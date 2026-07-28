#!/bin/bash
# Single-homes the {slug}/{today_date}/{project_name}/collision-check parameter
# chain duplicated near-verbatim across the Pre-flight sections of the
# doc-authoring family (tdd, adr, prd, ux-spec SKILL.md) — DKT-167.
#
# Collision field names are type-explicit, not a single overloaded `collision=`
# (advisor review: a boolean/path field meaning "exact path taken" for
# tdd/prd/ux-spec but "some ADR at some number shares this slug" for adr forces
# every consumer to already know the type to interpret it):
#   exact_path_collision  emitted for tdd/prd/ux-spec only — does
#                         {output_dir}/{slug}.md exist.
#   same_slug_existing    emitted for adr only — ADR has no fixed pre-claim path
#                         (numbering is reserved separately and atomically by
#                         next_doc_number.sh --claim, which is side-effecting and
#                         stays skill-side, not duplicated here), so this is a
#                         same-slug lookup across ANY existing {NNNN}-{slug}.md —
#                         a duplicate-decision signal distinct from the
#                         numbering mechanism.
#   near_dups             emitted for tdd only — the len(slug)>=12 near-duplicate
#                         prefix probe. tdd is the only skill whose Pre-flight
#                         prose already ran this by hand; adr/prd/ux-spec never
#                         had it, so it is deliberately NOT invented for them
#                         here (team-lead ruling, DKT-167) — expanding it to the
#                         other three types is a separate, out-of-scope decision.
#
# Every applicable field is tri-state, never a bare boolean/empty (advisor
# review: every docs/{tdd,adr,spec,ux} dir is commonly absent in a fresh repo —
# collapsing "directory doesn't exist yet" into the same empty value as
# "checked an existing directory, found nothing" silently misreports on
# essentially every real invocation):
#   {path}                        a real collision/near-dup was found
#   (empty string)                checked an existing directory; no hit
#   SKIPPED: {dir} absent         directory does not exist yet; not checked
set -euo pipefail

usage() {
    echo "Usage: doc_preflight.sh <tdd|adr|prd|ux-spec> \"<topic>\"" >&2
    echo >&2
    echo "Emits KEY=value lines to stdout. Always: slug, today_date, project_name." >&2
    echo "Type-conditional (only the fields applicable to <type> are printed):" >&2
    echo "  exact_path_collision  tdd/prd/ux-spec only — path to {output_dir}/{slug}.md" >&2
    echo "                        if it exists, else empty; or a 'SKIPPED: <dir> absent'" >&2
    echo "                        sentinel when {output_dir} does not exist yet." >&2
    echo "  same_slug_existing    adr only — path to any existing {NNNN}-{slug}.md" >&2
    echo "                        regardless of number, else empty/SKIPPED sentinel." >&2
    echo "  near_dups             tdd only, and only when len(slug) >= 12 — comma-" >&2
    echo "                        separated paths whose first 12 slug chars match" >&2
    echo "                        (excluding exact_path_collision itself), else" >&2
    echo "                        empty/SKIPPED sentinel." >&2
    exit 2
}

[ "$#" -eq 2 ] || usage
TYPE="$1"
TOPIC="$2"

case "$TYPE" in
    tdd) OUTPUT_DIR="docs/tdd" ;;
    adr) OUTPUT_DIR="docs/adr" ;;
    prd) OUTPUT_DIR="docs/spec" ;;
    ux-spec) OUTPUT_DIR="docs/ux" ;;
    *) usage ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "doc_preflight.sh: not inside a git repository" >&2
    exit 1
}
cd "$REPO_ROOT"

# Propagates slug.sh's own stderr + exit code verbatim on failure (exit 1:
# no alphanumeric survivors; exit 2: missing/empty topic).
SLUG=$("${SCRIPT_DIR}/slug.sh" "$TOPIC")

TODAY_DATE=$(date +%Y-%m-%d)
PROJECT_NAME=$(basename "$REPO_ROOT")
OUTPUT_PATH="${OUTPUT_DIR}/${SLUG}.md"

echo "slug=${SLUG}"
echo "today_date=${TODAY_DATE}"
echo "project_name=${PROJECT_NAME}"

if [ "$TYPE" = "adr" ]; then
    if [ ! -d "$OUTPUT_DIR" ]; then
        SAME_SLUG_EXISTING="SKIPPED: ${OUTPUT_DIR} absent"
    else
        SAME_SLUG_EXISTING=$(find "$OUTPUT_DIR" -maxdepth 1 -name "*-${SLUG}.md" 2>/dev/null | sort | head -1 || true)
    fi
    echo "same_slug_existing=${SAME_SLUG_EXISTING}"
else
    if [ ! -d "$OUTPUT_DIR" ]; then
        EXACT_PATH_COLLISION="SKIPPED: ${OUTPUT_DIR} absent"
    elif [ -f "$OUTPUT_PATH" ]; then
        EXACT_PATH_COLLISION="$OUTPUT_PATH"
    else
        EXACT_PATH_COLLISION=""
    fi
    echo "exact_path_collision=${EXACT_PATH_COLLISION}"
fi

if [ "$TYPE" = "tdd" ]; then
    if [ ! -d "$OUTPUT_DIR" ]; then
        NEAR_DUPS="SKIPPED: ${OUTPUT_DIR} absent"
    elif [ "${#SLUG}" -ge 12 ]; then
        PREFIX="${SLUG:0:12}"
        HITS=$(find "$OUTPUT_DIR" -maxdepth 1 -name "${PREFIX}*.md" 2>/dev/null | sort || true)
        FILTERED=""
        while IFS= read -r hit; do
            [ -z "$hit" ] && continue
            [ "$hit" = "$OUTPUT_PATH" ] && continue
            if [ -z "$FILTERED" ]; then
                FILTERED="$hit"
            else
                FILTERED="${FILTERED},${hit}"
            fi
        done <<< "$HITS"
        NEAR_DUPS="$FILTERED"
    else
        NEAR_DUPS=""
    fi
    echo "near_dups=${NEAR_DUPS}"
fi
