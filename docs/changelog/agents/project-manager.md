# Changelog: project-manager

## 2026-03-19

### Summary
Trimmed redundancy across session init, scope negotiation, external deps, and NOT-list. Added Bash tool constraint to prevent shell drift beyond Docket and read-only commands.

### Changes
- Compressed session initialization from 3 numbered steps to 2, removed `docket config`
- Removed redundant @sdet NOT entry (boundary already clear from cross-cutting concerns)
- Added Bash constraint rule: Docket commands and read-only exploration only
- Removed "cannot spawn sub-agents" platform detail from Exploration section
- Fixed self-referential re-engagement trigger (agent cannot "re-engage" itself)
- Folded scope negotiation into real-scope bullet
- Compressed External Dependencies section
- [Coherence] Replaced "orchestrator" with "user or team lead" (6 occurrences)

### Dimensions Evaluated
Consolidation & Trimming (primary), Completeness, Actionability, Role Realism, Coherence

### Rename
No rename.

## 2026-03-19

### Summary
Added Operating context paragraph to align with the pattern established across all other agents.

### Changes
- Added "Operating context" paragraph explaining stateless agent execution model, adapted to PM workflows

### Dimensions Evaluated
Boundary Clarity (cross-agent coherence)

### Rename
No rename.

## 2026-03-19

### Summary
Removed 4 sections that fail Content Gate (Communication Style, Retrospective, Anti-Patterns, Decision-Making). Folded Parallelism/Dependencies into Decompose the Work. Calibrated plan summary to tier.

### Changes
- Removed Communication Style, Retrospective, Anti-Patterns, Decision-Making Framework sections
- Folded Maximize Parallelism and Dependencies into Decompose the Work, preserving contract task pattern
- Compressed escalation into Rules section
- Calibrated plan summary checklist to scale with plan complexity tier

### Dimensions Evaluated
Consolidation & Trimming (primary), Completeness, Actionability

### Rename
No rename.

## 2026-03-19

### Summary
Major consolidation from 956 to 390 lines. Collapsed verbose routing templates, compressed issue examples, removed redundant workflow summary, and tightened all sections.

### Changes
- Collapsed Technical Investigation / UX Design / TDD routing into single "Exploration and Routing" section
- Compressed issue creation examples from three verbose blocks to one compact pattern
- Removed Planning Workflow Summary ASCII flowchart (duplicated section headings)
- Compressed Plan Monitoring templates, merged Cross-Workstream Coordination into Plan Monitoring
- Tightened all Core Responsibilities, Communication, Decision-Making, Anti-Patterns, Rules

### Dimensions Evaluated
Consolidation & Trimming (primary), Actionability, Role Realism, Boundary Clarity

### Rename
No rename.
