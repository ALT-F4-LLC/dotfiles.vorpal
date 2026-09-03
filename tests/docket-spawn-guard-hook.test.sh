#!/bin/bash

# Behavior suite for src/user/claude_code/hooks/docket-spawn-guard-hook.sh.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. The seam below is a fake `docket` on PATH, so
# the runner needs no engine binary, no database, and no network.
#
# TWO THINGS ARE PINNED.
#
# First, that the hook asks `guard spawn --active` and never resolves a run
# itself. An earlier version asked about `runs[0]` of `run status --active`,
# the newest run, so with two concurrent active runs the older run's reap hold
# went unasked. The fake engine below models the engine's documented --active
# semantics — walk the active runs oldest-first, deny on the first that holds,
# naming it — so a hook that regressed to naming one run would be allowed
# where the suite expects a deny.
#
# Second, the tribunal path. The guard denies every Workflow spawn while a
# write-class reap is unacknowledged, and the docket-run skill's documented
# remedy for that hold is to seat a panel by launching tribunal.js through the
# same Workflow tool — so the hold blocked its own resolution. The engine's
# answer is `guard spawn --run RUN-N --deciding-vote PROPOSAL-N`, which it
# refuses to compose with --active. So what is pinned is FORWARDING, not
# allowing: under a hold the hook must re-ask about the run the ENGINE named
# and hand it the proposal id — it must NOT decide the spawn itself. An
# earlier version exited 0 on any tribunal.js launch, which admitted
# proposal-less and closed-proposal launches alike and logged no
# `spawn-admitted` audit event. Cases below assert the exact argv, and assert
# that the verdict still comes back from the engine both ways.
#
# ALSO PINNED: the fail-OPEN path (no `docket`), the engine's own allow over
# no active run, and the ordinary path (a non-tribunal launch reaches the
# engine with no extra flags, and its denial text is the engine's).
#
# WHAT THIS SUITE CANNOT SEE: it drives the hook's stdin and PATH only. The
# stub answers however a case tells it to, so nothing here shows what the REAL
# engine does with `--deciding-vote` — that the proposal must exist and be
# open, that only the reap half is relaxed, and that the admission is logged
# are the engine's contract, restated in the hook's header and tested there.
#
# SEAM: PATH holds a fake `docket` that answers per env var and appends every
# argv it receives to a log file, so a case can assert what the hook asked the
# engine rather than only what came back.

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

# Fake engine. ACTIVE_RUNS lists the project's active runs OLDEST FIRST (empty
# = no active run). HELD_RUNS names those holding an unacknowledged write-class
# reap. `guard spawn --active` walks ACTIVE_RUNS and denies on the first held
# one, naming it, the way the engine documents; `guard spawn --run R` asks
# about R alone. ADMIT_VOTE is the one proposal id whose --deciding-vote the
# stub honors, standing in for "exists and is open". SPAWN_MARKER records
# every argv, so a case can assert what was ASKED and not only what was
# answered — including that `run status` is never asked.
#
# Bash builtins only: the hook's PATH sandbox below carries no grep.
cat >"${STUB_DIR}/docket" <<'STUB'
#!/bin/bash
if [ -n "${SPAWN_MARKER:-}" ]; then
    printf '%s\n' "$*" >>"$SPAWN_MARKER"
fi
held() {
    case " ${HELD_RUNS:-} " in
        *" $1 "*) return 0 ;;
    esac
    return 1
}
deny() {
    local reason="$1: spawn denied: unacknowledged reaps in bounded classes hold headroom"
    if [ "$JSON" = yes ]; then
        printf '{"ok":false,"error":"%s","code":"NOT_FOUND"}\n' "$reason"
    else
        printf '✘ Error: %s\n' "$reason" >&2
    fi
    exit 2
}
allow() {
    if [ "$JSON" = yes ]; then
        printf '{"ok":true,"data":{"allowed":true},"message":"allowed"}\n'
    else
        printf '✔ allowed\n'
    fi
    exit 0
}
[ "${1:-} ${2:-}" = "guard spawn" ] || {
    printf 'fake docket: unexpected invocation: %s\n' "$*" >&2
    exit 64
}
shift 2
MODE="" RUN="" VOTE="" JSON=no
while [ $# -gt 0 ]; do
    case "$1" in
        --active) MODE=active ;;
        --run) RUN="$2"; shift ;;
        --deciding-vote) VOTE="$2"; shift ;;
        --json) JSON=yes ;;
        *) printf 'fake docket: unexpected flag: %s\n' "$1" >&2; exit 64 ;;
    esac
    shift
done
if [ "$MODE" = active ]; then
    [ -z "$VOTE" ] || { printf '✘ Error: --active does not take --deciding-vote\n' >&2; exit 3; }
    for r in ${ACTIVE_RUNS:-}; do
        held "$r" && deny "$r"
    done
    allow
fi
[ -n "$RUN" ] || { printf '✘ Error: --run is required\n' >&2; exit 3; }
if held "$RUN"; then
    [ -n "$VOTE" ] && [ "$VOTE" = "${ADMIT_VOTE:-}" ] && allow
    deny "$RUN"
fi
allow
STUB
chmod +x "${STUB_DIR}/docket"

PATH_WITH_DOCKET="${STUB_DIR}:${TOOLS_DIR}"
PATH_NO_JQ="${STUB_DIR}:${TOOLS_DIR_NO_JQ}"
PATH_NO_DOCKET="${TOOLS_DIR}"

# THREE-VALUED ON PURPOSE, same reasoning as the run-guard suite: the allow
# path is exit 0 specifically, and any other non-deny status is a broken hook
# rather than an allow.
#
# PATH is scoped to the hook invocation rather than exported: cases below call
# this directly (not in a `$(…)` subshell) to inspect the marker and the
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
    unset ACTIVE_RUNS HELD_RUNS ADMIT_VOTE
}

# The common fixture: one active run holding a real reap, so an ALLOW can only
# come from the carve-out and never from an agreeable engine.
one_held_run() {
    reset_env
    export ACTIVE_RUNS="RUN-14"
    export HELD_RUNS="RUN-14"
}

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

asked() { # the argv of the last `docket` call the hook made, or empty
    [ -f "$MARKER" ] && tail -n 1 "$MARKER" || printf ''
}

asked_all() { # every argv, one per line
    [ -f "$MARKER" ] && cat "$MARKER" || printf ''
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

expect_never_asked() {
    local label="$1" pattern="$2"
    if asked_all | grep -q -- "$pattern"; then
        fail "${label} (asked: $(asked_all | tr '\n' ';'))"
    else
        pass "${label}"
    fi
}

# ---- Every active run is asked, in one engine call ----
case_two_active_runs_older_holds() {
    reset_env
    # RUN-15 is the newer run, the one `runs[0]` used to name. Only the older
    # holds, so a hook asking about the newest alone would be allowed here.
    export ACTIVE_RUNS="RUN-14 RUN-15"
    export HELD_RUNS="RUN-14"
    run_case "two active runs, only the OLDER holds a reap" DENY \
        "$(workflow_payload "$HOME/.claude/workflows/wave.js")"
    expect_argv "  ...asked over every active run" "guard spawn --active"
    if grep -q 'RUN-14' "$STDERR_FILE"; then
        pass "  ...and the denial names the older run"
    else
        fail "  ...denial did not name RUN-14 (stderr: $(tr '\n' ' ' <"$STDERR_FILE"))"
    fi
}

case_never_resolves_a_run() {
    one_held_run
    verdict_of "$PATH_WITH_DOCKET" \
        "$(workflow_payload "$HOME/.claude/workflows/wave.js")" >/dev/null
    expect_never_asked "the hook never asks run status for a run id" "^run "
    expect_never_asked "  ...and never names a run on the plain path" "--run"
}

# ---- FORWARDING: a tribunal.js launch carries its proposal to the engine ----
case_tribunal_installed_path_forwards() {
    one_held_run
    export ADMIT_VOTE="DKT-V46"
    run_case "tribunal.js at the installed path is admitted past the hold" ALLOW \
        "$(workflow_payload "$HOME/.claude/workflows/tribunal.js" DKT-V46)"
    expect_argv "  ...by forwarding its proposal onto the held run" \
        "guard spawn --run RUN-14 --deciding-vote DKT-V46"
}

case_tribunal_source_path_forwards() {
    one_held_run
    export ADMIT_VOTE="DOT-V3"
    # The skills' documented fallback when nothing is installed. Pinning it is
    # the whole reason the match is on basename rather than one absolute path.
    verdict_of "$PATH_WITH_DOCKET" \
        "$(workflow_payload "${REPO_ROOT}/src/user/claude_code/workflows/tribunal.js" DOT-V3)" >/dev/null
    expect_argv "tribunal.js at the dotfiles source path forwards too" \
        "guard spawn --run RUN-14 --deciding-vote DOT-V3"
}

case_tribunal_stringified_args_forwards() {
    one_held_run
    export ADMIT_VOTE="DKT-V46"
    # The harness stringifies `args`, so this is the shape the hook actually
    # meets in production; the object form above is the documented one.
    verdict_of "$PATH_WITH_DOCKET" \
        "$(workflow_payload_stringified_args "$HOME/.claude/workflows/tribunal.js" DKT-V46)" >/dev/null
    expect_argv "args arriving as a JSON STRING still yields the proposal" \
        "guard spawn --run RUN-14 --deciding-vote DKT-V46"
}

case_tribunal_admitted_onto_the_run_the_engine_named() {
    reset_env
    export ACTIVE_RUNS="RUN-14 RUN-15"
    export HELD_RUNS="RUN-14"
    export ADMIT_VOTE="DKT-V46"
    # The carve-out is a one-run act, and the run is the engine's to name:
    # the older, holding run — not the newest, which `runs[0]` would pick.
    run_case "tribunal.js with two active runs is admitted" ALLOW \
        "$(workflow_payload "$HOME/.claude/workflows/tribunal.js" DKT-V46)"
    expect_argv "  ...onto the run the engine's denial named" \
        "guard spawn --run RUN-14 --deciding-vote DKT-V46"
}

case_tribunal_verdict_still_the_engines() {
    one_held_run
    unset ADMIT_VOTE
    # The hook forwards; it does not decide. A stub that refuses even with the
    # flag must still produce a DENY — otherwise the hook is allowing on its
    # own authority, which is the defect this replaced.
    run_case "a refused --deciding-vote is still a DENY" DENY \
        "$(workflow_payload "$HOME/.claude/workflows/tribunal.js" DKT-V46)"
    expect_argv "  ...after the proposal was forwarded" \
        "guard spawn --run RUN-14 --deciding-vote DKT-V46"
}

case_tribunal_under_no_hold_claims_nothing() {
    reset_env
    export ACTIVE_RUNS="RUN-14"
    export ADMIT_VOTE="DKT-V46"
    # Nothing holds, so there is nothing to be admitted past: the carve-out
    # is never claimed and the plain question decides.
    run_case "tribunal.js with no hold anywhere" ALLOW \
        "$(workflow_payload "$HOME/.claude/workflows/tribunal.js" DKT-V46)"
    expect_never_asked "  ...claims no carve-out" "--deciding-vote"
}

# ---- The tribunal branch is not a blanket allow ----
case_tribunal_without_proposal_asks_plainly() {
    one_held_run
    # No voteId: the old hook admitted this outright. It must now reach the
    # engine with no flag, and be denied like anything else.
    run_case "tribunal.js carrying NO proposal is denied, not admitted" DENY \
        "$(workflow_payload "$HOME/.claude/workflows/tribunal.js")"
    expect_argv "  ...and asked the plain question, with no --deciding-vote" \
        "guard spawn --active"
}

case_tribunal_malformed_proposal_asks_plainly() {
    one_held_run
    run_case "a malformed proposal id is dropped, not forwarded" DENY \
        "$(workflow_payload "$HOME/.claude/workflows/tribunal.js" "not-an-id; rm -rf /")"
    expect_argv "  ...and asked the plain question" "guard spawn --active"
}

case_wave_still_denies() {
    one_held_run
    export ADMIT_VOTE="DKT-V46"
    run_case "wave.js under the same hold" DENY \
        "$(workflow_payload "$HOME/.claude/workflows/wave.js" DKT-V46)"
    expect_argv "  ...and a voteId on a NON-tribunal launch is ignored" \
        "guard spawn --active"
}

case_agent_call_still_denies() {
    one_held_run
    # An `Agent` spawn carries no scriptPath at all; it must fall straight
    # through to the guard rather than matching an empty basename.
    run_case "Agent spawn (no scriptPath) under the same hold" DENY \
        '{"tool_name":"Agent","tool_input":{"prompt":"review this","subagent_type":"general-purpose"}}'
}

case_lookalike_basename_still_denies() {
    one_held_run
    export ADMIT_VOTE="DKT-V46"
    run_case "a script merely ending in tribunal.js (not-tribunal.js)" DENY \
        "$(workflow_payload "$HOME/.claude/workflows/not-tribunal.js" DKT-V46)"
    expect_argv "  ...and it forwards nothing" "guard spawn --active"
}

case_tribunal_as_directory_still_denies() {
    one_held_run
    export ADMIT_VOTE="DKT-V46"
    run_case "tribunal.js as a DIRECTORY component, wave.js as the script" DENY \
        "$(workflow_payload "$HOME/.claude/workflows/tribunal.js/wave.js" DKT-V46)"
}

case_denial_text_is_the_engines() {
    one_held_run
    verdict_of "$PATH_WITH_DOCKET" \
        "$(workflow_payload "$HOME/.claude/workflows/wave.js")" >/dev/null
    if grep -q 'unacknowledged reaps in bounded classes hold headroom' "$STDERR_FILE"; then
        pass "deny forwards the engine's own reason on stderr"
    else
        fail "deny lost the engine's reason (stderr: $(tr '\n' ' ' <"$STDERR_FILE"))"
    fi
}

# ---- Paths the carve-out sits upstream of ----
case_no_active_run_allows() {
    reset_env
    run_case "no active run — the engine allows over an empty set" ALLOW \
        "$(workflow_payload "$HOME/.claude/workflows/wave.js")"
    expect_argv "  ...and the hook still asked, rather than deciding" \
        "guard spawn --active"
}

case_missing_docket_allows() {
    reset_env
    run_case "no docket binary on PATH (fail-OPEN on a tooling gap)" ALLOW \
        "$(workflow_payload "$HOME/.claude/workflows/wave.js")" "$PATH_NO_DOCKET"
}

case_missing_jq_still_guards() {
    one_held_run
    export ADMIT_VOTE="DKT-V46"
    # This used to ALLOW: jq read the run id, and no id meant no question. The
    # engine now resolves the runs itself, so jq is only needed to read a
    # tribunal's proposal id. Without it the carve-out is lost and the plain
    # question still reaches the engine — a missing tool must not widen into
    # a bypass of the hold when the question can still be asked.
    run_case "no jq on PATH — the plain question is still asked" DENY \
        "$(workflow_payload "$HOME/.claude/workflows/tribunal.js" DKT-V46)" "$PATH_NO_JQ"
    expect_argv "  ...with no carve-out claimed" "guard spawn --active"
}

case_empty_stdin_still_guards() {
    one_held_run
    # No hook input at all (a harness that sends nothing): there is no
    # scriptPath and no proposal to read, so the plain question is asked.
    run_case "empty stdin — nothing to forward, guard still decides" DENY ''
}

case_two_active_runs_older_holds
case_never_resolves_a_run
case_tribunal_installed_path_forwards
case_tribunal_source_path_forwards
case_tribunal_stringified_args_forwards
case_tribunal_admitted_onto_the_run_the_engine_named
case_tribunal_verdict_still_the_engines
case_tribunal_under_no_hold_claims_nothing
case_tribunal_without_proposal_asks_plainly
case_tribunal_malformed_proposal_asks_plainly
case_wave_still_denies
case_agent_call_still_denies
case_lookalike_basename_still_denies
case_tribunal_as_directory_still_denies
case_denial_text_is_the_engines
case_no_active_run_allows
case_missing_docket_allows
case_missing_jq_still_guards
case_empty_stdin_still_guards

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
