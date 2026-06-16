# dotfiles.vorpal

Declarative dotfiles manager built on the [Vorpal](https://github.com/ALT-F4-LLC/vorpal) build system. Instead of shell scripts or symlink managers, the entire development environment -- CLI tools, configuration files, themes, and symlinks -- is defined as a Rust program that produces reproducible, content-addressed artifacts.

This project also defines a [Claude Code](https://docs.anthropic.com/en/docs/claude-code) agent team configuration with agent personas, skills, and orchestration workflows that are deployed alongside the dotfiles.

## Overview

The project produces two top-level artifacts:

- **`dev`** -- Development toolchain (Protoc and Rust toolchain) used to build the project itself.
- **`user`** -- Full user environment containing all CLI tools, configurations, and filesystem symlinks.

When you run `vorpal build 'user'`, Vorpal builds artifacts into `/var/lib/vorpal/store/` and creates symlinks from the home directory into the store.

## CLI Tools

The user environment includes 16 CLI tools managed as Vorpal artifacts:

| Tool | Description |
|------|-------------|
| [awscli2](https://aws.amazon.com/cli/) | AWS command-line interface |
| [bat](https://github.com/sharkdp/bat) | Syntax-highlighted cat replacement |
| [direnv](https://direnv.net/) | Per-directory environment variables |
| [doppler](https://www.doppler.com/) | Secrets management |
| [fd](https://github.com/sharkdp/fd) | Fast file finder |
| [gh](https://cli.github.com/) | GitHub CLI |
| [git](https://git-scm.com/) | Version control |
| [gopls](https://pkg.go.dev/golang.org/x/tools/gopls) | Go language server |
| [jj](https://github.com/martinvonz/jj) | Git-compatible VCS |
| [jq](https://jqlang.github.io/jq/) | JSON processor |
| [k9s](https://k9scli.io/) | Kubernetes terminal UI |
| [kubectl](https://kubernetes.io/docs/reference/kubectl/) | Kubernetes CLI |
| [lazygit](https://github.com/jesseduffield/lazygit) | Terminal UI for git |
| [nnn](https://github.com/jarun/nnn) | Terminal file manager |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | Fast recursive search |
| [tmux](https://github.com/tmux/tmux) | Terminal multiplexer |

## Configuration Generators

Each tool configuration is defined as a builder struct in Rust:

- **BatConfig** -- Bat theme and settings (plain-text config)
- **ClaudeCode** -- Claude Code `settings.json` with permissions, MCP servers, hooks, and plugins
- **GhosttyConfig** -- Ghostty terminal emulator settings (key-value config)
- **K9sSkin** -- K9s Kubernetes UI skin (Tokyo Night theme, YAML)
- **Opencode** -- OpenCode AI tool settings with keybinds, LSP, agents, and themes (JSON)
- **statusline.sh** -- Bash script for Claude Code status bar with model, git, and cost info

## Agent Team

The project deploys a seven-agent Claude Code development team to `~/.claude/agents/`:

| Agent | Role |
|-------|------|
| **Team Lead** | Orchestrates the other agents through plan/implement/review/verify cycles |
| **Staff Engineer** | Architecture, technical design documents, code review |
| **Senior Engineer** | Implementation, code quality, debugging |
| **Project Manager** | Issue planning, task breakdown, dependency management |
| **Security Engineer** | Security review, threat modeling, trust-boundary analysis |
| **SDET** | Test infrastructure, automation, quality engineering, verification |
| **UX Designer** | User experience design specs |

Skills support the team:

| Skill | Location | Purpose |
|-------|----------|---------|
| **adr** | `src/user/claude-code/skills/adr/` | Authors an Architecture Decision Record as a Docket doc |
| **code-review-verdict** | `src/user/claude-code/skills/code-review-verdict/` | Conducts a scoped code review (general 6-dimension or security playbook) |
| **design-qa** | `src/user/claude-code/skills/design-qa/` | Post-implementation QA of a shipped UX surface against its spec |
| **design-review** | `src/user/claude-code/skills/design-review/` | Peer design review of a UX spec across six dimensions |
| **init-specs** | `src/user/claude-code/skills/init-specs/` | Bootstraps `docs/spec/` project specifications for new repositories |
| **prd** | `src/user/claude-code/skills/prd/` | Authors a Product Requirements Document as a Docket doc |
| **simplify-scout** | `src/user/claude-code/skills/simplify-scout/` | Scouts code for simplification/refactor opportunities (report-only) |
| **tdd** | `src/user/claude-code/skills/tdd/` | Authors a Technical Design Document as a Docket doc |
| **ux-spec** | `src/user/claude-code/skills/ux-spec/` | Authors a UX design spec as a Docket doc |
| **verify-ac** | `src/user/claude-code/skills/verify-ac/` | Verifies a Docket issue's acceptance criteria against the diff |
| **vote** | `src/user/claude-code/skills/vote/` | Multi-agent consensus voting protocol |
| **evolve-agents** | `.claude/skills/evolve-agents/` | Reviews and improves agent definitions in `src/user/claude-code/agents/*.md` |
| **evolve-skills** | `.claude/skills/evolve-skills/` | Reviews and improves skill definitions across the skill ecosystem |
| **evolve-coherence** | `.claude/skills/evolve-coherence/` | Audits agent↔skill coherence across four dimensions and routes fixes to evolve-agents/evolve-skills (report-and-route; never edits files) |

## Symlinks

The build creates the following symlinks on the host filesystem:

| Source (Vorpal store) | Target |
|---|---|
| bat config | `~/.config/bat/config` |
| bat Tokyo Night theme | `~/.config/bat/themes/tokyonight.tmTheme` |
| Claude Code settings | `~/.claude/settings.json` |
| Agent definitions | `~/.claude/agents/` |
| Skill definitions | `~/.claude/skills/` |
| Status line script | `~/.claude/statusline.sh` |
| Ghostty config | `~/Library/Application Support/com.mitchellh.ghostty/config` |
| K9s skin | `~/Library/Application Support/k9s/skins/tokyo_night.yaml` |
| Neovim markdown ftplugin | `~/.config/nvim/after/ftplugin/markdown.vim` |
| OpenCode config | `~/.config/opencode/opencode.json` |
| Vorpal binary | `~/.vorpal/bin/vorpal` |

## Prerequisites

- [Vorpal](https://github.com/ALT-F4-LLC/vorpal) runtime installed on the host system
- macOS on Apple Silicon (aarch64-darwin) -- the primary supported platform

## Building

Build the development toolchain first, then the user environment:

```bash
vorpal build 'dev'
vorpal build 'user'
```

The build system uses S3-backed remote caching (`altf4llc-vorpal-registry`) for artifact storage. Configure AWS credentials for remote cache access.

## CI/CD

GitHub Actions (`.github/workflows/vorpal.yaml`) runs on every push to `main` and on pull requests:

1. **build-dev** -- Builds the `dev` artifact and uploads `Vorpal.lock`.
2. **build** -- Builds the `user` artifact (depends on `build-dev`).

Both jobs run on `macos-latest` using [setup-vorpal-action](https://github.com/ALT-F4-LLC/setup-vorpal-action).

## Dependencies

| Dependency | Purpose |
|---|---|
| [vorpal-sdk](https://github.com/ALT-F4-LLC/vorpal) | Core Vorpal SDK (context, artifacts, environment types) |
| [vorpal-artifacts](https://github.com/ALT-F4-LLC/artifacts.vorpal.git) | Pre-built artifact types for common CLI tools |
| [anyhow](https://crates.io/crates/anyhow) | Error handling |
| [indoc](https://crates.io/crates/indoc) | Indented string literals for config templates |
| [serde](https://crates.io/crates/serde) + [serde_json](https://crates.io/crates/serde_json) | JSON serialization |
| [tokio](https://crates.io/crates/tokio) | Async runtime |

Dependency updates are managed by [Renovate](https://docs.renovatebot.com/) with auto-merge for minor and patch updates on stable crates.

## License

[Apache License 2.0](LICENSE)
