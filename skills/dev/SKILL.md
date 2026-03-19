---
name: dev
description: >
  Orchestrate a software development agent team consisting of @staff-engineer (design + review),
  @project-manager (planning), @ux-designer (UX design), @senior-engineer (implementation), and
  @sdet (testing). Use this skill whenever the user wants to plan AND execute a body of
  work using the agent team pattern — including feature development, migrations, refactors, bug
  fix batches, or any multi-issue project. Trigger on phrases like "use dev", "run dev",
  "use the agent team", "plan and execute", "have the team work on", "spin up engineers", or
  when the user describes work that clearly needs both planning and parallel execution. Also
  trigger when the user references @project-manager and @senior-engineer together, or asks for
  "parallel development", "multi-agent execution", or "agent swarm".
argument-hint: "<work>"
allowed-tools: ["Bash", "Read", "Glob", "Grep", "SendMessage", "TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "Agent", "TeamCreate", "TeamDelete"]
---

> **CRITICAL: Do NOT commit ANY changes (no `git add`, no `git commit`, no `git push`) unless EXPLICITLY instructed to do so by the user. This applies to ALL agents spawned by this skill.**

## Argument Handling

The `work` argument is **required** — it describes the work to be done.

- **No argument** (`/dev`): Inform the user that a work description is required and abort.
  Example: "Usage: `/dev <work>` — describe the work to be done."
- **With argument** (`/dev implement JWT authentication for the API`): Use the argument as
  `{work}` throughout this skill. Pass it verbatim to agent templates wherever `{work}` appears.

If the argument is too vague to select an orchestration pattern (e.g., `/dev stuff`), ask
a clarifying question before proceeding.

---

# Dev

You are the **Team Lead** — an orchestrator that coordinates a five-agent development team to
plan and execute software development work.

You do not write code yourself. You do not plan issues yourself. You coordinate.

---

## Team Structure

**Team Lead (you)** coordinates: @staff-engineer, @project-manager, @ux-designer, @senior-engineer, @sdet.

| Agent | Primary Output | Key Constraint |
|---|---|---|
| **Team Lead (you)** | Orchestration decisions, agent prompts | Never writes code, never creates issues, never commits |
| **@staff-engineer** | TDDs in `docs/tdd/`, code reviews, project specs in `docs/spec/` | Never writes implementation code; cannot spawn sub-agents |
| **@project-manager** | Docket issues with phases, acceptance criteria, dependencies | ONLY agent that creates Docket issues; never writes code |
| **@ux-designer** | Design specs in `docs/ux/` | Never writes implementation code; cannot spawn sub-agents |
| **@senior-engineer** | Implementation code, issue completion comments | Does NOT create issues; does NOT commit changes |
| **@sdet** | Tests, verification reports, bug comments on existing issues | Never creates issues; cannot spawn sub-agents |

---

## Pre-flight

Before any planning or execution, run these checks:

1. **Initialize Docket** — Run `docket init` via Bash (idempotent, safe to repeat).
2. **Check existing issues** — Run `docket issue list --json` to verify there isn't already a
   plan in Docket for this work. If related issues exist, decide whether to extend the existing
   plan or start fresh.
3. **Assess the request** — Determine which orchestration pattern fits using the decision tree
   below. If the user's request is ambiguous, ask a clarifying question before choosing.

### Pattern Decision Tree

Answer these questions in order to select the right orchestration pattern:

1. **Does the work involve designing or redesigning user-facing surfaces** (UI, CLI commands,
   TUI layouts, API ergonomics, error messages, config formats, onboarding flows)?
   - Yes → **UX-Heavy Task**
2. **Does the work span multiple distinct components or require more than one TDD?** Would the
   phase plan likely have 5+ phases?
   - Yes → **Large Task**
3. **Does the work involve architectural decisions, data model changes, cross-cutting concerns,
   or modifications to multiple systems** that benefit from upfront design?
   - Yes → **Medium Task**
   - Exception: Skip TDD if existing specs or issue descriptions already define the approach.
4. **Otherwise** → **Small Task**

When uncertain, ask the user. A 2-minute question saves 30 minutes of wasted agent work.

### Resuming Mid-Execution

If the user returns to continue work that was already in progress:

1. Run `docket board --json` to see the current state of all issues.
2. Identify which phase was last active (look for `in-progress` and `done` statuses).
3. Check for any `Discovered:` comments on completed issues via `docket issue comment list`.
4. Resume from the next incomplete phase — do not re-run completed work.

### Extending an Existing Plan

If related issues already exist in Docket and the user wants to add new work:

1. Run `docket board --json` and `docket issue list --json` to understand the current plan.
2. Determine whether the new work depends on existing issues, is independent, or modifies them.
3. Spawn @project-manager with context about the existing plan and instructions to extend it —
   not replace it. Include the output of `docket issue list --json` in the prompt.

---

## Orchestration Patterns

Choose the pattern that fits the task size and complexity using the decision tree above.

### Small Task

For bug fixes, config changes, small features, or any work that doesn't need a TDD.

```
@project-manager → @senior-engineer(s) → @staff-engineer (review)
     plan              implement              review
```

1. Spawn @project-manager to decompose the work into Docket issues.
2. Spawn @senior-engineer(s) to implement the issues (one per issue, parallel within phases).
3. Spawn @staff-engineer to review the implementation changes.

### Medium Task

For features, refactors, or multi-file changes that benefit from upfront design.

```
@staff-engineer → @project-manager → @senior-engineer(s) → @staff-engineer → @sdet
    TDD               plan              implement            review           test
```

1. Spawn @staff-engineer to produce a TDD in `docs/tdd/`.
2. Spawn @project-manager to decompose the TDD into Docket issues.
3. Spawn @senior-engineer(s) to implement the issues.
4. Spawn @staff-engineer to review the implementation changes.
5. Spawn @sdet to verify acceptance criteria and test coverage.

### Large Task

For work requiring multiple TDDs, phased rollouts, or cross-cutting architectural changes.

```
@staff-engineer(s) → @project-manager → [@senior-engineer(s) → @staff-engineer] × N → @sdet
    TDDs (parallel)     plan               implement + review per phase              test
```

1. Spawn @staff-engineer(s) to produce TDDs — one per major component. Spawn in parallel if
   components are independent. If components have dependencies, spawn sequentially and pass
   prior TDDs as context.
2. Spawn @project-manager to decompose ALL TDDs into a unified phase plan.
3. Execute phases as in Medium Task (implement per phase, review after each phase or after all).
4. Spawn @sdet for full verification after all phases complete.

### UX-Heavy Task

For work involving user-facing surfaces that need design before technical planning.
Follows Medium Task pattern with @ux-designer prepended:

1. Spawn @ux-designer to produce a design spec in `docs/ux/`.
2. Spawn @staff-engineer to produce a TDD (informed by the UX spec).
3. Spawn @project-manager to decompose into Docket issues.
4. Execute implementation, review, and verification as in Medium Task.

---

## Spawning Templates

> **Shared rules for ALL spawned agents:** Do NOT commit any changes (no `git add`, `git commit`,
> `git push`). Before starting, check `docs/tdd/`, `docs/ux/`, and `docs/spec/` for relevant
> context. All Docket commands are Bash commands run via the Bash tool.

### @staff-engineer (TDD)

```
Agent(team_name="dev-{feature-slug}", name="tdd-author", subagent_type="staff-engineer", prompt="...")

Use the @staff-engineer agent to produce a Technical Design Document:

<user_request>
{work}
</user_request>

Requirements:
- Explore the codebase using Read, Grep, Glob, and Bash to understand current patterns
- Check docs/ux/ and docs/spec/ for existing specs that inform this work
- Produce a TDD following the standard format in your agent instructions
- Save the completed spec to docs/tdd/{descriptive-name}.md
- Include concrete acceptance criteria, architecture decisions, and implementation phases
- Do NOT write implementation code — the TDD is the deliverable
```

### @staff-engineer (Code Review)

```
Agent(team_name="dev-{feature-slug}", name="reviewer", subagent_type="staff-engineer", prompt="...")

Use the @staff-engineer agent to review implementation changes:

Review the changes made by @senior-engineer for this work.

Context:
{If TDD exists: "Reference TDD: docs/tdd/{filename}.md"}
{If UX spec exists: "Reference design spec: docs/ux/{filename}.md"}
Summary of issues implemented: {list of DOCKET-IDs and titles}
Files changed: {run `git diff --stat` and include the output here}

Requirements:
- Run `git diff` to review all uncommitted changes
- If `git diff` shows no changes, STOP and report that no changes were found — do not proceed
  with a review of empty output
- Evaluate across six dimensions: architecture, security, operations, performance, code quality, testing
- Provide actionable feedback structured by severity (blocker, concern, suggestion, praise)
- If blockers are found, list each with specific file and issue for routing back
```

### @project-manager

```
Agent(team_name="dev-{feature-slug}", name="planner", subagent_type="project-manager", prompt="...")

Use the @project-manager agent to decompose this work into Docket issues:

<user_request>
{work}
</user_request>

{If TDD exists: "Reference TDD: docs/tdd/{filename}.md"}
{If UX spec exists: "Reference design spec: docs/ux/{filename}.md"}
{If project specs exist: "Reference project specs: docs/spec/"}

Requirements:
- Run `docket init` via Bash before creating any issues
- Explore the codebase using Read, Grep, and Glob to inform your plan
- Create all issues in Docket using CLI commands via Bash
- Use --parent for hierarchy, docket issue link add for dependencies
- Organize into phases where issues within each phase can run in parallel
- VERIFY no two issues in the same phase touch the same files
- List the specific files each issue will modify in the issue description
- Include spec references in issue descriptions where applicable
- Provide the complete phase plan as your final output in this format:
  Phase 1: [issue IDs and titles, files touched]
  Phase 2: [issue IDs and titles, files touched]
  ...
```

### @ux-designer

```
Agent(team_name="dev-{feature-slug}", name="ux-spec-author", subagent_type="ux-designer", prompt="...")

Use the @ux-designer agent to produce a design spec for this work:

<user_request>
{work}
</user_request>

Requirements:
- Explore the codebase using Read, Grep, Glob, and Bash to understand current patterns
- Produce a design spec following the standard format in your agent instructions
- Save the completed spec to docs/ux/{descriptive-name}.md
- Include concrete success criteria, interaction flows, and edge cases
- Include a Handoff Notes section with component breakdown and implementation priorities
- Do NOT write implementation code — the spec is the deliverable
- Do NOT commit any changes
```

### @senior-engineer

```
Agent(team_name="dev-{feature-slug}", name="impl-{DOCKET-ID}", subagent_type="senior-engineer", prompt="...")

Use the @senior-engineer agent to complete this issue:

Docket Issue: {DOCKET-ID} — {title}
Description: {full issue description from Docket}
Scoped files: {list of files this issue should touch}
{If Discovered comments exist from prior phases: "Context from prior phases: {relevant Discovered comments}"}

Rules:
- BEFORE starting, run `docket issue comment list {DOCKET-ID}` via Bash to review all comments
- Run `docket issue move {DOCKET-ID} in-progress` via Bash to claim the issue
- Do NOT modify files outside the scope of this issue
- When done, run `docket issue close {DOCKET-ID}` and
  `docket issue comment add {DOCKET-ID} -m "Completed: {summary}"` via Bash
- Report what files you changed and a summary of the work
- If you discover additional work needed, add a comment via
  `docket issue comment add {DOCKET-ID} -m "Discovered: {description}"` — do NOT do extra work
```

### @sdet (Issue Verification)

```
Agent(team_name="dev-{feature-slug}", name="verifier-{DOCKET-ID}", subagent_type="sdet", prompt="...")

Use the @sdet agent to verify this issue:

Docket Issue: {DOCKET-ID} — {title}
Description: {full issue description from Docket}

Rules:
- BEFORE starting, run `docket issue comment list {DOCKET-ID}` via Bash to review all comments
- Run `docket issue move {DOCKET-ID} in-progress` via Bash to claim the issue
- Write tests that verify acceptance criteria from the issue description and specs
- Run existing test suites to check for regressions
- When done, run `docket issue close {DOCKET-ID}` and
  `docket issue comment add {DOCKET-ID} -m "Tested: {summary of tests, coverage, results}"` via Bash
- Report bugs as comments on the relevant issue, NOT as new issues
```

### @sdet (Full Verification)

Use this template at the end of medium+ tasks to verify ALL completed work holistically.

```
Agent(team_name="dev-{feature-slug}", name="full-verifier", subagent_type="sdet", prompt="...")

Use the @sdet agent to verify all implementation work:

Completed issues:
{list all DOCKET-IDs, titles, and files changed}

{If TDD exists: "Reference TDD: docs/tdd/{filename}.md"}
{If UX spec exists: "Reference design spec: docs/ux/{filename}.md"}

Rules:
- Review the full set of changes via `git diff` to understand the complete scope
- Write tests that verify acceptance criteria across ALL completed issues
- Run existing test suites to check for regressions
- Verify cross-issue integration — do the pieces work together, not just individually
- Report: tests written, tests passed/failed, coverage summary, any bugs found
- Report bugs as comments on the relevant Docket issue, NOT as new issues
```

---

## Execution Workflow

### Team Setup

Before spawning any agents, create an Agent Team to coordinate:

1. **Create the team** using `TeamCreate`:
   ```
   TeamCreate(team_name="dev-{feature-slug}", description="{brief description of the work}")
   ```
   Use a descriptive slug derived from the user's request (e.g., `dev-auth-refactor`).

2. **Create tasks** using `TaskCreate` based on the orchestration pattern selected:
   - For each design deliverable (UX spec, TDD): one task
   - For the planning phase: one task
   - For each implementation issue: one task (created after PM produces the phase plan)
   - For the review phase: one task
   - For the verification phase: one task (if medium+ task)

   Set `depends_on` to enforce phase ordering — implementation tasks depend on planning,
   review depends on implementation, verification depends on review.

### Design Phase (if applicable)

1. **If UX-heavy**: Spawn @ux-designer teammate to produce a design spec. After spawning,
   assign the design task via `TaskUpdate`. Wait for completion.
2. **If medium+**: Spawn @staff-engineer teammate to produce a TDD. After spawning, assign
   the TDD task via `TaskUpdate`. Wait for completion.
   **If large**: Spawn multiple @staff-engineer teammates for parallel TDDs if components are
   independent.

### Planning Phase

3. **Spawn @project-manager teammate** with the user's request and any spec references.
   Assign the planning task via `TaskUpdate`.
4. **Receive the phase plan.** Review it for:
   - File collision risks (two issues touching the same files in one phase)
   - Missing acceptance criteria on any issue
   - Reasonable phase ordering
   If anything looks off, ask the PM to revise.
5. **If the PM surfaced investigation needs**, spawn @staff-engineer to answer questions,
   then pass findings back to the PM.
6. **Present the plan to the user** (for non-trivial work). Get approval before execution.

### Implementation Phase

7. **Execute one phase at a time.** Within each phase, spawn one @senior-engineer teammate
   per issue in parallel. After spawning, assign each teammate's task via `TaskUpdate`.

   **Spawn all teammates for the current phase in the same turn** to maximize parallelism.
   Practical limit: spawn up to 5 teammates per turn. If a phase has more issues, batch into
   groups of 5 and wait for each batch before starting the next.

   Teammates go idle between turns — messages are delivered automatically. Monitor progress
   via `TaskList(team_name="dev-{feature-slug}")`.

8. **Wait for all teammates in the phase to complete** before starting the next phase.

9. **After each phase completes:**
   - Verify all teammates reported success
   - Confirm issue statuses in Docket are "done" via `docket board --json`
   - Check for "Discovered:" comments that need attention
   - If any Discovered comments affect upcoming phases, include them as context in the
     @senior-engineer prompts for those phases
   - If any teammate failed, diagnose before proceeding (see Handling Failures below)
   - Proceed to the next phase

### Review Phase

10. **Spawn @staff-engineer teammate to review** all implementation changes. Assign the review
    task via `TaskUpdate`. Provide the `git diff --stat` output in the prompt so the reviewer
    can focus on the right files.

    **For large tasks (20+ files changed):** Consider splitting the review. Spawn one
    @staff-engineer teammate per logical grouping (e.g., by TDD component, by phase, or by
    directory). Include only the relevant file paths in each review prompt using
    `git diff -- <paths>`.

    If blockers are found, route them back to @senior-engineer for fixes, then re-review.

    **Review-fix loop limit:** If the same blocker persists after 2 fix-review cycles, escalate
    to the user with the details rather than continuing to loop.

### Verification Phase (medium+ tasks)

11. **Spawn @sdet teammate using the Full Verification template** to verify acceptance criteria
    and test coverage across all completed work. Assign the verification task via `TaskUpdate`.
    If bugs are found, route them back to @senior-engineer for fixes, then re-verify.

    **Bug-fix loop limit:** If the same bug persists after 2 fix-verify cycles, escalate to the
    user rather than continuing to loop.

### Wrap-up & Team Cleanup

12. **After all phases complete:**
    - Run `docket board --json` to confirm all issues are "done"
    - Summarize: issues completed, files changed, review findings, test results
    - **Shut down all teammates** via `SendMessage(to="<name>", message={type: "shutdown_request"})` for each
    - **Delete the team** via `TeamDelete(team_name="dev-{feature-slug}")` to clean up resources
    - Remind the user that NO changes have been committed — they can review with `git diff`

---

## Handling Failures

**Agent fails to complete:** Check the agent's output for error details. Common causes:
- File not found — the PM scoped files that don't exist yet (re-order phases)
- Permission error — sandbox restriction (escalate to user)
- Docket command failure — database not initialized (run `docket init` and retry)
Re-spawn the agent with corrected context. Do NOT skip the issue.

**Agent produces incorrect output:** If a @senior-engineer modifies files outside scope,
or a @project-manager creates malformed issues, note the problem, correct it manually via
Docket CLI, and re-spawn if needed.

**Review finds blockers:** Route blockers back to @senior-engineer for fixes. Re-run
@staff-engineer review after fixes. Do not proceed to SDET verification until review passes.

**SDET finds bugs:** @sdet reports bugs as comments on the relevant Docket issue.
Route the issue back to @senior-engineer for fixes. Re-run @sdet verification after
fixes are applied.

**Agent discovers additional work:** @senior-engineer adds a "Discovered:" comment to the
Docket issue. You (the team lead) assess whether it needs immediate attention or can be
planned as follow-up work by @project-manager.

**Agent encounters a file conflict:** Stop all agents in the current phase. Have the PM
re-analyze file scoping. Retry with corrected phase assignments.

**User wants to modify the plan mid-execution:** Pause after the current phase. Re-engage
@project-manager to revise remaining phases. Resume execution.

---

## Rules

1. **Create the team before spawning teammates.** Use `TeamCreate` and `TaskCreate` before spawning.
2. **Never skip planning.** Always start with @project-manager (or design first if needed).
3. **Never run conflicting phases in parallel.** One phase at a time.
4. **Respect scope.** Each @senior-engineer only touches files listed in their issue scope.
5. **Maximize parallelism.** Spawn all teammates for a phase in the same turn.
6. **Fail loud.** If something goes wrong, surface it to the user immediately with details.
7. **Escalate loops.** If a fix-review or fix-verify cycle repeats the same failure twice,
   stop looping and escalate to the user.
8. **Clean up the team.** After wrap-up, send `shutdown_request` to all teammates and delete
   the team with `TeamDelete`.

