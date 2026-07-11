#!/bin/bash

set -uo pipefail

ASK_REASON="git writes require explicit human approval each time - approve this commit at the prompt."

allow_default() {
    exit 0
}

ask() {
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s"}}\n' "$ASK_REASON"
    exit 0
}

# Exit 2 is a pre-permission hard stop: it blocks the tool call before
# permission rules/mode are evaluated at all, unlike a JSON
# permissionDecision:"deny" whose interaction with bypassPermissions mode is
# undocumented. Used for every deny path below so the block holds regardless
# of permission mode.
deny() {
    printf '%s\n' "$1" >&2
    exit 2
}

INPUT=$(cat 2>/dev/null) || allow_default

if ! command -v jq >/dev/null 2>&1; then
    allow_default
fi

TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null) || allow_default
[ "$TOOL_NAME" = "Bash" ] || allow_default

COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null) || allow_default
[ -n "$COMMAND" ] || allow_default

# Tokenizes on whitespace and, for every `git` token (bare or path-suffixed),
# skips recognized global options (including ones that consume a following
# value, e.g. `-C <path>`) before exact-matching the first remaining token
# against commit/push/add. This avoids false-denying `git remote add` /
# `git submodule add` / `git worktree add`, and correctly denies
# `git -C <path> commit`, `git -c user.email=x commit`, `git --no-pager push`.
MATCH=$(printf '%s' "$COMMAND" | awk '
{
    n = split($0, words, /[ \t]+/)
    for (i = 1; i <= n; i++) {
        w = words[i]
        gsub(/^[\047\042]+|[\047\042]+$/, "", w)
        if (w == "git" || w ~ /\/git$/) {
            j = i + 1
            while (j <= n) {
                opt = words[j]
                gsub(/^[\047\042]+|[\047\042]+$/, "", opt)
                if (opt !~ /^-/) break
                if (opt == "-C" || opt == "-c" || opt == "--git-dir" || opt == "--work-tree" || opt == "--exec-path" || opt == "--namespace" || opt == "--super-prefix" || opt == "--config-env" || opt == "--attr-source") {
                    j += 2
                } else {
                    j += 1
                }
            }
            if (j <= n) {
                s = words[j]
                gsub(/^[\047\042]+|[\047\042]+$/, "", s)
                if (s == "commit" || s == "push" || s == "add") {
                    print "MATCH"
                    exit
                }
            }
        }
    }
}
' 2>/dev/null)

[ "$MATCH" = "MATCH" ] || allow_default

PERMISSION_MODE=$(printf '%s' "$INPUT" | jq -r '.permission_mode // empty' 2>/dev/null) \
    || deny "git write blocked - could not determine permission_mode from hook input."

case "$PERMISSION_MODE" in
    default | plan | acceptEdits)
        ask
        ;;
    auto | dontAsk | bypassPermissions)
        deny "git writes are blocked in non-interactive permission mode '${PERMISSION_MODE}' where a human can't confirm approval - switch to an interactive mode (default/plan/acceptEdits) to commit."
        ;;
    *)
        deny "git write blocked - could not determine permission_mode from hook input."
        ;;
esac
