---
name: tdd
description: >
  Author a single Technical Design Document at docs/tdd/{slug}.md. Use for
  architecture, cross-module behavior, data model changes, APIs, migrations,
  new patterns, or multi-phase technical work. TDD means Technical Design
  Document, not test-driven development.
---

# TDD

Produce one Technical Design Document and stop. Do not commit changes.

## Workflow

1. Confirm the verified goal, constraints, non-goals, and acceptance criteria.
2. Read relevant code, existing `docs/tdd/`, `docs/tdd/adr/`, `docs/spec/`, and
   `docs/ux/`.
3. Decide whether this needs a TDD. Use `$adr` for one durable decision and
   direct implementation for obvious low-risk changes.
4. Choose `docs/tdd/{slug}.md`.
5. If the target file exists, ask before overwriting or choose a new slug.
6. Write a design that an implementer can execute without rediscovering the
   architecture.

## Format

```markdown
---
status: "draft"
owner: "@staff-engineer"
---

# {Title}

## Goal

## Non-Goals

## Current State

## Proposed Design

## Alternatives Considered

## Security Considerations

## UX Considerations

## Implementation Plan

## Acceptance Criteria

## Test Strategy

## Rollout and Rollback

## Open Questions
```

## Quality Bar

- Every load-bearing claim is verified against the repo or marked as an
  assumption.
- Alternatives are real options, not strawmen.
- Acceptance criteria are executable or inspectable.
- Security and UX sections say "not applicable" only when that is true.

## Output

Report the TDD path, selected approach, open questions, and recommended next
role.
