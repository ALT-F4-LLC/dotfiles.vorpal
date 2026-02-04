# Testing Review

## Core Question
Are we testing the right things in the right way?

## Testing Philosophy

Good tests answer: "Does the code do what it should?"
Not: "Does the code do what it does?"

### The Testing Pyramid
- **Unit tests**: Fast, isolated, cover logic branches
- **Integration tests**: Verify component interactions
- **End-to-end tests**: Validate critical user journeys

More tests at the bottom (unit), fewer at top (E2E).

## What to Test

### Must Have Tests
- Business logic and calculations
- Error handling paths
- Edge cases and boundary conditions
- Security-sensitive operations
- Data transformations and validations

### Can Skip Tests
- Trivial accessors with no logic
- Framework boilerplate
- Code already covered by higher-level tests

## Test Quality Signals

### Good Tests
- Test behavior, not implementation details
- Clear setup, action, assertion structure
- One logical concept per test
- Test names describe scenario and expectation
- Independent (no shared mutable state between tests)

### Problematic Tests
- Coupled to implementation (break when refactoring)
- Flaky (pass/fail randomly)
- Slow (discourage running frequently)
- Interdependent (one failure cascades)
- Over-mocked (not testing real behavior)

## Coverage vs Confidence

Coverage percentage is a vanity metric. Focus on:
- Are critical paths tested?
- Are failure modes tested?
- Are edge cases tested?
- Are assumptions documented in tests?

80% coverage with right tests > 100% coverage with wrong tests.

## Red Flags

### Missing Tests For
- New public interfaces
- Bug fixes (regression tests)
- Error handling branches
- Concurrent or async behavior

### Test Smells
- Time-based synchronization (sleep/wait)
- Tests that only work in specific environments
- Tests requiring manual setup
- Assertions commented out or weakened
- Tests inspecting private state

## Test Design Principles

### Boundaries and Mocking
- Mock at system boundaries (network, storage, external services)
- Don't mock what you own (test the real thing)
- Verify behavior and outcomes, not call sequences
- Consider fakes over mocks for complex dependencies

### Test Data
- Use realistic but minimal test data
- Avoid shared fixtures that create coupling
- Make test data intent clear (why these values?)
- Consider property-based testing for edge cases

## Questions to Ask

- "What would break if this test didn't exist?"
- "Can this test fail for the wrong reason?"
- "Does this test the contract or the implementation?"
- "How much confidence does this test provide?"
- "Will this test be maintainable as the code evolves?"

## What Good Looks Like

- Tests serve as documentation of expected behavior
- Fast feedback loop (most tests run in seconds)
- Failures point clearly to what's broken
- Tests enable refactoring with confidence
- Test maintenance burden is proportional to value
