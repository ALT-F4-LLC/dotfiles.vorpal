#!/usr/bin/env bash
#
# open-deps — for each issue id, name every depends_on target that is not
# done, with the route that target is on, so the completion gate can tell
# Run-ready from Waiting on a run prerequisite from Waiting on direct work
# mechanically instead of from a judge's readiness alone.
#
# Usage: open-deps.sh --checkout <dir> [--checkout <dir>]... < ids
#
# Reads one issue id per line on stdin. Each --checkout names a project
# checkout; an id is shown from the first checkout whose docket store
# resolves it (ids carry their project prefix, so the first hit is the
# owner). Prints one tab-separated line per id with an open target:
#
#   <id>\t<target>(<status>,<route>)[,<target>(<status>,<route>)...]
#
# <route> is the target's routing label (route-run, route-direct,
# route-loop) unless the row is an epic, which prints "epic" whatever its
# labels, else "unrouted"; a target that
# also carries the blocked label gets "+blocked" appended. A run plans only
# route-run targets, so any other route on an open target means the
# dependent waits on work done outside a run: docket-plan defers it as
# "waiting on direct work" on every pass until that target is done.
#
# Ids whose targets are all done print nothing. An id no checkout resolves
# prints "<id>\tunresolved", and a target no checkout resolves prints with
# status "missing"; both set the exit code so the gate records a
# Reported limit rather than a guess. Exit 0 when every id and target
# resolved, 1 otherwise. Read-only: it runs docket issue show only.
# bash 3.2: no associative arrays, so the status cache is a file.

set -u

checkouts=()
while [ $# -gt 0 ]; do
    case "$1" in
        --checkout) [ $# -ge 2 ] || { echo "open-deps: --checkout needs a directory" >&2; exit 2; }; checkouts+=("$2"); shift 2 ;;
        -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
        *) echo "open-deps: unknown argument $1" >&2; exit 2 ;;
    esac
done
if [ ${#checkouts[@]} -eq 0 ]; then
    echo "open-deps: at least one --checkout is required" >&2
    exit 2
fi

cache=$(mktemp "${TMPDIR:-/tmp}/open-deps.XXXXXX") || exit 2
trap 'rm -f "$cache"' EXIT

show() { # id -> JSON data object, or empty when no checkout resolves it
    local id=$1 c out
    for c in "${checkouts[@]}"; do
        out=$(cd "$c" 2>/dev/null && docket issue show "$id" --json=v2 2>/dev/null </dev/null) || continue
        printf '%s' "$out" | jq -e '.data' 2>/dev/null && return 0
    done
    return 1
}

# jq: status and route of one issue, as "<status> <route>"; route from the
# kind epic first, else the routing label, else unrouted, plus +blocked.
state_filter='
  (.status // "missing") + " " +
  ((.labels // []) as $l
   | (if .kind == "epic" then "epic"
      elif ($l | index("route-run")) then "route-run"
      elif ($l | index("route-direct")) then "route-direct"
      elif ($l | index("route-loop")) then "route-loop"
      else "unrouted" end)
     + (if ($l | index("blocked")) then "+blocked" else "" end))'

state_of() { # id -> "<status> <route>", "missing missing" when unresolved; cached
    local id=$1 s
    s=$(grep "^$id " "$cache" | cut -d' ' -f2-)
    if [ -z "$s" ]; then
        s=$(show "$id" | jq -r "$state_filter" 2>/dev/null)
        [ -z "$s" ] && s="missing missing"
        echo "$id $s" >> "$cache"
    fi
    printf '%s' "$s"
}

rc=0
while IFS= read -r id || [ -n "$id" ]; do
    [ -z "$id" ] && continue
    data=$(show "$id") || { printf '%s\tunresolved\n' "$id"; rc=1; continue; }
    targets=$(printf '%s' "$data" | jq -r --arg id "$id" \
        '.relations[]? | select(.relation_type=="depends_on" and .source_issue_id==$id) | .target_issue_id')
    open=""
    for t in $targets; do
        state=$(state_of "$t")
        s=${state%% *}
        route=${state#* }
        [ "$s" = done ] && continue
        [ "$s" = missing ] && rc=1
        open="${open:+$open,}$t($s,$route)"
    done
    [ -n "$open" ] && printf '%s\t%s\n' "$id" "$open"
done
exit $rc
