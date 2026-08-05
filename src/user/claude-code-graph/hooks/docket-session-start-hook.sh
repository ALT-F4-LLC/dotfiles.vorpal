#!/bin/bash

# SessionStart injection (03 §7, TDD §4.5) — SessionStart.
#
# One-line shim over `docket run status --active --json`, so a fresh session in
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
# SILENT WHEN THERE IS NO RUN. `--active` over an empty engine returns
# `{"ok":true,"data":{"runs":null,"total":0}}` [OBSERVED]. Injecting that into
# every non-graph session would spend context to say nothing, so the no-run case
# prints nothing at all and the session boots exactly as it does today. This is
# the SessionStart analogue of the heartbeat's no-op requirement (AC-4.5).
#
# ALWAYS EXIT 0. SessionStart cannot block [SPEC hooks.md: "No blocking or
# decision control"], and an exit 2 here would render a hook-error notice in the
# transcript that Claude never sees — noise with no signal. A session must boot
# whether or not the engine is reachable.

set -uo pipefail

command -v docket >/dev/null 2>&1 || exit 0

STATUS=$(docket run status --active --json 2>/dev/null) || exit 0
[ -n "$STATUS" ] || exit 0

# No active run: inject nothing. Uses a substring test rather than jq so the
# hook keeps no dependency beyond docket itself.
case "$STATUS" in
    *'"total":0'*) exit 0 ;;
esac

printf 'Active Docket engine runs in this repo (docket run status --active --json):\n%s\n' "$STATUS"
exit 0
