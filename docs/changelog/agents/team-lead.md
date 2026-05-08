# Changelog: team-lead

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
