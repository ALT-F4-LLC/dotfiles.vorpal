# Discovery

How a simplify-code sweep finds its units: how the repository is split, how many
read-only agents it spends, and what each returns. The workflow
`simplify-code.js` implements it; the skill's §1 launches it. A change to a
shard rule or the agent backstop lands in the workflow and here together.

## Cost model

The Workflow runtime runs at most `max(2, min(16, CPUs - 2))` agents at once, and a
two-CPU host runs two. A round's wall time is therefore its agent-minutes
divided by the host's width, not the longest chain. Measured on a two-wide
host, 16 scouts and 12 refuters ran as 14 serial waves of about 1.3 minutes
each, and 12 of the 16 scouts each re-read the whole repository. The design
below spends agent-minutes on reading each file once, on refuting every
finding, and on nothing else.

## Shards

The caller splits the source files into disjoint shards with
[`shard.sh`](shard.sh): `shard.sh <repo> [lines per shard]` prints
`[{ name, files, lines }]`, highest priority first (churn per line over six
months, because cruft in a hotspot is read most). Files that sit together in
the tree share a shard; tests, generated and vendored paths are left out.
Pass the array as `shards`.

A round seats one **shard scout** per shard. Each reads every
file of its shard once against the whole [catalog](catalog.md), all pattern
sections at the same time, and treats an entry's Signal as a hint, not a
filter. It also returns the Report only items of its shard with their
enclosing symbol. One **tree scout** covers what a per-shard read cannot see:
near-identical code in more than one file, and unused symbols that the
diagnostics the repository already produced report (passed in as
`baselineReports`; the skill runs no build or lint).

All scouts are read-only: search, read, LSP, and read-only git. None builds,
tests, or writes, so they leave the checkout exactly as they found it.

## Refutation

Every ranked unit is refuted; nothing cuts the list. As soon as a scout
returns, the workflow merges its units by path, drops the excluded ones
(tests, generated and vendored files, ledgered paths), sets aside the units a
scout judged a real security boundary, ranks the rest, groups whole units into
batches of up to ten items, and sends each batch to two refuters while other
scouts still read. A refuter defaults to refuted and must confirm each
numbered item is real: the code is where the item says, its entry applies, and
no Risk field or Leave alone case covers it. Two refuters lead from different
angles (false positive, evidence) and both must uphold an item. A refuter that
returned nothing refutes nothing. An
item a refuter explicitly rejected is remembered by its key and passed back as
`refutedKeys`, so later rounds do not re-find it until its path changes. A key
a kept or unvoted item shares is not remembered. The skill passes the keys of
skipped, declined, and filed findings the same way.

Units whose refutation failed, and units with an item that got no vote, come
back as `unverified` with a reason; shards whose scout returned nothing come
back as `uncovered`. Those items are nothing yet; the same unit's confirmed
findings still count.

## Split launches

The width limit is per Workflow launch, not per host. Measured on the
two-CPU host: three separate launches of six sleeping agents each ran six
agents at once (the two-wide waves of each launch overlapped), and finished in
80 seconds against about 216 for one launch. So the skill splits the shard list
into several launches and starts them in one turn: each launch takes a slice
of the shards, and the first also takes the tree scout (`tree: false` on the
rest). The slice count is the number of shards divided by four, rounded up, at
most six: the agents wait on the model, not on the CPU, and more launches only
add refuter contention. Each launch refutes its own units as its scouts
return; the skill merges the returns by path and drops from `refutedKeys` any key a launch's `units` still carries.

A later round in the same sweep scouts only the shards whose files appear in
`git diff --name-only <surveyed-head> HEAD`, plus the shards that failed or hold `unverified` units.

## Security boundaries

A scout that reads a unit implementing authentication, authorization, session
handling, secret handling, cryptography, permissions, or sandboxing, or one
that checks untrusted input at a privilege boundary, sets `securityBoundary`
and analyzes nothing in it. The workflow also skips a path whose name is on the
[list](gates.md#security-boundary-paths) as a backstop. Both come back as
`securitySkipped`; the skill ledgers them and reports them.

## Scope

A sweep looks at everything: every shard of the source is scanned, every
proposal a scout makes is refuted, and every unit that survives is a candidate
to file as an issue. No setting trims the shard list or the unit list. `MAX_AGENTS` in the
workflow is a runaway backstop on agents per launch, not a coverage limit.
