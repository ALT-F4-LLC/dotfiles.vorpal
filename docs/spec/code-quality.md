---
project: "dotfiles.vorpal"
maturity: "experimental"
last_updated: "2026-03-21"
updated_by: "@staff-engineer"
scope: "Code quality tooling, conventions, patterns, and standards in the dotfiles.vorpal project"
owner: "@staff-engineer"
dependencies:
  - architecture.md
---

# Code Quality

## Overview

dotfiles.vorpal is a Rust-based dotfiles configuration project (~4,100 lines across 9 source files) that uses the Vorpal SDK to declaratively build and deploy user environment artifacts — CLI tools, editor configs, terminal themes, and AI coding assistant settings. The project follows Rust 2021 edition conventions and relies on the Vorpal build system for compilation and artifact management rather than traditional Rust tooling (cargo) in CI.

## Language and Edition

- **Language:** Rust
- **Edition:** 2021 (specified in `Cargo.toml`)
- **Binary:** Single binary target `vorpal` at `src/vorpal.rs`
- **Package name:** `dotfiles` (crate name), binary name `vorpal`

## Formatting and Linting

### What Exists

- **No `rustfmt.toml` or `.rustfmt.toml`** — the project relies on default `rustfmt` formatting rules.
- **No `clippy.toml` or `.clippy.toml`** — no project-specific Clippy configuration.
- **No `.editorconfig`** — no cross-editor formatting enforcement.
- **No pre-commit hooks** — no automated formatting or linting gates before commit.
- **`cargo fmt` and `cargo clippy` are whitelisted** in the Claude Code permissions configuration (in `src/user.rs`), indicating these tools are expected to be used locally by developers and AI agents.

### What Does NOT Exist

- No CI-level formatting checks — the GitHub Actions workflow (`vorpal.yaml`) only runs `vorpal build`, with no `cargo fmt --check` or `cargo clippy` steps.
- No linting configuration files of any kind (no eslint, ruff, etc. — only Rust source exists).
- No automated code quality gates in the pipeline.

## Naming Conventions

The codebase follows standard Rust naming conventions consistently:

- **Structs:** PascalCase — `FileCreate`, `FileDownload`, `FileSource`, `UserEnvironment`, `BatConfig`, `GhosttyConfig`, `ClaudeCode`, `K9sSkin`, `Opencode`
- **Functions/methods:** snake_case — `get_output_path`, `with_theme`, `with_executable`, `format_yaml_list`
- **Variables:** snake_case — `bat_config_name`, `rust_toolchain_bin`, `claude_code_config_path`
- **Constants:** SCREAMING_SNAKE_CASE — `SYSTEMS`
- **Modules:** snake_case — `user`, `file`, `bat`, `claude_code`, `ghostty`, `k9s`, `opencode`
- **Enum variants:** PascalCase — `Aarch64Darwin`, `X8664Linux`, `Ask`, `Allow`, `Deny`

## Design Patterns

### Builder Pattern (Dominant)

The builder pattern is the primary design pattern throughout the codebase. Every configuration struct follows the same shape:

1. `new()` constructor with required fields (name, systems)
2. `with_*()` chainable methods for optional configuration
3. `build()` async method that produces the final artifact via `ConfigContext`

This pattern is used in:
- `FileCreate`, `FileDownload`, `FileSource` (in `src/file.rs`)
- `UserEnvironment` (in `src/user.rs`)
- `BatConfig` (in `src/user/bat.rs`)
- `GhosttyConfig` (in `src/user/ghostty.rs`)
- `ClaudeCode` (in `src/user/claude_code.rs`)
- `K9sSkin` (in `src/user/k9s.rs`)
- `Opencode` (in `src/user/opencode.rs`)

The pattern is also used by external dependencies from `vorpal_sdk` and `vorpal_artifacts` (e.g., `Protoc::new().build()`, `Bat::new().build()`).

### Serde Serialization for Config Generation

Several modules (`claude_code.rs`, `opencode.rs`) define Rust structs with `#[derive(Serialize, Deserialize)]` to generate JSON configuration files. This approach provides type-safe configuration generation with compile-time guarantees. Key serde patterns in use:

- `#[serde(rename_all = "camelCase")]` — for JSON camelCase output
- `#[serde(skip_serializing_if = "Option::is_none")]` — omit unset optional fields
- `#[serde(skip_serializing_if = "Vec::is_empty")]` — omit empty collections
- `#[serde(skip)]` — exclude metadata fields from serialization
- `#[serde(rename = "type")]` — rename reserved keyword fields
- `#[serde(untagged)]` — for union-type enums (e.g., `AutoUpdate`)
- `BTreeMap` over `HashMap` — for deterministic JSON key ordering

### Template-Based Config Generation

Some modules (`ghostty.rs`, `k9s.rs`, `file.rs`) use `indoc::formatdoc!` for generating non-JSON config files (Ghostty ini-style, K9s YAML, shell scripts). These produce config text via string interpolation rather than serialization.

## Error Handling

- **`anyhow::Result`** is used universally as the error type — no custom error types are defined anywhere.
- The `?` operator is used for all error propagation.
- One explicit error construction exists: `anyhow::anyhow!("Failed to serialize Claude Code settings: {}", e)` in `claude_code.rs:535`.
- No `unwrap()` or `expect()` calls exist in the source code (outside of the builder pattern's `unwrap_or_default()` for optional nested structs).
- No `panic!` calls exist.

## Code Organization

### Module Structure

```
src/
  lib.rs          — Public API: SYSTEMS constant, get_output_path(), re-exports user and file modules
  vorpal.rs       — Binary entrypoint: main(), wires dependencies and builds dev + user environments
  file.rs         — FileCreate, FileDownload, FileSource abstractions for artifact file operations
  user.rs         — UserEnvironment: orchestrates all tool + config artifacts into a user environment
  user/
    bat.rs          — BatConfig builder (38 lines)
    claude_code.rs  — ClaudeCode settings builder with full serde model (541 lines)
    ghostty.rs      — GhosttyConfig builder (73 lines)
    k9s.rs          — K9sSkin builder for YAML skin config (587 lines)
    opencode.rs     — Opencode settings builder with full serde model (2,207 lines)
```

### Size Distribution

- `opencode.rs` (2,207 lines) and `k9s.rs` (587 lines) are the largest files, primarily due to the large number of `with_*()` builder methods and struct fields needed to model their respective configuration schemas.
- `claude_code.rs` (541 lines) follows the same pattern.
- Core logic files (`vorpal.rs`, `lib.rs`, `file.rs`) are compact (48, 13, 129 lines respectively).

### Visibility

- All config builder structs and their `new()`, `with_*()`, `build()` methods are `pub`.
- Sub-modules under `user/` are declared as `mod` (private) in `user.rs`, with only `UserEnvironment` exported as `pub struct`.
- The `lib.rs` re-exports `pub mod file` and `pub mod user`.

## `#[allow(dead_code)]` Usage

Extensive use of `#[allow(dead_code)]` on builder methods in `claude_code.rs` and `opencode.rs`. These methods exist to provide a complete API surface for their respective configuration schemas, even though not all options are currently used by the `UserEnvironment` in `user.rs`. This is an intentional design choice — the builders model the full config schema so any option can be enabled without code changes to the builder.

## Dependency Management

### Crate Dependencies (Cargo.toml)

| Crate | Version | Purpose |
|---|---|---|
| `anyhow` | 1 | Error handling |
| `indoc` | 2 | Multi-line string formatting |
| `serde` | 1.0.228 (with `derive`) | Serialization/deserialization |
| `serde_json` | 1.0.148 | JSON output for config files |
| `tokio` | 1 (with `rt-multi-thread`) | Async runtime |
| `vorpal-artifacts` | git (main branch) | Pre-built artifact definitions (awscli2, bat, direnv, etc.) |
| `vorpal-sdk` | 0.1.0-alpha.0 | Core Vorpal SDK for artifact building |

### Automated Dependency Updates

Renovate is configured (`renovate.json`) with:
- **Automerge** for minor/patch updates on stable crates (version >= 1.0)
- **Manual review required** for major version updates
- **Grouped updates** for serde ecosystem (serde + serde_json)
- **Custom regex manager** tracking the `tokyonight.nvim` bat theme version from a raw GitHub URL in `src/user.rs`

## Non-Rust Artifacts

The project also contains non-Rust source artifacts that are built and deployed:

- **`agents/`** — 5 Markdown files defining Claude Code agent personas (project-manager, sdet, senior-engineer, staff-engineer, ux-designer)
- **`skills/`** — 4 skill directories for Claude Code (add-artifact, dev, specs, vote)
- **`src/user/statusline.sh`** — Bash script for Claude Code status line (5,251 bytes), included via `include_str!`

These are bundled as `FileSource` artifacts rather than compiled code. No linting or validation is applied to them.

## Testing

- **No test files exist** in the project — no `#[test]` functions, no `tests/` directory, no integration tests.
- **No test configuration** — no test-related CI steps.
- This is consistent with the project's nature as a declarative configuration project where the Vorpal build itself serves as the primary validation (if it builds, the configs are structurally valid).

## CI/CD Quality Gates

The GitHub Actions workflow (`vorpal.yaml`) has a two-stage pipeline:

1. **`build-dev`** — Runs `vorpal build 'dev'` on `macos-latest`, uploads `Vorpal.lock` as artifact
2. **`build`** — Runs `vorpal build 'user'` (matrix with single `user` artifact), depends on `build-dev`

There are no explicit quality gates beyond successful Vorpal builds. No `cargo test`, `cargo clippy`, `cargo fmt --check`, or any other static analysis steps exist in CI.

## Gaps and Observations

1. **No CI linting/formatting** — `cargo clippy` and `cargo fmt` are available locally but not enforced in CI, allowing style drift.
2. **No tests** — appropriate for the project's scope (declarative config), but the serde serialization logic in `claude_code.rs` and `opencode.rs` could benefit from snapshot tests to catch schema regressions.
3. **No `.editorconfig` or `rustfmt.toml`** — formatting relies entirely on rustfmt defaults, which is reasonable but could be made explicit.
4. **Extensive `#[allow(dead_code)]`** — while intentional, this suppresses a useful compiler signal. An alternative would be feature-gating unused builder methods or accepting the warnings as informational.
5. **`opencode.rs` size** — at 2,207 lines, this file is large. The builder pattern repetition is inherent to the approach, but the file could potentially be split into sub-modules by configuration section if it becomes unwieldy.
6. **Git dependency** — `vorpal-artifacts` is pinned to a git branch (`main`) rather than a versioned release, which means builds are not reproducible across time without the lockfile.
