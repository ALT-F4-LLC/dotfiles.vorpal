---
project: "dotfiles.vorpal"
maturity: "experimental"
last_updated: "2026-03-18"
updated_by: "@staff-engineer"
scope: "Coding standards, naming conventions, error handling patterns, design patterns, and style decisions for the dotfiles.vorpal project"
owner: "@staff-engineer"
dependencies:
  - architecture.md
---

# Code Quality

## Language and Edition

The project is written entirely in Rust using the **2021 edition** (specified in `Cargo.toml`). The
single binary target is `vorpal` (entry point at `src/vorpal.rs`), with a library crate (`src/lib.rs`)
exposing shared types and modules.

## Formatting and Linting

### What Exists

- **No `rustfmt.toml` or `.rustfmt.toml`**: The project relies on the default `rustfmt`
  configuration. All default Rust formatting rules apply without overrides.
- **No Clippy configuration**: There is no `clippy.toml`. Clippy is available via the Claude Code
  permission list (`cargo clippy:*` is an allowed command), indicating it is used during development
  but not enforced in CI.
- **No `.editorconfig`**: No cross-editor formatting standards are defined.
- **No `rust-toolchain.toml`**: The Rust toolchain version is managed dynamically by the Vorpal SDK
  (`rust_toolchain::version()`) rather than pinned in a file.

### What Does Not Exist

- **No CI linting step**: The GitHub Actions workflow (`vorpal.yaml`) runs `vorpal build 'dev'` and
  `vorpal build 'user'` only. There are no `cargo fmt --check`, `cargo clippy`, or `cargo test`
  steps in CI.
- **No pre-commit hooks**: No git hooks enforce formatting or linting before commits.
- **No lint annotations in code**: The codebase does not use `#![deny(clippy::all)]` or similar
  crate-level lint configuration, though individual methods use `#[allow(dead_code)]` where builder
  methods exist for future use.

### Gaps

The lack of CI-enforced linting means code quality relies entirely on developer discipline. Format
consistency is maintained informally based on `rustfmt` defaults. There is no automation preventing
drift from formatting standards.

## Naming Conventions

### Modules and Files

- **snake_case** for all module names and file names: `file.rs`, `user.rs`, `claude_code.rs`,
  `ghostty.rs`, `k9s.rs`, `opencode.rs`, `bat.rs`.
- Submodules are organized in a directory structure: `src/user/` contains per-tool configuration
  modules, re-exported from `src/user.rs` via `mod` declarations.

### Types

- **PascalCase** for all struct and enum names, following standard Rust convention: `FileCreate`,
  `FileDownload`, `FileSource`, `UserEnvironment`, `BatConfig`, `GhosttyConfig`, `ClaudeCode`,
  `K9sSkin`, `Opencode`.
- Type names are descriptive and self-documenting. Config generators are named `{Tool}Config` or
  match the tool name directly (e.g., `ClaudeCode`, `Opencode`).

### Functions and Methods

- **snake_case** for all functions and methods per Rust convention.
- Constructor: `new(name, systems)` pattern is universal across all builder structs.
- Builder methods: `with_{field}(self, value)` pattern consuming `self` and returning `Self`.
- Terminal method: `build(self, context)` consumes the builder and produces a `Result<String>`.
- Variable naming uses descriptive names with underscored components:
  `bat_theme_name`, `rust_toolchain_bin`, `claude_code_config_path`.

### Constants

- `SYSTEMS` is the only module-level constant, defined as an array with SCREAMING_SNAKE_CASE.

### Serde Rename Conventions

- `#[serde(rename_all = "camelCase")]` for JSON output (ClaudeCode config, Opencode config).
- `#[serde(rename_all = "lowercase")]` and `#[serde(rename_all = "UPPERCASE")]` for enum variants
  matching external tool expectations.
- `#[serde(rename = "type")]` used to work around Rust reserved keyword restrictions.

## Design Patterns

### Builder Pattern (Primary)

The builder pattern is the dominant design pattern across the entire codebase. Every configuration
generator and artifact definition follows this structure:

```
Struct::new(name, systems)       // Constructor with required fields
    .with_field(value)           // Optional field setters (consuming self)
    .build(context)              // Terminal async method producing Result<String>
    .await?
```

Key characteristics:
- Constructors take only required parameters (`name` and `systems` universally).
- Optional fields have sensible defaults set in `new()`.
- Builder methods take `mut self` (move semantics), not `&mut self`.
- The `build` method is always `async` and returns `Result<String>` (the artifact digest).
- The `build` method always requires a `&mut ConfigContext` parameter.

### Composition Over Inheritance

Complex artifacts are built by composing simpler ones. `UserEnvironment::build()` constructs 16+
tool artifacts, multiple configuration file artifacts, and composes them into a single environment
artifact. There is no trait-based inheritance hierarchy.

### String-Based Artifact References

Artifacts are referenced by their digest strings (opaque `String` values returned from `build()`).
Cross-artifact references use `get_output_path(namespace, &digest)` to compute filesystem paths.
This is a convention imposed by the Vorpal SDK.

### Template Generation via `formatdoc!`

Shell scripts and configuration files are generated using the `indoc::formatdoc!` macro for
multi-line string templates with embedded variables. This avoids external template files and keeps
configuration co-located with the builder logic. Used in `file.rs`, `ghostty.rs`, and `k9s.rs`.

### Serialization for Config Generation

For JSON-based configurations (ClaudeCode, Opencode), the pattern is:
1. Build a struct with serde derive attributes.
2. Call `serde_json::to_string_pretty()` in `build()`.
3. Pass the serialized string to `FileCreate` for artifact creation.

This ensures type-safe configuration generation with compile-time validation of structure.

### Embedded Resources via `include_str!`

Static file content is embedded at compile time using `include_str!` (e.g., `statusline.sh`).
This avoids runtime file reads and ensures the content is bundled into the binary.

## Error Handling

### `anyhow::Result` Throughout

Every fallible function returns `anyhow::Result<T>`. The project uses `anyhow` exclusively for
error handling -- there are no custom error types defined anywhere in the codebase.

### `?` Operator for Propagation

Errors are propagated using the `?` operator without additional context in most cases. The pattern
is fire-and-forget propagation:

```rust
let protoc = Protoc::new().build(context).await?;
```

### One Exception

`ClaudeCode::build()` adds context via `map_err`:

```rust
serde_json::to_string_pretty(&self)
    .map_err(|e| anyhow::anyhow!("Failed to serialize Claude Code settings: {}", e))?;
```

This is the only instance of explicit error context in the codebase. All other error propagation
relies on the underlying library error messages.

### Gap

Error messages in general lack call-site context. If an artifact build fails deep in the Vorpal SDK,
the resulting error may not indicate which artifact or configuration step caused the failure. Adding
`anyhow::Context` (`.context("building bat config")`) would improve debuggability.

## Module Organization

```
src/
  lib.rs           -- Public API: SYSTEMS constant, get_output_path(), mod declarations
  vorpal.rs        -- Binary entry point: main() builds dev + user environments
  file.rs          -- Generic file artifact builders: FileCreate, FileDownload, FileSource
  user.rs          -- UserEnvironment builder (composes all tools and configs)
  user/
    bat.rs         -- BatConfig builder
    claude_code.rs -- ClaudeCode settings builder (~540 lines)
    ghostty.rs     -- GhosttyConfig builder
    k9s.rs         -- K9sSkin builder (highly repetitive with_* methods)
    opencode.rs    -- Opencode settings builder (comprehensive API coverage)
    statusline.sh  -- Embedded shell script (included via include_str!)
```

The module hierarchy mirrors the artifact dependency graph: `vorpal.rs` depends on `lib.rs` and
`user.rs`, which depends on `file.rs` and the `user/` submodules.

## Code Size and Complexity

- `opencode.rs` and `k9s.rs` are the largest files due to exhaustive builder method coverage for
  their respective tool configurations. Each configurable field gets its own `with_*` method,
  leading to high line counts but low cyclomatic complexity.
- `claude_code.rs` follows the same pattern but is more moderate in size.
- `user.rs` is the composition hub, primarily consisting of sequential artifact builds and
  configuration wiring.
- The actual business logic files (`lib.rs`, `vorpal.rs`, `file.rs`) are compact (under 150
  lines each).

## Commit Message Convention

The project follows **Conventional Commits** format:

```
type(scope): description
```

Common types observed: `feat`, `fix`, `chore`. Scopes include: `user`, `cargo`, `vorpal`,
`agents`, `skills`, `deps`, `agents,skills`. Messages are lowercase and imperative or past tense
(inconsistent -- both "add" and "added" appear).

## Dependency Management

- **Renovate** manages dependency updates via `renovate.json`, with custom rules:
  - Serde ecosystem updates (`serde`, `serde_json`) are grouped together.
  - Minor/patch updates on stable crates (version >= 1.0) are auto-merged.
  - Major updates require manual review.
  - A custom regex manager tracks the tokyonight.nvim theme version from a raw GitHub URL in
    `src/user.rs`.
- `vorpal-artifacts` is pinned to a git branch (`main`), not a version. This is a stability risk
  as any breaking change on that branch will immediately affect this project.
- `vorpal-sdk` uses a semver pre-release version (`0.1.0-alpha.0`), indicating the SDK itself is
  not yet stable.

## `#[allow(dead_code)]` Usage

Many builder methods in `claude_code.rs` and `opencode.rs` are annotated with
`#[allow(dead_code)]`. These methods exist to provide a complete builder API for their respective
configuration structs, even though not all settings are currently used in the `user.rs` composition.
This is intentional API completeness rather than actual dead code -- the methods are available for
future configuration changes without requiring code additions.

Counts: approximately 41 instances in `claude_code.rs` and 165 in `opencode.rs`.

## Async Runtime

The project uses `tokio` with the `rt-multi-thread` feature. The `#[tokio::main]` attribute on
`main()` initializes the runtime. All `build()` methods are async, flowing through the Vorpal SDK's
async artifact pipeline.

## What Is Not Covered

- **No tests**: There are no test files, no `#[cfg(test)]` modules, and no integration tests
  directory. See `testing.md` for details.
- **No documentation comments**: No `///` doc comments exist on any public types or functions.
  The code relies on self-documenting naming conventions.
- **No unsafe code**: The codebase contains no `unsafe` blocks.
- **No macros**: Beyond standard derive macros and `formatdoc!`, the project defines no custom
  macros.
