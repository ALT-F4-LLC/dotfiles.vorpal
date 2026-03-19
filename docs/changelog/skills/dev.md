# Dev Skill Evolution Log

## 2026-03-19 (2)

### Summary
Second evolution cycle. Focused on decision-making actionability (pattern selection was heuristic prose, now a concrete decision tree), feedback loop safety (no escalation limits on review-fix and bug-fix cycles), discovered-context propagation between phases, and edge case handling (empty diff in review, plan extension workflow).

### Changes
- **Replaced "Choosing the Right Pattern" heuristics with a decision tree**: The previous prose list required the Team Lead to weigh multiple factors simultaneously. Restructured as an ordered question flow under "Pattern Decision Tree" in Pre-flight, so the Team Lead answers sequential yes/no questions to arrive at the correct pattern deterministically.
- **Added "Extending an Existing Plan" subsection to Pre-flight**: Previously, the skill covered resuming mid-execution but not adding new work to an existing Docket plan. New guidance instructs the Team Lead to inspect the current plan and spawn @project-manager with extension (not replacement) instructions.
- **Added empty-diff guard to Code Review template**: The @staff-engineer review template now includes "If `git diff` shows no changes, STOP and report that no changes were found." This prevents the reviewer from producing a meaningless review when agents failed silently or changes were accidentally reverted.
- **Added Discovered comment forwarding in step 9**: After each phase completes, the Team Lead now checks Discovered comments and includes relevant ones as context in subsequent @senior-engineer prompts. Previously, Discovered comments were checked but not propagated forward, meaning later phases could miss context from earlier ones.
- **Added context line to @senior-engineer template for Discovered comments**: The template now includes an optional `{If Discovered comments exist from prior phases: ...}` line so the Team Lead has a concrete place to inject cross-phase context.
- **Added review-fix and bug-fix loop limits**: Steps 10 and 11 now include explicit escalation guidance: if the same blocker or bug persists after 2 fix cycles, escalate to the user rather than looping indefinitely. Added corresponding Rule 11: "Escalate loops."
- **Added large-review splitting guidance in step 10**: For large tasks with 20+ files changed, the Team Lead is now instructed to consider splitting the review across multiple @staff-engineer agents by logical grouping, using `git diff -- <paths>` to scope each review. Prevents context window exhaustion on single-agent reviews.
- **Removed Collision Prevention section**: This section restated what the @project-manager template and the Handling Failures section already cover (PM lists files, shared files go in different phases, serialize when in doubt). The PM template includes "VERIFY no two issues in the same phase touch the same files" and "List the specific files each issue will modify." The "Agent encounters a file conflict" failure handler covers runtime collisions. Removing the standalone section eliminates ~15 lines of redundancy without losing any guidance.

### Dimensions Evaluated
- **Actionability**: Drove the pattern decision tree, empty-diff guard, Discovered comment forwarding, and loop escalation limits.
- **Completeness**: Drove the plan extension workflow and large-review splitting guidance.
- **Over-Engineering**: Drove removal of the Collision Prevention section (redundant with PM template and failure handlers).
- **Orchestration Effectiveness**: Drove Discovered comment propagation between phases and review splitting for large tasks.
- **Coherence with Other Skills**: Verified convention alignment with specs, evolve-skills, and evolve-agents. No conflicts found. Consistent commit-notice banner, rule formatting, and template structure across all skills.
- **Spec Alignment**: Verified against architecture.md (agent team structure accurate) and review-strategy.md (review splitting aligns with the spec's guidance on change size triage). No drift.

### Rename
No rename -- current name `dev` accurately reflects the skill's purpose as the development team orchestrator.

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
- **Coherence with Other Skills**: Verified convention alignment with specs, evolve-skills, and evolve-agents. No conflicts found.
- **Spec Alignment**: Verified against architecture.md and review-strategy.md. No drift.

### Rename
No rename -- current name `dev` accurately reflects the skill's purpose as the development team orchestrator.
