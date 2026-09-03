#!/bin/bash

# spawn-guard (03 §5, TDD §4.5) — PreToolUse: Workflow/Agent.
#
# Shim over `docket guard spawn --active`. The predicate is the engine's: no
# write-class reap may be unacknowledged on any active run of the project.
# This file contains no policy, no branching on run content, and no state
# (AC-4.1). The tribunal path below decides nothing either — it reads one id
# out of the harness's tool_input and hands it, with the run the engine itself
# named, back to the engine, which owns the verdict. Behavior is pinned by
# tests/docket-spawn-guard-hook.test.sh.
#
# Exit 0 allow / exit 2 deny with the engine's reason on stderr (engine-spec §2).
# PreToolUse honors exit 2 as a pre-permission hard stop, which is why the guard
# family's native exit contract is passed straight through rather than being
# translated into a permissionDecision envelope.
#
# --active, NOT --run. An earlier version resolved "the active run" as
# `runs[0]` of `docket run status --active`, which is the newest run, so with
# two concurrent active runs the older run's reap hold went unasked: measured
# with an older run holding and a newer run clean, this hook allowed while
# wave-audit's `guard record`, which answers over every run, denied naming the
# older one. The engine now walks every active run oldest-first itself, so the
# hook carries no run id (a cached or resolved id is exactly the drift hooks
# exist to prevent) and spends no subprocess on one. No active run is the
# engine's allow over an empty set: this session is not its business, which is
# what "hooks are global to the session tree" requires.
#
# NO --rows, DELIBERATELY. The hook cannot supply rows honestly -- it sees the
# harness's Workflow/Agent tool_input, not wave.js's canonical manifest bytes,
# and a re-serialization from tool_input would byte-mismatch a CORRECT dispatch
# and deny every legit spawn. Row matching is wave.js's to assert at the point
# it holds the real bytes; the hook's job here is the reap half.
#
# Fail-toward-safety on engine-state uncertainty (03 §5) is the engine's own
# behavior. The one fail-OPEN path is a missing `docket` binary -- a hook that
# hard-blocked every spawn on a tooling gap would take the session down rather
# than protect it. A missing `jq` only loses the tribunal carve-out below; the
# plain question still reaches the engine.

set -uo pipefail

# THE PANEL DEADLOCK IS THE ENGINE'S TO BREAK, NOT THIS HOOK'S.
#
# The reap half denies every Workflow spawn while a write-class reap is
# unacknowledged -- and the docket-run skill's documented remedy for exactly that
# hold is to open a vote proposal and seat a panel by launching tribunal.js
# through this same Workflow tool. So the hold blocked its own resolution:
# reproduced on a past run, where the tribunal launch for the deadlock-breaking
# vote was refused with the identical guard message before tribunal.js's own
# code ran.
#
# `guard spawn --run RUN-N --deciding-vote PROPOSAL-N` is the sanctioned exit
# (filed from that same deadlock and shipped engine-side). The engine refuses
# to compose it with --active, because the carve-out is admitted onto ONE run's
# spawn. So a tribunal launch asks the plain --active question first, and only
# when that denies does the hook re-ask about the run the engine named in its
# denial, with the proposal attached. Every judgement stays with the engine:
# the proposal must EXIST and be OPEN, only the REAP half is relaxed, nothing
# is acknowledged, and the admission is logged as `spawn-admitted` naming the
# proposal and the hold -- because a spawn let past a hold must not read like a
# spawn nothing was holding.
#
# An earlier version of this hook exited 0 here instead. That was worse in
# three ways at once and is deliberately not what this does: it admitted a
# tribunal launch carrying no proposal at all, it admitted one carrying a
# closed proposal (one settled vote authorizing every future spawn), and it
# produced no audit event, so the very thing the engine takes care to record
# went unrecorded.
#
# Matched on BASENAME, not the installed path: the skills resolve tribunal.js to
# `~/.claude/workflows/tribunal.js` where one exists and fall back to the source
# copy in the dotfiles checkout, so pinning one absolute path would leave the
# documented fallback deadlocked. `Agent` calls and every other workflow carry no
# scriptPath and fall straight through unchanged.
#
# The harness stringifies `args`, so the id is read from either shape: a JSON
# string that must be re-parsed, or an object already. It is then matched
# against docket's proposal-id grammar with a bash builtin -- never a `grep`,
# which would add a PATH dependency to a hook whose whole job is to run before
# anything else does. Anything that is not a well-formed id is dropped and the
# guard is asked the ordinary question, so a malformed launch is denied by the
# engine rather than waved through here.
DECIDING_VOTE=""
HOOK_INPUT=$(cat 2>/dev/null || true)
if [ -n "$HOOK_INPUT" ] && command -v jq >/dev/null 2>&1; then
    SCRIPT=$(printf '%s' "$HOOK_INPUT" \
        | jq -r '.tool_input.scriptPath // "" | split("/") | last' 2>/dev/null)
    if [ "$SCRIPT" = "tribunal.js" ]; then
        VOTE_ID=$(printf '%s' "$HOOK_INPUT" | jq -r '
            .tool_input.args
            | if type == "string" then (try fromjson catch {}) else (. // {}) end
            | .voteId // ""' 2>/dev/null)
        [[ "$VOTE_ID" =~ ^[A-Z]{1,8}-V[0-9]+$ ]] && DECIDING_VOTE="$VOTE_ID"
    fi
fi

command -v docket >/dev/null 2>&1 || exit 0

# stdout is dropped, stderr is not. On exit 0 the harness "parses stdout for JSON
# output fields", and the engine's human-mode `✔ allowed` is not JSON — so
# forwarding it would hand a parse failure to the debug log on every spawn while
# adding nothing the exit code doesn't already say. The deny path's reason goes
# to stderr, which exit 2 surfaces, so it must stay.
if [ -n "$DECIDING_VOTE" ]; then
    # The engine's --active denial leads with the oldest run that holds
    # ("RUN-N: ..."); that run is the one the carve-out is admitted onto. The
    # --json deny envelope is {ok, error, code} with no field for the run, so
    # the id is read off the front of the reason text; the prefix is the
    # engine's own format for naming the run, not a paraphrase. An allow, or
    # an answer with no run in it, falls through to the plain question so the
    # verdict arrives in the engine's own words.
    HELD=$(docket guard spawn --active --json 2>/dev/null \
        | jq -r 'select(.ok == false) | .error // ""' 2>/dev/null)
    if [[ "$HELD" =~ ^(RUN-[0-9]+): ]]; then
        exec docket guard spawn --run "${BASH_REMATCH[1]}" \
            --deciding-vote "$DECIDING_VOTE" >/dev/null
    fi
fi

exec docket guard spawn --active >/dev/null
