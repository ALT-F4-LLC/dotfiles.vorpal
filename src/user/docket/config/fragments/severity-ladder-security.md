---
fragment: severity-ladder-security
version: 3
---
# Severity ladder: security

Severity reflects **supported exploitability and security impact**, including
blast radius, in the intended supported deployment of the reviewed change.
State attacker capabilities, prerequisites, affected assets or tenants, and
effective controls. Fix effort, unrelated code quality, detection method, and
file type do not determine severity. Credit surrounding controls only where
their protection is established.

- **Critical**: a supported attack path permits severe compromise, such as
  broad privileged access, exposure of a high-impact live secret, remote code
  execution with substantial authority, or widespread loss of essential
  availability. The path is feasible under the assessed deployment conditions;
  active exploitation or a working exploit is not required. Fix before merge,
  or revert.
- **High**: a serious vulnerability below Critical, or a demonstrated material
  loss of a required security guarantee. Examples include a privileged path
  left unguarded or a mitigation regressed; use Critical when the resulting
  exploitability and impact warrant it. Fix, or accept the risk explicitly
  through the HUMAN security vote.
- **Medium**: a supported security concern below High because impact is limited
  or evidenced prerequisites substantially constrain exploitation. State those
  limits. Low confidence and the mere availability of a workaround do not
  qualify a finding for Medium.
- **Low**: a concrete defense-in-depth improvement with a stated security
  benefit. Worth doing; never a gate on its own.
- **Info**: a useful educational or incidental stylistic observation without a
  supported security defect or material control loss. Scanner-detectable
  vulnerabilities retain the rung their impact warrants.

This is the security track's authoring vocabulary. Do not borrow general-track
bands or use their criteria to grade security findings. A vulnerability class
or example alone does not establish severity; apply the conditions above.

**Emit-time mapping.** Author with this vocabulary and use the supplied 02 §6
payload contract. Map each rung exactly:

| Author as | Emit as |
| --- | --- |
| Critical | `blocker` |
| High | `high` |
| Medium | `medium` |
| Low | `low` |
| Info | `info` |

**Security convergence.** Critical and High route to the HUMAN security vote.
A supported Critical remains fix-before-merge or revert; a vote may correct or
reject its classification on evidence, but risk acceptance alone does not clear
it. High requires a fix or recorded acceptance by the authorized human decision
maker. Medium remains recorded and surfaces at the gates and in the backlog;
Low and Info remain available for downstream consideration.

No severity starts an automatic fix loop in this track. Retain the supplied
re-review contract's finding identities, evidence, carry-forward, and closure
rules, but use this ladder's terms and human convergence policy. Unresolved
findings remain unresolved when a review ends. Neither an absent `blocker` nor a
completed vote proves readiness: required checks, applicable gates, and
judgment-blocking gaps still apply. A gate override alone is not acceptance of
an independently supported security risk.

**Report low-severity findings; do not omit them.** Preserve all in-scope
findings, including scanner-duplicable vulnerabilities, Low improvements, and
incidental Info observations. Filtering, ranking, and deduplication happen
downstream. Do not invent security impact for a style observation or expand a
security review into a style sweep. A clean result is valid when the examined
evidence supports it. On large changes, concentrate effort on flows that cross
or define trust boundaries and state material coverage limits.

**Evidence and uncertainty.** Every security finding names the threat, affected
property (confidentiality / integrity / availability / non-repudiation), concrete
code or execution evidence, impact, and mitigation. Assess severity separately
from confidence. Preserve uncertain leads with their evidence limits under the
supplied evidence and gap contracts; do not assert an unproven defect, downgrade
it mechanically, or treat unknown reachability as safety. If the output contract
is unavailable, preserve the analysis and identify the gap without inventing
fields or claiming valid payload emission. Info observations need no fabricated
threat. Redact live secrets from report evidence.

**Mitigation must preserve the guarantee.** A proposed workaround does not lower
severity. Credit only controls established to apply in the assessed state, and
explain the residual exposure. Swallowing an exception that masks an auth
bypass, exempting an unsafe host from policy, or disabling a check for a green
build does not resolve the underlying finding. When the proper fix is out of
scope, keep that limitation and the unresolved risk explicit.

**Comments and suppressions use the same ladder.** Establish who can access or
influence the content, what information or protection is affected, and the
resulting risk. A live secret in a comment can be Critical. An internal hostname,
path, exploit explanation, or disabled-control rationale is not automatically
High or Medium; establish the disclosure or control loss and its consequence.

A suppression on or adjacent to security-sensitive code needs a justification:
what check is bypassed and what invariant is enforced in its place. Verify the
directive's actual scope and effect; proximity to credential validation alone
does not establish High. Report missing justification as an evidence gap or a
supported requirement violation, as applicable. A rationale alone does not
prove the replacement invariant; a demonstrated weakening takes the severity
its consequence warrants.
