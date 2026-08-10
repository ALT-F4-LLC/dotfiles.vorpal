---
fragment: tdd-discipline
version: 1
---
# Test discipline

A test must fail *only* when behavior breaks — never when implementation changes while
behavior is preserved. Implementation-asserting tests have the failure mode inverted:
they break on every refactor (noise) and stay green when behavior is actually wrong (no
signal).

- **Red first.** A test never observed to fail proves nothing. Write the test for an
  acceptance criterion before the code that satisfies it, and observe it fail for the
  right reason. An AC whose test passes *before* the change is evidence the criterion is
  mis-stated, not evidence of success — surface it rather than proceeding.
- **Pin behavior at the seam.** Test through the unit's public interface; unit-test an
  internal only when it is a gnarly nameable concept on its own, and even then through
  the smallest stable interface.
- **Assert outcomes, never interactions.** Return value, emitted event, persisted state.
  Asserting that a function *was called* asserts *how*, and breaks on every
  behavior-preserving refactor.
- **Mock only true external boundaries** — network, clock, filesystem, third-party APIs,
  entropy. Mocking an internal collaborator IS asserting implementation; prefer fakes
  (in-memory implementations) over mocks (assertions on calls).
- **Read tests as specifications.** Name each test for the behavior it pins: one
  behavior per test, one failure per reason.
- **Arrange only what the behavior depends on** — builders with sensible defaults;
  arrange only the fields the assertion touches.
- **Fixtures that must defeat a scanner are assembled at runtime.** A literal
  credential-shaped string in a test file trips the secret gate on the test's
  own diff; build it (`printf 'AKIA%s' '…'`) so no committed line matches the
  pattern, and the positive control still fires at run time.
- **Never weaken a test to make it pass.** Loosening an assertion, widening a tolerance,
  deleting a case, or marking it skipped converts a real failure into a false green. If
  a test is wrong, fix the test deliberately and say why; if the code is wrong, fix the
  code.

**Size and risk.** Justify every new test at the smallest size that can catch its defect
class — small (single-process, no I/O), medium (single-machine, local I/O), large
(multi-process, network). Large tests are the slowness and flake budget. Allocate effort
by risk: security boundaries, data transformations, public API contracts and
serialization get thorough tests; error handling, config parsing and integration points
get key paths; trivial accessors get little or none. The question is "if this line is
wrong, will we know before users do?" For each claimed resilience behavior (retry,
timeout, degrade, circuit-break), at least one test must INJECT the failure it defends
against — a fallback with no failure-injection test is unverified.

Rule out hardest: **coverage as a goal** — it measures which lines executed, not whether
anything was asserted; a diagnostic, never a target. **Snapshot tests no human
verified** — a blind-updated snapshot bakes the bug in. **Over-mocking** — four mocks
asserting collaborator calls and one outcome check pins implementation; the tell is that
it would fail under a behavior-preserving refactor.
