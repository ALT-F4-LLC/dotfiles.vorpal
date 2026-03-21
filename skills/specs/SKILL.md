---
name: specs
description: >
  Bootstrap the project specification files in docs/spec/ by spawning 7 @staff-engineer agents in
  parallel. Use this skill when the user wants to initialize, generate, or bootstrap project specs —
  including phrases like "specs", "generate specs", "bootstrap specs", "initialize specs", "create
  project specifications", "bootstrap docs/spec", "populate specs", or "set up project documentation".
argument-hint: "[file...]"
effort: medium
allowed-tools: ["Bash", "Read", "Glob", "Grep", "Agent", "SendMessage", "TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "TeamCreate", "TeamDelete"]
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

1. **Resolve context and prepare directory** — Run these Bash commands (parallel where possible):
   - `date +%Y-%m-%d` — capture as `{today_date}` for consistent frontmatter
   - `basename $(git rev-parse --show-toplevel)` — capture as `{project_name}` for frontmatter
   - `mkdir -p docs/spec` — ensure output directory exists
2. **Check for existing spec files** — Run `ls docs/spec/` to check for existing files.
3. **If files exist**, ask the user:
   - **Overwrite all** — delete existing files and regenerate everything
   - **Skip existing** — only generate missing spec files
   - **Cancel** — abort the operation
4. **If no files exist**, proceed directly to execution.

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
| `testing.md` | Check for test directories, test runners, test configs, and CI test steps. Identify the test pyramid breakdown: unit, integration, e2e, and their proportions. Look at coverage tools, test utilities, fixtures, and mocking patterns. Be honest if no tests exist. |

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

Agents send completion messages via SendMessage when done. Use `TaskList()` to check that
all tasks have status `completed`. Once all are complete, proceed to Step 3.

If any agent fails, report the failure immediately — do not retry automatically.

### Step 3: Verify

After all agents complete, run verification:

1. Run `ls docs/spec/` and confirm all expected files exist. Flag any missing files.
2. Run `head -1 docs/spec/*.md` and confirm every file starts with `---` (YAML frontmatter
   delimiter). Flag any file that does not — it indicates a malformed spec.

Report which files were created successfully and flag any that are missing or malformed.

---

## Spawning Template

Use this template for each spec file, substituting `{filename}`, `{exploration_guidance}`,
`{today_date}`, and `{project_name}` (from the pre-flight steps).

```
Use the @staff-engineer agent to generate a project specification:

Generate the `docs/spec/{filename}` project specification file.

Today's date: {today_date}
Project name: {project_name}

Requirements:
- Explore the codebase thoroughly using Read, Grep, Glob, and Bash
- {exploration_guidance}
- Check docs/tdd/ for any existing technical design documents that inform this spec
- If other docs/spec/ files already exist, skim them to avoid content overlap
- Document what ACTUALLY exists in the codebase — not aspirational goals
- Be honest about gaps and missing pieces
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

- List all spec files that were created (or skipped)
- Flag any files that failed to generate or have malformed output
- **Shut down all teammates** via `SendMessage(to="spec-{filename-without-ext}", message={"type": "shutdown_request", "reason": "Spec generation complete"})` for each
- **Delete the team** via `TeamDelete(team_name="specs-init-{today_date}")` to clean up resources
- Remind the user that NO changes have been committed — they can review with `git diff`

