---
fragment: threat-model-method
version: 3
---
# Threat modeling: the four questions

Establish the frame: the **system and change in scope**, the **adversary's initial
access and capabilities**, the **assets and security properties** at stake, and the
**acceptable residual risk** and who accepts it. Identify which inputs the adversary
controls. Treat prompt injection and supply-chain compromise as attack mechanisms,
not substitutes for specifying capabilities. If risk tolerance is unspecified, record
it as unresolved and continue the analysis without inventing acceptance.

Work all four questions:

1. **What are we working on?** Model components, data flows, dependencies, trust
   boundaries, and existing controls from the current artifacts. Record the revision
   and environment examined. Trace security configuration through relevant defaults,
   overrides, and merge rules to its enforcement point. Distinguish documented intent,
   implementation, effective configuration, and demonstrated runtime behavior. Model
   proposed changes explicitly as proposals.

2. **What can go wrong?** For each relevant boundary, describe plausible attack paths:
   prerequisites, attacker-controlled inputs, the security property violated, and the
   resulting impact. Include paths that cross several boundaries. Prioritize by impact
   and feasibility, stating uncertainty. Record relevant exclusions and their reasons;
   missing evidence is not a reason to declare a threat out of scope.

3. **What are we going to do about it?** Give each material threat a response and
   identify remaining risk. Every control names its enforcement point, prerequisites,
   and bypass paths; distinguish existing controls from proposed ones. A compensating
   control must provide comparable protection against the threats addressed by the
   control it replaces. Explain coverage and gaps, including when enforcement moves
   to another boundary.

4. **Did we do a good enough job?** Review the model's coverage, assumptions, threat
   responses, and residual risk. For each control, specify an abuse case and expected
   blocking or detection, plus a benign case that should remain allowed. Where
   practical, verify in an isolated test setup that deliberately breaking the control
   makes its verification fail. Record expected and actual results, with checks marked
   passed, failed, or not run. A verification plan is not a verification result.
   Identify unresolved work and any pending risk-acceptance decision.

Label material factual claims **OBSERVED**, **INFERRED**, or **UNKNOWN**. For observations,
cite the artifact or runtime result and its scope; observing source code does not
establish deployment or runtime enforcement. For inferences, state the supporting
evidence and reasoning. For material uncertainties, name the smallest practical check
that could confirm or refute them. State threat-model assumptions separately.

When adapting a control from another tool, compare the original and target input sets.
Inspect the relevant version's skip and exclusion semantics in its source where
available; mark unavailable internals as unknown. Explicitly retain, change, or remove
each relevant exclusion. Test whether attacker-controlled content, paths, or metadata
can trigger retained exclusions and evade the intended protection.

Scrutinize changes that allow previously blocked behavior. Before narrowing or removing
a control as redundant, establish why the remaining protection covers the relevant
attack paths and operating conditions, using implementation evidence and appropriate
bypass and failure tests. A passing test supports only the conditions it exercises.
If the redundancy claim remains unverified, retain the control and report the unresolved
dependency.
