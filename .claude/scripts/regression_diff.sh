#!/bin/bash
# Captures and diffs before/after failing-test-set snapshots, replacing the
# manual jq pipelines @sdet previously hand-built per invocation.
#
# This repo has no single JSON-emitting test runner, so capture runs the
# three real test surfaces directly and normalizes each to a failing-unit
# id, at the finest granularity each surface's own output actually supports:
#   cargo:<target>:<test>       from `cargo test` (per-test; not fail-fast)
#   bash:<script>:<assertion>   from tests/*.test.sh (PASS:/FAIL: lines; not fail-fast)
#   python:<script>             from .claude/scripts/test/test_*.py (file-level:
#                                these harnesses fail-fast on the first assertion,
#                                so which later tests would have failed is unknowable)
set -euo pipefail

usage() {
    echo "Usage: regression_diff.sh capture <key>" >&2
    echo "       regression_diff.sh compare <before_key> <after_key>" >&2
    echo "" >&2
    echo "  capture   runs cargo test, tests/*.test.sh, and" >&2
    echo "            .claude/scripts/test/test_*.py, then snapshots the" >&2
    echo "            failing-test set to \$REGRESSION_DIFF_DIR/<key>.json" >&2
    echo "            (default \$REGRESSION_DIFF_DIR: \${TMPDIR:-/tmp}/regression_diff)." >&2
    echo "  compare   diffs two snapshots and reports newly-failing," >&2
    echo "            newly-passing, and unchanged (still-failing) sets." >&2
    echo "            Exits 1 if newly-failing is non-empty." >&2
    exit 1
}

[ "$#" -ge 1 ] || usage

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "regression_diff.sh: not inside a git repository" >&2
    exit 1
}
cd "$REPO_ROOT"

SNAPSHOT_DIR="${REGRESSION_DIFF_DIR:-${TMPDIR:-/tmp}/regression_diff}"
mkdir -p "$SNAPSHOT_DIR"

FAILING=()

capture_cargo() {
    command -v cargo >/dev/null 2>&1 || return 0
    [ -f "Cargo.toml" ] || return 0

    local target="" line name status
    while IFS= read -r line; do
        if [[ "$line" == *"Running "* ]]; then
            target=$(printf '%s' "$line" \
                | sed -E 's/^ *Running (unittests )?//; s/ \(target.*$//' \
                | xargs -I{} basename {} \
                | sed -E 's/\.rs$//')
        elif [[ "$line" =~ ^test\ (.+)\ \.\.\.\ (ok|FAILED)$ ]]; then
            name="${BASH_REMATCH[1]}"
            status="${BASH_REMATCH[2]}"
            if [ "$status" = "FAILED" ]; then
                FAILING+=("cargo:${target:-unknown}:${name}")
            fi
        fi
    done < <(cargo test --no-fail-fast 2>&1 || true)
}

capture_bash() {
    local dir="tests" f base line
    [ -d "$dir" ] || return 0
    for f in "$dir"/*.test.sh; do
        [ -f "$f" ] || continue
        base=$(basename "$f")
        while IFS= read -r line; do
            if [[ "$line" == FAIL:\ * ]]; then
                FAILING+=("bash:${base}:${line#FAIL: }")
            fi
        done < <(bash "$f" 2>&1 || true)
    done
}

capture_python() {
    local dir=".claude/scripts/test" f base
    [ -d "$dir" ] || return 0
    for f in "$dir"/test_*.py; do
        [ -f "$f" ] || continue
        base=$(basename "$f")
        if ! python3 "$f" >/dev/null 2>&1; then
            FAILING+=("python:${base}")
        fi
    done
}

cmd_capture() {
    local key="$1"
    capture_cargo
    capture_bash
    capture_python

    local failing_json
    failing_json=$(printf '%s\n' "${FAILING[@]+"${FAILING[@]}"}" \
        | jq -R -s -c 'split("\n") | map(select(length > 0)) | unique | sort')

    jq -n \
        --arg key "$key" \
        --arg capturedAt "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --argjson failing "$failing_json" \
        '{key: $key, captured_at: $capturedAt, failing: $failing}' \
        > "${SNAPSHOT_DIR}/${key}.json"

    echo "Captured '${key}': $(printf '%s' "$failing_json" | jq 'length') failing test(s) -> ${SNAPSHOT_DIR}/${key}.json" >&2
}

cmd_compare() {
    local before_key="$1" after_key="$2"
    local before_file="${SNAPSHOT_DIR}/${before_key}.json"
    local after_file="${SNAPSHOT_DIR}/${after_key}.json"

    [ -f "$before_file" ] || {
        echo "regression_diff.sh: no snapshot for '${before_key}' (expected ${before_file}; run 'capture ${before_key}' first)" >&2
        exit 2
    }
    [ -f "$after_file" ] || {
        echo "regression_diff.sh: no snapshot for '${after_key}' (expected ${after_file}; run 'capture ${after_key}' first)" >&2
        exit 2
    }

    local report
    report=$(jq -n --slurpfile before "$before_file" --slurpfile after "$after_file" '
        ($before[0].failing) as $b
        | ($after[0].failing) as $a
        | {
            before_key: $before[0].key,
            after_key: $after[0].key,
            newly_failing: ($a - $b | sort),
            newly_passing: ($b - $a | sort),
            unchanged: ($a - ($a - $b) | sort)
          }
    ')

    printf '%s\n' "$report" | jq .

    local nf_count
    nf_count=$(printf '%s' "$report" | jq '.newly_failing | length')
    if [ "$nf_count" -gt 0 ]; then
        echo "regression_diff.sh: ${nf_count} newly-failing test(s) — regression detected" >&2
        exit 1
    fi
}

MODE="$1"
shift

case "$MODE" in
    capture)
        [ "$#" -eq 1 ] || usage
        cmd_capture "$1"
        ;;
    compare)
        [ "$#" -eq 2 ] || usage
        cmd_compare "$1" "$2"
        ;;
    *)
        usage
        ;;
esac
