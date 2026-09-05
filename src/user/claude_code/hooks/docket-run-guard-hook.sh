#!/bin/bash

# Let the engine decide whether this project's work prevents a stop. The
# current guard already allows absent stores and ignores other projects.
# Hook exceptions cover asynchronous dispatches, paused/planning runs, and
# runs whose pins prevent further dispatch.
# Unreadable or incomplete engine responses cannot establish an exception.

set -uo pipefail

allow() { exit 0; }
deny() { printf '%s\n' "$1" >&2; exit 2; }

DATA=$(cat 2>/dev/null) || allow
if command -v jq >/dev/null 2>&1; then
    STOP_HOOK_ACTIVE=$(printf '%s' "$DATA" | jq -r '.stop_hook_active // false' 2>/dev/null) \
        || STOP_HOOK_ACTIVE="false"
    # A repeated block must not trap the session in a Stop-hook loop.
    [ "$STOP_HOOK_ACTIVE" = "true" ] && allow
fi

command -v docket >/dev/null 2>&1 || allow
REASON=$(docket guard stop 2>&1 >/dev/null) && allow

# An open dispatch or outstanding reconciliation permits yielding while the
# workflow finishes outside this turn. Exit 2 also covers CLI read errors,
# so require the engine's affirmative reason, not merely that exit code.
# Human-mode reasons keep this path available without jq. Unknown wording
# stays a denial until the engine contract is checked again.
RECORD_REASON=$(NO_COLOR=1 docket guard record 2>&1 >/dev/null)
RECORD_EXIT=$?
if [ "$RECORD_EXIT" -eq 2 ]; then
    OPEN_REASON='^Error: RUN-[0-9]+ has an open dispatch: DISPATCH-[0-9]+ expiring at [0-9]+ — reconcile with .+$'
    RECONCILE_REASON='^Error: RUN-[0-9]+ has [1-9][0-9]* unreconciled discrepancy\(s\) and will not be offered new work until they are resolved: .+$'
    [[ "$RECORD_REASON" =~ $OPEN_REASON || "$RECORD_REASON" =~ $RECONCILE_REASON ]] && allow
fi

# --active filters before --limit; zero removes the run list's default cap
# of 50. Check total as well so a partial response never hides an older run.
# Empty means unknown here. An affirmative empty list does not override a
# denial from the project-scoped engine guard.
LIVE_RUNS=""
if command -v jq >/dev/null 2>&1; then
    LIVE_RUNS=$(docket run status --active --limit 0 --json 2>/dev/null \
        | jq -sce '
            select(length == 1) | .[0]
            | select(.ok == true) | .data
            | select((.runs | type) == "array")
            | select(.total == (.runs | length))
            | select(all(.runs[];
                (.run | type) == "string" and (.run | test("^RUN-[0-9]+$"))
                and (.status | type) == "string" and .status != ""))
            | select(([.runs[].run] | unique | length) == (.runs | length))
            | .runs
          ' 2>/dev/null) || LIVE_RUNS=""
fi

if [ -n "$LIVE_RUNS" ]; then
    # Pausing a run leaves pending steps. Planning runs have no activated work.
    printf '%s' "$LIVE_RUNS" \
        | jq -e 'length > 0 and all(.[]; .status == "waiting-human" or .status == "planning")' \
            >/dev/null 2>&1 && allow
fi

# GuardStop already exempts never-dispatched runs whose steps are all pending.
# Event absence cannot establish that exemption: direct claims or records can
# give a run step history without opening any dispatch, and events can prune.
RUNS=""
if [ -n "$LIVE_RUNS" ]; then
    RUNS=$(printf '%s' "$LIVE_RUNS" | jq -r '.[].run' 2>/dev/null) || RUNS=""
fi
if [ -n "$RUNS" ]; then
    # Exit 4 affirmatively reports changed pins. Exit 2 can also mean an
    # unrelated CLI error, so it must not be treated as evidence of drift.
    ALL_DRIFTED=1
    for R in $RUNS; do
        docket run verify-pins "$R" >/dev/null 2>&1
        [ "$?" -eq 4 ] || { ALL_DRIFTED=0; break; }
    done
    if [ "$ALL_DRIFTED" = "1" ]; then
        printf 'run-guard: stop allowed; every live run here (%s) has drifted pins. Inspect `docket run verify-pins <run>` before resuming dispatch.\n' \
            "${RUNS//$'\n'/ }" >&2
        allow
    fi
fi

[ -n "$REASON" ] || REASON="an active run still has work in flight"
deny "Session stop blocked by run-guard: ${REASON}. Finish or dispatch the named work. If an external dependency, permission, or operator decision blocks it, report that blocker; the next Stop-hook attempt is allowed. Paused and planning runs permit stopping when every live run is in one of those states."
