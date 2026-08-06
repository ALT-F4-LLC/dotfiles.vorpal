#!/bin/bash
# Wraps the "recent_transcripts.sh file list -> jq tool-call extraction ->
# per-command distinct-session counting" pipeline rebuilt from scratch by
# 4 independent sessions in the 2026-07-15 window (repetition-auditor FIX 1,
# src/user/claude-code/skills/team-doctrine/references/evolve-phase0-templates.md
# §"Repetition-Audit"). Reuses recent_transcripts.sh for file discovery.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RECENT_TRANSCRIPTS="${SCRIPT_DIR}/recent_transcripts.sh"

usage() {
    echo "Usage: tool_call_frequency.sh [--tool <name>] [--pattern <regex>] [--since <days>]" >&2
    echo "  Mines transcripts (file list via recent_transcripts.sh) for tool_use" >&2
    echo "  calls and emits one row per distinct command/pattern with a" >&2
    echo "  distinct-session count, sorted descending (count command)." >&2
    echo "  Requires at least one of --tool or --pattern." >&2
    echo "  --tool <name>     Filter to tool_use blocks with this tool name" >&2
    echo "                    (e.g. Bash, Grep, Skill). Omit to match any tool." >&2
    echo "  --pattern <regex> Filter extracted command text by extended regex" >&2
    echo "                    (jq test()). Omit to match any command." >&2
    echo "  --since <days>    Passed through to recent_transcripts.sh" >&2
    echo "                    (default 7, valid range 1-90)." >&2
    exit 1
}

TOOL=""
PATTERN=""
SINCE=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        --tool)
            [ "$#" -ge 2 ] || usage
            TOOL="$2"
            shift 2
            ;;
        --pattern)
            [ "$#" -ge 2 ] || usage
            PATTERN="$2"
            shift 2
            ;;
        --since)
            [ "$#" -ge 2 ] || usage
            SINCE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            usage
            ;;
    esac
done

if [ -z "$TOOL" ] && [ -z "$PATTERN" ]; then
    echo "tool_call_frequency.sh: at least one of --tool or --pattern is required" >&2
    exit 1
fi

if [ ! -x "$RECENT_TRANSCRIPTS" ]; then
    echo "tool_call_frequency.sh: missing sibling script ${RECENT_TRANSCRIPTS}" >&2
    exit 1
fi

FILE_ARGS=()
if [ -n "$SINCE" ]; then
    FILE_ARGS+=("$SINCE")
fi
FILE_ARGS+=("-0")

# Extracted "command" text falls back across known per-tool input fields
# (Bash=command, Grep=pattern, Read/Edit/Write=file_path, WebFetch=url,
# WebSearch=query, Task/Skill=prompt) so the interface stays generic across
# tools instead of hardcoding one; unrecognized tools fall back to the full
# input object.
JQ_FILTER='
  select(.sessionId != null and .message.content != null)
  | .sessionId as $sid
  | .message.content[]?
  | select(.type == "tool_use")
  | select($tool == "" or .name == $tool)
  | ((.input.command // .input.pattern // .input.file_path // .input.url // .input.query // .input.prompt // (.input | tostring)) | gsub("[\n\t]"; " ")) as $cmd
  | select($pattern == "" or ($cmd | test($pattern)))
  | [$sid, $cmd]
  | @tsv
'

# Stage 1 (jq -R 'fromjson?') tolerates a malformed/partial line from a
# concurrently-appended transcript without aborting the whole run; stage 2
# applies the tool/pattern filter above.
ROWS="$("$RECENT_TRANSCRIPTS" "${FILE_ARGS[@]}" \
    | xargs -0 jq -R 'fromjson?' 2>/dev/null \
    | jq -r --arg tool "$TOOL" --arg pattern "$PATTERN" "$JQ_FILTER" \
    | sort -u \
    | cut -f2- \
    | sort \
    | uniq -c \
    | sort -rn)"

if [ -z "$ROWS" ]; then
    echo "tool_call_frequency.sh: no matching tool calls found in the window" >&2
    exit 0
fi

printf '%s\n' "$ROWS"
