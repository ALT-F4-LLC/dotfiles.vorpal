# docs-only changelog

Version history of `workflows/docs-only.toml`, newest first. Each heading is
the `[pipeline].version` the entry describes.

## 30

Version history moves from the trailing comment on `version =` to
`changelogs/docs-only.md`; the TOML no longer carries it. No topology,
routing, or limit change.

## 29

the trusted `tests` gate joins the implement and fix gate
lists: test suites (tests/docket-run-skill.test.sh among them)
read skill prose that docs-only issues edit, so a prose change
can break a suite, and before this gate only review and
verify-ac guarded that. No topology or routing change.

## 28

`review` repoints `payload = "findings@10"` to `findings@12`:
findings@10's own description incorrectly still claimed
reconcile-step usage, which every workflow's reconcile step
moved off in an earlier version; findings@12 corrects the
description to say review/design-qa only. Same shape,
byte-identical constraints. No topology or routing change.

## 27

`diff-scope-docs` joins the implement and fix gate lists: the
track binds on the `docs-only` label alone, so before this gate a
code diff labelled docs-only shipped past document-only gates
with no build, tests, scans, threat model or security vote. The
gate refuses any touched path that is not a document. No topology
or routing change.

## 26

prose-only rewrite for concision; no topology, routing, or
limit change.

## 25

`lease_ttl` added to every `[limits]` entry, matched to
that entry's `max_step_duration`, so a lease lasts exactly
as long as the step may run. A long wave no longer outlives
the write-class lease and no longer draws an ack-reap panel;
`step heartbeat` could not extend past `max_step_duration`
anyway, so the ceiling is unchanged. No topology change.

## 24

the review step repoints `payload = "findings@10"` — a
prose-only schema correction (findings@9's stale field
descriptions), no validation-semantics change. No topology
change.

## 23

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

## 22

corpus-wide naming-convention pass (src/user/docket/config/README.md).
Step renames only, no topology change: `verify` -> `verify-ac`,
`review-tribunal` -> `review-vote`, `verify-tribunal` -> `verify-ac-vote`
(vote steps now uniformly named `<gated-step>-vote`; this file's two
distinct vote steps get two distinct new names, not the same one).
Every `after`, threshold route key, and `<step>.<kind>` input
reference updated to match.

## 21

both vote gates seat tribunal-correctness alone.
review-tribunal fired on 3 of 15 reviews and decided 2 (one
approved, one rejected); verify-tribunal never fired here (33 of 33
ACs met). Too few decisions to measure a seat, so this is design
judgment stated as such: both gates ask whether a blocker's or a
report's evidence holds, which is the correctness lens, and both
already route a rejection to the fix loop, so a wrong single-seat
reject costs one round, never a park. Corpus-wide the correctness
seat matched 25 of 25 decided verify-tribunal outcomes, and one
voter tallies 1.0 or 0.0 against the 0.67 rule.

## 20

`blocked` joins unless_labels: a hold label so
an issue not yet workable matches zero registered workflows
until the label is removed.

## 19

two input edits, no topology change. (1) `fix` adds
`issue.latest.change-summary` beside
`implement.change-summary`: the engine never rebinds a loop
body's own inputs, so at fix@2 and later the packet carried
implement@0's account and omitted fix@(N-1)'s, the tree the
fixer actually stands on (three fix@2 packets in one run on
a sibling track all bound to implement@0).
`issue.latest.<kind>` is the engine's named form for exactly
this; at fix@1 both entries resolve to implement@0 and the
bundle de-duplicates them. The sibling tracks also fed their
fixers the synthesize clusters for member evidence; this
track has one judge and no synthesize step, and its
`review.findings` already carries that judge's evidence, so
nothing to add. (2) `issue.diff` joins `verify-tribunal`, as
`review-tribunal` already has it: without it context assembly
lifts no target_sha, wave.js seats the panel with "NO target
ref — seats read their own HEAD", and seats re-derive the
judged tree from the ac-report's prose. With it the bundle
and the packet header carry target_sha/target_worktree; the
wave's own log line still needs `step show` to surface the
field, an engine change tracked separately.
