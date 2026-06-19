# Changelog: design-qa

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

## 2026-06-10

### Summary
Phase 2 coherence: removed dead `{today_date}` Pre-flight variable (grep-confirmed 1 definition, 0 template uses) and renumbered Pre-flight steps 4-7 → 3-6. Measured net -2 (214 → 212). Family ruling recorded: disable-model-invocation NOT adopted (agents/ux-designer.md `skills:` preload path is real).

### Changes
- CULL: Pre-flight step 3 "Resolve context" deleted (dead variable, lockstep with verify-ac/design-review) — cited signal: coherence-reviewer grep verification.
- Phase 2 rulings: silent-completion phrasing variance ruled acceptable (all four family carriers present, content equivalent); disable-model-invocation declined family-wide.

### Dimensions Evaluated
Coherence (lockstep removal + renumber; no §-refs existed), Consistency.

### Rename
No rename.

## 2026-06-10

### Summary
No changes applied. Reviewer proposed `disable-model-invocation: true` + When-to-Use trim, but the sibling design-review reviewer rejected the same flag and orchestrator grep confirmed agents/ux-designer.md lists design-qa under `skills:` (preload reliance) — conflicting parity-bound recommendation deferred to Phase 2.

### Changes
- None (deferred). disable-model-invocation family question (design-qa/design-review, possibly code-review-verdict/verify-ac) routed to Phase 2 with the empirical datum above.

### Dimensions Evaluated
All 8; shutdown-handshake verified lead-initiated; post-ABORT re-invocation parity with design-review verified clean (L194/L221); COUPLING marker byte-identical.

### Rename
No rename.

## 2026-06-10

### Summary
Compacted 11 entries (2026-05-16..2026-05-29) into Compacted history per ADR 0001.

### Changes
- Replaced the 11 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per ADR 0001, not a review cycle.

### Rename
No rename.

## 2026-06-10

### Summary
Phase 1 audit: NO changes. All historical-audit signals (render-gate mandate, HTTP-200 vs. rendered-content liveness, Marp/static-export unbundled-asset risk) verified fully encoded at L107-108 and Severity ladder L123. Docket CLI references carry no phantom flags. Consecutive NO-OP: 4th cycle.

### Changes
- None.

### Dimensions Evaluated
All 8; Over-Engineering primary (214 lines — within budget, no untrimmable redundancy); Completeness (both audit signals pre-encoded, grep-confirmed); Coherence (COUPLING marker, Doubling Rule, family parity).

### Rename
No rename.

## 2026-06-09

### Summary
Full-cycle audit: NO changes. Render-gate signal (3rd consecutive re-fire from cross-project memory) definitively closed — mandate fully encoded at L107 (media liveness by render), L108 (render-to-image + visually READ, MANDATORY), L123 (Blocker row). Fresh grep citations recorded.

### Changes
- None (NO-OP verdict).

### Dimensions Evaluated
All 8; Over-Engineering primary (214 lines, parity-bound blocks only); Coherence (COUPLING marker + Doubling Rule byte-parity with design-review confirmed).

### Rename
No rename.

## 2026-06-09

### Summary
Mythos/Fable-5 cycle audit: NO changes. The strong cross-repo render-gate signal (fem-kubernetes) verified FULLY encoded in live file: render-to-image + visually-READ at delivery resolution mandatory gate (L108, Blocker row L123); embedded-media liveness by render not HTTP 200 (L107). Reasoning-echo + $-escape + recall-filter audits clean.

### Changes
- None (NO-OP verdict, render-gate coverage grep-cited against live file).

### Dimensions Evaluated
All 8; Over-Engineering primary; historical render-gate signal NO-OP with citation.

### Rename
No rename.

## 2026-06-09

### Summary
Phase 2: MVP-cutline consumer note added to Pre-flight; code-review→code-review-verdict reference updates (lockstep).

### Changes
- Pre-flight step 4 now captures the ux-spec §9 Handoff Notes MVP cutline; deferred-polish components route to Acceptable Deviations, not Blockers (closes the ux-spec §9(b) consumer gap).
- 3 refs updated for the sibling rename, incl. the byte-identical COUPLING marker.

### Dimensions Evaluated
Coherence (ux-spec contract, family lockstep), Completeness.

### Rename
No rename (sibling code-review renamed → code-review-verdict; refs updated).

## 2026-06-09

### Summary
Phase 1 no-change verdict (2nd consecutive). Verified both historical-audit signals (render-content-not-liveness; perceptual legibility at screenshare scale) already Blocker-enforced (QA Procedure step 2 + Severity ladder, added 2026-06-04).

### Changes
- None. Unescaped-$-substitution scan clean; COUPLING marker byte-identical across the 4 siblings; team-lead.md Rule 8/step 14 references resolve. disallowed-tools family decline reaffirmed.

### Dimensions Evaluated
All 8; Over-Engineering (HIGHEST — no untrimmable redundancy at 215 lines), Completeness (both audit signals pre-encoded), Coherence (family parity md5-verified).

### Rename
No rename.

## 2026-06-08

### Summary
Phase 1 no-change verdict. Verify-then-recommend confirmed the cross-project render mandate (render-and-LOOK / external-asset bundling / legibility-at-scale) is already Blocker-enforced (QA Procedure step 2 + Severity ladder, added 2026-06-04) — a NO-OP, not a re-add. COUPLING marker byte-identical across the 4 leaf siblings.

### Changes
- None.

### Dimensions Evaluated
All 8; Over-Engineering (HIGHEST — no redundancy at 215 lines), Completeness (render mandate present), Coherence (family parity verified).

### Rename
No rename.

## 2026-06-05

### Summary
Phase 2 coherence: moved the report-emission COUPLING marker above "When NOT to Use" and synced its text with the family. All 4 markers now byte-identical. Phase 1 review found no other gap.

### Changes
- COUPLING marker relocated under "When NOT to Use"; doubling-rule parity sentence added.

### Dimensions Evaluated
Coherence (report-emission family COUPLING parity).

### Rename
No rename.

## 2026-06-04

### Summary
Added a Phase-0-validated media-rendering edge case to QA Procedure step 2 — design-qa's documented distinct value is catching dead media payloads (HTTP 200 / ref present but renders "content not available") that all @sdet liveness checks miss. Offset by removing the redundant "Stream long commands" bullet (duplicate of Pre-flight step 7). Net -1.

### Changes
- QA Procedure step 2: appended an externally-referenced-media check — confirm rendered content, not HTTP 200 / ref presence.
- Common Discipline: removed "Stream long commands" bullet — duplicate of Pre-flight step 7 (same run_in_background + Monitor prescription).

### Dimensions Evaluated
Completeness (HIGHEST — media-rendering gap), Over-Engineering (net -1 — bullet removal offsets the in-line addition), Coherence (clause is design-qa-specific — no family lockstep needed).

### Rename
No rename.

## 2026-05-30

### Summary
Aligned the Doubling Rule with team-lead.md Rule 8: design QA defaults to a single ux-advisor (opt up to doubled per Rule 8 triggers) rather than framing ≥2 parallel reviewers as the default. Canonical ephemeral name design-qa-{N}. Net 0.

### Changes
- Doubling Rule: "spawns ≥2 reviewers in parallel" (default) → "defaults to a single ux-advisor … opt up to a doubled panel when a Rule 8 trigger fires"; ephemeral `design-qa-2` → `design-qa-{N}`. Applied in lockstep with design-review (identical inversion) and code-review.

### Dimensions Evaluated
Coherence (HIGHEST — authority divergence vs team-lead.md Rule 8 default-single), Over-Engineering (no trim; net 0), Skill Design, Actionability, Completeness, Orchestration, Spec Alignment, Rename.

### Rename
No rename.

## 2026-05-29

### Summary
Harmonized the silent-completion self-check framing with the report-emission skill family (Phase 2 coherence).

### Changes
- Self-check now frames the actor as the calling agent ("the calling agent MUST self-check"), removing the self-referential "confirm you SendMessaged...to the calling agent" phrasing — the skill loads into the calling agent's context, so the calling agent is the actor. Matches code-review/verify framing. [Phase 2 coherence item 3]

### Dimensions Evaluated
Cross-skill coherence; instruction accuracy.

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
