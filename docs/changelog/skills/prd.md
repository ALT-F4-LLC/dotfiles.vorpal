# Changelog: prd

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
