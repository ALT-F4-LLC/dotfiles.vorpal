---
name: docket-reconcile
description: >-
  Use on "reconcile the workflows", "reconcile the schemas", "/reconcile",
  "make the registry match the corpus", "the workflows are out of date",
  "register the new workflow or schema versions", "deprecate the old
  workflows", or after any `just activate` that moved the corpus forward.
  Makes one Docket project's workflow and schema registries match the
  installed corpus exactly: registers missing versions, restores one retired
  by mistake, retires every version the corpus no longer declares, and
  reports orphaned workflow names, frozen-row conflicts, drifted sources,
  and dangling payload, fragment, or packet references it must not fix. Read-only until it prints a
  plan and the operator approves. Registry only; corpus authoring belongs to
  docket-refit.
---

# docket-reconcile

The corpus on disk is the authority. This skill makes one project's
registries say the same thing.

`just activate` moves `~/.docket/config/` forward but touches no registry: a
registry is rows in the store, the corpus is files, and nothing keeps them in
step. Run activation auto-registers what it binds, but only in the project it
runs in, and it never retires anything. A project quietly keeps whatever it
last registered, with stale rows looking healthy in `docket workflow list`
and `docket schema list`.

## What the corpus puts in a registry

The engine keeps exactly two registries, one per project: workflows and
schemas. Everything else in the corpus reaches a run another way:

| Corpus surface | How a run gets it | Reconciled here |
| --- | --- | --- |
| `workflows/*.toml` | registry row, bound at activation | yes |
| `schemas/<name>@<version>.json` | registry row, referenced by `payload` | yes |
| `contracts/`, `fragments/`, `policy.toml` | read from disk and pinned by hash at activation | no registry; the references to and from them are checked |
| `changelogs/`, `README.md`, `cut-ledger.json` | not read by the engine | no |

A contract, fragment, or `policy.toml` edit is live for the next activation
as soon as `just activate` installs it. A run already under way keeps the
bytes it pinned; `docket run verify-pins RUN-N` reports that drift, and it is
by design, not something to reconcile. Vote-rule thresholds
(`vote.rule.<name>.threshold`) are per-project store config that the corpus
names but does not declare; a missing one surfaces as an INVALID workflow
lint.

**The invariant you are establishing:**

- **Workflows, per name:** for every workflow name declared by a file in any
  root, the version that file declares is registered and binding, and every
  other registered version of that name is retired.
- **Schemas, per version:** the corpus carries several versions of one
  schema name at once (`findings@12` and `findings@13`), so the unit is
  `name@version`. Every schema file in any root is registered, in service,
  and hashes to its row's `source_sha256`. Every other registered,
  non-builtin schema version is retired.
- **References:** every `payload:` a contract declares names a schema file,
  every fragment a contract's `packet_includes` lists exists, and every
  packet path a binding workflow's steps pack exists, once per `fanout` seat
  for a fanout step. `workflow lint` checks none of these; a missing packet
  file refuses the run only at activation.
- **Sources:** every binding workflow row's `source_path` still hashes to
  its `source_sha256`, or activation refuses the run.

After a successful pass, the planner prints no actionable line and its
target counts equal the live counts in both registries.

**Automation first is the primary goal.** The plan is derived from the
corpus mechanically, never from judgment, and whatever it cannot resolve
mechanically (an orphaned workflow name, a frozen-row conflict, drift that
recurs after every activation) is reported with the remedy on the highest
rung of the docket skill's
[automation ladder](../docket/references/automation.md#the-automation-ladder)
that would stop it recurring, so reconciling needs a human less each time.
The approval before any registry write stays; it authorizes this pass.

**Not `docket-refit`.** You change registry rows only, never a workflow
TOML, a schema file, a contract, a version bump, or a definition; when the
corpus is what is wrong, stop and say so. Fixing it is `docket-refit`'s
contract.

## Cwd discipline — read this before running anything

Every docket registry verb resolves its project from the working directory.
Never `cd` out of the checkout you are reconciling; pass corpus files as
absolute paths instead. `workflow register`, `workflow deprecate`, `schema
register`, and `schema deprecate` take `--project <ref>` to write to another
project from here. From docket `nightly-209`, `workflow list` and `workflow
lint` take `--project <ref>` too. `schema list` does not, so the planner runs
every call with the target checkout as the child process's cwd (see Scope
below).

`~/.docket/config/` belongs to no project, so linting from inside it
resolves to whatever project the shell happens to sit in and can report a
missing schema or an unregistered `vote_rule` that isn't real. If a lint
reports either, suspect your cwd before you believe the finding: re-run
from the checkout with an absolute path. Only if it still fails is the
prerequisite genuinely absent. A missing corpus schema is a schema REGISTER
line in this skill's plan. A missing vote rule is `docket config set
vote.rule.<name>.threshold <n>`, scoped to this project, not `--global`,
unless the operator says every project should get it.

## Let the engine parse the TOML

Never `grep` a version out of a workflow file, and never hand-parse one. The
version line is bare today, but when it carried its changelog as a trailing
comment full of digits, piping `grep -m1 version` through a digit filter
reported `security-change@2525792` for `@25`. `docket workflow lint <file>
--json=v2` is the parser, and it is the same parse `docket workflow register`
runs:

```json
{"ok":true,"data":{"name":"docs-only","version":19,
 "sha256":"1b4969…","registration":"unchanged"},"message":"…"}
```

`registration` is the engine's own verdict on what a register would do:
`new`, `unchanged`, or a failure carrying `"code":"CONFLICT"` whose error
names the frozen `name@version` and both hashes. The engine decides the
workflow REGISTER / CONFLICT split, not a hash comparison in the planner.

One thing lint does not tell you: a registered-but-retired version still
lints `unchanged`, since retiring a row does not change its bytes. RESTORE is
read from `deprecated_at_ms` on the registry row, which the planner fetches
anyway.

A workflow file that fails lint for any other reason has no name the planner
can trust, so it is reported as INVALID and left out of the target binding
set entirely.

Schemas have no lint verb. A schema file's name is its declaration: the
`<name>@<version>` that `docket schema register` takes as its first argument.
The row's `source_sha256` is the sha256 of the registered file's bytes, so
the planner hashes the file and compares; a mismatch is a schema CONFLICT.
Rows marked `builtin` ship in the binary, cannot be retired, and are left
alone.

Packet paths and source drift also come from the engine's parse:
`docket workflow show <name>@<version> --json=v2` returns the parsed
`definition.steps`, each with its `executor` or `fanout` seats and its
`packet`, and a `source_status` whose `state` is `matches`, `drifted`,
`unreadable`, or `unchecked`. The planner reads these for each binding
corpus version, so it checks what the registry will bind, not a TOML reading
of its own. A workflow the plan will REGISTER has no row yet; its packet
paths are checked on the re-plan after it lands.

## Step 0 — survey (read-only)

When the dotfiles checkout is at hand, confirm the installed corpus is the
committed one before planning against it:

```bash
diff -rq -x .claude src/user/docket/config ~/.docket/config
```

Any difference means `just activate` is pending, and a plan made now
reconciles the registries to the previous corpus. Activate first, or report
the gap.

Then size the pass:

```bash
docket registry audit --json=v2
```

One call reports every project's drift against the shared corpus: `behind`
(the highest registered version of a name is below the corpus version) and
`orphaned` (no scanned file declares the name, with `retired` per name). Each
entry carries a `kind` of `workflow` or `schema`. Use it to tell the operator
how many projects are affected. It repairs nothing, and it does not replace
the planner, because it compares names, not versions:

- It misses a name the project never registered: a schema the corpus added
  after the project's last activation shows as neither behind nor orphaned.
- It misses a version the corpus removed while the name lives on: an old
  `findings` version stays in service after a newer one replaces its file.
- It misses an older workflow version still binding beside the current one.
- A corpus version retired by mistake may not show as `behind`.

It scans this invocation's roots, so a name another project declares in its
own `.docket/config/` reads as orphaned here.

## Step 1 — plan (read-only)

The planner is a script beside this file, so it is tested and never
retyped:

```bash
python3 ~/.claude/skills/docket-reconcile/scripts/reconcile_plan.py [CHECKOUT]
python3 ~/.claude/skills/docket-reconcile/scripts/reconcile_plan.py --all-projects [--summary]
```

With no argument it plans the project the cwd resolves to; a checkout
argument plans that project, running every docket call with the checkout as
its cwd while the shell stays where it is. `--all-projects` plans every
project in `docket project list`, reports a project whose checkout is
missing as SKIPPED, and refuses one whose checkout resolves to a different
prefix. `--summary` prints one line of action counts per project.
`--strict` exits 1 while any REGISTER, RESTORE, or DEPRECATE line remains.
Exit 2 means no plan: a registry read failed, or a listing came back
truncated, which would make a retired or registered row look absent.

It mutates nothing. It prints the actions in apply order and the target
counts, then stops. `just activate` runs it with `--all-projects --summary`
after installing the corpus, so drift is reported the moment it appears;
that report is the cue to run this skill.

Both listings read `--deprecated` rows. Without them, a retired row reads as
an unregistered one.

## Step 2 — read the plan before running it

**REGISTER** — the corpus is ahead. For a workflow, the engine already
called the file `new`; lint, then register anyway: the registry may have
moved between planning and approval, a definition that fails validation must
not reach it, and the lint is free. For a schema, no row holds that
`name@version`; registering compiles it as JSON Schema and refuses one that
does not compile.

**DEPRECATE** — a version the corpus no longer declares is still in service.
Retire it. Retirement is a filter, never a retraction: the row stays
registered and readable, `show` still emits the exact bytes, and any run that
already pinned it still resolves it and still completes. A retired workflow
stops binding; a retired schema stops accepting new `payload` references.
`schema deprecate` refuses, as `in-use`, a version that a live workflow still
names as a payload. That refusal is a reported outcome: it names a workflow
version that should itself have been retired, so re-plan after the workflow
DEPRECATE lines land.

**RESTORE** — the corpus version is registered but retired. For a workflow,
binding is falling through to something older; for a schema, a workflow
that references it will refuse to register. Re-registering the same bytes
reports success and changes nothing. `--restore` is the only verb that fixes
it.

**CONFLICT** — the registry holds this exact `name@version` with different
bytes than the file. For a workflow, the lint failed with `"code":"CONFLICT"`
and printed both hashes; for a schema, the file's sha256 differs from the
row's `source_sha256`. A registered `name@version` is frozen so a run that
pinned it cannot have the definition swapped underneath it. Stop; there is no
force flag worth reaching for. Someone edited the corpus file without a new
version: a `[pipeline].version` bump for a workflow, a new
`<name>@<version+1>.json` file for a schema. The fix is that change in
source, committed, then `just activate`, then reconcile again. Report it and
move on; one conflict does not block the rest.

**INVALID** — the file does not lint at all (bad TOML, a step rule it breaks,
a schema or `vote_rule` it references that is not registered here), or a
schema file is not named `<name>@<version>.json`. Suspect your cwd first
(above), then re-run the single lint by hand to read the whole error. A
workflow INVALID for a schema that a REGISTER line in the same plan adds is
the same fault reported twice: apply the schema line, then re-plan. A
genuinely broken definition is `docket-refit`'s to fix, in source; you
cannot register it and must not paper over it. The file contributes no name
to the target set while it fails, so a name it would have claimed can also
show up on an ORPHAN line.

**DANGLING** — a reference no corpus file answers: a contract's
`payload: <name>@<version>` that no schema file declares, a
`packet_includes` fragment that no root holds, or a packet path a binding
workflow step packs (per fanout seat) that no root holds. `workflow lint`
reads neither contracts nor packet paths, so the engine reports none of
these until a run hits them: a missing packet file refuses the whole
activation, and a dangling payload tells the executor to emit against a
schema no project can hold. The fix is in source (`docket-refit`).

**DRIFT** — `workflow show` reports the binding row's `source_status` as
`drifted` (the file at `source_path` holds different bytes) or `unreadable`.
Activation refuses a drifted source and warns on an unreadable one. A
drifted corpus file at a registered version is the CONFLICT fault seen from
the row side, with the same fix: a version bump in source. An unreadable
source usually means the row was registered from a path that no longer
exists; `just activate` and a re-plan tell you whether the corpus version
now registers from the installed path.

**ORPHAN** — a registered workflow name that no file in any root declares.
Cross-check with `docket workflow list --orphans`, the engine's own
filesystem verdict and cheaper to trust than the planner's. A retired orphan
is harmless and needs nothing. A live orphan can mean a renamed workflow left
every version of the old name binding, or that one issue's label matches two
workflows, one of which has not existed on disk for weeks. Retiring every
version of a name removes it from routing altogether, which is a routing
change: surface it to the operator and let them decide. Never fold it into
the approved batch on your own initiative. A schema version with no file is a
plain DEPRECATE, not an ORPHAN: retiring it changes no routing, and the
engine refuses it while any live workflow still depends on it.

When the advisor tool is available, call it on the plan before presenting
it for that decision.

## Step 3 — apply, then verify by assertion

Run the approved commands in the order the planner printed them: schema
REGISTER and RESTORE, then workflow REGISTER and RESTORE, then workflow
DEPRECATE, then schema DEPRECATE. A workflow's `payload` references must
resolve when it registers, and a schema cannot retire while a live workflow
still names it.

Then verify — do not eyeball a table, assert the invariant:

```bash
docket workflow list --limit 1000 --json=v2 | jq -r '
  if .data.truncated then error("listing truncated; raise --limit") else . end
  | .data.items as $items
  | ($items | group_by(.name) | map(select(length > 1) | {(.[0].name): (map(.version) | sort)}) | add) as $dupes
  | "names with >1 binding version: \($dupes // "none" | if . == "none" then . else tojson end)",
    "binding count: \($items | length)"'
docket schema list --limit 1000 --json=v2 | jq -r '
  if .data.truncated then error("listing truncated; raise --limit") else . end
  | "live schema versions: \([.data.items[] | select(.builtin | not)] | length)"'
```

Then re-run the planner with `--strict`; exit 0 means no `REGISTER`,
`RESTORE`, or `DEPRECATE` line remains. The binding count equals the
planner's workflow target, excluding any name under CONFLICT, and the live
schema count equals its schema target. `CONFLICT`, `INVALID`, `DANGLING`,
`DRIFT`, and `ORPHAN` lines are reported outcomes, not unfinished work; the
`action(s)` count includes them.
Any remaining actionable line means the pass did not finish; say so rather
than reporting success.

## Scope — one project unless told otherwise

A registry is per project and so is retirement. Everything above operates on
the project the cwd resolves to — the default, and the safe one.

Every register and deprecate verb takes `--project <ref>` (a prefix, name,
identity path, or row id) to write to one other project, and
`--all-projects`, which writes to every project in the store. Both report
each project's own outcome. The corpus drift this skill fixes is usually
store-wide, since `just activate` moves one shared corpus and every project
falls behind together, but sweeping every project is still an operator
decision: say how many are affected, then ask. Do not infer it from the drift
being shared.

For a multi-project pass, run the planner with `--all-projects`. It takes
each project's checkout from the `identity` field of `docket project list`,
plans it with that checkout as the cwd, and refuses a checkout that resolves
to a different prefix. Projects rarely carry the same actions: each one fell
behind at its own last activation. An action shared by every plan can run
once with `--all-projects`; `--all-projects` reports a project where there
was nothing to do as unchanged, not-registered, or already-deprecated, so a
line most plans share can also run that way. Run the rest per project with
`--project <prefix>`. Verify per project: run the Step 3 `jq` assertions in a
subshell per checkout (`(cd <identity> && docket workflow list …)`), re-run
the planner with `--all-projects --strict`, and expect `behind_total` 0 from
`docket registry audit`.

Validation is per target: a definition's `payload` and `vote_rule`
references resolve against the registry of the project being written to, so
the same bytes can be valid in one project and refused in the next for a
schema that does not exist there. Expect a mix of outcomes rather than one
verdict.

## Two roots, and one thing not verified

The planner reads a global root (`~/.docket/config/`) and an optional
repo-local one (`<repo>/.docket/config/`), the repo-local one winning a
workflow name declared in both. Activation refuses a workflow, schema, or
pinned file that two roots offer with different bytes, so a schema file in
both roots must be identical.

The workflow precedence is the planner's convention, not a verified engine
behavior. While no root declares a colliding name, the rule stays
unexercised. If you hit a name declared in both roots, confirm what the
engine binds before trusting the plan.
