# Changelog: vote

## 2026-03-29

### Summary
Aggressive trim from 616 to 466 lines. Removed verbose pass/fail JSON examples, compressed Delegation Protocol, folded Wrap-up into Phase 4, tightened language.

### Changes
- Removed 85-line Pass/Fail Examples from Audit Trail (Verification Procedure is sufficient)
- Compressed Delegation Protocol from 73 to ~45 lines (inline JSON, response table)
- Folded Wrap-up into Phase 4 as mandatory cleanup step with stronger language
- Compressed domain-specific checklists from paragraphs to table
- Consolidated Rules from 6 to 4 (removed duplicates of in-section instructions)
- Tightened coordinator description to remove academic PBFT framing
- Compressed Audit Trail preamble and Phase 1 redundant bullets

### Dimensions Evaluated
Over-Engineering (primary), Skill Design Quality, Orchestration & Agent Teams, Actionability, Coherence, Spec Alignment, Rename

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
