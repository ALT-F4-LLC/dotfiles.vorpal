---
project: "dotfiles.vorpal"
maturity: "stable"
last_updated: "2026-03-18"
updated_by: "@staff-engineer"
scope: "Coding standards, naming conventions, error handling patterns, and design patterns in the dotfiles.vorpal codebase"
owner: "@staff-engineer"
---

# Code Quality

## Language and Edition

The project is written in Rust (2021 edition) as declared in `Cargo.toml`. The crate name is
`dotfiles` and it produces a single binary named `vorpal` via `src/vorpal.rs`. There is a
library root at `src/lib.rs` that re-exports the `file` and `user` modules alongside a shared
`SYSTEMS` constant and a `get_output_path` helper.

## Formatting and Linting

### What Exists

- **No `rustfmt.toml` or `.rustfmt.toml`** -- the project relies on default `rustfmt` settings.
  The CI workflow (`cargo fmt` is permitted in Claude Code settings) and the codebase follow
  standard Rust formatting conventions (4-space indentation, trailing commas in multi-line
  expressions, standard brace placement).
- **No `clippy.toml` or `.clippy.toml`** -- Clippy runs with default lint levels. The CI
  permissions allow `cargo clippy` execution. No crate-level `#[warn]` or `#[deny]` attributes
  are set.
- **No `.editorconfig`** -- editor configuration is not standardized via file.
- **`#[allow(dead_code)]`** is used extensively in `claude_code.rs` and `opencode.rs` on builder
  methods that exist for API completeness but are not yet called in the current configuration.
  This is the only lint suppression used in the codebase.

### What Does Not Exist

- No pre-commit hooks or Husky-style hook configuration.
- No `cargo deny` or `cargo audit` configuration for dependency auditing.
- No CI-enforced formatting or lint gates -- the GitHub Actions workflow only runs `vorpal build`
  commands, not `cargo fmt --check` or `cargo clippy -- -D warnings`.

## Naming Conventions

### Rust Conventions (Followed Consistently)

- **Structs**: PascalCase -- `UserEnvironment`, `FileCreate`, `FileDownload`, `FileSource`,
  `BatConfig`, `GhosttyConfig`, `K9sSkin`, `ClaudeCode`, `Opencode`.
- **Enums**: PascalCase with PascalCase variants -- `PermissionAction::Ask`, `LogLevel::Debug`,
  `AgentMode::Subagent`, `AutoUpdate::Boolean`.
- **Functions / Methods**: snake_case -- `get_output_path`, `with_theme`, `format_yaml_list`.
- **Constants**: SCREAMING_SNAKE_CASE -- `SYSTEMS`.
- **Modules**: snake_case -- `claude_code`, `opencode`, `bat`, `ghostty`, `k9s`.
- **Fields**: snake_case -- follows Rust conventions. Where JSON output requires camelCase,
  `#[serde(rename_all = "camelCase")]` or `#[serde(rename_all = "snake_case")]` is used on the
  struct rather than renaming individual fields.

### Artifact Naming Pattern

All Vorpal artifact names follow the pattern `{environment}-{tool}-{purpose}`:
- `user-bat-config`, `user-bat-theme`
- `user-claude-code`, `user-claude-agents`, `user-claude-skills`, `user-claude-statusline`
- `user-ghostty-config`, `user-k9s-skin`
- `user-markdown-vim`, `user-opencode`

This is constructed programmatically via `format!("{}-{suffix}", &self.name)` where `self.name`
is the environment name (e.g., `"user"`).

## Design Patterns

### Builder Pattern (Primary Pattern)

Every configuration struct and artifact type uses the **consuming builder pattern**:

1. `Type::new(name, systems)` -- constructor with required fields.
2. `.with_field(value)` -- chainable setter methods that take `mut self` and return `Self`.
3. `.build(context)` -- async terminal method that consumes `self`, produces the artifact,
   and returns `Result<String>` (the artifact digest).

This pattern is applied uniformly across all types:
- `FileCreate`, `FileDownload`, `FileSource` (in `src/file.rs`)
- `BatConfig`, `GhosttyConfig`, `K9sSkin`, `ClaudeCode`, `Opencode` (in `src/user/`)
- `UserEnvironment` (in `src/user.rs`)
- External SDK types also follow this pattern (`Protoc::new().build()`, `Bat::new().build()`)

The builder methods consume `self` (not `&mut self`), which means each struct instance is used
exactly once through a chain ending in `.build()`. This is idiomatic for one-shot configuration
objects.

### Optional Field Handling

Two strategies are used for optional nested configuration:

1. **`Option<T>` with `unwrap_or_default()`** -- used in `ClaudeCode` and `Opencode` for nested
   structs like `Permissions`, `Sandbox`, `Attribution`. Each `with_*` method unwraps the
   current value or creates a default, mutates it, and wraps it back. Example from
   `claude_code.rs`:
   ```
   let mut perms = self.permissions.unwrap_or_default();
   perms.allow.push(rule.to_string());
   self.permissions = Some(perms);
   ```

2. **Direct field defaults in `new()`** -- used in `GhosttyConfig` and `K9sSkin` where all
   fields have sensible defaults set in the constructor. Every field is always present.

### Serialization-Driven Configuration

Configuration structs for JSON output (`ClaudeCode`, `Opencode`) use `serde` derive macros
with `Serialize` and `Deserialize`. Key patterns:

- `#[serde(skip_serializing_if = "Option::is_none")]` on all optional fields to produce clean
  JSON without null values.
- `#[serde(skip_serializing_if = "Vec::is_empty", default)]` on collection fields.
- `#[serde(skip_serializing_if = "BTreeMap::is_empty", default)]` on map fields.
- `#[serde(rename_all = "camelCase")]` for JSON-targeted structs.
- `#[serde(rename_all = "snake_case")]` for TOML/config-targeted structs.
- `#[serde(rename = "type")]` for reserved keyword fields.
- `#[serde(skip)]` for metadata fields not part of the serialized output (e.g., `name`,
  `systems` in `ClaudeCode`).
- `#[serde(untagged)]` for union types like `AutoUpdate`.
- `BTreeMap` (not `HashMap`) for deterministic key ordering in serialized output.

### Template-Driven Configuration

Configuration structs for non-JSON formats (`GhosttyConfig`, `K9sSkin`, `BatConfig`) use
`indoc::formatdoc!` to generate the output from interpolated Rust format strings. The template
is a string literal with named placeholders matching struct fields.

## Module Organization

```
src/
  lib.rs          -- Crate root: SYSTEMS const, get_output_path(), re-exports file + user
  vorpal.rs       -- Binary entrypoint: main() builds dev + user environments
  file.rs         -- Generic file artifact types (FileCreate, FileDownload, FileSource)
  user.rs         -- UserEnvironment struct + build() orchestrator
  user/
    bat.rs         -- BatConfig builder
    claude_code.rs -- ClaudeCode settings builder (serde/JSON)
    ghostty.rs     -- GhosttyConfig builder (template/key-value)
    k9s.rs         -- K9sSkin builder (template/YAML)
    opencode.rs    -- Opencode settings builder (serde/JSON)
    statusline.sh  -- Bash script included via include_str!()
```

Sub-modules under `user/` are declared as `mod` (private) in `user.rs` and only their public
types are used internally. The `user` module itself is `pub mod` from `lib.rs`, exposing
`UserEnvironment` as the public API.

The `file` module provides three reusable artifact types consumed by the config builders.
This is the only shared abstraction layer -- config builders compose `FileCreate` for output
rather than implementing artifact creation themselves.

## Error Handling

### Pattern: `anyhow::Result` Throughout

Every fallible function returns `anyhow::Result<T>`. The `?` operator propagates errors up the
call chain to `main()`, which returns `Result<()>`.

- **No custom error types** -- `anyhow::Result` is used exclusively. This is appropriate for a
  CLI tool that reports errors to the user rather than matching on error variants
  programmatically.
- **No `unwrap()` or `expect()` calls** on fallible operations in the source code. All `Result`
  values use `?` propagation. The `unwrap_or_default()` calls are on `Option<T>` values where
  the default is intentional, not on `Result`.
- **One explicit `map_err`** exists in `claude_code.rs` and `opencode.rs` where
  `serde_json::to_string_pretty` errors are wrapped with context via
  `anyhow::anyhow!("Failed to serialize ... settings: {}", e)`.

### Shell Script Error Handling

Embedded bash scripts in `FileCreate` and `FileSource` use `set -euo pipefail`:
- `-e`: exit immediately on non-zero status
- `-u`: treat unset variables as errors
- `-o pipefail`: propagate pipe failures

The `statusline.sh` script also follows `set -euo pipefail` and uses defensive patterns like
`2>/dev/null` on `stat` calls and `|| echo ""` fallbacks for optional fields.

## Dependency Management

### Rust Dependencies

Six direct dependencies, all pinned to major version ranges in `Cargo.toml`:
- `anyhow = "1"` -- error handling
- `indoc = { version = "2" }` -- indented string literals
- `serde = { version = "1.0.228", features = ["derive"] }` -- serialization (with patch pin)
- `serde_json = { version = "1.0.148" }` -- JSON serialization (with patch pin)
- `tokio = { features = ["rt-multi-thread"], version = "1" }` -- async runtime
- `vorpal-sdk = { version = "0.1.0-alpha.0" }` -- Vorpal build SDK (pre-release pin)
- `vorpal-artifacts` -- git dependency from `main` branch

### Dependency Update Policy

Renovate is configured in `renovate.json` with:
- Automerge for minor and patch updates on stable crates (`matchCurrentVersion`: not `0.x`)
- Manual review required for major version updates
- Serde ecosystem updates grouped together (`serde` + `serde_json`)
- Custom regex manager tracking the `tokyonight.nvim` bat theme version from raw GitHub URLs

### External SDK Dependencies

The `vorpal-sdk` and `vorpal-artifacts` crates provide the artifact system types and pre-built
tool definitions. SDK types also follow the builder pattern, maintaining API consistency between
project code and SDK code.

## Code Style Observations

### Consistent Patterns

- **Import ordering**: standard library, then external crates, then internal modules. Uses
  grouped `use` statements with nested paths (e.g., `use vorpal_sdk::{artifact::{...}, context::...}`).
- **Section comments**: `user.rs` and `vorpal.rs` use `// Dependencies`, `// Configuration files`,
  `// User environment` comment headers to delineate logical sections within long functions.
  `opencode.rs` uses `// ============` separator comments between type groups.
- **String handling**: `&str` parameters with `.to_string()` conversion inside methods, rather
  than accepting `String` or `impl Into<String>`. This is consistent across all builder methods.
- **No doc comments**: No `///` doc comments exist on any public types or methods. The code is
  self-documenting through descriptive names and consistent patterns, but API documentation is
  absent.
- **No inline comments**: Comments are limited to section headers. No explanatory inline
  comments within method bodies.

### Areas of Verbosity

- `k9s.rs` (587 lines) and `opencode.rs` (2000+ lines) are large due to exhaustive builder
  methods for every configurable field. Each method follows an identical pattern but the
  repetition results in significant line count.
- The `#[allow(dead_code)]` annotations on builder methods in `claude_code.rs` and `opencode.rs`
  indicate the API surface is designed for completeness rather than minimal current usage.
  These types model the full configuration schema of their respective tools.

## Gaps and Missing Pieces

1. **No CI lint enforcement**: `cargo fmt --check` and `cargo clippy -- -D warnings` are not
   part of the GitHub Actions workflow. Code quality is enforced only by convention.
2. **No test suite**: Zero tests exist in the codebase. No `#[cfg(test)]` modules, no
   `tests/` directory, no integration tests. The project relies entirely on successful
   `vorpal build` execution for validation.
3. **No doc comments**: Public API surface has no `///` documentation. The README serves as
   the only documentation.
4. **No CLAUDE.md**: No project-level `CLAUDE.md` file exists for Claude Code project-specific
   instructions.
5. **No pre-release dependency strategy**: `vorpal-sdk` is pinned to `0.1.0-alpha.0` and
   `vorpal-artifacts` is pinned to a git branch, which means builds are not reproducible across
   different points in time for the artifacts dependency.
6. **No `rustfmt.toml` or `clippy.toml`**: Formatting and lint rules rely entirely on defaults
   with no project-level customization or enforcement.
