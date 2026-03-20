---
project: "main"
maturity: "experimental"
last_updated: "2026-03-20"
updated_by: "@staff-engineer"
scope: "Code quality conventions, patterns, tooling, and style standards for the dotfiles.vorpal Rust codebase"
owner: "@staff-engineer"
dependencies:
  - architecture.md
---

# Code Quality

## Language & Edition

- **Language:** Rust (2021 edition)
- **Async runtime:** Tokio with `rt-multi-thread` feature
- **Error handling:** `anyhow::Result` throughout — no custom error types

## Formatting & Linting

### Current State

- **No `rustfmt.toml`** — the project relies on default `rustfmt` settings (Rust 2021 edition defaults)
- **No `clippy.toml`** — no custom Clippy configuration
- **No `.editorconfig`** — no editor-level formatting enforcement
- **No pre-commit hooks** — no automated formatting or lint checks before commit

### Observed Formatting Conventions

- 4-space indentation (Rust default)
- Imports grouped by crate with `use` blocks at the top of each file
- Multi-line import blocks use nested `{}` grouping (e.g., `use vorpal_sdk::{artifact::{...}, context::...}`)
- Builder method chains use one method call per line with leading `.`
- Comment sections use `// Section Name` with blank lines as separators (e.g., `// Dependencies`, `// Configuration files`, `// User environment`)

### CI Lint Checks

- **None.** The CI pipeline (`vorpal.yaml`) only runs `vorpal build 'dev'` and `vorpal build 'user'`. There are no `cargo clippy`, `cargo fmt --check`, or `cargo test` steps in CI.

## Naming Conventions

### Structs

- PascalCase with descriptive domain names: `UserEnvironment`, `FileCreate`, `FileDownload`, `FileSource`, `BatConfig`, `GhosttyConfig`, `ClaudeCode`, `K9sSkin`, `Opencode`
- Configuration structs represent a tool's settings and are named after the tool itself (e.g., `ClaudeCode`, `GhosttyConfig`)

### Functions & Methods

- snake_case per Rust convention
- Constructor: `new(name, systems)` pattern — takes a name string and a systems vector
- Builder methods: `with_<property>(mut self, value) -> Self` pattern — consume and return self
- Async build: `build(self, context: &mut ConfigContext) -> Result<String>` — consumes self, returns artifact digest

### Variables

- snake_case with descriptive names
- Name-derived variables follow `<tool>_<purpose>_name` / `<tool>_<purpose>_path` pattern (e.g., `bat_config_name`, `bat_config_path`)

### Modules

- Flat module structure under `src/user/` — one file per tool configuration
- Private submodules (`mod bat; mod claude_code;`) with public struct re-exports via `use`

## Design Patterns

### Builder Pattern

The dominant pattern across the codebase. Every configuration struct follows the same shape:

1. `new(name, systems)` — constructor with required fields and sensible defaults
2. `with_*()` — chainable builder methods that consume and return `Self`
3. `build(self, context) -> Result<String>` — async terminal method that produces a Vorpal artifact

This pattern is used by: `FileCreate`, `FileDownload`, `FileSource`, `BatConfig`, `GhosttyConfig`, `ClaudeCode`, `K9sSkin`, `Opencode`, `UserEnvironment`.

### Artifact Composition

Configuration structs delegate to `FileCreate` for file-based artifacts. The flow is:
1. Build configuration content as a string (plain text, JSON, or YAML)
2. Pass content to `FileCreate::new().build(context)` to create a Vorpal artifact
3. Return the artifact digest string

### Serialization Strategy

- `ClaudeCode` and `Opencode` use `serde` derive macros with `#[serde(rename_all = "camelCase")]` for JSON output
- `GhosttyConfig` and `K9sSkin` use `indoc::formatdoc!` macro for template-based config generation (not serde)
- `BatConfig` uses manual string building

## Error Handling

- **Uniform `anyhow::Result`** — every async function returns `anyhow::Result<T>`
- **`?` operator** used extensively for error propagation — no manual `match` on Results
- **No custom error types** — the codebase relies entirely on anyhow for error context
- **One explicit `.map_err()`** — in `ClaudeCode::build()` for serde serialization errors
- **No `unwrap()` or `expect()` calls** in production code paths

## Dead Code Management

- The `ClaudeCode` struct has extensive `#[allow(dead_code)]` annotations on builder methods that are defined but not yet used in the current configuration. This is intentional — the struct is designed as a comprehensive API surface for all Claude Code settings, with methods available for future use.

## Module Organization

```
src/
  lib.rs          -- Public constants (SYSTEMS), public utility (get_output_path), module declarations
  vorpal.rs       -- Binary entrypoint, builds dev and user environments
  file.rs         -- Generic file artifact builders (FileCreate, FileDownload, FileSource)
  user.rs         -- UserEnvironment struct, orchestrates all tool artifacts and symlinks
  user/
    bat.rs         -- BatConfig builder
    claude_code.rs -- ClaudeCode settings builder (largest file, ~540 lines)
    ghostty.rs     -- GhosttyConfig builder
    k9s.rs         -- K9sSkin builder (~590 lines)
    opencode.rs    -- Opencode settings builder (largest module)
```

- `lib.rs` is minimal — just constants and module declarations
- `vorpal.rs` is the entrypoint and orchestrates the top-level build
- `user.rs` is the integration point that wires all tools and configs together
- Tool-specific modules are private to `user` and follow a consistent structure

## Dependency Management

- **Renovate** manages dependency updates via `renovate.json`
- Serde ecosystem updates are grouped together
- Minor and patch updates for stable crates (version >= 1.0) are auto-merged
- Major updates require manual review
- Custom regex manager tracks the `tokyonight.nvim` bat theme version from raw GitHub URLs in `src/user.rs`

### External Dependencies

| Crate | Purpose | Version Strategy |
|-------|---------|-----------------|
| `anyhow` | Error handling | Major pin (`"1"`) |
| `indoc` | Template strings | Major pin (`"2"`) |
| `serde` + `serde_json` | Serialization | Exact minor pin with features |
| `tokio` | Async runtime | Major pin with `rt-multi-thread` |
| `vorpal-sdk` | Vorpal build system SDK | Alpha (`0.1.0-alpha.0`) |
| `vorpal-artifacts` | Pre-built artifact types | Git dependency (branch: main) |

## Gaps & Observations

1. **No automated formatting enforcement** — no `rustfmt.toml`, no CI format check. Formatting relies on developer discipline.
2. **No Clippy in CI** — no static analysis step in the build pipeline.
3. **No tests** — no `#[cfg(test)]` modules, no test files, no `cargo test` in CI. The project has zero test coverage.
4. **No documentation comments** — no `///` doc comments on public structs or methods.
5. **Large builder files** — `claude_code.rs`, `k9s.rs`, and `opencode.rs` are very large (400-600+ lines) due to exhaustive builder method definitions. This is a consequence of the builder pattern applied to configuration schemas with many fields.
6. **Git dependency** — `vorpal-artifacts` is pinned to a git branch (`main`) rather than a published crate version, which can cause reproducibility issues.
7. **Inconsistent config generation** — some modules use serde serialization (ClaudeCode, Opencode) while others use template strings (GhosttyConfig, K9sSkin). This is pragmatic (different output formats) but not unified.
