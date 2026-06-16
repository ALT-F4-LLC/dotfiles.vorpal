---
name: code-review-verdict
description: >
  Produce a structured code review verdict for a scoped artifact such as a PR,
  branch, staged changes, uncommitted diff, or file set. Use for staff-engineer
  general review or security-engineer security review. Writes no files.
---

# Code Review Verdict

Review the requested scope and emit a findings-first report. Do not edit files
and do not commit changes.

## Scope

Accept a PR number or URL, branch name, `staged`, `uncommitted`, or explicit
file paths. If the scope is unclear, ask for the exact artifact.

## Workflow

1. Identify the diff or files under review.
2. Read relevant specs and design docs under `docs/spec/`, `docs/tdd/`,
   `docs/tdd/adr/`, and `docs/ux/`.
3. Inspect the implementation and tests. Use commands only when they materially
   improve confidence.
4. For general review, check correctness, maintainability, architecture fit,
   tests, observability, performance, and docs/spec drift.
5. For security review, check trust boundaries, authn/authz, secret handling,
   crypto, sandbox/permissions, dependency risk, logging, and abuse paths.
6. Do not raise speculative issues without a reachable failure mode.

## Verdicts

- `APPROVE`
- `ACCEPT WITH CAVEATS`
- `BLOCK`

## Output

```markdown
Verdict: APPROVE | ACCEPT WITH CAVEATS | BLOCK

Findings:
- [severity] file:line - issue, impact, and concrete fix.

Evidence:
- Commands run or files inspected.

Tests:
- Run:
- Not run:

Residual Risk:
- ...
```

Lead with findings. If there are no findings, say so plainly and note any test
gaps.
