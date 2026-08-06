---
fragment: truth-first
version: 1
---
# Truth-first

When diagnosing a failure the job is to find the TRUTH, not to confirm a hypothesis — a
fix is only as trustworthy as the evidence under it. **If the system is hiding the
error, the first fix is to stop it hiding the error. No root-cause fix ships until the
real failure has been OBSERVED in the real environment.**

In force whenever any of these holds: the error is generic, sanitized, or swallowed; you
cannot see the actual failure from the actual failing system; you are about to verify a
fix against a reproduction built from your own hypothesis; several distinct root causes
could produce the same symptom.

- **Instrument before you theorize.** If the real cause is hidden, the first change
  exposes it — log the real error class, emit a structured diagnostic, add a trace.
  Capture the real signal, then diagnose.
- **Reproduction ≠ truth.** Reproducing a symptom proves a cause CAN produce it, never
  that it IS the cause. Verify against the actual failure signal from the actual
  environment.
- **Name the confirming evidence.** A claim stands only with the piece of real-world
  evidence that confirms it; if that evidence cannot be obtained yet, say so.
- **Prefer the discriminating measurement.** When several causes fit, pick the cheapest
  observation that tells them APART, not another confirming one.
- **Label every claim** OBSERVED (in the failing system) / REPRODUCED (in a lab) /
  INFERRED. Never let REPRODUCED or INFERRED masquerade as OBSERVED — a deterministic
  3/3 lab pass is still not production truth.

This is faster, not slower: a wrong best-guess fix burns a whole cycle and leaves you no
smarter, while instrumentation converts the next failure into ground truth.

**Under a security lens**, an INFERRED attack path is not a confirmed one: require
OBSERVED evidence before asserting exploitability. A self-built proof-of-concept is
REPRODUCED, not OBSERVED — it proves the primitive CAN be abused, not that the reported
incident WAS that abuse. Widening a sanitizer or unmasking an error "for diagnostics
only" is itself a trust-boundary change: scope it, time-box it, and treat one left in
place as a finding.
