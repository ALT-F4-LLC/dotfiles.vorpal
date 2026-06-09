# Changelog: init-specs

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

## 2026-05-07

### Summary
Coherence: added missing CANONICAL:BANNER markers around the existing team-spawning CRITICAL banner (parity with vote, adr, prd, tdd, ux-spec); corrected reciprocal reserved-names COUPLING comment to align with PRD's corrected version. Net 172→174.

### Changes
- Wrapped top-of-file CRITICAL banner with `<!-- CANONICAL:BANNER:BEGIN -->` / `<!-- CANONICAL:BANNER:END -->` markers — banner content unchanged (team-spawning variant)
- Reserved-names COUPLING comment: rewrote to reflect actual coupling — specs owns the names, PRD hard-refuses because it shares `docs/spec/`, sibling doc-authoring skills (tdd/adr/ux-spec) write to different directories and do not refuse

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename.

### Rename
No rename.

## 2026-05-07

### Summary
Phase 2 coherence: replaced stale `dev` skill reference with team-lead orchestrator and fixed stale H1 prefix.

### Changes
- Scope-boundary note now points to `agents/team-lead.md` Medium/Large Task patterns instead of the deleted `dev` skill — accurate ownership for ongoing `docs/spec/` maintenance
- H1 changed from `# Create Specs` to `# Specs` to match frontmatter `name: specs`. Symmetric to the vote H1 fix

### Dimensions Evaluated
Coherence; stale-reference cleanup.

### Rename
No rename.

## 2026-05-06

### Summary
Closed two safety-rail gaps: Mermaid-diagram verification (template required it but verification didn't enforce it) and an executable mechanism for the 10-min stall classifier (was unenforceable without recorded spawn times). Net 164→172.

### Changes
- Step 3: added `grep -L '```mermaid' docs/spec/*.md` sanity check so the Spawning Template's Mermaid requirement is actually enforced; requirement-without-verification was dead text
- Step 2: added spawn-time recording instruction (`Bash date +%s` keyed by agent name) so the "10 min stall" arm of failed-task classification has an executable timing source — TaskList does not expose age, so prior phrasing was unenforceable

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename.

### Rename
No rename.

## 2026-05-06

### Summary
**Rename: `create-specs` → `specs`** per operator request to drop the `create-` prefix from the spec/doc-authoring family. Directory moved, frontmatter `name:` updated, slash command `/create-specs` → `/specs`, all cross-references updated.

### Changes
- Directory renamed `skills/create-specs/` → `skills/specs/`
- Frontmatter `name: create-specs` → `name: specs`
- Cross-references updated in: sibling skills (`prd`, `tdd`, `adr`, `ux-spec`), `agents/staff-engineer.md`, `agents/project-manager.md`, `agents/team-lead.md`, `README.md`
- COUPLING comment phrasing changed from "create-* family" → "doc-authoring family"
- Reserved-name error messages in sibling skills updated to reference the `specs` skill
- Changelog file moved: `docs/changelog/skills/create-specs.md` → `specs.md`; H1 updated; historical entries left intact

### Dimensions Evaluated
Rename, Coherence

### Rename
Renamed `create-specs` → `specs` per operator request.

## 2026-05-06

### Summary
Phase 1 over-engineering trim: dropped half-finished verification spot-check (no defined remediation arm) and trailing git-diff reminder already covered by the CRITICAL banner. Net 168→161.

### Changes
- Verification: removed Step 3 "Spot-check codebase reality" sub-step. Reason: no defined failure response made it half-finished, and the spawning template's honest-mentor directive already enforces non-aspirational documentation.
- Wrap-up: removed step 4 git-diff reminder. Reason: top-of-file CRITICAL banner already states the no-commit rule; git-diff is operator general knowledge.

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename.

### Rename
No rename. Already aligned with create-* family per prior 2026-05-06 entry.

## 2026-05-06

### Summary
**Rename: `specs` → `create-specs`** to align with the create-* family. Directory moved, frontmatter `name:` updated, slash command `/specs` → `/create-specs`, all cross-references updated.

### Changes
- Directory renamed `skills/specs/` → `skills/create-specs/`
- Frontmatter `name: specs` → `name: create-specs`; trigger phrases updated to "create specs", "generate specs", "bootstrap project specs", "create project specifications"
- Title: `# Specs` → `# Create Specs`
- Slash command `/specs` → `/create-specs` in argument handling examples
- Banner: `invoke /vote` → `invoke /create-vote` (companion rename)
- Cross-references updated in: `skills/create-prd/`, `skills/create-tdd/`, `skills/create-adr/`, `skills/create-ux-spec/` (all "owned by the `specs` skill" → "the `create-specs` skill"), `agents/staff-engineer.md` (skills/specs/SKILL.md path), `agents/project-manager.md`, `README.md`
- create-prd error messages updated to name `create-specs` ("'{slug}.md' is a reserved name owned by the create-specs skill...")
- COUPLING comment in create-prd updated to point at `skills/create-specs/SKILL.md`
- Changelog file moved: `docs/changelog/skills/specs.md` → `create-specs.md`; H1 updated; historical entries left intact

### Dimensions Evaluated
Rename, Coherence, Spec Alignment

### Rename
Renamed `specs` → `create-specs` per operator request to align naming with the create-* family.

## 2026-05-06

### Summary
Updated COUPLING comment to enumerate all 4 dependent create-* skills enforcing the reserved-name list. Net 168→168.

### Changes
- COUPLING comment above Spec File Reference: now names all 4 dependents (create-prd, create-tdd, create-adr, create-ux-spec) instead of only create-prd. Reason: 4 skills enforce the 7-name reserved list; under-specified coupling risked drift in 3 unmentioned dependents.
- Rejected: rename, restructure, description trigger expansion (skill is at correct size for scope; CRITICAL banner divergence from create-* is intentional per 2026-05-05 entry).

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-05-05

### Summary
Phase 2 coherence fix: unified CRITICAL banner format with evolve-* skills, preserving leaf-agent terminology native to this skill.

### Changes
- Replaced top-of-file CRITICAL banner with unified two-rule format covering no-commit and leaf-agent constraints (parity across all 5 team-spawning skills)

### Dimensions Evaluated
Coherence

### Rename
No rename.

## 2026-05-05

### Summary
No improvements applied this cycle. Reviewer flagged Monitor-tool gap and CRITICAL banner format divergence; both rejected — adding Monitor without a usage fails Content Gate (Behavioral), and TaskList polling cannot be replaced with a Bash-stream Monitor since TaskList is a tool, not a CLI. Reviewer themselves recommended deferral. Banner format divergence judged not load-bearing. Net 165→165.

### Changes
- No code changes
- Rejected: add `Monitor` to allowed-tools (no usage proposed; reviewer deferred the polling rewrite due to TaskList CLI uncertainty)
- Rejected: rewrite Step 2 polling to a `claude task list --json` shell loop (TaskList is a tool, not a CLI)

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-05-05

### Summary
Converted Pre-flight goal-alignment from a free-text `AskUserQuestion` to a structured two-question call with concrete Scope (multiSelect over the 7 spec filenames) and Emphasis options. Eliminates typing where selectable choices apply. Net 162→165.

### Changes
- Replaced free-text "what specs / focus areas" prompt with structured `AskUserQuestion`: Scope question (`All 7`/`Custom subset` multiSelect/`Cancel`) + Emphasis question (`Balanced`/`Security`/`Operational`/`Testing`)
- Skip Scope question when `$ARGUMENTS` already declares the subset

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-05-04

### Summary
Closed three edge-case ambiguities (unknown-argument rejection, argument+existing-file interaction, Wrap-up shutdown targeting) and added `activeForm` per Claude Code recommendations. Net 161→162.

### Changes
- Defined abort behavior for unknown spec-file arguments (Argument Handling)
- Scoped existing-file conflict UX to "target set" so `/specs <files>` works correctly when a subset already exists
- Added `activeForm` to TaskCreate per Claude Code docs (operator-visible spinner)
- Tied Wrap-up shutdown step to Step 2's task-state classification for unambiguous targeting
- [Phase 2 coherence] Stripped unverifiable "v2.1.111 stall detection" parenthetical from Step 2 task classification

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-04-22

### Summary
Closed the crash/stall handling gap flagged by operator feedback: concrete 2-minute polling cadence, task-state classification with v2.1.111 stall reference, and structured `AskUserQuestion` options on failure (respawn / skip / abort). Upgraded `effort: medium → max` for team-spawning parity with dev/vote. Net 157→161.

### Changes
- Upgraded `effort: medium` → `effort: max` (team-spawning parity with dev and vote)
- Rewrote Step 2 with concrete polling cadence, task-state classification, and structured respawn/skip/abort choice on failure
- Hardened Wrap-up shutdown to tolerate already-crashed agents
- Tightened frontmatter-template `dependencies` to `[]` (matches canonical form in actual `docs/spec/` files)
- Compressed role paragraph: consolidated isolation clause and deferred leaf-agent tool list to single occurrence in Spawning Template

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-04-16

### Summary
Clarified agent independence model (isolated files, no cross-agent handoffs during generation) and expanded SendMessage triggers to cover blocker case. Addresses operator feedback on coordination clarity. Net 158→157.

### Changes
- Added explicit independence clause to role paragraph — agents work on isolated files with no cross-agent handoffs
- Expanded spawning-template SendMessage guidance to cover blocker trigger in addition to decisions
- Tightened Scope boundary paragraph from 3 lines to 2 (compensating trim)

### Dimensions Evaluated
Orchestration & Agent Teams (priority), Skill Design Quality, Actionability, Completeness, Over-Engineering, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-04-16

### Summary
Fixed missing `{verified_goal}` substitution in Step 1 to match the Spawning Template section. Skill remains lean at 158 lines — full-sweep review found no bloat, gaps, or coherence issues.

### Changes
- Added `{verified_goal}` to Step 1 substitution list for internal consistency with Spawning Template intro

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-04-06

### Summary
Added explicit leaf-agent constraints to prevent spawned agents from creating sub-agents or invoking skills.

### Changes
- Added leaf-agent prohibition to role description paragraph — spawned agents must NOT spawn sub-agents or invoke skills
- Added concrete leaf-agent instruction to spawning template — "Do NOT spawn sub-agents, invoke skills (e.g., /vote), or use the Agent tool"
- Addresses reported experience feedback: team agents were invoking /vote and spawning nested agents
- Standardized anti-spawning language to canonical 4-tool pattern (`/vote`, `Skill()`, `Agent()`, `TeamCreate`) — coherence fix

### Dimensions Evaluated
Orchestration & Agent Teams, Coherence, Completeness, Over-Engineering

### Rename
No rename.

## 2026-03-30

### Summary
Added rigorous honesty directives at orchestrator and spawning template levels, trimmed description, added docket plan context, removed redundant lines.

### Changes
- Added orchestrator-level honest mentor directive after role statement (coherence fix — all other skills had one)
- Added honest mentor reinforcement in spawning template — specs must document reality, flag gaps explicitly
- Trimmed description from ~343 to ~230 chars, front-loaded key use case
- Added `docket plan --json` context to spawning template for richer project awareness
- Removed redundant "The spec file is the deliverable" line
- Collapsed shutdown instructions

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-03-29

### Summary
Trimmed redundant instructions from spawning template and pre-flight, aligned argument handling with `$ARGUMENTS` convention.

### Changes
- Removed redundant "Do NOT write implementation code" from spawning template (already in @staff-engineer agent definition)
- Consolidated "If no files exist" into the existing file check step (-2 lines)
- Merged maturity/dependencies frontmatter bullets into single line (-2 lines)
- Added `$ARGUMENTS` reference in Argument Handling for cross-skill coherence

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.


## 2026-03-21

### Summary
Added operator-facing progress reporting during agent execution for cross-communication observability; removed stale artifact.

### Changes
- Added progress relay instruction in Step 2 — orchestrator now reports each agent's completion to the operator with count
- Removed stale `</output>` tag artifact from end of file

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-03-20

### Summary
Removed `context: fork` (breaks agent teams), fixed pre-flight numbering, corrected shutdown syntax.

### Changes
- Removed `context: fork` from frontmatter — breaks TeamCreate/TeamDelete coordination (coherence fix)
- Fixed pre-flight step numbering from 1,2,5,6 to 1,2,3,4
- Fixed shutdown SendMessage to use valid JSON with reason field

### Dimensions Evaluated
Coherence, Skill Design Quality, Actionability

### Rename
No rename.

## 2026-03-20

### Summary
Fixed pre-flight step numbering, corrected shutdown message syntax.

### Changes
- Fixed pre-flight step numbering from 1,2,5,6 to 1,2,3,4 (stale gap from prior deletions)
- Fixed shutdown SendMessage to use valid JSON with reason field

### Dimensions Evaluated
Skill Design Quality, Actionability

### Rename
No rename.

## 2026-03-20

### Summary
Added `context: fork` frontmatter, removed redundant Rules section, consolidated pre-flight steps.

### Changes
- Added `context: fork` frontmatter for isolated execution context
- Removed Rules section (3 rules already stated in CRITICAL banner and role description)
- Consolidated pre-flight steps 1-3 into single grouped step

### Dimensions Evaluated
Skill Design Quality, Over-Engineering, Actionability

### Rename
No rename.

## 2026-03-20

### Summary
Added SendMessage completion trigger to spawning template, clarified completion monitoring in Step 2, and removed redundant cleanup rule.

### Changes
- Added SendMessage + TaskUpdate completion instructions to spawning template for explicit orchestrator notification
- Rewrote Step 2 to reference SendMessage-based completion flow instead of vague idle description
- Removed Rule 4 (duplicate of Wrap-up section)

### Dimensions Evaluated
Orchestration Effectiveness & Cross-Communication, Actionability, Over-Engineering

### Rename
No rename.

## 2026-03-20

### Summary
Fixed Task tool API calls to match actual schema, added `effort: medium` frontmatter, and trimmed duplicate Agent call from spawning template.

### Changes
- Added `effort: medium` frontmatter for appropriate reasoning depth
- Fixed TaskCreate parameters (`title` -> `subject`, removed invalid `team_name` and `depends_on`)
- Fixed TaskUpdate to use `taskId` instead of `task_id`, removed invalid `team_name`
- Fixed TaskList to remove invalid `team_name` parameter
- Removed duplicate `Agent()` call from Spawning Template (-1 line)

### Dimensions Evaluated
Skill Design Quality, Actionability, Over-Engineering, Coherence with Other Skills

### Rename
No rename.

## 2026-03-19

### Summary
Added argument handling and trimmed Rules for net +3 lines (163 to 166). First skill to support targeted file arguments.

### Changes
- Added `argument-hint: "[file...]"` frontmatter for UI parity with dev and vote
- Added Argument Handling section with optional file-list argument support
- Trimmed Rules from 8 to 4 (removed rules already covered by Pre-flight, Execution, Wrap-up)

### Dimensions Evaluated
Coherence with Other Skills, Over-Engineering, Skill Design Quality

### Rename
No rename.

## 2026-03-19

### Summary
Added allowed-tools frontmatter, consolidated Team Setup into Step 1, removed redundant commit prohibition from spawning template, and added cross-spec awareness instruction.

### Changes
- Added `allowed-tools` frontmatter to preapprove orchestration tools (including TeamCreate/TeamDelete)
- Merged standalone "Team Setup" subsection into "Step 1" as numbered preamble
- Removed "Do NOT commit" from spawning template (covered by top-level CRITICAL banner)
- Added instruction for spawned agents to skim existing docs/spec/ files to avoid overlap

### Dimensions Evaluated
Skill Design Quality, Over-Engineering, Completeness, Coherence

### Rename
No rename.

## 2026-03-19

### Summary
Shifted orchestrator responsibilities out of spawned agents, improved frontmatter clarity, added content verification, and passed project name explicitly.

### Changes
- Moved `mkdir -p docs/spec` to Pre-flight step 3 (orchestrator creates dir once)
- Added Pre-flight step 2 to resolve project name via `basename $(git rev-parse --show-toplevel)`
- Restructured frontmatter instruction as concrete YAML code block
- Added explicit date/project context lines to spawning template
- Enhanced Step 3 to verify frontmatter via `head -1 docs/spec/*.md`

### Dimensions Evaluated
Actionability, Orchestration Effectiveness, Completeness, Spec Alignment

### Rename
No rename.

## 2026-03-19

### Summary
First evolution cycle. Improved date consistency, clarified scope boundary with dev skill, tightened spawning template, and streamlined reference table.

### Changes
- Added date resolution step in Pre-flight for consistent `last_updated` values
- Added scope boundary statement clarifying specs vs dev skill responsibilities
- Added `docs/tdd/` cross-reference to spawning template
- Removed redundant Task Subject column from reference table
- Added "Be honest if no tests exist" to testing.md exploration guidance

### Dimensions Evaluated
Actionability, Completeness, Over-Engineering, Coherence, Spec Alignment, Skill Design Quality

### Rename
No rename.
