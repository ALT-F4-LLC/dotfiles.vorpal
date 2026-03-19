---
project: "dotfiles.vorpal"
maturity: "experimental"
last_updated: "2026-03-18"
updated_by: "@staff-engineer"
scope: "Testing strategy, current test infrastructure, and coverage approach for the dotfiles.vorpal project"
owner: "@staff-engineer"
---

# Testing

## Current State

**The project has no tests.** There are zero `#[test]` functions, zero `#[cfg(test)]` modules,
zero dev-dependencies, and zero test-related CI steps. This is an honest assessment of the
codebase as it exists today.

## What Exists

### Build Verification (CI)

The only automated quality gate is the GitHub Actions workflow
(`.github/workflows/vorpal.yaml`), which runs on every push to `main` and on pull requests:

1. **`build-dev`** -- Builds the `dev` artifact via `vorpal build 'dev'`
2. **`build`** -- Builds the `user` artifact via `vorpal build 'user'`

Both jobs run on `macos-latest` with the Vorpal runtime provisioned via
`ALT-F4-LLC/setup-vorpal-action@main`. The workflow uses S3-backed remote caching for artifact
storage.

This means the only automated verification is "does the Rust code compile and does Vorpal
successfully produce the artifact." There is no `cargo test`, `cargo clippy`, `cargo fmt --check`,
or any other quality gate in CI.

### Static Analysis

- **No `clippy.toml`** or `rustfmt.toml` configuration files exist.
- **No CI steps** run `cargo clippy` or `cargo fmt --check`.
- The Claude Code permissions configuration does allowlist `Bash(cargo clippy:*)`,
  `Bash(cargo fmt:*)`, and `Bash(cargo test:*)`, indicating these tools are expected to be
  used during local development, but they are not enforced in CI.

### Dev Dependencies

`Cargo.toml` has no `[dev-dependencies]` section. No test frameworks (e.g., `rstest`,
`test-case`, `proptest`), assertion libraries, mocking libraries, or coverage tools are
configured.

### Local Test Evidence

The `target/debug/.fingerprint/` directory contains test fingerprints (e.g.,
`dep-test-lib-dotfiles`, `test-bin-vorpal`), indicating that `cargo test` has been run locally
at some point. Since the codebase has no `#[test]` functions, these runs would have produced
zero test results -- just compiler verification.

## Test Pyramid Breakdown

| Level | Count | Notes |
|---|---|---|
| Unit tests | 0 | No `#[test]` functions anywhere in `src/` |
| Integration tests | 0 | No `tests/` directory exists |
| End-to-end tests | 0 | No e2e test infrastructure |
| Build verification | 2 CI jobs | `vorpal build 'dev'` and `vorpal build 'user'` |

## How to Run Tests

```bash
# Compile check (works today)
cargo check

# Run tests (works today, but produces "0 tests" output)
cargo test

# Lint (works today, no custom config)
cargo clippy

# Format check (works today, no custom config)
cargo fmt --check

# Build artifacts via Vorpal (the actual CI gate)
vorpal build 'dev'
vorpal build 'user'
```

## What Would Be Worth Testing

Given the nature of this project -- a configuration generator that produces files, symlinks,
and tool artifacts -- the following areas carry the most risk and would benefit most from tests:

### High Value

- **Configuration output correctness**: The builder structs (`ClaudeCode`, `GhosttyConfig`,
  `K9sSkin`, `BatConfig`, `Opencode`) serialize to specific formats (JSON, YAML, key-value,
  plain text). Tests could verify that the serialized output matches expected format and content,
  catching regressions when fields are added or defaults change.
- **`ClaudeCode` JSON serialization**: This is the most complex configuration struct with nested
  permissions, sandbox config, MCP server rules, hooks, and environment variables. Incorrect
  serialization could break Claude Code behavior silently.
- **`K9sSkin` YAML generation**: The `format_yaml_list` helper and the large `formatdoc!` template
  could produce malformed YAML if field values contain special characters.

### Medium Value

- **`FileCreate` / `FileDownload` / `FileSource` shell script generation**: These structs
  generate bash scripts with string interpolation. Verifying the generated scripts are syntactically
  correct and handle edge cases (special characters in file content, names) would add confidence.
- **`get_output_path` function**: Simple but foundational -- used to construct all store paths.
  A unit test would prevent silent breakage.

### Lower Value (for this project type)

- **Vorpal artifact wiring**: Testing that all artifacts are correctly wired in
  `UserEnvironment::build` would require mocking the Vorpal SDK's `ConfigContext`, which is
  complex and tightly coupled to the build system. The CI build-verification jobs already
  cover this path.
- **Symlink mapping correctness**: The symlink pairs in `user.rs` are static data. Testing
  them adds little value beyond what a build-time check already provides.

## Gaps and Risks

### Critical Gaps

1. **No regression safety net**: Any change to a configuration builder could silently produce
   incorrect output. Without tests, the only way to detect breakage is manual inspection or
   waiting for a downstream tool to fail at runtime.
2. **No lint or format enforcement in CI**: Code quality is entirely honor-system. Clippy
   warnings and formatting drift can accumulate unchecked.
3. **No test for the most complex struct**: `ClaudeCode` has ~50 builder methods and produces
   nested JSON with permissions, sandbox settings, attribution, MCP rules, and hooks. This is
   the highest-risk area in the codebase for serialization bugs.

### Mitigating Factors

1. **Small codebase**: ~9 source files, ~1600 lines of Rust. The blast radius of untested
   changes is bounded by project size.
2. **Compilation as verification**: The Rust compiler catches type errors, missing fields, and
   most structural issues at compile time. The builder pattern used throughout enforces correct
   construction at the type level.
3. **Vorpal build as integration test**: The CI workflow's `vorpal build` step exercises the
   full artifact graph end-to-end. If any configuration generator produces invalid output that
   prevents artifact creation, the build fails.
4. **Declarative nature**: Most of the code is declarative configuration wiring rather than
   complex business logic with branching behavior. The surface area for logic bugs is small.

## Testing Approach Recommendations

If tests are added to this project, the highest-value starting point would be:

1. **Snapshot tests for configuration output**: Use `insta` or a similar snapshot testing
   library to capture the serialized output of each configuration builder with representative
   inputs. This provides regression detection with minimal test code.
2. **Add `cargo clippy` and `cargo fmt --check` to CI**: Zero-effort quality gates that
   prevent common issues. These require no test code, just additional CI steps.
3. **Unit tests for `ClaudeCode` serialization**: Given its complexity, at minimum verify that
   a fully-configured `ClaudeCode` instance serializes to valid JSON with the expected structure.

These recommendations are not requirements. The project functions without tests today due to its
small scope, declarative nature, and the Vorpal build acting as an integration check.
