# Changelog: adr

## 2026-07-27

### Summary
Phase 3 disambiguation gave the author list an explicit default/fallback precedence, matching the framing the sibling tdd skill already carries.

### Changes
- DISAMBIG (overlapping-ownership): author precedence stated explicitly — `@distinguished-engineer` by default on Medium+ cycles, `@staff-engineer` as gold-unavailable fallback and on sub-Medium/standalone, `@security-engineer` for security ADRs. The prior unordered list read as staff-first, contradicting the tdd sibling and evolve-coherence D2 #1.

### Dimensions Evaluated
Disambiguation: overlapping-ownership (applied), confusable-name, multi-reading.

### Rename
No rename.

## 2026-07-27

### Summary
S6 applied: the author roster named only @staff-engineer/@distinguished-engineer, silently routing a security ADR to the one agent categorically barred from security work. Roster now names @security-engineer and is single-homed. Net +76 bytes (17,966 → 18,042).
Findings: 5 → 1 sub / 0 cos / 1 rej / 3 def / 0 enc

### Changes
- AMPLIFY[SUBSTANTIVE]: S6 — contract line now names `@security-engineer` as the author of a security ADR, with @distinguished-engineer's security exclusion stated. Verified: security-engineer.md holds `adr` in frontmatter `skills:` (:19), claims security-ADR authorship (:5, :29), invokes `Skill(adr, ...)` (:187); distinguished-engineer.md:102 bars it from security-sensitive work.
- CULL[COSMETIC]: S6 drift-prevention — deleted the duplicate roster parenthetical from the When-to-Use bullet. A third author would have made the duplicate copy stale on the spot; roster now single-homed on the contract line.
- REJECTED: H11 (docs/**/adr discovery step) — re-raise of an already-REJECTED finding; re-verified neither `docs/adr/` nor `docs/tdd/adr/` diverges (ADRs consolidated per 120b273).
- DEFERRED (Docket tracking): H12 (prior-art Grep before the atomic claim), H13 (slug.sh truncation; dedupes with tdd's H9).
- DEFERRED (Phase 2 lockstep): I12 (dead collision-dialog clause in CANONICAL:SAVE_AND_RETURN — premise confirmed falsified; manifest strip-transform mechanism already exists and is live elsewhere), sequenced with tdd's I10 (same shared block).

### Dimensions Evaluated
All 8. Coherence carried the cycle (S6 role-routing gap plus its duplicate-roster drift vector). Over-Engineering: one trim only, doubling as the S6 byte offset.

### Rename
No rename.

## 2026-07-27 (Phase 4 history compaction)

### Summary
Compacted 2 entries (2026-06-17..2026-06-19) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 2 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-27 (Phase 4 history compaction)

### Summary
Compacted 4 entries (2026-06-10..2026-06-30) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 4 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-27

### Summary
Phase 3 disambiguation pass: pinned WHERE and WHEN to read the citation-hijack list that this cycle's new two-branch mismatch disposition keys on. `next_doc_number.sh` emits two different candidate-skip stderr lines, and the branch condition named neither form.

### Changes
- DISAMBIG[SUBSTANTIVE][confusable-name]: Pre-flight 4.1 — branch condition scoped to THIS `--claim` invocation's stderr and to the `already cited (citation-hijack)` line form only, with the script's second skip line (`lost the atomic claim (...), retrying`) called out as NOT a hijack and routed to the **Not listed** branch.

### Dimensions Evaluated
Phase 3 two-arm boundary test. Arm 1 PASSES: script exists, both branch arms internally consistent, Failure Modes row agrees with the prose. Arm 2 FAILS: both stderr lines share a common prefix, so a reader scanning for the mandated number matches both and a lock-contention hit wrongly routes to ABORT. Verified live: `next_doc_number.sh:111` (hijack line) vs `:125` (lock-contention line).

### Rename
No rename.

## 2026-07-27

### Summary
Aligned the contract line to the file's own When-to-Use (@distinguished-engineer authors ADRs on Medium+ cycles), defined the previously-undefined mandated-number mismatch disposition as a verified two-branch rule, and added `effort: xhigh`. Net +1,128 bytes (16,527 → 17,655).

### Changes
- FIX[SUBSTANTIVE]: OP-S2 — lines 19-20 said "typically @staff-engineer" while line 58 correctly added "or @distinguished-engineer on Medium+ cycles". Re-verified against team-lead.md's gold bullet ("ADR authoring inherits the active authoring seat's tier") and distinguished-engineer.md §Mode 1 ("TDD & ADR Authoring"). Companion tdd:19 fix is a separate dispatch.
- FIX[SUBSTANTIVE]: Pre-flight 4.1's "report a mismatch rather than proceeding silently" left the disposition undefined ("report, then proceed" satisfied it literally). Now branches on the script's citation-hijack stderr list: **listed** → ABORT (the self-forward-reference false positive from senior-engineer/pitfalls.md; proceeding would dangle every upstream citation); **not listed** → the mandate is merely stale, proceed and report. Verified next_doc_number.sh emits the discriminating stderr only for the first case.
- CLARIFY[COSMETIC]: step 4.4's abort-after-claim caveat rescoped from "past this point" to "at or after step 4.1" — the stub is created in 4.1, so the new abort fell outside the caveat covering it. New Failure Modes row for the abort branch, restoring the table's every-abort-has-a-row invariant.
- AMPLIFY[SUBSTANTIVE]: added `effort: xhigh` (family parity with tdd/code-review-verdict/verify-ac). team-lead.md names ADR as gold-tier design-artifact authoring, and a teammate ignores agent-frontmatter effort — the skill's own `effort:` is the only depth lever for this dispatch.
- CULL[COSMETIC]: dropped changelog narration of the removed pre/post-Write race-detection Globs; the operative noclobber guarantee is retained.
- DEFERRED-script: I7 (`next_doc_number.sh --release`) and I8 (`doc_stage_validate.sh`) — both verified genuinely absent, both script authoring, routed to Docket.

### Dimensions Evaluated
All 8. Coherence (OP-S2, 4.4 scope, family effort parity); Completeness (mismatch disposition, Failure Modes row); Skill Design Quality (frontmatter); Over-Engineering (-92 historical narration).

### Rename
No rename.

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
Phase 3 disambiguation: the CANONICAL:SAVE_AND_RETURN block's "collision dialog" clause reads as a live branch, but Phase 1 already established collision is structurally impossible for this skill (atomic `--claim` at Pre-flight step 4). Annotated OUTSIDE the CANONICAL block (parity-locked, cannot edit) rather than inside it.

### Changes
- CLARIFY[COSMETIC]: adr-specific note added immediately after CANONICAL:SAVE_AND_RETURN:END stating the collision-dialog clause is unreachable for this skill and kept only for family parity.

### Dimensions Evaluated
Coherence (disambiguation pass, Two-arm Boundary test — passed Arm 1 coherence, failed Arm 2 clarity).

### Rename
No rename.

## 2026-07-24

### Summary
Validation-Before-Save steps 1-2 aligned to the family union shape; placeholder token {tmpdir} → {staging_dir} (family-wide single token).

### Changes
- REFACTOR[COSMETIC]: token rename + wording alignment; no semantic change — adr already carried all three clauses.

### Dimensions Evaluated
Coherence. Phase 2 pass.

### Rename
No rename.

## 2026-07-24

### Summary
Retired the dead COLLISION_DIALOG block and its step-4 apology — verified next_doc_number.sh --claim makes collision structurally impossible, and the block's "if a file already exists" trigger actively mis-fires against the claimed stub Pre-flight guarantees exists. Narrowed a citation-hijack over-claim to path-prefix coverage, fixed a first-run defect handing the prior-art Grep nonexistent dirs, and fixed the full 3-part $TMPDIR/validator-invocation/heading-numbering bug found across the doc-authoring family (X1/X2/X3). H-adr-4 (docs/tdd/adr/ divergence) REJECTED — verified no defect (relocated to docs/adr/ per 120b273). Net +239 bytes (15,851 → 16,090; the earlier COLLISION_DIALOG/citation-hijack/Grep/X1 changes alone netted -135, offset by the X2/X3 follow-up).

### Changes
- CULL[SUBSTANTIVE]: removed Pre-flight step 4 + the CANONICAL:COLLISION_DIALOG block; renumbered step 5→4 across all cross-references. Coupled: adr's COLLISION_DIALOG row dropped from doctrine_check_manifest.tsv (4→3 carriers, still ≥2-checkable) and the orphaned AskUserQuestion dropped from allowed-tools.
- FIX[SUBSTANTIVE]: citation-hijack text narrowed to the docs/adr/{NNNN}- path-prefix form the script actually greps; added a caller-side mismatch check against an upstream-mandated number.
- FIX[SUBSTANTIVE]: prior-art Grep now passes only extant dirs (docs/spec/, docs/ux/ commonly absent — missing path arg exits 2) and aborts on a predecessor already recording the decision; new Failure Modes row.
- FIX[SUBSTANTIVE]: $TMPDIR staging bug (X1, cross-cutting with prd/tdd/ux-spec) — Write/Read take literal paths and don't expand shell variables; staging dir now resolved via Bash first.
- FIX[SUBSTANTIVE]: validator invoked via `python3` (X2) — a lost executable bit now exits 2 (handled) instead of an off-contract 126. Follow-up: review-tdd caught that this and X3 were mis-scoped as already-fixed in the original batch-2 briefs; applied directly here by the orchestrator.
- FIX[SUBSTANTIVE]: Required Sections now states headings carry the title only, never the list number (X3, family parity with prd).
- REJECTED: H-adr-4 — this repo's ADRs are correctly documented at docs/adr/ (relocated out of docs/tdd/adr/ per commit 120b273); the historical-auditor read pre-relocation transcript history.

### Dimensions Evaluated
All 8. Over-Engineering (-1808 bytes dead/orphaned content); Completeness (absent-dir Grep, duplicate decision, TMPDIR staging, validator invocation, heading numbering); Coherence (reference accuracy, family parity, step renumbering).

### Rename
No rename.

## 2026-07-20 (Phase 4 history compaction)

### Summary
Compacted 2 entries (2026-06-08..2026-06-09) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 2 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-20

### Summary
No changes needed. Verified both L1 numbering-race findings are already fully encoded — citation-hijack skip in next_doc_number.sh:106-115 (surfaced at Pre-flight §5.1) covers the phantom-number collision; the pre/post-Write race Globs in §Save & Return cover the parallel-author race. Pass B found no removable slack with a cited fitness signal at this 16+-cycle maturity plateau; the prose-heavy §Save & Return double-Glob section is ledger-locked (L2). allowed-tools Glob/Grep re-confirmed genuinely used (race Globs, prior-art Grep).

### Changes
- None (NO-OP verdict).

### Dimensions Evaluated
All 8; Over-Engineering (HIGHEST — no removable slack outside the L2-locked section); Coherence (family parity with prd/tdd/ux-spec, allowed-tools usage, $-escape clean); Completeness (L1 races already encoded). Deferred: L2 --claim wiring (tracked separately, DKT-19; note: the --claim mode already exists in next_doc_number.sh per DKT-307 — only the SKILL.md wiring remains deferred, deliberately, given interaction risk).

### Rename
No rename.

## 2026-07-13 (Phase 4 history compaction)

### Summary
Compacted 3 entries (2026-06-05..2026-06-05) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 3 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-13 (Phase 2 coherence pass, evolve-skills cycle)

### Summary
Phase 2 coherence: next_doc_number.sh consumer list now cites `src/user/claude-code/agents/...` instead of the dead bare `agents/...` root.

### Changes
- Three agent-file references corrected to the repo-path convention the same sentence already uses for the script itself.

### Dimensions Evaluated
Coherence (reference accuracy).

### Rename
No rename.

## 2026-07-12

### Summary
Added a pre-Write race Glob so a parallel-author collision aborts cleanly before writing (no orphan file, no cryptic harness unread-overwrite error) — closes a documented incident and a coherence defect (the "single-author, no pre-Write renumber needed" claim was contradicted by that same incident). The citation-hijack numbering defect was already fully handled by next_doc_number.sh + Pre-flight step 5.1 — verified, no change. Findings: 2 → 1 sub / 1 cos / 0 rej / 1 def / 1 enc

### Changes
- AMPLIFY[SUBSTANTIVE]: Save & Return sequence now brackets Write with pre- and post-Write race Globs; corrected the inaccurate "single-author" rationale
- AMPLIFY[COSMETIC]: added a Failure Modes table row for the new pre-Write abort, keeping the table a complete lookup

### Dimensions Evaluated
Actionability/Completeness (operational robustness — primary), Coherence (removed the single-author claim contradicted by the documented parallel-author incident). Deferred: doc_validate.py + slug.sh cross-skill extraction (shared with prd/tdd/ux-spec — this file's numbering-script precedent, next_doc_number.sh, is the natural analog). Already-encoded: citation-hijack collision handling (next_doc_number.sh:65-75 + Pre-flight step 5.1).

### Rename
No rename.

## 2026-07-10

### Summary
Fixed the broken COLLISION_DIALOG "Overwrite" branch — it Wrote over an existing file without a prior Read, which the harness rejects. Cross-cutting: applied byte-identically across adr/prd/tdd/ux-spec (surfaced by the ux-spec reviewer, propagated in lockstep).

### Changes
- AMPLIFY: Overwrite branch now Reads `{output_path}` before Write to satisfy the harness read-before-overwrite gate. CANONICAL:COLLISION_DIALOG lockstep across the 4 doc-authoring siblings.

### Dimensions Evaluated
Completeness / Coherence (bug fix). No model/routing/drift change.

### Rename
No rename.

## 2026-07-10

### Summary
No changes needed. Mature, internally consistent (16+ prior cycles); every candidate CULL/AMPLIFY lacked a cited fitness signal (zero correction/error signals, clean model outcomes on both fable-5 and opus). Shared validate_doc.py proposal declined for this leaf skill on Over-Engineering grounds.

### Changes
- None.

### Dimensions Evaluated
All 8; Over-Engineering (HIGHEST) — no CULL with a cited signal found.

### Rename
No rename.

## Compacted history

Entries below were compacted per ADR 0001; full text in git history (see the compaction entry's date).

- 2026-05-06: First entry: five fixes — forward-references, collision-dialog reachability under auto-numbering, deterministic numbering re-run, stale cross-reference.
- 2026-05-06: Removed dead missing-parent-prompt phrase from Save & Return Cancel handler — only create-tdd runs a parent probe.
- 2026-05-06: Phase 1 over-engineering pass: removed three duplicate restatements and meta-commentary; Mermaid Mandate collapsed to cross-reference (305→~272).
- 2026-05-06: Added create-* family COUPLING comment to When NOT to Use for sibling-asymmetry prevention.
- 2026-05-06: Renamed create-adr → adr per operator request; directory, frontmatter name, /adr slash command, and cross-references updated.
- 2026-05-06: Fixed post-write race-detection ordering — reframed as ADR-specific override between canonical Save & Return steps 3 and 4.
- 2026-05-07: Phase 2 coherence: H1 fixed from # Create ADR to # ADR to match frontmatter name after the create- prefix drop.
- 2026-05-07: Repaired SAVE_AND_RETURN canonical-block contamination (restored 3-step form); added optional superseded_by frontmatter field.
- 2026-05-07: Removed redundant sub-agent prohibition row from Failure Modes for symmetry with ux-spec.
- 2026-05-09: Phase 1 over-engineering: dropped the Mermaid Mandate entirely (now optional, judgment-based); trimmed Pre-flight meta-commentary (277→255).
- 2026-05-09: Three actionability + coherence fixes (operator pain points 1, 3): made the same-slug race gap explicit with operator-actionable mitigation, trimmed Pre-flig...
- 2026-05-09: Phase 2 coherence pass: hardened Validation §3 to self-reference Required Sections instead of hardcoding "all 4".
- 2026-05-13: Over-engineering pass: trimmed meta-commentary around numbering and race handling. Same-slug race paragraph compressed to actionable core; ADR-specific overr...
- 2026-05-16: Four small fixes prioritizing over-engineering pass: stripped unactionable "verify topic not in flight" advice from same-slug race guidance, compressed Pre-f...
- 2026-05-17: Three over-engineering / coherence fixes: collapsed duplicated Authoring §3-§6 into a pointer at Required Sections + Validation, dropped stale §5.7 forward-r...
- 2026-05-18: No-change verdict. Skill is mature and family-aligned with prd/tdd/ux-spec/specs after 13 prior changelog entries. Each candidate trim was evaluated against...
- 2026-05-25: Phase 2 coherence: removed redundant TYPE substitution note (lockstep with prd/tdd/ux-spec).
- 2026-05-25: No-change verdict. Skill remains mature and family-aligned with prd/tdd/ux-spec/specs after 14+ prior cycles. Three Phase 0 historical-audit focus areas eval...
- 2026-05-28: No-change verdict. Skill remains mature, lean, and family-aligned (prd/tdd/ux-spec/specs) after 14+ cycles. Operator coordination/handoff priority already se...
- 2026-05-30: No-change verdict (15th+ cycle). Re-read the full SKILL.md and verified family parity (frontmatter byte-identical with tdd/prd/ux-spec), tdd scope-boundary r...
- 2026-06-04: Dropped vestigial `Glob`/`Grep` from `allowed-tools` — the skill discovers prior art via `docket doc list`/`show` (Bash) and `Read`, never the Glob/Grep tool...
- 2026-06-05: Added Authoring Procedure step 4 (verify embedded technical assertions before writing as settled fact); prior step 4 renumbered to 5. Net +6.
- 2026-06-05: Phase 2 coherence — added fenced-code-block carve-out to §3 Section-order validation (count `##` headings outside fences), lockstep with tdd/prd/ux-spec.
- 2026-06-05: Phase 1 no-change verdict; Phase 2 added body-`status:` authority caveat naming Docket `.data.status` as source of truth (adr's proposed→accepted→superseded ladder).
- 2026-06-08: Phase 1 no-change verdict (25+ cycles); re-verified allowed-tools, docs-path taxonomy, family parity — no removable slack.
- 2026-06-09: No-change verdict (2nd consecutive); zero $-hazards, frontmatter/Skill(adr) reciprocity confirmed, absent docs/tdd/adr handled by design.
- 2026-06-09: Mythos/Fable-5 cycle audit: NO changes. Reasoning-echo clean; $-escape clean; no vague verify-reminders; numbering/race-detection steps are deterministic saf...
- 2026-06-09: Full-cycle audit: NO changes. Fourth consecutive no-change verdict. Glob/Grep confirmed genuinely used (numbering, race detection, prior-art) despite stale 2...
- 2026-06-09: Compacted 10 entries (2026-05-06..2026-05-09) into Compacted history per ADR 0001.
- 2026-06-10: No changes needed. Verified live file state against all 8 dimensions; `allowed-tools` (Glob/Grep) confirmed correct and genuinely used in body. Triple-Glob p...
- 2026-06-10: Phase 2 lockstep trim: removed the redundant "additional positional args" Failure-Mode row — CANONICAL:ARGUMENT_HANDLING body (L43) already states the identi...
- 2026-06-10: No changes needed. Full 8-dimension audit at 271 lines; Phase 0 signals verified against live file (Triple-Glob re-evaluated, retained; NO-OP verdict).
- 2026-06-10: Compacted 11 entries (2026-05-09..2026-06-04) into Compacted history per ADR 0001.
- 2026-06-17: Added a multi-agent single-writer baton guard and the COLLISION_DIALOG teammate-context caveat (lockstep). Trial: baton / inert-caveat → adopted.
- 2026-06-19: Collapsed the ADR-specific dual-Glob (pre-Write renumber + post-Write race-detection) to a single post-Write race-detection Glob. Drift (rate 7): all 7 SKIP — ordered-list ordinals + slug pseudo-code (parity).
- 2026-06-30: Missing documentation directories explicitly non-fatal in ADR numbering and prior-art discovery, net -1.
- 2026-06-30: Removed a mis-homed multi-agent coordination block contradicting the leaf BANNER and single-author invariant; verified self-validation path-fragility fix already applied. Net -2 (273→271).
