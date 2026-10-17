#!/bin/bash

# Count the unresolved items in a docket-groom ledger file.
#
# usage: ledger-open.sh [--final] <ledger.json>
#
# Prints "open=<n>" and one line per open item. Exit 0 when n is 0, 1 when
# items are open, 2 on an unreadable ledger or a goal ledger with no entries.
# A non-epic ledger entry (judged unless "judged": false) is open
# unless its "state" is one of the terminal states below; a gap in the
# top-level "gaps" array is open until it carries a non-empty "resolution".
# A ledger with "mode": "goal" belongs to an unattended pass, where the
# operator-blocked and declined states do not exist, so they count as open.
# --final also requires "verified": true (the advisor's review of the
# terminal states) and prints "verified=false" when it is missing.
#
# The completion gate, the Stop hook, and the pass itself all read this
# output, so the model's own "reported" flag never decides completion.

set -uo pipefail

FINAL=0
LEDGER=""
for a in "$@"; do
    if [ "$a" = "--final" ]; then FINAL=1; else LEDGER="$a"; fi
done
[ -n "$LEDGER" ] && [ -r "$LEDGER" ] || { echo "ledger-open.sh: unreadable ledger" >&2; exit 2; }
command -v jq >/dev/null 2>&1 || { echo "ledger-open.sh: jq is required" >&2; exit 2; }

OUT=$(jq -r --argjson final "$FINAL" '
  (.mode == "goal") as $goal
  | (["run-ready", "waiting", "retired", "held", "limit"]
     + (if $goal then [] else ["operator-blocked", "declined"] end)) as $terminal
  | if $goal and ((.ledger // []) | length) == 0 then error("goal ledger has no entries") else . end
  | [ ((.ledger // [])[] | select(.judged != false and .kind != "epic")
        | select(((.state // "open") | IN($terminal[])) | not)
        | "issue \(.id): state \(.state // "unset")"),
      ((.gaps // [])[] | select((.resolution // "") == "")
        | "gap \(.id // .issue // "?"): unresolved") ] as $open
  | "open=\($open | length)", $open[],
    (if $final == 1 and .verified != true then "verified=false" else empty end)
' "$LEDGER" 2>/dev/null) || { echo "ledger-open.sh: ledger is not valid JSON" >&2; exit 2; }

printf '%s\n' "$OUT"
[ "$(printf '%s\n' "$OUT" | sed -n 1p)" = "open=0" ] || exit 1
printf '%s\n' "$OUT" | grep -q '^verified=false$' && exit 1
exit 0
