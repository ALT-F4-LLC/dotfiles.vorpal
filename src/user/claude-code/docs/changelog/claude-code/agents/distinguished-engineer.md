# Changelog: distinguished-engineer

## 2026-07-11
### Summary
Phase 3 disambiguation: 2 fixes — ladder vocabulary ("Nits"→"Suggestions") and skeleton-round sender made explicit.
### Changes
- FIX[COSMETIC]: Craft Contract "better, not perfect" — "Nits, not Blockers" → "Suggestions, not Blockers"; DE reviews under the general ladder (Blocker/Concern/Suggestion/Question/Praise) and "Nit" is upstream Google vocabulary, not a team ladder rung.
- FIX[COSMETIC]: Mode 1 Skeleton round — sender named explicitly ("you (the author) send"); passive voice could read as staff-run on DE's behalf.
### Dimensions Evaluated
Boundary Clarity (confusable-name; multi-reading).
### Rename
No rename.

## 2026-07-11
### Summary
Phase 2 coherence: added a cite-don't-restate pointer to staff-engineer.md's Large-cycle skeleton round, which Phase 1 landed only in the fallback author's file even though the primary Large-cycle TDD author is this seat.
### Changes
- FIX[SUBSTANTIVE]: Design-authoring techniques gains a pointer to staff-engineer.md's Large-cycle skeleton round — the round was Large-only but landed only in the fallback author's file; the primary Large author (this seat) now carries it.
### Dimensions Evaluated
Completeness, Spec Alignment.
### Rename
No rename.

## 2026-07-11
### Summary
Added an operational-readiness (PRR) sub-lens to the merged acceptance panel's feasibility seat; added a Design-authoring-techniques block embedding Non-Goals + do-nothing Alternatives (Ubl), Premortem risk framing (Klein), and a pre-vote operational-readiness authoring check; folded two fresh 2026-07-11 tool-friction memory lessons; added a "better, not perfect" review-calibration counterweight.
Findings: 8 → 5 sub / 0 cos / 0 rej / 2 def / 1 enc

### Changes
- AMPLIFY[SUBSTANTIVE]: merged acceptance panel's @senior-engineer feasibility seat now explicitly covers operational readiness (rollback path, failure modes, observability) — cited Innovation Scan (PRR/launch-checklist, HIGH PRIORITY); staff-engineer.md:214 already names this lens for ad-hoc review, proving fit.
- AMPLIFY[SUBSTANTIVE]: new "Design-authoring techniques" block in Mode 1 — Non-Goals + do-nothing-alternative row (Ubl, *Design Docs at Google* 2020), Premortem risk framing (Klein HBR 2007; Mitchell/Russo/Pennington 1989), and a pre-vote operational-readiness authoring check — cited Google/Netflix-Grade Principles, written to reference the tdd skill's sections rather than duplicate its format authority.
- AMPLIFY[SUBSTANTIVE]: folded a JS-rendered-SPA WebFetch-title recovery lesson (fetch the JSON hydration endpoint before downgrading to secondary sources) into Mode 3 method gates — fresh centralized memory, dated 2026-07-11.
- AMPLIFY[SUBSTANTIVE]: folded a diff grep-filter structural-verification hazard (`grep -v '^[+-][+-]'` silently strips real +/- content lines) into Mode 2 review evidence gates — fresh centralized memory, dated 2026-07-11.
- AMPLIFY[SUBSTANTIVE]: added a "better, not perfect" counterweight to the Craft Contract's Honest Critique — cited Google/Netflix-Grade Principles (Google eng-practices); calibrates the doubled-review and coherence-reviewer seats against over-rejection.
- ALREADY-ENCODED (audit-only, no change): adr skill §3 already requires negative+neutral consequences (ADR-immutable-log finding satisfied); tdd skill §7/§10 already require rollback/observability sections (PRR section-presence satisfied — only the panel lens and authoring check were gaps); memory lesson #3 (co-author parallel briefing) already captured at line 228, dropped as redundant.

### Dimensions Evaluated
Role Realism, Actionability, Boundary Clarity, Completeness, Consolidation & Trimming, Capability Growth & Cross-Communication, Spec Alignment, Rename.

### Rename
No rename.
