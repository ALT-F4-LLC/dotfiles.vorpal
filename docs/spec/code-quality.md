---
project: "dotfiles.vorpal"
maturity: "experimental"
last_updated: "2026-03-18"
updated_by: "@staff-engineer"
scope: "Coding standards, naming conventions, error handling patterns, and design patterns in use"
owner: "@staff-engineer"
dependencies:
  - architecture.md
---

# Code Quality

## Language and Toolchain

- **Language**: Rust (edition 2021)
- **Async runtime**: Tokio with `rt-multi-thread` feature
- **Error handling crate**: `anyhow` (application-level error handling, no custom error types)
- **Serialization**: `serde` + `serde_json` for JSON config generation
- **String templating**: `indoc` (`formatdoc!` macro) for multi-line string literals

There are no linter configurations (no `clippy.toml`, `.rustfmt.toml`, or `.editorconfig`) checked into the repository. The project relies on Rust's default formatting and linting rules. The CI workflow does not run `cargo fmt --check` or `cargo clippy` -- it only runs `vorpal build`.

## Naming Conventions

### Files and Modules

- **snake_case** for all Rust source files: `claude_code.rs`, `statusline.sh`
- Module structure follows Rust conventions: `src/user.rs` as the parent module with `src/user/` directory containing submodules
- Submodules declared as `mod bat;` / `mod claude_code;` in the parent module with `pub use` of key types at the parent level
- Config builder modules are named after the tool they configure (e.g., `bat.rs` for `BatConfig`, `ghostty.rs` for `GhosttyConfig`)

### Types and Structs

- **PascalCase** for all structs and enums: `UserEnvironment`, `BatConfig`, `GhosttyConfig`, `K9sSkin`, `ClaudeCode`, `FileCreate`, `FileDownload`, `FileSource`
- Structs represent either configuration builders (e.g., `BatConfig`, `ClaudeCode`) or file-operation abstractions (e.g., `FileCreate`, `FileDownload`)
- Enum variants use PascalCase: `PermissionAction::Ask`, `AutoUpdate::Boolean`, `McpType::Local`

### Functions and Methods

- **snake_case** for all functions and methods
- Constructor: `new(name, systems)` pattern consistently across all builder structs
- Builder methods: `with_<field_name>` pattern (e.g., `with_theme`, `with_font_size`, `with_sandbox_enabled`)
- Terminal method: `build(context)` -- every builder has an async `build` that takes `&mut ConfigContext` and returns `Result<String>`
- Module-level utility functions: `get_output_path`, `format_yaml_list`

### Variables

- **snake_case** for all local variables
- Artifact variables named after the tool: `let bat = Bat::new().build(context).await?;`
- Config name variables use the pattern `let <tool>_config_name = format!("{}-<tool>-config", &self.name);`
- Path variables use the pattern `let <tool>_config_path = format!("{}/{name}", get_output_path(...))`

## Design Patterns

### Builder Pattern (Dominant Pattern)

Every configuration struct follows the same builder pattern:

1. `new(name, systems)` constructor with sensible defaults
2. Chain of `with_*` methods that take `mut self` and return `Self` (consuming builder)
3. Async `build(self, context: &mut ConfigContext) -> Result<String>` that produces the artifact

This pattern is used consistently across all files: `BatConfig`, `GhosttyConfig`, `K9sSkin`, `ClaudeCode`, `Opencode`, `FileCreate`, `FileDownload`, `FileSource`, and `UserEnvironment`.

The builder pattern is _consuming_ (takes `mut self`, not `&mut self`), which means builders cannot be reused after calling a method. This is idiomatic for one-shot configuration objects.

### Delegation to FileCreate

All configuration builders delegate their final output to `FileCreate::build()`. The builder's `build` method serializes the config to a string (via `formatdoc!`, `serde_json::to_string_pretty`, or manual string construction), then passes it to `FileCreate` which handles the Vorpal artifact creation. This creates a clean separation between config generation and artifact production.

### Serde-Based Config Generation (Newer Pattern)

`ClaudeCode` and `Opencode` use serde `Serialize`/`Deserialize` derives with `#[serde(rename_all = "camelCase")]` and `#[serde(skip_serializing_if = "...")]` to generate JSON config files. This is a more structured approach than the `formatdoc!` template approach used by `GhosttyConfig` and `K9sSkin`.

### Template-Based Config Generation (Older Pattern)

`GhosttyConfig` and `K9sSkin` use `indoc::formatdoc!` to generate config files as interpolated string templates. This is simpler but less type-safe than the serde approach. `BatConfig` uses manual `String::push_str`.

### Two-Phase Build in `user.rs`

The `UserEnvironment::build` method follows a consistent two-phase pattern:
1. **Dependencies phase**: Build all tool artifacts and config artifacts, collecting their digest strings
2. **Assembly phase**: Combine all artifacts, environment variables, and symlinks into a `UserEnvironment` artifact

## Error Handling

- **`anyhow::Result`** is used everywhere -- there are no custom error types in the project
- The `?` operator propagates errors up the call chain
- One explicit error construction exists: `anyhow::anyhow!("Failed to serialize Claude Code settings: {}", e)` in `claude_code.rs`
- No `unwrap()` or `expect()` calls in application code (outside of defaults in builder constructors)
- No `panic!` calls
- No error recovery or retry logic -- errors propagate to `main()` and terminate the process

## Module Organization

```
src/
  lib.rs          -- Public constants (SYSTEMS), utility function (get_output_path), module declarations
  vorpal.rs       -- Binary entry point (main), orchestrates dev + user environment builds
  file.rs         -- Generic file artifact builders (FileCreate, FileDownload, FileSource)
  user.rs         -- UserEnvironment struct and build orchestration
  user/
    bat.rs        -- BatConfig builder
    claude_code.rs -- ClaudeCode settings builder (JSON via serde)
    ghostty.rs    -- GhosttyConfig builder (key-value template)
    k9s.rs        -- K9sSkin builder (YAML template)
    opencode.rs   -- Opencode settings builder (JSON via serde)
    statusline.sh -- Bash script included via include_str!
```

The `lib.rs` exports `file` and `user` as public modules. The binary (`vorpal.rs`) imports from the library crate. Submodules under `user/` are private to the `user` module -- only `UserEnvironment` is publicly exported.

## Code Style Observations

### Consistency Strengths

- All builder structs follow an identical API shape (`new` / `with_*` / `build`)
- All `build` methods are async and return `Result<String>`
- Constructor parameters are consistently `(name: &str, systems: Vec<ArtifactSystem>)`
- The `name` field is always stored as an owned `String` via `.to_string()`

### Inconsistencies and Gaps

- **`#[allow(dead_code)]` proliferation**: The `ClaudeCode` builder has `#[allow(dead_code)]` on nearly every method. This suggests the API surface was designed speculatively -- many methods exist but are not yet called. The same pattern is not present in other builders.
- **Mixed config output strategies**: Some builders use serde serialization (`ClaudeCode`, `Opencode`) while others use `formatdoc!` templates (`GhosttyConfig`, `K9sSkin`) and one uses manual string building (`BatConfig`). There is no documented rationale for when to use which approach.
- **K9sSkin struct size**: The `K9sSkin` struct has 48+ fields with individual `with_*` methods for each. This produces a very large file (~580 lines). No intermediate grouping structs are used (e.g., a `FrameColors` substruct).
- **No documentation comments**: There are zero `///` doc comments or `//!` module-level docs anywhere in the source. Inline comments are sparse and limited to section headers (e.g., `// Dependencies`, `// Configuration files`).
- **No clippy or fmt enforcement in CI**: The GitHub Actions workflow runs `vorpal build` only -- there is no `cargo clippy` or `cargo fmt --check` step.

## Formatting

- No `.rustfmt.toml` or `rustfmt.toml` configuration file exists
- Code appears to follow default `rustfmt` formatting (4-space indentation, standard line lengths)
- Import grouping follows Rust convention: external crates first, then `crate::` imports, separated by blank lines

## Dependencies

- The project has 6 direct dependencies (see `Cargo.toml`)
- `vorpal-sdk` is pinned to `0.1.0-alpha.0` (crates.io)
- `vorpal-artifacts` tracks `main` branch via git dependency (no version pin)
- Renovate manages dependency updates with auto-merge for stable minor/patch updates

## Testing

There are no tests in this project. No `#[test]` functions, no `#[cfg(test)]` modules, no `tests/` directory. See `testing.md` for details.
