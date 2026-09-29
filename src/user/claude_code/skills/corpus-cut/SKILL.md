---
name: corpus-cut
description: >-
  Use on "cut the corpus", "/corpus-cut", "what in the docket corpus earns
  its place", "put the corpus on trial", "which definitions can go", or to
  keep the corpus lean under /loop (for example `/loop /corpus-cut`). Puts
  every definition under src/user/docket/config on trial: a prosecutor,
  a defender, a judge, and three refuters per definition rule stay,
  refactor (with the cut named), or remove for each file and each section,
  with the burden of proof on the definition; this session records the
  verdicts in the committed ledger and files one issue per cut for
  docket-refit to land. Bare invocation is one pass over what changed since
  the ledger; `all` re-tries everything; under /loop it passes until the
  corpus is unchanged and every cut is filed, then rests. Never executes a
  cut. Distinct from corpus-check, which audits coherence; tighten, which
  shortens prose; declutter, which cleans code; and docket-refit corpus
  mode, which keeps by default and redesigns.
argument-hint: "[all]"
model: fable
---

# corpus-cut

Run this skill inline in the main session. You enumerate the corpus, launch
the trial, file the issues, land the ledger, and commit. The workflow never
writes to the repository; the ledger candidate and every issue body land
under scratch, and this session files and commits.

**Automation first is the primary goal of every verdict.** Per the docket
skill's [automation reference](../docket/references/automation.md), an
issue this skill files names the definition, the unit, the cut, and the
evidence so `docket-refit` (or `tighten`, for a prose-only cut) can land it
without a further judgment call. The refit gates stay: this skill never
deletes, edits, or refactors a definition itself.

**The burden of proof is on the definition.** A unit (a file; a
section of a contract, meaning a top-level block after the Charter or any
second-level heading; a second-level section of a fragment; an
`[executors]` row of policy.toml)
with no evidence in any class that applies to its kind is removed, not
kept: no consumer resolves to it, no run exercised it, no executor would
act differently without it, no frozen record a run pins names it. The
classes and which apply per unit kind are in the workflow's `UNIT_CLASSES`
table. Nothing is protected: policy.toml's `[security]` block, every
workflow, and README.md are tried on the same evidence, and a remove
verdict on any of them lands only through refit's own gates.

**Run it under `/loop` for maintenance.** `corpus-cut` has no watch loop
of its own: `/loop /corpus-cut` (self-pacing) or `/loop 2h /corpus-cut`
supplies the recurring wake-up, and each firing re-enters this skill from
§1. Invoked bare with no loop wrapping it, do one pass and say so.

## Scope

The corpus is every tracked file under `src/user/docket/config` except
the ledger, `src/user/docket/config/cut-ledger.json`: `policy.toml`,
`README.md`, `contracts/*.md`, `fragments/*.md`, `workflows/*.toml`,
`schemas/*.json`. Every one receives a verdict each pass, fresh or carried
from the ledger; a definition the trial could not settle is reported as
unjudged, never silently omitted.

Evidence, all read-only: the corpus text; the static consumer census over
the corpus, the harness scripts, and the skill tree; the docket registry
and run store of every project in `docket project list`; agent transcripts
under `~/.claude/projects`; the friction ledger under `~/.claude/friction`;
and the installed copies under `~/.docket/config` and `~/.claude` compared
to source. Issue bodies cite transcript evidence by `path:line` locator,
the way shadow does, never by pasting transcript text.

Out of scope: executing any cut (that is `docket-refit` or `tighten`),
definitions under `src/user/claude_code`, anything under `~/.claude` or
`~/.docket` (read, never edited), `just activate`, pushing.

`$ARGUMENTS` is empty or `all`. Empty judges only definitions whose hash
differs from the ledger's or that carry no verdict, and carries every
other verdict forward. `all` re-tries every definition.

## 1. Each pass

1. Require a clean ledger. Run
   `git status --porcelain -- src/user/docket/config/cut-ledger.json` and
   stop if it is modified or staged: a pass lands as one commit, and a
   pre-existing edit would be swept into it.
2. Enumerate the corpus with hashes, from the repository root:

   ```bash
   git ls-files -- src/user/docket/config | grep -v '/cut-ledger\.json$' | while read -r f; do
     rel="${f#src/user/docket/config/}"
     case "$rel" in policy.toml) s=policy;; README.md) s=readme;; contracts/*) s=contract;; fragments/*) s=fragment;; workflows/*) s=workflow;; schemas/*) s=schema;; *) s=other;; esac
     printf '{"path":"%s","surface":"%s","hash":"%s"}\n' "$rel" "$s" "$(shasum -a 256 "$f" | cut -c1-64)"
   done | jq -s . > "$SCRATCH/definitions.json"
   ```

   Read the ledger with `jq . src/user/docket/config/cut-ledger.json`; a
   ledger with `"pass": 0` and no verdicts is the first pass.
3. Gather the evidence roots: `docket project list --json` for the
   projects (name, prefix, identity as root); the docket engine checkout at
   the docket.git project's identity path if that directory exists, else
   null; every directory under `~/.claude/projects` as transcript
   directories; `~/.claude/friction`, `~/.docket/config`, and `~/.claude`
   when they exist, else null. Expand `~` to a literal absolute path
   yourself.
4. Choose a scratch directory under `$TMPDIR`, empty and unique to this
   pass (for example `$TMPDIR/corpus-cut/pass-<n>`, incrementing `<n>`
   from earlier passes in this session), and take the UTC timestamp with
   `date -u +%Y-%m-%dT%H:%M:%SZ`.

## 2. Run the workflow

Invoke by `scriptPath`, always, at the installed path
`~/.claude/workflows/corpus-cut.js`, expanding `~` to a literal absolute
path yourself first. The Workflow tool does not expand `~` and resolves a
relative path against the target repo's cwd, not the dotfiles source tree.
The installed copy is the only one the tool may launch and the only one
guaranteed to match this session's build. A missing installed file means
the corpus was never activated after this skill was added: report that,
don't launch the source copy instead.

The committed ledger is too large to pass in one tool call, so pass it
slim. A stay or an already-filed cut keeps only the fields the workflow
reads; an unfiled cut keeps every field, because its writer renders the
issue body from it:

```bash
jq -c '.verdicts |= map(if (.verdict != "stay" and .issue == null) then . else {path, hash, unit, verdict, issue, disposition} end)' src/user/docket/config/cut-ledger.json > "$SCRATCH/ledger-slim.json"
```

```
Workflow({ scriptPath: "<absolute installed path to corpus-cut.js>", args: { checkoutRoot: "<repo root>", definitions: <contents of definitions.json>, ledger: <contents of ledger-slim.json, or null on the first pass>, all: <true when $ARGUMENTS is all>, projects: [{name, prefix, root}], engineRoot: <path or null>, transcriptDirs: [<absolute paths>], frictionDir: <path or null>, installedConfigDir: <path or null>, installedClaudeDir: <path or null>, scratchDir: "<absolute scratch path>", pass: <n>, nowIso: "<timestamp>" } })
```

The workflow plans the pass in code, gathers the evidence in one barrier,
then tries each selected definition through a prosecutor, a defender, a
judge, and three refuters (consumer, behavior, burden). Two refuters who
agree on a replacement override the judge; two who disagree leave the
ruling standing and contested; fewer than two seated leave it unverified.
Writers then land the merged ledger as sharded JSON arrays under
`<scratchDir>/ledger/` (`1.json`, `2.json`, ...), each checked entry by
entry in code, and one issue body per unfiled cut under
`<scratchDir>/issues/`, indexed by `index.<n>.tsv`. A file ruled remove
subsumes its sections: they stay in the ledger but get no issue of their
own. The return carries `plan`, `rest`, `verdicts`, `ledger`, `issues`,
`unfiled`, `superseded`, `evidence.coverage`, `uncovered`, and a one-line
`summary`. Each `superseded` entry, `{path, unit, issue, replacementKey}`,
names a ledgered issue of a re-judged definition and the replay key of the
cut that replaces it, or null when none does.

If the workflow throws or returns nothing, say so and stop. If `ledger` is
null while `rest` is false, a writer failed or its shard did not match:
report the `uncovered` reason and stop without landing anything. Do not
substitute a manual verdict as if it satisfied the trial.

## 3. File the cuts and land the ledger

When `rest` is true, nothing changed and every cut is filed: skip to §5.

Otherwise assemble the ledger candidate from the shards, then file one
issue per row of every `<scratchDir>/issues/index.<n>.tsv`, in this
session, from the repository root. In the snippets below `$SCRATCH`,
`$PASS`, and `$NOW` hold the scratch path, the pass number, and the
timestamp from §1. The row's key is the replay key: a
repeated pass on unchanged bytes returns the original issue, open or
closed. Once the bytes change the key changes, so a cut the operator
declined is skipped by title instead: a row whose title matches a closed
corpus-cut issue labelled `wont-do` files nothing and records that
issue's id. To decline a cut, run `docket issue label add <id> wont-do`,
then close it. A landed cut is closed without the label and never skipped.

The shards hold carried entries in the slim form you passed. Restore each
from the committed ledger, and stop if any restored entry disagrees with
its shard entry on path, hash, unit, verdict, or issue:

```bash
for f in $(ls "$SCRATCH/ledger" | sort -n); do cat "$SCRATCH/ledger/$f"; done | jq -s --arg pass "$PASS" --arg now "$NOW" '{version: 1, pass: ($pass | tonumber), judgedAt: $now, verdicts: add}' > "$SCRATCH/cut-ledger.raw.json"
jq '.verdicts | length' "$SCRATCH/cut-ledger.raw.json"   # must equal the return's ledger.entries
jq --slurpfile full src/user/docket/config/cut-ledger.json '
  ($full[0].verdicts | map({key: (.path + "\u0000" + .unit), value: .}) | from_entries) as $f
  | [.verdicts[] | select(has("reason") | not) | . as $v | $f[$v.path + "\u0000" + $v.unit]
     | select(. == null or [.path, .hash, .unit, .verdict, .issue] != [$v.path, $v.hash, $v.unit, $v.verdict, $v.issue]) | $v.path + "#" + $v.unit]' "$SCRATCH/cut-ledger.raw.json"   # must print []
jq --slurpfile full src/user/docket/config/cut-ledger.json '
  ($full[0].verdicts | map({key: (.path + "\u0000" + .unit), value: .}) | from_entries) as $f
  | .verdicts |= map(if has("reason") then . else $f[.path + "\u0000" + .unit] end)' "$SCRATCH/cut-ledger.raw.json" > "$SCRATCH/cut-ledger.json"
```

Only slim entries are restored: a unit judged this pass carries its full
fresh entry and is never replaced by the stale committed one.

Then map the declined cuts, title to id, and file:

```bash
docket issue list --all --limit 1000 -l corpus-cut -l wont-do --json=v2 > "$SCRATCH/declined.raw.json"
jq '.data.truncated' "$SCRATCH/declined.raw.json"   # must print false
jq '[.data.items[] | select(.status == "done") | {key: .title, value: .id}] | from_entries' "$SCRATCH/declined.raw.json" > "$SCRATCH/declined.json"
: > "$SCRATCH/ids.tsv"
cat "$SCRATCH"/issues/index.*.tsv 2>/dev/null | while IFS=$'\t' read -r key title scope body; do
  declined=$(jq -r --arg t "$title" '.[$t] // empty' "$SCRATCH/declined.json")
  [ -n "$declined" ] && { printf '%s\t%s\n' "$key" "$declined" >> "$SCRATCH/ids.tsv"; continue; }
  out=$(docket issue create --idempotency-key "$key" -t "$title" -d - -l corpus-cut --scope "$scope" --json=v2 < "$body") || { printf '%s\t%s\n' "$key" "FAILED" >> "$SCRATCH/ids.tsv"; continue; }
  printf '%s\t%s\n' "$key" "$(jq -r '.data.id // .data.issue.id // empty' <<< "$out")" >> "$SCRATCH/ids.tsv"
done
```

Stop if the assembled entry count differs from the return's
`ledger.entries`, or if the declined listing prints anything but `false`
for `truncated`: a partial map would re-file a declined cut. Repeated
`-l` flags AND, so the map holds only `wont-do` cuts. Confirm the id
field with the envelope on the first filed row; the docket skill's
reference names the v2 shapes. No routing label and no size is set: the
issue is unrouted for `docket-groom` to triage
and size, and `corpus-cut` is a plain label for listing. A row that
failed is reported with the CLI's error and left unfiled; its verdict
keeps `issue: null` and is filed again next pass.

Write the ids into the candidate, then land it:

```bash
jq -R -s 'split("\n") | map(select(length > 0) | split("\t")) | map(select(.[1] != "FAILED")) | map({(.[0]): .[1]}) | add // {}' "$SCRATCH/ids.tsv" > "$SCRATCH/ids.json"
jq --slurpfile ids "$SCRATCH/ids.json" '.verdicts |= map(if .key and $ids[0][.key] then .issue = $ids[0][.key] else . end)' "$SCRATCH/cut-ledger.json" > "$SCRATCH/cut-ledger.filed.json"
cp "$SCRATCH/cut-ledger.filed.json" src/user/docket/config/cut-ledger.json
```

Then close what the pass superseded, so a refit leaves no earlier cut
issue open. Write the return's `superseded` array to
`$SCRATCH/superseded.json` and handle each entry by its `replacementKey`,
looked up in `ids.json`, the ids.tsv map with FAILED rows dropped:

- It resolves to an id other than the entry's `issue`: close the issue
  with the note `superseded by <that id>`. A fresh verdict equal to the
  prior one on changed bytes lands here too: its key changed, so it filed
  a new issue, and the prior one closes as superseded by it.
- It resolves to the entry's own `issue` (a declined cut's row, or a key
  replayed under `all`): do nothing.
- It is null: close the issue with the note
  `cut no longer applies as of pass $PASS`.
- It maps to FAILED or is absent from ids.tsv: leave the issue open and
  report it, since its replacement never filed.
- Before either close, read the issue's status and skip one already in
  `done`, reporting it: a landed or declined cut is closed already.

```bash
: > "$SCRATCH/superseded.tsv"
jq -c '.[]' "$SCRATCH/superseded.json" | while read -r s; do
  issue=$(jq -r '.issue' <<< "$s"); rkey=$(jq -r '.replacementKey // empty' <<< "$s")
  if [ -n "$rkey" ]; then
    rid=$(jq -r --arg k "$rkey" '.[$k] // empty' "$SCRATCH/ids.json")
    [ -z "$rid" ] && { printf '%s\topen: replacement unfiled\n' "$issue" >> "$SCRATCH/superseded.tsv"; continue; }
    [ "$rid" = "$issue" ] && continue
    note="superseded by $rid"
  else
    note="cut no longer applies as of pass $PASS"
  fi
  status=$(docket issue show "$issue" --json=v2 | jq -r '.data.status // empty')
  [ -z "$status" ] && { printf '%s\topen: status unread\n' "$issue" >> "$SCRATCH/superseded.tsv"; continue; }
  [ "$status" = "done" ] && { printf '%s\tskipped: already done\n' "$issue" >> "$SCRATCH/superseded.tsv"; continue; }
  docket issue move "$issue" done --note "$note" --json=v2 < /dev/null > /dev/null \
    && printf '%s\tclosed: %s\n' "$issue" "$note" >> "$SCRATCH/superseded.tsv" \
    || printf '%s\topen: move failed\n' "$issue" >> "$SCRATCH/superseded.tsv"
done
```

`superseded.tsv` holds one row per entry the step closed, skipped, or
left open; the report lists them all.

Then run `just crossref-check` from the repository root and compare with
the state before the pass. The ledger is JSON, which the gate does not
scan, so a new failure names other work; report it and never act on it.

## 4. Commit

Invoke the `commit` skill scoped to the ledger
(`Skill({skill: "commit", args: "src/user/docket/config/cut-ledger.json"})`):
one commit cycle per pass, never batched across passes. Then report the
pass in a few lines: the pass number, definitions tried and carried, the
verdict counts, overrides by refuters, issues filed with their ids, rows
skipped as declined, rows that failed, every `superseded.tsv` row (issues
closed as superseded, skipped as already done, or left open), the commit
hash, every `uncovered`
entry, and the evidence coverage (run stores read, logs digested, engine
available or not).

## 5. Next pass

A pass rests when the corpus is unchanged since the ledger and every cut
has an issue; refit landing a cut changes the corpus, which gives the next
pass new bytes to try.

- **Bare invocation:** one pass. Say the pass is done and stop.
- **Self-paced `/loop /corpus-cut`:**
  - Tried or filed anything: arm
    `ScheduleWakeup({delaySeconds: 300, noop: false, prompt: "<the loop
    prompt verbatim>", reason: "corpus-cut tried definitions; checking for
    deferred or unfiled work"})` so a deferred definition or a failed row
    is picked up soon, and stop.
  - `rest` true: arm
    `ScheduleWakeup({delaySeconds: 1800, noop: true, prompt: "<the loop
    prompt verbatim>", reason: "corpus-cut found nothing new to try"})`
    and stop. Send no "nothing changed" message; a quiet tick is not an
    event.
- **Explicit interval (`/loop 2h /corpus-cut`):** one pass; the cron
  firing supplies the next tick, so stop.

The loop ends when the operator stops it (`ScheduleWakeup({stop: true})`
under self-pacing, or telling you to stop) or ends the `/loop`. A resting
pass is a rest, not a finish: the next edit to the corpus, or the next
run and transcript the evidence can read, gives a later tick new ground.

## Report

State what was tried, every verdict that is not stay with its unit and
reason, the issues filed, what was carried, what was deferred or
unverified, and the commit hash. Do not claim `just activate` ran; it
didn't, and the installed skills under `~/.claude` lag this checkout until
the operator runs it.
