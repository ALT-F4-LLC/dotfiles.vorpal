# Docket engine CLI — `docket guard` and `docket trust`

Covers the `docket guard` and `docket trust` families, the single copy of this
engine CLI contract, split out of docket's
[reference.md](../../docket/reference.md#json-envelope--per-verb-data-shapes)
(consumer: the docket-run skill), which still holds the response-shape
contract and parsing traps. Verified 2026-09-25 against `docket
nightly-209-ga348156` (commit `a348156`, built `2026-09-25T01:58:12Z`) by
`--help`/`--version` and the docket-cli-audit skill's runtime sweep
(`../../docket-cli-audit/references/cli-fixtures.json`); behavior and JSON
examples reflect the swept commands as of that build.

<a id="contents"></a>

## Contents

- [`docket guard`](#guard-commands) — 115 lines
  - [`guard record`](#guard-record) — 18 lines
  - [`guard spawn`](#guard-spawn) — 46 lines
- [`docket trust`](#trust-commands) — 199 lines
  - [`trust add <name> -- <argv...>`](#trust-add) — 65 lines
  - [`trust list`](#trust-list) — 16 lines
  - [`trust probe [--run RUN-N]`](#trust-probe) — 23 lines
  - [`trust rm <name>`](#trust-rm) — 20 lines
  - [The tenancy audit trail](#trust-tenancy-audit) — 18 lines
  - [The trust audit trail](#trust-audit) — 37 lines

<a id="guard-commands"></a>

### `docket guard` — `guard.go`

Deterministic predicates over engine state, for hooks.

| Verb | Allows when |
|---|---|
| `guard stop` | no pending work outside `waiting-human` |
| `guard gate --step NAME` | a **passed** `type="human"` **or** `type="vote"` step of that name exists for an active run — an approval on the one, a tallied approval on the other. Both kinds answer, so converting a gate to a vote does not silently stop the hooks that check it; a vote still being cast reads as undecided and denies |
| `guard record [--run RUN-N]` | no unreconciled dispatch exists — no open manifest, and no discrepancy |
| `guard spawn --run RUN-N` | the proposed rows byte-match the open dispatch **and** no write-class reap is unacknowledged (or `--deciding-vote PROPOSAL-N` names the open proposal this batch exists to decide — the reap half only) |
| `guard spawn --active` | the reap half over **every** active run of the project: denies on the oldest run that would deny, its reason prefixed `RUN-N: `. Mutually exclusive with `--run`, and it takes neither `--deciding-vote` nor `--rows` (exit 3) — the carve-out and a proposed batch each belong to one run, so name that run with `--run`. The `--json` deny envelope is `{ok:false, error, code}` with no run field; the id is the reason's prefix |

**Exit 0 = allow, exit 2 = deny with a reason**, independent of the ordinary
command error taxonomy: a guard's caller tests a boolean, so exit 2 here
means "denied," not "not found." The reason goes to stderr in human mode and
into the envelope's `error` under `--json`. That envelope's `code` is
`NOT_FOUND` on every denial, because the engine reuses the code to exit 2; do
not branch on it.

**When the resolved store has no database, a guard ALLOWS (exit 0)
rather than denying.** A repo with no engine has no engine state to
forbid anything, so "not applicable" is an allow. The reason still
travels — `not_applicable: true` plus a `reason` in the JSON payload, and
a `guard: …` note on stderr in human mode.

Only database absence receives this exemption; a guard's computed denial
still exits 2.

`guard stop` deliberately does **not** block on `waiting-human`: it asks
whether the machine is done working, and a run waiting on a person is not
something a stop interferes with.

A vote step with an open proposal, and work waiting behind that vote, do
not block stopping either: the panel can decide outside the conductor's
turn. After the proposal is decided, the step is dispatchable and blocks
until an engine invocation routes it. A stop hook should preserve this
distinction instead of treating every nonterminal row as active machine
work.

It also allows a never-dispatched run whose steps have never left
`pending`, permitting a bootstrap-only handoff. The exemption ends at the
first dispatch or first step transition, including work performed
without a manifest.

Guards answer over the **current project's** runs by default. `guard stop`,
`guard gate`, `guard record`, and `guard spawn` accept `--all-projects` to
answer over every project's runs in the store instead — the same vocabulary
as `events list --all-projects`.

<a id="guard-record"></a>

#### `guard record` — dispatch reconciliation

| Flag | Type | Default | Notes |
|---|---|---|---|
| `--run` | string | `""` | the run to check; **omit** to check every non-terminal run in the current project |
| `--all-projects` | bool | `false` | ask across projects instead of the current project |

The guard denies on an open dispatch or a recorded discrepancy, using the same
predicate as `next`. An open dispatch is expected while its executors work and
record; do not require this guard to allow before each executor completes.
Use it to inspect reconciliation at relay boundaries, and read the reason to
distinguish a legitimate wave in flight from unresolved discrepancies.

A named run that does not exist is refused rather than treated as an empty
run. Preserve that uncertainty when interpreting a hook result.

<a id="guard-spawn"></a>

#### `guard spawn` — before a relay starts a batch

| Flag | Type | Default | Notes |
|---|---|---|---|
| `--run` | string | `""` | the run whose batch is being spawned; mutually exclusive with `--active` |
| `--active` | bool | `false` | check reap holds over every active run of the current project |
| `--rows` | string | `""` | file holding the JSON array of rows about to be spawned (`-` for stdin); refused with `--active` |
| `--ack-reap` | lease-reaped | `[]` | acknowledge a write-class reap by its `lease-reaped` event `seq` (repeatable) |
| `--deciding-vote` | string | `""` | admit this batch past a reap hold because it exists to DECIDE the named OPEN proposal (`PROPOSAL-N`); event-logged |
| `--all-projects` | bool | `false` | answer over every project's runs, not just the current project's |

Both halves must hold. With **no** open dispatch and **no** `--rows`, the
row half is vacuously satisfied and the reap half still answers, so a
relay that batches its own way still gets the check. With `--rows` and no
open dispatch it is a **denial**: the relay believes it is spawning a
batch the engine never issued. A row that does not byte-match shows
**both sides' bytes**.

`--ack-reap` is processed **before** the predicate, so one command both
acknowledges and answers, letting a relay's spawn hook be a single
invocation. It is also the second of the two entry points for the
acknowledgment; `dispatch open --ack-reap` is the other, for a **new**
relay taking over from a crashed one. Acknowledging asserts *you* have
established the old writer is gone: the engine cannot check a process it
did not start.

Acking a seq twice is a success that changes nothing. Acking a seq that
names no reap of this run is `VALIDATION_ERROR` (exit 3).

`--deciding-vote` permits the panel that will decide a reap hold to
start. The proposal must exist and be open; the flag relaxes only the
reap check, never row matching, and does not acknowledge the reap. Every
use records a `spawn-admitted` event naming the proposal and hold. Use it
with `--run`, not `--active`, since the exception concerns one run's
panel.

**Both guards write nothing, except that acknowledgment** — and, when
`--deciding-vote` is used, its audit event. Neither reaps and neither
auto-abandons an expired dispatch.

**The guard is an early check, not a lock.** Between its allow and the
actual spawn, a dispatch can be abandoned or a lease reaped; the real
enforcement stays in `step claim`'s compare-and-swap.

<a id="trust-commands"></a>

### `docket trust` — `trust.go`

The allowlist of commands docket may execute. **A gate runs only when an entry
here authorizes it**; an unmatched gate is reported, never run. The trust
command's installed help gives the current executable contract.

Entries live in `$XDG_CONFIG_HOME/docket/trust.toml` (default
`~/.config/docket/trust.toml`), owned by you, mode `0600`, and **never read
from a repository**. There is no `--trust-file` flag, no env override beyond
`XDG_CONFIG_HOME`, and no config key — every extra way to point docket at a
trust file is another way for repo content to choose it.

**A missing trust file is not an error.** It is an empty allowlist: every
gate reports `unmatched`, nothing runs, and the run tells you what it
needed.

These verbs need no `.docket/` database: the store is user-level.

<a id="trust-add"></a>

#### `docket trust add <name> -- <argv...>` 

| Flag | Type | Default | Notes |
|---|---|---|---|
| `--global` | bool | `false` | trust in **every** repository, not just this one |
| `--prefix` | bool | `false` | match any command *beginning* with this argv; prints an over-authorization warning |
| `--re-runnable` | bool | `false` | safe to run again after a crash interrupted it |
| `--tree` | bool | `false` | touches the working tree; serializes against other such gates |
| `--flaky` | bool | `false` | may fail intermittently; re-runs on failure, each attempt recorded |
| `--stub` | bool | `false` | this is a **placeholder**, not the check its name implies; every result it produces is flagged `stub` in `step gates` and counted in the run report |
| `--stub-reason` | string | `""` | free-text reason recorded and shown alongside `stub` in `trust list` and its rendering; requires `--stub` |
| `--network` | stringSlice | `nil` | hosts this command must reach (repeatable). **Declares a requirement; grants nothing.** A gate that names any receives the proxy variables and `DOCKET_GATE_NETWORK`; one that names none is unchanged |
| `--timeout` | duration | `5m` | per-command timeout |
| `--yes` | bool | `false` | skip the interactive confirmation (the argv is **still** disclosed) |

**`--stub` marks hollow assurance.** A repo with no scanner installed still
wants to exercise a workflow's shape, so `docket trust add secret-scan --
/usr/bin/true` is legitimate. What is not legitimate is the row it
produces: without the flag, `secret-scan: pass` is indistinguishable from
a scanner that ran and found nothing. With it, `step gates` shows `stub`
in the FLAGS column and `run report` says `secret-scan: pass 1 — all
stubs, nothing was measured`.

Docket cannot work this out for itself — an argv cannot be inspected to
tell a real check from a convincing one. It is a declaration, like
`--tree` and `--flaky`, and it changes **nothing** about how the command
runs. Flipping it on a re-add is a `CONFLICT`, for the same reason
flipping `--tree` is.

**Everything after `--` is the argv, verbatim.** Your shell already
tokenized it and docket stores those tokens — nothing is split, expanded,
or globbed, and no shell is ever involved in running it. A flag after
`--` belongs to the trusted command:

```bash
docket trust add tests -- make test
docket trust add lint  -- golangci-lint run --fix   # trusts ["golangci-lint","run","--fix"]
```

The entry binds to the **current repository** unless `--global`. A command
trusted in one project does not execute in a clone of another; moving a
repository invalidates its entries (`trust list --all` shows the stale binding
so you can see why a gate went `unmatched`).

**The unmatched diagnostic leads with the case you are in**. When
an entry of the gate's name exists only in ANOTHER repository, the
message leads with `no trust entry for this repo; approve it with docket
trust add`, and mentions the other binding as an aside, since the common
case is that this repo never had an entry, not that it moved. A
gate whose name IS trusted here but whose argv differs says so directly.

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

<a id="trust-list"></a>

#### `docket trust list`

| Flag | Type | Notes |
|---|---|---|
| `--global` | bool | only global entries |
| `--all` | bool | every repository's entries, not just this one's |

A `Collection`, so `--json=v2` renders `{items, total, truncated}`. Argvs print
with control characters escaped. Under `--format json` (v2), every item
carries `class`: `gate` for an entry a workflow names in `gates`, `action`
for one a workflow declares via `action = "<name>"` — an engine ACTION fed a
JSON bundle on stdin at record time, which nothing but the engine can run.
The v1 `--json` envelope's entries omit `class`.

<a id="trust-probe"></a>

#### `docket trust probe [--run RUN-N]`

Runs every `class = "gate"` entry of this repository's roster once, in ONE
throwaway detached worktree of the repository's current HEAD, with each
entry's own `--timeout`, and returns a row per gate. A gate that fails here
fails on CLEAN HEAD, so no step's changes caused it: run it once before a
run's first dispatch instead of rediscovering the same failure as a parked
step per issue. `--run` labels the report and **does not narrow the roster**.
Action-class entries are skipped by name, never failed. The worktree is
removed on success, failure and interrupt.

This executes trusted commands; it is not a read-only status check. A detached
worktree isolates repository changes, not arbitrary external effects of the
commands. Run it only when executing those checks is within the current task's
authorization. Inspect `trust list` when the roster or its effects are unknown.

`--json` data: `{head, passed, failed: [name], skipped: [{name, reason}],
gates: [{name, stub, exit, log_tail}]}`. `passed` is true only when every
gate exited 0; a `stub` entry's pass is hollow and marked. Refuses outright
(not a pass) on an empty roster or a cwd outside a work tree.

<a id="trust-rm"></a>

#### `docket trust rm <name>`

Removes an approved command. The trust store is **published first**, and the
trust-removed event is recorded only after that publish succeeds. A revocation
recorded ahead of the write could leave an entry that still authorizes
execution while the event log said it was revoked.

Two failures remain, and each names what happened. If the store cannot be
published, nothing is removed and nothing is recorded. If the store is
published and the event cannot be recorded, the entry **is** removed and the
command says so; the log then still shows the entry as trusted.

| Flag | Type | Notes |
|---|---|---|
| `--global` | bool | remove the global entry rather than this repo's |

`NOT_FOUND` (exit 2) when no such entry is bound here.

<a id="trust-tenancy-audit"></a>

#### The tenancy audit trail

Registering a project writes a `project-registered` event carrying the
`cwd`, the resolved `identity`, and the `verb` that triggered it. Like a
trust event it has **no run** — registration precedes any run of the
project by definition — and it is scoped to the project it names, so it
appears in that project's feed rather than in every project's.

Registration itself is **gated**: a project row is created only when the
identity is a git worktree (or a deliberate `.docket` store) **and** the
verb is not a read. A read from a directory with no project answers
"nothing here"; a run-addressed verb (`step`, `dispatch`, `trust`,
`guard`, `events`) carries on with no ambient project, since it reads its
project off the run; and a verb that would WRITE through the ambient
project from a non-repository directory is refused by name.

<a id="trust-audit"></a>

#### The trust audit trail

`add` and `rm` write a `trust-added` / `trust-removed` event, carrying the
argv **hash** rather than the argv, so a grant made mid-run is auditable
without leaking the command's arguments into a feed a run report renders.
Beside the hash the event carries every property that affects behavior:
`name`, `repo`, `global`, `prefix`, `re_runnable`, `tree`, `flaky`,
`network`, and `timeout` — what a grant **widens**.

It also records **who**: `actor` (the git identity, falling back to the
OS username and then to `unknown`) and `cwd` (where the verb ran from).

**Neither is authenticated.** `git config user.name` is whatever the
invoking environment says it is; this is an attribution claim on the same
footing as step metadata, not a verified identity. Record it anyway: a
grant is the one act in the system that widens what code may
execute.

**Recording is mandatory inside a repository with a database, not
best-effort.** The
event is written *before* the store, as a hook inside the store's own
lock: if it cannot be recorded, the verb fails with `GENERAL_ERROR`
(exit 1) and **nothing is granted**.

**An idempotent re-add emits no event.** Nothing was written, so there is
nothing to record.

**Outside a repository the verbs still work, and say what they did not
do.** The store is user-level, so requiring a database to manage it would
mean somebody who installed docket could not approve a command until they
created a tracker. When the repository cannot be resolved, or there is
no database at the resolved path, the change is applied and a
**warning** says it was not recorded and that nothing will show it later.
The warning prints on stderr and rides in the JSON response's `warnings`
array; like the argv disclosure, it is not suppressible.
