# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Vorpal dotfiles configuration for TheAltF4Stream. Uses the Vorpal SDK to declaratively define and deploy user environment artifacts (CLI tools, configuration files, symlinks) across multiple systems (aarch64-darwin, aarch64-linux, x86_64-darwin, x86_64-linux).

## Build & Dev Commands

```bash
cargo build            # Compile the Vorpal artifact definition
cargo check            # Type-check without building
cargo clippy           # Lint
vorpal build dev       # Build dev environment (Rust toolchain + protoc)
vorpal build user      # Build full user environment (all tools + configs)
vorpal inspect         # Inspect built artifacts
```

The `.envrc` activates the dev environment via direnv: `vorpal build "dev" --path` provides the Rust toolchain.

## Architecture

### Entry Point

`src/vorpal.rs` - Sets up two environments:
1. **`dev`** (`ProjectEnvironment`) - Dev tooling: Rust toolchain + protoc
2. **`user`** (`UserEnvironment`) - Full user environment: CLI tools, config files, symlinks

### Core Modules

- `src/lib.rs` - Exports `SYSTEMS` (all 4 target platforms) and `get_output_path()` for artifact store paths (`/var/lib/vorpal/store/artifact/output/{namespace}/{digest}`)
- `src/file.rs` - Three artifact primitives:
  - `FileCreate` - Creates a file with inline content
  - `FileDownload` - Downloads a file from a URL
  - `FileSource` - Copies files from the project source tree into an artifact
- `src/user.rs` - Orchestrates all user-facing artifacts: CLI tools (from `vorpal-artifacts`), config files, environment variables, and symlinks to `$HOME/.config/` locations

### Configuration Builders (`src/user/`)

Each module uses a builder pattern (`new()` + chainable `with_*()` methods), serializes to the appropriate format, then uses `FileCreate` to produce an artifact:

- `bat.rs` - Bat syntax highlighter config
- `claude_code.rs` - Claude Code `settings.json` (permissions, hooks, plugins, attribution)
- `ghostty.rs` - Ghostty terminal config
- `k9s.rs` - K9s Kubernetes UI skin (YAML)
- `opencode.rs` - OpenCode config (JSON)

### Key Patterns

1. **Builder pattern everywhere** - All config structs use `new()` + `with_*()` for fluent configuration
2. **Artifact digests** - Artifacts return a digest string; output paths are constructed via `get_output_path("library", &digest)`
3. **Symlink mapping** - `UserEnvironment.with_symlinks()` maps artifact output paths to user home directory locations
4. **Platform-aware sources** - `Vorpal.lock` pins source URLs and digests per platform

### Dependencies

- `vorpal-sdk` (github.com/ALT-F4-LLC/vorpal) - Core SDK for building Vorpal artifacts
- `vorpal-artifacts` (github.com/ALT-F4-LLC/artifacts.vorpal) - Pre-built artifact definitions for common CLI tools

### CI

GitHub Actions (`.github/workflows/vorpal.yaml`) runs `vorpal build dev` then `vorpal build user` on macOS. Uses S3-backed registry.

## Issue Tracking

This project uses **beads** (`bd`) for issue tracking. See `AGENTS.md` for workflow commands.
