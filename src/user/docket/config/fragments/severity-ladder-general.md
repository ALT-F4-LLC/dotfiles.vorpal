---
fragment: severity-ladder-general
version: 1
---
# Severity ladder — general

- **Blocker** — must fix: data loss, a breaking change with no migration, a critical
  missing test on a privileged path, or any hard-gate symptom.
- **Concern** — should fix or explicitly justify: a pattern violation, a missing edge
  case, a test gap on a non-critical path.
- **Suggestion** — worth considering here or later: a better approach, a minor
  improvement.
- **Question** — clarification you need before the judgment can be completed. A question
  is a real result; do not convert one into a guess.
- **Praise** — a pattern worth highlighting. Recording what is right is not padding: it
  tells the next reader which parts were examined and found good.

This vocabulary is the general track's own. Keep it distinct from the security ladder —
the two have bled into each other before, and a merged vocabulary makes a Blocker and a
Critical indistinguishable to anything reading downstream.

**Emit-time mapping.** The words above are the authoring language; you reason and write
in them. The `severity` field of the findings payload takes 02 §6's five values, and the
three defect rungs map onto them as follows. The remaining two are not defects and do not
become payload entries at all:

| Author as  | Emit as   | Why                                                     |
|------------|-----------|---------------------------------------------------------|
| Blocker    | `blocker` | must fix — the ONLY value that opens a fix round        |
| Concern    | `high`    | recorded and surfaced; resolved at gates, never looped  |
| Suggestion | `low`     | below every gate; leaves `medium` free (see below)      |
| Question   | body — or a `gap` | not a defect; see below                         |
| Praise     | body only | a payload entry is a defect record                      |

**Only a Blocker opens a fix round** (operator convergence policy, 2026-08-10). The
fix loop's question is "may this change ship?", and a loop keyed on anything judges
can produce indefinitely never closes — measured: three rounds and a growing findings
payload on a five-line change. So `blocker` is the loop's whole fuel, and a Blocker
means exactly that: the change as it stands must not ship — an AC violated, the build
or tests broken by the change, a security regression, data loss. Distance from ideal
is never a Blocker.

**Concern is `high`, not `medium`, and its venue is the RECORD, not the loop.** A
Concern is "should fix or explicitly justify" — the justification now happens where a
human can weigh it: `high` outranks everything below it in cluster medians, is what a
held cluster's disagreement is measured over, surfaces at the reconcile and operator
gates, and lands in the run record and backlog the operator reviews before publishing.
What it no longer does is conscript a fix round: mechanical rework is the Blocker's
venue alone.

**Suggestion is `low`, keeping `medium` in reserve.** Both sit below every gate, so
routing does not distinguish them. `low` is the better home because a cluster's
severity is a median over its members, and a security judge on the same change emits
on a ladder whose serious values route to a human security vote; parking
general-track niceties at `low` keeps them from pulling a mixed cluster upward.
`medium` stays available for a Concern you have deliberately downgraded but are not
willing to drop.

**A Question is not a severity.** `severity` orders defects, and no value on it means "I
could not judge." Emitting `info` files a blocking question as the least consequential
thing in the set — backwards for something this ladder calls a real result; emitting
`blocker` invents a defect and opens a fix round with nothing to fix. So route by whether
the question blocks you: one that does **not** block the judgment is commentary and lives
in the markdown body; one that **does** takes the gap path your contract already names —
emit your findings plus a `gap` note saying exactly what you could not resolve.

**Praise lives in the body.** Every payload entry carries a severity and reads downstream
as a defect. Recording what is right tells the next reader what was examined and found
good — that is a body function, and filing it as `info` would put a compliment into the
cluster median.

**Report every finding; do not self-filter.** Severity is a classification, not a
suppression mechanism. A finding a linter would also catch is reported at `Suggestion` —
never omitted. Declining to report something you found because it seemed minor is a
recall defect, and filtering happens downstream where the whole set is visible, never at
authoring time.

**Better, not perfect.** Severity tracks the change's effect on health, not its distance
from ideal. A perfection delta that does not threaten correctness is a `Suggestion`, and
never a Blocker or Concern — on a change that definitely improves overall code health,
inflating a preference into a blocking finding is itself the defect. Where a change is
net-positive but too large or too mixed to judge cleanly, say that plainly rather than
blocking it on principle.

**Every Blocker and Concern names the general rule it instances**, not only its one-line
fix. A finding that teaches the class prevents the next instance; one that patches the
symptom buys a single line.

**Attention follows risk.** On large changes, concentrate on the fraction of the code
carrying most of the risk, and say what you did not examine closely rather than implying
uniform depth.
