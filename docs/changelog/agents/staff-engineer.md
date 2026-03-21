# Changelog: staff-engineer

## 2026-03-21

### Summary
Added cross-communication and vote observability, aligned Delegation Protocol with standardized JSON format, trimmed pre-flight and conflicting-feedback passages, folded conflicting feedback into TDD step 4.

### Changes
- Added cross-communication observability to Proactive Communication: summarize inter-agent exchanges for operator
- Added vote observability to /vote section: report vote ID, verdict, and dissenting findings
- Aligned Delegation Protocol with standardized JSON message format (was spec reference, now inline)
- Removed "During execution" block from Pre-Flight Gate (restates Operator Alignment)
- Folded "Conflicting feedback" paragraph into TDD workflow step 4

### Dimensions Evaluated
Capability Growth & Cross-Communication (primary), Consolidation & Trimming, Spec Alignment, all 8 evaluated

### Rename
No rename.

## 2026-03-20

### Summary
Compressed Advisory Mode and Anti-Patterns sections, added `docket plan` reference to review context gathering.

### Changes
- Compressed Advisory Mode from 10 lines to 3 (removed implicit conversation mechanics)
- Removed "Gold plating / bikeshedding" anti-pattern (general knowledge, restated by effort-matching in body)
- Compressed remaining anti-patterns
- Added `docket plan --json` to review workflow context gathering step

### Dimensions Evaluated
Consolidation & Trimming (primary), Completeness

### Rename
No rename.

## 2026-03-20

### Summary
Consolidated /vote section, compressed handoff, removed hardcoded spec count, added TDD revision and scope-change notification triggers, compressed review spec-update instruction.

### Changes
- Merged redundant /vote "REQUIRED" block into existing mandatory statement
- Compressed Handoff to remove restated /vote requirement
- Removed hardcoded "seven" from spec files reference
- Added TDD revision notification trigger for @senior-engineer
- Added scope-change notification trigger for @project-manager in review
- Compressed review spec-update instruction

### Dimensions Evaluated
Consolidation & Trimming (primary), Cross-Communication, Actionability

### Rename
No rename.

## 2026-03-20

### Summary
Compressed Review Workflow step 4, trimmed Advisory Mode to essential bullets, added cross-team review notification triggers for @sdet and @ux-designer, compressed /vote invocation.

### Changes
- Compressed Review Workflow step 4 from 4 sentences to 2 (cross-references Operator Alignment)
- Removed 3 redundant Advisory Mode "How to respond" bullets (covered elsewhere)
- Removed "What to expect" bullet list, replaced with single sentence
- Added cross-team notification triggers after code review (notify @sdet for test gaps, @ux-designer for UX inconsistencies)
- Compressed /vote "How to invoke" from code block to inline example
- [Coherence] Removed vague parenthetical from Advisory Mode opening
- [Coherence] Replaced "Tier 1/2 risk areas" with "high-risk areas" for terminology consistency

### Dimensions Evaluated
Consolidation & Trimming (primary), Capability Growth & Cross-Communication, Coherence

### Rename
No rename.

## 2026-03-20

### Summary
Added effort and memory frontmatter, removed Advisory Mode negative list, compressed System-Level Thinking, tightened status updates, added TDD handoff notification.

### Changes
- Added `effort: max` and `memory: project` frontmatter fields
- Removed Advisory Mode "What NOT to do" list (duplicates "What You Are NOT" constraints)
- Compressed System-Level Thinking from 4 sub-sections to 2
- Tightened status updates to use SendMessage (removed Docket comments reference)
- Added explicit SendMessage notification to @project-manager when TDD is ready for decomposition
- [Coherence] Decoupled Advisory Mode from `dev` skill name to avoid fragile cross-reference

### Dimensions Evaluated
Consolidation & Trimming (primary), Completeness, Capability Growth, Actionability

### Rename
No rename.

## 2026-03-19

### Summary
Compressed redundancy between Operator Alignment and TDD/Communication sections. Trimmed /vote negative list and verbose status updates. Added conflicting feedback resolution guidance.

### Changes
- Compressed TDD workflow step 1 — cross-references Operator Alignment instead of restating it
- Compressed "When to ASK" in Proactive Communication — deduplicated against Operator Alignment
- Compressed status update list from 6 bullets to a single paragraph
- Removed "When NOT to invoke /vote" — obvious inverse of positive list
- Compressed /vote invocation guidance paragraph
- Added conflicting feedback resolution guidance to TDD section
- Clarified TDD step 2 to include reading relevant specs before designing
- [Coherence] Docket comments now conditional ("when an issue exists") for advisory mode
- [Coherence] "user" → "operator" in TDD section (2 instances) for terminology consistency

### Dimensions Evaluated
Consolidation & Trimming (primary), Completeness, Spec Alignment, Coherence

### Rename
No rename.

## 2026-03-19

### Summary
Tightened SDET boundary, removed dead "engineering growth" responsibility, compressed redundant passages, added SendMessage to tool list for inter-agent communication.

### Changes
- Added SendMessage to frontmatter tools for team communication capability
- Compressed SDET boundary bullet from 5 to 3 lines
- Removed "engineering growth" from core responsibilities (no backing section)
- Removed redundant "Omit dependencies" comment from TDD frontmatter template
- Compressed Handoff section to essential instruction only
- Trimmed Dependencies/APIs paragraph — removed generic API design advice
- [Coherence] Replaced "orchestrator" with "user or team lead" (1 occurrence)

### Dimensions Evaluated
Consolidation & Trimming (primary), Completeness, Role Realism, Capability Growth, Coherence

### Rename
No rename.

## 2026-03-19

### Summary
Removed 3 sections that fail Content Gate (Mentorship, Influence/Alignment, Decision-Making Framework). Salvaged incident analysis into System-Level Thinking. Added concrete review context gathering decision tree.

### Changes
- Removed Responsibility 5 (Mentorship) — human social dynamics, not executable
- Removed Influence, Alignment, and Incident Response — salvaged incident analysis into System-Level Thinking
- Removed Decision-Making Framework — general LLM knowledge
- Trimmed anti-patterns from 6 to 3, keeping only agent-executable items
- Added review context gathering decision tree (PR vs branch vs uncommitted vs unspecified)
- Added stateless operating context to intro paragraph
- Removed "calibrate to author's level" from review philosophy

### Dimensions Evaluated
Consolidation & Trimming (primary), Actionability, Completeness, Role Realism

### Rename
No rename.

## 2026-03-19

### Summary
Major consolidation from 1094 to 249 lines. Eliminated pedagogical content a staff-level LLM already embodies while preserving all behavioral instructions, output formats, and team boundaries.

### Changes
- Compressed Code Review from 336 to ~35 lines — removed rubrics, question examples, comment/don't-comment lists
- Compressed TDD format from expanded bullets to compact one-line-per-section reference
- Removed duplicated YAML frontmatter template from Specs section
- Merged Influence/Alignment, Incident Analysis, and Communication Style into one compact section
- Collapsed System-Level Thinking from 94 to ~12 lines

### Dimensions Evaluated
Consolidation & Trimming (primary), Actionability, Boundary Clarity, Role Realism

### Rename
No rename.
