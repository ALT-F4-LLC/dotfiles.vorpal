# 03 — Runtime: the Claude Code side

Status: approved — 2026-08-02. This document defines everything that runs inside the Claude Code harness:
the planner, the conductor, executor archetypes, the hook set that makes the engine's
authority mechanical, human gates, and failure handling. Constraint honored throughout:
**all agent spawns originate inside Claude Code from prose definitions** (Phase 0).

## 1. Inventory of harness-side definitions

The entire Claude-side footprint is:

| File | Kind | Size target | Replaces |
|---|---|---|---|
| `.claude/skills/plan/SKILL.md` | skill (planner) | ~4KB | brief + PM planning prose |
| `.claude/skills/run/SKILL.md` | skill (conductor loop) | ~2KB | team-lead.md (82.7KB) + operator↔lead protocol |
| `.claude/workflows/wave.js` | saved workflow — the harness adapter (spawn rows → agents, claim→prompt, usage report) | ~2KB | — (new; the one harness-specific piece) |
| `.claude/agents/executor-{read,write,research}.md` | agent definitions ×3 | ~1KB each | — (new archetypes) |
| `hooks/` (§5: one-line shims over `docket guard` + kept tmp-guard + SessionStart) | shell one-liners | tiny | 6 current hooks + liveness/stop prose |
| `.claude/skills/bootstrap/SKILL.md` | mines the repo + git history → drafts `.docket/config/` (workflows, schemas, contracts, fragments, policy, trust proposals) for conversational approval | ~2KB | hand-authoring of instance config (T9) |
| `.docket/config/contracts/*.md` (25, 04) | data — machine-authored, engine-assembled into briefs | 3–5KB each | 8 agents + most of 17 skills |
| `.docket/config/fragments/*.md` (~16, 04 §3) | data — machine-authored, engine-inlined | 1–3KB each | doctrine/knowledge spread across the fleet |
| `.docket/config/{workflows,schemas}/` + `policy.toml` | machine-authored instances, auto-registered at activation (06 §2) | small | orchestration prose + tier tables |
| `~/.config/docket/trust.toml` | user-level exec allowlist (`docket trust`, 06 §4) — never repo-shipped | small | — (new; security boundary) |

Node contracts, fragments, workflows, policy, and gates are *data* — machine-authored
per T9 (bootstrap drafts them, retro evolves them, humans approve in conversation),
assembled or executed by the engine. The prose the harness itself loads drops from
~800KB to roughly 15KB, and none of the data layer is hand-maintained.

## 2. The planner

A skill (`/plan`), invoked in the operator's interactive session. It is the only place
where open-ended conversation happens, because intake is a judgment (AC-1).

Contract: converse until the request is unambiguous enough to
decompose — goal, constraints, acceptance criteria, security sensitivity, size; then
record in Docket: the request, a plan artifact (prose: decomposition rationale,
risk notes, suggested phasing), issues with kinds/labels/scopes/`depends_on` relations and
verbatim acceptance criteria in bodies, and stop. The planner never observes execution.
Re-planning — after a failure, or as a *planned* second sitting in a discovery-shaped
run (audit → select → build) — is a fresh planner invocation whose brief includes the
run record (steps, reconciled findings, gate outputs, operator gate notes): fresh
context, no accumulation. A plan may deliberately leave later phases uncomposed behind a
human gate; the follow-on invocation composes them from what execution learned, and
activation lints the extension like any DAG (§10 walks one).

Two deterministic backstops bound planner error: scope guesses are checked by the scope
gate (02 §5), and plan structure is checked at activation (`docket run activate` refuses
cycles, dangling deps, missing ACs, unscoped write-issues — the DoR check, absorbed into
the engine).

The operator approves the plan by activating the run — a human gate outside the model.

## 3. The conductor: `run` skill + the `wave` workflow

Spawning must originate in-harness (Phase 0), and a subagent cannot itself spawn — so the
conductor role lives in the operator's session as a skill, with the wave mechanics in
deterministic code (the harness's Workflow tool — a fact Erik confirmed in his harness:
saved JS workflows, agent() fan-out, ~16 concurrency, resumable, background with
completion notifications).

**The `run` skill (~2KB)** — the session-level loop:

1. `docket next --run $RUN --json`; empty with nothing running ⇒ report run state,
   stop.
2. Ready steps ⇒ `docket dispatch open`, then invoke the saved `wave` workflow with
   the returned spawn rows as args; await its completion notification (the session
   stays free for the operator meanwhile).
3. On wave completion: back-fill per-spawn usage from the wave journal,
   `docket dispatch close`, then `next` again — the engine has already gated and
   routed everything the executors recorded, and it **refuses** to issue the next
   ready set while discrepancies exist (unrecorded claims, missing usage rows —
   02 §5), so a drifting relay stalls loudly rather than proceeding. Surface
   `waiting-human` steps (§6). Loop.

**The `wave` workflow** (`.claude/workflows/wave.js`, static and versioned — not per-run
generated, 01 §4 A2): pipelines over the spawn rows it was handed and calls agent() per
step with the archetype, model, and effort the engine resolved. Each executor's prompt
is a fixed bootstrap: claim your step (`docket step claim STEP --render` — one atomic
mediation returning your **capability token and fully rendered brief**; on CONFLICT
stop immediately), execute the brief, record the result yourself
(`docket step complete|fail`, token via env), and end with the step id + recorded
status.
Tokens are minted at claim (random, engine-stored) — workflow scripts are barred from
wall-clock and randomness, which suits the engine. Fan-out, concurrency, per-agent model
routing, retry-on-dead-spawn, and progress display are the workflow runtime's job —
deterministic code, exactly where AC-2 wants it.

**Executors self-claim and self-record — and cannot do otherwise.** Claims are atomic
(02 §5), so a duplicated or freelance spawn is harmless: the loser gets CONFLICT and
stops. Recording requires the live lease's token (AUTH_ERROR otherwise), so an executor
that skipped claiming *mechanically cannot* record, and a late one is refused with
STALE_LEASE. The wave's return is a checklist; the engine's own discrepancy refusal in
`next` (02 §5) is the enforcement, and lease expiry backstops anything that died
unrecorded.

The conductor role holds no run state (ids, statuses, usage numbers — never artifact
bodies), makes no routing decisions, sizes no panels, reconciles nothing: all of that is
`docket next` and gate/threshold output. Drift is not trusted away, it is blocked (§5):
a wave not matching the ready set is denied pre-tool-use, an unreconciled wave return
blocks progression, and a premature stop is refused while the run has work.

Why subagents and not teammates: executors need a report-and-end lifecycle, fresh context
per invocation, and no peer messaging — precisely the subagent model, whether spawned by
the wave workflow or directly. The teams runtime's costs (shutdown handshakes, idle
interpretation, liveness doctrine, task-list mirroring — a large share of today's 800KB)
buy nothing this design needs (01 §4, A3).

## 4. Executor archetypes

Three thin agent definitions, differing only in tool surface (least privilege,
frontmatter-enforced):

- **executor-read** — Read/Grep/Glob/Bash(read-only allowlist **plus** the `docket`
  CLI and a $TMPDIR write path for artifact files — engine recording and scratch are
  not tree mutation). For judges, verify-ac, design-qa, investigators. Cannot write
  the working tree: review honesty is structural.
- **executor-write** — full file tools + Bash; no web. For implement, fix, test-infra,
  doc-author nodes.
- **executor-research** — read tools + WebSearch/WebFetch. For research nodes.

The archetype files contain *no* role content — the brief carries the entire contract
(02 §8). An executor's observable obligations are four: claim, do the brief, record the
artifact in the instructed format, and touch nothing outside scope (claims and recording
are engine calls; the scope gate checks the last). Where the harness offers LSP tools
(go-to-definition, references, call hierarchy — present in Erik's harness), read/write
archetypes include them: cheaper precision for judges and implementers alike. Writers may
additionally be granted worktree isolation (the harness's worktree primitives) where
policy wants parallel writes beyond scope-disjointness — an option, not the mechanism
(02 §5 scope exclusion remains primary; 08 D9 — optional, never required). Executors are leaves; only the planner
spawns helpers (explorers during intake), within harness depth limits.

## 5. Hooks: mechanical enforcement

Five enforcement hooks, plus the kept tmp-write guard and a SessionStart injection (§7).
Each hook body is a **one-line shim over an engine verb** — the `docket guard` family,
plus `docket step heartbeat` for the heartbeat hook (06 §2): the logic lives in the
engine, portable to any harness's hook mechanism; the shim only wires the event. All fail toward safety (block) on engine-state uncertainty — hooks contain no
policy of their own. Hooks are global to the session tree, so per-executor
scoping comes from engine state (claims, markers), not from hook configuration.

| Hook (event) | Enforces |
|---|---|
| `spawn-guard` (PreToolUse: Workflow/Agent) | `docket guard spawn`: the wave's spawn rows must match the open dispatch **byte-for-byte**, with no unacknowledged write-class reap — step ids, node types, models, efforts; a transcribed-away `never:` model or dropped row is exit 2, not a post-hoc ledger note. Ad-hoc Agent spawns need a claimable step. Atomic claims and `dispatch verify` remain the locks beneath this (hook visibility inside the workflow runtime is not assumed); recorded metadata makes any drift that slips through visible in the run report. |
| `heartbeat` (PostToolUse, global) | `docket step heartbeat --from-marker`: `claim` drops a **token-bound** marker in the executor's $TMPDIR scope; the hook renews only the lease whose token the marker carries and no-ops in sessions holding none. $TMPDIR privacy per subagent is verified in M3 (07) — if it doesn't hold, markers are cut and TTLs alone carry liveness. |
| `wave-audit` (PostToolUse: Workflow) | `docket guard record`: discrepancies (claimed-but-unrecorded, usage missing) surface immediately — a courtesy early warning. Enforcement is engine-side either way: `next` refuses while discrepancies stand, and a TTL'd dispatch can always be abandoned (02 §5). |
| `run-guard` (Stop) | `docket guard stop`: block session end while the active run has pending work and no `waiting-human` reason (today's stop-guard, re-keyed to engine truth). |
| `commit-guard` (PreToolUse: Bash) | `docket guard gate --step commit-gate`: `git commit/push/add` only behind an approved commit gate. Replaces the 13KB awk-parser hook's job with an engine query; the awk hardening is retained as the parser. |

Deleted with the teams runtime: task-completed, subagent-report (superseded by
wave-audit), teammate-idle.

## 6. Human gates

A `human:*` step makes the run `waiting-human` (02 §3). **The operator never types an
engine command** (T9): the session is the middleware. Presentation depends on presence:

- **Interactive:** the conductor surfaces the gate conversationally — plan approval,
  commit authorization (with the actual diff shown), held findings, budget breach,
  security waiver — and on the operator's conversational answer runs the engine verb
  itself (`docket step approve|reject --note …`, or `step resolve` for parked steps:
  retry / skip / abandon-issue / override-pass). The CLI remains the source of truth
  and audit surface; the human's interface is the conversation. Stated honestly:
  `approve|resolve` are middleware verbs inside the session-trust boundary — gate
  integrity rests on session integrity plus the audit trail (`run report` lists every
  gate resolution and note; an unrecognized one is D14's revisit trigger).
- **Unattended:** the run parks. `run-guard` permits session end (the run is legitimately
  waiting); any later session resumes it (§7). Nothing times out into a default: human
  gates have no auto-approve, ever.

Standard human gates and where pipelines place them: 05 §1–2. Everything the old fleet
escalated by prose ("2 same-failure cycles → escalate", "4-option menu", Critical-accept
votes) becomes either a pipeline routing (`waiting-human` on attempts-exhausted / budget
breach / held findings) or a vote gate — enumerated, not narrated.

## 7. Session lifecycle and resume

A run is not coupled to any session (02 §9). The operator's terminal session hosts
planning and conducting for convenience, but:

- **SessionStart hook** injects `docket run status --active --json`. Any new session in
  the repo knows the run state immediately; the operator says "continue" (or the `run`
  skill auto-offers) and a fresh conductor picks up the ready set. No handoff documents,
  no continuity preambles, no crash-recovery narratives.
- Interrupted executors are reclaimed by lease expiry; interrupted conductors by
  re-entry; interrupted humans by the run parking in `waiting-human`.
- Multiple sessions do not race: claims are atomic and owner-scoped, so a second
  conductor simply finds fewer ready steps. (Policy may still declare single-conductor
  as a norm; the point is that violating it is safe, not that it is useful.)

## 8. Failure handling (all failure logic in one table)

| Failure | Detected by | Deterministic response |
|---|---|---|
| Executor crash/hang | Lease expiry (no heartbeat) | Step → ready, attempt++; attempts exhausted → pipeline's on-fail routing |
| Executor returns garbage / wrong format | Artifact recording validation (payload schema, required sections) | `step fail`; retry with same brief (attempt++); persists → on-fail routing |
| Gate command fails | Gate exit code | Pipeline routing (`fix-loop` \| `waiting-human` \| `skip` \| `abandon-issue`) |
| Flaky gate | Policy: re-run N× on declared-flaky gates, record all runs | Consistent fail → routing; inconsistent → `waiting-human` (flake is a human problem) |
| Scope violation | Scope gate (diff vs declared globs) | `step fail` + issue flagged for replan (fresh planner invocation) |
| Budget breach | Engine counters (02 §7) | Run → `waiting-human` (budget reason) |
| Conductor drift (freelance spawn, unreconciled wave, premature stop) | spawn-guard / wave-audit / run-guard | Blocked mechanically (exit 2); atomic claims bound anything hooks can't see |
| Conductor death | Nothing to detect | Run persists; next session resumes (§7) |
| Engine/Docket write conflict | CAS / SQLite busy | CONFLICT to the caller; conductor retries the read-act-record cycle |
| Unauthenticated or stale record attempt | Capability check on complete/fail (06 §2) | AUTH_ERROR / STALE_LEASE — the work is discarded, the step re-readies by lease |
| Harness quirk (tool schema change, spawn API drift) | Hook/CLI failure surface | Fails loud at one seam (conductor/hook), fixed in one file — never fossilized into node prose (E-10) |

The rule behind the table: **models are never asked to notice failure.** Every detection
is a lease, an exit code, a validation, or a counter; every response is an enumerated
routing. Model judgment re-enters only inside `fix-loop` (the fix node reads the findings
and does the repair — a judgment) and at human gates.

## 9. Operator experience (day in the life)

Zero-touch (T9): Erik converses; the session runs every command. Lines marked `⚙` are
engine verbs the session executes on his behalf — he never types one.

```
Erik  › /plan add rate limiting to the registry API
Claude› Two clarifiers: at the router or per-endpoint? … burst policy?
Erik  › router, token bucket, defaults are fine
Claude› Plan drafted — RUN-7: DKT-101 token-bucket core → DKT-102 wire into API →
        DKT-103 docs. Scopes and ACs attached. Approve?
Erik  › approve
Claude› ⚙ docket run activate RUN-7 … activated; wave 1 spawned (implement DKT-101).
        I'll ping you at the gates — nothing else needs you.
        …
Claude› Review fan-out reconciled: one high finding entered the fix-loop (bounded ≤2);
        one cluster is HELD — judges split 2 levels apart: [one-line summary].
        Keep it high, or accept at medium?
Erik  › medium is right, proceed
Claude› ⚙ docket step approve --note "accept at medium" … disposition recorded and
        thresholds re-applied over the resolved set. Fix passed delta re-review;
        verify-ac: 5/5 met. Here's the DKT-101 diff: [diff]. Ship it?
Erik  › ship it
Claude› ⚙ docket step approve … commit-author drafted the message; commit gates
        passed; committed. DKT-102 running.
        …
Claude› RUN-7 done. Ledger: $9.80 · 41 steps · 2 fix-loops · your 3 gates were the
        only human moments. Full report, or file the retro suggestion?
```

The engine sees only its CLI (every `⚙` line lands in the event log); the human sees
only conversation. `docket events --follow` in a second terminal stays available for
watching — observation, never obligation.

Two properties worth naming: the operator's control surface is Docket (inspectable,
scriptable, honest), and the session is replaceable at any moment for the price of one
SessionStart injection.

## 10. Worked example: a discovery-shaped run

"Audit and implement any high value features discovered." This request cannot be fully
planned up front — the build half depends on what the audit finds — so the graph is
composed in two sittings, both planner-then-exit, both behind activation gates (§2).
Figures illustrative; as in §9, `>`-marked commands are executed by the session on
Erik's conversational instruction, never typed by him.

```
> /plan "Audit and implement any high value features discovered"
  planner (3 questions): audit target → this repo · "high value" judged by → operator,
  at a gate · budget → cap $15, pause at 60%
  RUN-8 recorded — plan artifact (two-phase shape: discover → select → re-plan → build)
    DKT-210  feature-opportunity audit    kind=investigation  scope=[]   phase 1
    DKT-211  select + extend plan         human gate          phase 2 (unexpanded)

> docket run activate RUN-8     # ⏸ gate 1: plan approved — phase 1 expands, phase 2 lazy
  wave: investigate + research ×2 fan-out → audit-report artifact: 7 candidates, each
  what · where · OBSERVED evidence · value rationale · effort guess → run: waiting-human

  ⏸ gate 2: SELECTION — "value" is a free-form judged quantity, so no threshold may
  fire on it (01 §3 E-8). The audit proposes; the operator disposes.
> docket step approve STEP-12 --note "build #2 and #5; drop the rest"

  fresh planner invocation reads the run record + note → appends phase 2:
    DKT-212  tdd: incremental export       spec-doc
    DKT-213  implement incremental export  standard-change  depends_on DKT-212,
                                                            scope internal/export/**
    DKT-214  implement --watch filters     standard-change  scope internal/watch/**
> docket run activate RUN-8     # ⏸ gate 3: extension approved (activation lints the new DAG)

  DKT-212 flows spec-doc (author → doc gates → review → acceptance vote);
  DKT-213 then DKT-214 — write steps serialize in v1 (`[limits] write=1`, 02 §5);
  the judge fan-outs inside each still run parallel; each flows standard-change
  (implement → gates → judges → reconcile → verify-ac);
  ⏸ per-issue commit gates → done

> docket run report RUN-8       # audit $2.10 · tdd $1.80 · builds $6.40 · 3 designed
                                #   human gates · 1 fix-loop · held: 0
```

Beyond §9, this exercises: the two-sitting graph (lazy phases + fresh planner, §2); the
selection gate as an E-8 consequence rather than a courtesy — no agent decides what is
"high value" and silently builds it; serialized writers with parallel read fan-outs
inside each slot (02 §5); and the budget cap that makes an open-ended audit safe to
fire at all (02 §7).
