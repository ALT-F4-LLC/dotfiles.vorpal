# Changelog: verify

## 2026-05-17

### Summary
Workflow-boundary cleanup: removed PR scope (dead surface for @sdet, who is Docket-issue centric per `agents/sdet.md`); strengthened Pre-flight §5 with "do not substitute completion comment for diff" warning lifted from @sdet's load-bearing rule; deduplicated peer-SendMessage and vote-trigger guidance against canonical banner and agent file.

### Changes
- Argument Handling: dropped PR-number and PR-URL rows from scope table; updated usage error to redirect PR review to Skill(code-review).
- Argument Handling: dropped `gh`-availability ambiguity rule (unreachable after PR removal).
- Pre-flight §5: added "do not substitute completion comment for diff" warning (from agents/sdet.md §Verification Workflow §2).
- Pre-flight §7: dropped redundant scoping preamble.
- Save & Return: vote-trigger bullet now defers to agents/sdet.md.
- Common Discipline: dropped redundant peer-SendMessage sentence (canonical banner owns this).
- Failure Modes: dropped `gh`-CLI-unavailable row.

### Dimensions Evaluated
Over-Engineering (HIGHEST), Coherence (workflow boundary with code-review, @sdet agent file), Actionability (Pre-flight §5).

### Rename
No rename.

## 2026-05-16

### Summary
Phase 2 coherence pass: Common Discipline now includes the AskUserQuestion structural contract (added to design-review this cycle).

### Changes
- Common Discipline: added "with 1-4 questions, each having 2-4 options and a `header` ≤12 chars" to the AskUserQuestion guidance — parity with design-review/code-review/design-qa.

### Dimensions Evaluated
Coherence (operator-prompt contract).

### Rename
No rename.

## 2026-05-16

### Summary
First changelog entry. Five over-engineering + coherence fixes: scoped spec-read examples for parity with code-review, compressed Pre-flight Docket-CLI enumeration to a single sentence (CLI guidance lives in agents/sdet.md), trimmed Failure Modes table to rows with new abort text only (matches code-review trim pattern), aligned Save & Return Docket move/close phrasing with agents/sdet.md, deduplicated Save & Return emission preamble against Output Contract.

### Changes
- Pre-flight §7: spec-read scope now names concrete examples + "skip the rest" — matches `code-review` §6 wording.
- Pre-flight §4: compressed 4-bullet Docket-CLI enumeration to one sentence; CLI procedure is owned by `agents/sdet.md`.
- Failure Modes table: dropped 6 rows that duplicated inline aborts; kept only CLI-unavailable + ignore-extras rows.
- Save & Return: aligned Docket move/close phrasing with `agents/sdet.md` (APPROVE → close+comment; ACCEPT WITH CAVEATS or BLOCK → `move review`).
- Save & Return: removed duplicate "no file / emit verbatim / no preamble" preamble — Output Contract owns those rules.

### Dimensions Evaluated
Over-Engineering (HIGHEST — primary cuts), Skill Design Quality, Actionability, Coherence (sibling skills + parent agent `agents/sdet.md`).

### Rename
No rename. `verify` is operator-aligned and family-aligned with report-emission siblings.
