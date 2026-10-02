#!/bin/bash
#
# The mechanical check behind simplify-corpus.js. It prints one report the
# workflow parses itself, so no check agent's reading of several commands
# decides a candidate.
#
# Usage:
#   simplify-check.sh <kind> <original> <candidate>
#
# kind is the workflow's classification: prose, contract, javascript,
# python, shell, rust, toml, or workflow-toml. A contract (a docket contract
# or fragment) and a workflow-toml are versioned.
#
# It runs the kind's syntax gate on the candidate. For Markdown it runs
# protected-spans.sh subset, so the candidate invents or alters no code
# block, quotation, link, or comment, and compares the frontmatter, where a
# contract may change only its version line. It reads both files' versions
# and measures both:
#   gate <name> ok | gate <name> failed: <first error line> | gate none
#   kind <name> ok | kind <name> changed: <detail>
#   version <original> <candidate>       -1 when the file declares none
#   bytes <original> <candidate>
#   lines <original> <candidate>
#   result intact|changed
# Exit 0 when intact, 1 when the gate failed or a kind changed, 2 on a usage
# or read error. Whether the version went up is the workflow's decision; the
# report carries both numbers.
#
# Bash 3.2 and POSIX awk. The JavaScript gate writes one temporary module
# copy under $TMPDIR and removes it.

set -uo pipefail
export LC_ALL=C

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

usage() {
    echo "usage: simplify-check.sh prose|contract|javascript|python|shell|rust|toml|workflow-toml <original> <candidate>" >&2
    exit 2
}

[ $# -eq 3 ] || usage
kind=$1 original=$2 candidate=$3
case "$kind" in
    prose | contract | javascript | python | shell | rust | toml | workflow-toml) ;;
    *) usage ;;
esac
for f in "$original" "$candidate"; do
    [ -f "$f" ] && [ -r "$f" ] || { echo "simplify-check: cannot read $f" >&2; exit 2; }
done

status=0

# gate <name> <command...>: run it, and report ok or the first output line
# that names an error (node prints the location first and the error later).
gate() {
    local name=$1 out rc line
    shift
    out=$("$@" 2>&1)
    rc=$?
    if [ "$rc" -eq 0 ]; then
        echo "gate $name ok"
        return
    fi
    line=$(printf '%s\n' "$out" | grep -m 1 -i 'error')
    [ -n "$line" ] || line=$(printf '%s\n' "${out:-exit $rc}" | sed '/^[[:space:]]*$/d' | head -n 1)
    echo "gate $name failed: $(printf '%s' "$line" | cut -c 1-200)"
    status=1
}

# A workflow script is an ES module with a top-level return, which a bare
# module rejects; neutralize only a column-0 return, as the module parse
# suite does, and check the copy in module mode.
module_check() { # <file>
    local copy rc
    copy=$(mktemp "${TMPDIR:-/tmp}/simplify-check.XXXXXX") || return 2
    mv "$copy" "$copy.mjs" || return 2
    copy="$copy.mjs"
    sed -e 's/^return[[:space:]]*$/void 0/' -e 's/^return;/void 0;/' -e 's/^return /void /' "$1" > "$copy"
    node --check "$copy"
    rc=$?
    rm -f "$copy"
    return "$rc"
}

case "$kind" in
    javascript) gate node-module module_check "$candidate" ;;
    python) gate python python3 "$HERE/syntax_check.py" python "$candidate" ;;
    shell) gate bash-n bash -n "$candidate" ;;
    rust) gate rustfmt rustfmt --check --edition 2021 "$candidate" ;;
    toml | workflow-toml) gate toml python3 "$HERE/syntax_check.py" toml "$candidate" ;;
    *) echo "gate none" ;;
esac

frontmatter() { # <file> — its frontmatter, without the version line in a contract
    if [ "$kind" = contract ]; then
        bash "$HERE/protected-spans.sh" extract frontmatter "$1" | grep -vE '^version:[[:space:]]*[0-9]+[[:space:]]*$'
    else
        bash "$HERE/protected-spans.sh" extract frontmatter "$1"
    fi
}

if [ "$kind" = prose ] || [ "$kind" = contract ]; then
    spans=$(bash "$HERE/protected-spans.sh" subset "$original" "$candidate")
    case $? in 0 | 1) ;; *) echo "simplify-check: protected-spans.sh failed" >&2; exit 2 ;; esac
    printf '%s\n' "$spans" | grep '^kind '
    printf '%s\n' "$spans" | grep -q '^kind .* changed' && status=1
    a=$(frontmatter "$original")
    b=$(frontmatter "$candidate")
    if [ "$a" = "$b" ]; then
        echo "kind frontmatter ok"
    else
        gone=$(comm -23 <(printf '%s\n' "$a" | sort) <(printf '%s\n' "$b" | sort) | sed '/^$/d' | head -n 1 | cut -c 1-160)
        added=$(comm -13 <(printf '%s\n' "$a" | sort) <(printf '%s\n' "$b" | sort) | sed '/^$/d' | head -n 1 | cut -c 1-160)
        echo "kind frontmatter changed:${gone:+ removed $gone}${added:+ added $added}"
        status=1
    fi
fi

version() { # <file>
    case "$kind" in
        contract)
            bash "$HERE/protected-spans.sh" extract frontmatter "$1" \
                | sed -n 's/^version:[[:space:]]*\([0-9][0-9]*\)[[:space:]]*$/\1/p' | head -n 1
            ;;
        workflow-toml)
            awk '
                /^\[pipeline\][[:space:]]*$/ { inside = 1; next }
                /^\[/ { inside = 0 }
                inside && /^version[[:space:]]*=[[:space:]]*[0-9]+[[:space:]]*$/ { sub(/^[^=]*=[[:space:]]*/, ""); sub(/[[:space:]]*$/, ""); print; exit }
            ' "$1"
            ;;
    esac
}

before=$(version "$original")
after=$(version "$candidate")
echo "version ${before:--1} ${after:--1}"
echo "bytes $(wc -c < "$original" | tr -d '[:space:]') $(wc -c < "$candidate" | tr -d '[:space:]')"
echo "lines $(wc -l < "$original" | tr -d '[:space:]') $(wc -l < "$candidate" | tr -d '[:space:]')"
if [ "$status" -eq 0 ]; then
    echo "result intact"
    exit 0
fi
echo "result changed"
exit 1
