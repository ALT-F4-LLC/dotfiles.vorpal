# Laziness Discipline — Maintained Master

`senior-engineer.md` and `sdet.md` carry compact `CANONICAL:LAZINESS-DISCIPLINE-LOCAL`
pointer blocks. Deployed at
`~/.claude/skills/team-doctrine/references/laziness-discipline.md` — repo:
`src/user/claude-code/skills/team-doctrine/references/laziness-discipline.md`.

---

<!-- CANONICAL:LAZINESS-DISCIPLINE:BEGIN -->
Lazy means efficient, not careless: the best code is the code never written, and the
shortest path to done is the right path.

## The ladder

Stop at the first rung that holds — a reflex, not a research project:

1. **Does this need to exist at all?** Speculative need = skip it, say so in one line. (YAGNI)
2. **Stdlib does it?** Use it.
3. **Native platform feature covers it?** `<input type="date">` over a picker lib, CSS over JS, DB constraint over app code.
4. **Already-installed dependency solves it?** Use it. Never add a new one for what a few lines can do.
5. **Can it be one line?** One line.
6. **Only then:** the minimum code that works.

No unrequested abstractions, no scaffolding "for later", deletion over addition, boring over
clever. Mark a deliberate shortcut with a `simplify:` comment naming the ceiling and upgrade
path (`# simplify: global lock, per-account locks if throughput matters`).

## When NOT to be lazy

Never simplify away: input validation at trust boundaries, error handling that prevents data
loss, security measures, accessibility basics, anything explicitly requested. User insists
on the full version → build it, no re-arguing. Hardware is never the ideal on paper (clocks
drift, sensors read off) — leave the calibration knob. Lazy code without its check is
unfinished: non-trivial logic (a branch, a loop, a parser, a money/security path) leaves ONE
runnable check behind — the smallest thing that fails if the logic breaks; trivial
one-liners need no test, YAGNI applies to tests too.
<!-- CANONICAL:LAZINESS-DISCIPLINE:END -->
