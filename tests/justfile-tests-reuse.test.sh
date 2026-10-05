#!/bin/bash

# The justfile `tests` recipe lets the engine's record-time `tests` gate reuse
# a full pass on the identical clean tree instead of running every suite a
# second time. This suite runs the recipe BODY, extracted from the justfile,
# inside a throwaway git repository holding a stub suite and a stub `cargo`,
# and asserts when a pass is stamped and when a stamp is reused: only a gate
# run (DOCKET_GATE set) reuses, only a stamp for the current clean tree counts,
# a stale or unreadable stamp does not, TESTS_NO_REUSE=1 forces a run, and a
# failing run or a dirtied tree stamps nothing.
#
# JUSTFILE overrides the recipe source, so a mutation probe can point the
# suite at a deliberately-broken COPY under $TMPDIR without touching the
# checkout.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
JUSTFILE="${JUSTFILE:-${SCRIPT_DIR}/../justfile}"

# This suite itself runs under the tests gate, whose environment sets
# DOCKET_GATE; every case below chooses its own.
unset DOCKET_GATE TESTS_NO_REUSE TESTS_REUSE_MAX_AGE

WORK=$(mktemp -d "${TMPDIR:-/tmp}/justfile-tests-reuse.XXXXXX") || exit 2
trap 'rm -rf "$WORK"' EXIT

# The recipe body, dedented, without its shebang line: the lines from the
# `tests:` header to the next non-indented line, as just itself reads a body.
awk '
    /^tests:/ { in_recipe = 1; next }
    in_recipe && /^[^[:space:]]/ { exit }
    in_recipe { sub(/^    /, ""); print }
' "$JUSTFILE" | sed '1{/^#!/d;}' > "${WORK}/body.sh"

if [ ! -s "${WORK}/body.sh" ]; then
    echo "justfile-tests-reuse: FAIL — no tests recipe body in ${JUSTFILE}" >&2
    exit 1
fi

# `cargo` is stubbed so the body's cargo step passes without building.
mkdir -p "${WORK}/bin"
printf '#!/bin/sh\nexit 0\n' > "${WORK}/bin/cargo"
chmod +x "${WORK}/bin/cargo"

REPO="${WORK}/repo"
RAN="${WORK}/ran"

g() { # git in the fixture, its commits off the operator's identity and signing agent
    git -C "$REPO" -c user.name=reuse-test -c user.email=reuse-test@example.invalid \
        -c commit.gpgsign=false "$@"
}

# The stub suite records each run outside the repository, so running it leaves
# the tree clean. It exits with the code in suite-exit, and dirties the tree
# when the dirty flag exists.
mkdir -p "${REPO}/tests"
git init -q "$REPO"
cat > "${REPO}/tests/stub.test.sh" <<STUB
#!/bin/bash
echo ran >> "${RAN}"
[ -e "${WORK}/dirty" ] && : > "${REPO}/left-behind.txt"
exit "\$(cat "${WORK}/suite-exit" 2>/dev/null || echo 0)"
STUB
g add -A
g commit -q -m fixture

STAMPS="$(cd "$REPO" && git rev-parse --absolute-git-dir)/tests-pass"
tree() { g rev-parse 'HEAD^{tree}'; }

# Run the recipe body in the fixture with the given VAR=value assignments,
# leaving combined output in out, the exit status in status, and how many
# times the stub suite ran in runs.
run_body() { # [VAR=value]...
    : > "$RAN"
    (
        cd "$REPO" || exit 2
        env PATH="${WORK}/bin:${PATH}" "$@" bash "${WORK}/body.sh"
    ) > "${WORK}/out" 2>&1
    echo $? > "${WORK}/status"
    wc -l < "$RAN" | tr -d ' ' > "${WORK}/runs"
}

fail=0
check() { # <label> <condition-status>
    if [ "$2" -eq 0 ]; then
        echo "ok   $1"
    else
        echo "FAIL $1"
        fail=1
    fi
}

# A full pass on a clean tree runs the suite and stamps HEAD's tree with the
# time and commit.
run_body
[ "$(cat "${WORK}/status")" = 0 ] && [ "$(cat "${WORK}/runs")" = 1 ]
check "a clean full pass runs the suite" $?
[ -f "${STAMPS}/$(tree)" ]
check "a clean full pass stamps HEAD's tree" $?
read -r at commit < "${STAMPS}/$(tree)"
[ "$commit" = "$(g rev-parse HEAD)" ] && [ $(( $(date +%s) - at )) -lt 60 ]
check "the stamp records the commit and the time" $?

# The gate on the same clean tree reuses the pass and names what it reused.
run_body DOCKET_GATE=tests
[ "$(cat "${WORK}/status")" = 0 ] && [ "$(cat "${WORK}/runs")" = 0 ]
check "a gate run on the stamped tree reuses the pass" $?
grep -q "REUSED the full pass of tree $(tree)" "${WORK}/out"
check "a reused pass names the tree in the gate output" $?

# Only the gate reuses: executor, judge and CI runs always run the suites.
run_body
[ "$(cat "${WORK}/runs")" = 1 ]
check "a run without DOCKET_GATE ignores the stamp" $?

run_body DOCKET_GATE=tests TESTS_NO_REUSE=1
[ "$(cat "${WORK}/runs")" = 1 ]
check "TESTS_NO_REUSE=1 forces a gate run" $?

# A stamp older than TESTS_REUSE_MAX_AGE, or one that does not hold a time,
# is run past rather than trusted or tripped over.
printf '1 %s\n' "$(g rev-parse HEAD)" > "${STAMPS}/$(tree)"
run_body DOCKET_GATE=tests
[ "$(cat "${WORK}/status")" = 0 ] && [ "$(cat "${WORK}/runs")" = 1 ]
check "a stale stamp is not reused" $?
printf 'not-a-time\n' > "${STAMPS}/$(tree)"
run_body DOCKET_GATE=tests
[ "$(cat "${WORK}/status")" = 0 ] && [ "$(cat "${WORK}/runs")" = 1 ]
check "an unreadable stamp is not reused and does not fail the run" $?

# Uncommitted work is not the tree that was stamped: no reuse, no stamp.
rm -rf "$STAMPS"
: > "${REPO}/untracked.txt"
run_body
[ ! -e "$STAMPS" ]
check "a pass on a dirty tree stamps nothing" $?
mkdir -p "$STAMPS"
printf '%s %s\n' "$(date +%s)" "$(g rev-parse HEAD)" > "${STAMPS}/$(tree)"
run_body DOCKET_GATE=tests
[ "$(cat "${WORK}/runs")" = 1 ]
check "a gate run on a dirty tree ignores the stamp" $?
rm -f "${REPO}/untracked.txt"

# A new commit is a new tree: the old stamp does not cover it, and the next
# pass replaces it.
run_body
old_tree=$(tree)
echo change > "${REPO}/README"
g add README
g commit -q -m change
run_body DOCKET_GATE=tests
[ "$(cat "${WORK}/runs")" = 1 ]
check "a stamp for an earlier tree is not reused" $?
[ -f "${STAMPS}/$(tree)" ] && [ ! -e "${STAMPS}/${old_tree}" ]
check "the next pass replaces the earlier stamp" $?

# A failing run stamps nothing, so the gate after it runs and fails too.
rm -rf "$STAMPS"
echo 1 > "${WORK}/suite-exit"
run_body
[ "$(cat "${WORK}/status")" = 1 ] && [ ! -e "$STAMPS" ]
check "a failing run stamps nothing" $?
run_body DOCKET_GATE=tests
[ "$(cat "${WORK}/status")" = 1 ] && [ "$(cat "${WORK}/runs")" = 1 ]
check "the gate after a failing run runs and fails" $?
rm -f "${WORK}/suite-exit"

# A suite that leaves the tree dirty voids the stamp.
rm -rf "$STAMPS"
: > "${WORK}/dirty"
run_body
[ "$(cat "${WORK}/status")" = 0 ] && [ ! -e "$STAMPS" ]
check "a run that dirties the tree stamps nothing" $?
rm -f "${WORK}/dirty" "${REPO}/left-behind.txt"

if [ "$fail" -ne 0 ]; then
    echo "justfile-tests-reuse: FAIL" >&2
    exit 1
fi

echo "justfile-tests-reuse: PASS"
