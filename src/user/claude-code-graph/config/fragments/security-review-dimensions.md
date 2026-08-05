---
fragment: security-review-dimensions
version: 1
---
# Security review dimensions

Work these in order, weighted by what the change touches. A dimension you examined and
found clean is reported as examined-clean — not as silence.

1. **Authn/authz** — privileged paths, default-deny. Where a dependency or engine
   pattern-matches privileged identifiers, enumerate wildcard, separator, and bracket
   semantics against the actual identifier shape, and require sequence-level abuse cases
   rather than single-input ones.
2. **Input validation & encoding** — every value crossing a trust boundary, parsed at
   first contact rather than checked in passing.
3. **Secret handling** — storage, transit, logs, lifetime, rotation. For strip/redact
   controls, verify **persist ordering**: a request-view transform can silently skip the
   at-rest path. Check the framework's own source, not just the change under review.
4. **Cryptography** — primitive, mode, key management, randomness, constant-time
   comparison. Verify against current authoritative guidance; never approximate a
   primitive's properties from memory.
5. **Trust boundaries** — where the change moves one, crosses one unparsed, or removes
   one.
6. **Supply chain** — provenance, pinning, transitive surface, CI integrity.
7. **Sandbox/isolation** — whether an enforcement point actually blocks under every mode
   it must survive, and whether it fails closed. A control that degrades to advisory
   under some configuration is not a control; require the mode-surviving floor and
   evidence it holds across all of them.
8. **Logging/observability** — PII and secret leakage, audit completeness.
9. **Denial of service** — unbounded allocations, regex backtracking, retry storms.

**Injection and deserialization surfaces** are examined wherever dimensions 2, 5 and 7
meet: any construction of a query, command, path, template, or object graph from data
that crossed a boundary.

**Blast radius before severity.** Trace the flagged mechanism to the actual execution
path that consumes it before scoring it. A finding on a code path nothing reaches is a
different finding than the same code on a privileged path.

**Fold re-check.** When a simplification removes or narrows a fail-closed control
because some property "makes it redundant", check whether that property is OBSERVED or
merely INFERRED. An inferred premise under a removed control is a fail-OPEN risk, not a
neutral cleanup: resolving the inference is a prerequisite, not a follow-up.

**Regressions count as findings.** An existing mitigation weakened by this change is a
finding in its own right, independent of whether the change introduces anything new.
