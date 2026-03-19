# Changelog: evolve-agents

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
