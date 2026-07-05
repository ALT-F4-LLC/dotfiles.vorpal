# Changelog: sdet

## 2026-07-01

### Summary
Compacted 2 entries (2026-06-09..2026-06-09) into Compacted history per ADR 0001.

### Changes
- Replaced the 2 oldest date-headed entries beyond the 10-entry keep-window with one-line ledger entries.

### Dimensions Evaluated
History Compaction (ADR 0001)

### Rename
No rename.

## 2026-07-01

### Summary
Phase 3 Disambiguation follow-up: clarified SDET report-only defect routing and shutdown report fields.

### Changes
- DISAMBIG: scoped defect Docket comments to interactive paired/test-infra spawns; lone verifier defects stay in the team-lead final report.
- DISAMBIG: normalized SP-1 final-report schema with explicit `safe_to_close` close readiness.

### Dimensions Evaluated
Phase 3 Disambiguation; report-only routing; shutdown schema.

### Rename
No rename.

## 2026-07-01

### Summary
Phase 2 coherence follow-up: made lone `verifier` report-only semantics read-only across Docket and tests.

### Changes
- FIX: default report-only verifier no longer comments, reopens, or writes tests; findings return to team-lead for routing.
- FIX: draft-TDD override Docket mirroring is scoped to team-lead or interactive spawns, not lone report-only verification.

### Dimensions Evaluated
Report-only lifecycle, Docket mutation scope, verifier composition.

### Rename
No rename.

## 2026-07-01

### Summary
Trial: report-only verifier lifecycle -> applied. Phase 1 SDET-only edits aligned lifecycle/progress, verifier composition, risk-gated set-diff, TDD override handling, and `fix_owner` output.

### Changes
- AMPLIFY: default `verifier` is report-only: one final report to team-lead, no teammate `send_input`; paired verifiers and test-infra stay interactive.
- AMPLIFY: risk-gated failing-test set diff; LIGHT checks may run targeted command only and state why full set-diff was not risk-justified.
- AMPLIFY: explicit operator override required for normally blocking TDD gate; verdict relays append `fix_owner`.

### Dimensions Evaluated
Phase 1 approved edits: lifecycle, progress, composition, risk gate, TDD override, output contract.

### Rename
No rename.

## 2026-06-30

### Summary
Phase 3 disambiguation polish: sharpened the report-only default verifier wording so it doesn't blur the report-only-vs-teammate distinction. Net 0.

### Changes
- DISAMBIG polish: "one ephemeral covers BOTH..." → "one report-only worker covers BOTH...". Signal: Phase 3 remaining-issue ("ephemeral" overloaded vs Rule 7 teammate lifecycle).

### Dimensions Evaluated
Phase 3 disambiguation.

### Rename
No rename.

## 2026-06-30

### Summary
Phase 2 coherence: reconciled the DEFAULT lone `verifier` to run as a report-only subagent (mirrors team-lead step 15) across Lifecycle / comm rule 6 / Verifier Composition / Shutdown + 5 scope-notes (comm rules 2, 7, 8, Inter-Agent matrix, step 5 closeout) so the no-SendMessage path is coherent; added the incoming abuse-case consult trigger; chained the test-infra claim. Net +1 (476→477).

### Changes
- AMPLIFY: DEFAULT single `verifier` = report-only subagent (plain-text verdict to team-lead, no shutdown handshake); paired-panel verifiers stay ephemeral teammates. Signal: team-lead step 15 (Distribution-Mechanism Gate).
- AMPLIFY: 5 scope-notes clarifying the SendMessage-based rules (ack, progress, matrix routing, closeout) apply to teammate/paired paths; the report-only default returns its verdict to team-lead, who routes. Signal: coherence (report-only has no SendMessage).
- AMPLIFY: incoming trigger — @security-engineer plan-phase abuse-case consult on a no-TDD security change → reply with abuse cases before the diff (FIX 5, mirrors security outgoing).
- Aligned test-infra claim to the chained one-call (FIX 7).

### Dimensions Evaluated
6 (Capability Growth) AMPLIFY + coherence reconciliation. 1/2/3/4/5/7/8 RETAIN.

### Rename
No rename.

## 2026-06-30

### Summary
Folded one new cross-project pitfall (GitOps selfHeal signal-timing) and one path-handling guard (EISDIR) into existing lines, offset by deduping the TFD FIX-verdict restatement. Net 0 (476→476). Two live-cluster Phase 0 items (kind-reaping, Monitor/~/.kube/config) already covered — not re-added. verifier-as-report-only-subagent flagged to Phase 2 (team-lead-owned).

### Changes
- CULL: line 322 FIX-verdict ladder restated the TFD-LOCAL block (lines 269-275); collapsed to a terse cross-ref, both verdict poles preserved. Signal: Consolidation HIGHEST.
- AMPLIFY: GitOps selfHeal:true reverts hand-applied resources — capture real-system signal AFTER sync, folded into verification discipline (c). Signal: cross-project pitfall ×2 repos.
- AMPLIFY: EISDIR directory-path guard folded into Verification Workflow step 2. Signal: the one real is_error in the historical audit.

### Dimensions Evaluated
All 8. 2 (Actionability) AMPLIFY (EISDIR). 4 (Completeness) AMPLIFY (selfHeal). 5 (Consolidation) AMPLIFY (TFD dedup). 1/3/6/7/8 RETAIN.

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
Folded two uncovered sandbox/verification lessons into existing blocks + deduped the kubectl/credential restatement. Net 0 physical lines (472→472; additions appended to existing lines). Drift: disabled (drift=0).

### Changes
- AMPLIFY (cited: historical memory-lesson c + focus 1): the sandbox-interaction block now covers `!`-negation/process-substitution misfires + a 3-bucket OPENED/FAILED/INDETERMINATE connectivity classifier; deduped the Monitor+kubectl credential restatement already present at line 252.
- AMPLIFY (cited: focus 2): added verification discipline (d) "exact consumer command path" (reproduce the literal consumer call, never an equivalent); bumped the list intro "Three→Four disciplines" for numbering coherence.

### Dimensions Evaluated
1 Role Realism RETAIN · 2 Actionability RETAIN · 3 Boundary Clarity RETAIN · 4 Completeness AMPLIFY · 5 Consolidation AMPLIFY (kubectl dedup) · 6 Cross-Comm AMPLIFY · 7 Spec Alignment RETAIN · 8 Rename RETAIN.

### Rename
No rename.

## 2026-06-19

### Summary
Trimmed verify-ac-skill-owned duplication from §Verification Workflow (verbatim-command, layer-signals, edge-case battery, verdict ladder — all owned by the skill, verified at SKILL.md), preserving the 3 sdet-unique disciplines; removed a duplicate authority-path citation. Net -1 (369→368). Drift: skipped (seed-target was a CRITICAL section — unsafe).

### Changes
- CULL: §Verification Workflow steps 3-5 restated the verify-ac FULL procedure; collapsed to one skill-citing step + one step holding the 3 unique disciplines (grep-sweep marker, before/after set-diff, real-system+operator-confirm).
- CULL: §Execution Workflow step 4 duplicate format-authority path citation (already owned by §Verification Output).

### Dimensions Evaluated
Consolidation & Trimming (CULL). Role Realism / Actionability / Boundary Clarity / Completeness / Capability Growth / Spec Alignment / Rename — RETAIN (health high).

### Rename
No rename.

## 2026-06-17

### Summary
Added sandbox-interaction patterns, a never-trust-0-failures set-diff procedure, and a shared-worktree baseline hazard. Trial: sandbox-patterns / set-diff / worktree-baseline → adopted. Drift: neutral reword of the @ux-designer testability-trigger bullet → adopted.

### Changes
- AMPLIFY: sandbox-interaction patterns (Monitor+kubectl → dangerouslyDisableSandbox kubectl wait; gh/curl TLS retry; `$TMPDIR` vs /tmp).
- AMPLIFY: never trust an implementer's "0 new failures" — full-suite set-diff of before/after failing sets.
- AMPLIFY: shared-worktree baseline hazard — use file-copy / dedicated worktree, not git stash.

### Dimensions Evaluated
Actionability (AMPLIFY), Completeness (AMPLIFY), Consolidation (RETAIN), others RETAIN.

### Rename
No rename.

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
- 2026-05-26: Phase 1 — shutdown coordination: proactive emit + drain; Lifecycle/Rule 6/Verifier Composition/Verification Output/Shutdown Handling. Net +4.
- 2026-05-26: Phase 2 — stripped 4 dangling docs/tdd/* citations; redirected to team-lead.md anchors.
- 2026-05-26: Verifier Composition realigned to default-single (team-lead Rule 8); canonical spawn names; claim-via-move drift fix (verification = ack-only). Net +2.
- 2026-05-26: Phase 2 coherence — step 5 close-flow ownership fixed (SE closes, sdet branches by verdict); drain-doctrine TaskStop parity.
- 2026-05-30: Test Failure Diagnosis dedup + §CRITICAL header claim-drift gap fix. Net ~0.
- 2026-05-30: Consolidation — step 5 edge-case folded into verify-ac; §Verification Output closeout collapsed. Net -3.
- 2026-05-30: Phase 2 coherence — dangling `§6 continuity preamble` pointer removed (fleet sweep). Within-line.
- 2026-06-05: Two Consolidation & Trimming dedups — step 2 claim convention, Shutdown Proactive idle-role enumeration. Net 0.
- 2026-06-09: Consolidation — §Verification Output closeout recap collapsed to back-reference chain. Net 0.
- 2026-06-09: Encoded historical-audit focus areas: verbatim commands, marker-derived sweep bounds, Monitor sandbox/no-background provisioning; net -8.
- 2026-06-09: Added cwd-outside-repo docket no-op guard and `updated_at` reconcile discipline to comm rule 7; count unchanged.
