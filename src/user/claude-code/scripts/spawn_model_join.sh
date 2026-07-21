#!/bin/bash
# Codifies the evolve-model-distribution distribution-auditor's per-spawn LOCAL
# join (one .meta.json sidecar = one spawn, joined against its .jsonl's
# resolved model) as a single script, so the loop is authored once instead of
# hand-duplicated in the SKILL.md spawn prompt and re-executed by hand again
# during Phase 2's evidence re-verification gate.
set -uo pipefail

usage() {
    echo "Usage: spawn_model_join.sh <days> [session-path]" >&2
    echo "  Joins spawn-request (.meta.json) records against resolved-model" >&2
    echo "  (.jsonl) records and emits one TSV row per spawn:" >&2
    echo "    role<TAB>requested<TAB>resolved<TAB>session" >&2
    echo "  <days>: trailing-window size in days. With no [session-path]," >&2
    echo "  scans \$HOME/.claude/projects for subagents/ dirs modified in the" >&2
    echo "  last <days> days." >&2
    echo "  [session-path]: restrict to this one session dir, or a root dir" >&2
    echo "  containing several session dirs (e.g. a test fixtures tree)," >&2
    echo "  instead of the default window scan — <days> is not used to filter" >&2
    echo "  in this mode; the caller already scoped the target (e.g. Phase 2" >&2
    echo "  re-verification against an exact session)." >&2
    exit 1
}

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    usage
fi

DAYS="$1"
SESSION_PATH="${2:-}"

case "$DAYS" in
    ''|*[!0-9]*)
        echo "spawn_model_join.sh: <days> must be a non-negative integer, got '${DAYS}'" >&2
        exit 1
        ;;
esac

# One .meta.json sidecar = one spawn (the unit of counting — NOT the many
# per-turn "model" occurrences inside a .jsonl, which over-count a spawn).
join_session() {
    local subagents_dir="$1"
    local session
    session="$(basename "$(dirname "$subagents_dir")")"

    # find -print0 drives the loop (zsh+bash-safe). A shell glob here ABORTS
    # under zsh with "no matches found" on an empty/absent subagents dir
    # BEFORE any guard runs, and 2>/dev/null does NOT suppress a zsh nomatch;
    # find just yields nothing -> no-op.
    find "$subagents_dir" -name 'agent-a*.meta.json' -print0 2>/dev/null |
    while IFS= read -r -d '' meta; do
        jf="${meta%.meta.json}.jsonl"
        role=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1])).get("name") or "<unnamed>")' "$meta" 2>/dev/null || echo '<unparseable>')
        req=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1])).get("model") or "<omitted>")' "$meta" 2>/dev/null || echo '<unparseable>')
        # resolved model(s): extract the bare value out of "model":"X", then
        # drop the <synthetic> placeholder (a real on-disk sentinel, not a
        # model). The trailing `|| true` tolerates a zero-byte/missing jsonl
        # (grep finds no matches, exits non-zero) without aborting the row
        # under pipefail — it degrades to <none> instead, matching the
        # malformed/absent-tolerance contract below.
        resolved=$(grep -oh '"model":"[^"]*"' "$jf" 2>/dev/null | sed -E 's/^"model":"(.*)"$/\1/' | grep -v '<synthetic>' | sort -u | paste -sd, - || true)
        printf '%s\t%s\t%s\t%s\n' "$role" "$req" "${resolved:-<none>}" "$session"
    done
}

if [ -n "$SESSION_PATH" ]; then
    SESSION_PATH="${SESSION_PATH%/}"
    if [ -d "$SESSION_PATH/subagents" ]; then
        join_session "$SESSION_PATH/subagents"
    else
        find "$SESSION_PATH" -type d -name subagents 2>/dev/null | while IFS= read -r subagents_dir; do
            join_session "$subagents_dir"
        done
    fi
else
    find "$HOME/.claude/projects" -type d -name subagents -mtime "-${DAYS}" 2>/dev/null | while IFS= read -r subagents_dir; do
        join_session "$subagents_dir"
    done
fi
