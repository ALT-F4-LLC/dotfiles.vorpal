# Changelog: staff-engineer

## 2026-07-27

### Summary
Compacted 8 entries (2026-07-11..2026-07-15) into Compacted history per the retention-compaction policy.

### Changes
- Replaced the 8 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (retention-compaction policy)

### Rename
No rename.

## 2026-07-27

### Summary
Phase 3 disambiguation: terminal-state marker scoped to the teammate path, and the fingerprint escape hatch resolved so a missing `frozen:` value never reads as a waived gate or a skipped fingerprint.

### Changes
- FIX[SUBSTANTIVE] (DISAMBIG 2): ephemeral pre-idle checklist item (a) scoped TEAMMATE-path-only -- a report-only subagent (Task family absent per the Tool envelope check discriminator) ends plain-text and OMITS the marker, resolving the contradiction with line 54's plain-text-and-END path.
- FIX[SUBSTANTIVE] (DISAMBIG 4): Moving-tree gate -- a GO with no `frozen:` value means only that its sender computed no fingerprint; the COMPARISON is unavailable, the GO gate is never waived, and `tree_fingerprint.sh` still runs once so the verdict's `+dirty:` field binds to the tree actually read.

### Dimensions Evaluated
Disambiguation (Phase 3): multi-reading

### Rename
No rename.

## 2026-07-27

### Summary
Phase 2 coherence: adopted the fleet-standard ephemeral terminal-state marker in the pre-idle checklist; wired the Moving-tree gate to re-check team-lead's frozen:<sha12> fingerprint; closed the C5 grep-pointer's templated-spawn blind spot.

### Changes
- FIX[SUBSTANTIVE] (I8): pre-idle checklist (a) leads the final report with the exact marker literal (master: senior-engineer.md Shutdown Handling step 3) -- team-lead reads completion from the report, not Docket-mirror inference.
- FIX[SUBSTANTIVE] (I6): Moving-tree gate re-runs tree_fingerprint.sh and refuses the verdict on frozen:<sha12> mismatch; graceful pass-through for a GO with no frozen: value.
- FIX[SUBSTANTIVE] (C5 follow-up): grep-pointer roster now names the grep-invisible templated review-<name> Phase 1 spawn class (evolve-agents:253).

### Dimensions Evaluated
Coherence & Cross-Communication (Phase 2)

### Rename
No rename.

## 2026-07-27

### Summary
Roster de-enumerated to a regeneration grep (ground truth: 9 staff-typed spawn names, seed listed 7);
deleted the unreachable Edit/Write fallback; corrected an unconditional auto-resume claim falsified
against sub-agents.md:945; adopted the SendMessage `summary` schema by pointer. Net +1,566ish
(63,684 -> 65,397).

### Changes
- FIX[SUBSTANTIVE] (C5): Lifecycle roster split into team-lead-dispatch (AUTHORITY = Per-Role Dispatch Table) and skill-spawned (regenerated via grep over both skill roots, not hand-enumerated).
- CULL[SUBSTANTIVE] (D1): unreachable Edit/Write-absent `$TMPDIR` fallback deleted -- `memory: project` force-enables Read/Write/Edit; void only under the auto-memory kill switch.
- FIX[SUBSTANTIVE] (D9): auto-resume claim qualified with the v2.1.191 operator-stop carve-out -- an operator-cancelled agent returns a refusal, not a stall.
- AMPLIFY[SUBSTANTIVE] (I5, scoped): already-present check now names both grep paths plus the changelog's `## Compacted history` section; `already_present.sh` deferred (does not exist).
- FIX[SUBSTANTIVE] (H7-derived): TDD step 8 open-question resolution split by mode -- AskUserQuestion is standalone-only.
- FIX[SUBSTANTIVE] (B1, revised): ack rule now points at team-lead.md SP-1b for the SendMessage `summary` schema -- B1's prescribed ack-template site doesn't exist in this file.

### Dimensions Evaluated
Completeness, Actionability, Spec Alignment, Role Realism, Consolidation & Trimming, Capability Growth

### Rename
No rename.

## 2026-07-27

### Summary
Compacted 3 entries (2026-07-10..2026-07-11) into Compacted history per the retention-compaction policy.

### Changes
- Replaced the 3 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (retention-compaction policy)

### Rename
No rename.

## 2026-07-27

### Summary
Phase 2 coherence: AskUserQuestion hedge corrected to the unconditional first-filter rule; CANONICAL:PITFALLS full body compacted to a PITFALLS-LOCAL pointer (single-homed in team-doctrine/references/pitfalls.md). Net -1.2KB.

### Changes
- FIX[SUBSTANTIVE]: "absent in the common team-mode spawn" -> "stripped from EVERY teammate and subagent spawn unconditionally (sub-agents.md first tool filter)" -- hedge falsified against the primary doc.
- CULL[SUBSTANTIVE]: CANONICAL:PITFALLS (2,811B) -> CANONICAL:PITFALLS-LOCAL pointer with inline hard gate; full body single-homed in the pitfalls master; manifest re-registered under PITFALLS-LOCAL, verified via doctrine_check.sh.

### Dimensions Evaluated
Coherence & Cross-Communication (Phase 2)

### Rename
No rename.

## 2026-07-27

### Summary
Wired the orphaned xref_check.py into the numbered-cross-reference ritual (with a measured false-positive caveat), corrected a live-falsified Task-tools absence claim, added a parity-locked byte-surface gate, and consolidated tier-split mechanics from 5 sites to 1 authority. Findings: 6 → 3 sub / 4 cos / 0 rej / 0 def / 0 enc

### Changes
- AMPLIFY[SUBSTANTIVE] (I1): Numbered-cross-reference reconciliation now mandates `xref_check.py DOC_A DOC_B`, with the measured caveat that its `enum` pattern yields mostly bare-paren noise on prose-heavy docs (20/22 rows) — reconcile structured rows, hand-grep only outside `PATTERNS`.
- FIX[SUBSTANTIVE] (docs-researcher): Tool-envelope check split the Task-family claim — a teammate ALWAYS keeps TaskCreate/Update/List/Get regardless of `tools:`; only background report-only subagents lose them. Falsified live this session (TaskList succeeded as a teammate on CC 2.1.220).
- AMPLIFY[SUBSTANTIVE]: New No Guessing gate — measure parity-locked bytes (`doctrine_check_manifest.tsv`) before accepting a TRIM/BALANCED mandate; "no legal trim here" is a valid verdict.
- CULL[COSMETIC] (I2): Tier-split mechanics consolidated to §What You Are NOT; Operating context, Lifecycle, Responsibility 1 and Responsibility 2 reduced to pointers (-579 bytes).
- AMPLIFY[SUBSTANTIVE] (D1 follow-up): Task-tool absence reframed as a teammate-vs-background-subagent discriminator routing to SP-2's plain-text-and-END shutdown path (+281 bytes; total net now +1486, 63,062 -> 64,548).

### Dimensions Evaluated
Completeness, Actionability, Spec Alignment, Consolidation & Trimming, Role Realism, Capability Growth

### Rename
No rename.

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
- 2026-07-11: Compacted 4 entries (2026-06-09..2026-06-10) into Compacted history per the retention-compaction policy.
- 2026-07-12: Phase 2 coherence: compacted the shutdown block to the master-pointer form; sanctioned `Skill(deep-research)` in the TDD precedent-study step (parity with distinguished-engineer.md).
- 2026-07-12: Findings: 3 → 3 sub / 0 cos / 0 rej / 1 def / 0 enc. Encoded the HA-STAFF1 authoring-time re-verification discipline into rule 6, adopted `vote_delegate.sh` (fixes omitted-`--threshold` bug), consolidated the duplicated tier-split AUTHORITY meta-statement. Net +109 bytes.
- 2026-07-13: Disambiguated the deep-research sanction (DKT-270): glossed the `Skill(vote)` restriction-class pointer and split the fused "team-lead/operator" routing target into "team-lead (team mode) or the operator (standalone)".
- 2026-07-13: Corrected the deep-research sanction in TDD step 3 (DKT-270) — deep-research is a bundled Workflow, not a Skill, and is not directly teammate-invokable.
- 2026-07-13: Compacted 3 entries (2026-06-17..2026-06-20) into Compacted history per the retention-compaction policy.
- 2026-07-15: Read-before-Edit rule -> pointer to senior-engineer.md's master (B3); stale-dispatch-check pointer added (R3); vote wire form deduped (I4).
- 2026-07-15: Self-review: no definition-file edits. All 4 findings (H13, H14, I11, D1) dispositioned without a change; file verified aligned to CC 2.1.210.
- 2026-07-10: Compacted 3 entries (2026-06-09..2026-06-09) into Compacted history per the retention-compaction policy.
- 2026-07-11: evolve-agents cycle: removed a dangling self-contradiction in Responsibility 2 Review output (spec-maintenance directive conflicted with Responsibility 4's disownment).
- 2026-07-11: Phase 2 coherence fix: corrected the SP-2 teammate/report-only-subagent discriminator (family-wide lockstep with 5 sibling agents + the shutdown-protocol master). Net -36 bytes.
