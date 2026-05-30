# Changelog: prd

## 2026-05-29

### Summary
Corrected a factually-incorrect frontmatter rationale: `allowed-tools` does NOT remove `Edit` from the skill's tool pool (per Claude Code docs, every tool stays callable). Reframed the no-fix-and-retry abort as the intended single-pass validate-then-write design.

### Changes
- Validation Before Save: replaced "`Edit` is excluded from this skill's tools" and "it has its own tools" with a design-intent rationale (validate-then-write once; the calling agent owns repair). Verified against code.claude.com/docs/en/skills.

### Dimensions Evaluated
Skill Design Quality (factual accuracy), Actionability, Over-Engineering (no trim warranted), Orchestration (leaf), Coherence (shared wrong string with tdd/ux-spec — fixed in lockstep), Spec Alignment, Completeness, Rename.

### Rename
No rename — prd consistent with the doc-authoring family (tdd/adr/ux-spec/specs).

## 2026-05-28

### Summary
One coordination fix (net 0): linked Authoring §1 prior-art discovery to the `dependencies` frontmatter field so downstream reviewers/decomposition can trace PRD lineage; offset by removing the redundant 3rd inline restatement of the 7 reserved names (now points to the Reserved-Name List).

### Changes
- Authoring Procedure §1: instruct recording each prior-art doc the PRD builds on in the `dependencies` frontmatter field; replaced inline 7-name enumeration with a pointer to the Reserved-Name List. CANONICAL:SAVE_AND_RETURN left untouched (verified byte-identical across prd/tdd/adr).

### Dimensions Evaluated
Orchestration & Coordination (primary — handoff traceability), Over-Engineering (offset — Non-redundant Gate), Coherence (SAVE_AND_RETURN parity verified), Spec Alignment, Skill Design Quality, Actionability, Completeness, Rename.

### Rename
No rename.

## 2026-05-25

### Summary
Phase 2 coherence: removed redundant TYPE substitution note (canonical ARGUMENT_HANDLING block's placeholder is self-explanatory).

### Changes
- Removed `For this skill, substitute {TYPE} with prd in the usage error.` — Item 1 lockstep across 5-skill COUPLING family (prd/tdd/adr/ux-spec).

### Dimensions Evaluated
Coherence (cross-skill meta-instruction redundancy).

### Rename
No rename.

## 2026-05-25

### Summary
Six edits: broadened trigger phrases to catch informal asks ("write up requirements for", "scope this feature") addressing zero-invocation signal, plus five over-engineering trims (Mermaid Mandate cross-ref triple-restatement, Authoring §5 Mermaid step duplication, Pre-flight §5 reserved-name verbosity, Validation §4 "currently 7 sections" editorial, Authoring §2 Docket probe verbosity). Net -10 lines.

### Changes
- Description: added "write up requirements for" and "scope this feature" trigger phrases for informal operator language.
- Mermaid Mandate: collapsed to single sentence + Validation pointer (was triple-restating the rule).
- Authoring §5: reduced to one-line pointer to Mermaid Mandate subsection.
- Pre-flight §5 reserved-name refusal: collapsed to single sentence.
- Validation §4: removed "(currently 7 sections). Off-by-one..." editorial.
- Authoring §2 Docket probe: condensed verbose multi-line instruction.

### Dimensions Evaluated
Over-Engineering (HIGHEST — 5 trims), Skill Design Quality (trigger broadening from historical signal).

### Rename
No rename.

## 2026-05-18

### Summary
One completeness fix: added Failure Mode row for invalid `maturity` value (proof-of-concept | draft | experimental | stable). Validation §3 enumerated the allowed set but the Failure Mode table had no matching abort row, asymmetric with the existing `status`-field defect row.

### Changes
- Failure Mode table: new row for `maturity` value outside the allowed set, with the specific abort message naming the allowed set.

### Dimensions Evaluated
Completeness (primary), Coherence (sibling-symmetry with status row).

### Rename
No rename.

## 2026-05-17

### Summary
One over-engineering trim from the 2026-05-17 broad sweep: de-duplicated the reserved-name error string. Pre-flight §5 was restating the same error message already canonical in the Failure Mode table — Pre-flight now states the trigger and points to the table.

### Changes
- Pre-flight §5 (Reserved-name refusal): removed inline error-string code block and trailing "Substitute the resolved slug..." sentence; replaced with one-paragraph trigger + pointer to the Failure Mode table. Failure Mode table row remains the single source of the error text.

### Dimensions Evaluated
Over-Engineering (primary — Non-redundant Content Gate), Coherence (sibling parity with prior Mermaid trim), Spec Alignment, Skill Design Quality, Actionability, Completeness, Orchestration, Rename.

### Rename
No rename.

## 2026-05-16

### Summary
Three small actionability fixes targeting operator pain on output quality and Docket integration: named the priority scheme in User Stories §4 (was undefined), added `docket issue list --tree` as a second Docket probe to surface pre-existing epics, and clarified that `docs/spec/` contains both PRDs and the 7 reserved engineering specs.

### Changes
- Required Sections §4 (User Stories): require an explicit per-story priority scheme (P0/P1/P2 or MVP/polish), mirroring ux-spec §9; bare "with priorities" is now a defect.
- Authoring Procedure §2 (Docket probe): added `docket issue list --tree` as second probe — PRDs precede epic decomposition, so tree view is the right Docket lens for overlap detection.
- Authoring Procedure §1 (prior art): clarified that the 7 reserved engineering specs in `docs/spec/` are not PRDs and should be skipped unless the PRD genuinely depends on one.

### Dimensions Evaluated
Actionability (primary), Output Quality, Coherence (sibling ux-spec §9 pattern), Spec Alignment.

### Rename
No rename.

## 2026-05-09

### Summary
Six output-quality fixes (operator pain point 3): added concreteness gates to Success Metrics and Requirements sections, sharpened Docket probe with priority filter, replaced fuzzy "before commitment" with concrete decomposition trigger, added validation rule + failure mode for numeric metric targets.

### Changes
- Authoring Procedure §2 (Docket probe): added `--sort priority:asc` filter and explicit instruction to consolidate findings under Risks & Open Questions, eliminating the "note candidates where appropriate" ambiguity.
- Required Sections §5 (Requirements): added testability rule — each requirement must be reviewable as satisfied/unsatisfied without follow-up.
- Required Sections §6 (Success Metrics): added concreteness rule — each metric names what/how/numeric target. Concrete example included.
- Required Sections §7 (Risks & Open Questions): replaced fuzzy "before commitment" with "before decomposition into Docket issues".
- Validation Before Save §7: new gate — Success Metrics section must contain at least one digit or comparison operator per item.
- Failure Mode table: new row aligning with the Success Metrics concreteness validation failure.

### Dimensions Evaluated
Skill Design Quality, Actionability (primary), Output Quality, Coherence (sibling tdd/adr/ux-spec), Spec Alignment, Over-Engineering (light — additive but bounded), Orchestration (leaf-safety unchanged), Rename.

### Rename
No rename.

## 2026-05-09

### Summary
Phase 2 coherence pass: hardened Validation §4 to self-reference Required Sections instead of hardcoding "all 7".

### Changes
- Replaced hardcoded "all 7 Required Sections" with self-referential enumeration ("(currently 7 sections). Off-by-one against the count is a defect.") — matches tdd's hardened pattern.

### Dimensions Evaluated
Coherence, Completeness.

### Rename
No rename.

## 2026-05-09

### Summary
Coherence pass: aligned When NOT to Use delegation ordering with sibling doc-authoring skills (tdd, adr, ux-spec) and sharpened PRD-vs-TDD disambiguation in When to Use.

### Changes
- When NOT to Use: moved "Project-wide engineering specs" bullet from second position to last, matching sibling skills' delegation-list ordering. Reason: family-wide consistency improves predictability for operators reading the doc-authoring skills in sequence.
- When to Use bullet 1: appended "Pick PRD over TDD when scope precedes architecture — what and why is uncertain, not how." Reason: PRD-vs-TDD is the most load-bearing routing decision for callers; team-lead.md already uses this framing — surface it where the calling agent reads it.

### Dimensions Evaluated
Coherence (sibling-skill alignment), Output Quality / Actionability (PRD-vs-TDD disambiguation), Operator Prompt Quality, Scope/Budget, Leaf-Skill Safety, Spec Alignment.

### Rename
No rename. The "prd" name is parallel to adr/tdd/ux-spec siblings.

## 2026-05-07

### Summary
Phase 2 coherence: removed redundant sub-agent prohibition row from Failure Modes for symmetry with ux-spec; already enforced by CANONICAL:BANNER + `allowed-tools`. Net -1.

### Changes
- Removed Failure Mode row "Calling agent attempts to spawn sub-agents..." — fully redundant with CANONICAL:BANNER + `allowed-tools` exclusion list (Content Gate: Non-redundant fail). Sibling parity with ux-spec's 2026-05-06 removal.

### Dimensions Evaluated
Coherence — sibling-skill symmetry.

### Rename
No rename.

## 2026-05-07

### Summary
Coherence pass: added missing "When NOT to Use" COUPLING comment for sibling-symmetry with adr/tdd/ux-spec; corrected false claim in reserved-names COUPLING that asserted tdd/adr/ux-spec hard-refuse reserved names (verified they don't — those skills write to different output directories so refusal is unnecessary). Net 280→281.

### Changes
- When NOT to Use: added `<!-- COUPLING: ... -->` comment above delegation routes; matches symmetric pattern in adr/tdd/ux-spec
- Failure Modes Reserved-Name List COUPLING: rewrote to reflect actual coupling — reserved-name refusal lives in PRD and specs only because they share `docs/spec/`; tdd/adr/ux-spec write to different directories and do not need refusal. Lockstep is now PRD ↔ specs, not 5-way.

### Dimensions Evaluated
Coherence (primary), Skill Design Quality, Actionability, Completeness, Over-Engineering, Spec Alignment, Orchestration, Rename.

### Rename
No rename.

## 2026-05-07

### Summary
Phase 2 coherence: fixed stale H1 prefix to align with `name: prd` after `create-` prefix was dropped. Symmetric to the vote H1 fix.

### Changes
- H1 changed from `# Create PRD — ...` to `# PRD — ...` to match frontmatter `name:` field

### Dimensions Evaluated
Coherence.

### Rename
No rename.

## 2026-05-06

### Summary
Coherence pass: replaced stale `dev` skill reference with the team-lead Large Task pattern (the dev skill was retired in commit 01b6d0c) and made the reserved-name COUPLING comment symmetric with sibling skills. Net +0.

### Changes
- When to Use: line 60 — "The `dev` skill's Large Task pattern" → "The team-lead Large Task pattern (`agents/team-lead.md`)". Reason: dev skill replaced by team-lead orchestrator; PRD entry-point now lives at agents/team-lead.md:78–85
- Failure Modes Reserved-Name List COUPLING comment: rephrased to match the symmetric "Update all 5 (this file plus the N siblings) in lockstep" pattern already used in tdd, adr, ux-spec, and specs

### Dimensions Evaluated
Coherence, Spec Alignment, Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration, Rename.

### Rename
No rename.

## 2026-05-06

### Summary
**Rename: `create-prd` → `prd`** per operator request to drop the `create-` prefix from the spec/doc-authoring family. Directory moved, frontmatter `name:` updated, slash command `/create-prd` → `/prd`, all cross-references updated.

### Changes
- Directory renamed `skills/create-prd/` → `skills/prd/`
- Frontmatter `name: create-prd` → `name: prd`
- Cross-references updated in: sibling skills (`adr`, `tdd`, `ux-spec`, `specs`), `agents/project-manager.md`, `agents/staff-engineer.md`, `agents/team-lead.md`, `README.md`
- COUPLING comment phrasing changed from "create-* family" → "doc-authoring family"
- Reserved-name error messages updated to reference the `specs` skill (no longer `create-specs`)
- Changelog file moved: `docs/changelog/skills/create-prd.md` → `prd.md`; H1 updated; historical entries left intact

### Dimensions Evaluated
Rename, Coherence

### Rename
Renamed `create-prd` → `prd` per operator request.

## 2026-05-06

### Summary
Phase 2 coherence: collapsed Mermaid Mandate triple-restatement to a single paragraph that defers to Authoring §5 and Validation Before Save.

### Changes
- Mermaid Mandate dedicated subsection: 7 lines → 4; same triple-restatement pattern reviewers trimmed from create-adr and create-ux-spec in Phase 1.

### Dimensions Evaluated
Over-Engineering (triple-restatement trim).

### Rename
No rename.

## 2026-05-06

### Summary
Phase 1 over-engineering and coherence pass: trimmed Mermaid Mandate editorial commentary, removed redundant output-path footer, and made COUPLING comment symmetric with sibling skills.

### Changes
- Mermaid Mandate: removed editorial paragraph about "rarely warrants a feature-level PRD / reconsider doc class". Reason: editorial advice for the calling agent, not behavioral instruction; validation gate is the load-bearing rule.
- Save & Return: removed duplicate "{output_dir} is docs/spec/" footer. Reason: Pre-flight step 2 already establishes the path; two assertions encourage drift.
- COUPLING comment: now names all 4 sibling skills (create-tdd, create-adr, create-ux-spec, create-specs) instead of only create-specs. Reason: matches symmetric contract already present in create-specs/SKILL.md.

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration, Coherence, Spec Alignment, Rename Consideration.

### Rename
No rename. The `create-{type}` family naming is established and mutually consistent.

## 2026-05-06

### Summary
Phase 2 coherence: removed dead "missing-parent prompt" phrase from SAVE_AND_RETURN. PRDs are top-level and have no parent-doc class.

### Changes
- Save & Return Cancel handler: trimmed "or missing-parent prompt" — PRDs have no parent-doc probe. Dead text removed.

### Dimensions Evaluated
Coherence, Actionability.

### Rename
No rename.

## 2026-05-06

### Summary
First changelog entry. Three small coherence and clarity fixes applied as part of the doc-authoring family pass.

### Changes
- Mermaid Mandate: replaced unverifiable "TDD §4.11" cross-reference with a direct contrast to create-tdd's pure-policy override. Reason: the cited section does not exist in create-tdd.
- Authoring Procedure step 6: removed duplicate self-check checklist; Validation Before Save is now the single source of truth. Reason: two near-identical checklists drift independently.
- Requirements section: named the MoSCoW scheme explicitly (Must / Should / Could / Won't). Reason: bare "must/should/could" read like RFC-2119 inconsistency.

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration, Coherence, Spec Alignment, Rename Consideration.

### Rename
No rename. The name is parallel to create-adr/create-tdd/create-ux-spec siblings.
