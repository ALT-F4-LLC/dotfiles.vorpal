#!/bin/bash
#
# Compare the protected spans of two Markdown files: the mechanical check
# behind tighten.js and simplify-corpus.js, and the main session's check
# before it lands a candidate.
#
# Usage:
#   protected-spans.sh equal   <original> <candidate>
#   protected-spans.sh subset  <original> <candidate>
#   protected-spans.sh extract <kind> <file>
#
# equal (tighten mode): every kind extracts identically from both files, so a
# rewrite may reword prose but never a protected span.
# subset (simplify mode): the candidate carries no code block, quote, link,
# or comment the original lacks; deleting one along with its prose is
# allowed.
# extract prints one kind's items from one file, for tests and debugging.
#
# Kinds:
#   frontmatter  the leading --- block, line for line
#   fences       every fenced code block, line for line
#   indented     every indented code block, line for line
#   headings     every heading line outside code blocks, in order
#   comments     every line of an HTML comment outside fences, in order
#   code         every inline code span in prose
#   quotes       every double-quoted span in prose
#   references   every section (§2) and file:line reference in prose
#   links        every link target, ](...), in prose
#   edges        trailing blank lines and the final newline
#
# An indented code block is a run of lines indented four or more spaces, or
# a tab, that follows a blank line after a paragraph or heading starting in
# column 0. After a list line the same indentation continues the list item,
# which stays prose.
#
# Prose is everything outside the frontmatter, code blocks, and comments,
# split into paragraphs at blank lines, headings, and those blocks. Whitespace
# collapses to one space, so rewrapping a paragraph never changes a span.
# Backticks and quote marks pair within a paragraph, and a quote mark inside
# inline code never pairs. Pairing across the whole file once let the quote
# marks in fenced code shift every later pair: 78% of docket-run's prose sat
# inside a span no edit could pass, while 15 of its 23 real quotations went
# unchecked.
#
# Report, one line per kind, then sizes and the verdict:
#   kind <name> ok
#   kind <name> changed: removed <item> added <item>
#   bytes <original> <candidate>
#   lines <original> <candidate>
#   result intact|changed
# Exit 0 when intact, 1 when a kind changed, 2 on a usage or read error.
#
# Bash 3.2 and POSIX awk, so it runs unchanged on macOS. It writes no files.

set -uo pipefail
export LC_ALL=C

EQUAL_KINDS="frontmatter fences indented headings comments code quotes references links edges"
SUBSET_KINDS="fences indented quotes links comments"

usage() {
    echo "usage: protected-spans.sh equal|subset <original> <candidate>" >&2
    echo "       protected-spans.sh extract <kind> <file>" >&2
    exit 2
}

readable() { # <file>
    [ -f "$1" ] && [ -r "$1" ] || { echo "protected-spans: cannot read $1" >&2; exit 2; }
}

extract() { # <kind> <file>
    awk -v kind="$1" '
        BEGIN { MASK = sprintf("%c", 1) }
        function heading(s) { return s ~ /^(#|##|###|####|#####|######) / }
        function fence(s) { return s ~ /^[[:space:]]*```/ }
        function indented(s) { return s ~ /^(    |\t)/ }
        function blank(s) { return s ~ /^[[:space:]]*$/ }
        # A column-0 line that is not a list item: an indented block after
        # it, past a blank line, is code rather than a list continuation.
        function opens_code(s) { return s ~ /^[^[:space:]]/ && s !~ /^([-*+]|[0-9]+[.)])[[:space:]]/ }
        function emit(k, s) { if (k == kind) print s }
        # A quote mark inside inline code is code, not quotation. Masking it
        # keeps the code text inside any quotation around it.
        function mask(s,   i, n, c, out, incode) {
            n = length(s); out = ""; incode = 0
            for (i = 1; i <= n; i++) {
                c = substr(s, i, 1)
                if (c == "`") incode = !incode
                else if (c == "\"" && incode) c = MASK
                out = out c
            }
            return out
        }
        function unmask(s,   out, j) {
            out = ""
            while ((j = index(s, MASK)) > 0) {
                out = out substr(s, 1, j - 1) "\""
                s = substr(s, j + 1)
            }
            return out s
        }
        # Pair marks left to right; an empty quotation carries nothing.
        function pair(s, mark,   i, n, open, start, span) {
            n = length(s); open = 0
            for (i = 1; i <= n; i++) {
                if (substr(s, i, 1) != mark) continue
                if (!open) { open = 1; start = i; continue }
                open = 0
                span = substr(s, start, i - start + 1)
                if (mark == "\"") {
                    if (length(span) < 3) continue
                    span = unmask(span)
                }
                print span
            }
        }
        function matches(s, which) {
            while (s != "") {
                if (which == "references") {
                    if (!match(s, /§[0-9]+|[A-Za-z0-9_.\/-]+\.(md|js|ts|sh|py|rs|go|toml|json|yaml|yml):[0-9]+/)) return
                } else if (!match(s, /\]\([^)]+\)/)) return
                print substr(s, RSTART, RLENGTH)
                s = substr(s, RSTART + RLENGTH)
            }
        }
        function flush(   s) {
            if (para == "") return
            s = para; para = ""
            gsub(/[[:space:]]+/, " ", s)
            if (kind == "code") pair(s, "`")
            else if (kind == "quotes") pair(mask(s), "\"")
            else if (kind == "references" || kind == "links") matches(s, kind)
        }
        NR == 1 && $0 == "---" { infm = 1; emit("frontmatter", $0); next }
        infm { emit("frontmatter", $0); if ($0 == "---") infm = 0; next }
        infence { emit("fences", $0); if (fence($0)) infence = 0; next }
        fence($0) { flush(); infence = 1; emit("fences", $0); last = ""; afterblank = 0; next }
        incode {
            if (indented($0)) { emit("indented", $0); next }
            if (blank($0)) { afterblank = 1; next }
            incode = 0
        }
        !incomment && index($0, "<!--") { incomment = 1 }
        incomment { flush(); emit("comments", $0); if (index($0, "-->")) incomment = 0; last = ""; afterblank = 0; next }
        afterblank && indented($0) && opens_code(last) { flush(); incode = 1; emit("indented", $0); next }
        heading($0) { flush(); emit("headings", $0); para = $0; flush(); last = $0; afterblank = 0; next }
        blank($0) { flush(); afterblank = 1; next }
        { para = (para == "" ? $0 : para " " $0); last = $0; afterblank = 0 }
        END { flush() }
    ' "$2"
}

edges() { # <file>
    local trailing final=final-newline
    trailing=$(awk '/^[[:space:]]*$/ { n++; next } { n = 0 } END { print n + 0 }' "$1")
    if [ -s "$1" ] && [ -n "$(tail -c 1 "$1")" ]; then final=no-final-newline; fi
    echo "trailing-blank-lines $trailing $final"
}

items() { # <kind> <file>
    case "$1" in
        edges) edges "$2" ;;
        *) extract "$1" "$2" ;;
    esac
}

listed() { # <items> — one per line, nothing at all for none
    if [ -n "$1" ]; then printf '%s\n' "$1"; fi
}

first_item() { # stdin: items — the first one, clipped, with a blank one named
    local line
    IFS= read -r line || return 0
    printf '%s\n' "${line:-(blank line)}" | cut -c 1-160
}

compare() { # <mode> <kind> <original> <candidate>
    local a b gone added
    a=$(items "$2" "$3")
    b=$(items "$2" "$4")
    if [ "$1" = equal ]; then
        case "$2" in
            code | quotes | references | links)
                a=$(listed "$a" | sort)
                b=$(listed "$b" | sort)
                ;;
        esac
        if [ "$a" = "$b" ]; then
            echo "kind $2 ok"
            return 0
        fi
    fi
    gone=$(comm -23 <(listed "$a" | sort) <(listed "$b" | sort) | first_item)
    added=$(comm -13 <(listed "$a" | sort) <(listed "$b" | sort) | first_item)
    if [ "$1" = subset ]; then
        if [ -z "$added" ]; then
            echo "kind $2 ok"
            return 0
        fi
        echo "kind $2 changed: added $added"
        return 1
    fi
    if [ -z "$gone$added" ]; then
        echo "kind $2 changed: order"
    else
        echo "kind $2 changed:${gone:+ removed $gone}${added:+ added $added}"
    fi
    return 1
}

size() { wc -c < "$1" | tr -d '[:space:]'; }
count() { wc -l < "$1" | tr -d '[:space:]'; }

case "${1:-}" in
    extract)
        [ $# -eq 3 ] || usage
        case " $EQUAL_KINDS " in *" $2 "*) ;; *) echo "protected-spans: unknown kind $2" >&2; exit 2 ;; esac
        readable "$3"
        items "$2" "$3"
        exit 0
        ;;
    equal) kinds=$EQUAL_KINDS ;;
    subset) kinds=$SUBSET_KINDS ;;
    *) usage ;;
esac
[ $# -eq 3 ] || usage
readable "$2"
readable "$3"

status=0
for kind in $kinds; do
    compare "$1" "$kind" "$2" "$3" || status=1
done
echo "bytes $(size "$2") $(size "$3")"
echo "lines $(count "$2") $(count "$3")"
if [ "$status" -eq 0 ]; then
    echo "result intact"
    exit 0
fi
echo "result changed"
exit 1
