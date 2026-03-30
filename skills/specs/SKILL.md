---
name: specs
description: >
  Bootstrap docs/spec/ by spawning @staff-engineer agents in parallel. Trigger on: "specs",
  "generate specs", "bootstrap specs", "initialize specs", "create project specifications",
  "bootstrap docs/spec", "populate specs", or "set up project documentation".
argument-hint: "[file...]"
effort: medium
allowed-tools: ["Bash", "Read", "Glob", "Grep", "Agent", "SendMessage", "TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "TeamCreate", "TeamDelete", "AskUserQuestion"]
---

> **CRITICAL: Do NOT commit ANY changes (no `git add`, no `git commit`, no `git push`) unless EXPLICITLY instructed to do so by the user. This applies to ALL agents spawned by this skill.**

## Argument Handling

The argument is **optional** — this skill has a single well-defined behavior.

- **No argument** (`/specs`): Proceed normally — bootstrap all 7 spec files.
- **With argument** (`/specs security.md operations.md`): Treat named files as the target set
  instead of all 7. Validate each name against the Spec File Reference table; reject unknown names.

# Specs

You are the **Spec Initializer** — an orchestrator that spawns 7 `@staff-engineer` agents in
parallel to populate `docs/spec/` with the Seven Spec Files. You coordinate and verify, but you
never write spec files yourself.

**Scope boundary:** This skill handles initial generation of spec files only. Ongoing maintenance
and updates to `docs/spec/` are handled by `@staff-engineer` agents during normal TDD and review
workflows (see `dev` skill).

---

## Pre-flight

Before spawning any agents:

1. **Goal alignment (HARD GATE)** — Do not proceed to context resolution or file checks until the goal is verified.
   - **If invoked directly by the operator** (no verified goal in the prompt): Use `AskUserQuestion` to confirm what specs they want generated (all 7, or a subset) and whether there are any special focus areas or constraints (e.g., "focus on security posture", "we have no CI yet so skip operations").
   - **If invoked by an orchestrator with a verified goal** (the prompt contains a verified goal statement): Use it as the starting point. Re-verify alignment if your understanding diverges. Extract the goal and carry it forward.
   - Capture the verified goal as `{verified_goal}` for use in the spawning template.
2. **Resolve context and prepare directory** — Run these Bash commands (parallel where possible):
   - `date +%Y-%m-%d` — capture as `{today_date}` for consistent frontmatter
   - `basename $(git rev-parse --show-toplevel)` — capture as `{project_name}` for frontmatter
   - `mkdir -p docs/spec` — ensure output directory exists
3. **Check for existing spec files** — Run `ls docs/spec/` to check for existing files.
4. **If files exist**, use AskUserQuestion to present options:
   - **Overwrite all** — "Delete existing files and regenerate everything"
   - **Skip existing** — "Only generate missing spec files"
   - **Cancel** — "Abort the operation"
5. **If no files exist**, proceed directly to execution.

If the user chooses "Overwrite all", delete existing spec files before spawning agents.
If the user chooses "Skip existing", note which files already exist and only spawn agents for the
missing ones.

---

## Spec File Reference

Each spec file covers a specific engineering dimension. The table below defines the unique
exploration guidance for each — used in the spawning template.

| Spec File | Exploration Guidance |
|---|---|
| `architecture.md` | Examine project structure, entry points, module boundaries, and dependency graph. Identify system components, design patterns, integration points, and key architectural decisions. Look at package manifests, config files, and directory layout for structure clues. |
| `security.md` | Examine authentication/authorization patterns, secret management, and environment variables. Check for .env files, credential handling, API key patterns, and trust boundaries. Identify security-relevant dependencies and their configurations. |
| `operations.md` | Check .github/ for CI/CD workflows, Dockerfiles, deployment configs, and infrastructure code. Look for monitoring, logging, observability setup, and operational runbooks. Identify rollback procedures, release processes, and environment management. |
| `performance.md` | Look for caching strategies, database queries, connection pooling, and concurrency patterns. Identify known bottlenecks, benchmarking tools, and performance-critical paths. Check for lazy loading, pagination, batching, and scaling considerations. |
| `code-quality.md` | Check for linter configs (eslint, clippy, ruff, etc.), formatters, and editor settings. Identify naming conventions, error handling patterns, and design patterns in use. Look at existing code style, module organization, and project-specific conventions. |
| `review-strategy.md` | Identify areas of high risk, complex logic, and frequent change. Determine which review dimensions matter most for this specific project. Look for existing PR templates, review checklists, contribution guidelines, and CI quality gates. |
| `testing.md` | Check for test directories, test runners, test configs, and CI test steps. Identify the test pyramid breakdown: unit, integration, e2e, and their proportions. Look at coverage tools, test utilities, fixtures, and mocking patterns. If no tests exist, state that explicitly. |

---

## Execution

### Step 1: Create Team and Spawn Agents

1. **Create the team** — `TeamCreate(team_name="specs-init-{today_date}", description="Bootstrap project specifications for {project_name}")`
2. **Create tasks** — one `TaskCreate` per spec file (all independent, no dependencies):
   `TaskCreate(subject="Generate {filename}", description="Generate docs/spec/{filename} project specification")`
3. **Spawn all agents in the SAME turn** to maximize parallelism. For each spec file (7 total, or fewer if skipping existing), spawn one `@staff-engineer` teammate using the spawning template below, substituting `{filename}`, `{exploration_guidance}`, `{today_date}`, and `{project_name}`:
   `Agent(team_name="specs-init-{today_date}", name="spec-{filename-without-ext}", subagent_type="staff-engineer", prompt="...")`
4. **Assign tasks** — `TaskUpdate(taskId=<id>, owner="spec-{filename-without-ext}", status="in_progress")`

### Step 2: Wait for Completion

Agents send completion messages via SendMessage when done. As each reports, relay to the operator: "spec-{name} completed docs/spec/{filename} ({N}/{total} done)".

Use `TaskList()` periodically. Once all tasks show `completed`, proceed to Step 3. If any agent fails or stops responding, report the failure to the operator — do not retry automatically.

### Step 3: Verify

After all agents complete, run verification:

1. Run `ls docs/spec/` and confirm all expected files exist. Flag any missing files.
2. Run `head -1 docs/spec/*.md` and confirm every file starts with `---` (YAML frontmatter
   delimiter). Flag any file that does not — it indicates a malformed spec.

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
- If other docs/spec/ files already exist, skim them to avoid content overlap
- Document only what exists in the codebase — flag gaps explicitly, do not invent aspirational content
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
  dependencies:
    - <related-spec-filename.md>
  ---
  ```
  - For `maturity`: choose honestly based on your findings about the overall project
  - For `dependencies`: list related spec filenames ONLY if a logical connection exists —
    omit the field entirely if none
- Do NOT write implementation code — the spec file is the deliverable
- After saving the file, mark your task as completed via TaskUpdate and send a completion
  message via SendMessage(to="team-lead", message="Completed docs/spec/{filename}")
```

---

## Wrap-up & Team Cleanup

After all agents complete and verification passes:

1. List all spec files that were created (or skipped). Flag any that failed or have malformed output.
2. **Shut down all teammates immediately** — send to EACH spawned agent:
   `SendMessage(to="spec-{name}", message={"type": "shutdown_request", "reason": "Spec generation complete"})`
   Send all shutdown messages in the SAME turn. Do not wait for responses.
3. **Delete the team** — `TeamDelete(team_name="specs-init-{today_date}")`
4. Remind the user that NO changes have been committed — they can review with `git diff`.
