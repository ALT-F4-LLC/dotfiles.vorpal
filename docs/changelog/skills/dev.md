# Changelog: dev

## 2026-05-05

### Summary
Phase 2 coherence fix: unified CRITICAL banner format with evolve-* skills — promotes no-sub-agents rule to top-of-file alongside no-commit rule for visibility at first-look location.

### Changes
- Replaced top-of-file CRITICAL banner with unified two-rule format covering both no-commit and no-sub-agents prohibitions (parity with evolve-agents/evolve-skills line 12)

### Dimensions Evaluated
Coherence, Orchestration & Agent Teams

### Rename
No rename.

## 2026-05-05

### Summary
Coherence pass: aligned phase-verification on canonical `docket plan` (matches CLI help "execution plan with phased grouping" and step 10 usage) instead of stale `docket board`. Trimmed two micro-redundancies in Argument Handling and step 8 shutdown caveat. Net 401→400.

### Changes
- Replaced `docket board --json` with `docket plan --json` in Planning Phase Guard for consistency with step 10 and CLI audit
- Trimmed downstream-step pointer from Argument Handling (pre-flight is read regardless)
- Removed step 8 trailing shutdown caveat — step 9 owns the full timing matrix

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-05-05

### Summary
AskUserQuestion adoption pass — converted four free-text operator decision points (existing-issues handling, re-plan on divergence, review-fix and bug-fix loop escalations) to structured-options prompts; goal-verification now uses pre-generated candidate options derived from `{work}` with free-text fallback. Net 395→401.

### Changes
- Goal verification: pre-generate candidate goals/scope as options with "None match" free-text fallback
- Existing-issues: AskUserQuestion (Extend/Start fresh/Cancel)
- Re-plan-on-divergence: operator decision via AskUserQuestion (Re-plan/Adjust/Pause)
- Review-fix and bug-fix loop limits: AskUserQuestion with structured next-step options instead of free-text escalation

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-05-05

### Summary
General review pass adopting Phase 0 features judiciously: confirmed `TeammateIdle` already in use, rejected speculative additions (Monitor, hooks, ${CLAUDE_*}) that did not earn their place per Content Gate. Trimmed 4 redundancies — collapsed standalone "Resuming Mid-Execution" subsection into the Planning Phase Guard, removed vacuous Orchestration Patterns intro and @sdet template meta-line, and deferred vote-delegation mechanics to the /vote skill. Net 408→395.

### Changes
- Collapsed "Resuming Mid-Execution" subsection into Planning Phase step 4 Guard — single source of truth for resume logic
- Removed redundant "Choose the pattern..." preamble before pattern subsections — decision tree above already directs
- Removed @sdet template meta-instruction — template's conditional fields already convey scope guidance
- Compressed "Handling Delegation Requests" to invoke `Skill(vote, "{vote_id}")` rather than re-specifying vote mechanics — eliminates duplication that can drift between dev and /vote

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-05-04

### Summary
General Over-Engineering pass at 422 lines: trimmed verbose Argument Handling, compressed Pre-flight goal verification prose, removed non-behavioral compaction rule, and de-duplicated six-dimensions enumeration that the @staff-engineer agent file already owns. Net 422→408.

### Changes
- Compressed Argument Handling from 10 lines to 3 (removed worked example and obvious substitution mechanics)
- Compressed Pre-flight step 1 from 6 lines to 1 (removed hand-coded vague-example list and HARD GATE rehearsal)
- Removed Rule 3 "Preserve context across compaction" — generic LLM advice, not behavioral
- De-duplicated six review dimensions enumeration in Code Review template (already in @staff-engineer agent spec)
- [Phase 2 coherence] Stripped unverifiable "v2.1.111 stall detection" parenthetical from Stall & Crash Recovery

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-04-22

### Summary
Added explicit crash/stall recovery for the 5-agent team (operator's #1 pain), trimmed delegation-protocol and consensus-trigger sections that duplicated the `/vote` skill, pruned redundant Rules and Team Lead preamble, and connected @ux-designer into the SendMessage graph. Net 454→422.

### Changes
- Added Teammate Stall & Crash Recovery subsection: detection signals (stuck TaskList entry, unanswered SendMessage, stuck docket issue), respawn procedure with resume preamble, shutdown-ack timeout (60s → proceed)
- Collapsed Handling Delegation Requests from full protocol spec to thin pointer into `/vote` skill's Reviewer Independence Enforcement
- Removed 4 of 6 Rules that duplicated Pre-flight/Execution/@senior-engineer template; kept cross-communication, fail-loud (with stall-respawn mention), and compaction recovery
- Compressed Team Lead preamble + removed self-referencing "Team Lead (you)" row from Team Structure table
- Compressed Consensus Integration trigger table into a single sentence pointing to `/vote` criticality rules
- Kept @ux-designer alive through implementation + added SendMessage channel for design-intent questions
- Phase 2 coherence: added `protocol_version: "1"` to documented delegation_request fields (parity with vote schema), added `TeammateIdle` hook signal to Stall & Crash Recovery detection

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-04-16

### Summary
Dimension 5 orchestration fixes: unified "advisor" lifecycle, explicit @project-manager shutdown timing, forwarded review findings into @sdet prompt, tightened vague SendMessage triggers. Addresses operator feedback on coordination clarity. Net 457→454.

### Changes
- Consolidated Design Phase steps 2-3: advisor is always persistent, TDD assignment varies by task size (fixes large-task ambiguity)
- Added `{If review completed: ...}` review-findings handoff to @sdet template
- Replaced "when needed" with concrete conditions in @sdet SendMessage trigger
- Added PM shutdown at plan-approval in step 7; added PM to wrap-up shutdown as safety net
- Compressed @senior-engineer team-context block from 5 to 3 lines
- Coherence: aligned vote-id placeholders with canonical `{vote-id}` — replaced `{proposal-id}` in `docket vote commit` example and `<vote_id>` shell placeholder in Delegation Protocol

### Dimensions Evaluated
Orchestration & Agent Teams (primary), Over-Engineering, Coherence, Actionability, Completeness, Skill Design Quality, Spec Alignment, Rename

### Rename
No rename.

## 2026-04-16

### Summary
Removed redundant per-template re-verification sentence (6 duplicates), collapsed UX-Heavy Task's recapitulation of Medium Task, compressed PM team-context and simplification-pass prose. Net -15 lines.

### Changes
- Removed "The operator's goal has been pre-verified..." line from all 6 spawning templates (-6) — duplicates agent system prompts
- Consolidated UX-Heavy Task: dropped 4-step list recapitulating Medium Task (-5)
- Compressed @project-manager "Team context" block from 3 lines to 1 (-2)
- Compressed Review Phase simplification-pass prose from 4 lines to 2 (-2)

### Dimensions Evaluated
Over-Engineering (primary), Skill Design Quality, Actionability, Completeness, Coherence, Orchestration & Agent Teams, Spec Alignment, Rename

### Rename
No rename.

## 2026-04-06

### Summary
Fixed critical orchestration gap: team agents lacked explicit sub-agent spawning prohibition in spawning templates. Added preamble, overrode @staff-engineer /vote behavior, completed team table constraints.

### Changes
- Added sub-agent prohibition preamble to Spawning Templates section (+2 lines)
- Added /vote delegation override to @staff-engineer TDD template (+1 line)
- Added "cannot spawn sub-agents" to @project-manager and @senior-engineer table rows
- Removed redundant delegation blockquote from Consensus Integration (-2 lines)
- Fixed Rule 4 "invoke" → "request" for /vote consistency

### Dimensions Evaluated
Orchestration & Agent Teams, Over-Engineering, Skill Design Quality, Actionability, Completeness, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-03-30

### Summary
Trimmed description from 800 to 230 chars (250-char cap). Compacted delegation response section. Net -11 lines.

### Changes
- Trimmed description to 230 chars, moved trigger phrases out (-7 lines)
- Merged delegation response paragraph with unknown-skills line, removed redundant blockquote (-4 lines)

### Dimensions Evaluated
Skill Design Quality, Actionability, Over-Engineering, Completeness, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-03-30

### Summary
Added honest mentor directive for the Team Lead orchestrator role. Compressed Rules section by merging redundant entries already covered in Execution Workflow.

### Changes
- Added "Rigorous orchestration over agreeability" directive to Team Lead role definition (+4 lines)
- Compressed Rules from 9 items to 5 by merging redundant team-setup, parallelism, loop-limit, and cleanup rules (-5 lines)

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-03-29

### Summary
Trimmed redundancy from spawning templates — removed shared-rules preamble and agent-definition duplicates from @ux-designer and @staff-engineer templates.

### Changes
- Removed "Shared rules" preamble from Spawning Templates (duplicates agent definitions and line 18, -5 lines)
- Compacted @ux-designer template requirements (3 of 6 lines duplicated agent definition, -3 lines)
- Compacted @staff-engineer TDD template requirements (2 of 6 lines duplicated agent definition, -2 lines)

### Dimensions Evaluated
Skill Design Quality, Actionability, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.


## 2026-03-21

### Summary
Added operator observability rule for cross-agent communication and vote events. Compacted delegation request handling.

### Changes
- Added Rule 6 requiring team lead to surface cross-communication and /vote events to the operator (+3 lines)
- Compacted Handling Delegation Requests vote steps and response format (-4 lines)
- Renumbered Rules 6-8 to 7-9

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-03-20

### Summary
Major consolidation: compressed Delegation Requests (-52 lines), merged @sdet templates (-20 lines), tightened decision trees and failure handlers.

### Changes
- Collapsed Delegation Requests from 81 to 18 lines (protocol spec → compact reference)
- Merged dual @sdet templates into single parameterized template (-20 lines)
- Compacted consensus trigger decision tree (-5 lines)
- Tightened pattern decision tree questions (-4 lines)
- Removed Extending an Existing Plan sub-section (-7 lines)
- Compacted Handling Failures and Resuming Mid-Execution
- Added docket vote CLI flag hints (+2 lines)

### Dimensions Evaluated
Over-Engineering (primary), Completeness, Actionability

### Rename
No rename.

## 2026-03-20

### Summary
Integrated `docket plan` and `docket vote commit` from CLI audit, attached file scoping via `-f` flag, trimmed redundancies.

### Changes
- Replaced `docket board --json` with `docket plan --json` for phase verification
- Added `docket vote commit` after `/vote` approval to finalize audit trail
- Added `docket issue create -f` guidance for structured file scoping
- Removed redundant "via Bash" from pre-flight
- Folded TDD exception into Medium Task question (-1 line)
- Removed redundant wrap-up board check (-1 line)

### Dimensions Evaluated
Completeness, Over-Engineering, Actionability, Spec Alignment

### Rename
No rename.

## 2026-03-20

### Summary
Added PM-to-advisor SendMessage trigger, compacted redundant patterns across templates and failure handlers.

### Changes
- Added Team context block to @project-manager template with SendMessage to advisor (+3 lines)
- Compacted duplicate "Assign task via TaskUpdate" in Design Phase steps (-2 lines)
- Removed redundant "via Bash" from template rules (covered by shared rules block)
- Simplified Pre-flight to `docket init` only — consensus dir created by /vote on demand
- Merged "Review blockers" and "SDET finds bugs" failure handlers

### Dimensions Evaluated
Orchestration Effectiveness & Cross-Communication, Over-Engineering, Coherence

### Rename
No rename.

## 2026-03-20

### Summary
Added `effort: max` frontmatter and `isolation: worktree` for parallel implementation safety. Removed redundant callout, duplicate commit warning, and compacted wrap-up.

### Changes
- Added `effort: max` frontmatter for complexity-appropriate reasoning
- Added `isolation="worktree"` to @senior-engineer spawn template (eliminates file conflict risk)
- Removed Persistent Advisor Pattern callout block (-5 lines, redundant with surrounding steps)
- Removed duplicate "Do NOT commit" from @ux-designer template (-1 line, covered by shared rules)
- Compacted wrap-up shutdown bullets into Rule 8 reference (-2 lines)

### Dimensions Evaluated
Skill Design Quality, Completeness, Over-Engineering, Orchestration Effectiveness

### Rename
No rename.

## 2026-03-19

### Summary
Trimmed from 503 to 487 lines. Removed redundant Consensus Phase Integration section, compacted consensus intro, and removed duplicate guidance.

### Changes
- Removed Phase Integration bullets from Consensus section (-11 lines, tautological with trigger tree)
- Compacted consensus intro paragraph from 3 lines to 1
- Removed duplicate "When uncertain, ask the user" (already in Pre-flight)
- Tightened team structure intro line

### Dimensions Evaluated
Over-Engineering (primary), Skill Design Quality, Coherence

### Rename
No rename.

## 2026-03-19

### Summary
Coherence fixes: added `allowed-tools` frontmatter, corrected `argument-hint` convention, added TeamCreate/TeamDelete to allowed-tools.

### Changes
- Added `allowed-tools` frontmatter to match convention across all orchestrator skills
- Changed `argument-hint` from `[work]` to `<work>` (angle brackets for required arguments)
- Added TeamCreate/TeamDelete to `allowed-tools`

### Dimensions Evaluated
Coherence with Other Skills, Skill Design Quality

### Rename
No rename.

## 2026-03-19

### Summary
Trimmed from 556 to 481 lines. Removed Docket CLI Quick Reference, replaced ASCII diagram with one-liner, extracted shared template boilerplate, consolidated rules, and compacted UX-Heavy Task pattern.

### Changes
- Removed Docket CLI Quick Reference (-32 lines, non-behavioral reference)
- Replaced ASCII team diagram with one-liner, kept table (-13 lines)
- Extracted shared template rules into preamble above Spawning Templates
- Consolidated 13 rules to 8 by removing those restated in workflow/templates
- Compacted UX-Heavy Task to reference Medium Task pattern

### Dimensions Evaluated
Over-Engineering (primary), Orchestration Effectiveness, Coherence

### Rename
No rename.

## 2026-03-19

### Summary
Added pattern decision tree, loop escalation limits, discovered-context propagation, and large-review splitting; removed Collision Prevention section.

### Changes
- Replaced heuristic pattern selection with ordered decision tree
- Added "Extending an Existing Plan" subsection to Pre-flight
- Added empty-diff guard to Code Review template
- Added Discovered comment forwarding between phases
- Added review-fix and bug-fix loop limits (2 cycles then escalate)
- Added large-review splitting guidance for 20+ file changes
- Removed redundant Collision Prevention section

### Dimensions Evaluated
Actionability, Completeness, Over-Engineering, Orchestration Effectiveness

### Rename
No rename.

## 2026-03-19

### Summary
First evolution cycle. Added Large Task pattern, Full Verification template, resume guidance, and consolidated Roles section.

### Changes
- Added Large Task orchestration pattern for multi-TDD work
- Added Full Verification @sdet template for cross-issue testing
- Added resume/continuation guidance in Pre-flight
- Consolidated Roles prose into compact table
- Added practical concurrency limit (5 agents per turn)

### Dimensions Evaluated
Actionability, Completeness, Over-Engineering, Orchestration Effectiveness

### Rename
No rename.
