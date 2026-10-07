#!/bin/bash

# The justfile `tests` recipe lets the engine's record-time `tests` gate reuse
# a full pass on the identical clean tree instead of running every suite a
# second time. This suite runs the recipe BODY, extracted from the justfile,
# inside a throwaway git repository holding a stub suite and a stub `cargo`,
# and asserts when a pass is stamped and when a stamp is reused: only the
# `tests` gate (DOCKET_GATE=tests) reuses, only a stamp for the current clean
# tree counts,
# a stale or unreadable stamp does not, TESTS_NO_REUSE=1 forces a run, and a
# failing run or a dirtied tree stamps nothing.
#
# The `sdet-abuse` recipe reuses that stamp only as its own record-time gate
# (DOCKET_GATE=sdet-abuse): it then runs .docket/bin/sdet-abuse in skip-suites
# mode, so the hook classification and registration checks still run and
# decide the result. Every other condition runs the hook suites, and no run
# changes the stamp directory.
#
# JUSTFILE overrides the recipe source, so a mutation probe can point the
# suite at a deliberately-broken COPY under $TMPDIR without touching the
# checkout.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
JUSTFILE="${JUSTFILE:-${SCRIPT_DIR}/../justfile}"

# This suite itself runs under the tests gate, whose environment sets
# DOCKET_GATE; every case below chooses its own.
unset DOCKET_GATE TESTS_NO_REUSE TESTS_REUSE_MAX_AGE SDET_ABUSE_SKIP_SUITES

WORK=$(mktemp -d "${TMPDIR:-/tmp}/justfile-tests-reuse.XXXXXX") || exit 2
trap 'rm -rf "$WORK"' EXIT

# A recipe body, dedented, without its shebang line: the lines from the
# `<recipe>:` header to the next non-indented line, as just itself reads a body.
extract_body() { # <recipe> <out>
    awk -v header="$1:" '
        $0 == header { in_recipe = 1; next }
        in_recipe && /^[^[:space:]]/ { exit }
        in_recipe { sub(/^    /, ""); print }
    ' "$JUSTFILE" | sed '1{/^#!/d;}' > "$2"
    if [ ! -s "$2" ]; then
        echo "justfile-tests-reuse: FAIL — no $1 recipe body in ${JUSTFILE}" >&2
        exit 1
    fi
}
extract_body tests "${WORK}/body.sh"
extract_body sdet-abuse "${WORK}/sdet-body.sh"

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

run_body DOCKET_GATE=ac-commands
[ "$(cat "${WORK}/runs")" = 1 ]
check "another gate running the recipe ignores the stamp" $?

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

# ---- sdet-abuse: the record-time gate reuses the tests stamp for its suites --
# A second fixture repository holds the real gate script, committed, so the
# tree is clean and the `tests` stamp keys on it. The hooks, the
# claude_code.rs stand-in, the registry and the hook suite live outside the
# repository and reach the gate through its SDET_ABUSE_* knobs, so adding an
# unclassified hook leaves the tree clean. The hook suite records each run in
# SRAN, outside the repository.
GATE_SRC="${SDET_ABUSE_SRC:-${SCRIPT_DIR}/../.docket/bin/sdet-abuse}"
SREPO="${WORK}/srepo"
SFIX="${WORK}/sfix"
SRAN="${WORK}/sran"
mkdir -p "${SREPO}/.docket/bin" "${SREPO}/tests" "${SFIX}/hooks" "${SFIX}/tests"
git init -q "$SREPO"
cp "$GATE_SRC" "${SREPO}/.docket/bin/sdet-abuse"
printf '#!/bin/bash\nexit 0\n' > "${SREPO}/tests/stub.test.sh"
printf '#!/bin/bash\nexit 2\n' > "${SFIX}/hooks/enforcing.sh"
printf '#!/bin/bash\necho observed\n' > "${SFIX}/hooks/advisory.sh"
cat > "${SFIX}/claude_code.rs" <<'RS'
fn build() {
    let settings_builder = settings_builder
        .with_hook(
            "PreToolUse",
            Some("Bash"),
            "bash ~/.claude/hooks/enforcing.sh",
            "command",
        );
}
RS
cat > "${SFIX}/registry.sh" <<'REG'
ENFORCING=(enforcing.sh)
ADVISORY=(advisory.sh)
UNWIRED=()
KNOWN_UNVERIFIED=()
REG
cat > "${SFIX}/tests/enforcing.test.sh" <<SUITE
#!/bin/bash
echo ran >> "${SRAN}"
for i in \$(seq 1 10); do echo "PASS case \$i"; done
SUITE
sg() { # git in the sdet-abuse fixture
    git -C "$SREPO" -c user.name=reuse-test -c user.email=reuse-test@example.invalid \
        -c commit.gpgsign=false "$@"
}
sg add -A
sg commit -q -m fixture
SSTAMPS="$(cd "$SREPO" && git rev-parse --absolute-git-dir)/tests-pass"
stree() { sg rev-parse 'HEAD^{tree}'; }

# Run the sdet-abuse recipe body in the fixture with the given VAR=value
# assignments, leaving combined output in sout, the exit status in sstatus,
# and how many times the hook suite ran in sruns.
run_sdet() { # [VAR=value]...
    : > "$SRAN"
    (
        cd "$SREPO" || exit 2
        env SDET_ABUSE_HOOKS_DIR="${SFIX}/hooks" \
            SDET_ABUSE_REGISTRATION="${SFIX}/claude_code.rs" \
            SDET_ABUSE_SUITES_DIR="${SFIX}/tests" \
            SDET_ABUSE_REGISTRY="${SFIX}/registry.sh" \
            "$@" bash "${WORK}/sdet-body.sh"
    ) > "${WORK}/sout" 2>&1
    echo $? > "${WORK}/sstatus"
    wc -l < "$SRAN" | tr -d ' ' > "${WORK}/sruns"
}
sran_full() { [ "$(cat "${WORK}/sstatus")" = 0 ] && [ "$(cat "${WORK}/sruns")" = 1 ]; }
# Every stamp file's name and contents, to show a run left them as they were.
snapshot() { # <out>
    find "$SSTAMPS" -type f | LC_ALL=C sort | while read -r f; do
        printf '%s\n' "$f"
        cat "$f"
    done > "$1"
}
# A fresh stamp a few seconds old, so a rewrite by the recipe changes it.
seed_stamp() { # [age-seconds]
    mkdir -p "$SSTAMPS"
    printf '%s %s\n' "$(( $(date +%s) - ${1:-5} ))" "$(sg rev-parse HEAD)" > "${SSTAMPS}/$(stree)"
}

# The stamp the gate reuses is the one a full `tests` pass writes.
(cd "$SREPO" && env PATH="${WORK}/bin:${PATH}" bash "${WORK}/body.sh") > /dev/null 2>&1
[ -f "${SSTAMPS}/$(stree)" ]
check "sdet-abuse fixture: a full tests pass stamps its tree" $?

# Reuse: the record-time gate on the stamped clean tree skips the suites,
# names the tree, still classifies, and leaves the stamps as they were.
seed_stamp
snapshot "${WORK}/snap-before"
run_sdet DOCKET_GATE=sdet-abuse
[ "$(cat "${WORK}/sstatus")" = 0 ] && [ "$(cat "${WORK}/sruns")" = 0 ]
check "sdet-abuse gate on a stamped clean tree exits 0 and runs no suite" $?
grep -q "$(stree)" "${WORK}/sout" && grep -qi 'reus' "${WORK}/sout"
check "sdet-abuse gate reuse names the reused tree" $?
grep -q 'enforcing.sh .*ENFORCING  suite' "${WORK}/sout" && grep -q 'advisory.sh .*ADVISORY   no deny path' "${WORK}/sout"
check "sdet-abuse gate reuse still prints the classification lines" $?
snapshot "${WORK}/snap-after"
cmp -s "${WORK}/snap-before" "${WORK}/snap-after"
check "sdet-abuse gate reuse leaves the stamp directory unchanged" $?

# On the reuse path a classification failure still fails the gate.
printf '#!/bin/bash\necho unclassified\n' > "${SFIX}/hooks/mystery.sh"
run_sdet DOCKET_GATE=sdet-abuse
[ "$(cat "${WORK}/sstatus")" != 0 ] && [ "$(cat "${WORK}/sruns")" = 0 ] \
    && grep -q 'mystery.sh is not classified' "${WORK}/sout"
check "sdet-abuse gate reuse with an unclassified hook exits non-zero and names it" $?
rm -f "${SFIX}/hooks/mystery.sh"

# Every other condition runs the suites in full.
seed_stamp
snapshot "${WORK}/snap-before"
run_sdet
sran_full
check "sdet-abuse without DOCKET_GATE runs the suites" $?
snapshot "${WORK}/snap-after"
cmp -s "${WORK}/snap-before" "${WORK}/snap-after"
check "sdet-abuse without DOCKET_GATE leaves the stamp directory unchanged" $?

run_sdet DOCKET_GATE=tests
sran_full
check "sdet-abuse under another gate runs the suites" $?

run_sdet DOCKET_GATE=sdet-abuse TESTS_NO_REUSE=1
sran_full
check "sdet-abuse gate with TESTS_NO_REUSE=1 runs the suites" $?

run_sdet SDET_ABUSE_SKIP_SUITES=1
sran_full
check "sdet-abuse ignores a caller's SDET_ABUSE_SKIP_SUITES off the reuse path" $?

: > "${SREPO}/untracked.txt"
run_sdet DOCKET_GATE=sdet-abuse
sran_full
check "sdet-abuse gate on a dirty tree runs the suites" $?
rm -f "${SREPO}/untracked.txt"

rm -f "${SSTAMPS}/$(stree)"
run_sdet DOCKET_GATE=sdet-abuse
sran_full
check "sdet-abuse gate with no stamp runs the suites" $?

seed_stamp 100000
run_sdet DOCKET_GATE=sdet-abuse
sran_full
check "sdet-abuse gate with a stale stamp runs the suites" $?

printf 'not-a-time\n' > "${SSTAMPS}/$(stree)"
run_sdet DOCKET_GATE=sdet-abuse
sran_full
check "sdet-abuse gate with an unreadable stamp runs the suites" $?

if [ "$fail" -ne 0 ]; then
    echo "justfile-tests-reuse: FAIL" >&2
    exit 1
fi

echo "justfile-tests-reuse: PASS"
