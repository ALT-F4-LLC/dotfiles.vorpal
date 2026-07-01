# Changelog: staff-engineer

## 2026-06-30

### Summary
Phase 2 (operator-approved PA + coherence): added Impl-plan REVIEW (advisor is the plan's engineering reviewer; team-lead — not advisor — emits `plan_approval_response`) and a shared pre-computed brief clause for doubled code-review panels. Net +2 (309→311). Trial: PA plan-approval → applied.

### Changes
- AMPLIFY: Impl-plan review (plan-approval mode) — advisor delivers an approve/reject conformance verdict on the impl PLAN to team-lead before edits; does NOT waive diff review. FIX 1 corrected the emitter (only the spawner team-lead sends plan_approval_response; advisor must not message an in-flight impl ephemeral — rule 9). Signal: Phase 0 PA innovation.
- AMPLIFY: shared pre-computed brief clause in §Responsibility 2 (Code Review) — ask team-lead to fold one changed-file list + spec excerpts + cargo audit (Cargo.lock-hash-keyed) into every reviewer's brief. Signal: Phase 0 efficiency.

### Dimensions Evaluated
6 (Capability Growth) AMPLIFY×2. 1/2/3/4/5/7/8 RETAIN.

### Rename
No rename.

## 2026-06-30

### Summary
Encoded the fresh regression-guard falsifier check into the TFD block and de-duped the §Shutdown ephemeral roster to a §Lifecycle cross-ref. Net +2 (307→309). PA impl-plan approval + doubled-panel shared-brief pre-computation deferred to Phase 2 (both need team-lead/senior wiring).

### Changes
- AMPLIFY: TFD block now flags a success-path-only regression guard/smoke test as indistinguishable from a no-op — require the failing-input assertion. Signal: local pitfall 2026-06-30 (falsifier never confirmed).
- CULL: de-duped the §Shutdown ephemeral roster to "(roster at §Lifecycle)" — matches the existing L59 cross-ref pattern. Signal: Consolidation (roster listed twice).
- Deferred: PA impl-plan approval (advisor-as-approver) + shared-brief pre-computation → Phase 2 (cross-cutting; need team-lead + senior-engineer counterparts).

### Dimensions Evaluated
All 8. 2 (Actionability) AMPLIFY. 5 (Consolidation) CULL. 6 (Capability Growth) → PA + shared-brief deferred. 1/3/4/7/8 RETAIN.

### Rename
No rename.

## 2026-06-21

### Summary
Compacted 9 entries (2026-05-26..2026-06-09) into Compacted history per ADR 0001.

### Changes
- Replaced the 9 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (ADR 0001)

### Rename
No rename.

## 2026-06-20

### Summary
Fixed the docket graph flag-order drift, hardened the moving-tree gate to an explicit team-lead-GO gate (resolving a self-contradiction), and cross-referenced the Executable-claim gate from the review path. Net 0 (302→302). Drift: disabled (drift=0).

### Changes
- CULL (cited: docket-audit drift): `docket issue graph --mermaid <id>` → `<id> --mermaid` (matches help text + 4 other agents).
- AMPLIFY (cited: historical advisor-early-start, 3×): the moving-tree gate is now a hard "no verdict until explicit team-lead GO confirming tree frozen" gate; removed the self-contradicting "blockedBy edge IS the freeze gate" (demoted to a corroborating signal — neither blockedBy nor task-assignment binds a persistent advisor).
- AMPLIFY (cited: innovation): review step 7 now cross-references the Executable-claim gate (regex ACs + cross-dialect SQL EXECUTED, never approved by inspection).

### Dimensions Evaluated
1 Role Realism RETAIN · 2 Actionability AMPLIFY · 3 Boundary Clarity RETAIN · 4 Completeness RETAIN · 5 Consolidation RETAIN · 6 Cross-Comm AMPLIFY · 7 Spec Alignment CULL+AMPLIFY · 8 Rename RETAIN.

### Rename
No rename.

## 2026-06-19

### Summary
Adopted two memory-sourced review-rigor directives (cited-authority live-`ls`; zero-hits-grep-is-suspect) and trimmed a 3×-stated after-compaction re-Read rule to a single owner. Net +2 (286→288). Drift: skipped (seed-target was the Consensus/vote cross-ref section — unsafe).

### Changes
- AMPLIFY: cited-authority live-`ls` directive in No Guessing — `ls` an external-authority doc's path live during review; absent path + "never restate" = HIGH coherence break (file-level gap vs the existing directory-level check).
- AMPLIFY: zero-hits-grep-is-suspect addendum to the step-6 executable-claim gate — a zero-hit grep may be a quoting/word-split/loop bug; re-run a known-positive control before concluding absence.
- CULL: collapsed the triple-stated after-compaction re-Read rule — R7's exception now points to rule 5 as sole owner.

### Dimensions Evaluated
Capability Growth (AMPLIFY), Actionability (AMPLIFY), Consolidation (CULL). Others RETAIN. Teammate-envelope rule (L119) verified accurate vs current docs — no edit.

### Rename
No rename.

## 2026-06-17

### Summary
Added relay-authority rule 10, an AC-staleness review gate, and a distinct-lens mandate for doubled TDD review; trimmed two redundant passages. Trial: relay-authority / AC-staleness / distinct-lens → adopted.

### Changes
- AMPLIFY: new Communication Discipline rule 10 (relay authority) — peer-relayed/recalled directives carry no claimed-origin authority; direct operator instruction wins (closes gap vs security/team-lead; v2.1.166 runtime-enforced).
- AMPLIFY: AC-staleness gate in Review Workflow step 2 — flag issue ACs predating an accepted ADR on the same surface.
- AMPLIFY: distinct-lens mandate for the 2 TDD secondary reviewers (architecture+system-fit vs completeness+AC-testability).
- CULL: trimmed "Don't overthink" opener (restated No-Guessing/R6) and the step-4 Pre-Flight-Gate restatement.

### Dimensions Evaluated
Completeness (AMPLIFY), Capability Growth (AMPLIFY), Consolidation (CULL), others RETAIN.

### Rename
No rename.

## 2026-06-10

### Summary
Compacted 3 entries (2026-05-24..2026-05-25) into Compacted history per ADR 0001.

### Changes
- Replaced the 3 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (ADR 0001)

### Rename
No rename.

## 2026-06-10

### Summary
Trial: R5 advisor trigger ">50 assistant turns" → "after a TDD secondary-review fix-loop completes" → shipped (lockstep with team-lead.md). Phase 2 coherence: sole-editor rule reduced to a pointer at the security-engineer.md AUTHORITY copy.

### Changes
- Sole-editor rule: duplicated serialization wording replaced with pointer to security-engineer.md §Responsibility 1 (AUTHORITY); staff-specific auth/crypto caveat retained.
- R5 advisor trigger: observable fix-loop-completion event replaces the turn-count proxy.

### Dimensions Evaluated
Coherence pass (cross-file mirrors).

### Rename
No rename.

## 2026-06-10

### Summary
Review cycle 2026-06-10: all Phase 0 signals verified NO-OP (already encoded) or routed as coherence flags. No edits; 258 lines unchanged.

### Changes
- None. NO-OPs cited: already-present check (L76); AC-grep-from-live-file + budget gates (TDD step 6 / rule 6); docs/ux existence guard (L70). \$N-escaping routed to evolve-skills scope. Three coherence flags routed to Phase 2 (sole-editor duplication, R5 turn-count proxy, Light-TDD vs Rule 8(a)).

### Dimensions Evaluated
All 8.

### Rename
No rename.

## 2026-06-09

### Summary
Compacted 39 entries (2026-03-19..2026-05-19) into Compacted history per ADR 0001.

### Changes
- Replaced the 39 oldest entries with one-line ledger entries in the terminal Compacted history section (DKT-264)

### Dimensions Evaluated
History Compaction (ADR 0001)

### Rename
No rename.

## 2026-06-09

### Summary
Fable-5 mandate slice: encoded the highest-recurrence "already-present check before recommending a change" guard into No-Guessing; added the missing use-when trigger for WebFetch/WebSearch. Offset by deduping rule 6's redundant back-reference. Net +2 (258 lines).

### Changes
- No-Guessing: added "Already-present check before recommending a change" — grep target file + changelog before proposing any audit/memory-sourced change; already-encoded = NO-OP with citation.
- TDD step 3 (Study precedent): added WebSearch/WebFetch use-when trigger (current external sources not derivable from codebase; ground citation in fetched content).
- Comm rule 6: removed redundant "(TDD Workflow step 6; Code Review step 7)" back-reference (steps already point forward to rule 6).

### Dimensions Evaluated
Capability Growth, Prescriptive Capability Triggers, Consolidation & Trimming, Reasoning-echo audit (no hits), Spec Alignment, Boundary Clarity, Rename.

### Rename
No rename.

## 2026-06-09

### Summary
Phase 2 lead-initiated shutdown flip: comm rule 7 ephemeral sentence + §Shutdown Handling Ephemeral paragraph (pre-shutdown checklist step (d) removed; pitfalls ordering kept as (c)). Count unchanged (257).

### Changes
- Rule 7: ephemerals await team-lead's request, reply shutdown_response (FIX 22).
- §Shutdown Handling Ephemeral: Pre-idle checklist (a)-(c); idle-awaiting-shutdown normal (FIX 23). PITFALLS family fix (FIX 32).

### Dimensions Evaluated
Spec Alignment, Coherence.

### Rename
No rename.

## 2026-06-09

### Summary
Deduped rule 7's shutdown contract against §Shutdown Handling (roster + await-shutdown_approved now pointers), upgraded the TDD step 6 teammate-envelope clause from inference to the officially documented rule (only `tools`/`model` apply to teammates; body appended — code.claude.com agent-teams doc), encoded the stale-line-citation edit pitfall into Comm rule 5. Net 0 (257 lines).

### Changes
- Comm rule 7: spawn-form roster → §Lifecycle pointer; duplicated await-shutdown_approved sentence → compact parenthetical pointing at §Shutdown Handling.
- TDD step 6: "Teammate-mode envelope assumption" → "(documented)" with citation; added "only `tools` and `model` apply; body APPENDED" facts.
- Comm rule 5: never aim an Edit at a reviewer-cited line number — line numbers drift across revisions; re-Read and target content strings (manifest-flux pitfall).
- Confirmed NO-OPs: no-op-before-redraft triage, freeze-gate (Moving-tree gate), memory:project/effort frontmatter (present on all 7 agents).

### Dimensions Evaluated
Consolidation & Trimming (rule 7 dedupe), Spec Alignment (envelope doc citation), Capability Growth (stale-line-citation), Role Realism, Actionability, Boundary Clarity, Completeness, Rename.

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
