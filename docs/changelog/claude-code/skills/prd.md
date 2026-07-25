# Changelog: prd

## 2026-07-24

### Summary
Compacted 5 entries (2026-06-05..2026-06-09) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 5 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-24

### Summary
Phase 3 disambiguation: "TDDs have none either" read ambiguously (either "no override" or "no Validation Before Save enforcement" depending on which antecedent clause "none" binds to).

### Changes
- CLARIFY[COSMETIC]: "TDDs have none either" → "TDDs likewise have no override" — pins the antecedent explicitly.

### Dimensions Evaluated
Coherence (disambiguation pass, Two-arm Boundary test — passed Arm 1 coherence, failed Arm 2 clarity).

### Rename
No rename.

## 2026-07-24

### Summary
Validation-Before-Save steps 1-2 normalized to the family union shape (tdd's resolved-path + python3 + exit-126 + missing-validator clauses) keeping {staging_dir}; {output_dir} bound explicitly in Pre-flight; false "Unlike TDDs...override" claim corrected against doc_validate.py.

### Changes
- REFACTOR[SUBSTANTIVE]: steps 1-2 → union/reference shape, quoted staged path.
- COHERENCE: Pre-flight step 2 binds {output_dir} (consumed by CANONICAL:SAVE_AND_RETURN; edit outside the block).
- BUGFIX[SUBSTANTIVE]: Mermaid Mandate no longer implies a TDD pure-policy override exists (verified: mermaid:True unconditional for both; adr is the only type without the mandate).

### Dimensions Evaluated
Coherence, Bug/Correctness. Phase 2 pass.

### Rename
No rename.

## 2026-07-24

### Summary
Fixed three verified-live defects in the Validation/Output-Contract path: Write never expands $TMPDIR so the staged draft landed off-target; the validator was invoked as a bare executable, making a lost +x bit exit 126 outside the documented 0/1/2 contract; the Mermaid mandate omitted the first-line-keyword rule the validator enforces and cited a nonexistent Validation §5. One Pass-B trim. Findings: 3 sub / 1 cos / 0 rej / 0 def / 1 enc

### Changes
- AMPLIFY[SUBSTANTIVE]: staging step resolves the staging dir via `Bash echo "${TMPDIR:-/tmp}"` and Writes the resolved absolute path; validator invoked as `python3 ~/.claude/scripts/doc_validate.py` so a lost executable bit no longer yields an unhandled exit 126. Cross-cutting — same defect in tdd/adr/ux-spec.
- AMPLIFY[SUBSTANTIVE]: Mermaid Mandate now states the first-non-blank-line diagram-keyword rule and points at "Validation Before Save" instead of the nonexistent §5.
- AMPLIFY[SUBSTANTIVE]: Required Sections states headings carry the title only, never the list number (H-ux-spec-1 parity family fix).
- CULL[COSMETIC]: removed the third restatement of "no overwrite path" from the Reserved-Name List preamble.

### Dimensions Evaluated
All 8. Pass A: 3 verified defects applied. Pass B: 1 trim; Validation/Failure-Mode pairing retained per 2026-07-10.

### Rename
No rename.

## 2026-07-20 (Phase 4 history compaction)

### Summary
Compacted 2 entries (2026-06-04..2026-06-05) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 2 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-20

### Summary
Full-cycle audit: NO changes. All 8 dimensions clean. Zero prd-specific Phase 0 signals (historical/model-routing/docs/bug/repetition all report nothing for prd); zero ledger findings. Verified doc_validate.py (prd rule) still mechanizes every claimed check — maturity allow-list, no-status forbid_field, section order, mermaid, success-metrics concreteness — matching the skill's Validation/Failure-Mode prose.

### Changes
- None (NO-OP verdict). CANONICAL shared blocks (ARGUMENT_HANDLING, COLLISION_DIALOG, SAVE_AND_RETURN, DOCS-PATHS-LOCAL) byte-consistent with tdd/adr siblings. Validator coherence re-confirmed against ~/.claude/scripts/doc_validate.py lines 52-60.

### Dimensions Evaluated
All 8; Over-Engineering: no trims (Validation/Failure-Mode pairing still deliberate per 2026-07-10).

### Rename
No rename.

## 2026-07-14

### Summary
Full-cycle audit: NO changes. All 8 dimensions clean. Pass A verified RESERVED-NAMES list is in sync with init-specs' Spec File Reference table (no drift); Pass B found no un-deliberate over-engineering (Validation/Failure-Mode pairing remains intentional per 2026-07-10).

### Changes
- None (NO-OP verdict). RESERVED-NAMES 7-name parity with init-specs verified. I27 (reserved-names doctrine_check arm) DEFER/PARITY-BOUND — shared-infra script, out of SKILL.md scope. I28 (doc-family CANONICAL manifest rows) PARITY-BOUND with I26/I30/I31.

### Dimensions Evaluated
All 8; Over-Engineering: no trims (prior-cycle Validation/Failure-Mode pairing still deliberate).

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
Full-cycle audit: NO changes. All 8 dimensions clean. Every prd-specific Phase-0 signal (invocations, pitfalls, model routing) reads zero; global bug findings inapplicable to this leaf skill.

### Changes
- None (NO-OP verdict). CANONICAL:COLLISION_DIALOG byte-identical across prd/tdd/adr/ux-spec (verified); SAVE_AND_RETURN shared body matches prd/adr/ux-spec.

### Dimensions Evaluated
All 8; Over-Engineering (no trims remaining, prior-cycle Validation/Failure-Mode pairing still deliberate).

### Rename
No rename.

## 2026-06-30

### Summary
Hardened prior-art discovery for sparse docs dirs and made Docket overlap reporting table-shaped, net 0.

### Changes
- AMPLIFY: prior-art discovery builds a search set from existing docs directories and tolerates sparse repos.
- AMPLIFY: Docket overlap reporting is a compact table with unavailable-Docket fallback.

### Dimensions Evaluated
All 8.

### Rename
No rename.

## 2026-06-30

### Summary
Phase-3 follow-on: widened the §5 mermaid diagram-type allow-list to non-exhaustive. Inline, net 0.

### Changes
- AMPLIFY: §5's keyword list is now `e.g.`-prefixed (non-exhaustive) and adds `journey`, `classDiagram`, `gantt` — closes the contradiction where prd's Mermaid Mandate invites a `journey` diagram but the Phase-2 4-keyword list would have rejected it. Applied byte-identically across tdd/prd/ux-spec §5. Phase-3 remaining-issue catch.

### Dimensions Evaluated
All 8. Over-Engineering: inline, net 0. Correctness: closed a self-introduced validation gap. No model/routing/drift change.

### Rename
No rename.

## 2026-06-30

### Summary
Phase-2 family-wide: strengthened Validation §5 from mermaid presence-only to "presence & shape" (renderer-free diagram-type-keyword check), applied byte-identically across tdd/prd/ux-spec §5 in lockstep. Phase 1 was RETAIN (no-signal organism).

### Changes
- AMPLIFY: §5 now requires the mermaid block's first non-blank line to declare a diagram-type keyword — catches the empty/typeless block that renders broken but passed presence-only. Renderer-free (no mermaid CLI in-repo, verified). Cited INNOVATION. §191 Mandate + Failure-Mode table reference §5 by number (no satellite edit needed).

### Dimensions Evaluated
All 8. Over-Engineering: +5 lines, justified. No model/routing/drift change; docket commands untouched.

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
Full-cycle audit: NO changes. All 8 dimensions clean at 274 lines.

### Changes
- None (NO-OP verdict). Reserved-name refusal (step 4) verified to precede collision dialog (step 5) — the historical refusal-gate pitfall is resolved in the live body. Glob/Grep allowed-tools body-exercised (L86/L117); 2026-06-04 changelog removal claim is an applied-then-reverted artifact.

### Dimensions Evaluated
All 8; Over-Engineering (HIGHEST — no trims remaining); Coherence (CANONICAL block parity intact); Spec Alignment (docs/spec/ singular, init-specs coupling intact).

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

## 2026-06-10

### Summary
Phase 2 lockstep trim: removed the redundant "additional positional args" Failure-Mode row — CANONICAL:ARGUMENT_HANDLING body (L41) already states the identical ignore-silently rule. Applied identically to all 4 doc-authoring siblings (prd/tdd/adr/ux-spec, -1 each). Net -1 (274 lines).

### Changes
- Failure Modes: deleted last table row (intra-file duplication of the CANONICAL block; byte-identical removal across the family, grep-verified 0 survivors).

### Dimensions Evaluated
Coherence (family lockstep), Over-Engineering.

### Rename
No rename.

## 2026-06-10

### Summary
Full-cycle audit: NO changes. All 8 dimensions clean. One family-wide redundancy (extra-positional-args Failure Mode row duplicates CANONICAL:ARGUMENT_HANDLING body text) confirmed parity-bound across all 4 doc-authoring siblings — deferred to Phase 2.

### Changes
- None (NO-OP verdict).

### Dimensions Evaluated
All 8; Over-Engineering (HIGHEST — no solo trims remaining; family-wide row deferred); Coherence (allowed-tools verified against body; CANONICAL block parity intact); Spec Alignment (docs/spec/ singular, reserved-name init-specs coupling intact).

### Rename
No rename.

## 2026-06-09

### Summary
Compacted 9 entries (2026-05-06..2026-05-07) into Compacted history per ADR 0001.

### Changes
- Replaced the 9 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per ADR 0001, not a review cycle.

### Rename
No rename.

## Compacted history

Entries below were compacted per ADR 0001; full text in git history (see the compaction entry's date).

- 2026-05-06: First entry: replaced unverifiable TDD §4.11 reference, removed duplicate self-check checklist, named the MoSCoW scheme explicitly.
- 2026-05-06: Removed dead missing-parent-prompt phrase from Save & Return — PRDs are top-level with no parent-doc probe.
- 2026-05-06: Phase 1 trim: removed Mermaid Mandate editorial commentary and duplicate output-path footer; COUPLING comment now names all 4 siblings.
- 2026-05-06: Collapsed Mermaid Mandate triple-restatement to a single paragraph deferring to Authoring §5 and Validation Before Save.
- 2026-05-06: Renamed create-prd → prd per operator request; directory, frontmatter name, /prd slash command, and cross-references updated.
- 2026-05-06: Replaced stale dev-skill reference with the team-lead Large Task pattern; reserved-name COUPLING comment made symmetric with siblings.
- 2026-05-07: Phase 2 coherence: H1 fixed from # Create PRD to # PRD to match frontmatter name.
- 2026-05-07: Added missing When-NOT-to-Use COUPLING comment; corrected reserved-names COUPLING — lockstep is PRD ↔ specs only, not 5-way.
- 2026-05-07: Removed redundant sub-agent prohibition row from Failure Modes for symmetry with ux-spec.
- 2026-05-09: Six output-quality fixes (operator pain point 3): added concreteness gates to Success Metrics and Requirements sections, sharpened Docket probe with priority...
- 2026-05-09: Phase 2 coherence pass: hardened Validation §4 to self-reference Required Sections instead of hardcoding "all 7".
- 2026-05-09: Coherence pass: aligned When NOT to Use delegation ordering with sibling doc-authoring skills (tdd, adr, ux-spec) and sharpened PRD-vs-TDD disambiguation in...
- 2026-05-16: Three small actionability fixes targeting operator pain on output quality and Docket integration: named the priority scheme in User Stories §4 (was undefined...
- 2026-05-17: One over-engineering trim from the 2026-05-17 broad sweep: de-duplicated the reserved-name error string. Pre-flight §5 was restating the same error message a...
- 2026-05-18: One completeness fix: added Failure Mode row for invalid `maturity` value (proof-of-concept | draft | experimental | stable). Validation §3 enumerated the al...
- 2026-05-25: Phase 2 coherence: removed redundant TYPE substitution note (canonical ARGUMENT_HANDLING block's placeholder is self-explanatory).
- 2026-05-25: Six edits: broadened trigger phrases to catch informal asks ("write up requirements for", "scope this feature") addressing zero-invocation signal, plus five...
- 2026-05-28: One coordination fix (net 0): linked Authoring §1 prior-art discovery to the `dependencies` frontmatter field so downstream reviewers/decomposition can trace...
- 2026-05-29: Corrected a factually-incorrect frontmatter rationale: `allowed-tools` does NOT remove `Edit` from the skill's tool pool (per Claude Code docs, every tool st...
- 2026-05-30: Single over-engineering trim: collapsed the triple-listed `maturity` allowed-set to one canonical source (Field rules), preventing independent drift. Net 0.
- 2026-06-04: Dropped vestigial Glob/Grep from allowed-tools — prior-art discovery uses docket doc list/show (Bash) + Read; lockstep with adr/tdd/ux-spec.
- 2026-06-05: Phase 2 coherence — added fenced-code-block carve-out to §4 Section-order validation (count ## outside fences); lockstep with tdd/adr/ux-spec.
- 2026-06-05: Phase 1 no-change verdict. Phase 2: restored the body-`status:` authority caveat (lockstep with ux-spec) — warns the field is documentation-only, names Docke...
- 2026-06-08: Phase 1 no-change verdict (277 lines, ~25 cycles). Verified load-bearing claims: CANONICAL blocks (BANNER/ARGUMENT_HANDLING/COLLISION_DIALOG/SAVE_AND_RETURN)...
- 2026-06-09: One completeness fix (net −1): reordered Pre-flight so reserved-name refusal precedes the collision check. All 7 reserved files exist on disk after init-spec...
- 2026-06-09: Mythos/Fable-5 cycle audit: NO changes. Historical overwrite-guard signal verified resolved in live file (reserved-name refusal step 4 L85 precedes collision...
- 2026-06-09: Full-cycle audit: NO changes. Reserved-name ordering signal verified resolved (refusal step 4 L85 precedes collision dialog step 5 L86). Stale 2026-06-04 ent...
