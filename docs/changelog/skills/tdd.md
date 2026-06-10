# Changelog: tdd

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

## 2026-06-04

### Summary
Dropped vestigial `Glob`/`Grep` from `allowed-tools`; added a status-authority rule clarifying Docket's `.data.status` is the single source of truth for the verify-ac gate (the body `status` field may drift stale).

### Changes
- `allowed-tools` trimmed to `["AskUserQuestion", "Bash", "Read", "Write"]` (dropped `Glob`, `Grep`) — family lockstep with adr/prd/ux-spec.
- Field rules: replaced "body `status` mirrors Docket's doc-level status" with an authority rule — Docket `.data.status` gates downstream verify-ac (ABORTs on non-`approved`); the body `status:` is documentation-only, not auto-synced by `docket doc edit -s`, so may drift stale.

### Dimensions Evaluated
Skill Design Quality, Coherence (consistency with the applied verify-ac status-gate fix), Completeness.

### Rename
No rename.

## 2026-05-30

### Summary
Added the reciprocal PRD-vs-TDD routing boundary to "When to Use" so the tdd↔prd split is symmetric — prd already states "pick PRD when scope precedes architecture"; tdd now states the inverse. Net +2.

### Changes
- "When to Use" bullet 1: appended a one-line PRD/TDD boundary ("pick TDD when *how* is the question — what/why settled") mirroring prd line 52. Verified prd's "scope precedes architecture" phrasing exists before referencing it.

### Dimensions Evaluated
Coherence (tdd↔prd boundary symmetry; tdd↔adr split verified sound), Over-Engineering (HIGHEST — +2, no trimmable slack at 288/500), Skill Design, Actionability, Completeness, Orchestration, Spec Alignment, Rename.

### Rename
No rename.

## 2026-05-29

### Summary
Corrected the same factually-incorrect `allowed-tools`-excludes-Edit rationale found in prd/ux-spec (per Claude Code docs, allowed-tools does not restrict the tool pool). Reframed the no-fix-and-retry abort as the intended single-pass validate-then-write design. Slug-batching contract reviewed — sound, no change.

### Changes
- Validation Before Save: replaced "`Edit` is excluded from this skill's tools" / "it has its own tools" with a design-intent rationale (validate-then-write once; caller owns repair). Fixed in lockstep with prd/ux-spec.

### Dimensions Evaluated
Skill Design Quality (factual accuracy), Completeness (slug disambiguation when batching multiple TDDs/session — verified robust), Over-Engineering (no trim), Orchestration (leaf), Coherence (doc-authoring family), Actionability, Spec Alignment, Rename.

### Rename
No rename — tdd is the established, family-consistent name.

## 2026-05-28

### Summary
No-change verdict. Flagged top item (slug determinism for mixed clean-slug/freeform args) is already resolved by the deterministic 8-step ARGUMENT_HANDLING derivation (canonical, family-shared) plus collision dialog and near-duplicate probe — freeform topics slugify deterministically by construction; no bug. argument-hint `<topic>` kept for 4-sibling parity. Zero docket/vote CLI to drift. 286 lines, ~43% under cap; Over-Engineering found no slack.

### Changes
- None.

### Dimensions Evaluated
Skill Design Quality (argument handling — top item), Over-Engineering (HIGHEST), Orchestration/handoff, Coherence (adr/prd/ux-spec parity), Vote handoff, Actionability, Completeness, Spec Alignment, Rename.

### Rename
No rename. `tdd` is the established, family-consistent name.

## 2026-05-25

### Summary
Phase 2 coherence: removed TYPE substitution note (lockstep with prd/adr/ux-spec) and removed stale "(currently 11 sections)" hardcoded count from Validation §3.

### Changes
- Removed `For this skill, substitute {TYPE} with tdd in the usage error.` — Item 1 lockstep.
- Removed stale section-count token from Validation §3 (mirrors prd's Phase 1 fix; Required Sections list is source of truth).

### Dimensions Evaluated
Coherence, Consolidation.

### Rename
No rename.

## 2026-05-25

### Summary
No-change verdict. Skill is mature — 186 sessions in 7d with zero operator corrections, 288 LOC under 500 cap, four trim-class entries in last 30 days already addressed coherence/over-engineering. Three historical-audit focus areas (stale-token verification, per-row arithmetic, missing-directory preamble) surfaced @staff-engineer/team-lead pitfalls but are NOT TDD-skill-content gaps — wrong layer (review/verification skills or team-lead spot-check own those defects).

### Changes
- None.

### Dimensions Evaluated
Over-Engineering (HIGHEST — no remaining slack), Skill Design Quality, Actionability, Completeness, Orchestration, Coherence (sibling parity), Spec Alignment, Rename.

### Rename
No rename. Family-aligned with prd/adr/ux-spec/specs.

## 2026-05-20

### Summary
Added non-blocking near-duplicate-slug probe to Pre-flight (closes gap surfaced by sessions dd8cea9d/962bb9d0 where near-identical args derived to different slugs and silently produced adjacent docs/tdd/ files — exact-match collision dialog can't catch this). Collapsed Authoring §4 Mermaid restatement now that Validation §5 + Failure Modes carry the gate. Renumbered Related-doc probe (was §5, now §6). Net +1 line.

### Changes
- Pre-flight: added §5 near-duplicate probe (advisory `Glob docs/tdd/{slug[:12]}*.md`, non-blocking note to calling agent).
- Pre-flight: renumbered existing §5 "Related-doc probe" → §6; Authoring §1 cross-reference "Pre-flight step 5" → "step 6".
- Authoring §4 Mermaid clause: trimmed restatement of Validation §5 + ADR routing (load-bearing gates live elsewhere).

### Dimensions Evaluated
Completeness (HIGHEST — near-duplicate slug gap from historical audit), Over-Engineering.

### Rename
No rename.

## 2026-05-18

### Summary
Three trim-class fixes: collapsed §4 security-track prose bloat that duplicated agents/security-engineer.md Threat-Model Annotation mechanics (skill keeps the validation contract; agent owns routing), condensed the maturity/status orthogonality rationale to its load-bearing fact, and removed the defect-restatement in Authoring §3 now that Validation §3 is the gate. Net -19.

### Changes
- Required Sections §4: trimmed 14-line security-track paragraph to the validation rule the skill enforces; routing of mixed-scope Threat-Model Annotation deferred to `agents/security-engineer.md`.
- Field rules §`maturity`: condensed 5-line ladder-rationale paragraph to the orthogonality fact.
- Authoring §3: removed defect-restatement now redundant with Validation §3; forward-pointer retained.

### Dimensions Evaluated
Over-Engineering (HIGHEST), Coherence (security-engineer.md routing ownership), Skill Design Quality.

### Rename
No rename.

## 2026-05-16

### Summary
Three coherence/over-engineering fixes: clarified §4 security-track prose to name the Threat-Model Annotation mechanism (append via Edit to the saved TDD, not re-invoke this skill); added defer-down clause to "When NOT to Use" so TDDs touching user-facing surfaces reference the UX spec rather than inline interaction design; removed the vestigial one-line "Mermaid Mandate" subsection.

### Changes
- Required Sections §4: replaced ambiguous "co-author" prose with explicit Threat-Model Annotation mechanism — @security-engineer appends sections via Edit, not by re-invoking this skill (which would hit the collision dialog).
- When NOT to Use (ux-spec route): added clause directing TDDs that touch user-facing surfaces to reference, not restate, the UX spec.
- Removed standalone "### Mermaid Mandate" subsection — vestigial restatement; rule lives in Authoring §4, Validation §5, and Failure Modes.

### Dimensions Evaluated
Coherence (security-engineer.md Threat-Model Annotation; ux-spec defer-down), Over-Engineering (Mermaid restatement collapse), Skill Design Quality.

### Rename
No rename. Family-aligned with prd/adr/ux-spec.

## 2026-05-13

### Summary
Coherence/Completeness fix: tightened §4 security-gating prose to match what Validation §7 actually enforces, and surfaced the co-author handoff path for mixed @staff-engineer/@security-engineer TDDs per security-engineer.md Responsibility 1. The prior prose mandated three subsections for any auth/secrets/sandbox-touching design, but Validation only checked `updated_by == @security-engineer`, creating an unenforced "should".

### Changes
- Required Sections §4: narrowed the prose mandate to `updated_by: @security-engineer` (matches Validation §7) and added explicit pointer to the team-lead co-author handoff in `agents/security-engineer.md` for mixed-scope TDDs.

### Dimensions Evaluated
Coherence (security-engineer.md co-author model; own Validation §7/§8), Completeness, Skill Design Quality, Orchestration.

### Rename
No rename.

## 2026-05-09

### Summary
Four handoff + actionability fixes (operator pain points 1, 3): added UX-spec input probe to mirror PRD probing, sharpened Implementation Phases §11 with the 6 PM-decomposable fields, encoded the security-track Abuse Cases contract in Testing Strategy §9 (mirrors security-engineer.md:142), and trimmed Authoring §3 redundancy with Validation §3.

### Changes
- Pre-flight §5: renamed "Parent-PRD probe" to "Related-doc probe" and extended Glob to `docs/spec/*.md docs/ux/*.md` so TDDs touching user-facing surfaces consume existing UX specs as input dependencies (closes asymmetry with prd's Authoring §1).
- Authoring §1: now reads candidate parent PRD OR UX spec from Pre-flight step 5.
- Required Sections §11 (Implementation Phases): expanded to specify the 6 fields the planner consumes directly (goal, file scope, acceptance, effort estimate, blocking dependencies, out-of-scope flags). Phases must be independently shippable or explicitly chained.
- Required Sections §9 (Testing Strategy): added security-track Abuse Cases subsection contract gated on `updated_by: @security-engineer` (mirrors security-engineer.md:142 mandate).
- Validation Before Save §8: enforces Abuse Cases subsection for security TDDs.
- Failure Modes table: new row for the Abuse Cases validation failure.
- Authoring §3: trimmed redundancy with Validation §3 ("Every section listed MUST appear, in the order shown" was duplicated); kept the "may be N/A" guidance and added a forward-pointer to Validation §3 as the enforcement gate.

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration (leaf — verified no sub-agent surface), Coherence (sibling prd / adr / ux-spec; security-engineer.md, ux-designer.md), Spec Alignment, Rename.

### Rename
No rename. Family-aligned with prd/adr/ux-spec.

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
