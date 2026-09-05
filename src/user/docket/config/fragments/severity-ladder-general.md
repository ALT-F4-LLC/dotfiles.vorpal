---
fragment: severity-ladder-general
version: 5
---
# Severity ladder: general

Use this vocabulary for general-track review. Keep the security track's
authoring vocabulary and rubric distinct. Apply the supplied evidence rules
and review scope; grade supported impact and applicable requirements separately
from confidence.

- **Blocker** (must fix before shipping): an established violation of an
  applicable acceptance criterion (AC); a required build or test broken by the
  change; a security regression; data loss; or a breaking change without the
  migration or compatibility path the applicable contract requires. A missing
  test on a privileged path is a Blocker when an applicable release requirement
  makes that coverage necessary to ship: identify the requirement and missing
  case. Missing coverage alone does not prove faulty runtime behavior.
  Confirmed, unoverridden hard-gate findings also qualify, but only under the
  packet rule below. Distance from ideal never qualifies.
- **Concern** (should fix or explicitly justify): a supported issue below the
  Blocker bar, such as a consequential pattern violation, missing edge case,
  maintainability risk, or test gap on a non-critical path. State the consequence
  that makes action or justification warranted.
- **Suggestion** (worth considering here or later): a minor issue or concrete
  improvement with an identifiable benefit. A preference alone cannot justify
  promotion to Concern or Blocker.
- **Question**: clarification needed to complete or qualify a judgment. Preserve
  the uncertainty; use the body or gap route below.
- **Praise**: an observed pattern worth highlighting. Say what was examined and
  found good without implying broader coverage.

**Hard gates require the packet.** Apply `fragments/hard-gates.md` only when its
contents are supplied in your packet. Confirm the trigger and check its
counter-examples and override rules before raising a gate finding; a candidate
symptom alone is insufficient. In this general track, a confirmed, unoverridden
gate finding is a Blocker. A seat without that fragment raises no gate findings
and reconstructs no gate list from memory. It may report the same substance
within its own remit, using its own rubric and terms. If the packet says the
fragment is required but its contents are missing, report that coverage gap.

**Emit-time mapping.** Author findings using the terms above, then use 02 §6's
payload schema and this mapping. Do not substitute security-track labels.

| Author as | Emit as | Routing |
| --- | --- | --- |
| Blocker | `blocker` | The only severity eligible to open a fix round |
| Concern | `high` | Reconcile, run record, backlog, and operator gates |
| Suggestion | `low` | Recorded for downstream consideration; no fix round |
| Question | Body or contract-defined `gap` | No severity entry |
| Praise | Body only | No severity entry |

`medium` has no default authoring rung here. Use it for a downgraded Concern
only if the controlling contract explicitly defines that exception; record
the supported reason and required disposition. Uncertainty, iteration count,
or a desire to avoid a gate does not justify a downgrade. `info` is not a
substitute for a Question or Praise. Use the contract's existing representation;
do not invent fields or encode missing judgment as a defect severity.

**Only a Blocker opens a fix round.** Concerns remain visible for resolution or
explicit justification at reconcile and operator gates. Suggestions remain
recorded. Neither recruits another automatic fix round. Preserve unresolved
findings and their identities under the re-review contract; do not suppress a
supported Blocker to finish the loop or promote a preference to continue it.
No Blockers means no severity-triggered fix round, not permission to publish:
required checks, unresolved judgment-blocking gaps, and operator dispositions
still govern readiness.

**Aggregation does not set severity.** Under max aggregation, a `low` member
cannot raise a cluster already at `medium` or above. That says nothing about
disagreement: lowering a member can widen its distance from a higher member.
Keep Suggestion at `low` because it is the intended classification, not to
manipulate a hold. Follow the aggregation contract for cluster membership,
severity order, and held-spread calculation; do not assume an unstated formula
or tune a finding's severity to obtain a routing outcome.

**Questions and Praise stay outside severity.** A Question that does not block
judgment lives in the markdown body. One that does block judgment uses the
contract's `gap` path alongside any independently supported findings. State
what is unknown, which judgment depends on it, and what would resolve it; leave
that judgment incomplete and continue independent work. Neither `info` nor
`blocker` means "could not judge." Praise lives in the body and never enters
cluster arithmetic.

**Report every finding; do not self-filter for importance.** Preserve supported
minor findings for downstream filtering. Tool detectability does not change
severity: a style-only lint finding is a Suggestion; a tool-detectable defect
meeting a higher rung keeps that rung. Retain uncertain leads with their
evidence limitations under the evidence and gap contracts rather than dropping
them or asserting an unproven defect. Reporting is not a quota: a clean result
is valid when the examined evidence supports it.

**Better, not perfect.** Grade each finding by its supported consequence. Net
improvement does not erase an independent defect; possible elegance does not
create a mandatory fix. A supported maintainability or verification concern
need not demonstrate an existing runtime failure. If size or mixed scope
prevents a sound judgment, identify the affected coverage and gap rather than
declaring the size itself a Blocker.

**Teach the rule and disclose coverage.** Every Blocker and Concern names the
applicable general rule, observed instance, consequence, and evidence, not only
a one-line fix. On large changes, concentrate effort on the highest-risk paths
and state what was not examined closely; do not imply uniform depth.
