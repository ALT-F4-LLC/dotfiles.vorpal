# Changelog: specs

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
