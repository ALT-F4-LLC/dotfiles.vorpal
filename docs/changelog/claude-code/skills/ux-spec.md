# Changelog: ux-spec

## 2026-07-27 (Phase 4 history compaction)

### Summary
Compacted 2 entries (2026-06-10..2026-06-10) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 2 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-27

### Summary
Phase 2 coherence fix (evolve-skills cycle): added `effort: xhigh` to complete design-artifact-authoring family parity (tdd/adr/code-review-verdict/verify-ac), grounded in team-lead.md's gold-tier authoring bullet which names UX spec alongside TDD and ADR.

### Changes
- AMPLIFY[SUBSTANTIVE]: added `effort: xhigh` frontmatter. This skill is only ever invoked for authoring (review/QA cycles never invoke it), so the hint never lands on a silver-bound path.

### Dimensions Evaluated
Skill Design Quality (frontmatter), Coherence (family parity).

### Rename
No rename.

## 2026-07-24

### Summary
Compacted 4 entries (2026-06-09..2026-06-09) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 4 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-24

### Summary
Validation-Before-Save steps 1-2 normalized to the family union shape keeping {staging_dir}; {output_dir} bound explicitly in Pre-flight. Mermaid first-line-keyword rule re-verified present at HEAD (review-tdd's flag was stale — fixed earlier this cycle).

### Changes
- REFACTOR[SUBSTANTIVE]: steps 1-2 → union/reference shape (gains resolved-path clause + quoted staged path).
- COHERENCE: Pre-flight step 2 binds {output_dir}.

### Dimensions Evaluated
Coherence. Phase 2 pass.

### Rename
No rename.

## 2026-07-24

### Summary
Correctness: closes all three live-verified halves of H-ux-spec-1. Required Sections now states the `##` headings carry the section title only (the validator's exact-match rejected numbered headings, the form the numbered list invites). Validator staging resolves $TMPDIR before Write instead of passing it as a literal, and the validator is invoked through python3 so a lost executable bit can no longer exit 126/127 outside the documented 0/1/2 contract. Findings: 3 → 3 sub / 0 cos / 0 rej / 0 def / 0 enc

### Changes
- AMPLIFY[SUBSTANTIVE]: Required Sections — headings carry the section title ONLY; numbers in the list are not part of the heading. Reproduced: numbered draft exits 1, unnumbered exits 0.
- AMPLIFY[SUBSTANTIVE]: Validation Before Save step 1 — resolve {staging_dir} via echo "${TMPDIR:-/tmp}" first; Write takes a literal path and never expands $TMPDIR.
- AMPLIFY[SUBSTANTIVE]: Validation Before Save step 2 — invoke via python3, never bare. Verified: bare non-executable exits 126, bare missing exits 127 (making the documented exit-2 branch unreachable); under python3 a missing validator exits 2.
- FIX[SUBSTANTIVE]: Mermaid Mandate now states the first-non-blank-line diagram-keyword rule — caught by review-tdd's cross-cutting sweep after ux-spec's own Phase 1 pass missed it; matches the fix already landed in tdd/prd.

### Dimensions Evaluated
All 8. Correctness/Completeness primary. Over-Engineering (Pass B): no trim — all CULL-sourcing auditors clean for ux-spec. Coherence: all cited path literals resolve, doctrine_check.sh all arms PASS. Spec Alignment vacuous.

### Rename
No rename.

## 2026-07-20 (Phase 4 history compaction)

### Summary
Compacted 2 entries (2026-06-05..2026-06-08) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 2 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-20

### Summary
Correctness (L41): §4 Interaction Design now requires any affordance gated on backend/system state to cite the authoritative code-level eligibility predicate verbatim (grepped, confirmed against code) rather than describe the condition in prose. Closes a verified inverted-gate defect class — a prose-derived gate showed exactly when the backend would reject the action.

### Changes
- AMPLIFY: §4 Required Section — affordance visibility/enablement gates MUST cite the backend predicate (handler precondition / accepted-state set) as ground truth, not infer from prose. Grounded in ux-designer memory L113-116 (real 422-inverted `s switch backend` affordance).

### Dimensions Evaluated
All 8. Correctness (L41 AMPLIFY — sole finding). Over-Engineering (HIGHEST): no removable waste; file settled after ~20 cycles. Bug/repetition/model-routing/innovation auditors: clean for ux-spec. No model/routing/drift change (6 invocations, 3× opus / 3× fable, no error/respawn/correction signal).

### Rename
No rename.

## 2026-07-14 (Phase 4 history compaction)

### Summary
Compacted 2 entries (2026-06-04..2026-06-05) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 2 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-14

### Summary
Coherence: added `docs/adr/` to the DOCS-PATHS-LOCAL Reads list to match Authoring Procedure §1, which greps `docs/adr/` for prior art. No behavior change — the read already happened; only the declared read-surface was stale.

### Changes
- DOCS-PATHS-LOCAL Reads: `docs/spec/`, `docs/tdd/`, `docs/ux/` → +`docs/adr/`.

### Dimensions Evaluated
Coherence (declared-contract vs. body), Completeness, Over-Engineering (Pass B — no trims warranted), Skill Design Quality (frontmatter parity confirmed clean).

### Rename
No rename.

## 2026-07-12

### Summary
Correction: the 2026-06-04 entry below claims `Glob`/`Grep` were dropped from `allowed-tools`, but the live SKILL.md retains and actively uses both (prior-art discovery; confirmed present and used at the 2026-06-10, 2026-06-17, and 2026-07-10 full-cycle audits). The removal claim was never accurate for this file. Noted as historical artifact — entry left immutable per changelog policy. Family lockstep: adr/prd/tdd already carry an equivalent correction note (2026-06-09); this closes the gap for ux-spec.

### Changes
- None (changelog-hygiene only; no SKILL.md change).

### Dimensions Evaluated
None (changelog correction, not a review cycle).

### Rename
No rename.

## 2026-07-10

### Summary
Fixed the broken COLLISION_DIALOG "Overwrite" branch — it Wrote over an existing file without a prior Read, which the harness rejects (FIX6, largest error class in the bug audit). Cross-cutting: applied byte-identically across adr/prd/tdd/ux-spec.

### Changes
- AMPLIFY: Overwrite branch now Reads `{output_path}` before Write to satisfy the harness read-before-overwrite gate. Grounded in FIX6 (largest error class). CANONICAL:COLLISION_DIALOG lockstep across the 4 doc-authoring siblings.

### Dimensions Evaluated
All 8. Over-Engineering (HIGHEST): no removable waste — file settled after ~15 cycles. Correctness: closed the latent Overwrite-abort. No model/routing/drift change (n=1, no signal).

### Rename
No rename.

## 2026-06-30

### Summary
Aligned UX prior-art discovery with sparse-doc-root behavior used by sibling doc-authoring skills.

### Changes
- AMPLIFY: gather prior art only from existing `docs/spec/`, `docs/tdd/`, and `docs/ux/` roots.

### Dimensions Evaluated
Phase 2 coherence.

### Rename
No rename.

## 2026-06-30

### Summary
Tightened UX layout guidance around rendered targets and interaction-state coverage, net 0.

### Changes
- AMPLIFY: structure sketches must name rendered effect target and states.
- AMPLIFY: required Interaction Design now includes a per-component/workflow interaction-state matrix.

### Dimensions Evaluated
All 8.

### Rename
No rename.

## 2026-06-30

### Summary
Phase-3 follow-on: widened the §5 mermaid diagram-type allow-list to non-exhaustive. Inline, net 0.

### Changes
- AMPLIFY: §5's keyword list is now `e.g.`-prefixed (non-exhaustive) and adds `journey`, `classDiagram`, `gantt` — the Phase-2 4-keyword list would have rejected valid diagram types. Applied byte-identically across tdd/prd/ux-spec §5. Phase-3 remaining-issue catch.

### Dimensions Evaluated
All 8. Over-Engineering: inline, net 0. Correctness: closed a self-introduced validation gap. No model/routing/drift change.

### Rename
No rename.

## 2026-06-30

### Summary
Phase-2 family-wide: strengthened Validation §5 from mermaid presence-only to "presence & shape" (renderer-free diagram-type-keyword check), applied byte-identically across tdd/prd/ux-spec §5 in lockstep. Phase 1 was RETAIN (wireframe-preview candidate already encoded at Authoring Procedure step 5).

### Changes
- AMPLIFY: §5 now requires the mermaid block's first non-blank line to declare a diagram-type keyword — catches the empty/typeless block that renders broken but passed presence-only. Renderer-free (no mermaid CLI in-repo, verified). Cited INNOVATION.
- NO-OP (verified already-encoded): the AskUserQuestion `preview`-for-wireframes recommendation already exists at Authoring Procedure step 5.

### Dimensions Evaluated
All 8. Over-Engineering: +5 lines, justified. No model/routing/drift change.

### Rename
No rename.

## 2026-06-17

### Summary
Added the COLLISION_DIALOG teammate-context caveat (lockstep across the 4 doc-authoring skills). Trial: inert-caveat → adopted.

### Changes
- AMPLIFY: COLLISION_DIALOG teammate-context caveat — AskUserQuestion is inert in a teammate, so the overwrite guard must block (route to team-lead) rather than silently overwrite. Applied byte-identically across adr/prd/tdd/ux-spec.

### Dimensions Evaluated
Correctness (AMPLIFY), others RETAIN.

### Rename
No rename.

## 2026-06-10

### Summary
Full 8-dimension review: NO changes. Six verification probes clean (rendered-EFFECT, content-design, Design Output Tiers, Mermaid cites all grounded in agents/ux-designer.md; {TYPE} parity locked; allowed-tools Glob/Grep present post-c10195b restoration).

### Changes
- None (NO-OP verdict).

### Dimensions Evaluated
All 8; Over-Engineering (HIGHEST — four Mermaid mentions each serve distinct roles, no removable waste); Coherence (changelog-vs-file drift false-positive resolved via git log -S); Spec Alignment (all cites grounded).

### Rename
No rename.

## 2026-06-10

### Summary
Compacted 11 entries (2026-05-09..2026-05-30) into Compacted history per ADR 0001.

### Changes
- Replaced the 11 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per ADR 0001, not a review cycle.

### Rename
No rename.

## Compacted history

Entries below were compacted per ADR 0001; full text in git history (see the compaction entry's date).

- 2026-05-06: First entry: removed three dead TDD §X.Y cross-references; broadened the N/A section allowance across surface types (296→298).
- 2026-05-06: Removed dead missing-parent-prompt phrase from Save & Return — prior-art scan is informational and never prompts.
- 2026-05-06: Phase 1 trim: removed five duplicated rules incl. self-check, prior-art scan, path restatement, and third Mermaid repetition (298→282).
- 2026-05-06: Added create-* family COUPLING comment to When NOT to Use for sibling-asymmetry prevention.
- 2026-05-06: Renamed create-ux-spec → ux-spec per operator request; directory, frontmatter name, /ux-spec slash command, and cross-references updated.
- 2026-05-06: Coherence sweep: dropped sub-agent prohibition row from Failure Modes; added blank line before Output Contract for formatting parity.
- 2026-05-07: Phase 2 coherence: H1 fixed from # Create UX Spec to # UX Spec to match frontmatter name.
- 2026-05-07: Restored status-field and Mermaid-missing Failure Modes rows for PRD parity; Mermaid Mandate clarified for non-GUI surfaces; Open Questions scoped.
- 2026-05-09: Sharpened §9 Handoff Notes with required sub-bullets and a vague-entries-are-a-defect rule; removed duplicate ASCII-wireframes sentence.
- 2026-05-09: Phase 2 coherence: removed the orphaned `### Failure Mode Table` subheading. PRD retains the subheading because it has a load-bearing sibling H3 (`### Reserv...
- 2026-05-09: Four handoff + actionability fixes (operator pain points 1, 2, 3): added `AskUserQuestion preview` guidance for visual variant comparison, strengthened cross...
- 2026-05-09: Phase 2 coherence pass: hardened Validation §4 to self-reference Required Sections instead of hardcoding "all 9".
- 2026-05-16: Coherence: added cross-family delegation routes to design-review (peer review of UX spec drafts) and design-qa (implementation verification against UX spec)...
- 2026-05-17: Replaced brittle curly-placeholder trigger `"design spec for {surface}"` with a concrete operator-typeable example (`"design spec for the new CLI"`). The pla...
- 2026-05-18: Surfaced the calling agent's Design Output Tiers gating directly in `When NOT to Use` — adds an explicit "skip to lighter tier" route for internal-only surfa...
- 2026-05-25: Phase 2 coherence: removed TYPE substitution note (lockstep) and removed stale "(currently 9 sections)" count from Validation §4 (mirrors tdd fix).
- 2026-05-25: Five over-engineering trims and one sibling-parity hardening: dropped dead "broader than pre-flight scan" parenthetical (2026-05-06 removed that step), colla...
- 2026-05-28: Closed a §9 Handoff Notes coordination gap (operator priority): orthogonalized the two priority axes — (a) is now the sequence axis (P0/P1/P2 for @project-ma...
- 2026-05-29: Merged two overlapping When-to-Use bullets into one, and corrected the same `allowed-tools`-excludes-Edit misinformation found in prd/tdd (per docs, allowed-...
- 2026-05-30: One over-engineering trim: Authoring §4 was re-declaring the Mermaid rule (including the diagram-type examples) that the canonical "### Mermaid Mandate" sect...
- 2026-06-04: Dropped vestigial Glob/Grep from allowed-tools (prior art via docket doc list/show + Read, not Glob/Grep). Family lockstep with adr/prd/tdd.
- 2026-06-05: Phase 2 coherence — added fenced-code-block carve-out to §4 Section-order validation (count `##` headings outside fences); family parity.
- 2026-06-05: Phase 1 — removed false circular ux-designer.md cross-ref (self-owns section list); Phase 2 restored status: authority caveat (lockstep prd).
- 2026-06-08: Removed circular cite again — 2026-06-05 fix was un-applied/reverted; grep re-confirmed ux-designer.md doesn't enumerate 9 sections. Net -1.
- 2026-06-09: No changes. Full 8-dimension review with 6 verification probes, all clean: no unescaped `$`+digit; `allowed-tools` in byte-identical family lockstep (current...
- 2026-06-09: Mythos/Fable-5 cycle audit: NO changes. Reasoning-echo clean (rendered-effect lines are artifact-content guidance, not narration); $-escape clean; no over-pr...
- 2026-06-09: Full-cycle audit: NO changes. 9 verification probes all clean: Glob/Grep present and used (c10195b restore — no phantom drift, pitfall #10 applied via git lo...
- 2026-06-09: Compacted 9 entries (2026-05-06..2026-05-09) into Compacted history per ADR 0001.
- 2026-06-10: Phase 2 lockstep trim: removed the redundant "additional positional args" Failure-Mode row (dup of CANONICAL:ARGUMENT_HANDLING); applied identically to prd/tdd/adr/ux-spec. Net -1 (296 lines).
- 2026-06-10: Full 8-dimension review: NO changes. Zero invocations in window; allowed-tools/TYPE substitution/CANONICAL blocks all verified intact. Net 0.
