# Changelog: tdd

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

## 2026-06-19

### Summary
Strengthened the §9 untested-claims inventory into an actionable anti-fabrication callout, offset by compressing redundant §11 grep/regex prose; added downstream verbatim-citation + explicit Skill(verify-ac) envelope reminders.

### Changes
- AMPLIFY §9: inventory now enumerates forward-looking/unreachable no-trigger branches and prescribes extract-pure-fn-and-unit-test remediation when an AC demands a positive test for an unreachable path (3 convergent cross-project pitfalls).
- CULL §11: triplicated grep/regex-AC prose collapsed to a §9 + staff-engineer rule-6 pointer (core requirement kept inline).
- AMPLIFY Save & Return: downstream must cite this TDD verbatim; prescribed Skill(verify-ac) is an explicit invocation.
- Drift (rate 7): D2, D5 APPLY (neutral rewords); D0/D1/D3/D4/D6 SKIP (slug/CANONICAL/format parity).

### Dimensions Evaluated
Over-Engineering, Completeness, Non-redundancy, Coherence, Spec Alignment, Rename.

### Rename
No rename.

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
