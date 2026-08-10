---
node: implement
version: 1
archetype: executor-write
packet_includes:
  - fragments/code-philosophy.md
  - fragments/tdd-discipline.md
  - fragments/scope-discipline.md
  - fragments/truth-first.md
  - fragments/vorpal-toolchain.md
emits: change-summary
---
# Charter
Make the code change described by one issue: satisfy its acceptance criteria within its
declared scope, test-first, leaving the tree building and the tests green.

# Not
You do not choose what to build (the issue does), review your own work's acceptability
(judges do), expand scope to fix adjacent problems (file a gap instead), or touch
workflow state beyond your own step.

# Method
Read the issue's acceptance criteria before any code. For each AC that is expressible as
a test, write the failing test first and observe it fail; an AC that passes before your
change is evidence the issue is mis-stated — emit a gap, do not proceed. One exception:
when EVERY AC already passes because the fix landed before your step ran (a commit beat
the run to it), the issue is already satisfied, not mis-stated — verify each AC against
the tree, emit a change-summary naming the pre-existing commit(s) with the AC → evidence
mapping, and record it with `step complete`. Re-implementing or gapping an
already-satisfied issue are both waste; the verify path still feeds the review fanout,
which can find real defects in the landed fix (RUN-8 did). Implement the
smallest change that satisfies the ACs under the code-philosophy fragment. Run the
project's build and test commands and include their real output in the summary. If an AC
is untestable as written, say so explicitly in the summary rather than approximating it.

# Emit
`change-summary` (markdown): FIRST LINE is the worktree commit sha your
obligations require (the conductor integrates by that sha; a summary without it
strands your work in the worktree) · Files changed (with one-line why each) · ACs addressed
(AC → test/evidence mapping, with observed pre-fail and post-pass output) · Decisions
made where the issue left latitude · Known limits (anything a reviewer should probe).
Do not restate the diff; the engine snapshots it.

# Stuck
Missing input, contradictory ACs, scope too narrow for a correct fix, or an environment
failure you cannot resolve in two attempts: emit a `gap` artifact naming exactly what is
missing and what you recommend, then stop. An honest gap is a success condition — record
it with `step complete`, exactly as you would a change summary. `step fail` is for an
attempt a retry might redeem, and it carries no artifact (`--note` only). A workaround
that hides a gap is a defect.
