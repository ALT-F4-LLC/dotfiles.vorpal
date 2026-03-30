# Changelog: evolve-skills

## 2026-03-29

### Summary
Trimmed over-engineered content, aligned Phase 1 shutdown pattern with evolve-agents (immediate per-agent), upgraded effort to max.

### Changes
- Removed Rule 15 (Mermaid diagrams) — fails Content Gate for Behavioral and Concrete
- Consolidated docs-researcher template from 25+ lines to 6 focused lines (-19 lines)
- Replaced verbose SIZE CONSTRAINT blockquote with one-liner referencing Pre-flight step 8
- Changed `effort: high` to `effort: max` (matches dev skill complexity)
- Consolidated docket audit template from 7 lines to 3
- Merged orchestrator post-steps 5-6 into steps 2 and wrap-up
- Added immediate per-agent shutdown to Phase 1 (coherence with evolve-agents pattern)
- Removed batch Phase 1 shutdown from Phase 2 section header

### Dimensions Evaluated
Skill Design Quality, Over-Engineering, Orchestration & Agent Teams, Coherence, all 8 evaluated

### Rename
No rename.


## 2026-03-21

### Summary
Added operator observability reporting for cross-communication and vote usage; expanded Dimension 1 evaluation criteria; trimmed redundant Content Gate and template content.

### Changes
- Added observability report section to Wrap-up requiring orchestrator to surface cross-communication events, vote invocations, and course-corrections (+2 lines)
- Expanded Dimension 1 to explicitly check `user-invocable`, `effort`, `argument-hint` frontmatter fields (+1 line)
- Removed redundant "Avoid" coaching from Phase 1 template — covered by staff-engineer's own anti-patterns (-1 line)
- Removed redundant "Never add" enumeration from Content Gate — fully covered by checks 1 and 4 (-2 lines)
- [Phase 2] Added cross-communication logging step to Phase 1 orchestrator workflow for consistency with evolve-agents

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-03-20

### Summary
Removed phantom ToolSearch pre-flight step, consolidated docket audit template, rejected `context: fork` (breaks agent teams).

### Changes
- Removed non-existent `ToolSearch` pre-flight step and renumbered remaining steps (-2 lines)
- Consolidated Phase 0 docket audit template from 5 verbose steps to 3 focused steps (-4 lines)
- Rejected `context: fork` recommendation — breaks agent team coordination (TeamCreate/TeamDelete)

### Dimensions Evaluated
Actionability, Over-Engineering, Skill Design Quality

### Rename
No rename.

## 2026-03-20

### Summary
Fixed incorrect docket CLI reference, trimmed duplicate Content Gate and evaluation dimensions from Phase 1 template, added `context: fork` frontmatter.

### Changes
- Fixed `docket vote start` to `docket vote create` in Phase 0 template (docket CLI audit)
- Replaced verbatim Content Gate in Phase 1 template with back-reference (-5 lines)
- Replaced verbatim 8-dimension listing in Phase 1 template with concise reference (-6 lines)
- Added `context: fork` frontmatter for isolated execution context (+1 line)
- Aligned Phase 0 docket audit template with evolve-agents (coherence fix)

### Dimensions Evaluated
Over-Engineering, Skill Design Quality, Completeness

### Rename
No rename.

## 2026-03-20

### Summary
Trimmed redundant Phase 0 template instructions, consolidated overlapping changelog rules, and aligned argument handling with evolve-agents conventions.

### Changes
- Trimmed Phase 0 template from verbose step-by-step to focused prompt (-14 lines)
- Consolidated "Strict Changelog Rules" and "Changelog Normalization" into single "Changelog Rules" section
- Condensed rules 9-10 to back-references instead of restating constraints
- Added `$ARGUMENTS` reference to argument handling for cross-skill consistency

### Dimensions Evaluated
Over-Engineering, Skill Design Quality, Coherence with Other Skills

### Rename
No rename.

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
