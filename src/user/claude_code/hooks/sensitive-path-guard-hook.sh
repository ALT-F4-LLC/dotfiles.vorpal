#!/bin/bash

# sensitive-path-guard — PreToolUse: Read|Grep|Glob.
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
# Decision: deny when the tool's target path (Read: file_path; Grep/Glob: path,
# defaulting to cwd) resolves to a listed root or anything beneath it. Every
# other input is silence and exit 0 — the hook must never block a normal read.

set -uo pipefail

SENSITIVE_ROOTS='
~/.aws/**
~/.claude.json
~/.config/gh/**
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
    Read) TARGET=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null || true) ;;
    Grep | Glob) TARGET=$(printf '%s' "$INPUT" | jq -r '.tool_input.path // ""' 2>/dev/null || true) ;;
    *) exit 0 ;;
esac

if [ -z "$TARGET" ]; then
    # Read without a path is a tool error, not a read. Grep/Glob without a
    # path search the working directory, so that is the path to judge.
    [ "$TOOL" = "Read" ] && exit 0
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

exit 0
