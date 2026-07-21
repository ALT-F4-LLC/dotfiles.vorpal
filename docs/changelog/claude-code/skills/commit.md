# Changelog: commit

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
