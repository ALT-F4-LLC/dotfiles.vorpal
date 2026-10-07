#!/bin/bash

# sensitive-path-guard — PreToolUse: Read|Grep|Glob, and Write once
# claude_code.rs registers it for that tool.
#
# Replaces the `Read(<sensitive path>)` permission deny rules. Those rules did
# two things: refuse the Read/Grep/Glob tools on credential stores, and make
# the harness refuse to auto-approve any Bash compound of the form
# `cd <dir> && grep <relative path>` — with any Read() deny rule configured,
# the harness cannot resolve the relative path statically and returns a hard
# "only you can approve running it anyway" ask that the auto-mode classifier
# is forbidden to answer. Measured on the operator: that prompt on scratch-root
# work (`cd /tmp/claude-501/STEP-N.d/target && grep ...`) was the dominant
# approval interruption from wave executors.
#
# The sandbox already refuses these paths for every Bash call at the syscall
# level (sandbox.filesystem.denyRead). This hook covers the other half — the
# Read, Grep and Glob tools, which do not go through the sandbox — so the
# Read() rules can go and the compound-cd ask goes with them.
#
# The list below MUST equal SENSITIVE_PATHS + SENSITIVE_PATHS_DENY_READ_ONLY in
# src/user/claude_code.rs; a unit test there parses this block and fails the
# build on drift.
#
# Decision: deny when the tool's target path (Read/Write: file_path; Grep/Glob:
# path, defaulting to cwd) resolves to a listed root or anything beneath it.
# Every other input is silence and exit 0 — the hook must never block a normal
# read.
#
# WRITE CONFINEMENT. executor-read seats record artifacts and payloads; a
# Write tool lets them do it without the Bash trust matcher reading the text.
# For agent_type executor-read only, a Write is allowed only beneath the
# seat's own scratch dir `<root>/STEP-N.d`, where N comes from the wave brief
# in the seat's own transcript (the sibling guard's rule, copied below) and
# <root> is $TMPDIR, its physical path, or a Claude scratch root
# (/tmp/claude-$UID, /private/tmp/claude-$UID): the seat and the harness may
# spell the same directory either way. With no step id found, the Write is
# denied. Every other caller keeps the sensitive-root check alone.

set -uo pipefail

SENSITIVE_ROOTS='
~/.aws/**
~/.claude.json
~/.doppler/**
~/.gemini/**
~/.gnupg/**
~/.kube/**
~/.netrc
~/.ssh/**
~/.talos/**
~/Desktop/**
~/Downloads/**
'

INPUT=$(cat 2>/dev/null || true)
[ -n "$INPUT" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0

TOOL=$(printf '%s' "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null || true)
CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // ""' 2>/dev/null || true)
[ -n "$CWD" ] || CWD=$PWD

case "$TOOL" in
    Read | Write) TARGET=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null || true) ;;
    Grep | Glob) TARGET=$(printf '%s' "$INPUT" | jq -r '.tool_input.path // ""' 2>/dev/null || true) ;;
    *) exit 0 ;;
esac

if [ -z "$TARGET" ]; then
    # Read or Write without a path is a tool error, not an access. Grep/Glob
    # without a path search the working directory, so that is the path to
    # judge.
    [ "$TOOL" = "Read" ] || [ "$TOOL" = "Write" ] && exit 0
    TARGET=$CWD
fi

# Expand a leading ~, anchor a relative path at cwd, then collapse `.` and
# `..` segments lexically. No symlink resolution: the deny rules this replaces
# did none either, and a symlink into a credential store is a finding for the
# sandbox denyRead list, not this hook.
normalize() {
    local p="$1" seg out=()
    case "$p" in
        '~') p=$HOME ;;
        '~/'*) p="${HOME}/${p#\~/}" ;;
        /*) ;;
        *) p="${CWD}/${p}" ;;
    esac
    set -f
    local IFS='/'
    for seg in $p; do
        case "$seg" in
            '' | '.') ;;
            '..') [ "${#out[@]}" -gt 0 ] && unset 'out[${#out[@]}-1]' ;;
            *) out+=("$seg") ;;
        esac
    done
    set +f
    if [ "${#out[@]}" -eq 0 ]; then
        printf '/'
    else
        printf '/%s' "${out[@]}"
    fi
}

RESOLVED=$(normalize "$TARGET")

# Grep/Glob paths may carry a trailing glob; judge the literal prefix before
# the first metacharacter so `~/.ssh/*` and `~/.ssh/**/*.pub` both resolve to
# the root they enumerate.
case "$RESOLVED" in
    *[\*\?\[]*) RESOLVED=$(normalize "${RESOLVED%%[\*\?\[]*}") ;;
esac

while IFS= read -r root; do
    [ -n "$root" ] || continue
    root=${root%/\*\*}
    root=$(normalize "$root")
    if [ "$RESOLVED" = "$root" ] || [ "${RESOLVED#"$root"/}" != "$RESOLVED" ]; then
        jq -n -c --arg tool "$TOOL" --arg path "$RESOLVED" --arg root "$root" \
            '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: ("sensitive-path-guard: " + $tool + " of " + $path + " is refused; " + $root + " is a credential or personal store the sandbox also denies. Nothing under it is needed for repo work.")}}'
        exit 0
    fi
done <<<"$SENSITIVE_ROOTS"

[ "$TOOL" = "Write" ] || exit 0
AGENT_TYPE=$(printf '%s' "$INPUT" | jq -r '.agent_type // ""' 2>/dev/null || true)
[ "$AGENT_TYPE" = "executor-read" ] || exit 0

# Copied from docket-sibling-guard-hook.sh: reads the opening of the seat's
# own transcript for the wave brief marker `docket step claim STEP-N --owner
# wave:STEP-N:` and sets OWN_STEP to N, or leaves it empty.
scan_transcript() {  # <transcript-path>
    local t="$1" chunk="" rest="" total=0 budget=65536
    local re='docket step claim STEP-([0-9]+) --owner wave:STEP-([0-9]+):'
    OWN_STEP=""
    [ -n "$t" ] && [ -r "$t" ] && [ -f "$t" ] && [ -s "$t" ] || return 0
    while [ "$total" -lt "$budget" ]; do
        chunk=""
        IFS= read -r -n $((budget - total)) chunk || [ -n "$chunk" ] || break
        rest="$chunk"
        while [[ $rest =~ $re ]]; do
            if [ "${BASH_REMATCH[1]}" = "${BASH_REMATCH[2]}" ]; then
                OWN_STEP="${BASH_REMATCH[1]}"
                return 0
            fi
            rest="${rest#*"${BASH_REMATCH[0]}"}"
        done
        total=$((total + ${#chunk} + 1))
    done < "$t"
    return 0
}

# Copied from docket-sibling-guard-hook.sh: inside a subagent the harness
# hands over the parent transcript_path, so the seat's own file is found by
# agent_id under the session directory.
own_transcript_path() {  # <transcript_path> <agent_id> <session_id>
    local t="$1" agent="$2" session="$3" base dir candidate
    local dirs=()
    if [ -z "$agent" ]; then
        printf '%s' "$t"
        return 0
    fi
    [ -n "$t" ] || return 0
    case "${t##*/}" in
        "agent-${agent}.jsonl")
            printf '%s' "$t"
            return 0
            ;;
    esac
    case "$t" in
        *.jsonl) dirs+=("${t%.jsonl}") ;;
    esac
    if [ -n "$session" ]; then
        base="${t%/*}"
        [ "$base" = "$t" ] && base="."
        dirs+=("${base}/${session}")
    fi
    for dir in ${dirs[@]+"${dirs[@]}"}; do
        [ -d "$dir" ] || continue
        candidate="${dir}/subagents/agent-${agent}.jsonl"
        if [ -f "$candidate" ]; then
            printf '%s' "$candidate"
            return 0
        fi
        for candidate in "${dir}"/subagents/workflows/*/"agent-${agent}.jsonl"; do
            if [ -f "$candidate" ]; then
                printf '%s' "$candidate"
                return 0
            fi
        done
    done
    return 0
}

deny_write() {  # <reason>
    jq -n -c --arg path "$RESOLVED" --arg why "$1" \
        '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: ("sensitive-path-guard: Write of " + $path + " is refused; " + $why)}}'
    exit 0
}

TRANSCRIPT_PATH=$(printf '%s' "$INPUT" | jq -r '.transcript_path // ""' 2>/dev/null || true)
AGENT_ID=$(printf '%s' "$INPUT" | jq -r '.agent_id // ""' 2>/dev/null || true)
SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // ""' 2>/dev/null || true)
scan_transcript "$(own_transcript_path "$TRANSCRIPT_PATH" "$AGENT_ID" "$SESSION_ID")"
[ -n "$OWN_STEP" ] || deny_write "an executor-read seat writes only inside its own scratch dir, and this hook found no step claim in the seat's transcript to name that dir, so no Write path is open to this seat. Report that as a launch defect rather than retrying."

SCRATCH_ROOTS=("/tmp/claude-${UID}" "/private/tmp/claude-${UID}")
if [ -n "${TMPDIR:-}" ]; then
    SCRATCH_ROOTS+=("$(normalize "$TMPDIR")")
    physical=$(cd -P -- "$TMPDIR" 2>/dev/null && pwd -P) && SCRATCH_ROOTS+=("$physical")
fi
for root in "${SCRATCH_ROOTS[@]}"; do
    own="${root%/}/STEP-${OWN_STEP}.d"
    [ "${RESOLVED#"$own"/}" != "$RESOLVED" ] && exit 0
done
deny_write "an executor-read seat writes only inside its own scratch dir \$TMPDIR/STEP-${OWN_STEP}.d. Write the file there."
