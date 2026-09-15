# Docket — command semantics and recovery

Read the subsection relevant to the current operation; do not load this whole
file for ordinary issue work. Use `docket <verb> --help` for the installed
command's flags. The focused guides linked from [SKILL.md](SKILL.md) cover
transport, issue work, workflow authoring, schemas, and voting.

The engine-conductor families (run, step, dispatch, events, guard, trust,
gate, policy, registry, report, doctor) are documented for the docket-run
skill under [docket-run/references](../docket-run/references/run.md) and
are not repeated here.

The additions below were checked on **2026-09-04 against
`docket nightly-46-g4f256e1` (commit `4f256e1`, built `2026-09-04T05:39:02Z`)**,
using `--help` and `--version` only; other behavioral claims and JSON examples
were not re-run. When installed behavior differs, use its help and inspect the
actual response before parsing it. A nearby source checkout is not proof of an
installed binary's behavior unless their commits match.

[references/cli-inventory.json](references/cli-inventory.json) records command
paths, aliases, usage, and local/inherited flags. Refreshed **2026-09-14 UTC**
against `nightly-112-gcffd10c` (commit `cffd10c`, built `2026-09-14T21:28:29Z`);
covers 151 public commands. From this skill directory,
`python3 scripts/cli_inventory.py --check` checks the inventory; `--write`
refreshes it after a CLI upgrade. The helper invokes only `--help` and
`--version` and does not read or mutate a Docket store. It detects command/flag
drift, not changes to runtime semantics or JSON response shapes.

<a id="contents"></a>

## Contents

Each entry names a section anchor and its line count, so
`grep -n 'id="issue-move"' reference.md` gives the offset and the count the
length to read. The engine families live in docket-run's references:
[run](../docket-run/references/run.md),
[step](../docket-run/references/step.md),
[dispatch](../docket-run/references/dispatch.md) (with `next --run`),
[events](../docket-run/references/events.md),
[guard and trust](../docket-run/references/guard-trust.md),
[gate, policy and registry](../docket-run/references/gate-policy.md),
[report and doctor](../docket-run/references/report-doctor.md).

- [JSON envelope](#json-output) — 71 lines
- [Command & Flag Reference](#command-reference) — 9 lines
- [`docket issue` (alias `i`)](#issue-commands) — 294 lines
  - [`issue create`](#issue-create) — 18 lines
  - [`issue edit [id]`](#issue-edit) — 34 lines
  - [`issue show [id]`](#issue-show) — 25 lines
  - [`issue list`](#issue-list) — 43 lines
  - [`issue close [id]`](#issue-close) — 12 lines
  - [`issue claim <id>`](#issue-claim) — 16 lines
  - [`issue heartbeat <id>`](#issue-heartbeat) — 12 lines
  - [`issue release <id>`](#issue-release) — 8 lines
  - [`issue move <id> <status>`](#issue-move) — 37 lines
  - [`issue reopen [id]`](#issue-reopen) — 10 lines
  - [`issue delete <id>`](#issue-delete) — 16 lines
  - [`issue log [id]`](#issue-log) — 10 lines
  - [`issue comment add [id]`](#issue-comment) — 11 lines
  - [`issue file add/remove/list`](#issue-file) — 8 lines
  - [`issue link add/remove/list`](#issue-link) — 7 lines
  - [`issue label add/rm/list/delete`](#issue-label) — 11 lines
  - [`issue graph [id]`](#issue-graph) — 12 lines
- [`docket plan`](#plan-commands) — 26 lines
- [`docket next`](#next-commands) — 21 lines
- [`docket workflow` (alias `wf`)](#workflow-commands) — 109 lines
  - [`workflow register <file.toml>`](#workflow-register) — 13 lines
  - [`workflow lint <file.toml>`](#workflow-lint) — 16 lines
  - [`workflow deprecate <name>@<version>`](#workflow-deprecate) — 15 lines
  - [`workflow list`](#workflow-list) — 26 lines
  - [`workflow show <name>[@<version>]`](#workflow-show) — 17 lines
  - [`workflow init`](#workflow-init) — 18 lines
- [`docket schema`](#schema-commands) — 51 lines
  - [`schema register <name@version> <file.json>`](#schema-register) — 17 lines
  - [`schema list`](#schema-list) — 14 lines
  - [`schema show <name>[@<version>]`](#schema-show) — 16 lines
- [`docket vote` (alias `v`)](#vote-commands) — 149 lines
  - [`vote create`](#vote-create) — 17 lines
  - [`vote cast <id>`](#vote-cast) — 18 lines
  - [`vote commit <id>`](#vote-commit) — 9 lines
  - [`vote close <id>`](#vote-close) — 44 lines
  - [`vote backfill-usage <id>`](#vote-backfill-usage) — 23 lines
  - [`vote link <proposal-id>`](#vote-link) — 8 lines
  - [`vote list`](#vote-list) — 14 lines
  - [`vote result <id>`](#vote-result) — 6 lines
  - [`vote show [id]`](#vote-show) — 6 lines
- [`docket doc` (alias `d`)](#doc-commands) — 80 lines
  - [`doc create`](#doc-create) — 12 lines
  - [`doc edit <id>`](#doc-edit) — 11 lines
  - [`doc show [id]`](#doc-show) — 10 lines
  - [`doc list`](#doc-list) — 14 lines
  - [`doc delete <id>`](#doc-delete) — 9 lines
  - [`doc link add/remove`](#doc-link) — 9 lines
  - [`doc comment add [id]`](#doc-comment) — 11 lines
- [`docket export`](#export-commands) — 11 lines
- [`docket import <file>`](#import-commands) — 10 lines
- [`docket board`](#board-commands) — 14 lines
- [`docket stats`](#stats-commands) — 6 lines
- [`docket init`](#init-commands) — 14 lines
- [`docket project`](#project-commands) — 63 lines
  - [`project list`](#project-list) — 10 lines
  - [`project delete <prefix|name|identity|id>`](#project-delete) — 13 lines
  - [`project set-prefix PREFIX`](#project-set-prefix) — 32 lines
- [`docket version`](#version-commands) — 6 lines
- [`docket config`](#config-commands) — 24 lines
  - [`config set <key> <value>`](#config-set-get) — 17 lines

<a id="json-output"></a>

## JSON envelope — per-verb `data` shapes

Every `--json` response is `{"ok": <bool>, "data": <verb-specific>}` (errors are
`{"ok": false, "error": "...", "code": "..."}` with no `data` key at all). The
envelope is stable; the shape of `data` is NOT, and guessing it is what crashes
hand-rolled parsers. The table below preserves earlier runtime observations,
not re-executed as part of the help-only verification above. Probe the
relevant read response when adapting a parser to a different binary. These are
core shapes, not exhaustive field lists; additive fields can appear.

| Verb | `data` under `--json` (v1) | `data` under `--json=v2` / `--format json` |
| --- | --- | --- |
| `events list` (incl. `--run`, `--tail N`) | `{events: [...], total: <int>}` | `{items: [...], total, truncated}` |
| `issue list` | `{issues: [...], total: <int>}` | `{items: [...], total, truncated}` |
| `step list --run RUN-N` | `{steps: [...], total: <int>}` | `{items: [...], total, truncated}` |
| `run status` (no id) | `{runs: [...], total: <int>}` | `{items: [...], total, truncated}` |
| `run status RUN-N` | `{run: {...}, issues: <int>, steps: [...], pins: [...]}` | identical |
| `run budget RUN-N` | `{run, budget, source, floor, reported, spend, row_version}` | identical |
| `step artifact ARTIFACT-N --payload` | the payload itself — array, object, **or `null`** | identical |
| `step artifact ARTIFACT-N` (no `--payload`) | `{artifact, kind, producer, body, payload, bytes, payload_bytes, sha256, created_at_ms}` | identical |
| `step artifacts STEP-N` | `{step: "STEP-N", artifacts: [...]}` | identical |
| `vote list` (`--all` for resolved) | `{proposals: [...], total: <int>}` | `{items: [...], total, truncated}` |
| `vote show VOTE-ID` | `{id, status, weighted_score, threshold, required_voters, criticality, final_outcome, escalation_reason, description, rationale, domain_tags, files_changed, linked_issues, linked_docs, created_by, created_at, updated_at, votes: [...]}` | identical |

Current help documents two more shape distinctions: `issue show ID` and
`step show ID` return one object under `data`; two or more IDs return an array
of those objects. Issue summaries from `issue list`, `next`, `plan`, and
`board` omit `description` by default and carry `description_bytes`; pass
`--with-body` for full descriptions. An omitted body is not an empty
description.

For `step complete` / `step record`, `ok: true` means the artifact recorded.
Check the step status and `failed_gates`: a recorded artifact can still fail
its gates and leave the step `waiting-human`. Guard verbs have a separate exit
contract: 0 allows, 2 denies; do not read their exit 2 as ordinary `NOT_FOUND`.

Four parsing traps from the earlier runtime checks:

- **`items` is the v2 key, never the v1 key.** `--json` (v1, the bare flag)
  names the collection after the verb — `events`, `issues`, `steps`, `runs`,
  `proposals`. `--json=v2` and `--format json` rename it to `items` and add
  `truncated`. `json.load(...)["data"]["items"]` on a bare `--json` pipe is a
  `KeyError`. The listed show verbs kept the same outer shape in the earlier
  comparison; don't assume every optional field or future version matches
  byte-for-byte.
- **`run status RUN-N` does not return the issue or step rows.** `issues` is an
  `int` count, and `steps` is a status ROLLUP —
  `[{"status": "done", "count": 32}, {"status": "skipped", "count": 30}, ...]`,
  not step objects. For real step rows use `step list --run RUN-N`, whose
  elements carry `{run, issue, step, instance, kind, attempt, status,
  expected_cost}`.
- **`total` is the match count, not the returned length.** `events list` with
  no `--tail` returned `len(events) == 100` against `total == 278`. Paging off
  `total` without checking the array length reads the same first page forever.
- **`--payload` can hand you `null`.** Artifacts of kind `findings` carry an
  array, `issue.diff` an object, and `doc`/`gap` carry no structured payload —
  `data` is JSON `null`. Type-check before subscripting.

Every serialized issue carries both `issue` and `id` with the same ID string,
on v1 and v2, including nested `sub_issues`, list rows, and mutation
responses. `.data.issue` is not a nested object.

`run status RUN-N`'s `pins` elements are `{kind, ref, sha256}` (`kind` is
`"file"` for on-disk config pins; `name@version` refs live in the DB, not on
disk). `vote show`'s `votes` elements are `{id, proposal_id, voter_name,
voter_role, verdict, confidence, domain_relevance, effective_weight, findings,
findings_json, summary, metadata, created_at}` — note `findings` is a string
and `findings_json` is frequently `null`.

<a id="command-reference"></a>

## Command & Flag Reference

These tables explain selected flag interactions and validation rules. The
generated inventory and installed help are the current mechanical inventory.
"Required in JSON mode" is distinct from an always-required flag; supply
noninteractive values explicitly rather than relying on a terminal form.

<a id="issue-commands"></a>

### `docket issue` (alias `i`) — `internal/cli/issue.go`

<a id="issue-create"></a>

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

<a id="issue-edit"></a>

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
concerns; `docket plan` uses them to split colliding work. `--scope` is a list
of path **globs** declaring what an issue is *expected* to touch — a judgment
made ahead of the work, snapshotted at activation and used by the scheduler
for mutual exclusion between steps. They differ in cardinality, semantics
(actual vs. intended), and matching rule (equality vs. glob intersection).

An issue created without `--scope` stores SQL `NULL`, not `[]`: "no scope
declared" and "declared to touch nothing" are different facts. An `issue edit`
that never mentions `--scope` leaves an earlier declaration alone.

**Reading it back:** `issue show` and `issue list` carry `scope` **when the
issue declares one**, under plain `--json` and `--json=v2`. The three states
are distinguishable on the wire: no key at all is undeclared, `[]` is
declared-to-touch-nothing, and a populated array is the declaration. A
declared scope also survives `export`/`import` intact, `NULL` included.

<a id="issue-show"></a>

#### `docket issue show [id]` — `issue_show.go`

No local flags. Watch-eligible.

Accepts one or more IDs. A single ID returns a flat object under `data`; two
or more return an array. The `issue` field is the ID string, not a nested
object: use `data.title`, not `data.issue.title`. Batch already-known IDs in
one call when their complete details are needed.

Abandoning an issue's run work leaves its tracker status unchanged. Check
`run_disposition` before treating `todo` or `review` as untouched work.
`issue show` prints the run, deciding step when present, timestamp, and
reason; `--json` carries `run_disposition` `{run, disposition, by, reason,
at}`, emitted **only when a run abandoned its work**, so an ordinary issue's
payload is unchanged. `by` is absent when an operator abandoned the issue from
outside the graph with `run abandon --issue`, where no step decided it.

It is the **latest** such ruling, keyed by ISSUE and not bound to any run: an
issue abandoned two runs ago and never resurfaced still reports the run that
stopped. It survives `issue reopen` too — a dated fact about a run, not a
claim about the issue's current status, and usually what a reopened issue
most needs. Earlier rulings stay in `events list`.

<a id="issue-list"></a>

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
| `--project` | — | string | `""` | list ANOTHER project's issues, by prefix, name, identity path, or row id |
| `--run` | — | string | `""` | list one RUN's roster — the issues bound to `RUN-N` |
| `--with-body` | — | bool | `false` | include descriptions in JSON rows; otherwise rows carry `description_bytes` |

Watch-eligible.

`--run RUN-N` lists the run's whole roster, **including `done` issues**, under
the run project's prefix. An unknown run is `NOT_FOUND`; `--run` and
`--project` together are refused because the run already defines the project.

Listing is otherwise cwd-scoped: the project the working directory resolves
to. `--project` is the escape hatch a machine-global store needs — without
it, reading another project's issues means changing directory into it, which
is impossible for a checkout not on this machine. Ids render under the NAMED
project's prefix, not the caller's, for the same reason
`events list --all-projects` does: the prefix is the only thing on the row
that says whose issue it is.

**The target resolves four ways** — exact `identity` path, numeric row `id`,
`name`, or display `prefix` (name and prefix case-insensitively) — every
column `docket project list` prints, through the same resolver `issue move
--project` and `project delete` use. The PREFIX matters most: it is the only
project identifier an issue id carries (`FLX-141`), so it is the one a reader
has actually seen. An ambiguous name or prefix is a `VALIDATION_ERROR` naming
the candidates (id, name, identity) rather than a guess.

<a id="issue-close"></a>

#### `docket issue close [id]` — `issue_close.go`

Shorthand for `move <id> done`, carrying the same lease contract (below): the
holder must supply its token, a non-holder gets `AUTH_ERROR`, and an
unclaimed issue needs none.

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--if-version` | — | int | `0` | apply only at this version; `CONFLICT` otherwise |

<a id="issue-claim"></a>

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

<a id="issue-heartbeat"></a>

#### `docket issue heartbeat <id>` — `issue_heartbeat.go`

Extends a lease you hold. Token via `DOCKET_TOKEN` or stdin. Does not change
`attempt` — a heartbeat is not a new claim.

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--ttl` | — | duration | configured | extension length |
| `--class` | — | string | `""` | executor class whose configured TTL applies |

<a id="issue-release"></a>

#### `docket issue release <id>` — `issue_release.go`

Releases a lease you hold, returning the issue to the unclaimed pool
immediately. No local flags. Token via `DOCKET_TOKEN` or stdin. `attempt`
survives; the released token never works again.

<a id="issue-move"></a>

#### `docket issue move <id> <status>` — `issue_move.go`

Two modes: a **status move** (two positional args, `id` and target status) or
a **project migration** (`<id>` plus `--project`, no status arg).

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--if-version` | — | int | `0` | apply only at this version; `CONFLICT` otherwise (enforced even on a no-op move). Status moves only — with `--project` it is a `VALIDATION_ERROR` |
| `--note` | — | string | `""` | why the issue moved; recorded as an issue **comment** in the **same transaction** as the move, so a refused move records no comment. Recorded even on a no-op move. Status moves only — with `--project` it is a `VALIDATION_ERROR` |
| `--project` | — | string | `""` | migrate the issue **and its whole sub-issue tree** to another project in the shared store |

**A status move to `done` ends a live lease**, the same contract `issue
close` (shorthand for this move) states: the holder must supply its token
(`DOCKET_TOKEN` or stdin); a non-holder gets `AUTH_ERROR` (exit 5). An
unclaimed issue needs no token.

**Migration (`--project`)** re-homes work that landed in the wrong project —
most commonly a gap recorded by `step complete --gap-file`, which lands in the
run's own project unconditionally. The target resolves in order: exact
`identity`, then numeric `id`, then unique `name`, then unique `prefix`
(name/prefix matches are case-insensitive) — the same resolver `issue list
--project` and `project delete` use; an ambiguous name or prefix is a
`VALIDATION_ERROR` naming the candidates. Labels re-map **by name** into the
target project (created there when missing, color preserved); comments,
relations, and activity ride along untouched — ids are store-wide, so nothing
referencing the issue goes stale. The response carries the target project and
the full list of migrated ids.

| Refusal | Code | Exit |
|---|---|---|
| a status arg **and** `--project` together | `VALIDATION_ERROR` | 3 |
| the issue has a parent — a sub-issue migrates with its root, never alone (migrate the root, or `issue edit --parent none` first) | `VALIDATION_ERROR` | 3 |
| the issue (or any sub-issue) belongs to a run — a run's snapshots and steps are project-scoped bookkeeping | `CONFLICT` | 4 |
| issue not found | `NOT_FOUND` | 2 |

<a id="issue-reopen"></a>

#### `docket issue reopen [id]` — `issue_reopen.go`

Only transitions if currently `done`, sets status to `backlog`.

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--if-version` | — | int | `0` | apply only at this version; `CONFLICT` otherwise |

<a id="issue-delete"></a>

#### `docket issue delete <id>` — `issue_delete.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--force` | `-f` | bool | `false` | cascade-delete sub-issues; mutually exclusive with `--orphan` |
| `--yes` | `-y` | bool | `false` | alias for `--force` |
| `--orphan` | — | bool | `false` | promote sub-issues to root; mutually exclusive with `--force` |

`--yes` is an ALIAS, not a third behavior: the confirmation it answers is a
three-way choice (cascade, orphan, cancel), and a flag meaning "yes" with
nothing to say yes to would pick one silently. `--force` names the choice;
`--yes` is the spelling scripted cleanup reaches for. An issue with no
sub-issues never asks anything and needs neither flag.

<a id="issue-log"></a>

#### `docket issue log [id]` — `issue_log.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--limit` | — | int | `20` | clamped to min 1 |

Watch-eligible.

<a id="issue-comment"></a>

#### `docket issue comment add [id]` / `docket issue comment list [id]` — `issue_comment.go`, `issue_comment_list.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--message` | `-m` | string | `""` | (`add` only) required in `--json` mode if stdin isn't piped |
| `--idempotency-key` | — | string | `""` | (`add` only) replay protection |

`comment list` has no local flags; watch-eligible.

<a id="issue-file"></a>

#### `docket issue file add/remove/list` — `issue_file.go`

`add <id> <file-path>...` and `remove <id> <file-path>...` take
`cobra.MinimumNArgs(2)` — no flags. `list <id>` takes `cobra.ExactArgs(1)` —
no flags.

<a id="issue-link"></a>

#### `docket issue link add/remove/list` — `issue_link.go`

`add <id> <relation> <target_id>` and `remove <id> <relation> <target_id>`
take `cobra.ExactArgs(3)` — no flags. `list <id>` — no flags.

<a id="issue-label"></a>

#### `docket issue label add/rm/list/delete` — `issue_label.go`

| Command | Flag | Short | Type | Default |
|---|---|---|---|---|
| `add <id> <label>...` | `--color` | — | string | `""` |
| `rm <id> <label>...` | — | — | — | no flags |
| `list` | — | — | — | no flags |
| `delete <label>` | `--force` | `-f` | bool | `false` |

<a id="issue-graph"></a>

#### `docket issue graph [id]` — `issue_graph.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--depth` | — | int | `0` | `0` = unlimited |
| `--direction` | — | string | `"both"` | `up`\|`down`\|`both` |
| `--mermaid` | — | bool | `false` | Mermaid flowchart output (ignored in `--json`) |

Watch-eligible.

<a id="plan-commands"></a>

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

JSON issue rows omit descriptions by default and include `description_bytes`.
Use `--with-body` to include full descriptions, or `issue show` to inspect
selected IDs.

<a id="next-commands"></a>

### `docket next` — `next.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--status` | `-s` | stringSlice | `nil` | default ready-set is `backlog`,`todo` if unset |
| `--priority` | `-p` | stringSlice | `nil` | repeatable |
| `--label` | `-l` | stringSlice | `nil` | repeatable |
| `--type` | `-T` | stringSlice | `nil` | repeatable |
| `--limit` | — | int | `10` | issue mode: always applies, default 10. **Step mode (`--run`): unlimited unless `--limit` is explicitly passed** — even an explicit `--limit 0` still means unlimited (`0` is the engine's no-limit sentinel); only an explicit `--limit N` with `N > 0` truncates |
| `--run` | — | string | `""` | switches to STEP mode: lists a run's offer (ready steps + staged closure) |
| `--with-body` | — | bool | `false` | include full descriptions in issue-mode JSON rows; otherwise they carry `description_bytes` |

Watch-eligible. Issue mode's `.data.issues` is always an array — `[]`, never
`null`, when nothing is ready.

Step mode (`--run RUN-N`) lists a run's dispatch offer instead. What it may
write, its refusals, and the `next row` shape are in docket-run's
[dispatch reference](../docket-run/references/dispatch.md#docket-next-in-step-mode--the-dispatch-offer).

<a id="workflow-commands"></a>

### `docket workflow` (alias `wf`) — `workflow.go`

<a id="workflow-register"></a>

#### `docket workflow register <file.toml>` — `workflow_register.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--json` | — | string | `""` | inherited; `v1` or `v2` |

Positional argument required; `-` reads the definition from stdin. Parses,
validates, and lints, then inserts at `name@version`. Identical bytes at an
existing `name@version` are an idempotent success returning the existing row;
differing bytes are `CONFLICT` (exit 4) naming both hashes.

<a id="workflow-lint"></a>

#### `docket workflow lint <file.toml>` — `workflow_lint.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--json` | — | string | `""` | inherited; `v1` or `v2` |

Positional argument required; `-` reads the definition from stdin. Runs the
exact validation `register` runs and **writes nothing** — no row, no frozen
`name@version`. The answer is `{name, version, sha256, registration}` with
`registration` ∈ `new` \| `unchanged`; different bytes at an existing
`name@version` is `CONFLICT` (exit 4), naming both hashes and the version to
bump to — this **fails** the lint rather than reporting a third
`registration` value.

<a id="workflow-deprecate"></a>

#### `docket workflow deprecate <name>@<version>` — `workflow_deprecate.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--restore` | — | bool | `false` | return a retired version to binding |

Retires one registered version from binding without deleting it; the row
stays readable and runs that pinned it are unaffected. The version is
**required** — a bare name is a `VALIDATION_ERROR` (exit 3), since it would
silently mean whichever version is highest today. An already-retired version
is `CONFLICT` (exit 4); an unregistered name or version is `NOT_FOUND`
(exit 2).

<a id="workflow-list"></a>

#### `docket workflow list` (alias `ls`) — `workflow_list.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--name` | — | string | `""` | filter to one workflow name |
| `--limit` | — | int | `50` | `0` means no limit |
| `--deprecated` | — | bool | `false` | include retired versions (`deprecated_at_ms` set); without it only versions still eligible to bind are listed |
| `--orphans` | — | bool | `false` | narrow to registered names no file in any config root declares; a per-name filesystem verdict, so `--deprecated` has no effect under it and retired rows are listed as they are |

The plain listing shows every version still eligible to bind, so a
superseded but unretired version appears beside the binding one and lineage
is visible rather than inferred. Retired versions appear only under
`--deprecated`.

A `Collection`: under `--json=v2` the payload is `{items, total, truncated}`,
where `total` is the true pre-limit count. Items carry `row_version` (the CAS
column) under v2 only; `version` is always the definition's version.

v2 items also carry **`deprecated_at_ms`**, the moment a version was retired
from binding. It is **omitted while the version still binds**, so binding
eligibility is readable from list output instead of every registered version
rendering alike. v1 does not carry it; human mode marks the row `[deprecated]`
instead.

<a id="workflow-show"></a>

#### `docket workflow show <name>[@<version>]` — `workflow_show.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--source` | — | bool | `false` | emit the stored TOML verbatim |

Omitting `@version` selects the highest registered version. A malformed ref
(`name@`, `name@x`, `name@0`) is a `VALIDATION_ERROR` (exit 3); an
unregistered name or version is `NOT_FOUND` (exit 2). `--source` returns the
exact registered bytes — the ones `source_sha256` hashes.

A retired version still resolves here, carrying `deprecated_at_ms` under
`--json=v2` (omitted while it binds) and a `status: DEPRECATED` line in
human mode. Retirement is a binding-time filter, not a retraction.

<a id="workflow-init"></a>

#### `docket workflow init` — `workflow_init.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--template` | — | string | `"standard-dev"` | `standard-dev` \| `parallel-check` |
| `--dir` | — | string | `""` | defaults to `.docket/config/workflows` |
| `--force` | — | bool | `false` | overwrite an existing file |

Needs no database, so it works before `docket init` does. Creates the
directory tree if absent. Refusing to overwrite is `CONFLICT` (exit 4) naming
the existing path; an unknown template is `VALIDATION_ERROR` (exit 3)
listing the available ones.

None of the `workflow` verbs are watch-eligible; `--watch` on any of them is a
`VALIDATION_ERROR`.

<a id="schema-commands"></a>

### `docket schema` — `schema.go`

<a id="schema-register"></a>

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

<a id="schema-list"></a>

#### `docket schema list` (alias `ls`) — `schema_list.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--name` | — | string | `""` | filter to one schema name |
| `--limit` | — | int | `50` | `0` means no limit |

A `Collection`: under `--json=v2` the payload is `{items, total, truncated}`,
where `total` is the true pre-limit count. Each row carries `name`, `version`,
`source_sha256`, `ordered_fields`, `builtin`, and `created_at_ms`; `row_version`
appears under v2 only.

<a id="schema-show"></a>

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

<a id="vote-commands"></a>

### `docket vote` (alias `v`) — `vote.go`

<a id="vote-create"></a>

#### `docket vote create` — `vote_create.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--description` | `-d` | string | `""` | required in `--json`; `"-"` reads stdin |
| `--rationale` | `-r` | string | `""` | `"-"` reads stdin |
| `--criticality` | `-c` | string | `"medium"` | `low`\|`medium`\|`high`\|`critical` |
| `--voters` | `-n` | int | `0` | required; must be `>= 1` |
| `--threshold` | — | float64 | `0.67` | must be in `(0.0, 1.0]` |
| `--created-by` | — | string | `""` | defaults to `git user.name` if empty |
| `--domain-tags` | — | string | `""` | comma-separated |
| `--files-changed` | — | string | `""` | comma-separated |
| `--escalation-reason` | — | string | `""` | |
| `--idempotency-key` | — | string | `""` | replay protection; repeat returns the original proposal |

<a id="vote-cast"></a>

#### `docket vote cast <id>` — `vote_cast.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--voter` | — | string | `""` | defaults to `git user.name` |
| `--role` | — | string | `""` | |
| `--verdict` | `-v` | string | `""` | required in `--json`; `approve`\|`approve-with-concerns`\|`reject` |
| `--confidence` | — | float64 | `0` | required (when explicitly set) in `--json`; range `[0.0, 1.0]` |
| `--domain-relevance` | — | float64 | `0` | required (when explicitly set) in `--json`; range `[0.0, 1.0]` |
| `--findings` | — | string | `""` | `"-"` reads stdin |
| `--findings-json` | — | string | `""` | `"-"` reads stdin; `{"blockers": [...], "concerns": [...], "suggestions": [...]}`. Each entry is a bare string, or `{"text": ..., "evidence": ["artifact:ARTIFACT-N", "gate:<name>"]}` naming what the finding rests on: an artifact the run holds (a bare `N` is rewritten to `artifact:ARTIFACT-N`), or a gate name any step of the run recorded a result for. Every reference is resolved against the run whose vote step or reap acknowledgment opened the proposal **before the cast records** — an unresolvable one, or a proposal no run opened, is a `VALIDATION_ERROR` naming the reference, and the seat's one cast is not spent. Entries that cite nothing pass unread and stay bare strings on the wire; the run report's `findings` section marks them `unsupported`. Mutually exclusive with `--findings` for stdin use |
| `--summary` | — | string | `""` | review summary; `"-"` reads stdin. A seat's rationale is routinely kilobytes of prose, and argv runs it past a shell first — a summary containing backticks was once expanded by the shell and stored expanded, and a voter casts once, so there is no amend path |
| `--summary-file` | — | string | `""` | read the summary from PATH; mutually exclusive with `--summary`. Use it when stdin already feeds `--findings`/`--findings-json` — stdin can feed only ONE flag per invocation, and asking two is a `VALIDATION_ERROR` naming both |
| `--metadata` | — | string | `""` | JSON object, 16 KiB cap measured on the **encoded** bag (whitespace does not count, escaping does); the seat's own unverified claim about what cast the vote — see [voting examples](references/voting.md). Stored verbatim and visible in the process list and exports; put nothing secret in it |
| `--usage` | — | string | `""` | `{"unit": n, ...}` — this seat's own spend report, recorded per seat in the `vote_usage` ledger inside the cast's transaction and summed per unit in the run report's `vote_usage` section. Same rules as `step complete --usage`: at most 32 units, finite non-negative numbers, opaque unit names. Exists because a vote step is never claimed (attempt stays 0), so the step ledger's key cannot hold per-seat rows. A relay that measures a seat's spend AFTER the cast records it with `docket vote backfill-usage` instead; the two stay distinguishable by `vote_usage.source` (v17) |

<a id="vote-commit"></a>

#### `docket vote commit <id>` — `vote_commit.go`

| Flag | Short | Type | Default |
|---|---|---|---|
| `--outcome` | — | string | `"Committed"` |
| `--escalation-reason` | — | string | `""` |

<a id="vote-close"></a>

#### `docket vote close <id>` — `vote_close.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--reason` | — | string | `""` | **required**; why the proposal is being closed without a tally |

Closes an **open** proposal whose underlying decision was made another
way — an operator authorized the guarded action directly, or the question
was superseded — and which would otherwise sit open forever. `closed` is
terminal and is **never a verdict**: no vote was counted, and the reason
lands in the proposal's `final_outcome`. Refusals: a decided proposal
(`approved`/`rejected`/`committed`/`closed`) is `CONFLICT` (exit 4); a
proposal opened by an engine **vote step** is `CONFLICT` too, naming
`docket step resolve` as the way to move a run past an uncast vote. A
closed proposal refuses further casts (`CONFLICT`), exactly as any
finalized one does.

**Three closures happen automatically**, because an open proposal is not
inert: `vote list` shows it as outstanding work, and it is what a
spawn-guard carve-out points at.

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

<a id="vote-backfill-usage"></a>

#### `docket vote backfill-usage <id>` — `vote_backfill.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--voter` | — | stringSlice | `nil` | seat whose usage is being recorded (repeatable) |
| `--unit` | — | stringSlice | `nil` | unit for the matching `--voter`; core has no default unit |
| `--quantity` | — | float64Slice | `nil` | quantity for the matching `--voter` and `--unit` |
| `--from-json` | — | string | `""` | JSON array of `{"voter","unit","quantity"}`; `-` reads stdin |
| `--source` | — | string | `"backfilled"` | who measured it; recorded on every row (v17) |

The vote-scoped back-fill. `vote cast --usage` is the seat's OWN report at
cast time; a relay that measures panel cost from its transcripts afterward
needs this verb, since tribunal seats carry a proposal id, never a step
id, so `dispatch backfill-usage` (step-keyed by design) cannot receive
them. Rows attach to each seat's **cast**: a seat that never cast is
refused by name (`VALIDATION_ERROR`), a repeat of a `(seat, unit)`
already recorded — by an earlier back-fill or by the seat itself — is
`CONFLICT`, and the whole batch is one transaction. `vote_usage.source`
(schema v17) keeps the relay's reconstruction distinguishable from the
seats' own reports.

<a id="vote-link"></a>

#### `docket vote link <proposal-id>` / `docket vote unlink <proposal-id>` — `vote_link.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--issue` | — | string | `""` | **required** on both `link` and `unlink` |

<a id="vote-list"></a>

#### `docket vote list` (alias `ls`) — `vote_list.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--status` | `-s` | string | `""` | `open`\|`approved`\|`rejected`\|`committed`\|`closed`; defaults to `open` unless `--all` |
| `--criticality` | `-c` | string | `""` | |
| `--domain-tag` | `-d` | string | `""` | |
| `--all` | — | bool | `false` | include resolved proposals |
| `--limit` | — | int | `50` | |

Watch-eligible.

<a id="vote-result"></a>

#### `docket vote result <id>` — `vote_result.go`

No local flags. Watch-eligible.

<a id="vote-show"></a>

#### `docket vote show [id]` — `vote_show.go`

No local flags. Watch-eligible.

<a id="doc-commands"></a>

### `docket doc` (alias `d`) — `doc.go`

<a id="doc-create"></a>

#### `docket doc create` — `doc_create.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--title` | `-t` | string | `""` | required in `--json` |
| `--description` | `-d` | string | `""` | `"@path"` loads a file, `"-"` reads stdin (1 MiB cap each) |
| `--type` | `-T` | string | `""` | free-form (no enum validation) |
| `--status` | `-s` | string | `""` | free-form (no enum validation) |
| `--idempotency-key` | — | string | `""` | replay protection; repeat returns the original doc |

<a id="doc-edit"></a>

#### `docket doc edit <id>` — `doc_edit.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--title` | `-t` | string | `""` | only applied when explicitly set |
| `--description` | `-d` | string | `""` | same `@path`/`-` semantics as create |
| `--type` | `-T` | string | `""` | |
| `--status` | `-s` | string | `""` | |

<a id="doc-show"></a>

#### `docket doc show [id]` — `doc_show.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--rev` | — | int | `0` | show a specific revision number |

Watch-eligible.

<a id="doc-list"></a>

#### `docket doc list` (alias `ls`) — `doc_list.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--type` | `-T` | stringSlice | `nil` | repeatable |
| `--status` | `-s` | stringSlice | `nil` | repeatable |
| `--author` | `-a` | string | `""` | |
| `--sort` | — | string | `""` | `field:direction`, e.g. `updated_at:desc` |
| `--limit` | — | int | `50` | |

Watch-eligible.

<a id="doc-delete"></a>

#### `docket doc delete <id>` — `doc_delete.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--cascade` | — | bool | `false` | also removes issue/proposal links (not the linked issues/proposals) |
| `--force` | `-f` | bool | `false` | **required in `--json` mode and non-interactive human mode** (an output-format flag is never consent); in interactive human mode it skips the confirmation prompt |

<a id="doc-link"></a>

#### `docket doc link add/remove` — `doc_link.go`

| Command | Flag | Short | Type | Default | Notes |
|---|---|---|---|---|---|
| `add <id> --issue <issue_id>` | `--issue` | — | string | `""` | **Req.** |
| `remove <id> --issue <issue_id>` | `--issue` | — | string | `""` | **Req.** |

<a id="doc-comment"></a>

#### `docket doc comment add [id]` / `docket doc comment list [id]` — `doc_comment.go`, `doc_comment_list.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--message` | `-m` | string | `""` | (`add` only) required in `--json` mode if stdin isn't piped |
| `--idempotency-key` | — | string | `""` | (`add` only) replay protection |

`comment list` has no local flags; watch-eligible.

<a id="export-commands"></a>

### `docket export` — `export.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--format` | `-o` | string | `"json"` | `json`\|`csv`\|`markdown` |
| `--file` | `-f` | string | `""` | output path; empty means stdout |
| `--status` | `-s` | stringSlice | `nil` | repeatable |
| `--label` | `-l` | stringSlice | `nil` | repeatable (OR match) |

<a id="import-commands"></a>

### `docket import <file>` — `import.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--merge` | — | bool | `false` | skip duplicates by ID; mutually exclusive with `--replace` |
| `--replace` | — | bool | `false` | destructive: clears DB first; mutually exclusive with `--merge` |
| `--yes` | — | bool | `false` | confirm `--replace`; **required** in every output mode |

<a id="board-commands"></a>

### `docket board` — `board.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--label` | `-l` | stringSlice | `nil` | repeatable |
| `--priority` | `-p` | stringSlice | `nil` | repeatable |
| `--assignee` | `-a` | string | `""` | |
| `--expand` | — | bool | `false` | show sub-issues individually instead of rolling up into parent |
| `--with-body` | — | bool | `false` | include descriptions in JSON rows; otherwise rows carry `description_bytes` |

Watch-eligible.

<a id="stats-commands"></a>

### `docket stats` — `stats.go`

No local flags. Watch-eligible.

<a id="init-commands"></a>

### `docket init` — `init.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--local` | — | bool | `false` | create a repo-local `.docket` store in the cwd instead of initializing the resolved (by default shared `~/.docket`) store |

`Annotations: {"skipDB": "true"}` — runs before any DB check/open, since its
job is to create the DB. Initializing an existing database is an idempotent
success (`created: false`) that also applies pending migrations. `--local`
opts out of the shared store; resolution prefers an existing local store over
the global one, so subsequent commands find it without any flag.

<a id="project-commands"></a>

### `docket project` — `project.go`

The shared store's tenancy surface. Under `~/.docket` every repository is a
row, and these verbs are the operator's view of that dimension. Neither is
watch-eligible.

<a id="project-list"></a>

#### `docket project list`

No local flags. Lists the store's projects — `{id, name, prefix, identity,
current}` — with the **current** invocation's project marked (`*` in human
mode). A project's `identity` is the canonical path (or git identity) that
claims it; `(unclaimed)` renders when none has. A `Collection` under
`--json=v2`. This is where `issue move --project` targets come from.

<a id="project-delete"></a>

#### `docket project delete <prefix|name|identity|id>`

No local flags. Removes an EMPTY project row. It refuses any project that
an issue, run, document, proposal, workflow, schema, or label still
references (`CONFLICT`, naming the counts), and refuses the default
project outright (`VALIDATION_ERROR`). To empty a project first, re-home
its issues with `issue move --project`. The argument takes the same four
keys `--project` does — display prefix, name, identity path, or row id —
through the same resolver; an ambiguous name or prefix is refused with the
candidates named.

<a id="project-set-prefix"></a>

#### `docket project set-prefix PREFIX`

Sets the prefix this project's issue ids render and parse with. The prefix is
**display only**: the number is the identity, global across the store. A bare
number always works, so references in old commit messages and other projects'
run records never go stale.

**An id renders under the prefix of the project that OWNS it, not the one
you are reading from**. Ids are minted from one store-wide sequence, so
two issues in two different projects can land one number apart; rendering
under the caller's own prefix instead of the owner's would let
cross-project linking confirm success while naming the wrong project's
issue.

**A prefixed reference that disagrees with the row's owner is refused**,
naming both projects, rather than silently discarding the given prefix
and resolving the bare number under the caller's own project. Cross-project
reads stay legal: a prefixed reference resolves the issue that number
really belongs to, which is what makes `issue list --project`'s output
round-trip.

A prefix is 1–8 letters (upcased); `DOC`, `RUN`, and `STEP` are reserved
for their own entities (`VALIDATION_ERROR`). A prefix ANOTHER project
already holds is refused (`CONFLICT`, naming the holder): the prefix is a
project's only discriminator in a listing, an event feed, or a report, so
two projects sharing one makes every id in the store ambiguous about its
owner. Registration derives a unique prefix from the project's name —
initials for a multi-word name, first three letters otherwise. The rest
of the invocation renders under the new prefix immediately.

<a id="version-commands"></a>

### `docket version` — `version.go`

No local flags. `skipDB` annotated.

<a id="config-commands"></a>

### `docket config` — `config.go`

No local flags. `skipDB` annotated (reads config even if no DB exists yet,
to report that fact). Watch-eligible.

<a id="config-set-get"></a>

#### `docket config set <key> <value>` / `docket config get [key]` — `config_set.go`

Engine defaults, stored in the `meta` table. **Not** `skipDB` — unlike the
bare verb these need the database. `get` with no key lists every value
with its source (`set` or `default`); under `--json=v2` the listing is a
standard `{items,total,truncated}` collection. A key that is unset AND
has no shipped default prints `<unset>` in human mode rather than an
empty line, which is indistinguishable from a key set to `""`. `--json`
is unchanged: `source` already carries the distinction there. Unknown
keys and ill-typed values are `VALIDATION_ERROR` (exit 3) at `set` time.
Both take `--global`: `set --global` writes the store-wide default rather
than this project's override, and `get --global` reads the store-wide
layer ignoring project overrides. See the [engine
configuration](references/workflows.md#engine-configuration-docket-config-setget)
for the key table, defaults, and project/store layering.
