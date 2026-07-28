# Changelog: commit

## 2026-07-27

### Summary
Closed the pre-commit stale-index gap (H14). Step 1's index precheck aborted on ANY non-empty index and asserted, without ever comparing, that the staged content was "not part of this commit's fileset" — false in the `MM` case (a path staged by an earlier fix round then edited again), which was a live condition in this tree at review time (10 `MM` entries). Step 1 now reads both porcelain status columns and partitions the staged set, blocking only on out-of-fileset paths. Net +771 bytes (20,800 → 21,571). Findings: 2 sub / 0 cos / 1 routed (I14) / 1 out-of-scope (I13)

### Changes
- AMPLIFY[SUBSTANTIVE]: Step 1.2 switches `git status --short` → `--porcelain` (stable across git versions and user config per git-status(1)) and documents the X/Y column semantics, so `MM` is actually read rather than merely emitted.
- AMPLIFY[SUBSTANTIVE]: Step 1.3 partitions `git diff --cached --name-only` against the fileset — in-fileset staged paths are the caller's own stale index and are refreshed by Step 4's `git add` (confirmed by Step 4's existing staged-set equality check); only out-of-fileset paths abort. Removes a false abort and an unverified claim in the `Blocked:` message.
- ROUTED: I14 (CANONICAL:CALLER-SIDE-EFFECT parity with review-and-comment) → Phase 2; touches a second file outside this cycle's edit scope.
- OUT OF SCOPE: I13 (`commit_execute.sh` consolidation) — new script, routed to Docket.
- CONFIRMED NO-OP: S10 — this file's Step 0 "STOP:"/"Blocked:" wording is ground truth; the "ABORTs" drift is agent-side and already routed to evolve-agents.

### Dimensions Evaluated
Actionability (2 defects found, both fixed), Completeness, Coherence, Over-Engineering, Redundancy, Skill Design Quality, Orchestration, Byte Budget (20,800 → 21,571).

### Rename
No rename.

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
