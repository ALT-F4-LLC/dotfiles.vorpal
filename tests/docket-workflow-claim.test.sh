#!/bin/bash

# Behavior suite for src/user/docket/bin/docket-workflow-claim, the script docket-workflow.js's
# claim agent runs to claim a step and write its work packet into a module the
# wave loads with a nested workflow({scriptPath}).
#
# Each case runs the script against a stub `docket` on PATH that answers
# `step claim` from a canned envelope and records `step fail`, so the suite
# needs only bash, jq and node: no engine, no database, no network. The node
# check evaluates the module the way the Workflow runtime does (a body with a
# top-level `return`) and compares the packet byte for byte.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CLAIM="${WAVE_CLAIM:-${SCRIPT_DIR}/../src/user/docket/bin/docket-workflow-claim}"
CLAIM=$(cd "$(dirname "$CLAIM")" && pwd)/$(basename "$CLAIM")

fatal() { printf 'FATAL: %s\n' "$1" >&2; exit 2; }
[ -x "$CLAIM" ] || fatal "docket-workflow-claim not executable at ${CLAIM}"
command -v jq >/dev/null 2>&1 || fatal "jq is required"
command -v node >/dev/null 2>&1 || fatal "node is required"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/docket-workflow-claim.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT

pass=0; fail=0
ok()   { pass=$((pass + 1)); printf 'PASS: %s\n' "$1"; }
bad()  { fail=$((fail + 1)); printf 'FAIL: %s\n' "$1"; }
check() { if [ "$1" -eq 0 ]; then ok "$2"; else bad "$2"; fi; }

TOKEN_VALUE='tok-SECRET-4f1c9e'

# A packet carrying every character class a JS string literal can trip on.
printf '== STEP STEP-7 implement@0\nrun:    RUN-3\n\n== FILE contracts/implement.md  abc\n# Charter\nbacktick ` dollar-brace ${x} backslash \\ quote " apostrophe '"'"'\nclose </script> tab\t cr\r crlf\r\n' >"$WORK/packet.txt"
printf '%s' $'separators [ ] [ ] astral [\U0001F9EA] bom [﻿]\n' >>"$WORK/packet.txt"
printf '\n== OUTPUT\nRecord an artifact of kind: change-summary\n' >>"$WORK/packet.txt"

mkdir -p "$WORK/bin"
cat >"$WORK/bin/docket" <<'STUB'
#!/bin/bash
# Stub docket: answers `step claim` per $STUB_MODE and `step render` from
# $STUB_RENDER (nothing when unset), records `step fail`.
printf '%s\n' "$*" >>"$STUB_LOG"
case "$1 $2" in
"step claim")
    cat >"$STUB_CLAIM_STDIN"
    env >"$STUB_CLAIM_ENV"
    case "$STUB_MODE" in
    success)
        jq -n --rawfile p "$STUB_PACKET" --arg t "$STUB_TOKEN" \
            '{ok: true, data: {step: "STEP-7", token: $t, lease_expires_ms: 1790000000000, packet: $p, attempt: 3, version: 9}}'
        ;;
    remint)
        jq -n --rawfile p "$STUB_PACKET" --arg t "$STUB_TOKEN" \
            '{ok: true, data: {step: "STEP-7", token: $t, lease_expires_ms: 1790000000000, packet: $p, attempt: 3, version: 9, re_minted: true}}'
        ;;
    conflict)
        printf '%s\n' '{"ok":false,"error":"step implement@0 is not ready to claim: the step is not pending","code":"CONFLICT"}'
        exit 4
        ;;
    failed)
        printf '%s\n' '{"ok":false,"error":"database is locked","code":"INTERNAL"}'
        exit 1
        ;;
    incomplete)
        jq -n --arg t "$STUB_TOKEN" \
            '{ok: true, data: {step: "STEP-7", token: $t, lease_expires_ms: 1, attempt: 3, version: 9, claim_error: "assembling the context bundle failed"}}'
        ;;
    empty-packet)
        jq -n --arg t "$STUB_TOKEN" '{ok: true, data: {step: "STEP-7", token: $t, lease_expires_ms: 1, attempt: 3, version: 9}}'
        ;;
    esac
    ;;
"step render")
    [ -z "${STUB_RENDER:-}" ] || cat "$STUB_RENDER"
    ;;
"step fail")
    cat >"$STUB_FAIL_STDIN"
    exit "${STUB_FAIL_EXIT:-0}"
    ;;
esac
STUB
chmod +x "$WORK/bin/docket"

# run_claim <case> <mode> [args...]: a fresh repo, TMPDIR and stub log per case.
run_claim() {
    local name="$1" mode="$2"; shift 2
    C="$WORK/$name"
    mkdir -p "$C/repo" "$C/tmp"
    : >"$C/stub.log"
    MODULE="$C/repo/.claude/docket-packets/STEP-7.a3.js"
    OUT=$(cd "$C/repo" && PATH="$WORK/bin:$PATH" TMPDIR="$C/tmp" STUB_MODE="$mode" \
        STUB_LOG="$C/stub.log" STUB_PACKET="${STUB_PACKET_FILE:-$WORK/packet.txt}" STUB_TOKEN="$TOKEN_VALUE" \
        STUB_RENDER="${STUB_RENDER:-}" \
        STUB_FAIL_STDIN="$C/fail.stdin" STUB_FAIL_EXIT="${STUB_FAIL_EXIT:-0}" \
        STUB_CLAIM_STDIN="$C/claim.stdin" STUB_CLAIM_ENV="$C/claim.env" \
        "$CLAIM" "$@" 2>&1)
    RC=$?
}

set_args() { # [module] — sets ARGS; a plain assignment, since bash 3.2 has no mapfile
    ARGS=(--step STEP-7 --owner wave:STEP-7:2 --attempt 3
        --module "${1:-$MODULE}" --metadata '{"variant":"std","model_requested":"opus"}')
}

# modval <module> <jq filter>: a field of the module's returned object.
modval() { sed -n '2s/^return //p' "$1" | jq -r "$2"; }

mode_of() { stat -c '%a' "$1" 2>/dev/null || stat -f '%Lp' "$1"; }

sha256_of() {
    if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | cut -d' ' -f1
    else shasum -a 256 "$1" | cut -d' ' -f1; fi
}

# ---- success ------------------------------------------------------------------
C="$WORK/success"; MODULE="$C/repo/.claude/docket-packets/STEP-7.a3.js"
set_args
run_claim success success "${ARGS[@]}"
[ "$RC" -eq 0 ]; check $? "success exits 0 (got $RC: $OUT)"
[ "$(printf '%s\n' "$OUT" | wc -l | tr -d ' ')" = "1" ] && [[ "$OUT" == "CLAIMED STEP-7 attempt=3 packet_bytes="*" module=$MODULE" ]]
check $? "success prints exactly one CLAIMED line naming the module"
grep -qxF 'step claim STEP-7 --owner wave:STEP-7:2 --render --metadata {"variant":"std","model_requested":"opus"} --json=v2' "$C/stub.log"
check $? "the claim carries the owner, --render, the metadata and --json=v2"
[ -f "$MODULE" ]; check $? "the module lands at the path docket-workflow.js computed"
[ "$(head -n 1 "$MODULE")" = "export const meta = { name: 'docket-packet', description: 'Docket work packet written by docket-workflow-claim' }" ]
check $? "the module opens with a pure-literal meta"
sed -n '2s/^return //p' "$MODULE" | jq -j '.packet' >"$C/packet.out"
cmp -s "$C/packet.out" "$WORK/packet.txt"; check $? "the module's packet is the engine's packet byte for byte"
[ "$(modval "$MODULE" '.step + " " + .owner + " " + (.attempt|tostring) + " " + (.expected_attempt|tostring) + " " + (.re_minted|tostring)')" = "STEP-7 wave:STEP-7:2 3 3 false" ]
check $? "the module records step, owner, attempt, expected attempt and re_minted"
[ "$(modval "$MODULE" '.dir')" = "$C/tmp/STEP-7.d" ] && [ "$(modval "$MODULE" '.token')" = "$C/tmp/STEP-7.d/STEP-7.token" ]
check $? "the module names the literal step dir and token file under TMPDIR"
! grep -qF "$TOKEN_VALUE" "$MODULE"; check $? "the token never enters the module"
! printf '%s' "$OUT" | grep -qF "$TOKEN_VALUE"; check $? "the token never reaches stdout"
[ "$(cat "$C/tmp/STEP-7.d/STEP-7.token")" = "$TOKEN_VALUE" ] && [ "$(mode_of "$C/tmp/STEP-7.d/STEP-7.token")" = "600" ]
check $? "the token is parked in its file, mode 600"
[ "$(mode_of "$C/tmp/STEP-7.d")" = "700" ]; check $? "the step dir is private, mode 700"
[ "$(grep -rlF "$TOKEN_VALUE" "$C/tmp" | wc -l | tr -d ' ')" = "1" ]
check $? "no file but the token file holds the token (the claim response is gone)"
cmp -s "$C/tmp/STEP-7.d/STEP-7.packet.md" "$WORK/packet.txt"; check $? "the packet is also kept beside the token"
[ "$(cat "$C/repo/.claude/docket-packets/.gitignore")" = "*" ]; check $? "the module dir ignores itself"
[ -z "$(cd "$C/repo" && git init -q . && git status --porcelain)" ]; check $? "git status shows nothing for the module dir"
[ "$(modval "$MODULE" '.packet_sha256')" = "$(sha256_of "$WORK/packet.txt")" ]
check $? "the module records the packet's sha256"

# The Workflow runtime runs a script body with a top-level return; evaluate
# the module the same way and compare what comes back.
cat >"$C/load.mjs" <<'JS'
import { readFileSync } from 'node:fs'
const [modulePath, packetPath] = process.argv.slice(2)
const body = readFileSync(modulePath, 'utf8').replace(/^export const meta/, 'const meta')
const value = new Function(body)()
const want = readFileSync(packetPath, 'utf8')
process.exit(value && value.packet === want && value.step === 'STEP-7' ? 0 : 1)
JS
node "$C/load.mjs" "$MODULE" "$WORK/packet.txt"
check $? "the module evaluates as a script body and returns the packet intact"

# ---- re-mint keeps the attempt and says so ---------------------------------
C="$WORK/remint"; MODULE="$C/repo/.claude/docket-packets/STEP-7.a3.js"
set_args
run_claim remint remint "${ARGS[@]}"
[ "$RC" -eq 0 ] && [ "$(modval "$MODULE" '.re_minted')" = "true" ]
check $? "a re-minted claim succeeds and the module records re_minted"

# ---- the recovery secret reaches the claim on stdin and nowhere else ----------
# A stale scratch file in the step dir must go with the rebuild; the secret,
# created fresh before the claim, must survive it.
C="$WORK/secret-fresh"; MODULE="$C/repo/.claude/docket-packets/STEP-7.a3.js"
mkdir -p "$C/tmp/STEP-7.d"
printf 'old scratch\n' >"$C/tmp/STEP-7.d/STEP-7-old.md"
set_args
run_claim secret-fresh success "${ARGS[@]}"
SECRET="$C/tmp/STEP-7.d/STEP-7.secret"
[ "$RC" -eq 0 ] && [ -f "$SECRET" ] && [ ! -L "$SECRET" ] && [ "$(mode_of "$SECRET")" = "600" ]
check $? "after the claim the secret survives the step-dir rebuild as a regular file, mode 600 (got $RC: $OUT)"
[ "$(wc -c <"$SECRET" | tr -d ' ')" -ge 32 ]; check $? "a fresh secret carries at least 32 bytes"
[ -s "$C/claim.stdin" ] && cmp -s "$C/claim.stdin" "$SECRET"
check $? "the claim reads exactly the secret file's bytes on stdin"
[ ! -e "$C/tmp/STEP-7.d/STEP-7-old.md" ] && [ "$(mode_of "$C/tmp/STEP-7.d")" = "700" ]
check $? "the rebuild clears every other file from the step dir and keeps it mode 700"
SECRET_VALUE=$(cat "$SECRET")
! grep -qF "$SECRET_VALUE" "$C/stub.log"; check $? "the secret never enters the claim's argv"
! grep -qF "$SECRET_VALUE" "$C/claim.env"; check $? "the secret never enters the claim's environment"
! grep -qF "$SECRET_VALUE" "$MODULE"; check $? "the secret never enters the module"
! printf '%s' "$OUT" | grep -qF "$SECRET_VALUE"; check $? "the secret never reaches stdout"

C="$WORK/secret-seeded"; MODULE="$C/repo/.claude/docket-packets/STEP-7.a3.js"
mkdir -p "$C/tmp/STEP-7.d"
chmod 700 "$C/tmp/STEP-7.d"
printf 'seeded-recovery-value' >"$C/tmp/STEP-7.d/STEP-7.secret"
chmod 600 "$C/tmp/STEP-7.d/STEP-7.secret"
set_args
run_claim secret-seeded success "${ARGS[@]}"
[ "$RC" -eq 0 ] && [ "$(cat "$C/claim.stdin")" = "seeded-recovery-value" ] &&
    [ "$(cat "$C/tmp/STEP-7.d/STEP-7.secret")" = "seeded-recovery-value" ] &&
    [ "$(mode_of "$C/tmp/STEP-7.d/STEP-7.secret")" = "600" ]
check $? "an existing secret is presented and kept unchanged (got $RC: $OUT)"

C="$WORK/secret-twice"; MODULE="$C/repo/.claude/docket-packets/STEP-7.a3.js"
set_args
run_claim secret-twice success "${ARGS[@]}"
first_rc=$RC
cp "$C/claim.stdin" "$C/claim.stdin.first"
run_claim secret-twice remint "${ARGS[@]}"
[ "$first_rc" -eq 0 ] && [ "$RC" -eq 0 ] && [ -s "$C/claim.stdin.first" ] &&
    cmp -s "$C/claim.stdin.first" "$C/claim.stdin"
check $? "two claims of one step present the same secret (got $first_rc then $RC)"

# refuse_secret <case> <label>: the planted secret is refused before any claim.
refuse_secret() {
    local name="$1" label="$2"
    set_args "$C/repo/.claude/docket-packets/STEP-7.a3.js"
    run_claim "$name" success "${ARGS[@]}"
    if [ "$RC" -eq 1 ] && [[ "$OUT" == "CLAIM FAILED: STEP-7: "*"STEP-7.secret"* ]] && [ ! -s "$C/stub.log" ]; then
        ok "a secret that is $label is refused before the claim"
    else
        bad "a secret that is $label is refused before the claim (exit $RC: $OUT; stub log: $(cat "$C/stub.log"))"
    fi
}
C="$WORK/secret-symlink"; mkdir -p "$C/tmp/STEP-7.d"
printf 'elsewhere' >"$C/elsewhere"; chmod 600 "$C/elsewhere"
ln -s "$C/elsewhere" "$C/tmp/STEP-7.d/STEP-7.secret"
refuse_secret secret-symlink "a symlink"
C="$WORK/secret-readable"; mkdir -p "$C/tmp/STEP-7.d"
printf 'readable' >"$C/tmp/STEP-7.d/STEP-7.secret"; chmod 644 "$C/tmp/STEP-7.d/STEP-7.secret"
refuse_secret secret-readable "readable by group or other"
C="$WORK/secret-dir"; mkdir -p "$C/tmp/STEP-7.d/STEP-7.secret"
refuse_secret secret-dir "a directory"
C="$WORK/secret-empty"; mkdir -p "$C/tmp/STEP-7.d"
: >"$C/tmp/STEP-7.d/STEP-7.secret"; chmod 600 "$C/tmp/STEP-7.d/STEP-7.secret"
refuse_secret secret-empty "empty"

# ---- a symlinked TMPDIR: the module carries the physical step dir -------------
# Under a sandbox the Write tool lands at the physical path, so the module
# names it beside the TMPDIR spelling the token and record commands use.
C="$WORK/symlink"; MODULE="$C/repo/.claude/docket-packets/STEP-7.a3.js"
mkdir -p "$C/real"
ln -s "$C/real" "$C/tmp"
REAL=$(cd "$C/real" && pwd -P)
set_args
run_claim symlink success "${ARGS[@]}"
[ "$RC" -eq 0 ] && [ "$(modval "$MODULE" '.dir_physical')" = "$REAL/STEP-7.d" ]
check $? "a symlinked TMPDIR yields a physical step dir equal to the target's STEP-7.d (got $(modval "$MODULE" '.dir_physical'))"
[ "$(modval "$MODULE" '.dir')" = "$C/tmp/STEP-7.d" ] && [ "$REAL/STEP-7.d" != "$C/tmp/STEP-7.d" ]
check $? "the module's dir keeps the TMPDIR spelling, which differs from the physical path"

# ---- conflict leaves the holder's files alone ---------------------------------
C="$WORK/conflict"; MODULE="$C/repo/.claude/docket-packets/STEP-7.a3.js"
mkdir -p "$C/tmp/STEP-7.d" "$C/repo/.claude/docket-packets"
printf 'holder-token' >"$C/tmp/STEP-7.d/STEP-7.token"
printf 'holder module\n' >"$MODULE"
set_args
run_claim conflict conflict "${ARGS[@]}"
[ "$RC" -eq 4 ]; check $? "a conflict exits 4 (got $RC)"
[ "$OUT" = $'STEP-7\nCONFLICT\nstep implement@0 is not ready to claim: the step is not pending' ]
check $? "a conflict prints the step, CONFLICT and the engine's line, nothing else"
[ "$(cat "$C/tmp/STEP-7.d/STEP-7.token")" = "holder-token" ] && [ "$(cat "$MODULE")" = "holder module" ]
check $? "a conflict leaves the holder's token file and module untouched"
[ -z "$(find "$C/tmp" -name 'STEP-7.claim.*')" ]; check $? "a conflict leaves no work dir behind"

# ---- other claim failures ---------------------------------------------------------
C="$WORK/failed"; MODULE="$C/repo/.claude/docket-packets/STEP-7.a3.js"
set_args
run_claim failed failed "${ARGS[@]}"
[ "$RC" -eq 1 ] && [ "$OUT" = "CLAIM FAILED: STEP-7: database is locked" ] && [ ! -e "$MODULE" ]
check $? "a refused claim prints CLAIM FAILED with the engine's error and writes no module"

# ---- a claim whose later stage failed is ended with step fail -------------------
C="$WORK/incomplete"; MODULE="$C/repo/.claude/docket-packets/STEP-7.a3.js"
set_args
run_claim incomplete incomplete "${ARGS[@]}"
[ "$RC" -eq 5 ]; check $? "claim_error exits 5 (got $RC)"
grep -qxF 'step fail STEP-7 --note assembling the context bundle failed' "$C/stub.log"
check $? "claim_error ends the lease with docket step fail, the error as the note"
[ "$(cat "$C/fail.stdin")" = "$TOKEN_VALUE" ]; check $? "step fail reads the token on stdin"
[[ "$OUT" == "CLAIM INCOMPLETE: STEP-7: assembling the context bundle failed; the lease was ended with docket step fail" ]] &&
    [ ! -e "$C/tmp/STEP-7.d" ] && [ ! -e "$MODULE" ]
check $? "after a clean step fail the step dir goes and no module is written"

C="$WORK/incomplete-kept"; MODULE="$C/repo/.claude/docket-packets/STEP-7.a3.js"
set_args
STUB_FAIL_EXIT=1 run_claim incomplete-kept incomplete "${ARGS[@]}"
[ "$RC" -eq 5 ] && [[ "$OUT" == *"docket step fail errored"*"the token is kept at $C/tmp/STEP-7.d/STEP-7.token" ]] &&
    [ "$(cat "$C/tmp/STEP-7.d/STEP-7.token")" = "$TOKEN_VALUE" ]
check $? "when step fail itself errors, the token is kept and its path reported"

C="$WORK/empty-packet"; MODULE="$C/repo/.claude/docket-packets/STEP-7.a3.js"
set_args
run_claim empty-packet empty-packet "${ARGS[@]}"
[ "$RC" -eq 1 ] && [[ "$OUT" == "CLAIM FAILED: STEP-7: the claim committed but carried no packet"* ]] && [ ! -e "$MODULE" ]
check $? "a claim with no packet fails, keeps the token for a reap and writes no module"

# ---- the Workflow script cap ------------------------------------------------------
# The Workflow tool refuses a script file over 524,288 bytes. The engine keeps
# up to 262,144 bytes of each gate's output, so two long rows overflow it.
CAP=524288

# gate_packet <verdict> <out>: a packet whose gate-results input holds two
# 262 KB rows of that verdict beside one short failing row.
gate_packet() {
    {
        printf '== STEP STEP-7 verify-ac@0\nrun:    RUN-3\n\n== INPUT gate-results from implement@0\n'
        jq -cn --arg v "$1" '
            def big($name): "HEAD-\($name)\n" + ("x" * 262000) + "TAIL-\($name)\n";
            [{gate: "tests", exit: 0, output: big("tests"), truncated: true, verdict: $v},
             {gate: "qa-test", exit: 0, output: big("qa-test"), truncated: true, verdict: $v},
             {gate: "lint", exit: 1, output: "lint: 3 errors\nLINT-TAIL\n", truncated: false, verdict: "fail"}]'
        printf '\n== OUTPUT\nRecord an artifact of kind: ac-report\n'
    } >"$2"
}
# gate_row <module> <gate> <jq filter>: a field of one abridged gate row.
gate_row() {
    modval "$1" '.packet' | sed -n '/^== INPUT gate-results from /{n;p;}' | jq -r --arg g "$2" ".[] | select(.gate == \$g) | $3"
}

gate_packet pass "$WORK/gates-pass.txt"
gate_packet fail "$WORK/gates-fail.txt"
# No gate row to abridge: the bulk sits in a section this script never cuts.
{ printf '== INPUT issue.diff from implement@0\n'; jq -rn '"d" * 900000'; } >"$WORK/too-big.txt"

C="$WORK/cap-pass"; MODULE="$C/repo/.claude/docket-packets/STEP-7.a3.js"
set_args
STUB_PACKET_FILE="$WORK/gates-pass.txt" STUB_RENDER="$WORK/gates-pass.txt" run_claim cap-pass success "${ARGS[@]}"
[ "$RC" -eq 0 ] && [ -f "$MODULE" ] && [ "$(wc -c <"$MODULE" | tr -d ' ')" -lt "$CAP" ]
check $? "two 262 KB passing gate rows yield a module under the script cap (got $RC: ${OUT:0:200})"
[[ "$OUT" == "CLAIMED STEP-7 attempt=3 packet_bytes=$(wc -c <"$WORK/gates-pass.txt" | tr -d ' ') module_bytes=$(wc -c <"$MODULE" | tr -d ' ') abridged=1 sha256="* ]]
check $? "the CLAIMED line carries the engine packet's bytes, the module's bytes and abridged=1"
[ "$(modval "$MODULE" '.packet_abridged')" = "true" ]; check $? "the module records that its packet is abridged"
[ "$(gate_row "$MODULE" tests '.output | length')" -lt 8500 ] &&
    [ "$(gate_row "$MODULE" tests '.output | startswith("HEAD-tests\n") and endswith("TAIL-tests\n")')" = "true" ] &&
    [ "$(gate_row "$MODULE" qa-test '.output | endswith("TAIL-qa-test\n")')" = "true" ]
check $? "an abridged passing row keeps the head and tail of its output"
gate_row "$MODULE" tests '.output' | grep -qF "characters omitted here to fit the Workflow script cap; the unabridged packet is $C/tmp/STEP-7.d/STEP-7.packet.md]"
check $? "the cut names its size and the file holding the engine's render"
[ "$(gate_row "$MODULE" tests '[.gate, .exit, .truncated, .verdict] | join(" ")')" = "tests 0 true pass" ]
check $? "an abridged row keeps every other field"
[ "$(gate_row "$MODULE" lint '.output')" = "$(printf 'lint: 3 errors\nLINT-TAIL')" ]
check $? "a short failing row reaches the module whole"
cmp -s "$C/tmp/STEP-7.d/STEP-7.packet.md" "$WORK/gates-pass.txt" &&
    [ "$(modval "$MODULE" '.packet_sha256')" = "$(sha256_of "$WORK/gates-pass.txt")" ]
check $? "the packet file and packet_sha256 stay the engine's render"
sed '/^== INPUT gate-results from /{n;d;}' "$WORK/gates-pass.txt" >"$C/packet.expected"
sed -n '2s/^return //p' "$MODULE" | jq -j '.packet' | sed '/^== INPUT gate-results from /{n;d;}' >"$C/packet.actual"
diff "$C/packet.actual" "$C/packet.expected" >/dev/null
check $? "every line outside the gate rows is unchanged"
[ "$(sed -n '1p' "$C/stub.log" | cut -d' ' -f1-3)" = "step claim STEP-7" ] && ! grep -q '^step render' "$C/stub.log"
check $? "the packet is sized from the claim's own render, with no separate render before it"
sed -n '2s/^return //p' "$MODULE" | jq -j '.packet' >"$C/packet.out"
node "$WORK/success/load.mjs" "$MODULE" "$C/packet.out"
check $? "the abridged module evaluates as a script body"

C="$WORK/cap-fail"; MODULE="$C/repo/.claude/docket-packets/STEP-7.a3.js"
set_args
STUB_PACKET_FILE="$WORK/gates-fail.txt" run_claim cap-fail success "${ARGS[@]}"
[ "$RC" -eq 0 ] && [ "$(wc -c <"$MODULE" | tr -d ' ')" -lt "$CAP" ] &&
    [ "$(gate_row "$MODULE" tests '.output | length')" -gt 65536 ] &&
    [ "$(gate_row "$MODULE" tests '.output | endswith(("x" * 40000) + "TAIL-tests\n")')" = "true" ]
check $? "a failing gate's output tail still reaches the module when its row is abridged (got $RC)"

C="$WORK/cap-small"; MODULE="$C/repo/.claude/docket-packets/STEP-7.a3.js"
set_args
STUB_RENDER="$WORK/packet.txt" run_claim cap-small success "${ARGS[@]}"
sed -n '2s/^return //p' "$MODULE" | jq -j '.packet' >"$C/packet.out"
[ "$RC" -eq 0 ] && cmp -s "$C/packet.out" "$WORK/packet.txt" && [ "$(modval "$MODULE" '.packet_abridged')" = "false" ] &&
    [ "$(modval "$MODULE" '.packet_by_reference')" = "false" ] && [[ "$OUT" == *" abridged=0 "* ]]
check $? "a packet whose module fits is never abridged or by reference"

# A packet that no gate-row abridgment can bring under the cap degrades to a
# by-reference packet instead of failing the claim.
C="$WORK/cap-byref"; MODULE="$C/repo/.claude/docket-packets/STEP-7.a3.js"
set_args
STUB_PACKET_FILE="$WORK/too-big.txt" run_claim cap-byref success "${ARGS[@]}"
[ "$RC" -eq 0 ] && [ -f "$MODULE" ] && [ "$(wc -c <"$MODULE" | tr -d ' ')" -lt "$CAP" ] &&
    [[ "$OUT" == "CLAIMED STEP-7 attempt=3 packet_bytes=$(wc -c <"$WORK/too-big.txt" | tr -d ' ') module_bytes=$(wc -c <"$MODULE" | tr -d ' ') abridged=1 sha256="* ]]
check $? "a 900 KB packet with no gate row to abridge claims with exit 0 and a module under the cap (got $RC: ${OUT:0:200})"
[ "$(modval "$MODULE" '.packet_by_reference')" = "true" ] && [ "$(modval "$MODULE" '.packet_abridged')" = "true" ]
check $? "the module records that its packet is by reference"
[ "$(modval "$MODULE" '.packet_sha256')" = "$(sha256_of "$WORK/too-big.txt")" ] &&
    cmp -s "$C/tmp/STEP-7.d/STEP-7.packet.md" "$WORK/too-big.txt" &&
    [ "$(modval "$MODULE" '.packet_file')" = "$C/tmp/STEP-7.d/STEP-7.packet.md" ]
check $? "packet_file and its packet_sha256 match the engine's packet"
modval "$MODULE" '.packet' | grep -qF "$C/tmp/STEP-7.d/STEP-7.packet.md" &&
    modval "$MODULE" '.packet' | grep -qF "$(sha256_of "$WORK/too-big.txt")" &&
    modval "$MODULE" '.packet' | grep -q '^== STEP STEP-7 (by reference)$'
check $? "the by-reference packet names the packet file and its sha256"
! grep -q '^step fail' "$C/stub.log" && [ -e "$C/tmp/STEP-7.d/STEP-7.token" ]
check $? "the by-reference claim keeps its lease: no step fail, token in place"
F="$C/tmp/STEP-7.d/STEP-7.packet.folded.md"
modval "$MODULE" '.packet' | grep -qF "$F" && [ "$(tr -d '\n' <"$F" | cksum)" = "$(tr -d '\n' <"$WORK/too-big.txt" | cksum)" ] &&
    [ "$(awk '{ if (length($0) > m) m = length($0) } END { print m }' "$F")" -le 1500 ]
check $? "the stub names a folded copy whose lines stay within 1,500 bytes and whose bytes match the packet"

# Gate rows abridged, yet the packet still over the cap: the realistic route to by reference.
{ cat "$WORK/gates-pass.txt"; printf '== INPUT issue.diff from implement@0\n'; jq -rn '"d" * 600000'; } >"$WORK/gates-big.txt"
C="$WORK/cap-byref-gates"; MODULE="$C/repo/.claude/docket-packets/STEP-7.a3.js"
set_args
STUB_PACKET_FILE="$WORK/gates-big.txt" run_claim cap-byref-gates success "${ARGS[@]}"
[ "$RC" -eq 0 ] && [ "$(modval "$MODULE" '.packet_by_reference')" = "true" ] &&
    [ "$(modval "$MODULE" '.packet_sha256')" = "$(sha256_of "$WORK/gates-big.txt")" ] &&
    [ "$(wc -c <"$MODULE" | tr -d ' ')" -lt "$CAP" ]
check $? "abridged gate rows that still leave the packet over the cap fall back to by reference (got $RC: ${OUT:0:200})"
# ---- stale modules are swept, fresh ones kept ------------------------------------
C="$WORK/sweep"; MODULE="$C/repo/.claude/docket-packets/STEP-7.a3.js"
mkdir -p "$C/repo/.claude/docket-packets"
printf 'old\n' >"$C/repo/.claude/docket-packets/STEP-1.a1.js"
touch -t 202001010000 "$C/repo/.claude/docket-packets/STEP-1.a1.js"
printf 'fresh\n' >"$C/repo/.claude/docket-packets/STEP-2.a1.js"
printf 'old\n' >"$C/repo/.claude/docket-packets/rows-0ld.js"
touch -t 202001010000 "$C/repo/.claude/docket-packets/rows-0ld.js"
printf 'fresh\n' >"$C/repo/.claude/docket-packets/rows-fre5h.js"
set_args
run_claim sweep success "${ARGS[@]}"
[ ! -e "$C/repo/.claude/docket-packets/STEP-1.a1.js" ] && [ -e "$C/repo/.claude/docket-packets/STEP-2.a1.js" ]
check $? "modules older than a day are swept; a fresh sibling module stays"
[ ! -e "$C/repo/.claude/docket-packets/rows-0ld.js" ] && [ -e "$C/repo/.claude/docket-packets/rows-fre5h.js" ]
check $? "launch rows modules older than a day are swept; a fresh one stays"

# ---- usage refusals never reach the engine ---------------------------------------
usage_case() { # <label> <args...>
    local label="$1"; shift
    run_claim "usage-$pass-$fail" success "$@"
    if [ "$RC" -eq 2 ] && [ ! -s "$C/stub.log" ]; then ok "usage: $label"; else bad "usage: $label (exit $RC, stub log: $(cat "$C/stub.log"))"; fi
}
M="$WORK/u/repo/.claude/docket-packets/STEP-7.a3.js"
usage_case "a step that is not STEP-N" --step STEP-x --owner wave:STEP-x:1 --attempt 3 --module "$M" --metadata '{}'
usage_case "an owner naming another step" --step STEP-7 --owner wave:STEP-8:1 --attempt 3 --module "$M" --metadata '{}'
usage_case "attempt zero" --step STEP-7 --owner wave:STEP-7:1 --attempt 0 --module "$M" --metadata '{}'
usage_case "a module outside .claude/docket-packets" --step STEP-7 --owner wave:STEP-7:1 --attempt 3 --module /tmp/STEP-7.a3.js --metadata '{}'
usage_case "a module named for another attempt" --step STEP-7 --owner wave:STEP-7:1 --attempt 3 --module "${M%a3.js}a2.js" --metadata '{}'
usage_case "a relative module path" --step STEP-7 --owner wave:STEP-7:1 --attempt 3 --module .claude/docket-packets/STEP-7.a3.js --metadata '{}'
usage_case "metadata that is not a JSON object" --step STEP-7 --owner wave:STEP-7:1 --attempt 3 --module "$M" --metadata '[1]'
usage_case "a flag with no value" --step

C="$WORK/no-tmpdir"; mkdir -p "$C/repo"; : >"$C/stub.log"
OUT=$(cd "$C/repo" && env -u TMPDIR PATH="$WORK/bin:$PATH" STUB_LOG="$C/stub.log" STUB_MODE=success \
    "$CLAIM" --step STEP-7 --owner wave:STEP-7:1 --attempt 3 --module "$C/repo/.claude/docket-packets/STEP-7.a3.js" --metadata '{}' 2>&1)
RC=$?
[ "$RC" -eq 1 ] && [ "$OUT" = "CLAIM FAILED: STEP-7: TMPDIR is unset" ] && [ ! -s "$C/stub.log" ]
check $? "an unset TMPDIR fails before any claim"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
