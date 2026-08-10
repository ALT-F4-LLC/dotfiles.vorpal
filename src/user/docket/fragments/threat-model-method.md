---
fragment: threat-model-method
version: 1
---
# Threat modeling: the four questions

Establish the frame before analyzing anything: the **adversary** (external attacker,
curious insider, supply-chain compromise, prompt injection), the **asset** at stake
(credentials, user data, build integrity, runtime isolation), and the **acceptable
residual risk**. A perfect analysis against the wrong threat model is a failure.

Then work Shostack's four questions, all four:

1. **What are we working on?** The system as it actually is — modules, interfaces, and
   existing controls read from the source, never remembered. Configuration claims
   (sandbox rules, permission tiers, allowlists) come from the config file itself; a
   documented control and an enforced one are different facts.
2. **What can go wrong?** Per boundary, what an adversary with the stated capabilities
   can do, and what they gain. State out-of-scope threats explicitly — an unstated
   exclusion reads as a missed one.
3. **What are we going to do about it?** Every control names where it is enforced. A
   compensating control is enforced at the same chokepoint as the protection it
   replaces, or it is not compensating.
4. **Did we do a good enough job?** Required, not optional. An analysis that specifies
   controls but never says how their effectiveness gets verified stops one question
   short and is incomplete. Name the verification for each control — the abuse case, the
   negative control that proves a detection actually fires.

Label every claim OBSERVED (traced in the live system) or INFERRED (suspected, with the
cheapest probe that would confirm). A model built on invented adversary capabilities or
an unverified primitive property spreads disinformation that downstream work trusts.
Where a control is modeled on an existing tool, enumerate that tool's skip and exclusion
semantics from its own source and dispose of each as inherited or dropped: the two have
different corpora, not merely different policies, and under a corpus change a
self-exclusion becomes an attacker-controlled opt-out.

Guard the fail-open direction hardest. When a control is narrowed or removed because some
property allegedly makes it redundant, that property must be observed, not inferred —
otherwise the simplification is a fail-open risk wearing neutral clothing.
