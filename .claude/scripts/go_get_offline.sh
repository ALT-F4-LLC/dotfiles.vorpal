#!/bin/bash
# Adds a Go module dependency in a network-restricted sandbox (GOPROXY=off)
# by pointing GOPROXY at the local module download cache as a file proxy,
# replacing the manual DL=... one-liner agents previously typed per invocation.
set -euo pipefail

usage() {
    echo "Usage: go_get_offline.sh <module> <version>" >&2
    echo "  Runs 'go get <module>@<version>' then 'go mod tidy' with GOPROXY" >&2
    echo "  pointed at the local module cache (file://\$(go env GOMODCACHE)/cache/download)" >&2
    echo "  and GOSUMDB=off, so no live network lookup is required." >&2
    echo "  Fails if go.sum loses any existing line (only growth is expected)." >&2
    exit 1
}

if [ "$#" -ne 2 ]; then
    usage
fi

MODULE="$1"
VERSION="$2"

if [ ! -f go.mod ]; then
    echo "go_get_offline.sh: no go.mod in $(pwd) — run from a Go module root" >&2
    exit 1
fi

DL="$(go env GOMODCACHE)/cache/download"

SUM_BEFORE=$(mktemp "${TMPDIR:-/tmp}/go_get_offline.XXXXXX")
trap 'rm -f "$SUM_BEFORE"' EXIT
[ -f go.sum ] && cp go.sum "$SUM_BEFORE" || : > "$SUM_BEFORE"

GOPROXY="file://${DL}" GOSUMDB=off go get "${MODULE}@${VERSION}"
GOPROXY="file://${DL}" GOSUMDB=off go mod tidy

REMOVED=$(comm -23 <(sort "$SUM_BEFORE") <(sort go.sum))
if [ -n "$REMOVED" ]; then
    echo "go_get_offline.sh: go.sum lost existing line(s) — expected growth only:" >&2
    echo "$REMOVED" >&2
    exit 1
fi

echo "go_get_offline.sh: added ${MODULE}@${VERSION} offline; go.sum grew only"
