#!/bin/bash
# Checks the context-engineering charter's byte ceilings against the live tree.
#
# The charter has stated "team-lead.md may not exceed 30KB" since the migration
# began, and nothing ever enforced it -- which is why the file drifted to 137KB,
# came back to 74KB, and kept growing a little with every correctness fix. A
# stated requirement that nothing checks is a wish, not a limit.
#
# WARN-ONLY by default (exit 0) so it can be adopted while the tree is still in
# breach; --strict makes it gate. Ceilings live in byte_ceilings.tsv, which
# restates the charter's numbers -- test_byte_ceiling_check.py fails if a row
# drifts from what the charter actually says.
set -uo pipefail

usage() {
    echo "Usage: byte_ceiling_check.sh [--strict] [--quiet]" >&2
    echo "" >&2
    echo "  Compares the tree against the charter's byte ceilings." >&2
    echo "    --strict   exit 1 on any unexcused breach (default: warn, exit 0)" >&2
    echo "    --quiet    print only breaches" >&2
    echo "" >&2
    echo "  Exits 0 clean (or warn-only), 1 on breach under --strict, 2 on usage error." >&2
    exit 2
}

STRICT=0
QUIET=0
while [ "$#" -gt 0 ]; do
    case "$1" in
        --strict) STRICT=1; shift ;;
        --quiet)  QUIET=1; shift ;;
        -h|--help) usage ;;
        *) usage ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${BYTE_CEILINGS:-${SCRIPT_DIR}/byte_ceilings.tsv}"
[ -f "$CONFIG" ] || { echo "byte_ceiling_check.sh: config not found: $CONFIG" >&2; exit 2; }

# Repo root: the config lives at <root>/src/user/claude-code/scripts/
ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
cd "$ROOT" || { echo "byte_ceiling_check.sh: cannot enter repo root ${ROOT}" >&2; exit 2; }

BREACHES=0
CHECKED=0

# Excused paths (per-file, for `each` rows only).
is_excused() {
    grep -q "^#EXCUSE	$1	" "$CONFIG" 2>/dev/null
}

report() {
    # report <status> <actual> <ceiling> <label>
    local status="$1" actual="$2" ceiling="$3" label="$4"
    local over=$(( actual - ceiling ))
    if [ "$status" = "OVER" ]; then
        printf '  %-6s %8d / %8d  (+%d, %d%%)  %s\n' \
            "OVER" "$actual" "$ceiling" "$over" "$(( actual * 100 / ceiling ))" "$label" >&2
    elif [ "$QUIET" -eq 0 ]; then
        printf '  %-6s %8d / %8d  %s\n' "$status" "$actual" "$ceiling" "$label"
    fi
}

while IFS=$'\t' read -r kind target ceiling note; do
    case "$kind" in ""|"#"*) continue ;; esac
    [ -n "${ceiling:-}" ] || continue

    case "$kind" in
        file)
            [ -f "$target" ] || { echo "  MISSING  $target" >&2; BREACHES=$((BREACHES+1)); continue; }
            n=$(wc -c < "$target" | tr -d ' ')
            CHECKED=$((CHECKED+1))
            if [ "$n" -gt "$ceiling" ]; then report OVER "$n" "$ceiling" "$target"; BREACHES=$((BREACHES+1))
            else report ok "$n" "$ceiling" "$target"; fi
            ;;
        sum)
            # shellcheck disable=SC2086
            n=$(cat $target 2>/dev/null | wc -c | tr -d ' ')
            CHECKED=$((CHECKED+1))
            if [ "$n" -gt "$ceiling" ]; then report OVER "$n" "$ceiling" "sum: $target"; BREACHES=$((BREACHES+1))
            else report ok "$n" "$ceiling" "sum: $target"; fi
            ;;
        each)
            # shellcheck disable=SC2086
            for f in $target; do
                [ -f "$f" ] || continue
                n=$(wc -c < "$f" | tr -d ' ')
                CHECKED=$((CHECKED+1))
                if [ "$n" -gt "$ceiling" ]; then
                    if is_excused "$f"; then
                        [ "$QUIET" -eq 0 ] && printf '  %-6s %8d / %8d  %s (excused)\n' "excus" "$n" "$ceiling" "$f"
                    else
                        report OVER "$n" "$ceiling" "$f"; BREACHES=$((BREACHES+1))
                    fi
                else
                    report ok "$n" "$ceiling" "$f"
                fi
            done
            ;;
        *) echo "byte_ceiling_check.sh: unknown kind '${kind}'" >&2; exit 2 ;;
    esac
done < "$CONFIG"

echo ""
if [ "$BREACHES" -eq 0 ]; then
    echo "byte-ceiling: clean (${CHECKED} target(s) within ceiling)"
    exit 0
fi
if [ "$STRICT" -eq 1 ]; then
    echo "byte-ceiling: FAIL — ${BREACHES} of ${CHECKED} target(s) over ceiling" >&2
    exit 1
fi
echo "byte-ceiling: WARN — ${BREACHES} of ${CHECKED} target(s) over ceiling (warn-only; --strict to gate)" >&2
exit 0
