# trivial-change changelog

Version history of `workflows/trivial-change.toml`, newest first. Each heading is
the `[pipeline].version` the entry describes.

## 8

Version history moves from the trailing comment on `version =` to
`changelogs/trivial-change.md`; the TOML no longer carries it. No topology,
routing, or limit change.

## 7

prose-only rewrite for concision; no topology, routing, or
limit change.

## 6

`diff-scope-trivial` joins the implement and fix gate lists: the
track binds on the `trivial` label alone, so a 400-line change
labelled trivial met zero judges. The gate refuses more than one
touched path, any added or deleted file, or more than ten changed
lines. No topology or routing change.

## 5

prose-only rewrite for concision; no topology, routing, or
limit change.

## 4

`lease_ttl` added to every `[limits]` entry, matched to that
entry's `max_step_duration`, so a lease lasts exactly as long
as the step may run. A long wave no longer outlives the
write-class lease and no longer draws an ack-reap panel;
`step heartbeat` could not extend past `max_step_duration`
anyway, so the ceiling is unchanged. No topology change.

## 3

`verify-ac` emits `ac-report@2` (adds `unmet-out-of-scope`)
and its vote predicate becomes `any(status != met)`, read after
`fix-loop`'s `any(status == unmet)`: an in-scope unmet still
loops, an out-of-scope or unverifiable AC goes to the one-seat
`verify-ac-vote` (approve passes with the gap filed, reject
routes fix-loop). No topology change; the measurement is on
standard-change@37.
Also `route-direct`, `route-loop` and `route-tend` join
unless_labels: an issue docket-groom routed to the operator's
own session, the tend queue, or a loop matches zero workflows,
like `blocked`, until the label changes; `route-run` stays
bindable.

## 2

corpus-wide naming-convention pass (src/user/docket/config/README.md).
Step renames only, no topology change: `verify` -> `verify-ac`,
`verify-tribunal` -> `verify-ac-vote`. Every `after`, `after_loop`,
threshold route key, and `<step>.<kind>` input reference updated to
match.

## 1

the lightest track, for a mechanical change that a person, the
groomer or the planner labelled `trivial`: a typo, a config value,
a one-line fix whose acceptance criteria a diff trace can verify.
Same implement step and gate list as standard-change, then AC
verification, the single-seat tribunal on an unverifiable AC, and
one fix round re-entering at verify. No judge at all: across the 225
distinct standard-change issues in every project's ledger, the
three-judge panel's whole in-run effect on changes of 20 lines or
fewer was a blocker fix round on 7 of 64, and the completion gates
(build, tests, secret-scan, vuln-scan, doc-validate), the AC
verification and the tribunal are the coverage here. Because that
7-in-64 is not zero, the `small` label wins when an issue carries
both, so a doubtful case takes the judged track, and the fixer reads
a step-level fragment saying the AC report is its whole work list.
Forecast rather than measured, from the same run's medians: 2
executor seats and about 21 seat-minutes (implement 12.8, verify
7.8), plus one tribunal seat when an AC is unverifiable, over two
dispatches instead of three. The label is applied before activation
because `[match]` and `when` read issue kind and labels only, never
the diff.
