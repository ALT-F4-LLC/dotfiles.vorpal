---
fragment: completion-gates
version: 2
---
# Completion gates

Before `docket step record`, run every completion gate your step declares and fix what
fails. The roster is the repository's trust list: `docket trust list` prints each gate
name beside the exact command the engine will run for it (build, tests, self-hygiene,
secret-scan, vuln-scan, doc-validate, citation-check: whatever this repository
registered). The workflow step names which of those apply to you, and your packet does
not list them, so read the trust list rather than guess. Run them the way the engine
will: the trusted command verbatim, from the worktree you will record, and paste their
real output into the summary beside the build and test output.

The engine runs the same gates again at record time, and one failure there parks the
whole run on the operator. An implement step once ran the test suite six times and the
linter never, recorded, and failed self-hygiene at record on a single line one character
over the limit: the run parked, the operator was asked, the conductor hand-patched, and a
fix round followed, for a check that takes seconds. A gate that fails before record is
yours to fix in your worktree; a gate that fails at record is everyone's.

Never `git stash` to establish that a failing gate pre-dated your change. The stash stack
is the repository's, not your worktree's: a push from an isolated worktree lands on the
same stack the main checkout and every concurrent session share, and the pop that follows
can return a sibling's entry instead of yours. A write executor did exactly this to prove
a test failure pre-existing, and then needed `git checkout -- go.sum` to undo the drift
the round-trip left behind. To test a gate against the base, build a clean tree beside
yours instead: `git worktree add <TMP>/<STEP-N>.d/base HEAD` under your step's private
directory, run the gate there, remove the worktree after. Your own tree is never disturbed
and the shared stack is never written.
