#!/bin/bash

# Every suite under tests/ must be invoked by the CI workflow, and every
# workflow row must name a suite that exists. Two suites once sat unwired and
# dead because nothing checked. Counting rows against files is not enough: a
# duplicated row plus a dropped one keeps the counts equal, so this compares
# the two SETS of suite names and reports both directions.
#
# TESTS_DIR and WORKFLOW_FILE override the inputs, so a mutation probe can
# point the suite at deliberately-broken COPIES under $TMPDIR without touching
# the checkout.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TESTS="${TESTS_DIR:-${SCRIPT_DIR}}"
WORKFLOW="${WORKFLOW_FILE:-${SCRIPT_DIR}/../.github/workflows/vorpal.yaml}"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/ci-suite-wiring.XXXXXX")
trap 'rm -rf "$WORK"' EXIT

if [ ! -f "$WORKFLOW" ]; then
    echo "ci-suite-wiring: FAIL — no workflow at ${WORKFLOW}" >&2
    exit 1
fi

ls "${TESTS}"/*.test.sh | xargs -n 1 basename | sort > "${WORK}/suites"
grep -oE 'bash tests/[A-Za-z0-9._-]+\.test\.sh' "$WORKFLOW" |
    sed -e 's|^bash tests/||' | sort -u > "${WORK}/rows"

fail=0

comm -23 "${WORK}/suites" "${WORK}/rows" > "${WORK}/unwired"
comm -13 "${WORK}/suites" "${WORK}/rows" > "${WORK}/orphaned"

while read -r suite; do
    echo "FAIL ${suite}: suite has no row in the workflow"
    fail=1
done < "${WORK}/unwired"

while read -r suite; do
    echo "FAIL ${suite}: workflow row names a suite that does not exist"
    fail=1
done < "${WORK}/orphaned"

if [ "$fail" -ne 0 ]; then
    echo "ci-suite-wiring: FAIL — tests/ and the workflow disagree." >&2
    exit 1
fi

echo "ci-suite-wiring: PASS ($(wc -l < "${WORK}/suites" | tr -d ' ') suites wired)"
