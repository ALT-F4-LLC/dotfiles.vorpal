# Transport, output, and capabilities

Read the section relevant to parsing output, transporting prose, handling a
claim, or observing a live command. For exact flags, use `docket <verb> --help`
and [the CLI reference](../reference.md).

Find the relevant heading before reading a large section:

- Global Flags & Output Contract
- `--watch` eligibility
- Free-text flags: quote so the shell cannot run your text
- JSON envelope shape
- `--json` values (v1 vs v2)
- Primary-key naming (`id` vs the noun)
- Error codes & exit codes
- Optimistic concurrency (`--if-version`)
- Idempotency keys (`--idempotency-key`)
- Claims, leases, and capability tokens
- Interactive forms
- Workflow: Watch Mode

## Global Flags & Output Contract

Defined once on `rootCmd` in `internal/cli/root.go` and inherited by every
subcommand:

| Flag | Shorthand | Type | Default | Behavior |
|---|---|---|---|---|
| `--json` | — | string | `""` | Switch to machine-readable JSON envelope on stdout. Bare `--json` selects v1; `--json=v2` selects the uniform envelope. See below. |
| `--format` | — | string | `""` | `json` is an alias for `--json=v2`; check command-local uses such as `export --format` before assuming the global meaning. |
| `--quiet` | `-q` | bool | `false` | Suppress non-essential human-mode info/warning lines on stderr. JSON still uses stdout for the envelope; operational diagnostics can appear on stderr. |
| `--watch` | `-w` | bool | `false` | Re-run the command on an interval and refresh output. Accepted only on the exact allowlist below; every other command — read-only or not — rejects it with a `VALIDATION_ERROR`. |
| `--interval` | — | duration | `2s` | Poll interval for `--watch` **and** `events list --follow`. Minimum `500ms`; anything lower is a `VALIDATION_ERROR`. |

### `--watch` eligibility

`--watch`/`-w` and `--interval` are hidden from the `--help` of every command
NOT in this allowlist (hidden at help-render time — the flags are shared
persistent globals, so they exist on every command even when help omits
them), defined in `internal/cli/watch_commands.go`:

```
docket board
docket issue list
docket issue show
docket issue log
docket issue graph
docket issue comment list
docket doc list
docket doc show
docket doc comment list
docket next
docket plan
docket stats
docket config
docket vote list
docket vote show
docket vote result
docket events list
docket step list
```

`docket events list` is on the list because its `--follow` polls on the same
`--interval`; the rest is the tracker surface.

Attempting `--watch` on any command off the list — read-only (`docket
project list`) or write alike — fails with a `VALIDATION_ERROR` whose
message enumerates the live allowlist: `--watch is limited to: docket board,
docket config, ...` (generated from the allowlist by
`watchRejectionMessage()`). The message's own enumeration is authoritative
if this copy ever drifts.

### Free-text flags: quote so the shell cannot run your text

Every free-text flag — `issue create`/`issue edit` `-d`, `issue comment add
-m`, `doc create -d`, `vote cast --summary`, `step fail`/`step
approve`/`step reject` `--note` — carries prose that often includes pasted
content: an upstream bug report, another agent's output, a transcript
excerpt, command names in backticks. Inside a DOUBLE-quoted argument the
shell RUNS backtick and `$(...)` spans — with your cwd, permissions, and
network — before docket ever sees the argv. The verb still exits 0; the only
tells are stray output printed ahead of the response and text truncated
where the substitution swallowed it. A hostile `$(curl … | sh)` arriving in
pasted text executes the same silent way, so treat this as an injection
boundary, not cosmetics.

Safe forms depend on the flag’s supported input modes:

- a supported file flag, such as `vote cast --summary-file`, or an explicitly
  supported `@path` value;
- a correctly single-quoted literal, escaping embedded apostrophes;
- stdin, when the flag documents it, via a QUOTED heredoc delimiter: `docket … -d - <<'DESC'` … `DESC`
  (pick a delimiter the body cannot contain — text quoting a shell snippet
  has a bare `EOF` line of its own, which closes an `EOF` heredoc early and
  runs the remainder as commands).

Pasting prose directly inside double quotes still allows shell substitution.
A double-quoted `echo "…" | docket … -d -` expands before the pipe, and an
unquoted heredoc (`<<EOF`) expands too. Prefer file/stdin transport for
untrusted or multiline bodies; do not assume every free-text flag implements
the `-` stdin sentinel. Use documented input modes for each flag.

### JSON envelope shape

JSON envelope responses are single-line objects written to stdout. Stream,
source/body, and export modes have command-specific contracts; check help
before treating raw output as an envelope.

Success:
```json
{"ok": true, "data": { ... }, "message": "Created DKT-1: Fix login bug"}
```
`message` is optional. Parse the result fields, not human-readable message text.
For `step record`, a successful envelope means the recording succeeded; gates
can still fail. Inspect `failed_gates` and the step’s status/routing before
reporting that the work passed.

Error:
```json
{"ok": false, "error": "issue DKT-99 not found", "code": "NOT_FOUND"}
```

### `--json` values (v1 vs v2)

`--json` is a string flag with `NoOptDefVal = "v1"`, so a bare `--json` behaves
exactly as it did when the flag was a boolean.

| Value | Mode | Notes |
|---|---|---|
| (flag absent) | human | |
| `--json` (bare) | JSON v1 | legacy per-verb response shapes, with the additive amendments below |
| `--json=v1` | JSON v1 | explicit form |
| `--json=true`, `--json=1` | JSON v1 | retained from the boolean-flag era |
| `--json=v2` | JSON v2 | uniform envelope, see below |
| `--json=false`, `--json=0` | human | retained from the boolean-flag era |
| anything else | `VALIDATION_ERROR` (exit 3) | e.g. `--json=v3` |

V1 preserves legacy response shapes with the additive amendments below. New
agent integrations should use v2 for uniform collections and version fields.
Do not depend on an exact serialized key set or byte sequence across releases.

| Payload | Shape |
|---|---|
| `issue show`, `issue list` | `scope` appears **when the issue declares one, and only then** — no declared scope emits no key and stays byte-identical to the pre-scope shape; a declared-but-empty scope emits `[]` |
| `issue show`, `issue list` | `resolution` appears **when a routing has set one**, so an abandoned issue stops being indistinguishable from a finished one |
| `issue show` | `run_disposition` appears **when a run abandoned its work on the issue** |
| every issue payload | `issue` mirrors `id`, **unconditionally** — see below |

### Primary-key naming (`id` vs the noun)

Issue payloads expose both `id` and `issue`, with the same displayed ID, in
v1 and v2. This includes nested sub-issues and issues returned by mutations.
Use either spelling consistently. Other engine responses may use noun keys,
but their nesting and value types are verb-specific: `run status` carries a
nested run object and step status counts, not the full step rows. Consult
[per-verb response shapes](../reference.md#json-envelope--per-verb-data-shapes).

Under **`--json=v2`**, list commands return a uniform envelope instead of their
per-command key (`issues`, `docs`, `proposals`, `entries`):

```json
{"ok": true, "data": {"items": [...], "total": 42, "truncated": true}}
```

- `total` is the number of matching records **before** `--limit` is applied.
- `truncated` is `true` when `--limit` dropped records.

This closes a silent-drop bug: under v1, `docket next --limit 10` and
`docket issue log --limit 10` report `"total": 10` whether 10 or 10 000 records
matched. Under v2 both report the true total and set `truncated`.

Single-entity responses remain verb-specific. Versioned issue responses add
`version` under v2 for optimistic concurrency. `issue show` and `step show`
with one ID return an object under `data`; with multiple IDs they return an
array of those objects. Do not assume every show verb carries the same fields.

Under v2, a **negative** `--limit` is a `VALIDATION_ERROR` on every list verb.
Under v1 the legacy behaviors are preserved unchanged (`issue list` and `next`
treat it as unlimited; `issue log` clamps it to 1).

### Error codes & exit codes

Ordinary command errors use this table in JSON and human mode. **Guards are
the exception: exit 0 allows and exit 2 denies.** A guard denial is not
`NOT_FOUND`; read its reason. See [guard contracts](../reference.md).

| `code` | Exit code | Meaning |
|---|---|---|
| `GENERAL_ERROR` | 1 | Unclassified failure (DB error, I/O error, etc.) |
| `NOT_FOUND` | 2 | Referenced issue/doc/proposal/label/relation does not exist |
| `VALIDATION_ERROR` | 3 | Bad input: invalid enum value, missing required flag, mutually exclusive flags, non-interactive environment without required flags, invalid `--json` value, negative `--limit` under v2, `--if-version < 1` |
| `CONFLICT` | 4 | State conflict: duplicate relation, cycle detected, already-voted, non-empty DB on import without `--merge`/`--replace`, `--if-version` mismatch, a dispatch already open for the run, `next --run` while a dispatch is open or discrepancies exist, `dispatch verify` byte mismatch, `dispatch close` over an unreconciled discrepancy, `dispatch backfill-usage` repeating a `(step, attempt, unit)` already recorded, any dispatch verb finding no manifest open, `step annotate` on a step that has not finished, or `issue move --project` on an issue a run holds |
| `AUTH_ERROR` | 5 | The supplied capability token does not hold this lease (or the entity is unclaimed) |
| `STALE_LEASE` | 6 | The token is correct but the lease has expired — claim again |
| `TIMEOUT` | 7 | Reserved — no verb emits this yet |
| `UNTRUSTED` | 8 | Reserved — no verb emits this yet |
| `GONE` | 9 | `events list --since` names a cursor below the retained minimum: those events no longer exist |

Codes 1–4 retain their established numbers. Codes 5 and 6 are used by
capability/lease operations; 7 and 8 remain reserved; new codes append.

`events list --since` can return `GONE` after `events prune` removed the
requested history. No automatic retention sweep runs: without an explicit
prune, history remains available. On `GONE`, re-read current state and resume
from the sequence named in the diagnostic instead of claiming uninterrupted
coverage of the missing events.

Exit code `0` is command success, not proof that the command’s subject passed
a gate. Ordinary store-dependent commands return `NOT_FOUND` when the store
is absent; initialize it only when creating a store is within the request.
Guards instead allow an absent store as not applicable.

### Optimistic concurrency (`--if-version`)

The issue mutation verbs listed below carry a `version` counter. Pass
`--if-version N` to apply a change only if the issue is still at version `N`.
Other entities can use different names, such as run budget’s `row_version`;
consult their own contracts.

```bash
# Read .data.version and use that observed value on the edit.
docket issue show DKT-1 --json=v2
docket issue edit DKT-1 --json=v2 --if-version 7 -s in-progress
```

- Version matches → the write applies and the version increments.
- Version differs → `CONFLICT` (exit 4) and **nothing is written**.
- Entity is missing → `NOT_FOUND` (exit 2), not `CONFLICT`.
- `--if-version` below 1 → `VALIDATION_ERROR` (exit 3); versions start at 1.

Omitting `--if-version` preserves the previous last-writer-wins behavior. The
version still increments, so a concurrent CAS writer detects the change.

Read the current version from `.data.version` under `--json=v2`; v1 payloads do
not carry the field.

Verbs accepting `--if-version`: `issue edit`, status-only `issue move`,
`issue close`, `issue reopen`. Moving with `--project` refuses this flag.
On a conflict, read the new version and reconcile the intended edit before
retrying; do not convert a stale write into an unconditional overwrite.

### Idempotency keys (`--idempotency-key`)

Create verbs accept `--idempotency-key KEY`. Repeating a create with the same
key returns the **original** entity with exit 0 and creates nothing new — so a
retry after an interrupted tool response cannot duplicate work:

```bash
docket issue create --json=v2 -t "Deploy checklist" --idempotency-key deploy-2026-08-02
docket issue create --json=v2 -t "Deploy checklist" --idempotency-key deploy-2026-08-02
# → same DKT-N both times, one issue created
```

Keys are scoped per verb, so the same key on `issue create` and `doc create` is
two independent records. An empty `--idempotency-key ""` is a
`VALIDATION_ERROR`. Without the flag, creates are never deduplicated.

Verbs accepting `--idempotency-key`: `issue create`, `doc create`,
`vote create`, `run start`, `issue comment add`, `doc comment add`.

### Claims, leases, and capability tokens

`docket issue claim` takes a lease on an issue and mints a **capability
token**. The claim is atomic: exactly one of any number of concurrent claimants
wins, and the losers get `CONFLICT` (exit 4).

```bash
DOCKET_CLAIM_OUTPUT=$(docket issue claim DKT-1 --owner ci-runner-7 --json=v2) || exit
DOCKET_CAPABILITY=$(printf '%s' "$DOCKET_CLAIM_OUTPUT" | jq -er 'select(.ok == true) | .data.token') || exit
DOCKET_TOKEN="$DOCKET_CAPABILITY" docket issue heartbeat DKT-1 --json=v2
DOCKET_TOKEN="$DOCKET_CAPABILITY" docket issue release DKT-1 --json=v2
```

**The token is returned exactly once.** Only its hash is stored, so it cannot
be read back from the database. Capture it from the claim response; losing it
does not permit replacing a live claim. Inspect the current lease and worker
before reclaiming after expiry. It never appears in `issue show`, `issue list`, or `issue log`.

**Tokens pass via `DOCKET_TOKEN` or stdin, never argv.** There is no `--token`
flag on any verb: `ps` exposes argv to every user on a shared host. Pipe it
(`printf '%s' "$DOCKET_CAPABILITY" | docket issue heartbeat DKT-1 --json=v2`)
or use the environment on that invocation. Do not print capabilities into logs.
Shell variables need not survive separate Bash calls: use protected runner
state or an owner-only temporary file outside the tracked tree when needed,
and clean it up when the claim ends.

Refusals:

| Situation | Code | Exit |
|---|---|---|
| No token supplied to a token-requiring verb | `VALIDATION_ERROR` | 3 |
| Token does not hold the lease, or issue unclaimed | `AUTH_ERROR` | 5 |
| Token is correct but the lease expired | `STALE_LEASE` | 6 |
| Claiming an issue whose lease is live | `CONFLICT` | 4 |

`AUTH_ERROR` covers both "wrong token" and "unclaimed" deliberately — a caller
holding no capability learns nothing about whether a lease exists.
`STALE_LEASE` is distinct because it means *re-claim*: the token was right,
time ran out.

**Expiry is the liveness mechanism.** A lease that lapses without release
returns the issue to the unclaimed pool: the next claim simply wins, and
`attempt` records that a claim was made. No reaper runs — expiry is resolved by
the next issue claim. Issue inspection reports *effective* status without
reaping, so an expired lease shows `"live": false` the instant it lapses.
This is distinct from step scheduling: `next --run`, `dispatch open`, and
`step claim` can reap step leases or otherwise mutate scheduling state.

```bash
docket issue show DKT-1 --json=v2 | jq '.data.lease'
# {"owner":"ci-runner-7","expires_ms":1754161200000,"attempt":1,"live":false}
```

`attempt` counts claims for all time — never decremented, never reset — so a
killed worker's claim and its successor's both appear.

The `lease` object is **`--json=v2` only**, and absent entirely when the issue
is unclaimed. An issue that is never claimed behaves exactly as it did before
leases existed on every verb.

`docket issue close` ends a live lease as a side effect. The holder may always
close; a non-holder closing a live-leased issue is refused `AUTH_ERROR`, so a
bystander cannot silently evict a working holder. Closing an **unclaimed**
issue needs no token.

A database lease does not terminate a process or isolate a worktree. Confirm
a prior writer has stopped before acknowledging a reap and admitting another
writer. For step tokens, completion retirement, and dispatch acknowledgments,
read [the CLI reference](../reference.md).

### Interactive forms

Several write commands (`issue create`, `issue delete` with sub-issues,
`vote create`, `vote cast`, `doc create`, `doc delete`, `label delete`)
fall back to an interactive `huh` form when required
flags are omitted and stdin is a TTY. `import --replace` is the one
exception: it requires `--yes` unconditionally, in every output mode and
regardless of terminal attachment — never a prompt, and never `--json` as
consent. (`issue comment` and `doc comment`
use a different fallback — they open `$EDITOR` when no message is piped
and stdin is a TTY; see [Comments](tracker.md#workflow-comments).) **In non-interactive/agent contexts
(no TTY) these commands return a `VALIDATION_ERROR` listing the missing
flags instead of hanging** — always pass all required flags explicitly
when scripting or running as an agent. `--json` mode never launches an
interactive form; missing required fields are always a hard
`VALIDATION_ERROR` in JSON mode.

---
## Workflow: Watch Mode

Any watch-eligible command (see [`--watch` eligibility](#--watch-eligibility))
can be re-run on an interval
instead of polling manually:

```bash
docket issue list --json=v2 --watch --interval 5s
docket board --watch                       # human-mode live board, default 2s interval
docket vote result DKT-V1 --watch --interval 1s
```

`--watch` is rejected with `VALIDATION_ERROR` on any command off the
allowlist, write or read-only (`docket issue create --watch` and
`docket project list --watch` both fail immediately). Watch mode runs until
`Ctrl-C` (SIGINT) or SIGTERM. In an agent session, give a watch an explicit
stop condition and keep it off a blocking foreground tool call when the user
needs continued interaction. Do not start indefinite watching for a one-time
status request.

---
