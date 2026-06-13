---
project: "main"
maturity: "draft"
last_updated: "2026-06-13"
updated_by: "@staff-engineer"
scope: "Describes observed performance characteristics of the Vorpal-backed dotfiles build, generated configuration payloads, cache usage, and local feedback loops."
owner: "@staff-engineer"
dependencies: []
---

# Performance Specification

## Performance-Critical Surfaces

This repository builds a declarative dotfiles environment through Vorpal. The README defines two top-level build targets: `dev`, which provides the toolchain used to build the project, and `user`, which publishes the full user environment with CLI tools, configuration files, and symlinks. The documented operator path is to run `vorpal build 'dev'` before `vorpal build 'user'`.

The main user build is performance-sensitive because it fans out across external tools, generated configuration artifacts, and copied agent and skill directories. `src/user.rs` currently requests 20 tool artifacts in sequence before building configuration artifacts. The final `UserEnvironment` aggregates those tools plus generated configs, copied agent and skill directories, shell scripts, and symlinks into the published environment.

The local Rust feedback loop is separate from the full Vorpal artifact build. The Rust crate has a `vorpal` binary, generated-configuration builders, and tests that inspect the checked-in agent and skill trees. The repository already contains a large local `target/` directory, so hot-cache Rust tests are expected to be much faster than a cold build.

## Build Latency

Observed local test latency on this machine:

- `/usr/bin/time -p cargo test` completed successfully in 0.45s real time with 6 passing tests and 1 ignored doc test.
- `/usr/bin/time -p bash tests/teammate-idle-hook.test.sh` completed successfully in 0.15s real time with 18 passing assertions.

No full `vorpal build 'dev'` or `vorpal build 'user'` timing was recorded during this spec pass. The full build is expected to be materially slower than the hot Rust tests because it resolves and builds or restores external artifacts, copies directory trees into Vorpal artifacts, and publishes symlinks into the user environment.

CI build latency is serialized across the Vorpal build jobs. `.github/workflows/vorpal.yaml` runs `test-hooks`, `build-dev`, and `build`; the `build` job has `needs: build-dev`, so the `user` build cannot start until the `dev` build completes and uploads `Vorpal.lock`. The `build` job currently has a single-item matrix containing only `user`, so matrix parallelism is structurally available but unused.

## Caching And Remote Artifacts

The README documents S3-backed remote caching through the `altf4llc-vorpal-registry` registry. CI configures the same S3 registry through `ALT-F4-LLC/setup-vorpal-action@main` in both the `build-dev` and `build` jobs, using AWS credentials and region values supplied by GitHub secrets and variables.

`Vorpal.lock` records content-addressed remote sources for external artifacts. The checked-in lock currently lists 34 source entries, all with remote HTTPS paths and digests. Sources include GitHub release assets, `sdk.vorpal.build` artifacts, AWS CLI, Kubernetes downloads, GNU mirrors, and the TokyoNight theme fetched from raw GitHub content.

The local Rust build cache is present and large: `target/` was observed at approximately 1.4G. The hot-cache `cargo test` result above shows that local Rust checks can be fast when this cache is warm. There is no observed CI cache for Cargo registry, Cargo build outputs, or the local `target/` directory in `.github/workflows/vorpal.yaml`; CI appears to rely primarily on Vorpal's remote artifact registry for the expensive environment artifacts.

## Generated Configuration Size

The build publishes both generated files and source directory snapshots:

- Agent source directories: 7 Claude Code markdown agent files and 7 Codex TOML agent files.
- Skill source directories: 13 Claude Code `SKILL.md` files and 14 Codex `SKILL.md` files.
- Large checked-in text payloads: `agents/claude-code/team-lead.md` is about 66KB, `src/user/opencode.rs` is about 79KB, `src/user/claude_code.rs` is about 55KB, and the combined sampled agent, skill, source, README, and lock files were about 882KB by `wc -c`.
- Directory size observations: `agents/` about 324K, `skills/` about 304K, `src/` about 276K, `docs/` about 504K, and `tests/` about 20K.

`FileSource` copies complete source directories into Vorpal artifact outputs for `agents/claude-code`, `agents/codex`, `skills/claude-code`, and `skills/codex`. Changes anywhere inside those copied directories can invalidate the corresponding directory artifact even when the changed file is small.

`Vorpal.toml` lists only `src`, `Cargo.toml`, and `Cargo.lock` as source includes. That means the Rust program's own source hash is scoped narrowly, while agent and skill directory contents are captured later through `FileSource` artifact sources inside the program.

## Local Feedback Loops

The fastest verified checks are the Rust tests and the shell hook test. Rust tests validate serialization and schema constraints for Codex agent and skill payloads, including directory walks over `agents/codex` and `skills/codex`. The shell test validates the teammate idle hook behavior and requires `jq`.

The generated config builders use strongly typed Rust structures with `serde`, `serde_json`, and `toml`. This gives fast compile-time and unit-test feedback for shape regressions, but it does not prove that a full Vorpal user build succeeds or that remote artifact restoration is healthy.

The CI workflow runs the shell hook test but does not currently run `cargo test` as a standalone job. The Vorpal builds may compile or evaluate the Rust generator indirectly, but the repository has no observed dedicated Cargo test gate in GitHub Actions.

## Concurrency

The Rust binary uses `#[tokio::main]`, and `Cargo.toml` enables Tokio's `rt-multi-thread` feature. The generator code itself awaits most artifact builder calls sequentially. In `src/user.rs`, the tool artifact declarations from `awscli2` through `zoxide` are written as a linear chain of `.build(context).await?` calls, followed by linear configuration artifact builds.

Any parallelism within a full build therefore appears to depend on the Vorpal SDK's internal scheduler after artifacts and steps have been registered, not on explicit concurrent orchestration in this repository. This spec did not verify Vorpal SDK scheduling behavior.

CI concurrency is limited by the `build-dev` to `build` dependency. The `test-hooks` job has no dependency and can run beside `build-dev`; the `user` build cannot run beside `dev` because it explicitly depends on `build-dev`.

## Known Bottlenecks

The highest-confidence bottlenecks are remote artifact resolution and restore/build work for the full `user` environment, because the environment includes many third-party CLI tools and remote source archives. Remote cache misses, unavailable AWS credentials, S3 latency, or upstream source fetch latency would directly affect full build time.

Directory snapshot artifacts are another likely cost center. The agent and skill trees are text-heavy and are copied wholesale into artifact outputs. This keeps publication simple, but it makes complete directory copies part of the build path and increases invalidation scope for documentation-only edits inside those trees.

The CI path serializes the two Vorpal build jobs and uploads `Vorpal.lock` between them. This is operationally simple and preserves the dev-before-user build order, but it prevents end-to-end CI time from benefiting from parallel execution across those two build targets.

## Gaps & Risks

- No cold-cache or remote-cache-miss timings were observed for `vorpal build 'dev'` or `vorpal build 'user'`.
- No benchmark or size budget exists for generated Claude Code, Codex, OpenCode, Ghostty, Bat, or K9s configuration output.
- No observed CI timing history is checked into the repository, so latency trends cannot be evaluated from repo evidence alone.
- No observed Cargo cache is configured in GitHub Actions; if Vorpal does not cover Rust compilation reuse, CI may pay cold Cargo costs.
- The generator source is mostly sequential at the call site; if Vorpal SDK does not internally parallelize independent artifacts, full builds may leave concurrency unused.
- `FileSource` copies complete agent and skill directories, so small edits may still force full directory artifact rebuilds.
- Remote cache health depends on AWS credentials and the `altf4llc-vorpal-registry` S3 bucket, but this spec did not validate bucket availability or cache hit rates.

## Evidence

- `README.md`: artifact model, build commands, S3 cache description, CLI tool inventory, and symlink publication.
- `.github/workflows/vorpal.yaml`: CI job graph, S3 registry setup, `build-dev` to `build` dependency, and shell hook test job.
- `Cargo.toml`: Rust binary/dependencies and Tokio multi-thread runtime feature.
- `Vorpal.toml`: narrow source includes for the Vorpal project.
- `Vorpal.lock`: remote source URLs and digests for external artifacts.
- `src/vorpal.rs`: top-level `dev` and `user` artifact construction.
- `src/user.rs`: user environment artifact fan-out, copied source directories, and symlink publication.
- `src/file.rs`: file creation, remote download, and source-directory copy artifact helpers.
- `tests/codex_payload.rs` and `tests/teammate-idle-hook.test.sh`: local validation surfaces.
