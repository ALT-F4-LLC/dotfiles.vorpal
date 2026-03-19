# Dev Init Skill Evolution Log

## 2026-03-19

### Summary
First evolution cycle. Improved date consistency across spawned agents, clarified scope boundary
with dev-team skill, tightened the spawning template, and streamlined the reference table.

### Changes
- Added explicit date resolution step in Pre-flight: the orchestrator now runs `date +%Y-%m-%d`
  before spawning and passes `{today_date}` to every agent template, ensuring consistent
  `last_updated` frontmatter values across all 7 spec files (previously each agent had to
  independently determine "today's date," risking inconsistency)
- Added scope boundary statement clarifying that dev-init handles initial spec generation while
  ongoing spec maintenance is handled by @staff-engineer during normal dev-team workflows
  (prevents confusion about which skill to use for spec updates)
- Added `docs/tdd/` cross-reference to spawning template: agents now check for existing TDDs
  that might inform the spec they are generating (aligns with @staff-engineer agent definition
  which says specs should incorporate TDD findings)
- Made `mkdir -p docs/spec` explicit in the spawning template (was "create if it doesn't exist"
  which is less actionable for Claude)
- Removed redundant `Task Subject` column from the Spec File Reference table — it added no
  information beyond the filename itself, and the template doesn't use a `{task_subject}` variable
- Added "Be honest if no tests exist" to the testing.md exploration guidance (this project
  currently has zero tests, and the agent should document that rather than speculate)
- Added "CI quality gates" to review-strategy.md exploration guidance for completeness
- Updated spawning template variable list to reflect the actual substitution variables used
  (`{filename}`, `{exploration_guidance}`, `{today_date}`)

### Dimensions Evaluated
- **Actionability**: Date resolution and explicit mkdir improved execution reliability
- **Completeness**: Scope boundary and TDD cross-reference closed gaps
- **Over-Engineering**: Removed unused Task Subject column
- **Coherence with Other Skills**: Clarified boundary with dev-team; conventions (commit notice,
  frontmatter, rules format) already aligned
- **Spec Alignment**: Cross-referencing docs/tdd/ aligns with architecture.md's description of
  how specs and TDDs interact
- **Skill Design Quality**: Frontmatter is appropriate — no `disable-model-invocation` needed
  (this skill is user-invoked), no `argument-hint` needed (no arguments)
- **Rename Consideration**: No rename needed — see below

### Rename
No rename — "dev-init" accurately communicates bootstrapping/initialization purpose. While
"spec-init" would be more specific, "dev-init" is established in the README and leaves room
for future initialization responsibilities beyond specs.
