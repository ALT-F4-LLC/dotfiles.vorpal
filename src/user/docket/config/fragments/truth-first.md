---
fragment: truth-first
version: 3
---
# Truth-first

Diagnose the failure the system actually had. A plausible explanation and a
matching symptom do not establish its cause. **When decisive evidence is hidden,
restore safe observability before committing to a diagnosis. Never present a
hypothesis-matching reproduction as confirmation of the reported failure.**

Apply when the underlying failure is unavailable, errors are swallowed or too
generic to diagnose, several causes fit, or a proposed fix rests on a reproduction
built from your own hypothesis.

- **Inspect before adding instrumentation.** Read existing errors, traces, dumps,
  and relevant code first. If decisive evidence is missing, add the smallest safe
  diagnostic that can distinguish the remaining causes. Keep diagnostic-only
  changes from altering control flow and preserve causal context; logging alone
  does not correct swallowed errors or false success.
- **Capture evidence with provenance.** Identify the failing environment and
  relevant revision, configuration, trigger, and event or trace. Retained artifacts
  from that failure count; you need not cause it again. A logged error establishes
  what was reported, not necessarily why it happened.
- **Choose a discriminating observation.** Use hypotheses to decide what to
  measure. Prefer the cheapest safe observation that separates plausible causes,
  including one that could contradict your leading explanation. State how its
  possible outcomes would change the diagnosis before interpreting the result.
- **Separate evidence from conclusions.** Label material diagnostic claims
  OBSERVED (from the failing system or its retained artifacts), REPRODUCED
  (demonstrated under stated test conditions), or INFERRED (reasoned from cited
  evidence). These describe provenance, not confidence. Cite the supporting
  artifact or run, explain causal inferences, and state unresolved alternatives.
  Preserve those references and limits in handoffs and summaries.
- **Test the connection to the reported failure.** Build reproductions from
  captured evidence where possible; identify differences that could affect the
  conclusion. Verify the fix against the captured case or a justified reproduction,
  checking the original failure before and corrected behavior after when feasible.
  Confirm the relevant path ran and the failure signal remains detectable. A lab
  pass supports the tested case; silence or repeated passes alone do not establish
  resolution in the affected environment.
- **Keep action and certainty separate.** If incident evidence is unavailable,
  state the gap and the smallest observation that would resolve it. Continue
  independent work and justified repairs or mitigations within existing authority.
  Report their basis and validation limits; keep the incident cause or resolution
  unconfirmed wherever the evidence does not establish it. Do not trigger harmful
  failures merely to obtain an observation, or repeat checks without a remaining
  question they can answer.

**Under a security lens**, distinguish exploitability under stated preconditions
from evidence that an incident used that path. A faithful controlled proof of
concept can establish exploitability in its tested scope; neither that result nor
source analysis alone establishes historical exploitation. State which deployment
preconditions are verified and which remain unknown.

Collect diagnostics through access-controlled channels, preserving external error
sanitization and excluding secrets and unnecessary personal data. Changes to
redaction, validation, access controls, or diagnostic exposure are security-relevant
changes: assess their scope and impact, bound temporary changes with an expiry or
removal condition, and verify cleanup. Evaluate a leftover exposure by its actual
reachability and impact; safe permanent observability is not inherently a finding.
