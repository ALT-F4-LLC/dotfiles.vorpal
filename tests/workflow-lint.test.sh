#!/bin/bash

# Every workflow TOML under src/user/docket/config/workflows/ must pass
# `docket workflow lint`, the same validation `docket workflow register` runs.
# Without this, a workflow edit that can never register passes the write
# steps' `tests` gate and fails only at registration.
#
# Availability: lint needs `docket` on PATH and a project registry that
# `docket project list --json` reports ok. When either is missing the suite
# FAILS, naming what is missing, so a green run is evidence that lint ran.
# The one exception is WORKFLOW_LINT_SKIP=1, which only the CI step sets
# (CI has no docket install): with it, a missing tool or registry prints one
# SKIP line naming the reason and exits 0. The variable is consulted only
# when docket or the registry is unavailable; it never skips a lint that
# could run. Neither this suite nor the justfile `tests` recipe sets it.
#
# WORKFLOWS_DIR overrides the directory linted, so a mutation probe can point
# the suite at a deliberately-broken COPY under $TMPDIR without touching the
# checkout. Lint still runs from the repository root, so the registry it
# resolves is this project's.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
WORKFLOWS="${WORKFLOWS_DIR:-${REPO_ROOT}/src/user/docket/config/workflows}"

cd "$REPO_ROOT" || exit 2

unavailable=""
if ! command -v docket > /dev/null 2>&1; then
    unavailable="docket is not on PATH"
elif ! docket project list --json < /dev/null 2> /dev/null | jq -e '.ok == true' > /dev/null 2>&1; then
    unavailable="the docket project registry is unavailable (docket project list --json did not return ok)"
fi

if [ -n "$unavailable" ]; then
    if [ "${WORKFLOW_LINT_SKIP:-}" = "1" ]; then
        echo "SKIP workflow-lint: ${unavailable}"
        exit 0
    fi
    echo "FAIL workflow-lint: ${unavailable}; set WORKFLOW_LINT_SKIP=1 only where docket cannot be installed" >&2
    exit 1
fi

shopt -s nullglob
files=("${WORKFLOWS}"/*.toml)
shopt -u nullglob

if [ "${#files[@]}" -eq 0 ]; then
    echo "FAIL workflow-lint: no *.toml workflows found under ${WORKFLOWS}" >&2
    exit 1
fi

fail=0
for file in "${files[@]}"; do
    if out=$(docket workflow lint "$file" < /dev/null 2>&1); then
        echo "ok   $(basename "$file")"
    else
        status=$?
        echo "FAIL $(basename "$file"): docket workflow lint exited ${status}"
        printf '%s\n' "$out" | sed 's/^/     /'
        fail=1
    fi
done

if [ "$fail" -ne 0 ]; then
    echo "workflow-lint: FAIL — a workflow TOML does not pass docket workflow lint." >&2
    exit 1
fi

echo "workflow-lint: PASS (${#files[@]} workflows lint clean)"
