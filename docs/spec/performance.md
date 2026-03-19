---
project: "dotfiles.vorpal"
maturity: "experimental"
last_updated: "2026-03-18"
updated_by: "@staff-engineer"
scope: "Performance characteristics, bottlenecks, caching, and scaling considerations for the dotfiles build system"
owner: "@staff-engineer"
dependencies:
  - architecture.md
  - operations.md
---

# Performance

## Overview

dotfiles.vorpal is a build-time configuration generator, not a long-running service. Its
performance characteristics center on artifact build latency, network download throughput, and
content-addressed caching efficiency. The program runs once per `vorpal build` invocation, produces
artifacts to `/var/lib/vorpal/store/`, and exits. There are no runtime hot paths, database queries,
connection pools, or request-serving loops.

## Build-Time Performance Profile

### Artifact Build Pipeline

The `vorpal build 'user'` command is the primary performance-sensitive operation. It builds
approximately 26 artifacts sequentially through the Vorpal SDK's `ConfigContext`:

1. **16 CLI tool artifacts** -- Each tool (awscli2, bat, direnv, doppler, fd, gh, git, gopls, jj,
   jq, k9s, kubectl, lazygit, nnn, ripgrep, tmux) is built via its respective builder from
   `vorpal-artifacts` or `vorpal-sdk`. These involve downloading pre-built binaries from upstream
   release URLs.
2. **10 configuration artifacts** -- Config files (bat config, bat theme, Claude Code settings,
   Ghostty config, K9s skin, OpenCode config, markdown vim, Claude statusline, Claude agents
   directory, Claude skills directory) are generated in-process and written via shell steps.

All artifact builds in `UserEnvironment::build()` (`src/user.rs`) are executed **sequentially**
using `await` -- each `.build(context).await?` call completes before the next begins. There is no
parallel artifact building within a single build invocation.

### Async Runtime

The project uses `tokio` with the `rt-multi-thread` feature (`#[tokio::main]`), but the actual
build logic is sequential. The multi-threaded runtime is required by the Vorpal SDK's gRPC
communication layer, not for application-level parallelism.

## Caching Strategy

### Content-Addressed Store

Vorpal uses a content-addressed artifact store at `/var/lib/vorpal/store/artifact/output/`. Each
artifact is stored under `{namespace}/{digest}`, where the digest is a hash of the artifact's
inputs. This provides automatic deduplication -- if an artifact's inputs haven't changed, its
cached output is reused without rebuilding.

The `get_output_path()` function in `src/lib.rs` constructs paths using this scheme:
```
/var/lib/vorpal/store/artifact/output/{namespace}/{digest}
```

### Remote Cache (S3)

The CI/CD pipeline configures an S3-backed remote registry (`altf4llc-vorpal-registry`) via the
`setup-vorpal-action`. This allows artifact outputs to be shared between CI runs and potentially
between local and CI environments, avoiding redundant downloads and builds.

### Source Locking

`Vorpal.lock` pins every external source by URL, platform, and SHA-256 digest. This ensures
reproducibility and allows the build system to skip downloads when the local cache already contains
a source with the matching digest. The lock file contains 30+ source entries, all pinned to
`aarch64-darwin`.

## Network I/O

### Download Bottleneck

The dominant performance cost for cold builds is network I/O. Each CLI tool artifact downloads a
pre-built binary from an upstream URL (GitHub Releases, AWS, kernel.org, Google, etc.). A cold
build must fetch all 16+ tool binaries plus supporting sources (Rust toolchain components, Go,
protoc, libevent, ncurses, readline, pkg-config).

The `Vorpal.lock` file lists 30 source entries for `aarch64-darwin` alone. On a cold build
without remote cache, all of these must be downloaded.

### File Downloads at Build Time

The `FileDownload` struct in `src/file.rs` downloads files at build time via source URLs. The bat
theme file is downloaded from a raw GitHub URL during the build. This is a small file but adds a
network dependency to what could otherwise be a purely local operation.

## Known Bottlenecks

### Sequential Artifact Builds

The most significant performance limitation is that all artifact builds in
`UserEnvironment::build()` run sequentially. Each of the ~26 artifacts waits for the previous one
to complete before starting. Many of these artifacts are independent -- for example, downloading
`bat` has no dependency on downloading `doppler` -- but they are not built in parallel.

This is likely a constraint of the Vorpal SDK's `ConfigContext` requiring `&mut` (exclusive
mutable reference), which prevents concurrent builds through the same context.

### Single-Platform Lock File

`Vorpal.lock` currently only contains entries for `aarch64-darwin`. While `src/lib.rs` declares
support for 4 platforms (`Aarch64Darwin`, `Aarch64Linux`, `X8664Darwin`, `X8664Linux`), the lock
file suggests only one platform is actively built. Cross-platform builds would require additional
source entries and downloads.

### No Incremental Configuration Generation

Configuration artifacts (Claude Code settings, Ghostty config, K9s skin, etc.) are regenerated
from scratch on every build, even if their inputs haven't changed. The content-addressed store
mitigates this at the storage layer -- if the generated output is identical, the same digest is
produced -- but the generation work still occurs.

## Compilation Performance

### Rust Build

The project itself is a Rust binary compiled with `edition = "2021"`. Key dependencies affecting
compile time:

- **serde + serde_json** -- Derive macros add to compile time but are standard and well-optimized.
- **tokio (rt-multi-thread)** -- Pulls in the full multi-threaded async runtime.
- **vorpal-sdk** -- Git dependency with protobuf code generation (`vorpal-sdk-*/out/*.rs` files in
  the build directory indicate `prost`/`tonic` codegen). Protobuf code generation is a known
  compile-time cost.
- **vorpal-artifacts** -- Git dependency from a separate repository.

The `dev` artifact in CI provides the Rust toolchain (protoc + rustup), so compilation depends on
these being cached or available.

### CI Build Performance

The CI pipeline (`vorpal.yaml`) runs two sequential jobs:

1. `build-dev` -- Builds the development toolchain and uploads `Vorpal.lock`.
2. `build` -- Builds the `user` artifact (depends on `build-dev`).

Both run on `macos-latest`. The sequential dependency between jobs means CI time is at least the
sum of both build times. The S3 remote cache helps avoid redundant artifact downloads across runs.

## Benchmarking

**No benchmarking infrastructure exists.** There are no `#[bench]` functions, no criterion
benchmarks, no build-time measurement scripts, and no performance regression tracking. Build
duration is observable only through CI job logs.

## Scaling Considerations

### Artifact Count Growth

As more CLI tools or configuration files are added, build time grows linearly due to sequential
execution. Each new tool artifact adds a network download (cold) or cache lookup (warm) plus a
shell step execution.

### Configuration Complexity

The Claude Code configuration generator (`src/user/claude_code.rs`) is the most complex
configuration builder, producing a large JSON settings file with permissions, sandbox rules,
environment variables, hooks, and plugin settings. As this configuration grows, serialization time
increases marginally -- but `serde_json::to_string_pretty` is fast enough that this is not a
practical concern at current scale.

### Multi-Platform Builds

If the project expands to actively build for all 4 declared platforms, the source download and
artifact build cost multiplies accordingly. The lock file would need entries for each platform,
and CI would need runners for each target architecture.

## Gaps

- **No parallel artifact building**: All builds are sequential through `ConfigContext`. This is
  the single largest performance improvement opportunity, but may require upstream Vorpal SDK
  changes.
- **No build-time profiling**: There is no instrumentation to measure where time is spent during
  a build (downloads vs. shell steps vs. SDK overhead).
- **No benchmarking suite**: No automated performance regression detection.
- **No lazy evaluation**: All artifacts are always built, even if only a subset has changed. The
  content-addressed cache mitigates rebuild cost but not the overhead of checking/building each
  artifact definition.
- **No download parallelism**: Network downloads for tool binaries happen sequentially. Parallel
  downloads could significantly reduce cold build time.
- **No local cache warming strategy**: There is no documented approach for pre-populating the
  local artifact store from the remote S3 cache outside of a full build.
