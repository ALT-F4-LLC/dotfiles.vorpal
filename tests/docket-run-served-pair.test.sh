#!/bin/bash

# Behavior suite for the docket-run skill's metadata re-send script,
# skills/docket-run/scripts/resend_metadata.sh.
#
# CI wiring: `.github/workflows/vorpal.yaml` enumerates test files by
# name and this one is in that list. It needs `jq`, and stubs `docket` on
# PATH — no engine, no database, no network.
#
# WHY THIS EXISTS. The engine's back-fill drops a row's metadata bag when its
# step is not yet terminal, and writes the usage anyway. Writer steps are
# often still gated at back-fill, and the bare re-close after a refused
# verify never re-sent the bag, so a run's implement steps read their served
# model and effort as unknown. The failures to catch: a dropped or refused
# step left unannotated, a pair that is not the row's, a still-gated step
# annotated (the engine refuses it), and a step whose rows carried no bag
# annotated with nothing.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
RESEND="${RESEND_SH:-${SCRIPT_DIR}/../src/user/claude_code/skills/docket-run/scripts/resend_metadata.sh}"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$RESEND" ] || fatal "resend_metadata.sh not found at ${RESEND}"
command -v jq >/dev/null 2>&1 || fatal "jq is required to run this test"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/served-pair.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT

# The stub answers `step show` from $STUB_STEPS/<step>.json and logs every
# call's argv, one JSON array per line, to $STUB_LOG.
mkdir -p "$WORK/bin" "$WORK/steps"
cat > "$WORK/bin/docket" <<'STUB'
#!/bin/bash
printf '%s\0' "$@" | jq -R -s -c 'split("\u0000")[:-1]' >> "$STUB_LOG"
case "$1 $2" in
    "step show")
        [ -f "$STUB_STEPS/$3.json" ] || { echo '{"ok":false,"error":{"code":"NOT_FOUND"}}'; exit 1; }
        cat "$STUB_STEPS/$3.json" ;;
    "step annotate") echo '{"ok":true,"data":{}}' ;;
    *) echo '{"ok":false}'; exit 1 ;;
esac
STUB
chmod +x "$WORK/bin/docket"
export PATH="$WORK/bin:$PATH" STUB_STEPS="$WORK/steps" STUB_LOG="$WORK/argv.log"

# step <id> <status> <model_resolved> <effort_resolved>
step() {
    jq -n -c --arg s "$1" --arg st "$2" --arg m "$3" --arg e "$4" \
        '{ok: true, data: {step: $s, status: $st, metadata: {model_requested: "opus", effort_requested: "medium", model_resolved: $m, effort_resolved: $e}}}' \
        > "$WORK/steps/$1.json"
}
step STEP-1 done unknown unknown          # named under metadata_dropped
step STEP-2 done unknown unknown          # under a close that refused at verify
step STEP-3 gated unknown unknown         # still non-terminal
step STEP-4 done unknown unknown          # its rows carried no metadata object
step STEP-5 done claude-opus-4-7 medium   # its bag already landed

# rows <step>... : four usage rows per step, the first carrying the step's bag
# unless the step is STEP-4.
rows() {
    for s in "$@"; do
        jq -n -c --arg s "$s" '
            [range(0; 4) as $i
             | {step: $s, unit: (["input_tokens","output_tokens","cache_read_tokens","cache_creation_tokens"][$i]), quantity: 10}
               + (if $i == 0 and $s != "STEP-4"
                  then {metadata: {model_resolved: "claude-opus-4-7", effort_resolved: "medium"}} else {} end)]'
    done | jq -s -c add
}

pass=0
failed=0
check() {
    if [ "$2" = "$3" ]; then
        pass=$((pass + 1))
    else
        failed=$((failed + 1))
        printf 'FAIL %s\n  want: %s\n  got:  %s\n' "$1" "$2" "$3"
    fi
}

annotations() {
    jq -s -c '[.[] | select(.[0] == "step" and .[1] == "annotate")
               | {step: .[2], metadata: (.[index("--metadata") + 1] | fromjson)}]' "$STUB_LOG"
}

# Case 1: the combined close succeeded and named STEP-1, STEP-3 and STEP-4
# under metadata_dropped.
: > "$STUB_LOG"
rows STEP-1 STEP-3 STEP-4 > "$WORK/rows-ok.json"
echo '{"ok":true,"data":{"backfill":{"metadata_dropped":[{"step":"STEP-1","instance":"i","status":"gated"},{"step":"STEP-3","instance":"i","status":"gated"},{"step":"STEP-4","instance":"i","status":"gated"}]},"verify":{},"close":{}}}' > "$WORK/close-ok.json"
out=$(bash "$RESEND" --rows "$WORK/rows-ok.json" --close "$WORK/close-ok.json")
check "dropped: exit" 0 "$?"
check "dropped: one annotate carrying the row's pair" \
    '[{"step":"STEP-1","metadata":{"model_resolved":"claude-opus-4-7","effort_resolved":"medium"}}]' "$(annotations)"
check "dropped: report" '{"annotated":["STEP-1"],"current":[],"pending":["STEP-3"]}' "$out"

# Case 2: the combined close refused at its verify stage, so every step whose
# rows carry a bag is a candidate.
: > "$STUB_LOG"
rows STEP-2 STEP-3 STEP-4 STEP-5 > "$WORK/rows-refused.json"
echo '{"ok":false,"error":{"code":"CONFLICT","message":"verify: genuinely-missing STEP-3"}}' > "$WORK/close-refused.json"
out=$(bash "$RESEND" --rows "$WORK/rows-refused.json" --close "$WORK/close-refused.json")
check "refused: exit" 0 "$?"
check "refused: one annotate carrying the row's pair" \
    '[{"step":"STEP-2","metadata":{"model_resolved":"claude-opus-4-7","effort_resolved":"medium"}}]' "$(annotations)"
check "refused: report" '{"annotated":["STEP-2"],"current":["STEP-5"],"pending":["STEP-3"]}' "$out"

# The steps the script must never annotate, across both cases.
: > "$STUB_LOG"
bash "$RESEND" --rows "$WORK/rows-ok.json" --close "$WORK/close-ok.json" >/dev/null
bash "$RESEND" --rows "$WORK/rows-refused.json" >/dev/null
check "no annotate for the still-gated step" 0 \
    "$(jq -s '[.[] | select(.[1] == "annotate" and .[2] == "STEP-3")] | length' "$STUB_LOG")"
check "no annotate for the step without a bag" 0 \
    "$(jq -s '[.[] | select(.[1] == "annotate" and .[2] == "STEP-4")] | length' "$STUB_LOG")"

# A refusing annotate fails the run; a missing rows argument is a usage error.
cat > "$WORK/bin/docket" <<'STUB'
#!/bin/bash
case "$1 $2" in
    "step show") cat "$STUB_STEPS/$3.json" ;;
    *) echo '{"ok":false}'; exit 1 ;;
esac
STUB
bash "$RESEND" --rows "$WORK/rows-refused.json" >/dev/null 2>&1
check "annotate refusal: exit" 1 "$?"
bash "$RESEND" >/dev/null 2>&1
check "usage error: exit" 2 "$?"

printf '%d passed, %d failed\n' "$pass" "$failed"
[ "$failed" -eq 0 ]
