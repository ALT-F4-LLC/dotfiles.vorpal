# Changelog: dev

## 2026-03-19

### Summary
Trimmed from 503 to 487 lines. Removed redundant Consensus Phase Integration section, compacted consensus intro, and removed duplicate guidance.

### Changes
- Removed Phase Integration bullets from Consensus section (-11 lines, tautological with trigger tree)
- Compacted consensus intro paragraph from 3 lines to 1
- Removed duplicate "When uncertain, ask the user" (already in Pre-flight)
- Tightened team structure intro line

### Dimensions Evaluated
Over-Engineering (primary), Skill Design Quality, Coherence

### Rename
No rename.

## 2026-03-19

### Summary
Coherence fixes: added `allowed-tools` frontmatter, corrected `argument-hint` convention, added TeamCreate/TeamDelete to allowed-tools.

### Changes
- Added `allowed-tools` frontmatter to match convention across all orchestrator skills
- Changed `argument-hint` from `[work]` to `<work>` (angle brackets for required arguments)
- Added TeamCreate/TeamDelete to `allowed-tools`

### Dimensions Evaluated
Coherence with Other Skills, Skill Design Quality

### Rename
No rename.

## 2026-03-19

### Summary
Trimmed from 556 to 481 lines. Removed Docket CLI Quick Reference, replaced ASCII diagram with one-liner, extracted shared template boilerplate, consolidated rules, and compacted UX-Heavy Task pattern.

### Changes
- Removed Docket CLI Quick Reference (-32 lines, non-behavioral reference)
- Replaced ASCII team diagram with one-liner, kept table (-13 lines)
- Extracted shared template rules into preamble above Spawning Templates
- Consolidated 13 rules to 8 by removing those restated in workflow/templates
- Compacted UX-Heavy Task to reference Medium Task pattern

### Dimensions Evaluated
Over-Engineering (primary), Orchestration Effectiveness, Coherence

### Rename
No rename.

## 2026-03-19

### Summary
Added pattern decision tree, loop escalation limits, discovered-context propagation, and large-review splitting; removed Collision Prevention section.

### Changes
- Replaced heuristic pattern selection with ordered decision tree
- Added "Extending an Existing Plan" subsection to Pre-flight
- Added empty-diff guard to Code Review template
- Added Discovered comment forwarding between phases
- Added review-fix and bug-fix loop limits (2 cycles then escalate)
- Added large-review splitting guidance for 20+ file changes
- Removed redundant Collision Prevention section

### Dimensions Evaluated
Actionability, Completeness, Over-Engineering, Orchestration Effectiveness

### Rename
No rename.

## 2026-03-19

### Summary
First evolution cycle. Added Large Task pattern, Full Verification template, resume guidance, and consolidated Roles section.

### Changes
- Added Large Task orchestration pattern for multi-TDD work
- Added Full Verification @sdet template for cross-issue testing
- Added resume/continuation guidance in Pre-flight
- Consolidated Roles prose into compact table
- Added practical concurrency limit (5 agents per turn)

### Dimensions Evaluated
Actionability, Completeness, Over-Engineering, Orchestration Effectiveness

### Rename
No rename.
