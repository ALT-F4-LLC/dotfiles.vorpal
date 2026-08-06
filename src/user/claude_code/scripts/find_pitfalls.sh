#!/bin/bash
# Wraps the CANONICAL:HARVEST cross-project pitfalls-manifest find block
# (src/user/claude-code/skills/team-doctrine/references/evolve-phase0-templates.md
# §2) into a single reusable script, replacing the 2-command find block
# hand-retyped/re-run inline by every historical-auditor Phase-0 spawn.
set -euo pipefail

usage() {
    echo "Usage: find_pitfalls.sh" >&2
    echo "  Enumerates pitfalls.md files under \$HOME/Development (in-repo" >&2
    echo "  homes, pruning node_modules/.git, maxdepth 12) and under the" >&2
    echo "  centralized \$HOME/.claude/agent-memory home (maxdepth 2)." >&2
    echo "  Prints the sorted, de-duped union of both, one path per line." >&2
    echo "  Read-only; an absent root is a no-op for that half." >&2
    exit 1
}

if [ "$#" -ne 0 ]; then
    usage
fi

DEV_ROOT="$HOME/Development"
CENTRAL_ROOT="$HOME/.claude/agent-memory"

{
    if [ -d "$DEV_ROOT" ]; then
        find "$DEV_ROOT" -maxdepth 12 \( -name node_modules -o -name '.git' \) -prune \
            -o -type f -path '*/.claude/agent-memory/*/pitfalls.md' -print
    fi
    if [ -d "$CENTRAL_ROOT" ]; then
        find "$CENTRAL_ROOT" -maxdepth 2 -type f -name 'pitfalls.md' -print
    fi
} 2>/dev/null | sort -u
