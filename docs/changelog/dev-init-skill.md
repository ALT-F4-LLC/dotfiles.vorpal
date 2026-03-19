# Dev Init Skill Evolution Log

## 2026-03-19 (second cycle)

### Summary
Second evolution cycle. Shifted orchestrator responsibilities out of spawned agents, improved
frontmatter instruction clarity in the spawning template, added content verification to the
post-spawn check, and passed project name explicitly to agents.

### Changes
- Moved `mkdir -p docs/spec` from the spawning template into Pre-flight step 3: the orchestrator
  now creates the output directory once before spawning, rather than having 7 agents each run
  `mkdir -p` independently. This is a cleaner separation of orchestrator vs. agent responsibilities
  and avoids 7 redundant shell calls.
- Added Pre-flight step 2 to resolve the project name via
  `basename $(git rev-parse --show-toplevel)` and pass it as `{project_name}` to every spawned
  agent. Previously the template told each agent to "use repository name" but left discovery to
  each agent independently, risking inconsistency (same problem the first cycle solved for dates).
- Restructured the frontmatter instruction in the spawning template from a single dense bullet
  point listing 7 fields inline to a concrete YAML code block that agents can use as a copy
  template. This significantly reduces the chance of agents producing malformed or inconsistent
  frontmatter. Sub-bullets explain the fields that require judgment (`maturity`, `dependencies`).
- Added explicit "Today's date" and "Project name" context lines at the top of the spawning
  template prompt, making these values immediately visible to the spawned agent rather than
  buried in a frontmatter instruction.
- Enhanced Step 3 (Verify) to check file content, not just existence: the orchestrator now runs
  `head -1 docs/spec/*.md` to confirm every file starts with `---` (YAML frontmatter delimiter),
  catching malformed output early.
- Updated Wrap-up to mention flagging malformed output alongside missing files.
- Added `{project_name}` to the substitution variable list in Execution Step 1 and the Spawning
  Template header.

### Dimensions Evaluated
- **Actionability**: Frontmatter YAML template block replaces a dense prose instruction, making
  agent output more reliable and consistent. Explicit date/project context lines at prompt top
  improve discoverability.
- **Orchestration Effectiveness**: Moving `mkdir -p` to orchestrator pre-flight is a proper
  separation of concerns — orchestrators prepare the environment, agents produce content.
  Resolving project name centrally eliminates redundant discovery across 7 agents.
- **Completeness**: Content verification in Step 3 catches malformed output that file-existence
  checks would miss. This closes a gap where an agent could write a file but produce invalid
  frontmatter.
- **Skill Design Quality**: Frontmatter, trigger phrases, and argument handling remain appropriate.
  No structural changes needed.
- **Over-Engineering**: No sections removed this cycle — the skill is already lean.
- **Coherence with Other Skills**: Conventions remain aligned with dev-team and evolve-* skills.
  No new coherence issues introduced.
- **Spec Alignment**: Project name resolution aligns with how architecture.md identifies the
  project. Frontmatter format matches the spec file format documented in the @staff-engineer
  agent definition.
- **Rename Consideration**: No rename needed — see below.

### Rename
No rename — "dev-init" remains the right name. No new arguments for change since first cycle.

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
