#!/bin/bash

# Behavior suite for src/user/claude_code/skills/docket-run/scripts/gate_repro.sh,
# the reproduction the standing ruling "a completion-gate failure the machine
# caused" requires before a gate park is presented.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. It needs `bash`, `git` and `jq`; the engine is a
# fake `docket` on PATH that answers from fixture files, so there is no
# database and no network.
#
# WHAT IS PINNED. A parked step whose non-security failing gate passes on a
# clean checkout of the recorded sha yields the override-pass resolve command.
# A gate that fails again, a security gate, an `unmatched` or `skipped` row, a
# step with nothing failing, and a step with no recorded sha all yield
# "present advisor-first", and the security, unmatched and skipped cases run
# nothing at all. The checkout is detached, at the sha of the newest
# unsuperseded issue.diff artifact, and gone afterwards. Each argv runs as an
# argv, not through a shell.
#
# WHAT THIS SUITE CANNOT SEE: the real engine's rows. The fixture mirrors the
# shape of `docket step gates STEP-N --json`, `step artifacts` and `step
# artifact`; a field the engine renames is the engine's contract to keep.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
REPRO="${GATE_REPRO:-${REPO_ROOT}/src/user/claude_code/skills/docket-run/scripts/gate_repro.sh}"

PASS=0
FAIL=0
pass() { printf 'PASS: %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf 'FAIL: %s\n' "$1" >&2; FAIL=$((FAIL + 1)); }
fatal() { printf 'FATAL: %s\n' "$1" >&2; exit 2; }

[ -f "$REPRO" ] || fatal "gate_repro.sh not found at ${REPRO}"
command -v jq >/dev/null 2>&1 || fatal "jq is required to run this test"
command -v git >/dev/null 2>&1 || fatal "git is required to run this test"

SANDBOX=$(mktemp -d "${TMPDIR:-/tmp}/gate-repro-test.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$SANDBOX"' EXIT
FIX="${SANDBOX}/fixture"
BIN="${SANDBOX}/bin"
CHECKOUT="${SANDBOX}/repo"
WORK="${SANDBOX}/work"
MARKER="${SANDBOX}/ran-security-gate"
mkdir -p "$FIX" "$BIN" "$CHECKOUT" "$WORK"

# The checkout under test: a passing script, a failing one, a script that
# records that it ran, and one that checks its arguments arrived intact.
git -C "$CHECKOUT" init -q . >/dev/null 2>&1 || fatal "git init failed"
git -C "$CHECKOUT" config user.email t@example.com
git -C "$CHECKOUT" config user.name t
git -C "$CHECKOUT" config commit.gpgsign false
printf 'exit 0\n' >"$CHECKOUT/ok.sh"
printf 'echo "tests FAILED on repro"\nexit 1\n' >"$CHECKOUT/bad.sh"
printf 'touch "%s"\nexit 0\n' "$MARKER" >"$CHECKOUT/mark.sh"
git -C "$CHECKOUT" add . && git -C "$CHECKOUT" commit -q -m seed || fatal "seed commit failed"
SHA=$(git -C "$CHECKOUT" rev-parse HEAD)
OLD_SHA=$(printf '%040d' 7)

# Fake engine: every verb answers from a fixture file.
cat >"${BIN}/docket" <<'STUB'
#!/bin/bash
case "$1 $2" in
    "step gates") cat "$FIX/gates.json" ;;
    "step artifacts") cat "$FIX/artifacts.json" ;;
    "step artifact") cat "$FIX/artifact-$3.json" ;;
    "step show") cat "$FIX/show.json" ;;
    *) echo "fake docket: unexpected $*" >&2; exit 9 ;;
esac
STUB
chmod +x "${BIN}/docket"
export FIX PATH="${BIN}:${PATH}"

row() { # <gate> <verdict> <argv-json> [ordinal]
    jq -nc --arg g "$1" --arg v "$2" --argjson a "$3" --argjson o "${4:-0}" \
        '{gate:$g, ordinal:$o, verdict:$v, exit:(if $v=="fail" then 1 else 0 end), argv:$a, fingerprint:("fp-"+$g), pre:false, stub:false, created_at_ms:1}'
}
gates() { # <rows...>
    printf '%s\n' "$@" | jq -sc '{ok:true, data:{step:"STEP-9", gates:.}}' >"$FIX/gates.json"
}
payload() { jq -nc --arg h "$1" '{ok:true, data:{payload:({head:$h, resolved_from:$h} | tojson)}}'; }
standard_artifacts() {
    # Two issue.diff artifacts: the newer supersedes the older, and only the newer holds the real sha.
    jq -nc '{ok:true, data:{step:"STEP-9", artifacts:[
        {artifact:"ARTIFACT-1", kind:"change-summary", created_at_ms:1},
        {artifact:"ARTIFACT-2", kind:"issue.diff", created_at_ms:2},
        {artifact:"ARTIFACT-3", kind:"issue.diff", supersedes:"ARTIFACT-2", created_at_ms:3}]}}' >"$FIX/artifacts.json"
    payload "$OLD_SHA" >"$FIX/artifact-ARTIFACT-2.json"
    payload "$SHA" >"$FIX/artifact-ARTIFACT-3.json"
}
jq -nc '{ok:true, data:{step:"STEP-9", run:"RUN-77", status:"done"}}' >"$FIX/show.json"

OUT="${SANDBOX}/out"
run_repro() { # args... ; sets CODE and OUT
    ( cd "$CHECKOUT" && "$REPRO" "$@" --work "$WORK" ) >"$OUT" 2>&1
    CODE=$?
}
expect() { # <label> <want-exit> <fragment>...
    local label="$1" want="$2"; shift 2
    if [ "$CODE" -eq "$want" ]; then pass "${label} (exit ${want})"; else fail "${label} (want exit ${want}, got ${CODE}: $(tr '\n' '|' <"$OUT"))"; fi
    local frag
    for frag in "$@"; do
        if grep -qF -- "$frag" "$OUT"; then pass "  ...output has: ${frag}"; else fail "  ...output lacks: ${frag} (got: $(tr '\n' '|' <"$OUT"))"; fi
    done
}
expect_absent() { # <fragment>
    if grep -qF -- "$1" "$OUT"; then fail "  ...output has '${1}' but should not"; else pass "  ...output lacks: ${1}"; fi
}

OK='["bash","ok.sh"]'
BAD='["bash","bad.sh"]'
MARK='["bash","mark.sh"]'

# ---- a non-security failing gate that passes on repro: the override-pass line ----
gates "$(row build pass "$OK")" "$(row tests fail "$OK")" "$(row secret-scan pass "$OK")"
standard_artifacts
run_repro STEP-9
expect "a failing tests gate whose argv exits 0 on repro" 0 \
    "VERDICT: override-pass" \
    "RESOLVE: docket step resolve STEP-9 --as override-pass --authority standing-grant --authority-ref machine-caused-gate-failure < <scratchpad>/conductor.d/RUN-77.token" \
    "SHA: ${SHA}" \
    "ROW: gate=tests recorded_exit=1 recorded_fingerprint=fp-tests repro_exit=0"
expect_absent "gate=build"

run_repro STEP-9 --token /s/conductor.d/RUN-77.token
expect "a --token path is used in the resolve command" 0 "< /s/conductor.d/RUN-77.token"

# ---- a gate that fails again on repro: advisor-first with the evidence ----
gates "$(row tests fail "$BAD")"
run_repro STEP-9
expect "a failing gate that fails again on repro" 1 \
    "VERDICT: present advisor-first" "failed again on reproduction" "gate=tests" "repro_exit=1" "tests FAILED on repro"
expect_absent "RESOLVE:"

# ---- a security gate is never run and never passed ----
rm -f "$MARKER"
gates "$(row secret-scan fail "$MARK")"
run_repro STEP-9
expect "a failing security gate" 1 "VERDICT: present advisor-first" "secret-scan is a security gate"
if [ -e "$MARKER" ]; then fail "  ...but the security gate's argv was run"; else pass "  ...and its argv was not run"; fi
for g in vuln-scan sdet-abuse; do
    gates "$(row "$g" fail "$MARK")"
    run_repro STEP-9
    expect "a failing ${g} gate" 1 "${g} is a security gate"
done
# A security failure beside a passing-on-repro ordinary one still presents.
gates "$(row tests fail "$OK")" "$(row vuln-scan fail "$MARK")"
run_repro STEP-9
expect "a security failure beside an ordinary one" 1 "vuln-scan is a security gate"
if [ -e "$MARKER" ]; then fail "  ...but a gate was run"; else pass "  ...and nothing was run"; fi

# ---- unmatched, skipped and any other verdict: advisor-first, nothing run ----
for v in unmatched skipped timeout; do
    gates "$(row tests fail "$MARK")" "$(row doc-validate "$v" "$MARK")"
    run_repro STEP-9
    expect "a gate reading ${v}" 1 "VERDICT: present advisor-first" "doc-validate reads ${v}"
    if [ -e "$MARKER" ]; then fail "  ...but a gate was run"; else pass "  ...and nothing was run"; fi
done

# ---- nothing failing, and only the newest ordinal of a gate counts ----
gates "$(row build pass "$OK")"
run_repro STEP-9
expect "no failing gate" 1 "VERDICT: present advisor-first" "nothing to reproduce"
gates "$(row tests fail "$BAD" 0)" "$(row tests pass "$OK" 1)"
run_repro STEP-9
expect "an older failing ordinal superseded by a passing retry" 1 "nothing to reproduce"
gates "$(row tests pass "$OK" 0)" "$(row tests fail "$OK" 1)"
run_repro STEP-9
expect "a newer failing ordinal is the one reproduced" 0 "VERDICT: override-pass" "ROW: gate=tests"

# ---- the sha: newest unsuperseded issue.diff, or --sha, or advisor-first ----
gates "$(row tests fail "$OK")"
jq -nc '{ok:true, data:{step:"STEP-9", artifacts:[{artifact:"ARTIFACT-1", kind:"change-summary", created_at_ms:1}]}}' >"$FIX/artifacts.json"
run_repro STEP-9
expect "a step with no issue.diff artifact records no sha" 1 "VERDICT: present advisor-first" "no issue.diff artifact"
run_repro STEP-9 --sha "$SHA"
expect "--sha supplies the sha when the step records none" 0 "SHA: ${SHA}" "VERDICT: override-pass"
standard_artifacts
run_repro STEP-9 --sha not-a-sha
expect "a malformed --sha" 1 "not a 40-hex commit id"
run_repro STEP-9 --sha "$OLD_SHA"
expect "a --sha that is not a commit in the checkout" 1 "is not a commit"

# ---- the argv runs as an argv, and the checkout is gone afterwards ----
ARGV_CHECK='["bash","-c","test \"$1\" = \"a b\" && test \"$#\" = 1","_","a b"]'
gates "$(row tests fail "$ARGV_CHECK")"
run_repro STEP-9
expect "an argument containing a space arrives as one argument" 0 "VERDICT: override-pass"
WT_COUNT=$(git -C "$CHECKOUT" worktree list | wc -l | tr -d ' ')
LEFT=$(ls "$WORK" | wc -l | tr -d ' ')
if [ "$WT_COUNT" = 1 ] && [ "$LEFT" = 0 ]; then pass "the detached worktree and its scratch directory are removed"; else fail "worktrees: ${WT_COUNT}, scratch entries: ${LEFT}"; fi
gates "$(row tests fail "$BAD")"
run_repro STEP-9
WT_COUNT=$(git -C "$CHECKOUT" worktree list | wc -l | tr -d ' ')
if [ "$WT_COUNT" = 1 ]; then pass "the worktree is removed after a failed reproduction too"; else fail "worktrees left after a failed repro: ${WT_COUNT}"; fi

# ---- the engine's gate input contract reaches the gate ----
# A range gate run with DOCKET_GATE unset scans an empty tree and passes
# whatever the step did, so the reproduction exports it. A gate that exits 0
# only without DOCKET_GATE must therefore NOT reproduce clean; one that needs
# DOCKET_GATE, DOCKET_STEP and DOCKET_ISSUE set to the right values does.
printf 'test -z "${DOCKET_GATE:-}"\n' >"$CHECKOUT/unset-only.sh"
printf 'test "${DOCKET_GATE:-}" = tests && test "${DOCKET_STEP:-}" = STEP-9 && test "${DOCKET_ISSUE:-}" = DOT-5 && test -z "${DOCKET_GATE_BASE:-}"\n' >"$CHECKOUT/needs-env.sh"
printf 'cat >/dev/null\nexit 0\n' >"$CHECKOUT/reads-stdin.sh"
printf 'echo locked >locked.txt\nchmod a-w locked.txt\nexit 0\n' >"$CHECKOUT/read-only.sh"
git -C "$CHECKOUT" add . && git -C "$CHECKOUT" commit -q -m fixtures || fatal "fixture commit failed"
SHA2=$(git -C "$CHECKOUT" rev-parse HEAD)
jq -nc '{ok:true, data:{step:"STEP-9", run:"RUN-77", issue:"DOT-5", status:"done"}}' >"$FIX/show.json"
gates "$(row doc-validate fail '["bash","unset-only.sh"]')"
run_repro STEP-9 --sha "$SHA2"
expect "a gate that passes only without DOCKET_GATE does not reproduce clean" 1 "VERDICT: present advisor-first" "repro_exit=1"
gates "$(row tests fail '["bash","needs-env.sh"]')"
run_repro STEP-9 --sha "$SHA2"
expect "DOCKET_GATE, DOCKET_STEP and DOCKET_ISSUE are exported, DOCKET_GATE_BASE is not" 0 "VERDICT: override-pass"

# ---- a gate that reads stdin must not swallow the rows behind it ----
gates "$(row a fail '["bash","reads-stdin.sh"]')" "$(row b fail "$BAD")"
run_repro STEP-9 --sha "$SHA2"
expect "a stdin-reading gate beside a failing one" 1 "VERDICT: present advisor-first" "gate=b" "repro_exit=1"
ROWS=$(grep -c '^ROW:' "$OUT")
if [ "$ROWS" = 2 ]; then pass "  ...and every failing row ran (2 ROW lines)"; else fail "  ...but ${ROWS} ROW lines were printed for 2 failing rows"; fi

# ---- a gate that leaves read-only files does not leave scratch behind ----
gates "$(row tests fail '["bash","read-only.sh"]')"
run_repro STEP-9 --sha "$SHA2"
expect "a gate that writes a read-only file" 0 "VERDICT: override-pass"
LEFT=$(ls "$WORK" | wc -l | tr -d ' ')
if [ "$LEFT" = 0 ]; then pass "  ...and its scratch directory is removed"; else fail "  ...but ${LEFT} scratch entries remain"; fi

# ---- the security-gate list tracks the workflows that name the gates ----
# The ruling's "any gate the security track adds": the gates security-change
# runs beyond standard-change, plus the two scanners standard-change names
# already. A new gate in the security track fails this row instead of being
# silently passed.
CONFIG="${REPO_ROOT}/src/user/docket/config/workflows"
if [ -f "${CONFIG}/security-change.toml" ] && [ -f "${CONFIG}/standard-change.toml" ]; then
    gate_names() { grep -h '^gates = \[' "$1" | head -n 1 | grep -o '"[a-z-]*"' | tr -d '"' | sort -u; }
    EXTRA=$(comm -13 <(gate_names "${CONFIG}/standard-change.toml") <(gate_names "${CONFIG}/security-change.toml") | tr '\n' ' ')
    WANT=$(printf '%s\n' secret-scan vuln-scan $EXTRA | sort -u | tr '\n' ' ')
    HAVE=$(sed -n 's/^SECURITY_GATES="\(.*\)"$/\1/p' "$REPRO" | tr ' ' '\n' | sort -u | tr '\n' ' ')
    if [ "$WANT" = "$HAVE" ]; then pass "SECURITY_GATES is secret-scan, vuln-scan and the gates security-change adds (${HAVE% })"; else fail "SECURITY_GATES drifted: workflows say '${WANT% }', script has '${HAVE% }'"; fi
else
    fail "the workflow definitions were not found under ${CONFIG}"
fi
gates "$(row qa-test fail "$MARK")"
rm -f "$MARKER"
run_repro STEP-9 --sha "$SHA2"
expect "a failing qa-test gate" 1 "qa-test is a security gate"

# ---- usage ----
run_repro
expect "no step id" 2 "usage: gate_repro.sh"
run_repro not-a-step
expect "a malformed step id" 2 "usage: gate_repro.sh"
run_repro STEP-9 --bogus
expect "an unknown flag" 2 "usage: gate_repro.sh"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
