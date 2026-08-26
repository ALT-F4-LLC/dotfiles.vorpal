---
fragment: test-code-boundaries
version: 2
---
# When the change under review is test code

A diff that is predominantly or entirely test code is a whole change under
review, not one seat's change. Every seat the fanout seats reviews it under its
own charter. No seat falls silent, defers its whole dimension to judge-testing,
or emits a `gap` on the grounds that the diff contains no production code: a
diff you can read is not a missing input, and gapping out of a test-heavy round
deletes a lens from the record while claiming nothing was examinable.

## The cutline: as code it is yours, as evidence it is judge-testing's

- **What the test does** (its own logic, its structure, the direction of what
  it imports and couples to, what it duplicates or hand-maintains, whether it is
  more machinery than the case needs, the posture of its fixtures and helpers,
  the copy and spec commitments it hard-codes) is ordinary code under your own
  lens. Review it exactly as you review production code, ground the finding in
  your own charter's terms, and hold your usual severity ladder. Test
  infrastructure in particular is production code for the engineers who depend
  on it.
- **What the test proves** (coverage, whether a green assertion could ever have
  gone red, whether a fixture shape proves anything about a real producer, flake
  risk, gaps conscious versus simply absent) is judge-testing's charter, and it
  stays judge-testing's on a test-heavy diff exactly as on a production one. It
  is the one dimension a test-heavy fanout does not duplicate.

judge-testing states its own half of this line: it judges tests *as evidence,
not as artifacts*. This is the other half. They are complements, not a contested
border, and neither seat's silence is what keeps them apart.

## Where both land on one defect

A hollow test is often both: that the assertion cannot fail is judge-testing's
adequacy finding, while the dead branch, the misused helper, or the fixture that
made it hollow may be squarely yours. Author yours in your own vocabulary on
your own evidence and let synthesize-findings cluster them: two judges
describing one defect in different words is one cluster carrying both
severities, and that convergence is licensed rather than a boundary breach.

The breach is reaching for the adequacy claim itself when your charter disclaims
it: "this branch is untested", "coverage here is thin", "this needs a negative
control", "the suite stays green without the fix". If the only statement you can
make about a test is about what it fails to prove, it is judge-testing's finding
and you do not file it.

## design-qa

Your evidence is the built surface and never the diff, so a test-only change
does not change your job: walk the specification's workflows against the real
output as always. "The diff is only tests" is never your reason to gap, and the
test source is not yours to read.
