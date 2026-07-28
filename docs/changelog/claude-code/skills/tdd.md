# Changelog: tdd

## 2026-07-27 (Phase 4 history compaction)

### Summary
Compacted 3 entries (2026-07-12..2026-07-13) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 3 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-27

### Summary
Phase 3 disambiguation pinned the referent of `updated_by` on a co-authored TDD, closing a silent skip of the security-track validator checks.

### Changes
- DISAMBIG (multi-reading): the `updated_by` field rule now names the document's TRACK owner rather than "whoever edited last" on a co-authored TDD, citing `doc_validate.py`'s exact-equality trigger on `@security-engineer` — the body author's identifier left in place silently no-ops the §4 Threat Model / Trust Boundaries / Security Considerations and §9 Abuse Cases checks.

### Dimensions Evaluated
Disambiguation: multi-reading (applied), confusable-name, overlapping-ownership.

### Rename
No rename.

## 2026-07-27

### Summary
Closed a live author-routing collision: the file named @distinguished-engineer as the default TDD author with no security carve-out, while distinguished-engineer.md categorically bars that seat from security-sensitive work and doc_validate.py gates security-track checks on updated_by: "@security-engineer". Also corrected one misdirected section cross-reference and trimmed three unactionable asides. Findings: 4 sub / 2 cos / 0 rej / 0 def. Net +27 bytes (24,226 / 65,000).

### Changes
- COHERENCE[SUBSTANTIVE][S6]: contract line — added the security carve-out (@security-engineer authors a security-dominated TDD; @distinguished-engineer barred per §Security Exclusion) and named updated_by as the validator's security-track selector.
- COHERENCE[SUBSTANTIVE][S6]: When-to-Use bullet — collapsed the duplicated author attribution to a pointer, removing the second drift carrier.
- COHERENCE[SUBSTANTIVE][S6]: Required Sections §4 — dropped the mixed-scope parenthetical carrying the stale @staff-engineer attribution and a duplicate authority pointer.
- XREF[SUBSTANTIVE]: §11(c) — AC-evidence rule re-cited from §9 (which contains no such rule) to Authoring §5, making the §5↔§11 reference bidirectional.
- TRIM[COSMETIC]: removed the sibling-PRD parity aside (Authoring §6) and the next_doc_number.sh descriptive clause (Pre-flight §2).
- Deferred (Docket tracking): slug.sh truncation bug (H9/H13, 4-skill blast radius), next_doc_number.sh unbounded grep (H13); Phase-2 lockstep: mv-instead-of-second-Write SAVE_AND_RETURN proposal (I10).

### Dimensions Evaluated
All 8. Findings in Coherence/cross-reference accuracy (S6 + the §9 misdirection) and Redundancy/over-engineering (3 trims). No findings in Argument Handling, Failure Modes, Validation, or Output Contract structure.

### Rename
No rename.

## 2026-07-27 (Phase 4 history compaction)

### Summary
Compacted 2 entries (2026-07-12..2026-07-12) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 2 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-27 (Phase 4 history compaction)

### Summary
Compacted 3 entries (2026-07-10..2026-07-10) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 3 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-27

### Summary
Phase 3 disambiguation pass: corrected the authoring default at both sites. The file named `@staff-engineer` as the typical author with `@distinguished-engineer` as the Medium+ variant, which is the inverse of live routing — and the sub-Medium case it implied staff covers produces no TDD at all.

### Changes
- DISAMBIG[SUBSTANTIVE][overlapping-ownership]: contract line — `@distinguished-engineer` named the default (TDDs are Medium+/TDD-bearing-only; that seat is gold on every such cycle), `@staff-engineer` scoped to gold-unavailable fallback and standalone use.
- DISAMBIG[SUBSTANTIVE][overlapping-ownership]: When-to-Use bullet — same substitution, applied in lockstep so the file does not name two different defaults 43 lines apart.

### Dimensions Evaluated
Phase 3 two-arm boundary test. Arm 1 PASSES by explicit carve-out — soft "typically @X" doc skills are advisory, plausibility-only. Arm 2 FAILS against team-lead.md's gold-tier design-artifact-authoring bullet and its explicit "Small: no TDD" rule, plus staff-engineer.md's own "gold-unavailable fallback" framing. adr/SKILL.md's parallel line is CORRECT as-is (ADR authoring inherits the active seat's tier) — deliberately excluded from this fix.

### Rename
No rename.

## 2026-07-27

### Summary
Aligned the contract line with the file's own When-to-Use line on TDD-authoring seats, and closed the claim-laundering point-of-use gap in the §5 verification arms. I5 falsified by live reproduction (g5_check.sh cannot scope to a staged draft) and routed to Docket. Findings: 3 → 2 sub / 1 cos / 1 rej / 2 def / 0 enc.

### Changes
- COHERENCE[SUBSTANTIVE]: contract line names `@distinguished-engineer` on Medium+ cycles (OP-S2; ground truth team-lead.md:241,258,289 + distinguished-engineer.md:127-133).
- AMPLIFY[SUBSTANTIVE]: §5 module/API arm extended — existence is not coverage; Read a named test's assertion body before citing it as coverage (historical-auditor: pattern recurs across 6 roles' pitfalls despite the upstream gate landing 2026-07-11).
- TRIM[COSMETIC]: Authoring §6 stops restating the Validation checklist it points at (its copy had already drifted).
- REJECTED: I5 — `g5_check.sh <staged-draft>` exits 128 (path outside repo) and its extractor reads a git diff, so an untracked draft yields no candidates. Blocked on a script content-mode; deferred to Docket with I6.

### Dimensions Evaluated
All 8. Coherence and Completeness carried the cycle. Over-Engineering: one defensible trim only — post-apply 24,017/65,000; the 2026-07-10 no-trim-slack finding still holds. Model routing unchanged (`effort: xhigh`; n=1 in-window, zero adverse signal).

### Rename
No rename.

## 2026-07-24

### Summary
Compacted 4 entries (2026-06-20..2026-06-30) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 4 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-24

### Summary
Own shape adopted as the family reference; gains the one clause it was missing (missing-validator exit-2); token {tmpdir} → {staging_dir} (steps 1-2 + tdd_preflight line); {output_dir} bound explicitly in Pre-flight.

### Changes
- AMPLIFY[SUBSTANTIVE]: missing-validator clause added to step 2 (true union — present in the other 3 carriers).
- REFACTOR[COSMETIC]: token rename, 3 occurrences.
- COHERENCE: Pre-flight step 2 binds {output_dir}.

### Dimensions Evaluated
Coherence. Phase 2 pass.

### Rename
No rename.

## 2026-07-24

### Summary
Fixed the family-wide $TMPDIR staging bug, bare-executable validator invocation, and numbered-heading trap; live-reproduced a Mermaid prose/validator mismatch that failed the skill's own mandatory gate; repaired three drifted numbered cross-references. Findings: 6 → 5 sub / 0 cos / 1 rej / 0 def / 0 enc

### Changes
- AMPLIFY[SUBSTANTIVE]: Validation §1-2/§4 resolve {tmpdir} once and invoke the validator via python3 (X1/X2, reproduced: 126 bare vs 0 under python3).
- AMPLIFY[SUBSTANTIVE]: Required Sections headings carry title ONLY (X3, reproduced; validator untouched).
- FIX[SUBSTANTIVE]: Mermaid gate now states the first-line keyword rule (reproduced both directions); fixed 2 dangling + 1 off-by-one numbered cross-refs.
- AMPLIFY[SUBSTANTIVE]: Authoring §5 gains an Enumerated-set completeness arm (H-tdd-2); ACs must quote source text verbatim (H-tdd-3).
- CULL[COSMETIC]: truncated status-lifecycle restatement → pointer.
- REJECTED: H-tdd-1 — pre-fix observation, remedy contradicts the validator's section-order contract.

### Dimensions Evaluated
Actionability, completeness, coherence, over-engineering.

### Rename
No rename.

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
- 2026-06-20: Encoded two recurring cross-project TDD pitfalls; net +3 (319→322). CANONICAL blocks deferred to Phase 2.
- 2026-06-30: Phase-2 family-wide: strengthened Validation §5 from mermaid presence-only to "presence & shape" (renderer-free diagram-type-keyword check). Applied byte-ide...
- 2026-06-30: Phase-3 follow-on: widened the §5 mermaid diagram-type allow-list to non-exhaustive. Inline, net 0.
- 2026-06-30: AMPLIFY sparse-repo prior-art discovery; net 0; no model-routing/frontmatter changes.
- 2026-07-10: Compacted 3 entries (2026-06-05..2026-06-05) into Compacted history per the retention-compaction policy.
- 2026-07-10: Fixed the broken COLLISION_DIALOG "Overwrite" branch — Wrote over an existing file without a prior Read; applied byte-identically across adr/prd/tdd/ux-spec.
- 2026-07-10: Full-cycle audit: NO-OP. Zero error/correction signals in window (19 clean invocations). §11-YAML AMPLIFY rejected; validate_doc.py deferred to Phase-2.
- 2026-07-12: Phase 3 disambiguation — trigger phrase collision with ux-spec fixed: "write the design for {feature}" → "write the technical design for {feature}".
- 2026-07-12: Added meta-TDD caveat to Validation §6 placeholder scan and a Path-citations bullet to Authoring §5 adopting tdd_preflight.sh with a migration/relocation caveat.
- 2026-07-12: Compacted 3 entries (2026-06-08..2026-06-09) into Compacted history per the retention-compaction policy.
- 2026-07-13: Phase 2 coherence — relocated TDD-specific insert below CANONICAL:SAVE_AND_RETURN END marker; block now byte-identical across 4 doc skills.
- 2026-07-13: Compacted 2 entries (2026-06-09..2026-06-09) into Compacted history per the retention-compaction policy.
