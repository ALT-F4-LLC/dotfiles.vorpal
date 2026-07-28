# Changelog: team-lead

## 2026-07-27

### Summary
Compacted 6 entries (2026-07-13..2026-07-15) into Compacted history per the retention-compaction policy.

### Changes
- Replaced the 6 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (retention-compaction policy)

### Rename
No rename.

## 2026-07-27

### Summary
Phase 3 disambiguation: root-cause routing now names a single owner (investigator executes, advisor consults), and the Moving-tree GO cites the seated advisor's gate on either tier rather than staff's alone; folded in one Phase-2-class self-consistency fix (bare "Subagent" mechanism label).

### Changes
- FIX[SUBSTANTIVE] (DISAMBIG 7): No-Direct-Debugging Required-routing bullet routes root-cause diagnosis/hypothesis/discriminating-test DESIGN to an ephemeral `investigator` (@distinguished-engineer, gold) per the Gold-first routing reflex; the seated `advisor` is named as the CONSULT seat, never the first-pass diagnostician -- removes the advisor-vs-investigator ownership collision with line 197.
- FIX[SUBSTANTIVE] (DISAMBIG 6): step-14 routine-review GO cites the SEATED advisor's Moving-tree gate (distinguished-engineer.md Mode 2 / staff-engineer.md Review Workflow step 1) and states the `frozen:` embed binds on either tier.
- FIX[COSMETIC] (COH-A): V/I/SR pattern's `mechanism:` label changed from bare "Subagent" to "Report-only subagent" -- self-violated the file's own Distribution-Mechanism-Gate naming rule (line 109).

### Dimensions Evaluated
Disambiguation (Phase 3): overlapping-ownership; Coherence & Cross-Communication (Phase 2, self-consistency)

### Rename
No rename.

## 2026-07-27

### Summary
TRIM cycle. Closed an unsatisfiable DE-spawn contract (no `Mode:` field was ever emitted), corrected the death-evidence ladder so a SendMessage REFUSAL no longer authorizes a duplicate spawn, killed the dispatch-ledger flag ambiguity behind 3 failed sessions, adopted 3 harness facts (sibling-roster snapshot, return scanning, spawn caps), and made the GO freeze claim evidence-based. Paid for with 19 consolidations: 6 duplicate restatements collapsed to pointers, 5 rationale passages compressed, 3 non-executable inventories culled. Findings: 11 applied / 1 rejected / 3 deferred / 1 already-encoded. Net -204 bytes (134,033 -> 133,829).

### Changes
- AMPLIFY[SUBSTANTIVE] (C1): `Mode: <tdd-author|advisor|investigator|deep-impl>` added to Common context-block elements -- distinguished-engineer.md:85 and simplify-scout/SKILL.md:39,170 both gate on a field team-lead never emitted (grep count was 1, and that hit was `permissionMode:` frontmatter).
- AMPLIFY[SUBSTANTIVE] (D9/docs-researcher unnumbered): a SendMessage refusal is NOT D3 death evidence -- name-collision (v2.1.199) and operator-stopped cancellation (v2.1.191, sub-agents.md:945) both mean alive-or-shadowed; both unconditional auto-resume claims bounded. Prevents a Rule 7 duplicate-spawn violation.
- AMPLIFY[SUBSTANTIVE] (I6): GO trigger now embeds `frozen:<sha12>` from `tree_fingerprint.sh`, matching the `+dirty:` field reviewers already emit -- the freeze claim becomes checkable instead of asserted. Peer Moving-tree gates remain Phase-2-coordinated.
- AMPLIFY[SUBSTANTIVE] (B6): `[triggers:...]` removed from the dispatch_ledger command line; the script accepts only the flags shown and trigger letters go in `--note=` (verified against its arg parser).
- AMPLIFY[SUBSTANTIVE] (D2/D3/D7): sibling-roster snapshot semantics (a failed peer send is a roster gap, not a stall), v2.1.210 return-scanning annotations (harness-inserted, non-byte-exact), and the 200/session + 20-concurrent caps with the teammate exemption.
- AMPLIFY[SUBSTANTIVE] (B1): `summary` requirement moved to R3, the composition point -- 3 "main"-authored hits were ad-hoc relays no template could cover.
- CULL[SUBSTANTIVE] (H2): TeammateIdle demoted from "canonical" stall signal -- it fires on ~95-100% of ALL spawns uniformly (model-routing-auditor), so it triggers the idle ladders, never a verdict.
- CULL[COSMETIC]: effort census, investigator-brief Fable duplicate, and the sixth no-new-authority disclaimer removed; SendMessage contract, CLOSED-set, Name/background, Rule 7 name list, and the step-14 promised-gate check collapsed to pointers; DKT-65, benign-late, skill-strip, Rule 2 prefix, and opencode-provenance passages compressed.
- MECHANICAL (C6): `sdet-{ID}` -> `sdet-{DOCKET-ID}` at both tier bullets; `docs-author*` added to Rule 7's ephemeral list.

### Dimensions Evaluated
Role Realism, Actionability, Boundary Clarity, Completeness, Consolidation & Trimming (Pass B), Capability Growth & Cross-Communication, Spec Alignment, Rename

### Rename
No rename.

## 2026-07-27

### Summary
Phase 3 disambiguation: 4 sites let a reader name the wrong owner or actor at a decision point -- the V/I/SR advisor tier, the "Direct" mechanism's actor, the fix-round security reviewer's name, and the plan-review authority pointer. Net +194 bytes.

### Changes
- FIX[SUBSTANTIVE]: root-cause routing line now carves out V/I/SR explicitly -- a standalone V/I/SR task is never TDD-bearing, so its advisor is @staff-engineer at silver, not the ambiguous "on Medium+ cycles" phrasing that named a seat the same file's other 3 sites forbid for this branch.
- FIX[COSMETIC]: Distribution-Mechanism Gate item 1 relabelled "Direct (lead-driven, one worker, no peer comms)" -- the old label read as team-lead doing the work, which the same file's write-boundary and No-Direct-Debugging Boundary forbid.
- FIX[MECHANICAL]: fix-round security delta reviewer renamed security-reviewer-fix-{N}, aligning with security-engineer.md's own roster and the fleet -fix-{N} convention (was security-reviewer-2, a same-name-respawn hazard).
- FIX[COSMETIC]: triage note (a)'s "(iii) SUPERSEDES..." disambiguated from a duplicate list label to "That (iii) SUPERSEDES...".
- FIX[SUBSTANTIVE]: PA overlay's plan-conformance-review citation now tier-aware (distinguished-engineer.md Mode 2 on TDD-bearing cycles / staff-engineer.md Responsibility 2 sub-Medium) instead of citing only the sub-Medium holder's file for a TDD-bearing (Medium+) case.

### Dimensions Evaluated
Overlapping-ownership, multi-reading, confusable-name (Phase 3, two-arm test)

### Rename
No rename.

## 2026-07-27

### Summary
Phase 2 coherence: two non-resolving `scripts/` path literals normalized to full repo paths. Net +50B. (The tool-envelope.md master extraction proposed in Phase 1 was DEFERRED by the coherence-reviewer: this cycle's own D1 edits landed 7 intentionally-divergent paragraph variants, falsifying the byte-identity premise the extraction needed.)

### Changes
- FIX[MECHANICAL]: `scripts/model_census_exemptions.tsv` / `scripts/model_census.sh` -> `src/user/claude-code/scripts/...` (line 240; non-resolving from either repo root or deployment).

### Dimensions Evaluated
Coherence & Cross-Communication (Phase 2)

### Rename
No rename.

## 2026-07-27

### Summary
TRIM cycle. Corrected a FALSE harness claim (teammates DO keep the Task tools -- the fused v2.1.217 stamp split into per-claim stamps) and a false skill-strip claim; wired the orphaned docket_promote.sh into all 5 promotion sites; retired the DKT-61 empirical narrative and the model-tier exempt-category duplication; replaced the GNU-only shuf spot-check picker with a tested portable python3 sampler. Findings: 13 -> 8 sub / 3 cos / 1 rej / 3 def / 2 enc. Net -1,650 bytes (135,441 -> 133,791; still ~54KB over the 80,000-byte target -- the tool-envelope master extraction, conditional on Phase 2, is the next lever).

### Changes
- AMPLIFY[SUBSTANTIVE] (D1/I8): triage note (a) split into per-claim version stamps; teammate Task-tool claim corrected (agent-teams.md:255, sub-agents.md:338, live CC 2.1.220); Agent-at-depth re-grounded on agent-teams.md:425/426, depth-based justification retired. 3-site restatement collapsed to pointers.
- AMPLIFY[SUBSTANTIVE] (E1): Skill(commit) removed from the teammate-invocable list; stated team-lead-exclusive per commit/SKILL.md Step 0.
- AMPLIFY[SUBSTANTIVE] (D3): Skill(session-metrics) strips Agent+SendMessage only, not the Task family; commit/review-and-comment's Edit+Write strip named.
- AMPLIFY[SUBSTANTIVE] (B9): portable python3 random-sample replaces `shuf -n 2` (verified absent on this host); sort -R explicitly excluded.
- AMPLIFY[SUBSTANTIVE] (H1): idle checks ordered BEFORE the stall probe -- closes the probe-crosses-completion-report race behind 2 of 3 fleet shutdown-rejections.
- CULL[SUBSTANTIVE] (I9): docket_promote.sh cited at all 5 sites; one canonical gate paragraph at step 11, pointers at steps 14/15.
- CULL[SUBSTANTIVE] (I10): DKT-61 narrative reduced to its Discriminator; exempt-category definitions cite model_census_exemptions.tsv.
- CULL[COSMETIC] x3 (Pass B): redundant step-15 Promised-gate block deleted; Rule 8's paraphrase of step 14's rules 1-6 and its duplicate degraded-fallback sentence collapsed to pointers; "consume both" -> "consume all four" arity fix.

### Dimensions Evaluated
Consolidation & Trimming (priority), Actionability, Completeness/Doctrine Accuracy, Boundary Clarity, Capability Growth. Deferred: tool-envelope master (Phase 2 lockstep), R1 script-existence checks (fleet doctrine, outside 8-file scope).

### Rename
No rename.
## 2026-07-24

### Summary
Widened the Tiers-block doctrine claim from a single-layer statement ("The tier→alias mapping resolves HERE and nowhere else in this file") to a two-layer statement distinguishing tier→alias authority (this file) from alias→model-ID authority (`src/user.rs`'s `ANTHROPIC_DEFAULT_*_MODEL` bindings), with an explicit exempt-category enumeration. Wires the new `scripts/model_census.sh` mechanism (arms 1+2) into CI via `tests/model_census.test.sh`.

### Changes
- AMPLIFY[SUBSTANTIVE]: Tiers-block doctrine claim (line ~240) now states both mapping layers and their separate authorities, plus the four exempt categories (product-capability facts, provenance records, functional values, deliberate enumerations) enforced machine-side by `scripts/model_census_exemptions.tsv` and checked by `scripts/model_census.sh`.
- CI: added `bash tests/model_census.test.sh` as a new step in the `test-hooks` job (`.github/workflows/vorpal.yaml`), alongside the existing `doctrine_check.test.sh` step. Arm 3 (`--backstop`) is not wired into CI.

### Dimensions Evaluated
Doctrine Accuracy. Closes the gap found by this session's manual investigation (the `claude-mythos-5`-class miss), where the single-layer claim let alias→model-ID restatements and their exemption categories go unstated and machine-unchecked.

### Rename
No rename.

## 2026-07-21

### Summary
Compacted 4 entries (2026-07-01..2026-07-10) into Compacted history per the retention-compaction policy.

### Changes
- Replaced the 4 oldest date-headed entries (between the 10-entry keep-window and the prior Compacted history) with one-line ledger entries.

### Dimensions Evaluated
History Compaction (retention-compaction policy)

### Rename
No rename.

## 2026-07-21

### Summary
Phase 3 disambiguation: Rule 8's reviewer-default sentence split by phase type to prevent a multi-reading — verification's default was misreadable as a persistent-advisor seat.

### Changes
- FIX[COSMETIC]: Rule 8 opening sentence now names the persistent advisor for review/design-QA and the single report-only `@sdet` verifier for verification separately, instead of one em-dash apposition covering all three phase types.

### Dimensions Evaluated
Multi-reading clarity (Phase 3). No behavioral change — codifies what step 15 and sdet.md already prescribe.

### Rename
No rename.

## 2026-07-21

### Summary
Phase 2 coherence review. Trial: replace fix-loop continuity preambles with Agent(subagent_type="fork") → REVERTED same-cycle. Platform semantics: "fork" clones the CALLER, not a context-inheriting spawn of a different role — a team-lead fork is bound by team-lead's own no-self-edit charter and cannot claim/edit an issue; it also bypasses senior-engineer's named-ephemeral execution contract and pins fix rounds to team-lead's model.

### Changes
- REVERT[SUBSTANTIVE]: §Fix-loop re-spawn and its 3 downstream pointers (step 14, step 15, Rule 7) restored to the named `impl-{DOCKET-ID}-fix-{N}` + continuity-preamble mechanism, verbatim pre-trial text.

### Dimensions Evaluated
Boundary Clarity, Actionability. The finding's underlying value (eliminating hand-assembled-preamble errors) is re-proposable as a fork-generates-the-brief design (fork consults its own context to author the brief, then dispatches a normal named ephemeral) in a future baselined Phase 1 trial — not attempted here.

### Rename
No rename.

## 2026-07-21

### Summary
Applied the fork trial + three verified fixes, paid for by consolidating triplicate Promised-gate prose and the now-fallback continuity-preamble enumeration. Net −8 bytes (TRIM satisfied; file remains ~42KB over the 80,000-byte target — needs a dedicated future trim pass). Trial: replace fix-loop continuity preambles with Agent(subagent_type="fork") for fully-Closed, no-SendMessage dispatches → applied (baseline: senior-engineer shutdown-rejections=2 @5d, weak proxy — no direct preamble-error metric existed pre-trial). Findings: 9 → 3 sub / 1 cos / 0 rej / 3 def / 2 enc.

### Changes
- AMPLIFY[SUBSTANTIVE] (I-tl1, Trial): Fork-default fix-loop re-spawn at §Fix-loop re-spawn; preamble now fallback-only. Consolidated 3 downstream preamble references (steps 14/15, Rule 7) to pointers.
- AMPLIFY[SUBSTANTIVE] (I-tl3): real entropy source `git diff --name-only | shuf -n 2` for the blind spot-check pick.
- AMPLIFY[SUBSTANTIVE] (I-tl4): wired `gate_check.sh` into the step-16 Promised-gate delivery check; compressed the triplicate Promised-gate passages at steps 14/15/16.
- AMPLIFY[COSMETIC] (R-PREVENT-1): `docket_bootstrap.sh` reference in step 2, matching senior-engineer/sdet.

### Dimensions Evaluated
Actionability (I-tl3/I-tl4), Consolidation & Trimming (priority — 5 trims), Capability Growth (fork trial), Spec Alignment (bootstrap). Deferred: H-tl2 (already covered by pre-shutdown gate + SP-4), B3 (marginal under TRIM), M4/D8 (no natural fit).

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
- 2026-06-21: Compacted 11 entries (2026-05-26..2026-06-09) into Compacted history per ADR 0001.
- 2026-06-20: Phase-2 coherence — closed a GO-gate producer/consumer deadlock (step-14 dispatch now carries the `GO — review NOW` trigger) + within-file shutdown-sweep de-restatement. Drift: disabled (drift=0).
- 2026-06-30: TRIM cycle, within-file safe whole-line trims (-6) + EI effort correction (teammates DO inherit session effort per v2.1.186; only frontmatter `effort:` is unhonored). Net -6 (667→661).
- 2026-06-30: Phase 2 cross-cutting (operator-approved) — adopted PA plan-approval overlay; defaulted lone step-15 verifier to report-only subagent; added Rule 8 shared pre-computed reviewer brief; parallel `planner-{slug}` Large-Task decomposition. Net +2 (661→663). Trial: PA plan-approval overlay adopted family-wide → applied (measure next cycle).
- 2026-06-30: Phase 3 disambiguation — clarified `verifier` name collision, distinguished PA impl plan from PM phase plan, made advisor TDD-conformance plan-routing explicit.
- 2026-07-01: TRIM cycle — compacted Alignment/Optimization + Orchestration Patterns into a routing matrix; normalized lone verifier as report-only close gate. Trial: team-lead TRIM and report-only close gate -> applied.
- 2026-07-01: Wired plan-approval dispatch routing, supply-chain `Cargo.lock` evidence-packet requirement, and `planner-fix-{N}` lifecycle wording.
- 2026-07-01: Removed two spacer lines from team-lead.md after coherence left it over budget.
- 2026-07-01: Removed direct verifier peer routing (team-lead owns fix-loop/advisor routing); normalized master SP-1 shutdown-report schema.
- 2026-07-01: Compacted 4 entries (2026-06-09..2026-06-09) into Compacted history per ADR 0001.
- 2026-07-10: TRIM-mode cycle — Rule-8 lettering fix, 3 BAD-PARAM bug fixes (FIX-9 vote-delegation payload, FIX-13 model=[1m] rejected, FIX-4 threshold fraction), brief-block fast path, liveness-gate pre-respawn check hardened. Net +387.
- 2026-07-10: Phase 3 disambiguation follow-up — unified `V/I/SR` pattern abbreviation (dispatch-ledger `VISR` token changed to match prose usage everywhere else).
- 2026-07-10: Compacted 3 entries (2026-06-10..2026-06-10) into Compacted history per the retention-compaction policy.
- 2026-07-11: evolve-agents cycle (SDLC role-comparison mandate): TRIM cycle grounded in SDLC role research + bug/docs audits — effort third-lever correction, SP-1b outgoing shutdown_request rule, SP-2 name/background exclusivity fix, docs-author dispatch row, AskUserQuestion report-only caveat. Net -39 bytes.
- 2026-07-11: Phase 3 disambiguation fix: the new `docs-author` dispatch-table row didn't disambiguate against the confusably-named `docs-researcher` bronze role. Net +150 bytes.
- 2026-07-11: Compacted 3 entries (2026-06-17..2026-06-20) into Compacted history per the retention-compaction policy.
- 2026-07-12: Findings: 11 → 5 sub / 10 cos / 0 rej / 6 def / 3 enc. TRIM cycle: applied 6 Phase-0 findings (docket-cli pointer, cycle_metrics wiring, Monitor-driven sweep, fresh-context Read, repo-root-sweep rule, no-report-file) funded by 10 prose consolidations. Net -1,325 bytes.
- 2026-07-12: Phase 3 disambiguation: 3 fixes resolving multi-reading/ownership ambiguity — V/I/SR consult-advisor conditional, deep-research work-shape vs Skill(deep-research) naming collision, missing explicit-`--threshold` mandate on team-lead's direct vote-create path.
- 2026-07-13: Phase 3 disambiguation (DKT-270): Gold-first routing reflex's `Skill(vote)` restriction-class pointer glossed, aligning with the same gloss applied to the 3 sanctioned-role files.
- 2026-07-13: Phase 2 coherence (DKT-270): corrected the stale `Skill(deep-research)` parenthetical in the Gold-first routing reflex — deep-research is a bundled Workflow, not a teammate-invokable Skill.
- 2026-07-13: Compacted 4 entries (2026-06-20..2026-06-30) into Compacted history per the retention-compaction policy.
- 2026-07-15: Compacted 5 entries (2026-06-30..2026-07-01) into Compacted history per the retention-compaction policy.
- 2026-07-15: Added a Read-before-Edit pointer (B3) and a bidirectional stale-dispatch cross-ref (R3); vote relay-contract wire-form tail deduped to a Skill(vote) citation (I4). Byte budget still ~35KB over.
- 2026-07-15: Landed a HARD anti-idle turn-end invariant (bans bare-sleep placeholders / zero-armed-watch turn-ends while teammates outstanding); merged SendMessage-schema + shutdown-typo guards into SP-1b; brief Done-state names issue-close disposition. Net -151B.
