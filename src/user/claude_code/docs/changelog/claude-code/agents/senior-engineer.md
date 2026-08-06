# Changelog: senior-engineer

## 2026-07-11
### Summary
Phase 3 coherence-class fix (routed by disambiguation-reviewer): acknowledged the merged-acceptance-panel senior seat that 4 sibling files (team-lead, staff-engineer, security-engineer, distinguished-engineer) already assign but this file never mentioned.
### Changes
- FIX[SUBSTANTIVE]: `/vote` section gains a "Merged acceptance panel seat" note — you cast implementation-feasibility + operational-readiness verdicts on Medium+ TDD votes; previously this duty was one-sided (assigned by 4 sibling files, unacknowledged here).
### Dimensions Evaluated
Completeness, Boundary Clarity.
### Rename
No rename.

## 2026-07-11
### Summary
Hardened Read-before-Edit from prose reminder to a zero-intervening-tool-calls forcing rule (highest-count bug class fleet-wide, 35+16 sessions); retired dead-doctrine commit bullets contradicting the no-commit rule; folded a fresh env-allowlist lesson; added a create-verify step for silently-dropped `-l`/`-f`; embedded a Netflix-grade revert-unit-before-ship practice.
Findings: 11 → 6 sub / 1 cos / 1 rej / 3 def / 0 enc

### Changes
- AMPLIFY[SUBSTANTIVE]: Read-before-Edit hardened to "zero tool calls between Read and Edit" — cited Bug Audit B4 (35 sessions, largest class fleet-wide, hit even team-lead.md itself); existing prose rule wasn't preventing it.
- AMPLIFY[SUBSTANTIVE]: shared/appended-file re-Read rule sharpened to literal adjacency — cited Bug Audit B6 (16 sessions, mostly pitfalls.md, despite an existing scoped rule already failing to prevent it).
- CULL[SUBSTANTIVE]: retired "one logical change per commit" / "lockfile in same commit" bullets as dead doctrine under the hard no-commit rule; retargeted to diff-scope hygiene, gated commit-specific text on operator-authorized commit mode — cited Innovation Scan (Retire).
- AMPLIFY[SUBSTANTIVE]: folded fresh centralized-memory lesson (bash auto-exports PWD/SHLVL/_ regardless of passed env) into Shell hygiene.
- AMPLIFY[SUBSTANTIVE]: added create-then-verify step for `docket issue create -l/-f` silently dropping labels/files — cited Bug Audit B8 (confirmed 2x via centralized pitfalls.md).
- AMPLIFY[SUBSTANTIVE]: added "name the revert unit" to self-review — cited Google/Netflix-Grade Principles (Netflix Kayenta/rollback-designed-before-ship, adapted).
- AMPLIFY[COSMETIC]: trimmed a redundant trivial-exception parenthetical (non-redundancy pass).

### Dimensions Evaluated
Role Realism, Actionability, Boundary Clarity, Completeness, Consolidation & Trimming, Capability Growth & Cross-Communication, Spec Alignment, Rename.

### Rename
No rename.
