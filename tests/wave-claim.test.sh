#!/bin/bash

# Behavior suite for src/user/docket/bin/wave-claim, the script wave.js's
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
CLAIM="${WAVE_CLAIM:-${SCRIPT_DIR}/../src/user/docket/bin/wave-claim}"
CLAIM=$(cd "$(dirname "$CLAIM")" && pwd)/$(basename "$CLAIM")

fatal() { printf 'FATAL: %s\n' "$1" >&2; exit 2; }
[ -x "$CLAIM" ] || fatal "wave-claim not executable at ${CLAIM}"
command -v jq >/dev/null 2>&1 || fatal "jq is required"
command -v node >/dev/null 2>&1 || fatal "node is required"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/wave-claim.XXXXXX") || fatal "mktemp failed"
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
# Stub docket: answers `step claim` per $STUB_MODE, records `step fail`.
printf '%s\n' "$*" >>"$STUB_LOG"
case "$1 $2" in
"step claim")
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
        STUB_LOG="$C/stub.log" STUB_PACKET="$WORK/packet.txt" STUB_TOKEN="$TOKEN_VALUE" \
        STUB_FAIL_STDIN="$C/fail.stdin" STUB_FAIL_EXIT="${STUB_FAIL_EXIT:-0}" \
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
[ -f "$MODULE" ]; check $? "the module lands at the path wave.js computed"
[ "$(head -n 1 "$MODULE")" = "export const meta = { name: 'docket-packet', description: 'Docket work packet written by wave-claim' }" ]
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

# ---- stale modules are swept, fresh ones kept ------------------------------------
C="$WORK/sweep"; MODULE="$C/repo/.claude/docket-packets/STEP-7.a3.js"
mkdir -p "$C/repo/.claude/docket-packets"
printf 'old\n' >"$C/repo/.claude/docket-packets/STEP-1.a1.js"
touch -t 202001010000 "$C/repo/.claude/docket-packets/STEP-1.a1.js"
printf 'fresh\n' >"$C/repo/.claude/docket-packets/STEP-2.a1.js"
set_args
run_claim sweep success "${ARGS[@]}"
[ ! -e "$C/repo/.claude/docket-packets/STEP-1.a1.js" ] && [ -e "$C/repo/.claude/docket-packets/STEP-2.a1.js" ]
check $? "modules older than a day are swept; a fresh sibling module stays"

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
