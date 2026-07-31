# Changelog: ux-designer

## 2026-07-30

### Summary
Compacted 2 entries (2026-07-12..2026-07-13) into Compacted history per the retention-compaction policy.

### Changes
- Replaced the 2 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (retention-compaction policy)

### Rename
No rename.

## 2026-07-30

### Summary
Phase 2 coherence: `TeammateIdle` reframed to routine-lifecycle per the named authority (the old text contradicted this file's own §Lifecycle); incoming TDD-consult trigger generalized from `@staff-engineer` to the authoring seat. `effort:` pin unchanged — already at the Claude 5 default `high`. Net +97.

### Changes
- FIX[SUBSTANTIVE]: Communication Discipline `TeammateIdle` line aligned to `team-lead.md` §Teammate Stall & Crash Recovery. `:259` already stated idle-between-phases is normal, so the old wording contradicted this file internally as well as the authority. Divergence was pre-existing (verified against HEAD).
- FIX[SUBSTANTIVE]: incoming trigger "@staff-engineer TDD revision / feasibility consult" → "the TDD authoring seat (`advisor` — either tier)". On Medium+ cycles the TDD author is @distinguished-engineer, so the role-hardcoded row missed the common case.
- FIX[SUBSTANTIVE]: outgoing escalation row converged to the same seat form ("the general-architecture seat (`advisor` — either tier)"). The coherence pass caught that converting only the incoming half left this file naming one seat two ways — and on a default single-reviewer Medium+ cycle no @staff-engineer instance is alive, so all five outgoing escalations addressed a role with no live seat. senior-engineer.md and security-engineer.md carry an explicit seat-name translation rule for exactly this; this file carries none, so converging the spelling is the fix rather than copying a translation note into a third carrier.
- RETAINED[SUBSTANTIVE]: `effort: high` — R1 confirmed this pin already sits at the documented default; measured binding dispatch is 0. Now carries a binding-provenance comment, closing the 4-of-8 annotation split the coherence pass flagged.

### Dimensions Evaluated
Coherence & Cross-Communication (Phase 2)

### Rename
No rename.

## 2026-07-27

### Summary
Compacted 4 entries (2026-07-11..2026-07-12) into Compacted history per the retention-compaction policy.

### Changes
- Replaced the 4 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (retention-compaction policy)

### Rename
No rename.

## 2026-07-27

### Summary
Phase 2 coherence: AskUserQuestion hedge corrected to the unconditional first-filter rule; CANONICAL:PITFALLS full body compacted to a PITFALLS-LOCAL pointer. Net -1.2KB.

### Changes
- FIX[SUBSTANTIVE]: "absent in the common team-mode spawn" -> "stripped from EVERY teammate and subagent spawn unconditionally (sub-agents.md first tool filter)".
- CULL[SUBSTANTIVE]: CANONICAL:PITFALLS (2,811B) -> CANONICAL:PITFALLS-LOCAL pointer; full body single-homed in the pitfalls master.

### Dimensions Evaluated
Coherence & Cross-Communication (Phase 2)

### Rename
No rename.

## 2026-07-27

### Summary
Fixed the design-QA verdict prefix divergence atomically across ux-designer.md and scripts/gate_check.sh (E2 Blocker), added the plan-protocol emitter constraint (E3), encoded three spec-validation gates from recorded rework incidents, corrected the falsified Task-tools claim (D1), and trimmed 3 redundant sections. Findings: 21 -> 8 sub / 4 cos / 6 rej / 1 def / 6 enc. Net +598 bytes (46,886 -> 47,484); gate_check.sh +2.

### Changes
- FIX[SUBSTANTIVE] (E2, Blocker): normalized `[UX->team-lead] Design QA:` -> `[UX->@team-lead] Design QA:` at both agent-file sites AND both scripts/gate_check.sh fixed-string matches in one atomic edit.
- AMPLIFY[SUBSTANTIVE] (E3): plan-approval incoming trigger now states team-lead emits the `plan_approval_response`; this role never sends a plan-protocol message directly to an in-flight impl ephemeral.
- AMPLIFY[SUBSTANTIVE] (reviewer, sourced from pitfalls): Design Spec Workflow step 4 gains three self-validate gates -- affordance predicates must mirror the backend handler precondition; columns/cells/sort keys must resolve against the real wire payload; backtick-quoted AC tokens get a literal grep -F check.
- FIX[SUBSTANTIVE] (D1): Task-family envelope hedge corrected to UNSTRIPPABLE-for-teammates, CC 2.1.220 version-stamped.
- AMPLIFY[SUBSTANTIVE] (R1): R6 bans ls-verification of doctrine-cited script paths.
- CULL[COSMETIC] x3 (reviewer): mirrored gold/silver tier table -> pointer; Responsibility 3 deep-research trivia trimmed; duplicated TeammateIdle sentence in Shutdown Handling removed.

### Dimensions Evaluated
Role Realism, Actionability, Boundary Clarity, Completeness, Consolidation & Trimming, Capability Growth & Cross-Communication, Spec Alignment

### Rename
No rename -- sdlc-role-researcher confirms clean UX-design industry mapping.

## 2026-07-21

### Summary
Compacted 3 entries (2026-07-10..2026-07-10) into Compacted history per the retention-compaction policy.

### Changes
- Replaced the 3 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (retention-compaction policy)

### Rename
No rename.

## 2026-07-21

### Summary
Phase 2 coherence review: rebased both `copy_verify.sh` citations from a bare `scripts/` relative path (would not resolve at agent runtime) to the dual-home convention.

### Changes
- FIX[COSMETIC]: both `copy_verify.sh` citations (content rule, QA Workflow) now read `~/.claude/scripts/copy_verify.sh` with the `repo:` pointer, matching the family convention.

### Dimensions Evaluated
Spec Alignment (path-citation correctness). Flagged, not fixed: `mcp__claude-in-chrome__*` frontmatter grantability to a spawned teammate is unverified — no other agent file uses `mcp__` naming; routed to the operator / a future evolve-config check.

### Rename
No rename.

## 2026-07-21

### Summary
Applied two operator-approved trials. Trial: adopt claude-in-chrome interactive QA for Web surfaces (gated, static-render fallback) → applied (baseline: no prior keyboard-reachability verification mechanism existed — claims were asserted, not measured). I-ux2: wired uncited scripts/copy_verify.sh into the spec content rule (author side) + QA Workflow (verify side). Findings: 5 → 2 sub / 0 cos / 0 rej / 2 def / 1 enc

### Changes
- AMPLIFY[SUBSTANTIVE] (I-ux1): render-mechanism table gains Web-interactive-a11y row + tools frontmatter grants mcp__claude-in-chrome__* + accessibility check routes keyboard-reachability to it; gated on extension site-permission, static render_verify.sh fallback.
- AMPLIFY[SUBSTANTIVE] (I-ux2): content rule + QA Workflow now cite scripts/copy_verify.sh as the deterministic copy-literal acceptance check (was uncited by any agent/skill).

### Dimensions Evaluated
Actionability, Capability Growth & Cross-Communication, Completeness. H-ux2 deferred (cross-agent hook concern), H-ux1 informational, D9 confirmed already-correct.

### Rename
No rename.

## 2026-07-15

### Summary
Compacted 6 entries (2026-06-19..2026-07-01) into Compacted history per the retention-compaction policy.

### Changes
- Replaced the 6 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (retention-compaction policy)

### Rename
No rename.

## 2026-07-15

### Summary
R7 gains the Read-before-Edit adjacency rule as a second outranking exception (R7's sole post-compaction exception implied mid-session adjacency re-Reads were unneeded, contradicting the master this file binds "in full").

### Changes
- AMPLIFY[SUBSTANTIVE]: R7 one-liner gains the adjacency-gate outranking exception, citing the top-of-file Read-before-Edit/Write rule.

### Dimensions Evaluated
Disambiguation (multi-reading).

### Rename
No rename.

## 2026-07-15

### Summary
Read-before-Edit paragraph → pointer to senior-engineer.md's new master (B3; Skill(ux-spec) delta retained); stale-dispatch-check pointer added (R3); vote wire form deduped (I4).

### Changes
- AMPLIFY[SUBSTANTIVE] (B3): Read-before-Edit paragraph → READ-BEFORE-EDIT pointer (concurrent docs/ux edits are the hot-file hotspot the master covers).
- AMPLIFY[SUBSTANTIVE] (R3): added stale-dispatch-check pointer on Rule 2.
- CULL[COSMETIC] (I4): wire-form paragraph replaced with a citation to Skill(vote)'s Delegation Protocol.

### Dimensions Evaluated
Consolidation & Trimming, Cross-Communication.

### Rename
No rename.

## 2026-07-15

### Summary
Folded the H6 reporting-discipline gap (proposal-only Phase 1 output reported as "applied") into Communication Discipline as rule 8; S2/I13 deferred, D1 already-encoded. Findings: 4 → 1 sub / 0 cos / 0 rej / 2 def / 1 enc

### Changes
- AMPLIFY[SUBSTANTIVE]: added Communication Discipline rule 8 — proposal voice for un-applied output (claim "applied" only after a self-run, verified Edit/Write) — cited historical-auditor + centralized pitfalls "reported proposal-only output as applied" (H6)

### Dimensions Evaluated
Capability Growth & Cross-Communication, Actionability (all 8 evaluated; S2 accessibility-dimension addition deferred to evolve-skills, I13 render_verify.sh deferred as infra, D1 teammate-envelope note already present).

### Rename
No rename.

## 2026-07-13 (DKT-270 Phase 3 disambiguation)

### Summary
Disambiguated the deep-research sanction: the unexplained `Skill(vote)` restriction-class pointer, the fused "team-lead/operator" routing target, and a "gates" pointer colliding with this file's other named Gates. Findings: 3 → 3 sub / 0 cos / 0 rej / 0 def / 0 enc

### Changes
- AMPLIFY[SUBSTANTIVE]: glossed "same restriction class as `Skill(vote)`" with the shared class itself (swarm-spawning entry points are main-session-only)
- AMPLIFY[SUBSTANTIVE]: split "team-lead/operator" into "team-lead (team mode) or the operator (standalone)"
- AMPLIFY[SUBSTANTIVE]: "per this role's gates" → "under this role's Honest-critique evidence discipline" — this file names several unrelated things "Gate" (Pre-Flight, render/verdict, Liveness-Confirmation); the intended referent (the :33 evidence rules) was never called a gate

### Dimensions Evaluated
Disambiguation (multi-reading ×2, confusable-name ×1).

### Rename
No rename.

## 2026-07-13 (DKT-270 correction)

### Summary
Corrected the deep-research sanction in Responsibility 3 (Research and Discovery) — deep-research is a bundled Workflow, not a Skill, and is not directly teammate-invokable. Findings: 1 → 1 sub / 0 cos / 0 rej / 0 def / 0 enc

### Changes
- AMPLIFY[SUBSTANTIVE]: replaced the "prefer `Skill(deep-research, ...)` — a registered bundled skill" clause with the Workflow-vs-Skill distinction, the dozens-to-~97 background-subagent fan-out, the no-`Workflow`-tool teammate restriction (same class as `Skill(vote)`), and the route-to-team-lead-or-hand-roll fallback per this role's gates — cited DKT-270 investigation, independently corroborated via code.claude.com/docs/en/workflows

### Dimensions Evaluated
Actionability.

### Rename
No rename.

## Compacted history

Entries below were compacted per ADR 0001; full text in git history (see the compaction entry's date).

- 2026-03-19: Major consolidation from 1104 to 318 lines. Compressed verbose sections, collapsed output templates, converted surface expertise to reference…
- 2026-03-19: Trimmed 25 lines through consolidation of redundant philosophy, anti-patterns, and system-level sections. Added "Check Specs Before Designing"…
- 2026-03-19: Added Operating context paragraph to align with the pattern established across all other agents.
- 2026-03-19: Removed 19 lines of duplicated guidance (conflict escalation, cross-surface coherence) and redistributed the one unique idea. Sharpened…
- 2026-03-19: Compressed /vote section and status updates list, tightened spec format descriptions, added accessibility and visual-prototyping checks to…
- 2026-03-20: Added effort and memory frontmatter, compressed Design Philosophy from 8 to 6 principles, removed Design Strategy Briefs, trimmed verbose status…
- 2026-03-20: Merged Content Design into Design Spec Format, deduplicated TDD conflict escalation, added @sdet notification trigger, removed redundant Design…
- 2026-03-20: Removed standalone "Check Specs Before Designing" section (duplicated workflow step 1), folded unique content into Clarify step, compressed…
- 2026-03-20: Compressed Vote CLI Reference, Anti-Patterns, Managing Ambiguity, and Research handoff notes. Added explicit docket comment command for issue…
- 2026-03-21: Added observability for cross-communication and vote audit trails, compressed surface table and anti-patterns, added disallowedTools frontmatter…
- 2026-03-29: Updated Docket Vote CLI reference with audit-discovered flags, compressed Delegation Protocol and Managing Ambiguity subsection. Net -15 lines.
- 2026-03-29: Added TaskCreate/TaskUpdate/TaskList/TaskGet to frontmatter, compressed spec format list, removed vestigial Anti-Patterns and Delegation…
- 2026-03-30: Added honest UX critique directive, compressed Decision-Making Framework and /vote critical-cases, added trade-off documentation check to…
- 2026-04-01: Added `model: opus[1m]` to frontmatter, added context compaction handling, compressed Pre-Flight and Inter-Agent Communication sections, added…
- 2026-04-06: Fixed `/vote` team-nesting bug (operator feedback): replaced direct `/vote` invocation with team/standalone mode routing. Removed Docket Vote…
- 2026-04-06: Added mandatory "Resolve open questions" workflow step (verified goal). Compressed What You Are NOT, Research, and Shutdown sections. Updated…
- 2026-04-16: Consolidation pass: merged text-medium directives, compressed What You Are NOT (added missing @sdet boundary for cross-agent coherence)…
- 2026-04-16: Cross-communication pass: restructured Inter-Agent Communication around concrete proactive SendMessage triggers (Consult first / Notify…
- 2026-04-19: Added "No guessing — research first" rule after Honest critique — STOP-and-research loop for UX patterns, user workflows, SDK/CLI conventions…
- 2026-05-05: Consolidation pass: compressed three stance paragraphs (Honest critique / No guessing / Text-only medium), tightened workflow step 1 (Clarify)…
- 2026-05-05: Phase 0+2 capability adoption + consolidation: added Bash run_in_background + Monitor pattern for QA of long-running surfaces, `color: magenta`…
- 2026-05-06: Cross-comms visibility + capability growth pass. Added Cross-communication observability paragraph (operator can't see inter-agent SendMessage)…
- 2026-05-06: Phase 2 coherence pass: replaced "summarize in next status update" cross-comm pattern with fleet-standard hybrid (Docket-comment prefix…
- 2026-05-07: Capability fix + Responsibility 4 trim. Added Monitor to tools frontmatter to match the existing Responsibility 5 mandate (introduced 2026-05-05…
- 2026-05-07: Phase 2 coherence: aligned HARD GATE delimiter style with peer agents.
- 2026-05-07: Closed persistent-advisor lifecycle gap (team-lead.md:169 mandates the orchestrator-side behavior but ux-designer.md previously had no…
- 2026-05-07: Phase 2 coherence: added persistent agent-memory paragraph aligning ux-designer with sdet/SE/staff/PM fleet pattern. UX-specific guidance on…
- 2026-05-08: Trim of redundant inter-agent communication structure, surface-table preamble, "How You Work" verb-routing, research framing, and a handoff line…
- 2026-05-08: Phase 2 coherence: surfaced the sub-agent invocation ban in the CRITICAL banner.
- 2026-05-08: Phase 3 operating discipline: extended Persistent memory to capture solutions to recurring design problems.
- 2026-05-09: Self-review trim pass: compressed Pre-Flight Goal-Alignment Gate, tightened workflow step 5, Design QA verify-behavior paragraph…
- 2026-05-13: Replaced loose "when to create a spec" bullets with an explicit four-tier output table (inline / Docket comment / interaction sketch / full…
- 2026-05-13: Phase 2 coherence: added @security-engineer to "What You Are NOT" and Outgoing triggers — closes bidirectional handoff gap where…
- 2026-05-16: Added Communication Discipline (rules 1-6) with rules 1-3 emphasized for ux-advisor's implementation-phase persistence; strengthened Design QA…
- 2026-05-16: Phase 2 coherence: normalize security-advisor canonical form; drop redundant parenthetical.
- 2026-05-17: Vote delegation payload synced to canonical `skills/vote/` Delegation Protocol shape (Phase 2 handoff from 2026-05-17 evolve-skills cycle).…
- 2026-05-17: pass 2: Addressed two historical-audit findings: highest per-session "File has not been read yet" rate (11/11 sessions) via explicit…
- 2026-05-17: Added canonical `TeammateIdle` stall-signal line for cross-agent terminology coherence.
- 2026-05-19: Addressed the "highest-leverage coherence fix" flagged by historical audit: promoted Visibility contract from conditional mirroring ("When an exchange ties to
- 2026-05-24: Closed the 6 historical shutdown-routing errors by making the routing rule explicit at Communication Discipline rule 6. `design-review-2` and `design-qa-2`
- 2026-05-25: Phase 1 self-review — Read-before-Edit compaction-awareness promoted; Doubled Reviewer Pattern consolidated into R5 canonical block; memory save trigger added.
- 2026-05-25: Phase 2 coherence — rule 6 WRONG/RIGHT shutdown example; @security-engineer incoming trigger added; P7a dropped from R7.
- 2026-05-26: Phase 1 — ephemeral verdict-then-shutdown vs persistent ux-advisor idle-OK lifecycle distinguished; design-review-{N}/design-qa-{N} pluralized. Net +4.
- 2026-05-26: Phase 2 — stripped 6 dangling docs/tdd/* citations; redirected to team-lead.md anchors.
- 2026-05-26: R2/R5 Reviewer Panel realigned to default-single + opt-up-doubled (Rule 8); design-qa-{N} naming convention parity. Net 0.
- 2026-05-30: Three coherence/consolidation fixes: AskUserQuestion standalone-only gate; reconciliation rule 6 (not 7); R2/R5 Fix-loop → pointers. Net 0.
- 2026-05-30: Consolidation — §Shutdown Handling ephemeral restatement → 1-line pointer to §Ephemeral roles. Net 0.
- 2026-06-05: Two render-gate pitfalls encoded: render-to-image QA gate + rendered-EFFECT-at-delivery-resolution spec rule. Net +4.
- 2026-06-09: Trimmed duplicated "What to save here" list to a pointer to §Persistent memory; kept symptom→cause→resolution form. Net 0 (256 lines).
- 2026-06-09: Consolidation pass — removed duplicate Fix-loop continuity paragraph, deduped DEGRADED fallback to Reviewer Panel pointer. Net -2 (256→254).
- 2026-06-09: Phase 2 shutdown flip — exit sequence inverted (report→await→respond); PITFALLS family fix. Net 0 (254 lines).
- 2026-06-09: Closed two Fable-5 prescriptive-trigger gaps; reasoning-echo audit clean; render-QA lessons already-encoded. Net +2 (255 lines).
- 2026-06-09: Compacted 37 entries (2026-03-19..2026-05-17) into Compacted history per ADR 0001 (DKT-264).
- 2026-06-10: Fixed undocumented frontmatter `color: magenta` → `purple`; retired "Text-only medium" framing (superseded by render-to-image QA gate). Net 0 (255 lines).
- 2026-06-10: Phase 2 coherence — R5 ux-advisor self-summary trigger fires only on a design-QA verdict surfacing spec/implementation mismatch (lockstep with team-lead.md R5).
- 2026-06-10: Compacted 3 entries (2026-05-17..2026-05-24) into Compacted history per ADR 0001.
- 2026-06-17: Added rendered-EFFECT obligation to spec self-validation + relay-authority clause. Trial: rendered-EFFECT / relay-authority → adopted.
- 2026-06-19: Maintenance review confirmed design-QA render gate already covers build-green-vs-render-correct; NO-OP. Drift: skipped (seed-target was the cross-agent Pre-Flight parity gate — unsafe).
- 2026-06-21: Compacted 8 entries (2026-05-25..2026-06-05) into Compacted history per ADR 0001.
- 2026-06-30: Culled redundant Fix-loop restatement; confirmed three render-gate pitfalls remain encoded (NO-OP); PA plan-review trigger deferred to Phase 2.
- 2026-06-30: Phase 2 PA: landed pre-impl plan-review trigger for @senior-engineer PLANs on spec'd surfaces. Trial: PA plan-approval → applied.
- 2026-07-01: Phase 1 UX lifecycle/QA classification update — dispatch, plan-review, QA evidence, ephemeral close guidance tightened. Trial: UX lifecycle and QA classification -> applied.
- 2026-07-01: Phase 3 Disambiguation follow-up — normalized UX shutdown report fields (SP-1 scope/changed-files/checks/risks/safe_to_close).
- 2026-07-10: Compacted 2 entries (2026-06-09..2026-06-09) into Compacted history per the retention-compaction policy.
- 2026-07-10: Phase 2 coherence follow-up — flagged vote-delegation JSON as a plain-text payload, never SendMessage's structured `message` object; matches team-lead.md bug-audit FIX-9.
- 2026-07-10: Scoped session-start reads to dispatched-surface slugs; made design-QA verdict terminal only via a durable Docket comment (DKT-76 near-miss). Net -72 bytes.
- 2026-07-11: evolve-agents cycle (SDLC role-comparison mandate): named the render mechanism per surface class for the design-QA render-to-image mandate. Net +542 bytes.
- 2026-07-11: Phase 2 coherence fix: corrected the SP-2 teammate/report-only-subagent discriminator (family-wide lockstep with 5 sibling agents + the shutdown-protocol master). Net +32 bytes.
- 2026-07-11: Compacted 3 entries (2026-06-09..2026-06-09) into Compacted history per the retention-compaction policy.
- 2026-07-12: Surfaced post-implementation design QA in the frontmatter description (HA-UX1), noted `skills:` frontmatter is inert in teammate mode (DR1), trimmed the Go scratch-module recipe to a pointer (IS-UX3). Net -120 bytes.
- 2026-07-12: Phase 2 coherence — fixed the threshold-less Design Spec Approval vote proposal (migrated to `vote_delegate.sh`); compacted the shutdown block; added CANONICAL:SANDBOX-RECOVERY-LOCAL and a deep-research sanction for competitive/standards research.
- 2026-07-13: Compacted 4 entries (2026-06-10..2026-06-17) into Compacted history per the retention-compaction policy.
