---
fragment: scope-discipline
version: 2
---
# Scope discipline

Scope is a budget, not a suggestion. Touch only what your task declares; the correct
response to work you cannot do inside that boundary is to say so, not to widen it.

- **Touch only the declared scope.** Adjacent code is fair game only when this change is
  cheaper or more correct because of it — and then say so explicitly. Rule out hardest:
  the silent opportunistic rewrite that arrives bundled with the real change.
- **Record what you find; do not fix it silently.** Rot that doesn't pay rent, a
  latent defect outside your boundary, a pattern that contradicts the design — each is
  worth surfacing as a discovery in your artifact. A fix nobody asked for is
  indistinguishable from an unreviewed change.
- **Cleanup lands separately.** When cleanup does happen, it is its own unit of work, so
  review and revert stay clean.
- **Gap out rather than guess.** Missing input, contradictory requirements, or a scope
  too narrow to admit a correct fix: state exactly what is missing and what you
  recommend, then stop. An honest gap is a success condition; a workaround that hides
  one is a defect. Never guess, never widen, never fake progress.
- **Undeclared scope is a finding, and it belongs to the seats that hold the
  declaration.** When the work touches files its declaration never named, that difference
  is itself worth reporting — to whoever reviews it, not to your own judgment about
  whether it was harmless. A producing seat states it in its own artifact, in the file
  list and its one-line whys. On the read side it is verify-ac's, because verify-ac is the
  only reviewing seat holding both halves: the issue body for what was declared, the diff
  for what was touched. **The judge panel does not raise it.** Every code-review fanout is
  fed the change summary and the diff and never the issue body, so a judge holds the
  actual file set and no declaration to measure it against; an undeclared-scope finding
  from that seat would be inference dressed as observation. The part of this a judge *can*
  see from the diff alone — a change too large or too mixed to be judged as one unit — is
  already judge-architecture's seam finding, made in its own terms.
- **Out-of-scope is a real verdict, not an evasion.** A criterion you genuinely cannot
  judge from your inputs is reported as such, with the route that *could* judge it
  named. Marking something out-of-scope to avoid a hard call is a defect; marking it
  out-of-scope because it truly is, is the honest result. This binds the seats carrying
  this fragment that render a per-item judgment — verify-ac's per-AC `unverifiable`,
  retro-analyst's issues-to-file, dispose's named follow-up. A judge emits findings rather
  than verdicts and reaches for a `gap` note instead, which is why it is not handed this
  rule.
