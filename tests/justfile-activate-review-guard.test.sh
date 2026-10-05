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
# for an empty answer.
cat > "${BIN}/docket" <<STUB
#!/bin/bash
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
activate() { # <force>
    rm -f "$MARKER"
    sed "s/{{force}}/$1/g" "${WORK}/body.sh" > "${WORK}/run.sh"
    (cd "$WORK" && PATH="${BIN}:${PATH}" bash "${WORK}/run.sh") > "${WORK}/out" 2> "${WORK}/err"
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

if [ "$fail" -ne 0 ]; then
    echo "justfile-activate-review-guard: FAIL" >&2
    exit 1
fi

echo "justfile-activate-review-guard: PASS"
