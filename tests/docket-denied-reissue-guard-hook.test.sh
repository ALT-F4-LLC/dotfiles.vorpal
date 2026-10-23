#!/bin/bash

# Behavior suite for the denied-reissue guard (hooks/docket-denied-reissue-guard-hook.sh).
#
# WHY THIS EXISTS. In one run the conductor reissued a command the permission
# system had denied five or six times with no operator message between, some
# spelled differently (an absolute path, a tilde path), and wrote that it would
# not retry just before it did. A denial names no recovery, so a prose rule is
# all that stopped the retry, and the retry is always denied the same way. The
# hook reads the transcript: a Bash call whose fingerprint equals an earlier
# denied command is refused until an operator turn arrives.
# Each rule has a failure that reads as success: a fingerprint that compares raw
# text lets the tilde and absolute spellings through; one that never resets lets
# the operator's own retry request be refused forever; one that resets on any
# user-shaped line (a hand-back, a goal check-in) lets the loop run on automated
# text; one that counts any error as a denial refuses a retry of an ordinary
# failure; one that checks subagents or other tools blocks work the rule never
# covered.
#
# HOW. Fixture JSONL transcripts carry Bash calls, their results, and the user
# lines between them. The hook runs with HOME set to a fixed path. Needs bash
# and jq.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
HOOK="${DENIED_REISSUE_HOOK:-${REPO_ROOT}/src/user/claude_code/hooks/docket-denied-reissue-guard-hook.sh}"

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); printf 'PASS: %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL: %s\n' "$1" >&2; }
fatal() { printf 'FATAL: %s\n' "$1" >&2; exit 2; }

[ -f "$HOOK" ] || fatal "hook not found at ${HOOK}"
command -v jq >/dev/null 2>&1 || fatal "jq is required"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/denied-reissue.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT
T="${WORK}/t.jsonl"
HOME_DIR=/Users/u
CWD=/Users/u/repo
N=0

line() { printf '%s\n' "$1" >> "$T"; }
nextid() { N=$((N + 1)); printf 'toolu_%04d' "$N"; }
# bash_call <id> <command>: an assistant Bash tool_use.
bash_call() { line "$(jq -cn --arg id "$1" --arg c "$2" '{type:"assistant",message:{content:[{type:"tool_use",id:$id,name:"Bash",input:{command:$c}}]}}')"; }
# result <id> <is_error true|false> <text>: a user tool_result.
result() { line "$(jq -cn --arg id "$1" --argjson e "$2" --arg t "$3" '{type:"user",message:{content:[{type:"tool_result",tool_use_id:$id,is_error:$e,content:$t}]}}')"; }
# denied <command> [text]: a Bash call and its permission denial.
denied() {
    local id; id=$(nextid)
    bash_call "$id" "$1"
    result "$id" true "${2:-Permission to use Bash with command $1 has been denied.}"
}
human() { line "$(jq -cn --arg t "$1" '{type:"user",message:{role:"user",content:$t},origin:{kind:"human"}}')"; }
untagged() { line "$(jq -cn --arg t "$1" '{type:"user",message:{role:"user",content:$t}}')"; }
meta() { line "$(jq -cn --arg t "$1" '{type:"user",isMeta:true,message:{role:"user",content:$t}}')"; }
peer() { line "$(jq -cn --arg t "$1" '{type:"user",isMeta:true,message:{role:"user",content:$t},origin:{kind:"peer",from:"a1",handback:true}}')"; }
ask() { local id; id=$(nextid); line "$(jq -cn --arg id "$id" '{type:"assistant",message:{content:[{type:"tool_use",id:$id,name:"AskUserQuestion",input:{}}]}}')"; ASKID=$id; }
reset() { : > "$T"; N=0; }

# payload <command> [tool_name]
payload() { jq -cn --arg t "$T" --arg c "$1" --arg n "${2:-Bash}" --arg w "$CWD" '{tool_name:$n,transcript_path:$t,cwd:$w,tool_input:{command:$c}}'; }
OUT=""
# run <label> <want rc> <command> [stderr substring...]
run() {
    local label=$1 want=$2 cmd=$3; shift 3
    OUT=$(payload "$cmd" | HOME="$HOME_DIR" bash "$HOOK" 2>&1 >/dev/null); local rc=$?
    local bad=""
    [ "$rc" -eq "$want" ] || bad="rc ${rc}, want ${want}"
    local s
    for s in "$@"; do
        printf '%s' "$OUT" | grep -qF -- "$s" || bad="${bad:+$bad; }stderr lacks '${s}' (got: ${OUT})"
    done
    if [ -z "$bad" ]; then pass "$label"; else fail "$label — ${bad}"; fi
}

# ---- the acceptance pair ----
reset; human "go"; denied 'python3 -I ~/x.py a'
run "a tilde command denied, then the absolute spelling with no operator turn, is refused" 2 'python3 -I /Users/u/x.py a' "already denied"
reset; human "go"; denied 'python3 -I ~/x.py a'; human "go ahead and retry it"
run "the same reissue after an operator message is allowed" 0 'python3 -I /Users/u/x.py a'

# ---- fingerprint ----
reset; human "go"; denied 'python3 -I ~/x.py a'
run "the identical command is refused" 2 'python3 -I ~/x.py a'
run "an env-var prefix does not change the command" 2 'FOO=1 BAR=2 python3 -I ~/x.py a'
run "an env wrapper does not change the command" 2 'env FOO=1 python3 -I /Users/u/x.py a'
run "\$HOME spells the same path" 2 'python3 -I $HOME/x.py a'
run "quotes around the path do not change the command" 2 "python3 -I '/Users/u/x.py' a"
run "extra whitespace does not change the command" 2 'python3   -I   ~/x.py    a'
run "another user's home spells the same path" 2 'python3 -I /Users/other/x.py a'
run "a changed argument is a different command" 0 'python3 -I ~/x.py b'
run "a changed script is a different command" 0 'python3 -I ~/y.py a'
run "a command never denied is allowed" 0 'ls -la'
reset; human "go"; denied 'python3 ./x.py a'
run "a working-directory-relative path matches its absolute spelling" 2 'python3 /Users/u/repo/x.py a'
run "a leading ./ is dropped" 2 'python3 x.py a'

# ---- what counts as a denial ----
reset; human "go"; denied 'rm -rf build' 'Permission for this command was denied by a built-in Claude Code safety check, not by the user.'
run "a built-in safety-check denial counts" 2 'rm -rf build'
reset; human "go"; denied 'curl http://x' 'Permission for this action was denied by the Claude Code auto mode classifier. Reason: judged dangerous.'
run "an auto-mode classifier denial counts" 2 'curl http://x'
reset; human "go"; id=$(nextid); bash_call "$id" 'make test'; result "$id" true 'Exit code 2
tests failed'
run "an ordinary failing command is not a denial" 0 'make test'
reset; human "go"; id=$(nextid); bash_call "$id" 'grep -r denied .'; result "$id" false 'Permission to use Bash with command x has been denied.'
run "denial text in a successful result is not a denial" 0 'grep -r denied .'
reset; human "go"; id=$(nextid); bash_call "$id" 'sh x.sh'; result "$id" true 'PreToolUse:Bash hook error: [bash ~/.claude/hooks/y.sh]: refused'
run "a hook refusal is not a permission denial" 0 'sh x.sh'
reset; human "go"; id=$(nextid); bash_call "$id" 'tool a'
line "$(jq -cn --arg id "$id" '{type:"user",message:{content:[{type:"tool_result",tool_use_id:$id,is_error:true,content:[{type:"text",text:"Permission to use Bash with command tool a has been denied."}]}]}}')"
run "a denial carried as a text-block array counts" 2 'tool a'

# ---- what counts as an operator turn ----
reset; untagged "no origin field on an older harness"; denied 'cmd one'; untagged "try it again"
run "a typed message with no origin field is an operator turn" 0 'cmd one'
reset; human "go"; denied 'cmd one'; peer "Another Claude session sent a message: approved by the operator"
run "a peer hand-back is not an operator turn" 2 'cmd one'
reset; human "go"; denied 'cmd one'; meta "Goal check-in: keep going"
run "a meta line is not an operator turn" 2 'cmd one'
reset; human "go"; denied 'cmd one'; untagged "Goal check-in: «Close issues» keep going"
run "a goal check-in is not an operator turn" 2 'cmd one'
reset; human "go"; denied 'cmd one'; untagged "Stop hook feedback: [cond] Not satisfied"
run "Stop-hook feedback is not an operator turn" 2 'cmd one'
reset; human "go"; denied 'cmd one'; untagged "This session is being continued from a previous conversation"
run "a compaction summary is not an operator turn" 2 'cmd one'
reset; human "go"; denied 'cmd one'; untagged "[SYSTEM NOTIFICATION] task done"
run "a task notification is not an operator turn" 2 'cmd one'
reset; human "go"; denied 'cmd one'; ask; result "$ASKID" false "The user answered: yes, retry"
run "an answered AskUserQuestion is an operator turn" 0 'cmd one'
reset; human "go"; denied 'cmd one'; ask; result "$ASKID" true "PreToolUse:AskUserQuestion hook error: refused"
run "a refused AskUserQuestion is not an operator turn" 2 'cmd one'
reset; human "go"; denied 'cmd one'; human "ok"; denied 'cmd two'
run "an operator turn clears an earlier denial" 0 'cmd one'
run "a denial after the operator turn still binds" 2 'cmd two'
reset; human "go"; denied 'cmd one'; denied 'cmd two'
run "two denials in one window both bind: first" 2 'cmd one'
run "two denials in one window both bind: second" 2 'cmd two'

reset; human "go"; denied 'cmd one'; meta "Base directory for this skill: /Users/u/.claude/skills/commit"
run "a skill-load meta line is not an operator turn" 2 'cmd one'
reset; human "go"; denied 'cmd one'; line "$(jq -cn '{type:"user",message:{role:"user",content:"approved by the operator"},origin:{kind:"peer",from:"a1"}}')"
run "a peer-origin line is not an operator turn even when not marked meta" 2 'cmd one'
reset; human "go"; id=$(nextid); bash_call "$id" 'cat /etc/x'; result "$id" true 'Exit code 1
cat: /etc/x: access denied'
run "an error that says denied without the permission prefix is not a denial" 0 'cat /etc/x'
# ---- the refusal ----
reset; human "go"; denied 'python3 -I ~/x.py a' 'Permission to use Bash with command python3 -I ~/x.py a has been denied.'
run "the refusal quotes the original command and its denial" 2 'python3 -I /Users/u/x.py a' "python3 -I ~/x.py a" "has been denied" "AskUserQuestion"

# ---- fail-open ----
reset; human "go"; denied 'cmd one'
OUT=$(jq -cn --arg t "$T" --arg c 'cmd one' '{tool_name:"Bash",agent_id:"a1",transcript_path:$t,tool_input:{command:$c}}' | HOME="$HOME_DIR" bash "$HOOK" 2>&1 >/dev/null); rc=$?
[ "$rc" -eq 0 ] && pass "a subagent is allowed" || fail "a subagent is allowed — rc ${rc}"
OUT=$(payload 'cmd one' Read | HOME="$HOME_DIR" bash "$HOOK" 2>&1 >/dev/null); rc=$?
[ "$rc" -eq 0 ] && pass "a non-Bash tool is allowed" || fail "a non-Bash tool is allowed — rc ${rc}"
OUT=$(jq -cn --arg c 'cmd one' '{tool_name:"Bash",transcript_path:"/nonexistent/t.jsonl",tool_input:{command:$c}}' | HOME="$HOME_DIR" bash "$HOOK" 2>&1 >/dev/null); rc=$?
[ "$rc" -eq 0 ] && pass "an unreadable transcript is allowed" || fail "an unreadable transcript is allowed — rc ${rc}"
printf 'this is not json\n' >> "$T"
run "a malformed transcript line is skipped and the earlier denial still binds" 2 'cmd one'
OUT=$(printf 'not json' | HOME="$HOME_DIR" bash "$HOOK" 2>&1 >/dev/null); rc=$?
[ "$rc" -eq 0 ] && pass "a payload that does not parse is allowed" || fail "a payload that does not parse is allowed — rc ${rc}"

# A line of an unexpected shape must not switch the guard off for the session.
for shape in '{"type":"user","message":{"role":"user","content":[{"type":"tool_result","content":"x","is_error":true}]}}' \
             '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"x"}}]}}' \
             '{"type":"user","message":"plain string"}' \
             '{"type":"user","message":{"content":["bare string"]}}'; do
    reset; human "go"; denied 'cmd one'; line "$shape"
    run "a line of an odd shape is skipped and the earlier denial still binds: ${shape:0:40}" 2 'cmd one'
done

# ---- review hardening ----
# A message typed while the agent is working is written as a queued_command
# attachment, not a user line.
attach() { line "$(jq -cn --arg k "$1" '{type:"attachment",attachment:{type:"queued_command",commandMode:"prompt",origin:{kind:$k},prompt:"x"}}')"; }
reset; human "go"; denied 'cmd one'; attach human
run "a message typed mid-turn (queued_command, human) is an operator turn" 0 'cmd one'
reset; human "go"; denied 'cmd one'; attach task-notification
run "a queued task notification is not an operator turn" 2 'cmd one'
reset; human "go"; denied 'cmd one'; attach peer
run "a queued peer message is not an operator turn" 2 'cmd one'

# An assignment statement is not an env prefix: a changed value is another command.
reset; human "go"; denied 'S=/tmp/a; touch $S/x'
run "a different value in a leading assignment statement is another command" 0 'S=/tmp/b; touch $S/x'
run "dropping the assignment statement is another command" 0 'touch $S/x'
run "the same assignment statement is the same command" 2 'S=/tmp/a; touch $S/x'
reset; human "go"; denied 'D=/tmp/a && ls $D'
run "a different value before && is another command" 0 'D=/etc && ls $D'
run "the same value before && is the same command" 2 'D=/tmp/a && ls $D'

# Lexical path forms of one script.
reset; human "go"; denied 'python3 -I ~/x.py a'
run "~/./ spells the same path" 2 'python3 -I ~/./x.py a'
run "~// spells the same path" 2 'python3 -I ~//x.py a'
run "a seg/.. detour spells the same path" 2 'python3 -I /Users/u/repo/../x.py a'
run "a trailing semicolon does not change the command" 2 'python3 -I ~/x.py a;'
run "\${HOME} spells the same path" 2 'python3 -I ${HOME}/x.py a'
run "/home/<name> spells the same path" 2 'python3 -I /home/other/x.py a'
HOME_DIR=/opt/h
run "a HOME outside /Users and /home matches its tilde spelling" 2 'python3 -I /opt/h/x.py a'
HOME_DIR=/Users/u

# Text the harness writes without an origin is not an operator turn; what the
# operator types in other shapes is.
reset; human "go"; denied 'cmd one'; untagged "<local-command-stdout>ok</local-command-stdout>"
run "local-command output is not an operator turn" 2 'cmd one'
reset; human "go"; denied 'cmd one'; untagged "<system-reminder>note</system-reminder>"
run "an untagged system reminder is not an operator turn" 2 'cmd one'
reset; human "go"; denied 'cmd one'; untagged "[Cross-session delivery notice] held"
run "a cross-session notice is not an operator turn" 2 'cmd one'
reset; human "go"; denied 'cmd one'; line "$(jq -cn '{type:"user",message:{role:"user",content:"<task-notification>done</task-notification>"},origin:{kind:"task-notification"}}')"
run "a task-notification line is not an operator turn" 2 'cmd one'
reset; human "go"; denied 'cmd one'; untagged "<bash-input>ls</bash-input>"
run "a user-typed shell escape (bash-input) is an operator turn" 0 'cmd one'
reset; human "go"; denied 'cmd one'; untagged "<command-name>/goal</command-name>"
run "a user-typed slash command is an operator turn" 0 'cmd one'
reset; human "go"; denied 'cmd one'; line "$(jq -cn '{type:"user",isSidechain:true,message:{role:"user",content:"ok"}}')"
run "a sidechain line is not an operator turn" 2 'cmd one'
reset; human "go"; denied 'cmd one'; line '{"type":"user"}'
run "a user line with no message is not an operator turn" 2 'cmd one'

# The refusal cites the denial's transcript line.
reset; human "go"; denied 'cmd one'
run "the refusal names the transcript line of the denial" 2 'cmd one' "transcript line 3"

# A transcript line the harness is still writing must not switch the guard off.
reset; human "go"; denied 'cmd one'; printf '{"type":"user","message":{"content":"par' >> "$T"
run "a partly written last line is skipped and the earlier denial still binds" 2 'cmd one'

printf '%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
