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

## Facts a live pass paid for

- The lint scripts once failed silently under the sandbox: bash 3.2 writes a
  here-string to a temp file outside TMPDIR, the sandbox refuses that from
  some working directories (the engine checkout in one session, both in
  another), and set -e does not stop on the failed redirect, so the loop
  ran zero times and the script exited 0 having checked nothing. Both
  scripts now read loop input from files under TMPDIR. Treat "cannot
  create temp file" in any lint output as a lint that did not run.
- The gate split between Run-ready and the Waiting states comes from
  `scripts/open-deps.sh`, which reads each issue's `depends_on` relations
  and the live status and route of every target, printed as
  `<target>(<status>,<route>)`; a judge's readiness does not see
  dependency status. One pass certified eight `route-run` issues as
  waiting on a prerequisite that carried `route-direct`: a run never does
  that work, so docket-plan would have deferred all eight on every pass.
  Any route other than `route-run` on an open target is §2b's cross-route
  finding, settled inside the pass.
- Judges return placeholder criterion drafts ("drafted for an uncovered
  requirement", "not linted") marked lint 0. The workflow logs them and
  returns them under `undraftedCriteria`; the pass drafts those criteria
  inline from source before any apply.
- An advisor result that never arrives is read from the subagent transcript
  at `~/.claude/projects/<project dir>/<session id>/subagents/agent-<agent
  id>.jsonl` (the assistant text entries), where the agent id is the spawn
  result's agentId and the sibling `.meta.json` names the agent's
  description for finding it; relaunching repeats the work
  and loses the same way. Three of six results in one pass needed this.
- A criterion that needs the engine QA suite is operator evidence under this
  sandbox: `pgrep` exits 3 (no process list), which makes the suite's
  detached-child wait return at once, and a here-document in the suite is
  refused. Say so when drafting the criterion, and ask the operator through
  `AskUserQuestion` to run
  `bash scripts/qa.sh "$(command -v docket)" <section>` from the engine
  checkout when the gate needs the result.
- macOS `grep` has no `-P`; key a tab-separated lookup with
  `awk -F'\t' -v k="$id" '$1==k'`. Check every helper script on bash 3.2
  and BSD userland before the pass depends on it.
