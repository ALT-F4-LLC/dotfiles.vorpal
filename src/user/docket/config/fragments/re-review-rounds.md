---
fragment: re-review-rounds
version: 8
---
# Re-review rounds

On a re-review round, your inputs include prior findings. Compare the current
state with the previous reviewed state. For each prior finding in your dimension,
retain its ID and state whether it is closed or still open, citing applicable
evidence. Close a finding when evidence establishes that its original defect is
resolved or its claim was invalid; a changed implementation or an author's
"fixed" claim is insufficient. Preserve established dispositions unless new
evidence invalidates them. Report missing evidence as a verification gap; do not
invent closure or claim that an unverified defect was reproduced.

Carry forward unresolved findings at their supported severities, including
`blocker`, unless new evidence or an explicitly accepted requirement change
justifies reassessment; they remain part of aggregation without counting as
new discoveries. A partial fix, moved manifestation, or restatement of the
same underlying defect updates the existing finding, and a new location alone
does not make a finding new.

Examine the changes and the behavior they affect, including unchanged callers,
dependencies, and contracts where needed to establish their effects. Do not
re-derive recorded findings whose relevant evidence remains unchanged. New
evidence can justify reassessment at an unchanged location; identify what changed
in the evidence. If the previous reviewed state or relevant history is missing,
state the comparison gap and limit claims about origin and closure accordingly.

## Apply the same top-severity bar on every round

Every `blocker` must meet the governing severity ladder's top rung. Regression
or recurrence establishes relevance to this round, not severity: a returned
minor defect remains minor unless its supported impact now meets a higher
rung.

For a new or reopened `blocker`, identify the triggering conditions, supporting
evidence, violated requirement or contract, and the applicable Blocker criterion.
Establish its relationship to the change; for a recurrence, link the prior
finding and explain why its closure no longer holds. Apply the round-0 test:
had this exact defect appeared in round 0 under the same requirements, would
the same evidence and stated impact have made it a Blocker? If not, use the
lower rung the ladder supports.

A fix that independently meets the Blocker rung remains a Blocker, including
data loss, a security regression, a broken build or test, or a violated
acceptance criterion as defined by the ladder. Grade missing tests, adjacent
cases, broader remedies, and maintainability risks by their demonstrated impact.
When their established impact is below the Blocker rung, report them at Concern
or below. Keep unresolved evidence gaps explicit rather than mechanically
downgrading an unverified claim.

Distance from an ideal fix is not itself a defect or a reason to escalate.

Keep supported lower-severity findings visible at reconcile, in the run
record, and at the operator gates before publishing. Under max aggregation on
a track whose ladder starts an automatic fix loop, one top-severity finding
can trigger another round: grade each finding on its supported severity alone,
neither promoting an optional improvement to trigger another round nor
suppressing or downgrading a supported top-severity finding to finish the
loop. Accept a clean delta when warranted; finding counts are diagnostic,
never a target that must decrease.
