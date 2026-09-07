#!/bin/bash

# Behavior suite for .docket/bin/frozen-drift-check's contracts/fragments
# comparison — the half of the gate that needs only git, run through
# FROZEN_DRIFT_CHECK_SKIP_ENGINE=1 to skip the schema/workflow phases, which
# need a live docket engine and its registry.
#
# THE PROPERTY UNDER TEST: a contract's front-matter version must move in
# lockstep with its body, checked against the merge-base with the
# integration branch rather than HEAD directly. Before that reference
# change, a body edit committed with `git commit -am` made HEAD equal the
# working tree, so the check compared a file against itself and always read
# "unchanged" — a committed missing version bump passed silently.
#
# SEAM. Each case builds a throwaway git fixture repo under $TMPDIR with a
# `main` branch and a `feature` branch checked out from it (mirroring this
# repository's own branch-off-main shape), edits a contract on `feature`,
# and drives the gate script against it with the engine phases skipped.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
GATE="${FROZEN_DRIFT_CHECK_GATE:-${REPO_ROOT}/.docket/bin/frozen-drift-check}"

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

[ -f "$GATE" ] || fatal "gate not found at ${GATE}"
command -v jq >/dev/null 2>&1 || fatal "jq is required to run this test"
command -v shasum >/dev/null 2>&1 || fatal "shasum is required to run this test"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/frozen-drift-check-test.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT

# build_repo <dir>; a git repo with a `main` branch holding one contract at
# v2, and a `feature` branch checked out from it — the shape this repository
# itself has (a worktree branched off main), so the merge-base reference has
# somewhere to diverge from. The gate script is copied into the fixture's
# own .docket/bin/: the gate finds its repo root via
# `git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel`, so
# running the worktree's own copy from a different cwd would still resolve
# to the worktree, not the fixture.
build_repo() { # <dir>
    local dir="$1"
    mkdir -p "${dir}/src/user/docket/config/contracts" \
        "${dir}/src/user/docket/config/fragments" \
        "${dir}/.docket/bin"
    git -C "$dir" init -q -b main
    git -C "$dir" config user.email test@test
    git -C "$dir" config user.name test
    cp "$GATE" "${dir}/.docket/bin/frozen-drift-check"
    chmod +x "${dir}/.docket/bin/frozen-drift-check"
    cat > "${dir}/src/user/docket/config/contracts/sample.md" <<'MD'
---
version: 2
---
Sample contract body.
MD
    git -C "$dir" add -A
    git -C "$dir" commit -q -m init
    git -C "$dir" checkout -q -b feature
}

# run_gate <dir>; runs the fixture's own copy of the gate with the engine
# phases skipped, printing combined stdout+stderr and returning its exit
# code.
run_gate() { # <dir>
    ( cd "$1" && FROZEN_DRIFT_CHECK_SKIP_ENGINE=1 bash .docket/bin/frozen-drift-check 2>&1 )
}

# ---- clean tree passes ------------------------------------------------
FIX="${WORK}/clean"
build_repo "$FIX"
if out=$(run_gate "$FIX"); then
    pass "clean tree: gate exits 0"
else
    fail "clean tree: expected exit 0, got $?"
    printf '%s\n' "$out" | sed 's/^/    /'
fi

# ---- unbumped body edit, committed, fails ------------------------------
FIX="${WORK}/unbumped-edit"
build_repo "$FIX"
cat > "${FIX}/src/user/docket/config/contracts/sample.md" <<'MD'
---
version: 2
---
Sample contract body EDITED.
MD
git -C "$FIX" commit -qam "edit body without bump"
if out=$(run_gate "$FIX"); then
    fail "unbumped body edit: expected non-zero exit, gate passed"
else
    if printf '%s\n' "$out" | grep -q "body changed but the version is not above"; then
        pass "unbumped body edit: gate fails with DRIFT"
    else
        fail "unbumped body edit: gate failed but not with the expected DRIFT message"
        printf '%s\n' "$out" | sed 's/^/    /'
    fi
fi

# ---- bumped body edit, committed, passes -------------------------------
FIX="${WORK}/bumped-edit"
build_repo "$FIX"
cat > "${FIX}/src/user/docket/config/contracts/sample.md" <<'MD'
---
version: 3
---
Sample contract body EDITED, bumped.
MD
git -C "$FIX" commit -qam "edit body with bump"
if out=$(run_gate "$FIX"); then
    pass "bumped body edit: gate exits 0"
else
    fail "bumped body edit: expected exit 0, got non-zero"
    printf '%s\n' "$out" | sed 's/^/    /'
fi

# ---- bump without a body edit fails ------------------------------------
FIX="${WORK}/bump-without-edit"
build_repo "$FIX"
cat > "${FIX}/src/user/docket/config/contracts/sample.md" <<'MD'
---
version: 3
---
Sample contract body.
MD
git -C "$FIX" commit -qam "bump version, no body change"
if out=$(run_gate "$FIX"); then
    fail "bump without edit: expected non-zero exit, gate passed"
else
    if printf '%s\n' "$out" | grep -q "version changed but the body is identical"; then
        pass "bump without edit: gate fails with DRIFT"
    else
        fail "bump without edit: gate failed but not with the expected DRIFT message"
        printf '%s\n' "$out" | sed 's/^/    /'
    fi
fi

# ---- a new contract file (absent from the merge-base) is skipped -------
FIX="${WORK}/new-file"
build_repo "$FIX"
cat > "${FIX}/src/user/docket/config/contracts/brand-new.md" <<'MD'
---
version: 1
---
Brand new contract, no prior version to compare against.
MD
git -C "$FIX" add -A
git -C "$FIX" commit -qm "add new contract"
if out=$(run_gate "$FIX"); then
    if printf '%s\n' "$out" | grep -q "brand-new.md"; then
        fail "new file: gate exited 0 but mentioned the new file unexpectedly"
        printf '%s\n' "$out" | sed 's/^/    /'
    else
        pass "new file: gate exits 0 and does not compare it"
    fi
else
    fail "new file: expected exit 0, got non-zero"
    printf '%s\n' "$out" | sed 's/^/    /'
fi

echo
if [ "$FAIL" -gt 0 ]; then
    echo "frozen-drift-check.test.sh: FAIL (${PASS} passed, ${FAIL} failed)"
    exit 1
fi
echo "frozen-drift-check.test.sh: PASS (${PASS} cases)"
