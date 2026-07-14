# Changelog: evolve-agents

## 2026-07-13 (Phase 3 disambiguation pass)

### Summary
Phase 3 disambiguation: Rules §2's read-only invariant now names its sole exception.

### Changes
- AMPLIFY[SUBSTANTIVE]: Rules §2 — "Teammates are read-only" read as exceptionless, contradicting Phase 4's `history-compactor` (spawned with Edit; applies/reverts its own compaction edits) — now names the compactor as sole exception

### Dimensions Evaluated
Disambiguation (multi-reading).

### Rename
No rename.

## 2026-07-13 (Phase 2 coherence pass)

### Summary
Phase 2 coherence: extended the Template-sourcing Read-once/ABORT convention to explicitly cover the relocated §9 SDLC Role Research template.

### Changes
- AMPLIFY[SUBSTANTIVE]: Template-sourcing paragraph now names §9 as single-homed under the same Read-once and ABORT rules — closes the gap where only the four auditor templates were enumerated after today's relocation

### Dimensions Evaluated
Coherence, Orchestration & Agent Teams, Completeness

### Rename
No rename.

## 2026-07-13

### Summary
Applied 1 accepted Docket finding (DKT-266a, folded into §8's future content, not applied here) + 5 verified Phase-0 findings from a scoped evolve-skills cycle. Relocated the SDLC Role Research template to team-doctrine's new §9 (clean, ~5.4KB relief, file now 58,666/65,000 bytes). Deferred the Innovation Scan/Docs Research relocation (§7/§8) — blocked by `symmetry_check.py` + tokenization coupling with evolve-skills' own inline copies. Findings: 6 → 6 sub / 0 cos / 0 rej / 1 def / 0 enc

### Changes
- CULL[SUBSTANTIVE]: SDLC Role Research inline template (49 lines) → 2-line pointer to `evolve-phase0-templates.md` §9 (I3c; verbatim relocation, evolve-agents-only, no symmetry-gate conflict)
- AMPLIFY[SUBSTANTIVE]: Wrap-up step 2 — fixed dead-path `find agents` → `find src/user/claude-code/agents` (I5; the over-budget consolidation gate was silently no-oping every cycle)
- CULL[SUBSTANTIVE]: cut false "currently over 65,000-byte limit" self-budget clause (I6; file was 63,444B, under budget even before this cycle)
- AMPLIFY[SUBSTANTIVE]: Phase-1 spawn-prompt `## Rules` — added explicit READ-ONLY rule citing the recurring self-edit + fabricated-"applied" failure (H1+H2; 5 Read-before-Edit violations in one session + 3 pitfalls.md entries across team-lead/ux-designer/staff-engineer memories)
- AMPLIFY[SUBSTANTIVE]: Crash & Stall Recovery — added signal (d) API-error self-report as a faster crash signal (DR1; changelog 2.1.198, verified)
- AMPLIFY[SUBSTANTIVE]: Crash & Stall Recovery — added nudge-before-respawn step for stuck (not dead) teammates (DR1; same 2.1.198 fix)
- DEFER: I3 §7 (Innovation Scan) + §8 (Docs Research) relocation — §7 is blocked by `symmetry_check.py`'s hardcoded byte-compare between evolve-agents/evolve-skills inline copies; §8 needs new tokenization ({TARGET_GLOB}, divergent FOCUS AREAS) and only partially completes (evolve-skills still duplicates docs-researcher). Both routed to a dedicated future cycle that can touch evolve-skills/SKILL.md + `symmetry_check.py` atomically.

### Dimensions Evaluated
Actionability (dead-path bug, stale claim), Orchestration & Agent Teams (crash detection, self-review discipline), Over-Engineering (template consolidation via single-homing).

### Rename
No rename.

## 2026-07-12 (Phase 4 history compaction)

### Summary
Compacted 5 entries (2026-06-09..2026-06-10) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 5 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-12 (Phase 3 disambiguation pass)

### Summary
Pinned single ownership of team-lead.md's model-routing surface (overlapping-ownership with /evolve-model-distribution); aligned the `day=N` alias documentation with evolve-skills' convention. Findings: 2 → 2 sub / 0 cos / 0 rej / 0 def / 0 enc

### Changes
- AMPLIFY[SUBSTANTIVE]: Phase 1 template now defers Tiers-list/routing-prose edits on team-lead.md to /evolve-model-distribution (DEFERRED disposition) — resolves overlapping-ownership with the routing-dedicated skill's heavier gates (Trial-only downgrades, per-proposal operator gate)
- AMPLIFY[SUBSTANTIVE]: Argument Handling — documented `day=N` as an accepted alias for `days=N`, matching evolve-skills

### Dimensions Evaluated
Disambiguation (overlapping-ownership, argument-parsing family consistency). Flagged for a FUTURE dedicated pass (too large/risky for this cycle's wrap-up): 29 occurrences of a stale `agents/*.md` path literal (real location is `src/user/claude-code/agents/`) — confirmed live via `ls`; the same class of bug this cycle already fixed twice elsewhere (evolve-skills' changelog path, this file's own changelog path). Recommend the next /evolve-agents cycle's own Phase 1 self-review fix this, or a dedicated targeted pass.

### Rename
No rename.

## 2026-07-12 (Phase 2 coherence pass)

### Summary
Repaired two silently-dead `find` paths (the sibling of the fix evolve-skills received earlier this cycle) and adopted cache-first changelog fetch in lockstep with evolve-skills/evolve-config. Findings: 2 → 2 sub / 0 cos / 0 rej / 0 def / 0 enc

### Changes
- FIX[SUBSTANTIVE]: pre-flight step 6 + Phase-4 gate — `docs/changelog/agents` → `docs/changelog/claude-code/agents` (old dir nonexistent; `2>/dev/null` masked it, deadening the compaction gate permanently)
- AMPLIFY[SUBSTANTIVE]: pre-flight step 9 — cache-first changelog fetch via `~/.claude/cache/changelog.md` (<24h mtime), curl-refresh fallback (repetition-auditor confirmed repeated re-fetch of an unchanged ~400KB file)

### Dimensions Evaluated
Coherence (sibling path-fix parity), Efficiency. Still over the 65,000B budget (79,481B) — the only real close is the deferred shared-doctrine/Phase-0-template extraction (recorded as a Trial proposal below).

### Rename
No rename.

Trial: extract shared Phase-0 auditor templates (historical/repetition/bug/model-routing + CANONICAL:HARVEST) to team-doctrine/references → proposed

## 2026-07-12

### Summary
Fixed stale @staff-engineer→@distinguished-engineer headings (Phase 2/3, same bug class as evolve-skills); added a mirrored-doctrine divergence check to the coherence-reviewer. Reverted an initial TRIM attempt on the Genetic-Drift Operator prose after confirming it is byte-identical parity-bound across evolve-agents/evolve-skills/evolve-config — deferred to Phase 2 lockstep instead. File remains over the 65,000B budget (79,229B); the only real budget-closing lever is the deferred shared Phase-0/doctrine template extraction. Findings: 6 → 1 sub / 1 cos / 1 rej / 4 def / 0 enc

### Changes
- CULL[COSMETIC]: corrected Phase 2/3 headings to @distinguished-engineer — cited innovation-scanner Retire + lifecycle-table/body cross-check (matches evolve-skills' identical fix)
- AMPLIFY[SUBSTANTIVE]: coherence-reviewer now greps agents/*.md for diverged mirrored doctrine beyond symmetry_check.py's 5 skill-vs-skill blocks — cited distinguished-engineer pitfalls 2026-07-11 (recurring gap)

### Dimensions Evaluated
All 8. Over-Engineering primary: file is 14.2KB over budget; only the DEFERRED shared-doctrine extraction closes it (this file is the primary beneficiary per its own §Self-budget line). Rejected the sdlc-role-researcher staleness gate (unproven safety, cost-optimization belongs in evolve-model-distribution). Deferred: drift_target.py codification, WebFetch docs-cache adoption (both cross-cutting w/ evolve-skills/evolve-config).

### Rename
No rename.

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
- 2026-06-09: Phase 2 parity fix — escaped 5 documentary `\$ARGUMENTS` occurrences, lockstep with evolve-skills; net 0 (368 lines).
- 2026-06-09: Compacted 34 entries (2026-03-19..2026-05-18) into Compacted history per ADR 0001.
- 2026-06-10: Full-cycle audit NO-OP (487 lines) — $ARGUMENTS escaping + docket drift + Phase-0 focus-area dedup verified already-encoded.
- 2026-06-10: Compacted 8 entries (2026-05-19..2026-05-30) into Compacted history per ADR 0001.
- 2026-06-10: Introduced evolutionary-theory core — CANONICAL:EVOLUTION-MODEL, selection dispositions, Genetic-Drift Operator, Scientific Trial Protocol.
