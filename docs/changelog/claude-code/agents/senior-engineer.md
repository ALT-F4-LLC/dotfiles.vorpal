# Changelog: senior-engineer

## 2026-07-21

### Summary
Compacted 4 entries (2026-06-30..2026-07-10) into Compacted history per the retention-compaction policy.

### Changes
- Replaced the 4 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (retention-compaction policy)

### Rename
No rename.

## 2026-07-21

### Summary
Phase 3 disambiguation: two vocabulary substitutions to remove multi-reading/confusable-name risk, no behavioral change.

### Changes
- FIX[COSMETIC]: Lifecycle "fresh Jobs" → "fresh ephemeral spawns" (sole family-wide occurrence of "Jobs", misreadable as background-job/fork-class dispatch after this cycle's fork-trial revert).
- FIX[COSMETIC]: Operating context "Stateless subagent" → "Stateless between spawns" (bare "subagent" collides with the reserved report-only-subagent mechanism term; every senior-engineer spawn is actually a teammate).

### Dimensions Evaluated
Confusable-name and multi-reading clarity (Phase 3).

### Rename
No rename.

## 2026-07-21

### Summary
Findings: 5 → 3 sub / 1 cos / 0 rej / 2 def / 0 enc. Adopted the shared phase_diff.sh cross-check for pre-close scope self-verification; corrected the AskUserQuestion tool-envelope fallback; made the /tmp→$TMPDIR rule explicit.

### Changes
- AMPLIFY[SUBSTANTIVE] (I-se1): Shared-tree diff scoping now cites `phase_diff.sh` for declared-vs-actual remainder detection before handoff — parity with sdet/security-engineer/staff-engineer, which already cite it.
- AMPLIFY[SUBSTANTIVE] (B6): Tool-envelope fallback corrected — AskUserQuestion has no Bash equivalent and routes via SendMessage team-lead when absent, instead of the wrong grep/find guidance.
- AMPLIFY[SUBSTANTIVE] (B2): Shell hygiene now explicitly prohibits literal `/tmp/…` paths (25x-recurring leak) with a concrete `cat > "$TMPDIR/edit.py"` pattern.
- CULL[COSMETIC]: trimmed the redundant inline pitfalls.md path listing in the pre-CANONICAL:PITFALLS bridge sentence (paths defined in full three lines below).

### Dimensions Evaluated
Actionability, Boundary Clarity, Capability Growth & Cross-Communication, Consolidation & Trimming. Deferred: B4 (READ-BEFORE-EDIT block already sharp, execution-leak not definition gap), D9 (teammate skills-inert caveat already correct).

### Rename
No rename.

## 2026-07-15

### Summary
Compacted 4 entries (2026-06-19..2026-06-30) into Compacted history per the retention-compaction policy.

### Changes
- Replaced the 4 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (retention-compaction policy)

### Rename
No rename.

## 2026-07-15

### Summary
Stale-dispatch check gains a scope discriminator (duplicate dispatch vs a new contradicting directive — overlapping trigger conditions had opposite prescribed responses); R7 now names the Read-before-Edit adjacency rule as a second outranking exception; master gains the missing empty-Read/new-path clause two citing files had assumed.

### Changes
- AMPLIFY[SUBSTANTIVE]: CANONICAL:STALE-DISPATCH-CHECK gains a Scope sentence distinguishing a duplicate dispatch (reply-once, never re-execute) from a new directive contradicting closed work (evidence + ask-which-is-final).
- AMPLIFY[SUBSTANTIVE]: R7 one-liner now names the READ-BEFORE-EDIT adjacency rule as a second exception that outranks it.
- AMPLIFY[SUBSTANTIVE]: CANONICAL:READ-BEFORE-EDIT master gains the new-path/empty-Read-satisfies-the-gate clause (staff-engineer.md and distinguished-engineer.md already cited this as master content it didn't contain).

### Dimensions Evaluated
Disambiguation (multi-reading ×3).

### Rename
No rename.

## 2026-07-15

### Summary
Hosts two new fleet-wide masters: `CANONICAL:READ-BEFORE-EDIT` (B3, 50-session fleet-wide failure class) and `CANONICAL:STALE-DISPATCH-CHECK` (R3, receiving-side crossed-in-flight convention); vote wire-form paragraph deduped to a Skill(vote) citation (I4).

### Changes
- AMPLIFY[SUBSTANTIVE] (B3): wrapped the existing Read-before-Edit paragraph (content unchanged, verified strongest copy) in `CANONICAL:READ-BEFORE-EDIT` markers so 6 other agent files can point to it.
- AMPLIFY[SUBSTANTIVE] (R3): new `CANONICAL:STALE-DISPATCH-CHECK` block — receiving-side convention for a stale inbound task_assignment.
- CULL[COSMETIC] (I4): vote wire-form paragraph replaced with a citation to `Skill(vote)`'s §Delegation Protocol (Team Path), which is the authoritative master.

### Dimensions Evaluated
Consolidation & Trimming, Cross-Communication (fleet-wide masters).

### Rename
No rename.

## 2026-07-15

### Summary
Wired the orphaned self_review_scan.sh into self-review step 5; added a terminal-state marker to the completion report to reduce the operator-reported team-lead idle gap. Findings: 5 → 2 sub / 0 cos / 1 rej / 0 def / 2 enc

### Changes
- AMPLIFY[SUBSTANTIVE] (I5): step 5 runs `self_review_scan.sh` as its mechanical first substep (debug/TODO/commented-code/merge-marker scan) before the manual re-read for error-handling/logic. Verified script existed (5570B) and was unreferenced.
- AMPLIFY[SUBSTANTIVE] (idle-pain, reviewer-originated): completion report now leads with a `DONE — awaiting shutdown_request` terminal marker so team-lead distinguishes finished from mid-work without probing.
- I9 rejected as a senior-engineer change — already-encoded via `regression_diff.sh baseline` mode (see sdet.md); routed as coherence.

### Dimensions Evaluated
Actionability, Capability Growth & Cross-Communication (all 8 evaluated). B3/B4/D1 already-encoded; 66% reinvocation rate assessed as legitimate ephemeral-lifecycle structure, not fix-loop churn.

### Rename
No rename.

## 2026-07-13

### Summary
Compacted 3 entries (2026-06-10..2026-06-17) into Compacted history per the retention-compaction policy.

### Changes
- Replaced the 3 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (retention-compaction policy)

### Rename
No rename.

## 2026-07-12

### Summary
Phase 2 coherence: migrated the hand-rolled team-mode vote proposal to `vote_delegate.sh` (fixes silent 0.67 threshold default — a real bug); compacted the SHUTDOWN-PROTOCOL-LOCAL block to the master-pointer form.

### Changes
- AMPLIFY[SUBSTANTIVE]: §Using `/vote` for Consensus now runs `vote_delegate.sh @senior-engineer` — fixes omitted `--threshold` bug; Wire-form warning preserved.
- CULL[SUBSTANTIVE]: §Shutdown Handling's 19-line SP-1/SP-2 spell-out reduced to a 3-line master pointer + Precondition — content fully covered by the shutdown-protocol master.

### Dimensions Evaluated
Cross-Agent Coherence (vote plumbing parity with 4 already-fixed files; SHUTDOWN-PROTOCOL block parity across the fleet).

### Rename
No rename.

## 2026-07-12

### Summary
Findings: 3 → 3 sub / 0 cos / 0 rej / 3 def / 2 enc. Applied 3 verified bug-audit/docs-research findings to the highest-volume role's Read-before-Edit and tool-envelope rules. Net +811 bytes.

### Changes
- AMPLIFY[SUBSTANTIVE] (BA-FIX2, DR1): widened Tool-envelope-check note — before calling ANY tool confirm it's in the actual system-prompt list (Grep/Glob/AskUserQuestion/TaskStop/MCP fall back to Bash equivalents); noted `skills:`/`mcpServers:` frontmatter is inert in teammate mode.
- AMPLIFY[SUBSTANTIVE] (BA-PREVENT4): extended Shared/appended-files rule to name `docs/tdd/*.md` & `docs/adr/*.md` as the dominant stale-read hotspot (109 occ/12 sessions) and promoted the `stat -f '%Sm %z'` mtime-stability check into canonical text.
- AMPLIFY[SUBSTANTIVE] (BA-PREVENT7): extended the `ls -d` doc-dir probe to also cover docs/tdd & docs/adr.

### Dimensions Evaluated
Actionability (all 3), Completeness/Boundary Clarity (DR1). BA-PREVENT5 (highest-volume bug): no new reminder added per its own guidance — dispatch-time fix owned by team-lead.md. Role Realism/Consolidation/Spec Alignment/Capability Growth/Rename: RETAIN.

### Rename
No rename.

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
- 2026-06-10: Phase 2 coherence — SE→staff cross-reference added linking escalate-or-implement test to staff's TDD-decision rubric.
- 2026-06-10: Compacted 3 entries (2026-05-25..2026-05-26) into Compacted history per ADR 0001.
- 2026-06-17: Repaired dead "see Runtime Discipline" cross-reference (L38) via non-numbered Shell-hygiene (zsh) bullet. Drift: neutral reword of the grep-call-sites bullet → adopted.
- 2026-06-19: Collapsed duplicated two-step-claim mechanic to a pointer; folded Idle-after-report facts into completion-contract step; corrected pitfalls-memory survival claim. Drift: neutral reorder of Core Operating Principle 3's three scenario-bullets → adopted.
- 2026-06-20: Extended @project-manager plan-change trigger to catch late directives contradicting closed work; five Phase-0 signals confirmed already-encoded. Drift: disabled (drift=0).
- 2026-06-21: Compacted 9 entries (2026-05-26..2026-06-09) into Compacted history per ADR 0001.
- 2026-06-30: Chained the two docket claim-writes into one Bash call (claim+ack 3→2 tool calls); PA-mode bullet deferred to Phase 2.
- 2026-06-30: Phase 2 landed the PA (plan-approval) mode bullet now that team-lead adopted PA dispatch. Net +1 (489→490). Trial: PA plan-approval → applied.
- 2026-07-01: Close handling drains background tasks pre-report; Plan mode dispatch claims-then-waits for proceed/revise; Docket file-attach example fixed. Trial: close-safety and plan-mode dispatch -> applied.
- 2026-07-10: Coordination & tool-correctness fixes (shared/appended-files rule, docket create -f vs file add, premise-check widened) offset by redundancy trims. Net +119 bytes.
- 2026-07-10: Phase 2 coherence follow-up — flagged vote-delegation JSON as a plain-text payload, never SendMessage's structured `message` object; matches team-lead.md bug-audit FIX-9.
