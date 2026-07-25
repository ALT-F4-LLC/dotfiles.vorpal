# Changelog: commit

## 2026-07-24

### Summary
Closed a documented-vs-implemented gap in the Step 3 forbidden-content check and a false abort message that could leave a dirty index unreported. `commit_msg_check.sh`'s rule-3 regex matches only five literal tokens (`session_id`/`task_id`/`vote_id`/`teammate`/`docket`), so model/tier names and bare teammate names that rule 3's prose forbids passed the mechanized check silently; Step 3 now states exit 0 is necessary but not sufficient for rule 3. The permission-mode failure row asserted "Nothing was staged/committed" even when `git add` had already succeeded. Findings: 4 sub / 3 cos / 2 rej / 1 def / 1 enc

### Changes
- AMPLIFY[SUBSTANTIVE]: Step 3 documents rule 3's un-mechanized residual scope (model/tier names, bare teammate names) and narrows the adjacent "always matches what's documented" overclaim.
- AMPLIFY[SUBSTANTIVE]: Step 4 documents the guard hook's interactive `ask` path — two separate operator prompts, not one.
- AMPLIFY[SUBSTANTIVE]: Failure Modes permission-mode row no longer claims a clean tree unconditionally; names the staged fileset when git add already succeeded.
- CULL[COSMETIC]: 1Password row and post-commit-mismatch row shortened to cite Step 5 instead of restating it (I-commit-1 partial).
- COSMETIC: corrected "fail all four checks" → "fail that check" (rule-specific accuracy).
- REJECTED: historical-auditor's guard-hook-false-positives-on-prose finding — verified fixed in the hook's quote-aware pre-pass.
- AMPLIFY[SUBSTANTIVE]: CRITICAL banner item (5) now enumerates all four tools `disallowed-tools` strips (`Edit`, `Write`, `Agent`, `SendMessage`), matching review-and-comment's clause byte-for-byte (CALLER-SIDE-EFFECT).

### Dimensions Evaluated
Actionability, Completeness, Coherence, Over-Engineering (Pass B). Skill Design Quality: frontmatter verified accurate (no phantom `Task` entry), but its banner under-enumerated the stripped tools — fixed. Orchestration: leaf skill, no agent use.

### Rename
No rename.

## 2026-07-20

### Summary
Removed false-positive gap in the forbidden-content self-check and de-drifted
three cross-file citations. Step 3 rule-2's issue-ID grep now pipes through an
allowlist so standard technical tokens (UTF-8, SHA-256, RFC-7231, ISO-8601,
CVE-2024-…) no longer force removal of legitimate commit-body content, keeping
the "zero surviving matches = clean" invariant honest. Three
`senior-engineer.md:NNN` line-number citations (all stale — 354 blank, 351
tech-debt prose) re-anchored to stable section names ("Shared-tree diff
scoping", "Commit-mode only"); one stale quote (`git add .` → `git add`) fixed.

### Changes
- Step 3 rule 2: append `| grep -viE '\b(UTF|SHA|RFC|ISO|TLS|SSL|AES|CVE)-[0-9]+\b'` and document the allowlist.
- Steps 0/1/2: replace 3 drifted `senior-engineer.md:NNN` citations with stable prose anchors; correct one stale quote.

### Dimensions Evaluated
Actionability, Completeness, Coherence (reference accuracy). Model-routing: no
data-grounded change (2× sonnet, 0 errors). Innovation/L9 (commit_msg_check.sh,
DKT-22) and L10 (guard-hook, DKT-23) explicitly out of scope this cycle.
