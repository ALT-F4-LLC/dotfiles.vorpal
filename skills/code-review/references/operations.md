# Operations Review

## Core Question
How does this behave in production, especially when things go wrong?

## The 3am Test

Before approving, ask: "If this breaks at 3am, can the on-call engineer diagnose and fix it?"

Requirements for yes:
- Clear error messages that point to the problem
- Visibility into what's happening (metrics, logs, traces)
- Documented or obvious rollback path
- No hidden dependencies that fail silently

## Observability Checklist

### Can We See What's Happening?
- Are new code paths instrumented?
- Do logs include enough context to debug?
- Are errors distinguishable from normal operation?
- Can we trace requests through the system?

### Can We Measure Success?
- Are success/failure states clearly defined?
- Do we have metrics for the new functionality?
- Can we detect degradation before total failure?
- Are SLOs defined for critical paths?

### Can We Alert Appropriately?
- Do new failure modes have corresponding alerts?
- Are alerts actionable (not just "something is wrong")?
- Will we know about problems before users report them?

## Failure Mode Analysis

### What Could Fail?
- Network operations (timeout, connection refused, partial failure)
- Data operations (corruption, inconsistency, exhaustion)
- External dependencies (unavailable, degraded, rate limited)
- Resource limits (memory, storage, connections, quotas)

### How Does It Fail?
- Graceful degradation vs hard failure
- Retry behavior (bounded? backoff?)
- Timeout configuration (too short causes flapping, too long causes cascading)
- Error propagation (does one failure cascade?)

## Deployment Safety

### Can We Roll Back?
- Are changes reversible?
- Can old versions read new data formats?
- Is there a migration plan for breaking changes?
- How long until we can detect problems?

### Can We Roll Out Safely?
- Can changes be deployed incrementally?
- Will health checks catch problems?
- Can traffic be shifted gradually?
- What's the blast radius during deployment?

## Questions to Ask

- "How will we know this is broken in production?"
- "What's the rollback plan?"
- "How long until we detect a problem? How long to mitigate?"
- "What happens to in-flight requests during deployment?"
- "What dependencies could cause this to fail?"

## What Good Looks Like

- Clear operational boundaries and failure domains
- Graceful degradation under partial failure
- Comprehensive observability for new code paths
- Documented runbooks for likely failure scenarios
- Safe deployment with rollback capability
