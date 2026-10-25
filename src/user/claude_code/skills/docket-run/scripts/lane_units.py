"""Split a kept manifest into wave launches, one per issue lane.

Usage: python3 lane_units.py <rows-file> <out-dir> [--workflows FILE]
                              [--tribunal PATH] [--integrated FILE]
                              [--in-flight LANES] [--write-cap N]

<rows-file> holds the rows the conductor kept after the kind filter, either
as one JSON array or as one JSON object per line; a file holding a single
object is that one row. --workflows names the run's roster, the JSON file
that says which workflow each bound issue runs under, so each launch names
the lane script to launch: lane_roster.sh's output ([{issue, workflow}], the
workflow as name@version), an activation's `--json` answer as a whole or its
`.data.bound_issues` array in the same shape, or a plain object of lane to
workflow name, where a lane is the issue id or row:<step> for a row without
an issue. On an active run only lane_roster.sh is complete: an activation
answer lists the issues that activation bound, not the run's. Every lane
launched must resolve, or the script exits 1 before writing anything and
names the lanes that did not. Without --workflows no launch names a script
and stderr says so. --tribunal is the installed tribunal.js path;
--integrated names a JSON file mapping each fix-round issue to its prior
INTEGRATION sha. --in-flight is a comma-separated list of the lanes whose
launches are still running: the issue id, or row:<step> for a row without
an issue, with stderr's `lane:` prefix and surrounding spaces accepted. A
refill re-split launches no lane in it, writes none of its rows anywhere,
and counts each against the launch cap, including a name matching no row,
which stderr lists in case it is a typo. --write-cap is the write class's
effective cap as the engine reports it, a positive integer; the launch cap
is then min(LAUNCH_CAP, N), so launches never outgrow the class headroom the
host grants, and LAUNCH_CAP when the flag is absent (the class is unbounded).
Run it from inside the run's git work tree: outside one it exits 1 and
writes nothing. The script writes, under <out-dir>:

  launch-<i>.jsonl  launch i's rows, one per line, in manifest order
  args-<i>.json     launch i's complete lane script args (below)
  launches.json     [{index, of, classCap, rows, lanes, harnessCap, workflow,
                    script}] per launch; `workflow` is the lane's workflow
                    name and `script` the lane script's file name,
                    <workflow>.js, both only when --workflows is given
  deferred.jsonl    rows of lanes past the free launch slots, one per line
                    (always written, empty when nothing is deferred)

and, under <toplevel>/.claude/docket-packets/ (`git rev-parse
--show-toplevel`), one rows module per launch, rows-<sha256>.js, returning
{v: 1, rows_sha256, rows}: launch i's rows, and the sha256 of
launch-<i>.jsonl's bytes. A Workflow script cannot read files but loads a
module under its working directory, as the lane scripts already load packet
modules from the same directory. The directory carries a `.gitignore` of `*`.

It prints the launch count N alone on stdout, so `N=$(python3 lane_units.py
rows.jsonl out)` works. Lanes and their launches go to stderr for the
dispatch report. args-<i>.json is launch i's Workflow args, passed unedited:
{rowsModule, rows_sha256, unit: {index, of, classCap}, harnessCap, cwd,
workflow, tribunal, integrated}, where cwd is the git toplevel, `workflow`
is the lane's workflow name when --workflows is given, `tribunal` is present
when --tribunal is given, and `integrated` only when --integrated is given.
The lane script compares the module's rows_sha256 with the args' before it
claims anything, and refuses a `workflow` that is not its own. The rows
themselves never ride in the args.

The partition. Every issue lane is its own launch: one issue, one wave. A
row without an issue is a lane of its own, keyed by its step. Lanes are
never welded or packed together. Writer lanes the engine never co-staged
therefore run in separate launches, and the engine's claim check keeps them
in stage order: a writer claimed while another lane's uncertified writer
holds its scope is refused, and the lane script settles that refusal as
skipped-not-ready, which a later refill relaunches. The free slots are the
launch cap minus the lanes in flight, never below zero. Past them, the
earliest lanes in manifest order launch and the rest go to deferred.jsonl,
named on stderr; the conductor launches them from a later re-split as
running launches return.

Class headroom. The engine certifies a class at the largest same-stage count
of its executor rows across the WHOLE manifest. A launch sees only its own
rows, so this script computes that count and gives each launch holding the
class its share: the count divided among the holders, the remainder to the
lowest-ranked holders, never below one.

Harness cap. Every launches.json entry carries harnessCap =
min(HARNESS_CAP, max(1, cpus - 2)), the value the conductor passes as the
launch's harnessCap arg. cpus is os.cpu_count(), or LANE_UNITS_CPUS when set.

This file exists because an inline heredoc (`python3 - <<'PY'`) is an
interpreter code argument the auto-mode deny rule refuses before it runs.
LAUNCH_CAP and HARNESS_CAP mirror lane_body.js and must not drift from it.
"""

import hashlib
import json
import os
import subprocess
import sys

LAUNCH_CAP = 20
HARNESS_CAP = 16
PACKET_DIR = os.path.join(".claude", "docket-packets")


def load_rows(path):
    with open(path, encoding="utf-8") as handle:
        text = handle.read()
    stripped = text.strip()
    if not stripped:
        return []
    try:
        data = json.loads(stripped)
    except json.JSONDecodeError:
        return [json.loads(line) for line in stripped.splitlines() if line.strip()]
    if isinstance(data, dict) and isinstance(data.get("rows"), list):
        return data["rows"]
    if isinstance(data, dict):
        return [data]
    if not isinstance(data, list):
        raise SystemExit(f"lane_units: {path} holds neither a rows array nor JSON lines")
    return data


def stage(row):
    value = row.get("stage")
    return value if isinstance(value, int) and not isinstance(value, bool) else 0


def cls(row):
    if isinstance(row.get("class"), str) and row["class"]:
        return row["class"]
    executor = row.get("executor")
    return executor if isinstance(executor, str) else ""


def lane(row):
    return str(row["issue"]) if row.get("issue") else "row:" + row["step"]


def is_executor(row):
    return row.get("kind") not in ("action", "vote")


def certified_classes(rows):
    counts = {}
    for row in rows:
        if is_executor(row):
            key = (stage(row), cls(row))
            counts[key] = counts.get(key, 0) + 1
    best = {}
    for (_, name), n in counts.items():
        best[name] = max(best.get(name, 0), n)
    return best


def split(rows, in_flight=frozenset(), launch_cap=LAUNCH_CAP):
    """One launch per lane not in flight, in manifest order, up to the free
    slots; the lanes past them defer."""
    order = [l for l in dict.fromkeys(lane(r) for r in rows) if l not in in_flight]
    free = max(0, launch_cap - len(in_flight))
    launched, deferred = order[:free], order[free:]
    launch_of = {l: i for i, l in enumerate(launched)}
    kept = [r for r in rows if lane(r) in launch_of]

    holders = {}
    for row in kept:
        if is_executor(row):
            holders.setdefault(cls(row), set()).add(launch_of[lane(row)])
    certified = certified_classes(rows)
    launches = []
    for index, name in enumerate(launched):
        cap = {}
        for klass, held in holders.items():
            if index not in held:
                continue
            ranked = sorted(held)
            base, remainder = divmod(certified.get(klass, 1), len(ranked))
            share = base + 1 if ranked.index(index) < remainder else base
            cap[klass] = max(1, share)
        launches.append({
            "index": index,
            "of": len(launched),
            "classCap": dict(sorted(cap.items())),
            "rows": [r for r in kept if lane(r) == name],
            "lanes": [name],
        })
    deferred_set = set(deferred)
    return launches, [r for r in rows if lane(r) in deferred_set], deferred


def harness_cap():
    override = os.environ.get("LANE_UNITS_CPUS")
    if override is None:
        cpus = os.cpu_count() or 1
    else:
        try:
            cpus = int(override)
        except ValueError:
            raise SystemExit(f"lane_units: LANE_UNITS_CPUS={override!r} is not an integer")
    return min(HARNESS_CAP, max(1, cpus - 2))


def write_rows(path, rows):
    text = "".join(json.dumps(row, separators=(",", ":")) + "\n" for row in rows)
    with open(path, "w", encoding="utf-8") as handle:
        handle.write(text)
    return text


def git_toplevel():
    """The checkout's root, looked up from this process's directory, or exit 1."""
    try:
        done = subprocess.run(["git", "rev-parse", "--show-toplevel"],
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                              universal_newlines=True)
    except OSError as err:
        raise SystemExit(f"lane_units: cannot run git ({err}); run from the run's git work tree")
    top = done.stdout.strip()
    if done.returncode != 0 or not top:
        why = done.stderr.strip() or "git rev-parse --show-toplevel printed nothing"
        raise SystemExit(f"lane_units: not inside a git work tree ({why}); run from the "
                         "run's checkout so the launch args carry its root as cwd")
    if not os.path.isdir(top):
        raise SystemExit(f"lane_units: git toplevel {top!r} is not a directory")
    return top


def write_module(packets, digest, rows):
    """Write a launch's rows as a module the lane script loads by path; return the path."""
    os.makedirs(packets, exist_ok=True)
    ignore = os.path.join(packets, ".gitignore")
    if not os.path.exists(ignore):
        with open(ignore, "w", encoding="utf-8") as handle:
            handle.write("*\n")
    path = os.path.join(packets, f"rows-{digest}.js")
    body = json.dumps({"v": 1, "rows_sha256": digest, "rows": rows}, separators=(",", ":"))
    partial = path + ".partial"
    with open(partial, "w", encoding="utf-8") as handle:
        handle.write("export const meta = { name: 'docket-launch-rows', "
                     "description: 'Wave launch rows written by lane_units.py' }\n")
        handle.write("return " + body + "\n")
    os.replace(partial, path)
    return path


USAGE = ("usage: lane_units.py <rows-file> <out-dir> [--workflows FILE] [--tribunal PATH] "
         "[--integrated FILE] [--in-flight LANES] [--write-cap N]")


def workflow_name(ref):
    """A workflow reference's name: `name@version` without the version."""
    return ref.split("@", 1)[0].strip()


def load_workflows(path):
    """--workflows as a dict of lane to workflow name, from lane_roster.sh's
    array (the bound_issues shape), an activation envelope holding one, or a
    plain lane to name object."""
    with open(path, encoding="utf-8") as handle:
        data = json.load(handle)
    bound = data
    if isinstance(bound, dict) and isinstance(bound.get("data"), dict):
        bound = bound["data"]
    if isinstance(bound, dict) and isinstance(bound.get("bound_issues"), list):
        bound = bound["bound_issues"]
    roster = {}
    if isinstance(bound, list):
        for item in bound:
            if (isinstance(item, dict) and isinstance(item.get("issue"), str)
                    and isinstance(item.get("workflow"), str) and item["workflow"]):
                roster[item["issue"]] = workflow_name(item["workflow"])
    elif isinstance(bound, dict):
        for key, value in bound.items():
            if isinstance(value, str) and value:
                roster[str(key)] = workflow_name(value)
    else:
        raise SystemExit(f"lane_units: {path} holds neither a roster array (lane_roster.sh's "
                         "output, or bound_issues), an activation envelope holding one, nor an "
                         "object of lane to workflow")
    if not roster:
        raise SystemExit(f"lane_units: {path} names no issue to workflow binding")
    return roster


def lane_key(name):
    """An --in-flight name as lane() keys it: stderr's `lane:` prefix and
    surrounding spaces dropped."""
    name = name.strip()
    return name[len("lane:"):].strip() if name.startswith("lane:") else name


def write_cap(value):
    """--write-cap's value as a positive int, or exit naming the flag."""
    if not (value.isascii() and value.isdecimal()) or int(value) < 1:
        raise SystemExit(f"lane_units: --write-cap {value!r} is not a positive integer")
    return int(value)


def parse_args(argv):
    positional, options = [], {}
    rest = list(argv[1:])
    while rest:
        arg = rest.pop(0)
        if arg in ("--workflows", "--tribunal", "--integrated", "--in-flight", "--write-cap"):
            if not rest:
                raise SystemExit(USAGE)
            options[arg[2:]] = rest.pop(0)
        elif arg.startswith("--"):
            raise SystemExit(USAGE)
        else:
            positional.append(arg)
    if len(positional) != 2:
        raise SystemExit(USAGE)
    in_flight = frozenset(filter(None, map(lane_key, options.get("in-flight", "").split(","))))
    launch_cap = LAUNCH_CAP
    if "write-cap" in options:
        launch_cap = min(LAUNCH_CAP, write_cap(options["write-cap"]))
    return (positional[0], positional[1], options.get("workflows"), options.get("tribunal"),
            options.get("integrated"), in_flight, launch_cap)


def main(argv):
    (rows_file, out, workflows_file, tribunal, integrated_file,
     in_flight, launch_cap) = parse_args(argv)
    cap = harness_cap()
    rows = load_rows(rows_file)
    roster = load_workflows(workflows_file) if workflows_file is not None else None
    integrated = None
    if integrated_file is not None:
        with open(integrated_file, encoding="utf-8") as handle:
            integrated = json.load(handle)
        if not isinstance(integrated, dict):
            raise SystemExit(f"lane_units: {integrated_file} holds no JSON object of issue -> sha")
    top = git_toplevel()
    packets = os.path.join(top, PACKET_DIR)
    launches, deferred_rows, deferred_lanes = split(rows, in_flight, launch_cap)
    if roster is not None:
        unresolved = [launch["lanes"][0] for launch in launches
                      if launch["lanes"][0] not in roster]
        if unresolved:
            raise SystemExit("lane_units: no workflow in " + workflows_file + " for lane(s) "
                             + ", ".join(unresolved) + "; re-derive the roster with "
                             "`lane_roster.sh RUN-N`. A row:<step> lane (a row with no issue) has "
                             "no binding and no lane script: stop and report it")
    os.makedirs(out, exist_ok=True)
    summary = []
    for launch in launches:
        index = launch["index"]
        text = write_rows(os.path.join(out, f"launch-{index}.jsonl"), launch["rows"])
        digest = hashlib.sha256(text.encode("utf-8")).hexdigest()
        entry = {k: (len(v) if k == "rows" else v) for k, v in launch.items()}
        entry["harnessCap"] = cap
        if roster is not None:
            entry["workflow"] = roster[launch["lanes"][0]]
            entry["script"] = entry["workflow"] + ".js"
        summary.append(entry)
        args = {
            "rowsModule": write_module(packets, digest, launch["rows"]),
            "rows_sha256": digest,
            "unit": {"index": index, "of": launch["of"], "classCap": launch["classCap"]},
            "harnessCap": cap,
            "cwd": top,
        }
        if roster is not None:
            args["workflow"] = entry["workflow"]
        if tribunal is not None:
            args["tribunal"] = tribunal
        if integrated is not None:
            args["integrated"] = integrated
        with open(os.path.join(out, f"args-{index}.json"), "w", encoding="utf-8") as handle:
            json.dump(args, handle, separators=(",", ":"))
            handle.write("\n")
    with open(os.path.join(out, "launches.json"), "w", encoding="utf-8") as handle:
        json.dump(summary, handle, indent=2)
        handle.write("\n")
    write_rows(os.path.join(out, "deferred.jsonl"), deferred_rows)
    print(len(launches))
    for launch in launches:
        print(f"lane:{launch['lanes'][0]} -> launch {launch['index']}", file=sys.stderr)
    if launches and roster is None:
        print("lane_units: no --workflows given, so no launch names its lane script",
              file=sys.stderr)
    if launches and tribunal is None:
        print("lane_units: no --tribunal given, so no args object carries tribunal",
              file=sys.stderr)
    absent = sorted(in_flight - {lane(r) for r in rows})
    if absent:
        print("lane_units: in flight but in no row: " + ", ".join(absent) +
              "; each still holds a launch slot", file=sys.stderr)
    if deferred_lanes:
        print(f"deferred: {len(deferred_lanes)} lane(s) past the {launch_cap}-launch cap "
              f"with {len(in_flight)} in flight, {len(deferred_rows)} row(s) in "
              f"deferred.jsonl; launch them as launches return: " + ", ".join(deferred_lanes),
              file=sys.stderr)


if __name__ == "__main__":
    main(sys.argv)
