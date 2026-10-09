#!/usr/bin/env bash
#
# ac-lint — check that every source citation in acceptance-criterion text
# resolves at a named commit, so docket-groom never writes a criterion whose
# path:line anchor points at the wrong line.
#
# Usage: ac-lint.sh --base <sha> [--repo <dir>] [file ...]
#   Reads the criterion text from each file, or from stdin when none is
#   named. --base is the commit the citations must hold at (docket-groom
#   passes the checkout HEAD sha); --repo is the git checkout to read it
#   from, the current directory by default.
#
# A citation is a path token, optionally with a line or line range
# (`path:N`, `path:N-M`), and its quoted expression is the backtick- or
# double-quoted span that follows it, separated only by blanks and an
# optional `(`: src/a.awk:168 `marked_group`, or src/a.awk ("marked_group").
# A path written inside its own backtick span is read the same way.
#   - path:N with an expression: line N (or any line of N-M) at --base must
#     contain the expression, compared as a fixed string.
#   - path:N with no expression: refused. A bare line number drifts with
#     every edit above it, so it must carry the text it points at.
#   - path with an expression and no line: the expression must occur on
#     exactly one line of the file at --base (grep -F); zero or several
#     occurrences are refused as unresolved or ambiguous.
#   - path with neither: prose, not a citation; ignored.
# A path holding a `/` must exist at --base. A bare file name resolves to the
# one file at --base with that name; several such files are refused as
# ambiguous, and none means the token is not a repository path (a host:port,
# an abbreviation), so it is ignored.
#
# Read-only: it runs git cat-file, ls-tree and show against --base and
# writes nothing. Exit 0 when every citation resolves, 1 with one line per
# unresolved citation on stdout, 2 on a usage error or an unreadable base.

set -euo pipefail

usage() {
    printf 'usage: ac-lint.sh --base <sha> [--repo <dir>] [file ...]\n' >&2
    exit 2
}

base=""
repo="."
files=()
while [ $# -gt 0 ]; do
    case "$1" in
        --base) [ $# -ge 2 ] || usage; base="$2"; shift 2 ;;
        --repo) [ $# -ge 2 ] || usage; repo="$2"; shift 2 ;;
        -h | --help) usage ;;
        --) shift; files+=("$@"); break ;;
        -*) usage ;;
        *) files+=("$1"); shift ;;
    esac
done
[ -n "$base" ] || usage
if ! commit=$(git -C "$repo" rev-parse --verify --quiet "${base}^{commit}"); then
    printf 'ac-lint: --base %s is not a commit in %s\n' "$base" "$repo" >&2
    exit 2
fi

if [ ${#files[@]} -gt 0 ]; then
    text=$(cat -- "${files[@]}")
else
    text=$(cat)
fi

# One row per citation, fields split by \037 (a tab would collapse empty
# fields in read): path, first line, last line, expression. Lines
# are empty for a citation without a line; the expression is empty when
# none follows.
citations=$(printf '%s\n' "$text" | awk '
{
    line = $0
    while (match(line, /[A-Za-z0-9_.\/-]*[A-Za-z0-9_-]\.[A-Za-z0-9]+(:[0-9]+(-[0-9]+)?)?/)) {
        tok = substr(line, RSTART, RLENGTH)
        before = (RSTART > 1) ? substr(line, RSTART - 1, 1) : ""
        rest = substr(line, RSTART + RLENGTH)
        line = rest
        path = tok; from = ""; to = ""
        if (match(tok, /:[0-9]+(-[0-9]+)?$/)) {
            path = substr(tok, 1, RSTART - 1)
            range = substr(tok, RSTART + 1)
            split(range, r, "-")
            from = r[1]; to = (2 in r) ? r[2] : r[1]
            delete r
        }
        if (before == "`" && substr(rest, 1, 1) == "`") rest = substr(rest, 2)
        sub(/^[ \t]*\(?[ \t]*/, "", rest)
        expr = ""
        q = substr(rest, 1, 1)
        if (q == "`" || q == "\"") {
            close_at = index(substr(rest, 2), q)
            if (close_at > 1) expr = substr(rest, 2, close_at - 1)
        }
        if (from == "" && expr == "") continue
        printf "%s\037%s\037%s\037%s\n", path, from, to, expr
    }
}')

tree=$(git -C "$repo" ls-tree -r --name-only "$commit")
problems=0
report() {
    problems=$((problems + 1))
    printf '%s\n' "$1"
}

while IFS=$'\037' read -r path from to expr; do
    [ -n "$path" ] || continue
    cite="$path${from:+:$from}"
    [ -n "$from" ] && [ "$to" != "$from" ] && cite="$cite-$to"
    case "$path" in
        */*)
            if ! git -C "$repo" cat-file -e "${commit}:${path}" 2>/dev/null; then
                report "unresolved: ${cite}: no such file at ${base}"
                continue
            fi
            file="$path"
            ;;
        *)
            matches=$(printf '%s\n' "$tree" | awk -v n="$path" '$0 == n || substr($0, length($0) - length(n)) == "/" n')
            count=$(printf '%s' "$matches" | grep -c . || true)
            [ "$count" -eq 0 ] && continue
            if [ "$count" -gt 1 ]; then
                report "ambiguous: ${cite}: ${count} files at ${base} are named ${path}; cite the path"
                continue
            fi
            file="$matches"
            ;;
    esac
    if [ -n "$from" ]; then
        if [ -z "$expr" ]; then
            report "bare: ${cite}: a line citation needs a quoted expression from that line"
            continue
        fi
        if ! git -C "$repo" show "${commit}:${file}" | sed -n "${from},${to}p" | grep -qF -- "$expr"; then
            report "unresolved: ${cite}: does not contain \"${expr}\" at ${base}"
        fi
        continue
    fi
    hits=$(git -C "$repo" show "${commit}:${file}" | grep -cF -- "$expr" || true)
    if [ "$hits" -eq 0 ]; then
        report "unresolved: ${cite}: \"${expr}\" does not occur at ${base}"
    elif [ "$hits" -gt 1 ]; then
        report "ambiguous: ${cite}: \"${expr}\" occurs on ${hits} lines at ${base}; add a line or a longer expression"
    fi
done <<<"$citations"

[ "$problems" -eq 0 ] || exit 1
exit 0
