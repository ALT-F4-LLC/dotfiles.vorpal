#!/usr/bin/env python3
"""Numbered cross-reference reconciliation for two (or three) documents.

Automates staff-engineer.md's "No Guessing" numbered-cross-reference
reconciliation ritual: confirming that numbered references (``decision 4``,
``item (c)``, a bare ``(c)`` enumerated-list marker, ``ADR-4``, ``§4``) in
one document still match the numbering used in another, instead of a
hand-grep-both-docs pass.

The pattern set is centralized in the module-level ``PATTERNS`` list below —
that list IS the "configurable/generic" surface (edit it to add a class or
adjust a regex); there is deliberately no ``--pattern`` CLI flag.

Usage:
    xref_check.py DOC_A DOC_B
        Extract tokens from both documents and report a symmetric diff:
        tokens present in DOC_A but not DOC_B, and vice-versa.

    xref_check.py DOC_A DOC_B --authority CANONICAL
        Treat CANONICAL as the third, authoritative source and diff BOTH
        DOC_A and DOC_B against it (two symmetric diffs) instead of DOC_A
        and DOC_B against each other.

Exit codes: 0 all tokens reconcile, 1 at least one mismatched/missing token,
2 a given path is not a file.

Read-only. Never edits, never writes. Stdlib only.
"""

import argparse
import re
import sys
from pathlib import Path

# Named, compiled, case-insensitive cross-reference token patterns. Group 1
# is always the captured number/label. This list is the single place to add
# or adjust a reference class -- "configurable/generic" means editing this
# list, not a CLI flag.
PATTERNS = [
    ("decision", re.compile(r"\bdecision\s+(\d+)", re.IGNORECASE)),
    ("item", re.compile(r"\bitem\s+\(([a-z0-9]+)\)", re.IGNORECASE)),
    ("enum", re.compile(r"\(([a-z0-9]+)\)", re.IGNORECASE)),
    ("adr", re.compile(r"\bADR-(\d+)\b", re.IGNORECASE)),
    ("section", re.compile(r"§\s*(\d+)", re.IGNORECASE)),
]

# Display template per pattern name, used to render a token back to prose.
_DISPLAY = {
    "decision": "decision {}",
    "item": "item ({})",
    "enum": "({})",
    "adr": "ADR-{}",
    "section": "§{}",
}


def extract_tokens(text):
    """De-duped set of (pattern_name, normalized_value) tokens found in
    `text`, across every entry in PATTERNS."""
    tokens = set()
    for name, pattern in PATTERNS:
        for m in pattern.finditer(text):
            tokens.add((name, m.group(1).lower()))
    return tokens


def _render(token):
    name, value = token
    return _DISPLAY[name].format(value)


def report_diff(label_a, label_b, tokens_a, tokens_b):
    """Print each token present in one side but not the other. Returns the
    count of mismatched/missing tokens found."""
    only_a = sorted(tokens_a - tokens_b)
    only_b = sorted(tokens_b - tokens_a)

    for token in only_a:
        print(f"  MISMATCH  {_render(token)} in {label_a}, missing from {label_b}")
    for token in only_b:
        print(f"  MISMATCH  {_render(token)} in {label_b}, missing from {label_a}")

    return len(only_a) + len(only_b)


def run(doc_a, doc_b, authority=None):
    """Reconcile numbered cross-references. Returns an exit code: 0 all
    resolved, 1 at least one mismatch, 2 a path is not a file."""
    paths = [doc_a, doc_b] + ([authority] if authority else [])
    for p in paths:
        if not p.is_file():
            print(f"error: file not found: {p}", file=sys.stderr)
            return 2

    tokens_a = extract_tokens(doc_a.read_text())
    tokens_b = extract_tokens(doc_b.read_text())

    if authority:
        tokens_auth = extract_tokens(authority.read_text())
        mismatches = report_diff(str(authority), str(doc_a), tokens_auth, tokens_a)
        mismatches += report_diff(str(authority), str(doc_b), tokens_auth, tokens_b)
        total = len(tokens_auth | tokens_a | tokens_b)
    else:
        mismatches = report_diff(str(doc_a), str(doc_b), tokens_a, tokens_b)
        total = len(tokens_a | tokens_b)

    if total == 0:
        print("xref: none found across the document(s)")
        return 0
    if mismatches:
        print(f"xref: MISMATCH ({mismatches} mismatched/missing token(s) of {total})")
        return 1
    print(f"xref: OK ({total} token(s), all reconcile)")
    return 0


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("doc_a", help="first document path")
    parser.add_argument("doc_b", help="second document path")
    parser.add_argument("--authority", help="third canonical source; diff BOTH doc_a and doc_b against it instead of against each other")
    args = parser.parse_args(argv)

    authority = Path(args.authority) if args.authority else None
    return run(Path(args.doc_a), Path(args.doc_b), authority)


if __name__ == "__main__":
    sys.exit(main())
