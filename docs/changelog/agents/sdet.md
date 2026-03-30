# Changelog: sdet

## 2026-03-30

### Summary
Added rigorous honest quality gatekeeper directive, compressed Mermaid subsection and "When NOT to consult" list, tightened Pre-Flight gate. Net: +1 line.

### Changes
- Added "Quality stance" directive: act as rigorous honest quality gatekeeper, challenge inadequate coverage, prioritize correctness over agreeableness, explain critiques with alternatives
- Compressed Mermaid Diagrams subsection from 5 lines + header to 2-line inline directive
- Compressed "When NOT to consult" from 4-line list to 2-line inline directive
- Tightened Pre-Flight standalone mode (-1 line)
- [Coherence] Standardized heading from "CRITICAL" to "MANDATORY: Pre-Flight Goal-Alignment Gate"

### Dimensions Evaluated
Role Realism (primary — mentor directive), Consolidation & Trimming, Actionability, Boundary Clarity, Completeness, Capability Growth, Spec Alignment, Rename — all 8 evaluated

### Rename
No rename.

## 2026-03-29

### Summary
Added TaskCreate/TaskUpdate/TaskList/TaskGet to frontmatter and verification workflow, compressed cross-communication observability, proactive intelligence, delegation protocol, and testing philosophy. Net: -7 lines.

### Changes
- Added task coordination tools to frontmatter and multi-step verification guidance
- Compressed cross-communication observability from 6 to 3 lines
- Compressed proactive quality intelligence from 5 to 3 lines
- Tightened greenfield step 7 (-1 line)
- Compressed Delegation Protocol to inline format (-3 lines)
- Trimmed testing philosophy truism (-2 lines)
- [Coherence] Consolidated standalone Delegation Protocol into /vote section (aligned with staff-engineer/ux-designer pattern)

### Dimensions Evaluated
Consolidation & Trimming (primary), Completeness, Actionability, Coherence (Phase 2), all 8 evaluated

### Rename
No rename.

## 2026-03-29

### Summary
Fixed Docket CLI reference inaccuracies (voter defaults, missing reopen/domain-tag/limit), compressed Pre-Flight Goal-Alignment Gate and Delegation Protocol, added --quiet flag awareness.

### Changes
- Fixed `docket vote cast` flags to show optional defaults (--voter defaults to git user.name)
- Added `docket issue reopen` as separate line and `--domain-tag`/`--limit` to vote list CLI reference
- Removed ambiguous `/ reopen <id>` from move line (reopen is its own command)
- Compressed Pre-Flight Goal-Alignment standalone mode from 8 lines to 2
- Compressed Delegation Protocol from 8 lines to 4
- Added `--quiet` flag note to Execution Workflow
- [Coherence] Restored required flags on `vote cast` (--confidence, --domain-relevance, --findings, --role) to match all other agents

### Dimensions Evaluated
Completeness (primary), Consolidation & Trimming, Actionability, Capability Growth, Role Realism, Boundary Clarity, Spec Alignment, Rename — all 8 evaluated

### Rename
No rename.

## 2026-03-21

### Summary
Added cross-communication observability (Docket logging for BLOCK/coverage-gap/vote), fixed operating context to acknowledge project memory, added --findings-json to vote cast, trimmed testing philosophy and shutdown handling.

### Changes
- Added cross-communication observability: log BLOCK, coverage-gap, and vote interactions as Docket comments
- Fixed operating context to acknowledge `memory: project` instead of claiming stateless
- Added `--findings-json` flag to `docket vote cast` CLI reference
- Trimmed Testing Philosophy opener (redundant with Risk-Based Prioritization)
- Compressed Shutdown Handling from 3 lines to 2

### Dimensions Evaluated
Capability Growth & Cross-Communication (primary), Completeness, Consolidation & Trimming, all 8 evaluated

### Rename
No rename.

## 2026-03-20

### Summary
Added `reopen` and `log` docket commands to workflow, compressed Docket CLI Reference and Per-Session Metrics, added rework return step.

### Changes
- Added `docket issue log <id>` to Review context step for activity history
- Added step 6 "Return for rework" with `docket issue reopen` for BLOCK scenarios
- Compressed Docket CLI Reference from 15 lines to 9 (removed inline descriptions, merged related commands)
- Compressed Per-Session Metrics (removed restated testing.md content)

### Dimensions Evaluated
Completeness, Consolidation & Trimming, Actionability

### Rename
No rename.

## 2026-03-20

### Summary
Merged Block/Accept Criteria into Verification Workflow, compressed greenfield edge-case steps, removed standalone test code review section (boundary overlap with @staff-engineer code review), added coverage-gap escalation trigger.

### Changes
- Merged Block/Accept Criteria section into Verification Workflow step 6 (eliminates standalone section)
- Compressed greenfield steps 7-9 into single conditional step
- Removed "Reviewing @senior-engineer Test Code" section (duplicates test quality principles already in agent, overlaps with @staff-engineer's code review boundary)
- Reframed test code review sentence in "What You Are NOT" to match actual verification boundary
- Added "Notify on coverage gap" cross-communication trigger for @senior-engineer and @project-manager
- Added `skills: [vote]` frontmatter (coherence fix — body references /vote but frontmatter didn't declare it)

### Dimensions Evaluated
Consolidation & Trimming (primary), Boundary Clarity, Cross-Communication, Completeness, Role Realism, Actionability, Spec Alignment, Rename

### Rename
No rename.

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
