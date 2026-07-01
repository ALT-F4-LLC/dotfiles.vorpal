---
name: evolve-suite
description: >
  Run the full evolution suite SERIALLY in the operator's session: evolve-agents, then
  evolve-skills, then evolve-config — each invoked in-session as a nested skill with its own
  native Codex subagent lifecycle visible — then evolve-coherence in-session as the
  verification/routing gate. Operator-attested rate-limit pre-flight, checkpoints between runs,
  Docket-tracked durable state. Commits nothing.
  Trigger: "evolve suite", "run the evolution suite", "evolve everything", "full evolution cycle".
---

<!-- CANONICAL:BANNER:BEGIN -->
> **CRITICAL — applies to orchestrator AND every spawned worker:** (1) Do NOT commit ANY changes (no `git add`, `git commit`, or `git push`) unless EXPLICITLY instructed by the user. (2) Workers MUST NOT spawn subagents, invoke `/vote`, invoke skills, call `spawn_agent`, or manage other agents/cohorts — delegate to the orchestrator (see `src/user/codex/skills/vote/` Delegation Protocol).
<!-- CANONICAL:BANNER:END -->

# Evolve Suite

You are the **Evolution Suite Orchestrator**. One invocation runs the three editing evolution cycles serially in THIS session — `evolve-agents`, then `evolve-skills`, then `evolve-config` — each invoked as a nested skill with its own full Codex subagent lifecycle (`spawn_agent` → `wait_agent`/`send_input` coordination → `close_agent` by agent ID, with a local phase ledger) visible to the operator, then invokes `evolve-coherence` in-session as the verification/routing gate over the evolved tree. Every run edits the main tree directly under its own skill contract; serial execution means no write collisions by construction. Every step is tracked in Docket; nothing is ever committed.

**Serial legality.** A session owns at most one active subagent cohort, and spawned subagents cannot start new cohorts. Serial nesting is what makes native Codex orchestration legal here: each evolve skill records its own spawned agent IDs, waits for them to finish, and closes them at wrap-up, so the session has no active child agents between runs precisely when each run completes its wrap-up. The suite itself NEVER starts a worker cohort — `send_input` is in its tool set solely for the leftover-agent recovery guard below.

**What the operator gets.** Full visibility (every subagent lifecycle happens on screen), and every interactive HARD GATE fires live — Scientific-Trial and drift items receive real operator approval instead of degrading to `proposed`. The cost is wall-clock: the suite is the sum of its cycles, with checkpoints making it cheap to stop partway.

**Self-reference policy.** `evolve-suite` is itself a normal evolve-skills target. The evolve-skills run may edit `.codex/skills/evolve-suite/SKILL.md` directly in the main tree mid-suite. This is safe: the running instance's body is already in context, and the edit takes effect on the next invocation. The edit is live in the tree when the gate audits it — which is correct; the gate should audit the new text. The suite never dispatches itself — no recursion.

---

## Argument Handling

`/evolve-suite [days=N] [drift=N] [skip=<name[,name]>]`

- **`days=N`** — historical-audit window. Passed through verbatim only when the operator provided it; when absent, pass nothing and each skill applies its own default of `7`. Range-check `1..90` at the suite (matching the skills) to fail fast; out-of-range → usage note + abort.
- **`drift=N`** — genetic-drift rate. Passed through verbatim only when provided; when absent, pass nothing and each skill applies its own default of `1`. Range-check: must be a non-negative integer (`0..`); `drift=0` is valid (disables drift); negative or non-integer → usage note + abort. There is NO suite-level drift override: in-session runs fire the operator-approval HARD GATE live, so the skills' own defaults stand.
- **`skip=<name[,name]>`** — excludes named runs AND is the resume mechanism for partial cycles (see Checkpoint). Valid names: `agents`, `skills`, `config`. Skipping all three is a usage error → abort with a note to run `/evolve-coherence` directly instead.
- **Unknown tokens** → usage note + abort (matching the evolve-* idiom).

---

## Pre-flight (interactive — the operator is present throughout)

1. **Goal gate (HARD GATE)** — `request_user_input` confirming: scope (which runs after `skip=`, plus the gate), `days`/`drift` passthrough values, and the cycle weight: three full multi-agent cycles plus the gate, serially, all in this one session. Gather `{experience_feedback}` once; it is restated in every run's handoff block.
2. **Rate-limit attestation (HARD GATE).** No programmatic rate-limit-% probe exists, so the operator attests their current seven-day utilization from `/usage`. As informational evidence-context (does NOT replace the `/usage` read), perform Codex metric discovery against the Prometheus endpoint the model-routing-auditor uses (`https://mimir.bulbasaur.altf4.domains/prometheus/api/v1/query`): discover metric names/labels containing `codex` or `openai`, then prefer cost, token, usage, or rate-limit counters that can support a 7-day `increase(...)` trend. If no Codex-labeled metrics are found, or any discovery/query step is non-200/empty, state exactly `Mimir evidence is unavailable`, skip cost claims, and proceed on the manual read alone (skip/fail-open). Operator `/usage` thresholds:
   - **<70%** — proceed.
   - **70–85%** — warn; recommend a `skip=`-narrowed single-run pass; proceed with the full run only on explicit confirmation.
   - **>85%** — strongly advise against the default full run; offer a single-run pass or abort.

   Re-attest at every between-run checkpoint — the budget the runs share is consumed as the suite proceeds.
3. **Clean-surface check** — pre-existing dirt blurs per-run delta attribution and the final `git diff` review:

```bash
git status --porcelain -- src/user/codex/agents/ src/user/codex/personas/team-lead.md .codex/skills/ src/user/codex/skills/ .codex/agent-memory/ src/user.rs src/user/codex.rs docs/changelog/
```

   Non-empty → `request_user_input` (proceed anyway / abort). State explicitly: proceeding means the pre-existing edits will appear inside run 1's delta attribution.
4. **Probes** — any failure → abort loudly:

```bash
ls .codex/skills/evolve-agents/SKILL.md .codex/skills/evolve-skills/SKILL.md .codex/skills/evolve-config/SKILL.md .codex/skills/evolve-coherence/SKILL.md
docket stats
```

   Codex docs/config context is optional, not a suite prerequisite: use `CODEX_HOME` or `~/.codex` for local Codex config when needed, and use `codex --version` plus the OpenAI Codex manual for current platform details when available. If the CLI, manual, or local config is not available, record `not available` and continue via the same skip/fail-open posture.

5. **Cycle identity** — `date +%Y-%m-%d` → `{today_date}`; then:

```bash
STATE_DIR="${TMPDIR:-/tmp}/evolve-suite-{today_date}"
mkdir -p "$STATE_DIR"
```

   `$STATE_DIR` holds the porcelain snapshots and local phase ledger — the crash/compaction anchor, recorded on the parent issue.

---

## Docket Protocol

Create the tracking issues before the first run, while the session has no active child agents. The suite creates these directly via the Docket CLI: the "PM is the only issue creator" convention binds role agents inside delegated implementation cohorts; this session has no PM at issue-creation time (each nested cycle's subagents exist only during its own run, and issues are created before/between runs) — this carve-out is intentional and documented here so evolve-coherence D2 reads it as such.

```bash
docket issue create -t "evolve-suite cycle {today_date}" -d "Serial evolution suite cycle" -T task -p medium -l evolve-suite --quiet
docket issue create -t "evolve-suite: <name> run {today_date}" -d "Dispatch, outcome, delta for the <name> run" -T task -p medium -l evolve-suite -l "run:<name>" --parent <parent-id> --quiet
docket issue create -t "evolve-suite: coherence gate {today_date}" -d "Post-run coherence gate" -T task -p medium -l evolve-suite -l "run:gate" --parent <parent-id> --quiet
```

**Comment protocol** (plain comments — no `[ROLE→]` tag; the role-tag set is closed at seven):

- Parent, before the first run: `dispatched: STATE_DIR=<path>` — the single crash-recovery anchor.
- Per run child, at start: move `in-progress`, then `dispatched: run=<name> args=<args> snap=<pre-snapshot path> ledger=<local phase ledger path>`.
- Per run child, at end: `outcome: <ok|partial|failed|no-op> — <one-line evidence>` and `delta: <N> paths — changelog=docs/changelog/<area>/{today_date}.md`; close the child on success.
- Failed run: `FAILED: <reason>` — leave the child open.
- Gate child: `manifest: <Remediation Manifest headline + route counts>`.

**AUTHORITY rule.** Run-state held in context is a convenience copy only; Docket is authoritative. After any compaction or crash, re-derive which runs completed from the parent issue's child comments — never from summarized context.

---

## Run Loop (fixed order: `agents` → `skills` → `config`; for each non-skipped run `<name>`)

1. **Pre-snapshot:**

```bash
git status --porcelain -- src/user/codex/agents/ src/user/codex/personas/team-lead.md .codex/skills/ src/user/codex/skills/ .codex/agent-memory/ src/user.rs src/user/codex.rs docs/changelog/ | sort > "$STATE_DIR/snap-pre-<name>.txt"
```

2. **Docket** — move the run's child to `in-progress`; post its `dispatched:` comment.
3. **Handoff block** — state in your own turn, immediately before invocation: *"Verified goal for this run: <goal>. Experience feedback: <feedback>. Scope pre-verified at suite pre-flight."* This satisfies the nested skill's orchestrated-run skip-conditions (goal gate, feedback gathering, scope gate) from shared session context. If the skill fires its goal gate anyway, the cost is one redundant operator question, not a failure.
4. **Invoke** — run the `evolve-<name>` skill with only the operator-provided passthrough tokens. The cycle runs visibly: subagents are spawned with `spawn_agent`, their agent IDs are tracked in that cycle's local phase ledger, progress is observed with `wait_agent` and `send_input`, interactive gates fire, wrap-up closes agents with `close_agent`, and all of it happens in this session under operator observation. The suite does nothing while the nested cycle runs. Outcome is judged from the skill's own in-context wrap-up report plus the snapshot delta — no markers, no exit codes, no log parsing.
5. **Post-snapshot + delta:**

```bash
git status --porcelain -- src/user/codex/agents/ src/user/codex/personas/team-lead.md .codex/skills/ src/user/codex/skills/ .codex/agent-memory/ src/user.rs src/user/codex.rs docs/changelog/ | sort > "$STATE_DIR/snap-post-<name>.txt"
comm -13 "$STATE_DIR/snap-pre-<name>.txt" "$STATE_DIR/snap-post-<name>.txt"
```

   The delta is the `comm` output plus content changes to paths already dirty pre-run (attributed per the clean-surface answer). Post the `outcome:` and `delta:` comments; close the child on success. Empty delta + clean wrap-up report = legitimate no-op — the skills explicitly permit "no improvements found"; record `outcome: no-op`, not a failure.
6. **Child-agent guard** — the nested cycle's wrap-up `close_agent` calls are the between-run invariant. An abnormal end (operator interrupt, mid-cycle abort) can leave child agents alive. Recovery: read the nested cycle's local phase ledger for remaining agent IDs, use `wait_agent` to identify live agents, `send_input` a plain stop request when an agent can still answer, then `close_agent(target=<agent-id>)` for each remaining child. If the NEXT nested skill's first `spawn_agent` call reports an active-agent collision, run this guard, then re-invoke that skill once. A second collision → `FAILED: agent-collision`, stop the suite.
7. **Checkpoint (HARD GATE)** — `request_user_input`, including rate-limit re-attestation at the pre-flight thresholds:
   - **Continue** — proceed to the next run.
   - **Pause for /compact** — recommended after run 1 (evolve-agents is the heaviest run) and again after run 2, plus after any observed auto-compaction. The operator runs `/compact`, then prompts "continue evolve-suite"; on resume, re-derive completed-run state from the parent issue's child comments, not from summarized context.
   - **Stop — resume later** — resume contract: fresh session, `/evolve-suite skip=<completed names> days=… drift=…`, citing the parent issue. Clean by construction: completed runs' edits are already in the tree and Docket records which runs ran.
   - **(after a failed run only) Revert this run's delta vs keep partial edits** — revert uses the snapshot path list: `git checkout -- <modified paths>` plus `rm <new untracked paths>`. Default is KEEP: each evolve cycle applies per-target edits incrementally, and the gate exists precisely to flag any resulting incoherence.

   Guidance: a rate-limit-class failure recommends **Stop** (subsequent runs share the exhausted budget); a skill-internal abort permits **Continue** (the three surfaces are independent and execution is serial).

### Run-surface attribution table

This table is an attribution/rollback reference, not an enforcement input — the skills' own contracts govern their edits. It tells the operator which run a delta path belongs to and what a failed-run revert touches:

| Run | Expected surface | Shared (serial-safe) |
|---|---|---|
| evolve-agents | `src/user/codex/agents/*.toml`, `src/user/codex/personas/team-lead.md`, `docs/changelog/agents/` | `.codex/agent-memory/*/pitfalls.md` (appends + sole compaction authority, ADR 0001) |
| evolve-skills | `.codex/skills/*/SKILL.md`, `src/user/codex/skills/*/SKILL.md`, `docs/changelog/skills/` | `.codex/agent-memory/*/pitfalls.md` (appends) |
| evolve-config | `src/user.rs`, `src/user/codex.rs`, own `SKILL.md` CANONICAL blocks, `docs/changelog/config/` | `.codex/agent-memory/*/pitfalls.md` (appends) |

Pitfalls appends are serial and therefore race-free; no merge step exists or is needed.

---

## Context-Saturation Management (the central risk)

Three full multi-agent orchestrations plus the gate share ONE context window — there is no precedent for this in a single session. Treat auto-compaction as expected, not exceptional. The design stance is to make compaction survivable rather than pretend to prevent it:

- **Durable state at run boundaries.** Everything needed to resume is on disk before each checkpoint: Docket comments (which runs ran, outcomes, deltas), porcelain snapshots in `$STATE_DIR`, changelog files, and the tree itself.
- **Between-run compaction is the cheap case.** The checkpoint's Pause-for-/compact option aligns compaction with run boundaries, where transient state is at its minimum.
- **Mid-run compaction is the expensive case**, and it is the nested cycle's responsibility — not the suite's. Each evolve skill and agent definition carries its own post-compaction discipline (re-read before edit; orchestrator re-derivation); the suite neither protects nor claims to protect a nested cycle's internal state.

**Broken vs slow — the operator's heuristic.** A slow-but-healthy cycle still makes forward progress: new tool calls keep landing, the files being read and edited change from turn to turn, subagents emit fresh `send_input` reports or Docket comments, and the orchestrator's narration tracks its current phase. A broken cycle (mid-run compaction casualty) shows distinct signatures: repeated `wait_agent` no-progress observations for the same agent ID without intervening work; the orchestrator re-reads the same files repeatedly without acting on them; `send_input` or `close_agent` reports unknown/stale agent IDs; or the orchestrator restarts a phase already recorded in the local phase ledger. Slow → wait. Broken → stop the run, run the child-agent guard, mark the child `FAILED: saturation`, and take the checkpoint's Stop option with a fresh-session `skip=` resume.

**Fallback.** Residual risk is honestly Medium-High on a full pass. If supervised runs show routine mid-run breakage, drop to one-run-per-session operation — `/evolve-suite skip=…` once per session — same skill, same Docket spine, zero redesign.

---

## Gate

If ≥1 run completed (no-op counts), invoke the `evolve-coherence` skill in-session over the evolved tree — read-only by its No-Edit Guard, and the session has no active child agents at this point so its `spawn_agent` lifecycle is legal. Input context: the per-run changelog paths and any kept-partial warning from a failed run. The Coherence Report + Remediation Manifest land in-context; post the `manifest:` summary on the gate child and close it. Zero completed runs → skip the gate; the cycle failed.

---

## Wrap-up

1. `rm -rf "$STATE_DIR"` — snapshots only; nothing else to clean.
2. Close the parent with the cycle summary: per-run outcome + delta counts, trials/drift approved vs `proposed`, manifest headline, and the closing line "nothing committed — review with `git diff`".

---

## Failure Runbook

Index to the inline recovery contracts; each names its `FAILED:` class and primary home:

- **Skill abort mid-run** → `FAILED: <reason>` → child-agent guard (Run Loop step 6) + checkpoint revert-vs-keep (step 7).
- **Saturation** → `FAILED: saturation` → broken-vs-slow recovery (Context-Saturation Management) + checkpoint Stop.
- **Rate-limit mid-run** → `FAILED: rate-limit` → checkpoint guidance + Fallback; Stop recommended (remaining runs share the exhausted budget).
- **Leftover-agent collision** → `FAILED: agent-collision` (on 2nd) → child-agent guard (step 6).
- **Crash re-entry** → recover from Docket alone (Docket Protocol AUTHORITY rule → STATE_DIR + completed runs), child-agent guard, resume `/evolve-suite skip=<completed names>`.

---

## Rules

1. **Commit nothing, anywhere** — no `git add`/`commit`/`push` in this session or any nested cycle; no branches created; post-run `git status` shows only the cycles' legitimate uncommitted edits.
2. **The suite never creates its own worker cohort** — every spawned agent belongs to a nested cycle; the suite's `send_input` exists for the recovery guard only.
3. **Fixed serial order** — `agents` → `skills` → `config` → gate; never reorder, never run two cycles at once.
4. **Fail loud** — every failure class posts a `FAILED:` comment naming its recovery path; partial cycles are resumable via `skip=` by construction.
5. **Docket is authoritative** — durable state lands at run boundaries; after compaction or crash, re-derive from the parent issue's comments, never from summarized context.
