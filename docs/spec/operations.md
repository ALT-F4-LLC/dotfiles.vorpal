---
project: "dotfiles.vorpal"
maturity: "experimental"
last_updated: "2026-03-18"
updated_by: "@staff-engineer"
scope: "Deployment strategy, build pipeline, observability, environment management, and operational procedures for dotfiles.vorpal"
owner: "@staff-engineer"
dependencies:
  - architecture.md
  - security.md
---

# Operations

## Build System

The project uses the [Vorpal](https://github.com/ALT-F4-LLC/vorpal) build system to produce
content-addressed, reproducible artifacts. All environment components -- CLI tools, configuration
files, themes, and symlinks -- are defined as a Rust program (`src/vorpal.rs`) that Vorpal
evaluates to produce deterministic outputs.

### Build Artifacts

Two top-level artifacts are produced:

| Artifact | Purpose | Dependencies |
|----------|---------|--------------|
| `dev` | Development toolchain (Protoc + Rust toolchain) used to build the project itself | None |
| `user` | Full user environment: 16 CLI tools, config files, agent definitions, symlinks | None (built independently, but logically depends on `dev` for the Rust build step) |

### Build Commands

```bash
# Build the development toolchain
vorpal build 'dev'

# Build the full user environment
vorpal build 'user'
```

Both commands invoke the Vorpal runtime, which compiles the Rust source, evaluates the artifact
graph, downloads sources per `Vorpal.lock`, builds each artifact in an isolated step, and stores
outputs in `/var/lib/vorpal/store/artifact/output/<namespace>/<digest>`.

### Artifact Store

All built artifacts are stored in the Vorpal content-addressed store at:

```
/var/lib/vorpal/store/artifact/output/{namespace}/{digest}
```

Where `namespace` is either `library` (for configuration artifacts) or another category, and
`digest` is the content hash. This provides inherent deduplication and reproducibility.

### Lockfile

`Vorpal.lock` pins all external source downloads (CLI tool binaries, themes, toolchains) with
SHA-256 content digests and explicit platform tags (`aarch64-darwin`). The lockfile currently
contains 30+ pinned sources.

`Vorpal.toml` declares the project language (`rust`) and source includes (`src`, `Cargo.toml`,
`Cargo.lock`).

---

## CI/CD Pipeline

### GitHub Actions Workflow

A single workflow file at `.github/workflows/vorpal.yaml` runs on:
- Every push to `main`
- Every pull request

The workflow defines two jobs:

#### Job 1: `build-dev`
- **Runner**: `macos-latest`
- **Steps**:
  1. Checkout code (`actions/checkout@v6`)
  2. Set up Vorpal via `ALT-F4-LLC/setup-vorpal-action@main` with S3 registry backend
  3. Run `vorpal build 'dev'`
  4. Upload `Vorpal.lock` as a build artifact (`actions/upload-artifact@v6`)
- **Secrets required**: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
- **Variables required**: `AWS_DEFAULT_REGION`

#### Job 2: `build`
- **Runner**: `macos-latest`
- **Depends on**: `build-dev`
- **Strategy**: Matrix over `artifact: [user]`
- **Steps**:
  1. Checkout code
  2. Set up Vorpal with same S3 registry configuration
  3. Run `vorpal build '${{ matrix.artifact }}'`
- **Same secrets/variables as `build-dev`**

### Remote Cache (S3 Registry)

Both CI jobs configure Vorpal with an S3-backed remote artifact registry:
- **Bucket**: `altf4llc-vorpal-registry`
- **Backend type**: `s3`
- **Vorpal version**: `nightly`

This enables build artifact caching across CI runs. When an artifact's content hash already
exists in the S3 registry, Vorpal reuses it instead of rebuilding.

### What CI Does NOT Do

- **No deployment step**: The workflow validates that `dev` and `user` artifacts build
  successfully. There is no automated deployment to end-user machines.
- **No test step**: There are no test commands in the CI pipeline. The build itself is the
  primary validation.
- **No linting step**: No `cargo clippy`, `cargo fmt --check`, or other lint checks in CI.
- **No release/tag process**: No release automation, changelogs, or versioning workflow exists.
- **No multi-platform matrix**: CI only runs on `macos-latest`. Despite the code declaring
  support for four systems (`Aarch64Darwin`, `Aarch64Linux`, `X8664Darwin`, `X8664Linux`), CI
  only validates the macOS build.

---

## Dependency Management

### Rust Dependencies (Cargo)

Managed via `Cargo.toml` and `Cargo.lock`. Key dependencies:
- `vorpal-sdk` (from crates.io, `0.1.0-alpha.0`)
- `vorpal-artifacts` (from Git, `ALT-F4-LLC/artifacts.vorpal.git`, branch `main`)
- `anyhow`, `indoc`, `serde`, `serde_json`, `tokio`

### Automated Updates (Renovate)

[Renovate](https://docs.renovatebot.com/) is configured in `renovate.json` with these rules:

| Rule | Scope | Behavior |
|------|-------|----------|
| Serde grouping | `serde`, `serde_json` | Grouped into a single PR |
| Auto-merge minor/patch | Stable Cargo crates (version >= 1.0) | Auto-merged |
| Manual review for major | All Cargo crates | Requires human approval |
| Custom: tokyonight theme | `folke/tokyonight.nvim` GitHub releases | Tracked via regex in `src/user.rs` |

### External Tool Sources (Vorpal.lock)

The 30+ CLI tool binaries and source archives pinned in `Vorpal.lock` are not managed by
Renovate. Version bumps to these sources require manual updates to the Rust source code and
re-running `vorpal build` to regenerate the lockfile.

**Gap**: No automated process exists to detect when new versions of pinned CLI tools are
available. Updates depend on manual awareness.

---

## Deployment Model

This project follows a **local build, local deploy** model. There is no remote deployment target
or fleet management.

### How Deployment Works

1. Developer runs `vorpal build 'user'` on their local machine.
2. Vorpal builds all artifacts into `/var/lib/vorpal/store/`.
3. Vorpal creates symlinks from the user's home directory into the store (e.g.,
   `~/.config/bat/config` -> `/var/lib/vorpal/store/artifact/output/library/<digest>/...`).
4. The user environment is immediately active.

### Symlink Targets

The `user` artifact creates symlinks for:
- Bat config and theme -> `~/.config/bat/`
- Claude Code settings -> `~/.claude/settings.json`
- Claude agents and skills -> `~/.claude/agents/`, `~/.claude/skills/`
- Claude statusline script -> `~/.claude/statusline.sh`
- Ghostty terminal config -> `~/Library/Application Support/com.mitchellh.ghostty/config`
- K9s skin -> `~/Library/Application Support/k9s/skins/tokyo_night.yaml`
- Neovim markdown ftplugin -> `~/.config/nvim/after/ftplugin/markdown.vim`
- OpenCode config -> `~/.config/opencode/opencode.json`
- Vorpal binary (from separate build) -> `~/.vorpal/bin/vorpal`

### Environment Variables

The `user` artifact sets:
- `EDITOR=nvim`
- `GOPATH=$HOME/Development/language/go`
- `PATH` prepends: VMware Fusion, `$GOPATH/bin`, `~/.opencode/bin`, `~/.vorpal/bin`, `~/.local/bin`

### Rollback

Because Vorpal uses content-addressed storage, previous artifact versions remain in
`/var/lib/vorpal/store/` until garbage collected. Rolling back requires:
1. Checking out the previous Git commit.
2. Re-running `vorpal build 'user'`.
3. Vorpal will either reuse cached artifacts or rebuild, then update symlinks.

**Gap**: No single-command rollback mechanism exists. There is no `vorpal rollback` or similar.
The developer must know which commit to return to.

---

## Observability

### OpenTelemetry Configuration

The Claude Code settings (`src/user.rs`) configure OTLP-based telemetry export for Claude Code
sessions:

| Signal | Exporter | Endpoint | Protocol |
|--------|----------|----------|----------|
| Logs | OTLP | `https://loki.bulbasaur.altf4.domains/otlp/v1/logs` | HTTP/Protobuf |
| Metrics | OTLP | `https://mimir.bulbasaur.altf4.domains/otlp/v1/metrics` | HTTP/Protobuf |

Additional settings:
- `CLAUDE_CODE_ENABLE_TELEMETRY=1`
- `OTEL_LOGS_EXPORT_INTERVAL=15000` (15 seconds)
- `OTEL_METRIC_EXPORT_INTERVAL=15000` (15 seconds)
- `OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE=cumulative`

This means Claude Code sessions emit structured logs to a Loki instance and metrics to a Mimir
instance, both hosted at `bulbasaur.altf4.domains`. This provides observability into AI agent
behavior, cost, and usage patterns.

### Claude Code Status Line

A custom status line script (`src/user/statusline.sh`) provides real-time session observability
in the terminal. It displays:
- Model name and agent name
- Project directory and Git branch
- Staged/modified file counts
- Context window usage (with color-coded progress bar)
- Session cost (USD)
- Session duration
- Lines added/removed

The script uses a 5-second file-based cache for Git info to avoid performance overhead.

### What Is NOT Observed

- **Build telemetry**: No metrics or logs are emitted for `vorpal build` operations. Build
  success/failure is only visible in CI logs or local terminal output.
- **Artifact store health**: No monitoring of disk usage in `/var/lib/vorpal/store/`.
- **Symlink integrity**: No automated check that symlinks are valid and pointing to existing
  store paths.
- **Dependency freshness**: No alerts when pinned tool versions in `Vorpal.lock` become outdated
  or have known vulnerabilities.

---

## Environment Management

### Supported Platforms

The code declares four target systems in `src/lib.rs`:
- `Aarch64Darwin` (macOS ARM -- primary)
- `Aarch64Linux`
- `X8664Darwin`
- `X8664Linux`

However, `Vorpal.lock` only contains source entries for `aarch64-darwin`. The other three
platforms have no pinned sources, meaning builds on those platforms would fail.

**In practice, this is a macOS Apple Silicon project.**

### Prerequisites

- Vorpal runtime installed on the host
- AWS credentials configured for S3 registry access (for remote cache)
- macOS on Apple Silicon

### Local Development

The `.envrc` file (contents not readable due to permissions) likely configures direnv for the
local development environment. The `dev` artifact provides Protoc and Rust toolchain for building
the project itself.

---

## Operational Runbooks

### Rebuilding the Environment

```bash
# Full rebuild
vorpal build 'dev'
vorpal build 'user'
```

### Updating a CLI Tool Version

1. Update the version URL in the relevant source code or Vorpal artifact definition.
2. Run `vorpal build 'user'` to regenerate `Vorpal.lock` with new digests.
3. Commit both source changes and updated `Vorpal.lock`.

### Troubleshooting Broken Symlinks

If a symlink target no longer exists in the Vorpal store (e.g., after store cleanup):
```bash
vorpal build 'user'
```
This rebuilds and re-links all artifacts.

### CI Failure Debugging

1. Check GitHub Actions logs for the failing job (`build-dev` or `build`).
2. Common causes:
   - AWS credential rotation (expired `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`)
   - S3 registry unavailability
   - Source URL no longer valid (upstream release removed or moved)
   - Vorpal `nightly` version regression

---

## Gaps and Improvement Opportunities

| Area | Current State | Gap |
|------|--------------|-----|
| **CI testing** | Build-only validation | No lint, format check, or test step |
| **Multi-platform CI** | macOS-only | No Linux validation despite declared support |
| **Lockfile for non-macOS** | Only `aarch64-darwin` sources | Other platforms cannot build |
| **Release process** | None | No versioning, tagging, or changelog automation |
| **Rollback** | Manual (checkout + rebuild) | No single-command rollback |
| **Build observability** | None | No telemetry for build operations |
| **Store management** | Manual | No garbage collection or disk monitoring |
| **Tool version tracking** | Manual except Renovate-managed Cargo deps | CLI tool versions in `Vorpal.lock` have no automated update tracking |
| **Symlink health checks** | None | No validation that symlinks are intact |
| **Operational runbooks** | Informal (README) | No structured runbook documentation |
