# Security Review

## Core Question
What could go wrong if inputs are malicious or if an attacker is watching?

## Threat Modeling (Quick Pass)

For every change, consider:
- **Spoofing**: Can someone impersonate another user or system?
- **Tampering**: Can data be modified without detection?
- **Repudiation**: Can actions be denied without audit trail?
- **Information Disclosure**: Can sensitive data leak?
- **Denial of Service**: Can this be abused to degrade the system?
- **Elevation of Privilege**: Can users access things they shouldn't?

## Red Flags

### Authentication & Authorization
- Missing permission checks on new functionality
- Authorization logic that can be bypassed
- Credentials or secrets in code or configuration
- Session handling vulnerabilities
- Overly broad access grants

### Input Handling
- Untrusted input used without validation
- String concatenation for queries or commands
- User-controlled data in sensitive operations
- Missing or incorrect encoding/escaping
- Deserialization of untrusted data

### Data Protection
- Sensitive data in logs or error messages
- PII exposed in URLs or client-side storage
- Missing encryption for data at rest or in transit
- Secrets that can't be rotated
- Insufficient audit logging

### Trust Boundaries
- External input trusted without verification
- Internal services assumed to be safe
- Client-side validation without server-side checks
- Third-party integrations with excessive access

## Questions to Ask

- "Who can reach this code path and with what permissions?"
- "What's the worst case if this input is malicious?"
- "Where does this data end up? Who can see it?"
- "What's the blast radius if this credential leaks?"
- "How would we detect if this was being abused?"

## What Good Looks Like

- Defense in depth (multiple layers of protection)
- Principle of least privilege
- Fail-safe defaults (deny by default)
- Input validation at trust boundaries
- Sensitive operations logged for audit
- Secrets managed separately from code
