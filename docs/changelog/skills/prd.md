# Changelog: prd

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

## 2026-06-09

### Summary
Full-cycle audit: NO changes. Reserved-name ordering signal verified resolved (refusal step 4 L85 precedes collision dialog step 5 L86). Stale 2026-06-04 entry (claimed Glob/Grep removal never reflected in live file) noted as historical artifact — entries immutable, live state correct.

### Changes
- None (NO-OP verdict).

### Dimensions Evaluated
All 8; Over-Engineering primary (275 lines, no trims remaining); Coherence (allowed-tools vs body consistent; sibling parity with adr/tdd/ux-spec intact).

### Rename
No rename.

## 2026-06-09

### Summary
Mythos/Fable-5 cycle audit: NO changes. Historical overwrite-guard signal verified resolved in live file (reserved-name refusal step 4 L85 precedes collision dialog step 5 L87; Failure Mode table ordering matches). Reasoning-echo clean; $-escape clean.

### Changes
- None (NO-OP verdict, guard-ordering grep-cited against live file).

### Dimensions Evaluated
All 8; Over-Engineering primary; reasoning-echo + $-escape audits clean.

### Rename
No rename.

## 2026-06-09

### Summary
One completeness fix (net −1): reordered Pre-flight so reserved-name refusal precedes the collision check. All 7 reserved files exist on disk after init-specs runs, so the old ordering routed reserved slugs into COLLISION_DIALOG's "Overwrite" option before the hard-refusal fired — contradicting the Failure Mode table's "(and slug is not reserved)" precedence.

### Changes
- Pre-flight: reserved-name refusal moved from step 5 to step 4, ahead of collision; cross-reference in When NOT to Use updated (step 5 → step 4).
- Phase-0 doc audit clean: no unescaped $-digit, description under budget, format authority within compaction cap.

### Dimensions Evaluated
All 8; Over-Engineering (HIGHEST — no remaining trims; rejected docket-doc adoption as reversal of c10195b), Completeness (primary), Coherence (init-specs reciprocal coupling verified intact).

### Rename
No rename.

## 2026-06-08

### Summary
Phase 1 no-change verdict (277 lines, ~25 cycles). Verified load-bearing claims: CANONICAL blocks (BANNER/ARGUMENT_HANDLING/COLLISION_DIALOG/SAVE_AND_RETURN) byte-identical (md5) across prd/tdd/adr/ux-spec; docs-path taxonomy match (singular docs/spec/, prd writes {slug}.md); reserved-name reciprocal coupling with init-specs intact.

### Changes
- None.

### Dimensions Evaluated
All 8; Over-Engineering (HIGHEST — Validation/Failure-Mode pairing is deliberate, not redundant), Coherence (CANONICAL parity + reserved-name lockstep), Orchestration (leaf confirmed).

### Rename
No rename.

## 2026-06-05

### Summary
Phase 1 no-change verdict. Phase 2: restored the body-`status:` authority caveat (lockstep with ux-spec) — warns the field is documentation-only, names Docket `.data.status` as the single source of truth for downstream gates, never gate on the body value.

### Changes
- `status` field rule: appended source-of-truth + documentation-only + never-gate caveat (+4 lines, identical to ux-spec).

### Dimensions Evaluated
All 8; Over-Engineering (HIGHEST — prior cycles already deduped), Coherence (family status-authority parity).

### Rename
No rename.

## 2026-06-05

### Summary
Phase 2 coherence: added a fenced-code-block carve-out to the §4 Section-order validation (count only `##` headings outside ``` fences), for doc-authoring family parity (lockstep with tdd/adr/ux-spec). Phase 1 review found no other gap.

### Changes
- §4 Section order: count only `##` headings at column 0 outside ``` code fences.

### Dimensions Evaluated
Coherence (doc-authoring family lockstep).

### Rename
No rename.

## 2026-06-04

### Summary
Dropped vestigial `Glob`/`Grep` from `allowed-tools` — prior-art discovery uses `docket doc list`/`show` (Bash) and `Read`, never the Glob/Grep tools. Family lockstep with adr/tdd/ux-spec.

### Changes
- `allowed-tools` trimmed to `["AskUserQuestion", "Bash", "Read", "Write"]` (dropped `Glob`, `Grep`).

### Dimensions Evaluated
Skill Design Quality (frontmatter tool pool), Coherence (byte-identical lockstep with adr/tdd/ux-spec).

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
