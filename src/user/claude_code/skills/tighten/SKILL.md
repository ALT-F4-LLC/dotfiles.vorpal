---
name: tighten
description: >-
  Use on "tighten", "/tighten", "tighten the prose", "make this more
  concise", "simplify the prose in", "cut the filler", or to keep the
  corpus's prose tight under /loop (for example `/loop /tighten`). Rewrites
  Markdown prose for concision under CLAUDE.md's prose rules through a
  workflow that verifies every candidate mechanically (frontmatter, code,
  headings, anchors byte-equal) and adversarially (three refuters, majority
  uphold) before this session lands it, checks cross-references, and commits
  each pass. Bare invocation does one pass over the named paths or the
  default corpus; under /loop it keeps passing until nothing shrinks, then
  rests. Prose only, never code; distinct from simplify, which cleans code,
  and corpus-check, which audits coherence without rewriting.
argument-hint: "[paths or globs, default: skills/**/*.md agents/*.md]"
model: fable
---

# tighten

Run this skill inline in the main session. You resolve the targets, launch
the workflow, land what it accepted one file at a time, and commit. The
workflow never writes to the repository; every candidate lands here.

**Run it under `/loop` for repeated passes.** `tighten` has no watch loop
of its own: `/loop /tighten` (self-pacing) or `/loop 30m /tighten <paths>`
supplies the recurring wake-up, and each firing re-enters this skill from
§1. Invoked bare with no loop wrapping it, do one pass and say so; there
will be no next tick.

## Scope

`$ARGUMENTS` optionally names repo-relative paths or globs. Bare
invocation targets the default corpus under `src/user/claude_code`:
`skills/**/*.md` and `agents/*.md`.

Only Markdown prose is ever rewritten. Never target, and drop from any
argument that matches:

- `src/user/claude_code/CLAUDE.md` and
  `src/user/claude_code/references/working-agreement.md`: the operator's
  own working agreement, owned outside this corpus's style authority, and
  the source of the rules this skill enforces.
- Code and configuration: `workflows/*.js`, `hooks/`, `settings.rs`,
  `statusline.sh`, `allowed_signers`, and everything under
  `src/user/docket`. Frozen contracts and fragments carry versions and
  belong to `docket-refit`.

Inside a file the workflow diffs frontmatter, fenced blocks at any
indentation, inline code, headings, section and line references,
double-quoted spans, relative links, and HTML comments between original
and candidate, and rejects a candidate where any differs. Never run
`just activate`.

## 1. Each pass

1. Resolve targets. Run `git ls-files -- <globs>` from the repository
   root over `$ARGUMENTS` (or the default globs), keep only `.md` files,
   and apply the Scope exclusions. Only tracked files are ever candidates,
   so an untracked file another session is drafting is never rewritten and
   the revert in §3 always has a committed state to return to. No files
   means nothing to do: report it and stop (under self-paced `/loop`, arm
   the idle wakeup in §5 first).
2. Require a clean starting point. Run `git status --porcelain -- <targets>`
   and stop if any target is modified or staged: a pass lands as one
   commit, and pre-existing edits would be swept into it or lost by the
   revert in §3. Report the dirty paths instead.
3. Record the gate's baseline. Run `just crossref-check` from the
   repository root and keep its failure lines, if any. Failures already
   present before the pass belong to other work; §3 compares against this
   list so the pass is charged only for what it introduced.
4. Choose a scratch directory under `$TMPDIR`, empty and unique to this
   pass, for candidate files (for example
   `$TMPDIR/tighten/pass-<n>`, incrementing `<n>` from earlier passes in
   this session). Candidates mirror repo-relative paths under it.

## 2. Run the workflow

Invoke by `scriptPath`, always, at the installed path
`~/.claude/workflows/tighten.js`, expanding `~` to a literal absolute path
yourself first. The Workflow tool does not expand `~` and resolves a
relative path against the target repo's cwd, not the dotfiles source tree.
The installed copy is the only one the tool may launch and the only one
guaranteed to match this session's build. A missing installed file means
the corpus was never activated after this skill was added: report that,
don't launch the source copy instead.

```
Workflow({ scriptPath: "<absolute installed path to tighten.js>", args: { files: [<repo-relative paths>], scratchDir: "<absolute scratch path>", pass: <n> } })
```

The workflow runs one rewriter per file, which copies the file into the
scratch mirror and edits the copy in place, or returns `changed=false` for
a file already tight. A mechanical check then diffs every protected span
between original and candidate and measures both; a candidate that changed
a protected span or did not shrink is rejected in code. Survivors face three refuters, each
leading from a different angle (meaning, reader, churn), and a candidate
needs two upholds to be accepted. The return carries `accepted`, each with
its `file`, `candidate` path, byte and line counts, and vote tally;
`rejected`, each with its reason; `unchanged`; and a one-line `summary`.

If the workflow throws or returns nothing, say so and stop. Do not
substitute a manual rewrite as if it satisfied the step.

## 3. Land accepted candidates

Copy each accepted candidate over its file serially, in this session, in
the order returned:

```bash
cp "<candidate>" "<file>"
```

Then run `just crossref-check` from the repository root and compare its
failure lines with the baseline from §1. A line absent from the baseline
that names a landed file is this pass's breakage (a dead anchor, a renamed
reference the mechanical check could not see). Revert that file to its
committed state with `git checkout -- <file>`, drop it from the accepted
list with the failure line as its reason, and rerun the gate. At most two
rounds; if new failures remain, revert every file this pass landed,
report the failure lines, and stop. Baseline failures, and new failures
naming files this pass did not land, are reported and never acted on;
the revert touches only files this pass landed.

Nothing accepted, or everything reverted, means the pass landed nothing.
Skip §4 and go to §5.

## 4. Commit

Invoke the `commit` skill scoped to the landed paths
(`Skill({skill: "commit", args: "<landed paths>"})`): one commit cycle per
pass, never batched across passes. Then report the pass in a few lines:
the pass number, files landed with their line deltas, the commit hash,
files rejected with their reasons, and files unchanged.

## 5. Next pass

A pass that landed edits is evidence the corpus can shrink further: another
pass may find more, and a pass that finds nothing is what stops the loop.

- **Bare invocation:** one pass. Say the pass is done and stop.
- **Self-paced `/loop /tighten`:**
  - Landed edits: loop back to §1 immediately on the same targets, up to
    three consecutive passes per tick, then arm
    `ScheduleWakeup({delaySeconds: 300, noop: false, prompt: "<the loop
    prompt verbatim>", reason: "tighten landed edits; resuming passes"})`
    so the operator can read the commits between bursts.
  - Landed nothing: the corpus is tight for now. Arm
    `ScheduleWakeup({delaySeconds: 1800, noop: true, prompt: "<the loop
    prompt verbatim>", reason: "tighten found nothing to shrink"})` and
    stop. Send no "nothing changed" message; a quiet tick is not an event.
- **Explicit interval (`/loop 30m /tighten`):** one pass; the cron firing
  supplies the next tick, so stop.

The loop ends when the operator stops it (`ScheduleWakeup({stop: true})`
under self-pacing, or telling you to stop) or ends the `/loop`. A pass that
lands nothing is a rest, not a finish: later edits to the corpus give the
next tick new prose to tighten.

## Report

State what landed, what was rejected and why, what was unchanged, and the
commit hash. Do not claim `just activate` ran; it didn't, and the installed
skills under `~/.claude` lag this checkout until the operator runs it.
