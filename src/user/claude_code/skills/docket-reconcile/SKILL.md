---
name: docket-reconcile
description: >-
  Use on "reconcile the workflows", "/reconcile", "make the registry match the
  corpus", "the workflows are out of date", "register the new workflow
  versions", "deprecate the old workflows", or after any `just activate` that
  moved the corpus forward. Makes one Docket project's workflow registry match
  the installed corpus exactly: registers missing versions, restores one
  retired by mistake, retires every other version of a name, and reports
  orphaned names and frozen-row conflicts it must not fix. Read-only until it
  prints a plan and the operator approves. Registry only; corpus authoring
  belongs to docket-refit.
---

# docket-reconcile

The corpus on disk is the authority. This skill makes one project's workflow
registry say the same thing.

`just activate` moves `~/.docket/config/` forward but touches no registry: a
registry is rows in the store, the corpus is files, and nothing keeps them in
step. A project quietly keeps binding whatever it last registered, with stale
rows looking healthy in `docket workflow list`.

**The invariant you are establishing:** for every workflow name declared by
a file in any root, the version that file declares is
registered and binding, and every other registered version of that name is
retired. After a successful pass, `docket workflow list` and the corpus
files agree name-for-name and version-for-version, with a binding count
equal to the target binding set the planner printed.

**Not `docket-refit`.** You change registry rows only, never a workflow
TOML, a version bump, or a definition; when the corpus is what is wrong,
stop and say so — fixing it is `docket-refit`'s contract.

## Cwd discipline — read this before running anything

Every docket registry verb resolves its project from the working directory.
Never `cd` out of the checkout you are reconciling; pass corpus files as
absolute paths instead. `register` and `deprecate` also take `--project
<ref>` to write to another project from here; `workflow list` and `workflow
lint` do not, so reading another project means running them with that
project's checkout as the child process's cwd (see Scope below).

`~/.docket/config/` belongs to no project, so linting from inside it
resolves to whatever project the shell happens to sit in and can report a
missing schema or an unregistered `vote_rule` that isn't real. If a lint
reports either, suspect your cwd before you believe the finding: re-run
from the checkout with an absolute path. Only if it still fails is the
prerequisite genuinely absent, and only then reach for `docket schema
register <ref> <file>` or `docket config set vote.rule.<name>.threshold
<n>`, scoped to this project, not `--global`, unless the operator says
every project should get it.

## Let the engine parse the TOML

Never `grep` a version out of these files: the version line carries a
trailing changelog comment full of digits, so piping `grep -m1 version`
through a digit filter concatenates the version with that comment and
reports `security-change@2525792` for `@25`. Never hand-parse them either.
`docket workflow lint <file> --json=v2` is the parser, and it is the same parse
`docket workflow register` runs:

```json
{"ok":true,"data":{"name":"docs-only","version":19,
 "sha256":"1b4969…","registration":"unchanged"},"message":"…"}
```

`registration` is the engine's own verdict on what a register would do:
`new`, `unchanged`, or a failure carrying `"code":"CONFLICT"` whose error
names the frozen `name@version` and both hashes. The engine decides the
REGISTER / CONFLICT split, not a hash comparison in the planner, so the
planner needs no TOML library and no `sha256` of its own.

One thing lint does not tell you: a registered-but-retired version still
lints `unchanged`, since retiring a row does not change its bytes. RESTORE is
read from `deprecated_at_ms` on the registry row, which the planner fetches
anyway.

A file that fails lint for any other reason has no name the planner can
trust, so it is reported as INVALID and left out of the target binding set
entirely.

## Step 0 — survey the store (read-only)

```bash
docket registry audit --json=v2
```

One call reports every project's drift against the shared corpus: `behind`
(the highest registered version of a name is below the corpus version) and
`orphaned` (no scanned file declares the name, with `retired` per name). Use
it to size the pass and to tell the operator how many projects are affected.
It repairs nothing, and it does not replace the planner: it compares only
the highest registered version, so it misses an older version still binding
beside the current one and a corpus version retired by mistake. It scans
this invocation's roots, so a name another project declares in its own
`.docket/config/` reads as orphaned here.

## Step 1 — plan (read-only)

Run from the checkout, or pass another project's checkout as the first
argument; every docket call then runs with that directory as its cwd, and
the shell stays where it is. This mutates nothing; it prints the actions and
stops.

```python
# docket-reconcile-plan.py [checkout] — defaults to cwd
import glob, json, os, re, subprocess, sys

repo = sys.argv[1] if len(sys.argv) > 1 else os.getcwd()
roots = [os.path.expanduser("~/.docket/config/workflows"),
         os.path.join(repo, ".docket/config/workflows")]

def docket(*args):                     # always cwd=repo -- see "Cwd discipline" above
    p = subprocess.run(["docket", *args], capture_output=True, text=True, cwd=repo)
    try:
        return json.loads(p.stdout)
    except ValueError:
        return {"ok": False, "error": (p.stderr or p.stdout).strip() or f"exit {p.returncode}"}

cur = [p for p in docket("project", "list", "--json=v2").get("data", {}).get("items", []) if p["current"]]
print("project:", cur[0]["prefix"] if cur else "UNRESOLVED", repo)

disk, bad = {}, []
for root in roots:                     # later root wins -- see "Two roots" below
    for f in sorted(glob.glob(os.path.join(root, "*.toml"))):
        r = docket("workflow", "lint", f, "--json=v2")
        if r.get("ok"):
            d = r["data"]
            disk[d["name"]] = {"v": d["version"], "f": f, "reg": d["registration"]}
            continue
        err = str(r.get("error", ""))
        m = re.search(r"([^\s@]+)@(\d+) is registered with different bytes", err)
        if r.get("code") == "CONFLICT":        # the frozen row the engine named
            name = m.group(1) if m else os.path.basename(f)
            version = int(m.group(2)) if m else None
            disk[name] = {"v": version, "f": f, "reg": "conflict"}
        else:
            bad.append((f, err.splitlines()[0] if err else "lint failed"))

out = docket("workflow", "list", "--deprecated", "--limit", "500", "--json=v2")
if not out.get("ok"):
    sys.exit("registry read failed: " + str(out.get("error")))
reg = {}
for r in out["data"]["items"]:
    reg.setdefault(r["name"], {})[r["version"]] = r

plan = [("INVALID", f"# {f} fails lint: {err} -- fix in SOURCE (docket-refit), never here")
        for f, err in bad]

for name, d in sorted(disk.items()):
    rows = reg.get(name, {})
    if d["reg"] == "conflict":
        plan.append(("CONFLICT", f"# {name}@{d['v']} registered bytes != {d['f']} -- bump [pipeline].version in SOURCE, never force"))
        continue        # leave this name's binding untouched until the version bump lands
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
invisible and a retired row reads as an unregistered one.

## Step 2 — read the plan before running it

**REGISTER** — the corpus is ahead; the engine already called this file
`new`. Lint, then register anyway: the registry may have moved between
planning and approval, a definition that fails validation must not reach it,
and the lint is free.

**DEPRECATE** — a version other than the corpus file's is still binding.
Retire it. Retirement is a binding-time filter and never a retraction: the
row stays registered and readable, `workflow show --source` still emits
the exact bytes, and any run that already pinned it still resolves it and
still completes.

**RESTORE** — the corpus version is registered but retired, so binding is
falling through to something older. Re-registering the same bytes reports
success and changes nothing, leaving the wrong version binding.
`--restore` is the only verb that fixes it.

**CONFLICT** — the registry holds this exact `name@version` with different
bytes than the file. This is the engine's own verdict, not an inference: the
lint failed with `"code":"CONFLICT"` and printed both hashes. A registered
`name@version` is frozen so a run that pinned it cannot have the definition
swapped underneath it. Stop; there is no force flag worth reaching for.
Someone edited the corpus file without bumping `[pipeline].version`; the fix
is a version bump in source, committed, then `just activate`, then reconcile
again. Report it and move on — one conflict does not block the rest.

**INVALID** — the file does not lint at all: bad TOML, a step rule it
breaks, a schema or `vote_rule` it references that is not registered here.
Suspect your cwd first (above), then re-run the single lint by hand to read
the whole error. A genuinely broken definition is `docket-refit`'s to fix, in
source; you cannot register it and must not paper over it. The file
contributes no name to the target set while it fails, so a name it would
have claimed can also show up on an ORPHAN line — that pairing is the same
fault reported twice, not two.

**ORPHAN** — a registered name that no file in any root declares.
Cross-check with `docket workflow list --orphans`, the engine's own
filesystem verdict and cheaper to trust than the planner's. A retired orphan
is harmless and needs nothing. A live orphan can mean a renamed workflow left
every version of the old name binding, or that one issue's label matches two
workflows, one of which has not existed on disk for weeks. Retiring every
version of a name removes it from routing altogether, which is a routing
change: surface it to the operator and let them decide. Never fold it into
the approved batch on your own initiative.

When the advisor tool is available, call it on the plan before presenting
it for that decision.

## Step 3 — apply, then verify by assertion

Run the approved commands in plan order: REGISTER and RESTORE before
DEPRECATE, so no name is left with nothing eligible to bind.

Then verify — do not eyeball a table, assert the invariant:

```bash
docket workflow list --limit 500 --json=v2 | jq -r '
  .data.items as $items
  | ($items | group_by(.name) | map(select(length > 1) | {(.[0].name): (map(.version) | sort)}) | add) as $dupes
  | "names with >1 binding version: \($dupes // "none" | if . == "none" then . else tojson end)",
    "binding count: \($items | length)"'
```

Then re-run the planner. A clean pass prints no `REGISTER`, `RESTORE`, or
`DEPRECATE` line, and a binding count equal to the target binding set
printed by the planner, excluding any name currently under CONFLICT.
`CONFLICT`, `INVALID`, and `ORPHAN` lines are reported outcomes, not
unfinished work; the `action(s)` count includes them. Any remaining
actionable line means the pass did not finish; say so rather than reporting
success.

## Scope — one project unless told otherwise

A registry is per project and so is retirement. Everything above operates on
the project the cwd resolves to — the default, and the safe one.

`register`, `deprecate`, and `schema register` all take `--project <ref>`
(a prefix, name, identity path, or row id) to write to one other project,
and `--all-projects`, which writes to every project in the store. Both
report each project's own outcome. The corpus drift this skill fixes is
usually store-wide, since `just activate` moves one shared corpus and every
project falls behind together, but sweeping every project is still an
operator decision: say how many are affected, then ask. Do not infer it from the drift being shared.

For a multi-project pass, take each project's checkout from the `identity`
field of `docket project list --json=v2` and run the planner once per
checkout with that path as its argument; confirm its `project:` line names
the intended prefix. When every plan carries the same actions, apply them
once with `--all-projects` instead of per project. Verify per project: run
the Step 3 `jq` assertion in a subshell per checkout (`(cd <identity> &&
docket workflow list …)`), re-run the planner for each, and expect
`behind_total` 0 from `docket registry audit`.

Validation is per target: a definition's `payload` and `vote_rule`
references resolve against the registry of the project being written to, so
the same bytes can be valid in one project and refused in the next for a
schema that does not exist there. Register schemas first when sweeping a
store that has not seen the corpus (`docket schema register <ref> <file>
--all-projects`), and expect a mix of outcomes rather than one verdict.

## Two roots, and one thing not verified

The planner reads a global root (`~/.docket/config/workflows/`) and an
optional repo-local one (`<repo>/.docket/config/workflows/`), the repo-local
one winning a name declared in both.

That precedence is the planner's convention, not a verified engine
behavior. While no root declares a colliding name, the rule stays
unexercised. If you hit a name declared in both roots, confirm what the
engine binds before trusting the plan.
