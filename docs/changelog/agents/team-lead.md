# Changelog: team-lead

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
