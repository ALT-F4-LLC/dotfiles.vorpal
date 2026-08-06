#!/bin/bash
# Mechanizes evolve-config's Phase 1 step 3 "Verify the generated output" chain --
# previously three hand-sequenced checks with independent skip-note prose (variance
# by hand-execution, exactly the Content Gate's Executable concern). Sequences all
# three, emitting one PASS/FAIL/SKIPPED line per step plus a single exit code:
#   1. cargo check              -- catches a call to a non-existent setter or a
#                                  type error the serde-attribute read (step 2's
#                                  fallback) cannot, since that fallback assumes
#                                  the code already compiles.
#   2. config_render_diff.sh    -- confirms the changed setter actually produces
#                                  the intended settings.json field (Content Gate
#                                  check 2, Behavioral). Runs against the live
#                                  render target (DKT-94):
#                                    cargo test --lib user::tests::prints_rendered_claude_code_config -- --nocapture
#   3. bash -n <script>...      -- confirms every edited shell script still parses.
#
# If cargo is unavailable, steps 1-2 report SKIPPED (not FAIL) and the caller
# falls back to re-reading claude_code.rs's #[serde(...)] attribute for
# rename/skip semantics (a skip_serializing_if field set to its default produces
# NO output diff and fails the Content Gate Behavioral check) -- this script does
# not attempt that fallback itself, it only reports the gap so the caller knows
# to do it by hand.
#
# Exit code: 0 only if every step that RAN passed (SKIPPED steps do not block).
# Non-zero if any step that ran reported FAIL.
set -uo pipefail

usage() {
    echo "Usage: config_verify.sh [<edited-script>...]" >&2
    echo "  Run from the repo root (or anywhere inside the repo)." >&2
    echo "  <edited-script>... -- zero or more shell scripts to bash -n check." >&2
    exit 1
}

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "config_verify.sh: not inside a git repository" >&2
    exit 1
}
cd "$REPO_ROOT"

FAIL=0

echo "=== Step 1: cargo check ==="
if command -v cargo >/dev/null 2>&1; then
    if cargo check --quiet 2>&1; then
        echo "PASS: cargo check"
    else
        echo "FAIL: cargo check"
        FAIL=1
    fi
else
    echo "SKIPPED: cargo not on PATH -- re-read claude_code.rs's #[serde(...)] attributes by hand for rename/skip semantics"
fi

echo "=== Step 2: config_render_diff.sh (Content Gate Behavioral check) ==="
if command -v cargo >/dev/null 2>&1; then
    SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
    if "$SCRIPT_DIR/config_render_diff.sh" 'cargo test --lib user::tests::prints_rendered_claude_code_config -- --nocapture'; then
        echo "PASS: config_render_diff.sh (output DIFFERS from HEAD -- the change is behavioral)"
    else
        STATUS=$?
        if [ "$STATUS" -eq 1 ]; then
            echo "FAIL: config_render_diff.sh reports output is IDENTICAL to HEAD -- no-op with_* call, fails the Content Gate Behavioral check"
        else
            echo "FAIL: config_render_diff.sh exited ${STATUS} (unexpected -- see its own output above)"
        fi
        FAIL=1
    fi
else
    echo "SKIPPED: cargo not on PATH -- cannot render either git state for diffing"
fi

echo "=== Step 3: bash -n (edited scripts) ==="
if [ "$#" -eq 0 ]; then
    echo "SKIPPED: no scripts passed to check"
else
    for script in "$@"; do
        if [ ! -f "$script" ]; then
            echo "FAIL: ${script} does not exist"
            FAIL=1
            continue
        fi
        if bash -n "$script"; then
            echo "PASS: bash -n ${script}"
        else
            echo "FAIL: bash -n ${script}"
            FAIL=1
        fi
    done
fi

echo "=== config_verify.sh: $([ "$FAIL" -eq 0 ] && echo 'ALL PASS/SKIPPED' || echo 'AT LEAST ONE FAIL') ==="
exit "$FAIL"
