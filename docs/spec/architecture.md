---
project: "main"
maturity: "stable"
last_updated: "2026-03-20"
updated_by: "@staff-engineer"
scope: "System architecture of the dotfiles.vorpal declarative environment manager"
owner: "@staff-engineer"
dependencies:
  - security.md
  - operations.md
---

# Architecture

## System Overview

dotfiles.vorpal is a declarative dotfiles manager built as a Rust program on the [Vorpal](https://github.com/ALT-F4-LLC/vorpal) build system. Instead of shell scripts or symlink managers, the entire development environment — CLI tools, configuration files, themes, and symlinks — is defined in Rust code that produces reproducible, content-addressed artifacts stored in `/var/lib/vorpal/store/`.

The project also defines and deploys a five-agent Claude Code development team with orchestration skills.

## Top-Level Artifacts

The build produces two top-level artifacts:

| Artifact | Purpose |
|----------|---------|
| `dev` | Development toolchain (Protoc + Rust toolchain) used to build the project itself |
| `user` | Full user environment: 16 CLI tools, 6 configuration generators, agent/skill definitions, and filesystem symlinks |

Build order is sequential: `dev` must complete before `user` can be built, because `user` is compiled with the Rust toolchain that `dev` provides.

## Module Structure

```
src/
├── vorpal.rs          # Binary entry point — builds both `dev` and `user` artifacts
├── lib.rs             # Library root — exports modules, defines supported systems and store path helper
├── file.rs            # Generic file artifact primitives (FileCreate, FileDownload, FileSource)
└── user/
    ├── user.rs        # UserEnvironment — orchestrates all CLI tools, configs, and symlinks (mod re-exported from src/user.rs)
    ├── bat.rs         # BatConfig builder
    ├── claude_code.rs # ClaudeCode settings.json builder (permissions, sandbox, plugins, env, hooks, MCP)
    ├── ghostty.rs     # GhosttyConfig builder (key-value terminal config)
    ├── k9s.rs         # K9sSkin builder (YAML theme)
    ├── opencode.rs    # Opencode builder (JSON config with permissions, keybinds, LSP, agents, themes)
    └── statusline.sh  # Bash script for Claude Code status bar (included via include_str!)
```

### Entry Point (`src/vorpal.rs`)

The binary is a `#[tokio::main]` async function that:

1. Obtains a Vorpal `ConfigContext` via `get_context().await`
2. Builds the `dev` artifact: `Protoc` + `RustToolchain`, packaged as a `DevelopmentEnvironment` with PATH/RUSTUP env vars
3. Builds the `user` artifact: delegates to `UserEnvironment::new("user", SYSTEMS).build(context)`
4. Calls `context.run().await` to execute the build plan

### Library Root (`src/lib.rs`)

Exports two modules (`file`, `user`), defines the four supported `ArtifactSystem` variants (`Aarch64Darwin`, `Aarch64Linux`, `X8664Darwin`, `X8664Linux`), and provides `get_output_path()` for constructing Vorpal store paths.

### File Primitives (`src/file.rs`)

Three reusable abstractions for creating Vorpal artifacts from file content:

| Struct | Purpose |
|--------|---------|
| `FileCreate` | Creates an artifact from inline string content (with optional executable flag) |
| `FileDownload` | Creates an artifact from a remote URL download |
| `FileSource` | Creates an artifact from local source files (copies a directory subtree) |

All three follow the builder pattern and produce artifacts via shell steps executed by Vorpal.

### User Environment (`src/user.rs` + `src/user/`)

`UserEnvironment` is the central orchestrator. Its `build()` method:

1. **Builds 16 CLI tool artifacts** — each from `vorpal-artifacts` or `vorpal-sdk` crate types (e.g., `Awscli2::new().build(context)`)
2. **Builds 6 configuration file artifacts** — using builder structs in `src/user/` modules (BatConfig, ClaudeCode, GhosttyConfig, K9sSkin, Opencode, plus a statusline script via FileCreate)
3. **Builds 2 directory source artifacts** — the `agents/` and `skills/` directories, copied into the store via `FileSource`
4. **Assembles the final `UserEnvironment`** — combining all artifacts, environment variables (EDITOR, GOPATH, PATH), and 11 symlink mappings from the Vorpal store to the host filesystem

## Configuration Generator Pattern

Each configuration module in `src/user/` follows the same pattern:

1. **Struct** with configuration fields and metadata (name, systems)
2. **Constructor** `::new(name, systems)` with sensible defaults
3. **Builder methods** `with_*()` returning `Self` for chaining
4. **`build()` method** that serializes to the target format (plain text, JSON, YAML, key-value) and delegates to `FileCreate` to produce a Vorpal artifact

This pattern is consistent across all six generators. The `ClaudeCode` builder is the most complex (~540 lines), modeling the full Claude Code `settings.json` schema with serde serialization.

## Dependency Graph

### External Crate Dependencies

| Crate | Role |
|-------|------|
| `vorpal-sdk` (0.1.0-alpha.0, crates.io) | Core SDK: context, artifact types, build steps, environment primitives |
| `vorpal-artifacts` (git: ALT-F4-LLC/artifacts.vorpal.git, main branch) | Pre-built artifact types for common CLI tools (Awscli2, Bat, Direnv, etc.) |
| `anyhow` | Error handling via `Result<T>` |
| `indoc` | Indented string literals for config templates |
| `serde` + `serde_json` | JSON serialization (ClaudeCode, Opencode configs) |
| `tokio` (rt-multi-thread) | Async runtime for the build process |

### Artifact Dependency Graph

```
dev
├── Protoc
└── RustToolchain (cargo, clippy, rust-analyzer, rust-src, rust-std, rustc, rustfmt)

user
├── CLI Tools (16): awscli2, bat, direnv, doppler, fd, gh, git, gopls, jj, jq, k9s, kubectl, lazygit, nnn, ripgrep, tmux
├── Config Files (6): bat-config, claude-code, ghostty-config, k9s-skin, opencode, markdown-vim
├── Downloaded Assets (1): bat-theme (Tokyo Night .tmTheme from GitHub)
├── Directory Sources (2): claude-agents, claude-skills
└── Scripts (1): claude-statusline
```

## Agent Team Architecture

The project defines and deploys a five-agent Claude Code team. Agent definitions live in `agents/*.md` and are copied into `~/.claude/agents/` as Vorpal artifacts.

| Agent | File | Role |
|-------|------|------|
| Staff Engineer | `agents/staff-engineer.md` | Architecture, TDDs, code review |
| Senior Engineer | `agents/senior-engineer.md` | Implementation, debugging |
| Project Manager | `agents/project-manager.md` | Issue planning, task breakdown |
| SDET | `agents/sdet.md` | Test infrastructure, QA |
| UX Designer | `agents/ux-designer.md` | UX design specs |

Four orchestration skills coordinate the team:

| Skill | Location | Purpose |
|-------|----------|---------|
| `dev` | `skills/dev/SKILL.md` | Full development workflow orchestration |
| `specs` | `skills/specs/SKILL.md` | Bootstrap `docs/spec/` project specifications |
| `evolve-agents` | `.claude/skills/evolve-agents/SKILL.md` | Review and improve agent definitions |
| `evolve-skills` | `.claude/skills/evolve-skills/SKILL.md` | Review and improve skill definitions |

A fifth skill, `vote`, provides PBFT-inspired consensus voting for multi-agent decision validation.

## Build & Deployment Model

### Content-Addressed Store

All artifacts are built into `/var/lib/vorpal/store/artifact/output/{namespace}/{digest}`. The digest is content-addressed — identical inputs produce identical outputs. The `Vorpal.lock` file pins source URLs and their SHA-256 digests for reproducibility.

### Symlink Deployment

The `user` artifact creates symlinks from well-known host filesystem paths into the Vorpal store:

| Store Source | Host Target |
|---|---|
| bat config artifact | `~/.config/bat/config` |
| bat Tokyo Night theme | `~/.config/bat/themes/tokyonight.tmTheme` |
| Claude Code settings | `~/.claude/settings.json` |
| Agent definitions directory | `~/.claude/agents/` |
| Skill definitions directory | `~/.claude/skills/` |
| Status line script | `~/.claude/statusline.sh` |
| Ghostty config | `~/Library/Application Support/com.mitchellh.ghostty/config` |
| K9s skin | `~/Library/Application Support/k9s/skins/tokyo_night.yaml` |
| Neovim markdown ftplugin | `~/.config/nvim/after/ftplugin/markdown.vim` |
| OpenCode config | `~/.config/opencode/opencode.json` |
| Vorpal binary (from local build) | `~/.vorpal/bin/vorpal` |

### Remote Caching

Artifacts are cached in an S3 bucket (`altf4llc-vorpal-registry`) for sharing between CI and local builds. The CI workflow and local `setup-vorpal-action` both configure this backend.

## CI/CD Pipeline

GitHub Actions (`.github/workflows/vorpal.yaml`) runs on push to `main` and on pull requests:

1. **`build-dev`** — Checks out code, installs Vorpal (nightly) with S3 registry backend, builds `dev`, uploads `Vorpal.lock` as a CI artifact
2. **`build`** (depends on `build-dev`) — Builds the `user` artifact using a matrix strategy (currently single-entry: `user`)

Both jobs run on `macos-latest` using `ALT-F4-LLC/setup-vorpal-action@main`.

## Supported Platforms

The `SYSTEMS` constant declares four target platforms: `Aarch64Darwin`, `Aarch64Linux`, `X8664Darwin`, `X8664Linux`. However, the `Vorpal.lock` file currently only contains source digests for `aarch64-darwin`, and the CI runs exclusively on `macos-latest`. The primary supported platform in practice is **macOS on Apple Silicon**.

## Dependency Management

[Renovate](https://docs.renovatebot.com/) manages dependency updates with the following rules:

- **Cargo crates**: Minor/patch updates auto-merge for stable (>=1.0) crates; major updates require manual review; serde + serde_json are grouped
- **Custom manager**: Tracks the Tokyo Night bat theme version from the raw GitHub URL in `src/user.rs` via regex extraction against `github-releases`

## Design Decisions

### Why Rust Instead of Shell/Nix/YAML

The entire environment is a compiled Rust program. This provides type safety for configuration generation, compile-time validation of builder patterns, and leverages the Vorpal SDK's artifact system for reproducibility. The tradeoff is higher complexity for simple config changes compared to plain dotfile managers.

### Builder Pattern for All Configs

Every configuration generator uses the same `new() -> with_*() -> build()` pattern. This makes the API consistent and composable, but results in verbose code for simple configurations (e.g., `BatConfig` is 38 lines for a single `--theme=tokyonight` setting).

### Agent Definitions as Source Artifacts

Agent and skill markdown files are stored in the repository (`agents/`, `skills/`) and deployed via `FileSource` into the Vorpal store, then symlinked to `~/.claude/`. This means agent definitions are version-controlled and deployed atomically alongside tool configurations.

## Gaps and Limitations

- **Single-platform lock file**: `Vorpal.lock` only contains `aarch64-darwin` sources despite `SYSTEMS` declaring four platforms. Linux and x86_64 builds would fail without lock entries.
- **No tests**: The project has no unit or integration tests. Configuration generators rely solely on the type system and CI build success for validation.
- **No rollback mechanism**: Symlink deployment is atomic per-file but there is no versioned rollback to a previous environment state.
- **K9s and OpenCode modules are large**: `k9s.rs` (23K lines) and `opencode.rs` (79K lines) contain extensive builder APIs that are predominantly boilerplate.
