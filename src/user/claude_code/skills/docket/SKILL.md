---
name: docket
description: >
  Reference for the issue-tracker surface of the Docket CLI (`docket`), a
  local-first, SQLite-backed tracker. Covers issues, docs, votes and
  export/import — NOT the engine groups (run, step, dispatch, workflow,
  schema, trust, guard, events, project). Use this skill whenever the user
  asks to create, edit, list, move, close, or reopen issues; attach files, add
  comments, apply labels, or link relations between issues; generate an
  execution plan or find work-ready issues; create or cast a consensus vote
  ("run a vote", "start a proposal"); author, edit, or link a document; watch
  live-updating output; export or import a Docket database; or any request
  to "use docket", "track this in docket", "create a docket issue", "check
  docket status", "run docket plan/next", "show the docket board", etc.
---

# Docket CLI Skill

Docket (`docket`) is a local-first, SQLite-backed issue tracker driven
entirely through a single CLI binary. There is no server and no network
call — all state lives in an `issues.db` SQLite file, resolved in order:
`$DOCKET_PATH` → a repo-local `.docket/issues.db` found by walking up to the
worktree toplevel → the shared per-user store at `~/.docket` (the default,
and the only arrangement the union model expects).

**One store, many projects — and scoping is split.** Under the shared store
each repo is a separate PROJECT, identified by the checkout's git dir, and
the engine's definition corpus is the union of the config roots listed in
`~/.docket/config` (the user-global root plus any repo roots it names);
nothing is materialized in the repo. The split that trips agents up:

- **Id lookups resolve store-wide.** `docket issue show DKT-1` returns an
  issue owned by a different project from inside this checkout.
- **Collections filter to the current project.** `issue list`, `stats`,
  `board`, `plan`, and `next` return only this project's rows. So
  `docket issue list --json --all` answering `{"issues":[],"total":0}` and
  `docket stats --json` answering all zeros is the correct result for a
  project with no issues — NOT an empty store and NOT a create that failed.

Run `docket config --json` when a result surprises you: it reports which
store and project the current directory binds to.

This skill teaches an agent how to drive the tracker surface of `docket` end
to end: issue CRUD and lifecycle, file attachments, comments, labels,
relations, dependency graphs, execution planning, consensus voting, docs,
watch mode, and export/import.

**Not covered here.** The engine half of the binary is a separate surface
with its own groups — `run`, `step`, `dispatch`, `workflow`, `schema`,
`trust`, `guard`, `events`, `project`. Their absence below is not evidence
they do not exist: `docket step record`, `docket next --run`, and `docket
dispatch` are all real verbs. Read `docket <group> --help` for them, or use
the `plan` and `conduct` skills, which drive that surface.

Every command supports **two output modes**: human-readable (default,
colorized via lipgloss when the terminal supports it) and machine-readable
JSON (`--json`). **Agents should always pass `--json`** for reliable
parsing — the examples below show both.

## Quick Start

```bash
docket config --json                          # FIRST: which store and project am I bound to?
docket issue create -t "Fix login bug" --json # create an issue, get its ID back
docket issue list --json                      # list THIS project's open issues
docket issue show DKT-1 --json                # show full detail incl. comments/activity
docket next --json                            # what's ready to work on right now?
```

`docket init` is rarely needed — the shared `~/.docket` store is created on
first use. **Never run `docket init --local`.** It materializes a repo-local
`.docket/issues.db` that shadows the shared store for every command run
inside the checkout and cuts the repo off from the union config corpus.

Issue IDs are formatted `<PREFIX>-<n>` (e.g. `DKT-42`), document IDs
`DOC-<n>`, and proposal (vote) IDs `<PREFIX>-V<n>`. **The issue prefix is
per-project, not a constant** — `DKT-` is one project's value, set with
`docket project set-prefix` and readable from `docket config --json`; every
`DKT-` in this skill is illustrative. Numbering is a single store-wide
sequence, so one project's ids are not contiguous. All three forms accept
either the bare number or the formatted string as CLI arguments
(`model.ParseID`, `ParseDocID`, `ParseProposalID` all strip the prefix
case-insensitively).

## Global Flags & Output Contract

Defined once on `rootCmd` in `internal/cli/root.go` and inherited by every
subcommand:

| Flag | Shorthand | Type | Default | Behavior |
|---|---|---|---|---|
| `--json` | — | string | off | Machine-readable JSON envelope on stdout. Bare `--json` = the frozen v1 shape (what this skill documents); `--json=v2` reshapes collections to `{items, total, truncated}`. |
| `--format` | — | string | `""` | Output format selector. `--format json` is an **alias for `--json=v2`**, not for bare `--json` — collections come back as `{items, total, truncated}` and v1 parsers mis-read them. Use `--json`. |
| `--quiet` | `-q` | bool | `false` | Suppress non-essential human-mode info/warning lines on stderr. No effect in `--json` mode (already silent). |
| `--watch` | `-w` | bool | `false` | Re-run the command on an interval and refresh output. Accepted only on the allowlist below; every other command rejects it with a `VALIDATION_ERROR`, read-only or not. |
| `--interval` | — | duration | `2s` | Refresh interval for `--watch`. Minimum `500ms`; anything lower is a `VALIDATION_ERROR`. |

### `--watch` eligibility

`--watch`/`-w` and `--interval` are global flags: they are listed under
Global Flags in **every** `--help`, including `issue create`, so `--help` is
no guide to eligibility. The engine accepts them only on this allowlist,
defined in `internal/cli/watch_commands.go`:

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
```

The allowlist is the tracker surface only — no engine read verb is on it.
**Anything off the list is rejected whether or not it writes**, and the
error text lies about why: read-only `docket project list --watch --json`
returns the same `{"ok":false,"error":"--watch is not supported on write
commands","code":"VALIDATION_ERROR"}` that `issue create --watch` does.
Ignore the "write commands" wording; the rule is membership in the list.

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

**`ok: false` does not always mean failure.** A few engine verbs use it as a
state answer about the thing they inspected — `docket dispatch verify`
reports an unsatisfied dispatch with `ok:false` on its happy path, and that
verb is outside this skill's scope, so do not carry "ok:false = broken" into
a run. Discriminate on `code` plus the process exit status: a real failure
carries a `code` from the table below and exits non-zero; a state answer
exits `0`.

### Error codes & exit codes

Defined in `internal/output/json.go`. The process exit code always matches
the table below, in both JSON and human mode (`ExitCodeForError`):

| `code` | Exit code | Meaning |
|---|---|---|
| `GENERAL_ERROR` | 1 | Unclassified failure (DB error, I/O error, etc.) |
| `NOT_FOUND` | 2 | Referenced issue/doc/proposal/label/relation does not exist |
| `VALIDATION_ERROR` | 3 | Bad input: invalid enum value, missing required flag, mutually exclusive flags, non-interactive environment without required flags |
| `CONFLICT` | 4 | State conflict: duplicate relation, cycle detected, already-voted, non-empty project on import without `--merge`/`--replace` |

Exit code `0` is success. A missing repo-local store is NOT an error: with no
`.docket/` up-tree, commands fall back to the shared `~/.docket` store
silently (creating it on first use). Codes 5-9 also exist on the current
engine (AUTH_ERROR 5, STALE_LEASE 6, GONE 9); 1-4 are frozen.

### Interactive forms

Several write commands (`issue create`, `issue delete` with sub-issues,
`vote create`, `vote cast`, `doc create`, `doc delete`, `label delete`,
`import --replace`) fall back to an interactive `huh` form when required
flags are omitted and stdin is a TTY. (`issue comment` and `doc comment`
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
  --scope internal/api \
  -l backend -l must-have \
  -f internal/api/router.go \
  -a "@alice"
```

**Always pass `--scope`.** Cobra does not require it, so leaving it off
silently produces a scopeless issue — the field is load-bearing for
downstream planning and scheduling, and nothing in the create response tells
you it is missing. If you are unsure what value belongs, read `docket issue
create --help` and copy the convention already used by
`docket issue list --json`.

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

`docket plan` groups issues into dependency-ordered execution phases
(topological sort; a cycle returns `CONFLICT`). It does **not** cover all
non-done issues: the default status set is `backlog`, `todo`, `in-progress`,
so `review` issues are silently excluded — name them with `-s` to include
them:

```bash
docket plan --json
docket plan --json --root DKT-1                      # scope to a parent issue's subtree
docket plan --json -s backlog -s todo -l must-have    # filter by status/label
docket plan --json -p high -p critical -T bug -a alice # filter by priority/type/assignee
docket plan --json -s backlog -s todo -s in-progress -s review # include review too
```

`docket next` finds work-ready issues — no incomplete blockers, in one of
the ready statuses (default `backlog`,`todo`):

```bash
docket next --json
docket next --json -s todo -p high -p critical -l must-have --limit 5
```

`docket next --run` switches the verb to a different subject entirely: the
ready STEPS of an activated run rather than issues. That is the form the
`conduct` skill lives on, and its rows are what the wave workflow consumes.
Run `docket next --help` for the argument it takes; the step and dispatch
surface around it is out of scope here.

---

## Workflow: Voting (`docket vote`, consensus proposals)

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
  --summary "LGTM"
```

Valid `--verdict`/`-v` values: `approve`, `approve-with-concerns`, `reject`.
Valid `--criticality`/`-c` values: `low`, `medium`, `high`, `critical`.
`--confidence` and `--domain-relevance` are floats in `[0.0, 1.0]`.

Inspect and finalize:

```bash
docket vote show DKT-V1 --json
docket vote result DKT-V1 --json
docket vote list --json --all               # default: open proposals only
docket vote commit DKT-V1 --json --outcome "Approved: adopting Result<T,E>"
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

`--watch` is rejected with `VALIDATION_ERROR` on every command off the
allowlist — write commands like `docket issue create --watch`, but equally
read-only ones like `docket project list --watch`. Watch mode runs until
`Ctrl-C` (SIGINT) or SIGTERM.

---

## Workflow: Export / Import

```bash
docket export --json -o json -f backup.json
docket export -o csv -f issues.csv -s todo -s in-progress
docket export -o markdown > issues.md

docket import backup.json --json --merge      # colliding ids are REMAPPED, nothing is dropped
docket import backup.json --json --replace    # destructive: replaces THIS PROJECT's data
docket import backup.json --json              # default: requires an EMPTY project, else CONFLICT
```

`export` streams to stdout when `-f`/`--file` is omitted. `import` requires
`--merge` XOR `--replace`, or an empty project — passing both is a
`VALIDATION_ERROR`, and importing into a non-empty project without either
flag is a `CONFLICT`.

Two corrections worth holding onto: `--merge` does **not** skip duplicates —
an incoming id that collides is remapped to a fresh one, so every record in
the file lands and ids shift. And `--replace` replaces the current
PROJECT's data, not the whole store — under the shared store other projects
survive it, but this project's issues do not. It destroys data; get the
operator's confirmation before running it.

---

## Command & Flag Reference (tracker subset)

The tables below cover the tracker surface only. They are transcribed from
the `cmd.Flags().*` calls in the corresponding `internal/cli/*.go` file's
`init()` and were checked against `docket --help` on engine
`s7-51-g79fbf69` (schema v12) on 2026-08-10. **A flag's absence here is not
evidence it does not exist** — the engine groups are omitted by design and a
newer engine may have added flags; confirm with `docket <command> --help`
before concluding something is unsupported. "Req." marks flags
enforced via `cmd.Flags().MarkFlagRequired` (Cobra rejects the command
before `RunE` runs if absent) — distinct from flags that are merely
required *in JSON mode* by manual checks inside `RunE` (noted in Notes).

### `docket issue` (alias `i`) — `internal/cli/issue.go`

Beyond the subcommands documented below, `docket issue` carries three lease
verbs the engine uses for work assignment: `claim` (take a lease on an
issue), `heartbeat` (extend a lease you hold before its TTL expires), and
`release` (hand it back). They are part of the engine surface — see
`docket issue <verb> --help`.

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
| `--scope` | — | string | `""` | work scope; **pass it** — omitting it silently creates a scopeless issue |
| `--idempotency-key` | — | string | `""` | dedupe key for safe retries: a repeated create with the same key does not produce a second issue |

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
| `--scope` | — | string | `""` | set/change the work scope; the way to fix an issue created without one |
| `--if-version` | — | — | — | optimistic-concurrency guard: pass the version you read and the edit is refused if the issue changed under you (see `--help` for the accepted form) |

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

Watch-eligible.

#### `docket issue close [id]` — `issue_close.go`

No flags. Shorthand for `move <id> done`.

#### `docket issue move <id> <status>` — `issue_move.go`

No flags. Two positional args, `id` and target status.

#### `docket issue reopen [id]` — `issue_reopen.go`

No flags. Only transitions if currently `done`, sets status to `backlog`.

#### `docket issue delete <id>` — `issue_delete.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--force` | `-f` | bool | `false` | cascade-delete sub-issues; mutually exclusive with `--orphan` |
| `--orphan` | — | bool | `false` | promote sub-issues to root; mutually exclusive with `--force` |

#### `docket issue log [id]` — `issue_log.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--limit` | — | int | `20` | clamped to min 1 |

Watch-eligible.

#### `docket issue comment add [id]` / `docket issue comment list [id]` — `issue_comment.go`, `issue_comment_list.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--message` | `-m` | string | `""` | (`add` only) required in `--json` mode if stdin isn't piped |

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
| `--status` | `-s` | stringSlice | `nil` (engine applies `backlog`,`todo`,`in-progress`) | repeatable; when unset, `review` and `done` are excluded |
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
| `--run` | — | run selector | — | switches the subject from ready ISSUES to the ready STEPS of a run — the engine form `conduct` uses; check `docket next --help` for the exact argument |

Watch-eligible.

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
| `--idempotency-key` | — | string | `""` | dedupe key for safe retries: a repeated create with the same key does not open a second proposal |

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

#### `docket vote commit <id>` — `vote_commit.go`

| Flag | Short | Type | Default |
|---|---|---|---|
| `--outcome` | — | string | `"Committed"` |
| `--escalation-reason` | — | string | `""` |

#### `docket vote link <proposal-id>` / `docket vote unlink <proposal-id>` — `vote_link.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--issue` | — | string | `""` | **Req.** (`MarkFlagRequired`) on both `link` and `unlink` |

#### `docket vote list` (alias `ls`) — `vote_list.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--status` | `-s` | string | `""` | `open`\|`approved`\|`rejected`\|`committed`; defaults to `open` unless `--all` |
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
| `--idempotency-key` | — | string | `""` | dedupe key for safe retries: a repeated create with the same key does not produce a second doc |

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
| `--force` | `-f` | bool | `false` | skip interactive confirmation |

#### `docket doc link add/remove` — `doc_link.go`

| Command | Flag | Short | Type | Default | Notes |
|---|---|---|---|---|---|
| `add <id> --issue <issue_id>` | `--issue` | — | string | `""` | **Req.** |
| `remove <id> --issue <issue_id>` | `--issue` | — | string | `""` | **Req.** |

#### `docket doc comment add [id]` / `docket doc comment list [id]` — `doc_comment.go`, `doc_comment_list.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--message` | `-m` | string | `""` | (`add` only) required in `--json` mode if stdin isn't piped |

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
| `--merge` | — | bool | `false` | merge in; colliding ids are **remapped, nothing is dropped**; mutually exclusive with `--replace` |
| `--replace` | — | bool | `false` | destructive: replaces THIS PROJECT's data (not the whole store); mutually exclusive with `--merge` |

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
| `--local` | — | bool | `false` | create a repo-local `.docket/issues.db` instead of joining the shared store — **do not use** |

`Annotations: {"skipDB": "true"}` — runs before any DB check/open, since its
job is to create the DB. Under the union model you do not pass `--local`: a
repo-local store shadows `~/.docket` for every command run inside the
checkout and severs the repo from the union config corpus. Plain
`docket init`, or no init at all, is what you want.

### `docket version` — `version.go`

No local flags. `skipDB` annotated.

### `docket config` — `config.go`

Bare `docket config` prints the resolved binding — store path, project
identity and prefix, config roots — and is the first command to run when a
result looks wrong. No local flags; `skipDB` annotated (reads config even if
no DB exists yet, to report that fact); watch-eligible.

| Subcommand | Effect | Notes |
|---|---|---|
| `config get <key>` | reads | one resolved engine setting |
| `config set <key> <value>` | **WRITES the DB** | persists an engine default; despite living under `config` it is not read-only |

Keys `config set` accepts include `lease.ttl.default`, `lease.ttl.<class>`,
`attempt.max`, `budget.default`, `context.warn_bytes`, and
`context.error_bytes`. Treat it as a mutation: it changes engine defaults
that later runs inherit, so confirm with the operator before running it.

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
| Proposal status | `open`, `approved`, `rejected`, `committed` |
| Vote verdict | `approve`, `approve-with-concerns`, `reject` |

`docket doc`'s `--type`/`-T` and `--status`/`-s` are **free-form strings**
with no enum validation in the CLI layer — pick a project convention (e.g.
`tdd`, `adr`, `ux`) and use it consistently.

## ID Formats

| Entity | Prefix | Example | Parse accepts |
|---|---|---|---|
| Issue | project prefix | `DKT-42` | `DKT-42`, `dkt-42`, or bare `42` |
| Document | `DOC-` | `DOC-7` | `DOC-7`, `doc-7`, or bare `7` |
| Proposal (vote) | project prefix + `V` (no separator before digits) | `DKT-V3` | `DKT-V3`, `dkt-v3`, or bare `3` |

The issue/proposal prefix belongs to the PROJECT, not to Docket: `DKT-` is a
default, other projects in the same store use their own, and
`docket project set-prefix` changes it. Read the live value from
`docket config --json` rather than assuming `DKT-`. Issue numbering is one
sequence across the whole store, so gaps in a project's ids are normal and
say nothing about missing issues.
