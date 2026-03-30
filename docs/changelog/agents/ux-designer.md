# Changelog: ux-designer

## 2026-03-30

### Summary
Added honest UX critique directive, compressed Decision-Making Framework and /vote critical-cases, added trade-off documentation check to self-validate. Net: -5 lines.

### Changes
- Added "Honest critique over validation" directive after Core responsibilities (+6 lines)
- Compressed Decision-Making Framework from enumerated hierarchy to single-line priority chain (-8 lines)
- Compressed /vote critical-cases from 4-bullet list to single sentence (-3 lines)
- Compressed Design System Coherence intro (-1 line)
- Added trade-off honesty check to self-validate step (+1 line)
- Tightened Research section parentheticals (-1 line)
- [Coherence] Standardized heading to "MANDATORY: Pre-Flight Goal-Alignment Gate"

### Dimensions Evaluated
Completeness (primary — honest critique directive), Consolidation & Trimming, Actionability, Role Realism, Boundary Clarity, Capability Growth, Spec Alignment, Rename — all 8 evaluated

### Rename
No rename.

## 2026-03-29

### Summary
Added TaskCreate/TaskUpdate/TaskList/TaskGet to frontmatter, compressed spec format list, removed vestigial Anti-Patterns and Delegation Protocol sections, deduplicated Handoff. Net: -12 lines.

### Changes
- Added task coordination tools to frontmatter and multi-step design tracking guidance
- Compressed spec format sections 8-10 into single grouped item (-5 lines)
- Removed Handoff duplication with workflow steps 5-6 (-4 lines)
- Folded Anti-Patterns bullet into spec format intro (-3 lines)
- Merged Delegation Protocol into /vote section (-2 lines)
- [Coherence] Added post-/vote notification to @project-manager in Handoff section (aligned with staff-engineer pattern)

### Dimensions Evaluated
Consolidation & Trimming (primary), Completeness, Capability Growth, Coherence (Phase 2), all 8 evaluated

### Rename
No rename.

## 2026-03-29

### Summary
Updated Docket Vote CLI reference with audit-discovered flags, compressed Delegation Protocol and Managing Ambiguity subsection. Net -15 lines.

### Changes
- Updated `vote list` CLI reference with `-d/--domain-tag`, `--limit`, `--quiet` flags
- Fixed `--voter` as optional (defaults to git user.name) in `vote cast` reference
- Compressed Delegation Protocol from 10 lines to 2 (essential behavior preserved)
- Merged Managing Ambiguity subsection into Decision-Making Framework closing sentence (-4 lines)
- [Coherence] Removed `[--quiet]` from `vote list` (global flag, not per-command)

### Dimensions Evaluated
Consolidation & Trimming (primary), Completeness, Actionability, all 8 evaluated

### Rename
No rename.

## 2026-03-21

### Summary
Added observability for cross-communication and vote audit trails, compressed surface table and anti-patterns, added disallowedTools frontmatter to enforce no-edit boundary.

### Changes
- Added Observability paragraph to Inter-Agent Communication: log consultations and votes as Docket comments
- Added vote audit trail guidance to /vote section (log vote ID + outcome)
- Added `disallowedTools: Edit` frontmatter to enforce no-code boundary
- Compressed Surface-Specific Design Considerations table (removed AI/Conversational row, shortened)
- Compressed Anti-Patterns from 2 bullets to 1 (measurement already in spec format)

### Dimensions Evaluated
Capability Growth & Cross-Communication (primary), Consolidation & Trimming, Boundary Clarity, all 8 evaluated

### Rename
No rename.

## 2026-03-20

### Summary
Compressed Vote CLI Reference, Anti-Patterns, Managing Ambiguity, and Research handoff notes. Added explicit docket comment command for issue tracking.

### Changes
- Compressed Docket Vote CLI Reference from 8 to 5 lines (merged related commands)
- Removed "Don't ignore operational signals" anti-pattern (restated by Research section)
- Compressed Managing Ambiguity and Research handoff notes
- Added explicit `docket issue comment add` command to status updates (was referenced but not shown)

### Dimensions Evaluated
Consolidation & Trimming (primary), Actionability

### Rename
No rename.

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
