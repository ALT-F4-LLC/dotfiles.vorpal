# Changelog: docket

## 2026-07-24

### Summary
Phase 3 disambiguation: the `vote list --json --all` example's trailing comment ("default: open proposals only") read as describing the shown command's own behavior, when it actually describes the flag's absence — inverted on a literal reading.

### Changes
- CLARIFY[COSMETIC]: comment reworded to state both the `--all` and default (no `--all`) behaviors explicitly.

### Dimensions Evaluated
Coherence (disambiguation pass, Two-arm Boundary test — passed Arm 1 coherence, failed Arm 2 clarity).

### Rename
No rename.

## 2026-07-24

### Summary
Corrected the DB filename, documented the non-uniform `--json` output shapes behind the recurring AttributeError, and closed two reproduced exit-code-lies (empty comment message, claim-script false negative). Findings: 9 → 4 sub / 1 cos / 0 rej / 0 def / 4 enc

### Changes
- FIX[SUBSTANTIVE]: `.docket/docket.db` → `.docket/issues.db` in both occurrences — verified against `docket config --json` and a fresh `docket init`.
- AMPLIFY[SUBSTANTIVE]: replaced the `issue list`-only parsing note with a shape table covering every commonly parsed subcommand, plus the rule that sub-entity `list` returns a bare array while other list commands return an object with a named key + `total`.
- AMPLIFY[SUBSTANTIVE]: added the silent-truncation detector — `--limit` defaults 50/10 emit no warning; `total` counts the full match set.
- AMPLIFY[SUBSTANTIVE]: `comment add` with an empty message exits 0 writing nothing in human mode; `--json` turns it into a hard error. Includes the split-Bash-call stage-file corollary.
- AMPLIFY[SUBSTANTIVE]: `docket_claim.sh` exit 1 can be a false negative — second-granularity `updated_at`; verify via `issue show` before retrying.
- FIX[SUBSTANTIVE]: wrapper table: "Seven" → "Nine", added the missing `docket_promote.sh` and `vote_record.sh` rows.
- CULL[COSMETIC]: collapsed the comment-add rows duplicated across two tables into one pointer.

### Dimensions Evaluated
Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration, Coherence, Spec Alignment, Rename.

### Rename
No rename.

## 2026-07-22

### Summary
Phase 3 disambiguation: `vote_delegate.sh` wrapper-table row types its `<voters>` argument.

### Changes
- Deterministic Wrapper Scripts table's Encodes column now reads `vote create -n <voters>` with `<voters>` glossed as an integer voter count, not names — closing the count-vs-name-list two-reading in the CLI reference home.

### Dimensions Evaluated
Disambiguation (multi-reading).

### Rename
No rename.

## 2026-07-20

### Summary
Disambiguated three flag-reference Notes whose "required (when explicitly set)" phrasing read as conditional; all three verified unconditionally required in --json mode against the live CLI.

### Changes
- Reworded `vote create --voters` Note to "required in --json mode" with the verified VALIDATION_ERROR text — the old parenthetical invited omitting -n (Phase 3 disambiguation, multi-reading).
- Reworded `vote cast --confidence`/`--domain-relevance` Notes identically — live probe: omission exits 3 with "required in JSON mode".

### Dimensions Evaluated
Disambiguation (confusable-name, multi-reading, overlapping-ownership).

### Rename
No rename.

## 2026-07-20

### Summary
Closed the enum-discoverability gap that caused agents to guess invalid `--type` values (test/docs/spike) by inlining the Issue status/type enums into the create/edit/list flag tables, and surfaced the 5 deterministic wrapper scripts previously invisible to skill-only loaders. Findings: 3 → 3 sub / 0 cos / 0 rej / 1 def / 0 enc

### Changes
- AMPLIFY[SUBSTANTIVE] issue create/edit/list flag tables: inlined `--status` (`backlog`|`todo`|`in-progress`|`review`|`done`) and `--type` (`task`|`bug`|`feature`|`epic`|`chore`) enums into the Notes column, scoped to `docket issue` commands (doc/next/plan untouched) (L13).
- AMPLIFY[SUBSTANTIVE] new "Deterministic Wrapper Scripts" section citing docket_claim/close/write/create.sh + vote_delegate.sh with verified invocation syntax (L17).
- DEFER: flags.md progressive-disclosure split — file at 44% of TRIM threshold, churn unjustified (L15). L14 already encoded by existing Quick Start callout — no change.

### Dimensions Evaluated
Actionability, Discoverability, Completeness, Non-redundancy

### Rename
No rename.

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
