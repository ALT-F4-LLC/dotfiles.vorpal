#!/usr/bin/env bash
#
# scope-lint — check that an issue's `files` and `scope` cover every
# repository path its acceptance criteria name and the test beside each Go
# file it lists, so docket-groom and docket-plan never call an issue
# run-ready whose executor must cross its own declared scope.
#
# Usage: docket issue show <id> --json | scope-lint.sh --base <sha> [--repo <dir>]
#        scope-lint.sh --base <sha> [--repo <dir>] <issue.json>
#   Reads the `docket issue show --json` envelope from the named file or
#   stdin. --base is the commit paths resolve at (the checkout HEAD sha);
#   --repo is the git checkout to read it from, the current directory by
#   default.
#
# The criteria text is the description's section under an `Acceptance
# criteria` heading or bold `**Acceptance criteria**` label, up to the next
# heading of the same or a higher level (any heading after a bold label),
# or the whole description when it has neither. Lines inside ``` or ~~~
# fences are never headings. A token in it, a run of letters, digits and
# `_.-/` without trailing dots, is a repository path when:
#   - it holds a `/`: the file exists at --base, or the name has an
#     extension and its directory exists there (a file the change creates).
#   - it is a bare name with an extension or a leading dot: exactly one file
#     at --base has that name.
#   - it is any other bare name: a file of that name sits at the root.
# A trailing `:N` line citation is not part of the path. Each such path must
# appear in `files` and match a `scope` glob. Each `files` entry `x.go` whose
# `x_test.go` exists at --base needs that test matched by a `scope` glob.
#
# Scope globs match as the engine applies them, as git pathspecs filtering
# the step's diff: a glob without `*`, `?` or `[` covers that path and
# everything under it; otherwise `*` matches any run of characters, `/`
# included (so `**` is `*`), `?` any one character, and `[...]` a character
# class (`[!...]` negates). Braces are literal.
#
# Read-only: it runs git rev-parse and ls-tree against --base and writes
# nothing. Exit 0 with no output when everything is covered, 1 with one line
# per gap on stdout, 2 on a usage error, an unreadable base, or input that is
# not an issue envelope.

set -euo pipefail

usage() {
    printf 'usage: scope-lint.sh --base <sha> [--repo <dir>] [issue.json]\n' >&2
    exit 2
}

base=""
repo="."
input=""
while [ $# -gt 0 ]; do
    case "$1" in
        --base) [ $# -ge 2 ] || usage; base="$2"; shift 2 ;;
        --repo) [ $# -ge 2 ] || usage; repo="$2"; shift 2 ;;
        -h | --help) usage ;;
        -*) usage ;;
        *) [ -z "$input" ] || usage; input="$1"; shift ;;
    esac
done
[ -n "$base" ] || usage
if ! commit=$(git -C "$repo" rev-parse --verify --quiet "${base}^{commit}"); then
    printf 'scope-lint: --base %s is not a commit in %s\n' "$base" "$repo" >&2
    exit 2
fi

if [ -n "$input" ]; then
    envelope=$(cat -- "$input")
else
    envelope=$(cat)
fi
shape='.data | (.description | type == "string")
    and ((.files // []) | type == "array")
    and ((.scope // []) | type == "array")'
if ! printf '%s' "$envelope" | jq -e "$shape" >/dev/null 2>&1; then
    printf 'scope-lint: input is not a `docket issue show --json` envelope\n' >&2
    exit 2
fi
description=$(printf '%s' "$envelope" | jq -r '.data.description')
files=$(printf '%s' "$envelope" | jq -r '(.data.files // [])[]')
scope=$(printf '%s' "$envelope" | jq -r '(.data.scope // [])[]')

criteria=$(printf '%s\n' "$description" | awk '
    /^[ \t]*(```|~~~)/ { fenced = !fenced }
    !fenced && tolower($0) ~ /^(#+[ \t]+acceptance criteria|\*\*acceptance criteria:?\*\*)/ {
        level = match($0, /^#+/) ? RLENGTH : 6; inside = 1; found = 1; next
    }
    inside && !fenced && /^#+[ \t]/ { match($0, /^#+/); if (RLENGTH <= level) inside = 0 }
    inside { print }
    { all = all $0 "\n" }
    END { if (!found) printf "%s", all }
')

tokens=$(printf '%s\n' "$criteria" | awk '
{
    line = $0
    while (match(line, /[A-Za-z0-9_.\/-]+/)) {
        tok = substr(line, RSTART, RLENGTH)
        line = substr(line, RSTART + RLENGTH)
        sub(/\.+$/, "", tok)
        if (tok != "") print tok
    }
}' | sort -u)

tree=$(git -C "$repo" ls-tree -r --full-tree --name-only "$commit")
dirs=$(git -C "$repo" ls-tree -r -d --full-tree --name-only "$commit")
in_list() { # <item> <newline-separated list>
    grep -Fxq -- "$1" <<<"$2"
}

ac_paths=""
while IFS= read -r tok; do
    [ -n "$tok" ] || continue
    case "$tok" in
        */)
            continue
            ;;
        */*)
            if ! in_list "$tok" "$tree"; then
                case "${tok##*/}" in
                    ?*.[A-Za-z0-9]*) in_list "${tok%/*}" "$dirs" || continue ;;
                    *) continue ;;
                esac
            fi
            path="$tok"
            ;;
        ?*.?* | .?*)
            path=$(printf '%s\n' "$tree" | awk -v n="$tok" '$0 == n || substr($0, length($0) - length(n)) == "/" n')
            [ -n "$path" ] && [ "$(printf '%s\n' "$path" | wc -l)" -eq 1 ] || continue
            ;;
        *)
            in_list "$tok" "$tree" || continue
            path="$tok"
            ;;
    esac
    ac_paths="${ac_paths}${path}"$'\n'
done <<<"$tokens"
ac_paths=$(printf '%s' "$ac_paths" | sort -u)

# Rows to check against scope: path, then why it must be in scope.
scope_rows=""
while IFS= read -r path; do
    [ -n "$path" ] || continue
    scope_rows="${scope_rows}${path}"$'\t'"named by the acceptance criteria"$'\n'
done <<<"$ac_paths"
while IFS= read -r file; do
    case "$file" in
        *_test.go | "") continue ;;
        *.go) ;;
        *) continue ;;
    esac
    sibling="${file%.go}_test.go"
    in_list "$sibling" "$tree" || continue
    scope_rows="${scope_rows}${sibling}"$'\t'"test beside ${file}"$'\n'
done <<<"$files"

problems=0
while IFS= read -r path; do
    [ -n "$path" ] || continue
    if ! in_list "$path" "$files"; then
        problems=$((problems + 1))
        printf 'missing from files: %s (named by the acceptance criteria)\n' "$path"
    fi
done <<<"$ac_paths"

outside=$(printf '%s' "$scope_rows" | SCOPE_LINT_GLOBS="$scope" awk -F '\t' '
function literal_re(c) {
    if (c == "^" || c == "\\") return "\\" c
    if (index(".+()|{}$[]*?", c)) return "[" c "]"
    return c
}
function glob_re(g,   out, i, n, c, j, cls) {
    out = "^"; n = length(g)
    for (i = 1; i <= n; i++) {
        c = substr(g, i, 1)
        if (c == "*") out = out ".*"
        else if (c == "?") out = out "."
        else if (c == "[" && (j = index(substr(g, i + 1), "]")) > 1) {
            cls = substr(g, i + 1, j - 1)
            if (substr(cls, 1, 1) == "!") cls = "^" substr(cls, 2)
            out = out "[" cls "]"; i += j
        }
        else if (c == "\\" && i < n) out = out literal_re(substr(g, ++i, 1))
        else out = out literal_re(c)
    }
    return out "$"
}
function covers(g, path) {
    if (g ~ /[*?[]/) return path ~ glob_re(g)
    sub(/\/+$/, "", g)
    return path == g || index(path, g "/") == 1
}
BEGIN { count = split(ENVIRON["SCOPE_LINT_GLOBS"], globs, "\n") }
{
    for (k = 1; k <= count; k++) if (globs[k] != "" && covers(globs[k], $1)) next
    printf "outside scope: %s (%s)\n", $1, $2
}')
if [ -n "$outside" ]; then
    problems=$((problems + $(printf '%s\n' "$outside" | wc -l)))
    printf '%s\n' "$outside"
fi

[ "$problems" -eq 0 ] || exit 1
exit 0
