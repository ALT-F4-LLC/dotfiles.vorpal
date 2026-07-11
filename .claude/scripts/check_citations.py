#!/usr/bin/env python3
"""Citation checker for markdown artifacts (TDDs, review verdicts, advisories).

Extracts path-like citations from inline code spans (`` `docs/tdd/foo.md` ``,
`` `src/main.rs:42` ``) and verifies each resolves on disk, relative to
``--base`` (default: cwd — invoke from the repo root). Automates the
path-existence half of staff-engineer.md's No Guessing discipline; the
"captured-resolution grounding" half (is a recalled resolution actually
mandated by the owning agent spec?) remains a semantic-judgment call for the
reviewing agent, not this script.

Fenced code blocks (```...```) are stripped before extraction so code
listings are never mistaken for citations. A trailing ``:NN`` or ``:NN-NN``
line-number suffix is stripped before the existence check. Glob patterns
(containing ``*``) are matched with ``Path.glob`` and count as resolved if
at least one match exists. ``~``-prefixed paths are expanded but not
glob-matched.

Read-only. Never edits, never writes. Stdlib only.
"""

import argparse
import re
import sys
from pathlib import Path

_FENCE_RE = re.compile(r"```.*?```", re.DOTALL)
_INLINE_CODE_RE = re.compile(r"`([^`\n]+)`")

# A path-like token: an optional ~/ or ./ or ../ prefix, one or more
# directory segments ending in '/', then an optional final filename/glob
# segment, then an optional :LINE or :LINE-LINE suffix. The lookbehind/
# lookahead keep matches on word/path boundaries (e.g. never mid-URL).
_PATH_RE = re.compile(
    r"(?<![\w/.~-])"
    r"(?P<path>(?:~/|\.{1,2}/)?(?:[\w*.-]+/)+[\w*.-]*)"
    r"(?::(?P<line>\d+(?:-\d+)?))?"
    r"(?![\w/<>-])"
)


def _looks_like_path(path: str) -> bool:
    """Filter out slash-separated prose ("and/or", "3/4") that the bare
    _PATH_RE grammar would otherwise catch. A real citation has a trailing
    slash (directory), a glob, or a file extension."""
    return path.endswith("/") or "*" in path or bool(re.search(r"\.[A-Za-z0-9]{1,10}$", path))


def extract_citations(text):
    """De-duped (path, line_suffix) pairs, in first-seen order, found inside
    inline code spans of `text` (fenced code blocks are stripped first)."""
    stripped = _FENCE_RE.sub("", text)
    seen = set()
    citations = []
    for span_match in _INLINE_CODE_RE.finditer(stripped):
        for m in _PATH_RE.finditer(span_match.group(1)):
            path = m.group("path")
            if not _looks_like_path(path):
                continue
            key = (path, m.group("line"))
            if key in seen:
                continue
            seen.add(key)
            citations.append(key)
    return citations


def citation_exists(path_str, base):
    """Whether `path_str` (line-suffix already stripped) resolves under `base`."""
    if path_str.startswith("~"):
        return Path(path_str).expanduser().exists()
    if "*" in path_str:
        try:
            return any(base.glob(path_str))
        except (ValueError, NotImplementedError):
            return False
    return (base / path_str).exists()


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("artifact", help="markdown file to scan for path-like citations")
    parser.add_argument("--base", default=".", help="root to resolve relative citations against (default: cwd)")
    args = parser.parse_args(argv)

    artifact_path = Path(args.artifact)
    if not artifact_path.is_file():
        print(f"error: file not found: {artifact_path}", file=sys.stderr)
        return 2

    base = Path(args.base)
    citations = extract_citations(artifact_path.read_text())

    if not citations:
        print(f"citations: none found in {artifact_path}")
        return 0

    missing = 0
    for path, line in citations:
        ok = citation_exists(path, base)
        suffix = f":{line}" if line else ""
        print(f"  {'OK' if ok else 'MISSING':<7} {path}{suffix}")
        if not ok:
            missing += 1

    if missing:
        print(f"citations: MISSING ({missing} of {len(citations)} not found)")
        return 1
    print(f"citations: OK ({len(citations)} found, all resolved)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
