# Docket engine CLI — `docket events`

Covers the `docket events` family, the single copy of this engine CLI
contract, split out of docket's
[reference.md](../../docket/reference.md#json-envelope--per-verb-data-shapes)
(consumer: the docket-run skill), which still holds the response-shape
contract and parsing traps. Verified 2026-09-14 against `docket
nightly-112-gcffd10c` (commit `cffd10c`, built `2026-09-14T21:28:29Z`) by
`--help`/`--version` only; behavior and JSON examples were not re-run.

<a id="contents"></a>

## Contents

- [`docket events`](#events-commands) — 189 lines
  - [`events list`](#events-list) — 98 lines
  - [`events prune`](#events-prune) — 46 lines
  - [Attribution](#events-attribution) — 37 lines

<a id="events-commands"></a>

### `docket events` — `events.go`

The engine's event log, as a cursor feed. Every transition an engine verb makes
writes an event in the same transaction that performs it, so the log is the run's
own account of itself rather than a summary written afterwards.

<a id="events-list"></a>

#### `docket events list`

| Flag | Type | Default | Notes |
|---|---|---|---|
| `--since` | int64 | `0` | return events with `seq` **strictly greater** than this cursor |
| `--run` | string | `""` | filter to one run; omit for the project-wide feed |
| `--all-projects` | bool | `false` | show every project's events instead of the current project's |
| `--tail` | int | `0` | return the newest N events, still **oldest-first** — the mid-incident read, since reaching the end of a long feed by cursor means paging through all of it. Mutually exclusive with `--since` |
| `--limit` | int | `100` | maximum events returned, applied **after** ordering |
| `--follow` | bool | `false` | poll for new events and print them as they arrive; Ctrl-C to stop |

`--follow` uses the **global** `--interval` (default `2s`, minimum `500ms`) — the
same flag `--watch` uses, so the poll period has one definition across every verb
that polls. An interval below the floor is `VALIDATION_ERROR` (exit 3).

Each event is:

```
{ seq, at_ms, kind, run?, step?, step_id?, issue?, data }
```

`seq` is a monotonic counter that is **never reused**, including after a delete.
`run` is `RUN-N` and `step` is the rendered instance identity (`name@k#i`); both
are omitted when the event has none — a trust grant belongs to no run. `step_id`
is `STEP-N`, so a consumer can follow the feed straight into `step show`.
`data` is the transition's own payload, carried **verbatim**: core never reshapes
it, and never reads a key inside it.

`issue` is `DKT-N`, omitted when the event has none. **Filter on it, never on
the instance label**: instance labels collide across issues in one run — two
issues bound to the same workflow both have a `fix@1` — so a feed filtered by
label alone can misattribute a pass-route across that collision.

**The cursor contract.** `--since` is strictly greater, so you store the last
`seq` you saw and pass it back without re-reading that event. The read is one
query in one transaction over a monotonic counter, so an event written *while*
you are reading lands above your cursor and arrives on the next call. **No event
is ever skipped and none is ever returned twice.** Ordering is always oldest
first; there is no reverse mode, because a cursor feed that could run backwards
is a cursor feed that skips.

A cursor past the end returns an empty page, not an error — a consumer that has
caught up must be able to keep polling. A cursor *below the retained minimum* is
`GONE` (exit 9) rather than a silently short answer, and the message names the
`seq` to resume from. `docket events prune` is what puts a cursor there.

Without `--run` the feed is project-wide, which is the only place events
belonging to no run — trust grants, project registrations — are visible;
`--all-projects` widens it to every project in the store.

**How a store-level event is scoped.** An event's project is its run's,
else its issue's, else **the repository its payload names** — `repo` for a
trust change, `identity` for a `project-registered`. A store-level event
naming no repository at all is a fact about the store and appears in every
scoped view; one naming a DIFFERENT repository belongs to that repository's
trail. The scoped feed admits only rows scoped to this project or naming no
repository at all, so a `--tail` in one repository is not diluted by trust
rows recorded against others.

**Ids render under their OWNING project's prefix**, not the querying
project's. Rows also carry `project` — the owning project's name, omitted
in a single-project feed and shown as a column under `--all-projects`,
since two projects can both hold a `fix@1` and a `RUN-6` and the ids alone
do not say whose.

**`at_ms` is monotonic with `seq`.** `gate-rerun` and `gate-unmatched` stamp
`at_ms` at emission, and the writer clamps every event up to its
predecessor's stamp, so the documented oldest-first-arrival reading holds for
`at_ms` as well as for `seq`.

**Gate events carry their verdict**: `detail=<gate> verdict=<v>
exit=<n>`, so a failing gate is distinguishable from a passing one on the
feed itself. An unmatched gate carries no `exit` at all — it never ran, and
`exit=0` would read as a pass.

**`--follow` polls.** There is no daemon and no subscription: the flag runs
the same query on a ticker, printing only what is new each cycle, idle in
between. The cursor advances to the last `seq` actually returned, so the
same no-skip-no-repeat property the one-shot form has extends across
cycles.

Output is append-only: the screen is never cleared and no page is
reprinted, so a follow can be piped, grepped, and read afterwards. Ctrl-C
ends it and exits 0.

A follow whose cursor falls below the retained minimum — someone pruned
under it — **stops** with `GONE` rather than resuming at the new minimum.

Human mode renders one line per event and escapes stored strings on the way to
the terminal; `--json` carries the raw bytes, because the consumer there is a
program. Under `--json=v2` the result is the usual `{items, total, truncated}`
collection, where `total` counts matching events **before** the limit sliced
them.

**It writes nothing.** Reading the log cannot advance a run.

<a id="events-prune"></a>

#### `docket events prune`

| Flag | Type | Default | Notes |
|---|---|---|---|
| `--before` | int64 | `0` | delete events with `seq` **strictly less** than this |
| `--before-run` | string | `""` | delete every event of this run (`RUN-N`) |
| `--run` | string | `""` | narrow `--before` to one run |
| `--dry-run` | bool | `false` | report what would be deleted and delete nothing |
| `--yes` | bool | `false` | confirm the deletion; **required** unless `--dry-run` |

Exactly one of `--before` / `--before-run` is required: a destructive verb
with a default target is how a log gets deleted by a typo.

**It refuses more than it accepts.** Two refusals, neither negotiable:

- **Events of runs that have not reached `done` or `abandoned`** are never
  deleted (`CONFLICT`, exit 4, naming the runs). A live run's events are
  what the engine *computes from* — its budget floor is summed from its
  `step-claimed` events, and its saga resumes from its `gate-started`
  events — so pruning them would change the run, not only its record.
- **Events younger than `docket config events.retain`** are held back. That
  window defaults to `0`, which retains **everything**: prune deletes
  nothing until an operator states a retention policy. When the window
  holds rows back, the answer says how many.

Events belonging to no run — trust grants — are prunable by `--before`,
since there is no run whose liveness could forbid it.

**It deletes rows in `events` and nothing else.** No artifact, no step, no
run, no usage row, no dispatch row. It does not `VACUUM`.

The prune **records itself** as an `events-pruned` event whose `seq` is
above everything it removed, so a consumer that hits `GONE` and resumes at
the new minimum reads the explanation for its own gap first.

The answer is `{pruned, retained_minimum, held_by_retention?, dry_run?}`.
The retained minimum lets a consumer reset its cursor without a second
call.

Pruning costs the audit trail `docket run report` computes over: a trimmed
run reports fewer transitions than it actually made. Trim whole finished
runs rather than the oldest N events across all of them, and the report
stays honest for every run it still covers.

<a id="events-attribution"></a>

#### Attribution — who caused each transition

Every event kind maps to exactly one of four actors, and `docket run report`
publishes the per-actor counts:

| Actor | Meaning | Kinds |
|---|---|---|
| `next` | the scheduler | `step-ready`, `lease-reaped`, `join-completed`, `loop-entered`, `dispatch-abandoned`, `issue-promoted` |
| `gate` | a deterministic check, actions included | `gate-started`, `gate-recorded`, `gate-unmatched`, `gate-rerun`, `vote-opened`, `vote-tallied` |
| `threshold` | computed routing | `step-routed`, `step-failed`, `step-superseded`, `step-skipped`, `step-held`, `step-batch-overridden` |
| `human` | an operator verb, including one a harness relays | `run-*` (`run-started`, `run-activated`, `run-paused`, `run-resumed`, `run-abandoned`, `run-done`, `run-budget-set`, `run-repinned`), `step-claimed`, `step-heartbeat`, `step-recorded`, `step-resolved`, `step-approved`, `step-rejected`, `step-annotated`, `issue-abandoned`, `issue-diff-repinned`, `gate-override-granted`, `spawn-admitted`, `trust-*`, `project-registered`, `dispatch-opened`, `dispatch-closed`, `reap-acknowledged`, `conductor-seated`, `events-pruned` |

The three operator lifecycle kinds each carry `data` of `{from, to,
reason}`, written in the same transaction as the status they record.
`lease-reaped` is attributed to `next` whether the lease expired or
`docket step reap` forced it; `data.forced` plus the operator's `reason`
separates the two.

**`run-done` is `human`** even though
no operator verb moves a run to `done`: the reconciliation rollup writes
it, but runs inside whatever operator-actor verb completed the run's last
work. **`step-claimed` is `human`, not `next`**: the scheduler *offers*,
and something else *takes*. **`run-paused` is `human` even when a budget
breach causes it**, because the transition means "a person must now
decide"; `data.reason` distinguishes a budget breach from an operator's
`run pause`. **`events-pruned` is `human`** because nothing in the engine
prunes on its own — the event exists only because somebody ran the verb.
**`conductor-seated` is `human`** for the same reason: `run conduct` is an
operator verb whether a person or a harness relay ran it, and its
`data.actor` and `data.cwd` say which.

Attribution is computed over the events that *remain*, so a pruned run
reports fewer transitions than it made. `events-pruned` is what keeps that
honest — a trimmed log says it was trimmed rather than looking like a
quieter run.
