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
#
# TWO CARVE-OUTS, both observed on RUN-1 (2026-08-06):
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
if command -v jq >/dev/null 2>&1; then
    LIVE=$(docket run status --json 2>/dev/null \
        | jq -r '[.data.runs // [] | .[] | select(.status != "abandoned" and .status != "done" and .status != "complete" and .status != "completed")] | length' 2>/dev/null) \
        || LIVE=""
    [ "$LIVE" = "0" ] && allow
fi

# Carve-out 2: a dispatch is open (or a discrepancy stands) — the wave is in
# flight and turn-end is the designed await. guard record's exit 2 is exactly
# that condition; any other exit falls through to the deny below.
docket guard record >/dev/null 2>&1
[ "$?" -eq 2 ] && allow

[ -n "$REASON" ] || REASON="an active run still has work in flight"

deny "Session stop blocked by run-guard: ${REASON}. Finish or dispatch the named work; approve a human gate with \`docket step approve\`, resolve a step PARKED in waiting-human with \`docket step resolve\` (it refuses pending steps — dispatch those or end the run), or end the run with \`docket run abandon\`. NOTE: \`docket run pause\` does NOT clear this — it moves the RUN to waiting-human while its steps stay pending, and this guard reads step status (verified: a paused run with a pending gate still denies)."
