#!/bin/bash
# Wraps the `find ~/.claude/projects -name '*.jsonl' -mtime -N` transcript-
# discovery pattern re-typed verbatim across historical-auditor,
# repetition-auditor, and bug-auditor Phase-0 spawn prompts
# (src/user/claude-code/skills/team-doctrine/references/evolve-phase0-templates.md).
set -euo pipefail

usage() {
    echo "Usage: recent_transcripts.sh [days] [-0|--print0]" >&2
    echo "  Enumerates \$HOME/.claude/projects/**/*.jsonl transcripts modified" >&2
    echo "  within the last <days> days. Default 7, matching evolve-agents'" >&2
    echo "  pre-flight history-window default (valid range: 1-90)." >&2
    echo "  Prints one path per line by default; -0/--print0 emits NUL-" >&2
    echo "  delimited paths for piping to 'xargs -0' (matches the -print0" >&2
    echo "  form used by the repetition/bug-audit templates)." >&2
    exit 1
}

DAYS=7
DAYS_SET=""
PRINT0=0

for ARG in "$@"; do
    case "$ARG" in
        -0|--print0)
            PRINT0=1
            ;;
        -h|--help)
            usage
            ;;
        *)
            if [ -n "$DAYS_SET" ]; then
                usage
            fi
            DAYS="$ARG"
            DAYS_SET=1
            ;;
    esac
done

case "$DAYS" in
    ''|*[!0-9]*)
        echo "recent_transcripts.sh: days must be a positive integer, got '${DAYS}'" >&2
        exit 1
        ;;
esac

if [ "$DAYS" -lt 1 ] || [ "$DAYS" -gt 90 ]; then
    echo "recent_transcripts.sh: days must be in range 1-90, got '${DAYS}'" >&2
    exit 1
fi

TRANSCRIPTS_DIR="$HOME/.claude/projects"

if [ ! -d "$TRANSCRIPTS_DIR" ]; then
    echo "recent_transcripts.sh: no transcripts directory at ${TRANSCRIPTS_DIR} (no-op)" >&2
    exit 0
fi

if [ "$PRINT0" -eq 1 ]; then
    find "$TRANSCRIPTS_DIR" -name '*.jsonl' -mtime "-${DAYS}" -print0
else
    find "$TRANSCRIPTS_DIR" -name '*.jsonl' -mtime "-${DAYS}"
fi
