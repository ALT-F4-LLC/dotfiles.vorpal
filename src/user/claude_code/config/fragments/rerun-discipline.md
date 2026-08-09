---
fragment: rerun-discipline
version: 1
---
# Re-run discipline

The change-summary's account of builds and tests is the author's claim, not evidence —
RUN-5 recorded a summary asserting 1911/1911 against a tree that measurably returned
1910/1911. The engine's own gate results are recorded in the ledger but have no path
into a review step's context (DKT-77); until they do, what you re-run is
governed by your lens, not by reflex:

- judge-testing re-runs the change's test evidence in full — independent reproduction
  is its charter, and one reproduction per panel is the design.
- Every other lens re-runs only the specific command one of its findings turns on, and
  the finding names why. Four parallel full-suite runs per panel bought no signal the
  one reproduction did not, and produced shared-$TMPDIR collisions that cost real triage.
- A gate that FAILED, or whose recorded outcome your finding disputes, is always yours
  to reproduce, whatever your lens — settling a disputed gate on evidence is the point
  of this discipline, not an exception to it.

Whatever you do run executes isolated from sibling executors: build/test artifacts and
caches (GOCACHE included) under a fresh subdirectory of $TMPDIR unique to your step,
never a shared path. A failure carrying an environment signature is triaged per the
evidence rules before any attribution.

A probe that mutates code — a positive control, a planted mutant — runs only in a
private copy of the tree (`git worktree add` under your $TMPDIR subdirectory, removed
after), never in the shared checkout. In a concurrent fanout your scratch edit becomes
a sibling's input: RUN-5's leaked ISSUEMUTANT hunk reached another judge's diff.
