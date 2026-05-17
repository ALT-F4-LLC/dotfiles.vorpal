# Changelog: ux-designer

## 2026-05-17 (Phase 2 coherence)

### Summary
Added canonical `TeammateIdle` stall-signal line for cross-agent terminology coherence.

### Changes
- Communication Discipline: appended TeammateIdle canonical-signal line below rule 6.

### Dimensions Evaluated
Cross-agent terminology coherence.

### Rename
No rename.

## 2026-05-17 (pass 2)

### Summary
Addressed two historical-audit findings: highest per-session "File has not been read yet" rate (11/11 sessions) via explicit Read-before-Edit/Write rule, and least-used-specialist discoverability via a "Dispatch me when" anchor. Deduplicated Design-QA verify-behavior paragraph against Communication Discipline rule 5.

### Changes
- Added "Read before Edit/Write" rule paired with the honest-critique paragraph — Read-first applies to every Edit/Write target including docs/ux/ specs across sessions and post-compaction.
- Added "Dispatch me when" 4-trigger anchor under Core responsibilities for peer discoverability — addresses lowest in-window invocation count.
- Compressed standalone Design-QA "Verify behavior" paragraph against Communication Discipline rule 5 — preserved unique long-running-surface tooling (Monitor) reference.

### Dimensions Evaluated
Actionability (Read-before-Edit — primary), Boundary Clarity (dispatch anchor), Consolidation & Trimming (verify-behavior dedup), Capability Growth.

### Rename
No rename.

## 2026-05-17

### Summary
Vote delegation payload synced to canonical `skills/vote/` Delegation Protocol shape (Phase 2 handoff from 2026-05-17 evolve-skills cycle). Narrative payload replaced with structured form.

### Changes
- Design Spec Approval §Team mode: replaced narrative payload ("artifact path, and initial assessment") with canonical structured shape (`{type, protocol_version, skill, request_id, vote_id, from, summary?, artifact?}`). Added `docket vote create ... --json` prerequisite; documented `failed` response on missing `vote_id`.

### Dimensions Evaluated
Cross-skill coherence (vote-skill payload contract), Coordination & Handoff.

### Rename
No rename.

## 2026-05-16

### Summary
Phase 2 coherence: normalize security-advisor canonical form; drop redundant parenthetical.

### Changes
- "(canonical name: `security-advisor`)" → "(canonical persistent name: `security-advisor`)" — matches sdet.md and security-engineer.md.
- Dropped redundant "(or `security-advisor`)" later in same file — canonical form established earlier.

### Dimensions Evaluated
Security-advisor aliasing consistency.

### Rename
None.

## 2026-05-16

### Summary
Added Communication Discipline (rules 1-6) with rules 1-3 emphasized for ux-advisor's implementation-phase persistence; strengthened Design QA to require behavior verification before any Pass verdict.

### Changes
- Added Communication Discipline section (+24) — closed-loop, ack, saturation, blocker, verify, one-turn shutdown.
- Persistent Advisor Lifecycle cross-references rules 1-3 as mandatory for ux-advisor.
- Design QA "Verify behavior, not code" strengthened: never accept @senior-engineer's intent statement as evidence — walk workflow before Pass verdict.
- Trimmed Operating Context preamble, Shutdown Handling timing redundancy, "What You Are NOT" SDET entry collapsed into implementer/PM line.

### Dimensions Evaluated
Role Realism · Actionability · Boundary Clarity · Completeness · Consolidation & Trimming · Capability Growth & Cross-Communication · Spec Alignment · Rename.

### Rename
No rename.

## 2026-05-13

### Summary
Phase 2 coherence: added @security-engineer to "What You Are NOT" and Outgoing triggers — closes bidirectional handoff gap where security-engineer expected UX consults on consent flows, permission prompts, and security-critical defaults.

### Changes
- "What You Are NOT": added @security-engineer role boundary entry referencing canonical persistent name `security-advisor`
- Outgoing SendMessage triggers: added @security-engineer / security-advisor trigger for consent prompts, permission flows, security defaults, and security-relevant error copy

### Dimensions Evaluated
Coherence (bidirectional with security-engineer.md), Cross-Communication, Boundary Clarity

### Rename
No rename.

## 2026-05-13

### Summary
Replaced loose "when to create a spec" bullets with an explicit four-tier output table (inline / Docket comment / interaction sketch / full spec) addressing operator pain that full specs were being generated for work better served by lighter outputs. Tied workflow step 1 to a tier decision. Adopted canonical "ux-advisor" persistent name aligning with fleet pattern (advisor / security-advisor / ux-advisor). Net: +2 lines (229 → 231).

### Changes
- New "Design Output Tiers" table with explicit thresholds replaces three-bullet spec-creation guidance
- Workflow step 1 renamed "Clarify and pick the tier" — pushes tier decision before drafting
- Senior-engineer incoming trigger collapsed to a pointer to the new tier table
- Persistent Advisor Lifecycle adopts canonical name "ux-advisor"

### Dimensions Evaluated
Completeness (spec threshold — operator feedback), Actionability, Consolidation, Capability Growth (canonical name), Coherence

### Rename
No rename.

## 2026-05-09

### Summary
Self-review trim pass: compressed Pre-Flight Goal-Alignment Gate, tightened workflow step 5, Design QA verify-behavior paragraph, honest-critique stance, and dropped generic team-lead trigger and SDET fluff. Net: −25 lines (254 → 229). Favors decisive guidance over deliberative monologue per fleet directive.

### Changes
- Pre-Flight: dropped "operator may or may not be end user" paragraph and collapsed Standalone/Team Mode subsections into a bullet pair
- Inter-Agent Communication: removed generic "Team lead — status, blockers, completion" trigger (universal end-of-task report-back, not a UX-specific trigger)
- Workflow step 5 Resolve open questions: compressed from 5 lines to 1
- Design QA verify-against-implementation: compressed from 6 lines to 3
- What You Are NOT SDET bullet: dropped fluff tail
- Honest critique stance: dropped values restatement, preserved behavioral rule

### Dimensions Evaluated
Consolidation & Trimming (PRIMARY — HIGHEST priority), Actionability (decisive over deliberative), Output Quality, Boundary Clarity, Capability Growth & Cross-Communication, Role Realism, Completeness, Spec Alignment, Rename

### Rename
No rename.

## 2026-05-08

### Summary
Phase 3 operating discipline: extended Persistent memory to capture solutions to recurring design problems.

### Changes
- Persistent memory now also saves solutions to recurring design problems (symptom → root cause → resolution) so future specs don't re-encounter the same friction

### Dimensions Evaluated
Capability Growth (PRIMARY — memory captures design problem-solution pairs)

### Rename
No rename.

## 2026-05-08

### Summary
Phase 2 coherence: surfaced the sub-agent invocation ban in the CRITICAL banner.

### Changes
- CRITICAL banner now covers both commit ban AND `/vote`/Skill/Agent/TeamCreate ban (was only commit ban)

### Dimensions Evaluated
Coherence (PRIMARY — banner uniformity across fleet), Behavioral (clarifies an existing rule that was hidden)

### Rename
No rename.

## 2026-05-08

### Summary
Trim of redundant inter-agent communication structure, surface-table preamble, "How You Work" verb-routing, research framing, and a handoff line that duplicated the ux-spec skill responsibilities. Audit-scoring rubric relocated from "How You Work" into Responsibility 5 / Design QA where it belongs.

### Changes
- Consolidated "Consult first" + "Notify proactively" trigger lists into a single "Outgoing triggers" list (peer-message preference line dropped — already implied by the trigger list)
- Trimmed redundant Surface-Specific table caption
- Compressed Research and Discovery to one declarative paragraph
- Removed "How You Work" verb-routing table; relocated audit-scoring rubric into Design QA Output
- Removed `last_updated`/`updated_by` instruction (format authority is `skills/ux-spec/SKILL.md` per the agent's own directive)

### Dimensions Evaluated
Consolidation & Trimming (PRIMARY), Capability Growth & Cross-Communication, Actionability, Completeness, Spec Alignment

### Rename
No rename.

## 2026-05-07

### Summary
Phase 2 coherence: added persistent agent-memory paragraph aligning ux-designer with sdet/SE/staff/PM fleet pattern. UX-specific guidance on what to persist (operator flag/terminology ergonomics, rejected design alternatives, cross-surface precedent decisions, surface-typed anti-patterns) versus what stays in `docs/ux/`. Net: +6 lines (262→268).

### Changes
- Added Persistent memory paragraph after Operating context with UX-specific signals to persist; explicit do-not-memorize rule for spec content

### Dimensions Evaluated
Coherence with Fleet Standards (agent-memory pattern), Capability Growth, Boundary Clarity (memory vs spec separation)

### Rename
No rename.

## 2026-05-07

### Summary
Closed persistent-advisor lifecycle gap (team-lead.md:169 mandates the orchestrator-side behavior but ux-designer.md previously had no receiving-end guidance). Tightened Operating context paragraph (harness now provides persistent memory) and trimmed cross-agent bookkeeping parenthetical. Net: 0 lines (262→262).

### Changes
- Added Persistent Advisor Lifecycle section before Shutdown Handling — covers alive-between-spec-and-verification behavior (priority-one inbound peer questions, no unrelated work). Added shutdown-rejection clause when verification is in flight ("verification incomplete" reason)
- Trimmed "match staff/PM mandate" bookkeeping parenthetical from text-only-medium line — kept the MUST mandate, dropped the cross-agent commentary
- Tightened Operating context paragraph: replaced "Stateless ... with project-scoped memory" with "fresh conversation context, persistent memory and docs"; preserved heuristic-evaluation/error-log substitution guidance

### Dimensions Evaluated
Completeness (PRIMARY — persistent advisor gap), Capability Growth & Cross-Communication, Consolidation & Trimming, Coherence

### Rename
No rename.

## 2026-05-07

### Summary
Phase 2 coherence: aligned HARD GATE delimiter style with peer agents.

### Changes
- Pre-Flight Goal-Alignment Gate: replaced `**HARD GATE:` (colon) with `**HARD GATE —` (em-dash) to match staff/senior/sdet/PM/team-lead. Collapsed two-line bold to one line for consistency with the H2+single-bold-line pattern used by other standalone-flow agents.

### Dimensions Evaluated
Cross-agent terminology consistency, visual coherence of HARD GATE markers across agent files.

### Rename
None.

## 2026-05-07

### Summary
Capability fix + Responsibility 4 trim. Added Monitor to tools frontmatter to match the existing Responsibility 5 mandate (introduced 2026-05-05 without the tool). Trimmed rhetorical filler from Design System Coherence.

### Changes
- Added `Monitor` to tools frontmatter — closes capability gap with Responsibility 5 ("use Monitor to stream output without blocking" for QA of dev servers/preview builds/watchers)
- Trimmed rhetorical phrases in Responsibility 4 ("atoms of coherence", "worst-designed moments") and dropped redundant intro line — behavioral content (same semantic intent across surfaces, 2+ team validation gate, treat breaking pattern changes like breaking API changes) preserved

### Dimensions Evaluated
Completeness (PRIMARY — Monitor capability gap), Consolidation & Trimming (HIGHEST priority offset), Capability Growth, Cross-Communication, Boundary Clarity, Role Realism, Actionability, Spec Alignment, Rename

### Rename
No rename.

## 2026-05-06

### Summary
Phase 2 coherence pass: replaced "summarize in next status update" cross-comm pattern with fleet-standard hybrid (Docket-comment prefix `[UX→@agent]` for persistence + concurrent team-lead cc for high-stakes events). Strengthened Mermaid statement to MUST-use mandate to align with staff/PM.

### Changes
- Replaced "Cross-communication observability" paragraph with "Operator-visibility contract" — Docket-comment prefix `[UX→@agent]` + real-time cc for high-stakes (breaking-UX broadcast, blocking design-QA Fail, TDD/UX conflict escalation, cross-surface precedent)
- Strengthened Mermaid statement to "MUST be used to visualize user flows, state transitions, and cross-surface journeys" — matches staff/PM fleet mandate

### Dimensions Evaluated
Cross-Communication & Observability (PRIMARY), Coherence with Fleet Standards, Documentation Mandate Alignment

### Rename
No rename.

## 2026-05-06

### Summary
Cross-comms visibility + capability growth pass. Added Cross-communication observability paragraph (operator can't see inter-agent SendMessage), added missing incoming trigger for @senior-engineer implementation-complete → design QA wake-up (closed bidirectional gap with senior-engineer's diff-ready outbound), compressed "How You Work" three-mode block (duplicated Responsibilities 1/2/5). Net: -3 lines (284→281).

### Changes
- Added Cross-communication observability to Inter-Agent Communication (mirrors staff-engineer canonical pattern at agents/staff-engineer.md:260) — operator visibility focus
- Added incoming trigger: @senior-engineer implementation-complete on user-facing surface → run design QA per Responsibility 5 (closed bidirectional gap)
- Compressed "How You Work" three-mode block — collapsed verb-routing into single sentence, removed Evaluate-mode duplication of Responsibility 5

### Dimensions Evaluated
Cross-Communication (PRIMARY — observability + missing inbound trigger), Consolidation & Trimming (HIGHEST priority offset), Capability Growth, Boundary Clarity, Actionability, Role Realism, Completeness, Spec Alignment, Rename

### Rename
No rename.

## 2026-05-05

### Summary
Phase 0+2 capability adoption + consolidation: added Bash run_in_background + Monitor pattern for QA of long-running surfaces, `color: magenta` frontmatter. Merged Honest-critique + No-guessing stance, merged two @staff-engineer incoming triggers, trimmed Pre-Flight parentheticals and stale skills footnote. Net: -3 lines (287→284).

### Changes
- Added Monitor + run_in_background pattern in Responsibility 5 (Design QA) for long-running user-facing surfaces (Phase 0)
- Added `color: magenta` frontmatter (Phase 2 fleet decision)
- Merged Honest-critique and No-guessing stance paragraphs into single block
- Merged two @staff-engineer incoming-trigger lines (TDD revision + feasibility consult) into one bidirectional trigger
- Tightened Pre-Flight Standalone Mode wording
- Dropped Phase 0 footnote about `skills` frontmatter no longer auto-loading in team mode
- Deferred (Phase 2): `model: claude-opus-4-7`, `effort: xhigh` — A/B one agent first

### Dimensions Evaluated
Consolidation & Trimming (PRIMARY), Capability Growth (Monitor for QA), Actionability, Boundary Clarity, Role Realism, Completeness, Cross-Communication, Spec Alignment, Rename

### Rename
No rename.

## 2026-05-05

### Summary
Consolidation pass: compressed three stance paragraphs (Honest critique / No guessing / Text-only medium), tightened workflow step 1 (Clarify), trimmed Pre-Flight Standalone Mode parenthetical. Added Phase 0 note that `skills` frontmatter does not auto-load in team mode — clarifying the existing Design Spec Approval routing. Net: -6 lines (290→284).

### Changes
- Compressed Honest critique / No guessing / Text-only medium stance paragraphs
- Trimmed Clarify workflow step (removed TDD escalation duplicate already in What You Are NOT)
- Tightened Pre-Flight Standalone Mode question list (work-type parenthetical was non-load-bearing)
- Restructured Design Spec Approval — added explicit note that `skills` frontmatter does not auto-load in team mode (Phase 0 finding)
- [Phase 2] Added 3 incoming-trigger entries closing inverse-trigger gaps: @staff-engineer feasibility/precedent consult, @senior-engineer missing-UX-spec notification, @project-manager pre-decomposition ergonomics consult

### Dimensions Evaluated
All 8: Consolidation & Trimming (HIGHEST — primary), Capability Growth (skill-in-teammate note), Boundary Clarity, Actionability, Role Realism, Completeness, Spec Alignment, Rename

### Rename
No rename.

## 2026-04-19

### Summary
Added "No guessing — research first" rule after Honest critique — STOP-and-research loop for UX patterns, user workflows, SDK/CLI conventions, accessibility standards. Routes un-verifiable standards to AskUserQuestion (no WebFetch in tools). Compressed stance paragraphs, operating context, workflow step 5, and How-You-Work modes.

### Changes
- Added "No guessing — research first" — concrete STOP-and-research with Read/Grep/Bash; unverifiable standards routed to AskUserQuestion (no WebFetch in tools)
- Compressed Honest critique, Core responsibilities preamble, Staff-level opener, Operating context, Text-only medium parenthetical
- Compressed workflow step 5 (Resolve open questions) and How You Work modes
- [Phase 2] Added Incoming triggers block (previously absent) with 5 entries — @staff-engineer TDD/constraint, @sdet UX deviation, @senior-engineer pattern question, @project-manager scope change, ADR `*` broadcast

### Dimensions Evaluated
All 8: Role Realism (primary — no-guess rule), Consolidation (offset), Actionability, Capability Growth, Boundary Clarity, Completeness, Spec Alignment, Rename

### Rename
No rename.

## 2026-04-16

### Summary
Cross-communication pass: restructured Inter-Agent Communication around concrete proactive SendMessage triggers (Consult first / Notify proactively) keyed to specific teammates. Phase 2 reconciled spec-handoff timing. Added `docket issue show` and `comment list` as context-read commands before commenting. Net: -9 lines.

### Changes
- PRIMARY: Replaced 3 vague "When to consult" blocks + generic "Proactive communication" with two crisp trigger-keyed blocks — **Consult first** (4 agents, specific preconditions) and **Notify proactively** (5 targets with "when X → notify Y" triggers)
- Added triggers: @PM handoff, @sdet testability check before finalizing spec with error states, @senior-engineer on spec revision affecting implemented behavior, @staff-engineer on cross-surface precedent
- [Phase 2] Resolved spec-handoff timing: @PM notification happens after vote approval (not on save), reconciling Inter-Agent trigger with Design Spec Workflow step 7
- Added broadcast discipline (prefer direct; `*` only for cross-surface precedent) and `docket issue show`/`comment list` as required context reads

### Dimensions Evaluated
All 8: Cross-Communication (GOAL — primary), Consolidation (HIGHEST — offset secured), Capability Growth, Actionability, Boundary Clarity, Role Realism, Spec Alignment, Rename

### Rename
No rename.

## 2026-04-16

### Summary
Consolidation pass: merged text-medium directives, compressed What You Are NOT (added missing @sdet boundary for cross-agent coherence), tightened Operating context. Phase 2 coherence: replaced in-role Docket create/edit guidance with routing through @project-manager (matches role boundary). Net: -12 lines.

### Changes
- Merged Markdown-only + Mermaid sections into single "Text-only medium" paragraph
- Compressed What You Are NOT from verbose prose; added missing NOT-@sdet bullet (peer agents all include it)
- Tightened Operating context paragraph while preserving concrete adaptations
- [Coherence] Replaced "Attach design spec files with `docket issue create --file`" with "notify @project-manager" — PM owns issue creation/file attachment per "What You Are NOT"

### Dimensions Evaluated
All 8: Consolidation & Trimming (primary), Boundary Clarity, Actionability, Spec Alignment, Role Realism, Completeness, Capability Growth, Rename

### Rename
No rename.

## 2026-04-06

### Summary
Added mandatory "Resolve open questions" workflow step (verified goal). Compressed What You Are NOT, Research, and Shutdown sections. Updated Handoff Notes to require resolved decisions. Net: +1 line.

### Changes
- **CRITICAL**: Added workflow step 5 "Resolve open questions — do not defer" requiring all design questions be surfaced to operator via AskUserQuestion before saving spec
- Updated Handoff Notes: replaced "open questions" with "resolved design decisions"
- Compressed What You Are NOT from 4 bullets to 2 (merged implementer + PM, removed SDET)
- Compressed Research section from two paragraphs to one
- Compressed Shutdown Handling from 3 lines to 1

### Dimensions Evaluated
All 8: Completeness (primary — open questions workflow), Consolidation & Trimming, Spec Alignment, Role Realism, Actionability, Boundary Clarity, Capability Growth, Rename

### Rename
No rename.

## 2026-04-06

### Summary
Fixed `/vote` team-nesting bug (operator feedback): replaced direct `/vote` invocation with team/standalone mode routing. Removed Docket Vote CLI Reference block. Compressed self-validate checklist and Design System Coherence. Net: -24 lines.

### Changes
- **CRITICAL**: Replaced "Using `/vote` for Consensus" with "Design Spec Approval" — team mode delegates to orchestrator via SendMessage, standalone invokes `/vote` directly
- Removed Docket Vote CLI Reference block (redundant with `docket vote --help`)
- Compressed self-validate checklist from 8 to 5 checks
- Compressed Design System Coherence from 5 to 3 bullets (merged tokens + component APIs + cross-platform)
- Updated workflow step 6 and Handoff to reference new approval section
- Updated cross-communication observability wording

### Dimensions Evaluated
All 8: Capability Growth (vote fix — primary), Consolidation & Trimming (CLI ref, self-validate, design system), Role Realism, Actionability, Boundary Clarity, Completeness, Spec Alignment, Rename

### Rename
No rename.

## 2026-04-01

### Summary
Added `model: opus[1m]` to frontmatter, added context compaction handling, compressed Pre-Flight and Inter-Agent Communication sections, added Edit tool. Net: -12 lines.

### Changes
- Added `model: opus[1m]` to frontmatter (settings standardization)
- Added context compaction handling to Operating context (team-wide pattern)
- Compressed Pre-Flight standalone mode from 13 to 4 lines
- Merged notification triggers into single Proactive communication block
- Compressed cross-communication observability
- Compressed vote cast CLI reference to inline format
- Added Edit tool for incremental docs/ux/ spec updates

### Dimensions Evaluated
All 8: Completeness (frontmatter, Edit tool), Consolidation & Trimming (primary), Role Realism, Actionability, Boundary Clarity, Capability Growth, Spec Alignment, Rename

### Rename
No rename.

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
