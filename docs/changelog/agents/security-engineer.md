# Changelog: security-engineer

## 2026-05-17

### Summary
Vote delegation payload synced to canonical `skills/vote/` Delegation Protocol shape (Phase 2 handoff from 2026-05-17 evolve-skills cycle). `threat_summary` retained as an optional observability hint.

### Changes
- Consensus Voting §Team mode: replaced ad-hoc payload with canonical shape (`{type, protocol_version, skill, request_id, vote_id, from, summary?, artifact?, threat_summary?}`). Added `docket vote create ... --json` step; documented `failed` response on missing `vote_id`. Authoritative proposal (including threat model) lives in docket.

### Dimensions Evaluated
Cross-skill coherence (vote-skill payload contract), Coordination & Handoff.

### Rename
No rename.

## 2026-05-16

### Summary
Added Communication Discipline (rules 1-6) with rule 5 (verify load-bearing claims) emphasized for security sign-off; fixed misleading `docket vote commit --outcome` enum syntax to free-text; trimmed "What You Are NOT" and Proactive Communication outgoing-trigger duplication.

### Changes
- Added Communication Discipline section (+15) — closed-loop, ack, saturation, blocker, verify-evidence-this-session, one-turn shutdown.
- Fixed Docket cheatsheet: `vote commit --outcome` is free-text ("Approved: <summary>" / "Rejected: <reason>"), not an enum; clarified `--findings` vs `--findings-json`.
- Trimmed "What You Are NOT" entries to one-line per role (-6).
- Consolidated 7 Proactive Communication triggers into 5 by merging scope-delta + annotation-split, and TDD-accepted + cross-cutting ADR (-11).

### Dimensions Evaluated
Role Realism · Actionability · Boundary Clarity · Completeness · Consolidation & Trimming · Capability Growth & Cross-Communication · Spec Alignment · Rename.

### Rename
No rename.

## 2026-05-13

### Summary
Rebalanced documentation-vs-direct-action axis per operator pain. Added Threat-Model Annotation tier between full security TDD and inline review note. Tightened ADR threshold, trimmed Consensus Voting over-prescription, compressed Pre-Flight Gate and Shutdown sections. Added Docket CLI cheatsheet for review/voting surface. Net: -8 lines (327 → 319).

### Changes
- Added "scope test" gate + Threat-Model Annotation tier in §When to Create a Security TDD; reframed Proactively to require BOTH new surface AND non-trivial threat model
- Tightened ADR threshold (skip when rationale fits in PR comment with no future "why?" cost)
- Added Docket CLI cheatsheet (`docket vote create/cast/commit/link`, `docket issue file list`, `docket plan --root`) under Responsibility 2
- Compressed Pre-Flight Gate, Consensus Voting, Shutdown Handling, System-Level Thinking
- Strengthened @staff-engineer boundary to prefer annotation over parallel TDD on mixed changes
- Added proactive trigger for annotation-grown-too-large → split escalation

### Dimensions Evaluated
Completeness (operator pain on over-documentation; docket audit gap), Consolidation, Actionability, Boundary Clarity, Cross-Communication, Role Realism, Spec Alignment

### Rename
No rename.

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
