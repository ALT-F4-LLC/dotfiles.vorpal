# Changelog: team-lead

## 2026-05-24

### Summary
Encoded DKT-37 / DKT-40 operator-prescribed resolution (independently corroborated by historical audit: 9 state-divergence shutdown-rejections from impl-DKT-40 + 6 wrong-recipient routing errors). Added shutdown-async clarification, pre-shutdown state-verification gate, state-divergence-rejection trust rule, mid-cycle redirect-race rule, label-discipline rule, and routing reminder requirement. Dropped stale "unverified" disclaimer on docket plan --watch (verified by docket-auditor). Added agent-memory bootstrap note. Net +15 lines (425 → 440).

### Changes
- Teammate Stall & Crash Recovery: prepended Shutdown protocol (async-by-design) + mandatory Pre-shutdown state-verification gate (git diff --stat + docket issue show + reconcile-or-probe + cite verification + routing reminder) + Trust state-divergence rejections + Mid-cycle redirect-race rule + Label-discipline rule. Encodes operator pitfall points 1-5.
- Step 12: added (c) pre-shutdown gate cross-reference; collapsed redundant "no keep alive" narrative.
- Step 13: collapsed redundant "Confirm completed ephemerals exited" bullet to one-line Rule 7 cross-ref.
- Teammate Stall section: collapsed redundant Fix-loop re-spawn paragraph (kept inline preamble enumeration; removed restated-elsewhere framing).
- Step 12 Long-running phases: dropped stale "(unverified)" parenthetical on `docket plan --json --watch`; noted interval default 2s.
- Step 16 Memory check: added `mkdir -p .claude/agent-memory/team-lead` bootstrap (directory does not yet exist).

### Dimensions Evaluated
Actionability (PRIMARY — encodes operator resolution as concrete commands + sequence) · Boundary Clarity (state-divergence rejection authority) · Consolidation & Trimming (3 redundancy collapses offset 1 substantive addition) · Spec Alignment (verified docket flags) · Completeness (bootstrap gap)

### Rename
No rename.

## 2026-05-19 (P1 brief-authoring + lifecycle hygiene + memory activation)

### Summary
Encoded the operator's P1 lesson (DKT-6 brief-authoring contradiction) as a Closed-vs-Open dimension rule + detector in the @senior-engineer Spawning Template. Added a TeamCreate lifecycle pre-flight to eliminate 24 recurring `Already leading team` errors. Activated the dormant agent-memory channel via a wrap-up nudge gated on "recurring pitfall." Offset with three exhortation-tail trims plus an Epistemic Discipline annotation. Net +5 lines (359 → 364).

### Changes
- @senior-engineer Spawning Template: added Brief-Authoring Discipline (Closed vs Open per dimension) + detector — author MUST grep own brief for prescriptive overlap with the consult list and collapse to one.
- Team Setup step 1: added Lifecycle pre-flight — on `Already leading team` error, run TeamDelete on the named prior team and retry.
- Wrap-up step 16: added Memory check — append `symptom → root cause → resolution` entry to `.claude/agent-memory/team-lead/pitfalls.md` ONLY on recurring pitfalls.
- Step 13: removed moralizing tail about stale-claim history; behavior is already in the Flag-discrepancy line.
- Rule 2: removed exhortation tail; the spot-check-as-high-stakes-event is already enumerated.
- Pattern Decision Tree: removed over-orchestration restatement; L60 already prescribes lightest-pattern-default.
- Step 12 Long-running phases: annotated `docket plan --json --watch` as unverified per Rule 6.

### Dimensions Evaluated
Actionability (PRIMARY — P1 brief-authoring rule + detector) · Capability Growth (lifecycle hygiene + memory activation) · Consolidation (three exhortation trims) · Epistemic Discipline (unverified-CLI annotation).

### Rename
No rename.

## 2026-05-19

### Summary
Tightened orchestrator contracts around the vote-skill handoff, tool envelope, and operator-visibility convention based on historical audit findings (delegation `from`-field gap, Edit-tool errors, prefix-convention drift, AskUserQuestion option-cap errors). Net +4 lines (355 → 359), within BALANCED budget.

### Changes
- Consensus Integration: added explicit Delegation relay contract — verify `skill`/`vote_id`, run standalone vote, relay result to `delegation_request.from`, mirror to operator.
- Lead role declaration: stated tool envelope explicitly (no Edit/Write) to prevent unsupported-tool errors.
- Operator-visibility Rule 2: codified `[{ROLE}→@{recipient}]` prefix convention beyond `[LEAD→]`.
- Pre-flight step 4 + new hard rule: AskUserQuestion ≤4 options per question.
- Direct Task pattern footer: trimmed redundant decision-tree restatement.

### Dimensions Evaluated
Capability Growth & Cross-Communication (PRIMARY — vote handoff) · Boundary Clarity (tool envelope) · Cross-Agent Coherence (prefix table) · Actionability (option-cap rule) · Consolidation (Direct Task trim).

### Rename
No rename.

## 2026-05-17 (Phase 2 coherence)

### Summary
Documented intentional execution-vs-doc Communication Discipline rule-numbering asymmetry as Rule 5.

### Changes
- Rules section: appended Rule 5 documenting the execution (1-8+) vs doc (1-6) vs PM (1-5) rule-numbering convention.

### Dimensions Evaluated
Convention documentation; future-cycle coherence durability.

### Rename
No rename.

## 2026-05-17

### Summary
Consolidation pass: -28 lines target by collapsing redundant guidance that already lives in Security Track, step 13 spot-check protocol, and recovery recipe. No behavioral changes — every removed phrase was a restatement of guidance present elsewhere in the file.

### Changes
- Review Phase parallel-security explainer collapsed to one-line pointer to Security Track.
- Wrap-up spot-check restatement removed; cross-refers to step 13.
- Context-saturation handoff condensed; defers to recovery recipe.
- Probe-once rule tightened.
- Common scaffolding auto-resume note tightened; ux-advisor added to alias list.
- Re-plan on divergence moralizing tail removed.
- Pattern Decision Tree closing exhortation condensed.
- Security Track Small bullet phrasing tightened.

### Dimensions Evaluated
Consolidation & Trimming (PRIMARY), Role Realism, Completeness, Coherence.

### Rename
No rename.

## 2026-05-16

### Summary
Phase 2 coherence: align @senior-engineer Spawning Template with Rule 7 (claim-first ordering).

### Changes
- Reordered the "BEFORE starting" line to put `docket issue move <id> in-progress` as FIRST tool call on dispatch, then `comment list`. Matches senior-engineer.md Rule 7 and sdet.md new Rule 7. Stall-detection signal (e) already aligned.

### Dimensions Evaluated
Claim-before-work ordering parity between Spawning Template and teammate workflows.

### Rename
None.

## 2026-05-16

### Summary
Added orchestrator-side controls for the communication-discipline rules: context-saturation handoff protocol (rule 3), claim-before-work and 10-min progress-silence stall signals (rules 7+8), and SendMessage auto-resume note for stopped advisors. Consolidated triple-bucket triage into Pattern Decision Tree.

### Changes
- Consolidated three-bucket triage block into Pattern Decision Tree (-15) — duplicate guidance.
- Added "Context-saturation handoff" protocol to Stall & Crash Recovery (+6) — teammate-initiated respawn with continuity briefing.
- Stall detection list: added (e) claim-before-work failure and (f) >10-min progress silence (+3).
- Documented SendMessage auto-resume for stopped advisors in Common scaffolding (+1).
- Operator-visibility contract now lists spot-check discrepancies as high-stakes events (+2).

### Dimensions Evaluated
Role Realism · Actionability · Boundary Clarity · Completeness · Consolidation & Trimming · Capability Growth & Cross-Communication · Spec Alignment · Rename.

### Rename
No rename.

## 2026-05-13

### Summary
Phase 2 coherence: renamed UX persistent teammate spawn to canonical "ux-advisor" (aligns with advisor/security-advisor pattern); annotated `docket issue close` with no-`-m` clarification in @senior-engineer Spawning Template.

### Changes
- @ux-designer Spawning Template: `name="ux-spec-author"` → `name="ux-advisor"`; matches ux-designer.md canonical persistent name
- Wrap-up shutdown list updated: `ux-spec-author if spawned` → `ux-advisor if spawned`
- @senior-engineer Spawning Template close-out: added `(no -m flag)` annotation inline

### Dimensions Evaluated
Coherence (canonical persistent-name alignment), Actionability (close-flag annotation)

### Rename
ux-spec-author → ux-advisor (spawn name in team-lead.md only; aligns with canonical persistent-teammate naming).

## 2026-05-13

### Summary
Added **Direct Task** orchestration pattern (single @senior-engineer, no PM/review/team) addressing operator pain — documentation overhead generated for trivial work. Sharpened Pattern Decision Tree thresholds with concrete quantification (file counts, phase counts) and explicit "default to the lightest pattern" bias. Offset via trims to Review parallel-explainer, Re-plan block, Monitor block, and minor edits. Net: -2 lines (344 → 342).

### Changes
- New **Direct Task** pattern: trivial single-edit work (rename, typo, dep bump, log tweak, ≤3 files, no design) spawns ONE @senior-engineer in solo mode, no TeamCreate, no @project-manager planning, no @staff-engineer review
- Sharpened Pattern Decision Tree: 5 sizing steps (was 4), explicit file-count/phase-count thresholds, "default to lightest" footer
- Pre-flight step 4 ambiguity AskUserQuestion now includes Direct (5 options), biased to lighter
- Team Setup marks TeamCreate as skipped for Direct Task
- Trimmed Re-plan on divergence (3 lines), parallel-review explainer (security-vs-general dimension list now lives only in Security Track and security-engineer Spawning Template), Monitor block, HARD GATE phrasing, persistent-memory line, Wrap-up final bullet

### Dimensions Evaluated
Completeness (operator pain on over-documentation; Direct Task), Actionability, Consolidation, Coherence, Role Realism, Boundary Clarity, Capability Growth

### Rename
No rename.

## 2026-05-09

### Summary
Trimmed redundant spawning-template scaffolding (hoisted common Agent() / Verified goal / `<user_request>` boilerplate into a single preamble), fixed step-numbering collision between Design Phase and Planning Phase (which restarted at 4), promoted TeammateIdle hook as canonical stall signal, and added `docket vote link` post-commit. Net: −95 lines (439 → 344).

### Changes
- Hoisted common spawning scaffolding into a single preamble; trimmed all 8 templates: @staff-engineer (TDD + Code Review), @security-engineer (TDD + Review), @project-manager, @ux-designer, @senior-engineer, @sdet
- Fixed step-numbering collision: phases renumbered into a single 1-16 sequence (Team Setup 1-2, Design 3-6, Planning 7-10, Implementation 11-13, Review 14, Verification 15, Wrap-up 16); cross-references updated
- Added `docket vote link {vote-id} --issue {DOCKET-ID}` to Consensus Integration so votes unblocking a specific issue are traceable
- Promoted `TeammateIdle` hook to canonical stall signal in Stall & Crash Recovery (cheaper and more accurate than 10-min TaskList polling)
- Tightened persistent-memory paragraph parenthetical

### Dimensions Evaluated
Consolidation & Trimming (PRIMARY — 7 of 12 changes), Actionability (step-numbering correctness), Completeness (vote-link integration, TeammateIdle promotion), Capability Growth, Spec Alignment, Boundary Clarity, Role Realism, Rename

### Rename
No rename.

## 2026-05-08

### Summary
Phase 3 operating discipline: added Persistent memory section to capture solutions to non-obvious orchestration problems.

### Changes
- Added Persistent memory paragraph at top: save operator priorities, recurring orchestration pitfalls (stall classes, fix-loop offenders, re-plan triggers), AND solutions to non-obvious coordination problems (symptom → root cause → resolution) so future cycles don't re-discover the same gap; explicit do-not-save list (per-cycle plan details, teammate reports — those live in Docket/changelogs)

### Dimensions Evaluated
Capability Growth (PRIMARY — orchestrator now persists cross-cycle learning), Coherence (memory format aligned with fleet bold-prefix paragraph convention)

### Rename
No rename.

## 2026-05-08

### Summary
Phase 2 coherence: broadened Rule 1 hub-and-spoke description to match fleet reality — the prior 4-pair allowlist contradicted documented peer triggers in every teammate file.

### Changes
- Rule 1 now allows any peer pair for narrow technical clarification (architecture, shared-interface, test-failure, design-QA, spec-feasibility) while reserving team-lead as relay for cross-cutting decisions (re-plans, scope changes, vote delegation, escalations, stall recoveries, plan revisions to in-flight issues)

### Dimensions Evaluated
Coherence (PRIMARY — canonical→reality alignment), Behavioral (preserves the actual rule that teammates already follow), Concrete (enumerates which classes route through hub vs. peer-to-peer)

### Rename
No rename.

## 2026-05-08

### Summary
Fixed `TaskCreate` API misuse in Team Setup (no `depends_on` parameter exists; dependencies are set via `TaskUpdate` `addBlockedBy`). Removed redundant /vote prohibition from the TDD spawning template — already covered by the file-top CRITICAL banner. Net: -1 line.

### Changes
- Fixed Team Setup step 2: `TaskCreate ... set depends_on` → `TaskCreate` then `TaskUpdate ... addBlockedBy` (correctness bug — `depends_on` is not a valid TaskCreate parameter; phases would silently lack ordering)
- Removed `Do NOT invoke /vote for TDD approval` clause from the @staff-engineer (TDD) spawning template — duplicates the CRITICAL banner which already prohibits all teammates from invoking /vote, Skill(), Agent(), TeamCreate

### Dimensions Evaluated
Spec Alignment (PRIMARY — TaskCreate API correctness), Consolidation & Trimming, Actionability

### Rename
No rename.

## 2026-05-07

### Summary
Fixed invalid `docket issue graph --direction blocks` flag value (verified at runtime). Added Monitor tool guidance for long-running phases and explicit hub-and-spoke topology rule with allowed peer-to-peer exceptions. Trimmed HARD GATE phrasing and Implementation Phase parallelism guidance to offset additions. Net: 0 lines (360→360).

### Changes
- Fixed `docket issue graph --direction blocks` → `--direction up` (line 292) — invalid flag value; valid values are up/down/both. "Blast-radius before re-planning" semantically maps to `up` (which dependents would be affected)
- Added Monitor tool usage in Implementation Phase step 9 for streaming docket state changes during long-running phases (10+ minutes); surfaces stalls before the 10-min TaskList threshold
- Added Hub-and-spoke topology rule explicitly listing allowed peer-to-peer SendMessage exceptions (PM↔advisor, senior↔advisor, senior↔senior, sdet↔senior); cross-cutting decisions (re-plan/scope/escalation/votes) route through orchestrator
- Trimmed HARD GATE phrasing (Pre-flight step 1) — merged duplicative re-ask + don't-proceed clauses
- Trimmed Implementation step 8 parallelism guidance from 4 lines to 1; preserved 5-per-turn limit

### Dimensions Evaluated
Spec Alignment (PRIMARY — correctness bug), Capability Growth & Cross-Communication (Monitor + hub-and-spoke), Consolidation & Trimming, Actionability

### Rename
No rename.

## 2026-05-07

### Summary
First evolve cycle for team-lead since extraction from /dev skill (cf9a8d0). Added fleet-standard `[LEAD→@agent]` operator-visibility prefix to mirror inter-agent SendMessage to Docket comments. Fixed broken "Handling Failures below" cross-reference. Standardized HARD GATE header to fleet pattern. Trimmed redundancy in shutdown phrasing, Consensus Integration, and Pre-flight step 4. Added Docket CLI pointer for `--root` and `issue graph --direction` per audit.

### Changes
- Added `[LEAD→@agent]` operator-visibility contract in Rules (mirrors staff/senior/sdet pattern); folded Rule 1 into the contract
- Fixed broken "see Handling Failures below" reference → "see Teammate Stall & Crash Recovery below"
- Standardized HARD GATE header in Pre-flight step 1 (matches fleet wording)
- Trimmed shutdown phrasing in step 9 (removed misleading small-task clause)
- Compressed Consensus Integration paragraph (removed criticality criteria duplicated in skills/vote/)
- Tightened Pre-flight step 4 (decision tree IS the assessment mechanism)
- Added `docket plan --root` and `docket issue graph --direction blocks` capabilities to step 10 phase verification

### Dimensions Evaluated
Consolidation & Trimming (PRIMARY — 4 of 7 changes), Capability Growth & Cross-Communication (operator-visibility prefix + Docket CLI), Completeness (broken cross-ref), Coherence with Fleet Standards (HARD GATE), Role Realism, Actionability, Boundary Clarity, Spec Alignment, Rename

### Rename
No rename. "team-lead" is the canonical orchestrator role name across the fleet.
