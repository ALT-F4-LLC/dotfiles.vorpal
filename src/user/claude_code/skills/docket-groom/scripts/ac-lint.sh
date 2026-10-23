#!/usr/bin/env bash
#
# ac-lint — check that every source citation in acceptance-criterion text
# resolves at a named commit, so docket-groom never writes a criterion whose
# path:line anchor points at the wrong line.
#
# Usage: ac-lint.sh --base <sha> [--repo <dir>] [--shared-base] [file ...]
#   Reads the criterion text from each file, or from stdin when none is
#   named. --base is the commit the citations must hold at (docket-groom
#   passes the checkout HEAD sha); --repo is the git checkout to read it
#   from, the current directory by default.
#
# A citation is a path token, optionally with a line or line range
# (`path:N`, `path:N-M`), and its quoted expression is the backtick- or
# double-quoted span that follows it, separated only by blanks and an
# optional `(`: src/a.awk:168 `marked_group`, or src/a.awk ("marked_group").
# A path inside a backtick span, at any position in it, is read the same way:
# the span's closing backtick never opens the expression.
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
# --shared-base is passed when the issue has depends_on edges or siblings under
# one parent. A sibling's commits land on the moving branch, so a `Verify:`
# command that measures from `git merge-base ... main` or a bare `main` or
# `origin/main` (git diff, log, rev-list, show, cherry) changes under the
# issue and can read unmet whatever the fix does. Such a line is refused as
# moving-base; the fix is the literal base sha recorded at groom time. Without
# the flag, no base is checked.
#
# Read-only: it runs git cat-file, ls-tree and show against --base and
# writes nothing. Exit 0 when every citation resolves, 1 with one line per
# unresolved citation on stdout, 2 on a usage error or an unreadable base.

set -euo pipefail

# Loop input goes through files, never here-strings: bash 3.2 writes a
# here-string to a temp file outside TMPDIR, the sandbox refuses it from
# some working directories, and set -e does not stop on that failed
# redirect, so the loop runs zero times and the script exits 0 having
# checked nothing.
lint_tmpd=$(mktemp -d "${TMPDIR:-/tmp}/lint.XXXXXX")
trap 'rm -rf "$lint_tmpd"' EXIT
lines_of() { local f; f=$(mktemp "$lint_tmpd/l.XXXXXX"); printf '%s\n' "$1" > "$f"; printf '%s' "$f"; }

usage() {
    printf 'usage: ac-lint.sh --base <sha> [--repo <dir>] [--shared-base] [file ...]\n' >&2
    exit 2
}

base=""
repo="."
shared_base=0
files=()
while [ $# -gt 0 ]; do
    case "$1" in
        --base) [ $# -ge 2 ] || usage; base="$2"; shift 2 ;;
        --repo) [ $# -ge 2 ] || usage; repo="$2"; shift 2 ;;
        --shared-base) shared_base=1; shift ;;
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
    ticks = 0
    while (match(line, /[A-Za-z0-9_.\/-]*[A-Za-z0-9_-]\.[A-Za-z0-9]+(:[0-9]+(-[0-9]+)?)?/)) {
        tok = substr(line, RSTART, RLENGTH)
        before = substr(line, 1, RSTART - 1)
        ticks += gsub(/`/, "", before)
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
        if (ticks % 2 == 1) sub(/^[ \t]*`/, "", rest)
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
done < "$(lines_of "$citations")"

# A moving base: on an issue with siblings or dependencies, a Verify command
# that measures from the merge-base with main, or from bare main, shifts as
# other work lands. A criterion is a bullet or paragraph, so a command wrapped
# across lines or fenced is joined first; only the backtick spans after
# `Verify:` are read, so prose that mentions main is never flagged. A pathspec
# after ` -- ` is not a base, and `merge-base --is-ancestor` with a literal sha
# is a stable check.
if [ "$shared_base" -eq 1 ]; then
    git_cmd='git([[:space:]]+(-C[[:space:]]+[^[:space:]]+|-[^[:space:]]+))*[[:space:]]+'
    main_ref='(^|[^A-Za-z0-9_./-]|\.\.)(origin/)?main($|[^A-Za-z0-9_./-]|\.\.)'
    units=$(printf '%s\n' "$text" | awk '
        function flush() { if (unit != "") print unit; unit = "" }
        /^[ \t]*([-*+]|[0-9]+[.)])[ \t]/ { flush() }
        /^[ \t]*$/ { flush(); next }
        { unit = unit (unit == "" ? "" : " ") $0 }
        END { flush() }')
    while IFS= read -r unit; do
        printf '%s\n' "$unit" | grep -qiE 'verify:' || continue
        spans=$(printf '%s\n' "$unit" | sed -E 's/^.*[Vv][Ee][Rr][Ii][Ff][Yy]:[[:space:]]*//; s/```[a-z]*/`/g' | grep -oE '`[^`]+`' || true)
        while IFS= read -r span; do
            [ -n "$span" ] || continue
            cmd="${span#\`}"; cmd="${cmd%\`}"
            head="${cmd%% -- *}"
            excerpt=$(printf '%s' "$cmd" | cut -c1-80)
            if printf '%s\n' "$cmd" | grep -qE "${git_cmd}merge-base"; then
                if printf '%s\n' "$cmd" | grep -qE -e '--is-ancestor' && ! printf '%s\n' "$head" | grep -qE "$main_ref"; then
                    continue
                fi
                report "moving-base: \`${excerpt}\` uses git merge-base, which moves as sibling work lands; record the literal base sha at groom time"
            elif printf '%s\n' "$head" | grep -qE "${git_cmd}(diff|log|rev-list|show|cherry)[^|;&]*${main_ref}"; then
                report "moving-base: \`${excerpt}\` measures from main, which moves as sibling work lands; record the literal base sha at groom time"
            fi
        done < "$(lines_of "$spans")"
    done < "$(lines_of "$units")"
fi

[ "$problems" -eq 0 ] || exit 1
exit 0
