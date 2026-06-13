---
project: "main"
maturity: "draft"
last_updated: "2026-06-13"
updated_by: "@staff-engineer"
scope: "Describes the observed test runners, CI validation, fixtures, coverage posture, and testing gaps for this repository."
owner: "@staff-engineer"
dependencies: []
---

# Testing Specification

## Current Test Surface

This repository has tests. The observed automated test surface is:

- Rust unit tests compiled and run by `cargo test`.
- Rust integration tests in `tests/codex_payload.rs`.
- A standalone Bash hook test in `tests/teammate-idle-hook.test.sh`.
- GitHub Actions validation in `.github/workflows/vorpal.yaml`.

No existing `docs/spec/` files were present during this bootstrap, so this spec does not depend on another project spec.

## Rust Tests

The Rust crate is configured by `Cargo.toml` as package `dotfiles`, edition 2021, with a binary named `vorpal` at `src/vorpal.rs`. No `[dev-dependencies]` section is present.

`cargo test` currently discovers:

- One unit test in `src/user/codex.rs`, `serializes_current_config_shape`, which verifies selected TOML serialization output for the Codex config builder.
- Five integration tests in `tests/codex_payload.rs`.
- One doctest from `src/user/opencode.rs`, which is ignored.
- Zero unit tests for the `src/vorpal.rs` binary target.

The integration suite in `tests/codex_payload.rs` validates repo-shape and generated-payload contracts for Codex assets:

- `agents/codex/*.toml` must match the expected seven-role set, parse as TOML, include required fields, omit Claude-only fields, and avoid Claude-only runtime terms.
- `agents/codex/team-lead.toml` must preserve delegation-oriented instructions and avoid older direct-first delegation language.
- `src/user.rs` must register all expected Codex agent files and configure the Codex agent snapshot and symlink target.
- `skills/codex/*/SKILL.md` must match the expected skill directory set, include YAML frontmatter with `name` and `description`, omit Claude skill-only frontmatter, and avoid Claude-only runtime terms.
- `skills/codex/init-specs/SKILL.md` must require staff-engineer delegation and staff-engineer ownership metadata for generated specs.

These tests read live repository files rather than isolated fixtures. That keeps them close to the deployable payload, but changes to agent or skill inventory require synchronized updates to the expected constant lists in the test.

## Shell Hook Tests

`tests/teammate-idle-hook.test.sh` directly executes `src/user/teammate-idle-hook.sh` through Bash. It is a self-contained test harness with local assertion helpers and requires `jq` to parse JSON output.

Observed cases cover:

- Input with `agent_type`.
- Input without `agent_type`.
- Malformed stdin.
- Empty stdin.
- Injection safety for a command-substitution-shaped `agent_type` payload using a `mktemp` sentinel file.

The shell test fails fast if the hook file is missing or `jq` is unavailable. It uses temporary filesystem state for the injection sentinel and removes the scratch directory when the case completes.

## CI Validation

GitHub Actions uses `.github/workflows/vorpal.yaml` on pull requests and pushes to `main`.

The observed jobs are:

- `test-hooks` on `ubuntu-latest`, running `bash tests/teammate-idle-hook.test.sh`.
- `build-dev` on `macos-latest`, using `ALT-F4-LLC/setup-vorpal-action@main`, S3-backed registry configuration, and AWS credentials to run `vorpal build 'dev'`; it uploads `Vorpal.lock` as an artifact.
- `build` on `macos-latest`, after `build-dev`, using the same Vorpal setup to run `vorpal build 'user'`.

The workflow does not explicitly run `cargo test`, `cargo fmt`, `cargo clippy`, shell linting, or coverage tooling. The Rust tests are therefore a local verification surface unless another external CI path runs them outside the observed workflow.

## Fixtures, Mocks, And Test Data

No dedicated `fixtures/`, `mocks/`, snapshot, or golden-output directories were observed. Tests use:

- Inline constants for expected Codex roles, skills, banned runtime terms, and Claude-only fields.
- Live repository files under `agents/codex`, `skills/codex`, and `src`.
- Inline JSON payload strings for the shell hook test.
- A temporary sentinel file path for injection-safety validation.

No network mocks were observed. The current tests do not exercise remote artifact retrieval, S3 registry behavior, or live Vorpal store interactions.

## Coverage And Quality Tooling

No coverage configuration or coverage command was observed. No `cargo llvm-cov`, `cargo tarpaulin`, `grcov`, or similar coverage tooling appears in the repository files inspected.

No dedicated test runner wrapper, `Makefile`, `Justfile`, `nextest` config, or `.cargo/config` test profile was observed. The direct local commands are:

```bash
cargo test
bash tests/teammate-idle-hook.test.sh
```

## Recommended Verification For Changes

For changes touching Rust builders, generated config shape, Codex agents, Codex skills, or `src/user.rs`, run:

```bash
cargo test
```

For changes touching `src/user/teammate-idle-hook.sh`, Claude/Codex hook wiring, or shell/JSON output behavior, run:

```bash
bash tests/teammate-idle-hook.test.sh
```

For changes touching Vorpal artifact construction, generated symlink layout, external tool inventory, or `Vorpal.lock`, use the CI-equivalent build checks where credentials and Vorpal setup are available:

```bash
vorpal build 'dev'
vorpal build 'user'
```

## Gaps & Risks

- CI does not explicitly run `cargo test`, so the Rust unit and integration tests can pass locally while being absent from the observed GitHub Actions gate.
- CI does not run Rust formatting or lint checks such as `cargo fmt` or `cargo clippy`.
- CI does not run shell linting for `tests/teammate-idle-hook.test.sh` or `src/user/teammate-idle-hook.sh`.
- No coverage tooling or coverage threshold is configured.
- Most Rust builder modules have no observed unit tests; only the Codex config builder has an observed unit test.
- The Vorpal build path is validated by CI, but there are no observed tests that assert specific generated artifact contents, symlink manifests, or store paths beyond the targeted Codex payload assertions.
- The shell hook test depends on `jq`; environments without `jq` fail with a harness prerequisite error rather than executing assertions.
- Integration tests are tightly coupled to hard-coded role and skill inventories. That is useful for payload drift detection but requires deliberate test updates for intentional inventory changes.
- README CI documentation describes the build jobs but does not mention the observed `test-hooks` workflow job, so the documentation and workflow are partially out of sync.
