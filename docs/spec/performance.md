---
project: "dotfiles.vorpal"
maturity: "draft"
last_updated: "2026-03-21"
updated_by: "@staff-engineer"
scope: "Performance characteristics, caching strategies, and build-time optimization of the dotfiles.vorpal project"
owner: "@staff-engineer"
dependencies:
  - architecture.md
  - operations.md
---

# Performance Specification

## 1. Project Performance Profile

dotfiles.vorpal is a **build-time configuration generator**, not a long-running service. Its performance profile is fundamentally different from a web application or API server:

- **No runtime hot path.** The Rust binary (`src/vorpal.rs`) runs once per `vorpal build` invocation, generates artifact definitions, and exits. There are no request-response cycles, connection pools, or query patterns.
- **No database.** The project has no database dependencies, queries, or ORM usage.
- **No concurrency under user control.** The project does not implement custom concurrency primitives. Async behavior is delegated entirely to the Vorpal SDK via `tokio` with the `rt-multi-thread` feature.
- **Performance-critical path = build time.** The only meaningful performance metric is how long `vorpal build 'user'` takes from invocation to completion.

## 2. Build-Time Performance

### 2.1 Artifact Build Sequence

The `UserEnvironment::build()` method (`src/user.rs:41-488`) builds 16 CLI tool artifacts and 10 configuration artifacts **sequentially** using `await` on each:

```
awscli2 -> bat -> direnv -> doppler -> fd -> gh -> git -> gopls -> jj -> jq ->
k9s -> kubectl -> lazygit -> nnn -> ripgrep -> tmux -> [config artifacts]
```

Each `.build(context).await?` call is awaited in order. There is no parallel artifact resolution at the application level -- parallelism, if any, is handled internally by the Vorpal SDK's `ConfigContext`.

### 2.2 Content-Addressed Caching (Vorpal)

The Vorpal build system uses **content-addressed artifact storage** at `/var/lib/vorpal/store/`. Artifacts are identified by digest (see `Vorpal.lock` entries with `digest` fields). This provides implicit caching:

- If an artifact's inputs (source, dependencies) have not changed, the Vorpal runtime can skip rebuilding it.
- The `Vorpal.lock` file pins 27 source entries with SHA-256 digests, ensuring reproducible builds.

The project itself does **not** implement any custom caching logic beyond what Vorpal provides.

### 2.3 Remote Artifact Registry (S3)

Builds use an S3-backed remote registry (`altf4llc-vorpal-registry`) for artifact storage:

- **CI configuration** (`.github/workflows/vorpal.yaml`): Both `build-dev` and `build` jobs configure `registry-backend: s3` with the `altf4llc-vorpal-registry` bucket.
- **Local builds**: The `.envrc` configures the same registry for local development.
- **Effect on performance**: Remote caching means that artifacts already built and pushed (by CI or another developer) can be fetched from S3 rather than rebuilt locally. This is the single largest performance optimization in the project.

### 2.4 Two-Phase CI Build

The CI pipeline splits the build into two sequential jobs:

1. **`build-dev`**: Builds the `dev` artifact (Protoc + Rust toolchain), uploads `Vorpal.lock`.
2. **`build`**: Depends on `build-dev`, builds the `user` artifact.

This two-phase approach means the `user` build can leverage cached `dev` artifacts from the first phase. The `build` job uses a matrix strategy, but currently only has a single entry (`user`), so no actual parallelism occurs.

## 3. Compile-Time Performance

### 3.1 Rust Compilation

The project compiles as a single Rust binary (`vorpal`) with these dependencies:

| Dependency | Impact |
|---|---|
| `tokio` (rt-multi-thread) | Heavyweight async runtime; increases compile time |
| `serde` + `serde_json` (derive) | Proc macros add compile time; used for JSON config generation |
| `vorpal-sdk` (git dependency) | Fetched from git on each clean build; not pinned to a version |
| `vorpal-artifacts` (git dependency) | Same git-fetch concern |
| `anyhow` | Minimal compile impact |
| `indoc` | Minimal compile impact |

The `Cargo.lock` pins 432 transitive dependencies (65,996 bytes).

### 3.2 Known Compile-Time Concerns

- **Git dependencies**: `vorpal-artifacts` is a git dependency (`branch = "main"`). Every `cargo update` or clean build fetches from the remote. This is not pinned to a specific commit in `Cargo.toml` (though `Cargo.lock` pins it).
- **No incremental build configuration**: The project does not configure `[profile.dev]` or `[profile.release]` in `Cargo.toml` -- it uses Rust defaults.
- **No build caching in CI beyond Vorpal**: The GitHub Actions workflow does not use `actions/cache` for the Cargo target directory or registry. Rust compilation starts from scratch on each CI run (though the Vorpal artifact cache means the built binary's output artifacts are cached).

## 4. Configuration Generation Performance

The configuration generators (`ClaudeCode`, `GhosttyConfig`, `BatConfig`, `K9sSkin`, `Opencode`) use the builder pattern to construct in-memory representations, then serialize to strings:

- `ClaudeCode` serializes via `serde_json::to_string_pretty()` (`src/user/claude_code.rs:534`).
- `GhosttyConfig` uses `formatdoc!` macro for plain-text generation.
- `BatConfig` uses simple string concatenation.
- `K9sSkin` uses YAML serialization (via serde).

All config generation is trivially fast (microsecond-scale string operations). The performance cost is in the subsequent Vorpal artifact creation (shell step execution, content-addressed storage), not in the serialization.

## 5. Statusline Script Performance

The Claude Code statusline script (`src/user/statusline.sh`) runs repeatedly as a shell command. It implements a local caching strategy:

- **Git info cache** (lines 59-86): Caches `git` command output to `/tmp/claude-statusline-git-cache-{hash}` with a 5-second TTL. Uses `cksum` for cache key derivation and `stat -f %m` for age checking.
- **Token data**: Reads Claude Code session data via `jq` from the Claude status API. No caching -- reads fresh data each invocation.

This is the only user-facing component with a recurring performance impact, as it runs on every statusline refresh.

## 6. Gaps and Missing Pieces

### 6.1 No Benchmarks

The project contains no benchmarks (`cargo bench`, criterion, or custom timing). There is no way to measure build-time regression.

### 6.2 No Parallel Artifact Building

The sequential `await` chain in `UserEnvironment::build()` means artifacts that have no dependency relationship (e.g., `bat` and `kubectl`) are built one at a time. The Vorpal SDK may handle this internally, but the application code does not express artifact-level parallelism.

### 6.3 No Build Profiling

There is no `--timings` flag usage, no build tracing, and no CI step that records or compares build duration over time.

### 6.4 No Cargo Build Cache in CI

GitHub Actions does not cache `target/` or `~/.cargo/registry/`. Each CI run pays the full Rust compilation cost for the `vorpal` binary itself (distinct from the Vorpal artifact cache which caches the build *outputs*).

### 6.5 No Lazy Loading or Pagination

Not applicable -- the project is a build tool, not a service. All artifacts are built eagerly in a single pass.

### 6.6 No Connection Pooling

Not applicable -- the project makes no network connections at the application level. Network operations (S3 registry access, source downloads) are handled by the Vorpal runtime.

## 7. Performance Optimization Opportunities

These are observations, not recommendations for immediate action:

1. **Parallel artifact resolution**: If the Vorpal SDK supports concurrent artifact builds, `UserEnvironment::build()` could use `tokio::join!` or `futures::join_all` for independent artifacts rather than sequential awaits.
2. **Cargo CI caching**: Adding `actions/cache` for `~/.cargo/registry` and `target/` in the GitHub Actions workflow would reduce CI compile times for the `vorpal` binary.
3. **Build timing telemetry**: Adding duration logging around major build phases would establish a baseline for detecting regressions.
