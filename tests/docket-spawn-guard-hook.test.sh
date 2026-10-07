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
# itself. An earlier version asked about `runs[0]` of `run status`,
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
# Third, the usage join. wave-usage.js claims no step, so a launch of the
# INSTALLED copy asks `guard spawn --active --usage-join` and the engine
# admits it past a reap hold. The match is on the resolved path, never the
# basename: a same-named copy elsewhere, or wave.js, asks the plain question.
# Production ~/.claude/workflows is a symlink into the vorpal store, so the
# rows use fixture HOMEs, one real directory and one symlinked, and both the
# symlinked and the resolved scriptPath must match.
#
# ALSO PINNED: the fail-OPEN path (no `docket`), the engine's own allow over
# no active run, and the ordinary path (a launch that is neither tribunal.js
# nor the installed wave-usage.js reaches the engine with no extra flags, and its denial text is the engine's).
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

# shellcheck source=tests/lib/hook-probe.sh
. "${SCRIPT_DIR}/lib/hook-probe.sh"

SANDBOX=$(mktemp -d "${TMPDIR:-/tmp}/docket-spawn-guard-test.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$SANDBOX"' EXIT
STDERR_FILE="${SANDBOX}/hook.stderr"
MARKER="${SANDBOX}/engine-consulted"

TOOLS_DIR="${SANDBOX}/tools"
TOOLS_DIR_NO_JQ="${SANDBOX}/tools-no-jq"
STUB_DIR="${SANDBOX}/stub"
mkdir -p "$STUB_DIR"
hook_probe_link_shims "$TOOLS_DIR" bash cat jq || fatal "cannot build hook probe shims"
hook_probe_link_shims "$TOOLS_DIR_NO_JQ" bash cat || fatal "cannot build hook probe shims"

# Fake engine. ACTIVE_RUNS lists the project's active runs OLDEST FIRST (empty
# = no active run). HELD_RUNS names those holding an unacknowledged write-class
# reap. `guard spawn --active` walks ACTIVE_RUNS and denies on the first held
# one, naming it, the way the engine documents; `guard spawn --run R` asks
# about R alone. ADMIT_VOTE is the one proposal id whose --deciding-vote the
# stub honors, standing in for "exists and is open". --usage-join relaxes the
# reap half, so a held run admits only a launch that carries it; the stub
# refuses it beside --deciding-vote, as the engine does. SPAWN_MARKER records
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
MODE="" RUN="" VOTE="" USAGE="" JSON=no
while [ $# -gt 0 ]; do
    case "$1" in
        --active) MODE=active ;;
        --run) RUN="$2"; shift ;;
        --deciding-vote) VOTE="$2"; shift ;;
        --usage-join) USAGE=yes ;;
        --json) JSON=yes ;;
        *) printf 'fake docket: unexpected flag: %s\n' "$1" >&2; exit 64 ;;
    esac
    shift
done
if [ -n "$USAGE" ] && [ -n "$VOTE" ]; then
    printf '✘ Error: --usage-join and --deciding-vote are mutually exclusive\n' >&2
    exit 3
fi
if [ "$MODE" = active ]; then
    [ -z "$VOTE" ] || { printf '✘ Error: --active does not take --deciding-vote\n' >&2; exit 3; }
    [ -n "$USAGE" ] && allow
    for r in ${ACTIVE_RUNS:-}; do
        held "$r" && deny "$r"
    done
    allow
fi
[ -n "$RUN" ] || { printf '✘ Error: --run is required\n' >&2; exit 3; }
if held "$RUN"; then
    [ -n "$USAGE" ] && allow
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
        | PATH="$path_value" HOME="${HOOK_HOME:-$HOME}" SPAWN_MARKER="$MARKER" "$BASH_BIN" "$HOOK" \
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
    unset ACTIVE_RUNS HELD_RUNS ADMIT_VOTE HOOK_HOME
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

# A launch carrying args.cwd, from a session whose working directory (the
# payload's top-level `cwd`, which the harness sends with every hook input) is
# the repo root. $3 = "string" emits args as a JSON string, the shape the
# harness actually sends.
workflow_payload_cwd() {
    jq -nc --arg p "$1" --arg c "$2" --arg shape "${3:-object}" --arg s "$REPO_ROOT" \
        '{tool_name:"Workflow", cwd:$s, tool_input:{scriptPath:$p,
          args:({cwd:$c} | if $shape == "string" then tojson else . end)}}'
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
    # grep the file directly: under pipefail, `asked_all | grep -q` reads as
    # no match when grep exits early and SIGPIPEs cat.
    if [ -f "$MARKER" ] && grep -q -- "$pattern" "$MARKER"; then
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

# ---- A launch cwd that is not the checkout's root is refused before spawn ----
# A hand-typed cwd that misses the checkout died late, at wave.js's first claim
# agent, leaving an open dispatch behind. The hook refuses it first: no engine
# call, exit 2, the bad path verbatim on stderr.
# The reason is asserted too: a nonexistent path can never equal the toplevel,
# so without it the existence check would be invisible to every row.
expect_cwd_refused() {
    local label="$1" bad="$2" reason="$3" payload="$4"
    one_held_run
    run_case "$label" DENY "$payload"
    if grep -qF -- "$bad" "$STDERR_FILE"; then
        pass "  ...naming the path verbatim"
    else
        fail "  ...stderr did not name ${bad} (stderr: $(tr '\n' ' ' <"$STDERR_FILE"))"
    fi
    if grep -qF -- "$reason" "$STDERR_FILE"; then
        pass "  ...because it is ${reason}"
    else
        fail "  ...stderr did not say '${reason}' (stderr: $(tr '\n' ' ' <"$STDERR_FILE"))"
    fi
    if [ -f "$MARKER" ]; then
        fail "  ...but the engine was consulted (asked: $(asked_all | tr '\n' ';'))"
    else
        pass "  ...before the engine was consulted"
    fi
}

# Under the held run the existing verdict is the engine's DENY, so the row can
# only pass if the hook let the launch through to the engine.
expect_cwd_passes_through() {
    local label="$1" payload="$2"
    one_held_run
    run_case "$label" DENY "$payload"
    expect_argv "  ...the engine's verdict, asked the ordinary way" "guard spawn --active"
}

case_wave_cwd_missing_refused() {
    local bad="${REPO_ROOT}-no-such-checkout"
    expect_cwd_refused "wave.js with a nonexistent cwd (a sibling of the repo root)" "$bad" \
        "not an existing directory" \
        "$(workflow_payload_cwd "$HOME/.claude/workflows/wave.js" "$bad")"
}

case_wave_cwd_subdirectory_refused() {
    local bad="${REPO_ROOT}/tests"
    expect_cwd_refused "wave.js with a cwd that is a subdirectory of the repo" "$bad" \
        "not the git toplevel" \
        "$(workflow_payload_cwd "$HOME/.claude/workflows/wave.js" "$bad")"
}

case_wave_cwd_toplevel_passes() {
    expect_cwd_passes_through "wave.js with cwd equal to the repo root" \
        "$(workflow_payload_cwd "$HOME/.claude/workflows/wave.js" "$REPO_ROOT")"
}

case_wave_cwd_toplevel_trailing_slash_passes() {
    expect_cwd_passes_through "wave.js with cwd equal to the repo root plus a trailing slash" \
        "$(workflow_payload_cwd "$HOME/.claude/workflows/wave.js" "${REPO_ROOT}/")"
}

# tribunal.js carries the same hand-typed cwd. A launch with no args.cwd keeps
# the existing verdict; the voteId forwarding rows above pin that.
case_tribunal_cwd_missing_refused() {
    local bad="${REPO_ROOT}-no-such-checkout"
    expect_cwd_refused "tribunal.js with a nonexistent cwd, object args" "$bad" \
        "not an existing directory" \
        "$(workflow_payload_cwd "$HOME/.claude/workflows/tribunal.js" "$bad")"
}

case_tribunal_cwd_missing_stringified_refused() {
    local bad="${REPO_ROOT}-no-such-checkout"
    expect_cwd_refused "tribunal.js with a nonexistent cwd, args as a JSON string" "$bad" \
        "not an existing directory" \
        "$(workflow_payload_cwd "$HOME/.claude/workflows/tribunal.js" "$bad" string)"
}

case_tribunal_cwd_subdirectory_refused() {
    local bad="${REPO_ROOT}/tests"
    expect_cwd_refused "tribunal.js with a cwd that is a subdirectory of the repo" "$bad" \
        "not the git toplevel" \
        "$(workflow_payload_cwd "$HOME/.claude/workflows/tribunal.js" "$bad")"
}

case_tribunal_cwd_toplevel_passes() {
    expect_cwd_passes_through "tribunal.js with cwd equal to the repo root" \
        "$(workflow_payload_cwd "$HOME/.claude/workflows/tribunal.js" "$REPO_ROOT")"
}

case_tribunal_cwd_toplevel_trailing_slash_passes() {
    expect_cwd_passes_through "tribunal.js with cwd equal to the repo root plus a trailing slash" \
        "$(workflow_payload_cwd "$HOME/.claude/workflows/tribunal.js" "${REPO_ROOT}/")"
}

# ---- USAGE JOIN: the installed wave-usage.js declares itself to the engine ----
# Fixture HOMEs, so the rows hold on a runner with no ~/.claude/workflows.
# USAGE_HOME has a real workflows directory. LINK_HOME's workflows is a
# symlink to STORE_DIR, as production's points into the vorpal store; the
# target is resolved with `cd -P` because $TMPDIR itself may sit behind a
# symlink (/var -> /private/var on macOS), and the resolved form is what a
# caller holding the store path would pass.
USAGE_HOME="${SANDBOX}/home-real"
LINK_HOME="${SANDBOX}/home-link"
STORE_DIR="${SANDBOX}/store/workflows"
ELSEWHERE_DIR="${SANDBOX}/elsewhere"
mkdir -p "${USAGE_HOME}/.claude/workflows" "${LINK_HOME}/.claude" "$STORE_DIR" "$ELSEWHERE_DIR" \
    || fatal "cannot build usage-join fixtures"
: >"${USAGE_HOME}/.claude/workflows/wave-usage.js"
: >"${USAGE_HOME}/.claude/workflows/wave.js"
: >"${STORE_DIR}/wave-usage.js"
: >"${ELSEWHERE_DIR}/wave-usage.js"
ln -s "$STORE_DIR" "${LINK_HOME}/.claude/workflows" || fatal "cannot link the fixture workflows"
STORE_DIR_REAL=$(cd -P "$STORE_DIR" && pwd -P) || fatal "cannot resolve the fixture store"

# Under one held run, so an ALLOW can only come from the engine admitting
# the flag; the plain question is denied.
expect_usage_join_admitted() {
    local label="$1" home="$2" script="$3"
    one_held_run
    HOOK_HOME="$home"
    run_case "$label" ALLOW "$(workflow_payload "$script")"
    expect_argv "  ...by declaring the usage join alongside --active" \
        "guard spawn --active --usage-join"
}

expect_usage_join_not_claimed() {
    local label="$1" home="$2" script="$3"
    one_held_run
    HOOK_HOME="$home"
    run_case "$label" DENY "$(workflow_payload "$script")"
    expect_never_asked "  ...and declares no usage join" "--usage-join"
    expect_argv "  ...asking the plain question" "guard spawn --active"
}

case_usage_join_installed_path() {
    expect_usage_join_admitted "wave-usage.js at the installed path under a hold" \
        "$USAGE_HOME" "${USAGE_HOME}/.claude/workflows/wave-usage.js"
}

case_usage_join_not_for_wave() {
    expect_usage_join_not_claimed "wave.js at the installed path under a hold" \
        "$USAGE_HOME" "${USAGE_HOME}/.claude/workflows/wave.js"
}

case_usage_join_not_for_foreign_path() {
    expect_usage_join_not_claimed "wave-usage.js at /tmp/x, outside the install" \
        "$USAGE_HOME" "/tmp/x/wave-usage.js"
}

case_usage_join_not_for_same_named_copy() {
    expect_usage_join_not_claimed "an existing same-named copy outside the install" \
        "$USAGE_HOME" "${ELSEWHERE_DIR}/wave-usage.js"
}

case_usage_join_symlinked_install() {
    expect_usage_join_admitted "wave-usage.js through a symlinked workflows directory" \
        "$LINK_HOME" "${LINK_HOME}/.claude/workflows/wave-usage.js"
}

case_usage_join_resolved_target() {
    expect_usage_join_admitted "wave-usage.js at the symlink's resolved target" \
        "$LINK_HOME" "${STORE_DIR_REAL}/wave-usage.js"
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
case_wave_cwd_missing_refused
case_wave_cwd_subdirectory_refused
case_wave_cwd_toplevel_passes
case_wave_cwd_toplevel_trailing_slash_passes
case_tribunal_cwd_missing_refused
case_tribunal_cwd_missing_stringified_refused
case_tribunal_cwd_subdirectory_refused
case_tribunal_cwd_toplevel_passes
case_tribunal_cwd_toplevel_trailing_slash_passes
case_usage_join_installed_path
case_usage_join_not_for_wave
case_usage_join_not_for_foreign_path
case_usage_join_not_for_same_named_copy
case_usage_join_symlinked_install
case_usage_join_resolved_target

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
