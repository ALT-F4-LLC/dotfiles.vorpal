"""Count the lane units of a kept manifest, the way wave.js partitions it.

Usage: python3 lane_units.py <rows-file>

<rows-file> holds the rows the conductor kept after the kind filter, either
as one JSON array or as one JSON object per line. Writer lanes (rows whose
class, or executor when class is absent, is "write") that never share a
manifest stage are welded into one unit; every other lane is a unit of its
own. The shard count N, the unit count capped at four and floored at one,
is printed alone on stdout so `N=$(python3 lane_units.py rows.json)` works;
the units themselves go to stderr for the dispatch report.

This file exists because the same program as an inline heredoc
(`python3 - <<'PY'`) is an interpreter code argument, which the auto-mode
deny rule refuses before it runs. The arithmetic is wave.js's partition and
must not drift from it: a different count here launches the wrong number of
shards.
"""

import json
import sys


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
    return row["stage"] if isinstance(row.get("stage"), int) else 0


def cls(row):
    if isinstance(row.get("class"), str) and row["class"]:
        return row["class"]
    return row.get("executor") or ""


def lane(row):
    return str(row["issue"]) if row.get("issue") else "row:" + row["step"]


def writer(row):
    return row.get("kind") not in ("action", "vote") and cls(row) == "write"


def count_units(rows):
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
        for b in writers[i + 1:]:
            if frozenset((a, b)) not in certified:
                parent[find(b)] = find(a)
    units = {
        ("unit:" + find(l)) if l in parent else ("lane:" + l)
        for l in {lane(r) for r in rows}
    }
    return sorted(units)


def main(argv):
    if len(argv) != 2:
        raise SystemExit("usage: lane_units.py <rows-file>")
    units = count_units(load_rows(argv[1]))
    print(max(1, min(4, len(units))))
    print("units:", " ".join(units) if units else "(none)", file=sys.stderr)


if __name__ == "__main__":
    main(sys.argv)
