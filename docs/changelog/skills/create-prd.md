# Changelog: create-prd

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
