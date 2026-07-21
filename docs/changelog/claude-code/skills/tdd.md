# Changelog: tdd

## 2026-07-20 (Phase 4 history compaction)

### Summary
Compacted 2 entries (2026-06-17..2026-06-19) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 2 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-20

### Summary
Coherence pass: one sibling-relative citation expanded to a repo-root path.

### Changes
- `adr/SKILL.md` reference in Pre-flight step 2 expanded to `src/user/claude-code/skills/adr/SKILL.md` (fails repo-root citation resolution; fleet convention is full paths)

### Dimensions Evaluated
Reference accuracy.

### Rename
No rename.

## 2026-07-20

### Summary
Retired the "single-writer baton" co-author framing (contradicted the file-global modified-since-read doctrine), added Non-Goals to Problem Statement §1 as the validator-safe interim form, and consolidated a duplicated ephemerality statement. L21 (OBSERVED/INFERRED marking) verified already-encoded. Findings: 3 → 2 sub / 1 cos / 0 rej / 0 def / 1 enc

### Changes
- FIX[SUBSTANTIVE]: Authoring §3 hazard note rewritten — drop the "edit token"/baton metaphor; state the file-global modified-since-read gate is the real primitive, add on-error re-Read+diff (no blind-retry), cite security-engineer.md §Responsibility 1 as the sole-editor authority (L34; contradicts distinguished-engineer.md's co-author serialization doctrine)
- FIX[SUBSTANTIVE]: Required Sections §1 now names non-goals (explicit out-of-scope) with an anti-advocacy clause — validator forbids a top-level `## Non-Goals` (doc_validate.py exact-match), so implemented as the DE-prescribed interim Problem-Statement form (L33)
- REDUCE[COSMETIC]: Save & Return ephemerality sentence replaced with an in-file pointer to the `status` frontmatter rule (deduped verbatim fact + citation)

### Dimensions Evaluated
Cross-file coherence; completeness/anti-advocacy; redundancy/size budget; validator-coupling correctness.

### Rename
No rename.

## 2026-07-14 (Phase 4 history compaction)

### Summary
Compacted 4 entries (2026-06-10..2026-06-10) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 4 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-14

### Summary
Phase 3 disambiguation: made the insertion-anchor authoring check's grep procedure single-reading.

### Changes
- Rewrote "`Grep` it for `CANONICAL:` / mirrored-block membership" as an explicit BEGIN/END-membership test on the target file — the literal reading (grep the anchor line itself) false-passes any anchor sitting mid-block, defeating the parity guard (multi-reading).

### Dimensions Evaluated
Confusable names/triggers/terms; multi-reading wording; overlapping ownership.

### Rename
No rename.

## 2026-07-14

### Summary
Added an author-side pre-Write citation gate (tdd_preflight.sh now also runs on the staged draft, not just panel-side post-Write), OBSERVED/INFERRED labeling for load-bearing claims, an insertion-anchor CANONICAL-block check, and tolerance-band ACs for measured/rendered values. Findings: 5 → 4 sub / 0 cos / 0 rej / 1 def / 0 enc

### Changes
- AMPLIFY[SUBSTANTIVE]: Validation Before Save now runs `tdd_preflight.sh` author-side on the staged draft (was panel-side post-Write only), converting broken-citation rejections into pre-Write repairs; Authoring §5 Path-citations bullet shortened to point at it (I29)
- AMPLIFY[SUBSTANTIVE]: load-bearing claims must be labeled OBSERVED or INFERRED; a claim feeding a Risk row or phase AC MUST be OBSERVED (H21)
- AMPLIFY[SUBSTANTIVE]: new Insertion-anchor check arm — verify an anchor line is not inside a CANONICAL:*-LOCAL synced block before citing it (H22)
- AMPLIFY[SUBSTANTIVE]: §11(c) ACs — MEASURED/RENDERED values now use tolerance bands, not exact-match; deterministic grep/regex counts stay exact (H23)

### Dimensions Evaluated
Completeness/Actionability (primary), Coherence (insertion-anchor + citation-gate consistency with staff-engineer.md). Deferred: I30 (doc-family CANONICAL manifest rows), PARITY-BOUND with adr/prd/ux-spec/init-specs.

### Rename
No rename.

## 2026-07-13 (Phase 4 history compaction)

### Summary
Compacted 2 entries (2026-06-09..2026-06-09) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 2 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-13 (Phase 2 coherence pass, evolve-skills cycle)

### Summary
Phase 2 coherence: relocated the 7-line TDD-specific insert (planning-consumer provenance, ephemerality, explicit Skill(verify-ac) note) from inside CANONICAL:SAVE_AND_RETURN to immediately below its END marker — content verbatim-preserved, block restored to byte-parity with adr/prd/ux-spec.

### Changes
- SAVE_AND_RETURN block now hashes identical across the 4 doc skills, matching evolve-coherence D4's "byte-identical within each set" invariant and enabling future manifest registration.

### Dimensions Evaluated
Coherence (CANONICAL parity).

### Rename
No rename.

## 2026-07-12 (Phase 4 history compaction)

### Summary
Compacted 3 entries (2026-06-08..2026-06-09) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 3 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-12 (Phase 3 disambiguation pass)

### Summary
Trigger phrase made disjoint from ux-spec's design-spec triggers. Findings: 1 → 1 sub / 0 cos / 0 rej / 0 def / 0 enc

### Changes
- AMPLIFY[SUBSTANTIVE]: trigger "write the design for {feature}" → "write the technical design for {feature}" — the old phrase co-fired with ux-spec's "design spec for the new CLI"/"produce a design spec" on user-facing features; a routing classifier could not pick a single owner

### Dimensions Evaluated
Disambiguation (confusable-name).

### Rename
No rename.

## 2026-07-12

### Summary
Added a meta-TDD caveat to Validation §6's placeholder scan (docs documenting a doc-authoring skill need fenced/angle-bracket path templates, not inline-backtick literals) and a Path-citations bullet to Authoring §5, adopting `tdd_preflight.sh` (verified exists) with a migration/relocation caveat so target-state citations aren't flat-failed. Findings: 2 → 2 sub / 0 cos / 0 rej / 1 def / 0 enc

### Changes
- AMPLIFY[SUBSTANTIVE]: Validation §6 placeholder scan — added a meta-TDD caveat (fenced blocks or `<slug>`/`<NNNN>-<slug>` phrasing for docs about doc-authoring skills; inline `{slug}` literals still trip the scan)
- AMPLIFY[SUBSTANTIVE]: Authoring §5 — added a Path-citations bullet: verify inline-backtick citations resolve while drafting; the acceptance panel mechanizes this post-Write via `tdd_preflight.sh`, with a migration/relocation caveat (target-state paths report MISSING against the current tree — classify before treating as failure)

### Dimensions Evaluated
Actionability/Completeness (primary — both target documented recurring pitfalls). Deferred: `doc_validate.py`/`slug.sh` cross-skill extraction (anchored at adr, shared with prd/ux-spec). Follow-up flagged (script-logic, out of prose scope): `check_citations.py`/`tdd_preflight.sh` should classify MISSING-citation causes rather than flat-fail migration TDDs — the SKILL.md caveat is the prose mitigation, not the root-cause fix.

### Rename
No rename.

## 2026-07-10

### Summary
Compacted 3 entries (2026-06-05..2026-06-05) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 3 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

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
Full-cycle audit: NO-OP. Zero error/correction signals in window (19 clean invocations). §11-YAML AMPLIFY rejected: goal already served by existing stand-alone-distillation clause. validate_doc.py deferred to Phase-2 family-wide reconciliation.

### Changes
- None.

### Dimensions Evaluated
All 8. Over-Engineering HIGHEST — no trim slack without breaking format-authority determinism.

### Rename
No rename.

## 2026-06-30

### Summary
AMPLIFY sparse-repo prior-art discovery; net 0; no model-routing/frontmatter changes.

### Changes
- AMPLIFY: build prior-art search roots only from existing docs directories.

### Dimensions Evaluated
All 8.

### Rename
No rename.

## 2026-06-30

### Summary
Phase-3 follow-on: widened the §5 mermaid diagram-type allow-list to non-exhaustive. Inline, net 0.

### Changes
- AMPLIFY: §5's keyword list is now `e.g.`-prefixed (non-exhaustive) and adds `journey`, `classDiagram`, `gantt` — the Phase-2 4-keyword list would have rejected valid diagram types (prd's Mandate invites a `journey` diagram). Applied byte-identically across tdd/prd/ux-spec §5. Phase-3 remaining-issue catch.

### Dimensions Evaluated
All 8. Over-Engineering: inline, net 0. Correctness: closed a self-introduced validation gap. No model/routing/drift change.

### Rename
No rename.

## 2026-06-30

### Summary
Phase-2 family-wide: strengthened Validation §5 from mermaid presence-only to "presence & shape" (renderer-free diagram-type-keyword check). Applied byte-identically across tdd/prd/ux-spec §5 in lockstep. Phase 1 was RETAIN (cited fenced-code section-order fix already encoded).

### Changes
- AMPLIFY: §5 now requires the mermaid block's first non-blank line to declare a diagram-type keyword (graph/flowchart, sequenceDiagram, stateDiagram, erDiagram) — catches the empty/typeless block that renders broken but passed presence-only. Renderer-free (no mermaid CLI in-repo, verified). Cited INNOVATION. Satellites (§5-by-number refs) need no edit.
- NO-OP (verified already-encoded): the cross-project fenced-code section-order exclusion is already present (§3/§4/§6 "outside code fences").

### Dimensions Evaluated
All 8. Over-Engineering: +5 lines, justified (closes a real malformed-block gap), renderer-free. No model/routing/drift change.

### Rename
No rename.

## 2026-06-20

### Summary
Encoded two recurring cross-project TDD pitfalls; net +3 (319→322). CANONICAL blocks deferred to Phase 2.

### Changes
- AMPLIFY: added a §5 "Concrete value" assertion-check arm — Grep the committed artifact that owns an asserted value (tag/count/path/flag/version) and confirm match. Cited Phase-0 canonical-fact-drift pitfall (`:latest` vs `:v1`; "8 diagrams" when 5 exist).
- AMPLIFY: §11(c) grep/regex ACs must now embed the exact command + expected hit count inline as evidence. Cited Phase-0 regex-AC-brittleness pitfall (fixed-word-order regex never run before completion).

### Dimensions Evaluated
Skill Design, Actionability, Completeness, Over-Engineering, Orchestration, Coherence, Spec Alignment, Rename.

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
- 2026-06-05: Over-engineering trim collapsing redundant Authoring Procedure steps 5/6/7 into step 3, matching prd's leaner pattern; net -6.
- 2026-06-05: Added fenced-code-block carve-out to §3 Section-order and §4 Alternatives-count validations, lockstep with adr/prd/ux-spec.
- 2026-06-05: Added robustness bar for grep/regex-based §11 acceptance criteria (must be executable, cover all matches); net +3.
- 2026-06-08: Added Authoring §5 verify-embedded-claims step (adr parity); trimmed §4 Mermaid restatement + §1 tail; net +5 (303/500).
- 2026-06-09: Closed cross-project verified-claim pitfalls in Authoring §5 + §11(c); trimmed 2 redundant security Failure-Mode rows; net +0 (303/500).
- 2026-06-09: Mythos/Fable-5 cycle audit — NO-OP; 3 cross-repo signals already encoded (regex-AC, scope-bounded verified claims, named-source-vs-live-artifact).
- 2026-06-09: Full-cycle audit NO-OP — allowed-tools/cross-refs/description verified consistent with siblings; stale 2026-06-04 entry noted as historical artifact (entries immutable).
- 2026-06-09: Compacted 9 entries (2026-05-06..2026-05-09) into Compacted history per ADR 0001.
- 2026-06-10: Full-cycle audit NO-OP — verified/canonical-claim discipline and coherence-grep AC signals already encoded; verify-ac-snippet declined.
- 2026-06-10: Phase 2 lockstep trim — removed redundant "additional positional args" row (dup of CANONICAL:ARGUMENT_HANDLING); family-wide, net -1.
- 2026-06-10: Compacted 11 entries (2026-05-09..2026-06-04) into Compacted history per ADR 0001.
- 2026-06-10: Closed staff pitfall — Authoring §5 requires quantitative/line-budget feasibility claims be measured (wc -l), never estimated; net +1.
- 2026-06-17: Added co-author single-writer baton note, verify-checklist restructure, COLLISION_DIALOG teammate-context caveat (lockstep). Trial: baton / verify-checklist / inert-caveat → adopted.
- 2026-06-19: Strengthened §9 untested-claims inventory into anti-fabrication callout; compressed §11 grep/regex prose; added verbatim-citation + Skill(verify-ac) reminders. Drift (rate 7): D2, D5 APPLY (neutral rewords); D0/D1/D3/D4/D6 SKIP (slug/CANONICAL/format parity).
