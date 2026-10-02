# Reading a terminal run

Consumer: the docket-run skill, whose **Ending and resuming** section
points here. Read this file in full before characterizing a `done` or
`abandoned` run or re-presenting one of its parked decisions.

**A terminal run, `done` or `abandoned`, is picked up from its rulings,
not its statuses.** Step statuses, park messages, and issue statuses do
not say how a run ended. Before characterizing it or re-presenting a
parked decision, read that run's terminal events by kind:

```bash
docket events list --run $RUN --json --tail 400 | jq -r '
  (if type == "object" and has("data") then .data else . end)
  | (if type == "array" then . else .events end)     # missing .events beats a silent empty read
  | .[] | select(.kind as $k | ["issue-abandoned","step-resolved","step-approved","step-rejected","run-done","run-abandoned"] | index($k))
  | "\(.seq) \(.kind) \(.issue // "") \(.step // "") \(.data | tojson)"'
```

**Filter on the `kind` field; never keyword-grep the detail text.** Words
like `waiting-human` appear on the moments a run parked and never on the
moments it resolved: a grep for them selects questions and drops every
answer.

**The step-lifecycle fact that read rests on:** a step parked
`waiting-human` finalizes to `failed-routed` when its issue is abandoned.
That carries a decided park, not an undecided one; the resolution lives
in the event feed. An issue left at `review`/`todo` after a run-scoped
abandonment is frozen the same way, and a run whose issues were all
abandoned rolls up to `done` legitimately.

**Recorded rulings cite ids; those ids are required reading.** Read
everything an `issue-abandoned` note cites before putting any related
question to the operator. If a ruling turns out genuinely superseded, say
what it was and why, and let them rule on that.
