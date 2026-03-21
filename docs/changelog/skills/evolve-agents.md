# Changelog: evolve-agents

## 2026-03-21

### Summary
Added cross-communication and vote observability reporting to address operator pain point about lacking visibility into inter-agent messaging and vote usage during evolution cycles.

### Changes
- Added cross-communication log and vote proposal tracking to wrap-up report output (operator feedback: no observability into agent messaging/votes)
- Added cross-communication logging step to Phase 1 orchestrator workflow
- Compressed Phase 0 docket audit template steps from 5 to 3 (-3 lines, offset additions)

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-03-20

### Summary
Coherence fixes: added Docs Research task to Team Setup, renamed Phase 0 heading to match behavior.

### Changes
- Added Docs Research task to Team Setup step 2 (was missing vs evolve-skills)
- Renamed Phase 0 heading from "Documentation Research & Docket CLI Audit" to "Docket CLI Audit & Docs Context"

### Dimensions Evaluated
Coherence

### Rename
No rename.

## 2026-03-20

### Summary
Removed phantom ToolSearch step, compressed changelog rules, expanded docket audit checklist.

### Changes
- Removed non-existent `ToolSearch` pre-flight step and renumbered steps (-2 lines)
- Compressed Changelog Rules from 18 lines to 7, matching evolve-skills format (-11 lines)
- Added `docket next`, `docket board`, `--escalation-reason` to Phase 0 audit checklist

### Dimensions Evaluated
Actionability, Over-Engineering, Completeness, Coherence

### Rename
No rename.

## 2026-03-20

### Summary
Compressed pseudo-code blocks, fixed docket CLI audit completeness, added `context: fork` frontmatter.

### Changes
- Compressed Phase 0, Phase 1, and Phase 2 spawn pseudo-code (-13 lines)
- Updated Phase 0 template to check for newly-discovered docket commands and flags
- Added `context: fork` frontmatter for subagent isolation
- Replaced `grep -r` with Grep tool reference in Phase 0 template
- Compressed "Never add" list into "Reject examples" one-liner

### Dimensions Evaluated
Over-Engineering, Completeness, Actionability, Spec Alignment

### Rename
No rename.

## 2026-03-20

### Summary
Removed Phase 0 agent spawning (docs research now passed as caller context), removed project-agnostic Content Gate check, compressed argument handling, dimension restatements, and template redundancies.

### Changes
- Replaced Phase 0 agent spawn with passthrough of caller-provided docs research context
- Removed Phase 0 spawning template (dead code after Phase 0 change)
- Removed Content Gate check #3 (project-agnostic) — agent files are project-specific; aligns with evolve-skills
- Compressed Argument Handling by removing redundant ls block (duplicated in Pre-flight)
- Compressed Phase 1 template dimension list — removed redundant "Content Gate applies" notes

### Dimensions Evaluated
Over-Engineering, Actionability, Coherence with Other Skills

### Rename
No rename.

## 2026-03-20

### Summary
Added effort frontmatter, compressed Phase 0 template and Team Setup pseudo-code, simplified timeout fallback rule, added ultrathink trigger for deep self-review analysis.

### Changes
- Added `effort: high` frontmatter for complexity-appropriate reasoning depth
- Compressed Phase 0 spawning template from 35 to 25 lines by removing boilerplate output format
- Compressed Team Setup pseudo-code from verbose inline code to concise descriptions
- Simplified rule 10 timeout fallback to single-attempt-then-orchestrator pattern
- Added ultrathink trigger to Phase 1 for extended thinking during self-review
- Fixed 2 TaskUpdate calls: `task_id` to `taskId`, removed `team_name`
- Fixed 1 TaskList call: removed invalid `team_name` parameter

### Dimensions Evaluated
Skill Design Quality, Completeness, Over-Engineering, Coherence with Other Skills

### Rename
No rename.

## 2026-03-19

### Summary
Trimmed from 459 to 457 lines. Collapsed redundant changelog normalization restatement.

### Changes
- Collapsed Phase 1 step 4 changelog normalization detail into reference to Changelog Format section

### Dimensions Evaluated
Over-Engineering

### Rename
No rename.

## 2026-03-19

### Summary
Added `allowed-tools` frontmatter, compressed Wrap-up and Team Setup sections, replaced redundant "orchestrator-only edits" line with self-evolution note, matching evolve-skills conventions.

### Changes
- Added `allowed-tools` frontmatter to preapprove orchestrator tools (including TeamCreate/TeamDelete)
- Compressed Wrap-up from 22 to 9 lines to match evolve-skills pattern
- Compressed Team Setup pseudo-code from verbose code blocks to inline format
- Replaced triple-stated "only orchestrator edits" with self-evolution note

### Dimensions Evaluated
Skill Design Quality, Over-Engineering, Coherence with Other Skills

### Rename
No rename.

## 2026-03-19

### Summary
Fixed date propagation gap and aligned template structure with evolve-skills conventions.

### Changes
- Added `{today_date}` propagation to Phase 1 and Phase 2 spawning templates
- Strengthened pre-flight step 1 wording to require template substitution
- Added `Agent: <name>` identifier line to Phase 1 template header
- Added spec selectivity guidance to orchestration workflow

### Dimensions Evaluated
Actionability, Coherence with Other Skills, Completeness

### Rename
No rename.

## 2026-03-19

### Summary
Added Pre-flight section, fixed template issues, and aligned with evolve-skills conventions.

### Changes
- Added Pre-flight section with 5 validation steps
- Fixed duplicate step 6 numbering in Phase 1 workflow
- Removed hardcoded agent role descriptions from template
- Replaced hardcoded WebFetch URL with graceful degradation
- Added `.claude/skills/` to Phase 2 rename search paths

### Dimensions Evaluated
Completeness, Actionability, Coherence with Other Skills

### Rename
No rename.
