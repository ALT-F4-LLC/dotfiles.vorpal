"""Split a kept manifest into wave launches, one per lane unit.

Usage: python3 lane_units.py <rows-file> <out-dir>

<rows-file> holds the rows the conductor kept after the kind filter, either
as one JSON array or as one JSON object per line. The script writes, under
<out-dir>:

  launch-<i>.jsonl  launch i's rows, one per line, in manifest order
  launches.json     [{index, of, classCap, rows, lanes, harnessCap}] per launch

and prints the launch count N alone on stdout, so `N=$(python3 lane_units.py
rows.jsonl out)` works. Units and their launches go to stderr for the
dispatch report. Each launch's Workflow args are its own rows, `unit: {index,
of, classCap}`, and `harnessCap`, the last two copied from launches.json.

The partition. Writer lanes (rows whose class, or executor when class is
absent, is "write") that never share a manifest stage are welded into one
unit, since wave.js serializes them through an in-flight set no sibling
launch can see; every other lane is a unit of its own. Units are packed onto
at most LAUNCH_CAP launches, largest projected agent cost first, onto the
least-loaded launch, ties by unit name then lowest launch index.

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
The weights and caps mirror wave.js (EXECUTOR_AGENT_COST, VOTE_PROBE_COST,
DEFAULT_PANEL_SEATS, LAUNCH_CAP, HARNESS_CAP) and must not drift from it.
"""

import json
import os
import sys

LAUNCH_CAP = 20
EXECUTOR_AGENT_COST = 3
VOTE_PROBE_COST = 4
DEFAULT_PANEL_SEATS = 3
HARNESS_CAP = 16


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


def writer(row):
    return is_executor(row) and cls(row) == "write"


def agent_cost(row):
    if row.get("kind") == "action":
        return 0
    if row.get("kind") == "vote":
        seats = row.get("voter_assignments")
        count = len(seats) if isinstance(seats, list) and seats else DEFAULT_PANEL_SEATS
        return count + VOTE_PROBE_COST
    return EXECUTOR_AGENT_COST


def units_of(rows):
    """Map each lane to its unit key: welded writer lanes share one."""
    by_stage = {}
    for row in rows:
        if writer(row) and row.get("issue"):
            by_stage.setdefault(stage(row), set()).add(lane(row))
    certified = {
        frozenset((a, b))
        for lanes in by_stage.values()
        for a in lanes
        for b in lanes
        if a != b
    }
    parent = {}

    def find(x):
        parent.setdefault(x, x)
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    writers = sorted({lane(r) for r in rows if writer(r) and r.get("issue")})
    for i, a in enumerate(writers):
        find(a)
        for b in writers[i + 1:]:
            if frozenset((a, b)) not in certified:
                ra, rb = find(a), find(b)
                if ra != rb:
                    lo, hi = sorted((ra, rb))
                    parent[hi] = lo
    return {
        l: ("unit:" + find(l)) if l in parent else ("lane:" + l)
        for l in {lane(r) for r in rows}
    }


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
    lane_unit = units_of(rows)
    sizes = {}
    for row in rows:
        key = lane_unit[lane(row)]
        sizes[key] = sizes.get(key, 0) + agent_cost(row)
    of = max(1, min(LAUNCH_CAP, len(sizes))) if rows else 0
    load = [0] * of
    unit_launch = {}
    for key in sorted(sizes, key=lambda k: (-sizes[k], k)):
        target = min(range(of), key=lambda s: (load[s], s))
        load[target] += sizes[key]
        unit_launch[key] = target
    launch_of = {l: unit_launch[k] for l, k in lane_unit.items()}

    holders = {}
    for row in rows:
        if is_executor(row):
            holders.setdefault(cls(row), set()).add(launch_of[lane(row)])
    certified = certified_classes(rows)
    launches = []
    for index in range(of):
        cap = {}
        for name, held in holders.items():
            if index not in held:
                continue
            ranked = sorted(held)
            base, remainder = divmod(certified.get(name, 1), len(ranked))
            share = base + 1 if ranked.index(index) < remainder else base
            cap[name] = max(1, share)
        mine = [r for r in rows if launch_of[lane(r)] == index]
        launches.append({
            "index": index,
            "of": of,
            "classCap": dict(sorted(cap.items())),
            "rows": mine,
            "lanes": sorted({lane(r) for r in mine}),
        })
    return launches, lane_unit, unit_launch


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


def main(argv):
    if len(argv) != 3:
        raise SystemExit("usage: lane_units.py <rows-file> <out-dir>")
    cap = harness_cap()
    rows = load_rows(argv[1])
    out = argv[2]
    os.makedirs(out, exist_ok=True)
    launches, lane_unit, unit_launch = split(rows)
    summary = []
    for launch in launches:
        path = os.path.join(out, f"launch-{launch['index']}.jsonl")
        with open(path, "w", encoding="utf-8") as handle:
            for row in launch["rows"]:
                handle.write(json.dumps(row, separators=(",", ":")) + "\n")
        entry = {k: (len(v) if k == "rows" else v) for k, v in launch.items()}
        entry["harnessCap"] = cap
        summary.append(entry)
    with open(os.path.join(out, "launches.json"), "w", encoding="utf-8") as handle:
        json.dump(summary, handle, indent=2)
        handle.write("\n")
    print(len(launches))
    units = sorted(set(lane_unit.values()))
    if len(units) > LAUNCH_CAP:
        print(f"packed: {len(units)} units onto {LAUNCH_CAP} launches", file=sys.stderr)
    for key in units:
        print(f"{key} -> launch {unit_launch[key]}", file=sys.stderr)


if __name__ == "__main__":
    main(sys.argv)
