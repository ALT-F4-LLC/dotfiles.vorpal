---
name: design-review
description: >
  Review a UX spec, draft design, or proposed user-facing surface and emit a
  structured UX review report. Use before implementation or when design quality
  needs an independent pass. Writes no files by default.
---

# Design Review

Review the design artifact named by the invocation scope. Do not commit changes.

## Workflow

1. Read the target UX spec, draft, issue, or surface description.
2. Read adjacent `docs/ux/`, `docs/spec/`, and existing implementation patterns.
3. Evaluate the design across workflow fit, information architecture, state
   coverage, consistency, accessibility, copy, and implementation handoff.
4. Separate blocking usability or correctness issues from polish.
5. Prefer concrete alternative copy, layout, command, or state behavior over
   broad advice.

## Recommendation

- `APPROVE`
- `APPROVE WITH CHANGES`
- `REVISE`
- `BLOCK`

## Output

```markdown
Recommendation: APPROVE | APPROVE WITH CHANGES | REVISE | BLOCK

Findings:
- [severity] location - issue, user impact, and recommended change.

Strengths:
- ...

Open Questions:
- ...

Implementation Handoff Notes:
- ...
```
