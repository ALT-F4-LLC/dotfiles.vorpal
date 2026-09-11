---
fragment: tdd-discipline
version: 4
---
# Test discipline

Pin the intended behavior through stable interfaces. Tests should detect contract
violations and survive changes to incidental implementation details. A test that
only confirms internal wiring can miss an incorrect result.

- **Red first for changed behavior.** Write or extend a test for the acceptance
  criterion before implementing it; observe failure caused by the missing or
  incorrect behavior. Unrelated setup, discovery, or environment failures do not
  count. A missing new API can be an initial red; do not describe it as an
  executed behavior assertion. If the test already passes, investigate whether
  the behavior already exists, the scenario misses the
  defect, or the criterion needs correction; report what you establish before
  making a dependent change. Characterization tests and tests guarding a pure
  refactor may start green; do not manufacture a failure in correct code.
- **Complete the loop.** Implement the behavior, observe the test pass, then
  refactor with relevant tests green. Run required checks before claiming
  completion. Follow the evidence rules for commands, evaluated state, discovery,
  skips, cached results, and blocked checks; report verification gaps explicitly.
- **Pin behavior at the seam.** Test through the unit's public interface. Test
  an internal concept separately when it has a coherent responsibility and
  meaningful contract, using its smallest stable interface. Do not expose
  private details solely to assert them.
- **Assert outcomes and contractual effects.** Check returned values, errors,
  emitted events, persisted state, and forbidden effects. Assert a call's
  arguments, count, order, or absence only when those properties are part of the
  contract, such as no payment request after authorization fails. Do not pin
  incidental helper calls.
- **Keep doubles at meaningful boundaries.** Prefer real collaborators. Replace
  I/O, time, entropy, or other slow, unavailable, or nondeterministic dependencies
  at stable interfaces; explain unusual internal substitutions. Prefer simple,
  faithful fakes over scripted call expectations. Use existing contract or
  integration coverage to check material assumptions in fakes; add focused
  coverage when those assumptions are unverified and consequential. A fake
  alone cannot establish the real dependency's behavior.
- **Read tests as specifications.** Name each test for one behavior; multiple
  assertions may establish that behavior. Derive expected results from the
  contract or an independent oracle, never the same production path being tested.
  A failure should make the violated expectation clear.
- **Arrange the scenario.** Use builders with sensible defaults. Make inputs,
  state, and prerequisites that determine the behavior explicit; omit unrelated
  setup. Relevant inputs need not appear in the assertion.
- **Control nondeterminism.** Control time and randomness when relevant; isolate
  mutable state and clean up owned resources. Use deterministic synchronization
  or bounded condition waits instead of arbitrary sleeps. Tests must not depend
  on execution order or another test's leftovers.
- **Build scanner fixtures at runtime, never from committed literals.** The
  test-infrastructure fragment's scanner rule governs their construction;
  never use real credentials.
- **Never change expectations merely to obtain green.** Do not loosen assertions,
  widen tolerances, delete cases, skip failures, or change runner exclusions to
  hide a defect. Correct an invalid or obsolete test from the intended contract,
  explain why, and preserve relevant coverage. If the code is wrong, fix it.

**Size and risk.** Give each new test a defect class to catch; reuse or extend
existing tests when they already provide the right seam. Choose the smallest
size that faithfully exercises it. Follow repository size definitions; otherwise
use small (single-process, no filesystem or network I/O), medium (one machine,
including local I/O, subprocesses, or localhost services), and large (remote
services or distributed execution). Budget large tests by the integration risks
smaller tests cannot cover. Allocate effort by failure consequences: security
boundaries, data transformations, public contracts, and serialization warrant
thorough checks; trivial accessors usually do not.

For each claimed resilience behavior—retry, timeout, degradation, circuit
breaking—inject the failure it handles, confirm that path was exercised, and
assert the promised outcome and applicable limits. Test exhaustion, recovery,
and forbidden side effects when those are claimed. A fallback tested only on
the happy path remains unverified.

Rule out hardest: **coverage padding**—execution coverage is a diagnostic, not
proof of assertion quality; **snapshots without human-reviewed expectations**—a
blind update can preserve a bug; **over-mocking**—a test that breaks when
incidental wiring changes pins implementation rather than the intended contract.
