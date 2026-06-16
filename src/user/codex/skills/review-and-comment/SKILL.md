---
name: review-and-comment
description: >
  Review a GitHub pull request, draft concise inline review comments in the
  operator's voice, and post only comments the operator explicitly approves. Use
  for "review this PR and comment" requests. Does not modify code.
---

# Review And Comment

Review a pull request and prepare inline comments. Post nothing until each
comment is approved by the user.

## Input

Accept a PR number, PR URL, or `OWNER/REPO#NUMBER`. If only a number is given,
resolve the repository from the current checkout.

## Workflow

1. Identify the PR and authenticated GitHub account.
2. Fetch PR metadata, files, and diff.
3. Review through general correctness and security lenses.
4. Produce one candidate comment per finding. Keep comments specific, concise,
   and actionable.
5. Ask the user to approve, edit, or drop each candidate comment.
6. Post only approved comments.

## Candidate Comment Format

```text
file:line
severity:
comment:
reason:
```

## Guardrails

- Do not post summary comments unless requested.
- Do not modify the PR branch.
- Do not approve your own candidates silently.
- If the requested GitHub operation requires network or credentials outside the
  sandbox, ask for approval through the normal command approval flow.

## Output

Report comments posted, comments skipped, and any findings not posted.
