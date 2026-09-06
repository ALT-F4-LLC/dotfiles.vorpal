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
# Known limits, each named with the direction it errs in:
#   - `continue-on-error: true` on a step: the row still counts as wired, but
#     a red run there does not fail CI, so "wired" is weaker than "must pass"
#     for that row. Over-reports.
#   - `if: always()` (or any expression referencing a gated dependency's
#     status) on a job that `needs:` a gated job: this file treats the
#     dependent as gated like any other `needs:` edge, but Actions still runs
#     an `always()` job whose need was skipped. Under-reports (loud: a wired
#     suite is reported unwired).
#   - a `needs:` target that names a job this file never defines (a typo, or
#     a job in another workflow file): the lookup is silently absent from
#     `gated`, so the dependent is never marked gated. Over-reports.
#   - the job-key indentation assumption: job keys are matched only at two
#     spaces (`ind == 2`). A workflow reindented to some other width would
#     have every job read as key-less text, and every suite would report
#     unwired. Under-reports (loud).
#
# This file also checks a second wiring path: the justfile `tests` recipe
# that a developer runs locally must reach every suite too, or a relaxed
# guard is caught only in CI, on the pull request, rather than before it.
#
# TESTS_DIR, WORKFLOW_FILE and JUSTFILE override the inputs, so a mutation
# probe can point the suite at deliberately-broken COPIES under $TMPDIR
# without touching the checkout.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TESTS="${TESTS_DIR:-${SCRIPT_DIR}}"
WORKFLOW="${WORKFLOW_FILE:-${SCRIPT_DIR}/../.github/workflows/vorpal.yaml}"
JUSTFILE="${JUSTFILE:-${SCRIPT_DIR}/../justfile}"

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
        # A dependency token may be quoted (needs: ["gate"] or needs:\n  - "gate");
        # strip a matching pair of surrounding quotes so it compares equal to the
        # job key, which is never quoted.
        function unquote_needs(list,    n, i, tok, out) {
            n = split(list, tok, /[[:space:]]+/)
            out = ""
            for (i = 1; i <= n; i++) {
                if (tok[i] == "") continue
                gsub(/^"|"$|^'\''|'\''$/, "", tok[i])
                out = out " " tok[i]
            }
            return out
        }
        function flush_job() {
            flush_step()
            if (job != "") {
                gated[job] = job_gated
                needs[job] = unquote_needs(job_needs)
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
            if (ind == 2) {
                hdr = rest
                sub(/[[:space:]]+#.*$/, "", hdr)
                if (hdr ~ /^[A-Za-z0-9_.-]+:[[:space:]]*$/) {
                    flush_job()
                    job = hdr
                    sub(/:[[:space:]]*$/, "", job)
                    next
                }
            }
            # A needs: block sequence dash item may sit at the indentation of
            # the needs: key itself (ind 4) or one level deeper (ind 6); either
            # way this must fire before the general ind==4 handling below,
            # which re-derives in_needs from rest and clears it for a line
            # that is not a key.
            if (in_needs && (ind == 4 || ind == 6) && rest ~ /^- /) {
                job_needs = job_needs " " substr(rest, 3)
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
# Suite basenames the justfile's `tests` recipe would run, sorted and
# deduplicated. The workflow-vs-directory comparison above says nothing about
# the local `tests` recipe itself: deleting its loop over tests/*.test.sh
# leaves CI and that comparison green, since CI never runs `just tests`. This
# extracts the recipe body (from its header line to the next non-indented,
# non-blank line, matching just's own recipe-body rule) and reads two shapes
# out of it: a `for <var> in tests/*.test.sh` glob loop, which reaches every
# suite whatever the tree currently holds, and any literal
# `bash tests/<name>.test.sh` mention, for a recipe that lists suites by
# name instead. A recipe with a glob loop is read as reaching every suite
# under the given tests directory without naming them, since that is what
# the shell would do.
recipe_suites() { # <tests-dir> <justfile>
    local tests="$1" body loop_var
    body=$(awk '
        /^tests:/ { in_recipe = 1; next }
        in_recipe && /^[^[:space:]]/ { exit }
        in_recipe { print }
    ' "$2")

    loop_var=$(printf '%s\n' "$body" |
        sed -n 's/^[[:space:]]*for[[:space:]][[:space:]]*\([A-Za-z_][A-Za-z0-9_]*\)[[:space:]][[:space:]]*in[[:space:]][[:space:]]*tests\/\*\.test\.sh[[:space:]]*;.*/\1/p' |
        head -n1)

    if [ -n "$loop_var" ]; then
        suite_names "$tests"
        return
    fi

    printf '%s\n' "$body" |
        sed -n 's|.*bash[[:space:]][[:space:]]*tests/\([A-Za-z0-9._-]*\.test\.sh\).*|\1|p' | sort -u
}

# Compare one tests directory against one justfile's `tests` recipe, printing
# a FAIL line per suite the recipe cannot reach. This is one-directional,
# unlike compare_wiring: a recipe naming a deleted suite is a dead reference,
# not a gap in coverage, and is out of scope here.
compare_recipe() { # <tests-dir> <justfile>
    local tests="$1" justfile="$2" cmp status=0 suite

    if [ ! -d "$tests" ]; then
        echo "FAIL: no tests directory at ${tests}"
        return 2
    fi
    if [ ! -f "$justfile" ]; then
        echo "FAIL: no justfile at ${justfile}"
        return 2
    fi
    if ! grep -q '^tests:' "$justfile"; then
        echo "FAIL: no tests recipe in ${justfile}"
        return 2
    fi

    cmp=$(mktemp -d "${WORK}/recipe.XXXXXX") || {
        echo "FAIL: no scratch directory under ${WORK}"
        return 2
    }

    suite_names "$tests" > "${cmp}/suites"
    if [ ! -s "${cmp}/suites" ]; then
        echo "FAIL: no *.test.sh suites found under ${tests}"
        return 2
    fi
    recipe_suites "$tests" "$justfile" > "${cmp}/reached"

    comm -23 "${cmp}/suites" "${cmp}/reached" > "${cmp}/unreached"

    while read -r suite; do
        echo "FAIL ${suite}: suite is not reachable from the tests recipe"
        status=1
    done < "${cmp}/unreached"

    return "$status"
}

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
if ! compare_recipe "$TESTS" "$JUSTFILE"; then
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

# A job header carrying a trailing comment must still end the previous job:
# the comment must not merge test-hooks and dead into one buffer and drop
# alpha's row into dead's gated flush.
cat > "${FIX}/gated-job-commented-header.yaml" <<'YAML'
jobs:
  test-hooks:
    runs-on: ubuntu-latest
    steps:
      - run: bash tests/alpha.test.sh
  dead: # macos build
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

# A block-sequence `- ` item at the SAME indentation as its `needs:` key
# (rather than one level deeper) must still gate.
cat > "${FIX}/needs-gated-job-same-indent.yaml" <<'YAML'
jobs:
  gate:
    if: false
    runs-on: ubuntu-latest
    steps:
      - run: echo gate
  test-hooks:
    needs:
    - gate
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

# A quoted dependency token must compare equal to the unquoted job key: both
# the flow-sequence and block-sequence spellings can carry quotes.
cat > "${FIX}/needs-gated-job-quoted.yaml" <<'YAML'
jobs:
  gate:
    if: false
    runs-on: ubuntu-latest
    steps:
      - run: echo gate
  test-hooks:
    needs: ["gate"]
    runs-on: ubuntu-latest
    steps:
      - run: bash tests/alpha.test.sh
      - run: bash tests/beta.test.sh
YAML

cat > "${FIX}/needs-gated-job-quoted-block.yaml" <<'YAML'
jobs:
  gate:
    if: false
    runs-on: ubuntu-latest
    steps:
      - run: echo gate
  test-hooks:
    needs:
      - "gate"
    runs-on: ubuntu-latest
    steps:
      - run: bash tests/alpha.test.sh
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

# `if:` written AFTER `run:` in the same step must still gate it: nothing in
# YAML requires the condition to precede the command.
cat > "${FIX}/gated-step-if-after-run.yaml" <<'YAML'
jobs:
  test-hooks:
    runs-on: ubuntu-latest
    steps:
      - run: bash tests/alpha.test.sh
      - run: bash tests/beta.test.sh
        if: false
YAML

# A gated job placed BEFORE an ungated job: gating must not leak across the
# job boundary, in either direction.
cat > "${FIX}/gated-job-first.yaml" <<'YAML'
jobs:
  dead:
    if: false
    runs-on: ubuntu-latest
    steps:
      - run: echo dead
  test-hooks:
    runs-on: ubuntu-latest
    steps:
      - run: bash tests/alpha.test.sh
      - run: bash tests/beta.test.sh
YAML

cat > "${FIX}/mention-only.yaml" <<'YAML'
jobs:
  test-hooks:
    runs-on: ubuntu-latest
    steps:
      - run: bash tests/alpha.test.sh
      - run: echo "to reproduce locally, run bash tests/beta.test.sh"
YAML

# A tests recipe that globs tests/*.test.sh reaches every suite in the tree
# without naming any of them.
cat > "${FIX}/justfile-loop" <<'JUST'
tests:
    #!/usr/bin/env bash
    set -euo pipefail
    cargo test --locked --offline
    for suite in tests/*.test.sh; do
        echo "==> $suite"
        bash "$suite"
    done

build:
    cargo build --locked --offline
JUST

# The mutant this issue exists to catch: the loop over tests/*.test.sh is
# gone, so nothing in the recipe reaches any suite.
cat > "${FIX}/justfile-no-loop" <<'JUST'
tests:
    #!/usr/bin/env bash
    set -euo pipefail
    cargo test --locked --offline

build:
    cargo build --locked --offline
JUST

# A recipe that lists suites by name instead of globbing: reaches only the
# suites it names.
cat > "${FIX}/justfile-named" <<'JUST'
tests:
    #!/usr/bin/env bash
    set -euo pipefail
    bash tests/alpha.test.sh

build:
    cargo build --locked --offline
JUST

cat > "${FIX}/justfile-no-tests-recipe" <<'JUST'
build:
    cargo build --locked --offline
JUST

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

# Same shape as expect_wiring, for compare_recipe.
expect_recipe() { # <label> <status> <tests-dir> <justfile> [<expected line>...]
    local label="$1" want_status="$2" tests="$3" justfile="$4"
    shift 4
    local out got want_out=''
    if [ "$#" -gt 0 ]; then
        want_out=$(printf '%s\n' "$@")
    fi
    out=$(compare_recipe "$tests" "$justfile")
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
expect_wiring "commented job header before a gated job" 1 "${FIX}/tests" \
    "${FIX}/gated-job-commented-header.yaml" "$UNWIRED_BETA" || fail=1
expect_wiring "job needing a gated job" 1 "${FIX}/tests" "${FIX}/needs-gated-job.yaml" \
    "$UNWIRED_ALPHA" "$UNWIRED_BETA" || fail=1
expect_wiring "job needing a gated job, block sequence at key indentation" 1 \
    "${FIX}/tests" "${FIX}/needs-gated-job-same-indent.yaml" \
    "$UNWIRED_ALPHA" "$UNWIRED_BETA" || fail=1
expect_wiring "job needing a job that needs a gated job" 1 "${FIX}/tests" \
    "${FIX}/needs-gated-transitive.yaml" "$UNWIRED_ALPHA" "$UNWIRED_BETA" || fail=1
expect_wiring "job needing a gated job, quoted flow sequence" 1 "${FIX}/tests" \
    "${FIX}/needs-gated-job-quoted.yaml" "$UNWIRED_ALPHA" "$UNWIRED_BETA" || fail=1
expect_wiring "job needing a gated job, quoted block sequence" 1 "${FIX}/tests" \
    "${FIX}/needs-gated-job-quoted-block.yaml" "$UNWIRED_ALPHA" "$UNWIRED_BETA" || fail=1
expect_wiring "job needing an ungated job" 0 "${FIX}/tests" \
    "${FIX}/needs-ungated-job.yaml" || fail=1
expect_wiring "if-gated step" 1 "${FIX}/tests" "${FIX}/gated-step.yaml" \
    "$UNWIRED_BETA" || fail=1
expect_wiring "if-gated step, if after run" 1 "${FIX}/tests" \
    "${FIX}/gated-step-if-after-run.yaml" "$UNWIRED_BETA" || fail=1
expect_wiring "gated job before an ungated job" 0 "${FIX}/tests" \
    "${FIX}/gated-job-first.yaml" || fail=1
expect_wiring "suite named but not run" 1 "${FIX}/tests" "${FIX}/mention-only.yaml" \
    "$UNWIRED_BETA" || fail=1
expect_wiring "suite name holding a space" 1 "${FIX}/spaced" "${FIX}/matched.yaml" \
    "FAIL two words.test.sh: suite is not invoked by any step the workflow runs" || fail=1
expect_wiring "empty tests directory" 2 "${FIX}/empty" "${FIX}/matched.yaml" \
    "FAIL: no *.test.sh suites found under ${FIX}/empty" || fail=1
expect_wiring "missing tests directory" 2 "${FIX}/absent" "${FIX}/matched.yaml" \
    "FAIL: no tests directory at ${FIX}/absent" || fail=1

expect_recipe "recipe with a glob loop" 0 "${FIX}/tests" "${FIX}/justfile-loop" || fail=1
expect_recipe "recipe with the loop deleted" 1 "${FIX}/tests" "${FIX}/justfile-no-loop" \
    "FAIL alpha.test.sh: suite is not reachable from the tests recipe" \
    "FAIL beta.test.sh: suite is not reachable from the tests recipe" || fail=1
expect_recipe "recipe naming one suite" 1 "${FIX}/tests" "${FIX}/justfile-named" \
    "FAIL beta.test.sh: suite is not reachable from the tests recipe" || fail=1
expect_recipe "no tests recipe in the justfile" 2 "${FIX}/tests" \
    "${FIX}/justfile-no-tests-recipe" \
    "FAIL: no tests recipe in ${FIX}/justfile-no-tests-recipe" || fail=1
expect_recipe "missing tests directory, recipe check" 2 "${FIX}/absent" \
    "${FIX}/justfile-loop" "FAIL: no tests directory at ${FIX}/absent" || fail=1

if [ "$fail" -ne 0 ]; then
    echo "ci-suite-wiring: FAIL — tests/ and the workflow disagree." >&2
    exit 1
fi

echo "ci-suite-wiring: PASS ($(suite_names "$TESTS" | wc -l | tr -d ' ') suites wired)"
