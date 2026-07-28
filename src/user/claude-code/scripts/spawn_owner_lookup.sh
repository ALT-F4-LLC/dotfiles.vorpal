#!/bin/bash
# Codifies evolve-model-distribution's Spawn-source-authority owner-recovery
# procedure (.claude/skills/evolve-model-distribution/SKILL.md, ~line 185) as
# a script, so the hand-executed grep chain (direct pin -> stem retry ->
# suffix strip -> bare-name prose fallback) is authored once instead of
# re-typed by hand each cycle — the gap that cost 3 fix-rounds in one day
# (a missing -retry suffix, a missing bare-name fallback for
# history-compactor, an under-scoped single-root grep).
set -uo pipefail

usage() {
    echo "Usage: spawn_owner_lookup.sh <role> [<role> ...]" >&2
    echo "  Recovers the owning file:line + pinned model= literal for a" >&2
    echo "  measured spawn <role> absent from team-lead.md's Tiers/Dispatch" >&2
    echo "  Table, by walking the SKILL.md Spawn-source-authority procedure:" >&2
    echo "    1. direct grep:  Agent(name=\"<role>\"  across BOTH skill roots" >&2
    echo "       (.claude/skills/, src/user/claude-code/skills/)" >&2
    echo "    2. on a miss, strip a trailing -r2 / -retry / -fix-<N> suffix" >&2
    echo "       and retry" >&2
    echo "    3. on a miss, retry the stem template the role instantiates" >&2
    echo "       from (review-d<n> -> review-d{n}, review-<name> -> review-<name>)" >&2
    echo "    4. on a miss, bare-name grep (no Agent(name= literal) for a" >&2
    echo "       roster-table/prose-only owner declaration" >&2
    echo "  Emits one TAB-separated line per role:" >&2
    echo "    <role><TAB><file>:<line> / model=<alias>   (pinned)" >&2
    echo "    <role><TAB><file>:<line> / UNPINNED        (prose-only owner)" >&2
    echo "    <role><TAB>UNRECOVERABLE                   (no hit in either root)" >&2
    echo "  A role pinned in BOTH roots (shared template + a restating" >&2
    echo "  Source: line) emits a DISAGREEMENT header followed by every" >&2
    echo "  owning hit, never a silently-picked single line:" >&2
    echo "    <role><TAB>DISAGREEMENT" >&2
    echo "    <role><TAB><file1>:<line1> / model=<alias1>" >&2
    echo "    <role><TAB><file2>:<line2> / model=<alias2>" >&2
    exit 1
}

if [ "$#" -lt 1 ]; then
    usage
fi

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "spawn_owner_lookup.sh: not inside a git repository" >&2
    exit 1
}
cd "$REPO_ROOT"

ROOT_A=".claude/skills"
ROOT_B="src/user/claude-code/skills"

# Literal (non-regex) Agent(name="<name>" pin grep across both roots.
# Emits raw "file:line:content" hits, or nothing on a miss.
grep_pin() {
    local name="$1"
    grep -rnF "Agent(name=\"${name}\"" "$ROOT_A" "$ROOT_B" 2>/dev/null || true
}

# Bare-name substring grep (no Agent(name= literal required) — the
# roster-table/prose fallback for owners like history-compactor that declare
# a spawn without ever writing an Agent(name=... literal for it.
grep_bare() {
    local name="$1"
    grep -rnF -- "$name" "$ROOT_A" "$ROOT_B" 2>/dev/null || true
}

# Strip exactly one trailing -r2 / -retry / -fix-<digits> suffix. A no-op
# (echoes the input unchanged) when none of the three match.
strip_suffix() {
    local name="$1"
    name="${name%-r2}"
    name="${name%-retry}"
    name=$(printf '%s' "$name" | sed -E 's/-fix-[0-9]+$//')
    printf '%s\n' "$name"
}

# The two named placeholder stems a concrete role name may instantiate from.
# review-d<n> is checked before the general review-<name> stem so a role
# like review-d3 retries the more specific template first.
stem_template() {
    local name="$1"
    if [[ "$name" =~ ^review-d[0-9]+$ ]]; then
        printf '%s\n' 'review-d{n}'
    elif [[ "$name" == review-* ]]; then
        printf '%s\n' 'review-<name>'
    fi
}

# Dedupe raw grep -rn hits to one line per owning file (first occurrence),
# so a role pinned at multiple template sites in the same shared file (e.g.
# historical-auditor pinned 3x in evolve-phase0-templates.md) reports one
# owning line per file rather than every occurrence.
dedupe_by_file() {
    awk -F: '!seen[$1]++'
}

# $1 = one "file:line:content" grep hit. Extracts model="<alias>" from the
# matched line, or UNPINNED when the Agent(name= line carries no model=.
format_hit() {
    local hit="$1" file rest line content model
    file="${hit%%:*}"
    rest="${hit#*:}"
    line="${rest%%:*}"
    content="${rest#*:}"
    if [[ "$content" =~ model=\"([a-zA-Z0-9_-]+)\" ]]; then
        model="model=${BASH_REMATCH[1]}"
    else
        model="UNPINNED"
    fi
    printf '%s:%s / %s' "$file" "$line" "$model"
}

resolve_role() {
    local role="$1" stripped template hits

    hits="$(grep_pin "$role")"

    stripped="$(strip_suffix "$role")"
    if [ -z "$hits" ] && [ "$stripped" != "$role" ]; then
        hits="$(grep_pin "$stripped")"
    fi

    if [ -z "$hits" ]; then
        template="$(stem_template "$stripped")"
        if [ -n "$template" ]; then
            hits="$(grep_pin "$template")"
        fi
    fi

    if [ -n "$hits" ]; then
        hits="$(printf '%s\n' "$hits" | dedupe_by_file)"

        local in_a=0 in_b=0 f
        while IFS= read -r hit; do
            [ -z "$hit" ] && continue
            f="${hit%%:*}"
            case "$f" in
                "$ROOT_A"/*) in_a=1 ;;
                "$ROOT_B"/*) in_b=1 ;;
            esac
        done <<< "$hits"

        if [ "$in_a" = 1 ] && [ "$in_b" = 1 ]; then
            printf '%s\tDISAGREEMENT\n' "$role"
        fi
        while IFS= read -r hit; do
            [ -z "$hit" ] && continue
            printf '%s\t%s\n' "$role" "$(format_hit "$hit")"
        done <<< "$hits"
        return
    fi

    local bare
    bare="$(grep_bare "$role")"
    if [ -z "$bare" ] && [ "$stripped" != "$role" ]; then
        bare="$(grep_bare "$stripped")"
    fi

    if [ -n "$bare" ]; then
        bare="$(printf '%s\n' "$bare" | dedupe_by_file)"
        while IFS= read -r hit; do
            [ -z "$hit" ] && continue
            printf '%s\t%s:%s / UNPINNED\n' "$role" "${hit%%:*}" "$(printf '%s' "$hit" | cut -d: -f2)"
        done <<< "$bare"
        return
    fi

    printf '%s\tUNRECOVERABLE\n' "$role"
}

for role in "$@"; do
    resolve_role "$role"
done
