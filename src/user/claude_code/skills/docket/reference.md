# Docket — complete command & flag reference

Split out of SKILL.md on 2026-08-19. It was 2,371 of that file's 4,022 lines
and loaded in full on every invocation, while agents ran `docket <verb> --help`
1,226 times in the same week and used only 72 distinct flags across 14,648
invocations. The CLI's own `--help` is authoritative and cheaper than this
file; reach here for the exhaustive per-flag semantics `--help` does not carry.

## Complete Command & Flag Reference

Every flag below is transcribed directly from the `cmd.Flags().*` calls in
the corresponding `internal/cli/*.go` file's `init()`. "Req." marks flags
enforced via `cmd.Flags().MarkFlagRequired` (Cobra rejects the command
before `RunE` runs if absent) — distinct from flags that are merely
required *in JSON mode* by manual checks inside `RunE` (noted in Notes).

### `docket issue` (alias `i`) — `internal/cli/issue.go`

#### `docket issue create` — `issue_create.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--title` | `-t` | string | `""` | Required in `--json` mode |
| `--description` | `-d` | string | `""` | `"-"` reads from stdin |
| `--status` | `-s` | string | `"backlog"` | |
| `--priority` | `-p` | string | `"none"` | |
| `--type` | `-T` | string | `"task"` | |
| `--label` | `-l` | stringSlice | `nil` | repeatable |
| `--file` | `-f` | stringSlice | `nil` | repeatable |
| `--assignee` | `-a` | string | `""` | |
| `--parent` | — | string | `""` | parent issue ID |
| `--scope` | — | stringSlice | `nil` | repeatable; path glob this issue is expected to touch |
| `--idempotency-key` | — | string | `""` | replay protection; repeat returns the original issue |

#### `docket issue edit [id]` — `issue_edit.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--title` | `-t` | string | `""` | only applied when explicitly set |
| `--description` | `-d` | string | `""` | `"-"` reads from stdin |
| `--status` | `-s` | string | `""` | |
| `--priority` | `-p` | string | `""` | |
| `--type` | `-T` | string | `""` | |
| `--assignee` | `-a` | string | `""` | |
| `--file` | `-f` | stringSlice | `nil` | repeatable; **replaces** existing file list |
| `--parent` | — | string | `""` | `"0"` or `"none"` clears parent |
| `--scope` | — | stringSlice | `nil` | repeatable; **replaces** the declaration, `--scope=` clears it |
| `--if-version` | — | int | `0` | apply only at this version; `CONFLICT` otherwise |

**`--scope` is not `--file`.** `--file` records the concrete paths an issue
concerns, and `docket plan` uses them to split colliding work. `--scope` is a
list of path **globs** declaring what an issue is *expected* to touch — a
judgment made ahead of the work, which activation snapshots and which the
scheduler will use for mutual exclusion between steps. They differ in
cardinality, in semantics (actual vs. intended), and in matching rule (equality
vs. glob intersection).

An issue created without `--scope` stores SQL `NULL`, not `[]`: "no scope
declared" and "declared to touch nothing" are different facts. An `issue edit`
that never mentions `--scope` leaves an earlier declaration alone.

**Reading it back:** `issue show` and `issue list` carry `scope` **when the
issue declares one**, under plain `--json` as well as `--json=v2` — the one
amendment to the v1 freeze (DKT-55, see above). The three states are
distinguishable on the wire: no key at all is undeclared, `[]` is
declared-to-touch-nothing, and a populated array is the declaration. A
declared scope also survives `export`/`import` intact, `NULL` included.

#### `docket issue show [id]` — `issue_show.go`

No local flags. Watch-eligible.

#### `docket issue list` (alias `ls`) — `issue_list.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--status` | `-s` | stringSlice | `nil` | repeatable |
| `--priority` | `-p` | stringSlice | `nil` | repeatable |
| `--label` | `-l` | stringSlice | `nil` | repeatable |
| `--type` | `-T` | stringSlice | `nil` | repeatable |
| `--assignee` | `-a` | string | `""` | |
| `--parent` | — | string | `""` | |
| `--roots` | — | bool | `false` | root issues only |
| `--tree` | — | bool | `false` | indented hierarchy |
| `--sort` | — | string | `""` | `field:direction`, e.g. `priority:asc` |
| `--limit` | — | int | `50` | |
| `--all` | — | bool | `false` | include `done` issues |
| `--project` | — | string | `""` | list ANOTHER project's issues, by name, identity path, or row id (DKT-72) |

Watch-eligible.

Listing is otherwise cwd-scoped: the project the working directory resolves to.
`--project` is the escape hatch a machine-global store needs — without it,
reading another project's issues means changing directory into it, and is
impossible for a project whose checkout is not on this machine. Ids render
under the NAMED project's prefix, not the caller's, for the same reason
`events list --all-projects` does (DKT-67): the prefix is the only thing on the
row that says whose issue it is. An ambiguous name is refused with the
candidates' ids rather than resolved by guess; `docket project list` is where
the names come from.

#### `docket issue close [id]` — `issue_close.go`

Shorthand for `move <id> done`.

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--if-version` | — | int | `0` | apply only at this version; `CONFLICT` otherwise |

Ends a live lease. The holder must supply its token (`DOCKET_TOKEN` or stdin);
a non-holder gets `AUTH_ERROR` (exit 5). An unclaimed issue needs no token.

#### `docket issue claim <id>` — `issue_claim.go`

Takes a lease and mints a capability token, returned exactly once.

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--owner` | — | string | — | **required**; identifies the lease holder |
| `--ttl` | — | duration | configured | lease duration; overrides the configured TTL |
| `--class` | — | string | `""` | executor class whose configured TTL applies (opaque) |

Response (`--json`): `{"issue":"DKT-N","token":"<64 hex>","lease_expires_ms":N}`.
Under `--json=v2` it also carries `attempt` and `version`. Exit 4 if a live
lease is held; exit 2 if the issue does not exist.

#### `docket issue heartbeat <id>` — `issue_heartbeat.go`

Extends a lease you hold. Token via `DOCKET_TOKEN` or stdin. Does not change
`attempt` — a heartbeat is not a new claim.

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--ttl` | — | duration | configured | extension length |
| `--class` | — | string | `""` | executor class whose configured TTL applies |

#### `docket issue release <id>` — `issue_release.go`

Releases a lease you hold, returning the issue to the unclaimed pool
immediately. No local flags. Token via `DOCKET_TOKEN` or stdin. `attempt`
survives; the released token never works again.

#### `docket issue move <id> <status>` — `issue_move.go`

Two modes: a **status move** (two positional args, `id` and target status) or
a **project migration** (`<id>` plus `--project`, no status arg).

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--if-version` | — | int | `0` | apply only at this version; `CONFLICT` otherwise (enforced even on a no-op move). Status moves only — with `--project` it is a `VALIDATION_ERROR` |
| `--project` | — | string | `""` | migrate the issue **and its whole sub-issue tree** to another project in the shared store |

**Migration (`--project`)** re-homes work that landed in the wrong project —
most commonly a gap recorded by `step complete --gap-file`, which lands in the
run's own project unconditionally. The target resolves in order: exact
`identity`, then numeric `id`, then unique `name`, then unique `prefix` (the
name/prefix matches are case-insensitive); an ambiguous name or prefix is a
`VALIDATION_ERROR` pointing at `docket project list`. Labels re-map **by
name** into the target project (created there when missing, color preserved);
comments, relations, and activity ride along untouched — ids are store-wide,
so nothing referencing the issue goes stale. The response carries the target
project and the full list of migrated ids.

| Refusal | Code | Exit |
|---|---|---|
| a status arg **and** `--project` together | `VALIDATION_ERROR` | 3 |
| the issue has a parent — a sub-issue migrates with its root, never alone (migrate the root, or `issue edit --parent none` first) | `VALIDATION_ERROR` | 3 |
| the issue (or any sub-issue) belongs to a run — a run's snapshots and steps are project-scoped bookkeeping | `CONFLICT` | 4 |
| issue not found | `NOT_FOUND` | 2 |

#### `docket issue reopen [id]` — `issue_reopen.go`

Only transitions if currently `done`, sets status to `backlog`.

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--if-version` | — | int | `0` | apply only at this version; `CONFLICT` otherwise |

#### `docket issue delete <id>` — `issue_delete.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--force` | `-f` | bool | `false` | cascade-delete sub-issues; mutually exclusive with `--orphan` |
| `--yes` | `-y` | bool | `false` | alias for `--force` (DKT-72) |
| `--orphan` | — | bool | `false` | promote sub-issues to root; mutually exclusive with `--force` |

`--yes` is an ALIAS, not a third behavior: the confirmation it answers is a
three-way choice (cascade, orphan, cancel), and a flag meaning "yes" without
saying to what would have to pick one silently. `--force` names the choice;
`--yes` is the spelling scripted cleanup reaches for. An issue with no
sub-issues never asks anything and needs neither flag.

#### `docket issue log [id]` — `issue_log.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--limit` | — | int | `20` | clamped to min 1 |

Watch-eligible.

#### `docket issue comment add [id]` / `docket issue comment list [id]` — `issue_comment.go`, `issue_comment_list.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--message` | `-m` | string | `""` | (`add` only) required in `--json` mode if stdin isn't piped |
| `--idempotency-key` | — | string | `""` | (`add` only) replay protection |

`comment list` has no local flags; watch-eligible.

#### `docket issue file add/remove/list` — `issue_file.go`

`add <id> <file-path>...` and `remove <id> <file-path>...` take
`cobra.MinimumNArgs(2)` — no flags. `list <id>` takes `cobra.ExactArgs(1)` —
no flags.

#### `docket issue link add/remove/list` — `issue_link.go`

`add <id> <relation> <target_id>` and `remove <id> <relation> <target_id>`
take `cobra.ExactArgs(3)` — no flags. `list <id>` — no flags.

#### `docket issue label add/rm/list/delete` — `issue_label.go`

| Command | Flag | Short | Type | Default |
|---|---|---|---|---|
| `add <id> <label>...` | `--color` | — | string | `""` |
| `rm <id> <label>...` | — | — | — | no flags |
| `list` | — | — | — | no flags |
| `delete <label>` | `--force` | `-f` | bool | `false` |

#### `docket issue graph [id]` — `issue_graph.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--depth` | — | int | `0` | `0` = unlimited |
| `--direction` | — | string | `"both"` | `up`\|`down`\|`both` |
| `--mermaid` | — | bool | `false` | Mermaid flowchart output (ignored in `--json`) |

Watch-eligible.

### `docket plan` — `plan.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--root` | — | string | `""` | scope to a parent issue subtree |
| `--status` | `-s` | stringSlice | `nil` | repeatable |
| `--label` | `-l` | stringSlice | `nil` | repeatable |
| `--priority` | `-p` | stringSlice | `nil` | repeatable |
| `--type` | `-T` | stringSlice | `nil` | repeatable |
| `--assignee` | `-a` | string | `""` | |

Watch-eligible. Cycle in the dependency graph → `CONFLICT`. `--json` output
additionally includes per-issue `blocked_by` (array of formatted blocker IDs,
`[]` if none), per-phase `level` (1-based topological-level index —
sub-phases produced by splitting one topo-level across file collisions share
the same `level`), and top-level `total_levels` (count of distinct levels).
Human/plain rendering distinguishes a same-level file-collision split
("Phase N (same dependency level as Phase N-1, split by file collision):")
from a genuine new dependency level ("Phase N (parallel, after Phase N-1):").

### `docket next` — `next.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--status` | `-s` | stringSlice | `nil` | default ready-set is `backlog`,`todo` if unset |
| `--priority` | `-p` | stringSlice | `nil` | repeatable |
| `--label` | `-l` | stringSlice | `nil` | repeatable |
| `--type` | `-T` | stringSlice | `nil` | repeatable |
| `--limit` | — | int | `10` | |
| `--run` | — | string | `""` | switches to STEP mode: lists a run's offer (ready steps + staged closure) |

Watch-eligible.

**Two modes.** Without `--run` this is the issue-mode verb, unchanged. With
`--run RUN-N` it lists that run's OFFER instead, in the `next row` shape
below: the claimable steps **plus their staged dependency closure** — rows
carried ahead of their own readiness (`status: staged`), leveled by `stage`,
so a dispatcher sees whole dependency chains rather than one frontier at a
time. The offer **rations class headroom**: a class with a finite `[limits]
max` contributes at most that many rows, so fewer same-class rows than ready
steps is the offer working, not a bug. The issue filters (`--status`,
`--priority`, `--label`, `--type`) are
**refused** in step mode with `VALIDATION_ERROR` rather than silently ignored —
a filter that quietly does nothing is one a dispatcher would trust and be wrong
about.

Step mode may WRITE: it reaps expired step leases, returning them to the ready
pool, and it auto-abandons a dispatch manifest that has outlived its TTL. Lease
reaping happens here and at `step claim` and nowhere else; the dispatch
auto-abandon happens here alone (`claim` never retires a manifest — a dispatch
is about a *batch*, and letting a single-step verb expire one would let a claim
silently unwedge a run whose relay is still alive).

**Step mode REFUSES rather than returning an empty list.** An empty ready set
means "nothing to do"; a refusal means "I will not answer until you reconcile",
and a dispatcher cannot tell those apart from a zero-length array. Each refusal
is `CONFLICT` (exit 4):

| Refusal | When | The way out |
|---|---|---|
| open dispatch | a manifest is open for the run and has not expired | `docket dispatch close`, `docket dispatch abandon`, or wait for `dispatch.ttl` — the message names all three plus the dispatch and its expiry |
| `claimed-but-unrecorded` | a step is `claimed`/`running` and has been silent longer than `dispatch.grace` | **lease expiry clears it**: the lease lapses, the next `next` reaps the step, and the discrepancy dissolves. The message names the expiry time |
| `usage-rows-missing` | a step finished after the run was activated with no recorded usage, **in a run that has ever opened a dispatch** | record the usage with `docket dispatch backfill-usage` (or `step complete --usage` at the time), or `docket dispatch close --accept-missing-usage`, which records the acceptance but does **not** clear the discrepancy |

The reap runs *before* the refusal is evaluated, so a step this invocation frees
is never reported as a discrepancy naming a resolution that has already
happened.

**Discrepancies are a property of the run, not of a manifest** — a relay that
never opened a dispatch can still leave a claimed step unrecorded. But
`usage-rows-missing` applies only to runs with dispatch history: a run no relay
ever drove has nobody owing usage, so a solo operator who completes steps
without `--usage` is never refused.

Issue mode (`docket next` with no `--run`) probes none of this and is
byte-identical to what it was before dispatches existed.

`next --run` also names any unacknowledged write-class reaps on **stderr**, with
the flag that clears them — a headroom denial with nothing running is otherwise
baffling. The JSON payload is unchanged by it.

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
| `attempt` | claims made against this step, ever |
| `expected_cost` | declared cost; accrues to the run's budget floor when this step is claimed |
| `lease_ttl_s` | lease TTL in **seconds** |
| `stage` | start-order constraint **within this offer**: do not start a row until every lower-stage row in the set has completed; rows sharing a stage run concurrently. `0` (omitted) means unstaged. NOT a priority — for `ready` rows it is a hint, for `staged` rows `claim` itself enforces the predicate |
| `conditional` | `true` on a staged row sitting (transitively) behind a HOLD-CAPABLE in-offer predecessor — an `aggregate` declaring `hold_spread`, whose completion may hold for an operator instead of routing. Advisory, like `stage`: confirm the predecessor actually ROUTED before spawning such a row, or defer it to the next offer — spawning at the stage boundary risks paying a full boot for a claim refusal. Omitted when false |
| `status` | effective status, never stored — `ready`, or `staged` on a closure row offered ahead of its readiness (claimable only once its lower-stage predecessors record) |
| `metadata` | the definition's opaque KV, verbatim |

### `docket workflow` (alias `wf`) — `workflow.go`

#### `docket workflow register <file.toml>` — `workflow_register.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--json` | — | string | `""` | inherited; `v1` or `v2` |

Positional argument is required; `-` reads the definition from stdin. Parses,
validates, and lints, then inserts at `name@version`. Identical bytes at an
existing `name@version` are an idempotent success returning the existing row;
differing bytes are `CONFLICT` (exit 4) naming both hashes.

#### `docket workflow lint <file.toml>` — `workflow_lint.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--json` | — | string | `""` | inherited; `v1` or `v2` |

Positional argument is required; `-` reads the definition from stdin. Runs the
exact validation `register` runs and **writes nothing** — no row, no frozen
`name@version`. The answer is `{name, version, sha256, registration}` with
`registration` ∈ `new` \| `unchanged`; different bytes at an existing
`name@version` is `CONFLICT` (exit 4) naming both hashes and the version to bump
to, which **fails** the lint rather than reporting a third `registration` value.

#### `docket workflow deprecate <name>@<version>` — `workflow_deprecate.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--restore` | — | bool | `false` | return a retired version to binding |

Retires one registered version from binding without deleting it; the row stays
readable and runs that pinned it are unaffected. The version is **required** —
a bare name is a `VALIDATION_ERROR` (exit 3), since it would silently mean
whichever version is highest today. An already-retired version is `CONFLICT`
(exit 4); an unregistered name or version is `NOT_FOUND` (exit 2).

#### `docket workflow list` (alias `ls`) — `workflow_list.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--name` | — | string | `""` | filter to one workflow name |
| `--limit` | — | int | `50` | `0` means no limit |

**Every** registered version of each name is listed, not only the binding one —
the query reduces nothing — so lineage is visible rather than inferred.

A `Collection`: under `--json=v2` the payload is `{items, total, truncated}`,
where `total` is the true pre-limit count. Items carry `row_version` (the CAS
column) under v2 only; `version` is always the definition's version.

v2 items also carry **`deprecated_at_ms`**, the moment a version was retired
from binding. It is **omitted while the version still binds** — a field that is
not a fact does not appear — so binding eligibility is readable from list output
instead of every registered version rendering alike. v1 does not carry it; human
mode marks the row `[deprecated]` instead.

#### `docket workflow show <name>[@<version>]` — `workflow_show.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--source` | — | bool | `false` | emit the stored TOML verbatim |

Omitting `@version` selects the highest registered version. A malformed ref
(`name@`, `name@x`, `name@0`) is a `VALIDATION_ERROR` (exit 3); an
unregistered name or version is `NOT_FOUND` (exit 2). `--source` returns the
exact registered bytes — the ones `source_sha256` hashes.

A retired version still resolves here, carrying `deprecated_at_ms` under
`--json=v2` (omitted while it binds) and a `status: DEPRECATED` line in human
mode. Retirement is a binding-time filter, not a retraction.

#### `docket workflow init` — `workflow_init.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--template` | — | string | `"standard-dev"` | `standard-dev` \| `parallel-check` |
| `--dir` | — | string | `""` | defaults to `.docket/config/workflows` |
| `--force` | — | bool | `false` | overwrite an existing file |

Needs no database, so it works before `docket init` does. Creates the
directory tree if absent. Refusing to overwrite is `CONFLICT` (exit 4) naming
the existing path; an unknown template is `VALIDATION_ERROR` (exit 3) listing
the available ones.

None of the `workflow` verbs are watch-eligible; `--watch` on any of them is a
`VALIDATION_ERROR`.

### `docket schema` — `schema.go`

#### `docket schema register <name@version> <file.json>` — `schema_register.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--json` | — | string | `""` | inherited; `v1` or `v2` |

Both positional arguments are required. `name@version` uses the same grammar a
step's `payload` field does, so what a workflow may reference and what the
registry accepts cannot drift. The document is compiled as JSON Schema **here**,
at registration — a schema that does not compile is refused while an author is
looking at it, not hours into a run. The `ordered_enum` index is derived once
and stored beside the bytes it came from. Identical bytes at an existing
`name@version` are an idempotent success returning the existing row; differing
bytes are `CONFLICT` (exit 4) naming both hashes.

#### `docket schema list` (alias `ls`) — `schema_list.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--name` | — | string | `""` | filter to one schema name |
| `--limit` | — | int | `50` | `0` means no limit |

A `Collection`: under `--json=v2` the payload is `{items, total, truncated}`,
where `total` is the true pre-limit count. Each row carries `name`, `version`,
`source_sha256`, `ordered_fields`, `builtin`, and `created_at_ms`; `row_version`
appears under v2 only.

#### `docket schema show <name>[@<version>]` — `schema_show.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--body` | — | bool | `false` | emit the stored schema document verbatim |

Omitting `@version` selects the highest registered version. An unregistered name
or version is `NOT_FOUND` (exit 2). `--body` returns the exact registered
bytes — the ones `source_sha256` hashes and the ones a run validates payloads
against, so `docket schema show risk-report@1 --body > risk-report.json` round-trips.

None of the `schema` verbs are watch-eligible; `--watch` on any of them is a
`VALIDATION_ERROR`.

### `docket run` — `run.go`

A run binds registered workflows to issues and schedules their steps. Runs
follow `planning → active ⇄ waiting-human → done | abandoned`; run IDs are
formatted `RUN-<n>` and, like issue IDs, accept the bare number too.

#### `docket run start` — `run_start.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--issue` | — | stringSlice | `nil` | issue to attach (repeatable) |
| `--request-file` | — | string | `""` | file holding the run's request text |
| `--budget` | — | float64 | `0` | per-run cap, **enforced**, in the unit `budget.unit` names (see `docket run budget --help`); `0` means unlimited |

Creates a run in `planning`: nothing is bound, nothing is pinned, and no step
exists until `run activate`. The run records the resolved **exec root** and
the git branch/HEAD at start — what diff recording and the activation routing
lint later resolve against, pinned here so the answer never depends on where a
later invocation happened to stand. A malformed or absent `--issue` refuses
**before** the run is created, so a typo leaves no empty run behind. A
negative `--budget` is `VALIDATION_ERROR` (exit 3); a missing `--request-file`
is `NOT_FOUND` (exit 2).

The issue set is **not fixed here** — `docket run issue add|remove` edits it
afterwards (see below).

**The cap is enforced against `max(reported usage, declared-cost floor)`.** The
floor is the sum of `expected_cost` over the run's claimed steps, accrued per
claim from facts the engine produced itself — so a worker that reports nothing
cannot spend past the cap. Reported usage can only **raise** the counter.

A claim that would **cross** the cap is refused with `CONFLICT` (exit 4) and the
run flips to `waiting-human` with a reason of the shape
`budget: spend N of cap M reached at <instance>`. A claim that lands *exactly* on
the cap is allowed: a budget reached is spent, not exceeded.

Omitting `--budget` takes `docket config budget.default`, resolved **at
`run start`** and stored on the run. A default set afterwards does not re-cap a
run already started — the same pinning property a workflow version has.
`docket run report` prints the effective cap and where it came from, so "why
didn't it stop?" is answered by a read verb.

**A breached run is un-wedged with `docket run budget RUN-N --set N`** (DKT-29).
`run resume` alone clears nothing — the cap has not moved, so the next claim
breaches again — which is why raising the cap and resuming are two commands:

```bash
docket run budget RUN-3 --set 50 --reason "estimate was low"
docket run resume RUN-3
```

#### `docket run issue add|remove RUN-N DKT-N...` — `run_issue.go`

Edits a run's issue set after `run start`. Both take a run and **one or more**
issues, and take no flags beyond the global ones.

```bash
docket run issue add RUN-3 DKT-11 DKT-12 --json
docket run issue remove RUN-3 DKT-12 --json
```

| Verb | Legal while the run is… | Refused when… |
|---|---|---|
| `add` | `planning` **or** `active` | the run is parked or terminal — `CONFLICT` (exit 4) |
| `remove` | `planning` only | the run has been activated at all — `CONFLICT` (exit 4) |

**`add` on an ACTIVE run is legal**, and the new issues are bound and
snapshotted by the **next** `docket run activate` (RA3) — they join as their
dependencies allow, exactly as a later phase does. The success message says so.
A parked run is a person's decision in progress and a terminal run's issue set
is history, so neither admits an add.

**`remove` stops at activation** because an activated issue is bound,
snapshotted, and possibly scheduled: removing it would strand steps that already
exist. Abandon the run instead if its shape is wrong.

**The whole set is validated before anything is written.** `add` checks every
issue exists first, so a typo'd second ID cannot leave a half-applied add
behind; `remove` checks every issue is actually attached first, so
`remove DKT-1 TYPO` cannot detach `DKT-1` and then refuse. An issue that does
not exist, or is not attached to this run, is `NOT_FOUND` (exit 2); a missing
run is `NOT_FOUND`; a malformed ID is `VALIDATION_ERROR` (exit 3).

Both answer with the set **after** the change — `{run, status, issues}` — so a
caller sees what the run now holds rather than re-deriving it from what it
asked for.

#### `docket run report RUN-N` — `run_report.go`

Takes no flags beyond the global ones. **READ-ONLY**: it computes effective
status and writes nothing — not even the lease reap `next` performs — so polling
it cannot advance a run. It works on a run in **any** status: `planning` reports
zeros, `abandoned` reports the trail up to abandonment.

| Section | Contents |
|---|---|
| `run` | id, status, reason, request, wall clock (activation → now, or → the terminal transition) |
| `budget` | effective `cap` and its `cap_source` (`run` \| `config` \| `unlimited`), the `floor`, `reported` per unit, the `budget_unit` the cap counts, `spend` = max(reported, floor), `burn_rate` (floor per wall-clock hour), and `breach_reason` when a budget paused the run |
| `steps` | count by **effective** status, plus per-step `attempts`, each row carrying `routing` (how the step ended, with its reason) and — for a vote step — `vote` (its proposal and how it tallied) |
| `gates` | per-gate pass/fail/unmatched/**skipped** counts, a **stub** count, and the per-step trail |
| `actions` | the same rollup over action results, `builtin` included |
| `artifacts` | the **index**: id, kind, producer instance, producer `executor` and `issue`, sha256, bytes — never the bodies |
| `metadata` | step `metadata` keys → distinct values with counts, verbatim and uninterpreted — over the **merged** bag, so both what a definition declared and what a worker reported via `step complete --metadata` are counted |
| `actors` | per-actor event counts (`next` / `gate` / `threshold` / `human`) — the attribution rollup described under `docket events` below, computed over the events that remain |
| `vote_metadata` | the same key → distinct-value rollup over vote seats' `--metadata` bags |
| `vote_usage` | per-unit sums of vote seats' `--usage` reports (DKT-95), beside the step ledger's `reported` — never merged with it |
| `vote_usage_coverage` | `{casts, reported}` — how many seat-casts reported spend at all (DKT-257). **Never omitted**, so "panels ran and said nothing" is distinguishable from "no panels ran" |

**A status alone does not say what happened** (DKT-258), which is why every
step row carries its `routing` and the human report prints a *How steps ended*
section. One word covers outcomes that need opposite responses:

| Status | Covers |
|---|---|
| `skipped` | a tribunal that **never convened**, and one whose panel deliberated and was then resolved by an operator |
| `failed-routed` | a step that was **measured and failed**, and one **cascade-terminated** by an issue-abandon without ever being claimed |

The engine records the difference in each step's `routing` — an abandon cascade
now writes `abandon-issue: cascade: DKT-N was abandoned by <step>; this step was
never measured`, where before it wrote only the status and left a cascade-
terminated step byte-identical to a real failure.

A vote step's `attempts` is permanently `0` — it is never claimed — so the count
that tells every other row apart from one that did nothing says nothing here.
`vote` carries the proposal and its status beside the routing, so a tribunal
that convened, tallied, and was *then* disposed of by an operator reads as both
facts rather than as a bare `skipped`.

**Trail and index rows are attributable.** A gate or action trail row is
`{step, step_id, issue, name, ordinal, verdict, reason?, output?}` — the
instance label alone was not enough, because instance names **collide across
issues in one run** (two issues on the same workflow both have an
`implement@0`), so a trail keyed on the label was unattributable. Join on
`step_id`; read `issue` to tell the two apart.

`output` rides on **non-pass rows only**, as the last 2000 bytes of the capture
prefixed with `…` when it was longer. A passing check's chatter is noise every
reader pays for, while a failing gate's diagnosis otherwise meant re-running it
out-of-band — most expensive exactly where a false failure blocks a security
path. The full capture stays on the result row itself; the report's job is
diagnosis, not archival.

The artifact index carries the producer's `executor` and `issue` for the same
reason. `producer` alone is a fanout ordinal (`review@0#2`), which says *where*
in the topology an artifact came from and nothing about *who* — and the opaque
executor hint is the axis a question about judge behavior actually groups by.
Both are omitted when the row has none.

**The budget numbers are bare.** There is no currency and no unit: what they
count is the workflow's business. The report publishes the numbers a warn policy
needs — cap, floor, reported-per-unit, burn rate — so an instance computes its
own warn threshold from a read verb. Core ships the cap and no warn.

**Reported usage is summed per unit and never across units.** Two units are two
numbers; docket has no opinion about whether they add up. Only the unit
`budget.unit` names participates in the cap comparison; the rest are recorded and
reported.

The document is **deterministic** given the same rows — every section orders by a
total key — apart from the wall clock and the burn rate derived from it, which
measure elapsed time.

#### `docket run activate RUN-N` — `run_activate.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--pin` | — | stringSlice | `nil` | file to pin by content hash (repeatable) |
| `--dry-run` | — | bool | `false` | compute the activation, print what it would bind and invoke, **write nothing** |
| `--reason` | — | string | `""` | why; recorded on the `run-activated` event |

One transaction, all or nothing:

0. **Auto-register** the contents of `.docket/config/` (see below).
1. **Bind** each issue to **exactly one** registered workflow by its `[match]`
   clause (`kind`, `labels_any`, `labels_all`, `unless_labels`, the last
   evaluated last and winning). Matching considers only the **highest
   registered version of each name**, the same version `workflow show NAME`
   resolves to, so exactly-one-match applies across *names*: bumping a
   workflow's version never makes the next activation ambiguous. Zero matches
   or several is `VALIDATION_ERROR` naming the issue **and** every candidate
   (the bindable ones — superseded versions are never listed).
2. **Lint** the work graph for dependency cycles.
3. **Pin** each bound workflow at its registered `source_sha256`, plus every
   `--pin` file at its own. Pinning is never partial: one unreadable path
   refuses the whole activation and writes nothing.
4. **Snapshot** each issue's body, title, kind, labels, and scope. Steps read
   the snapshot, never the live issue.
5. **Harvest** fenced command blocks whose tag a bound workflow's gates declare
   as `source = "fence:<tag>"`, verbatim and hashed. Blocks with an undeclared
   tag are **not** harvested.
6. **Expand** the first phase's steps — those whose issues have no unsatisfied
   `depends_on`. Later phases expand as their predecessors complete.
7. **Promote** the issues `backlog → todo`, and the run to `active`.

**Nothing executes.** No gate, no action, and no command runs during
activation; files are read only to hash them.

**Auto-registration — you never run a register verb.** Activation registers the
current contents of `.docket/config/`, so a definition goes from "written" to
"registered" by starting a run:

| Directory | What activation does |
|---|---|
| `config/schemas/*.json` | **registers** as a payload schema, named for the file (`findings@1.json` → `findings@1`) |
| `config/workflows/*.toml` | **registers** as a workflow definition, named by its own `[pipeline]` block |
| everything else under `config/` | **pins** by content hash and registers nothing — contracts, fragments, templates, `policy.toml` |

**Schemas register in full before workflows**, so a workflow naming a schema in
the same tree always registers second and its `payload` reference resolves.
Within each group the order is lexical, for determinism. Registry directories are
scanned flat; the pinned ones are scanned recursively. A file whose extension
does not match — a `README.md` in `workflows/` — is skipped in the registry and
pinned like any other file, so documentation never blocks a run.

Registration reuses the ordinary register path: same validation, same
immutability. **Changed bytes at an unchanged `name@version` is `CONFLICT`
(exit 4) and refuses the whole activation**, naming the file, both hashes, and
the literal edit to make:

```
.docket/config/workflows/standard-dev.toml has changed since it was
registered as standard-dev@1.

  registered  sha256:3f9a…   current  sha256:c41b…

A registered name@version is frozen so that a run which pinned it can
reproduce. To adopt these changes, bump the definition's version to 2,
then activate again. Runs already pinned to standard-dev@1 are unaffected.
```

Docket never auto-bumps a version, never overwrites a registered one, and never
silently uses the old bytes. Identical bytes re-register freely and change
nothing.

**A re-activation does not re-scan.** It inherits its pin set, so a config file
edited while a run is under way is invisible to that run and cannot trigger the
refusal above on a run that was working fine.

**A repo with no `.docket/config/` is untouched by any of this**: the directory
is checked once, and an absent one skips the scan entirely.

**The registration report.** Activation prints one line per registered file —
`name@version  path  (new | unchanged)`, schemas first — followed by a count of
what it pinned. Under `--json` the same data rides in a `registered` array of
`{kind, name, version, path, sha256, outcome}`. An activation that registered
nothing prints no block and carries no `registered` key.

**The trust report.** After the transaction commits, activation prints every
harvested fenced command verbatim, annotated `matched` (naming the trust entry)
or `unmatched` (with the reason) — so you see which commands a run will
actually invoke *before* it runs, not after. Under `--json` the same data rides
in a `fences` array of `{issue, gate, tag, ordinal, command, matched, entry,
reason}`.

It is a **report, not a gate**: activation succeeds with unmatched commands.
They simply will not run, and their gates route per `on_fail` when reached —
refusing would let anyone who can file an issue block a run by adding an
untrusted line.

Commands print with control characters escaped (see security.md §8.2); the
`--json` form carries the raw bytes. `--dry-run` prints the same report and
discards the whole transaction, so you can inspect what a run would bind
without committing to it.

**The gate preflight.** The trust report answers "will this command run" for a
*harvested* command. Activation asks the same question of every gate the bound
workflows **declare** (DKT-255) and warns with the list of gates that resolve to
no trust entry here, naming the workflows that declared each one. It prints
**nothing** when every gate resolves — an activation already prints four blocks,
and a fifth saying "all 6 gates are fine" on every run is how the one that is
*not* fine stops being read.

The gap it closes: all 34 gate-unmatched events of one epoch were
missing-entry cases — not moved repos, not argv drift, not prefix mismatches —
and every one was knowable before the run started. Nine of them across a single
day's fleet, each either pausing a run 2–7 minutes while an operator added the
entry, or silently skipping the AC commands the workflow declared.

It is a **warning, not a block**, for the fence report's reason: some gates are
legitimately absent on some machines, and activation is not the place to make
that a hard stop. An unmatched gate still records `unmatched` and routes per its
step's `on_fail`.

A gate whose entry is a **stub** (`trust add --stub`) is listed separately as a
note: it resolves and will run, but it will measure nothing, and that is a fact
about the run's assurance worth seeing beside the roster you are approving.

Fence gates are excluded — their commands are the trust report's subject, and a
named gate has no argv here to resolve. Under `--json` the data rides in a
`gate_preflight` array of `{gate, workflows, matched, entry, stub, reason}`,
`omitempty`.

**The hold policy.** A hold is the one step in a run no author declared — the
engine mints it when a `hold_spread` trips — so who *answers* it is not visible
anywhere a workflow author or an operator normally looks. Activation now says
(DKT-266): with **both** `vote.hold.rule` and `vote.hold.voters` set, holds go
to a panel and the line names it; with **neither** set, one operator decides and
nothing prints; with **one** set, holds go to one operator and activation warns,
because that is the state an operator who configured half of it would least
expect and least easily notice. Under `--json` it rides in `hold_policy` as
`{rule, voters, panel}` — `panel` is never omitted, since "one operator decides"
must be distinguishable from a docket too old to report it.

**The scope lint.** Activation warns about every issue that declared **no
scope at all** while binding a workflow that holds the tree — such an issue's
holding step occupies the tree without excluding, or being excluded by, any
other issue, so the scheduler can offer it beside work it collides with. The
warnings ride in `scope_warnings` under `--json` (a `{issue, workflow, reason}`
array, `omitempty`, so a fully-scoped run carries no key — `issue` is the
display id, e.g. `"DKT-87"`, never the internal numeric PK) and print on
**stderr** in human mode, naming the remedy —
`docket issue edit DKT-N --scope GLOB`, since scope is set on the *issue*, not
in the workflow named beside it.

It is a warning, never a refusal. A **declared-but-empty** scope does not warn:
that is a decision somebody made on purpose, and warning about it is how a
warning becomes noise. The lint reads the **live** issue rather than the
snapshot, so an operator who sets a scope after a first activation has fixed
the omission by the next one. "Holds the tree" means `holds_tree` and nothing
else — never a class name, which core attaches no meaning to.

**The routing lint (DKT-33).** A second warning, in the same `scope_warnings`
array, fires per issue whose declared scope resolves **nothing** under the
run's recorded exec root — the signature of an issue planned into the wrong
repository, which otherwise surfaces only after a full wave (an executor
booted into a worktree that cannot contain the fix, a gap filed, the review
fanout dispatched over the empty result). The test is **anchored existence,
not file existence**: each entry's literal prefix (up to the first glob
metacharacter) must exist under the root, or its parent directory must; one
anchored entry clears the issue. A scope may name files the work will CREATE,
so the lint deliberately under-reports rather than flagging greenfield
new-file scopes. A run with no recorded exec root skips it entirely. The
message names the root it resolved against and the way out —
`docket issue move --project`, or fix the scope.

Re-activating an `active` run expands newly-unblocked phases only and
**inherits** the original pin set — a workflow re-registered or a pinned file
edited since activation does not reach a run already under way. Its success line
says so: `(re-activation: original pin set inherited, nothing re-registered)`,
because counts alone read as fresh binding-and-pinning work, which is exactly
how a no-op against a stale picture gets mistaken for a real activation.

Refusals: unbindable issue / work-graph cycle / run with no issues / context
over `context.error_bytes` → `VALIDATION_ERROR` (3); missing run or `--pin`
path → `NOT_FOUND` (2); terminal run, `waiting-human` run, or open dispatch →
`CONFLICT` (4).

Two of those `CONFLICT`s say more than that they happened:

- A **terminal** run's refusal carries the run's **recorded reason** — an
  operator whose picture of the run is stale learns from one message not only
  that the run ended but why, instead of going to read the row.
- A **`waiting-human`** run is refused with `resume it with docket run resume
  RUN-N before re-activating`. Flipping it back to `active` here would take a
  person's decision as a side effect, and worse: only `active` runs count as
  re-activations, so this path would treat it as a *first* activation and
  re-scan config.

#### `docket run pause|resume|abandon RUN-N` — `run_lifecycle.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--reason` | — | string | `""` | required on `abandon` (with or without `--issue`) |
| `--issue` | — | string | `""` | (`abandon` only) abandon only this issue's remaining steps; the run and its other issues continue |

`pause` moves `active → waiting-human`; `resume` moves it back; `abandon` is
terminal from any non-terminal status. A paused run blocks new claims and
honors in-flight completes.

**Abandonment NAMES the run's recorded worktrees (DKT-116).** A relay's
close-time sweep only covers worktrees its own session created, and an
abandoned run never reaches a close — so abandonment was the exit that
stranded checkouts and `worktree-wf_*` branches with nothing reporting them.
`run abandon` collects the distinct `steps.work_root` values the run's steps
declared at record time and names them in the success message, in the
`run-abandoned` event's `data.worktrees`, and (under `--json=v2` only) as a
`worktrees` key beside the run — the v1 payload is unchanged. `abandon
--issue` does the same for the stopped issue's steps, in the
`issue-abandoned` event and the v2 outcome. Docket **names and never
removes**: the checkouts are the operator's tree, and a
recorded-but-never-integrated sha may still be worth recovering from one. A
worktree a relay created for a step that never recorded is a fact docket was
never told, and stays the relay's to sweep.

**`abandon --issue` is the per-issue disposition (DKT-28)** — for a mis-routed
or unimplementable issue that should not take the whole run down with it.
Every remaining (non-terminal) step of that issue moves to `failed-routed` —
the same terminus the `abandon-issue` routing produces — an `issue-abandoned`
event records `{issue, reason, steps}` (the stopped instances), and the
ordinary reconciliation rollup runs in the **same transaction**, so the run
continues, returns from a park, or completes if this was its last unfinished
work. The issue's **own status is not forced terminal** — triage stays the
operator's — but the issue's **`resolution` is set to `abandoned`** (schema
v18, DKT-245), and both `step resolve --as abandon-issue` and this verb record
it, since they are one fact about the issue with two actors. That is what
keeps an issue whose fix step had completed from going on rendering `✔ done`
for work a review reproduced as not fixing anything: `issue list` shows
`⊘ abandoned` in the status column, `issue show` prints the status and the
resolution side by side, and `issue show --json` carries a `resolution` key —
emitted **only when set**, so an unresolved issue's payload is unchanged.
`issue reopen` clears it, because an issue back on the board is one the
operator has taken off the machine's hands. Refusals: run not `active` or `waiting-human` → `CONFLICT`
(exit 4); issue not part of the run → `NOT_FOUND` (exit 2); every step already
terminal → `CONFLICT` (nothing to abandon); missing `--reason` →
`VALIDATION_ERROR` (exit 3).

An **illegal transition is refused** with `CONFLICT` (exit 4) rather than
silently applied — pausing an already-paused run must not report success, or a
harness believes it quiesced a run that never was active. `abandon` without
`--reason` is `VALIDATION_ERROR` (exit 3).

**Each of the three writes its event in the same transaction as the status** —
`run-paused`, `run-resumed`, `run-abandoned`, with `data` carrying
`{from, to, reason}`. `from` is there because the interesting question about a
transition is what it left; `reason` because "abandoned" alone does not answer
what somebody will ask about a run that ended without completing. Before this,
abandonment wrote no event at all and a consumer reading only the feed saw a
paused run as the final state, unable to learn that the run had ended, when, or
why. There is no `run-done` here: no operator verb moves a run to `done` —
that is the reconciliation rollup's transition, and it logs itself.

#### `docket run budget RUN-N [--set N]` — `run_budget.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--set` | — | float | — | set the cap to this number; `0` means unlimited |
| `--reason` | — | string | `""` | why the cap is changing (recorded in the event) |
| `--if-version` | — | int | — | apply only at this `row_version`; `CONFLICT` (4) otherwise |

Without `--set` this **reads**: the cap, where it came from (`run` \| `config` \|
`unlimited`), the `floor`, the `reported` usage in the unit `budget.unit` names,
and the `spend` = `max(reported, floor)` that is actually enforced. Those are the
numbers an operator needs to choose a new cap, so choosing one does not require
reading a report first.

**There is a SECOND, INDEPENDENT cap over MEASURED usage** (DKT-238) — what the
ledger actually recorded, as opposed to the declared step costs the cap above
counts. Arm it with `run start --usage-budget N` (or `budget.usage.default`)
**and** `budget.usage.unit`; both are required, since a cap with no unit counts
nothing, and the read form says `DORMANT` when only one is set. `run budget`
and `run report` then carry `usage_budget` / `usage_unit` / `usage_spend`
beside the declared numbers.

The two are **never combined**. 280 declared units and 4.8M output tokens are
answers to different questions, and folding measured tokens into
`max(reported, floor)` would let the token count swamp the declared discipline
the instant it was armed — which is how a raise tribunal came to deliberate
over a proxy while the run's real spend ran to hundreds of millions of tokens.
They are also **checked differently**: a step's declared cost is known before
it runs, so the declared cap RESERVES (`spend + cost <= cap`); a step's token
spend is not knowable in advance, so the measured cap STOPS (`spend <= cap`) —
work continues while recorded usage is at or under the cap, and the first claim
after it is exceeded is refused. A breach on the measured cap names its unit
(`usage budget: measured output_tokens spend …`), so raising the wrong cap is
not a mistake you can make silently.

`--set` **raises or lowers** a live cap. Raising is the way out of a budget
breach:

```bash
docket run budget RUN-3                    # what stopped it, and at what
docket run budget RUN-3 --set 50 --reason "estimate was low"
docket run resume RUN-3                    # a separate, deliberate act
```

**It does not change the run's status.** A breached run is `waiting-human` and
stays so until `run resume` — `waiting-human` means a person decides when work
restarts, and a verb that un-parked as a side effect would take that decision
back. Nothing re-scans and nothing sweeps: the claim path reads the cap fresh
from the row, so the next claim after a resume simply proceeds.

Lowering below what a run has already spent takes effect the same way — the next
claim refuses. **Raising a cap cannot un-spend what was spent:** the floor is
computed from the run's claim events, so it does not move when the cap does. A
new cap below the existing floor refuses the very next claim.

**A cap change that resolves the breach clears the breach record.** When the run
carries a `breach_reason` and the new cap is unlimited (`0`) or at least the
current `spend`, `breach_reason` is cleared; if that breach is also what parked
the run, the run's `reason` is **rewritten** to name the cap change —
`budget: cap changed from N to M after breach (was: …); run resume to continue`.
The row states what is true *now*. Without this the stale
`budget: spend N of cap M reached at <instance>` survived a raise and read as a
still-walled run to anyone checking (see also `run report`'s `breach_reason`).

The change is **event-logged** as `run-budget-set` carrying `from` and `to`, so a
run whose cap moved has a trail saying so, and the clearing rides in **that same
event** as `breach_cleared` (the retired reason string) — so an auditor reads
"the cap moved *and* the breach record was retired" as one fact instead of
inferring the second from the row's silence. `row_version` is bumped whether or
not `--if-version` was passed. Refused on a terminal run (`CONFLICT`, exit 4): a
finished run's cap is a record of what it was allowed to spend, and that does not
move.

Clearing the record still does not change the run's **status** — a breached run
stays `waiting-human` until `run resume`, which remains a separate, deliberate
act.

#### `docket run status [RUN-N]` — `run_status.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--active` | — | bool | `false` | list only non-terminal runs (list form) |
| `--limit` | — | int | `50` | list form; `0` means no limit |

With an ID: the run, its issue count, its steps grouped by status, and its
pins. Without: a `Collection` of runs — under `--json=v2` the payload is
`{items, total, truncated}` with each item carrying `row_version`.

**Read-only.** This verb computes effective status and writes nothing.
`--active` keeps `planning` runs: a run that exists but has not been activated
is still live work. Passing `--active` with an ID is `VALIDATION_ERROR`, since
it filters a list.

None of the `run` verbs are watch-eligible.

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

#### `docket dispatch open`

| Flag | Type | Default | Notes |
|---|---|---|---|
| `--run` | string | — | **required** |
| `--limit` | int | `0` | maximum manifest rows; 0 is no limit. Slices *after* ordering, so a limited manifest holds the highest-priority steps |
| `--ack-reap` | int64Slice | `nil` | acknowledge a write-class reap by its `lease-reaped` event `seq`; repeatable |

Response is engine-spec §11.4's `dispatch` shape: `{dispatch, run, opened_seq,
expires_ms, rows: [<next row>…]}`. Each row is stored as its canonical JSON
bytes plus a sha256, so `verify` compares bytes rather than a re-serialization
that could differ in key order.

`open` performs the same lazy lease reap `next` does — offering a stale step
that a reap would have freed would make the manifest wrong the moment it was
written.

**A manifest short of the rows you can see are ready says why.** When R7
withholds steps for lack of budget headroom, the response carries
`budget_held` — `withheld: N step(s), reason=budget headroom X < cost:
<instance> (cost Y)…` — and the same line goes to stderr for a human; `next`
reports the identical fact on stderr (DKT-242). The field is **absent whenever
nothing was withheld**, the same dormancy the reap hold and the loop-body hold
keep, so an uncapped run's payload is unchanged. Without it, an offer of 1 of 5
ready judges — or an empty `next` against a run reporting 9 pending — is
indistinguishable from a graph that has run dry, which is the reading that
makes a dispatcher stop asking.

**Exactly one dispatch is open per run**, enforced by a partial unique index
rather than a check-then-insert: two relays racing produce one manifest and one
`CONFLICT`, never two manifests. The loser's computation is discarded, not
merged — a merge would produce a manifest neither relay saw.

#### `docket dispatch verify`

**This verb writes nothing, including no lease reap.** It is the one
scheduling-shaped verb that must not reap: reaping would change the very ready
set it was asked to compare against, and a verify that mutated its own subject
could never fail.

Equal is exit 0 with `{verified: true}`. Unequal is `CONFLICT` naming the
**first differing position**, with the stored row and the recomputed row both
rendered — so an operator can see whether a lease lapsed, a priority changed, or
a step completed, rather than being told the two differ.

**Every stored row gets a verdict, in one pass** (`rows` in the payload,
summarized above the refusal for a human): `matched`, `recorded` (the step
moved off the scheduler — the dispatch working, and not a failure),
`rendering-shifted` (still offerable, renders differently than at open), or
`genuinely-missing` (still non-terminal and yet no longer offerable — the
narrow, alarming case). The comparison used to stop at the first shifted row,
so a dispatch where several steps had moved mid-flight reported one and hid the
rest, costing a manual per-step confirm round before a `close` that reconciles
the same state without complaint (DKT-243). The exit code is unchanged: any row
that is not `matched` or `recorded` still fails the verb.

`stage` and `conditional` are **normalized before the comparison**: both are
set-relative, and both legitimately move as an in-offer predecessor records or
routes, so a row whose stage collapsed or whose conditional mark cleared is
not a discrepancy.

A step that has legitimately left the scheduler is **skipped**, not reported
(DKT-65). That set is terminal (`done`, `skipped`, `superseded`,
`failed-routed`) **plus `waiting-human`**: a step that recorded correctly and
then parked is absent from the recomputation by design, and calling that a
mismatch failed the verb on two measured runs for dispatches that were entirely
correct. The stored pair's own hash is checked **before** any of that, so a
drifted row can no longer bail out ahead of the tamper check — the previous
order meant genuine manifest tampering went undetected on exactly the rows most
likely to have been tampered with.

#### `docket dispatch close`

| Flag | Type | Default | Notes |
|---|---|---|---|
| `--run` | string | — | **required** |
| `--accept-missing-usage` | bool | `false` | close despite `usage-rows-missing`, recording the acceptance |

Refuses `CONFLICT` while any discrepancy exists, enumerating each with its
resolution (the table under `docket next` above). `--accept-missing-usage`
accepts **only** that class: `claimed-but-unrecorded` has its own resolution —
lease expiry — and a flag that accepted both would let a relay close over work
that is still running.

The acceptance is *recorded*, not merely permitted: `close_reason` becomes
`accepted-missing-usage` and the accepted step list rides in the
`dispatch-closed` event's `data`.

**Acceptance closes the dispatch; it does not clear the discrepancy.** The
`usage-rows-missing` probe is computed from `steps.usage_recorded` and never
reads `close_reason`, so a later `next` recomputes the same refusal from the
same column — and each subsequent close re-accepts the whole set. To make the
discrepancy go away, record the usage: `docket dispatch backfill-usage`.

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

engine-core §7's back-fill: a relay that measured its own spawns carries those
numbers into the ledger, with the source recorded. Usage otherwise rides only
on `step complete --usage`, which a claimant that cannot observe its own
consumption has no way to supply.

Two forms, one per invocation — `--step/--unit/--quantity` pair positionally
(the Nth of each is one row), or `--from-json` for a whole batch. Passing both
is refused: one batch, one source of truth.

**The whole batch is one transaction.** A back-fill that half-applied would
leave a dispatch neither closable nor honestly re-runnable.

Rows land on the step's **recorded attempt**, and there is deliberately no flag
to name a different one — back-filling an arbitrary historical attempt is
rewriting history. The ledger's `(step, attempt, unit)` key means a retried
step's second attempt records *beside* its first, and a repeat of the same
triple is refused `CONFLICT` rather than merged.

**`--on-duplicate` decides how a repeat is handled.** `refuse` (the default)
aborts the whole batch, which is right when a duplicate means real spend is
about to be double-counted. `skip` passes that row over, records the rest, and
**names every row it skipped** — never a silent drop. Cross-wave duplicates are
structural (a gate probed in wave N and seated in wave N+1 emits usage in both
journals), and aborting the batch for them meant hand-filtering rows before
every re-run (DKT-241). A skipped row writes nothing, so the batch stays
all-or-nothing over the rows it actually records.

**To see what is already recorded, read `docket run report`'s `step_usage`** —
the ledger row by row, with each row's step, instance, attempt, unit, quantity,
and source. The budget section sums the same rows per unit; `step_usage` is the
detail behind that headline, and it is what the duplicate refusal points at.

`--source` is free text and is always written explicitly, so a relay's
reconstruction stays distinguishable from a claimant's own `reported` rows.
Core enumerates no sources, for the same reason it enumerates no units.

#### `docket dispatch abandon`

| Flag | Type | Default | Notes |
|---|---|---|---|
| `--run` | string | — | **required** |
| `--reason` | string | `""` | why; recorded in the `dispatch-abandoned` event |

**Unconditional, and that is the point.** This is the crashed-relay path: the
relay is gone and cannot resolve anything, so a recovery verb that refused to
recover while a discrepancy existed would be the mechanism by which a crashed
relay wedges a run.

Nothing is lost. Opening a manifest never claimed anything, so its steps return
to the ready set intact, and an executor that claimed one *before* the crash
finishes normally.

#### The write-reap acknowledgment

Reaping a lease in a class with a finite `[limits] max` **holds that class's
headroom** until somebody acknowledges the reap. The database lease is not a
tree fence: nothing about an expired lease stops a still-running process from
writing, so a successor must not start beside a writer that may still be alive.

Core cannot check a process it did not start, so it refuses to pretend
otherwise and asks for the one fact it cannot observe. The acknowledgment
**never requires the dead relay** — a new session, which may be a person typing,
confirms the tree is quiet and passes `--ack-reap <seq>`.

- The reaped step itself is re-offered; other steps in its class are not.
- Classes with **no** `[limits] max` get neither ack rows nor a hold. A repo
  with no `[limits]` never sees this mechanism at all.
- Acking a seq that is not a reap, or not this run's, is `VALIDATION_ERROR`.
  Acking the same seq twice is a success that changes nothing.
- `acked_by` records the **verb** (`dispatch-open`), never a user identity —
  core has no identity model.

`docket guard spawn --ack-reap` is the other entry point and lands with the
guard verbs.

### `docket events` — `events.go`

The engine's event log, as a cursor feed. Every transition an engine verb makes
writes an event in the same transaction that performs it, so the log is the run's
own account of itself rather than a summary written afterwards.

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
issues bound to the same workflow both have a `fix@1` — and a feed filtered by
label once misattributed a pass-route to a reaped step over exactly that
collision. The column was always stored; the wire now carries it.

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

**How a store-level event is scoped** (DKT-68). An event's project is its run's,
else its issue's, else **the repository its payload names** — `repo` for a trust
change, `identity` for a `project-registered`. A store-level event naming no
repository at all is a fact about the store and appears in every scoped view;
one naming a DIFFERENT repository belongs to that repository's trail, not to
this one's. The scoped feed used to admit every project-less row, which made a
`--tail 60` across eight concurrent sessions return 8 rows of local history and
52 trust rows from other repos — 87% noise, with the history the operator asked
for pushed off the top.

**Ids render under their OWNING project's prefix** (DKT-67), not the querying
project's. `--all-projects` used to render every issue id under the caller's
prefix, so the one view whose whole purpose is to span projects displayed six
siblings' issues as if they were the caller's own. Rows also carry `project` —
the owning project's name, omitted in a single-project feed and shown as a
column under `--all-projects`, since two projects can both hold a `fix@1` and a
`RUN-6` and the ids alone do not say whose.

**`at_ms` is monotonic with `seq`** (DKT-66). It was not: `gate-rerun` and
`gate-unmatched` carried a clock taken at the top of a long transaction — on the
resume path, the step's record time — so a `gate-unmatched` at seq 265 was
stamped 57 seconds before seq 264, and any consumer windowing on `at_ms`
mis-ordered gate history. Those kinds now stamp at emission, and the writer
clamps every event up to its predecessor's stamp, so the documented
oldest-first-arrival reading holds for `at_ms` as well as for `seq`.

**Gate events carry their verdict** (DKT-63): `detail=<gate> verdict=<v>
exit=<n>`. A failing gate used to render character-identical to a passing one,
and a conductor reading the feed reported three failed gates as passes. An
unmatched gate carries no `exit` at all — it never ran, and `exit=0` would read
as a pass.

**`--follow` polls.** There is no daemon and no subscription: the flag runs the
same query on a ticker, printing only what is new each cycle, and the process is
idle in between. The cursor advances to the last `seq` actually returned, so an
event written *while* a cycle was reading arrives on the next one — the same
no-skip-no-repeat property the one-shot form has, extended across cycles.

Output is append-only: the screen is never cleared and no page is reprinted, so
a follow can be piped, grepped, and read afterwards. Ctrl-C ends it and exits 0
— interrupting a follow is how a follow ends.

A follow whose cursor falls below the retained minimum — someone pruned under it
— **stops** with `GONE` rather than resuming at the new minimum. Resuming would
hand the consumer a feed with a hole in it and no indication there was one.

#### `docket events prune`

| Flag | Type | Default | Notes |
|---|---|---|---|
| `--before` | int64 | `0` | delete events with `seq` **strictly less** than this |
| `--before-run` | string | `""` | delete every event of this run (`RUN-N`) |
| `--run` | string | `""` | narrow `--before` to one run |
| `--dry-run` | bool | `false` | report what would be deleted and delete nothing |
| `--yes` | bool | `false` | confirm the deletion; **required** unless `--dry-run` |

Exactly one of `--before` / `--before-run` is required: a destructive verb with a
default target is how a log gets deleted by a typo.

**It refuses more than it accepts.** Two refusals, and neither is negotiable:

- **Events of runs that have not reached `done` or `abandoned`** are never
  deleted (`CONFLICT`, exit 4, naming the runs). A live run's events are what the
  engine *computes from* — its budget floor is summed from its `step-claimed`
  events, and its saga resumes from its `gate-started` events — so pruning them
  would change the run rather than only its record.
- **Events younger than `docket config events.retain`** are held back. That
  window defaults to `0`, which retains **everything**: prune deletes nothing at
  all until an operator states a retention policy. When the window holds rows
  back, the answer says how many, rather than returning a smaller number with no
  explanation.

Events belonging to no run — trust grants — are prunable by `--before`, since
there is no run whose liveness could forbid it.

**It deletes rows in `events` and nothing else.** No artifact, no step, no run,
no usage row, no dispatch row. It does not `VACUUM`: reclaiming file space is a
decision made against a backup, not a side effect of trimming a log.

The prune **records itself** as an `events-pruned` event whose `seq` is above
everything it removed — so the record of the deletion survives the deletion, and
a consumer that hits `GONE` and resumes at the new minimum reads the explanation
for its own gap as the first thing it sees.

The answer is `{pruned, retained_minimum, held_by_retention?, dry_run?}`. The
retained minimum is there so a consumer can reset its cursor without a second
call — the call that invalidated the cursor is this one.

Pruning costs the audit trail `docket run report` computes over: a trimmed run
reports fewer transitions than it actually made. Trim whole runs that have
finished rather than the oldest N events across all of them, and the report stays
honest for every run it still covers.

Human mode renders one line per event and escapes stored strings on the way to
the terminal; `--json` carries the raw bytes, because the consumer there is a
program. Under `--json=v2` the result is the usual `{items, total, truncated}`
collection, where `total` counts matching events **before** the limit sliced
them.

**It writes nothing.** Reading the log cannot advance a run.

#### Attribution — who caused each transition

Every event kind maps to exactly one of four actors, and `docket run report`
publishes the per-actor counts:

| Actor | Meaning | Kinds |
|---|---|---|
| `next` | the scheduler | `step-ready`, `lease-reaped`, `join-completed`, `loop-entered`, `dispatch-abandoned`, `issue-promoted` |
| `gate` | a deterministic check, actions included | `gate-started`, `gate-recorded`, `gate-unmatched`, `gate-rerun`, `vote-opened`, `vote-tallied` |
| `threshold` | computed routing | `step-routed`, `step-failed`, `step-superseded`, `step-skipped`, `step-held` |
| `human` | an operator verb, including one a harness relays | `run-*` (`run-started`, `run-activated`, `run-paused`, `run-resumed`, `run-abandoned`, `run-done`, `run-budget-set`), `step-claimed`, `step-heartbeat`, `step-recorded`, `step-resolved`, `step-approved`, `step-rejected`, `step-annotated`, `issue-abandoned`, `trust-*`, `project-registered`, `dispatch-opened`, `dispatch-closed`, `reap-acknowledged`, `events-pruned` |

The three operator lifecycle kinds each carry `data` of `{from, to, reason}`,
written in the same transaction as the status they record. `lease-reaped` is
attributed to `next` whether the lease expired or `docket step reap` forced it;
`data.forced` plus the operator's `reason` is what separates the two.

Four rows are worth their sentence. **`run-done` is `human`** even though no
operator verb moves a run to `done`: the reconciliation rollup writes it, but
the rollup runs inside whatever operator-actor verb completed the run's last
work, and the table maps kinds, not code paths.
**`step-claimed` is `human`, not `next`**:
the scheduler *offers*, and something else *takes* — calling the claim a
scheduling decision would hide exactly the boundary this table exists to expose.
**`run-paused` is `human` even when a budget breach causes it**, because the
transition means "a person must now decide"; `data.reason` distinguishes a
budget breach from an operator's `run pause`. **`events-pruned` is `human`**
because nothing in the engine prunes — there is no sweep, no compaction, and no
automatic retention — so the event exists only because somebody ran the verb.

Note what the last row implies about the audit itself: attribution is computed
over the events that *remain*, so a pruned run reports fewer transitions than it
made. `events-pruned` is what keeps that honest — a trimmed log says it was
trimmed rather than looking like a quieter run.

### `docket step` — `step.go`

Steps are the units of work a run schedules. A step is **claimed** — which
mints a capability token and returns the whole context bundle in one response —
then **completed** with an artifact.

| Verb | Token | Effect |
|---|---|---|
| `step claim STEP-N [--render] [--template F]` | no | CAS claim; mints token; returns token + context (or packet) |
| `step heartbeat STEP-N` | **yes** | extends the lease; does not touch `attempt` |
| `step reap STEP-N --reason R` | no | forced reap of a dead holder's claim, without waiting out the lease |
| `step complete STEP-N --artifact-file F …` | **yes** (stages 0–1) | the saga |
| `step fail STEP-N [--note …] [--metadata …]` | **yes** | routes per `on_fail` when the CLAIM count reaches `max_attempts` (E-8: attempt counts claims, never failures) |
| `step annotate STEP-N --metadata JSON` | no | merges opaque KV onto a **finished** step's record; event-logged |
| `step approve\|reject STEP-N [--note …] [--value V]` | no | `type="human"` gate steps, and a materialized held step of either kind (a vote-minted one once a failed tally parks it) |
| `step resolve STEP-N --as …` | no | `waiting-human` resolutions; `retry` **resets attempts** |
| `step show STEP-N` | no | read-only; effective status |
| `step list (--run RUN-N \| --issue ISSUE-N)` | no | read-only; steps with id, run, instance, issue, kind, effective status, attempt, expected_cost — in (issue, creation) order. Scope by `--run` (the whole run), `--issue` (that issue across every run holding a step for it), or both (that issue inside that run); at least one is required. The budget-projection enumeration (DKT-54): step ids are a store-wide sequence, so id arithmetic cannot enumerate a run. `--issue` is the issue-shaped question a conductor actually holds (DKT-244). Watch-eligible. |
| `step context STEP-N [--meta]` | no | re-emits `context` read-only |
| `step render STEP-N [--template F]` | no | context bundle → rendered work packet |
| `step artifacts STEP-N` | no | read-only; lists what the step PRODUCED, sizes not bodies |
| `step artifact ARTIFACT-N [--payload]` | no | read-only; one artifact in full |

#### `docket step artifacts` / `docket step artifact`

**How an action step's verdict is read.** An action's result and an
aggregate's held-cluster payload both live in the `artifacts` table, and
neither had a CLI surface before: `step show` renders the row, `step context`
renders a step's **inputs**, and the run report's artifact index gives sizes
and hashes but never a body. Reading a verdict meant opening
`.docket/issues.db` with `sqlite3` by hand.

`step artifacts STEP-N` lists — reference, kind, size, payload size, hash,
`supersedes` — and deliberately carries **no bodies**, since an artifact runs to
1MiB. `supersedes` names the artifact this one REVISES (DKT-70), and is absent
on an original. A held cluster's resolution records its own artifact rather than
annotating the original, deliberately — what the engine computed and what the
operator accepted are two records. The `sha256` is a content address over the
artifact's **body AND payload** (DKT-112): a supersession whose payload changed
never shares a hash with what it revises, and the resolution artifact's body is
**regenerated** from the resolved payload — it counts the still-held and
operator-resolved clusters as they now stand rather than repeating the stale
"held for an operator decision" line. (Body-only artifacts — gaps, diffs —
hash exactly as before.) **A rollup counting work should skip artifacts that
carry `supersedes`.** The run report's artifact index carries it too. A step that
produced nothing lists nothing and exits 0; a step that does not exist is
`NOT_FOUND`, so a typo never reads as "this step produced nothing".

`step render` emits a **`== RESOLUTION`** block when the step carries a routing
record — the routing that sent it back, and the note whoever decided it wrote
(DKT-247). A resolve/approve note used to be audit-trail only, so an operator
ruling issued BETWEEN rounds could not reach the retry it authorized, and
rulings were applied as out-of-band repo commits instead. It is **scoped to
the step's own row**: a note on another step never renders here, because
instance labels repeat across a run's issues and one instance's ruling in
another's packet is exactly the collision that makes possible. Absent on a
step with no routing record, so a first-round packet is unchanged.

**The resolution also names the gates that did not pass** — verdict and reason,
last attempt per gate (DKT-261). It rides in `context.resolution.gates` under
`--json`, so a relay composing a retry can tell an **environmental** failure
from a **capability** one without a second query.

That distinction is the hard part of any escalation ladder, and it is now
readable rather than guessed. `skipped` means nothing was measured — the tree
could not be bound — and such a step parks for an operator rather than routing
`on_fail`, so it never reaches a retry at all. `unmatched` means the command was
never trusted here. Only **`fail`** means a measurement was taken and the work
did not pass it.

**`escalate_to` is not docket's.** It lives in the relay's `policy.toml` and is
read by the relay; docket has no `escalate_to` and never picks a model or an
effort. Every one of one epoch's three genuine capability-suspect retries turned
out to be environmental, so a ladder keyed on "gates failed twice" would have
escalated three times and helped zero. Key it on `fail` — the verdict that
survives the other two now having their own — and read the reason before
spending a more expensive variant.

`step show` renders a **gate summary** when the step has recorded gate results
(DKT-63) — a verdict, the gate name, an exit code, and a pointer to
`step gates` when something did not pass. It used to print no gate section at
all, so the surface an operator reaches for to ask "why is this step parked" was
silent about the gates that parked it; a conductor read it and the event feed on
2026-08-16 and reported three failing gates as passes. It is a summary, not a
copy of `step gates`: that verb owns the reasons and the output tails.

`step artifact ARTIFACT-N` fetches one in full. `--payload` narrows to the
structured half and, under `--json`, emits it as **parsed JSON rather than a
string**, so `jq` reaches the verdict's own keys directly:

```
docket step artifact ARTIFACT-3 --payload --json=v2 | jq -r '.data[0].severity'
```

Both take the `ARTIFACT-N` form the listing and the run report's index print; a
bare `N` is accepted too. Both are **read-only and write nothing** — no reap,
no lease touch.

#### `docket step claim`

| Flag | Type | Default | Notes |
|---|---|---|---|
| `--owner` | string | — | **required**; identifies the lease holder |
| `--ttl` | duration | `0` | defaults to the step's configured TTL |
| `--render` | bool | `false` | return the rendered packet instead of the bundle |
| `--template` | string | `""` | template file for `--render` |
| `--executor` | string | `""` | resolved executor hint for `--render`'s `{executor}` packet substitution (default: the step's declared hint) |

The response is engine-spec §11.4's `claim response` verbatim:
`{ step, token, lease_expires_ms, context }`. The token is returned **exactly
once** — capture it or claim again. In human mode it prints on its own line and
never inside the status message.

Claim enforces readiness **itself** rather than trusting that you ran `next`; a
step that is not ready is `CONFLICT` naming the unmet condition. **Human, vote,
and action steps are not claimable** — the first two are gates rather than work,
and an action step is the engine's own computation — and a claim against one is
`CONFLICT` naming its class and what advances it instead.

#### `docket step reap`

| Flag | Type | Default | Notes |
|---|---|---|---|
| `--reason` | string | `""` | **required**; why the holder is being declared dead |

**Token-free**, like `approve` and `resolve`: the authority is repository access
plus the recorded assertion that the holder is gone. Liveness is otherwise
TTL-only, and a TTL cannot be sized right in both directions — raised to cover
healthy long writers, it multiplies how long a dead agent's claim blocks its row.
The engine cannot probe a process it did not start, but the relay that spawned
the executor can, and this verb is the channel for what it observed.

**Every consequence is the expiry reap's own**: the same `lease-reaped` event
(carrying `data.forced` and the reason, which is how a reader tells the two
apart), the same write-class headroom hold awaiting `--ack-reap`, the same return
of the step to the ready pool.

`--reason` is required, and omitting it is a `VALIDATION_ERROR` (exit 3) — a
forced reap asserts the holder is gone, and somebody will ask on whose word.
Only a `claimed` or `running` step holds a lease to reap; anything else is
`CONFLICT` (exit 4) naming the step's actual status, and a missing step is
`NOT_FOUND` (exit 2).

**Reaping a holder that is in fact alive carries exactly the risks a lease
expiry does** — the database lease was never a tree fence. Assert liveness, do
not assume it.

This verb is also the way to clear a dead holder on a run that is **not
active**, where neither the lease TTL nor `max_step_duration` reaps at all (see
`[limits]` above). `step reap` checks the step's own status, not the run's.

#### `docket step complete`

| Flag | Type | Notes |
|---|---|---|
| `--artifact-file` | string | **required**; the artifact body. Capped at **1 MiB**; over it is `VALIDATION_ERROR` naming the size and the cap |
| `--payload-file` | string | JSON array of objects. When the step declares `payload = "name@version"`, it is validated against that schema — the bytes the run PINNED, not the registry's current ones — and a failure is a `VALIDATION_ERROR` (exit 3) naming the element and property (`payload[3].severity: …`), up to five lines and then `(+N more)`. Omitting it on a step that declares `payload` is the same refusal: a declared payload is a contract, and recording none would make every threshold over it evaluate against the empty set. A step that declares no `payload` is shape-checked only, exactly as before. |
| `--gap-file` | string, **repeatable** | one out-of-scope problem the work surfaced. Each records an auxiliary artifact of kind `gap` beside the step's declared emit **and** materializes a backlog issue related (`relates_to`) to the step's own — same transaction, so the residue cannot evaporate. Capped at **1 MiB** each, like any artifact; an **empty** gap is `VALIDATION_ERROR` (exit 3). Gap files are read whole before the saga starts, so a bad path refuses without spending the completion |
| `--usage` | string | `{"unit": n, …}` — a JSON object of **opaque** unit names to numbers, recorded in the run's usage ledger and summed per unit by `run report`. At most **32** units; each name at most **64** printable-ASCII bytes with no whitespace; each number finite and **≥ 0**. Any other shape is `VALIDATION_ERROR` (exit 3) naming the offending key. Docket never interprets, converts, or routes on these numbers — the one named by `docket config budget.unit`, if any, participates in the run's cap comparison, and that is the whole contract |
| `--metadata` | string | a JSON **object** of opaque keys to values, **merged onto the step's own** metadata: keys the definition declared survive, keys only the worker reports are added, and a key in both takes the worker's value. The merge is **shallow** — a nested object is a value, replaced wholesale, never descended into. Capped at **16 KiB** measured on the supplied bytes; over it is `VALIDATION_ERROR` naming the size, the cap, and the two channels for bulk detail (`--artifact-file`, `--payload-file`). Anything that is not a JSON object — an array, a scalar, `null` — is `VALIDATION_ERROR`. Docket never reads a key inside: the merged bag is delivered verbatim in the context bundle and rolled up key → distinct value → count by `run report` |
| `--worktree` | string | the checkout the work happened in; the recorded `issue.diff` is computed **there** rather than in the invoking checkout (the default). The declared path lands in the diff's round record beside the head sha, which is where a consumer's `target_worktree` comes from |

Completion is a **saga**: validate → record the artifact → gates one by one →
routing. **The token retires when the artifact records.** From that commit the
step is engine-owned and finishes under any later invocation, so a worker that
dies mid-saga strands nothing. Completing twice is `AUTH_ERROR`, not a duplicate
artifact.

**Gaps need no workflow declaration — the channel is always open.** A worker
that surfaces a problem outside its own scope has nowhere to put it: narrating
it into the artifact body buries it in prose, and dropping it loses it entirely.
`--gap-file` gives it two durable homes at once, in the completion's own
transaction. The materialized issue is created `backlog` / `none` / `task`, with
the gap body as its description and its title taken from the gap's first
non-blank line (leading `#` stripped, capped at 120 characters). Docket never
interprets what the gap says. The success message names the issues it filed —
`Completed, gaps filed as DKT-91, DKT-92: …`. The materialized issue lands in
the RUN'S OWN project unconditionally — `--gap-file` has no cross-project
routing — so a gap whose problem lives in another repository's project gets
re-homed by whoever reads the completion: `docket issue move <id> --project
<target>` (operator ruling, 2026-08-16: gaps belong to their respective
projects).

**A gap-only completion PARKS instead of passing (DKT-25).** When the declared
emit's body is empty (whitespace-trimmed) and at least one gap was recorded,
the step routes `waiting-human` **before the gate verdict or threshold is
consulted** — the worker's whole answer was "this work cannot be done here,
and here is the residue", and routing `pass` over it would schedule the
issue's entire downstream pipeline over an empty change (a full judge fanout
independently verifying "nothing to judge" was the measured cost).
`step resolve` is the operator's disposition. Gaps recorded **beside real
content** route exactly as before. When the gap belongs to a different
repository, `docket issue move --project` re-homes the filed issue.

#### `docket step fail`

| Flag | Type | Notes |
|---|---|---|
| `--note` | string | why the step failed — lands on the **failure EVENT**, prose for a human reading the run's history |
| `--metadata` | string | a JSON **object** of opaque keys to values, merged onto the step's own — lands on the **STEP ROW**, structured KV for a query. `--note` and `--metadata` are complementary, not alternatives, and both are accepted on the same invocation |

`--metadata` is DKT-69's parity with `step complete --metadata`: the same
shallow, last-write-wins merge, the same shared write path
(`internal/engine`'s `mergeMetadata` and `db.SetStepMetadataTx`), and the same
16 KiB cap — measured and refused pre-transaction, so a rejected `--metadata`
spends no attempt. The refusal message differs from `complete`'s: `step fail`
offers no `--artifact-file` or `--payload-file`, so it points at `--note`
instead of channels this verb does not have.

**It SURVIVES INTO A RETRY.** A failed attempt's bag merges into the step's
row like any other, so the next attempt's completion (or failure) overlays on
top of it — a worker that reports *why* it failed has produced the most
valuable metadata in the run, and discarding it at retry would lose exactly
the diagnostic an operator wants. It reaches `run report --json`'s existing
metadata rollup the same way a completion's does — no new rollup, no new
report section, and it is reachable **even for a step that never completes**,
which is the run an operator most wants tier-drift data from.

#### `docket step annotate`

| Flag | Type | Notes |
|---|---|---|
| `--metadata` | string | **required**; a JSON **object** of opaque keys to values, merged onto the finished step's own metadata |

The post-completion channel for facts that become true only **after** a step's
record freezes (DKT-35). The canonical case is integration: a relay that
rebases or cherry-picks a recorded commit mints a NEW sha, and every run
record citing the writer's own — change-summary first lines, issue comments,
the round record — is unreachable from any ref once the worktree is swept.
Annotating the step with the durable id keeps the run record re-checkable.

The merge is the **same rule `step complete --metadata` uses** — shallow,
last-write-wins, 16 KiB cap on the supplied bytes, non-object refused — and it
is **token-free**: the lease retired with the artifact, and this is an
operator-side act about the record, not a completion. The merge is logged as a
`step-annotated` event carrying the annotation **verbatim**, so what was added
survives a later annotation overwriting the same key.

Refusals: a step that has not reached a terminal status is `CONFLICT` (exit 4)
naming its actual status — a live step's metadata lands with its record, under
its holder's token, and a side channel into an in-flight record would bypass
exactly that authorization. Empty or non-object `--metadata` is
`VALIDATION_ERROR` (exit 3); a missing step is `NOT_FOUND` (exit 2).

#### `docket step resolve`

| Flag | Type | Notes |
|---|---|---|
| `--as` | string | **required**: `retry` \| `rerun-gates` \| `skip` \| `abandon-issue` \| `override-pass` \| `fix-round` |
| `--note` | string | why |

`retry` resets the **step's** attempt budget. That is a different counter from
the issue-level attempt trail, which is monotonic and never reset. It also
**releases the lease**, so the re-execution goes through a fresh claim and lands
on its own attempt number: `pending` with a live lease is a contradiction —
`claimPredicate` refuses every new claimant while the previous holder's token
still records, so both executions share one number, the usage ledger's
`(step, attempt, unit)` key admits only the first, and the report counts one
attempt for work that happened twice. `resolve` is also how an operator moves a
run past a `type="vote"` step whose voters have not cast — a run must not be
hostage to a quorum that never arrives.

**`rerun-gates` re-measures without re-executing** (DKT-259). Most retries in
practice are not about the work at all: a gate failed because a trust entry was
missing or a tool was broken, someone fixed that out of band, and the step's own
output was never in question. `retry` was the only lever, and it is the wrong
one twice over — it pays for a full re-execution, and the re-execution is
**destructive**: it diffs a tree that already contains the change, so the diff
comes back empty and supersedes the real `issue.diff` with 0 bytes.

`rerun-gates` rewinds the step to the point just after its artifact recorded and
re-runs every completion gate from there, then routes on the new verdicts. The
step never returns to the pool, no worker re-executes it, no attempt is
consumed, and the recorded artifact is untouched. It re-measures; it does not
forgive — gates that still fail park the step again, exactly where it was.

Reach for `rerun-gates` when the **gate** was wrong, and `retry` when the
**work** was. A step declaring no completion gates refuses `rerun-gates` and
says so, naming `retry` instead: a `pre = true` gate runs at claim and is not
part of the completion saga, so a step with only those has nothing to re-run.

Two artifact rules follow from the same reasoning and apply to **every** path,
not just this verb. A recomputed `issue.diff` that records **no change** does
not supersede one that recorded a change — an empty diff is evidence that this
measurement had nothing to compare, never evidence that the change vanished (a
*first* empty diff still records; a genuine "nothing changed" is a real result).
And a **byte-identical** re-record is not a supersession at all: nothing
revised, so no new revision is written.

**`fix-round` is the sanctioned re-entry into an exhausted fix loop** (DKT-237).
Exhausting `max_fix_loops` parks the issue, correctly — but nothing could then
mint another round, and going around the engine became the reasonable move: one
run's fix was built by an out-of-band agent, cherry-picked with no judge review
as a step, with ~100k output tokens in no ledger. This authorizes **one** more
loop for **that issue** and enters it in the same transaction, minting a fresh
fix+review round judged like every other.

It is deliberately **not** `retry`: retry re-runs the check that reported the
problem, which asks the same question again; `fix-round` says the problem is
real and schedules work on it. The authorization is recorded as a per-issue
grant (`run_issues.loop_grants`, schema v20) rather than as an edit to
`max_fix_loops` — the workflow's bound is the author's standing policy over
every issue it matches, and loosening it to unstick one issue would loosen it
for all of them and leave no record of who reopened what. The effective bound
is `max_fix_loops + loop_grants`, so **one grant buys exactly one round** and
the bound reasserts itself immediately after. The parked step is recorded
`superseded`, not passed: its question is answered by the new round's work, not
by a verdict nobody reached. The park's own reason now names this verb.

**`retry` is refused on a step parked by a rejected held cluster** —
`VALIDATION_ERROR` (exit 3), naming the held step — rather than silently
re-parking it. Re-running the aggregate re-reads the same rejected decision and
routes to the same place, so the attempt counter was never what blocked it. The
refusal names the three resolutions that can move it: `override-pass`, `skip`,
`abandon-issue`.

**`retry` is refused on a held cluster parked by a vote that did not pass**, for
the same reason: the idempotency key is `(run, instance)`, so the next `next`
re-reads the *same* finished tally and parks it again. That refusal names
`step approve` / `step reject`, which is the better remedy anyway — the question
is open and the operator can simply answer it. The other three resolutions do
apply to such a step, and `override-pass` there records the cluster as resolved
exactly as `approve` would, so the payload never says "undecided" about a
cluster the routing already passed.

#### `docket step approve|reject`

| Flag | Type | Default | Notes |
|---|---|---|---|
| `--note` | string | `""` | why the gate was approved or rejected |
| `--value` | string | `""` | (`approve` only) corrected value for a **held cluster's** aggregated field |

Both are **token-free**: a gate is resolved by an operator who never claimed it.
They apply to `type="human"` steps, and to a **materialized** `<step>-held` step
whichever kind it was minted as — anything else is `VALIDATION_ERROR` naming the
step's actual class, because reaching for `approve` usually means mistaking
which step is blocking.

The held step is where an `aggregate` step's held clusters are decided. The
difference from a declared gate is where the consequence lands: approving a
declared gate finishes that gate, while approving a held cluster un-defers the
aggregate step's routing (see *Held clusters* above). Deciding one twice is
`CONFLICT` (exit 4) naming both steps.

When holds are minted as votes (`vote.hold.*`), these verbs apply to a held step
**once a vote that did not pass has parked it** at `waiting-human`. Before that
the tally owns the decision and both verbs are `VALIDATION_ERROR`, naming
`step resolve` as what moves a run past a vote still being cast — approving
during a tally would take the panel's turn away and orphan its open proposal.

`--value` belongs to that second case only. It sets the cluster's aggregated
field to a value validated against the **pinned schema's declared enum**,
recording the computed value it replaced as `operator_set_from`, and `--note`
travels with it as `operator_note` — the full rules are in *Held clusters* above.
On a declared human gate, or alongside `reject`, it is a `VALIDATION_ERROR`.

#### `docket step context` / `render`

`context` re-emits the bundle read-only, no token. It is assembled from the
run's **pinned and snapshotted** state only — the issue as it read at
activation, the recorded input artifacts, and the pin list. It never reads the
live issue, never reads the working tree, and never opens a pinned file, so two
calls at the same run state are byte-identical whatever has been edited between
them. `--meta` adds per-section byte counts as a **sibling** object, leaving the
bundle itself unchanged.

`render` formats that bundle through a template. Without `--template` the
shipped default is used; it ships in the binary and cannot drift. With
`--template F`, **if the run pinned that path the file's bytes are verified
against the pin** and a mismatch is `CONFLICT` naming both hashes — never a
warning, never a silent re-pin. An unpinned template renders unverified and says
so. `--executor` (also on `step claim --render`) overrides the resolved hint
used for `packet` entries' `{executor}` substitution; the default is the
step's own declared hint.

**Read verbs here write nothing**, including no reap — even for a step whose
lease has lapsed, which reads as `pending` while the row still carries the stale
owner.

### `docket guard` — `guard.go`

Deterministic predicates over engine state, for hooks.

| Verb | Allows when |
|---|---|
| `guard stop` | no pending work outside `waiting-human` |
| `guard gate --step NAME` | a **passed** `type="human"` **or** `type="vote"` step of that name exists for an active run — an approval on the one, a tallied approval on the other. Both kinds answer, so converting a gate to a vote does not silently stop the hooks that check it; a vote still being cast reads as undecided and denies |
| `guard record [--run RUN-N]` | no unreconciled dispatch exists — no open manifest, and no discrepancy |
| `guard spawn --run RUN-N` | the proposed rows byte-match the open dispatch **and** no write-class reap is unacknowledged (or `--deciding-vote PROPOSAL-N` names the open proposal this batch exists to decide — the reap half only) |

**Exit 0 = allow, exit 2 = deny with a reason.** That contract is independent of
the error-code table above: a guard's caller tests a boolean, so exit 2 here
means "denied", not "not found". The reason goes to stderr in human mode and
into the envelope's `error` under `--json`.

**When the resolved store has no database, a guard ALLOWS (exit 0) rather than
denying.** A repo with no engine has no engine state to forbid anything, so
"not applicable" is an allow. The reason still travels — `not_applicable: true`
plus a `reason` in the JSON payload, and a `guard: …` note on stderr in human
mode — so a surprisingly-permissive hook is still diagnosable.

This is the one place the exit-2 collision had to be broken. Previously a
missing database took NOT_FOUND's exit 2, which a hook wired as
`docket guard stop || exit` could not tell from a denial, so every non-docket
repo on the machine started denying. Only the absence of a database allows this
way; every verdict a guard actually computes still denies through exit 2.

`guard stop` deliberately does **not** block on `waiting-human`: it asks whether
the machine is done working, and a run waiting on a person is not something a
stop interferes with.

It also does not block on a run **nothing has ever happened to** (DKT-71):
never dispatched, and no step ever out of `pending`. `bootstrap`'s contractual
terminal state is exactly that — an activated, never-dispatched run — and all
six bootstraps measured on 2026-08-16 were denied a turn-end over it, twice
pushing the operator into starting work nobody had asked for. Nothing was handed
to anything, so there is nothing for a stop to interrupt. The exemption ends at
the first dispatch, or at the first step that leaves `pending`: a run that
acquired history without a manifest still blocks.

Guards answer over the **current project's** runs by default. `guard stop`,
`guard gate`, and `guard record` accept `--all-projects` to answer over every
project's runs in the store instead — the same vocabulary as
`events list --all-projects`. (`guard spawn` is inherently per-run and has no
such flag.)

#### `guard record` — before a worker records

| Flag | Type | Default | Notes |
|---|---|---|---|
| `--run` | string | `""` | the run to check; **omit** to check every non-terminal run |

Wire it before letting a worker call `step complete`. An unreconciled batch means
the engine's picture of what is running is already wrong, and recording an
artifact into that picture is how drift becomes durable.

"Unreconciled" is the **same two probes `next` uses** — an open dispatch, or any
discrepancy — computed by the same function, so the guard and the scheduler
cannot disagree. The denial repeats `next`'s refusal verbatim, resolutions
included.

Without `--run` it answers over every non-terminal run and denies if any is
unreconciled, matching `guard stop`'s shape, so a hook wired once keeps working
as runs come and go. A `--run` naming a run that does not exist is `NOT_FOUND`
(exit 2), not a vacuous allow: a typo must not read as permission.

#### `guard spawn` — before a relay starts a batch

| Flag | Type | Default | Notes |
|---|---|---|---|
| `--run` | string | `""` | **required** — the run whose batch is being spawned |
| `--rows` | string | `""` | file holding the JSON array of rows about to be spawned (`-` for stdin) |
| `--ack-reap` | int64Slice | `nil` | acknowledge a write-class reap by its `lease-reaped` event `seq` (repeatable) |
| `--deciding-vote` | string | `""` | admit this batch past a reap hold because it exists to DECIDE the named OPEN proposal (`PROPOSAL-N`); event-logged |

Both halves must hold. With **no** open dispatch and **no** `--rows`, the row
half is vacuously satisfied and the reap half still answers — so a relay that
batches its own way still gets the check. With `--rows` and no open dispatch it
is a **denial**: the relay believes it is spawning a batch the engine never
issued. A row that does not byte-match shows **both sides' bytes**, so you can
see what moved rather than being told they differ.

`--ack-reap` is processed **before** the predicate, so one command both
acknowledges and answers — which is what lets a relay's spawn hook be a single
invocation. It is also the second of the two entry points for the
acknowledgment; `dispatch open --ack-reap` is the other, for a **new** relay
taking over from a crashed one. Acknowledging asserts *you* have established the
old writer is gone: the engine knows its database lease lapsed and cannot check a
process it did not start.

Acking a seq twice is a success that changes nothing. Acking a seq that names no
reap of this run is `VALIDATION_ERROR` (exit 3) — an acknowledgment must name a
real reap.

**`--deciding-vote` breaks the one deadlock this guard creates** (DKT-236).
Unacknowledged reaps hold headroom; the sanctioned way to decide whether to
acknowledge them is a judge panel; and the hold denied that panel's own spawn —
the exact state the panel exists to decide. Nothing could move, so what happened
instead was a ~10h operator round trip followed by two self-passed `--ack-reap`
calls with no panel at all, which is authorization creep arriving through the
gate's own deadlock. The denial now names the flag, so the way out is readable
off the refusal.

The carve-out is narrow, and each clause is load-bearing. The proposal must
**exist** — an id nobody created would be a bypass with a plausible-looking
flag — and must be **open**, since a decided proposal would otherwise authorize
every future spawn forever. It relaxes the **reap half only**: row drift is a
fact about a relay spawning a batch the engine never issued, and no vote makes
that acceptable. It does **not** acknowledge anything — it admits the panel that
will decide, and deciding stays the panel's job. Every use writes a
`spawn-admitted` event carrying the carve-out, the proposal, and the hold it was
admitted over, because a spawn let past a hold must not read like a spawn
nothing was holding.

**Both guards write nothing, except that acknowledgment** — and, when
`--deciding-vote` is used, its audit event. Neither reaps and neither
auto-abandons an expired dispatch, so a hook's mere presence cannot change how a
run schedules.

**The guard is an early check, not a lock.** Between its allow and the actual
spawn, a dispatch can be abandoned or a lease reaped; the real enforcement stays
where it has always been, in `step claim`'s compare-and-swap.

### `docket trust` — `trust.go`

The allowlist of commands docket may execute. **A gate runs only when an entry
here authorizes it**; an unmatched gate is reported, never run. Full details and
the reasoning are in docs/spec/security.md §7.

Entries live in `$XDG_CONFIG_HOME/docket/trust.toml` (default
`~/.config/docket/trust.toml`), owned by you, mode `0600`, and **never read
from a repository**. There is no `--trust-file` flag, no env override beyond
`XDG_CONFIG_HOME`, and no config key — every extra way to point docket at a
trust file is another way for repo content to choose it.

**A missing trust file is not an error.** It is an empty allowlist: every gate
reports `unmatched`, nothing runs, and the run tells you what it needed. That
is the answer to "I just installed this and nothing executes" — nothing is
supposed to, yet.

These verbs need no `.docket/` database: the store is user-level.

#### `docket trust add <name> -- <argv...>` 

| Flag | Type | Default | Notes |
|---|---|---|---|
| `--global` | bool | `false` | trust in **every** repository, not just this one |
| `--prefix` | bool | `false` | match any command *beginning* with this argv; prints an over-authorization warning |
| `--re-runnable` | bool | `false` | safe to run again after a crash interrupted it |
| `--tree` | bool | `false` | touches the working tree; serializes against other such gates |
| `--flaky` | bool | `false` | may fail intermittently; re-runs on failure, each attempt recorded |
| `--stub` | bool | `false` | this is a **placeholder**, not the check its name implies; every result it produces is flagged `stub` in `step gates` and counted in the run report |
| `--network` | stringSlice | `nil` | hosts this command must reach (repeatable). **Declares a requirement; grants nothing.** A gate that names any receives the proxy variables and `DOCKET_GATE_NETWORK`; one that names none is unchanged |
| `--timeout` | duration | `5m` | per-command timeout |
| `--yes` | bool | `false` | skip the interactive confirmation (the argv is **still** disclosed) |

**`--stub` marks hollow assurance.** A repo with no scanner installed still
wants to exercise a workflow's shape, so `docket trust add secret-scan -- /usr/bin/true`
is legitimate and stays legitimate. What is not legitimate is the row it
produces: without the flag, `secret-scan: pass` is indistinguishable from a
scanner that ran and found nothing, and a reviewer reads it as one. With it,
`step gates` shows `stub` in the FLAGS column and `run report` says
`secret-scan: pass 1 — all stubs, nothing was measured`.

Docket cannot work this out for itself — an argv cannot be inspected to tell a
real check from a convincing one, and a guess would miss a `scan.sh` whose body
is `exit 0` while flagging a legitimate `true` guard. It is a declaration, like
`--tree` and `--flaky`, and it changes **nothing** about how the command runs.
Flipping it on a re-add is a `CONFLICT`, for the same reason flipping `--tree`
is: the store would otherwise show only that something of that name was
re-approved.

**Everything after `--` is the argv, verbatim.** Your shell already tokenized
it and docket stores those tokens — nothing is split, expanded, or globbed, and
no shell is ever involved in running it. A flag after `--` belongs to the
trusted command:

```bash
docket trust add tests -- make test
docket trust add lint  -- golangci-lint run --fix   # trusts ["golangci-lint","run","--fix"]
```

The entry binds to the **current repository** unless `--global`. A command
trusted in one project does not execute in a clone of another; moving a
repository invalidates its entries (`trust list --all` shows the stale binding
so you can see why a gate went `unmatched`).

**The unmatched diagnostic leads with the case you are actually in** (DKT-64).
When an entry of the gate's name exists only in ANOTHER repository, the message
leads with `no trust entry for this repo; approve it with docket trust add`, and
mentions the other binding as an aside with the moved-path reading offered
conditionally. It used to lead with "restore the repo to that path if it was
moved" — which is this branch's every occurrence, including the common one where
nothing moved and this repo simply never had an entry; five projects hit it on
one gate and every one went hunting for a path problem that did not exist. A
gate whose name IS trusted here but whose argv differs now says so, instead of
falling through to "no trust entry" and pointing at the wrong verb.

`--yes` suppresses the prompt, **never the disclosure**: the argv, the binding,
and the `--prefix` warning print on every add and ride in the JSON response.

| Situation | Result |
|---|---|
| new name+repo | insert, exit 0 |
| identical argv and flags at an existing name+repo | idempotent success, nothing written, exit 0 |
| **different** argv or flags at an existing name+repo | `CONFLICT` (exit 4) naming both argvs; `trust rm` first |
| unsafe store (symlink, wrong mode, wrong owner, writable parent) | `VALIDATION_ERROR` (exit 3) naming the path and the fix |
| no argv after `--` | `VALIDATION_ERROR` (exit 3) |
| the grant cannot be recorded in this repo's event log | `GENERAL_ERROR` (exit 1); the store is **untouched** |

#### `docket trust list`

| Flag | Type | Notes |
|---|---|---|
| `--global` | bool | only global entries |
| `--all` | bool | every repository's entries, not just this one's |

A `Collection`, so `--json=v2` renders `{items, total, truncated}`. Argvs print
with control characters escaped.

#### `docket trust rm <name>`

| Flag | Type | Notes |
|---|---|---|
| `--global` | bool | remove the global entry rather than this repo's |

`NOT_FOUND` (exit 2) when no such entry is bound here.

#### The tenancy audit trail

Registering a project writes a `project-registered` event carrying the `cwd`,
the resolved `identity`, and the `verb` that triggered it (DKT-61). A project
row is what every other row is attributed TO, and until this kind existed the
project itself recorded nothing about its own origin: attributing one junk row
to the verb that minted it took a hand-join of raw table timestamps against nine
session transcripts. Like a trust event it has **no run** — registration
precedes any run of the project by definition — and it is scoped to the project
it names, so it appears in that project's feed rather than in every project's.

Registration itself is now **gated** (DKT-58): a project row is created only
when the identity is a git worktree (or a deliberate `.docket` store) **and**
the verb is not a read. A read from a directory with no project answers "nothing
here"; a run-addressed verb (`step`, `dispatch`, `trust`, `guard`, `events`)
carries on with no ambient project, since it reads its project off the run; and
a verb that would WRITE through the ambient project from a non-repository
directory is refused by name. Before this, any command run from a
non-repository directory minted a permanent row — a judge executor recording a
step from the shared scratchpad root created one named `claude-501`.

#### The trust audit trail

`add` and `rm` write a `trust-added` / `trust-removed` event, carrying the argv
**hash** rather than the argv — so a grant made mid-run is auditable without
leaking the command's arguments into a feed a run report renders. Beside the
hash the event carries every property that affects behavior: `name`, `repo`,
`global`, `prefix`, `re_runnable`, `tree`, `flaky`, `network`, and `timeout`.
Those are what a grant **widens**, and a feed showing only the name could not
tell a re-approval from an escalation.

It also records **who**: `actor` (the git identity, falling back to the OS
username and then to `unknown`) and `cwd` (where the verb ran from). The
timestamp only ever answered *during which run* a grant happened — two
concurrent sessions on one machine bracket a run identically, so recovering
by-whom meant correlating against session logs. `cwd` is the field that
separates them.

**Neither is authenticated.** `git config user.name` is whatever the invoking
environment says it is; this is an attribution claim on the same footing as step
metadata, not a verified identity. It is worth recording anyway — a grant is the
one act in the system that widens what code may execute, and an unauthenticated
name in the trail beats a join against wall-clock.

**Recording is mandatory inside a repository, not best-effort.** The event is
written *before* the store, as a hook inside the store's own lock: if it cannot
be recorded, the verb fails with `GENERAL_ERROR` (exit 1) and **nothing is
granted**. An absent event is not a neutral outcome — an auditor reads it as
"no grant happened" — so the only divergence that can survive is a recorded
change that then failed to land, which is loud rather than silent and errs
toward over-reporting authority.

**An idempotent re-add emits no event.** Nothing was written, so there is
nothing to record: a record of a change must prove a change happened.

**Outside a repository the verbs still work, and say what they did not do.**
The store is user-level, so requiring a database to manage it would mean
somebody who installed docket could not approve a command until they created a
tracker. When the repository cannot be resolved, or there is simply no database
at the resolved path, the change is applied and a **warning** says it was not
recorded and that nothing will show it later. The warning prints on stderr and
rides in the JSON response's `warnings` array; like the argv disclosure, it is
not suppressible.

### `docket vote` (alias `v`) — `vote.go`

#### `docket vote create` — `vote_create.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--description` | `-d` | string | `""` | required in `--json`; `"-"` reads stdin |
| `--rationale` | `-r` | string | `""` | `"-"` reads stdin |
| `--criticality` | `-c` | string | `"medium"` | `low`\|`medium`\|`high`\|`critical` |
| `--voters` | `-n` | int | `0` | required (when explicitly set) in `--json` mode; must be `>= 1` |
| `--threshold` | — | float64 | `0.67` | must be in `(0.0, 1.0]` |
| `--created-by` | — | string | `""` | defaults to `git user.name` if empty |
| `--domain-tags` | — | string | `""` | comma-separated |
| `--files-changed` | — | string | `""` | comma-separated |
| `--escalation-reason` | — | string | `""` | |
| `--idempotency-key` | — | string | `""` | replay protection; repeat returns the original proposal |

#### `docket vote cast <id>` — `vote_cast.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--voter` | — | string | `""` | defaults to `git user.name` |
| `--role` | — | string | `""` | |
| `--verdict` | `-v` | string | `""` | required in `--json`; `approve`\|`approve-with-concerns`\|`reject` |
| `--confidence` | — | float64 | `0` | required (when explicitly set) in `--json`; range `[0.0, 1.0]` |
| `--domain-relevance` | — | float64 | `0` | required (when explicitly set) in `--json`; range `[0.0, 1.0]` |
| `--findings` | — | string | `""` | `"-"` reads stdin |
| `--findings-json` | — | string | `""` | `"-"` reads stdin; parsed as `model.Findings` JSON; mutually exclusive with `--findings` for stdin use |
| `--summary` | — | string | `""` | one-line summary |
| `--metadata` | — | string | `""` | JSON object, 16 KiB cap measured on the **encoded** bag (whitespace does not count, escaping does); the seat's own opaque claim about what cast the vote — worked example above; stored whole, never read by core, never verified. It is visible in the process list, stored verbatim in the store, and re-emitted verbatim by `docket export`, so put nothing secret in it |
| `--usage` | — | string | `""` | `{"unit": n, ...}` — this seat's own spend report (DKT-95), recorded per seat in the `vote_usage` ledger inside the cast's transaction and summed per unit in the run report's `vote_usage` section. Same rules as `step complete --usage`: at most 32 units, finite non-negative numbers, opaque unit names. Exists because a vote step is never claimed (attempt stays 0), so the step ledger's key cannot hold per-seat rows. A relay that measures a seat's spend AFTER the cast records it with `docket vote backfill-usage` instead; the two stay distinguishable by `vote_usage.source` (v17, DKT-115) |

#### `docket vote commit <id>` — `vote_commit.go`

| Flag | Short | Type | Default |
|---|---|---|---|
| `--outcome` | — | string | `"Committed"` |
| `--escalation-reason` | — | string | `""` |

#### `docket vote close <id>` — `vote_close.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--reason` | — | string | `""` | **required**; why the proposal is being closed without a tally |

Closes an **open** proposal whose underlying decision was made another way
(DKT-114) — an operator authorized the guarded action directly, or the
question was superseded — and which would otherwise sit open forever. `closed`
is terminal and is **never a verdict**: no vote was counted, and the reason
lands in the proposal's `final_outcome`. Refusals: a decided proposal
(`approved`/`rejected`/`committed`/`closed`) is `CONFLICT` (exit 4) — records
do not move; a proposal opened by an engine **vote step** is `CONFLICT` too,
naming `docket step resolve` as the way to move a run past an uncast vote —
closing the step's own machinery underneath it would not route the step. A
closed proposal refuses further casts (`CONFLICT`), exactly as any finalized
one does.

**Three closures now happen automatically** (DKT-262), because an open proposal
is not inert: `vote list` shows it as outstanding work, and it is what a
spawn-guard carve-out points at, so a stale one makes two surfaces lie.

| Transition | What it closes |
|---|---|
| `run abandon` | every open ballot the run's **vote steps** opened. Ad-hoc proposals — an operator's own, bound to no step — are untouched |
| an acknowledged reap (`--ack-reap SEQ`) | the ack ballot registered under `reap-ack:<run>:<seq>`, if one exists |
| a fix loop entering a later ordinal | the ballot of each vote step the sweep supersedes |

Each rides **inside the transition's own transaction**, so a close cannot be
lost while the transition stands. Only `open` rows move, exactly as the verb
insists — every other status is the record of a decision.

The reason written into `final_outcome` names the **transition**, never a
verdict: these ballots reached none, and an outcome that read like one would
replace an honest stale-open row with a dishonest decided one. A reader can
spot the first and cannot spot the second.

**`reap-ack:<run>:<seq>` is the key convention a conductor should use** when it
opens a ballot to decide a reap. The engine defines it even though the
conductor creates the ballot, because only one of the two can be the definition
and it has to be the side that must *find* the row later. A conductor that does
not use it simply gets no auto-close, exactly as before.

#### `docket vote backfill-usage <id>` — `vote_backfill.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--voter` | — | stringSlice | `nil` | seat whose usage is being recorded (repeatable) |
| `--unit` | — | stringSlice | `nil` | unit for the matching `--voter`; core has no default unit |
| `--quantity` | — | float64Slice | `nil` | quantity for the matching `--voter` and `--unit` |
| `--from-json` | — | string | `""` | JSON array of `{"voter","unit","quantity"}`; `-` reads stdin |
| `--source` | — | string | `"backfilled"` | who measured it; recorded on every row (v17) |

The vote-scoped back-fill (DKT-115). `vote cast --usage` is the seat's OWN
report at cast time; a relay that measures panel cost from its transcripts
afterwards had no ledger path — tribunal seats carry a proposal id, never a
step id, so `dispatch backfill-usage` (step-keyed by design) could not receive
them and governance spend stayed invisible to budget and report. Rows attach
to each seat's **cast**: a seat that never cast is refused by name
(`VALIDATION_ERROR`), a repeat of a `(seat, unit)` already recorded — by an
earlier back-fill or by the seat itself — is `CONFLICT`, and the whole batch
is one transaction. `vote_usage.source` (schema v17) keeps the relay's
reconstruction distinguishable from the seats' own reports forever.

#### `docket vote link <proposal-id>` / `docket vote unlink <proposal-id>` — `vote_link.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--issue` | — | string | `""` | **Req.** (`MarkFlagRequired`) on both `link` and `unlink` |

#### `docket vote list` (alias `ls`) — `vote_list.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--status` | `-s` | string | `""` | `open`\|`approved`\|`rejected`\|`committed`\|`closed`; defaults to `open` unless `--all` |
| `--criticality` | `-c` | string | `""` | |
| `--domain-tag` | `-d` | string | `""` | |
| `--all` | — | bool | `false` | include resolved proposals |
| `--limit` | — | int | `50` | |

Watch-eligible.

#### `docket vote result <id>` — `vote_result.go`

No local flags. Watch-eligible.

#### `docket vote show [id]` — `vote_show.go`

No local flags. Watch-eligible.

### `docket doc` (alias `d`) — `doc.go`

#### `docket doc create` — `doc_create.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--title` | `-t` | string | `""` | required in `--json` |
| `--description` | `-d` | string | `""` | `"@path"` loads a file, `"-"` reads stdin (1 MiB cap each) |
| `--type` | `-T` | string | `""` | free-form (no enum validation) |
| `--status` | `-s` | string | `""` | free-form (no enum validation) |
| `--idempotency-key` | — | string | `""` | replay protection; repeat returns the original doc |

#### `docket doc edit <id>` — `doc_edit.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--title` | `-t` | string | `""` | only applied when explicitly set |
| `--description` | `-d` | string | `""` | same `@path`/`-` semantics as create |
| `--type` | `-T` | string | `""` | |
| `--status` | `-s` | string | `""` | |

#### `docket doc show [id]` — `doc_show.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--rev` | — | int | `0` | show a specific revision number |

Watch-eligible.

#### `docket doc list` (alias `ls`) — `doc_list.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--type` | `-T` | stringSlice | `nil` | repeatable |
| `--status` | `-s` | stringSlice | `nil` | repeatable |
| `--author` | `-a` | string | `""` | |
| `--sort` | — | string | `""` | `field:direction`, e.g. `updated_at:desc` |
| `--limit` | — | int | `50` | |

Watch-eligible.

#### `docket doc delete <id>` — `doc_delete.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--cascade` | — | bool | `false` | also removes issue/proposal links (not the linked issues/proposals) |
| `--force` | `-f` | bool | `false` | **required in `--json` mode and non-interactive human mode** (DKT-27: an output-format flag is never consent); in interactive human mode it skips the confirmation prompt |

#### `docket doc link add/remove` — `doc_link.go`

| Command | Flag | Short | Type | Default | Notes |
|---|---|---|---|---|---|
| `add <id> --issue <issue_id>` | `--issue` | — | string | `""` | **Req.** |
| `remove <id> --issue <issue_id>` | `--issue` | — | string | `""` | **Req.** |

#### `docket doc comment add [id]` / `docket doc comment list [id]` — `doc_comment.go`, `doc_comment_list.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--message` | `-m` | string | `""` | (`add` only) required in `--json` mode if stdin isn't piped |
| `--idempotency-key` | — | string | `""` | (`add` only) replay protection |

`comment list` has no local flags; watch-eligible.

### `docket export` — `export.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--format` | `-o` | string | `"json"` | `json`\|`csv`\|`markdown` |
| `--file` | `-f` | string | `""` | output path; empty means stdout |
| `--status` | `-s` | stringSlice | `nil` | repeatable |
| `--label` | `-l` | stringSlice | `nil` | repeatable (OR match) |

### `docket import <file>` — `import.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--merge` | — | bool | `false` | skip duplicates by ID; mutually exclusive with `--replace` |
| `--replace` | — | bool | `false` | destructive: clears DB first; mutually exclusive with `--merge` |
| `--yes` | — | bool | `false` | confirm `--replace`; **required** in every output mode (DKT-15) |

### `docket board` — `board.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--label` | `-l` | stringSlice | `nil` | repeatable |
| `--priority` | `-p` | stringSlice | `nil` | repeatable |
| `--assignee` | `-a` | string | `""` | |
| `--expand` | — | bool | `false` | show sub-issues individually instead of rolling up into parent |

Watch-eligible.

### `docket stats` — `stats.go`

No local flags. Watch-eligible.

### `docket init` — `init.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--local` | — | bool | `false` | create a repo-local `.docket` store in the cwd instead of initializing the resolved (by default shared `~/.docket`) store |

`Annotations: {"skipDB": "true"}` — runs before any DB check/open, since its
job is to create the DB. Initializing an existing database is an idempotent
success (`created: false`) that also applies pending migrations. `--local`
opts out of the shared store; resolution prefers an existing local store over
the global one, so subsequent commands find it without any flag.

### `docket project` — `project.go`

The shared store's tenancy surface. A store used to BE a project, so there was
nothing to list; under `~/.docket` every repository is a row, and these verbs
are the operator's view of that dimension. Neither is watch-eligible.

#### `docket project list`

No local flags. Lists the store's projects — `{id, name, prefix, identity,
current}` — with the **current** invocation's project marked (`*` in human
mode). A project's `identity` is the canonical path (or git identity) that
claims it; `(unclaimed)` renders when none has. A `Collection` under
`--json=v2`. This is where `issue move --project` targets come from.

#### `docket project delete <name|id>`

No local flags. Removes an EMPTY project row — the way back out for a row
created by mistake (DKT-59). It refuses any project that an issue, run,
document, proposal, workflow, schema, or label still references (`CONFLICT`,
naming the counts), and refuses the default project outright
(`VALIDATION_ERROR`), so it can remove junk and cannot remove history. To empty
a project first, re-home its issues with `issue move --project`. The argument
is a row id, a name, or an identity path; an ambiguous name is refused with the
candidates' ids.

#### `docket project set-prefix PREFIX`

Sets the prefix this project's issue ids render and parse with. The prefix is
**display only**: the number is the identity, global across the store. A bare
number always works, so references in old commit messages and other projects'
run records never go stale.

**An id renders under the prefix of the project that OWNS it, not the one you
are reading from** (DKT-256). Ids are minted from one store-wide sequence —
`DKT-267` and `DOT-268` were consecutive — so a prefix rendered from your cwd
made every cross-project reference silently wrong: the same `run report` row
showed `DOT-81` from one checkout and `ART-81` from another, and
`docket issue link add DOT-268 relates_to DKT-267` confirmed success as
"Linked DOT-268 relates_to **DOT-267**", renaming another project's issue in
the act of reporting that the right thing had been done.

**A prefixed reference that disagrees with the row's owner is refused**, naming
both projects. Before this, `docket issue show DOT-20` from `docket.git`
discarded the prefix, resolved `20` under the caller's project, and printed
`DKT-20` — the reader asked about one issue and was shown another. Cross-project
reads stay legal: `DOT-268` resolves issue 268 when 268 really is DOT's, which
is what makes `issue list --project`'s output round-trip. What is gone is the
third outcome — a *different* issue wearing the requested number. 1–8 letters (upcased); `DOC`,
`RUN`, and `STEP` are reserved for their own entities (`VALIDATION_ERROR`).
A prefix ANOTHER project already holds is refused (`CONFLICT`, naming the
holder): the prefix is a project's only discriminator in a listing, an event
feed, or a report, so two projects sharing one makes every id in the store
ambiguous about its owner (DKT-60). Registration derives a unique prefix from
the project's name — initials for a multi-word name, first three letters
otherwise — rather than the hardcoded `DKT` it used to write for every row.
The rest of the invocation renders in the new voice immediately.

### `docket version` — `version.go`

No local flags. `skipDB` annotated.

### `docket config` — `config.go`

No local flags. `skipDB` annotated (reads config even if no DB exists yet,
to report that fact). Watch-eligible.

#### `docket config set <key> <value>` / `docket config get [key]` — `config_set.go`

Engine defaults, stored in the `meta` table. **Not** `skipDB` — unlike the bare
verb these need the database. `get` with no key lists every value with its
source (`set` or `default`); under `--json=v2` the listing is a standard
`{items,total,truncated}` collection. A key that is unset AND has no shipped
default prints `<unset>` in human mode rather than an empty line (DKT-69) — an
empty line is indistinguishable from a key set to `""`, and in bulk it produced
fewer lines than keys, so a reader matching lines to keys positionally read the
wrong values. `--json` is unchanged: `source` already carries the distinction
there, and a consumer parsing `value` must not have to strip a human marker. Unknown keys and ill-typed values are
`VALIDATION_ERROR` (exit 3) at `set` time. Both take `--global`: `set --global`
writes the store-wide default rather than this project's override, and
`get --global` reads the store-wide layer ignoring project overrides. See the
Engine configuration section above for the key table, defaults, and the
project/store layering.
