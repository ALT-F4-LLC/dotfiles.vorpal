---
project: "dotfiles.vorpal"
maturity: "experimental"
last_updated: "2026-03-21"
updated_by: "@staff-engineer"
scope: "Code and artifact review processes, quality gates, and approval workflows"
owner: "@staff-engineer"
dependencies:
  - architecture.md
  - code-quality.md
  - testing.md
  - security.md
---

# Review Strategy

This document describes the review processes, quality gates, and approval workflows that exist in
the dotfiles.vorpal project today. It covers CI-based automated checks, agent-driven code review,
consensus-based approval for architectural decisions, and dependency update review policies.

---

## 1. Review Dimensions

The project's review model operates across two distinct artifact types:

1. **Rust source code** (`src/`) -- The Vorpal build definitions, configuration generators, file
   utilities, and user environment assembly.
2. **Agent and skill definitions** (`agents/*.md`, `skills/*/SKILL.md`, `.claude/skills/*/SKILL.md`)
   -- Markdown-based behavioral specifications for the five-agent Claude Code team.

These artifact types have different risk profiles and require different review emphasis:

| Dimension | Rust Source | Agent/Skill Definitions |
|-----------|------------|------------------------|
| Architecture | Module boundaries, dependency graph, Vorpal SDK usage | Agent responsibility boundaries, delegation protocol, orchestration flow |
| Security | Permission configs, secret handling, symlink targets | Permission allow/deny lists, sandbox config, sensitive path exclusions |
| Operations | CI build stability, artifact reproducibility | Agent spawning patterns, consensus protocol reliability |
| Performance | Build time, artifact size | N/A (no runtime performance) |
| Code Quality | Builder pattern consistency, error handling | Instruction clarity, cross-agent coherence, redundancy |
| Testing | Build verification in CI | End-to-end `/dev` execution, `/vote` protocol validation |

---

## 2. Automated Quality Gates

### 2.1 CI Pipeline (GitHub Actions)

The project has a single CI workflow at `.github/workflows/vorpal.yaml` that runs on all pushes to
`main` and on all pull requests:

| Job | Trigger | What It Does |
|-----|---------|-------------|
| `build-dev` | push to main, PRs | Builds the `dev` artifact (Rust toolchain + Protoc) using `vorpal build 'dev'` on `macos-latest` |
| `build` | after `build-dev` succeeds | Builds the `user` artifact using `vorpal build 'user'` on `macos-latest` (matrix: `[user]`) |

**What the CI validates:**
- Rust compilation succeeds (the `vorpal build` command compiles `src/vorpal.rs` and all dependencies)
- All configuration generators produce valid output artifacts
- Agent and skill markdown files are included in the build (via `FileSource` from the `agents/` and `skills/` directories)
- Symlink targets resolve to valid artifact output paths

**What the CI does NOT validate:**
- No `cargo test` step -- there is no test suite for the Rust code
- No `cargo clippy` or `cargo fmt` -- no linting or formatting checks
- No markdown linting for agent/skill definitions
- No schema validation for configuration outputs (Claude Code settings JSON, OpenCode JSON, K9s YAML)
- No security scanning (no `cargo audit`, no dependency vulnerability checks)

**Gap:** The CI is purely a "does it build" check. There are no code quality, lint, format, test, or security gates. A PR that introduces a regression in configuration output will only be caught if it causes a build failure.

### 2.2 Dependency Update Automation (Renovate)

Renovate is configured (`renovate.json`) with these review policies:

| Update Type | Policy | Review Required |
|-------------|--------|----------------|
| Minor/patch on stable crates (version >= 1.0) | Auto-merge | No |
| Major updates on any crate | Manual review | Yes |
| Serde ecosystem (serde + serde_json) | Grouped as single PR | Per update type |
| Custom: tokyonight.nvim bat theme | Tracked via regex manager | Per update type |

**What this means for review:** Most dependency updates bypass human review entirely. Only major
version bumps require explicit approval. The auto-merge policy trusts semver compliance of stable
crates.

**Gap:** Pre-release dependencies (`vorpal-sdk = "0.1.0-alpha.0"`, `vorpal-artifacts` from git
branch) are not covered by the auto-merge rules. Breaking changes from these upstream dependencies
would only be caught by the `vorpal build` CI gate.

---

## 3. Agent-Driven Review Process

### 3.1 Review Roles

The five-agent team has structured review responsibilities:

| Reviewer | Reviews What | Scope |
|----------|-------------|-------|
| **@staff-engineer** | All @senior-engineer code changes; @project-manager plans (feasibility, ordering); @sdet test architecture; @ux-designer specs (technical feasibility) | Six-dimension review: architecture, security, operations, performance, code quality, testing |
| **@sdet** | Test adequacy, acceptance criteria verification, regression checking | Test coverage, bug detection, cross-issue integration |
| **Team Lead** (`/dev` orchestrator) | Phase plans from @project-manager (file collision, missing criteria, phase ordering) | Plan-level sanity check before execution |

@senior-engineer does NOT review. @project-manager does NOT review. @ux-designer does NOT review
code.

### 3.2 Review Workflow Within `/dev` Orchestration

The review phase is integrated into every orchestration pattern:

**Small tasks:**
```
@project-manager (plan) -> @senior-engineer (implement) -> @staff-engineer (review)
```

**Medium tasks:**
```
@staff-engineer (TDD) -> @project-manager (plan) -> @senior-engineer (implement)
  -> @staff-engineer (review) -> @sdet (verify)
```

**Large tasks:**
```
@staff-engineer(s) (TDDs) -> @project-manager (plan)
  -> [@senior-engineer (implement) + @staff-engineer (review)] x N phases
  -> @sdet (full verify)
```

Key workflow behaviors:
- The review is sent to the persistent "advisor" @staff-engineer via `SendMessage`, not a fresh
  agent spawn (for medium+ tasks where the advisor was already created for TDD).
- The reviewer receives `git diff --stat` output to focus on the right files.
- For large tasks (20+ files changed), additional @staff-engineer agents may be spawned for
  parallel file-group reviews.
- Review findings route back to @senior-engineer for fixes (the implementation agents remain alive).

### 3.3 Review Severity Levels

Feedback is structured by severity:

| Severity | Meaning | Action |
|----------|---------|--------|
| **Blocker** | Must fix before merge | Security vulnerabilities, data loss risk, breaking changes without migration, critical missing tests |
| **Concern** | Should fix or explicitly justify | |
| **Suggestion** | Consider for this or future work | |
| **Question** | Need clarification to complete review | |
| **Praise** | Good patterns worth highlighting | |

### 3.4 Review Output Formats

- **Trivial/small changes:** `LGTM - [one line summary]`
- **Needs clarification:** Questions first, then review after response
- **Medium/large changes:** Summary, Risk Assessment (blast radius, rollback complexity,
  confidence), Findings (Blockers / Concerns / Suggestions / What's Good), Checklist (backward
  compatibility, error handling, observability, tests, docs)

### 3.5 Review-Fix Loop

When blockers are found:
1. Route blocker details to @senior-engineer for fixes.
2. @staff-engineer re-reviews.
3. **2-cycle limit:** If the same blocker persists after 2 fix-review cycles, escalate to the
   user rather than continuing to loop.

The same 2-cycle limit applies to @sdet bug-fix-verify loops.

---

## 4. Consensus-Based Approval (PBFT `/vote` Protocol)

For high-stakes decisions, the project uses a PBFT-inspired voting protocol (`/vote` skill) that
spawns independent reviewer agents to evaluate proposals.

### 4.1 Mandatory Consensus Triggers

| Decision Type | Required | Criticality |
|---------------|----------|-------------|
| TDD approval (all TDDs) | **Always** -- hard requirement, no exceptions | High |
| UX design spec approval | **Always** | High |
| Security-sensitive review (auth, permissions, crypto) | **Always** | Critical |

### 4.2 Optional Consensus Triggers

| Decision Type | Trigger Condition | Criticality |
|---------------|-------------------|-------------|
| Code review | 500+ lines or Tier 1/2 risk areas | High/Medium |
| Plan with breaking changes | >30% scope change | Medium |
| Architectural advisory | Two viable approaches, need independent validation | Varies |
| Design review disagreement | Significant divergence between reviewer and proposer | Varies |

### 4.3 Vote Mechanics

- Reviewers are spawned as independent agents with no shared context.
- Each reviewer casts a verdict: approve, reject, approve-with-concerns, or abstain.
- Votes are weighted by confidence and domain relevance.
- Quorum is evaluated against a configurable threshold (default 0.75).
- Results are recorded in docket for auditability.

### 4.4 Delegation Protocol for Sub-Agent Voting

Sub-agents (e.g., @staff-engineer spawned by `/dev`) cannot spawn reviewer agents directly (they
lack `Agent`/`TeamCreate` tools). They use a delegation protocol documented in
`docs/tdd/agent-delegation-protocol.md`:

1. Sub-agent creates the vote proposal in docket via `docket vote create`.
2. Sub-agent sends a lightweight `delegation_request` (containing only the `vote_id`) to the Team
   Lead via `SendMessage`.
3. Team Lead reads the proposal from docket, spawns reviewers, casts votes, evaluates quorum.
4. Team Lead sends a `delegation_response` back to the sub-agent.
5. Sub-agent reads the full result from docket via `docket vote result`.

---

## 5. Review Scope by Risk Area

### 5.1 High-Risk Areas (All Six Dimensions)

These areas warrant full structured review:

- **Permission configuration** (`src/user/claude_code.rs`) -- The Claude Code settings builder
  defines allow/ask/deny permission lists, sandbox configuration, and network access controls.
  Changes here directly affect what the agent team can do on the host system. ~170 lines of
  permission rules.
- **Symlink targets** (`src/user.rs:473-485`) -- Symlinks write into sensitive locations
  (`~/.claude/settings.json`, `~/.claude/agents/`, `~/Library/Application Support/`). Incorrect
  paths could overwrite user data or break the host environment.
- **Agent behavioral specifications** (`agents/*.md`) -- Define the boundaries, permissions, and
  decision authority of each agent. Subtle changes can cause agents to exceed their intended scope.
- **Delegation protocol** (any changes touching `delegation_request`/`delegation_response`
  patterns) -- Protocol coherence across skill and agent files is critical.

### 5.2 Medium-Risk Areas

- **Configuration generators** (`src/user/bat.rs`, `src/user/ghostty.rs`, `src/user/k9s.rs`,
  `src/user/opencode.rs`) -- Builder patterns that produce tool-specific config files. Mistakes
  produce broken tool configs but are recoverable by rebuilding.
- **Skill orchestration** (`skills/dev/SKILL.md`) -- Changes to orchestration flow, spawning
  templates, or phase ordering affect the entire agent team workflow.
- **Vorpal SDK integration** (`src/vorpal.rs`, `src/lib.rs`) -- Build system entry point and
  artifact assembly. Changes affect the build pipeline.

### 5.3 Low-Risk Areas

- **Theme values** (color hex codes in K9s skin, Ghostty theme name) -- Cosmetic, no functional
  impact. Quick sanity check sufficient.
- **README updates** -- Documentation only. LGTM-level review.
- **Changelog files** (`docs/changelog/`) -- Historical records. No review needed for content
  accuracy (generated by evolve-* skills).

---

## 6. Cross-Team Review Notifications

The @staff-engineer review process includes structured cross-team communication:

| Finding | Notify | Via |
|---------|--------|-----|
| Test gaps or test architecture concerns | @sdet | SendMessage with specific gaps and risk level |
| UX inconsistencies with `docs/ux/` specs | @ux-designer | SendMessage |
| Scope changes not in the original plan | @project-manager | SendMessage |
| TDD revision after implementation started | @senior-engineer | SendMessage with specific changes |

---

## 7. What Does NOT Exist

The following review practices are absent from the project:

- **No PR template or checklist** -- No `.github/PULL_REQUEST_TEMPLATE.md` exists. PRs have no
  structured format.
- **No CODEOWNERS file** -- No automatic reviewer assignment based on file paths.
- **No CONTRIBUTING guide** -- No documented contribution process for external or new contributors.
- **No branch protection rules** (as visible from the repo) -- No required reviews, no required
  status checks configured at the GitHub level.
- **No pre-commit hooks** -- No local linting, formatting, or validation before commit.
- **No `cargo clippy` or `cargo fmt` in CI** -- No automated code style enforcement for Rust code.
- **No `cargo test` in CI** -- No test execution (no tests exist to run).
- **No `cargo audit` or dependency security scanning** -- No automated vulnerability detection.
- **No markdown linting** -- Agent/skill definitions are not validated for structural consistency.
- **No human review requirement** -- The CI pipeline does not enforce that a human (or specific
  agent) has approved before merge. Renovate auto-merges minor/patch dependency updates.

---

## 8. Review Strategy Maturity Assessment

| Aspect | Current State | Maturity |
|--------|--------------|----------|
| CI build verification | Present -- `vorpal build` on every PR | Stable |
| Automated code quality | Absent -- no clippy, fmt, test, audit | Gap |
| Agent-driven review | Well-defined in agent specs, six-dimension model | Experimental |
| Consensus protocol | Defined with `/vote` skill and delegation TDD | Experimental |
| Dependency review | Renovate with tiered auto-merge | Stable |
| PR templates / contribution guides | Absent | Gap |
| Branch protection | Not configured | Gap |
| Security scanning | Absent | Gap |

The project's review strategy is architecturally ambitious (multi-agent review with PBFT consensus)
but operationally immature (no automated quality gates beyond build success). The agent review
process is well-specified in markdown but has no enforcement mechanism at the CI or GitHub level --
it depends entirely on the `/dev` orchestrator being invoked for changes.
