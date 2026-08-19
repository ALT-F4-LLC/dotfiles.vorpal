#!/bin/bash

# Behavior suite for src/user/claude_code/hooks/docket-run-guard-hook.sh.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list, beside the commit-guard suite. The seam below
# is a fake `docket` on PATH, so the runner needs no engine binary, no
# database, and no network.
#
# FOCUS: carve-out 4 — a project whose every live run is waiting on a person
# (waiting-human) or not yet activated (planning) is a sanctioned stop,
# restated from the hook's own header (a step in waiting-human already does not
# block; carve-out 4 makes the RUN-level equivalent hold even though
# `run pause` leaves the run's STEPS in pending, which is what defeats
# `guard stop`/`guard record` and carve-out 3's dispatch check). The
# pre-existing carve-outs are pinned too, so an edit cannot delete one of them
# while carve-out 4 masks the loss.
#
# WHAT THIS SUITE CANNOT SEE: every carve-out is a pure ALLOW short-circuit, so
# reordering them changes only how many subprocesses run, never a verdict — no
# case here detects a reordering, and none claims to. Carve-out 4's PRESENCE is
# pinned by its ALLOW cases alone: a fail-closed case denies with or without
# it, so those cases pin the chain as a whole, not any one block.
#
# SEAM: PATH holds a fake `docket` whose answers to `guard stop`, `run
# status --json`, `guard record`, and `events list --run <id> --json` are all
# driven by env vars set per case — a small test, single process, no network,
# no real .docket database or run.

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

# Fake engine. RUN_NAMES / RUN_STATUSES are parallel space-separated lists
# consulted by both `run status --json` (carve-outs 1b, 3's run list, and 4)
# and, via DISPATCH_OPENED_DEFAULT, by `events list` (carve-out 3). GUARD_
# prefixed vars drive the two direct guard verbs.
cat >"${STUB_DIR}/docket" <<'STUB'
#!/bin/bash
build_runs_json() {
    names=(${RUN_NAMES:-})
    statuses=(${RUN_STATUSES:-})
    json="[]"
    i=0
    for n in "${names[@]}"; do
        s="${statuses[$i]}"
        json=$(printf '%s' "$json" | jq -c --arg run "$n" --arg status "$s" '. + [{"run":$run,"status":$status}]')
        i=$((i + 1))
    done
    printf '%s' "$json"
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
                if [ -n "${RUN_STATUS_UNREADABLE:-}" ]; then
                    # The hook's other named fail-closed input: an answer that
                    # is not JSON at all (engine crash, truncated pipe).
                    printf 'panic: engine unavailable'
                    exit 0
                fi
                RUNS=$(build_runs_json)
                printf '{"ok":true,"data":{"runs":%s}}' "$RUNS"
                ;;
            *)
                printf 'fake docket: unexpected run subcommand: %s\n' "$*" >&2
                exit 64
                ;;
        esac
        ;;
    events)
        case "${2:-}" in
            list)
                OPENED="${DISPATCH_OPENED_DEFAULT:-0}"
                if [ "$OPENED" -gt 0 ] 2>/dev/null; then
                    printf '{"ok":true,"data":{"events":[{"kind":"dispatch-opened"}]}}'
                else
                    printf '{"ok":true,"data":{"events":[{"kind":"run-activated"}]}}'
                fi
                ;;
            *)
                printf 'fake docket: unexpected events subcommand: %s\n' "$*" >&2
                exit 64
                ;;
        esac
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
    local path_value="$1" rc
    export PATH="$path_value"
    printf '{}' | "$BASH_BIN" "$HOOK" >/dev/null 2>"$STDERR_FILE"
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
    unset GUARD_STOP_REASON GUARD_RECORD_EXIT RUN_NAMES RUN_STATUSES DISPATCH_OPENED_DEFAULT RUN_STATUS_UNREADABLE
}

# ---- CARVE-OUT 4: every live run paused (waiting-human) allows the stop ----
case_carveout4_single_run_paused_allows() {
    reset_env
    export GUARD_STOP_REASON="work is still pending: [approve@0 (pending)]"
    export GUARD_RECORD_EXIT=1
    export RUN_NAMES="RUN-1"
    export RUN_STATUSES="waiting-human"
    export DISPATCH_OPENED_DEFAULT=1
    run_case "single live run, waiting-human, dispatch was opened earlier" ALLOW
}

case_carveout4_one_active_run_denies() {
    reset_env
    export GUARD_STOP_REASON="work is still pending"
    export GUARD_RECORD_EXIT=1
    export RUN_NAMES="RUN-1 RUN-2"
    export RUN_STATUSES="waiting-human active"
    export DISPATCH_OPENED_DEFAULT=1
    run_case "one of two live runs is active, not waiting-human" DENY
}

case_carveout4_two_runs_both_paused_allows() {
    reset_env
    export GUARD_STOP_REASON="work is still pending"
    export GUARD_RECORD_EXIT=1
    export RUN_NAMES="RUN-1 RUN-2"
    export RUN_STATUSES="waiting-human waiting-human"
    export DISPATCH_OPENED_DEFAULT=1
    run_case "two live runs, both waiting-human" ALLOW
}

case_carveout4_planning_run_allows() {
    reset_env
    export GUARD_STOP_REASON="work is still pending"
    export GUARD_RECORD_EXIT=1
    export RUN_NAMES="RUN-1 RUN-2"
    export RUN_STATUSES="waiting-human planning"
    export DISPATCH_OPENED_DEFAULT=1
    run_case "paused run plus an unactivated (planning) run" ALLOW
}

case_carveout4_terminal_run_ignored_allows() {
    reset_env
    export GUARD_STOP_REASON="work is still pending"
    export GUARD_RECORD_EXIT=1
    export RUN_NAMES="RUN-1 RUN-2"
    export RUN_STATUSES="waiting-human done"
    export DISPATCH_OPENED_DEFAULT=1
    run_case "paused run plus a done run (terminal filter drops the done one)" ALLOW
}

case_carveout4_unknown_status_denies() {
    reset_env
    export GUARD_STOP_REASON="work is still pending"
    export GUARD_RECORD_EXIT=1
    export RUN_NAMES="RUN-1 RUN-2"
    export RUN_STATUSES="waiting-human cancelled"
    export DISPATCH_OPENED_DEFAULT=1
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

case_regression_no_live_runs_allows() {
    reset_env
    export GUARD_STOP_REASON="work is still pending"
    run_case "zero live runs in project -> allow (carve-out 1b)" ALLOW
}

case_regression_open_dispatch_allows() {
    reset_env
    export GUARD_STOP_REASON="work is still pending"
    export GUARD_RECORD_EXIT=2
    export RUN_NAMES="RUN-1"
    export RUN_STATUSES="active"
    run_case "dispatch open (guard record exits 2) -> allow (carve-out 2)" ALLOW
}

case_regression_never_dispatched_allows() {
    reset_env
    export GUARD_STOP_REASON="work is still pending"
    export GUARD_RECORD_EXIT=1
    export RUN_NAMES="RUN-1"
    export RUN_STATUSES="active"
    run_case "never dispatched, run still active -> allow (carve-out 3)" ALLOW
}

case_full_denial_baseline() {
    reset_env
    export GUARD_STOP_REASON="work is still pending: [approve@0 (pending)]"
    export GUARD_RECORD_EXIT=1
    export RUN_NAMES="RUN-1"
    export RUN_STATUSES="active"
    export DISPATCH_OPENED_DEFAULT=1
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

case_carveout4_single_run_paused_allows
case_carveout4_one_active_run_denies
case_carveout4_two_runs_both_paused_allows
case_carveout4_planning_run_allows
case_carveout4_terminal_run_ignored_allows
case_carveout4_unknown_status_denies
case_chain_fails_closed_without_jq
case_chain_fails_closed_on_unreadable_run_list
case_regression_guard_stop_success_allows
case_regression_no_live_runs_allows
case_regression_open_dispatch_allows
case_regression_never_dispatched_allows
case_full_denial_baseline

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"

if [ "$FAIL" -ne 0 ]; then
    exit 1
fi

exit 0
