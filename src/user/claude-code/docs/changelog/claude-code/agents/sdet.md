# Changelog: sdet

## 2026-07-11
### Summary
Added a red-green fail-first evidence gate closing the hollow-green test class; added Google test-size (small/medium/large) classification with smallest-size justification; added a Production Readiness lens for runtime-surface diffs; added a Netflix-chaos-derived negative-path/failure-injection rule. Model tier RETAINED at opus[1m] on error-rate evidence.
Findings: 8 → 4 sub / 1 cos / 0 rej / 3 def / 0 enc

### Changes
- AMPLIFY[SUBSTANTIVE]: Testing Philosophy now requires every new test ship recorded evidence it FAILS against pre-fix/mutated code — cited Innovation Scan (Rethink: closes the hollow-green class my own Coverage Principles warn about but never gated).
- AMPLIFY[SUBSTANTIVE]: Test Pyramid now classifies by SIZE (small/medium/large hermeticity, not just type) and requires justifying every new test at the smallest size that catches its defect class — cited Google/Netflix-Grade Principles (Google Testing Blog 2010/2015, SWE-at-Google ch.11-12).
- AMPLIFY[SUBSTANTIVE]: added a 3-row Readiness lens (rollback path / failure-mode / docs-updated) for runtime-surface diffs, skipped for docs/config-only — cited Google/Netflix-Grade Principles (SRE launch checklist / PRR).
- AMPLIFY[SUBSTANTIVE]: added a negative-path rule requiring failure-injection tests for claimed resilience/fallback behavior — cited Google/Netflix-Grade Principles (Netflix chaos falsifiable-hypothesis, non-redundant delta over existing TFD-4 coverage).
- AMPLIFY[COSMETIC]: trimmed a redundant "report-only verifier has no SendMessage" restatement (7th occurrence).
- CULL[reviewer-proposed, rejected at apply]: a `.claude/scripts/flaky_confirm.sh` citation was withdrawn before landing — the script does not exist yet (fails the Content Gate's Executable check); tracked as a Phase-2/Docket follow-up.

### Model tier
RETAINED opus[1m] — no frontmatter change. Evidence: 78 spawns (46 opus / 32 sonnet), opus shows ~3.5x lower error rate (0.24 vs 0.84 errors/spawn) on comparable balanced samples with no documented task-tier split to explain it as selection bias — the strongest error-rate gap in the Phase 0 audit. Per the Improvement-Only Mandate this outweighs the innovation-scanner's routing-table-consistency argument for a downgrade.

### Dimensions Evaluated
Role Realism, Actionability, Boundary Clarity, Completeness, Consolidation & Trimming, Capability Growth & Cross-Communication, Spec Alignment, Rename.

### Rename
No rename.
