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

``--xref <doc-b>`` switches to numbered-cross-reference reconciliation between
``artifact`` (doc A) and ``<doc-b>`` — staff-engineer.md's
"Numbered-cross-reference reconciliation." It extracts ``decision N`` / ``§N``
/ ``item (x)`` cross-references from BOTH docs and reconciles each against the
authoritative numbering DEFINED across the pair (a decision heading/label, a
numbered section heading, an enumerated ``(x)`` list leader). A referenced
number with no matching definition anywhere in the pair is DANGLING drift.
Only this decidable half is mechanized; "one fact cited under two different
decision numbers" needs semantic fact-identity and stays a reviewer judgment.

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


# Numbered cross-reference classes. Each class has a REFERENCE regex (a
# free-floating citation) and a DEFINITION regex (where the number is
# authoritatively established). Group 1 is the number/label in every pattern.
_XREF_REF = {
    "decision": re.compile(r"\bdecision\s+(\d+)\b", re.IGNORECASE),
    "section": re.compile(r"§\s*(\d+(?:\.\d+)*)"),
    "item": re.compile(r"\bitem\s*\(([A-Za-z0-9]+)\)", re.IGNORECASE),
}
_XREF_DEF = {
    # A decision is DEFINED by a heading or a bold/colon label.
    "decision": re.compile(
        r"(?:^#{1,6}\s+.*?|\*\*\s*)decision\s+(\d+)\b|"
        r"\bdecision\s+(\d+)\s*[:—-]",
        re.IGNORECASE | re.MULTILINE,
    ),
    # A section is DEFINED by a numbered heading (## 3, ### 3.1) or a §N heading.
    "section": re.compile(
        r"^#{1,6}\s+(?:§\s*)?(\d+(?:\.\d+)*)\b", re.MULTILINE
    ),
    # An item is DEFINED by a list/paragraph leader that starts with (x).
    "item": re.compile(r"^\s*(?:[-*]\s*)?\(([A-Za-z0-9]+)\)\s", re.MULTILINE),
}


def _norm(num):
    return num.lower()


def extract_xrefs(text):
    """De-duped (klass, number, is_definition) is not returned; instead return
    two structures: references [(klass, number)] in first-seen order, and the
    set of DEFINED numbers per class. Fenced code blocks are stripped first."""
    stripped = _FENCE_RE.sub("", text)

    defined = {klass: set() for klass in _XREF_DEF}
    for klass, rex in _XREF_DEF.items():
        for m in rex.finditer(stripped):
            num = next((g for g in m.groups() if g is not None), None)
            if num is not None:
                defined[klass].add(_norm(num))

    references = []
    seen = set()
    for klass, rex in _XREF_REF.items():
        for m in rex.finditer(stripped):
            num = _norm(m.group(1))
            key = (klass, num)
            if key in seen:
                continue
            seen.add(key)
            references.append(key)
    return references, defined


def run_xref(doc_a, doc_b):
    """Reconcile numbered cross-references between two coupled docs. Returns an
    exit code: 0 all resolved, 1 at least one dangling, 2 a doc is unreadable."""
    for p in (doc_a, doc_b):
        if not p.is_file():
            print(f"error: file not found: {p}", file=sys.stderr)
            return 2

    refs_a, def_a = extract_xrefs(doc_a.read_text())
    refs_b, def_b = extract_xrefs(doc_b.read_text())

    # Authoritative numbering is shared across the coupled pair.
    authoritative = {
        klass: def_a[klass] | def_b[klass] for klass in _XREF_DEF
    }

    dangling = 0
    total = 0
    for label, refs in ((str(doc_a), refs_a), (str(doc_b), refs_b)):
        if not refs:
            continue
        print(f"{label}:")
        for klass, num in refs:
            total += 1
            ok = num in authoritative[klass]
            token = {"decision": f"decision {num}", "section": f"§{num}", "item": f"item ({num})"}[klass]
            print(f"  {'OK' if ok else 'DANGLING':<9} {token}")
            if not ok:
                dangling += 1

    defined_total = sum(len(v) for v in authoritative.values())
    if total == 0:
        print(f"xref: none found across the pair ({defined_total} definition(s) present)")
        return 0
    if dangling:
        print(f"xref: DANGLING ({dangling} of {total} reference(s) resolve to no definition in the pair)")
        return 1
    print(f"xref: OK ({total} reference(s), all resolve to {defined_total} definition(s) in the pair)")
    return 0


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("artifact", help="markdown file to scan for path-like citations (doc A in --xref mode)")
    parser.add_argument("--base", default=".", help="root to resolve relative citations against (default: cwd)")
    parser.add_argument("--xref", metavar="DOC_B", help="reconcile numbered cross-references between artifact and DOC_B")
    args = parser.parse_args(argv)

    if args.xref:
        return run_xref(Path(args.artifact), Path(args.xref))

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
