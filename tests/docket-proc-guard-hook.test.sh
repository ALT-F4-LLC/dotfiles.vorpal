#!/bin/bash

# Suite for hooks/docket-proc-guard-hook.sh, driven by synthetic PreToolUse
# payloads and fixture conductor tokens. For a docket conductor (a session
# whose scratchpad holds a conductor.d token) the hook runs
# proc_supervise.sh's inventory, dry run and kill outside the Bash sandbox, on
# exact command shapes. It denies the kill to subagents and to non-conductors,
# and takes no action on anything else.
# DOCKET_PROC_GUARD_SCRIPT points the hook at a stub that
# records its arguments and payload, so no process is signalled here; the
# script's own signal path is pinned in docket-run-proc-supervise.test.sh.
#
# DOCKET_PROC_GUARD_HOOK overrides the hook under test for mutation probes.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
HOOK="${DOCKET_PROC_GUARD_HOOK:-${SCRIPT_DIR}/../src/user/claude_code/hooks/docket-proc-guard-hook.sh}"
REISSUE="${SCRIPT_DIR}/../src/user/claude_code/hooks/docket-denied-reissue-guard-hook.sh"

command -v jq >/dev/null 2>&1 || { echo "FATAL: jq is required" >&2; exit 2; }
[ -f "$HOOK" ] || { echo "FATAL: no hook at $HOOK" >&2; exit 2; }

WORK=$(mktemp -d "${TMPDIR:-/tmp}/docket-proc-guard-test.XXXXXX") || exit 2
trap 'rm -rf "$WORK"' EXIT

PASS=0
FAIL=0
pass() { printf 'PASS: %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf 'FAIL: %s\n' "$1" >&2; FAIL=$((FAIL + 1)); }

SID=11111111-1111-1111-1111-111111111111
SCRIPT_REL=.claude/skills/docket-run/scripts/proc_supervise.sh
STUB="$WORK/stub.sh"
cat > "$STUB" <<'STUB'
#!/bin/bash
printf '%s\n' "$*" > "$STUB_LOG"
while [ $# -gt 0 ]; do [ "$1" = --payload ] && cp "$2" "$STUB_LOG.payload"; shift; done
printf 'own-shell\tstop\t123\t100\tx\tx\t/w\tzsh\n'
printf 'signal\tTERM\t123\town-shell\n'
printf 'refuse\t200\tsibling\tnot-a-target\n'
exit "${STUB_RC:-0}"
STUB

# Conductor tokens: a conductor session's scratchpad holds a non-empty
# conductor.d/RUN-<digits>.token. Every other session lacks one, or holds a
# file that must not count.
SP="$WORK/sp"
export DOCKET_PROC_GUARD_TOKEN_GLOB="$SP/@SESSION@/scratchpad/conductor.d/RUN-*.token"
NOTOK=22222222-2222-2222-2222-222222222222
EMPTYTOK=33333333-3333-3333-3333-333333333333
LINKTOK=44444444-4444-4444-4444-444444444444
NEWTOK=55555555-5555-5555-5555-555555555555
BADRUN=66666666-6666-6666-6666-666666666666
for s in "$SID" "$EMPTYTOK" "$LINKTOK" "$NEWTOK" "$BADRUN"; do mkdir -p "$SP/$s/scratchpad/conductor.d"; done
printf 'tok\n' > "$SP/$SID/scratchpad/conductor.d/RUN-12.token"
: > "$SP/$EMPTYTOK/scratchpad/conductor.d/RUN-5.token"
ln -s "$SP/$SID/scratchpad/conductor.d/RUN-12.token" "$SP/$LINKTOK/scratchpad/conductor.d/RUN-5.token"
printf 'tok\n' > "$SP/$NEWTOK/scratchpad/conductor.d/RUN-5.token.new"
printf 'tok\n' > "$SP/$BADRUN/scratchpad/conductor.d/RUN-x.token"

payload() { # <command> <session_id> [agent_id] [transcript]
    jq -cn --arg c "$1" --arg s "$2" --arg a "${3:-}" --arg t "${4:-$WORK/none.jsonl}" \
        '{session_id: $s, transcript_path: $t, hook_event_name: "PreToolUse", tool_name: "Bash", tool_input: {command: $c}}
         + (if $a == "" then {} else {agent_id: $a, agent_type: "executor-write"} end)'
}
hook() { # <payload> ; sets rc, err; stub log in $WORK/log
    rm -f "$WORK/log" "$WORK/log.payload"
    err=$(printf '%s' "$1" | DOCKET_PROC_GUARD_SCRIPT="$STUB" STUB_LOG="$WORK/log" STUB_RC="${STUB_RC:-0}" bash "$HOOK" 2>&1 >/dev/null)
    rc=$?
}
expect() { # <label> <rc> <stub ran: yes|no> [stderr pattern]
    local ran=no; [ -f "$WORK/log" ] && ran=yes
    if [ "$rc" -eq "$2" ] && [ "$ran" = "$3" ] && { [ -z "${4:-}" ] || printf '%s' "$err" | grep -q -- "$4"; }; then
        pass "$1"
    else
        fail "$1: rc=$rc ran=$ran err=$err"
    fi
}

KILL="bash ~/$SCRIPT_REL kill --pid 123 --pid 200"

# ---- no action -----------------------------------------------------------------
hook "$(jq -cn '{tool_name: "Read", tool_input: {file_path: "/x"}}')"
expect "a non-Bash tool is allowed untouched" 0 no
hook "$(payload 'git status' "$SID")"
expect "an unrelated Bash command is allowed untouched" 0 no
hook "$(payload "bash ~/$SCRIPT_REL inventory" "$NOTOK")"
expect "a non-conductor's inventory runs in the sandbox, no action" 0 no
hook "$(payload "bash ~/$SCRIPT_REL kill --dry-run --pid 123" "$NOTOK")"
expect "a non-conductor's kill --dry-run runs in the sandbox, no action" 0 no
hook "$(payload "bash ~/$SCRIPT_REL inventory --snapshot /tmp/f" "$SID")"
expect "an inventory with an extra flag is not the trigger" 0 no
hook "$(payload "bash ~/$SCRIPT_REL kill --dry-run --dry-run --pid 123" "$SID")"
expect "a repeated --dry-run is not the trigger" 0 no
hook "$(payload "bash ~/$SCRIPT_REL kill --dry-run" "$SID")"
expect "a dry run with no --pid is not the trigger" 0 no
hook "$(payload "$KILL; rm -rf /tmp/x" "$SID")"
expect "a chained command is not the trigger" 0 no
hook "$(payload "bash ~/$SCRIPT_REL kill --pid \$(cat /tmp/pid)" "$SID")"
expect "a substituted pid is not the trigger" 0 no
hook "$(payload "grep -n kill ~/$SCRIPT_REL" "$SID")"
expect "a grep naming the script is not the trigger" 0 no
hook "$(payload "bash /tmp/copy/proc_supervise.sh kill --pid 123" "$SID")"
expect "a copied script path is not the trigger" 0 no
hook "$(payload "bash ~/$SCRIPT_REL kill --pid 123 --snapshot /tmp/forged.tsv" "$SID")"
expect "an extra flag (a forged table) is not the trigger" 0 no
hook "$(payload "bash ~/$SCRIPT_REL kill --signal STOP --pid 123" "$SID")"
expect "an unlisted signal is not the trigger" 0 no
hook "$(payload "bash ~/$SCRIPT_REL kill
--pid 123" "$SID")"
expect "a newline in the command is not the trigger" 0 no

# ---- criterion 4: subagents only inventory ---------------------------------------
hook "$(payload "$KILL" "$SID" agent-7)"
expect "a subagent's exact kill is denied" 2 no "subagent agent-7 may only inventory"
hook "$(payload "cd /tmp && bash ~/$SCRIPT_REL kill --pid 123 | tee x" "$SID" agent-7)"
expect "a subagent's kill in a chained spelling is denied" 2 no "may only inventory"
hook "$(payload "bash ~/$SCRIPT_REL kill --dry-run --pid 123" "$SID" agent-7)"
expect "a subagent's dry run is allowed" 0 no
hook "$(payload "bash ~/$SCRIPT_REL inventory" "$SID" agent-7)"
expect "a subagent's inventory is allowed" 0 no

# ---- operator scope: docket conductors only --------------------------------------
hook "$(payload "$KILL" "$NOTOK")"
expect "a session with no conductor token is denied" 2 no "runs only from a docket conductor"
hook "$(payload "$KILL" "$EMPTYTOK")"
expect "an empty token does not make a conductor" 2 no "runs only from a docket conductor"
hook "$(payload "$KILL" "$LINKTOK")"
expect "a symlinked token does not make a conductor" 2 no "runs only from a docket conductor"
hook "$(payload "$KILL" "$NEWTOK")"
expect "only a RUN-N.token.new does not make a conductor" 2 no "runs only from a docket conductor"
hook "$(payload "$KILL" "$BADRUN")"
expect "a token with a non-numeric run id does not make a conductor" 2 no "runs only from a docket conductor"
hook "$(payload "$KILL" "$SID/../$SID")"
expect "a session id with a path character is never a conductor" 2 no "runs only from a docket conductor"
hook "$(payload "$KILL" "")"
expect "a payload with no session id is never a conductor" 2 no "runs only from a docket conductor"

# ---- the conductor's kill runs, unsandboxed, with only the parsed words -----------
hook "$(payload "$KILL" "$SID")"
expect "a conductor's exact kill runs and the sandboxed call is denied with results" 2 yes "ran this kill outside the Bash sandbox"
[ "$(sed 's/--payload [^ ]*/--payload P/' "$WORK/log" 2>/dev/null)" = "kill --payload P --pid 123 --pid 200" ] \
    && pass "the script gets only kill, the payload and the parsed --pid words" || fail "script args: $(cat "$WORK/log" 2>/dev/null)"
jq -e --arg s "$SID" '.session_id == $s and (has("agent_id") | not)' "$WORK/log.payload" >/dev/null 2>&1 \
    && pass "the payload handed over is the conductor's own" || fail "payload not forwarded"
printf '%s' "$err" | grep -q $'^signal\tTERM\t123\town-shell$' && printf '%s' "$err" | grep -q $'^refuse\t200\tsibling\tnot-a-target$' \
    && ! printf '%s' "$err" | grep -q '^own-shell' \
    && pass "the reason carries the signal and refuse rows, not the inventory" || fail "reason rows: $err"
hook "$(payload "\$HOME/$SCRIPT_REL kill --signal KILL --pid 123" "$SID")"
expect "the \$HOME spelling is accepted" 2 yes "ran this kill"
grep -q -- '--signal KILL --pid 123' "$WORK/log" 2>/dev/null && pass "--signal is passed through" || fail "signal args: $(cat "$WORK/log" 2>/dev/null)"
hook "$(payload "$HOME/$SCRIPT_REL kill --pid 123" "$SID")"
expect "the literal home spelling is accepted" 2 yes "ran this kill"
STUB_RC=3 hook "$(payload "$KILL" "$SID")"
expect "a script refusal still denies the sandboxed call and reports the exit" 2 yes "Script exit 3"


# ---- the conductor's inventory and dry run run unsandboxed, full table back -------
hook "$(payload "bash ~/$SCRIPT_REL inventory" "$SID")"
expect "a conductor's inventory runs outside the sandbox and returns the table" 2 yes "ran this inventory outside the Bash sandbox"
[ "$(cat "$WORK/log" 2>/dev/null)" = "inventory --session $SID" ] && [ ! -f "$WORK/log.payload" ] \
    && printf '%s' "$err" | grep -q $'^own-shell\tstop\t123\t' \
    && pass "the inventory gets only the payload's session and its rows come back" || fail "inventory args/rows: $(cat "$WORK/log" 2>/dev/null) | $err"
hook "$(payload "bash ~/$SCRIPT_REL kill --dry-run --pid 123 --signal KILL" "$SID")"
expect "a conductor's dry run runs outside the sandbox" 2 yes "ran this dry-run outside the Bash sandbox"
[ "$(cat "$WORK/log" 2>/dev/null)" = "kill --dry-run --session $SID --pid 123 --signal KILL" ] && [ ! -f "$WORK/log.payload" ] \
    && pass "the dry run gets --dry-run, the session and the parsed words, never --payload" || fail "dry-run args: $(cat "$WORK/log" 2>/dev/null)"
hook "$(payload "bash ~/$SCRIPT_REL inventory" "$SID" agent-7)"
expect "a subagent's inventory stays in the sandbox even in a conductor session" 0 no
# ---- the deny text does not read as a permission denial ---------------------------
hook "$(payload "$KILL" "$SID")"
case "$err" in Permission*) fail "deny text begins with Permission" ;; *) pass "the deny text never begins with Permission" ;; esac
if [ -f "$REISSUE" ]; then
    T="$WORK/reissue.jsonl"
    { jq -cn --arg c "$KILL" '{type: "assistant", message: {content: [{type: "tool_use", id: "k1", name: "Bash", input: {command: $c}}]}}'
      jq -cn --arg e "PreToolUse:Bash hook error: $err" '{type: "user", message: {content: [{type: "tool_result", tool_use_id: "k1", is_error: true, content: $e}]}}'
    } > "$T"
    printf '%s' "$(payload "$KILL" "$SID" "" "$T")" | bash "$REISSUE" >/dev/null 2>&1
    [ $? -eq 0 ] && pass "docket-denied-reissue-guard lets the same kill be reissued" || fail "reissue guard refused a reissued kill"
fi

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
