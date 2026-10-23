# Groom mechanics

Shapes and shell facts a pass needs at the keyboard. Every item here cost
an earlier pass a failed command and a retry; read it once at the survey
instead of rediscovering it. The skill text (`../SKILL.md`) says what a
pass does; this file says how the commands behave.

## Workflow result file

The `Workflow` tool writes the script's return under `tasks/<task id>.output`
in the session directory. The file is an envelope, not the return:

```bash
F=<output file from the task notification>
jq -r '.summary' "$F"                     # the script's one-line summary
jq '.result.ledger' "$F"                  # one entry per issue; epics carry judged=false
jq '.result.clusters, .result.uncovered' "$F"
jq '{agents: .agentCount, tokens: .totalTokens, tools: .totalToolCalls}' "$F"
```

`.ledger` at the top level is null. Judged entries carry `value.decision`,
`size.tier`, `size.sizeVerdict`, `routing.verdict`, `routing.matches`,
`epic.candidate`, `criteria[]` (`verdict`, `defect`, `repair`, `lint`),
`readiness.scopeLint`, and `notes`. The two lint fields carry the base sha,
exit code, and reported lines of the judge's own lint runs.
Copy the file into the scratchpad beside the ledger: the session directory
is not kept, and a later audit of the pass has nothing else to read.

## Docket JSON envelopes

Every `--json=v2` answer is `{"ok": true, "data": ...}`.

- `docket issue list --json=v2 --limit 1000 ...`: `.data.items[]`,
  `.data.total`, `.data.truncated`. Rows carry no description; read
  `description_bytes` to see which issues have one.
- `docket issue show <id> --json=v2`: `.data.description`, `.data.version`,
  `.data.sub_issues[]` on an epic, `.data.relations[]` (fields
  `source_issue_id`, `target_issue_id`, `relation_type`), `.data.labels`,
  `.data.files`, `.data.scope`, `.data.size`.
- `docket issue comment list <id> --json=v2`: `.data.comments[]`.
- `docket project list --json`: `.data.projects[]` with `name`, `prefix`,
  `identity`, `current`.
- `docket run status --json`: `.data.total` and `.data.runs[]`.

A `docket issue create --json=v2` answer can carry raw control characters
inside the echoed description, which `jq` refuses. Strip them first:

```bash
docket issue create ... --json=v2 | tr -d '\000-\010\013\014\016-\037' | jq -r '.data.id'
```

Then confirm the create as §4b requires: `created_at` not earlier than the
pass id and the proposed title.

## Verbs and flags confirmed against the installed CLI

- Labels: `docket issue label add <id> <label>...` and
  `docket issue label rm <id> <label>...`. `docket issue edit` has no `-l`
  flag, and `label remove` is not a verb.
- Relations: `docket issue link add <id> <relation> <target>`,
  `docket issue link remove ...`, `docket issue link list <id>`. Adding an
  existing relation fails with "relation already exists"; check
  `link list` first instead of retrying.
- Files: `docket issue file add <id> <path>...` appends;
  `docket issue edit -f` replaces the whole list.
- Descriptions: pass `-d -` and the body on stdin from a file. Never pipe
  through `echo`: zsh `echo` interprets backslashes and once mangled eight
  description edits while their labels landed. Use `printf '%s'` or
  `cat <file>`.
- Comments: `docket issue comment add <id> -m "$(cat <file>)"`.
- Every edit and close takes `--if-version <n>` from a fresh
  `issue show`, and every write bumps the version: on one issue run the
  edit first, then the comment and labels, each from a re-read. A stale
  version fails with "modified by another writer (version mismatch)", code
  CONFLICT, which is the signal to re-read, not to retry.

## Shell facts on this machine

- `sed -i` needs an empty suffix: `sed -i '' -e '...'`. GNU-only flags
  such as `sed -E 's/.../.../I'` fail with "bad flag in substitute command".
- No `timeout` command; run `go test` without it.
- The only bash is 3.2 (`/bin/bash`; `#!/usr/bin/env bash` finds the same
  one): no `declare -A`, no `mapfile`, and `set -u` fails on an empty
  array expansion, which needs `"${arr[@]+"${arr[@]}"}"`.
- The sandbox refuses process substitution (`<(...)` fails with
  "/dev/fd: Operation not permitted") and `eval` of a command file. Write
  the file and run it with `bash <file>`.
- Run `scripts/ac-lint.sh` and `scripts/scope-lint.sh` with `--repo` set to
  the issue's home checkout or from inside it; from elsewhere they fail
  with "not a git repository".
- Post-process with `jq`, `grep`, `sed -n`, `head`, `wc`. The
  auto-mode classifier refuses `python`, `perl`, `node`, and `ruby` given
  code inline or on stdin.

## Apply pattern that needs no rework

Before a proposal goes to the advisor, build the stored shape it would
leave (criteria text, files, scope) in scratchpad files and run both lints
on that shape: `ac-lint.sh --base <sha> --repo <checkout> --shared-base
<criteria file>` (`--shared-base` is a flag; the file is a positional
argument) and `scope-lint.sh --base <sha> --repo <checkout> <envelope file>`,
where the file holds a `{"data": {"description", "files", "scope"}}`
envelope with the proposed values; any other shape exits 2. A path named
inside a `Verify:` command is a files-and-scope
gap unless it follows one of scope-lint's inspect markers, so name a trusted
command (`build`, `tests`) rather than its script path when the issue does
not change that script. Apply only a shape both lints pass; then the
post-apply lint is a confirmation, not a second drafting round.
