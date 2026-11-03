#!/bin/bash

# Behavior suite for src/user/claude_code/hooks/direnv-env-hook.sh.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name.
#
# THE PROPERTY UNDER TEST: the hook keeps exactly one block of direnv exports
# in CLAUDE_ENV_FILE, for the directory the event names, and leaves every
# other line of that file alone. A load replaces the block, an empty diff
# removes it, and a refusal or failure leaves the file as it was.
#
# DEFECT CLASS. Two failure directions, both silent in production:
#   STALE ENV  - a previous directory's PATH survives a move (the block is
#     appended instead of replaced, or never cleared), so `go` resolves to the
#     wrong dev shell or to one the directory does not have.
#   LOST ENV   - another hook's exports are dropped, or a failed export wipes
#     a working block, or a move into a directory without a `.envrc` unloads
#     the dev shell the launch environment already holds (`direnv exec .
#     claude`), so later Bash commands lose `go` and `cargo`.
#
# SEAM. A fake `direnv` on PATH, steered by FAKE_DIRENV_MODE, records the
# directory each `export` ran in; `status --json` reports the directory's
# `.envrc` as foundRC, as real direnv does, unless FAKE_DIRENV_STATUS=fail.
# The hook's stdout and the env file are the verdict.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
HOOK="${DIRENV_ENV_HOOK:-${REPO_ROOT}/src/user/claude_code/hooks/direnv-env-hook.sh}"

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

WORK=$(mktemp -d "${TMPDIR:-/tmp}/direnv-env-hook-test.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT

BEGIN_MARK='# >>> direnv-env-hook >>>'

# Tools the hook needs, without any real direnv: jq plus the base system.
TOOLS="$WORK/tools"
mkdir -p "$TOOLS"
ln -s "$(command -v jq)" "$TOOLS/jq"
BASE_PATH="$TOOLS:/usr/bin:/bin"

FAKE="$WORK/fake"
mkdir -p "$FAKE"
cat >"$FAKE/direnv" <<'EOF'
#!/bin/bash
if [ "${1:-}" = status ]; then
    [ "${FAKE_DIRENV_STATUS:-ok}" = fail ] && exit 1
    d=$PWD
    while [ -n "$d" ] && [ ! -f "$d/.envrc" ]; do d=${d%/*}; done
    if [ -n "$d" ]; then
        printf '{"state":{"foundRC":{"path":"%s/.envrc","allowed":0},"loadedRC":null}}\n' "$d"
    else
        printf '{"state":{"foundRC":null,"loadedRC":null}}\n'
    fi
    exit 0
fi
pwd >>"$FAKE_DIRENV_LOG"
case "${FAKE_DIRENV_MODE:-load}" in
    load) printf 'export PATH=%s;\n' "'/dev-shell/${FAKE_DIRENV_TAG:-a}/bin:/usr/bin'" ;;
    # What real direnv prints outside any .envrc when the harness env carries
    # DIRENV_DIFF from the launch: the launch dev shell, reverted.
    unload) printf 'unset DIRENV_DIFF;export PATH=%s;\n' "'/usr/bin:/bin'" ;;
    empty) ;;
    blocked)
        echo 'direnv: error /x/.envrc is blocked. Run `direnv allow` to approve its content' >&2
        exit 1
        ;;
    fail)
        echo 'direnv: error loading .envrc: exit status 1' >&2
        exit 1
        ;;
esac
EOF
chmod +x "$FAKE/direnv"

DIR_A="$WORK/repo-a"
DIR_B="$WORK/repo-b"
DIR_PLAIN="$WORK/scratch"
mkdir -p "$DIR_A" "$DIR_B" "$DIR_PLAIN"
printf 'use vorpal\n' >"$DIR_A/.envrc"
printf 'use vorpal\n' >"$DIR_B/.envrc"

# The launch environment of `direnv exec <DIR_A> claude`: the dev shell is on
# PATH and direnv's state variables name it.
LAUNCH_ENV=(
    "DIRENV_DIR=-$DIR_A"
    "DIRENV_FILE=$DIR_A/.envrc"
    "DIRENV_DIFF=launch-diff"
    "DIRENV_WATCHES=launch-watches"
)

ENV_FILE="$WORK/env"
LOG="$WORK/direnv.log"
OUT="$WORK/out"

# run_hook <mode> <json> [tag] — runs the hook with the fake direnv on PATH;
# leaves stdout in $OUT and returns the hook's exit code.
run_hook() {
    local mode="$1" json="$2" tag="${3:-a}"
    : >"$LOG"
    PATH="$FAKE:$BASE_PATH" CLAUDE_ENV_FILE="$ENV_FILE" FAKE_DIRENV_MODE="$mode" \
        FAKE_DIRENV_TAG="$tag" FAKE_DIRENV_LOG="$LOG" \
        "$BASH_BIN" "$HOOK" <<<"$json" >"$OUT" 2>/dev/null
}

# run_hook_launched <mode> <json> [status] — run_hook under LAUNCH_ENV, with
# the dev shell already on PATH; status=fail makes `direnv status` fail.
run_hook_launched() {
    local mode="$1" json="$2" status="${3:-ok}"
    : >"$LOG"
    env "${LAUNCH_ENV[@]}" PATH="/dev-shell/a/bin:$FAKE:$BASE_PATH" \
        CLAUDE_ENV_FILE="$ENV_FILE" FAKE_DIRENV_MODE="$mode" \
        FAKE_DIRENV_STATUS="$status" FAKE_DIRENV_LOG="$LOG" \
        "$BASH_BIN" "$HOOK" <<<"$json" >"$OUT" 2>/dev/null
}

session_start() { printf '{"hook_event_name":"SessionStart","cwd":"%s"}' "$1"; }
cwd_changed() { printf '{"hook_event_name":"CwdChanged","cwd":"%s","old_cwd":"%s","new_cwd":"%s"}' "$1" "$1" "$2"; }

block_count() { grep -cxF "$BEGIN_MARK" "$ENV_FILE" 2>/dev/null || true; }

case_no_env_file_is_a_noop() {
    rm -f "$ENV_FILE"
    : >"$LOG"
    PATH="$FAKE:$BASE_PATH" FAKE_DIRENV_LOG="$LOG" "$BASH_BIN" "$HOOK" \
        <<<"$(session_start "$DIR_A")" >"$OUT" 2>/dev/null
    local rc=$?
    if [ "$rc" -eq 0 ] && [ ! -e "$ENV_FILE" ] && [ ! -s "$LOG" ] && [ ! -s "$OUT" ]; then
        pass "no CLAUDE_ENV_FILE: exit 0, direnv not run, nothing written"
    else
        fail "no CLAUDE_ENV_FILE: rc=$rc, env file or direnv call or output appeared"
    fi
}

case_no_direnv_is_a_noop() {
    printf 'export KEEP=1\n' >"$ENV_FILE"
    PATH="$BASE_PATH" CLAUDE_ENV_FILE="$ENV_FILE" "$BASH_BIN" "$HOOK" \
        <<<"$(session_start "$DIR_A")" >"$OUT" 2>/dev/null
    local rc=$?
    if [ "$rc" -eq 0 ] && [ "$(cat "$ENV_FILE")" = "export KEEP=1" ] && [ ! -s "$OUT" ]; then
        pass "direnv absent: exit 0, env file untouched"
    else
        fail "direnv absent: rc=$rc or env file changed"
    fi
}

case_session_start_loads_block() {
    rm -f "$ENV_FILE"
    run_hook load "$(session_start "$DIR_A")" a
    local rc=$?
    if [ "$rc" -eq 0 ] && [ "$(block_count)" = "1" ] && grep -q '/dev-shell/a/bin' "$ENV_FILE"; then
        pass "SessionStart: writes one marked block with the exports"
    else
        fail "SessionStart: rc=$rc, blocks=$(block_count)"
    fi
    if grep -q 'loaded the environment for' "$OUT"; then
        pass "SessionStart: reports the load on stdout"
    else
        fail "SessionStart: no load line on stdout"
    fi
    if [ "$(cat "$LOG")" = "$(cd "$DIR_A" && pwd)" ]; then
        pass "SessionStart: direnv runs in the event's cwd"
    else
        fail "SessionStart: direnv ran in '$(cat "$LOG")', not $DIR_A"
    fi
}

case_cwd_changed_uses_new_cwd() {
    rm -f "$ENV_FILE"
    run_hook load "$(cwd_changed "$DIR_A" "$DIR_B")" b
    if [ "$(cat "$LOG")" = "$(cd "$DIR_B" && pwd)" ]; then
        pass "CwdChanged: direnv runs in new_cwd, not cwd"
    else
        fail "CwdChanged: direnv ran in '$(cat "$LOG")', not $DIR_B"
    fi
}

case_reload_replaces_block() {
    rm -f "$ENV_FILE"
    run_hook load "$(session_start "$DIR_A")" a
    run_hook load "$(cwd_changed "$DIR_A" "$DIR_B")" b
    if [ "$(block_count)" = "1" ] && grep -q '/dev-shell/b/bin' "$ENV_FILE" \
        && ! grep -q '/dev-shell/a/bin' "$ENV_FILE"; then
        pass "a second load replaces the block instead of appending"
    else
        fail "a second load left blocks=$(block_count) or kept the old exports"
    fi
}

case_other_lines_preserved() {
    printf 'export OTHER_HOOK=1\n' >"$ENV_FILE"
    run_hook load "$(session_start "$DIR_A")" a
    run_hook load "$(cwd_changed "$DIR_A" "$DIR_B")" b
    if grep -qxF 'export OTHER_HOOK=1' "$ENV_FILE"; then
        pass "another hook's exports survive load and reload"
    else
        fail "another hook's exports were dropped"
    fi
}

case_empty_diff_clears_block() {
    printf 'export OTHER_HOOK=1\n' >"$ENV_FILE"
    run_hook load "$(session_start "$DIR_A")" a
    run_hook empty "$(cwd_changed "$DIR_A" "$DIR_B")"
    local rc=$?
    if [ "$rc" -eq 0 ] && [ "$(block_count)" = "0" ] && ! grep -q '/dev-shell/' "$ENV_FILE" \
        && grep -qxF 'export OTHER_HOOK=1' "$ENV_FILE"; then
        pass "an empty diff removes the block and keeps other lines"
    else
        fail "an empty diff left blocks=$(block_count) or dropped other lines (rc=$rc)"
    fi
    if grep -q 'cleared the loaded environment' "$OUT"; then
        pass "an empty diff after a load reports the clear"
    else
        fail "an empty diff after a load printed no clear line"
    fi
}

case_empty_diff_without_block_is_silent() {
    printf 'export OTHER_HOOK=1\n' >"$ENV_FILE"
    run_hook empty "$(session_start "$DIR_A")"
    if [ ! -s "$OUT" ] && [ "$(cat "$ENV_FILE")" = "export OTHER_HOOK=1" ]; then
        pass "an empty diff with nothing loaded prints nothing and changes nothing"
    else
        fail "an empty diff with nothing loaded printed or changed the file"
    fi
}

case_blocked_envrc_leaves_file() {
    rm -f "$ENV_FILE"
    run_hook load "$(session_start "$DIR_A")" a
    local before
    before=$(cat "$ENV_FILE")
    run_hook blocked "$(cwd_changed "$DIR_A" "$DIR_B")"
    local rc=$?
    if [ "$rc" -eq 0 ] && [ "$(cat "$ENV_FILE")" = "$before" ]; then
        pass "a blocked .envrc leaves the env file as it was"
    else
        fail "a blocked .envrc changed the env file (rc=$rc)"
    fi
    if grep -q 'direnv allow' "$OUT"; then
        pass "a blocked .envrc names \`direnv allow\` on stdout"
    else
        fail "a blocked .envrc printed no allow hint"
    fi
}

case_failed_export_leaves_file() {
    rm -f "$ENV_FILE"
    run_hook load "$(session_start "$DIR_A")" a
    local before
    before=$(cat "$ENV_FILE")
    run_hook fail "$(cwd_changed "$DIR_A" "$DIR_B")"
    local rc=$?
    if [ "$rc" -eq 0 ] && [ "$(cat "$ENV_FILE")" = "$before" ] && grep -q 'export failed' "$OUT"; then
        pass "a failed export keeps the working block and reports the failure"
    else
        fail "a failed export changed the env file or printed nothing (rc=$rc)"
    fi
}

case_missing_directory_is_a_noop() {
    printf 'export KEEP=1\n' >"$ENV_FILE"
    run_hook load "$(session_start "$WORK/does-not-exist")"
    local rc=$?
    if [ "$rc" -eq 0 ] && [ "$(cat "$ENV_FILE")" = "export KEEP=1" ] && [ ! -s "$LOG" ]; then
        pass "a missing directory: exit 0, direnv not run, file untouched"
    else
        fail "a missing directory: rc=$rc or the file changed or direnv ran"
    fi
}

case_malformed_input_falls_back_to_pwd() {
    rm -f "$ENV_FILE"
    : >"$LOG"
    (cd "$DIR_B" && PATH="$FAKE:$BASE_PATH" CLAUDE_ENV_FILE="$ENV_FILE" FAKE_DIRENV_MODE=load \
        FAKE_DIRENV_LOG="$LOG" "$BASH_BIN" "$HOOK" <<<'not json' >"$OUT" 2>/dev/null)
    local rc=$?
    if [ "$rc" -eq 0 ] && [ "$(cat "$LOG")" = "$(cd "$DIR_B" && pwd)" ]; then
        pass "malformed input: exit 0, direnv runs in the hook's own directory"
    else
        fail "malformed input: rc=$rc, direnv ran in '$(cat "$LOG")'"
    fi
}

case_launch_env_same_repo_writes_nothing() {
    printf 'export OTHER_HOOK=1\n' >"$ENV_FILE"
    run_hook_launched empty "$(session_start "$DIR_A")"
    local rc=$?
    if [ "$rc" -eq 0 ] && [ "$(cat "$ENV_FILE")" = "export OTHER_HOOK=1" ] && [ ! -s "$OUT" ]; then
        pass "launch env holds the dev shell: SessionStart in that repo writes no block"
    else
        fail "launch env holds the dev shell: SessionStart in that repo changed the file or printed (rc=$rc)"
    fi
}

case_launch_env_survives_move_out_of_repo() {
    printf 'export OTHER_HOOK=1\n' >"$ENV_FILE"
    run_hook_launched unload "$(cwd_changed "$DIR_A" "$DIR_PLAIN")"
    local rc=$?
    if [ "$rc" -eq 0 ] && [ "$(block_count)" = "0" ] && ! grep -q 'DIRENV_DIFF' "$ENV_FILE" \
        && grep -qxF 'export OTHER_HOOK=1' "$ENV_FILE"; then
        pass "launch env holds the dev shell: a move to a dir without .envrc writes no unload block"
    else
        fail "launch env holds the dev shell: a move to a dir without .envrc unloaded it (rc=$rc, blocks=$(block_count))"
    fi
    if [ ! -s "$LOG" ]; then
        pass "a dir without .envrc: direnv export does not run"
    else
        fail "a dir without .envrc: direnv export ran in '$(cat "$LOG")'"
    fi
}

case_launch_env_move_clears_other_repo_block() {
    rm -f "$ENV_FILE"
    run_hook_launched load "$(cwd_changed "$DIR_A" "$DIR_B")"
    run_hook_launched unload "$(cwd_changed "$DIR_B" "$DIR_PLAIN")"
    if [ "$(block_count)" = "0" ] && ! grep -q '/dev-shell/' "$ENV_FILE" \
        && grep -q 'cleared the loaded environment' "$OUT"; then
        pass "leaving another repo for a dir without .envrc returns to the launch env"
    else
        fail "leaving another repo for a dir without .envrc left blocks=$(block_count)"
    fi
}

case_launch_env_other_repo_still_loads() {
    rm -f "$ENV_FILE"
    run_hook_launched load "$(cwd_changed "$DIR_A" "$DIR_B")"
    if [ "$(block_count)" = "1" ] && [ "$(cat "$LOG")" = "$(cd "$DIR_B" && pwd)" ]; then
        pass "launch env holds the dev shell: a move into another repo still loads its .envrc"
    else
        fail "launch env holds the dev shell: a move into another repo loaded nothing (blocks=$(block_count))"
    fi
}

case_launch_repo_subdir_still_exports() {
    mkdir -p "$DIR_A/sub"
    rm -f "$ENV_FILE"
    run_hook_launched empty "$(cwd_changed "$DIR_A" "$DIR_A/sub")"
    if [ "$(cat "$LOG")" = "$(cd "$DIR_A/sub" && pwd)" ] && [ "$(block_count)" = "0" ]; then
        pass "a subdirectory of the launch repo finds the parent .envrc and runs the export"
    else
        fail "a subdirectory of the launch repo skipped the export (log='$(cat "$LOG")')"
    fi
}

case_status_failure_falls_back_to_export() {
    rm -f "$ENV_FILE"
    run_hook_launched load "$(cwd_changed "$DIR_A" "$DIR_PLAIN")" fail
    if [ "$(cat "$LOG")" = "$(cd "$DIR_PLAIN" && pwd)" ] && [ "$(block_count)" = "1" ]; then
        pass "direnv status unavailable: the hook falls back to direnv export"
    else
        fail "direnv status unavailable: export did not run (log='$(cat "$LOG")')"
    fi
}

case_no_env_file_is_a_noop
case_no_direnv_is_a_noop
case_session_start_loads_block
case_cwd_changed_uses_new_cwd
case_reload_replaces_block
case_other_lines_preserved
case_empty_diff_clears_block
case_empty_diff_without_block_is_silent
case_blocked_envrc_leaves_file
case_failed_export_leaves_file
case_missing_directory_is_a_noop
case_malformed_input_falls_back_to_pwd
case_launch_env_same_repo_writes_nothing
case_launch_env_survives_move_out_of_repo
case_launch_env_move_clears_other_repo_block
case_launch_env_other_repo_still_loads
case_launch_repo_subdir_still_exports
case_status_failure_falls_back_to_export

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
