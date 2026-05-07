---
name: create-specs
description: >
  Bootstrap docs/spec/ by spawning @staff-engineer agents in parallel to generate project
  specification files. Trigger on: "create specs", "generate specs", "bootstrap project
  specs", "create project specifications".
argument-hint: "[file...]"
effort: max
allowed-tools: ["Bash", "Read", "Glob", "Grep", "Agent", "SendMessage", "TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "TeamCreate", "TeamDelete", "AskUserQuestion"]
---

> **CRITICAL — applies to orchestrator AND every spawned teammate:** (1) Do NOT commit ANY changes (no `git add`, `git commit`, or `git push`) unless EXPLICITLY instructed by the user. (2) Teammates are leaf agents — MUST NOT spawn sub-agents, invoke `/create-vote`, or use `Skill()`, `Agent()`, or `TeamCreate`. SendMessage team-lead if blocked.

## Argument Handling

The argument is **optional** — this skill has a single well-defined behavior.

- **No argument** (`/create-specs`): Bootstrap all 7 spec files.
- **With argument** (`/create-specs security.md operations.md`): Treat `$ARGUMENTS` as the target set
  instead of all 7. Validate each name against the Spec File Reference table.
- **On unknown name(s)**: Abort with a message listing the rejected name(s) and the 7 valid filenames; do not partially proceed.

# Create Specs

You are the **Spec Initializer** — an orchestrator that spawns 7 `@staff-engineer` agents in parallel to populate `docs/spec/` with the Seven Spec Files. You coordinate and verify; you never write spec files yourself. Each agent works on an isolated file with no cross-agent handoffs; spawned agents are leaf agents (prohibition detailed in the Spawning Template).

> **Rigorous honesty over aspirational specs.** Specs must document what actually exists in the codebase, not what should exist. When reviewing agent output, reject any spec content that invents capabilities, softens gaps, or presents aspirational goals as current state. A spec that says "no tests exist" is more valuable than one that hedges.

**Scope boundary:** Initial generation only. Ongoing `docs/spec/` maintenance is handled by
`@staff-engineer` during TDD and review workflows (see `dev` skill).

---

## Pre-flight

Before spawning any agents:

1. **Goal alignment (HARD GATE)** — Do not proceed to context resolution or file checks until the goal is verified.
   - **If invoked directly by the operator** (no verified goal in the prompt): Use a single `AskUserQuestion` call with two questions:
     1. `header: "Scope"` — "Which spec files should be generated?" Options: `All 7 specs` (default), `Custom subset` (multiSelect — present the 7 filenames so the operator can pick), `Cancel`.
     2. `header: "Emphasis"` — "Any dimension to emphasize during exploration?" Options: `Balanced (no emphasis)` (default), `Security posture`, `Operational readiness`, `Testing maturity`. Single-select.
     If `$ARGUMENTS` was passed, skip question 1 (the subset is already declared) and only ask question 2.
   - **If invoked by an orchestrator with a verified goal** (the prompt contains a verified goal statement): Use it as the starting point. Re-verify alignment if your understanding diverges. Extract the goal and carry it forward.
   - Capture the verified goal (including any selected emphasis) as `{verified_goal}` for use in the spawning template.
2. **Resolve context and prepare directory** — Run these Bash commands (parallel where possible):
   - `date +%Y-%m-%d` — capture as `{today_date}` for consistent frontmatter
   - `basename $(git rev-parse --show-toplevel)` — capture as `{project_name}` for frontmatter
   - `mkdir -p docs/spec` — ensure output directory exists
3. **Check for existing spec files** — Run `ls docs/spec/` to check for existing files.
4. **If any file in the target set already exists**, use AskUserQuestion to present options. The "target set" is all 7 by default, or the `$ARGUMENTS` subset:
   - **Overwrite** — delete the conflicting file(s) in the target set and regenerate
   - **Skip existing** — only generate missing files in the target set
   - **Cancel** — abort the operation
   If every file in the target set is missing, proceed directly to execution.

---

## Spec File Reference

Each spec file covers a specific engineering dimension. The table below defines the unique
exploration guidance for each — used in the spawning template.

<!-- COUPLING: the 7 reserved names are HARD-REFUSED by skills/create-prd, create-tdd, create-adr, and create-ux-spec. Update all 5 (this file plus the 4 create-* skills) in lockstep when adding/removing names. -->
<!-- RESERVED-NAMES:BEGIN -->
| Spec File | Exploration Guidance |
|---|---|
| `architecture.md` | Examine project structure, entry points, module boundaries, and dependency graph. Identify system components, design patterns, integration points, and key architectural decisions. Look at package manifests, config files, and directory layout for structure clues. |
| `security.md` | Examine authentication/authorization patterns, secret management, and environment variables. Check for .env files, credential handling, API key patterns, and trust boundaries. Identify security-relevant dependencies and their configurations. |
| `operations.md` | Check .github/ for CI/CD workflows, Dockerfiles, deployment configs, and infrastructure code. Look for monitoring, logging, observability setup, and operational runbooks. Identify rollback procedures, release processes, and environment management. |
| `performance.md` | Look for caching strategies, database queries, connection pooling, and concurrency patterns. Identify known bottlenecks, benchmarking tools, and performance-critical paths. Check for lazy loading, pagination, batching, and scaling considerations. |
| `code-quality.md` | Check for linter configs (eslint, clippy, ruff, etc.), formatters, and editor settings. Identify naming conventions, error handling patterns, and design patterns in use. Look at existing code style, module organization, and project-specific conventions. |
| `review-strategy.md` | Identify areas of high risk, complex logic, and frequent change. Determine which review dimensions matter most for this specific project. Look for existing PR templates, review checklists, contribution guidelines, and CI quality gates. |
| `testing.md` | Check for test directories, test runners, test configs, and CI test steps. Identify the test pyramid breakdown: unit, integration, e2e, and their proportions. Look at coverage tools, test utilities, fixtures, and mocking patterns. If no tests exist, state that explicitly. |
<!-- RESERVED-NAMES:END -->

---

## Execution

### Step 1: Create Team and Spawn Agents

1. **Create the team** — `TeamCreate(team_name="specs-init-{today_date}", description="Bootstrap project specifications for {project_name}")`
2. **Create tasks** — one `TaskCreate` per spec file (all independent, no dependencies):
   `TaskCreate(subject="Generate {filename}", activeForm="Generating {filename}", description="Generate docs/spec/{filename} project specification")`
3. **Spawn all agents in the SAME turn** to maximize parallelism. For each spec file (7 total, or fewer if skipping existing), spawn one `@staff-engineer` teammate using the spawning template below, substituting `{filename}`, `{exploration_guidance}`, `{today_date}`, `{project_name}`, and `{verified_goal}`:
   `Agent(team_name="specs-init-{today_date}", name="spec-{filename-without-ext}", subagent_type="staff-engineer", prompt="...")`
4. **Assign tasks** — `TaskUpdate(taskId=<id>, owner="spec-{filename-without-ext}", status="in_progress")`

### Step 2: Wait for Completion

Agents send completion messages via SendMessage when done. As each reports, relay to the operator: "spec-{name} completed docs/spec/{filename} ({N}/{total} done)".

Poll `TaskList()` every ~2 minutes. Classify each task:
- **completed** — agent SendMessaged; verify the spec file exists on disk.
- **failed** — agent SendMessaged a failure, OR task is `in_progress` past ~10 min with no SendMessage activity.
- **in_progress** — still working; continue polling.

**On any failure**, do NOT auto-retry. Use `AskUserQuestion` to ask the operator: (a) **respawn** — spawn a replacement `@staff-engineer` for just that file (reuse the same spawning template and task), (b) **skip** — mark the task completed, note the gap in the final report, and proceed, (c) **abort** — cancel remaining work and hand partial state back to the operator.

Proceed to Step 3 once every task is `completed` OR the operator has resolved every failure.

### Step 3: Verify

After all agents complete, run verification:

1. Run `ls docs/spec/` and confirm all expected files exist. Flag any missing files.
2. Run `head -1 docs/spec/*.md` and confirm every file starts with `---` (YAML frontmatter
   delimiter). Flag any file that does not — it indicates a malformed spec.
3. **Spot-check codebase reality.** Pick 1-2 spec files and verify a factual claim from each
   using Grep or Read (e.g., if a spec says "tests use pytest," confirm pytest is configured).
   Flag any content that appears aspirational rather than factual.

Report which files were created successfully and flag any that are missing or malformed.

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
- Do NOT spawn sub-agents, invoke `/create-vote`, or use `Skill()`, `Agent()`, or `TeamCreate`. You are a leaf agent. SendMessage team-lead if you are blocked or need a decision; the completion SendMessage is covered below.
- Include Mermaid diagrams to visualize architecture, component relationships, data flows, and system interactions. Every spec file MUST contain at least one Mermaid diagram where the subject matter involves relationships or flows between components.
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
- After saving the file, mark your task as completed via TaskUpdate and send a completion
  message via SendMessage(to="team-lead", message="Completed docs/spec/{filename}")
```

---

## Wrap-up & Team Cleanup

After all agents complete and verification passes:

1. List all spec files that were created (or skipped). Flag any that failed or have malformed output.
2. **Shut down surviving teammates** — for each spawned agent whose task is `completed` (per Step 2 classification), send `shutdown_request` in the SAME turn. Skip agents whose task was marked `failed` (no process to terminate).
3. **Delete the team** — `TeamDelete(team_name="specs-init-{today_date}")`
4. Remind the user that NO changes have been committed — they can review with `git diff`.
