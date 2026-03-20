# Changelog: vote

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
