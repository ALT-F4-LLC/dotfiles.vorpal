#!/bin/bash
# Wraps `docket issue create`, then re-verifies via `docket issue show <id>
# --json` that every passed -l/--label and -f/--file value actually landed
# (docket's create response is known to omit them despite exit 0 and despite
# them landing), backfilling any that are truly missing.
set -euo pipefail

usage() {
    echo "Usage: docket_create.sh <docket issue create flags...>" >&2
    echo "  Wraps 'docket issue create', then verifies every -l/--label and" >&2
    echo "  -f/--file value landed via a re-show, backfilling any that didn't." >&2
    echo "  Guards cwd to repo root." >&2
    exit 1
}

if [ "$#" -eq 0 ]; then
    usage
fi

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "docket_create.sh: not inside a git repository" >&2
    exit 1
}
cd "$REPO_ROOT"

LABELS=()
FILES=()
ARGS=("$@")
i=0
while [ "$i" -lt "${#ARGS[@]}" ]; do
    arg="${ARGS[$i]}"
    case "$arg" in
        -l|--label)
            i=$((i + 1))
            LABELS+=("${ARGS[$i]}")
            ;;
        -l=*|--label=*)
            LABELS+=("${arg#*=}")
            ;;
        -f|--file)
            i=$((i + 1))
            FILES+=("${ARGS[$i]}")
            ;;
        -f=*|--file=*)
            FILES+=("${arg#*=}")
            ;;
    esac
    i=$((i + 1))
done

CREATE_OUTPUT=$(docket issue create --json "$@") || {
    echo "docket_create.sh: create failed: ${CREATE_OUTPUT}" >&2
    exit 1
}

ID=$(printf '%s' "$CREATE_OUTPUT" | jq -r '.data.id')

if [ -z "$ID" ] || [ "$ID" = "null" ]; then
    echo "docket_create.sh: could not determine created issue ID from output:" >&2
    echo "$CREATE_OUTPUT" >&2
    exit 1
fi

SHOW_OUTPUT=$(docket issue show "$ID" --json) || {
    echo "docket_create.sh: failed to show ${ID}: ${SHOW_OUTPUT}" >&2
    exit 1
}

item_missing() {
    # $1 = show output, $2 = jq field (labels|files), $3 = value to check
    ! printf '%s' "$1" | jq -e --arg v "$3" --arg f "$2" '(.data[$f] // []) | index($v) != null' >/dev/null
}

MISSING_LABELS=()
for label in "${LABELS[@]+"${LABELS[@]}"}"; do
    if item_missing "$SHOW_OUTPUT" labels "$label"; then
        MISSING_LABELS+=("$label")
    fi
done

MISSING_FILES=()
for file in "${FILES[@]+"${FILES[@]}"}"; do
    if item_missing "$SHOW_OUTPUT" files "$file"; then
        MISSING_FILES+=("$file")
    fi
done

if [ "${#MISSING_LABELS[@]}" -gt 0 ]; then
    echo "docket_create.sh: backfilling dropped labels on ${ID}: ${MISSING_LABELS[*]}" >&2
    docket issue label add "$ID" "${MISSING_LABELS[@]}"
fi

if [ "${#MISSING_FILES[@]}" -gt 0 ]; then
    echo "docket_create.sh: backfilling dropped files on ${ID}: ${MISSING_FILES[*]}" >&2
    docket issue file add "$ID" "${MISSING_FILES[@]}"
fi

if [ "${#MISSING_LABELS[@]}" -gt 0 ] || [ "${#MISSING_FILES[@]}" -gt 0 ]; then
    SHOW_OUTPUT=$(docket issue show "$ID" --json) || {
        echo "docket_create.sh: failed to re-show ${ID} after backfill: ${SHOW_OUTPUT}" >&2
        exit 1
    }
    STILL_MISSING_LABELS=()
    for label in "${MISSING_LABELS[@]+"${MISSING_LABELS[@]}"}"; do
        if item_missing "$SHOW_OUTPUT" labels "$label"; then
            STILL_MISSING_LABELS+=("$label")
        fi
    done
    STILL_MISSING_FILES=()
    for file in "${MISSING_FILES[@]+"${MISSING_FILES[@]}"}"; do
        if item_missing "$SHOW_OUTPUT" files "$file"; then
            STILL_MISSING_FILES+=("$file")
        fi
    done
    if [ "${#STILL_MISSING_LABELS[@]}" -gt 0 ] || [ "${#STILL_MISSING_FILES[@]}" -gt 0 ]; then
        echo "docket_create.sh: backfill did not take effect on ${ID} — still missing labels: ${STILL_MISSING_LABELS[*]:-none}, files: ${STILL_MISSING_FILES[*]:-none}" >&2
        exit 1
    fi
fi

echo "Created ${ID} (labels verified: ${#LABELS[@]}, files verified: ${#FILES[@]})"
printf '%s\n' "$SHOW_OUTPUT"
