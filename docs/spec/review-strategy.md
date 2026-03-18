---
project: "dotfiles.vorpal"
maturity: "experimental"
last_updated: "2026-03-18"
updated_by: "@staff-engineer"
scope: "Code review priorities, high-risk areas, and review dimensions for the dotfiles.vorpal project"
owner: "@staff-engineer"
dependencies:
  - security.md
  - code-quality.md
---

# Review Strategy

## Project Profile

dotfiles.vorpal is a single-developer declarative dotfiles manager built on the Vorpal build system.
The entire development environment -- CLI tools, configuration files, themes, and symlinks -- is
defined as a Rust program that produces reproducible, content-addressed artifacts. The project also
deploys a Claude Code agent team configuration alongside the dotfiles.

**Contributor profile:** Single maintainer (Erik Reinert), with Renovate bot handling automated
dependency updates. No external contributors at this time.

**Change frequency:** ~74 commits total. Most changes are additive -- new tool configurations, new
permissions, agent definition updates. Destructive refactors are rare.

**CI/CD:** GitHub Actions runs `vorpal build 'dev'` and `vorpal build 'user'` on every push to
`main` and on pull requests. There are no linting, formatting, or test steps in CI -- the only
verification is that the Vorpal build succeeds.

## Review Dimension Priorities

Dimensions are ranked by relevance to this specific project. The project's primary risk surface is
not traditional application logic but rather **configuration correctness** and **security
boundaries** in generated settings files.

| Priority | Dimension | Rationale |
|----------|-----------|-----------|
| 1 | **Security** | The project generates permission rules, sandbox configurations, and secret management boundaries for Claude Code and other tools. Misconfigured permissions can expose sensitive files or allow unintended shell commands. |
| 2 | **Correctness** | Generated configurations are deployed directly to the user's home directory via symlinks. A malformed config breaks the user's development environment with no graceful degradation. |
| 3 | **Operations** | Changes deploy to the host filesystem via Vorpal's content-addressed store. Bad symlink targets or incorrect paths cause silent failures. CI only validates that the build compiles, not that configs are semantically correct. |
| 4 | **Architecture** | The builder pattern used across all configuration generators should remain consistent. New config generators should follow established patterns. |
| 5 | **Code Quality** | Important for maintainability of the config generators, but the codebase is small (~1,200 lines of source) and the patterns are repetitive by design. |
| 6 | **Performance** | Not a meaningful concern. The build runs infrequently and performance is dominated by Vorpal artifact resolution, not this project's code. |

## High-Risk Areas

### 1. Claude Code Permissions and Sandbox Configuration

**Files:** `src/user/claude_code.rs`, `src/user.rs` (lines 86-257)

This is the highest-risk area in the project. The `ClaudeCode` struct generates `settings.json`
for Claude Code, which controls:

- **Allow/ask/deny permission rules** for bash commands, file read/write/edit, and web access
- **Sandbox configuration** including excluded commands and network restrictions
- **Sensitive file deny rules** protecting `.env`, `.ssh`, `.gnupg`, `.kube`, and other credential paths

**What to watch for:**
- New `with_permission_allow()` calls that grant broad shell access (especially to destructive
  commands like `rm`, `git reset`, `git checkout`)
- Removal or weakening of `with_permission_deny()` rules for sensitive paths
- Changes to sandbox excluded commands (`aws`, `docker`, `gh`, `git` are currently excluded
  from sandboxing)
- New environment variable additions to `with_env()` that might contain secrets or telemetry
  endpoints
- The ordering of allow/ask/deny rules matters -- later rules may override earlier ones depending
  on the Claude Code settings resolution

**Review approach:** Compare every permission change against the existing deny list. Verify that
new allow rules do not create a path to bypass existing deny rules. Check that sensitive
directories remain protected.

### 2. Symlink Targets and Filesystem Paths

**Files:** `src/user.rs` (lines 473-485)

Symlinks map Vorpal store paths to locations in `$HOME`. Incorrect targets can:

- Overwrite existing user configuration files
- Point to nonexistent store paths (silent failure)
- Create symlinks in system directories (though current targets are all under `$HOME`)

**What to watch for:**
- New symlink entries that target paths outside `$HOME`
- Changes to `get_output_path()` format strings that could break path resolution
- Symlink targets that conflict with other tools' expected configuration locations

### 3. Shell Script Generation via `FileCreate`

**Files:** `src/file.rs`

`FileCreate` writes content into build scripts using heredoc (`cat << 'EOF'`). The content is
user-controlled (from builder methods) and injected directly into a bash script.

**What to watch for:**
- Content that could break the heredoc boundary (e.g., a line containing only `EOF`)
- Changes to the shell script template that could alter file permissions beyond 644/755
- The `with_executable(true)` flag grants execute permission -- verify this is intentional for
  each use

### 4. Agent and Skill Definitions

**Files:** `agents/*.md`, `skills/*/SKILL.md`

These markdown files define the behavior of AI agents deployed to `~/.claude/agents/`. Changes
here affect how Claude Code agents operate across all projects on the machine.

**What to watch for:**
- Instructions that could cause agents to bypass safety guards (commit without asking, force push,
  delete files)
- Scope creep in agent responsibilities that could lead to unintended actions
- Changes to the "no-commit guard" that was explicitly added in commit `6cc3c77`
- Skill orchestration changes that could create infinite loops or excessive API usage

### 5. External Dependencies and Version Pins

**Files:** `Cargo.toml`, `renovate.json`, `src/user.rs` (theme URL on line 66)

**What to watch for:**
- `vorpal-artifacts` is pinned to a git branch (`main`), not a version -- any upstream change
  is automatically pulled. This is the highest dependency risk.
- `vorpal-sdk` uses a `0.1.0-alpha.0` version -- pre-release versions may have breaking changes
- Renovate auto-merges minor/patch updates for stable crates only (version >= 1.0). This is
  correctly configured but should be monitored.
- The bat theme URL embeds a specific git tag (`v4.14.1`). Renovate has a custom manager for
  this, which is good, but the URL is in source code rather than a separate config.

## Common Change Patterns

Based on commit history, these are the most frequent types of changes:

### Permission Updates (Most Frequent)

Changes to Claude Code allow/ask/deny rules are the most common commit type. Review checklist:

- [ ] New `allow` rules are scoped to specific command prefixes (not wildcards)
- [ ] No existing `deny` rules are removed without explicit justification
- [ ] `ask` rules are used for destructive operations (`git commit`, `git push`, `rm`, `chown`)
- [ ] Deny rules cover all three permission types (Read, Write, Edit) for sensitive paths
- [ ] New web fetch permissions are limited to specific domains

### New Tool Configuration Generators

Adding support for a new tool (like bat, ghostty, k9s). Review checklist:

- [ ] Follows the builder pattern: `new()` -> `with_*()` -> `build()` -> `FileCreate`
- [ ] Struct lives in its own module under `src/user/`
- [ ] Tool is added to the `UserEnvironment::build()` dependency chain
- [ ] Symlink is added mapping store output to the correct config path
- [ ] The `SYSTEMS` constant is used for cross-platform support (even if only macOS is primary)

### Agent/Skill Definition Changes

- [ ] Changes align with the five-agent team model (staff, senior, PM, QA, UX)
- [ ] No-commit guard remains intact across all agents
- [ ] Skill orchestration does not create circular dependencies between agents

### Dependency Updates

- [ ] Renovate auto-merge rules are respected (manual review for major bumps)
- [ ] `vorpal-artifacts` branch pin is acknowledged as a risk
- [ ] Pre-release dependency versions are treated with extra scrutiny

## Gaps and Missing Review Infrastructure

### No Automated Checks

- **No `cargo fmt` or `cargo clippy` in CI.** Formatting and lint checks are manual. The
  `with_permission_allow("Bash(cargo fmt:*)")` and `with_permission_allow("Bash(cargo clippy:*)")`
  permissions exist for local Claude Code use, but nothing enforces them.
- **No tests.** The project has zero test files. There are no unit tests for configuration
  generators, no integration tests for generated output, and no snapshot tests for expected
  config file contents.
- **No PR template or CONTRIBUTING guide.** As a single-developer project this is expected, but
  it means there is no documented review process.
- **No CODEOWNERS file.** Not needed currently but would be relevant if contributors are added.
- **No pre-commit hooks.** No `.pre-commit-config.yaml` or git hooks are present in the
  repository.

### No Configuration Validation

The build system only verifies that the Rust code compiles and that `vorpal build` succeeds. It
does not validate that:

- Generated JSON files parse correctly (Claude Code settings, OpenCode config)
- Generated YAML files parse correctly (K9s skin)
- Generated key-value configs have valid syntax (Ghostty, bat)
- Symlink targets will resolve at deploy time
- Permission rules follow the expected Claude Code schema

### No Rollback Documentation

There is no documented procedure for rolling back a bad configuration deployment. Since Vorpal
uses content-addressed artifacts, previous versions exist in the store, but the process to
revert a symlink to a prior artifact is not documented.

## Review Workflow Recommendations

### For the Current Single-Developer Setup

1. **Self-review against this document's checklists** before merging permission or agent changes.
2. **Use `cargo clippy` and `cargo fmt --check` locally** before pushing, since CI does not
   enforce them.
3. **Manually verify generated JSON** after changing `ClaudeCode` or `Opencode` builder calls
   (e.g., `cargo run` and inspect the output, or add a simple debug print).
4. **Treat agent definition changes as security-sensitive** -- they control AI behavior across
   all projects on the machine.

### If Contributors Are Added

1. Add `cargo fmt --check` and `cargo clippy` to the GitHub Actions workflow.
2. Create a PR template with the permission-change checklist from this document.
3. Require review approval for changes to `src/user/claude_code.rs` and `agents/`.
4. Add snapshot tests for generated configuration files to catch unintended changes.
5. Consider adding a CODEOWNERS file routing security-sensitive files to the project owner.
