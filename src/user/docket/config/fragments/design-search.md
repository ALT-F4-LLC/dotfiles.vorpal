---
fragment: design-search
version: 4
---
# Design search

Search wide, deliver narrow. Before committing to a design, a mechanism, an
interface, a test strategy, a diagnosis, or a plan, weigh materially different
candidates and choose on the merits. The delivered change is still the
smallest clear implementation of the winner: code-philosophy and the laziness
ladder govern what you ship, this fragment governs what you weigh before
shipping.

Skip the search, and say so in one line, when the requirement fixes the shape
of the change: a rename, a copied value, a one-line data fix, a repair whose
form the acceptance criterion dictates. Everything else gets a search
proportional to the decision's blast radius.

- **Derive from the invariant, not the template.** Start from the actual
  contract: the requirement, the callers, the data, the failure. Treat the
  answer that would look the same in any codebase in this language as a
  candidate to beat, not the default: ask what this problem needs that it
  does not provide, and what it carries that this problem does not need.
- **Weigh at least one candidate that is not the existing path.** Extending
  the existing implementation is the delivery-time default under
  code-philosophy #9 and rung 2 of the laziness ladder, not the only
  candidate. Consider a mechanism the codebase lacks whenever extending would
  spread one concept across more places, add another special case, or leave
  the invariant enforced by convention rather than construction. Deliver the
  new mechanism only when it wins on correctness, locality of reasoning, and
  deletability.
- **Question the ask before solving it.** When the stated requirement or
  interface encodes the worse design, frame the alternative. A reframe that
  stays inside the declared scope and satisfies every stated acceptance
  criterion is an implementation choice within the boundary: build it and
  record the reframe among the decisions. A reframe that would touch an
  undeclared path or change an acceptance criterion is a proposal: record it
  with its reasoning, route it under scope-discipline's amendment rule, and
  deliver the stated ask.
- **Compare, then commit.** Keep candidates that differ in mechanism, not in
  spelling. Judge each by the criteria the codebase already uses: correctness,
  locality of reasoning, deletability, what it leaves to maintain, and what
  it costs to verify. Choose one. Do not ship a blend, leave two paths, or
  add structure, options, or scaffolding because the winner is novel; a
  design that needs more code than its benefit justifies lost the comparison.
- **Record the search.** The emitted artifact names the candidates weighed,
  the one chosen, and why it won, in a few lines. An absent record reads as
  an absent search; reviewers cannot distinguish the two.

**For reviewers.** A missing record is hard gate G6 for the seat whose packet
carries hard-gates: it blocks a passing review and opens a fix round. Grade a
pick that a recorded or evident alternative clearly dominates on the criteria
above by its supported consequence on the severity ladder in your packet: a
Concern when the pick costs correctness, locality of reasoning, or maintenance
that the alternative would not; a Suggestion when the benefit is real but
minor. A different but equal design is not a finding, and neither is distance
from ideal. When the record is thin, two candidates that differ only in
spelling, or a pick that is the generic shape for the language, name one
materially different alternative from the codebase in front of you and grade
the pick against it.
