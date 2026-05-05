# Changelog: evolve-skills

## 2026-05-05

### Summary
Adopted `paths:` frontmatter (new Claude Code feature, Apr 2026) and `Monitor` tool for stall detection. Removed third restatement of 500-line budget, merged top-of-file critical-rules blockquotes, and made Phase 1→Phase 2 cross-cutting handoff concrete. Net 304→303.

### Changes
- Added `paths:` frontmatter (.claude/skills/**, skills/**, docs/changelog/skills/**) — declares write surface to harness
- Added `Monitor` to allowed-tools — supports Rule 10's event-driven stall detection
- Merged commit-ban and no-nested-agents blockquotes into one critical-rules block — both are spawned-teammate invariants, fragmenting them obscured the region
- Removed redundant "## Size Budget" block from Phase 1 template — `{mode}` substitution and Output Format's `NET_LINES:` field already carry the rule
- Made Phase 1 cross-cutting handoff concrete — orchestrator appends cross-cutting findings to running notes and passes them verbatim into the Phase 2 prompt's "Phase 1 Coherence Issues" section
- [Phase 2] Updated Rule 10 stall detection to reference TeammateIdle notification + Monitor stream silence (replaces 10-minute polling heuristic) — parity with evolve-agents Crash & Stall Recovery

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-05-04

### Summary
Trim pass: removed restated orchestrator-identity content, vague Rule #12, vague Phase 2 "bidirectional" check, and redundant size/priority restatements in Phase 1 template. Consolidated Pre-flight inventory steps. Net 313→304.

### Changes
- Tightened orchestrator-identity paragraph — removed restatement of Phase 1 workflow steps and the Behavioral-failing "self-evolution is expected" sentence
- Removed Rule #12 (Self-correct on mediocre results) — no concrete trigger; Rules #11 and #7 cover its intent
- Removed "verify bidirectional triggers where applicable" from Phase 2 cross-communication checks — fails Concrete (no defined "applicable" criterion)
- Consolidated Pre-flight steps 4 and 8 into one `wc -l` inventory step
- Removed redundant "Build on strengths, don't rewrite" from Phase 1 Requirements (duplicates Rule #7)
- Removed "SIZE CONSTRAINT" half of merged blockquote (third restatement of 500-line rule; broken step reference after consolidation)
- Tightened Phase 1 Size Budget block — removed TRIM/BALANCED definitions already passed via `{mode}` substitution
- Removed duplicate "HIGHEST PRIORITY / offset" reminder from Phase 1 Your Task section
- [Phase 2 coherence] Stripped unverifiable "v2.1.111 stall detection" parenthetical from Rule #10

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-04-22

### Summary
Hardened crash recovery: expanded Rule #10 with concrete stall/crash detection signals and fail-forward behavior when shutdown_response doesn't land. Resolved contradiction between the old "review directly" fallback and the orchestrator-only-coordinates invariant. Addresses operator pain: agents crashing silently and needing manual restart. Net 316→313.

### Changes
- Rule #10 now defines: 3 failure-detection signals (Agent error return, 10+ min stalled task per v2.1.111 OR `TeammateIdle` hook, no SendMessage response), shutdown-timeout behavior (proceed after one turn if no shutdown_response), single re-spawn with name suffix, and fail-forward ("No review performed" changelog entry) rather than the self-contradicting "review directly"
- Lifecycle rules document shutdown-ack timeout so phases don't block on dead agents
- Removed "Rigorous honesty" blockquote — redundant with Rule #11 and Phase 1 template's reviewer-side directive; merged "Self-evolution" and "SIZE CONSTRAINT" into one blockquote
- Phase 2 coherence: added `TeammateIdle` hook signal to Rule #10 for parity with evolve-agents stall detection

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-04-16

### Summary
Centralized agent lifecycle, made Phase 1 SendMessage triggers explicit, added Phase 2 handoff gate, removed duplicate rules. Addresses operator feedback that agent coordination felt unclear. Net 328→316.

### Changes
- Added "Agent Lifecycle" rules (single source for shutdown + report capture); Phase 0 / Wrap-up now reference them instead of inlining shutdown JSON
- Replaced vague "Route cross-cutting findings from SendMessage to peers" with explicit triggers: orchestrator-only relay, cross-cutting/delegation/blocker categories
- Phase 2 gate made explicit: tasks completed + edits applied + teammates shut down
- Removed duplicate Rule 6 ("Only orchestrator edits") and Rule 13 ("Clean up"); renumbered
- Coherence: added pointer to `skills/vote/` Delegation Protocol in "No nested agents" blockquote so teammates can resolve delegation_request schema without duplicated content

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-04-16

### Summary
Removed dead `{focus_areas}` substitution variable from Phase 1 template and promoted Over-Engineering to HIGHEST PRIORITY in the main dimension list to match template enforcement.

### Changes
- Removed `{focus_areas}` variable from Phase 1 substitution list — never interpolated; redundant with `{experience_feedback}`
- Dimension 4 now labeled "Over-Engineering (HIGHEST PRIORITY)" with offset-here reminder, aligning main list with Phase 1 template and evolve-agents dim-5 treatment

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-04-06

### Summary
Added anti-sub-agent-spawning instructions to orchestrator identity, Phase 1 template, Phase 2 template, and consolidated verbose rules. Removed "vote invocations" from wrap-up report.

### Changes
- Added "No nested agents" blockquote at orchestrator identity level (+2 lines)
- Added "No sub-agents" rule to Phase 1 spawning template Requirements (+1 line)
- Added anti-spawning instruction to Phase 2 coherence reviewer template (+1 line)
- Removed "vote invocations" from wrap-up report list (contradicts sub-agent prevention)
- Consolidated rules 14-15 verbose phrasing (-3 lines)

### Dimensions Evaluated
Orchestration & Agent Teams, Coherence, Over-Engineering, Completeness, Skill Design Quality, Actionability, Spec Alignment, Rename

### Rename
No rename.

## 2026-03-30

### Summary
Trimmed description from 758 to ~185 chars to meet 250-char cap; removed redundant experience feedback section from Phase 1 template.

### Changes
- Trimmed description from 758 chars to ~185 chars — 250-char cap per Claude Code docs, moved details to body
- Removed duplicate `## Operator Experience Feedback` from Phase 1 template — already present in template header
- Fixed Phase 0 and wrap-up shutdown syntax to use full structured SendMessage format (coherence with evolve-agents)

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-03-30

### Summary
Added rigorous honest mentor directives to orchestrator identity and Phase 1 template; trimmed docs-researcher checklist, consolidated rules, fixed role paragraph structure.

### Changes
- Added honest mentor directive to orchestrator identity block — enforces Content Gate rigor
- Fixed role paragraph structure — reunited split paragraph and repositioned honest mentor blockquote (coherence with evolve-agents)
- Added honest mentor reinforcement to Phase 1 spawning template task section
- Removed vague "Also check" list from docs-researcher template
- Consolidated rules 11-12 (Fail loud + Timeout fallback) into single rule, renumbered

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

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
