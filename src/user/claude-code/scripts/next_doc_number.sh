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
#
# --claim <dir> <slug> additionally reserves the winning candidate
# atomically: it creates a number-only lock stub {dir}/.claim-{NNNN}.lock
# via a noclobber (`set -C`) redirection, which bash opens O_EXCL so the
# create itself is the atomicity boundary, not a separate check-then-write.
# The reservation is keyed on the number alone (not number+slug) so two
# concurrent claimants racing for the same number with DIFFERENT slugs
# still contend on the identical lock path instead of both winning
# (DKT-307 fix-1: the original number+slug keying let different-slug
# claimants sail past each other and collide on the same number). The
# winner then creates the real {dir}/{NNNN}-{slug}.md stub; the lock file
# is deliberately left in place (not removed) because a slower concurrent
# claimant may have computed the same candidate number before the winner's
# stub existed on disk — if the lock were removed after the win, that
# slower claimant could still win the now-freed lock and mint a duplicate
# number under its own slug. Leaving the lock permanently makes the number
# claim durable and matches the numbered stub it guards. A losing claimant
# sees the lock create fail and retries the next candidate instead of
# returning the same number. This mode is additive-only: the plain `<dir>`
# call signature below is unchanged and never reserves anything on disk.
set -euo pipefail

usage() {
    echo "Usage: next_doc_number.sh <docs/tdd|docs/adr>" >&2
    echo "       next_doc_number.sh --claim <docs/tdd|docs/adr> <slug>" >&2
    echo "  Prints the next available {NNNN} for the target dir to stdout." >&2
    echo "  Skipped (citation-hijacked) candidates are reported to stderr." >&2
    echo "  --claim also atomically reserves the number by creating an" >&2
    echo "  empty {dir}/{NNNN}-{slug}.md stub; a losing concurrent claim" >&2
    echo "  retries the next candidate instead of colliding." >&2
    exit 1
}

CLAIM=0
SLUG=""
if [ "${1:-}" = "--claim" ]; then
    CLAIM=1
    shift
    if [ "$#" -ne 2 ]; then
        usage
    fi
    SLUG="$2"
    set -- "$1"
fi

if [ "$#" -ne 1 ]; then
    usage
fi

DIR="${1%/}"
case "$DIR" in
    docs/tdd|docs/adr) ;;
    *) usage ;;
esac

if [ "$CLAIM" -eq 1 ] && ! [[ "$SLUG" =~ ^[a-z0-9-]+$ ]]; then
    echo "next_doc_number.sh: --claim slug must match ^[a-z0-9-]+\$ (got: ${SLUG})" >&2
    exit 1
fi

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
    if [ -n "$hits" ]; then
        echo "next_doc_number.sh: candidate ${padded} already cited (citation-hijack) in:" >&2
        echo "$hits" | sed 's/^/  /' >&2
        candidate=$((candidate + 1))
        continue
    fi

    if [ "$CLAIM" -eq 1 ]; then
        lock_path="${DIR}/.claim-${padded}.lock"
        if ( set -C; : > "$lock_path" ) 2>/dev/null; then
            claim_path="${DIR}/${padded}-${SLUG}.md"
            : > "$claim_path"
            printf "%04d\n" "$candidate"
            exit 0
        fi
        echo "next_doc_number.sh: candidate ${padded} lost the atomic claim (${lock_path} already exists), retrying" >&2
        candidate=$((candidate + 1))
        continue
    fi

    break
done

printf "%04d\n" "$candidate"
