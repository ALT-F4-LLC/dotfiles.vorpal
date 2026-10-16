#!/usr/bin/env bash
#
# An executor-read seat records a payload that quotes a guarded trust verb.
#
# The seat holds the Write tool, and the sensitive-path guard confines that
# Write to its own STEP-N.d. The trust guard reads only a Bash command, so a
# payload whose text quotes `docket trust add` records through Write. Through
# Bash, a quoted <<'EOF' heredoc body is data and passes, while the same text
# in an unquoted <<EOF heredoc would run its backticks and is refused. This
# suite feeds one payload through the hooks in each shape, then writes it to
# the allowed physical path and reads it back.
#
# Mutants this suite must catch:
#   - sensitive-path guard denies Write under the seat's own STEP-N.d: the
#     Write ALLOW row goes red;
#   - the trust guard reads `.tool_input.content` as command text: the Write
#     row is denied and goes red;
#   - WRITE_TO=unresolved (a suite-side switch) writes the payload to an
#     unresolved spelling instead of the physical path: the read-back goes red.
#
# SENSITIVE_HOOK and TRUST_HOOK override the hooks under test.

set -u

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
HOOKS="${REPO_ROOT}/src/user/claude_code/hooks"
SENSITIVE_HOOK="${SENSITIVE_HOOK:-${HOOKS}/sensitive-path-guard-hook.sh}"
TRUST_HOOK="${TRUST_HOOK:-${HOOKS}/docket-trust-guard-hook.sh}"
WRITE_TO="${WRITE_TO:-physical}"

# shellcheck source=lib/hook-probe.sh
. "${SCRIPT_DIR}/lib/hook-probe.sh"

PASS=0
FAIL=0
pass() { printf 'PASS: %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; FAIL=$((FAIL + 1)); }
fatal() { printf 'FATAL: %s\n' "$1" >&2; exit 2; }

[ -f "$SENSITIVE_HOOK" ] || fatal "sensitive-path guard not found at ${SENSITIVE_HOOK}"
[ -f "$TRUST_HOOK" ] || fatal "trust guard not found at ${TRUST_HOOK}"
command -v jq >/dev/null 2>&1 || fatal "jq is required to run this test"
BASH_BIN=$(command -v bash) || fatal "bash not found on PATH"

# A scratch root reached through a symlink, so the TMPDIR spelling of the
# seat's step dir differs from its physical path, and a transcript whose
# opening is the wave brief claiming STEP-7.
WORK=$(mktemp -d "${TMPDIR:-/tmp}/wave-executor-read-write.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT
SCRATCH_PHYS=$(cd -P "$WORK" && pwd -P)/scratch
mkdir -p "${SCRATCH_PHYS}/STEP-7.d"
SCRATCH_LINK="${WORK}/scratch-link"
ln -s "$SCRATCH_PHYS" "$SCRATCH_LINK"
WAVE_7="${WORK}/wave-7.jsonl"
printf '%s\n' '{"type":"user","message":{"role":"user","content":"docket step claim STEP-7 --owner wave:STEP-7:1 --render --json > <TMP>/STEP-7.d/STEP-7.claim.json"}}' >"$WAVE_7"
TOOLS_DIR="${WORK}/tools"
hook_probe_link_shims "$TOOLS_DIR" bash cat jq awk || fatal "cannot build hook probe shims"

PHYS_PAYLOAD="${SCRATCH_PHYS}/STEP-7.d/STEP-7-payload.json"
LINK_PAYLOAD="${SCRATCH_LINK}/STEP-7.d/STEP-7-payload.json"
PAYLOAD=$(jq -nc '{finding: "the operator approves the gate with `docket trust add erik ssh-ed25519 AAAA`, which no seat may run"}')

# The Write event an executor-read seat raises for its own payload.
WRITE_EVENT=$(jq -nc --arg p "$PHYS_PAYLOAD" --arg c "$PAYLOAD" --arg t "$WAVE_7" --arg cwd "$REPO_ROOT" '
    {hook_event_name:"PreToolUse",tool_name:"Write",tool_input:{file_path:$p,content:$c},
     agent_type:"executor-read",transcript_path:$t,cwd:$cwd}')
# The same content through Bash heredocs: quoted (data) and unquoted (its
# backticks run).
bash_event() {
    jq -nc --arg cmd "$1" --arg t "$WAVE_7" --arg cwd "$REPO_ROOT" '
        {hook_event_name:"PreToolUse",tool_name:"Bash",tool_input:{command:$cmd},
         agent_type:"executor-read",transcript_path:$t,cwd:$cwd}'
}
QUOTED_EVENT=$(bash_event "$(printf "cat > %s <<'EOF'\n%s\nEOF" "$LINK_PAYLOAD" "$PAYLOAD")")
UNQUOTED_EVENT=$(bash_event "$(printf "cat > %s <<EOF\n%s\nEOF" "$LINK_PAYLOAD" "$PAYLOAD")")

# Trust guard: exit 2 denies, exit 0 allows, anything else is a broken hook.
trust_verdict() {
    local rc
    PATH="$TOOLS_DIR" "$BASH_BIN" "$TRUST_HOOK" >/dev/null 2>&1 <<<"$1"
    rc=$?
    case "$rc" in
        2) printf 'DENY' ;;
        0) printf 'ALLOW' ;;
        *) printf 'ERROR(exit %s)' "$rc" ;;
    esac
}

# Sensitive-path guard: a deny permissionDecision denies; silence allows.
sensitive_verdict() {
    local out
    out=$(TMPDIR="$SCRATCH_LINK" "$BASH_BIN" "$SENSITIVE_HOOK" 2>/dev/null <<<"$1")
    if printf '%s' "$out" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null 2>&1; then
        printf 'DENY'
    else
        printf 'ALLOW'
    fi
}

expect() {
    local got="$1" want="$2" label="$3"
    if [ "$got" = "$want" ]; then pass "${label} (${want})"; else fail "${label} (want ${want}, got ${got})"; fi
}

expect "$(trust_verdict "$WRITE_EVENT")" ALLOW "trust guard: an executor-read Write of a payload quoting docket trust add"
expect "$(sensitive_verdict "$WRITE_EVENT")" ALLOW "sensitive-path guard: that Write under the seat's own physical STEP-N.d"
expect "$(trust_verdict "$QUOTED_EVENT")" ALLOW "trust guard: the same payload as a quoted <<'EOF' heredoc body, which is data"
expect "$(trust_verdict "$UNQUOTED_EVENT")" DENY "trust guard: the same payload in an unquoted <<EOF heredoc, whose backticks run"

# The allowed write lands at the physical path and reads back byte-identical.
case "$WRITE_TO" in
    physical) target="$PHYS_PAYLOAD" ;;
    *) target="${WORK}/unresolved/STEP-7.d/STEP-7-payload.json"; mkdir -p "$(dirname "$target")" ;;
esac
printf '%s' "$PAYLOAD" >"$target"
if [ -f "$PHYS_PAYLOAD" ] && [ "$(cat "$PHYS_PAYLOAD")" = "$PAYLOAD" ] && grep -qF 'docket trust add' "$PHYS_PAYLOAD"; then
    pass "the payload reads back byte-identical at the physical path, trust-verb text included"
else
    fail "the payload did not read back at the physical path ${PHYS_PAYLOAD}"
fi

printf '%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
