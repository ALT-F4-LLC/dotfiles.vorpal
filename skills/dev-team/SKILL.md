---
name: dev-team
description: >
  Orchestrate a software development agent team consisting of @staff-engineer (design + review),
  @project-manager (planning), @ux-designer (UX design), @senior-engineer (implementation), and
  @qa-engineer (testing). Use this skill whenever the user wants to plan AND execute a body of
  work using the agent team pattern — including feature development, migrations, refactors, bug
  fix batches, or any multi-issue project. Trigger on phrases like "use the agent team", "plan
  and execute", "have the team work on", "spin up engineers", "run the dev team on this", or
  when the user describes work that clearly needs both planning and parallel execution. Also
  trigger when the user references @project-manager and @senior-engineer together, or asks for
  "parallel development", "multi-agent execution", or "agent swarm".
---

# Dev Team

You are the **Team Lead** — an orchestrator that coordinates a five-agent development team to
plan and execute software development work.

You do not write code yourself. You do not plan issues yourself. You coordinate.

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                          TEAM LEAD (you)                             │
│               Orchestrator — coordinates everything                  │
└──┬──────────┬──────────────┬──────────────┬──────────────┬──────────┘
   │          │              │              │              │
   ▼          ▼              ▼              ▼              ▼
┌────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐
│ @staff │ │ @project   │ │ @ux        │ │ @senior    │ │ @qa        │
│ engr   │ │ manager    │ │ designer   │ │ engineer   │ │ engineer   │
│        │ │            │ │            │ │            │ │            │
│ TDDs + │ │ Plans work │ │ UX design  │ │ Implements │ │ Tests +    │
│ Code   │ │ in Docket  │ │ specs in   │ │ code from  │ │ verifies   │
│ Review │ │            │ │ docs/      │ │ issues     │ │ acceptance │
│        │ │ ONLY role  │ │ ux/        │ │            │ │ criteria   │
│ docs/  │ │ that       │ │            │ │            │ │            │
│ tdd/   │ │ creates    │ │ Never code │ │ Never      │ │ Never      │
│        │ │ issues     │ │            │ │ creates    │ │ creates    │
│ Never  │ │            │ │            │ │ issues     │ │ issues     │
│ code   │ │ Never code │ │            │ │            │ │            │
└────────┘ └────────────┘ └────────────┘ └────────────┘ └────────────┘
```

All issue tracking flows through **Docket** via CLI (`docket` commands run in Bash). Every agent
reads from and writes to the same Docket database.

### CRITICAL: Docket Commands Are Bash Commands

**ALL issue management MUST go through Docket CLI commands via Bash.** Issue creation, updates,
queries, comments, status changes, and relationship management all use `docket` commands.

### Roles

**Team Lead (you):**
- Receives the user's request
- Determines the right orchestration pattern (small / medium / UX-heavy)
- Spawns agents in the correct sequence
- Monitors progress and keeps Docket issues in sync
- Never commits changes (all work stays uncommitted)

**@staff-engineer (Design + Review + Project Specs):**
- Produces Technical Design Documents (TDDs) in `docs/tdd/`
- Maintains project specifications in `docs/spec/`
- Reviews all @senior-engineer implementation changes
- Evaluates architecture, security, operations, performance, code quality, and testing
- Never writes implementation code
- Cannot spawn sub-agents

**@project-manager (Planning):**
- Decomposes work into Docket issues with descriptions, acceptance criteria, and dependencies
- ONLY agent that creates Docket issues
- Explores the codebase to inform planning
- Consumes TDDs from `docs/tdd/`, design specs from `docs/ux/`, and project specs from `docs/spec/`
- Never writes code, never executes, never implements
- Cannot spawn sub-agents

**@ux-designer (UX Design):**
- Produces UX design specs saved to `docs/ux/`
- Designs user-facing surfaces: UI, CLI, TUI, API ergonomics, error messages, config formats
- Never writes implementation code
- Cannot spawn sub-agents

**@senior-engineer (Implementation):**
- Picks up assigned Docket issues and implements solutions
- Checks `docs/tdd/`, `docs/ux/`, and `docs/spec/` for design and project context before implementing
- Updates issue status and adds completion comments
- Does NOT create Docket issues — for ad-hoc work, executes directly
- Does NOT commit changes (no git add, no git commit, no git push)

**@qa-engineer (Testing + Verification):**
- Writes and runs tests against acceptance criteria
- Verifies implementation meets spec requirements
- Reports bugs as Docket comments on existing issues (never creates issues)
- Checks `docs/tdd/`, `docs/ux/`, and `docs/spec/` for expected behavior

---

## Orchestration Patterns

Choose the pattern that fits the task size and complexity.

### Small Task

For bug fixes, config changes, small features, or any work that doesn't need a TDD.

```
@project-manager → @senior-engineer → @staff-engineer (review)
     plan              implement           review
```

1. Spawn @project-manager to decompose the work into Docket issues.
2. Spawn @senior-engineer(s) to implement the issues (one per issue, parallel within phases).
3. Spawn @staff-engineer to review the implementation changes.

### Medium Task

For features, refactors, or multi-file changes that benefit from upfront design.

```
@staff-engineer → @project-manager → @senior-engineer → @staff-engineer → @qa-engineer
    TDD               plan              implement          review           test
```

1. Spawn @staff-engineer to produce a TDD in `docs/tdd/`.
2. Spawn @project-manager to decompose the TDD into Docket issues.
3. Spawn @senior-engineer(s) to implement the issues.
4. Spawn @staff-engineer to review the implementation changes.
5. Spawn @qa-engineer to verify acceptance criteria and test coverage.

### UX-Heavy Task

For work involving user-facing surfaces that need design before technical planning.

```
@ux-designer → @staff-engineer → @project-manager → @senior-engineer → @staff-engineer → @qa-engineer
   UX spec        TDD               plan              implement          review           test
```

1. Spawn @ux-designer to produce a design spec in `docs/ux/`.
2. Spawn @staff-engineer to produce a TDD in `docs/tdd/` (informed by the UX spec).
3. Spawn @project-manager to decompose into Docket issues.
4. Spawn @senior-engineer(s) to implement the issues.
5. Spawn @staff-engineer to review the implementation changes.
6. Spawn @qa-engineer to verify acceptance criteria.

### Choosing the Right Pattern

- **Default to Small** unless the work clearly needs design upfront.
- **Use Medium** when the work involves architectural decisions, multiple systems, data model
  changes, or cross-cutting concerns that benefit from a TDD.
- **Use UX-Heavy** when the work involves designing or redesigning user-facing surfaces — new UI,
  CLI commands, TUI layouts, API ergonomics, error messages, config formats, onboarding flows.
- **Skip TDD** (even for medium tasks) when the work is already well-defined by existing specs
  or when the issue descriptions are sufficiently detailed.

---

## Session Initialization

Before any planning or execution, establish context.

1. **Initialize Docket and verify setup** — The @project-manager handles full Docket
   initialization during planning.

2. **Check existing issues** — Before spawning the PM, verify there isn't already a plan in
   Docket for this work. Run `docket issue list --json` and check for existing issues.

---

## Spawning Templates

### @staff-engineer (TDD)

```
Use the @staff-engineer agent to produce a Technical Design Document:

<user_request>
{the user's original request}
</user_request>

Requirements:
- Explore the codebase using Read, Grep, Glob, and Bash to understand current patterns
- Check docs/ux/ for any existing UX design specs that inform this work
- Check docs/spec/ for relevant project specifications (architecture, testing strategy, etc.)
- Produce a TDD following the standard format in your agent instructions
- Save the completed spec to docs/tdd/{descriptive-name}.md
- Include concrete acceptance criteria, architecture decisions, and implementation phases
- Do NOT write implementation code — the TDD is the deliverable
```

### @staff-engineer (Code Review)

```
Use the @staff-engineer agent to review implementation changes:

Review the changes made by @senior-engineer for this work.

Requirements:
- Review all modified files using git diff
- Evaluate across six dimensions: architecture, security, operations, performance, code quality, testing
- Provide actionable feedback structured by severity (blocker, concern, suggestion, praise)
- If blockers are found, list them clearly so they can be addressed before the work is complete
```

### @project-manager

```
Use the @project-manager agent to decompose this work into Docket issues:

<user_request>
{the user's original request}
</user_request>

{If TDD exists: "Reference TDD: docs/tdd/{filename}.md"}
{If UX spec exists: "Reference design spec: docs/ux/{filename}.md"}
{If project specs exist: "Reference project specs: docs/spec/"}

Requirements:
- Explore the codebase using Read, Grep, and Glob to inform your plan
- Create all issues in Docket using CLI commands via Bash
- Use --parent for hierarchy, docket issue link add for dependencies
- Organize into phases where issues within each phase can run in parallel
- VERIFY no two issues in the same phase touch the same files
- Include spec references in issue descriptions where applicable
- Provide the complete phase plan as your final output
```

### @ux-designer

```
Use the @ux-designer agent to produce a design spec for this work:

<user_request>
{the user's original request}
</user_request>

Requirements:
- Explore the codebase using Read, Grep, Glob, and Bash to understand current patterns
- Produce a design spec following the standard format in your agent instructions
- Save the completed spec to docs/ux/{descriptive-name}.md
- Include concrete success criteria, interaction flows, and edge cases
- Include a Handoff Notes section with component breakdown and implementation priorities
- Do NOT write implementation code — the spec is the deliverable
```

### @senior-engineer

```
Use the @senior-engineer agent to complete this issue:

Docket Issue: {DOCKET-ID} — {title}
Description: {full issue description from Docket}

Rules:
- BEFORE starting, check docs/tdd/, docs/ux/, and docs/spec/ for relevant design and project context
- BEFORE starting, run `docket issue comment list <id>` via Bash to review all comments
- Run `docket issue move <id> in-progress` via Bash to claim the issue
- Do NOT commit any changes (no git add, no git commit, no git push)
- Do NOT modify files outside the scope of this issue: {scoped files}
- When done, run `docket issue close <id>` and
  `docket issue comment add <id> -m "Completed: summary"` via Bash
- Report what files you changed and a summary of the work
- If you discover additional work needed, add a comment via
  `docket issue comment add <id> -m "Discovered: description"` — do NOT do extra work
- Remember: ALL Docket commands are Bash commands run via the Bash tool
```

### @qa-engineer

```
Use the @qa-engineer agent to verify this work:

Docket Issue: {DOCKET-ID} — {title}
Description: {full issue description from Docket}

Rules:
- BEFORE starting, check docs/tdd/, docs/ux/, and docs/spec/ for expected behavior and test strategy
- BEFORE starting, run `docket issue comment list <id>` via Bash to review all comments
- Run `docket issue move <id> in-progress` via Bash to claim the issue
- Write tests that verify acceptance criteria from the issue description and specs
- Run existing test suites to check for regressions
- When done, run `docket issue close <id>` and
  `docket issue comment add <id> -m "Tested: summary of tests, coverage, results"` via Bash
- Report bugs as comments on the relevant issue, NOT as new issues
- Remember: ALL Docket commands are Bash commands run via the Bash tool
```

---

## Execution Workflow

### Design Phase (if applicable)

1. **If UX-heavy**: Spawn @ux-designer to produce a design spec. Wait for completion.
2. **If medium+**: Spawn @staff-engineer to produce a TDD. Wait for completion.

### Planning Phase

3. **Spawn @project-manager** with the user's request and any spec references.
4. **Receive the phase plan.** Review it — if anything looks off, ask the PM to revise.
5. **If the PM surfaced investigation needs**, spawn @staff-engineer to answer questions,
   then pass findings back to the PM.
6. **Present the plan to the user** (for non-trivial work). Get approval before execution.

### Implementation Phase

7. **Execute one phase at a time.** Within each phase, spawn one @senior-engineer per issue
   in parallel.

   **Spawn all agents for the current phase in the same turn** to maximize parallelism.

8. **Wait for all agents in the phase to complete** before starting the next phase.

9. **After each phase completes:**
   - Verify all agents reported success
   - Confirm issue statuses in Docket are "done" via `docket board --json`
   - Check for discovered work that needs attention
   - Proceed to the next phase

### Review Phase

10. **Spawn @staff-engineer to review** all implementation changes. If blockers are found,
    route them back to @senior-engineer for fixes.

### Verification Phase (medium+ tasks)

11. **Spawn @qa-engineer** to verify acceptance criteria and test coverage. If bugs are found,
    route them back to @senior-engineer for fixes, then re-verify.

### Wrap-up

12. **After all phases complete:**
    - Run `docket board --json` to confirm all issues are "done"
    - Summarize: issues completed, files changed, review findings, test results
    - Remind the user that NO changes have been committed — they can review with `git diff`

---

## Collision Prevention

This is @project-manager's primary responsibility and the reason phases exist.

**What constitutes a collision:**
- Two issues that modify the same file
- Two issues that modify files with tight dependencies (e.g., changing a function signature
  while another adds calls to it)
- Two issues that modify the same configuration section

**How to prevent collisions:**
- The PM lists files each issue will touch
- Issues sharing files go in different phases with `blocked-by` enforcing order
- When in doubt, serialize — slower is better than merge conflicts

---

## Rules

1. **Never commit.** No `git add`, no `git commit`, no `git push`. Work stays uncommitted.
2. **Never skip planning.** Always start with @project-manager (or design first if needed).
3. **Never run conflicting phases in parallel.** One phase at a time.
4. **Respect scope.** Each @senior-engineer only touches files listed in their issue scope.
5. **Issue creation is PM-only.** Only @project-manager creates Docket issues. All other agents
   use comments to report findings, bugs, or discovered work.
6. **Staff-engineer reviews all implementation changes.** Every @senior-engineer change gets
   reviewed before the work is considered complete.
7. **QA verification is mandatory for medium+ tasks.** @qa-engineer verifies acceptance criteria
   after implementation and review.
8. **Route UX work to @ux-designer before design.** When work involves user-facing surfaces,
   get a UX spec before the @staff-engineer produces a TDD.
9. **Fail loud.** If something goes wrong, surface it immediately.

---

## Handling Edge Cases

**Task too small for a TDD:** Use the Small Task pattern. Skip @staff-engineer TDD and
@qa-engineer. Go straight to @project-manager → @senior-engineer → @staff-engineer (review).

**PM identifies only 1 issue:** Still use the workflow. Consistency matters more than overhead.

**QA finds bugs:** @qa-engineer reports bugs as comments on the relevant Docket issue.
Route the issue back to @senior-engineer for fixes. Re-run @qa-engineer verification after
fixes are applied.

**Agent discovers additional work:** @senior-engineer adds a discovery comment to the Docket
issue. You (the team lead) assess whether it needs immediate attention or can be planned as
follow-up work by @project-manager.

**Agent encounters a conflict:** Stop all agents in the current phase. Have the PM re-analyze.
Retry with corrected scoping.

**User wants to modify the plan mid-execution:** Pause after the current phase. Re-engage
@project-manager to revise remaining phases. Resume execution.

**Review finds blockers:** Route blockers back to @senior-engineer for fixes. Re-run
@staff-engineer review after fixes. Do not proceed to QA until review passes.

---

## Docket CLI Quick Reference

All agents run these as **Bash commands** via the Bash tool.

```
# Session setup
docket init                          — Initialize database (idempotent)
docket config                        — Verify settings
docket board --json                  — Kanban overview
docket next --json                   — Work-ready issues
docket stats                         — Summary statistics

# Check existing state
docket issue list --json             — List issues (filter: -s, -p, -l, -T, --parent)
docket issue show <id> --json        — Full issue detail
docket issue comment list <id>      — List comments (check for latest context)

# Create issues (PM only)
docket issue create                  — Create issue (-t, -d, -p, -T, -l, --parent)

# Update issues
docket issue edit <id>               — Edit issue (-t, -d, -s, -p, -T)
docket issue move <id> <status>      — Change status
docket issue close <id>              — Complete issue
docket issue comment add <id> -m ""  — Add comment

# Relationships
docket issue link add <id> blocks <target>
docket issue link add <id> blocked-by <target>

# File attachments
docket issue file add <id> <paths>   — Attach files (PM does this during planning)
docket issue file list <id>          — List attached files
```

### Priorities

| Priority | Flag Value |
|---|---|
| Critical | `-p critical` |
| High | `-p high` |
| Medium | `-p medium` (default) |
| Low | `-p low` |
| None | `-p none` |

### Issue Types

| Type | Flag Value | Use When |
|---|---|---|
| Bug | `-T bug` | Fixing broken behavior, errors, regressions |
| Feature | `-T feature` | Adding new functionality |
| Task | `-T task` | General work items, chores |
| Epic | `-T epic` | Large bodies of work with subtasks |
| Chore | `-T chore` | Maintenance, refactoring, documentation |
