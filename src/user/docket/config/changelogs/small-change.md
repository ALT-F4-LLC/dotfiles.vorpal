# small-change changelog

Version history of `workflows/small-change.toml`, newest first. Each heading is
the `[pipeline].version` the entry describes.

## 11

`verify-ac` gains the input `implement.gate-results`, so it reads the
implement step's recorded `build` and `tests` verdicts. The `ac-commands`
pre-gate no longer runs build and tests inline, since its claim budget
killed them. `verify-ac.gate-results` stays for the pre-gate's own rows.
Fix-round gate results are not yet reachable: `fix` is a loop step, not a
predecessor of `verify-ac`, pending DKT-3131. No topology, routing, or
limit change.

## 10

Version history moves from the trailing comment on `version =` to
`changelogs/small-change.md`; the TOML no longer carries it. No topology,
routing, or limit change.

## 9

prose-only rewrite for concision; no topology, routing, or
limit change.

## 8

`review` repoints `payload = "findings@10"` to `findings@12`:
the description incorrectly still claimed reconcile-step
usage, moved off in an earlier version; findings@12 corrects
it to say review/design-qa only. Same shape, byte-identical
constraints. No topology or routing change.

## 7

`diff-scope-small` joins the implement and fix gate lists: the
track binds on the `small` label alone. The gate enforces the plan
skill's sizing rule mechanically: at most two touched paths in one
directory and no added file. No topology or routing change.

## 6

prose-only rewrite for concision; no topology, routing, or
limit change.

## 5

`lease_ttl` added to every `[limits]` entry, matched to that
entry's `max_step_duration`, so a lease lasts exactly as long
as the step may run. A long wave no longer outlives the
write-class lease and no longer draws an ack-reap panel;
`step heartbeat` could not extend past `max_step_duration`
anyway, so the ceiling is unchanged. No topology change.

## 4

three fixes, no topology change. Two earlier changelog
entries were stale against the current corpus: the
dispatch-chain comment now names `reconcile` among the
second chain's steps, and the label-timing comment no
longer misattributes a rule to a step's `when` (only a
workflow's `[match]` reads issue kind and labels). review
repoints to `findings@10` — a prose-only schema correction,
no validation-semantics change.

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
`verify-tribunal` -> `verify-ac-vote`. Every `after`, threshold route
key, and `<step>.<kind>` input reference updated to match.

## 1

the light track for an ordinary change that a person, the groomer
or the planner labelled `small`. Same implement step and gate list
as standard-change; one correctness judge instead of three; no
synthesize, reconcile or drain step, because those exist to cluster
several judges' findings and one judge's payload routes on its own
severity field, exactly as docs-only's review does. The label is
applied before activation because a workflow's `[match]` reads issue
kind and labels only, never the diff.
