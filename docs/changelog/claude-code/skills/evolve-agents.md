# Changelog: evolve-agents

## 2026-07-17 (Phase 4 history compaction)

### Summary
Compacted 4 entries (2026-07-11..2026-07-12) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 4 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-17

### Summary
coherence-reviewer's Phase 2 pass verified the rename/parity fixes landed clean and proposed one additional parity-bound fix: mechanize the Phase 2 byte-identity check with doctrine_check.sh.

### Changes
- AMPLIFY[SUBSTANTIVE]: appended a `doctrine_check.sh` (exit 0 required) invocation after the manual grep-based byte-identity check in the Phase 2 apply instructions - its byte-parity arm re-verifies ALL manifest-registered CANONICAL blocks, catching a diverged carrier the single-line grep misses. Parity-bound with evolve-skills (identical appended clause).

### Dimensions Evaluated
Mechanical verification coverage; family parity.

### Rename
No rename.

## 2026-07-17

### Summary
Phase 2 family-wide lockstep application: the docs-researcher rename (P1) and 2 parity-bound findings (I4, I5b) deferred from this cycle's Phase 1 pass, applied identically across evolve-agents + evolve-skills (+ the shared canonical template + evolve-config for the rename).

### Changes
- AMPLIFY[SUBSTANTIVE]: renamed evolve Phase-0 auditor `docs-researcher` -> `docs-researcher-phase0` (8 occurrences) - lockstep with the canonical evolve-phase0-templates.md:422 template + evolve-skills (8 occ) + evolve-config (9 occ, bespoke copy). team-lead.md's bronze docs-researcher untouched (P1).
- AMPLIFY[SUBSTANTIVE]: Phase 2 gate now runs findings_ledger_check.py mechanically (I4) - byte-identical wiring applied to evolve-skills too; verified via grep post-apply.
- CULL[COSMETIC]: stripped settled innovation-scanner-relocation clause from symmetry_check step (I5b) - byte-identical strip applied to evolve-skills too; verified via grep post-apply.

### Dimensions Evaluated
Rename, Coherence, Actionability.

### Rename
docs-researcher -> docs-researcher-phase0 (Phase-0 auditor instance; team-lead.md's docs-researcher is a separate, untouched agent).

## 2026-07-17

### Summary
Targeted 2-item cycle (of a 3-item shared mandate across evolve-agents/evolve-skills/evolve-config/evolve-model-distribution): documented the intentional gold(agent/skill genome)/silver(config genome) coherence-reviewer tier split, and added the missing check_citations.py parity step to the Phase 2 coherence template. The docs-researcher rename (P1) is deferred to this cycle's Phase 2 for family-wide lockstep application (touches the shared evolve-phase0-templates.md + 2 sibling skills). Findings: 12 -> 2 sub / 0 cos / 1 rej / 6 def / 2 enc (P1 rename applies in Phase 2, not counted here).

### Changes
- AMPLIFY[SUBSTANTIVE]: document gold/silver coherence-reviewer tier split as intentional (agent/skill-genome auditing = gold; Rust-config-genome auditing = silver) - cited gold-tier-routing-gap-investigation (P3).
- AMPLIFY[SUBSTANTIVE]: add check_citations.py step to Phase 2 coherence template - parity restore vs evolve-skills' existing step, cited I3.

### Dimensions Evaluated
Coherence, Completeness, Spec Alignment.

### Rename
Deferred to Phase 2: docs-researcher -> docs-researcher-phase0 (evolve Phase-0 auditor instance only; team-lead.md's bronze docs-researcher is untouched), lockstep with evolve-phase0-templates.md + evolve-skills + evolve-config.

## 2026-07-14 (Phase 4 history compaction)

### Summary
Compacted 2 entries (2026-07-10..2026-07-10) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 2 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-14

### Summary
Phase 3 disambiguation: resolved a confusable recipient term in Crash & Stall Recovery.

### Changes
- Replaced "self-reports `failed` to the lead" with "to the orchestrator" — in standalone runs no team-lead exists, and the three sibling evolve-* copies of this clause already say "orchestrator" (confusable-name).

### Dimensions Evaluated
Confusable names/triggers/terms; multi-reading wording; overlapping ownership.

### Rename
No rename.

## 2026-07-14

### Summary
Added a post-cycle /evolve-coherence pointer to Wrap-up — root-cause fix for evolve-coherence's zero in-window invocations despite its description promising a post-edit gate. Supersedes DKT-311's evolve-agents half.

### Changes
- AMPLIFY: Wrap-up step 4 recommends operator run /evolve-coherence before committing — supersedes DKT-311's evolve-agents half.

### Dimensions Evaluated
Coherence (post-edit gate handoff).

### Rename
No rename.

## 2026-07-13 (Phase 4 history compaction)

### Summary
Compacted 8 entries (2026-06-10..2026-06-30) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 8 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-13 (Phase 3 disambiguation pass, evolve-skills cycle)

### Summary
Phase 3 disambiguation (evolve-skills cycle): charter pointer made self-resolving; scratchpad computation now mandates `$TMPDIR` expansion. Findings: 2 → 2 sub

### Changes
- AMPLIFY[SUBSTANTIVE]: Phase 3 template charter citation names `.claude/skills/evolve-agents/SKILL.md` §Phase 3 (was a dangling "section above" unresolvable from the delivered prompt)
- AMPLIFY[SUBSTANTIVE]: pre-flight step 3 — `{scratchpad}` computed by EXPANDING `$TMPDIR` to a literal absolute path before template substitution (an unexpanded string is un-Read-able by teammates; the sandbox remaps `$TMPDIR` per context)

### Dimensions Evaluated
Disambiguation (multi-reading).

### Rename
No rename.

## 2026-07-13 (Phase 2 coherence pass)

### Summary
Phase 2 coherence: EVOLUTION-MODEL vocabulary line corrected in 4-carrier lockstep; docket-auditor template gains explicit report-back line.

### Changes
- Fixed CANONICAL:EVOLUTION-MODEL header to name all 4 carriers (added evolve-config) — lockstep with siblings; doctrine_check.sh arm (c) re-verified.
- Added "SendMessage the orchestrator the report verbatim." to the docket-auditor spawn template — only Phase-0 template lacking the explicit report-back line.

### Dimensions Evaluated
Coherence (CANONICAL parity, cross-communication trigger completeness).

### Rename
No rename.

## 2026-07-13 (Phase 0 findings materialization)

### Summary
Materialized Phase 0 audit blocks + Findings Ledger to a shared scratchpad path instead of inline-pasting into Phase 1 spawn templates (DKT-275). Findings: 12 → 1 sub / 0 cos / 0 rej / 8 def / 1 enc.

### Changes
- AMPLIFY[SUBSTANTIVE]: Phase 0 completion Writes each audit block → `{scratchpad}/phase0/<auditor>.md` and the ledger → `{scratchpad}/findings-ledger.md`, where `{scratchpad}` = `$TMPDIR/evolve-agents-{today_date}` (shared, non-session-scoped path — cross-teammate Read access empirically verified 2026-07-13) — DKT-275 (large token cut; ledger survives compaction).
- AMPLIFY[SUBSTANTIVE]: Phase 1 template flips 8 `{..._findings}` inline pastes → a Read-these-paths list — DKT-275.
- AMPLIFY[SUBSTANTIVE]: SKIPPED (pre-flight step 8) + UNAVAILABLE (Crash & Stall Recovery) sentinels now written as file content so Read-by-path never hits a missing file — DKT-275.
- AMPLIFY[SUBSTANTIVE]: Phase 2 gate + Phase-1-spawn substitution list point at `{scratchpad}/findings-ledger.md` / add `{scratchpad}` — DKT-275.

### Dimensions Evaluated
Capability Growth, Actionability, Boundary Clarity (all 8 dimensions assessed; Pass B no-op — the DKT-275 SUBSTANTIVE changes ride un-offset, well under the 65,000-byte budget: 55,510 → 57,726 bytes).

### Rename
No rename.

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

## Compacted history

Entries below were compacted per ADR 0001; full text in git history (see the compaction entry's date).

- 2026-06-04: Fixed `days=N` argument parse defect — all-agents scope HARD GATE and inventory validation no longer mis-fire on bare `days=N`; Parsing rule strips window token first.
- 2026-06-05: Symmetric trim with evolve-skills — removed redundant Phase 1 reviewer read-list recap from template-forwarding sentence (already verbatim in template); net 0.
- 2026-06-08: Two redundancy trims (368→366): Phase 1 per-agent narration line and historical-auditor "never bulk-cat ~/Development" clause (duplicated in CANONICAL:HARVEST); parity with evolve-skills.
- 2026-06-09: NET_LINES budget lesson codified — physical-newline `wc -l` delta only; post-apply `wc -l` is the only budget truth; both mirrored to evolve-skills Phase 2.
- 2026-07-10: Phase 2 coherence — aligned docs-paths citation to team-doctrine ref; culled redundant Phase 2 template steps 6-8. ~3,683B over hard limit.
- 2026-07-10: File confirmed 4,334-4,373B over the 65,000 hard limit; corrected false self-budget claim. Evolutionary-doctrine extraction deferred to Phase 2.
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
- 2026-06-10: Full-cycle audit (1-day window) — NO changes; NET_LINES physical-vs-display and researcher ADOPTION caveat verified already-encoded.
- 2026-06-10: Phase 2 coherence (lockstep evolve-skills) — apply step 2 gains Read-before-Edit, re-Read-after-grep/mv, 1:1 Edit↔CHANGE discipline; line-neutral (496 lines).
- 2026-06-19: Drift FOCUS-AREAS + Context read-order rewords; all 4 prioritized changes deferred/rejected. | Drift: FOCUS-AREAS reorder → applied. | Drift: Phase-1 Context read-order → applied. | DRIFT: Phase 0 docs-researcher FOCUS AREAS reordered (coordination-primitives first, Changelog last) — neutral allele substitution, seed 6f0ab504 pick 1, net 0, non-parity-bound. | DRIFT: Phase 1 ## Context read-order reformulated (feedback-priority stated first) — neutral allele substitution, seed 6f0ab504 pick 2, net 0, non-parity-bound.
- 2026-06-19: Phase 2 coherence — concrete stall threshold + TeammateIdle backtick, biodiversity CANONICAL-tag cull (lockstep evolve-skills), re-invocation signal added.
- 2026-06-20: Compacted 7 entries (2026-06-04..2026-06-09) into Compacted history per ADR 0001.
- 2026-06-20: Phase 2 — pinned model= on all 8 Agent() spawns; added $TMPDIR scratch guard to shell-heavy auditor Rules.
- 2026-06-30: Phase-2 coherence — propagated glob-abort find-form fix (zsh nomatch) to all 4 single-root inventory/changelog globs; inline, net 0.
- 2026-06-30: Trimmed evolve-agents 522→498 lines; added Phase 0 coordination/lifecycle heatmap output; replaced fixed line-window reads with relevant-section reads.
- 2026-07-11: Added sdlc-role-researcher as standing Phase 0 teammate; switched coherence-reviewer/disambiguation-reviewer to distinguished-engineer/fable (operator-directed).
- 2026-07-12: Fixed stale @staff-engineer→@distinguished-engineer headings (Phase 2/3); added mirrored-doctrine divergence check to coherence-reviewer beyond symmetry_check.py.
- 2026-07-12: Repaired two silently-dead `find` paths; adopted cache-first changelog fetch (lockstep evolve-skills/evolve-config). | Trial: extract shared Phase-0 auditor templates (historical/repetition/bug/model-routing + CANONICAL:HARVEST) to team-doctrine/references → proposed
- 2026-07-12: Pinned single ownership of team-lead.md's model-routing surface to /evolve-model-distribution; aligned `day=N` alias documentation with evolve-skills.
