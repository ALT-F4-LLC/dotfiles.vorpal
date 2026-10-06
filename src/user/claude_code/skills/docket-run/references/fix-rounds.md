# Fix-round ancestry map

Consumer: the docket-run skill, whose step 2 points here when a dispatch
carries a fix round's review fanout. Read this file in full before
composing that dispatch's launches.

**A dispatch carrying a fix round's review fanout also carries
`integrated`.** For instances `name@N#k` with N ≥ 2, map each such issue
to the sha of the integration commit of the write step the judged tree
was built on: round N-1's integration (fix@(N-1)'s, or the implement
round's when N-1 is the implement round), never fix@N's own, since fix@N
produced the tree the judges are about to read. wave.js asserts the
judged tree descends from that commit (`git merge-base --is-ancestor
<integrated sha> <target sha>`) and parks the round `parked-base-ancestry`
when it does not. The sha must be the integrated one; the writer's sha is
never an ancestor of the shared branch even after landing.

**Round off-by-one trap:** if fix@N has already been integrated before its
own fanout dispatches, fix@N's integration commit is the wrong sha: it
post-dates the judged tree, so wave.js's ancestry self-check detects it,
logs "wrong round, fail-open", and dispatches the round without the
ancestry guard, leaving that fanout unguarded. Ask "which
write step built the tree these judges will read?" and pass the
integration of the one before it. Derive it fresh each time: the writer
sha for round N-1 is that round's change-summary first line, and its
integration commit is `git log --format='%H %s' --grep="cherry picked
from commit <writer sha>"` on the shared branch. Confirm direction: `git
log -1 --format=%B <the sha you are about to pass>` must not end in
`(cherry picked from commit <the round's own writer sha>)`.

Omit the field only with no fix-round fanout at all. Omit one issue's
entry only when its previous round was never integrated (no matching
`cherry picked from commit` trailer on the shared branch); a fanout for
round N dispatched alongside fix@N still needs round N-1's entry.
wave.js fails open on a missing entry and logs it, but an entry you
cannot re-derive is omitted, never guessed.
