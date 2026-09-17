# Queue ownership

The one statement of which open issues a backlog-reading skill may treat as
free, how to read the whole backlog, and what to do when the question tool is
missing. `docket-plan`, `docket-groom`, and `tend` point here instead of
restating it; a change to a rule lands here once.

## Not free to take or edit

- **Run-included.** For each run `docket run status --json` returns
  (planning, active, or paused: anything not done or abandoned),
  `docket issue list --run <ref> --json=v2 --limit 1000` names that run's
  roster. An open issue on any of those rosters belongs to a docket-plan/
  docket-run session, even while parked. Skip it; groom may still add
  comments and labels that leave workflow eligibility unchanged, and routes
  every other edit through its approval step.
- **Claimed.** Any issue with a non-empty `assignee` already belongs to
  someone or something else. Skip it. tend never sets `assignee` on the
  issues it works, so a populated field is always someone else.
- **Routed elsewhere.** The routing label decides the consumer:
  `route-run` is docket-plan's, `route-tend` is tend's, `route-direct` is the
  operator's own session through brief, `route-loop` is a scheduled loop's.
  An issue carrying another skill's label, or none, is not yours: docket-plan
  counts unrouted issues and points at groom; tend skips them silently.

## Read the whole backlog

`--limit 1000` is not optional: `issue list` caps at 50 and `next` at 10 by
default, and neither flags the truncation. If a result reaches the requested
limit, use the CLI's help-verified pagination or unlimited form to finish the
survey before claiming coverage. A capped result or an omitted project is not
a full pass: report the missing coverage and stop before editing.

## When AskUserQuestion is unavailable

A skill whose approval or confirmation round runs through `AskUserQuestion`
stops before recording, applying, or committing when that tool is absent, and
reports that it needs an interactive main session. It never substitutes
inferred answers or delegates the question to a subagent, which has no such
tool either.
