#!/bin/bash

# Two invariants over the docket contract corpus's packet_includes:
#
#   1. Every packet_includes entry in every contracts/*.md resolves to an
#      existing file under the corpus root (fragments/ or contracts/).
#   2. Every contract whose executor sits on a step with non-pre gates in any
#      workflows/*.toml lists fragments/completion-gates.md — the fragment
#      that carries gate-resolution and denial-disclosure duty. A pre gate
#      (`{ name = ..., pre = true }`) runs before the step, so a seat sitting
#      only behind pre gates (verify-ac, design-qa) is excluded.
#
# CORPUS_DIR overrides the directory under test, so a mutation probe can
# point this suite at a deliberately-broken COPY under $TMPDIR without
# touching the checkout.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CORPUS="${CORPUS_DIR:-${SCRIPT_DIR}/../src/user/docket/config}"

fail=0

# ---- 1. packet_includes entries resolve to real files ---------------------

check_includes() { # <contracts-dir>
    local dir="$1" file rel
    shopt -s nullglob
    for file in "$dir"/*.md; do
        while IFS= read -r rel; do
            [ -n "$rel" ] || continue
            if [ ! -f "${CORPUS}/${rel}" ]; then
                echo "FAIL $(basename "$file"): packet_includes entry '${rel}' does not resolve under ${CORPUS}"
                fail=1
            fi
        done < <(awk '
            /^packet_includes:/ { in_list = 1; next }
            in_list && /^[[:space:]]*-[[:space:]]/ {
                line = $0
                sub(/^[[:space:]]*-[[:space:]]*/, "", line)
                gsub(/[[:space:]]+$/, "", line)
                print line
                next
            }
            in_list { in_list = 0 }
        ' "$file")
    done
    shopt -u nullglob
}

check_includes "${CORPUS}/contracts"

# ---- 2. every non-pre-gated executor's contract carries completion-gates --

# Extract, per workflow file, the set of executor names that sit on at least
# one step whose `gates` array has at least one non-pre entry. Fields inside
# one [[step]] block are declared in alphabetical order in this corpus
# (executor before gates before name), so a block-scoped scan bounded by
# `[[step]]` markers reads each step's own executor/gates pair correctly.
non_pre_gated_executors() { # <workflow-file>
    awk '
        function flush() {
            # Fanout steps (spec-project'"'"'s spec-author) carry no `executor`
            # key; the executor identity is the packet template name instead.
            ex = executor
            if (ex == "" && packet ~ /contracts\//) {
                ex = packet
                sub(/^.*contracts\//, "", ex)
                sub(/\.md.*$/, "", ex)
            }
            if (ex != "" && have_gates && non_pre) print ex
            executor = ""; packet = ""; have_gates = 0; non_pre = 0
        }
        /^\[\[step\]\]/ { flush() }
        /^executor[[:space:]]*=/ {
            line = $0
            sub(/^executor[[:space:]]*=[[:space:]]*"/, "", line)
            sub(/".*/, "", line)
            executor = line
        }
        /^packet[[:space:]]*=/ {
            line = $0
            sub(/^packet[[:space:]]*=[[:space:]]*\[[[:space:]]*"/, "", line)
            sub(/".*/, "", line)
            packet = line
        }
        /^gates[[:space:]]*=/ {
            have_gates = 1
            gates_line = $0
            sub(/^gates[[:space:]]*=[[:space:]]*/, "", gates_line)
            # Non-pre: a bare-string element, or a table without "pre = true".
            # Every entry in this corpus is either a quoted string or a
            # single-line { ... } table, never nested, so two passes over the
            # same line — one with tables stripped, one over the tables
            # alone — classify every entry without a full array parser.
            non_pre = 0
            tmp = gates_line
            gsub(/\{[^}]*\}/, "", tmp)
            if (tmp ~ /"[A-Za-z0-9_-]+"/) non_pre = 1
            # Table entries without pre = true also count as non-pre.
            t = gates_line
            while (match(t, /\{[^}]*\}/)) {
                entry = substr(t, RSTART, RLENGTH)
                if (entry !~ /pre[[:space:]]*=[[:space:]]*true/) non_pre = 1
                t = substr(t, RSTART + RLENGTH)
            }
        }
        END { flush() }
    ' "$1" | sort -u
}

WORK=$(mktemp -d "${TMPDIR:-/tmp}/contract-includes.XXXXXX") || exit 2
trap 'rm -rf "$WORK"' EXIT

shopt -s nullglob
for wf in "${CORPUS}/workflows"/*.toml; do
    non_pre_gated_executors "$wf"
done | sort -u > "${WORK}/needs-gates"
shopt -u nullglob

while IFS= read -r ex; do
    [ -n "$ex" ] || continue
    contract="${CORPUS}/contracts/${ex}.md"
    if [ ! -f "$contract" ]; then
        echo "FAIL ${ex}: sits on a step with non-pre gates but no contracts/${ex}.md exists"
        fail=1
        continue
    fi
    if ! grep -q 'fragments/completion-gates\.md' "$contract"; then
        echo "FAIL ${ex}: contracts/${ex}.md sits on a step with non-pre gates but omits fragments/completion-gates.md"
        fail=1
    fi
done < "${WORK}/needs-gates"

if [ "$fail" -ne 0 ]; then
    echo "contract-includes: FAIL" >&2
    exit 1
fi
echo "contract-includes: PASS ($(wc -l < "${WORK}/needs-gates" | tr -d ' ') non-pre-gated executors checked)"
