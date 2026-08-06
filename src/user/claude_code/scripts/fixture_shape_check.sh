#!/bin/bash
# Field-set diff between a test fixture and real on-disk artifacts, replacing
# the manual find-a-real-artifact-and-diff-by-eye step in sdet.md's
# "fixtures must mirror production shape" verification. Compares the set of
# key paths (nested object keys, array indices normalized to "[]" so element
# count differences don't register as drift), not raw content -- a fixture
# with different values but the same shape is a pass; a fixture missing or
# inventing a field is a fail. Supports JSON (single document) and JSONL
# (line-delimited JSON, e.g. history.jsonl / transcript *.jsonl in this repo)
# per-artifact, auto-detected.
set -euo pipefail

usage() {
    echo "Usage: fixture_shape_check.sh <fixture-path> <real-artifact-glob>" >&2
    echo "" >&2
    echo "  Computes the field-set (keys, including nested paths; array indices" >&2
    echo "  normalized to '[]') of <fixture-path> and of each real artifact matched" >&2
    echo "  by <real-artifact-glob>, then reports fixture-only fields (stale/" >&2
    echo "  invented) and real-only fields (drift/missing coverage) -- a field-set" >&2
    echo "  diff, not a raw content diff." >&2
    echo "" >&2
    echo "  <real-artifact-glob> is a single shell glob pattern; quote it so this" >&2
    echo "  script expands it, e.g. fixture_shape_check.sh fx.json 'artifacts/*.json'" >&2
    echo "" >&2
    echo "  Supports JSON (single document) and JSONL (line-delimited JSON)," >&2
    echo "  auto-detected per file." >&2
    echo "" >&2
    echo "  Exit codes: 0 = no drift, 1 = field-set diverged, 2 = usage/input error." >&2
    exit 2
}

[ "$#" -eq 2 ] || usage
case "$1" in
    -h|--help) usage ;;
esac

FIXTURE="$1"
GLOB_PATTERN="$2"

command -v jq >/dev/null 2>&1 || {
    echo "fixture_shape_check.sh: jq is required" >&2
    exit 2
}

[ -f "$FIXTURE" ] || {
    echo "fixture_shape_check.sh: fixture not found: ${FIXTURE}" >&2
    exit 2
}

FIELD_FILTER='[paths(scalars) as $p | ($p | map(if type=="number" then "[]" else tostring end) | join("."))] | unique[]'

# Prints the normalized field-set (one path per line) for $1 to stdout.
# Detects a single JSON document first, falls back to JSONL (every non-blank
# line must independently parse as JSON). Returns 1 if neither applies.
field_paths() {
    local file="$1"
    if jq '.' "$file" >/dev/null 2>&1; then
        jq -r "$FIELD_FILTER" "$file"
        return 0
    fi
    local line ok=1
    while IFS= read -r line || [ -n "$line" ]; do
        [ -z "$line" ] && continue
        if ! printf '%s\n' "$line" | jq '.' >/dev/null 2>&1; then
            ok=0
            break
        fi
    done < "$file"
    [ "$ok" -eq 1 ] || return 1
    while IFS= read -r line || [ -n "$line" ]; do
        [ -z "$line" ] && continue
        printf '%s\n' "$line" | jq -r "$FIELD_FILTER"
    done < "$file"
}

REAL_FILES=()
while IFS= read -r f; do
    [ -f "$f" ] && REAL_FILES+=("$f")
done < <(compgen -G "$GLOB_PATTERN" || true)

[ "${#REAL_FILES[@]}" -gt 0 ] || {
    echo "fixture_shape_check.sh: no files matched glob: ${GLOB_PATTERN}" >&2
    exit 2
}

WORKDIR=$(mktemp -d "${TMPDIR:-/tmp}/fixture_shape_check.XXXXXX")
trap 'rm -rf "$WORKDIR"' EXIT

if ! field_paths "$FIXTURE" > "${WORKDIR}/fixture_raw"; then
    echo "fixture_shape_check.sh: fixture is not valid JSON or JSONL: ${FIXTURE}" >&2
    exit 2
fi

MATCHED_VALID=0
: > "${WORKDIR}/real_raw"
for f in "${REAL_FILES[@]}"; do
    if field_paths "$f" >> "${WORKDIR}/real_raw"; then
        MATCHED_VALID=$((MATCHED_VALID + 1))
    else
        echo "fixture_shape_check.sh: warning: skipping unparseable artifact (not JSON or JSONL): ${f}" >&2
    fi
done

[ "$MATCHED_VALID" -gt 0 ] || {
    echo "fixture_shape_check.sh: no real artifact matching '${GLOB_PATTERN}' parsed as JSON or JSONL" >&2
    exit 2
}

LC_ALL=C sort -u "${WORKDIR}/fixture_raw" -o "${WORKDIR}/fixture_fields"
LC_ALL=C sort -u "${WORKDIR}/real_raw" -o "${WORKDIR}/real_fields"

FIXTURE_ONLY=$(comm -23 "${WORKDIR}/fixture_fields" "${WORKDIR}/real_fields")
REAL_ONLY=$(comm -13 "${WORKDIR}/fixture_fields" "${WORKDIR}/real_fields")

echo "=== fixture_shape_check: $(basename "$FIXTURE") vs ${MATCHED_VALID} real artifact(s) matching '${GLOB_PATTERN}' ==="
echo ""
echo "--- Fixture-only fields (stale/invented; in fixture, absent from all real artifacts) ---"
if [ -z "$FIXTURE_ONLY" ]; then
    echo "(none)"
else
    echo "$FIXTURE_ONLY"
fi
echo ""
echo "--- Real-only fields (drift/missing coverage; in real artifacts, absent from fixture) ---"
if [ -z "$REAL_ONLY" ]; then
    echo "(none)"
else
    echo "$REAL_ONLY"
fi

if [ -n "$FIXTURE_ONLY" ] || [ -n "$REAL_ONLY" ]; then
    exit 1
fi
exit 0
