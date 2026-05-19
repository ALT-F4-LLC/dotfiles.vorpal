# Changelog: design-review

## 2026-05-19

### Summary
Phase 2 coherence — added explicit Epistemic Discipline Validation check (new check #10) so the banned-phrases rule from Common Discipline is gate-enforced, matching code-review's check #9. Net +1 line.

### Changes
- Validation Before Emit: added check #10 — scan What's Strong / What Needs Work / Open Questions / Next Steps for banned confidence phrases; a hit is a defect.

### Dimensions Evaluated
Coherence, Epistemic Discipline, Report-Emission Family Parity.

### Rename
No rename.

## 2026-05-18

### Summary
Phase 1 trim + Epistemic Discipline pass: removed incorrect "Stream long inspections" bullet (design-review is PRE-impl — nothing runs), collapsed Pre-flight empty-artifact guard to Failure Modes reference, folded banned-hedge list into Honest Critique bullet. Net -5 lines, behavior unchanged.

### Changes
- Common Discipline: removed "Stream long inspections" bullet — design-review has no binary/dev-server scope.
- Common Discipline "Honest critique" → "Honest critique with evidence": added requirement to cite the grounding artifact and listed banned hedges per Epistemic Discipline.
- Pre-flight step 6: collapsed inline abort code-fence to a one-line reference pointing at Failure Modes table.

### Dimensions Evaluated
Over-Engineering (HIGHEST), Skill Design Quality, Coherence (vs design-qa, family parity), Spec Alignment.

### Rename
No rename.

## 2026-05-17

### Summary
Phase 1 trim pass: removed redundant Role Detection note, dropped Failure Modes row that pure-restates a Validation inline abort, tightened Validation rule #2 and Failure Modes preamble. Net -22 lines, no behavioral change.

### Changes
- Role Detection: removed "Note" block restating @staff-engineer/@security-engineer routing — already covered by When NOT to Use + abort message.
- Failure Modes: removed "Recommendation/severity mismatch" row — pure-restates Validation rule #2's abort, matching the 2026-05-16 trim criterion.
- Validation Before Emit rule #2: tightened wording, dropped parenthetical that duplicated Recommendation Ladder content.
- Failure Modes preamble: compressed enumeration of inline-abort locations to one sentence.

### Dimensions Evaluated
Over-Engineering (HIGHEST), Skill Design Quality, Actionability, Coherence (vs design-qa).

### Rename
No rename.

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
