# Performance Specification

> Project: `dotfiles.vorpal` (ALT-F4-LLC/dotfiles.vorpal)
> Last updated: 2026-02-21

## Overview

This document describes the performance characteristics, known bottlenecks, caching strategies,
and scaling considerations for the `dotfiles.vorpal` project as they actually exist in the
codebase today.

The project is a Rust-based Vorpal configuration that defines a personal development environment
as code. It is a build-time configuration tool -- not a long-running service -- so performance
concerns center on build throughput, artifact resolution, and the efficiency of generated
configuration files rather than runtime latency or request handling.

---

## 1. Runtime Model

### Async Runtime

The application uses **Tokio** with the `rt-multi-thread` feature enabled (`Cargo.toml:15`).
The entrypoint is annotated with `#[tokio::main]` (`src/vorpal.rs:11`), which spawns a
multi-threaded runtime. This is appropriate given that the Vorpal SDK performs network I/O
(artifact fetching, registry communication) and the multi-thread scheduler allows concurrent
task execution across available CPU cores.

No custom runtime configuration (worker thread count, stack size, etc.) is applied. The runtime
uses Tokio's defaults, which sets the worker thread count to the number of available CPU cores.

### Execution Model

The build process in `src/vorpal.rs` and `src/user.rs` follows a **sequential async** pattern:

```
context -> protoc -> rust_toolchain -> dev environment -> user environment -> run
```

Within `UserEnvironment::build()` (`src/user.rs:41-403`), all 16 tool artifacts (awscli2, bat,
direnv, doppler, fd, gh, git, gopls, jj, jq, k9s, kubectl, lazygit, nnn, ripgrep, tmux) are
built sequentially via individual `.build(context).await?` calls (lines 44-59). Configuration
artifacts (bat config, claude code config, ghostty config, k9s skin, etc.) are also built
sequentially afterward (lines 63-348).

**This is the primary performance characteristic of the project**: approximately 30 sequential
async build operations, each involving potential network I/O to fetch sources and registry
interactions.

---

## 2. Caching Strategy

### Vorpal Registry Cache (S3-backed)

The project uses an **S3-backed artifact registry** (`altf4llc-vorpal-registry`) configured in
the CI workflow (`.github/workflows/vorpal.yaml:17-18`). The Vorpal build system handles
content-addressable artifact caching via the registry:

- Each artifact is identified by a digest in `Vorpal.lock` (e.g., SHA-256 hashes for each
  source).
- When an artifact's digest matches a previously built artifact in the S3 registry, the build
  can skip re-building and use the cached result.
- The `Vorpal.lock` file (`Vorpal.lock:1-250`) pins 30+ source artifacts with explicit digests,
  enabling deterministic and cache-friendly builds.

This is the project's most significant performance optimization. Rebuilds that hit the registry
cache avoid re-downloading sources and re-executing build steps entirely.

### Statusline Git Cache

The Claude Code statusline script (`src/user/statusline.sh:55-88`) implements a **file-based
TTL cache** for git status information:

- Cache key: checksum of the project directory path.
- Cache location: `/tmp/claude-statusline-git-cache-${cache_key}`.
- TTL: **5 seconds** (line 68).
- Caches branch name, staged file count, and modified file count.
- Falls back to live `git` commands on cache miss, then writes the result to the cache file.

This prevents repeated expensive `git diff --cached --numstat` and `git diff --numstat` calls
on every statusline refresh, which would otherwise add noticeable latency to the terminal
prompt.

### No Application-Level In-Memory Cache

The Rust source code contains no in-memory caching (no `HashMap`-based caches, no `lazy_static`,
no `once_cell` patterns beyond what the Vorpal SDK may provide internally). This is appropriate
for a build tool that runs once and exits.

---

## 3. Build Performance Characteristics

### Sequential Artifact Builds

The most impactful performance characteristic is that all artifact builds in
`UserEnvironment::build()` are **strictly sequential**. Each `.build(context).await?` call must
complete before the next begins. With 16 tool artifacts plus approximately 10 configuration
artifacts, a cold build involves roughly 26 sequential async operations.

**Why this matters**: Many of these artifacts have no dependency on each other. For example,
`awscli2`, `bat`, `direnv`, `doppler`, `fd`, and `ripgrep` are independent tools that could
theoretically be fetched and built in parallel. However, because they all mutate the shared
`&mut ConfigContext`, parallel builds would require either a different API from the Vorpal SDK
or internal synchronization.

**Current mitigation**: The S3 registry cache means that warm builds (where artifacts haven't
changed) are fast regardless of sequentiality, since each build step resolves to a cache hit
quickly.

### Artifact Source Downloads

The `Vorpal.lock` file references 30+ external source URLs (GitHub releases, language toolchain
distributions, etc.) totaling significant download volume on cold builds. Sources include:

- Large archives: Rust toolchain components (~100MB+), Go distribution, git source
- Medium archives: awscli2, tmux, ncurses
- Small binaries: jq, direnv, kubectl, fd, ripgrep

Download performance is bounded by network bandwidth and the remote server response times. The
Vorpal framework handles these downloads, and the S3 registry cache eliminates re-downloads for
unchanged artifacts.

### String Allocation Patterns

The codebase makes heavy use of `String` allocation through `.to_string()`, `format!()`, and
`.clone()` calls (332 occurrences across 9 source files). This is most pronounced in the builder
pattern implementations for configuration structs (`K9sSkin`, `ClaudeCode`, `Opencode`,
`GhosttyConfig`), which convert `&str` parameters to owned `String` values.

This is not a practical concern for this project. The configuration structs are built once during
a single build invocation and the total memory footprint of string allocations is negligible
(a few kilobytes of configuration text). Optimizing to `Cow<'a, str>` or string interning would
add complexity with no measurable benefit.

---

## 4. CI/CD Build Performance

### Workflow Structure

The CI pipeline (`.github/workflows/vorpal.yaml`) uses a **two-stage build**:

1. **`build-dev`**: Builds the `dev` artifact (Rust toolchain + protoc).
2. **`build`**: Depends on `build-dev`, then builds the `user` artifact.

The `build` job cannot start until `build-dev` completes (`needs: [build-dev]`). This creates
a sequential dependency in CI that adds to total pipeline time.

### Registry Backend

Both CI jobs configure the Vorpal registry with S3 backend:
```yaml
registry-backend: s3
registry-backend-s3-bucket: altf4llc-vorpal-registry
```

S3 provides durable, low-latency artifact caching for CI. The S3 bucket is in the AWS region
specified by `AWS_DEFAULT_REGION`, and artifact fetch latency depends on the geographic proximity
of the CI runner to the S3 region.

### CI Runner

Both jobs run on `macos-latest` GitHub Actions runners. The `Vorpal.lock` sources are all pinned
to `aarch64-darwin`, which means the builds are architecture-specific and cannot benefit from
cross-platform cache sharing.

---

## 5. Generated Configuration Performance

### Claude Code Configuration

The Claude Code configuration (`src/user/claude_code.rs`, `src/user.rs:86-172`) generates a
JSON settings file with:

- **OTEL export intervals**: Metrics and logs export interval set to `15000` ms (15 seconds),
  which is a reasonable balance between observability granularity and overhead.
- **Telemetry enabled**: `CLAUDE_CODE_ENABLE_TELEMETRY=1` enables telemetry collection, which
  adds background network I/O during Claude Code sessions.
- **Permission rules**: 40+ permission rules are defined. The Claude Code runtime evaluates
  these on each tool invocation. The rules use simple string/glob matching, so evaluation cost
  is minimal.

### Statusline Script

The statusline script (`src/user/statusline.sh`) runs on every prompt refresh. Performance
considerations:

- **jq invocations**: 9 separate `jq` calls to parse the same JSON input (lines 13-27, 35).
  Each call forks a new process. This could be consolidated into a single `jq` call extracting
  all fields at once, but the practical impact is small (a few milliseconds per invocation).
- **Git cache**: As described in Section 2, git operations are cached with a 5-second TTL.
- **Progress bar rendering**: The bar construction loop (lines 144-145) uses bash string
  concatenation in a loop, which is slow for large widths but the bar width is fixed at 10
  characters.

---

## 6. Dependency Performance Profile

### Direct Dependencies

| Dependency | Purpose | Performance Relevance |
|---|---|---|
| `tokio` (rt-multi-thread) | Async runtime | Multi-threaded executor for concurrent I/O |
| `serde` + `serde_json` | Serialization | Used for config file generation; fast for small payloads |
| `anyhow` | Error handling | Zero-cost in success path |
| `indoc` | String formatting | Compile-time macro; zero runtime cost |
| `vorpal-sdk` | Build framework | Controls artifact fetching, caching, and build orchestration |
| `vorpal-artifacts` | Artifact definitions | Provides tool artifact builders (awscli2, bat, etc.) |

The performance-critical dependency is `vorpal-sdk`, which manages all artifact resolution,
source downloading, and registry interaction. Its internal caching and network behavior
dominates build time.

### Transitive Dependencies

The `Cargo.lock` includes HTTP/TLS libraries (hyper, rustls, h2, http-body) pulled in
transitively through the Vorpal SDK. These handle the actual network I/O for artifact
downloads and registry communication.

---

## 7. Known Bottlenecks

1. **Sequential artifact builds**: The ~26 sequential `.build(context).await?` calls are the
   dominant factor in cold build time. This is constrained by the Vorpal SDK's
   `&mut ConfigContext` API, which requires exclusive mutable access.

2. **Cold build download volume**: A fully cold build (empty registry cache) must download all
   30+ source archives specified in `Vorpal.lock`, which involves significant network transfer.

3. **CI two-stage dependency**: The `build` job waits for `build-dev` to complete, adding
   sequential latency to the CI pipeline even though the `user` artifact build could potentially
   start preparing independent artifacts earlier.

4. **Single-platform lock file**: `Vorpal.lock` only contains `aarch64-darwin` sources. Builds
   on other platforms would require resolving sources at build time rather than using pinned
   digests.

---

## 8. Benchmarking and Profiling

### Current State

**There is no benchmarking or profiling infrastructure in this project.** No `#[bench]` tests,
no criterion benchmarks, no flamegraph configuration, and no build-time measurement tooling
exists.

This is reasonable for the project's nature -- it is a personal dotfiles configuration tool,
not a performance-sensitive application. Build time is the only meaningful performance metric,
and it is dominated by external factors (network speed, registry cache hit rate).

### Observability

The project configures OpenTelemetry endpoints for Claude Code sessions:
- Logs: `https://loki.bulbasaur.altf4.domains/otlp/v1/logs`
- Metrics: `https://mimir.bulbasaur.altf4.domains/otlp/v1/metrics`

These provide observability into Claude Code usage but do not measure build performance of the
dotfiles project itself.

---

## 9. Scaling Considerations

This project is a personal dotfiles manager. It does not serve traffic, handle concurrent users,
or need horizontal scaling. The relevant "scaling" dimensions are:

- **Adding more tools**: Each new tool artifact adds one more sequential build step. Build time
  grows linearly with the number of artifacts. Currently at ~26 artifacts.
- **Configuration complexity**: The builder pattern structs (especially `K9sSkin` at 80+ fields
  and `ClaudeCode` at 40+ fields) grow in source code size but not in runtime cost, since they
  generate static configuration files.
- **Cross-platform support**: The `SYSTEMS` constant declares 4 target systems
  (`Aarch64Darwin`, `Aarch64Linux`, `X8664Darwin`, `X8664Linux`) but `Vorpal.lock` only pins
  `aarch64-darwin` sources. Supporting additional platforms would multiply the number of source
  entries in the lock file.

---

## 10. Gaps and Recommendations

| Gap | Impact | Notes |
|---|---|---|
| No parallel artifact builds | Moderate | Constrained by Vorpal SDK API (`&mut ConfigContext`); not actionable without SDK changes |
| No build-time metrics | Low | Would be useful for tracking build performance trends over time |
| Multiple jq forks in statusline | Low | 9 separate `jq` processes per statusline refresh; could be consolidated into 1 |
| No Cargo build profile tuning | Low | Default `dev` and `release` profiles are used; no custom `[profile]` configuration in `Cargo.toml` |
| Single-platform Vorpal.lock | Low | Only `aarch64-darwin` sources are pinned; other platforms would have slower first builds |

None of these gaps represent urgent problems. The project's performance is adequate for its
purpose as a personal dotfiles configuration tool, with the S3-backed artifact registry providing
the most impactful caching layer.
