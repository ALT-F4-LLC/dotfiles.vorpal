---
fragment: test-infra-discipline
version: 1
---
# Test-infrastructure discipline

When the change builds or modifies test infrastructure — harnesses, fakes, fixtures,
generators, builders, CI gates — that surface is production code: engineers depend on it
the way they depend on the product, and a slow, flaky, or untrustworthy suite taxes
every change that follows.

- **Name the defect class first.** Establish what class of defect the infrastructure is
  meant to catch before building it; a harness with no named defect class is
  scaffolding. The laziness ladder applies here as anywhere: the framework's own
  facility, then an existing helper, then the smallest thing that works — a bespoke
  generator for a case a literal fixture covers is overbuild.
- **Build at the smallest size that catches that class**, and build the harness so its
  users can stay there — infrastructure that forces a network round-trip to test a
  parser has spent the suite's flake budget on everyone's behalf.
- **Design seams for state, not interactions.** A harness whose users must assert *that
  a collaborator was called* has pushed implementation-coupling onto every test
  downstream of it, permanently; supply fakes they can assert real state against. Make
  time, randomness, and I/O injectable rather than ambient — determinism is a property
  built in at this layer, and no test above can retrofit it.
- **Fixtures mirror production shape.** A fixture carrying invented fields, or missing
  fields the real artifact has, produces tests that pass against a world that does not
  exist — compare against a real artifact rather than your memory of one. Fixture
  values are varied and realistic: repeated-character filler is silently suppressed by
  placeholder filters and by the very scanners a fixture is meant to exercise. Never
  read credential files or embed real secrets — a fixture needing a credential is a
  test-environment blocker to surface.
- **Prove it reports red.** A harness never observed to fail is unproven: demonstrate a
  deliberately broken input reaching it and the failure it produces — via a throwaway
  probe (a temp test file you then delete, or a mirror of the tree under your temp
  directory), never by breaking and restoring the checkout itself. For each resilience
  behavior the infrastructure supports — retry, timeout, degradation — it must be able
  to inject the failure it defends against; a fallback path with no failure injection
  is untestable by construction.

Test infrastructure that is quietly non-deterministic is worse than none — it spends
every future engineer's attention on rerunning it.
