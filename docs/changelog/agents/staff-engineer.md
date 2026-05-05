# Changelog: staff-engineer

## 2026-05-05

### Summary
Consolidation pass: compressed "What You Are NOT" to dense one-liners (matches senior-engineer style), trimmed Pre-Flight Gate prose, merged TDD workflow status-transition steps, tightened Consensus Voting block, fused review escalation triggers. Net: -31 lines (317→286).

### Changes
- Compressed "What You Are NOT" from 13 to 5 lines (kept @senior-engineer feedback nuance)
- Trimmed Pre-Flight Gate philosophy + mode block from 14 to 6 lines
- Merged TDD workflow steps 8/9/10/11 into tighter status-transition flow with @project-manager + @senior-engineer dual-notify on accepted
- Compressed Consensus Voting team-mode block: inlined JSON delegation payload, condensed "Additional uses" and Vote observability
- Fused "Re-plan over incremental patches" and "2-cycle hard limit" into single "Escalate, do not loop" block
- [Phase 2] Added 3 incoming-trigger entries closing inverse-trigger gaps: @senior-engineer TDD-deviation/shared-interface/arch-decision consult, @ux-designer feasibility/perf/TDD-constraint consult, @ux-designer systemic-QA / cross-surface-precedent escalation

### Dimensions Evaluated
All 8: Consolidation & Trimming (PRIMARY), Boundary Clarity, Actionability, Capability Growth & Cross-Communication, Spec Alignment, Role Realism, Completeness, Rename

### Rename
No rename.

## 2026-04-19

### Summary
Added "No Guessing" top-level section covering ADR decisions, spec conventions, test outcomes, and API/pattern existence — staff role is uniquely prone to guessing across all four responsibilities. Added 2-cycle review-fix hard limit aligned with `docs/spec/review-strategy.md` §4.5. Compressed Honest Technical Critique.

### Changes
- Added "No Guessing" section — STOP and research before producing TDDs/reviews/ADRs; concrete tools per uncertainty type (Read, Bash, Grep); silence beats unverified claims
- Added 2-cycle hard limit to Review Approval Judgment (matches `docs/spec/review-strategy.md` §4.5)
- Compressed Honest Technical Critique (6 → 4 lines)
- [Phase 2] Added @project-manager spike-ambiguity/architectural-guidance incoming trigger — reply proceed/adjust/need-TDD to unblock decomposition

### Dimensions Evaluated
All 8: Capability Growth (primary — No Guessing), Spec Alignment (2-cycle limit), Consolidation, Role Realism, Actionability, Boundary Clarity, Completeness, Rename

### Rename
No rename.

## 2026-04-16

### Summary
Cross-communication pass: rewrote Proactive Communication into 10 concrete "situation → action" SendMessage triggers (5 new). Added Incoming triggers for reciprocal handling. Trimmed intro; removed duplicated Cross-team notifications. Added `docket issue graph --mermaid` and `docket stats` to review Gather Context. Net: -13 lines.

### Changes
- PRIMARY: Rewrote Proactive Communication — 10 concrete triggers naming peer + payload (was 6 vague). New: consult-@sdet-pre-test-infra-review, PM-scope-delta, re-plan dual-notify (@senior + @PM), spec-drift dual-action, ADR `*` broadcast for cross-cutting, TDD-accepted dual-notify (@PM + @senior)
- [Phase 2] Added Incoming triggers block: @sdet BLOCK priority re-review, @sdet TDD-not-accepted verify request, @senior test-infra flag → consult @sdet before reviewing
- Trimmed intro (archetype list, core-responsibilities restatement) and removed redundant Cross-team notifications (absorbed)
- Added `docket issue graph --mermaid <id>` and `docket stats` to Review Gather Context step

### Dimensions Evaluated
All 8: Cross-Communication (GOAL — primary), Consolidation (HIGHEST priority), Capability Growth, Completeness, Role Realism, Actionability, Boundary Clarity, Spec Alignment, Rename

### Rename
No rename.

## 2026-04-16

### Summary
Compressed Pre-Flight Gate mode descriptions and "When to Create a TDD" bullets; added proactive consultation triggers for @sdet (TDD Testing Strategy) and @ux-designer (user-facing surfaces) before TDD finalization. Net: -7 lines.

### Changes
- Compressed Pre-Flight Goal-Alignment Gate Standalone/Team mode descriptions
- Compressed "When to Create a TDD" from 5 verbose bullets to 5 concise bullets
- Added two proactive SendMessage consultation triggers: consult @sdet on Testing Strategy and @ux-designer on user-facing TDD surfaces before finalizing

### Dimensions Evaluated
All 8: Consolidation & Trimming (primary), Capability Growth & Cross-Communication, Role Realism, Actionability, Boundary Clarity, Completeness, Spec Alignment, Rename

### Rename
No rename.

## 2026-04-06

### Summary
CRITICAL: Encoded mandatory TDD question-resolution workflow — open questions resolved via AskUserQuestion, secondary @staff-engineer review, status tracking. Added `status` field to TDD frontmatter. Folded Advisory Mode. Net: -5 lines.

### Changes
- **CRITICAL**: Replaced TDD workflow steps 7-8 with steps 7-11: save(draft) → resolve questions(AskUserQuestion) → secondary review → vote → update status(accepted)
- Added `status` field to TDD frontmatter template (draft | questions-resolved | in-review | accepted | superseded)
- Updated "Risks & Open Questions" — questions must be resolved before vote
- Compressed Handoff section — PM notification moved to workflow step 11
- Folded Advisory Mode into Responsibility 3 opening

### Dimensions Evaluated
All 8: Completeness (primary — question-resolution workflow), Actionability, Consolidation & Trimming, Role Realism, Boundary Clarity, Capability Growth, Spec Alignment, Rename

### Rename
No rename.

## 2026-04-06

### Summary
Fixed `/vote` team-nesting bug (operator feedback): team-mode now delegates to orchestrator instead of invoking Skill directly. Removed Docket Vote CLI Reference block (agent can run `docket vote --help`). Compressed Mermaid Diagrams section. Net: -20 lines.

### Changes
- **CRITICAL**: Rewrote `/vote` section as "Consensus Voting for TDD Approval" — team mode delegates via SendMessage, standalone invokes Skill directly. Prevents nested agent teams.
- Removed 15-line Docket Vote CLI Reference block (redundant with `docket vote --help`)
- Compressed Mermaid Diagrams from 5 to 2 lines
- Updated TDD step 8 to reference new section name and team-mode delegation
- Changed Handoff wording from "`/vote` approval" to "vote approval"

### Dimensions Evaluated
All 8: Capability Growth (vote fix — primary), Consolidation & Trimming (CLI ref removal, Mermaid compression), Role Realism, Actionability, Boundary Clarity, Completeness, Spec Alignment, Rename

### Rename
No rename.

## 2026-04-01

### Summary
Added `model: opus[1m]` to frontmatter and Edit tool for incremental doc updates. Settings standardization and coherence fix.

### Changes
- Added `model: opus[1m]` to frontmatter (settings standardization)
- [Coherence] Added `Edit` to tools list (was the only doc-producing agent without it)

### Dimensions Evaluated
All 8: Completeness (frontmatter — primary), Consolidation & Trimming, Role Realism, Actionability, Boundary Clarity, Capability Growth, Spec Alignment, Rename

### Rename
No rename.

## 2026-03-30

### Summary
Added Honest Technical Critique directive establishing posture on intellectual honesty, challenging flawed designs, and avoiding rubber-stamp reviews. Compressed System-Level Thinking, Proactive Communication, and Advisory Mode. Net: +4 lines.

### Changes
- Added "Honest Technical Critique" section after intro, before "What You Are NOT" (+8 lines)
- Compressed System-Level Thinking "Dependencies and incidents" sentence (-2 lines)
- Compressed "When to ASK" in Proactive Communication to single-line cross-reference (-1 line)
- Compressed Advisory Mode from 3 sentences to 2 (-1 line)
- Added review posture cross-reference in Code Review philosophy (0 lines)
- [Coherence] Added `/vote` fallback pattern for when skill is unavailable

### Dimensions Evaluated
Role Realism (primary: honest mentor directive), Consolidation & Trimming, Actionability, Boundary Clarity, Completeness, Capability Growth, Spec Alignment, Rename — all 8 evaluated

### Rename
No rename.

## 2026-03-29

### Summary
Added TaskCreate/TaskUpdate/TaskList/TaskGet to frontmatter, removed speculative Delegation Protocol and redundant Anti-Patterns sections, compressed Shutdown Handling, clarified SDET review boundary. Net: -10 lines.

### Changes
- Added task coordination tools to frontmatter
- Removed Delegation Protocol section (speculative fallback, -6 lines)
- Removed Anti-Patterns section (both bullets restate TDD workflow instructions, -6 lines)
- Compressed Shutdown Handling (-1 line)
- Clarified SDET boundary to include test architecture review

### Dimensions Evaluated
Consolidation & Trimming (primary), Completeness, Boundary Clarity, all 8 evaluated

### Rename
No rename.

## 2026-03-29

### Summary
Updated Docket Vote CLI reference with audit findings (new flags, corrected --voter default), compressed Delegation Protocol from 12 to 3 lines, trimmed System-Level Thinking, added docket issue show to review context gathering.

### Changes
- Updated vote CLI reference: `--voter` now optional (defaults to git user.name), added `--quiet`, `-d/--domain-tag`, `--limit` flags
- Compressed Delegation Protocol from numbered procedure to single-line with fallback note (-7 lines)
- Compressed System-Level Thinking dependencies paragraph (-3 lines)
- Added `docket issue show` to review workflow context gathering step
- [Coherence] Removed `[--quiet]` from `vote result` (global flag, not per-command)
- [Coherence] Added `docket issue log <id> [--limit N]` to CLI reference

### Dimensions Evaluated
All 8: Completeness (CLI gaps filled), Consolidation & Trimming (primary: -8 net), Role Realism, Actionability, Boundary Clarity, Capability Growth, Spec Alignment, Rename

### Rename
No rename.

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
