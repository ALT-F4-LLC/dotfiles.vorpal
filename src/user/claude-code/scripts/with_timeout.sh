#!/bin/bash
# macOS-compatible timeout wrapper: runs <command...> under a wall-clock
# deadline without depending on GNU coreutils `timeout`/`gtimeout` being
# installed. A sentinel file (not exit-code heuristics) records whether the
# watchdog actually fired, so a command that itself exits 124 or via
# SIGTERM/SIGKILL is never mistaken for a timeout-kill.
set -u

usage() {
    echo "Usage: with_timeout.sh <seconds> <command...>" >&2
    echo "  Runs <command...> with a <seconds> wall-clock deadline." >&2
    echo "  On timeout: sends TERM, then KILL after a 3s grace period, exits 124." >&2
    echo "  Otherwise: exits with the command's own real exit code." >&2
    exit 1
}

if [ "$#" -lt 2 ]; then
    usage
fi

SECONDS_LIMIT="$1"
shift

TIMEOUT_FLAG=$(mktemp -p "${TMPDIR:-/tmp}")
trap 'rm -f "$TIMEOUT_FLAG"' EXIT

"$@" &
CMD_PID=$!

(
    sleep "$SECONDS_LIMIT"
    if kill -0 "$CMD_PID" 2>/dev/null; then
        echo timeout > "$TIMEOUT_FLAG"
        kill -TERM "$CMD_PID" 2>/dev/null
        sleep 3
        kill -KILL "$CMD_PID" 2>/dev/null
    fi
) &
WATCHDOG_PID=$!

wait "$CMD_PID" 2>/dev/null
CMD_EXIT=$?

kill "$WATCHDOG_PID" 2>/dev/null
wait "$WATCHDOG_PID" 2>/dev/null

if [ -s "$TIMEOUT_FLAG" ]; then
    exit 124
fi

exit "$CMD_EXIT"
