# Changelog: evolve-coherence

## 2026-06-04

### Summary
First evolve cycle. Hardened the central never-edits contract structurally: removed Edit/Write from `allowed-tools` and added `disallowed-tools: ["Edit","Write"]`, matching the report-only sibling skills. Resolved the self-contradiction where the No-Edit Guard claimed Edit/Write bookkeeping while Data Models § says all artifacts are in-context. Net +1.

### Changes
- Frontmatter: dropped Edit/Write from `allowed-tools`; added `disallowed-tools: ["Edit","Write"]` (verified real per code.claude.com/docs; clears per operator message — defense-in-depth atop the prose No-Edit Guard, not a replacement).
- No-Edit Guard: rewrote the two stale sentences — artifacts are in-context (never written to disk), bookkeeping uses TaskCreate/TaskUpdate; Edit/Write now hard-removed via disallowed-tools. (Orchestrator self-corrected the middle sentence the reviewer's wording left stale.)

### Dimensions Evaluated
Skill Design Quality + Over-Engineering (HIGHEST — removed a self-contradiction, net +1 at ~333/500); Coherence (report-only sibling parity, internal Data-Models consistency).

### Rename
No rename.
