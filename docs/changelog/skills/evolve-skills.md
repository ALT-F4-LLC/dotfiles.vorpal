# Changelog: evolve-skills

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

## 2026-05-30

### Summary
Added a Phase-0-findings-are-signals-not-facts rule to the Phase 1 template, governing both the Docket CLI and Historical audit blocks — closes the recurring fabricated-"verified"-finding failure class. Net +1.

### Changes
- Phase 1 template: new blockquote above the historical-prioritization line — Phase 0 audit findings (Docket commands, frontmatter fields, feature claims) are SIGNALS-TO-VERIFY against ground truth (--help, Grep/Read) before any CHANGE relies on them; a change built on a fabricated finding is reject-class. Byte-symmetric version applied to evolve-agents this cycle for sibling parity.

### Dimensions Evaluated
Actionability + Completeness (incident-class root-cause fix), Over-Engineering (HIGHEST — +1 at 359/500 justified), Coherence (symmetric placement vs evolve-agents; HARVEST blocks byte-identical).

### Rename
No rename.

## 2026-05-29

### Summary
Added a scope-confirmation HARD GATE to Pre-flight (new step 9), achieving parity with evolve-agents step 7 (Phase 2 coherence).

### Changes
- New Pre-flight step 9: in standalone all-skills mode with >3 skills, surface planned scope + total line count via AskUserQuestion before committing (skips in single-skill and team mode). Closes a real gap — step 1 is a routing question that runs before inventory and cannot show cycle weight; all-skills mode (~13 skills) is the heaviest cycle yet had no cost checkpoint. Placed as step 9 to avoid renumbering the step-8 reference. Net +1 (327→328; BALANCED, well under 500). [Phase 2 coherence item 6b]

### Dimensions Evaluated
Sibling-skill parity; operator-prompt safety; over-engineering skepticism (no-op in team mode; value concentrated in standalone all-skills).

### Rename
No rename.

## 2026-05-28

### Summary
Phase 2 coherence: added "Always run Phase 2" parity rule (matching evolve-agents Rule 1), consolidated SKIPPED-skip guidance in tandem with evolve-agents (4×→2×), and added the shutdown-idiom clarifying note. Net +1.

### Changes
- New Rule 1 "Always run Phase 2 — even for single-skill improvements" (parity with evolve-agents).
- "skip historical-auditor if SKIPPED" consolidated 4×→2× (removed table parenthetical + template-header sentence).
- One-line note: orchestrator-originated shutdown is intentional vs leaf-review self-initiate (`agents/team-lead.md` Rule 7).

### Dimensions Evaluated
Coherence, Over-Engineering (consolidation), Completeness (Phase 2 guarantee).

### Rename
No rename.

## 2026-05-28

### Summary
Closed coordination/handoff gaps: de-dup transcript counts in the historical-auditor (raw grep hits ~10x inflated by replication), made the re-invocation signal replication-safe, and added a Phase 0-auditor crash→placeholder rule so Phase 1 templates never get dangling substitutions. Offset by trimming the triple-stated friction distinction. Net -1.

### Changes
- Historical-auditor template: added "De-dupe before counting" bullet — report DISTINCT `sessionId` counts, not raw line hits.
- Re-invocation signal: count DISTINCT invocation events (UUID/timestamp), not replicated lines — prevents false ≥2 signals.
- Crash & Stall "Second failure": Phase 0 auditors now substitute an `UNAVAILABLE` placeholder for their findings token so Phase 1 templates stay valid.
- Removed redundant workflow-narrative friction distinction — template preamble (line 182) + rule (line 224) already carry it.

### Dimensions Evaluated
Orchestration (handoff/crash-substitution), Actionability (de-dup), Over-Engineering (HIGHEST — offset trim), Coherence.

### Rename
No rename.

## 2026-05-25

### Summary
Five changes: trimmed Phase 1 post-review-loop shutdown bullet (duplicates lifecycle table), trimmed orchestrator-identity workflow restatement, bolded Phase 1 "spawn all in same turn" pattern, trimmed Phase 0 "scoped here" wrap-clause, clarified shutdown-response routing to orchestrator (mirrored from evolve-agents). Net -3 lines.

### Changes
- Phase 1 post-review loop step 6: removed — duplicates lifecycle table row 1.
- Orchestrator identity: dropped TeamCreate/spawn workflow restatement — duplicates Team Setup + Phase 1 template.
- Phase 1 spawn instruction: bolded "**Spawn all in the same turn**" for evolve-agents parity.
- Phase 0 friction-distinction: removed "scoped to the skills under review here" wrap.
- Shutdown protocol: added "addressed to the orchestrator (never to a peer)" clause — mirrored from evolve-agents per team-lead pitfall on routing ambiguity.

### Dimensions Evaluated
Over-Engineering (HIGHEST — trim x3), Coherence (sister evolve-agents parity x2), Orchestration (routing clarity).

### Rename
No rename.

## 2026-05-20

### Summary
Two sister-parity trims (Phase 1 Context clause restating section headers below; Phase 0 Distinction-from-friction negative-form tail duplicating affirmative clause) plus cross-cutting `${history_days}` shell-var leak fix in Phase 0 historical-auditor template (same defect identified in sister evolve-agents). Net 0 lines (text-internal rewording).

### Changes
- Phase 1 template Context: dropped `and apply the docs research / docket audit findings below` — section headers within 3-9 lines below prompt application; fails Behavioral check.
- Phase 0 Distinction-from-friction: dropped `— no clustering, no routing` tail — implied by `feeds Phase 1 reviewers directly`; fails Non-redundant check.
- Phase 0 historical-auditor template: `-mtime -${history_days}` → `-mtime -{history_days}` — sister-cross-cutting defect; orchestrator substitutes `{...}` not `${...}`.

### Dimensions Evaluated
Over-Engineering (HIGHEST — trim x2), Coherence (sister evolve-agents parity x3), Skill Design Quality (defect fix).

### Rename
No rename.

## 2026-05-18

### Summary
Closed the historical-auditor ISO→epoch-ms conversion gap that produced the wrong cutoff (1808066891000 = 2027-04-18 instead of 2026-04-18) in this cycle's audit. Pre-flight now computes both `{history_cutoff_iso}` and `{history_cutoff_epoch_ms}`; historical-auditor template substitutes the epoch-ms value directly instead of asking the auditor to convert inline. Net +2 lines.

### Changes
- Pre-flight step 8: compute `{history_cutoff_epoch_ms}` alongside `{history_cutoff_iso}` (macOS/Linux Bash commands) so the auditor never has to convert.
- Phase 0 historical-auditor template header: include `epoch-ms {history_cutoff_epoch_ms}` alongside the ISO cutoff.
- Phase 0 historical-auditor template step 2: replace `epoch-ms of {history_cutoff_iso}` with direct `{history_cutoff_epoch_ms}` substitution.

### Dimensions Evaluated
Completeness (HIGHEST), Actionability, Skill Design Quality, Over-Engineering.

### Rename
No rename.

## 2026-05-17

### Summary
Phase 2 sister-parity trim: condensed Phase 1 template Size Budget block from 2 lines to 1 line, matching evolve-agents' equivalent trim applied earlier this cycle. Net -1 line; no behavioral change.

### Changes
- Phase 1 template Size Budget: collapsed 2-line restatement to 1 line. Restores byte-parity with sister evolve-agents Phase 1 template.

### Dimensions Evaluated
Over-Engineering (HIGHEST), Coherence (sister evolve-agents parity).

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
