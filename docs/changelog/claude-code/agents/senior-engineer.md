# Changelog: senior-engineer

## 2026-07-11

### Summary
Compacted 3 entries (2026-06-09..2026-06-10) into Compacted history per the retention-compaction policy.

### Changes
- Replaced the 3 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (retention-compaction policy)

### Rename
No rename.

## 2026-07-11

### Summary
Phase 2 coherence fix: corrected the SP-2 teammate/report-only-subagent discriminator (family-wide lockstep with 5 sibling agents + the shutdown-protocol master). Net +32 bytes.

### Changes
- FIX[SUBSTANTIVE]: SP-2 LOCAL copy corrected — `name=` is the sole discriminator; report-only subagents run background-by-default since Claude Code v2.1.198, so `run_in_background` no longer discriminates. Stale phrasing contradicted team-lead.md's Phase-1-corrected copy and current harness behavior.

### Dimensions Evaluated
Spec Alignment (v2.1.198 harness behavior), Boundary Clarity (family-wide parity with 5 siblings + master).

### Rename
No rename.

## 2026-07-11

### Summary
evolve-agents cycle (SDLC role-comparison mandate): fixed a confirmed docket CLI drift and added docs-author hosting for the one genuine SDLC gap identified this cycle (end-user documentation). Net +685 bytes.

### Changes
- FIX[SUBSTANTIVE]: corrected "-f flag exists only on `create`" — `docket issue edit` also accepts `-f` (replaces attachments rather than appending); internal inconsistency with project-manager.md's own reference block.
- AMPLIFY[SUBSTANTIVE]: added a "Host for `docs-author`" bullet in What-You-Are-NOT, assigning end-user documentation (README/usage/API docs) ownership to this role — the one genuine gap identified by this cycle's SDLC role research (no existing owner; docs-researcher is retrieval-only). Phrased as "when dispatched to author end-user docs" rather than presupposing a specific team-lead.md dispatch-table row, pending Phase 2 reconciliation.

### Dimensions Evaluated
Actionability (CLI fix), Completeness / Boundary Clarity (docs-author). Read-before-Edit and build/commit hygiene already strongly stated — no duplication added. Role Realism/Consolidation/Spec Alignment/Capability Growth/Rename: RETAIN.

### Rename
No rename.

## 2026-07-10

### Summary
Compacted 2 entries (2026-06-09..2026-06-09) into Compacted history per the retention-compaction policy.

### Changes
- Replaced the 2 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (retention-compaction policy)

### Rename
No rename.

## 2026-07-10

### Summary
Phase 2 coherence follow-up: flagged vote-delegation JSON as a plain-text payload.

### Changes
- AMPLIFY: appended a wire-form clarification to the vote-delegation paragraph — the JSON is sent as a plain-text string, never SendMessage's structured `message` object (`delegation_*` are vote-skill conventions, not real `message.type` values). Matches team-lead.md:360's receiving-side fix (bug-audit FIX-9, fleet-wide sweep).

### Dimensions Evaluated
Actionability (cross-agent coherence sweep).

### Rename
No rename.

## 2026-07-10

### Summary
Coordination & tool-correctness fixes offset by redundancy trims. Net +119 bytes. Role & coordination focus this cycle.

### Changes
- AMPLIFY: Read-before-Edit now names shared/appended files (pitfalls.md, MEMORY.md) needing immediate re-Read — concurrent ephemerals append (historical-audit PREVENT-2, 13 sessions).
- CORRECTION: disambiguated `docket issue create -f` (flag) vs `docket issue file add` (positional, no -f) (bug-audit FIX-6, 3 sessions).
- AMPLIFY: premise-check extended from shared-helpers to ANY cited artifact (code/TDD/ADR path) (bug-audit PREVENT-16, 4+ sessions).
- CULL: redundant compaction re-read sentence, verbose Monitor bullet, and persistent-memory intro trimmed (each duplicated content already stated elsewhere).

### Dimensions Evaluated
Actionability (2 corrections), Capability Growth & Cross-Communication (2 amplify), Consolidation & Trimming (3 culls). Role Realism/Boundary/Completeness/Spec Alignment/Rename: RETAIN.

### Rename
No rename.

## 2026-07-01

### Summary
Trial: close-safety and plan-mode dispatch -> applied.

### Changes
- AMPLIFY: close handling now drains background shell tasks before the final report, requires `safe_to_close`, and names report contents plus idle-after-report boundaries.
- AMPLIFY: Plan mode dispatch now claims first, reads Docket/TDD/spec context, sends assumptions plus verification commands, and waits for proceed/revise before edits.
- CORRECTION: Docket file attachment example now uses repeatable `--file <path>` / `-f <path>` flags.

### Dimensions Evaluated
Close Safety, Plan Dispatch, Docket Traceability.

### Rename
No rename.

## 2026-06-30

### Summary
Phase 2: landed the PA (plan-approval) mode bullet now that team-lead adopted PA dispatch (operator-approved). Net +1 (489→490). Trial: PA plan-approval → applied.

### Changes
- AMPLIFY: PA-mode bullet — on a TDD-bearing issue dispatched `mode="plan"`, emit the impl PLAN and AWAIT approval before any edit; rejection returns to plan mode with feedback (no respawn). Catches impl-to-TDD divergence pre-edit. Signal: Phase 0 PA innovation (senior = PA's primary home).

### Dimensions Evaluated
6 (Capability Growth) AMPLIFY. 1/2/3/4/5/7/8 RETAIN.

### Rename
No rename.

## 2026-06-30

### Summary
Chained the two docket claim-writes into one Bash call (claim+ack 3→2 tool calls; reconciled the §Implementation L146 "two-step" wording to "chained" to stay internally coherent). Net -1 (490→489). PA-mode bullet deferred to Phase 2 (conditional on team-lead PA dispatch adoption).

### Changes
- AMPLIFY: dispatch claim now `docket issue edit -a && docket issue move in-progress` in ONE call (assignee-first preserved — team-lead's probe key intact). Signal: Phase 0 efficiency, highest-volume agent (124 inv/41 sessions).
- Deferred: PA-mode impl bullet (emit plan + await approval before edit) → Phase 2 (cross-cutting; dangling without team-lead PA dispatch + reviewer-side wiring).

### Dimensions Evaluated
All 8. 2 (Actionability) AMPLIFY. 5 (Consolidation) AMPLIFY (bash -1). 6 (Capability Growth) → PA deferred. 4 (Completeness) RETAIN (Read-before-Edit complete+top-placed despite 144 is_error — execution-discipline gap, not docs). 1/3/7/8 RETAIN.

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
One net-zero in-place edit extending an incoming-trigger to cover late/out-of-order directives contradicting closed work; five strongest Phase-0 signals confirmed already-encoded (NO-OP). Net 0 (488→488). Drift: disabled (drift=0).

### Changes
- AMPLIFY (cited: historical message-ordering signal): the @project-manager plan-change incoming-trigger now also catches any late directive contradicting already-closed on-disk state — resolution is reply-with-evidence-and-ask-which-is-final before acting.

### Dimensions Evaluated
1 Role Realism RETAIN · 2 Actionability RETAIN · 3 Boundary Clarity RETAIN · 4 Completeness RETAIN (TFD pre-flight, git-diff scoping, zsh `!` hygiene already encoded) · 5 Consolidation RETAIN · 6 Cross-Comm AMPLIFY · 7 Spec Alignment RETAIN · 8 Rename RETAIN.

### Rename
No rename.

## 2026-06-19

### Summary
Collapsed the duplicated two-step-claim mechanic to a pointer; folded the redundant "Idle after final report" paragraph's unique facts into the completion-contract step and removed it; corrected the pitfalls-memory survival claim (file verified absent on disk). Net -2 (384→382). Drift: neutral reorder of Core Operating Principle 3's three scenario-bullets → adopted.

### Changes
- CULL: Execution Workflow step 1 restated the claim command pair already owned by §Communication discipline → "Claim before work + dispatch-ack"; collapsed to a pointer.
- CULL: "Idle after final report" paragraph duplicated the Ephemeral completion contract; its 2 unique facts (TaskStop Monitor watches; team-lead owns the sweep, step 13) folded into step 5, paragraph removed.
- CORRECTION: pitfalls.md "is version-controlled and survives" → "version-controlled — once created … survives" (file absent; create-on-first-use).

### Dimensions Evaluated
Consolidation (CULL ×2), Spec Alignment (correction). Others RETAIN (fix-2 rate 2/22 healthy; shared-tree git-hygiene HELD per XC-1 spike-gate).

### Rename
No rename.

## 2026-06-17

### Summary
Repaired the dead "see Runtime Discipline" cross-reference (L38) by adding a non-numbered Shell-hygiene (zsh) reminder. Drift: neutral reword of the grep-call-sites bullet → adopted.

### Changes
- AMPLIFY: added a non-numbered "Shell hygiene (zsh)" bullet to Runtime Discipline (`!=` mangling, `$TMPDIR` edit-scripts) — the real target for L38's dangling pointer; R1-R7 canon preserved (NOT a new R8).
- Verified NO-OP: git-add overreach, locate-by-grep-not-line-number, out-of-order supersession already encoded.

### Dimensions Evaluated
Completeness / Actionability (AMPLIFY — xref repair), Consolidation (RETAIN), others RETAIN.

### Rename
No rename.

## 2026-06-10

### Summary
Compacted 3 entries (2026-05-25..2026-05-26) into Compacted history per ADR 0001.

### Changes
- Replaced the 3 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (ADR 0001)

### Rename
No rename.

## 2026-06-10

### Summary
Phase 2 coherence: gray-zone resolution gains an SE→staff cross-reference to the TDD-vs-direct rubric (staff-engineer.md §Responsibility 1).

### Changes
- One-clause cross-ref linking the escalate-or-implement test to staff's TDD-decision rubric — the two halves of one decision now reference each other.

### Dimensions Evaluated
Coherence pass (cross-file mirrors).

### Rename
No rename.

## Compacted history

Entries below were compacted per ADR 0001; full text in git history (see the compaction entry's date).

- 2026-03-19: Major consolidation pass removing ~400 lines (758 → 361) to bring the agent well under the 500-line budget.
- 2026-03-19: Added UX spec escalation trigger so @senior-engineer stops and requests design input when user-facing work lacks a spec in `docs/ux/`.
- 2026-03-19: Strengthened self-review step for generated/serialized output, removed non-actionable Incident Response section, compressed Cross-Cutting…
- 2026-03-19: Consolidated redundant build-verification steps, compressed Dependency & API Surface section and SDET boundary description, added SendMessage…
- 2026-03-19: Consolidated redundant instructions, compressed status-update checklist, added @staff-engineer review notification to self-review workflow…
- 2026-03-20: Consolidation pass removing duplicate content across sections, added memory frontmatter, calibrated self-review depth to change risk.
- 2026-03-20: Consolidation pass removing self-review/Config-as-Code duplication and implicit "when not to consult" list, added @sdet and @project-manager…
- 2026-03-20: Consolidated duplicate build-verification bullets, removed redundant anti-pattern, added @ux-designer cross-communication trigger, compressed…
- 2026-03-20: Removed Anti-Patterns section (restated by Core Operating Principles), compressed CLI Reference and Cross-Cutting Concerns, updated CLI with…
- 2026-03-21: Added cross-communication observability (SendMessage and /vote logging as Docket comments), updated CLI with missing vote flags and…
- 2026-03-29: CLI reference fixes from docket audit (reopen, --domain-tag, --limit, optional --voter, --status, --assignee, --quiet), consolidated Build &…
- 2026-03-29: Added TaskCreate/TaskUpdate/TaskList/TaskGet to frontmatter, compressed Inter-Agent Communication (merged status updates and observability)…
- 2026-03-30: Added rigorous honest mentor directive near top of file. Removed /vote "when NOT" list, folded Mermaid Diagrams into Cross-Cutting Concerns…
- 2026-04-01: Added `model: opus[1m]` to frontmatter, compressed proactive sharing, /vote guidance, and Docket CLI Reference. Added docket aliases. Net: -13…
- 2026-04-06: Added TDD status gate (only implement from ACCEPTED TDDs). Compressed Core Operating Principles and Verification. Updated CLI reference with…
- 2026-04-16: Consolidation pass: trimmed Operating Context boilerplate, Docket Rules redundancy, and self-review bullet list. Aligned CLI reference with…
- 2026-04-16: Cross-communication pass: replaced vague "proactive sharing" prose with concrete phase-indexed SendMessage trigger matrix (before/during/close…
- 2026-04-19: Embedded operator "No guessing — verify" rule at top-of-file principle level adjacent to Rigorous honesty, and reinforced operationally in…
- 2026-05-05: Consolidation pass eliminating triple-stated "no guessing" overlap, redundant `docs/spec/` references, and the restated Docket Rules block.…
- 2026-05-05: Phase 0+2 capability adoption: added `Monitor` for build/dev-server/test streaming, `docket issue graph --mermaid` for refactor blast-radius…
- 2026-05-06: Capability growth via Phase 0 docket CLI audit — added `docket issue log <id>` (pre-start activity context), `docket issue graph --direction…
- 2026-05-06: Adopted PM's operator-visibility contract: every peer SendMessage is mirrored as a Docket comment with `[SE→@agent] {summary}` prefix (operator…
- 2026-05-06: Phase 2 coherence pass: extended operator-visibility contract with high-stakes real-time cc rule (TDD-deviation-requiring-re-plan…
- 2026-05-07: BALANCED-mode consolidation pass: removed three true duplications between Proactive SendMessage Triggers and Check Specs / Navigate Ambiguity…
- 2026-05-07: Phase 2 coherence: corrected the team-mode coordination model claim that contradicted SE's own SendMessage triggers and the team-wide pattern.
- 2026-05-07: Capability-growth pass: closed worktree-isolation gap (SE is the primary user of `isolation="worktree"` per orchestrator) and project-memory…
- 2026-05-08: Removed redundant Docket CLI cheatsheet, deduped TDD-gate and file-attachment rules, sharpened memory section, and made the ADR-broadcast…
- 2026-05-08: Phase 2 coherence: surfaced the sub-agent invocation ban in the CRITICAL banner — teammates only read their own definition, so the team-lead.md…
- 2026-05-08: Phase 3 operating discipline: codified four behavioral rules surfaced by operator — no surface-level fixes, no retry loops / no install…
- 2026-05-09: Trim-heavy pass aligned with operator feedback (file-size bloat, no overthinking, output quality). Compressed top-of-file principles…
- 2026-05-09: Phase 2 coherence: added explicit "NOT @security-engineer" boundary (now that the security consult trigger exists), and closed bidirectional…
- 2026-05-13: Added "Implement Directly vs. Escalate for Design" rubric so SE proceeds directly on bugfixes/config/internal-refactors/pattern-extensions and…
- 2026-05-13: Phase 2 coherence: added Direct Task / solo-mode invocation acknowledgment to Operating context — defines behavior when team-lead delegates a…
- 2026-05-16: Consolidated all 8 operator communication-discipline rules into a non-negotiable block (closed-loop, ack, claim-first-Rule-7, 10-min…
- 2026-05-16: Phase 2 coherence: normalize security-advisor canonical form across three references.
- 2026-05-17: Vote delegation payload synced to canonical `skills/vote/` Delegation Protocol shape (Phase 2 handoff from 2026-05-17 evolve-skills cycle).
- 2026-05-17: pass 2: Cycle 2026-05-17 historical-audit pass: dropped aspirational `.claude/agent-memory/senior-engineer/` reference (directory unused across…
- 2026-05-17: Phase 2 coherence: Tightened dispatch-ack to same-turn pattern matching sdet.md Rule 2. Added @security-engineer CVE/advisory incoming trigger.
- 2026-05-19: Cycle 2026-05-19 historical-audit pass. Closes the DKT-2 close-without-verify failure mode (strongest single signal in the audit) with an…
- 2026-05-19: Phase 2 coherence: Added `ux-advisor` canonical-name reference for symmetry with existing `security-advisor` / `advisor` patterns. Existing UX…
- 2026-05-19: Phase 2 coherence — brief contradiction-detection + envelope fallback: Closed the second line of defense on the Phase 1 P1 lesson: added brief…
- 2026-05-24: Phase 2 coherence — shutdown_response routing rule: Closed the 6 historical `is_error:true` "shutdown_response must be sent to team-lead"…
- 2026-05-25: Phase 1 self-review — shutdown routing example + peer dispatch hard gate: Two targeted rewrites, net 0 lines. (1) Replaced abstract "never to…
- 2026-05-25: Two coherence fixes: (1) added docs-dir existence guard to "Check Specs Before Implementing" matching project-manager/staff-engineer convention (prevents
- 2026-05-26: Encoded two-step claim ritual (`docket issue edit -a @senior-engineer` BEFORE `docket issue move in-progress`) across bash codeblock + Communication Discipline
- 2026-05-26: Stripped 3 dangling citations (Phase 0 verified files do not exist in this repo). Redirected to team-lead.md anchors.
- 2026-05-26: TDD deep-read gate added to step 2; Override Convention compressed. Net -7.
- 2026-05-26: Phase 2 coherence — ux-designer trigger reworded (vacuous → concrete); TaskStop drain doctrine fleet parity.
- 2026-05-30: Dead `commit` skill removed from frontmatter; frozen "(32 fix-round ephemerals)" count trimmed. Net -1.
- 2026-05-30: Frontmatter `**No code comments.**` block compressed to pointer to principle 7. Net 0.
- 2026-05-30: Phase 2 coherence — dangling `§6 continuity preamble` pointer removed ×5 (fleet sweep). Within-line.
- 2026-06-05: Shared-tree diff scoping + Premise-check + `\!=` escape fix + step-1 probe dedup. Net +1.
- 2026-06-09: Docs-exploration block triplicated → canonical Docs-paths block. Net -6.
- 2026-06-09: Docket cwd-outside-repo guard added to Execution Workflow step 6. Net 0.
- 2026-06-09: evolve-skills reference update: code-review → code-review-verdict; 1 reference updated.
- 2026-06-09: Audit-driven hardening — mv/rename gate, git-add-self-verify prohibition, grep-based edit-site location. Net -2 (360→358).
- 2026-06-09: Phase 2 shutdown flip — completion-contract step 5 + Monitor-watch replaced with await-lead semantics. Count unchanged (358).
- 2026-06-09: Fable-5 calibration — minor-choice autonomy + silence-default narration added; Technical Debt/Navigate-Ambiguity trimmed to offset. Net 0.
- 2026-06-09: Compacted 43 entries (2026-03-19..2026-05-25) into Compacted history per ADR 0001 (DKT-264).
- 2026-06-10: Fixed `.data.status` JSON-path bug in close-verify; compressed Tool-envelope (\$TMPDIR-script); scoped git-stash to shared-tree. Net 0.
