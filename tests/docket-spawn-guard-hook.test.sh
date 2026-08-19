#!/bin/bash

# Behavior suite for src/user/claude_code/hooks/docket-spawn-guard-hook.sh.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. The seam below is a fake `docket` on PATH, so
# the runner needs no engine binary, no database, and no network.
#
# FOCUS: the tribunal.js carve-out (DOT-166). The guard denies every Workflow
# spawn while a write-class reap is unacknowledged, and the conduct skill's
# documented remedy for that hold is to seat a panel by launching tribunal.js
# through the same Workflow tool — so without the carve-out the hold blocks its
# own resolution. The carve-out is pinned from BOTH directions: tribunal.js
# allows while the engine is denying, AND a spawn that only resembles it
# (wave.js, `not-tribunal.js`, a directory named tribunal.js) still denies.
# A carve-out that swallowed every deny would pass the allow cases alone.
#
# ALSO PINNED, because the carve-out sits upstream of them and an edit could
# strand either: the fail-OPEN paths (no `docket`, no active run) and the
# reach-the-engine path (denial text comes from the engine, not the hook).
#
# WHAT THIS SUITE CANNOT SEE: it drives the hook's stdin and PATH only. It
# cannot show that the real `docket guard spawn` denies for the reason the
# carve-out assumes (an unacknowledged reap) — the stub is told to deny. The
# claim that the row half is vacuous without --rows is the engine's, restated
# in the hook's header, and is not re-derived here.
#
# SEAM: PATH holds a fake `docket` that denies or allows per env var and
# touches a marker file whenever it runs, so a carve-out can be shown to
# short-circuit BEFORE the engine is consulted rather than merely agreeing
# with it.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
HOOK="${SPAWN_HOOK:-${REPO_ROOT}/src/user/claude_code/hooks/docket-spawn-guard-hook.sh}"

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

SANDBOX=$(mktemp -d "${TMPDIR:-/tmp}/docket-spawn-guard-test.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$SANDBOX"' EXIT
STDERR_FILE="${SANDBOX}/hook.stderr"
MARKER="${SANDBOX}/engine-consulted"

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

# Fake engine. ACTIVE_RUN names the run `run status --active` reports (empty =
# no active run, the hook's other fail-OPEN). GUARD_SPAWN_REASON, when set,
# makes `guard spawn` deny with that text on stderr — standing in for the
# unacknowledged-reap hold. SPAWN_MARKER is appended to on every invocation so
# a case can assert the engine was never reached.
cat >"${STUB_DIR}/docket" <<'STUB'
#!/bin/bash
[ -n "${SPAWN_MARKER:-}" ] && printf 'x' >>"$SPAWN_MARKER"
case "${1:-}" in
    run)
        case "${2:-}" in
            status)
                if [ -n "${ACTIVE_RUN:-}" ]; then
                    printf '{"ok":true,"data":{"runs":[{"run":"%s"}]}}' "$ACTIVE_RUN"
                else
                    printf '{"ok":true,"data":{"runs":[]}}'
                fi
                ;;
            *)
                printf 'fake docket: unexpected run subcommand: %s\n' "$*" >&2
                exit 64
                ;;
        esac
        ;;
    guard)
        case "${2:-}" in
            spawn)
                if [ -n "${GUARD_SPAWN_REASON:-}" ]; then
                    printf '%s\n' "$GUARD_SPAWN_REASON" >&2
                    exit 2
                fi
                printf '%s\n' "allowed"
                exit 0
                ;;
            *)
                printf 'fake docket: unexpected guard subcommand: %s\n' "$*" >&2
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
PATH_NO_DOCKET="${TOOLS_DIR}"

# THREE-VALUED ON PURPOSE, same reasoning as the run-guard suite: the allow
# path is exit 0 specifically, and any other non-deny status is a broken hook
# rather than an allow.
#
# PATH is scoped to the hook invocation rather than exported: two cases below
# call this directly (not in a `$(…)` subshell) to inspect the marker and the
# stderr afterwards, and a leaked PATH would leave the suite's own `rm`, `grep`
# and `tr` unresolvable in the tool sandbox.
verdict_of() {
    local path_value="$1" payload="$2" rc
    rm -f "$MARKER"
    printf '%s' "$payload" \
        | PATH="$path_value" SPAWN_MARKER="$MARKER" "$BASH_BIN" "$HOOK" \
            >/dev/null 2>"$STDERR_FILE"
    rc=$?
    case "$rc" in
        0) printf 'ALLOW' ;;
        2) printf 'DENY' ;;
        *) printf 'ERROR(%d)' "$rc" ;;
    esac
}

run_case() {
    local label="$1" want="$2" payload="$3" path_value="${4:-$PATH_WITH_DOCKET}" got
    got=$(verdict_of "$path_value" "$payload")
    if [ "$got" = "$want" ]; then
        pass "${label} (${want})"
    else
        fail "${label} (want ${want}, got ${got})"
    fi
}

reset_env() {
    unset ACTIVE_RUN GUARD_SPAWN_REASON
}

# The hold every case below is decided against: a real reap denial, so an
# ALLOW can only come from the carve-out and never from an agreeable engine.
HOLD='spawn denied: unacknowledged reaps in bounded classes hold headroom'

workflow_payload() {
    jq -nc --arg p "$1" '{tool_name:"Workflow", tool_input:{scriptPath:$p, args:{}}}'
}

# ---- CARVE-OUT: tribunal.js allows through an active hold ----
case_tribunal_installed_path_allows() {
    reset_env
    export ACTIVE_RUN="RUN-14"
    export GUARD_SPAWN_REASON="$HOLD"
    run_case "tribunal.js at the installed path, reap held" ALLOW \
        "$(workflow_payload "$HOME/.claude/workflows/tribunal.js")"
}

case_tribunal_source_path_allows() {
    reset_env
    export ACTIVE_RUN="RUN-14"
    export GUARD_SPAWN_REASON="$HOLD"
    # The skills' documented fallback when nothing is installed. Pinning it is
    # the whole reason the match is on basename rather than one absolute path.
    run_case "tribunal.js at the dotfiles source path, reap held" ALLOW \
        "$(workflow_payload "${REPO_ROOT}/src/user/claude_code/workflows/tribunal.js")"
}

case_tribunal_short_circuits_before_engine() {
    reset_env
    export ACTIVE_RUN="RUN-14"
    export GUARD_SPAWN_REASON="$HOLD"
    verdict_of "$PATH_WITH_DOCKET" \
        "$(workflow_payload "$HOME/.claude/workflows/tribunal.js")" >/dev/null
    if [ -s "$MARKER" ]; then
        fail "tribunal.js carve-out ran before the engine was consulted (docket was invoked)"
    else
        pass "tribunal.js carve-out ran before the engine was consulted (docket never invoked)"
    fi
}

# ---- The carve-out is not a blanket allow ----
case_wave_still_denies() {
    reset_env
    export ACTIVE_RUN="RUN-14"
    export GUARD_SPAWN_REASON="$HOLD"
    run_case "wave.js under the same hold" DENY \
        "$(workflow_payload "$HOME/.claude/workflows/wave.js")"
}

case_agent_call_still_denies() {
    reset_env
    export ACTIVE_RUN="RUN-14"
    export GUARD_SPAWN_REASON="$HOLD"
    # An `Agent` spawn carries no scriptPath at all; it must fall straight
    # through to the guard rather than matching an empty basename.
    run_case "Agent spawn (no scriptPath) under the same hold" DENY \
        '{"tool_name":"Agent","tool_input":{"prompt":"review this","subagent_type":"general-purpose"}}'
}

case_lookalike_basename_still_denies() {
    reset_env
    export ACTIVE_RUN="RUN-14"
    export GUARD_SPAWN_REASON="$HOLD"
    run_case "a script merely ending in tribunal.js (not-tribunal.js)" DENY \
        "$(workflow_payload "$HOME/.claude/workflows/not-tribunal.js")"
}

case_tribunal_as_directory_still_denies() {
    reset_env
    export ACTIVE_RUN="RUN-14"
    export GUARD_SPAWN_REASON="$HOLD"
    run_case "tribunal.js as a DIRECTORY component, wave.js as the script" DENY \
        "$(workflow_payload "$HOME/.claude/workflows/tribunal.js/wave.js")"
}

case_denial_text_is_the_engines() {
    reset_env
    export ACTIVE_RUN="RUN-14"
    export GUARD_SPAWN_REASON="$HOLD"
    verdict_of "$PATH_WITH_DOCKET" \
        "$(workflow_payload "$HOME/.claude/workflows/wave.js")" >/dev/null
    if grep -q 'unacknowledged reaps in bounded classes hold headroom' "$STDERR_FILE"; then
        pass "deny forwards the engine's own reason on stderr"
    else
        fail "deny lost the engine's reason (stderr: $(tr '\n' ' ' <"$STDERR_FILE"))"
    fi
}

# ---- Pre-existing paths the carve-out now sits upstream of ----
case_no_active_run_allows() {
    reset_env
    export GUARD_SPAWN_REASON="$HOLD"
    run_case "no active run — this session is not the engine's business" ALLOW \
        "$(workflow_payload "$HOME/.claude/workflows/wave.js")"
}

case_missing_docket_allows() {
    reset_env
    run_case "no docket binary on PATH (fail-OPEN on a tooling gap)" ALLOW \
        "$(workflow_payload "$HOME/.claude/workflows/wave.js")" "$PATH_NO_DOCKET"
}

case_missing_jq_allows() {
    reset_env
    export ACTIVE_RUN="RUN-14"
    export GUARD_SPAWN_REASON="$HOLD"
    # Documented, pre-existing and unchanged by the carve-out: without jq the
    # run id cannot be read, so the hook allows. The carve-out likewise needs
    # jq, and skipping it here changes nothing — the allow arrives anyway.
    run_case "no jq on PATH (fail-OPEN, run id unreadable)" ALLOW \
        "$(workflow_payload "$HOME/.claude/workflows/wave.js")" "$PATH_NO_JQ"
}

case_empty_stdin_still_guards() {
    reset_env
    export ACTIVE_RUN="RUN-14"
    export GUARD_SPAWN_REASON="$HOLD"
    # No hook input at all (a harness that sends nothing): the carve-out has
    # nothing to read and must not fire, so the guard still decides.
    run_case "empty stdin — carve-out cannot fire, guard still decides" DENY ''
}

case_tribunal_installed_path_allows
case_tribunal_source_path_allows
case_tribunal_short_circuits_before_engine
case_wave_still_denies
case_agent_call_still_denies
case_lookalike_basename_still_denies
case_tribunal_as_directory_still_denies
case_denial_text_is_the_engines
case_no_active_run_allows
case_missing_docket_allows
case_missing_jq_allows
case_empty_stdin_still_guards

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
