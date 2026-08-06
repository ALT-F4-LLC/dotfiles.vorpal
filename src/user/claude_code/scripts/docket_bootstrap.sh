#!/bin/bash
# Chains init + version into one call, replacing the manual 2-command
# sequence agents previously typed by hand at session start.
set -euo pipefail

usage() {
    echo "Usage: docket_bootstrap.sh" >&2
    echo "  Runs: docket init && docket version --quiet" >&2
    echo "  Guards cwd to repo root." >&2
    exit 1
}

if [ "$#" -ne 0 ]; then
    usage
fi

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "docket_bootstrap.sh: not inside a git repository" >&2
    exit 1
}
cd "$REPO_ROOT"

docket init
docket version --quiet
