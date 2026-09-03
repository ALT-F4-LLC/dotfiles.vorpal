---
fragment: rerun-discipline
version: 5
---
# Re-run discipline

The change-summary's account of builds and tests is the author's claim, not evidence:
a past run recorded a summary asserting 1911/1911 against a tree that measurably returned
1910/1911. The engine's own gate results are recorded in the ledger but have no path
into a review step's context (a tracked gap); until they do, what you re-run is
governed by your lens, not by reflex:

- judge-testing re-runs the change's test evidence in full: independent reproduction
  is its charter, and one reproduction per panel is the design.
- Every other lens re-runs only the specific command one of its findings turns on, and
  the finding names why. Four parallel full-suite runs per panel bought no signal the
  one reproduction did not, and produced shared-$TMPDIR collisions that cost real triage.
- A gate that FAILED, or whose recorded outcome your finding disputes, is always yours
  to reproduce, whatever your lens: settling a disputed gate on evidence is the point
  of this discipline, not an exception to it.

Whatever you do run executes isolated from sibling executors: build/test artifacts and
caches (GOCACHE included) under a fresh subdirectory of $TMPDIR unique to your step,
never a shared path. A failure carrying an environment signature is triaged per the
evidence rules before any attribution.

When you compare two outputs, write both to files under that subdirectory and diff the
files. Process substitution (`diff <(...) <(...)`) and a diff read from stdin are refused
under the sandbox ("Operation not permitted" on `/dev/fd/N`), and a lift is never the
answer; the refusal is the environment, not a finding.

A probe that mutates code (a positive control, a planted mutant) runs only in a
private copy of the tree (`git worktree add` under your $TMPDIR subdirectory, removed
after), never in the shared checkout. In a concurrent fanout your scratch edit becomes
a sibling's input: in an earlier run, one judge's leaked planted-mutant hunk reached
another judge's diff.

`git stash` is never how you get a clean tree, there or anywhere. The stash stack is the
repository's, not your worktree's: a push from an isolated worktree lands on the same
stack the main checkout and every concurrent session share, and the pop that follows can
return a sibling's entry instead of yours. To run a command against the base rather than
your tree, `git worktree add <TMP>/<STEP-N>.d/base HEAD` under your step's private
directory, run it there, and remove the worktree after.
