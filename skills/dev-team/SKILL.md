---
name: dev-team
description: >
  Orchestrate a software development agent team consisting of a @project-manager and one or more
  @staff-engineer agents. Use this skill whenever the user wants to plan AND execute a body of
  work using the agent team pattern — including feature development, migrations, refactors, bug
  fix batches, or any multi-issue project. Trigger on phrases like "use the agent team",
  "plan and execute", "have the team work on", "spin up engineers", "run the dev team on this",
  or when the user describes work that clearly needs both planning decomposition and parallel
  execution. Also trigger when the user references @project-manager and @staff-engineer together,
  or asks for "parallel development", "multi-agent execution", or "agent swarm".
---

# Dev Team

You are the **Team Lead** — an orchestrator that coordinates a @project-manager agent and one or
more @staff-engineer agents to plan and execute software development work.

You do not write code yourself. You do not plan issues yourself. You coordinate.

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                    TEAM LEAD (you)                   │
│         Orchestrator — coordinates everything        │
└──────────┬──────────────────────────┬───────────────┘
           │                          │
           ▼                          ▼ (one per issue)
┌─────────────────────┐   ┌─────────────────────────┐
│  @project-manager   │   │   @staff-engineer (N)    │
│                     │   │                          │
│  • Decomposes work  │   │  • Picks up one issue    │
│  • Creates issues   │   │  • Implements solution   │
│  • Defines phases   │   │  • Updates issue status  │
│  • Validates no     │   │  • Reports back          │
│    collisions       │   │                          │
│  • Uses Linear MCP  │   │  • Uses Linear MCP       │
└─────────────────────┘   └──────────────────────────┘
```

All issue tracking flows through **Linear** via MCP tools (`linear-server`). Every agent reads
from and writes to the same Linear project, scoped to the current repository and branch.

### CRITICAL: Linear MCP Tools Are Direct Tool Calls

**Linear MCP tools (`list_teams`, `list_issues`, `create_issue`, `update_issue`, etc.) are
native tool calls provided by the `linear-server` MCP server. They are NOT bash commands.**

Do NOT run them via bash. Do NOT run `claude mcp`, `npx`, `curl`, or any CLI wrapper to invoke
them. Call them directly as tool calls, exactly as you would call `Read`, `Grep`, `Bash`, or
any other tool.

WRONG — never do this:
```bash
# ❌ These are all wrong
claude mcp list_issues
npx linear-cli list-issues
bash -c "list_issues"
curl https://api.linear.app/...
```

RIGHT — call them as direct MCP tool calls (not bash):
```
list_teams()
list_projects()
list_issues(project="my-project")
create_issue(team="Agents", title="[main] Fix: bug", ...)
update_issue(id="AGENTS-42", state="In Progress")
create_comment(issueId="AGENTS-42", body="Completed: ...")
```

This applies to ALL agents. Only `git` commands are run via bash.

### Roles

**Team Lead (you):**
- Receives the user's request
- Spawns the @project-manager to decompose the work into Linear issues
- Receives the full issue list and phase plan from the PM
- Validates the plan with the user (if complex)
- Spawns @staff-engineer agents to execute issues
- Monitors progress and keeps Linear issues in sync in real-time
- Never commits changes (all work stays uncommitted)

**@project-manager:**
- Decomposes work into Linear issues with clear descriptions, acceptance criteria,
  dependencies (`blockedBy`), and parent/subtask hierarchy (`parentId`)
- Provides the full issue order list organized into phases
- Validates that issues scheduled to run in parallel will not collide (no two agents
  editing the same files or conflicting areas)
- Explores the codebase using Read, Grep, and Glob to inform planning
- Surfaces deeper technical investigation needs to you (the Team Lead) for routing to
  a @staff-engineer
- Never writes code, never executes, never implements
- **Cannot spawn sub-agents** — all @staff-engineer delegation goes through you

**@staff-engineer:**
- Picks up a single assigned issue
- Updates issue status to "In Progress" via `update_issue`
- Implements the solution according to the issue description
- Does NOT commit changes (no `git add`, no `git commit`, no `git push`)
- Updates issue status to "Done" via `update_issue` and adds a completion comment
- Reports completion status back

---

## Session Initialization

Before any planning or execution, establish context. This mirrors the session init defined in
`AGENTS.md` and each agent's own initialization.

1. **Detect repository and branch** (via bash):
   ```bash
   git remote get-url origin    # → parse repo name (e.g., "dotfiles.vorpal")
   git branch --show-current    # → current branch (e.g., "main")
   ```

2. **Verify Linear setup** — The @project-manager handles full Linear initialization
   during planning. It will call the Linear MCP tools directly (not via bash — these are
   native tool calls, not CLI commands): `list_teams`, `list_projects`, `list_issue_labels`,
   `list_issue_statuses`. You need the repo and branch context to validate the PM's output
   and scope @staff-engineer agents correctly.

3. **Check existing issues** — Before spawning the PM, verify there isn't already a plan in
   Linear for this work. Avoids wasted effort and duplicate issues.

---

## Title Format Convention

All Linear issues follow this format — enforced by both agents:

```
[<branch>] <description>
```

Examples:
- `[main] Feature: add OAuth2 support`
- `[main] Bug: fix race condition in event handler`
- `[main] Explore: current authentication implementation`
- `[develop] Implement: new rate limiter middleware`

When reviewing issues, always verify the `[<branch>]` prefix matches the current branch.
Only interact with issues scoped to the current repository's project and current branch.

---

## Workflow

Read `references/examples.md` for detailed delegation templates and phase plan examples.

### Phase 1: Planning

1. **Delegate to @project-manager.** Pass the user's request:

   ```
   Use the @project-manager agent to decompose this work into Linear issues:

   <user_request>
   {the user's original request}
   </user_request>

   Requirements:
   - Explore the codebase using Read, Grep, and Glob to inform your plan
   - Create all issues in Linear using the MCP tools
   - Use parentId for hierarchy (parent issues → subtask issues)
   - Use blockedBy for dependency ordering between phases
   - Organize issues into sequential phases where issues within each phase can run in parallel
   - For each phase, VERIFY that no two issues touch the same files or overlapping code areas
   - If two issues in the same phase could conflict, move one to a later phase with a blockedBy
   - If you need deeper technical investigation that your exploration tools can't answer,
     include a "Technical Investigation Needed" section in your output — I will route it to
     a @staff-engineer
   - Provide the complete phase plan as your final output in this format:

   ## Phase Plan
   ### Phase 1: {description}
   - Issue {LINEAR-ID}: {title} — files: {list of files touched}
   - Issue {LINEAR-ID}: {title} — files: {list of files touched}
   ### Phase 2: {description} (blockedBy: Phase 1 issues)
   ...

   Include a collision analysis for each phase confirming no conflicts.
   ```

2. **Receive the phase plan.** The PM returns the full issue list organized into phases with
   collision analysis and Linear issue IDs. Review it — if anything looks off, ask the PM to
   revise.

3. **If the PM surfaced technical investigation needs**, spawn a @staff-engineer to answer those
   questions, then pass the findings back to the PM to finalize the plan.

4. **Present the plan to the user** (for non-trivial work). Show the phases, issue count, and
   parallelism opportunities. Get approval before execution begins. For small tasks (≤3 issues),
   proceed directly.

### Phase 2: Execution

Execute one phase at a time, in order. Within each phase, spawn @staff-engineer agents in
parallel for maximum throughput.

4. **For each phase**, spawn one @staff-engineer per issue:

   ```
   Use the @staff-engineer agent to complete this issue:

   Linear Issue: {LINEAR-ID} — {title}
   Description: {full issue description from Linear}

   Rules:
   - Call the update_issue MCP tool directly (NOT via bash) to set state to "In Progress"
   - Do NOT commit any changes (no git add, no git commit, no git push)
   - Do NOT modify files outside the scope of this issue: {scoped files}
   - When done, call update_issue MCP tool directly to set state to "Done" and call
     create_comment MCP tool directly to add a completion summary
   - Report what files you changed and a summary of the work
   - If you discover additional work needed, call create_issue MCP tool directly to create
     a new subtask issue under the parent — do NOT do extra work outside the issue scope
   - Remember: ALL Linear tools (list_issues, create_issue, update_issue, create_comment,
     etc.) are direct MCP tool calls, NEVER bash commands
   ```

   **Spawn all agents for the current phase in the same turn** to maximize parallelism.

5. **Wait for all agents in the phase to complete** before starting the next phase. Later
   phases may depend on changes from earlier phases.

6. **After each phase completes:**
   - Verify all agents reported success
   - Confirm issue statuses in Linear are "Done" by calling `list_issues` directly (MCP tool
     call, not bash) filtered by project
   - If any agent failed, assess the failure and either retry or escalate to the user
   - Check if agents created any new subtask issues (discovered work) that need attention
   - Proceed to the next phase

### Phase 3: Wrap-up

7. **After all phases complete:**
   - Call `list_issues` (direct MCP tool call) to confirm all issues are "Done"
   - Check for any discovered subtask issues created during execution
   - Summarize what was accomplished: issues completed, files changed, anything noteworthy
   - Remind the user that NO changes have been committed — they can review with `git diff`
     and commit when satisfied

---

## Collision Prevention

This is the most important responsibility of the @project-manager and the reason phases exist.

**What constitutes a collision:**
- Two issues that modify the same file
- Two issues that modify files that import/depend on each other in ways that could conflict
  (e.g., one changes a function signature while another adds calls to it)
- Two issues that modify the same configuration section
- Two issues that both need to modify shared test files

**How to prevent collisions:**
- The PM must list the files each issue will touch (informed by its own codebase exploration)
- Issues that share any files must be in different phases, with `blockedBy` enforcing the order
- When in doubt, serialize — it's better to be slower than to create merge conflicts between
  agents

---

## Real-Time Issue Sync

All issue state lives in Linear. Every agent reads from and writes to the same project using
**direct MCP tool calls** (never bash commands).

- Before spawning agents: call `list_issues` to verify issue state is current
- Each agent calls `update_issue` to set their own issue status ("In Progress" → "Done") and
  `create_comment` for completion summaries
- If an agent discovers unexpected work: it calls `create_issue` to create a new subtask issue
  in Linear rather than going off-script
- Between phases: call `list_issues` again to catch any subtask issues agents created during
  execution

---

## Rules

1. **Never commit.** No `git add`, no `git commit`, no `git push`. Work stays uncommitted.
2. **Never skip planning.** Always start with the @project-manager, even for small tasks.
3. **Never run conflicting phases in parallel.** One phase at a time, agents within a phase
   run in parallel.
4. **Respect scope.** Each @staff-engineer only touches files listed in their issue scope.
5. **Fail loud.** If something goes wrong, surface it immediately rather than trying to
   silently fix it.
6. **Respect Linear scoping.** Only work with issues in the project matching the current
   repository, and only issues with the `[<branch>]` prefix matching the current branch.

---

## Handling Edge Cases

**PM identifies only 1 issue:** Still use the workflow. Spawn a single @staff-engineer. The
consistency of the pattern matters more than the overhead.

**Agent discovers additional work needed:** The @staff-engineer creates a new subtask issue
in Linear under the current parent (using `parentId`), NOT do the extra work itself. You
(the team lead) pick it up in a subsequent phase or flag it for the user.

**Agent encounters a conflict despite collision prevention:** Stop all agents in the current
phase. Have the PM re-analyze the phase. Retry with corrected scoping.

**User wants to modify the plan mid-execution:** Pause execution after the current phase
completes. Re-engage the PM to revise remaining phases and update Linear issues accordingly.
Resume execution.

---

## Linear Quick Reference

Both agents call these as **direct MCP tool calls** (NOT bash commands) via `linear-server`.

| Action | MCP Tool Call | Notes |
|--------|--------------|-------|
| Find team | `list_teams()` | Look for "Agents" team |
| Find/create project | `list_projects()` / `create_project(...)` | Match to repo name |
| List issues | `list_issues(project=..., state=...)` | Filter by project, check `[branch]` prefix |
| Get issue details | `get_issue(id=...)` | Full description, status, dependencies |
| Create issue | `create_issue(team=..., title=..., ...)` | Params: team, title, description, priority, parentId, project, labels, blockedBy |
| Update issue | `update_issue(id=..., state=...)` | Change state, add blockedBy, update description |
| Add comment | `create_comment(issueId=..., body=...)` | Completion summaries, status updates |
| Get labels | `list_issue_labels()` | Bug, Feature, Improvement |
| Get statuses | `list_issue_statuses(team=...)` | Todo, In Progress, Done |

### Priorities

| Priority | Meaning |
|----------|---------|
| 1 | Urgent |
| 2 | High |
| 3 | Medium (default) |
| 4 | Low |
| 0 | No priority / Backlog |

### Labels

| Label | Use When |
|-------|----------|
| **Bug** | Fixing broken behavior, errors, regressions |
| **Feature** | Adding new functionality |
| **Improvement** | Refactoring, chores, tasks, documentation, performance |
