---
fragment: laziness-ladder
version: 1
---
# Laziness ladder

Lazy means efficient, not careless: the best code is the code never written, and the
shortest path to done is the right path.

Stop at the first rung that holds — a reflex, not a research project:

1. **Does this need to exist at all?** A speculative need is skipped, and the skip is
   stated in one line.
2. **Does the standard library do it?** Use it.
3. **Does a native platform feature cover it?** A built-in input type over a picker
   library, a stylesheet over script, a database constraint over application code.
4. **Does an already-installed dependency solve it?** Use it. Never add a new dependency
   for what a few lines can do.
5. **Can it be one line?** One line.
6. **Only then:** the minimum code that works.

No unrequested abstractions, no scaffolding "for later", deletion over addition, boring
over clever. Mark a deliberate shortcut with a comment naming its ceiling and the upgrade
path — "global lock; per-account locks if throughput matters" — so the next reader knows
it was a choice rather than an oversight.

**When not to be lazy.** Never simplify away input validation at a trust boundary, error
handling that prevents data loss, a security measure, accessibility basics, or anything
explicitly requested. When the full version is what was asked for, build it and do not
re-argue the point. Hardware is never the ideal on paper — clocks drift, sensors read
off — so leave the calibration knob in.

**Lazy code without its check is unfinished.** Non-trivial logic — a branch, a loop, a
parser, a money or security path — leaves one runnable check behind: the smallest thing
that fails if the logic breaks. Trivial one-liners need no test; the ladder applies to
tests too.
