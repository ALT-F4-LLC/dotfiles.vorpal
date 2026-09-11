#!/bin/bash

# synthesize-findings.md restates findings-cluster@3's top-level key names in
# prose (a fenced sentence, CLUSTER-KEYS-BEGIN/END, in its ## Payload
# section). Nothing else compares the restatement to the schema: if the
# schema gains, drops, or renames a key, the prose can go stale silently and
# start teaching synth steps a shape the engine will refuse at record.
#
# This suite extracts the backticked names from the fence, reads the
# schema's `.items.required` and `.items.properties` with jq, and fails on
# any set difference — both directions: a name the fence claims that the
# schema lacks, and a schema property the fence omits. It also asserts every
# required key is named in the fence, since the fence covers the full
# property set, required and optional together.
#
# CORPUS_DIR overrides the directory under test, so a mutation probe can
# point this suite at a deliberately-broken COPY under $TMPDIR without
# touching the checkout.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CORPUS="${CORPUS_DIR:-${SCRIPT_DIR}/../src/user/docket/config}"

CONTRACT="${CORPUS}/contracts/synthesize-findings.md"
SCHEMA="${CORPUS}/schemas/findings-cluster@3.json"

if ! command -v jq >/dev/null 2>&1; then
    echo "contract-cluster-keys: FAIL — jq is required and not on PATH." >&2
    exit 2
fi

if [ ! -f "$CONTRACT" ]; then
    echo "contract-cluster-keys: FAIL — no contract at ${CONTRACT}" >&2
    exit 2
fi
if [ ! -f "$SCHEMA" ]; then
    echo "contract-cluster-keys: FAIL — no schema at ${SCHEMA}" >&2
    exit 2
fi

WORK=$(mktemp -d "${TMPDIR:-/tmp}/contract-cluster-keys.XXXXXX") || exit 2
trap 'rm -rf "$WORK"' EXIT

# The fenced sentence's backticked names, one per line, sorted+deduped.
fence_keys() {
    awk '
        /CLUSTER-KEYS-BEGIN/ { in_fence = 1; next }
        /CLUSTER-KEYS-END/   { in_fence = 0 }
        in_fence             { print }
    ' "$CONTRACT" | grep -o '`[A-Za-z][A-Za-z0-9_]*`' | tr -d '`' | sort -u
}

fence_keys > "${WORK}/fence"
if [ ! -s "${WORK}/fence" ]; then
    echo "contract-cluster-keys: FAIL — no CLUSTER-KEYS-BEGIN/END fence found (or it named no keys) in ${CONTRACT}" >&2
    exit 1
fi

jq -r '.items.properties | keys[]' "$SCHEMA" | sort -u > "${WORK}/schema-properties"
jq -r '.items.required[]' "$SCHEMA" | sort -u > "${WORK}/schema-required"

if [ ! -s "${WORK}/schema-properties" ]; then
    echo "contract-cluster-keys: FAIL — schema has no .items.properties" >&2
    exit 2
fi

fail=0

comm -23 "${WORK}/fence" "${WORK}/schema-properties" > "${WORK}/fence-only"
while read -r key; do
    [ -n "$key" ] || continue
    echo "FAIL ${key}: fenced in the contract but not a findings-cluster@3 property"
    fail=1
done < "${WORK}/fence-only"

comm -13 "${WORK}/fence" "${WORK}/schema-properties" > "${WORK}/schema-only"
while read -r key; do
    [ -n "$key" ] || continue
    echo "FAIL ${key}: a findings-cluster@3 property the contract's fence omits"
    fail=1
done < "${WORK}/schema-only"

comm -23 "${WORK}/schema-required" "${WORK}/fence" > "${WORK}/required-missing"
while read -r key; do
    [ -n "$key" ] || continue
    echo "FAIL ${key}: required by findings-cluster@3 but not named in the contract's fence"
    fail=1
done < "${WORK}/required-missing"

if [ "$fail" -ne 0 ]; then
    echo "contract-cluster-keys: FAIL" >&2
    exit 1
fi
echo "contract-cluster-keys: PASS ($(wc -l < "${WORK}/fence" | tr -d ' ') keys checked against findings-cluster@3)"
