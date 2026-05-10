# Changelog: security-engineer

## 2026-05-09

### Summary
Phase 2 coherence: anchored canonical teammate name "security-advisor" to team-lead.md §Spawning Templates so naming stays consistent if team-lead.md ever renames.

### Changes
- §Operating context: replaced generic "spawned as a persistent advisor" with "named 'security-advisor'" plus reference to team-lead.md §Spawning Templates as the canonical name authority

### Dimensions Evaluated
Coherence (PRIMARY — canonical name anchoring), Spec Alignment, Role Realism

### Rename
No rename.

## 2026-05-09

### Summary
Phase 1 self-review (initial entry). Trimmed redundant preambles and verbose Review Output paragraph; merged duplicate incoming triggers per peer; added concrete handoff trigger for verdict-reconciliation with @staff-engineer; adopted AskUserQuestion `multiSelect` for multi-adversary threat scoping. Net: −13 lines (340 → 327).

### Changes
- Trimmed Honest Risk Critique two-paragraph framing; merged "Surface-level mitigations" rule into a single tight block (Consolidation)
- Compressed "When to Create a Security TDD" — merged "Skip" + "Ask when uncertain" into one decisive bullet (Consolidation, decisiveness)
- Compressed "Match formality" preamble into the Responsibility 3 header line; removed redundant "Lightweight Security Advisory" subsection wrapper (Consolidation)
- Compressed Review Output paragraph (line 208) — skill is format authority; kept only the routing/reconcile/escalate ownership clause (Consolidation, decisiveness)
- Merged duplicate @staff-engineer incoming triggers (review-handoff + TDD-handoff → one) and @sdet incoming triggers (abuse-case design + test failure → one) (Coordination & handoffs)
- Added outgoing trigger: parallel-review verdict conflict with @staff-engineer → reconcile before merge to avoid contradictory operator-facing recommendations (Coordination & handoffs)
- Pre-Flight Gate: clarified that adversary scope is `multiSelect: true` (threat models often span multiple adversaries) — concrete capability adoption (Capability Growth)

### Dimensions Evaluated
All 8: Consolidation (PRIMARY — preamble redundancy, duplicate triggers, verbose review-output), Coordination & Handoffs (parallel-review reconciliation trigger, decisive responses), Role Realism, Actionability, Boundary Clarity, Completeness, Capability Growth (multiSelect adoption), Spec Alignment

### Rename
No rename.
