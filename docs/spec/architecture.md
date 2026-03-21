---
project: "dotfiles.vorpal"
maturity: "experimental"
last_updated: "2026-03-21"
updated_by: "@staff-engineer"
scope: "System architecture of the dotfiles.vorpal declarative environment manager"
owner: "@staff-engineer"
dependencies:
  - security.md
  - operations.md
---

# Architecture

This document describes the architecture of `dotfiles.vorpal` as it exists today. It is a declarative dotfiles manager built on the Vorpal build system, where the entire development environment -- CLI tools, configuration files, themes, and symlinks -- is defined as a Rust program that produces reproducible, content-addressed artifacts.

## System Overview

The project is a Rust binary (`vorpal`) that acts as a Vorpal build configuration. When executed by the Vorpal runtime, it declares artifacts (CLI tools, generated config files, downloaded resources) and their relationships, which Vorpal then builds, caches, and deploys to the local filesystem via symlinks into `/var/lib/vorpal/store/`.

The project also defines and deploys a Claude Code agent team (5 agents, 4 skills) as part of the user environment.

### Top-Level Artifacts

The binary produces two top-level artifacts:

| Artifact | Purpose | Entry Point |
|----------|---------|-------------|
| `dev` | Development toolchain (Protoc + Rust toolchain) for building the project itself | `src/vorpal.rs:33` |
| `user` | Full user environment: 16 CLI tools, 10 config files, symlinks, env vars | `src/vorpal.rs:43` |

Build order: `dev` must be built first (provides the Rust toolchain), then `user`.

## Module Structure

```
src/
  vorpal.rs          # Binary entry point. Builds `dev` and `user` artifacts.
  lib.rs             # Library root. Exports `file`, `user` modules. Defines SYSTEMS constant.
  file.rs            # Generic file artifact builders (FileCreate, FileDownload, FileSource).
  user.rs            # UserEnvironment struct. Orchestrates all user artifact building.
  user/
    bat.rs           # BatConfig -- plain-text bat configuration generator.
    claude_code.rs   # ClaudeCode -- JSON settings.json generator with builder pattern.
    ghostty.rs       # GhosttyConfig -- key-value config generator for Ghostty terminal.
    k9s.rs           # K9sSkin -- YAML skin generator for K9s (Tokyo Night theme).
    opencode.rs      # Opencode -- JSON config generator for OpenCode AI tool.
    statusline.sh    # Bash script (included via include_str!) for Claude Code status bar.
```

### Module Responsibilities

**`src/vorpal.rs`** -- The binary entry point. Acquires a Vorpal `ConfigContext`, builds the `dev` artifact (Protoc + Rust toolchain), then builds the `user` artifact via `UserEnvironment::build()`, and finally calls `context.run()` to execute the build plan.

**`src/lib.rs`** -- Library root. Defines the `SYSTEMS` constant (all four supported Vorpal target systems: `Aarch64Darwin`, `Aarch64Linux`, `X8664Darwin`, `X8664Linux`) and a `get_output_path()` helper that constructs Vorpal store paths. Note: while all four systems are declared, the project is primarily built and tested on `aarch64-darwin` only.

**`src/file.rs`** -- Three generic artifact builders:
- `FileCreate` -- Creates a file artifact from inline string content. Supports an `executable` flag. Used for generated configs and the statusline script.
- `FileDownload` -- Downloads a file from a URL and packages it as an artifact. Used for the bat theme.
- `FileSource` -- Copies files from the project source tree into an artifact. Used for the `agents/` and `skills/` directories.

**`src/user.rs`** -- The `UserEnvironment` struct and its `build()` method. This is the core orchestration module (~490 lines). It:
1. Builds 16 CLI tool artifacts via `vorpal-artifacts` and `vorpal-sdk` types.
2. Builds 10 configuration file artifacts via the `user/` sub-modules and `FileCreate`/`FileDownload`/`FileSource`.
3. Assembles everything into a `UserEnvironment` artifact with environment variables, symlinks, and artifact dependencies.

**`src/user/*.rs`** -- Configuration generators, each following the builder pattern:
- Struct with fields for all config options.
- `new()` constructor with sensible defaults.
- `with_*()` builder methods for each option.
- `build()` method that serializes to the target format (JSON, YAML, or plain text) and wraps the result in a `FileCreate` artifact.

## Dependency Graph

### External Crate Dependencies

| Crate | Version | Purpose |
|-------|---------|---------|
| `vorpal-sdk` | `0.1.0-alpha.0` (crates.io) | Core Vorpal SDK: context, artifact types, build primitives |
| `vorpal-artifacts` | `0.1.0-rc.0` (git, `main` branch) | Pre-built artifact definitions for common CLI tools (awscli2, bat, direnv, etc.) |
| `anyhow` | `1` | Error handling with context |
| `indoc` | `2` | Indented string literals for shell script templates |
| `serde` + `serde_json` | `1.0.228` / `1.0.148` | JSON serialization for config generators |
| `tokio` | `1` (rt-multi-thread) | Async runtime for Vorpal context operations |

Key observation: `vorpal-artifacts` is pinned to git `main` branch (not a tagged release), meaning it tracks upstream HEAD. This is a deliberate choice for a personal dotfiles repo but introduces supply chain risk (see `security.md`).

### Internal Artifact Dependency Graph

```
dev (DevelopmentEnvironment)
  |-- Protoc
  |-- RustToolchain

user (UserEnvironment)
  |-- 16 CLI tools: awscli2, bat, direnv, doppler, fd, gh, git, gopls,
  |                  jj, jq, k9s, kubectl, lazygit, nnn, ripgrep, tmux
  |-- bat config (BatConfig)
  |-- bat theme (FileDownload -- tokyonight.tmTheme)
  |-- Claude Code settings (ClaudeCode -> JSON)
  |-- Claude agents (FileSource -> agents/*.md)
  |-- Claude skills (FileSource -> skills/*/)
  |-- Claude statusline (FileCreate -> statusline.sh)
  |-- Ghostty config (GhosttyConfig)
  |-- K9s skin (K9sSkin -> YAML)
  |-- Markdown vim ftplugin (FileCreate -> "setlocal wrap")
  |-- OpenCode config (Opencode -> JSON)
```

All artifacts within `user` are built sequentially (awaited one at a time in `user.rs`), then assembled into the final `UserEnvironment` with symlinks and environment variables.

## Key Architectural Patterns

### Builder Pattern for Configuration

Every configuration generator (`ClaudeCode`, `GhosttyConfig`, `K9sSkin`, `BatConfig`, `Opencode`) follows the same pattern:

1. `Struct::new(name, systems)` -- creates default config.
2. `.with_*(value)` -- chainable builder methods.
3. `.build(context)` -- serializes and creates a Vorpal `FileCreate` artifact.

This pattern enables the configuration to be expressed declaratively in Rust while producing deterministic output files.

### Content-Addressed Artifact Store

All built artifacts are stored in `/var/lib/vorpal/store/artifact/output/{namespace}/{digest}`. The `get_output_path()` function in `lib.rs` constructs these paths. Paths are content-addressed by digest, enabling caching and deduplication.

### Symlink-Based Deployment

The `user` artifact does not install tools to traditional paths. Instead, it:
1. Builds each tool/config into the Vorpal store.
2. Creates symlinks from user-facing paths (e.g., `~/.config/bat/config`, `~/.claude/settings.json`) into the store.

This means the user's home directory contains only symlinks pointing into `/var/lib/vorpal/store/`. Deployment is atomic at the symlink level.

### Shell Script Steps

File artifacts are built using shell script steps (`step::shell()`). The `FileCreate`, `FileDownload`, and `FileSource` builders all generate bash scripts that copy/create files into `$VORPAL_OUTPUT`. This is the Vorpal build primitive -- every artifact is produced by a shell script step.

## Agent Team Architecture

The project deploys a five-agent Claude Code development team. Agent definitions live in `agents/*.md` and are deployed to `~/.claude/agents/` via `FileSource`.

### Agents

| Agent File | Role |
|-----------|------|
| `agents/staff-engineer.md` | Architecture, TDDs, code review, design guidance |
| `agents/senior-engineer.md` | Implementation, code quality, debugging |
| `agents/project-manager.md` | Issue planning, task breakdown, dependency management |
| `agents/sdet.md` | Test infrastructure, automation, quality engineering |
| `agents/ux-designer.md` | User experience design specs |

### Skills

| Skill | Location | Purpose |
|-------|----------|---------|
| `dev` | `skills/dev/SKILL.md` | Multi-agent orchestrator -- coordinates all 5 agents for development work |
| `specs` | `skills/specs/SKILL.md` | Bootstraps `docs/spec/` project specifications |
| `vote` | `skills/vote/SKILL.md` | PBFT-inspired consensus protocol for decision validation |
| `add-artifact` | `skills/add-artifact/` | Empty (placeholder for future artifact addition workflow) |
| `evolve-agents` | `.claude/skills/evolve-agents/` | Reviews and improves agent definitions |
| `evolve-skills` | `.claude/skills/evolve-skills/` | Reviews and improves skill definitions |

### Delegation Protocol

Sub-agents (spawned by the `/dev` orchestrator) lack `Agent`/`TeamCreate` tools. When a sub-agent needs to invoke `/vote` (which requires spawning reviewer agents), it uses a delegation protocol:

1. Sub-agent creates a vote proposal via `docket vote create` (has Bash access).
2. Sub-agent sends a lightweight `delegation_request` (containing only `vote_id`) to the orchestrator via `SendMessage`.
3. Orchestrator spawns reviewer agents, casts votes, evaluates quorum.
4. Orchestrator sends `delegation_response` back to the sub-agent.
5. Sub-agent reads full result from docket.

This protocol is documented in detail in `docs/tdd/agent-delegation-protocol.md`.

### Docket Integration

The project uses Docket (`.docket/`) for issue tracking and consensus voting. Docket stores its data in `.docket/issues.db` (SQLite) and `.docket/consensus/`. All agents have access to the `docket` CLI via Bash.

## Build and Deployment Pipeline

### Local Build

```bash
vorpal build 'dev'   # Build development toolchain
vorpal build 'user'  # Build full user environment (depends on dev)
```

The Vorpal runtime:
1. Compiles the Rust binary (using the toolchain from `dev`).
2. Executes the binary to discover the artifact graph.
3. Builds each artifact (running shell script steps).
4. Caches artifacts by content hash in the local store and optionally in S3.
5. Creates symlinks from the user's home directory into the store.

### CI/CD

GitHub Actions (`.github/workflows/vorpal.yaml`) runs on pushes to `main` and pull requests:

1. **`build-dev`** job: Builds the `dev` artifact on `macos-latest`. Uploads `Vorpal.lock` as a build artifact.
2. **`build`** job (depends on `build-dev`): Builds the `user` artifact using a matrix strategy (currently only `user`).

Both jobs use `ALT-F4-LLC/setup-vorpal-action@main` with S3-backed remote caching (`altf4llc-vorpal-registry` bucket).

### Source Management

- `Vorpal.toml` -- Declares the project language (`rust`) and source includes (`src`, `Cargo.toml`, `Cargo.lock`).
- `Vorpal.lock` -- Lock file for external source downloads. Contains content-addressed digests for all downloaded artifacts (CLI tool binaries, theme files). Currently locks 38 sources, all for `aarch64-darwin`.
- `.envrc` -- Direnv integration for activating the Vorpal development environment.
- `renovate.json` -- Automated dependency updates with auto-merge for minor/patch on stable crates.

## Platform Support

The `SYSTEMS` constant in `lib.rs` declares four target systems: `Aarch64Darwin`, `Aarch64Linux`, `X8664Darwin`, `X8664Linux`. However, in practice:

- **`aarch64-darwin` is the only actively used and tested platform.** All 38 entries in `Vorpal.lock` are `aarch64-darwin`. The CI runs on `macos-latest`.
- The other three systems are declared but have no corresponding lock entries, meaning builds would need to fetch and hash sources at build time.
- This is appropriate for a personal dotfiles repository targeting a single developer's machine.

## Known Gaps

1. **No tests.** The project has no unit tests, integration tests, or build verification beyond CI building the artifacts successfully.
2. **Sequential artifact building.** All artifacts in `UserEnvironment::build()` are built sequentially with `await`. The Vorpal runtime may parallelize the underlying build steps, but the configuration declaration is sequential.
3. **`add-artifact` skill is empty.** The `skills/add-artifact/` directory exists but contains no `SKILL.md`.
4. **`vorpal-artifacts` pinned to git main.** Not a tagged release -- tracks upstream HEAD.
5. **No rollback mechanism documented.** If a build produces a bad configuration, there is no documented procedure to revert to a previous artifact set (though the content-addressed store retains previous versions).
6. **Observability is external.** Claude Code telemetry is configured to ship to external Grafana endpoints (Loki, Mimir) but there is no observability for the dotfiles build process itself.
