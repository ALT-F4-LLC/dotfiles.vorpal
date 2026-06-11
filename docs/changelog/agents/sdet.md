# Changelog: sdet

## 2026-06-10

### Summary
Compacted 2 entries (2026-05-25..2026-05-25) into Compacted history per ADR 0001.

### Changes
- Replaced the 2 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (ADR 0001)

### Rename
No rename.

## 2026-06-10

### Summary
Culled the redundant "Idle after verdict (await-lead semantics)" paragraph — a 4-way restatement of comm rule 6, Lifecycle, §Await-lead, and §Drain — folding its one unique verb (`TaskStop`) into Drain-before-shutdown. Net -2 (341→339).

### Changes
- CULL: §Shutdown Handling "Idle after verdict" paragraph — every clause already owned elsewhere (grep-verified, no inbound references; Phase 0 retire signal).
- AMPLIFY: §Drain-before-shutdown gains explicit `TaskStop outstanding watches` verb.

### Dimensions Evaluated
All 8; Consolidation primary; 7 dimensions RETAIN (0 operator-corrections, 0 stalls, 0 shutdown-rejections in window).

### Rename
No rename.

## 2026-06-09

### Summary
Compacted 38 entries (2026-03-19..2026-05-24) into Compacted history per ADR 0001.

### Changes
- Replaced the 38 oldest entries with one-line ledger entries in the terminal Compacted history section (DKT-264)

### Dimensions Evaluated
History Compaction (ADR 0001)

### Rename
No rename.

## 2026-06-09

### Summary
Fable-5 mandate slice: added autonomy calibration (pick minor choices, note in report) and silence-default narration (text only on finding/direction-change/blocker) to the decisiveness paragraph; trimmed a redundant compaction-re-read clause to offset. Net +2 (341 lines).

### Changes
- Extended "Don't overthink" paragraph with autonomy-calibration + narrate-by-exception directive; silence-default scoped to between-tool-call narration only, preserving comm rule 8 progress signal and verdict-cites-evidence rule
- Trimmed duplicate "re-read after compaction" clause from operating-context line (covered by comm rule 9 + R7)
- [NO-OP, grep-cited] Prescriptive triggers, reasoning-echo absence, historical signals 1-3 all already encoded

### Dimensions Evaluated
Consolidation & Trimming (primary), Autonomy Calibration, Silence-Default Narration, Prescriptive Triggers, Reasoning-Echo

### Rename
No rename.

## 2026-06-09

### Summary
Phase 2 lead-initiated shutdown flip: comm rule 6, Lifecycle, Verifier Composition, §Shutdown Handling (Proactive→Await-lead), Monitor-watch paragraph. Rule numbering 1-10 intact; reject-on-unrecoverable-test-results ground preserved. Count unchanged (340).

### Changes
- Rule 6 retitled "await lead's request, same-turn reply"; self-emit removed (FIX 17).
- Lifecycle sequence, sister-verifier line, Proactive→Await-lead, drain clause, Monitor-watch paragraph flipped (FIX 16, 18-21). PITFALLS family fix (FIX 32).

### Dimensions Evaluated
Spec Alignment, Coherence, Boundary Clarity.

### Rename
No rename.

## 2026-06-09

### Summary
Encoded the three historical-audit focus areas as within-line appends: verbatim-command verification, marker-derived (never hardcoded) sweep bounds, Monitor-sandbox + no-backgrounded-provisions. Re-verified the 2026-06-05 "already in verify-ac" NO-OP claim — rule absent from SKILL.md (grep-refuted), so encoded here; mirror routed to evolve-skills. Net -8 (348→340).

### Changes
- §Verification Workflow step 3: literal-command verbatim rule + marker-derived grep-sweep bounds (stale hardcoded ranges fail OPEN).
- §Test Failure Diagnosis: Monitor is sandboxed (no credential paths — foreground poll loops); never background long provisioning commands.
- Operating context: memory save-list deduped to §Shutdown Handling back-reference.
- §Defect Analysis folded into §Bug Reporting opener (-4).
- §Greenfield Test Strategy: 4-step list → single prose line (-4).

### Dimensions Evaluated
Actionability (3 historical focus areas), Consolidation & Trimming (3 trims), Spec Alignment (verify-ac NO-OP claim refuted), Boundary Clarity, Completeness, Role Realism, Capability Growth, Rename.

### Rename
No rename.

## 2026-06-09

### Summary
Phase 2 fleet decision: added the docket cwd-outside-repo silent-no-op guard + reconcile-by-`updated_at` discipline to comm rule 7 (within the existing claim-convention line; count unchanged at 348). Covers sdet's `reopen`/`comment add`/test-infra `move` writes — recurring theme A.

### Changes
- Comm rule 7: appended cwd guard — docket commands silently NO-OP from a cwd outside the repo tree; `cd` repo-root same Bash call + confirm `updated_at`; a stale read is not a write-failure (reconcile by timestamp, never force-write).

### Dimensions Evaluated
Capability Growth & Cross-Communication (primary), Actionability, Spec Alignment, Rename

### Rename
No rename.

## 2026-06-09

### Summary
One Consolidation & Trimming dedup (line count unchanged at 348; fewer words). §Verification Output's trailing closeout recap re-stated the close/comment → SendMessage → shutdown chain already owned by comm rule 6, Lifecycle, and Execution Workflow step 5 — collapsed to a single back-reference chain. AskUserQuestion-on-spawn flag investigated and dismissed (correctly gated behind "Standalone:"); flagged to Phase 2 as a parity-bound fleet pattern.

### Changes
- §Verification Output: collapse duplicated closeout-sequence enumeration to a back-reference chain (targets verified: comm rule 6, §Execution Workflow step 5, §Inter-Agent Communication matrix).

### Dimensions Evaluated
Consolidation & Trimming (primary), Spec Alignment, Boundary Clarity, Role Realism, Actionability, Completeness, Capability Growth, Rename

### Rename
No rename.

## 2026-06-05

### Summary
Two Consolidation & Trimming dedups (net 0 lines; 341 lines). Execution Workflow step 2 collapsed to a comm rule 7 back-reference (claim convention was near-verbatim duplicated). §Shutdown Proactive's idle-role enumeration collapsed to a comm rule 6 / Lifecycle back-reference, keeping only the unique precondition. Both historical focus areas resolved: literal-command-AC already encoded in verify-ac skill (NO-OP); destroy-recreate-NEW-backend is a runtime concern outside sdet's static-verification charter (routed to a tracking issue, not dropped).

### Changes
- §Execution Workflow step 2: fold spawn-type claim convention into a comm rule 7 back-reference (target verified present at L50).
- §Shutdown Handling Proactive: collapse duplicated advisor/idle-role enumeration to a comm rule 6 / Lifecycle back-reference (targets L38/L304 verified present); retain unique precondition.

### Dimensions Evaluated
Consolidation & Trimming (PRIMARY — 2 dedups) · Boundary Clarity (single canonical home for idle-role doctrine) · Spec Alignment (team-lead anchors + docket commands verified extant).

### Rename
No rename.

## 2026-05-30

### Summary
Phase 2 coherence: removed the dangling `§6 continuity preamble` pointer (1× — L38). No §6 heading exists; the preamble is defined in team-lead.md §Teammate Stall & Crash Recovery. Within-line; 341 lines.

### Changes
- `§6 continuity preamble` → `continuity preamble`. Fleet-symmetric sweep across senior-engineer/security-engineer/team-lead.

### Dimensions Evaluated
Cross-Agent Coherence (PRIMARY — dangling cross-ref) · Terminology consistency.

### Rename
No rename.

## 2026-05-30

### Summary
Two Consolidation & Trimming edits (net -3 lines; 344→341) deduping content the verify-ac SKILL already owns. §Verification Workflow step 5's edge-case battery (verbatim verify-ac SKILL.md) folded into a `Skill(verify-ac)` back-reference with the BLOCK/ACCEPT decide-clause merged in (old step 6 absorbed; 6-step list → 5). §Verification Output's "Closeout sequence" triplicated §Execution Workflow step 5 + the recipient matrix + comm rule 6 — collapsed to single back-references. Rejected deleting §Verification Depth (verify-ac names sdet.md as the depth-judgment authority). No behavioral loss.

### Changes
- §Verification Workflow: fold step 5 edge-case list into a verify-ac back-reference; merge old step 6 (decide ladder) into it.
- §Verification Output: collapse the closeout-sequence enumeration to back-references (§Execution Workflow step 5 / §Inter-Agent Communication matrix / comm rule 6).

### Dimensions Evaluated
Consolidation & Trimming (PRIMARY — 2 dedups vs verify-ac skill) · Boundary Clarity (closeout now points to single-actor §Execution Workflow step 5) · Completeness (no Task() drift; frontmatter memory/effort/color already wired)

### Rename
No rename.

## 2026-05-30

### Summary
Two edits from the evolve-agents self-review (net ~0; 344 lines). (1) Deduped the §Test Failure Diagnosis snapshot sentence — verbatim-redundant with §Testing Philosophy's "never blind-update; trace each diff..."; folded to a back-reference + the non-redundant table-driven pointer. (2) Scoped "move" in the §CRITICAL: Verify Issues header to read-only/BLOCK-reopen-only, closing the historical-audit verifier-ephemeral claim-drift gap at the section opener (Rule 7 / step 2 already encode it; the header undercut them).

### Changes
- §Test Failure Diagnosis Snapshots para: collapse redundant blind-update clause to a §Testing Philosophy back-reference.
- §CRITICAL: Verify Issues header: scope "move" to READ-ONLY + BLOCK-reopen; cross-reference comm rule 7.

### Dimensions Evaluated
Consolidation & Trimming (PRIMARY — snapshot dedup) · Boundary Clarity (claim-drift gap at section header, historical-audit focus) · Spec Alignment (verify-ac rename consistent, no Task( drift; hook events TeammateIdle/background_tasks/session_crons correct)

### Rename
No rename.

## 2026-05-26 (Phase 2 coherence)

### Summary
Two coherence fixes from Phase 2 cross-agent review. (1) §Execution Workflow step 5 contradicted senior-engineer.md step 6 — both closed the issue, making sdet's `docket issue close` a no-op. Rewritten as "issue already closed by senior; APPROVE = comment-only; ACCEPT WITH CAVEATS = comment + route follow-up; BLOCK = reopen+comment (step 6)". (2) §Shutdown Handling auto-shutdown block now matches project-manager.md's inline `TaskStop the Monitor watch (drain doctrine — outstanding watches at shutdown leak resources)` between final-report and `shutdown_request` per drain-doctrine symmetry.

### Changes
- §Execution Workflow step 5: rewrite to acknowledge prior @senior-engineer close; branch by verdict (APPROVE/ACCEPT-WITH-CAVEATS/BLOCK) without re-closing.
- §Shutdown Handling §Auto-shutdown on idle bullet: add inline TaskStop the Monitor watch per PM symmetry.

### Dimensions Evaluated
Boundary Clarity (PRIMARY — close-flow ownership now single-actor) · Spec Alignment (drain doctrine fleet-symmetric)

### Rename
No rename.

## 2026-05-26

### Summary
Two systemic alignments net +2 lines (337 → 339). (1) §Verifier Composition contradicted team-lead.md — said "no single variant" while team-lead.md DEFAULTS to single `verifier` and opts up to paired only on ≥3 issues / ≥5 files / security-sensitive. Rewritten to match, with canonical-name guard against the 20+ observed drift variants (`verifier-DKT-16`, `verifier-full`, etc.). (2) Claim-via-`docket issue move` drift (team-lead pitfalls.md in cross-project memory flagged sdet ephemerals generalizing senior-engineer's claim-first rule to verification, regressing issue state). Comm rule 7 + Execution Workflow step 2 + rule 2 reference now distinguish: verification = ack-only (no `docket issue move`); test-infra writing = claim+ack per @senior-engineer convention.

### Changes
- §Verifier Composition: rewrite to default-single + opt-up-paired (team-lead Rule 8); codify three canonical spawn names; refuse issue-scoped drift variants.
- §Lifecycle (L38): spawn-name list reframed; fix-loop wording matches default-single.
- §Comm Discipline rule 7 (L50): split verification (ack-only, no move) from test-infra (claim+ack).
- §Execution Workflow step 2 (L237): mirror rule 7 split.
- §Comm Discipline rule 2 (L45): updated cross-reference to rule 7's spawn-type branches.

### Dimensions Evaluated
Spec Alignment (PRIMARY — verifier-composition realignment with team-lead Rule 8) · Boundary Clarity (PRIMARY — claim-via-move drift fix) · Capability Growth (canonical-name guard against drift variants)

### Rename
No rename.

## 2026-05-26 (Phase 2 — strip 4 dangling docs/tdd/* citations)

### Summary
Stripped 4 dangling citations (Phase 0 verified files do not exist in this repo). Redirected to team-lead.md anchors.

### Changes
- L34 Lifecycle: dropped "+ docs/tdd/reviewer-doubling-lifecycle.md §4.4" tail.
- L162 Verifier Composition: dropped "+ reviewer-doubling-lifecycle.md §4.2 row 3" tail.
- L167 reconciliation note: replaced "TDD §4.3" with team-lead.md step 14 anchor.
- L319 Runtime Discipline opener: replaced "§4.5 applicability matrix" with team-lead.md §Runtime Discipline anchor.

### Dimensions Evaluated
Spec Alignment (PRIMARY — No Guessing violation closed)

### Rename
No rename.

## 2026-05-26 (Phase 1 — shutdown coordination: proactive emit + drain)

### Summary
Five edits encoding proactive ephemeral self-shutdown (verdict-then-`shutdown_request` as FINAL TOOL CALL same turn) per operator directive. Lifecycle, Comm Rule 6, Verifier Composition, Verification Output, and Shutdown Handling all clarified. Background-task drain rule added. Sister-verifier coordination clarified as peer-only (not joint persistence). Net +4 lines (367 → 371).

### Changes
- §Lifecycle: enumerated three ephemeral spawn names; explicit "not one of the three sanctioned idle advisors"; sequence ends with `shutdown_request` as FINAL TOOL CALL the same turn.
- §Comm Rule 6: split into proactive-emit (default for sdet, post-verdict) vs reactive-reply; routing rule strengthened.
- §Verifier Composition: sister coordination is peer messaging only — each verifier shuts down independently.
- §Verification Output: explicit 3-step closeout sequence ending in `shutdown_request`.
- §Shutdown Handling: proactive subsection added; `background_tasks`/`session_crons` drain rule added; "only the three advisors stay idle" framing.

### Dimensions Evaluated
Actionability (PRIMARY — verdict-then-shutdown as final tool call) · Boundary Clarity (sister-verifier peer-only) · Capability Growth (proactive emission + drain rule) · Completeness (background-task drain)

### Rename
No rename.

## Compacted history

Entries below were compacted per ADR 0001; full text in git history (see the compaction entry's date).

- 2026-03-19: Major consolidation from 867 to 308 lines. Merged verbose responsibility sections, eliminated redundant and generic content, compressed all…
- 2026-03-19: Added stateless operating context, removed non-executable human-process sections (Test Planning, Communication Style), compressed…
- 2026-03-19: Tightened greenfield strategy to reference spec, removed redundant "Running Tests" subsection, replaced prose review section with actionable…
- 2026-03-19: Compressed Inter-Agent Communication section (-20 lines of redundant status/intelligence lists), added greenfield zero-test handling, tightened…
- 2026-03-20: Consolidated Operator Alignment into Check Specs preamble, compressed Testing Philosophy, removed inverse /vote guidance, added effort…
- 2026-03-20: Consolidated flaky test management into diagnosis workflow, trimmed redundant philosophy opener, added BLOCK notification trigger and…
- 2026-03-20: Merged Block/Accept Criteria into Verification Workflow, compressed greenfield edge-case steps, removed standalone test code review section…
- 2026-03-20: Added `reopen` and `log` docket commands to workflow, compressed Docket CLI Reference and Per-Session Metrics, added rework return step.
- 2026-03-21: Added cross-communication observability (Docket logging for BLOCK/coverage-gap/vote), fixed operating context to acknowledge project memory…
- 2026-03-29: Fixed Docket CLI reference inaccuracies (voter defaults, missing reopen/domain-tag/limit), compressed Pre-Flight Goal-Alignment Gate and…
- 2026-03-29: Added TaskCreate/TaskUpdate/TaskList/TaskGet to frontmatter and verification workflow, compressed cross-communication observability, proactive…
- 2026-03-30: Added rigorous honest quality gatekeeper directive, compressed Mermaid subsection and "When NOT to consult" list, tightened Pre-Flight gate.…
- 2026-04-01: Added `model: opus[1m]` to frontmatter, added context compaction awareness, compressed Inter-Agent Communication, merged status/observability…
- 2026-04-06: Replaced direct `/vote` invocation with team-mode delegation pattern (critical cross-cutting fix — prevents nested team spawning). Added global…
- 2026-04-06: Added TDD status gate awareness to spec-checking workflow, updated Docket CLI reference with new vote flags, compressed Testing Philosophy and…
- 2026-04-16: Consolidation pass — removed duplicated operator-alignment guidance between Pre-Flight gate, Check Specs ambiguity paragraph, and Verification…
- 2026-04-16: Cross-communication pass: replaced 5 prose Inter-Agent Communication subsections with an 11-trigger notification table (6 new triggers). Added…
- 2026-04-19: Embedded operator "No guessing" behavioral gate after Quality stance — verification must be evidence-based (Read/Grep source, Bash run code…
- 2026-05-05: Consolidation pass — trimmed NOT section restating description, compressed operating-context/TDD-gate to peer-brevity, removed duplicated…
- 2026-05-05: Phase 0+2 capability adoption: added `Monitor` to tools with run_in_background + until-loop pattern for long test runs / CI watches / flaky…
- 2026-05-06: Cross-agent comms visibility pass — adopted PM's `"[SDET→@agent] {summary}"` Docket-comment logging so operator can see SendMessage traffic in…
- 2026-05-07: Coherence and consolidation pass — removed duplicated push-tests-down rationale (already in Test Pyramid), trimmed Testability Advocacy…
- 2026-05-07: Phase 2 coherence: aligned standalone-mode AskUserQuestion shape language with peer agents.
- 2026-05-07: Capability adoption pass — documented persistent agent-memory dir for SDET-specific recurring-signal tracking (flaky patterns, fixture quirks…
- 2026-05-08: Coherence & trimming pass — merged operating-context + agent-memory paragraphs into senior-engineer-style single block, removed three duplicate…
- 2026-05-08: Phase 2 coherence: surfaced the sub-agent invocation ban in the CRITICAL banner; aligned testability-trigger vocabulary with ux-designer.
- 2026-05-08: Phase 3 operating discipline: codified two behavioral rules surfaced by operator — no retry loops on failing test commands (ask for help…
- 2026-05-09: Phase 1 trim + bidirectional coherence — compressed Quality stance, No-guessing, Stop-and-ask, Pre-Flight, Inter-Agent, /vote, Shutdown, and…
- 2026-05-13: Added LIGHT vs FULL verification depth thresholds — trivial fixes get one-line APPROVE; non-trivial work still uses the structured template.…
- 2026-05-13: Phase 2 coherence: added @security-engineer to "What You Are NOT" with security-advisor persistent-name alias; annotated `docket issue close`…
- 2026-05-16: Encoded 8 operator communication-discipline rules (closed-loop reply, ack, saturation, blocker, verify, shutdown, claim-first, 10-min progress)…
- 2026-05-16: Phase 2 coherence: align Communication Discipline rule numbering with brief's canonical map (rule 7 = claim-first, rule 8 = 10-min progress).
- 2026-05-17: Two Phase 2 handoffs from the 2026-05-17 evolve-skills cycle: (1) Vote delegation payload synced to canonical `skills/vote/` shape; (2)…
- 2026-05-17: Addresses highest-severity audit signal (3 operator history corrections + 17 TeammateIdle hits) by closing the dispatch-to-first-SendMessage…
- 2026-05-17: Phase 2 coherence: Added Read-before-Edit/Write reflex as Rule 9, matching Phase 1 propagation across Edit/Write-capable agents.
- 2026-05-19: Closes audit gaps: verification-evidence specificity (real-vs-mocked at trust boundaries), `index.lock` recovery (fleet-wide #1 error, sdet=8)…
- 2026-05-19: Phase 2 coherence: Universal-mirror visibility contract alignment (replaces narrower "BLOCK / coverage-gap / vote / approach-changing" trigger).…
- 2026-05-24: Phase 2 coherence — shutdown_response routing rule: Closed the 6 historical `is_error:true` "shutdown_response must be sent to team-lead"…
- 2026-05-25: Three behavioral gaps from 10+ sandbox-blocked errors and 2 operator over-reach interruptions in historical audit: sandbox off-limits documentation, jq
- 2026-05-25: Three coherence fixes from Phase 2 audit: (1) added concrete WRONG/RIGHT shutdown-routing example to Comm Discipline rule 6 for fleet parity with
