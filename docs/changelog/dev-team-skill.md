# Dev Team Skill Evolution Log

## 2026-03-19

### Summary
First evolution cycle. Focused on actionability gaps (SDET verification mismatch, code review template missing file context), completeness gaps (no Large Task pattern, no resume guidance), and a redundancy between the ASCII diagram and prose Roles section.

### Changes
- **Added Large Task orchestration pattern**: For work requiring multiple TDDs or 5+ phases. Fills the gap between Medium and "just use Medium repeatedly" that the skill had no guidance for.
- **Added Full Verification @sdet template**: The workflow step 11 called for holistic verification across all completed work, but the only @sdet template was issue-scoped. Added a second template that covers cross-issue integration verification using `git diff` for full scope.
- **Renamed existing @sdet template to "Issue Verification"**: Disambiguates the two @sdet templates now that both exist.
- **Improved @staff-engineer (Code Review) template**: Added `Files changed: {run git diff --stat and include the output here}` to give the reviewer concrete file scope. Changed "Review all modified files using git diff" to the more specific "Run `git diff` to review all uncommitted changes."
- **Added resume/continuation guidance**: New "Resuming Mid-Execution" subsection under Pre-flight. Instructs the Team Lead to check `docket board --json`, identify the last active phase, check for Discovered comments, and resume from the next incomplete phase.
- **Consolidated Roles section**: Replaced the verbose per-role prose with a compact table (Agent, Primary Output, Key Constraint). The ASCII diagram above it already showed the hierarchy -- the table adds the structured detail the diagram cannot convey without duplicating the same information in paragraph form.
- **Added practical concurrency note**: Step 7 now includes "Practical limit: spawn up to 5 agents per turn" with batching guidance for larger phases.
- **Clarified placeholder handling in templates**: Changed `{the user's original request}` to `{copy the user's original request verbatim}` to remove ambiguity about whether to summarize or copy.
- **Updated step 10 (Review Phase)**: Now instructs the Team Lead to include `git diff --stat` output in the review prompt.
- **Updated step 11 (Verification Phase)**: Now explicitly references the "Full Verification template" to resolve the mismatch between the workflow step and the available templates.

### Dimensions Evaluated
- **Actionability**: Drove the SDET template split, code review file context, placeholder clarification, and concurrency guidance.
- **Completeness**: Drove the Large Task pattern and resume/continuation section.
- **Over-Engineering**: Drove the Roles section consolidation from prose to table.
- **Orchestration Effectiveness**: Drove the Full Verification template and step 10/11 improvements.
- **Coherence with Other Skills**: Verified convention alignment with dev-init, evolve-skills, and evolve-agents. No conflicts found.
- **Spec Alignment**: Verified against architecture.md and review-strategy.md. No drift.

### Rename
No rename -- current name `dev-team` accurately reflects the skill's purpose as the development team orchestrator.
