#!/bin/bash
# Write-side schema enforcement for team-lead's step-16 dispatch-ledger
# entry (agents/team-lead.md step 16), replacing hand-formatted prose with
# a fixed field order, required-field, and no-pipe-character validation.
#
# Schema (one line per cycle, pipe-delimited, consumed by DKT-187's
# read-side cycle_metrics.py once that script exists — field names below
# are the shared contract; do not rename without updating both sides):
#   {YYYY-MM-DD} | cycle={slug} | pattern={value} | review={value} |
#   verify={value} | votes={value} | fix_rounds={value} |
#   review_spawns_total={value} [| note={value}]
set -euo pipefail

LEDGER_PATH=".claude/agent-memory/team-lead/dispatch-ledger.md"

usage() {
    echo "Usage: dispatch_ledger.sh append --cycle=<slug> --pattern=<pattern> \\" >&2
    echo "         --review=<review> --verify=<verify> --votes=<votes> \\" >&2
    echo "         --fix_rounds=<fix_rounds> --review_spawns_total=<n> [--note=<note>]" >&2
    echo "  Appends one schema-consistent line to ${LEDGER_PATH}:" >&2
    echo "  {YYYY-MM-DD} | cycle={c} | pattern={p} | review={r} | verify={v} |" >&2
    echo "  votes={vt} | fix_rounds={f} | review_spawns_total={n} [| note={note}]" >&2
    echo "  All fields required except --note. Guards cwd to repo root." >&2
    exit 1
}

if [ "$#" -eq 0 ] || [ "$1" != "append" ]; then
    usage
fi
shift

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "dispatch_ledger.sh: not inside a git repository" >&2
    exit 1
}
cd "$REPO_ROOT"

CYCLE=""
PATTERN=""
REVIEW=""
VERIFY=""
VOTES=""
FIX_ROUNDS=""
REVIEW_SPAWNS_TOTAL=""
NOTE=""

ARGS=("$@")
i=0
while [ "$i" -lt "${#ARGS[@]}" ]; do
    arg="${ARGS[$i]}"
    case "$arg" in
        --cycle=*) CYCLE="${arg#*=}" ;;
        --pattern=*) PATTERN="${arg#*=}" ;;
        --review=*) REVIEW="${arg#*=}" ;;
        --verify=*) VERIFY="${arg#*=}" ;;
        --votes=*) VOTES="${arg#*=}" ;;
        --fix_rounds=*) FIX_ROUNDS="${arg#*=}" ;;
        --review_spawns_total=*) REVIEW_SPAWNS_TOTAL="${arg#*=}" ;;
        --note=*) NOTE="${arg#*=}" ;;
        --cycle|--pattern|--review|--verify|--votes|--fix_rounds|--review_spawns_total|--note)
            echo "dispatch_ledger.sh: use --flag=value form, not '${arg} <value>'" >&2
            exit 1
            ;;
        *)
            echo "dispatch_ledger.sh: unrecognized argument '${arg}'" >&2
            usage
            ;;
    esac
    i=$((i + 1))
done

if [ -z "$CYCLE" ]; then
    echo "dispatch_ledger.sh: missing required --cycle" >&2
    exit 1
fi
if [ -z "$PATTERN" ]; then
    echo "dispatch_ledger.sh: missing required --pattern" >&2
    exit 1
fi
if [ -z "$REVIEW" ]; then
    echo "dispatch_ledger.sh: missing required --review" >&2
    exit 1
fi
if [ -z "$VERIFY" ]; then
    echo "dispatch_ledger.sh: missing required --verify" >&2
    exit 1
fi
if [ -z "$VOTES" ]; then
    echo "dispatch_ledger.sh: missing required --votes" >&2
    exit 1
fi
if [ -z "$FIX_ROUNDS" ]; then
    echo "dispatch_ledger.sh: missing required --fix_rounds" >&2
    exit 1
fi
if [ -z "$REVIEW_SPAWNS_TOTAL" ]; then
    echo "dispatch_ledger.sh: missing required --review_spawns_total" >&2
    exit 1
fi

for pair in "cycle:$CYCLE" "pattern:$PATTERN" "review:$REVIEW" "verify:$VERIFY" \
    "votes:$VOTES" "fix_rounds:$FIX_ROUNDS" "review_spawns_total:$REVIEW_SPAWNS_TOTAL" \
    "note:$NOTE"; do
    name="${pair%%:*}"
    value="${pair#*:}"
    case "$value" in
        *'|'*)
            echo "dispatch_ledger.sh: --${name} value contains '|', which breaks the pipe-delimited schema: ${value}" >&2
            exit 1
            ;;
    esac
done

DATE=$(date +%Y-%m-%d)
LINE="${DATE} | cycle=${CYCLE} | pattern=${PATTERN} | review=${REVIEW} | verify=${VERIFY} | votes=${VOTES} | fix_rounds=${FIX_ROUNDS} | review_spawns_total=${REVIEW_SPAWNS_TOTAL}"
if [ -n "$NOTE" ]; then
    LINE="${LINE} | note=${NOTE}"
fi

mkdir -p "$(dirname "$LEDGER_PATH")"
printf '%s\n' "$LINE" >> "$LEDGER_PATH"

echo "Appended to ${LEDGER_PATH}:"
echo "$LINE"
