#!/bin/bash

# The justfile `tests` recipe runs the tests/*.test.sh suites concurrently.
# Running them one after another took over two minutes alone and past the
# tests gate's five-minute timeout when several writers ran it at once, so the
# recipe now fans the suites out under a bounded job count. This suite runs the
# recipe BODY, extracted from the justfile, inside a fixture directory holding
# stub suites and a stub `cargo`, and asserts what the parallel loop must
# still do: run every suite after one fails, exit non-zero when any fails,
# print `FAILED: <suite>` for each failure, and never exceed the job bound.
#
# JUSTFILE overrides the recipe source, so a mutation probe can point the
# suite at a deliberately-broken COPY under $TMPDIR without touching the
# checkout.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
JUSTFILE="${JUSTFILE:-${SCRIPT_DIR}/../justfile}"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/justfile-tests-parallel.XXXXXX") || exit 2
trap 'rm -rf "$WORK"' EXIT

# The recipe body, dedented, without its shebang line: the lines from the
# `tests:` header to the next non-indented line, as just itself reads a body.
awk '
    /^tests:/ { in_recipe = 1; next }
    in_recipe && /^[^[:space:]]/ { exit }
    in_recipe { sub(/^    /, ""); print }
' "$JUSTFILE" | sed '1{/^#!/d;}' > "${WORK}/body.sh"

if [ ! -s "${WORK}/body.sh" ]; then
    echo "justfile-tests-parallel: FAIL — no tests recipe body in ${JUSTFILE}" >&2
    exit 1
fi

# `cargo` is stubbed so the body's cargo step passes without building.
mkdir -p "${WORK}/bin"
printf '#!/bin/sh\nexit 0\n' > "${WORK}/bin/cargo"
chmod +x "${WORK}/bin/cargo"

fail=0

# A fixture directory holding the given stub suites, each `name:exit-code`.
# Every stub records that it ran, then holds a lock directory for a moment so
# the number alive at once can be read back.
make_fixture() { # <dir> <name:code>...
    local dir="$1" spec name code
    shift
    mkdir -p "${dir}/tests" "${dir}/locks"
    : > "${dir}/ran"
    : > "${dir}/concurrency"
    for spec in "$@"; do
        name="${spec%%:*}"
        code="${spec##*:}"
        cat > "${dir}/tests/${name}.test.sh" <<STUB
#!/bin/bash
echo "${name}" >> "${dir}/ran"
mkdir "${dir}/locks/${name}"
ls "${dir}/locks" | wc -l | tr -d ' ' >> "${dir}/concurrency"
sleep 0.3
rmdir "${dir}/locks/${name}"
echo "stub ${name} exiting ${code}"
exit ${code}
STUB
    done
}

# Run the recipe body in a fixture, leaving combined output in <dir>/out and
# the exit status in <dir>/status.
run_body() { # <dir> [<jobs>]
    local dir="$1" jobs="${2:-}"
    (
        cd "$dir" || exit 2
        PATH="${WORK}/bin:${PATH}" TESTS_JOBS="$jobs" bash "${WORK}/body.sh"
    ) > "${dir}/out" 2>&1
    echo $? > "${dir}/status"
}

check() { # <label> <condition-status>
    if [ "$2" -eq 0 ]; then
        echo "ok   $1"
    else
        echo "FAIL $1"
        fail=1
    fi
}

# One passing and two failing suites: exit 1, a FAILED line for each failing
# suite and none for the passing one, and every suite ran.
F1="${WORK}/mixed"
make_fixture "$F1" alpha:0 beta:1 gamma:3
run_body "$F1"
[ "$(cat "${F1}/status")" = 1 ]
check "mixed fixture exits 1" $?
grep -qx 'FAILED: tests/beta.test.sh' "${F1}/out"
check "names the first failing suite" $?
grep -qx 'FAILED: tests/gamma.test.sh' "${F1}/out"
check "names the second failing suite" $?
! grep -q 'FAILED: tests/alpha.test.sh' "${F1}/out"
check "does not name the passing suite" $?
[ "$(sort "${F1}/ran" | tr '\n' ' ')" = 'alpha beta gamma ' ]
check "every suite ran after a failure" $?
grep -q 'stub alpha exiting 0' "${F1}/out" && grep -q 'stub gamma exiting 3' "${F1}/out"
check "suite output is replayed" $?

# The last suite failing alone must still be reported, and an earlier failure
# must not hide behind it: each job is waited on, not only the final one.
F2="${WORK}/last-fails"
make_fixture "$F2" alpha:1 beta:0 gamma:1
run_body "$F2"
[ "$(grep -c '^FAILED: ' "${F2}/out")" = 2 ]
check "reports both failures when the last suite also fails" $?

F3="${WORK}/first-fails"
make_fixture "$F3" alpha:1 beta:0 gamma:0
run_body "$F3"
[ "$(cat "${F3}/status")" = 1 ] && grep -qx 'FAILED: tests/alpha.test.sh' "${F3}/out"
check "reports a failure in a job that is not the last" $?

# All suites passing: exit 0 and no FAILED line.
F4="${WORK}/all-pass"
make_fixture "$F4" alpha:0 beta:0 gamma:0
run_body "$F4"
[ "$(cat "${F4}/status")" = 0 ] && ! grep -q '^FAILED: ' "${F4}/out"
check "all-passing fixture exits 0 with no FAILED line" $?

# The job count is a bound, and the suites really do overlap under it.
F5="${WORK}/bounded"
make_fixture "$F5" a:0 b:0 c:0 d:0 e:0 f:0
run_body "$F5" 2
[ "$(sort -n "${F5}/concurrency" | tail -n1)" = 2 ]
check "TESTS_JOBS=2 runs two suites at once and no more" $?
[ "$(sort "${F5}/ran" | wc -l | tr -d ' ')" = 6 ]
check "every suite ran under a bound of 2" $?

if [ "$fail" -ne 0 ]; then
    echo "justfile-tests-parallel: FAIL" >&2
    exit 1
fi

echo "justfile-tests-parallel: PASS"
