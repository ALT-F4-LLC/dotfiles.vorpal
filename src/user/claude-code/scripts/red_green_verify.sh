#!/bin/bash
# Proves a new test can fail (red) against a pre-implementation baseline and
# pass (green) against the working tree, for @sdet's red-green test
# discipline. Reuses regression_diff.sh's worktree-baseline mechanics
# (git worktree add --detach <ref>, trap-guarded removal) to materialize the
# baseline without disturbing the shared working tree.
set -euo pipefail

usage() {
    echo "Usage: red_green_verify.sh <test-selector> [--baseline-ref <ref>]" >&2
    echo "" >&2
    echo "  test-selector   one of:" >&2
    echo "                    cargo:<test-filter>                    cargo test filter string" >&2
    echo "                    bash:<tests/foo.test.sh>[:<assertion>]  PASS:/FAIL: line match;" >&2
    echo "                                                            omit assertion for whole-script" >&2
    echo "                    python:<path/to/test_foo.py>           file-level, by exit code" >&2
    echo "                  bare paths ending in .test.sh or test_*.py are auto-detected as" >&2
    echo "                  bash:/python: respectively; anything else is treated as a cargo:" >&2
    echo "                  test filter." >&2
    echo "  --baseline-ref  git ref to materialize as the pre-implementation baseline" >&2
    echo "                  (default: HEAD)" >&2
    echo "" >&2
    echo "Runs the selected test against --baseline-ref (expecting FAIL) and against the" >&2
    echo "current working tree (expecting PASS), then emits a JSON verdict to stdout:" >&2
    echo '  {selector, baseline_ref, baseline_result, working_tree_result, verdict, reason}' >&2
    echo "verdict is one of PASS / FAIL / ERROR:" >&2
    echo "  PASS  - baseline FAILed and working tree PASSes: a valid red-green proof" >&2
    echo "  FAIL  - baseline did not FAIL (invalid proof - test already passes at the" >&2
    echo "          baseline ref) or working tree did not PASS" >&2
    echo "  ERROR - the selector matched nothing runnable in one of the two trees" >&2
    echo "Exit code 0 iff verdict is PASS." >&2
    exit 1
}

[ "$#" -ge 1 ] || usage

SELECTOR=""
BASELINE_REF="HEAD"

while [ "$#" -gt 0 ]; do
    case "$1" in
        --baseline-ref)
            [ "$#" -ge 2 ] || usage
            BASELINE_REF="$2"
            shift 2
            ;;
        --baseline-ref=*)
            BASELINE_REF="${1#--baseline-ref=}"
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            [ -z "$SELECTOR" ] || usage
            SELECTOR="$1"
            shift
            ;;
    esac
done

[ -n "$SELECTOR" ] || usage

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "red_green_verify.sh: not inside a git repository" >&2
    exit 1
}
cd "$REPO_ROOT"

git rev-parse --verify --quiet "${BASELINE_REF}^{commit}" >/dev/null 2>&1 || {
    echo "red_green_verify.sh: '${BASELINE_REF}' is not a valid git ref" >&2
    exit 2
}

SCRATCH_DIR="${REGRESSION_DIFF_DIR:-${TMPDIR:-/tmp}/regression_diff}"
mkdir -p "$SCRATCH_DIR"

# --- selector dispatch ------------------------------------------------------
KIND=""
SPEC=""
case "$SELECTOR" in
    cargo:*)  KIND="cargo";  SPEC="${SELECTOR#cargo:}" ;;
    bash:*)   KIND="bash";   SPEC="${SELECTOR#bash:}" ;;
    python:*) KIND="python"; SPEC="${SELECTOR#python:}" ;;
    *.test.sh) KIND="bash";   SPEC="$SELECTOR" ;;
    */test_*.py|test_*.py) KIND="python"; SPEC="$SELECTOR" ;;
    *)        KIND="cargo";  SPEC="$SELECTOR" ;;
esac

# run_selected fills RESULT_STATUS (PASS|FAIL|ERROR) and, on ERROR,
# RESULT_DETAIL. Must be invoked with cwd set to the tree under test.
RESULT_STATUS=""
RESULT_DETAIL=""

run_cargo() {
    local filter="$1"
    command -v cargo >/dev/null 2>&1 || { RESULT_STATUS="ERROR"; RESULT_DETAIL="cargo not found on PATH"; return; }
    [ -f "Cargo.toml" ] || { RESULT_STATUS="ERROR"; RESULT_DETAIL="no Cargo.toml at $(pwd)"; return; }

    local out ran=0 failed=0
    out=$(cargo test "$filter" --no-fail-fast 2>&1) || true
    while IFS= read -r line; do
        if [[ "$line" =~ ^test\ (.+)\ \.\.\.\ (ok|FAILED)$ ]]; then
            ran=1
            [ "${BASH_REMATCH[2]}" = "FAILED" ] && failed=1
        fi
    done <<< "$out"

    if [ "$ran" -eq 0 ]; then
        RESULT_STATUS="ERROR"
        RESULT_DETAIL="cargo test filter '${filter}' matched no tests"
        return
    fi
    RESULT_STATUS=$([ "$failed" -eq 1 ] && echo FAIL || echo PASS)
}

run_bash() {
    local spec="$1"
    local script="$spec"
    local assertion=""
    if [[ "$spec" == *:* ]]; then
        script="${spec%%:*}"
        assertion="${spec#*:}"
    fi
    [ -f "$script" ] || { RESULT_STATUS="ERROR"; RESULT_DETAIL="bash test script not found: ${script}"; return; }

    local out
    out=$(bash "$script" 2>&1) || true

    if [ -n "$assertion" ]; then
        if printf '%s\n' "$out" | grep -qF "FAIL: ${assertion}"; then
            RESULT_STATUS="FAIL"
        elif printf '%s\n' "$out" | grep -qF "PASS: ${assertion}"; then
            RESULT_STATUS="PASS"
        else
            RESULT_STATUS="ERROR"
            RESULT_DETAIL="assertion '${assertion}' not found in ${script} output"
        fi
    else
        if printf '%s\n' "$out" | grep -q '^FAIL: '; then
            RESULT_STATUS="FAIL"
        else
            RESULT_STATUS="PASS"
        fi
    fi
}

run_python() {
    local script="$1"
    [ -f "$script" ] || { RESULT_STATUS="ERROR"; RESULT_DETAIL="python test script not found: ${script}"; return; }
    if python3 "$script" >/dev/null 2>&1; then
        RESULT_STATUS="PASS"
    else
        RESULT_STATUS="FAIL"
    fi
}

run_selected() {
    case "$KIND" in
        cargo)  run_cargo "$SPEC" ;;
        bash)   run_bash "$SPEC" ;;
        python) run_python "$SPEC" ;;
    esac
}

# --- baseline run: mirrors regression_diff.sh's cmd_baseline/cleanup_worktree
WORKTREE_DIR=""
cleanup_worktree() {
    [ -n "$WORKTREE_DIR" ] || return 0
    cd "$REPO_ROOT" 2>/dev/null || true
    git worktree remove --force "$WORKTREE_DIR" >/dev/null 2>&1 || true
    WORKTREE_DIR=""
}

WORKTREE_DIR="${SCRATCH_DIR}/red_green_worktree.$$"
rm -rf "$WORKTREE_DIR"
trap cleanup_worktree EXIT INT TERM

if ! git worktree add --detach "$WORKTREE_DIR" "$BASELINE_REF" >&2; then
    echo "red_green_verify.sh: 'git worktree add' failed for ref '${BASELINE_REF}'" >&2
    exit 1
fi

cd "$WORKTREE_DIR"
run_selected
BASELINE_RESULT="$RESULT_STATUS"
BASELINE_DETAIL="$RESULT_DETAIL"
cd "$REPO_ROOT"
cleanup_worktree
trap - EXIT INT TERM

# --- working tree run --------------------------------------------------------
cd "$REPO_ROOT"
run_selected
WORKING_RESULT="$RESULT_STATUS"
WORKING_DETAIL="$RESULT_DETAIL"

# --- verdict ------------------------------------------------------------------
if [ "$BASELINE_RESULT" = "ERROR" ] || [ "$WORKING_RESULT" = "ERROR" ]; then
    VERDICT="ERROR"
    REASON="baseline: ${BASELINE_DETAIL:-ok}; working tree: ${WORKING_DETAIL:-ok}"
elif [ "$BASELINE_RESULT" != "FAIL" ]; then
    VERDICT="FAIL"
    REASON="baseline did not fail (result: ${BASELINE_RESULT}) -- not a valid red-green proof; the test already passes at '${BASELINE_REF}'"
elif [ "$WORKING_RESULT" != "PASS" ]; then
    VERDICT="FAIL"
    REASON="working tree did not pass (result: ${WORKING_RESULT})"
else
    VERDICT="PASS"
    REASON="baseline FAILed at '${BASELINE_REF}' and working tree PASSes -- valid red-green proof"
fi

jq -n \
    --arg selector "$SELECTOR" \
    --arg baseline_ref "$BASELINE_REF" \
    --arg baseline_result "$BASELINE_RESULT" \
    --arg working_tree_result "$WORKING_RESULT" \
    --arg verdict "$VERDICT" \
    --arg reason "$REASON" \
    '{selector: $selector, baseline_ref: $baseline_ref, baseline_result: $baseline_result, working_tree_result: $working_tree_result, verdict: $verdict, reason: $reason}'

[ "$VERDICT" = "PASS" ]
