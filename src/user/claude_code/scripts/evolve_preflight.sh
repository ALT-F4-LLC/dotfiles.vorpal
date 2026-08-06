#!/bin/bash
# Single-homes the {today_date}/{scratchpad}/{history_cutoff_iso,epoch_ms}/
# transcript-probe/{drift_rate,drift_seed}/{claude_version,changelog_source} parameter
# chain duplicated near-verbatim across the Pre-flight sections of evolve-agents,
# evolve-skills, evolve-config, and (partially, --drift omitted) evolve-model-distribution
# SKILL.md (DKT-292 / DKT-285 item 3). Digest distillation and the WebFetch fallback stay
# in skill prose -- bash can neither summarize nor invoke a WebFetch tool call.
set -euo pipefail

usage() {
    echo "Usage: evolve_preflight.sh --cycle <name> [--days N] [--drift N]" >&2
    echo "  --cycle <name>  cycle identity for scratchpad + drift-seed derivation" >&2
    echo "                  (e.g. evolve-agents, evolve-skills, evolve-config)" >&2
    echo "  --days N        historical-audit window in days, 1..90 (default 7)" >&2
    echo "  --drift N       genetic-drift rate, integer >= 0; when present, also" >&2
    echo "                  emits the reproducible drift_seed. Omit entirely for" >&2
    echo "                  skills with no genetic-drift operator (e.g." >&2
    echo "                  evolve-model-distribution)." >&2
    echo >&2
    echo "Emits KEY=value lines to stdout:" >&2
    echo "  today_date              YYYY-MM-DD" >&2
    echo "  scratchpad               \${TMPDIR}/<cycle-name>-<today_date>, expanded absolute path" >&2
    echo "  history_cutoff_iso      UTC ISO-8601, \${days} days ago" >&2
    echo "  history_cutoff_epoch_ms same instant, epoch milliseconds" >&2
    echo "  transcript_probe        path to a matching transcript, or a" >&2
    echo "                          'SKIPPED: no transcripts in last N days' sentinel" >&2
    echo "  drift_rate              only when --drift is passed" >&2
    echo "  drift_seed              only when --drift is passed (decimal integer converted" >&2
    echo "                          from an 8-hex-char shasum digest, for drift_target.sh's" >&2
    echo "                          decimal-only seed arg)" >&2
    echo "  claude_version          only when --drift is passed; SKIPPED sentinel if the probe fails" >&2
    echo "  changelog_source        only when --drift is passed; path to raw CHANGELOG.md to Read" >&2
    echo "                          and distil, or a CURL_FAILED:/SKIPPED: sentinel" >&2
    exit 1
}

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "evolve_preflight.sh: not inside a git repository" >&2
    exit 1
}
cd "$REPO_ROOT"

CYCLE=""
DAYS=7
DRIFT=""
HAVE_DRIFT=0

while [ "$#" -gt 0 ]; do
    case "$1" in
        --cycle)
            [ "$#" -ge 2 ] || usage
            CYCLE="$2"
            shift 2
            ;;
        --days)
            [ "$#" -ge 2 ] || usage
            DAYS="$2"
            shift 2
            ;;
        --drift)
            [ "$#" -ge 2 ] || usage
            DRIFT="$2"
            HAVE_DRIFT=1
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            usage
            ;;
    esac
done

[ -n "$CYCLE" ] || usage

case "$DAYS" in
    ''|*[!0-9]*)
        echo "evolve_preflight.sh: --days must be a non-negative integer (got '${DAYS}')" >&2
        exit 1
        ;;
esac
if [ "$DAYS" -lt 1 ] || [ "$DAYS" -gt 90 ]; then
    echo "evolve_preflight.sh: --days must be in 1..90 (got ${DAYS})" >&2
    exit 1
fi

if [ "$HAVE_DRIFT" -eq 1 ]; then
    case "$DRIFT" in
        ''|*[!0-9]*)
            echo "evolve_preflight.sh: --drift must be a non-negative integer (got '${DRIFT}')" >&2
            exit 1
            ;;
    esac
fi

TODAY_DATE=$(date +%Y-%m-%d)
SCRATCHPAD="${TMPDIR:-/tmp}/${CYCLE}-${TODAY_DATE}"

if [ "$(uname)" = "Darwin" ]; then
    HISTORY_CUTOFF_ISO=$(date -u -v-"${DAYS}"d +%Y-%m-%dT%H:%M:%SZ)
    HISTORY_CUTOFF_EPOCH_S=$(date -u -v-"${DAYS}"d +%s)
else
    HISTORY_CUTOFF_ISO=$(date -u -d "${DAYS} days ago" +%Y-%m-%dT%H:%M:%SZ)
    HISTORY_CUTOFF_EPOCH_S=$(date -u -d "${DAYS} days ago" +%s)
fi
HISTORY_CUTOFF_EPOCH_MS=$(( HISTORY_CUTOFF_EPOCH_S * 1000 ))

TRANSCRIPT_PROBE=$(find ~/.claude/projects -name "*.jsonl" -mtime -"${DAYS}" -print -quit 2>/dev/null)
if [ -z "$TRANSCRIPT_PROBE" ]; then
    TRANSCRIPT_PROBE="SKIPPED: no transcripts in last ${DAYS} days"
fi

echo "today_date=${TODAY_DATE}"
echo "scratchpad=${SCRATCHPAD}"
echo "history_cutoff_iso=${HISTORY_CUTOFF_ISO}"
echo "history_cutoff_epoch_ms=${HISTORY_CUTOFF_EPOCH_MS}"
echo "transcript_probe=${TRANSCRIPT_PROBE}"

if [ "$HAVE_DRIFT" -eq 1 ]; then
    DRIFT_SEED_HEX=$(printf '%s' "${CYCLE}-${TODAY_DATE}" | shasum | cut -c1-8)
    DRIFT_SEED=$(( 16#${DRIFT_SEED_HEX} ))
    echo "drift_rate=${DRIFT}"
    echo "drift_seed=${DRIFT_SEED}"

    CHANGELOG_URL="https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md"
    if CLAUDE_VERSION=$(claude --version 2>/dev/null) && [ -n "$CLAUDE_VERSION" ]; then
        CACHE_DIR="${HOME}/.claude/cache"
        CACHE_FILE="${CACHE_DIR}/changelog.md"
        CACHE_FRESH=0
        if [ -f "$CACHE_FILE" ]; then
            if [ "$(uname)" = "Darwin" ]; then
                CACHE_MTIME=$(stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)
            else
                CACHE_MTIME=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)
            fi
            CACHE_AGE_S=$(( $(date +%s) - CACHE_MTIME ))
            [ "$CACHE_AGE_S" -lt 86400 ] && CACHE_FRESH=1
        fi
        if [ "$CACHE_FRESH" -eq 1 ]; then
            CHANGELOG_SOURCE="$CACHE_FILE"
        elif FETCHED=$(curl -fsSL "$CHANGELOG_URL" 2>/dev/null) && [ -n "$FETCHED" ]; then
            mkdir -p "$CACHE_DIR" 2>/dev/null || true
            if printf '%s' "$FETCHED" >"$CACHE_FILE" 2>/dev/null; then
                CHANGELOG_SOURCE="$CACHE_FILE"
            else
                FALLBACK_FILE="${TMPDIR:-/tmp}/evolve-preflight-changelog-${CYCLE}-${TODAY_DATE}.md"
                printf '%s' "$FETCHED" >"$FALLBACK_FILE"
                CHANGELOG_SOURCE="$FALLBACK_FILE"
            fi
        else
            CHANGELOG_SOURCE="CURL_FAILED: try WebFetch ${CHANGELOG_URL} (requires a WebFetch grant for raw.githubusercontent.com + code.claude.com + mimir.bulbasaur.altf4.domains), else SKIPPED: claude --version or changelog fetch unavailable -- researcher uses its own WebSearch/WebFetch as primary"
        fi
    else
        CLAUDE_VERSION="SKIPPED: claude --version unavailable"
        CHANGELOG_SOURCE="SKIPPED: claude --version or changelog fetch unavailable -- researcher uses its own WebSearch/WebFetch as primary"
    fi
    echo "claude_version=${CLAUDE_VERSION}"
    echo "changelog_source=${CHANGELOG_SOURCE}"
fi
