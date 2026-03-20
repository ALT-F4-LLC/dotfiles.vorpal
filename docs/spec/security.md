---
project: "main"
maturity: "experimental"
last_updated: "2026-03-20"
updated_by: "@staff-engineer"
scope: "Security posture of dotfiles.vorpal — secret management, CI credentials, AI agent sandboxing, permission boundaries, and dependency trust"
owner: "@staff-engineer"
dependencies:
  - architecture.md
  - operations.md
---

# Security Specification

## 1. Overview

This repository is a **Vorpal-based dotfiles configuration** project. It is a Rust binary that declaratively builds and deploys user environment artifacts — CLI tools, editor configs, AI agent settings, and shell customizations — via the Vorpal SDK. The security surface is narrow but consequential: the project manages CI credentials, configures AI coding agent permissions/sandboxing, downloads external resources, and symlinks configuration files into the user's home directory.

There is **no web application, no user-facing API, no database, and no authentication system** within this codebase. Security concerns center on supply chain integrity, secret handling in CI, AI agent permission boundaries, and the trust model for artifact sources.

## 2. Trust Boundaries

### 2.1 Build-Time vs. Runtime

| Boundary | Description |
|---|---|
| **Vorpal build host** | The Rust binary executes at build time via `vorpal build`. It fetches artifacts, runs shell scripts, and produces output artifacts stored under `/var/lib/vorpal/store/artifact/output/`. |
| **CI environment** | GitHub Actions workflows execute builds with access to AWS credentials. The CI host is the highest-privilege boundary. |
| **User workstation** | Vorpal output artifacts are symlinked into the user's home directory (`~/.claude/`, `~/.config/`, `~/Library/`). The user's local session is the runtime trust boundary. |
| **AI agent sandbox** | Claude Code and Opencode run within configured permission and sandbox boundaries. The agent is an untrusted actor constrained by the permission model defined in this codebase. |

### 2.2 Data Flow Trust

```
[GitHub Actions CI] --(AWS creds)--> [Vorpal Registry (S3)]
[Vorpal build]      --(HTTPS)------> [External URLs: raw.githubusercontent.com]
[Vorpal build]      --(crates.io)--> [Rust dependency graph]
[Vorpal output]     --(symlinks)----> [User home directory configs]
```

## 3. Secret Management

### 3.1 CI Secrets

Secrets are managed via GitHub Actions secrets/variables — never stored in the repository.

| Secret | Purpose | Storage |
|---|---|---|
| `AWS_ACCESS_KEY_ID` | S3 registry backend authentication | GitHub Actions secret |
| `AWS_SECRET_ACCESS_KEY` | S3 registry backend authentication | GitHub Actions secret |
| `AWS_DEFAULT_REGION` | S3 region configuration | GitHub Actions variable (non-secret) |

These are injected as environment variables in `.github/workflows/vorpal.yaml` (lines 21–23, 49–51) into the `ALT-F4-LLC/setup-vorpal-action@main` step.

### 3.2 Local Secrets

The `.envrc` file exists but is denied from being read by AI agents (see Section 5). Its contents are not committed — `.gitignore` does not list `.envrc`, but the Claude Code permission model explicitly blocks `Read(.envrc)`.

### 3.3 No Hardcoded Secrets

The codebase contains **no hardcoded API keys, tokens, or passwords**. The `api_key_helper` field on the `ClaudeCode` struct exists but is not set in the current configuration. OTEL endpoints (`src/user.rs:98–113`) are infrastructure URLs, not secrets.

## 4. AI Agent Permission Model

The most security-significant code in this repository is the **Claude Code permission configuration** (`src/user.rs:86–257` and `src/user/claude_code.rs`). This is a defense-in-depth model with three tiers.

### 4.1 Permission Tiers

**Allow (auto-approved, no prompt):**
- Read-only CLI tools: `ls`, `cat`, `head`, `tail`, `find`, `grep`, `rg`, `wc`, `tree`, `sort`, `jq`, `test`
- Build/lint tools: `cargo build|check|clippy|fmt|test|tree|update|search|outdated|run`, `go build|test|vet|doc|list|mod tidy`, `bun run|test`, `npm run build|lint|test`, `yarn build|lint|test`, `npx tsc`
- Git read operations: `git add`, `git diff`, `git log`, `git show`, `git status`, `git remote get-url`
- Infrastructure read: `docker images|logs|ps`, `vorpal build|inspect`, `gh pr diff|list|view`, `docket`
- Network: `WebFetch` to `api.github.com`, `crates.io`, `github.com`; `WebSearch`

**Ask (requires user confirmation):**
- `chown`, `git commit`, `git push`, `rm`

**Deny (blocked entirely):**
- Destructive git: `git checkout`, `git reset`
- System directories: Read/Edit/Write to `/Applications/**`, `/Library/**`, `/System/**`
- Sensitive dotfiles: `~/.aws/**`, `~/.ssh/**`, `~/.gnupg/**`, `~/.kube/**`, `~/.talos/**`, `~/.doppler/**`, `~/.netrc`
- AI tool configs: `~/.claude/**`, `~/.claude.json`, `~/.codex/**`, `~/.gemini/**`, `~/.opencode/**`, `~/.vorpal/**`
- User directories: `~/Desktop/**`, `~/Downloads/**`, `~/Library/**`
- Environment files: `.env`, `.env.*`, `.envrc`

### 4.2 Sandbox Configuration

Claude Code sandbox is **enabled** (`src/user.rs:246`) with:
- `auto_allow_bash_if_sandboxed: true` — bash commands auto-allowed when sandboxed
- `allow_unsandboxed_commands: true` — certain commands can escape the sandbox
- `excluded_commands: ["aws", "docker", "gh", "git"]` — these run outside the sandbox since they need network/socket access
- `network.allow_local_binding: false` — agents cannot bind local ports

### 4.3 Additional Hardening

- `default_mode: "acceptEdits"` — file edits are allowed by default (within non-denied paths)
- `disable_bypass_permissions_mode: "disable"` — prevents agents from escalating to bypass mode
- Attribution is set to empty strings for both commit and PR — disabling auto-attribution

### 4.4 Opencode Permission Model

Opencode (`src/user/opencode.rs`) has a simpler model:
- Default bash: `Ask` (prompt for all commands)
- Read-only commands explicitly allowed: `cat`, `echo`, `file`, `find`, `git branch`, `git log`, `grep`, `head`, `ls`, `sort`, `test`, `tree`, `wc`
- File operations: `edit: Ask`, `glob/list/lsp/read: Allow`, `webfetch: Allow`

## 5. Dependency Security

### 5.1 Rust Dependencies

Direct dependencies (`Cargo.toml`):
- `anyhow` (1.x) — error handling
- `indoc` (2.x) — string formatting
- `serde` + `serde_json` (1.x) — serialization
- `tokio` (1.x, `rt-multi-thread`) — async runtime
- `vorpal-artifacts` — **git dependency** from `https://github.com/ALT-F4-LLC/artifacts.vorpal.git` (branch: main)
- `vorpal-sdk` (0.1.0-alpha.0) — Vorpal SDK from crates.io

**Risk: `vorpal-artifacts` is pinned to `branch = "main"`**, meaning any push to that branch's main is automatically pulled on next `cargo update`. This is a supply chain risk — a compromised commit in that repository would propagate here. The `Cargo.lock` file (committed) mitigates this by pinning the exact revision until explicitly updated.

### 5.2 Renovate Bot

Renovate (`renovate.json`) manages dependency updates:
- **Automerge enabled** for minor/patch updates of stable (≥1.0) crates — reduces friction but means dependency updates can land without manual review
- Major updates require manual review
- Custom manager tracks the `tokyonight.nvim` theme version from GitHub releases

### 5.3 GitHub Actions Dependencies

- `actions/checkout@v6` — pinned to major version tag (not SHA)
- `actions/upload-artifact@v6` — pinned to major version tag
- `ALT-F4-LLC/setup-vorpal-action@main` — **pinned to branch**, same supply chain concern as the Rust git dependency

## 6. External Resource Downloads

The build downloads one external file at build time:
- **bat theme**: `https://raw.githubusercontent.com/folke/tokyonight.nvim/refs/tags/v4.14.1/extras/sublime/tokyonight_night.tmTheme` (`src/user.rs:66–67`)

This is pinned to a specific git tag (`v4.14.1`), which is good. The Renovate custom manager tracks version updates for this URL.

## 7. Build Script Security

Shell scripts are generated at build time via `FileCreate` (`src/file.rs`). These scripts use heredoc-based file creation with `set -euo pipefail`:

```bash
cat << 'EOF' > $VORPAL_OUTPUT/{name}
{contents}
EOF
chmod {mode} $VORPAL_OUTPUT/{name}
```

The single-quoted `'EOF'` delimiter prevents variable expansion inside the heredoc, which is correct. The `$VORPAL_OUTPUT` path is controlled by the Vorpal runtime, not user input.

**Note:** The `FileSource` and `FileDownload` structs construct shell scripts with interpolated `name` and `path` values (`src/file.rs:76–83, 112–117`). These values originate from hardcoded Rust strings in the codebase — not from external input — so shell injection is not a practical risk in the current usage. However, the pattern does not escape these values, so any future use with user-supplied input would be vulnerable.

## 8. Filesystem Security

### 8.1 Symlink Strategy

Vorpal output artifacts are symlinked into the user's home directory. The symlink targets include:
- `$HOME/.claude/settings.json` — Claude Code configuration
- `$HOME/.claude/agents/` and `$HOME/.claude/skills/` — AI agent definitions
- `$HOME/.config/bat/`, `$HOME/.config/nvim/`, `$HOME/.config/opencode/` — tool configs
- `$HOME/Library/Application Support/com.mitchellh.ghostty/config` — terminal config
- `$HOME/Library/Application Support/k9s/skins/` — k9s skin

### 8.2 Vorpal Store

All build outputs are stored under `/var/lib/vorpal/store/artifact/output/{namespace}/{digest}` (`src/lib.rs:11–13`). The content-addressed store (digest-based paths) provides integrity verification.

## 9. Gaps and Risks

| Area | Finding | Severity |
|---|---|---|
| **Git dependency on main branch** | `vorpal-artifacts` and `setup-vorpal-action` are pinned to `main` branch, not SHA or tag | Medium |
| **Actions not SHA-pinned** | `actions/checkout@v6` and `actions/upload-artifact@v6` use version tags, not commit SHAs | Low |
| **Automerge for minor/patch** | Renovate automerges stable crate updates without review | Low |
| **Sandbox excluded commands** | `aws`, `docker`, `gh`, `git` run unsandboxed — necessary but expands attack surface if agent is compromised | Low (accepted risk) |
| **No SAST/dependency scanning** | No `cargo audit`, `cargo deny`, or similar tool in CI | Medium |
| **Shell script interpolation** | `FileCreate`/`FileSource` interpolate Rust strings into bash without escaping — safe with current hardcoded values, fragile if extended | Low |
| **No code signing** | Vorpal artifacts and output configs are not signed or verified beyond content-addressing | Low |

## 10. Recommendations

1. **Pin git dependencies to commit SHAs** — both `vorpal-artifacts` in `Cargo.toml` and `setup-vorpal-action` in the workflow
2. **Pin GitHub Actions to commit SHAs** — use `actions/checkout@<sha>` instead of `@v6`
3. **Add `cargo audit`** to CI to detect known vulnerabilities in dependencies
4. **Consider `cargo deny`** for license compliance and duplicate dependency detection
5. **Review automerge policy** — even stable minor versions can introduce behavioral changes
