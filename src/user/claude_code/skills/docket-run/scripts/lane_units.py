"""Split a kept manifest into wave launches, one per issue lane.

Usage: python3 lane_units.py <rows-file> <out-dir> [--tribunal PATH]
                              [--integrated FILE]

<rows-file> holds the rows the conductor kept after the kind filter, either
as one JSON array or as one JSON object per line; a file holding a single
object is that one row. --tribunal is the installed tribunal.js path;
--integrated names a JSON file mapping each fix-round issue to its prior
INTEGRATION sha. Run it from inside the run's git work tree: outside one it
exits 1 and writes nothing. The script writes, under <out-dir>:

  launch-<i>.jsonl  launch i's rows, one per line, in manifest order
  args-<i>.json     launch i's complete wave.js args (below)
  launches.json     [{index, of, classCap, rows, lanes, harnessCap}] per launch
  deferred.jsonl    rows of lanes past LAUNCH_CAP, one per line (always written,
                    empty when nothing is deferred)

and, under <toplevel>/.claude/docket-packets/ (`git rev-parse
--show-toplevel`), one rows module per launch, rows-<sha256>.js, returning
{v: 1, rows_sha256, rows}: launch i's rows, and the sha256 of
launch-<i>.jsonl's bytes. A Workflow script cannot read files but loads a
module under its working directory, as wave.js already loads packet modules
from the same directory. The directory carries a `.gitignore` of `*`.

It prints the launch count N alone on stdout, so `N=$(python3 lane_units.py
rows.jsonl out)` works. Lanes and their launches go to stderr for the
dispatch report. args-<i>.json is launch i's Workflow args, passed unedited:
{rowsModule, rows_sha256, unit: {index, of, classCap}, harnessCap, cwd,
tribunal, integrated}, where cwd is the git toplevel, `tribunal` is present
when --tribunal is given, and `integrated` only when --integrated is given.
wave.js compares the module's rows_sha256 with the args' before it claims
anything. The rows themselves never ride in the args.

The partition. Every issue lane is its own launch: one issue, one wave. A
row without an issue is a lane of its own, keyed by its step. Lanes are
never welded or packed together. Writer lanes the engine never co-staged
therefore run in separate launches, and the engine's claim check keeps them
in stage order: a writer claimed while another lane's uncertified writer
holds its scope is refused, and wave.js settles that refusal as a deferral
the engine re-offers at the next dispatch. Past LAUNCH_CAP lanes, the
earliest lanes in manifest order launch and the rest go to deferred.jsonl,
named on stderr; the engine re-offers them at the next dispatch.

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
LAUNCH_CAP and HARNESS_CAP mirror wave.js and must not drift from it.
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


def split(rows):
    """One launch per lane, in manifest order; lanes past LAUNCH_CAP defer."""
    order = list(dict.fromkeys(lane(r) for r in rows))
    launched, deferred = order[:LAUNCH_CAP], order[LAUNCH_CAP:]
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
    return launches, [r for r in rows if lane(r) not in launch_of], deferred


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
    """Write a launch's rows as a module wave.js loads by path; return the path."""
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


USAGE = "usage: lane_units.py <rows-file> <out-dir> [--tribunal PATH] [--integrated FILE]"


def parse_args(argv):
    positional, options = [], {}
    rest = list(argv[1:])
    while rest:
        arg = rest.pop(0)
        if arg in ("--tribunal", "--integrated"):
            if not rest:
                raise SystemExit(USAGE)
            options[arg[2:]] = rest.pop(0)
        elif arg.startswith("--"):
            raise SystemExit(USAGE)
        else:
            positional.append(arg)
    if len(positional) != 2:
        raise SystemExit(USAGE)
    return positional[0], positional[1], options.get("tribunal"), options.get("integrated")


def main(argv):
    rows_file, out, tribunal, integrated_file = parse_args(argv)
    cap = harness_cap()
    rows = load_rows(rows_file)
    integrated = None
    if integrated_file is not None:
        with open(integrated_file, encoding="utf-8") as handle:
            integrated = json.load(handle)
        if not isinstance(integrated, dict):
            raise SystemExit(f"lane_units: {integrated_file} holds no JSON object of issue -> sha")
    top = git_toplevel()
    packets = os.path.join(top, PACKET_DIR)
    os.makedirs(out, exist_ok=True)
    launches, deferred_rows, deferred_lanes = split(rows)
    summary = []
    for launch in launches:
        index = launch["index"]
        text = write_rows(os.path.join(out, f"launch-{index}.jsonl"), launch["rows"])
        digest = hashlib.sha256(text.encode("utf-8")).hexdigest()
        entry = {k: (len(v) if k == "rows" else v) for k, v in launch.items()}
        entry["harnessCap"] = cap
        summary.append(entry)
        args = {
            "rowsModule": write_module(packets, digest, launch["rows"]),
            "rows_sha256": digest,
            "unit": {"index": index, "of": launch["of"], "classCap": launch["classCap"]},
            "harnessCap": cap,
            "cwd": top,
        }
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
    if launches and tribunal is None:
        print("lane_units: no --tribunal given, so no args object carries tribunal",
              file=sys.stderr)
    if deferred_lanes:
        print(f"deferred: {len(deferred_lanes)} lane(s) past the {LAUNCH_CAP}-launch cap, "
              f"{len(deferred_rows)} row(s) in deferred.jsonl; the engine re-offers them "
              f"next dispatch: " + ", ".join(deferred_lanes), file=sys.stderr)


if __name__ == "__main__":
    main(sys.argv)
