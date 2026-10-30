#!/usr/bin/env bash
#
# resend_metadata — re-send the served-model metadata a wave's back-fill could
# not land, once each step it belongs to has turned terminal.
#
# Usage: resend_metadata.sh --rows FILE [--close FILE]
#
# The engine's back-fill drops a row's metadata bag when its step is not yet
# terminal and still writes the usage. Writer steps are often still gated when
# their wave is back-filled, so their model_resolved/effort_resolved stayed
# unknown, and the bare re-close after a refusal never re-sent them.
#
#   --rows   the dispatch's merged rows file, the bare array the combined
#            `dispatch close --backfill-from` read.
#   --close  that combined close's saved --json output. When it answered
#            {ok: true}, the candidates are the steps it named under
#            .data.backfill.metadata_dropped. When it refused, or --close is
#            not given, the candidates are every step whose rows carry a
#            metadata object, since a refusal does not say which bags dropped.
#
# A step whose rows carry no metadata object is never a candidate. For each
# candidate the script reads `docket step show STEP-N --json`: a step in a
# terminal status (done, skipped, superseded, failed-routed) whose stored
# model_resolved or effort_resolved differs from its row's gets one
# `docket step annotate STEP-N --metadata <that row's metadata object>`; a
# step that already carries them is left alone; a non-terminal step gets no
# call and is listed as pending, for a later re-run. The script holds no
# state, so re-running it is safe.
#
# Stdout: {annotated: [...], current: [...], pending: [...]}, step ids each.
# Exit 0 on success; 1 on any failure (a bad --rows or --close file, a step
# show or annotate refusing); 2 on a usage error.

set -euo pipefail

usage() {
    printf 'usage: resend_metadata.sh --rows FILE [--close FILE]\n' >&2
    exit 2
}

fail() {
    printf 'resend_metadata: %s\n' "$1" >&2
    exit 1
}

rows=""
close=""
while [ $# -gt 0 ]; do
    case "$1" in
        --rows) [ $# -ge 2 ] || usage; rows="$2"; shift 2 ;;
        --close) [ $# -ge 2 ] || usage; close="$2"; shift 2 ;;
        *) usage ;;
    esac
done
[ -n "$rows" ] || usage

[ -f "$rows" ] || fail "rows file not found: ${rows}"
jq -e 'type == "array"' "$rows" >/dev/null 2>&1 || fail "rows file is not a JSON array: ${rows}"

# The first metadata object each step's rows carry, keyed by step.
bags=$(jq -c 'map(select(has("step") and (.metadata | type) == "object"))
              | reduce .[] as $r ({}; if has($r.step) then . else .[$r.step] = $r.metadata end)' "$rows")

if [ -n "$close" ]; then
    [ -f "$close" ] || fail "close output not found: ${close}"
    jq -e . "$close" >/dev/null 2>&1 || fail "close output is not JSON: ${close}"
fi
if [ -n "$close" ] && jq -e '.ok == true' "$close" >/dev/null 2>&1; then
    candidates=$(jq -r --argjson bags "$bags" \
        '[.data.backfill.metadata_dropped // [] | .[].step] | unique | .[] | . as $s | select($bags | has($s))' "$close")
else
    candidates=$(jq -r 'keys | .[]' <<<"$bags")
fi

annotated=()
current=()
pending=()
for step in $candidates; do
    shown=$(docket step show "$step" --json) || fail "docket step show ${step} refused"
    status=$(jq -r '.data.status // empty' <<<"$shown")
    [ -n "$status" ] || fail "docket step show ${step} answered no status"
    case "$status" in
        done|skipped|superseded|failed-routed) ;;
        *) pending+=("$step"); continue ;;
    esac
    bag=$(jq -c --arg s "$step" '.[$s]' <<<"$bags")
    if jq -e --argjson bag "$bag" \
        '(.data.metadata // {}) as $m | all($bag | keys[]; $m[.] == $bag[.])' <<<"$shown" >/dev/null; then
        current+=("$step")
        continue
    fi
    docket step annotate "$step" --metadata "$bag" --json >/dev/null || fail "docket step annotate ${step} refused"
    annotated+=("$step")
done

jq -n -c '{annotated: $ARGS.positional[0], current: $ARGS.positional[1], pending: $ARGS.positional[2]}' \
    --jsonargs \
    "$(printf '%s\n' "${annotated[@]+"${annotated[@]}"}" | jq -R -s -c 'split("\n") | map(select(. != ""))')" \
    "$(printf '%s\n' "${current[@]+"${current[@]}"}" | jq -R -s -c 'split("\n") | map(select(. != ""))')" \
    "$(printf '%s\n' "${pending[@]+"${pending[@]}"}" | jq -R -s -c 'split("\n") | map(select(. != ""))')"
