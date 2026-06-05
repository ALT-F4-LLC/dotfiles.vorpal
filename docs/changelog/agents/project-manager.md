# Changelog: project-manager

## 2026-06-05

### Summary
Encoded three CONFIRMED recurring historical pitfalls the file did not previously cover, all verified against the zero-drift Docket CLI audit (`-d` sets body / accepts `-` stdin; `-f` only attaches refs). Net +2 (332→334). §9 DOC-link tail (duplicate of §10) trimmed as partial offset.

### Changes
- §6 Decompose: same-file-same-layer leaves now require a DIRECT `depends_on` (co-gating behind independent parents does NOT serialize; both succeed in isolation then collide at apply); check extends to TEST files.
- §8 Write Descriptions: stated `-d` sets the body (use `-d -` for multi-line stdin) vs `-f` only attaches refs — passing the body via `-f` yields an empty description + a dead attachment.
- §9 Attach File Refs: `-f` must be the leaf's real EDIT/CREATE target (read What/Where); fixed the "must resolve on disk" rule to handle new-file deliverables; dropped DOC-link tail duplicating §10.

### Dimensions Evaluated
Capability Growth (PRIMARY — all 3 historical pitfalls) · Actionability (`-d -` idiom) · Consolidation & Trimming (§9 tail dedup) · Spec Alignment (CLI ground-truth verified).

### Rename
No rename.

## 2026-05-30

### Summary
Three Consolidation & Trimming edits (net -2 lines; 324→322) removing internal redundancy. §Strict Ephemeral Lifecycle stated the FRESH-ephemeral / continuity-preamble / doubling-exemption facts across three paragraphs; §Plan Monitoring re-enumerated the preamble with a stale "§6 continuity preamble" self-reference (no §6 exists in this file); §Shutdown "What to save here" duplicated the top-of-file memory description. Canonical homes (team-lead.md Rule 8, §Teammate Stall & Crash Recovery) preserved as pointers; no behavioral loss.

### Changes
- §Strict Ephemeral Lifecycle: merged the standalone "Doubling rule does NOT apply" paragraph into "Re-planning spawns a FRESH ephemeral"; condensed re-enumerated preamble contents to a pointer.
- §Plan Monitoring §Re-engagement: dropped the duplicated preamble sentence; fixed the stale "§6 continuity preamble" reference to defer to team-lead's preamble.
- §Shutdown "What to save here": replaced the duplicate of the top-of-file memory description with a pointer + pitfalls-vs-memory distinction.

### Dimensions Evaluated
Consolidation & Trimming (PRIMARY — all 3) · Boundary Clarity (senior-engineer single-ad-hoc-issue carve-out verified intact) · Completeness (no net-new capability warranted) · Spec Alignment (absent-dir case already handled)

### Rename
No rename.

## 2026-05-30

### Summary
One change closing the cross-cutting brief-integrity gap (historical finding: PM authored issue bodies citing nonexistent file refs + stale TDD line numbers). §9 now requires verifying each `-f` path resolves on disk before attaching and re-confirming spec line-refs against the live file; swapped in place for the triplicated `issue edit -f` REPLACES warning (canonical home retained at Docket Reference foot-guns). Within-line; 324 lines unchanged.

### Changes
- §9 Attach File References: added "Verify before attaching" (confirm path resolves via `ls`/Read; re-confirm cited spec line-refs against the live file — line numbers drift); dropped the redundant inline `edit -f` warning, pointing to Docket Reference foot-guns.

### Dimensions Evaluated
Capability Growth (PRIMARY — brief-integrity discipline, historical finding) · Consolidation & Trimming (de-triplicated `edit -f` warning)

### Rename
No rename.

## 2026-05-26

### Summary
Codified the P0 historical signal — explicitly close the parent epic after all children close (children do NOT auto-close the parent). Applied SubagentStop drain doctrine to the Monitor auto-shutdown procedure (TaskStop the watch before emitting shutdown_request). Dropped redundant `docket stats` from session init per CLI audit. Consolidated Risks bullets and Persistent-advisors lifecycle clause. Net: -7 lines (326 → 319).

### Changes
- §Plan Monitoring §Cancellation/completion: explicit `docket issue close <epic-id>` after children close — child closure does NOT cascade.
- §Session Initialization: dropped `docket stats` (redundant with `board --json` + `plan --json`).
- §Shutdown Handling §Auto-shutdown on idle: TaskStop the Monitor watch before emitting shutdown_request (drain doctrine, v2.1.145).
- §Assess Risks: four single-sentence bullets inlined into lede paragraph (-5 lines).
- §Strict Ephemeral Lifecycle: folded "Persistent advisors unaffected" clause into Lifecycle opener (-2 lines).

### Dimensions Evaluated
Capability Growth (epic-close rule, drain doctrine) · Consolidation & Trimming (Risks inline, Persistent-advisors fold, docket stats drop) · Completeness (docs research v2.1.145)

### Rename
No rename.

## 2026-05-26 (Phase 2 — strip 4 dangling docs/tdd/* citations)

### Summary
Stripped 4 dangling citations (Phase 0 verified files do not exist in this repo). Redirected to team-lead.md anchors.

### Changes
- L41 Lifecycle: dropped "+ docs/tdd/reviewer-doubling-lifecycle.md §4.4" tail.
- L45 Re-planning: replaced "§6 continuity preamble per docs/tdd/reviewer-doubling-lifecycle.md" with "continuity preamble (per team-lead.md §Stall & Crash Recovery)".
- L47 Doubling rule: replaced "TDD §4.1" + "TDD §6" with team-lead.md Rule 8 + §Stall & Crash Recovery anchors.
- L317 Runtime Discipline opener: replaced "agents-token-optimization.md §4.5" with team-lead.md §Runtime Discipline anchor.

### Dimensions Evaluated
Spec Alignment (PRIMARY — No Guessing violation closed)

### Rename
No rename.

## 2026-05-26 (Phase 1 — planner FINAL-tool-call + two-step claim ritual)

### Summary
Encoded planner shutdown semantics (FINAL TOOL CALL on approval turn; CLOSED-set boundary callout) and embedded the two-step claim ritual in the standard/complex issue description template — the docket-auditor's primary capability-growth recommendation enabling team-lead's proactive `docket issue list -a <role> -s in-progress --json` liveness probe. Consolidation: collapsed re-engagement duplication between Strict Ephemeral Lifecycle and Plan Monitoring; trimmed redundant TDD §4.1 verbatim quote. Net -1 line (389 → 388).

### Changes
- §Strict Ephemeral Lifecycle: planner `shutdown_request` is FINAL TOOL CALL on approval turn; async-by-design caveat ("do NOT continue working after emitting"); explicit "NOT in CLOSED persistent set" boundary callout.
- §Plan Monitoring (re-engagement): collapsed duplicated lifecycle backstory; kept unique first-turn duties + portfolio-rollup guidance.
- §Issue Template: added `Claim Ritual` footer prescribing two-step claim (`docket issue edit -a @<role>` + `docket issue move in-progress`) — the mechanism enabling team-lead's proactive sweep probe.
- §Doubling rule on planning: trimmed redundant TDD §4.1 verbatim quote.

### Dimensions Evaluated
Actionability (PRIMARY — planner exit sequence, two-step claim) · Boundary Clarity (CLOSED-set callout) · Capability Growth (claim ritual = proactive-monitoring enabler) · Consolidation & Trimming (re-engagement dedup + TDD quote trim)

### Rename
No rename.

## 2026-05-25 (Phase 2 coherence — P7a drop)

### Summary
Single coherence fix: dropped dead "(P7a)" cross-reference from R7 exception clause (fleet-wide cleanup).

### Changes
- §R7 exception clause: dropped "(P7a)" suffix

### Dimensions Evaluated
Actionability (dead-reference removal)

### Rename
No rename.

## 2026-05-25 (Phase 1 self-review — docs-dir fallback + memory threshold)

### Summary
Four targeted fixes addressing the confirmed session-d4949934 docs-dir error, empty-memory root cause (over-conservative "recurring" threshold), a redundant lifecycle note, and a CLI audit doc gap. Net: 0 lines.

### Changes
- §Operating Context: Compressed "Persistent advisor consults" paragraph to one line (redundant with §Cross-Agent Communication)
- §Core Responsibilities > Check specs: Added `ls -d docs/tdd docs/ux docs/spec 2>/dev/null` guard — skip absent dirs silently (fixes audit error in session d4949934)
- §Shutdown Handling: Rewrote memory-check trigger — operator priority/routing signals now save on **first occurrence** (not "recurring" only); removes the threshold that was causing zero memory writes across all sessions
- §Docket CLI Reference: Added `"0"` as alternative to `"none"` for `--parent` flag per CLI audit

### Dimensions Evaluated
Role Realism · Actionability (docs-dir fix) · Boundary Clarity · Completeness · Consolidation & Trimming · Capability Growth (memory threshold) · Spec Alignment (CLI fix) · Rename

### Rename
No rename.

## 2026-05-24 (Phase 2 coherence — shutdown_response routing rule)

### Summary
Closed the 6 historical shutdown-routing errors by adding the routing rule to the Shutdown Handling section. `planner` ephemerals shut down after operator plan approval and routinely have active SendMessage threads with multiple peers (@staff-engineer for arch consults, team-lead for plan delivery) — routing rule belongs adjacent to the timing rule. No file-size change.

### Changes
- Shutdown Handling: inserted Routing clause inline — `shutdown_response` ALWAYS addressed to team-lead, never to peer agents or the original dispatcher.

### Dimensions Evaluated
Cross-Agent Coherence (PRIMARY) · Actionability (rule visibility for `planner` / `planner-fix-{N}` ephemerals)

### Rename
No rename.

## 2026-05-19 (Phase 2 coherence — memory channel activation)

### Summary
Activated the dormant `.claude/agent-memory/project-manager/` channel via a shutdown-time memory check. Reinforces the existing memory-description examples (scope-pressure priorities, scope-creep patterns) with a behavioral trigger.

### Changes
- Shutdown Handling: added memory check before approving shutdown — append recurring planning pitfalls (operator priority signal under scope pressure, recurring scope-creep pattern by codebase area, stakeholder routing preference, non-obvious planning symptom→diagnosis→resolution) to `.claude/agent-memory/project-manager/pitfalls.md`. Skip if nothing recurring surfaced.

### Dimensions Evaluated
Capability Growth & Cross-Communication (PRIMARY — dormant channel activated) · Coherence (parallel to team-lead + staff-engineer + security-engineer wrap-up nudges).

### Rename
No rename.

## 2026-05-19 (Phase 2 coherence)

### Summary
Canonical "Visibility contract" heading alignment + cross-cutting-fallback clause + `[PM→team-lead]` escalation prefix for fleet symmetry. Universal-mirror rule was already correct.

### Changes
- §Cross-Agent Communication: renamed "Operator-visibility contract" → "Visibility contract" (canonical heading); added cross-cutting-fallback clause (pick most-affected issue when no single issue applies); added `[PM→team-lead]` escalation prefix for parity with siblings.

### Dimensions Evaluated
Cross-Agent Coherence (PRIMARY — canonical heading + escalation prefix).

### Rename
No rename.

## 2026-05-19

### Summary
Sibling-coherence: add `ux-advisor` canonical persistent name for @ux-designer consults. Trim duplication between the "no guessing" framing and Epistemic Discipline / §What You Are NOT.

### Changes
- §Cross-Agent Communication peer-consult list: added `(canonical persistent name: `ux-advisor`)` to @ux-designer entry, matching the form used for `advisor` and `security-advisor`.
- §intro: collapsed the "Rigorous, honest, no guessing" paragraph to the unique pushback framing; verify-don't-invent intent is carried by Epistemic Discipline (rule 6), and the "never write code" boundary is already in the frontmatter, §What You Are NOT, and §Rules.

### Dimensions Evaluated
Role Realism · Actionability · Boundary Clarity · Completeness · Consolidation & Trimming (HIGHEST) · Capability Growth & Cross-Communication · Spec Alignment · Rename.

### Rename
No rename.

## 2026-05-17 (Phase 2 coherence)

### Summary
Added ADR `*` broadcast incoming trigger to match staff-engineer's outgoing broadcast pattern.

### Changes
- Incoming triggers: added ADR `*` broadcast entry for planning conventions.

### Dimensions Evaluated
Cross-agent handoff bidirectionality.

### Rename
No rename.

## 2026-05-17

### Summary
Align Communication Discipline with peer-agent canonical form (numbered rules 1–5 + `TeammateIdle` canonical stall signal). Minor trims offset additions; net 0.

### Changes
- §Communication Discipline: numbered rules 1–5, promoted lead-in sentence to rule 1 (close-the-loop), added canonical `TeammateIdle` signal reference. Rules 6–8 from peer agents intentionally omitted — PM does not execute issues (no claim-before-work, no 10-min progress signal) and shutdown lives in §Shutdown Handling.
- §Cross-Agent Communication closing: removed duplicate "AND a Docket comment" requirement (already in §Operator-visibility contract).
- §Plan Monitoring: split comma-spliced re-engagement sentence into two clauses for scanability.

### Dimensions Evaluated
Role Realism · Actionability · Boundary Clarity · Completeness · Consolidation & Trimming (HIGHEST) · Capability Growth & Cross-Communication · Spec Alignment · Rename.

### Rename
No rename.

## 2026-05-17

### Summary
Vote delegation payload synced to canonical `skills/vote/` Delegation Protocol shape (Phase 2 handoff from 2026-05-17 evolve-skills cycle). project-manager was closest to canonical pre-edit; this entry brings it byte-aligned with siblings.

### Changes
- Consensus Voting §Team mode: replaced abbreviated `delegation_request` pointer with full canonical payload (`{type, protocol_version, skill, request_id, vote_id, from, summary?}`). The `docket vote create` prerequisite was already documented; this clarifies the resulting payload shape and the `failed` response on missing `vote_id`.

### Dimensions Evaluated
Cross-skill coherence (vote-skill payload contract), Coordination & Handoff.

### Rename
No rename.

## 2026-05-16

### Summary
Phase 2 coherence: add @security-engineer to "What You Are NOT" (bidirectional gap); normalize security-advisor canonical form.

### Changes
- Added @security-engineer bullet to "What You Are NOT" — closes bidirectional cross-reference gap (all 6 other agents list security-engineer).
- Normalized first @security-engineer reference to canonical "(canonical persistent name: `security-advisor`)" form.

### Dimensions Evaluated
Bidirectional cross-references, security-advisor aliasing consistency.

### Rename
None.

## 2026-05-16

### Summary
Added Communication Discipline section enforcing closed-loop replies, receipt ack, blocker surfacing, verify-before-signoff, and saturation self-monitor; tightened Shutdown Handling to "within one turn"; documented Docket status enum and grooming foot-guns.

### Changes
- Added Communication Discipline block (+14) encoding operator rules 1-5 for PM role.
- Shutdown Handling: explicit "within one turn" reply (-3).
- Docket reference: added canonical status enum and `--orphan` deletion foot-gun (+2).
- Plan Monitoring/Re-Engagement/Cross-Workstream consolidated to prose blocks (-6).
- Merged "Rigorous honest mentor" + "No guessing" into one block (-8).

### Dimensions Evaluated
Role Realism · Actionability · Boundary Clarity · Completeness · Consolidation & Trimming · Capability Growth & Cross-Communication · Spec Alignment · Rename.

### Rename
No rename.

## 2026-05-13

### Summary
Phase 2 coherence: corrected CRITICAL banner (removed incorrect `Skill() for vote/prd` ban — PM authors PRDs directly via `Skill(prd, ...)` per workflow). Added `security-advisor` persistent-name alias to Consult peers list.

### Changes
- CRITICAL banner: removed `prd` from forbidden Skill() list; only `vote` is correctly forbidden (only nested-team-spawning operation)
- §Cross-Agent Communication "Consult peers directly": added @security-engineer (security-advisor) entry for security-feasibility consults and CVE remediation scoping; annotated @staff-engineer with `advisor` persistent-name alias

### Dimensions Evaluated
Bug fix (banner contradiction with workflow), Cross-Communication (security-advisor handoff), Coherence (persistent-name aliases)

### Rename
No rename.

## 2026-05-13

### Summary
Added explicit "Direct-to-Issues vs Formal Docs" decision rule addressing operator pain (formal docs generated for work that should go direct). Default is direct-to-issues; TDD/UX-spec/PRD required only when specific triggers fire. Plus consolidation trims. Net: -4 lines (338 → 334).

### Changes
- Added Direct-to-Issues vs Formal Docs subsection under §Plan Complexity Tiers with explicit triggers for TDD/UX-spec/PRD vs go-direct
- Trimmed §Authoring Feature-Level PRDs to mechanism-only (when-triggers moved to Tiers)
- Banner now bans Skill() for vote AND prd; renamed §Consensus Voting and compressed to one paragraph
- Trimmed CLI Reference trailing comment, §Decompose tautology, §Plan Tiers opener, §Persistent memory enumeration

### Dimensions Evaluated
Completeness (doc-vs-direct gap), Actionability, Consolidation, Boundary Clarity, Coherence (banner), Spec Alignment

### Rename
No rename.

## 2026-05-09

### Summary
Phase 2 coherence: aligned hub-and-spoke language with team-lead.md canonical model (narrow technical clarification with @senior-engineer/@sdet permitted; scope/plan/status changes still route through team-lead); closed bidirectional gap with @security-engineer's CVE / advisory broadcast.

### Changes
- §Cross-Agent Communication "Route through team-lead": softened "no direct PM↔SE/SDET channel" to align with team-lead.md §Rules canonical model
- §Cross-Agent Communication "Consult peers directly": added @senior-engineer / @sdet narrow technical clarification entry (spike clarification, ambiguous AC source, test-failure context)
- §Cross-Agent Communication "Incoming triggers": added @security-engineer CVE / advisory / security-driven scope-delta entry — closes reciprocal to security-engineer.md outgoing CVE broadcast

### Dimensions Evaluated
Coherence (PRIMARY — hub-and-spoke alignment + bidirectional triggers), Boundary Clarity, Coordination & Handoffs, Spec Alignment

### Rename
No rename.

## 2026-05-09

### Summary
Phase 1 trim: collapsed verbose Cross-Agent Communication section, tightened Pre-Flight Goal-Alignment Gate, Persistent memory, Cross-Cutting Concerns, Decompose, DoR/Self-review, Re-Engagement, and decomposition bash example. Added `docket vote link/unlink` to CLI Reference. Net: −49 lines (385 → 336).

### Changes
- Consolidated Cross-Agent Communication: merged Consult/Route/Escalate/Status subsections; preserved hub-and-spoke and operator-visibility contract
- Tightened Pre-Flight Goal-Alignment Gate, Persistent memory paragraph, Cross-Cutting Concerns, Decompose section, §10 DoR/Self-review, Re-Engagement, and decomp bash example
- Added `docket vote link/unlink` to CLI Reference (Phase 0 docket audit follow-up)

### Dimensions Evaluated
Consolidation & Trimming (PRIMARY — 8 trims, −49 NET), Coordination & Handoffs (CommComm consolidation), Capability Growth (vote link), Actionability (decisive over deliberative), Role Realism, Boundary Clarity, Completeness, Spec Alignment, Rename

### Rename
No rename.

## 2026-05-08

### Summary
Phase 3 operating discipline: extended Persistent memory to capture solutions to recurring planning problems.

### Changes
- Persistent memory now also saves solutions to recurring planning problems (symptom → diagnosis → resolution) so future plans don't re-encounter the same pitfall

### Dimensions Evaluated
Capability Growth (PRIMARY — memory captures planning problem-solution pairs)

### Rename
No rename.

## 2026-05-08

### Summary
Phase 2 coherence: surfaced the sub-agent invocation ban in the CRITICAL banner.

### Changes
- CRITICAL banner now covers both commit ban AND `/vote`/Skill/Agent/TeamCreate ban
- Existing peer-routing language (Phase 1 hub-and-spoke fix) confirmed consistent with corrected team-lead Rule 1; no body changes required

### Dimensions Evaluated
Coherence (PRIMARY — banner uniformity across fleet), Behavioral (no rule changes)

### Rename
No rename.

## 2026-05-08

### Summary
Hub-and-spoke compliance: removed direct PM→senior-engineer and PM→sdet notify channels (forbidden by team-lead.md hub-and-spoke topology — PM peer channel is advisor-only). Consolidated those triggers plus the Broadcast bullet into a single team-lead-routed block, preserving the operator-visibility contract via Docket comment mirror. Fixed invalid `blocked` Docket status in Cancellation section (statuses are `backlog | todo | in-progress | review | done`). Net: -5 lines (391→386).

### Changes
- Replaced "Notify @senior-engineer directly when", "Notify @sdet directly when", and "Broadcast" sections with a single "Route through team-lead" block aligned with hub-and-spoke topology
- Replaced `todo`/`blocked` with `todo`/`in-progress` in Cancellation section (no `blocked` status exists in Docket)

### Dimensions Evaluated
Boundary Clarity (PRIMARY — hub-and-spoke conflict resolved), Spec Alignment (Docket status enum correctness), Consolidation & Trimming (-5 lines), Cross-Communication (notify pattern realigned to team-lead canon)

### Rename
No rename.

## 2026-05-07

### Summary
Phase 2 coherence: replaced 3 remaining `blocked-by` prose sites with valid CLI relation `depends_on` (Phase 1 fixed runtime invocations; this fixes prose shorthand to prevent LLM agents from copy-pasting invalid tokens). Added persistent agent-memory paragraph aligning PM with sdet/SE/staff fleet pattern, with PM-specific guidance on operator priorities, scope-creep patterns, and stakeholder routing. Net: +6 lines (385→391).

### Changes
- Replaced `blocked-by remediation task` → `depends_on remediation task` in incoming-trigger row
- Replaced `Test (blocked-by Implement)` → `Test (depends_on Implement)` in Medium tier shape
- Replaced `Phase sub-issues (blocked-by chain)` → `Phase sub-issues (depends_on chain)` in Large tier shape
- Added Persistent memory paragraph after No-guessing rule with PM-specific signals to persist (operator scope-pressure priorities, recurring scope-creep patterns, dependency-discovery surprises, stakeholder routing) — distinct from Docket per-issue details

### Dimensions Evaluated
Spec Alignment (PRIMARY — CLI correctness in prose), Coherence with Fleet Standards (agent-memory pattern across 4 of 5 subagents), Capability Growth, Boundary Clarity (memory vs Docket separation)

### Rename
No rename.

## 2026-05-07

### Summary
Correctness fixes for invalid `blocked-by` relation token (rejected by docket CLI; verified at runtime) across three sites: §6 prose, §7 example, and CLI Reference. Documented full relation set and adopted `relates_to` for soft cross-workstream links. Upgraded parent-issue example to `-T epic`. Added `docket stats` to Session Init. Net: +1 line (384→385).

### Changes
- Replaced invalid `blocked-by` with `depends_on` in §6 prose, §7 example, and CLI Reference (3 sites)
- Documented full link relation set: `blocks | depends_on | relates_to | duplicates`
- Adopted `relates_to` for soft cross-workstream links in Cross-Workstream Coordination
- Upgraded parent-issue example from `-T feature` to `-T epic`
- Added `docket stats` to Session Init for situational awareness
- REJECTED: trim of Status & Observability bullet (line 145) — keeps canonical list of planning-status transition triggers; complementary to format rule at lines 98-101 (not duplicative)

### Dimensions Evaluated
Spec Alignment (PRIMARY — CLI correctness), Capability Growth (relates_to, stats, epic type), Consolidation & Trimming, Actionability

### Rename
No rename.

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
