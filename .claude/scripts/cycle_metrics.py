#!/usr/bin/env python3
"""Aggregates .claude/agent-memory/team-lead/dispatch-ledger.md (team-lead.md
step 16 instrumentation) into fix_rounds rate, review_spawns_total
distribution, DEGRADED-fallback count, and pattern mix — with named
thresholds that mandate an evolve-* review when blown.

Ledger line schema (write side: .claude/scripts/dispatch_ledger.sh):
  {YYYY-MM-DD} | cycle={slug} | pattern={value} | review={value} |
  verify={value} | votes={value} | fix_rounds={value} |
  review_spawns_total={value} [| note={value}]

Thresholds are evaluated over a rolling window of the most recent
ROLLING_WINDOW ledger lines (recency-sensitive — a regression should not be
diluted by old green cycles), and only once the window holds at least
MIN_SAMPLE_SIZE entries (a near-empty ledger must not false-positive).
Threshold VALUES below are initial estimates with no historical baseline
(consult: advisor, DKT-187) — tune as the ledger fills; each is a named
module-level constant for a one-line edit, not a logic hunt.

Read-only. Never edits, never writes. Stdlib only.
"""

import argparse
import sys
from collections import Counter
from pathlib import Path

LEDGER_PATH = ".claude/agent-memory/team-lead/dispatch-ledger.md"

ROLLING_WINDOW = 10  # most recent N cycles considered per threshold
MIN_SAMPLE_SIZE = 5  # minimum cycles in window before any threshold is evaluated
FIX_ROUNDS_RATE_THRESHOLD = 0.5  # fraction of windowed cycles with fix_rounds>=1
REVIEW_SPAWNS_AVG_THRESHOLD = 3.0  # average review_spawns_total per windowed cycle
DEGRADED_COUNT_THRESHOLD = 2  # count of DEGRADED-fallback notes within the window


def parse_ledger(path):
    entries = []
    for lineno, raw in enumerate(path.read_text().splitlines(), start=1):
        line = raw.strip()
        if not line:
            continue
        parts = [p.strip() for p in line.split("|")]
        if len(parts) < 2:
            print(f"cycle_metrics.py: skipping unparseable line {lineno}: {line!r}", file=sys.stderr)
            continue
        entry = {"date": parts[0], "_raw": line}
        for field in parts[1:]:
            if "=" not in field:
                continue
            key, _, value = field.partition("=")
            entry[key.strip()] = value.strip()
        entries.append(entry)
    return entries


def to_int(value):
    if value is None:
        return None
    try:
        return int(value)
    except ValueError:
        return None


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--ledger", default=LEDGER_PATH, help=f"path to dispatch ledger (default: {LEDGER_PATH})")
    args = parser.parse_args(argv)

    ledger_path = Path(args.ledger)
    if not ledger_path.is_file():
        print(f"cycle_metrics.py: no ledger found at {ledger_path} (nothing dispatched yet)", file=sys.stderr)
        return 0

    entries = parse_ledger(ledger_path)
    total = len(entries)
    print(f"Ledger: {ledger_path} ({total} total cycle(s) recorded)")
    if total == 0:
        print("No entries to analyze.")
        return 0

    window = entries[-ROLLING_WINDOW:]
    window_n = len(window)
    print(f"Rolling window: last {window_n} of {total} cycle(s) (ROLLING_WINDOW={ROLLING_WINDOW})")
    print()

    # Pattern mix, over the window (recency-sensitive, matching the threshold metrics)
    pattern_mix = Counter(e.get("pattern", "?") for e in window)
    print("Pattern mix (windowed):")
    for pattern, count in pattern_mix.most_common():
        print(f"  {pattern}: {count}")
    print()

    blown = []

    if window_n < MIN_SAMPLE_SIZE:
        print(f"Thresholds: insufficient data (window={window_n} < MIN_SAMPLE_SIZE={MIN_SAMPLE_SIZE}) — not evaluated")
    else:
        fix_rounds_ints = [to_int(e.get("fix_rounds")) for e in window]
        flagged = sum(1 for v in fix_rounds_ints if v is not None and v >= 1)
        parseable = sum(1 for v in fix_rounds_ints if v is not None)
        fix_rounds_rate = (flagged / window_n) if window_n else 0.0
        fix_rounds_blown = fix_rounds_rate > FIX_ROUNDS_RATE_THRESHOLD
        print(
            f"fix_rounds rate: {flagged}/{window_n} cycles had fix_rounds>=1 "
            f"({fix_rounds_rate:.2f}, threshold >{FIX_ROUNDS_RATE_THRESHOLD}) "
            f"[{'BLOWN' if fix_rounds_blown else 'OK'}] ({parseable}/{window_n} fix_rounds values parseable)"
        )
        if fix_rounds_blown:
            blown.append("fix_rounds rate")

        review_spawns_ints = [v for v in (to_int(e.get("review_spawns_total")) for e in window) if v is not None]
        if review_spawns_ints:
            review_spawns_avg = sum(review_spawns_ints) / len(review_spawns_ints)
            review_spawns_blown = review_spawns_avg > REVIEW_SPAWNS_AVG_THRESHOLD
            print(
                f"review_spawns_total avg: {review_spawns_avg:.2f} over {len(review_spawns_ints)} parseable "
                f"cycle(s) (threshold >{REVIEW_SPAWNS_AVG_THRESHOLD}) [{'BLOWN' if review_spawns_blown else 'OK'}]"
            )
            if review_spawns_blown:
                blown.append("review_spawns_total avg")
        else:
            print("review_spawns_total avg: no parseable values in window — not evaluated")

        degraded_count = sum(1 for e in window if "DEGRADED" in e.get("note", ""))
        degraded_blown = degraded_count >= DEGRADED_COUNT_THRESHOLD
        print(
            f"DEGRADED-fallback count: {degraded_count} in window "
            f"(threshold >={DEGRADED_COUNT_THRESHOLD}) [{'BLOWN' if degraded_blown else 'OK'}]"
        )
        if degraded_blown:
            blown.append("DEGRADED-fallback count")

    print()
    if blown:
        print(f"MANDATORY EVOLVE-* REVIEW: YES — blown threshold(s): {', '.join(blown)}")
        return 1
    print("MANDATORY EVOLVE-* REVIEW: NO")
    return 0


if __name__ == "__main__":
    sys.exit(main())
