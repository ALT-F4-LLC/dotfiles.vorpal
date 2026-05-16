# Changelog: design-qa

## 2026-05-16

### Summary
Phase 2 coherence pass: Common Discipline now includes the AskUserQuestion structural contract; Failure Modes trimmed to honor its "only new abort text" intro; Save & Return collapsed to "Output Contract owns the emission rules" per family-wide pattern.

### Changes
- Common Discipline: added "with 1-4 questions, each having 2-4 options and a `header` ≤12 chars" to the AskUserQuestion guidance — parity with design-review/code-review/verify.
- Failure Modes: dropped 4 rows that pure-restate inline aborts (missing scope, role mismatch, spec path not found, generic validation failure); kept 3 rows with new abort text (no-spec-attached, no-implementation, extras-ignored).
- Save & Return: replaced verbose preamble with "No file is written (Output Contract owns the emission rules)".

### Dimensions Evaluated
Coherence (operator-prompt contract; Failure Modes trim pattern; family Save & Return phrasing), Over-Engineering (HIGHEST — Failure Modes trim).

### Rename
No rename.

## 2026-05-16

### Summary
First changelog entry. Added evidence-citation requirement to QA Procedure common-discipline so every Blocker/Concern names file:line, command output, generated artifact, or surface state. Added matching validation check before report emit (renumbered placeholder scan).

### Changes
- QA Procedure common-discipline: added "Cite implementation evidence per finding" rule. Reason: prior format required Spec Section but not traceable evidence, allowing bare "diverges from spec" claims the calling agent could not action.
- Validation Before Emit: added check 5 enforcing the evidence requirement; renumbered subsequent placeholder-scan check 6 → 7. Reason: validation gate, not aspirational guidance.

### Dimensions Evaluated
Actionability (HIGHEST), Output quality / actionability (operator pain class #3).

### Rename
No rename. `design-qa` is precise, distinct from `design-review`, already cross-referenced across `agents/ux-designer.md` and sibling skills.
