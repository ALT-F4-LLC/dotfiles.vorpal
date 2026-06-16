---
name: adr
description: >
  Author a single Architecture Decision Record at docs/tdd/adr/{NNNN}-{slug}.md.
  Use when Codex needs to record a durable architectural decision, compare options,
  or preserve why a choice was made without creating a full technical design doc.
---

# ADR

Produce one Architecture Decision Record and stop. Do not commit changes.

## Input

Use the invocation topic as the decision subject. If the topic is missing, ask
for a concise decision title before writing.

## Workflow

1. Read existing ADRs in `docs/tdd/adr/` to determine the next four-digit
   number and avoid duplicate decisions.
2. Read related `docs/tdd/`, `docs/spec/`, `docs/ux/`, and code references.
3. Confirm the decision is narrow enough for an ADR. Use `$tdd` instead for
   multi-phase technical designs.
4. Choose `docs/tdd/adr/{NNNN}-{slug}.md`.
5. If the target file exists, ask before overwriting or choose a new slug.
6. Write the ADR with frontmatter and sections below.

## Format

```markdown
---
status: "proposed"
date: "YYYY-MM-DD"
deciders: []
consulted: []
informed: []
---

# {Decision Title}

## Context

## Decision

## Consequences

## Options Considered

### Option 1: {name}

- Pros:
- Cons:

## Acceptance Criteria

## References
```

## Output

Report the ADR path, selected decision, status, and any open questions.
