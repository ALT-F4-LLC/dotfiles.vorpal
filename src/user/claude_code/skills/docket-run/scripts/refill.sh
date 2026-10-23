#!/usr/bin/env bash
#
# refill — one refill of freed launch slots at a launch return: extend the
# open dispatch, keep the appended rows, settle or hold the returned launch's
# steps, rebuild the pending rows, and re-split them into fresh launches.
#
# Usage: refill.sh --run RUN-N --rows FILE --settled FILE --held FILE
#                  --pending FILE --launch-dir DIR
#                  [--statuses FILE] [--reaped] [--tribunal PATH]
#                  [--integrated FILE] [--in-flight LANES] [--write-cap N]
#
# This is docket-run's refill loop (the skill's steps 1, 2, 4 and 5) as one
# command, so the bookkeeping that once failed by hand cannot: a conductor
# piped `docket dispatch extend` into a row count, the appended rows never
# reached the kept rows file, and they waited for the next dispatch.
#
#   1. Runs `docket dispatch extend --run RUN-N --json` itself, keeps its
#      stdout in a file, and appends every row whose kind is not "human" and
#      whose step is not already in --rows, as one JSON line each. The rows
#      file is the manifest of record; nothing else is written there.
#   2. With --statuses (the returned launch's statuses array), appends the
#      steps it settled to --settled: every row except a skipped-not-ready
#      row and the skipped-chain-dead rows of an issue that has one in this
#      launch (the issue of each step is read from --rows).
#   3. A return is a bounce when its launch claimed nothing because every
#      claim was refused: every row waits as step 2 reads it, and at least
#      one was refused. On a bounce it appends the launch's steps to
#      --held; on any other return it empties --held. --reaped says a dead
#      holder was reaped at this return (the skill's step 3), so the return
#      is never a bounce. Without --statuses, --held is left as it is.
#   4. Rebuilds --pending: every row of --rows whose step is in neither
#      --settled nor --held.
#   5. Runs lane_units.py (the sibling file) over --pending into
#      --launch-dir with --tribunal, --integrated, --in-flight and
#      --write-cap as given. The launch count N is the only stdout.
#
# The reap itself (the skill's step 3) stays the conductor's: it needs the
# dead-holder evidence. Run it before this script, after writing --statuses.
# Run from inside the run's git work tree.
#
# The engine commits extend's rows to the manifest and never returns them
# again, so the answer is saved to <--rows>.extend.json before it is parsed
# and removed only once its rows are in --rows. Any failure after extend
# exits 1 and names that file; append its rows to --rows by hand, delete it,
# and re-run (the script refuses to run while the file exists).
# A failure of lane_units.py after the append leaves --rows, --settled,
# --held and --pending written, and re-running is safe: repeated lines in
# --settled and --held are ignored. A non-empty reaped list or reap_hold in
# the extend answer is printed on stderr: guard spawn denies the next launch
# on a reap_hold, so verify it before launching.
#
# Exit 0 on success; 1 on any failure (a bad --rows or --statuses file,
# extend failing or answering something but {ok:true, data:{rows:[...]}},
# lane_units.py failing); 2 on a usage error.

set -euo pipefail

usage() {
    printf 'usage: refill.sh --run RUN-N --rows FILE --settled FILE --held FILE --pending FILE --launch-dir DIR [--statuses FILE] [--reaped] [--tribunal PATH] [--integrated FILE] [--in-flight LANES] [--write-cap N]\n' >&2
    exit 2
}

run="" rows="" settled="" held="" pending="" launch_dir=""
statuses="" reaped=0 tribunal="" integrated="" in_flight="" write_cap=""
while [ $# -gt 0 ]; do
    case "$1" in
        --run) [ $# -ge 2 ] || usage; run="$2"; shift 2 ;;
        --rows) [ $# -ge 2 ] || usage; rows="$2"; shift 2 ;;
        --settled) [ $# -ge 2 ] || usage; settled="$2"; shift 2 ;;
        --held) [ $# -ge 2 ] || usage; held="$2"; shift 2 ;;
        --pending) [ $# -ge 2 ] || usage; pending="$2"; shift 2 ;;
        --launch-dir) [ $# -ge 2 ] || usage; launch_dir="$2"; shift 2 ;;
        --statuses) [ $# -ge 2 ] || usage; statuses="$2"; shift 2 ;;
        --reaped) reaped=1; shift ;;
        --tribunal) [ $# -ge 2 ] || usage; tribunal="$2"; shift 2 ;;
        --integrated) [ $# -ge 2 ] || usage; integrated="$2"; shift 2 ;;
        --in-flight) [ $# -ge 2 ] || usage; in_flight="$2"; shift 2 ;;
        --write-cap) [ $# -ge 2 ] || usage; write_cap="$2"; shift 2 ;;
        -h | --help) usage ;;
        *) usage ;;
    esac
done
[ -n "$run" ] && [ -n "$rows" ] && [ -n "$settled" ] && [ -n "$held" ] && [ -n "$pending" ] && [ -n "$launch_dir" ] || usage
command -v jq >/dev/null 2>&1 || { printf 'refill: jq is required\n' >&2; exit 1; }
[ -f "$rows" ] || { printf 'refill: --rows %s does not exist; it is the manifest of record\n' "$rows" >&2; exit 1; }
[ -f "$settled" ] || : > "$settled"
[ -f "$held" ] || : > "$held"
if [ -n "$statuses" ] && ! jq -e 'type == "array"' "$statuses" >/dev/null 2>&1; then
    printf 'refill: --statuses %s is not a JSON array of launch statuses\n' "$statuses" >&2
    exit 1
fi

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
work=$(mktemp -d "${TMPDIR:-/tmp}/refill.XXXXXX")
trap 'rm -rf "$work"' EXIT

# 1. Extend, keep the answer, append the new launchable rows. The engine
# commits the appended rows to the manifest and never returns them again, so
# the answer is written beside --rows before anything parses it and stays
# there; every failure after extend names that file. Validating --rows first
# means a bad rows file stops the script before extend spends the rows.
extend_file="$rows.extend.json"
if [ -e "$extend_file" ]; then
    printf 'refill: %s is a saved extend answer whose rows may not be in %s; append them, delete the file, then re-run\n' "$extend_file" "$rows" >&2
    exit 1
fi
if ! jq -r '.step' "$rows" > "$work/have.txt"; then
    printf 'refill: --rows %s holds a line that is not JSON; nothing was extended\n' "$rows" >&2
    exit 1
fi
if ! docket dispatch extend --run "$run" --json > "$extend_file"; then
    printf 'refill: docket dispatch extend --run %s failed; the rows file is unchanged (any partial answer is in %s)\n' "$run" "$extend_file" >&2
    exit 1
fi
lost() { printf 'refill: %s; the engine already appended its rows, so they are kept in %s: append them to %s by hand, then re-run\n' "$1" "$extend_file" "$rows" >&2; exit 1; }
jq -e '.ok == true and ((.data.rows // []) | type == "array")' "$extend_file" >/dev/null 2>&1 \
    || lost "docket dispatch extend answered something other than {ok:true, data:{rows:[...]}}"
jq -c --rawfile have "$work/have.txt" '(.data.rows // [])[] | select(.kind != "human") | select(.step as $s | (($have | split("\n")) | index([$s])) | not)' "$extend_file" > "$work/new.jsonl" \
    || lost "the extend answer could not be filtered"
appended=$(wc -l < "$work/new.jsonl" | tr -d ' ')
cat "$work/new.jsonl" >> "$rows" || lost "the rows file could not be appended to"
# The engine's reaps and the hold they leave: guard spawn denies the next
# launch on a reap_hold, so say so before the launches are written.
jq -r '(.data.reaped // [])[] | "refill: extend reaped an expired lease on \(.)"' "$extend_file" >&2 || true
jq -r 'select((.data.reap_hold // "") != "") | "refill: reap hold: \(.data.reap_hold)"' "$extend_file" >&2 || true
rm -f "$extend_file"

# 2 and 3. Settle the returned launch's steps; hold or release. A row waits
# when it was refused (skipped-not-ready) or is a skipped-chain-dead row of an
# issue that has a refused row in this launch: those wait on the refusal. A
# skipped-chain-dead row of any other issue (a writer that recorded pending, a
# failed predecessor) is deferred to the next dispatch, so it settles. The
# issue of a step is read from --rows.
waits='(reduce $rows[] as $r ({}; .[$r.step] = ($r.issue // ""))) as $iss
    | ([.[] | select(.status == "skipped-not-ready") | $iss[.step] // ""] | unique) as $refused
    | map(. + {waits: (.status == "skipped-not-ready"
        or (.status == "skipped-chain-dead" and (($iss[.step] // "") as $i | $refused | any(.[]; . == $i))))})'
if [ -n "$statuses" ]; then
    jq -r --slurpfile rows "$rows" "$waits"' | .[] | select(.waits | not) | .step' "$statuses" >> "$settled"
    if [ "$reaped" -eq 0 ] && jq -e --slurpfile rows "$rows" "$waits"' | any(.[]; .status == "skipped-not-ready") and all(.[]; .waits)' "$statuses" >/dev/null; then
        jq -r '.[].step' "$statuses" >> "$held"
    else
        : > "$held"
    fi
fi

# 4. Pending: every row of the manifest of record that is neither settled nor held.
jq -c --rawfile settled "$settled" --rawfile held "$held" 'select(.step as $id | ($settled | split("\n")) + ($held | split("\n")) | index([$id]) | not)' "$rows" > "$pending"

# 5. Re-split the pending rows.
args=("$pending" "$launch_dir")
[ -z "$tribunal" ] || args+=(--tribunal "$tribunal")
[ -z "$integrated" ] || args+=(--integrated "$integrated")
[ -z "$in_flight" ] || args+=(--in-flight "$in_flight")
[ -z "$write_cap" ] || args+=(--write-cap "$write_cap")
npending=$(wc -l < "$pending" | tr -d ' ')
printf 'refill: appended %s row(s) to %s; %s pending\n' "$appended" "$rows" "$npending" >&2
python3 "$here/lane_units.py" "${args[@]}"
