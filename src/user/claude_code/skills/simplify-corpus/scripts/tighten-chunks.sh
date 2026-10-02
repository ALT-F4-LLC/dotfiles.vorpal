#!/bin/bash
#
# Split a Markdown file into chunks for tighten.js, and join chunks back into
# one candidate. One rewriter and one refuter panel per chunk means a bad
# edit costs its chunk, not the whole file.
#
# Usage:
#   tighten-chunks.sh split <file> <workdir> [target-lines]
#   tighten-chunks.sh join  <workdir> <dest> [chunk-id ...]
#
# split writes the file's chunks in order to <workdir>/orig/NNN.md, and a
# copy of each to <workdir>/cand/NNN.md for a rewriter to edit. A chunk
# starts only at a heading, or at a line that starts in column 0 after a
# blank line, and never inside the frontmatter, a fenced block, or an HTML
# comment. Those are paragraph edges for protected-spans.sh too, so the spans
# of the chunks add up to the spans of the file. A chunk runs to at least
# target-lines (default 200) but closes early at a `## ` heading once it
# holds half that, and a tail under a quarter of it joins the chunk before.
# split then checks that the chunks concatenate to the file byte for byte
# and prints:
#   chunk <id> lines <first>-<last> bytes <n>
#   chunks <count>
#
# join concatenates every chunk in order into <dest>, taking cand/<id>.md
# for each id named and orig/<id>.md for the rest, and prints:
#   joined <count> chunks, <k> rewritten, <n> bytes
#
# Exit 0 on success, 1 when the split fails its byte check, 2 on a usage or
# I/O error. Bash 3.2 and POSIX awk, so it runs unchanged on macOS.

set -uo pipefail
export LC_ALL=C
shopt -s nullglob

usage() {
    echo "usage: tighten-chunks.sh split <file> <workdir> [target-lines]" >&2
    echo "       tighten-chunks.sh join <workdir> <dest> [chunk-id ...]" >&2
    exit 2
}

fail() { # <message>
    echo "tighten-chunks: $1" >&2
    exit 2
}

size() { wc -c < "$1" | tr -d '[:space:]'; }

split_file() { # <file> <workdir> <target-lines>
    local file=$1 dir=$2 target=$3 nofinal=0 ranges id first last chunks
    [ -f "$file" ] && [ -r "$file" ] || fail "cannot read $file"
    case "$target" in '' | *[!0-9]*) fail "target-lines must be a positive integer" ;; esac
    [ "$target" -gt 0 ] || fail "target-lines must be a positive integer"
    if [ -d "$dir/orig" ] && [ -n "$(ls -A "$dir/orig")" ]; then
        fail "$dir/orig is not empty; split into a fresh workdir"
    fi
    mkdir -p "$dir/orig" "$dir/cand" || fail "cannot create $dir"
    if [ -s "$file" ] && [ -n "$(tail -c 1 "$file")" ]; then nofinal=1; fi

    ranges=$(awk -v target="$target" -v nofinal="$nofinal" -v dir="$dir/orig" '
        { line[NR] = $0 }
        END {
            n = NR
            # start[i]: a chunk may start at line i. The state is the one in
            # force after line i-1.
            for (i = 1; i <= n; i++) {
                s = line[i]
                blank = (s ~ /^[[:space:]]*$/)
                start[i] = 0
                if (i > 1 && !infm && !infence && !incomment && !blank && s != "---") {
                    if (s ~ /^(#|##|###|####|#####|######) /) start[i] = 1
                    else if (prevblank && s ~ /^[^[:space:]]/) start[i] = 1
                }
                h2[i] = (s ~ /^## /)
                if (i == 1 && s == "---") infm = 1
                else if (infm) { if (s == "---") infm = 0 }
                else if (infence) { if (s ~ /^[[:space:]]*```/) infence = 0 }
                else if (s ~ /^[[:space:]]*```/) infence = 1
                else if (incomment) { if (index(s, "-->")) incomment = 0 }
                else if (index(s, "<!--") && !index(s, "-->")) incomment = 1
                prevblank = blank
            }
            nc = 0; from = 1
            for (i = 2; i <= n; i++) {
                if (!start[i]) continue
                held = i - from
                if (held >= target || (h2[i] && held * 2 >= target)) {
                    nc++; cs[nc] = from; ce[nc] = i - 1; from = i
                }
            }
            if (n > 0) { nc++; cs[nc] = from; ce[nc] = n }
            if (nc > 1 && (ce[nc] - cs[nc] + 1) * 4 < target) { ce[nc - 1] = ce[nc]; nc-- }
            for (c = 1; c <= nc; c++) {
                id = sprintf("%03d", c)
                path = dir "/" id ".md"
                for (i = cs[c]; i <= ce[c]; i++) {
                    if (i == n && nofinal) printf "%s", line[i] > path
                    else print line[i] > path
                }
                close(path)
                print id, cs[c], ce[c]
            }
        }
    ' "$file") || fail "awk failed on $file"

    if [ -n "$ranges" ]; then
        if ! cat "$dir"/orig/*.md | cmp -s - "$file"; then
            echo "tighten-chunks: chunks of $file do not reproduce it byte for byte" >&2
            exit 1
        fi
        cp "$dir"/orig/*.md "$dir/cand/" || fail "cannot copy chunks to $dir/cand"
    elif [ -s "$file" ]; then
        fail "no chunks written for non-empty $file"
    fi

    chunks=0
    while read -r id first last; do
        [ -n "$id" ] || continue
        echo "chunk $id lines $first-$last bytes $(size "$dir/orig/$id.md")"
        chunks=$((chunks + 1))
    done <<EOF
$ranges
EOF
    echo "chunks $chunks"
}

join_chunks() { # <workdir> <dest> [chunk-id ...]
    local dir=$1 dest=$2 want id src total=0 rewritten=0
    shift 2
    want=" $* "
    [ -d "$dir/orig" ] || fail "no chunks under $dir/orig"
    for id in "$@"; do
        [ -f "$dir/cand/$id.md" ] && [ -f "$dir/orig/$id.md" ] || fail "no chunk $id under $dir"
    done
    mkdir -p "$(dirname "$dest")" || fail "cannot create the parent of $dest"
    : > "$dest" || fail "cannot write $dest"
    for src in "$dir"/orig/*.md; do
        id=$(basename "$src" .md)
        total=$((total + 1))
        case "$want" in
            *" $id "*)
                src="$dir/cand/$id.md"
                rewritten=$((rewritten + 1))
                ;;
        esac
        cat "$src" >> "$dest" || fail "cannot append $src to $dest"
    done
    echo "joined $total chunks, $rewritten rewritten, $(size "$dest") bytes"
}

case "${1:-}" in
    split)
        [ $# -eq 3 ] || [ $# -eq 4 ] || usage
        split_file "$2" "$3" "${4:-200}"
        ;;
    join)
        [ $# -ge 3 ] || usage
        shift
        join_chunks "$@"
        ;;
    *) usage ;;
esac
