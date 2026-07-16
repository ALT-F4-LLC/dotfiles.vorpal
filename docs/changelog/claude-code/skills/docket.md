# Changelog: docket

## 2026-07-15

### Summary
Phase 3 disambiguation: added a precedence carve-out to the new Quick Start flag-reference note, resolving its ownership collision with the evolve-* Phase-0 ground-truth gates that mandate `docket --help` verification. Findings: 1 → 1 sub / 0 cos / 0 rej / 0 def / 0 enc

### Changes
- AMPLIFY[SUBSTANTIVE] Quick Start flag-reference note: a governing gate that explicitly names `--help` as its verification source (e.g. evolve-* Phase-0 ground-truth check) outranks the in-file lookup shortcut (DISAMBIG 1, overlapping-ownership).

### Dimensions Evaluated
Disambiguation (confusable-name, multi-reading, overlapping-ownership)

### Rename
No rename.

## 2026-07-15

### Summary
Applied 2 pre-approved DKT-334 findings: a Quick Start pointer discouraging redundant `docket --help` re-runs, and a Comments-section callout naming the correct `-m` comment form vs. the nonexistent `-b`/`--body` flag and `comment create` subcommand. Findings: 2 → 2 sub / 0 cos / 0 rej / 0 def / 0 enc

### Changes
- AMPLIFY[SUBSTANTIVE] Quick Start: added a rule pointing agents to the in-file flag reference and instructing against re-running `docket --help` absent suspected version drift (H1).
- AMPLIFY[SUBSTANTIVE] Comments: added a common-mistakes callout documenting `docket issue comment add -m "<message>"` as correct and naming `-b`/`--body` and `comment create` as wrong (H2).

### Dimensions Evaluated
Actionability, Coherence

### Rename
No rename.
