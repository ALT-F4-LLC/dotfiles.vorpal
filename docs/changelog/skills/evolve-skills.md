# Changelog: evolve-skills

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

## 2026-06-09

### Summary
No Phase-1 edits (378 lines, net 0). Two parity-bound items routed to Phase 2: escape documentary `\$ARGUMENTS` (L51/57/67/77/217 — substitution empirically confirmed to occur inside backticks) and optional NO-OP-grep-citation hardening (orchestrator declined: grep already mandated, citation-only gain is marginal).

### Changes
- None applied in Phase 1; `\$ARGUMENTS` escape routed to Phase 2 lockstep with evolve-agents (parallel lines).

### Dimensions Evaluated
All 8; Over-Engineering primary (rejected harness-redundant Read-before-Edit prose); $+digit self-audit clean (L307 gate correctly escaped).

### Rename
No rename.

## 2026-06-09

### Summary
Three mid-run-safe additions (360→359, net −1 via offset), two parity-bound with evolve-agents: docs-researcher repo-adoption grep gate, Phase-1 $-escape reviewer flag, rename-sweep LIVE-file scoping.

### Changes
- docs-researcher MISSION: grep local ADOPTION before asserting current-repo state. PARITY-BOUND with evolve-agents (clause parity verified at apply).
- Phase-1 Content Gate line: flag unescaped `\$`+digit in documentary prose (examples escaped at apply time). PARITY-BOUND.
- Phase-2 prose: rename reference updates scoped to live def files (skills/, .claude/skills/, agents/), never changelogs/pitfalls/prose.
- Offset: historical-auditor rules bullets collapsed (2 lines → 1).

### Dimensions Evaluated
All 8. Over-Engineering: net −1. Coherence: lockstep with evolve-agents. HARVEST byte-parity intact. Reasoning-echo clean.

### Rename
No rename.

## 2026-06-09

### Summary
Phase 2: historical-auditor correction-regex FP guard; budget-truth wording mirrored from evolve-agents; WebFetch added to allowed-tools (lockstep).

### Changes
- Auditor template: correction-phrase scan now matches only operator-typed turns (skip teammate-message/command/tool_result echoes) — 3 consecutive audits were FP-dominated.
- Phase 1 Size Budget + orchestrator step 2 adopt evolve-agents' physical-newline / post-apply wc -l wording (restores symmetry).
- allowed-tools gains WebFetch (pre-flight step 10 prefers it; byte-identical with evolve-agents).

### Dimensions Evaluated
Coherence (cross-pipeline symmetry), Actionability (audit precision).

### Rename
No rename.

## 2026-06-09

### Summary
No direct changes (360 lines, net 0). All four findings touch text shared near-verbatim with sister evolve-agents (correction-regex FP fix, Phase 1 Size Budget drift, shared allowed-tools line, step-4 semantics duplication) — routed parity-bound to Phase 2 for lockstep application.

### Changes
- None applied in Phase 1; 4 parity-bound items routed to Phase 2 (headline: historical-auditor operator-correction regex excludes teammate-message/command-output turns — 3 consecutive FP-dominated audits).

### Dimensions Evaluated
All 8. Over-Engineering (HIGHEST): only residual duplication is sister-shared — Phase 2. Spec Alignment vacuous: docs/spec/ does not exist in this repo. $-escape audit clean; when_to_use/paths/disallowed-tools adoption rejected with reasons.

### Rename
No rename.

## 2026-06-08

### Summary
One redundancy trim (360 lines, net 0 — in-line shorten). Trimmed the historical-auditor Rules bullet's trailing "never bulk-cat ~/Development" clause — verbatim-duplicated in the same template's CANONICAL:HARVEST block (the auditor reads both; clause survives in HARVEST, no info lost). Kept the unique transcript-scan half. Parity-bound; applied identically to evolve-agents in one lockstep turn.

### Changes
- Phase 0 historical-auditor Rules: dropped duplicated cross-project-scan clause from the per-skill-grep bullet. PARITY-BOUND with evolve-agents.

### Dimensions Evaluated
Over-Engineering (HIGHEST — sole finding; governance/parity blocks correctly retained), Coherence (sister evolve-agents parity; CANONICAL:HARVEST byte-identical post-edit). Phase 0 signals NO-OP.

### Rename
No rename.

## 2026-06-05

### Summary
Trimmed the redundant reviewer read-list recap from the Phase 1 workflow prose — the template-forwarding sentence restated the read-list + 8-dimension mandate already verbatim in the Phase 1 spawning template (L268/L285). Net 0 (one-line shorten). Symmetric trim applied to evolve-agents.

### Changes
- Phase 1 workflow: shortened "...follows the Phase 1 spawning template below — reads [read-list], then evaluates ALL 8 dimensions and reports" to "...follows the Phase 1 spawning template below." Content-Gate non-redundant fix. All Phase 0 signals verified NO-OP (optional-token parse, frontmatter-adoption gate, docket guard, $-escape — already encoded or correctly absent).

### Dimensions Evaluated
Over-Engineering (HIGHEST — sole redundancy; dense incident-prevention blocks correctly retained), Coherence (symmetric trim vs evolve-agents; CANONICAL:BANNER/HARVEST byte-identical). All Phase 0 signals NO-OP.

### Rename
No rename.

## 2026-06-04

### Summary
Fixed the live `/evolve-skills days=7` all-skills pattern, which the pre-flight guards (steps 5, 9) silently broke by treating the `days=N` window token as a skill name. Net +2.

### Changes
- Argument Handling: added a Parsing rule — strip `days=N` FIRST; a remaining non-`days=` token is the skill name. Root-cause fix.
- Step 5 guard: "If a skill-name token is present" (was "If targeting a specific skill") — no longer mis-fires on `days=7`.
- Step 9 scope HARD GATE: triggers on "no skill-name token (all-skills mode)" (was "$ARGUMENTS empty") — the gate now fires for `/evolve-skills days=7`, the heaviest cycle it protects.

### Dimensions Evaluated
Completeness + Coherence (live-operator-path defect, root-cause fix), Over-Engineering (HIGHEST — +2 at 347/500; guard rewordings net-0).

### Rename
No rename.

## Compacted history

Entries below were compacted per ADR 0001; full text in git history (see the compaction entry's date).

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
