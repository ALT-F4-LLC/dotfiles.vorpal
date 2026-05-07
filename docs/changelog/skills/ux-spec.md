# Changelog: ux-spec

## 2026-05-06

### Summary
**Rename: `create-ux-spec` → `ux-spec`** per operator request to drop the `create-` prefix from the spec/doc-authoring family. Directory moved, frontmatter `name:` updated, slash command `/create-ux-spec` → `/ux-spec`, all cross-references updated.

### Changes
- Directory renamed `skills/create-ux-spec/` → `skills/ux-spec/`
- Frontmatter `name: create-ux-spec` → `name: ux-spec`
- Cross-references updated in: sibling skills (`prd`, `tdd`, `adr`, `specs`), `agents/ux-designer.md`, `agents/team-lead.md`, `README.md`
- COUPLING comment phrasing changed from "create-* family" → "doc-authoring family"
- Changelog file moved: `docs/changelog/skills/create-ux-spec.md` → `ux-spec.md`; H1 updated; historical entries left intact

### Dimensions Evaluated
Rename, Coherence

### Rename
Renamed `create-ux-spec` → `ux-spec` per operator request.

## 2026-05-06

### Summary
Phase 2 coherence: added create-* family COUPLING comment for sibling-asymmetry prevention.

### Changes
- Added COUPLING comment to "When NOT to Use" section listing the 4 sibling create-* skills (mirroring create-prd's RESERVED-NAMES marker) — prevents asymmetric drift when adding/removing siblings.

### Dimensions Evaluated
Coherence (cross-skill family symmetry).

### Rename
No rename.

## 2026-05-06

### Summary
Phase 1 over-engineering trim: removed five duplicated rules — Authoring self-check (mirrored Validation), Pre-flight prior-art scan (overlapped Authoring step 1), trailing path restatement, two redundant Failure Modes rows, and the third repetition of Mermaid Mandate. Net 298→282.

### Changes
- Authoring step 8 self-check removed — duplicated Validation Before Save verbatim
- Pre-flight step 5 prior-art scan removed — Authoring step 1 already runs a broader Grep over docs/
- Removed trailing `{output_dir}` / `{output_path}` restatement after SAVE_AND_RETURN block — Pre-flight step 2 establishes the path
- Failure Modes table: collapsed three rows (status-field, Mermaid-missing, generic validation) into one row referencing common defects
- Validation step 5: removed third repetition of "Mermaid Mandate is mandatory; there is no override"

### Dimensions Evaluated
Over-Engineering, Coherence, Actionability, Completeness, Orchestration.

### Rename
No rename. Family-aligned with create-tdd/create-prd/create-adr.

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
