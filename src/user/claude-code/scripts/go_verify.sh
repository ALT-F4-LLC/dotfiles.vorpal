#!/bin/bash
# Wraps `go build ./...` and `go vet ./...`, standardizing the sprawl of
# hand-rolled invocations found across sessions: silent (no output, exit 0)
# on success; full, untruncated output on failure. Defaults to
# GOTOOLCHAIN=local (no network toolchain download) but respects an
# already-exported GOTOOLCHAIN. Prefers the vorpal-managed go:1.26.0
# toolchain per vorpal-tools.md, falling back to a natively installed `go`.
set -uo pipefail

usage() {
    echo "Usage: go_verify.sh [module-dir]" >&2
    echo "  Runs 'go build ./...' then 'go vet ./...' against the Go module" >&2
    echo "  in [module-dir] (default: current directory)." >&2
    echo "  Silent with exit 0 on success; full combined output and the" >&2
    echo "  failing command's exit code on failure." >&2
    echo "  Go version override: GO_VERIFY_GO_VERSION (default: 1.26.0)." >&2
    exit 2
}

case "${1:-}" in
    -h|--help) usage ;;
esac

MODDIR="${1:-.}"
GO_VERSION="${GO_VERIFY_GO_VERSION:-1.26.0}"

[ -d "$MODDIR" ] || {
    echo "go_verify.sh: directory not found: ${MODDIR}" >&2
    exit 2
}
MODDIR=$(cd "$MODDIR" && pwd)

[ -f "$MODDIR/go.mod" ] || {
    echo "go_verify.sh: no go.mod in ${MODDIR}" >&2
    exit 2
}

if command -v vorpal >/dev/null 2>&1; then
    GOROOT=$(vorpal run "go:${GO_VERSION}" env GOROOT 2>/dev/null) || {
        echo "go_verify.sh: failed to resolve go toolchain via 'vorpal run go:${GO_VERSION} env GOROOT'" >&2
        exit 2
    }
    GO_BIN="${GOROOT}/bin/go"
elif command -v go >/dev/null 2>&1; then
    GO_BIN=$(command -v go)
else
    echo "go_verify.sh: no go toolchain found (vorpal or native 'go')" >&2
    exit 2
fi

export GOTOOLCHAIN="${GOTOOLCHAIN:-local}"

OUTPUT=$(cd "$MODDIR" && "$GO_BIN" build ./... 2>&1 && "$GO_BIN" vet ./... 2>&1)
STATUS=$?

[ "$STATUS" -eq 0 ] && exit 0

printf '%s\n' "$OUTPUT"
exit "$STATUS"
