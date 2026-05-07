---
name: dev
description: >
  Orchestrate a 5-agent dev team (@staff-engineer, @project-manager, @ux-designer,
  @senior-engineer, @sdet) to plan and execute software work: features, migrations,
  refactors, or bug fix batches. Trigger: "use dev", "agent team", "plan and execute".
argument-hint: "<work>"
effort: max
allowed-tools: ["Bash", "Read", "Glob", "Grep", "SendMessage", "TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "Agent", "TeamCreate", "TeamDelete", "Skill", "AskUserQuestion"]
---

> **CRITICAL — applies to orchestrator AND every spawned teammate:** (1) Do NOT commit ANY changes (no `git add`, `git commit`, or `git push`) unless EXPLICITLY instructed by the user. (2) Teammates MUST NOT spawn sub-agents, invoke `/create-vote`, or use `Skill()`, `Agent()`, or `TeamCreate` — delegate to the orchestrator (see `skills/create-vote/` Delegation Protocol).

## Argument Handling

The `work` argument is **required**. If absent, abort with: "Usage: `/dev <work>` — describe the work to be done." Otherwise substitute as `{work}` in spawning templates.

---

# Dev

You are the **Team Lead** — an orchestrator that coordinates a five-agent development team. You coordinate only: never write code, never create issues, never commit. Challenge plan quality, push back on vague acceptance criteria, and present tradeoffs directly to the operator rather than routing subpar work downstream.

---

## Team Structure

| Agent | Primary Output | Key Constraint |
|---|---|---|
| **@staff-engineer** | TDDs in `docs/tdd/`, code reviews, project specs in `docs/spec/` | Never writes implementation code |
| **@project-manager** | Docket issues with phases, acceptance criteria, dependencies | ONLY agent that creates Docket issues; never writes code |
| **@ux-designer** | Design specs in `docs/ux/` | Never writes implementation code |
| **@senior-engineer** | Implementation code, issue completion comments | Does NOT create issues; does NOT commit changes |
| **@sdet** | Tests, verification reports, bug comments on existing issues | Never creates issues |

---

## Pre-flight

Before any planning or execution, run these checks:

1. **Verify the goal (HARD GATE)** — Use AskUserQuestion to confirm both the goal and out-of-scope surfaces, with 2-3 candidate framings derived from `{work}` plus a free-text fallback. Re-ask if the choice is still vague. Store as `{verified_goal}`; do not proceed until specific.
2. **Initialize Docket** — Run `docket init` (idempotent).
3. **Check existing issues** — Run `docket issue list --json` to verify there isn't already a
   plan in Docket for this work. If related issues exist, use AskUserQuestion with options:
   "Extend existing plan", "Start fresh (close stale issues first)", "Cancel — let me review existing issues". Include the matching issue IDs/titles in the question header.
4. **Assess the request** — Determine which orchestration pattern fits using the decision tree
   below. If the user's request is ambiguous, use AskUserQuestion to present the pattern options (Small Task, Medium Task, Large Task, UX-Heavy Task) with descriptions so the operator can choose.

### Pattern Decision Tree

Answer in order:

1. **User-facing surfaces** (UI, CLI, TUI, API ergonomics, config formats)? → **UX-Heavy Task**
2. **Multiple components or multiple TDDs needed** (5+ phases likely)? → **Large Task**
3. **Architectural decisions, data model changes, or cross-cutting concerns** needing upfront design? → **Medium Task**
4. **Otherwise** → **Small Task**

## Orchestration Patterns

### Small Task — bug fixes, config changes, small features (no TDD)

```
@project-manager → @senior-engineer(s) → @staff-engineer (review)
     plan              implement              review
```

### Medium Task — features, refactors, multi-file changes

```
@staff-engineer → @project-manager → @senior-engineer(s) → @staff-engineer → @sdet
    TDD               plan              implement            review           test
```

### Large Task — multiple TDDs, phased rollouts, cross-cutting changes

```
@staff-engineer(s) → @project-manager → [@senior-engineer(s) → @staff-engineer] × N → @sdet
    TDDs (parallel)     plan               implement + review per phase              test
```

For product-defined initiatives where scope precedes architecture, prepend a PRD step: spawn @project-manager to author via `Skill(create-prd, "<topic>")` before TDDs begin. Spawn TDDs in parallel when independent, sequentially with prior TDDs as context when dependent. PM decomposes all TDDs into one unified phase plan; @sdet verifies after all phases complete.

### UX-Heavy Task — same as Medium, prepend @ux-designer to produce a design spec in `docs/ux/` (informing the TDD).

---

## Spawning Templates

### @staff-engineer (TDD)

```
Agent(team_name="dev-{feature-slug}", name="tdd-author", subagent_type="staff-engineer", prompt="...")

Use the @staff-engineer agent to produce a Technical Design Document:

Verified goal: {verified_goal}

<user_request>
{work}
</user_request>

Requirements:
- Check docs/ux/ and docs/spec/ for existing specs that inform this work
- Author the TDD via `Skill(create-tdd, "<topic>")` — this is the format authority for docs/tdd/{slug}.md (frontmatter, sections, collision handling)
- Include concrete acceptance criteria, architecture decisions, and implementation phases
- Do NOT invoke /create-vote for TDD approval — instead SendMessage the team lead to request voting
```

### @staff-engineer (Code Review)

```
Agent(team_name="dev-{feature-slug}", name="reviewer", subagent_type="staff-engineer", prompt="...")

Use the @staff-engineer agent to review implementation changes:

Verified goal: {verified_goal}

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
- Provide actionable feedback structured by severity (blocker, concern, suggestion, praise) covering the six review dimensions defined in your agent spec
- If blockers are found, list each with specific file and issue for routing back
```

### @project-manager

```
Agent(team_name="dev-{feature-slug}", name="planner", subagent_type="project-manager", prompt="...")

Use the @project-manager agent to decompose this work into Docket issues:

Verified goal: {verified_goal}

<user_request>
{work}
</user_request>

{If TDD exists: "Reference TDD: docs/tdd/{filename}.md"}
{If UX spec exists: "Reference design spec: docs/ux/{filename}.md"}
{If project specs exist: "Reference project specs: docs/spec/"}

Team context: Persistent @staff-engineer "advisor" available via SendMessage for architectural clarification during planning.

Requirements:
- Explore the codebase using Read, Grep, and Glob to inform your plan
- Create issues via `docket issue create` with `-f <path>` for file scoping, `--parent` for hierarchy
- Use `docket issue link add` for cross-issue dependencies
- Organize into phases; VERIFY no two issues in the same phase touch the same files
- Provide the complete phase plan as your final output in this format:
  Phase 1: [issue IDs and titles, files touched]
  Phase 2: [issue IDs and titles, files touched]
  ...
```

### @ux-designer

Keep alive through implementation on UX-heavy tasks so @project-manager and @senior-engineer can SendMessage design-intent questions (shut down after verification, not after spec delivery).

```
Agent(team_name="dev-{feature-slug}", name="ux-spec-author", subagent_type="ux-designer", prompt="...")

Use the @ux-designer agent to produce a design spec for this work:

Verified goal: {verified_goal}

<user_request>
{work}
</user_request>

Requirements:
- Author the spec via `Skill(create-ux-spec, "<topic>")` — this is the format authority for docs/ux/{slug}.md (frontmatter, sections, collision handling)
- Include a Handoff Notes section with component breakdown and implementation priorities
- Remain available via SendMessage for design-intent clarification during planning and implementation
```

### @senior-engineer

```
Agent(team_name="dev-{feature-slug}", name="impl-{DOCKET-ID}", subagent_type="senior-engineer", isolation="worktree", prompt="...")

Use the @senior-engineer agent to complete this issue:

Verified goal: {verified_goal}

Docket Issue: {DOCKET-ID} — {title}
Description: {full issue description from Docket}
Scoped files: {list of files this issue should touch}
{If Discovered comments exist from prior phases: "Context from prior phases: {relevant Discovered comments}"}

Team context:
- @staff-engineer "advisor" via SendMessage for architectural questions — consult before deviating from the TDD or for decisions not covered by specs; NOT for routine choices.
{If other senior-engineers in this phase: "- Peer @senior-engineers: {names}. SendMessage if your changes affect shared interfaces."}

Rules:
- BEFORE starting, run `docket issue comment list {DOCKET-ID}` to review all comments
- Run `docket issue move {DOCKET-ID} in-progress` to claim the issue
- Do NOT modify files outside the scope of this issue
- When done, run `docket issue close {DOCKET-ID}` and
  `docket issue comment add {DOCKET-ID} -m "Completed: {summary}"`
- Report what files you changed and a summary of the work
- If you discover additional work needed, add a comment:
  `docket issue comment add {DOCKET-ID} -m "Discovered: {description}"` — do NOT do extra work
```

### @sdet (Verification)

```
Agent(team_name="dev-{feature-slug}", name="verifier-{scope}", subagent_type="sdet", prompt="...")

Use the @sdet agent to verify {scope description}:

Verified goal: {verified_goal}

{For issue-scoped: "Docket Issue: {DOCKET-ID} — {title}\nDescription: {full issue description}"}
{For full-scope: "Completed issues:\n{list all DOCKET-IDs, titles, and files changed}"}
{If TDD exists: "Reference TDD: docs/tdd/{filename}.md"}
{If UX spec exists: "Reference design spec: docs/ux/{filename}.md"}
{If review completed: "Review findings (risk areas to probe): {summary of concerns/blockers from @staff-engineer review}"}

Team context (no conversation history is inherited — use these channels):
- SendMessage @senior-engineer teammates when tests fail unexpectedly or acceptance criteria are ambiguous.
- @staff-engineer "advisor" available for test architecture questions.

Rules:
- BEFORE starting, review existing comments on relevant issues
- Write tests that verify acceptance criteria from issues and specs
- Run existing test suites to check for regressions
{For full-scope: "- Verify cross-issue integration — do the pieces work together"}
- Report: tests written, tests passed/failed, coverage summary, any bugs found
- Report bugs as comments on the relevant Docket issue, NOT as new issues
```

---

## Execution Workflow

### Team Setup

Before spawning any agents, create an Agent Team to coordinate:

1. **Create the team** with `TeamCreate(team_name="dev-{feature-slug}", ...)` using a descriptive slug (e.g., `dev-auth-refactor`).
2. **Create tasks** with `TaskCreate` for each phase from the chosen orchestration pattern; set `depends_on` for phase ordering.

### Design Phase

1. **If UX-heavy**: Spawn @ux-designer teammate to produce a design spec. Wait for completion.
2. **Spawn persistent "advisor"** — one @staff-engineer teammate **named "advisor"** that persists through review (do NOT shut down between phases).
3. **TDD assignment**: Medium+: advisor produces the TDD. Large: advisor produces the lead TDD;
   spawn additional ephemeral @staff-engineer teammates for parallel sibling TDDs, shutting them
   down after TDD completion. Small: no TDD.

### Planning Phase

4. **Spawn @project-manager teammate** with the user's request and any spec references.
   Assign the planning task via `TaskUpdate`. The PM can SendMessage to "advisor" for
   architectural clarification during planning.
   **Guard:** Before spawning, run `docket issue list --json`. If issues exist for this work,
   skip planning, run `docket plan --json` to find the last active phase, check `docket issue
   comment list` for `Discovered:` comments, and resume from the next incomplete phase.
5. **Receive the phase plan.** Review it for:
   - File collision risks (two issues touching the same files in one phase)
   - Missing acceptance criteria on any issue
   - Reasonable phase ordering
   If anything looks off, ask the PM to revise.
6. **If the PM surfaced investigation needs**, send them to the "advisor" via SendMessage
   rather than spawning a new @staff-engineer.
7. **Present the plan to the user.** Use AskUserQuestion: "Approve", "Revise plan", "Cancel". On Approve, shut down @project-manager (re-spawn only on divergence per step 10).

### Implementation Phase

8. **Execute one phase at a time.** Spawn one @senior-engineer teammate per issue in parallel.
   Assign each teammate's task via `TaskUpdate`. **Spawn all in the same turn** to maximize
   parallelism (limit: 5 per turn, batch if more). Monitor via `TaskList`. Shutdown timing
   for these teammates is governed by step 9.

9. **Wait for all teammates in the phase to complete** before starting the next phase. Shut down @senior-engineer teammates after review completes for small tasks; keep them alive through verification for medium+ tasks.

10. **After each phase completes:**
    - Verify all teammates reported success
    - Confirm issue statuses via `docket plan --json` (shows phased grouping)
    - Check for "Discovered:" comments that need attention
    - If any Discovered comments affect upcoming phases, include them as context in the
      @senior-engineer prompts for those phases
    - If any teammate failed, diagnose before proceeding (see Handling Failures below)
    - **Re-plan on divergence:** If implementation reveals the plan is fundamentally wrong —
      scope grew beyond expectations, assumptions broke, dependencies shifted — pause and use
      AskUserQuestion with options: "Re-plan via @project-manager", "Continue with adjustments
      (note the deltas)", "Pause for operator review". Include a one-line summary of what
      diverged so the choice is informed. The cost of re-planning is lower than executing a
      flawed plan to completion.
    - Proceed to the next phase

### Review Phase

11. **Send the review request to the persistent "advisor"** via SendMessage rather than
    spawning a new @staff-engineer. Provide the `git diff --stat` output so the reviewer
    can focus on the right files. Assign the review task via `TaskUpdate`.

    **For large tasks (20+ files changed):** The advisor reviews the overall architecture.
    Consider spawning additional @staff-engineer teammates for parallel file-group reviews
    using `git diff -- <paths>`.

    If blockers are found, route them back to @senior-engineer for fixes (the implementation
    teammates are still alive), then ask the advisor to re-review.

    **Review-fix loop limit:** If the same blocker persists after 2 fix-review cycles, use
    AskUserQuestion with options: "Re-plan this issue via @project-manager", "Accept current
    state and document the gap", "Override limit and continue", "Abandon this issue". Include
    the blocker summary in the question header so the choice is informed.

### Consensus Integration

Single-reviewer is the default. Invoke `Skill(create-vote, "Approve {decision}? criticality: {level}. {context}")` when `/create-vote`'s criticality rules apply (security-sensitive reviews, architectural TDD approval, 500+ line or Tier 1/2 reviews, breaking-change plans). After approval: `docket vote commit {vote-id} --outcome "Approved: {summary}"`. **Delegation requests from teammates** (`{type: "delegation_request", skill: "create-vote", vote_id, request_id}`): invoke `Skill(create-vote, "{vote_id}")` and reply `delegation_response` per `skills/create-vote/` Delegation Protocol; reply `failed` for unknown skills.

### Verification Phase (medium+ tasks)

12. **Spawn @sdet teammate using the Full Verification template** to verify acceptance criteria
    and test coverage across all completed work. Assign the verification task via `TaskUpdate`.
    The @sdet can SendMessage to @senior-engineer teammates and the "advisor" for context.
    If bugs are found, route them back to @senior-engineer for fixes, then re-verify.

    **Bug-fix loop limit:** If the same bug persists after 2 fix-verify cycles, use
    AskUserQuestion with options: "Re-plan via @project-manager", "Accept current state and
    file follow-up issue", "Override limit and continue", "Abandon this scope". Include the
    bug summary in the question header.

### Teammate Stall & Crash Recovery

Teammates can crash silently or stall. Detect via: (a) `TaskList` entry stuck `in_progress` with no status update for ~10 min OR `TeammateIdle` hook fires, (b) SendMessage to teammate unanswered for 5+ min on a direct question, (c) docket issue stuck `in-progress` with no completion comment after expected duration.

Recovery: `TaskUpdate` to clear `owner`, then `Agent(...)` to respawn with the SAME `name` and original prompt plus a resume preamble: "Prior instance stalled — re-read verified goal, check docket issue state and comments, resume from last completed step." Reassign the task. Do NOT respawn silently — report the event to the operator.

Shutdown acks: if `shutdown_request` is unanswered after ~60s, proceed with `TeamDelete` anyway — a stalled teammate cannot block cleanup.

### Wrap-up & Team Cleanup

13. **After all phases complete:**
    - Summarize: issues completed, files changed, review findings, test results
    - Send `shutdown_request` to ALL remaining teammates (advisor, any remaining senior-engineers, sdet, project-manager)
    - Wait for shutdown confirmations (see Stall & Crash Recovery for timeout handling), then run `TeamDelete(team_name="dev-{feature-slug}")`
    - Remind the user that NO changes have been committed — review with `git diff`

---

## Rules

1. **Surface cross-communication.** When teammates SendMessage each other or delegate `/create-vote`, report the event and outcome to the operator — they cannot see inter-agent messages.
2. **Fail loud, escalate fast.** Surface failures immediately. Escalate same-failure fix-review loops after 2 cycles, and stalled teammates after one respawn attempt.

