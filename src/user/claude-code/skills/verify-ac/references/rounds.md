# Round-2+ re-verification and multi-issue isolation

Read when this is a re-verification of a previously-verdicted issue, or the 2nd+
`Skill(verify-ac)` invocation in one session.

## Prior-verdict carry-forward (Pre-flight §3a)

Before scoring criteria on a Round-2+ pass, scan `docket issue comment list {id}` for prior
verification reports. Read `<prior fingerprint>` from the prior report's **Tree state**
field; compute `<current fingerprint>` as `git rev-parse --short HEAD` plus `+dirty:<sha12>`
from `~/.claude/scripts/tree_fingerprint.sh` when the tree is dirty. For each criterion
previously marked PASS, run:

```
~/.claude/scripts/verify_carry_forward.sh <prior fingerprint> <current fingerprint> <evidence path>
```

(repo: `src/user/claude-code/scripts/verify_carry_forward.sh`) with that criterion's
evidence file/test path — it mechanizes the fingerprint comparison (rev-range
`git diff --name-only` for the commit component; hash-equality for the `+dirty` component).

- `[CARRY-FORWARD]` — the criterion's evidence is untouched since the prior round: cite
  `PASS — unchanged since round {N}: {prior evidence}` instead of re-running the command.
- `[RE-VERIFY]` — the evidence path was touched (or the dirty hash changed without
  per-file localization): re-run that criterion's evidence command fresh.

Re-run the full test suite end-to-end regardless; never carry forward a FAILed criterion
or an Additional Testing gap.

## Cross-issue contamination guard (Pre-flight §6a)

When a prior issue's verification in this session produced persistent artifacts (database
rows, generated files outside the diff, env-var mutations, cached fixtures) that could
affect the current issue's tests, reset the relevant state (drop test DB, `rm` generated
artifacts, unset env vars) BEFORE running the current issue's tests and cite the reset
commands in evidence. If reset is impractical (shared infra), surface a Test Coverage
finding: `Cross-issue contamination risk: prior verification of {prior_issue} mutated
{artifact}; current verification not isolated`.
