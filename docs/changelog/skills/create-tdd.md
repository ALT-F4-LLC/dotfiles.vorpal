# Changelog: create-tdd

## 2026-05-06

### Summary
First changelog entry. Four fixes: removed stale "TDD §4.3" cross-reference, clarified pure-policy Mermaid override location, collapsed redundant Self-check, removed trailing path restatement. Net 317→311.

### Changes
- Frontmatter field rules: removed unverifiable "see TDD §4.3" cross-reference (this skill is itself the format authority)
- Authoring §4 Mermaid clause: override note now belongs in the drafted Architecture & System Design section, not in the skill's own §4 — eliminates instruction-target ambiguity
- Authoring §8 Self-check: collapsed duplicative checklist into one-line pointer (Validation Before Save is the load-bearing gate)
- Removed redundant `{output_dir}` / `{output_path}` restatement after canonical SAVE_AND_RETURN block (already specified in Pre-flight §2)

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration, Coherence, Spec Alignment, Rename

### Rename
No rename. Family-aligned with create-adr/create-prd/create-ux-spec.
