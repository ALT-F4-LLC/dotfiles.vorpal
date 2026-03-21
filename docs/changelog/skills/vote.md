# Changelog: vote

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
