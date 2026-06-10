# Changelog: project-manager

## 2026-06-09

### Summary
Compacted 40 entries (2026-03-19..2026-05-19) into Compacted history per ADR 0001.

### Changes
- Replaced the 40 oldest entries with one-line ledger entries in the terminal Compacted history section (DKT-264)

### Dimensions Evaluated
History Compaction (ADR 0001)

### Rename
No rename.

## 2026-06-09

### Summary
Fable-mandate pass: added prescriptive "use when" triggers for the two capability families granted in frontmatter but absent from the body (WebFetch/WebSearch, Monitor). Reasoning-echo audit clean; docket foot-guns already encoded (NO-OP). Net +1 (334 lines).

### Changes
- Added WebSearch/WebFetch usage trigger to the "No guessing" rule (external-fact verification only; never to rediscover repo facts)
- Added a Monitor start-trigger reminder to Runtime Discipline (long external jobs gating a planning decision; TaskStop before idle)
- [NO-OP, grep-cited] `-f` ≠ description body and never-trust-✔-Updated already encoded; `docket next` adoption declined (overlaps existing plan-derived ordering — Content Gate)

### Dimensions Evaluated
Prescriptive Capability Triggers (primary), Reasoning-Echo Audit (clean), Consolidation & Trimming (no cuts available)

### Rename
No rename.

## 2026-06-09

### Summary
Phase 2 lead-initiated shutdown flip: planner lifecycle (final-tool-call emit → await on approval) and Monitor-watch paragraph replaced with await-lead semantics. Count unchanged (334).

### Changes
- §Operating Context planner lifecycle flipped (FIX 30); Auto-shutdown → "Idle after plan delivery" (FIX 31). PITFALLS family fix (FIX 32).

### Dimensions Evaluated
Spec Alignment, Coherence.

### Rename
No rename.

## 2026-06-09

### Summary
Encoded $TMPDIR scratch-file discipline into the §8 body-write guard; corrected CLI-default drift verified against `issue create --help` (priority default `none`, create status `backlog` — §7 now mandates explicit `-s todo`); offset by three redundancy trims. Net 0 (334→334).

### Changes
- §8: stage scratch body files under `$TMPDIR` only — sandbox-denied `/tmp`/`$CLAUDE_JOB_DIR/tmp` writes are the root cause of the stale-body "✔ Updated" failure (fem-kubernetes pitfall).
- Docket Reference: defaults corrected — status `backlog`, priority `none`, type `task` (file wrongly marked `medium` as priority default).
- §7: explicit `-s todo` on create + bash example updated — backlog-default issues are invisible to executor `-s todo` queries.
- Three within-line trims: duplicate CLOSED-set enumeration (§Operating Context), third planner-ephemerality restatement (§Shutdown), Docket-only restatement (§Rules).

### Dimensions Evaluated
Consolidation & Trimming (3 offsets), Capability Growth ($TMPDIR), Spec Alignment (CLI defaults), Actionability (-s todo); Role Realism, Boundary Clarity, Completeness, Rename — sound.

### Rename
No rename.

## 2026-06-09

### Summary
Phase 2 fleet decision: extended the §8 `-d`-write success-line-distrust guard with the docket cwd-outside-repo silent-no-op + reconcile-by-`updated_at` discipline (within the existing line; count unchanged at 334). PM is the heaviest issue-mutator — recurring theme A.

### Changes
- §8: appended cwd guard — docket commands silently NO-OP from a cwd outside the repo tree; `cd` repo-root same Bash call + confirm `updated_at`; a stale read is not a write-failure (reconcile by timestamp, never force-write).

### Dimensions Evaluated
Capability Growth & Cross-Communication (primary), Actionability, Spec Alignment, Rename

### Rename
No rename.

## 2026-06-09

### Summary
Encoded two cross-project memory lessons as behavioral guards (trust-no-success-line after `-d` writes; enumerated-list completeness count+map), offset by compressing the triple-stated ephemeral re-spawn prose. Net +4 (330→334).

### Changes
- §8 Write Descriptions: added "never trust the success line after `issue create/edit -d`" — a sandbox-denied scratch write prints `✔ Updated` with stale/empty body; re-`show --json` + grep a marker before treating ready.
- §10 Validate and Finish: added enumerated-list completeness guard (created-child-count == N + source→ID map) against the silent-drop "done with N−1" failure class.
- §Operating Context: compressed the third restatement of the spawn→preamble re-plan lifecycle.

### Dimensions Evaluated
Consolidation & Trimming (primary), Actionability, Completeness, Boundary Clarity, Role Realism, Capability Growth, Spec Alignment, Rename

### Rename
No rename.

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

## Compacted history

Entries below were compacted per ADR 0001; full text in git history (see the compaction entry's date).

- 2026-03-19: Major consolidation from 956 to 390 lines. Collapsed verbose routing templates, compressed issue examples, removed redundant workflow summary…
- 2026-03-19: Removed 4 sections that fail Content Gate (Communication Style, Retrospective, Anti-Patterns, Decision-Making). Folded Parallelism/Dependencies…
- 2026-03-19: Added Operating context paragraph to align with the pattern established across all other agents.
- 2026-03-19: Trimmed redundancy across session init, scope negotiation, external deps, and NOT-list. Added Bash tool constraint to prevent shell drift beyond…
- 2026-03-19: Compressed status updates, removed redundant exploration checklist, merged architect NOT entry, added spike output format and blocking links to…
- 2026-03-20: Added memory and effort frontmatter, compressed cross-cutting concerns and external dependencies, removed redundant anti-pattern and vote example.
- 2026-03-20: Trimmed redundant operator-alignment restatement and effort section, removed redundant operating context sentence, added @sdet notification…
- 2026-03-20: Restructured cross-cutting concerns for scannability, removed redundant rules, added @staff-engineer spike notification trigger, added…
- 2026-03-20: Added new docket CLI commands (`plan`, `graph`, `reopen`, `label`) to reference and workflows, compressed /vote and Cancellation sections.
- 2026-03-21: Added cross-communication observability (Docket logging for SendMessage and vote), fixed CLI discrepancies (link remove syntax…
- 2026-03-29: Updated Docket CLI reference with audit findings (missing flags, corrected defaults, new subcommands), removed obsolete Delegation Protocol (PM…
- 2026-03-29: Added TaskCreate/TaskUpdate/TaskList/TaskGet to frontmatter and session initialization, connected Mermaid graph output to plan validation…
- 2026-03-30: Added rigorous honest mentor directive adapted to PM role (challenge vague requirements, surface uncomfortable scope truths, flag plan…
- 2026-04-01: Added `model: opus[1m]` to frontmatter, compressed 5 sections, added context compaction awareness. Net: -10 lines.
- 2026-04-06: Added TDD acceptance gate blocking premature decomposition. Compressed Plan Monitoring and merged Program-Level Rollup. Updated CLI reference…
- 2026-04-16: Consolidation pass: trimmed aspirational prose, compressed redundant "NEVER write code" paragraph, restructured TDD routing bullets. Phase 2…
- 2026-04-16: Cross-communication pass: restructured Cross-Agent Communication into explicit per-teammate direct-SendMessage trigger blocks (@staff-engineer…
- 2026-04-19: Embedded operator "no guessing" durable rule with concrete verification (docket show, Read, Grep, --help) at top-of-file. Trimmed Rules…
- 2026-05-05: Consolidation pass — removed duplicated "NOT a guesser" boundary bullet (covered by No-guessing rule above), circular Alignment risk bullet, and…
- 2026-05-05: Phase 0+2 capability adoption + consolidation: added `color: yellow` frontmatter for split-pane visual ID, added `docket issue label list`…
- 2026-05-06: Operator-visibility & capability-growth pass. Hoisted the cross-agent comms visibility contract (`[PM→@agent]` Docket-comment mirror) to top of…
- 2026-05-06: Phase 2 coherence pass: standardized Pre-Flight Gate to "HARD GATE" terminology (fleet majority — matches senior/sdet/ux). No cross-comm changes…
- 2026-05-07: BALANCED-mode trim pass at 406 lines: removed redundant Operating-context paragraph (covered by fleet pattern), tightened Session Init step 3…
- 2026-05-07: Phase 2 coherence: removed duplicate HARD GATE marker on adjacent lines for cleaner gate phrasing.
- 2026-05-07: Correctness fixes for invalid `blocked-by` relation token (rejected by docket CLI; verified at runtime) across three sites: §6 prose, §7…
- 2026-05-07: Phase 2 coherence: replaced 3 remaining `blocked-by` prose sites with valid CLI relation `depends_on` (Phase 1 fixed runtime invocations; this…
- 2026-05-08: Hub-and-spoke compliance: removed direct PM→senior-engineer and PM→sdet notify channels (forbidden by team-lead.md hub-and-spoke topology — PM…
- 2026-05-08: Phase 2 coherence: surfaced the sub-agent invocation ban in the CRITICAL banner.
- 2026-05-08: Phase 3 operating discipline: extended Persistent memory to capture solutions to recurring planning problems.
- 2026-05-09: Phase 1 trim: collapsed verbose Cross-Agent Communication section, tightened Pre-Flight Goal-Alignment Gate, Persistent memory, Cross-Cutting…
- 2026-05-09: Phase 2 coherence: aligned hub-and-spoke language with team-lead.md canonical model (narrow technical clarification with @senior-engineer/@sdet…
- 2026-05-13: Added explicit "Direct-to-Issues vs Formal Docs" decision rule addressing operator pain (formal docs generated for work that should go direct).…
- 2026-05-13: Phase 2 coherence: corrected CRITICAL banner (removed incorrect `Skill() for vote/prd` ban — PM authors PRDs directly via `Skill(prd, ...)` per…
- 2026-05-16: Added Communication Discipline section enforcing closed-loop replies, receipt ack, blocker surfacing, verify-before-signoff, and saturation…
- 2026-05-16: Phase 2 coherence: add @security-engineer to "What You Are NOT" (bidirectional gap); normalize security-advisor canonical form.
- 2026-05-17: Vote delegation payload synced to canonical `skills/vote/` Delegation Protocol shape (Phase 2 handoff from 2026-05-17 evolve-skills cycle).…
- 2026-05-17: Align Communication Discipline with peer-agent canonical form (numbered rules 1–5 + `TeammateIdle` canonical stall signal). Minor trims offset…
- 2026-05-17: Phase 2 coherence: Added ADR `*` broadcast incoming trigger to match staff-engineer's outgoing broadcast pattern.
- 2026-05-19: Sibling-coherence: add `ux-advisor` canonical persistent name for @ux-designer consults. Trim duplication between the "no guessing" framing and…
- 2026-05-19: Phase 2 coherence: Canonical "Visibility contract" heading alignment + cross-cutting-fallback clause + `[PM→team-lead]` escalation prefix for…
