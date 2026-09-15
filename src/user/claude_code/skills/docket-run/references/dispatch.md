# Docket engine CLI — `docket dispatch` and `docket next --run`

Covers the `docket dispatch` family and `docket next` in step mode (`--run`).
Consumer: the docket-run skill; this file is the single copy of the engine CLI
contract for these verbs, split out of docket's reference.md, whose [JSON
envelope
section](../../docket/reference.md#json-envelope--per-verb-data-shapes) still
holds the response-shape contract and parsing traps. Command and flag inventory
verified 2026-09-14 against `docket nightly-112-gcffd10c` (commit `cffd10c`,
built `2026-09-14T21:28:29Z`) by `--help` and `--version` only; behavioral
claims and JSON examples were not re-run.

<a id="contents"></a>

## Contents

- [`docket next` in step mode](#next-run) — 81 lines
- [`docket dispatch`](#dispatch-commands) — 266 lines
  - [`dispatch open`](#dispatch-open) — 73 lines
  - [`dispatch verify`](#dispatch-verify) — 37 lines
  - [`dispatch close`](#dispatch-close) — 39 lines
  - [`dispatch backfill-usage`](#dispatch-backfill-usage) — 49 lines
  - [`dispatch abandon`](#dispatch-abandon) — 18 lines
  - [The write-reap acknowledgment](#dispatch-write-reap-ack) — 25 lines

<a id="next-run"></a>

### `docket next` in step mode — the dispatch offer

The flag table for `docket next` sits with issue mode in
[docket's reference](../../docket/reference.md#docket-next--nextgo); this
section is the `--run RUN-N` contract.

**Two modes.** Without `--run` this is the issue-mode verb, unchanged. With
`--run RUN-N` it lists that run's OFFER instead, in the `next row` shape
below: the claimable steps **plus their staged dependency closure** — rows
carried ahead of their own readiness (`status: staged`), leveled by `stage`,
so a dispatcher sees whole dependency chains rather than one frontier at a
time. **Step mode's `--limit` default does not apply**: omit the flag and the
offer is unbounded — the registered default of `10` is issue-mode's alone,
and the v2 envelope's `truncated` reads `false` whenever no `--limit` was
actually typed. The offer **rations class headroom**: a class with a finite
`[limits] max` contributes at most that many rows, so fewer same-class rows
than ready steps is the offer working, not a bug. The issue filters
(`--status`, `--priority`, `--label`, `--type`) are **refused** in step mode
with `VALIDATION_ERROR` rather than silently ignored, so a dispatcher never
trusts a filter that does nothing.

Step mode may WRITE: it reaps expired step leases, returning them to the ready
pool, and auto-abandons a dispatch manifest that has outlived its TTL. Lease
reaping happens here and at `step claim` and nowhere else; the dispatch
auto-abandon happens here alone — `claim` never retires a manifest, since a
dispatch is about a *batch*, and letting a single-step verb expire one would
let a claim silently unwedge a run whose relay is still alive.

**Step mode REFUSES rather than returning an empty list.** An empty ready set
means "nothing to do"; a refusal means "I will not answer until you
reconcile" — a dispatcher cannot tell those apart from a zero-length array.
Each refusal is `CONFLICT` (exit 4):

| Refusal | When | The way out |
|---|---|---|
| open dispatch | a manifest is open for the run and has not expired | `docket dispatch close`, `docket dispatch abandon`, or wait for `dispatch.ttl` — the message names all three plus the dispatch and its expiry |
| `claimed-but-unrecorded` | a step is `claimed`/`running` and has been silent longer than `dispatch.grace` | **lease expiry clears it**: the lease lapses, the next `next` reaps the step, and the discrepancy dissolves. The message names the expiry time |
| `usage-rows-missing` | a step finished after the run was activated with no recorded usage, **in a run that has ever opened a dispatch** | record the usage with `docket dispatch backfill-usage` (or `step complete --usage` at the time), or `docket dispatch close --accept-missing-usage`, which settles the accepted steps and clears the discrepancy immediately (no back-fill required to unblock `next`) |

The reap runs *before* the refusal is evaluated, so a step this invocation
frees is never reported as a discrepancy naming a resolution that already
happened.

**Discrepancies are a property of the run, not of a manifest** — a relay that
never opened a dispatch can still leave a claimed step unrecorded. But
`usage-rows-missing` applies only to runs with dispatch history: a run no
relay ever drove has nobody owing usage, so a solo operator completing steps
without `--usage` is never refused.

Issue mode (`docket next` with no `--run`) probes none of this and is
byte-identical to what it was before dispatches existed.

`next --run` also names any unacknowledged write-class reaps on **stderr**,
with the flag that clears them — a headroom denial with nothing running is
otherwise baffling. The JSON payload is unchanged by it.

The `next row` shape (engine-spec §11.4):

| Field | Meaning |
|---|---|
| `step` | `STEP-N` id |
| `instance` | rendered `name@k#i` identity |
| `issue` / `run` | `DKT-N` / `RUN-N` |
| `kind` | `executor` \| `action` \| `human` \| `vote` |
| `executor` | opaque hint; **absent** on human and vote steps |
| `labels` | the issue's labels, for label-keyed routing policy; **omitted** when the issue has none |
| `voters` | the step's opaque voter list; **present only on vote steps** |
| `proposal` | `DKT-VN` of the proposal this vote step opened; **absent** until it is opened |
| `class` | opaque concurrency-accounting key |
| `attempt` | **claims made against this step, ever** — a 0-based spent-count, incremented at claim time ONLY. Nothing else moves it: not a reap, not `step fail`, not `step resolve --as retry` (retry refreshes the budget base; the counter is never reset). A `next` row necessarily samples it BEFORE the claim it invites, so a fresh step reads `0` and a step with one dead claim reads `1`; the packet/`step show` after that claim reads one higher. It counts claims, NOT failures — a reaped lease spends one with nothing failing. An escalation policy wants `failed_attempts` below, not this |
| `failed_attempts` | how many of those claims ended in an explicit `step fail` — the holder measured its work and recorded the failure. **Omitted when 0** |
| `reaped_claims` | how many were reaped **without** a failure — lease expiry, `max_step_duration`, forced `step reap`: the holder went silent, nothing was measured. **Omitted when 0.** `failed_attempts + reaped_claims ≤ attempt`; the remainder is live claims, recorded completions, and pre-v23 history (the migration back-fills nothing) |
| `expected_cost` | declared cost; accrues to the run's budget floor when this step is claimed |
| `lease_ttl_s` | lease TTL in **seconds** |
| `stage` | start-order constraint **within this offer**: do not start a row until every lower-stage row in the set has completed; rows sharing a stage run concurrently. `0` (omitted) means unstaged. NOT a priority — for `ready` rows it is a hint, for `staged` rows `claim` itself enforces the predicate |
| `conditional` | `true` on a staged row sitting (transitively) behind a HOLD-CAPABLE in-offer predecessor — an `aggregate` declaring `hold_spread`, whose completion may hold for an operator instead of routing. Advisory, like `stage`: confirm the predecessor actually ROUTED before spawning such a row, or defer it to the next offer — spawning at the stage boundary risks paying a full boot for a claim refusal. Omitted when false |
| `status` | effective status, never stored — `ready`, or `staged` on a closure row offered ahead of its readiness (claimable only once its lower-stage predecessors record) |
| `metadata` | the definition's opaque KV, verbatim |

<a id="dispatch-commands"></a>

### `docket dispatch` — `dispatch.go`

A **dispatch** is a frozen copy of one `next --run` answer, recorded so a batch
dispatcher's spawns can be checked against what the engine actually offered.

It is **not a lock and not a claim.** The steps in a manifest are still
`pending`, and any claimant may still claim them — a dispatcher is the thing
that *starts* workers, not a worker, so claiming on its behalf would mint a
token nobody holds. What a manifest buys is that the engine can refuse to offer
a *new* batch while the previous one is unreconciled, which turns a relay that
lost track of its own spawns from a silent double-executor into a stalled run
with a reason.

| Verb | Writes | Effect |
|---|---|---|
| `dispatch open --run RUN-N` | yes | computes the offer exactly as `next --run` does and records it |
| `dispatch verify --run RUN-N` | **no** | recomputes and compares to the manifest, byte for byte |
| `dispatch close --run RUN-N` | yes | reconciles and closes — refused while a discrepancy exists |
| `dispatch abandon --run RUN-N` | yes | gives up on the manifest **unconditionally** |
| `dispatch backfill-usage --run RUN-N` | yes | records usage a relay measured but the claimant could not report |

`--run` is required on all five. None are watch-eligible.

<a id="dispatch-open"></a>

#### `docket dispatch open`

| Flag | Type | Default | Notes |
|---|---|---|---|
| `--run` | string | — | **required** |
| `--limit` | int | `0` | maximum manifest rows; 0 is no limit. Slices *after* ordering, so a limited manifest holds the highest-priority steps |
| `--ack-reap` | int64Slice | `nil` | acknowledge a write-class reap by its `lease-reaped` event `seq`; repeatable |

Response is engine-spec §11.4's `dispatch` shape: `{dispatch, run, opened_seq,
expires_ms, rows: [<next row>…]}`, plus `reaped` and `reap_hold` (both
`omitempty`, absent when this open reaped nothing). Each row is stored as its
canonical JSON bytes plus a sha256, so `verify` compares bytes rather than a
re-serialization that could differ in key order.

`open` performs the same lazy lease reap `next` does — offering a stale step
that a reap would have freed would make the manifest wrong the moment it was
written. `reaped` names the step instances THIS open reaped, and `reap_hold`
is the guard's own denial text for any unacknowledged bounded-class reap
still holding the run afterward (this open's own reaps included): the seq of
each and `--ack-reap` as the flag that clears it. `--ack-reap` applied on the
same call cannot cover a reap this open performs after the ack, so a relay
reading a non-empty `reap_hold` acknowledges it or convenes an ack-reap panel
before composing the next launch, rather than discovering the same hold from
a `guard spawn` denial afterward.

**`stale_targets` asks about CONTENT, not just about the sha.** Integration
cherry-picks an executor's worktree commit onto the shared branch, which
always mints a new sha, so a recorded target is never an ancestor of HEAD
after the designed flow and ancestry alone would warn on every run. A
disproved ancestry opens a second question: does HEAD still carry that
target's content on the paths the work touched — or, where that cannot be
answered (no merge base, or a target that touched nothing), is HEAD's
**root tree the same object**? Either equality is silence. The reason text
says which shape it is: `and its tree still differs from that HEAD on the
paths the work touched` is a **measured** divergence to act on, while
`whether HEAD still carries its tree could not be determined` is a sha that
moved with the tree question unanswered — check the tree by hand before
reading that one as divergence.

**`stale_targets` names the claim-time semantics in its own reason text.**
A claim does **not** re-derive a step's target from the branch's current
HEAD: it re-resolves the step's declared inputs and takes the target from
the winning `issue.diff` artifact's recorded round record, whose diff body
is the text its producer recorded at completion. So a warned row stays on
the diverged sha unless an upstream step records a **newer** diff for that
issue before the row is claimed — exactly the condition under which
dispatching through the warning is safe, and it is stated in the `reason`.

**Pin drift is surfaced the same advisory way `stale_targets` is** — a
`pin_drift` field, the run's unsound pin verdicts, rides beside
`stale_targets` in the response, plus the same lines on stderr for a human
(naming each drifted ref, both hashes, and `docket run repin` as the
remedy). Advisory, not a refusal — `open` still returns the manifest —
because drift blocks only the steps that read a drifted ref, and the
per-step `CONFLICT` at claim/render remains the actual enforcement.
`pin_drift` is **absent whenever every pin is sound**.

**A manifest short of the rows you can see are ready says why.** When the
engine withholds steps for lack of budget headroom, the response carries
`budget_held` — `withheld: N step(s), reason=budget headroom X < cost:
<instance> (cost Y)…` — and the same line goes to stderr for a human;
`next` reports the identical fact on stderr. The field is **absent
whenever nothing was withheld**. Without it, an offer of 1 of 5 ready
judges — or an empty `next` against a run reporting 9 pending — is
indistinguishable from a graph that has run dry.

**Exactly one dispatch is open per run**, enforced by a partial unique index
rather than a check-then-insert: two relays racing produce one manifest and one
`CONFLICT`, never two manifests. The loser's computation is discarded, not
merged — a merge would produce a manifest neither relay saw.

<a id="dispatch-verify"></a>

#### `docket dispatch verify`

**This verb writes nothing, including no lease reap.** It is the one
scheduling-shaped verb that must not reap: reaping would change the very
ready set it was asked to compare against, and a verify that mutated its
own subject could never fail.

Equal is exit 0 with `{verified: true}`. Unequal is `CONFLICT` naming the
**first differing position**, with the stored row and the recomputed row
both rendered — so an operator can see whether a lease lapsed, a priority
changed, or a step completed.

**Every stored row gets a verdict, in one pass** (`rows` in the payload,
summarized above the refusal for a human): `matched`, `recorded` (the step
moved off the scheduler — the dispatch working, not a failure),
`rendering-shifted` (still offerable, renders differently than at open), or
`genuinely-missing` (still non-terminal and yet no longer offerable — the
narrow, alarming case). The comparison covers every stored row rather than
stopping at the first shifted one, so a dispatch where several steps moved
mid-flight reports all of them. The exit code is unchanged: any row that is
not `matched` or `recorded` still fails the verb.

`stage` and `conditional` are **normalized before the comparison**: both
are set-relative and legitimately move as an in-offer predecessor records or
routes, so a row whose stage collapsed or whose conditional mark cleared is
not a discrepancy.

A step that has legitimately left the scheduler is **skipped**, not
reported. That set is terminal (`done`, `skipped`, `superseded`,
`failed-routed`) **plus `waiting-human`**: a step that recorded correctly
and then parked is absent from the recomputation by design. The stored
pair's own hash is checked **before** any of that, so tamper detection runs
ahead of any drift check and a tampered row cannot escape it by also
drifting.

<a id="dispatch-close"></a>

#### `docket dispatch close`

| Flag | Type | Default | Notes |
|---|---|---|---|
| `--run` | string | — | **required** |
| `--accept-missing-usage` | bool | `false` | close despite `usage-rows-missing`, recording the acceptance |
| `--backfill-from` | string | — | a JSON array of `{step, unit, quantity}` (`-` reads stdin): back-fill, verify, then close in one invocation |
| `--source` | string | `backfilled` | with `--backfill-from`: who measured it, recorded on every row |
| `--on-duplicate` | string | `refuse` | with `--backfill-from`: `refuse` the batch or `skip` a row whose (step, attempt, unit) is already recorded, reporting it |
| `--skip-integration-check` | string | — | close without verifying integration, recording this REASON on the close event; the operator's override, never a relay's |

**Close verifies integration.** Every write-class step recorded in the
dispatch must have its commit on the shared branch — an ancestor of HEAD,
or patch-equivalent (`git cherry`; a cherry-pick mints a new sha for
identical content). An unintegrated commit refuses `CONFLICT` naming the
step, its sha, and its worktree; a cherry that errors counts as
unintegrated. Integrate, then close again. The close event records
`integration: verified|skipped` and the shas checked, which `run report`
shows.

Refuses `CONFLICT` while any discrepancy exists, enumerating each with its
resolution (the table under `docket next` above). `--accept-missing-usage`
accepts **only** that class: `claimed-but-unrecorded` has its own
resolution — lease expiry — and a flag that accepted both would let a relay
close over work that is still running.

The acceptance is *recorded*, not merely permitted: `close_reason` becomes
`accepted-missing-usage` and the accepted step list rides in the
`dispatch-closed` event's `data`.

**Acceptance settles the discrepancy, not merely the close.** The
`usage-rows-missing` probe reads `steps.usage_recorded`, and acceptance
writes that column directly for every step it accepts, so a later `next`
no longer recomputes the same refusal. Settling is not reporting: the
ledger stays empty until `docket dispatch backfill-usage` writes real
numbers, still how usage reaches `run report`'s budget accounting.

<a id="dispatch-backfill-usage"></a>

#### `docket dispatch backfill-usage`

| Flag | Type | Default | Notes |
|---|---|---|---|
| `--run` | string | — | **required** |
| `--step` | string (repeatable) | — | step whose usage is being recorded |
| `--unit` | string (repeatable) | — | unit for the matching `--step`; core has no default unit |
| `--quantity` | float (repeatable) | — | quantity for the matching `--step` and `--unit` |
| `--from-json` | string | `""` | JSON array of `{"step","unit","quantity"}`; `-` reads stdin |
| `--on-duplicate` | string | `"refuse"` | `refuse` \| `skip` — what to do with a row whose `(step, attempt, unit)` is already recorded |
| `--source` | string | `"backfilled"` | who measured it; recorded on every row |

engine-core §7's back-fill: a relay that measured its own spawns carries
those numbers into the ledger, with the source recorded. Usage otherwise
rides only on `step complete --usage`, which a claimant that cannot observe
its own consumption has no way to supply.

Two forms, one per invocation — `--step/--unit/--quantity` pair
positionally (the Nth of each is one row), or `--from-json` for a whole
batch. Passing both is refused: one batch, one source of truth.

**The whole batch is one transaction.** A back-fill that half-applied would
leave a dispatch neither closable nor honestly re-runnable.

Rows land on the step's **recorded attempt**; there is deliberately no
flag to name a different one, since back-filling an arbitrary historical
attempt is rewriting history. The ledger's `(step, attempt, unit)` key
means a retried step's second attempt records *beside* its first, and a
repeat of the same triple is refused `CONFLICT` rather than merged.

**`--on-duplicate` decides how a repeat is handled.** `refuse` (the
default) aborts the whole batch, right when a duplicate means real spend is
about to be double-counted. `skip` passes that row over, records the rest,
and **names every row it skipped**. Cross-wave duplicates are structural (a
gate probed in wave N and seated in wave N+1 emits usage in both
journals), and aborting the batch for them meant hand-filtering rows
before every re-run. A skipped row writes nothing, so the batch stays
all-or-nothing over the rows it actually records.

**To see what is already recorded, read `docket run report`'s
`step_usage`** — the ledger row by row, with each row's step, instance,
attempt, unit, quantity, and source. The budget section sums the same rows
per unit; `step_usage` is the detail behind that headline.

`--source` is free text and always written explicitly, so a relay's
reconstruction stays distinguishable from a claimant's own `reported` rows.

<a id="dispatch-abandon"></a>

#### `docket dispatch abandon`

| Flag | Type | Default | Notes |
|---|---|---|---|
| `--run` | string | — | **required** |
| `--reason` | string | `""` | why; recorded in the `dispatch-abandoned` event |

**Unconditional, and that is the point.** This is the crashed-relay path:
the relay is gone and cannot resolve anything, so a recovery verb that
refused to recover while a discrepancy existed would let a crashed relay
wedge a run.

Nothing is lost. Opening a manifest never claimed anything, so its steps
return to the ready set intact, and an executor that claimed one *before*
the crash finishes normally.

<a id="dispatch-write-reap-ack"></a>

#### The write-reap acknowledgment

Reaping a lease in a class with a finite `[limits] max` **holds that
class's headroom** until somebody acknowledges the reap. The database
lease is not a tree fence: nothing about an expired lease stops a
still-running process from writing, so a successor must not start beside
a writer that may still be alive.

Core cannot check a process it did not start, so it asks for the one fact
it cannot observe. The acknowledgment **never requires the dead relay** — a
new session, which may be a person typing, confirms the tree is quiet and
passes `--ack-reap <seq>`.

- The reaped step itself is re-offered; other steps in its class are not.
- Classes with **no** `[limits] max` get neither ack rows nor a hold. A repo
  with no `[limits]` never sees this mechanism at all.
- Acking a seq that is not a reap, or not this run's, is `VALIDATION_ERROR`.
  Acking the same seq twice is a success that changes nothing.
- `acked_by` records the **verb** (`dispatch-open`), never a user identity —
  core has no identity model.

`docket guard spawn --ack-reap` is the other entry point and lands with the
guard verbs.
