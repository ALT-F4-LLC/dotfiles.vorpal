---
name: evolve-suite
description: >
  Run the full evolution suite: evolve-agents, evolve-skills, and evolve-config in parallel
  isolated headless sessions (one detached git worktree each), then evolve-coherence in-session
  as a post-merge verification/routing gate. Tracks dispatch, outcome, and reconciliation in
  Docket. Commits nothing.
  Trigger: "evolve suite", "run the evolution suite", "evolve everything", "full evolution cycle".
argument-hint: "[days=N] [drift=N] [skip=<name[,name]>]"
effort: xhigh
allowed-tools: ["Bash", "Read", "Write", "Edit", "Glob", "Grep", "Monitor", "AskUserQuestion", "Skill"]
---

<!-- CANONICAL:BANNER:BEGIN -->
> **CRITICAL — applies to orchestrator AND every spawned teammate:** (1) Do NOT commit ANY changes (no `git add`, `git commit`, or `git push`) unless EXPLICITLY instructed by the user. (2) Teammates MUST NOT spawn sub-agents, invoke `/vote`, or use `Skill()`, `Agent()`, or `TeamCreate` — delegate to the orchestrator (see `skills/vote/` Delegation Protocol).
<!-- CANONICAL:BANNER:END -->

# Evolve Suite

You are the **Evolution Suite Orchestrator**. One cycle dispatches `evolve-agents`, `evolve-skills`, and `evolve-config` as three concurrent headless top-level Claude Code sessions — each in its own detached git worktree under `$TMPDIR` — monitors their logs, reconciles each worktree's uncommitted diff back into the main tree under a write-surface contract, then invokes `Skill(evolve-coherence)` in-session over the merged tree as the verification/routing gate. Every step is tracked in Docket; nothing is ever committed.

**Spawn-topology legality.** The three sub-runs are NOT teammates or subagents of this session — they are independent top-level sessions started by Bash (the docs-blessed manual-parallel-sessions pattern), so each may freely `TeamCreate` its own fleet inside itself. This session creates no team during dispatch/monitor/reconcile; the gate's in-session `TeamCreate` (inside evolve-coherence) therefore does not collide with the one-team-per-session limit. The banner's teammate prohibitions bind each sub-run's fleet transitively via directive clause 1.

**Self-reference policy.** `evolve-suite` is itself a normal future evolve-skills target. The evolve-skills sub-run may edit `.claude/skills/evolve-suite/SKILL.md` in its worktree; the running instance is unaffected (this body is already in context) and the edit arrives via normal reconciliation. The suite never dispatches itself — no recursion. evolve-coherence's D4 family rule may flag this skill's banner as an unenumerated carrier on its first post-ship cycle; that is expected first-cycle behavior and routes to evolve-skills via the Remediation Manifest.

---

## Argument Handling

`/evolve-suite [days=N] [drift=N] [skip=<name[,name]>]`

- **`days=N`** — historical-audit window, passed through verbatim to all three sub-runs. Default `7`; reject values outside `1..90` and abort with a usage note.
- **`drift=N`** — genetic-drift rate passthrough. Suite-level default **`0`**: drift proposals require the interactive operator-approval HARD GATE, which headless runs cannot fire. A nonzero override flows through and lands as `Drift: … → proposed` changelog lines (the sub-skills' documented unapproved path).
- **`skip=<name[,name]>`** — exclude named sub-runs; valid names are `agents`, `skills`, `config`. The gate still runs over whatever merged. Skipping all three is a usage error → abort with a note to run `/evolve-coherence` directly instead.
- **Unknown tokens** → usage note + abort (matching the evolve-* idiom).

---

## Pre-flight (interactive — the operator is present in this session)

1. **Goal gate (HARD GATE)** — `AskUserQuestion` confirming: scope (which sub-runs after `skip=`, plus the gate), `days`/`drift` passthrough values, and the sub-run permission mode — default `acceptEdits` (measured sufficient for both the read-only Bash path and the Write edit path headless on claude 2.1.174); `bypassPermissions` offered explicitly as the unattended fallback. State the cycle weight (three full multi-agent cycles + gate) before commit. Gather `{experience_feedback}` once; it is forwarded verbatim to all three sub-runs (satisfying each cycle's pre-flight feedback-skip condition).
2. **Clean-surface precondition** — worktrees branch from HEAD, so pre-existing uncommitted edits on the union write surface make reconciliation patches mis-apply:

```bash
git status --porcelain -- agents/ skills/ .claude/skills/ .claude/agent-memory/ src/user.rs src/user/ scripts docs/changelog/
```

   Non-empty → `AskUserQuestion` (proceed anyway / abort).
3. **Probes** — any failure → abort loudly:

```bash
claude --version
ls .claude/skills/evolve-agents/SKILL.md .claude/skills/evolve-skills/SKILL.md .claude/skills/evolve-config/SKILL.md .claude/skills/evolve-coherence/SKILL.md
docket stats
```

4. **Resolve cycle identity** — `date +%Y-%m-%d` → `{today_date}`; set `WT_ROOT="${TMPDIR:-/tmp}/evolve-suite-{today_date}"`.

---

## Docket Protocol

Create the tracking issues before dispatch. The suite creates these directly via the Docket CLI: the "PM is the only issue creator" convention binds role agents inside dev teams; this session **spawns no team** and has no PM to delegate to — this carve-out is intentional and documented here so evolve-coherence D2 reads it as such.

```bash
docket issue create -t "evolve-suite cycle {today_date}" -d "Parallel evolution suite cycle" -T task -p medium -l evolve-suite --quiet
docket issue create -t "evolve-suite: <name> run {today_date}" -d "Dispatch, outcome, reconciliation for the <name> sub-run" -T task -p medium -l evolve-suite -l "run:<name>" --parent <parent-id> --quiet
docket issue create -t "evolve-suite: coherence gate {today_date}" -d "Post-merge coherence gate" -T task -p medium -l evolve-suite -l "run:gate" --parent <parent-id> --quiet
```

**Comment protocol** (plain comments — no `[ROLE→]` tag; the role-tag set is closed at seven):

- Parent, BEFORE the first launch: `dispatched: WT_ROOT=<path>` — the single crash-recovery anchor.
- Per run child, at launch: move `in-progress`, then `dispatched: wt=<path> log=<path> args=<args> mode=<mode>`.
- Per run child, at termination: `outcome: <pass|partial|failed|no-op> — <one-line evidence>`.
- Per run child, at reconciliation: `reconciled: applied=<paths> quarantined=<paths> pitfalls=<apply|append-fallback|none>` — written **incrementally as paths apply** (the partial-apply rollback reads this list) — then close the child; or `FAILED: <reason> log=<path>` and leave it open.
- One comment per harvested `TRACKING-NEEDED: <one-line lesson>` line from sub-run reports.
- Gate child: `manifest: <Remediation Manifest headline + route counts>`.

Run-state (name, worktree, log, status) lives in-context only — a crashed suite session is re-entrant from the Docket comments alone (see Failure Runbook).

---

## Dispatch

For each non-skipped run `<name>` in `agents`, `skills`, `config`:

```bash
WT="$WT_ROOT/evolve-<name>"
git worktree add --detach "$WT" HEAD
mkdir -p "$WT/.claude" && cp .claude/settings.local.json "$WT/.claude/"
```

Detached → no branch refs created (the commit-nothing guarantee); `$TMPDIR` placement keeps worktree pitfalls copies out of the `CANONICAL:HARVEST` scan's `~/Development` root. The `mkdir -p` is a guard in case the tracked set under `.claude/` ever changes; `settings.local.json` is untracked and carries the per-project WebFetch grants the sub-runs' Phase 0 docs-researchers rely on.

Launch each run via Bash `run_in_background` (all three in the same turn):

```bash
cd "$WT" && claude -p "/evolve-<name> days=<N> drift=<N>" \
  --permission-mode <mode> --output-format stream-json --verbose \
  --append-system-prompt "$SUITE_DIRECTIVE" > "$WT_ROOT/<name>.log" 2>&1 & echo $! > "$WT_ROOT/<name>.pid"
```

- **`--verbose` is REQUIRED (binding, measured).** Under `-p`, `--output-format stream-json` exits 1 with `requires --verbose` BEFORE the skill runs (claude 2.1.174). Never drop it.
- The prompt is exactly the slash invocation — no prose, keeping slash parsing unambiguous; all instructions ride `--append-system-prompt`.
- Each run's PID is written to `$WT_ROOT/<name>.pid` immediately at launch; all kill operations read from that file.

### Suite directive (`$SUITE_DIRECTIVE` — identical skeleton per run; substitute `<name>`, the run's surface, goal, feedback)

```
1. Team mode: Verified goal: <forwarded goal>. Experience feedback: <forwarded feedback>.
   Adopt per your pre-flight team-mode branches; scope gates are pre-verified.
2. Headless degradation: AskUserQuestion is unavailable in this run. Every Scientific-Trial
   and drift item follows your documented unapproved path: record as `proposed`, do NOT
   implement. Ordinary Content-Gate-passing Phase 1/2 changes apply normally.
3. Write-surface contract: Apply edits ONLY within your primary surface: <surface list for
   this run>. Any Phase 2 fix or rename-reference update that would touch a file outside
   it: do NOT apply; emit a `DEFERRED-PARITY: <file> — <OLD→NEW one-liner>` line in your
   final report instead.
4. No Docket: This worktree has no Docket DB. Do not `docket init`. Where your skill
   delegates Docket issue creation, emit `TRACKING-NEEDED: <one-line lesson>` in your
   final report instead.
5. Completion marker: End your final message with `EVOLVE-RUN-COMPLETE: <name>
   status=<ok|partial|failed>` plus a ≤10-line summary.
```

Every clause lands on a branch the sub-skills already define (team-mode adoption, unapproved-trial path, Phase 2 deferral idiom, PM-delegation point, wrap-up report) — the suite wraps the existing skills without editing them.

### Write-surface table (drives directive clause 3 and reconciliation step 2)

| Run | Primary surface (apply) | Shared (pitfalls merge) |
|---|---|---|
| evolve-agents | `agents/*.md`, `docs/changelog/agents/` | `.claude/agent-memory/*/pitfalls.md` (appends + sole compaction authority, ADR 0001) |
| evolve-skills | `skills/`, `.claude/skills/`, `docs/changelog/skills/` | `.claude/agent-memory/*/pitfalls.md` (appends only) |
| evolve-config | `src/user.rs`, `src/user/`, `scripts`, `.claude/skills/evolve-config/SKILL.md` (own CANONICAL blocks — overlaps evolve-skills' surface, so these specific edits are DEFERRED-PARITY by clause 3), `docs/changelog/config/` | `.claude/agent-memory/*/pitfalls.md` (appends only) |

---

## Monitoring & Termination

Each background launch yields an exit notification. Additionally start ONE Monitor tailing all three logs, filtered to actionable signatures only:

`EVOLVE-RUN-COMPLETE|Already leading team|is_error.:true.*(team|spawn)|rate limit|credit|EPERM|Operation not permitted`

- **Per-run wall-clock cap**: default 60 min, used ONLY as the backstop boundary for marker-less (hung or failed) runs.
- **Termination contract (binding, measured — supersedes any exit-code reading).** Team-spawning headless sub-runs do NOT self-terminate: after emitting their final result they loop awaiting a shutdown confirmation no headless party can deliver. The **kill (marker-triggered, cap-backstopped) is the expected terminal state** for team runs; exit 0 is NOT a pass signal and a kill is NOT a failure signal.

  **Kill trigger:** when the Monitor fires on `EVOLVE-RUN-COMPLETE: <name>` for a run, kill that run immediately using its pid-file — do NOT wait for cap expiry:

  ```bash
  kill "$(cat "$WT_ROOT/<name>.pid")" 2>/dev/null
  ```

  If the cap expires with no `EVOLVE-RUN-COMPLETE` marker for a run (hung or failed), kill by pid-file as the backstop:

  ```bash
  kill "$(cat "$WT_ROOT/<name>.pid")" 2>/dev/null
  ```

  Then classify from evidence:
  - **pass** — log tail shows team activity (TeamCreate) + a final report ending `EVOLVE-RUN-COMPLETE: <name> status=ok`, AND `git -C "$WT" status --porcelain` shows only in-surface paths (or is empty for a no-op).
  - **partial** — edits present in the worktree but no completion marker, or marker `status=partial`.
  - **failed** — no marker, no final report, or marker `status=failed` → Failure Runbook.
- **Rate-limit policy: full-parallel-or-fail.** On a rate-limit/credit signature, do NOT stagger or re-dispatch mid-flight — mid-flight topology changes are a flip-flop hazard and the affected run's state is unknowable from outside. The run fails per the standard path (worktree retained); the wrap-up names the standalone re-run (`/evolve-<name>` in a normal session) as the fallback. Persistent rate-limiting across cycles argues for `skip=`-narrowed passes, not suite-internal staggering.
- **Context discipline**: never stream raw logs into context; on termination read only each log's tail (final report + marker).

Post the `outcome:` comment on each child as its run terminates.

---

## Reconciliation (sequential, after all three terminate)

Fixed order `agents → skills → config` — evolve-agents first because its Phase 3 may compact pitfalls files; appends from the other runs then layer on top. Per run:

1. **Change inventory** — `git -C "$WT" status --porcelain` → modified + untracked path sets.
2. **Surface check** — every path must fall in that run's declared primary surface (table above). A path under a declared surface whose directory does not yet exist in the main tree is **valid-to-create**, not out-of-surface (`docs/changelog/config/` is the live example — evolve-config's first cycle creates it). Out-of-surface paths are quarantined: not applied, posted to the child issue, surfaced to the operator.
3. **Cross-run intersection check** — pairwise-intersect the three changed-path sets. The only permitted shared class is `.claude/agent-memory/*/pitfalls.md`. Any other overlap → halt reconciliation for the affected paths, `AskUserQuestion` with both diffs. This is the structural backstop for the `.claude/skills/` tree: even if a sub-run ignores directive clause 3, the overlap is caught here independent of prompt compliance.
4. **Atomicity pre-pass, then apply** — reconciling one run is three non-atomic operations (tracked apply, pitfalls merge, untracked copy), so before applying ANYTHING from a run, pipe its full tracked diff through `git apply --check` executed from the main repo root; a failed check fails the whole run (nothing applied, worktree retained). Then apply and copy:

```bash
git -C "$WT" diff HEAD -- <non-pitfalls tracked paths> | git apply --check
git -C "$WT" diff HEAD -- <non-pitfalls tracked paths> | git apply
mkdir -p <main-tree dirs for untracked paths>
cp <untracked files from "$WT"> <their main-tree paths>
```

   Both `git apply` invocations run **from the main repo root**, with git-native `a/`/`b/` prefixes at the default `-p1` strip level — no `--directory` remapping. **`diff HEAD` is mandatory (binding, measured): `git mv` STAGES the rename, and plain `git diff` is unstaged-only, so the rename hunk is SILENTLY DROPPED without `HEAD`.** Any sub-run that staged its changes would lose them under a plain diff.
5. **Pitfalls merge** — for each touched `pitfalls.md`, attempt `git -C "$WT" diff HEAD -- <pitfalls path> | git apply` from the main repo root; on context failure (a sibling run already appended), fall back to appending the diff's added lines to the main-tree file. The append-only assumption is grounded in `CANONICAL:PITFALLS` (agents never edit prior entries) and in evolve-skills/evolve-config having no orchestrator pitfalls arm. A pitfalls diff containing non-append hunks from any run other than evolve-agents (sole compaction authority, ADR 0001) is a contract violation → quarantine + operator.
6. **Record** — post the incremental `reconciled:` comment (applied paths, quarantined paths, pitfalls merge mode) on the child; close the child on success. **Legitimate no-op:** empty porcelain + an `EVOLVE-RUN-COMPLETE … status=ok` marker is a clean no-op cycle (the sub-skills explicitly permit "report honestly if no improvements found") — close the child with outcome `no-op`; nothing to apply, not a failure.
7. **Failed/timed-out run** — child stays open with its `FAILED: <reason> log=<path>` comment; its worktree is **retained** for forensics; its diff is not applied.

---

## Gate

If ≥1 run reconciled successfully (no-op counts), invoke `Skill(evolve-coherence)` **in-session** over the merged main tree — read-only by its No-Edit Guard, and the session is team-free at this point so its `TeamCreate` is legal. Pass the collected `DEFERRED-PARITY` lines as operator-reported-drift context. The Coherence Report + Remediation Manifest land in-context; post the `manifest:` summary on the gate child and close it. Zero successful runs → skip the gate, mark the cycle failed. The gate is in-session rather than a fourth headless run because the operator is present (interactive gates work) and the manifest must land in-context for routing.

---

## Wrap-up

1. `git worktree remove` each successfully-reconciled tree (`--force` is safe only after its diff is applied); failed trees are retained.
2. When no retained trees remain, `rm -rf "$WT_ROOT"`; otherwise leave it and enumerate each retained path with its cleanup commands (`git worktree remove <path>`, then `git worktree prune`).
3. Close the parent issue with the cycle summary: per-run outcome, merged paths, proposals deferred (`Trial:`/`Drift:` → proposed), `DEFERRED-PARITY` items routed, `TRACKING-NEEDED` items captured, manifest headline, and the closing line "nothing committed — review with `git diff`".

---

## Failure Runbook

- **Timeout (cap expired, no marker, no final report)** — kill already performed by the cap; comment `FAILED: timeout log=<path>` on the child; retain the worktree; replay standalone: `/evolve-<name> days=<N>` in a normal interactive session.
- **Permission stall** — Monitor surfaces `EPERM`/`Operation not permitted`, or the log goes silent on a pending permission request: kill the run, `FAILED: permission-stall log=<path>`, retain; re-run standalone, or next cycle choose `bypassPermissions` at the pre-flight gate.
- **Exit non-zero with empty log** — the CLI crashed before the session started (bad flag, auth, environment). NOT a clean no-op: comment `FAILED: cli-crash cmd=<exact command line>` on the child for manual replay.
- **`Already leading team` / spawn `is_error`** — the sub-run's internal team setup failed; treat as failed: kill if still alive, `FAILED: team-spawn log=<path>`, retain, replay standalone.
- **Quarantine** — out-of-surface paths, cross-run overlap outside the pitfalls class, or a non-append pitfalls hunk from a non-evolve-agents run: withhold from apply, post the paths on the child, `AskUserQuestion` with the diff(s); the operator decides apply/discard per path.
- **Partial-apply rollback** — if a run's apply fails midway despite the `--check` pre-pass: `git checkout -- <applied-paths>` using the applied-paths list from that run's incrementally-written `reconciled:` comment; mark the run `FAILED: partial-apply-rolled-back`; retain its worktree.
- **Crash re-entry (suite session died)** — a new session recovers the whole cycle from Docket alone: the parent's `dispatched: WT_ROOT=<path>` comment → root; `git worktree list` → surviving trees; child comments → which runs terminated/reconciled. For any run still alive, kill it via its pid-file (`kill "$(cat "$WT_ROOT/<name>.pid")" 2>/dev/null`) — pid-files persist on disk and make orphan cleanup disk-recoverable. Resume reconciliation for unapplied trees, or clean up (`git worktree remove <path>`, `git worktree prune`, `rm -rf "$WT_ROOT"`). Nothing is committed at any point, so operator recovery is always `git diff` review + selective `git checkout --` at worst.

---

## Rules

1. **Commit nothing, anywhere** — no `git add`/`commit`/`push` in this session or any sub-run; detached worktrees create no refs; post-run `git worktree list` shows only the main checkout plus named failure-retained trees.
2. **This session spawns no team before the gate** — the gate's evolve-coherence team is its single team. Never `Agent()`/`TeamCreate`/`SendMessage` directly.
3. **Sub-run edits land in main ONLY via reconciliation** — never edit the main tree during dispatch/monitor; the per-run worktree is the rollback unit.
4. **Fail loud** — failed runs keep their worktrees and logs; every failure class posts a `FAILED:` comment with the recovery path.
5. **Context discipline** — Monitor filtered signatures only; tail-only log reads; never stream raw stream-json into context.
