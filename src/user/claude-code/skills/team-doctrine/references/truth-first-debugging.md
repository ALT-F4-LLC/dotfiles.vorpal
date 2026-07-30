# Truth-First Debugging — Maintained Master

Agents carry compact, role-tailored `CANONICAL:TRUTH-FIRST-DEBUGGING-LOCAL` copies (the
project-manager/ux-designer LOCALs carry principle + banner + one role line only — that
tailoring is deliberate, not drift). Deployed at
`~/.claude/skills/team-doctrine/references/truth-first-debugging.md` — repo:
`src/user/claude-code/skills/team-doctrine/references/truth-first-debugging.md`.

---

## Truth-First Debugging

<!-- CANONICAL:TRUTH-FIRST-DEBUGGING:BEGIN -->
When diagnosing a failure the job is to find the TRUTH, not to confirm a hypothesis — a fix
is only as trustworthy as the evidence under it. **Banner:** "If the system is hiding the
error, the first fix is to stop it hiding the error. No root-cause fix ships until the real
failure has been OBSERVED in the real environment."

**Triggers (any one → discipline in force):** the error is generic/sanitized/swallowed; you
cannot see the actual failure from the actual failing system; you are about to verify a fix
against a reproduction built from your own hypothesis; multiple distinct root causes could
produce the same symptom.

- **TFD-1 — Instrument before you theorize.** If the real cause is hidden, the FIRST change
  exposes it (log the real error class/cause, emit a structured diagnostic, add a
  trace/metric). Ship that, capture the real signal, then diagnose.
- **TFD-2 — Reproduction ≠ truth.** Reproducing a symptom proves a cause CAN produce it,
  never that it IS the cause. Verify against the actual failure signal from the actual
  environment.
- **TFD-3 — Name the confirming evidence.** A fix ships only with the piece of REAL-WORLD
  evidence that confirms its hypothesis; if that evidence cannot be obtained yet, instrument
  until it can.
- **TFD-4 — Prefer the discriminating measurement.** When several causes fit, pick the
  cheapest observation that tells them APART, not another confirming one.
- **TFD-5 — Label every claim** as OBSERVED (in the failing system) / REPRODUCED (in a lab)
  / INFERRED. Never let REPRODUCED or INFERRED masquerade as OBSERVED — a deterministic 3/3
  lab pass is still not prod truth.

Why this is faster, not slower: a wrong best-guess fix burns a full
implement→review→deploy cycle and leaves you no smarter; instrumentation converts the NEXT
failure into ground truth.
<!-- CANONICAL:TRUTH-FIRST-DEBUGGING:END -->
