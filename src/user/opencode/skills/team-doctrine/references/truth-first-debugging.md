# Truth-First Debugging — Maintained Master

**LOCAL-copy consumers:** all 6 team agents (`staff-engineer.md`, `security-engineer.md`,
`senior-engineer.md`, `sdet.md`, `project-manager.md`, `ux-designer.md`) plus `team-lead.md`,
each carrying a compact `CANONICAL:TRUTH-FIRST-DEBUGGING-LOCAL` copy (role-tailored).
Relocated from `src/user/opencode/agents/team-lead.md` §Truth-First Debugging (DKT-59/60
doctrine-home migration). Deployed at
`~/.config/opencode/skills/team-doctrine/references/truth-first-debugging.md` — repo:
`src/user/opencode/skills/team-doctrine/references/truth-first-debugging.md`. Read on
demand only — never `skill({ name: "team-doctrine" })`.

---

## Truth-First Debugging

<!-- CANONICAL:TRUTH-FIRST-DEBUGGING:BEGIN -->
**Truth-First Debugging (maintained master).** When diagnosing a failure the job is to find the
TRUTH, not to confirm a hypothesis — a fix is only as trustworthy as the evidence under it. If the
system is HIDING the truth, the FIRST deliverable is to make the truth observable, not to ship a
best-guess fix. Each agent carries a compact `CANONICAL:TRUTH-FIRST-DEBUGGING-LOCAL` copy
(role-tailored) maintained from this block. **Banner:** "If the system is hiding the error, the
first fix is to stop it hiding the error. No root-cause fix ships until the real failure has been
OBSERVED in the real environment."

**Triggers (any one → discipline in force):** error is generic / sanitized / swallowed / opaque
("internal error", catch-all message, stripped stack or cause, one constant string covering many
causes); you cannot see the actual failure from the actual failing system (prod / user env); you
are about to build or "verify" a fix against a REPRODUCTION you constructed from your own
hypothesis; multiple distinct root causes could produce the same observed symptom.

- **TFD-1 — Instrument before you theorize.** If the real cause is hidden, the FIRST change exposes
  it (log the real error class/code/cause, emit a structured diagnostic, widen a sanitizer for
  diagnostics only, add a trace/metric). Ship that, capture the real signal, THEN diagnose.
- **TFD-2 — Reproduction ≠ truth.** Reproducing a symptom proves a cause CAN produce it, never that
  it IS the cause. Verify against the actual failure signal from the actual environment, not a
  self-built reproduction.
- **TFD-3 — State the falsifier first.** Before writing a fix record: (a) the hypothesis, (b) the
  single piece of REAL-WORLD evidence that would confirm it, (c) how you'll obtain it. Can't obtain
  it → instrument until you can. No fix ships without its confirming real-world evidence.
- **TFD-4 — Prefer the discriminating measurement.** When several causes fit, pick the cheapest
  observation that tells them APART, not another confirming one.
- **TFD-5 — Label every claim.** Tag each as OBSERVED (in the failing system) / REPRODUCED (in a
  lab) / INFERRED. Never let REPRODUCED or INFERRED masquerade as OBSERVED; a deterministic 3/3 lab
  pass is still not prod truth.

**Banned moves:** committing to or "verifying" a fix whose root cause was never OBSERVED in the real
failing environment; treating a successful reproduction of a generic symptom as proof of the cause;
escalating confidence ("verified" / "confirmed" / "100%") on lab-only evidence; spending iterations
refining a theory while the real error remains uncaptured and capturable.

**Pre-fix gate (all must pass before any fix is written):** [ ] actual error/cause is OBSERVED in the
real failing environment (not a proxy); [ ] if NOT observed → the current deliverable is the
instrument, not a fix; [ ] hypothesis has a named falsifier and the real-world evidence is
obtainable; [ ] chosen evidence discriminates this cause from the other plausible ones.

**Why faster, not slower:** a wrong best-guess fix burns a full implement→review→deploy cycle and
leaves you no smarter; instrumentation that surfaces the real error converts the NEXT failure into
ground truth — usually cheaper than one wrong fix cycle.
<!-- CANONICAL:TRUTH-FIRST-DEBUGGING:END -->
