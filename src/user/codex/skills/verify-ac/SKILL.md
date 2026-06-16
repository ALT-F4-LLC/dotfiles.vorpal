---
name: verify-ac
description: >
  Verify acceptance criteria for a Docket issue, PR, branch, staged changes,
  uncommitted diff, or file set and emit an evidence-based verification report.
  Use for SDET-style verification. Writes no files unless adding tests is
  explicitly in scope.
---

# Verify AC

Verify the requested scope against acceptance criteria. Do not commit changes.

## Workflow

1. Identify the verification scope and source of acceptance criteria.
2. Read Docket issue descriptions and comments when applicable; comments may
   supersede stale issue text.
3. Read linked specs under `docs/spec/`, `docs/tdd/`, and `docs/ux/`.
4. Inspect the implementation diff and tests.
5. Run criteria-derived verification commands. Prefer evidence over assertion.
6. Add focused tests only when the parent task authorizes test edits and the
   repository patterns make the change low risk.
7. Separate product defects, test gaps, and environment blockers.

## Verdicts

- `PASS`
- `ACCEPT WITH CAVEATS`
- `BLOCK`

## Output

```markdown
Verdict: PASS | ACCEPT WITH CAVEATS | BLOCK

Criteria:
- [PASS|FAIL|UNKNOWN] criterion - evidence.

Commands:
- command - outcome.

Tests Added:
- ...

Gaps:
- ...

Recommended Next Step:
- ...
```
