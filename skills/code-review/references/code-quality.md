# Code Quality Review

## Core Question
Will future engineers thank us for this code?

## The Maintainability Test

Ask: "Will an engineer joining 6 months from now understand this?"

Quality code is:
- **Readable**: Intent is clear without extensive comments
- **Predictable**: Follows established patterns
- **Testable**: Dependencies are injectable, side effects isolated
- **Deletable**: Easy to remove when no longer needed

## Readability

### Naming
- Names describe what, not how
- Abbreviations only if universally understood
- Consistent terminology across codebase
- Boolean names read naturally (isEnabled, hasAccess)

### Structure
- Functions do one thing
- Early returns reduce nesting
- Related code is grouped together
- Abstraction level is consistent within a function

### Comments
- Explain why, not what
- Document non-obvious constraints
- Keep in sync with code (stale comments mislead)
- TODOs have ownership or ticket references

## Error Handling

### Good Patterns
- Errors include context (what failed, with what inputs)
- Errors are handled at the appropriate level
- Error types distinguish different failure modes
- Expected errors have clear handling paths

### Red Flags
- Errors silently swallowed or ignored
- Generic messages that don't aid debugging
- Crashes for recoverable conditions
- Inconsistent error handling style

## Design Signals

### Positive Signals
- Single responsibility (each component does one thing)
- Dependency injection (collaborators passed in)
- Explicit over implicit (no magic or hidden behavior)
- Composition over inheritance
- Fail-fast on invalid state

### Warning Signs
- God objects (one class doing everything)
- Deep inheritance hierarchies
- Circular dependencies
- Feature envy (methods using other objects' data)
- Primitive obsession (strings/ints for domain concepts)

## Technical Debt

### Debt Being Added
- Copy-pasted code with variations
- Workarounds for upstream issues
- "Temporary" solutions without cleanup plans
- Feature flags that never get removed

### Debt Being Paid
- Acknowledged in PR description
- Refactoring separate from feature changes
- Test coverage before refactoring
- Documentation updated

## Questions to Ask

- "Is there a simpler way to achieve this?"
- "What assumptions does this code make?"
- "How would someone unfamiliar debug a problem here?"
- "What happens when requirements change slightly?"
- "Is this consistent with how we do things elsewhere?"

## What Good Looks Like

- Clear intent without needing comments
- Consistent with codebase conventions
- Easy to test and mock dependencies
- Obvious how to extend or modify
- No surprises for the next reader
