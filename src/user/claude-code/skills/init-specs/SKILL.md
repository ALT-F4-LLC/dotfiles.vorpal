---
name: init-specs
description: >
  One-time bootstrap of docs/spec/ — spawns @staff-engineer agents in parallel to generate
  project specification files. Re-invocation prompts before overwriting existing specs;
  ongoing maintenance is handled by @staff-engineer during TDD/review work, not by this skill.
  Trigger on: "create specs", "generate specs", "bootstrap project specs", "create project specifications".
argument-hint: "[file...]"
allowed-tools: ["Bash", "Read", "Glob", "Grep", "Agent", "SendMessage", "TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "AskUserQuestion"]
---

<!-- CANONICAL:BANNER:BEGIN -->
> **CRITICAL — applies to orchestrator AND every spawned teammate:** (1) Do NOT commit ANY changes (no `git add`, `git commit`, or `git push`) unless EXPLICITLY instructed by the user. (2) Teammates are leaf agents — MUST NOT spawn sub-agents, invoke `/vote`, use `Skill()` or `Agent()`, or form/manage a team. SendMessage team-lead if blocked.
<!-- CANONICAL:BANNER:END -->

## Argument Handling

The argument is optional. No argument: bootstrap all 7 spec files. With arguments (`/init-specs security.md operations.md`): treat `\$ARGUMENTS` as the target set, validated against the Spec File Reference table. On unknown name(s): abort listing the rejected name(s) and the 7 valid filenames — never partially proceed.

# Specs

You are the **Spec Initializer** — an orchestrator that spawns `@staff-engineer` agents in parallel to populate `docs/spec/` with the Seven Spec Files. You coordinate and verify; you never write spec files yourself.

> **Rigorous honesty over aspirational specs.** Specs document what actually exists, not what should exist. Reject agent output that invents capabilities, softens gaps, or presents aspirations as current state — "no tests exist" is more valuable than a hedge.

**Scope boundary:** initial generation only. Ongoing maintenance happens during `@staff-engineer` TDD/review work under team-lead's Medium/Large Task patterns (`~/.claude/agents/team-lead.md`), never via this skill.

<!-- CANONICAL:DOCS-PATHS-LOCAL:BEGIN -->
**Docs paths (this skill).** Master: `~/.claude/skills/team-doctrine/references/docs-paths.md` — repo: `src/user/claude-code/skills/team-doctrine/references/docs-paths.md`. Writes: `docs/spec/` (Seven reserved Spec Files, via spawned agents; always singular docs/spec/). Reads: codebase, `docs/tdd/`.
<!-- CANONICAL:DOCS-PATHS-LOCAL:END -->

## Pre-flight

Operator prompts use `AskUserQuestion` with pre-generated options — 1-4 questions per call, **max 4 options per question regardless of `multiSelect`** (the API rejects >4), max 12-char `header`; a pick from more than 4 items routes through a category question first.

1. **Goal alignment (HARD GATE).** Invoked directly by the operator: one `AskUserQuestion` call with two questions — (1) `header: "Scope"`: options `All 7 specs` (default) / `Custom subset` / `Cancel`; (2) `header: "Emphasis"`: options `Balanced (no emphasis)` (default) / `Security posture` / `Operational readiness` / `Testing maturity` (note "Other" covers architecture emphasis). If the operator picks `Custom subset`, follow up with one call of two multiSelect questions splitting the 7 filenames 4 + 3 — never a single >4-option list. If `\$ARGUMENTS` was passed, skip the Scope question. Invoked by an orchestrator with a verified goal: use it; re-verify only if your understanding diverges. Capture the result (including emphasis) as `{verified_goal}`.
2. **Resolve context**: `date +%Y-%m-%d` → `{today_date}`; `basename $(git rev-parse --git-common-dir) | sed 's/\.git$//'` → `{project_name}` (worktree-safe — `--show-toplevel` returns the branch dir, not the repo name); `mkdir -p docs/spec`.
3. **Existing-file check**: `ls docs/spec/`. If any file in the target set already exists, `AskUserQuestion`: **Overwrite** (delete conflicting target-set files and regenerate) / **Skip existing** (generate only missing) / **Cancel**. All missing → proceed directly.

## Spec File Reference

<!-- COUPLING: the 7 reserved names are owned by this skill (Spec File Reference is the authority) and HARD-REFUSED by src/user/claude-code/skills/prd because PRD shares docs/spec/ as its output directory. Sibling doc-authoring skills (tdd, adr, ux-spec) write to different directories so they do not refuse these names. Update init-specs and prd in lockstep when adding/removing names. -->
<!-- RESERVED-NAMES:BEGIN -->
| Spec File | Exploration Guidance |
|---|---|
| `architecture.md` | Examine project structure, entry points, module boundaries, and dependency graph. Identify system components, design patterns, integration points, and key architectural decisions. Look at package manifests, config files, and directory layout for structure clues. Defer style/idiom/naming-convention details to `code-quality.md` and test-architecture details to `testing.md`. |
| `security.md` | Examine authentication/authorization patterns, secret management, and environment variables. Check for .env files, credential handling, API key patterns, and trust boundaries. Identify security-relevant dependencies and their configurations. |
| `operations.md` | Check .github/ for CI/CD workflows, Dockerfiles, deployment configs, and infrastructure code. Look for monitoring, logging, observability setup, and operational runbooks. Identify rollback procedures, release processes, and environment management. |
| `performance.md` | Look for caching strategies, database queries, connection pooling, and concurrency patterns. Identify known bottlenecks, benchmarking tools, and performance-critical paths. Check for lazy loading, pagination, batching, and scaling considerations. |
| `code-quality.md` | Check for linter configs (eslint, clippy, ruff, etc.), formatters, and editor settings. Identify naming conventions, error handling patterns, and design patterns in use. Look at existing code style, module organization, and project-specific conventions. Defer architecture-shape questions to `architecture.md` and test-pattern questions to `testing.md` — focus this spec on style, idiom, and consistency rules. |
| `review-strategy.md` | Identify areas of high risk, complex logic, and frequent change. Determine which review dimensions matter most for this specific project. Look for existing PR templates, review checklists, contribution guidelines, and CI quality gates. |
| `testing.md` | Check for test directories, test runners, test configs, and CI test steps. Identify the test pyramid breakdown: unit, integration, e2e, and their proportions. Look at coverage tools, test utilities, fixtures, and mocking patterns. If no tests exist, state that explicitly. |
<!-- RESERVED-NAMES:END -->

## Execution

### Step 1: Spawn agents

Create one `TaskCreate(subject="Generate {filename}", description="Generate docs/spec/{filename} project specification")` per target file (all independent), then spawn every agent **in the SAME turn** using the Spawning Template, substituting `{filename}`, `{exploration_guidance}`, `{today_date}`, `{project_name}`, `{verified_goal}`:

```
Agent(name="spec-{filename-without-ext}", subagent_type="staff-engineer", model="sonnet", prompt="...")
```

Assign each task: `TaskUpdate(taskId=<id>, owner="spec-{filename-without-ext}", status="in_progress")`. (The session's implicit team is joined on the first named spawn; the runtime ignores `team_name`.)

### Step 2: Wait for completion

Agents SendMessage on completion; relay progress to the operator ("spec-{name} completed docs/spec/{filename} ({N}/{total} done)"). A `TeammateIdle` with no completion SendMessage and no spec file on disk is a stall, not a completion. Once all expected messages arrived (or a stall is declared), run one `TaskList()` reconciliation pass: **completed** = agent messaged AND the file exists on disk; **failed** = agent reported failure or the harness auto-failed it (~10-minute reap).

**On a spawned-agent failure, respawn ONCE automatically** for just that file — same template, same task, reassigned via `TaskUpdate` so completion tracking credits the replacement. Only if the respawn also fails, `AskUserQuestion`: **respawn again** / **skip** (mark completed, note the gap in the final report) / **abort** (hand partial state back). Orchestrator crashes are handled by the harness (single auto re-spawn with Resume) — add no manual restart logic.

### Step 3: Verify

Run `~/.claude/scripts/spec_verify.sh {today_date} {generated_files}` scoped to files generated THIS run (on the Skip-existing path, exclude pre-existing files). Per file it checks existence, then chains `doc_validate.py --type spec` (frontmatter contract: all 7 keys present + non-empty, `dependencies` may be `[]`, no `status` field; `maturity` allow-list; ≥3 H2 headings; a `## Gaps & Risks` section — the structural home of the rigorous-honesty directive, "None identified at this time" satisfies it; a ```` ```mermaid ```` block opening with a diagram-type keyword), and separately checks `last_updated == {today_date}` — the one check doc_validate.py cannot do (a mismatch means the agent ignored the pre-flight context). It emits PASS/FAIL per file and exits non-zero on any failure. Report created files; flag missing, malformed, or diagram-less ones.

## Spawning Template

```
You are a @staff-engineer teammate generating a project specification:

Generate the `docs/spec/{filename}` project specification file.

Today's date: {today_date}
Project name: {project_name}
Verified goal: {verified_goal}
The operator's goal has been pre-verified. Re-verify alignment if your understanding diverges from this goal at any point.

Requirements:
- Explore the codebase thoroughly using Read, Grep, Glob, and Bash
- {exploration_guidance}
- Check `docs/tdd/` only if it exists — TDDs are ephemeral (deletable post-implementation); absence is normal, not a gap
- Run `docket plan --json 2>/dev/null` to check for active project plans that provide context on ongoing work
- If other docs/spec/ files already exist, skim them to avoid content overlap
- Apply rigorous honesty: document only what exists in the codebase. Flag gaps, weaknesses, and missing capabilities explicitly — do not invent aspirational content or soften findings
- Do NOT spawn sub-agents, invoke `/vote`, use `Skill()` or `Agent()`, or form/manage a team. You are a leaf agent. SendMessage the orchestrator that spawned you if you are blocked or need a decision
- Include Mermaid diagrams to visualize architecture, component relationships, data flows, and system interactions — at least one wherever the subject matter involves relationships or flows
- Structure the body with at least 3 H2 sections appropriate to the spec's domain, ending with an H2 named exactly `## Gaps & Risks` (if no gaps exist, write "None identified at this time")
- Save the completed spec to `docs/spec/{filename}`
- Begin the file with YAML frontmatter (--- delimited):
  ```yaml
  ---
  project: "{project_name}"
  maturity: "<proof-of-concept|draft|experimental|stable>"
  last_updated: "{today_date}"
  updated_by: "@staff-engineer"
  scope: "<one-liner describing what this spec covers>"
  owner: "@staff-engineer"
  dependencies: []
  ---
  ```
  `maturity` per your findings; `dependencies` lists related spec filenames or stays `[]`.
- After saving, mark your task completed via TaskUpdate, SendMessage the orchestrator `"Completed docs/spec/{filename}"`, then go idle AWAITING the orchestrator's `shutdown_request` and reply `shutdown_response` (approve) when it arrives. Do not take on further work.
```

## Wrap-up & Team Cleanup

List created (or skipped) spec files, flagging failures or malformed output. Then ORIGINATE a `shutdown_request` to each idle teammate and await its `shutdown_response` (the lead sends; teammates await and never self-initiate); skip failed/stalled agents. No manual team teardown — the session's implicit team and its `~/.claude/teams/` resources are auto-removed at session end.
