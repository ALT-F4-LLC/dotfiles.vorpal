#!/bin/bash

# Every suite under tests/ must be invoked by a step the CI workflow actually
# runs, and every such step must name a suite that exists. Two non-hook suites
# once sat unwired and dead because nothing checked. Counting rows against
# files is not enough: a duplicated row plus a dropped one keeps the counts
# equal, so this compares the two SETS of suite names and reports both
# directions.
#
# The row scan reads workflow STRUCTURE, not text: a commented-out row, or a
# row under an `if:`-gated job or step, does not run in CI and so does not
# count as wiring. A gated row is treated as absent whatever its condition
# says — evaluating GitHub expressions here would be a second, worse parser,
# and "the suite runs on every CI run" is the invariant worth holding.
#
# Boundary with `.docket/bin/sdet-abuse`: that gate re-runs the HOOK suites
# behind a minimum-case floor, so it catches a hook suite that has stopped
# asserting anything. This one covers every suite's wiring and says nothing
# about whether an invoked suite can still fail.
#
# TESTS_DIR and WORKFLOW_FILE override the inputs, so a mutation probe can
# point the suite at deliberately-broken COPIES under $TMPDIR without touching
# the checkout.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TESTS="${TESTS_DIR:-${SCRIPT_DIR}}"
WORKFLOW="${WORKFLOW_FILE:-${SCRIPT_DIR}/../.github/workflows/vorpal.yaml}"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/ci-suite-wiring.XXXXXX") || exit 2
trap 'rm -rf "$WORK"' EXIT

# Suite basenames under <dir>, sorted. The glob is used directly: `ls | xargs`
# word-splits any filename containing whitespace.
suite_names() { # <tests-dir>
    local f
    shopt -s nullglob
    for f in "$1"/*.test.sh; do
        basename "$f"
    done | sort
    shopt -u nullglob
}

# Suite basenames invoked by a step that CI will run, sorted and deduplicated.
# The awk pass walks the workflow's indentation so that comments, gated jobs
# and gated steps drop out; only a single-line `run:` on an ungated step in an
# ungated job reaches the grep.
wired_suites() { # <workflow-file>
    awk '
        function flush_step() {
            if (step_run != "" && !job_gated && !step_gated) print step_run
            step_run = ""
            step_gated = 0
        }
        /^[[:space:]]*#/ { next }
        {
            match($0, /^ */)
            ind = RLENGTH
            rest = substr($0, ind + 1)
            if (rest == "") next

            if (ind == 0) { flush_step(); job_gated = 0; in_steps = 0; next }
            if (ind == 2 && rest ~ /^[A-Za-z0-9_.-]+:[[:space:]]*$/) {
                flush_step(); job_gated = 0; in_steps = 0; next
            }
            if (ind == 4) {
                flush_step()
                in_steps = (rest ~ /^steps:/)
                if (rest ~ /^if:/) job_gated = 1
                next
            }
            if (!in_steps) next

            if (ind == 6 && rest ~ /^- /) { flush_step(); key = substr(rest, 3) }
            else if (ind == 8) { key = rest }
            else next

            if (key ~ /^if:/) step_gated = 1
            if (key ~ /^run:/) step_run = substr(key, 5)
        }
        END { flush_step() }
    ' "$1" |
        grep -oE 'bash tests/[A-Za-z0-9._-]+\.test\.sh' |
        sed -e 's|^bash tests/||' | sort -u
}

# Compare one tests directory against one workflow, printing a FAIL line per
# disagreement. Returns 1 when the two sets differ, 0 when they match.
compare_wiring() { # <tests-dir> <workflow-file>
    local tests="$1" workflow="$2" cmp status=0 suite
    cmp=$(mktemp -d "${WORK}/cmp.XXXXXX") || return 2

    if [ ! -d "$tests" ]; then
        echo "FAIL: no tests directory at ${tests}"
        return 1
    fi
    if [ ! -f "$workflow" ]; then
        echo "FAIL: no workflow at ${workflow}"
        return 1
    fi

    suite_names "$tests" > "${cmp}/suites"
    if [ ! -s "${cmp}/suites" ]; then
        echo "FAIL: no *.test.sh suites found under ${tests}"
        return 1
    fi
    wired_suites "$workflow" > "${cmp}/rows"

    comm -23 "${cmp}/suites" "${cmp}/rows" > "${cmp}/unwired"
    comm -13 "${cmp}/suites" "${cmp}/rows" > "${cmp}/orphaned"

    while read -r suite; do
        echo "FAIL ${suite}: suite is not invoked by any step the workflow runs"
        status=1
    done < "${cmp}/unwired"

    while read -r suite; do
        echo "FAIL ${suite}: workflow row names a suite that does not exist"
        status=1
    done < "${cmp}/orphaned"

    return "$status"
}

fail=0

# ---- The real tree ----------------------------------------------------
if ! compare_wiring "$TESTS" "$WORKFLOW"; then
    fail=1
fi

# ---- The suite's own honesty check ------------------------------------
# CI only ever exercises the passing path, so each failure direction is
# pinned here against fixtures: without this, deleting either `comm` line
# leaves half the guard dead and CI green.
FIX="${WORK}/fixtures"
mkdir -p "${FIX}/tests"
: > "${FIX}/tests/alpha.test.sh"
: > "${FIX}/tests/beta.test.sh"

cat > "${FIX}/matched.yaml" <<'YAML'
jobs:
  test-hooks:
    runs-on: ubuntu-latest
    steps:
      - run: bash tests/alpha.test.sh
      - run: bash tests/beta.test.sh
YAML

cat > "${FIX}/unwired.yaml" <<'YAML'
jobs:
  test-hooks:
    runs-on: ubuntu-latest
    steps:
      - run: bash tests/alpha.test.sh
YAML

cat > "${FIX}/orphaned.yaml" <<'YAML'
jobs:
  test-hooks:
    runs-on: ubuntu-latest
    steps:
      - run: bash tests/alpha.test.sh
      - run: bash tests/beta.test.sh
      - run: bash tests/deleted.test.sh
YAML

cat > "${FIX}/commented.yaml" <<'YAML'
jobs:
  test-hooks:
    runs-on: ubuntu-latest
    steps:
      - run: bash tests/alpha.test.sh
      # - run: bash tests/beta.test.sh
YAML

cat > "${FIX}/gated-job.yaml" <<'YAML'
jobs:
  test-hooks:
    runs-on: ubuntu-latest
    steps:
      - run: bash tests/alpha.test.sh
  dead:
    if: false
    runs-on: ubuntu-latest
    steps:
      - run: bash tests/beta.test.sh
YAML

cat > "${FIX}/gated-step.yaml" <<'YAML'
jobs:
  test-hooks:
    runs-on: ubuntu-latest
    steps:
      - run: bash tests/alpha.test.sh
      - if: false
        run: bash tests/beta.test.sh
YAML

expect_wiring() { # <label> <agree|disagree> <workflow-fixture>
    local label="$1" want="$2" out got
    out=$(compare_wiring "${FIX}/tests" "$3")
    if [ $? -eq 0 ]; then got=agree; else got=disagree; fi
    if [ "$got" = "$want" ]; then
        echo "ok   self-check ${label}: ${want}"
        return 0
    fi
    echo "FAIL self-check ${label}: expected ${want}, got ${got}"
    printf '%s\n' "$out" | sed 's/^/     /'
    return 1
}

expect_wiring "matched sets" agree "${FIX}/matched.yaml" || fail=1
expect_wiring "suite with no row" disagree "${FIX}/unwired.yaml" || fail=1
expect_wiring "row naming a missing suite" disagree "${FIX}/orphaned.yaml" || fail=1
expect_wiring "commented-out row" disagree "${FIX}/commented.yaml" || fail=1
expect_wiring "row in an if-gated job" disagree "${FIX}/gated-job.yaml" || fail=1
expect_wiring "if-gated step" disagree "${FIX}/gated-step.yaml" || fail=1

# An empty tests directory must fail loudly rather than report a vacuous pass.
mkdir -p "${FIX}/empty"
if compare_wiring "${FIX}/empty" "${FIX}/matched.yaml" > /dev/null; then
    echo "FAIL self-check empty tests directory: reported agreement on an empty suite set"
    fail=1
else
    echo "ok   self-check empty tests directory: disagree"
fi

if [ "$fail" -ne 0 ]; then
    echo "ci-suite-wiring: FAIL — tests/ and the workflow disagree." >&2
    exit 1
fi

echo "ci-suite-wiring: PASS ($(suite_names "$TESTS" | wc -l | tr -d ' ') suites wired)"
