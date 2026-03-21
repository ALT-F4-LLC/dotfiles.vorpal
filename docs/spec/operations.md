---
project: "dotfiles.vorpal"
maturity: "experimental"
last_updated: "2026-03-21"
updated_by: "@staff-engineer"
scope: "Build pipeline, CI/CD, deployment model, observability, dependency management, and operational runbooks"
owner: "@staff-engineer"
dependencies:
  - architecture.md
  - security.md
---

# Operations

## 1. Build System

### Vorpal Build Pipeline

The project uses the [Vorpal](https://github.com/ALT-F4-LLC/vorpal) build system exclusively. All artifacts are defined as Rust code in `src/` and compiled into content-addressed, reproducible artifacts stored in `/var/lib/vorpal/store/`.

**Two top-level artifacts:**

| Artifact | Purpose | Command |
|----------|---------|---------|
| `dev` | Development toolchain (Protoc + Rust toolchain) needed to build the project itself | `vorpal build 'dev'` |
| `user` | Full user environment — 16 CLI tools, config files, agent definitions, skills, symlinks | `vorpal build 'user'` |

Build order is sequential: `dev` must complete before `user` can be built. This dependency is enforced in CI via the `needs` directive.

### Source Configuration

Defined in `Vorpal.toml`:

```toml
language = "rust"

[source]
includes = ["src", "Cargo.toml", "Cargo.lock"]
```

Only the `src/`, `Cargo.toml`, and `Cargo.lock` files are included in the build context. Agent definitions (`agents/`) and skill definitions (`skills/`) are included separately via `FileSource` artifacts that copy directory contents into the Vorpal store.

### Artifact Storage

- **Local store:** `/var/lib/vorpal/store/artifact/output/{namespace}/{digest}`
- **Remote cache:** S3-backed registry at `altf4llc-vorpal-registry` bucket
- **Content addressing:** All artifacts are identified by digest, enabling deduplication and cache hits across builds
- **Lockfile:** `Vorpal.lock` records source URLs, digests, and platform for all external dependencies (currently 29 sources for `aarch64-darwin`)

### Supported Platforms

The code declares support for four platforms in `src/lib.rs`:

```
Aarch64Darwin, Aarch64Linux, X8664Darwin, X8664Linux
```

However, `Vorpal.lock` currently only contains sources for `aarch64-darwin`. CI only runs on `macos-latest`. **Linux and x86_64 platforms are declared but not exercised.**

## 2. CI/CD

### GitHub Actions Workflow

Single workflow file: `.github/workflows/vorpal.yaml`

**Trigger events:**
- Push to `main`
- Pull requests (all branches)

**Jobs:**

| Job | Runner | Depends On | Steps |
|-----|--------|------------|-------|
| `build-dev` | `macos-latest` | — | Checkout, setup Vorpal (nightly, S3 registry), `vorpal build 'dev'`, upload `Vorpal.lock` as artifact |
| `build` | `macos-latest` | `build-dev` | Checkout, setup Vorpal (nightly, S3 registry), `vorpal build 'user'` (matrix: `[user]`) |

**Setup action:** `ALT-F4-LLC/setup-vorpal-action@main` configures the Vorpal runtime with:
- `version: nightly` — tracks the latest Vorpal build
- `registry-backend: s3` with `registry-backend-s3-bucket: altf4llc-vorpal-registry`

**Secrets/variables used:**
- `AWS_ACCESS_KEY_ID` (secret)
- `AWS_SECRET_ACCESS_KEY` (secret)
- `AWS_DEFAULT_REGION` (variable)

### What CI Does NOT Do

- **No deployment step.** CI validates that artifacts build successfully but does not deploy them to a target machine. Deployment is a local operation (`vorpal build 'user'` on the target host).
- **No automated testing.** There are no test suites, linters, or formatters in the CI pipeline. `cargo test` is not run.
- **No release tagging or versioning.** The project is at `0.1.0` with no release automation.
- **No branch protection rules visible** in the repository configuration files (these may exist in GitHub settings but are not codified here).

### Artifact Upload

The `build-dev` job uploads `Vorpal.lock` as a GitHub Actions artifact (`{runner.arch}-{runner.os}-vorpal-lock`). This preserves the lockfile state from the dev build but is not consumed by downstream jobs in the current workflow.

## 3. Deployment Model

### Local Deployment

This is a dotfiles project. "Deployment" means running `vorpal build 'user'` on the developer's machine, which:

1. Builds all 16 CLI tools and configuration artifacts into `/var/lib/vorpal/store/`
2. Creates symlinks from well-known paths (e.g., `~/.config/bat/config`, `~/.claude/settings.json`) into the Vorpal store
3. Sets environment variables via the user environment shell integration (`EDITOR=nvim`, `GOPATH`, `PATH` additions)

There is no remote deployment target, no staging environment, and no multi-machine fleet. The blast radius of any change is a single developer workstation.

### Symlink Layout

All configuration is deployed via symlinks (defined in `src/user.rs` lines 473-485):

| Store Artifact | Host Path |
|---|---|
| Vorpal binary | `~/.vorpal/bin/vorpal` |
| Bat config | `~/.config/bat/config` |
| Bat Tokyo Night theme | `~/.config/bat/themes/tokyonight.tmTheme` |
| Claude Code agents | `~/.claude/agents/` |
| Claude Code settings | `~/.claude/settings.json` |
| Claude Code skills | `~/.claude/skills/` |
| Claude Code statusline | `~/.claude/statusline.sh` |
| Ghostty config | `~/Library/Application Support/com.mitchellh.ghostty/config` |
| K9s skin | `~/Library/Application Support/k9s/skins/tokyo_night.yaml` |
| Neovim markdown ftplugin | `~/.config/nvim/after/ftplugin/markdown.vim` |
| OpenCode config | `~/.config/opencode/opencode.json` |

### Rollback

Rollback is implicit via content addressing. Previous artifact digests remain in the Vorpal store. To roll back:
1. Check out the previous commit
2. Run `vorpal build 'user'` — the lockfile will reference the previous source digests, and cached artifacts will be used if still in the store

**Gap:** There is no explicit rollback command or mechanism to restore a previous environment state without checking out a prior commit. Old artifacts may be garbage-collected from the local store (this depends on Vorpal's store management, which is external to this project).

## 4. Observability

### Telemetry Configuration

Claude Code telemetry is configured via OpenTelemetry environment variables in `src/user.rs` (lines 93-112):

| Signal | Endpoint | Protocol |
|--------|----------|----------|
| Logs | `https://loki.bulbasaur.altf4.domains/otlp/v1/logs` | `http/protobuf` |
| Metrics | `https://mimir.bulbasaur.altf4.domains/otlp/v1/metrics` | `http/protobuf` |

**Export intervals:** Both logs and metrics use 15-second export intervals (`OTEL_LOGS_EXPORT_INTERVAL=15000`, `OTEL_METRIC_EXPORT_INTERVAL=15000`).

**Metrics temporality:** Cumulative (`OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE=cumulative`).

**Telemetry flag:** `CLAUDE_CODE_ENABLE_TELEMETRY=1`

### Status Line

A Bash status line script (`src/user/statusline.sh`) provides real-time session observability in the Claude Code terminal:

- Model name and agent name
- Project directory and git branch with staged/modified file counts
- Context window usage (percentage with color-coded progress bar: green < 70%, yellow 70-89%, red >= 90%)
- Session cost in USD
- Session duration
- Lines added/removed

The script uses a 5-second file-based cache (`/tmp/claude-statusline-git-cache-*`) for git info to avoid repeated subprocess calls.

### What Is NOT Observed

- **No application-level monitoring.** This is a build-time project with no long-running services.
- **No CI pipeline monitoring or alerting.** Build failures are only visible in the GitHub Actions UI.
- **No artifact store health monitoring.** No alerts for S3 cache availability or local store disk usage.
- **No tracing.** Only logs and metrics are configured; traces are not exported.

## 5. Dependency Management

### Rust Dependencies

Managed via `Cargo.toml` and `Cargo.lock`:

| Dependency | Version | Purpose |
|------------|---------|---------|
| `vorpal-sdk` | `0.1.0-alpha.0` (crates.io) | Core Vorpal SDK |
| `vorpal-artifacts` | git branch `main` | Pre-built artifact types for CLI tools |
| `anyhow` | `1` | Error handling |
| `indoc` | `2` | Indented string literals |
| `serde` + `serde_json` | `1.0.228` / `1.0.148` | JSON serialization |
| `tokio` | `1` (rt-multi-thread) | Async runtime |

**Risk:** `vorpal-artifacts` is pinned to the `main` branch of a git repository, not a versioned release. Any breaking change on that branch will break builds.

### Renovate Bot

Automated dependency updates via `renovate.json`:

- **Cargo minor/patch on stable crates:** Auto-merged (crates with version >= 1.0)
- **Cargo major updates:** Manual review required
- **Serde ecosystem:** Grouped updates (`serde` + `serde_json` together)
- **Custom manager:** Tracks `folke/tokyonight.nvim` GitHub releases for the bat theme URL in `src/user.rs`

### External Tool Versions

All 29 external tool sources are pinned by URL and SHA-256 digest in `Vorpal.lock`. Version bumps require updating both the URL and digest. Renovate does not manage these — they must be updated manually or via a custom process.

## 6. Environment Management

### direnv Integration

The project uses direnv (`.envrc` exists but is not readable due to permissions). The `.envrc` likely loads the Vorpal development environment, given that `direnv` is included in the managed tool set and `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` is set in the Claude Code configuration.

### Environment Variables Set by the User Artifact

Defined in `src/user.rs` (lines 468-471):

```
EDITOR=nvim
GOPATH=$HOME/Development/language/go
PATH=/Applications/VMware Fusion.app/Contents/Library:$GOPATH/bin:$HOME/.opencode/bin:$HOME/.vorpal/bin:$HOME/.local/bin:$PATH
```

### Secrets

No secrets are stored in the repository. CI secrets (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`) are managed via GitHub Actions secrets/variables. The `doppler` CLI is included in the tool set, suggesting that Doppler is used for runtime secrets management in other contexts.

## 7. Operational Gaps

| Gap | Impact | Recommendation |
|-----|--------|----------------|
| No automated tests in CI | Rust compilation errors caught by build, but logic errors and regressions not detected | Add `cargo test`, `cargo clippy`, and `cargo fmt --check` to the CI workflow |
| No Linux CI runner | Linux platform support declared in code but never validated | Add a Linux runner to the GitHub Actions matrix or remove Linux platform declarations |
| `vorpal-artifacts` pinned to `main` branch | Upstream breaking changes cause immediate build failures | Pin to a tagged release or specific commit SHA |
| No Vorpal store garbage collection | Local store grows unbounded over time | Document or automate periodic cleanup of `/var/lib/vorpal/store/` |
| No CI notification/alerting | Build failures only visible via GitHub UI | Add Slack/email notifications for failed builds on `main` |
| Vorpal `nightly` version in CI | CI uses an unpinned Vorpal runtime version | Pin to a specific Vorpal release for reproducible CI |
| No lockfile validation | `Vorpal.lock` upload in CI is not consumed or validated | Either remove the upload step or add a lockfile comparison step |
| No operational runbooks | No documented procedures for common operational tasks | Create runbooks for: initial setup, adding a new tool, updating tool versions, troubleshooting build failures |
