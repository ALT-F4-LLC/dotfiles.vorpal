# Changelog: create-prd

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
