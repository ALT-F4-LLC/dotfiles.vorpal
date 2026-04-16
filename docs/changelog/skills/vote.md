# Changelog: vote

## 2026-04-16

### Summary
Fixed Pre-flight→Phase 1 ordering bug (TeamCreate referenced `{vote-id}` before it existed) and aligned delegation_request schema with dev skill. Trimmed redundant cross-reference note.

### Changes
- Moved `TeamCreate` + `TaskCreate` from Pre-flight steps 6-7 into Phase 1 after `docket vote create` — pre-flight required a vote-id that didn't exist yet
- Added `protocol_version: "1"` and `request_id` to delegation_request example to match dev/SKILL.md schema
- Trimmed two-line cross-reference blockquote to a single line (section being referenced is the next one)

### Dimensions Evaluated
Over-Engineering, Coherence, Actionability, Completeness, Skill Design Quality, Orchestration & Agent Teams, Spec Alignment, Rename

### Rename
No rename.

## 2026-04-06

### Summary
Fixed critical nested agent spawning bug: replaced broken Execution Mode Detection (tool-availability check that never triggers for team agents) with team-context awareness. Added explicit team-spawning prohibition to Rules.

### Changes
- Rewrote Execution Mode Detection to use team-context (team_name presence) instead of tool availability — fixes root cause of team agents spawning reviewer sub-agents
- Added Rule 2: explicit prohibition on agent spawning from within a team, with delegation protocol redirect
- Rewrote description to distinguish standalone (spawns reviewers) vs team (delegates to orchestrator) behavior
- Renamed "Sub-Agent Path" to "Team Path" in Delegation Protocol header
- Added "Standalone Mode Only" header and team-mode note to Reviewer Prompt Template section
- Removed trailing blank lines
- Fixed duplicate Rule 3 numbering (renumbered to 3-6) — coherence fix

### Dimensions Evaluated
Over-Engineering, Skill Design Quality, Actionability, Completeness, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-03-30

### Summary
Trimmed description to 250-char limit, simplified Execution Mode Detection, compressed Delegation Protocol and Audit Trail. Net -29 lines.

### Changes
- Trimmed description from 271 to ~195 chars — removed trailing example list
- Replaced 10-line Execution Mode Detection with 2-line conditional (-8 lines)
- Compressed Delegation Protocol from 22 to 10 lines — inlined JSON schema, merged steps
- Compressed Audit Trail table from verbose 3-column to concise 2-column format (-4 lines)
- Added explicit `team_name` to `TeamDelete()` call for consistency with all other skills (coherence)

### Dimensions Evaluated
Over-Engineering, Skill Design Quality, Actionability, Completeness, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-03-30

### Summary
Added honest consensus integrity directive and reviewer honesty instruction; trimmed redundant audit verification procedure, mapping freshness note, and description. Net -15 lines.

### Changes
- Added "Consensus integrity over false agreement" directive after coordinator role statement (+5 lines)
- Added honest-reviewer instruction to Reviewer Prompt Template (+3 lines)
- Removed redundant Verification Procedure bash block — Audit Questions table is sufficient (-14 lines)
- Removed "Mapping freshness" maintenance note — meta-documentation, not executable (-3 lines)
- Tightened description to ~240 chars, front-loading key use case per 250-char limit (-6 lines)

### Dimensions Evaluated
Cross-Skill Coherence, Over-Engineering, Skill Design Quality, Actionability, Completeness, Orchestration & Agent Teams, Spec Alignment, Rename

### Rename
No rename.

## 2026-03-29

### Summary
Trimmed identity verdict mapping, folded Phase 3 into Phase 4, removed mid-protocol notification, upgraded effort to max. Net -22 lines.

### Changes
- Removed identity verdict mapping table (approve->approve) left over from request-changes removal (-12 lines)
- Folded Phase 3 (Quorum Evaluation) into Phase 4 — single command doesn't warrant its own phase (-7 lines)
- Removed "all reviews collected" operator notification — redundant with outcome notification (-3 lines)
- Replaced non-standard "ultrathink" directive with concrete reasoning instruction
- Scoped Mermaid diagram requirement to escalation reports only
- Upgraded effort from high to max for Opus 4.6 multi-agent coordination

### Dimensions Evaluated
Over-Engineering (primary), Skill Design Quality, Actionability, Coherence, Orchestration & Agent Teams, Completeness, Spec Alignment, Rename

### Rename
No rename.


## 2026-03-21

### Summary
Added operator observability via `[VOTE]`-prefixed SendMessage notifications at phase transitions; removed unsupported `request-changes` reviewer verdict.

### Changes
- Added SendMessage notification to operator after proposal creation (Phase 1) with `[VOTE]` prefix
- Added SendMessage notification to operator after all reviews collected (Phase 2)
- Added `[VOTE]` prefix to existing Phase 4 SendMessage calls for consistent filtering
- Removed `request-changes` from reviewer verdict options and mapping table (not a valid `docket vote cast` verdict)

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration & Agent Teams, Coherence, Spec Alignment, Rename

### Rename
No rename.

## 2026-03-20

### Summary
Trimmed redundant explanations, consolidated View Change section, added --findings-json support.

### Changes
- Removed verbose stdin piping explanation from Phase 1 (-1 line)
- Added `--findings-json` as alternative to `--findings` in Phase 2 vote casting
- Trimmed Delegation Protocol step e from 3 to 2 lines
- Simplified argument handling description
- Consolidated View Change Constraints into parent section (-5 lines, +1 folded)

### Dimensions Evaluated
Over-Engineering, Completeness, Actionability

### Rename
No rename.

## 2026-03-20

### Summary
Fixed CLI flag usage to match docket vote capabilities; corrected verdict mapping; added `docket vote commit` for finalizing proposals.

### Changes
- Used dedicated `--rationale`, `--domain-tags`, `--files-changed` flags on `docket vote create`
- Fixed verdict mapping: `approve-with-concerns` is a native CLI verdict
- Added `--summary` flag to `docket vote cast` command template
- Added `docket vote commit` step to Phase 4 when quorum is reached
- Removed redundant rule 5 and obsolete "Behavioral change" note

### Dimensions Evaluated
Actionability, Completeness, Over-Engineering, Spec Alignment

### Rename
No rename.

## 2026-03-20

### Summary
Added full agent team lifecycle (TeamCreate/TaskCreate/TaskUpdate/TeamDelete) to align with all other skills.

### Changes
- Added TeamCreate, TaskCreate, TaskUpdate, TaskList, TaskGet, TeamDelete to allowed-tools
- Added team creation and task creation to Pre-flight (steps 5-6)
- Updated reviewer spawn template to include team_name parameter
- Added task assignment and TaskList monitoring to Phase 2
- Added TaskUpdate completion instruction to reviewer template
- Added Wrap-up & Team Cleanup section with shutdown and TeamDelete
- Added rules 1 (create team before spawning) and 7 (clean up the team)

### Dimensions Evaluated
Orchestration Effectiveness, Coherence with Other Skills

### Rename
No rename.

## 2026-03-20

### Summary
Fixed inconsistent `$ARGUMENTS` references to align with the skill's own `{proposal}` convention.

### Changes
- Replaced `$ARGUMENTS` in Pre-flight step 2 with plain language matching `{proposal}` convention
- Replaced `$ARGUMENTS` in Phase 1 Pre-Prepare with plain language matching `{proposal}` convention

### Dimensions Evaluated
Coherence with other skills (argument handling consistency)

### Rename
No rename.

## 2026-03-20

### Summary
Removed unused team tools from frontmatter, added SendMessage cross-communication for result reporting, and trimmed redundant content.

### Changes
- Removed TeamCreate/TeamDelete from allowed-tools (unused — vote spawns ephemeral agents, not teams)
- Added SendMessage instructions in Phase 4 for reporting results to invoking agents
- Added SendMessage to view-change escalation path
- Removed redundant "records are permanent" statement
- Removed redundant rule 2 (quorum arithmetic) — duplicates Phase 3 statement

### Dimensions Evaluated
Skill Design Quality, Orchestration Effectiveness & Cross-Communication, Over-Engineering

### Rename
No rename.

## 2026-03-20

### Summary
Added `effort: high` frontmatter, trimmed reviewer prompt scales, enabled ultrathink for deep reasoning, and consolidated duplicate rules.

### Changes
- Added `effort: high` frontmatter (new Claude Code capability)
- Trimmed confidence/domain_relevance scale descriptions in reviewer prompt (-6 lines)
- Added ultrathink trigger to reviewer prompt template for extended thinking
- Removed redundant request-changes verdict explanation (-1 line, implicit in formula)
- Consolidated rules 1+2 into single independence rule (-1 line)
- Renumbered Rules section (was 1,2,4,5,6,7 — now 1-6)
- Added "This applies to ALL agents spawned by this skill." to CRITICAL banner

### Dimensions Evaluated
Skill Design Quality, Completeness, Over-Engineering, Coherence with Other Skills

### Rename
No rename.

## 2026-03-19

### Summary
First evolution cycle. Added coherence conventions, removed duplication, and fixed Claude Code anti-patterns.

### Changes
- Added TeamCreate/TeamDelete to allowed-tools (convention alignment with dev/specs)
- Added no-commit guard (convention alignment with all other skills)
- Removed duplicate quorum threshold table (verbatim copy in Phase 3)
- Replaced Bash cat-redirect with Write tool for consensus records
- Trimmed consensus record schema (removed nested proposal duplication)
- Consolidated code review agent selection rows
- Removed redundant request-changes/reject usage guidance

### Dimensions Evaluated
Skill Design Quality, Over-Engineering, Coherence with Other Skills, Actionability

### Rename
No rename.
