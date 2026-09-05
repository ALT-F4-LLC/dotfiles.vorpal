#!/bin/bash

# Exercise stop decisions with a fake engine, including complete run
# enumeration, asynchronous yields, paused runs, and uncertain responses.
# No real Docket store or model calls are used.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
HOOK="${GUARD_HOOK:-${REPO_ROOT}/src/user/claude_code/hooks/docket-run-guard-hook.sh}"

PASS=0
FAIL=0

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    FAIL=$((FAIL + 1))
}

pass() {
    printf 'PASS: %s\n' "$1"
    PASS=$((PASS + 1))
}

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$HOOK" ] || fatal "hook not found at ${HOOK}"
command -v jq >/dev/null 2>&1 || fatal "jq is required to run this test"

BASH_BIN=$(command -v bash) || fatal "bash not found on PATH"

SANDBOX=$(mktemp -d "${TMPDIR:-/tmp}/docket-run-guard-test.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$SANDBOX"' EXIT
STDERR_FILE="${SANDBOX}/hook.stderr"

TOOLS_DIR="${SANDBOX}/tools"
TOOLS_DIR_NO_JQ="${SANDBOX}/tools-no-jq"
STUB_DIR="${SANDBOX}/stub"
mkdir -p "$TOOLS_DIR" "$TOOLS_DIR_NO_JQ" "$STUB_DIR"
for tool in bash cat jq; do
    tool_path=$(command -v "$tool") || fatal "hook dependency ${tool} not found on PATH"
    ln -s "$tool_path" "${TOOLS_DIR}/${tool}"
done
for tool in bash cat; do
    tool_path=$(command -v "$tool") || fatal "hook dependency ${tool} not found on PATH"
    ln -s "$tool_path" "${TOOLS_DIR_NO_JQ}/${tool}"
done

# Fake engine with the real default run page limit. Keeping the
# pagination here makes omitted flags change behavior rather than only text.
cat >"${STUB_DIR}/docket" <<'STUB'
#!/bin/bash
build_runs_json() {
    jq -cn --arg names "${RUN_NAMES:-}" --arg statuses "${RUN_STATUSES:-}" '
        ($names | split(" ") | map(select(. != ""))) as $names
        | ($statuses | split(" ")) as $statuses
        | [range(0; $names | length) | {run:$names[.], status:$statuses[.]}]'
}

case "${1:-}" in
    guard)
        case "${2:-}" in
            stop)
                if [ -n "${GUARD_STOP_REASON:-}" ]; then
                    printf '%s\n' "$GUARD_STOP_REASON" >&2
                    exit 2
                fi
                exit 0
                ;;
            record)
                printf '%s' "${GUARD_RECORD_REASON:-}" >&2
                exit "${GUARD_RECORD_EXIT:-0}"
                ;;
            *)
                printf 'fake docket: unexpected guard subcommand: %s\n' "$*" >&2
                exit 64
                ;;
        esac
        ;;
    run)
        case "${2:-}" in
            status)
                if [ -n "${RUN_STATUS_JSON:-}" ]; then
                    printf '%s' "$RUN_STATUS_JSON"
                    exit "${RUN_STATUS_EXIT:-0}"
                fi
                if [ -n "${RUN_STATUS_UNREADABLE:-}" ]; then
                    # The hook's other named fail-closed input: an answer that
                    # is not JSON at all (engine crash, truncated pipe).
                    printf 'panic: engine unavailable'
                    exit 0
                fi
                limit=50
                active=false
                shift 2
                while [ "$#" -gt 0 ]; do
                    case "$1" in
                        --active) active=true ;;
                        --limit) shift; limit="$1" ;;
                        --json) ;;
                        *) exit 64 ;;
                    esac
                    shift
                done
                RUNS=$(build_runs_json)
                printf '%s' "$RUNS" | jq -c --argjson active "$active" --argjson limit "$limit" '
                    (if $active then map(select(.status != "done" and .status != "abandoned")) else . end) as $runs
                    | {ok:true, data:{total:($runs | length),
                        runs:(if $limit > 0 then $runs[:$limit] else $runs end)}}'
                exit "${RUN_STATUS_EXIT:-0}"
                ;;
            verify-pins)
                # VERIFY_PINS_EXITS is parallel to RUN_NAMES, like
                # RUN_STATUSES; a single value answers for every run. Unset
                # means 0 (all pins sound), so cases predating carve-out 5
                # keep their meaning.
                names=(${RUN_NAMES:-})
                exits=(${VERIFY_PINS_EXITS:-0})
                i=0
                for n in "${names[@]}"; do
                    if [ "$n" = "${3:-}" ]; then
                        exit "${exits[$i]:-${exits[0]}}"
                    fi
                    i=$((i + 1))
                done
                exit "${exits[0]}"
                ;;
            *)
                printf 'fake docket: unexpected run subcommand: %s\n' "$*" >&2
                exit 64
                ;;
        esac
        ;;
    events)
        # Legacy event absence is deliberately available to a buggy hook:
        # the direct-step-history regression must retain the engine denial
        # even when no dispatch event exists.
        [ "${2:-}" = "list" ] || exit 64
        printf '%s' '{"ok":true,"data":{"events":[],"total":0}}'
        ;;
    *)
        printf 'fake docket: unexpected invocation: %s\n' "$*" >&2
        exit 64
        ;;
esac
STUB
chmod +x "${STUB_DIR}/docket"

PATH_WITH_DOCKET="${STUB_DIR}:${TOOLS_DIR}"
PATH_NO_JQ="${STUB_DIR}:${TOOLS_DIR_NO_JQ}"
# THREE-VALUED ON PURPOSE. The hook's allow path is exit 0 specifically; any
# other non-deny status (1 from a stray failed command, 64 from the stub's own
# unexpected-invocation guard, 127 from a hook that cannot even start) is a
# broken hook, not an allow. Folding those into ALLOW let a hook whose entire
# body was `exit 127` score six passes.
verdict_of() {
    local path_value="$1" rc stop_input="${STOP_INPUT_JSON:-}"
    [ -n "$stop_input" ] || stop_input='{}'
    export PATH="$path_value"
    printf '%s' "$stop_input" | "$BASH_BIN" "$HOOK" >/dev/null 2>"$STDERR_FILE"
    rc=$?
    case "$rc" in
        0) printf 'ALLOW' ;;
        2) printf 'DENY' ;;
        *) printf 'ERROR(%d)' "$rc" ;;
    esac
}

run_case() {
    local label="$1" want="$2" path_value="${3:-$PATH_WITH_DOCKET}" got
    got=$(verdict_of "$path_value")
    if [ "$got" = "$want" ]; then
        pass "${label} (${want})"
    else
        fail "${label} (want ${want}, got ${got})"
    fi
}

reset_env() {
    unset GUARD_STOP_REASON GUARD_RECORD_EXIT GUARD_RECORD_REASON RUN_NAMES RUN_STATUSES RUN_STATUS_UNREADABLE VERIFY_PINS_EXITS
    unset RUN_STATUS_JSON RUN_STATUS_EXIT STOP_INPUT_JSON
}

# ---- CARVE-OUT 4: every live run paused (waiting-human) allows the stop ----
case_carveout4_single_run_paused_allows() {
    reset_env
    export GUARD_STOP_REASON="work is still pending: [approve@0 (pending)]"
    export GUARD_RECORD_EXIT=1
    export RUN_NAMES="RUN-1"
    export RUN_STATUSES="waiting-human"
    run_case "single live run, waiting-human, dispatch was opened earlier" ALLOW
}

case_carveout4_one_active_run_denies() {
    reset_env
    export GUARD_STOP_REASON="work is still pending"
    export GUARD_RECORD_EXIT=1
    export RUN_NAMES="RUN-1 RUN-2"
    export RUN_STATUSES="waiting-human active"
    run_case "one of two live runs is active, not waiting-human" DENY
}

case_carveout4_two_runs_both_paused_allows() {
    reset_env
    export GUARD_STOP_REASON="work is still pending"
    export GUARD_RECORD_EXIT=1
    export RUN_NAMES="RUN-1 RUN-2"
    export RUN_STATUSES="waiting-human waiting-human"
    run_case "two live runs, both waiting-human" ALLOW
}

case_carveout4_planning_run_allows() {
    reset_env
    export GUARD_STOP_REASON="work is still pending"
    export GUARD_RECORD_EXIT=1
    export RUN_NAMES="RUN-1 RUN-2"
    export RUN_STATUSES="waiting-human planning"
    run_case "paused run plus an unactivated (planning) run" ALLOW
}

case_carveout4_terminal_run_ignored_allows() {
    reset_env
    export GUARD_STOP_REASON="work is still pending"
    export GUARD_RECORD_EXIT=1
    export RUN_NAMES="RUN-1 RUN-2"
    export RUN_STATUSES="waiting-human done"
    run_case "paused run plus a done run (terminal filter drops the done one)" ALLOW
}

case_carveout4_unknown_status_denies() {
    reset_env
    export GUARD_STOP_REASON="work is still pending"
    export GUARD_RECORD_EXIT=1
    export RUN_NAMES="RUN-1 RUN-2"
    export RUN_STATUSES="waiting-human cancelled"
    run_case "paused run plus a status this hook does not know -> deny" DENY
}

# ---- FAIL-CLOSED: these pin the CHAIN, not carve-out 4 in particular -------
# Both inputs disable every jq-gated block at once, so the deny they observe is
# attributable to no single carve-out. They are here because the hook's header
# names both inputs as fail-closed and neither had a case.

case_chain_fails_closed_without_jq() {
    reset_env
    export GUARD_STOP_REASON="work is still pending"
    export GUARD_RECORD_EXIT=1
    run_case "jq missing from PATH -> deny (no jq-gated carve-out can evaluate)" DENY "$PATH_NO_JQ"
}

case_chain_fails_closed_on_unreadable_run_list() {
    reset_env
    export GUARD_STOP_REASON="work is still pending"
    export GUARD_RECORD_EXIT=1
    export RUN_STATUS_UNREADABLE=1
    run_case "run status answers with non-JSON -> deny (unknown is not none)" DENY
}

# ---- REGRESSION: pre-existing carve-outs still fire ahead of carve-out 4 --

case_regression_guard_stop_success_allows() {
    reset_env
    export RUN_NAMES="RUN-1"
    export RUN_STATUSES="active"
    run_case "guard stop itself succeeds -> allow before any carve-out" ALLOW
}

case_regression_empty_list_cannot_override_engine_denial() {
    reset_env
    export GUARD_STOP_REASON="work is still pending"
    run_case "empty list cannot override the project-scoped engine's denial" DENY
}

case_regression_open_dispatch_allows() {
    reset_env
    export GUARD_STOP_REASON="work is still pending"
    export GUARD_RECORD_EXIT=2
    export GUARD_RECORD_REASON='Error: RUN-1 has an open dispatch: DISPATCH-1 expiring at 123456789 — reconcile with `docket dispatch close --run RUN-1`, give up on it with `docket dispatch abandon --run RUN-1`, or wait for the TTL to auto-abandon it'
    export RUN_NAMES="RUN-1"
    export RUN_STATUSES="active"
    run_case "guard record confirms an open dispatch -> allow asynchronous yield" ALLOW
}

case_regression_never_dispatched_engine_contract() {
    reset_env
    export RUN_NAMES="RUN-1"
    export RUN_STATUSES="active"
    run_case "engine exempts fresh never-dispatched run with every step pending" ALLOW
    export GUARD_STOP_REASON="work is still pending: [implement@0 (claimed)]"
    run_case "undispatched run with direct step history retains the engine denial" DENY
}

# ---- CARVE-OUT 5: every live run pin-blocked (verify-pins exit 4) ----------
# The drift wedge: the engine refuses the dispatch over pin drift while
# this hook denies the stop over the same pending rows. Only the engine's
# affirmative CHANGED verdict (exit 4) allows; exit 2 — which doubles as the
# CLI's generic error code — and every other non-4 answer stay a deny.

case_carveout5_drifted_pins_allow() {
    reset_env
    export GUARD_STOP_REASON="work is still pending: [review@0#0 (pending) review@0#1 (pending)]"
    export GUARD_RECORD_EXIT=1
    export RUN_NAMES="RUN-1"
    export RUN_STATUSES="active"
    export VERIFY_PINS_EXITS="4"
    run_case "active run, pending steps, pins drifted (verify-pins exit 4)" ALLOW

    if grep -q 'drifted pins' "$STDERR_FILE"; then
        pass "drift allow narrates the reason to stderr"
    else
        fail "drift allow printed no explanatory note to stderr"
    fi
}

case_carveout5_clean_pins_deny_unchanged() {
    reset_env
    export GUARD_STOP_REASON="work is still pending: [review@0#0 (pending)]"
    export GUARD_RECORD_EXIT=1
    export RUN_NAMES="RUN-1"
    export RUN_STATUSES="active"
    export VERIFY_PINS_EXITS="0"
    run_case "same shape with sound pins (verify-pins exit 0) -> deny unchanged" DENY
}

case_carveout5_exit2_is_not_drift_denies() {
    reset_env
    export GUARD_STOP_REASON="work is still pending"
    export GUARD_RECORD_EXIT=1
    export RUN_NAMES="RUN-1"
    export RUN_STATUSES="active"
    export VERIFY_PINS_EXITS="2"
    run_case "verify-pins exit 2 (missing pin / generic error) -> deny, not drift" DENY
}

case_carveout5_mixed_drift_denies() {
    reset_env
    export GUARD_STOP_REASON="work is still pending"
    export GUARD_RECORD_EXIT=1
    export RUN_NAMES="RUN-1 RUN-2"
    export RUN_STATUSES="active active"
    export VERIFY_PINS_EXITS="4 0"
    run_case "one drifted run beside a clean one -> deny (clean work is advanceable)" DENY
}

case_full_denial_baseline() {
    reset_env
    export GUARD_STOP_REASON="work is still pending: [approve@0 (pending)]"
    export GUARD_RECORD_EXIT=1
    export RUN_NAMES="RUN-1"
    export RUN_STATUSES="active"
    run_case "active run, dispatch open earlier, none of the carve-outs fire" DENY

    # The deny text is the only thing an operator reads, and it used to tell
    # them `run pause` does NOT clear this guard — the exact opposite of what
    # carve-out 4 now does. Assert the retracted claim is gone rather than
    # matching the whole prose, which would break on any rewording.
    if ! grep -q 'Session stop blocked by run-guard' "$STDERR_FILE"; then
        fail "deny wrote no run-guard reason to stderr"
    elif grep -q 'does NOT clear' "$STDERR_FILE"; then
        fail "deny message still says run pause does NOT clear the guard"
    else
        pass "deny message is run-guard's and drops the retracted run-pause claim"
    fi
}

case_complete_run_enumeration() {
    reset_env
    export GUARD_STOP_REASON="work is still pending"
    export GUARD_RECORD_EXIT=1
    local i
    RUN_NAMES="RUN-1"
    RUN_STATUSES="waiting-human"
    for ((i=2; i<=50; i++)); do
        RUN_NAMES+=" RUN-$i"
        RUN_STATUSES+=" waiting-human"
    done
    RUN_NAMES+=" RUN-51"
    RUN_STATUSES+=" active"
    export RUN_NAMES RUN_STATUSES
    run_case "active run beyond the default 50 results still blocks" DENY
    RUN_STATUSES="${RUN_STATUSES%active}waiting-human"
    run_case "all 51 paused runs allow stopping" ALLOW
    RUN_STATUSES="active"
    for ((i=2; i<=51; i++)); do RUN_STATUSES+=" done"; done
    run_case "terminal history cannot hide live work" DENY
}

case_uncertain_run_responses() {
    reset_env
    export GUARD_STOP_REASON="work is still pending"
    export GUARD_RECORD_EXIT=1
    local payload
    for payload in \
        '{"ok":false,"error":"unavailable"}' \
        '{"ok":true,"data":{}}' \
        '{"ok":true,"data":{"runs":null,"total":0}}' \
        '{"ok":true,"data":{"runs":[],"total":1}}' \
        '{"ok":true,"data":{"runs":[{"run":"RUN-1","status":"waiting-human"}],"total":2}}' \
        '{"ok":true,"data":{"runs":[{"status":"waiting-human"}],"total":1}}' \
        '{"ok":true,"data":{"runs":[{"run":"RUN-1","status":"waiting-human"},{"run":"RUN-1","status":"waiting-human"}],"total":2}}' \
        '{"ok":true,"data":{"runs":[{"run":"RUN-1","status":"active"}],"total":1}} {"ok":true,"data":{"runs":[{"run":"RUN-2","status":"waiting-human"}],"total":1}}'; do
        export RUN_STATUS_JSON="$payload"
        run_case "incomplete or invalid run envelope cannot establish an exception: $payload" DENY
    done
    export RUN_STATUS_JSON='{"ok":true,"data":{"runs":[{"run":"RUN-1","status":"waiting-human"}],"total":1}}'
    export RUN_STATUS_EXIT=2
    run_case "successful-looking run JSON from a failed command stays unknown" DENY
}

case_uncertain_guard_record_responses() {
    reset_env
    export GUARD_STOP_REASON="work is still pending"
    export GUARD_RECORD_EXIT=2
    export RUN_NAMES="RUN-1"
    export RUN_STATUSES="active"
    local reason
    for reason in '' 'Error: database is locked' 'Error: RUN-1 not found' \
        '{"ok":false,"error":"unavailable"}' \
        'Error: RUN-1 has an open dispatch:' \
        'Error: RUN-1 has 0 unreconciled discrepancy(s) and will not be offered new work until they are resolved: none'; do
        export GUARD_RECORD_REASON="$reason"
        run_case "guard record exit 2 without affirmative asynchronous state stays unknown: $reason" DENY
    done
    export GUARD_RECORD_REASON='Error: RUN-1 has 1 unreconciled discrepancy(s) and will not be offered new work until they are resolved: reconcile the missing usage'
    run_case "affirmative outstanding reconciliation permits yielding" ALLOW
    export GUARD_RECORD_EXIT=1
    run_case "asynchronous-looking text on an unexpected exit stays unknown" DENY
}

case_engine_and_session_contracts() {
    reset_env
    export GUARD_STOP_REASON="no docket database found"
    export GUARD_RECORD_EXIT=1
    run_case "historical database error text cannot override a current engine denial" DENY
    export STOP_INPUT_JSON='{"stop_hook_active":true}'
    run_case "a repeated Stop-hook block allows the turn to end" ALLOW
    unset STOP_INPUT_JSON
    export GUARD_RECORD_EXIT=2
    export GUARD_RECORD_REASON='Error: RUN-1 has an open dispatch: DISPATCH-1 expiring at 123456789 — reconcile with `docket dispatch close --run RUN-1`, give up on it with `docket dispatch abandon --run RUN-1`, or wait for the TTL to auto-abandon it'
    run_case "async dispatch still permits yielding without jq" ALLOW "$PATH_NO_JQ"
    export GUARD_RECORD_REASON='Error: database is locked'
    run_case "generic exit 2 remains unknown without jq" DENY "$PATH_NO_JQ"
}

case_carveout4_single_run_paused_allows
case_carveout4_one_active_run_denies
case_carveout4_two_runs_both_paused_allows
case_carveout4_planning_run_allows
case_carveout4_terminal_run_ignored_allows
case_carveout4_unknown_status_denies
case_chain_fails_closed_without_jq
case_chain_fails_closed_on_unreadable_run_list
case_regression_guard_stop_success_allows
case_regression_empty_list_cannot_override_engine_denial
case_regression_open_dispatch_allows
case_regression_never_dispatched_engine_contract
case_carveout5_drifted_pins_allow
case_carveout5_clean_pins_deny_unchanged
case_carveout5_exit2_is_not_drift_denies
case_carveout5_mixed_drift_denies
case_full_denial_baseline

case_complete_run_enumeration
case_uncertain_run_responses
case_uncertain_guard_record_responses
case_engine_and_session_contracts

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"

if [ "$FAIL" -ne 0 ]; then
    exit 1
fi

exit 0
