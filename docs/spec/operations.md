---
project: "main"
maturity: "experimental"
last_updated: "2026-03-20"
updated_by: "@staff-engineer"
scope: "CI/CD, build pipeline, dependency management, observability, and deployment operations"
owner: "@staff-engineer"
dependencies:
  - architecture.md
  - security.md
---

# Operations

## Build System

### Vorpal Build Pipeline

The project uses [Vorpal](https://github.com/ALT-F4-LLC/vorpal), a content-addressed build system. All artifacts are built into `/var/lib/vorpal/store/` and symlinked to their target locations on the host filesystem.

Two top-level build targets exist:

| Target | Purpose | Dependencies |
|--------|---------|-------------|
| `dev` | Development toolchain (Protoc + Rust toolchain) | None — bootstraps the build environment |
| `user` | Full user environment (16 CLI tools + configs + symlinks) | Requires `dev` to have been built |

Build commands:

```bash
vorpal build 'dev'   # Build toolchain
vorpal build 'user'  # Build full user environment
```

### Artifact Storage

- **Local store**: `/var/lib/vorpal/store/artifact/output/{namespace}/{digest}`
- **Remote cache**: S3-backed registry at bucket `altf4llc-vorpal-registry`
- Artifacts are content-addressed by digest, enabling reproducible builds and cache hits across CI and local machines.

### Lock File

`Vorpal.lock` pins all external source artifacts with SHA-256 digests and exact download URLs. As of the current state, it tracks 30+ sources (CLI tool binaries, library tarballs, theme files) exclusively for the `aarch64-darwin` platform.

`Vorpal.toml` defines the build language (`rust`) and source includes (`src`, `Cargo.toml`, `Cargo.lock`).

## CI/CD

### GitHub Actions Workflow

Single workflow file: `.github/workflows/vorpal.yaml`

**Triggers:**
- Push to `main` branch
- All pull requests

**Jobs:**

| Job | Runner | Steps | Depends On |
|-----|--------|-------|------------|
| `build-dev` | `macos-latest` | Checkout, setup Vorpal (nightly, S3 backend), `vorpal build 'dev'`, upload `Vorpal.lock` as artifact | — |
| `build` | `macos-latest` | Checkout, setup Vorpal (nightly, S3 backend), `vorpal build 'user'` (matrix: `user`) | `build-dev` |

Both jobs use `ALT-F4-LLC/setup-vorpal-action@main` to install the Vorpal runtime with:
- `version: nightly`
- `registry-backend: s3`
- `registry-backend-s3-bucket: altf4llc-vorpal-registry`

**Secrets and variables used:**
- `AWS_ACCESS_KEY_ID` (secret) — S3 registry access
- `AWS_SECRET_ACCESS_KEY` (secret) — S3 registry access
- `AWS_DEFAULT_REGION` (variable) — S3 region configuration

### CI Artifacts

The `build-dev` job uploads `Vorpal.lock` as a GitHub Actions artifact named `{arch}-{os}-vorpal-lock` for traceability.

### What CI Does NOT Do

- No automated deployment or release step — the build is the artifact, applied locally via `vorpal build 'user'`
- No automated testing — no test suite exists in the project
- No linting or formatting checks in CI
- No container builds — no Dockerfiles exist
- No multi-platform CI — only `macos-latest` runners

## Dependency Management

### Rust Dependencies (Cargo)

Managed via `Cargo.toml` with `Cargo.lock` checked in. Key dependencies:

| Crate | Purpose |
|-------|---------|
| `vorpal-sdk` | Core Vorpal SDK (context, artifacts, environment types) |
| `vorpal-artifacts` | Pre-built artifact types for CLI tools (git dep from `ALT-F4-LLC/artifacts.vorpal.git`) |
| `anyhow` | Error handling |
| `indoc` | Indented string literals for config generation |
| `serde` + `serde_json` | JSON serialization for config files |
| `tokio` | Async runtime |

### Renovate Bot

Automated dependency updates via `renovate.json`:

- **Auto-merge**: Minor and patch updates for stable crates (version `>= 1.0`)
- **Manual review**: Major crate updates
- **Grouped**: `serde` and `serde_json` updates are grouped together
- **Custom manager**: Tracks the `tokyonight.nvim` bat theme version embedded in `src/user.rs` via regex extraction from the raw GitHub URL

### External Tool Versions

All CLI tool versions are pinned in `Vorpal.lock` with exact URLs and SHA-256 digests. Version bumps require regenerating the lock file. There is no automated mechanism for updating these pinned tool versions — they are manually managed.

## Observability

### Telemetry Configuration

Claude Code telemetry is configured in the generated `settings.json` with OpenTelemetry (OTEL) environment variables:

| Signal | Exporter | Endpoint | Protocol |
|--------|----------|----------|----------|
| Logs | OTLP | `https://loki.bulbasaur.altf4.domains/otlp/v1/logs` | `http/protobuf` |
| Metrics | OTLP | `https://mimir.bulbasaur.altf4.domains/otlp/v1/metrics` | `http/protobuf` |

Additional OTEL settings:
- `OTEL_LOGS_EXPORT_INTERVAL`: 15000ms (15s)
- `OTEL_METRIC_EXPORT_INTERVAL`: 15000ms (15s)
- `OTEL_METRICS_EXPORTER`: otlp
- `OTEL_LOGS_EXPORTER`: otlp
- `OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE`: cumulative
- `CLAUDE_CODE_ENABLE_TELEMETRY`: 1

The telemetry backend uses Grafana's Loki (logs) and Mimir (metrics) hosted at `bulbasaur.altf4.domains`.

### What Observability Does NOT Cover

- No application-level monitoring for the dotfiles build itself
- No alerting configuration
- No dashboards defined in this repo
- No tracing (only logs and metrics for Claude Code)
- Telemetry is specific to Claude Code usage, not the build system

## Platform Support

### Current State

- **Primary platform**: macOS on Apple Silicon (`aarch64-darwin`)
- **Declared systems** in code: `Aarch64Darwin`, `Aarch64Linux`, `X8664Darwin`, `X8664Linux`
- **Actual lock file coverage**: `aarch64-darwin` only — all 30+ pinned sources target this single platform
- **CI runners**: `macos-latest` only

There is a gap between declared platform support (4 platforms) and actual artifact availability (1 platform).

## Deployment Model

This project has no traditional deployment. The "deployment" is a local `vorpal build 'user'` invocation that:

1. Fetches/builds all artifacts into the Vorpal content-addressed store
2. Creates symlinks from the home directory into the store (e.g., `~/.claude/settings.json`, `~/.config/bat/config`)
3. Sets environment variables via the user environment shell integration

There is no rollback mechanism beyond rebuilding with a previous commit's `Vorpal.lock`.

### Agent and Skill Deployment

Claude Code agents (`agents/*.md`) and skills (`skills/`) are deployed as symlinks:
- `~/.claude/agents/` — symlinked from the Vorpal store
- `~/.claude/skills/` — symlinked from the Vorpal store
- `~/.claude/settings.json` — generated configuration with permissions, plugins, and telemetry

## Environment Management

### direnv Integration

`.envrc` is present but its contents are denied from reading by Claude Code security permissions. The project uses `direnv` (included as a managed CLI tool) for per-directory environment setup.

### Shell Environment

The user environment injects these environment variables:
- `EDITOR=nvim`
- `GOPATH=$HOME/Development/language/go`
- `PATH` prepends: VMware Fusion library, `$GOPATH/bin`, `~/.opencode/bin`, `~/.vorpal/bin`, `~/.local/bin`

## Gaps and Missing Pieces

| Area | Status |
|------|--------|
| Automated testing | None — no test suite exists |
| Multi-platform CI | Only macOS; Linux and x86_64 not tested in CI |
| Lock file coverage | Only `aarch64-darwin` despite 4 declared platforms |
| Rollback procedure | No formal rollback — rebuild from prior commit |
| Release process | No versioned releases — continuous from `main` |
| Monitoring/alerting | No build or infrastructure monitoring |
| Runbooks | None |
| Incident response | No documented process |
| Secrets rotation | AWS credentials in GitHub Secrets; no rotation policy documented |
| Infrastructure as code | S3 bucket and Grafana backends are external; not managed in this repo |
