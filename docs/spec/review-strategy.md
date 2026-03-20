---
project: "main"
maturity: "experimental"
last_updated: "2026-03-20"
updated_by: "@staff-engineer"
scope: "Code review strategy, quality gates, and review dimensions for the dotfiles.vorpal configuration project"
owner: "@staff-engineer"
dependencies:
  - code-quality.md
  - testing.md
  - security.md
---

# Review Strategy

## 1. Project Review Context

This repository (`dotfiles.vorpal`) is a Rust-based declarative dotfiles/environment management project built on the Vorpal SDK. It produces reproducible user environment artifacts — tool installations, configuration files, and symlinks — across four target systems (aarch64-darwin, aarch64-linux, x86_64-darwin, x86_64-linux).

The codebase is ~4,100 lines of Rust across 9 source files, with the bulk being builder-pattern configuration structs for tools like Claude Code, Ghostty, K9s, Bat, and Opencode. Changes tend to be additive (new tools, new config options) rather than refactors of core logic.

### Review Participants

- **@staff-engineer**: Designated reviewer for all @senior-engineer implementation changes. Owns architectural review, security review, and spec alignment.
- **@senior-engineer**: Primary implementer. Submits changes for review.
- **Multi-agent team**: The project uses a Claude Code agent team (`dev` skill) with @staff-engineer, @senior-engineer, @project-manager, @sdet, and @ux-designer roles.

## 2. CI/CD Quality Gates

### GitHub Actions Workflow (`.github/workflows/vorpal.yaml`)

The project has a single CI workflow with two sequential jobs:

1. **`build-dev`**: Runs on `macos-latest`. Checks out code, sets up Vorpal (nightly, S3 registry backend), and runs `vorpal build 'dev'`. Uploads `Vorpal.lock` as an artifact.
2. **`build`**: Depends on `build-dev`. Runs `vorpal build 'user'` via a matrix strategy (currently single-entry: `user`).

**Triggers**: Pull requests (all branches) and pushes to `main`.

**What CI covers**:
- Compilation of the Rust codebase via Vorpal's build system
- Artifact generation for the `dev` and `user` environments
- Lock file consistency (uploaded as artifact)

**What CI does NOT cover**:
- No `cargo clippy`, `cargo fmt`, or `cargo test` steps
- No linting or static analysis
- No unit or integration tests (none exist in the codebase)
- No PR template or required review configuration detected
- No branch protection rules visible from repository content

### Renovate (Automated Dependency Updates)

Renovate is configured (`renovate.json`) with:
- **Automerge**: Minor and patch updates for stable Cargo crates (version >= 1.0)
- **Manual review required**: Major Cargo crate updates
- **Grouped updates**: `serde` + `serde_json` are grouped together
- **Custom manager**: Tracks `tokyonight.nvim` bat theme version from raw GitHub URLs in `src/user.rs`

## 3. Review Dimensions — Prioritized for This Project

### Tier 1: High Priority (Always Review)

#### Configuration Correctness
The primary risk surface. Most changes add or modify declarative configuration for developer tools. Review must verify:
- Builder pattern calls produce valid configuration output (JSON, TOML, YAML, plain text)
- Symlink targets are correct and won't overwrite unrelated user files
- Environment variable values are syntactically valid and don't introduce path conflicts
- File permissions (644 vs 755) are appropriate for the artifact type

#### Security — Permissions & Sandbox Configuration
The Claude Code configuration (`src/user/claude_code.rs`, `src/user.rs`) defines a detailed permission model with allow/ask/deny rules and sandbox settings. Changes here have outsized impact:
- New `with_permission_allow` entries expand what automated agents can do
- Deny rules protect sensitive paths (~/.ssh, ~/.gnupg, ~/.aws, etc.)
- Sandbox exclusions (`excluded_commands`) bypass filesystem sandboxing
- Any change to permission or sandbox configuration should be treated as security-sensitive

#### Cross-Platform Consistency
Artifacts target 4 systems. Review must check:
- New tools/configs use `self.systems.clone()` (all platforms) or explicitly justify platform-specific targeting
- Shell scripts in `FileCreate` use portable constructs (`set -euo pipefail`, POSIX where possible)
- File paths use the correct format for the target OS

### Tier 2: Medium Priority (Review When Changed)

#### Dependency Management
- New `vorpal_artifacts` or `vorpal_sdk` API usage should be verified against upstream documentation
- New external artifact dependencies (tools like `awscli2`, `kubectl`, etc.) add supply chain surface area
- Git-branch dependencies (`vorpal-artifacts` depends on `branch = "main"`) are inherently unstable

#### Builder Pattern API Design
The codebase follows a consistent builder pattern (`::new()`, `.with_*()`, `.build()`). Review should verify:
- New builders follow the established pattern
- `#[allow(dead_code)]` is used for builder methods that exist for completeness but aren't yet called
- `serde` skip attributes (`skip_serializing_if`) are correctly applied
- New fields default to `None`/empty in `::new()`

#### Artifact Composition
`UserEnvironment::build()` in `src/user.rs` is the critical orchestration point. Review changes here for:
- Correct ordering of artifact builds (dependencies before dependents)
- Proper wiring of output paths into symlinks
- No duplicate artifact names

### Tier 3: Low Priority (Quick Check)

#### Cosmetic / Theme Configuration
Color values, font settings, theme names — low risk, quick visual check for typos.

#### Documentation & Agent Definitions
Changes to `agents/*.md` and `skills/*/SKILL.md` are reviewed for coherence with the team model but are lower-risk than code changes.

## 4. Review Process

### Current State

There is **no formal review process enforced by tooling**. The repository has:
- No PR template
- No `CODEOWNERS` file
- No required reviewers configured (not visible from repo content)
- No `CONTRIBUTING.md` or review guidelines
- No pre-commit hooks

The multi-agent team model designates @staff-engineer as the reviewer, but this is enforced by agent definitions, not by GitHub branch protection.

### Recommended Review Flow

For changes submitted by @senior-engineer (or any contributor):

1. **CI must pass** — `vorpal build` for both `dev` and `user` artifacts succeeds
2. **@staff-engineer reviews** using the tiered dimension system above
3. **Approval criteria**:
   - **Approve**: CI passes, no Tier 1 concerns, Tier 2 concerns are minor
   - **Request changes**: Any Tier 1 issue, or Tier 2 issues that could cause runtime failures
   - **Quick LGTM**: Pure Tier 3 changes (theme tweaks, doc updates) with passing CI

### Review Sizing Heuristic

| Change Size | Files | Approach |
|---|---|---|
| Small | 1-2 files, < 50 lines | Quick check, focus on correctness |
| Medium | 3-5 files, 50-200 lines | Full Tier 1 + Tier 2 review |
| Large | 5+ files or 200+ lines | Request split if logically separable; structured review |

## 5. Risk Areas Requiring Extra Scrutiny

### `src/user.rs` — Environment Orchestration
This file is the highest-risk single file. It wires together all tool artifacts, configuration files, environment variables, and symlinks. A mistake here can break the entire user environment setup. Changes should be reviewed with particular attention to:
- Symlink source/target correctness
- Environment variable `PATH` construction (easy to break existing tools)
- Artifact dependency ordering

### `src/user/claude_code.rs` — Agent Security Boundary
The Claude Code settings struct defines the security boundary for AI agent operations. The permission model (allow/ask/deny) and sandbox configuration directly control what agents can access. This file should receive the same scrutiny as an IAM policy change.

### `src/user/opencode.rs` — Largest Source File
At 2,207 lines, this is the largest file and most likely to accumulate complexity. Review for:
- Builder method sprawl
- Serialization correctness for the complex nested JSON schema
- Permission model consistency with the Claude Code config

### `src/file.rs` — Shell Script Injection Surface
`FileCreate`, `FileDownload`, and `FileSource` construct shell scripts from string interpolation. While currently all inputs are compile-time constants, any future dynamic input would be an injection risk. Review new uses of these types for input provenance.

## 6. Gaps & Improvement Opportunities

| Gap | Impact | Recommendation |
|---|---|---|
| No automated linting in CI | Style drift, potential bugs | Add `cargo fmt --check` and `cargo clippy` to workflow |
| No tests | Zero automated correctness verification beyond "it compiles" | Add unit tests for builder output serialization |
| No PR template | Inconsistent PR descriptions | Add `.github/pull_request_template.md` |
| No branch protection | Direct pushes to `main` possible | Enable required reviews and status checks |
| No CODEOWNERS | No automated reviewer assignment | Add `CODEOWNERS` mapping `src/user/claude_code.rs` and permission changes to security-aware reviewers |
| Git-branch dependency | `vorpal-artifacts` on `branch = "main"` is fragile | Pin to a specific release or tag when available |
| No `cargo audit` | Dependency vulnerabilities not checked | Add `cargo audit` to CI or Renovate vulnerability alerts |

## 7. Renovate Review Delegation

Renovate handles routine dependency updates with the following review expectations:

- **Automerged (no human review)**: Minor/patch updates of stable crates. Acceptable given CI build verification.
- **Requires review**: Major crate updates. Reviewer should check for breaking API changes and update usage accordingly.
- **Custom tracked**: `tokyonight.nvim` theme — cosmetic, low risk, quick approve unless the theme format changes.
