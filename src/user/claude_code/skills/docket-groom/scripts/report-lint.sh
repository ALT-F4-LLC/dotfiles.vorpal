#!/usr/bin/env bash
#
# report-lint — check a draft docket-groom report or mid-pass turn closing
# for hand-backs: work the pass could have finished, worded as a loose end.
# A pass that ends a turn on a "still open" list, or reports "your call" or
# "not re-judged", leaves the operator to drive the rest.
#
# Usage: report-lint.sh [draft.txt]      (reads stdin without a file)
#
# A line is a hand-back when it holds, in any case, one of: "still open",
# "still to do", "open items", "remaining items", "your call",
# "up to you", "not re-judged", "did not re-judge", "not yet proposed", "matches
# its siblings", "check belongs with", "re-run to", "want me to", "let me know";
# or "waiting on <PREFIX-N>" with no route in parentheses after the id, since
# a prerequisite named without its route hides one no run can reach.
# Gate states name their own gap instead: "blocked on the operator: <input
# needed>", "waiting on <id> (route-run)", "waiting on direct work: <id>
# (<route>)", "waiting on <named condition>", "declined #<n>", "held by protection", or
# "reported limit: <blocker>".
#
# Read-only. Exit 0 with no output when the draft holds no hand-back, 1 with
# one `line <n>: <text>` per hand-back on stdout, 2 on a usage error or an
# unreadable file.

set -euo pipefail

if [ $# -gt 1 ]; then
    printf 'usage: report-lint.sh [draft.txt]\n' >&2
    exit 2
fi
if [ $# -eq 1 ] && [ ! -r "$1" ]; then
    printf 'report-lint: cannot read %s\n' "$1" >&2
    exit 2
fi

pattern='waiting on [a-z]+-[0-9]+([^ (0-9]|$| [^(])|still open|still to do|\bopen items|remaining items|your call|up to you|not re-judged|did not re-judge|not yet proposed|(check|criterion|criteria) (that )?belongs? (with|on)|match(es|ing) (its )?siblings|re-run to|want me to|let me know'

# grep exits 1 on no match; that is the clean case.
if grep -n -i -E -- "$pattern" "${1:--}" | sed -E 's/^([0-9]+):/line \1: /'; then
    exit 1
fi
exit 0
