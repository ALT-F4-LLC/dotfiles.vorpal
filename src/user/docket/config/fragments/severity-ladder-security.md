---
fragment: severity-ladder-security
version: 1
---
# Severity ladder — security

Severity reflects **exploitability and blast radius**, never effort to fix and never how
good the surrounding code is.

- **Critical** — exploitable now: authentication bypass, secret exposure, remote code
  execution. Fix before merge, or revert.
- **High** — material weakening of posture: a control removed or narrowed, a privileged
  path left unguarded, a mitigation regressed. Fix, or accept the risk explicitly.
- **Medium** — a real concern with a workaround or low likelihood.
- **Low** — defense-in-depth; worth doing, never a gate on its own.
- **Info** — educational, or a finding a standard scanner would also catch.

This vocabulary is the security track's own. Do not map it onto a general-purpose
quality ladder or borrow that ladder's bands — the two have bled into each other before,
and the cost is a real Critical arriving dressed as a style nit.

**Emit-time mapping.** The words above are the authoring language; you reason and write
in them. The `severity` field of the findings payload takes 02 §6's five values, and
every rung maps 1:1 onto one of them:

| Author as | Emit as    |
|-----------|------------|
| Critical  | `blocker`  |
| High      | `high`     |
| Medium    | `medium`   |
| Low       | `low`      |
| Info      | `info`     |

The rungs already carry the payload's semantics: Critical is the fix-before-merge band
and `blocker` is the value that always routes there. High and above route to the HUMAN
security vote, which converges by decision; Medium's "real concern with a workaround"
is recorded and surfaces at the gates and in the backlog — the automatic fix loop is
retired for this track too (operator convergence policy, 2026-08-10), because a loop
keyed on values judges can produce indefinitely never closes, and on the security
track the serious findings were already the vote's to arbitrate.

**Report low-severity findings; do not omit them.** Stylistic observations and
scanner-duplicable findings are still reported, at `Info` — filtering and ranking happen
downstream, never at authoring time. On large changes, focus effort on the fraction that
crosses or defines a trust boundary.

**Calibration.** Do not default to "ship it": unjustified panic is as harmful as
unjustified approval, and a false clean on a trust-boundary change can expose users,
data, or the supply chain. Every critique names the threat, the impact category
(confidentiality / integrity / availability / non-repudiation), and a concrete
mitigation. Surface-level mitigations are reject-class — a swallowed exception masking an
auth bypass, an allowlisted host silencing a policy, a check disabled for a green build.
When the proper fix is out of scope, say so; do not report the symptom as handled.

**Comment content is a security question only when the content creates risk.** A
redundant comment is someone else's style nit. A comment leaking a secret, an internal
hostname or path, an exploit detail, or a disabled-control rationale is High on
security-sensitive code and Medium elsewhere on a security-touched path. A suppression
directive on or adjacent to security-sensitive code needs a stated justification — what
check was bypassed and what invariant is asserted in its place; a bare suppression next
to a credential-validation call is High.
