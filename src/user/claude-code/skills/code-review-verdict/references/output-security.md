# Security-track output template (@security-engineer)

`report_lint.py --skill code-review-verdict` validates emissions against this shape: the
exact banner, the nine `###` sections in order, all five severity buckets explicit, the
recommendation allow-list, and the trailing confirmation line.

For changes with no security-relevant surface:

```
LGTM (security) - no security-relevant changes
```

For substantive security-relevant changes:

```
## Review (security — @security-engineer)

### Summary
{1-3 sentence security framing of what changed}

### Scope Reviewed
- Source: {PR # / branch / uncommitted / staged / files}
- Files changed: {N} (security-touched paths called out)
- Tree state: {git rev-parse --short HEAD}[+dirty:<sha12>] — same fingerprint and carry-forward rules as the general template
- Reference docs: {the issue's distilled security contracts, `docs/adr/` security records, docs/spec/security.md sections — or "None applicable"}
- Inherited exclusions: {one entry per inherited exclusion of shape `exclusion — source-tool corpus — this corpus — why still appropriate`, or "None", or "N/A — no detection control in diff"}

### Threat Model (assumed)
- Adversary: {external attacker / curious insider / supply-chain compromise / prompt injection / ...}
- Asset under defense: {credentials / user data / build integrity / runtime isolation / ...}
- Out of scope: {explicit non-threats}

### Risk Assessment
- Blast radius: {what gets compromised}
- Exploit prerequisites: {auth required? remote? local? user interaction?}
- Data sensitivity: {none / low / high / regulated}
- Confidence: {high / medium / low — and why}

### Findings

**Critical** ({count}):
- {file:line} — {finding} — {threat} — {required mitigation}
- ... or "None"

**High** ({count}):
- ... or "None"

**Medium** ({count}):
- ... or "None"

**Low** ({count}):
- ... or "None"

**Info** ({count}):
- ... or "None"

### Required Mitigations
- {numbered list of must-do mitigations before merge — or "None"}

### Dimension Checklist
| Dimension | Status |
|---|---|
| Authn / Authz | pass / concern / fail / N/A |
| Input validation & encoding | pass / concern / fail / N/A |
| Secret handling | pass / concern / fail / N/A |
| Cryptography | pass / concern / fail / N/A |
| Trust boundaries | pass / concern / fail / N/A |
| Supply chain | pass / concern / fail / N/A |
| Sandbox / isolation | pass / concern / fail / N/A |
| Logging / observability | pass / concern / fail / N/A |
| Denial of service | pass / concern / fail / N/A |

### Recommendation
One of: **Approve (security)** / **Approve with follow-up** / **Block (security)** / **Split required**

### Next Steps
{What the calling agent should do — e.g., deliver this verdict to team-lead for step-14 reconciliation (security verdict binds for security findings), surface any security-vs-general track contradiction, escalate to operator if the threat model diverges from the issue's distilled threat contracts, request a vote for residual-risk acceptance. Standalone (no orchestrator): notify the parallel reviewer for unified handoff and route critical/high to @senior-engineer.}

Code review emitted ({recommendation}).
```
