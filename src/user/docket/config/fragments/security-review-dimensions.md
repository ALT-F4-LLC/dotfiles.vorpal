---
fragment: security-review-dimensions
version: 5
---
# Security review dimensions

Use this order as a checklist. Weight depth by the change's security impact and
follow affected flows across dimensions. Establish the reviewed state, affected
entry points, attacker capabilities, and required security properties first,
including affected callers, dependencies, and configuration beyond the diff.

For each dimension, report findings and coverage. **examined-clean** means no
finding within the cited paths, modes, and checks. Mark material gaps or relevant
exclusions **unverified**. Use **not-applicable** only for irrelevant dimensions,
with a reason. A finding does not erase remaining gaps: silence or an incomplete
check is not a clean result.

1. **Authn/authz**: identity and session validity, default-deny, object and tenant
   access, privileged operations. Check enforcement at the protected operation.
   Where an engine pattern-matches privileged identifiers, verify its actual
   version, options, normalization, wildcard, separator, and bracket semantics
   against real identifier shapes. Include allowed and denied cases, plus abuse
   sequences that create, change, reuse, or revoke relevant state. Isolated inputs
   do not establish sequence safety.
2. **Input validation & encoding**: identify the guarantees each boundary value
   needs and establish them at ingress before dependent use. Check syntax, meaning,
   size, and canonicalization as applicable. Credit enforced upstream guarantees
   while they remain valid; opaque data need not be interpreted without a reason.
   Use parameterization or context-specific encoding at the consuming operation.
   Successful parsing alone does not prevent injection.
3. **Secret handling**: storage, transit, logs, lifetime, rotation, revocation.
   For strip/redact controls, trace transformation and **persistence ordering**
   through every affected write path, including queues and error paths. A
   request-view transform may leave stored values untouched. Inspect the relevant
   framework source for the version in use, not just the diff; unavailable source
   leaves source-dependent claims unverified.
4. **Cryptography**: primitive, mode, authentication, key management, randomness,
   nonce requirements, and timing-sensitive comparisons. Verify applicable
   properties and usage against current authoritative guidance and documentation
   for the implementation in use. Cite them rather than relying on memory.
5. **Trust boundaries**: identify who controls data and authority at each crossing,
   including stored data and external responses. Check new, moved, or removed
   boundaries and unintended delegation, network access, or data disclosure. Check
   security invariants across state transitions, replay, and concurrent operations,
   including changes between authorization and use.
6. **Supply chain**: provenance, resolved versions and integrity, pinning,
   applicable advisories, transitive exposure, and CI/build credentials and code
   execution. Establish security impact; a dependency change alone is not a finding.
7. **Sandbox/isolation**: name the guarantee and the modes/configurations in which
   it must hold. Verify the enforcing layer, bypass and fallback paths, errors,
   and mode transitions. Identify the minimum enforcement that remains effective
   throughout that scope. An advisory check cannot satisfy a required blocking
   guarantee; unexamined required modes remain unverified.
8. **Logging/observability**: sensitive-data leakage, audit coverage and integrity
   for required security events, and access to logs. Verify what is emitted on
   success and failure paths.
9. **Denial of service**: attacker-triggerable CPU, memory, storage, connection,
   or cost growth; regex backtracking, amplification, and retry storms. Check
   effective limits and cancellation at the resource-consuming operation.
10. **Injection and deserialization**: trace untrusted data into queries,
    commands, paths, templates, interpreters, or object graphs, including after
    storage or transformation. Examine these surfaces wherever present; sandbox
    involvement is not a prerequisite. For AI-enabled paths, include lower-trust
    content influencing instructions, tool authority, or data disclosure.

**Execution path and impact before severity.** Trace each candidate from an
attacker-controlled entry or state to the consuming operation and violated
security property. State preconditions, effective mitigations, and affected
assets or tenants, and cite a concrete code trace or applicable execution
evidence. Unknown reachability is unverified, not evidence of unreachability.
Assign severity from supported impact and preconditions, separately from
confidence.

**Control-removal re-check.** When simplification removes or narrows a fail-closed
control as redundant, establish that the replacement premise holds throughout the
required states and modes and preserves the guarantee. An observed example or an
unsupported inference is insufficient. An unresolved premise blocks an
examined-clean result for that control; resolve it before accepting the removal.
Report a demonstrated bypass as a finding and an unproven premise as a
verification gap, preserving any independently established regression.

**Regressions count as findings.** Compare effective protection before and after
the change. A mitigation weakened in a way that reduces required protection is a
finding even when the underlying hazard predates the change. Attribute issues
introduced, exposed, or worsened by the change; identify unrelated pre-existing
issues separately. Do not require a novel exploit or inflate severity merely
because the issue is a regression.
