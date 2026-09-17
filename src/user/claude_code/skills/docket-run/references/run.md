# Docket engine CLI — `docket run`

Covers the `docket run` family, the single copy of this engine CLI contract,
split out of docket's
[reference.md](../../docket/reference.md#json-envelope--per-verb-data-shapes)
(consumer: the docket-run skill), which still holds the response-shape
contract and parsing traps. Verified 2026-09-17 against `docket
nightly-136-g835f706` (commit `835f706`, built `2026-09-17T01:02:08Z`) by
`--help`/`--version` and the docket-cli-audit skill's runtime sweep
(`../../docket-cli-audit/references/cli-fixtures.json`); behavior and JSON
examples reflect the swept commands as of that build.

<a id="contents"></a>

## Contents

- [`docket run`](#run-commands) — 740 lines
  - [`run start`](#run-start) — 49 lines
  - [`run issue add|remove RUN-N DKT-N...`](#run-issue) — 38 lines
  - [`run note add|list`](#run-note) — 22 lines
  - [`run refresh-scope`](#run-refresh-scope) — 31 lines
  - [`run report RUN-N`](#run-report) — 101 lines
  - [`run activate RUN-N`](#run-activate) — 204 lines
  - [`run conduct RUN-N`](#run-conduct) — 39 lines
  - [`run pause|resume|abandon RUN-N`](#run-lifecycle) — 84 lines
  - [`run repin RUN-N --reason R`](#run-repin) — 65 lines
  - [`run budget RUN-N [--set N]`](#run-budget) — 70 lines
  - [`run status [RUN-N]`](#run-status) — 29 lines

<a id="run-commands"></a>

### `docket run` — `run.go`

A run binds registered workflows to issues and schedules their steps. Runs
follow `planning → active ⇄ waiting-human → done | abandoned`; run IDs are
formatted `RUN-<n>` and, like issue IDs, accept the bare number too.

<a id="run-start"></a>

#### `docket run start` — `run_start.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--issue` | — | stringSlice | `nil` | issue to attach (repeatable) |
| `--request-file` | — | string | `""` | file holding the run's request text |
| `--budget` | — | float64 | `0` | per-run cap, **enforced**, in the unit `budget.unit` names (see `docket run budget --help`); `0` means unlimited |
| `--usage-budget` | — | float64 | `0` | independent cap over measured usage; requires `budget.usage.unit` to be armed |
| `--idempotency-key` | — | string | `""` | repeating a start with the same key returns the original run |

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

**A breached run is un-wedged with `docket run budget RUN-N --set N`.**
`run resume` alone clears nothing — the cap has not moved, so the next claim
breaches again — which is why raising the cap and resuming are two commands:

```bash
docket run budget RUN-3 --set 50 --reason "estimate was low"
docket run resume RUN-3
```

<a id="run-issue"></a>

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

<a id="run-note"></a>

#### `docket run note add|list`

Use a run note for an established fact or authorized disposition every later
worker needs. Notes render verbatim as `== RUN NOTE N` after `== REQUEST` in
the shipped packet template and appear as `notes` in `step context`. Custom
templates must render `.Notes` explicitly. Issue comments and mid-run issue
description edits do not enter packets.

```bash
docket run note add RUN-N --file note.txt --json
docket run note list RUN-N --json
```

`add` requires exactly one of `--text` or `--file`; `--file -` reads stdin.
The note is capped at 16 KiB and one trailing newline is dropped from file
input. Notes are append-only and event-logged; record a later correction
instead of editing history. Adding is allowed while planning, active, or
parked, and refused for done or abandoned runs. A note records an existing
decision; it does not itself authorize a scope change or failed-gate override.

<a id="run-refresh-scope"></a>

#### `docket run refresh-scope`

After an authorized scope change, use both channels in order:

```bash
docket issue edit DKT-M --scope 'src/component/**' --json
docket run refresh-scope RUN-N --issue DKT-M --reason 'Authorized scope change' --json
```

`issue edit --scope` changes the live declaration used by scheduler mutual
exclusion. `refresh-scope` copies that declaration into this run's snapshot
for the issue's remaining work; it has no `--scope` flag of its own. The
reason is required. Titles, kind, labels, description, pins, and terminal
step records keep their existing state; the event records old and new scope
and the affected instances.

The refresh refuses while any affected issue step is claimed, running, or
gated; while a dispatch is open; on planning or terminal runs; when every
affected step is terminal; or when the live and frozen scopes already match.
Respect the refusal and resolve the in-flight state before retrying.

| Intended change | Channel |
|---|---|
| Tell every later worker an established fact | `run note add` |
| Explain the same step's next retry | `step resolve ... --as retry --note ...` |
| Explain an authorized next fix round | `step resolve ... --as fix-round --note ...` |
| Propagate an authorized scope declaration to remaining work | `issue edit --scope`, then `run refresh-scope` |
| Replace drifted pinned file bytes after authorization | `run repin --reason ...`; this does not update issue descriptions |

<a id="run-report"></a>

#### `docket run report RUN-N` — `run_report.go`

Takes no flags beyond the global ones. **READ-ONLY**: it computes effective
status and writes nothing, not even the lease reap `next` performs, so
polling it cannot advance a run. Works on a run in **any** status: `planning`
reports zeros, `abandoned` reports the trail up to abandonment.

| Section | Contents |
|---|---|
| `run` | id, status, reason, request |
| `wall_clock_ms` | its own top-level key, not nested in `run`: activation → now, or → the terminal transition |
| `pinned_workflows` | the run's pinned workflow refs: `{ref, name, pinned_version, current_version, behind}` |
| `budget` | effective `cap` and its `cap_source` (`run` \| `config` \| `unlimited`), the `floor`, `reported` per unit, the `budget_unit` the cap counts, `spend` = max(reported, floor), `burn_rate` (floor per wall-clock hour), and `breach_reason` when a budget paused the run |
| `steps` | count by **effective** status, plus per-step `attempts`, each row carrying its `issue`, its `routing` (how the step ended, with its reason) and — for a vote step — `vote` (its proposal and how it tallied) |
| `issues` | the run's **issue-level terminal rulings**: per abandoned issue, `{issue, disposition, by, reason}` — the operator's recorded rationale, verbatim. Rendered as a *How issues ended* section |
| `gates` | per-gate pass/fail/unmatched/**skipped** counts, a **stub** count, and the per-step trail |
| `actions` | the same rollup over action results, `builtin` included |
| `artifacts` | the **index**: id, kind, producer instance, producer `executor` and `issue`, sha256, bytes — never the bodies |
| `metadata` | step `metadata` keys → distinct values with counts, verbatim and uninterpreted — over the **merged** bag, so both what a definition declared and what a worker reported via `step complete --metadata` are counted |
| `actors` | per-actor event counts (`next` / `gate` / `threshold` / `human`) — the attribution rollup described under `docket events` below, computed over the events that remain |
| `authorities` | per-`authority` value event counts — the companion rollup to `actors`, reflecting the `--authority` flag on `run pause`/`abandon` and `step approve`/`reject`/`resolve` |
| `step_usage` | the usage **ledger** row by row: each row's `step`, `instance`, `attempt`, `unit`, `quantity`, and `source` — the detail behind `budget`'s per-unit `reported` sums, and what a duplicate back-fill refusal points at |
| `vote_metadata` | the same key → distinct-value rollup over vote seats' `--metadata` bags |
| `vote_usage` | per-unit sums of vote seats' `--usage` reports, beside the step ledger's `reported` — never merged with it |
| `vote_usage_coverage` | `{casts, reported}` — how many seat-casts reported spend at all. **Never omitted**, so "panels ran and said nothing" is distinguishable from "no panels ran" |
| `findings` | every structured finding the run's panels recorded, one row per entry: `proposal`, `voter`, `role`, `kind` (`blocker` \| `concern` \| `suggestion`), `text`, and the `evidence` it cited — the references `vote cast --findings-json` resolved against this run, in canonical spelling. An entry that cited nothing carries `unsupported: true` (rendered *unsupported: no evidence cited*) rather than an absent list, so an asserted finding and a reproduced one read differently. Casts on a sealed proposal that is still open are withheld, as every read verb withholds them. Omitted when no panel recorded structured findings |

**A status alone does not say what happened**, which is why every step row
carries its `routing` and the human report prints a *How steps ended*
section. One word covers outcomes that need opposite responses:

| Status | Covers |
|---|---|
| `skipped` | a tribunal that **never convened**, and one whose panel deliberated and was then resolved by an operator |
| `failed-routed` | a step that was **measured and failed**, and one **cascade-terminated** by an issue-abandon without ever being claimed |

The step's `routing` records which: an abandon cascade writes
`abandon-issue: cascade: DKT-N was abandoned by <step>; this step was never
measured`.

**A park's routing text is a question; the report says when it was
answered.** `docket run abandon --issue` terminalizes an issue's remaining
steps **without touching `routing`**, so a step parked with "loop 4 would
exceed `max_fix_loops` = 3; `docket step resolve --as fix-round` authorizes
one more round" reaches `failed-routed` still carrying that question, while
the operator's actual ruling lives only in an `issue-abandoned` event. Two
things close the gap:

- a **`How issues ended`** section (`issues` in `--json`), naming each
  abandoned issue, the step that abandoned it where one did, and the
  recorded reason in full;
- an inline `— later resolved: <issue> abandoned (…)` on any `failed-routed`
  or `waiting-human` step of a disposed issue whose own `routing` does not
  already name the abandon. Steps the `abandon-issue` routing already
  annotated (`abandon-issue: cascade: …`) are left alone.

Only abandonment appears: a **completed** issue leaves no event and needs
none — its steps are `done` and the step sections say so.

**Step lines name their issue on a multi-issue run.** Instance labels are
unique within an issue and repeat across them, so a run with multiple issues
can show the same instance label (e.g. `"implement@0"`) once per issue with
nothing to tell the rows apart. Where the report's attempt rows cover two or
more distinct issues, every step line is labelled with its issue prefixed
onto the instance instead: `"<issue> implement@0":`. A single-issue run keeps
the plain instance label. `--json` is unaffected either way — every attempt
row has always carried `issue`.

A vote step's `attempts` is permanently `0` — it is never claimed. `vote`
carries the proposal and its status beside the routing, so a tribunal that
convened, tallied, and was *then* disposed of by an operator reads as both
facts rather than as a bare `skipped`.

**Trail and index rows are attributable.** A gate or action trail row is
`{step, step_id, issue, name, ordinal, verdict, reason?, output?}` — the
instance label alone is not enough, since instance names **collide across
issues in one run** (two issues on the same workflow both have an
`implement@0`). Join on `step_id`; read `issue` to tell the two apart.

`output` rides on **non-pass rows only**, as the last 2000 bytes of the
capture prefixed with `…` when longer — a passing check's chatter is noise,
while a failing gate's diagnosis otherwise means re-running it out-of-band.
The full capture stays on the result row itself.

The artifact index carries the producer's `executor` and `issue` for the same
reason: `producer` alone is a fanout ordinal (`review@0#2`) that says where
in the topology an artifact came from, not who produced it. Both are omitted
when the row has none.

**The budget numbers are bare.** No currency and no unit: what they count is
the workflow's business. The report publishes the numbers a warn policy
needs — cap, floor, reported-per-unit, burn rate — so an instance computes
its own warn threshold from a read verb. Core ships the cap and no warn.

**Reported usage is summed per unit and never across units.** Two units are
two numbers; docket has no opinion about whether they add up. Only the unit
`budget.unit` names participates in the cap comparison; the rest are recorded
and reported.

The document is **deterministic** given the same rows — every section orders
by a total key — apart from the wall clock and the burn rate derived from it.

<a id="run-activate"></a>

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

**A first activation mints the run's CONDUCTOR CAPABILITY** and returns it
exactly once: `conductor_token` in the JSON envelope (`omitempty`, absent
on a re-activation and under `--dry-run`), its own trailing stdout line in
human mode. Only its SHA-256 is stored. From then on `step
approve|reject|resolve|reap` and `run pause|resume|abandon` on the run
require it; `run conduct` below re-mints it for a session that does not
hold it. A run conducted while still `planning` keeps that capability
rather than minting a second.

**Auto-registration — you never run a register verb.** Activation registers
the current contents of `.docket/config/`, so a definition goes from
"written" to "registered" by starting a run:

| Directory | What activation does |
|---|---|
| `config/schemas/*.json` | **registers** as a payload schema, named for the file (`findings@10.json` → `findings@10`) |
| `config/workflows/*.toml` | **registers** as a workflow definition, named by its own `[pipeline]` block |
| everything else under `config/` | **pins** by content hash and registers nothing — contracts, fragments, templates, `policy.toml` |

**Schemas register in full before workflows**, so a workflow naming a schema
in the same tree always registers second and its `payload` reference
resolves. Within each group the order is lexical, for determinism. Registry
directories are scanned flat; pinned ones are scanned recursively. A file
whose extension does not match — a `README.md` in `workflows/` — is skipped
in the registry and pinned like any other file, so documentation never
blocks a run.

Registration reuses the ordinary register path: same validation, same
immutability. **Changed bytes at an unchanged `name@version` is `CONFLICT`
(exit 4) and refuses the whole activation**, naming the file, both hashes, and
the literal edit to make:

```
.docket/config/workflows/standard-change.toml has changed since it was
registered as standard-change@1.

  registered  sha256:3f9a…   current  sha256:c41b…

A registered name@version is frozen so that a run which pinned it can
reproduce. To adopt these changes, bump the definition's version to 2,
then activate again. Runs already pinned to standard-change@1 are unaffected.
```

Docket never auto-bumps a version, never overwrites a registered one, and
never silently uses the old bytes. Identical bytes re-register freely and
change nothing.

**A re-activation does not re-scan.** It inherits its pin set, so a config
file edited while a run is under way is invisible to that run and cannot
trigger the refusal above on a run that was working fine.

**A repo with no `.docket/config/` is untouched by any of this**: the
directory is checked once, and an absent one skips the scan entirely.

**The registration report.** Activation prints one line per registered
file — `name@version  path  (new | unchanged)`, schemas first — followed by
a count of what it pinned. Under `--json` the same data rides in a
`registered` array of `{kind, name, version, path, sha256, outcome}`. An
activation that registered nothing prints no block and carries no
`registered` key.

**The trust report.** After the transaction commits, activation prints every
harvested fenced command verbatim, annotated `matched` (naming the trust
entry) or `unmatched` (with the reason), so you see which commands a run
will actually invoke *before* it runs. Under `--json` the same data rides in
a `fences` array of `{issue, gate, tag, ordinal, command, matched, entry,
reason}`.

It is a **report, not a gate**: activation succeeds with unmatched commands.
They simply will not run, and their gates route per `on_fail` when reached —
refusing would let anyone who can file an issue block a run by adding an
untrusted line.

Commands print with control characters escaped; the `--json` form carries
the raw bytes. `--dry-run` prints the same report and discards the whole
transaction, so you can inspect what a run would bind without committing to
it.

**The gate preflight.** The trust report answers "will this command run" for
a *harvested* command. Activation asks the same question of every gate the
bound workflows **declare** and warns with the list of gates that resolve to
no trust entry here, naming the workflows that declared each one. It prints
**nothing** when every gate resolves.

Gate-unmatched events are typically missing-entry cases, knowable before the
run starts; left uncaught, each one either pauses a run while an operator
adds the entry, or silently skips the AC commands the workflow declared.

It is a **warning, not a block**: some gates are legitimately absent on some
machines, and activation is not the place to make that a hard stop. An
unmatched gate still records `unmatched` and routes per its step's
`on_fail`.

A gate whose entry is a **stub** (`trust add --stub`) is listed separately
as a note: it resolves and will run, but it will measure nothing.

Fence gates are excluded — their commands are the trust report's subject,
and a named gate has no argv here to resolve. Under `--json` the data rides
in a `gate_preflight` array of `{gate, workflows, matched, entry, stub,
reason}`, `omitempty`.

**The hold policy.** A hold is the one step in a run no author declared — the
engine mints it when a `hold_spread` trips — so who *answers* it is not
visible anywhere a workflow author or an operator normally looks. Activation
reports the hold policy: with **both** `vote.hold.rule` and
`vote.hold.voters` set, holds go to a panel and the line names it; with
**neither** set, one operator decides and nothing prints; with **one** set,
holds go to one operator and activation warns. Under `--json` it rides in
`hold_policy` as `{rule, voters, panel}` — `panel` is never omitted, since
"one operator decides" must be distinguishable from a docket too old to
report it.

**The scope lint.** Activation warns about every issue that declared **no
scope at all** while binding a workflow that holds the tree — such an
issue's holding step occupies the tree without excluding, or being excluded
by, any other issue, so the scheduler can offer it beside work it collides
with. The warnings ride in `scope_warnings` under `--json` (a `{issue,
workflow, reason}` array, `omitempty`, so a fully-scoped run carries no
key — `issue` is the display id, e.g. `"DKT-87"`, never the internal numeric
PK) and print on **stderr** in human mode, naming the remedy —
`docket issue edit DKT-N --scope GLOB`, since scope is set on the *issue*,
not in the workflow named beside it.

It is a warning, never a refusal. A **declared-but-empty** scope does not
warn: that is a decision somebody made on purpose. The lint reads the
**live** issue rather than the snapshot, so setting a scope after a first
activation fixes the omission by the next one. "Holds the tree" means
`holds_tree` and nothing else — never a class name, which core attaches no
meaning to.

**The routing lint.** A second warning, in the same `scope_warnings` array,
fires per issue whose declared scope resolves **nothing** under the run's
recorded exec root — the signature of an issue planned into the wrong
repository, which otherwise surfaces only after a full wave (an executor
booted into a worktree that cannot contain the fix, a gap filed, the review
fanout dispatched over the empty result). The test is **anchored existence,
not file existence**: each entry's literal prefix (up to the first glob
metacharacter) must exist under the root, or its parent directory must; one
anchored entry clears the issue. A scope may name files the work will
CREATE, so the lint deliberately under-reports rather than flagging
greenfield new-file scopes. A run with no recorded exec root skips it
entirely. The message names the root it resolved against and the way out —
`docket issue move --project`, or fix the scope.

Re-activating an `active` run expands newly-unblocked phases only and
**inherits** the original pin set — a workflow re-registered or a pinned
file edited since activation does not reach a run already under way. Its
success line says so: `(re-activation: original pin set inherited, nothing
re-registered)`, since counts alone would read as fresh binding-and-pinning
work.

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

<a id="run-conduct"></a>

#### `docket run conduct RUN-N` — `run_conduct.go`

No local flags. Takes (or re-takes) the run's CONDUCTOR SEAT: mints a fresh
256-bit capability, stores only its hash (`runs.conductor_token_hash`,
schema v29), retires any standing one, and records a `conductor-seated`
event whose `data` is `{actor, cwd, rotated}` (`rotated` true when a
capability already stood). Response (`--json`): `{"run":"RUN-N",
"token":"<64 hex>","rotated":<bool>}`. Human mode prints `Took the
conductor seat on RUN-N` (`; the previous capability is retired` when
rotated) and then the token on its own stdout line, `step claim`'s
discipline, so a session whose stdout lands in a transcript uses `--json`
and extracts the field without printing it.

The seven operator verbs — `step approve|reject|resolve|reap`, `run
pause|resume|abandon` (with or without `--issue`) — require the capability
on a bound run, via `DOCKET_TOKEN` or stdin, never argv (there is no
`--token` flag on any verb): none supplied is `VALIDATION_ERROR` (exit 3)
naming both channels and this verb; a wrong one, a step's lease token
included, is `AUTH_ERROR` (exit 5). Both messages name `run conduct` and
never echo the presented token. Every run this binary activates is bound at
birth (`run activate` above); a run activated before the capability existed
asks for nothing until it is conducted, and conducting it binds it. A
`planning` run is conductable (`run abandon` applies to one), and its first
activation then keeps the capability rather than minting a second.

The verb is **deliberately token-free**: nothing authenticates a caller, and
a run whose conductor session died must stay pausable and abandonable. That
makes the seat TAMPER-EVIDENT, not tamper-proof: the taker's token is the
only valid one from that moment, the displaced conductor's next ruling
refuses `AUTH_ERROR`, and the `conductor-seated` event names who took it
and from where. A harness keys its own callers off this one verb (the
sibling guard denies it to the executor archetypes); the engine keeps them
off the other seven.

Refusals: `done` or `abandoned` run → `CONFLICT` (exit 4, "there is nothing
left to conduct"); missing run → `NOT_FOUND` (exit 2).

<a id="run-lifecycle"></a>

#### `docket run pause|resume|abandon RUN-N` — `run_lifecycle.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--reason` | — | string | `""` | required on `abandon` (with or without `--issue`) |
| `--issue` | — | string | `""` | (`abandon` only) abandon only this issue's remaining steps; the run and its other issues continue |
| `--authority` | — | string | `""` | **required on `pause` and `abandon`**: `operator`\|`standing-grant`\|`conductor`. Names what entitled the decision; refused as `VALIDATION_ERROR` (exit 3) without it. `resume` does not take this flag |
| `--authority-ref` | — | string | `""` | required alongside `--authority standing-grant`; names the standing authorization |

`pause` moves `active → waiting-human`; `resume` moves it back; `abandon` is
terminal from any non-terminal status. A paused run blocks new claims and
honors in-flight completes.

All three, `abandon --issue` included, require the run's conductor
capability, same channels and refusals as `run conduct` above. The check
runs after the run is found and before any status check or write, so a
missing token is reported before an illegal transition would be.

**Abandonment NAMES the run's recorded worktrees.** A relay's
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

**The warning is STATTED before it is printed.** Recorded rows outlive the
directories: a relay that swept its own checkouts at close time leaves
`steps.work_root` behind, so the recorded list is a superset of what is
still there. The message lists only the paths still present and counts the
rest (`all N recorded … are already gone from disk; nothing to sweep`);
`data.worktrees` and the v2 `worktrees` key still carry the RECORDED list
unchanged. A path that cannot be statted at all (permission, dead mount)
counts as present: a failure to look is not an absence.

**`abandon --issue` is the per-issue disposition** — for a mis-routed or
unimplementable issue that should not take the whole run down with it.
Every remaining (non-terminal) step of that issue moves to `failed-routed` —
the same terminus the `abandon-issue` routing produces — an
`issue-abandoned` event records `{issue, reason, steps}` (the stopped
instances), and the ordinary reconciliation rollup runs in the **same
transaction**, so the run continues, returns from a park, or completes if
this was its last unfinished work. The issue's **own status is not forced
terminal** — triage stays the operator's — but the issue's **`resolution` is
set to `abandoned`** (schema v18); both `step resolve --as abandon-issue`
and this verb record it, since they are one fact about the issue with two
actors. `issue list` shows `⊘ abandoned` in the status column, `issue show`
prints the status and the resolution side by side, and `issue show --json`
carries a `resolution` key — emitted **only when set**. The resolution says
*that* a run gave up; **which run, when, and why** is the `Run disposition`
section `issue show` prints beside it (in [reference.md](../../docket/reference.md), under `issue show`). `issue reopen` clears it.
Refusals: run not `active` or `waiting-human` → `CONFLICT` (exit 4); issue
not part of the run → `NOT_FOUND` (exit 2); every step already terminal →
`CONFLICT` (nothing to abandon); missing `--reason` → `VALIDATION_ERROR`
(exit 3).

An **illegal transition is refused** with `CONFLICT` (exit 4) rather than
silently applied — pausing an already-paused run must not report success.
`abandon` without `--reason` is `VALIDATION_ERROR` (exit 3).

**Each of the three writes its event in the same transaction as the
status** — `run-paused`, `run-resumed`, `run-abandoned`. `run-abandoned`'s
`data` carries `{from, to, reason, authority, authority_ref?}` (confirmed:
`authority_ref` appears only alongside `standing-grant`). `run-paused`
likely carries the same `authority` fields since `pause` now requires the
flag too, but this was not directly confirmed against a fixture. `run-resumed`
stays `{from, to, reason}`, since `resume` takes no `--authority`. There is no
`run-done` here: no operator verb moves a run to `done` — that is the
reconciliation rollup's transition, and it logs itself.

**`resume` states pin drift unprompted.** Resuming is exactly the moment a
parked run's steps are about to claim again, and a corpus install that
replaced a pinned file during the park is invisible until then. The resume
itself still **succeeds** — the per-step `CONFLICT` at claim/render remains
the enforcement — but when the run's pins are no longer sound, the human
message appends a `Pin drift:` block (the same one `run status` renders,
below) and, under `--json=v2` only, the run payload carries a `pin_drift`
key beside it, the same v1/v2 split `run abandon` uses for `worktrees`
above. `pause` and `abandon` do not check: drift matters when steps are
about to resume claiming, not when they stop.

<a id="run-repin"></a>

#### `docket run repin RUN-N --reason R` — `run_repin.go`

| Flag | Type | Default | Notes |
|---|---|---|---|
| `--reason` | string | `""` | **required** — why the recorded agreement is moving; empty is `VALIDATION_ERROR` (exit 3) |
| `--drop` | stringArray | — | retire this one pinned file ref, which no longer resolves and no pending step reads (repeatable); records a `run-repinned` event with a null `new_sha256` and `dropped: true` |
| `--drop-unresolvable` | bool | `false` | retire every drifted file pin that no longer resolves and no pending step reads; never touches refs that resolve to different bytes, nor workflow or schema pins |

The recovery half of the pin story. `run activate` freezes a pin per ref at
content-hash granularity, and `docket run verify-pins RUN-N` reports when
one no longer matches disk (`ok` / `changed` / `missing` per pin,
`CONFLICT`/`NOT_FOUND` if any is unsound) — but writes nothing, not even a
re-pin. Re-activation makes that permanent: it deliberately **inherits** the
original pin set rather than re-scanning (see `run activate` above).
Without `repin`, a corpus install that replaces a pinned file out from
under an active or parked run would leave abandon and a full re-plan as the
only disposition.

`repin` adopts what each drifted ref resolves to **now** as the run's
pinned bytes, for steps that have not yet claimed under the old agreement.
It runs the identical comparison `verify-pins` reports, so the two verbs
can never disagree about what is drifted.

**Completed steps' pins are never rewritten.** The write touches only the
`pins` table, one row at a time, as `UPDATE pins SET sha256 = <new> WHERE …
AND sha256 = <old>` — a compare-and-swap, so a pin that moved between the
read and the write hits zero rows and the whole repin rolls back. One
`run-repinned` event per **changed** ref is recorded in the same
transaction, carrying `{kind, ref, old_sha256, new_sha256, path, reason}`.
`steps`, `artifacts`, and `step_inputs` are never touched.

**Refuses `CONFLICT` (exit 4) rather than straddling the transition:**

- any step is `claimed` — an executor mid-flight holds a packet rendered
  under the old agreement, and repinning under it would change what the
  packet means mid-execution
- a dispatch is open for the run — its manifest was offered under the
  current pins
- the run is `done`, `abandoned`, or `planning`, or every one of its steps
  is already terminal — nothing remains for a new agreement to govern, so a
  repin could only rewrite completed steps' history
- a `changed` verdict that new bytes cannot explain — no resolved hash at
  all, or the same hash as the pin (e.g. a schema that is byte-identical to
  what it pinned but no longer compiles): repointing the pin is not the fix

**Refuses `NOT_FOUND` (exit 2)** when any pinned ref no longer resolves at
all — repin adopts current disk bytes and a missing ref has none to adopt,
so by default it refuses the **whole set**, all-or-nothing, the same rule
activation's own pinning follows. Three ways out: restore the file(s),
abandon the run, or retire the dead pins with `--drop REF` /
`--drop-unresolvable` — opt-in, and refused all the same when a
**non-terminal** step's packet closure still reaches the ref, naming the
readers.

**A no-op is success, not an error.** When nothing has drifted the response
reports `0` repinned and the message says every pin already matches disk, so
running `repin` twice — or against a run that turns out to be sound — is
always safe.

Response: `{run, repinned: [{kind, ref, old_sha256, new_sha256, path}],
dropped: [...], added: [...], unchanged}` — `dropped` carries the refs
retired via `--drop`/`--drop-unresolvable`, `added` carries newly-adopted
pins; all three arrays empty (never `null`) on a no-op. `run-repinned` is
attributed to `human` (Attribution, below).

<a id="run-budget"></a>

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

**There is a SECOND, INDEPENDENT cap over MEASURED usage** — what the
ledger actually recorded, as opposed to the declared step costs the cap above
counts. Arm it with `run start --usage-budget N` (or `budget.usage.default`)
**and** `budget.usage.unit`; both are required, since a cap with no unit counts
nothing, and the read form says `DORMANT` when only one is set. `run budget`
and `run report` then carry `usage_budget` / `usage_unit` / `usage_spend`
beside the declared numbers.

The two are **never combined**: declared units and measured tokens answer
different questions, and folding measured tokens into `max(reported, floor)`
would let the token count swamp the declared discipline the instant it was
armed. They are also **checked differently**: a step's declared cost is
known before it runs, so the declared cap RESERVES (`spend + cost <= cap`);
a step's token spend is not knowable in advance, so the measured cap STOPS
(`spend <= cap`) — work continues while recorded usage is at or under the
cap, and the first claim after it is exceeded is refused. A breach on the
measured cap names its unit (`usage budget: measured output_tokens spend
…`).

`--set` **raises or lowers** a live cap. Raising is the way out of a budget
breach:

```bash
docket run budget RUN-3                    # what stopped it, and at what
docket run budget RUN-3 --set 50 --reason "estimate was low"
docket run resume RUN-3                    # a separate, deliberate act
```

**It does not change the run's status.** A breached run is `waiting-human`
and stays so until `run resume` — a separate, deliberate act. Nothing
re-scans and nothing sweeps: the claim path reads the cap fresh from the
row, so the next claim after a resume simply proceeds.

Lowering below what a run has already spent takes effect the same way — the
next claim refuses. **Raising a cap cannot un-spend what was spent:** the
floor is computed from the run's claim events and does not move when the
cap does. A new cap below the existing floor refuses the very next claim.

**A cap change that resolves the breach clears the breach record.** When
the run carries a `breach_reason` and the new cap is unlimited (`0`) or at
least the current `spend`, `breach_reason` is cleared; if that breach also
parked the run, the run's `reason` is **rewritten** to name the cap
change — `budget: cap changed from N to M after breach (was: …); run resume
to continue`.

The change is **event-logged** as `run-budget-set` carrying `from` and
`to`; the clearing rides in **that same event** as `breach_cleared` (the
retired reason string). `row_version` is bumped whether or not
`--if-version` was passed. Refused on a terminal run (`CONFLICT`, exit 4): a
finished run's cap is a record of what it was allowed to spend.

Clearing the record still does not change the run's **status** — a
breached run stays `waiting-human` until `run resume`.

<a id="run-status"></a>

#### `docket run status [RUN-N]` — `run_status.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--all` | — | bool | `false` | list form: widen the list to `done` and `abandoned` runs; the bare list is active-only |
| `--limit` | — | int | `50` | list form; `0` means no limit |

With an ID: the run, its issue count, its steps grouped by status, and its
pins. Without: a `Collection` of runs — under `--json=v2` the payload is
`{items, total, truncated}` with each item carrying `row_version`.

**Read-only.** Computes effective status and writes nothing — the pin-drift
check below reads disk, not the database, but still writes nothing.
The bare list is active-only and keeps `planning` runs: a run that exists
but has not been activated is still live work. `--all` widens it to `done`
and `abandoned` runs. The retired `--active` flag is refused.

**Pin drift is checked and stated unprompted, for the single-run form.**
For a run that is `active` or `waiting-human`, status also hashes the run's
pinned files against disk, and, when anything no longer matches, adds a
`pin_drift` field (the unsound pin verdicts, `omitempty`) to the JSON
payload and a `Pin drift:` block to the human rendering, naming each
drifted ref, both hashes, and pointing at `docket run repin` as the remedy.
Absent whenever every pin is sound. Skipped for a terminal run: its pins
are history.

None of the `run` verbs are watch-eligible.
