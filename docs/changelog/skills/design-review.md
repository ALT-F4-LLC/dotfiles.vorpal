# Changelog: design-review

## 2026-05-16

### Summary
Phase 2 coherence pass: banner footer now mentions Docket comments (matches Save & Return obligations and aligns with design-qa); Save & Return collapsed to "Output Contract owns the emission rules" per family-wide pattern.

### Changes
- Banner footer: added `and Docket comments` to the leaf-skill banner — Save & Return §line 236 requires Docket comment mirroring, so banner was inaccurate.
- Save & Return: replaced "This skill does NOT write a file. After Validation Before Emit passes, emit verbatim..." preamble with "No file is written (Output Contract owns the emission rules)" — matches code-review/design-qa/verify post-Phase-2.

### Dimensions Evaluated
Coherence (banner/footer parity, family Save & Return phrasing), Over-Engineering.

### Rename
No rename.

## 2026-05-16

### Summary
First changelog entry. Five fixes: aligned Output Contract frontmatter field with ux-spec contract (`maturity` not `status`), made the `Praise` severity's routing to `What's Strong` explicit, added AskUserQuestion structural contract (1-4 questions, 2-4 options, ≤12-char header), loosened Validation rule #2 to allow Redesign/Incremental Improvement when no Blocker is citable but the foundation is wrong, and trimmed Failure Modes table to rows with new abort text.

### Changes
- Output Contract Artifact section: `Maturity / status` line now reflects UX spec frontmatter contract.
- Severity Ladder Praise row: explicit "routes to What's Strong, not What Needs Work" annotation.
- Common Discipline: AskUserQuestion now specifies 1-4 questions, 2-4 options, ≤12-char header, default recommendation in first option's description.
- Validation Before Emit rule #2: Redesign / Incremental Improvement permitted with Concerns-only OR no severity findings when body argues fundamental rethink or bounded improvement.
- Failure Modes table compressed from 7 rows to 3 — dropped rows that pure-restate inline aborts; kept rows with new abort text.

### Dimensions Evaluated
Over-Engineering (HIGHEST — Failure Modes trim), Skill Design Quality, Actionability, Operator Prompt Quality, Spec Alignment, Coherence (vs design-qa).

### Rename
No rename.
