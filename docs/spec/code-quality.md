# Code Quality

Project-specific coding standards, naming conventions, error handling patterns, design patterns in
use, and style decisions observed in the `dotfiles` codebase.

---

## Language and Edition

- **Primary language:** Rust (2021 edition)
- **Secondary language:** Bash (shell scripts embedded via `include_str!` and generated via
  `formatdoc!`)
- **Configuration formats authored:** Markdown (agent prompts, skills), JSON (Renovate, Claude Code
  settings, Opencode settings), YAML (K9s skins, GitHub Actions workflows), plaintext (Ghostty
  config, bat config)
- **Rust toolchain version:** 1.89.0 (pinned in `Vorpal.lock`)

---

## Linter and Formatter Configuration

### What Exists

- **rustfmt:** The Rust toolchain (including `rustfmt` 1.89.0) is provisioned through Vorpal. No
  custom `rustfmt.toml` or `.rustfmt.toml` exists, so the default `rustfmt` settings apply.
- **Clippy:** The Rust toolchain (including `clippy` 1.89.0) is provisioned through Vorpal. No
  custom `clippy.toml` or `.clippy.toml` exists, so the default Clippy lints apply. The Claude Code
  permissions allowlist includes `Bash(cargo clippy:*)` and `Bash(cargo fmt:*)`, indicating these
  tools are expected to be run.
- **Renovate:** Dependency management is configured via `renovate.json` with `config:recommended`
  as the base. Serde ecosystem updates are grouped. Minor/patch updates for stable crates (version
  >= 1.0) are automerged. Major updates require manual review. A custom regex manager tracks the
  tokyonight.nvim theme version embedded in `src/user.rs`.

### What Does NOT Exist

- No `.editorconfig` file.
- No `rust-toolchain.toml` file (the toolchain is managed by Vorpal, not `rustup`).
- No custom rustfmt or Clippy configuration files -- all defaults are used.
- No pre-commit hooks or commit-time linting in the repository itself (though Claude Code
  permissions suggest `cargo clippy` and `cargo fmt` are used interactively).

---

## Naming Conventions

### Rust

- **Crate name:** `dotfiles` (snake_case, as required by Cargo).
- **Binary name:** `vorpal` (defined in `[[bin]]` section of `Cargo.toml`).
- **Modules:** snake_case, matching filenames (`file`, `user`, `user/bat`, `user/ghostty`, etc.).
- **Structs:** PascalCase, descriptive nouns representing the configuration or artifact they model:
  `FileCreate`, `FileDownload`, `FileSource`, `UserEnvironment`, `GhosttyConfig`, `BatConfig`,
  `K9sSkin`, `ClaudeCode`, `Opencode`.
- **Struct fields:** snake_case for Rust-side fields. `#[serde(rename_all = "camelCase")]` or
  `#[serde(rename_all = "snake_case")]` attributes are used to match the target config format's
  expected casing during serialization.
- **Builder methods:** `with_*` pattern consistently used across all config structs (e.g.,
  `with_theme`, `with_font_family`, `with_body_fg_color`, `with_permission_allow`). Methods
  consume `mut self` and return `Self` for fluent chaining.
- **Build methods:** Every config struct has an `async fn build(self, context: &mut ConfigContext)
  -> Result<String>` method that produces the final artifact. This is the universal terminal method
  for the builder pattern.
- **Constants:** SCREAMING_SNAKE_CASE (`SYSTEMS`).
- **Functions:** snake_case (`get_output_path`, `format_yaml_list`).
- **Artifact naming:** Runtime artifact names follow the pattern `{environment}-{tool}-{type}`,
  e.g., `user-bat-config`, `user-ghostty-config`, `user-k9s-skin`, `user-claude-code`.

### Serde Enum Conventions

- Enums use `#[serde(rename_all = "...")]` to match the target format:
  - `"UPPERCASE"` for `LogLevel`
  - `"lowercase"` for `ShareMode`, `AgentMode`, `PermissionAction`, `DiffStyle`, `McpType`
- `#[serde(untagged)]` is used for enums that can deserialize from multiple JSON shapes
  (`AutoUpdate`, `PermissionRule`, `PermissionConfig`).

---

## Design Patterns

### Builder Pattern (Dominant Pattern)

The entire codebase is organized around the builder pattern. Every configuration struct follows
this lifecycle:

1. **Construction:** `StructName::new(name, systems)` creates a struct with sensible defaults.
2. **Configuration:** Chained `.with_*()` methods customize the configuration. Each method
   consumes `mut self` and returns `Self`.
3. **Build:** `.build(context).await?` produces the artifact string (a digest/hash).

This pattern is used consistently in:
- `FileCreate`, `FileDownload`, `FileSource` (in `src/file.rs`)
- `BatConfig`, `GhosttyConfig`, `K9sSkin`, `ClaudeCode`, `Opencode` (in `src/user/`)
- `UserEnvironment` (in `src/user.rs`)
- External SDK types: `Protoc`, `RustToolchain`, `Awscli2`, `Bat`, `Direnv`, etc.

### Configuration-as-Code

The project treats all user environment configuration as Rust code. Configuration files (JSON,
YAML, plaintext) are not stored as static files -- they are generated programmatically by Rust
structs that serialize to the target format at build time. This applies to:
- Claude Code settings (JSON via `serde_json`)
- Opencode settings (JSON via `serde_json`)
- K9s skins (YAML via `formatdoc!` string templates)
- Ghostty config (plaintext via `formatdoc!`)
- Bat config (plaintext via string construction)

### Artifact System Integration

All outputs flow through the Vorpal artifact system:
- `Artifact::new(name, steps, systems).build(context)` registers build artifacts
- `step::shell(context, ...)` wraps shell scripts as build steps
- `ArtifactSource::new(name, path).build()` declares source dependencies
- The build graph is declarative and content-addressed (digests in `Vorpal.lock`)

### Module Organization

```
src/
  lib.rs          -- Public API: SYSTEMS constant, get_output_path(), re-exports modules
  vorpal.rs       -- Binary entry point (main), orchestrates build graph
  file.rs         -- Generic file artifact builders (FileCreate, FileDownload, FileSource)
  user.rs         -- UserEnvironment: assembles all user tools and configs
  user/
    bat.rs        -- BatConfig builder
    claude_code.rs -- ClaudeCode settings builder (JSON)
    ghostty.rs    -- GhosttyConfig builder
    k9s.rs        -- K9sSkin builder (YAML)
    opencode.rs   -- Opencode settings builder (JSON)
    statusline.sh -- Claude Code status line script (included via include_str!)
```

The `user.rs` module acts as the composition root: it instantiates all tool artifacts and config
builders, wires them together with symlinks and environment variables, and produces the final
`UserEnvironment` artifact.

---

## Error Handling

### Pattern: `anyhow::Result` Everywhere

- All fallible functions return `anyhow::Result<T>`.
- The `?` operator is used consistently for error propagation.
- The main function (`src/vorpal.rs`) returns `Result<()>`, allowing errors to propagate to the
  top level.
- `anyhow::anyhow!()` is used for custom error messages in serialization failures (e.g.,
  `"Failed to serialize Claude Code settings: {}"` in `claude_code.rs` and `opencode.rs`).

### `unwrap_or_default()` for Optional Builder State

- Builder methods that accumulate into optional nested structs use `unwrap_or_default()` to
  lazily initialize the nested struct on first use. This pattern appears extensively in
  `claude_code.rs` (for `Permissions`, `Sandbox`, `Attribution`) and `opencode.rs` (for
  `KeybindsConfig`, `TuiConfig`, `ServerConfig`, `WatcherConfig`, `AgentConfig`, etc.).
- This is safe because the structs derive `Default`.

### No `unwrap()` or `expect()` on Fallible Operations

- The codebase does not use `unwrap()` or `expect()` on `Result` types.
- `unwrap_or_default()` on `Option` types is the only `unwrap` variant used, and it is always
  safe (used on structs that implement `Default`).

---

## `#[allow(dead_code)]` Usage

The codebase makes extensive use of `#[allow(dead_code)]` on builder methods in `claude_code.rs`
(~38 instances) and `opencode.rs` (~170+ instances). These are builder methods for configuration
options that are defined in the struct but not currently used in the composition in `user.rs`. This
is an intentional design choice: the builders expose the full API surface of the target
configuration format, even when only a subset is used in the current dotfiles setup. This allows
the user to enable new options without modifying the builder struct itself.

---

## Code Style Observations

### Import Organization

Imports follow this order (consistent across all files):
1. `crate::` imports (local modules)
2. `anyhow::Result`
3. Third-party crate imports (`indoc`, `serde`, `serde_json`)
4. Standard library imports (`std::collections::BTreeMap`)
5. `vorpal_sdk` and `vorpal_artifacts` imports

Within each group, imports are alphabetically sorted (as enforced by default `rustfmt`).

### String Handling

- `&str` parameters in constructors and builder methods, converted to `String` via `.to_string()`
  for storage.
- `format!()` and `formatdoc!()` (from the `indoc` crate) for multi-line string construction.
- `include_str!()` for embedding static files at compile time (`statusline.sh`).

### Collection Types

- `Vec<ArtifactSystem>` for system platform lists (passed by value, cloned when needed).
- `BTreeMap<String, T>` (not `HashMap`) for ordered maps -- used in `ClaudeCode` and `Opencode`
  for `env`, `hooks`, `enabled_plugins`, and agent config maps. This ensures deterministic
  serialization order.
- `Vec<String>` for permission lists, server lists, and other ordered collections.

### Serde Annotations

Consistent use of serde attributes across all serializable structs:
- `#[serde(skip_serializing_if = "Option::is_none")]` on all `Option<T>` fields
- `#[serde(skip_serializing_if = "Vec::is_empty", default)]` on all `Vec<T>` fields
- `#[serde(skip_serializing_if = "BTreeMap::is_empty", default)]` on all `BTreeMap<K,V>` fields
- `#[serde(skip)]` on metadata fields not intended for serialization (`name`, `systems`)
- `#[serde(rename = "type")]` for fields named `type` (a Rust keyword)
- `#[derive(Debug, Clone, Serialize, Deserialize)]` on all serializable types
- `#[derive(Default)]` on structs used with `unwrap_or_default()`

### Comment Style

- Section-separator comments using `// ============...` blocks (seen in `opencode.rs`)
- Inline section comments like `// Dependencies`, `// Configuration files`, `// User environment`
  to delineate logical sections in long functions (seen in `user.rs` and `vorpal.rs`)
- No doc comments (`///`) are used anywhere in the codebase
- No module-level documentation (`//!`) exists

---

## Shell Script Standards

The single shell script (`statusline.sh`) follows these conventions:
- `#!/bin/bash` shebang
- `set -euo pipefail` for strict error handling
- Descriptive section comments with `# -- Section Name --`
- SCREAMING_SNAKE_CASE for variables
- Functions use `local` for variable scoping
- ANSI color codes defined as named variables
- `jq` for JSON parsing with `// fallback` default values
- Caching (file-based with TTL) for expensive operations (git status)

---

## Non-Source File Conventions

### Agent Prompt Files (`agents/*.md`)

- Plain Markdown files defining agent personas and behavior
- Structured with clear sections: responsibilities, rules, anti-patterns
- Tables used for classification (review dimensions, triage matrices)
- Code blocks for CLI references and templates
- Files range from ~7KB to ~28KB

### Skill Files (`skills/*/SKILL.md`)

- YAML front matter with `name` and `description` fields
- Markdown body with structured workflow steps
- Agent spawning templates as code blocks
- Rules sections with numbered constraints

### GitHub Actions Workflow (`.github/workflows/vorpal.yaml`)

- Single workflow file for CI
- Two-job pipeline: `build-dev` (builds the dev environment) then `build` (builds user artifacts)
- Matrix strategy for artifact builds
- Uses Vorpal's own GitHub Action (`ALT-F4-LLC/setup-vorpal-action@main`)
- S3-backed registry for artifact storage

---

## Gaps and Missing Pieces

- **No doc comments:** No `///` or `//!` documentation exists on any public types or functions.
  The code is self-documenting through naming but lacks API-level documentation.
- **No custom linter configuration:** All Clippy and rustfmt settings are defaults. There are no
  project-specific lint rules or format preferences codified.
- **No `.editorconfig`:** No editor-agnostic formatting configuration exists.
- **No contribution guidelines:** No `CONTRIBUTING.md` or code style guide for human contributors.
- **No pre-commit hooks:** No automated formatting or linting enforcement before commits.
- **Large files:** `opencode.rs` (2,207 lines) and `k9s.rs` (587 lines) are dominated by
  repetitive builder methods. This is a consequence of the comprehensive builder API approach
  but makes these files difficult to review at a glance.
- **No tests:** The `src/` directory contains no test modules (`#[cfg(test)]`), test files, or
  test infrastructure. The project relies entirely on Vorpal's build system for validation
  (if the artifact builds and the config serializes, it works).
