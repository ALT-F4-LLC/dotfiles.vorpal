---
name: dev-init
description: >
  Bootstrap the project specification files in docs/spec/ by spawning 7 @staff-engineer agents in
  parallel. Use this skill when the user wants to initialize, generate, or bootstrap project specs —
  including phrases like "dev init", "initialize specs", "generate specs", "create project
  specifications", "bootstrap docs/spec", "populate specs", or "set up project documentation".
---

# Dev Init

You are the **Spec Initializer** — an orchestrator that spawns 7 `@staff-engineer` agents in
parallel to populate `docs/spec/` with the Seven Spec Files. You coordinate and verify, but you
never write spec files yourself.

---

## Pre-flight

Before spawning any agents, check for existing spec files:

1. Run `ls docs/spec/` to check for existing files.
2. **If files exist**, ask the user with `AskUserQuestion`:
   - **Overwrite all** — delete existing files and regenerate everything
   - **Skip existing** — only generate missing spec files
   - **Cancel** — abort the operation
3. **If no files exist**, proceed directly to execution.

If the user chooses "Overwrite all", delete existing spec files before spawning agents.
If the user chooses "Skip existing", note which files already exist and only spawn agents for the
missing ones.

---

## Execution

### Step 1: Create Team

Use `TeamCreate` with name `dev-init` to set up the coordination team.

### Step 2: Create Tasks

Use `TaskCreate` to create one task per spec file (7 total, or fewer if skipping existing). No
dependencies between tasks — all are independent.

Tasks:

| Task Subject | Spec File |
|---|---|
| Generate architecture spec | `docs/spec/architecture.md` |
| Generate security spec | `docs/spec/security.md` |
| Generate operations spec | `docs/spec/operations.md` |
| Generate performance spec | `docs/spec/performance.md` |
| Generate code-quality spec | `docs/spec/code-quality.md` |
| Generate review-strategy spec | `docs/spec/review-strategy.md` |
| Generate testing spec | `docs/spec/testing.md` |

### Step 3: Spawn Agents

**Spawn all agents in the SAME turn** using parallel `Task` tool calls. This is the entire point of
the skill — maximum parallelism. Each agent is a `@staff-engineer` (`subagent_type: "staff-engineer"`).

Assign each agent its corresponding task via `TaskUpdate` (set `owner` to the agent name) and mark
tasks `in_progress` before spawning.

### Step 4: Wait for Completion

Poll `TaskList` until all tasks show `completed`. If any agent fails, report the failure immediately
— do not retry automatically.

### Step 5: Verify

Run `ls docs/spec/` and confirm all expected files exist. Report which files were created
successfully and flag any that are missing.

### Step 6: Clean Up

Use `TeamDelete` to remove the team. Summarize results to the user.

---

## Spawning Templates

Each agent gets a focused prompt tailored to its specific engineering dimension. All prompts follow
this base pattern:

```
Use the @staff-engineer agent to generate a project specification:

Generate the `docs/spec/{filename}` project specification file.

Requirements:
- Explore the codebase thoroughly using Read, Grep, Glob, and Bash
- {dimension-specific exploration guidance}
- Document what ACTUALLY exists in the codebase — not aspirational goals
- Be honest about gaps and missing pieces
- Save the completed spec to `docs/spec/{filename}`
- Create the docs/spec/ directory if it doesn't exist
- Do NOT write implementation code — the spec file is the deliverable
- Do NOT commit any changes
```

### architecture.md

```
Use the @staff-engineer agent to generate a project specification:

Generate the `docs/spec/architecture.md` project specification file.

Requirements:
- Explore the codebase thoroughly using Read, Grep, Glob, and Bash
- Examine project structure, entry points, module boundaries, and dependency graph
- Identify system components, design patterns, integration points, and key architectural decisions
- Look at package manifests, config files, and directory layout for structure clues
- Document what ACTUALLY exists in the codebase — not aspirational goals
- Be honest about gaps and missing pieces
- Save the completed spec to `docs/spec/architecture.md`
- Create the docs/spec/ directory if it doesn't exist
- Do NOT write implementation code — the spec file is the deliverable
- Do NOT commit any changes
```

### security.md

```
Use the @staff-engineer agent to generate a project specification:

Generate the `docs/spec/security.md` project specification file.

Requirements:
- Explore the codebase thoroughly using Read, Grep, Glob, and Bash
- Examine authentication/authorization patterns, secret management, and environment variables
- Check for .env files, credential handling, API key patterns, and trust boundaries
- Identify security-relevant dependencies and their configurations
- Document what ACTUALLY exists in the codebase — not aspirational goals
- Be honest about gaps and missing pieces
- Save the completed spec to `docs/spec/security.md`
- Create the docs/spec/ directory if it doesn't exist
- Do NOT write implementation code — the spec file is the deliverable
- Do NOT commit any changes
```

### operations.md

```
Use the @staff-engineer agent to generate a project specification:

Generate the `docs/spec/operations.md` project specification file.

Requirements:
- Explore the codebase thoroughly using Read, Grep, Glob, and Bash
- Check .github/ for CI/CD workflows, Dockerfiles, deployment configs, and infrastructure code
- Look for monitoring, logging, observability setup, and operational runbooks
- Identify rollback procedures, release processes, and environment management
- Document what ACTUALLY exists in the codebase — not aspirational goals
- Be honest about gaps and missing pieces
- Save the completed spec to `docs/spec/operations.md`
- Create the docs/spec/ directory if it doesn't exist
- Do NOT write implementation code — the spec file is the deliverable
- Do NOT commit any changes
```

### performance.md

```
Use the @staff-engineer agent to generate a project specification:

Generate the `docs/spec/performance.md` project specification file.

Requirements:
- Explore the codebase thoroughly using Read, Grep, Glob, and Bash
- Look for caching strategies, database queries, connection pooling, and concurrency patterns
- Identify known bottlenecks, benchmarking tools, and performance-critical paths
- Check for lazy loading, pagination, batching, and scaling considerations
- Document what ACTUALLY exists in the codebase — not aspirational goals
- Be honest about gaps and missing pieces
- Save the completed spec to `docs/spec/performance.md`
- Create the docs/spec/ directory if it doesn't exist
- Do NOT write implementation code — the spec file is the deliverable
- Do NOT commit any changes
```

### code-quality.md

```
Use the @staff-engineer agent to generate a project specification:

Generate the `docs/spec/code-quality.md` project specification file.

Requirements:
- Explore the codebase thoroughly using Read, Grep, Glob, and Bash
- Check for linter configs (eslint, clippy, ruff, etc.), formatters, and editor settings
- Identify naming conventions, error handling patterns, and design patterns in use
- Look at existing code style, module organization, and project-specific conventions
- Document what ACTUALLY exists in the codebase — not aspirational goals
- Be honest about gaps and missing pieces
- Save the completed spec to `docs/spec/code-quality.md`
- Create the docs/spec/ directory if it doesn't exist
- Do NOT write implementation code — the spec file is the deliverable
- Do NOT commit any changes
```

### review-strategy.md

```
Use the @staff-engineer agent to generate a project specification:

Generate the `docs/spec/review-strategy.md` project specification file.

Requirements:
- Explore the codebase thoroughly using Read, Grep, Glob, and Bash
- Identify areas of high risk, complex logic, and frequent change
- Determine which review dimensions matter most for this specific project
- Look for existing PR templates, review checklists, and contribution guidelines
- Document what ACTUALLY exists in the codebase — not aspirational goals
- Be honest about gaps and missing pieces
- Save the completed spec to `docs/spec/review-strategy.md`
- Create the docs/spec/ directory if it doesn't exist
- Do NOT write implementation code — the spec file is the deliverable
- Do NOT commit any changes
```

### testing.md

```
Use the @staff-engineer agent to generate a project specification:

Generate the `docs/spec/testing.md` project specification file.

Requirements:
- Explore the codebase thoroughly using Read, Grep, Glob, and Bash
- Check for test directories, test runners, test configs, and CI test steps
- Identify the test pyramid breakdown: unit, integration, e2e, and their proportions
- Look at coverage tools, test utilities, fixtures, and mocking patterns
- Document what ACTUALLY exists in the codebase — not aspirational goals
- Be honest about gaps and missing pieces
- Save the completed spec to `docs/spec/testing.md`
- Create the docs/spec/ directory if it doesn't exist
- Do NOT write implementation code — the spec file is the deliverable
- Do NOT commit any changes
```

---

## Rules

1. **Spawn all agents in the same turn.** Parallelism is the entire point of this skill.
2. **Never write spec files yourself.** You are the orchestrator, not the author.
3. **Never commit.** No `git add`, no `git commit`, no `git push`.
4. **No Docket.** This skill does not use Docket for issue tracking.
5. **No cross-agent dependencies.** All 7 specs are independent — no task blocks another.
6. **Respect the user's choice on existing files.** Honor overwrite/skip/cancel decisions.
7. **Fail loud.** If an agent fails, report it immediately with details.
