# sdet recurring pitfalls

- Changelog "NO-OP — already encoded in <skill>" claims fail OPEN → a prior evolve cycle (2026-06-05) recorded the literal-command-AC rule as already present in skills/verify-ac/SKILL.md; grep on 2026-06-09 refuted it, so the focus area was silently skipped for a full cycle → root cause: NO-OP verdicts were accepted from changelog prose without re-grepping the claimed target → resolution: treat every "already encoded elsewhere" claim as a signal-to-verify; grep the named file for the rule before recording NO-OP, and cite the grep in the changelog.
