# Changelog: security-engineer

## 2026-05-24 (Phase 2 coherence — shutdown routing + advisor-idle parity)

### Summary
Two coherence fixes. (1) Closed the 6 historical shutdown-routing errors by making the routing rule explicit at rule 6. Security review doubling (4 parallel reviewers) makes peer-vs-team-lead recipient confusion especially likely. (2) Strengthened persistent-advisor idle-is-normal rule to name `TeammateIdle` explicitly and cite TDD §4.4 rule 5 — achieves parity with staff-engineer.md and ux-designer.md. No file-size change.

### Changes
- Communication Discipline rule 6: appended Routing clause — `shutdown_response` ALWAYS addressed to team-lead, never to peer agents or original dispatcher; applies to `security-advisor` and every ephemeral spawn (`security-reviewer-2`, sibling security-TDD authors, ad-hoc consults).
- Lifecycle contract paragraph: strengthened persistent-advisor idle phrasing — names `TeammateIdle` signal explicitly, cites TDD §4.4 rule 5, states "does NOT trigger auto-respawn" (parity with staff-engineer.md line 40 and ux-designer.md line 277).

### Dimensions Evaluated
Cross-Agent Coherence (PRIMARY — both fixes) · Actionability (routing visibility on doubled security track) · Boundary Clarity (advisor-idle rule self-contained)

### Rename
No rename.

## 2026-05-19 (Phase 2 coherence — memory channel activation)

### Summary
Activated the dormant `.claude/agent-memory/security-engineer/` channel via a shutdown-time memory check, tailored to security context: explicitly excludes per-cycle threat models and one-shot CVEs (which have other homes) so the criterion stays sharp.

### Changes
- Shutdown Handling: added memory check before approving shutdown — append recurring threat-model pitfalls (recurring vulnerability class in this codebase, rejected adversary assumptions, operator risk-tolerance signals, non-obvious security symptom→root-cause→remediation patterns) to `.claude/agent-memory/security-engineer/pitfalls.md`. Skip if nothing recurring surfaced.

### Dimensions Evaluated
Capability Growth & Cross-Communication (PRIMARY — dormant channel activated, tailored gate) · Coherence (parallel to team-lead + staff-engineer wrap-up nudges).

### Rename
No rename.

## 2026-05-19 (Phase 2 coherence)

### Summary
Universal-mirror visibility contract alignment (Phase 2 canonical decision). Conditional-mirror language replaced with explicit universal-mirror clause + cross-cutting fallback.

### Changes
- §Visibility contract (renamed from "Operator visibility"): every SendMessage mirrored as Docket comment with `[SEC→@agent]` prefix; cross-cutting-fallback clause for security ADRs / fleet-wide threat-model calls; (cc operator) real-time signal preserved layered on top.

### Dimensions Evaluated
Cross-Agent Coherence (PRIMARY — universal-mirror alignment).

### Rename
No rename.

## 2026-05-19

### Summary
Targeted self-review responding to historical-audit signals: codified the respawn-recovery handoff (4× operator pattern), added a vote-commit race guard (6 cancelled parallel commits observed), tightened operator-visibility framing for fleet consistency, and compressed Communication Discipline by merging Read-before-Edit/Write into rule 6 to keep BALANCED budget. Net 0 lines.

### Changes
- §Operating context: added "operator may address by either name" clarifier and explicit `Interrupt recovery` clause — first-turn state summary after respawn/compaction.
- §Consensus Voting: added **Vote-commit race guard** bullet — team-lead owns `docket vote commit`; standalone must `docket vote show` to verify state before committing.
- §Operator visibility: split cc-vs-prefix framing into two explicit channels ("cc is real-time signal; prefix is persistent record") to match @staff-engineer's wording.
- §Communication Discipline: merged Read-before-Edit/Write into rule 6 alongside shutdown protocol; removed standalone subsection. Rule count remains 7.

### Dimensions Evaluated
Capability Growth & Cross-Communication (PRIMARY — respawn handoff, race guard) · Boundary Clarity (operator-visibility two-channel) · Consolidation (Read-before-Edit/Write merge) · Actionability (vote-commit race) · Cross-Agent Coherence (rule numbering preserved).

### Rename
No rename.

## 2026-05-17 (Phase 2 coherence)

### Summary
Cross-agent coherence: added canonical `TeammateIdle` stall-signal line and Read-before-Edit/Write reflex.

### Changes
- Communication Discipline: appended TeammateIdle canonical-signal line below rule 6.
- Communication Discipline: added Read-before-Edit/Write reflex (TDD/ADR/security.md authoring).

### Dimensions Evaluated
Cross-agent terminology coherence; tool-gate reflexes.

### Rename
No rename.

## 2026-05-17 (pass 2)

### Summary
Trimmed three blocks for parity with peers and to remove intra-doc duplication: Design Review's dimension list redirected to Responsibility 2 (was duplicated); Communication Discipline rules 1-4/6 compressed; two @senior-engineer mid-impl incoming triggers merged. Net -12 lines. No behavioral change.

### Changes
- Design Review: replaced duplicated security-dimension list with cross-reference to Responsibility 2 step 3; kept operational-readiness emphasis and output ladder.
- Communication Discipline: tightened rules 1-4 and 6; rule 5 (verify load-bearing claims) left intact as it carries the security-specific load.
- Incoming triggers: merged @senior-engineer proactive-consult + reactive-discovery into one trigger.

### Dimensions Evaluated
Consolidation & Trimming (PRIMARY), Boundary Clarity, Coordination & Handoffs, Spec Alignment.

### Rename
No rename.

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
