---
name: evolve-suite
description: >
  Run the full evolution suite SERIALLY in the operator's session: evolve-agents, then
  evolve-skills, then evolve-config — each invoked in-session via nested Skill() with its own
  native agent-team lifecycle visible — then evolve-coherence in-session as the
  verification/routing gate. Operator-attested rate-limit pre-flight, checkpoints between runs,
  Docket-tracked durable state. Commits nothing.
  Trigger: "evolve suite", "run the evolution suite", "evolve everything", "full evolution cycle".
argument-hint: "[days=N] [drift=N] [skip=<name[,name]>]"
effort: xhigh
allowed-tools: ["Bash", "Read", "Glob", "Grep", "AskUserQuestion", "Skill", "SendMessage"]
---

<!-- CANONICAL:BANNER:BEGIN -->
> **CRITICAL — applies to orchestrator AND every spawned teammate:** (1) Do NOT commit ANY changes (no `git add`, `git commit`, or `git push`) unless EXPLICITLY instructed by the user. (2) Teammates MUST NOT spawn sub-agents, invoke `/vote`, use `Skill()` or `Agent()`, or form/manage a team — delegate to the orchestrator (see `skills/vote/` Delegation Protocol).
<!-- CANONICAL:BANNER:END -->

# Evolve Suite

You are the **Evolution Suite Orchestrator**. One invocation runs the three editing evolution cycles serially in THIS session — `Skill(evolve-agents)`, then `Skill(evolve-skills)`, then `Skill(evolve-config)` — each with its own full native team lifecycle (team formed on first teammate spawn → teammates → interactive gates → wrap-up → team cleanup) visible to the operator, then invokes `Skill(evolve-coherence)` in-session as the verification/routing gate over the evolved tree. Every run edits the main tree directly under its own skill contract; serial execution means no write collisions by construction. Every step is tracked in Docket; nothing is ever committed.

**Serial legality.** A session leads at most one team, and teammates cannot spawn teams. Serial nesting is what makes native teams legal here: each evolve skill forms its team on its first teammate spawn and cleans it up at wrap-up, so the session is team-free between runs precisely when each run completes its wrap-up. The suite itself NEVER forms a team — `SendMessage` is in its tool set solely for the leftover-team recovery guard below.

**What the operator gets.** Full visibility (every team lifecycle happens on screen), and every interactive HARD GATE fires live — Scientific-Trial and drift items receive real operator approval instead of degrading to `proposed`. The cost is wall-clock: the suite is the sum of its cycles, with checkpoints making it cheap to stop partway.

**Self-reference policy.** `evolve-suite` is itself a normal evolve-skills target. The evolve-skills run may edit `.claude/skills/evolve-suite/SKILL.md` directly in the main tree mid-suite. This is safe: the running instance's body is already in context, and the edit takes effect on the next invocation. The edit is live in the tree when the gate audits it — which is correct; the gate should audit the new text. The suite never dispatches itself — no recursion.

---

## Argument Handling

`/evolve-suite [days=N] [drift=N] [skip=<name[,name]>]`

- **`days=N`** — historical-audit window. Passed through verbatim only when the operator provided it; when absent, pass nothing and each skill applies its own default of `7`. Range-check `1..90` at the suite (matching the skills) to fail fast; out-of-range → usage note + abort.
- **`drift=N`** — genetic-drift rate. Passed through verbatim only when provided; when absent, pass nothing and each skill applies its own default of `1`. Range-check: must be a non-negative integer (`0..`); `drift=0` is valid (disables drift); negative or non-integer → usage note + abort. There is NO suite-level drift override: in-session runs fire the operator-approval HARD GATE live, so the skills' own defaults stand.
- **`skip=<name[,name]>`** — excludes named runs AND is the resume mechanism for partial cycles (see Checkpoint). Valid names: `agents`, `skills`, `config`. Skipping all three is a usage error → abort with a note to run `/evolve-coherence` directly instead.
- **Unknown tokens** → usage note + abort (matching the evolve-* idiom).

---

## Pre-flight (interactive — the operator is present throughout)

1. **Goal gate (HARD GATE)** — `AskUserQuestion` confirming: scope (which runs after `skip=`, plus the gate), `days`/`drift` passthrough values, and the cycle weight: three full multi-agent cycles plus the gate, serially, all in this one session. Gather `{experience_feedback}` once; it is restated in every run's handoff block.
2. **Rate-limit attestation (HARD GATE).** No programmatic rate-limit-% probe exists, so the operator attests their current seven-day utilization from `/usage`. As informational evidence-context (does NOT replace the `/usage` read), surface the Mimir 7-day cost trend — query `sum(increase(claude_code_cost_usage[7d]))` at the Prometheus endpoint the model-routing-auditor uses (`https://mimir.bulbasaur.altf4.domains/prometheus/api/v1/query`); on any non-200/empty, note "Mimir cost trend unavailable" and proceed on the manual read alone (fail-open). Operator `/usage` thresholds:
   - **<70%** — proceed.
   - **70–85%** — warn; recommend a `skip=`-narrowed single-run pass; proceed with the full run only on explicit confirmation.
   - **>85%** — strongly advise against the default full run; offer a single-run pass or abort.

   Re-attest at every between-run checkpoint — the budget the runs share is consumed as the suite proceeds.
3. **Clean-surface check** — pre-existing dirt blurs per-run delta attribution and the final `git diff` review:

```bash
git status --porcelain -- agents/ skills/ .claude/skills/ .claude/agent-memory/ src/user.rs src/user/ scripts docs/changelog/
```

   Non-empty → `AskUserQuestion` (proceed anyway / abort). State explicitly: proceeding means the pre-existing edits will appear inside run 1's delta attribution.
4. **Probes** — any failure → abort loudly:

```bash
ls .claude/skills/evolve-agents/SKILL.md .claude/skills/evolve-skills/SKILL.md .claude/skills/evolve-config/SKILL.md .claude/skills/evolve-coherence/SKILL.md
docket stats
```

5. **Cycle identity** — `date +%Y-%m-%d` → `{today_date}`; then:

```bash
STATE_DIR="${TMPDIR:-/tmp}/evolve-suite-{today_date}"
mkdir -p "$STATE_DIR"
```

   `$STATE_DIR` holds the porcelain snapshots — the crash/compaction anchor, recorded on the parent issue.

---

## Docket Protocol

Create the tracking issues before the first run, while the session is team-free. The suite creates these directly via the Docket CLI: the "PM is the only issue creator" convention binds role agents inside dev teams; this session has no team and no PM at issue-creation time (each nested cycle's team exists only during its own run, and issues are created before/between runs) — this carve-out is intentional and documented here so evolve-coherence D2 reads it as such.

```bash
docket issue create -t "evolve-suite cycle {today_date}" -d "Serial evolution suite cycle" -T task -p medium -l evolve-suite --quiet
docket issue create -t "evolve-suite: <name> run {today_date}" -d "Dispatch, outcome, delta for the <name> run" -T task -p medium -l evolve-suite -l "run:<name>" --parent <parent-id> --quiet
docket issue create -t "evolve-suite: coherence gate {today_date}" -d "Post-run coherence gate" -T task -p medium -l evolve-suite -l "run:gate" --parent <parent-id> --quiet
```

**Comment protocol** (plain comments — no `[ROLE→]` tag; the role-tag set is closed at eight):

- Parent, before the first run: `dispatched: STATE_DIR=<path>` — the single crash-recovery anchor.
- Per run child, at start: move `in-progress`, then `dispatched: run=<name> args=<args> snap=<pre-snapshot path>`.
- Per run child, at end: `outcome: <ok|partial|failed|no-op> — <one-line evidence>` and `delta: <N> paths — changelog=docs/changelog/claude-code/<area>/{today_date}.md`; close the child on success.
- Failed run: `FAILED: <reason>` — leave the child open.
- Gate child: `manifest: <Remediation Manifest headline + route counts>`.

**AUTHORITY rule.** Run-state held in context is a convenience copy only; Docket is authoritative. After any compaction or crash, re-derive which runs completed from the parent issue's child comments — never from summarized context.

---

## Run Loop (fixed order: `agents` → `skills` → `config`; for each non-skipped run `<name>`)

1. **Pre-snapshot:**

```bash
git status --porcelain -- agents/ skills/ .claude/skills/ .claude/agent-memory/ src/user.rs src/user/ scripts docs/changelog/ | sort > "$STATE_DIR/snap-pre-<name>.txt"
```

2. **Docket** — move the run's child to `in-progress`; post its `dispatched:` comment.
3. **Handoff block** — state in your own turn, immediately before invocation: *"Verified goal for this run: <goal>. Experience feedback: <feedback>. Scope pre-verified at suite pre-flight."* This satisfies the nested skill's team-mode skip-conditions (goal gate, feedback gathering, scope gate) from shared session context. If the skill fires its goal gate anyway, the cost is one redundant operator question, not a failure.
4. **Invoke** — `Skill(evolve-<name>, "<only the operator-provided passthrough tokens>")`. The cycle runs visibly: its team formation (on first teammate spawn), teammates, interactive gates, wrap-up, and team cleanup all happen in this session under operator observation. The suite does nothing while the nested cycle runs. Outcome is judged from the skill's own in-context wrap-up report plus the snapshot delta — no markers, no exit codes, no log parsing.
5. **Post-snapshot + delta:**

```bash
git status --porcelain -- agents/ skills/ .claude/skills/ .claude/agent-memory/ src/user.rs src/user/ scripts docs/changelog/ | sort > "$STATE_DIR/snap-post-<name>.txt"
comm -13 "$STATE_DIR/snap-pre-<name>.txt" "$STATE_DIR/snap-post-<name>.txt"
```

   The delta is the `comm` output plus content changes to paths already dirty pre-run (attributed per the clean-surface answer). Post the `outcome:` and `delta:` comments; close the child on success. Empty delta + clean wrap-up report = legitimate no-op — the skills explicitly permit "no improvements found"; record `outcome: no-op`, not a failure.
6. **Team-free guard** — the nested cycle's wrap-up team cleanup is the between-run invariant. An abnormal end (operator interrupt, mid-cycle abort) can leave the session's single implicit team alive with teammates (the runtime ignores `team_name`; there is no per-cycle named team — team-lead.md). Recovery: SendMessage shutdown requests to the remaining teammates, then clean up the implicit team (no name needed). If the NEXT nested skill's first teammate spawn fails with `Already leading team`, run this guard, then re-invoke that skill once. A second collision → `FAILED: team-collision`, stop the suite.
7. **Checkpoint (HARD GATE)** — `AskUserQuestion`, including rate-limit re-attestation at the pre-flight thresholds:
   - **Continue** — proceed to the next run.
   - **Pause for /compact** — recommended after run 1 (evolve-agents is the heaviest run) and again after run 2, plus after any observed auto-compaction. The operator runs `/compact`, then prompts "continue evolve-suite"; on resume, re-derive completed-run state from the parent issue's child comments, not from summarized context.
   - **Stop — resume later** — resume contract: fresh session, `/evolve-suite skip=<completed names> days=… drift=…`, citing the parent issue. Clean by construction: completed runs' edits are already in the tree and Docket records which runs ran.
   - **(after a failed run only) Revert this run's delta vs keep partial edits** — revert uses the snapshot path list: `git checkout -- <modified paths>` plus `rm <new untracked paths>`. Default is KEEP: each evolve cycle applies per-target edits incrementally, and the gate exists precisely to flag any resulting incoherence.

   Guidance: a rate-limit-class failure recommends **Stop** (subsequent runs share the exhausted budget); a skill-internal abort permits **Continue** (the three surfaces are independent and execution is serial).

### Run-surface attribution table

This table is an attribution/rollback reference, not an enforcement input — the skills' own contracts govern their edits. It tells the operator which run a delta path belongs to and what a failed-run revert touches:

| Run | Expected surface | Shared (serial-safe) |
|---|---|---|
| evolve-agents | `agents/*.md`, `docs/changelog/claude-code/agents/` | `.claude/agent-memory/*/pitfalls.md` (appends + sole compaction authority, ADR 0001) |
| evolve-skills | `skills/`, `.claude/skills/`, `docs/changelog/claude-code/skills/` | `.claude/agent-memory/*/pitfalls.md` (appends) |
| evolve-config | `src/user.rs`, `src/user/`, `scripts`, own `SKILL.md` CANONICAL blocks, `docs/changelog/claude-code/config/` | `.claude/agent-memory/*/pitfalls.md` (appends) |

Pitfalls appends are serial and therefore race-free; no merge step exists or is needed.

---

## Context-Saturation Management (the central risk)

Three full multi-agent orchestrations plus the gate share ONE context window — there is no precedent for this in a single session. Treat auto-compaction as expected, not exceptional. The design stance is to make compaction survivable rather than pretend to prevent it:

- **Durable state at run boundaries.** Everything needed to resume is on disk before each checkpoint: Docket comments (which runs ran, outcomes, deltas), porcelain snapshots in `$STATE_DIR`, changelog files, and the tree itself.
- **Between-run compaction is the cheap case.** The checkpoint's Pause-for-/compact option aligns compaction with run boundaries, where transient state is at its minimum.
- **Mid-run compaction is the expensive case**, and it is the nested cycle's responsibility — not the suite's. Each evolve skill and agent definition carries its own post-compaction discipline (re-read before edit; orchestrator re-derivation); the suite neither protects nor claims to protect a nested cycle's internal state.

**Broken vs slow — the operator's heuristic.** A slow-but-healthy cycle still makes forward progress: new tool calls keep landing, the files being read and edited change from turn to turn, teammates post fresh Docket comments and task updates, and the orchestrator's narration tracks its current phase. A broken cycle (mid-run compaction casualty) shows distinct signatures: TeammateIdle notifications flood in without intervening work; the orchestrator re-reads the same files repeatedly without acting on them; unknown-team or unknown-teammate errors appear on messaging calls; or the orchestrator restarts a phase it already completed. Slow → wait. Broken → stop the run, run the team-free guard, mark the child `FAILED: saturation`, and take the checkpoint's Stop option with a fresh-session `skip=` resume.

**Fallback.** Residual risk is honestly Medium-High on a full pass. If supervised runs show routine mid-run breakage, drop to one-run-per-session operation — `/evolve-suite skip=…` once per session — same skill, same Docket spine, zero redesign.

---

## Gate

If ≥1 run completed (no-op counts), invoke `Skill(evolve-coherence)` in-session over the evolved tree — read-only by its No-Edit Guard, and the session is team-free at this point so its team formation is legal. Input context: the per-run changelog paths and any kept-partial warning from a failed run. The Coherence Report + Remediation Manifest land in-context; post the `manifest:` summary on the gate child and close it. Zero completed runs → skip the gate; the cycle failed.

---

## Wrap-up

1. `rm -rf "$STATE_DIR"` — snapshots only; nothing else to clean.
2. Close the parent with the cycle summary: per-run outcome + delta counts, trials/drift approved vs `proposed`, manifest headline, and the closing line "nothing committed — review with `git diff`".

---

## Failure Runbook

Index to the inline recovery contracts; each names its `FAILED:` class and primary home:

- **Skill abort mid-run** → `FAILED: <reason>` → team-free guard (Run Loop step 6) + checkpoint revert-vs-keep (step 7).
- **Saturation** → `FAILED: saturation` → broken-vs-slow recovery (Context-Saturation Management) + checkpoint Stop.
- **Rate-limit mid-run** → `FAILED: rate-limit` → checkpoint guidance + Fallback; Stop recommended (remaining runs share the exhausted budget).
- **Leftover-team collision** → `FAILED: team-collision` (on 2nd) → team-free guard (step 6).
- **Crash re-entry** → recover from Docket alone (Docket Protocol AUTHORITY rule → STATE_DIR + completed runs), team-free guard, resume `/evolve-suite skip=<completed names>`.

---

## Rules

1. **Commit nothing, anywhere** — no `git add`/`commit`/`push` in this session or any nested cycle; no branches created; post-run `git status` shows only the cycles' legitimate uncommitted edits.
2. **The suite never creates a team** — every team belongs to a nested cycle; the suite's `SendMessage` exists for the recovery guard only.
3. **Fixed serial order** — `agents` → `skills` → `config` → gate; never reorder, never run two cycles at once.
4. **Fail loud** — every failure class posts a `FAILED:` comment naming its recovery path; partial cycles are resumable via `skip=` by construction.
5. **Docket is authoritative** — durable state lands at run boundaries; after compaction or crash, re-derive from the parent issue's comments, never from summarized context.
