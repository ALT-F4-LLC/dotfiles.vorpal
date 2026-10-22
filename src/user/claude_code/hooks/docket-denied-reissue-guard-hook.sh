#!/bin/bash

# Refuse a Bash command the permission system already denied, reissued without
# a new word from the operator.
#
# Runs before each Bash call. A denial is a Bash tool_result in this session's
# transcript that is an error and begins "Permission to use Bash ..." (a deny
# rule) or "Permission for this command|action ..." (the built-in safety check
# and the auto-mode classifier), and names "denied". The call is refused when
# its fingerprint equals the fingerprint of such a denied command and no
# operator turn sits between the denial and now. An operator turn is a typed
# message (origin human, or no origin on a line that is not harness text), or a
# non-error answer to an AskUserQuestion. A peer message, a subagent hand-back,
# a task notification, a goal check-in and a Stop-hook notice are not operator
# turns.
#
# The fingerprint drops leading VAR=value words (not an assignment statement
# ended by `;` or `&&`) and `env`, strips quote characters and a trailing `;`,
# collapses whitespace, `//` and `/./`, resolves `seg/..`, maps `~`, `$HOME`,
# the home directory and `/Users/<name>` or `/home/<name>` to one token, and drops
# the working directory prefix and a leading `./`, so a tilde, an absolute and a
# relative spelling of one script compare equal. Every `/Users/<name>` and
# `/home/<name>` is one token, so two users' paths merge; that only over-refuses.
#
# This is a tripwire against the respelling loop observed in one run, not a
# boundary: the permission system is the boundary. It does not catch a changed
# flag or argument, a cd prefix, a redirection or pipe suffix, an sh -c or bash
# -c wrapper, command/time/exec wrappers, a trailing comment, an interpreter
# spelled by path, a command spelled through a shell variable, or a subshell.
#
# A transcript line of an unexpected shape is skipped like a malformed one; it
# neither ends the scan nor clears a denial. Relative paths resolve against the
# working directory of the call being checked, not that of the denial, so a
# relative command denied in one directory also matches the same text from
# another. The harness-text filter reads string content only: an array-content
# user line counts as typed.
#
# Cost: a transcript with no denial text costs one grep. Otherwise each call
# reads the whole transcript with jq, about 2 s on a 296 MB transcript and
# 0.14 s on a 21 MB one, growing with the session. A hook that times out fails
# open.
#
# Subagents, any unreadable transcript and any payload that does not parse are
# allowed: a subagent's payload carries the parent's transcript, and the rule
# binds the session that was refused.

set -uo pipefail

allow() { exit 0; }
deny() { printf '%s\n' "$1" >&2; exit 2; }

command -v jq >/dev/null 2>&1 || allow
DATA=$(cat 2>/dev/null) || allow

[ "$(printf '%s' "$DATA" | jq -r '.tool_name // empty' 2>/dev/null)" = "Bash" ] || allow
[ -n "$(printf '%s' "$DATA" | jq -r '.agent_id // empty' 2>/dev/null)" ] && allow
TRANSCRIPT=$(printf '%s' "$DATA" | jq -r '.transcript_path // empty' 2>/dev/null)
[ -n "$TRANSCRIPT" ] && [ -r "$TRANSCRIPT" ] || allow
CMD=$(printf '%s' "$DATA" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -n "$CMD" ] || allow
CWD=$(printf '%s' "$DATA" | jq -r '.cwd // empty' 2>/dev/null)

# Most transcripts hold no denial at all; a grep for its opening words skips
# the jq pass for them.
grep -qE 'Permission (to use Bash|for this (command|action))' "$TRANSCRIPT" 2>/dev/null || allow

# shellcheck disable=SC2016
PROGRAM='
def strip_env:
    if test("^(env +)?[A-Za-z_][A-Za-z0-9_]*=[^ ;&|]* +[^ ;&|]")
    then sub("^(env +)?[A-Za-z_][A-Za-z0-9_]*=[^ ;&|]* +"; "") | strip_env
    else sub("^env +"; "") end;
def unwind: if test("/(?!\\.\\.(/|$))[^/ ]+/\\.\\.(/|$)") then sub("/(?!\\.\\.(/|$))[^/ ]+/\\.\\.(?<e>/|$)"; "\(.e)") | unwind else . end;
def paths: gsub("/\\./"; "/") | gsub("//+"; "/") | unwind;
def homed:
    gsub("(?<p>^|[ =:])(~|\\$HOME|\\$\\{HOME\\}|/Users/[^/ ]+|/home/[^/ ]+)/"; "\(.p)<HOME>/")
    | if ($home | test("^/[A-Za-z0-9_./-]+$")) then split($home + "/") | join("<HOME>/") else . end;
def fp($cwdn):
    gsub("[\\x27\"]"; "") | gsub("\\s+"; " ") | sub("^ "; "") | sub("[; ]+$"; "")
    | strip_env | paths | homed
    | if $cwdn != "" then split($cwdn + "/") | join("") else . end
    | gsub("(?<p>^| )\\./"; "\(.p)");
def text: if type == "string" then . else ([.[]? | select(type == "object") | .text? // empty] | join("\n")) end;
def denial: test("^Permission (to use Bash|for this (command|action))") and test("denied");
def operator_turn:
    .type == "user" and ((.isMeta // false) | not) and ((.isSidechain // false) | not) and (.message != null)
    and ((.message.content | type) as $t | $t == "string" or ([.message.content[]? | .type] | index("tool_result") | not))
    and ((.origin.kind // "human") == "human")
    and ((.message.content | type) != "string"
         or (.message.content | test("^(This session is being continued|<local-command|Goal check-in|Stop hook feedback|\\[SYSTEM NOTIFICATION|\\[Cross-session|<system-reminder)") | not));
($cwd | homed) as $cwdn
| ($cmd | fp($cwdn)) as $want
| reduce (inputs | try fromjson catch null) as $l ({pend: {}, ask: {}, denied: []};
    . as $s | try (
    if ($l | type) != "object" then .
    elif $l.type == "assistant" then
        reduce (($l.message.content? // [])[]? | select(type == "object" and .type == "tool_use")) as $u (.;
            if $u.name == "Bash" and (($u.input.command? // null) | type) == "string" then .pend[$u.id] = $u.input.command
            elif $u.name == "AskUserQuestion" then .ask[$u.id] = true
            else . end)
    elif $l.type == "user" then
        (if ($l | operator_turn) then .denied = [] else . end)
        | reduce (($l.message.content? // [])[]? | select(type == "object" and .type == "tool_result")) as $r (.;
            if (.ask[$r.tool_use_id] // false) and (($r.is_error // false) | not) then .denied = []
            elif ($r.is_error // false) and (.pend[$r.tool_use_id] != null) and (($r.content | text) | denial)
            then .denied += [{fp: (.pend[$r.tool_use_id] | fp($cwdn)), cmd: .pend[$r.tool_use_id], text: ($r.content | text), line: input_line_number}]
            else . end)
    elif $l.type == "attachment" and (($l.attachment.type? // "") == "queued_command") and (($l.attachment.origin.kind? // "") == "human") then .denied = []
    else . end
    ) catch $s)
| .denied | map(select(.fp == $want)) | last // empty
'

HIT=$(jq -R -n -c --arg cmd "$CMD" --arg cwd "$CWD" --arg home "${HOME:-}" "$PROGRAM" "$TRANSCRIPT" 2>/dev/null) || allow
[ -n "$HIT" ] || allow

ORIG=$(printf '%s' "$HIT" | jq -r '.cmd | gsub("\\s+"; " ") | .[0:240]')
WHY=$(printf '%s' "$HIT" | jq -r '.text | gsub("\\s+"; " ") | .[0:240]')
LINE=$(printf '%s' "$HIT" | jq -r '.line')
deny "Refused: this command was already denied and the operator has not spoken since (transcript line ${LINE}: ${ORIG}). The denial read: ${WHY} A reworded or re-spelled retry needs new authorization. Do not retry it; ask the operator through AskUserQuestion, or take a different approach."
