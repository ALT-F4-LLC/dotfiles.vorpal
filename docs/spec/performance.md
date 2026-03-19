---
project: "dotfiles.vorpal"
maturity: "experimental"
last_updated: "2026-03-18"
updated_by: "@staff-engineer"
scope: "Performance characteristics, build-time behavior, caching, and scaling considerations"
owner: "@staff-engineer"
dependencies:
  - architecture.md
  - operations.md
---

# Performance

## Nature of the Project

This is a **build-time configuration generator**, not a long-running service. The Rust binary
(`vorpal`) executes once per invocation to declare artifacts, then hands off to the Vorpal build
system. Performance characteristics therefore fall into two categories:

1. **Configuration generation** -- the Rust code in this repository that runs during `vorpal build`
2. **Artifact build execution** -- Vorpal's build system processing the declared artifacts (outside this codebase)

Most performance-critical behavior lives in category 2, which is owned by the upstream
[vorpal-sdk](https://github.com/ALT-F4-LLC/vorpal) and
[vorpal-artifacts](https://github.com/ALT-F4-LLC/artifacts.vorpal.git) projects.

## Async Runtime

The binary uses Tokio with the multi-threaded runtime (`rt-multi-thread` feature in `Cargo.toml`).
The entrypoint at `src/vorpal.rs:12` is annotated with `#[tokio::main]`.

All artifact `.build()` calls are async and awaited sequentially within `UserEnvironment::build()`
(`src/user.rs:41-487`). The 16 CLI tool artifacts and ~10 configuration artifacts are built one
after another via individual `.await` calls. There is **no parallelism** at the declaration level
within this codebase -- artifacts are registered with the Vorpal context serially.

Whether the upstream Vorpal build system parallelizes actual artifact construction is determined
by `vorpal-sdk`, not by this project.

## Build Execution Profile

A typical `vorpal build 'user'` invocation follows this path:

1. `get_context()` initializes the Vorpal SDK context (network/registry connection)
2. `DevelopmentEnvironment` registers Protoc and Rust toolchain artifacts
3. `UserEnvironment::build()` sequentially registers ~26 artifacts (16 tools + ~10 configs)
4. `context.run()` hands off to the Vorpal build engine for actual execution

The Rust code itself is lightweight string formatting and struct construction. The time-dominant
operations are in steps 1 and 4, which are owned by the SDK.

## Caching

### Vorpal Content-Addressed Store

Artifacts are stored in `/var/lib/vorpal/store/artifact/output/{namespace}/{digest}`. The Vorpal
build system uses content-addressed storage -- if an artifact's inputs haven't changed, it is not
rebuilt. This is the primary caching mechanism and is entirely SDK-managed.

### S3 Remote Cache

The CI/CD pipeline and local builds can leverage S3-backed remote caching via the
`altf4llc-vorpal-registry` bucket. The `Vorpal.lock` file pins source digests (SHA-256 hashes)
for all 30+ external sources, enabling deterministic cache hits across machines.

### Statusline Script Cache

The `statusline.sh` script (`src/user/statusline.sh:57-88`) implements a file-based cache for
git status information:

- Cache key: CRC checksum of the project directory path
- Cache location: `/tmp/claude-statusline-git-cache-{key}`
- TTL: 5 seconds (checked via `stat` mtime comparison)
- Purpose: Avoids repeated `git diff` and `git symbolic-ref` calls during rapid status bar refreshes

This is the only caching logic implemented within this repository's own code.

### No Application-Level Caching

The configuration generators (BatConfig, ClaudeCode, GhosttyConfig, K9sSkin, Opencode) perform
no caching of their own. They generate configuration strings in memory and pass them to
`FileCreate`, which delegates to the Vorpal artifact system. This is appropriate -- the Vorpal
store handles deduplication.

## Memory Characteristics

### String Allocations

The configuration generators are allocation-heavy relative to their output size. Notable patterns:

- **Builder pattern with owned Strings**: Every builder method (e.g., `K9sSkin` has 50+ fields)
  clones `&str` into `String` via `.to_string()`. This is the idiomatic Rust builder pattern and
  the allocation cost is negligible for a build tool.
- **K9sSkin**: The largest single struct with ~50 `String` fields, all heap-allocated. The
  `format_yaml_list()` helper at `src/user/k9s.rs:6-12` creates intermediate `Vec<String>`
  allocations.
- **ClaudeCode**: Uses `BTreeMap<String, String>` for env vars, hooks, and plugins. Serializes
  the entire struct to JSON via `serde_json::to_string_pretty()`.
- **Opencode**: The largest module (~2200 lines) with deep nested structs. JSON serialization
  via serde.

None of these are performance concerns. The total memory footprint of configuration generation
is well under 1 MB.

### Vorpal Lock File

The `Vorpal.lock` file (~7.5 KB) contains 30+ source entries with SHA-256 digests. It is parsed
by the Vorpal runtime, not by this codebase.

## Compilation Performance

### Build Profile

The `Cargo.toml` specifies no custom build profiles -- no `[profile.release]` overrides for
`opt-level`, `lto`, `codegen-units`, or `strip`. The binary is compiled with default Rust
settings. The `target/debug/` directory is present, indicating debug builds are the norm for
local development.

### Dependency Weight

The project has 6 direct dependencies:

| Dependency | Impact |
|---|---|
| `tokio` (rt-multi-thread) | Heavy; pulls in the full multi-threaded async runtime |
| `vorpal-sdk` | SDK with gRPC (tonic/prost), likely the largest dependency tree |
| `vorpal-artifacts` | Git dependency; adds pre-built artifact types |
| `serde` + `serde_json` | Moderate; derive macros add compile time |
| `anyhow` | Light |
| `indoc` | Light; proc macro |

The `Cargo.lock` contains ~200+ transitive dependencies, driven primarily by the Vorpal SDK's
gRPC stack (tonic, prost, hyper, rustls, ring). Compile times are dominated by these transitive
dependencies on clean builds.

### No Benchmarks

There are no benchmarks (`benches/` directory, criterion, or similar). There are no
`#[bench]` annotations or performance test infrastructure. This is reasonable for a build-time
configuration tool where execution time is dominated by external I/O.

## Scaling Considerations

### Artifact Count

The current artifact count (~26 total) is small. Adding more CLI tools or configuration files
would add proportionally to:

- Build declaration time (negligible -- struct construction)
- Vorpal build execution time (dependent on SDK parallelism and cache hits)
- `Vorpal.lock` size (linear growth, trivial)

### Multi-Platform Support

The `SYSTEMS` constant in `src/lib.rs:9` declares 4 target platforms:
`Aarch64Darwin`, `Aarch64Linux`, `X8664Darwin`, `X8664Linux`. Each artifact is registered for
all 4 systems, but the Vorpal build system only builds for the current host. The CI pipeline
runs on `macos-latest` only.

### Configuration Generator Size

The Opencode configuration generator (`src/user/opencode.rs`) is ~2200 lines. The ClaudeCode
generator is ~540 lines. These are the largest files. Growth in configuration complexity
increases code size but has no runtime performance impact -- it's all compile-time type checking
and build-time string formatting.

## Known Bottlenecks

### Sequential Artifact Declaration

All artifacts in `UserEnvironment::build()` are declared sequentially. Each `.build(context).await`
must complete before the next begins. If any artifact's SDK registration involves I/O (e.g.,
resolving source digests, communicating with the Vorpal daemon), this serialization could become
a bottleneck as artifact count grows.

**Mitigation**: The current count (~26 artifacts) is small enough that this is not a practical
problem. If it becomes one, artifact declarations that don't depend on each other's output could
be parallelized with `tokio::join!` or `futures::join_all`.

### External Source Downloads

The `Vorpal.lock` file pins 30+ external URLs (GitHub releases, language tool archives). First
builds without cache require downloading all sources. The lock file's SHA-256 digests ensure
that subsequent builds use cached artifacts. Download parallelism is controlled by the Vorpal
runtime, not this codebase.

### CI Build Times

The CI pipeline runs two sequential jobs (`build-dev` then `build`) on `macos-latest`. The
`build` job depends on `build-dev`, so they cannot run in parallel. This is inherently sequential
because `user` depends on the `dev` toolchain.

## Gaps

- **No compilation profile tuning**: No release profile optimizations in `Cargo.toml`. The binary
  is small enough that this is unlikely to matter, but `lto = true` and `strip = true` could
  reduce binary size if distribution becomes a concern.
- **No benchmark infrastructure**: No way to measure regression in configuration generation time.
  Acceptable for the current project size.
- **No CI caching of Cargo build artifacts**: The GitHub Actions workflow does not use
  `actions/cache` for `target/` or `~/.cargo/`. Clean Cargo builds on every CI run add
  unnecessary time. The Vorpal artifact cache (S3) handles Vorpal-level caching, but Rust
  compilation itself is not cached in CI.
- **No profiling or tracing**: No `tracing` instrumentation in the configuration generators.
  If build times become a concern, adding span-level tracing would help identify which artifact
  declarations are slow.
- **Sequential artifact registration**: As noted above, all artifacts are awaited one at a time.
  Not a current problem but limits future scalability.
