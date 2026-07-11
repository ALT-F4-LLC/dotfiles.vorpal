# Changelog: team-lead

## 2026-07-11

### Summary
Compacted 3 entries (2026-06-17..2026-06-20) into Compacted history per the retention-compaction policy.

### Changes
- Replaced the 3 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (retention-compaction policy)

### Rename
No rename.

## 2026-07-11

### Summary
Phase 3 disambiguation fix: the new `docs-author` dispatch-table row didn't disambiguate against the confusably-named `docs-researcher` bronze role. Net +150 bytes.

### Changes
- FIX[SUBSTANTIVE]: added a "NOT doc RETRIEVAL → `docs-researcher`" clause to the `docs-author` Per-Role Dispatch Table row — both are `docs-*`/bronze and share the "documentation" trigger surface, but `docs-researcher` has no table row of its own (lives inline elsewhere), so the author-vs-retrieve discriminator needed to live in-row.

### Dimensions Evaluated
Boundary Clarity (confusable-name, Phase 3 disambiguation). SP-1/SP-1b adjacency, the 3-site effort-lever correction, and the DE/PM naming-note asymmetry were all checked and cleared as unambiguous.

### Rename
No rename.

## 2026-07-11

### Summary
evolve-agents cycle (SDLC role-comparison mandate): TRIM cycle grounded in SDLC role research + bug/docs audits. Net -39 bytes (8 adds paid by 12 prose consolidations).

### Changes
- FIX[SUBSTANTIVE]: effort third-lever correction at 3 sites (§Effort intro, TEAMMATE bullet, Per-model brief deltas) — a skill's own `effort:` frontmatter overrides session effort even on a teammate running that skill; the prior text claimed this lever didn't exist.
- ADD[SUBSTANTIVE] SP-1b: outgoing `shutdown_request` construction rule — omit `reason` (never `null`), no top-level `type`/`recipient` (bug audit, 21 sessions).
- FIX[SUBSTANTIVE] SP-2 + line-209 Name/background exclusivity: `name=` is the sole teammate/subagent discriminator; subagents run background-by-default since v2.1.198 (docs research).
- ADD[SUBSTANTIVE]: `docs-author` ephemeral dispatch row (@senior-engineer, bronze) — the one genuine SDLC functional gap identified this cycle (user-facing docs); ephemeral row on an existing agent, not a Speciation event.
- ADD[SUBSTANTIVE]: report-only subagents cannot invoke AskUserQuestion (UI-dependent) — folded into the Distribution-Mechanism Gate caveat.
- CULL[COSMETIC] ×12: prose consolidations (anti-staleness rule, Gold-first failure-mode, stale-pair shutdown passage, named-mechanism fidelity, ground-truth consult briefs, dispatch hygiene, Rule-8 cargo-audit tail, git-verification caveats a/b, Durable Fable caveat, promised-gate delivery check, cycle-bloat surfacing, V/I/SR rationale).

### Dimensions Evaluated
Actionability (effort correction + SP-1b), Spec Alignment (SP-2 v2.1.198), Completeness (docs-author SDLC gap), Boundary Clarity (AskUserQuestion note), Consolidation & Trimming (12 trims, TRIM-mode compliant). Role Realism: SDLC research confirms the coordination/technical-direction Tech-Lead split (team-lead + advisor) is deliberate, not a gap. Rename: RETAIN.

### Rename
No rename.

## 2026-07-10

### Summary
Compacted 3 entries (2026-06-10..2026-06-10) into Compacted history per the retention-compaction policy.

### Changes
- Replaced the 3 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (retention-compaction policy)

### Rename
No rename.

## 2026-07-10

### Summary
Phase 3 disambiguation follow-up: unified the `V/I/SR` pattern abbreviation (was spelled two ways within the file — prose used "V/I/SR", the dispatch-ledger enum used "VISR" with no gloss linking them).

### Changes
- DISAMBIG: dispatch-ledger `pattern={...|VISR}` token changed to `pattern={...|V/I/SR}` to match the abbreviation used everywhere else in the file.

### Dimensions Evaluated
Boundary Clarity (consistent terminology).

### Rename
No rename.

## 2026-07-10

### Summary
TRIM-mode cycle. Applied Rule-8 lettering/ledger-grammar fix, 3 BAD-PARAM bug fixes (FIX-9 vote-delegation plain-text payload, FIX-13 Agent model= rejects [1m], FIX-4 threshold fraction), a brief-block Pre-flight fast path, and a mechanical pre-respawn liveness check hardening the convergent 3-auditor signal (advisor triple-spawn recurrence). Net +387 this pass; the largest cited trim (-513, acceptance-panel hoist to a shared master) is CONTINGENT on creating that master and is deferred to Phase 2 since it touches 4 files atomically.

### Changes
- FIX: Rule 8 opt-up triggers renumbered (c)/(d)/(e)→(a)/(b)/(c); dispatch-ledger grammar and cross-refs updated to match (0 net bytes, correctness-only).
- AMPLIFY: vote-delegation JSON clarified as a plain-text string payload, not the structured SendMessage `message` object (bug-audit FIX-9, 16 sessions — largest SendMessage finding this cycle).
- AMPLIFY: `Agent()` `model=` clarified to take the bare alias only — `[1m]` suffix is REJECTED by the tool enum (bug-audit FIX-13).
- AMPLIFY: `--threshold` clarified as a fraction 0.0-1.0, not a percentage (bug-audit FIX-4, 4 sessions).
- AMPLIFY: Pre-flight step 1 gains a brief-block fast path — consumes the `brief` skill's block instead of re-verifying from scratch (innovation-scan: producer-with-no-consumer gap).
- AMPLIFY: Liveness-Confirmation Gate decision-ladder step (1) now forces a `TaskList`+`docket -a @<role> -s in-progress` tool call before any respawn — convergent signal from 3 independent Phase-0 auditors (historical: 2 shutdown-rejections this window correctly caught team-lead's own stale state; repetition: advisor/advisor-2/advisor-3 recurred AFTER being memory-logged; model-routing: DE's outlier idle/error density traces to the same duplicate-concurrency pattern) that the prose gate, though comprehensive, was not firing under pressure.
- CULL: line-235 teammate/subagent fallback explanation consolidated (-290); line-237 duplicate Fable reasoning-echo caveat removed, already stated at line 211 (-123).
- DEFERRED to Phase 2 (contingent, multi-file): step-6 merged-acceptance-panel composition hoisted to a new CANONICAL:ACCEPTANCE-PANEL-LOCAL pointer once `team-doctrine/references/acceptance-panel.md` exists — same content is duplicated in staff-engineer.md, security-engineer.md, and distinguished-engineer.md.

### Dimensions Evaluated
Actionability (3 bug fixes + brief fast path), Boundary Clarity (liveness-gate forcing), Consolidation & Trimming (2 applied trims + 1 deferred large trim). Role Realism/Completeness/Spec Alignment/Rename: RETAIN.

### Rename
No rename.

## 2026-07-01

### Summary
Compacted 4 entries (2026-06-09..2026-06-09) into Compacted history per ADR 0001.

### Changes
- Replaced the four oldest committed date-headed entries outside the 10-entry keep-window with one-line ledger entries.

### Dimensions Evaluated
History Compaction (ADR 0001)

### Rename
No rename.

## 2026-07-01

### Summary
Phase 3 Disambiguation follow-up: removed direct verifier peer routing and normalized shutdown report fields.

### Changes
- DISAMBIG: rewrote SDET verifier context so team-lead owns fix-loop and advisor routing; lone verifier reports only to team-lead.
- DISAMBIG: normalized master SP-1 final-report schema with explicit `safe_to_close` close readiness.

### Dimensions Evaluated
Phase 3 Disambiguation; verifier routing; shutdown schema.

### Rename
No rename.

## 2026-07-01

### Summary
Phase 2 TRIM correction: removed two spacer lines from `team-lead.md` after coherence left it over budget.

### Changes
- CULL: removed blank lines around `Plan-approval mode` in the @senior-engineer section; behavior unchanged.

### Dimensions Evaluated
Consolidation & Trimming; Phase 2 coherence follow-up.

### Rename
No rename.

## 2026-07-01

### Summary
Phase 2 coherence follow-up: wired plan-approval dispatch, supply-chain evidence packet routing, and `planner-fix-{N}` lifecycle wording.

### Changes
- FIX: `mode=plan` dispatch now routes senior implementation PLANs to advisor/security/UX receivers and relays `plan_approval_response`.
- FIX: security review dispatch now carries or requires a security-owned `Cargo.lock` evidence packet for supply-chain verdicts.
- FIX: Rule 7 ephemeral examples include `planner-fix-{N}`.

### Dimensions Evaluated
Lifecycle, PA dispatch, security review routing, Rule 7 consistency.

### Rename
No rename.

## 2026-07-01

### Summary
Trial: team-lead TRIM and report-only close gate -> applied. Net trim targeted the over-budget team-lead file.

### Changes
- CULL: compacted Alignment/Optimization and Orchestration Patterns into a routing matrix.
- CULL: replaced volatile model metrics with tier policy while keeping intentional model/reasoning routing.
- AMPLIFY: normalized lone verifier as report-only; added minimal close gate, file-list checks, and draft-TDD override handoff.
- CULL: collapsed Rule 8 to step 14/15 sizing and reconciliation pointers.

### Dimensions Evaluated
Consolidation, Spec Alignment, Lifecycle/Verification close semantics, Docket executability.

### Rename
No rename.

## 2026-06-30

### Summary
Phase 3 disambiguation: clarified the `verifier` name collision, distinguished the PA impl plan from the PM phase plan, and made advisor TDD-conformance plan-routing explicit. Net 0.

### Changes
- DISAMBIG (confusable-name): step 15 "ephemeral-teammate `verifier`" → "paired ephemeral-teammate verifiers (`verifier-criteria`/`verifier-integration`)" — the lone `verifier` is report-only, never a teammate.
- DISAMBIG (term overload): step 11 "read-only plan" → "read-only implementation plan (distinct from the PM phase/decomposition plan the operator approves at step 10)".
- DISAMBIG (overlapping-ownership): step 11 now routes TDD-bearing plans to `advisor` for TDD-conformance review (aligns staff Impl-plan review), then additionally to security-advisor/ux-advisor for security/spec'd surfaces.

### Dimensions Evaluated
Phase 3 disambiguation (confusable-name, term-overload, overlapping-ownership).

### Rename
No rename.

## 2026-06-30

### Summary
Phase 2 cross-cutting (operator-approved). Adopted the PA plan-approval overlay for risky dispatches; defaulted the lone step-15 verifier to a report-only subagent; added a shared pre-computed reviewer brief (Rule 8) + parallel `planner-{slug}` Large-Task decomposition; aligned the senior-template claim wording to the chained one-call. Net +2 (661→663). Trial: PA plan-approval overlay adopted family-wide → applied (measure next cycle).

### Changes
- AMPLIFY: step 11 Plan-approval (PA) overlay — dispatch @senior-engineer `mode="plan"`, team-lead emits `plan_approval_response`, route security/spec'd plans to security-advisor/ux-advisor. Signal: Phase 0 innovation (PA = top unused lever).
- AMPLIFY: step 15 lone verifier → report-only subagent per Distribution-Mechanism Gate. Signal: Phase 0 innovation + internal incoherence.
- AMPLIFY: Rule 8 shared pre-computed brief (`git diff --stat` + spec excerpts + `cargo audit` keyed to Cargo.lock hash). Signal: Phase 0 efficiency (redundant re-runs across panels).
- AMPLIFY: Large-Task parallel `planner-{slug}` decomposition counterpart to PM's surfaced option.

### Dimensions Evaluated
6 (Capability Growth) AMPLIFY×3 + coherence alignment (claim wording). 1/2/3/4/5/7/8 RETAIN.

### Rename
No rename.

## 2026-06-30

### Summary
TRIM cycle, within-file safe whole-line trims (-6) + EI effort correction (net 0). Net -6 (667→661). PA overlay + verifier-as-report-only deferred to Phase 2 (operator-gated, cross-cutting). PRIMARY budget lever — relocating the Truth-First-Debugging MASTER out of the debugging-forbidden orchestrator — deferred to an evolve-coherence/ADR follow-up (deleting the master with no replacement is unsafe within one agents cycle); file stays >500 this cycle.

### Changes
- CULL: removed restating "The tell" line (dup of FORBIDDEN bullet + Per-turn self-audit). Signal: Consolidation; low historical violation rate (1 correction/72 sessions).
- CULL: collapsed two Alignment example bullets into their blockquote (kept the "question exists" nuance). Signal: Consolidation (restated the preceding blockquote).
- CULL: folded "Subagent-branch availability" paragraph into the Distribution-Mechanism Gate item 2. Signal: Consolidation.
- AMPLIFY (Spec Alignment, EI): corrected stale effort claim — teammates DO inherit the lead's SESSION effort (v2.1.186); only the definition's `effort:` FRONTMATTER is unhonored on the teammate path.
- Deferred: PA plan-approval overlay + lone-verifier→report-only-subagent → Phase 2 (operator-gated). TFD-MASTER relocation → evolve-coherence/ADR.

### Dimensions Evaluated
All 8. 5 (Consolidation) CULL×3 (structural relocation deferred). 7 (Spec Alignment) AMPLIFY (EI). 6 (Capability) → PA + verifier deferred to Phase 2. 1/2/3/4/8 RETAIN.

### Rename
No rename.

## 2026-06-20

### Summary
Phase-2 coherence: closed a GO-gate producer/consumer deadlock + a within-file shutdown-sweep de-restatement. Net 0 lines (still 637 — budget overage routed to a structural-refactor ADR). Drift: disabled (drift=0).

### Changes
- AMPLIFY (coherence): the routine single-reviewer dispatch (step 14) now MUST carry the `GO — review NOW` trigger — closes a deadlock where staff-engineer.md's Moving-tree gate hard-gates EVERY verdict on a GO the default path never sent.
- CULL (redundancy): step-13 line 314 de-duplicated against the step-13 Shutdown-sweep bullet (316), which owns the still-alive sweep in full.

### Dimensions Evaluated
Producer/consumer gate consistency (FIX) · within-file redundancy (FIX) · CANONICAL dedup (measured — none net-reduce, NONE applied) · line budget (remains 137 over — structural-refactor ADR recommended).

### Rename
No rename.

## 2026-06-21

### Summary
Compacted 11 entries (2026-05-26..2026-06-09) into Compacted history per ADR 0001.

### Changes
- Replaced the 11 oldest committed date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (ADR 0001)

### Rename
No rename.

## Compacted history

Entries below were compacted per ADR 0001; full text in git history (see the compaction entry's date).

- 2026-05-07: First evolve cycle for team-lead since extraction from /dev skill (cf9a8d0). Added fleet-standard `[LEAD→@agent]` operator-visibility prefix to…
- 2026-05-07: Fixed invalid `docket issue graph --direction blocks` flag value (verified at runtime). Added Monitor tool guidance for long-running phases and…
- 2026-05-08: Fixed `TaskCreate` API misuse in Team Setup (no `depends_on` parameter exists; dependencies are set via `TaskUpdate` `addBlockedBy`). Removed…
- 2026-05-08: Phase 2 coherence: broadened Rule 1 hub-and-spoke description to match fleet reality — the prior 4-pair allowlist contradicted documented peer…
- 2026-05-08: Phase 3 operating discipline: added Persistent memory section to capture solutions to non-obvious orchestration problems.
- 2026-05-09: Trimmed redundant spawning-template scaffolding (hoisted common Agent() / Verified goal / `<user_request>` boilerplate into a single preamble)…
- 2026-05-13: Added **Direct Task** orchestration pattern (single @senior-engineer, no PM/review/team) addressing operator pain — documentation overhead…
- 2026-05-13: Phase 2 coherence: renamed UX persistent teammate spawn to canonical "ux-advisor" (aligns with advisor/security-advisor pattern); annotated…
- 2026-05-16: Added orchestrator-side controls for the communication-discipline rules: context-saturation handoff protocol (rule 3), claim-before-work and…
- 2026-05-16: Phase 2 coherence: align @senior-engineer Spawning Template with Rule 7 (claim-first ordering).
- 2026-05-17: Consolidation pass: -28 lines target by collapsing redundant guidance that already lives in Security Track, step 13 spot-check protocol, and…
- 2026-05-17: Phase 2 coherence: Documented intentional execution-vs-doc Communication Discipline rule-numbering asymmetry as Rule 5.
- 2026-05-19: Tightened orchestrator contracts around the vote-skill handoff, tool envelope, and operator-visibility convention based on historical audit…
- 2026-05-19: P1 brief-authoring + lifecycle hygiene + memory activation: Encoded the operator's P1 lesson (DKT-6 brief-authoring contradiction) as a…
- 2026-05-24: Encoded DKT-37 / DKT-40 operator-prescribed resolution (independently corroborated by historical audit: 9 state-divergence shutdown-rejections…
- 2026-05-25: Encoded 5 active memory pitfalls (solution-dimension HARD GATE, ls-before-dispatch, budget-table per-row arithmetic, mechanical-fix shortcut + cycle-bloat
- 2026-05-25: Single coherence fix: dropped dead "(P7a)" cross-reference from R7 canonical body (fleet-wide cleanup; no agent canonically labels its Read rule as P7a).
- 2026-05-26: Encoded proactive shutdown-coordination per operator directive. New end-of-turn shutdown sweep step (probes `docket issue list -a @<role> -s in-progress
- 2026-05-26: Phase 2 — stripped 12 dangling docs/tdd/* citations; redirected to intra-team-lead anchors (Rule 7/8, step 14 rules, Stall & Crash Recovery, Runtime Discipline).
- 2026-05-26: Step 14 reconciliation rules: deleted rule 3 + rule 8, renumbered 4-7→3-6; sandbox-masked-diff caveat; Brief-Authoring Discipline inline; trigger dedup. Net -3.
- 2026-05-26: Phase 2 coherence — ux-designer Spawning Template corrected to default-single; frontmatter skills/mcpServers caveat added to Common context-block.
- 2026-05-30: `.env*` phantom-deletion pitfall promoted to step 13; "Trust state-divergence rejections" folded into pre-shutdown gate step 3. Net -2.
- 2026-05-30: Phase 2 coherence — Rule 2 prefix registry completed with STAFF/SEC/SDET/UX tokens. Within-line.
- 2026-05-30: Three correctness fixes: §4.3→step 14 reconciliation rules; (1-8)→(1-6); two fabricated docket-subcommand phrasings reworded. Net 0.
- 2026-05-30: Phase 2 coherence — dangling `§6 continuity preamble` ×6 removed; Rule 5 staff count 1-8→1-9 corrected. Within-line.
- 2026-06-05: One-authoritative-message rule generalized; AskUserQuestion-override demoted to the redirect instance. Net 0.
- 2026-06-05: Phase 2 coherence — visual-deliverable render-verification pointer added to step-13 spot-check; Phantom-deletion wording trimmed. Net 0.
- 2026-06-09: TRIM cycle: 504→483 by consolidating duplicated prose (async-shutdown, return-verdict, R1/R5/R6). Net -21.
- 2026-06-09: evolve-skills reference update: code-review → code-review-verdict; 7 references updated.
- 2026-06-09: Compacted 15 oldest entries (2026-05-07..2026-05-24) into ledger entries per ADR 0001 (DKT-264).
- 2026-06-09: Added per-spawn model routing and canonical 5-field ephemeral brief schema; trimmed over-enumerated guidance. Net +8.
- 2026-06-09: Flipped ephemeral shutdown to report then await team-lead close; added R6 stale-reader and Rule 1 relayed-authority text. Net +1.
- 2026-06-09: Corrected teammate-envelope caveat, deduped DEGRADED fallback, and added edit-to-finding traceability. Net -2.
- 2026-06-10: Compacted 3 entries (2026-05-25..2026-05-26) into Compacted history per ADR 0001.
- 2026-06-10: R5 advisor trigger (">50 turns") replaced with fix-loop-completion event; ux-advisor R5 variant conditioned on spec/implementation mismatch. | Trial: replace unobservable ">50 turns" advisor R5 trigger with fix-loop-completion event → shipped (operator-approved; next-cycle audit measures).
- 2026-06-10: Retired two drift-prone historical routing-error tallies (6 wrong-recipient; 11 misroutes) in favor of behavioral-rule causes. Net 0 (491 lines). | Drift: planner lifecycle line re-worded (neutral allele substitution, seed 12471b8f, no-signal index 112/157) → applied. | Drift: ux-advisor lifecycle/review-sizing paragraph re-worded (neutral substitution, index 113/157) → applied.
- 2026-06-17: TRIM self-review (589→587) — docket-CLI drift fix, name/background exclusivity deduped into SP-2, fable/opus restatement removed, Rule 5 parity. Drift: neutral reword of the Brief-Authoring "Detector" bullet → adopted.
- 2026-06-19: TRIM self-review (589→588) — merged opus tier bullets, compacted step-16 cleanup prose, softened fable wording to "opus is the standing tier". Drift: skipped (TRIM net-negative mandate — any neutral add violates it).
- 2026-06-20: Fable-5 accuracy correction (worldwide suspension) + word-level consolidations + two gap-fills; net 0 (637 lines, TRIM goal unmet). Drift: disabled (drift=0).
