#!/bin/bash

# sandbox-bypass-ask — PreToolUse: Bash.
#
# A Bash call carrying dangerouslyDisableSandbox=true runs OUTSIDE the
# sandbox. The 2026-08-19 fleet review measured the auto-mode classifier
# approving twenty such calls from wave executors in one run while their
# briefs prohibited the bypass outright — the prohibition had no mechanical
# backing. This hook gives it one: every bypass request becomes an explicit
# permission question. An interactive operator confirms the rare legitimate
# lift in one keypress; an unattended executor's request parks instead of
# sailing through. The hook holds no policy about WHICH commands deserve a
# lift — that judgment stays with the operator answering the question.
set -uo pipefail

INPUT=$(cat)
BYPASS=$(jq -r '.tool_input.dangerouslyDisableSandbox // false' <<<"$INPUT" 2>/dev/null || echo false)

if [ "$BYPASS" = "true" ]; then
    jq -n '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "ask", permissionDecisionReason: "This command asks to run OUTSIDE the sandbox (dangerouslyDisableSandbox). Confirm the lift is warranted."}}'
fi

exit 0
