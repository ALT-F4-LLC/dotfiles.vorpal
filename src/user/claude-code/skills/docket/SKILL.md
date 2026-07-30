---
name: docket
description: >
  Comprehensive reference for using the Docket CLI (`docket`), a local-first,
  SQLite-backed issue tracker. Use this skill whenever the user asks to
  create, edit, list, move, close, or reopen issues; attach files, add
  comments, apply labels, or link relations between issues; generate an
  execution plan or find work-ready issues; create or cast a consensus vote
  ("run a vote", "start a proposal"); author, edit, or link a document; watch
  live-updating output; export or import a Docket database; or any request
  to "use docket", "track this in docket", "create a docket issue", "check
  docket status", "run docket plan/next", "show the docket board", etc.
---

# Docket CLI Skill

Docket (`docket`) is a local-first, SQLite-backed issue tracker driven entirely through one
CLI binary — no server, no network; all state lives in a `.docket/issues.db` file resolved
from the cwd. **Always pass `--json`** for reliable parsing. Worked examples for every
workflow (issues, files, comments, labels/relations, graph, plan/next, vote, docs, watch,
export/import) live in `references/workflows.md` — read it when composing a multi-step
invocation; the contracts every call depends on are below.

```bash
docket init                                   # create .docket/issues.db in the cwd
docket issue create -t "Fix login bug" --json # create an issue, get its ID back
docket issue list --json                      # list open issues
docket issue show DKT-1 --json                # full detail incl. comments/activity
docket next --json                            # what's ready to work on right now?
```

At session start prefer `docket_bootstrap.sh` (see Wrapper Scripts) over hand-typing
`docket init && docket version --quiet`.

**The flag reference below is complete and current** — look flags up here rather than
re-running `--help`, unless a governing gate (e.g. the evolve-* Phase-0 ground-truth check)
names `--help` as its verification source. `docket_ref_check.sh` mechanizes the drift check
against the installed binary and is the recommended Phase-0 ground-truth step when auditing
this skill.

## Global Flags & Output Contract

Inherited by every subcommand:

| Flag | Shorthand | Type | Default | Behavior |
|---|---|---|---|---|
| `--json` | — | bool | `false` | Machine-readable JSON envelope on stdout. |
| `--quiet` | `-q` | bool | `false` | Suppress human-mode info/warning lines on stderr. |
| `--watch` | `-w` | bool | `false` | Re-run on an interval. Read-only commands only (`board`, `issue list/show/log/graph`, `issue comment list`, `doc list/show`, `doc comment list`, `next`, `plan`, `stats`, `config`, `vote list/show/result`); write commands reject it with `VALIDATION_ERROR`. |
| `--interval` | — | duration | `2s` | Watch refresh interval; minimum `500ms`. |

### JSON envelope shape

Single-line JSON object on stdout. Success:
`{"ok": true, "data": { ... }, "message": "Created DKT-1: Fix login bug"}` (`message` is
`omitempty` — don't depend on it). Error:
`{"ok": false, "error": "issue DKT-99 not found", "code": "NOT_FOUND"}`.

### Error codes & exit codes

The process exit code always matches, in both JSON and human mode:

| `code` | Exit code | Meaning |
|---|---|---|
| `GENERAL_ERROR` | 1 | Unclassified failure (DB error, I/O error, etc.) |
| `NOT_FOUND` | 2 | Referenced issue/doc/proposal/label/relation does not exist (also: no `.docket/` DB yet — run `docket init`) |
| `VALIDATION_ERROR` | 3 | Bad input: invalid enum, missing required flag, mutually exclusive flags, non-interactive environment without required flags |
| `CONFLICT` | 4 | State conflict: duplicate relation, cycle, already-voted, non-empty DB on import without `--merge`/`--replace` |

### `.data` shapes are NOT uniform — check before parsing

Sub-entity `list` subcommands return `.data` as a **bare array**; every other list command
returns an **object** with a named collection key plus `total`. Confusing the two is the
most common Docket parsing failure.

| Command | `.data` | jq for the rows |
|---|---|---|
| `issue list`, `next` | object | `.data.issues[]` |
| `doc list` | object | `.data.docs[]` |
| `vote list` | object | `.data.proposals[]` |
| `issue log` | object | `.data.entries[]` |
| `plan` | object | `.data.phases[]` |
| `issue graph` | object | `.data.nodes[]` / `.data.edges[]` |
| `issue show` | object (the issue itself) | `.data.status`, `.data.comments[]` |
| `issue comment list`, `doc comment list` | **bare array** | `.data[]` |
| `issue file list`, `label list`, `link list` | **bare array** | `.data[]` |

**Truncation is silent.** `issue list`/`doc list`/`vote list` default to `--limit 50`
(`next` to 10) with no warning when rows are cut; `total` counts the FULL match set:

```bash
docket issue list --json | jq -e '.data.total > (.data.issues|length)' >/dev/null \
  && echo "TRUNCATED — re-run with a higher --limit"
```

### Non-interactive contexts

Write commands with missing required flags fall back to an interactive form or `$EDITOR`
only when stdin is a TTY; with no TTY they return `VALIDATION_ERROR` listing the missing
flags, and `--json` mode never launches a form. Always pass all required flags explicitly.

### The comment contract

The message is **always** `-m`/`--message` — never a bare positional arg, never
`-b`/`--body` — and the verb is `add`, never `create`; the same contract covers
`doc comment add`. **Always pass `--json` on `comment add`:** in human mode an empty
message (`-m ""`, or `-m "$VAR"` with `VAR` unset) takes the editor path, prints
`Cancelled.`, exits 0, and writes NOTHING — a silent drop; under `--json` the same input is
a hard `VALIDATION_ERROR` (exit 3). Corollary: never split a stage-file write from its
consumption (`-m "$(cat "$STAGE")"`) across two Bash tool calls — shell variables do not
persist between calls, so the comment lands empty.

Two more forms that fail: `issue edit -l` (no label flag on `edit` — use
`issue label add`), and `issue move ... -m "note"` (no message flag on `move` — comment
separately).

### ID formats

| Entity | Prefix | Example | Parse accepts |
|---|---|---|---|
| Issue | `DKT-` | `DKT-42` | `DKT-42`, `dkt-42`, or bare `42` |
| Document | `DOC-` | `DOC-7` | `DOC-7`, `doc-7`, or bare `7` |
| Proposal (vote) | `DKT-V` | `DKT-V3` | `DKT-V3`, `dkt-v3`, or bare `3` |

## Deterministic Wrapper Scripts

Nine helpers under `src/user/claude-code/scripts/` chain multi-command rituals behind a
cwd-guard and post-write verification — prefer them over hand-composing raw sequences:

| Script | Args | Encodes |
|---|---|---|
| `docket_bootstrap.sh` | (none) | `init` then `version --quiet` — the session-start invocation |
| `docket_claim.sh` | `<id> <role>` | `edit -a @<role>` then `move in-progress`; rejects if still `backlog`; verifies against `status`/`assignee` (not `updated_at`, whose second-granularity made same-second claims false-negative) |
| `docket_close.sh` | `<id> <msg>` | `close` → verify `status==done` → `comment "Completed: <msg>"` |
| `docket_promote.sh` | `<id>` | promote `backlog` → `todo` if still `backlog`, else no-op — the team-lead-only pre-dispatch move |
| `docket_write.sh` | `<id> <issue subcommand...>` | any `docket issue` write + activity-log-advanced re-verify |
| `docket_create.sh` | `<issue create flags...>` | `issue create` + re-verify every `-l`/`-f` landed, backfilling omissions |
| `vote_delegate.sh` | `<role> <criticality> <desc> <voters> [artifact]` | `vote create -n <voters>` (integer voter count, not names) with criticality-correct `--threshold` + prints the delegation payload |
| `vote_record.sh` | `<vote-id> <voter> <role> <report-file>` | parses a reviewer report's Verdict/Confidence/Domain-Relevance/Findings sections and casts via `vote cast`, streaming findings through stdin |
| `docket_ref_check.sh` | `[skill-md-path]` | diffs this file's flag tables against installed `docket <cmd> --help`; exits nonzero on drift |

---

## Complete Command & Flag Reference

Every flag below is transcribed from the `cmd.Flags().*` calls in the corresponding
`internal/cli/*.go` file. "Req." marks Cobra `MarkFlagRequired` flags — distinct from flags
required only *in JSON mode* by checks inside `RunE` (noted in Notes).

### `docket issue` (alias `i`) — `internal/cli/issue.go`

#### `docket issue create` — `issue_create.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--title` | `-t` | string | `""` | Required in `--json` mode |
| `--description` | `-d` | string | `""` | `"-"` reads from stdin |
| `--status` | `-s` | string | `"backlog"` | `backlog`\|`todo`\|`in-progress`\|`review`\|`done` |
| `--priority` | `-p` | string | `"none"` | |
| `--type` | `-T` | string | `"task"` | `task`\|`bug`\|`feature`\|`epic`\|`chore` |
| `--label` | `-l` | stringSlice | `nil` | repeatable |
| `--file` | `-f` | stringSlice | `nil` | repeatable |
| `--assignee` | `-a` | string | `""` | |
| `--parent` | — | string | `""` | parent issue ID |

#### `docket issue edit [id]` — `issue_edit.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--title` | `-t` | string | `""` | only applied when explicitly set |
| `--description` | `-d` | string | `""` | `"-"` reads from stdin |
| `--status` | `-s` | string | `""` | `backlog`\|`todo`\|`in-progress`\|`review`\|`done` |
| `--priority` | `-p` | string | `""` | |
| `--type` | `-T` | string | `""` | `task`\|`bug`\|`feature`\|`epic`\|`chore` |
| `--assignee` | `-a` | string | `""` | |
| `--file` | `-f` | stringSlice | `nil` | repeatable; **replaces** existing file list |
| `--parent` | — | string | `""` | `"0"` or `"none"` clears parent |

#### `docket issue show [id]` — `issue_show.go`

No local flags. Watch-eligible.

#### `docket issue list` (alias `ls`) — `issue_list.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--status` | `-s` | stringSlice | `nil` | repeatable; `backlog`\|`todo`\|`in-progress`\|`review`\|`done` |
| `--priority` | `-p` | stringSlice | `nil` | repeatable |
| `--label` | `-l` | stringSlice | `nil` | repeatable |
| `--type` | `-T` | stringSlice | `nil` | repeatable; `task`\|`bug`\|`feature`\|`epic`\|`chore` |
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
| `--status` | `-s` | stringSlice | `nil` | repeatable |
| `--label` | `-l` | stringSlice | `nil` | repeatable |
| `--assignee` | `-a` | string | `""` | filter by assignee |
| `--priority` | `-p` | stringSlice | `nil` | repeatable |
| `--type` | `-T` | stringSlice | `nil` | repeatable |

Watch-eligible. Cycle in the dependency graph → `CONFLICT`.

### `docket next` — `next.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--status` | `-s` | stringSlice | `nil` | default ready-set is `backlog`,`todo` if unset |
| `--priority` | `-p` | stringSlice | `nil` | repeatable |
| `--label` | `-l` | stringSlice | `nil` | repeatable |
| `--type` | `-T` | stringSlice | `nil` | repeatable |
| `--limit` | — | int | `10` | |

Watch-eligible.

### `docket vote` (alias `v`) — `vote.go`

#### `docket vote create` — `vote_create.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--description` | `-d` | string | `""` | required in `--json`; `"-"` reads stdin |
| `--rationale` | `-r` | string | `""` | `"-"` reads stdin |
| `--criticality` | `-c` | string | `"medium"` | `low`\|`medium`\|`high`\|`critical` |
| `--voters` | `-n` | int | `0` | required in `--json` mode (omission fails `VALIDATION_ERROR: --voters is required`); must be `>= 1` |
| `--threshold` | — | float64 | `0.67` | must be in `(0.0, 1.0]` |
| `--created-by` | — | string | `""` | defaults to `git user.name` if empty |
| `--domain-tags` | — | string | `""` | comma-separated |
| `--files-changed` | — | string | `""` | comma-separated |
| `--escalation-reason` | — | string | `""` | |

#### `docket vote cast <id>` — `vote_cast.go`

| Flag | Short | Type | Default | Notes |
|---|---|---|---|---|
| `--voter` | — | string | `""` | defaults to `git user.name` |
| `--role` | — | string | `""` | |
| `--verdict` | `-v` | string | `""` | required in `--json`; `approve`\|`approve-with-concerns`\|`reject` |
| `--confidence` | — | float64 | `0` | required in `--json` mode (omission fails `VALIDATION_ERROR: --confidence is required in JSON mode`); range `[0.0, 1.0]` |
| `--domain-relevance` | — | float64 | `0` | required in `--json` mode (same unconditional check); range `[0.0, 1.0]` |
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
| `--merge` | — | bool | `false` | skip duplicates by ID; mutually exclusive with `--replace` |
| `--replace` | — | bool | `false` | destructive: clears DB first; mutually exclusive with `--merge` |

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

No local flags. `Annotations: {"skipDB": "true"}` — runs before any DB check/open.

### `docket version` — `version.go`

No local flags. `skipDB` annotated.

### `docket config` — `config.go`

No local flags. `skipDB` annotated (reads config even if no DB exists yet). Watch-eligible.

---

## Enum Reference

| Enum | Values |
|---|---|
| Issue status | `backlog`, `todo`, `in-progress`, `review`, `done` |
| Issue priority | `none`, `low`, `medium`, `high`, `critical` |
| Issue type/kind | `task`, `bug`, `feature`, `epic`, `chore` (no `docs`/`spike` kind — use `task` or `chore` for documentation-only work) |
| Relation type | `blocks`, `depends_on`, `relates_to`, `duplicates` |
| Proposal criticality | `low`, `medium`, `high`, `critical` |
| Proposal status | `open`, `approved`, `rejected`, `committed` |
| Vote verdict | `approve`, `approve-with-concerns`, `reject` |

`docket doc`'s `--type`/`-T` and `--status`/`-s` are **free-form strings** with no enum
validation — pick a project convention (e.g. `tdd`, `adr`, `ux`) and use it consistently.
