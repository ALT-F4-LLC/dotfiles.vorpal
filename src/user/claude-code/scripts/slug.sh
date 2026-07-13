#!/bin/bash
# Shared slug derivation for the doc-authoring skills (adr, prd, tdd, ux-spec),
# previously hand-copied byte-identical into each skill's
# CANONICAL:ARGUMENT_HANDLING block. Implements the 8-step deterministic
# algorithm: lowercase -> non-alphanumeric runs to '-' -> strip -> 60-char cut
# -> prefer a word boundary in [40,60) -> re-strip -> empty check.
set -euo pipefail

usage() {
    echo "Usage: slug.sh \"<topic>\"" >&2
    exit 2
}

# Missing or empty <topic> is a usage error (exit 2); a non-empty topic with no
# alphanumeric survivors aborts at step 7 (exit 1). Extra args are ignored.
if [ "$#" -lt 1 ] || [ -z "$1" ]; then
    usage
fi

topic="$1"

lower=$(printf '%s' "$topic" | tr '[:upper:]' '[:lower:]')
cleaned=$(printf '%s' "$lower" | sed 's/[^a-z0-9]\{1,\}/-/g')
trimmed=$(printf '%s' "$cleaned" | sed 's/^-*//; s/-*$//')
truncated="${trimmed:0:60}"

len=${#truncated}
end=$(( len < 60 ? len : 60 ))
boundary=-1
i=$(( end - 1 ))
while [ "$i" -ge 40 ]; do
    if [ "${truncated:$i:1}" = "-" ]; then
        boundary=$i
        break
    fi
    i=$(( i - 1 ))
done
if [ "$boundary" -ne -1 ]; then
    truncated="${truncated:0:$boundary}"
fi

truncated=$(printf '%s' "$truncated" | sed 's/^-*//; s/-*$//')

if [ -z "$truncated" ]; then
    echo "Error: Topic must contain at least one alphanumeric character." >&2
    exit 1
fi

printf '%s\n' "$truncated"
