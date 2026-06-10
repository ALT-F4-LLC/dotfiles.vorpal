# Changelog: init-specs

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

## 2026-06-09

### Summary
Third consecutive no-change verdict (184 lines, one-time bootstrap, zero usage in window). Phase-0 signals verified against ground truth: `$`+digit substitution audit clean; COUPLING reciprocity with prd re-confirmed accurate post file-based-paths refactor (c10195b); RESERVED-NAMES exact-match with team-lead.md taxonomy.

### Changes
- None. Spawning Template envelope-safe (no Skill() prescribed to spawned agents). `docket doc` adoption and `paths:` re-add rejected (Content Gate / prior operator revert f8b18a2).

### Dimensions Evaluated
All 8; Over-Engineering (HIGHEST — no trim headroom, concur with prior cycle), Orchestration (envelope-safety verified), Coherence (prd reciprocity + taxonomy parity verified on-disk).

### Rename
No rename.

## 2026-06-08

### Summary
Phase 1 no-change verdict (185 lines, one-time bootstrap orchestrator, unused in window — expected). Seven Spec File names verified exact-match against team-lead.md §Docs-Path Taxonomy; team-spawn/shutdown lifecycle verified against the async-shutdown model + Rule 7; COUPLING reciprocity with prd confirmed coherent on-disk. No trim candidate removable without dropping a load-bearing verification rail.

### Changes
- None.

### Dimensions Evaluated
All 8; Over-Engineering (HIGHEST — no trim headroom without losing safety rails), Orchestration (shutdown + parallel-spawn lifecycle), Coherence (Seven-Spec-File taxonomy parity).

### Rename
No rename.

## 2026-06-05

### Summary
Corrected a factually wrong COUPLING comment: prd does NOT write to docs/spec/ (it creates a Docket doc), and the doc-authoring siblings refuse reserved names by doc-type, not output directory. Rewrote to match prd's accurate ownership/name-collision rationale. Surfaced cross-cutting from the prd review; operator-approved out-of-scope fix.

### Changes
- Line 67 COUPLING comment: replaced the false "shares docs/spec/ output directory" / "write to different directories" rationale with the correct name-collision framing (0 net).

### Dimensions Evaluated
Coherence (cross-skill coupling accuracy), Correctness. Caught during the adr/prd/ux-spec/tdd Phase 2 coherence pass.

### Rename
No rename.

## 2026-05-30

### Summary
No-change verdict this cycle. Changelog file renamed specs.md → init-specs.md to match the skill rename applied in a prior cycle (skill dir is skills/init-specs/; the changelog filename was the last specs residue). SKILL.md body unchanged.

### Changes
- Rename only: docs/changelog/skills/specs.md → init-specs.md; H1 updated to `# Changelog: init-specs`. No SKILL.md edits.

### Dimensions Evaluated
Coherence (filename/skill-name parity — last residue cleared), Over-Engineering (HIGHEST — no trim candidates), Rename (executed).

### Rename
Changelog file specs.md → init-specs.md to align with the skills/init-specs/ directory. Skill itself was renamed in a prior cycle.

## 2026-05-28

### Summary
Fixed a crossed shutdown handshake in the parallel-spawn flow: orchestrator now APPROVES each spawned agent's self-initiated `shutdown_request` (per @staff-engineer agent def + ephemeral lifecycle) instead of originating competing requests, and the Spawning Template now instructs self-shutdown explicitly. Removes idle/stuck-ephemeral risk. Net 0 (inline; reviewer estimated +2).

### Changes
- Spawning Template: spawned `@staff-engineer` now emits `shutdown_request` to the orchestrator as its final tool call after the completion message, awaiting `shutdown_approved`. Aligns with sister skills (code-review, design-qa, design-review, vote).
- Wrap-up step 2: reframed from orchestrator-originated shutdown to "approve each self-initiated request; originate only as fallback; `TeamDelete` reaps failed/stalled."

### Dimensions Evaluated
Orchestration & Agent Teams (operator priority — crossed handshake), Completeness (idle-ephemeral), Over-Engineering (HIGHEST — no trim candidates), Coherence (shutdown idiom aligned with family).

### Rename
No rename. Family-aligned with prd/tdd/adr/ux-spec.

## 2026-05-25

### Summary
No-change verdict. Smallest skill in the doc-authoring family (177 lines) and thoroughly trimmed across prior cycles. Phase 0 focus areas resolve as structurally moot (agents write to unique paths) or already implemented (re-invocation gate in Pre-flight step 4). Single observed invocation insufficient to codify new prescribed flow.

### Changes
- None.

### Dimensions Evaluated
Over-Engineering (HIGHEST — BALANCED headroom intentionally not filled), Skill Design Quality, Actionability, Completeness, Orchestration, Coherence (family parity), Spec Alignment, Rename.

### Rename
No rename. Family-aligned with prd/tdd/adr/ux-spec.

## 2026-05-18

### Summary
Closed verification-scope bug (false-flagging pre-existing specs on "Skip existing" path) and trimmed two layers of redundant leaf-agent prohibition + an inflated scope-boundary cross-reference.

### Changes
- Step 3 Verify: scoped all four grep checks and `head -1` to `{generated_files}` (the Step 2 `completed` set) instead of `docs/spec/*.md`. Closes a false-flag bug where verification on the "Skip existing" path scanned pre-existing files whose Gaps section uses organic headings and incorrectly reported them missing the required section.
- Role paragraph: removed parenthetical "(prohibition detailed in the Spawning Template)" — the CRITICAL banner and Spawning Template already state the leaf-agent rule.
- Scope boundary: trimmed two-line cross-reference paragraph to a single line.

### Dimensions Evaluated
Actionability (HIGHEST — verification-scope bug), Over-Engineering, Skill Design Quality, Coherence.

### Rename
No rename.

## 2026-05-17

### Summary
Phase 2 coherence sync: corrected false AskUserQuestion "multiSelect lifts the 4-option cap" carve-out (matches sister orchestrator-skill corrections this cycle — the API hard-rejects >4 options regardless of multiSelect).

### Changes
- Operator-prompts blockquote: replaced "up to 8 options when multiSelect AND fixed dimension catalog" with "max 4 regardless of multiSelect" + routing-question pattern. Sister-parity with evolve-skills / evolve-agents / friction-driven-evolution this cycle.

### Dimensions Evaluated
Coherence (cross-skill parity on AskUserQuestion contract), Skill Design Quality (correctness).

### Rename
No rename.

## 2026-05-17

### Summary
Respawn arm now explicitly reassigns task ownership and re-records spawn time so polling credits the replacement agent; description tightened to signal one-time-bootstrap character and surface re-invocation safety (historical-audit signal that operators may re-type /specs mid-project).

### Changes
- Step 2 respawn arm: added explicit `TaskUpdate(... owner=..., status="in_progress")` and spawn-time re-record instruction. Closes gap where TaskList polling and 600s stall classifier would still credit the dead agent after respawn.
- Frontmatter description: added "One-time bootstrap" framing and one-line note that re-invocation prompts before overwrite; ongoing maintenance is @staff-engineer's. Trigger phrases unchanged.

### Dimensions Evaluated
Skill Design Quality, Actionability, Orchestration & Agent Teams.

### Rename
No rename. Family-aligned with prd/tdd/adr/ux-spec.

## 2026-05-16

### Summary
Phase 2 coherence pass: shutdown_request payload now specifies full `{type, reason}` shape (uniform with vote/evolve-*); AskUserQuestion preamble extended with multiSelect+fixed-catalog carve-out for Scope question's 7-file subset.

### Changes
- Wrap-up step 2: shutdown_request now uses `SendMessage(to="<name>", message={type: "shutdown_request", reason: "specs bootstrap complete"})` — uniform schema across orchestrator-family skills.
- Operator-prompts banner: extended option-count contract to permit "up to 8 options when multiSelect AND fixed dimension catalog" — covers Scope question's Custom-subset multiSelect over 7 spec files.

### Dimensions Evaluated
Coordination (shutdown payload uniformity), Operator prompt quality (AskUserQuestion contract honesty), Coherence.

### Rename
No rename.

## 2026-05-16

### Summary
Four operator-pain fixes: added canonical "Operator prompts" banner (coherence with evolve-skills/evolve-agents); hardened Verification globs against empty-glob expansion errors; resolved leaf-agent SendMessage recipient ambiguity between team/standalone modes; added minimum structural contract (3 H2s + required `## Gaps & Risks` section).

### Changes
- Pre-flight: added canonical "Operator prompts" banner — locks AskUserQuestion contract across the 4 call sites in this skill.
- Step 3 Verify: added `2>/dev/null` to both grep -L commands — prevents noisy "No such file or directory" false positives.
- Spawning Template: replaced hardcoded `SendMessage(to="team-lead", ...)` with role-resolved recipient — fixes standalone-mode handoff where team-lead may not exist.
- Spawning Template + Step 3 Verify: added minimum structural requirement (≥3 H2s + required `## Gaps & Risks` section) and matching grep verification check.

### Dimensions Evaluated
Skill Design Quality, Actionability, Over-Engineering (no bloat), Orchestration & Agent Teams (recipient ambiguity), Coherence (canonical banner with evolve-* siblings).

### Rename
No rename. Family-aligned with `prd`, `tdd`, `adr`, `ux-spec`.

## 2026-05-09

### Summary
Three small actionability + coherence fixes (operator pain points 1, 3): added `last_updated` regression check to Step 3 verification, clarified that template substitutions apply to the Spawning Template body (not the `Agent()` call), and added a reciprocal architecture↔code-quality cross-link to mirror the existing code-quality↔siblings deferral. Also notes that the prior entry's `paths:` addition has since been reverted (commit f8b18a2 removed `paths:` skill-wide); current frontmatter contains no `paths:` field, which is correct.

### Changes
- Step 3 Verify: added `grep -L "last_updated: \"{today_date}\"" docs/spec/*.md` — closes a regression path the existing `head -1` frontmatter check missed (an agent could write valid YAML with a stale or hardcoded date and slip past).
- Step 1 #3: added a one-line clarifier that the substitutions apply to the Spawning Template body, not to the `Agent()` call itself — prevents new operators from misreading the substitution scope.
- Spec File Reference: added reciprocal cross-link in `architecture.md` row deferring style/idiom and test-architecture details to their owning specs (mirrors the pre-existing code-quality.md cross-link); prevents content overlap when agents work in parallel.
- Note: the prior `## 2026-05-09` entry below documented adding `paths:` frontmatter, which was subsequently removed in commit f8b18a2 as part of a skill-wide cleanup. The prior entry remains as historical record (per the never-modify-existing-entries rule); current frontmatter correctly contains no `paths:` field.

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence (sibling vote, evolve-skills, evolve-agents), Spec Alignment (verified against `docs/spec/` actual files), Rename.

### Rename
No rename. Family-aligned with `prd`, `tdd`, `adr`, `ux-spec`.

## 2026-05-09

### Summary
Phase 2 coherence pass: declared `paths:` write surface for orchestrator parity with evolve-agents and evolve-skills.

### Changes
- Frontmatter: added `paths: ["docs/spec/*.md"]` — orchestrator skill writes to docs/spec/ via spawned teammates; aligns with evolve-agents/evolve-skills convention.

### Dimensions Evaluated
Coherence, Skill Design Quality.

### Rename
No rename.

## 2026-05-09

### Summary
Three small operator-experience and coordination-clarity fixes: added Architecture/maintainability emphasis option, distinguished spawned-agent failure handling from harness-level orchestrator crash recovery, and tightened code-quality.md exploration guidance to reduce overlap with sibling specs. Net 174→183.

### Changes
- Pre-flight Emphasis options: added `Architecture & maintainability` so operators with architecture-focused goals don't fall back to free-text re-prompting.
- Step 2 failure handling: scoped "On any failure" → "On any spawned-agent failure" and added a one-line note that orchestrator crashes are harness-handled (single auto re-spawn + Resume) so future readers don't add redundant manual restart logic.
- Spec File Reference: tightened `code-quality.md` exploration guidance to defer architecture and test-pattern questions to their owning specs.

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename. Operator pain points: Operator prompt quality, Output actionability, Coordination & handoff gaps.

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
