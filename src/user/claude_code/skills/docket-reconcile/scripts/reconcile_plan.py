#!/usr/bin/env python3
"""Plan a docket-reconcile pass: what makes a project's registries match the corpus.

    reconcile_plan.py [CHECKOUT]                  one project; defaults to cwd
    reconcile_plan.py --all-projects              every project in the store
    reconcile_plan.py --all-projects --summary    one line per project

--strict exits 1 when any REGISTER, RESTORE, or DEPRECATE line remains.
Exit 2 means the plan could not be made (registry read failed or truncated).

Read-only: it runs lint, list, and show verbs and prints commands, never
running a register or deprecate. Every docket call runs with the target
checkout as its cwd, because `schema list` has no --project flag.
"""
import glob
import hashlib
import json
import os
import re
import subprocess
import sys

LIMIT = "1000"
ACTIONABLE = ("REGISTER", "RESTORE", "DEPRECATE")
# Apply order: schemas in, workflows in, workflows out, schemas out.
SCHEMA_IN, WORKFLOW_IN, WORKFLOW_OUT, SCHEMA_OUT, REPORTED = range(5)


class PlanError(Exception):
    pass


def docket(cwd, *args):
    p = subprocess.run(["docket", *args], capture_output=True, text=True, cwd=cwd)
    try:
        return json.loads(p.stdout)
    except ValueError:
        return {"ok": False, "error": (p.stderr or p.stdout).strip() or f"exit {p.returncode}"}


def config_roots(checkout):
    # later root wins a workflow name declared in both
    return [os.path.expanduser("~/.docket/config"), os.path.join(checkout, ".docket", "config")]


def corpus_files(roots, sub, ext):
    return [f for root in roots for f in sorted(glob.glob(os.path.join(root, sub, "*" + ext)))]


def resolves(roots, rel):
    return any(os.path.isfile(os.path.join(root, rel)) for root in roots)


def frontmatter(path):
    """Return (payload refs, packet_includes paths) from a contract's frontmatter."""
    with open(path) as fh:
        lines = fh.read().split("\n")
    if not lines or lines[0].strip() != "---":
        return [], []
    payloads, includes, in_includes = [], [], False
    for line in lines[1:]:
        if line.strip() == "---":
            break
        item = re.match(r"^\s+-\s+(\S+)\s*$", line)
        if in_includes and item:
            includes.append(item.group(1))
            continue
        in_includes = line.startswith("packet_includes:")
        m = re.match(r"^payload:\s*(\S+)\s*$", line)
        if m:
            payloads.append(m.group(1))
    return payloads, includes


def registry_rows(checkout, kind):
    out = docket(checkout, kind, "list", "--deprecated", "--limit", LIMIT, "--json=v2")
    if not out.get("ok"):
        raise PlanError(f"{kind} registry read failed: {out.get('error')}")
    if out["data"].get("truncated"):
        raise PlanError(f"{kind} list truncated at {LIMIT} of {out['data'].get('total')} rows; raise LIMIT")
    return out["data"]["items"]


def plan_project(checkout):
    """Return (prefix, actions, targets); actions are (phase, kind, text)."""
    roots = config_roots(checkout)
    cur = [p for p in docket(checkout, "project", "list", "--json=v2").get("data", {}).get("items", [])
           if p.get("current")]
    prefix = cur[0]["prefix"] if cur else "UNRESOLVED"
    plan = []

    def add(phase, kind, text):
        plan.append((phase, kind, text))

    # --- schemas: one target per name@version file
    sdisk = {}
    for f in corpus_files(roots, "schemas", ".json"):
        ref = os.path.basename(f)[: -len(".json")]
        if not re.fullmatch(r"[A-Za-z0-9_-]+@[1-9][0-9]*", ref):
            add(REPORTED, "INVALID", f"# {f} is not named <name>@<version>.json -- fix in SOURCE (docket-refit)")
            continue
        with open(f, "rb") as fh:
            sdisk[ref] = {"f": f, "sha": hashlib.sha256(fh.read()).hexdigest()}
    sreg = {f"{r['name']}@{r['version']}": r for r in registry_rows(checkout, "schema")}

    for ref, d in sorted(sdisk.items()):
        row = sreg.get(ref)
        if row is None:
            add(SCHEMA_IN, "REGISTER", f"docket schema register {ref} {d['f']}")
        elif row.get("source_sha256") != d["sha"]:
            add(REPORTED, "CONFLICT",
                f"# schema {ref} registered bytes != {d['f']} -- new <name>@<version+1> file in SOURCE, never force")
        elif row.get("deprecated_at_ms"):
            add(SCHEMA_IN, "RESTORE", f"docket schema deprecate {ref} --restore")
    for ref, row in sorted(sreg.items()):
        if ref not in sdisk and not row.get("builtin") and not row.get("deprecated_at_ms"):
            add(SCHEMA_OUT, "DEPRECATE", f"docket schema deprecate {ref}")

    # --- contracts: payloads and packet includes must resolve in the corpus
    for f in corpus_files(roots, "contracts", ".md"):
        payloads, includes = frontmatter(f)
        for ref in payloads:
            if ref not in sdisk:
                add(REPORTED, "DANGLING", f"# {f} pins payload {ref}, which no schema file declares -- fix in SOURCE (docket-refit)")
        for rel in includes:
            if not resolves(roots, rel):
                add(REPORTED, "DANGLING", f"# {f} includes {rel}, which no root holds -- fix in SOURCE (docket-refit)")

    # --- workflows: one binding version per name
    disk = {}
    for f in corpus_files(roots, "workflows", ".toml"):
        r = docket(checkout, "workflow", "lint", f, "--json=v2")
        if r.get("ok"):
            d = r["data"]
            disk[d["name"]] = {"v": d["version"], "f": f, "reg": d["registration"]}
            continue
        err = str(r.get("error", ""))
        m = re.search(r"([^\s@]+)@(\d+) is registered with different bytes", err)
        if r.get("code") == "CONFLICT":  # the frozen row the engine named
            name = m.group(1) if m else os.path.basename(f)
            disk[name] = {"v": int(m.group(2)) if m else None, "f": f, "reg": "conflict"}
        else:
            first = err.splitlines()[0] if err else "lint failed"
            add(REPORTED, "INVALID", f"# {f} fails lint: {first} -- fix in SOURCE (docket-refit), never here")
    wreg = {}
    for r in registry_rows(checkout, "workflow"):
        wreg.setdefault(r["name"], {})[r["version"]] = r

    for name, d in sorted(disk.items()):
        versions = wreg.get(name, {})
        if d["reg"] == "conflict":
            add(REPORTED, "CONFLICT",
                f"# workflow {name}@{d['v']} registered bytes != {d['f']} -- bump [pipeline].version in SOURCE, never force")
            continue  # leave this name's binding untouched until the version bump lands
        if d["reg"] == "new":
            add(WORKFLOW_IN, "REGISTER", f"docket workflow lint {d['f']} && docket workflow register {d['f']}")
        else:
            if versions.get(d["v"], {}).get("deprecated_at_ms"):
                add(WORKFLOW_IN, "RESTORE", f"docket workflow deprecate {name}@{d['v']} --restore")
            check_registered_workflow(checkout, roots, name, d["v"], add)
        for ov, row in sorted(versions.items()):
            if ov != d["v"] and not row.get("deprecated_at_ms"):
                add(WORKFLOW_OUT, "DEPRECATE", f"docket workflow deprecate {name}@{ov}")
    for name, versions in sorted(wreg.items()):
        live = sorted(v for v, r in versions.items() if not r.get("deprecated_at_ms"))
        if name not in disk and live:
            add(REPORTED, "ORPHAN",
                f"# workflow {name} declared by no file; still binding: {live} -- retire ALL only on operator approval")

    plan.sort(key=lambda a: a[0])
    return prefix, plan, (len(disk), len(sdisk))


def check_registered_workflow(checkout, roots, name, version, add):
    """Source drift and packet paths, read from the engine's own parse of the row."""
    out = docket(checkout, "workflow", "show", f"{name}@{version}", "--json=v2")
    if not out.get("ok"):
        add(REPORTED, "INVALID", f"# workflow show {name}@{version} failed: {out.get('error')}")
        return
    data = out["data"]
    status = (data.get("source_status") or {}).get("state")
    if status in ("drifted", "unreadable"):
        add(REPORTED, "DRIFT",
            f"# workflow {name}@{version} source {status} at {data.get('source_path')} -- activation "
            + ("refuses; bump [pipeline].version in SOURCE" if status == "drifted" else "warns; re-install the corpus"))
    for step in (data.get("definition") or {}).get("steps", []):
        # a fanout step expands {executor} once per seat
        seats = [step["executor"]] if step.get("executor") else step.get("fanout") or [""]
        for rel in step.get("packet") or []:
            for seat in seats:
                path = rel.replace("{executor}", seat).replace("{name}", step.get("name", ""))
                if "{" in path or not path or not resolves(roots, path):
                    add(REPORTED, "DANGLING",
                        f"# workflow {name}@{version} step {step.get('name')} packs {path}, which no root holds -- fix in SOURCE (docket-refit)")


def print_plan(prefix, checkout, plan, targets):
    print("project:", prefix, checkout)
    for _, kind, text in plan:
        print(f"{kind:9} {text}")
    print(f"\n{len(plan)} action(s); target binding set = {targets[0]} workflows, {targets[1]} schema versions")


def summary_line(prefix, plan):
    counts = {}
    for _, kind, _ in plan:
        counts[kind] = counts.get(kind, 0) + 1
    detail = ", ".join(f"{n} {k}" for k, n in sorted(counts.items()))
    return f"{prefix:6} {detail or 'in sync'}"


def main(argv):
    args = [a for a in argv if not a.startswith("--")]
    flags = {a for a in argv if a.startswith("--")}
    unknown = flags - {"--all-projects", "--summary", "--strict"}
    if unknown or len(args) > 1 or (args and "--all-projects" in flags):
        print(__doc__, file=sys.stderr)
        return 2

    if "--all-projects" in flags:
        here = os.getcwd()
        items = docket(here, "project", "list", "--json=v2").get("data", {}).get("items", [])
        targets = [(p["prefix"], p["identity"]) for p in items]
    else:
        targets = [(None, args[0] if args else os.getcwd())]

    actionable, failed = 0, False
    for want, checkout in targets:
        if not os.path.isdir(checkout):
            print(f"{want:6} SKIPPED checkout missing at {checkout}" if "--summary" in flags
                  else f"project: {want} SKIPPED checkout missing at {checkout}\n")
            continue
        try:
            prefix, plan, counts = plan_project(checkout)
        except PlanError as e:
            print(f"project: {want or checkout} FAILED {e}", file=sys.stderr)
            failed = True
            continue
        if want and prefix != want:
            print(f"project: {want} FAILED checkout {checkout} resolves to {prefix}", file=sys.stderr)
            failed = True
            continue
        actionable += sum(1 for _, kind, _ in plan if kind in ACTIONABLE)
        if "--summary" in flags:
            print(summary_line(prefix, plan))
        else:
            print_plan(prefix, checkout, plan, counts)
            if len(targets) > 1:
                print("---")

    if failed:
        return 2
    if "--strict" in flags and actionable:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
