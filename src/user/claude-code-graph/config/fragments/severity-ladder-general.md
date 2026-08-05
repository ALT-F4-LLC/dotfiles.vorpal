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
| Blocker    | `blocker` | must fix — always routes to the fix loop                |
| Concern    | `high`    | `high` is the lowest value the fix loop triggers on     |
| Suggestion | `low`     | below the gate; leaves `medium` free (see below)        |
| Question   | body — or a `gap` | not a defect; see below                         |
| Praise     | body only | a payload entry is a defect record                      |

**Concern is `high`, not `medium.`** The threshold that matters is `any(severity >=
high)`: `high` and above open a fix round, everything below flows to the reconciled set
untouched. A Concern is "should fix or explicitly justify" — at `medium` it would pass
silently, and the justification this rung demands would have nowhere to happen. `high` is
what gives it a venue.

**Suggestion is `low`, keeping `medium` in reserve.** Both sit below the gate, so routing
does not distinguish them. `low` is the better home because a cluster's severity is a
median over its members, and a security judge on the same change emits on a ladder whose
own threshold is `≥ medium`; parking general-track niceties at `low` keeps them from
pulling a mixed cluster upward. `medium` stays available for a Concern you have
deliberately downgraded but are not willing to drop.

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
