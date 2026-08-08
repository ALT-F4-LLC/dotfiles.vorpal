#!/usr/bin/env bash
# shadow-transcript-summary — compact per-line view of a Claude Code session
# transcript: `type ~ HH:MM:SS ~ TEXT:/TOOL:/RESULT: …`, newlines flattened.
# Read-only, deterministic. Usage: shadow-transcript-summary <transcript.jsonl> [from-line]
set -euo pipefail
tr_file=${1:?usage: shadow-transcript-summary <transcript.jsonl> [from-line]}
from=${2:-1}
awk -v n="$from" 'NR>=n' "$tr_file" | jq -rc '
  [ .type,
    (.timestamp // "")[11:19],
    (if .message.content|type == "string" then (.message.content[0:300]|gsub("\n";" ⏎ "))
     elif .message.content|type == "array" then
       ([.message.content[] |
         if .type=="text" then "TEXT:"+(.text[0:300]|gsub("\n";" ⏎ "))
         elif .type=="tool_use" then "TOOL:"+.name+":"+((.input|tostring)[0:300]|gsub("\n";" ⏎ "))
         elif .type=="tool_result" then "RESULT:"+((.content|tostring)[0:200]|gsub("\n";" ⏎ "))
         else .type end] | join(" | "))
     else (.summary // .subtype // "") end)
  ] | join(" ~ ")' 2>/dev/null
