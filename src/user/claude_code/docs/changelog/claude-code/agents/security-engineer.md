# Changelog: security-engineer

## 2026-07-11
### Summary
Phase 3 disambiguation: removed a general-ladder severity term ("Suggestion") from security review-judgment prose — code-review-verdict SKILL.md forbids cross-ladder mixing.
### Changes
- FIX[COSMETIC]: "A Low/Info hardening nit is a Suggestion" → "...is non-blocking" — `Suggestion` is the general ladder's rung (staff), not security's (Critical/High/Medium/Low/Info).
### Dimensions Evaluated
Boundary Clarity (confusable-name / cross-file terminology bleed).
### Rename
No rename.

## 2026-07-11
### Summary
Phase 2 coherence: aligned step-9 merged-panel senior-seat text with the canonical C1 statement; reworded the Q4-closure escalation trigger, which was unroutable at cycle-close time under sdet's report-only lifecycle.
### Changes
- FIX[COSMETIC]: step-9 merged-panel senior-seat text aligned to canonical C1 (+ operational readiness sub-lens).
- FIX[SUBSTANTIVE]: Q4-closure escalation reworded to route via team-lead (fresh @sdet ephemeral) — direct @sdet SendMessage at cycle close is unroutable under sdet's report-only/no-persistent-seat lifecycle.
### Dimensions Evaluated
Boundary Clarity, Capability Growth & Cross-Communication, Spec Alignment.
### Rename
No rename.

## 2026-07-11
### Summary
Embedded Shostack's four-question threat-modeling frame with Q4 ("did we do a good job?") made required and given an explicit owner via a new closure trigger — converts threat modeling from a design-time artifact into a closed loop. Added Google's "better, not perfect" approve-threshold standard, an ADR-supersession append rule, and fixed a dangling cross-reference. Model tier CONFIRMED opus[1m], no change.
Findings: 7 → 5 sub / 1 cos / 0 rej / 1 def / 0 enc

### Changes
- AMPLIFY[SUBSTANTIVE]: Pre-Flight Gate reframed as Shostack's four-question frame (2014), naming Q1-Q3 as already-covered and Q4 as required — cited Google/Netflix-Grade Principles + Innovation Scan (convergent signal from both research and innovation-scan independently).
- AMPLIFY[SUBSTANTIVE]: new Q4-closure outgoing trigger — security-advisor confirms @sdet executed named abuse cases before a security-tracked cycle closes, mirroring team-lead's Promised-gate delivery check — cited Innovation Scan (HIGH PRIORITY finding: nothing gated that abuse cases were run).
- AMPLIFY[SUBSTANTIVE]: added Google "better, not perfect" approve-threshold standard to Approval Judgment — cited Google/Netflix-Grade Principles (google.github.io/eng-practices).
- AMPLIFY[SUBSTANTIVE]: added ADR-supersession append rule (append pointer at EOF, never inline, to avoid shifting line-number citations) — cited Historical Audit (in-repo memory lesson, security-engineer authors ADR supersessions).
- AMPLIFY[COSMETIC]: fixed dangling cross-reference ("§Teammate Stall & Crash Recovery" — no such heading in this file — now points to "§Communication Discipline rule 6").
- CULL[reviewer-proposed, rejected at apply]: a `.claude/scripts/secret_scan.sh` citation in Review Workflow step 3 was withdrawn before landing — the script does not exist yet (fails the Content Gate's Executable check); tracked as a Phase-2/Docket follow-up.

### Model tier
CONFIRMED opus[1m] — no change. 62 spawns (61 opus, 1 fable, n=1 too small for comparison); both principle (Fable-classifier-nondeterminism pin documented as load-bearing) and usage confirm the deliberate pin.

### Dimensions Evaluated
Role Realism, Actionability, Boundary Clarity, Completeness, Consolidation & Trimming, Capability Growth & Cross-Communication, Spec Alignment, Rename.

### Rename
No rename.
