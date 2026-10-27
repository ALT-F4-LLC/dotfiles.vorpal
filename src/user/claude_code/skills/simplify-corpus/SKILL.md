---
name: simplify-corpus
description: >-
  Use on "simplify the corpus", "/simplify-corpus", "run simplify over the
  skills", "simplify every workflow", "tighten", "tighten the prose", "make
  this more concise", "cut the filler", or to keep the corpus simple under
  /loop (for example `/loop /simplify-corpus tighten`). Bare, applies the
  built-in simplify review to every tracked file in the repository whose
  kind it can check; `tighten` rewrites every tracked Markdown file for
  concision, never code. Paths or globs narrow either mode. A workflow
  verifies each candidate mechanically and adversarially,
  then this session files each survivor as a worker-ready Docket issue with
  the diff and evidence. Never edits the checkout or commits; under /loop it
  rests when nothing new is left to file. Distinct from the built-in simplify
  (current diff once), simplify-code (code cruft), corpus-check (coherence),
  and docket-prune (trials definitions).
argument-hint: "[tighten] [paths or globs, default: every tracked file the mode can check]"
---

# simplify-corpus

Run this skill inline in the main session. You resolve the targets, launch
the workflow, and file what it accepted as Docket issues. The session never
edits the checkout: its only writes are Docket issues and scratch files
under `$TMPDIR`. No `just activate`, no commit, no push, no run.

**Two modes share one pass.** A first argument of `tighten` selects tighten
mode, and the arguments after it are its paths; otherwise every argument is
a simplify-mode path. Simplify mode applies the built-in simplify skill's
review (reuse, simplification, efficiency, altitude) to any file kind.
Tighten mode rewrites Markdown prose for concision under CLAUDE.md's prose
rules and never touches code. The sections below name each place the modes
differ; everything else applies to both. `$MODE` is `simplify` or `tighten`
and `$LABEL` is `corpus-$MODE` throughout.

**Run it under `/loop` for repeated passes.** `simplify-corpus` has no watch
loop of its own: `/loop /simplify-corpus [tighten]` (self-pacing) or
`/loop 30m /simplify-corpus [tighten] <paths>` supplies the recurring
wake-up, and each firing re-enters this skill from §1. Invoked outside
`/loop`, do one pass and say so; there will be no next tick.

## Scope

`$ARGUMENTS` optionally names repo-relative paths or globs, after the
`tighten` word in tighten mode.

### Simplify mode

Bare invocation targets every tracked file in the repository whose kind the
workflow's `classify()` accepts: Markdown prose, `.js`, `.py`, `.sh`, `.rs`
and `.toml` anywhere in the checkout, every extensionless script under
`.docket/bin/` and `src/user/docket/bin/`, and the registered JSON schemas.
That reaches the corpus (skill, agent and reference Markdown,
`workflows/*.js`, `skills/*/scripts`, `statusline.sh`, `settings.rs`,
`hooks/*.sh`, and under docket `bin/doc-record`,
`bin/docket-workflow-claim`, `config/README.md`, `config/policy.toml`,
contracts, fragments, workflow TOML and `config/schemas/*.json`) and
everything outside it that `classify()` has a kind for: `tests/*.test.sh`,
the gate scripts under `.docket/bin/`, the repository `README.md`,
`Cargo.toml`, `Vorpal.toml`.

Skipped, because the review cannot apply to them: files `classify()`
returns as `data` (`allowed_signers`, `*.lock`, `*.jq`, `*.awk`, the
`justfile`, `renovate.json`, and every `*.json` that is not a registered
schema: fixtures, evals, inventories, the cut ledger), since they are
neither code the syntax gates can check nor prose the protected-span check
can guard. The workflow rejects any that reach it. Nothing else is skipped.

Never target with a filed issue; read, review, and report only, as §3's
report-only step says. Drop from no argument, since each is still read:

- `src/user/claude_code/CLAUDE.md` and
  `src/user/claude_code/references/working-agreement.md`: the operator's
  own working agreement, owned outside this corpus's style authority. Tighten
  mode treats them the same way.
- `src/user/claude_code/hooks/`, every file: the guard hooks are a
  permission and sandbox boundary that changes only by the operator's
  hand.
- `src/user/docket/config/schemas/`: every `<name>@<version>.json` is
  frozen bytes once registered, and the legitimate change is a new
  version file, which is design work for `docket-refit`; the candidate is
  reported as a refit proposal, never filed as a diff against the file.

Two target classes carry filing rules of their own, both in §3:
`settings.rs` is filed with a security gate line, and versioned docket files
(contracts, fragments, workflow TOML) are filed with the version bump
`frozen-drift-check` demands.

### Tighten mode

Without paths, tighten mode targets every tracked Markdown file in the
repository: `skills/**/*.md`, `agents/*.md`, `references/*.md`, the
repository `README.md`, and `src/user/docket/config/README.md`.

Only Markdown prose is ever rewritten, so every other kind is skipped
because the mode cannot apply to it: code and configuration
(`workflows/*.js`, `hooks/`, `settings.rs`, `statusline.sh`, TOML, JSON,
shell) and data (`allowed_signers`, lockfiles); simplify mode covers the
code. Two Markdown sets are skipped too, each for a reason: contracts and
fragments under `src/user/docket/config`, because the equal-mode
protected-span check demands byte-identical frontmatter while a body change
there demands a `version` bump, so a tighten candidate could never land
(simplify mode reviews them with its bump rule); and
`src/user/docket/config/changelogs/*.md`, which record landed versions
rather than instruct anyone.

Never target with a filed issue; read, rewrite, and report only, as §3's
report-only step says:

- `src/user/claude_code/CLAUDE.md` and
  `src/user/claude_code/references/working-agreement.md`: the operator's
  own working agreement, owned outside this corpus's style authority, and
  the source of the rules this mode enforces.

Inside a file, `scripts/protected-spans.sh` compares frontmatter, fenced
blocks at any indentation, indented code blocks, headings, and HTML
comments, and in prose the inline code, double-quoted spans, section and
line references, and link targets, plus trailing blank lines and the final
newline, between original and candidate; the workflow rejects a chunk where
any differs. Backticks and quote marks pair only within a paragraph, so a
quote mark inside a code snippet never locks the prose after it.

## 1. Each pass

1. Resolve targets. Run `git ls-files -- <paths>` from the repository root
   over the mode's paths (`git ls-files` alone with none: the whole
   repository is the default, and paths only narrow it), keep only `.md`
   files in tighten mode, and apply the mode's Scope skips. Keep the
   report-only files in the list; §3 reports their candidates instead of
   filing them. Only tracked files are ever candidates, so every candidate
   has a committed state to diff against. No files means nothing to do:
   report it and stop (under self-paced `/loop`, arm the idle wakeup in §4
   first).
2. Require unmodified targets. Run `git status --porcelain` and stop if a
   target is modified or staged; in simplify mode stop if any tracked file
   is, target or not. Candidates are built from the working-tree bytes and
   filed as a diff against `HEAD`, so a target that differs from `HEAD`
   would file a diff that does not apply. Simplify mode checks the whole
   tree because the built-in simplify skill reviews the current diff, so a
   dirty tree is what a simplifier following it could pick up. Report the
   dirty paths instead.
3. Bind the project and load what is already filed. Run from the repository
   root, since the cwd picks the Docket project; if no project answers,
   stop and say so, and do not register one. The open set is this skill's
   dedupe set and the declined map lists cuts the operator turned down:

   ```bash
   SCRATCH=$TMPDIR/simplify-corpus/pass-<n>   # empty and unique to this pass
   mkdir -p "$SCRATCH"
   git status --porcelain > "$SCRATCH/porcelain-before.txt"   # the §2 tree check diffs against this
   docket issue list --json=v2 --limit 1000 --with-body -l "$LABEL" -s backlog -s todo -s in-progress -s review > "$SCRATCH/open.json"
   docket issue list --json=v2 --all --limit 1000 -l "$LABEL" -l wont-do > "$SCRATCH/declined.json"
   jq '.data.truncated' "$SCRATCH/open.json" "$SCRATCH/declined.json"   # must print false twice
   jq -r '.data.items[] | [.id, .status, .title, ((([(.description // "") | scan("Corpus fingerprint: (\\S+)") | .[0]] | first) // ""))] | @tsv' "$SCRATCH/open.json" > "$SCRATCH/open.tsv"
   jq -r '.data.items[] | select(.status == "done") | [.title, .id] | @tsv' "$SCRATCH/declined.json" > "$SCRATCH/declined.tsv"
   ```

   Stop if either listing is truncated or cannot be read: a partial map
   would re-file work the operator already has or declined. `<n>` starts at
   1 and increments from earlier passes in this session.
4. Drop the targets that are already settled, so no agent is spent on them.
   A target's fingerprint is `$MODE/<path>/<blob>`, with `<blob>` from
   `git rev-parse HEAD:<path>`. Drop a target when any of these holds:
   - `open.tsv` carries its fingerprint: it is filed and waiting.
   - `declined.tsv` carries the title `corpus-$MODE: <path>`: the operator
     declined it with `wont-do`; the title match survives byte changes.
   - The session memo `$TMPDIR/simplify-corpus/seen-$MODE.tsv` carries a
     row for the path at the same blob: an earlier pass found it
     unchanged, rejected, or already filed. Rerunning on identical bytes
     would repeat the answer at full cost. The memo is session state and
     never committed; a new session retries everything.

   Nothing left means the pass rests: report it and go to §4.
5. Record the gates' baseline. Run `just crossref-check` and
   `just prose-gates` from the repository root, plus
   `just frozen-drift-check` in simplify mode, and keep their failure
   lines, if any. `frozen-drift-check` exits 2 without `docket`, `jq`, or
   `shasum`; record that as "gate unavailable" and, in that case, treat
   every versioned docket file as excluded for this pass, since nothing
   could prove its bump. The baseline goes into each issue so the worker
   charges the change only for failures it introduces.

## 2. Run the workflow

Each mode has its own workflow script: `simplify-corpus.js` for simplify
mode, `tighten.js` for tighten mode. Invoke it by `scriptPath`, always, at
the installed path `~/.claude/workflows/<script>`, expanding `~` to a
literal absolute path yourself first. The Workflow tool does not expand `~`
and resolves a relative path against the target repo's cwd, not the
dotfiles source tree. The installed copy is the only one the tool may
launch and the only one guaranteed to match this session's build. A missing
installed file means the corpus was never activated after this skill was
added: report that, don't launch the source copy.

```
Workflow({ scriptPath: "<absolute installed path to the mode's script>", args: { files: [<repo-relative paths>], scratchDir: "<absolute scratch path>", pass: <n> } })
```

Candidates mirror repo-relative paths under `scratchDir`, so the scratch
directory of §1 is the one to pass.

**Simplify mode.** The workflow classifies each file by kind and runs one
simplifier per file, which copies the file into the scratch mirror, invokes
the built-in simplify skill on the copy where the Skill tool is available
and applies its four criteria directly otherwise, or returns
`changed=false` for a file already simple. A runner agent then executes
`scripts/simplify-check.sh` and returns its report verbatim. The script
runs the kind's syntax gate, checks Markdown's protected spans with
`scripts/protected-spans.sh subset` (a candidate may delete protected
content but never add or alter it) and its frontmatter, reads the version
of a versioned docket file, and measures both files. The workflow parses
the report and rejects in code a candidate that fails a gate, did not
shrink, lacks a strictly greater version, or left no parsable report.
Survivors face three refuters, each leading from a different angle
(behavior or meaning, the caller or reader, churn), and a candidate needs
two upholds to be accepted. The return carries `accepted`, each with its
`file`, `kind`, `candidate` path, `summary`, `confirm` and `versioned`
flags, version, byte and line counts, and vote tally; `rejected`, each with
its reason; `unchanged`; and a one-line `summary`.

**Tighten mode.** The workflow splits each file with
`scripts/tighten-chunks.sh` into chunks of about 200 lines, cut only at a
heading or paragraph edge outside fences and frontmatter, and runs one
rewriter per chunk, which reads it sentence by sentence and edits a copy in
place, or returns `changed=false` for a chunk already tight. A runner agent
executes `scripts/protected-spans.sh equal` on the chunk and returns its
output verbatim; the workflow parses that output and rejects in code a
chunk that changed a protected span, did not shrink, or left no parsable
report. Survivors face three refuters, each leading from a different angle
(meaning, reader, churn), and a chunk needs two upholds to be accepted.
Accepted chunks join with the untouched rest into one candidate per file,
which must pass the whole-file check again, so a refuted edit costs its
chunk, not the file. The return carries `accepted`, each with its `file`,
`candidate` path, byte and line counts, per-chunk vote tallies, and the
`rejectedChunks` that are not in the candidate with their reasons;
`rejected`, each with its reason; `unchanged`; and a one-line `summary`.

If the workflow throws or returns nothing, say so and stop. Do not
substitute a manual rewrite as if it satisfied the step.

Run `git status --porcelain` again and diff it against
`$SCRATCH/porcelain-before.txt`: the workflow writes only scratch
candidates, so any new or changed tracked file is a defect. Report it,
restore nothing yourself, and stop before filing. The check cannot see
further writes to a non-target file that was already dirty (tighten mode
allows those) or writes to ignored files.

Add a row `<path><TAB><blob><TAB>unchanged` or `rejected` to the session
memo for every file the return lists under `unchanged` or `rejected`.

## 3. File the accepted candidates

Each accepted candidate becomes one Docket issue, created from the
repository root. The filing contract is docket-postmortem's
[worker-ready issue contract](../docket-postmortem/references/filing.md#worker-ready-issue-contract)
and
[deduplicate before creating](../docket-postmortem/references/filing.md#deduplicate-before-creating)
sections as written, with these substitutions: the label is `$LABEL`, the
type is `chore`, the priority is `low`, and the description follows the
structure below. The issue is unrouted: no routing label, no assignee, no
size label. `docket-groom` triages it and `docket-plan` or direct work
drains it.

**Report-only files never reach the CLI.** Before step 1, set aside every
accepted candidate whose file is `src/user/claude_code/CLAUDE.md`,
`src/user/claude_code/references/working-agreement.md`, anything under
`src/user/claude_code/hooks/`, or (simplify mode) a schema under
`src/user/docket/config/schemas/`. Run step 1's check on each so the
report carries real evidence, keep the scratch candidate path, and carry
the file, the entry's summary, the bytes and lines removed, and the diff's
scratch location to the Report as an operator decision: the charter changes
by the operator's hand, a hook is a permission boundary, and a schema
candidate is a `docket-refit` proposal for a new version, never a diff
against frozen bytes. Add `<path><TAB><blob><TAB>reported` to the session
memo so a later pass does not rerun the workflow on the same bytes. File
nothing for them.

1. **Check the candidate yourself.** The workflow read the check's report
   through a runner agent, so run the check again on the scratch candidate
   and keep its output for the issue:

   ```bash
   # tighten mode
   bash ~/.claude/skills/simplify-corpus/scripts/protected-spans.sh equal "<file>" "<candidate>"
   # simplify mode, with the accepted entry's kind
   bash ~/.claude/skills/simplify-corpus/scripts/simplify-check.sh <kind> "<file>" "<candidate>"
   ```

   Exit 0 files it. Any other exit drops the candidate from the accepted
   list with the report's `changed` or `failed` lines as its reason, and it
   gets a `rejected` memo row.
2. **Take the diff.** `diff -u --label "a/<file>" --label "b/<file>" "<file>" "<candidate>"`
   is the change, and `git apply` takes it at the inspected blob. A diff
   over 800 lines is held, not filed: an issue body that large defeats a
   cold reader. Report the file as held with its scratch candidate path.
3. **Name the gates.** The worker runs what a landing would have run. Build
   the list from the file and mode, and find each suite with `grep -lF` over
   `tests/`: by the file's path below `src/user/claude_code/` in tighten
   mode (nearly every suite names some `SKILL.md`), and by its basename in
   simplify mode.
   - always: `just crossref-check` and `just prose-gates`;
   - a skill file: `just doc-validate`;
   - each suite under `tests/` that names the file;
   - simplify mode, also: `just frozen-drift-check` when it was available at
     baseline; for `workflows/*.js`, `bash tests/workflow-module-parse.test.sh`
     and `bash tests/workflow-structured-output.test.sh`; for a contract,
     fragment, or workflow TOML, `bash tests/contract-corpus.test.sh`,
     `bash tests/contract-includes.test.sh`, and
     `bash tests/contract-cluster-keys.test.sh`; for `settings.rs`,
     `just self-hygiene` and `just tests`, named in the issue and not run
     here, since they write build output into the checkout.

   Run the other named suites once on the unmodified tree and add any
   failure lines to the baseline from §1; a suite already red is not this
   change's breakage.
4. **Draft the body** into `$SCRATCH/issues/<n>.md`, and pass it to the CLI
   as a file, never interpolated into shell text:

   ```text
   [settings.rs only, as the first line:] Security gate required: this remedy
   touches sandbox/permissions.

   Observed: <file> (<kind>) at <HEAD> can be <simplified|tightened>:
     <the entry's summary>. The candidate removes <bytes> bytes and <lines>
     lines.
   Evidence: the mechanical check on the scratch candidate, verbatim:
     <report>. Refuters: <upheld> of <votes> upheld. [Tighten: <accepted> of
     <total> chunks in the candidate; <rejectedChunks with reasons>.]
   Baseline: gate failures present before the change: <lines, or none>.
   Remedy: apply the diff below to <file>.
     [Versioned file: the candidate bumps version <before> to <after>.]
     [Workflow TOML: add a `## <after>` entry at the top of
     src/user/docket/config/changelogs/<name>.md in that file's existing
     style, from the summary.]
   <the unified diff, in a diff fence>
   Acceptance:
     - `git apply --check` accepts the diff at blob <blob>; save a copy of the
       file, then apply it.
     - <the step 1 command, with `src/user/claude_code/skills/simplify-corpus/scripts/`
       as the script directory, the saved copy as the original, and the
       edited file as the candidate> exits 0. Failing variant: the same
       command exits non-zero when one protected span (a quoted phrase, a
       link target, a fenced block) differs, or the file no longer parses.
     - Each gate named below introduces no failure absent from Baseline:
       <the gates from step 3>.
     - A failure that names a sentence a suite pins verbatim means that hunk
       is dropped, not forced and not worked around by editing the suite;
       say which hunk in the closing comment.
   Corpus fingerprint: <$MODE>/<path>/<blob>
   ```

   The `settings.rs` line is the filing contract's wording for a sandbox or
   permission remedy. It sends the issue through the security gates of the
   workflow that drains it, and this skill waives none of them.
5. **Create.** One create per candidate. `--size small` holds for every
   candidate: one file, or one workflow TOML with its changelog, which the
   [sizing reference](../docket/references/sizing.md) counts as one
   directory, and every criterion is verifiable from the diff or a named
   command. No size label: `settings.rs` is security-sensitive and carries
   none, and `docket-plan` applies the others.

   ```bash
   fp="$MODE/$file/$(git rev-parse "HEAD:$file")"
   scope="$file"   # a workflow TOML: src/user/docket/config/*/<name>.* (the TOML and its changelog)
   out=$(docket issue create --json=v2 -t "corpus-$MODE: $file" -T chore -p low -l "$LABEL" --size small \
     -f "$file" --scope "$scope" --idempotency-key "$fp" -d - < "$body") || echo "FAILED $file"
   jq -r '.data.id // .data.issue.id // empty' <<< "$out"
   ```

   A workflow TOML adds a second `-f` for its changelog. `-f` and `--scope`
   are never omitted. The idempotency key is the fingerprint, so a retried
   create, or a repeat on the same blob, replays the original issue instead
   of filing a second. Read each receipt back with `docket issue show` and
   confirm its id, title, files, label, and empty assignee; verify the scope
   from the create response, since `show` does not return it. A failed row
   is reported with the CLI's error and left unfiled, and the next pass
   retries it because it has no memo row.
6. **Supersede.** `open.tsv` rows with the same title and a different
   fingerprint are filings for bytes that have since changed. After the new
   issue exists, close each in status `backlog` or `todo`:

   ```bash
   docket issue move "<old id>" done --note "superseded by <new id>" --json=v2 < /dev/null > /dev/null
   ```

   Leave one in `in-progress` or `review` open and report it; a worker may
   be holding it.
7. **Remember.** Add `<path><TAB><blob><TAB>filed` to the session memo for
   each candidate filed or replayed, and `held` for each candidate held for
   size, so a later pass does not rerun the workflow on bytes that already
   produced an unfileable candidate.

## 4. Next pass

A pass rests when every candidate is filed, replayed, or settled. Filing
changes no file, so a second pass over the same bytes would repeat the
first; the settled checks in §1 are what end the loop.

- **Outside `/loop`:** one pass. Say the pass is done and stop.
- **Self-paced `/loop /simplify-corpus [tighten]`:**
  - Filed anything or a row failed: arm
    `ScheduleWakeup({delaySeconds: 300, noop: false, prompt: "<the loop
    prompt verbatim>", reason: "simplify-corpus <mode> filed issues;
    checking for failed or newly eligible rows"})` and stop.
  - Nothing new to file: arm
    `ScheduleWakeup({delaySeconds: 1800, noop: true, prompt: "<the loop
    prompt verbatim>", reason: "simplify-corpus <mode> found nothing new to
    file"})` and stop. Send no "nothing changed" message; a quiet tick is
    not an event.
- **Explicit interval (`/loop 30m /simplify-corpus [tighten]`):** one pass;
  the cron firing supplies the next tick, so stop.

The loop ends when the operator stops it (`ScheduleWakeup({stop: true})`
under self-pacing, or telling you to stop) or ends the `/loop`. A resting
pass is a rest, not a finish: a worker landing a filed change, or any later
edit to the corpus, gives the next tick new bytes to simplify or tighten.

## Report

State the mode and pass number, the issues filed with their ids and files,
replays and filings superseded (with any left open and why), candidates held
for size, every report-only candidate (file, summary, bytes and lines
removed, scratch diff path) as an operator decision with nothing filed,
files rejected with their reasons, files unchanged, files skipped
as settled or declined, and failed rows with the CLI's error. Say that no
fixes were applied: filed issues drain through `docket-groom` routing into a
`docket-plan` and `docket-run` execution or direct work, and a landed
contract, fragment, or workflow TOML reaches the engine only after the
operator runs `just activate` and `docket-reconcile`. Do not claim
`just activate` ran; it didn't.
