# Security Specification

This document describes the security model, trust boundaries, secret management, and
authentication/authorization patterns that exist in the dotfiles.vorpal project as of the current
codebase state. It reflects what is actually implemented, not aspirational goals.

---

## 1. Project Security Context

This project is a **personal dotfiles configuration system** built on the Vorpal build framework.
It generates and deploys user environment configurations (shell, editor, terminal, AI coding tools)
to a developer workstation. The security surface is narrower than a typical web service but has
distinct concerns around:

- **Supply chain integrity** of downloaded binary artifacts
- **Secret management** in CI/CD pipelines
- **AI tool permission boundaries** (Claude Code, Opencode)
- **Configuration files** deployed to the user's home directory via symlinks

---

## 2. Trust Boundaries

### 2.1 Build-Time Trust Boundary

The Vorpal build system operates as a trusted build orchestrator. It downloads external artifacts
(binaries, themes, tools) from the internet and assembles them into a user environment. The trust
boundary is:

- **Trusted**: The Vorpal SDK, vorpal-artifacts library, and this repository's Rust source code.
  These are compiled and executed locally or in CI.
- **Semi-trusted**: External binary downloads specified in `Vorpal.lock`. These are pinned by
  SHA-256 digest, providing integrity verification but not provenance attestation.
- **Untrusted**: The network transport layer for downloads. Mitigated by HTTPS URLs and digest
  verification.

### 2.2 Runtime Trust Boundary

The generated environment runs as the local user on macOS. Configuration files are symlinked from
the Vorpal store (`/var/lib/vorpal/store/artifact/output/`) into `$HOME/.config/`, `$HOME/.claude/`,
and `$HOME/Library/Application Support/`. The local user has full read/write access to all deployed
artifacts.

### 2.3 CI/CD Trust Boundary

GitHub Actions workflows execute builds with access to AWS credentials for the Vorpal registry
(S3 backend). The CI environment is the most sensitive trust boundary in the project.

---

## 3. Secret Management

### 3.1 CI/CD Secrets (GitHub Actions)

The workflow at `.github/workflows/vorpal.yaml` uses the following secrets:

| Secret | Source | Purpose |
|---|---|---|
| `AWS_ACCESS_KEY_ID` | GitHub Secrets (`${{ secrets.AWS_ACCESS_KEY_ID }}`) | S3 registry authentication |
| `AWS_SECRET_ACCESS_KEY` | GitHub Secrets (`${{ secrets.AWS_SECRET_ACCESS_KEY }}`) | S3 registry authentication |
| `AWS_DEFAULT_REGION` | GitHub Variables (`${{ vars.AWS_DEFAULT_REGION }}`) | S3 region configuration |

These secrets are passed as environment variables to the `ALT-F4-LLC/setup-vorpal-action@main`
action. The region is stored as a non-secret variable, which is appropriate since it is not
sensitive.

### 3.2 Local Secret Management

The project includes **Doppler CLI** as a managed artifact (`Doppler::new().build(context)`),
indicating that Doppler is the intended secret management solution for the local development
environment. However, there is no Doppler configuration within this repository itself -- Doppler
is simply provisioned as a tool in the user environment.

### 3.3 No Embedded Secrets

The codebase contains **no hardcoded secrets, API keys, or credentials**. The following patterns
were verified:

- No `.env` files exist in the repository
- `.gitignore` only excludes `/target` (Rust build artifacts)
- No credential files, private keys, or tokens are committed
- The `.envrc` file exists but was not inspectable in this review; it likely contains a `use`
  directive for direnv/Vorpal environment setup

### 3.4 AI Tool API Keys

The Claude Code configuration supports an `api_key_helper` field (defined in
`src/user/claude_code.rs:108`) which allows delegating API key retrieval to an external command
rather than embedding keys. This field is **not currently used** in the configuration at
`src/user.rs:87-172` -- Claude Code authentication is handled externally by Anthropic's own
login flow.

---

## 4. AI Tool Permission Model

The most significant security-relevant code in this project is the **permission configuration for
AI coding assistants** (Claude Code and Opencode). These tools can execute arbitrary commands, so
their permission boundaries are critical.

### 4.1 Claude Code Permissions

Defined in `src/user.rs:114-168`, the Claude Code settings configure a permission model with
three tiers:

**Allow list** (auto-approved without user prompt):
- Build/test commands: `cargo build`, `cargo check`, `cargo clippy`, `cargo fmt`, `cargo test`,
  `go build`, `go test`, `go vet`, `make build`, `make lint`, `make test`
- Read-only commands: `cat`, `find`, `grep`, `ls`, `sort`, `tree`, `wc`, `xargs`
- Package management: `cargo search`, `cargo update`, `cargo outdated`, `cargo tree`,
  `go get`, `go list`, `go mod tidy`
- VCS: `git add`, `git branch --show-current`, `git remote get-url`, `gh pr list`
- Build tools: `vorpal build`, `vorpal inspect`, `cue export`, `cue vet`, `curl`, `tar`,
  `docket`
- Skills: `Skill(code-review *)`, `Skill(commit)`
- Web: `WebFetch(domain:crates.io)`, `WebFetch(domain:github.com)`, `WebSearch`

**Deny list** (blocked regardless of user input):
- `Read(./**/*.key)` -- private key files
- `Read(./**/*.pem)` -- certificate/key files
- `Read(./.env)` -- environment variable files
- `Read(./.env*)` -- all dotenv variants
- `Read(./.secrets/**)` -- secrets directory
- `Read(./secrets/**)` -- alternative secrets directory

**Default mode**: `acceptEdits` -- Claude Code requires user approval for file edits.

**Security observations**:
- The allow list permits `curl:*` with any arguments, which could be used to exfiltrate data
  to arbitrary URLs. This is a known tradeoff for developer convenience.
- `git add:*` is allowed but `git commit` and `git push` are not auto-approved, providing a
  commit review checkpoint.
- The deny list correctly prevents reading sensitive file patterns (keys, certs, env files).
- Sandbox configuration is available in the `ClaudeCode` struct but is **not enabled** in the
  current configuration.

### 4.2 Opencode Permissions

Defined in `src/user.rs:179-206`, Opencode uses a simpler permission model:

- **Bash default**: `Ask` (all commands require user approval by default)
- **Bash allow list**: `cat`, `echo`, `file`, `find`, `git branch`, `git log`, `grep`, `head`,
  `ls`, `sort`, `test`, `tree`, `wc` -- all read-only operations
- **Edit**: `Ask` (requires approval)
- **Glob/List/LSP/Read**: `Allow` (read operations are auto-approved)
- **WebFetch**: `Allow`

Opencode's permission model is **more restrictive** than Claude Code's, requiring explicit user
approval for any command not in the read-only allow list.

---

## 5. Supply Chain Security

### 5.1 Binary Artifact Integrity

The `Vorpal.lock` file pins every external download by:

- **Exact URL**: Each artifact has a specific versioned URL
- **SHA-256 digest**: Each artifact includes a `digest` field with a hex-encoded SHA-256 hash
- **Platform specificity**: Artifacts are locked per-platform (`aarch64-darwin`)

There are **31 digest-verified sources** in `Vorpal.lock`, covering tools such as: awscli2, bat,
cargo, clippy, direnv, doppler, fd, gh, git, go, gopls, jj, jq, k9s, kubectl, lazygit, libevent,
ncurses, nnn, pkg-config, protoc, readline, ripgrep, rust-analyzer, rust-src, rust-std, rustc,
rustfmt, tmux, and the bat theme.

**What this provides**: Integrity verification -- if a download is tampered with in transit or at
the source, the digest mismatch will fail the build.

**What this does not provide**:
- Provenance attestation (no signature verification from upstream maintainers)
- Reproducibility guarantees (digests are manually or tool-updated, not derived from source)
- Multi-platform verification (only `aarch64-darwin` is currently locked)

### 5.2 Rust Dependency Management

The project depends on two Git-based Rust crates:

- `vorpal-artifacts` from `ALT-F4-LLC/artifacts.vorpal.git` (branch: main)
- `vorpal-sdk` from `ALT-F4-LLC/vorpal.git` (branch: main)

Both are pinned to `branch = "main"` in `Cargo.toml`, meaning they track the latest commit on
main. The `Cargo.lock` file provides reproducible builds by locking exact commit hashes, but
any `cargo update` will pull the latest main. These are first-party dependencies within the
ALT-F4-LLC organization.

Third-party crate dependencies include cryptographic libraries (`ring`, `rustls`) which are
pulled transitively through the Vorpal SDK for TLS communication with the registry.

### 5.3 Renovate Bot

`renovate.json` configures automated dependency updates with:

- **Automerge** for minor/patch updates on stable crates (version >= 1.0)
- **Manual review** for major version updates
- Custom regex tracking for the tokyonight bat theme version

Automerging minor/patch updates is a reasonable balance between freshness and review burden for a
personal dotfiles project. The `matchCurrentVersion: "!/^0/"` guard correctly excludes pre-1.0
crates from automerge, since they may have breaking changes in minor versions.

### 5.4 GitHub Actions Supply Chain

The CI workflow uses:

- `actions/checkout@v6` -- pinned to major version tag
- `ALT-F4-LLC/setup-vorpal-action@main` -- pinned to branch, first-party action
- `actions/upload-artifact@v6` -- pinned to major version tag

**Gap**: Actions are pinned to version tags, not commit SHAs. This is vulnerable to tag
mutability attacks where a compromised action could republish a tag pointing to malicious code.
For a personal project this is an accepted risk, but for higher-security environments, SHA
pinning would be preferred.

---

## 6. Build Script Security

### 6.1 Shell Script Generation

The `FileCreate` struct in `src/file.rs:37-60` generates bash scripts that write file content
using heredoc syntax:

```bash
cat << 'EOF' > $VORPAL_OUTPUT/{name}
{contents}
EOF
chmod {chmod_mode} $VORPAL_OUTPUT/{name}
```

The use of a **single-quoted heredoc delimiter** (`'EOF'`) prevents variable expansion within the
content, which is the correct approach to avoid shell injection when writing arbitrary content.
All generated scripts use `set -euo pipefail` for strict error handling.

### 6.2 File Permissions

Generated configuration files default to `644` (read-only for group/other). Executable files
(like the statusline script) are explicitly set to `755`. This is appropriate.

---

## 7. Telemetry and Observability Endpoints

The Claude Code configuration sends telemetry data to external endpoints defined in
`src/user.rs:94-113`:

| Data Type | Endpoint | Protocol |
|---|---|---|
| Logs | `https://loki.bulbasaur.altf4.domains/otlp/v1/logs` | HTTP/Protobuf |
| Metrics | `https://mimir.bulbasaur.altf4.domains/otlp/v1/metrics` | HTTP/Protobuf |

These are first-party observability endpoints under the `altf4.domains` domain. The OTEL
configuration enables:

- `CLAUDE_CODE_ENABLE_TELEMETRY=1` -- Claude Code telemetry enabled
- Log and metric export intervals of 15 seconds
- Cumulative metrics temporality

**Security consideration**: Telemetry data may include session metadata, cost information, and
usage patterns. The endpoints use HTTPS, providing transport encryption. Authentication to these
endpoints is not configured in this codebase -- it may be handled at the network/infrastructure
level or by Doppler-managed secrets.

---

## 8. Filesystem Security Model

### 8.1 Vorpal Store

Artifacts are stored in `/var/lib/vorpal/store/artifact/output/{namespace}/{digest}`. This is a
system-level directory requiring elevated permissions to modify, providing integrity for built
artifacts after deployment.

### 8.2 Symlink-Based Deployment

The user environment deploys configuration via symlinks from the Vorpal store into user-writable
locations. Symlink targets defined in `src/user.rs:388-400` include:

- `$HOME/.config/bat/config`
- `$HOME/.config/bat/themes/tokyonight.tmTheme`
- `$HOME/.claude/agents/`
- `$HOME/.claude/settings.json`
- `$HOME/.claude/skills/`
- `$HOME/.claude/statusline.sh`
- `$HOME/Library/Application Support/com.mitchellh.ghostty/config`
- `$HOME/Library/Application Support/k9s/skins/tokyo_night.yaml`
- `$HOME/.config/nvim/after/ftplugin/markdown.vim`
- `$HOME/.config/opencode/opencode.json`
- `$HOME/.vorpal/bin/vorpal` (links to a local dev build)

The symlink to `$HOME/.vorpal/bin/vorpal` points to a local Vorpal development build at a
hardcoded absolute path. This means the `vorpal` binary in the user's PATH is whatever is
currently compiled in the local Vorpal repository checkout, not a released/verified version.

---

## 9. Known Gaps and Risks

| Area | Gap | Severity | Notes |
|---|---|---|---|
| GitHub Actions pinning | Actions use version tags, not SHA pins | Low | Acceptable for personal project |
| Git dependency pinning | Vorpal SDK/artifacts track `branch = "main"` | Low | First-party deps, Cargo.lock provides reproducibility |
| Claude Code sandbox | Sandbox is not enabled in current configuration | Medium | Would provide OS-level isolation for AI-executed commands |
| `.gitignore` coverage | Only `/target` is ignored; no `.env`, `*.key`, `*.pem` patterns | Low | No such files exist, but .gitignore is not defensive |
| Telemetry auth | OTEL endpoints lack visible authentication configuration | Low | Likely handled at infrastructure level |
| curl permissions | Claude Code allows `curl:*` without restriction | Medium | Could exfiltrate data; tradeoff for developer convenience |
| Single-platform lock | `Vorpal.lock` only contains `aarch64-darwin` digests | Info | Other platforms declared in code but not yet locked |
| Provenance | Binary downloads verified by digest only, no signature checking | Low | Standard practice for most package managers |

---

## 10. Summary

The project has a reasonable security posture for a personal dotfiles system:

- **Strong**: SHA-256 digest verification for all binary downloads, AI tool deny lists for
  sensitive files, no embedded secrets, strict shell scripts with `set -euo pipefail`,
  heredoc quoting to prevent injection.
- **Adequate**: CI secrets managed via GitHub Secrets, Renovate with guarded automerge,
  first-party dependency tracking.
- **Gaps**: No Claude Code sandbox enabled, `.gitignore` is minimal, GitHub Actions not SHA-pinned,
  `curl:*` allowed without restriction in Claude Code permissions.
