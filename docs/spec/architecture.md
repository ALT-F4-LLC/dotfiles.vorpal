---
project: "dotfiles.vorpal"
maturity: "experimental"
last_updated: "2026-03-18"
updated_by: "@staff-engineer"
scope: "System architecture, component relationships, design patterns, and key architectural decisions"
owner: "@staff-engineer"
dependencies:
  - security.md
  - operations.md
---

# Architecture

## System Overview

dotfiles.vorpal is a declarative dotfiles manager built as a Rust program on top of the
[Vorpal](https://github.com/ALT-F4-LLC/vorpal) build system. Rather than imperative shell scripts
or symlink managers, the entire development environment -- CLI tools, configuration files, themes,
and symlinks -- is expressed as Rust code that produces reproducible, content-addressed artifacts.

The project has a dual purpose:

1. **Dotfiles management** -- Build and deploy a complete user environment (CLI tools,
   configuration files, themes, symlinks) through the Vorpal artifact pipeline.
2. **Claude Code agent team** -- Define and deploy a five-agent Claude Code development team
   (agent personas, orchestration skills) alongside the dotfiles.

## Top-Level Artifact Graph

The build produces two top-level artifacts:

```
vorpal build 'dev'    --> DevelopmentEnvironment (protoc + Rust toolchain)
vorpal build 'user'   --> UserEnvironment (16 CLI tools + configs + symlinks + agents)
```

`dev` is the bootstrap artifact: it provides the Rust toolchain and Protoc compiler needed to
build the project itself. `user` depends on `dev` implicitly (the project must compile first) but
is a separate artifact with its own dependency graph.

### Dependency Flow

```
                        ┌─────────────┐
                        │   vorpal.rs │  (binary entry point)
                        │   main()    │
                        └──────┬──────┘
                               │
                 ┌─────────────┼─────────────┐
                 ▼                             ▼
        ┌────────────────┐           ┌────────────────┐
        │ dev artifact   │           │ user artifact  │
        │ (DevelopmentEnv)│           │ (UserEnvironment)│
        └───────┬────────┘           └───────┬────────┘
                │                             │
        ┌───────┴───────┐          ┌──────────┼──────────────┐
        ▼               ▼          ▼          ▼              ▼
   ┌─────────┐   ┌───────────┐  CLI tools  Config      Agent/Skill
   │ Protoc  │   │ Rust      │  (16 total) generators  source dirs
   └─────────┘   │ Toolchain │             (5 types)
                 └───────────┘
```

## Directory Structure

```
.
├── src/
│   ├── vorpal.rs          # Binary entry point -- builds dev + user artifacts
│   ├── lib.rs             # Library root -- exports SYSTEMS const, get_output_path()
│   ├── file.rs            # Generic file artifact builders (FileCreate, FileDownload, FileSource)
│   └── user/
│       ├── mod.rs (user.rs)  # UserEnvironment -- orchestrates all user artifacts
│       ├── bat.rs            # BatConfig builder
│       ├── claude_code.rs    # ClaudeCode settings.json builder
│       ├── ghostty.rs        # GhosttyConfig builder
│       ├── k9s.rs            # K9sSkin YAML builder
│       ├── opencode.rs       # Opencode JSON builder
│       └── statusline.sh     # Bash script included via include_str!()
├── agents/                # Claude Code agent persona definitions (markdown)
│   ├── staff-engineer.md
│   ├── senior-engineer.md
│   ├── project-manager.md
│   ├── sdet.md
│   └── ux-designer.md
├── skills/                # Claude Code orchestration skills (markdown)
│   ├── dev-team/SKILL.md
│   └── dev-init/SKILL.md
├── .claude/skills/        # Additional Claude Code evolution skills
│   ├── evolve-agents/SKILL.md
│   └── evolve-skills/SKILL.md
├── Cargo.toml             # Rust package manifest
├── Cargo.lock             # Locked dependency versions
├── Vorpal.toml            # Vorpal build configuration (language, source includes)
├── Vorpal.lock            # Locked source artifact digests (content-addressed)
├── .github/workflows/     # CI pipeline
│   └── vorpal.yaml
├── .docket/               # Docket issue tracking database
│   └── issues.db
├── renovate.json          # Renovate dependency update configuration
└── .envrc                 # direnv environment configuration
```

## Component Architecture

### 1. Entry Point (`src/vorpal.rs`)

The binary entry point. Uses `tokio::main` for async runtime. Performs two sequential operations:

1. Builds the `dev` artifact (`DevelopmentEnvironment`) containing Protoc and the Rust toolchain
   with appropriate environment variables (`PATH`, `RUSTUP_HOME`, `RUSTUP_TOOLCHAIN`).
2. Builds the `user` artifact (`UserEnvironment`) containing all CLI tools, configurations, and
   symlinks.
3. Calls `context.run().await` to execute the Vorpal build pipeline.

The `ConfigContext` from `vorpal_sdk` is the central coordination object -- all artifact builders
receive a mutable reference to it and register their artifacts through it.

### 2. Library Root (`src/lib.rs`)

Exports three items:

- `SYSTEMS` -- A constant array of four supported `ArtifactSystem` targets:
  `Aarch64Darwin`, `Aarch64Linux`, `X8664Darwin`, `X8664Linux`.
- `get_output_path()` -- Formats the Vorpal store path for artifact outputs:
  `/var/lib/vorpal/store/artifact/output/{namespace}/{digest}`.
- Module declarations for `file` and `user`.

The `SYSTEMS` constant defines cross-platform intent (four targets), although the primary
deployment target is `aarch64-darwin` (macOS on Apple Silicon). The Vorpal.lock file currently
only contains `aarch64-darwin` sources, confirming that cross-platform builds are declared but
not actively exercised.

### 3. File Artifact Builders (`src/file.rs`)

Three generic structs for creating file-based artifacts:

| Struct | Purpose | Mechanism |
|---|---|---|
| `FileCreate` | Generate a file from inline content | Writes content via heredoc in shell step |
| `FileDownload` | Fetch a file from a URL | Downloads and copies to output |
| `FileSource` | Package a local directory as an artifact | Copies source directory contents to output |

All three follow the same pattern:
1. Construct with `::new()`, optionally chain builder methods (e.g., `.with_executable(true)`).
2. Call `.build(context)` which creates a shell step, wraps it in an `Artifact`, and registers it
   with the `ConfigContext`.
3. Return a content-addressed digest string.

`FileCreate` supports an `executable` flag that sets chmod 755 vs 644. `FileSource` uses
`ArtifactSource` with include filters to package specific subdirectories from the repository.

### 4. User Environment (`src/user.rs` + `src/user/`)

`UserEnvironment` is the largest component. Its `build()` method orchestrates:

**CLI Tool Artifacts (16 tools):**
Built via `vorpal-artifacts` crate wrappers. Each tool follows the same pattern: `Tool::new().build(context).await?`.
Tools: awscli2, bat, direnv, doppler, fd, gh, git, gopls, jj, jq, k9s, kubectl, lazygit, nnn,
ripgrep, tmux.

**Configuration Generators (5 types):**

| Generator | Output Format | Module |
|---|---|---|
| `BatConfig` | Plain text (`--theme=...`) | `user/bat.rs` |
| `ClaudeCode` | JSON (`settings.json`) | `user/claude_code.rs` |
| `GhosttyConfig` | Key-value pairs | `user/ghostty.rs` |
| `K9sSkin` | YAML (K9s skin format) | `user/k9s.rs` |
| `Opencode` | JSON (OpenCode config) | `user/opencode.rs` |

Each generator is a builder struct with `with_*()` chainable methods that culminates in a
`.build(context)` call. Internally, they all serialize their configuration to a string and
delegate to `FileCreate` for artifact registration.

**Static Assets:**
- `statusline.sh` -- Included at compile time via `include_str!()`, packaged as an executable
  `FileCreate` artifact.
- Bat Tokyo Night theme -- Downloaded from a pinned GitHub release tag via `FileDownload`.
- Neovim markdown ftplugin -- A one-line `FileCreate` (`setlocal wrap`).

**Agent and Skill Directories:**
- `agents/` directory -- Packaged as a `FileSource` artifact, deployed to `~/.claude/agents/`.
- `skills/` directory -- Packaged as a `FileSource` artifact, deployed to `~/.claude/skills/`.

**Environment Variables:**
Three environment variables are set globally: `EDITOR=nvim`,
`GOPATH=$HOME/Development/language/go`, and a `PATH` that includes VMware Fusion, Go bin,
OpenCode bin, Vorpal bin, and local bin.

**Symlinks:**
The final `UserEnvironment` registers 11 symlinks mapping Vorpal store paths to home directory
locations. This is the mechanism by which built artifacts become active on the host system.

### 5. Claude Code Configuration (`src/user/claude_code.rs`)

The most complex configuration generator. Models the full Claude Code `settings.json` schema
as a Rust struct hierarchy:

- `ClaudeCode` -- Top-level settings (model, permissions, sandbox, attribution, MCP servers,
  hooks, plugins, status line, environment variables).
- `Permissions` -- Three-tier permission model (allow/ask/deny) with glob patterns for
  Bash commands, file operations, and web access.
- `Sandbox` -- Sandbox configuration (enabled, excluded commands, network restrictions).
- `Attribution` -- Commit/PR attribution settings.
- `StatusLine`, `HookConfig`, `HookCommand`, `McpServerRule` -- Supporting types.

The builder pattern is used extensively with 40+ `with_*()` methods. All fields use
`#[serde(skip_serializing_if = ...)]` to produce minimal JSON output. The final `build()`
serializes to pretty-printed JSON and delegates to `FileCreate`.

### 6. Agent Team Architecture

Five agent personas defined as markdown files in `agents/`:

| Agent | Responsibility |
|---|---|
| `staff-engineer` | Architecture, TDDs, code review, project specifications |
| `senior-engineer` | Implementation, code quality, debugging |
| `project-manager` | Issue planning, task breakdown, dependency management |
| `sdet` | Test infrastructure, automation, quality engineering |
| `ux-designer` | User experience design specifications |

Two orchestration skills in `skills/`:

- `dev-team` -- Coordinates all five agents for planning and executing development work.
  The Team Lead (skill executor) dispatches to agents based on work type.
- `dev-init` -- Bootstraps `docs/spec/` by spawning 7 parallel `@staff-engineer` agents to
  generate the seven project specification files.

Two additional evolution skills in `.claude/skills/`:

- `evolve-agents` -- For evolving agent persona definitions.
- `evolve-skills` -- For evolving skill definitions.

## Key Design Patterns

### Builder Pattern

Every artifact and configuration type uses the builder pattern:

```
Struct::new(name, systems)
    .with_option_a(value)
    .with_option_b(value)
    .build(context)
    .await?
```

This is the dominant pattern across the entire codebase. It provides a fluent API for
configuration while keeping the `build()` method as the single point of artifact registration.

### Content-Addressed Artifacts

All artifacts are content-addressed via SHA-256 digests. The `Vorpal.lock` file pins every
external source (CLI tool binaries, themes, toolchain components) to exact content hashes.
The `get_output_path()` function constructs store paths as
`/var/lib/vorpal/store/artifact/output/{namespace}/{digest}`, ensuring immutability and
deduplication.

### Configuration-as-Code

All tool configurations are expressed as Rust structs with typed builder APIs rather than
template files or raw strings. This provides:
- Compile-time validation of configuration structure.
- Type-safe builder methods (e.g., `with_font_size(u8)` instead of raw strings).
- Centralized defaults in struct constructors.

The exception is `statusline.sh`, which is a raw bash script included via `include_str!()`.

### Compile-Time Inclusion

Static assets that do not need runtime parameterization are included at compile time via
`include_str!()` (statusline.sh). This avoids filesystem dependencies at build time beyond
the Cargo source includes defined in `Vorpal.toml`.

### Symlink-Based Deployment

The final deployment mechanism is symlinks from well-known home directory paths into the Vorpal
content-addressed store. This means:
- Atomic updates: symlinks are updated to point to new store paths.
- Rollback: previous store entries remain available.
- No file copying: configurations are references into the immutable store.

## External Dependencies

### Build-Time Dependencies (Cargo.toml)

| Crate | Version | Purpose |
|---|---|---|
| `vorpal-sdk` | `0.1.0-alpha.0` | Core Vorpal SDK (context, artifacts, environments) |
| `vorpal-artifacts` | Git (main branch) | Pre-built artifact types for CLI tools |
| `anyhow` | `1` | Error handling with context |
| `indoc` | `2` | Indented string literals for config templates |
| `serde` + `serde_json` | `1.x` | JSON serialization with derive macros |
| `tokio` | `1` (rt-multi-thread) | Async runtime |

The `vorpal-sdk` is at `0.1.0-alpha.0`, confirming the Vorpal ecosystem is pre-stable. The
`vorpal-artifacts` crate is pinned to the `main` branch via Git dependency, meaning it tracks
upstream changes without version pinning.

### Runtime Dependencies

- **Vorpal runtime** -- Must be installed on the host. The build system itself.
- **S3-backed registry** -- `altf4llc-vorpal-registry` bucket for remote artifact caching.
  Requires AWS credentials.
- **jq** -- Used by `statusline.sh` at runtime to parse JSON session data.

## Integration Points

### Vorpal Build System

The project is a Vorpal "config" -- a Rust program that registers artifacts with a
`ConfigContext` and calls `context.run()`. Vorpal handles:
- Source content hashing and lockfile management (`Vorpal.lock`).
- Artifact build orchestration and caching.
- Store management (`/var/lib/vorpal/store/`).
- Symlink creation on the host filesystem.

### GitHub Actions CI

Two-stage pipeline in `.github/workflows/vorpal.yaml`:
1. `build-dev` -- Builds the dev artifact, uploads `Vorpal.lock` as a CI artifact.
2. `build` (depends on `build-dev`) -- Builds the user artifact.

Both stages use `ALT-F4-LLC/setup-vorpal-action@main` to install Vorpal with nightly version
and S3 registry backend.

### Renovate Dependency Management

`renovate.json` configures automated dependency updates:
- Groups serde ecosystem updates together.
- Auto-merges minor/patch updates for stable crates (version >= 1.0).
- Requires manual review for major updates.
- Custom regex manager tracks the tokyonight.nvim theme version from the raw GitHub URL in
  `src/user.rs`.

### OpenTelemetry Observability

The Claude Code configuration includes OTEL environment variables that ship logs and metrics
to external endpoints:
- Logs: `loki.bulbasaur.altf4.domains` (OTLP HTTP/protobuf)
- Metrics: `mimir.bulbasaur.altf4.domains` (OTLP HTTP/protobuf, cumulative temporality)

This indicates an external observability stack (Grafana Loki + Mimir) for monitoring Claude Code
agent sessions.

### Docket Issue Tracking

The `.docket/` directory contains an `issues.db` SQLite database used by the project-manager
agent for local issue tracking and task management.

## Platform Support

The `SYSTEMS` constant declares four targets, but the Vorpal.lock only contains
`aarch64-darwin` sources. The CI pipeline runs on `macos-latest`. Symlink targets include
macOS-specific paths (`~/Library/Application Support/`). The primary (and effectively only)
supported platform is **macOS on Apple Silicon**.

The multi-platform declaration in `SYSTEMS` is aspirational infrastructure for future
cross-platform support but is not currently exercised.

## Architectural Gaps and Observations

1. **No tests.** The project has zero test files. Configuration generators produce strings that
   are not validated beyond Rust's type system. There is no integration testing of the Vorpal
   build pipeline.

2. **Git dependency on vorpal-artifacts.** Pinned to `main` branch, not a versioned release.
   This creates implicit coupling to upstream changes and makes builds non-reproducible across
   time without Cargo.lock.

3. **Single-user design.** The entire configuration is hardcoded for one user's preferences
   (specific tools, themes, font choices, OTEL endpoints). There is no parameterization or
   multi-user abstraction.

4. **No error recovery in statusline.sh.** The script uses `set -euo pipefail` but has no
   fallback if jq is unavailable or the JSON structure changes.

5. **Alpha SDK dependency.** `vorpal-sdk` at `0.1.0-alpha.0` means the core API surface is
   unstable and subject to breaking changes.

6. **Vorpal binary symlink points to a local debug build.**
   `$HOME/Development/repository/github.com/ALT-F4-LLC/vorpal.git/main/target/debug/vorpal`
   is symlinked to `$HOME/.vorpal/bin/vorpal`, coupling the deployed environment to a local
   development checkout of the Vorpal project itself.
