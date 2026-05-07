# Changelog: create-specs

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
