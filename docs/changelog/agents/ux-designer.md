# Changelog: ux-designer

## 2026-03-20

### Summary
Removed standalone "Check Specs Before Designing" section (duplicated workflow step 1), folded unique content into Clarify step, compressed anti-patterns and Design System Coherence, added bidirectional notification trigger.

### Changes
- Removed "Check Specs Before Designing" section — duplicated Design Spec Workflow step 1
- Folded spec-reading file paths and selective-reading guidance into Clarify step
- Removed Operator Alignment anti-patterns (restated positive guidance above)
- Compressed Cross-team consistency into Pattern governance bullet
- Added "Request notification from others" trigger for bidirectional cross-communication

### Dimensions Evaluated
Consolidation & Trimming (primary), Cross-Communication, Completeness

### Rename
No rename.

## 2026-03-20

### Summary
Merged Content Design into Design Spec Format, deduplicated TDD conflict escalation, added @sdet notification trigger, removed redundant Design debt bullet.

### Changes
- Merged Responsibility 5 (Content Design) into Design Spec Format as a compact content design rule — the guidance is only actionable during spec creation
- Deduplicated TDD conflict escalation (appeared in 3 places, now references the canonical version)
- Added @sdet proactive notification trigger for testable edge cases in design specs
- Removed Design debt bullet (restates evaluation mode + anti-patterns)
- Fixed double blank line in Research section
- Renumbered Design QA from Responsibility 6 to 5

### Dimensions Evaluated
Consolidation & Trimming (primary), Cross-Communication, Boundary Clarity, Role Realism, Actionability, Completeness, Spec Alignment, Rename Consideration

### Rename
No rename.

## 2026-03-20

### Summary
Added effort and memory frontmatter, compressed Design Philosophy from 8 to 6 principles, removed Design Strategy Briefs, trimmed verbose status updates and decision heuristics.

### Changes
- Added `effort: max` and `memory: project` frontmatter fields
- Compressed Core Principles from 8 to 6 (removed items covered by Operator Alignment/specs)
- Removed "Aesthetics" from Decision-Making Framework (subsumed by Simplicity+Consistency)
- Removed Design Strategy Briefs subsection (niche, design spec format covers multi-surface)
- Compressed status updates from 7 to 1 line
- Removed Research heuristic paragraph
- Merged Evolution bullet into Cross-surface journeys
- Compressed /vote "skip for" guidance
- Updated Operating context to reflect project-scoped memory

### Dimensions Evaluated
Consolidation & Trimming (primary), Completeness, Actionability, Capability Growth

### Rename
No rename.

## 2026-03-19

### Summary
Compressed /vote section and status updates list, tightened spec format descriptions, added accessibility and visual-prototyping checks to self-validation, removed duplicated sentence from Operator Alignment.

### Changes
- Compressed /vote section from 28 to 10 lines — removed "When NOT" list and verbose invocation
- Compressed status updates list from 7 to 4 bullets
- Tightened Internationalization/Privacy/Measurement/Handoff spec section descriptions
- Added accessibility requirements check to self-validate step
- Added visual prototyping flag to self-validate step
- Removed duplicated "do not proceed to drafting" sentence from Operator Alignment
- [Coherence] Status updates: SendMessage now primary channel; Docket comments conditional

### Dimensions Evaluated
Consolidation & Trimming (primary), Completeness, Actionability, Coherence

### Rename
No rename.

## 2026-03-19

### Summary
Removed 19 lines of duplicated guidance (conflict escalation, cross-surface coherence) and redistributed the one unique idea. Sharpened evaluation mode for non-runnable surfaces.

### Changes
- Removed Cross-Agent Conflicts subsection (duplicated in "What You Are NOT" staff-engineer bullet)
- Removed System-Level Design Thinking section (restated Design System Coherence and Content Design)
- Added cross-surface journey mapping bullet to Responsibility 4
- Renamed Responsibility 5 from "Alignment and Content Design" to "Content Design"
- Clarified evaluation mode workflow for non-runnable surfaces
- [Coherence] Replaced "orchestrator" with "user or team lead" (4 occurrences)
- [Coherence] Added missing `permissionMode: dontAsk` to frontmatter

### Dimensions Evaluated
Consolidation & Trimming (primary), Actionability, Completeness, Role Realism, Coherence

### Rename
No rename.

## 2026-03-19

### Summary
Added Operating context paragraph to align with the pattern established across all other agents.

### Changes
- Added "Operating context" paragraph explaining stateless agent execution model, adapted to UX designer workflows

### Dimensions Evaluated
Boundary Clarity (cross-agent coherence)

### Rename
No rename.

## 2026-03-19

### Summary
Trimmed 25 lines through consolidation of redundant philosophy, anti-patterns, and system-level sections. Added "Check Specs Before Designing" section to align with team-wide pattern.

### Changes
- Removed Communication Style section (non-executable AI guidance)
- Removed Alignment Practices subsection (generic reasoning a capable LLM already has)
- Compressed Decision-Making Framework, Managing Ambiguity, and Migration/Strategic sections
- Collapsed 6 redundant anti-patterns that restate existing principles and workflow steps
- Added "Check Specs Before Designing" section matching other agents' pattern
- Merged migration concerns into Design System Coherence Evolution bullet

### Dimensions Evaluated
Consolidation & Trimming (primary), Spec Alignment, Completeness, Actionability

### Rename
No rename.

## 2026-03-19

### Summary
Major consolidation from 1104 to 318 lines. Compressed verbose sections, collapsed output templates, converted surface expertise to reference table, removed non-actionable mentorship section.

### Changes
- Converted surface-specific expertise from 8 subsections (76 lines) to compact reference table (12 lines)
- Collapsed design spec format from verbose bullets to single-line-per-section descriptions
- Removed Mentorship section — behaviors already enacted through spec/review quality
- Consolidated Design Review from 134 to 18 lines
- Compressed Research, Design System, Design QA, System-Level Thinking, and How You Work sections

### Dimensions Evaluated
Consolidation & Trimming (primary), Actionability, Role Realism

### Rename
No rename.
