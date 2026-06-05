# Changelog: evolve-skills

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

## 2026-05-17

### Summary
Corrected false AskUserQuestion "multiSelect lifts the 4-option cap" carve-out (API hard-rejects >4 even with multiSelect — verified live this cycle when 6-option step 2 enum failed pre-flight). Documented `.claude/agent-memory/` may be absent. Collapsed step 2 options to 4 and removed duplicate friction-payload field list (Phase 1 template is the load-bearing copy).

### Changes
- Operator-prompts blockquote: replaced "up to 8 options when multiSelect" with "max 4 regardless of multiSelect" plus a routing-question pattern for >4-option dimensions.
- Pre-flight step 2: collapsed 6 options to 4 (merged Coordination+Orchestration, Operator+Output quality, Scope+Budget+File-size); removed duplicate friction-payload field list (load-bearing copy lives in Phase 1 template).
- Phase 0 historical-audit template: noted `.claude/agent-memory/` may not exist; auditor treats absence as `none`.

### Dimensions Evaluated
Skill Design Quality (correctness — primary), Completeness, Over-Engineering (HIGHEST), Coherence (sister evolve-agents + friction-driven-evolution carry same false carve-out — Phase 2 will sync).

### Rename
No rename.

## 2026-05-16

### Summary
Phase 2 coherence pass: AskUserQuestion preamble extended with multiSelect+fixed-catalog carve-out to match actual 6-option pain-class usage in step 2.

### Changes
- Operator-prompts banner: extended option-count contract to permit "up to 8 options when multiSelect AND fixed dimension catalog" — resolves contradiction between 2-4 cap and step 2's 6-option pain-class multiSelect.

### Dimensions Evaluated
Operator prompt quality (AskUserQuestion contract honesty), Coherence (sister parity with evolve-agents).

### Rename
No rename.

## 2026-05-16

### Summary
Wired up the friction-driven-evolution `[friction-driven-evolution: cluster-{id}]` payload contract end-to-end (Pre-flight step 2 + Phase 1 template) so downstream-routed runs preserve `proposed_edit.target` and `severity` signal. Closed cross-root coordination gap (`.claude/skills/` vs `skills/`) in Phase 1 SendMessage triggers and Pre-flight step 5 collision handling. Trimmed redundant Rule 1 (duplicated by Phase 2 gate) and removed unnecessary Phase 1 template lead-in.

### Changes
- Pre-flight step 2: recognize friction-driven-evolution structured `experience_feedback` payload (prioritize `proposed_edit.target`, weight by `severity`). Closes silent-integration gap.
- Phase 1 template: substitution guidance for structured friction payload — reviewers cite `example_session_refs` in CONTEXT.
- Pre-flight step 5: explicit handling for name collision across `.claude/skills/` and `skills/` roots via `AskUserQuestion`.
- Phase 1 template SendMessage trigger: include which root when reporting cross-cutting findings.
- Final Rules: removed Rule 1 (duplicated by Phase 2 gate and lifecycle table).
- Phase 1 template: removed redundant "Use the @staff-engineer agent..." lead-in.

### Dimensions Evaluated
Coordination & handoff gaps (primary — friction integration + cross-root), Over-Engineering (x2), Output quality, Skill Design Quality.

### Rename
No rename.

## 2026-05-13

### Summary
Phase 2 coherence: removed orphan Evaluation Dimensions pointer block. Phase 1 collapsed the full 8-item rubric to a single-paragraph pointer; coherence review found even the pointer was non-behavioral duplication of inlined Phase 1 template content (fails Content Gate "Behavioral"). Restores symmetry with sister evolve-agents (no equivalent top-level block). Net -6 lines.

### Changes
- Removed top-level `## Evaluation Dimensions` section entirely — dimensions live as source of truth inside the Phase 1 Spawning Template's "Your Task" block. Closes Phase 1 review-evolve-agents coherence issue #1.

### Dimensions Evaluated
Coherence (primary), Over-Engineering.

### Rename
No rename.

## 2026-05-13

### Summary
Trim duplicate Evaluation Dimensions block (orchestrator level was a verbatim copy of inlined Phase 1 template), reorder Pre-flight operator-prompts blockquote for sister-skill parity, drop redundant tail in final Rule 3, restore stronger Dimension 4 wording in the surviving template instance. Net change: -8 lines (290 → 282).

### Changes
- Collapsed top-level Evaluation Dimensions section to a compact pointer — 8-item list is inlined in the Phase 1 template (source of truth for stateless reviewers); orchestrator verifies Content Gate compliance, not full rubric. Saves 10 lines of pure duplication.
- Pre-flight: moved "Operator prompts" blockquote above "Before spawning any agents:" for sister evolve-agents parity (reads as global guidance, not step-internal).
- Final Rule 3: dropped redundant "Never review directly — invariant is absolute" tail. Enforced by CANONICAL banner, Rule 2, and Crash & Stall Recovery line.
- Phase 1 template Dimension 4: restored "Every addition from other dimensions MUST be offset here" (stronger phrasing migrated from now-trimmed top-level block).

### Dimensions Evaluated
Over-Engineering (HIGHEST — trim x2), Coherence (sister parity x2). No other dimensions touched.

### Rename
No rename.

## 2026-05-09

### Summary
Seven trim + parity fixes (operator pain points 1-4): wrapped CRITICAL block in `<!-- CANONICAL:BANNER -->` markers, dropped stale `paths` frontmatter reference (commit f8b18a2 deleted the field), tightened Pre-flight step 1 options + step 4 inventory, condensed Phase 1 Context bullets into prose, restructured Wrap-up as a numbered list, and trimmed the redundant Shutdown protocol restatement. Net change: -8 lines.

### Changes
- Top of file: wrapped CRITICAL block in `<!-- CANONICAL:BANNER:BEGIN/END -->` (matches leaf skills `vote`, `specs`, `code-review`).
- Pre-flight step 1: tightened option list and dropped forward-reference to the not-yet-run inventory step (matches sister evolve-agents fix).
- Pre-flight step 4: condensed 4-line TRIM/BALANCED definition to 1 line — definitions also live in Phase 1 template's Size Budget.
- Wrap-up: prose paragraph → 3-step numbered list (parity with sister evolve-agents) and named the `wc -l` paths explicitly.
- Shutdown protocol: removed the "no teammate reused" sentence (lifecycle table covers) and "treat as dead" forward-reference (Crash & Stall Recovery defines).
- Phase 1 template Context: 5-bullet flat list → 2-line prose (parity with sister evolve-agents), same content.
- Phase 1 template Dimension 1: removed `paths` from the frontmatter check list — the field was deleted from skill frontmatter in commit f8b18a2; reviewers were being told to evaluate a field that no longer exists.

### Dimensions Evaluated
Skill Design Quality, Actionability, Over-Engineering (HIGHEST), Coherence (sister evolve-agents), Spec Alignment, Rename.

### Rename
No rename.

## 2026-05-09

### Summary
Phase 2 coherence pass: inlined the 8 evaluation dimensions inside the Phase 1 reviewer template (stateless agents had no access to the orchestrator's top-level dimensions section), declared `paths:` write surface for orchestrator parity with evolve-agents, and restored an explicit Size Budget block to the Phase 1 template.

### Changes
- Phase 1 template "Your Task": inlined the 8 evaluation dimensions (Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename) so spawned reviewers have the rubric without needing to read the orchestrator file. Sister evolve-agents already has this pattern.
- Frontmatter: added `paths: [".claude/skills/*/SKILL.md", "skills/*/SKILL.md", "docs/changelog/skills/*.md"]` for orchestrator write-surface declaration consistency.
- Phase 1 template: added explicit `## Size Budget` block (TRIM/BALANCED rules) to match evolve-agents prominence.

### Dimensions Evaluated
Coherence, Actionability, Skill Design Quality.

### Rename
No rename.

## 2026-05-09

### Summary
Trim pass on Phase 1 template Context section: removed two self-referencing bullets that duplicate the immediately-following headers, replacing with a single compact clause. Tightened Pre-flight step 1's option-routing parenthetical, removing forward-reference to step 4. Net 278→275.

### Changes
- Phase 1 template Context bullets: removed duplicate "review operator experience feedback below" and "review docs research and docket audit findings below" — fail Content Gate Behavioral (sections appear with headers in the next 10 lines). Replaced with single compact clause for parity with evolve-agents.
- Pre-flight step 1: dropped inline routing parentheticals (`use $ARGUMENTS or list step-4 inventory`, `follow-up multiSelect over the 8 dimensions`) and folded the dimension follow-up into a separate sentence — removes forward-reference to step 4 (which runs later) and reduces operator-prompt verbosity.

### Dimensions Evaluated
Skill Design Quality (no change), Actionability (no change), Completeness (no change), Over-Engineering (trim x2), Orchestration & Agent Teams (no change), Coherence (improved parity with evolve-agents), Spec Alignment (no change), Rename (no change).

### Rename
No rename.

## 2026-05-07

### Summary
Self-evolution trim pass: collapsed self-referential orchestrator identity block, removed Behavioral-failing "Self-evolution" blockquote, dropped redundant Phase 0 lifecycle restatement, trimmed Dimension 5 team-lifecycle restatement, and tightened Phase 1 SendMessage triggers parenthetical. Net 287→278.

### Changes
- Orchestrator identity block: collapsed 5-line block to 1 sentence — "including the `evolve-*` skills themselves" is self-referential (globs already match), "you do not perform reviews yourself" duplicates Rules 2 + 3
- Removed "Self-evolution" blockquote — general filesystem/LLM knowledge (fails Content Gate Behavioral)
- Phase 0 description: removed "Then shut down both per lifecycle rules before starting Phase 1" — duplicates lifecycle table row 0
- Dimension 5: removed trailing team-lifecycle sentence — duplicates lifecycle table + Wrap-up
- Phase 1 SendMessage triggers: compressed parenthetical, preserving the 2026-05-05 anti-drift rationale via "race conditions across independent edit surfaces" framing

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename.

### Rename
No rename.

## 2026-05-07

### Summary
Phase 2 coherence: replaced deleted `dev` skill name in argument-handling example with current `tdd`.

### Changes
- `/evolve-skills dev` example changed to `/evolve-skills tdd` — `dev` was deleted earlier this cycle; the example now uses a real skill name and exercises the same Pre-flight step 5 validation path

### Dimensions Evaluated
Coherence; stale-reference cleanup.

### Rename
No rename.

## 2026-05-06

### Summary
Self-evolution pass: collapsed bloated 10-rule Rules section to 4 rules matching sister evolve-agents (removed duplicates of CRITICAL blockquote, Orchestration Workflow ordering, Changelog Format, and Content Gate). Trimmed Dimension 5 trailing self-instruction. Phase 2 `## Tasks` → `## Task` for sister parity. Net 294→287.

### Changes
- Rules section: 10 rules → 4 rules; rules 1-5 duplicated Orchestration Workflow ordering, rule 6 duplicated CRITICAL blockquote, rule 7 duplicated Changelog Format, rule 8 duplicated Pre-flight step 4 + template `{mode}`, rule 10 duplicated Content Gate — all fail Content Gate Non-redundant
- Dimension 5: removed trailing "Check: self-verification, course-correction triggers, efficient context (targeted Grep over broad reads)" — fails Content Gate Behavioral
- Phase 2 template: `## Tasks` → `## Task` for parity with Phase 1 template (`## Your Task`) and sister evolve-agents

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename.

### Rename
No rename.

## 2026-05-06

### Summary
Phase 1 self-review aligned with sister evolve-agents: collapsed Pre-flight step 2 to single multiSelect, extracted Rule 10 (Fail loud) + Rule 12 (compaction) into a dedicated "Crash & Stall Recovery" section after the lifecycle table, trimmed Phase 1 post-review loop, bulleted SendMessage triggers, removed non-behavioral Rule 7 ("Build on strengths"), tightened Phase 0 docs-researcher MISSION wording, dropped redundant Phase 2 task 4 enumeration.

### Changes
- Pre-flight step 2: 3 questions → 1 multiSelect with `Other` follow-up (parity with evolve-agents)
- Pre-flight step 1: trimmed verbose option-list parenthetical
- Extracted Rules 10/12 into a dedicated `### Crash & Stall Recovery` section after Team Setup & Agent Lifecycle — improves mid-incident scannability and matches evolve-agents structure
- Phase 1 post-review loop: 5 prose steps + separate shutdown paragraph → 6 numbered bullets including "Self-correct" step
- Phase 1 SendMessage triggers paragraph → bulleted triggers + 1-line policy
- Phase 1 spawning template: renamed "Requirements" → "Rules"; added "No peer-to-peer SendMessage" bullet for explicitness
- Phase 0 docs-researcher MISSION: aligned wording with evolve-agents
- Removed Rule 7 ("Build on strengths — improve, don't rewrite") — fails Content Gate Concrete check
- Phase 2 Task 4: removed enumeration (Phase 1 Dimension 5 already covers triggers)
- Rules section: renumbered after consolidation (10 rules, was 12)

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename.

### Rename
No rename.

## 2026-05-06

### Summary
Removed unverified `disable-model-invocation` from Dimension 1, trimmed Phase 0 docs-researcher template asymmetry vs. docket-auditor sibling, tightened mode threshold wording. Net 295→288.

### Changes
- Dimension 1: replaced `user-invocable` and `disable-model-invocation` references with `effort`/`argument-hint`/`allowed-tools` — `disable-model-invocation` is not in documented frontmatter and not used in any skill
- Phase 0 docs-researcher template: folded INSTRUCTIONS into MISSION, collapsed OUTPUT FORMAT to one line — reduces asymmetry with docket-auditor sibling
- Pre-flight step 4: tightened mode threshold to `>500` / `≤500` to match Rule 9's boundary

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-05-05

### Summary
Phase 2 coherence fix: inlined Argument Handling validation note for parity with evolve-agents.

### Changes
- Inlined "See Pre-flight for validation" → "Pre-flight step 5 validates the argument matches an existing skill directory" (parity with evolve-agents:25, removes low-value forward-reference)

### Dimensions Evaluated
Coherence

### Rename
No rename.

## 2026-05-05

### Summary
Trimmed Pre-flight steps 1 and 2 AskUserQuestion verbosity, justified the no-peer-to-peer policy in Phase 1, and converted lifecycle prose to a Phase | Agents | Lifecycle table for parity with evolve-agents. Net 314→295.

### Changes
- Pre-flight step 1: removed verbatim option-label prose; kept structured-question pattern and the four selectable choices in compressed form
- Pre-flight step 2: collapsed three-question construction prose; preserved Q1 multiSelect, Q2 dimension focus, Q3 paste-material gate
- Phase 1 SendMessage triggers: added one-sentence justification for orchestrator-only-relay (independent edit surfaces, Phase 2 consolidates) so future cycles don't strip the rule
- Lifecycle rules: replaced bulleted prose with Phase | Agents | Lifecycle table for coherence with evolve-agents
- Rejected: removing "No sub-agents" from Phase 1 template — that line IS the spawning-prompt content reaching teammates; top-of-file CRITICAL block does not auto-propagate

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-05-05

### Summary
Eliminated free-text operator prompts from Pre-flight in favor of structured `AskUserQuestion` calls (Step 1 four explicit options; Step 2 single multi-question call with concrete dimension-aligned options); added operator-prompts blockquote rule near top. Free-text reserved for paste material only. Net 299→314.

### Changes
- Pre-flight step 1: replaced vague "(e.g., all skills, specific skill, specific dimensions)" hint with four explicit AskUserQuestion options + follow-up patterns
- Pre-flight step 2: replaced three free-text bullets with one structured multi-question AskUserQuestion call (Friction multiSelect, Focus, Specifics) — addresses operator pain that prompts/options beat typing
- Added blockquote rule above Pre-flight: operator prompts use AskUserQuestion w/ pre-generated options; free-text only for paste material via prior option-led question

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-05-05

### Summary
Adopted `paths:` frontmatter (new Claude Code feature, Apr 2026) and `Monitor` tool for stall detection. Removed third restatement of 500-line budget, merged top-of-file critical-rules blockquotes, and made Phase 1→Phase 2 cross-cutting handoff concrete. Net 304→303.

### Changes
- Added `paths:` frontmatter (.claude/skills/**, skills/**, docs/changelog/skills/**) — declares write surface to harness
- Added `Monitor` to allowed-tools — supports Rule 10's event-driven stall detection
- Merged commit-ban and no-nested-agents blockquotes into one critical-rules block — both are spawned-teammate invariants, fragmenting them obscured the region
- Removed redundant "## Size Budget" block from Phase 1 template — `{mode}` substitution and Output Format's `NET_LINES:` field already carry the rule
- Made Phase 1 cross-cutting handoff concrete — orchestrator appends cross-cutting findings to running notes and passes them verbatim into the Phase 2 prompt's "Phase 1 Coherence Issues" section
- [Phase 2] Updated Rule 10 stall detection to reference TeammateIdle notification + Monitor stream silence (replaces 10-minute polling heuristic) — parity with evolve-agents Crash & Stall Recovery

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-05-04

### Summary
Trim pass: removed restated orchestrator-identity content, vague Rule #12, vague Phase 2 "bidirectional" check, and redundant size/priority restatements in Phase 1 template. Consolidated Pre-flight inventory steps. Net 313→304.

### Changes
- Tightened orchestrator-identity paragraph — removed restatement of Phase 1 workflow steps and the Behavioral-failing "self-evolution is expected" sentence
- Removed Rule #12 (Self-correct on mediocre results) — no concrete trigger; Rules #11 and #7 cover its intent
- Removed "verify bidirectional triggers where applicable" from Phase 2 cross-communication checks — fails Concrete (no defined "applicable" criterion)
- Consolidated Pre-flight steps 4 and 8 into one `wc -l` inventory step
- Removed redundant "Build on strengths, don't rewrite" from Phase 1 Requirements (duplicates Rule #7)
- Removed "SIZE CONSTRAINT" half of merged blockquote (third restatement of 500-line rule; broken step reference after consolidation)
- Tightened Phase 1 Size Budget block — removed TRIM/BALANCED definitions already passed via `{mode}` substitution
- Removed duplicate "HIGHEST PRIORITY / offset" reminder from Phase 1 Your Task section
- [Phase 2 coherence] Stripped unverifiable "v2.1.111 stall detection" parenthetical from Rule #10

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-04-22

### Summary
Hardened crash recovery: expanded Rule #10 with concrete stall/crash detection signals and fail-forward behavior when shutdown_response doesn't land. Resolved contradiction between the old "review directly" fallback and the orchestrator-only-coordinates invariant. Addresses operator pain: agents crashing silently and needing manual restart. Net 316→313.

### Changes
- Rule #10 now defines: 3 failure-detection signals (Agent error return, 10+ min stalled task per v2.1.111 OR `TeammateIdle` hook, no SendMessage response), shutdown-timeout behavior (proceed after one turn if no shutdown_response), single re-spawn with name suffix, and fail-forward ("No review performed" changelog entry) rather than the self-contradicting "review directly"
- Lifecycle rules document shutdown-ack timeout so phases don't block on dead agents
- Removed "Rigorous honesty" blockquote — redundant with Rule #11 and Phase 1 template's reviewer-side directive; merged "Self-evolution" and "SIZE CONSTRAINT" into one blockquote
- Phase 2 coherence: added `TeammateIdle` hook signal to Rule #10 for parity with evolve-agents stall detection

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-04-16

### Summary
Centralized agent lifecycle, made Phase 1 SendMessage triggers explicit, added Phase 2 handoff gate, removed duplicate rules. Addresses operator feedback that agent coordination felt unclear. Net 328→316.

### Changes
- Added "Agent Lifecycle" rules (single source for shutdown + report capture); Phase 0 / Wrap-up now reference them instead of inlining shutdown JSON
- Replaced vague "Route cross-cutting findings from SendMessage to peers" with explicit triggers: orchestrator-only relay, cross-cutting/delegation/blocker categories
- Phase 2 gate made explicit: tasks completed + edits applied + teammates shut down
- Removed duplicate Rule 6 ("Only orchestrator edits") and Rule 13 ("Clean up"); renumbered
- Coherence: added pointer to `skills/vote/` Delegation Protocol in "No nested agents" blockquote so teammates can resolve delegation_request schema without duplicated content

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-04-16

### Summary
Removed dead `{focus_areas}` substitution variable from Phase 1 template and promoted Over-Engineering to HIGHEST PRIORITY in the main dimension list to match template enforcement.

### Changes
- Removed `{focus_areas}` variable from Phase 1 substitution list — never interpolated; redundant with `{experience_feedback}`
- Dimension 4 now labeled "Over-Engineering (HIGHEST PRIORITY)" with offset-here reminder, aligning main list with Phase 1 template and evolve-agents dim-5 treatment

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-04-06

### Summary
Added anti-sub-agent-spawning instructions to orchestrator identity, Phase 1 template, Phase 2 template, and consolidated verbose rules. Removed "vote invocations" from wrap-up report.

### Changes
- Added "No nested agents" blockquote at orchestrator identity level (+2 lines)
- Added "No sub-agents" rule to Phase 1 spawning template Requirements (+1 line)
- Added anti-spawning instruction to Phase 2 coherence reviewer template (+1 line)
- Removed "vote invocations" from wrap-up report list (contradicts sub-agent prevention)
- Consolidated rules 14-15 verbose phrasing (-3 lines)

### Dimensions Evaluated
Orchestration & Agent Teams, Coherence, Over-Engineering, Completeness, Skill Design Quality, Actionability, Spec Alignment, Rename

### Rename
No rename.

## 2026-03-30

### Summary
Trimmed description from 758 to ~185 chars to meet 250-char cap; removed redundant experience feedback section from Phase 1 template.

### Changes
- Trimmed description from 758 chars to ~185 chars — 250-char cap per Claude Code docs, moved details to body
- Removed duplicate `## Operator Experience Feedback` from Phase 1 template — already present in template header
- Fixed Phase 0 and wrap-up shutdown syntax to use full structured SendMessage format (coherence with evolve-agents)

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-03-30

### Summary
Added rigorous honest mentor directives to orchestrator identity and Phase 1 template; trimmed docs-researcher checklist, consolidated rules, fixed role paragraph structure.

### Changes
- Added honest mentor directive to orchestrator identity block — enforces Content Gate rigor
- Fixed role paragraph structure — reunited split paragraph and repositioned honest mentor blockquote (coherence with evolve-agents)
- Added honest mentor reinforcement to Phase 1 spawning template task section
- Removed vague "Also check" list from docs-researcher template
- Consolidated rules 11-12 (Fail loud + Timeout fallback) into single rule, renumbered

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-03-29

### Summary
Trimmed over-engineered content, aligned Phase 1 shutdown pattern with evolve-agents (immediate per-agent), upgraded effort to max.

### Changes
- Removed Rule 15 (Mermaid diagrams) — fails Content Gate for Behavioral and Concrete
- Consolidated docs-researcher template from 25+ lines to 6 focused lines (-19 lines)
- Replaced verbose SIZE CONSTRAINT blockquote with one-liner referencing Pre-flight step 8
- Changed `effort: high` to `effort: max` (matches dev skill complexity)
- Consolidated docket audit template from 7 lines to 3
- Merged orchestrator post-steps 5-6 into steps 2 and wrap-up
- Added immediate per-agent shutdown to Phase 1 (coherence with evolve-agents pattern)
- Removed batch Phase 1 shutdown from Phase 2 section header

### Dimensions Evaluated
Skill Design Quality, Over-Engineering, Orchestration & Agent Teams, Coherence, all 8 evaluated

### Rename
No rename.


## 2026-03-21

### Summary
Added operator observability reporting for cross-communication and vote usage; expanded Dimension 1 evaluation criteria; trimmed redundant Content Gate and template content.

### Changes
- Added observability report section to Wrap-up requiring orchestrator to surface cross-communication events, vote invocations, and course-corrections (+2 lines)
- Expanded Dimension 1 to explicitly check `user-invocable`, `effort`, `argument-hint` frontmatter fields (+1 line)
- Removed redundant "Avoid" coaching from Phase 1 template — covered by staff-engineer's own anti-patterns (-1 line)
- Removed redundant "Never add" enumeration from Content Gate — fully covered by checks 1 and 4 (-2 lines)
- [Phase 2] Added cross-communication logging step to Phase 1 orchestrator workflow for consistency with evolve-agents

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-03-20

### Summary
Removed phantom ToolSearch pre-flight step, consolidated docket audit template, rejected `context: fork` (breaks agent teams).

### Changes
- Removed non-existent `ToolSearch` pre-flight step and renumbered remaining steps (-2 lines)
- Consolidated Phase 0 docket audit template from 5 verbose steps to 3 focused steps (-4 lines)
- Rejected `context: fork` recommendation — breaks agent team coordination (TeamCreate/TeamDelete)

### Dimensions Evaluated
Actionability, Over-Engineering, Skill Design Quality

### Rename
No rename.

## 2026-03-20

### Summary
Fixed incorrect docket CLI reference, trimmed duplicate Content Gate and evaluation dimensions from Phase 1 template, added `context: fork` frontmatter.

### Changes
- Fixed `docket vote start` to `docket vote create` in Phase 0 template (docket CLI audit)
- Replaced verbatim Content Gate in Phase 1 template with back-reference (-5 lines)
- Replaced verbatim 8-dimension listing in Phase 1 template with concise reference (-6 lines)
- Added `context: fork` frontmatter for isolated execution context (+1 line)
- Aligned Phase 0 docket audit template with evolve-agents (coherence fix)

### Dimensions Evaluated
Over-Engineering, Skill Design Quality, Completeness

### Rename
No rename.

## 2026-03-20

### Summary
Trimmed redundant Phase 0 template instructions, consolidated overlapping changelog rules, and aligned argument handling with evolve-agents conventions.

### Changes
- Trimmed Phase 0 template from verbose step-by-step to focused prompt (-14 lines)
- Consolidated "Strict Changelog Rules" and "Changelog Normalization" into single "Changelog Rules" section
- Condensed rules 9-10 to back-references instead of restating constraints
- Added `$ARGUMENTS` reference to argument handling for cross-skill consistency

### Dimensions Evaluated
Over-Engineering, Skill Design Quality, Coherence with Other Skills

### Rename
No rename.

## 2026-03-20

### Summary
Added `effort: high` frontmatter and trimmed redundant Phase 2 preamble. Rejected Phase 0 removal (it IS the docs research mechanism, not redundant).

### Changes
- Added `effort: high` frontmatter for complexity-appropriate reasoning depth
- Trimmed redundant "read-only" preamble from Phase 2 template header (-2 lines)
- Fixed 3 TaskCreate calls: `title` to `subject`, removed `team_name` and `depends_on`
- Fixed 2 TaskUpdate calls: `task_id` to `taskId`, removed `team_name`
- Fixed 1 TaskList call: removed invalid `team_name` parameter

### Dimensions Evaluated
Skill Design Quality, Over-Engineering, Completeness, Coherence with Other Skills

### Rename
No rename.

## 2026-03-19

### Summary
Trimmed from 499 to 485 lines. Condensed Argument Handling and removed generic agent SDK boilerplate.

### Changes
- Condensed Argument Handling from 16 lines to 4, deferring validation to Pre-flight
- Removed "teammates go idle between turns" boilerplate (general agent behavior)

### Dimensions Evaluated
Over-Engineering (primary), Coherence with Other Skills

### Rename
No rename.

## 2026-03-19

### Summary
Coherence fixes: restored Phase 0 output format bullets for alignment with evolve-agents, added TeamCreate/TeamDelete to allowed-tools.

### Changes
- Restored bullet-point examples in Phase 0 Output Format to match evolve-agents template
- Added TeamCreate/TeamDelete to `allowed-tools`

### Dimensions Evaluated
Coherence with Other Skills, Actionability

### Rename
No rename.

## 2026-03-19

### Summary
Added `allowed-tools` frontmatter, trimmed Phase 0 output format scaffolding, and consolidated duplicate "orchestrator-only edits" statements.

### Changes
- Added `allowed-tools` frontmatter listing all tools the orchestrator needs
- Removed placeholder bullets from Phase 0 output format template (headers suffice)
- Consolidated two adjacent "orchestrator-only editing" statements into one

### Dimensions Evaluated
Skill Design Quality, Over-Engineering, Completeness

### Rename
No rename.

## 2026-03-19

### Summary
Closed date passthrough gap in spawning templates so agents receive consistent dates.

### Changes
- Added `Today's date is {today_date}` to Phase 1 spawning template Context section
- Added `Today's date: {today_date}` to Phase 2 spawning template header
- Updated template headers to list `{today_date}` in substitution variables
- Refined pre-flight step 1 to name the `{today_date}` variable explicitly

### Dimensions Evaluated
Completeness, Actionability, Orchestration Effectiveness

### Rename
No rename.

## 2026-03-19

### Summary
Added Pre-flight section, fixed WebFetch degradation, and aligned conventions with evolve-agents.

### Changes
- Replaced hardcoded WebFetch URL with graceful degradation
- Fixed duplicate step 6 numbering in Phase 1 workflow
- Added argument matching guidance for both skill paths
- Added Pre-flight section with 5 validation steps
- Added "Run pre-flight before spawning" as Rule #1

### Dimensions Evaluated
Completeness, Actionability, Coherence with Other Skills

### Rename
No rename.
