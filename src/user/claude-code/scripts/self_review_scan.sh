#!/bin/bash
# Self-review scan for senior-engineer.md's Self-review step 5: greps the
# CHANGED lines of the given paths for artifacts that must never survive to
# handoff — debug statements, un-ticketed TODO/FIXME, commented-out code, and
# merge-conflict markers. Reports file:line per finding so the author can
# clear each before close.
#
# "Changed lines" means the working-tree diff's ADDED lines (the shared-tree
# discipline: an author's contribution is the UNSTAGED diff of their own
# files; never `git add` to inspect). Untracked files have no diff, so their
# full content is scanned. `--all` forces whole-file scanning of every path
# regardless of git state.
#
# Categories (each ADDED/scanned line is tested against all four):
#   debug         dbg!( / println!( / console.log( / fmt.Println(  ... etc.
#   todo          TODO or FIXME with no DKT- issue reference
#   commented     a comment line that looks like commented-out code (heuristic)
#   merge-marker  a git conflict marker (<<<<<<<, =======, >>>>>>>)
set -uo pipefail

usage() {
    echo "Usage: self_review_scan.sh [--all] <path>..." >&2
    echo "" >&2
    echo "  <path>...   Files (or dirs, recursed) to scan." >&2
    echo "  --all       Scan whole file contents, not just working-tree" >&2
    echo "              diff added lines (default: diff added lines, with" >&2
    echo "              untracked files scanned whole)." >&2
    echo "" >&2
    echo "  Emits '<category> <file>:<line>: <content>' per finding." >&2
    echo "  Exits 0 if no findings, 1 if any finding, 2 on usage error." >&2
    exit 2
}

SCAN_ALL=0
PATHS=()

while [ "$#" -gt 0 ]; do
    case "$1" in
        -h|--help) usage ;;
        --all)
            SCAN_ALL=1
            shift
            ;;
        -*)
            usage
            ;;
        *)
            PATHS+=("$1")
            shift
            ;;
    esac
done

[ "${#PATHS[@]}" -ge 1 ] || usage

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "self_review_scan.sh: not inside a git repository" >&2
    exit 2
}
cd "$REPO_ROOT"

DEBUG_RE='(^|[^[:alnum:]_])(dbg!|e?println!|console\.(log|debug|error|warn)|fmt\.Print(ln|f)?)'
MERGE_RE='^(<<<<<<<|=======|>>>>>>>)'
# A comment line whose payload looks like code: a //, #, or -- comment leader
# followed by text that ends in ; { } or contains an assignment / call shape.
# The -- leader requires a trailing space so shell `--flag)` case patterns are
# not mistaken for SQL/Lua `-- comment` lines (heuristic — false positives on
# prose that ends in a semicolon are expected).
COMMENTED_RE='^[[:space:]]*(//|#|-- )[[:space:]]*[[:alnum:]_].*([;{}]|[[:alnum:]_]+[[:space:]]*[=(])[[:space:]]*$'

FOUND=0

emit() {
    # emit <category> <file> <lineno> <content>
    printf '%-13s %s:%s: %s\n' "$1" "$2" "$3" "$4"
    FOUND=1
}

# scan_stream reads "<lineno>\t<content>" records on stdin and classifies each.
scan_stream() {
    local file="$1" lineno content
    while IFS=$'\t' read -r lineno content; do
        [ -n "$lineno" ] || continue
        if printf '%s' "$content" | grep -qE "$MERGE_RE"; then
            emit merge-marker "$file" "$lineno" "$content"
        fi
        if printf '%s' "$content" | grep -qE "$DEBUG_RE"; then
            emit debug "$file" "$lineno" "$content"
        fi
        if printf '%s' "$content" | grep -qiE '(^|[^[:alnum:]_])(TODO|FIXME)([^[:alnum:]_]|$)'; then
            if ! printf '%s' "$content" | grep -qE 'DKT-[0-9]+'; then
                emit todo "$file" "$lineno" "$content"
            fi
        fi
        if printf '%s' "$content" | grep -qE "$COMMENTED_RE"; then
            emit commented "$file" "$lineno" "$content"
        fi
    done
}

# added_lines emits "<newlineno>\t<content>" for each ADDED line in the
# working-tree diff of <file>, tracking new-file line numbers from hunk headers.
added_lines() {
    local file="$1"
    git diff -- "$file" | awk '
        /^@@/ {
            # @@ -a,b +c,d @@  -> new-file cursor starts at c
            match($0, /\+[0-9]+/)
            cur = substr($0, RSTART + 1, RLENGTH - 1) + 0
            next
        }
        /^\+\+\+/ { next }
        /^\+/ {
            printf "%d\t%s\n", cur, substr($0, 2)
            cur++
            next
        }
        /^-/ { next }
        /^ / { cur++; next }
    '
}

# whole_file emits "<lineno>\t<content>" for every line of <file>.
whole_file() {
    awk '{ printf "%d\t%s\n", NR, $0 }' "$1"
}

# Expand dirs to files (tracked + untracked, excluding .git).
expand_paths() {
    local p
    for p in "${PATHS[@]}"; do
        if [ -d "$p" ]; then
            find "$p" -type f -not -path '*/.git/*'
        elif [ -e "$p" ]; then
            printf '%s\n' "$p"
        else
            echo "self_review_scan.sh: path not found: $p" >&2
        fi
    done
}

while IFS= read -r file; do
    [ -n "$file" ] || continue
    # Process substitution (not a pipe) so scan_stream runs in THIS shell and
    # its FOUND updates propagate — a pipe would subshell it and lose them.
    if [ "$SCAN_ALL" -eq 1 ]; then
        scan_stream "$file" < <(whole_file "$file")
    elif git ls-files --error-unmatch "$file" >/dev/null 2>&1; then
        scan_stream "$file" < <(added_lines "$file")
    else
        # untracked: no diff, scan whole content
        scan_stream "$file" < <(whole_file "$file")
    fi
done < <(expand_paths)

if [ "$FOUND" -eq 0 ]; then
    echo "self-review: clean (no debug/todo/commented-code/merge-marker findings)"
    exit 0
fi
echo "self-review: findings present — clear each before handoff" >&2
exit 1
