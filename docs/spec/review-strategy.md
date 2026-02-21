# Review Strategy

This document describes the code review strategy for the `dotfiles.vorpal` project based on what
actually exists in the codebase. It identifies areas of high risk, the review dimensions that
matter most, common pitfalls, and the review workflow in use.

---

## Project Context

This is a Rust-based dotfiles management project built on the Vorpal SDK. It generates
configuration artifacts for developer tools (Claude Code, Ghostty, k9s, bat, opencode) and
provisions a complete user environment with CLI tools and symlinked configs. The project also
contains an AI agent team system (agents/, skills/) that defines roles and workflows for
Claude Code agent teams.

**Key characteristics that shape review strategy:**

- Single contributor (Erik Reinert) with automated dependency updates via Renovate
- No existing test suite -- zero unit, integration, or end-to-end tests
- No PR templates, CODEOWNERS, or CONTRIBUTING guidelines
- No linter configuration (no clippy config, no rustfmt.toml)
- CI runs `vorpal build` only -- no test, lint, or format checks in CI
- Two distinct content domains: Rust source code and Markdown agent/skill definitions
- Configuration-heavy codebase -- most Rust code is builder patterns that generate config files

---

## Review Dimensions by Priority

For this specific project, review dimensions are ordered by relevance:

### 1. Security (HIGH priority)

This is the highest-risk dimension because the project directly manages:

- **Claude Code permissions** (`src/user/claude_code.rs`): The allow/deny permission lists
  control what an AI agent can execute on the developer's machine. An overly permissive rule
  (e.g., `Bash(rm:*)`) or a missing deny rule for sensitive paths could have severe consequences.
- **Secret exposure paths**: Deny rules for `.env*`, `.key`, `.pem`, and `.secrets/` files
  protect credentials. Any change to these rules requires careful review.
- **Environment variable injection**: OTEL endpoints, PATH modifications, and tool configurations
  are embedded in the Rust source. Malicious or incorrect values propagate to the user environment.
- **Shell script generation**: `FileCreate` embeds content into bash heredocs. Changes to
  `src/file.rs` must be reviewed for injection risks via the `content` parameter flowing into
  `cat << 'EOF'` blocks.
- **External URL references**: The bat theme is downloaded from a raw GitHub URL with a pinned
  version tag. Changes to download URLs must be verified for supply chain safety.

**Review checklist for security-sensitive changes:**
- Verify no new `Bash(*)` wildcard permissions are introduced without justification
- Confirm deny rules still cover `.env*`, `*.key`, `*.pem`, `.secrets/`
- Check that external URLs point to pinned versions, not branches
- Inspect shell script content for injection vectors
- Verify OTEL/telemetry endpoints point to expected infrastructure

### 2. Correctness (HIGH priority)

Configuration generation errors are silent and only surface when the user tries to use the
generated config. There is no test suite to catch regressions.

**High-risk areas for correctness:**
- **Serialization logic** in `src/user/claude_code.rs` and `src/user/opencode.rs`: These structs
  use `serde` with `rename_all`, `skip_serializing_if`, and `untagged` variants. Incorrect serde
  attributes produce invalid JSON that Claude Code or opencode will reject or silently ignore.
- **YAML generation** in `src/user/k9s.rs`: The k9s skin uses `formatdoc!` string interpolation
  for YAML, not a YAML serialization library. Indentation errors or quoting issues produce
  invalid YAML that k9s will fail to parse.
- **Symlink paths** in `src/user.rs` (lines 388-399): Incorrect source or target paths in
  `with_symlinks` cause the user environment to silently miss configurations. Escaped spaces in
  paths (e.g., `VMware\\ Fusion`) are easy to break.
- **Agent markdown frontmatter** in `agents/*.md`: The YAML frontmatter (`name`, `description`,
  `permissionMode`, `tools`, `skills`) must conform to Claude Code's agent schema. Invalid
  frontmatter silently disables agents.

**Review checklist for correctness:**
- For serde changes: verify JSON output matches the target tool's expected schema
- For `formatdoc!` changes: verify generated output is valid YAML/TOML/config syntax
- For symlink changes: verify both source artifact path and target home directory path
- For agent changes: verify frontmatter fields match Claude Code agent schema

### 3. Architecture (MEDIUM priority)

The codebase follows a consistent builder pattern with clear module boundaries. Architectural
review matters when:

- **New tool configurations are added**: Each tool follows the pattern of a struct with builder
  methods and a `build()` method that calls `FileCreate`. Deviations from this pattern should be
  flagged.
- **The Vorpal SDK API changes**: Dependencies on `vorpal-sdk` and `vorpal-artifacts` are
  git-pinned to `branch = "main"`. SDK API changes can break the build without version bumps.
  Review dependency updates carefully.
- **Agent/skill definitions change**: The agent team architecture (team lead, staff-engineer,
  project-manager, senior-engineer, qa-engineer, ux-designer) has specific role boundaries.
  Changes that blur these boundaries (e.g., giving senior-engineer the ability to create Docket
  issues) undermine the system design.

### 4. Operations (MEDIUM priority)

- **CI workflow** (`.github/workflows/vorpal.yaml`): Changes to the build pipeline, Vorpal
  setup action, or S3 registry configuration affect whether builds succeed. The workflow uses
  AWS credentials from secrets.
- **Renovate configuration** (`renovate.json`): Custom managers track the tokyonight.nvim theme
  version. Automerge rules allow minor/patch Cargo updates for stable crates (version >= 1.0).
  Changes to these rules affect the automated dependency update flow.

### 5. Code Quality (LOW priority)

- The codebase has a high volume of `#[allow(dead_code)]` annotations across builder methods in
  `src/user/claude_code.rs`. This is acceptable -- builder methods are part of the public API
  surface even if not all are currently called.
- Heavy use of `String` and `Vec<String>` for domain values (color codes, permission strings,
  paths) is a pragmatic choice for a configuration generation project. Don't flag this as
  primitive obsession -- the values are passed through to config files, not used for logic.
- The k9s skin builder (`src/user/k9s.rs`, ~590 lines) is the largest file by method count.
  This is inherent to the k9s skin schema, not a code quality issue.

### 6. Performance (NEGLIGIBLE priority)

This is a build-time configuration generator. It runs once to produce artifacts, not in a hot
path. Performance review is not relevant unless someone introduces blocking I/O in an
inappropriate context or the async build pipeline changes fundamentally.

---

## Areas of High Risk

### Tier 1: Changes Require Thorough Review

| Area | Files | Risk |
|---|---|---|
| Claude Code permissions | `src/user/claude_code.rs`, `src/user.rs` | Controls what AI agents can execute on the host machine |
| Shell script generation | `src/file.rs`, `src/user/statusline.sh` | Content embedded in heredocs; injection risk |
| Agent role boundaries | `agents/*.md` | Incorrect permissions or tool grants undermine team safety model |
| Skill orchestration | `skills/dev-team/SKILL.md` | Incorrect workflow ordering can cause agents to conflict |

### Tier 2: Changes Require Standard Review

| Area | Files | Risk |
|---|---|---|
| User environment composition | `src/user.rs` | Symlink targets, artifact wiring, PATH ordering |
| Serde-based config generation | `src/user/claude_code.rs`, `src/user/opencode.rs` | Silent serialization errors |
| YAML template generation | `src/user/k9s.rs` | Indentation/quoting errors in `formatdoc!` |
| CI pipeline | `.github/workflows/vorpal.yaml` | Build breakage, secret exposure |
| Dependency management | `Cargo.toml`, `renovate.json` | Git-pinned deps, automerge rules |

### Tier 3: Changes Can Be Reviewed Quickly

| Area | Files | Risk |
|---|---|---|
| Color/theme values | `src/user/k9s.rs`, `src/user/ghostty.rs` | Cosmetic; low impact |
| New builder methods (unused) | Any `src/user/*.rs` | API surface expansion; no runtime effect |
| Agent prose/instructions | `agents/*.md` (non-frontmatter) | Behavioral guidance; no schema impact |
| Documentation | `README.md`, `docs/**` | No runtime impact |

---

## Most Frequently Changed Files

Based on git history (62 total commits):

| File | Changes | Review Implication |
|---|---|---|
| `src/user.rs` | 34 | Primary integration point; most changes land here. Review symlinks and artifact wiring carefully. |
| `Cargo.lock` | 17 | Automated dependency updates. Verify no unexpected transitive changes. |
| `agents/staff-engineer.md` | 9 | Agent role definition under active iteration. Review role boundary changes. |
| `agents/project-manager.md` | 9 | Agent role definition under active iteration. Review role boundary changes. |
| `.github/workflows/vorpal.yaml` | 9 | CI pipeline. Review for secret handling and build logic. |
| `src/user/claude_code.rs` | 7 | Permission model. Security-sensitive -- thorough review always. |
| `src/user/statusline.sh` | 7 | Shell script. Review for correctness and injection safety. |
| `Cargo.toml` | 7 | Dependency changes. Check for git-pinned branch changes. |

---

## Review Workflow

### Current State

There is no formal review process in the codebase. No PR templates, CODEOWNERS, branch
protection rules, or contribution guidelines exist. The project has a single contributor.

### Agent-Based Review

The project defines an agent-based review workflow through the `@staff-engineer` agent role
and the `dev-team` skill:

1. **@staff-engineer is the designated reviewer** for all `@senior-engineer` implementation
   changes.
2. **Review uses six dimensions**: architecture, security, operations, performance, code quality,
   and testing -- weighted by relevance to the change.
3. **Feedback is structured by severity**: blocker, concern, suggestion, question, praise.
4. **Review output format** is defined in the staff-engineer agent instructions with templates
   for trivial, small, and medium/large changes.

This agent-based review is the primary review mechanism for the project. It is triggered as
part of the dev-team orchestration workflow (plan -> implement -> review -> test).

### Recommended Review Focus by Change Type

| Change Type | Primary Dimensions | Depth |
|---|---|---|
| Permission changes (allow/deny rules) | Security | Thorough -- verify every rule |
| New tool configuration module | Architecture, Correctness | Standard -- verify pattern conformance and output validity |
| Agent/skill definition changes | Architecture | Standard -- verify role boundaries and workflow ordering |
| Dependency updates (Cargo) | Security, Operations | Quick for minor/patch; thorough for major or git-pinned |
| Renovate config changes | Operations | Standard -- verify automerge rules are safe |
| CI workflow changes | Operations, Security | Standard -- verify secret handling |
| Color/theme changes | Correctness | Quick -- verify values are valid hex/named colors |
| Shell script changes | Security, Correctness | Thorough -- verify no injection vectors |

---

## Common Pitfalls

These are recurring patterns that reviewers should watch for:

1. **Silent config breakage**: Because there are no tests, configuration changes are only
   validated when the Vorpal build runs or the user loads the config. Reviewers must mentally
   trace the generated output.

2. **Serde rename mismatches**: The `ClaudeCode` struct uses `#[serde(rename_all = "camelCase")]`
   while the `Opencode` struct uses different conventions. Adding fields to either requires
   verifying the rename matches the target tool's expected JSON schema.

3. **Git-pinned dependency drift**: Both `vorpal-sdk` and `vorpal-artifacts` are pinned to
   `branch = "main"` in `Cargo.toml`. The `Cargo.lock` pins the actual revision, but upstream
   breaking changes on main can surface unexpectedly. Reviewers should be aware that `cargo
   update` may pull breaking changes.

4. **Heredoc content injection**: `FileCreate` uses `cat << 'EOF'` (single-quoted delimiter,
   which prevents variable expansion). However, the content itself could contain `EOF` on a
   line by itself, which would prematurely terminate the heredoc. This is unlikely but worth
   noting for reviewer awareness.

5. **Agent frontmatter schema changes**: Claude Code's agent schema may evolve. If new fields
   are added to frontmatter or existing fields change meaning, all agent definitions need
   coordinated updates.

6. **Permission rule ordering**: Claude Code evaluates permission rules in order (allow > deny
   or vice versa depending on version). Reviewers should verify that deny rules are not
   accidentally overridden by broader allow rules.

---

## Gaps

The following review infrastructure does not exist and represents gaps:

- **No automated linting in CI**: `cargo clippy` and `cargo fmt --check` are not run in the
  GitHub Actions workflow. Code style issues are caught only by human review.
- **No test suite**: Zero tests means zero regression detection. Every change must be reviewed
  with the assumption that there is no safety net.
- **No PR template**: Contributors (or agents) have no structured prompt for describing changes,
  testing performed, or risk assessment.
- **No CODEOWNERS**: No automatic reviewer assignment. The agent workflow handles this through
  the `@staff-engineer` role, but GitHub-native CODEOWNERS is absent.
- **No branch protection**: No evidence of required reviews or status checks before merge.
- **No schema validation for generated configs**: The project generates JSON (Claude Code,
  opencode) and YAML (k9s) configs but does not validate them against their target schemas.
  A schema validation step in CI or build would catch configuration errors automatically.
