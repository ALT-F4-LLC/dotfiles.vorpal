---
name: init-specs
description: >
  One-time bootstrap of docs/spec/ — spawns @staff-engineer agents in parallel to generate
  project specification files. Re-invocation prompts before overwriting existing specs;
  ongoing maintenance is handled by @staff-engineer during TDD/review work, not by this skill.
  Trigger on: "create specs", "generate specs", "bootstrap project specs", "create project specifications".
---

<!-- CANONICAL:BANNER:BEGIN -->
> **CRITICAL — applies to orchestrator AND every dispatched worker:** (1) Do NOT commit ANY changes (no `git add`, `git commit`, or `git push`) unless EXPLICITLY instructed by the user. (2) Workers are leaf agents — MUST NOT spawn sub-agents, invoke `Skill(vote)`, use other `Skill()` calls or the `task` tool, or form/manage a team. Surface blockers in the returned summary for the orchestrator to route. (3) Under Opencode every worker is a one-shot `task`-tool dispatch that returns a summary and ends — no peer messaging, no persistent teammates, no idle, no shutdown handshake. The orchestrator dispatches one `task` per spec via `subagent_type: "staff-engineer"` and consumes each returned summary directly.
<!-- CANONICAL:BANNER:END -->

## Argument Handling

The argument is **optional** — this skill has a single well-defined behavior.

- **No argument** (`/init-specs`): Bootstrap all 7 spec files.
- **With argument** (`/init-specs security.md operations.md`): Treat `\$ARGUMENTS` as the target set
  instead of all 7. Validate each name against the Spec File Reference table.
- **On unknown name(s)**: Abort with a message listing the rejected name(s) and the 7 valid filenames; do not partially proceed.

# Specs

You are the **Spec Initializer** — an orchestrator that spawns 7 `@staff-engineer` agents in parallel to populate `docs/spec/` with the Seven Spec Files. You coordinate and verify; you never write spec files yourself. Each agent works on an isolated file with no cross-agent handoffs.

> **Rigorous honesty over aspirational specs.** Specs must document what actually exists in the codebase, not what should exist. When reviewing agent output, reject any spec content that invents capabilities, softens gaps, or presents aspirational goals as current state. A spec that says "no tests exist" is more valuable than one that hedges.

**Scope boundary:** Initial generation only. Ongoing `docs/spec/` maintenance lives in `~/.config/opencode/agents/team-lead.md` (repo: `src/user/opencode/agents/team-lead.md`) (Medium/Large Task patterns).

---

<!-- CANONICAL:DOCS-PATHS-LOCAL:BEGIN -->
**Docs paths (this skill).** Master: `~/.config/opencode/skills/team-doctrine/references/docs-paths.md` — repo: `src/user/opencode/skills/team-doctrine/references/docs-paths.md` (maintained copy).
- Writes: `docs/spec/` (Seven reserved Spec Files; via spawned agents).
- Reads: codebase, `docs/tdd/`.
- Always singular docs/spec/ — never docs/specs/.
<!-- CANONICAL:DOCS-PATHS-LOCAL:END -->

## Pre-flight

> **Operator prompts:** All operator-facing `question` calls in this skill (Scope, Emphasis, conflict resolution, failure handling) MUST use pre-generated selectable options (1-4 questions per call; **max 4 options per question regardless of `multiple`** — the API rejects >4); max 12-char `header`. If the operator needs to pick more than 4, ask a routing question first ("which category?") then a second narrow question. Free-text is permitted ONLY when the operator must paste material that doesn't fit options.

Before spawning any agents:

1. **Goal alignment (HARD GATE)** — Do not proceed to context resolution or file checks until the goal is verified.
   - **If invoked directly by the operator** (no verified goal in the prompt): Use a single `question` call with two questions:
     1. `header: "Scope"` — "Which spec files should be generated?" Options: `All 7 specs` (default), `Custom subset` (multiSelect — present the 7 filenames so the operator can pick), `Cancel`.
     2. `header: "Emphasis"` — "Any dimension to emphasize during exploration?" Options: `Balanced (no emphasis)` (default), `Security posture`, `Operational readiness`, `Testing maturity`, `Architecture & maintainability`. Single-select.
     If `\$ARGUMENTS` was passed, skip question 1 (the subset is already declared) and only ask question 2.
   - **If invoked by an orchestrator with a verified goal** (the prompt contains a verified goal statement): Use it as the starting point. Re-verify alignment if your understanding diverges. Extract the goal and carry it forward.
   - Capture the verified goal (including any selected emphasis) as `{verified_goal}` for use in the spawning template.
2. **Resolve context and prepare directory** — Run these Bash commands (parallel where possible):
   - `date +%Y-%m-%d` — capture as `{today_date}` for consistent frontmatter
   - `basename $(git rev-parse --git-common-dir) | sed 's/\.git$//'` — capture as `{project_name}` for frontmatter (works in worktree layouts where `--show-toplevel` returns the branch dir, not the repo name)
   - `mkdir -p docs/spec` — ensure output directory exists
3. **Check for existing spec files** — Run `ls docs/spec/` to check for existing files.
4. **If any file in the target set already exists**, use `question` to present options. The "target set" is all 7 by default, or the `\$ARGUMENTS` subset:
   - **Overwrite** — delete the conflicting file(s) in the target set and regenerate
   - **Skip existing** — only generate missing files in the target set
   - **Cancel** — abort the operation
   If every file in the target set is missing, proceed directly to execution.

---

## Spec File Reference

Each spec file covers a specific engineering dimension. The table below defines the unique
exploration guidance for each — used in the spawning template.

<!-- COUPLING: the 7 reserved names are owned by this skill (Spec File Reference is the authority) and HARD-REFUSED by src/user/opencode/skills/prd because PRD shares docs/spec/ as its output directory. Sibling doc-authoring skills (tdd, adr, ux-spec) write to different directories so they do not refuse these names. Update init-specs and prd in lockstep when adding/removing names. -->
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

---

## Execution

### Step 1: Spawn Agents

1. **Dispatch workers via the `task` tool** — each `task` dispatch is a one-shot, isolated child session (`subagent_type: "staff-engineer"`); there is no implicit team to join and no peer messaging.
2. **Create tasks** — one `todowrite` entry per spec file (all independent, no dependencies). Each entry's `content` is `"Generate {filename}"`.
3. **Spawn all workers in the SAME message** to maximize parallelism (concurrent dispatch). For each spec file (7 total, or fewer if skipping existing), dispatch one `task({ subagent_type: "staff-engineer", description: "Generate {filename}", prompt: ..., task_id? })` with the Spawning Template below as `prompt`, substituting `{filename}`, `{exploration_guidance}`, `{today_date}`, `{project_name}`, and `{verified_goal}` (substitutions are applied to the Spawning Template body in the next section, not to the `task` call itself). The `subagent_type` IS the model pin (the agent def in `opencode.json` binds `model` + `variant`); there is no per-call `model=` and no `name=`.
4. **Assign tasks** — `todowrite` to set the entry to `in_progress`. Track each dispatch via its returned `task_id` (there is no `owner=` concept — dispatches are one-shot).

### Step 2: Wait for Completion

Each `task` dispatch returns a single summary when the worker ends — there is no peer-messaging completion and no idle notification. As each `task` returns, relay to the operator: "spec-{name} completed docs/spec/{filename} ({N}/{total} done)". A `task` return whose summary indicates failure and leaves no spec file on disk is a failed worker, not a normal completion.

Once all expected `task` dispatches have returned, run a single `todowrite` reconciliation pass to confirm task states before proceeding to Step 3. Classify each task:
- **completed** — `task` returned a success summary; verify the spec file exists on disk.
- **failed** — `task` returned a failure summary, errored at spawn, or exceeded the harness dispatch budget.

**On any spawned-worker failure**, do NOT auto-retry. Use `question` to ask the operator: (a) **respawn** — dispatch a replacement `task` (`subagent_type: "staff-engineer"`) for just that file (reuse the same spawning template; mark the `todowrite` entry back to `in_progress` so completion tracking credits the new dispatch), (b) **skip** — mark the task `completed` in `todowrite`, note the gap in the final report, and proceed, (c) **abort** — cancel remaining work and hand partial state back to the operator.

> Orchestrator crashes (this skill itself) are handled by the harness — on Opencode a crash falls through to the operator immediately. Do not add manual orchestrator-restart logic here.

Proceed to Step 3 once every task is `completed` OR the operator has resolved every failure.

### Step 3: Verify

After all agents complete, run verification **scoped to files generated this run** (`{generated_files}` = the set whose tasks reached `completed` in Step 2; on the "Skip existing" path this excludes pre-existing files this run did not produce):

1. Confirm every file in the expected target set exists on disk (`ls docs/spec/` and intersect with the target set). Flag any missing files.
2. Run `head -1 {generated_files}` and confirm every file starts with `---` (YAML frontmatter delimiter). Flag any file that does not — it indicates a malformed spec.
3. Run `grep -L '```mermaid' {generated_files} 2>/dev/null` to flag any newly-generated spec missing the required Mermaid diagram (per Spawning Template). Diagram presence is a sanity check; if a spec genuinely has no relationships/flows to diagram, the agent should have noted that — flag it for operator review.
4. Run `grep -L "last_updated: \"{today_date}\"" {generated_files} 2>/dev/null` to flag any spec whose `last_updated` does not match today's resolved date — indicates the agent ignored the pre-flight context.
5. Run `grep -L "^## Gaps & Risks" {generated_files} 2>/dev/null` to flag any newly-generated spec missing the required Gaps & Risks section — enforces the structural home for the rigorous-honesty directive.

Report which files were created successfully and flag any that are missing, malformed, or
missing required diagrams.

---

## Spawning Template

Use this template for each spec file, substituting `{filename}`, `{exploration_guidance}`,
`{today_date}`, `{project_name}`, and `{verified_goal}` (from the pre-flight steps).

```
Use the @staff-engineer agent to generate a project specification:

Generate the `docs/spec/{filename}` project specification file.

Today's date: {today_date}
Project name: {project_name}
Verified goal: {verified_goal}
The operator's goal has been pre-verified. Re-verify alignment if your understanding diverges from this goal at any point.

Requirements:
- Explore the codebase thoroughly using Read, Grep, Glob, and Bash
- {exploration_guidance}
- Check docs/tdd/ for any existing technical design documents that inform this spec
- Run `docket plan --json 2>/dev/null` to check for active project plans that provide context on ongoing work
- If other docs/spec/ files already exist, skim them to avoid content overlap
- Apply rigorous honesty: document only what exists in the codebase. Flag gaps, weaknesses, and missing capabilities explicitly — do not invent aspirational content or soften findings. A spec that honestly says "no tests exist" is more valuable than one that hedges
- Do NOT spawn sub-agents, invoke `Skill(vote)`, use other `Skill()` calls or the `task` tool, or form/manage a team. You are a leaf agent. If blocked, return a final summary naming the blocker and stop — your returned summary IS the delivery channel to the orchestrator that spawned you (there is no peer-messaging channel and no `SendMessage`).
- Include Mermaid diagrams to visualize architecture, component relationships, data flows, and system interactions. Every spec file MUST contain at least one Mermaid diagram where the subject matter involves relationships or flows between components.
- Structure the body with at least 3 H2 sections appropriate to the spec's domain (e.g. `architecture.md`: Components, Boundaries, Decisions; `security.md`: Trust Boundaries, Controls, Threat Model). Every spec MUST include a final H2 named exactly `## Gaps & Risks` — this is the structural home for the rigorous-honesty directive. If no gaps exist, write "None identified at this time" under it.
- Save the completed spec to `docs/spec/{filename}`
- Begin the file with YAML frontmatter (--- delimited) using this structure:
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
  - For `maturity`: choose based on your findings. For `dependencies`: list related spec filenames as YAML array items if a logical connection exists; leave as `[]` if none.
- After saving the file, mark your task as completed via `todowrite`, then return a final
  report summary stating `"Completed docs/spec/{filename}"` and end — your returned summary
  ends the dispatch (there is no peer-messaging channel, no idle, and no shutdown handshake;
  do not take on further work past the returned summary).
```

---

## Wrap-up

After all workers complete and verification passes:

1. List all spec files that were created (or skipped). Flag any that failed or have malformed output.
2. **No shutdown/cleanup step.** Every `task` dispatch already ended when its summary returned — there is no persistent team roster, no idle worker to reclaim, no `shutdown_request`/`shutdown_response` handshake, and no team-cleanup tool. Nothing remains to shut down.
