---
name: docket-cli-audit
description: >-
  Use after a docket upgrade, or on "audit the docket CLI", "/docket-cli-audit",
  "is the docket prose still right", "did the docket upgrade break the docs",
  or "check src/user against the installed docket". Probes the installed
  binary's help surface and, against a throwaway store, every command's exit
  codes, messages and both JSON dialects, then audits every file under src/user
  that names a docket command against that evidence through a multi-agent
  workflow. Mechanical drift (renamed or removed commands, flags, aliases,
  defaults) is fixed directly; behavior, shape and wording changes land only
  after operator confirmation. Distinct from corpus-check, which checks the
  corpus against itself and never consults the binary.
argument-hint: "[--no-sweep to reuse the recorded fixtures]"
model: fable
---

# docket-cli-audit

Run this skill inline in the main session. It uses `AskUserQuestion` to
confirm semantic fixes before landing them. Do not delegate the confirmation
gate or the fix application to a subagent.

## Scope

Evidence comes from the `docket` binary on PATH and nothing else. Two probes
produce it, both read-only against the operator's own state:

- **Help surface**: `skills/docket/scripts/cli_inventory.py` records every
  command path, alias, usage line, flag, value type and default from `--help`
  and `--version` into `skills/docket/references/cli-inventory.json`.
- **Runtime sweep**: `scripts/cli_sweep.py` drives every command the
  inventory lists, in the order `references/sweep-scenario.json` scripts,
  against a scratch store, and records exit code, human output and both JSON
  dialects (`--json` v1, `--format json` v2) into
  `references/cli-fixtures.json`. It runs with `HOME`, every `XDG_*_HOME` and
  the git config pointed at a scratch directory, refuses to continue if the
  store it opened lives anywhere else, keeps the trust roster empty for every
  run- and step-level verb so no gate can execute, and refuses `trust probe`,
  `--watch`, `--follow` and `--interval` in code. The scratch directory is
  removed afterwards, including on failure. It also sets `NO_COLOR=1` and
  `TERM=dumb`, which strip the status glyphs (`✔`, `✘`) from human output.
  A hook runs without them and sees `✔ allowed`, so a fixture's missing glyph
  is not evidence against prose that quotes one.

Prose in scope is every file under `src/user` that names a docket command,
found by grep at run time (step 4), not a fixed list. Comments and strings in
`.rs`, `.js`, `.sh` and `.toml` files count: a permission row naming a verb, a
hook parsing an output shape, a script passing a flag.

Report-only, never edited: `src/user/claude_code/CLAUDE.md` and
`src/user/claude_code/references/working-agreement.md` (the operator's own
charter). The three generated evidence files (`cli-inventory.json`,
`cli-fixtures.json`, `sweep-scenario.json`) are evidence, not prose, and are
excluded from the audit. Never run `just activate`. Never point a probe at
`~/.docket` or `~/.config/docket`.

`$ARGUMENTS` may carry `--no-sweep`: skip step 2 and audit against the
fixtures already recorded. Use it only when the recorded fixtures carry the
installed binary's version; the report must say the sweep was skipped.

## 1. Refresh the help surface

From the repository root:

```bash
python3 src/user/claude_code/skills/docket/scripts/cli_inventory.py --check
```

Exit 0 means the inventory already matches the installed binary. Exit 1
prints a unified diff of old inventory against installed binary: save it to
the scratchpad as `inventory-diff.patch` and read it, since every hunk is a
mechanical finding candidate (an added or removed command, flag, alias or
default). Note the old and new `binary_version` lines. Then refresh:

```bash
python3 src/user/claude_code/skills/docket/scripts/cli_inventory.py --write
```

Exit 2 means a probe failed or the help output could not be parsed; stop and
report it, since the rest of the audit has no surface to check against.

## 2. Run the runtime sweep

```bash
python3 src/user/claude_code/skills/docket-cli-audit/scripts/cli_sweep.py --coverage
```

The scenario must exercise every command the refreshed inventory lists or
skip it with a reason. A coverage failure after an upgrade is expected and is
itself a finding: for each `uncovered:` line, add a step to
`references/sweep-scenario.json` (read the command's `--help`; place engine
verbs inside the run they belong to, and any `trust add` after every engine
step), or add a `skipped` row with a reason a reader would accept, such as a
verb that executes trusted commands or blocks on a terminal. A `stale skip:`
line means a skip row now shadows a scripted step; delete the row. A `not in
inventory:` line means the upstream removed a command the scenario still
drives; delete the step and record the removal as a mechanical finding.

Then:

```bash
python3 src/user/claude_code/skills/docket-cli-audit/scripts/cli_sweep.py --check
```

Exit 0 means the recorded fixtures match the installed binary. Exit 1 prints
the unified diff of old fixtures against installed behavior: save it as
`fixtures-diff.patch` and read it, since each changed record is a semantic
finding candidate (a new exit code, a renamed `data` key, a reworded
message). Exit 2 is a scenario failure: a step with `expect_exit` got a
different code, a capture path no longer resolves, or an isolation assertion
fired. Fix the scenario for the first two; for an isolation failure stop
immediately and report the message verbatim, since the script refused to touch
a store outside its scratch root.

Refresh the fixtures once the sweep completes:

```bash
python3 src/user/claude_code/skills/docket-cli-audit/scripts/cli_sweep.py --write
```

Run `--check` once more. A second diff means the output is nondeterministic
for some record: extend the normalizer in `cli_sweep.py` (timestamps, hashes,
relative ages, padded columns) or mark the step `"unordered": true` when only
the order of same-instant rows varies. Do not commit fixtures that fail their
own check.

## 3. Build the evidence bundle

Write the digest to the scratchpad:

```bash
python3 src/user/claude_code/skills/docket-cli-audit/scripts/cli_sweep.py --digest > <scratchpad>/digest.md
```

It lists, per command, every record's id, mode, exit code and the top-level
shape of its output. Readers start there and grep the fixtures JSON for the
record they need.

## 4. Discover the files

From the repository root:

```bash
grep -rlE '(^|[^A-Za-z0-9_/.-])docket (--|[a-z])' src/user
```

Drop the three evidence files. Every remaining path is in scope, however
small its mention. Do not narrow the list by judgment; a one-line permission
row that names a removed verb is exactly what the audit exists to catch.

## 5. Audit the prose

Invoke by `scriptPath`, always, at the installed path
`~/.claude/workflows/docket-cli-audit.js`, expanding `~` to a literal absolute
path yourself first. The Workflow tool does not expand `~` and resolves a
relative path against the target repo's cwd. The installed copy is the only
one guaranteed to match this session's build; a missing installed file means
the corpus was never activated after this skill was added. Report that and
stop rather than launching the source copy.

```
Workflow({
  scriptPath: "<absolute installed path to docket-cli-audit.js>",
  args: {
    files: [<every path from step 4>],
    evidence: {
      digest: "<scratchpad>/digest.md",
      inventoryDiff: "<scratchpad>/inventory-diff.patch or ''>",
      fixturesDiff: "<scratchpad>/fixtures-diff.patch or ''>",
      inventory: "src/user/claude_code/skills/docket/references/cli-inventory.json",
      fixtures: "src/user/claude_code/skills/docket-cli-audit/references/cli-fixtures.json",
      binaryVersion: "<docket --version line>",
      previousVersion: "<binary_version the inventory held before step 1>"
    },
    protectedFiles: ["src/user/claude_code/CLAUDE.md", "src/user/claude_code/references/working-agreement.md"]
  }
})
```

The workflow fans out one reader per file (sharded by line range over
roughly 1500 lines), runs a completeness critic that re-dispatches any file or
range nothing covered, then verifies every raw finding in per-file batches
through three refuters with distinct angles (quote, evidence, reading) under a
majority-uphold rule. `findings` holds survivors, each with its file,
location, quote, claim, cited evidence, kind (mechanical or semantic),
severity and a proposed fix. `unverified` holds findings the budget could not
cover or that got no vote; `verificationPartial` says whether that happened.
`cleanNotes` lists files whose docket claims all checked out. When
`verificationPartial` is true, report the unverified findings by file as
unaudited, never as clean.

If the workflow throws or returns nothing, say so and stop. Do not substitute
a smaller manual read as if it satisfied the step.

## 6. Classify

Two edits are deterministic and land without a finding:

- The inventory paragraph in `skills/docket/reference.md` (the one that names
  `cli-inventory.json`) states the refresh date, binary version and command
  count; rewrite it from the refreshed inventory.
- Any statement elsewhere that quotes an inventory or fixture version
  verbatim (search for the old nightly tag) is updated the same way.

Then, for each surviving finding:

- **Mechanical** (`kind: mechanical`): a command, flag, alias or default that
  the inventory renamed, removed or added. Apply directly. A mechanical
  finding in a protected file is reported, not applied.
- **Semantic** (`kind: semantic`): a described behavior, exit code, message,
  JSON field or shape that the fixtures contradict, or a wording change the
  fix implies. Stage it. Do not land it without confirmation.
- **Needs operator decision** (`needsOperatorDecision: true`, or any finding
  whose fix changes a rule rather than a description): do not stage it; carry
  it to the report with enough context to act on.

A code change (a hook or workflow script passing a flag the binary no longer
takes, a permission row for a removed verb) is mechanical when the
replacement is one-for-one and semantic otherwise. Keep frozen-file rules in
mind: `src/user/docket/config` contracts, fragments and workflows carry
versions; a prose fix there follows the same bump rules corpus-check applies,
and a schema fix is an operator-decision item.

When the advisor tool is available, call it on the staged batch before
presenting it, and fold its input in with the rest of the classification.

Present the staged semantic batch with `AskUserQuestion`: group by file, show
each fix's before and after, and cite the fixture record or inventory hunk it
rests on. Options are the whole batch, a filtered subset, or none. An
ambiguous or skipped response is not confirmation.

## 7. Apply and verify

Apply fixes one file at a time, serially, in this session. After every batch
of edits:

```bash
just crossref-check
just frozen-drift-check
just doc-validate
just secret-scan
bash tests/docket-cli-inventory.test.sh
bash tests/docket-cli-sweep.test.sh
bash tests/crossref-check.test.sh
bash tests/ci-suite-wiring.test.sh
```

Run `contract-corpus`, `contract-includes` and `mutant-rule-crossref` from
`tests/` as well when a file under `src/user/docket/config` changed. A failure
means a fix was wrong or incomplete, not a stale suite. `secret-scan` matters
here specifically: the fixtures file is committed, and a token or hash the
normalizer missed would land in the repository.

## 8. Report

State the binary versions before and after, what the help-surface diff and
the fixture diff contained, how the scenario changed (new steps, new skips,
removed steps), what the audit found and verified, what landed (mechanical
directly, semantic after confirmation), every item left for an operator
decision, every protected-file finding, and every file or range the workflow
could not cover or verify. Say whether the sweep ran or `--no-sweep` reused
the recorded fixtures. Do not claim `just activate` ran; the installed corpus
under `~/.claude` lags this checkout until the operator runs it.
