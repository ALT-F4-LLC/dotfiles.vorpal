# Changelog: evolve-skills

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

## 2026-06-10

### Summary
Introduced evolutionary-theory core: CANONICAL:EVOLUTION-MODEL block (genome/trait/fitness-signal vocabulary), natural-selection dispositions (AMPLIFY/CULL/RETAIN), Genetic-Drift Operator (fitness-independent neutral substitution, skill-path grep for no-signal-set, `drift=N` parameter), Scientific Trial Protocol (hypothesis → operator-approval HARD GATE → measure → adopt-or-rollback), biodiversity invariant, and speciation gate. CANONICAL:EVOLUTION-MODEL byte-identical across evolve-agents/evolve-skills/evolve-coherence (hash e9ef8d09).

### Changes
- CANONICAL:EVOLUTION-MODEL block added (Phase A); byte-identical across all three evolve-* carriers.
- Innovation Mandate updated to cite three variation sources: innovation-scanner, historical-auditor, genetic-drift operator.
- Genetic-Drift Operator section added: structural no-signal-set via `grep` over `<skill-path>/SKILL.md`, `{drift_seed} mod len(set)` target selection, S2 reproducibility caveat.
- Scientific Trial Protocol added: Hypothesis → operator approval → measurement → adopt-or-rollback; `Trial:`/`Drift:` changelog recording.
- Selection disposition rule added to Phase 1 template (AMPLIFY/CULL require cited fitness signal; RETAIN is default).

### Dimensions Evaluated
Coherence (EVOLUTION-MODEL family parity, D4 0 Blockers); Completeness (selection dispositions, drift operator, trial protocol coverage); Skill Design Quality (structural target selection, determinism caveat).

### Rename
No rename.

## 2026-06-10

### Summary
Compacted 8 entries (2026-05-17..2026-05-30) into Compacted history per ADR 0001.

### Changes
- Replaced the 8 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per ADR 0001, not a review cycle.

### Rename
No rename.

## 2026-06-10

### Summary
No edits (491 lines, net 0). All Phase 0 signals verified to no-change: `days=` plumbing complete (L8/55-57/77-79, incl. all-skills `days=`-only path); three innovation suggestions rejected (audit-profile gate = over-engineering near cap; shared enumeration = breaks parallelism; Phase-3 scoped wc = correctness regression vs ADR 0001 standing budget).

### Changes
- None applied. Innovation-scanner template confirmed byte-symmetric with evolve-agents (modulo established noun substitutions).

### Dimensions Evaluated
All 8. Over-Engineering primary (rejected all 3 additions on a 491-line near-cap file). Coherence: innovation-scanner sister parity verified PASS; $-escape clean.

### Rename
No rename.

## 2026-06-09

### Summary
Compacted 35 entries (2026-03-19..2026-05-17) into Compacted history per ADR 0001.

### Changes
- Replaced the 35 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per ADR 0001, not a review cycle.

### Rename
No rename.

## 2026-06-09

### Summary
Phase 2 parity fix: escaped 5 documentary `\$ARGUMENTS` occurrences (L51/57/67/77/217) in Argument Handling + Pre-flight prose. Backtick code spans do NOT exempt substitution (empirically confirmed: `days=1` substituted inside backticks this cycle) — bare occurrences rendered empty/wrong at invocation. Net 0 (378 lines).

### Changes
- L51/57/67/77/217: backticked `$ARGUMENTS` → `\$ARGUMENTS` in documentary prose; L307 meta-rule already escaped, untouched. Lockstep with evolve-agents.

### Dimensions Evaluated
Skill Design Quality (arg-escape correctness); Coherence (sister parity; CANONICAL:HARVEST byte-symmetry verified PASS).

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
