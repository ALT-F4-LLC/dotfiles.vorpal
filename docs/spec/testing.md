---
project: "main"
maturity: "proof-of-concept"
last_updated: "2026-03-20"
updated_by: "@staff-engineer"
scope: "Testing infrastructure, strategy, and coverage for the dotfiles.vorpal configuration project"
owner: "@staff-engineer"
dependencies:
  - code-quality.md
---

# Testing Specification

## Overview

This document describes the current state of testing in the `dotfiles.vorpal` project — a Rust
binary that uses the Vorpal SDK to declaratively build and deploy a user environment (CLI tools,
configuration files, symlinks) across multiple system architectures.

## Current State

### No Tests Exist

The project contains **zero tests**. There are no:

- Unit tests (`#[cfg(test)]` / `#[test]` blocks)
- Integration tests (`tests/` directory)
- End-to-end tests
- Property-based tests
- Snapshot tests
- Test fixtures, helpers, or utilities
- Coverage tooling or coverage thresholds
- Test-related CI steps

The CI pipeline (`.github/workflows/vorpal.yaml`) runs `vorpal build` for the `dev` and `user`
artifacts but does not invoke `cargo test` or any test runner.

### Why This Is Acceptable (Currently)

The project is a **personal dotfiles configuration** — essentially a declarative manifest that
composes Vorpal SDK artifacts and configuration files. The codebase is:

- **Declarative**: Most code is builder-pattern calls chaining SDK methods (e.g., `ClaudeCode::new().with_permission_allow(...)`)
- **Thin**: ~490 lines of application code across 9 source files
- **Configuration-heavy**: The majority of logic is assembling string values and struct fields
- **Validated at build time**: `vorpal build` compiles and builds all artifacts, serving as an
  implicit integration test — if the configuration is malformed, the build fails

### Build-as-Test

The CI workflow provides the only form of validation:

1. **`build-dev`** — Runs `vorpal build 'dev'` on `macos-latest`, validating the Rust toolchain
   and protoc artifact configurations compile and resolve
2. **`build`** — Runs `vorpal build 'user'` (depends on `build-dev`), validating the full user
   environment artifact graph (16+ tools, 10+ config files, symlinks)

Both jobs run on every push to `main` and every pull request. Build failure = broken configuration.

## Test Pyramid Assessment

| Level       | Count | Coverage | Notes                                    |
|-------------|-------|----------|------------------------------------------|
| Unit        | 0     | 0%       | No `#[test]` blocks in any source file   |
| Integration | 0     | 0%       | No `tests/` directory                    |
| E2E         | 0     | 0%       | No end-to-end test infrastructure        |
| Build       | 2     | —        | CI `vorpal build` for `dev` and `user`   |

## Coverage Tooling

No coverage tools are configured. No `cargo-tarpaulin`, `cargo-llvm-cov`, or similar tooling is
present in dependencies or CI.

## Mocking & Test Utilities

None. The project does not use any mocking crates (`mockall`, `mockito`, etc.) or test utility
libraries.

## Where Tests Would Add Value

If the project grows beyond its current scope, the following areas would benefit from testing:

1. **`file.rs` — File artifact builders**: The `FileCreate`, `FileDownload`, and `FileSource`
   structs generate shell scripts. Unit tests could validate script content generation without
   requiring a Vorpal runtime.

2. **Configuration struct serialization**: The `ClaudeCode`, `GhosttyConfig`, `K9sSkin`,
   `BatConfig`, and `Opencode` modules generate configuration file content. Snapshot tests could
   catch unintended changes to generated config output.

3. **`get_output_path` utility**: Simple function that could have a trivial unit test, though
   the value is marginal.

4. **Symlink path construction**: The symlink mappings in `UserEnvironment::build` are complex
   string interpolations. Tests could validate path correctness.

## Gaps & Risks

- **No regression safety net**: If a code change breaks configuration generation, the only signal
  is a `vorpal build` failure in CI — which may not catch subtle content errors (e.g., a
  permission typo in the Claude Code config)
- **No local test workflow**: Developers cannot run `cargo test` to validate changes before
  pushing — there are no tests to run
- **Configuration drift is invisible**: Changes to generated config files (JSON, YAML, TOML, shell
  scripts) are not validated against expected output
- **SDK contract changes**: If `vorpal-sdk` or `vorpal-artifacts` change their APIs, there are no
  tests to catch incompatibilities beyond compilation
