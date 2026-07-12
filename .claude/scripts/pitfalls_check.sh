#!/bin/bash
# Shared existence-check + mkdir -p bootstrap for the CANONICAL:PITFALLS
# two-homes convention (src/user/claude-code/skills/team-doctrine/references/pitfalls.md),
# replacing the "mkdir -p the target dir if absent" boilerplate reinvented
# inline by every agent file carrying that block. Does NOT decide which home
# to use — the in-repo-vs-centralized write-gate judgment call stays with the
# calling agent; this script only bootstraps the already-chosen home.
set -euo pipefail

usage() {
    echo "Usage: pitfalls_check.sh <role> <in-repo|centralized>" >&2
    echo "  Resolves the pitfalls.md path for <role> under the chosen home," >&2
    echo "  mkdir -p's its parent directory if absent, and prints the" >&2
    echo "  resolved absolute path to stdout. The file itself is left for" >&2
    echo "  the caller's append (e.g. cat >> \"\$path\") to create." >&2
    echo "  in-repo   -> <repo-root>/.claude/agent-memory/<role>/pitfalls.md" >&2
    echo "  centralized -> \$HOME/.claude/agent-memory/<role>/pitfalls.md" >&2
    exit 1
}

if [ "$#" -ne 2 ]; then
    usage
fi

ROLE="$1"
HOME_KIND="$2"

case "$ROLE" in
    ''|*[!a-zA-Z0-9_-]*)
        echo "pitfalls_check.sh: invalid role '${ROLE}' (expected alnum/hyphen/underscore)" >&2
        exit 1
        ;;
esac

case "$HOME_KIND" in
    in-repo)
        REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
            echo "pitfalls_check.sh: not inside a git repository" >&2
            exit 1
        }
        TARGET_DIR="$REPO_ROOT/.claude/agent-memory/$ROLE"
        ;;
    centralized)
        TARGET_DIR="$HOME/.claude/agent-memory/$ROLE"
        ;;
    *)
        usage
        ;;
esac

TARGET_FILE="$TARGET_DIR/pitfalls.md"

mkdir -p "$TARGET_DIR"

if [ -f "$TARGET_FILE" ]; then
    echo "pitfalls_check.sh: existing pitfalls.md found at $TARGET_FILE" >&2
else
    echo "pitfalls_check.sh: no pitfalls.md yet at $TARGET_FILE (directory bootstrapped)" >&2
fi

printf '%s\n' "$TARGET_FILE"
