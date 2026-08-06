#!/bin/bash
# Confirms whether a test is genuinely flaky (intermittent) vs. deterministically
# broken, per sdet.md's "flaky (run 3-5x to confirm, quarantine if confirmed)"
# convention. Runs <test-cmd> n times, captures the verbatim failure signature
# from each failing run, dedupes identical signatures with occurrence counts,
# and reports a pass/fail tally plus a verdict.
set -uo pipefail

usage() {
    echo "Usage: flaky_confirm.sh <test-cmd> [n]" >&2
    echo "  Runs <test-cmd> (a single shell command string) n times (default: 5)," >&2
    echo "  captures the verbatim failure signature (stdout+stderr tail) from each" >&2
    echo "  failing run, and reports a pass/fail tally plus deduped failure" >&2
    echo "  signatures with occurrence counts." >&2
    echo "  FLAKY_CONFIRM_TAIL_LINES (default: 20) controls signature tail length." >&2
    exit 1
}

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    usage
fi

TEST_CMD="$1"
N="${2:-5}"

case "$N" in
    ''|*[!0-9]*)
        echo "flaky_confirm.sh: n must be a positive integer, got '${N}'" >&2
        exit 1
        ;;
esac
if [ "$N" -lt 1 ]; then
    echo "flaky_confirm.sh: n must be >= 1, got '${N}'" >&2
    exit 1
fi

TAIL_LINES="${FLAKY_CONFIRM_TAIL_LINES:-20}"

PASS_COUNT=0
FAIL_COUNT=0
declare -a SIGNATURES=()
declare -a SIGNATURE_COUNTS=()

for i in $(seq 1 "$N"); do
    OUTPUT=$(bash -c "$TEST_CMD" 2>&1)
    STATUS=$?
    if [ "$STATUS" -eq 0 ]; then
        PASS_COUNT=$((PASS_COUNT + 1))
        echo "run ${i}/${N}: PASS"
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        SIGNATURE=$(printf '%s' "$OUTPUT" | tail -n "$TAIL_LINES")
        echo "run ${i}/${N}: FAIL (exit ${STATUS})"

        FOUND=0
        for idx in "${!SIGNATURES[@]}"; do
            if [ "${SIGNATURES[$idx]}" = "$SIGNATURE" ]; then
                SIGNATURE_COUNTS[$idx]=$((SIGNATURE_COUNTS[$idx] + 1))
                FOUND=1
                break
            fi
        done
        if [ "$FOUND" -eq 0 ]; then
            SIGNATURES+=("$SIGNATURE")
            SIGNATURE_COUNTS+=(1)
        fi
    fi
done

echo
echo "Tally: ${PASS_COUNT} pass, ${FAIL_COUNT} fail (of ${N} runs)"

if [ "$FAIL_COUNT" -gt 0 ]; then
    echo
    echo "Distinct failure signatures (${#SIGNATURES[@]}):"
    for idx in "${!SIGNATURES[@]}"; do
        echo "--- signature $((idx + 1)) (seen ${SIGNATURE_COUNTS[$idx]}x) ---"
        echo "${SIGNATURES[$idx]}"
    done
fi

echo
if [ "$PASS_COUNT" -gt 0 ] && [ "$FAIL_COUNT" -gt 0 ]; then
    echo "Verdict: FLAKY (intermittent — both pass and fail observed across ${N} runs)"
elif [ "$FAIL_COUNT" -eq "$N" ]; then
    echo "Verdict: DETERMINISTICALLY BROKEN (all ${N} runs failed)"
    if [ "${#SIGNATURES[@]}" -gt 1 ]; then
        echo "  (note: ${#SIGNATURES[@]} distinct failure signatures across all-fail runs — may still indicate non-determinism in the failure mode itself)"
    fi
else
    echo "Verdict: STABLE (all ${N} runs passed)"
fi

exit 0
