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
