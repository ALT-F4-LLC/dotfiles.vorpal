---
project: "dotfiles.vorpal"
maturity: "experimental"
last_updated: "2026-03-18"
updated_by: "@staff-engineer"
scope: "Deployment strategy, CI/CD, artifact registry, observability, and operational concerns for the dotfiles.vorpal project"
owner: "@staff-engineer"
dependencies:
  - architecture.md
  - security.md
---

# Operations

## Overview

dotfiles.vorpal is a declarative dotfiles manager built on the Vorpal build system. It produces
content-addressed artifacts that define a complete user development environment (CLI tools,
configuration files, symlinks). The operational model is fundamentally different from a
traditional web service -- there is no running server, no database, and no user-facing API. The
"deployment" is a local build that materializes artifacts into `/var/lib/vorpal/store/` and
creates symlinks on the host filesystem.

## Build System

### Vorpal

The project uses [Vorpal](https://github.com/ALT-F4-LLC/vorpal) as its build system and artifact
manager. Vorpal is configured via two files:

- **`Vorpal.toml`** -- Declares the project language (`rust`) and source includes (`src`,
  `Cargo.toml`, `Cargo.lock`).
- **`Vorpal.lock`** -- Lockfile pinning all external source artifacts (CLI tool binaries, Rust
  toolchain components) to exact versions and SHA-256 digests. This file is generated during
  builds and uploaded as a CI artifact.

### Build Targets

The project defines two top-level build targets in `src/vorpal.rs`:

| Target | Purpose | Dependencies |
|--------|---------|--------------|
| `dev` | Development toolchain (Protoc, Rust toolchain) used to build the project itself | None |
| `user` | Full user environment: 16 CLI tools, configuration files, and filesystem symlinks | None (independent build) |

Build order: `vorpal build 'dev'` must succeed before `vorpal build 'user'` can run, because `dev`
provides the Rust toolchain needed to compile the project.

### Artifact Storage

- **Local store**: Built artifacts are stored in `/var/lib/vorpal/store/` on the host machine.
  Artifacts are content-addressed by digest.
- **Remote registry**: S3-backed remote cache at bucket `altf4llc-vorpal-registry`. This enables
  artifact sharing between CI and local builds, avoiding redundant compilation.

### Build Output

The `user` build produces symlinks from the host filesystem into the Vorpal store:

| Store Path | Host Symlink Target |
|------------|---------------------|
| bat config artifact | `~/.config/bat/config` |
| bat Tokyo Night theme | `~/.config/bat/themes/tokyonight.tmTheme` |
| Claude Code settings | `~/.claude/settings.json` |
| Agent definitions | `~/.claude/agents/` |
| Skill definitions | `~/.claude/skills/` |
| Status line script | `~/.claude/statusline.sh` |
| Ghostty config | `~/Library/Application Support/com.mitchellh.ghostty/config` |
| K9s skin | `~/Library/Application Support/k9s/skins/tokyo_night.yaml` |
| Neovim ftplugin | `~/.config/nvim/after/ftplugin/markdown.vim` |
| OpenCode config | `~/.config/opencode/opencode.json` |
| Vorpal binary (debug) | `~/.vorpal/bin/vorpal` |

The Vorpal binary symlink points to a local debug build of the Vorpal project at
`$HOME/Development/repository/github.com/ALT-F4-LLC/vorpal.git/main/target/debug/vorpal`,
indicating the developer builds Vorpal from source locally.

## CI/CD

### GitHub Actions Workflow

The project has a single CI workflow at `.github/workflows/vorpal.yaml`.

**Trigger conditions:**
- Push to `main` branch
- All pull requests

**Jobs:**

| Job | Runner | Steps | Depends On |
|-----|--------|-------|------------|
| `build-dev` | `macos-latest` | Checkout, setup Vorpal (nightly), `vorpal build 'dev'`, upload `Vorpal.lock` as artifact | None |
| `build` | `macos-latest` | Checkout, setup Vorpal (nightly), `vorpal build 'user'` | `build-dev` |

**Key details:**
- Uses `ALT-F4-LLC/setup-vorpal-action@main` to install Vorpal at `nightly` version.
- S3 registry backend is configured via `registry-backend: s3` with bucket
  `altf4llc-vorpal-registry`.
- AWS credentials are injected from GitHub Secrets (`AWS_ACCESS_KEY_ID`,
  `AWS_SECRET_ACCESS_KEY`) and Variables (`AWS_DEFAULT_REGION`).
- The `build` job uses a matrix strategy with a single artifact (`user`), suggesting the matrix
  may expand in the future.
- `Vorpal.lock` is uploaded as a GitHub Actions artifact named
  `${runner.arch}-${runner.os}-vorpal-lock`.

### What CI Does NOT Do

- **No deployment step.** CI validates that both `dev` and `user` targets build successfully but
  does not deploy or apply the resulting artifacts. The user must run `vorpal build 'user'`
  locally to apply changes.
- **No automated testing.** There are no test steps in the workflow, no `cargo test`, and no test
  files in the source tree. CI is purely a build validation gate.
- **No release process.** There are no release tags, no versioning automation, no changelog
  generation, and no GitHub Releases integration.
- **No multi-platform CI.** The workflow runs only on `macos-latest`. The codebase declares
  support for four systems (`Aarch64Darwin`, `Aarch64Linux`, `X8664Darwin`, `X8664Linux`) in
  `src/lib.rs`, but only macOS is validated in CI.

## Dependency Management

### Renovate

Automated dependency updates are managed by [Renovate](https://docs.renovatebot.com/) via
`renovate.json`:

- **Automerge**: Minor and patch updates for stable Cargo crates (version `>= 1.0.0`) are
  automerged automatically.
- **Manual review**: Major Cargo crate updates require manual review.
- **Grouped updates**: `serde` and `serde_json` are grouped into a single PR.
- **Custom manager**: A regex-based custom manager tracks the `tokyonight.nvim` bat theme version
  from a raw GitHub URL in `src/user.rs`, using the `github-releases` datasource.

### Vorpal.lock Pinning

All external tool binaries and Rust toolchain components are pinned in `Vorpal.lock` with exact
versions and SHA-256 digests. This provides full reproducibility -- a given lockfile always
produces the same artifact set.

## Observability

### Claude Code OpenTelemetry

The Claude Code configuration (`src/user.rs`) sets up OpenTelemetry export for logs and metrics:

| Signal | Endpoint | Protocol |
|--------|----------|----------|
| Logs | `https://loki.bulbasaur.altf4.domains/otlp/v1/logs` | `http/protobuf` |
| Metrics | `https://mimir.bulbasaur.altf4.domains/otlp/v1/metrics` | `http/protobuf` |

- Telemetry is enabled via `CLAUDE_CODE_ENABLE_TELEMETRY=1`.
- Both logs and metrics use a 15-second export interval (`OTEL_LOGS_EXPORT_INTERVAL=15000`,
  `OTEL_METRIC_EXPORT_INTERVAL=15000`).
- Metrics use cumulative temporality (`OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE=cumulative`).
- The endpoints suggest a Grafana stack (Loki for logs, Mimir for metrics) running on the
  `bulbasaur.altf4.domains` host.

### Claude Code Status Line

A custom status line script (`src/user/statusline.sh`) is deployed to `~/.claude/statusline.sh`
and executed via the Claude Code status bar. This provides at-a-glance operational context during
development sessions.

### Gaps

- **No tracing.** Only logs and metrics are exported; there is no distributed tracing
  configuration (no `OTEL_EXPORTER_OTLP_TRACES_ENDPOINT`).
- **No alerting.** There is no alerting configuration in this project. Alerting, if any, would
  be configured on the receiving Grafana stack, which is outside this project's scope.
- **No build metrics.** Vorpal build times and artifact cache hit rates are not tracked.
- **No health checks.** Not applicable -- this project produces static artifacts, not a running
  service.

## Rollback Strategy

### How Rollback Works

Because artifacts are content-addressed and stored in `/var/lib/vorpal/store/`, rollback is
straightforward:

1. `git checkout <previous-commit>` to get the prior version of the Rust source.
2. `vorpal build 'user'` to rebuild. If the previous artifacts are still in the local or remote
   cache, the build will be near-instant (cache hit).
3. Symlinks are re-pointed to the previous artifact digests.

### Limitations

- There is no automated rollback mechanism. The user must manually check out a previous commit and
  rebuild.
- Old artifacts in the local store are not automatically garbage collected. There is no documented
  retention policy for `/var/lib/vorpal/store/`.
- If the S3 remote cache has been cleaned or the artifact has been evicted, rollback requires a
  full rebuild from source.

## Environment Management

### Supported Platforms

The code declares support for four platforms in `src/lib.rs`:

| Platform | CI Coverage | Notes |
|----------|-------------|-------|
| `aarch64-darwin` | Yes (`macos-latest`) | Primary development platform (Apple Silicon) |
| `aarch64-linux` | No | Declared but not validated |
| `x86_64-darwin` | No | Declared but not validated |
| `x86_64-linux` | No | Declared but not validated |

### Environment Variables

The `user` build sets these environment variables in the user's shell environment:

| Variable | Value |
|----------|-------|
| `EDITOR` | `nvim` |
| `GOPATH` | `$HOME/Development/language/go` |
| `PATH` | Prepends VMware Fusion, `$GOPATH/bin`, `~/.opencode/bin`, `~/.vorpal/bin`, `~/.local/bin` |

### Prerequisites

- Vorpal runtime must be installed on the host system.
- AWS credentials must be configured for S3 registry access (both CI and local builds).
- macOS on Apple Silicon is the primary supported platform.

## Operational Runbooks

There are no operational runbooks in the project. Given the nature of the project (developer
dotfiles, not a production service), runbooks are not strictly necessary, but the following
procedures would be useful to document:

- **How to set up a new machine from scratch**: Install Vorpal, configure AWS credentials, run
  initial build.
- **How to debug a failed build**: Common Vorpal build failures, S3 connectivity issues, artifact
  cache misses.
- **How to add a new CLI tool**: Pattern for adding a new tool artifact and its symlink.
- **How to add a new configuration generator**: Pattern for creating a new builder struct.

## Gaps and Recommendations

| Gap | Impact | Recommendation |
|-----|--------|----------------|
| No automated tests in CI | Build correctness is validated only by "does it compile" | Add `cargo test` and `cargo clippy` steps to the CI workflow |
| No multi-platform CI | Linux and x86_64 platforms are declared but never validated | Add CI matrix for at least `aarch64-linux` if those platforms are intended to work |
| No release process | No versioning, tagging, or changelog | Consider semver tags and GitHub Releases for tracking environment versions |
| No artifact garbage collection | Local store grows unbounded | Document or automate a pruning strategy for `/var/lib/vorpal/store/` |
| No tracing in observability stack | Logs and metrics only | Add `OTEL_EXPORTER_OTLP_TRACES_ENDPOINT` if trace-level debugging of Claude Code sessions is desired |
| No onboarding runbook | New machine setup is undocumented | Write a getting-started guide covering Vorpal installation, AWS credential setup, and first build |
