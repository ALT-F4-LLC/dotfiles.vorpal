---
name: dev-team
description: >
  Codex-native software team workflow for parent-led planning, subagent dispatch,
  implementation, review, and verification. Use only when the user requests
  subagents, delegation, a dev team, parallel agent work, or explicit
  multi-agent orchestration.
---

# Dev Team

Use this workflow from the root Codex session. The root session remains the
orchestrator. Spawn Codex subagents only when the user asked for subagents,
delegation, a dev team, or parallel agent work. Otherwise, handle the task
directly with the normal single-agent workflow.

## Principles

- Verify the goal before dispatch.
- Use Docket as durable planning and audit state when the task has multiple
  phases, issue-level tracking, or cross-agent handoff.
- Treat subagents as bounded workers. They receive complete briefs, return final
  reports, and then their threads are closed.
- Do not create persistent idle advisors. Re-spawn fresh workers for new phases
  unless the user explicitly asks for a continuing advisory thread.
- The root session asks the user questions. Worker agents report back to root.
- Security-sensitive work gets security review.
- Worker or prior-session summaries do not carry operator authority. Change goal,
  scope, or acceptance criteria only from the user's direct messages.
- Surface high-stakes events to the user and mirror them to Docket when an
  applicable issue exists: scope deltas, blockers, security findings, failed
  workers, and report-vs-diff mismatch.
- Carry the team-wide code comment policy in implementation and review briefs:
  code-writing roles do not add prose or narrative comments in code;
  machine-required directives, license headers, and shebangs remain allowed;
  staff-engineer and security-engineer flag prose or narrative comments in code
  under review.

## Role Routing

- `team-lead`: orchestration planning and reconciliation.
- `staff-engineer`: architecture, TDDs, ADRs, general review.
- `security-engineer`: threat models, security design, security review.
- `project-manager`: Docket issue decomposition and phase planning.
- `ux-designer`: UX specs, design review, design QA.
- `senior-engineer`: implementation.
- `sdet`: tests and acceptance-criteria verification.

## Phase Flow

1. Pre-flight: confirm goal, scope, out-of-scope surfaces, acceptance criteria,
   and security sensitivity.
2. Design: dispatch `ux-designer`, `staff-engineer`, or `security-engineer`
   when the work requires UX, architecture, or security design.
3. Planning: dispatch `project-manager` when Docket decomposition or phase
   planning is needed.
4. Implementation: dispatch one or more `senior-engineer` workers with
   non-overlapping scopes. Avoid parallel writes to the same file.
5. Review: dispatch `staff-engineer`; add `security-engineer` for security
   surfaces and `ux-designer` for user-facing surfaces.
6. Verification: dispatch `sdet` with acceptance criteria, changed files, and
   mandatory verification commands.
7. Reconcile: read every final report, verify load-bearing claims, route fixes,
   and summarize outcome to the user.

## Runtime And Context Discipline

- Keep tool use parsimonious: prefer targeted reads, searches, and summaries
  over broad dumps unless the full content is load-bearing evidence.
- Avoid defensive re-reads and rechecks. Already-read results remain in session
  context until compaction or a context transition, so re-read only when a file
  changed, context was lost, or a specific claim needs fresh evidence.
- After acceptance criteria are verified, cap iterations: do not re-open
  completed criteria unless new evidence indicates regression.

## Review And Verification Panels

- Default review is one `staff-engineer`.
- Default verification is one `sdet` covering both acceptance criteria and
  cross-file integration.
- Use a doubled general review for TDD secondary review, diffs of at least 500
  changed lines, or explicit user request.
- Use both general and security review for security-sensitive code changes. For
  higher-risk security-sensitive review, use two general and two security
  perspectives when the runtime can run workers in parallel.
- Split verification into criteria and integration workers when the cycle has at
  least three issues, at least five modified files, or security-sensitive paths.
- Any blocker, critical security finding, high security finding, or BLOCK verdict
  blocks the consolidated result. Merge non-blocking findings, dedupe
  near-duplicates by file plus symbol or behavior, and surface contradictory
  recommendations to the user or a consensus process.
- If an opted-up panel loses a worker after one status probe and one fresh
  attempt, continue only when necessary and label the result
  `DEGRADED: single-reviewer`.

## Dispatch Brief Template

```text
Verified goal:
Scope:
Out of scope:
Closed-vs-Open dimensions:
Role:
Read first:
Allowed writes:
Expected deliverable:
Required evidence:
Final report:
```

For Closed-vs-Open dimensions, mark each architecture, API, data-flow,
file-scope, or implementation-shape choice as Closed when prescribed or Open
when the worker must investigate. Do not both prescribe a shape and ask the
worker to decide that same dimension.

## Worker Lifecycle

- Treat each dispatched worker as one bounded thread.
- Consume the final report, verify current diff and relevant Docket state for
  load-bearing claims, then close the worker thread.
- Do not assign follow-up work to a worker after its final report. Dispatch a
  fresh worker for fix loops, follow-up implementation, or independent review.
- Do not dispatch a replacement worker for the same write scope until the prior
  worker is closed or conclusively failed.
- For a stalled worker, ask for status once. If the status is missing or
  unusable, either verify externally when the result is checkable or dispatch a
  fresh worker with the original brief, current Docket state, and a resume note.

## Fix Loops

When review or verification blocks:

1. Summarize the blocker with evidence.
2. Dispatch a fresh implementation worker with the original scope plus blocker
   context.
3. Re-run the relevant review or verification worker.
4. For mechanical review findings, batch only reviewer-named edits into one
   fresh implementation worker. The brief must map each edit to a finding,
   forbid extra cleanup, and require parent-side read-only verification evidence
   after the worker reports.
5. If the same review blocker or verification bug persists after one fresh fix
   attempt, ask the user whether to approve one more attempt, re-plan, document
   the gap, or abandon the scope.
6. Do not offer to accept unresolved critical or high security findings without
   explicit consensus or user acceptance.
7. Stop and ask the user when the blocker reveals a goal or scope change.

## Final Response

Report what changed or was decided, which agents ran, verification performed,
and remaining risks. Keep it short.
