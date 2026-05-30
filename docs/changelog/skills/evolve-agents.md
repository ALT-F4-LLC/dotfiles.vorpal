# Changelog: evolve-agents

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

## 2026-05-18

### Summary
Fixed the date-to-epoch-ms gap in the historical-auditor's history.jsonl filter (pre-flight step 7 now computes `{history_cutoff_epoch_ms}`; step 4 of the historical-audit template uses it via a concrete jq one-liner). Net +2 lines. Sister `evolve-skills` got the identical fix.

### Changes
- Pre-flight step 7: added macOS/Linux command to compute `{history_cutoff_epoch_ms}` from `{history_days}` so the auditor can compare history.jsonl `timestamp` epoch-ms directly.
- Historical-audit template step 4: replaced unworkable `grep`+`epoch-ms of ISO-string` directive with a concrete `jq` one-liner that uses the new `{history_cutoff_epoch_ms}` substitution.

### Dimensions Evaluated
Actionability (HIGHEST — closed a silent-failure path), Coherence (sister evolve-skills parity), Completeness.

### Rename
No rename.

## 2026-05-17

### Summary
Corrected AskUserQuestion option cap (multiSelect does NOT raise the 4-option limit — verified live this cycle when step 2's 7-option call would have failed), collapsed step 2 options to 4, plus 8 mirror-with-evolve-skills trims. Net -23 lines.

### Changes
- Operator-prompts banner: replaced false "up to 8 options when multiSelect" carve-out with "≤4 regardless of multiSelect".
- Pre-flight step 2: collapsed 7 options to 4 (Role & coordination gaps, Operator prompts & output quality, File-size bloat, Other) to comply with cap.
- Pre-flight step 4: dropped self-evident "lists files and records counts" parenthetical.
- Phase 0 Docket-Audit template: tightened to sister evolve-skills' 2-line form.
- Phase 0 historical-auditor template: removed duplicate friction-distinction, trimmed Task preamble, dropped secondary @-grep, removed redundant tail in body distinction.
- Phase 1 body: collapsed SendMessage-triggers pointer paragraph.
- Phase 1 template Size Budget: condensed 4-line restatement to one line.

### Dimensions Evaluated
Skill Design Quality (correctness), Over-Engineering (HIGHEST), Coherence (sister evolve-skills + friction-driven-evolution), Actionability.

### Rename
No rename.

## 2026-05-16

### Summary
Phase 2 coherence pass: friction-payload recognition mirrored from evolve-skills (Pre-flight + Phase 1 template); AskUserQuestion preamble extended with multiSelect+fixed-catalog carve-out to match actual 7-option usage.

### Changes
- Pre-flight step 2: recognize friction-driven-evolution structured `experience_feedback` payload — mirrors evolve-skills this cycle so agent-targeted clusters route identically.
- Phase 1 template: substitution guidance for structured friction payload (cite `example_session_refs` in CONTEXT) — mirrors evolve-skills.
- Operator-prompts banner: extended option-count contract to permit "up to 8 options when multiSelect AND fixed dimension catalog" — resolves contradiction with step 2's 7-option multiSelect.

### Dimensions Evaluated
Coordination & handoff (friction-payload sister-parity), Operator prompt quality (AskUserQuestion contract honesty), Coherence.

### Rename
No rename.

## 2026-05-16

### Summary
Three over-engineering trims (net 283→276): merged Pre-flight inventory-validation steps 5+6 into a single abort check, replaced redundant Phase 1 SendMessage triggers body subsection with a pointer to the canonical site (Phase 1 template Rules), and dropped the exhortation tail on Rule 3 already covered by Crash & Stall Recovery.

### Changes
- Pre-flight: merged steps 5 (specific-agent validation) and 6 (no-files-found abort) into a single "Validate inventory" step. Reason: both were abort-checks against the inventory from step 4.
- Body Phase 1 SendMessage triggers subsection: replaced 5-line block with one-line pointer to canonical site in Phase 1 template Rules. Reason: spawned agents read the template; duplicate sites desynchronize.
- Rule 3 "Fail loud": dropped "Never review directly — orchestrator-only-coordinates invariant is absolute" tail. Reason: already stated in Crash & Stall Recovery step 2.

### Dimensions Evaluated
Over-Engineering (HIGHEST — all 3), Skill Design Quality, Coherence (sister parity flag for evolve-skills).

### Rename
No rename.

## 2026-05-13

### Summary
Two sister-evolve-skills parity fixes (net 276→279): added CANONICAL banner markers around the CRITICAL block (matches docs research recommendation + evolve-skills convention) and reformatted Phase 2 template Output from inline `>`-chained schema to clean H3 list with field schemas (matches Phase 1 layout + sister skill).

### Changes
- Wrapped CRITICAL banner in `<!-- CANONICAL:BANNER:BEGIN/END -->` markers. Reason: explicit format-authority declaration per new Claude Code convention; brings parity with sister evolve-skills.
- Phase 2 template Output Format: replaced inline `>`-chained schema with separated H3 headings carrying per-line field schemas. Reason: matches Phase 1 template normalized 2026-05-09 and sister evolve-skills Phase 2; easier for stateless spawned agent to parse.

### Dimensions Evaluated
Coherence (sister parity + CANONICAL markers), Actionability (Phase 2 template readability), Over-Engineering (no net bloat — +3 lines offset by clearer schemas).

### Rename
No rename.

## 2026-05-09

### Summary
Four pain-point fixes (net 276→273): fixed Pre-flight step 1 forward-reference to step 4, normalized Phase 1 template Output Format from H4 to H3 (parity with evolve-skills + changelog format spec), condensed Rule 3 that re-stated Crash & Stall Recovery, and dropped redundant Phase 2 spawn parenthetical.

### Changes
- Pre-flight step 1: removed forward-reference to step 4 (replaced "follow-up listing inventoried agents from step 4" with "free-text follow-up for the agent name"). The HARD GATE ran before step 4's inventory existed, breaking the flow.
- Phase 1 template Output Format: switched section headings from `####` to `###` for parity with sister evolve-skills and to match the changelog format spec (which expects H3 sub-sections). Mixed H4/H3 caused level-mismatch when the agent inlined its `### Summary` changelog inside an H4 block.
- Rule 3 ("Fail loud"): condensed inline restatement of Crash & Stall Recovery to a one-line pointer. The full protocol already lives in the dedicated section.
- Phase 2 spawn lead-in: dropped `(@staff-engineer, read-only)` parenthetical. The Phase 2 template already declares both fields.

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering (HIGHEST), Orchestration & Agent Teams, Coherence (sister evolve-skills parity), Spec Alignment, Rename.

### Rename
No rename.

## 2026-05-09

### Summary
Three operator-pain-point fixes: aligned Pre-flight step 2 pain-point options with evolve-skills + actual operator categories, restructured Phase 1 Output Format to multi-line H4 with explicit Coherence Issues schema, and added `paths:` frontmatter for write-surface declaration.

### Changes
- Pre-flight step 2: replaced stale option set (`Agent quality / role realism`, `Cross-agent communication visibility`, `File-size bloat / verbosity`, `Workflow gaps or stalls`) with operator-reported categories matching evolve-skills (`Coordination & handoff gaps`, `Operator prompt quality`, `Output quality / actionability`, `Scope or budget mismatch`, `Agent role realism`, `File-size bloat`). Reason: prior list didn't reflect what operators actually report.
- Phase 1 template Output Format: lifted from dense single-line prose to multi-line H4 layout; added explicit field schema for Coherence Issues (`ISSUE` / `AFFECTED_AGENTS` / `DETAIL`). Reason: stateless spawned agents need explicit templates; Coherence Issues had no schema and produced vague output.
- Frontmatter: added `paths: ["agents/*.md", "docs/changelog/agents/*.md"]` for write-surface declaration in orchestrator skills.

### Dimensions Evaluated
Skill Design Quality (frontmatter), Actionability (output schema), Boundary Clarity (n/c), Completeness (pain-point options), Consolidation & Trimming (no over-budget), Capability Growth (paths declaration), Spec Alignment (n/a meta-tooling), Rename (none).

### Rename
No rename.

## 2026-05-07

### Summary
Phase 2 coherence: aligned Phase 1 workflow structure and Output Format layout with sister evolve-skills for parity. Lifted teammate's per-task workflow into a numbered list, added explicit Phase 1 SendMessage triggers subsection, reformatted Output Format to multi-line H4-style for readability.

### Changes
- Phase 1 body: lifted teammate per-task workflow into a 4-item numbered list (parity with evolve-skills lines 130-134)
- Phase 1 body: added explicit "Phase 1 SendMessage triggers" subsection — preserves the orchestrator-only-relay rationale and consolidation-in-Phase-2 framing
- Phase 1 template Output Format: reformatted from dense inline-prose to multi-line H4-style — same content, clearer layout matches evolve-skills

### Dimensions Evaluated
Actionability, Coherence — orchestrator/teammate symmetry across sibling evolve-* skills.

### Rename
No rename.

## 2026-05-07

### Summary
Five parity/redundancy trims aligning with sister evolve-skills: dropped restated description tail, condensed Phase 1 lead-in mapping example, removed wrap-up step 1 parenthetical covered by Lifecycle table, tightened Phase 1 template Content Gate header, and collapsed template-substitute block triple-restatement. Net 258→254.

### Changes
- Description: removed "(each agent reviews its own file)" tail — body and template restate the mechanic
- Phase 1 lead-in: dropped @senior-engineer/agents/senior-engineer.md example — fully specified in substitute block below
- Wrap-up step 1: removed "(Phase 0 and Phase 1 agents were shut down in their phases)" parenthetical — Lifecycle table covers per-phase shutdown
- Phase 1 template Content Gate header: tightened to `## Content Gate` — body restates the "reject if ANY fails" assertion
- Template-substitute block: collapsed 4 lines to 1 by removing the matching-agent-type example (third restatement) — adopts evolve-skills' terser form

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename.

### Rename
No rename.

## 2026-05-06

### Summary
Two redundancy trims plus Phase 2 gate parity with evolve-skills. Net 262→258.

### Changes
- Phase 2 spawn line: dropped redundant "The Phase 2 teammate follows the Phase 2 spawning template" restatement — preceding sentence already names the template
- Phase 2 gate: tightened to match evolve-skills — added explicit "all Phase 1 teammates shut down" precondition (was only "complete + applied"); prevents spawning Phase 2 while stalled Phase 1 agents are still alive
- Phase 0 Docket CLI Audit: removed "Spawn one docket-auditor agent using subagent_type..." preamble — the code block on the next line restates it

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename.

### Rename
No rename.

## 2026-05-06

### Summary
Phase 2 coherence: aligned operator-prompt blockquote phrasing with evolve-skills.

### Changes
- Pre-flight operator-prompts blockquote: now matches evolve-skills wording ("logs, reproductions, large diffs, or verbatim quotes" replaces "logs, repros, large diffs"). The two skills share the same operator-prompt convention; aligning the phrasing prevents future drift.

### Dimensions Evaluated
Coherence (cross-skill convention alignment).

### Rename
No rename.

## 2026-05-06

### Summary
Phase 1 trim/coherence pass with sister evolve-skills: pruned redundant description tail, collapsed restated Phase 2 paragraph, merged Rule 5 into Rule 3 (Crash & Stall Recovery section already covers compaction), trimmed orchestrator-role triple-redundancy, added `reason: "<phase> complete"` to shutdown_protocol, aligned Phase 0 capture phrasing.

### Changes
- Description: removed redundant "Spawns agents to review themselves, enforces Content Gate and 500-line budget" tail. Reason: covered by body.
- Phase 2: collapsed restated template body — lead-in "follows the Phase 2 spawning template" is sufficient.
- Rules: merged Rule 5 (compaction recovery pointer) into Rule 3; Crash & Stall Recovery already covers compaction.
- Orchestrator role: removed duplicate "teammates are read-only / orchestrator edits" — Rule 2 + top-of-file CRITICAL block already cover.
- Shutdown protocol: added `reason: "<phase> complete"` parameter (parity with evolve-skills).
- Phase 0 capture: aligned phrasing with evolve-skills ("captured verbatim as `{docs_research_findings}` and `{docket_audit_findings}` for Phase 1 template substitution").

### Dimensions Evaluated
Role Realism, Actionability, Boundary Clarity, Completeness, Consolidation & Trimming, Capability Growth & Cross-Communication, Spec Alignment, Rename.

### Rename
No rename. Stable name parallel to evolve-skills.

## 2026-05-06

### Summary
Six parity/coherence fixes against sister evolve-skills: structured AskUserQuestion options for Pre-flight goal alignment, operator-prompts discipline blockquote, consolidated Team Setup & Agent Lifecycle, dropped duplicative Phase 1 line, fixed stale 10-min stall reference, trimmed cross-communication log from wrap-up. Net 273→266.

### Changes
- Pre-flight step 1: structured AskUserQuestion options (parity with evolve-skills)
- Added operator-prompts discipline blockquote to Pre-flight
- Consolidated separate "Team Setup" H3 into "Team Setup & Agent Lifecycle" header
- Removed duplicative Phase 1 line referencing dead "ultrathink" guidance
- Rule 3: removed stale ">10min" reference contradicting Monitor adoption
- Wrap-up step 3: replaced "cross-communication log" with "cross-communication events"

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-05-05

### Summary
Three Orchestration & Agent Teams alignments with evolve-skills (mid-Phase-1 routing fix, explicit no-peer-to-peer rule in Phase 1 template, shutdown-protocol consolidation) plus two trims. Net 274→270.

### Changes
- Fixed mid-Phase-1 cross-cutting routing: append findings to a notes list and pass to Phase 2 — do NOT route to in-flight siblings (race condition); aligns with evolve-skills line 158
- Phase 1 template: added explicit "No peer-to-peer SendMessage — orchestrator is the only relay" rule (parity with evolve-skills)
- Consolidated Shutdown protocol → Crash & Stall Recovery (removed duplicate timeout language)
- Removed Argument Handling forward-reference to Pre-flight step 5 (step 5 is one line, encountered immediately)
- Compressed Crash & Stall Recovery intro list (failure modes covered by detection mechanisms)

### Dimensions Evaluated
Role Realism, Actionability, Boundary Clarity, Completeness, Consolidation & Trimming, Capability Growth & Cross-Communication, Spec Alignment, Rename

### Rename
No rename.

## 2026-05-05

### Summary
Pre-flight step 2 experience-feedback prompt restructured: replaced one-line free-text `AskUserQuestion` with `multiSelect: true` over six pain-point classes (role realism, coordination gaps, cross-comm visibility, file-size bloat, workflow stalls, Other) with free-text follow-up only when `Other` is selected. Net 274→274.

### Changes
- Pre-flight step 2: replaced free-text experience-feedback ask with `AskUserQuestion` (multiSelect: true, six pain-point options + Other free-text follow-up); addresses operator feedback that prompts/options beat typing
- Rejected: structuring Pre-flight step 1 standalone goal-confirm (speculative bloat)

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-05-05

### Summary
Adopted `Monitor` tool for stall detection, replacing the 10-minute wall-clock heuristic with event-driven streaming. Removed duplicate invariants. Phase 2 unified top-of-file blockquotes into one critical-rules block (parity with evolve-skills) and consolidated pre-flight inventory steps. Net 310→274.

### Changes
- Added `Monitor` to allowed-tools — used in updated Crash & Stall Recovery for event-driven detection
- Tightened Crash & Stall Recovery to reference TeammateIdle notification + Monitor stream (replaces 10-minute wall-clock heuristic)
- Compressed orchestrator intro and removed three duplicate invariant blocks (Rigorous honesty callout, Evaluation Dimensions pointer, Phase 1 description summary)
- Trimmed Phase 1 template Rules from 4 to 2 bullets (Read-only and Minimize-context were restatements)
- Removed Rules pointer paragraph; numbered rules below were the actual behavior
- [Phase 2] Merged top-of-file blockquotes into one CRITICAL critical-rules block matching evolve-skills' structure (commit-ban + no-nested-agents); removed standalone SIZE CONSTRAINT (already in Pre-flight)
- [Phase 2] Consolidated Pre-flight steps 4 (`ls`) and 8 (`wc -l`) into one inventory step — parity with evolve-skills
- Rejected: TeammateIdle frontmatter hook (system already auto-delivers idle notifications — fails Non-redundant Content Gate)

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-05-04

### Summary
Trim pass: removed redundant Argument Handling tail, dropped unverifiable v2.1.111 reference, compressed Phase 0/1/2 description blocks (Agent() pseudo-code already lives in spawning templates), removed duplicate experience-feedback section header, and consolidated pointer-only Rules. Net 332→310.

### Changes
- Removed Argument Handling tail that restated Pre-flight step 5
- Removed unverifiable "v2.1.111 stall detection surfaces this" parenthetical (TeammateIdle hook reference retained)
- Compressed Phase 0/1/2 description blocks — dropped Agent() pseudo-code already present in spawning templates
- Removed redundant "## Operator Experience Feedback" section in Phase 1 template (already substituted at top of prompt)
- Consolidated Rules: pointer-only items collapsed into one intro line; kept 5 behavioral rules
- [Phase 2 coherence] Reordered frontmatter to `argument-hint → effort → allowed-tools` to match the 3-skill majority

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-04-22

### Summary
Added explicit Crash & Stall Recovery protocol addressing the operator's #1 pain (silent agent failures and manual restart churn). Documented TeammateIdle detection, re-spawn-once with resume context, fail-forward with changelog entry on second failure (never review directly), and compaction recovery. Offset by consolidating duplicate dimension lists, tightening Pre-flight, and compressing Phase 1 Context block. Net 344→332.

### Changes
- Added Crash & Stall Recovery subsection: stall detection (>10min / TeammateIdle hook / v2.1.111), crash detection (shutdown timeout / Agent error), single re-spawn with `Resume context:` preamble, fail-forward on second failure, compaction recovery
- Strengthened shutdown protocol: documents shutdown_response handling, rejection handling, one-turn timeout → re-spawn path
- Rule 6 references the Crash & Stall Recovery protocol and names TeammateIdle as the detection hook
- Rule 8 reframed around orchestrator-as-SPOF to make compaction recovery the primary mitigation
- Consolidated near-duplicate dimension lists (orchestrator-facing list replaced by pointer to Phase 1 template's canonical list)
- Compressed Pre-flight steps 1-2 and Phase 1 template Context block (duplicated template structure below)

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-04-16

### Summary
Added Agent Lifecycle table, replaced vague course-correct rule with specific (a)/(b)/(c) SendMessage triggers, consolidated Phase 1 post-completion, compressed Pre-flight step 2. Addresses operator feedback on coordination clarity. Net 347→344.

### Changes
- Added Agent Lifecycle table at top of Orchestration Workflow — centralizes spawn/shutdown per phase
- Removed redundant Phase 0 shutdown paragraph (now covered by Lifecycle table)
- Consolidated Phase 1 post-completion: folded shutdown into numbered steps, made Phase 2 handoff explicit, collapsed cross-cutting paragraph
- Replaced vague Phase 1 template "Course-correct" rule with specific (a)/(b)/(c) SendMessage triggers
- Compressed Pre-flight step 2 (experience feedback) from 6 lines to 1
- Coherence: added pointer to `skills/vote/` Delegation Protocol in "No nested agents" blockquote (symmetry with evolve-skills)

### Dimensions Evaluated
Role Realism, Actionability, Boundary Clarity, Completeness, Consolidation & Trimming, Capability Growth & Cross-Communication, Coherence, Rename

### Rename
No rename.

## 2026-04-16

### Summary
Trimmed ~12 lines (359→347) via size-constraint/checklist consolidation; Phase 2 aligned dimension naming in template and promoted "No nested agents" to intro callout.

### Changes
- Collapsed SIZE CONSTRAINT block from 5 lines to 1, referencing Pre-flight step 8
- Compressed Pre-flight step 8 from 8 lines to 4
- Compressed post-Phase-1 checklist from 8 numbered steps to 5
- Phase 1 template: "Over-Engineering is HIGHEST PRIORITY" → "Consolidation & Trimming is HIGHEST PRIORITY" to match dimension 5 name
- Moved "No nested agents" rule from Rule 8 to intro callout for discoverability parity with evolve-skills

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-04-06

### Summary
Added anti-sub-agent-spawning instructions to Phase 1 template, Phase 2 template, and Rules section. Compressed post-Phase-1 verification steps.

### Changes
- Added "No sub-agents" rule to Phase 1 template Rules — prevents `/vote`, `Skill()`, `Agent()`, `TeamCreate` (+2 lines)
- Added anti-spawning instruction to Phase 2 template (+1 line)
- Added Rule 8 "No nested agents" establishing orchestrator as sole agent-spawner (+2 lines)
- Compressed post-Phase-1 steps 6-8 from 8 lines to 3 (-5 lines)

### Dimensions Evaluated
Role Realism, Actionability, Boundary Clarity, Completeness, Consolidation & Trimming, Capability Growth & Cross-Communication, Spec Alignment, Rename

### Rename
No rename.

## 2026-03-30

### Summary
Trimmed description from 815 to ~230 chars (250-char cap), removed unused template variable, added anti-rubber-stamp directive for evolve-skills coherence.

### Changes
- Compressed description from 815 chars to ~230 chars — was 3x over Claude Code docs 250-char cap
- Removed unused `{focus_areas}` variable from Phase 1 substitution list — experience_feedback already covers operator feedback
- Added "Do not default to approval" directive to Phase 1 template task heading (coherence with evolve-skills)

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Consolidation & Trimming, Capability Growth & Cross-Communication, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-03-30

### Summary
Added rigorous honest orchestrator directive (operator priority), compressed Phase 0 templates, removed inapplicable Mermaid rule.

### Changes
- Added "Rigorous honesty over agreeability" directive block after orchestrator role description — enforces Content Gate ruthlessly, challenges unsupported claims (+4 lines)
- Compressed docs-researcher template FOCUS AREAS and removed non-behavioral instructions (-4 lines)
- Removed Rule 8 Mermaid diagram requirement — skill produces changelogs not architectural docs (-1 line)
- Compressed docket-auditor template preamble and steps (-1 line)

### Dimensions Evaluated
Role Realism, Actionability, Boundary Clarity, Completeness, Consolidation & Trimming, Capability Growth, Spec Alignment, Rename

### Rename
No rename.

## 2026-03-29

### Summary
Compressed dimension 6, aligned templates with evolve-skills, upgraded effort to max, consolidated docs-researcher template.

### Changes
- Compressed Dimension 6 from 5 to 3 lines (agent team lifecycle details were orchestrator-level)
- Added `{focus_areas}` variable to Phase 1 template for evolve-skills parity
- Added re-spawn-once timeout fallback (was skipping straight to orchestrator review)
- Removed "vote proposals created" from wrap-up report (never creates votes)
- Removed redundant "Read-only" from Phase 0 docket-auditor template
- Upgraded `effort: high` to `effort: max` (coherence with evolve-skills and vote)
- Consolidated docs-researcher template from 30+ lines to ~12 (matches evolve-skills format)

### Dimensions Evaluated
Consolidation & Trimming, Coherence, Completeness, Over-Engineering, Skill Design Quality, all 8 evaluated

### Rename
No rename.


## 2026-03-21

### Summary
Added cross-communication and vote observability reporting to address operator pain point about lacking visibility into inter-agent messaging and vote usage during evolution cycles.

### Changes
- Added cross-communication log and vote proposal tracking to wrap-up report output (operator feedback: no observability into agent messaging/votes)
- Added cross-communication logging step to Phase 1 orchestrator workflow
- Compressed Phase 0 docket audit template steps from 5 to 3 (-3 lines, offset additions)

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-03-20

### Summary
Coherence fixes: added Docs Research task to Team Setup, renamed Phase 0 heading to match behavior.

### Changes
- Added Docs Research task to Team Setup step 2 (was missing vs evolve-skills)
- Renamed Phase 0 heading from "Documentation Research & Docket CLI Audit" to "Docket CLI Audit & Docs Context"

### Dimensions Evaluated
Coherence

### Rename
No rename.

## 2026-03-20

### Summary
Removed phantom ToolSearch step, compressed changelog rules, expanded docket audit checklist.

### Changes
- Removed non-existent `ToolSearch` pre-flight step and renumbered steps (-2 lines)
- Compressed Changelog Rules from 18 lines to 7, matching evolve-skills format (-11 lines)
- Added `docket next`, `docket board`, `--escalation-reason` to Phase 0 audit checklist

### Dimensions Evaluated
Actionability, Over-Engineering, Completeness, Coherence

### Rename
No rename.

## 2026-03-20

### Summary
Compressed pseudo-code blocks, fixed docket CLI audit completeness, added `context: fork` frontmatter.

### Changes
- Compressed Phase 0, Phase 1, and Phase 2 spawn pseudo-code (-13 lines)
- Updated Phase 0 template to check for newly-discovered docket commands and flags
- Added `context: fork` frontmatter for subagent isolation
- Replaced `grep -r` with Grep tool reference in Phase 0 template
- Compressed "Never add" list into "Reject examples" one-liner

### Dimensions Evaluated
Over-Engineering, Completeness, Actionability, Spec Alignment

### Rename
No rename.

## 2026-03-20

### Summary
Removed Phase 0 agent spawning (docs research now passed as caller context), removed project-agnostic Content Gate check, compressed argument handling, dimension restatements, and template redundancies.

### Changes
- Replaced Phase 0 agent spawn with passthrough of caller-provided docs research context
- Removed Phase 0 spawning template (dead code after Phase 0 change)
- Removed Content Gate check #3 (project-agnostic) — agent files are project-specific; aligns with evolve-skills
- Compressed Argument Handling by removing redundant ls block (duplicated in Pre-flight)
- Compressed Phase 1 template dimension list — removed redundant "Content Gate applies" notes

### Dimensions Evaluated
Over-Engineering, Actionability, Coherence with Other Skills

### Rename
No rename.

## 2026-03-20

### Summary
Added effort frontmatter, compressed Phase 0 template and Team Setup pseudo-code, simplified timeout fallback rule, added ultrathink trigger for deep self-review analysis.

### Changes
- Added `effort: high` frontmatter for complexity-appropriate reasoning depth
- Compressed Phase 0 spawning template from 35 to 25 lines by removing boilerplate output format
- Compressed Team Setup pseudo-code from verbose inline code to concise descriptions
- Simplified rule 10 timeout fallback to single-attempt-then-orchestrator pattern
- Added ultrathink trigger to Phase 1 for extended thinking during self-review
- Fixed 2 TaskUpdate calls: `task_id` to `taskId`, removed `team_name`
- Fixed 1 TaskList call: removed invalid `team_name` parameter

### Dimensions Evaluated
Skill Design Quality, Completeness, Over-Engineering, Coherence with Other Skills

### Rename
No rename.

## 2026-03-19

### Summary
Trimmed from 459 to 457 lines. Collapsed redundant changelog normalization restatement.

### Changes
- Collapsed Phase 1 step 4 changelog normalization detail into reference to Changelog Format section

### Dimensions Evaluated
Over-Engineering

### Rename
No rename.

## 2026-03-19

### Summary
Added `allowed-tools` frontmatter, compressed Wrap-up and Team Setup sections, replaced redundant "orchestrator-only edits" line with self-evolution note, matching evolve-skills conventions.

### Changes
- Added `allowed-tools` frontmatter to preapprove orchestrator tools (including TeamCreate/TeamDelete)
- Compressed Wrap-up from 22 to 9 lines to match evolve-skills pattern
- Compressed Team Setup pseudo-code from verbose code blocks to inline format
- Replaced triple-stated "only orchestrator edits" with self-evolution note

### Dimensions Evaluated
Skill Design Quality, Over-Engineering, Coherence with Other Skills

### Rename
No rename.

## 2026-03-19

### Summary
Fixed date propagation gap and aligned template structure with evolve-skills conventions.

### Changes
- Added `{today_date}` propagation to Phase 1 and Phase 2 spawning templates
- Strengthened pre-flight step 1 wording to require template substitution
- Added `Agent: <name>` identifier line to Phase 1 template header
- Added spec selectivity guidance to orchestration workflow

### Dimensions Evaluated
Actionability, Coherence with Other Skills, Completeness

### Rename
No rename.

## 2026-03-19

### Summary
Added Pre-flight section, fixed template issues, and aligned with evolve-skills conventions.

### Changes
- Added Pre-flight section with 5 validation steps
- Fixed duplicate step 6 numbering in Phase 1 workflow
- Removed hardcoded agent role descriptions from template
- Replaced hardcoded WebFetch URL with graceful degradation
- Added `.claude/skills/` to Phase 2 rename search paths

### Dimensions Evaluated
Completeness, Actionability, Coherence with Other Skills

### Rename
No rename.
