---
fragment: test-infra-discipline
version: 5
---
# Test-infrastructure discipline

When building or modifying test infrastructure—harnesses, fakes, fixtures,
generators, builders, or CI gates—treat its reliability and maintenance as
production concerns. Engineers depend on it for every change that follows;
scale its design to the behavior and users it actually supports.

- **Name the purpose first.** Identify the defect class the infrastructure helps
  detect or the test-reliability problem it solves. Apply the laziness ladder:
  reuse existing code and framework facilities before building new machinery.
  A bespoke generator for a case a literal fixture covers is overbuild.
- **Use the smallest size that faithfully catches that class.** Let consumers
  stay at that size: testing a parser should not require a network round-trip.
  Keep real collaborators when they are fast, deterministic, and practical.
  Size definitions and budgets follow the test-discipline fragment.
- **Expose outcomes and contractual effects.** Supply simple, faithful fakes
  when doubles are needed, exposing the effects the test fragment says tests
  assert; do not force tests to pin incidental wiring.
  Check consequential fake behavior against the real contract through existing
  contract or integration coverage, adding focused checks where needed. Make
  unsupported fake behavior fail explicitly rather than silently succeed.
- **Build in isolation and replay.** Make relevant time, randomness, and I/O
  controllable at stable boundaries. Preserve generated inputs or seeds and
  configuration needed to reproduce failures. Isolate mutable state and owned
  resources across tests and workers; clean up even after failure. An
  injectable clock does not prevent interference from a shared cache.
- **Fixtures match the contract under test.** Ground consequential shape
  assumptions in a schema, producer contract, or safe reference artifact.
  Representative valid fixtures preserve the fields and relationships relevant
  to that boundary; minimal, missing-field, and malformed fixtures are valid
  when those conditions are intentional. Make the intended deviation explicit.
  Never read credential files or embed real secrets. Use synthetic values;
  report unavailable authorized test-environment access as a verification gap.
- **Secret-scanner fixtures must exercise the detector.** Construct synthetic positive
  controls at runtime, keeping credential-shaped literals out of committed
  source. Satisfy the detector's actual format, context, and entropy requirements;
  repeated-character filler may be filtered out. Use the scanner mode and
  effective configuration under test, assert the expected finding, and keep the
  committed source within its gate without suppressing the positive control.
- **Prove detection through the real entry point.** For new or changed detection
  behavior, demonstrate a valid control passing and a known defect being rejected
  through the entry point users or CI invoke. Reuse applicable evidence. Confirm
  the intended check ran, failed for the expected reason, and propagated the
  required result to its caller. Unrelated setup or discovery failures, and a
  nonzero exit alone, do not establish detection. Run code-mutating probes only
  in a private copy containing the intended candidate changes; never plant and
  undo a scratch mutation in the shared checkout. Preserve the probe and result
  as evidence before removing disposable files. A throwaway probe does not
  replace warranted regression coverage.
- **A failure hook must be exercised.** Provide the injection point for each
  claimed retry, timeout, or degradation behavior; the test fragment governs
  asserting the behavior it enables. An available but unused failure hook
  leaves the behavior unverified.

Keep failures reproducible and diagnostic: a flaky suite spends every future
engineer's attention on rerunning it.
