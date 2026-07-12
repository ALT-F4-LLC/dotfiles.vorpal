#!/bin/bash
# Shared doc-number allocation + citation-hijack check for docs/tdd/ and
# docs/adr/ authoring (previously hand-computed independently by
# @distinguished-engineer, @staff-engineer, and @security-engineer).
#
# Computes the next available {NNNN} (4-digit zero-padded, max-existing + 1
# over files matching ^[0-9]{4}-[a-z0-9-]+\.md$ in the target dir), then
# checks the repo for citation-hijack: a candidate number already referenced
# in prose (e.g. "docs/adr/0007-foo.md") even though no file with that
# number exists on disk yet. Referenced-but-missing numbers carry identity
# through their citations; writing new content at one would silently
# hijack it. On a hit, the candidate is skipped and the next number tried.
set -euo pipefail

usage() {
    echo "Usage: next_doc_number.sh <docs/tdd|docs/adr>" >&2
    echo "  Prints the next available {NNNN} for the target dir to stdout." >&2
    echo "  Skipped (citation-hijacked) candidates are reported to stderr." >&2
    exit 1
}

if [ "$#" -ne 1 ]; then
    usage
fi

DIR="${1%/}"
case "$DIR" in
    docs/tdd|docs/adr) ;;
    *) usage ;;
esac

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "next_doc_number.sh: not inside a git repository" >&2
    exit 1
}
cd "$REPO_ROOT"

mkdir -p "$DIR"

max_num=0
malformed=()
shopt -s nullglob
for f in "$DIR"/*.md; do
    base=$(basename "$f")
    if [[ "$base" =~ ^([0-9]{4})-[a-z0-9-]+\.md$ ]]; then
        num=$((10#${BASH_REMATCH[1]}))
        if [ "$num" -gt "$max_num" ]; then
            max_num=$num
        fi
    else
        malformed+=("$base")
    fi
done
shopt -u nullglob

if [ "${#malformed[@]}" -gt 0 ]; then
    echo "next_doc_number.sh: could not determine next doc number." >&2
    echo "  Existing filenames in ${DIR}/ must start with NNNN- (4-digit zero-padded)." >&2
    echo "  Found malformed: ${malformed[*]}" >&2
    exit 1
fi

candidate=$((max_num + 1))

while :; do
    padded=$(printf "%04d" "$candidate")
    pattern="${DIR}/${padded}-"
    hits=$(grep -rl --exclude-dir=.git -F "$pattern" . 2>/dev/null || true)
    if [ -z "$hits" ]; then
        break
    fi
    echo "next_doc_number.sh: candidate ${padded} already cited (citation-hijack) in:" >&2
    echo "$hits" | sed 's/^/  /' >&2
    candidate=$((candidate + 1))
done

printf "%04d\n" "$candidate"
