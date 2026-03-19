---
project: "dotfiles.vorpal"
maturity: "experimental"
last_updated: "2026-03-18"
updated_by: "@staff-engineer"
scope: "System architecture, component relationships, design patterns, and integration points"
owner: "@staff-engineer"
dependencies:
  - operations.md
  - security.md
---

# Architecture

## System Overview

dotfiles.vorpal is a declarative dotfiles manager built as a Rust program on top of the
[Vorpal](https://github.com/ALT-F4-LLC/vorpal) build system. Rather than using shell scripts or
symlink managers, the entire development environment — CLI tools, configuration files, themes, and
symlinks — is defined as Rust code that produces reproducible, content-addressed artifacts stored
in `/var/lib/vorpal/store/`.

The project also serves as a deployment vehicle for a five-agent Claude Code team configuration,
including agent personas, skills, and orchestration workflows.

## Top-Level Artifact Graph

The build produces two top-level artifacts:

```
vorpal build 'dev'   --> DevelopmentEnvironment("dev")
                           ├── Protoc
                           └── RustToolchain (cargo, clippy, rustfmt, rust-analyzer, rust-src, rust-std, rustc)

vorpal build 'user'  --> UserEnvironment("user")
                           ├── 16 CLI tool artifacts (awscli2, bat, direnv, doppler, fd, gh, git, gopls, jj, jq, k9s, kubectl, lazygit, nnn, ripgrep, tmux)
                           ├── 10 configuration file artifacts (bat config, bat theme, claude code settings, claude agents, claude skills, claude statusline, ghostty config, k9s skin, markdown vim, opencode config)
                           ├── Environment variables (EDITOR, GOPATH, PATH)
                           └── 12 symlinks (store paths -> home directory locations)
```

The `dev` artifact is a self-hosting dependency: it provides the Rust toolchain and Protoc needed
to build this project itself. The `user` artifact is the primary deliverable containing all tools
and configuration for the end-user environment.

## Source Code Structure

```
src/
├── vorpal.rs          # Binary entry point (main). Builds dev + user artifacts.
├── lib.rs             # Library root. Exports file, user modules. Defines SYSTEMS constant and get_output_path().
├── file.rs            # Generic file artifact primitives: FileCreate, FileDownload, FileSource.
├── user.rs            # UserEnvironment struct. Orchestrates all user tool and config artifact builds.
└── user/
    ├── bat.rs         # BatConfig builder (plain-text config generation)
    ├── claude_code.rs # ClaudeCode builder (JSON settings.json generation via serde)
    ├── ghostty.rs     # GhosttyConfig builder (key-value config generation)
    ├── k9s.rs         # K9sSkin builder (YAML skin generation via formatdoc templates)
    ├── opencode.rs    # Opencode builder (JSON config generation via serde)
    └── statusline.sh  # Bash script included via include_str!() for Claude Code status bar
```

### Non-Source Directories

```
agents/                # Claude Code agent persona markdown files (5 agents)
skills/                # Claude Code skill definitions
  ├── dev-team/        #   Multi-agent orchestration skill
  └── dev-init/        #   Spec bootstrapping skill
docs/                  # Project documentation
  └── spec/            #   Project specification files
```

## Key Architectural Decisions

### 1. Dotfiles as a Rust Binary, Not Scripts

The entire environment is defined as a Rust program compiled to a binary named `vorpal`. The
`main()` function in `src/vorpal.rs` is the sole entry point. It builds two artifacts sequentially
by calling into the Vorpal SDK's context system. This gives compile-time type safety for
configuration generation and leverages Vorpal's content-addressed artifact store for
reproducibility.

### 2. Builder Pattern for Configuration Generation

Each tool configuration is represented as a Rust struct with a builder-style API:

- `BatConfig::new().with_theme("tokyonight").build(context)`
- `ClaudeCode::new().with_permission_allow("...").build(context)`
- `GhosttyConfig::new().with_font_family("...").build(context)`
- `K9sSkin::new().with_body_fg_color("#f8f8f2").build(context)`
- `Opencode::new().with_theme("tokyonight").build(context)`

All builders follow the same pattern: construct with `::new(name, systems)`, chain `with_*`
methods, and finalize with `.build(context)`. The `build()` method serializes the configuration
to its target format (JSON, YAML, key-value, or plain text) and wraps it in a `FileCreate`
artifact.

### 3. Three File Artifact Primitives

`src/file.rs` provides three reusable file artifact types, each wrapping Vorpal SDK primitives:

| Type | Purpose | Serialization |
|------|---------|---------------|
| `FileCreate` | Generate a file from in-memory content | Shell script writes content via heredoc |
| `FileDownload` | Fetch a file from a URL | Vorpal source downloads, shell copies to output |
| `FileSource` | Include files from the project source tree | Vorpal source includes, shell copies to output |

Each type follows the same pattern: construct shell script steps, create a Vorpal `Artifact`,
and register it with the build context. `FileCreate` supports an `executable` flag that sets
`chmod 755` vs `644`.

### 4. Content-Addressed Store with Symlinks

Artifacts are stored at content-addressed paths under `/var/lib/vorpal/store/artifact/output/`.
The path format is `{namespace}/{digest}` where namespace is either `library` (for config files)
or the tool name. The `get_output_path()` function in `lib.rs` generates these paths.

The `UserEnvironment` registers symlinks that map store paths to user-facing locations like
`~/.config/bat/config`, `~/.claude/settings.json`, and
`~/Library/Application Support/com.mitchellh.ghostty/config`. This means the home directory
contains only symlinks into the immutable store.

### 5. Multi-Platform Support (Declared, Not Fully Exercised)

The `SYSTEMS` constant in `lib.rs` declares support for four platforms:

- `Aarch64Darwin` (macOS Apple Silicon)
- `Aarch64Linux`
- `X8664Darwin` (macOS Intel)
- `X8664Linux`

However, the `Vorpal.lock` file only contains entries for `aarch64-darwin`, and the CI pipeline
runs only on `macos-latest`. The other three platforms are declared but not currently built or
tested in CI.

### 6. Agent Team as Deployable Configuration

The Claude Code agent team (5 agents, 2 skills) is defined as markdown files in `agents/` and
`skills/`, included in the build via `FileSource`, and symlinked to `~/.claude/agents/` and
`~/.claude/skills/`. The Claude Code settings JSON is generated programmatically by the
`ClaudeCode` builder, including permissions, sandbox rules, environment variables (OTEL
telemetry), and plugin configuration.

## Dependency Graph

### Rust Crate Dependencies

| Crate | Version | Purpose |
|-------|---------|---------|
| `vorpal-sdk` | `0.1.0-alpha.0` | Core Vorpal SDK — build context, artifact types, environment builders, built-in tool artifacts (gh, git, gopls, protoc, rust-toolchain) |
| `vorpal-artifacts` | git (main branch) | Pre-built artifact types for 13 CLI tools (awscli2, bat, direnv, doppler, fd, jj, jq, k9s, kubectl, lazygit, nnn, ripgrep, tmux) |
| `anyhow` | `1` | Error handling |
| `indoc` | `2` | Indented string literals for config templates |
| `serde` + `serde_json` | `1.0.x` | JSON serialization (ClaudeCode and Opencode configs) |
| `tokio` | `1` (rt-multi-thread) | Async runtime required by Vorpal SDK |

The split between `vorpal-sdk` (stable release on crates.io) and `vorpal-artifacts` (git
dependency tracking main branch) is significant: the SDK provides core primitives while the
artifacts crate provides the community/extended tool catalog. The artifacts crate is pinned to
the `main` branch, meaning builds track upstream HEAD.

### External Runtime Dependencies

- **Vorpal runtime**: Must be installed on the host. The build expects `vorpal` CLI to be
  available. A symlink from a local debug build is included in the user environment
  (`$HOME/.vorpal/bin/vorpal`).
- **AWS S3**: The CI pipeline uses S3-backed remote caching
  (`altf4llc-vorpal-registry` bucket) for artifact storage. Requires AWS credentials.

## Build Flow

```
1. vorpal build 'dev'
   └── ConfigContext is created via get_context()
       ├── Protoc::new().build(context)
       ├── RustToolchain::new().build(context)
       └── DevelopmentEnvironment::new("dev", SYSTEMS)
           .with_artifacts([protoc, rust_toolchain])
           .with_environments([PATH, RUSTUP_HOME, RUSTUP_TOOLCHAIN])
           .build(context)

2. vorpal build 'user'
   └── UserEnvironment::new("user", SYSTEMS)
       ├── Build 16 CLI tool artifacts (each via ToolName::new().build(context))
       ├── Build 10 configuration file artifacts (each via Builder::new().build(context))
       ├── Assemble into artifact::UserEnvironment
       │   .with_artifacts([...all 26 artifacts...])
       │   .with_environments([EDITOR, GOPATH, PATH])
       │   .with_symlinks([...12 symlinks...])
       └── .build(context) -> registers with Vorpal
```

All artifact builds are `async` and executed sequentially within each phase (tools, then configs,
then assembly). The Vorpal SDK handles content-addressing, caching, and store management.

## CI/CD Architecture

GitHub Actions workflow (`.github/workflows/vorpal.yaml`):

```
push/PR to main
  ├── build-dev (macos-latest)
  │   ├── checkout
  │   ├── setup-vorpal-action (nightly, S3 registry)
  │   ├── vorpal build 'dev'
  │   └── upload Vorpal.lock artifact
  │
  └── build (macos-latest, depends on build-dev)
      ├── checkout
      ├── setup-vorpal-action (nightly, S3 registry)
      └── vorpal build 'user'
```

The pipeline uses `setup-vorpal-action` to install the Vorpal runtime and configure the S3
registry backend. The `build-dev` job uploads `Vorpal.lock` as a GitHub Actions artifact, though
the `build` job does not explicitly download it — it rebuilds from source.

## Dependency Management

[Renovate](https://docs.renovatebot.com/) manages dependency updates with custom configuration:

- **Cargo crates**: Auto-merges minor/patch updates for stable crates (version >= 1.0).
  Major updates require manual review.
- **Serde ecosystem**: `serde` and `serde_json` are grouped into a single update PR.
- **Custom regex manager**: Tracks the `tokyonight.nvim` bat theme version from the raw
  GitHub URL in `src/user.rs`.

## Gaps and Limitations

- **Single-platform CI**: Only `aarch64-darwin` (macOS Apple Silicon) is built and tested in
  CI, despite four platforms being declared in code.
- **No tests**: The project has zero test files. Configuration generators are not unit-tested.
- **Git dependency on vorpal-artifacts**: The `vorpal-artifacts` crate is pinned to `main`
  branch via git, making builds non-reproducible across time. A version bump in the upstream
  repo can break this project without notice.
- **Sequential artifact builds**: All artifacts are built sequentially despite no data
  dependencies between them. The Vorpal SDK may handle parallelism internally, but the Rust
  code awaits each build serially.
- **Vorpal binary self-reference**: The user environment symlinks a local debug build of Vorpal
  (`$HOME/Development/repository/github.com/ALT-F4-LLC/vorpal.git/main/target/debug/vorpal`)
  to `$HOME/.vorpal/bin/vorpal`. This is a development convenience that creates a circular
  dependency: Vorpal is needed to build the dotfiles, and the dotfiles provide Vorpal.
- **No rollback mechanism**: There is no documented or automated way to roll back to a previous
  version of the user environment. The content-addressed store retains old artifacts, but
  symlinks always point to the latest build output.
- **vorpal-sdk is alpha**: The SDK is at `0.1.0-alpha.0`, indicating the API surface is
  unstable and subject to breaking changes.
