---
project: "main"
maturity: "experimental"
last_updated: "2026-03-20"
updated_by: "@staff-engineer"
scope: "Performance characteristics, build-time behavior, and runtime efficiency of the dotfiles Vorpal configuration"
owner: "@staff-engineer"
dependencies:
  - architecture.md
  - operations.md
---

# Performance Specification

## 1. Overview

This document describes the performance characteristics of the `dotfiles` project — a Rust-based Vorpal configuration that declaratively builds and deploys a personal development environment. The project is a build-time configuration tool, not a long-running service, so performance concerns center on build latency, artifact resolution, and CI pipeline efficiency rather than request throughput or database queries.

## 2. Project Performance Profile

### 2.1 Nature of Workload

The project produces a single binary (`vorpal`) that acts as a Vorpal configuration entry point. When executed via `vorpal build <artifact>`, it:

1. Initializes a Vorpal `ConfigContext` (async, via `get_context().await`)
2. Sequentially builds ~16 tool artifacts (awscli2, bat, direnv, doppler, fd, gh, git, gopls, jj, jq, k9s, kubectl, lazygit, nnn, ripgrep, tmux)
3. Builds ~10 configuration file artifacts (bat config/theme, claude code settings, ghostty config, k9s skin, opencode config, markdown vim, statusline script, claude agents dir, claude skills dir)
4. Assembles a `UserEnvironment` with symlinks and environment variables
5. Calls `context.run().await` to execute the build plan

### 2.2 Runtime: Tokio Multi-Thread

The binary uses `#[tokio::main]` with the `rt-multi-thread` feature, giving it access to Tokio's work-stealing thread pool. However, the actual build orchestration depends on the Vorpal SDK's `ConfigContext` — the local code itself does not explicitly parallelize artifact builds.

## 3. Build-Time Performance Characteristics

### 3.1 Sequential Artifact Registration

**Current state:** In `src/user.rs`, all 16 tool artifacts and 10 configuration artifacts are built sequentially via chained `.await` calls:

```rust
let awscli2 = Awscli2::new().build(context).await?;
let bat = Bat::new().build(context).await?;
let direnv = Direnv::new().build(context).await?;
// ... 13 more tools, each awaited in sequence
```

Each `.build(context)` call registers the artifact with the Vorpal context. Whether these calls involve actual network I/O (fetching from registry), local computation, or are purely declarative registration depends on the Vorpal SDK internals (`vorpal-sdk` and `vorpal-artifacts` crates). The local code does not attempt concurrent registration.

**Observation:** If artifact registration involves I/O (e.g., checking a remote registry), sequential awaiting leaves potential parallelism on the table. If registration is purely local/declarative, the sequential pattern has negligible overhead.

### 3.2 Vorpal Build Execution

The actual heavy work happens inside `context.run().await`, which is owned by the Vorpal SDK. This project has no visibility into or control over:

- Whether artifacts are built in parallel or sequentially
- Caching and content-addressable store behavior
- Network fetching strategy for remote artifacts
- Sandbox execution of shell build steps

### 3.3 Shell Step Execution

Configuration artifacts (`FileCreate`, `FileDownload`, `FileSource` in `src/file.rs`) generate bash scripts that run inside the Vorpal sandbox:

- **FileCreate**: Writes inline content via `cat << 'EOF'` and `chmod`. Minimal overhead.
- **FileDownload**: Uses `ArtifactSource` with a URL, then copies from `source/` directory. The download itself is handled by Vorpal.
- **FileSource**: Copies local source directories into the output. Uses `cp -rv` with `mkdir -pv`.

These shell scripts are straightforward — no complex transformations, no compilation steps. Performance is bounded by I/O (file copy) and Vorpal's sandbox overhead.

### 3.4 Configuration Serialization

The `ClaudeCode` struct (largest configuration artifact) uses `serde_json::to_string_pretty` for serialization. The K9s skin uses `formatdoc!` string interpolation for YAML generation. Both are negligible in cost — the configurations are small (< 10KB each).

## 4. Compilation Performance

### 4.1 Dependency Weight

The project has 7 direct dependencies:

| Dependency | Purpose | Weight |
|---|---|---|
| `anyhow` | Error handling | Lightweight |
| `indoc` | String formatting macros | Compile-time only |
| `serde` + `serde_json` | JSON serialization (Claude Code config) | Moderate |
| `tokio` (rt-multi-thread) | Async runtime | Heavy |
| `vorpal-artifacts` | Pre-built artifact definitions (git dep) | Unknown |
| `vorpal-sdk` | Vorpal build SDK | Unknown |

The `Cargo.lock` is ~66KB, indicating a substantial transitive dependency tree (primarily from Tokio and the Vorpal SDK crates).

### 4.2 Compile Times

No benchmarks or compile-time tracking exists. The project is a single `[[bin]]` target with a small lib crate (~6 source files, ~1700 lines total). Compile time is dominated by dependencies, not local code.

## 5. CI/CD Performance

### 5.1 Pipeline Structure

The GitHub Actions workflow (`.github/workflows/vorpal.yaml`) has two jobs:

1. **`build-dev`**: Runs on `macos-latest`, builds the `dev` artifact, uploads `Vorpal.lock`
2. **`build`**: Depends on `build-dev`, runs on `macos-latest` with matrix strategy, builds the `user` artifact

**Observation:** The `build` job depends on `build-dev` completing first, creating a serial pipeline. The matrix strategy currently has only one entry (`user`), so no actual parallelism is achieved from the matrix.

### 5.2 Registry Caching

The workflow uses an S3-backed Vorpal registry (`altf4llc-vorpal-registry`). This means:

- Previously built artifacts can be fetched from S3 rather than rebuilt
- Build performance depends on S3 latency and cache hit rates
- The `Vorpal.lock` file is uploaded as a GitHub Actions artifact, enabling lockfile consistency across jobs

### 5.3 Cross-Platform Scope

The `SYSTEMS` constant declares support for 4 platforms: `Aarch64Darwin`, `Aarch64Linux`, `X8664Darwin`, `X8664Linux`. However, CI only runs on `macos-latest` (ARM64 macOS). Cross-platform builds for other targets depend on Vorpal's ability to build artifacts for non-native systems.

## 6. Caching

### 6.1 Vorpal Content-Addressable Store

Artifacts are stored at `/var/lib/vorpal/store/artifact/output/{namespace}/{digest}` (per `get_output_path` in `src/lib.rs`). The digest-based path implies content-addressable storage — unchanged artifacts should be cache hits.

### 6.2 No Application-Level Caching

The project itself implements no caching logic. All caching behavior is delegated to:

- The Vorpal SDK's build system
- The S3-backed registry in CI
- Cargo's build cache for compilation

## 7. Known Gaps

| Gap | Impact | Severity |
|---|---|---|
| No build timing instrumentation | Cannot identify slow artifacts or measure improvement | Medium |
| Sequential artifact registration | Potential missed parallelism if registration involves I/O | Low–Medium |
| No profiling or benchmarks | No baseline for regression detection | Low |
| Single CI runner architecture | Cannot verify cross-platform build performance | Low |
| No Cargo build caching in CI | Each CI run starts with a cold Cargo cache (unless setup-vorpal-action handles this) | Medium |
| No incremental build metrics | Unknown how well content-addressable caching performs in practice | Medium |

## 8. Performance-Critical Paths

Given the project's nature as a dotfiles configuration, there are no user-facing latency-sensitive paths. The most performance-relevant operations are:

1. **Full `vorpal build user`** — the end-to-end build of the entire user environment. This is the primary operation users run and the one most affected by caching effectiveness.
2. **CI pipeline wall time** — the total time from push to green check. Currently serial (`build-dev` then `build`).
3. **Vorpal SDK initialization** — `get_context().await` is the first async call and gates all subsequent work.

## 9. Recommendations for Future Work

These are observations, not commitments:

- **Instrument build times**: Add timing around individual artifact `.build()` calls to identify bottlenecks.
- **Evaluate parallel registration**: If Vorpal SDK supports it, register independent artifacts concurrently (e.g., `tokio::try_join!` for tools that don't depend on each other).
- **CI Cargo caching**: Add `actions/cache` for `target/` directory if not already handled by the Vorpal setup action.
- **Pipeline parallelism**: If `build-dev` and `build` don't truly depend on each other's outputs, remove the `needs` dependency.
