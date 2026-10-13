#!/bin/bash

# Behavior suite for .docket/bin/frozen-drift-check. Most cases drive the
# contracts/fragments comparison — the half of the gate that needs only git,
# run through FROZEN_DRIFT_CHECK_SKIP_ENGINE=1 to skip the schema/workflow
# phases, which need a live docket engine and its registry. The schema-phase
# cases at the end put a stub `docket` first on PATH instead.
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

# ---- schema phase: a stub `docket` first on PATH ------------------------
# The engine phases read their records from `docket ... list` calls. The stub
# answers `schema list` with <deprecated.json> only when --deprecated is
# passed and with an empty ok listing otherwise, so a gate that omits the
# flag never sees the retired record. `workflow list` answers with
# <workflow-records> (a JSON array, default empty) the way the engine pages:
# `.data.total` is always the full count, but the rows are cut to the first
# one unless `--limit 0` is passed, a one-row stand-in for the engine's
# default --limit 50. Any other call fails loudly.

# build_stub_docket <stubdir> <schema-listing-with-deprecated> <schema-listing-without> [<workflow-records>]
build_stub_docket() {
    local stub="$1"
    mkdir -p "${stub}/bin"
    printf '%s\n' "$2" > "${stub}/schemas-deprecated.json"
    printf '%s\n' "$3" > "${stub}/schemas-current.json"
    printf '%s\n' "${4:-[]}" > "${stub}/workflows.json"
    cat > "${stub}/bin/docket" <<'STUB'
#!/bin/bash
stub_dir=$(cd "$(dirname "$0")/.." && pwd)
case "$1 $2" in
    "schema list")
        for arg in "$@"; do
            if [ "$arg" = "--deprecated" ]; then
                cat "${stub_dir}/schemas-deprecated.json"
                exit 0
            fi
        done
        cat "${stub_dir}/schemas-current.json"
        ;;
    "workflow list")
        cap=1
        prev=
        for arg in "$@"; do
            if [ "$prev" = "--limit" ]; then
                cap="$arg"
            fi
            prev="$arg"
        done
        jq -c --argjson cap "$cap" \
            '{ok:true,data:{total:length,workflows:(if $cap == 0 then . else .[:$cap] end)}}' \
            "${stub_dir}/workflows.json"
        ;;
    *)
        echo "stub docket: unsupported call: $*" >&2
        exit 64
        ;;
esac
STUB
    chmod +x "${stub}/bin/docket"
}

# run_gate_with_engine <dir> <stubdir> <stderr-file>; runs the fixture's gate
# with the engine phases enabled against the stub, printing stdout and
# leaving stderr in <stderr-file>.
run_gate_with_engine() {
    ( cd "$1" && PATH="$2/bin:$PATH" bash .docket/bin/frozen-drift-check 2>"$3" )
}

# ---- a retired schema version whose file drifted fails -----------------
FIX="${WORK}/retired-schema-drift"
STUB="${WORK}/retired-schema-drift-stub"
build_repo "$FIX"
mkdir -p "$STUB"
printf '{"retired": "edited after registration"}\n' > "${STUB}/retired@1.json"
registered_sha=$(printf 'bytes as registered\n' | shasum -a 256 | cut -d' ' -f1)
retired_listing=$(jq -nc --arg sha "$registered_sha" --arg path "${STUB}/retired@1.json" \
    '{ok:true,data:{schemas:[{name:"retired",version:1,source_sha256:$sha,source_path:$path}]}}')
build_stub_docket "$STUB" "$retired_listing" '{"ok":true,"data":{"schemas":[]}}'
if out=$(run_gate_with_engine "$FIX" "$STUB" "${STUB}/stderr"); then
    fail "retired schema drift: expected non-zero exit, gate passed"
    printf '%s\n' "$out" | sed 's/^/    /'
elif grep -q "DRIFT schema retired@1" "${STUB}/stderr"; then
    pass "retired schema drift: gate fails with DRIFT schema retired@1"
else
    fail "retired schema drift: gate failed but did not report DRIFT schema retired@1"
    printf '%s\n' "$out" | sed 's/^/    /'
    sed 's/^/    /' "${STUB}/stderr"
fi

# ---- a schema listing that is not ok:true is an environment failure ----
FIX="${WORK}/schema-listing-not-ok"
STUB="${WORK}/schema-listing-not-ok-stub"
build_repo "$FIX"
build_stub_docket "$STUB" '{"ok":false}' '{"ok":false}'
run_gate_with_engine "$FIX" "$STUB" "${STUB}/stderr" >/dev/null
status=$?
if [ "$status" -ne 2 ]; then
    fail "schema listing not ok: expected exit 2, got ${status}"
    sed 's/^/    /' "${STUB}/stderr"
elif grep -qF "docket schema list --deprecated --limit 0 --json" "${STUB}/stderr"; then
    pass "schema listing not ok: gate exits 2 naming the --deprecated listing"
else
    fail "schema listing not ok: exit 2 but stderr does not name 'docket schema list --deprecated --limit 0 --json'"
    sed 's/^/    /' "${STUB}/stderr"
fi

# ---- a workflow's newest version past the listing's default cap -------
# The listing reports total 2 but its capped page holds only paged@1. The
# file declares v2 with bytes that differ from paged@2's registration, so it
# is drift against paged@2. A gate that reads only the capped page compares
# against paged@1, sees "declares v2 > registered v1", and passes silently.
FIX="${WORK}/workflow-listing-capped"
STUB="${WORK}/workflow-listing-capped-stub"
build_repo "$FIX"
mkdir -p "$STUB"
printf '[pipeline]\nversion = 2\n# edited in place after v2 registered\n' > "${STUB}/paged.toml"
v1_sha=$(printf '[pipeline]\nversion = 1\n' | shasum -a 256 | cut -d' ' -f1)
v2_sha=$(printf '[pipeline]\nversion = 2\n' | shasum -a 256 | cut -d' ' -f1)
paged_records=$(jq -nc --arg v1 "$v1_sha" --arg v2 "$v2_sha" --arg path "${STUB}/paged.toml" \
    '[{name:"paged",version:1,source_sha256:$v1,source_path:$path},
      {name:"paged",version:2,source_sha256:$v2,source_path:$path}]')
build_stub_docket "$STUB" '{"ok":true,"data":{"schemas":[]}}' '{"ok":true,"data":{"schemas":[]}}' "$paged_records"
run_gate_with_engine "$FIX" "$STUB" "${STUB}/stderr" >"${STUB}/stdout"
status=$?
if [ "$status" -eq 1 ] && grep -q "DRIFT workflow paged@2" "${STUB}/stderr"; then
    pass "capped workflow listing: gate compares paged@2 and reports its DRIFT"
elif [ "$status" -eq 2 ] && grep -qF "docket workflow list" "${STUB}/stderr"; then
    pass "capped workflow listing: gate refuses the truncated listing with exit 2"
else
    fail "capped workflow listing: expected DRIFT workflow paged@2 or exit 2, got exit ${status}"
    sed 's/^/    /' "${STUB}/stdout" "${STUB}/stderr"
fi

echo
if [ "$FAIL" -gt 0 ]; then
    echo "frozen-drift-check.test.sh: FAIL (${PASS} passed, ${FAIL} failed)"
    exit 1
fi
echo "frozen-drift-check.test.sh: PASS (${PASS} cases)"
