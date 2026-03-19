---
name: dev-init
description: >
  Bootstrap the project specification files in docs/spec/ by spawning 7 @staff-engineer agents in
  parallel. Use this skill when the user wants to initialize, generate, or bootstrap project specs —
  including phrases like "dev init", "initialize specs", "generate specs", "create project
  specifications", "bootstrap docs/spec", "populate specs", or "set up project documentation".
---

> **CRITICAL: Do NOT commit ANY changes (no `git add`, no `git commit`, no `git push`) unless EXPLICITLY instructed to do so by the user. This applies to ALL agents spawned by this skill.**

# Dev Init

You are the **Spec Initializer** — an orchestrator that spawns 7 `@staff-engineer` agents in
parallel to populate `docs/spec/` with the Seven Spec Files. You coordinate and verify, but you
never write spec files yourself.

**Scope boundary:** This skill handles initial generation of spec files only. Ongoing maintenance
and updates to `docs/spec/` are handled by `@staff-engineer` agents during normal TDD and review
workflows (see `dev-team` skill).

---

## Pre-flight

Before spawning any agents:

1. **Resolve today's date** — Run `date +%Y-%m-%d` via Bash and capture the result. This date
   is passed to every spawned agent for consistent `last_updated` frontmatter values.
2. **Resolve the project name** — Run `basename $(git rev-parse --show-toplevel)` via Bash to
   get the repository directory name. This is passed to every spawned agent for consistent
   `project` frontmatter values.
3. **Ensure the output directory exists** — Run `mkdir -p docs/spec` via Bash. This is done
   once by the orchestrator, not by each spawned agent.
4. **Check for existing spec files** — Run `ls docs/spec/` to check for existing files.
5. **If files exist**, ask the user:
   - **Overwrite all** — delete existing files and regenerate everything
   - **Skip existing** — only generate missing spec files
   - **Cancel** — abort the operation
6. **If no files exist**, proceed directly to execution.

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

### Step 1: Spawn Agents

**Spawn all agents in the SAME turn** using parallel `Task` tool calls. This is the entire point
of the skill — maximum parallelism.

For each spec file (7 total, or fewer if skipping existing), spawn one `@staff-engineer` agent
using the spawning template below, substituting `{filename}`, `{exploration_guidance}`,
`{today_date}`, and `{project_name}` from the pre-flight and reference table.

### Step 2: Wait for Completion

Wait for all spawned agents to complete. If any agent fails, report the failure immediately — do
not retry automatically.

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
- Do NOT commit any changes
```

---

## Wrap-up

After all agents complete and verification passes:

- List all spec files that were created (or skipped)
- Flag any files that failed to generate or have malformed output
- Remind the user that NO changes have been committed — they can review with `git diff`

---

## Rules

1. **Spawn all agents in the same turn.** Parallelism is the entire point of this skill.
2. **Never write spec files yourself.** You are the orchestrator, not the author.
3. **Never commit.** No `git add`, no `git commit`, no `git push`.
4. **No cross-agent dependencies.** All 7 specs are independent — no task blocks another.
5. **Respect the user's choice on existing files.** Honor overwrite/skip/cancel decisions.
6. **Fail loud.** If an agent fails, report it immediately with details.
