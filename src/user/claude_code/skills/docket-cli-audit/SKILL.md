---
name: docket-cli-audit
description: >-
  Use after a docket upgrade, or on "audit the docket CLI", "/docket-cli-audit",
  "is the docket prose still right", "did the docket upgrade break the docs",
  or "check src/user against the installed docket". Probes the installed
  binary's help surface and, against a throwaway store, every command's exit
  codes, messages and both JSON dialects, then audits every tracked file in
  the repository that names a docket command against that evidence through a
  multi-agent workflow. Files the drift as Docket issues, one per file plus
  one for the refreshed evidence; never edits the checkout. Paths or globs
  narrow the audit. Distinct from corpus-check, which checks the corpus
  against itself and never consults the binary.
argument-hint: "[--no-sweep] [paths or globs, default: every tracked file naming a docket command]"
---

# docket-cli-audit

Run this skill inline in the main session. You probe the binary, launch the
audit, and file the issues. The checkout is read-only: every probe writes
under scratch, and the only writes outside scratch are Docket issues. A fix
is an issue's work, never this skill's.

**Automation first is the primary goal of every remedy.** Per the docket
skill's [automation reference](../docket/references/automation.md), drift
a program could have caught gets a remedy on the highest rung of its ladder
that fits (a sweep scenario row, a fixture assertion, a `crossref-check`
rule) beside the prose fix, so the next upgrade finds it without a person
reading. An issue names that rung in its Remedy.

## Scope

Evidence comes from the `docket` binary on PATH and nothing else. Two probes
produce it, both read-only against the operator's own state:

- **Help surface**: `skills/docket/scripts/cli_inventory.py` records every
  command path, alias, usage line, flag, value type and default from `--help`
  and `--version`. The committed copy is
  `skills/docket/references/cli-inventory.json`; this skill writes the fresh
  one under scratch with `--inventory`.
- **Runtime sweep**: `scripts/cli_sweep.py` drives every command the
  inventory lists, in the order `references/sweep-scenario.json` scripts,
  against a scratch store, and records exit code, human output and both JSON
  dialects (`--json` v1, `--format json` v2). The committed copy is
  `references/cli-fixtures.json`; this skill writes the fresh one under
  scratch with `--fixtures`. It runs with `HOME`, every `XDG_*_HOME` and
  the git config pointed at a scratch directory, refuses to continue if the
  store it opened lives anywhere else, keeps the trust roster empty for every
  run- and step-level verb so no gate can execute, and refuses `trust probe`,
  `--watch`, `--follow` and `--interval` in code. The scratch directory is
  removed afterwards, including on failure. It also sets `NO_COLOR=1` and
  `TERM=dumb`, which strip the status glyphs (`✔`, `✘`) from human output.
  A hook runs without them and sees `✔ allowed`, so a fixture's missing glyph
  is not evidence against prose that quotes one.

Prose in scope is every tracked file in the repository that names a docket
command, found by grep at run time (step 4) over the whole checkout, not a
fixed list or a tree. Comments and strings in `.rs`, `.js`, `.sh`, `.jq`,
`.awk` and `.toml` files count: a permission row naming a verb, a hook
parsing an output shape, a script passing a flag. `tests/*.test.sh` and
`.docket/bin/*` are prose in scope like any other file, since a test that
asserts a removed flag or a gate script that calls one is exactly the drift
the audit exists to catch; a repository-wide grep reads about half again as
many files as a `src/user` grep did, and that cost is the coverage.

Skipped, because the audit cannot apply to them: the generated
`cli-inventory.json` and `cli-fixtures.json` and the hand-authored
`sweep-scenario.json`, which are the evidence itself, not prose about it.
Nothing else is skipped.

Report-only, read and audited but never filed as a remedy:
`src/user/claude_code/CLAUDE.md` and
`src/user/claude_code/references/working-agreement.md` (the operator's own
charter) and every file under `src/user/claude_code/hooks/` (a permission and
sandbox boundary that changes only by the operator's hand). Never run
`just activate`. Never point a probe at `~/.docket` or `~/.config/docket`.

`$ARGUMENTS` only narrows. Repo-relative paths or globs limit step 4's grep
to the tracked files under them; with none, the grep covers every tracked
file. `--no-sweep` skips step 2 and audits against the fixtures already
committed. Use it only when the committed fixtures carry the installed
binary's version; the report must say the sweep was skipped.

Confirm the Docket project bound to this checkout before step 1, since cwd
picks the project. If no project answers, stop and say so; do not register
one.

## 1. Probe the help surface

From the repository root, with `$SCRATCH` an empty directory under
`$TMPDIR` unique to this audit:

```bash
python3 src/user/claude_code/skills/docket/scripts/cli_inventory.py --check
```

Exit 0 means the committed inventory already matches the installed binary.
Exit 1 prints a unified diff of the committed inventory against the installed
binary: save it to `$SCRATCH/inventory-diff.patch` and read it, since every
hunk is a mechanical finding candidate (an added or removed command, flag,
alias or default). Note the committed and installed `binary_version` lines.
On exit 0 or 1, write the fresh inventory to scratch, since later steps
read it either way:

```bash
python3 src/user/claude_code/skills/docket/scripts/cli_inventory.py --inventory "$SCRATCH/cli-inventory.json" --write
```

Exit 2 means a probe failed or the help output could not be parsed; stop and
report it, since the rest of the audit has no surface to check against.

## 2. Run the runtime sweep

Skip this step under `--no-sweep`; steps 3 and 5 then read the committed
fixtures.

The sweep refuses to run when its scenario no longer matches the inventory
(`collect` checks coverage first and exits 2 on an `uncovered:`, `stale
skip:`, or `not in inventory:` line, or on an `expect_exit` mismatch), and
that is exactly the state an upgrade leaves. So the scenario is repaired on
a scratch copy first, against the fresh inventory, never the committed one:

```bash
cp src/user/claude_code/skills/docket-cli-audit/references/sweep-scenario.json "$SCRATCH/sweep-scenario.json"
python3 src/user/claude_code/skills/docket-cli-audit/scripts/cli_sweep.py --coverage --scenario "$SCRATCH/sweep-scenario.json" --inventory "$SCRATCH/cli-inventory.json"
```

The scenario must exercise every command the fresh inventory lists or skip
it with a reason. For each `uncovered:` line, add a step to the scratch
scenario (read the command's `--help`, place engine verbs inside the run
they belong to, and place any `trust add` after every engine step), or add a
`skipped` row with a reason a reader would accept, such as a verb that
executes trusted commands or blocks on a terminal. A `stale skip:` line means
a skip row now shadows a scripted step; delete the row. A `not in inventory:`
line means the upstream removed a command the scenario still drives; delete
the step and record the removal as a mechanical finding. Rerun `--coverage`
until it exits 0, then save the difference for the evidence issue:

```bash
diff -u src/user/claude_code/skills/docket-cli-audit/references/sweep-scenario.json "$SCRATCH/sweep-scenario.json" > "$SCRATCH/scenario.patch"
```

Then check the committed fixtures against the installed binary, with the
repaired scenario:

```bash
python3 src/user/claude_code/skills/docket-cli-audit/scripts/cli_sweep.py --check --scenario "$SCRATCH/sweep-scenario.json" --inventory "$SCRATCH/cli-inventory.json"
```

Exit 0 means the committed fixtures match the installed binary. Exit 1 prints
the unified diff of committed fixtures against installed behavior: save it as
`$SCRATCH/fixtures-diff.patch` and read it, since each changed record is a
semantic finding candidate (a new exit code, a renamed `data` key, a reworded
message). Exit 2 is a scenario failure: a step with `expect_exit` got a
different code, a capture path no longer resolves, or an isolation assertion
fired. For the first two, fix the scratch scenario, extend `scenario.patch`,
and rerun. For an isolation failure stop immediately and report the message
verbatim, since the script refused to touch a store outside its scratch root.

Write the fresh fixtures to scratch once the sweep completes:

```bash
python3 src/user/claude_code/skills/docket-cli-audit/scripts/cli_sweep.py --scenario "$SCRATCH/sweep-scenario.json" --inventory "$SCRATCH/cli-inventory.json" --fixtures "$SCRATCH/cli-fixtures.json" --write
```

Run `--check` once more with the same three paths. A second diff means the
output is nondeterministic for some record: the evidence issue's remedy
extends the normalizer in `cli_sweep.py` (timestamps, hashes, relative ages,
padded columns) or marks the step `"unordered": true` when only the order of
same-instant rows varies. Name the record in the issue.

## 3. Build the evidence bundle

Write the digest to scratch from the fresh evidence. Under `--no-sweep`, set
`FIXTURES` to the committed
`src/user/claude_code/skills/docket-cli-audit/references/cli-fixtures.json`;
otherwise to `$SCRATCH/cli-fixtures.json`:

```bash
python3 src/user/claude_code/skills/docket-cli-audit/scripts/cli_sweep.py --digest --inventory "$SCRATCH/cli-inventory.json" --fixtures "$FIXTURES" > "$SCRATCH/digest.md"
```

It lists, per command, every record's id, mode, exit code and the top-level
shape of its output. Readers start there and grep the fixtures JSON for the
record they need.

## 4. Discover the files

From the repository root, over every tracked file (or the tracked files
under the paths `$ARGUMENTS` named, passed after `--`):

```bash
git ls-files -z -- . | xargs -0 grep -lE '(^|[^A-Za-z0-9_/.-])docket (--|[a-z])'
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
      digest: "<$SCRATCH>/digest.md",
      inventoryDiff: "<$SCRATCH>/inventory-diff.patch or ''>",
      fixturesDiff: "<$SCRATCH>/fixtures-diff.patch or ''>",
      inventory: "<$SCRATCH>/cli-inventory.json",
      fixtures: "<the same $FIXTURES path step 3 used>",
      binaryVersion: "<docket --version line>",
      previousVersion: "<binary_version the committed inventory held>"
    },
    protectedFiles: ["src/user/claude_code/CLAUDE.md", "src/user/claude_code/references/working-agreement.md", <every step 4 path under src/user/claude_code/hooks/>]
  }
})
```

The workflow fans out one reader per file (sharded by line range over
roughly 1500 lines), runs a completeness critic that re-dispatches any file or
range nothing covered, then verifies every raw finding in per-file batches
through three refuters with distinct angles (quote, evidence, reading) under a
majority-uphold rule. It returns one JSON object. `findings` holds
survivors, each with its file, location, quote, claim, cited evidence, kind
(mechanical or semantic), severity and a proposed fix. `unverified` holds
findings the budget could not cover or that got no vote;
`verificationPartial` says whether that happened. `cleanNotes` lists
`{file, notes}` for each file whose docket claims all checked out.
`coverage` is `{complete, gapsFound, refilled, uncovered}`, each gap a
`{file, range, reason}`. When `verificationPartial` is true, report the
unverified findings by file as unaudited, never as clean; when
`coverage.complete` is false, name every `uncovered` span as unaudited.

If the workflow throws or returns nothing, say so and stop. Do not substitute
a smaller manual read as if it satisfied the step.

## 6. File the issues

The filing contract is docket-postmortem's
[worker-ready issue contract](../docket-postmortem/references/filing.md#worker-ready-issue-contract)
and [deduplicate before creating](../docket-postmortem/references/filing.md#deduplicate-before-creating)
sections as written, with these substitutions: the label is `cli-drift`, the
fingerprint line is `Drift fingerprint:`, and the priority and description
follow this section. Read both sections before the first write. The
dotfiles project owns every issue here, since the prose lives in this
checkout; a finding about the engine's own behavior goes to the Docket
engine project per that reference's routing section.

**Group the survivors.** One issue per independent outcome, as the sizing
reference requires: a finding a worker could deliver and verify without the
file's other findings is its own issue. Batch findings into one issue per file
only when they are wording-only `chore` drift on one surface sharing one
remedy, or one-for-one mechanical rewrites in one file that a single
verification covers. One more issue holds the evidence refresh whenever step
1 or 2 found a difference (see below).

**Classify each finding inside its issue** so the worker knows what the
fix may do:

- **Mechanical** (`kind: mechanical`): a command, flag, alias or default that
  the inventory renamed, removed or added. The remedy is a one-for-one
  rewrite. A mechanical finding in a protected file is reported in the
  summary, never filed.
- **Semantic** (`kind: semantic`): a described behavior, exit code, message,
  JSON field or shape that the fixtures contradict, or a wording change the
  fix implies. The remedy states the before and after and cites the fixture
  record or inventory hunk.
- **Needs a decision** (`needsOperatorDecision: true`, or any finding whose
  fix changes a rule rather than a description): file it as its own issue
  titled for the decision, with the options and a recommendation in the
  body, so the executing worker does not guess. A schema fix is always this
  kind.

A code change (a hook or workflow script passing a flag the binary no longer
takes, a permission row for a removed verb) is mechanical when the
replacement is one-for-one and semantic otherwise. The Remedy of an issue
that touches `src/user/docket/config` contracts, fragments or workflows names
the version bump `frozen-drift-check` demands and, for a workflow, the
changelog entry.

**The evidence issue** carries the regeneration, not the bytes:

- Remedy: refresh `skills/docket/references/cli-inventory.json` with
  `cli_inventory.py --write`, refresh
  `references/cli-fixtures.json` with `cli_sweep.py --write` (after the
  scenario changes this audit found), rewrite the inventory paragraph in
  `skills/docket/reference.md` (it names `cli-inventory.json` and states the
  refresh date, binary version and command count), and update any statement
  that quotes the old version verbatim.
- The scenario changes from step 2 (`uncovered`, `stale skip`, `not in
  inventory`, nondeterministic records), each named, with
  `$SCRATCH/scenario.patch` inline in the body so the worker applies the
  repaired scenario before regenerating the fixtures.
- Acceptance: `cli_inventory.py --check`, `cli_sweep.py --coverage`, and
  `cli_sweep.py --check` exit 0 on the committed files, then
  `bash tests/docket-cli-inventory.test.sh`,
  `bash tests/docket-cli-sweep.test.sh`, and `just secret-scan` pass. The
  fixtures file is committed, so a token or hash the normalizer missed would
  land in the repository.
- Paths (`-f`): the two evidence files, the scenario, `reference.md`, and
  `scripts/cli_sweep.py` when the remedy extends the normalizer. `--scope`
  is the `docket-cli-audit/` and `docket/` directories that hold those
  files.

**Priority and type.** A finding that breaks behavior (a hook, a permission
row, a script passing a removed flag) is a `bug` at `high`. Prose that tells
a worker the wrong command is a `task` at `medium`. Wording-only drift in
one file is a `chore` at `low`. The evidence issue is a `task` at `medium`.
A batched issue takes the type and priority of its highest-ranked finding.

**Fingerprint.** `docket-cli-audit/<repo-relative path>/<command or claim>/<remedy class>`
for a file issue; `docket-cli-audit/evidence/<installed binary_version>` for
the evidence issue. A file issue carries the lead finding's identity. The
binary version is in the evidence fingerprint only, so a repeated audit of
the same binary returns the same issue while a new upgrade files a new one.

**Idempotency key.** The key is the fingerprint, verbatim. A repeated create
with it returns the original issue, open or closed, so it covers retries and
repeat audits of unchanged drift. When the dedupe listing finds the finding
again under a closed issue without `wont-do`, that is a regression: follow
filing.md's new-regression convention, link the prior id in the body, and
append `/after-<prior issue id>` to the key so the create does not replay
the closed issue. A closed issue labelled `wont-do` files nothing; record its
id. A closed decision issue without `wont-do` records a chosen option: link
it and file nothing, since the option's work belongs in its own issue. Ask
in each decision issue that a leave-as-is answer close it with `wont-do`.

**Description:**

```text
[Only when the remedy touches a hook, a permission row, secrets handling, or
another security-sensitive surface, as the first line:] Security gate
required: this remedy touches <the relevant categories>.

Observed: the claim as written (file:line, minimal verbatim excerpt) and
the installed behavior that contradicts it.
Evidence: binary versions (committed and installed), the inventory hunk or
fixture record id, and exit code or output where material.
Countercheck: what the refuters tried and what was found.
Remedy: per finding, kind, the one-for-one rewrite or the before and after;
the automation rung; the version bump when a frozen file changes.
Acceptance: the check of resulting behavior and the failing variant it
rejects, plus the gates below.
Drift fingerprint: <identity>.
```

Acceptance for a file issue always includes `just crossref-check`,
`just frozen-drift-check`, `just doc-validate`, `just secret-scan`, and
`bash tests/crossref-check.test.sh`, plus `contract-corpus`,
`contract-includes` and `mutant-rule-crossref` from `tests/` when a file
under `src/user/docket/config` is among its paths. The worker applies a
file's fixes serially and reruns them, and a failure means a fix was wrong or
incomplete, not a stale suite.

When the session can launch agents, launch the `advisor` agent on the drafted
issue set before filing it, and fold its input in. File with `docket issue
create`, `-f`, `--scope`, `--size` and `--idempotency-key` set, no routing
label, no assignee; read each receipt back and record the id.

## 7. Report

State the binary versions before and after, what the help-surface diff and
the fixture diff contained, which scenario changes the audit found, what the
audit found and verified, every issue filed with its id and grade, every
finding attached to an existing issue instead of a duplicate, every finding
held with its reason, every protected-file finding, and every file or range
the workflow could not cover or verify. Say whether the sweep ran or
`--no-sweep` reused the committed fixtures. Say that no fixes were applied;
filed issues drain through `docket-groom` into a `docket-plan` and
`docket-run` execution or direct work. Do not claim `just activate` ran; the
installed corpus under `~/.claude` lags this checkout until the operator runs
it.
