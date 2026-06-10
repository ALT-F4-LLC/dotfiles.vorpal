# Changelog: evolve-agents

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

## 2026-06-09

### Summary
Full-cycle audit (1-day window): NO changes. Both historical focus areas verified already-encoded via fresh grep: docs-researcher ADOPTION grep gate (L174) and post-apply re-wc/NET_LINES-untrusted rule (L134), both byte-parity with evolve-skills.

### Changes
- None (NO-OP verdict). Documentary `$ARGUMENTS` escaping question (L48/54/64/73/198) routed to Phase 2, parity-bound with evolve-skills.

### Dimensions Evaluated
All 8; Over-Engineering primary (no bloat at 368 lines); Coherence (CANONICAL:BANNER + HARVEST byte-parity confirmed with evolve-skills).

### Rename
No rename.

## 2026-06-09

### Summary
Three mid-run-safe gate additions (368→367, net −1 via offset): docs-researcher repo-adoption grep gate, Phase-1 $-escape reviewer flag, rename-sweep LIVE-file scoping.

### Changes
- docs-researcher MISSION: grep local ADOPTION before asserting current-repo state (doc existence ≠ adoption) — fixes prior false "agents use no optional fields" assertion. PARITY-BOUND, mirrored to evolve-skills lockstep (clause parity verified).
- Phase-1 Content Gate line: flag unescaped `\$`+digit in documentary prose (renders empty; examples escaped at apply time — reviewer's originals were self-violating). PARITY-BOUND.
- Phase-2 rename step: reference updates scoped to live def files (agents/, skills/, .claude/skills/), never changelogs/pitfalls/prose.
- Offset: historical-auditor rules bullets collapsed (2 lines → 1).

### Dimensions Evaluated
All 8. Over-Engineering: net −1. Coherence: 2 parity-bound applied lockstep. HARVEST byte-parity preserved. Reasoning-echo clean.

### Rename
No rename.

## 2026-06-09

### Summary
Phase 2: historical-auditor correction-regex FP guard (lockstep with evolve-skills); WebFetch added to allowed-tools (lockstep).

### Changes
- Auditor template: correction-phrase scan now matches only operator-typed turns; mirror clause preserved.
- allowed-tools gains WebFetch (byte-identical with evolve-skills).

### Dimensions Evaluated
Coherence (cross-pipeline symmetry), Actionability.

### Rename
No rename.

## 2026-06-09

### Summary
Codified the TRIM-mode budget lesson from team-lead pitfalls (claimed −10 vs actual −2 on a prior cycle): NET_LINES is the physical-newline `wc -l` delta, and the orchestrator's post-apply `wc -l` is the only budget truth. Net 0.

### Changes
- Phase 1 template Size Budget: NET_LINES defined as physical-newline (`wc -l`) delta, not soft-wrapped display lines; whole bullet/list-line removals move the count.
- Orchestrator post-review step 2: post-apply `wc -l` is the only budget truth — reviewer estimates untrusted; a still-over-budget file is not-done. PARITY: mirror both to evolve-skills in Phase 2.

### Dimensions Evaluated
All 8. Over-Engineering (HIGHEST): both changes net 0 in-place. Coherence: correction-regex FP fix + allowed-tools WebFetch routed to Phase 2 as parity-bound. No unescaped `$`+digit; frontmatter sound.

### Rename
No rename.

## 2026-06-08

### Summary
Two redundancy trims (368 lines, net -2). Phase 1: removed a per-agent narration line (~L113) that restated the auditor's binding "stay per-agent" rule and an already-implied "feeds Phase 1" fact, resolving an asymmetry vs evolve-skills. Phase 2 (lockstep with evolve-skills): trimmed the historical-auditor Rules bullet's trailing "never bulk-cat ~/Development" clause — verbatim-duplicated in the same template's CANONICAL:HARVEST block (clause survives there; no info lost).

### Changes
- Phase 0 §: removed redundant per-agent narration line.
- Phase 0 historical-auditor Rules: dropped duplicated cross-project-scan clause; kept the unique transcript-scan half. PARITY-BOUND — applied identically to evolve-skills.

### Dimensions Evaluated
Over-Engineering (HIGHEST — both findings redundancy), Coherence (sibling parity verified; BANNER/HARVEST byte-identical post-edit). Other dimensions sound; DISTINCT-sessionId + $TMPDIR focus items NO-OP/N-A.

### Rename
No rename.

## 2026-06-05

### Summary
Symmetric trim (paired with evolve-skills): removed the redundant reviewer read-list recap from the Phase 1 workflow prose (L112) — the read-list + 8-dimension mandate already live verbatim in this skill's Phase 1 template (L264/L280). Net 0 (one-line shorten). The 8-dimension review otherwise found all signals NO-OP.

### Changes
- Phase 1 workflow: shortened the template-forwarding sentence to drop the duplicated read-list / 8-dimension recap. Content-Gate non-redundant fix, parity with evolve-skills. (Optional-token parse + audit-resolution verification already encoded; CANONICAL:BANNER/HARVEST verified byte-identical with evolve-skills; no `$`+digit present.)

### Dimensions Evaluated
Over-Engineering (HIGHEST — sole redundancy), Coherence (symmetric with evolve-skills). Remaining dimensions sound; all Phase 0 signals NO-OP.

### Rename
No rename.

## 2026-06-04

### Summary
Fixed the `days=N` argument parse defect (parallel to the evolve-skills fix): the all-agents scope HARD GATE and inventory validation no longer mis-fire on a bare `days=N` invocation.

### Changes
- Added a **Parsing:** rule to Argument Handling: strip `days=N` first; the remaining token is the agent name.
- Reworded pre-flight step 5 to key on "agent-name token present" instead of `$ARGUMENTS` set.
- Reworded pre-flight step 7 scope gate to "no agent-name token (all-agents mode)" so the HARD GATE runs on `/evolve-agents days=N`.

### Dimensions Evaluated
Coherence (cross-skill parse parity with evolve-skills), Completeness (scope-gate coverage), Actionability.

### Rename
No rename.

## 2026-05-30

### Summary
Two changes: closed a sibling-asymmetric "Second failure" recovery gap (Phase 0 auditor fallback), and added the Phase-0-findings-are-signals-not-facts rule to the Phase 1 template (byte-symmetric with evolve-skills). Net +1.

### Changes
- Crash & Stall Recovery "Second failure": added the Phase 0 auditor branch — substitute "UNAVAILABLE: <name> failed twice" for the findings token so Phase 1 templates stay valid when an auditor double-fails (parity with evolve-skills).
- Phase 1 template: new blockquote above the prioritization line — Phase 0 audit findings (Docket commands, frontmatter fields, feature claims) are SIGNALS-TO-VERIFY against ground truth before any CHANGE relies on them; a change built on a fabricated finding is reject-class. Byte-symmetric with evolve-skills (cross-cutting coherence).

### Dimensions Evaluated
Completeness (recovery-path gap + fabrication-class fix), Coherence (sibling parity w/ evolve-skills; HARVEST blocks verified byte-identical), Orchestration, Over-Engineering (HIGHEST — minimal net).

### Rename
No rename.

## 2026-05-29

### Summary
Normalized the Content Gate intro line to byte-identical with the sibling evolve-skills (Phase 2 coherence).

### Changes
- Content Gate intro → "Every proposed addition MUST pass ALL 4 checks. Reject content that fails ANY check." — names the check count (gate has exactly 4) and matches evolve-skills verbatim. The 4 numbered checks remain domain-specific (unchanged). [Phase 2 coherence item 6a]

### Dimensions Evaluated
Sibling-skill coherence; wording consistency.

### Rename
No rename.

## 2026-05-28

### Summary
Phase 2 coherence: mirrored evolve-skills' transcript-replication guards into the historical-auditor, added orchestrator-only-relay rationale to the Phase 1 narrative, consolidated the SKIPPED-skip guidance (4×→2×), and added a shutdown-idiom clarifying note. Net +1.

### Changes
- De-dupe-before-counting bullet (DISTINCT sessionId, ~10x inflation guard); `-r2` respawn count → DISTINCT events by name+sessionId.
- Phase 1 narrative gains race-condition rationale for orchestrator-only relay.
- "skip historical-auditor if SKIPPED" consolidated 4×→2× (removed table parenthetical + template-header sentence).
- One-line note: orchestrator-originated shutdown is intentional vs leaf-review self-initiate (`agents/team-lead.md` Rule 7).

### Dimensions Evaluated
Coherence, Over-Engineering (consolidation), Orchestration & cross-communication.

### Rename
No rename.

## 2026-05-28

### Summary
Added an absent/empty-dir guard to the Phase 0 historical-auditor's agent-memory read step (parity with evolve-skills), preventing undefined read behavior on the confirmed-empty `.claude/agent-memory/<agent>/` dirs. Net 0 lines.

### Changes
- Phase 0 historical-auditor template (line 185): agent-memory read step now guards "(dir may be absent or empty — treat as `none`)" matching evolve-skills — closes the only undefined-behavior path in the read step. Rejected an unsound convergence/stop-criterion gate (a net-0 prior cycle does not imply net-0 now; fresh upstream findings change weekly).

### Dimensions Evaluated
Orchestration & Agent Teams (HIGHEST — operator coordination priority), Coherence (sister parity), Over-Engineering (offset discipline).

### Rename
No rename.

## 2026-05-25

### Summary
Seven changes addressing 46% pre-flight abort signal and shutdown-routing ambiguity from team-lead memory: added scope-confirmation HARD GATE, clarified shutdown-response routing to orchestrator, followed-through step renumbering (7→8), plus mirrored trims from evolve-skills. Net +4 lines (338→342).

### Changes
- New pre-flight step 7: scope-confirmation HARD GATE in all-agents mode (>3 agents) surfacing planned cycle weight before Phase 0 spawn. Closes 46% abort-after-spawn signal.
- Shutdown protocol: added "addressed to the orchestrator (never to a peer)" clause per canonical staff-engineer routing rule.
- Step renumbering (7→8) followed through three internal references for coherence.
- Phase 1 post-review-loop step 6: removed — mirrors evolve-skills; lifecycle table is source of truth.
- Phase 0 friction-distinction: removed "scoped to the agents under review here" wrap — mirrors evolve-skills.

### Dimensions Evaluated
Completeness (HIGHEST — historical signal), Orchestration (routing + scope gate), Coherence (renumbering + sister parity), Consolidation.

### Rename
No rename.

## 2026-05-20

### Summary
Phase 2 coherence pass: aligned Changelog Rules format with sister evolve-skills — promoted normalization actions from trailing prose to `**Normalization:**` labelled sub-statement for scannability parity.

### Changes
- Promoted normalization actions to a labelled sub-statement (`**Normalization:**` prefix) instead of trailing prose, matching evolve-skills line 73 scannability.

### Dimensions Evaluated
Coherence (cross-skill format parity).

### Rename
No rename.

## 2026-05-20

### Summary
Fixed `${history_days}` shell-var leak in Phase 0 historical-auditor template (orchestrator substitutes `{...}` braces, not shell-var `${...}` — auditor subshell had no env var, find expanded to literal `-mtime -` and silently returned zero results), declared `{history_cutoff_epoch_ms}` on the auditor Window line for sister evolve-skills parity, and split Pre-flight step 7 mega-paragraph into sub-bullets matching evolve-skills step 8 layout. Net +3 lines.

### Changes
- Phase 0 historical-auditor template: `-mtime -${history_days}` → `-mtime -{history_days}` — closes silent zero-result failure path.
- Window line: added `epoch-ms {history_cutoff_epoch_ms}` declaration so substitution used downstream is declared upstream.
- Pre-flight step 7: split mega-paragraph into sub-bullets for the two epoch computations and probe; matches evolve-skills step 8 layout.

### Dimensions Evaluated
Skill Design Quality (HIGHEST — defect fix), Coherence (sister evolve-skills parity), Consolidation & Trimming.

### Rename
No rename.

## 2026-05-19

### Summary
Phase 2 coherence pass — aligned operator-prompt banner to evolve-skills' stronger phrasing (explicit ≤4-options API constraint + routing-question fallback). Net 0 lines (rewrap only). Behavior unchanged for ≤4-option callers; corrects misleading "doesn't raise the cap" phrasing for the >4-option path.

### Changes
- Pre-flight operator-prompts banner: aligned verbatim with `evolve-skills/SKILL.md:35` — adds the explicit "API rejects >4" callout and the route-first-then-narrow recipe for >4-option scenarios.

### Dimensions Evaluated
Coherence, Operator Prompts, Family Parity.

### Rename
No rename.

## Compacted history

Entries below were compacted per ADR 0001; full text in git history (see the compaction entry's date).

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
