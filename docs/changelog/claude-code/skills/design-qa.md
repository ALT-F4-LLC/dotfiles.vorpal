# Changelog: design-qa

## 2026-07-24

### Summary
Compacted 5 entries (2026-06-09..2026-06-10) into Compacted history per the retention-compaction policy.

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
Template now carries the trailing confirmation line; silent-completion self-check normalized to the family structure; lint invocation gains full path + the anti-hand-roll staging guard; COUPLING comment extended.

### Changes
- BUGFIX[SUBSTANTIVE]: `Design QA report emitted ({verdict}).` added inside the Output Contract template.
- BUGFIX[SUBSTANTIVE]: ~/.claude/scripts/ prefix on the report_stage_lint.sh fence line; stdin-preferred + never-hand-roll-mktemp guard added.
- REFACTOR[SUBSTANTIVE]: silent-completion self-check normalized to family sentence structure, channel tail preserved.
- COHERENCE: COUPLING comment extension (lockstep, 4 files).

### Dimensions Evaluated
Coherence, Bug/Correctness. Phase 2 pass.

### Rename
No rename.

## 2026-07-24

### Summary
Collapsed the Doubling Rule from a 1380-byte restatement of team-lead.md Rule 8 into a pointer plus the four genuine skill-specific deltas, removing design-qa's share of a 4-way hand-synced drift surface. Verified the cluster mktemp staging bug is already fixed here (fixed 2026-07-20; delegates to report_stage_lint.sh, carries no template). Findings: 4 → 1 sub / 0 cos / 1 rej / 1 def / 1 enc

### Changes
- CULL[SUBSTANTIVE]: Doubling Rule reduced to a team-lead.md Rule 8 / Rule 7 / step 14 pointer plus deltas only — seat names, `(spec section, surface)` dedupe key, verbatim DEGRADED annotation, standalone carve-out. (-771 bytes; I-code-review-verdict-2b)
- No edit for H-design-qa-2 (mktemp): ALREADY-ENCODED — verified no literal template remains.

### Dimensions Evaluated
Over-Engineering, Coherence, Skill Design Quality, Actionability, Completeness, Orchestration, Spec Alignment, Rename.

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
Fixed the BSD/macOS mktemp staging-file collision (L5). The `mktemp "$TMPDIR/report-XXXXXX.md"` template only randomizes trailing X's on BSD, so it yields a literal un-randomized name that collides `File exists` on the second call — defeating the section's own race-avoidance purpose. Reproduced on Darwin 25.5.0. Findings: 1 → 0 sub-cosmetic / 1 bug / 0 rej / 0 def / 0 enc

### Changes
- BUGFIX[SUBSTANTIVE]: staging template `report-XXXXXX.md` → `report-XXXXXX`; empirically verified on Darwin 25.5.0 that the suffixed form collides and the bare form randomizes. (L5)

### Dimensions Evaluated
Bug-fix (executable correctness), Actionability, Completeness, Coherence.

### Rename
No rename.

## 2026-07-15 (Phase 4 history compaction)

### Summary
Compacted 3 entries (2026-06-05..2026-06-09) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 3 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-15

### Summary
Reviewer superseded its own prior same-day H6 recommendation to reach lockstep with design-review's H5: reverted the "Non-color encoding" bullet split and the Blocker-row edit, leaving the pre-existing Color-contrast bullet's "color is not the sole indicator" clause intact and using the identical bullet names design-review uses. Findings: 1 → 1 sub / 0 cos / 0 rej / 0 def / 0 enc

### Changes
- AMPLIFY[SUBSTANTIVE]: step-3 checklist now gains exactly two bullets — **Data-visualization output** and **Data-table semantics** — appended after Semantic/ARIA correctness, reframed post-implementation ("measure actual rendered contrast", "inspect the rendered markup/accessibility tree"). Supersedes the immediately-prior 2026-07-15 entry's 3-bullet + Blocker-row version (H6, DKT-336 AC item 2).

### Dimensions Evaluated
Actionability, Completeness, Coherence.

### Rename
No rename.

## 2026-07-15

### Summary
Applied DKT-336 accessibility finding H6: expanded QA Procedure step-3 accessibility checklist with post-implementation dataviz-output contrast, non-color encoding, and table/tabular-layout semantic checks (keyboard-only flows already covered); folded the two net-new critical failure modes into the Blocker severity ladder. Findings: 1 → 1 sub / 0 cos / 0 rej / 0 def / 0 enc

### Changes
- AMPLIFY[SUBSTANTIVE]: step-3 checklist gains **Data-visualization output**, **Non-color encoding** (promoted + specified from the old color-contrast clause), and **Table / tabular-layout semantics** checks; Blocker severity row now names color-only encoding and table semantics. All statelessly verifiable per the Content Gate. (H6, DKT-336 AC item 2)

### Dimensions Evaluated
Actionability, Completeness, Coherence.

### Rename
No rename.

## 2026-07-14 (Phase 4 history compaction)

### Summary
Compacted 3 entries (2026-05-29..2026-06-04) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 3 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-14

### Summary
Added `effort: xhigh` frontmatter for report-emission family lockstep with code-review-verdict/verify-ac/tdd; propagated mktemp race-safe validation staging (doubled `design-qa-{N}` panels shared `$TMPDIR`, fixed `report.md` name raced).

### Changes
- AMPLIFY: added `effort: xhigh` (was absent) — matches code-review-verdict/verify-ac/tdd; comparable six-dimension + render analytical demand.
- AMPLIFY: `mktemp`-unique staging file in Validation Before Emit — restores lockstep with code-review-verdict's this-cycle race fix.

### Dimensions Evaluated
Coherence (frontmatter parity, cross-family staging symmetry).

### Rename
No rename.

## 2026-07-14

### Summary
Named `render_verify.sh` as the render mechanism in QA Procedure step 2, closing the agent↔skill coherence gap (ux-designer.md already canonicalized the tool; the skill's procedure did not name it). Findings: 3 → 1 sub / 0 cos / 0 rej / 1 def / 1 enc

### Changes
- AMPLIFY[SUBSTANTIVE]: QA Procedure step 2 static-export mandate now names `render_verify.sh <arm>` (html/tui/cli) and cites ux-designer.md's canonical per-surface table rather than duplicating it. Prior (2026-07-10) decline resolved: the script now exists and is multi-surface, answering the "over-fits" objection. (I33)

### Dimensions Evaluated
All 8; Coherence + Actionability primary. Over-Engineering: no untrimmable single-skill redundancy (concurs with 2026-07-10). I34 flagged PARITY-BOUND.

### Rename
No rename.

## 2026-07-13 (Phase 3 disambiguation pass, evolve-skills cycle)

### Summary
Phase 3 disambiguation (evolve-skills cycle): doubled-panel dispatch verb no longer implies re-spawning the persistent ux-advisor.

### Changes
- AMPLIFY[SUBSTANTIVE]: Doubling Rule — "spawns `ux-advisor` + one ephemeral" → "dispatches … persistent `ux-advisor` via SendMessage (CLOSED-set name, never re-spawned) + one ephemeral via `Agent()`" — the old verb invited a duplicate-instance spawn of a CLOSED persistent name

### Dimensions Evaluated
Disambiguation (multi-reading).

### Rename
No rename.

## 2026-07-10

### Summary
Full-cycle audit: NO changes. Well-evidenced render-mechanism Rethink declined — pinned-command half over-fits multi-surface scope; evidence-path half already enforced by Validation check 4. CANONICAL-tagging of Doubling Rule + self-check routed to Phase 2.

### Changes
- None.

### Dimensions Evaluated
All 8; Over-Engineering primary (no untrimmable single-skill redundancy; no operator pain).

### Rename
No rename.

## 2026-06-30

### Summary
Clarified operator/team-lead-triggered design QA ownership.

### Changes
- DISAMBIG: reworded the When to Use operator/team-lead trigger so it routes through `@ux-designer` and names implementation QA against an existing UX spec.

### Dimensions Evaluated
Phase 3 Disambiguation: overlapping-ownership.

### Rename
No rename.

## 2026-06-30

### Summary
Route verify-ac OUT-OF-SCOPE runtime/render criteria on docs/ux surfaces into design-qa, net 0.

### Changes
- AMPLIFY: design-qa invocation now covers verify-ac OUT-OF-SCOPE runtime/render criteria on docs/ux surfaces.

### Dimensions Evaluated
All 8.

### Rename
No rename.

## 2026-06-20

### Summary
One non-parity trim; net -1 (212→211). Render-to-image gate confirmed already present (NO-OP on the Phase-0 signal). Doubling Rule + self-check removals deferred to Phase 2 (family-wide).

### Changes
- CULL: removed the "Long-running surface preparation" Pre-flight note — generic background+Monitor guidance already provided by the harness Bash tooling, not design-qa-specific.

### Dimensions Evaluated
Skill Design, Actionability, Completeness, Over-Engineering, Orchestration, Coherence, Spec Alignment, Rename.

### Rename
No rename.

## 2026-06-19

### Summary
Added a classifier-block fallback to the Output Contract (Phase-2 family lockstep): a blocked Stage-2 invocation renders the QA report per this format authority.

### Changes
- AMPLIFY (Output Contract): if the harness blocks invocation (Stage-2 auto-mode classifier), render the QA report per THIS format authority — required sections + Pass / Pass with Issues / Fail ladder. Family extension of verify-ac's measured fallback. Net +1.
- Drift (rate 7): all 7 SKIP — output section headers / verdict-ladder / ABORT lines.

### Dimensions Evaluated
Actionability, Completeness, Coherence, Over-Engineering, Rename.

### Rename
No rename.

## Compacted history

Entries below were compacted per ADR 0001; full text in git history (see the compaction entry's date).

- 2026-05-16: Phase 2 coherence pass: Common Discipline now includes the AskUserQuestion structural contract; Failure Modes trimmed to honor its "only new abort text" intr...
- 2026-05-16: First changelog entry. Added evidence-citation requirement to QA Procedure common-discipline so every Blocker/Concern names file:line, command output, genera...
- 2026-05-17: Phase 1 trim pass per 2026-05-17 evolve cycle: description rewritten to flag dormancy root cause and clarify post-impl lifecycle position; dropped 2 redundan...
- 2026-05-18: Resolved Validation/Procedure contradiction on "Cross-surface" Spec Section (cross-surface precedent violations are Blocker-class per the Severity ladder and...
- 2026-05-19: Phase 2 coherence — Epistemic Discipline parity with the report-emission family. Added the canonical banned-phrase list to Common Discipline and a Validation...
- 2026-05-20: Tightened description trigger-phrase set per evolve-skills 2026-05-20 cycle: replaced verbose "design quality assurance" with lifecycle-anchored "QA the ship...
- 2026-05-25: Phase 2 coherence: AskUserQuestion structural trim, explicit Praise routing for family parity with design-review, removed duplicate reviewer-doubling-lifecyc...
- 2026-05-25: Phase 2 coherence + orchestration: added silent-completion self-check to Save & Return (cross-cutting with code-review per pitfalls.md "silent-completion of...
- 2026-05-28: Phase 2 coherence: repointed the line-66 dead `docs/tdd/reviewer-doubling-lifecycle.md` references (file does not exist) to `agents/team-lead.md` Rule 8 + st...
- 2026-05-28: Over-engineering trim: collapsed the Failure Modes table — all 3 rows were verbatim duplicates of inline aborts (Pre-flight lines 86 & 92, Argument Handling...
- 2026-05-29: Removed the empty Failure Modes section — pure meta-narration with no scope-specific content (it only stated that abort paths live elsewhere); the abort-emis...
- 2026-05-29: Harmonized silent-completion self-check framing with report-emission family — actor is the calling agent, not self-referential phrasing.
- 2026-05-30: Aligned Doubling Rule with team-lead.md Rule 8 — single ux-advisor by default, opt up on trigger; canonical ephemeral design-qa-{N}.
- 2026-06-04: Added media-rendering edge case to QA step 2 (catch dead media payloads, not just HTTP 200); removed redundant "Stream long commands" bullet.
- 2026-06-05: Phase 2 coherence — moved report-emission COUPLING marker above "When NOT to Use"; synced text with family, all 4 markers byte-identical.
- 2026-06-08: Phase 1 no-change verdict — verified cross-project render mandate already Blocker-enforced (QA Procedure step 2 + Severity ladder); COUPLING marker family-parity confirmed.
- 2026-06-09: Phase 1 no-change verdict (2nd consecutive) — verified render-content-not-liveness + perceptual-legibility-at-scale signals already Blocker-enforced (added 2026-06-04).
- 2026-06-09: Mythos/Fable-5 no changes — render-gate signal (fem-kubernetes) verified fully encoded; reasoning-echo/$-escape/recall-filter audits clean.
- 2026-06-09: Phase 2 — MVP-cutline consumer note added to Pre-flight; code-review→code-review-verdict reference updates (lockstep).
- 2026-06-09: Full-cycle audit: NO changes. Render-gate signal (3rd consecutive re-fire from cross-project memory) definitively closed — mandate fully encoded at L107 (med...
- 2026-06-10: Phase 1 audit: NO changes. All historical-audit signals (render-gate mandate, HTTP-200 vs. rendered-content liveness, Marp/static-export unbundled-asset risk...
- 2026-06-10: Compacted 11 entries (2026-05-16..2026-05-29) into Compacted history per ADR 0001.
- 2026-06-10: No changes applied. Reviewer proposed `disable-model-invocation: true` + When-to-Use trim, but the sibling design-review reviewer rejected the same flag and...
- 2026-06-10: Phase 2 coherence: removed dead `{today_date}` Pre-flight variable (grep-confirmed 1 definition, 0 template uses) and renumbered Pre-flight steps 4-7 → 3-6....
