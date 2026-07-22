# Changelog: staff-engineer

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
Phase 3 disambiguation: "Stateless subagent" → "Stateless between spawns" to remove a confusable-name collision with the reserved report-only-subagent mechanism term.

### Changes
- FIX[COSMETIC]: Operating context now reads "Stateless between spawns" — staff-engineer's spawn forms (persistent advisor, ephemeral reviewers) are teammates with the full shutdown handshake, not report-only subagents.

### Dimensions Evaluated
Confusable-name clarity (Phase 3).

### Rename
No rename.

## 2026-07-21

### Summary
Verified H-staff1's sampled pitfalls, D7, and B7 as already-encoded/not-applicable NO-OPs. Encoded one undistilled sign-off lesson from the full 733-line pitfalls backlog: green-but-blind synthetic fixtures. Findings: 9 → 1 sub / 0 cos / 0 rej / 4 def / 4 enc

### Changes
- AMPLIFY[SUBSTANTIVE] (own pitfalls-backlog read): Sign-off verification techniques gains (d) Green-but-blind synthetic fixtures — a green suite where every external-sourced fixture uses the empty/happy shape is not real-environment evidence; ties to existing TFD-3 live-exercise requirement.

### Dimensions Evaluated
Capability Growth (Responsibility 2). Deferred: I-staff1 (xref_check.py doesn't exist), I-staff2 + B7 (cross-cutting, routed to Phase 2 / evolve-skills).

### Rename
No rename.

## 2026-07-15

### Summary
Compacted 5 entries (2026-06-21..2026-07-01) into Compacted history per the retention-compaction policy.

### Changes
- Replaced the 5 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (retention-compaction policy)

### Rename
No rename.

## 2026-07-15

### Summary
Read-before-Edit rule → pointer to senior-engineer.md's new master (B3, reviewer-line-number delta retained); stale-dispatch-check pointer added (R3); vote wire form deduped (I4).

### Changes
- AMPLIFY[SUBSTANTIVE] (B3): Rule 5 → READ-BEFORE-EDIT pointer.
- AMPLIFY[SUBSTANTIVE] (R3): added stale-dispatch-check pointer on Rule 2.
- CULL[COSMETIC] (I4): wire-form paragraph replaced with a citation to Skill(vote)'s Delegation Protocol.

### Dimensions Evaluated
Consolidation & Trimming, Cross-Communication.

### Rename
No rename.

## 2026-07-15

### Summary
Self-review: no definition-file edits. All 4 findings (H13, H14, I11, D1) dispositioned without a change; file verified aligned to CC 2.1.210. Findings: 4 → 0 sub / 0 cos / 1 rej / 2 def / 1 enc

### Changes
None this cycle. H13 rejected as self-edit (dispatcher-side, routed to Coherence w/ project-manager H9). H14 deferred to Phase 4 History Compaction. I11 deferred — evidence-gate consolidation into Skill(code-review-verdict) needs the skill to gain the gates first (verified skill lacks them); routed to Coherence w/ distinguished-engineer. D1 already-encoded (line 159).

### Dimensions Evaluated
All 8 — Role Realism, Actionability, Boundary Clarity, Completeness, Consolidation/Trimming, Capability Growth & Cross-Communication, Spec Alignment, Rename — no signal-backed edit found.

### Rename
No rename.

## 2026-07-13 (DKT-270 Phase 3 disambiguation)

### Summary
Disambiguated the deep-research sanction: the unexplained `Skill(vote)` restriction-class pointer and the fused "team-lead/operator" routing target. Findings: 2 → 2 sub / 0 cos / 0 rej / 0 def / 0 enc

### Changes
- AMPLIFY[SUBSTANTIVE]: glossed "same restriction class as `Skill(vote)`" with the shared class itself (swarm-spawning entry points are main-session-only) — the trailing "no `Workflow` tool" primed a false mechanical reading
- AMPLIFY[SUBSTANTIVE]: split "team-lead/operator" into "team-lead (team mode) or the operator (standalone)" — the slash-compound hid which target applies when

### Dimensions Evaluated
Disambiguation (multi-reading).

### Rename
No rename.

## 2026-07-13 (DKT-270 correction)

### Summary
Corrected the deep-research sanction in TDD step 3 (Study precedent) — deep-research is a bundled Workflow, not a Skill, and is not directly teammate-invokable. Findings: 1 → 1 sub / 0 cos / 0 rej / 0 def / 0 enc

### Changes
- AMPLIFY[SUBSTANTIVE]: replaced the "prefer `Skill(deep-research, ...)` — a registered bundled skill" clause — deep-research is a harness Workflow spawning dozens-to-~97 background subagents; a teammate has no `Workflow` tool (same class as `Skill(vote)`) so must route to team-lead/operator for a `/deep-research` run or hand-roll the WebSearch/WebFetch fan-out per this step's gates — cited DKT-270 investigation, independently corroborated via code.claude.com/docs/en/workflows

### Dimensions Evaluated
Actionability.

### Rename
No rename.

## 2026-07-13

### Summary
Compacted 3 entries (2026-06-17..2026-06-20) into Compacted history per the retention-compaction policy.

### Changes
- Replaced the 3 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (retention-compaction policy)

### Rename
No rename.

## 2026-07-12

### Summary
Phase 2 coherence: compacted the shutdown block to the master-pointer form; sanctioned `Skill(deep-research)` in the TDD precedent-study step (parity with distinguished-engineer.md).

### Changes
- CULL[SUBSTANTIVE]: §Shutdown Handling's 19-line SP-1/SP-2 spell-out reduced to a 3-line master pointer + Precondition.
- AMPLIFY[SUBSTANTIVE]: TDD Creation Workflow step 3 gains a `Skill(deep-research)` preference for external-source-dominated precedent study.

### Dimensions Evaluated
Cross-Agent Coherence (SHUTDOWN-PROTOCOL block parity; deep-research sanction parity with distinguished-engineer.md).

### Rename
No rename.

## 2026-07-12

### Summary
Findings: 3 → 3 sub / 0 cos / 0 rej / 1 def / 0 enc. Encoded the HA-STAFF1 authoring-time re-verification discipline into rule 6, adopted `vote_delegate.sh` (fixes omitted-`--threshold` bug), consolidated the duplicated tier-split AUTHORITY meta-statement. Net +109 bytes.

### Changes
- AMPLIFY[SUBSTANTIVE] (HA-STAFF1): rule 6 broadened from "before sign-off" to "before an artifact leaves you — authoring OR sign-off"; adds the memory/relay-non-substitution crux and cross-references/decisions to the verify list. Addresses the top meta-lesson in the largest-of-8 pitfalls file.
- CULL[SUBSTANTIVE] (IS-STAFF2): line-44 tier-split copy (near-verbatim duplicate of §What You Are NOT AUTHORITY) reduced to a pointer; AUTHORITY meta now stated exactly once.
- REFACTOR[SUBSTANTIVE] (IS-TL4-STAFF): replaced hand-rolled `docket vote create` (omitted `--threshold`, inheriting the CLI's silent 0.67 default) with a `vote_delegate.sh` pointer.

### Dimensions Evaluated
Completeness/Actionability (rule 6), Consolidation & Trimming (tier-split), Capability Growth/Cross-Communication (vote_delegate.sh). Role Realism, Boundary Clarity, Spec Alignment, Rename: RETAIN.

### Rename
No rename.

## 2026-07-11

### Summary
Compacted 4 entries (2026-06-09..2026-06-10) into Compacted history per the retention-compaction policy.

### Changes
- Replaced the 4 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (retention-compaction policy)

### Rename
No rename.

## 2026-07-11

### Summary
Phase 2 coherence fix: corrected the SP-2 teammate/report-only-subagent discriminator (family-wide lockstep with 5 sibling agents + the shutdown-protocol master). Net -36 bytes.

### Changes
- FIX[SUBSTANTIVE]: SP-2 LOCAL copy corrected — `name=` is the sole discriminator; report-only subagents run background-by-default since Claude Code v2.1.198, so `run_in_background` no longer discriminates. Stale phrasing contradicted team-lead.md's Phase-1-corrected copy and current harness behavior.

### Dimensions Evaluated
Spec Alignment (v2.1.198 harness behavior), Boundary Clarity (family-wide parity with 5 siblings + master).

### Rename
No rename.

## 2026-07-11

### Summary
evolve-agents cycle (SDLC role-comparison mandate): removed a dangling self-contradiction in Responsibility 2. Findings: 4 → 1 sub / 0 cos / 0 rej / 2 def / 1 enc.

### Changes
- CULL[SUBSTANTIVE]: removed "Update impacted specs per Responsibility 4 after the skill returns." from §Responsibility 2 Review output — Responsibility 4 explicitly disowns spec maintenance as a standing responsibility, making this directive a live self-contradiction on every review pass. Residual signal (spec-invalidating findings) already covered by System-Level Thinking + the scope-delta SendMessage trigger — cited by innovation-scanner RETIRE finding.

### Dimensions Evaluated
Boundary Clarity, Consolidation & Trimming. SDLC role research confirms strong fit to industry "Staff Engineer" (cross-team design docs, review floor, no implementation) — no charter change. Role Realism/Actionability/Completeness/Capability Growth/Spec Alignment/Rename: RETAIN.

### Rename
No rename.

## 2026-07-10

### Summary
Compacted 3 entries (2026-06-09..2026-06-09) into Compacted history per the retention-compaction policy.

### Changes
- Replaced the 3 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (retention-compaction policy)

### Rename
No rename.

## Compacted history

Entries below were compacted per ADR 0001; full text in git history (see the compaction entry's date).

- 2026-03-19: Major consolidation from 1094 to 249 lines. Eliminated pedagogical content a staff-level LLM already embodies while preserving all behavioral…
- 2026-03-19: Removed 3 sections that fail Content Gate (Mentorship, Influence/Alignment, Decision-Making Framework). Salvaged incident analysis into…
- 2026-03-19: Tightened SDET boundary, removed dead "engineering growth" responsibility, compressed redundant passages, added SendMessage to tool list for…
- 2026-03-19: Compressed redundancy between Operator Alignment and TDD/Communication sections. Trimmed /vote negative list and verbose status updates. Added…
- 2026-03-20: Added effort and memory frontmatter, removed Advisory Mode negative list, compressed System-Level Thinking, tightened status updates, added TDD…
- 2026-03-20: Compressed Review Workflow step 4, trimmed Advisory Mode to essential bullets, added cross-team review notification triggers for @sdet and…
- 2026-03-20: Consolidated /vote section, compressed handoff, removed hardcoded spec count, added TDD revision and scope-change notification triggers…
- 2026-03-20: Compressed Advisory Mode and Anti-Patterns sections, added `docket plan` reference to review context gathering.
- 2026-03-21: Added cross-communication and vote observability, aligned Delegation Protocol with standardized JSON format, trimmed pre-flight and…
- 2026-03-29: Updated Docket Vote CLI reference with audit findings (new flags, corrected --voter default), compressed Delegation Protocol from 12 to 3 lines…
- 2026-03-29: Added TaskCreate/TaskUpdate/TaskList/TaskGet to frontmatter, removed speculative Delegation Protocol and redundant Anti-Patterns sections…
- 2026-03-30: Added Honest Technical Critique directive establishing posture on intellectual honesty, challenging flawed designs, and avoiding rubber-stamp…
- 2026-04-01: Added `model: opus[1m]` to frontmatter and Edit tool for incremental doc updates. Settings standardization and coherence fix.
- 2026-04-06: Fixed `/vote` team-nesting bug (operator feedback): team-mode now delegates to orchestrator instead of invoking Skill directly. Removed Docket…
- 2026-04-06: CRITICAL: Encoded mandatory TDD question-resolution workflow — open questions resolved via AskUserQuestion, secondary @staff-engineer review…
- 2026-04-16: Compressed Pre-Flight Gate mode descriptions and "When to Create a TDD" bullets; added proactive consultation triggers for @sdet (TDD Testing…
- 2026-04-16: Cross-communication pass: rewrote Proactive Communication into 10 concrete "situation → action" SendMessage triggers (5 new). Added Incoming…
- 2026-04-19: Added "No Guessing" top-level section covering ADR decisions, spec conventions, test outcomes, and API/pattern existence — staff role is…
- 2026-05-05: Consolidation pass: compressed "What You Are NOT" to dense one-liners (matches senior-engineer style), trimmed Pre-Flight Gate prose, merged TDD…
- 2026-05-05: Phase 0+2 consolidation + capability adoption: trimmed TDD section (removed redundant docs/tdd/ note, compressed "When to Create" bullets…
- 2026-05-06: Cross-comm observability + capability growth: marked 5 high-stakes outgoing triggers with **(cc operator)** for real-time visibility (vs batched…
- 2026-05-06: Phase 2 coherence pass: added persistent Docket-comment prefix `[STAFF→@agent]` alongside existing real-time `(cc operator)` markers — completes…
- 2026-05-07: Trimming pass: folded one-sentence "Handoff" H3 into workflow step 10, tightened Honest Critique closing (removed redundant "preserving…
- 2026-05-07: Capability-growth pass: adopted persistent agent memory for cross-session architectural precedent; named `AskUserQuestion` explicitly in…
- 2026-05-08: Consolidation pass: fused two duplicate operator-visibility rationale paragraphs into one block, trimmed intro restatement of frontmatter…
- 2026-05-08: Phase 2 coherence: aligned Operating context label and Persistent Memory format with the other four teammates; surfaced the sub-agent invocation…
- 2026-05-08: Phase 3 operating discipline: codified surface-fix rejection on review side, and remember solutions to recurring architectural problems.
- 2026-05-09: Tightened deliberative phrasing in Honest Critique close and TDD-workflow steps (decisive over meta), surfaced parallel @security-engineer…
- 2026-05-09: Phase 2 coherence: added explicit "NOT @security-engineer" boundary to clarify TDD-authoring split and parallel-review responsibility on…
- 2026-05-13: Sharpened §When to Create a TDD into an explicit threshold checklist (write-if-2-of-N, decline-and-route-if-any) addressing operator pain that…
- 2026-05-13: Phase 2 coherence: acknowledged Threat-Model Annotation handoff from @security-engineer in "NOT @security-engineer" boundary so staff-advisor is…
- 2026-05-16: Added Communication Discipline (rules 1-6) with rule 5 reinforced at the two highest-risk gates — TDD acceptance (verify before vote, not just…
- 2026-05-16: Phase 2 coherence: remove stale "Change 2/3" reference in Communication Discipline rule 3.
- 2026-05-17: Vote delegation payload synced to canonical `skills/vote/` Delegation Protocol shape (Phase 2 handoff from 2026-05-17 evolve-skills cycle). The…
- 2026-05-17: pass 2: Cycle 2026-05-17: addressed three Phase 0 audit findings — interrupt-recovery / TeammateIdle stall vocabulary (2 `interrupted` events…
- 2026-05-17: Phase 2 coherence: Added @security-engineer critical/high re-plan incoming trigger for bidirectional handoff coherence.
- 2026-05-19: Cycle 2026-05-19 self-review across 8 dimensions. File is in good shape (282 lines); vote delegation payload already canonical per 2026-05-17…
- 2026-05-19: Phase 2 coherence: Universal-mirror visibility contract alignment (Phase 2 canonical decision: every SendMessage mirrors to Docket; conditional…
- 2026-05-19: Phase 2 coherence — memory channel activation: Activated the dormant `.claude/agent-memory/staff-engineer/` channel via a shutdown-time memory…
- 2026-05-24: Closed the 6 historical `is_error:true` shutdown-routing errors by making the routing rule explicit at rule 7 (shutdown protocol). Covers persistent `advisor`
- 2026-05-25: Promoted 4 pitfalls from actively-maintained memory (`pitfalls.md`) into the agent definition: advisor topology rule (NEW Comm Discipline rule 9), directory
- 2026-05-25: Two coherence fixes: (1) added explicit compaction-awareness clause to Comm Discipline rule 5 (Read before Write/Edit) matching senior-engineer L33 and
- 2026-05-26: Phase 1 — ephemeral shutdown contract + tdd-reviewer-{N}/coherence-reviewer in roster; await shutdown_approved (not shutdown_response); 4-step drain checklist.
- 2026-05-26: Phase 2 — stripped 7 dangling docs/tdd/* citations; redirected to team-lead.md anchors.
- 2026-05-26: Teammate-mode envelope assumption + docket export rollup + Lifecycle/Shutdown dedup. Net 0.
- 2026-05-30: Two verbatim-duplication removals — TDD step 9 reconciliation + Rule 7 gloss collapsed to pointers. Within-line.
- 2026-05-30: Doubling-Rule default corrected (Doubled→Single reviewer is the default; Rule 8 opt-up). Net 0.
- 2026-06-05: Executable-claim gate generalized to cover cross-dialect SQL + regex ACs; spec-name enumeration trimmed. Net 0.
- 2026-06-05: Sole-editor rule mirrored from security-engineer; within-line. Net 0.
- 2026-06-09: Moving-tree gate added to Review Workflow Triage; Reviewer-panel Lifecycle paragraph removed. Net 0.
- 2026-06-09: evolve-skills reference update: code-review → code-review-verdict; 4 references updated.
- 2026-06-09: Added "already-present check" to No-Guessing + WebFetch/WebSearch use-when trigger. Net +2 (258 lines).
- 2026-06-09: Shutdown flip — rule 7 ephemeral sentence + §Shutdown Handling Ephemeral flipped to await-team-lead. Count unchanged (257).
- 2026-06-09: Deduped rule 7 shutdown contract; documented TDD step 6 envelope clause; encoded stale-line-citation pitfall. Net 0 (257 lines).
- 2026-06-09: Compacted 39 entries (2026-03-19..2026-05-19) into Compacted history per ADR 0001 (DKT-264).
- 2026-06-10: Review cycle — all Phase 0 signals verified NO-OP or routed as coherence flags; no edits (258 lines).
- 2026-06-10: Sole-editor rule reduced to pointer at security-engineer.md AUTHORITY copy. Trial: R5 advisor trigger ">50 assistant turns" → "after a TDD secondary-review fix-loop completes" → shipped (lockstep with team-lead.md).
- 2026-06-10: Compacted 3 entries (2026-05-24..2026-05-25) into Compacted history per ADR 0001.
- 2026-06-17: Added relay-authority rule 10, AC-staleness review gate, distinct-lens mandate for doubled TDD review; trimmed two redundant passages. Trial: relay-authority / AC-staleness / distinct-lens → adopted.
- 2026-06-19: Adopted two memory-sourced review-rigor directives (cited-authority live-`ls`; zero-hits-grep-is-suspect); trimmed a 3×-stated after-compaction re-Read rule to a single owner. Net +2 (286→288). Drift: skipped (seed-target was the Consensus/vote cross-ref section — unsafe).
- 2026-06-20: Fixed docket graph flag-order drift; hardened moving-tree gate to explicit team-lead-GO gate; cross-referenced Executable-claim gate from review path. Net 0 (302→302). Drift: disabled (drift=0).
- 2026-06-21: Compacted 9 entries (2026-05-26..2026-06-09) into Compacted history per ADR 0001.
- 2026-06-30: Encoded fresh regression-guard falsifier check into the TFD block; de-duped §Shutdown ephemeral roster to a §Lifecycle cross-ref.
- 2026-06-30: Phase 2 PA + coherence: added Impl-plan REVIEW (advisor reviews plan, team-lead emits plan_approval_response) + shared pre-computed reviewer brief clause. Trial: PA plan-approval → applied.
- 2026-07-01: Added `routing_recommendation` fields, close-ready report schema, team-lead verdict handoff, doubled-review cap/fix-loop wording. Trial: lifecycle close-ready/routing schema -> applied.
- 2026-07-01: Added staff receiver for team-lead-routed implementation PLAN review (TDD-conformance check + routing_recommendation; does not waive later diff review).
- 2026-07-10: Phase 3 disambiguation follow-up — qualified mixed local/foreign rule citation ("staff rule 9, team-lead.md step-14 rules 3a/3b") and fixed 2 stale "Rule 8(e)" cross-references to "Rule 8(c)".
- 2026-07-10: Phase 2 coherence follow-up — flagged vote-delegation JSON as a plain-text payload, never SendMessage's structured `message` object; matches team-lead.md bug-audit FIX-9.
- 2026-07-10: Consolidation-only cycle — trimmed redundant tier-split restatement in §Operating context (dup of §Lifecycle/§What You Are NOT). Net -32 bytes.
