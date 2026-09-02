---
name: reconcile
description: Make one Docket project's workflow registry match the installed file corpus exactly — register every version the corpus declares but the registry lacks, restore one that was retired by mistake, retire every other version of that name so the corpus file is the only thing binding, and report orphaned names and frozen-row conflicts it must not fix on its own. Use on "reconcile the workflows", "/reconcile", "make the registry match the corpus", "the workflows are out of date", "register the new workflow versions", "deprecate the old workflows", or after any `just activate` that moved the corpus forward. Read-only until it prints a plan and the operator approves it. Registry-only: it never edits a workflow TOML, and corpus authoring belongs to `refit`.
model: fable
---

# reconcile

The corpus on disk is the authority. This skill makes one project's workflow
registry say the same thing.

`just activate` moves `~/.docket/config/` forward. It does not touch any
registry, because a registry is a set of rows in the store and the corpus is a
set of files. Nothing keeps them in step, so a project quietly keeps binding
whatever it last registered — in one observed case four workflows behind
(`docs-only@17` while the corpus had `@18`, `standard-change@25` against `@26`)
with every one of those stale rows looking perfectly healthy in
`docket workflow list`.

**The invariant you are establishing:** for every workflow name declared by a
file in any instance-config root, the version that file declares is registered
and binding, and every other registered version of that name is retired. After
a successful pass, `docket workflow list` and the corpus files agree
name-for-name and version-for-version, with the same count on both sides.

**Not `refit`.** You change registry rows only. You never edit a workflow TOML,
never bump a version, never author a definition. When the corpus is what is
wrong, this skill stops and says so — fixing it is `refit`'s contract, in
source, committed.

## Cwd discipline — read this before running anything

**Every docket registry verb resolves its project from the working directory.
Never `cd` out of the checkout you are reconciling.** Pass corpus files as
absolute paths instead.

This is not a style note, it is the failure this skill exists downstream of. A
session linting the corpus ran `cd ~/.docket/config/workflows` first and got
four confident errors — a missing `findings@9` schema, three unregistered vote
rules — every one of them an artifact of having resolved to a different project
than the one being fixed. `~/.docket/config/` belongs to no project. Re-running
the identical lints from the checkout with absolute paths passed clean on all
four.

So: if a lint reports a missing schema or an unregistered `vote_rule`,
**suspect your cwd before you believe the finding.** Re-run from the checkout
with an absolute path. Only if it still fails is the prerequisite genuinely
absent, and only then reach for `docket schema register <ref> <file>` or
`docket config set vote.rule.<name>.threshold <n>` — scoped to this project,
not `--global`, unless the operator says every project should get it.

## Let the engine parse the TOML

Never `grep` a version out of these files: a `grep -m1 version` silently
concatenates digits from unrelated keys and reports `security-change@2525792`
for what is actually `@25`. Never hand-parse them either. The planner used to
import `tomllib`, which needs Python 3.11+ and is simply absent where `python3`
is 3.9 — as it is here.

`docket workflow lint <file> --json=v2` is the parser, and it is the same parse
`docket workflow register` runs:

```json
{"ok":true,"data":{"name":"docs-only","version":19,
 "sha256":"1b4969…","registration":"unchanged"},"message":"…"}
```

`registration` is the engine's own verdict on what a register would do: `new`,
`unchanged`, or a failure carrying `"code":"CONFLICT"` whose error names the
frozen `name@version` and both hashes. That is precisely the REGISTER /
CONFLICT decision, decided by the engine rather than by a hash comparison in
the planner — so the planner needs no TOML library and no `sha256` of its own.

One thing lint does *not* tell you: a registered-but-retired version still
lints `unchanged`, because retiring a row does not change its bytes. RESTORE is
therefore still read from `deprecated_at_ms` on the registry row, which the
planner fetches anyway.

A file that fails lint for any other reason has no name the planner can trust,
so it is reported as INVALID and left out of the target binding set entirely.

## Step 1 — plan (read-only)

Run from the checkout. This mutates nothing; it prints the actions and stops.

```python
# reconcile-plan.py — run with cwd set to the checkout being reconciled
import glob, json, os, re, subprocess, sys

repo = os.getcwd()
roots = [os.path.expanduser("~/.docket/config/workflows"),
         os.path.join(repo, ".docket/config/workflows")]

def docket(*args):                     # always cwd=repo -- see "Cwd discipline" above
    p = subprocess.run(["docket", *args], capture_output=True, text=True, cwd=repo)
    try:
        return json.loads(p.stdout)
    except ValueError:
        return {"ok": False, "error": (p.stderr or p.stdout).strip() or f"exit {p.returncode}"}

disk, bad = {}, []
for root in roots:                     # later root wins -- see "Two roots" below
    for f in sorted(glob.glob(os.path.join(root, "*.toml"))):
        r = docket("workflow", "lint", f, "--json=v2")
        if r.get("ok"):
            d = r["data"]
            disk[d["name"]] = {"v": d["version"], "f": f, "reg": d["registration"]}
            continue
        err = str(r.get("error", ""))
        m = re.match(r"([^\s@]+)@(\d+) is registered with different bytes", err)
        if r.get("code") == "CONFLICT" and m:      # the frozen row the engine named
            disk[m.group(1)] = {"v": int(m.group(2)), "f": f, "reg": "conflict"}
        else:
            bad.append((f, err.splitlines()[0] if err else "lint failed"))

out = docket("workflow", "list", "--deprecated", "--limit", "500", "--json=v2")
if not out.get("ok"):
    sys.exit("registry read failed: " + str(out.get("error")))
reg = {}
for r in out["data"]["items"]:
    reg.setdefault(r["name"], {})[r["version"]] = r

plan = [("INVALID", f"# {f} fails lint: {err} -- fix in SOURCE (refit), never here")
        for f, err in bad]

for name, d in sorted(disk.items()):
    rows = reg.get(name, {})
    if d["reg"] == "conflict":
        plan.append(("CONFLICT", f"# {name}@{d['v']} registered bytes != {d['f']} -- bump [pipeline].version in SOURCE, never force"))
    elif d["reg"] == "new":
        plan.append(("REGISTER", f"docket workflow lint {d['f']} && docket workflow register {d['f']}"))
    elif rows.get(d["v"], {}).get("deprecated_at_ms"):
        plan.append(("RESTORE", f"docket workflow deprecate {name}@{d['v']} --restore"))
    for ov, row in sorted(rows.items()):
        if ov != d["v"] and not row.get("deprecated_at_ms"):
            plan.append(("DEPRECATE", f"docket workflow deprecate {name}@{ov}"))

for name, rows in sorted(reg.items()):
    if name in disk:
        continue
    live = sorted(v for v, r in rows.items() if not r.get("deprecated_at_ms"))
    if live:
        plan.append(("ORPHAN", f"# {name} declared by no file; still binding: {live} -- retire ALL only on operator approval"))

for kind, cmd in plan:
    print(f"{kind:9} {cmd}")
print(f"\n{len(plan)} action(s); target binding set = {len(disk)} workflows")
if bad:
    print(f"{len(bad)} file(s) failed lint and are absent from that set -- an ORPHAN line may be one of them")
```

`--deprecated` on that listing is load-bearing. Without it, retired rows are
invisible and a retired row reads as an unregistered one — which sets up the
trap in the next section.

## Step 2 — read the plan before running it

**REGISTER** — the corpus is ahead; the engine already called this file `new`.
Lint, then register anyway. Lint first every time: the registry may have moved
between planning and approval, a definition that fails validation must not reach
the registry, and the lint is free.

**DEPRECATE** — a version other than the corpus file's is still binding. Retire
it. Retirement is a binding-time filter and never a retraction: the row stays
registered and readable, `workflow show --source` still emits the exact bytes,
and any run that already pinned it still resolves it and still completes.

**RESTORE** — the corpus version is registered but retired, so binding is
falling through to something older. This is the case that punishes the obvious
shortcut: re-registering the same bytes is "a success and changes nothing", so
it will report success and leave the wrong version binding. `--restore` is the
only verb that fixes it.

**CONFLICT** — the registry holds this exact `name@version` with different
bytes than the file. This is the engine's own verdict, not an inference: the
lint failed with `"code":"CONFLICT"` and printed both hashes. A registered
`name@version` is frozen so a run that pinned it cannot have the definition
swapped underneath it. **Stop.** There is no
force flag worth reaching for here. Someone edited the corpus file without
bumping `[pipeline].version`; the fix is a version bump in source, committed,
then `just activate`, then reconcile again. Report it and move on to the other
names — one conflict does not block the rest.

**INVALID** — the file does not lint at all: bad TOML, a step rule it breaks, a
schema or `vote_rule` it references that is not registered here. Suspect your
cwd first (above), then re-run the single lint by hand to read the whole error.
A genuinely broken definition is `refit`'s to fix, in source — you cannot
register it and must not paper over it. Note that the file contributes no name
to the target set while it fails, so a name it would have claimed can also show
up on an ORPHAN line; that pairing is the same fault reported twice, not two.

**ORPHAN** — a registered name that no file in any root declares. Cross-check
with `docket workflow list --orphans`, which is the engine's own filesystem
verdict and cheaper to trust than the planner's. A *retired* orphan is
harmless and needs nothing. A *live* orphan looks like this: a renamed
workflow leaves every version of the old name binding, and one issue's label
can match two workflows, one of which has not existed on disk for weeks.
Retiring every version of a name removes it from routing altogether — that is a
routing change, so **surface it to the operator and let them decide.** Never
fold it into the approved batch on your own initiative.

## Step 3 — apply, then verify by assertion

Run the approved commands in plan order: REGISTER and RESTORE before DEPRECATE,
so no name is ever left with nothing eligible to bind.

Then verify — do not eyeball a table, assert the invariant:

```bash
docket workflow list --limit 500 --json=v2 | python3 -c "
import json,sys
items = json.load(sys.stdin)['data']['items']
by = {}
for i in items: by.setdefault(i['name'], []).append(i['version'])
dupes = {n: sorted(v) for n, v in by.items() if len(v) > 1}
print('names with >1 binding version:', dupes or 'none')
print('binding count:', len(items))
"
```

Then re-run the planner. **A clean pass prints `0 action(s)`** and a binding
count equal to the corpus file count. Anything else means the pass did not
finish; say so plainly rather than reporting success.

## Scope — one project unless told otherwise

A registry is per project and so is retirement. Everything above operates on
the project the cwd resolves to. That is the default and it is the safe one.

`register`, `deprecate`, and `schema register` all take `--all-projects`, which
writes to every project in the store and reports each project's own outcome.
The corpus drift this skill fixes is usually store-wide — `just activate` moved
one shared corpus, so every project fell behind together — which makes the
sweep tempting. **It is still an operator decision.** Say how many projects are
affected, then ask. Do not infer it from the drift being shared.

Note that validation is per target: a definition's `payload` and `vote_rule`
references resolve against the registry of the project being written to, so the
same bytes can be valid in one project and refused in the next for a schema
that does not exist there. Register schemas first when sweeping a store that
has not seen the corpus (`docket schema register <ref> <file> --all-projects`),
and expect a sweep to report a mix of outcomes rather than one verdict.

## Two roots, and one thing not verified

The planner reads a global root (`~/.docket/config/workflows/`) and an optional
repo-local one (`<repo>/.docket/config/workflows/`), with the repo-local one
winning a name declared in both.

**That precedence is the planner's convention, not a verified engine
behaviour.** No repo in this store currently has a local config root, so the
collision has never occurred and the rule has never been exercised. If you hit
a name declared in both roots, confirm what the engine actually binds before
trusting the plan — and once you know, replace this paragraph with the answer.
