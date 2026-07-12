#!/bin/bash
# Closed-arithmetic reference-count sweep: greps the repo root for a target
# pattern, partitions hits into exempt (paths under any -e exemption, plus
# .git which is always exempt) vs actionable, and emits counts satisfying
# total == exempt_count + actionable_count. Replaces the hand-built
# grep-with-exemptions sweep independently maintained by
# distinguished-engineer.md, staff-engineer.md, sdet.md, and team-lead.md.
set -euo pipefail

usage() {
    echo "Usage: ref_census.sh -p <pattern> [-e <exempt-path>]... [-F]" >&2
    echo "  -p, --pattern <pattern>   ERE regex to sweep for (required)." >&2
    echo "  -e, --exempt <path>       Exempt a directory (its full subtree) or" >&2
    echo "                            an exact file, matched as a repo-root-" >&2
    echo "                            relative path prefix; repeatable." >&2
    echo "                            .git is always exempt." >&2
    echo "  -F, --fixed-string        Treat <pattern> as a literal string," >&2
    echo "                            not a regex (grep -F)." >&2
    echo "  Emits JSON: {pattern, exempt_paths, total, exempt_count," >&2
    echo "  actionable_count, actionable_hits} with" >&2
    echo "  total == exempt_count + actionable_count (line counts, grep -c semantics)." >&2
    exit 1
}

PATTERN=""
EXEMPTS=()
MATCH_MODE_FLAG="-E"

while [ "$#" -gt 0 ]; do
    case "$1" in
        -p|--pattern)
            [ "$#" -ge 2 ] || usage
            PATTERN="$2"
            shift 2
            ;;
        -e|--exempt)
            [ "$#" -ge 2 ] || usage
            EXEMPTS+=("$2")
            shift 2
            ;;
        -F|--fixed-string)
            MATCH_MODE_FLAG="-F"
            shift
            ;;
        *)
            usage
            ;;
    esac
done

[ -n "$PATTERN" ] || usage

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "ref_census.sh: not inside a git repository" >&2
    exit 1
}
cd "$REPO_ROOT"

count_lines() {
    local text="$1"
    if [ -z "$text" ]; then
        echo 0
    else
        printf '%s\n' "$text" | wc -l | tr -d ' '
    fi
}

# Path-prefix match (not grep --exclude's basename-only glob semantics) so a
# specific file path exemption (e.g. "src/foo/bar.md") never accidentally
# exempts every "bar.md" in the tree, and a directory exemption covers its
# full subtree regardless of depth.
is_exempt() {
    local filepath="$1" ex
    for ex in ${EXEMPTS[@]+"${EXEMPTS[@]}"}; do
        ex="${ex%/}"
        case "$filepath" in
            "./$ex"|"./$ex/"*) return 0 ;;
        esac
    done
    return 1
}

BASELINE_ARGS=(-rnI "$MATCH_MODE_FLAG" --exclude-dir=.git)
BASELINE_HITS=$(grep "${BASELINE_ARGS[@]}" -- "$PATTERN" . 2>/dev/null || true)
TOTAL=$(count_lines "$BASELINE_HITS")

ACTIONABLE_HITS=""
if [ -n "$BASELINE_HITS" ]; then
    while IFS= read -r LINE; do
        FILEPATH="${LINE%%:*}"
        if ! is_exempt "$FILEPATH"; then
            if [ -z "$ACTIONABLE_HITS" ]; then
                ACTIONABLE_HITS="$LINE"
            else
                ACTIONABLE_HITS="$ACTIONABLE_HITS"$'\n'"$LINE"
            fi
        fi
    done <<< "$BASELINE_HITS"
fi
ACTIONABLE_COUNT=$(count_lines "$ACTIONABLE_HITS")
EXEMPT_COUNT=$((TOTAL - ACTIONABLE_COUNT))

jq -n \
    --arg pattern "$PATTERN" \
    --argjson exemptPaths "$(printf '%s\n' ${EXEMPTS[@]+"${EXEMPTS[@]}"} | jq -R . | jq -s 'map(select(length > 0))')" \
    --argjson total "$TOTAL" \
    --argjson exemptCount "$EXEMPT_COUNT" \
    --argjson actionableCount "$ACTIONABLE_COUNT" \
    --arg actionableHitsRaw "$ACTIONABLE_HITS" \
    '{
        pattern: $pattern,
        exempt_paths: $exemptPaths,
        total: $total,
        exempt_count: $exemptCount,
        actionable_count: $actionableCount,
        actionable_hits: (if $actionableHitsRaw == "" then [] else ($actionableHitsRaw | split("\n")) end)
    }'
