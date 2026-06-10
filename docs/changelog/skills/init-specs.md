# Changelog: init-specs

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
