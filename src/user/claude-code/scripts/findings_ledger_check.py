#!/usr/bin/env python3
"""Mechanizes the evolve-skills/evolve-agents Phase-2 gate: a cycle's Findings
Ledger (`{scratchpad}/findings-ledger.md`, CANONICAL:IMPACT-CLASS) must carry
exactly one terminal disposition per finding before Phase 2 may start. This
currently depends on orchestrator diligence reading the file by eye; this
script makes it a deterministic pre-Phase-2 gate.

Ledger grammar (normative; no existing consumer yet -- this is the reference
definition for the format the orchestrator Writes and this script Reads):
  - Each finding is one column-0 bullet: `- <ID>: <summary...>` where <ID> is
    a short alnum token (e.g. H1, B2, I3) -- one uppercase-letter-led auditor
    tag followed by digits, matching the IDs the orchestrator assigns per
    CANONICAL:IMPACT-CLASS ("H1, B2, I3, ...").
  - An entry's terminal disposition is one of the five literal keywords
    (APPLIED-SUBSTANTIVE, APPLIED-COSMETIC, REJECTED, DEFERRED,
    ALREADY-ENCODED) followed by a non-empty `(...)` evidence span, anywhere
    within the entry's text (the entry spans from its bullet line to the
    line before the next `- <ID>:` bullet, or EOF).
  - An entry with no disposition keyword is OPEN (blocks Phase 2). An entry
    whose disposition keyword has no evidence, or empty `()`, is
    EVIDENCE-LESS (per the "disposition missing its parenthesized evidence
    is INVALID" rule) -- both are reject-class and non-zero-exit findings.

Exit codes: 0 = every entry present carries a valid disposition + evidence
(including the case of zero entries -- an empty ledger has nothing to gate
on); 1 = at least one entry is OPEN or EVIDENCE-LESS; 2 = the ledger file is
missing, empty, or has no parseable entries at all (a precondition failure,
distinct from "zero findings this cycle" -- an evolve cycle always Writes
the file, even if empty, at Phase 0 completion).
"""
import re
import sys

DISPOSITIONS = (
    "APPLIED-SUBSTANTIVE",
    "APPLIED-COSMETIC",
    "REJECTED",
    "DEFERRED",
    "ALREADY-ENCODED",
)

ENTRY_START_RE = re.compile(r"^- ([A-Z][0-9]+): ")
DISPOSITION_RE = re.compile(
    r"(" + "|".join(DISPOSITIONS) + r")\s*\(([^)]*)\)"
)


def parse_entries(text):
    """Returns a list of (id, entry_text) for each column-0 `- <ID>: ` bullet."""
    lines = text.splitlines()
    starts = []
    for i, line in enumerate(lines):
        m = ENTRY_START_RE.match(line)
        if m:
            starts.append((i, m.group(1)))
    entries = []
    for idx, (line_no, entry_id) in enumerate(starts):
        end = starts[idx + 1][0] if idx + 1 < len(starts) else len(lines)
        entries.append((entry_id, "\n".join(lines[line_no:end])))
    return entries


def check_entry(entry_id, entry_text):
    """Returns None if valid, else a short reason string."""
    m = DISPOSITION_RE.search(entry_text)
    if not m:
        return "OPEN (no terminal disposition)"
    evidence = m.group(2).strip()
    if not evidence:
        return f"EVIDENCE-LESS ({m.group(1)} has empty evidence)"
    return None


def main(argv):
    if len(argv) != 2:
        print("Usage: findings_ledger_check.py <path-to-findings-ledger.md>", file=sys.stderr)
        return 2

    path = argv[1]
    try:
        with open(path, "r") as f:
            text = f.read()
    except OSError as exc:
        print(f"findings_ledger_check.py: cannot read {path}: {exc}", file=sys.stderr)
        return 2

    entries = parse_entries(text)
    if not entries:
        print(f"findings_ledger_check.py: no `- <ID>: ` entries found in {path}", file=sys.stderr)
        return 2

    failed = 0
    for entry_id, entry_text in entries:
        reason = check_entry(entry_id, entry_text)
        if reason is None:
            print(f"[OK] {entry_id}")
        else:
            print(f"[FAIL] {entry_id}: {reason}")
            failed += 1

    print(f"{len(entries) - failed}/{len(entries)} dispositioned")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
