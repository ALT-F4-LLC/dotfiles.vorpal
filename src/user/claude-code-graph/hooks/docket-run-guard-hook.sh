#!/bin/bash

# run-guard (03 §5, TDD §4.5) — Stop.
#
# Shim over `docket guard stop`: block session end while an active run has a
# step in pending/ready/claimed/running/gated. A STEP parked in `waiting-human`
# does NOT block — the guard asks whether the MACHINE is still working, and work
# waiting on a person is not something a stop interferes with. That is the
# engine's predicate, not this hook's; the hook holds no policy (AC-4.1).
#
# STEP status, not RUN status — a distinction worth stating because the obvious
# remediation is wrong. [OBSERVED] `docket run pause RUN-N` moves the RUN to
# `waiting-human`, but its steps revert to `pending`, and this guard still
# denies: `run status` reads `RUN-2 waiting-human` while `guard stop` reads
# `work is still pending: [approve@0 (pending)]`. Only clearing the STEPS
# (approve/resolve/complete) or ending the run lets a stop through. The deny
# message below says so explicitly, because an operator who follows
# "park the run" advice would otherwise loop against an unchanged block.
#
# EXIT 2, NOT THE JSON BLOCK ENVELOPE — and the two are mutually exclusive.
# [OBSERVED, code.claude.com/docs/en/hooks.md] For the Stop event, exit 2 "can
# block: prevents Claude from stopping, continues the conversation", and
# "stderr text is fed back to Claude as an error message". The same doc is
# explicit that the mechanisms cannot be mixed: "You must choose one approach
# per hook, not both... Claude Code only processes JSON on exit 0. If you exit
# 2, any JSON is ignored." So emitting both a `{"decision":"block"}` envelope
# AND exit 2 would silently discard the envelope. AC-4.2 requires exit 2, and
# exit 2 already surfaces the engine's reason verbatim via stderr — which is
# also what makes AC-4.7's "the reason surfaced is run-guard's" hold. The old
# fleet's stop-guard keeps its own JSON envelope; each hook picks its own
# mechanism independently, which is a per-hook choice, not a session-wide one.
#
# NO --run: `docket guard stop` takes no run argument at all [OBSERVED
# `guard stop --help`] — it answers over every active run. TDD §4.5's table
# writes `docket guard stop --run $RUN`; that flag does not exist. Recorded as
# a deviation. It is the better shape here for the same reason `guard record`'s
# optional --run is: one wiring keeps working as runs come and go, and no
# `run status` subprocess runs on every Stop.
#
# stop_hook_active IS CHECKED, and this is load-bearing, not defensive. [SPEC
# hooks.md] Claude Code "overrides the hook and ends the turn after 8
# consecutive blocks", and that cap governs blocks from ANY signaling channel.
# With two Stop hooks registered (AC-4.7) both able to block, an unguarded
# re-block would burn the shared cap roughly twice as fast as either hook alone.
# Returning allow when the harness is already continuing because of a prior
# stop-hook block matches the old fleet's row-1 behavior exactly.
#
# Fail-OPEN on missing tooling (docket/jq absent, unparsable stdin), matching
# this hook family's convention: an infrastructure gap must not strand a
# session that cannot stop. Engine-state uncertainty inside a reachable engine
# resolves the other way — that is the engine's own exit 2.

set -uo pipefail

allow() {
    exit 0
}

deny() {
    printf '%s\n' "$1" >&2
    exit 2
}

DATA=$(cat 2>/dev/null) || allow

if command -v jq >/dev/null 2>&1; then
    STOP_HOOK_ACTIVE=$(printf '%s' "$DATA" | jq -r '.stop_hook_active // false' 2>/dev/null) \
        || STOP_HOOK_ACTIVE="false"
    [ "$STOP_HOOK_ACTIVE" = "true" ] && allow
fi

command -v docket >/dev/null 2>&1 || allow

REASON=$(docket guard stop 2>&1 >/dev/null) && allow

[ -n "$REASON" ] || REASON="an active run still has work in flight"

deny "Session stop blocked by run-guard: ${REASON}. Finish or dispatch the named work; approve a human gate with \`docket step approve\`, park a blocked step with \`docket step resolve\`, or end the run with \`docket run abandon\`. NOTE: \`docket run pause\` does NOT clear this — it moves the RUN to waiting-human while its steps stay pending, and this guard reads step status (verified: a paused run with a pending gate still denies)."
