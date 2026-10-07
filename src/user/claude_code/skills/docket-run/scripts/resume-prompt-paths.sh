#!/usr/bin/env bash
#
# resume-prompt-paths: print | check <prompt-file> | attach <prompt-file>
#
# The paths in a docket-run resume prompt come from git and are checked when
# the prompt is recorded and again when a new session attaches
# (references/pause.md, **Resume-prompt paths**).
#
#   print   emits the cwd checkout's **Checkout:** and **Branch:** lines and a
#           **Worktree:** line per worktree entry, skipping every entry git
#           marks prunable (its directory is gone), so check passes it.
#   check   exits 1 when an absolute path in the prompt file does not exist,
#           quoting each such line on stderr; exits 0 when all exist.
#   attach  exits 1 when the prompt's Checkout is not this cwd's
#           `git rev-parse --show-toplevel`, naming both; exits 0 on a match.
#
# check reads a path as a run of two or more /-separated components starting
# at a line start, whitespace, backtick, quote or parenthesis, so RUN-N,
# /docket-run and URLs are not paths to it.
#
# Exit 2 on a usage error or a missing prompt file.
set -u
prompt=${2:-}
case "${1:-}" in
    print)
        top=$(git rev-parse --show-toplevel) || exit 1
        branch=$(git rev-parse --abbrev-ref HEAD) || exit 1
        printf '**Checkout:** `%s`\n**Branch:** `%s`\n' "$top" "$branch"
        git worktree list --porcelain | awk '
            function emit() { if (wt != "" && !prunable) printf "**Worktree:** `%s`\n", wt; wt = ""; prunable = 0 }
            /^worktree / { emit(); wt = substr($0, 10); next }
            /^prunable/ { prunable = 1; next }
            /^$/ { emit() }
            END { emit() }'
        ;;
    check)
        [ -f "$prompt" ] || { echo "resume-prompt-paths: no prompt file: $prompt" >&2; exit 2; }
        grep -noE '(^|[[:space:]`"(])/[^/[:space:]`"()]+/([^[:space:]`"()]*[^[:space:]`"().,;:])?' "$prompt" | {
            status=0
            while IFS=: read -r line_no match; do
                path=/${match#*/}
                test -e "$path" && continue
                echo "resume-prompt-paths: line $line_no names a path that does not exist: $path" >&2
                sed -n "${line_no}p" "$prompt" >&2
                status=1
            done
            exit "$status"
        }
        ;;
    attach)
        [ -f "$prompt" ] || { echo "resume-prompt-paths: no prompt file: $prompt" >&2; exit 2; }
        checkout=$(sed -n 's/^[[:space:]]*\*\*Checkout:\*\* `\([^`]*\)`.*$/\1/p' "$prompt")
        top=$(git rev-parse --show-toplevel) || exit 1
        if [ "$checkout" != "$top" ]; then
            echo "resume-prompt-paths: the prompt's Checkout is '${checkout:-<none>}' but this session's checkout is '$top'" >&2
            exit 1
        fi
        echo "resume-prompt-paths: Checkout matches $top"
        ;;
    *)
        echo "usage: bash resume-prompt-paths.sh print | check <prompt-file> | attach <prompt-file>" >&2
        exit 2
        ;;
esac
