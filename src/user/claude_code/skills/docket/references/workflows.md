# Workflow definitions and engine semantics

Read the section for the definition or routing behavior you are changing.
For corpus bootstrap, planning, and execution, use the corresponding companion
skill named in [the entry point](../SKILL.md). This file describes CLI and
engine semantics; it does not replace a companion skill’s operating policy.

Find the relevant heading before reading a large section:

- Engine configuration (`docket config set|get`)
- Workflow definitions (`docket workflow`)
- Shipped templates
- Registration is content-addressed and immutable
- Checking a draft without registering it (`docket workflow lint`)
- Retiring a version from binding (`docket workflow deprecate`)
- `docket workflow` refusals
- The definition grammar
- Engine-produced inputs
- Gates — what actually runs
- What a gate's child process sees
- Action steps — computations, not workers
- The trusted-command contract
- `aggregate` — the one builtin
- Held clusters, and what you do about one
- Fanout and joins
- Loops

## Engine configuration (`docket config set|get`)

Engine defaults live in the database, read by the claim machinery:

| Key | Type | Default | Meaning |
|---|---|---|---|
| `lease.ttl.default` | duration | `15m` | fallback lease TTL |
| `lease.ttl.<class>` | duration | (falls back to default) | per-class lease TTL. **The class is a step's `class` field, which defaults to its `executor` name** — see below |
| `attempt.max` | int ≥ 1 | `3` | maximum claims per entity |
| `budget.default` | number ≥ 0 | `0` | default per-run budget cap; 0 is unlimited. Resolved at `run start` and stored on the run, so setting it later does not re-cap a run already started |
| `budget.unit` | unit name or `""` | `""` | which recorded usage unit the run cap counts. Empty (the default) means the cap rests on the declared-cost floor alone |
| `dispatch.ttl` | duration | `30m` | how long a dispatch manifest stays open before `next` auto-abandons it |
| `dispatch.grace` | duration | `15m` | how long a claimed step may go unrecorded before it counts as a dispatch discrepancy |
| `events.retain` | duration or `0` | `0` | how long events are protected from `events prune`. `0` (the default) retains **everything**, so prune deletes nothing until a policy is set |
| `context.warn_bytes` | int ≥ 0 | `65536` | context size that triggers a warning |
| `context.error_bytes` | int ≥ 0 | `131072` | context size that triggers an error |
| `vote.rule.<name>.threshold` | float in (0,1] | (unset) | approval threshold a `vote_rule` tallies at |
| `vote.rule.<name>.criticality` | low\|medium\|high\|critical | `medium` | the proposal's criticality |
| `vote.hold.rule` | rule name or `""` | `""` | vote rule a **materialized held step** is tallied under. Empty (the default) mints held steps as `human` for one operator to decide |
| `vote.hold.voters` | comma-separated names or `""` | `""` | who casts on a materialized held step. Empty (the default) mints held steps as `human` |

A step without an explicit `class` uses its executor hint as the class.
Declare `class = "read"` or `class = "write"` to configure those keys;
setting `lease.ttl.read` cannot affect an unrelated class. Class names are
opaque. A finite `[limits] max`, not the word "write," activates reap
acknowledgments and class headroom holds. Reaping fences database authority
but does not stop an operating-system process.

`docket config set lease.ttl.<class>` **warns** when no registered workflow
declares that class, naming the ones that do; it does not refuse.

```bash
docket config set lease.ttl.write 45m
docket config get lease.ttl.write --json=v2     # {"key":...,"value":"45m","source":"set"}
docket config get                            # every key, with its source
```

`source` is `set` or `default`, distinguishing "nobody configured this" from
"configured to the same value". An unknown key or a value of the wrong type
is a `VALIDATION_ERROR` (exit 3) at `set` time. The class in
`lease.ttl.<class>` is an opaque string; docket never interprets it.

Config is **layered per project**: a read resolves the current project's
override, then the store-wide value, then the built-in default (the first two
both report `source: set`). `config set --global` writes the store-wide
default instead of this project's override; `config get --global` reads the
store-wide values, ignoring this project's overrides.

**Vote rules.** A `type="vote"` step names a rule instead of passing flags. A
rule *exists* iff its `.threshold` is set — criticality has a default, so it
cannot be the existence test:

```bash
docket config set vote.rule.majority.threshold 0.6
docket config set vote.rule.majority.criticality high
```

`<name>` is opaque, like the lease class. A step whose `vote_rule` names an
unregistered rule is refused at `workflow register` (V26), naming the rule
and listing the registered ones. `required_voters` comes from the step's own
`voters` list, not the rule: the rule sets *how strictly to tally*, the step
sets *who casts*.

**Held steps by tally.** A materialized `<step>-held` step is the one row in a
run no author wrote, so it has no `[[step]]` table to carry `voters` and
`vote_rule`. `vote.hold.rule` and `vote.hold.voters` supply them instead:

```bash
docket config set vote.rule.panel.threshold 0.6
docket config set vote.hold.rule panel
docket config set vote.hold.voters alice,bob,carol
```

**BOTH keys are required; unset is a strict no-op.** With either missing,
holds are minted `human`, and one operator approves or rejects them. With
both set they are minted `vote` and flow through the ordinary vote lifecycle.
The escalation is one-directional:

- **pass** — the computed value stands, identical to `step approve` on the
  cluster. The payload records `operator_resolved` and the aggregate resumes.
- **anything else** — the step **parks** at `waiting-human`, and an operator
  answers with `step approve` (including `--value`) or `step reject`. A tally
  can confirm the engine's own computation but cannot overrule it.

The minted kind persists: config supplies the roster, the step row supplies
the question's type. Editing or clearing these keys mid-run changes who casts
on holds minted *after* the edit, never an already-open question.

## Workflow definitions (`docket workflow`)

A **workflow** is a declarative description of the steps a piece of work goes
through: what runs, in what order, what each step needs from earlier ones,
and what happens on failure. It is a TOML file registered into the database;
nothing about it is specific to any kind of work or worker.

For standalone authoring, start from a shipped template, lint the draft, then
register when ready. Shared-corpus bootstrap follows its companion skill
instead: activation registers schemas before workflows, and registering
early would freeze a version before approval.

```bash
docket workflow init --template standard-dev
# → wrote .docket/config/workflows/standard-dev.toml
docket workflow lint .docket/config/workflows/standard-dev.toml --json=v2
docket workflow register .docket/config/workflows/standard-dev.toml --json=v2
docket workflow list --json=v2
docket workflow show standard-dev --json=v2
```

Registration only stores, validates, and makes a workflow inspectable;
nothing runs it yet. A repo that never registers one runs no workflow.

### Shipped templates

| Template | Shape |
|---|---|
| `standard-dev` | two steps — run the checks, then have a person approve. One fenced-command gate, no fanout. |
| `parallel-check` | prepare → several checks in parallel → summarize → verify. Fanout with a join quorum. |

Both templates are ordinary TOML definitions subject to the same validation
as a hand-authored workflow.

### Registration is content-addressed and immutable

A registered `name@version` is frozen:

| Second registration of… | Result |
|---|---|
| the same bytes | success, returns the existing row, changes nothing |
| **different** bytes at the same `name@version` | `CONFLICT` (exit 4), naming both hashes |
| any bytes at a new `version` | an ordinary registration |

To change a workflow, bump `[pipeline].version`: a run that pinned
`name@version` cannot have the definition swapped underneath it.

`register` accepts `-` to read stdin:

```bash
generate-workflow | docket workflow register - --json=v2
```

### Checking a draft without registering it (`docket workflow lint`)

Registration is a persistent write: it inserts a row and freezes a
`name@version`. `lint` runs the identical validation and **writes nothing**:

```bash
docket workflow lint .docket/config/workflows/standard-dev.toml --json=v2
# → {"name":"standard-dev","version":1,"sha256":"…","registration":"new"}
generate-workflow | docket workflow lint - --json=v2     # `-` reads stdin
```

It is the **same pipeline `register` runs**, call for call: grammar and step
rules, vote rules against the config registry (V26), and threshold fields and
literals against the registered schemas. The two report identical verdicts on
the same bytes.

The registry is **consulted, never written**; the verdict says what a real
register would do:

| `registration` | Meaning |
|---|---|
| `new` | nothing holds this `name@version`; a register would insert |
| `unchanged` | the same bytes are already registered; a register would be an idempotent success |
| *(refusal)* | **different** bytes hold this `name@version` — `CONFLICT` (exit 4), naming both hashes and the version to bump `[pipeline].version` to |

**The conflict case fails the lint rather than reporting a third outcome.**
This is the trap `lint` exists to catch: an edited file at a frozen
`name@version` would otherwise validate cleanly and then refuse the *whole
activation* the next time a run starts.

### Retiring a version from binding (`docket workflow deprecate`)

A registered **name** binds forever at its highest version; deleting its TOML
does not unregister it, since nothing removes a `workflows` row. `deprecate`
retires one version from binding without deleting it:

```bash
docket workflow deprecate standard-dev@1 --json=v2
docket workflow deprecate standard-dev@1 --json=v2 --restore   # back into binding
```

The row survives and stays fully readable: `workflow show` renders it,
`--source` emits the exact registered bytes, and a run that already
**pinned** it still resolves it and completes. Only its candidacy for new
bindings stops. Matching picks the highest **non-retired** version of each
name, so retiring the top version falls back to the one beneath it, and
retiring every version of a name takes that name out of routing entirely.

A retired version reports `deprecated_at_ms` under `--json=v2` and prints
`[deprecated]` in human mode. See `workflow list` in [the CLI reference](../reference.md).

### `docket workflow` refusals

| Situation | Code | Exit |
|---|---|---|
| Grammar, validation, or lint failure | `VALIDATION_ERROR` | 3 |
| `payload` names a schema that is not registered | `VALIDATION_ERROR` | 3 |
| A threshold names a field its declared schema does not declare | `VALIDATION_ERROR` | 3 |
| A threshold literal is not a value its declared schema allows | `VALIDATION_ERROR` | 3 |
| An ordered comparison (`>=`, `>`, `<=`, `<`) on a field with no `ordered_enum` | `VALIDATION_ERROR` | 3 |
| A step emitting the reserved kind `gate-results` or `vote-record` | `VALIDATION_ERROR` | 3 |
| `<step>.vote-record` naming a producer whose `type` is not `"vote"` (V11) | `VALIDATION_ERROR` | 3 |
| `issue.linked.<relation>.<kind>` naming `*`, `gate-results`, or `vote-record` as the kind | `VALIDATION_ERROR` | 3 |
| Definition file not found | `NOT_FOUND` | 2 |
| Re-registering different bytes at an existing `name@version` | `CONFLICT` | 4 |
| `workflow lint` on a draft whose `name@version` is registered with different bytes | `CONFLICT` | 4 |
| `workflow show` on an unregistered name or version | `NOT_FOUND` | 2 |
| `workflow init` target exists without `--force` | `CONFLICT` | 4 |
| `workflow deprecate` without an explicit `@version` | `VALIDATION_ERROR` | 3 |
| `workflow deprecate` on an already-retired version | `CONFLICT` | 4 |

### The definition grammar

A definition has `[pipeline]`, an optional `[match]`, an optional `[limits]`,
and one or more `[[step]]` tables. **Unknown keys are an error**, naming the
key and its step — this catches a typo like `max_attempt` silently taking a
default.

```toml
[pipeline]
name    = "standard-dev"       # required; runs pin name@version
version = 1                    # required, integer >= 1
description = "…"              # optional

[match]                        # which issues bind to this workflow
                               # evaluated over the highest non-retired version of each name
kind          = ["task", "bug"]
labels_any    = ["…"]
labels_all    = ["…"]
unless_labels = ["…"]          # evaluated last and wins

[limits]                       # per executor CLASS, not per step
write = { max = 1, lease_ttl = "45m", max_step_duration = "2h" }
read  = 4                      # bare int is shorthand for { max = 4 }

[[step]]
name  = "check"
after = []                     # [] means root; see below
executor = "author"
class = "write"                # accounted under [limits].write above
emits = "check-report"
```

**`[limits]` keys, and what each bounds.** A class is an opaque string; these
are the only three things a bound on one does.

| Key | Bounds |
|---|---|
| `max` | how many steps of the class may be `claimed`/`running` at once. A **finite** `max` is also what makes the class write-class for [dispatch reap acknowledgments](../reference.md#docket-dispatch--dispatchgo) — a class with no `max` gets neither ack rows nor a headroom hold |
| `lease_ttl` | the lease a claim of this class takes, overriding `docket config lease.ttl.<class>` |
| `max_step_duration` | a **schedule-to-close** bound measured from the claim, **independent of heartbeats** |

A step past `max_step_duration` is reaped **even with a live lease and a
fresh heartbeat** — the difference from a lease TTL, and how a runaway holder
is stopped from renewing forever. It is a `[limits]` key on the workflow
class; there is no `docket config` key for it.

**Both reaps are scoped to an ACTIVE run.** A lease that lapses while a run
sits in `waiting-human` is not reaped, nor is a step past its
`max_step_duration` there: on a run that is not active nothing would be
re-offered anyway, so the reap would only clear a live worker's lease and
take a write-reap hold on its class for no benefit. This is a **suspension,
not an exemption** — no expiry is rewritten, so the first `next` after the
run returns to `active` reaps what came due meanwhile. A run parks when *any*
step is parked, leaving that step's siblings legitimately `claimed` at
`waiting-human`.

`[[step]]` fields, in full:

| Field | Type / default | Meaning |
|---|---|---|
| `name` | string, required, unique in workflow | step identity |
| `executor` | string (opaque hint) | a worker step; docket never interprets the value |
| `action` | string | a deterministic computation step |
| `type` | `"human"` \| `"vote"` | an operator gate |
| `fanout` | [hints] | expands to one parallel sibling per entry |
| — | | **exactly one** of `executor` / `action` / `type` / `fanout` per step |
| `class` | string, default = the `executor` value | the key `[limits]` accounts against |
| `emits` | artifact-kind string | **required on executor steps**; what the step records |
| `payload` | `name@version` | a registered payload schema; the step's `--payload-file` is validated against it at `step record`, from the bytes the run pinned |
| `voters`, `vote_rule` | [hints], name | **required on `type="vote"`**, forbidden elsewhere |
| `after` | [step names], **required** except on the first step and `loop = true` steps | predecessors; `[]` means root |
| `inputs` | [`"<step>.<kind>"` \| `"<step>.*"` \| `"<step>.gate-results"` \| `"<step>.vote-record"` \| `"issue.body"` \| `"issue.diff"` \| `"issue.linked.<relation>.<kind>"` \| `"issue.latest.<kind>"`] | artifacts delivered to the step |
| `holds_tree` | bool, **default true** | whether this step occupies its issue's scope while it runs. Scope exclusion consults it, and it decides whether the step's completion records an `issue.diff` |
| `gates` | [name \| `{name, source="fence:<tag>", pre=bool}`] | checks; `pre = true` runs at claim |
| `params` | table | arguments defined by the selected action’s contract; built-in aggregate keys are interpreted and validated |
| `min_siblings` | int, default = all | how many fanout siblings the join needs |
| `threshold` | table: routing → predicate | routing computed from the step's results |
| `on_fail` | `"fix-loop"` \| `"waiting-human"` \| `"skip"` \| `"abandon-issue"`; default `"waiting-human"` | where a failure routes. **Required explicitly on `type="human"` and `type="vote"` steps** |
| `loop` | bool, default false | marks a loop-body step |
| `serves` | [step names], default = every `fix-loop`-capable step | scopes this `loop = true` step (and its `after_loop` chain) to the named steps' **loop cluster** — entry fires only the bodies serving the step whose routing actually triggered it (the **trigger**). Omitted or empty means "serves every trigger," one cluster for the whole workflow |
| `after_loop` | step name | where execution re-enters after a loop body |
| `max_attempts` | int ≥ 1 | per-instance retry budget |
| `max_fix_loops` | int ≥ 0 | round budget, checked against the issue's one loop-ordinal counter. Declared on a step with no `serves`, it is the **issue-level ceiling**. Declared on a `serves`-scoped body, it is that **cluster's own** budget, counted over ordinals holding that cluster's instances — the issue-level ceiling still governs on top of it |
| `pass_floor` | `{ field, at }`, optional; requires `payload`, and `at` must be a value of `field`'s declared order (V37/V37a) | exit bar on a `pass` routing: if the routing resolves to `pass` but the step's recorded payload holds an element whose `field` value sits at or above `at`'s position and is neither `held` nor `operator_resolved`, the step parks `waiting-human` instead of exiting, naming `--as override-pass` and `--as fix-round` as the ways out. Opaque tokens compared by position *(engine commit 2c58fc9; present in the installed nightly-90 build, unused by the corpus as of 2026-09-10)* |
| `max_stalled_rounds` | int ≥ 0, default 0 (never fires); only on a step that can route `fix-loop` and records an artifact (V38) | non-convergence tolerance over this step's routed volume: a `fix-loop` entry after that many consecutive rounds where the recorded payload's element count never fell below the smallest count any earlier round recorded is refused — counter restored, nothing instantiated, `waiting-human` naming `--as fix-round`. A shrinking set never parks; one oscillating around a floor does. The first measured round is only a baseline, so a bound of N needs N+1 measured rounds and fires on loop entry N+1: under `max_fix_loops = 2` only `= 1` can ever fire, on the second entry, when round 1's count did not fall below round 0's *(same commit and status; unused by the corpus — measured on RUN-98, converging loops ran 9→8→3→3, 7→5→3→5 and 2→2→0→0 clusters, and `= 1` would have parked the third one round before it converged)* |
| `expected_cost` | number ≥ 0, default 0 | the step's contribution to the run's budget floor, accrued **per claim**. Per expanded sibling on a fanout — four siblings accrue four times, no proration |
| `when` | predicate over `kind` / `labels` — `<kind\|labels> <==\|!=\|contains> <value>` or `labels contains-any (a, b, c)` clauses, joined by `and` throughout or `or` throughout | step is skipped when false. `or` needs one clause to hold, `and` needs all; mixing the two connectives in one predicate is rejected at register time (no parentheses, so `a and b or c` has no defined reading). `contains-any` holds when the list intersects the issue's labels, the step-level `labels_any` — so `kind == task and labels contains-any (security-change, security)` combines kind and labels without mixing connectives. The engine also accepts `labels contains_any [a, b, c]` (underscore, square brackets), used by spec-doc.toml, but the comma/nesting/whitespace constraints below were verified only against the paren form |
| `metadata` | opaque table | recorded and delivered verbatim |
| `packet` | list of paths, relative to `.docket/config/` | files inlined into the step's rendered work packet, **in declared order**. Each must be pinned by the run (they are, automatically, if they live under `.docket/config/`); an entry the run did not pin is refused **at activation**. An entry may carry the `{executor}` token, substituted with that sibling's executor hint — which is how one `fanout` step gives each sibling a different file. Docket reads their bytes and never interprets them |

**`packet` inlines files; it never points at them.** The rendered packet
carries each file's **body**, delimited and labeled with its path and hash,
so a worker receives one document rather than a list of things to go read.
Bytes are admitted only when they hash to what the run pinned: a file edited
after activation is `CONFLICT` (exit 4) naming **both** hashes, and one
deleted is `NOT_FOUND` (exit 2). This keeps a packet reproducible: same step,
same packet, byte-identical, even mid-run.

A packet file may declare more files in a `packet_includes:` frontmatter
list, inlined immediately after it. **That is the only frontmatter key
docket reads** — every other key is ignored, not validated or surfaced —
and includes are followed **exactly one level deep**. A malformed
`packet_includes` is `VALIDATION_ERROR` at render, naming the file; a
declared include that is missing or unpinned is refused rather than silently
omitted.

#### Engine-produced inputs

The input forms below resolve to engine records or activation-pinned linked
artifacts rather than an ordinary local step artifact.

`issue.body` is the activation snapshot. `issue.diff` is the run's computed
VCS diff, recorded only at the completion of a step that holds the tree
(`holds_tree`, default true, the same field scope exclusion reads). A
non-holding step records nothing; its consumers resolve to the artifact the
last **holding** step recorded, the reviewed object pinned at the moment the
change existed, rather than a diff recomputed from a live tree that may have
changed. Action, human, and vote steps record no diff; with no diff artifact
at all, the input resolves to an **empty diff**, never an error and never a
live `git diff`.

**The bundle carries a machine-readable target ref.** Context assembly lifts
the resolved `issue.diff` artifact's round record onto the bundle as
`target_sha` (the commit the diff's tree stood at) and `target_worktree` (the
producing record's declared worktree path, valid while that checkout is
still on disk; swept at integration). Both are omitted entirely when the
resolved diff carries no round record. The default packet template states
them in its header, so a reviewing consumer reads the tree from these fields
rather than a prose convention in the change-summary's first line.

`<step>.gate-results` is the named step's **recorded** gate results, served
from the ledger rather than re-run — one input per `done` producer instance,
carrying a JSON array in the recorded gate-result shape (`gate`, `ordinal`,
`argv`, `exit`, `duration_ms`, `output`, `truncated`, `verdict`, `pre`,
`reason`), the same shape a claim response's `pre_gates` carries. Instance
selection mirrors ordinary artifact resolution (same issue, `done` only,
ordinal-scoped with the per-input fallback, siblings in index order), with
one departure: the **requesting step admits itself regardless of status**, so
a self-declared `<self>.gate-results` reads the step's own claim-time
`pre = true` rows (which commit before context assembly, while the step is
still `claimed`). Completion-side rows, not yet recorded at claim, show up
as the empty array.

```toml
inputs = ["implement.change-summary", "implement.gate-results"]
```

The producer **must be a step of this workflow**, but need not declare gates:
a producer that recorded none resolves to an **empty array**, not an absent
input, since "this step ran no checks" is an answer a consumer can act on
while a missing input reads as a resolution failure. Gates can also arrive
from a `fence:` source the definition does not enumerate, so requiring a
declaration would refuse correct workflows. `gate-results` is a **reserved
kind**: a step emitting it is refused at `workflow register` (V11a), since
the engine-served form would shadow any artifact of that kind.

`<step>.vote-record` is the named **vote step's** recorded tally, as JSON:
the proposal id, its status, the weighted score, and every cast (`voter`,
`role`, `verdict`, `confidence`, `rationale`, `findings`) — mirrors
`gate-results` in shape and instance-selection (same issue, `done` vote-step
producers only, highest matching ordinal). A vote step an operator moved a
run past with `docket step resolve` before any proposal opened contributes
**no input at all**, not an empty record. `vote-record` is a reserved kind
like `gate-results`: a step declaring `emits = "vote-record"` is refused at
register time, and so is `<step>.vote-record` naming a producer whose `type`
is not `"vote"` (rule V11).

```toml
inputs = ["gate.vote-record"]
```

`issue.linked.<relation>.<kind>` is a **cross-issue** input: the latest
recorded artifact of `<kind>` held by each issue this issue is linked to by
`<relation>`, resolved and **pinned by artifact id at activation**, in the
same transaction that snapshots the issue. `<relation>` is an existing
relation type or its inverse token — "linked" addresses either end of an
ordinary `docket issue link add` edge, not a new relation kind:

| Canonical (forward) | Inverse |
|---|---|
| `blocks` | `blocked_by` / `blocked-by` |
| `depends_on` / `depends-on` | `dependency_of` / `dependency-of` |
| `relates_to` | — (symmetric; its own inverse) |
| `duplicates` | `duplicate_of` |

```toml
inputs = ["issue.body", "issue.linked.depends_on.ux-spec"]
```

There is no separate "linkable" marking and no project scoping — any recorded
artifact on any issue this one is linked to is reachable, even across
projects. `<kind>` names exactly **one** kind; a wildcard (`*`) is refused at
register time, and so is `gate-results` or `vote-record` as the named kind
(no linked issue could ever hold either). Resolution happens **once, at
activation**: an artifact recorded on the linked issue afterward never
reaches the bundle, and every linked issue holding the kind resolves,
ordered by linked-issue id. Activation refuses loudly (`VALIDATION_ERROR`,
exit 3) rather than binding an empty input — an issue with no edge of
`<relation>` at all, or whose linked issue(s) hold no artifact of `<kind>`,
fails the **whole** activation, naming `docket issue link add` as the way
out.

**`after` is required, and `after = []` is how you declare a root.** A step
that forgets `after` would otherwise silently become a root and run first.
Only the first step and `loop = true` steps may omit it.

**Every gate step must declare `on_fail` explicitly** — `type="human"` and
`type="vote"` alike (V13a). The default is `waiting-human`, so a gate that
declares nothing has a routing its author never chose.

**A `type="human"` step additionally may not route rejects to
`waiting-human`** (V13): that would park the issue on the resolution of the
very thing that just rejected it, a deadlock. Legal values there are
`fix-loop`, `skip`, and `abandon-issue`.

**A `type="vote"` step may route to `waiting-human`**, and often should: on a
vote gate that routing is the escalation — a tally that did not reach its
threshold decided nothing, so the question passes to an operator who has not
been asked yet. All four values are legal there.

`threshold` predicates have the shape `agg(field op literal)` with
`agg ∈ {any, all, count>=n}` and `op ∈ {==, !=, >=, >, <=, <}`; routings are
`fix-loop`, `waiting-human`, `pass`, or a step name (which interposes that step
as a gate). Routings are evaluated **top to bottom, first match routes**, and
no match routes `pass`.

**An interposed gate runs only when routed to.** A step named as a step-name
routing target — authored with `after = [routing-step]` — is latched by
readiness until a routing predecessor's **recorded** routing names it. When
the routing resolves anywhere else, it is terminalized `skipped` in the same
routing transaction, so joins and issue completion resolve without it. A
`next --run` offer may still carry such a gate in its staged closure, marked
`conditional`: confirm the predecessor actually routed to it before spawning
anything for it.

**Fields and literals are opaque tokens to docket, but checked against your
schema.** When a step declares a `payload`, `workflow register` verifies
that every predicate's field is one the schema declares, that every literal
is a value that field accepts, and that any ordered operator (`>=`, `>`,
`<=`, `<`) names a field the schema marks `ordered_enum`. Docket learns that
`high` comes after `medium` because your document said so; it holds no
opinion about what either word means.

A step with a `threshold` and **no** `payload` is legal: equality has never
needed an order. An ordered comparison over such a field **parks the step**
`waiting-human` with a reason naming the predicate, rather than docket
guessing an order.

**Executor hints are opaque.** `executor`, `fanout` entries, `voters`, and
`class` are strings docket stores, echoes back, and uses as map keys. There
is no registry of known executors and no behavior keyed on the value: role
names, team names, or people's names there mean what you intend. `metadata`
remains opaque. `params` follows the selected action's contract: docket
reads `output`, and the built-in `aggregate` validates and interprets its
declared keys. See [Action steps](#action-steps--computations-not-workers).

**`when`'s list form has constraints the table entry above doesn't show.**
`contains-any` needs at least one element — `labels contains-any ()` is
rejected — with no leading, trailing, or doubled commas and no nesting.
Whitespace around elements and parens is fine; whitespace inside a bare
value is not. Values in either clause form may be quoted (`kind == "bug"`,
`labels contains-any ("docs", "urgent")`) or bare — they read the same.
`contains-any` is **`labels`-only**: `kind contains-any (...)` is not a form
the grammar defines. The mixed-connective refusal (rule V22, register time)
reads:

```
step %q: `when` %q mixes `and` and `or`; a predicate must join its
clauses with one connective throughout, because the grammar has
no precedence rule and no parentheses to disambiguate the mix
```

### Gates — what actually runs

A gate is a check a step must pass. It comes in two spellings:

```toml
gates = ["tests"]                                       # a named gate
gates = [{ name = "checks", source = "fence:checks" }]  # commands from the issue body
gates = [{ name = "measure", pre = true }]              # runs at claim, not at record
```

**A gate name is an opaque string.** Docket looks it up in your trust store and
never interprets it — there is no registry of known gates, no gate whose name
has behavior, and no default gate.

**Every gate needs a matching trust entry or it does not run** (see [trust
contracts](../reference.md#docket-trust--trustgo)). A gate declaration does
not authorize adding trust; apply the companion policy and existing user
authorization. An unmatched gate is recorded `verdict: "unmatched"` with
null `argv` and null `exit`, nothing spawns, and **the step fails** and
routes per `on_fail`.

| Spelling | Where the command comes from |
|---|---|
| `"name"` or `{name}` | the trust entry's own argv — the entry *is* the command |
| `{name, source="fence:<tag>"}` | fenced blocks in the issue body whose info string is `<tag>`, harvested and hashed at activation, one command per line |
| `{name, pre=true}` | runs at **claim**, with its result in the context bundle rather than judging the step |

A fence tag is opaque too: `source = "fence:checks"` harvests ```` ```checks ````
blocks and docket never knows what the word means. Fenced commands are matched
**per line**, each its own decision with its own recorded result.

Gate results are recorded as `{gate, ordinal, argv, exit, duration_ms, output,
truncated, verdict, pre, reason}` with
`verdict ∈ {pass, fail, unmatched, skipped}`. A `pre = true` gate's results ride
in the claim response under `context.pre_gates` — present only when the step
declares them. A failing pre-gate does **not** refuse the claim: it is a
measurement the step consumes, and the judging is the step's job. A later step
reads the same rows by declaring `inputs = ["<step>.gate-results"]` (see
*Engine-produced inputs* above).

**`skipped` means nothing was measured**, a different fact from `fail`. A
gate measures the tree its step is about to judge; when that tree cannot be
bound, docket **records `skipped` rather than measuring a different tree**.
A pass collected in the shared checkout, while the change under review lives
elsewhere, is a verdict with no evidence value that still reads as green.

Docket tries to avoid the skip first. A worktree that has been swept
(integration removes them between waves) is **reconstructed from the object
database**: the commit is still there, so the tree is rebuilt in a throwaway
detached checkout, measured, and removed, with those rows saying so in their
`reason`. Only when the commit itself is unreachable does the gate skip, and
the reason names the sha to fetch.

A step whose gates recorded `skipped` **parks at `waiting-human`**, not its
`on_fail`: nothing is known about the change, so a fix loop or a judge panel
would deliberate over an infrastructure condition rather than the change
itself. `skipped` is counted in its own column in `run report`, beside
`pass` and `fail`.

#### What a gate's child process sees

The child environment is **constructed, not inherited**: a variable is present
only because the allowlist names it (`PATH`, `HOME`, `USER`, `LOGNAME`, `SHELL`,
`LANG`, `LC_ALL`, `LC_CTYPE`, `TZ`, `TMPDIR`, `SSL_CERT_FILE`, `SSL_CERT_DIR`,
`XDG_CACHE_HOME`). An unset parent variable is omitted rather than set empty.
`DOCKET_TOKEN` and `DOCKET_PATH` are denied outright — a capability token in a
child would convert code execution into engine authority — and a spawn aborts
if either is ever found in the constructed set.

Docket then **sets** these itself:

| Variable | Value |
|---|---|
| `TERM` | always `dumb` — a gate's output is captured, not displayed, and inherited ANSI escapes would pollute the run report |
| `CI` | always `1`, the near-universal "non-interactive" convention |
| `DOCKET_GATE` | the gate name (opaque to core) |
| `DOCKET_REPO` | the repository root |
| `DOCKET_ISSUE` | `DKT-N`, the issue the gated step belongs to |
| `DOCKET_SCOPE` | the issue's declared scope globs, **newline-joined**; absent entirely when there are no globs to carry |
| `DOCKET_GATE_NETWORK` | the trust entry's declared hosts, comma-joined — set only when it declared any |

`DOCKET_ISSUE` and `DOCKET_SCOPE` let a **diff-shaped** gate evaluate the
change it is actually gating instead of the whole dirty tree. The globs are
newline-joined rather than JSON because the consumer is a shell check reading
its own environment, where `while IFS= read -r glob` needs no parser.
**Absent is not empty**: an issue that declared no scope gives the check no
narrower answer than the tree, rather than docket inventing one.

The variable carries globs or nothing, so declaring no scope and declaring
an empty one look alike here: a declared-but-empty scope leaves
`DOCKET_SCOPE` unset too, rather than setting it to the empty string.
Elsewhere the two stay distinguished (the `scope` key, and the activation
lint that warns about the first and not the second). A gate that must tell
them apart reads `docket issue show`, not its environment.

There is no way to extend the allowlist: no flag, config key, or trust-entry
field.

### Action steps — computations, not workers

An `action` step has no worker. It declares a computation and `params.output`,
which is the artifact kind it produces:

```toml
[[step]]
name    = "reconcile"
after   = ["synthesize-findings"]
action  = "aggregate"
inputs  = ["synthesize-findings.findings"]
payload = "findings@10"
params  = { field = "severity", method = "max", hold_spread = 3, output = "findings" }
```

**Nothing claims an action step.** `docket step claim` refuses one with
`CONFLICT` — "resolved by the engine, not by a worker" — the same way it
refuses a `human` or `vote` gate. The engine runs it, records its artifact,
and routes. It still appears in `docket next --run` so a dispatcher can see
what a run is doing; the row carries no `executor` to spawn.

**Resolution is builtin-first.** `aggregate` is the one computation docket
performs itself; every other action name is looked up in your trust store
and run as a **user-trusted command**, through the same matching, argv
resolution, env allowlist, timeout, capture, and repo containment a gate
goes through, with no exceptions and no second execution path. The name
`aggregate` is reserved, so a trust entry cannot shadow it — `workflow
register` refuses rather than leaving you to wonder why your command never
ran.

An unmatched action name records `verdict: "unmatched"` with null `argv` and
null `exit`, spawns nothing, and **fails the step**, which routes per
`on_fail`.

#### The trusted-command contract

| Direction | Shape |
|---|---|
| **stdin** | the step context object, exactly as `docket step context --json` emits it — one JSON document, then EOF |
| **stdout** | one JSON object `{"body": "<string>", "payload": [ … ]}`. `body` defaults to `""`, `payload` to `[]`. No other keys, one document |
| **exit 0** | success; the artifact records with `kind = params.output` |
| **non-zero exit** | failure; the step routes per `on_fail`, the captured output is recorded, and **no artifact is written** |
| **unparseable stdout on exit 0** | failure, with the first 200 bytes quoted back with control characters escaped |

An object rather than "stdout is the payload", because every artifact has a
human-readable body and a command needs a channel for it. `stderr` is the
diagnostic stream and is what `action_results.output` records; it cannot corrupt
the document docket parses.

If the step declares a `payload`, the produced payload is validated against that
schema exactly as a worker's is. A failure there is a step failure routed per
`on_fail`, not a refusal to a caller — there is no caller.

Every attempt is recorded as an **action result**:
`{action, ordinal, argv, exit, duration_ms, output, truncated, verdict, builtin,
reason}` with `verdict ∈ {pass, fail, unmatched}`. `builtin` marks a computation
docket performed itself, and `argv`/`exit` are null there because nothing
spawned. A `flaky` trust entry re-runs and each attempt gets its own row, with
the **last** one deciding the routing.

#### `aggregate` — the one builtin

`aggregate` reduces clustered values to one value per cluster, over an order
**your schema declares**. It works for severities, priorities, tiers, T-shirt
sizes, or ripeness grades alike: docket knows position, never significance.

| Param | Type | Required | Meaning |
|---|---|---|---|
| `field` | string | yes | the payload property to reduce |
| `method` | `median` \| `max` \| `min` | yes | the reduction |
| `hold_spread` | integer ≥ 0, default 0 | no | hold when the spread reaches this; `0` never holds |
| `output` | string | yes | the artifact kind this step produces |

No other keys are accepted — a typo'd `method = "medain"` is refused at
`workflow register`, not discovered hours into a run.

An `aggregate` step **must** declare `payload = "name@version"`, and that
schema must mark `params.field` as `ordered_enum`. Median, max, and min are
defined only over an order, so an aggregate without one could never compute.

**The input.** The builtin reduces the **concatenated payloads of the step's
declared `inputs` artifacts**, resolved by the ordinary input rules (`done`
producers only, in declared order, scoped to the step's own loop ordinal). So
`inputs = ["synthesize-findings.findings"]` means "reduce what
`synthesize-findings` recorded". `inputs` must be non-empty on an
`aggregate` step, refused at `workflow register`.

Each element of that payload is one cluster. The element's `field` is either an
**array** of values — the cluster's members — or a **scalar**, which is a
one-member cluster. Every other key of the element is carried through verbatim.

Over a flat payload of scalars, `aggregate` is the **identity**: every value
passes through, nothing is held, nothing is demoted. You can introduce
clustering later without a behavior change anywhere else.

**The even-count rule.** With members sorted by their position in your declared
order, the reduction is `m[0]` for `min`, `m[len-1]` for `max`, and
`m[(len-1)/2]` for `median` — **the LOWER of the two central values when the
count is even**. So a cluster of `{low, blocker}` medians to `low`.

Docket does not know which end of your order is worse: taking "the more
severe of the two" would be docket holding an opinion about severities,
wrong for a `confidence` or `ripeness` enum. The lower median is the
standard choice for ordinal data where no average exists.

**If that is the wrong end for your order, say so in the schema.** Add
`"conservative_end": "upper"` beside the `ordered_enum` annotation and that
field's even-count median ties resolve toward the top of the declared order
instead — `{low, blocker}` medians to `blocker`. Declare nothing and the
lower median is unchanged. See [The `conservative_end`
annotation](schemas.md#the-conservative_end-annotation).

The direction moves the **median tie and nothing else**: `min` and `max`
already name an end explicitly, and an odd-count median has no tie to
break. To get the top of the order in *every* case, not only on ties, use
`method = "max"` instead.

**Spread and holds.** `spread` is the distance between the extreme members'
**positions** — so with `["info","low","medium","high","blocker"]`, both
`{low, high}` and `{low, medium, high}` have spread 2. A cluster holds when
`hold_spread > 0 && spread >= hold_spread`.

**The demotion trail.** When the computed value's position is strictly below
its highest member's, the output records `demoted_from` with the value not
taken. When nothing was demoted the key is **absent**, not empty. `max`
never demotes.

**The output**, one element per input element, validated against both the
shipped `aggregate@1` schema and your own:

```json
{ "severity": "medium", "members": ["low","medium","high"], "held": true,
  "demoted_from": "high", "operator_resolved": false, "…your other keys…": "…" }
```

#### Held clusters, and what you do about one

When `hold_spread` trips, docket materializes a `type="human"` step **per held
cluster**, named `<step>-held` at the same ordinal with the cluster's payload
index as its sibling suffix — `reconcile-held@0#0`, `reconcile-held@0#2`, … —
and the routing step **stops**. Concretely:

- The routing step's status stays `gated`, non-terminal, so every downstream
  step waits. Its threshold is **not** evaluated yet.
- Each held step is offered by `next --run` immediately, takes no claim and
  no token, and shows up as an ordinary human gate, or as a vote gate when
  `vote.hold.*` is configured (see *Engine configuration*). Either way, a
  tally answers first and escalates to the operator's verbs below when it
  does not pass.
- Use `guard stop` to check whether stopping is currently allowed. A
  `waiting-human` state does not itself forbid stopping; do not approve or
  abandon a held question merely to end a turn.
- The step-name suffix `-held` is **reserved**: no step name may end in it.
- **`#N` is the cluster's position in the payload, not a cluster id.** A
  held step names its own provenance: `step show` carries `held_cluster`
  (`cluster_index`, `cluster_count`, the `artifact` the payload lives on,
  and the `producer_step` that recorded it), and `step artifacts` on the
  row — legitimately empty since a hold produces nothing — names that
  artifact instead. Two clusters of one payload point at the same artifact,
  which is what the index disambiguates.

**One step per cluster, so you can answer them differently.** A hold carrying
four clusters gives you four approve/reject decisions, not one. The suffix is
the cluster's index in the payload, which is stable across re-reads of the same
immutable artifact — so a resumed saga re-derives the same step for the same
cluster, and a cluster that was never held has no step. (A hold where only the
second cluster trips materializes `#1` and no `#0`.)

| Verb | Effect |
|---|---|
| `docket step approve <held> [--note N] [--value V]` | records a **new** artifact on the routing step with `operator_resolved: true` on **that cluster**, marks the held step `done` |
| `docket step reject <held> [--note N]` | records **no** artifact for that cluster, marks the held step `done` |

**`--value V` is the corrected value for the cluster's aggregated field.** It
lands on the **field itself**, so every threshold and every downstream input
routes on the number the operator endorsed; the computed value it replaced is
recorded beside it as `operator_set_from`, so the two stay distinguishable
rather than one overwriting the other. `--note`, when given, travels with
the decision as `operator_note` on the same element, so a fixer reading the
resolved payload learns what was decided, not just that a decision happened.

| Rule about `--value` | |
|---|---|
| It is validated against the **pinned schema's declared enum** before anything is written | a correction must be a member of the membership set the run agreed to; a value outside it is a `VALIDATION_ERROR` |
| It is **never parsed from `--note`** | docket does not read a disposition out of prose; `--value` is the structured field that carries one |
| It accompanies **approve** only | reject records no artifact for the cluster, so there is no value to set — `--value` with `reject` is a `VALIDATION_ERROR` |
| It applies to **materialized** `<step>-held` steps only | a declared human gate has no payload of its own to correct, so the flag would reach nothing there; that too is a `VALIDATION_ERROR` naming the step |
| The routing step must declare an aggregated field and a `payload` schema | otherwise there is no field to set and no enum to check against |

The value rides in the `step-approved` event beside the note.

The routing step waits until **every** cluster has an answer, then routes
once: per its effective `on_fail` if **any** cluster was rejected, otherwise
through the threshold over the resolved payload. Reject is the escalating
answer, so a mixed set does not silently pass, but each cluster keeps its
own status, routing, and note.

Approval means *accept the cluster* — at the computed value, or at the one
`--value` names. The originally-held artifact stays addressable forever:
what docket computed and what you accepted are two records, not one
overwritten one.

A step parked because its clusters were **rejected** cannot be retried:
`docket step resolve --as retry` refuses there rather than silently
re-parking it. The rejection is sticky — re-running the aggregate re-reads
the same rejected decision and routes to the same place. What moves such a
step is `override-pass`, `skip`, or `abandon-issue`, and the rejected
verdict stays addressable through all three.

A loop entry supersedes an unresolved held step along with everything else at
that ordinal — the question was about that ordinal's computation, and the loop
has moved past it.

### Fanout and joins

A `fanout` step expands to one sibling per hint, in declared order:
`review@0#0 … review@0#3`. A step declaring `after = ["review"]` waits for the
**join**, and the rules are worth knowing exactly:

| Rule | Behavior |
|---|---|
| The join releases when **every** sibling is terminal | terminal means `done`, `skipped`, `superseded`, or `failed-routed`. A sibling that ended any of those ways has ended; waiting for all of them to be `done` would deadlock on the first one that failed or was skipped. |
| A sibling in `waiting-human` **parks the issue** | `waiting-human` is not terminal, so the join stays open until an operator resolves it with `docket step resolve`. |
| Downstream `inputs` resolve over **`done` siblings only** | a sibling that failed produced no result, so its artifact is not an input. |
| `on_fail` applies **per sibling** | one sibling failing routes that sibling. The other three still finish on their own terms. |
| `min_siblings` is a **quorum**, compared after the join | if fewer than `min_siblings` siblings are `done` once every sibling is terminal, the fanned step routes per its `on_fail`. |

**`min_siblings` does not cancel early.** Reaching the quorum does not
release the join: docket waits for every sibling to finish and *then*
compares. A 4-way fanout with `min_siblings = 2` and two siblings already
`done` still waits for the other two, rather than docket cancelling work
already running to save time on a quorum already met.

### Loops

A `threshold` (or an `on_fail`) that routes `fix-loop` enters a loop. There is
**no other loop construct** — a threshold routing to a *step name* interposes
that step as a one-off gate and is not a loop.

**Loop entry is scoped to a cluster.** A `loop = true` step's `serves` list
scopes it, and its `after_loop` chain, to the named steps' `fix-loop`
routings, its **loop cluster**. On entry the engine derives the **trigger**:
the step whose routing actually resolved to `fix-loop` (an `-held` approval
step maps back to the routing step that names it first). Only the bodies
**serving that trigger** instantiate, and only their `after_loop` downstream
is superseded — a second gate elsewhere in the workflow stays untouched,
still `pending`, not stale. Omitting `serves` (or leaving it empty) means
"serves every trigger": one cluster spans the whole workflow. Input
redirection for stale artifacts is still computed workflow-wide, not per
cluster; only the supersede/instantiate set on entry is cluster-scoped. The
event feed's `loop-entered` data gains a `trigger` field alongside
`ordinal`.

What happens on loop entry, in one transaction:

1. **The issue's loop counter increments.** The counter is per-issue, not
   per-step: one shared sequence even across independent clusters. If the
   new count would exceed `max_fix_loops`, the routing becomes
   `waiting-human` instead and no loop is entered, with the parked step's
   routing recording why. A **cluster-scoped** `max_fix_loops` (declared on
   a `serves`-scoped body) bounds only that cluster's own rounds, under the
   issue-level ceiling declared elsewhere — hitting it parks with `loop
   round %d for %q would exceed its cluster's max_fix_loops = %d on %s`
   instead of the issue-wide `loop %d would exceed max_fix_loops = %d on
   %s`; either way `docket step resolve --as fix-round` authorizes one more
   round. Two refusals share that park's shape without touching the bound
   *(engine commit f2dcb58)*: a round whose predecessor moved no bytes in
   the issue's scope, and one whose routing step recorded the same verdict
   as the round below it, are refused — nothing superseded, nothing
   instantiated, `waiting-human` naming `--as fix-round`, which re-enters
   through the authorized path the refusal does not check. A degenerate
   diff (empty, or carrying only the unresolved-base marker) never counts
   as unchanged. Exhaustion itself has no routing of its own: the bound
   always parks `waiting-human`; a declared exhaustion routing is an open
   engine request.
2. **Unclaimed work downstream of the triggered cluster's `after_loop`
   root(s) is superseded.** Instances at a lower ordinal that are still
   `pending` become `superseded`, a terminal status, not a deletion.
   Already-claimed and running instances are **left alone to finish**;
   their eventual routing is recorded for the ledger but applies no
   downstream effect, so a slow step from the previous ordinal cannot
   re-route an issue that has already moved on.
3. **`loop = true` steps serving the trigger instantiate at the new
   ordinal**, along with their `after_loop` step and everything
   transitively after it. Gates re-run and thresholds re-apply on the new
   instances — they are fresh, with no gate trail and no routing carried
   over.

Steps **upstream** of `after_loop` do not re-run. That is why `inputs` bind
**per input**: a step at ordinal 1 resolves each declared input at ordinal 1
if something produced it there, and otherwise falls back to the highest
earlier ordinal that did. A `fix` step at ordinal 1 binds
`reconcile.findings` fresh at ordinal 1 and `implement.change-summary` from
ordinal 0, in the same step.

**Issue completion is evaluated over highest-ordinal instances only.** A
`done` step at ordinal 0 whose ordinal-1 instance is still pending does not
count as finished, and superseded ordinal-0 instances do not block
completion. Prior instances and their artifacts stay immutable and
addressable for the ledger.

---

