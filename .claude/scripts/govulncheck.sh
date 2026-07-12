#!/bin/bash
# Wraps the 4-step vorpal Go toolchain setup (GOROOT/PATH/GOPROXY/GOSUMDB) that
# `govulncheck` needs on this host, per security-engineer.md's Dependency-CVE
# guidance, so the recipe isn't hand-typed each session. Must be invoked under
# Bash(dangerouslyDisableSandbox: true) — the Go build/vuln toolchain is not
# sandbox-compatible here.
set -euo pipefail

usage() {
    echo "Usage: govulncheck.sh [govulncheck-args...]" >&2
    echo "  Resolves GOROOT via 'vorpal run go:<ver> env GOROOT', puts it on PATH," >&2
    echo "  sets GOPROXY=direct GOSUMDB=off (repo fetch posture), then runs" >&2
    echo "  'govulncheck' with the given args (default: ./...)." >&2
    echo "  Go version override: GOVULNCHECK_GO_VERSION (default: 1.26.0)." >&2
    exit 1
}

case "${1:-}" in
    -h|--help) usage ;;
esac

GO_VERSION="${GOVULNCHECK_GO_VERSION:-1.26.0}"

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "govulncheck.sh: not inside a git repository" >&2
    exit 1
}
cd "$REPO_ROOT"

command -v govulncheck >/dev/null 2>&1 || {
    echo "govulncheck.sh: 'govulncheck' not found on PATH — install via" >&2
    echo "  'go install golang.org/x/vuln/cmd/govulncheck@latest'" >&2
    exit 1
}

GOROOT=$(vorpal run "go:${GO_VERSION}" env GOROOT) || {
    echo "govulncheck.sh: failed to resolve GOROOT via 'vorpal run go:${GO_VERSION} env GOROOT'" >&2
    exit 1
}
export GOROOT
export PATH="${GOROOT}/bin:${PATH}"
export GOPROXY=direct
export GOSUMDB=off

if [ "$#" -eq 0 ]; then
    set -- ./...
fi

govulncheck "$@"
