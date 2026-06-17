# Changelog: team-lead

## 2026-06-17

### Summary
TRIM self-review (589→587): docket-CLI drift fix, de-duplicated name/background exclusivity into canonical SP-2, removed a fable/opus restatement, Rule 5 staff-count parity. Drift: neutral reword of the Brief-Authoring "Detector" bullet → adopted.

### Changes
- CULL: `docket issue graph --direction up` → `<id> --direction up` (L312); `[id]` is the required first positional per `--help`.
- CULL: collapsed the L166 name/background-exclusivity duplication into a one-line discriminator + pointer to canonical SP-2 (removes a two-site drift hazard).
- CULL: removed the fable/opus sentence restated by the tier preamble; folded "use opus until fable available" into it.
- Rule 5 parity: `@staff-engineer 1-9` → `1-10` (reflects staff's new relay-authority rule).

### Dimensions Evaluated
Actionability (CULL), Consolidation & Trimming (CULL — HIGHEST), Boundary Clarity (RETAIN), others RETAIN.

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
Trial: replace unobservable ">50 turns" advisor R5 trigger with fix-loop-completion event → shipped (operator-approved; next-cycle audit measures). Phase 2 coherence: ux-advisor R5 variant conditioned on spec/implementation mismatch.

### Changes
- R5 per-advisor variants: `advisor` ">50 turns" → "after a TDD secondary-review fix-loop completes" (lockstep staff-engineer.md); `ux-advisor` verdict half conditioned on mismatch (lockstep ux-designer.md).

### Dimensions Evaluated
Coherence pass (cross-file mirrors, byte-parity grep-verified).

### Rename
No rename.

## 2026-06-10

### Summary
Drift: planner lifecycle line re-worded (neutral allele substitution, seed 12471b8f, no-signal index 112/157) → applied. Drift: ux-advisor lifecycle/review-sizing paragraph re-worded (neutral substitution, index 113/157) → applied. Retired two drift-prone historical tallies, replacing frozen counts with behavioral causes. Net 0 physical lines (491).

### Changes
- CULL: "6 wrong-recipient" and "11 misroutes (4 UUIDs, 7 peer names)" stale tallies (Phase 0 retire signal — frozen counts drift each cycle; behavioral rules stand alone).
- NO-OP cited: fable alias present (L132); TeamCreate-before-TaskCreate already correct; Monitor sweep + label-discipline example already encoded; EXPERIMENTAL_AGENT_TEAMS env deliberately omitted (family coherence).

### Dimensions Evaluated
All 8; Consolidation primary; routing-table invariant validated against measured distribution (compliant post-reversion).

### Rename
No rename.

## 2026-06-09

### Summary
Compacted 15 entries (2026-05-07..2026-05-24) into Compacted history per ADR 0001.

### Changes
- Replaced the 15 oldest entries with one-line ledger entries in the terminal Compacted history section (DKT-264)

### Dimensions Evaluated
History Compaction (ADR 0001)

### Rename
No rename.

## 2026-06-09

### Summary
Mythos/Fable-5 optimization: added per-spawn model-routing subsection (sonnet/inherit/fable/opus by cognitive load; never haiku) and a canonical 5-field ephemeral-brief schema; offset by trimming the over-enumerated "don't overthink" banned-list (Fable degrades on exhaustive lists). Net +8 (481→489).

### Changes
- Spawning Templates: new Per-spawn model routing block — per-invocation param overrides frontmatter, no model: pins; security reviewers pinned opus (Fable classifier reroute determinism).
- Common context block: new canonical ephemeral-brief schema naming 5 fields; dispatch-hygiene bullet now its detail.
- Pre-flight overthink directive: collapsed 5-item banned-list to 2 (Fable offset).
- [NO-OP, cited] Reasoning-echo clean; Monitor triggers complete; apply-batch 1:1, post-compaction re-Read, budget-table checks already encoded.

### Dimensions Evaluated
Capability Growth (model routing), Actionability + Consolidation (brief schema), Consolidation & Trimming (overthink trim), reasoning-echo audit, capability-trigger audit.

### Rename
No rename.

## 2026-06-09

### Summary
Phase 2 lead-initiated shutdown flip (operator-decided): ephemerals report then AWAIT team-lead's `shutdown_request`; sweep = team-lead SENDS on delivered report. Added R6 stale-own-reader extension and canonical Relayed-authority sentence (Rule 1). Net +1 (481→482).

### Changes
- Dispatch hygiene, impl template, step 13 sweep ×2, step 16, §Stall shutdown-protocol paragraph, Rule 7, stall-detection guard: self-emit → await-lead (FIX 1-8).
- CANONICAL:PITFALLS lead sentence reworded family-wide, byte-parity preserved (FIX 32).
- R6: lagging-reader STOP-re-reading extension (FIX 33). Rule 1: relayed-authority canonical sentence (FIX 34).

### Dimensions Evaluated
Spec Alignment (agent-teams docs), Coherence (lockstep across 7), Completeness, Boundary Clarity.

### Rename
No rename.

## 2026-06-09

### Summary
Updated the frontmatter skills/mcpServers caveat to cite the officially documented teammate-envelope rule (tools+model honored, body appended). Deduplicated the triple-stated DEGRADED single-reviewer fallback, folding the surviving-sister-verifier clause into step 14 rule 6. Encoded 1:1 edit-to-finding traceability for self-applied batches and aligned the Mechanical-fix shortcut with the default single-reviewer panel. Net -2 (483 → 481).

### Changes
- Replaced "v2.1.117 docs" inference with the documented envelope rule: teammates honor only `tools`+`model`, body is appended, `skills`/`mcpServers` not applied (verified against code.claude.com agent-teams docs).
- Removed the §Stall & Crash Recovery "Double-ephemeral failure" paragraph (duplicate of step 14 rule 6 + Rule 8); preserved "(or surviving sister verifier)" in rule 6.
- Mechanical-fix shortcut: "BOTH reviewers" → "ALL dispatched reviewers" (default panel is 1); added 1:1 self-applied-edit-to-finding traceability (audit: fabricated edit in an 8-edit batch).

### Dimensions Evaluated
Consolidation & Trimming, Spec Alignment, Actionability, Completeness, Role Realism, Boundary Clarity, Capability Growth, Rename.

### Rename
No rename.

## 2026-06-09

### Summary
evolve-skills cycle reference update: code-review skill renamed → code-review-verdict (bundled-skill collision, operator-approved); 7 references updated (banner example, project-registration list, 4 spawn-template invocations, R2 example).

### Changes
- All `Skill(code-review...)` invocations and skill-name mentions → code-review-verdict.

### Verification
- `grep -rnE 'Skill\(code-review[,)]' agents/` returns zero hits.

## 2026-06-09

### Summary
TRIM cycle: brought team-lead.md from 504 (over budget) to 483 by consolidating duplicated prose. No rule semantics changed; sibling files reference the R-rule bodies via pointer, not verbatim copy, so the R-rule trims orphan nothing (verified family-wide in Phase 2). Net −21.

### Changes
- Phase 1: collapsed the two async-shutdown paragraphs (shutdown-protocol + post-final-report-idle) into one.
- Phase 1: deduped "return verdict / never route directly" out of both review templates into the common context block (Rule 1 already mandates it).
- Phase 2: compacted R1 batched-calls+escape-hatch, R5 self-summary body (7-bullet block → 3 bullets), and R6 banned-phrase bullet — semantics preserved, padding removed.
- Confirmed already-mitigated (no design change): the artifacts.vorpal shutdown-loop lesson; AskUserQuestion usage is correct (team-lead runs as MAIN thread).

### Dimensions Evaluated
Consolidation & Trimming (primary — under 500), Role Realism, Boundary Clarity, Spec Alignment, Completeness, Capability Growth, Rename

### Rename
No rename.

## 2026-06-05

### Summary
Phase 2 coherence: added a visual-deliverable render-verification pointer to the step-13 spot-check, deferring visual surfaces to ux-advisor (coherent with ux-designer.md's new render-to-image gate) rather than duplicating render-to-image in team-lead; offset by a within-line Phantom-deletion trim. Net 0; 481 lines.

### Changes
- Step 13 spot-check: added "Visual deliverables are render-verified, not Read-verified → defer to ux-advisor design-QA" so a source-diff-green pass does not approve a slide/static-export/rendered-UI surface. Offset by compacting the Phantom-deletion sub-case wording (behavioral content retained).

### Dimensions Evaluated
ux↔team-lead Coherence (PRIMARY) · Consolidation & Trimming (net-zero offset, held 481/500) · No-duplication (routes to ux-advisor, does not re-implement render-to-image).

### Rename
No rename.

## 2026-06-05

### Summary
Generalized §Mid-cycle redirect-race rule into the canonical one-authoritative-message rule (net +0; 481 lines). The historical audit's most-repeated team-lead lesson ("one authoritative message per teammate, then WAIT; decide once; never flip-flop a low-stakes call mid-flight") was only partially encoded — only the AskUserQuestion-override instance existed; the general async-ordering principle was absent here and in all 6 peer files.

### Changes
- §Mid-cycle redirect-race rule: prepended the general "one authoritative message per teammate per wait-window, then WAIT; do not flip-flop a low-stakes call mid-flight (a superseding message crosses the prior, teammate replies to STALE)" principle; demoted the AskUserQuestion-override case to "the redirect instance". Heading substring kept (L121 back-reference).

### Dimensions Evaluated
Capability Growth & Cross-Communication (PRIMARY) · Consolidation & Trimming (net +0; declined near-ceiling additions) · Completeness (docs-researcher recs #1/#3/#5/#6 confirmed already-applied NO-OPs; #2/#7 flagged cross-cutting for Phase 2).

### Rename
No rename.

## 2026-05-30

### Summary
Phase 2 coherence: (1) removed the dangling `§6 continuity preamble` pointer (6× — L128/154/168/287/313/344); team-lead is the file that DEFINES the preamble (§Teammate Stall & Crash Recovery, Fix-loop re-spawn), so `§6` was pure noise. (2) Corrected the Rule 5 numbering table: `@staff-engineer 1-8` → `1-9` (staff carries a 9th Advisor-topology rule; the table was the stale side — a wrong count risks a future evolve cycle deleting a real rule). Within-line; 481 lines.

### Changes
- `§6 continuity preamble` → `continuity preamble` (×6).
- Rule 5: `@staff-engineer 1-8` → `1-9`, noting the 9th Advisor-topology rule (recommendations route through team-lead).

### Dimensions Evaluated
Cross-Agent Coherence (PRIMARY — self-referential dangling ptr + table-vs-reality drift) · Rule-numbering convention accuracy.

### Rename
No rename.

## 2026-05-30

### Summary
Three within-line correctness fixes (net 0; 481 lines). (1) Healed the dangling `§4.3 reconciliation rules` pointer (2× — step 15 + Rule 8; no §4.3 heading exists, rules live in step 14) → "step 14 reconciliation rules", and corrected the wrong "(1-8)" count → "(1-6)" (step 14 has exactly 6 rules). (2+3) Reworded two phrasings that read like fabricated docket subcommands (Phase 0 docket-audit items) — "docket issue stuck `in-progress`" → noun phrase, and resume-preamble "check docket issue state" → "run `docket issue show <id>`". No speculative consolidation near the 500 ceiling.

### Changes
- Step 15 + Rule 8: `§4.3 reconciliation rules` → `step 14 reconciliation rules`; `(1-8)` → `(1-6)`.
- §Stall & Crash Recovery detection bullet (d): "docket issue stuck `in-progress`" → "a docket issue sitting in `in-progress`".
- §Stall & Crash Recovery resume preamble: "check docket issue state + comments" → "run `docket issue show <id>` + comment list".

### Dimensions Evaluated
Spec Alignment / Cross-Agent Coherence (PRIMARY — 2 dangling pointers + 1 wrong count) · Actionability (2 Docket-CLI clarity rewordings) · Consolidation & Trimming (declined near-ceiling churn)

### Rename
No rename.

## 2026-05-30 (Phase 2 — coherence)

### Summary
Completed the Rule 2 canonical role-prefix example registry. The visibility-contract examples listed only `[LEAD→…]`/`[PM→…]`/`[SE→…]`, but the fleet also uses `[STAFF→…]`, `[SEC→…]`, `[SDET→…]`, `[UX→…]` (all valid `[{ROLE}→@{recipient}]` instantiations). Added the four missing tokens so Rule 2 is authoritative for all 7 roles. Within-line; 481 lines.

### Changes
- Rule 2 (Visibility contract): appended `[STAFF→…]`, `[SEC→…]`, `[SDET→…]`, `[UX→…]` to the canonical-prefix example list.

### Dimensions Evaluated
Spec Alignment / Cross-Agent Coherence (Rule 2 prefix registry now complete for all 7 roles)

### Rename
No rename.

## 2026-05-30

### Summary
Two changes, net -2 (483→481), trim-leaning near the 500 ceiling. (1) Promoted the recurring `.env*` phantom-deletion pitfall (RECURS across agentic-services + weft memory) into the EXISTING step-13 sandbox-masked-diff caveat — deny-listed paths surface as `Operation not permitted` / phantom-DELETED, `dangerouslyDisableSandbox` does not lift it, treat as masked state. (2) Consolidated the standalone "Trust state-divergence rejections" paragraph into the pre-shutdown gate step 3 (which it restated), keeping only the non-redundant "don't override by re-issuing the same reasoning" directive. Docs-research recs already satisfied.

### Changes
- Step 13 spot-check sandbox-masked caveat: appended phantom-deletion sub-case (`.env*` → `Operation not permitted` → masked state, never a real deletion).
- Pre-shutdown gate step 3: folded in the "trust the rejection / don't re-issue same reasoning" directive; deleted the standalone "Trust state-divergence rejections." paragraph (-2 lines).

### Dimensions Evaluated
Consolidation & Trimming (PRIMARY — net-negative achieved) · Capability Growth (cross-repo recurring memory promoted into an existing rule)

### Rename
No rename.

## 2026-05-26 (Phase 2 coherence)

### Summary
Two coherence fixes from Phase 2 cross-agent review. (1) §Spawning Templates @ux-designer line said "doubled per Rule 8" — but Rule 8 DEFAULTS to single, opts up to doubled. ux-designer.md Responsibility 5 had it right; team-lead Spawning Template was the outlier. Rewritten to match (default single ux-advisor via SendMessage; opt up to doubled). (2) Added one-line frontmatter `skills:`/`mcpServers:` caveat to §Spawning Templates Common context-block — spawned-teammate mode IGNORES frontmatter `skills:` (only `--agent` main-thread honors them per v2.1.117 docs). Single fleet-wide note avoids 6x duplication across agents that declare skills.

### Changes
- §Spawning Templates @ux-designer (L161): "doubled per Rule 8" → "default single `ux-advisor` via SendMessage per Rule 8; opt up to doubled per Rule 8 conditions".
- §Spawning Templates Common context-block: new bullet — frontmatter `skills:`/`mcpServers:` caveat with the 9 team-relied-upon skills listed.

### Dimensions Evaluated
Spec Alignment (PRIMARY — Spawning Template now matches Rule 8) · Boundary Clarity (frontmatter caveat prevents future silent-fail when adding skills)

### Rename
No rename.

## 2026-05-26

### Summary
Deleted 2 redundant reconciliation rules in step 14 (rule 3 "Approve+Block→Block wins" restated rule 1; rule 8 "Eager parallel dispatch" restated section intro). Renumbered remaining 4-7 → 3-6; updated 3 cross-references at lines 253 (intro), 319 (Stall & Crash Recovery), 353 (Rule 8). Added sandbox-masked-diff caveat to step 13 spot-check (ports CC-1 from cross-project pitfalls.md into the rule body). Compressed Brief-Authoring Discipline (5→4 lines via Detector inline) and Security-Sensitive flag enumeration (deduped trigger list). Net: -3 lines (480 → 477).

### Changes
- Step 14 reconciliation rules: deleted rule 3 + rule 8 (-2 lines); renumbered 4-7 → 3-6.
- Cross-references updated at 3 sites (intro at line 253, Stall & Crash Recovery at 319, Rule 8 at 353) — "rule 8" / "rule 7" stripped or renumbered to "rule 6".
- Step 13 spot-check `git diff --stat` bullet: appended "Sandbox-masked diff caveat" — retry with `dangerouslyDisableSandbox=true` when teammate references files absent from your diff.
- Pattern Decision Tree step 6: Security-Sensitive trigger enumeration deduplicated (was stated twice).
- @senior-engineer Brief-Authoring Discipline: folded Detector paragraph into bulleted list (-1 line).

### Dimensions Evaluated
Consolidation & Trimming (PRIMARY — net-negative achieved despite ceiling pressure) · Spec Alignment (cross-project pitfalls.md item ported; 3 stale cross-refs healed)

### Rename
No rename.

## 2026-05-26 (Phase 2 — strip 12 dangling docs/tdd/* citations)

### Summary
Stripped all 12 dangling citations to `docs/tdd/reviewer-doubling-lifecycle.md` and `docs/tdd/agents-token-optimization.md` (files do not exist in this repo per Phase 0 verification). Each citation replaced with intra-team-lead anchor pointing at the inline rule it claimed to reference (Rule 7, Rule 8, step 14 reconciliation rules 1-8, §Teammate Stall & Crash Recovery, §Runtime Discipline).

### Changes
- 12 strip-only edits across L188, L206, L240, L242, L244, L256, L274, L282, L306, L331, L334, L340, L346.
- Common patterns: "TDD §4.3" → "step 14 rules" / "reconciliation rule N in step 14"; "TDD §4.4" → "Rule 7"; "TDD §4.2" → "Rule 8"; "§6 continuity preamble" → "continuity preamble (per Stall & Crash Recovery)"; "§4.5 applicability matrix" → "this section is the source of truth".

### Dimensions Evaluated
Spec Alignment (PRIMARY — No Guessing violation closed) · Boundary Clarity (intra-file anchors are unambiguous)

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
