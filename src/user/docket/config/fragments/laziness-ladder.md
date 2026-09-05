---
fragment: laziness-ladder
version: 3
---
# Laziness ladder

Lazy means efficient, not incomplete. Deliver the requested behavior with the
least code and machinery to maintain. Correctness and readability come first.

Stop at the first rung that satisfies the actual requirements. Keep the search
proportional to the task:

1. **Does this need to exist now?** Skip speculative additions. Complete what
   was requested; do not re-argue its necessity.
2. **Can the existing code do it?** Read the affected implementation and relevant
   callers. Prefer editing or reusing that path over adding a parallel one.
3. **Does the standard library do it?** Use it when it meets the requirements.
4. **Does a native platform feature cover it?** Prefer a built-in input type,
   stylesheet, or database constraint when it provides the required behavior.
5. **Does an installed dependency solve it?** Use its supported interface
   directly where practical. Add a dependency only when it removes meaningful
   implementation or maintenance burden; do not hand-roll security primitives
   to save lines.
6. **Only then:** write the smallest clear local implementation. Add structure
   only when the requested behavior requires it or would otherwise be difficult
   to understand; keep it within the affected code. Do not compress readable
   code to meet a line count.

No scaffolding for later, speculative configuration, or wrappers that merely
rename an existing operation. Fix the responsible code instead of accumulating
special cases around it. Comment a deliberate limitation only when its
consequences are non-obvious; name the ceiling and upgrade path.

**Finish by subtracting.** Inspect the complete task diff. Remove unnecessary
additions, duplicated behavior, and temporary scaffolding created for the task.
Delete code the change makes obsolete after checking supported callers and
contracts. Keep cleanup within scope. The additions-to-deletions ratio is a
review signal, never a quota.

**Preserve the contract.** Keep required boundary validation, data-loss
protection, security, accessibility, and explicitly requested behavior. Rely on
established guarantees instead of duplicating enforcement. Where hardware
behavior depends on drift or measurement error, preserve necessary tolerances
and calibration; add controls only for an actual requirement.

**Lazy code without its check is unfinished.** Run the smallest relevant
existing checks. Extend coverage when meaningful changed behavior or risk is
otherwise untested, using the existing harness where available. Money and
security paths need verification regardless of line count. Check observable
behavior, not implementation shape. Rerun affected checks after simplification;
report anything that could not be verified.
