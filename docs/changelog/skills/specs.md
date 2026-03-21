# Changelog: specs

## 2026-03-20

### Summary
Added SendMessage completion trigger to spawning template, clarified completion monitoring in Step 2, and removed redundant cleanup rule.

### Changes
- Added SendMessage + TaskUpdate completion instructions to spawning template for explicit orchestrator notification
- Rewrote Step 2 to reference SendMessage-based completion flow instead of vague idle description
- Removed Rule 4 (duplicate of Wrap-up section)

### Dimensions Evaluated
Orchestration Effectiveness & Cross-Communication, Actionability, Over-Engineering

### Rename
No rename.

## 2026-03-20

### Summary
Fixed Task tool API calls to match actual schema, added `effort: medium` frontmatter, and trimmed duplicate Agent call from spawning template.

### Changes
- Added `effort: medium` frontmatter for appropriate reasoning depth
- Fixed TaskCreate parameters (`title` -> `subject`, removed invalid `team_name` and `depends_on`)
- Fixed TaskUpdate to use `taskId` instead of `task_id`, removed invalid `team_name`
- Fixed TaskList to remove invalid `team_name` parameter
- Removed duplicate `Agent()` call from Spawning Template (-1 line)

### Dimensions Evaluated
Skill Design Quality, Actionability, Over-Engineering, Coherence with Other Skills

### Rename
No rename.

## 2026-03-19

### Summary
Added argument handling and trimmed Rules for net +3 lines (163 to 166). First skill to support targeted file arguments.

### Changes
- Added `argument-hint: "[file...]"` frontmatter for UI parity with dev and vote
- Added Argument Handling section with optional file-list argument support
- Trimmed Rules from 8 to 4 (removed rules already covered by Pre-flight, Execution, Wrap-up)

### Dimensions Evaluated
Coherence with Other Skills, Over-Engineering, Skill Design Quality

### Rename
No rename.

## 2026-03-19

### Summary
Added allowed-tools frontmatter, consolidated Team Setup into Step 1, removed redundant commit prohibition from spawning template, and added cross-spec awareness instruction.

### Changes
- Added `allowed-tools` frontmatter to preapprove orchestration tools (including TeamCreate/TeamDelete)
- Merged standalone "Team Setup" subsection into "Step 1" as numbered preamble
- Removed "Do NOT commit" from spawning template (covered by top-level CRITICAL banner)
- Added instruction for spawned agents to skim existing docs/spec/ files to avoid overlap

### Dimensions Evaluated
Skill Design Quality, Over-Engineering, Completeness, Coherence

### Rename
No rename.

## 2026-03-19

### Summary
Shifted orchestrator responsibilities out of spawned agents, improved frontmatter clarity, added content verification, and passed project name explicitly.

### Changes
- Moved `mkdir -p docs/spec` to Pre-flight step 3 (orchestrator creates dir once)
- Added Pre-flight step 2 to resolve project name via `basename $(git rev-parse --show-toplevel)`
- Restructured frontmatter instruction as concrete YAML code block
- Added explicit date/project context lines to spawning template
- Enhanced Step 3 to verify frontmatter via `head -1 docs/spec/*.md`

### Dimensions Evaluated
Actionability, Orchestration Effectiveness, Completeness, Spec Alignment

### Rename
No rename.

## 2026-03-19

### Summary
First evolution cycle. Improved date consistency, clarified scope boundary with dev skill, tightened spawning template, and streamlined reference table.

### Changes
- Added date resolution step in Pre-flight for consistent `last_updated` values
- Added scope boundary statement clarifying specs vs dev skill responsibilities
- Added `docs/tdd/` cross-reference to spawning template
- Removed redundant Task Subject column from reference table
- Added "Be honest if no tests exist" to testing.md exploration guidance

### Dimensions Evaluated
Actionability, Completeness, Over-Engineering, Coherence, Spec Alignment, Skill Design Quality

### Rename
No rename.
