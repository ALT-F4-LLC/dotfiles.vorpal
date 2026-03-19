---
project: "dotfiles.vorpal"
maturity: "experimental"
last_updated: "2026-03-18"
updated_by: "@staff-engineer"
scope: "Security model, trust boundaries, secret management, and AI agent sandboxing for the dotfiles.vorpal project"
owner: "@staff-engineer"
dependencies:
  - architecture.md
  - operations.md
---

# Security

## Overview

dotfiles.vorpal is a declarative dotfiles manager that produces configuration artifacts deployed to the local filesystem via the Vorpal build system. The project has two primary security surfaces: (1) the build-time supply chain that downloads and installs CLI tools and configurations, and (2) the runtime AI agent permission model that controls what Claude Code and OpenCode can do on the host machine.

The project does not run a network service, does not process untrusted user input at runtime, and does not manage authentication for end users. Its security posture is primarily about supply chain integrity, secret hygiene, and constraining AI agent behavior.

## Trust Boundaries

### Build-Time Trust Boundaries

1. **Vorpal Build System**: The project trusts the Vorpal runtime (`vorpal-sdk`, `vorpal-artifacts`) to execute build steps in isolation. Build steps run as shell scripts (`set -euo pipefail`) that download, extract, and copy artifacts into `/var/lib/vorpal/store/`. The Vorpal store is content-addressed by artifact digest.

2. **External Download Sources**: The `Vorpal.lock` file pins every external dependency to a specific URL and SHA-256 digest. This includes CLI tool binaries (from GitHub Releases, official distribution sites), the Rust toolchain (from `static.rust-lang.org`), and theme files (from GitHub raw content). The lockfile provides integrity verification, but trust in the upstream sources themselves is implicit.

3. **Git Dependencies**: Two Cargo dependencies use git sources:
   - `vorpal-artifacts` (`artifacts.vorpal.git`, branch `main`) -- no version pin, follows branch HEAD
   - `vorpal-sdk` (version `0.1.0-alpha.0` from crates.io)

   The `vorpal-artifacts` git dependency tracks `main` without a commit pin, meaning builds are not fully reproducible across time. This is a known gap.

4. **CI/CD Pipeline**: GitHub Actions workflows (`vorpal.yaml`) run on `macos-latest` and use the `ALT-F4-LLC/setup-vorpal-action@main` action, which also tracks `main` without a version pin.

### Runtime Trust Boundaries

1. **Vorpal Store to Home Directory**: The build creates symlinks from the Vorpal content-addressed store (`/var/lib/vorpal/store/artifact/output/...`) into the user's home directory. Once symlinked, configuration files are read by their respective tools (Claude Code, Ghostty, bat, k9s, etc.) with the user's permissions.

2. **AI Agent Sandbox**: Claude Code is configured with a three-tier permission model (allow/ask/deny) and a filesystem sandbox. This is the most security-critical configuration the project produces.

## Secret Management

### Secrets in CI/CD

The GitHub Actions workflow uses three secrets:
- `AWS_ACCESS_KEY_ID` -- stored as a GitHub Actions secret
- `AWS_SECRET_ACCESS_KEY` -- stored as a GitHub Actions secret
- `AWS_DEFAULT_REGION` -- stored as a GitHub Actions variable (not a secret)

These credentials provide access to the S3-backed Vorpal registry (`altf4llc-vorpal-registry`) for remote artifact caching. No scoping or rotation policy is documented.

### Secrets at Runtime

- **Doppler CLI**: Included in the user environment as a managed tool. Doppler is a secrets management service -- its presence suggests secrets are fetched at runtime via `doppler run` rather than baked into configuration files. No Doppler configuration is defined in the dotfiles themselves.
- **AWS CLI**: Included in the user environment. AWS credentials are expected to exist on the host (likely in `~/.aws/`), which is explicitly denied from AI agent read access.
- **No hardcoded secrets**: The codebase contains no API keys, tokens, or credentials in source files. The only URLs are public download endpoints and observability endpoints (Loki, Mimir).

### Observability Endpoints

The Claude Code configuration includes OTEL exporter endpoints:
- `https://loki.bulbasaur.altf4.domains/otlp/v1/logs`
- `https://mimir.bulbasaur.altf4.domains/otlp/v1/metrics`

These endpoints receive telemetry data from Claude Code sessions. There is no authentication configured for these endpoints in the dotfiles -- authentication may be handled at the network/infrastructure level, but this is not visible in the codebase.

## AI Agent Permission Model

This is the most substantial security surface in the project. The Claude Code `settings.json` is generated programmatically with a detailed permission configuration.

### Permission Tiers

**Allow (auto-approved):**
- Read-only and build commands: `cargo build`, `cargo test`, `go build`, `git status`, `git diff`, `git log`, `ls`, `find`, `grep`, `rg`, etc.
- Package manager read operations: `cargo search`, `cargo tree`, `cargo outdated`
- Limited web access: `api.github.com`, `crates.io`, `github.com` only
- Web search capability

**Ask (requires user confirmation):**
- `chown` -- ownership changes
- `git commit` -- creating commits
- `git push` -- pushing to remotes
- `rm` -- file deletion

**Deny (blocked):**
- Destructive git operations: `git checkout`, `git reset`
- Reading sensitive directories: `~/.aws`, `~/.ssh`, `~/.gnupg`, `~/.kube`, `~/.doppler`, `~/.talos`, `~/.netrc`
- Reading environment files: `.env`, `.env.*`, `.envrc`
- Reading/writing/editing system directories: `/Applications`, `/Library`, `/System`
- Reading/writing/editing other tool configs: `~/.claude`, `~/.vorpal`, `~/.opencode`, `~/.codex`, `~/.gemini`
- Reading/writing user directories: `~/Desktop`, `~/Downloads`, `~/Library`

### Sandbox Configuration

- **Sandbox enabled**: `true`
- **Auto-allow bash if sandboxed**: `true` -- bash commands run automatically within sandbox constraints
- **Allow unsandboxed commands**: `true` -- commands excluded from sandbox can run without sandbox
- **Excluded from sandbox**: `aws`, `docker`, `gh`, `git` -- these run outside the sandbox
- **Network local binding**: `false` -- agents cannot bind to local ports

### Security Assessment of Agent Permissions

**Strengths:**
- Comprehensive deny list covering credential stores, SSH keys, cloud configs, and environment files
- Destructive git operations are blocked entirely
- Write access to system directories is denied
- The permission model is generated from code, making it auditable and version-controlled
- Bypass permissions mode is disabled (`disable`)
- Default permission mode is `acceptEdits` (not fully autonomous)

**Gaps and Risks:**
- `allow_unsandboxed_commands: true` combined with excluding `aws`, `docker`, `gh`, `git` from the sandbox means these tools have unrestricted network and filesystem access. An agent could theoretically use `gh` or `aws` to exfiltrate data or make changes to remote systems.
- The `Bash(cat:*)` allow rule permits reading any file the user has access to, including files outside the project directory -- the deny rules on `Read()` operations cover sensitive paths, but `cat` via bash is a separate permission pathway.
- `Bash(xargs:*)` and `Bash(find:*)` are allowed, which combined with `cat` could be used to read files in bulk.
- `Bash(chmod:*)` is allowed (not just ask), enabling permission changes on any accessible file.
- `Bash(tar:*)` is allowed, which could be used to create archives of accessible files.

### OpenCode Permission Model

OpenCode (a separate AI coding tool) has a simpler permission model:
- Bash: default `Ask`, with specific read-only commands allowed (`cat`, `find`, `grep`, `ls`, `head`, `sort`, `test`, `tree`, `wc`)
- Edit: `Ask`
- Glob/List/LSP/Read: `Allow`
- Web fetch: `Allow`

This is a more conservative model than Claude Code's.

## Supply Chain Security

### Dependency Integrity

- **Vorpal.lock**: All external binary downloads are pinned to exact URLs and SHA-256 digests. This prevents silent substitution of binaries. The lockfile currently covers aarch64-darwin only.
- **Cargo.lock**: Rust dependency versions are locked. Renovate auto-merges minor/patch updates for stable crates (version >= 1.0) and requires manual review for major updates and pre-1.0 crates.
- **No signature verification**: Downloaded binaries are verified by digest but not by cryptographic signature. If an upstream release is compromised before the digest is recorded in `Vorpal.lock`, the compromised binary would be accepted.

### Build Reproducibility

- Builds are content-addressed through the Vorpal store, providing some reproducibility guarantees.
- The `vorpal-artifacts` git dependency on `main` branch without commit pinning means the same source checkout may produce different build plans over time.
- The CI action `ALT-F4-LLC/setup-vorpal-action@main` is also unpinned.

### Renovate Automation

- Renovate is configured to auto-merge minor and patch updates for stable Cargo crates.
- Major version updates require manual review.
- A custom manager tracks the tokyonight.nvim theme version from the raw GitHub URL in `src/user.rs`.

## Filesystem Security

### Vorpal Store

Artifacts are stored in `/var/lib/vorpal/store/artifact/output/`. This directory is managed by the Vorpal runtime. The content-addressed storage model means artifacts are immutable once built -- symlinks point to specific digest-identified paths.

### Symlink Targets

The build creates symlinks into sensitive locations:
- `~/.claude/settings.json` -- controls AI agent behavior
- `~/.claude/agents/` -- agent persona definitions
- `~/.claude/skills/` -- skill definitions
- `~/.config/bat/config` -- bat configuration
- `~/Library/Application Support/com.mitchellh.ghostty/config` -- terminal config
- `~/Library/Application Support/k9s/skins/` -- k9s theme

These symlinks point into the Vorpal store, which provides integrity (content-addressed), but the symlinks themselves could be replaced by a local attacker with write access to the home directory.

### File Permissions

- Configuration files are created with `chmod 644` (read/write owner, read others).
- Executable files (e.g., `statusline.sh`) are created with `chmod 755`.
- No files are created with elevated permissions.

## Shell Script Injection Surface

The `FileCreate` abstraction uses heredoc (`cat << 'EOF'`) to write file contents, with single-quoted EOF delimiter preventing variable expansion in the content. This is the correct pattern to avoid injection. The `FileSource` and `FileDownload` abstractions interpolate `name` and `path` into shell scripts -- these values come from the Rust source code (not user input), so injection risk is minimal in the current design, but the pattern would be fragile if extended to accept external input.

## Gaps and Recommendations

1. **Unpinned CI action**: `ALT-F4-LLC/setup-vorpal-action@main` should be pinned to a specific commit SHA to prevent supply chain attacks via the action repository.

2. **Unpinned git dependency**: `vorpal-artifacts` on `main` branch should be pinned to a specific commit or tag for reproducible builds.

3. **No binary signature verification**: Consider adding GPG or cosign verification for downloaded binaries where upstream projects provide signatures.

4. **AWS credential scoping**: The S3 credentials used in CI should be scoped to minimum required permissions (read/write to the specific registry bucket only). No evidence of scoping is visible in the codebase.

5. **Observability endpoint authentication**: OTEL endpoints for logs and metrics have no visible authentication. If these are internet-accessible, telemetry data (which may include code snippets, file paths, and usage patterns) could be intercepted or spoofed.

6. **Agent sandbox exclusions**: The `aws`, `docker`, `gh`, and `git` commands running outside the sandbox is a pragmatic tradeoff, but it means an AI agent can interact with cloud infrastructure, container runtimes, and remote repositories without sandbox constraints. The `ask` requirement for `git push` mitigates the git case, but `aws` and `docker` have no such gate.

7. **Bash cat/tar/xargs allows**: The combination of allowed bash commands could be used to read and exfiltrate files outside the intended scope. The deny rules on `Read()` operations do not cover the `Bash(cat:*)` pathway.
