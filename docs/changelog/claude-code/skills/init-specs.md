# Changelog: init-specs

## 2026-07-14 (Phase 4 history compaction)

### Summary
Compacted 2 entries (2026-06-08..2026-06-09) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 2 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-14

### Summary
No-change verdict. All 8 dimensions clean. I32 parity re-verified manually: init-specs Spec File Reference table and prd RESERVED-NAMES are IN SYNC (7 names, same order) — flagged PARITY-BOUND, mechanized check deferred to prd's I27 arm. spec_verify.sh now exists and Step 3's description matches it exactly. No trim headroom.

### Changes
- None (NO-OP verdict).

### Dimensions Evaluated
All 8; Over-Engineering (HIGHEST — no trim without dropping a safety rail); Coherence (prd RESERVED-NAMES parity + spec_verify.sh reference accuracy verified on-disk).

### Rename
No rename.

## 2026-07-13 (Phase 4 history compaction)

### Summary
Compacted 3 entries (2026-05-28..2026-06-05) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 3 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-13 (Phase 3 disambiguation pass, evolve-skills cycle)

### Summary
Phase 3 disambiguation (evolve-skills cycle): spawning-template opener no longer reads as a delegation instruction.

### Changes
- AMPLIFY[SUBSTANTIVE]: template opener "Use the @staff-engineer agent to generate…" → "You are a @staff-engineer teammate generating…" — the prompt recipient could read the old opener as an instruction to spawn an agent, contradicting the leaf-agent rule in the same template

### Dimensions Evaluated
Disambiguation (multi-reading).

### Rename
No rename.

## 2026-07-12

### Summary
Fixed a stale/circular Wrap-up step ("clean up the team — clean up the team") that referenced the removed `TeamDelete` tool. Confirmed the `model="sonnet"` spec-author pin agrees with team-lead.md's live bronze-tier routing (no change — changing it would CREATE an inconsistency, not fix one). `spec_verify.sh` deferred, confirmed nonexistent. Findings: 1 → 1 sub / 0 cos / 0 rej / 1 def / 1 enc

### Changes
- CULL[SUBSTANTIVE]: Wrap-up step 3 — replaced the tautological "clean up the team" imperative (leftover from the removed `TeamDelete` tool) with an accurate no-manual-teardown note; per-teammate shutdown (step 2) is the only explicit cleanup

### Dimensions Evaluated
Orchestration & Agent Teams / Coherence (primary). Already-encoded (no action, agree-and-hold): `model="sonnet"` spec-author pin — verified against live team-lead.md:244 (`init-specs` spec-gen explicitly bronze-tier); the scanner's silver-floor argument is a legitimate routing-policy debate but team-lead.md's table has already made the call. Deferred: `spec_verify.sh` codification (confirmed nonexistent; proposed interface noted for a future cycle).

### Rename
No rename.

## 2026-07-10

### Summary
No-change verdict. All 8 dimensions clean; ground-truth re-verified ($ escapes, model enum, effort-absent family convention). Two cross-cutting items routed to Phase 2 (Agent-description family-wide shorthand; validate_doc.py doesn't exist yet).

### Changes
- None (NO-OP verdict).

### Dimensions Evaluated
All 8; Over-Engineering (no trim headroom without dropping a Step-3 verification rail).

### Rename
No rename.

## 2026-06-30

### Summary
AMPLIFY Mermaid verification from presence-only to renderer-free diagram-type shape validation, net 0.

### Changes
- AMPLIFY: verification and spawning-template requirements now reject missing, empty, or typeless Mermaid blocks with a renderer-free diagram-type check.

### Dimensions Evaluated
All 8.

### Rename
No rename.

## 2026-06-20

### Summary
Coherence/over-engineering + operator-approved model= pin; net -1 (180→179). Banner deferred to Phase 2.

### Changes
- CULL: replaced "Poll TaskList() every ~2 minutes" (Step 2) with a SendMessage-primary model + a single TaskList reconciliation pass — the poll loop contradicted the skill's own SendMessage-driven completion model and its "no hand-rolled wall-clock timer" rule (the now-moot v2.1.181 idle-row caveat went with it; a stale "polling" reference in the failure path was updated to "completion tracking").
- AMPLIFY: pinned `model="sonnet"` on the 7-way spec-generation Agent() spawn template — closes the dispatch defect (omitted model= → non-deterministic teammate fallback); operator-approved per-tier pinning.

### Dimensions Evaluated
Skill Design, Actionability, Completeness, Over-Engineering, Orchestration, Coherence, Spec Alignment, Rename.

### Rename
No rename.

## 2026-06-19

### Summary
Re-anchored stall detection on harness-native signals and removed the hand-rolled 480s wall-clock timer + spawn-time map (grounded in v2.1.181 idle-row-hide behavior).

### Changes
- AMPLIFY (Step 2): classify a stall via TeammateIdle + the ~10-min harness auto-fail reap instead of a 480s wall-clock heuristic — an idle teammate's row hides after 30s while still running (v2.1.181). Now matches vote/SKILL.md + team-lead signal (f). Removed orphaned spawn-time-map clauses. Net -3.
- DEFERRED: grep→awk batch (CHANGE 2) — proposed awk changed last_updated matching from substring to exact-equality; unverifiable, held.
- Drift (rate 7): all SKIP — token/machine-coupled or already-minimal prose.

### Dimensions Evaluated
Over-Engineering, Actionability, Completeness, Coherence, Orchestration, Rename.

### Rename
No rename.

## 2026-06-17

### Summary
Fixed the worktree project-name bug, corrected an inverted shutdown direction in the spawning template, and tightened the stall threshold. Trial: worktree-fix / shutdown-direction / stall-threshold → adopted.

### Changes
- CULL: `basename $(git rev-parse --show-toplevel)` → `basename $(git rev-parse --git-common-dir) | sed 's/\.git$//'` — `--show-toplevel` returned the branch dir (`main`), not the repo name, in worktree layouts (verified live).
- CULL: spawning-template shutdown was inverted ("emit shutdown_request") — corrected to idle-AWAIT the orchestrator's request, reply shutdown_response (canonical protocol).
- AMPLIFY: stall threshold 600s → 480s for a ~2-min early-warning window before the harness ~10-min auto-fail.

### Dimensions Evaluated
Skill Design Quality / Orchestration (CULL), Coherence (AMPLIFY), others RETAIN.

### Rename
No rename.

## 2026-06-10

### Summary
No-change verdict. All 8 dimensions clean; Phase 0 signals re-verified against ground truth: refusal-gate ordering correct (unknown-arg abort precedes overwrite dialog), \$ARGUMENTS escapes present since 2026-06-09 fix, Step 3 grep passes retain clarity over an awk batch.

### Changes
- None (NO-OP verdict). isolation: worktree inapplicable — unique file path per spawned agent, no collision risk.

### Dimensions Evaluated
All 8; Over-Engineering (HIGHEST — no trim without dropping a safety rail); Orchestration (worktree eval); Coherence (reserved-names shared-include candidate routed to Phase 2 as parity-bound with prd).

### Rename
No rename.

## 2026-06-10

### Summary
Compacted 9 entries (2026-05-09..2026-05-25) into Compacted history per ADR 0001.

### Changes
- Replaced the 9 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per ADR 0001, not a review cycle.

### Rename
No rename.

## 2026-06-10

### Summary
One correctness fix: replaced `shutdown_approved` with `shutdown_response` in the Spawning Template, aligning with the documented protocol response type used ecosystem-wide. Net 0 (183 lines).

### Changes
- Spawning Template L172: `shutdown_approved` → `shutdown_response` — the documented shutdown protocol type; grep confirmed `shutdown_approved` appeared only here across all skill/agent definition files. Overwrite-prompt guard verified present (Pre-flight step 4); Monitor-alternative for the stall classifier remains rejected per 2026-05-05 entry.

### Dimensions Evaluated
All 8; Orchestration & Agent Teams (shutdown terminology correctness), Coherence (protocol-term parity with family).

### Rename
No rename.

## 2026-06-09

### Summary
Compacted 27 entries (2026-03-19..2026-05-07) into Compacted history per ADR 0001.

### Changes
- Replaced the 27 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per ADR 0001, not a review cycle.

### Rename
No rename.

## 2026-06-09

### Summary
Phase 2 fix: escaped 3 documentary `\$ARGUMENTS` occurrences (L21/52/60). The prior "backtick-inline documented-variable, deliberately not escaped" rationale is refuted by this cycle's empirical evidence that substitution occurs inside backticks — bare occurrences corrupted Argument Handling/Pre-flight prose at invocation. Net 0 (183 lines).

### Changes
- L21/52/60: backticked `$ARGUMENTS` → `\$ARGUMENTS` in documentary prose.

### Dimensions Evaluated
Skill Design Quality (arg-escape correctness); Coherence (family-wide documentary-escape ruling; vote L27 live command confirmed stays bare).

### Rename
No rename.

## 2026-06-09

### Summary
Fourth consecutive no-change verdict. Phase-0 step-ordering signal NO-OP: unknown-arg abort (L23) fires before Pre-flight; overwrite dialog (L60) unreachable by reserved-name concern (init-specs owns those names; prd's refusal-first ordering confirmed downstream). Seven Spec Files exact-match team-lead taxonomy.

### Changes
- None (NO-OP verdict). `$ARGUMENTS` substitution-intent ruling (L21/52/60) deferred to Phase 2 alongside the family-wide escape decision.

### Dimensions Evaluated
All 8; Over-Engineering primary (183 lines, no trim headroom); Coherence (COUPLING reciprocity with prd consistent).

### Rename
No rename.

## 2026-06-09

### Summary
Mythos/Fable-5 cycle audit: NO changes. Reasoning-echo clean. $ARGUMENTS hits (L21/52/60) are backtick-inline documented-variable idiom — NOT positional-expansion hazards; deliberately NOT escaped (escaping would corrupt the documented meaning). Third consecutive no-change verdict.

### Changes
- None (NO-OP verdict).

### Dimensions Evaluated
All 8; Over-Engineering primary; $-escape audit: documented-variable exception applied.

### Rename
No rename.

## Compacted history

Entries below were compacted per ADR 0001; full text in git history (see the compaction entry's date).

- 2026-03-19: First evolution cycle: date-resolution step, scope boundary vs dev skill, docs/tdd cross-reference, streamlined reference table.
- 2026-03-19: Moved orchestrator responsibilities out of spawned agents (mkdir, project name); concrete frontmatter YAML; frontmatter verification in Step 3.
- 2026-03-19: Added allowed-tools frontmatter; merged Team Setup into Step 1; cross-spec awareness instruction for spawned agents.
- 2026-03-19: Added argument handling with optional file-list support; trimmed Rules 8→4.
- 2026-03-20: Fixed TaskCreate/TaskUpdate/TaskList parameters to actual schema; added effort: medium; removed duplicate Agent() call.
- 2026-03-20: Added SendMessage completion trigger to spawning template; rewrote Step 2 completion monitoring; removed duplicate cleanup rule.
- 2026-03-20: Added context: fork frontmatter; removed redundant Rules section; consolidated pre-flight steps.
- 2026-03-20: Fixed pre-flight step numbering and shutdown message JSON syntax.
- 2026-03-20: Removed context: fork (breaks agent teams); fixed pre-flight numbering; corrected shutdown syntax.
- 2026-03-21: Added operator-facing progress relay per completed agent; removed stale </output> artifact.
- 2026-03-29: Trimmed redundant spawning-template/pre-flight instructions; aligned argument handling with $ARGUMENTS convention.
- 2026-03-30: Added honesty directives at orchestrator and template levels; trimmed description; added docket plan context.
- 2026-04-06: Added explicit leaf-agent constraints — spawned agents must not spawn sub-agents or invoke skills; canonical 4-tool anti-spawning pattern.
- 2026-04-16: Added missing {verified_goal} substitution in Step 1; full-sweep review found no bloat at 158 lines.
- 2026-04-16: Clarified agent independence (isolated files, no cross-agent handoffs); SendMessage triggers expanded to blocker case.
- 2026-04-22: Closed crash/stall gap: 2-min polling cadence, task-state classification, respawn/skip/abort AskUserQuestion; effort medium→max.
- 2026-05-04: Closed edge-case ambiguities (unknown-argument abort, argument+existing-file interaction, shutdown targeting); added activeForm.
- 2026-05-05: Pre-flight goal-alignment converted to structured two-question AskUserQuestion (Scope multiSelect + Emphasis).
- 2026-05-05: No improvements applied; rejected Monitor-tool addition and TaskList polling rewrite with rationale.
- 2026-05-05: Phase 2 coherence: unified CRITICAL banner format with evolve-* skills, preserving leaf-agent terminology.
- 2026-05-06: COUPLING comment now enumerates all 4 dependent create-* skills enforcing the reserved-name list.
- 2026-05-06: Renamed specs → create-specs to align with the create-* family; directory, frontmatter, slash command, cross-references updated.
- 2026-05-06: Phase 1 trim: dropped half-finished verification spot-check and trailing git-diff reminder (168→161).
- 2026-05-06: Renamed create-specs → specs per operator request; directory, frontmatter, /specs slash command, cross-references updated.
- 2026-05-06: Closed two safety-rail gaps: Mermaid-diagram grep check in Step 3; spawn-time recording for the 10-min stall classifier (164→172).
- 2026-05-07: Replaced stale dev-skill reference with team-lead orchestrator; H1 fixed from # Create Specs to # Specs.
- 2026-05-07: Added CANONICAL:BANNER markers around the CRITICAL banner; corrected reciprocal reserved-names COUPLING comment (172→174).
- 2026-05-09: Three small actionability + coherence fixes (operator pain points 1, 3): added `last_updated` regression check to Step 3 verification, clarified that templat...
- 2026-05-09: Phase 2 coherence pass: declared `paths:` write surface for orchestrator parity with evolve-agents and evolve-skills.
- 2026-05-09: Three small operator-experience and coordination-clarity fixes: added Architecture/maintainability emphasis option, distinguished spawned-agent failure handl...
- 2026-05-16: Phase 2 coherence pass: shutdown_request payload now specifies full `{type, reason}` shape (uniform with vote/evolve-*); AskUserQuestion preamble extended wi...
- 2026-05-16: Four operator-pain fixes: added canonical "Operator prompts" banner (coherence with evolve-skills/evolve-agents); hardened Verification globs against empty-g...
- 2026-05-17: Phase 2 coherence sync: corrected false AskUserQuestion "multiSelect lifts the 4-option cap" carve-out (matches sister orchestrator-skill corrections this cy...
- 2026-05-17: Respawn arm now explicitly reassigns task ownership and re-records spawn time so polling credits the replacement agent; description tightened to signal one-t...
- 2026-05-18: Closed verification-scope bug (false-flagging pre-existing specs on "Skip existing" path) and trimmed two layers of redundant leaf-agent prohibition + an inf...
- 2026-05-25: No-change verdict. Smallest skill in the doc-authoring family (177 lines) and thoroughly trimmed across prior cycles. Phase 0 focus areas resolve as structur...
- 2026-05-28: Fixed crossed shutdown handshake in parallel-spawn flow — orchestrator now approves self-initiated shutdown_request instead of originating competing requests. Net 0.
- 2026-05-30: No-change verdict; changelog file renamed specs.md → init-specs.md to match the skill rename applied in a prior cycle.
- 2026-06-05: Corrected factually wrong COUPLING comment (prd does not write to docs/spec/; siblings refuse reserved names by doc-type, not directory).
- 2026-06-08: Phase 1 no-change verdict — Seven Spec File names verified exact-match vs team-lead.md taxonomy; shutdown lifecycle + COUPLING confirmed.
- 2026-06-09: Third consecutive no-change verdict — $+digit audit clean; COUPLING reciprocity re-confirmed post refactor; RESERVED-NAMES exact-match.
