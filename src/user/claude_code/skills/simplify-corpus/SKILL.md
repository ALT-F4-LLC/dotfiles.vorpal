---
name: simplify-corpus
description: >-
  Use on "simplify the corpus", "/simplify-corpus", "run simplify over the
  skills", "simplify every workflow", "tighten", "tighten the prose", "make
  this more concise", "simplify the prose in", "cut the filler", or to keep
  the corpus simple and tight under /loop (for example `/loop
  /simplify-corpus tighten`). Bare, applies the built-in simplify review
  (reuse, simplification, efficiency, altitude) to every tracked file under
  src/user/claude_code and src/user/docket; `tighten` mode rewrites
  Markdown prose for concision under CLAUDE.md's prose rules, never code.
  A workflow verifies every candidate mechanically and adversarially before
  this session lands and commits it; under /loop it passes until nothing
  shrinks, then rests. Distinct from the built-in simplify, which reviews
  the current diff once; declutter-code, which cleans any repository's code
  with a mutation-probe proof; corpus-check, which audits coherence; and
  docket-prune, which tries definitions without editing.
argument-hint: "[tighten] [paths or globs, default: src/user/claude_code src/user/docket; tighten: skills/**/*.md agents/*.md]"
---

# simplify-corpus

Run this skill inline in the main session. You resolve the targets, launch
the workflow, land what it accepted one file at a time, run the gates, and
commit. The workflow never writes to the repository; every candidate lands
here.

**Two modes share one pass.** A first argument of `tighten` selects tighten
mode, and the arguments after it are its paths; otherwise every argument is
a simplify-mode path. Simplify mode applies the built-in simplify skill's
review (reuse, simplification, efficiency, altitude) to any file kind.
Tighten mode rewrites Markdown prose for concision under CLAUDE.md's prose
rules and never touches code. The sections below name each place the modes
differ; everything else applies to both.

**Run it under `/loop` for repeated passes.** `simplify-corpus` has no watch
loop of its own: `/loop /simplify-corpus [tighten]` (self-pacing) or
`/loop 30m /simplify-corpus [tighten] <paths>` supplies the recurring
wake-up, and each firing re-enters this skill from §1. Invoked bare with no
loop wrapping it, do one pass and say so; there will be no next tick.

## Scope

`$ARGUMENTS` optionally names repo-relative paths or globs, after the
`tighten` word in tighten mode.

### Simplify mode

Bare invocation targets every tracked file under `src/user/claude_code` and
`src/user/docket`, both trees always. That includes skill, agent, and
reference Markdown, `CLAUDE.md` and `references/working-agreement.md`,
`workflows/*.js`, `skills/*/scripts`, `statusline.sh`, `settings.rs`, and
under docket `bin/doc-record`, `config/README.md`, `config/policy.toml`,
contracts, fragments, and workflow TOML.

Never target, and drop from any argument that matches:

- `src/user/claude_code/hooks/`, every file: the guard hooks are a
  permission and sandbox boundary that changes only by the operator's
  hand.
- `src/user/docket/config/schemas/`: every `<name>@<version>.json` is
  frozen bytes once registered, and the legitimate change is a new
  version file, which is design work for `docket-refit`.
- Data files, which are neither code nor prose: `allowed_signers`, and
  every `*.json` under the trees (fixtures, evals, inventories). The
  workflow rejects any that reach it.

Two target classes carry landing rules of their own, both in §3:
`settings.rs` lands only after the operator confirms its candidate, and
versioned docket files (contracts, fragments, workflow TOML) land only with
the version bump `frozen-drift-check` demands.

### Tighten mode

Without paths, tighten mode targets the default corpus under
`src/user/claude_code`: `skills/**/*.md` and `agents/*.md`.

Only Markdown prose is ever rewritten. Never target, and drop from any
argument that matches:

- `src/user/claude_code/CLAUDE.md` and
  `src/user/claude_code/references/working-agreement.md`: the operator's
  own working agreement, owned outside this corpus's style authority, and
  the source of the rules this mode enforces.
- Code and configuration: `workflows/*.js`, `hooks/`, `settings.rs`,
  `statusline.sh`, `allowed_signers`, and everything under
  `src/user/docket`. Frozen contracts and fragments carry versions and
  belong to `docket-refit`.

Inside a file the workflow diffs frontmatter, fenced blocks at any
indentation, inline code, headings, section and line references,
double-quoted spans, relative links, and HTML comments between original
and candidate, and rejects a candidate where any differs.

Never run `just activate`. Never push.

## 1. Each pass

1. Resolve targets. Run `git ls-files -- <paths>` from the repository root
   over the mode's paths (or its default targets), keep only `.md` files in
   tighten mode, and apply the mode's Scope exclusions. Only tracked files
   are ever candidates, so an untracked file another session is drafting is
   never rewritten and the revert in §3 always has a committed state to
   return to. No files means nothing to do: report it and stop (under
   self-paced `/loop`, arm the idle wakeup in §5 first).
2. Require a clean tree. Run `git status --porcelain` and stop if a tracked
   file is modified or staged: any tracked file in simplify mode, target or
   not, and any target in tighten mode. A pass lands as one commit, and
   pre-existing edits to a target would be swept into it or lost by the
   revert in §3. Simplify mode checks the whole tree because the built-in
   simplify skill reviews the current diff, so a dirty tree is what a
   simplifier following it could edit. Report the dirty paths instead.
3. Record the gates' baseline. Run `just crossref-check` and
   `just prose-gates` from the repository root, plus
   `just frozen-drift-check` in simplify mode, and keep their failure
   lines, if any. `frozen-drift-check` exits 2 without `docket`, `jq`, or
   `shasum`; record that as "gate unavailable" and, in that case, treat
   every versioned docket file as excluded for this pass, since nothing
   could prove its bump. Failures already present before the pass belong
   to other work; §3 compares against this list so the pass is charged
   only for what it introduced.
4. Choose a scratch directory under `$TMPDIR`, empty and unique to this
   pass, for candidate files (for example
   `$TMPDIR/simplify-corpus/pass-<n>`, or `$TMPDIR/tighten/pass-<n>` in
   tighten mode, incrementing `<n>` from earlier passes in this session).
   Candidates mirror repo-relative paths under it.

## 2. Run the workflow

Each mode has its own workflow script: `simplify-corpus.js` for simplify
mode, `tighten.js` for tighten mode. Invoke it by `scriptPath`, always, at
the installed path `~/.claude/workflows/<script>`, expanding `~` to a
literal absolute path yourself first. The Workflow tool does not expand `~`
and resolves a relative path against the target repo's cwd, not the
dotfiles source tree. The installed copy is the only one the tool may
launch and the only one guaranteed to match this session's build. A missing
installed file means the corpus was never activated after this skill was
added: report that, don't launch the source copy instead.

```
Workflow({ scriptPath: "<absolute installed path to the mode's script>", args: { files: [<repo-relative paths>], scratchDir: "<absolute scratch path>", pass: <n> } })
```

**Simplify mode.** The workflow classifies each file by kind and runs one
simplifier per file, which copies the file into the scratch mirror, invokes
the built-in simplify skill on the copy where the Skill tool is available
and applies its four criteria directly otherwise, or returns
`changed=false` for a file already simple. A mechanical check then runs the
kind's syntax gate, diffs protected spans for Markdown (a candidate may
delete protected content but never add or alter it), reads the version of a
versioned docket file, and measures both files; a candidate that fails a
gate, did not shrink, or lacks a strictly greater version is rejected in
code. Survivors face three refuters, each leading from a different angle
(behavior or meaning, the caller or reader, churn), and a candidate needs
two upholds to be accepted. The return carries `accepted`, each with its
`file`, `kind`, `candidate` path, `confirm` and `versioned` flags, byte and
line counts, and vote tally; `rejected`, each with its reason;
`unchanged`; and a one-line `summary`.

**Tighten mode.** The workflow runs one rewriter per file, which copies the
file into the scratch mirror and edits the copy in place, or returns
`changed=false` for a file already tight. A mechanical check then diffs
every protected span between original and candidate and measures both; a
candidate that changed a protected span or did not shrink is rejected in
code. Survivors face three refuters, each leading from a different angle
(meaning, reader, churn), and a candidate needs two upholds to be accepted.
The return carries `accepted`, each with its `file`, `candidate` path, byte
and line counts, and vote tally; `rejected`, each with its reason;
`unchanged`; and a one-line `summary`.

If the workflow throws or returns nothing, say so and stop. Do not
substitute a manual rewrite as if it satisfied the step.

## 3. Land accepted candidates

Separate the accepted list first; only simplify mode returns `confirm`:

- **`confirm: true` (settings.rs).** Never landed by a `/loop` tick:
  report the candidate path and its summary and leave it for the operator.
  Under bare invocation, show the operator `diff -u <file> <candidate>`
  and ask, with `AskUserQuestion`, whether to land it; land it only on a
  yes.
- **Everything else** lands now.

Copy each candidate to land over its file serially, in this session, in
the order returned:

```bash
cp "<candidate>" "<file>"
```

When the file is a docket workflow TOML, also add the entry for its new
version at the top of `src/user/docket/config/changelogs/<name>.md`, under
a `## <version>` heading, from the candidate's summary; the TOML carries no
version comment.

Then run the gates from the repository root and compare their failure
lines with the baseline from §1:

- always: `just crossref-check` and `just prose-gates`;
- in simplify mode, also:
  - `just frozen-drift-check` (when it was available at baseline);
  - when a `workflows/*.js` file landed: `bash tests/workflow-module-parse.test.sh`;
  - when a skill file landed: `just doc-validate`;
  - when a contract, fragment, or docket workflow TOML landed:
    `bash tests/contract-corpus.test.sh`, `bash tests/contract-includes.test.sh`,
    and `bash tests/contract-cluster-keys.test.sh`, the suites that pin
    clauses, includes, and key names a structural cut can remove;
  - when `settings.rs` landed: `just self-hygiene` and `just tests`;
  - for every landed file: each suite under `tests/` whose text names the
    file's basename, found with `grep -l`.

A line absent from the baseline that names a landed file, or the skill it
belongs to, is this pass's breakage: a dead anchor, a renamed reference the
mechanical check could not see, a broken caller the refuters missed, a
version the drift check rejects, or a sentence a guard suite pins verbatim,
which no rewording may touch. Revert that file to its committed state with
`git checkout -- <file>`, drop it from the accepted list with the failure
line as its reason, and rerun the gates. At most two rounds; if new
failures remain, revert every file this pass landed, report the failure
lines, and stop. Baseline failures, and new failures naming files this pass
did not land, are reported and never acted on; the revert touches only
files this pass landed. A pinned sentence changes only in a commit that
re-anchors its test in the same change, which is never this skill's.

Nothing accepted, or everything reverted, means the pass landed nothing.
Skip §4 and go to §5.

## 4. Commit

Invoke the `commit` skill scoped to the landed paths, including any
changelog entry written in §3
(`Skill({skill: "commit", args: "<landed paths>"})`): one commit cycle per
pass, never batched across passes. Then report the pass in a few lines:
the mode and pass number, files landed with their line deltas and, for
versioned docket files, the version bump, the commit hash, files rejected
with their reasons, files unchanged, and any settings.rs candidate awaiting
the operator.

A landed contract, fragment, or workflow TOML reaches the engine only
after the operator runs `just activate` and `docket-reconcile`; say so
when one landed.

## 5. Next pass

A pass that landed edits is evidence the corpus can shrink further: another
pass may find more, and a pass that finds nothing is what stops the loop.

- **Bare invocation:** one pass. Say the pass is done and stop.
- **Self-paced `/loop /simplify-corpus [tighten]`:**
  - Landed edits: loop back to §1 immediately on the same mode and targets,
    up to three consecutive passes per tick, then arm
    `ScheduleWakeup({delaySeconds: 300, noop: false, prompt: "<the loop
    prompt verbatim>", reason: "simplify-corpus <mode> landed edits;
    resuming passes"})` so the operator can read the commits between
    bursts.
  - Landed nothing: the corpus is simple, or tight, for now. Arm
    `ScheduleWakeup({delaySeconds: 1800, noop: true, prompt: "<the loop
    prompt verbatim>", reason: "simplify-corpus <mode> found nothing to
    shrink"})` and stop. Send no "nothing changed" message; a quiet tick
    is not an event.
- **Explicit interval (`/loop 30m /simplify-corpus [tighten]`):** one pass;
  the cron firing supplies the next tick, so stop.

The loop ends when the operator stops it (`ScheduleWakeup({stop: true})`
under self-pacing, or telling you to stop) or ends the `/loop`. A pass that
lands nothing is a rest, not a finish: later edits to the corpus give the
next tick new files to simplify or prose to tighten.

## Report

State the mode, what landed, what was rejected and why, what was unchanged,
what awaits the operator's confirmation, and the commit hash. Do not claim
`just activate` ran; it didn't, and the installed skills under `~/.claude`
lag this checkout until the operator runs it.
