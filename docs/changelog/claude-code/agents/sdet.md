# Changelog: sdet

## 2026-07-30

### Summary
sdet holds the fleet's only high-volume BINDING `effort:` pin — the default `verifier` is a report-only subagent — so `xhigh` → `high` lands here with real reach. Paid for by six §1.5/§1.6 culls. Net −106 (42409 → 42303).
Trial: `effort: high` — BINDING measured (report-only 9/9 honored the pin, n≈480); QUALITY delta unmeasured, no eval exists. Adopts-or-rolls-back at the next Phase 0.
Findings: 9 → 6 sub / 2 cos / 4 rej / 2 def / 4 enc

### Changes
- AMPLIFY[SUBSTANTIVE] (I4+I11): `effort: xhigh` → `high` + binding-provenance comment; 5 report-only spawns = 67% of all fleet binding dispatch.
- CULL[SUBSTANTIVE] (§1.6): shell-hygiene restatement → citation of `senior-engineer.md §Shell hygiene`; the local copy was over-broad and contradicted the master.
- CULL[SUBSTANTIVE] (§1.5): three blocks `verify-ac/SKILL.md` already owns cut to their deltas — step-2 diff reading, edge-probe inputs, FULL-depth enumeration.
- CULL[COSMETIC] (§1.5): third in-file carrier of "no Docket issue creation" removed; routing kept.
- FIX[SUBSTANTIVE]: mode discriminator made deductive — Task family PRESENT ⇒ teammate, not "inconclusive"; the stated premises already entailed it.
- FIX[SUBSTANTIVE]: BLOCK routing corrected to the implementing seat, adding @distinguished-engineer's deep-impl arm (the matrix had no DE row).
- REJECTED (B3): zsh `status` fix belongs in `senior-engineer.md`, the master — adding it here is a second carrier (§1.5); none of B3's 4 sessions were sdet spawns.

### Dimensions Evaluated
All 9, two passes. 4 caps markers, zero unmappable (§2.1/§2.3).

### Rename
No rename.

## 2026-07-27

### Summary
Compacted 7 entries (2026-07-12..2026-07-15) into Compacted history per the retention-compaction policy.

### Changes
- Replaced the 7 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (retention-compaction policy)

### Rename
No rename.

## 2026-07-27

### Summary
Phase 3 disambiguation: the cross-cutting re-sweep is restated as the verifier's own duty rather than an inert brief-side obligation.

### Changes
- FIX[SUBSTANTIVE] (DISAMBIG 10): Verifier Composition -- "Default-verifier brief phrasing" retitled "Cross-cutting-sweep re-sweep duty -- YOURS, whether or not the brief says it"; the verifier re-sweeps the whole tree unconditionally, with team-lead.md step 15 named as the brief-side half. @sdet authors no brief, so the prior phrasing left the duty ownerless.

### Dimensions Evaluated
Disambiguation (Phase 3): overlapping-ownership

### Rename
No rename.

## 2026-07-27

### Summary
Phase 2 coherence: teammate-path verdict adopts the fleet-standard terminal-state marker (report-only verifier explicitly excluded); incoming testability consult recognizes the Medium+ @distinguished-engineer author seat.

### Changes
- FIX[SUBSTANTIVE] (I8): Shutdown-by-mode teammate precondition leads the verdict SendMessage with the exact marker literal (master: senior-engineer.md Shutdown Handling step 3); report-only path excluded -- its plain-text-and-END contract has no shutdown await.
- FIX[SUBSTANTIVE] (bidirectionality): incoming testability-consult trigger extended to @distinguished-engineer (tdd-author / Medium+ advisor), matching DE's outbound consult-@sdet trigger.

### Dimensions Evaluated
Coherence & Cross-Communication (Phase 2)

### Rename
No rename.

## 2026-07-27

### Summary
Normalized `sdet-{ID}` -> `sdet-{DOCKET-ID}`, deleted the unreachable Edit/Write-absent fallback,
fixed ack templates to require SendMessage's `summary`, added an unscripted edge-probing pass, and
fixed a Testing Philosophy contradiction. Net +727 (60,374 -> 61,101).

### Changes
- FIX[COSMETIC] (C6): `sdet-{ID}` -> `sdet-{DOCKET-ID}` at both sites.
- CULL[SUBSTANTIVE] (D1): removed the unreachable Edit/Write-absent `$TMPDIR` fallback -- `memory: project` force-enables Read/Write/Edit; retained the still-live zsh heredoc warning.
- FIX[SUBSTANTIVE] (B1): ack templates now require `summary` on a plain-string `message`.
- AMPLIFY[SUBSTANTIVE]: new unscripted edge-probing pass (<=5 probes outside ACs, non-UX surfaces) -- closes the one industry QA function with zero prior coverage (sdlc-role-researcher).
- CULL[COSMETIC]: dropped a redundant LIGHT/FULL restatement the same sentence forbids duplicating.
- FIX[SUBSTANTIVE]: Greenfield strategy no longer orders snapshots before unit tests, which contradicted Testing Philosophy's rule-out of unverified snapshots.

### Dimensions Evaluated
Completeness, Consolidation & Trimming, Spec Alignment, Capability Growth, Actionability

### Rename
No rename.

## 2026-07-27

### Summary
Compacted 4 entries (2026-07-10..2026-07-11) into Compacted history per the retention-compaction policy.

### Changes
- Replaced the 4 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (retention-compaction policy)

### Rename
No rename.

## 2026-07-27

### Summary
Phase 2 coherence: AskUserQuestion hedge corrected; CANONICAL:PITFALLS compacted to a pointer; orphaned red_green_verify.sh wired into the red-green discipline bullet; a stale non-resolving path fixed.

### Changes
- FIX[SUBSTANTIVE]: "absent in the common team-mode spawn" -> "stripped from EVERY teammate and subagent spawn unconditionally (sub-agents.md first tool filter)".
- AMPLIFY[SUBSTANTIVE]: red-green bullet now cites `red_green_verify.sh` (stale I-sdet1 deferral: script now exists, wraps regression_diff.sh mechanics into a one-call red-then-green proof).
- CULL[SUBSTANTIVE]: CANONICAL:PITFALLS (2,811B) -> CANONICAL:PITFALLS-LOCAL pointer.
- FIX[MECHANICAL]: `agents/senior-engineer.md` -> `senior-engineer.md` (non-resolving path literal).

### Dimensions Evaluated
Coherence & Cross-Communication (Phase 2)

### Rename
No rename.

## 2026-07-27

### Summary
Consolidated the report-only-vs-teammate mode split from 7 restatement sites to §Lifecycle as sole authority (I7), and paid the savings into a Task-family mode self-check, the foreground-pipe false-GREEN trap, the empty-`-m` editor hang, and R1 script-path trust. Net +959 (59,991 -> 60,950).

### Changes
- CULL[SUBSTANTIVE] (I7): §Lifecycle designated the file's single mode-split authority; comm rule 6, comm-rule preamble, Verifier Composition default, Inter-Agent preamble, Execution step 5, and Shutdown by mode reduced to pointers with all mode-specific uniques preserved (-1,029).
- AMPLIFY[SUBSTANTIVE] (D1): §Lifecycle gains a Task-family mode self-check (teammates always keep the task tools; the background filter strips them) and labels report-only SendMessage silence a DOCTRINE choice, not a harness limit.
- FIX[SUBSTANTIVE] (D1): Execution step 4 no longer instructs the default report-only mode to use TaskCreate/TaskUpdate; the Tool envelope Task-family hedge is now a rule, not "absent in some spawn contexts".
- AMPLIFY[SUBSTANTIVE]: foreground `<cmd> | tail; echo $?` reports tail's exit -- a failing suite reads as a clean PASS; never measure a verdict-bearing exit through a pipe.
- AMPLIFY[SUBSTANTIVE]: an empty `docket ... -m` value opens `$EDITOR` and hangs to timeout; stage-and-post in ONE Bash call and echo `${#VAR}` first.
- AMPLIFY[SUBSTANTIVE] (R1): R1 now says to trust doctrine-cited `~/.claude/scripts/*.sh` paths without an existence check.

### Dimensions Evaluated
Consolidation & Trimming, Completeness, Actionability, Spec Alignment, Capability Growth, Role Realism, Boundary Clarity

### Rename
No rename -- sdlc-role-researcher confirms QA/SDET industry mapping.

## 2026-07-21

### Summary
Compacted 3 entries (2026-07-01..2026-07-10) into Compacted history per the retention-compaction policy.

### Changes
- Replaced the 3 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (retention-compaction policy)

### Rename
No rename.

## 2026-07-21

### Summary
Phase 3 disambiguation: "Stateless subagent" → "Stateless between spawns" to remove a confusable-name collision with the reserved report-only-subagent mechanism term — sdet's own file is where the teammate-vs-report-only-subagent split matters most.

### Changes
- FIX[COSMETIC]: Operating context now reads "Stateless between spawns" instead of a role-level "subagent" label that could prime the wrong dispatch mode.

### Dimensions Evaluated
Confusable-name clarity (Phase 3).

### Rename
No rename.

## 2026-07-21

### Summary
Consolidated report-only-verifier "no SendMessage" caveat from Comm Discipline rules 2/7/8 into one preamble above the numbered rules (I-sdet2); wired zero-citation `copy_verify.sh` into §Verification Workflow as a deterministic UX-copy-literal check (I-ux2). Net +323. Findings: 7 → 3 sub / 0 cos / 1 rej / 1 def / 0 enc. Drift: reworded 'Over-mocking' bullet (Testing Philosophy) to an equivalent formulation → applied.

### Changes
- CULL[SUBSTANTIVE] (I-sdet2): hoisted the "teammate/paired paths only" caveat (rules 2, 7, 8) into one mode-applicability preamble above the numbered rules; removed all 3 individual restatements.
- AMPLIFY[SUBSTANTIVE] (I-ux2): §Verification Workflow now cites `copy_verify.sh` as the deterministic UX-copy-literal check against a `docs/ux/` spec.
- Drift[COSMETIC] (DRIFT-sdet-L137): reworded the "Over-mocking" bullet (Testing Philosophy) to an equivalent formulation, surfacing the refactor-breakage "tell" explicitly.

### Dimensions Evaluated
Consolidation & Trimming, Capability Growth & Cross-Communication. Deferred: I-sdet1 (red_green_verify.sh doesn't exist). No-op: B4 (no gap in this file).

### Rename
No rename.

## 2026-07-15

### Summary
Compacted 4 entries (2026-06-30..2026-07-01) into Compacted history per the retention-compaction policy.

### Changes
- Replaced the 4 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (retention-compaction policy)

### Rename
No rename.

## Compacted history

Entries below were compacted per ADR 0001; full text in git history (see the compaction entry's date).

- 2026-03-19: Major consolidation from 867 to 308 lines. Merged verbose responsibility sections, eliminated redundant and generic content, compressed all…
- 2026-03-19: Added stateless operating context, removed non-executable human-process sections (Test Planning, Communication Style), compressed…
- 2026-03-19: Tightened greenfield strategy to reference spec, removed redundant "Running Tests" subsection, replaced prose review section with actionable…
- 2026-03-19: Compressed Inter-Agent Communication section (-20 lines of redundant status/intelligence lists), added greenfield zero-test handling, tightened…
- 2026-03-20: Consolidated Operator Alignment into Check Specs preamble, compressed Testing Philosophy, removed inverse /vote guidance, added effort…
- 2026-03-20: Consolidated flaky test management into diagnosis workflow, trimmed redundant philosophy opener, added BLOCK notification trigger and…
- 2026-03-20: Merged Block/Accept Criteria into Verification Workflow, compressed greenfield edge-case steps, removed standalone test code review section…
- 2026-03-20: Added `reopen` and `log` docket commands to workflow, compressed Docket CLI Reference and Per-Session Metrics, added rework return step.
- 2026-03-21: Added cross-communication observability (Docket logging for BLOCK/coverage-gap/vote), fixed operating context to acknowledge project memory…
- 2026-03-29: Fixed Docket CLI reference inaccuracies (voter defaults, missing reopen/domain-tag/limit), compressed Pre-Flight Goal-Alignment Gate and…
- 2026-03-29: Added TaskCreate/TaskUpdate/TaskList/TaskGet to frontmatter and verification workflow, compressed cross-communication observability, proactive…
- 2026-03-30: Added rigorous honest quality gatekeeper directive, compressed Mermaid subsection and "When NOT to consult" list, tightened Pre-Flight gate.…
- 2026-04-01: Added `model: opus[1m]` to frontmatter, added context compaction awareness, compressed Inter-Agent Communication, merged status/observability…
- 2026-04-06: Replaced direct `/vote` invocation with team-mode delegation pattern (critical cross-cutting fix — prevents nested team spawning). Added global…
- 2026-04-06: Added TDD status gate awareness to spec-checking workflow, updated Docket CLI reference with new vote flags, compressed Testing Philosophy and…
- 2026-04-16: Consolidation pass — removed duplicated operator-alignment guidance between Pre-Flight gate, Check Specs ambiguity paragraph, and Verification…
- 2026-04-16: Cross-communication pass: replaced 5 prose Inter-Agent Communication subsections with an 11-trigger notification table (6 new triggers). Added…
- 2026-04-19: Embedded operator "No guessing" behavioral gate after Quality stance — verification must be evidence-based (Read/Grep source, Bash run code…
- 2026-05-05: Consolidation pass — trimmed NOT section restating description, compressed operating-context/TDD-gate to peer-brevity, removed duplicated…
- 2026-05-05: Phase 0+2 capability adoption: added `Monitor` to tools with run_in_background + until-loop pattern for long test runs / CI watches / flaky…
- 2026-05-06: Cross-agent comms visibility pass — adopted PM's `"[SDET→@agent] {summary}"` Docket-comment logging so operator can see SendMessage traffic in…
- 2026-05-07: Coherence and consolidation pass — removed duplicated push-tests-down rationale (already in Test Pyramid), trimmed Testability Advocacy…
- 2026-05-07: Phase 2 coherence: aligned standalone-mode AskUserQuestion shape language with peer agents.
- 2026-05-07: Capability adoption pass — documented persistent agent-memory dir for SDET-specific recurring-signal tracking (flaky patterns, fixture quirks…
- 2026-05-08: Coherence & trimming pass — merged operating-context + agent-memory paragraphs into senior-engineer-style single block, removed three duplicate…
- 2026-05-08: Phase 2 coherence: surfaced the sub-agent invocation ban in the CRITICAL banner; aligned testability-trigger vocabulary with ux-designer.
- 2026-05-08: Phase 3 operating discipline: codified two behavioral rules surfaced by operator — no retry loops on failing test commands (ask for help…
- 2026-05-09: Phase 1 trim + bidirectional coherence — compressed Quality stance, No-guessing, Stop-and-ask, Pre-Flight, Inter-Agent, /vote, Shutdown, and…
- 2026-05-13: Added LIGHT vs FULL verification depth thresholds — trivial fixes get one-line APPROVE; non-trivial work still uses the structured template.…
- 2026-05-13: Phase 2 coherence: added @security-engineer to "What You Are NOT" with security-advisor persistent-name alias; annotated `docket issue close`…
- 2026-05-16: Encoded 8 operator communication-discipline rules (closed-loop reply, ack, saturation, blocker, verify, shutdown, claim-first, 10-min progress)…
- 2026-05-16: Phase 2 coherence: align Communication Discipline rule numbering with brief's canonical map (rule 7 = claim-first, rule 8 = 10-min progress).
- 2026-05-17: Two Phase 2 handoffs from the 2026-05-17 evolve-skills cycle: (1) Vote delegation payload synced to canonical `skills/vote/` shape; (2)…
- 2026-05-17: Addresses highest-severity audit signal (3 operator history corrections + 17 TeammateIdle hits) by closing the dispatch-to-first-SendMessage…
- 2026-05-17: Phase 2 coherence: Added Read-before-Edit/Write reflex as Rule 9, matching Phase 1 propagation across Edit/Write-capable agents.
- 2026-05-19: Closes audit gaps: verification-evidence specificity (real-vs-mocked at trust boundaries), `index.lock` recovery (fleet-wide #1 error, sdet=8)…
- 2026-05-19: Phase 2 coherence: Universal-mirror visibility contract alignment (replaces narrower "BLOCK / coverage-gap / vote / approach-changing" trigger).…
- 2026-05-24: Phase 2 coherence — shutdown_response routing rule: Closed the 6 historical `is_error:true` "shutdown_response must be sent to team-lead"…
- 2026-05-25: Three behavioral gaps from 10+ sandbox-blocked errors and 2 operator over-reach interruptions in historical audit: sandbox off-limits documentation, jq
- 2026-05-25: Three coherence fixes from Phase 2 audit: (1) added concrete WRONG/RIGHT shutdown-routing example to Comm Discipline rule 6 for fleet parity with
- 2026-05-26: Phase 1 — shutdown coordination: proactive emit + drain; Lifecycle/Rule 6/Verifier Composition/Verification Output/Shutdown Handling. Net +4.
- 2026-05-26: Phase 2 — stripped 4 dangling docs/tdd/* citations; redirected to team-lead.md anchors.
- 2026-05-26: Verifier Composition realigned to default-single (team-lead Rule 8); canonical spawn names; claim-via-move drift fix (verification = ack-only). Net +2.
- 2026-05-26: Phase 2 coherence — step 5 close-flow ownership fixed (SE closes, sdet branches by verdict); drain-doctrine TaskStop parity.
- 2026-05-30: Test Failure Diagnosis dedup + §CRITICAL header claim-drift gap fix. Net ~0.
- 2026-05-30: Consolidation — step 5 edge-case folded into verify-ac; §Verification Output closeout collapsed. Net -3.
- 2026-05-30: Phase 2 coherence — dangling `§6 continuity preamble` pointer removed (fleet sweep). Within-line.
- 2026-06-05: Two Consolidation & Trimming dedups — step 2 claim convention, Shutdown Proactive idle-role enumeration. Net 0.
- 2026-06-09: Consolidation — §Verification Output closeout recap collapsed to back-reference chain. Net 0.
- 2026-06-09: Encoded historical-audit focus areas: verbatim commands, marker-derived sweep bounds, Monitor sandbox/no-background provisioning; net -8.
- 2026-06-09: Added cwd-outside-repo docket no-op guard and `updated_at` reconcile discipline to comm rule 7; count unchanged.
- 2026-06-09: Compacted 38 entries (2026-03-19..2026-05-24) into Compacted history per ADR 0001.
- 2026-06-09: Fable-5 slice — added autonomy calibration + silence-default narration; trimmed redundant re-read clause. Net +2 (341 lines).
- 2026-06-09: Shutdown flip — comm rule 6, Lifecycle, Verifier Composition, §Shutdown Handling → Proactive→Await-lead. Count unchanged (340).
- 2026-06-10: Culled redundant "Idle after verdict" paragraph (4-way restatement); folded TaskStop verb into Drain-before-shutdown. Net -2 (339 lines).
- 2026-06-10: Compacted 2 entries (2026-05-25..2026-05-25) into Compacted history per ADR 0001.
- 2026-06-17: Added sandbox-interaction patterns, never-trust-0-failures set-diff procedure, shared-worktree baseline hazard. Trial: sandbox-patterns / set-diff / worktree-baseline → adopted. Drift: neutral reword of the @ux-designer testability-trigger bullet → adopted.
- 2026-06-19: Trimmed verify-ac-skill-owned duplication from §Verification Workflow (verbatim-command, layer-signals, edge-case battery, verdict ladder). Net -1 (369→368). Drift: skipped (seed-target was a CRITICAL section — unsafe).
- 2026-06-20: Folded two uncovered sandbox/verification lessons into existing blocks + deduped the kubectl/credential restatement. Net 0 (472→472). Drift: disabled (drift=0).
- 2026-06-21: Compacted 9 entries (2026-05-26..2026-06-09) into Compacted history per ADR 0001.
- 2026-06-30: Reconciled DEFAULT lone `verifier` to run as a report-only subagent (mirrors team-lead step 15); added abuse-case consult trigger; chained test-infra claim. Net +1 (476→477).
- 2026-06-30: Folded GitOps selfHeal signal-timing pitfall + EISDIR path-handling guard; deduped TFD FIX-verdict restatement. Net 0 (476→476).
- 2026-06-30: Phase 3 disambiguation polish — sharpened report-only default verifier wording to not blur report-only-vs-teammate distinction.
- 2026-07-01: Phase 1 SDET edits — report-only verifier lifecycle, risk-gated set-diff, TDD override handling, `fix_owner` output. Trial: report-only verifier lifecycle -> applied.
- 2026-07-01: Made lone `verifier` report-only semantics read-only across Docket and tests (no comments/reopens/writes; TDD override scoped to team-lead/interactive spawns).
- 2026-07-01: Phase 3 Disambiguation follow-up — clarified SDET report-only defect routing and normalized SP-1 shutdown report schema.
- 2026-07-01: Compacted 2 entries (2026-06-09..2026-06-09) into Compacted history per ADR 0001.
- 2026-07-10: Phase 2 coherence follow-up — fixed vote-delegation `message: {object}` bug (rewrote to plain-text string); only fleet-wide instance of a JSON object literally assigned to SendMessage's `message:` param (bug-audit FIX-9).
- 2026-07-10: Documented `docket vote cast --findings-json` array-of-STRINGS shape (not objects) to prevent a recurring BAD-PARAM class. Net +119 bytes.
- 2026-07-10: Compacted 3 entries (2026-06-09..2026-06-09) into Compacted history per the retention-compaction policy.
- 2026-07-11: evolve-agents cycle (SDLC role-comparison mandate): verification-only pass, no content changes; charter confirmed matching industry SDET, model-tier retained (54.8%/45.2%).
- 2026-07-11: Phase 2 coherence fix: corrected the SP-2 teammate/report-only-subagent discriminator (family-wide lockstep with 5 sibling agents + the shutdown-protocol master). Net +32 bytes.
- 2026-07-11: Compacted 3 entries (2026-06-10..2026-06-17) into Compacted history per the retention-compaction policy.
- 2026-07-12: Phase 3 disambiguation: named the `sdet-{ID}` test-infrastructure spawn class as distinct from the three verifier names (closing a wrongful-refusal risk); closed a vote Fallback path that instructed a bare `docket vote create`.
- 2026-07-12: Phase 2 coherence: compacted the SHUTDOWN-PROTOCOL-LOCAL block to the master-pointer form (parity with the fleet-wide compaction).
- 2026-07-12: evolve-agents self-review: wired `flaky_confirm.sh` and `vote_delegate.sh` into workflow, retired single-investigation depth, added teammate-frontmatter-inert note. Net −1067 bytes.
- 2026-07-13: Compacted 5 entries (2026-06-19..2026-06-30) into Compacted history per the retention-compaction policy.
- 2026-07-15: READ-BEFORE-EDIT pointer's file-class scoping rephrased file-class-agnostic (was excludable via shared/appended-files reading); R7 gains the adjacency-gate outranking exception.
- 2026-07-15: Read-before-Edit rule -> pointer to senior-engineer.md's master (B3); stale-dispatch-check pointer added (R3); vote wire form deduped to Skill(vote) citation (I4).
- 2026-07-15: Fixed the unexecutable regression-baseline "capture before" instruction by pointing it at `regression_diff.sh`'s self-serve `baseline` mode; missing-baseline case now escalates to team-lead as a coverage gap.
