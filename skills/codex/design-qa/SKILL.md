---
name: design-qa
description: >
  Verify an implemented user-facing surface against a docs/ux/ specification and
  emit a structured design QA report. Use after implementation, not for spec
  review. Writes no files unless the parent task explicitly requests notes.
---

# Design QA

Verify implementation against design intent. Do not commit changes.

## Workflow

1. Identify the UX spec, implementation scope, and primary workflows.
2. Read the relevant `docs/ux/` spec and any linked `docs/spec/` or `docs/tdd/`
   material.
3. Inspect the implemented UI, CLI, TUI, API, SDK, config, copy, and error
   states as applicable.
4. Verify flows, states, accessibility, consistency, empty/error/loading
   handling, copy, and visual or command hierarchy.
5. Use screenshots or runtime checks when available and worthwhile; otherwise
   cite file and command evidence.

## Verdicts

- `PASS`
- `PASS WITH CAVEATS`
- `BLOCK`

## Output

```markdown
Verdict: PASS | PASS WITH CAVEATS | BLOCK

Spec:
Implementation Scope:

Findings:
- [severity] file:line - mismatch, user impact, and recommended fix.

Evidence:
- ...

Not Verified:
- ...
```
