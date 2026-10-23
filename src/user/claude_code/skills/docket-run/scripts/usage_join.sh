#!/usr/bin/env bash
#
# usage_join — measure a completed wave's token spend from its agent
# transcripts and print the back-fill rows, with no agent spawned.
#
# Usage: usage_join.sh <wave dir> [--mode steps|seats] [--exclude KEY,KEY...]
#                      [--full]
#
# <wave dir> is the transcript directory the wave wrote its agent-*.jsonl
# files to (the directory docket-workflow-usage.js takes as args.dir).
# --mode steps (the default) emits one row per (step, unit) for `docket
# dispatch backfill-usage --from-json -`; --mode seats emits one row per
# (proposal, voter, unit), plus a tool_uses row per seat, for `docket vote
# backfill-usage --from-json -`. --exclude names the steps (steps mode) or
# seats (seats mode) a prior dispatch's back-fill already carries; each is
# skipped and named on stderr.
#
# stdout is the rows as one compact JSON array, the rows docket-workflow-
# usage.js returns, so
#   usage_join.sh "$DIR" | docket dispatch backfill-usage --from-json -
# works as the workflow's output did. --full prints the whole return
# ({rows, overhead, skipped, errors, model_observations}) instead. stderr
# carries the report: wave overhead, skipped agents, and the row count.
#
# This replaces the workflow's scout and per-transcript extract agents with
# the same fixed jq programs run directly: usage_extract.jq is the workflow's
# EXTRACT_JQ verbatim, and usage_reduce.jq is its classify and reduceRows.
# Usage is deduplicated by message id with the last occurrence winning, an
# agent is partitioned once into step executor, seat, or wave overhead by what
# its bootstrap brief told it to do, and a claim agent or probe is overhead,
# never a step's. tests/docket-run-usage-join.test.sh diffs the rows against
# the workflow's, byte for byte, over the same transcripts.
#
# Exit 0 with the rows on stdout. Exit 1, with nothing on stdout, when the
# directory is missing or holds no agent-*.jsonl, a transcript cannot be read,
# or the reduction reports an error (a step executor whose brief names no
# claim or record, a transcript with no usage, a lane mismatch); each error is
# named on stderr. Exit 2 on a usage error.

set -euo pipefail

usage() {
    printf 'usage: usage_join.sh <wave dir> [--mode steps|seats] [--exclude KEY,KEY...] [--full]\n' >&2
    exit 2
}

dir="" mode="steps" exclude="" full=0
while [ $# -gt 0 ]; do
    case "$1" in
        --mode) [ $# -ge 2 ] || usage; mode="$2"; shift 2 ;;
        --exclude) [ $# -ge 2 ] || usage; exclude="$2"; shift 2 ;;
        --full) full=1; shift ;;
        -h | --help) usage ;;
        -*) usage ;;
        *) [ -z "$dir" ] || usage; dir="$1"; shift ;;
    esac
done
[ -n "$dir" ] || usage
case "$mode" in steps | seats) ;; *) printf 'usage_join: --mode must be steps or seats, got %s\n' "$mode" >&2; exit 2 ;; esac
command -v jq >/dev/null 2>&1 || { printf 'usage_join: jq is required\n' >&2; exit 1; }
[ -d "$dir" ] || { printf 'usage_join: %s is not a directory\n' "$dir" >&2; exit 1; }

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
work=$(mktemp -d "${TMPDIR:-/tmp}/usage-join.XXXXXX")
trap 'rm -rf "$work"' EXIT

find "$dir" -maxdepth 1 -type f -name 'agent-*.jsonl' | LC_ALL=C sort > "$work/files.txt"
if [ ! -s "$work/files.txt" ]; then
    printf 'usage_join: %s holds no agent-*.jsonl transcripts\n' "$dir" >&2
    exit 1
fi

# One extract per transcript, raw lines so a line that is not JSON is skipped
# instead of aborting the file, wrapped with the transcript's basename.
: > "$work/extracts.jsonl"
failed=0
while IFS= read -r file; do
    base=${file##*/}
    if jq -c -n -R -f "$here/usage_extract.jq" "$file" > "$work/one.json" 2> "$work/err" && [ -s "$work/one.json" ]; then
        jq -c --arg file "$base" '{file: $file, extract: .}' "$work/one.json" >> "$work/extracts.jsonl"
    else
        printf 'usage_join: %s: jq failed: %s\n' "$base" "$(head -c 300 "$work/err")" >&2
        failed=1
    fi
done < "$work/files.txt"
[ "$failed" -eq 0 ] || exit 1

# --exclude entries are trimmed, and in steps mode each must be a STEP-N id: a
# padded or mistyped entry would otherwise exclude nothing and bill the step
# twice without a word.
exclude_json=$(jq -n -c --arg e "$exclude" '$e | split(",") | map(gsub("^\\s+|\\s+$"; "") | select(. != ""))')
if [ "$mode" = steps ] && ! jq -e 'all(.[]; test("^STEP-[0-9]+$"))' <<< "$exclude_json" >/dev/null; then
    printf 'usage_join: --exclude in steps mode takes STEP-N ids, got %s\n' "$exclude" >&2
    exit 2
fi
jq -c -s --arg mode "$mode" --argjson exclude "$exclude_json" -f "$here/usage_reduce.jq" "$work/extracts.jsonl" > "$work/result.json"

jq -r '.model_observations[] | "usage_join: \(.file): serving models \(if (.models | length) > 0 then (.models | join(", ")) else "unknown" end) (\(if .complete then "all parsed response model fields present" else "model fields missing" end)); last \(.last_model // "unknown"), effort \(.effort_resolved)"' "$work/result.json" >&2
jq -r '.errors[] | "usage_join: " + .' "$work/result.json" >&2
jq -r '.skipped[] | "usage_join: " + .file + " (" + .label + "): " + .reason + " (not measured here)"' "$work/result.json" >&2
jq -r '.overhead.agents[] | "usage_join: " + .file + ": " + .label + ": recorded no step, so its usage is wave overhead and is attributed to none"' "$work/result.json" >&2
jq -r 'select((.overhead.agents | length) > 0) | .overhead.sums as $s | "usage_join: WAVE OVERHEAD: \(.overhead.agents | length) agent(s), input_tokens \($s.input_tokens), output_tokens \($s.output_tokens), cache_creation_tokens \($s.cache_creation_tokens), cache_read_tokens \($s.cache_read_tokens): reported, not back-filled"' "$work/result.json" >&2
jq -r --arg mode "$mode" '"usage_join: \(.rows | length) row(s) over \(.rows | map(if $mode == "seats" then .proposal + " " + .voter else .step end) | unique | length) key(s)"' "$work/result.json" >&2

if [ "$(jq '.errors | length' "$work/result.json")" -ne 0 ]; then
    exit 1
fi
if [ "$full" -eq 1 ]; then
    cat "$work/result.json"
else
    jq -c '.rows' "$work/result.json"
fi
