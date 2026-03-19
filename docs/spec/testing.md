---
project: "dotfiles.vorpal"
maturity: "experimental"
last_updated: "2026-03-18"
updated_by: "@staff-engineer"
scope: "Testing strategy, current coverage, gaps, and recommendations for the dotfiles.vorpal project"
owner: "@staff-engineer"
---

# Testing

## Current State

**This project has no tests.** There are zero unit tests, zero integration tests, and zero end-to-end tests in the codebase. No `#[cfg(test)]` blocks, no `#[test]` functions, no `tests/` directory, and no test utilities or fixtures exist anywhere in the source tree.

The CI pipeline (`.github/workflows/vorpal.yaml`) runs only `vorpal build 'dev'` and `vorpal build 'user'` -- it does not execute `cargo test`, `cargo clippy`, `cargo check`, or `cargo fmt --check`. The build succeeding is the only signal that the code is not broken.

## Test Infrastructure

### Build Toolchain

- **Language**: Rust (edition 2021)
- **Test runner**: `cargo test` (built into Cargo, available but unused)
- **No test dependencies** in `Cargo.toml` -- no `[dev-dependencies]` section exists
- **No coverage tools** configured (no `cargo-tarpaulin`, `cargo-llvm-cov`, or similar)
- **No linting in CI** -- `cargo clippy` and `cargo fmt --check` are not run

### What Exists

- The Rust standard test framework is available by default via `cargo test`
- The `anyhow` crate is used for error handling, which is test-friendly
- The `serde` and `serde_json` crates are used for serialization, which produces testable output

### What Does Not Exist

- No `[dev-dependencies]` section in `Cargo.toml`
- No `tests/` directory for integration tests
- No `#[cfg(test)]` modules in any source file
- No test fixtures, helpers, or mocking utilities
- No coverage configuration or reporting
- No property-based testing (e.g., `proptest`, `quickcheck`)
- No snapshot testing (e.g., `insta`)
- No CI test steps

## Code Analysis for Testability

### Highly Testable (Pure Data Transformation)

The configuration generator modules produce deterministic output from their inputs. These are the most natural candidates for unit testing:

| Module | What It Does | Testability |
|--------|-------------|-------------|
| `src/user/bat.rs` | Generates bat config string from theme name | Trivial -- pure string construction |
| `src/user/ghostty.rs` | Generates Ghostty key-value config | Trivial -- deterministic template |
| `src/user/k9s.rs` | Generates K9s YAML skin from color palette | Medium -- large template, YAML format |
| `src/user/claude_code.rs` | Generates Claude Code JSON settings | Medium -- complex JSON with many optional fields |
| `src/user/opencode.rs` | Generates OpenCode JSON config | Medium -- nested JSON with enums |

All of these follow the builder pattern (`new()` -> `with_*()` -> `build()`), where `build()` is async and requires a `ConfigContext` from the Vorpal SDK. The `ConfigContext` dependency makes unit testing harder because it couples config generation to the Vorpal runtime.

### Difficult to Test (External Dependencies)

| Module | Constraint |
|--------|-----------|
| `src/vorpal.rs` | `main()` function that calls into Vorpal SDK -- requires a running Vorpal daemon |
| `src/file.rs` | `FileCreate`, `FileDownload`, `FileSource` all call `step::shell()` and `Artifact::build()` -- tightly coupled to Vorpal SDK |
| `src/user.rs` | `UserEnvironment::build()` orchestrates all artifact builds -- requires full Vorpal context |

The core issue is that the builder pattern's `build()` methods take `&mut ConfigContext`, which is a Vorpal SDK type that assumes a running build system. There is no mock, fake, or trait abstraction for `ConfigContext` in the current codebase.

## Test Pyramid Assessment

| Level | Current | Ideal for This Project |
|-------|---------|----------------------|
| **Unit** | 0 tests | Low-to-medium priority -- most value from testing serialization output of config generators |
| **Integration** | 0 tests | Low priority -- would require Vorpal SDK test harness |
| **End-to-end** | 0 tests (CI build is the closest analog) | Already partially covered by CI `vorpal build` steps |

### Realistic Unit Test Targets

The highest-value, lowest-effort tests would verify the serialized output of configuration generators. However, this requires either:

1. **Extracting serialization logic** from the `build()` methods so it can be tested without `ConfigContext`, or
2. **Creating a mock/fake `ConfigContext`** (depends on whether the Vorpal SDK supports this)

Currently, the serialization and the Vorpal artifact registration are interleaved in each `build()` method. For example, in `claude_code.rs`, `serde_json::to_string_pretty(&self)` happens inside `build()` alongside `FileCreate::new(...).build(context).await`. Separating these would make the serialization independently testable.

### What CI Currently Validates

The GitHub Actions workflow provides a coarse "does it compile and build" check:

1. `vorpal build 'dev'` -- validates the dev toolchain artifact builds successfully
2. `vorpal build 'user'` -- validates all user environment artifacts build successfully

This is effectively a build-time integration test. If any configuration generator produces invalid output or any artifact definition is malformed, the build fails. This catches structural errors but not semantic correctness (e.g., a valid JSON file with wrong permission values).

## Gaps

### Critical Gaps

1. **No serialization output validation**: The config generators produce JSON, YAML, and plain-text configs. None of these outputs are verified against expected values. A refactor could silently change the output format without detection.

2. **No CI quality gates**: `cargo clippy`, `cargo fmt --check`, and `cargo test` are not run in CI. Code can be merged with lint warnings, formatting inconsistencies, or (if tests existed) test failures.

3. **No regression protection**: Without tests, there is no way to catch regressions short of the full `vorpal build` pipeline succeeding. Subtle bugs in generated configs (wrong JSON keys, missing fields, incorrect values) would not be caught.

### Moderate Gaps

4. **No snapshot tests for generated configs**: Tools like `insta` would provide high-value regression detection for the config generators with minimal test code.

5. **No validation of symlink targets**: The `UserEnvironment` defines symlink mappings, but there is no verification that the target paths are correct or that the symlinks would resolve after a build.

### Low-Priority Gaps

6. **No property-based testing**: For the builder pattern structs, property-based testing could verify that arbitrary combinations of `with_*()` calls produce valid output. This is low priority given the project's maturity level.

## Recommendations

### Phase 1: CI Quality Gates (No Code Changes)

Add `cargo check`, `cargo clippy -- -D warnings`, and `cargo fmt -- --check` to the CI workflow. This requires only a workflow file change and provides immediate value.

### Phase 2: Snapshot Tests for Config Generators

1. Add `insta` as a `[dev-dependency]`
2. For each config generator, extract the serialization logic into a testable function that returns `String` (or `serde_json::Value`) without requiring `ConfigContext`
3. Write snapshot tests that capture the expected output for known inputs
4. Run `cargo test` in CI

This would cover `BatConfig`, `GhosttyConfig`, `K9sSkin`, `ClaudeCode`, and `Opencode` -- the five configuration generators that produce the most complex output.

### Phase 3: Structural Validation

Add tests that parse the generated output and validate structural properties:
- JSON configs parse as valid JSON with expected top-level keys
- YAML configs parse as valid YAML
- Permission lists in `ClaudeCode` follow expected patterns
- Symlink path pairs in `UserEnvironment` follow expected conventions

### Not Recommended

- **Mocking `ConfigContext`**: Unless the Vorpal SDK provides a test harness or trait-based abstraction, mocking the build context is not worth the effort. The `vorpal build` CI step already validates artifact construction.
- **End-to-end symlink tests**: Testing that symlinks resolve correctly requires a full Vorpal runtime and host filesystem access. The CI build already covers this implicitly.

## How to Run Tests

```bash
# Currently a no-op (no tests exist)
cargo test

# Recommended additions to CI
cargo check
cargo clippy -- -D warnings
cargo fmt -- --check
cargo test
```
