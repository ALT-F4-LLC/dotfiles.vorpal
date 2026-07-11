#!/usr/bin/env python3
"""File-collision linter for a docket epic's execution plan.

Given a root/epic issue id, walks ``docket plan --root <epic> --json`` to
enumerate descendant issues and phases, then ``docket issue show <id>
--json`` per issue for its attached files and ``depends_on`` relations
(one call gets both, so a separate ``docket issue file list`` pass per
issue is unnecessary). Flags:

  (a) COLLISION  two issues in the *same* phase touching the same file
      (a same-phase collision is a planning bug regardless of any
      depends_on link — depends_on cannot fix concurrent execution).
  (b) WARNING    two issues in *different* phases touching the same file
      with no depends_on chain (direct or transitive, either direction)
      connecting them — phase ordering happens to keep them serialized,
      but nothing records that the ordering is required.

Mechanizes project-manager.md's "No-collision duty" (producer-side) and
team-lead.md step 8's consumer-side re-check of the same thing.

Read-only against Docket (issues a `docket plan`/`docket issue show` per
issue; never mutates). Stdlib only — invokes the `docket` CLI as a
subprocess.
"""

import argparse
import itertools
import json
import subprocess
import sys
from collections import defaultdict


def run_docket(*args):
    result = subprocess.run(["docket", *args, "--json"], capture_output=True, text=True)
    if result.returncode != 0:
        print(f"error: docket {' '.join(args)} failed: {result.stderr.strip()}", file=sys.stderr)
        sys.exit(2)
    payload = json.loads(result.stdout)
    if not payload.get("ok"):
        print(f"error: docket {' '.join(args)} returned ok=false: {payload}", file=sys.stderr)
        sys.exit(2)
    return payload["data"]


def load_plan_issue_ids(root):
    """Issue id -> phase number, for every issue in root's active plan."""
    data = run_docket("plan", "--root", root)
    phase_by_issue = {}
    for phase in data["phases"]:
        for issue in phase["issues"]:
            phase_by_issue[issue["id"]] = phase["phase"]
    return phase_by_issue


def load_issue_details(issue_ids):
    """issue id -> (files: set[str], depends_on: set[issue_id]) via `issue show`."""
    files_by_issue = {}
    depends_on = defaultdict(set)
    for issue_id in issue_ids:
        data = run_docket("issue", "show", issue_id)
        files_by_issue[issue_id] = set(data.get("files") or [])
        for rel in data.get("relations") or []:
            if rel["relation_type"] != "depends_on":
                continue
            src, dst = rel["source_issue_id"], rel["target_issue_id"]
            if src in issue_ids and dst in issue_ids:
                depends_on[src].add(dst)
    return files_by_issue, depends_on


def _reachable(start, target, depends_on):
    seen = set()
    stack = [start]
    while stack:
        node = stack.pop()
        if node == target:
            return True
        if node in seen:
            continue
        seen.add(node)
        stack.extend(depends_on.get(node, ()))
    return False


def linked(a, b, depends_on):
    """Whether a depends_on chain (either direction, transitive) connects a and b."""
    return _reachable(a, b, depends_on) or _reachable(b, a, depends_on)


def find_collisions(root):
    phase_by_issue = load_plan_issue_ids(root)
    issue_ids = set(phase_by_issue)
    files_by_issue, depends_on = load_issue_details(issue_ids)

    file_to_issues = defaultdict(set)
    for issue_id, files in files_by_issue.items():
        for f in files:
            file_to_issues[f].add(issue_id)

    collisions = []
    warnings = []
    for f, touching in file_to_issues.items():
        if len(touching) < 2:
            continue
        for a, b in itertools.combinations(sorted(touching), 2):
            phase_a, phase_b = phase_by_issue[a], phase_by_issue[b]
            if phase_a == phase_b:
                collisions.append((f, a, b, phase_a))
            elif not linked(a, b, depends_on):
                warnings.append((f, a, b, phase_a, phase_b))

    return collisions, warnings


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--root", required=True, help="root/epic issue id, e.g. DKT-145")
    parser.add_argument("--json", action="store_true", help="emit machine-readable JSON instead of text")
    args = parser.parse_args(argv)

    collisions, warnings = find_collisions(args.root)

    if args.json:
        print(
            json.dumps(
                {
                    "root": args.root,
                    "collisions": [{"file": f, "issue_a": a, "issue_b": b, "phase": p} for f, a, b, p in collisions],
                    "warnings": [
                        {"file": f, "issue_a": a, "issue_b": b, "phase_a": pa, "phase_b": pb}
                        for f, a, b, pa, pb in warnings
                    ],
                },
                indent=2,
            )
        )
    else:
        if not collisions and not warnings:
            print(f"plan_collision_check: OK ({args.root}: no same-phase collisions, no missing depends_on links)")
        for f, a, b, p in collisions:
            print(f"COLLISION  phase {p}: {a} and {b} both touch {f}")
        for f, a, b, pa, pb in warnings:
            print(f"WARNING    {a} (phase {pa}) and {b} (phase {pb}) both touch {f} with no depends_on link")

    return 1 if collisions else 0


if __name__ == "__main__":
    sys.exit(main())
