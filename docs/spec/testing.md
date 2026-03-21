---
project: "dotfiles.vorpal"
maturity: "proof-of-concept"
last_updated: "2026-03-21"
updated_by: "@staff-engineer"
scope: "Testing infrastructure, coverage, and validation practices for dotfiles.vorpal"
owner: "@staff-engineer"
dependencies:
  - code-quality.md
---

# Testing Specification

## 1. Current State

### 1.1 Test Presence

**The project has zero application-level tests.** There are no unit tests, integration tests, end-to-end tests, or any other form of automated test within the `src/` directory. No `#[test]` attributes, `#[cfg(test)]` modules, or assertion macros exist in any source file.

### 1.2 Test Infrastructure

| Component | Status |
|---|---|
| Unit tests (`#[test]`) | None |
| Integration tests (`tests/` directory) | Directory does not exist |
| Test fixtures / test data | None |
| Mocking libraries | Not in `Cargo.toml` dependencies |
| Coverage tools (tarpaulin, llvm-cov) | Not configured |
| Property-based testing (proptest, quickcheck) | Not configured |
| Benchmarks (`benches/` directory) | Directory does not exist |

### 1.3 CI/CD Validation

The GitHub Actions workflow (`.github/workflows/vorpal.yaml`) provides the only automated validation:

- **`build-dev` job**: Runs `vorpal build 'dev'` on `macos-latest` — validates that the development environment artifact compiles and builds successfully via the Vorpal SDK.
- **`build` job**: Runs `vorpal build 'user'` (matrix strategy, currently single artifact) — validates that the user environment artifact builds successfully.

These are **build-time validation only**, not tests. They confirm that `cargo build` succeeds and that Vorpal artifact construction does not error. They do not validate runtime behavior, configuration correctness, or file content.

### 1.4 What the Build Validates Implicitly

Because the project is a Rust binary that declaratively constructs Vorpal artifacts, a successful `cargo build` provides:

- **Type checking**: Rust's type system validates that all artifact builder APIs are called correctly (e.g., `Artifact::new`, `step::shell`, `FileCreate::build`).
- **Dependency resolution**: `Cargo.lock` pins all transitive dependencies; build failure signals dependency breakage.
- **API contract compliance**: The `vorpal-sdk` and `vorpal-artifacts` crate APIs enforce correct usage at compile time.

This is a meaningful — but incomplete — form of validation for a declarative configuration project.

## 2. Test Pyramid Analysis

```
          /\
         /  \       E2E: None
        /----\
       /      \     Integration: None
      /--------\
     /          \   Unit: None
    /____________\
    Build validation   <-- Only this layer exists (CI build jobs)
```

The test pyramid is entirely absent. The project relies solely on compilation as validation.

## 3. What Could Be Tested

Given the project's nature as a declarative dotfile configuration system, potential test categories include:

### 3.1 Unit Tests (High Value)

- **`FileCreate` content generation**: Verify that generated shell scripts contain expected content, correct `chmod` modes, and proper variable interpolation.
- **`FileDownload` / `FileSource` path construction**: Validate that source paths and output paths are constructed correctly.
- **`get_output_path` utility**: Simple function (`src/lib.rs:11`) that formats a path string — trivially testable.
- **Configuration struct serialization**: `ClaudeCode`, `GhosttyConfig`, `BatConfig`, `K9sSkin`, `Opencode` all produce configuration content that could be snapshot-tested.

### 3.2 Integration Tests (Medium Value)

- **Artifact dependency graph**: Validate that `UserEnvironment::build` correctly wires all tool dependencies.
- **Vorpal SDK contract tests**: Ensure artifact construction calls produce valid Vorpal build graphs (requires Vorpal SDK test utilities, if available).

### 3.3 End-to-End Tests (Lower Value, Higher Cost)

- **Full `vorpal build` execution**: Already covered by CI, but not as a test harness — results are not asserted against.
- **Configuration file deployment verification**: Validate that built artifacts produce the expected file tree.

## 4. Gaps and Risks

### 4.1 Critical Gaps

1. **No regression safety net**: Any change to configuration content (e.g., modifying `claude_code.rs` or `k9s.rs`) has no automated check that the output is still correct. Only a broken build (compilation failure) would be caught.
2. **No content validation**: The project generates substantial configuration files (e.g., `opencode.rs` is 79KB of configuration). There is no snapshot testing or content assertion to catch unintended changes.
3. **No coverage tracking**: No tooling to measure what percentage of code paths are exercised.

### 4.2 Risk Assessment

| Risk | Severity | Likelihood | Notes |
|---|---|---|---|
| Silent configuration regression | Medium | Medium | A valid Rust change could produce incorrect config output |
| Broken artifact dependency wiring | Low | Low | Type system catches most issues; build catches the rest |
| Upstream SDK breaking change | Medium | Low | `Cargo.lock` pins versions; `renovate.json` manages updates |

### 4.3 Mitigating Factors

- The project is a **personal dotfiles configuration** tool, not a production service. The blast radius of bugs is limited to the operator's development environment.
- Rust's type system provides significant compile-time guarantees for the artifact builder pattern.
- CI build validation catches structural failures on every PR and push to `main`.
- The Vorpal SDK's builder pattern is designed to fail fast on misconfiguration.

## 5. Recommendations

Ordered by value-to-effort ratio for a project of this nature:

1. **Snapshot tests for configuration output** (highest value): Use `insta` or similar to snapshot the generated content from `FileCreate` builders. Catches silent regressions in config file content with minimal maintenance overhead.
2. **Unit tests for `get_output_path` and `FileCreate`/`FileDownload`/`FileSource`**: Simple, fast, and validates the core abstractions.
3. **`cargo clippy` in CI**: Not a test, but a low-effort addition to `.github/workflows/vorpal.yaml` that would catch common Rust anti-patterns. Currently absent from CI.
4. **`cargo fmt --check` in CI**: Enforces consistent formatting. Currently absent from CI.

Full integration or end-to-end test suites are likely overkill for a personal dotfiles project unless the project grows in scope or gains additional users.
