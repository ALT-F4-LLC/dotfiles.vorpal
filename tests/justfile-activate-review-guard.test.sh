#!/bin/bash

# `just activate` installs this checkout's hooks for every session on the
# machine. A paused or waiting-human run passes `docket guard stop`, yet a
# write step it already integrated into main can still be under review, so
# the recipe also refuses while any step on such an issue is unfinished. This
# suite runs the recipe BODY, extracted from the justfile with `{{force}}`
# substituted as just would, against a stub `docket` answering from fixture
# JSON and a stub `vorpal` whose vorpal-activate leaves a marker file. CI has
# no `just`, so the body is run with bash directly.
#
# JUSTFILE overrides the recipe source, so a mutation probe can point the
# suite at a deliberately-broken COPY under $TMPDIR without touching the
# checkout.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
JUSTFILE="${JUSTFILE:-${SCRIPT_DIR}/../justfile}"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/justfile-activate-review-guard.XXXXXX") || exit 2
trap 'rm -rf "$WORK"' EXIT

# The recipe body, dedented, without its shebang line: the lines from the
# `activate` header to the next non-indented line, as just itself reads a body.
awk '
    /^activate / { in_recipe = 1; next }
    in_recipe && /^[^[:space:]]/ { exit }
    in_recipe { sub(/^    /, ""); print }
' "$JUSTFILE" | sed '1{/^#!/d;}' > "${WORK}/body.sh"

if [ ! -s "${WORK}/body.sh" ]; then
    echo "justfile-activate-review-guard: FAIL — no activate recipe body in ${JUSTFILE}" >&2
    exit 1
fi

BIN="${WORK}/bin"
FIX="${WORK}/fixtures"
MARKER="${WORK}/vorpal-activate-ran"
mkdir -p "$BIN" "$FIX" "${WORK}/store/bin"

# The stub docket admits `guard stop` (the run is paused) and answers the
# three reads from the fixture files the current case wrote. Any other call,
# or a read with no fixture, fails, so an unexpected call is never mistaken
# for an empty answer. Every call is logged to CALLS, one per line, so a case
# can assert that a read was never reached.
CALLS="${WORK}/calls.log"
cat > "${BIN}/docket" <<STUB
#!/bin/bash
echo "\$*" >> "${CALLS}"
case "\$1 \$2" in
    "guard stop") exit 0 ;;
    "run status") exec cat "${FIX}/runs.json" ;;
    "step list")
        [ "\$3" = --run ] || exit 1
        f="${FIX}/steps-\$4.json"
        [ -f "\$f" ] || { echo "stub docket: no step list for \$4" >&2; exit 1; }
        exec cat "\$f" ;;
    "step show")
        f="${FIX}/show-\$3.json"
        [ -f "\$f" ] || { echo "stub docket: no step show for \$3" >&2; exit 1; }
        exec cat "\$f" ;;
esac
echo "stub docket: unexpected call: \$*" >&2
exit 1
STUB

# `vorpal build --path user` prints the built store path; its vorpal-activate
# leaves the marker that says the corpus was installed.
cat > "${BIN}/vorpal" <<STUB
#!/bin/sh
echo "${WORK}/store"
STUB
cat > "${WORK}/store/bin/vorpal-activate" <<STUB
#!/bin/sh
: > "${MARKER}"
STUB
# The drift report after activation is not under test.
printf '#!/bin/sh\nexit 0\n' > "${BIN}/python3"
chmod +x "${BIN}/docket" "${BIN}/vorpal" "${BIN}/python3" "${WORK}/store/bin/vorpal-activate"

SHA=4f1c2d9e8b7a6f5e4d3c2b1a0f9e8d7c6b5a4f3e

# Write the fixtures for one non-terminal run, RUN-7, whose issue DOT-1 has
# an integrated implement step, STEP-10, and a review step, STEP-11, in the
# given status. Issue DOT-2 has an implement step still in flight and nothing
# integrated, which on its own is no reason to refuse.
arrange() { # <STEP-11 status>
    rm -f "${FIX}"/*.json
    cat > "${FIX}/runs.json" <<'JSON'
{"ok":true,"data":{"runs":[{"run":"RUN-7","status":"paused"}],"total":1}}
JSON
    cat > "${FIX}/steps-RUN-7.json" <<JSON
{"ok":true,"data":{"steps":[
 {"run":"RUN-7","issue":"DOT-1","step":"STEP-9","instance":"threat-model@0","kind":"executor","attempt":1,"status":"done"},
 {"run":"RUN-7","issue":"DOT-1","step":"STEP-10","instance":"implement@0","kind":"executor","attempt":1,"status":"done"},
 {"run":"RUN-7","issue":"DOT-1","step":"STEP-11","instance":"review-correctness@0","kind":"executor","attempt":1,"status":"$1"},
 {"run":"RUN-7","issue":"DOT-2","step":"STEP-20","instance":"implement@0","kind":"executor","attempt":1,"status":"claimed"}
],"total":4}}
JSON
    cat > "${FIX}/show-STEP-9.json" <<'JSON'
{"ok":true,"data":{"step":"STEP-9","class":"threat-model","metadata":{}}}
JSON
    cat > "${FIX}/show-STEP-10.json" <<JSON
{"ok":true,"data":{"step":"STEP-10","class":"write","metadata":{"integrated_sha":"${SHA}","writer_sha":"0123456789abcdef0123456789abcdef01234567"}}}
JSON
    cat > "${FIX}/show-STEP-11.json" <<'JSON'
{"ok":true,"data":{"step":"STEP-11","class":"judge-correctness","metadata":{}}}
JSON
}

# Run the body with `{{force}}` set to the given value, leaving stderr in err,
# the exit status in status, and whether vorpal-activate ran in activated.
# CASE_PATH, when set, replaces the whole PATH the body runs under.
BASH_BIN=$(command -v bash)
activate() { # <force>
    rm -f "$MARKER" "$CALLS"
    sed "s/{{force}}/$1/g" "${WORK}/body.sh" > "${WORK}/run.sh"
    (cd "$WORK" && PATH="${CASE_PATH:-${BIN}:${PATH}}" "$BASH_BIN" "${WORK}/run.sh") > "${WORK}/out" 2> "${WORK}/err"
    echo $? > "${WORK}/status"
    if [ -e "$MARKER" ]; then echo yes; else echo no; fi > "${WORK}/activated"
}

fail=0
check() { # <label> <condition-status>
    if [ "$2" -eq 0 ]; then
        echo "ok   $1"
    else
        echo "FAIL $1"
        sed 's/^/     stderr: /' "${WORK}/err"
        fail=1
    fi
}

refused() {
    [ "$(cat "${WORK}/status")" != 0 ] && [ "$(cat "${WORK}/activated")" = no ]
}
admitted() {
    [ "$(cat "${WORK}/status")" = 0 ] && [ "$(cat "${WORK}/activated")" = yes ]
}

# (a) A paused run's integrated write commit with its review not yet done
# refuses activation, naming the step and the commit.
for review_status in pending ready waiting-human failed; do
    arrange "$review_status"
    activate ""
    refused
    check "a ${review_status} review on an integrated step refuses activation" $?
    grep -q 'STEP-10' "${WORK}/err" && grep -q "$SHA" "${WORK}/err"
    check "the ${review_status}-review refusal names STEP-10 and its sha" $?
done

# (b) With the review finished, nothing awaits review, so activation runs.
for review_status in done skipped superseded; do
    arrange "$review_status"
    activate ""
    admitted
    check "a ${review_status} review lets activation run" $?
done

# (b) No non-terminal run at all.
arrange done
printf '%s\n' '{"ok":true,"data":{"runs":[],"total":0}}' > "${FIX}/runs.json"
activate ""
admitted
check "no non-terminal run lets activation run" $?

# (c) force=1 overrides the refusal.
arrange ready
activate 1
admitted
check "force=1 activates despite a pending review" $?

# A read that fails, or a partial list, cannot establish that nothing awaits
# review.
arrange done
rm -f "${FIX}/steps-RUN-7.json"
activate ""
refused
check "a failed step list refuses activation" $?

arrange done
printf '%s\n' '{"ok":true,"data":{"runs":[{"run":"RUN-7","status":"paused"}],"total":2}}' > "${FIX}/runs.json"
activate ""
refused
check "a truncated run list refuses activation" $?

arrange ready
rm -f "${FIX}/show-STEP-10.json"
activate ""
refused
check "a failed step show refuses activation" $?

# The run-status and step-list envelopes are validated with the same
# fail-closed rules as docket-run-guard-hook.sh: a `runs` array, run ids
# matching ^RUN-[0-9]+$ with no duplicates, and step ids matching
# ^STEP-[0-9]+$. Anything else refuses before the next read is made.
called() { # <docket subcommand pair>
    [ -f "$CALLS" ] && grep -q "^$1" "$CALLS"
}
run_status_refused() {
    refused && grep -q '(run status)\.$' "${WORK}/err" && ! called 'step list'
}

arrange done
printf '%s\n' '{"ok":true,"data":{"total":0}}' > "${FIX}/runs.json"
activate ""
refused && grep -q 'cannot read docket state to check integrated commits awaiting review (run status)' "${WORK}/err"
check "a run status with no runs key refuses activation" $?

for bad_run in 'RUN-1 RUN-2' 'run-7'; do
    arrange done
    printf '{"ok":true,"data":{"runs":[{"run":"%s","status":"paused"}],"total":1}}\n' "$bad_run" > "${FIX}/runs.json"
    activate ""
    run_status_refused
    check "a malformed run id ('${bad_run}') refuses before any step list" $?
done

arrange done
printf '%s\n' '{"ok":true,"data":{"runs":[{"run":"RUN-7","status":"paused"},{"run":"RUN-7","status":"paused"}],"total":2}}' > "${FIX}/runs.json"
activate ""
run_status_refused
check "a duplicate run id refuses before any step list" $?

# A malformed step id in either position of a candidate pair: the done step
# (STEP-10 renamed) or the first unfinished step on its issue (STEP-11).
for case_ in 'STEP-10:STEP-1 x:done step' 'STEP-11:step-2:open step'; do
    IFS=: read -r good bad label <<< "$case_"
    arrange ready
    sed "s/\"step\":\"${good}\"/\"step\":\"${bad}\"/" "${FIX}/steps-RUN-7.json" > "${FIX}/steps.tmp"
    mv "${FIX}/steps.tmp" "${FIX}/steps-RUN-7.json"
    cp "${FIX}/show-STEP-10.json" "${FIX}/show-STEP-1.json"
    activate ""
    refused && grep -q '(step list RUN-7)\.$' "${WORK}/err" && ! called 'step show'
    check "a malformed ${label} id ('${bad}') refuses before any step show" $?
done

# A step list whose total disagrees with its steps is partial, even when every
# listed step is finished and nothing else would refuse.
arrange done
cat > "${FIX}/steps-RUN-7.json" <<'JSON'
{"ok":true,"data":{"steps":[
 {"run":"RUN-7","issue":"DOT-1","step":"STEP-9","instance":"threat-model@0","kind":"executor","attempt":1,"status":"done"},
 {"run":"RUN-7","issue":"DOT-1","step":"STEP-10","instance":"implement@0","kind":"executor","attempt":1,"status":"done"},
 {"run":"RUN-7","issue":"DOT-1","step":"STEP-11","instance":"review-correctness@0","kind":"executor","attempt":1,"status":"done"},
 {"run":"RUN-7","issue":"DOT-2","step":"STEP-20","instance":"implement@0","kind":"executor","attempt":1,"status":"skipped"}
],"total":5}}
JSON
activate ""
refused && grep -q '(step list RUN-7)' "${WORK}/err"
check "a step list whose total differs from its length refuses activation" $?

# Without jq nothing can be checked. The PATH holds only the stubs and cat
# (macOS ships /usr/bin/jq, so no system directory is on it).
NOJQ="${WORK}/nojq"
mkdir -p "$NOJQ"
for tool in docket vorpal python3; do ln -s "${BIN}/${tool}" "${NOJQ}/${tool}"; done
ln -s "$(command -v cat)" "${NOJQ}/cat"
arrange done
if PATH="$NOJQ" command -v jq >/dev/null 2>&1; then
    echo "justfile-activate-review-guard: FAIL — jq is reachable on the no-jq PATH" >&2
    fail=1
fi
CASE_PATH="$NOJQ" activate ""
refused && grep -q 'jq is missing' "${WORK}/err"
check "a missing jq refuses activation" $?

# A non-string run id refuses through the filter's own type check, not
# through a jq runtime error on the id regex.
arrange done
printf '%s\n' '{"ok":true,"data":{"runs":[{"run":7,"status":"paused"}],"total":1}}' > "${FIX}/runs.json"
activate ""
refused && grep -q '(run status)' "${WORK}/err" && ! grep -q '^jq: error' "${WORK}/err"
check "a non-string run id refuses activation" $?

if [ "$fail" -ne 0 ]; then
    echo "justfile-activate-review-guard: FAIL" >&2
    exit 1
fi

echo "justfile-activate-review-guard: PASS"
