#!/usr/bin/env bash
#
# bind-probe — for each issue, count the registered workflows its labels
# bind and print the declared-cost forecast of the one it binds, so
# docket-plan reads bindings and costs from the registry in one call instead
# of rebuilding the probe and the arithmetic by hand each session.
#
# Usage: docket issue list --json=v2 --limit 1000 -s backlog -s todo | bind-probe.sh
#        docket issue show <id> --json | bind-probe.sh
#        bind-probe.sh [--workflows <file>] [<issues.json>]
#   Issues come from the named file or stdin: a `docket issue list` or
#   `docket issue show` envelope, or a bare array of issue rows. Workflows
#   come from `docket workflow list --json=v2 --limit 0` unless --workflows
#   names a file holding that output. Run it from the repository checkout:
#   the registry listing is empty from anywhere else.
#
# The bindable set is the highest registered version of each workflow name
# whose row carries no `deprecated_at_ms`. A workflow binds an issue when
# its `[match]` accepts the labels: some `labels_any` label present (when
# `labels_any` is set), every `labels_all` label present, and no
# `unless_labels` label present.
#
# Output, one tab-separated line per issue after a header:
#   id  n  bound  floor  loops  round  headroom  total
#   n         how many workflows bind (1 is the only runnable count)
#   bound     name@version of each, comma-joined, empty when n is 0
#   floor     sum of step `expected_cost`, fanout expanded, `when`-gated and
#             loop steps included once (what `docket workflow show` prints)
#   loops     the `max_fix_loops` the definition declares, 0 when none
#   round     cost of one rework round: the costliest `loop = true` step (the
#             `when`-gated variants of one loop are alternatives) plus the
#             `after_loop` step and every step transitively after it
#   headroom  round x loops minus the loop steps' cost already inside
#             the floor
#   total     floor + headroom: the worst-case declared cost with every rework
#             round spent (headroom alone can read small when the floor already
#             holds several `when`-gated variants of the loop step)
# floor, loops, round, headroom and total are `-` unless n is 1. Read-only.
#
# Exit 0 on success, 2 on a usage error or input that is not issues JSON.

set -euo pipefail

usage() { printf 'usage: %s [--workflows <file>] [<issues.json>]\n' "${0##*/}" >&2; exit 2; }

wf_file=""
in_file=""
while [ $# -gt 0 ]; do
  case "$1" in
    --workflows) [ $# -ge 2 ] || usage; wf_file=$2; shift 2 ;;
    -h|--help) usage ;;
    -*) usage ;;
    *) [ -z "$in_file" ] || usage; in_file=$1; shift ;;
  esac
done

tmpd=$(mktemp -d "${TMPDIR:-/tmp}/bind-probe.XXXXXX")
trap 'rm -rf "$tmpd"' EXIT

if [ -n "$in_file" ]; then cat "$in_file" > "$tmpd/issues.json"; else cat > "$tmpd/issues.json"; fi
if [ -n "$wf_file" ]; then
  cat "$wf_file" > "$tmpd/wf.json"
else
  docket workflow list --json=v2 --limit 0 > "$tmpd/wf.json"
fi

jq -e . "$tmpd/issues.json" >/dev/null 2>&1 || { echo "bind-probe: issues input is not JSON" >&2; exit 2; }
jq -e '(if type == "array" then . else (.data.items // .data // .) end) | (type == "array" or (type == "object" and has("id")))' \
  "$tmpd/issues.json" >/dev/null 2>&1 || { echo "bind-probe: no issue rows in input" >&2; exit 2; }
jq -e '.data.items | type == "array"' "$tmpd/wf.json" >/dev/null 2>&1 \
  || { echo "bind-probe: workflow list has no .data.items" >&2; exit 2; }

jq -r --slurpfile wf "$tmpd/wf.json" '
  def cost: (.expected_cost // 0) * ((.fanout // [1]) | length);
  def closure($steps; $start):
    {set: [$start]} | until(
      (. as $s | [$steps[] | select((.after // []) | any(. as $a | $s.set | index($a))) | .name]
        | map(select(. as $n | $s.set | index($n) | not)) | length) == 0;
      . as $s | .set += [$steps[] | select((.after // []) | any(. as $a | $s.set | index($a))) | .name]
        | .set |= unique
    ) | .set;
  def facts:
    .steps as $steps
    | ([$steps[] | cost] | add // 0) as $floor
    | ([$steps[] | .max_fix_loops // empty] | max // 0) as $loops
    | ([$steps[] | select(.loop == true)]) as $loopsteps
    | ([$loopsteps[] | cost] | add // 0) as $loopsum
    | ([$loopsteps[] | cost] | max // 0) as $loopcost
    | ([$loopsteps[] | .after_loop // empty] | unique) as $entry
    | ([$entry[] as $e | closure($steps; $e)[]] | unique) as $names
    | ([$steps[] | select(.name as $n | $names | index($n)) | cost] | add // 0) as $closurecost
    | ($loopcost + $closurecost) as $round
    | {floor: $floor, loops: $loops, round: $round,
       headroom: ($round * $loops - $loopsum)};
  def accepts($labels):
    (.labels_any // []) as $any | (.labels_all // []) as $all | (.unless_labels // []) as $un
    | (($any | length) == 0 or ($any | any(. as $l | $labels | index($l))))
      and ($all | all(. as $l | $labels | index($l)))
      and ($un | any(. as $l | $labels | index($l)) | not);
  ($wf[0].data.items
    | map(select((.deprecated_at_ms // .definition.deprecated_at_ms // null) == null))
    | group_by(.name) | map(max_by(.version))) as $bindable
  | (if type == "array" then . else (.data.items // .data // .) end) as $rows
  | ($rows | if type == "array" then . else [.] end)
  | ["id", "n", "bound", "floor", "loops", "round", "headroom", "total"],
    (.[] | . as $i | ($i.labels // []) as $labels
      | [$bindable[] | select(.definition.match | accepts($labels))] as $hits
      | [$i.id, ($hits | length), ($hits | map("\(.name)@\(.version)") | join(","))]
        + (if ($hits | length) == 1
           then ($hits[0].definition | facts) | [.floor, .loops, .round, .headroom, (.floor + .headroom)]
                | map((. * 100 | round) / 100 | tostring)
           else ["-", "-", "-", "-", "-"] end))
  | @tsv
' "$tmpd/issues.json"
