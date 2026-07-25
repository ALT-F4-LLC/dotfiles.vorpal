# Changelog: design-review

## 2026-07-24

### Summary
Compacted 5 entries (2026-06-10..2026-06-10) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 5 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-24

### Summary
Phase 3 disambiguation: the COUPLING comment's "keep its shape in sync" instruction for the Doubling Rule invited flattening verify-ac's intentionally divergent (delegation-only) Doubling Rule to this family's three-bullet delta shape. Added an explicit carve-out.

### Changes
- CLARIFY[COSMETIC]: COUPLING comment's Doubling Rule sync clause gains a parenthetical naming verify-ac's Doubling Rule as intentionally delegation-only (no Seats/dedupe/degraded bullets) — never normalize it to the three-bullet shape (lockstep, 4 files).

### Dimensions Evaluated
Coherence (disambiguation pass, Two-arm Boundary test — passed Arm 1 coherence, failed Arm 2 clarity).

### Rename
No rename.

## 2026-07-24

### Summary
Staging guidance strengthened with the explicit never-hand-roll-mktemp clause; COUPLING comment gains the family silent-completion sync guard. Own trailing-line and path fixes landed in Phase 1; this pass completes family parity around them.

### Changes
- AMPLIFY[SUBSTANTIVE]: "never hand-roll mktemp or carry $$ across separate Bash calls" added to the staging sentence (family anti-hand-roll parity).
- COHERENCE: COUPLING comment extension (lockstep, 4 files).

### Dimensions Evaluated
Coherence. Phase 2 pass.

### Rename
No rename.

## 2026-07-24

### Summary
Shrank the Doubling Rule to the family pointer+bullet template, closed two live staging defects (undefined $DRAFT_FILE leaking scratch to repo root; unresolvable bare script name yielding an unhandled exit 127), added a literal-vs-semantic rule for backticked spec tokens after a production false Blocker, and put the validator-required trailing confirmation line inside the Output Contract template. Findings: 5 → 4 sub / 1 cos / 1 rej / 2 def / 1 enc

### Changes
- REFACTOR[SUBSTANTIVE]: Doubling Rule shrunk 1,392B → 613B to the design-qa/verify-ac bullet template; every dropped mechanic verified present in team-lead.md Rule 8/Rule 7/step 14 before removal.
- BUGFIX[SUBSTANTIVE]: staging guidance — prefer stdin; if staging, create under $TMPDIR in the same Bash call. Script invocation promoted to the full ~/.claude/scripts/ path (bare name unresolvable, verified exit 127, outside the documented 0/1/2 contract).
- AMPLIFY[SUBSTANTIVE]: Common Discipline gains a literal-vs-semantic rule for backtick-quoted artifact tokens; ambiguous cases route to Question, not Blocker.
- BUGFIX[SUBSTANTIVE]: Output Contract template now carries the trailing confirmation line — report_lint.py requires it in the linted body, while the section's own "no trailing notes" rule forbade appending it.
- TRIM[COSMETIC]: removed the third inline copy of the recommendation ladder.

### Dimensions Evaluated
Selection, Over-Engineering, Bug/Correctness, Actionability, Redundancy, Coherence, Byte budget. Spec Alignment vacuous.

### Rename
No rename.

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
- 2026-06-10: Removed re-invocation instruction after Validation Before Emit ABORT — it contradicted the ABORT contract (leaf aborts cannot be resumed in-place). Net -1.
- 2026-06-10: Phase 2 self-correct: restored the post-ABORT re-invocation line removed earlier this cycle. The Phase 1 removal claimed design-qa parity but design-qa:194 c...
- 2026-06-10: Inlined the empty-artifact abort guard at Pre-flight step 6 (matching design-qa's inline Empty-implementation guard structure) and removed the now-redundant...
- 2026-06-10: Phase 2 coherence: removed dead `{today_date}` Pre-flight variable (grep-confirmed 1 definition, 0 template uses) and renumbered Pre-flight steps 4-6 → 3-5....
- 2026-06-10: Compacted 10 entries (2026-05-16..2026-05-29) into Compacted history per ADR 0001.
