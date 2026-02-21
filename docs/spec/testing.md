# Testing

> Project specification for testing strategy, test pyramid, coverage approach, and how to run
> tests in the `dotfiles.vorpal` project.

## Current State

**This project has no tests.** There are zero unit tests, zero integration tests, and zero
end-to-end tests in the codebase today. There is no `#[cfg(test)]` module in any source file, no
`#[test]` function anywhere, no `[dev-dependencies]` section in `Cargo.toml`, and no test step in
the CI workflow.

This is an honest assessment of the current state, not a judgment. The project is a personal
dotfiles configuration tool with a small surface area. The sections below describe what exists,
what gaps are present, and what testing would look like if introduced.

---

## How to Run Tests

### Rust Tests (if added)

```bash
# Run all tests
cargo test

# Run tests with output
cargo test -- --nocapture

# Run a specific test
cargo test <test_name>

# Run tests for the library only
cargo test --lib
```

### Build Verification (current CI approach)

The project currently uses build success as its primary validation mechanism:

```bash
# Build the dev environment artifact (runs in CI)
vorpal build 'dev'

# Build the user environment artifact (runs in CI)
vorpal build 'user'
```

These commands are run in the GitHub Actions workflow at `.github/workflows/vorpal.yaml`. If the
Rust code compiles and the Vorpal artifact builds successfully, the CI passes. This is the only
automated validation that exists.

---

## Test Infrastructure

### Compiler as Test

The Rust compiler provides strong static guarantees via the type system. For a configuration
generation project like this, compilation catches a meaningful class of errors:

- Type mismatches in builder patterns
- Missing required fields (if enforced by types)
- Invalid enum variants
- Borrow checker violations

### CI Pipeline

The CI workflow (`.github/workflows/vorpal.yaml`) runs two jobs:

1. **`build-dev`**: Builds the `dev` artifact on `macos-latest`, which compiles the Rust project
   and produces a development environment.
2. **`build`**: Depends on `build-dev`, builds the `user` artifact (the full dotfiles environment).

Neither job runs `cargo test`, `cargo clippy`, or `cargo fmt`. The CI relies solely on successful
`vorpal build` as the quality gate.

### No Test Dependencies

`Cargo.toml` contains no `[dev-dependencies]` section. There are no test utilities, mocking
libraries, assertion crates, or test harnesses configured.

### No Coverage Tooling

There is no coverage tool (tarpaulin, llvm-cov, grcov, or similar) configured or referenced
anywhere in the project.

---

## Test Pyramid Assessment

| Level | Count | Description |
|---|---|---|
| **Unit** | 0 | No `#[test]` functions exist in any source file |
| **Integration** | 0 | No integration tests (no `tests/` directory) |
| **End-to-End** | 0 | No e2e tests; `vorpal build` in CI is the closest approximation |

### What E2E Coverage Exists (Implicit)

The `vorpal build` commands in CI serve as a crude end-to-end validation. They exercise:

- Rust compilation (all source files must parse and type-check)
- Vorpal SDK integration (artifact definitions must be valid)
- Source dependency resolution (Vorpal.lock entries must resolve)
- Shell script generation (build steps produce shell scripts that execute)

However, this does not validate the *correctness* of generated configuration files -- only that
the build process completes without error.

---

## Source Files and Testability

The project has 9 Rust source files in `src/`:

| File | Purpose | Testability |
|---|---|---|
| `src/lib.rs` | Library root; exports modules, defines constants and `get_output_path` | `get_output_path` is a pure function, trivially testable |
| `src/vorpal.rs` | Binary entrypoint (`main`); wires up Vorpal context | Requires Vorpal runtime; not unit-testable without mocking |
| `src/file.rs` | `FileCreate`, `FileDownload`, `FileSource` structs | Builders depend on `ConfigContext`; need mocking or integration setup |
| `src/user.rs` | `UserEnvironment` builder; assembles all user artifacts | Heavy integration with Vorpal SDK; would need full context |
| `src/user/bat.rs` | `BatConfig` builder | Content generation is testable (string output) |
| `src/user/claude_code.rs` | `ClaudeCode` config builder | Content generation is testable (JSON output) |
| `src/user/ghostty.rs` | `GhosttyConfig` builder | Content generation is testable (string output) |
| `src/user/k9s.rs` | `K9sSkin` YAML builder | Content generation is testable (YAML output) |
| `src/user/opencode.rs` | `Opencode` JSON config builder | Content generation is testable (JSON output) |

### Most Testable Areas

The configuration builder structs (`BatConfig`, `GhosttyConfig`, `K9sSkin`, `ClaudeCode`,
`Opencode`) generate string/JSON/YAML content. Their output could be validated with unit tests
if the content generation logic were separated from the `build` method that depends on
`ConfigContext`.

Currently, content generation and artifact building are coupled in the same `build()` method,
making it difficult to unit test the configuration output without also invoking the Vorpal SDK.

---

## Gaps and Missing Pieces

### No Linting in CI

`cargo clippy` and `cargo fmt --check` are not run in CI. The Claude Code permissions config
allows `cargo clippy` and `cargo fmt`, suggesting these tools are used locally, but they are not
enforced as CI gates.

### No Test Step in CI

The workflow does not include a `cargo test` step. Even if tests were added to the source code,
they would not run automatically on PRs or pushes.

### No Snapshot Testing

For a project that generates configuration files (Ghostty config, K9s YAML skins, bat config,
Claude Code JSON settings, Opencode JSON), snapshot testing would be a natural fit. Tools like
`insta` (Rust snapshot testing crate) could verify that generated configs match expected output
and catch unintended changes.

### No Validation of Generated Content

There is no verification that the generated configuration files are valid for their target
applications. For example:

- Generated Ghostty config is not validated against Ghostty's schema
- Generated K9s YAML skin is not validated against K9s skin schema
- Generated Claude Code JSON is not validated against settings schema
- Generated Opencode JSON is not validated against config schema

### No Integration with Vorpal Build Verification

The Vorpal build process runs shell scripts that copy files and set permissions. There is no
verification that the symlink targets, file permissions, or directory structures produced by the
build are correct beyond the build completing without error.

---

## Recommendations for Testing (If Pursued)

### Priority 1: Unit Tests for Pure Functions

- Test `get_output_path` in `src/lib.rs` (trivial but establishes the pattern)
- Extract content generation from config builders into testable functions

### Priority 2: Snapshot Tests for Config Generation

- Add `insta` as a `[dev-dependencies]` crate
- Create snapshot tests for each config builder's output
- This catches regressions when config format or content changes unintentionally

### Priority 3: CI Improvements

- Add `cargo fmt --check` step to CI
- Add `cargo clippy` step to CI
- Add `cargo test` step to CI (once tests exist)

### Priority 4: Schema Validation

- Validate generated JSON configs against their respective schemas
- Validate generated YAML configs against expected structure

---

## Test Execution for Different Change Types

| Change Type | Expected Testing |
|---|---|
| Config value change (e.g., color, font) | Snapshot test update (if snapshots exist); manual verification |
| New config builder | Unit tests for content generation; snapshot of output |
| New dependency/artifact | Verify `vorpal build` succeeds (existing CI) |
| Vorpal SDK version bump | Full `vorpal build` verification (existing CI) |
| Builder API change | Unit tests for new builder patterns |
| Shell script changes (`file.rs`) | Integration test or manual `vorpal build` verification |

---

## Summary

The project currently relies on Rust's type system and successful Vorpal artifact builds as its
only quality gates. There are zero explicit tests, no test dependencies, no coverage tooling, and
no linting in CI. The project's small scope and configuration-generation nature mean this approach
has been sufficient so far, but it provides no protection against logical errors in generated
configuration content. Snapshot testing would be the highest-value addition if testing were
prioritized.
