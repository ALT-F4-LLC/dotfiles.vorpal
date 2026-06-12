---
name: ux-spec
description: >
  Author a single UX design spec at docs/ux/{slug}.md. Use for web, mobile,
  CLI, TUI, API, SDK, configuration, copy, or developer-facing workflow design.
---

# UX Spec

Produce one UX design spec and stop. Do not commit changes.

## Workflow

1. Confirm users, primary workflow, constraints, success criteria, and non-goals.
2. Read existing `docs/ux/`, related specs, and current implementation patterns.
3. Choose `docs/ux/{slug}.md`.
4. If the target file exists, ask before overwriting or choose a new slug.
5. Specify flows, states, information hierarchy, copy, accessibility, edge
   cases, and implementation handoff notes.
6. Include a Mermaid flow or state diagram for non-trivial workflows.

## Format

```markdown
---
status: "draft"
owner: "@ux-designer"
---

# {Title}

## Goal

## Users and Context

## Workflows

## States

## Content and Copy

## Accessibility

## Error and Empty States

## Handoff Notes

## Acceptance Criteria

## Open Questions
```

## Output

Report the spec path, core UX decisions, implementation priorities, and open
questions.
