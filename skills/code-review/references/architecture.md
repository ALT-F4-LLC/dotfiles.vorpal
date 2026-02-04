# Architecture Review

## Core Question
Does this change fit the system's design, or is it fighting against it?

## System Impact Analysis

Before reviewing the code itself, ask:
1. **Boundary changes**: Does this modify contracts between components?
2. **Dependency direction**: Are we creating cycles or inappropriate coupling?
3. **Responsibility shifts**: Is a component taking on work outside its domain?
4. **Pattern consistency**: Does this follow established patterns or introduce new ones?

## Red Flags

### Architectural Drift
- New pattern introduced without deprecating the old one
- Abstractions that leak implementation details
- Components taking responsibilities outside their domain
- Shared mutable state crossing boundaries

### Coupling Problems
- Components that can't be tested in isolation
- Changes that require coordinated updates across many files
- Circular dependencies between modules
- "Utility" modules that become dumping grounds

### Scalability Concerns
- Synchronous operations where async would be appropriate
- Missing pagination on unbounded data
- No backpressure mechanisms for producers/consumers
- Assumptions about single-instance deployment

### Abstraction Issues
- Wrong level of abstraction (too high or too low)
- Premature abstraction (generalizing from one case)
- Missing abstraction (copy-paste with variations)
- Leaky abstraction (callers need to know internals)

## Questions to Ask

- "What happens if this component is unavailable?"
- "How would we split this later if it grows?"
- "What's the migration path if requirements change?"
- "What implicit assumptions does this design make?"
- "Who else is affected by this change?"

## What Good Looks Like

- Changes that work with the existing architecture, not against it
- Clear boundaries with explicit contracts
- Dependencies that flow in one direction
- Components that can evolve independently
- Decisions documented with rationale
