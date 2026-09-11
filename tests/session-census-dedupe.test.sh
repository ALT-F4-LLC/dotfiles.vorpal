#!/bin/bash

# Behavior suite for session-census.js's per-transcript extractor: assistant
# rows are deduplicated by message id, last occurrence wins.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. It needs only `jq`, `node` and `awk` — no
# engine, no database, no network, and it never runs a workflow.
#
# WHY THIS EXISTS. A streamed assistant message repeats across transcript
# lines under one message id with output_tokens growing on each rewrite, so a
# per-line sum inflated every token and character total (wave-usage.js
# measured 1.65-2.36x on one wave). The extractor now retracts the earlier
# line's share before adding the later one; this suite pins that arithmetic
# on a fixture whose inflated and deduplicated totals differ on every field.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CENSUS="${SESSION_CENSUS_JS:-${SCRIPT_DIR}/../src/user/claude_code/workflows/session-census.js}"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$CENSUS" ] || fatal "session-census.js not found at ${CENSUS}"
for tool in jq node awk; do
    command -v "$tool" >/dev/null 2>&1 || fatal "${tool} is required to run this test"
done

WORK=$(mktemp -d "${TMPDIR:-/tmp}/session-census-dedupe.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT

pass=0
fail=0
ok() { # <condition-already-evaluated: 0/1> <label>
    if [ "$1" -eq 0 ]; then
        pass=$((pass + 1)); printf 'PASS: %s\n' "$2"
    else
        fail=$((fail + 1)); printf 'FAIL: %s\n' "$2" >&2
    fi
}

extract() { # <region> — body between the TEST-BEGIN/TEST-END markers
    awk -v r="$1" '
        index($0, "TEST-END " r)   { open = 0; ends++ }
        open                       { print }
        index($0, "TEST-BEGIN " r) { open = 1; begins++ }
        END {
            if (begins != 1 || ends != 1) {
                printf "expected exactly one TEST-BEGIN/TEST-END pair for %s, found %d/%d\n", r, begins, ends > "/dev/stderr"
                exit 1
            }
        }
    ' "$CENSUS"
}

{
    extract session-census-config  || fatal "bad or missing TEST markers for session-census-config"
    extract session-census-extract || fatal "bad or missing TEST markers for session-census-extract"
} > "${WORK}/regions.js" || exit 2
{ cat "${WORK}/regions.js"; echo 'process.stdout.write(CENSUS_JQ)'; } > "${WORK}/emit.js"
node "${WORK}/emit.js" > "${WORK}/census.jq" || fatal "could not evaluate CENSUS_JQ"
[ -s "${WORK}/census.jq" ] || fatal "CENSUS_JQ is empty"

# ---- Fixture ------------------------------------------------------------------
# msg-a streams three times: thinking grows, then a text block appears and
# output_tokens grows again. Only the last line is the message. msg-b is a
# single line with a tool call and no thinking, so think_msgs must stay at 1.
# The id-less row exercises the fallback: no id, no dedupe, counted once.
node - "$WORK/main.jsonl" <<'JS' || fatal "fixture build failed"
const fs = require('fs')
const row = (id, out, think, blocks, extra = {}) => JSON.stringify({
    type: 'assistant', version: '2.1.300', timestamp: '2026-09-11T10:00:00Z', effort: 'high',
    message: { id, model: 'claude-opus-5', usage: { output_tokens: out, output_tokens_details: { thinking_tokens: think } }, content: blocks },
    ...extra,
})
const lines = [
    JSON.stringify({ type: 'user', timestamp: '2026-09-11T09:59:00Z', message: { content: 'hello' } }),
    row('msg-a', 10, 5, [{ type: 'thinking', thinking: 'ab' }]),
    row('msg-a', 40, 30, [{ type: 'thinking', thinking: 'abcdef' }]),
    row('msg-a', 100, 30, [{ type: 'thinking', thinking: 'abcdef' }, { type: 'text', text: 'done' }]),
    row('msg-b', 20, 0, [{ type: 'text', text: 'run' }, { type: 'tool_use', name: 'Bash' }]),
    row(undefined, 7, 0, [{ type: 'text', text: 'x' }]),
]
fs.writeFileSync(process.argv[2], lines.join('\n') + '\n')
JS

jq -c -n -R --arg kind main -f "${WORK}/census.jq" "${WORK}/main.jsonl" > "${WORK}/out.json"
ok $? 'the jq program runs clean over the fixture transcript'

get() { jq -r "$1" "${WORK}/out.json"; }

[ "$(get .msgs)" = "3" ]; ok $? "msgs counts messages, not lines (got $(get .msgs))"
[ "$(get .out)" = "127" ]; ok $? "out sums each message's last output_tokens: 100+20+7 (got $(get .out))"
[ "$(get .think)" = "30" ]; ok $? "think keeps only the final thinking count for msg-a (got $(get .think))"
[ "$(get .think_msgs)" = "1" ]; ok $? "think_msgs counts msg-a once (got $(get .think_msgs))"
[ "$(get .think_chars)" = "6" ]; ok $? "think_chars is the final thinking block's length, not 2+6+6 (got $(get .think_chars))"
[ "$(get .text_chars)" = "8" ]; ok $? "text_chars is 4+3+1 (got $(get .text_chars))"
[ "$(get .tool_uses)" = "1" ]; ok $? "tool_uses is unaffected by the rewrites (got $(get .tool_uses))"
[ "$(get '.rows.assistant')" = "5" ]; ok $? "rows still counts lines, so the histogram fields are line-based (got $(get '.rows.assistant'))"
[ "$(get '.seen // "absent"')" = "absent" ]; ok $? 'the seen map is stripped from the emitted object'

cell=$(get '.cells[] | select(.model == "claude-opus-5") | "\(.msgs) \(.out) \(.think) \(.think_msgs) \(.think_chars) \(.text_chars)"')
[ "$cell" = "3 127 30 1 6 8" ]; ok $? "the model|effort|skill cell carries the same deduplicated totals (got '${cell}')"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
