---
project: "dotfiles.vorpal"
maturity: "experimental"
last_updated: "2026-03-18"
updated_by: "@staff-engineer"
scope: "System architecture, component relationships, design patterns, and key architectural decisions"
owner: "@staff-engineer"
dependencies:
  - operations.md
  - security.md
---

# Architecture

## Overview

dotfiles.vorpal is a declarative dotfiles manager built on the [Vorpal](https://github.com/ALT-F4-LLC/vorpal) build system. Rather than using shell scripts or symlink managers, the entire development environment -- CLI tools, configuration files, themes, and symlinks -- is defined as a Rust program that produces reproducible, content-addressed artifacts through Vorpal's build pipeline.

The project also deploys a five-agent Claude Code development team configuration (agent personas, skills, and orchestration workflows) alongside the dotfiles.

## System Architecture

### High-Level Component Diagram

```
+-----------------------------------------------------------+
|                      vorpal.rs (Entry Point)               |
|  main() -> get_context() -> build dev + user artifacts     |
+-------------------+-------------------+-------------------+
                    |                   |
        +-----------v----+    +---------v-----------+
        | DevelopmentEnv |    | UserEnvironment     |
        | ("dev")        |    | ("user")            |
        +----------------+    +---------------------+
        | - Protoc       |    | - 16 CLI tools      |
        | - RustToolchain|    | - 6 config generators|
        +----------------+    | - agent/skill files  |
                              | - symlink mappings   |
                              +----------+----------+
                                         |
                    +--------------------+--------------------+
                    |                    |                    |
             +------v------+    +-------v------+    +-------v------+
             | file.rs     |    | user/*.rs    |    | vorpal-      |
             | FileCreate  |    | Config       |    | artifacts    |
             | FileDownload|    | Generators   |    | (external)   |
             | FileSource  |    +--------------+    +--------------+
             +-------------+
```

### Runtime Flow

1. **`vorpal.rs::main()`** obtains a `ConfigContext` from `vorpal_sdk::context::get_context()`.
2. It builds the **`dev`** artifact: a `DevelopmentEnvironment` containing Protoc and the Rust toolchain, used to compile the project itself.
3. It builds the **`user`** artifact via `UserEnvironment::build()`, which:
   - Instantiates 16 CLI tool artifacts from `vorpal-artifacts` and `vorpal-sdk` crates.
   - Generates configuration files (bat, Claude Code, Ghostty, K9s, Neovim, OpenCode) using builder-pattern structs.
   - Bundles agent definitions and skill definitions from the `agents/` and `skills/` directories as `FileSource` artifacts.
   - Declares environment variables (`EDITOR`, `GOPATH`, `PATH`).
   - Declares symlink mappings from Vorpal store paths to home directory locations.
4. **`context.run()`** executes the Vorpal build pipeline, which content-addresses each artifact, caches results, and creates the declared symlinks.

### Artifact Store

All built artifacts are stored in `/var/lib/vorpal/store/artifact/output/{namespace}/{digest}`. The `get_output_path()` function in `lib.rs` constructs these paths using a `"library"` namespace for configuration artifacts. Digests are content-addressed hashes, making builds reproducible and cacheable.

## Component Breakdown

### 1. Entry Point (`src/vorpal.rs`)

Single binary target named `vorpal`. Async entry point using `tokio::main`. Orchestrates both the `dev` and `user` artifact builds sequentially. The `dev` artifact must exist before the project can be compiled (it provides the Rust toolchain), but at runtime both are built in a single invocation.

### 2. Library Root (`src/lib.rs`)

Exports two modules (`file`, `user`), defines the supported platform list (`SYSTEMS`), and provides the `get_output_path()` helper. The `SYSTEMS` constant declares support for four platforms (aarch64-darwin, aarch64-linux, x86_64-darwin, x86_64-linux), though the primary target is aarch64-darwin (Apple Silicon macOS).

### 3. File Abstraction Layer (`src/file.rs`)

Three structs handle all file artifact creation:

| Struct | Purpose | Mechanism |
|---|---|---|
| **`FileCreate`** | Generate a file from inline string content | Writes content via a shell step (`cat << 'EOF'`), optionally sets executable bit |
| **`FileDownload`** | Fetch a file from a URL | Declares an `ArtifactSource` with the URL, copies to output |
| **`FileSource`** | Bundle local directory contents as an artifact | Declares an `ArtifactSource` pointing at local paths with include filters |

All three use the Vorpal SDK's `Artifact` and `step::shell` primitives to produce content-addressed outputs. They follow a consistent builder pattern: `new()` -> optional `with_*()` methods -> `build(context)`.

### 4. User Environment (`src/user.rs`)

The `UserEnvironment` struct is the orchestrator for the full user environment. Its `build()` method:

- **CLI tool artifacts** (16 total): Each tool is instantiated from either `vorpal_artifacts` (community/pre-built: awscli2, bat, direnv, doppler, fd, jj, jq, k9s, kubectl, lazygit, nnn, ripgrep, tmux) or `vorpal_sdk::artifact` (SDK-provided: gh, git, gopls). All follow the `Tool::new().build(context)` pattern.
- **Configuration artifacts** (6 generators + 1 download + 1 vim setting): Each config module under `src/user/` produces a file artifact.
- **Agent and skill bundles**: The `agents/` and `skills/` directories are packaged as `FileSource` artifacts.
- **Symlink declarations**: 11 symlink mappings connecting Vorpal store paths to home directory locations (`~/.config/bat/config`, `~/.claude/settings.json`, etc.).
- **Environment variables**: Sets `EDITOR`, `GOPATH`, and an extended `PATH`.

### 5. Configuration Generators (`src/user/*.rs`)

Each generator follows the same pattern: a struct with builder methods that accumulate settings, and a `build()` method that renders the configuration to a string and wraps it in a `FileCreate` artifact.

| Module | Output Format | Key Characteristics |
|---|---|---|
| `bat.rs` | Plain text | Simple `--theme=<name>` config |
| `claude_code.rs` | JSON | Full Claude Code `settings.json` with permissions, sandbox, env vars, plugins, MCP servers, hooks, status line, attribution |
| `ghostty.rs` | Key-value | Ghostty terminal emulator config (font, opacity, theme) |
| `k9s.rs` | YAML | K9s Kubernetes UI skin with full Tokyo Night color palette |
| `opencode.rs` | JSON | OpenCode AI tool config with permissions, keybinds, LSP, agents, themes |
| `statusline.sh` | Bash script | Included via `include_str!()`, provides Claude Code status bar |

The `claude_code.rs` module is the most complex, modeling the full Claude Code settings schema with typed structs for permissions, sandbox, attribution, MCP servers, hooks, and status line configuration.

### 6. Agent Definitions (`agents/`)

Five markdown files define Claude Code agent personas deployed to `~/.claude/agents/`:

- `staff-engineer.md` -- Architecture, TDDs, code review
- `senior-engineer.md` -- Implementation, code quality, debugging
- `project-manager.md` -- Issue planning, task breakdown, dependency management
- `qa-engineer.md` -- Testing, verification, acceptance criteria
- `ux-designer.md` -- User experience design specs

### 7. Skill Definitions (`skills/`)

Two skills orchestrate agent collaboration:

- `dev-team/SKILL.md` -- Coordinates all five agents for planning and executing development work
- `dev-init/SKILL.md` -- Bootstraps `docs/spec/` project specifications for new repositories

## Design Patterns

### Builder Pattern (Pervasive)

Every artifact and configuration struct uses the builder pattern: `Struct::new(name, systems)` followed by `with_*()` chaining and a terminal `build(context)` call. This provides a consistent, composable API across all components.

### Content-Addressed Artifacts

Vorpal content-addresses all build outputs by digest. The `get_output_path("library", &digest)` pattern is used throughout to construct store paths. This enables:
- **Reproducibility**: Same inputs always produce the same output path.
- **Caching**: Unchanged artifacts are never rebuilt.
- **Atomicity**: Symlinks point to immutable store paths.

### Configuration-as-Code

All tool configurations are defined programmatically in Rust rather than as static dotfiles. This enables:
- Type-checked configuration (compile-time errors for invalid settings).
- Composability (e.g., reusing color palette variables across K9s, Ghostty).
- Version-controlled, reviewable changes to tool settings.

### Separation of Concerns

The codebase cleanly separates:
- **File primitives** (`file.rs`) from **domain logic** (`user.rs`, `user/*.rs`).
- **Tool artifact acquisition** (delegated to `vorpal-artifacts`/`vorpal-sdk`) from **configuration generation** (local modules).
- **Build definition** (this crate) from **build execution** (Vorpal runtime).

## External Dependencies

### Build-Time Dependencies

| Crate | Purpose |
|---|---|
| `vorpal-sdk` (0.1.0-alpha.0) | Core SDK: context, artifact primitives, step execution, built-in tool artifacts (gh, git, gopls, rust toolchain, protoc) |
| `vorpal-artifacts` (git: main branch) | Pre-built artifact types for community CLI tools (awscli2, bat, direnv, etc.) |
| `anyhow` | Error handling with context |
| `indoc` | Indented string literals for config template rendering |
| `serde` + `serde_json` | JSON serialization for Claude Code and OpenCode configs |
| `tokio` | Async runtime (multi-threaded) |

### Runtime Dependencies

| System | Purpose |
|---|---|
| **Vorpal runtime** | Executes build steps, manages artifact store, creates symlinks |
| **S3 remote cache** (`altf4llc-vorpal-registry`) | Stores and retrieves pre-built artifacts |
| **macOS (aarch64-darwin)** | Primary supported host platform |

### Dependency Management

- Cargo crate updates managed by [Renovate](https://docs.renovatebot.com/) with auto-merge for minor/patch on stable crates (version >= 1.0).
- Custom Renovate manager tracks the tokyonight.nvim bat theme version from raw GitHub URLs in `src/user.rs`.
- `vorpal-artifacts` is pinned to `main` branch via git dependency (no versioned releases yet).

## Key Architectural Decisions

### 1. Rust as Configuration Language

The project uses Rust as the configuration language rather than YAML, TOML, or a dedicated DSL. This trades simplicity of authoring for:
- Compile-time type safety on all configuration values.
- Full programmatic composability (shared color palettes, conditional logic).
- IDE support (autocomplete, go-to-definition on builder methods).

### 2. Single Binary, Two Artifacts

Both `dev` and `user` artifacts are defined in a single `main()` function. The `dev` artifact is a bootstrapping dependency (provides the Rust toolchain to compile this project), while `user` is the actual deliverable. This creates a circular dependency resolved by having Vorpal installed separately on the host.

### 3. Vorpal as Build System

The project delegates all artifact management (fetching, building, caching, symlinking) to Vorpal. The Rust code is purely a build definition -- it describes what to build, not how. This means the project cannot be built or tested without a working Vorpal installation.

### 4. Git-Pinned Dependency for vorpal-artifacts

`vorpal-artifacts` is a git dependency pinned to `main` rather than a versioned crate. This allows rapid iteration but means builds are not fully reproducible across time without the `Cargo.lock` file. The `Vorpal.lock` file provides content-addressed source pinning at the Vorpal level.

### 5. Agent Team as Deployed Artifacts

Claude Code agent definitions and skills are treated as build artifacts, packaged from local `agents/` and `skills/` directories via `FileSource` and symlinked to `~/.claude/`. This makes agent persona management part of the same build pipeline as tool configuration.

## Platform Support

The `SYSTEMS` constant declares four platforms, but in practice the project targets **aarch64-darwin** (Apple Silicon macOS). The `Vorpal.lock` file pins all sources to `aarch64-darwin`, and the CI runs exclusively on `macos-latest`. The multi-platform declaration in `SYSTEMS` appears to be aspirational or inherited from Vorpal SDK conventions.

## CI/CD Pipeline

GitHub Actions (`.github/workflows/vorpal.yaml`) defines a two-stage pipeline:

1. **`build-dev`**: Checks out code, installs Vorpal (nightly) with S3 registry backend, builds `dev` artifact, uploads `Vorpal.lock` as a build artifact.
2. **`build`** (depends on `build-dev`): Builds the `user` artifact using the same Vorpal setup.

Both jobs run on `macos-latest` and use AWS credentials from GitHub Secrets for S3 cache access.

## Gaps and Limitations

- **No tests**: The project has no unit tests, integration tests, or build verification beyond CI running `vorpal build`. Configuration generators are untested.
- **No error recovery**: All `build()` calls use `?` propagation with `anyhow`. There is no retry logic, partial build recovery, or graceful degradation.
- **Single-user design**: The configuration is hardcoded for a single user's preferences (specific tools, Tokyo Night theme, specific font). There is no parameterization or multi-user support.
- **macOS-only in practice**: Despite declaring four platform targets, only aarch64-darwin is actually supported in the lock file and CI.
- **Alpha SDK dependency**: `vorpal-sdk` is at `0.1.0-alpha.0`, meaning the API surface is unstable and may change without notice.
- **No local development story without Vorpal**: The project cannot be built, tested, or validated without a working Vorpal installation. There is no mock or dry-run mode.
- **Large OpenCode config module**: `src/user/opencode.rs` is notably large with extensive struct definitions, suggesting it may benefit from generation or simplification if the schema stabilizes.
