#!/usr/bin/env python3
"""Drift guard for inlined "skip `--help`" fenced command blocks (DKT-112/DKT-118).

DKT-112 inlined copy-paste-ready fenced-code syntax blocks (dispatch_ledger.sh,
secret_scan.sh, singleton_wait.sh) into team-lead.md, each tagged "skip
`--help` -- this is the complete, current syntax." That label asserts a
freshness nothing previously enforced: if a script's ``Usage:`` line changed
and the inlined block didn't follow, the label would become actively
misleading. This script mechanizes the check.

For every "skip `--help`" occurrence in the target doc, the next fenced
block is taken as the inlined command, matched to its source script by
basename (globbed from ``--scripts-dir``), and compared against that
script's live ``Usage:`` line (a leading ``# Usage:`` comment, or the first
``echo "Usage: ..."`` in a ``usage()`` function, continuation lines included
via trailing ``\\`` markers).

Comparison mode is chosen from the script's own usage text: scripts with
``--flag`` syntax are compared by ordered flag-name sequence plus leading
subcommand (so team-lead.md's elaborated placeholders, e.g.
``--pattern=<Direct|Small|...>`` vs the script's ``--pattern=<pattern>``, are
not false positives -- only an added/removed/renamed/reordered flag is
drift); purely positional scripts are compared by normalized literal text
(stripped of any path prefix and the "Usage:" label).

Exit codes: 0 all inlined blocks in sync (or none found), 1 at least one
diverges or is unresolved, 2 a required path is missing.

Read-only. Never edits, never writes. Stdlib only.
"""

import argparse
import re
import sys
from pathlib import Path

MARKER = "skip `--help`"

# Every doc that currently holds an inlined block. team-lead.md carries all
# three (singleton_wait.sh, secret_scan.sh, dispatch_ledger.sh).
# A block relocated into a doc absent from this list is never scanned and the
# guard passes vacuously, so add any destination in the SAME commit as the move.
# test_drift_guard_check.py re-derives the true set from the tree and fails if
# this list does not cover it.
DEFAULT_DOCS = [
    "src/user/claude-code/agents/team-lead.md",
]

_COMMENT_USAGE_RE = re.compile(r"^#\s*Usage:\s*(.+)$")
_ECHO_LINE_RE = re.compile(r'^echo\s+"(.*)"\s*(?:>&2)?\s*$')


def _strip_continuation(segment):
    """Drop a trailing literal `\\\\` (two backslash chars) continuation
    marker -- the source uses it purely for copy-paste display, never real
    bash line-continuation between separate `echo` statements."""
    stripped = segment.rstrip()
    if stripped.endswith("\\\\"):
        stripped = stripped[:-2].rstrip()
    return stripped


def extract_script_usage(script_path):
    """The script's live Usage syntax (basename onward, "Usage:" label
    stripped), or None if no Usage line is found. Returns the FIRST
    occurrence in file order -- a leading `# Usage:` doc comment takes
    priority over a later `usage()` function's echo, matching which one
    DKT-118's cited anchors reference."""
    lines = script_path.read_text().splitlines()
    for i, raw_line in enumerate(lines):
        line = raw_line.strip()

        m = _COMMENT_USAGE_RE.match(line)
        if m:
            return m.group(1).strip()

        m = _ECHO_LINE_RE.match(line)
        if m and m.group(1).strip().startswith("Usage:"):
            parts = [_strip_continuation(m.group(1))]
            continued = m.group(1).rstrip().endswith("\\\\")
            j = i + 1
            while continued and j < len(lines):
                m2 = _ECHO_LINE_RE.match(lines[j].strip())
                if not m2:
                    break
                continued = m2.group(1).rstrip().endswith("\\\\")
                parts.append(_strip_continuation(m2.group(1)))
                j += 1
            joined = " ".join(p.strip() for p in parts if p.strip())
            return re.sub(r"^Usage:\s*", "", joined).strip()

    return None


def find_inlined_blocks(doc_text, marker=MARKER):
    """(marker_offset, block_content) for every fenced block immediately
    following a `marker` occurrence, in document order."""
    blocks = []
    pos = 0
    while True:
        marker_idx = doc_text.find(marker, pos)
        if marker_idx == -1:
            break
        fence_start = doc_text.find("```", marker_idx)
        if fence_start == -1:
            break
        newline_idx = doc_text.find("\n", fence_start + 3)
        if newline_idx == -1:
            break
        content_start = newline_idx + 1
        fence_end = doc_text.find("```", content_start)
        if fence_end == -1:
            break
        blocks.append((marker_idx, doc_text[content_start:fence_end].strip()))
        pos = fence_end + 3
    return blocks


def compare_usage(script_usage, block_text, basename):
    """Whether `block_text` (an inlined fenced block) is in sync with
    `script_usage` (the script's live Usage syntax). Returns (ok, detail)."""
    idx = block_text.find(basename)
    block_from_script = block_text[idx:] if idx != -1 else block_text

    if "--" in script_usage:
        script_flags = re.findall(r"--[A-Za-z0-9][\w-]*", script_usage)
        block_flags = re.findall(r"--[A-Za-z0-9][\w-]*", block_from_script)

        sub_re = re.compile(re.escape(basename) + r"\s+([A-Za-z_][\w-]*)")
        script_sub_m = sub_re.search(script_usage)
        block_sub_m = sub_re.search(block_from_script)
        script_sub = script_sub_m.group(1) if script_sub_m else None
        block_sub = block_sub_m.group(1) if block_sub_m else None

        ok = script_flags == block_flags and script_sub == block_sub
        detail = (
            f"flags script={script_flags} block={block_flags}; "
            f"subcommand script={script_sub!r} block={block_sub!r}"
        )
        return ok, detail

    norm_script = script_usage.strip()
    norm_block = block_from_script.strip()
    return norm_script == norm_block, f"positional script={norm_script!r} block={norm_block!r}"


def run(doc_paths, scripts_dir):
    # Accepts a set of docs, not just one. All three blocks currently sit in
    # team-lead.md, but the multi-doc path is kept deliberately: a relocation
    # that moves a block elsewhere must be able to declare its new home in the
    # same commit, and an empty scan exits clean, so an undeclared destination
    # would pass vacuously.
    if isinstance(doc_paths, (str, Path)):
        doc_paths = [doc_paths]
    doc_paths = [Path(d) for d in doc_paths]

    for doc_path in doc_paths:
        if not doc_path.is_file():
            print(f"error: file not found: {doc_path}", file=sys.stderr)
            return 2
    if not scripts_dir.is_dir():
        print(f"error: not a directory: {scripts_dir}", file=sys.stderr)
        return 2

    blocks = []
    for doc_path in doc_paths:
        for marker, block_content in find_inlined_blocks(doc_path.read_text()):
            blocks.append((doc_path, block_content))
    if not blocks:
        scanned = ", ".join(str(d) for d in doc_paths)
        print(f"drift-guard: none found ({MARKER!r} not present in {scanned})")
        return 0

    multi = len(doc_paths) > 1
    basenames = sorted(p.name for p in scripts_dir.glob("*.sh"))
    mismatches = 0
    for doc_path, block_content in blocks:
        where = f"[{doc_path.name}] " if multi else ""
        matched = [b for b in basenames if b in block_content]
        if not matched:
            print(f"  UNRESOLVED  {where}no known script referenced in block: {block_content!r}")
            mismatches += 1
            continue
        if len(matched) > 1:
            print(f"  UNRESOLVED  {where}ambiguous script match {matched} for block: {block_content!r}")
            mismatches += 1
            continue

        basename = matched[0]
        script_usage = extract_script_usage(scripts_dir / basename)
        if script_usage is None:
            print(f"  UNRESOLVED  {where}{basename} -- no Usage: line found in script")
            mismatches += 1
            continue

        ok, detail = compare_usage(script_usage, block_content, basename)
        print(f"  {'OK' if ok else 'DRIFT':<10} {where}{basename} -- {detail}")
        if not ok:
            mismatches += 1

    if mismatches:
        print(f"drift-guard: FAIL ({mismatches} of {len(blocks)} inlined block(s) diverge from their script's Usage line)")
        return 1
    print(f"drift-guard: OK ({len(blocks)} inlined block(s) in sync with their script's Usage line)")
    return 0


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument(
        "--doc",
        action="append",
        dest="docs",
        metavar="DOC",
        help=(
            "markdown file to scan for inlined 'skip `--help`' fenced blocks; repeatable. "
            f"Default: {' + '.join(DEFAULT_DOCS)} (invoke from repo root). "
            "The default set must name EVERY doc holding an inlined block -- a block "
            "relocated into a doc nobody scans passes vacuously."
        ),
    )
    parser.add_argument(
        "--scripts-dir",
        default="src/user/claude-code/scripts",
        help="directory of *.sh scripts to resolve inlined blocks against (default: src/user/claude-code/scripts)",
    )
    args = parser.parse_args(argv)
    return run([Path(d) for d in (args.docs or DEFAULT_DOCS)], Path(args.scripts_dir))


if __name__ == "__main__":
    sys.exit(main())
