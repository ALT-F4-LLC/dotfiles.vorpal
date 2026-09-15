#!/bin/bash

# SessionStart injection (03 §7, TDD §4.5) — SessionStart.
#
# One-line shim over `docket run status --json`, so a fresh session in
# the repo knows the run state with no handoff document (AC-4.4). That verb is
# documented READ-ONLY — "computes effective status and WRITES NOTHING" — which
# is what makes it safe to fire on every session start, including the
# operator's own and the old fleet's.
#
# INJECTION MECHANISM: plain stdout. [OBSERVED hooks.md] SessionStart is one of
# the three events where "stdout is added as context that Claude can see and act
# on", so the raw JSON needs no `additionalContext` envelope. A wrapper would
# only add a jq dependency and a failure mode to a hook whose whole job is to
# hand over one document.
#
# SILENT WHEN THERE IS NO RUN. The bare list is active-only (done and abandoned
# runs need `--all`), and over an empty engine it returns
# `{"ok":true,"data":{"runs":null,"total":0}}` [OBSERVED]. Injecting that into
# every non-graph session would spend context to say nothing, so the no-run case
# prints nothing at all and the session boots exactly as it does today. This is
# the SessionStart analogue of the heartbeat's no-op requirement (AC-4.5).
#
# EXIT 0 UNLESS DOCKET IS PRESENT AND FAILS. SessionStart cannot block [SPEC
# hooks.md: "No blocking or decision control"]; a session boots either way. A
# missing binary or a repo with no store exits 0 silently. A present docket
# whose status read errors exits 1 with one stderr line, so the operator sees
# that the run state is unknown instead of a session that silently believes
# there is no run.

set -uo pipefail

command -v docket >/dev/null 2>&1 || exit 0

# A present docket that FAILS is signal, not noise: `|| exit 0` here hid a
# retired flag for weeks, and a session booted believing there was no run.
# Exit 1 is non-blocking (SessionStart cannot block anyway) and shows the one
# stderr line to the operator; a repo with no store still exits 0 silently
# below, since NOT_FOUND on the deny channel is not a failure of the hook.
ERR_FILE=$(mktemp "${TMPDIR:-/tmp}/docket-session-start.XXXXXX") || exit 0
STATUS=$(docket run status --json 2>"$ERR_FILE"); RC=$?
ERR=$(cat "$ERR_FILE" 2>/dev/null); rm -f "$ERR_FILE"
if [ "$RC" -ne 0 ]; then
    case "$ERR" in
        *'no docket database found'*|*NOT_FOUND*) exit 0 ;;
    esac
    printf 'docket-session-start: `docket run status --json` failed (exit %s): %s — run state is UNKNOWN for this session\n' "$RC" "${ERR:-no stderr}" >&2
    exit 1
fi
[ -n "$STATUS" ] || exit 0

# No active run: inject nothing. Uses a substring test rather than jq so the
# hook keeps no dependency beyond docket itself.
case "$STATUS" in
    *'"total":0'*) exit 0 ;;
esac

printf 'Active Docket engine runs in this repo (docket run status --json):\n%s\n' "$STATUS"
exit 0
