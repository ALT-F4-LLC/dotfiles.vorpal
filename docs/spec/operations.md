# Operations

> How this project is built, deployed, updated, and operated.

This document describes the operational characteristics of the `dotfiles.vorpal` project as they
actually exist in the codebase today.

---

## Project Overview

This is a **Vorpal-based dotfiles management project** -- a Rust codebase that declaratively defines
a developer environment as reproducible artifacts. It is not a deployed service; it is a build-time
configuration system that produces a user environment (tools, configs, symlinks) via the Vorpal
package manager.

The "deployment target" is a local developer workstation, not a server or cluster.

---

## Build System

### Vorpal

The project uses [Vorpal](https://github.com/ALT-F4-LLC/vorpal) as its primary build and package
management system. Vorpal is a content-addressable artifact build system.

**Configuration files:**
- `Vorpal.toml` -- Project configuration declaring Rust as the language and `src/`, `Cargo.toml`,
  `Cargo.lock` as source includes.
- `Vorpal.lock` -- Lock file pinning all external artifact sources with cryptographic digests
  (SHA-256). Contains exact versions and URLs for ~30+ tools and dependencies.

**Build artifacts:**
- `dev` -- Development environment artifact providing protoc and Rust toolchain for building the
  project itself.
- `user` -- User environment artifact containing all developer tools, configuration files, and
  symlinks for the end-user workstation.

**Build commands:**
- `vorpal build 'dev'` -- Builds the development environment.
- `vorpal build 'user'` -- Builds the full user environment with all tools and configs.

**Artifact store:**
- Artifacts are stored at `/var/lib/vorpal/store/artifact/output/{namespace}/{digest}`.
- Content-addressed by digest, enabling reproducibility and caching.

### Rust / Cargo

The underlying language is Rust (edition 2021). The Rust build is orchestrated through Vorpal, not
directly via `cargo` in CI.

**Dependencies (from `Cargo.toml`):**
- `anyhow` -- Error handling
- `indoc` -- Indented string formatting
- `serde` / `serde_json` -- Serialization for config file generation
- `tokio` -- Async runtime (multi-threaded)
- `vorpal-artifacts` -- Artifact definitions (from `ALT-F4-LLC/artifacts.vorpal.git`)
- `vorpal-sdk` -- Vorpal SDK for building artifacts (from `ALT-F4-LLC/vorpal.git`)

---

## CI/CD Pipeline

### GitHub Actions

A single workflow file exists at `.github/workflows/vorpal.yaml`.

**Trigger conditions:**
- `pull_request` -- All pull requests (any branch)
- `push` to `main` -- Every push to the main branch

**Jobs:**

#### `build-dev`
- **Runner:** `macos-latest`
- **Steps:**
  1. Checkout repository (`actions/checkout@v6`)
  2. Setup Vorpal (`ALT-F4-LLC/setup-vorpal-action@main`) with S3 registry backend
  3. Run `vorpal build 'dev'`
  4. Upload `Vorpal.lock` as artifact (`actions/upload-artifact@v6`, named
     `{arch}-{os}-vorpal-lock`)

#### `build`
- **Runner:** `macos-latest`
- **Depends on:** `build-dev`
- **Strategy:** Matrix over `artifact: [user]`
- **Steps:**
  1. Checkout repository
  2. Setup Vorpal with S3 registry backend
  3. Run `vorpal build '${{ matrix.artifact }}'`

**Registry backend:**
- Type: S3
- Bucket: `altf4llc-vorpal-registry`
- Authentication: AWS credentials via GitHub Secrets (`AWS_ACCESS_KEY_ID`,
  `AWS_SECRET_ACCESS_KEY`) and Variables (`AWS_DEFAULT_REGION`)

**Platform coverage:**
- CI currently runs on `macos-latest` only.
- The codebase declares support for 4 systems: `Aarch64Darwin`, `Aarch64Linux`, `X8664Darwin`,
  `X8664Linux` (defined in `src/lib.rs:9`).
- **Gap:** No Linux CI runners are configured. Linux builds are declared but not validated in CI.

### No CD Pipeline

There is no continuous deployment pipeline. This is expected -- the project produces a local
developer environment, not a deployed service. The "deployment" is running `vorpal build 'user'`
on a developer workstation.

---

## Dependency Management

### Renovate

Automated dependency updates are configured via `renovate.json`.

**Configuration:**
- Extends `config:recommended` (Renovate's recommended base config)
- **Serde ecosystem grouping:** `serde` and `serde_json` Cargo crate updates are grouped together
- **Automerge policy:**
  - Minor and patch updates for stable crates (version >= 1.0) are automerged
  - Major updates require manual review
- **Custom manager:** Tracks `tokyonight.nvim` bat theme version from raw GitHub URLs in
  `src/user.rs` via regex extraction from `raw.githubusercontent.com` URLs

### Vorpal.lock Pinning

All external tool sources in `Vorpal.lock` are pinned by:
- Exact version in the download URL
- SHA-256 digest for integrity verification
- Platform specification (`aarch64-darwin` for current entries)

**Currently pinned tools (partial list):**
awscli2, bat, cargo, clippy, direnv, doppler, fd, gh, git, go, gopls, jj, jq, k9s, kubectl,
lazygit, libevent, ncurses, nnn, pkg-config, protoc, readline, ripgrep, rust-analyzer, rust-src,
rust-std, rustc, rustfmt, tmux.

**Gap:** Renovate does not currently manage Vorpal.lock entries. Tool version updates in
Vorpal.lock appear to be manual.

---

## Observability

### OpenTelemetry (Claude Code)

The project configures OpenTelemetry (OTEL) environment variables for Claude Code sessions,
enabling telemetry export to external backends.

**Configured endpoints (from `src/user.rs:97-113`):**

| Signal  | Endpoint                                                  | Protocol       |
|---------|----------------------------------------------------------|----------------|
| Logs    | `https://loki.bulbasaur.altf4.domains/otlp/v1/logs`     | http/protobuf  |
| Metrics | `https://mimir.bulbasaur.altf4.domains/otlp/v1/metrics`  | http/protobuf  |

**Export intervals:** 15,000ms (15 seconds) for both logs and metrics.
**Metrics temporality:** Cumulative.

This telemetry covers Claude Code agent session data (usage, costs, context window, duration),
not the dotfiles build system itself.

### Claude Code Status Line

A custom status line script (`src/user/statusline.sh`) provides real-time session observability
within the terminal. It displays:
- Model name and agent name
- Project directory and Git branch status (staged/modified files)
- Context window usage percentage with color-coded progress bar
- Session cost (USD)
- Session duration
- Lines added/removed

Git info is cached in `/tmp/claude-statusline-git-cache-*` with a 5-second TTL.

### Build System Observability

**Gap:** No monitoring, alerting, or observability exists for the Vorpal build process itself.
Build failures are only visible through GitHub Actions workflow status. There are no:
- Build time tracking or trending
- Cache hit/miss metrics for the S3 registry
- Alerting on build failures
- Artifact size tracking

---

## Environment Management

### Developer Workstation Setup

The `user` artifact produces a complete developer environment via symlinks:

| Source (Vorpal artifact output)           | Target (user filesystem)                                         |
|-------------------------------------------|------------------------------------------------------------------|
| Local Vorpal debug binary                 | `$HOME/.vorpal/bin/vorpal`                                       |
| bat config                                | `$HOME/.config/bat/config`                                       |
| bat theme                                 | `$HOME/.config/bat/themes/tokyonight.tmTheme`                    |
| Claude Code agents                        | `$HOME/.claude/agents`                                           |
| Claude Code settings                      | `$HOME/.claude/settings.json`                                    |
| Claude Code skills                        | `$HOME/.claude/skills`                                           |
| Claude Code statusline                    | `$HOME/.claude/statusline.sh`                                    |
| Ghostty config                            | `$HOME/Library/Application Support/com.mitchellh.ghostty/config` |
| K9s skin                                  | `$HOME/Library/Application Support/k9s/skins/tokyo_night.yaml`   |
| Markdown vim config                       | `$HOME/.config/nvim/after/ftplugin/markdown.vim`                 |
| Opencode config                           | `$HOME/.config/opencode/opencode.json`                           |

**Environment variables set:**
- `EDITOR=nvim`
- `GOPATH=$HOME/Development/language/go`
- `PATH` includes VMware Fusion, Go bin, opencode bin, Vorpal bin, and local bin

### direnv

The project uses `direnv` for local environment management. The `.envrc` file exists but its
contents were not accessible during this analysis.

---

## Release Process

### Current Process

There is no formal release process. The project operates on a trunk-based development model:

1. Changes are made on feature branches.
2. Pull requests trigger CI (build-dev + build).
3. Merges to `main` trigger CI again.
4. No Git tags or releases exist.
5. No versioning scheme beyond `Cargo.toml` version `0.1.0`.

The "release" is implicit -- merging to `main` means the latest `main` is the current version.
Users rebuild their environment by running `vorpal build 'user'` against `main`.

### Rollback

**Rollback strategy:** Git revert or checkout a previous commit, then rebuild with
`vorpal build 'user'`.

Vorpal's content-addressable store means previous artifact outputs persist locally until cleaned.
Rolling back to a previous commit and rebuilding should produce identical artifacts thanks to
digest-pinned sources in `Vorpal.lock`.

**Gap:** No automated rollback mechanism exists. No "last known good" artifact tracking.

---

## Infrastructure

### S3 Registry

The Vorpal artifact registry uses AWS S3 as its backend:
- **Bucket:** `altf4llc-vorpal-registry`
- **Purpose:** Caching built artifacts to avoid redundant rebuilds
- **Authentication:** AWS IAM credentials stored as GitHub Secrets

### External Services

| Service                        | Purpose                          | Used By         |
|--------------------------------|----------------------------------|-----------------|
| AWS S3                         | Vorpal artifact registry/cache   | CI + local      |
| Loki (bulbasaur.altf4.domains) | Log aggregation                  | Claude Code     |
| Mimir (bulbasaur.altf4.domains)| Metrics storage                  | Claude Code     |
| GitHub                         | Source control, CI, dependency PRs| Everything     |

---

## Operational Gaps

The following operational capabilities are absent. This is partially expected given the project
is a local development environment tool, not a production service.

| Area                        | Status  | Notes                                                   |
|-----------------------------|---------|----------------------------------------------------------|
| Linux CI validation         | Missing | Code declares 4 platforms but CI only tests macOS        |
| Vorpal.lock auto-updates    | Missing | Renovate does not manage Vorpal.lock tool versions       |
| Build metrics/trending      | Missing | No tracking of build times, cache hit rates, artifact sizes |
| Automated rollback          | Missing | Manual git revert + rebuild required                     |
| Health checks               | N/A     | Not applicable (not a running service)                   |
| Alerting                    | Missing | No alerts on CI failures beyond GitHub defaults          |
| Runbooks                    | Missing | No operational runbooks exist                            |
| Disaster recovery           | Minimal | S3 bucket loss would require full artifact rebuilds      |
| Secret rotation             | Missing | No automated rotation for AWS credentials                |
| Vorpal.lock integrity CI    | Missing | No CI step validates Vorpal.lock digests match downloads |

---

## Commit Convention

The project follows [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(scope): description    -- New feature
fix(scope): description     -- Bug fix
chore(scope): description   -- Maintenance
```

Common scopes observed: `agents`, `skills`, `user`, `claude-code`, `deps`, `staff-engineer`,
`vorpal`, `file`.
