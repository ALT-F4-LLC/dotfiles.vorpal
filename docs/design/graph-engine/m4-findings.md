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
  FIX DESIGNED (2026-08-06): usage-backfill-wedge.md approved — `docket
  dispatch backfill-usage` (triples or --from-json), source free-text
  defaulting "backfilled", one transaction, no schema change (v10's source
  column anticipated exactly this).
  LANDED (2026-08-06, commit 2cb3127, DKT-77).
- E-4: `--accept-missing-usage` cannot clear D2. The probe is computed-never-
  stored from step status + usage_ledger and never reads close_reason
  (dispatch.go:448-505 vs :640). Acceptance lets the close succeed — its real
  contract — but `next` refuses forever once any step completes without
  usage; each later close re-accepts the ENTIRE set (audit noise grows one
  per completed step). Also: the D2 refusal names the instance (implement@0),
  not the step id — ambiguous with same-named instances across issues.
  ADJUDICATED (2026-08-06, wedge TDD §2(A)): working as designed —
  acceptance's contract is the close, not the probe; the missing state was
  usage, and the back-fill verb supplies it. Step-scoped acceptance REJECTED
  (it makes the ledger lie by design). The instance-vs-step-id message
  ambiguity is carried by E-13's round. The verb landed (2cb3127);
  the acceptance path is untouched per wedge §4.4.
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
  read-read coexistence. SECOND REFINEMENT (wave 6): claim races have no
  fairness — DKT-76 review fanout is 0-for-5 on claims, starved by whatever
  overlapping cluster spawns alongside it. The E-5 fix shape should include
  ordering (e.g. oldest-ready-first subsets), not only disjointness.
- E-12 (COMPOSITE, run-ending): builtin action steps are driven ONLY from
  next (driveActionSteps, next.go:205), which runs after
  refuseIfUnreconciledTx (next.go:137) returns early — so gap E-4's
  permanent D2 refusal starves every action step forever. RUN-3 wedged at
  DKT-75's reconcile with attempt 0. No verb, adaptation, or ordering
  reaches it; the pre-registration's halt-with-cause rule applies. Fix
  shape: drive actions before (or independent of) the discrepancy refusal,
  and/or fix E-4's acceptance semantics.
  FIX DESIGNED (2026-08-06): the back-fill verb (usage-backfill-wedge.md)
  retires the only discrepancy class that can stand while an action step is
  ready — back-fill quiets D2, next stops refusing, actions drive. The
  drive-before-refusal ordering half was REJECTED as designed at review:
  driveActionSteps runs AFTER tx.Commit() on the raw conn because the saga
  opens its own transactions and the pool is capped at one connection
  (next.go's own comment) — moving it into the tx deadlocks, and driving it
  durably before a refusal contradicts "a refused call must not
  half-advance the run". The starvation CLASS is filed as its own tracker
  issue instead of riding this TDD.
  LANDED (2026-08-06, 2cb3127): TestBackfillRetiresTheD2Wedge pins RUN-3's
  exact shape end-to-end; the starvation class is DKT-79.
- E-7 (pre-existing, surfaced): TestNextHumanTableUnchanged flakes on
  relative-timestamp rendering ("1 second ago" vs "now") — pin the clock.
  FIXED (2026-08-06, 063ee67): literal pinned instant, not a time.Now offset.
- E-8 (pre-existing, judge-proven wave 4): attempt DOUBLE-COUNT — ClaimStep
  increments attempt (steps.go:543) and FailStep bumps it again (human.go:269),
  so max_attempts=N exhausts after N-1 failures and the retry branch is
  unreachable; TestFailMetadataSurvivesIntoRetry is hollow-green (never
  retries). Three judges converged independently; STEP-2 probe-proved it.
  Also skews escalation arithmetic (attempt-derived rungs).
  FIXED (2026-08-06, 8c4076d): FailStep's bump removed; claimTx is now the
  SOLE increment (CAS + version + attempt in one statement — structural, not
  documented); caller-less BumpStepAttemptTx deleted with its phantom §6.10
  cite; TestAttemptCountsClaimsNotClaimsPlusFailures pins the arithmetic and
  the below-max test gained an explicit attempt==1 (status-only pins go
  hollow the other way).
- E-9 (judge-found wave 4): issue.diff omits UNTRACKED files — new files are
  invisible to review (STEP-11's entire guard_stop_test.go and the cli/guard.go
  adaptation were never in the reviewed diff). A review blind spot covering
  exactly the class of change (new tests) reviews most need to see.
  FIXED (2026-08-06, 4126a7c): untrackedDiff renders each untracked file as
  an addition appended after the tracked diff — non-mutating, no
  intent-to-add staging.
- E-11 (wave 5) — NOT REPRODUCED, engine exonerated (2026-08-06 review):
  the probe (input-payloads.md Part II) shows resolution is issue-scoped by
  construction (matchingArtifacts filters producer.IssueID before names,
  context.go:400-422), and RUN-3's own DB proves delivery was correct — all
  four DKT-75 review steps consumed ARTIFACT-3, DKT-75's OWN implement
  artifact (step_inputs, steps 12-15), whose recorded BODY was DKT-76's
  summary. The corruption predates the engine: see H-13 (shared scratchpad
  artifact path). Judges detected it and reviewed the correct diff anyway.
- E-13 (low, opened at E-11's adjudication): ContextInput.ProducerStep
  renders the bare instance name (producerInstance, context.go:505-510) with
  no issue qualification — four correct multi-issue briefs all label their
  producer implement@0, indistinguishable across issues (the same ambiguity
  E-4's refusal message carries). Deferred to its own round: changing the
  rendered producer identity alters every packet's bytes and every golden.
- E-10 (observed wave 4): under overlapping scopes and the commit-at-end
  workflow, issue.diff shows SIBLING issues' uncommitted work — a DKT-69
  judge reviewed and flagged DKT-75's guard.go change (cross-issue diff
  bleed; the fleet's cumulative-delta lesson reincarnated). Produced a
  cross-issue blocker inside DKT-69's reconcile. FINAL-REPORT CONSEQUENCE
  (ledger 28): DKT-69's severity set is inflated by a blocker DKT-75 owns —
  any threshold computed over DKT-69's clusters reads another issue's
  finding. Narrow scopes (P-5) or per-issue trees are the fix.

Fixed pre-run by the patch session, verified live in-run: DKT-68 (completion
metadata persisted; requested==resolved observed on real steps — no tier
drift) and DKT-70 (packet composition — see §5).

## 2. Harness defects (wave.js / render / conduct) — mostly FIXED or CAPPED

- H-1 FIXED: graph workflows/ was never rendered — wave.js unreachable at
  first spawn (F-M4-1). Render path added, committed.
- H-2 FIXED IN SOURCE (post-M4 batch, 2026-08-05): the harness JSON-encodes workflow args in
  transit; wave.js now decodes string args, refuses garbage. MUST be ported
  to the dotfiles source (src/user/claude-code-graph/workflows/wave.js) —
  the next `just activate` overwrites the rendered fix. Hashes on DOC-1:
  0c3aa1f8 (pinned) -> aa6ae41f (decode) -> 087c5ec4 (essay cap).
- H-3: Workflow({name:}) executes a stale registry snapshot — three runs ran
  pre-edit bytes after the file changed. scriptPath is the only
  deterministic invocation; conduct skill must say so.
- H-4 FIXED (post-M4 batch): the rendered claim command omits the REQUIRED --owner flag; every
  executor errors (exit 3) and improvises an owner string. One-line wave.js
  prompt fix.
- H-5 FIXED (post-M4 batch): nothing told executors DOCKET_TOKEN is already in env and must never
  be printed/re-exported — produced the token echo (token was dead-by-design
  at completion; transcripts retained as audit record). One-line prompt fix.
- H-6: executors are never told to pass --usage on complete (root of E-3's
  visibility; blocked on E-3 anyway since executors cannot know their usage).
- H-7 CAPPED, PORTED TO SOURCE (post-M4 batch): conflict-losers wrote 40-110KB investigation essays each;
  prompt now caps CONFLICT reports at three lines (087c5ec4), effective
  after DISPATCH-5.
- H-8 FIXED (post-M4 batch): the wave skill's invoke hint advertises policyPath; the script reads
  {rows, policyText} and can read no files. Cost failure #1.
- H-12 (ledger 27): synthesize briefs supply judge PROSE but not payload
  severities, which the contract requires clusters to carry unchanged — the
  executor recovered them by reading a DB copy, noting local sqlite 3.51
  cannot open the 3.53-written file in place. Brief assembly for
  synthesize-class steps must include input payloads, not only bodies.
  FIX DESIGNED (2026-08-06): input-payloads.md approved — ContextInput gains
  Payload carried VERBATIM (omitempty), InputsBytes accounts it, template
  renders it conditionally; payload-less packets stay byte-identical.
  LANDED (2026-08-06, f4e27ba, DKT-78): eight tests incl. fanout
  attribution and the live-state extension; engine-spec §11.4 row amended.
- H-13 (found 2026-08-06 adjudicating E-11; production-proven): the emit
  convention gives every executor the SAME session-scoped scratchpad path —
  STEP-11 (DKT-75 implement) and STEP-21 (DKT-76 implement) both completed
  with --artifact-file .../0132b2fd-.../scratchpad/change-summary.md
  (transcripts). Concurrent same-kind writers cross-wire, and the engine
  faithfully records the sibling's bytes (content is opaque to core). H-11's
  staged waves serialize writers but do NOT fix the stale-read half: an
  executor that never writes still completes citing the predecessor's
  leftover, silently. Fix (instance-side, REQUIRED before RUN-4):
  step-scoped artifact paths (scratchpad/STEP-N/<kind>.md) in the emit
  conventions, so a missing write is a missing file — loud — rather than a
  sibling's artifact.
- H-11 LANDED (post-M4 batch, operator-designed, wave-6 observation): STAGED WAVES — wave.js
  currently spawns all rows in one parallel blast (one phase). Using data
  rows already carry (class, issue), it can stage: serial write rows first
  (each awaited), then read rows grouped per issue (parallel within, awaited
  between) — eliminating every conflict class this run exhibited without
  filtering, scope data, or engine change. phase() labels make the stages
  visible in /workflows. Residual races (cross-run holders, mid-wave state
  drift) remain the engine fix E-5/E-6 target; this is the interim that
  makes RUN-4 cheap. Lands in the dotfiles wave.js batch.
- H-9 FIXED (post-M4 batch): conduct-skill edits owed: open-first loop (next
  is D2-wedged for any real run until E-4 resolves), back-fill-before-close
  ordering, the scriptPath rule, stop-opening-empty-dispatches guidance. All
  four written; the open-first fallback is written CONDITIONALLY (triggered by
  the `usage-rows-missing` refusal, reverts to next-first when E-4/E-12 lands)
  so it retires itself rather than becoming permanent folklore.

### Post-M4 harness batch (2026-08-05) — what landed in dotfiles source

Source of record: `src/user/claude-code-graph/`. The rendered copies under
`~/.claude/` had drifted AHEAD of source via the two authorized mid-run edits;
this batch heals that divergence in source, where it survives `just activate`.

- `workflows/wave.js` — H-2, H-7 (ported from the rendered copy), H-4, H-5,
  P-13, H-8, H-11. sha256 0c3aa1f8 -> 374e18ed. Verified: golden check PASS
  against an UNCHANGED policy.expected.json (2ca4a8bb, parser untouched);
  AC-2.2 resolver table re-run, 31/31 hints resolved, 0 unresolved, escalation
  /sensitivity/diamond-gating spot checks unchanged; staged wave demonstrated
  on a hand-built row set (2 writers + 2 issues' readers) — 10/10 assertions,
  peak concurrency 2 not 6.
- `skills/conduct/SKILL.md` — H-3 (scriptPath always), H-9's four items,
  P-13's routing half (executor rows only).
- `skills/plan/SKILL.md` — P-2 (rulings into BODIES; bodies freeze at
  activation, comments never reach briefs), P-5 (narrowest honest glob; a
  broad glob serializes the run against itself).
- `skills/bootstrap/SKILL.md` — P-1 (name trust entries after what the script
  does; propose genericity.sh as `genericity`, and state plainly that scope
  containment is ungated until the real script exists, DKT-74's batch).

Explicitly NOT in this batch, still open: H-12 and H-6 (engine-side — brief
payloads, usage back-fill verb), the AC7 hook-note/TDD updates (deferred to
RUN-4/DKT-76), and anything under the old fleet (M5's).

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
- P-7 CORRECTED BY SYNTHESIS (STEP-6, source-read saga.go:245/263/282):
  the inversion claim was FALSE — complete has the identical
  metadata-before-authorize ordering, so DKT-69 mirrors existing behavior.
  Residual question (both verbs): is that shared ordering itself wrong vs
  saga.go:277's stated rule? Carried as a design question, not a defect in
  the change. Judge-testing was right; judge-architecture's premise wrong;
  synthesis carried both severities unchanged and wrote the remedy to cover
  both verbs — the reconciliation layer working on the reviewers.
- P-10 (wave 5, judge-found, TWO independent probes with firing positive
  controls): landed DKT-75 re-introduces its own defect class — the new
  open-dispatch arm probes ALL discrepancies via refuseIfUnreconciledTx even
  with no open dispatch, and D2 fires on terminal steps, so any run with
  stranded usage (every real run until E-3/E-4) has a PERMANENTLY blockable
  stop. NOT operational in RUN-3 (running binary pinned pre-change) but must
  not ship unrepaired. Bundle: blocksStop helper no longer mirrors the
  predicate (comment lies); materialized=1 clause mutation-untested (=99
  stays green); no docs/ in the change set — contradicts §6.12 and H11's
  reviewed 2026-08-03 decision; SKILL.md now contradicts the TDD. Routed:
  wave-6 reconcile -> fix loop with judge findings as inputs (the designed
  reopen).
- P-12 (wave 6, DKT-76's four judges): doc-comment misattached to
  spawnReapVerdictAllRuns (spec text G5(b)/G9 now documents the wrong
  function; parser-confirmed); the all-runs denial embeds a remedy
  (guard spawn --ack-reap <seq>) that the same code refuses without --run —
  following the error verbatim yields VALIDATION_ERROR, on the hook-facing
  path DKT-76 exists for; refusal text claims fan-out risk that
  UNIQUE(reaped_seq) makes impossible (right code, wrong reason). Flows to
  DKT-76's synthesize/reconcile — which E-12 now blocks; carries to RUN-4.
- P-13 FIXED (post-M4 batch): an action-kind row was handed to the wave once;
  wave refused correctly but misdiagnosed it as policy drift — wave.js
  message fix joins the dotfiles batch; conduct routes executor rows only
  (ratified).
- P-11: item 23 RECURRED (second judge probe-file tree write, self-reported,
  cleaned, git-verified) — the sanctioned scratch path for read-class judges
  rises from nice-to-have to required.
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

## 7. Run close-out (2026-08-06)

RUN-3 abandoned, halt-with-cause, operator-ratified; cause = E-12; DOC-1
carries the record. Final: 9 waves / 13 dispatches / 53 spawns; 21 conflict
losses (~40%, essay-capped from wave 5); 18 steps done, 3 reconciles
ready-undriveable; spend 12.9/30 declared, 801,892 output tokens
journal-measured (ledger usage null throughout — E-3/H-6). Tree: +667/−77
across 16 files, three implemented+reviewed+synthesized changes, NOT
committed — each carries open findings (P-10 bundle on DKT-75; DKT-76's
remedy-contradiction; DKT-69's hollow-test/E-8). Syntheses ARTIFACT-23/33/35
(16,141 / 13,641 / 17,692 B) are RUN-4's fix-brief inputs. Conduct ledger
item 26 recorded as symptom of E-12 per its own final report. AC6/AC7 not
scorable as met (cross-repo files absent). Synthesis quality: severity
multisets verified identical to inputs; consensus never manufactured;
judge disagreement resolved by source-read (see P-7 correction).

Engine patch session 2 (2026-08-06), five commits, reviewed and accepted:
8c4076d E-8 · 2cb3127 DKT-77 (wedge verb) · f4e27ba DKT-78 (input payloads)
· 4126a7c E-9 · 063ee67 E-7. Suite green, QA 1839/1839, genericity 5/5.
Follow-ups for the next engine round, deliberately NOT drive-by-fixed:
(1) ZG contention flake — under load all five claim losers can busy-timeout
so zero surface CONFLICT; the one-winner invariant held both runs. Note on
DKT-35 (its test-side echo); candidate fix is dropping the >=1-CONFLICT-
loser assertion since the winner count already forbids the dangerous
outcome. (2) backfill-usage lacks a non-terminal-step guard: back-filling a
still-running step would later collide with the claimant's own
`complete --usage` at the unique key — loud and recoverable, and the
conduct flow (back-fill after completion, before close) never hits it, but
a one-clause refusal closes the misuse window. Remaining before RUN-4:
H-13 corpus fix (reviewer-owned, dotfiles), gates restoration (DKT-74),
repair issues from ARTIFACT-23/33/35 with rulings in bodies (P-2) and
narrow scopes (P-5).
