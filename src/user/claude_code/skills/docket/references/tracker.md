# Issues, documents, and store data

Read the relevant recipe for issue or document operations. For project tenancy
and exact flag contracts, use [the CLI reference](../reference.md).

Find the relevant heading before reading a large section:

- Workflow: Issue Creation & Editing
- Workflow: File Attachment (`docket issue file`)
- Workflow: Comments
- Workflow: Labels & Relations
- Workflow: Dependency Graph (`docket issue graph`)
- Workflow: Planning (`docket plan` and `docket next`)
- Workflow: Docs (`docket doc`)
- Workflow: Export / Import
- Enum Reference
- ID Formats

## Workflow: Issue Creation & Editing

Create an issue (only `--title` is required in JSON mode). In this example the
description arrives on stdin with `-d -`, through a QUOTED heredoc
delimiter, so the shell cannot run anything embedded in the text (see
[prose transport](transport.md#free-text-flags-quote-so-the-shell-cannot-run-your-text); a double-quoted `echo "…" |` pipe does
NOT protect it):

```bash
docket issue create --json=v2 \
  -t 'Add rate limiting to API' \
  -s todo -p high -T feature \
  -l backend -l must-have \
  -f internal/api/router.go \
  --scope 'internal/api/**' \
  -a alice \
  -d - <<'DESC'
Prevent abuse on public endpoints — `just build` and $(go test ./...) arrive
intact because the quoted DESC delimiter stops the shell expanding them.
DESC
```

For multiline or pasted text, prefer a supported file input or stdin through
a quoted heredoc. A short, correctly single-quoted literal is also safe.
See [prose transport](transport.md#free-text-flags-quote-so-the-shell-cannot-run-your-text).

Pick a delimiter the body cannot contain. `EOF` is the wrong default for
descriptions quoting shell snippets — a body with a bare `EOF` line of its
own closes the heredoc early and the rest of the text is executed as
commands. `DESC` (or a uniquely-named one) is the habit.

Edit only the fields you pass — `issue edit` uses `cmd.Flags().Changed(...)`
so omitted flags are left untouched, not reset to zero values:

```bash
docket issue edit DKT-1 --json=v2 -s in-progress -a bob
docket issue edit DKT-1 --json=v2 --parent DKT-5      # reparent
docket issue edit DKT-1 --json=v2 --parent none        # make it a root issue again
docket issue edit DKT-1 --json=v2 -f a.go -f b.go       # REPLACES the file list (not additive)
```

Reparenting validates against cycles (`db.IsDescendant`) and rejects
self-parenting with `VALIDATION_ERROR`/`CONFLICT`.

Status transitions and lifecycle commands follow. Delete, cascade, and
project-migration examples require the corresponding requested scope; they
are alternatives, not a sequence to execute:

```bash
docket issue move DKT-1 review --json=v2     # arbitrary status transition
docket issue move DKT-1 --project vorpal --json=v2  # migrate issue + subtree to another project
docket issue close DKT-1 --json=v2           # shorthand for: move <id> done
docket issue reopen DKT-1 --json=v2          # shorthand for: move <id> backlog (only if currently done)
docket issue delete DKT-1 --json=v2 --force  # cascade-delete issue + all sub-issues
docket issue delete DKT-1 --json=v2 --orphan # delete issue, promote sub-issues to root
```

Valid `--status`, `--priority`, and `--type`/`-T` values are listed under
[Enum Reference](#enum-reference).

List and inspect:

```bash
docket issue list --json=v2 -s todo -s in-progress -p high --tree
docket issue show DKT-1 --json=v2     # full detail: sub-issues, relations, comments, activity, docs
docket issue log DKT-1 --json=v2 --limit 50
```

`issue show` accepts multiple IDs: one ID returns an object under `data`,
two or more return an array. `issue list`, `next`, `plan`, and `board` return
summary rows without descriptions by default and carry `description_bytes`.
Use `--with-body` when full descriptions are required, or batch `issue show`
for the selected IDs. Missing description fields are not empty descriptions.

---

## Workflow: File Attachment (`docket issue file`)

```bash
docket issue file add DKT-1 --json=v2 internal/api/router.go internal/api/middleware.go
docket issue file list DKT-1 --json=v2
docket issue file remove DKT-1 --json=v2 internal/api/router.go
```

`add`/`remove` take 2+ positional args (`id` then one or more file paths) —
there is no `-f` flag on `issue file add`; that's only on `issue create -f`
and `issue edit -f`. Files are additive on `file add` (unlike `issue edit
-f`, which replaces the whole list).

---

## Workflow: Comments

```bash
docket issue comment add DKT-1 --json=v2 -m 'Investigated — root cause is a stale cache key in internal/cache/key.go:88; reproduced with go test ./internal/cache -run TestKeyReuse'
docket issue comment list DKT-1 --json=v2
```

`-m`/`--message` is optional: if omitted and stdin is a pipe, the body is
read from stdin; if omitted and stdin is a TTY (human mode only), `$EDITOR`
(default `vi`) is opened. In `--json` mode, `-m` (or piped stdin) is
required — there is no editor fallback.

**Record the observation and its provenance.** State what was found, the
relevant measured result, and a command, path, revision, or artifact ID that
helps another reader verify it. A date or ID alone does not explain the
evidence, but useful pointers should accompany the self-contained finding.

---

## Workflow: Labels & Relations

```bash
docket issue label add DKT-1 --json=v2 backend must-have --color '#ff0000'
docket issue label rm DKT-1 --json=v2 must-have
docket issue label list --json=v2
docket issue label delete backend --json=v2 --force   # --force skips the attached-issue-count confirmation

docket issue link add DKT-1 --json=v2 blocks DKT-2      # DKT-1 blocks DKT-2
docket issue link add DKT-1 --json=v2 depends_on DKT-3   # DKT-1 depends_on DKT-3
docket issue link remove DKT-1 --json=v2 blocks DKT-2
docket issue link list DKT-1 --json=v2
```

Valid `<relation>` values (`model.RelationType`): `blocks`, `depends_on`,
`relates_to`, `duplicates`.

---

## Workflow: Dependency Graph (`docket issue graph`)

```bash
docket issue graph DKT-1 --json=v2 --direction both --depth 2
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
docket plan --json=v2
docket plan --json=v2 --root DKT-1                      # scope to a parent issue's subtree
docket plan --json=v2 -s backlog -s todo -l must-have    # filter by status/label
docket plan --json=v2 -p high -p critical -T bug -a alice # filter by priority/type/assignee
```

`docket next` finds work-ready issues — no incomplete blockers, in one of
the ready statuses (default `backlog`,`todo`):

```bash
docket next --json=v2
docket next --json=v2 -s todo -p high -p critical -l must-have --limit 5
```

For planning or executing a run, follow the companion skills linked from
[the entry point](../SKILL.md). `next` without `--run` inspects issues;
`next --run` is a scheduler operation with possible mutations.

---

## Workflow: Docs (`docket doc`)

```bash
docket doc create --json=v2 -t 'ADR-0003: SQLite over Postgres' -T adr -s accepted \
  -d '@docs/adr/0003-sqlite.md'          # '@path' loads body from a file
docket doc create --json=v2 -t 'Quick note' -d - <<'DOCKET_NOTE_A71C'
Record the agreed API limit.
DOCKET_NOTE_A71C
docket doc show DOC-1 --json=v2
docket doc show DOC-1 --json=v2 --rev 2               # a specific revision
docket doc list --json=v2 -T adr -s accepted
docket doc edit DOC-1 --json=v2 -s superseded
docket doc delete DOC-1 --json=v2 --force
docket doc link add DOC-1 --json=v2 --issue DKT-1
docket doc link remove DOC-1 --json=v2 --issue DKT-1
docket doc comment add DOC-1 --json=v2 -m 'Needs a follow-up on migration path'
docket doc comment list DOC-1 --json=v2
```

`--description`/`-d` on `doc create`/`doc edit` supports the same three
input modes as `issue create -d`: literal string, `@path/to/file` (loads
file contents, 1 MiB cap), or `-` (stdin, 1 MiB cap).

---

## Workflow: Export / Import

A shared store can contain several projects. Confirm the intended store,
export scope, and destination before transferring data. `--replace` wipes the
database, so use it only for an explicitly authorized replacement; choose
one import mode from these alternatives.

```bash
docket export --json=v2 -o json -f backup.json
docket export -o csv -f issues.csv -s todo -s in-progress
docket export -o markdown > issues.md

docket import backup.json --json=v2 --merge          # skip duplicates by ID
docket import backup.json --json=v2 --replace --yes  # destructive: wipes DB first; --yes required in every output mode
docket import backup.json --json=v2                  # default: requires an EMPTY database, else CONFLICT
```

`export` streams to stdout when `-f`/`--file` is omitted. `import` requires
`--merge` XOR `--replace`, or an empty database — passing both is a
`VALIDATION_ERROR`, and importing into a non-empty DB without either flag
is a `CONFLICT`.

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

---

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
parse to the same issue, **from any project**. That last part is what
makes `issue list --project` usable: the listing prints another project's ids,
and the next command has to be able to take one back. `DOC`, `RUN`, and `STEP`
are reserved, never project-configurable, and never parse as issue ids — an
`issue show RUN-3` that resolved to issue 3 is exactly the ambiguity the
reservation exists to prevent.

A step also carries a rendered **instance identity** — `name@k#i`, where `k` is
the loop ordinal and `#i` the fanout sibling index (`implement@0`,
`review@0#2`). That is the step's public name in wire shapes, events, and error
strings; `STEP-N` is its database id. Both appear on every step row.
