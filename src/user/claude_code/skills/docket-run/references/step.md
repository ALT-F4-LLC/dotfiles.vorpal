# Docket engine CLI — `docket step`

Covers the `docket step` family. Consumer: the docket-run skill; this file is
the single copy of the engine CLI contract for these verbs, split out of
docket's reference.md, whose [JSON envelope
section](../../docket/reference.md#json-envelope--per-verb-data-shapes) still
holds the response-shape contract and parsing traps. Command and flag inventory
verified 2026-09-14 against `docket nightly-112-gcffd10c` (commit `cffd10c`,
built `2026-09-14T21:28:29Z`) by `--help` and `--version` only; behavioral
claims and JSON examples were not re-run.

<a id="contents"></a>

## Contents

- [`docket step`](#step-commands) — 513 lines
  - [`step artifacts`](#step-artifacts) — 68 lines
  - [`step claim`](#step-claim) — 34 lines
  - [`step reap`](#step-reap) — 40 lines
  - [`step complete`](#step-complete) — 68 lines
  - [`step fail`](#step-fail) — 23 lines
  - [`step annotate`](#step-annotate) — 49 lines
  - [`step resolve`](#step-resolve) — 121 lines
  - [`step approve|reject`](#step-approve-reject) — 44 lines
  - [`step context`](#step-context) — 26 lines

<a id="step-commands"></a>

### `docket step` — `step.go`

Steps are the units of work a run schedules. A step is **claimed** — which
mints a capability token and returns the whole context bundle in one response —
then **completed** with an artifact.

| Verb | Token | Effect |
|---|---|---|
| `step claim STEP-N [--render] [--template F]` | no | CAS claim; mints token; returns token + context (or packet) |
| `step heartbeat STEP-N` | **yes** | extends the lease; does not touch `attempt` |
| `step reap STEP-N --reason R` | **conductor** | forced reap of a dead holder's claim, without waiting out the lease |
| `step complete STEP-N --artifact-file F …` | **yes** (stages 0–1) | the saga |
| `step fail STEP-N [--note …] [--metadata …]` | **yes** | routes per `on_fail` when the CLAIM count reaches `max_attempts` (attempt counts claims, never failures); counts the failure into the row's `failed_attempts` (a reap counts into `reaped_claims` instead) |
| `step annotate STEP-N [--metadata JSON] [--integrated-sha SHA]` | no | merges opaque KV onto a **finished** step's record; `--integrated-sha` verifies ancestry and re-records the step's `issue.diff` from the named commit; event-logged |
| `step approve\|reject STEP-N [--note …] [--value V]` | **conductor** | `type="human"` gate steps, and a materialized held step of either kind (a vote-minted one once a failed tally parks it) |
| `step resolve STEP-N --as …` | **conductor** | `waiting-human` resolutions; `retry` **resets the retry budget** (moves `attempt_base`) — `attempt` itself and the `failed_attempts`/`reaped_claims` breakdown are never reset and not incremented by it |
| `step show STEP-N` | no | read-only; effective status |
| `step list (--run RUN-N \| --issue ISSUE-N)` | no | read-only; steps with id, run, instance, issue, kind, effective status, attempt (plus its `failed_attempts`/`reaped_claims` breakdown when nonzero), expected_cost — in (issue, creation) order. Scope by `--run` (the whole run), `--issue` (that issue across every run holding a step for it), or both (that issue inside that run); at least one is required. The budget-projection enumeration: step ids are a store-wide sequence, so id arithmetic cannot enumerate a run. `--issue` is the issue-shaped question a conductor actually holds. Watch-eligible. |
| `step context STEP-N [--meta]` | no | re-emits `context` read-only |
| `step render STEP-N [--template F]` | no | context bundle → rendered work packet |
| `step artifacts STEP-N` | no | read-only; lists what the step PRODUCED, sizes not bodies |
| `step artifact ARTIFACT-N [--payload]` | no | read-only; one artifact in full |

**conductor** in the Token column is the run's CONDUCTOR CAPABILITY (`run
activate` / `run conduct`, in [run.md](run.md)), not a lease token: on a bound run the verb
reads it from `DOCKET_TOKEN` or stdin, never argv, after the step is found
and before anything is written. None supplied is `VALIDATION_ERROR` (exit
3) naming both channels and `run conduct`; a wrong one, a step's lease token
included, is `AUTH_ERROR` (exit 5). A run activated before the capability
existed asks for none until it is conducted.

`step show` accepts multiple IDs: one returns an object under `data`, two or
more return an array. An expired but unreaped lease is marked `lease_expired:
true` even though effective status reads `pending`; operations that inspect
the stored claim can still refuse until it is reaped. When inputs bind an
`issue.diff`, `target_sha` and `target_worktree` identify the reviewed tree;
do not substitute the shared checkout's HEAD when those fields are absent.

<a id="step-artifacts"></a>

#### `docket step artifacts` / `docket step artifact`

**How an action step's verdict is read.** An action's result and an
aggregate's held-cluster payload both live in the `artifacts` table.
`step show` renders the row, `step context` renders a step's **inputs**,
and the run report's artifact index gives sizes and hashes but never a
body; `step artifacts` / `step artifact` (below) are the CLI surface for
the body itself.

`step artifacts STEP-N` lists reference, kind, size, payload size, hash,
`supersedes` — and deliberately carries **no bodies**, since an artifact
runs to 1MiB. `supersedes` names the artifact this one REVISES and is
absent on an original. A held cluster's resolution records its own
artifact rather than annotating the original: what the engine computed
and what the operator accepted are two records. The `sha256` is a content
address over the artifact's **body AND payload**: a supersession whose
payload changed never shares a hash with what it revises, and the
resolution artifact's body is **regenerated** from the resolved payload.
(Body-only artifacts — gaps, diffs — hash exactly as before.) **A rollup
counting work should skip artifacts that carry `supersedes`.** The run
report's artifact index carries it too. A step that produced nothing
lists nothing and exits 0; a step that does not exist is `NOT_FOUND`.

`step render` emits a **`== RESOLUTION`** block when the step carries a
routing record — the routing that sent it back, and the note whoever
decided it wrote. This lets an operator ruling issued BETWEEN rounds reach
the retry it authorizes, instead of requiring an out-of-band repo commit.
It is **scoped to the step's own row**: instance labels repeat across a
run's issues, so a note on another step never renders here. Absent on a
step with no routing record.

**The resolution also names the gates that did not pass** — verdict and
reason, last attempt per gate. It rides in `context.resolution.gates`
under `--json`, so a relay composing a retry can tell an **environmental**
failure from a **capability** one without a second query.

`skipped` means nothing was measured — the tree could not be bound — and
such a step parks for an operator rather than routing `on_fail`, so it
never reaches a retry at all. `unmatched` means the command was never
trusted here. Only **`fail`** means a measurement was taken and the work
did not pass it.

Use the pinned policy's resolved assignment rather than inventing model or
effort choices; `policy resolve` exposes the engine's seat-resolution rules.
A `fail` verdict establishes that a measurement ran, not that model capability
caused the failure. Read its reason before escalating: an environmental defect
does not improve because the next variant costs more.

`step show` renders a **gate summary** when the step has recorded gate results — a verdict, the gate name, an exit code, and a pointer to
`step gates` when something did not pass, so the surface an operator reaches
for to ask "why is this step parked" reports the gates that parked it. It is a
summary, not a copy of `step gates`: that verb owns the reasons and the
output tails.

`step artifact ARTIFACT-N` fetches one in full. `--payload` narrows to the
structured half and, under `--json`, emits it as **parsed JSON rather than a
string**, so `jq` reaches the verdict's own keys directly:

```
docket step artifact ARTIFACT-3 --payload --json=v2 | jq -r '.data[0].severity'
```

Both take the `ARTIFACT-N` form the listing and the run report's index print; a
bare `N` is accepted too. Both are **read-only and write nothing** — no reap,
no lease touch.

<a id="step-claim"></a>

#### `docket step claim`

| Flag | Type | Default | Notes |
|---|---|---|---|
| `--owner` | string | — | **required**; identifies the lease holder |
| `--ttl` | duration | `0` | defaults to the step's configured TTL |
| `--render` | bool | `false` | return the rendered packet instead of the bundle |
| `--template` | string | `""` | template file for `--render` |
| `--executor` | string | `""` | resolved executor hint for `--render`'s `{executor}` packet substitution (default: the step's declared hint) |
| `--metadata` | string | `""` | opaque JSON object merged onto the step in the claim transaction; record known routing facts before the worker can fail |
| `--cost-multiplier` | float | `1` | scale declared `expected_cost` for this claim; the scaled amount is checked against the budget cap and recorded with the claim |

Record known model, effort, and variant choices in claim metadata. Record the
actual serving model separately when it can be observed; do not infer it from
the requested alias. Use a cost multiplier when the dispatcher's established
pricing policy assigns the resolved variant a different cost. A guess about
model prices is not a reliable budget conversion.

The claim response includes `{ step, token, lease_expires_ms, context }`.
The token is returned **exactly once**: persist the successful claim output
privately without printing its token into conversation. If the call is
interrupted, inspect `step show` before retrying; a live claim can already
exist. Recover the original output if available. Otherwise report the lost
capability and use the lease/reap recovery protocol; do not turn an uncertain
response into another claim or reap a worker whose liveness is unknown.

Claim enforces readiness **itself** rather than trusting that you ran `next`; a
step that is not ready is `CONFLICT` naming the unmet condition. **Human, vote,
and action steps are not claimable** — the first two are gates rather than work,
and an action step is the engine's own computation — and a claim against one is
`CONFLICT` naming its class and what advances it instead.

<a id="step-reap"></a>

#### `docket step reap`

| Flag | Type | Default | Notes |
|---|---|---|---|
| `--reason` | string | `""` | **required**; why the holder is being declared dead |

**No lease token, but the run's conductor capability**, like `approve`,
`reject` and `resolve` (`docket run conduct`, in [run.md](run.md)): the holder's own token
is exactly what a reap cannot require, so the verb reads the run's
conductor token from `DOCKET_TOKEN` or stdin (none is `VALIDATION_ERROR`,
exit 3; a wrong one, a step's lease token included, is `AUTH_ERROR`, exit
5; a run activated before the capability existed asks for none), and the
authority for the reap itself is the recorded assertion that the holder is
gone. Liveness is otherwise TTL-only, and a TTL cannot be sized right in both directions —
raised to cover healthy long writers, it multiplies how long a dead agent's
claim blocks its row. The engine cannot probe a process it did not start,
but the relay that spawned the executor can, and this verb is the channel
for what it observed.

**Every consequence is the expiry reap's own**: the same `lease-reaped`
event (carrying `data.forced` and the reason, which is how a reader tells
the two apart), the same write-class headroom hold awaiting `--ack-reap`,
the same return of the step to the ready pool.

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
`[limits]` in [workflows.md](../../docket/references/workflows.md)). `step reap` checks the step's own status, not the run's.

<a id="step-complete"></a>

#### `docket step complete`

`step record` is an identical alias. Prefer it in Claude Code shell commands
when the word `complete` collides with shell-builtin classification.

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

**Recording success does not establish gate success.** The JSON envelope can
have `ok: true` while `failed_gates` names failures and the step is parked
`waiting-human`. Check the returned step state and gates before reporting
completion. If the recording call times out, use `step show`, `step artifacts`,
and `step gates` to establish whether the artifact recorded before retrying;
an uncertain call is not evidence that the token remains usable.

**Gaps need no workflow declaration.** Each `--gap-file` records an
auxiliary artifact and a related backlog issue in the same transaction.
The body is retained verbatim and the first nonblank line supplies the
title (leading `#` stripped, capped at 120 characters). Immediately
following it, consecutive `Key: value` lines form an optional header
block, ending at the first non-header line, including a blank line:

```text
Clean-checkout tests cannot find the required fixture
Severity: high
Kind: bug
Labels: test-infrastructure, follow-up

The required test fails because fixtures/example.json is absent at clean HEAD.
```

| Header | Effect |
|---|---|
| `Severity` | `blocker`, `high`, `medium`, `low` map to priority `critical`, `high`, `medium`, `none` |
| `Priority` | `critical`, `high`, `medium`, `low`, `none`; wins over Severity |
| `Kind` | `bug`, `feature`, `task`, `epic`, `chore`; default `task` |
| `Labels` | comma-separated labels, at most 16 |

Unknown keys do not end the header block; unsupported values for recognized
keys are ignored. Without headers the issue defaults to priority `none`, kind
`task`, and no labels. The completion names filed IDs. Gaps always land in the
run's project; moving one to its actual owning project uses
`docket issue move ID --project TARGET` under the applicable authorization.

**A gap-only completion PARKS instead of passing.** When the declared
emit's body is empty (whitespace-trimmed) and at least one gap was
recorded, the step routes `waiting-human` **before the gate verdict or
threshold is consulted** — the worker's whole answer was "this work cannot
be done here, and here is the residue", and routing `pass` over it would
schedule the issue's entire downstream pipeline over an empty change.
`step resolve` is the operator's disposition. Gaps recorded **beside real
content** route exactly as before. When the gap belongs to a different
repository, `docket issue move --project` re-homes the filed issue.

<a id="step-fail"></a>

#### `docket step fail`

| Flag | Type | Notes |
|---|---|---|
| `--note` | string | why the step failed — lands on the **failure EVENT**, prose for a human reading the run's history |
| `--metadata` | string | a JSON **object** of opaque keys to values, merged onto the step's own — lands on the **STEP ROW**, structured KV for a query. `--note` and `--metadata` are complementary, not alternatives, and both are accepted on the same invocation |

`--metadata` here has parity with `step complete --metadata`: the same
shallow, last-write-wins merge, the same shared write path
(`internal/engine`'s `mergeMetadata` and `db.SetStepMetadataTx`), and the
same 16 KiB cap — measured and refused pre-transaction, so a rejected
`--metadata` spends no attempt. The refusal message differs from
`complete`'s: `step fail` offers no `--artifact-file` or `--payload-file`,
so it points at `--note` instead.

**It SURVIVES INTO A RETRY.** A failed attempt's bag merges into the
step's row like any other, so the next attempt's completion (or failure)
overlays on top of it. It reaches `run report --json`'s existing metadata
rollup the same way a completion's does, and is reachable **even for a
step that never completes**.

<a id="step-annotate"></a>

#### `docket step annotate`

| Flag | Type | Notes |
|---|---|---|
| `--metadata` | string | a JSON **object** of opaque keys to values, merged onto the finished step's own metadata; **required unless `--integrated-sha` is given** |
| `--integrated-sha` | string | the **full 40-hex** commit id the shared branch carries for a write-class step's landed work; the engine **verifies** it is an ancestor of the shared checkout's HEAD, then re-records the step's `issue.diff` from that commit's own patch and sets `integrated_sha` in the step's metadata |

**`--integrated-sha` is the verified integration** — the path for a write
step whose landed content diverged from its recorded commit (a cherry-pick
whose conflict you resolved by hand, an operator-ruled patch on top of a
gate failure). Ancestry is checked first and a sha the shared branch does
not carry is refused (`CONFLICT`) with nothing written; then the step's
newest `issue.diff` is superseded by one computed from the named commit
(`git diff-tree`, scoped like every `issue.diff`, out-of-scope paths
disclosed), the same supersession `step resolve --worktree` performs, and
the re-record is logged `issue-diff-repinned` with both shas and
`resolution: integrated-sha`. From then on every downstream packet binds
its `target_sha` to the resolved commit, `dispatch open` reports no
`stale_targets` for the step's review rows, and `dispatch close` accepts
the step with `how: "resolved"` in its integration record — no
`--skip-integration-check` needed. The sha names ONE ordinary commit whose
patch is the step's landed work; a merge commit records an empty body.
Refusals beyond ancestry: a step that records no `issue.diff` of its own or
whose record names no commit (`VALIDATION_ERROR`), a prefix or non-hex sha
(`VALIDATION_ERROR`), an unanswerable ancestry question or an engine with
no git probe wired (`CONFLICT`). The success line and the JSON envelope
(`issue_diff_repin`) report the re-record exactly as a resolve's re-pin
does. Both flags may be given together; the verified sha wins over any
`integrated_sha` the metadata spells.

The post-completion channel for facts that become true only **after** a
step's record freezes. The canonical case is integration: a relay that
rebases or cherry-picks a recorded commit mints a NEW sha, and every run
record citing the writer's own is unreachable from any ref once the
worktree is swept. Annotating the step with the durable id keeps the run
record re-checkable.

The merge is the **same rule `step complete --metadata` uses** — shallow,
last-write-wins, 16 KiB cap on the supplied bytes, non-object refused — and
it is **token-free**: the lease retired with the artifact, and this is an
operator-side act about the record, not a completion. The merge is logged
as a `step-annotated` event carrying the annotation **verbatim**.

Refusals: a step that has not reached a terminal status is `CONFLICT`
(exit 4) naming its actual status. Empty or non-object `--metadata` is
`VALIDATION_ERROR` (exit 3); a missing step is `NOT_FOUND` (exit 2).

<a id="step-resolve"></a>

#### `docket step resolve`

| Flag | Type | Notes |
|---|---|---|
| `--as` | string | **required**: `retry` \| `rerun-gates` \| `skip` \| `abandon-issue` \| `override-pass` \| `fix-round` |
| `--note` | string | why |
| `--batch` | bool | with `--as override-pass` only: also record one **run-scoped** grant per failed gate |

Every resolution requires the run's **conductor capability** (`docket run
conduct`, in [run.md](run.md)) via `DOCKET_TOKEN` or stdin, checked after the step is
found and before anything is written: none is `VALIDATION_ERROR` (exit 3),
a wrong one `AUTH_ERROR` (exit 5); a run activated before the capability
existed asks for none.

`retry` resets the **step's** attempt budget, a different counter from the
issue-level attempt trail, which is monotonic and never reset. It also
**releases the lease**, so the re-execution goes through a fresh claim and
lands on its own attempt number: `pending` with a live lease is a
contradiction — `claimPredicate` refuses every new claimant while the
previous holder's token still records, so both executions share one
number, the usage ledger's `(step, attempt, unit)` key admits only the
first, and the report counts one attempt for work that happened twice.
`resolve` is also how an operator moves a run past a `type="vote"` step
whose voters have not cast — a run must not be hostage to a quorum that
never arrives.

**`rerun-gates` re-measures without re-executing**. Most retries in
practice are not about the work at all: a gate fails because a trust entry
is missing or a tool is broken, someone fixes that out of band, and the
step's own output was never in question. Using `retry` for this case pays
for a full re-execution, and the re-execution is **destructive**: it diffs
a tree that already contains the change, so the diff comes back empty and
supersedes the real `issue.diff` with 0 bytes.

`rerun-gates` rewinds the step to the point just after its artifact recorded and
re-runs every completion gate from there, then routes on the new verdicts. The
step never returns to the pool, no worker re-executes it, no attempt is
consumed, and the recorded artifact is untouched. It re-measures; it does not
forgive — gates that still fail park the step again, exactly where it was.

Reach for `rerun-gates` when the **gate** was wrong, and `retry` when the
**work** was. A step declaring no completion gates refuses `rerun-gates`
and says so, naming `retry` instead: a `pre = true` gate runs at claim and
is not part of the completion saga, so a step with only those has nothing
to re-run.

Two artifact rules follow from the same reasoning and apply to **every**
path, not just this verb. A recomputed `issue.diff` that records **no
change** does not supersede one that recorded a change — an empty diff is
evidence that this measurement had nothing to compare, never evidence that
the change vanished (a *first* empty diff still records; a genuine
"nothing changed" is a real result). And a **byte-identical** re-record is
not a supersession at all.

**`override-pass --batch` extends the ruling to identical later failures in
the same run** (schema v24). The dominant measured operator toil is
environmental gate parks — the same "sandbox artifact, not a code defect"
ruling re-made for every step of a run. With `--batch`, the override-pass
also records one grant per failed completion gate, keyed by the failure
**signature**: gate name + exit code + reason classification. A later step
of the **same run** whose every failing gate matches a grant routes the
same generic `pass` the override-pass records, instead of parking; the
gates still run, and a failure with a **different** signature (a different
exit, a new reason) parks exactly as before. Every auto-pass is
attributed: the covered step's routing names the grant(s), the grant's
`covered_steps` counts them, and the feed carries `gate-override-granted`
(human) at mint and `step-batch-overridden` (threshold) at each spend. The
grant **dies with the run**. Refusals: `--batch` without `--as
override-pass`, or on a park with no failed completion gate (a vote
quorum, a rejected hold, a gap-only completion), is `VALIDATION_ERROR`
(exit 3). A step whose threshold interposes another step is **never**
auto-passed, so it parks with the block named, for individual resolution.

**`fix-round` is the sanctioned re-entry into an exhausted fix loop**.
Exhausting `max_fix_loops` parks the issue, correctly; without this verb
the only alternative is going around the engine. `fix-round` authorizes
**one** more loop for **that issue** and enters it in the same
transaction, minting a fresh fix+review round judged like every other.

It is deliberately **not** `retry`: retry re-runs the check that reported
the problem; `fix-round` says the problem is real and schedules work on
it. The authorization is recorded as a per-issue grant
(`run_issues.loop_grants`, schema v20) rather than as an edit to
`max_fix_loops` — the workflow's bound is the author's standing policy
over every issue it matches, and loosening it to unstick one issue would
loosen it for all of them. The effective bound is `max_fix_loops +
loop_grants`, so **one grant buys exactly one round**. The parked step is
recorded `superseded`, not passed: its question is answered by the new
round's work, not by a verdict nobody reached. The park's own reason now
names this verb.

**`retry` is refused on a step parked by a rejected held cluster** —
`VALIDATION_ERROR` (exit 3), naming the held step — rather than silently
re-parking it. Re-running the aggregate re-reads the same rejected
decision and routes to the same place. The refusal names the three
resolutions that can move it: `override-pass`, `skip`, `abandon-issue`.

**`retry` is refused on a held cluster parked by a vote that did not
pass**, for the same reason: the idempotency key is `(run, instance)`, so
the next `next` re-reads the *same* finished tally and parks it again.
That refusal names `step approve` / `step reject`. The other three
resolutions do apply to such a step, and `override-pass` there records the
cluster as resolved exactly as `approve` would.

**Resolving a held cluster runs `dispatch open`'s stale-target check at
resolve time.** Under the staged closure the verify/review rows downstream
of a held reconcile are usually already inside an open dispatch, so no
`dispatch open` runs between the resolution and their execution. A
resolution that ends the hold (here or via `step approve`/`step reject`)
therefore re-asks the same recorded-target-vs-shared-HEAD ancestry
question over the steps it just un-blocked, on the same two channels the
manifest advisory uses: warning lines on stderr in human mode, and a
`stale_targets` field beside the step row in the JSON envelope, absent
when there is nothing to warn about and never present on non-held
resolutions. **Advisory, never a refusal** — completed steps keep their
recorded provenance untouched. It shares the underlying check, so it also
inherits the tree comparison described under `dispatch open`: a sanctioned
cherry-pick that rewrote the sha but not the content warns about nothing.

<a id="step-approve-reject"></a>

#### `docket step approve|reject`

| Flag | Type | Default | Notes |
|---|---|---|---|
| `--note` | string | `""` | why the gate was approved or rejected |
| `--value` | string | `""` | (`approve` only) corrected value for a **held cluster's** aggregated field |

Neither takes a lease token (a gate is never claimed), and both require
the run's **conductor capability** (`docket run conduct`, in [run.md](run.md)) via
`DOCKET_TOKEN` or stdin: none is `VALIDATION_ERROR` (exit 3), a wrong one
`AUTH_ERROR` (exit 5), checked after the step is found and before anything
is written; a run activated before the capability existed asks for none.
They apply to `type="human"` steps, and to a **materialized**
`<step>-held` step whichever kind it was minted as — anything else is
`VALIDATION_ERROR` naming the step's actual class.

The held step is where an `aggregate` step's held clusters are decided.
The difference from a declared gate is where the consequence lands:
approving a declared gate finishes that gate, while approving a held
cluster un-defers the aggregate step's routing (see [held
clusters](../../docket/references/workflows.md#held-clusters-and-what-you-do-about-one)).
Deciding one twice is `CONFLICT` (exit 4) naming both steps.

When holds are minted as votes (`vote.hold.*`), these verbs apply to a
held step **once a vote that did not pass has parked it** at
`waiting-human`. Before that the tally owns the decision and both verbs
are `VALIDATION_ERROR`, naming `step resolve` as what moves a run past a
vote still being cast.

`--value` belongs to that second case only. It sets the cluster's aggregated
field to a value validated against the **pinned schema's declared enum**,
recording the computed value it replaced as `operator_set_from`, and `--note`
travels with it as `operator_note` — see [held-cluster rules](../../docket/references/workflows.md#held-clusters-and-what-you-do-about-one).
On a declared human gate, or alongside `reject`, it is a `VALIDATION_ERROR`.

Deciding a **held cluster** with either verb carries the same resolve-time
stale-target advisory `step resolve` documents above: when the
decision un-blocks downstream steps whose packets render from a recorded target
sha the shared checkout's HEAD no longer carries, the divergence is named on
stderr (human mode) and in a `stale_targets` field beside the row (JSON).
Declared human gates never carry the field.

<a id="step-context"></a>

#### `docket step context` / `render`

`context` re-emits the bundle read-only, no token. It uses the run's
snapshots, recorded artifacts, pins, and recorded run notes. It never
reads the live issue or working tree and never opens a pinned file. For a
claimed step, inputs and their `target_sha` / `target_worktree` replay the
bindings recorded at claim time. An unclaimed step or one pending retry
resolves current run artifacts. `--live` explicitly asks what a new claim
would receive now for any step; use the default when investigating what a
worker actually saw. `--meta` adds per-section byte counts alongside the
bundle.

`render` formats that bundle through a template. Without `--template` the
shipped default is used, which ships in the binary and cannot drift. With
`--template F`, **if the run pinned that path the file's bytes are
verified against the pin** and a mismatch is `CONFLICT` naming both
hashes — never a warning, never a silent re-pin. An unpinned template
renders unverified and says so. `--executor` (also on `step claim
--render`) overrides the resolved hint used for `packet` entries'
`{executor}` substitution; the default is the step's own declared hint.

**Read verbs here write nothing**, including no reap — even for a step whose
lease has lapsed, which reads as `pending` while the row still carries the stale
owner.
