---
name: corpus-check
description: Audit src/user/claude_code and src/user/docket/config for coherence and consistency — mechanical reference breakage plus semantic drift (contradictions, terminology, staleness) across skills, agents, contracts, fragments, workflows, policy, and schemas. Runs `just crossref-check` first, then a full multi-agent audit via the corpus-check workflow, then applies operator-confirmed fixes and reports the rest as open decisions. Read-only until the confirmation gate; never edits without it. Use after a batch of prose changes to either tree, or on "audit the corpus", "check corpus coherence", "/corpus-check", "did my prose edits break anything", or "is the skill/docket config still consistent".
argument-hint: "[since ref, e.g. main or a commit sha]"
model: fable
---

# corpus-check

Run this skill inline in the main session. It uses `AskUserQuestion` to
confirm fixes before landing them; do not delegate the confirmation gate or
the fix application to a subagent.

## Scope

Two trees, always both, whole-corpus (not diff-scoped — drift can predate
the working tree, the same reasoning `frozen-drift-check` uses):

- `src/user/claude_code`: `CLAUDE.md`, `skills/**/*.md`, `agents/*.md`,
  `workflows/*.js`.
- `src/user/docket/config`: `contracts/*.md`, `fragments/*.md`,
  `workflows/*.toml`, `policy.toml`, `schemas/*.json`, `README.md`.

Out of scope unless the operator explicitly widens it: `hooks/`,
`settings.rs`, `statusline.sh`, `allowed_signers`, `src/user/docket/bin`.
Never edit `fragments/prime-directive.md` — it is a verbatim copy of the
operator's own global `~/.claude/CLAUDE.md` charter, owned outside this
corpus; report drift there as an operator decision, never as a fix to apply.
Never run `just activate`.

`$ARGUMENTS` optionally names a git ref (branch or SHA). Pass it through as
the workflow's `sinceRef` arg (step 2) when given, else pass `null`. It is
informational context only, passed to every reading agent as a note about
what changed recently — it never skips or deprioritizes a file. The
workflow reads every file in full and runs every cross-boundary check
regardless of this value; drift a stale reference introduces is not
confined to files the diff touched.

## 1. Mechanical gate

Run `just crossref-check` first, from the repository root. This is fast,
free of judgment calls, and catches dead paths, dead relative links and
heading anchors, dead `/docket-*` references and skill names in a
description, schema references with no file on disk, undeclared workflow
executors, gate names with no `just` recipe or `PROJECT_GATES` row, bad
routing labels, and name/stem mismatches — read `.docket/bin/crossref-check`
if you need the exact rule set.

If it fails, read every failure line; these are unambiguous (a name either
resolves or it doesn't) and safe to fix directly, the same way you would fix
any other failing gate: no confirmation needed. Rerun the gate until it
passes before moving to the semantic audit — a mechanically broken corpus is
not a useful base for a judgment-driven audit.

## 2. Semantic audit

Invoke by `scriptPath`, always, at the installed path
`~/.claude/workflows/corpus-check.js` — but expand `~` to a literal absolute
path yourself first (`echo ~` or your session's known home). The Workflow
tool does not expand `~` and resolves a relative path against the target
repo's cwd, not the dotfiles source tree; the installed copy under
`~/.claude/workflows` is also the only one the tool is permitted to launch,
and the only one guaranteed to match this session's own build (the source
file under `src/user/claude_code/workflows/corpus-check.js` may have moved
since the last `just activate`). A missing installed file means the corpus
was never activated after this skill was added — report that, don't launch
the source copy instead.

```
Workflow({ scriptPath: "<absolute installed path to corpus-check.js>", args: {sinceRef: "<value or null>"} })
```

This fans out one agent per file over both trees (sharded by line range for
any file over roughly 1500 lines — `docket-run/SKILL.md`, `docket/reference.md`,
and `workflows/wave.js` are the known cases as of writing; the workflow
measures sizes itself at run time), runs a completeness pass
that re-dispatches any file or range nothing covered, then a cross-boundary
pass pairing claims one tree makes about the other, then verifies raw
findings in per-file batches (independent skeptics voting refute/uphold)
within an agent budget it fixes before the read fan-out. `findings` holds only
majority-survived findings, each carrying its file, location, quote,
counterpart, severity, and a proposed fix. `unverified` holds every finding the
budget could not cover or that received no vote; `verificationPartial`,
`verifiedCount`, and `unverifiedCount` say how far verification got, and
`coverageNote` states it in words. Read the summary line for what was refuted
and what could not be covered. When `verificationPartial` is true, report the
unverified findings by file as unaudited, never as clean, and do not report
exhaustive coverage the run itself flagged as partial.

If the workflow throws or returns nothing, say so and stop; do not
substitute a smaller manual read as if it satisfied this step.

## 3. Classify each returned finding

- **Mechanical** (should have been caught by step 1 but wasn't — a
  materially new check the audit surfaced): fix directly, and note it as a
  candidate rule for `.docket/bin/crossref-check` in your final report.
- **Unambiguous prose fix** (a stale claim, a dropped word, a terminology
  outlier against a clearly dominant term, a wording asymmetry between two
  files that both audits agree should read one way): stage it.
- **Needs operator decision** (two files each state a currently-correct but
  incompatible design choice, a deliberate-looking deviation with no
  recorded reason, a schema correction whose cascade is expensive, or
  anything the workflow itself flagged as unresolved): do not stage it.
  Carry it to the final report instead.

## 4. Confirm the staged batch before landing it

Frozen-file edits need a version bump, decided by which file changed:

- `contracts/*.md`, `fragments/*.md`: bump frontmatter `version:`. A changed
  body demands strictly greater; do not bump without a body change.
- `workflows/*.toml`: bump `[pipeline].version` and add a changelog line
  above the previous one, in this corpus's existing style.
- `schemas/*.json`: cannot be edited in place. A fix here means a new
  `<name>@<N+1>.json` plus a `payload =` update in every workflow step that
  declared the old version. Treat this as expensive by default — surface it
  as an operator-decision item rather than staging it, unless the operator
  has already asked for the schema cascade.
- `policy.toml`: no version field; free to edit directly, but keep its
  version-history comment block accurate.
- `skills/**/*.md`, `agents/*.md`, `CLAUDE.md`, `README.md`: no version
  field; free to edit directly.

Never spend a version bump on a comment that only flags an unresolved
question (a TODO, a "needs operator decision" note) with no other content
change — that pattern forces a second bump later for no reason. Land such
notes as an unversioned comment addition when the file is a policy/README
file, or fold the flag into your final report instead of touching a frozen
file at all.

Present the staged batch to the operator with `AskUserQuestion`: group by
file, show each fix's before/after and the version bump it implies. Options
are the whole batch, a filtered subset, or none. An ambiguous or skipped
response is not confirmation — do not land anything without an explicit
yes.

## 5. Apply and verify

Apply confirmed fixes one file at a time, serially, in this session — not
inside the workflow and not through parallel subagents, since audits
routinely overlap on the same file and a parallel writer would race or need
worktree isolation this task doesn't warrant. After every batch of edits:

```bash
just crossref-check
just frozen-drift-check
bash tests/contract-corpus.test.sh
bash tests/contract-includes.test.sh
bash tests/contract-cluster-keys.test.sh
bash tests/frozen-drift-check.test.sh
bash tests/crossref-check.test.sh
just doc-validate
bash tests/mutant-rule-crossref.test.sh
bash tests/ci-suite-wiring.test.sh
```

A failure here means a fix was wrong or incomplete, not that the suite is
stale — diagnose and correct before reporting completion.

## 6. Report

State plainly, without hedging: what the mechanical gate caught and fixed,
what the semantic audit found and verified, what landed with its version
bumps, and every item left for an operator decision with enough context to
act on it without re-reading this session. Name any file or line range the
workflow could not cover so "audited" never reads as "audited everything"
when it wasn't. Do not claim `just activate` was run; it wasn't, and the
installed corpus under `~/.docket/config` and `~/.claude` now lags this
checkout until the operator runs it.
