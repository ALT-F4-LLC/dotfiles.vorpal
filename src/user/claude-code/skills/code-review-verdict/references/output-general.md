# General-track output template (@staff-engineer / @distinguished-engineer)

`report_lint.py --skill code-review-verdict` validates emissions against this shape: the
exact banner, the eight `###` sections in order, all six severity buckets explicit, the
recommendation allow-list, and the trailing confirmation line.

For trivial / no-op changes:

```
LGTM - {one line summary}
```

For substantive changes:

```
## Review (general — @staff-engineer)

### Summary
{1-3 sentence description of what changed and why}

### Scope Reviewed
- Source: {PR # / branch / uncommitted / staged / files}
- Files changed: {N} ({git diff --stat one-line summary})
- Tree state: {git rev-parse --short HEAD}[+dirty:<sha12> — `~/.claude/scripts/tree_fingerprint.sh` output (repo: `src/user/claude-code/scripts/tree_fingerprint.sh`) — for uncommitted/staged] — the tree this verdict binds to; a Round-N re-review feeds this recorded fingerprint to `verify_carry_forward.sh` to decide carry-forward.
- Reference docs: {TDDs, specs consulted — or "None applicable"}

### Risk Assessment
- Blast radius: {scope of impact if this regresses}
- Rollback complexity: {trivial / moderate / hard}
- Confidence: {high / medium / low — and why}

### Findings

**Blockers** ({count}):
- {file:line} — {finding} — {recommended fix}
- ... or "None"

**Concerns** ({count}):
- ... or "None"

**Suggestions** ({count}):
- ... or "None"

**Questions** ({count}):
- ... or "None"

**Praise**:
- ... or "None"

**Overrides Recognized** ({count}):
- {file:line} — gate G{1..5} — `OVERRIDE: code-philosophy/{id} — {reason}` (operator decides whether the reason holds)
- ... or "None"

### Hard Gates Triggered
List any of G1..G5 that produced a Blocker in this review (after override recognition). If no gates fired, write "None".

- **G1 (swallowed error):** {file:line — symptom — required mitigation} or "None"
- **G2 (unguarded shared mutation):** {file:line — symptom — required mitigation} or "None"
- **G3 (unparsed boundary input):** {file:line — symptom — required mitigation} or "None"
- **G4 (surface-not-invariant patch):** {file:line — symptom — required mitigation} or "None"
- **G5 (unexecuted AC regex):** {file:line — regex — expected hit count vs actual hit count — required mitigation} or "None"

### Dimension Checklist
| Dimension | Status |
|---|---|
| Architecture | pass / concern / fail / N/A |
| Security (general) | pass / concern / fail / N/A |
| Operations | pass / concern / fail / N/A |
| Performance | pass / concern / fail / N/A |
| Code Quality (12 principles) | pass / concern / fail / N/A |
| Testing | pass / concern / fail / N/A |

### Recommendation
One of: **Approve** / **Approve with follow-up** / **Request changes** / **Block** / **Split required**

### Next Steps
{What the calling agent should do — e.g., route blockers to @senior-engineer, request a vote for a 500+ line change, escalate to operator for re-plan}

Code review emitted ({recommendation}).
```
