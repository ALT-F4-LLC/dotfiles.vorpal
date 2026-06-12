---
name: prd
description: >
  Author a single Product Requirements Document at docs/spec/{slug}.md. Use for
  product-defined features, unclear scope boundaries, stakeholder requirements,
  or when requirements must be captured before technical design.
---

# PRD

Produce one Product Requirements Document and stop. Do not commit changes.

## Workflow

1. Confirm the product goal, target users, non-goals, constraints, and success
   metrics.
2. Refuse the reserved project spec names used by `$init-specs`.
3. Read related `docs/spec/`, `docs/ux/`, `docs/tdd/`, Docket issues, and
   existing product surfaces.
4. Choose `docs/spec/{slug}.md`.
5. If the target file exists, ask before overwriting or choose a new slug.
6. Write requirements without prescribing implementation details unless they are
   explicit constraints.

## Format

```markdown
---
status: "draft"
owner: "@project-manager"
---

# {Feature Name} PRD

## Goal

## Non-Goals

## Users and Use Cases

## Requirements

## Acceptance Criteria

## UX and Content Notes

## Security and Privacy

## Rollout and Measurement

## Open Questions
```

## Output

Report the PRD path, core requirements, open questions, and recommended next
role.
