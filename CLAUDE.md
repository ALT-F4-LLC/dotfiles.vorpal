# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Vorpal dotfiles configuration project for TheAltF4Stream. It uses the Vorpal SDK to declaratively define and deploy user environment artifacts (CLI tools, configuration files, symlinks) across multiple systems (aarch64-darwin, aarch64-linux, x86_64-darwin, x86_64-linux).

## Build & Run Commands

```bash
# Build the project (compiles the Vorpal artifact definition)
cargo build

# Run the Vorpal configuration (builds and deploys artifacts)
vorpal build

# Inspect built artifacts
vorpal inspect
```

## Architecture

### Entry Point
- `src/vorpal.rs` - Main entry point. Sets up a `ProjectEnvironment` (dev tools) and `UserEnvironment` (user dotfiles/tools).

### Core Modules
- `src/lib.rs` - Exports `SYSTEMS` constant (all target platforms) and `get_output_path()` helper for artifact store paths.
- `src/user.rs` - Defines `UserEnvironment` which orchestrates all user-facing artifacts:
  - CLI tools from `vorpal-artifacts` (awscli2, bat, beads, direnv, doppler, fd, gh, git, gopls, jj, jq, k9s, kubectl, lazygit, nnn, ripgrep, tmux)
  - Configuration files (bat, claude-code, ghostty, k9s skins, opencode)
  - Environment variables and symlinks to `$HOME/.config/` locations
- `src/file.rs` - Two artifact primitives:
  - `FileCreate` - Creates a file with inline content
  - `FileDownload` - Downloads a file from a URL

### Configuration Builders (src/user/)
Each module implements a builder pattern with `new()` and chainable `with_*()` methods, serializes to JSON/text, then uses `FileCreate` to produce an artifact:
- `claude_code.rs` - Claude Code settings.json configuration
- `ghostty.rs` - Ghostty terminal configuration
- `k9s.rs` - K9s Kubernetes UI skin configuration
- `opencode.rs` - OpenCode configuration
- `bat.rs` - Bat syntax highlighter configuration

### Key Patterns
1. **Builder pattern**: All config structs use `new()` + `with_*()` methods for fluent configuration.
2. **Artifact digests**: Artifacts return a digest string used to construct output paths via `get_output_path("library", &digest)`.
3. **Symlink mapping**: `UserEnvironment` maps artifact output paths to user home directory locations via `with_symlinks()`.

## Dependencies

- `vorpal-sdk` (github.com/ALT-F4-LLC/vorpal) - Core SDK for building Vorpal artifacts
- `vorpal-artifacts` (github.com/ALT-F4-LLC/artifacts.vorpal) - Pre-built artifact definitions for common tools

## Issue Tracking

This project uses **beads** (`bd`) for issue tracking. See AGENTS.md for workflow commands.
