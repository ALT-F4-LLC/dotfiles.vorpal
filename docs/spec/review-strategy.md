---
project: "dotfiles.vorpal"
maturity: "experimental"
last_updated: "2026-03-18"
updated_by: "@staff-engineer"
scope: "Review dimensions, high-risk areas, common pitfalls, and priorities for code review"
owner: "@staff-engineer"
dependencies:
  - code-quality.md
  - security.md
  - testing.md
---

# Review Strategy

## Project Context

dotfiles.vorpal is a declarative dotfiles manager built on the Vorpal build system. It is a Rust
program that produces reproducible, content-addressed artifacts for CLI tools, configuration files,
and an AI agent team configuration. The project is maintained by a single developer with automated
dependency updates via Renovate.

The codebase is relatively small (~3,200 lines of Rust across 9 source files, plus ~1,200 lines
of agent/skill markdown). Changes are frequent -- 75+ commits from the primary author, 4 from
Renovate -- and concentrated in a few hot files.

## Review Dimensions by Priority

The review dimensions below are ordered by importance for this specific project. Not all dimensions
apply equally to every change.

### 1. Correctness (Highest Priority)

This project produces the author's live development environment. A bad build means broken CLI
tools, missing configurations, or a corrupted Claude Code setup. There is no staging environment
-- builds go directly to the host filesystem via symlinks into `/var/lib/vorpal/store/`.

**What to check:**
- Configuration output matches the expected format for each target tool (YAML for K9s, JSON for
  Claude Code and OpenCode, key-value for Ghostty, plain text for Bat).
- Symlink targets resolve correctly. The `get_output_path` function constructs store paths using
  namespace and content digest -- verify the path construction is consistent.
- Shell scripts embedded via `formatdoc!` or `include_str!` are syntactically valid. The
  `FileCreate` builder wraps content in a heredoc (`cat << 'EOF'`), so content with `EOF` on
  its own line would break the build script.
- Artifact dependency ordering is correct -- `UserEnvironment::build` constructs 16 CLI tool
  artifacts and 10+ configuration artifacts sequentially, all of which must succeed.

### 2. Security (High Priority)

The project generates a Claude Code `settings.json` that defines permissions, sandbox rules, and
deny lists controlling what AI agents can access on the host machine. This is the security boundary
for all agent-assisted development work.

**What to check:**
- Permission rule changes in `src/user.rs` (the `ClaudeCode` builder chain). This is the most
  security-sensitive code in the project. Every `with_permission_allow`, `with_permission_ask`,
  and `with_permission_deny` call defines the agent's capabilities.
- Deny rules must remain intact for sensitive paths: `~/.ssh`, `~/.gnupg`, `~/.aws`, `~/.kube`,
  `~/.doppler`, `~/.netrc`, `/Applications`, `/Library`, `/System`.
- Sandbox configuration changes (`with_sandbox_*` methods). The sandbox exclusion list
  (`excluded_commands`) currently allows `aws`, `docker`, `gh`, and `git` to bypass sandboxing.
- Agent markdown files in `agents/` define behavioral constraints. Changes that relax safety
  guards (e.g., removing the no-commit directive) have outsized impact.
- Environment variables in the Claude Code config include OTEL endpoints pointing to external
  infrastructure (`loki.bulbasaur.altf4.domains`, `mimir.bulbasaur.altf4.domains`). Changes to
  these endpoints affect where telemetry data is sent.

### 3. Operations (Medium Priority)

The build runs in CI (GitHub Actions on `macos-latest`) and locally. Failures are immediately
visible because the user cannot rebuild their environment.

**What to check:**
- CI workflow changes (`.github/workflows/vorpal.yaml`). The workflow uses S3-backed remote
  caching with AWS credentials from GitHub secrets.
- Changes to `Vorpal.toml` source includes -- the build only includes `src`, `Cargo.toml`, and
  `Cargo.lock`. Adding a new source directory requires updating this list.
- Lock file changes (`Cargo.lock`, `Vorpal.lock`). Cargo.lock has been touched by 19 commits.
  Vorpal.lock contains content-addressed digests for all external downloads -- verify digest
  integrity on any manual change.
- External URL changes in `src/user.rs` (e.g., the tokyonight.nvim theme URL). These are
  pinned to specific tags and tracked by Renovate's custom regex manager.

### 4. Code Quality (Medium Priority)

The codebase follows a consistent builder pattern across all configuration generators. Deviations
from this pattern increase cognitive load.

**What to check:**
- New configuration generators should follow the established pattern: struct with fields, `new()`
  constructor with sensible defaults, `with_*()` builder methods returning `Self`, and an
  `async fn build()` that delegates to `FileCreate`.
- The `FileCreate`, `FileDownload`, and `FileSource` abstractions in `src/file.rs` are the core
  building blocks. Changes here affect every configuration generator.
- Serde derive usage -- the project uses `#[serde(rename_all = "camelCase")]`,
  `#[serde(skip_serializing_if = "...")]`, and `#[serde(untagged)]` extensively. Incorrect
  serde attributes produce silently wrong JSON output.
- Builder method proliferation. `K9sSkin` has 44 builder methods for individual color fields,
  and `ClaudeCode` has 35+ builder methods. New configuration structs should consider whether
  this granularity is necessary or whether grouped configuration would be cleaner.

### 5. Performance (Low Priority)

Build performance is dominated by the Vorpal build system and external artifact downloads, not by
this project's code. The Rust code runs once at build time to produce configuration files.

**What to check:**
- Unnecessary sequential artifact builds. The `UserEnvironment::build` method builds all 16 CLI
  tools sequentially with `await`. If Vorpal supports parallel builds, this could be optimized,
  but is not a review concern for most changes.
- Large embedded content via `include_str!` or `formatdoc!` -- currently only `statusline.sh` is
  included via `include_str!`, which is fine.

### 6. Testing (Low Priority -- Gap)

**There are no tests in this project.** Zero `#[test]` or `#[cfg(test)]` annotations exist across
the entire source tree. This is the largest gap in the project's review strategy.

**Implication for review:**
- Every change must be reviewed more carefully for correctness because there is no automated
  safety net.
- Configuration format correctness must be verified manually or via the CI build.
- Reviewers should pay extra attention to edge cases in string formatting, especially in
  `formatdoc!` templates and serde serialization.

## High-Risk Areas

These areas of the codebase carry disproportionate risk and deserve extra scrutiny.

### Tier 1: Critical

| Area | File(s) | Risk | Why |
|------|---------|------|-----|
| Claude Code permissions | `src/user.rs` lines 88-257 | Security | Defines what AI agents can access on the host. 39 commits touch this file. |
| Claude Code config struct | `src/user/claude_code.rs` | Security | Serde serialization produces the live `settings.json`. Incorrect field names or serialization silently break the config. |
| File creation with shell scripts | `src/file.rs` | Correctness | `FileCreate::build` wraps content in a bash heredoc. Content injection is possible if content contains `EOF`. |
| Symlink mapping | `src/user.rs` lines 473-485 | Correctness | Incorrect symlink targets overwrite or break host filesystem paths including `~/.claude/settings.json`. |

### Tier 2: High

| Area | File(s) | Risk | Why |
|------|---------|------|-----|
| Agent definitions | `agents/*.md` | Behavioral | Agent instructions define the behavior of AI assistants. Relaxed constraints have cascading effects. 13 commits touch this directory. |
| OpenCode config | `src/user/opencode.rs` | Correctness | 2,207 lines. Largest file. Complex nested JSON serialization with many serde attributes. |
| External URLs | `src/user.rs` | Availability | Hardcoded URLs (e.g., GitHub raw content) break builds if the URL changes or the tag is deleted. |
| CI workflow | `.github/workflows/vorpal.yaml` | Operations | Uses secrets for AWS S3 cache. Misconfiguration breaks all CI builds. |

### Tier 3: Medium

| Area | File(s) | Risk | Why |
|------|---------|------|-----|
| Theme/skin configs | `src/user/ghostty.rs`, `src/user/k9s.rs`, `src/user/bat.rs` | Low | Incorrect color values produce cosmetic issues only. |
| Statusline script | `src/user/statusline.sh` | Low | Bash script with `set -euo pipefail`. Failures affect the Claude Code status bar display only. |

## Common Pitfalls

These are recurring patterns that have caused issues or are likely to cause issues.

1. **Permission syntax format changes.** The project has migrated permission syntax at least twice
   (space-delimited to colon-delimited). Ensure all permissions in a change use the current
   format: `Bash(command:*)`.

2. **Serde field naming mismatches.** The `ClaudeCode` struct uses `#[serde(rename_all = "camelCase")]`
   but the JSON schema expects specific field names. Adding a Rust field named `my_new_field`
   produces `myNewField` in JSON -- verify this matches the consumer's expectation.

3. **Missing deny rules when adding new tool integrations.** When a new tool with file access
   is added (e.g., a new MCP server or a new permission allow rule), corresponding deny rules
   for sensitive paths should be reviewed.

4. **Heredoc content injection in FileCreate.** The `FileCreate::build` method generates a bash
   script using `cat << 'EOF'`. If the `content` field contains a line consisting solely of
   `EOF`, the heredoc terminates early and the remaining content is interpreted as bash commands.

5. **Lock file drift.** Both `Cargo.lock` and `Vorpal.lock` should be committed together with
   their corresponding source changes. `Vorpal.lock` contains content-addressed digests -- if a
   URL changes but the digest is not updated, the build fails at download time.

6. **Agent markdown changes without corresponding skill updates.** The agent definitions in
   `agents/` are referenced by skills in `skills/`. Changes to agent roles or capabilities may
   require corresponding skill updates.

## Review Checklist by Change Type

### Adding a New CLI Tool

- [ ] New artifact builder call added to `UserEnvironment::build` in `src/user.rs`
- [ ] Artifact added to the `with_artifacts` vec
- [ ] If the tool needs configuration, a new config generator module exists under `src/user/`
- [ ] Config generator follows the builder pattern (struct, `new()`, `with_*()`, `build()`)
- [ ] Symlink mapping added to `with_symlinks` if the tool needs host filesystem access
- [ ] Vorpal.lock updated if the tool is downloaded from an external URL

### Modifying Claude Code Permissions

- [ ] No sensitive paths removed from deny lists
- [ ] New allow rules use the current `command:*` syntax
- [ ] Destructive operations remain in `ask` mode (git commit, git push, rm, chown)
- [ ] `git checkout` and `git reset` remain in deny
- [ ] Sandbox exclusion list reviewed if adding commands that need network or filesystem access

### Modifying Agent Definitions

- [ ] No-commit guard still present (agents should not commit without explicit instruction)
- [ ] Role boundaries still clear (staff-engineer does not write code, project-manager does not
  implement, etc.)
- [ ] Skill files in `skills/` updated if agent capabilities changed
- [ ] Changes do not introduce contradictions between agent instructions

### Updating Dependencies

- [ ] `Cargo.lock` changes match `Cargo.toml` version bumps
- [ ] For `vorpal-sdk` or `vorpal-artifacts` updates: check for breaking API changes in the
  builder methods and artifact types used
- [ ] Renovate auto-merge rules in `renovate.json` are appropriate for the update type
  (auto-merge for minor/patch of stable crates only)

### Modifying the CI Workflow

- [ ] AWS credential secret names unchanged unless intentionally rotating
- [ ] `setup-vorpal-action` version pinning reviewed
- [ ] Matrix strategy still includes all required artifact targets
- [ ] Build job dependency chain preserved (`build` depends on `build-dev`)

## Existing Review Infrastructure

### What Exists

- **CI gate:** GitHub Actions runs `vorpal build 'dev'` and `vorpal build 'user'` on every PR
  and push to main. This is the only automated validation.
- **Renovate:** Automated dependency updates with auto-merge for minor/patch updates of stable
  crates (version >= 1.0). Major updates and pre-1.0 crate updates require manual review.
- **Docket:** Issue tracking via `.docket/issues.db` (local SQLite). No PR-issue linking
  automation observed.

### What Does Not Exist

- **No PR template.** There is no `.github/PULL_REQUEST_TEMPLATE.md`.
- **No CONTRIBUTING guide.** There is no `CONTRIBUTING.md`.
- **No automated tests.** Zero unit, integration, or end-to-end tests.
- **No linting in CI.** `cargo clippy` and `cargo fmt --check` are not run in the CI workflow.
  Only `vorpal build` is executed.
- **No branch protection rules observed.** Single-developer workflow with direct pushes to main.
- **No CODEOWNERS file.** Not needed for a single-maintainer project but worth noting.

## Reviewer Allocation

Given the single-maintainer nature of this project and the AI agent team configuration:

- **@staff-engineer** reviews architectural changes, permission/security changes, and agent
  definition changes.
- **@senior-engineer** implements changes and performs self-review for routine additions (new
  tool configs, theme changes).
- **@sdet** should be engaged for any future test infrastructure work.

For the highest-risk changes (Claude Code permissions, symlink targets, agent constraints), the
staff-engineer review is non-negotiable regardless of change size.
