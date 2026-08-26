---
fragment: re-review-rounds
version: 4
---
# Re-review rounds

On a re-review round (your inputs carry a previous round's findings), scope to
the delta: state whether each prior finding in your dimension is closed or
still open, examine what changed since, and do not re-derive findings at
unchanged loci a prior round already recorded. Repetition is not discovery,
and flat finding volume across rounds is the signal a fix loop cannot
converge on.

## The Blocker bar rises on re-review

The loci a fix touched are legitimately new ground, and a genuinely new defect
there is a real finding; report it at its honest severity. But under max
aggregation one `blocker` from one judge at one new locus spends an entire fix
round, and a fresh fix diff reliably offers new loci, so a loop whose rounds
each blocker-ize the previous round's fix never converges (measured, in a past run:
finding volume 20 → 16 → 17 across three rounds while the loci rotated; each
round's blockers were about the previous round's fix). On a re-review round,
emit `blocker` ONLY when one of these holds:

- **Regression**: a defect a prior round recorded as fixed is back, or the
  fix broke behavior that was correct before it ran.
- **The fix independently meets the Blocker bar**: it introduces data loss, a
  security regression, a broken build or test, or a violated AC, established
  on its own evidence, exactly as the severity ladder defines the rung. The
  test: had this exact code appeared in round 0, you would have called it a
  Blocker then, for the same stated reason.

Everything else about the fix is authored at Concern or below: it is unpinned
by a new test (unless that gap itself meets the ladder's Blocker rung), it is
narrower or less elegant than the ideal remedy, it would ideally also have
handled an adjacent case, its shape invites future defects. "The ideal fix
would also have done X" is distance from ideal, distance from ideal is never a
Blocker, and on a re-review round it is the exact finding class that starves
the loop of convergence. Those findings lose nothing by being `high`: they
surface at reconcile, land in the run record, and are weighed at the operator
gates before publishing; the loop is simply not their venue.
