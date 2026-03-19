---
project: "dotfiles.vorpal"
maturity: "experimental"
last_updated: "2026-03-18"
updated_by: "@staff-engineer"
scope: "Deployment strategy, CI/CD pipelines, artifact registry, environment management, and operational procedures for the dotfiles.vorpal project"
owner: "@staff-engineer"
dependencies:
  - architecture.md
  - security.md
---

# Operations

## Overview

dotfiles.vorpal is a declarative dotfiles manager built on the Vorpal build system. It produces
content-addressed artifacts that are deployed to the local filesystem via symlinks into the Vorpal
store (`/var/lib/vorpal/store/`). The operational model is unusual compared to typical server-side
applications: there is no running service to monitor, no multi-environment deployment pipeline,
and no rollback in the traditional sense. Instead, "deployment" means building artifacts and
symlinking them onto a developer workstation.

The operational surface is:
- A GitHub Actions CI pipeline that validates builds on every push and PR
- An S3-backed remote artifact registry for caching built artifacts
- A local Vorpal runtime that executes builds on the developer's machine
- Renovate for automated dependency updates

## CI/CD Pipeline

### GitHub Actions Workflow

**File:** `.github/workflows/vorpal.yaml`

The project has a single workflow named `vorpal` with two jobs:

| Job | Trigger | Runner | Purpose |
|-----|---------|--------|---------|
| `build-dev` | Push to `main`, all PRs | `macos-latest` | Builds the `dev` artifact (Rust toolchain + Protoc) and uploads `Vorpal.lock` as a build artifact |
| `build` | After `build-dev` succeeds | `macos-latest` | Builds the `user` artifact using a matrix strategy (currently only `user`) |

Both jobs use the `ALT-F4-LLC/setup-vorpal-action@main` action to install the Vorpal runtime with
the `nightly` version channel. The action configures S3 as the registry backend with the bucket
`altf4llc-vorpal-registry`.

### Build Sequence

1. `build-dev` runs first, building the development toolchain (`vorpal build 'dev'`).
2. On success, it uploads the `Vorpal.lock` file as a GitHub Actions artifact (`$RUNNER_ARCH-$RUNNER_OS-vorpal-lock`).
3. `build` depends on `build-dev` and runs `vorpal build 'user'` for each matrix entry.

### Pipeline Gaps

- **No test job.** The pipeline only validates that artifacts build successfully. There is no
  test suite, linting step, or `cargo clippy`/`cargo fmt --check` gate.
- **No deployment step.** CI builds verify that the project compiles and artifacts can be
  produced, but deployment to the developer's machine is a manual local operation (`vorpal build 'user'`).
- **No build status badge or notifications.** Build failures are only visible in the GitHub
  Actions UI.
- **Nightly Vorpal version.** Both CI jobs pin to `version: nightly`, meaning CI builds can
  break due to upstream Vorpal changes without any change to this repository.
- **macOS-only CI.** The `SYSTEMS` constant in `src/lib.rs` declares support for four platforms
  (`Aarch64Darwin`, `Aarch64Linux`, `X8664Darwin`, `X8664Linux`), but CI only runs on
  `macos-latest`. Linux artifact builds are not validated in CI.
- **No lock file validation.** The `Vorpal.lock` is uploaded as an artifact but not compared
  against committed state or used by the `build` job.

## Artifact Registry

### Remote Cache

The project uses an S3-backed registry for artifact caching:

- **Bucket:** `altf4llc-vorpal-registry`
- **Region:** Configured via `AWS_DEFAULT_REGION` GitHub Actions variable
- **Authentication:** AWS access key credentials stored as GitHub Actions secrets (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`)

The Vorpal build system uses content-addressed storage. Each artifact is identified by a digest,
and artifacts are stored at paths like `/var/lib/vorpal/store/artifact/output/{namespace}/{digest}`.
The S3 registry enables sharing built artifacts between CI runs and (if credentials are available)
local builds.

### Local Store

On the developer's machine, Vorpal stores artifacts at `/var/lib/vorpal/store/`. The `user`
artifact creates symlinks from well-known home directory paths into this store (see
`src/user.rs:473-485` for the full symlink map).

## Deployment Model

### How Deployment Works

There is no server-side deployment. "Deploying" this project means running `vorpal build 'user'`
on the target machine. This:

1. Compiles the Rust binary (the Vorpal config program).
2. Executes the config program, which declares all artifacts and their build steps.
3. Vorpal resolves dependencies, builds artifacts (or fetches from the S3 cache), and writes
   outputs to the local store.
4. Symlinks are created from home directory locations to the store paths.

### Deployment Prerequisites

- Vorpal runtime must be installed on the host system.
- macOS on Apple Silicon (aarch64-darwin) is the primary supported platform.
- For remote cache access: AWS credentials must be configured locally.
- For building from source: The `dev` artifact must be built first (`vorpal build 'dev'`),
  which provides the Rust toolchain and Protoc.

### Rollback

There is no formal rollback procedure. Because Vorpal uses content-addressed storage:

- Previous artifact versions remain in the local store until garbage collected.
- Rolling back would require checking out a previous commit and re-running `vorpal build 'user'`.
- There is no `vorpal rollback` command or equivalent.
- Symlinks point to specific store paths, so they break if referenced artifacts are removed.

**Gap:** There is no documented or automated rollback procedure. No artifact versioning or
pinning mechanism is visible beyond the `Vorpal.lock` file.

## Dependency Management

### Renovate

**File:** `renovate.json`

Renovate is configured for automated dependency updates with the following rules:

| Rule | Scope | Behavior |
|------|-------|----------|
| Group serde updates | `serde`, `serde_json` | Grouped into a single PR |
| Automerge minor/patch | Stable crates (version >= 1.0) | Auto-merged without review |
| Manual review for major | All Cargo crates | Requires manual review |
| Track bat theme | `folke/tokyonight.nvim` GitHub releases | Custom regex manager tracking the raw GitHub URL in `src/user.rs` |

### Cargo Dependencies

The project has two notable dependency sources:

- **`vorpal-sdk`** (`0.1.0-alpha.0`): Published to a registry (crates.io or custom). Alpha version
  indicates the upstream SDK is not yet stable.
- **`vorpal-artifacts`**: Pinned to the `main` branch of `ALT-F4-LLC/artifacts.vorpal.git` via
  git dependency. This means any push to that repo's main branch can affect this project's builds.

**Risk:** Both core dependencies are pre-stable. Breaking changes in either can break builds
without warning. The `vorpal-artifacts` git branch pin is especially fragile.

## Monitoring and Observability

### Claude Code Telemetry

The project configures OpenTelemetry (OTEL) export for Claude Code sessions (see
`src/user.rs:94-113`):

| Signal | Endpoint | Protocol |
|--------|----------|----------|
| Logs | `https://loki.bulbasaur.altf4.domains/otlp/v1/logs` | HTTP/Protobuf |
| Metrics | `https://mimir.bulbasaur.altf4.domains/otlp/v1/metrics` | HTTP/Protobuf |

Export intervals are set to 15 seconds for both logs and metrics. Metrics use cumulative
temporality.

This telemetry is for Claude Code AI assistant sessions, not for the dotfiles project itself.

### Status Line

A bash status line script (`src/user/statusline.sh`) provides real-time session information in
the Claude Code terminal:

- Model name and agent identity
- Project directory and git branch with change counts
- Context window usage with color-coded progress bar
- Session cost, duration, and lines changed

The script uses a 5-second file-based cache for git info at `/tmp/claude-statusline-git-cache-*`.

### Gaps

- **No monitoring for the build system itself.** There is no alerting on CI failures, no build
  time tracking, no artifact size monitoring.
- **No health checks.** The symlinked artifacts are static files and configs; there is no
  mechanism to verify they are intact or that symlinks are not broken.
- **No audit trail.** Beyond git history and the `Vorpal.lock` file, there is no record of what
  was deployed to a machine or when.

## Environment Management

### Build Environments

The project defines two artifact environments:

| Environment | Purpose | Contents |
|-------------|---------|----------|
| `dev` | Development toolchain | Protoc, Rust toolchain (with `RUSTUP_HOME`, `RUSTUP_TOOLCHAIN`, `PATH` configured) |
| `user` | Full user environment | 16 CLI tools, config files, symlinks, environment variables (`EDITOR=nvim`, `GOPATH`, `PATH`) |

### Platform Support

The `SYSTEMS` constant declares four supported platforms:
- `Aarch64Darwin` (macOS Apple Silicon) -- primary target
- `Aarch64Linux`
- `X8664Darwin`
- `X8664Linux`

**Reality:** Only macOS is tested in CI. The README states macOS on Apple Silicon as the primary
supported platform. Linux and x86_64 support is declared but unvalidated.

## Operational Runbooks

**There are no operational runbooks.** The following procedures are undocumented:

- How to set up a new machine from scratch
- How to troubleshoot a failed build
- How to debug broken symlinks
- How to recover from a corrupted Vorpal store
- How to rotate AWS credentials for the S3 registry
- How to upgrade the Vorpal runtime version

The README provides basic build commands (`vorpal build 'dev'`, `vorpal build 'user'`) but no
troubleshooting guidance.

## Release Process

**There is no formal release process.** The project operates on a trunk-based model:

- All work lands on `main` via pull requests.
- CI validates builds on every push and PR.
- There are no version tags, release branches, or changelogs.
- The `Cargo.toml` version is `0.1.0`, which has not been updated.
- Deployment is manual: the developer runs `vorpal build 'user'` at their discretion.

## Infrastructure as Code

The project does not contain infrastructure definitions. The S3 bucket
(`altf4llc-vorpal-registry`) and the Grafana stack (Loki, Mimir at `*.bulbasaur.altf4.domains`)
are provisioned externally. Their configuration is not tracked in this repository.

## Summary of Operational Gaps

| Area | Status | Gap |
|------|--------|-----|
| CI/CD pipeline | Exists | No tests, no linting, no Linux CI, nightly Vorpal pin |
| Remote artifact cache | Exists | No cache eviction policy documented, no monitoring |
| Local deployment | Exists | Manual only, no automation or validation |
| Rollback | Missing | No documented procedure, depends on git checkout + rebuild |
| Monitoring | Partial | OTEL for Claude Code sessions only; no build/deploy monitoring |
| Runbooks | Missing | No operational runbooks exist |
| Release process | Missing | No versioning, tagging, or changelog |
| Dependency stability | At risk | Core dependencies are pre-stable alpha/git-branch pins |
| Multi-platform validation | Missing | Four platforms declared, one tested in CI |
