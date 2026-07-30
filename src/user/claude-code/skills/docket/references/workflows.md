# Docket Workflows — worked examples

Recipes for each workflow area. The contracts (JSON envelope, exit codes, `.data` shapes,
enums, comment `-m` rule) live in SKILL.md; this file only shows composed invocations.

## Issue creation & editing

```bash
docket issue create --json \
  -t "Add rate limiting to API" \
  -d "Prevent abuse on public endpoints" \
  -p high -T feature \
  -l backend -l must-have \
  -f internal/api/router.go \
  -a "@alice"
```

Only `--title` is required in JSON mode. New issues default to `backlog`; only team-lead
promotes to `todo`, immediately before spawning the ephemeral that claims it. Description
can be piped: `echo "Long description..." | docket issue create --json -t "Title" -d -`.

`issue edit` applies only the fields you pass (omitted flags are left untouched):

```bash
docket issue edit DKT-1 --json -s in-progress -a "@bob"
docket issue edit DKT-1 --json --parent DKT-5    # reparent (cycle/self-parent rejected)
docket issue edit DKT-1 --json --parent none     # make it a root issue again
docket issue edit DKT-1 --json -f a.go -f b.go   # REPLACES the file list (not additive)
```

Lifecycle:

```bash
docket issue move DKT-1 review --json     # arbitrary status transition
docket issue close DKT-1 --json           # shorthand for: move <id> done
docket issue reopen DKT-1 --json          # move done -> backlog (only if currently done)
docket issue delete DKT-1 --json --force  # cascade-delete issue + all sub-issues
docket issue delete DKT-1 --json --orphan # delete issue, promote sub-issues to root
```

List and inspect:

```bash
docket issue list --json -s todo -s in-progress -p high --tree
docket issue show DKT-1 --json     # full detail: sub-issues, relations, comments, activity, docs
docket issue log DKT-1 --json --limit 50
```

## File attachments

```bash
docket issue file add DKT-1 --json internal/api/router.go internal/api/middleware.go
docket issue file list DKT-1 --json
docket issue file remove DKT-1 --json internal/api/router.go
```

`add`/`remove` take positional paths (no `-f` flag here — that's only on `issue create`/
`issue edit`). `file add` is additive, unlike `issue edit -f` which replaces the list.

## Comments

```bash
docket issue comment add DKT-1 --json -m "Investigated — root cause is a stale cache key"
docket issue comment list DKT-1 --json
```

The message contract (always `-m`, always the verb `add`, always `--json`) is in SKILL.md.

## Labels & relations

```bash
docket issue label add DKT-1 --json backend must-have --color "#ff0000"
docket issue label rm DKT-1 --json must-have
docket issue label list --json
docket issue label delete backend --json --force   # --force skips the attached-count confirmation

docket issue link add DKT-1 --json blocks DKT-2      # DKT-1 blocks DKT-2
docket issue link add DKT-1 --json depends_on DKT-3
docket issue link remove DKT-1 --json blocks DKT-2
docket issue link list DKT-1 --json
```

## Dependency graph

```bash
docket issue graph DKT-1 --json --direction both --depth 2
docket issue graph DKT-1 --mermaid --direction down   # Mermaid flowchart, human mode only
```

`--direction`: `up` (what blocks this), `down` (what this blocks), `both` (default);
`--depth 0` = unlimited. Use before touching a shared interface to assess blast radius.

## Planning

```bash
docket plan --json                                   # dependency-ordered phases (cycle -> CONFLICT)
docket plan --json --root DKT-1                      # scope to a parent issue's subtree
docket plan --json -s backlog -s todo -l must-have
docket next --json                                   # work-ready issues (no incomplete blockers)
docket next --json -s todo -p high -p critical -l must-have --limit 5
```

## Voting

```bash
docket vote create --json \
  -d "Adopt Result<T,E> for all internal/db error returns" \
  -r "Panics currently propagate uncaught in 3 call sites" \
  -c high -n 3 --threshold 0.67 \
  --domain-tags "database,error-handling" \
  --files-changed "internal/db/issue.go,internal/db/doc.go"

docket vote cast DKT-V1 --json \
  -v approve --confidence 0.9 --domain-relevance 0.8 \
  --findings "Reviewed all call sites, no blockers" \
  --summary "LGTM"

docket vote show DKT-V1 --json
docket vote result DKT-V1 --json
docket vote list --json --all               # omit --all for open-only (the default)
docket vote commit DKT-V1 --json --outcome "Approved: adopting Result<T,E>"
docket vote link DKT-V1 --json --issue DKT-1
docket vote unlink DKT-V1 --json --issue DKT-1
```

## Docs

```bash
docket doc create --json -t "ADR-0003: SQLite over Postgres" -T adr -s accepted \
  -d "@docs/adr/0003-sqlite.md"          # "@path" loads body from a file (1 MiB cap)
docket doc create --json -t "Quick note" -d "-"   # "-" reads body from stdin
docket doc show DOC-1 --json --rev 2               # a specific revision
docket doc list --json -T adr -s accepted
docket doc edit DOC-1 --json -s superseded
docket doc delete DOC-1 --json --force
docket doc link add DOC-1 --json --issue DKT-1
docket doc comment add DOC-1 --json -m "Needs a follow-up on migration path"
```

## Watch mode

```bash
docket issue list --json --watch --interval 5s
docket board --watch                       # human-mode live board, default 2s interval
docket vote result DKT-V1 --watch --interval 1s
```

Runs until SIGINT/SIGTERM. Write commands reject `--watch` with `VALIDATION_ERROR`.

## Export / import

```bash
docket export --json -o json -f backup.json
docket export -o csv -f issues.csv -s todo -s in-progress
docket export -o markdown > issues.md              # streams to stdout when -f omitted

docket import backup.json --json --merge      # skip duplicates by ID
docket import backup.json --json --replace    # DESTRUCTIVE: wipes DB first
docket import backup.json --json              # default: requires an EMPTY database, else CONFLICT
```

`import` requires `--merge` XOR `--replace`, or an empty database — both flags together is
a `VALIDATION_ERROR`; a non-empty DB without either is a `CONFLICT`.
