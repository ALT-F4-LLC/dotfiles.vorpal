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

## Dispatch Brief Template

```text
Verified goal:
Scope:
Out of scope:
Role:
Read first:
Allowed writes:
Expected deliverable:
Required evidence:
Final report:
```

## Fix Loops

When review or verification blocks:

1. Summarize the blocker with evidence.
2. Dispatch a fresh implementation worker with the original scope plus blocker
   context.
3. Re-run the relevant review or verification worker.
4. Stop and ask the user when the blocker reveals a goal or scope change.

## Final Response

Report what changed or was decided, which agents ran, verification performed,
and remaining risks. Keep it short.
