# Changelog: design-qa

## 2026-05-25

### Summary
Phase 2 coherence: AskUserQuestion structural trim, explicit Praise routing for family parity with design-review, removed duplicate reviewer-doubling-lifecycle cross-reference.

### Changes
- Replaced AskUserQuestion structural-contract restatement with pointer to calling agent's contract (Item 4 lockstep).
- Added explicit Praise routing to `What's Implemented Well` (Item 5 family parity with design-review:119).
- Removed redundant `See docs/tdd/reviewer-doubling-lifecycle.md...` pointer — same cross-ref already cited inline within Doubling Rule paragraph (Item 6).

### Dimensions Evaluated
Coherence, Family parity.

### Rename
No rename.

## 2026-05-25

### Summary
Phase 2 coherence + orchestration: added silent-completion self-check to Save & Return (cross-cutting with code-review per pitfalls.md "silent-completion of Skill output"). Mirrored design-review's canonical Doubling Rule phrasing for family parity — explicit `Agent()` spawn mechanic, `(spec section, surface)` dedupe key, and `AskUserQuestion`/`Skill(vote, ...)` contradiction-surfacing path. Net +3 lines.

### Changes
- Save & Return: added "Self-check before ending the turn" paragraph reminding the calling agent that in-context emission is the working artifact and the SendMessage is the deliverable. Lands in lockstep with code-review/verify/design-review.
- Doubling Rule: matched design-review's canonical phrasing — added `Agent()` spawn mechanic, `(spec section, surface)` dedupe key, and explicit AskUserQuestion / Skill(vote, ...) contradiction-surface path.

### Dimensions Evaluated
Orchestration (HIGHEST — silent-completion fix), Coherence (Doubling Rule family parity), Over-Engineering (evidence-backed additions only).

### Rename
No rename.

## 2026-05-20

### Summary
Tightened description trigger-phrase set per evolve-skills 2026-05-20 cycle: replaced verbose "design quality assurance" with lifecycle-anchored "QA the shipped UX" to add a cleanly distinct routing hook vs design-review without adding bulk. Net 0 lines.

### Changes
- Description trigger list: swapped "design quality assurance" → "QA the shipped UX".

### Dimensions Evaluated
Skill Design Quality, Coherence (disambiguation from design-review).

### Rename
No rename.

## 2026-05-19

### Summary
Phase 2 coherence — Epistemic Discipline parity with the report-emission family. Added the canonical banned-phrase list to Common Discipline and a Validation Before Emit scan so the rule is gate-enforced. Net +2 lines.

### Changes
- Common Discipline "Honest critique + concrete fix shape": appended the canonical banned-phrases list.
- Validation Before Emit: added check #7 — Epistemic Discipline scan across Issues / What's Implemented Well / Acceptable Deviations / Recommendation.

### Dimensions Evaluated
Coherence, Epistemic Discipline, Report-Emission Family Parity.

### Rename
No rename.

## 2026-05-18

### Summary
Resolved Validation/Procedure contradiction on "Cross-surface" Spec Section (cross-surface precedent violations are Blocker-class per the Severity ladder and must be allowed in that column at any severity); added "pair Blocker with concrete fix shape" rule to Common Discipline for parity with design-review and to reinforce the existing Output Contract column. Net -1 line.

### Changes
- Validation Before Emit (check 3): allow `"Cross-surface"` for Blockers/Concerns on cross-surface precedent findings, not just Suggestions/Praise.
- Common Discipline: merged "Honest critique" + "concrete fix shape" rule (parity with design-review). Reinforces the "expected per spec + observed" requirement.

### Dimensions Evaluated
Coherence (HIGHEST — cross-skill parity + internal contradiction), Actionability.

### Rename
No rename.

## 2026-05-17

### Summary
Phase 1 trim pass per 2026-05-17 evolve cycle: description rewritten to flag dormancy root cause and clarify post-impl lifecycle position; dropped 2 redundant Ambiguity rules and a redundant Validation check; tightened Failure Modes intro and one trigger phrasing. Net -15 lines.

### Changes
- Description: re-cast as "post-implementation QA" with explicit "invoke after spec is implemented" cue.
- Argument Handling: dropped 2 Ambiguity rules — both dead guidance (first-match-wins + no branch-name detection in the table).
- Validation Before Emit: removed check 1 (spec-reference re-confirmation) — Pre-flight step 4 already aborts on missing spec.
- Failure Modes: compressed 2-sentence intro to one.
- When to Use: tightened @sdet design-deviation trigger to drop process description.

### Dimensions Evaluated
Over-Engineering (HIGHEST), Skill Design Quality, Coherence, Actionability.

### Rename
No rename. `design-qa` is precise and lifecycle-distinct from `design-review`.

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
