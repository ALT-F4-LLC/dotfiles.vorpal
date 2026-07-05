# Monitor for Orchestration — Maintained Master

**LOCAL-copy consumers:** `team-lead.md` only (compact LOCAL copy under its kept `### Monitor
for Orchestration` header). Relocated from `src/user/claude-code/agents/team-lead.md` lines
305-312 (DKT-44, design-complete-gate-before-planning); the `### Monitor for Orchestration`
header itself stays inline in team-lead.md (step 12's `§Monitor for Orchestration`
cross-reference must resolve). Deployed at
`~/.claude/skills/team-doctrine/references/monitor-orchestration.md` — repo:
`src/user/claude-code/skills/team-doctrine/references/monitor-orchestration.md`. Read on demand
only — never `Skill(team-doctrine)`.

---

`Monitor` is the canonical mechanism for keeping turns short while teammates work. Default to Monitor instead of polling whenever you'd otherwise block on a long wait (>30s) or repeat a probe more than twice. Each pattern below is one event-stream per occurrence — your turn stays cheap and you react when something actually happens.

- **Phase completion (any phase >5min expected):** `Monitor("docket plan --json --watch", filter: lines whose status transitions to closed/done)`. One event per issue closing; no sleep loops.
- **Stall / zombie sweep (continuous during steps 11–16):** `Monitor("docket issue list -a @senior-engineer -s in-progress --watch --json", filter: rows with no completion comment within ~5 min)`. Replaces manual every-turn probing in step 13's shutdown sweep — emit `shutdown_request` only when the watch surfaces a candidate. Run analogous watches for `-a @sdet` / `-a @staff-engineer` / `-a @distinguished-engineer` during paired reviewer / verifier phases.
- **CI / PR checks (when work touches a PR):** `Monitor("gh pr checks <num> --watch", filter: terminal states succeeded/failed/cancelled)`.
- **Inbound Discovered comments (mid-phase scope deltas):** `Monitor("docket issue comment list <ID> --watch", filter: 'Discovered:' lines)`. Surfaces scope deltas in real time instead of waiting for the spot-check.

Filter must be selective (no raw log dumps) and cover failure signatures alongside the happy path (per Monitor tool's coverage rule). Use `Bash(run_in_background=true)` for one-shot "wait until X is done" cases; use Monitor for "tell me each time X happens." Combine with TaskUpdate at every state transition so the operator sees progress.
