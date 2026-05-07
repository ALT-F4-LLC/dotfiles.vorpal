# Changelog: create-tdd

## 2026-05-06

### Summary
Phase 2 coherence: added create-* family COUPLING comment, collapsed Mermaid Mandate triple-restatement, clarified maturity-vs-status rationale.

### Changes
- Added COUPLING comment to "When NOT to Use" section listing the 4 sibling create-* skills (mirroring create-prd's RESERVED-NAMES marker) — prevents asymmetric drift.
- Mermaid Mandate dedicated subsection: 14 lines → 4; rule lives in Authoring §4 and Validation Before Save.
- Field rules: added one-paragraph note explaining why TDDs carry BOTH `maturity` and `status` while PRDs/UX specs use only `maturity` and ADRs use only `status` — locks the orthogonal-ladder design intent into the file. Phase 1 reviewer's CHANGE 2 (drop maturity) deferred with rationale.

### Dimensions Evaluated
Coherence (cross-skill family symmetry), Over-Engineering (triple-restatement trim), Skill Design Quality (frontmatter contract clarity).

### Rename
No rename.

## 2026-05-06

### Summary
Phase 1: collapsed over-engineered Parent-PRD probe (30-line keyword-split + AskUserQuestion) into a single Glob-and-judge step; tightened Validation §4 alternatives heuristic; cleaned up orphaned references to the now-removed missing-parent prompt. Net 311→~285.

### Changes
- Pre-flight §5 Parent-PRD probe: replaced multi-step keyword-split + stopword + per-keyword-glob + zero-result AskUserQuestion procedure with a single Glob-and-note step. Reason: calling-agent judgment is authoritative; the ceremony added no signal beyond "look in docs/spec/".
- Validation §4: removed brittle `### Alt` prefix heuristic; kept the concrete "two `###`-level subsections" rule. Natural alternatives may use `### Option A`, `### In-process worker`, etc.
- SAVE_AND_RETURN: trimmed orphaned "or missing-parent prompt" phrase from the Cancel handler (parallel cleanup to the prior 2026-05-06 entries in create-prd / create-ux-spec / create-adr).
- Failure Modes table: removed orphaned "Parent-PRD probe finds zero results" row (the missing-parent AskUserQuestion no longer exists).
- DEFERRED to Phase 2: reviewer's CHANGE 2 (drop `maturity` frontmatter) — coherence-reviewer must reconcile against create-prd (uses `maturity` only) and create-adr (uses `status` only) before unifying.

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration, Coherence, Spec Alignment, Rename.

### Rename
No rename. Family-aligned with create-adr/create-prd/create-ux-spec.

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
