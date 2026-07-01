---
name: init-specs
description: >
  One-time bootstrap of docs/spec/ — spawns @staff-engineer agents in parallel to generate
  project specification files. Re-invocation prompts before overwriting existing specs;
  ongoing maintenance is handled by @staff-engineer during TDD/review work, not by this skill.
  Trigger: "create specs", "generate specs", "bootstrap project specs", "create project specifications".
---
<!-- CANONICAL:BANNER:BEGIN -->
> **CRITICAL — applies to coordinator AND every spawned worker:** (1) Do NOT commit ANY changes (no `git add`, `git commit`, or `git push`) unless EXPLICITLY instructed by the user. (2) Workers are leaf agents — MUST NOT spawn sub-agents, invoke `/vote`, invoke other skills recursively, call `send_input`, or form/manage a team. Report blockers in the final worker report for the coordinator to route.
<!-- CANONICAL:BANNER:END -->

## Argument Handling

The argument is **optional** — this skill has a single well-defined behavior.

- **No argument** (`/init-specs`): Bootstrap all 7 spec files.
- **With argument** (`/init-specs security.md operations.md`): Treat `\$ARGUMENTS` as the target set
  instead of all 7. Validate each name against the Spec File Reference table.
- **On unknown name(s)**: Abort with a message listing the rejected name(s) and the 7 valid filenames; do not partially proceed.

# Specs

You are the **Spec Initializer** — a coordinator that bootstraps `docs/spec/` with the Seven Spec Files through delegated Codex staff-engineer workers. You coordinate and verify; you never write spec files yourself. Each worker owns one isolated file with no cross-agent handoffs.

Always delegates spec authoring to parent-led Codex staff-engineer subagents. The coordinator may prepare directories, dispatch workers, wait for reports, verify outputs, and summarize results, but it does not author spec content.

> **Rigorous honesty over aspirational specs.** Specs must document what actually exists in the codebase, not what should exist. When reviewing agent output, reject any spec content that invents capabilities, softens gaps, or presents aspirational goals as current state. A spec that says "no tests exist" is more valuable than one that hedges.

**Scope boundary:** Initial generation only. Ongoing `docs/spec/` maintenance lives in `src/user/codex/personas/team-lead.md` (Medium/Large Task patterns).

---

<!-- CANONICAL:DOCS-PATHS-LOCAL:BEGIN -->
**Docs paths (this skill).** Master: team-lead.md §Docs-Path Taxonomy (maintained copy).
- Writes: `docs/spec/` (Seven reserved Spec Files; via spawned agents).
- Reads: codebase, `docs/tdd/`.
- Always singular docs/spec/ — never docs/specs/.
<!-- CANONICAL:DOCS-PATHS-LOCAL:END -->

## Pre-flight

> **Operator prompts:** All operator-facing `AskUserQuestion` calls in this skill (Scope, Emphasis, conflict resolution, failure handling) MUST use pre-generated selectable options (1-4 questions per call; **max 4 options per question regardless of `multiSelect`** — the API rejects >4); max 12-char `header`. If the operator needs to pick more than 4, ask a routing question first ("which category?") then a second narrow question. Free-text is permitted ONLY when the operator must paste material that doesn't fit options.

Before spawning any agents:

1. **Goal alignment (HARD GATE)** — Do not proceed to context resolution or file checks until the goal is verified.
   - **If invoked directly by the operator** (no verified goal in the prompt): Use a single `AskUserQuestion` call with two questions:
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
4. **If any file in the target set already exists**, use AskUserQuestion to present options. The "target set" is all 7 by default, or the `\$ARGUMENTS` subset:
   - **Overwrite** — delete the conflicting file(s) in the target set and regenerate
   - **Skip existing** — only generate missing files in the target set
   - **Cancel** — abort the operation
   If every file in the target set is missing, proceed directly to execution.

---

## Spec File Reference

Each spec file covers a specific engineering dimension. The table below defines the unique
exploration guidance for each — used in the spawning template.

<!-- COUPLING: the 7 reserved names are owned by this skill (Spec File Reference is the authority) and HARD-REFUSED by src/user/codex/skills/prd because PRD shares docs/spec/ as its output directory. Sibling doc-authoring skills (tdd, adr, ux-spec) write to different directories so they do not refuse these names. Update init-specs and prd in lockstep when adding/removing names. -->
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

### Step 1: Dispatch Workers

1. Create a local phase ledger with one row per target file: filename, worker id, status (`planned | spawned | reported | verified | failed`), and output path.
2. Dispatch one Codex `staff-engineer` subagent per target file. Each `spawn_agent` call MUST set an explicit Codex worker model and effort: default `model="gpt-5.4"` and `reasoning_effort="medium"` unless the verified brief explicitly justifies an upgrade for a specific spec. Record the model/effort in the local ledger. Spawn all independent workers in the SAME turn where the harness permits parallel dispatch.
3. Each worker brief uses the Spawning Template below, substituting `{filename}`, `{exploration_guidance}`, `{today_date}`, `{project_name}`, and `{verified_goal}`. Track the returned Codex agent id in the local ledger.
4. If the current harness cannot spawn workers from this skill context, emit the prepared worker briefs and stop with `Blocked: parent-led Codex staff-engineer subagents are required for spec authoring.` Do not write specs directly.

### Step 2: Wait for Reports

Wait on the returned worker ids. As each report arrives, record whether it created `docs/spec/{filename}`, failed, or blocked.

Classify each ledger row:
- **reported** — worker returned a final report and the file exists on disk.
- **failed** — worker reported failure, timed out, or returned without creating its assigned file.
- **spawned** — worker still running; continue bounded waiting.

**On any worker failure**, do NOT auto-retry. Use `AskUserQuestion` to ask the operator: (a) **respawn** — dispatch a replacement `staff-engineer` worker for just that file with the same template and the failure context, (b) **skip** — leave the file absent and note the gap in the final report, or (c) **abort** — cancel remaining work and return partial state.

Proceed to Step 3 once every target row is `reported` OR the operator has resolved every failure.

### Step 3: Verify

After all agents complete, run verification **scoped to files generated this run** (`{generated_files}` = the set whose tasks reached `completed` in Step 2; on the "Skip existing" path this excludes pre-existing files this run did not produce):

1. Confirm every file in the expected target set exists on disk (`ls docs/spec/` and intersect with the target set). Flag any missing files.
2. Run `head -1 {generated_files}` and confirm every file starts with `---` (YAML frontmatter delimiter). Flag any file that does not — it indicates a malformed spec.
3. Run a renderer-free Mermaid shape check over `{generated_files}`: flag files with no ` ```mermaid ` block unless the spec explicitly explains why no relationship/flow diagram applies, and flag any Mermaid block whose first non-blank content line is empty or not a Mermaid diagram-type keyword (for example, `graph`/`flowchart`, `sequenceDiagram`, `stateDiagram`, `erDiagram`, `journey`, `classDiagram`, `gantt`).
4. Run `grep -L "last_updated: \"{today_date}\"" {generated_files} 2>/dev/null` to flag any spec whose `last_updated` does not match today's resolved date — indicates the agent ignored the pre-flight context.
5. Run `grep -L "^## Gaps & Risks" {generated_files} 2>/dev/null` to flag any newly-generated spec missing the required Gaps & Risks section — enforces the structural home for the rigorous-honesty directive.

Report which files were created successfully and flag any that are missing, malformed, or
missing required diagrams.

---

## Spawning Template

Use this template for each spec file, substituting `{filename}`, `{exploration_guidance}`,
`{today_date}`, `{project_name}`, and `{verified_goal}` (from the pre-flight steps).

```
Use the @staff-engineer agent to generate a project specification. Dispatch as a Codex worker with `model="gpt-5.4"` and `reasoning_effort="medium"` unless the verified brief explicitly justifies an upgraded model/effort for this file.

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
- Do NOT spawn sub-agents, invoke `/vote`, invoke other skills recursively, call `send_input`, or form/manage a team. You are a leaf worker. If blocked, return a final report naming the blocker and stop.
- Include Mermaid diagrams to visualize architecture, component relationships, data flows, and system interactions. Every spec file MUST contain at least one Mermaid diagram where the subject matter involves relationships or flows between components. Any ` ```mermaid ` block MUST have a first non-blank content line declaring a Mermaid diagram type (for example, `graph`/`flowchart`, `sequenceDiagram`, `stateDiagram`, `erDiagram`, `journey`, `classDiagram`, `gantt`).
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
- After saving the file, return a final report with `Completed docs/spec/{filename}`, commands or files inspected, and any gaps or risks. Then stop work; the coordinator owns worker closeout.
```

---

## Wrap-up & Worker Cleanup

After all agents complete and verification passes:

1. List all spec files that were created (or skipped). Flag any that failed or have malformed output.
2. Close each returned Codex worker id after its report is consumed and output verification is complete.
3. Emit a concise completion summary: target set, created files, skipped files, failures, and verification evidence.
