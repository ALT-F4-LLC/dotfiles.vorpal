# Changelog: evolve-skills

## 2026-03-20

### Summary
Added `effort: high` frontmatter and trimmed redundant Phase 2 preamble. Rejected Phase 0 removal (it IS the docs research mechanism, not redundant).

### Changes
- Added `effort: high` frontmatter for complexity-appropriate reasoning depth
- Trimmed redundant "read-only" preamble from Phase 2 template header (-2 lines)
- Fixed 3 TaskCreate calls: `title` to `subject`, removed `team_name` and `depends_on`
- Fixed 2 TaskUpdate calls: `task_id` to `taskId`, removed `team_name`
- Fixed 1 TaskList call: removed invalid `team_name` parameter

### Dimensions Evaluated
Skill Design Quality, Over-Engineering, Completeness, Coherence with Other Skills

### Rename
No rename.

## 2026-03-19

### Summary
Trimmed from 499 to 485 lines. Condensed Argument Handling and removed generic agent SDK boilerplate.

### Changes
- Condensed Argument Handling from 16 lines to 4, deferring validation to Pre-flight
- Removed "teammates go idle between turns" boilerplate (general agent behavior)

### Dimensions Evaluated
Over-Engineering (primary), Coherence with Other Skills

### Rename
No rename.

## 2026-03-19

### Summary
Coherence fixes: restored Phase 0 output format bullets for alignment with evolve-agents, added TeamCreate/TeamDelete to allowed-tools.

### Changes
- Restored bullet-point examples in Phase 0 Output Format to match evolve-agents template
- Added TeamCreate/TeamDelete to `allowed-tools`

### Dimensions Evaluated
Coherence with Other Skills, Actionability

### Rename
No rename.

## 2026-03-19

### Summary
Added `allowed-tools` frontmatter, trimmed Phase 0 output format scaffolding, and consolidated duplicate "orchestrator-only edits" statements.

### Changes
- Added `allowed-tools` frontmatter listing all tools the orchestrator needs
- Removed placeholder bullets from Phase 0 output format template (headers suffice)
- Consolidated two adjacent "orchestrator-only editing" statements into one

### Dimensions Evaluated
Skill Design Quality, Over-Engineering, Completeness

### Rename
No rename.

## 2026-03-19

### Summary
Closed date passthrough gap in spawning templates so agents receive consistent dates.

### Changes
- Added `Today's date is {today_date}` to Phase 1 spawning template Context section
- Added `Today's date: {today_date}` to Phase 2 spawning template header
- Updated template headers to list `{today_date}` in substitution variables
- Refined pre-flight step 1 to name the `{today_date}` variable explicitly

### Dimensions Evaluated
Completeness, Actionability, Orchestration Effectiveness

### Rename
No rename.

## 2026-03-19

### Summary
Added Pre-flight section, fixed WebFetch degradation, and aligned conventions with evolve-agents.

### Changes
- Replaced hardcoded WebFetch URL with graceful degradation
- Fixed duplicate step 6 numbering in Phase 1 workflow
- Added argument matching guidance for both skill paths
- Added Pre-flight section with 5 validation steps
- Added "Run pre-flight before spawning" as Rule #1

### Dimensions Evaluated
Completeness, Actionability, Coherence with Other Skills

### Rename
No rename.
