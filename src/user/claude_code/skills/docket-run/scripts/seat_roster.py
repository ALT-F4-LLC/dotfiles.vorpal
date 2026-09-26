"""Resolve a conversational gate's voters from the pinned policy.

Usage: python3 seat_roster.py <seat,seat,...> [policy.toml]

Prints the `voters` array tribunal.js takes for a conversational gate: one
{seat, model, effort, variant} per seat named, each a lookup from the
policy's [executors] and [variants] tables, never a choice. The policy
defaults to ~/.docket/config/policy.toml; the second argument exists so a
test can point at a fixture. A seat or variant the file does not carry is a
non-zero exit naming the partial rows, never a voter with a null field
(tribunal.js refuses those anyway).

No tomllib before Python 3.11 (the operator's python3 has been 3.9), so the
two inline tables are read directly: [executors] rows are
`seat = { variant = "..." }`, [variants] rows are
`name = { model = "...", effort = "...", ... }`.

This file exists because the same program as an inline heredoc
(`python3 - <<'PY'`) is an interpreter code argument, which the auto-mode
deny rule refuses before it runs.
"""

import json
import os
import re
import sys


def table(text, name):
    match = re.search(
        r"^\[" + re.escape(name) + r"\][^\n]*\n(.*?)(?=^\[|\Z)", text, re.S | re.M
    )
    return match.group(1) if match else ""


def inline(tbl, key):
    match = re.search(r"^" + re.escape(key) + r"\s*=\s*\{([^}]*)\}", tbl, re.M)
    if not match:
        return {}
    return dict(re.findall(r"([A-Za-z_]+)\s*=\s*\"([^\"]*)\"", match.group(1)))


def roster(text, seats):
    executors, variants = table(text, "executors"), table(text, "variants")
    out = []
    for seat in seats:
        variant = inline(executors, seat).get("variant")
        v = inline(variants, variant) if variant else {}
        out.append(
            {
                "seat": seat,
                "model": v.get("model"),
                "effort": v.get("effort"),
                "variant": variant,
            }
        )
    return out


def main(argv):
    if len(argv) not in (2, 3):
        raise SystemExit("usage: seat_roster.py <seat,seat,...> [policy.toml]")
    seats = [s for s in argv[1].split(",") if s]
    if not seats:
        raise SystemExit("seat_roster: no seats named")
    path = argv[2] if len(argv) == 3 else os.path.expanduser("~/.docket/config/policy.toml")
    with open(path, encoding="utf-8") as handle:
        text = handle.read()
    out = roster(text, seats)
    if not all(all(row.values()) for row in out):
        # A null field means the seat or the variant is not in the file.
        raise SystemExit(
            "seat_roster: a seat or variant is missing from " + path + ": " + json.dumps(out)
        )
    print(json.dumps(out))


if __name__ == "__main__":
    main(sys.argv)
