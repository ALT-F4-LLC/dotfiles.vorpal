# Changelog: sdet

## 2026-07-15

### Summary
Compacted 4 entries (2026-06-30..2026-07-01) into Compacted history per the retention-compaction policy.

### Changes
- Replaced the 4 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (retention-compaction policy)

### Rename
No rename.

## 2026-07-15

### Summary
READ-BEFORE-EDIT pointer's "on every test file or fixture" scoping rephrased file-class-agnostic (was excludable-reading of shared/appended files, the master's dominant failure class); R7 gains the adjacency-gate outranking exception.

### Changes
- AMPLIFY[SUBSTANTIVE]: comm rule 9 rephrased — the gate binds every file; test files/fixtures are the common case, not the scope; pitfalls.md explicitly named as binding identically.
- AMPLIFY[SUBSTANTIVE]: R7 one-liner gains the Read-before-Edit adjacency rule as a second outranking exception.

### Dimensions Evaluated
Disambiguation (multi-reading ×2).

### Rename
No rename.

## 2026-07-15

### Summary
Read-before-Edit rule → pointer to senior-engineer.md's new master (B3); stale-dispatch-check pointer added (R3); vote wire form deduped to Skill(vote) citation (I4).

### Changes
- AMPLIFY[SUBSTANTIVE] (B3): Rule 9 now points to senior-engineer.md §CANONICAL:READ-BEFORE-EDIT (inherits the adjacency/hot-file rules this file's copy lacked).
- AMPLIFY[SUBSTANTIVE] (R3): added stale-dispatch-check pointer on the report-only-verifier ack sentence.
- CULL[COSMETIC] (I4): wire-form paragraph replaced with a citation to Skill(vote)'s Delegation Protocol.

### Dimensions Evaluated
Consolidation & Trimming, Cross-Communication.

### Rename
No rename.

## 2026-07-15

### Summary
Fixed the unexecutable regression-baseline "capture before" instruction (verifier spawns post-impl) by pointing it at `regression_diff.sh`'s existing self-serve `baseline` mode (git-worktree reconstruction), reconciling a conflict between this review's own proposal and senior-engineer's independently-verified finding that `baseline` already closes the gap. Findings: 5 → 1 sub / 0 cos / 1 rej / 1 def / 2 enc

### Changes
- AMPLIFY[SUBSTANTIVE] (I9): step 3(b) now uses `regression_diff.sh baseline before` (self-serve, no cross-role handoff — supersedes this review's own originally-proposed ownership-reassignment text, which the orchestrator rejected after verifying `baseline` mode already exists for exactly this purpose) + `capture after` + `compare`; missing-baseline case now escalates to team-lead as a coverage gap instead of silently trusting the targeted run.
- H7 routed to Coherence (team-lead dispatch-template wording, not this file). H8/D1 already-encoded. I8 (fixture_shape_check.sh) deferred as infra.

### Dimensions Evaluated
Actionability (unexecutable-instruction fix), Capability Growth (missing-baseline escalation), Cross-Communication (capture-before ownership resolved via existing tooling, not a new handoff).

### Rename
No rename.

## 2026-07-13

### Summary
Compacted 5 entries (2026-06-19..2026-06-30) into Compacted history per the retention-compaction policy.

### Changes
- Replaced the 5 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (retention-compaction policy)

### Rename
No rename.

## 2026-07-12

### Summary
Phase 3 disambiguation: 3 fixes — named the `sdet-{ID}` test-infrastructure spawn class (previously only in team-lead.md, causing a plausible wrongful refusal under the "only three verifier names allowed" rule), and closed a vote Fallback path that instructed exactly the bare `docket vote create` the same section warns diverges from doctrine.

### Changes
- AMPLIFY[SUBSTANTIVE]: verifier-name refusal rule scoped explicitly to VERIFICATION dispatches; `sdet-{ID}` test-infrastructure dispatches are named as a distinct, non-refusable class.
- AMPLIFY[SUBSTANTIVE]: Lifecycle's spawn-name enumeration now names the `sdet-{ID}` class alongside the three verifier names, closing the same ambiguity at its second occurrence.
- FIX[SUBSTANTIVE]: vote Fallback now routes through `vote_delegate.sh` (or an explicit `--threshold`) instead of instructing a bare `docket vote create` two sentences after warning it silently defaults to 0.67.

### Dimensions Evaluated
Disambiguation (confusable-name, multi-reading) — two findings share one root cause (an unmarked narrow reading of "canonical spawn names").

### Rename
No rename.

## 2026-07-12

### Summary
Phase 2 coherence: compacted the SHUTDOWN-PROTOCOL-LOCAL block to the master-pointer form (parity with the fleet-wide compaction).

### Changes
- CULL[SUBSTANTIVE]: §Shutdown Handling's 19-line SP-1/SP-2 spell-out reduced to a 3-line master pointer + Precondition.

### Dimensions Evaluated
Cross-Agent Coherence (SHUTDOWN-PROTOCOL block byte-parity across all 7 non-team-lead agents).

### Rename
No rename.

## 2026-07-12

### Summary
evolve-agents self-review: wired two verified-existing unreferenced scripts into workflow, retired single-investigation depth, added teammate-frontmatter-inert note. Net −1067 bytes.

### Changes
- WIRE[SUBSTANTIVE]: §Test Failure Diagnosis step 3 flaky-classification now points to `flaky_confirm.sh` (VERIFIED exists, cited sdet but referenced by zero agents) instead of manual "run 3-5x". [IS-SDET2]
- WIRE[SUBSTANTIVE]: §Using /vote team-mode now calls `vote_delegate.sh` (VERIFIED exists) — fixes the omitted `--threshold` bug (bare `docket vote create` silently defaults 0.67, diverging from the vote skill's Criticality table). [IS-TL4-SDET]
- RETIRE[SUBSTANTIVE]: removed the ~1330-byte "Verifying nested `claude -p` / subprocess-containment claims" paragraph — single-investigation depth bloating every verifier spawn. [IS-SDET3]
- ADD[SUBSTANTIVE]: R2 note that teammate mode does not auto-load `skills:`/`mcpServers:` frontmatter — invoke via explicit `Skill(<name>)`. [DR1]
- ADD[SUBSTANTIVE]: sandbox-recovery LOCAL block gains a verdict gate — rerun with `dangerouslyDisableSandbox` before raising a BLOCK on a possibly-sandbox-induced tool failure. [HA-SDET1]

### Dimensions Evaluated
Completeness/Actionability (script wire-ins), Consolidation (retire single-investigation depth), Spec Alignment (teammate frontmatter envelope), Capability Growth (sandbox verdict gate).

### Rename
No rename.

## 2026-07-11

### Summary
Compacted 3 entries (2026-06-10..2026-06-17) into Compacted history per the retention-compaction policy.

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
evolve-agents cycle (SDLC role-comparison mandate): verification-only pass, no content changes. All three memory-excerpt fixes confirmed wired into workflow text; charter confirmed matching industry SDET; model-tier retained (already the roster's best-diversified role, 54.8%/45.2%).

### Changes
(none — RETAIN across the board; see Dimensions Evaluated)

### Dimensions Evaluated
Role Realism: SDLC research confirms modern consolidated industry SDET fit (test infra + automation + AC verification, manual-QA-below-SDET correctly not adopted, matching the industry trend). Confirmed present: "read the ENTIRE issue body" false-BLOCK fix, background exit-code/$TMPDIR-loss guard, nested `claude -p` config-leak warning. Actionability/Boundary Clarity/Completeness/Consolidation/Spec Alignment: RETAIN.

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

## 2026-07-10

### Summary
Phase 2 coherence follow-up: fixed vote-delegation `message: {object}` bug and flagged wire form.

### Changes
- FIX: `message: {"type": "delegation_request", ...}` rewrote to a plain-text string (`message: "delegation_request (vote) JSON: {...}"`) — this was the ONLY instance fleet-wide where a JSON object was literally assigned to SendMessage's `message:` param (bug-audit FIX-9's clearest illustration). Added the same wire-form clarification as the other 6 files.

### Dimensions Evaluated
Actionability (cross-agent coherence sweep, hard tool-call bug).

### Rename
No rename.

## 2026-07-10

### Summary
Documented the `--findings-json` array-of-STRINGS shape on the vote-cast CLI reference to prevent a recurring BAD-PARAM class. Net +119 bytes. Cleanest-audit agent this cycle (0 stalls, 0 shutdown-rejections) — most sections RETAIN by design.

### Changes
- AMPLIFY: `docket vote cast --findings-json` reference now shows the exact `{"blockers":[…],"concerns":[…],"suggestions":[…]}` string-array shape, not objects. Signal: bug-audit FIX-7 (4 sessions).
- Deferred to Phase 2 (shared/parity-bound, not applied here): the `delegation_request` JSON block duplicated near-verbatim across 7+ agent files, differing only by `--created-by`.

### Dimensions Evaluated
Completeness, Actionability. Consolidation (highest priority) evaluated but RETAIN — the report-only-vs-teammate guard-clause repetition across comm rules correlates with a clean audit, no cited cull signal. Role Realism/Boundary/Capability Growth/Spec Alignment/Rename: RETAIN.

### Rename
No rename.

## 2026-07-01

### Summary
Compacted 2 entries (2026-06-09..2026-06-09) into Compacted history per ADR 0001.

### Changes
- Replaced the 2 oldest date-headed entries beyond the 10-entry keep-window with one-line ledger entries.

### Dimensions Evaluated
History Compaction (ADR 0001)

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
- 2026-06-09: Compacted 38 entries (2026-03-19..2026-05-24) into Compacted history per ADR 0001.
- 2026-06-09: Fable-5 slice — added autonomy calibration + silence-default narration; trimmed redundant re-read clause. Net +2 (341 lines).
- 2026-06-09: Shutdown flip — comm rule 6, Lifecycle, Verifier Composition, §Shutdown Handling → Proactive→Await-lead. Count unchanged (340).
- 2026-06-10: Culled redundant "Idle after verdict" paragraph (4-way restatement); folded TaskStop verb into Drain-before-shutdown. Net -2 (339 lines).
- 2026-06-10: Compacted 2 entries (2026-05-25..2026-05-25) into Compacted history per ADR 0001.
- 2026-06-17: Added sandbox-interaction patterns, never-trust-0-failures set-diff procedure, shared-worktree baseline hazard. Trial: sandbox-patterns / set-diff / worktree-baseline → adopted. Drift: neutral reword of the @ux-designer testability-trigger bullet → adopted.
- 2026-06-19: Trimmed verify-ac-skill-owned duplication from §Verification Workflow (verbatim-command, layer-signals, edge-case battery, verdict ladder). Net -1 (369→368). Drift: skipped (seed-target was a CRITICAL section — unsafe).
- 2026-06-20: Folded two uncovered sandbox/verification lessons into existing blocks + deduped the kubectl/credential restatement. Net 0 (472→472). Drift: disabled (drift=0).
- 2026-06-21: Compacted 9 entries (2026-05-26..2026-06-09) into Compacted history per ADR 0001.
- 2026-06-30: Reconciled DEFAULT lone `verifier` to run as a report-only subagent (mirrors team-lead step 15); added abuse-case consult trigger; chained test-infra claim. Net +1 (476→477).
- 2026-06-30: Folded GitOps selfHeal signal-timing pitfall + EISDIR path-handling guard; deduped TFD FIX-verdict restatement. Net 0 (476→476).
- 2026-06-30: Phase 3 disambiguation polish — sharpened report-only default verifier wording to not blur report-only-vs-teammate distinction.
- 2026-07-01: Phase 1 SDET edits — report-only verifier lifecycle, risk-gated set-diff, TDD override handling, `fix_owner` output. Trial: report-only verifier lifecycle -> applied.
- 2026-07-01: Made lone `verifier` report-only semantics read-only across Docket and tests (no comments/reopens/writes; TDD override scoped to team-lead/interactive spawns).
- 2026-07-01: Phase 3 Disambiguation follow-up — clarified SDET report-only defect routing and normalized SP-1 shutdown report schema.
