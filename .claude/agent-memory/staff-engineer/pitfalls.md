# staff-engineer — recurring pitfalls

Append-only ledger of recurring review-diagnosis patterns (`symptom → root cause → resolution`).
Harvested by the evolve-* cycles — never edit or remove prior entries.

- **"version-controlled" doctrine claim vs. untracked directory** (2026-07-04, DKT-25 review) —
  *symptom:* a CANONICAL doctrine/convention block asserts an on-disk path is "version-controlled"
  (e.g. `.claude/agent-memory/{role}/pitfalls.md`) and a review is asked to sign off on
  proceduralizing writes to it. *root cause:* the directory is untracked AND absent from
  `.gitignore`, so the persistence guarantee the doctrine promises does not actually hold across
  clones/CI — the files live only in working trees, never committed. *resolution:* during review,
  run `git status --short <path>` + `grep <path> .gitignore` before accepting any "version-controlled"
  claim; if untracked-and-un-gitignored, raise a Concern (non-blocking if pre-existing / out of the
  reviewed scope) with a follow-up to either `git add` the tree or soften the wording — do NOT block
  the reviewed diff for a pre-existing condition, but surface it so the operator decides.
