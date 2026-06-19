# Changelog: design-review

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

## 2026-06-09

### Summary
Full-cycle audit: NO-OP verdict. Skill(vote signal fully resolved: L75 (parity reconciliation block), L84 (navigational pointer), L236 (mode-split — standalone direct, team NEVER) all verified correct via fresh grep.

### Changes
- None (NO-OP verdict).

### Dimensions Evaluated
All 8; Over-Engineering primary (249 lines, no trim opportunities after prior cycles); Coherence (design-review/design-qa lifecycle pair clean).

### Rename
No rename.

## 2026-06-09

### Summary
Mythos/Fable-5 cycle audit: NO changes. Reasoning-echo clean (accessibility rendered-effect line is review-rubric content); $-escape clean; recall-filter grep zero hits (orchestrator-verified); validation ladder + 6 dimensions preserved.

### Changes
- None (NO-OP verdict).

### Dimensions Evaluated
All 8; Over-Engineering primary; reasoning-echo + $-escape + recall-filter audits clean.

### Rename
No rename.

## 2026-06-09

### Summary
Phase 2: code-review→code-review-verdict reference updates (lockstep only).

### Changes
- 2 refs updated for the sibling rename, incl. the byte-identical COUPLING marker.
- Monitor retained in allowed-tools despite no body usage — family parity decision (pre-approval, not capability).

### Dimensions Evaluated
Coherence (family lockstep).

### Rename
No rename (sibling code-review renamed → code-review-verdict; refs updated).

## 2026-06-09

### Summary
Coherence: fixed Save & Return vote escalation to mode-split (standalone `Skill(vote)`; team mode delegation_request to team-lead) — prior wording instructed a team-mode Skill(vote) call that agents/ux-designer.md's CRITICAL banner forbids. Trimmed duplicated routing parenthetical + rhetorical tail from the self-check. Net 0.

### Changes
- Save & Return vote bullet: `Skill(vote, ...)` → mode-split escalation per agents/ux-designer.md Design Spec Approval.
- Self-check: dropped routing clause duplicating bullet 1 and "regardless of how complete..." filler.
- Cross-cutting: same Skill(vote) hazard in code-review:390, verify-ac:261, and family When-NOT-to-Use bullets routed to Phase 2 for lockstep harmonization.

### Dimensions Evaluated
All 8. Coherence (vote-routing contradiction), Over-Engineering (HIGHEST — self-check trim), Skill Design (no unescaped $digit; under compaction cap; description under budget). Spec Alignment N/A (docs/spec/ absent).

### Rename
No rename.

## 2026-06-08

### Summary
Coherence: corrected the Doubling Rule reconciliation dedupe key from `(file, symbol)` to `(spec section, surface)` — a UX peer review grounds findings on spec sections/workflows (pre-implementation, often no code), matching Validation check #4 and the design-qa sibling. design-review-local divergence; siblings (code-review/verify-ac key on file/symbol) unaffected. Net 0.

### Changes
- Doubling Rule: dedupe key `(file, symbol)` → `(spec section, surface)`.

### Dimensions Evaluated
Coherence (dedupe-key accuracy vs this skill's own grounding unit + design-qa parity), Over-Engineering (HIGHEST — nothing to trim at 250 lines after 16 cycles), all 8 reviewed; rest sound. Scope boundary vs design-qa verified crisp.

### Rename
No rename.

## 2026-06-05

### Summary
Phase 2 coherence: moved the COUPLING marker above "When NOT to Use" and replaced "doubling-rule note below" with directionless wording ("The Doubling Rule section...") — the Doubling Rule sits above the marker post-move, so "below" was inaccurate. All 4 family markers now byte-identical.

### Changes
- COUPLING marker relocated under "When NOT to Use"; "below" wording corrected; family parity restored.

### Dimensions Evaluated
Coherence (report-emission family COUPLING placement + text parity).

### Rename
No rename.

## 2026-05-30

### Summary
Aligned the Doubling Rule with team-lead.md Rule 8: design review defaults to a single ux-advisor (opt up to doubled per Rule 8 triggers) rather than ≥2-by-default. Canonical ephemeral name design-review-{N}. Net 0.

### Changes
- Doubling Rule: default-doubled framing → default-single/opt-up-doubled per team-lead.md Rule 8; ephemeral `design-review-2` → `design-review-{N}`. Applied in lockstep with design-qa and code-review (shared inversion).

### Dimensions Evaluated
Coherence (HIGHEST — Rule 8 default + canonical naming), Over-Engineering (no trim; net 0), Skill Design, Actionability, Completeness, Orchestration, Spec Alignment, Rename.

### Rename
No rename.

## 2026-05-29

### Summary
Harmonized the silent-completion self-check framing with the report-emission skill family (Phase 2 coherence).

### Changes
- Self-check reframed to "the calling agent MUST self-check," dropping the self-referential "to the calling agent" destination (now peer/team-lead per trigger). Matches code-review/verify; resolves the deferred Phase-1 "leaf skill can't SendMessage" objection without deleting the load-bearing reminder. [Phase 2 coherence item 3]

### Dimensions Evaluated
Cross-skill coherence; instruction accuracy.

### Rename
No rename.

## Compacted history

Entries below were compacted per ADR 0001; full text in git history (see the compaction entry's date).

- 2026-05-16: First changelog entry — Output Contract maturity field, Praise→What's Strong routing, AskUserQuestion contract, Validation rule #2 loosened, Failure Modes 7→3 rows.
- 2026-05-16: Coherence — banner footer + Docket comments; Save & Return preamble → "Output Contract owns the emission rules" (family parity).
- 2026-05-17: Trim — Role Detection Note removed, redundant Failure Modes row dropped, Validation rule #2 tightened, Failure Modes preamble compressed. Net -22.
- 2026-05-18: Trim + Epistemic — "Stream long inspections" removed; Honest Critique → evidence; Pre-flight step 6 collapsed to Failure Modes ref. Net -5.
- 2026-05-19: Coherence — Validation check #10 added (banned-phrases gate matching code-review check #9). Net +1.
- 2026-05-20: Coherence + OE — Doubling Rule promoted H3→H2 matching design-qa density; Failure Modes row dropped. Net -9.
- 2026-05-25: Orchestration + OE — silent-completion self-check added to Save & Return; AskUserQuestion contract duplication trimmed. Net +3.
- 2026-05-28: Handoff — verdict-routing unified across self-check/Save & Return/Next Steps; hub-and-spoke violation fixed; non-existent @ux-designer-author removed. Net 0.
- 2026-05-28: Coherence — dead `docs/tdd/reviewer-doubling-lifecycle.md` refs → `agents/team-lead.md` Rule 8 + step 14. Net 0.
- 2026-05-29: OE — Validation check #2: 3 sub-bullets → 1 enforceable line. Net -3.
