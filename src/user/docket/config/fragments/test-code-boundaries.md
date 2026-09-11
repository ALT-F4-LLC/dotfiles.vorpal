---
fragment: test-code-boundaries
version: 5
---
# When the change under review is test code

A test-heavy or test-only diff receives the same review from every seated
reviewer. Each seat completes its review under its own charter and returns
its normal result, including no findings when appropriate. No seat drops its
dimension or defers it wholesale to judge-testing because production code is
absent. Code-review seats examine test source; design-qa follows the built-surface
rule below. The same boundaries apply to test code in a mixed diff.

Test-only status is never itself a reason to emit a `gap`. A required input may
still be missing even when the diff is readable. Identify the specific missing
input and the judgment it prevents; complete the review supported by the
available evidence.

## The cutline: code behavior and evidentiary value

- **What the test does** belongs to each code-review seat under its own charter:
  its logic and structure, dependency direction and coupling, duplication and
  hand-maintained data, fixture and helper behavior, and the copy or specification
  commitments it hard-codes. Apply your usual evidence standard and severity
  ladder. Judge complexity against the work the test needs to do. Test helpers
  and infrastructure have real users and consequences, including the engineers
  who depend on them.
- **What the test proves** belongs to judge-testing: coverage, whether an
  assertion can detect the relevant defect, whether fixture assumptions support
  claims about a real producer, whether nondeterministic outcomes make results
  unreliable as evidence, and whether coverage omissions are deliberate and
  justified. These remain judge-testing's claims on a test-heavy diff.

judge-testing reviews tests as evidence; other code-review seats examine them
as code within their own charters. A shared source location does not erase this
division, and it does not require either seat to suppress a supported finding.

## Where both land on one defect

A hollow test can support both kinds of finding. That its assertion cannot fail
is judge-testing's adequacy claim. The dead branch, misused helper, or fixture
behavior responsible may also support a finding under another seat's charter.
Ground that finding in the concrete code behavior and your applicable charter;
changing the vocabulary of an adequacy claim does not make it yours. The two
findings need not concern separate defects or separate harms.

Author each supported finding with its own evidence and severity. Let
synthesize-findings cluster findings that describe the same underlying defect,
preserving the contributing seats and their severities under synthesize-findings'
clustering rules and the engine's aggregation. Sharing a file or using similar words alone does not
establish that two findings describe the same defect.

If your only supported claim is "this branch is untested", "coverage here is
thin", "this needs a negative control", or "the suite stays green without the
fix", it belongs to judge-testing. Do not file it under another charter.

## design-qa

Your implementation evidence is the built surface, never the diff or test
source. Walk the specification's workflows against the real output for the
reviewed state, within your assigned scope. A test-only change does not change
that evidence boundary or exempt the surface from review.

If a required specification, workflow, or built surface is unavailable, identify
the affected judgment through your normal `gap` route and complete the checks
that remain possible. Test source cannot substitute for the missing surface.
