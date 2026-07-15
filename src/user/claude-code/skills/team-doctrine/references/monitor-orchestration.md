# Monitor for Orchestration — Maintained Master

**LOCAL-copy consumers:** `team-lead.md` only (compact LOCAL copy under its kept `### Monitor
for Orchestration` header). Relocated from `src/user/claude-code/agents/team-lead.md` lines
305-312 (DKT-44, per the accepted Design-Complete Gate doctrine (`references/design-gate.md`)); the `### Monitor for Orchestration`
header itself stays inline in team-lead.md (step 12's `§Monitor for Orchestration`
cross-reference must resolve). Deployed at
`~/.claude/skills/team-doctrine/references/monitor-orchestration.md` — repo:
`src/user/claude-code/skills/team-doctrine/references/monitor-orchestration.md`. Read on demand
only — never `Skill(team-doctrine)`.

---

`Monitor` is the canonical mechanism for keeping turns short while teammates work. Default to Monitor instead of polling whenever you'd otherwise block on a long wait (>30s) or repeat a probe more than twice. Each pattern below is one event-stream per occurrence — your turn stays cheap and you react when something actually happens.

- **Phase completion (any phase >5min expected):** `Monitor("docket plan --json --watch", filter: lines whose status transitions to closed/done)`. One event per issue closing; no sleep loops.
- **Stall / zombie sweep (continuous during steps 11–16):** `Monitor("deadman_watch.sh <stall-threshold-minutes>", filter: none needed — every stdout line is already a STALL-CANDIDATE event)`. `deadman_watch.sh` (`src/user/claude-code/scripts/deadman_watch.sh`) polls `roster_sweep.sh`'s `{role: [in-progress issue ids]}` plus `docket plan --json`'s per-issue `updated_at` on a fixed interval (default 30s) and diffs `updated_at` itself, emitting `STALL-CANDIDATE: <role> <issue> unchanged <N>min` per stall. It alerts once per stall (re-arming only after the issue progresses and stalls again) so the event stream doesn't flood. Replaces manual every-turn probing in step 13's shutdown sweep — emit `shutdown_request` only when the watch surfaces a candidate. This single watch already covers every role `roster_sweep.sh` tracks (senior-engineer, sdet, staff-engineer, distinguished-engineer, project-manager, security-engineer, ux-designer) — no need for one watch per role.

  **Why not `docket ... --watch` for this:** `--watch` (and hand-rolled `docket issue list -a @role -s in-progress --watch --json` variants) only emits when a row's fields CHANGE between refreshes — it is a change-detector, not a silence-detector. An issue that has genuinely stalled (no status/updated_at delta at all — the exact zombie case this sweep exists to catch) produces zero `--watch` events, so a stall recipe built on `--watch` structurally cannot fire. `deadman_watch.sh` exists specifically to close this gap: it polls on a timer and treats an *unchanged* `updated_at` past the threshold as the signal, rather than waiting for a change event that will never come. Do not reintroduce a `--watch`-based recipe here for this reason.
- **CI / PR checks (when work touches a PR):** `Monitor("gh pr checks <num> --watch", filter: terminal states succeeded/failed/cancelled)`.
- **Inbound Discovered comments (mid-phase scope deltas):** `Monitor("docket issue comment list <ID> --watch", filter: 'Discovered:' lines)`. Surfaces scope deltas in real time instead of waiting for the spot-check.

Filter must be selective (no raw log dumps) and cover failure signatures alongside the happy path (per Monitor tool's coverage rule). The change-detection recipes above (phase completion, CI/PR checks, inbound comments) hand `docket`'s native `--watch`/`-w` global flag (with `--interval DURATION`, default 2s — confirmed live in `docket --help`) to Monitor as the poll primitive; prefer it over wrapping a bare `docket` query in a hand-rolled `while … ; sleep N; done` loop. The stall sweep is the sanctioned exception: it needs to detect the *absence* of a change, which `--watch` cannot express, so `deadman_watch.sh` polls-and-diffs on its own timer instead of asking `docket` to watch. Use `Bash(run_in_background=true)` for one-shot "wait until X is done" cases; use Monitor for "tell me each time X happens." Combine with TaskUpdate at every state transition so the operator sees progress.
