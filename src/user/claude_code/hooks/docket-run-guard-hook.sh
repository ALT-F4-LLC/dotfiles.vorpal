#!/bin/bash

# run-guard (03 §5, TDD §4.5) — Stop.
#
# Shim over `docket guard stop`: block session end while an active run has a
# step in pending/ready/claimed/running/gated. A STEP parked in `waiting-human`
# does NOT block — the guard asks whether the MACHINE is still working, and work
# waiting on a person is not something a stop interferes with. That is the
# engine's predicate, not this hook's; the hook holds no policy (AC-4.1).
#
# STEP status, not RUN status, is what `guard stop`/`guard record` read — a
# distinction worth stating because the obvious remediation used to be wrong.
# [OBSERVED] `docket run pause RUN-N` moves the RUN to `waiting-human`, but its
# steps revert to `pending`, so `run status` reads `RUN-2 waiting-human` while
# `guard stop` still reads `work is still pending: [approve@0 (pending)]`.
# Carve-out 4 below is the fix: when NO live run in the project is waiting on
# the machine, that IS the sanctioned "work waiting on a person" state the
# header above grants a single step, so the hook allows the stop directly from
# RUN status without waiting for the steps to clear.
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
# optional --run is: one wiring keeps working as runs come and go.
#
# COST, honestly stated: a denied `guard stop` is no longer the end of the
# story, so the carve-outs below do read the engine on a Stop that reaches
# them — ONE `run status --json` (captured once into LIVE_RUNS and reused by
# every carve-out that needs it) plus, in carve-out 3 only, one `events list`
# per live run. A Stop that `guard stop` allows outright still costs nothing
# beyond that one call.
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
#
# THE CARVE-OUTS SHARE ONE INVARIANT: each block below allows ONLY on an
# affirmative answer to its own question, and everything else — missing
# tooling, an unreadable engine answer, an unexpected status — falls through to
# the deny at the bottom of the file. Count them by reading, not by trusting a
# number in this header. The first two were observed on RUN-1 (2026-08-06):
#
# NO DATABASE = NOTHING IN FLIGHT. Every guard verb exits 2 with "✘ Error: no
# docket database found" when no .docket exists up-tree — the same exit code as
# a legitimate deny, so without this carve-out the hook blocks every turn-end
# in every repo that is not docket's business. [OBSERVED] mid-bootstrap,
# pre-init: the deny pushed the session to run `docket init` earlier than it
# had deliberately planned. No DB means no run means nothing a stop interferes
# with: allow. (The honest fix is engine-side — NOT_FOUND should not share the
# deny channel — filed; this is the hook-side mitigation.)
#
# OPEN DISPATCH = WAVE IN FLIGHT = TURN-END IS THE DESIGN. The conduct skill's
# await pattern ("await the wave's completion notification; the session is
# free meanwhile") REQUIRES ending the turn — notifications only deliver at
# turn boundaries. But claimed/running steps made this hook deny every
# turn-end mid-wave, which taught the conductor to busy-wait ("I just need to
# actually wait rather than end the turn" — RUN-1, verbatim), burning tokens
# and starving itself of the very notification it awaited. `docket guard
# record` exits 2 exactly while a dispatch is open or a discrepancy stands —
# both states where the machine is working WITHOUT the session, so a yielding
# conductor is correct and an abandoning operator loses nothing (any session
# resumes from `run status --active`). Allow on that probe.

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

# Carve-out 1: no database — this repo is not docket's business.
case "$REASON" in
    *'no docket database found'*) allow ;;
esac

# Carve-out 1b: this project has no live run. The global store answers for
# every project on the machine, which made carve-out 1 dead code (a database
# always exists up-tree now) and widened `guard stop`'s no-run-argument
# wiring from repo-wide to machine-wide — a session standing in an unrelated
# repo was denied over another project's run [OBSERVED 2026-08-11, RUN-2:
# dotfiles cwd, deny named docket.git's steps]. `run status` IS
# project-scoped (same probe: 0 runs from dotfiles, RUN-2 from docket.git),
# so zero live runs in the cwd's project means a stop here interferes with
# nothing: allow. The affirmative zero is the only new allow path — missing
# jq or a parse failure falls through to the deny, keeping conductor-seat
# behavior byte-identical. (Engine asymmetry — guards store-wide, sibling
# reads project-scoped — is filed; this is the hook-side mitigation.)
#
# THE LIVE-RUN LIST IS READ ONCE, HERE, and reused by carve-outs 3 and 4. One
# read keeps the terminal-status vocabulary in a single place: three copies of
# this filter would let a partial future edit fail toward a silent ALLOW.
# LIVE_RUNS is a JSON array on success and EMPTY on any failure (no jq, no
# engine answer, unparsable payload) — every reader below must treat empty as
# "unknown", never as "none".
LIVE_RUNS=""
if command -v jq >/dev/null 2>&1; then
    LIVE_RUNS=$(docket run status --json 2>/dev/null \
        | jq -c '[.data.runs // [] | .[] | select(.status != "abandoned" and .status != "done" and .status != "complete" and .status != "completed")]' 2>/dev/null) \
        || LIVE_RUNS=""
    [ "$LIVE_RUNS" = "[]" ] && allow
fi

# Carve-out 2: a dispatch is open (or a discrepancy stands) — the wave is in
# flight and turn-end is the designed await. guard record's exit 2 is exactly
# that condition; any other exit falls through to the deny below.
docket guard record >/dev/null 2>&1
[ "$?" -eq 2 ] && allow

# Carve-out 3: a freshly activated run nobody has dispatched. `guard stop`
# counts steps in `pending`, which is exactly the state bootstrap is REQUIRED
# to leave behind: §5 activates, §7 hands off, and the session ends. Denying
# there makes that contract unsatisfiable — the only exits the deny offers are
# conduct the run or abandon it, and on 2026-08-17 all six successful
# bootstraps hit this, two of them pushed into `/conduct` by the guard itself.
# The predicate matches the hook's own header question ("is the MACHINE still
# working?"): with zero `dispatch-opened` events, nothing has ever been handed
# out, so nothing is in flight to interrupt. A conductor between `next` and
# `dispatch open` lands here too, and equally interrupts nothing.
#
# FAILS CLOSED, exactly like carve-out 1b: missing jq, an unreadable run list,
# a non-numeric count, or any run that HAS been dispatched all fall through to
# the deny. Only an affirmative "every live run in this project has zero
# dispatch-opened events" allows.
if command -v jq >/dev/null 2>&1; then
    NEVER_DISPATCHED=1
    RUNS=$(printf '%s' "$LIVE_RUNS" | jq -r '.[].run' 2>/dev/null) \
        || RUNS=""
    [ -n "$RUNS" ] || NEVER_DISPATCHED=0
    for R in $RUNS; do
        # No `// []` fallback on purpose: an error payload ({"ok":false}, a
        # missing key, anything not a real events array) must ERROR here so
        # OPENED comes back empty and we deny, rather than reading as a
        # legitimate zero and allowing. Every live run has at least
        # `run-activated`, so a genuine response always carries the array.
        OPENED=$(docket events list --run "$R" --json 2>/dev/null \
            | jq -e -r '[.data.events[] | select(.kind == "dispatch-opened")] | length' 2>/dev/null) \
            || OPENED=""
        [ "$OPENED" = "0" ] || { NEVER_DISPATCHED=0; break; }
    done
    [ "$NEVER_DISPATCHED" = "1" ] && allow
fi

# Carve-out 4: NO live run in this project is waiting on the machine — a
# sanctioned stop. `run pause` reverts its STEPS to pending (see header),
# which is exactly what defeats `guard stop`/`guard record` and carve-out 3's
# dispatch check, so a paused run denies without this carve-out. The RUN's own
# status is the correct signal instead.
#
# TWO statuses qualify, and neither is an accident:
#   waiting-human — the same "work waiting on a person" state the header
#     already grants a single step. This DELIBERATELY includes a run the
#     engine parked on a budget breach: the engine sets the same status there,
#     only the run-paused event's `data.reason` tells the two apart, and in
#     both cases the machine has stopped and a person must act. A stop
#     interferes with neither, so the hook does not spend an `events list` per
#     run to distinguish them.
#   planning — a run nobody has activated. It holds no dispatchable work at
#     all, so it can never be the thing a stop interrupts; counting it as live
#     work made "one paused run plus one unactivated run" deny.
# Any OTHER live status (active, gated, or a status this hook has never heard
# of) means the machine may still be working: fall through to the deny.
#
# FAILS CLOSED, same shape as 1b/3: missing jq, an unreadable run list, an
# empty live set, or any live run outside those two statuses all reach the
# deny below. `jq -e` carries that for us — it exits non-zero on `false` and
# on unparsable input alike — and `length > 0` rejects the empty set without a
# separate sentinel.
if command -v jq >/dev/null 2>&1; then
    printf '%s' "$LIVE_RUNS" \
        | jq -e 'length > 0 and all(.[]; .status == "waiting-human" or .status == "planning")' \
            >/dev/null 2>&1 \
        && allow
fi

[ -n "$REASON" ] || REASON="an active run still has work in flight"

deny "Session stop blocked by run-guard: ${REASON}. Finish or dispatch the named work; approve a human gate with \`docket step approve\`, resolve a step PARKED in waiting-human with \`docket step resolve\` (it refuses pending steps — dispatch those or end the run), or end the run with \`docket run abandon\`. If the work is blocked by something OUTSIDE the engine — a refused spawn, a denied permission, an operator ruling to withhold it — none of those verbs is the answer: say so plainly and stop, since one deny per session is expected and the second is suppressed. NOTE: \`docket run pause\` alone now clears this guard — once every live run is parked (waiting-human, whether an operator paused it or a budget breach did) or still in planning, the stop is allowed even though the run's steps stay pending (carve-out 4); this deny means some live run is still active/gated, or a dispatch is genuinely open."
