# Changelog: tdd

## 2026-06-17

### Summary
Added a co-author single-writer baton note, restructured assertion-verification as a checklist, and added the COLLISION_DIALOG teammate-context caveat (lockstep). Trial: baton / verify-checklist / inert-caveat → adopted.

### Changes
- AMPLIFY: single-writer baton note — concurrent co-author edits to one TDD cause "File modified since read"; serialize via team-lead, file-on-disk is the handoff state.
- AMPLIFY: step-5 verify restructured into a 4-arm checklist (snippet/portability/size/module), citing staff-engineer.md's Executable-claim gate (rule 6) rather than restating it.
- AMPLIFY: COLLISION_DIALOG teammate-context caveat (AskUserQuestion inert in teammates → block, don't silently overwrite); applied lockstep across adr/prd/tdd/ux-spec.

### Dimensions Evaluated
Completeness / Correctness (AMPLIFY), Over-Engineering (RETAIN), others RETAIN.

### Rename
No rename.

## 2026-06-10

### Summary
Closed the cited 2026-06-10 staff pitfall (TDD line-budget feasibility asserted from estimate — a net-additive phase nearly breached the 500-line gate): Authoring §5's verify-before-settled enumeration now names quantitative/line-budget feasibility claims (measure with wc -l/sed -n, never estimate). Measured net +1 (301 → 302 per post-apply wc -l; reviewer estimate was 0).

### Changes
- AMPLIFY: Authoring §5 — added quantitative/line-budget claims to the MUST-verify enumeration; dropped the illustrative "zero X exist (verified)" tail parenthetical (normative rule stands without it) — cited signal: staff pitfalls 2026-06-10 line-budget re-fire.

### Dimensions Evaluated
All 8; Completeness primary; AC-vocabulary focus area confirmed already encoded (§5 L142-144 + §11(c)); staff-engineer.md L111 quantitative-arm gap routed out of scope (tracking issue); CANONICAL shared-include duplication remains a Phase 2 standing item.

### Rename
No rename.

## 2026-06-10

### Summary
Compacted 11 entries (2026-05-09..2026-06-04) into Compacted history per ADR 0001.

### Changes
- Replaced the 11 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per ADR 0001, not a review cycle.

### Rename
No rename.

## 2026-06-10

### Summary
Phase 2 lockstep trim: removed the redundant "additional positional args" Failure-Mode row — CANONICAL:ARGUMENT_HANDLING body (L43) already states the identical ignore-silently rule. Applied identically to all 4 doc-authoring siblings (prd/tdd/adr/ux-spec, -1 each). Net -1 (301 lines).

### Changes
- Failure Modes: deleted last table row (intra-file duplication of the CANONICAL block; byte-identical removal across the family, grep-verified 0 survivors).

### Dimensions Evaluated
Coherence (family lockstep), Over-Engineering.

### Rename
No rename.

## 2026-06-10

### Summary
Full-cycle audit: NO-OP. All cross-project pitfall signals (verified/canonical-claim discipline, coherence-grep AC under-match) confirmed already encoded against the live file — Authoring §5 (L142-148) bars contradicted-facts + scope-overreach; §11(c) (L222-227) requires run-with-hit-set-verified grep ACs. verify-ac-snippet innovation declined (sibling-boundary + no BALANCED offset).

### Changes
- None (NO-OP verdict, grep-cited against live file).

### Dimensions Evaluated
All 8; Over-Engineering HIGHEST (no trim slack without breaking format-authority determinism); Completeness (pitfall halves a/b/c all present); Coherence (CANONICAL trio + COUPLING verified across family).

### Rename
No rename.

## 2026-06-09

### Summary
Compacted 9 entries (2026-05-06..2026-05-09) into Compacted history per ADR 0001.

### Changes
- Replaced the 9 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per ADR 0001, not a review cycle.

### Rename
No rename.

## 2026-06-09

### Summary
Full-cycle audit: NO-OP verdict. allowed-tools (Glob+Grep) verified consistent with doc-authoring siblings and used in body; cross-references correct; no unescaped $-digit; description 269 chars. Stale 2026-06-04 entry (claimed Glob/Grep removal not reflected in live file or siblings) noted as historical artifact — entries immutable, live state correct.

### Changes
- None (NO-OP verdict).

### Dimensions Evaluated
All 8; Over-Engineering primary (no trim slack at 302/500); Coherence (COUPLING → 5 skills verified).

### Rename
No rename.

## 2026-06-09

### Summary
Mythos/Fable-5 cycle audit: NO changes. All 3 cross-repo historical signals verified already encoded against the LIVE file (regex-AC run-and-verify §11(c) L224-227 + §5; scope-bounded "verified" claims §5 L146-148; named-source-vs-live-artifact §5 L143-145). Reasoning-echo clean; $-escape clean; no over-prescription trims available without breaking deterministic format authority.

### Changes
- None (NO-OP verdict, grep-cited against live file per the already-present check).

### Dimensions Evaluated
All 8; Over-Engineering primary; reasoning-echo + $-escape audits clean.

### Rename
No rename.

## 2026-06-09

### Summary
Closed residual halves of the cross-project verified-claim pitfalls: Authoring §5 now bars scope-overreach on "verified" claims (scope must match what was checked, artifact named); §11(c) tightened from "executable" to run-with-hit-set-verified. Offset by removing two security Failure-Mode rows redundant with Validation §7/§8 + generic abort row. Net +0 (303/500).

### Changes
- Authoring §5: "verified" label must not claim broader scope than checked; name the artifact/command behind it.
- §11(c): grep/regex AC must be run with hit set verified, not merely "executable" (staff-engineer.md Executable-claim-gate alignment).
- Failure Modes: dropped two security rows (restate Validation §7/§8; generic row carries the abort template).

### Dimensions Evaluated
Completeness (PRIMARY — verified-claim pitfalls), Actionability, Over-Engineering (HIGHEST — net 0), Coherence (paths/when_to_use rejected/parity-bound; docket co-authoring N/A — zero docket refs since c10195b), Skill Design, Orchestration, Spec Alignment, Rename.

### Rename
No rename.

## 2026-06-08

### Summary
Doc-family parity + closure of cross-project pitfall (a) (TDD asserts a "verified" fact the committed artifact contradicts): added Authoring §5 requiring embedded technical assertions (code/config/SQL snippets, cross-platform/engine claims, Implementation-Phase grep ACs, module/API/test-infra references) to be verified against their actual target before being written as settled — mirrors adr:148 ("State unverified claims as assumptions, not facts"), which tdd lacked despite carrying more such claims. Partially offset by trimming §4 Mermaid restatement and §1 tail. Net +5 (303/500).

### Changes
- Authoring Procedure: new §5 verify-embedded-claims step (adr parity); §4 Mermaid compressed (dropped Failure-Modes ADR-routing restatement, kept Validation §5 gate); §1 tail tightened; prior §5 → §6.

### Dimensions Evaluated
Completeness (PRIMARY — pitfall (a)), Coherence (adr↔tdd authoring-step parity), Over-Engineering (HIGHEST — addition partly offset). Priority item 2 (under-matching grep AC) NO-OP — already at §11(c). Priority item 3 (concurrent-authorship) NO-OP — Sole-editor rule owned by security-engineer.md + staff-engineer.md.

### Rename
No rename.

## 2026-06-05

### Summary
Over-engineering trim: collapsed redundant Authoring Procedure steps 5/6/7 (Alternatives/Risks/Phases — restatements of Required Sections §3/§8/§11) into step 3, matching prd's leaner pattern; preserved the chosen-alternative-matches-§4 constraint. Net -6.

### Changes
- Authoring Procedure: removed steps 5/6/7 as redundant with Required Sections; folded the N/A rule + §3↔§4 coherence constraint into step 3; renumbered.

### Dimensions Evaluated
Over-Engineering (HIGHEST), Coherence (Authoring shape toward prd), Actionability. Status-authority confirmed canonical (no edit); maturity confirmed live-consumer field (no edit).

### Rename
No rename.

## 2026-06-05

### Summary
Phase 2 coherence: added a fenced-code-block carve-out to the §3 Section-order and §4 Alternatives-count validations so example headings embedded in ``` fences are not mis-counted (aligns with the §6 placeholder-scan exclusion). Applied in lockstep with adr/prd/ux-spec.

### Changes
- §3 Section order: count only `##` headings at column 0 outside ``` code fences.
- §4 Alternatives count: count only `###` headings outside ``` code fences.

### Dimensions Evaluated
Coherence (doc-authoring family validation symmetry).

### Rename
No rename.

## 2026-06-05

### Summary
Added a robustness bar for grep/regex-based per-phase acceptance criteria in §11 (Implementation Phases), tracing to a recorded incident where a brittle single-arm regex AC silently under-matched. Net +3.

### Changes
- §11 (c): grep/regex-based ACs must be executable against the named files and cover all expected matches (escape markdown, arm for word-order/formatting variants); a single-arm regex that silently under-matches is a defect.

### Dimensions Evaluated
Completeness (PRIMARY — AC robustness), Actionability, Over-Engineering (HIGHEST — single clause, no trim slack at 275/500), Coherence. The §3/§4 fenced-heading-exclusion fix is family-wide (tdd/adr/prd/ux-spec) and deferred to Phase 2 for lockstep.

### Rename
No rename.

## Compacted history

Entries below were compacted per ADR 0001; full text in git history (see the compaction entry's date).

- 2026-05-06: First entry: removed stale TDD §4.3 reference, clarified pure-policy Mermaid override location, collapsed redundant Self-check (317→311).
- 2026-05-06: Collapsed over-engineered Parent-PRD probe to one Glob-and-judge step; tightened Validation §4; removed orphaned missing-parent references (311→~285).
- 2026-05-06: Added create-* family COUPLING comment; Mermaid Mandate subsection 14→4 lines; documented maturity-vs-status orthogonal-ladder rationale.
- 2026-05-06: Renamed create-tdd → tdd per operator request; directory, frontmatter name, /tdd slash command, and cross-references updated.
- 2026-05-06: Replaced stale dev-skill reference with the team-lead orchestrator's Medium Task pattern in When to Use §3.
- 2026-05-07: Phase 2 coherence: H1 fixed from # Create TDD to # TDD to match frontmatter name.
- 2026-05-07: Dropped pure-policy Mermaid escape hatch (policy decisions route to Skill(adr)); Authoring §8 self-check collapsed to a Validation pointer (273→269).
- 2026-05-07: Removed redundant sub-agent prohibition row from Failure Modes for symmetry with ux-spec.
- 2026-05-09: Encoded security-track subsection contract (Threat Model, Trust Boundaries, Security Considerations) with Validation §7; Parent-PRD probe deterministic.
- 2026-05-09: Four handoff + actionability fixes (operator pain points 1, 3): added UX-spec input probe to mirror PRD probing, sharpened Implementation Phases §11 with the...
- 2026-05-13: Coherence/Completeness fix: tightened §4 security-gating prose to match what Validation §7 actually enforces, and surfaced the co-author handoff path for mix...
- 2026-05-16: Three coherence/over-engineering fixes: clarified §4 security-track prose to name the Threat-Model Annotation mechanism (append via Edit to the saved TDD, no...
- 2026-05-18: Three trim-class fixes: collapsed §4 security-track prose bloat that duplicated agents/security-engineer.md Threat-Model Annotation mechanics (skill keeps th...
- 2026-05-20: Added non-blocking near-duplicate-slug probe to Pre-flight (closes gap surfaced by sessions dd8cea9d/962bb9d0 where near-identical args derived to different...
- 2026-05-25: Phase 2 coherence: removed TYPE substitution note (lockstep with prd/adr/ux-spec) and removed stale "(currently 11 sections)" hardcoded count from Validation...
- 2026-05-25: No-change verdict. Skill is mature — 186 sessions in 7d with zero operator corrections, 288 LOC under 500 cap, four trim-class entries in last 30 days alread...
- 2026-05-28: No-change verdict. Flagged top item (slug determinism for mixed clean-slug/freeform args) is already resolved by the deterministic 8-step ARGUMENT_HANDLING d...
- 2026-05-29: Corrected the same factually-incorrect `allowed-tools`-excludes-Edit rationale found in prd/ux-spec (per Claude Code docs, allowed-tools does not restrict th...
- 2026-05-30: Added the reciprocal PRD-vs-TDD routing boundary to "When to Use" so the tdd↔prd split is symmetric — prd already states "pick PRD when scope precedes archit...
- 2026-06-04: Dropped vestigial `Glob`/`Grep` from `allowed-tools`; added a status-authority rule clarifying Docket's `.data.status` is the single source of truth for the...
