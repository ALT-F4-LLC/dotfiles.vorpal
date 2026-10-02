#!/bin/bash

# tests/workflow-lint.test.sh is the write steps' `tests` gate for workflow
# TOML, and its worth is in how it fails: missing docket, jq or registry must
# fail, the WORKFLOW_LINT_SKIP escape must hold only in CI, a working docket
# must never be skipped, and a lint rejection or an empty glob must fail. CI
# runs that suite with the skip set and no docket, so none of those branches
# run there; an edit could turn the gate into a silent no-op and stay green.
# This suite pins each branch against a stub docket.
#
# Every case runs the lint suite under `env -i` on a PATH of symlinks to only
# the tools it calls plus the stub, with a temp WORKFLOWS_DIR, and with
# WORKFLOW_LINT_SKIP and GITHUB_ACTIONS set or left unset per case, so neither
# the real docket, the checkout's workflows, nor the caller's environment
# (a CI runner sets GITHUB_ACTIONS=true) can change an outcome.
#
# LINT_SUITE overrides the suite under test, so a mutation probe can point
# this suite at a deliberately-broken COPY under $TMPDIR without touching the
# checkout.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LINT="${LINT_SUITE:-${SCRIPT_DIR}/workflow-lint.test.sh}"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$LINT" ] || fatal "lint suite not found at ${LINT}"
BASH_BIN=$(command -v bash) || fatal "bash not found on PATH"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/workflow-lint-contract.XXXXXX") || exit 2
trap 'rm -rf "$WORK"' EXIT

# Two controlled PATHs: the tools the lint suite calls, with and without jq.
# The stub docket joins each through its own directory.
TOOLS="${WORK}/tools"
TOOLS_NO_JQ="${WORK}/tools-no-jq"
STUB="${WORK}/stub"
mkdir -p "$TOOLS" "$TOOLS_NO_JQ" "$STUB"
for tool in bash dirname basename sed jq; do
    tool_path=$(command -v "$tool") || fatal "lint suite dependency ${tool} not found on PATH"
    ln -s "$tool_path" "${TOOLS}/${tool}"
    [ "$tool" = jq ] || ln -s "$tool_path" "${TOOLS_NO_JQ}/${tool}"
done

# `project list --json` answers ok only when STUB_REGISTRY_OK=1, and
# `workflow lint` rejects only the basename named in STUB_LINT_FAIL.
cat > "${STUB}/docket" <<STUB
#!${BASH_BIN}
case "\$1 \$2" in
    "project list")
        if [ "\${STUB_REGISTRY_OK:-}" = "1" ]; then echo '{"ok":true}'; else echo '{"ok":false}'; fi
        ;;
    "workflow lint")
        [ "\${3##*/}" != "\${STUB_LINT_FAIL:-}" ] || { echo "stub: \${3##*/} rejected"; exit 3; }
        ;;
    *)
        echo "stub docket: unexpected call: \$*" >&2
        exit 64
        ;;
esac
STUB
chmod +x "${STUB}/docket"

WITH_DOCKET="${STUB}:${TOOLS}"
NO_JQ="${STUB}:${TOOLS_NO_JQ}"
NO_DOCKET="$TOOLS"

# Workflow directories: an empty one, and one with a good and a bad file. The
# stub never reads them, so their content is irrelevant.
DIR_EMPTY="${WORK}/wf-empty"
DIR_MIXED="${WORK}/wf-mixed"
mkdir -p "$DIR_EMPTY" "$DIR_MIXED"
: > "${DIR_MIXED}/good.toml"
: > "${DIR_MIXED}/bad.toml"

# Run the lint suite with a clean environment: only PATH, WORKFLOWS_DIR and
# the given VAR=value pairs. Sets status, OUT and ERR.
run_lint() { # <path> <workflows-dir> [VAR=value...]
    local path="$1" dir="$2"
    shift 2
    OUT=$(env -i PATH="$path" WORKFLOWS_DIR="$dir" "$@" "$BASH_BIN" "$LINT" 2> "${WORK}/err")
    status=$?
    ERR=$(cat "${WORK}/err")
}

fail=0
cases=0

# Assert the exit status and one or more output checks for the last run_lint.
# A check is `out~<text>` (stdout contains), `err~<text>` (stderr contains),
# `out^<text>` (a stdout line starts with), or `nil^<text>` (no line of either
# stream starts with).
expect() { # <label> <status> <check>...
    local label="$1" want="$2" check text bad=""
    shift 2
    cases=$((cases + 1))
    [ "$status" = "$want" ] || bad="expected exit ${want}, got ${status}"
    for check in "$@"; do
        text="${check:4}"
        case "${check:0:4}" in
            'out~') [[ "$OUT" == *"$text"* ]] || bad="${bad:+$bad; }stdout lacks '${text}'" ;;
            'err~') [[ "$ERR" == *"$text"* ]] || bad="${bad:+$bad; }stderr lacks '${text}'" ;;
            'out^') [[ $'\n'"$OUT" == *$'\n'"$text"* ]] || bad="${bad:+$bad; }no stdout line starts with '${text}'" ;;
            'nil^') [[ $'\n'"$OUT"$'\n'"$ERR" != *$'\n'"$text"* ]] || bad="${bad:+$bad; }a line starts with '${text}'" ;;
            *) fatal "unknown check ${check}" ;;
        esac
    done
    if [ -z "$bad" ]; then
        echo "ok   ${label}"
        return
    fi
    echo "FAIL ${label}: ${bad}"
    printf '%s\n' "$OUT" | sed 's/^/     stdout: /'
    printf '%s\n' "$ERR" | sed 's/^/     stderr: /'
    fail=1
}

run_lint "$NO_DOCKET" "$DIR_MIXED"
expect "no docket fails" 1 'err~docket is not on PATH'

run_lint "$WITH_DOCKET" "$DIR_MIXED" STUB_REGISTRY_OK=0
expect "unavailable registry fails" 1 'err~registry is unavailable'

run_lint "$NO_DOCKET" "$DIR_MIXED" WORKFLOW_LINT_SKIP=1 GITHUB_ACTIONS=true
expect "no docket skips in CI" 0 'out^SKIP workflow-lint:'

run_lint "$NO_DOCKET" "$DIR_MIXED" WORKFLOW_LINT_SKIP=1
expect "skip outside CI fails" 1 'err~FAIL workflow-lint:' 'nil^SKIP workflow-lint:'

run_lint "$WITH_DOCKET" "$DIR_MIXED" STUB_REGISTRY_OK=1 STUB_LINT_FAIL=bad.toml \
    WORKFLOW_LINT_SKIP=1 GITHUB_ACTIONS=true
expect "skip not honored while docket works" 1 'out~FAIL bad.toml'

run_lint "$WITH_DOCKET" "$DIR_MIXED" STUB_REGISTRY_OK=1 STUB_LINT_FAIL=bad.toml
expect "lint rejection fails naming the file" 1 'out~FAIL bad.toml'

run_lint "$WITH_DOCKET" "$DIR_EMPTY" STUB_REGISTRY_OK=1
expect "empty glob fails" 1 'err~no *.toml workflows found'

run_lint "$WITH_DOCKET" "$DIR_MIXED" STUB_REGISTRY_OK=1
expect "clean lint passes" 0 'out~workflow-lint: PASS'

run_lint "$NO_JQ" "$DIR_MIXED" STUB_REGISTRY_OK=1 WORKFLOW_LINT_SKIP=1 GITHUB_ACTIONS=true
expect "no jq fails even in CI" 1 'err~jq is not on PATH' 'nil^SKIP workflow-lint:'

if [ "$fail" -ne 0 ]; then
    echo "workflow-lint-contract: FAIL — workflow-lint.test.sh broke its availability or failure contract." >&2
    exit 1
fi

echo "workflow-lint-contract: PASS (${cases} cases)"
