#!/bin/bash

# spawn-guard (03 §5, TDD §4.5) — PreToolUse: Workflow/Agent.
#
# One-line shim over `docket guard spawn`. The predicate is the engine's: the
# proposed rows must byte-match the open dispatch and no write-class reap may be
# unacknowledged. This file contains no policy, no branching on run content, and
# no state (AC-4.1). The tribunal path below decides nothing either — it reads
# one id out of the harness's tool_input and hands it to the engine, which owns
# the verdict. Behavior is pinned by tests/docket-spawn-guard-hook.test.sh.
#
# Exit 0 allow / exit 2 deny with the engine's reason on stderr (engine-spec §2).
# PreToolUse honors exit 2 as a pre-permission hard stop, which is why the guard
# family's native exit contract is passed straight through rather than being
# translated into a permissionDecision envelope.
#
# NO --rows, DELIBERATELY. The engine's documented semantics: with no open
# dispatch and no --rows the row half is "vacuously satisfied and the reap half
# still answers", so a relay batching its own way still gets the reap check.
# The hook cannot supply rows honestly -- it sees the harness's Workflow/Agent
# tool_input, not wave.js's canonical manifest bytes, and a re-serialization
# from tool_input would byte-mismatch a CORRECT dispatch and deny every legit
# spawn. Row matching is wave.js's to assert at the point it holds the real
# bytes; the hook's job here is the reap half plus the no-dispatch case.
#
# Fail-toward-safety on engine-state uncertainty (03 §5) is the engine's own
# behavior: an unresolvable/missing run is exit 2, not exit 0. The one fail-OPEN
# path is a missing `docket` binary -- a hook that hard-blocked every spawn on a
# tooling gap would take the session down rather than protect it.

set -uo pipefail

# THE PANEL DEADLOCK (DOT-166) IS THE ENGINE'S TO BREAK, NOT THIS HOOK'S.
#
# The reap half denies every Workflow spawn while a write-class reap is
# unacknowledged -- and the conduct skill's documented remedy for exactly that
# hold is to open a vote proposal and seat a panel by launching tribunal.js
# through this same Workflow tool. So the hold blocked its own resolution:
# reproduced on RUN-14, where the tribunal launch for DKT-V46 was refused with
# the identical guard message before tribunal.js's own code ran.
#
# `guard spawn --deciding-vote PROPOSAL-N` is the sanctioned exit (DKT-236,
# filed FROM DOT-166 and shipped engine-side). All this hook does is notice a
# tribunal.js launch, lift the proposal id out of its args, and pass it along.
# Every judgement stays with the engine: the proposal must EXIST and be OPEN,
# only the REAP half is relaxed, nothing is acknowledged, and the admission is
# logged as `spawn-admitted` naming the proposal and the hold -- because a
# spawn let past a hold must not read like a spawn nothing was holding.
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
# The id is read through the same shape the policy-guard uses, because the
# harness stringifies `args`: a JSON string that must be re-parsed, or an
# object already. It is then matched against docket's proposal-id grammar with
# a bash builtin -- never a `grep`, which would add a PATH dependency to a hook
# whose whole job is to run before anything else does. Anything that is not a
# well-formed id is dropped and the guard is asked the ordinary question, so a
# malformed launch is denied by the engine rather than waved through here.
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

# $RUN resolution per invocation, never cached (TDD §4.5): "a cached run id is
# exactly the drift hooks exist to prevent." Unlike run-guard and wave-audit,
# whose verbs answer over all active runs and so need no id, `guard spawn`
# requires --run.
#
# A missing `jq` leaves RUN empty and the hook allows below — the same fail-OPEN
# direction as a missing `docket`, stated here because the pipe hides it.
#
# LIMITATION, recorded rather than papered over: `runs[0]` is the most recently
# activated run ([OBSERVED] `--active` sorts newest-first), so with TWO
# concurrent active runs this hook asks about only one of them. Scope of the
# gap: the reap half goes unasked for the older run. It is narrow because the
# row half is vacuous here anyway (no --rows, see above), and because
# `wave-audit`'s `guard record` DOES answer over every non-terminal run —
# verified: with RUN-3 holding an open dispatch and RUN-4 newer and clean, this
# hook allowed while wave-audit denied and named RUN-3. Closing it properly
# needs an engine-side `--active` mode on `guard spawn` (TDD §4.5's own stated
# fallback for $RUN cost) rather than a hook-side loop over runs, which would
# reintroduce policy into a shim.
RUN=$(docket run status --active --json 2>/dev/null \
    | jq -r '.data.runs[0].run // empty' 2>/dev/null) || RUN=""

# No active run means no graph dispatch to drift from: this session is not the
# engine's business. Both the operator's own sessions and the old fleet's land
# here, which is what "hooks are global to the session tree" requires.
[ -n "$RUN" ] || exit 0

# stdout is dropped, stderr is not. On exit 0 the harness "parses stdout for JSON
# output fields", and the engine's human-mode `✔ allowed` is not JSON — so
# forwarding it would hand a parse failure to the debug log on every spawn while
# adding nothing the exit code doesn't already say. The deny path's reason goes
# to stderr, which exit 2 surfaces, so it must stay.
if [ -n "$DECIDING_VOTE" ]; then
    exec docket guard spawn --run "$RUN" --deciding-vote "$DECIDING_VOTE" >/dev/null
fi

exec docket guard spawn --run "$RUN" >/dev/null
