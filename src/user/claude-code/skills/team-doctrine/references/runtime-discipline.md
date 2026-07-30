# Runtime Discipline (R1-R7) — Maintained Master

Source of truth for the R-rule bodies. Agent files carry a one-line reminder per applicable
rule plus a pointer here; team-lead additionally carries compact LOCAL bodies for R1/R3/R4/R6.
Deployed at `~/.claude/skills/team-doctrine/references/runtime-discipline.md` — repo:
`src/user/claude-code/skills/team-doctrine/references/runtime-discipline.md`.

## Runtime Discipline (R1-R7)

Per-agent applicability (tl=team-lead, st=staff, de=distinguished, se=security, pm=pm,
ux=ux, sd=sdet, sr=senior; ▾ = grouped pointer only, — = omit):

| Rule | tl | st | de | se | pm | ux | sd | sr |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
| **R1 Tool-Use Parsimony** | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **R2 Skill Invocation Restraint** | ▾ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **R3 SendMessage Terseness** | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **R4 Iteration Scope** | ✓ | ✓ | ✓ | ✓ | — | ✓ | ✓ | ✓ |
| **R5 Advisor Continuity** | ▾ | ✓ | ✓ | ✓ | — | ✓ | — | — |
| **R6 Doctrine-Pinned Script Trust** | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **R7 Read-Cache Awareness** | ▾ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

### R1 — Tool-Use Parsimony

Tool-call results land in context verbatim — filter before the result lands (`grep -l` over
`grep -rn` for enumeration, ranged `Read`, `jq`/`grep`-piped Bash), and batch independent
calls in one turn. A bulk read that IS the load-bearing evidence (full file for review, full
diff for verification) is correct — the rule bans speculative bulk reads. Tool-contract
facts that recur as errors:

- `Read` `offset`/`limit` are each a SINGLE integer (`{"offset": 218, "limit": 12}`), and
  `Read` takes a file path, never a directory — enumerate with `Glob` or `ls` first.
- cwd PERSISTS across Bash calls, and `docket` resolves its DB from cwd — never leave the
  repo root; scope directory-local commands with a subshell `(cd <dir> && ...)`. On
  `no docket database found`, `pwd` and cd back — do NOT re-`docket init`.
- `Monitor`'s `timeout_ms` has a hard floor of 1000ms (default 300000, max 3600000) — a call
  below the floor is rejected outright, not clamped.

### R2 — Skill Invocation Restraint

Every `Skill(name)` call loads the entire SKILL.md into context — invoke only on a real
trigger match or an explicit operator/team-lead directive, never "to learn the format";
orchestrators, planners, and persistent advisors leave skill bodies to the
artifact-producing agent. Never guess a skill name — invoke only a name that appears
verbatim in the current available-skills listing; a guess fails closed or silently loads the
wrong body. Scope boundary: R2 restrains `Skill()` calls only, never a skill-prescribed Bash
validation step — "I know this skill's format" never licenses skipping a prescribed gate
like `report_stage_lint.sh` on an emission.

### R3 — SendMessage Terseness

Payloads accumulate in BOTH endpoints' contexts: one message per purpose, no quoting-back,
`TaskUpdate` for state transitions instead of narrative status. Schema fact: `summary` is
REQUIRED whenever `message` is a plain STRING (harness-rejected otherwise; long
status/vote-result messages are where it gets forgotten — risk rises with length);
object-form `message` needs no `summary` — see shutdown-protocol.md SP-1b. High-stakes
events (re-plan triggers, scope deltas, blocker escalations) earn a longer message;
terseness bounds redundant state, never load-bearing context.

### R4 — Iteration Scope

Re-verify a completed criterion only when specific evidence of regression points at it, and
only that criterion. Verification scope beyond the acceptance criteria is @sdet's call, not
unilaterally yours.

### R5 — Advisor Continuity (persistent advisors only)

Before dropping any transient state, write memory first (pitfalls home per pitfalls.md) —
within-session drops are irreversible; never drop a cross-cycle canonical decision-record,
and when unsure whether content is load-bearing, keep it and surface to team-lead. When
continuity can no longer be maintained, SendMessage team-lead to respawn with a continuity
preamble.

### R6 — Doctrine-Pinned Script Trust

Any script path cited by its exact path in your own role's doctrine text (this master, your
agent file, or a skill you're following) is pinned — version-controlled at a fixed location
(repo `src/user/claude-code/scripts/`, deployed `~/.claude/scripts/`). Invoke it directly;
never `ls`/`test -e`/`--help` it first — a failed invocation reports the same fact in one
call. This does NOT extend to the Read-before-Edit gate or to file-existence checks at other
trust boundaries (e.g. confirming an issue's attached paths resolve before citing them) —
those stand unchanged. Re-read a file only on actual cause (edited since last Read,
operator-flagged divergence, explicit reviewer concern); once the owning authority confirms
state, stop re-reading lagging readers to re-confirm it.

### R7 — Read-Cache Awareness

Files Read this session are already in context — re-Read only when the file changed (a peer
says "I just edited X") or after compaction, where one Read per file re-satisfies the
Read-before-Edit gate.
