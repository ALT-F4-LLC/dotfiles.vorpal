# M4 findings register — RUN-3 (the v1 shadow run)

Canonical, compaction-proof record. Compiled by the reviewer 2026-08-06 from
the conduct session's ledger (21 items), the reviewer's trail, and source
verification. The disposition (07 §4 step 5) consumes THIS file. At run end,
the conduct session's final ledger is diffed against it; anything it carries
that this file lacks gets added before disposition.

## 1. Engine gaps (docket) — found by this run, OPEN

- E-3: no usage back-fill verb. 02 §7 promises "the run skill back-fills from
  the wave journal, source recorded"; no verb exists. Usage rides only on
  `step complete --usage`, which executors cannot self-report. Every step's
  measured usage is stranded journal-side; ledger usage stays null; spend
  tracks declared expected_cost only (the budget FLOOR is the enforcement by
  design — precision, not safety, is what degrades).
- E-4: `--accept-missing-usage` cannot clear D2. The probe is computed-never-
  stored from step status + usage_ledger and never reads close_reason
  (dispatch.go:448-505 vs :640). Acceptance lets the close succeed — its real
  contract — but `next` refuses forever once any step completes without
  usage; each later close re-accepts the ENTIRE set (audit noise grows one
  per completed step). Also: the D2 refusal names the instance (implement@0),
  not the step id — ambiguous with same-named instances across issues.
- E-5: ready sets are offered mutually-conflicting. Readiness checks scope
  against claimed/running only, never ready-vs-ready; dispatch rows carry no
  scope field, so the harness cannot filter. Cost: N-1 agent boots per
  overlapping cluster per wave (wave 3: 8 opus losses of 9 spawns).
- E-6: scope conflict is class-blind with a same-issue-only exemption
  (ready.go:616-643, scope.go:84-86). Different issues' READ steps exclude
  each other: review fanouts run four-at-once within an issue but serialize
  across issues. Fix candidates: class-aware read-read coexistence, or
  disjoint-subset next (pairs with E-5). REFINED (wave 5, operator-observed):
  artifact-only steps suffer it worst — synthesize reads recorded payloads,
  never the tree, yet inherits its issue's tree scope and lost a claim race
  to another issue's judges over files it would never open. The fix shape
  includes per-step scope exemption for artifact-only steps, not only
  read-read coexistence.
- E-7 (pre-existing, surfaced): TestNextHumanTableUnchanged flakes on
  relative-timestamp rendering ("1 second ago" vs "now") — pin the clock.
- E-8 (pre-existing, judge-proven wave 4): attempt DOUBLE-COUNT — ClaimStep
  increments attempt (steps.go:543) and FailStep bumps it again (human.go:269),
  so max_attempts=N exhausts after N-1 failures and the retry branch is
  unreachable; TestFailMetadataSurvivesIntoRetry is hollow-green (never
  retries). Three judges converged independently; STEP-2 probe-proved it.
  Also skews escalation arithmetic (attempt-derived rungs).
- E-9 (judge-found wave 4): issue.diff omits UNTRACKED files — new files are
  invisible to review (STEP-11's entire guard_stop_test.go and the cli/guard.go
  adaptation were never in the reviewed diff). A review blind spot covering
  exactly the class of change (new tests) reviews most need to see.
- E-10 (observed wave 4): under overlapping scopes and the commit-at-end
  workflow, issue.diff shows SIBLING issues' uncommitted work — a DKT-69
  judge reviewed and flagged DKT-75's guard.go change (cross-issue diff
  bleed; the fleet's cumulative-delta lesson reincarnated). Produced a
  cross-issue blocker inside DKT-69's reconcile.

Fixed pre-run by the patch session, verified live in-run: DKT-68 (completion
metadata persisted; requested==resolved observed on real steps — no tier
drift) and DKT-70 (packet composition — see §5).

## 2. Harness defects (wave.js / render / conduct) — mostly FIXED or CAPPED

- H-1 FIXED: graph workflows/ was never rendered — wave.js unreachable at
  first spawn (F-M4-1). Render path added, committed.
- H-2 FIXED (rendered copy only): the harness JSON-encodes workflow args in
  transit; wave.js now decodes string args, refuses garbage. MUST be ported
  to the dotfiles source (src/user/claude-code-graph/workflows/wave.js) —
  the next `just activate` overwrites the rendered fix. Hashes on DOC-1:
  0c3aa1f8 (pinned) -> aa6ae41f (decode) -> 087c5ec4 (essay cap).
- H-3: Workflow({name:}) executes a stale registry snapshot — three runs ran
  pre-edit bytes after the file changed. scriptPath is the only
  deterministic invocation; conduct skill must say so.
- H-4: the rendered claim command omits the REQUIRED --owner flag; every
  executor errors (exit 3) and improvises an owner string. One-line wave.js
  prompt fix.
- H-5: nothing tells executors DOCKET_TOKEN is already in env and must never
  be printed/re-exported — produced the token echo (token was dead-by-design
  at completion; transcripts retained as audit record). One-line prompt fix.
- H-6: executors are never told to pass --usage on complete (root of E-3's
  visibility; blocked on E-3 anyway since executors cannot know their usage).
- H-7 CAPPED: conflict-losers wrote 40-110KB investigation essays each;
  prompt now caps CONFLICT reports at three lines (087c5ec4), effective
  after DISPATCH-5.
- H-8: the wave skill's invoke hint advertises policyPath; the script reads
  {rows, policyText} and can read no files. Cost failure #1.
- H-9: conduct-skill edits owed: open-first loop (next is D2-wedged for any
  real run until E-4 resolves), back-fill-before-close ordering, the
  scriptPath rule, stop-opening-empty-dispatches guidance.

## 3. Process and instance-config findings

- P-1: the "scope" trust entry is mislabeled — bound to genericity.sh, which
  is not a scope-containment check. NO diff-within-declared-scope gate ran
  on any of the three landed changes. Reviewer approved the bootstrap list
  and missed it. Real scope-gate script is post-run work (with DKT-74's
  five unported gates).
- P-2: mid-run operator rulings have no channel into briefs — issue bodies
  snapshot at activation (freeze semantics, by design). Rulings go into
  bodies BEFORE activation, or flow via judge findings (inputs). The DKT-75
  gated ruling was reasoned around in a vacuum because it lived in a
  comment. REFINED wave 4: a judge CAN reach mid-run rulings by reading
  the tracker (read-class carries docket read verbs) — STEP-3 quoted the
  DKT-75 ruling verbatim from its comment, unprompted. The channel exists;
  it is discretionary, not guaranteed.
- P-3: DKT-75 landed with `gated` in the blocking set — over-conservative
  deviation from the recorded operator ruling (annoys, never endangers; it
  held the conduct session open during STEP-1's saga, exactly as
  characterized). Follow-up issue post-run, ruling in its body from birth.
- P-4: old-fleet stop-guard blocks no-team graph sessions contrary to its
  own self-scoping header (F-M4-2); redundant while run-guard also denies,
  wrong once the run completes. M5 deletes it regardless.
- P-5: broad scope globs (internal/engine/**) make the whole run serialize;
  planner guidance for the next run: narrow globs per issue, and expect E-5/
  E-6 economics until fixed.
- P-7 (wave 4, judge-found): FailStep validates content BEFORE authorizing
  the holder (human.go:250 vs :265), inverting saga.go:277's stated rule —
  a real defect in landed DKT-69, flowing to its fix loop via reconcile.
- P-8: bootstrap prompt omits --artifact-file/--payload-file on complete
  (conduct item 22) and read-class judges have no sanctioned scratch path —
  one copied a probe file into the tree, removed it, and self-reported
  (conduct item 23; the self-report is the discipline working).
- P-6: AC7 cross-repo remainder — DKT-76's hook-note + m3 TDD updates live
  in dotfiles, outside the executor's reach (operator follow-up). The
  companion lesson: ACs must not name files outside the run's repo.

## 4. Pre-registration deviations — the disposition weighs these

- wave.js hash amended twice mid-run (decode; essay cap), both with reasons
  on DOC-1; the decode was pre-first-spawn (zero agents had run).
- Loop adapted to open-first (E-4 forced it); empty-dispatch closes then
  retired after two noise rounds.
- --accept-missing-usage authorized by the operator for the run — a third
  case outside the flag's two anticipated ones (journal HAS the usage; the
  engine cannot receive it).
- Interventions exceeded the pre-registered list (plan approval, held
  findings, commit gate, reap-ack, sandbox prompts): transport debugging,
  two wave.js authorizations, multiple reviewer rulings, one issue-shape
  consult. By the pre-registration's own rule each extra intervention is a
  finding — T9 (zero-touch) took real damage this run, and the register
  says so plainly rather than smoothing it.

## 5. Positives — for the disposition, with the same weight

- Packet composition verified LIVE: wave-3 briefs carried contract +
  declared fragments inline (DKT-70 in production). The corpus steers real
  executors.
- Routing fidelity: every spawn policy-resolved (bronze implements, silver
  judges); requested==resolved on all recorded steps; AC-2.2b held — no
  model chose a tier anywhere.
- Executor discipline: 12 conflict-losses across three waves, zero fake
  completions, zero token-less recordings, zero routing-around; the no-token
  refusal reasoning was exemplary.
- Engine correctness invariants held throughout: atomic claims under 6-way
  contention, single-open dispatch CAS, manifest byte-verify, gates executed
  real trusted commands, budget floor enforced, zero state corruption
  across four failed pre-spawn runs + abandons.
- The guards guarded: run-guard's denials were correct every firing; the
  commit guard blocked exactly the writes it should until fixed to
  three-case semantics.
- P-9, LIVE-PROVEN (wave 4, reviewer-audited from transcripts): the severity
  emit-time mapping (M2b batch 7) held in production — four judges' payloads
  carried exactly the 02 §6 enum (blocker 1 / high 9 / medium 1 / low 7),
  zero authoring-ladder words leaked. The three-line CONFLICT cap is
  verbatim-complied across waves 4-5. Judges self-discovered the
  --payload-file mechanics via --help (the P-8 gap's honest workaround).
- Three real engine fixes landed with tests (DKT-75 closing 66+67, DKT-76
  closing 65, DKT-69), each through composed briefs, gates, and a human
  gate. Spend 4.5/30 declared at three-implementations-landed.

## 6. Run outcomes ledger (as of STEP-1 override-pass)

- STEP-21 (DKT-76) done · STEP-11 (DKT-75) done, gated deviation noted ·
  STEP-1 (DKT-69) done. All three: build/tests PASS, scope UNMATCHED (P-1).
- Remaining: 8 review steps, then synthesize/reconcile/verify/commit-gate
  per issue. Judges may independently flag the gated inclusion — the one
  channel (P-2) that carries the ruling into a fix brief.
