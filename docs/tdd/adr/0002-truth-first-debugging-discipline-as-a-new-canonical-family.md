---
project: "main"
last_updated: "2026-06-20"
updated_by: "@staff-engineer"
status: "accepted"
---

# ADR 0002: Truth-First Debugging as a New CANONICAL Family Across All 7 Agents

## Context

Operator feedback identified a recurring failure mode in how the agent team diagnoses failures: leaning into a hypothesis and shipping a best-guess fix instead of first surfacing the real failure signal. When a system hides the truth (generic/sanitized/swallowed error, no visibility into the actual failing environment, a self-built reproduction standing in for the real cause, or several causes producing one symptom), a fix built on an unobserved root cause burns a full implement→review→deploy cycle and leaves the team no smarter. The directive: every agent must surface the real failure signal — instrument before theorizing, treat reproduction as "can produce" not "is the cause," and label evidence OBSERVED vs REPRODUCED vs INFERRED — before any root-cause fix ships.

The team already carries three "maintained master + per-agent LOCAL copy" canonical families in `src/user/claude-code/agents/team-lead.md` — `CANONICAL:SHUTDOWN-PROTOCOL`, `CANONICAL:VORPAL-TOOLS`, and `CANONICAL:DOCS-PATHS` — each with `CANONICAL:{NAME}-LOCAL` copies in the other agent files, maintained from the master. team-lead.md Rule 5 documents a deliberate rule-numbering asymmetry across agents that must be preserved (issue-claiming agents carry claim-first rules; doc/review agents do not), and Rule 6 already governs general assertion-grounding (Epistemic Discipline). This decision adds the discipline without perturbing either.

This ADR records the decisions made during the design + review of the rollout (Docket DKT-30): the discipline itself, the housing choice, the per-role tailoring split, the accepted line-budget cost, and the new-family precedent. It is authored post-rollout — the 7-file change was designed, implemented, and reviewed (verdict: Approve, 0 blockers) before this ADR was written.

## Decision

Adopt **Truth-First Debugging (TFD)** as a fourth `CANONICAL` family. The maintained master lives in `team-lead.md` as a new trailing `## Truth-First Debugging` section (after `## Runtime Discipline`), bounded by `CANONICAL:TRUTH-FIRST-DEBUGGING:BEGIN/END`. It carries: the core principle + banner ("If the system is hiding the error, the first fix is to stop it hiding the error. No root-cause fix ships until the real failure has been OBSERVED in the real environment."); the triggers; five lettered sub-rules (TFD-1 instrument-before-theorize, TFD-2 reproduction≠truth, TFD-3 state-the-falsifier-first, TFD-4 prefer-the-discriminating-measurement, TFD-5 label-every-claim OBSERVED/REPRODUCED/INFERRED); banned moves; a four-item pre-fix gate; and the why-faster-not-slower rationale. The master cross-links Rule 6 ("complements... does not restate") rather than duplicating it, and adds an orchestration-application sentence binding the Review/Verification phases (steps 14-15): do not accept a teammate's root-cause claim or fix sign-off whose root cause was never OBSERVED in the real failing environment.

The other six agents carry a compact `CANONICAL:TRUTH-FIRST-DEBUGGING-LOCAL` copy whose first line is the house-style pointer `**Truth-First Debugging (this role).** Master: team-lead.md §CANONICAL:TRUTH-FIRST-DEBUGGING.`, role-tailored by what each agent actually does:

- **senior-engineer** (heaviest consumer — ships fixes): full LOCAL in `### Verification Feedback Loop`, carrying the BINDING pre-fix gate and instrument-first-is-your-first-deliverable.
- **sdet** (verification/labeling): LOCAL in `### Test Failure Diagnosis` threading the existing reproduce/flaky steps, plus a one-line cross-ref in `### Verification Output` tying the OBSERVED/REPRODUCED/INFERRED ladder to the verify-ac verdict ladder.
- **staff-engineer** and **security-engineer** (diagnosis-review): LOCALs that make an unobserved root cause a review finding (Concern/Blocker, or Critical/High for security) and demand the discriminating measurement.
- **project-manager** and **ux-designer** (trimmed): principle + banner + one role line only (PM: don't decompose a fix issue on an INFERRED/REPRODUCED-only cause; UX: capture OBSERVED behavior before attributing spec-gap vs impl-bug). The pre-fix gate and TFD-1..5 detail are deliberately omitted — neither role writes or verifies fixes.

## Consequences

**Positive.** The team now has one canonical, role-appropriate discipline that forces the real failure signal to surface before a fix ships — the operator's stated goal. The orchestration-application sentence makes it enforceable at the review/verification gates, not just aspirational. Reusing the established master+LOCAL mechanism means future evolve-agents and drift-lint cycles treat TFD identically to the existing three families (same marker shape, same `Master: ...` pointer line), with no special-casing. The Rule-6 cross-link avoids a fourth restatement of Epistemic Discipline and its attendant drift hazard.

**Negative / harder.** team-lead.md grows by ~49 lines to 637 (the master + orchestration sentence), pushing its line-budget breach from +88 to **+137 over the 500-line hard limit tracked in DKT-27 Item 2**. This breach is accepted deliberately (see Alternatives Considered → Option B) on the condition that DKT-27 budget remediation **compacts existing prose and does not relocate the TFD master** out of team-lead — relocating just one master would create a permanent "why is this one different?" asymmetry in the family mechanism. The maintained master now imposes a fourth byte-consistency obligation: any future edit to the TFD master must be propagated to the six LOCALs (the banner, in particular, must stay byte-identical — verified at rollout as present in 7/7 files). Two-variant tailoring (full vs trimmed) means a future maintainer must respect that pm/ux intentionally omit the pre-fix gate and TFD-N detail; re-adding them would be over-tailoring, not a fix.

**Neutral.** No Rule or R-rule numbering changed — TFD uses its own TFD-N internal labels (exactly as SHUTDOWN uses SP-N), independent of the Rule/R-rule schemes, so Rule 5's documented asymmetry is preserved untouched (team-lead Rules still end at 9). The change is additive markdown only (+137/-0); no executable surface, trivial rollback. The TFD master is `status: accepted` immediately because it was reviewed and approved as part of the rollout, not proposed for future debate.

## Alternatives Considered

- **Option B — banner+triggers+pointer in team-lead (~10 lines), full master housed in senior-engineer.md.** Would save ~20 lines against the budget breach but makes TFD the only family not mastered in team-lead, creating a permanent special-case for every future evolve/drift cycle. Rejected: the 20-line saving is not worth a permanent asymmetry in the master/LOCAL mechanism; the budget is already in remediation backlog (DKT-27) and is better fixed by compacting existing prose. Option A (master in team-lead) was chosen.
- **Full LOCAL for all 7 agents (no trimmed variant).** Rejected: PM and UX neither write nor verify fixes, so the pre-fix gate and TFD-1..5 mechanics are dead weight in their context; the trimmed principle+banner+role-line keeps them coherent with the team-wide discipline while giving them only the one application that touches their actual workflow.
- **Fold TFD into Rule 6 (Epistemic Discipline) instead of a new family.** Rejected: Rule 6 governs general assertion-grounding; TFD governs the specific act of diagnosing a hidden failure and adds the OBSERVED/REPRODUCED/INFERRED ladder, the instrument-first ordering, and a pre-fix gate that Rule 6 does not carry. A cross-link preserves the separation of concerns without duplication.
