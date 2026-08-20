---
name: docket
description: >
  Comprehensive reference for using the Docket CLI (`docket`), a local-first,
  SQLite-backed issue tracker. Use this skill whenever the user asks to
  create, edit, list, move, close, or reopen issues; attach files, add
  comments, apply labels, or link relations between issues; generate an
  execution plan or find work-ready issues; create or cast a consensus vote
  ("run a vote", "start a proposal"); author, edit, or link a document; define
  or register a workflow ("set up a workflow", "register a pipeline"); watch
  live-updating output; export or import a Docket database; or any request
  to "use docket", "track this in docket", "create a docket issue", "check
  docket status", "run docket plan/next", "show the docket board", etc.
---

# Docket CLI Skill

Docket (`docket`) is a local-first, SQLite-backed issue tracker driven
entirely through a single CLI binary. There is no server and no network
call — all state lives in one SQLite `issues.db` file inside a **store**,
resolved via `internal/config` in this order:

1. **`DOCKET_PATH`** — taken as the store directory, normalized to absolute.
2. **A repo-local `.docket/` store** containing `issues.db`, discovered by
   walking from the cwd up to the git worktree toplevel (just the cwd
   outside a repository). The legacy per-repo layout keeps working wherever
   it already exists.
3. **The shared per-user store, `~/.docket`** — the default. Every
   repository resolving here is a **project** row in one database (see
   `docket project` below); issue ids are store-wide numbers.

This skill teaches an agent how to drive `docket` end to end: issue CRUD
and lifecycle, file attachments, comments, labels, relations, dependency
graphs, execution planning, consensus voting, docs, watch mode, and
export/import.

Every command supports **two output modes**: human-readable (default,
colorized via lipgloss when the terminal supports it) and machine-readable
JSON (`--json`). **Agents should always pass `--json`** for reliable
parsing — the examples below show both.

## Quick Start

```bash
docket init                                   # initialize the resolved store (~/.docket by default)
docket init --local                           # opt out: create a repo-local .docket store in the cwd
docket issue create -t "Fix login bug" --json # create an issue, get its ID back
docket issue list --json                      # list open issues
docket issue show DKT-1 --json                # show full detail incl. comments/activity
docket next --json                            # what's ready to work on right now?
```

Issue IDs are formatted `DKT-<n>` (e.g. `DKT-42`), document IDs `DOC-<n>`,
and proposal (vote) IDs `DKT-V<n>` — all three accept either the bare number
or the formatted string as CLI arguments (`model.ParseID`, `ParseDocID`,
`ParseProposalID` all strip the prefix case-insensitively). The issue prefix
is a **per-project display setting** (`docket project set-prefix`): another
project's issues may render `VOR-42`, but the number is the store-wide
identity and `DKT-` always parses whatever the prefix.

## Global Flags & Output Contract

Defined once on `rootCmd` in `internal/cli/root.go` and inherited by every
subcommand:

| Flag | Shorthand | Type | Default | Behavior |
|---|---|---|---|---|
| `--json` | — | string | `""` | Switch to machine-readable JSON envelope on stdout. Bare `--json` selects v1; `--json=v2` selects the uniform envelope. See below. |
| `--quiet` | `-q` | bool | `false` | Suppress non-essential human-mode info/warning lines on stderr. No effect in `--json` mode (already silent). |
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

### JSON envelope shape

All JSON output (`internal/output/json.go`) is a single-line JSON object
written to stdout via `json.Encoder` (HTML-escaping disabled).

Success:
```json
{"ok": true, "data": { ... }, "message": "Created DKT-1: Fix login bug"}
```
`message` is `omitempty` — it is present on success responses but callers
should not depend on it being non-empty for every command.

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
| `--json` (bare) | JSON v1 | byte-identical to the pre-v2 output |
| `--json=v1` | JSON v1 | explicit form |
| `--json=true`, `--json=1` | JSON v1 | retained from the boolean-flag era |
| `--json=v2` | JSON v2 | uniform envelope, see below |
| `--json=false`, `--json=0` | human | retained from the boolean-flag era |
| anything else | `VALIDATION_ERROR` (exit 3) | e.g. `--json=v3` |

**v1 is frozen, with one recorded amendment.** New response data appears under
v2 only, which is what makes `--json` safe for existing scripts.

The amendment is DKT-55: an issue's `scope` reaches the **v1** payload of
`issue show` and `issue list` **when the issue declares one, and only then**.
An issue with no declared scope emits no `scope` key and stays byte-identical
to the pre-scope shape, so a repo that never passed `--scope` sees a v1 that
has not moved; a declared-but-empty scope emits `[]`. The amendment was made
because the declaration is the fact an operator checks first, and it was
invisible on the surface everyone reads. Nothing else amends v1.

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

Commands returning a single entity (`issue show`, `issue create`, …) are not
wrapped — v2 returns the same object as v1, plus a `version` field (see
Optimistic concurrency below).

Under v2, a **negative** `--limit` is a `VALIDATION_ERROR` on every list verb.
Under v1 the legacy behaviors are preserved unchanged (`issue list` and `next`
treat it as unlimited; `issue log` clamps it to 1).

### Error codes & exit codes

Defined in `internal/output/json.go`. The process exit code always matches
the table below, in both JSON and human mode (`ExitCodeForError`):

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

Codes 1–4 and their exit numbers are a frozen contract and are never
renumbered. Codes 5–8 are declared ahead of the verbs that will raise them, so
the taxonomy is fixed once rather than extended per feature. `GONE` **appends**
at 9 rather than taking exit 6 — that number is `STALE_LEASE`, which emits today,
and two codes sharing one exit would be indistinguishable to a script testing
`$?`. New codes only ever append.

**`GONE` is reached by `docket events prune`, and by nothing else.** The engine
never deletes an event on its own — there is no retention sweep, no compaction at
`run done`, and no prune inside `next` — so a repo whose operator has never run
that verb retains the first event ever written and can never answer `GONE` to
anybody. Once something *has* been pruned, a cursor naming events below what
survives gets this code and a message naming the `seq` to resume from.

Exit code `0` is success. Note `PersistentPreRunE` also returns `NOT_FOUND`
(exit 2) if the resolved store has no database yet — run `docket init` first.

### Optimistic concurrency (`--if-version`)

Every mutable entity carries a `version` counter that increments on each
mutation. Pass `--if-version N` to a mutating verb to apply the change only if
the entity is still at version `N`:

```bash
V=$(docket issue show DKT-1 --json=v2 | jq -r '.data.version')
docket issue edit DKT-1 --json=v2 --if-version "$V" -s in-progress
```

- Version matches → the write applies and the version increments.
- Version differs → `CONFLICT` (exit 4) and **nothing is written**.
- Entity is missing → `NOT_FOUND` (exit 2), not `CONFLICT`.
- `--if-version` below 1 → `VALIDATION_ERROR` (exit 3); versions start at 1.

Omitting `--if-version` preserves the previous last-writer-wins behavior. The
version still increments, so a concurrent CAS writer detects the change.

Read the current version from `.data.version` under `--json=v2`; v1 payloads do
not carry the field.

Verbs accepting `--if-version`: `issue edit`, `issue move`, `issue close`,
`issue reopen`.

### Idempotency keys (`--idempotency-key`)

Create verbs accept `--idempotency-key KEY`. Repeating a create with the same
key returns the **original** entity with exit 0 and creates nothing new — so a
retry after a dropped connection cannot duplicate work:

```bash
docket issue create --json -t "Deploy checklist" --idempotency-key deploy-2026-08-02
docket issue create --json -t "Deploy checklist" --idempotency-key deploy-2026-08-02
# → same DKT-N both times, one issue created
```

Keys are scoped per verb, so the same key on `issue create` and `doc create` is
two independent records. An empty `--idempotency-key ""` is a
`VALIDATION_ERROR`. Without the flag, creates are never deduplicated.

Verbs accepting `--idempotency-key`: `issue create`, `doc create`,
`vote create`, `issue comment add`, `doc comment add`.

### Claims, leases, and capability tokens

`docket issue claim` takes a lease on an issue and mints a **capability
token**. The claim is atomic: exactly one of any number of concurrent claimants
wins, and the losers get `CONFLICT` (exit 4).

```bash
TOKEN=$(docket issue claim DKT-1 --owner ci-runner-7 --json | jq -r '.data.token')
DOCKET_TOKEN="$TOKEN" docket issue heartbeat DKT-1     # extend while working
DOCKET_TOKEN="$TOKEN" docket issue release DKT-1       # or close, when done
```

**The token is returned exactly once.** Only its hash is stored, so it cannot
be read back from the database — capture it from the claim response or claim
again. It never appears in `issue show`, `issue list`, or `issue log`.

**Tokens pass via `DOCKET_TOKEN` or stdin, never argv.** There is no `--token`
flag on any verb: `ps` exposes argv to every user on a shared host. Pipe it
(`echo "$TOKEN" | docket issue heartbeat DKT-1`) or export it.

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
the next claim — and **no read verb ever writes**. Reads report *effective*
status, so an expired lease shows `"live": false` the instant it lapses:

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

See `docs/spec/security.md` for the full token model, including what a lease
does and does not defend against.

### Engine configuration (`docket config set|get`)

Engine defaults live in the database and are read by the claim machinery:

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

**A class is whatever string your steps carry, and a step that declares no
`class` carries its `executor` name** (DKT-260). So `lease.ttl.read` binds
nothing unless your definitions actually say `class = "read"` — and in a corpus
where steps declare no class, the only strings that ever appear in that column
are executor names, which is not what "per-class lease TTL" suggests. The cost
of the mismatch is not cosmetic: every unforced reap of one epoch killed a
*healthy* step 15–30 minutes into its claim against a 15m default, and reap is
a database fence — it marks the claim dead and cannot stop a process that is
still running, so a wrongly-reaped write step means two processes editing one
tree.

**Docket cannot supply `read` and `write` classes of its own.** The class name
is the workflow author's; core is deliberately blind to it (the headroom
mechanism keys on the declared `[limits] max`, never on a name, and a source
guard asserts core contains no `"write"` literal). Declare the classes you want
to configure.

`docket config set lease.ttl.<class>` **warns** when no registered workflow
declares that class, naming the ones that do. A warning and not a refusal —
configuring ahead of a workflow is ordinary — but a TTL that binds nothing is
otherwise discovered when a healthy step is reaped mid-run.

```bash
docket config set lease.ttl.write 45m
docket config get lease.ttl.write --json     # {"key":...,"value":"45m","source":"set"}
docket config get                            # every key, with its source
```

`source` is `set` or `default`, so "nobody configured this" is distinguishable
from "configured to the same value". An unknown key or a value of the wrong
type is a `VALIDATION_ERROR` (exit 3) at `set` time — a typo never silently
stores a key nothing reads. The class in `lease.ttl.<class>` is an opaque
string; docket never interprets it.

Under the shared store, config is **layered per project**: a read resolves the
current project's override, then the store-wide value, then the built-in
default (the first two both report `source: set`). `config set --global`
writes the store-wide default instead of this project's override, and
`config get --global` reads the store-wide values ignoring this project's
overrides.

**Vote rules.** A workflow's `type="vote"` step names a rule rather than passing
flags, because a step cannot pass flags. A rule *exists* iff its `.threshold` is
set — criticality has a default, so it cannot be the existence test:

```bash
docket config set vote.rule.majority.threshold 0.6
docket config set vote.rule.majority.criticality high
```

`<name>` is opaque, exactly as the lease class is. A step whose `vote_rule`
names an unregistered rule is refused at `workflow register` (V26), naming the
rule and listing the registered ones — a workflow that cannot possibly tally
should not register. Note that `required_voters` comes from the step's own
`voters` list, not from the rule: a rule is about *how strictly to tally*, the
step about *who casts*.

**Held steps by tally.** A materialized `<step>-held` step is the one row in a
run no author wrote, so it has no `[[step]]` table to carry `voters` and
`vote_rule`. `vote.hold.rule` and `vote.hold.voters` are where an instance says
them instead:

```bash
docket config set vote.rule.panel.threshold 0.6
docket config set vote.hold.rule panel
docket config set vote.hold.voters alice,bob,carol
```

**BOTH keys are required, and unset is a strict no-op:** with either missing,
holds are minted `human` exactly as they always were, and one operator approves
or rejects them. With both set they are minted `vote` and flow through the
ordinary vote lifecycle. The escalation is one-directional:

- **pass** — the computed value stands, identical to `step approve` on the
  cluster. The payload records `operator_resolved` and the aggregate resumes.
- **anything else** — the step **parks** at `waiting-human` and the question
  passes to an operator, who answers it with `step approve` (including
  `--value`) or `step reject`. A tally may confirm the engine's own computation
  and may never overrule it, so a panel that could not agree cannot produce the
  effect of an operator who declined.

The MINTED KIND is what persists: config supplies the roster, the step row
supplies the question's type. Editing or clearing these keys mid-run changes who
casts on holds minted *after* the edit, never what an already-open question is.

### Interactive forms

Several write commands (`issue create`, `issue delete` with sub-issues,
`vote create`, `vote cast`, `doc create`, `doc delete`, `label delete`)
fall back to an interactive `huh` form when required
flags are omitted and stdin is a TTY. `import --replace` is the one
exception: it requires `--yes` unconditionally, in every output mode and
regardless of terminal attachment — never a prompt, and never `--json` as
consent (DKT-15). (`issue comment` and `doc comment`
use a different fallback — they open `$EDITOR` when no message is piped
and stdin is a TTY; see the Comments section below.) **In non-interactive/agent contexts
(no TTY) these commands return a `VALIDATION_ERROR` listing the missing
flags instead of hanging** — always pass all required flags explicitly
when scripting or running as an agent. `--json` mode never launches an
interactive form; missing required fields are always a hard
`VALIDATION_ERROR` in JSON mode.

---

## Workflow: Issue Creation & Editing

Create an issue (only `--title` is required in JSON mode):

```bash
docket issue create --json \
  -t "Add rate limiting to API" \
  -d "Prevent abuse on public endpoints" \
  -s todo -p high -T feature \
  -l backend -l must-have \
  -f internal/api/router.go \
  -a "@alice"
```

Description can be piped from stdin with `-d -`:

```bash
echo "Long description..." | docket issue create --json -t "Title" -d -
```

Edit only the fields you pass — `issue edit` uses `cmd.Flags().Changed(...)`
so omitted flags are left untouched, not reset to zero values:

```bash
docket issue edit DKT-1 --json -s in-progress -a "@bob"
docket issue edit DKT-1 --json --parent DKT-5      # reparent
docket issue edit DKT-1 --json --parent none        # make it a root issue again
docket issue edit DKT-1 --json -f a.go -f b.go       # REPLACES the file list (not additive)
```

Reparenting validates against cycles (`db.IsDescendant`) and rejects
self-parenting with `VALIDATION_ERROR`/`CONFLICT`.

Status transitions and other lifecycle commands:

```bash
docket issue move DKT-1 review --json     # arbitrary status transition
docket issue move DKT-1 --project vorpal --json  # migrate issue + subtree to another project
docket issue close DKT-1 --json           # shorthand for: move <id> done
docket issue reopen DKT-1 --json          # shorthand for: move <id> backlog (only if currently done)
docket issue delete DKT-1 --json --force  # cascade-delete issue + all sub-issues
docket issue delete DKT-1 --json --orphan # delete issue, promote sub-issues to root
```

Valid `--status` values: `backlog`, `todo`, `in-progress`, `review`, `done`.
Valid `--priority` values: `none`, `low`, `medium`, `high`, `critical`.
Valid `--type`/`-T` values: `task`, `bug`, `feature`, `epic`, `chore`.

List and inspect:

```bash
docket issue list --json -s todo -s in-progress -p high --tree
docket issue show DKT-1 --json     # full detail: sub-issues, relations, comments, activity, docs
docket issue log DKT-1 --json --limit 50
```

---

## Workflow: File Attachment (`docket issue file`)

```bash
docket issue file add DKT-1 --json internal/api/router.go internal/api/middleware.go
docket issue file list DKT-1 --json
docket issue file remove DKT-1 --json internal/api/router.go
```

`add`/`remove` take 2+ positional args (`id` then one or more file paths) —
there is no `-f` flag on `issue file add`; that's only on `issue create -f`
and `issue edit -f`. Files are additive on `file add` (unlike `issue edit
-f`, which replaces the whole list).

---

## Workflow: Comments

```bash
docket issue comment add DKT-1 --json -m "Investigated — root cause is a stale cache key"
docket issue comment list DKT-1 --json
```

`-m`/`--message` is optional: if omitted and stdin is a pipe, the body is
read from stdin; if omitted and stdin is a TTY (human mode only), `$EDITOR`
(default `vi`) is opened. In `--json` mode, `-m` (or piped stdin) is
required — there is no editor fallback.

---

## Workflow: Labels & Relations

```bash
docket issue label add DKT-1 --json backend must-have --color "#ff0000"
docket issue label rm DKT-1 --json must-have
docket issue label list --json
docket issue label delete backend --json --force   # --force skips the attached-issue-count confirmation

docket issue link add DKT-1 --json blocks DKT-2      # DKT-1 blocks DKT-2
docket issue link add DKT-1 --json depends_on DKT-3   # DKT-1 depends_on DKT-3
docket issue link remove DKT-1 --json blocks DKT-2
docket issue link list DKT-1 --json
```

Valid `<relation>` values (`model.RelationType`): `blocks`, `depends_on`,
`relates_to`, `duplicates`.

---

## Workflow: Dependency Graph (`docket issue graph`)

```bash
docket issue graph DKT-1 --json --direction both --depth 2
docket issue graph DKT-1 --mermaid --direction down   # Mermaid flowchart, human-readable only
```

`--direction` must be one of `up` (what blocks this), `down` (what this
blocks), or `both` (default). `--depth 0` (default) means unlimited BFS
traversal. Use this before touching a shared interface to assess blast
radius.

---

## Workflow: Planning (`docket plan` and `docket next`)

`docket plan` groups all non-done issues into dependency-ordered execution
phases (topological sort; a cycle returns `CONFLICT`):

```bash
docket plan --json
docket plan --json --root DKT-1                      # scope to a parent issue's subtree
docket plan --json -s backlog -s todo -l must-have    # filter by status/label
docket plan --json -p high -p critical -T bug -a alice # filter by priority/type/assignee
```

`docket next` finds work-ready issues — no incomplete blockers, in one of
the ready statuses (default `backlog`,`todo`):

```bash
docket next --json
docket next --json -s todo -p high -p critical -l must-have --limit 5
```

On docket.git itself (the engine repo), backlog defect sweeps run directly
in-session — plain edits, tests, commits — unless the operator asks for a
run: the plan/conduct pipeline is for corpus-governed work, and routing an
engine-repo sweep into `run start` has cost an operator interrupt and an
abandoned run (2026-08-17).

---

## Workflow: Workflow definitions (`docket workflow`)

A **workflow** is a declarative description of the steps a piece of work goes
through: what runs, in what order, what each step needs from the ones before
it, and what happens when something fails. It is a TOML file you register into
the database; nothing about it is specific to any kind of work or any kind of
worker.

Start from a shipped template and register what it writes:

```bash
docket workflow init --template standard-dev
# → wrote .docket/config/workflows/standard-dev.toml
docket workflow lint .docket/config/workflows/standard-dev.toml --json
docket workflow register .docket/config/workflows/standard-dev.toml --json
docket workflow list --json
docket workflow show standard-dev --json
```

At this stage registration is all that happens: a registered workflow is
stored, inspectable, and validated, but nothing runs it yet. A repo that never
registers one behaves exactly as it did before workflows existed.

### Shipped templates

| Template | Shape |
|---|---|
| `standard-dev` | two steps — run the checks, then have a person approve. One fenced-command gate, no fanout. |
| `parallel-check` | prepare → several checks in parallel → summarize → verify. Fanout with a join quorum. |

Both are ordinary definitions, byte-identical to files you could have typed,
and both are asserted to register cleanly by a test.

### Registration is content-addressed and immutable

A registered `name@version` is **frozen**:

| Second registration of… | Result |
|---|---|
| the same bytes | success, returns the existing row, changes nothing |
| **different** bytes at the same `name@version` | `CONFLICT` (exit 4), naming both hashes |
| any bytes at a new `version` | an ordinary registration |

To change a workflow, bump `[pipeline].version`. This exists so that pinning
means something: a run that pinned `name@version` cannot have the definition
swapped underneath it.

`register` accepts `-` to read stdin, so configuration generated in a pipeline
needs no temp file:

```bash
generate-workflow | docket workflow register - --json
```

### Checking a draft without registering it (`docket workflow lint`)

Registration is a persistent write: it inserts a row and freezes a
`name@version`. Checking a draft that way either accumulates versions nobody
wanted or does not happen at all — so `lint` runs the identical validation and
**writes nothing**:

```bash
docket workflow lint .docket/config/workflows/standard-dev.toml --json
# → {"name":"standard-dev","version":1,"sha256":"…","registration":"new"}
generate-workflow | docket workflow lint - --json     # `-` reads stdin
```

It is the **same pipeline `register` runs**, call for call: grammar and step
rules, vote rules against the config registry (V26), and threshold fields and
literals against the registered schemas. The two cannot report different
verdicts on the same bytes.

The registry is **consulted, never written**, and the verdict says what a real
register would do:

| `registration` | Meaning |
|---|---|
| `new` | nothing holds this `name@version`; a register would insert |
| `unchanged` | the same bytes are already registered; a register would be an idempotent success |
| *(refusal)* | **different** bytes hold this `name@version` — `CONFLICT` (exit 4), naming both hashes and the version to bump `[pipeline].version` to |

**The conflict case fails the lint rather than reporting a third outcome.** A
definition that cannot register as it stands has not passed a check — and that
case is the trap this verb exists for: an edited file at a frozen `name@version`
validates cleanly and then refuses the *whole activation* the next time a run
starts.

### Retiring a version from binding (`docket workflow deprecate`)

A registered **name** binds forever at its highest version, and deleting its
TOML does not unregister it — nothing removes a `workflows` row. `deprecate`
retires one version from binding without deleting it:

```bash
docket workflow deprecate standard-dev@1 --json
docket workflow deprecate standard-dev@1 --json --restore   # back into binding
```

The row survives and stays fully readable: `workflow show` renders it,
`--source` emits the exact registered bytes, and a run that already **pinned**
it still resolves it and still completes. Only its candidacy for NEW bindings
stops — matching picks the highest **non-retired** version of each name, so
retiring the top version falls back to the one beneath it, and retiring every
version of a name takes that name out of routing entirely.

A retired version reports `deprecated_at_ms` under `--json=v2` (see
`workflow list` below) and prints `[deprecated]` in human mode.

### `docket workflow` refusals

| Situation | Code | Exit |
|---|---|---|
| Grammar, validation, or lint failure | `VALIDATION_ERROR` | 3 |
| `payload` names a schema that is not registered | `VALIDATION_ERROR` | 3 |
| A threshold names a field its declared schema does not declare | `VALIDATION_ERROR` | 3 |
| A threshold literal is not a value its declared schema allows | `VALIDATION_ERROR` | 3 |
| An ordered comparison (`>=`, `>`, `<=`, `<`) on a field with no `ordered_enum` | `VALIDATION_ERROR` | 3 |
| A step emitting the reserved kind `gate-results` | `VALIDATION_ERROR` | 3 |
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
key and its step — a typo'd `max_attempt` silently taking a default is exactly
the bug that makes a workflow behave differently from what its author read.

```toml
[pipeline]
name    = "standard-dev"       # required; runs pin name@version
version = 1                    # required, integer >= 1
description = "…"              # optional

[match]                        # which issues bind to this workflow
                               # evaluated over the HIGHEST version of each name
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
emits = "check-report"
```

**`[limits]` keys, and what each bounds.** A class is an opaque string; these
are the only three things a bound on one does.

| Key | Bounds |
|---|---|
| `max` | how many steps of the class may be `claimed`/`running` at once. A **finite** `max` is also what makes the class write-class for the reap acknowledgment below — a class with no `max` gets neither ack rows nor a headroom hold |
| `lease_ttl` | the lease a claim of this class takes, overriding `docket config lease.ttl.<class>` |
| `max_step_duration` | a **schedule-to-close** bound measured from the claim, **independent of heartbeats** |

`max_step_duration` is the one worth stating plainly: a step past it is reaped
**even with a live lease and a fresh heartbeat**, which is the whole difference
between it and a lease TTL. A runaway holder cannot renew forever. It is a
`[limits]` key on the workflow class — there is no `docket config` key for it.

**Both reaps are scoped to an ACTIVE run.** A lease that lapses while a run sits
in `waiting-human` is not reaped, and neither is a step past its
`max_step_duration` there. A TTL is a bet that a silent worker is dead and its
step is better re-offered; on a run that is not active nothing would be offered
anyway, so the reap is pure loss — it clears a live worker's lease and takes a
write-reap hold on its class. This is a **suspension, not an exemption**: no
expiry is rewritten, so the first `next` after the run returns to `active` reaps
what came due meanwhile. It matters because the state is ordinary rather than
exotic — a run parks when *any* step is parked, leaving that step's siblings
legitimately `claimed` at `waiting-human`.

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
| `payload` | `name@version` | a registered payload schema; the step's `--payload-file` is validated against it at `complete`, from the bytes the run pinned |
| `voters`, `vote_rule` | [hints], name | **required on `type="vote"`**, forbidden elsewhere |
| `after` | [step names], **required** except on the first step and `loop = true` steps | predecessors; `[]` means root |
| `inputs` | [`"<step>.<kind>"` \| `"<step>.*"` \| `"<step>.gate-results"` \| `"issue.body"` \| `"issue.diff"`] | artifacts delivered to the step |
| `holds_tree` | bool, **default true** | whether this step OCCUPIES its issue's scope while it runs. It is what scope exclusion consults, and what decides whether the step's completion records an `issue.diff` |
| `gates` | [name \| `{name, source="fence:<tag>", pre=bool}`] | checks; `pre = true` runs at claim |
| `params` | opaque table | arguments to an `action` step |
| `min_siblings` | int, default = all | how many fanout siblings the join needs |
| `threshold` | table: routing → predicate | routing computed from the step's results |
| `on_fail` | `"fix-loop"` \| `"waiting-human"` \| `"skip"` \| `"abandon-issue"`; default `"waiting-human"` | where a failure routes. **Required explicitly on `type="human"` and `type="vote"` steps** — the default is a routing nobody chose |
| `loop` | bool, default false | marks a loop-body step |
| `after_loop` | step name | where execution re-enters after a loop body |
| `max_attempts` | int ≥ 1 | per-instance retry budget |
| `max_fix_loops` | int ≥ 0 | loop-entry budget per issue |
| `expected_cost` | number ≥ 0, default 0 | the step's contribution to the run's budget floor, accrued **per claim**. Per expanded sibling on a fanout — four siblings accrue four times, no proration |
| `when` | predicate over `kind` / `labels` | step is skipped when false |
| `metadata` | opaque table | recorded and delivered verbatim |
| `packet` | list of paths, relative to `.docket/config/` | files inlined into the step's rendered work packet, **in declared order**. Each must be pinned by the run (they are, automatically, if they live under `.docket/config/`); an entry the run did not pin is refused **at activation**. An entry may carry the `{executor}` token, substituted with that sibling's executor hint — which is how one `fanout` step gives each sibling a different file. Docket reads their bytes and never interprets them |

**`packet` inlines files; it never points at them.** The rendered packet carries
each file's **body**, delimited and labeled with its path and hash, so a worker
receives one document rather than a list of things to go read. Bytes are
admitted only when they hash to what the run pinned: a file edited after
activation is `CONFLICT` (exit 4) naming **both** hashes, and one deleted is
`NOT_FOUND` (exit 2). That is what makes a packet reproducible — same step, same
packet, byte-identical, even mid-run.

A packet file may declare more files in a `packet_includes:` frontmatter list,
and those are inlined immediately after it. **That is the only frontmatter key
Docket reads** — every other key is ignored entirely, not validated and not
surfaced — and includes are followed **exactly one level deep**. A malformed
`packet_includes` is `VALIDATION_ERROR` at render, naming the file; a declared
include that is missing or unpinned is refused rather than silently omitted.

#### Engine-produced inputs

Three `inputs` forms resolve to something the engine recorded rather than to a
step's declared artifact.

`issue.body` is the activation snapshot. `issue.diff` is the run's computed VCS
diff, and **it is recorded only at the completion of a step that holds the
tree** — `holds_tree`, default true, the same declaration scope exclusion reads.
A non-holding step records nothing, and its consumers resolve to the artifact
the last **holding** step recorded: the reviewed object, pinned at the moment
the change existed, byte-identical for every sibling that reads it. Recomputing
at every executor completion was the defect this closes — read-shaped fanout
siblings each re-diffed the *live* tree at their own record time, so a diff
taken after the change landed came out empty and one taken beside a sibling's
in-flight probe carried the probe. Action, human, and vote steps never record a
diff either; with no diff artifact at all, the input resolves to an **empty
diff**, never an error and never a live `git diff`.

**The bundle carries a machine-readable target ref (DKT-24).** Context
assembly lifts the resolved `issue.diff` artifact's round record onto the
bundle as `target_sha` — the commit the diff's tree stood at — and
`target_worktree` — the producing record's declared worktree path, good while
that checkout is still on disk (it is swept at integration). Both are omitted
entirely when the resolved diff carries no round record. The default packet
template states them in its header, so a reviewing consumer no longer
re-derives the tree from a prose convention in the change-summary's first
line. They are exactly as reproducible as the input they describe.

`<step>.gate-results` is the named step's **recorded** gate results, served from
the ledger rather than re-run — one input per `done` producer instance, carrying
a JSON array in §11.4's gate-result shape (`gate`, `ordinal`, `argv`, `exit`,
`duration_ms`, `output`, `truncated`, `verdict`, `pre`, `reason`), the same
shape a claim response's `pre_gates` carries. Instance selection mirrors
ordinary artifact resolution — same issue, `done` only, ordinal-scoped with
the per-input fallback, siblings in index order — with one departure (DKT-12):
the **requesting step admits itself regardless of status**, so a self-declared
`<self>.gate-results` reads the step's own claim-time `pre = true` rows (which
commit before context assembly, while the step is still `claimed`).
Completion-side rows, not yet recorded at claim, show up as the empty array.

```toml
inputs = ["implement.change-summary", "implement.gate-results"]
```

The producer **must be a step of this workflow**, but need not declare gates:
a producer that recorded none resolves to an **empty array**, not an absent
input, because "this step ran no checks" is an answer a consumer can act on
while a missing input reads as a resolution failure. (Gates can also arrive
from a `fence:` source the definition does not enumerate, so requiring a
declaration would refuse correct workflows.) `gate-results` is a **reserved
kind**: a step emitting it is refused at `workflow register` (V11a), since an
artifact of that kind could never be addressed — the engine-served form would
shadow it.

**`after` is required, and `after = []` is how you declare a root.** Implicit
topology was a footgun: a step that forgets `after` would silently become a
root and run first. Only the first step and `loop = true` steps may omit it.

**Every gate step must declare `on_fail` explicitly — `type="human"` and
`type="vote"` alike (V13a).** The default is `waiting-human`, so a gate that
declares nothing has a routing its author never chose.

**A `type="human"` step additionally may not route rejects to `waiting-human`**
(V13): it would park the issue on the resolution of the very thing that just
rejected it, a deadlock. Legal values there are `fix-loop`, `skip`, and
`abandon-issue`.

**A `type="vote"` step MAY route to `waiting-human`**, and often should: on a
vote gate that routing is the ESCALATION — a tally that did not reach its
threshold decided nothing, so the question passes to an operator who has not
been asked yet, which is not a wait on the decider that just declined. All four
values are legal there. Because both readings are defensible, the grammar makes
you say which you mean rather than inheriting one silently.

`threshold` predicates have the shape `agg(field op literal)` with
`agg ∈ {any, all, count>=n}` and `op ∈ {==, !=, >=, >, <=, <}`; routings are
`fix-loop`, `waiting-human`, `pass`, or a step name (which interposes that step
as a gate). Routings are evaluated **top to bottom, first match routes**, and
no match routes `pass`.

**An interposed gate runs only when routed to.** A step named as a step-name
routing target — author it with `after = [routing-step]` — is latched by
readiness until a routing predecessor's **recorded** routing names it, and when
the routing resolves anywhere else it is terminalized `skipped` in the same
routing transaction, so joins and issue completion resolve without it. A
`next --run` offer may still carry such a gate in its staged closure, marked
`conditional`: confirm the predecessor actually routed to it before spawning
anything for it.

**Fields and literals are still opaque tokens to docket — but they are checked
against your schema.** When a step declares a `payload`, `workflow register`
verifies that every predicate's field is one the schema declares, that every
literal is a value that field accepts, and that any ordered operator
(`>=`, `>`, `<=`, `<`) names a field the schema marks `ordered_enum`. Docket
learns that `high` comes after `medium` because your document said so; it holds
no opinion about what either word means.

A step with a `threshold` and **no** `payload` is legal and unchanged:
equality has never needed an order. An ordered comparison over such a field
**parks the step** `waiting-human` with a reason naming the predicate — docket
declines rather than guessing an order.

**Executor hints are opaque.** `executor`, `fanout` entries, `voters`, and
`class` are strings docket stores, echoes back, and uses as map keys. There is
no registry of known executors and no behavior keyed on the value: put role
names, team names, or people's names there and they mean what you intend.
`params` and `metadata` are likewise opaque — docket never reads a key inside
them.

### Gates — what actually runs

A gate is a check a step must pass. It comes in two spellings:

```toml
gates = ["tests"]                                       # a named gate
gates = [{ name = "checks", source = "fence:checks" }]  # commands from the issue body
gates = [{ name = "measure", pre = true }]              # runs at claim, not at complete
```

**A gate name is an opaque string.** Docket looks it up in your trust store and
never interprets it — there is no registry of known gates, no gate whose name
has behavior, and no default gate.

**Every gate needs a matching trust entry or it does not run** (see
`docket trust` below and security.md §7). An unmatched gate is recorded
`verdict: "unmatched"` with null `argv` and null `exit`, nothing spawns, and
**the step fails** and routes per `on_fail`. A workflow whose check cannot run
has not passed its check.

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

**`skipped` means nothing was measured**, and it is a different fact from
`fail`. A gate measures the tree its step is about to judge; when that tree
cannot be bound, docket **records `skipped` rather than measuring a different
tree**. A pass collected in the shared checkout, while the change under review
lives somewhere else, is a verdict with no evidence value — and one that reads
as green.

Docket tries to avoid the skip first. A worktree that has been swept (integration
removes them between waves) is **reconstructed from the object database**: the
commit is still there, so the tree is rebuilt in a throwaway detached checkout,
measured, and removed. Those rows say so in their `reason`. Only when the commit
itself is unreachable does the gate skip, and the reason names the sha so you
know what to fetch.

A step whose gates recorded `skipped` **parks at `waiting-human`** — not its
`on_fail`. Nothing is known about the change, so a fix loop would ask a worker to
fix a tree nobody read, and a judge panel would deliberate over an infrastructure
condition. What *is* known is something an operator can act on. `skipped` is
counted in its own column in `run report`, beside `pass` and `fail`.

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
| `DOCKET_GATE_NETWORK` | the trust entry's declared hosts, comma-joined — set only when it declared any, alongside the proxy variables |

`DOCKET_ISSUE` and `DOCKET_SCOPE` are what let a **diff-shaped** gate evaluate
the change it is actually gating instead of the whole dirty tree. The globs are
newline-joined rather than JSON because the consumer is a shell check reading
its own environment, where `while IFS= read -r glob` needs no parser. **Absent
is not empty**: an issue that declared no scope gives the check no narrower
answer than the tree, and inventing one would be docket deciding what the issue
touches.

The variable carries globs or nothing, so it is the one surface where declaring
no scope and declaring an empty one look alike — a declared-but-empty scope
leaves `DOCKET_SCOPE` unset too, rather than setting it to the empty string.
Everywhere the two are distinguishable they stay distinguished: v1's `scope`
key, and the activation lint that warns about the first and not the second. A
gate that must tell them apart reads `docket issue show`, not its environment.

There is no way to extend the allowlist — no flag, no config key, no trust-entry
field.

### Action steps — computations, not workers

An `action` step has no worker. It declares a computation and `params.output`,
which is the artifact kind it produces:

```toml
[[step]]
name    = "reconcile"
after   = ["synthesize"]
action  = "aggregate"
inputs  = ["synthesize.findings"]
payload = "findings@1"
params  = { field = "severity", method = "median", hold_spread = 2, output = "findings" }
```

**Nothing claims an action step.** `docket step claim` refuses one with
`CONFLICT` — "resolved by the engine, not by a worker" — the same way it refuses
a `human` or `vote` gate. The engine runs it, records its artifact, and routes.
It still appears in `docket next --run` so a dispatcher can see what a run is
doing; the row simply carries no `executor` to spawn.

**Resolution is builtin-first.** `aggregate` is the one computation docket
performs itself; every other action name is looked up in your trust store and
run as a **user-trusted command**, through the same matching, argv resolution,
env allowlist, timeout, capture, and repo containment a gate goes through. There
are no exceptions and no second execution path. The name `aggregate` is
reserved, so a trust entry cannot shadow it — `workflow register` says so rather
than leaving you to wonder why your command never ran.

An unmatched action name records `verdict: "unmatched"` with null `argv` and
null `exit`, spawns nothing, and **fails the step**, which routes per `on_fail`.
A computation that could not run has not succeeded.

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
declared `inputs` artifacts**, resolved by the ordinary input rules — `done`
producers only, in declared order, and scoped to the step's own loop ordinal. So
`inputs = ["synthesize.findings"]` means "reduce what `synthesize` recorded".
`inputs` must be non-empty on an `aggregate` step, refused at `workflow
register`: a step with nothing to read can never compute.

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

That is not caution. Docket does not know which end of your order is worse: a
rule that took "the more severe of the two" would be docket holding an opinion
about severities, which is simply wrong for a `confidence` or a `ripeness`
enum and invisible when it is. One expression, no special case, and the
standard lower median for ordinal data where no average exists.

**If that is the wrong end for your order, say so in the schema.** Docket cannot
know which end is worse, but *your order can*. Add `"conservative_end": "upper"`
beside the `ordered_enum` annotation and that field's even-count median ties
resolve toward the top of the declared order instead — `{low, blocker}` medians
to `blocker`. Declare nothing and the lower median is unchanged, which is what
keeps a `confidence` or `ripeness` order behaving exactly as it always has. See
[The `conservative_end` annotation](#the-conservative_end-annotation).

The direction moves the **median tie and nothing else**: `min` and `max` already
name an end explicitly, and an odd-count median has no tie to break. If you want
the top of the order in *every* case and not only on ties, that is `method =
"max"`, not a direction.

**Spread and holds.** `spread` is the distance between the extreme members'
**positions** — so with `["info","low","medium","high","blocker"]`, both
`{low, high}` and `{low, medium, high}` have spread 2. A cluster holds when
`hold_spread > 0 && spread >= hold_spread`.

**The demotion trail.** When the computed value's position is strictly below its
highest member's, the output records `demoted_from` with the value that was not
taken. When nothing was demoted the key is **absent**, not empty. `max` never
demotes.

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

- The routing step's status stays `gated`, which is non-terminal, so every
  downstream step waits. Its threshold is **not** evaluated yet.
- Each held step is offered by `next --run` immediately, takes no claim and no
  token, and shows up as an ordinary human gate — or as a vote gate, when
  `vote.hold.*` is configured (see *Engine configuration*). Everything below is
  the same either way; a tally simply answers first, and escalates to the
  operator's verbs below when it does not pass.
- `guard stop` **denies** while any is open, exactly as it does for a declared
  human gate awaiting approval. Stopping means resolving or abandoning first.
- The step-name suffix `-held` is **reserved**: you cannot declare a step whose
  name ends in it.
- **`#N` is the cluster's POSITION in the payload, not a cluster id.** A held
  step names its own provenance so the two cannot be confused: `step show`
  carries `held_cluster` — `cluster_index`, `cluster_count`, the `artifact`
  the payload lives on, and the `producer_step` that recorded it — and `step
  artifacts` on the row, which is legitimately empty because a hold produces
  nothing, names that artifact instead of stopping at "produced no artifacts"
  (DKT-239). Two clusters of one payload point at the SAME artifact, which is
  exactly what the index disambiguates.

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
routes on the number the operator actually endorsed, and the computed value it
replaced is recorded beside it as `operator_set_from` — the two records stay
distinguishable rather than one overwriting the other. `--note`, when given,
travels with the decision as `operator_note` on the same element, so a fixer
reading the resolved payload learns *what was decided* and not merely *that a
decision happened*.

| Rule about `--value` | |
|---|---|
| It is validated against the **pinned schema's declared enum** before anything is written | a correction must be a member of the membership set the run agreed to; a value outside it is a `VALIDATION_ERROR` |
| It is **never parsed from `--note`** | docket does not read a disposition out of prose. Refusing to infer one was always right; what it argued for was a structured field, not no field |
| It accompanies **approve** only | reject records no artifact for the cluster, so there is no value to set — `--value` with `reject` is a `VALIDATION_ERROR` |
| It applies to **materialized** `<step>-held` steps only | a declared human gate has no payload of its own to correct, so the flag would reach nothing there; that too is a `VALIDATION_ERROR` naming the step |
| The routing step must declare an aggregated field and a `payload` schema | otherwise there is no field to set and no enum to check against |

The value rides in the `step-approved` event beside the note, so the feed's
account of the decision carries the decision's content.

The routing step waits until **every** cluster has an answer, then routes once:
per its effective `on_fail` if **any** cluster was rejected, otherwise through
the threshold over the resolved payload. Reject is the escalating answer, so a
mixed set does not silently pass — but each cluster keeps its own status,
routing, and note, so the record stays per-cluster even though what routes is
one decision.

Approval means *accept the cluster* — at the computed value, or at the one
`--value` names. The originally-held artifact stays addressable forever: what
docket computed and what you accepted are two records, not one overwritten one.

A step parked because its clusters were **rejected** cannot be retried:
`docket step resolve --as retry` refuses there rather than silently re-parking
it. The rejection is sticky — re-running the aggregate re-reads the same
rejected decision and routes to the same place, so the attempt counter was never
what blocked it. What moves such a step is `override-pass`, `skip`, or
`abandon-issue`, and the rejected verdict stays addressable through all three.

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

**`min_siblings` does not cancel early.** Reaching the quorum does not release
the join: docket waits for every sibling to finish and *then* compares. A
4-way fanout with `min_siblings = 2` and two siblings already `done` still waits
for the other two. This is deliberate for v1 — cancelling work that is already
running, to save time on a quorum that is already met, is a decision docket
declines to make on your behalf.

### Loops

A `threshold` (or an `on_fail`) that routes `fix-loop` enters a loop. There is
**no other loop construct** — a threshold routing to a *step name* interposes
that step as a one-off gate and is not a loop.

What happens on loop entry, in one transaction:

1. **The issue's loop counter increments.** The counter is per-issue, not
   per-step. If the new count would exceed `max_fix_loops`, the routing becomes
   `waiting-human` instead and no loop is entered — loops are bounded by
   construction, and the parked step's routing records why.
2. **Unclaimed work downstream of `after_loop` is superseded.** Instances at a
   lower ordinal that are still `pending` become `superseded` — a terminal
   status, not a deletion. Already-claimed and running instances are **left
   alone to finish**; their eventual routing is recorded for the ledger but
   applies no downstream effect, so a slow step from the previous ordinal cannot
   re-route an issue that has already moved on.
3. **`loop = true` steps instantiate at the new ordinal**, along with the
   `after_loop` step and everything transitively after it. Gates re-run and
   thresholds re-apply on the new instances — they are fresh, with no gate trail
   and no routing carried over.

Steps **upstream** of `after_loop` do not re-run. That is why `inputs` bind
**per input**: a step at ordinal 1 resolves each declared input at ordinal 1 if
something produced it there, and otherwise falls back to the highest earlier
ordinal that did. The fixture's `fix` step binds `reconcile.findings` fresh at
ordinal 1 and `implement.change-summary` from ordinal 0, in the same step.

**Issue completion is evaluated over highest-ordinal instances only.** A `done`
step at ordinal 0 whose ordinal-1 instance is still pending does not count as
finished, and superseded ordinal-0 instances do not block completion. Prior
instances and their artifacts stay immutable and addressable for the ledger.

---

## Workflow: Payload schemas (`docket schema`)

A step can declare `payload = "name@version"`. That names a **payload schema**:
a JSON Schema document you register, against which the step's `--payload-file`
is checked, and — this is the part that matters — the place where **order comes
from**.

Docket's threshold predicates include ordered comparisons: `any(risk >= medium)`.
Docket does not know that `medium` outranks `low`. It knows it because your
schema said so.

```bash
docket schema register risk-report@1 .docket/config/schemas/risk-report.json
docket schema list
docket schema show risk-report@1 --body
```

### The `ordered_enum` annotation

An ordinary JSON Schema, plus one key:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "array",
  "items": {
    "type": "object",
    "properties": {
      "risk": {
        "type": "string",
        "enum": ["info", "low", "medium", "high", "blocker"],
        "ordered_enum": true
      }
    },
    "required": ["risk"]
  }
}
```

| Rule | |
|---|---|
| The order **is** the `enum` array, as written, ascending | there is no second list to disagree with it, and adding a value to `enum` cannot leave the order stale |
| `ordered_enum` must sit beside an `enum` of **at least two unique strings** | otherwise it is a `VALIDATION_ERROR` naming the property path |
| It constrains **nothing** | a document that validated before the annotation validates after it; the annotation declares position, not a new rule |
| Only **top-level properties of the array's item schema** are indexed | that is exactly what a threshold predicate's bare field token can name |

Docket learns *position*, never *significance*. It does not know which end of
your order is worse, more urgent, or better — and it never has to. A median over
a declared order is the same computation for risk levels, priorities, tiers,
T-shirt sizes, or ripeness grades.

A payload is an array of objects. A schema over it is therefore usually
`{"type": "array", "items": {"type": "object", …}}` — and a document that is not
that shape still registers, it simply declares nothing a threshold can name.

### The `conservative_end` annotation

Docket learns position, never significance — but *an order can know its own bad
end even when docket cannot*. One optional key says which one it is:

```json
"risk": {
  "type": "string",
  "enum": ["info", "low", "medium", "high", "blocker"],
  "ordered_enum": true,
  "conservative_end": "upper"
}
```

| Rule | |
|---|---|
| The value is `"upper"` or `"lower"` — **positions in the ascending `enum`**, never the values it holds | `"high"` is a `VALIDATION_ERROR`: it is a member of *this* enum and could not name an end of any other |
| It must sit beside `"ordered_enum": true` | a direction names an end of an order; declared over an unordered field it is a `VALIDATION_ERROR` naming the property path, not a silently-ignored key |
| It is **optional**, and absent means `"lower"` | every schema written before this key existed computes exactly what it did before |
| It changes exactly one decision: the **even-count median tie** | it does not reach `min`, `max`, an odd-count median, a threshold predicate, `spread`, or a hold |

Declare it on a severity, a priority, or any order where a tie should fall on
the cautious side; leave it off for a confidence, a ripeness, or a tier, where
the two central values are simply two values and neither end is "bad". A
direction is not part of the order, so adding one to a schema does not change
what any threshold predicate compares — only which of two tied medians is taken.

### Registration is content-addressed and immutable

Exactly as workflows are:

| Second registration of… | Result |
|---|---|
| the same bytes | success, returns the existing row, changes nothing |
| **different** bytes at the same `name@version` | `CONFLICT` (exit 4), naming both hashes |
| any bytes at a new `version` | an ordinary registration |

To change a schema, register a new version. This is not ceremony: a schema
decides whether a worker's payload is *accepted*, so a mutable `risk-report@1`
would change a running job's acceptance criteria mid-flight. A workflow that
wants the new schema declares it and bumps its own `[pipeline].version`.

Registering `risk-report@2` does nothing to a workflow that declares
`payload = "risk-report@1"`. Version references are exact.

### Register schemas before the workflows that name them

A workflow declaring `payload = "risk-report@1"` is **checked against the
registered schema when you register the workflow**, not later:

| Check | What it refuses |
|---|---|
| the schema is registered | `payload` naming something absent — with the `docket schema register` line to run |
| the field exists | `any(rsk >= medium)` when the schema declares `risk`, listing what it does declare |
| the literal is valid | `any(risk == severe)` when the enum is `low, medium, high` |
| ordered means ordered | `any(stage >= final)` when `stage` declares an `enum` but no `ordered_enum` |

So register schemas first. A workflow that could never route correctly should
not register at all — the alternative is discovering a typo hours into a run, on
a step whose work is already done.

**Auto-registration already does this for you.** Activation registers everything
under `.docket/config/schemas/` before anything under `.docket/config/workflows/`,
so a workflow and the schema it names can live side by side in the same tree and
the ordering is never yours to arrange. The rule above matters when you register
by hand, and as the reason the auto-registration order is what it is.

**A threshold on a step with no `payload` is untouched by all of this.** It is
grammar-checked and nothing more, and at runtime an ordered comparison over a
field with no declared order parks the step for a human rather than guessing.
`any(status == unmet)` never needed a schema to be correct, and still does not:
equality has never needed an order.

**Changing a schema does not change an already-registered workflow.**
`payload = "risk-report@1"` names a version. Registering `risk-report@2` creates
a new row and touches nothing; a workflow that wants it declares it and bumps its
own `[pipeline].version`. That is worth knowing because "the schema was updated"
is the first thing anyone assumes when a threshold behaves as it did yesterday.

### The one shipped schema

`docket schema list` reports one row in a fresh repo:

```
aggregate@1                  1e0a0be39394  builtin
```

`aggregate@1` ships with docket and describes the output of the builtin
`aggregate` action step. It is inert unless such a step runs, and nothing else
in the registry arrives without someone registering it.

### Validation at `complete`

A step that declares `payload = "name@version"` has its `--payload-file`
validated when it completes:

```
Error: step assess@0: payload does not satisfy risk-report@1:
  payload[3].risk: value "urgent" is not one of ["info","low","medium","high","blocker"]
  (+2 more)
```

Three things about that refusal are deliberate:

- **It is path-precise.** `payload[3].risk` is the element and the property, in
  the notation the file itself is written in. "The payload is invalid" would be
  something a worker can only re-submit against blindly.
- **It is capped at five lines.** A worker's log is not improved by a hundred,
  and the count of what was dropped is reported so you know the list is partial.
- **It validates against the bytes the RUN PINNED**, not against whatever the
  registry holds now. Two runs of the same work at the same pins reach the same
  verdict on the same payload.

Authorization is checked first, always: a caller that does not hold the step's
token gets `AUTH_ERROR` and learns nothing about the schema.

### `docket schema` refusals

| Situation | Code | Exit |
|---|---|---|
| Schema file not found or unreadable | `NOT_FOUND` | 2 |
| Reference is not `name@version` with a version ≥ 1 | `VALIDATION_ERROR` | 3 |
| Malformed JSON, or a document that does not compile as JSON Schema | `VALIDATION_ERROR` | 3 |
| `ordered_enum` without a usable sibling `enum` | `VALIDATION_ERROR` | 3, naming the property path |
| Re-registering different bytes at an existing `name@version` | `CONFLICT` | 4 |
| `schema show` on an unregistered name or version | `NOT_FOUND` | 2 |
| `--payload-file` fails the step's declared schema at `complete` | `VALIDATION_ERROR` | 3 |
| `--payload-file` omitted on a step that declares `payload` | `VALIDATION_ERROR` | 3 |

---

## Workflow: Voting (`docket vote`, consensus proposals)

**A workflow step can open one of these.** A `type="vote"` step creates a
proposal when it becomes ready, fans out to the voters it names, and routes on
the outcome — `approved` passes the step, `rejected` routes per its `on_fail`,
which such a step must declare explicitly (V13a). `waiting-human` is legal there
and means *escalate to an operator*, unlike on a human gate where it is refused.
The proposal's id rides on the step row as `proposal`, and the roster as
`voters`, so a caller holding a `next` row can cast without reading the pinned
definition. Nothing about the machinery below changes: voters cast with the same
`docket vote cast` shown here, the tally is the same weighted score and quorum,
and there is **no new verb**. The step names a `vote_rule`, which is a pair of
`vote.rule.<name>.*` config keys, and `required_voters` is the length of its own
`voters` list. Nothing casts a vote automatically — a voter is a person or a
process running the CLI.

Create a proposal:

```bash
docket vote create --json \
  -d "Adopt Result<T,E> for all internal/db error returns" \
  -r "Panics currently propagate uncaught in 3 call sites" \
  -c high -n 3 --threshold 0.67 \
  --domain-tags "database,error-handling" \
  --files-changed "internal/db/issue.go,internal/db/doc.go"
```

Cast a vote:

```bash
docket vote cast DKT-V1 --json \
  -v approve --confidence 0.9 --domain-relevance 0.8 \
  --findings "Reviewed all call sites, no blockers" \
  --summary "LGTM" \
  --metadata '{"model_resolved":"claude-sonnet-5","effort_resolved":"high"}'
```

`--metadata` is optional and opaque: a seat records what produced its vote
there, and the value is stored whole and read by nobody. Pass it whenever the
vote was cast by something whose spend an operator may later want to attribute.
Treat the value as public — it is visible to anyone who can list processes, it
is stored verbatim in the store, and `docket export` re-emits it verbatim with
no redaction. It reads back through `vote show --json`, `vote result --json`,
and the export document; the human-readable tables do not render it.

Valid `--verdict`/`-v` values: `approve`, `approve-with-concerns`, `reject`.
Valid `--criticality`/`-c` values: `low`, `medium`, `high`, `critical`.
`--confidence` and `--domain-relevance` are floats in `[0.0, 1.0]`.

Inspect and finalize:

```bash
docket vote show DKT-V1 --json
docket vote result DKT-V1 --json
docket vote list --json --all               # default: open proposals only
docket vote commit DKT-V1 --json --outcome "Approved: adopting Result<T,E>"
docket vote close DKT-V1 --json --reason "decided out-of-band; operator ran the verb directly"
docket vote backfill-usage DKT-V1 --json --voter tribunal-security --unit output_tokens --quantity 48211
docket vote link DKT-V1 --json --issue DKT-1
docket vote unlink DKT-V1 --json --issue DKT-1
```

---

## Workflow: Docs (`docket doc`)

```bash
docket doc create --json -t "ADR-0003: SQLite over Postgres" -T adr -s accepted \
  -d "@docs/adr/0003-sqlite.md"          # "@path" loads body from a file
docket doc create --json -t "Quick note" -d "-"   # "-" reads body from stdin
docket doc show DOC-1 --json
docket doc show DOC-1 --json --rev 2               # a specific revision
docket doc list --json -T adr -s accepted
docket doc edit DOC-1 --json -s superseded
docket doc delete DOC-1 --json --force
docket doc link add DOC-1 --json --issue DKT-1
docket doc link remove DOC-1 --json --issue DKT-1
docket doc comment add DOC-1 --json -m "Needs a follow-up on migration path"
docket doc comment list DOC-1 --json
```

`--description`/`-d` on `doc create`/`doc edit` supports the same three
input modes as `issue create -d`: literal string, `@path/to/file` (loads
file contents, 1 MiB cap), or `-` (stdin, 1 MiB cap).

---

## Workflow: Watch Mode

Any watch-eligible command (see table above) can be re-run on an interval
instead of polling manually:

```bash
docket issue list --json --watch --interval 5s
docket board --watch                       # human-mode live board, default 2s interval
docket vote result DKT-V1 --watch --interval 1s
```

`--watch` is rejected with `VALIDATION_ERROR` on any write command (e.g.
`docket issue create --watch` fails immediately). Watch mode runs until
`Ctrl-C` (SIGINT) or SIGTERM.

---

## Workflow: Export / Import

```bash
docket export --json -o json -f backup.json
docket export -o csv -f issues.csv -s todo -s in-progress
docket export -o markdown > issues.md

docket import backup.json --json --merge          # skip duplicates by ID
docket import backup.json --json --replace --yes  # destructive: wipes DB first; --yes is required
                                                    # in every output mode, --json never substitutes (DKT-15)
docket import backup.json --json                  # default: requires an EMPTY database, else CONFLICT
```

`export` streams to stdout when `-f`/`--file` is omitted. `import` requires
`--merge` XOR `--replace`, or an empty database — passing both is a
`VALIDATION_ERROR`, and importing into a non-empty DB without either flag
is a `CONFLICT`.

---

## Complete Command & Flag Reference

Moved to `reference.md` beside this file — 2,371 lines of exhaustive per-flag
detail that does not need to be resident for ordinary work.

**Reach for it only when you need semantics `--help` does not carry** — exact
validation rules, required-flag enforcement, exit-code contracts, or a flag's
interaction with another. For "what flags does this verb take", run
`docket <verb> --help`; it is authoritative, current with the installed
binary, and costs one command instead of a resident reference.

---

## Enum Reference

Transcribed from `internal/model/issue.go`, `relation.go`, `proposal.go`
(validated by `model.Validate*` helpers called from the corresponding
`RunE`):

| Enum | Values |
|---|---|
| Issue status | `backlog`, `todo`, `in-progress`, `review`, `done` |
| Issue priority | `none`, `low`, `medium`, `high`, `critical` |
| Issue type/kind | `task`, `bug`, `feature`, `epic`, `chore` |
| Relation type | `blocks`, `depends_on`, `relates_to`, `duplicates` |
| Proposal criticality | `low`, `medium`, `high`, `critical` |
| Proposal status | `open`, `approved`, `rejected`, `committed`, `closed` |
| Vote verdict | `approve`, `approve-with-concerns`, `reject` |

`docket doc`'s `--type`/`-T` and `--status`/`-s` are **free-form strings**
with no enum validation in the CLI layer — pick a project convention (e.g.
`tdd`, `adr`, `ux`) and use it consistently.

## ID Formats

| Entity | Prefix | Example | Parse accepts |
|---|---|---|---|
| Issue | `DKT-` (per-project display; see below) | `DKT-42` | `DKT-42`, `dkt-42`, bare `42`, or **any project's prefix** (`AMS-42`) |
| Document | `DOC-` | `DOC-7` | `DOC-7`, `doc-7`, or bare `7` |
| Proposal (vote) | `DKT-V` (no separator before digits) | `DKT-V3` | `DKT-V3`, `dkt-v3`, or bare `3` |
| Run | `RUN-` | `RUN-3` | `RUN-3`, `run-3`, or bare `3` |
| Step | `STEP-` | `STEP-12` | `STEP-12`, `step-12`, or bare `12` |

The issue prefix is per-project (`docket project set-prefix`) and display
only: in a project whose prefix is `VOR`, issues render `VOR-42`, but the
number is the store-wide identity — `DKT-42`, `VOR-42`, and bare `42` all
parse to the same issue, **from any project** (DKT-72). That last part is what
makes `issue list --project` usable: the listing prints another project's ids,
and the next command has to be able to take one back. `DOC`, `RUN`, and `STEP`
are reserved, never project-configurable, and never parse as issue ids — an
`issue show RUN-3` that resolved to issue 3 is exactly the ambiguity the
reservation exists to prevent.

A step also carries a rendered **instance identity** — `name@k#i`, where `k` is
the loop ordinal and `#i` the fanout sibling index (`implement@0`,
`review@0#2`). That is the step's public name in wire shapes, events, and error
strings; `STEP-N` is its database id. Both appear on every step row.
