# Changelog: project-manager

## 2026-05-07

### Summary
Phase 2 coherence: removed duplicate HARD GATE marker on adjacent lines for cleaner gate phrasing.

### Changes
- Session Initialization step 2: dropped the parenthetical `(HARD GATE):` from the heading line, leaving the canonical `**HARD GATE — Do not proceed...**` imperative on the line below. Single HARD GATE marker per gate matches team-lead's pattern; preserves the intentional inline-in-numbered-list variance (vs. H2+bold pattern used by standalone-flow agents).

### Dimensions Evaluated
Within-file gate-marker consistency, alignment with team-lead's orchestrator-flow gate pattern.

### Rename
None.

## 2026-05-07

### Summary
BALANCED-mode trim pass at 406 lines: removed redundant Operating-context paragraph (covered by fleet pattern), tightened Session Init step 3, SendMessage consult preamble, Notify @senior-engineer block, Status & Observability, Cross-Workstream Coordination, /vote section, and Plan Monitoring preamble. Fixed `docket vote create` short flag (`-r|--rationale`) per Phase 0 CLI audit. Net: -22 lines (406→384).

### Changes
- Removed Operating-context paragraph (duplicates fleet stateless-subagent pattern + step-1 reconstruction guidance)
- Tightened Session Init step 3, SendMessage preamble, Notify @senior-engineer, Status & Observability, Cross-Workstream, /vote section, Plan Monitoring preamble
- Fixed `docket vote create -r|--rationale` short flag in CLI Reference

### Dimensions Evaluated
Consolidation & Trimming (PRIMARY at 406 lines), Spec Alignment (CLI fix), Boundary Clarity, Actionability, Role Realism, Completeness, Capability Growth, Rename

### Rename
No rename.

## 2026-05-06

### Summary
Phase 2 coherence pass: standardized Pre-Flight Gate to "HARD GATE" terminology (fleet majority — matches senior/sdet/ux). No cross-comm changes — PM already practices the prefix-mirroring pattern that the rest of the fleet adopted in this cycle.

### Changes
- Standardized Pre-Flight Gate to "HARD GATE — Do not proceed..." (matches senior/sdet/ux fleet pattern)

### Dimensions Evaluated
Coherence with Fleet Standards (Pre-Flight Gate terminology)

### Rename
No rename.

## 2026-05-06

### Summary
Operator-visibility & capability-growth pass. Hoisted the cross-agent comms visibility contract (`[PM→@agent]` Docket-comment mirror) to top of Cross-Agent Communication so operators can predict where to look. Added SendMessage auto-resumes-idle-peers note, plan-revision broadcast trigger, and stalled-work check-in trigger. Offset by trimming Session Init step 2, redundant TDD acceptance gate (duplicated trigger), and Plan Monitoring preamble. Net: +6 lines (386→392; under 500 budget).

### Changes
- Hoisted operator-visibility contract for `[PM→@agent]` Docket comments to top of Cross-Agent Communication (was buried in Status & Observability)
- Added SendMessage auto-resumes-idle-peers note (Phase 0 capability finding)
- Added stalled-work check-in trigger to @senior-engineer Notify block
- Added new Broadcast trigger for plan revisions affecting ≥2 in-flight issues
- Trimmed Session Init step 2 (5 commands → essentials + reference pointer); renumbered downstream steps
- Removed standalone TDD acceptance gate block (duplicated Incoming-trigger entry)
- Trimmed Plan Monitoring preamble (re-plan-immediately repeated Re-Engagement step 2)

### Dimensions Evaluated
Capability Growth & Cross-Communication (FOCUS), Consolidation & Trimming, Boundary Clarity, Actionability, Role Realism, Completeness, Spec Alignment, Rename

### Rename
No rename.

## 2026-05-05

### Summary
Phase 0+2 capability adoption + consolidation: added `color: yellow` frontmatter for split-pane visual ID, added `docket issue label list` pre-creation check (prevents label drift), consolidated 9-bullet Incoming-Triggers list to 4, tightened No-guessing/Cancellation/Plan-Monitoring prose. Net: -6 lines (392→386).

### Changes
- Added `color: yellow` frontmatter (Phase 2 fleet decision — distinct visual ID)
- Added `docket issue label list` pre-creation check (Phase 0 Docket audit finding)
- Consolidated 9-bullet Incoming-triggers list to 4 (preserved every signal)
- Tightened No-guessing paragraph, Cancellation section, Plan-Monitoring preamble
- Rejected (Content Gate): Monitor-tool addition — PM doesn't run long-running commands
- Deferred (Phase 2): `model: claude-opus-4-7`, `effort: xhigh` — A/B one agent first

### Dimensions Evaluated
Consolidation & Trimming (PRIMARY), Completeness, Capability Growth, Boundary Clarity, Spec Alignment, Role Realism, Actionability, Rename

### Rename
No rename.

## 2026-05-05

### Summary
Consolidation pass — removed duplicated "NOT a guesser" boundary bullet (covered by No-guessing rule above), circular Alignment risk bullet, and tightened verbose paragraphs across No-guessing, Estimate Effort, Decompose the Work, Self-review/Verify-assumptions (merged), Re-Engagement step 4, /vote section, and Rules. Updated Shutdown Handling to reference the explicit `shutdown_response` protocol per Phase 0 docs research. Net: -20 lines (406→386).

### Changes
- Removed duplicate "NOT a guesser" boundary bullet (covered by No-guessing rule above)
- Removed circular Alignment risk bullet (no actionable content)
- Compressed No-guessing, Estimate Effort, Decompose the Work, Re-Engagement step 4, /vote, and Rules
- Merged Self-review and Verify-assumptions paragraphs
- Updated Shutdown Handling to reference `shutdown_response` protocol explicitly
- [Phase 2] Added 6 incoming-trigger entries closing inverse-trigger gaps: @staff-engineer TDD-accepted/scope-delta/re-plan, @senior-engineer scope-expansion / discovered-follow-up, @sdet coverage-gap tracking, @ux-designer post-vote handoff / breaking-UX / scope-discovery

### Dimensions Evaluated
All 8: Consolidation & Trimming (PRIMARY), Boundary Clarity, Capability Growth (shutdown protocol), Actionability, Role Realism, Completeness, Spec Alignment, Rename

### Rename
No rename.

## 2026-04-19

### Summary
Embedded operator "no guessing" durable rule with concrete verification (docket show, Read, Grep, --help) at top-of-file. Trimmed Rules, Estimate Effort, File References, Status/Observability, and mentor framing. Removed orphaned `docket config` CLI mention (Phase 0 audit). Added ultrathink hint for Complex tier.

### Changes
- Added "No guessing" behavior rule — STOP and verify IDs/flags/paths/conventions before acting; never invent parent IDs, acceptance criteria, or TDD references from memory
- Strengthened "NOT a guesser" identity bullet to reference verification rule
- Consolidated Estimate Effort, File References, and Status/Observability paragraphs
- Trimmed Rules section (removed duplicates of CLI reference, DoR, Plan Tiers)
- Removed `docket config` from CLI reference line (auditor finding — never used in workflow)
- Added ultrathink hint to Complex tier for deep decomposition analysis

### Dimensions Evaluated
All 8: Actionability (primary — no-guessing rule), Consolidation (secondary), Role Realism, Boundary Clarity, Completeness, Capability Growth, Spec Alignment, Rename

### Rename
No rename.

## 2026-04-16

### Summary
Cross-communication pass: restructured Cross-Agent Communication into explicit per-teammate direct-SendMessage trigger blocks (@staff-engineer, @ux-designer, @senior-engineer, @sdet) plus a team-lead escalation block. Added Incoming triggers block for reciprocal handling. Compressed mentor paragraph and operating context. Net: -1 line body, +5 Phase 2.

### Changes
- PRIMARY: Replaced vague "proactive sharing" prose with concrete "notify/consult X when Y" triggers. New: @senior-engineer on active-issue plan edits, @sdet on acceptance-criteria change, team-lead escalation on DoR failure, direct @ux-designer ergonomics consult, @staff-engineer on spike-ambiguity
- [Phase 2] Added Incoming triggers block: @staff-engineer spec-drift → `chore` issue; ADR/TDD broadcast → flag invalidated active issues; @sdet missing-criteria → update or blocked-by follow-up
- Compressed "rigorous honest mentor" paragraph (7 → 4 lines) and Operating context (5 → 4 lines)

### Dimensions Evaluated
All 8: Capability Growth & Cross-Communication (GOAL — primary), Consolidation & Trimming, Actionability, Role Realism, Boundary Clarity, Completeness, Spec Alignment, Rename

### Rename
No rename.

## 2026-04-16

### Summary
Consolidation pass: trimmed aspirational prose, compressed redundant "NEVER write code" paragraph, restructured TDD routing bullets. Phase 2 coherence: normalized Docket CLI reference (flag placeholders, `--rationale TEXT`, `--escalation-reason`, destructive-edit warning). Net: -7 lines.

### Changes
- Compressed "NEVER write code" paragraph — merged with output-contract sentence
- Removed "Communication is a planning tool, not overhead" aspirational framing (Content Gate: non-behavioral)
- Removed "Estimates are communication tools, not commitments" aspirational preamble (Content Gate: non-behavioral)
- Restructured Cross-Agent Communication so TDD acceptance gate no longer splits routing bullets
- [Coherence] `issue create -f FILES` → `-f FILE ...`; `vote create -r TEXT` → `--rationale TEXT`, added `--escalation-reason`
- [Coherence] `vote list` — added flag type placeholders and `--all` default-behavior comment
- [Coherence] `issue edit` — added `-f FILE ...` placeholder and destructive-attachment warning in CLI reference

### Dimensions Evaluated
All 8: Consolidation & Trimming (primary), Actionability, Role Realism, Boundary Clarity, Completeness, Capability Growth & Cross-Communication, Spec Alignment, Rename

### Rename
No rename.

## 2026-04-06

### Summary
Added TDD acceptance gate blocking premature decomposition. Compressed Plan Monitoring and merged Program-Level Rollup. Updated CLI reference with `--created-by` flag. Net: -1 line.

### Changes
- **PRIMARY**: Added TDD acceptance gate to Exploration and Routing — blocks decomposition until TDD acceptance pipeline completes (questions → review → vote → status update)
- Compressed Plan Monitoring intro from 7 lines to 4
- Merged Program-Level Rollup into Re-Engagement step 4
- Added `--created-by NAME` to `vote create` in CLI reference (docket audit finding)

### Dimensions Evaluated
All 8: Completeness (primary — TDD acceptance gate, CLI audit), Consolidation & Trimming, Spec Alignment, Boundary Clarity, Actionability, Role Realism, Capability Growth, Rename

### Rename
No rename.

## 2026-04-01

### Summary
Added `model: opus[1m]` to frontmatter, compressed 5 sections, added context compaction awareness. Net: -10 lines.

### Changes
- Added `model: opus[1m]` to frontmatter (standardization across all agents)
- Compressed Goal-Alignment standalone mode from 4 to 2 lines
- Compressed cross-communication observability from 7 to 3 lines
- Trimmed 4 comment lines from bash issue-creation example
- Compressed Program-Level Rollup and Validate/Finish sections
- [Coherence] Added context compaction awareness to Operating context (was the only agent missing it)

### Dimensions Evaluated
All 8: Completeness (frontmatter), Consolidation & Trimming (primary), Role Realism, Actionability, Boundary Clarity, Capability Growth, Spec Alignment, Rename

### Rename
No rename.

## 2026-03-30

### Summary
Added rigorous honest mentor directive adapted to PM role (challenge vague requirements, surface uncomfortable scope truths, flag plan weaknesses). Compressed redundant goal-alignment restatement, fixed `issue edit -f` footgun, added `-r` shorthand and `FIELD:DIR` sort format. Net: +3 lines.

### Changes
- Added honest mentor directive after role introduction — pushback on vague scope, unrealistic timelines, and hidden plan risk
- Compressed "Understand the Problem" clarify-ambiguity bullets to back-reference goal alignment (-4 lines)
- Added `issue edit -f` replacement warning to file attachment section (CLI audit finding)
- Compressed vote CLI reference lines and added `-r` shorthand for `--rationale`
- Fixed `--sort FIELD` to `--sort FIELD:DIR` format (CLI audit finding)
- Removed redundant "NOT a rubber stamp" bullet (subsumed by mentor directive)
- [Coherence] Added @sdet to "What You Are NOT" section (was the only agent missing it)
- [Coherence] Added `/vote` fallback pattern for when skill is unavailable
- [Coherence] Standardized goal-alignment heading to "MANDATORY: Pre-Flight Goal-Alignment Gate"

### Dimensions Evaluated
Role Realism (primary — mentor directive), Consolidation & Trimming, Completeness (CLI audit), Actionability, Boundary Clarity, Capability Growth, Spec Alignment, Rename — all 8 evaluated

### Rename
No rename.

## 2026-03-29

### Summary
Added TaskCreate/TaskUpdate/TaskList/TaskGet to frontmatter and session initialization, connected Mermaid graph output to plan validation, trimmed restated goal-alignment and proactive-sharing patterns. Net: -3 lines.

### Changes
- Added task coordination tools to frontmatter and planning progress tracking step
- Added `--mermaid` flag guidance to self-review validation step
- Trimmed operating context analogy sentence (-2 lines)
- Compressed proactive information sharing bullets into prose (-6 lines)
- Compressed exploration re-alignment paragraph (-4 lines)

### Dimensions Evaluated
Consolidation & Trimming (primary), Capability Growth, Completeness, Actionability, all 8 evaluated

### Rename
No rename.

## 2026-03-29

### Summary
Updated Docket CLI reference with audit findings (missing flags, corrected defaults, new subcommands), removed obsolete Delegation Protocol (PM has /vote skill directly), added --quiet flag awareness, trimmed redundant vote skip guidance. Net: -14 lines.

### Changes
- Updated CLI reference: added `-a ASSIGNEE` on board/list, `-s STATUS` on create, `--orphan`/`-f` on delete, `--merge`/`--replace` on import, `-d`/`--limit` on vote list, `--findings-json` on vote cast, `issue log`, label subcommands with `--color`; fixed `--voter` as optional
- Removed Delegation Protocol section — PM has `/vote` skill in frontmatter, delegation workaround is dead code (-14 lines)
- Added `--quiet` flag note to Session Initialization
- Removed "Skip /vote for trivial/standard plans" sentence (inverse of trigger list)
- [Coherence] Fixed `vote create` flags: `-c`/`-n` restored to required (consistent with all other agents)
- [Coherence] Fixed `vote cast` flag brackets and added `JSON` arg to `--findings-json` (aligned with staff/senior/ux pattern)

### Dimensions Evaluated
Completeness (primary — CLI audit alignment), Consolidation & Trimming, Capability Growth, Actionability, Role Realism, Boundary Clarity, Spec Alignment, Rename — all 8 evaluated

### Rename
No rename.

## 2026-03-21

### Summary
Added cross-communication observability (Docket logging for SendMessage and vote), fixed CLI discrepancies (link remove syntax, --escalation-reason, approve-with-concerns, next -s), added export/import, trimmed non-behavioral prose.

### Changes
- Added cross-communication observability section: log SendMessage exchanges and vote invocations as Docket comments
- Fixed `link remove` syntax to include required `<relation>` argument
- Added `--escalation-reason` to vote create, `approve-with-concerns` verdict to vote cast, `-s` to next
- Added `docket export / import` to CLI reference
- Removed "NOT a bureaucrat" bullet (aspirational, enforced by DoR/Rules)
- Removed "impact is measured" sentence (aspirational, not behavioral)

### Dimensions Evaluated
Capability Growth & Cross-Communication (primary), Completeness, Consolidation & Trimming, all 8 evaluated

### Rename
No rename.

## 2026-03-20

### Summary
Added new docket CLI commands (`plan`, `graph`, `reopen`, `label`) to reference and workflows, compressed /vote and Cancellation sections.

### Changes
- Added `docket plan --json` to Session Initialization for phased execution visibility
- Added `docket plan` and `docket issue graph` to self-review validation step
- Updated Docket CLI Reference with `plan`, `graph`, `reopen`, `label` commands and compressed vote lines
- Compressed Cancellation section (removed restated patterns)
- Compressed "When NOT to invoke /vote" to single sentence

### Dimensions Evaluated
Completeness, Consolidation & Trimming, Spec Alignment

### Rename
No rename.

## 2026-03-20

### Summary
Restructured cross-cutting concerns for scannability, removed redundant rules, added @staff-engineer spike notification trigger, added spec-aware test task guidance.

### Changes
- Restructured cross-cutting concerns from run-on prose to scannable list format
- Removed redundant "Explore before planning" rule (already in Exploration and Routing section)
- Removed redundant "Complete analysis before creating issues" rule (enforced by section ordering)
- Compressed Docket CLI priorities/types into compact format
- Added @staff-engineer notification trigger when creating spike issues with architectural questions
- Added guidance to check `docs/spec/testing.md` before creating test tasks

### Dimensions Evaluated
Consolidation & Trimming (primary), Capability Growth & Cross-Communication, Spec Alignment

### Rename
No rename.

## 2026-03-20

### Summary
Trimmed redundant operator-alignment restatement and effort section, removed redundant operating context sentence, added @sdet notification trigger and build-as-test awareness.

### Changes
- Compressed Alignment risk bullet to reference Operator Alignment section instead of restating
- Merged "Flag uncertainty" and "Shape to capacity" into sizing and total-plan bullets
- Removed redundant "Check progress" definition from Operating Context (covered by Re-Engagement)
- Added SendMessage notification trigger for @sdet when creating test tasks
- Added build-as-test awareness to cross-cutting concerns for projects without test suites

### Dimensions Evaluated
Consolidation & Trimming (primary), Capability Growth & Cross-Communication, Spec Alignment, Role Realism, Actionability, Boundary Clarity, Completeness, Rename

### Rename
No rename.

## 2026-03-20

### Summary
Added memory and effort frontmatter, compressed cross-cutting concerns and external dependencies, removed redundant anti-pattern and vote example.

### Changes
- Added `memory: project` and `effort: high` frontmatter fields
- Removed redundant "solving the wrong problem well" anti-pattern
- Compressed 7-item cross-cutting concerns checklist into inline prose
- Removed /vote invocation example code block
- Folded "Identify External Dependencies" into Risk Assessment dependency bullet
- Renumbered Core Responsibilities sections 6-10 (was 7-11)
- Compressed Re-Engagement steps 4-5
- Updated Operating Context to reflect project memory

### Dimensions Evaluated
Completeness (memory, effort), Consolidation & Trimming (primary), Actionability

### Rename
No rename.

## 2026-03-19

### Summary
Compressed status updates, removed redundant exploration checklist, merged architect NOT entry, added spike output format and blocking links to issue template.

### Changes
- Compressed 10-line status update enumeration into 3-line prose
- Removed "What to look for" exploration paragraph (signals already in Core Responsibilities)
- Compressed Re-Engagement step 1 to reference Session Initialization
- Added spike acceptance criteria: findings comment, recommendation, sufficient detail
- Added "Blocked by" field to issue description template
- Merged "architect" NOT entry into @staff-engineer NOT entry

### Dimensions Evaluated
Consolidation & Trimming (primary), Actionability, Completeness, Capability Growth

### Rename
No rename.

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
