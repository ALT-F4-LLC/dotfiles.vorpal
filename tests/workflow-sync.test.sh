#!/bin/bash

# Drift check for the deliberately duplicated code in wave.js and tribunal.js.
#
# A workflow script has no module resolution and no file access at run time,
# so the TOML policy parser and the seat contract cannot live in a shared
# module — each script carries its own copy, fenced by
# `// SYNC-BEGIN <region>` / `// SYNC-END <region>` markers. This suite
# extracts every fenced region from both files, normalizes the one legitimate
# difference (each copy names its own file in error messages), and diffs.
# Any other byte of drift is a failure.
#
# WORKFLOWS_DIR overrides the directory under test, so a mutation probe can
# point the suite at a deliberately-drifted COPY under $TMPDIR and observe
# red without touching the checkout.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
WORKFLOWS="${WORKFLOWS_DIR:-${SCRIPT_DIR}/../src/user/claude_code/workflows}"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/workflow-sync.XXXXXX")
trap 'rm -rf "$WORK"' EXIT

REGIONS=(policy-parser seat-contract)

extract() { # <file> <region> — fenced region body, self-names normalized
    awk -v r="$2" '
        index($0, "SYNC-END " r)   { open = 0; ends++ }
        open                       { print }
        index($0, "SYNC-BEGIN " r) { open = 1; begins++ }
        END {
            if (begins != 1 || ends != 1) {
                printf "expected exactly one SYNC-BEGIN/SYNC-END pair for %s, found %d/%d\n", r, begins, ends > "/dev/stderr"
                exit 1
            }
        }
    ' "$1" | sed -e 's/wave\.js/SELF/g' -e 's/tribunal\.js/SELF/g'
}

fail=0
for region in "${REGIONS[@]}"; do
    if ! a=$(extract "${WORKFLOWS}/wave.js" "$region"); then
        echo "FAIL ${region}: bad or missing markers in wave.js"
        fail=1
        continue
    fi
    if ! b=$(extract "${WORKFLOWS}/tribunal.js" "$region"); then
        echo "FAIL ${region}: bad or missing markers in tribunal.js"
        fail=1
        continue
    fi
    if [ -z "$a" ] || [ -z "$b" ]; then
        echo "FAIL ${region}: fenced region is empty"
        fail=1
        continue
    fi
    printf '%s\n' "$a" > "${WORK}/wave"
    printf '%s\n' "$b" > "${WORK}/tribunal"
    if delta=$(diff "${WORK}/wave" "${WORK}/tribunal"); then
        lines=$(printf '%s\n' "$a" | wc -l | tr -d ' ')
        echo "ok   ${region} (${lines} lines)"
    else
        echo "FAIL ${region}: wave.js and tribunal.js have drifted"
        printf '%s\n' "$delta"
        fail=1
    fi
done

if [ "$fail" -ne 0 ]; then
    echo "workflow-sync: FAIL — the duplicated regions must match; edit both or neither." >&2
    exit 1
fi
echo "workflow-sync: PASS"
