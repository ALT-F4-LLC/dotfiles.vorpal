#!/bin/bash
# Claude Code status line script
# Receives JSON session data on stdin, outputs a single-line color-coded status bar.

set -euo pipefail

# -- Read JSON from stdin --

DATA=$(cat)

# -- Parse JSON fields with jq --

MODEL=$(echo "$DATA" | jq -r '.model.display_name // .model.id // "unknown"')
PROJECT_DIR=$(echo "$DATA" | jq -r '.workspace.project_dir // .workspace.current_dir // ""')
COST=$(echo "$DATA" | jq -r '.cost.total_cost_usd // 0')
DURATION_MS=$(echo "$DATA" | jq -r '.cost.total_duration_ms // 0')
LINES_ADDED=$(echo "$DATA" | jq -r '.cost.total_lines_added // 0')
LINES_REMOVED=$(echo "$DATA" | jq -r '.cost.total_lines_removed // 0')
INPUT_TOKENS=$(echo "$DATA" | jq -r '.context_window.current_usage.input_tokens // 0')
CACHE_CREATE=$(echo "$DATA" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')
CACHE_READ=$(echo "$DATA" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')
OUTPUT_TOKENS=$(echo "$DATA" | jq -r '.context_window.current_usage.output_tokens // 0')
CTX_SIZE=$(echo "$DATA" | jq -r '.context_window.context_window_size // 200000')
TOTAL_TOKENS=$(( INPUT_TOKENS + CACHE_CREATE + CACHE_READ + OUTPUT_TOKENS ))
if [ "$CTX_SIZE" -gt 0 ] 2>/dev/null; then
    CTX_USED=$(( (TOTAL_TOKENS * 100) / CTX_SIZE ))
else
    CTX_USED=0
fi
AGENT_NAME=$(echo "$DATA" | jq -r '.agent.name // empty')

# -- Colors --

CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
DIM='\033[90m'
BOLD='\033[1m'
RESET='\033[0m'

# -- Project directory basename --

if [ -n "$PROJECT_DIR" ]; then
    DIR_NAME=$(basename "$PROJECT_DIR")
else
    DIR_NAME="unknown"
fi

# -- Git info with caching --

get_git_info() {
    local dir="$1"
    local cache_key
    cache_key=$(printf '%s' "$dir" | cksum | cut -d' ' -f1)
    local cache_file="/tmp/claude-statusline-git-cache-${cache_key}"

    if [ -f "$cache_file" ]; then
        local now cache_mtime cache_age
        now=$(date +%s)
        cache_mtime=$(stat -f %m "$cache_file" 2>/dev/null || stat -c %Y "$cache_file" 2>/dev/null || echo 0)
        cache_age=$((now - cache_mtime))
        if [ "$cache_age" -lt 5 ]; then
            cat "$cache_file"
            return 0
        fi
    fi

    local result=""
    if git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        local branch
        branch=$(git -C "$dir" symbolic-ref --short HEAD 2>/dev/null || git -C "$dir" rev-parse --short HEAD 2>/dev/null || echo "")
        if [ -n "$branch" ]; then
            local staged=0 modified=0
            staged=$(git -C "$dir" diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
            modified=$(git -C "$dir" diff --numstat 2>/dev/null | wc -l | tr -d ' ')
            result="${branch}:${staged}:${modified}"
        fi
    fi

    echo "$result" > "$cache_file"
    echo "$result"
}

# -- Build single output line --

OUT=""

# Model name
OUT="${OUT}🤖 ${CYAN}${MODEL}${RESET}"

# Agent name if present
if [ -n "$AGENT_NAME" ]; then
    OUT="${OUT} ${DIM}[${YELLOW}${AGENT_NAME}${DIM}]${RESET}"
fi

# Project directory (folder icon)
OUT="${OUT} ${DIM}|${RESET} 📁 ${BOLD}${DIR_NAME}${RESET}"

# Git info (branch icon)
if [ -n "$PROJECT_DIR" ]; then
    GIT_INFO=$(get_git_info "$PROJECT_DIR")
    if [ -n "$GIT_INFO" ]; then
        BRANCH=$(echo "$GIT_INFO" | cut -d: -f1)
        STAGED=$(echo "$GIT_INFO" | cut -d: -f2)
        MODIFIED=$(echo "$GIT_INFO" | cut -d: -f3)

        OUT="${OUT} ${DIM}|${RESET} 🌿 ${BRANCH}"

        if [ "$STAGED" -gt 0 ] 2>/dev/null; then
            OUT="${OUT} ${GREEN}+${STAGED}${RESET}"
        fi
        if [ "$MODIFIED" -gt 0 ] 2>/dev/null; then
            OUT="${OUT} ${YELLOW}~${MODIFIED}${RESET}"
        fi
    fi
fi

# Context percentage with color
CTX_INT=${CTX_USED%.*}
CTX_INT=${CTX_INT:-0}
if [ "$CTX_INT" -gt 100 ] 2>/dev/null; then CTX_INT=100; fi
if [ "$CTX_INT" -lt 0 ] 2>/dev/null; then CTX_INT=0; fi

if [ "$CTX_INT" -ge 90 ]; then
    CTX_COLOR="$RED"
elif [ "$CTX_INT" -ge 70 ]; then
    CTX_COLOR="$YELLOW"
else
    CTX_COLOR="$GREEN"
fi

# Build compact progress bar (10 chars)
BAR_WIDTH=10
FILLED=$(( (CTX_INT * BAR_WIDTH) / 100 ))
EMPTY=$(( BAR_WIDTH - FILLED ))
BAR_FILLED=""
BAR_EMPTY=""
for (( i=0; i<FILLED; i++ )); do BAR_FILLED="${BAR_FILLED}▓"; done
for (( i=0; i<EMPTY; i++ )); do BAR_EMPTY="${BAR_EMPTY}░"; done

OUT="${OUT} ${DIM}|${RESET} 🧠 ${CTX_COLOR}${BAR_FILLED}${DIM}${BAR_EMPTY}${RESET} ${CTX_COLOR}${CTX_INT}%${RESET}"

# Cost
COST_FMT=$(printf '$%.2f' "$COST" 2>/dev/null || echo '$0.00')
OUT="${OUT} ${DIM}|${RESET} 💰 ${COST_FMT}"

# Duration
DURATION_SEC=$(( DURATION_MS / 1000 ))
DURATION_MIN=$(( DURATION_SEC / 60 ))
DURATION_REM=$(( DURATION_SEC % 60 ))
if [ "$DURATION_MIN" -gt 0 ]; then
    DURATION_FMT="${DURATION_MIN}m ${DURATION_REM}s"
else
    DURATION_FMT="${DURATION_REM}s"
fi
OUT="${OUT} ${DIM}|${RESET} ⏱️ ${DURATION_FMT}"

# Lines changed
OUT="${OUT} ${DIM}|${RESET} ✏️ ${GREEN}+${LINES_ADDED}${RESET} ${RED}-${LINES_REMOVED}${RESET}"

# -- Output --

printf '%b\n' "$OUT"
