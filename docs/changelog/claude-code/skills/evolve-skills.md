# Changelog: evolve-skills

## 2026-07-12 (Phase 4 history compaction)

### Summary
Compacted 5 entries (2026-06-09..2026-06-10) into Compacted history per the retention-compaction policy.

### Changes
- History Compaction: replaced the 5 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per the retention-compaction policy, not a review cycle.

### Rename
No rename.

## 2026-07-12 (Phase 2 coherence pass)

### Summary
Adopted cache-first changelog fetch in lockstep with evolve-agents/evolve-config. Findings: 1 → 1 sub / 0 cos / 0 rej / 0 def / 0 enc

### Changes
- AMPLIFY[SUBSTANTIVE]: pre-flight step 10 — cache-first changelog fetch via `~/.claude/cache/changelog.md` (<24h mtime), curl-refresh fallback

### Dimensions Evaluated
Efficiency (repetition-auditor: repeated re-fetch of an unchanged ~400KB changelog). Still over the 65,000B budget (72,670B) — see the deferred shared-doctrine extraction Trial recorded in this cycle's earlier entry.

### Rename
No rename.

## 2026-07-12

### Summary
Self-review: fixed the never-existent `docs/changelog/skills` path (3 sites, silently zeroed changelog discovery + the Phase 4 compaction gate) and the stale `@staff-engineer` labels on the Phase 2/3 templates that actually spawn `distinguished-engineer` (confirmed contradicting the 2026-07-11 entry below). Findings: 9 → 1 sub / 1 cos / 0 rej / 5 def / 2 enc

### Changes
- CULL[SUBSTANTIVE]: `find docs/changelog/skills` → `.../claude-code/skills` at pre-flight step 7 (2×) + Phase 4 gate — dir never existed, `2>/dev/null` hid the error so compaction could never trigger (bug-auditor confirmed, live-verified)
- CULL[SUBSTANTIVE]: dropped contradictory "Use the @staff-engineer agent" directive from Phase 2/3 prompt bodies; relabeled headings @staff-engineer → @distinguished-engineer to match pinned spawn params (innovation-scanner Retire, confirmed)

### Dimensions Evaluated
Coherence (routing labels), Actionability (broken find command), Over-Engineering (net −13 B; sustainable TRIM = deferred Phase-0-template extraction, cross-cutting with evolve-agents/evolve-config). Deferred: docs-cache WebFetch adoption, Findings-Ledger validator script, changelog_normalize.py, shared Phase-0 template extraction, path-normalization mismatch vs evolve-agents (all cross-cutting, routed to Phase 2 / future Trial).

### Rename
No rename.

## 2026-07-11

### Summary
Operator-directed permanent doctrine change (not a self-review cycle): switched Phase 2 `coherence-reviewer` + Phase 3 `disambiguation-reviewer` from `staff-engineer`/opus to `distinguished-engineer`/fable, keeping symmetry with the same change just made in evolve-agents.

### Changes
- CHANGE: `coherence-reviewer` and `disambiguation-reviewer` subagent_type/model changed from `staff-engineer`/`opus` to `distinguished-engineer`/`fable` (Phase table, both Phase gate descriptions, both spawn templates).

### Dimensions Evaluated
Operator directive, applied verbatim. Kept symmetric with evolve-agents' identical change per the CANONICAL:EVOLUTION-MODEL shared vocabulary these two skills share.

### Rename
No rename.

## 2026-07-10

### Summary
Phase 2 coherence pass: aligned docs-paths master citation to the relocated team-doctrine reference. File remains ~3,352B over the 65,000 hard limit — same shared-doctrine-extraction candidate flagged for evolve-agents applies here too (operator-gated, not applied).

### Changes
- Docs-paths citation → `…/team-doctrine/references/docs-paths.md` (was team-lead.md §copy).

### Dimensions Evaluated
Cross-reference accuracy.

### Rename
No rename.

## 2026-07-10

### Summary
Removed redundant Phase 2 coherence steps 6-8 (mechanized by symmetry_check.py `--check all`) and fixed the stale top-level `skills/` root that made scope-detection blind to the 15 skills under `src/user/claude-code/skills/` (this cycle's own operator-corrected scope). Net -583 (68,832→68,249; still TRIM, drift-section consolidation pending Phase 2).

### Changes
- CULL: dropped Phase 2 steps 6-8 (innovation-scanner/model-routing/Mimir byte-symmetry checks), renumbered 9→6 — cited symmetry_check.py docstring "mechanizes checks 5-8" + innovation-scanner Retire finding. Parity-locked with evolve-agents (deferred to Phase 2 lockstep).
- CULL: fixed 2 `find .claude/skills skills` commands + 7 prose `skills/*/SKILL.md` refs → `src/user/claude-code/skills/*/SKILL.md` — cited this cycle's operator scope correction; the command silently missed all 15 non-evolve skills. Family-wide (evolve-agents, evolve-coherence share the same stale root — routed to Phase 2).
- DEFERRED (Phase 2, parity-locked with evolve-agents): consolidate the Genetic-Drift Operator prose (~2,352B, no measured usage benefit) — not applied unilaterally.

### Dimensions Evaluated
All 8. Over-Engineering (net -583, TRIM honored but still over budget). Rejected a CHANGELOG-cache addition as over-engineering (no persistent cache substrate; step already fails open).

### Rename
No rename.

## 2026-06-30

### Summary
Restored evolve-agents/evolve-skills symmetry for innovation and model-routing audit text.

### Changes
- AMPLIFY: innovation-scanner now uses the shared script-path skip/fail-open wording.
- AMPLIFY: model-routing auditor now matches the session JSON and Mimir discovery wording used by evolve-agents, with skill nouns substituted.

### Dimensions Evaluated
Phase 2 coherence.

### Rename
No rename.

## 2026-06-30

### Summary
Pre-flight pins the two Codex skill roots and Phase 1 budget honors prompted caps including the 535-line self-budget. Net 0.

### Changes
- AMPLIFY: pre-flight names `.codex/skills` and `src/user/codex/skills` as the only Codex skill roots — cited historical `find: skills: No such file or directory` abort.
- AMPLIFY: Phase 1 NET_LINES guidance now follows the prompted cap, including the 535-line evolve-skills self-budget — cited self-review budget mismatch.

### Dimensions Evaluated
All 8.

### Rename
No rename.

## 2026-06-30

### Summary
Fixed the live zsh-nomatch glob-abort across all 4 inventory/changelog glob sites (reproduced this cycle: a missing top-level `skills/` root aborted pre-flight discovery and `2>/dev/null` does not suppress nomatch) and added a last-run preamble so re-running isn't the only way to confirm prior completion. Net -1 (534→533).

### Changes
- CULL: replaced 4 `*/SKILL.md`/`*.md` globs (pre-flight steps 4 & 7, Phase 4 gate, wrap-up step 2) with `find … -maxdepth 2 -name … -exec wc -l {} + 2>/dev/null` — cited HISTORICAL BUG, reproduced live (zsh aborts mid-discovery, yielding zero inventory).
- AMPLIFY: pre-flight step 7 now surfaces `Last evolve-skills changelog entry: <date>` — cited HISTORICAL signal (3 same-day re-runs were the only way to confirm prior completion); also collapses 2 lines to 1.
- AMPLIFY: Phase 1 template `Read(limit=80)` → ranged Read of the relevant section — cited INNOVATION (the 80-line cap predates the 1M-context default and can hide a cross-file contract past line 80).

### Dimensions Evaluated
All 8. Over-Engineering: net -1 (TRIM honored, 533/535). No model/routing/drift changes (none data-justified, operator hard-gate). No unescaped `$`+digit. Phase-2 deferrals: glob-abort family propagation; report-only auditor conversion.

### Rename
No rename.

## 2026-06-20

### Summary
Phase 2 (self-edit): pinned model= (aliases) on all 8 Agent() spawns + added a $TMPDIR scratch guard to the shell-heavy auditor Rules. In-line edits, no line growth (stays 534, at self-budget).

### Changes
- AMPLIFY: pinned `model=` on every Agent() spawn — sonnet (docket/historical/model-routing auditors) / opus (docs-researcher, innovation-scanner, review-<name>, coherence-reviewer, disambiguation-reviewer). Cited the dispatch-defect rule; operator-approved per-tier pinning.
- AMPLIFY: appended a `$TMPDIR`-not-`/tmp` scratch guard to the historical-auditor + model-routing-auditor Rules lines — cited the /tmp run ERROR.

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
Phase 2 coherence pass: concrete stall threshold added to stall-detect line, biodiversity CANONICAL-tag correctness cull (lockstep with evolve-agents). Parity checks 5-9 all CLEAN.

### Changes
- AMPLIFY: added "≥2 turns with no new tool call is stall evidence" to stall-detect line — concretizes abstract trigger.
- CULL: removed "CANONICAL tag" from biodiversity niche-token filter — matches every family carrier, defeats monoculture guard (correctness defect; lockstep with evolve-agents).

### Dimensions Evaluated
Coherence (stall threshold, biodiversity correctness defect).

### Rename
No rename.

## 2026-06-19

### Summary
Drift: Changelog-Format read-latest clause reworded (seed 6f0ab504, pick 5) → applied. Drift: Crash & Stall "Re-spawn ONCE" bullet reworded (pick 6) → applied. BUG fix (docket-auditor scope), 2 wording AMPLIFYs, day= alias folded net-zero. File stays 498/500.

### Changes
- CULL: docket-auditor cross-reference `agents/` → `.claude/skills/` and `skills/` — copy-paste artifact from evolve-agents; evolve-skills never audits agents/ (confirmed via DOCS-PATHS-LOCAL).
- AMPLIFY: Phase 1 template "first ~80 lines only" → explicit `Read(limit=80)` — machine-followable constraint.
- AMPLIFY: Phase 2 task 4 "SendMessage trigger gaps between dependent skills" → "orchestrator-to-teammate SendMessage trigger completeness" — skills don't message each other.
- AMPLIFY: accept `day=N` as alias for `days=N` in Argument Handling and Parsing (this session's `/evolve-skills day=7` would abort under prior parsing).
- DRIFT: Changelog-Format read-latest clause reworded — neutral, pick 5, net 0.
- DRIFT: Crash & Stall "Re-spawn ONCE" → "Re-spawn exactly once" — neutral, pick 6, net 0.

### Dimensions Evaluated
All 8; Coherence (BUG fix, Phase 2 task-4 accuracy); Actionability (Read(limit=80), day= alias); Over-Engineering (net 0). Parity: docket-auditor template is NOT byte-symmetry-bound with evolve-agents (scope correctly differs).

### Rename
No rename.

## 2026-06-10

### Summary
Phase 2 coherence (lockstep with evolve-agents): Phase 1 apply step 2 gains Read-before-Edit, re-Read-after-grep/mv, and 1:1 Edit↔CHANGE apply-discipline. Line-neutral (498 lines, appended to the existing step-2 line); post-apply byte-identity verified (sort -u = 1 line across both files).

### Changes
- AMPLIFY: apply step 2 — in-session Read-before-Edit, re-Read after grep/mv targeting content strings, one Edit per approved CHANGE — cited signal: two re-fired team-lead pitfalls ("File has not been read yet" ×2 in 2026-06-09 cycle; stray [MARKER-KEEP] token).

### Dimensions Evaluated
Coherence (lockstep pair byte-identical), Completeness (apply-discipline gaps closed), budget (498/500 unchanged). Checks 5-9 all PASS (HARVEST/innovation/model-routing/Mimir parity; drift heading exempt as approved).

### Rename
No rename.

## 2026-06-10

### Summary
Drift: heading "Phase 0: Historical Audit (per-skill)" → "(one block per target skill)" (seed 124bf552, i=229) → applied, net 0.
Drift: DOCS-PATHS-LOCAL Reads-list reorder (seed 124bf552, i=230) → proposed (operator declined — CANONICAL-maintained block).
No reviewer edits (498 lines, net 0). Clean audit (0 corrections/errors/stalls). Dimension-5 cost-tier routing NO-OP: no skill pins model= in templates (grep-confirmed); routing is team-lead.md's authority; fable-monoculture already fixed at routing layer (90a3694).

### Changes
- None applied beyond drift. Parity-bound apply-discipline gaps (Read-before-Edit after grep/mv, 1:1 Edit↔CHANGE guard, $N live-command exemption) routed to Phase 2 lockstep with evolve-agents, gated on family-wide offset (498/500).

### Dimensions Evaluated
All 8; Over-Engineering primary (no CULL earns a cited signal; drift/trial traits unmeasured → RETAIN); Orchestration (Dimension 5 verified NO-OP); Coherence (3 parity-bound gaps → Phase 2).

### Rename
No rename.

## Compacted history

Entries below were compacted per ADR 0001; full text in git history (see the compaction entry's date).

- 2026-06-04: Fixed live `/evolve-skills days=7` all-skills pattern — pre-flight guards no longer treat `days=N` as skill name; Parsing rule strips window token first; net +2.
- 2026-06-05: Trimmed redundant Phase 1 reviewer read-list recap from template-forwarding sentence (already verbatim in spawning template); net 0; symmetric with evolve-agents.
- 2026-06-08: Trimmed historical-auditor "never bulk-cat ~/Development" clause (duplicated in CANONICAL:HARVEST); net 0 in-line shorten; parity-bound with evolve-agents.
- 2026-06-09: NO-OP Phase 1 (360 lines) — 4 parity-bound items routed to Phase 2; headline: correction-regex FP guard excludes teammate-message/command-output turns.
- 2026-06-09: Phase 2 — historical-auditor FP guard, budget-truth wording mirrored from evolve-agents, WebFetch added to allowed-tools; Coherence + Actionability.
- 2026-06-09: Three mid-run-safe additions (360→359): docs-researcher repo-adoption grep gate, Phase-1 $-escape reviewer flag, rename-sweep LIVE-file scoping; 2 parity-bound with evolve-agents.
- 2026-06-09: NO-OP Phase 1 (378 lines) — `\$ARGUMENTS` escape routed to Phase 2 lockstep; harness-redundant Read-before-Edit prose rejected; $+digit audit clean.
- 2026-03-19: Added Pre-flight section with 5 validation steps; WebFetch graceful degradation; argument matching for both skill paths.
- 2026-03-19: Closed date passthrough gap — {today_date} added to Phase 1/2 spawning templates.
- 2026-03-19: Added allowed-tools frontmatter; trimmed Phase 0 output scaffolding; consolidated orchestrator-only-edits statements.
- 2026-03-19: Restored Phase 0 output format bullets for evolve-agents alignment; added TeamCreate/TeamDelete to allowed-tools.
- 2026-03-19: Condensed Argument Handling 16→4 lines; removed generic agent SDK boilerplate (499→485).
- 2026-03-20: Added effort: high; trimmed Phase 2 preamble; fixed TaskCreate/TaskUpdate/TaskList parameter names; rejected Phase 0 removal.
- 2026-03-20: Trimmed Phase 0 template verbosity; consolidated changelog rules; $ARGUMENTS reference added.
- 2026-03-20: Fixed docket vote start → docket vote create; Phase 1 template back-references Content Gate and dimensions; context: fork added.
- 2026-03-20: Removed phantom ToolSearch step; consolidated docket audit template; rejected context: fork (breaks agent teams).
- 2026-03-21: Added observability report to Wrap-up (cross-communication, votes, course-corrections); expanded Dimension 1 frontmatter checks.
- 2026-03-29: Trimmed over-engineered content; immediate per-agent Phase 1 shutdown; effort high→max; docs-researcher template 25→6 lines.
- 2026-03-30: Added honest-mentor directives to orchestrator identity and Phase 1 template; consolidated Fail-loud + timeout rules.
- 2026-03-30: Trimmed description 758→~185 chars; removed duplicate experience-feedback section; fixed shutdown syntax.
- 2026-04-06: Added anti-sub-agent-spawning instructions at orchestrator, Phase 1, and Phase 2 levels; removed vote invocations from wrap-up.
- 2026-04-16: Removed dead {focus_areas} variable; Over-Engineering promoted to HIGHEST PRIORITY in main dimension list.
- 2026-04-16: Centralized Agent Lifecycle rules; explicit Phase 1 SendMessage triggers; Phase 2 handoff gate; removed duplicate rules (328→316).
- 2026-04-22: Hardened crash recovery: Rule #10 stall/crash signals, shutdown-timeout fail-forward, single re-spawn (316→313).
- 2026-05-04: Trim pass: orchestrator-identity restatements, vague Rule #12 removed, consolidated Pre-flight inventory steps (313→304).
- 2026-05-05: Adopted paths: frontmatter and Monitor tool; merged critical-rules blockquotes; concrete Phase 1→2 cross-cutting handoff (304→303).
- 2026-05-05: Eliminated free-text operator prompts in favor of structured AskUserQuestion; operator-prompts blockquote added (299→314).
- 2026-05-05: Trimmed Pre-flight AskUserQuestion verbosity; justified no-peer-to-peer policy; lifecycle table for evolve-agents parity (314→295).
- 2026-05-05: Phase 2 coherence: inlined Argument Handling validation note for evolve-agents parity.
- 2026-05-06: Removed unverified disable-model-invocation from Dimension 1; docs-researcher template asymmetry trimmed; mode threshold tightened (295→288).
- 2026-05-06: Phase 1 aligned with evolve-agents: Crash & Stall Recovery section extracted, multiSelect Pre-flight step 2, numbered post-review loop.
- 2026-05-06: Rules section collapsed 10→4 (duplicates of CRITICAL block, ordering, Changelog Format, Content Gate); Phase 2 ## Task parity (294→287).
- 2026-05-07: Phase 2 coherence: /evolve-skills dev example changed to tdd — dev skill deleted earlier this cycle.
- 2026-05-07: Self-evolution trim: collapsed orchestrator identity block, removed Self-evolution blockquote, trimmed Dimension 5 (287→278).
- 2026-05-09: Trimmed Phase 1 template Context self-referencing bullets; Pre-flight step 1 forward-reference removed (278→275).
- 2026-05-09: Inlined 8 evaluation dimensions in Phase 1 reviewer template; paths: declared; Size Budget block restored.
- 2026-05-09: Seven trim + parity fixes: CANONICAL banner markers, stale paths reference dropped, Wrap-up numbered list (net -8).
- 2026-05-13: Collapsed top-level Evaluation Dimensions to a pointer; operator-prompts blockquote reordered; Dimension 4 wording restored (290→282).
- 2026-05-13: Removed orphan Evaluation Dimensions pointer block entirely — dimensions live in Phase 1 template (net -6).
- 2026-05-16: Wired friction-driven-evolution payload contract end-to-end; cross-root collision handling; removed duplicate Rule 1.
- 2026-05-16: Operator-prompts banner extended with multiSelect+fixed-catalog carve-out to match 6-option step 2 usage.
- 2026-05-17: Corrected false multiSelect-lifts-4-option-cap carve-out (API hard-rejects >4, verified live); step 2 collapsed to 4 options.
- 2026-05-17: Phase 2 sister-parity trim: condensed Phase 1 template Size Budget block from 2 lines to 1 line, matching evolve-agents' equivalent trim applied earlier this...
- 2026-05-18: Closed the historical-auditor ISO→epoch-ms conversion gap that produced the wrong cutoff (1808066891000 = 2027-04-18 instead of 2026-04-18) in this cycle's a...
- 2026-05-20: Two sister-parity trims (Phase 1 Context clause restating section headers below; Phase 0 Distinction-from-friction negative-form tail duplicating affirmative...
- 2026-05-25: Five changes: trimmed Phase 1 post-review-loop shutdown bullet (duplicates lifecycle table), trimmed orchestrator-identity workflow restatement, bolded Phase...
- 2026-05-28: Phase 2 coherence: added "Always run Phase 2" parity rule (matching evolve-agents Rule 1), consolidated SKIPPED-skip guidance in tandem with evolve-agents (4...
- 2026-05-28: Closed coordination/handoff gaps: de-dup transcript counts in the historical-auditor (raw grep hits ~10x inflated by replication), made the re-invocation sig...
- 2026-05-29: Added a scope-confirmation HARD GATE to Pre-flight (new step 9), achieving parity with evolve-agents step 7 (Phase 2 coherence).
- 2026-05-30: Added a Phase-0-findings-are-signals-not-facts rule to the Phase 1 template, governing both the Docket CLI and Historical audit blocks — closes the recurring...
- 2026-06-09: Phase 2 parity fix — escaped 5 documentary `\$ARGUMENTS` occurrences, lockstep with evolve-agents; net 0 (378 lines).
- 2026-06-09: Compacted 35 entries (2026-03-19..2026-05-17) into Compacted history per ADR 0001.
- 2026-06-10: No edits (491 lines) — days= plumbing complete; 3 innovation suggestions rejected as over-engineering/regression.
- 2026-06-10: Compacted 8 entries (2026-05-17..2026-05-30) into Compacted history per ADR 0001.
- 2026-06-10: Introduced evolutionary-theory core — CANONICAL:EVOLUTION-MODEL, selection dispositions, Genetic-Drift Operator, Scientific Trial Protocol.
