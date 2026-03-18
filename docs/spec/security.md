---
project: "dotfiles.vorpal"
maturity: "draft"
last_updated: "2026-03-18"
updated_by: "@staff-engineer"
scope: "Security model, trust boundaries, secret management, and permission controls for the dotfiles configuration system"
owner: "@staff-engineer"
dependencies:
  - architecture.md
  - operations.md
---

# Security

This document describes the security characteristics of the dotfiles.vorpal project as they
actually exist in the codebase. The project is a declarative dotfiles manager that generates
configuration files and symlinks -- it does not run services, handle user authentication, or
process untrusted input at runtime. Its security profile is shaped primarily by supply chain
trust, CI secret management, filesystem permission boundaries, and the AI agent permission model
it configures.

## Trust Model

### Trust Boundaries

The system operates across four trust boundaries:

1. **Build-time (Vorpal runtime)**: The Rust binary executes as a Vorpal config, producing
   content-addressed artifacts in `/var/lib/vorpal/store/`. The Vorpal runtime is trusted to
   execute build steps in isolation and manage the artifact store. Build steps run shell scripts
   (`set -euo pipefail`) that write to `$VORPAL_OUTPUT` -- the Vorpal runtime controls what this
   path resolves to.

2. **CI environment (GitHub Actions)**: Workflows run on `macos-latest` runners and access AWS
   credentials via GitHub Secrets for S3-backed artifact registry. The CI boundary is where
   secrets are most exposed.

3. **Host filesystem (symlink deployment)**: Built artifacts are symlinked from the Vorpal store
   into the user's home directory (`~/.claude/`, `~/.config/`, `~/Library/Application Support/`).
   Once symlinked, configurations are live and affect the behavior of tools that read them.

4. **AI agent runtime (Claude Code / OpenCode)**: The generated `settings.json` defines
   permission boundaries for AI coding agents. This is the most security-sensitive output of the
   project, as it controls what an AI agent can read, write, and execute on the host.

### What Is Trusted

- The Vorpal SDK and `vorpal-artifacts` crate (pulled from GitHub `main` branch)
- The Vorpal runtime executing build steps
- The host user running `vorpal build`
- GitHub Actions runner environment
- AWS S3 for artifact registry storage
- External URLs fetched at build time (e.g., tokyonight theme from GitHub raw content)

### What Is NOT Trusted

- AI agent actions at runtime -- the entire Claude Code permission model exists to constrain
  what agents can do
- External theme/asset URLs -- fetched at build time but not cryptographically verified beyond
  content-addressing in the Vorpal store

## Secret Management

### Secrets in CI

The GitHub Actions workflow (`.github/workflows/vorpal.yaml`) uses two secrets:

| Secret | Purpose | Storage |
|--------|---------|---------|
| `AWS_ACCESS_KEY_ID` | S3 artifact registry authentication | GitHub Secrets |
| `AWS_SECRET_ACCESS_KEY` | S3 artifact registry authentication | GitHub Secrets |

Additionally, `AWS_DEFAULT_REGION` is stored as a GitHub Actions variable (not a secret).

These credentials are passed as environment variables to the `setup-vorpal-action` step and are
scoped to the CI runner's lifetime.

### Secrets in the Codebase

**No secrets are hardcoded in the codebase.** The project does not contain `.env` files, API
keys, tokens, or credentials in source code. The `.gitignore` excludes `/target` and `/.docket`
but does not explicitly list `.env` files (there are none to exclude).

### Secret Management Tools

The user environment includes [Doppler](https://www.doppler.com/) as a managed CLI tool,
indicating that secrets in the broader development workflow are managed externally via Doppler.
However, the dotfiles project itself does not configure or consume Doppler secrets -- it only
ensures the CLI binary is available.

### Claude Code API Key Helper

The `ClaudeCode` configuration struct supports an `api_key_helper` field that can specify an
external command to retrieve API keys. In the current configuration, this field is **not set**
(`None`). If used in the future, this would delegate credential retrieval to an external process
rather than storing keys in configuration.

## AI Agent Permission Model

The most security-significant output of this project is the Claude Code `settings.json`, which
defines a three-tier permission system controlling what AI agents can do on the host.

### Permission Tiers

**Allow (auto-approved):**
- Read-only bash commands: `ls`, `cat`, `head`, `tail`, `find`, `grep`, `rg`, `wc`, `tree`,
  `sort`, `test`, `jq`
- Build/test commands: `cargo build/check/clippy/fmt/test/tree/update/search/outdated/run`,
  `go build/test/vet/doc/list/mod tidy`, `bun run/test`, `npm run build/lint/test`,
  `yarn build/lint/test`, `npx tsc`, `make`, `gofmt`, `staticcheck`
- Git read operations: `git diff`, `git log`, `git status`, `git show`, `git remote get-url`,
  `git add`
- GitHub read operations: `gh pr diff`, `gh pr list`, `gh pr view`
- Container read operations: `docker images`, `docker logs`, `docker ps`
- Project tooling: `vorpal build`, `vorpal inspect`, `docket`, `cue`
- File operations: `chmod`, `tar`, `xargs`
- Web fetch: `api.github.com`, `crates.io`, `github.com` domains, plus general `WebSearch`

**Ask (requires user approval):**
- `chown`
- `git commit`
- `git push`
- `rm`

**Deny (blocked entirely):**
- Destructive git: `git checkout`, `git reset`
- Read access to sensitive paths: `.env`, `.env.*`, `.envrc`, `~/.aws/`, `~/.ssh/`,
  `~/.gnupg/`, `~/.kube/`, `~/.talos/`, `~/.doppler/`, `~/.netrc`, `~/.claude.json`,
  `~/.claude/`, `~/.codex/`, `~/.gemini/`, `~/.opencode/`, `~/.vorpal/`
- Write/edit access to: same sensitive paths as above, plus `/Applications/`, `/Library/`,
  `/System/`, `~/Desktop/`, `~/Downloads/`, `~/Library/`

### Sandbox Configuration

Claude Code sandboxing is **enabled** with the following settings:

- `auto_allow_bash_if_sandboxed`: true -- bash commands run inside the sandbox are auto-approved
- `allow_unsandboxed_commands`: true -- commands excluded from sandbox can still run (with
  permission checks)
- `excluded_commands`: `aws`, `docker`, `gh`, `git` -- these run outside the sandbox because they
  need network/credential access
- `network.allow_local_binding`: false -- agents cannot bind local network ports

### Permission Mode

- `default_mode`: `acceptEdits` -- file edits require explicit user acceptance
- `disable_bypass_permissions_mode`: `disable` -- agents cannot escalate their own permissions

### Gaps and Observations

- **`git add` is in the allow list** while `git commit` requires approval. This means agents can
  stage files freely but cannot commit without user consent.
- **`chmod` and `xargs` are auto-allowed.** These are powerful primitives -- `chmod` can change
  file permissions, and `xargs` can amplify other commands. The sandbox mitigates some risk here.
- **Sandbox exclusions for `aws`, `docker`, `gh`, `git`** mean these tools run outside the
  sandbox. The permission tiers (ask/deny) provide the only gate for these commands.
- **`WebSearch` is broadly allowed** without domain restrictions, meaning agents can fetch
  arbitrary web content for search purposes.

## OpenCode Permission Model

The OpenCode configuration uses a simpler permission model:

- **Default**: all bash commands require approval (`Ask`)
- **Allow**: read-only commands (`cat`, `echo`, `file`, `find`, `git branch`, `git log`, `grep`,
  `head`, `ls`, `sort`, `test`, `tree`, `wc`)
- **Allow**: `Glob`, `List`, `LSP`, `Read`, `WebFetch`
- **Ask**: `Edit`

This is more restrictive than the Claude Code configuration -- no build/test commands are
auto-approved, and all edits require approval.

## Build-Time Security

### Shell Script Generation

The `FileCreate`, `FileDownload`, and `FileSource` structs in `src/file.rs` generate shell
scripts that run during `vorpal build`. Key characteristics:

- All generated scripts use `set -euo pipefail` for strict error handling
- `FileCreate` uses a heredoc with `'EOF'` (single-quoted) delimiter, which prevents variable
  expansion in the content -- this is correct and prevents injection via content values
- `FileDownload` downloads from URLs specified in source code (not user input) -- currently
  only the tokyonight theme from a pinned GitHub release tag (`v4.14.1`)
- `FileSource` copies files from the project's own source tree into artifacts

### Content-Addressed Storage

All artifacts are stored in the Vorpal store at `/var/lib/vorpal/store/artifact/output/{namespace}/{digest}`.
The digest-based path provides content-addressing, meaning artifacts are immutable once built and
can be verified by their content hash.

### String Interpolation in Shell Scripts

The `name` and `path` fields in `FileCreate`, `FileDownload`, and `FileSource` are interpolated
into shell scripts via Rust's `formatdoc!` macro. These values originate from string literals in
the Rust source code (not from external input), so injection risk is low in the current design.
However, if these structs were ever used with dynamic/external input, the interpolation into shell
scripts would become an injection vector. There is no shell escaping applied to interpolated
values.

## Supply Chain

### Direct Dependencies

| Crate | Risk Notes |
|-------|-----------|
| `vorpal-sdk` (0.1.0-alpha.0) | Alpha release from crates.io. Pre-1.0 with breaking changes expected. |
| `vorpal-artifacts` (git, `main` branch) | Pinned to a branch, not a tag or commit hash. Changes on `main` are pulled automatically. |
| `anyhow`, `indoc`, `serde`, `serde_json`, `tokio` | Widely-used, well-maintained ecosystem crates. Low supply chain risk. |

### Dependency Update Policy (Renovate)

- **Auto-merge**: Minor and patch updates for stable crates (version >= 1.0)
- **Manual review**: Major updates, all pre-1.0 crate updates
- Custom tracking for the tokyonight theme URL in `src/user.rs`

### Observations

- **`vorpal-artifacts` tracks `main` branch**: This is a supply chain risk. Any push to the
  `main` branch of `artifacts.vorpal.git` is automatically incorporated. Since this is an
  ALT-F4-LLC internal repository, the risk is bounded by organizational trust, but pinning to a
  specific commit or tag would be more secure.
- **`vorpal-sdk` at alpha**: The `0.1.0-alpha.0` version signals instability. Breaking changes
  and security-relevant API changes may occur without major version bumps.
- **`setup-vorpal-action@main`**: The CI action also tracks `main` branch, not a pinned version.
  This is a CI supply chain risk -- a compromised action could access AWS secrets.

## Telemetry

The Claude Code configuration enables telemetry and sends data to external endpoints:

| Endpoint | Protocol | Purpose |
|----------|----------|---------|
| `https://loki.bulbasaur.altf4.domains/otlp/v1/logs` | HTTP/protobuf | Log export (OTLP) |
| `https://mimir.bulbasaur.altf4.domains/otlp/v1/metrics` | HTTP/protobuf | Metrics export (OTLP) |

These are ALT-F4-LLC internal observability endpoints. Telemetry is enabled explicitly via
`CLAUDE_CODE_ENABLE_TELEMETRY=1`. The export interval is 15 seconds for both logs and metrics.

**Note**: These endpoints are hardcoded in the Rust source. There is no mechanism to disable
telemetry without modifying and rebuilding the configuration.

## Filesystem Impact

The project creates symlinks from the Vorpal store into the user's home directory. The following
paths are written to (via symlink):

- `~/.claude/settings.json` -- AI agent permissions and configuration
- `~/.claude/agents/` -- Agent persona definitions
- `~/.claude/skills/` -- Agent skill definitions
- `~/.claude/statusline.sh` -- Executable shell script
- `~/.config/bat/config` and `~/.config/bat/themes/`
- `~/.config/nvim/after/ftplugin/markdown.vim`
- `~/.config/opencode/opencode.json`
- `~/Library/Application Support/com.mitchellh.ghostty/config`
- `~/Library/Application Support/k9s/skins/tokyo_night.yaml`
- `~/.vorpal/bin/vorpal` -- Symlink to a locally-built Vorpal binary

The `statusline.sh` script is the only executable artifact. It runs as part of Claude Code's
status line feature and has access to session JSON data passed via stdin. It writes a temporary
cache file to `/tmp/claude-statusline-git-cache-*` with a 5-second TTL.

## Gaps and Recommendations

### Current Gaps

1. **No `.env` in `.gitignore`**: While no `.env` files exist today, the `.gitignore` does not
   exclude them. If a contributor accidentally adds one, it would be committed.

2. **Unpinned git dependencies**: `vorpal-artifacts` tracks `main` branch and
   `setup-vorpal-action` tracks `main`. Both should ideally pin to specific commits or tags.

3. **No shell escaping in build scripts**: The `formatdoc!` interpolation in `src/file.rs` does
   not escape values for shell safety. Currently safe because all inputs are compile-time string
   literals, but fragile if the API surface expands.

4. **Temp file predictability**: The statusline script writes to `/tmp/claude-statusline-git-cache-{cksum}`
   which uses a deterministic cache key. On a shared system this could be a symlink attack vector,
   though the primary target is single-user macOS workstations.

5. **No SBOM or dependency audit pipeline**: There is no `cargo audit` or equivalent in CI to
   detect known vulnerabilities in dependencies.

6. **Telemetry cannot be toggled without rebuild**: The OTLP endpoints are hardcoded. A
   configuration flag or environment variable override would provide more operational flexibility.
