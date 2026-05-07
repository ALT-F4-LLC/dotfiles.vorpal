# Changelog: create-ux-spec

## 2026-05-06

### Summary
Phase 2 coherence: removed dead "missing-parent prompt" phrase from SAVE_AND_RETURN. create-ux-spec runs only an informational prior-art scan; no parent prompt.

### Changes
- Save & Return Cancel handler: trimmed "or missing-parent prompt" — Pre-flight step 5 is informational and never prompts. Dead text removed.

### Dimensions Evaluated
Coherence, Actionability.

### Rename
No rename.

## 2026-05-06

### Summary
First changelog entry. Removed three dead "TDD §X.Y" cross-references and broadened the N/A section allowance to apply across surface types. Net 296→298.

### Changes
- Removed two "TDD §4.3" references and one "TDD §4.11" reference. No numbered TDD section system exists in `docs/tdd/` or `docs/spec/`; verified with grep. The skill is itself the format authority.
- Mermaid Mandate authority: now points to `agents/ux-designer.md` only (was also citing TDD §4.11)
- Authoring step 3 N/A allowance: broadened from "internationalization for a CLI-only flag" to apply across surface×section combinations (visual design for a CLI flag, accessibility for a non-interactive config schema, etc.) — eliminates need to enumerate every combination

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration, Coherence, Spec Alignment, Rename

### Rename
No rename. Family-aligned with create-prd/create-tdd/create-adr.
