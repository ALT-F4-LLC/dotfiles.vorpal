# Architecture

This document describes the system architecture of the `dotfiles` project as it actually exists
in the codebase.

---

## Overview

This project is a **declarative dotfiles manager** built on top of the
[Vorpal](https://github.com/ALT-F4-LLC/vorpal) build system. Rather than using shell scripts or
symlink managers to configure a development environment, it defines the entire user environment --
tools, configuration files, themes, and symlinks -- as a Rust program that produces Vorpal
artifacts. The Vorpal runtime then materializes those artifacts into a reproducible, content-
addressed environment on the host system.

The project also contains a second major concern: **Claude Code agent team configuration**. It
defines agent personas, skills, and orchestration workflows that are deployed alongside the
dotfiles as Claude Code settings and agent definitions.

---

## System Components

```
dotfiles (Cargo binary: "vorpal")
├── src/
│   ├── vorpal.rs          -- Binary entry point
│   ├── lib.rs             -- Library root, constants, helpers
│   ├── file.rs            -- Generic file artifact primitives
│   └── user.rs            -- User environment definition (orchestrator)
│       └── user/
│           ├── bat.rs         -- Bat syntax highlighter config
│           ├── claude_code.rs -- Claude Code settings.json generator
│           ├── ghostty.rs     -- Ghostty terminal config
│           ├── k9s.rs         -- K9s Kubernetes UI skin
│           ├── opencode.rs    -- OpenCode AI tool config
│           └── statusline.sh  -- Claude Code status bar script
├── agents/                -- Claude Code agent persona definitions
│   ├── staff-engineer.md
│   ├── senior-engineer.md
│   ├── project-manager.md
│   ├── qa-engineer.md
│   └── ux-designer.md
├── skills/                -- Claude Code skill definitions
│   ├── dev-team/SKILL.md  -- Multi-agent orchestration workflow
│   └── dev-init/SKILL.md  -- docs/spec/ bootstrapper
├── Vorpal.toml            -- Vorpal project manifest
├── Vorpal.lock            -- Pinned source artifact digests
└── Cargo.toml             -- Rust package manifest
```

### Component Relationships

```
vorpal.rs (main)
    │
    ├── Creates "dev" artifact (ProjectEnvironment)
    │   ├── Protoc (protobuf compiler)
    │   └── RustToolchain (Rust compiler, cargo, etc.)
    │
    └── Creates "user" artifact (UserEnvironment)
        ├── CLI Tool Artifacts (16 tools)
        │   awscli2, bat, direnv, doppler, fd, gh, git, gopls,
        │   jj, jq, k9s, kubectl, lazygit, nnn, ripgrep, tmux
        │
        ├── Configuration File Artifacts
        │   ├── BatConfig → bat config file
        │   ├── FileDownload → bat Tokyo Night theme
        │   ├── ClaudeCode → settings.json (Claude Code config)
        │   ├── Opencode → opencode.json (OpenCode config)
        │   ├── GhosttyConfig → Ghostty terminal config
        │   ├── K9sSkin → K9s YAML skin file
        │   ├── FileCreate → markdown.vim config
        │   └── FileCreate → statusline.sh script
        │
        ├── Source Directory Artifacts
        │   ├── FileSource → agents/ directory
        │   └── FileSource → skills/ directory
        │
        ├── Environment Variables
        │   EDITOR, GOPATH, PATH
        │
        └── Symlinks (host filesystem mappings)
            ~/.config/bat/config
            ~/.config/bat/themes/tokyonight.tmTheme
            ~/.claude/settings.json
            ~/.claude/agents/
            ~/.claude/skills/
            ~/.claude/statusline.sh
            ~/Library/Application Support/com.mitchellh.ghostty/config
            ~/Library/Application Support/k9s/skins/tokyo_night.yaml
            ~/.config/nvim/after/ftplugin/markdown.vim
            ~/.config/opencode/opencode.json
            ~/.vorpal/bin/vorpal (linked to local Vorpal debug build)
```

---

## Key Architectural Decisions

### 1. Configuration as Code via Vorpal SDK

The project does not use dotfile managers like `stow`, `chezmoi`, or Nix home-manager. Instead, it
uses the Vorpal SDK to define artifacts programmatically in Rust. Each tool or config file is an
"artifact" with a build step that produces content-addressed output stored under
`/var/lib/vorpal/store/artifact/output/`.

**Rationale:** Vorpal provides reproducible, content-addressed builds with remote caching (S3).
This means the environment is fully declarative and can be rebuilt identically from source.

**Trade-off:** Requires the Vorpal runtime to be available on the host. The binary itself is
symlinked from a local debug build (`~/Development/repository/github.com/ALT-F4-LLC/vorpal.git/
main/target/debug/vorpal`), creating a bootstrap dependency.

### 2. Builder Pattern for Configuration Structs

Every configuration generator (BatConfig, ClaudeCode, GhosttyConfig, K9sSkin, Opencode) follows
the same pattern:

```
Struct::new(name, systems) -> .with_*() chain -> .build(context).await -> Result<String>
```

The `.build()` method serializes the configuration to its target format (JSON, YAML, INI-style,
or plain text) and wraps it in a `FileCreate` artifact. The returned `String` is the content-
addressed artifact hash, not the file content.

**Rationale:** Consistent API across all configuration types. The builder pattern allows the
caller (`user.rs`) to compose configurations declaratively without knowing serialization details.

### 3. Two-Tier Artifact Hierarchy

The binary produces two top-level artifacts:

- **`dev`** (`ProjectEnvironment`): Development toolchain -- protoc and Rust toolchain. This is
  what CI builds first to compile the project itself.
- **`user`** (`UserEnvironment`): The full user environment -- all CLI tools, configurations, and
  symlinks. This depends on `dev` implicitly (same Vorpal context).

CI builds these in sequence: `build-dev` runs first, then `build` runs `vorpal build 'user'`.

### 4. Content-Addressed Store with Symlinks

Artifacts are stored in `/var/lib/vorpal/store/artifact/output/{namespace}/{digest}`. The
`UserEnvironment` maps these store paths to human-friendly locations via symlinks (e.g.,
`~/.config/bat/config` -> `/var/lib/vorpal/store/artifact/output/library/{hash}/user-bat-config`).

The `get_output_path()` helper in `lib.rs` constructs these store paths.

### 5. Multi-Platform Target Declarations

The `SYSTEMS` constant declares support for four platforms:

```rust
[Aarch64Darwin, Aarch64Linux, X8664Darwin, X8664Linux]
```

However, all source entries in `Vorpal.lock` are pinned to `aarch64-darwin` only. The CI workflow
also only runs on `macos-latest`. The multi-platform declaration exists in the code but is not
exercised in practice.

### 6. Agent Team as Deployed Artifacts

The `agents/` and `skills/` directories are not just documentation -- they are deployed to
`~/.claude/agents/` and `~/.claude/skills/` as Vorpal artifacts. This means Claude Code agent
definitions are version-controlled and deployed through the same pipeline as dotfiles.

---

## External Dependencies

### Vorpal SDK (`vorpal-sdk`)

The core dependency. Provides:
- `ConfigContext` -- build context for registering artifacts
- `Artifact`, `ArtifactSource`, `ArtifactSystem` -- artifact definition types
- `step::shell()` -- shell step builder for artifact build scripts
- `ProjectEnvironment`, `UserEnvironment` -- high-level artifact constructors
- Built-in artifact types: `Gh`, `Git`, `Gopls`, `Protoc`, `RustToolchain`

Source: `https://github.com/ALT-F4-LLC/vorpal.git` (branch: `main`)

### Vorpal Artifacts (`vorpal-artifacts`)

Community/organization artifact library. Provides pre-built artifact types for common CLI tools:
`Awscli2`, `Bat`, `Direnv`, `Doppler`, `Fd`, `Jj`, `Jq`, `K9s`, `Kubectl`, `Lazygit`, `Nnn`,
`Ripgrep`, `Tmux`.

Source: `https://github.com/ALT-F4-LLC/artifacts.vorpal.git` (branch: `main`)

### Rust Crate Dependencies

| Crate | Purpose |
|---|---|
| `anyhow` | Error handling |
| `indoc` | Indented string literals for config templates |
| `serde` + `serde_json` | JSON serialization (Claude Code settings, OpenCode config) |
| `tokio` | Async runtime (multi-threaded, required by Vorpal SDK) |

---

## Data Flow

### Build-Time Flow

```
1. `vorpal build 'user'` invokes the binary
2. main() gets a ConfigContext from Vorpal
3. Each artifact type (tool, config, file) registers with the context:
   - Downloads sources from URLs (specified in Vorpal.lock)
   - Runs shell build steps to produce output files
   - Content-addresses the output
4. UserEnvironment registers symlinks mapping store paths to home directory
5. context.run() executes the build plan
6. Vorpal materializes symlinks on the host filesystem
```

### Configuration Generation Flow

```
1. Builder struct created: ClaudeCode::new("user-claude-code", systems)
2. Builder methods set configuration values: .with_env(), .with_permission_allow(), etc.
3. .build(context) serializes to JSON via serde
4. JSON string passed to FileCreate::new()
5. FileCreate generates a shell script that writes the content to $VORPAL_OUTPUT
6. Vorpal executes the script, stores the output, returns the content hash
7. Content hash used to construct store path for symlink mapping
```

---

## Module Boundaries

### `lib.rs` -- Library Root

Exports the `file` and `user` modules. Defines the `SYSTEMS` constant (supported platforms) and
the `get_output_path()` helper for constructing Vorpal store paths.

### `file.rs` -- File Artifact Primitives

Three generic file artifact types:

- **`FileCreate`**: Creates a file from inline string content. Supports setting executable
  permissions. Used for config files, scripts.
- **`FileDownload`**: Downloads a file from a URL via Vorpal's source mechanism. Used for
  external assets (bat themes).
- **`FileSource`**: Packages a local directory as a Vorpal artifact. Used for shipping the
  `agents/` and `skills/` directories.

### `user.rs` -- User Environment Orchestrator

The main orchestrator module. `UserEnvironment::build()` is a ~360-line async method that:
1. Builds all 16 CLI tool artifacts
2. Builds all configuration file artifacts
3. Packages agent and skill directories
4. Composes everything into a `UserEnvironment` with environment variables and symlinks

### `user/` submodules -- Configuration Generators

Each submodule defines a builder struct for a specific tool's configuration:

- **`bat.rs`** (39 lines): Minimal config file generator. Produces a plain-text config.
- **`claude_code.rs`** (509 lines): Comprehensive Claude Code `settings.json` generator.
  Models the full Claude Code settings schema including permissions, sandbox, attribution,
  MCP servers, hooks, plugins, and status line.
- **`ghostty.rs`** (73 lines): Ghostty terminal emulator config generator. Produces INI-style
  key-value config.
- **`k9s.rs`** (587 lines): K9s Kubernetes UI skin generator. Produces YAML via string
  templating (not serde). Extensive color palette configuration.
- **`opencode.rs`** (2207 lines): OpenCode AI tool config generator. Comprehensive JSON config
  with many nested structures for keybinds, permissions, MCP servers, LSP, agents, and themes.
- **`statusline.sh`** (169 lines): Bash script for Claude Code status bar. Reads JSON session
  data from stdin, outputs a color-coded status line with model, project, git, context window,
  cost, and line change information.

---

## CI/CD Integration

The project uses GitHub Actions (`.github/workflows/vorpal.yaml`):

1. **`build-dev` job**: Runs on `macos-latest`. Sets up Vorpal with S3 registry backend
   (`altf4llc-vorpal-registry`). Builds the `dev` artifact. Uploads `Vorpal.lock` as a build
   artifact.

2. **`build` job**: Depends on `build-dev`. Runs on `macos-latest`. Builds the `user` artifact
   using matrix strategy (currently only `user`).

Both jobs use `ALT-F4-LLC/setup-vorpal-action@main` to install Vorpal with the `nightly`
version and configure S3 registry credentials via GitHub secrets.

---

## Gaps and Honest Assessment

### Actively Used vs. Declared Platform Support

The code declares support for 4 platforms (aarch64-darwin, aarch64-linux, x86_64-darwin,
x86_64-linux) but `Vorpal.lock` only pins sources for `aarch64-darwin`. CI only runs on
`macos-latest`. In practice, this is an **aarch64-darwin-only** project.

### Bootstrap Dependency

The `user` artifact symlinks `~/Development/repository/github.com/ALT-F4-LLC/vorpal.git/main/
target/debug/vorpal` to `~/.vorpal/bin/vorpal`. This assumes a specific local checkout path for
the Vorpal repository exists with a debug build available. This is a manual bootstrap step not
captured in the build system.

### No Tests

There are no test files, no test configuration, and no test steps in CI. The project has zero
automated test coverage. Correctness is verified only by whether `vorpal build` succeeds.

### Git-Branch Dependencies

Both `vorpal-sdk` and `vorpal-artifacts` are pulled from `branch = "main"` in their respective
Git repositories. There is no version pinning -- builds depend on the current state of main
branches in external repositories. `Cargo.lock` provides deterministic resolution, but any
`cargo update` could pull breaking changes.

### Large Configuration Modules

`opencode.rs` (2207 lines) and `k9s.rs` (587 lines) are large files dominated by builder
method boilerplate. The K9s module uses string templating for YAML generation rather than a YAML
serialization library, which could drift from the actual K9s skin schema.

### Dependency Management

The project uses Renovate (`renovate.json`) for automated dependency updates, configured with
the `config:recommended` preset. However, Renovate's ability to update Git branch dependencies
(vorpal-sdk, vorpal-artifacts) depends on its Git source manager support.

### Agent Team Configuration

The agents and skills directories represent a significant portion of the project's intellectual
property -- defining a multi-agent software development team with specific roles, orchestration
patterns, and workflows. These are deployed as static markdown files and are not validated or
tested against the Claude Code agent framework's requirements. Changes to Claude Code's agent
spec could break these definitions silently.
