# Changelog: evolve-agents

## 2026-07-11

### Summary
Operator-directed permanent doctrine changes (not a self-review cycle): added `sdlc-role-researcher` as a STANDING Phase 0 teammate (was ad-hoc/supplementary in the just-completed SDLC-comparison cycle), and switched Phase 2 `coherence-reviewer` + Phase 3 `disambiguation-reviewer` from `staff-engineer`/opus to `distinguished-engineer`/fable. File grows further over the pre-existing 65,000-byte overage (now ~78,126B; tracked separately, not addressed here).

### Changes
- ADD: `sdlc-role-researcher` (distinguished-engineer, fable) added to the Phase 0 roster (now EIGHT teammates), its own spawning template, `{sdlc_research_findings}` threaded into the Phase 1 per-agent template, and the TaskCreate/Phase-table entries. Never gated by the historical-audit SKIPPED flag (WebSearch-driven, not transcript-mining) — always runs.
- CHANGE: `coherence-reviewer` and `disambiguation-reviewer` subagent_type/model changed from `staff-engineer`/`opus` to `distinguished-engineer`/`fable` (Phase table, both Phase gate descriptions, both spawn templates).

### Dimensions Evaluated
Operator directive, applied verbatim (not a self-review Content-Gate cycle). Byte-budget overage is a known, separately-tracked condition (this changelog's own 2026-07-10 entries); not remediated here.

### Rename
No rename.

## 2026-07-10

### Summary
Phase 2 coherence pass: aligned docs-paths master citation to the relocated team-doctrine reference; culled redundant Phase 2 template steps 6-8 (now mechanized by symmetry_check.py) to restore parity with evolve-skills. File remains ~3,683B over the 65,000 hard limit — flagged (FLAG A/B below, not applied) as an operator-gated Scientific Trial candidate.

### Changes
- Docs-paths citation → `…/team-doctrine/references/docs-paths.md` (was team-lead.md §copy).
- Phase 2 template: removed steps 6-8 (innovation-scanner/model-routing/Mimir byte-symmetry, mechanized by step 5's `symmetry_check.py --check all`); renumbered historical-auditor-note check 9→6.
- FLAGGED (not applied, operator-gated): root-path convention is half-migrated (bare `agents/*.md`/`skills/*/SKILL.md` vs repo `src/user/claude-code/{agents,skills}/`) — evolve-agents' own pre-flight inventory (`find agents -maxdepth 1`) would find zero agents in this repo layout. Needs a deliberate family-wide sweep, not a coherence quick-fix.
- FLAGGED (not applied, operator-gated): shared evolutionary-doctrine extraction (EVOLUTION-MODEL/Innovation Mandate/Scientific Trial/Genetic-Drift, ~3.1-4KB near-identical across 4 carriers) to a new team-doctrine reference file — required to bring both evolve-agents AND evolve-skills under the 65,000-byte hard limit; the byte-identical CANONICAL sub-block alone (1,930B) is insufficient.

### Dimensions Evaluated
Cross-reference accuracy; template parity; mechanization coherence (symmetry_check.py `--check all` now exits 0).

### Rename
No rename.

## 2026-07-10

### Summary
File confirmed 4,334-4,373 B OVER the 65,000 hard limit (`wc -c`=69,373). Corrected a false "byte budget accommodates this file" self-budget claim. PRIMARY remedy — extracting the ~5,443 B shared evolutionary-doctrine block (EVOLUTION-MODEL/Innovation Mandate/Scientific Trial/Genetic-Drift, lines 30-50) to `team-doctrine/references/evolution-model.md`, cite-not-restate — is deferred to Phase 2 + operator Scientific-Trial-Protocol approval (new shared file + touches 4 skills: evolve-agents, evolve-skills, evolve-config, evolve-coherence).

### Changes
- CULL: corrected the false self-budget claim (line 127) that asserted the byte budget "accommodates this file" while the file was 4,334 B over — cited measured `wc -c` violation.
- DEFERRED (Phase 2, operator-gated): extract shared evolutionary-doctrine blocks (lines 30-50) to a team-doctrine reference — cited over-hard-limit + confirmed near-byte-identical duplication across 4 carriers.

### Dimensions Evaluated
All 8. Over-Engineering (HIGHEST) — primary open item is the budget violation, remedy pending Phase 2. Agent()-`description` param family-wide gap (45/46 examples) flagged, not fixed unilaterally.

### Rename
No rename.

## 2026-06-30

### Summary
Trimmed evolve-agents from 522 to estimated 498 lines while adding Phase 0 coordination/lifecycle heatmap output and replacing fixed line-window reads with relevant-section reads.

### Changes
- AMPLIFY: historical-auditor output now includes a compact coordination/lifecycle heatmap — cited recurring lifecycle-signal correlation needs.
- AMPLIFY: Phase 2 coherence now reuses evolve-coherence XREF rubric/detection seeds — cited cross-family drift detection reuse.
- CULL: collapsed the verbose 8-dimension list and ADR 0001 compaction restatement — cited over-budget prose duplication.

### Dimensions Evaluated
All 8.

### Rename
No rename.

## 2026-06-30

### Summary
Phase-2 coherence: propagated the glob-abort find-form (same bug class fixed in evolve-skills this cycle) to all 4 single-root inventory/changelog globs. Inline, net 0 (stays 533). Phase 1 was RETAIN (no-signal organism).

### Changes
- CULL: replaced `wc -l agents/*.md`/`ls docs/changelog/agents/*.md` globs (pre-flight steps 4 & 6, Phase 4 gate, wrap-up step 2) with `find <root> -maxdepth N -name … -exec wc -l {} + 2>/dev/null` — zsh nomatch aborts a bare glob even with `2>/dev/null` when the root is empty/absent (real risk: fresh-repo changelog dir). Family-consistency with the evolve-skills fix. All find-forms verified under zsh.

### Dimensions Evaluated
All 8. Over-Engineering: inline, net 0 (533/535 self-budget). No model/routing/drift change. Cross-organism items routed to evolve-agents cycle (clean-up-team reword; adr stale-state guidance; $ARGUMENTS-banner escaping).

### Rename
No rename.

## 2026-06-20

### Summary
Phase 2: pinned model= (aliases) on all 8 Agent() spawns + added a $TMPDIR scratch guard to the shell-heavy auditor Rules. In-line edits, no line growth (stays 533).

### Changes
- AMPLIFY: pinned `model=` on every Agent() spawn — sonnet (docket/historical/model-routing auditors) / opus (docs-researcher, innovation-scanner, review-<name>, coherence-reviewer, disambiguation-reviewer). Cited team-lead.md "an Agent() call without model= is a dispatch defect"; operator-approved per-tier pinning.
- AMPLIFY: appended a `$TMPDIR`-not-`/tmp` scratch guard to the historical-auditor + model-routing-auditor Rules lines — cited the config-history-auditor run ERROR `operation not permitted: /tmp/...`.

### Dimensions Evaluated
Skill Design, Actionability, Completeness, Over-Engineering, Orchestration, Coherence, Spec Alignment, Rename.

### Rename
No rename.

## 2026-06-20

### Summary
Compacted 7 entries (2026-06-04..2026-06-09) into Compacted history per ADR 0001.

### Changes
- Replaced the 7 oldest committed entries (entries 11-17) with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per ADR 0001, not a review cycle.

### Rename
No rename.

## 2026-06-19

### Summary
Phase 2 coherence pass: concrete stall threshold + `TeammateIdle` backtick on stall-detect line, biodiversity CANONICAL-tag correctness cull (lockstep with evolve-skills), re-invocation failure signal added to historical-auditor. Parity checks 5-9 all CLEAN.

### Changes
- AMPLIFY: backticked `TeammateIdle` + added "≥2 turns with no new tool call is stall evidence" to stall-detect line — concretizes abstract trigger.
- CULL: removed "CANONICAL tag" from biodiversity niche-token filter — matches every family carrier, defeats monoculture guard (correctness defect; lockstep with evolve-skills).
- AMPLIFY: added re-invocation failure signal to historical-auditor (source bullet + output line) — closes measurement gap vs evolve-skills. Net +2 lines (498/500).

### Dimensions Evaluated
Coherence (parity fixes, TeammateIdle backtick); Correctness (CANONICAL-tag defect); Completeness (re-invocation signal).

### Rename
No rename.

## 2026-06-19

### Summary
Drift: FOCUS-AREAS reorder → applied. Drift: Phase-1 Context read-order → applied. All 4 prioritized adaptive changes deferred or rejected: 3 parity-bound with evolve-skills (stall threshold, biodiversity CANONICAL-tag cull, shutdown parenthetical) routed to Phase 2 lockstep; Wrap-up pitfall-write rejected (Content Gate: Executable fail — no orchestrator pitfalls contract).

### Changes
- DRIFT: Phase 0 docs-researcher FOCUS AREAS reordered (coordination-primitives first, Changelog last) — neutral allele substitution, seed 6f0ab504 pick 1, net 0, non-parity-bound.
- DRIFT: Phase 1 ## Context read-order reformulated (feedback-priority stated first) — neutral allele substitution, seed 6f0ab504 pick 2, net 0, non-parity-bound.

### Dimensions Evaluated
All 8; Over-Engineering primary (no agents-local additions survived gate). Parity: CANONICAL blocks intact; 3 deferred changes are byte-identical with evolve-skills and require Phase 2 lockstep.

### Rename
No rename.

## 2026-06-10

### Summary
Phase 2 coherence (lockstep with evolve-skills): Phase 1 apply step 2 gains Read-before-Edit, re-Read-after-grep/mv, and 1:1 Edit↔CHANGE apply-discipline. Line-neutral (496 lines); post-apply byte-identity with evolve-skills verified (sort -u = 1 line).

### Changes
- AMPLIFY: apply step 2 — in-session Read-before-Edit, re-Read after grep/mv targeting content strings, one Edit per approved CHANGE — cited signal: two re-fired team-lead pitfalls (Read-before-Edit failures ×2; stray-token batch defect).

### Dimensions Evaluated
Coherence (lockstep pair byte-identical), Completeness (apply-discipline gaps closed), budget (496/500 unchanged).

### Rename
No rename.

## 2026-06-10

### Summary
Full-cycle audit (1-day window): NO changes. File clean at 496 lines; NET_LINES physical-vs-display (L392/L146) and researcher repo-state ADOPTION caveat (L199/L412) verified already-encoded; spawn templates correctly carry subagent_type-only (cost-tier model routing lives in team-lead.md / agent defs, not skill templates).

### Changes
- None (NO-OP verdict). Phase-0 spawning-templates extraction (~180 lines, lockstep with evolve-skills) routed to Phase 2 as parity-bound; apply-discipline gaps (Read-before-Edit, 1:1 Edit↔CHANGE) shared with evolve-skills also routed to Phase 2.

### Dimensions Evaluated
All 8; Over-Engineering primary (drift-operator rationale load-bearing, no failure signal — RETAIN); Coherence (CANONICAL byte-parity with evolve-skills confirmed).

### Rename
No rename.

## 2026-06-10

### Summary
Introduced evolutionary-theory core: CANONICAL:EVOLUTION-MODEL block (genome/trait/fitness-signal vocabulary), natural-selection dispositions (AMPLIFY/CULL/RETAIN), Genetic-Drift Operator (fitness-independent neutral substitution, `drift=N` parameter, structural no-signal-set construction), Scientific Trial Protocol (hypothesis → operator-approval HARD GATE → measure → adopt-or-rollback), biodiversity invariant, and speciation gate. CANONICAL:EVOLUTION-MODEL byte-identical across evolve-agents/evolve-skills/evolve-coherence (hash e9ef8d09).

### Changes
- CANONICAL:EVOLUTION-MODEL block added (Phase A); byte-identical across all three evolve-* carriers.
- Innovation Mandate updated to cite three variation sources: innovation-scanner, historical-auditor, genetic-drift operator.
- Genetic-Drift Operator section added: structural no-signal-set construction (grep-then-subtract), `{drift_seed} mod len(set)` target selection, S2 reproducibility caveat.
- Scientific Trial Protocol added: Hypothesis → operator approval → measurement → adopt-or-rollback; `Trial:`/`Drift:` changelog recording.
- Selection disposition rule added to Phase 1 template (AMPLIFY/CULL require cited fitness signal; RETAIN is default).

### Dimensions Evaluated
Coherence (EVOLUTION-MODEL family parity, D4 0 Blockers); Completeness (selection dispositions, drift operator, trial protocol coverage); Skill Design Quality (structural target selection, determinism caveat).

### Rename
No rename.

## 2026-06-10

### Summary
Compacted 8 entries (2026-05-19..2026-05-30) into Compacted history per ADR 0001.

### Changes
- Replaced the 8 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per ADR 0001, not a review cycle.

### Rename
No rename.

## 2026-06-10

### Summary
Full-cycle audit (1-day window): NO changes. File clean at 487 lines; all `\$ARGUMENTS` escaped, no docket drift, self-referential Phase 0 focus areas (de-dup L241, FP-filter L242) verified already-encoded.

### Changes
- None (NO-OP verdict). audit-profile gate, transcript-index builder, model-grep collapse, and `-r2` centralization all routed to Phase 2 as cross-skill/parity-bound, not Phase 1 edits.

### Dimensions Evaluated
All 8; Over-Engineering primary (no bloat at 487/500); Coherence (CANONICAL:BANNER + frontmatter byte-parity confirmed with evolve-skills).

### Rename
No rename.

## 2026-06-09

### Summary
Compacted 34 entries (2026-03-19..2026-05-18) into Compacted history per ADR 0001.

### Changes
- Replaced the 34 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per ADR 0001, not a review cycle.

### Rename
No rename.

## 2026-06-09

### Summary
Phase 2 parity fix: escaped 5 documentary `\$ARGUMENTS` occurrences (L48/54/64/73/198), lockstep with evolve-skills sister. Backtick spans do not prevent substitution (empirically confirmed this cycle). Net 0 (368 lines).

### Changes
- L48/54/64/73/198: backticked `$ARGUMENTS` → `\$ARGUMENTS` in documentary prose; L293 meta-rule already escaped, untouched.

### Dimensions Evaluated
Skill Design Quality (arg-escape); Coherence (byte-parity with evolve-skills on shared prose + HARVEST block verified PASS).

### Rename
No rename.

## Compacted history

Entries below were compacted per ADR 0001; full text in git history (see the compaction entry's date).

- 2026-06-04: Fixed `days=N` argument parse defect — all-agents scope HARD GATE and inventory validation no longer mis-fire on bare `days=N`; Parsing rule strips window token first.
- 2026-06-05: Symmetric trim with evolve-skills — removed redundant Phase 1 reviewer read-list recap from template-forwarding sentence (already verbatim in template); net 0.
- 2026-06-08: Two redundancy trims (368→366): Phase 1 per-agent narration line and historical-auditor "never bulk-cat ~/Development" clause (duplicated in CANONICAL:HARVEST); parity with evolve-skills.
- 2026-06-09: NET_LINES budget lesson codified — physical-newline `wc -l` delta only; post-apply `wc -l` is the only budget truth; both mirrored to evolve-skills Phase 2.
- 2026-06-09: Phase 2 — historical-auditor correction-regex FP guard (operator-typed turns only); WebFetch added to allowed-tools; lockstep with evolve-skills.
- 2026-06-09: Three mid-run-safe additions (368→367): docs-researcher repo-adoption grep gate, Phase-1 $-escape reviewer flag, rename-sweep LIVE-file scoping; 2 parity-bound with evolve-skills.
- 2026-06-09: NO-OP (368 lines) — documentary `$ARGUMENTS` escape and NET_LINES wording routed to Phase 2 parity-bound with evolve-skills; CANONICAL:BANNER + HARVEST byte-parity confirmed.
- 2026-03-19: Added Pre-flight section with 5 validation steps; fixed duplicate step numbering; removed hardcoded roles; graceful WebFetch degradation.
- 2026-03-19: Added {today_date} propagation to Phase 1/2 templates; Agent identifier line; spec selectivity guidance.
- 2026-03-19: Added allowed-tools frontmatter; compressed Wrap-up 22→9 lines and Team Setup; self-evolution note.
- 2026-03-19: Collapsed redundant changelog normalization restatement (459→457).
- 2026-03-20: Added effort: high; compressed Phase 0 template and Team Setup; simplified timeout fallback; fixed TaskUpdate/TaskList params.
- 2026-03-20: Replaced Phase 0 agent spawn with caller-provided docs research passthrough; removed project-agnostic Content Gate check.
- 2026-03-20: Compressed spawn pseudo-code; Phase 0 checks newly-discovered docket commands; added context: fork.
- 2026-03-20: Removed phantom ToolSearch step; compressed Changelog Rules 18→7; expanded docket audit checklist.
- 2026-03-20: Added Docs Research task to Team Setup; renamed Phase 0 heading to match behavior.
- 2026-03-21: Added cross-communication log and vote-proposal tracking to wrap-up report for operator observability.
- 2026-03-29: Compressed dimension 6; re-spawn-once timeout fallback; effort high→max; consolidated docs-researcher template to ~12 lines.
- 2026-03-30: Added rigorous-honesty orchestrator directive; compressed Phase 0 templates; removed inapplicable Mermaid rule.
- 2026-03-30: Trimmed description 815→~230 chars; removed unused {focus_areas} variable; anti-rubber-stamp directive.
- 2026-04-06: Added anti-sub-agent-spawning instructions to Phase 1/2 templates and Rules; compressed post-Phase-1 verification.
- 2026-04-16: Consolidated size-constraint/checklist blocks (359→347); dimension naming aligned; No-nested-agents promoted to intro callout.
- 2026-04-16: Added Agent Lifecycle table; replaced vague course-correct rule with (a)/(b)/(c) SendMessage triggers (347→344).
- 2026-04-22: Added Crash & Stall Recovery protocol: TeammateIdle detection, re-spawn-once, fail-forward, compaction recovery (344→332).
- 2026-05-04: Trim pass: removed redundant tails, v2.1.111 reference, compressed phase description blocks, consolidated Rules (332→310).
- 2026-05-05: Adopted Monitor tool for stall detection replacing 10-min heuristic; unified critical-rules block; removed duplicate invariants (310→274).
- 2026-05-05: Pre-flight step 2 restructured to multiSelect over six pain-point classes with Other follow-up.
- 2026-05-05: Three orchestration alignments with evolve-skills: mid-Phase-1 routing fix, no-peer-to-peer rule, shutdown consolidation (274→270).
- 2026-05-06: Six parity fixes vs evolve-skills: structured AskUserQuestion options, operator-prompts blockquote, consolidated lifecycle header (273→266).
- 2026-05-06: Phase 1 trim/coherence with evolve-skills: merged Rule 5 into Rule 3, shutdown reason param, aligned Phase 0 capture phrasing.
- 2026-05-06: Aligned operator-prompt blockquote phrasing with evolve-skills.
- 2026-05-06: Two redundancy trims plus Phase 2 gate parity — explicit all-Phase-1-shut-down precondition (262→258).
- 2026-05-07: Five parity/redundancy trims aligning with sister evolve-skills (258→254).
- 2026-05-07: Phase 2 coherence: Phase 1 workflow numbered list, SendMessage-triggers subsection, Output Format multi-line layout.
- 2026-05-09: Aligned Pre-flight step 2 pain-point options with evolve-skills; Phase 1 Output Format multi-line with Coherence Issues schema; paths: added.
- 2026-05-09: Four pain-point fixes: Pre-flight forward-reference, H4→H3 Output Format parity, condensed Rule 3, dropped spawn parenthetical (276→273).
- 2026-05-13: Sister-parity: CANONICAL banner markers around CRITICAL block; Phase 2 template Output reformatted to H3 list (276→279).
- 2026-05-16: Three over-engineering trims: merged Pre-flight steps 5+6, SendMessage-triggers pointer, dropped Rule 3 tail (283→276).
- 2026-05-16: Friction-payload recognition mirrored from evolve-skills; AskUserQuestion preamble multiSelect carve-out extended.
- 2026-05-17: Corrected AskUserQuestion option cap (≤4 regardless of multiSelect, verified live); collapsed step 2 to 4 options; 8 mirror trims (net -23).
- 2026-05-18: Fixed date-to-epoch-ms gap in historical-auditor history.jsonl filter ({history_cutoff_epoch_ms} + jq one-liner); sister parity.
- 2026-05-19: Phase 2 coherence pass — aligned operator-prompt banner to evolve-skills' stronger phrasing (explicit ≤4-options API constraint + routing-question fallback)....
- 2026-05-20: Phase 2 coherence pass: aligned Changelog Rules format with sister evolve-skills — promoted normalization actions from trailing prose to `**Normalization:**`...
- 2026-05-20: Fixed `${history_days}` shell-var leak in Phase 0 historical-auditor template (orchestrator substitutes `{...}` braces, not shell-var `${...}` — auditor subs...
- 2026-05-25: Seven changes addressing 46% pre-flight abort signal and shutdown-routing ambiguity from team-lead memory: added scope-confirmation HARD GATE, clarified shut...
- 2026-05-28: Phase 2 coherence: mirrored evolve-skills' transcript-replication guards into the historical-auditor, added orchestrator-only-relay rationale to the Phase 1...
- 2026-05-28: Added an absent/empty-dir guard to the Phase 0 historical-auditor's agent-memory read step (parity with evolve-skills), preventing undefined read behavior on...
- 2026-05-29: Normalized the Content Gate intro line to byte-identical with the sibling evolve-skills (Phase 2 coherence).
- 2026-05-30: Two changes: closed a sibling-asymmetric "Second failure" recovery gap (Phase 0 auditor fallback), and added the Phase-0-findings-are-signals-not-facts rule...
