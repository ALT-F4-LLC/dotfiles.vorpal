#!/usr/bin/env python3
"""Definition-of-Ready (DoR) checker for a Docket issue tree.

Walks `docket issue list --parent <id> --all --json` recursively to
enumerate every issue in the tree (breadth-first from root_id), then
`docket issue show <id> --json` per issue to assert each passes the DoR
checklist in project-manager.md's "Definition of Ready (DoR)" section
(src/user/claude-code/agents/project-manager.md:285). NOTE: enumeration
deliberately does NOT use `docket plan --root --json` — that command
silently excludes issues already in `done` status from its phase output
(confirmed empirically: a plan re-queried after some children close
under-reports the tree), which would corrupt the completeness check below
once any child issue is closed. `docket issue list --parent --all` includes
done issues and is the accurate source of truth for tree enumeration.
  1. Clear title + description (heuristic: non-trivial description length —
     docket has no structured what/where/why/AC fields, so this is a length
     proxy, not a semantic check; below-threshold issues need manual review)
  2. Scope label present: one of must-have/should-have/could-have (docket has
     no distinct "estimated size" field, so the scope label is the checkable
     proxy for that DoR bullet)
  3. Files attached via `docket issue file add`; dependencies declared or
     none (absence of a depends_on relation is treated as "explicitly none",
     since docket has no dedicated no-dependencies marker)
  4. No unresolved blocking question markers in comments (heuristic keyword
     scan — cannot semantically judge "resolved", only flag for review)

Also enforces the "Completeness check before reporting done" convention
(project-manager.md:293): when --expected-count N is given, asserts the
number of DIRECT child issues under <root-id> equals N.

Read-only. Never edits, never writes. Stdlib + docket CLI only.
"""

import argparse
import json
import re
import subprocess
import sys

MOSCOW_LABELS = {"must-have", "should-have", "could-have"}
BLOCKING_MARKERS = re.compile(
    r"(unresolved|blocking question|needs a consult|open design dimension|"
    r"\btbd\b|needs decision|not settled|undetermined)",
    re.IGNORECASE,
)


def run_docket_json(*args):
    result = subprocess.run(["docket", *args, "--json"], capture_output=True, text=True)
    if result.returncode != 0:
        print(f"dor_check.py: docket {' '.join(args)} failed: {result.stderr.strip()}", file=sys.stderr)
        sys.exit(2)
    payload = json.loads(result.stdout)
    if not payload.get("ok", False):
        print(f"dor_check.py: docket {' '.join(args)} returned ok=false: {payload}", file=sys.stderr)
        sys.exit(2)
    return payload["data"]


def collect_tree_ids(root_id):
    """(all_descendant_ids, direct_child_count) for the tree rooted at root_id,
    walked breadth-first via `docket issue list --parent <id> --all`."""
    from collections import deque

    visited = {root_id}
    all_descendant_ids = []
    direct_child_count = 0
    queue = deque([root_id])
    while queue:
        parent = queue.popleft()
        data = run_docket_json("issue", "list", "--parent", parent, "--all")
        for issue in data.get("issues", []):
            issue_id = issue["id"]
            if issue_id in visited:
                continue
            visited.add(issue_id)
            all_descendant_ids.append(issue_id)
            if parent == root_id:
                direct_child_count += 1
            queue.append(issue_id)
    return all_descendant_ids, direct_child_count


def check_issue(issue, min_desc_length):
    findings = []
    title = (issue.get("title") or "").strip()
    description = (issue.get("description") or "").strip()
    if not title:
        findings.append("FAIL title: empty")
    if not description or len(description) < min_desc_length:
        findings.append(
            f"FAIL description: below heuristic length threshold "
            f"({len(description)} < {min_desc_length} chars) — verify manually "
            f"it states what/where/why/acceptance-criteria"
        )

    labels = set(issue.get("labels") or [])
    if not (labels & MOSCOW_LABELS):
        findings.append(
            f"FAIL scope-label: none of {sorted(MOSCOW_LABELS)} present (labels={sorted(labels)})"
        )

    files = issue.get("files") or []
    if not files:
        findings.append("FAIL files: none attached")

    comments = issue.get("comments") or []
    blocking = [c for c in comments if BLOCKING_MARKERS.search(c.get("body", ""))]
    if blocking:
        excerpt = blocking[0]["body"][:120].replace("\n", " ")
        findings.append(
            f"WARN blocking-question: {len(blocking)} comment(s) match blocking-keyword "
            f'heuristic, e.g. "{excerpt}..."'
        )

    return findings


def main(argv=None):
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("root_id", help="root/epic Docket issue id, e.g. DKT-180")
    parser.add_argument(
        "--expected-count",
        type=int,
        default=None,
        help="expected direct-child-issue count (N); enforces created-child-count == N",
    )
    parser.add_argument(
        "--min-desc-length",
        type=int,
        default=40,
        help="heuristic minimum description length in chars (default: 40)",
    )
    args = parser.parse_args(argv)

    all_descendant_ids, direct_child_count = collect_tree_ids(args.root_id)
    if not all_descendant_ids:
        print(f"dor_check.py: no child issues found under root {args.root_id}", file=sys.stderr)
        return 2

    total_fail = 0
    total_warn = 0
    for issue_id in all_descendant_ids:
        issue = run_docket_json("issue", "show", issue_id)
        findings = check_issue(issue, args.min_desc_length)
        fails = [f for f in findings if f.startswith("FAIL")]
        warns = [f for f in findings if f.startswith("WARN")]
        total_fail += len(fails)
        total_warn += len(warns)
        if not findings:
            print(f"{issue_id}: PASS")
        else:
            status = "FAIL" if fails else "WARN"
            print(f"{issue_id}: {status}")
            for f in findings:
                print(f"  {f}")

    print()
    print(
        f"DoR summary: {len(all_descendant_ids)} issue(s) checked, "
        f"{total_fail} FAIL finding(s), {total_warn} WARN finding(s)"
    )

    count_ok = True
    if args.expected_count is not None:
        count_ok = direct_child_count == args.expected_count
        marker = "OK" if count_ok else "MISMATCH"
        print(
            f"Completeness check: direct children under {args.root_id} = "
            f"{direct_child_count}, expected = {args.expected_count} [{marker}]"
        )

    return 1 if (total_fail > 0 or not count_ok) else 0


if __name__ == "__main__":
    sys.exit(main())
