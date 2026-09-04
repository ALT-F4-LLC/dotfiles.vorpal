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
# count as wiring. Gating is a property of the whole job, so a job's rows are
# buffered and emitted only after the job has been read out; YAML puts no
# ordering constraint on a job's keys, and an `if:` written below `steps:`
# gates the job exactly as one written above it. Gating rides down `needs:`
# too: Actions skips a job whose needed job was skipped, so a job needing a
# gated job is itself gated, transitively. A gated row is treated as
# absent whatever its condition says — evaluating GitHub expressions here
# would be a second, worse parser, and "the suite runs on every CI run" is the
# invariant worth holding.
#
# A row counts only when its whole `run:` command, trimmed, is exactly
# `bash tests/<name>.test.sh`. A suite merely named inside a larger command
# (an echo, a conditional) is deliberately read as unwired: such a command may
# never execute the suite, and under-reporting wiring is the safe direction.
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
# and gated steps drop out; rows are held per job and released only once the
# whole workflow has been read, so a late `if:` still gates them and gating
# can ride down `needs:` edges before anything is printed.
wired_suites() { # <workflow-file>
    awk '
        function flush_step() {
            if (step_run != "" && !step_gated) {
                rowjob[++nrows] = job
                rowcmd[nrows] = step_run
            }
            step_run = ""
            step_gated = 0
        }
        function flush_job() {
            flush_step()
            if (job != "") {
                gated[job] = job_gated
                needs[job] = job_needs
            }
            job = ""
            job_gated = 0
            job_needs = ""
            in_steps = 0
            in_needs = 0
        }
        /^[[:space:]]*#/ { next }
        {
            match($0, /^ */)
            ind = RLENGTH
            rest = substr($0, ind + 1)
            if (rest == "") next

            if (ind == 0) { flush_job(); next }
            if (ind == 2 && rest ~ /^[A-Za-z0-9_.-]+:[[:space:]]*$/) {
                flush_job()
                job = rest
                sub(/:[[:space:]]*$/, "", job)
                next
            }
            if (ind == 4) {
                flush_step()
                in_steps = (rest ~ /^steps:/)
                in_needs = (rest ~ /^needs:/)
                if (rest ~ /^if:/) job_gated = 1
                if (in_needs) {
                    dep_list = substr(rest, 7)
                    gsub(/[][,]/, " ", dep_list)
                    job_needs = job_needs " " dep_list
                }
                next
            }
            if (in_needs && ind == 6 && rest ~ /^- /) {
                job_needs = job_needs " " substr(rest, 3)
                next
            }
            if (!in_steps) next

            if (ind == 6 && rest ~ /^- /) { flush_step(); key = substr(rest, 3) }
            else if (ind == 8) { key = rest }
            else next

            if (key ~ /^if:/) step_gated = 1
            if (key ~ /^run:/) {
                step_run = substr(key, 5)
                sub(/^[[:space:]]+/, "", step_run)
                sub(/[[:space:]]+$/, "", step_run)
            }
        }
        END {
            flush_job()
            do {
                spread = 0
                for (j in needs) {
                    if (gated[j]) continue
                    n = split(needs[j], dep, /[[:space:]]+/)
                    for (i = 1; i <= n; i++)
                        if (dep[i] != "" && gated[dep[i]]) {
                            gated[j] = 1
                            spread = 1
                        }
                }
            } while (spread)
            for (i = 1; i <= nrows; i++)
                if (!gated[rowjob[i]]) print rowcmd[i]
        }
    ' "$1" |
        sed -n 's|^bash tests/\([A-Za-z0-9._-]*\.test\.sh\)$|\1|p' | sort -u
}

# Compare one tests directory against one workflow, printing a FAIL line per
# disagreement. Returns 0 when the sets match and 1 when they differ; 2 means
# an input made the comparison impossible, which a caller must never read as a
# trustworthy disagreement.
compare_wiring() { # <tests-dir> <workflow-file>
    local tests="$1" workflow="$2" cmp status=0 suite

    if [ ! -d "$tests" ]; then
        echo "FAIL: no tests directory at ${tests}"
        return 2
    fi
    if [ ! -f "$workflow" ]; then
        echo "FAIL: no workflow at ${workflow}"
        return 2
    fi

    cmp=$(mktemp -d "${WORK}/cmp.XXXXXX") || {
        echo "FAIL: no scratch directory under ${WORK}"
        return 2
    }

    suite_names "$tests" > "${cmp}/suites"
    if [ ! -s "${cmp}/suites" ]; then
        echo "FAIL: no *.test.sh suites found under ${tests}"
        return 2
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
mkdir -p "${FIX}/tests" "${FIX}/spaced" "${FIX}/empty"
: > "${FIX}/tests/alpha.test.sh"
: > "${FIX}/tests/beta.test.sh"
: > "${FIX}/spaced/alpha.test.sh"
: > "${FIX}/spaced/beta.test.sh"
: > "${FIX}/spaced/two words.test.sh"

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

cat > "${FIX}/commented-row.yaml" <<'YAML'
jobs:
  test-hooks:
    runs-on: ubuntu-latest
    steps:
      - run: bash tests/alpha.test.sh
      # - run: bash tests/beta.test.sh
YAML

# A comment is legal at any column, including inside a steps list. This one
# sits at column zero, where only the comment rule can drop it: the shape test
# that catches the fixture above never sees it.
cat > "${FIX}/comment-column-zero.yaml" <<'YAML'
jobs:
  test-hooks:
    runs-on: ubuntu-latest
    steps:
      - run: bash tests/alpha.test.sh
# a note parked at column zero, still inside the steps list
      - run: bash tests/beta.test.sh
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

cat > "${FIX}/gated-job-late-if.yaml" <<'YAML'
jobs:
  test-hooks:
    runs-on: ubuntu-latest
    steps:
      - run: bash tests/alpha.test.sh
  dead:
    runs-on: ubuntu-latest
    steps:
      - run: bash tests/beta.test.sh
    if: false
YAML

# Actions skips a job whose needed job was skipped, so gating rides down the
# `needs:` edges. Inline list form here, block form below.
cat > "${FIX}/needs-gated-job.yaml" <<'YAML'
jobs:
  gate:
    if: false
    runs-on: ubuntu-latest
    steps:
      - run: echo gate
  test-hooks:
    needs: [gate]
    runs-on: ubuntu-latest
    steps:
      - run: bash tests/alpha.test.sh
      - run: bash tests/beta.test.sh
YAML

cat > "${FIX}/needs-gated-transitive.yaml" <<'YAML'
jobs:
  gate:
    if: false
    runs-on: ubuntu-latest
    steps:
      - run: echo gate
  middle:
    needs:
      - gate
    runs-on: ubuntu-latest
    steps:
      - run: bash tests/alpha.test.sh
  test-hooks:
    needs:
      - middle
    runs-on: ubuntu-latest
    steps:
      - run: bash tests/beta.test.sh
YAML

# The control for the two above: a `needs:` on an ungated job gates nothing.
cat > "${FIX}/needs-ungated-job.yaml" <<'YAML'
jobs:
  build-dev:
    runs-on: ubuntu-latest
    steps:
      - run: echo build
  test-hooks:
    needs:
      - build-dev
    runs-on: ubuntu-latest
    steps:
      - run: bash tests/alpha.test.sh
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

cat > "${FIX}/mention-only.yaml" <<'YAML'
jobs:
  test-hooks:
    runs-on: ubuntu-latest
    steps:
      - run: bash tests/alpha.test.sh
      - run: echo "to reproduce locally, run bash tests/beta.test.sh"
YAML

# Assert both halves of compare_wiring's answer: the status AND the exact FAIL
# lines. Asserting the status alone would leave the two `comm` directions
# interchangeable, so a suite naming every real failure as its own inverse
# would still read green.
expect_wiring() { # <label> <status> <tests-dir> <workflow> [<expected line>...]
    local label="$1" want_status="$2" tests="$3" workflow="$4"
    shift 4
    local out got want_out=''
    if [ "$#" -gt 0 ]; then
        want_out=$(printf '%s\n' "$@")
    fi
    out=$(compare_wiring "$tests" "$workflow")
    got=$?
    if [ "$got" = "$want_status" ] && [ "$out" = "$want_out" ]; then
        echo "ok   self-check ${label}"
        return 0
    fi
    echo "FAIL self-check ${label}: expected status ${want_status}, got ${got}"
    echo "     expected output:"
    printf '%s\n' "$want_out" | sed 's/^/       /'
    echo "     actual output:"
    printf '%s\n' "$out" | sed 's/^/       /'
    return 1
}

UNWIRED_ALPHA="FAIL alpha.test.sh: suite is not invoked by any step the workflow runs"
UNWIRED_BETA="FAIL beta.test.sh: suite is not invoked by any step the workflow runs"

expect_wiring "matched sets" 0 "${FIX}/tests" "${FIX}/matched.yaml" || fail=1
expect_wiring "suite with no row" 1 "${FIX}/tests" "${FIX}/unwired.yaml" \
    "$UNWIRED_BETA" || fail=1
expect_wiring "row naming a missing suite" 1 "${FIX}/tests" "${FIX}/orphaned.yaml" \
    "FAIL deleted.test.sh: workflow row names a suite that does not exist" || fail=1
expect_wiring "commented-out row" 1 "${FIX}/tests" "${FIX}/commented-row.yaml" \
    "$UNWIRED_BETA" || fail=1
expect_wiring "column-zero comment between rows" 0 "${FIX}/tests" \
    "${FIX}/comment-column-zero.yaml" || fail=1
expect_wiring "job gated before steps" 1 "${FIX}/tests" "${FIX}/gated-job.yaml" \
    "$UNWIRED_BETA" || fail=1
expect_wiring "job gated after steps" 1 "${FIX}/tests" "${FIX}/gated-job-late-if.yaml" \
    "$UNWIRED_BETA" || fail=1
expect_wiring "job needing a gated job" 1 "${FIX}/tests" "${FIX}/needs-gated-job.yaml" \
    "$UNWIRED_ALPHA" "$UNWIRED_BETA" || fail=1
expect_wiring "job needing a job that needs a gated job" 1 "${FIX}/tests" \
    "${FIX}/needs-gated-transitive.yaml" "$UNWIRED_ALPHA" "$UNWIRED_BETA" || fail=1
expect_wiring "job needing an ungated job" 0 "${FIX}/tests" \
    "${FIX}/needs-ungated-job.yaml" || fail=1
expect_wiring "if-gated step" 1 "${FIX}/tests" "${FIX}/gated-step.yaml" \
    "$UNWIRED_BETA" || fail=1
expect_wiring "suite named but not run" 1 "${FIX}/tests" "${FIX}/mention-only.yaml" \
    "$UNWIRED_BETA" || fail=1
expect_wiring "suite name holding a space" 1 "${FIX}/spaced" "${FIX}/matched.yaml" \
    "FAIL two words.test.sh: suite is not invoked by any step the workflow runs" || fail=1
expect_wiring "empty tests directory" 2 "${FIX}/empty" "${FIX}/matched.yaml" \
    "FAIL: no *.test.sh suites found under ${FIX}/empty" || fail=1
expect_wiring "missing tests directory" 2 "${FIX}/absent" "${FIX}/matched.yaml" \
    "FAIL: no tests directory at ${FIX}/absent" || fail=1

if [ "$fail" -ne 0 ]; then
    echo "ci-suite-wiring: FAIL — tests/ and the workflow disagree." >&2
    exit 1
fi

echo "ci-suite-wiring: PASS ($(suite_names "$TESTS" | wc -l | tr -d ' ') suites wired)"
