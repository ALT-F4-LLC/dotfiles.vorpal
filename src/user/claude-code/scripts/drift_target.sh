#!/bin/bash
# Codifies the Genetic-Drift "structural target selection" procedure (MC2): enumerate a
# target file's structural candidates, subtract any the historical-auditor already cited
# this cycle, then deterministically pick {drift-rate} traits from the remaining no-signal
# set via {drift-seed}. Replaces the hand-computed prose duplicated across evolve-agents,
# evolve-skills, and evolve-config SKILL.md.
set -euo pipefail

usage() {
    echo "Usage: drift_target.sh <target-file> <drift-seed> <drift-rate> [cited-findings-file]" >&2
    echo "  target-file:          path (repo-root-relative or absolute) to the file to select drift targets from" >&2
    echo "  drift-seed:           non-negative integer seed for deterministic selection" >&2
    echo "  drift-rate:           positive integer count of traits to select" >&2
    echo "  cited-findings-file:  optional file with one historical-auditor-cited heading/bullet" >&2
    echo "                        substring per line (already-cited candidates are subtracted" >&2
    echo "                        before selection). Omit, or pass \"-\", for an empty cited set." >&2
    echo "" >&2
    echo "  Enumerates candidates as the target file's headings and top-level list items," >&2
    echo "  subtracts cited candidates (the no-signal set), then indexes the no-signal set" >&2
    echo "  (in file order) starting at (drift-seed mod len) and emits drift-rate traits," >&2
    echo "  wrapping around and capped at len(no-signal set) to avoid duplicate picks." >&2
    echo "  Emits one \"<line-number>:<text>\" per selected trait. Empty no-signal set" >&2
    echo "  (every candidate cited) -> no-op: prints nothing to stdout, exits 0." >&2
    exit 1
}

if [ "$#" -lt 3 ] || [ "$#" -gt 4 ]; then
    usage
fi

TARGET_FILE="$1"
DRIFT_SEED="$2"
DRIFT_RATE="$3"
CITED_FILE="${4:--}"

if ! [[ "$DRIFT_SEED" =~ ^[0-9]+$ ]]; then
    echo "drift_target.sh: drift-seed must be a non-negative decimal integer, got: ${DRIFT_SEED}" >&2
    echo "drift_target.sh: (evolve_preflight.sh's drift_seed output is already decimal --" >&2
    echo "drift_target.sh: pass it through unmodified, don't re-derive from the hex digest)" >&2
    exit 1
fi
if ! [[ "$DRIFT_RATE" =~ ^[0-9]+$ ]] || [ "$DRIFT_RATE" -lt 1 ]; then
    echo "drift_target.sh: drift-rate must be a positive integer, got: ${DRIFT_RATE}" >&2
    exit 1
fi

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "drift_target.sh: not inside a git repository" >&2
    exit 1
}
cd "$REPO_ROOT"

if [ ! -f "$TARGET_FILE" ]; then
    echo "drift_target.sh: target file not found: ${TARGET_FILE}" >&2
    exit 1
fi

# (1) Enumerate candidate traits as headings and top-level list items, in file order.
CANDIDATES=()
while IFS= read -r line; do
    CANDIDATES+=("$line")
done < <(grep -nE '^#{2,4} |^- |^[0-9]+\. ' "$TARGET_FILE" || true)

if [ "${#CANDIDATES[@]}" -eq 0 ]; then
    echo "drift_target.sh: no candidate traits found in ${TARGET_FILE} -- drift is a no-op" >&2
    exit 0
fi

CITED=()
if [ "$CITED_FILE" != "-" ]; then
    if [ ! -f "$CITED_FILE" ]; then
        echo "drift_target.sh: cited-findings file not found: ${CITED_FILE}" >&2
        exit 1
    fi
    while IFS= read -r line; do
        CITED+=("$line")
    done < <(grep -v '^[[:space:]]*$' "$CITED_FILE" || true)
fi

# (2) Subtract any candidate whose text was cited in a historical-auditor finding.
NO_SIGNAL=()
for candidate in "${CANDIDATES[@]}"; do
    text="${candidate#*:}"
    cited=false
    for c in "${CITED[@]+"${CITED[@]}"}"; do
        if [[ "$text" == *"$c"* ]]; then
            cited=true
            break
        fi
    done
    if [ "$cited" = false ]; then
        NO_SIGNAL+=("$candidate")
    fi
done

COUNT="${#NO_SIGNAL[@]}"
if [ "$COUNT" -eq 0 ]; then
    echo "drift_target.sh: no-signal set is empty (every candidate cited) -- drift is a no-op" >&2
    exit 0
fi

# (3) Index the no-signal set (file order) with drift-seed mod len, pick drift-rate traits,
# wrapping around and capped at COUNT so picks never repeat.
START=$(( 10#$DRIFT_SEED % COUNT ))
PICKED=$(( DRIFT_RATE < COUNT ? DRIFT_RATE : COUNT ))
for ((i = 0; i < PICKED; i++)); do
    idx=$(( (START + i) % COUNT ))
    printf '%s\n' "${NO_SIGNAL[$idx]}"
done
