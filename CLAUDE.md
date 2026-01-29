# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Rust-based dotfiles and configuration management system using Vorpal for artifact-based builds. It generates and manages user environment configurations across multiple platforms (macOS/Linux, ARM/Intel).

## Build Commands

```bash
vorpal build 'dev'   # Build dev environment (Rust toolchain + protoc)
vorpal build 'user'  # Build user environment (tools + configs)
cargo build          # Standard Rust build
cargo check          # Check compilation
cargo test           # Run tests
```

## Architecture

**Entry Point:** `src/vorpal.rs` - Builds two environments:
- `dev`: Development tools (Rust toolchain, protoc)
- `user`: User tools and configurations

**Core Pattern:** Builder pattern with `.with_*()` methods for configuration:
```rust
ClaudeCode::new(name, systems)
    .with_always_thinking_enabled(true)
    .with_permission_allow("Bash(cargo build:*)")
    .build(context)
    .await?
```

**Key Files:**
- `src/lib.rs` - Exports and SYSTEMS constant (4 target platforms)
- `src/user.rs` - UserEnvironment builder, configures all user tools and symlinks
- `src/file.rs` - FileCreate and FileDownload utilities
- `src/user/*.rs` - Individual tool configurations (bat, claude_code, ghostty, k9s, opencode)

**Output:** Artifacts are stored in `/var/lib/vorpal/store/artifact/output/{namespace}/{digest}` and symlinked to standard config locations (e.g., `~/.claude/settings.json`, `~/.config/bat/config`).

## Dependencies

External crates from ALT-F4-LLC:
- `vorpal-sdk` - Core Vorpal functionality
- `vorpal-artifacts` - Pre-built tool artifacts (awscli2, bat, k9s, etc.)

## Supported Platforms

Builds target all four systems defined in `SYSTEMS`:
- aarch64-darwin (ARM macOS)
- aarch64-linux (ARM Linux)
- x86_64-darwin (Intel macOS)
- x86_64-linux (Intel Linux)

## Issue Tracking

This project uses **bd** (beads) for issue tracking:
```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --status in_progress  # Claim work
bd close <id>         # Complete work
bd sync               # Sync with git
```

## Session Completion

Work is NOT complete until `git push` succeeds. Mandatory workflow:
1. Create issues for remaining work
2. Run quality gates if code changed
3. Update issue status
4. Push: `git pull --rebase && bd sync && git push`
