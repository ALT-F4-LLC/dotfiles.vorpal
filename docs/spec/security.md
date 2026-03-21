---
project: "dotfiles.vorpal"
maturity: "experimental"
last_updated: "2026-03-21"
updated_by: "@staff-engineer"
scope: "Security posture of the dotfiles.vorpal project — secrets management, trust boundaries, supply chain integrity, and AI agent sandboxing"
owner: "@staff-engineer"
dependencies:
  - architecture.md
---

# Security

This document describes the security-relevant aspects of dotfiles.vorpal as they actually exist today. It covers trust boundaries, secret management, supply chain integrity, AI agent sandboxing, and filesystem permissions.

## 1. Trust Model

### Build-Time vs. Runtime Trust

The project operates in two distinct trust domains:

1. **Build-time (Vorpal)** -- The Rust program (`src/vorpal.rs`) runs during `vorpal build` to produce content-addressed artifacts stored in `/var/lib/vorpal/store/`. Build-time has full access to the host filesystem and network. Trust here is placed in the Vorpal SDK, the vorpal-artifacts library, and the upstream artifact sources (GitHub releases, official distribution tarballs).

2. **Runtime (User environment)** -- After build, the user environment consists of symlinks from `$HOME` into the Vorpal store. Runtime tools (awscli2, kubectl, gh, etc.) operate with the user's ambient permissions. The dotfiles project does not add or remove runtime trust -- it provisions tools at specific, pinned versions.

### Trust Boundaries

| Boundary | Description | Current Controls |
|----------|-------------|------------------|
| Vorpal store | Artifacts at `/var/lib/vorpal/store/artifact/output/` | Content-addressed by digest; read-only after build |
| CI/CD secrets | AWS credentials for S3 registry | GitHub Actions secrets (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`) |
| Upstream artifacts | Binary downloads from GitHub/vendor CDNs | SHA-256 digest verification in `Vorpal.lock` |
| Claude Code sandbox | AI agent filesystem/network access | Three-tier permission model (allow/ask/deny) plus sandbox |
| Home directory symlinks | Configs written to `$HOME` | Symlinks point into Vorpal store; source is the build output |

## 2. Secret Management

### Secrets in This Repository

**No secrets are stored in the repository.** The `.gitignore` excludes `/.docket` and `/target`. The `.envrc` file is present but denied from Claude Code reading via `Read(.envrc)` deny rule.

### Secrets Referenced at Build Time

The CI workflow (`.github/workflows/vorpal.yaml`) references three secrets/variables:

| Secret/Variable | Scope | Purpose |
|-----------------|-------|---------|
| `secrets.AWS_ACCESS_KEY_ID` | GitHub Actions | S3 registry authentication for Vorpal remote cache |
| `secrets.AWS_SECRET_ACCESS_KEY` | GitHub Actions | S3 registry authentication for Vorpal remote cache |
| `vars.AWS_DEFAULT_REGION` | GitHub Actions | AWS region for S3 registry |

These are injected as environment variables into the `setup-vorpal-action` step. They never appear in build output or artifact content.

### Secrets Referenced at Runtime

The user environment provisions **Doppler CLI** (`doppler`) as a managed tool, indicating that runtime secrets are managed through Doppler's secret management platform rather than local `.env` files or environment variable exports. The dotfiles project itself does not configure Doppler -- it only ensures the CLI binary is available.

**AWS CLI** (`awscli2`) is also provisioned. AWS credentials at runtime are expected to be managed through `~/.aws/` (which is deny-listed from Claude Code reading).

### Sensitive Paths Protected from AI Agents

The Claude Code configuration (`src/user.rs:202-223`) explicitly denies read access to:

- `.env`, `.env.*`, `.envrc` -- Environment variable files
- `~/.aws/**` -- AWS credentials
- `~/.ssh/**` -- SSH keys
- `~/.gnupg/**` -- GPG keys
- `~/.kube/**` -- Kubernetes configs (may contain tokens)
- `~/.doppler/**` -- Doppler configuration
- `~/.netrc` -- Network credentials
- `~/.talos/**` -- Talos (Kubernetes OS) configs
- `~/.claude.json`, `~/.claude/**` -- Claude Code internal config
- `~/.codex/**`, `~/.gemini/**`, `~/.opencode/**`, `~/.vorpal/**` -- Other AI tool configs

Write and Edit access to the same paths is also denied (`src/user.rs:224-241`).

## 3. Supply Chain Integrity

### Artifact Source Verification

All 30+ binary artifacts in `Vorpal.lock` use SHA-256 digest verification. Each entry contains:

```toml
[[sources]]
name = "bat"
path = "https://github.com/sharkdp/bat/releases/download/v0.25.0/bat-v0.25.0-aarch64-apple-darwin.tar.gz"
digest = "3abca7df1be4d52ef37ccd22f0b01da87f149f4ca1f74633d53deba87d98b078"
platform = "aarch64-darwin"
```

The `digest` field is a SHA-256 hash that Vorpal verifies at download time. If the upstream artifact changes, the digest mismatch causes a build failure. This provides **pinning** (exact version) and **integrity verification** (hash match) for all downloaded binaries.

### Dependency Sources

| Source Category | Examples | Verification |
|----------------|----------|--------------|
| Official vendor CDNs | `awscli.amazonaws.com`, `dl.k8s.io`, `go.dev`, `static.rust-lang.org` | SHA-256 digest in Vorpal.lock |
| GitHub releases | bat, fd, gh, jj, jq, k9s, lazygit, nnn, ripgrep, doppler, direnv | SHA-256 digest in Vorpal.lock |
| Source tarballs (compiled from source) | git, tmux, libevent, ncurses, readline, pkg-config, gopls | SHA-256 digest in Vorpal.lock |
| Raw file downloads | tokyonight.nvim bat theme | SHA-256 digest in Vorpal.lock |

### Rust Dependency Chain

The project depends on two Vorpal-ecosystem crates:

- `vorpal-sdk = "0.1.0-alpha.0"` -- from crates.io
- `vorpal-artifacts` -- from GitHub (`ALT-F4-LLC/artifacts.vorpal.git`, `main` branch)

The `vorpal-artifacts` dependency uses a **git branch reference** (`branch = "main"`), not a pinned commit or version. This means builds are not fully reproducible against this dependency -- a force-push to `main` could change what gets built. The `Cargo.lock` mitigates this by recording the exact commit hash at lock time, but `cargo update` would pick up whatever `main` points to.

**Transitive dependencies** include TLS/crypto libraries (`ring`, `rustls`, `rustls-pki-types`) used by the Vorpal SDK for secure communication with the Vorpal registry/daemon. These are standard, well-audited Rust crypto libraries.

### Dependency Update Policy

Renovate (`renovate.json`) manages automated dependency updates with the following policy:

- **Minor/patch updates** on stable crates (version >= 1.0): auto-merged
- **Major updates**: require manual review
- **Pre-release crates** (version < 1.0): not auto-merged (the `matchCurrentVersion: "!/^0/"` filter excludes them)
- **Custom version tracking**: the tokyonight.nvim bat theme version is tracked via a regex custom manager pointing at a GitHub raw URL in `src/user.rs`

**Gap:** The `serde` ecosystem is grouped for update convenience but still follows the same auto-merge rules. No explicit audit step exists for transitive dependency additions.

## 4. AI Agent Sandboxing

### Claude Code Permission Model

The Claude Code configuration (`src/user.rs:114-254`) implements a comprehensive three-tier permission system:

**Allow (auto-approved):**
- Read-only operations: `ls`, `cat`, `head`, `tail`, `find`, `grep`, `rg`, `wc`, `tree`, `sort`, `test`
- Build/check commands: `cargo build/check/clippy/fmt/test/tree`, `go build/test/vet`, `npm/bun/yarn` variants
- Vorpal operations: `vorpal build`, `vorpal inspect`
- Docket operations: `docket:*` (full access for agent team coordination)
- Git read operations: `git diff`, `git log`, `git status`, `git show`, `git remote get-url`
- GitHub read operations: `gh pr diff`, `gh pr list`, `gh pr view`
- Network fetch: `api.github.com`, `crates.io`, `github.com` only

**Ask (requires user confirmation):**
- `git commit` -- state-changing but reversible
- `git push` -- affects remote state
- `chown` -- filesystem permission changes
- `rm` -- file deletion

**Deny (blocked entirely):**
- `git checkout`, `git reset` -- destructive git operations
- All Read/Edit/Write operations on sensitive home directory paths (see Section 2)
- System directories: `/Applications/**`, `/Library/**`, `/System/**`

### Sandbox Configuration

The sandbox (`src/user.rs:246-255`) provides an additional enforcement layer:

- **Sandbox enabled:** `true`
- **Auto-allow bash if sandboxed:** `true` -- bash commands run in sandbox by default
- **Allow unsandboxed commands:** `true` -- commands can request sandbox bypass (with user approval)
- **Excluded commands** (run without sandbox): `aws`, `docker`, `gh`, `git` -- these need network/credential access that the sandbox would block
- **Network local binding:** `false` -- prevents agents from starting local servers

### Permission Bypass Protection

- `disable_bypass_permissions_mode` is set to `"disable"` (`src/user.rs:243`), preventing agents from escalating their own permissions
- `default_mode` is set to `"acceptEdits"` (`src/user.rs:242`), requiring explicit approval for file modifications

### Agent Team Security

The five-agent team (staff-engineer, senior-engineer, project-manager, sdet, ux-designer) defined in `agents/` operates under Claude Code's sub-agent model:

- Sub-agents inherit the permission/sandbox configuration from the parent Claude Code instance
- Sub-agents lack `Agent` and `TeamCreate` tools -- they cannot spawn additional agents (see `docs/tdd/agent-delegation-protocol.md`)
- Inter-agent communication uses `SendMessage` which is internal to the session
- The delegation protocol routes privileged operations (agent spawning) through the orchestrator

## 5. CI/CD Security

### GitHub Actions Workflow

The workflow (`.github/workflows/vorpal.yaml`) runs on:
- Every push to `main`
- Every pull request

**Security-relevant characteristics:**

- Uses `actions/checkout@v6` (major version pinned, not SHA-pinned)
- Uses `ALT-F4-LLC/setup-vorpal-action@main` (branch-pinned, not SHA-pinned or version-pinned)
- Runs on `macos-latest` (GitHub-hosted runners)
- AWS credentials are scoped to the Vorpal S3 registry bucket (`altf4llc-vorpal-registry`)
- The `Vorpal.lock` is uploaded as a build artifact for the `build` job to consume

**Gap:** Neither `actions/checkout` nor `setup-vorpal-action` are pinned to SHA digests. A compromised action version could inject malicious code into the build pipeline. The `setup-vorpal-action` at `@main` is particularly risky since it tracks a mutable branch.

### Build Matrix

The `build` job uses a strategy matrix with a single artifact (`user`). The `build-dev` job builds the `dev` artifact. Both jobs independently authenticate to the S3 registry.

## 6. Filesystem Security

### Content-Addressed Store

Vorpal stores build outputs at `/var/lib/vorpal/store/artifact/output/{namespace}/{digest}`. The digest-based path means:
- Artifacts are immutable after build (changing content changes the path)
- Multiple versions can coexist without collision
- Rollback is implicit (old digests remain in the store)

### Symlink Layout

The user environment creates symlinks from user-writable paths into the Vorpal store:

- `~/.claude/settings.json` -> Vorpal store (Claude Code config)
- `~/.claude/agents/` -> Vorpal store (agent definitions)
- `~/.claude/skills/` -> Vorpal store (skill definitions)
- `~/.config/bat/config` -> Vorpal store
- Terminal/editor configs -> Vorpal store

Since symlink targets are in the Vorpal store (which is content-addressed), modifying a config at runtime would require writing through the symlink into the store. The practical security implication: config drift is visible because the store path encodes the expected content hash.

### File Permissions

Build scripts (`src/file.rs:38,48`) set file permissions explicitly:
- Regular files: `644` (owner read/write, group/others read)
- Executable files: `755` (owner read/write/execute, group/others read/execute)

## 7. Known Gaps and Risks

| Gap | Severity | Description |
|-----|----------|-------------|
| Git branch dependency | Medium | `vorpal-artifacts` is referenced by branch (`main`), not pinned commit. `Cargo.lock` provides de facto pinning, but explicit commit pinning would be more robust. |
| CI action pinning | Medium | GitHub Actions (`actions/checkout@v6`, `setup-vorpal-action@main`) are not SHA-pinned. A supply chain attack on these actions could compromise the build. |
| No SBOM generation | Low | No Software Bill of Materials is generated during build. The `Vorpal.lock` serves a similar role for direct artifacts but does not cover transitive Rust dependencies. |
| No dependency audit in CI | Low | `cargo audit` or equivalent is not run in the CI pipeline. Vulnerable transitive dependencies would not be caught automatically. |
| Sandbox exclusions | Low | `aws`, `docker`, `gh`, `git` are excluded from the sandbox. These tools have legitimate reasons to access credentials and network, but a prompt injection attack through these tools would bypass sandboxing. |
| No code signing | Low | Built artifacts are not code-signed. Integrity relies on the Vorpal store's content-addressing, which protects against accidental modification but not targeted tampering on the host. |
| Auto-merge policy | Low | Renovate auto-merges minor/patch updates for stable crates. A malicious minor version bump of a dependency could be auto-merged without review. Mitigated by the `>=1.0` filter and crates.io's existing trust model. |
