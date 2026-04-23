# Changelog: senior-engineer

## 2026-04-19

### Summary
Embedded operator "No guessing — verify" rule at top-of-file principle level adjacent to Rigorous honesty, and reinforced operationally in Verification Feedback Loop. Compressed boundary prose and redundant SendMessage closings to offset.

### Changes
- Added "No guessing — verify" top-level principle — STOP and verify APIs/signatures/paths via Read, Grep, Bash, WebFetch; never invent imports or patch symptoms
- Added pre-code verification bullet to Verification Feedback Loop
- Compressed "What You Are NOT" (8 → 5 lines) and SendMessage preamble; removed redundant "Report transitions" block
- [Phase 2] Added @sdet source-clarification incoming trigger — reciprocates SDET fixture/framework uncertainty outgoing
- [Phase 2] Added @project-manager plan-change incoming trigger — reciprocates PM active-issue scope/dep notifications

### Dimensions Evaluated
All 8: Role Realism (primary — No Guessing), Actionability (verification steps), Consolidation (offset trims), Boundary Clarity, Completeness, Capability Growth, Spec Alignment, Rename

### Rename
No rename.

## 2026-04-16

### Summary
Cross-communication pass: replaced vague "proactive sharing" prose with concrete phase-indexed SendMessage trigger matrix (before/during/close, 14 triggers). Added Incoming triggers for bidirectional reciprocity. Trimmed boilerplate across Operating Context, Rigorous Honesty, What You Are NOT, Pre-Flight Gate, and Check-Specs. Applied Docket CLI audit findings. Net: -29 lines.

### Changes
- PRIMARY: Added phase-indexed SendMessage trigger matrix — 14 concrete "when X → notify Y" rules grouped by implementation phase (before/during/close)
- [Phase 2] Added Incoming triggers block: @sdet BLOCK fix-loop, TDD-accepted/revised preload, @ux-designer spec-revision reconcile, ADR `*` broadcast consumption; flag test-infra-adjacent changes on review handoff
- Trimmed Operating Context (-2), Rigorous Honesty (-4), What You Are NOT (-7), Pre-Flight Gate (-17), Check-Specs (-8)
- CLI: `docket export` expanded; `vote list` added `-d|--domain-tag TAG`; `vote create` documented `-r|--rationale` short form

### Dimensions Evaluated
All 8: Cross-Communication (GOAL — primary), Consolidation (HIGHEST priority), Completeness (CLI audit), Boundary Clarity, Role Realism, Actionability, Spec Alignment, Rename

### Rename
No rename.

## 2026-04-16

### Summary
Consolidation pass: trimmed Operating Context boilerplate, Docket Rules redundancy, and self-review bullet list. Aligned CLI reference with Docket audit findings. Phase 2 coherence: normalized `--created-by` value name and added `vote list` default-behavior comment. Net: -13 lines.

### Changes
- Trimmed Operating Context — removed inherited "verify in production" / "own the regression" metaphors already implied by role
- Compressed Docket Rules — removed restated intro guidance
- Compressed Execution Workflow step 5 — merged notify bullets and diff-review bullets
- CLI: `vote cast` now documents `--findings-json FILE` alternative (aligned with @sdet)
- CLI: `vote list` now documents `--all` flag (default is open-only)
- CLI: `issue create` clarified `-f FILE ...` (repeatable, not multi-value)
- [Coherence] `--created-by AGENT` → `--created-by NAME` (peer-agent convention)
- [Coherence] Added `--all` default-behavior comment to `vote list`

### Dimensions Evaluated
All 8: Consolidation & Trimming (primary), Completeness (CLI audit), Spec Alignment, Actionability, Role Realism, Boundary Clarity, Capability Growth, Rename

### Rename
No rename.

## 2026-04-06

### Summary
Added TDD status gate (only implement from ACCEPTED TDDs). Compressed Core Operating Principles and Verification. Updated CLI reference with audit findings. Net: -3 lines.

### Changes
- **CRITICAL**: Added TDD status gate — only implement from TDDs with `status: accepted` frontmatter; non-accepted TDDs block implementation with notification
- Compressed "Own the Outcome" — removed non-executable "regressions after close" (-1 line)
- Compressed "Right-Size the Effort" — merged sink-cost paragraph into single sentence (-3 lines)
- Compressed Verification Feedback Loop — removed puffery and redundant "mediocre, redo" bullet (-2 lines)
- Updated CLI: `--created-by`/`--escalation-reason` on vote create, `--summary`/`--voter` on vote cast, `export --status` (+1 line)

### Dimensions Evaluated
All 8: Completeness (TDD gate — primary, CLI audit), Consolidation & Trimming, Spec Alignment, Role Realism, Actionability, Boundary Clarity, Capability Growth, Rename

### Rename
No rename.

## 2026-04-01

### Summary
Added `model: opus[1m]` to frontmatter, compressed proactive sharing, /vote guidance, and Docket CLI Reference. Added docket aliases. Net: -13 lines.

### Changes
- Added `model: opus[1m]` to frontmatter (settings standardization)
- Compressed proactive sharing from 12 to 5 lines with trigger→recipient mapping
- Merged /vote "when to invoke" bullets, tightened trailing prose (-5 lines)
- Compressed Docket CLI Reference: inlined VERDICT, merged vote subcommands, added aliases (-3 lines)

### Dimensions Evaluated
All 8: Completeness (frontmatter), Consolidation & Trimming (primary), Capability Growth (docket aliases), Role Realism, Actionability, Boundary Clarity, Spec Alignment, Rename

### Rename
No rename.

## 2026-03-30

### Summary
Added rigorous honest mentor directive near top of file. Removed /vote "when NOT" list, folded Mermaid Diagrams into Cross-Cutting Concerns, added missing CLI flags, fixed orphan dependency bullet. Net: -2 lines.

### Changes
- Added "Rigorous honesty over agreeability" directive after intro paragraph (+8 lines)
- Removed "When NOT to invoke /vote" list — logical inverse of "when to invoke" (-4 lines)
- Folded Mermaid Diagrams subsection into Cross-Cutting Concerns one-liner (-3 lines)
- Added `--label` flag to `issue create` and `--escalation-reason` to `vote commit` in CLI reference
- Merged orphan dependency-scrutiny bullet into Technical Debt list (-1 line)

### Dimensions Evaluated
Role Realism (mentor directive), Completeness (CLI audit flags), Consolidation & Trimming (vote, mermaid, orphan bullet), Actionability, Boundary Clarity, Capability Growth, Spec Alignment, Rename — all 8 evaluated

### Rename
No rename.

## 2026-03-29

### Summary
Added TaskCreate/TaskUpdate/TaskList/TaskGet to frontmatter, compressed Inter-Agent Communication (merged status updates and observability), trimmed consult list and description, shortened Mermaid section. Net: -13 lines.

### Changes
- Added task coordination tools to frontmatter tools list
- Merged "Status updates to the operator" and "Cross-communication observability" into "Status updates and observability" (-5 lines)
- Compressed @staff-engineer consult list from 4 to 3 bullets (-2 lines)
- Shortened frontmatter description (-2 lines)
- Compressed Mermaid Diagrams section (-2 lines)
- [Coherence] Consolidated standalone Delegation Protocol into /vote section (aligned with staff-engineer/ux-designer pattern)

### Dimensions Evaluated
Consolidation & Trimming (primary), Completeness (task tools), Coherence (Phase 2), all 8 evaluated

### Rename
No rename.

## 2026-03-29

### Summary
CLI reference fixes from docket audit (reopen, --domain-tag, --limit, optional --voter, --status, --assignee, --quiet), consolidated Build & Commit Hygiene and Decision-Making Framework, merged Dependency Evaluation into Technical Debt.

### Changes
- Fixed CLI reference: added `reopen`, `--domain-tag`, `--limit` on vote list; marked `--voter` optional; added `-s`/`-a` on issue create
- Added `--quiet` flag documentation (global note + ad-hoc example)
- Compressed Build & Commit Hygiene from 5 bullets to 3 (merged lockfile and commit discipline bullets)
- Compressed Decision-Making Framework from 2 paragraphs to 1
- Merged Dependency Evaluation section into Technical Debt as fourth bullet

### Dimensions Evaluated
Completeness (CLI audit — primary), Consolidation & Trimming, Role Realism, Actionability, Boundary Clarity, Capability Growth, Spec Alignment, Rename — all 8 evaluated

### Rename
No rename.

## 2026-03-21

### Summary
Added cross-communication observability (SendMessage and /vote logging as Docket comments), updated CLI with missing vote flags and approve-with-concerns verdict, compressed Delegation Protocol and Own the Outcome.

### Changes
- Added cross-communication observability subsection: log SendMessage exchanges and /vote outcomes as Docket comments
- Added vote outcome logging to /vote section
- Updated CLI: -T/-s on next, --domain-tags/--files-changed/--escalation-reason on vote create, --findings-json/--summary on vote cast, approve-with-concerns verdict
- Compressed Delegation Protocol from bullet list to inline format
- Trimmed "Own the Outcome" (removed redundancy with Navigate Ambiguity)

### Dimensions Evaluated
Capability Growth & Cross-Communication (primary), Completeness (CLI audit), Consolidation & Trimming, all 8 evaluated

### Rename
No rename.

## 2026-03-20

### Summary
Removed Anti-Patterns section (restated by Core Operating Principles), compressed CLI Reference and Cross-Cutting Concerns, updated CLI with `log` and `file add` commands.

### Changes
- Removed Anti-Patterns to Avoid section entirely (scope creep, silent compliance, resume-driven dev all restated in Core Operating Principles and Dependency Evaluation)
- Compressed Docket CLI Reference from 15 to 10 lines, added `log`, `file add`
- Compressed Cross-Cutting Concerns to remove explicit spec file names (already says "relevant docs/spec/")
- Compressed Dependency Evaluation bullet to paragraph

### Dimensions Evaluated
Consolidation & Trimming (primary), Completeness, Actionability

### Rename
No rename.

## 2026-03-20

### Summary
Consolidated duplicate build-verification bullets, removed redundant anti-pattern, added @ux-designer cross-communication trigger, compressed Docket CLI Reference, improved Navigate Ambiguity for stateless model.

### Changes
- Merged two duplicate "run the build" bullets in self-review step 5 into one
- Removed Operator Alignment anti-pattern paragraph (restated by "During implementation" bullets)
- Added @ux-designer to proactive sharing examples in Inter-Agent Communication
- Compressed Docket CLI Reference by removing section headers and shortening descriptions
- Reworded "reasonable timeframe" to "current session" in Navigate Ambiguity

### Dimensions Evaluated
Consolidation & Trimming (primary), Cross-Communication, Actionability

### Rename
No rename.

## 2026-03-20

### Summary
Consolidation pass removing self-review/Config-as-Code duplication and implicit "when not to consult" list, added @sdet and @project-manager cross-communication triggers, realigned Docket CLI Reference.

### Changes
- Replaced verbose generated-output self-review bullet with pointer to Config-as-Code Safety section
- Removed "When NOT to consult — just proceed" subsection (logical inverse of consult list)
- Added @sdet notification after implementation completion for test verification handoff
- Added @project-manager SendMessage trigger for scope discoveries
- Replaced `docket issue list` in CLI Reference with `docket next` (agent's actual entry point)
- Compressed "Right-Size the Effort" from 3 lines to 1
- [Coherence] Added `vote` to `skills` frontmatter to match body usage
- [Coherence] Description frontmatter now mentions @sdet verification alongside @staff-engineer review

### Dimensions Evaluated
Consolidation & Trimming (primary), Capability Growth & Cross-Communication, Boundary Clarity, Coherence

### Rename
No rename.

## 2026-03-20

### Summary
Consolidation pass removing duplicate content across sections, added memory frontmatter, calibrated self-review depth to change risk.

### Changes
- Removed "Own the Outcome" alignment paragraph (duplicate of Operator Alignment section)
- Removed "Navigate Ambiguity" preamble paragraph (restated by its own bullets)
- Compressed Inter-Agent Communication preamble from 5 lines to 1
- Removed "Plan Before You Execute" subsection (covered by Check Specs and System-Level Awareness)
- Trimmed Docket CLI Reference session-setup block (duplicated by Session Initialization)
- Merged "debuggable code" bullet into error-context bullet in Code Quality
- Added `memory: project` frontmatter for cross-session codebase learning
- Added risk-calibrated self-review guidance
- [Coherence] Added missing `effort: max` frontmatter (aligned with all other agents)

### Dimensions Evaluated
Consolidation & Trimming (primary), Completeness, Capability Growth, Role Realism

### Rename
No rename.

## 2026-03-19

### Summary
Consolidated redundant instructions, compressed status-update checklist, added @staff-engineer review notification to self-review workflow, pointed cross-cutting concerns to relevant specs.

### Changes
- Removed duplicate "verify TDD match" from System-Level Awareness (already in self-review step 5)
- Removed "Copy-paste implementation" anti-pattern (redundant with DRY in Code Quality)
- Compressed 6-bullet status-update checklist into compact paragraph format
- Added concrete SendMessage notification to @staff-engineer after self-review in step 5
- Removed "Other SendMessage uses" sub-section (all items covered elsewhere)
- Removed "When asked to cut corners" bullet (covered by anti-patterns and intro)
- Updated cross-cutting concerns to reference relevant spec files
- [Coherence] Clarified file attachment verification: PM attaches, engineer verifies, scoped STOP to pre-planned issues

### Dimensions Evaluated
Consolidation & Trimming (primary), Completeness, Actionability, Spec Alignment, Coherence

### Rename
No rename.

## 2026-03-19

### Summary
Consolidated redundant build-verification steps, compressed Dependency & API Surface section and SDET boundary description, added SendMessage inter-agent communication guidance.

### Changes
- Merged "Verify after deployment" (step 7) into self-review checklist (step 5) to eliminate redundant build-run instructions
- Compressed Dependency & API Surface Evaluation from 3 bullets to 1 focused bullet
- Shortened SDET boundary bullet from 6 lines to 3 without losing key information
- Added Inter-Agent Communication subsection with SendMessage guidance for real-time teammate coordination
- Fixed double blank line formatting inconsistency
- [Coherence] Replaced "orchestrator" with "user or team lead" (3 occurrences)
- [Coherence] Added SendMessage to tools frontmatter
- [Coherence] Streamlined session initialization to context-dependent commands

### Dimensions Evaluated
Consolidation & Trimming, Capability Growth, Role Realism, Boundary Clarity, Coherence

### Rename
No rename.

## 2026-03-19

### Summary
Strengthened self-review step for generated/serialized output, removed non-actionable Incident Response section, compressed Cross-Cutting Concerns checklist.

### Changes
- Expanded self-review serialization bullet into a concrete before/after diff step aligned with project's config-generator nature
- Removed Incident Response & Debugging subsection — stateless agent cannot perform ongoing incident management; useful debugging guidance already covered by existing principles
- Compressed Cross-Cutting Concerns from verbose parenthetical definitions to terse checklist

### Dimensions Evaluated
Role Realism, Consolidation & Trimming, Spec Alignment

### Rename
No rename.

## 2026-03-19

### Summary
Added UX spec escalation trigger so @senior-engineer stops and requests design input when user-facing work lacks a spec in `docs/ux/`.

### Changes
- Added missing UX spec escalation bullet to "Navigate Ambiguity" section, parallel to existing TDD escalation pattern, with trivial-change carve-out

### Dimensions Evaluated
Boundary Clarity (cross-agent coherence)

### Rename
No rename.

## 2026-03-19

### Summary
Major consolidation pass removing ~400 lines (758 → 361) to bring the agent well under the 500-line budget.

### Changes
- Removed five entire sections: Database & Schema Changes, Growing Engineers Around You, Technical Spikes & Prototyping, Communication Style, Cross-Functional Collaboration
- Removed Complete Workflow section (duplicate of Docket Execution Workflow)
- Merged Backward Compatibility, Production Ownership, Negotiate Scope, Build & CI Hygiene into existing sections
- Compressed Core Operating Principles, Decision-Making Framework, Anti-Patterns, Docket Rules

### Dimensions Evaluated
Consolidation & Trimming (primary), Spec Alignment, Role Realism

### Rename
No rename.
