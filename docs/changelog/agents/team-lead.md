# Changelog: team-lead

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

## 2026-05-26 (Phase 1 — proactive shutdown sweep + claim ritual + anti-inversion)

### Summary
Encoded proactive shutdown-coordination per operator directive. New end-of-turn shutdown sweep step (probes `docket issue list -a @<role> -s in-progress --json`); two-step claim ritual in @senior-engineer Requirements; async-shutdown-as-FINAL-tool-call in common Dispatch hygiene; stronger anti-inversion rule in step 16 grounded in audit's 11 misroutes. R5 per-advisor variants collapsed -5 lines to offset +3 substantive additions. Net -3 lines (470 → 467).

### Changes
- Step 13 area: NEW "Shutdown sweep" sub-bullet — proactive monitoring via `docket issue list -a @<role> -s in-progress --json` (every turn during steps 11-16, NOT gated by spot-check predicate). Only CLOSED-set advisors may idle.
- @senior-engineer Requirements (line 175): two-step claim ritual `docket issue edit -a @senior-engineer` + `docket issue move in-progress` (enables the sweep probe); explicit `shutdown_request` as FINAL tool call this turn after close.
- Dispatch hygiene bullet (common scaffolding): added explicit FINAL-tool-call shutdown requirement for ephemerals; CLOSED-set exempt per Rule 7.
- Step 16 Shutdown direction: strengthened — team-lead MUST NOT reply with `shutdown_response`, MUST NOT address raw agent-IDs, MUST NOT address peer ephemeral names. Historical context (11 misroutes: 4 UUIDs, 7 peer names) cited; silence is correct response to shutdown approval.
- R5 per-advisor variants (lines 437-441): 5-line bulleted block collapsed to 1 inline line preserving all three triggers.

### Dimensions Evaluated
Actionability (PRIMARY — proactive sweep, FINAL-tool-call, anti-inversion) · Boundary Clarity (shutdown direction) · Completeness (proactive monitoring step) · Capability Growth (two-step claim ritual + liveness probe) · Consolidation & Trimming (R5 collapse offsets net additions)

### Rename
No rename.

## 2026-05-25 (Phase 2 coherence — P7a drop)

### Summary
Single coherence fix: dropped dead "(P7a)" cross-reference from R7 canonical body (fleet-wide cleanup; no agent canonically labels its Read rule as P7a).

### Changes
- §R7 exception clause: dropped "(P7a)" suffix

### Dimensions Evaluated
Actionability (dead-reference removal)

### Rename
No rename.

## 2026-05-25 (Phase 1 self-review — 5 memory pitfalls + CRITICAL shutdown inversion bug)

### Summary
Encoded 5 active memory pitfalls (solution-dimension HARD GATE, ls-before-dispatch, budget-table per-row arithmetic, mechanical-fix shortcut + cycle-bloat surfacing) and closed the CRITICAL shutdown_response inversion bug from session 4785313c. Consolidated stale coordination-note bullet (already encoded in Rule 8) to offset new dispatch-hygiene bullet. Net +4 lines (464 → 468).

### Changes
- Pre-flight step 1 HARD GATE: AskUserQuestion now spans goal axes, out-of-scope surfaces, AND solution dimensions (how-to-cut). Closes memory pitfall #1 (dev-agents-token-opt).
- Spawning Templates Common context-block: replaced stale coordination-note bullet with consolidated Dispatch hygiene bullet — `ls -d` file-target verification + ephemeral first-tool-call/final-report mandate + review/verify `Mandatory verification commands` subsection requirement. Closes memory pitfalls #2, #4 + audit-suggested ephemeral delivery discipline.
- Step 13 spot-check: added budget-table per-row arithmetic sub-bullet. Closes memory pitfall #2.
- Step 14 Review-fix loop: added Mechanical-fix shortcut (BOTH reviewers mechanical + <5 LOC → team-lead self-applies, skip re-doubled-review) + Cycle bloat surfacing (>40 implementation turns → AskUserQuestion offering accelerated-wrap). Closes memory pitfall #4.
- Step 16 wrap-up: added Shutdown direction bullet — team-lead is sender of shutdown_request / receiver of shutdown_response; emits shutdown_response ONLY to operator. Closes CRITICAL audit finding from session 4785313c (dev-weft-auth).

### Dimensions Evaluated
Actionability (PRIMARY — 5 memory pitfalls + critical shutdown bug encoded) · Boundary Clarity (shutdown direction) · Completeness (solution-dimension axis) · Capability Growth (mechanical-fix + cycle-bloat shortcuts) · Consolidation & Trimming (coordination-note removal offsets dispatch-hygiene addition) · Epistemic Discipline (cite-results requirement in dispatch briefs)

### Rename
No rename.

## 2026-05-24

### Summary
Encoded DKT-37 / DKT-40 operator-prescribed resolution (independently corroborated by historical audit: 9 state-divergence shutdown-rejections from impl-DKT-40 + 6 wrong-recipient routing errors). Added shutdown-async clarification, pre-shutdown state-verification gate, state-divergence-rejection trust rule, mid-cycle redirect-race rule, label-discipline rule, and routing reminder requirement. Dropped stale "unverified" disclaimer on docket plan --watch (verified by docket-auditor). Added agent-memory bootstrap note. Net +15 lines (425 → 440).

### Changes
- Teammate Stall & Crash Recovery: prepended Shutdown protocol (async-by-design) + mandatory Pre-shutdown state-verification gate (git diff --stat + docket issue show + reconcile-or-probe + cite verification + routing reminder) + Trust state-divergence rejections + Mid-cycle redirect-race rule + Label-discipline rule. Encodes operator pitfall points 1-5.
- Step 12: added (c) pre-shutdown gate cross-reference; collapsed redundant "no keep alive" narrative.
- Step 13: collapsed redundant "Confirm completed ephemerals exited" bullet to one-line Rule 7 cross-ref.
- Teammate Stall section: collapsed redundant Fix-loop re-spawn paragraph (kept inline preamble enumeration; removed restated-elsewhere framing).
- Step 12 Long-running phases: dropped stale "(unverified)" parenthetical on `docket plan --json --watch`; noted interval default 2s.
- Step 16 Memory check: added `mkdir -p .claude/agent-memory/team-lead` bootstrap (directory does not yet exist).

### Dimensions Evaluated
Actionability (PRIMARY — encodes operator resolution as concrete commands + sequence) · Boundary Clarity (state-divergence rejection authority) · Consolidation & Trimming (3 redundancy collapses offset 1 substantive addition) · Spec Alignment (verified docket flags) · Completeness (bootstrap gap)

### Rename
No rename.

## 2026-05-19 (P1 brief-authoring + lifecycle hygiene + memory activation)

### Summary
Encoded the operator's P1 lesson (DKT-6 brief-authoring contradiction) as a Closed-vs-Open dimension rule + detector in the @senior-engineer Spawning Template. Added a TeamCreate lifecycle pre-flight to eliminate 24 recurring `Already leading team` errors. Activated the dormant agent-memory channel via a wrap-up nudge gated on "recurring pitfall." Offset with three exhortation-tail trims plus an Epistemic Discipline annotation. Net +5 lines (359 → 364).

### Changes
- @senior-engineer Spawning Template: added Brief-Authoring Discipline (Closed vs Open per dimension) + detector — author MUST grep own brief for prescriptive overlap with the consult list and collapse to one.
- Team Setup step 1: added Lifecycle pre-flight — on `Already leading team` error, run TeamDelete on the named prior team and retry.
- Wrap-up step 16: added Memory check — append `symptom → root cause → resolution` entry to `.claude/agent-memory/team-lead/pitfalls.md` ONLY on recurring pitfalls.
- Step 13: removed moralizing tail about stale-claim history; behavior is already in the Flag-discrepancy line.
- Rule 2: removed exhortation tail; the spot-check-as-high-stakes-event is already enumerated.
- Pattern Decision Tree: removed over-orchestration restatement; L60 already prescribes lightest-pattern-default.
- Step 12 Long-running phases: annotated `docket plan --json --watch` as unverified per Rule 6.

### Dimensions Evaluated
Actionability (PRIMARY — P1 brief-authoring rule + detector) · Capability Growth (lifecycle hygiene + memory activation) · Consolidation (three exhortation trims) · Epistemic Discipline (unverified-CLI annotation).

### Rename
No rename.

## 2026-05-19

### Summary
Tightened orchestrator contracts around the vote-skill handoff, tool envelope, and operator-visibility convention based on historical audit findings (delegation `from`-field gap, Edit-tool errors, prefix-convention drift, AskUserQuestion option-cap errors). Net +4 lines (355 → 359), within BALANCED budget.

### Changes
- Consensus Integration: added explicit Delegation relay contract — verify `skill`/`vote_id`, run standalone vote, relay result to `delegation_request.from`, mirror to operator.
- Lead role declaration: stated tool envelope explicitly (no Edit/Write) to prevent unsupported-tool errors.
- Operator-visibility Rule 2: codified `[{ROLE}→@{recipient}]` prefix convention beyond `[LEAD→]`.
- Pre-flight step 4 + new hard rule: AskUserQuestion ≤4 options per question.
- Direct Task pattern footer: trimmed redundant decision-tree restatement.

### Dimensions Evaluated
Capability Growth & Cross-Communication (PRIMARY — vote handoff) · Boundary Clarity (tool envelope) · Cross-Agent Coherence (prefix table) · Actionability (option-cap rule) · Consolidation (Direct Task trim).

### Rename
No rename.

## 2026-05-17 (Phase 2 coherence)

### Summary
Documented intentional execution-vs-doc Communication Discipline rule-numbering asymmetry as Rule 5.

### Changes
- Rules section: appended Rule 5 documenting the execution (1-8+) vs doc (1-6) vs PM (1-5) rule-numbering convention.

### Dimensions Evaluated
Convention documentation; future-cycle coherence durability.

### Rename
No rename.

## 2026-05-17

### Summary
Consolidation pass: -28 lines target by collapsing redundant guidance that already lives in Security Track, step 13 spot-check protocol, and recovery recipe. No behavioral changes — every removed phrase was a restatement of guidance present elsewhere in the file.

### Changes
- Review Phase parallel-security explainer collapsed to one-line pointer to Security Track.
- Wrap-up spot-check restatement removed; cross-refers to step 13.
- Context-saturation handoff condensed; defers to recovery recipe.
- Probe-once rule tightened.
- Common scaffolding auto-resume note tightened; ux-advisor added to alias list.
- Re-plan on divergence moralizing tail removed.
- Pattern Decision Tree closing exhortation condensed.
- Security Track Small bullet phrasing tightened.

### Dimensions Evaluated
Consolidation & Trimming (PRIMARY), Role Realism, Completeness, Coherence.

### Rename
No rename.

## 2026-05-16

### Summary
Phase 2 coherence: align @senior-engineer Spawning Template with Rule 7 (claim-first ordering).

### Changes
- Reordered the "BEFORE starting" line to put `docket issue move <id> in-progress` as FIRST tool call on dispatch, then `comment list`. Matches senior-engineer.md Rule 7 and sdet.md new Rule 7. Stall-detection signal (e) already aligned.

### Dimensions Evaluated
Claim-before-work ordering parity between Spawning Template and teammate workflows.

### Rename
None.

## 2026-05-16

### Summary
Added orchestrator-side controls for the communication-discipline rules: context-saturation handoff protocol (rule 3), claim-before-work and 10-min progress-silence stall signals (rules 7+8), and SendMessage auto-resume note for stopped advisors. Consolidated triple-bucket triage into Pattern Decision Tree.

### Changes
- Consolidated three-bucket triage block into Pattern Decision Tree (-15) — duplicate guidance.
- Added "Context-saturation handoff" protocol to Stall & Crash Recovery (+6) — teammate-initiated respawn with continuity briefing.
- Stall detection list: added (e) claim-before-work failure and (f) >10-min progress silence (+3).
- Documented SendMessage auto-resume for stopped advisors in Common scaffolding (+1).
- Operator-visibility contract now lists spot-check discrepancies as high-stakes events (+2).

### Dimensions Evaluated
Role Realism · Actionability · Boundary Clarity · Completeness · Consolidation & Trimming · Capability Growth & Cross-Communication · Spec Alignment · Rename.

### Rename
No rename.

## 2026-05-13

### Summary
Phase 2 coherence: renamed UX persistent teammate spawn to canonical "ux-advisor" (aligns with advisor/security-advisor pattern); annotated `docket issue close` with no-`-m` clarification in @senior-engineer Spawning Template.

### Changes
- @ux-designer Spawning Template: `name="ux-spec-author"` → `name="ux-advisor"`; matches ux-designer.md canonical persistent name
- Wrap-up shutdown list updated: `ux-spec-author if spawned` → `ux-advisor if spawned`
- @senior-engineer Spawning Template close-out: added `(no -m flag)` annotation inline

### Dimensions Evaluated
Coherence (canonical persistent-name alignment), Actionability (close-flag annotation)

### Rename
ux-spec-author → ux-advisor (spawn name in team-lead.md only; aligns with canonical persistent-teammate naming).

## 2026-05-13

### Summary
Added **Direct Task** orchestration pattern (single @senior-engineer, no PM/review/team) addressing operator pain — documentation overhead generated for trivial work. Sharpened Pattern Decision Tree thresholds with concrete quantification (file counts, phase counts) and explicit "default to the lightest pattern" bias. Offset via trims to Review parallel-explainer, Re-plan block, Monitor block, and minor edits. Net: -2 lines (344 → 342).

### Changes
- New **Direct Task** pattern: trivial single-edit work (rename, typo, dep bump, log tweak, ≤3 files, no design) spawns ONE @senior-engineer in solo mode, no TeamCreate, no @project-manager planning, no @staff-engineer review
- Sharpened Pattern Decision Tree: 5 sizing steps (was 4), explicit file-count/phase-count thresholds, "default to lightest" footer
- Pre-flight step 4 ambiguity AskUserQuestion now includes Direct (5 options), biased to lighter
- Team Setup marks TeamCreate as skipped for Direct Task
- Trimmed Re-plan on divergence (3 lines), parallel-review explainer (security-vs-general dimension list now lives only in Security Track and security-engineer Spawning Template), Monitor block, HARD GATE phrasing, persistent-memory line, Wrap-up final bullet

### Dimensions Evaluated
Completeness (operator pain on over-documentation; Direct Task), Actionability, Consolidation, Coherence, Role Realism, Boundary Clarity, Capability Growth

### Rename
No rename.

## 2026-05-09

### Summary
Trimmed redundant spawning-template scaffolding (hoisted common Agent() / Verified goal / `<user_request>` boilerplate into a single preamble), fixed step-numbering collision between Design Phase and Planning Phase (which restarted at 4), promoted TeammateIdle hook as canonical stall signal, and added `docket vote link` post-commit. Net: −95 lines (439 → 344).

### Changes
- Hoisted common spawning scaffolding into a single preamble; trimmed all 8 templates: @staff-engineer (TDD + Code Review), @security-engineer (TDD + Review), @project-manager, @ux-designer, @senior-engineer, @sdet
- Fixed step-numbering collision: phases renumbered into a single 1-16 sequence (Team Setup 1-2, Design 3-6, Planning 7-10, Implementation 11-13, Review 14, Verification 15, Wrap-up 16); cross-references updated
- Added `docket vote link {vote-id} --issue {DOCKET-ID}` to Consensus Integration so votes unblocking a specific issue are traceable
- Promoted `TeammateIdle` hook to canonical stall signal in Stall & Crash Recovery (cheaper and more accurate than 10-min TaskList polling)
- Tightened persistent-memory paragraph parenthetical

### Dimensions Evaluated
Consolidation & Trimming (PRIMARY — 7 of 12 changes), Actionability (step-numbering correctness), Completeness (vote-link integration, TeammateIdle promotion), Capability Growth, Spec Alignment, Boundary Clarity, Role Realism, Rename

### Rename
No rename.

## 2026-05-08

### Summary
Phase 3 operating discipline: added Persistent memory section to capture solutions to non-obvious orchestration problems.

### Changes
- Added Persistent memory paragraph at top: save operator priorities, recurring orchestration pitfalls (stall classes, fix-loop offenders, re-plan triggers), AND solutions to non-obvious coordination problems (symptom → root cause → resolution) so future cycles don't re-discover the same gap; explicit do-not-save list (per-cycle plan details, teammate reports — those live in Docket/changelogs)

### Dimensions Evaluated
Capability Growth (PRIMARY — orchestrator now persists cross-cycle learning), Coherence (memory format aligned with fleet bold-prefix paragraph convention)

### Rename
No rename.

## 2026-05-08

### Summary
Phase 2 coherence: broadened Rule 1 hub-and-spoke description to match fleet reality — the prior 4-pair allowlist contradicted documented peer triggers in every teammate file.

### Changes
- Rule 1 now allows any peer pair for narrow technical clarification (architecture, shared-interface, test-failure, design-QA, spec-feasibility) while reserving team-lead as relay for cross-cutting decisions (re-plans, scope changes, vote delegation, escalations, stall recoveries, plan revisions to in-flight issues)

### Dimensions Evaluated
Coherence (PRIMARY — canonical→reality alignment), Behavioral (preserves the actual rule that teammates already follow), Concrete (enumerates which classes route through hub vs. peer-to-peer)

### Rename
No rename.

## 2026-05-08

### Summary
Fixed `TaskCreate` API misuse in Team Setup (no `depends_on` parameter exists; dependencies are set via `TaskUpdate` `addBlockedBy`). Removed redundant /vote prohibition from the TDD spawning template — already covered by the file-top CRITICAL banner. Net: -1 line.

### Changes
- Fixed Team Setup step 2: `TaskCreate ... set depends_on` → `TaskCreate` then `TaskUpdate ... addBlockedBy` (correctness bug — `depends_on` is not a valid TaskCreate parameter; phases would silently lack ordering)
- Removed `Do NOT invoke /vote for TDD approval` clause from the @staff-engineer (TDD) spawning template — duplicates the CRITICAL banner which already prohibits all teammates from invoking /vote, Skill(), Agent(), TeamCreate

### Dimensions Evaluated
Spec Alignment (PRIMARY — TaskCreate API correctness), Consolidation & Trimming, Actionability

### Rename
No rename.

## 2026-05-07

### Summary
Fixed invalid `docket issue graph --direction blocks` flag value (verified at runtime). Added Monitor tool guidance for long-running phases and explicit hub-and-spoke topology rule with allowed peer-to-peer exceptions. Trimmed HARD GATE phrasing and Implementation Phase parallelism guidance to offset additions. Net: 0 lines (360→360).

### Changes
- Fixed `docket issue graph --direction blocks` → `--direction up` (line 292) — invalid flag value; valid values are up/down/both. "Blast-radius before re-planning" semantically maps to `up` (which dependents would be affected)
- Added Monitor tool usage in Implementation Phase step 9 for streaming docket state changes during long-running phases (10+ minutes); surfaces stalls before the 10-min TaskList threshold
- Added Hub-and-spoke topology rule explicitly listing allowed peer-to-peer SendMessage exceptions (PM↔advisor, senior↔advisor, senior↔senior, sdet↔senior); cross-cutting decisions (re-plan/scope/escalation/votes) route through orchestrator
- Trimmed HARD GATE phrasing (Pre-flight step 1) — merged duplicative re-ask + don't-proceed clauses
- Trimmed Implementation step 8 parallelism guidance from 4 lines to 1; preserved 5-per-turn limit

### Dimensions Evaluated
Spec Alignment (PRIMARY — correctness bug), Capability Growth & Cross-Communication (Monitor + hub-and-spoke), Consolidation & Trimming, Actionability

### Rename
No rename.

## 2026-05-07

### Summary
First evolve cycle for team-lead since extraction from /dev skill (cf9a8d0). Added fleet-standard `[LEAD→@agent]` operator-visibility prefix to mirror inter-agent SendMessage to Docket comments. Fixed broken "Handling Failures below" cross-reference. Standardized HARD GATE header to fleet pattern. Trimmed redundancy in shutdown phrasing, Consensus Integration, and Pre-flight step 4. Added Docket CLI pointer for `--root` and `issue graph --direction` per audit.

### Changes
- Added `[LEAD→@agent]` operator-visibility contract in Rules (mirrors staff/senior/sdet pattern); folded Rule 1 into the contract
- Fixed broken "see Handling Failures below" reference → "see Teammate Stall & Crash Recovery below"
- Standardized HARD GATE header in Pre-flight step 1 (matches fleet wording)
- Trimmed shutdown phrasing in step 9 (removed misleading small-task clause)
- Compressed Consensus Integration paragraph (removed criticality criteria duplicated in skills/vote/)
- Tightened Pre-flight step 4 (decision tree IS the assessment mechanism)
- Added `docket plan --root` and `docket issue graph --direction blocks` capabilities to step 10 phase verification

### Dimensions Evaluated
Consolidation & Trimming (PRIMARY — 4 of 7 changes), Capability Growth & Cross-Communication (operator-visibility prefix + Docket CLI), Completeness (broken cross-ref), Coherence with Fleet Standards (HARD GATE), Role Realism, Actionability, Boundary Clarity, Spec Alignment, Rename

### Rename
No rename. "team-lead" is the canonical orchestrator role name across the fleet.
