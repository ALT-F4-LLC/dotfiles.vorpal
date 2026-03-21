# Changelog: sdet

## 2026-03-20

### Summary
Consolidated flaky test management into diagnosis workflow, trimmed redundant philosophy opener, added BLOCK notification trigger and build-as-test greenfield step.

### Changes
- Removed standalone "Flaky Test Management" subsection (already covered by Test Failure Diagnosis step 3)
- Trimmed Testing Philosophy opener (redundant with Risk-Based Prioritization and Review Checklist)
- Added "Notify on BLOCK" cross-communication trigger for @staff-engineer and @senior-engineer
- Added greenfield step 9: recognize build-as-test as existing validation layer (aligns with docs/spec/testing.md)
- [Coherence] Added @ux-designer notification trigger for design spec deviations (bidirectional gap fix)

### Dimensions Evaluated
Consolidation & Trimming (primary), Cross-Communication, Spec Alignment, Completeness, Coherence

### Rename
No rename.

## 2026-03-20

### Summary
Consolidated Operator Alignment into Check Specs preamble, compressed Testing Philosophy, removed inverse /vote guidance, added effort frontmatter, fixed code review boundary coherence.

### Changes
- Merged Operator Alignment section into Check Specs preamble (-12 lines, unique content preserved)
- Compressed Testing Philosophy by removing truisms already in Review Checklist and Test Pyramid
- Removed "When NOT to invoke /vote" list (logical inverse of positive list)
- Added `effort: max` frontmatter for thorough verification reasoning
- Fixed "perform code reviews" to "perform production code reviews" matching frontmatter
- [Coherence] Removed vestigial `docket config` from Session Initialization
- [Coherence] Added `memory: project` frontmatter (aligned with all other agents)

### Dimensions Evaluated
Consolidation & Trimming (primary), Completeness, Boundary Clarity, Coherence

### Rename
No rename.

## 2026-03-19

### Summary
Compressed Inter-Agent Communication section (-20 lines of redundant status/intelligence lists), added greenfield zero-test handling, tightened Test Pyramid prose.

### Changes
- Compressed "Status updates to the operator" 13-line list to 3-line directive
- Compressed "Proactive quality intelligence" 10-line list to 4-line essentials
- Removed redundant "Asking questions about intent" paragraph (covered by Operator Alignment)
- Added step 8 to Greenfield Test Strategy for zero-test-result handling
- Tightened Test Pyramid subsection by removing truism opener
- [Coherence] Frontmatter: "does not perform code reviews" → "does not perform production code reviews"
- [Coherence] Docket comments now conditional ("when working on an issue") for ad-hoc contexts

### Dimensions Evaluated
Consolidation & Trimming (primary), Completeness, Spec Alignment, Coherence

### Rename
No rename.

## 2026-03-19

### Summary
Tightened greenfield strategy to reference spec, removed redundant "Running Tests" subsection, replaced prose review section with actionable checklist.

### Changes
- Updated greenfield strategy to reference `docs/spec/testing.md` as primary input, with fallback for missing specs
- Removed "Running Tests in This Codebase" subsection (redundant with spec-check section and greenfield strategy)
- Replaced prose paragraph in "Reviewing @senior-engineer Test Code" with scannable checklist including deterministic assertions check
- [Coherence] Replaced "orchestrator" with "user or team lead" (2 occurrences)

### Dimensions Evaluated
Actionability, Consolidation & Trimming, Spec Alignment, Role Realism, Coherence

### Rename
No rename.

## 2026-03-19

### Summary
Added stateless operating context, removed non-executable human-process sections (Test Planning, Communication Style), compressed Decision-Making Framework to actionable Block/Accept criteria, fixed formatting artifacts.

### Changes
- Added operating context paragraph explaining stateless subagent execution model
- Removed Test Planning & Incident Analysis section (human processes: timeline negotiation, production incident observation)
- Removed Communication Style section (generic LLM output-quality instructions with zero behavioral impact)
- Compressed Decision-Making Framework to Block/Accept criteria (removed generic 6-factor list)
- Fixed double horizontal rule formatting artifacts

### Dimensions Evaluated
Role Realism, Actionability, Consolidation & Trimming (primary)

### Rename
No rename.

## 2026-03-19

### Summary
Major consolidation from 867 to 308 lines. Merged verbose responsibility sections, eliminated redundant and generic content, compressed all templates and prose.

### Changes
- Merged Responsibilities 1-3 into single "Test Architecture & Infrastructure" section
- Removed Responsibility 7 (Test Environment & Data Management) — generic advice implied by existing principles
- Removed Cross-Cutting Quality Concerns and Anti-Patterns sections — generic SDET knowledge
- Compressed Mentorship to focused test code review guidance
- Compressed Docket workflow, verification template, decision framework, and all prose

### Dimensions Evaluated
Consolidation & Trimming (primary), Actionability, Boundary Clarity, Spec Alignment

### Rename
No rename.
