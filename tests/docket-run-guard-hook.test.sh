#!/bin/bash

# Behavior suite for src/user/claude_code/hooks/docket-run-guard-hook.sh.
#
# NOT WIRED INTO CI. `.github/workflows/vorpal.yaml` enumerates test files by
# name and this one is not in that list — running it is a manual/local check
# only, until a follow-up adds the enumeration. Recorded here rather than
# silently, per the activation panel's routing note on this issue.
#
# FOCUS: carve-out 4 — every live run paused (waiting-human) is a sanctioned
# stop, restated from the hook's own header (a step in waiting-human already
# does not block; carve-out 4 makes the RUN-level equivalent hold even though
# `run pause` leaves the run's STEPS in pending, which is what defeats
# `guard stop`/`guard record` and carve-out 3's dispatch check). A handful of
# the pre-existing carve-outs are pinned too, so a future edit cannot silently
# reorder carve-out 4 ahead of one of them.
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
verdict_of() {
    local path_value="$1" rc
    export PATH="$path_value"
    printf '{}' | "$BASH_BIN" "$HOOK" >/dev/null 2>&1
    rc=$?
    if [ "$rc" -eq 2 ]; then
        printf 'DENY'
    else
        printf 'ALLOW'
    fi
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
    unset GUARD_STOP_REASON GUARD_RECORD_EXIT RUN_NAMES RUN_STATUSES DISPATCH_OPENED_DEFAULT
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

case_carveout4_fails_closed_without_jq() {
    reset_env
    export GUARD_STOP_REASON="work is still pending"
    export GUARD_RECORD_EXIT=1
    run_case "jq missing from PATH -> deny (carve-out 4 cannot evaluate)" DENY "$PATH_NO_JQ"
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
}

case_carveout4_single_run_paused_allows
case_carveout4_one_active_run_denies
case_carveout4_two_runs_both_paused_allows
case_carveout4_fails_closed_without_jq
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
