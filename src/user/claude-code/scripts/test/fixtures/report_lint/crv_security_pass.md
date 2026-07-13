## Review (security — @security-engineer)

### Summary
Reviews a new token-verification helper.

### Scope Reviewed
- Source: uncommitted
- Files changed: 1 (auth.go)
- Reference docs: docs/spec/security.md §Secrets

### Threat Model (assumed)
- Adversary: external attacker
- Asset under defense: session credentials
- Out of scope: physical access

### Risk Assessment
- Blast radius: auth path
- Exploit prerequisites: remote, unauthenticated
- Data sensitivity: high
- Confidence: high — traced every call site

### Findings

**Critical** (0):
- None

**High** (1):
- auth.go:12 — timing-unsafe token compare — attacker recovers token — use hmac.Equal

**Medium** (0):
- None

**Low** (0):
- None

**Info** (0):
- None

### Required Mitigations
- Replace the byte compare at auth.go:12 with a constant-time compare.

### Dimension Checklist
| Dimension | Status |
|---|---|
| Authn / Authz | concern |
| Input validation & encoding | pass |
| Secret handling | pass |
| Cryptography | fail |
| Trust boundaries | pass |
| Supply chain | pass |
| Sandbox / isolation | N/A |
| Logging / observability | pass |
| Denial of service | pass |

### Recommendation
**Block (security)** — the timing-unsafe compare is exploitable and must be fixed.

### Next Steps
Deliver to team-lead; security verdict binds for the crypto finding.

Code review emitted (Block (security)).
