# Changelog: design-review

## 2026-07-20 (Phase 4 history compaction)

### Summary
Compacted 2 entries (2026-06-09..2026-06-09) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 2 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-20

### Summary
Fixed a BSD/macOS mktemp staging-file collision (L5). The `mktemp "$TMPDIR/review-XXXXXX.md"` template only randomizes trailing X's on BSD, so it yields a literal un-randomized name that collides `File exists` on the second call — defeating the section's own race-avoidance purpose. Reproduced on Darwin 25.5.0. Findings: 1 → 0 sub-cosmetic / 1 bug / 0 rej / 0 def / 0 enc

### Changes
- BUGFIX[SUBSTANTIVE]: dropped `.md` from the mktemp staging template (`review-XXXXXX`); added an inline guard note on BSD trailing-X behavior. Verified fix randomizes; report_lint.py enforces no file extension. Identical pattern fixed in sibling report-emission skills this cycle.

### Dimensions Evaluated
Bug/Correctness, Coherence, Redundancy, Byte budget.

### Rename
No rename.

## 2026-07-15 (Phase 4 history compaction)

### Summary
Compacted 2 entries (2026-06-09..2026-06-09) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 2 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-15

### Summary
Amplified Accessibility dimension #3 with dataviz-output-contrast and data-table-semantics checks (DKT-336 H5). Applied as AMPLIFY not a new dimension — Accessibility is already dimension #3 and the six-dimension count is validator-enforced. Findings: 1 → 1 sub / 0 cos / 0 rej / 0 def / 0 enc

### Changes
- AMPLIFY[SUBSTANTIVE]: added two checklist bullets to Accessibility dimension #3 — dataviz-output contrast/color-encoding and screen-reader table semantics (H5); color-only + keyboard-only checks already present.

### Dimensions Evaluated
Actionability, Completeness, Coherence.

### Rename
No rename.

## 2026-07-14 (Phase 4 history compaction)

### Summary
Compacted 2 entries (2026-06-05..2026-06-08) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 2 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-14

### Summary
Added `effort: xhigh` for report-emission family lockstep with code-review-verdict/verify-ac/tdd; propagated mktemp race-safe validation staging (doubled `design-review-{N}` panels shared `$TMPDIR`, fixed `review.md` name raced).

### Changes
- AMPLIFY: added `effort: xhigh` (was absent) — six-UX-dimension review + user-journey simulation; comparable demand to xhigh siblings.
- AMPLIFY: `mktemp`-unique staging file — doubled `design-review-{N}` panels shared `$TMPDIR`, fixed `review.md` name raced.

### Dimensions Evaluated
Coherence (frontmatter parity, cross-family staging symmetry).

### Rename
No rename.

## 2026-07-13 (Phase 4 history compaction)

### Summary
Compacted 2 entries (2026-05-29..2026-05-30) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 2 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-13 (Phase 3 disambiguation pass, evolve-skills cycle)

### Summary
Phase 3 disambiguation (evolve-skills cycle): doubled-panel dispatch verb no longer implies re-spawning the persistent ux-advisor (lockstep with design-qa).

### Changes
- AMPLIFY[SUBSTANTIVE]: Doubling Rule — "spawns `ux-advisor` + one ephemeral" → "dispatches … persistent `ux-advisor` via SendMessage (CLOSED-set name, never re-spawned) + one ephemeral via `Agent()`" — same two-reading failure as design-qa; applied in the same turn per the family's Doubling-Rule shape-sync note

### Dimensions Evaluated
Disambiguation (multi-reading).

### Rename
No rename.

## 2026-07-12

### Summary
Coherence: extended Validation check #4 to enforce spec-section/workflow citation on Blockers, not just Concerns — matches Common Discipline (L145) and restores parity with design-qa's sibling check. The 10-arm Validation-Before-Emit checklist was assessed for Over-Engineering and found NOT redundant — each arm maps to a distinct format-authority guarantee; no trim applied. Findings: 2 → 1 sub / 0 cos / 0 rej / 1 def / 0 enc

### Changes
- AMPLIFY[SUBSTANTIVE]: Validation check #4 "Every Concern names..." → "Every Blocker and Concern names..." — closed an enforcement gap where the highest-stakes findings were exempt from the grounding rule Common Discipline already mandates

### Dimensions Evaluated
Over-Engineering PRIMARY (10-arm checklist assessed — NO trim, size is format-driven, not bloat); Coherence (design-qa parity + own-discipline alignment). Deferred: `report_lint.py` shared validator (4 skills: code-review-verdict, verify-ac, design-qa, design-review) — mechanization/DRY win, not a correctness fix, no urgency.

### Rename
No rename.

## 2026-07-10

### Summary
Full 8-dimension audit: NO-OP. "Possibly bypassed" historical finding investigated and cleared — ux-designer.md routes to Skill(design-review) correctly; zero invocations = demand-side, not a routing gap.

### Changes
- None (NO-OP verdict).

### Dimensions Evaluated
All 8; Over-Engineering primary (no trim after 16+ cycles); Coherence (routing verified). Cross-cutting family self-check CANONICAL-tag proposal flagged and deferred.

### Rename
No rename.

## 2026-06-30

### Summary
Clarified operator-triggered design review ownership.

### Changes
- DISAMBIG: reworded the When to Use operator trigger so it routes through `@ux-designer` and names pre-implementation design feedback.

### Dimensions Evaluated
Phase 3 Disambiguation: overlapping-ownership.

### Rename
No rename.

## 2026-06-30

### Summary
Tightened self-check to prevent silent completion in report-emission family, net 0.

### Changes
- AMPLIFY: self-check now requires the structured verdict body to be sent before idling or marking complete.

### Dimensions Evaluated
All 8.

### Rename
No rename.

## 2026-06-20

### Summary
Disambiguation + efficiency; net -1 (243→242). Severity ladder + Doubling Rule deferred to Phase 2.

### Changes
- AMPLIFY: added an "Invoke BEFORE implementation / use Skill(design-qa) for post-impl verification" qualifier to the description — cited Phase-0 design-review-vs-design-qa conflation signal (design-qa already reciprocates the cross-link).
- CULL: collapsed Pre-flight step 4's Grep + Glob into one `grep -rl` — `docs/tdd/adr/` is under `docs/tdd/`, so the ADR Glob was redundant (one fewer tool call, zero info loss).

### Dimensions Evaluated
Skill Design, Actionability, Completeness, Over-Engineering, Orchestration, Coherence, Spec Alignment, Rename.

### Rename
No rename.

## 2026-06-19

### Summary
Phase-2 coherence: aligned the silent-completion self-check to the family anchor and added a classifier-block fallback to the Output Contract.

### Changes
- AMPLIFY (silent-completion self-check): replaced "closed-loop failure" with the family-anchored "silent-completion — the dominant defect class across this skill family (code-review-verdict, verify-ac, design-review, design-qa)". Net 0.
- AMPLIFY (Output Contract): if the harness blocks invocation (Stage-2 auto-mode classifier), render the review per THIS format authority — required sections + Approve / Approve with follow-up / Block / Redesign / Incremental Improvement ladder. Family extension. Net +1.
- Drift (rate 7): all 7 SKIP — descriptive / format-authority tokens.

### Dimensions Evaluated
Coherence, Actionability, Completeness, Over-Engineering, Rename.

### Rename
No rename.

## 2026-06-10

### Summary
Compacted 10 entries (2026-05-16..2026-05-29) into Compacted history per ADR 0001.

### Changes
- 10 entries (2026-05-16, 2026-05-16, 2026-05-17, 2026-05-18, 2026-05-19, 2026-05-20, 2026-05-25, 2026-05-28, 2026-05-28, 2026-05-29) replaced with ledger lines in ## Compacted history section.

### Dimensions Evaluated
History Compaction (ADR 0001).

### Rename
No rename.

## 2026-06-10

### Summary
Phase 2 coherence: removed dead `{today_date}` Pre-flight variable (grep-confirmed 1 definition, 0 template uses) and renumbered Pre-flight steps 4-6 → 3-5. Measured net -2 (245 → 243).

### Changes
- CULL: Pre-flight step 3 "Resolve context" deleted (dead variable, lockstep with verify-ac/design-qa) — cited signal: coherence-reviewer grep verification.

### Dimensions Evaluated
Coherence (lockstep removal + renumber; no §-refs existed; no stale "Failure Modes" references after the Phase 1 inline — grep 0 hits), Consistency.

### Rename
No rename.

## 2026-06-10

### Summary
Inlined the empty-artifact abort guard at Pre-flight step 6 (matching design-qa's inline Empty-implementation guard structure) and removed the now-redundant single-row `## Failure Modes` section. Measured net -4 (249 → 245 per post-apply wc -l; reviewer estimate was -6).

### Changes
- CULL: Pre-flight step 6 "see Failure Modes" pointer → inline ABORT code-fence; `## Failure Modes` section removed — cited signal: single-row table duplicating an inline-guard pattern the design-qa sibling already inlines (structural parity + Over-Engineering trim; orchestrator grep-verified design-qa L95 inline guard and absence of a Failure Modes section).

### Dimensions Evaluated
All 8; Over-Engineering (HIGHEST); Coherence (design-qa structural parity restored); vote-escalation mode-split and re-invocation parity verified sound; disable-model-invocation evaluated and rejected (ux-designer `skills:` preloads this skill).

### Rename
No rename.

## 2026-06-10

### Summary
Phase 2 self-correct: restored the post-ABORT re-invocation line removed earlier this cycle. The Phase 1 removal claimed design-qa parity but design-qa:194 carries the identical line — the edit BROKE parity rather than restoring it. Net +2 (back to 249).

### Changes
- Re-inserted "The calling agent corrects in its own context and re-invokes `Skill(design-review, ...)`" after the validation ABORT fence, matching design-qa's structure exactly (grep-verified both at L221/L194 post-fix).

### Dimensions Evaluated
Coherence (sibling parity — empirical grep settled the conflicting Phase 1 claims).

### Rename
No rename.

## 2026-06-10

### Summary
Removed re-invocation instruction after Validation Before Emit ABORT — it contradicted the ABORT contract (leaf aborts cannot be resumed in-place). Net -1.

### Changes
- Validation Before Emit: removed "calling agent corrects and re-invokes" line following the ABORT code-fence — on abort the skill ends; recovery is a fresh invocation. Restores parity with design-qa, which carries no such line at its abort gate.

### Dimensions Evaluated
All 8. Skill Design Quality / Actionability (HIGHEST — defect removal). Over-Engineering (net -1). Coherence (design-qa sibling parity restored).

### Rename
No rename.

## Compacted history

Entries below were compacted per ADR 0001; full text in git history (see the compaction entry's date).

- 2026-05-16: First changelog entry — Output Contract maturity field, Praise→What's Strong routing, AskUserQuestion contract, Validation rule #2 loosened, Failure Modes 7→3 rows.
- 2026-06-05: Phase 2 coherence — moved COUPLING marker above "When NOT to Use"; corrected "below" wording. All 4 family markers byte-identical.
- 2026-06-08: Coherence — corrected Doubling Rule dedupe key from (file, symbol) to (spec section, surface), matching Validation check #4 + design-qa.
- 2026-05-16: Coherence — banner footer + Docket comments; Save & Return preamble → "Output Contract owns the emission rules" (family parity).
- 2026-05-17: Trim — Role Detection Note removed, redundant Failure Modes row dropped, Validation rule #2 tightened, Failure Modes preamble compressed. Net -22.
- 2026-05-18: Trim + Epistemic — "Stream long inspections" removed; Honest Critique → evidence; Pre-flight step 6 collapsed to Failure Modes ref. Net -5.
- 2026-05-19: Coherence — Validation check #10 added (banned-phrases gate matching code-review check #9). Net +1.
- 2026-05-20: Coherence + OE — Doubling Rule promoted H3→H2 matching design-qa density; Failure Modes row dropped. Net -9.
- 2026-05-25: Orchestration + OE — silent-completion self-check added to Save & Return; AskUserQuestion contract duplication trimmed. Net +3.
- 2026-05-28: Handoff — verdict-routing unified across self-check/Save & Return/Next Steps; hub-and-spoke violation fixed; non-existent @ux-designer-author removed. Net 0.
- 2026-05-28: Coherence — dead `docs/tdd/reviewer-doubling-lifecycle.md` refs → `agents/team-lead.md` Rule 8 + step 14. Net 0.
- 2026-05-29: OE — Validation check #2: 3 sub-bullets → 1 enforceable line. Net -3.
- 2026-05-29: Harmonized silent-completion self-check framing with report-emission family — "MUST self-check" (peer/team-lead), resolved Phase-1 SendMessage objection.
- 2026-05-30: Aligned Doubling Rule with team-lead.md Rule 8 (default-single, opt-up-doubled); ephemeral name design-review-2 → design-review-{N}.
- 2026-06-09: Coherence — mode-split Save & Return vote escalation (standalone Skill(vote); team mode → delegation_request); trimmed duplicate routing text. Net 0.
- 2026-06-09: Phase 2 — code-review→code-review-verdict reference updates (2 refs, lockstep only); Monitor retained in allowed-tools (family parity).
- 2026-06-09: Full-cycle audit NO-OP — Skill(vote) signal resolved (parity block, nav pointer, mode-split) all verified via fresh grep.
- 2026-06-09: Mythos/Fable-5 no changes — reasoning-echo/$-escape/recall-filter audits clean; validation ladder + 6 dimensions preserved.
