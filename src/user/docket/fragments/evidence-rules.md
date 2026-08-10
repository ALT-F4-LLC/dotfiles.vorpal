---
fragment: evidence-rules
version: 1
---
# Evidence rules

Every load-bearing claim cites what was actually run, read, or observed: the exact
command, the `file:line`, the real output. Evidence-free framings — "clearly",
"obviously", "should work", "definitely" — are defects, not emphasis. A justified
negative result is worth more than an unexamined positive one.

## Signals that lie toward "it's fine"

- **Sandbox signatures before attribution.** Before blaming a failure on the code under
  review, check the failure text for environment signatures (permission denials, bind or
  socket errors). Only a run free of them is citable as a real failure.
- **Stale cached results.** A bare re-run can report a cached pass from someone else's
  run. Bypass the cache before citing a green run as evidence this code passes.
- **Empty-diff triage.** An empty diff on files whose content demonstrably changed means
  staged or committed, not "no changes" — check the staged and committed views before
  concluding anything from emptiness.
- **Hollow green.** A green build proves a criterion only if the tests actually RAN.
  Verify that any artifact a ruling depends on is really present and not excluded, and
  treat skip-gated suites as hollow-green hazards.

## Signals that lie toward "it's broken"

- **A self-built probe tests your phrasing, not the condition.** Read the actual target
  region before trusting a probe's zero-hit result. Never reuse a location anchor across
  an edit: a stale anchor fails toward a confident, wrong answer rather than an error.
- **Pair every negative probe with a positive control.** "The detector missed my planted
  input" and "my fixture was inert" are the same observation until a known-positive case
  proves the probe fires at all. Use realistic fixture values — repeating-character
  placeholders are silently filtered by many detectors and produce a clean-looking false
  negative.
- **A "found it" result needs MORE scrutiny than a "found nothing" result.** False
  negatives are self-limiting: silence invites a second look. A false positive reads as
  diligence and passes unchallenged. Trace root cause BEFORE writing the finding —
  hardest exactly when the finding confirms what you expected.
- **Severity cap with no control.** A probe-sourced finding with no positive control
  fired in the same pass is not dropped, but it is reported one band lower than its
  uncapped severity, with the reason stated in the finding itself. A later pass whose
  control fires restores full severity; one whose control comes back negative downgrades
  or withdraws the finding.
- **Inherited exclusions are not authored ones.** Where a control's coverage depends on
  another tool's skip semantics, enumerate those semantics from that tool's own source;
  literal text searches are evidence for an enumerated skip, never the search space
  itself. A pre-existing occurrence proves the exclusion is inherited, and the operative
  distinction is different *corpora*, not merely different policies.

## Anti-fabrication

Write each finding only from the complete, freshly rendered content of the thing it is
about — never from memory of what this kind of change usually does, and never from an
empty or errored result. An empty result means UNVERIFIED, not unchanged: re-read before
asserting anything about it. Prefer reading the real content over a pattern match for
anything load-bearing. An evidence-anchored line that is actually fabricated is worse
than an honest "did not verify."
