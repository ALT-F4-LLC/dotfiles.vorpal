---
project: "dotfiles.vorpal"
maturity: "experimental"
last_updated: "2026-03-18"
updated_by: "@staff-engineer"
scope: "Performance characteristics, build-time behavior, caching strategy, and scaling considerations"
owner: "@staff-engineer"
dependencies:
  - architecture.md
  - operations.md
---

# Performance

## Overview

dotfiles.vorpal is a build-time configuration generator, not a long-running service. Performance
characteristics are dominated by artifact build times, network downloads, and Vorpal's
content-addressed store operations. The project itself does minimal compute -- it assembles
configuration data structures and delegates to the Vorpal SDK for artifact building and caching.

## Performance Profile

### Build-Time (Primary Concern)

The project runs as a short-lived `vorpal build` invocation. Two top-level artifacts are built:

1. **`dev`** -- Rust toolchain + Protoc. Heavy first-build cost (large downloads), near-instant
   on cache hit.
2. **`user`** -- 16 CLI tools + configuration files + symlinks. The bulk of build time.

All artifact builds are **sequential** within the `UserEnvironment::build` method
(`src/user.rs:41-488`). Each tool artifact is built one-by-one via `await?`:

```
awscli2 -> bat -> direnv -> doppler -> fd -> gh -> git -> gopls -> jj -> jq -> k9s -> kubectl -> lazygit -> nnn -> ripgrep -> tmux
```

This sequential chain means build time is the **sum** of all individual artifact build times, not
the maximum. There is no parallel artifact construction within this project's code -- parallelism
(if any) is delegated to the Vorpal runtime.

### Runtime (Negligible)

The generated artifacts are static files (config files, symlinks, binaries). They impose zero
runtime overhead once deployed. The only runtime component is the statusline script
(`src/user/statusline.sh`), which runs periodically in the Claude Code status bar.

## Caching Strategy

### Vorpal Content-Addressed Store

All artifacts are stored in Vorpal's content-addressed store at
`/var/lib/vorpal/store/artifact/output/{namespace}/{digest}`. Cache hits are determined by content
hash -- if the artifact inputs haven't changed, the cached output is reused without rebuilding.

This is the primary performance optimization and it is provided entirely by the Vorpal runtime,
not by this project's code.

### S3 Remote Cache

The CI pipeline and local builds use an S3-backed remote registry (`altf4llc-vorpal-registry`)
configured via `setup-vorpal-action`. This means:

- Artifacts built in CI are available locally without rebuilding
- Artifacts built locally are available in CI without rebuilding
- First-time builds on a new machine pull from S3 rather than building from source

Configuration in `.github/workflows/vorpal.yaml`:
```yaml
registry-backend: s3
registry-backend-s3-bucket: altf4llc-vorpal-registry
```

### Vorpal.lock

The `Vorpal.lock` file pins exact source URLs and SHA-256 digests for all external downloads
(30+ entries). This ensures:

- Reproducible builds across machines
- Content verification (no re-download if digest matches)
- The lock file is uploaded as a CI artifact from the `build-dev` job for downstream consumption

### Statusline Script Cache

The statusline script (`src/user/statusline.sh:59-86`) implements a file-based cache for git
status information:

- Cache key: CRC checksum of the directory path
- Cache location: `/tmp/claude-statusline-git-cache-{key}`
- TTL: 5 seconds (checked via file modification time)
- Purpose: Avoids running `git diff` and `git status` on every status bar refresh

This is a sensible optimization -- git operations on large repos can take hundreds of milliseconds,
and the status bar refreshes frequently.

## Known Bottlenecks

### Sequential Artifact Builds

The biggest performance bottleneck is the sequential build chain in `UserEnvironment::build`. Each
of the 16 CLI tool artifacts is awaited sequentially. Independent artifacts (e.g., `bat` and `jq`)
could theoretically be built in parallel using `tokio::join!` or `futures::join_all`, but:

- The `ConfigContext` is passed as `&mut`, requiring exclusive access
- Parallelism would require the Vorpal SDK to support concurrent context operations
- On cache hit, each build is fast regardless, making this primarily a cold-build concern

### Network Downloads on Cold Builds

Cold builds download 30+ source archives from various URLs (GitHub releases, kernel.org, Go
downloads, etc.). These are fetched sequentially through the Vorpal SDK. Total download size for
the `user` artifact on aarch64-darwin is substantial (AWS CLI alone is a large package).

### Compilation from Source

Some artifacts (git, tmux, nnn, gopls) are compiled from source rather than downloaded as
pre-built binaries. These are the slowest individual builds:

- **git** -- compiled from `git-2.53.0.tar.gz`
- **tmux** -- compiled from `tmux-3.5a.tar.gz` with dependencies (libevent, ncurses, readline,
  pkg-config)
- **nnn** -- compiled from source
- **gopls** -- compiled from Go source with the Go toolchain

The Vorpal cache mitigates this after the first successful build.

## Async Runtime

The project uses Tokio with the `rt-multi-thread` feature (`Cargo.toml:15`). The `#[tokio::main]`
macro on `src/vorpal.rs:11` sets up the multi-threaded runtime. However, the actual build logic is
entirely sequential `await` chains -- the multi-threaded runtime is present because the Vorpal SDK
requires it, not because this project exploits parallelism.

## Memory Characteristics

Memory usage is low. The project:

- Holds configuration structs in memory (small -- strings and enums)
- Serializes JSON via serde (ClaudeCode config, Opencode config)
- Generates YAML via string formatting (K9s skin)
- Delegates heavy work (downloads, compilation, hashing) to Vorpal worker processes

The largest in-memory structure is the `ClaudeCode` configuration struct, which holds ~100+
permission rules as `Vec<String>`. This is trivially small.

## Benchmarking

**No benchmarks exist.** There are no `#[bench]` functions, no criterion benchmarks, no build-time
measurement tooling, and no performance regression tests.

This is appropriate for the project's maturity level. The performance-critical path is inside the
Vorpal runtime (not this project), and build times are dominated by network I/O and compilation --
neither of which is controlled by this project's code.

## Scaling Considerations

### Adding More Artifacts

Each new CLI tool added to `UserEnvironment` adds to the sequential build chain. The incremental
cost is:

- **Pre-built binary**: Download time only (~seconds on cache miss, instant on hit)
- **Compiled from source**: Compilation time (~minutes on cache miss, instant on hit)

The current 16-tool count is manageable. Scaling to 50+ tools would make cold builds noticeably
slow but would not affect cached builds.

### Multi-Platform Support

The `SYSTEMS` constant declares support for 4 platforms (`Aarch64Darwin`, `Aarch64Linux`,
`X8664Darwin`, `X8664Linux`), but the `Vorpal.lock` currently only contains `aarch64-darwin`
entries. Building for additional platforms would multiply the number of source downloads and
compilations needed.

### Configuration Generators

The configuration generator structs (ClaudeCode, K9sSkin, Opencode, etc.) are lightweight builders
that produce string output. They have no performance concerns at any realistic scale. The K9sSkin
struct is the largest at 50+ fields, but its `build` method is a single `formatdoc!` macro
invocation.

## Gaps

| Gap | Impact | Notes |
|-----|--------|-------|
| No parallel artifact builds | Cold build time is sum of all artifacts, not max | Blocked by `&mut ConfigContext` requirement |
| No build time measurement | Cannot track regressions | Could add timing instrumentation around each `.build()` call |
| No CI caching of Cargo build artifacts | CI rebuilds the Rust binary every run | `actions/cache` for `target/` directory would help |
| No download parallelism | Cold builds wait for each download sequentially | Controlled by Vorpal SDK, not this project |
| Single-platform lock file | Only aarch64-darwin sources are locked | Other platforms declared in `SYSTEMS` but not exercised |
