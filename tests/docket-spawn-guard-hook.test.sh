#!/bin/bash

# Behavior suite for src/user/claude_code/hooks/docket-spawn-guard-hook.sh.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. The seam below is a fake `docket` on PATH, so
# the runner needs no engine binary, no database, and no network.
#
# FOCUS: the tribunal path (DOT-166). The guard denies every Workflow spawn
# while a write-class reap is unacknowledged, and the conduct skill's
# documented remedy for that hold is to seat a panel by launching tribunal.js
# through the same Workflow tool — so the hold blocked its own resolution. The
# engine's answer is `guard spawn --deciding-vote PROPOSAL-N` (DKT-236); this
# hook's whole job is to notice a tribunal.js launch, lift the proposal id out
# of its args, and pass it along.
#
# So what is pinned here is FORWARDING, not allowing. The hook must reach the
# engine and hand it the id — it must NOT decide the spawn itself. That
# distinction is the point: an earlier version exited 0 on any tribunal.js
# launch, which admitted proposal-less and closed-proposal launches alike and
# logged no `spawn-admitted` audit event. Cases below assert the exact argv,
# and assert that the verdict still comes back from the engine both ways.
#
# ALSO PINNED, because the tribunal branch sits upstream of them: the fail-OPEN
# paths (no `docket`, no active run, no jq) and the ordinary path (a non-
# tribunal launch reaches the engine with no extra flags, and its denial text
# is the engine's).
#
# WHAT THIS SUITE CANNOT SEE: it drives the hook's stdin and PATH only. The
# stub answers however a case tells it to, so nothing here shows what the REAL
# engine does with `--deciding-vote` — that the proposal must exist and be
# open, that only the reap half is relaxed, and that the admission is logged
# are the engine's contract, restated in the hook's header and tested there.
#
# SEAM: PATH holds a fake `docket` that denies or allows per env var and
# appends its own argv to a log file, so a case can assert what the hook asked
# the engine rather than only what came back.

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
# unacknowledged-reap hold. SPAWN_MARKER records every `guard spawn` argv, so a
# case can assert what was ASKED and not only what was answered.
cat >"${STUB_DIR}/docket" <<'STUB'
#!/bin/bash
if [ -n "${SPAWN_MARKER:-}" ] && [ "${1:-}" = "guard" ]; then
    printf '%s\n' "$*" >>"$SPAWN_MARKER"
fi
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

# args is emitted as a real OBJECT here and as a JSON STRING in the sibling
# below, because the harness stringifies `args` on the way to the tool and the
# hook has to read the id out of either shape.
workflow_payload() {
    jq -nc --arg p "$1" --arg v "${2:-}" \
        '{tool_name:"Workflow", tool_input:{scriptPath:$p,
          args:(if $v == "" then {} else {voteId:$v} end)}}'
}

workflow_payload_stringified_args() {
    jq -nc --arg p "$1" --arg v "$2" \
        '{tool_name:"Workflow", tool_input:{scriptPath:$p,
          args:({voteId:$v} | tojson)}}'
}

asked() { # the argv of the last `guard spawn` the hook ran, or empty
    [ -f "$MARKER" ] && tail -n 1 "$MARKER" || printf ''
}

expect_argv() {
    local label="$1" want="$2" got
    got=$(asked)
    if [ "$got" = "$want" ]; then
        pass "${label}"
    else
        fail "${label} (asked: ${got:-<the engine was never reached>})"
    fi
}

# ---- FORWARDING: a tribunal.js launch carries its proposal to the engine ----
case_tribunal_installed_path_forwards() {
    reset_env
    export ACTIVE_RUN="RUN-14"
    unset GUARD_SPAWN_REASON
    verdict_of "$PATH_WITH_DOCKET" \
        "$(workflow_payload "$HOME/.claude/workflows/tribunal.js" DKT-V46)" >/dev/null
    expect_argv "tribunal.js at the installed path forwards its proposal" \
        "guard spawn --run RUN-14 --deciding-vote DKT-V46"
}

case_tribunal_source_path_forwards() {
    reset_env
    export ACTIVE_RUN="RUN-14"
    unset GUARD_SPAWN_REASON
    # The skills' documented fallback when nothing is installed. Pinning it is
    # the whole reason the match is on basename rather than one absolute path.
    verdict_of "$PATH_WITH_DOCKET" \
        "$(workflow_payload "${REPO_ROOT}/src/user/claude_code/workflows/tribunal.js" DOT-V3)" >/dev/null
    expect_argv "tribunal.js at the dotfiles source path forwards too" \
        "guard spawn --run RUN-14 --deciding-vote DOT-V3"
}

case_tribunal_stringified_args_forwards() {
    reset_env
    export ACTIVE_RUN="RUN-14"
    unset GUARD_SPAWN_REASON
    # The harness stringifies `args`, so this is the shape the hook actually
    # meets in production; the object form above is the documented one.
    verdict_of "$PATH_WITH_DOCKET" \
        "$(workflow_payload_stringified_args "$HOME/.claude/workflows/tribunal.js" DKT-V46)" >/dev/null
    expect_argv "args arriving as a JSON STRING still yields the proposal" \
        "guard spawn --run RUN-14 --deciding-vote DKT-V46"
}

case_tribunal_verdict_still_the_engines() {
    reset_env
    export ACTIVE_RUN="RUN-14"
    export GUARD_SPAWN_REASON="$HOLD"
    # The hook forwards; it does not decide. A stub that refuses even with the
    # flag must still produce a DENY — otherwise the hook is allowing on its
    # own authority, which is the defect this replaced.
    run_case "a refused --deciding-vote is still a DENY" DENY \
        "$(workflow_payload "$HOME/.claude/workflows/tribunal.js" DKT-V46)"
}

# ---- The tribunal branch is not a blanket allow ----
case_tribunal_without_proposal_asks_plainly() {
    reset_env
    export ACTIVE_RUN="RUN-14"
    export GUARD_SPAWN_REASON="$HOLD"
    # No voteId: the old hook admitted this outright. It must now reach the
    # engine with no flag, and be denied like anything else.
    run_case "tribunal.js carrying NO proposal is denied, not admitted" DENY \
        "$(workflow_payload "$HOME/.claude/workflows/tribunal.js")"
    expect_argv "  ...and asked the plain question, with no --deciding-vote" \
        "guard spawn --run RUN-14"
}

case_tribunal_malformed_proposal_asks_plainly() {
    reset_env
    export ACTIVE_RUN="RUN-14"
    export GUARD_SPAWN_REASON="$HOLD"
    run_case "a malformed proposal id is dropped, not forwarded" DENY \
        "$(workflow_payload "$HOME/.claude/workflows/tribunal.js" "not-an-id; rm -rf /")"
    expect_argv "  ...and asked the plain question" \
        "guard spawn --run RUN-14"
}

case_wave_still_denies() {
    reset_env
    export ACTIVE_RUN="RUN-14"
    export GUARD_SPAWN_REASON="$HOLD"
    run_case "wave.js under the same hold" DENY \
        "$(workflow_payload "$HOME/.claude/workflows/wave.js" DKT-V46)"
    expect_argv "  ...and a voteId on a NON-tribunal launch is ignored" \
        "guard spawn --run RUN-14"
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
        "$(workflow_payload "$HOME/.claude/workflows/not-tribunal.js" DKT-V46)"
    expect_argv "  ...and it forwards nothing" "guard spawn --run RUN-14"
}

case_tribunal_as_directory_still_denies() {
    reset_env
    export ACTIVE_RUN="RUN-14"
    export GUARD_SPAWN_REASON="$HOLD"
    run_case "tribunal.js as a DIRECTORY component, wave.js as the script" DENY \
        "$(workflow_payload "$HOME/.claude/workflows/tribunal.js/wave.js" DKT-V46)"
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
    # No hook input at all (a harness that sends nothing): there is no
    # scriptPath and no proposal to read, so the plain question is asked.
    run_case "empty stdin — nothing to forward, guard still decides" DENY ''
}

case_tribunal_installed_path_forwards
case_tribunal_source_path_forwards
case_tribunal_stringified_args_forwards
case_tribunal_verdict_still_the_engines
case_tribunal_without_proposal_asks_plainly
case_tribunal_malformed_proposal_asks_plainly
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
