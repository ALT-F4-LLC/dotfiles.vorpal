#!/bin/bash
# Structural + closed-list drift-guard sweep for untiered Claude model-name
# mentions (the class of miss that let claude-mythos-5 through a manual
# sweep). Calls ref_census.sh as the sweep primitive per arm, then subtracts
# content-anchored (path-prefix + line-substring) exemptions read from
# model_census_exemptions.tsv from ref_census.sh's actionable_hits. Arms
# 1+2+4+5 are the CI-enforced default invocation; arm 3 is a report-only
# backstop (--backstop), never CI-gated — its capitalized-token heuristic
# has an irreducible false-positive rate on prose-heavy doctrine, and gating
# on it would train reflexive stoplist-padding.
set -euo pipefail

usage() {
    echo "Usage: model_census.sh [--backstop] [--json]" >&2
    echo "  (no flags)   Run arm 1 (structural claude-[a-z]+-[0-9] sweep) +" >&2
    echo "               arm 2 (closed-list alias/product-word sweep)," >&2
    echo "               both exemption-filtered against" >&2
    echo "               model_census_exemptions.tsv, plus arm 4 (stale-" >&2
    echo "               exemption-row sweep) and arm 5 (invented-alias" >&2
    echo "               sweep). Exit 1 on any actionable hit from any of" >&2
    echo "               these arms, 0 otherwise. This is the CI-enforced" >&2
    echo "               invocation." >&2
    echo "  --backstop   Run arm 3 only: report-only residual capitalized-" >&2
    echo "               token sweep, filtered to tokens co-occurring with" >&2
    echo "               tier vocabulary. Always exits 0. Never wired to CI." >&2
    echo "  --json       Emit closed-arithmetic JSON for arms 1+2" >&2
    echo "               (total == exempt_count + actionable_count)," >&2
    echo "               matching ref_census.sh's output shape, plus" >&2
    echo "               stale_exemption_count/rows and" >&2
    echo "               invented_alias_count/hits for arms 4+5." >&2
    exit 1
}

BACKSTOP=0
JSON=0
while [ "$#" -gt 0 ]; do
    case "$1" in
        --backstop) BACKSTOP=1; shift ;;
        --json) JSON=1; shift ;;
        -h|--help) usage ;;
        *) usage ;;
    esac
done

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REF_CENSUS="${SCRIPT_DIR}/ref_census.sh"

[ -f "$REF_CENSUS" ] || {
    echo "model_census.sh: ref_census.sh not found at ${REF_CENSUS}" >&2
    exit 1
}

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "model_census.sh: not inside a git repository" >&2
    exit 1
}
cd "$REPO_ROOT"

# Overridable via env for test fixtures (tests/model_census.test.sh); unset
# in normal use so the real exemption manifest applies.
: "${EXEMPTIONS_TSV:=src/user/claude-code/scripts/model_census_exemptions.tsv}"

count_lines() {
    local text="$1"
    if [ -z "$text" ]; then
        echo 0
    else
        printf '%s\n' "$text" | wc -l | tr -d ' '
    fi
}

# Whole-file-out-of-scope paths: structurally incapable of carrying a
# doctrine restatement, so a sweep-level path exemption is correct here
# (unlike team-lead.md/distinguished-engineer.md, where only PART of the
# file is out of scope and content-anchored TSV exemption is mandatory).
# Cargo.lock/Vorpal.lock are cargo/vorpal-generated (nobody authors doctrine
# there); the model_census.sh/model_census_exemptions.tsv/
# model_census.test.sh trio is the census's own closed list, data file, and
# fixtures, which necessarily self-match.
SWEEP_EXEMPT_PATHS=(
    Cargo.lock
    Vorpal.lock
    src/user/claude-code/scripts/model_census.sh
    src/user/claude-code/scripts/model_census_exemptions.tsv
    tests/model_census.test.sh
)

run_ref_census() {
    local -a exempt_flags=()
    local p
    for p in "${SWEEP_EXEMPT_PATHS[@]}"; do
        exempt_flags+=(-e "$p")
    done
    bash "$REF_CENSUS" -p "$1" "${exempt_flags[@]}"
}

# Mirrors ref_census.sh's is_exempt() path-prefix semantics (repo-root-
# relative path prefix; a directory prefix covers its full subtree) — not a
# new matching strategy. Re-expressed here (rather than reused directly)
# because the TSV's exemption is content-anchored (path prefix AND line
# substring), which ref_census.sh's whole-path -e flag cannot express.
path_has_prefix() {
    local filepath="$1" prefix="$2"
    prefix="${prefix%/}"
    case "$filepath" in
        "./$prefix"|"./$prefix/"*) return 0 ;;
    esac
    return 1
}

# Subtracts content-anchored TSV exemptions from a newline-separated
# "path:line:content" hit list (ref_census.sh's actionable_hits shape,
# joined). Sets FILTERED_ACTIONABLE (remaining hits, newline-joined) and
# FILTERED_EXEMPT_COUNT (hits removed).
apply_exemptions() {
    local hits="$1"
    FILTERED_ACTIONABLE=""
    FILTERED_EXEMPT_COUNT=0
    [ -z "$hits" ] && return 0
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        local filepath rest content exempted cat prefix substr rationale
        filepath="${line%%:*}"
        rest="${line#*:}"
        content="${rest#*:}"
        exempted=0
        while IFS=$'\t' read -r cat prefix substr rationale; do
            case "$cat" in
                ''|'#'*) continue ;;
            esac
            if path_has_prefix "$filepath" "$prefix" && [[ "$content" == *"$substr"* ]]; then
                exempted=1
                break
            fi
        done < "$EXEMPTIONS_TSV"
        if [ "$exempted" -eq 1 ]; then
            FILTERED_EXEMPT_COUNT=$((FILTERED_EXEMPT_COUNT + 1))
        else
            FILTERED_ACTIONABLE="${FILTERED_ACTIONABLE:+${FILTERED_ACTIONABLE}$'\n'}${line}"
        fi
    done <<< "$hits"
}

# --- Arm 4: stale-exemption-row sweep (CI-enforced) --------------------------

# Flags any model_census_exemptions.tsv row whose match-substring no longer
# appears anywhere under its cited path-prefix (a single file, or a
# directory's full subtree). Deterministic containment check (grep -F, no
# heuristic), so unlike arm 3 this is folded into the CI-enforced default
# invocation alongside arms 1+2. A row whose path-prefix no longer exists at
# all is also stale (the cited file/dir was renamed or removed).
# Sets ARM4_STALE (newline-joined "category<TAB>prefix<TAB>substring" rows)
# and ARM4_STALE_COUNT.
run_arm4_stale_exemptions() {
    local stale="" cat prefix substr rationale target found row
    while IFS=$'\t' read -r cat prefix substr rationale; do
        case "$cat" in
            ''|'#'*) continue ;;
        esac
        target="${prefix%/}"
        found=0
        if [ -f "$target" ]; then
            grep -qIF -- "$substr" "$target" 2>/dev/null && found=1
        elif [ -d "$target" ]; then
            grep -rqIF --exclude-dir=.git -- "$substr" "$target" 2>/dev/null && found=1
        fi
        if [ "$found" -eq 0 ]; then
            row=$(printf '%s\t%s\t%s' "$cat" "$target" "$substr")
            stale="${stale:+${stale}$'\n'}${row}"
        fi
    done < "$EXEMPTIONS_TSV"
    ARM4_STALE="$stale"
    ARM4_STALE_COUNT=$(count_lines "$stale")
}

# --- Arm 5: invented-alias sweep (CI-enforced) -------------------------------

# Canonical routing-vocabulary aliases per team-lead.md's Tiers block
# (gold/silver/bronze resolve to fable/opus/sonnet respectively); `haiku` is
# deliberately excluded -- suspended from the routing vocabulary (revisit
# 2026-09-01), not a valid `model="..."` value.
CANONICAL_MODEL_ALIASES=(fable opus sonnet)

is_canonical_alias() {
    local v="$1" c
    for c in "${CANONICAL_MODEL_ALIASES[@]}"; do
        [ "$v" = "$c" ] && return 0
    done
    return 1
}

# src/user/codex targets an entirely different agent framework (OpenAI/GPT
# worker models via spawn_agent's model="gpt-*"), structurally incapable of
# carrying an invented Claude tier alias -- same whole-path-out-of-scope
# rationale as SWEEP_EXEMPT_PATHS above, not a new exemption category.
ARM5_EXEMPT_PATHS=("${SWEEP_EXEMPT_PATHS[@]}" src/user/codex)

run_ref_census_arm5() {
    local -a exempt_flags=()
    local p
    for p in "${ARM5_EXEMPT_PATHS[@]}"; do
        exempt_flags+=(-e "$p")
    done
    bash "$REF_CENSUS" -p "$1" "${exempt_flags[@]}"
}

# Sweeps for `model="<value>"` literals (spawn-call argument shape) and
# flags any hit whose captured value isn't one of CANONICAL_MODEL_ALIASES.
# The character class ([a-zA-Z][a-zA-Z0-9_-]*) deliberately excludes spaces
# and angle brackets, so prose placeholders like
# `model="<per the routing rule below>"` never match at all. Sets
# ARM5_INVENTED (newline-joined hit lines) and ARM5_INVENTED_COUNT.
run_arm5_invented_alias() {
    local raw_json hits filtered=""
    raw_json=$(run_ref_census_arm5 'model="[a-zA-Z][a-zA-Z0-9_-]*"')
    hits=$(printf '%s' "$raw_json" | jq -r '.actionable_hits[]?')
    if [ -n "$hits" ]; then
        while IFS= read -r line; do
            [ -z "$line" ] && continue
            local rest content values val bad
            rest="${line#*:}"
            content="${rest#*:}"
            values=$(printf '%s' "$content" | grep -oE 'model="[a-zA-Z][a-zA-Z0-9_-]*"' | sed -E 's/model="([^"]*)"/\1/')
            [ -z "$values" ] && continue
            bad=0
            while IFS= read -r val; do
                [ -z "$val" ] && continue
                is_canonical_alias "$val" || bad=1
            done <<< "$values"
            [ "$bad" -eq 1 ] && filtered="${filtered:+${filtered}$'\n'}${line}"
        done <<< "$hits"
    fi
    # Same content-anchored manifest arms 1+2 filter through (apply_exemptions)
    # also backs this arm, so a non-spawn `model="..."` shell variable (e.g.
    # spawn_owner_lookup.sh's report-construction sentinel, DKT-179) can be
    # exempted the same way a doctrine mention is.
    apply_exemptions "$filtered"
    ARM5_INVENTED="$FILTERED_ACTIONABLE"
    ARM5_INVENTED_COUNT=$(count_lines "$FILTERED_ACTIONABLE")
}

# --- Arm 3: report-only backstop (--backstop) -------------------------------

# Genuinely open dimension (not prescribed by the design contract): the exact
# stoplist contents. Never CI-gated, so an imperfect stoplist is a UX
# concern for whoever runs --backstop, not a correctness risk.
BACKSTOP_STOPLIST=(
    The This That These Those With From Into When Then Where Which While Who
    For And But Not All Any One Two Use Used Using Via New Old
    Note Example Examples Warning Important Required Optional Default
    Doctrine Docket Skill Skills Agent Agents Arm Arms Phase Phases
    TSV JSON CLI TAB CI API URL ID IDs
    Repo Repository File Files Path Paths Line Lines Hit Hits
    Team Lead Engineer Advisor Design Contract Contracts
    Category Categories Column Columns Schema Header Comment Comments
    Rationale Exemption Exemptions Sweep Regex Pattern Patterns
    Structural Backstop Census Model Models Claude Anthropic
    Test Tests Case Cases Fixture Fixtures Issue Issues Row Rows
)

is_stoplisted() {
    local tok="$1" w
    for w in "${BACKSTOP_STOPLIST[@]}"; do
        [ "$tok" = "$w" ] && return 0
    done
    return 1
}

run_backstop() {
    local raw_json hits filtered=""
    raw_json=$(run_ref_census '\b[A-Z][a-zA-Z]{2,}\b')
    hits=$(printf '%s' "$raw_json" | jq -r '.actionable_hits[]?')
    if [ -n "$hits" ]; then
        while IFS= read -r line; do
            [ -z "$line" ] && continue
            local rest content
            rest="${line#*:}"
            content="${rest#*:}"
            # co-occurrence filter: the line must mention tier vocabulary.
            printf '%s' "$content" | grep -qiE '(gold|silver|bronze|tier)' || continue
            local tokens tok kept=0
            tokens=$(printf '%s' "$content" | grep -oE '\b[A-Z][a-zA-Z]{2,}\b')
            [ -z "$tokens" ] && continue
            while IFS= read -r tok; do
                [ -z "$tok" ] && continue
                is_stoplisted "$tok" || kept=1
            done <<< "$tokens"
            [ "$kept" -eq 1 ] || continue
            filtered="${filtered:+${filtered}$'\n'}${line}"
        done <<< "$hits"
    fi
    local n
    n=$(count_lines "$filtered")
    if [ "$n" -eq 0 ]; then
        echo "model_census.sh --backstop: 0 residual capitalized-token hits (report-only, never CI-gated)"
    else
        echo "model_census.sh --backstop: ${n} residual capitalized-token hit(s) (report-only, never CI-gated; review manually, do not reflexively pad the stoplist)"
        printf '%s\n' "$filtered"
    fi
}

if [ "$BACKSTOP" -eq 1 ]; then
    run_backstop
    exit 0
fi

# --- Arms 1+2: CI-enforced structural + closed-list sweep --------------------

[ -f "$EXEMPTIONS_TSV" ] || {
    echo "model_census.sh: exemptions TSV not found at ${EXEMPTIONS_TSV}" >&2
    exit 1
}

ARM1_PATTERN='claude-[a-z]+-[0-9]'

# Tier aliases + product names (both cases, matched as prose mentions) plus
# legacy full model IDs in Anthropic's pre-tier digit-first naming scheme
# (e.g. claude-3-5-haiku) that arm 1's letter-then-digit structural regex
# cannot match.
ARM2_WORDS=(fable opus sonnet haiku Fable Opus Sonnet Haiku \
    claude-3-opus claude-3-sonnet claude-3-haiku \
    claude-3-5-sonnet claude-3-5-haiku claude-3-7-sonnet)
ARM2_PATTERN="\\b($(IFS='|'; echo "${ARM2_WORDS[*]}"))\\b"

ARM1_JSON=$(run_ref_census "$ARM1_PATTERN")
ARM2_JSON=$(run_ref_census "$ARM2_PATTERN")

ARM1_HITS=$(printf '%s' "$ARM1_JSON" | jq -r '.actionable_hits[]?')
ARM2_HITS=$(printf '%s' "$ARM2_JSON" | jq -r '.actionable_hits[]?')

COMBINED_HITS="$ARM1_HITS"
if [ -n "$ARM2_HITS" ]; then
    COMBINED_HITS="${COMBINED_HITS:+${COMBINED_HITS}$'\n'}${ARM2_HITS}"
fi

apply_exemptions "$COMBINED_HITS"
# Captured immediately: arm5 also calls apply_exemptions (below), which
# reassigns FILTERED_ACTIONABLE/FILTERED_EXEMPT_COUNT for its own hits --
# reading $FILTERED_ACTIONABLE downstream of that call would silently pick up
# arm5's list instead of arm1+2's.
ACTIONABLE_HITS_RAW="$FILTERED_ACTIONABLE"
ACTIONABLE_COUNT=$(count_lines "$FILTERED_ACTIONABLE")
EXEMPT_COUNT="$FILTERED_EXEMPT_COUNT"
TOTAL=$((ACTIONABLE_COUNT + EXEMPT_COUNT))

run_arm4_stale_exemptions
run_arm5_invented_alias

if [ "$JSON" -eq 1 ]; then
    EXEMPT_PATHS=$(awk -F'\t' '!/^#/ && NF>=2 && $1!="" {print $2}' "$EXEMPTIONS_TSV" | sort -u)
    jq -n \
        --arg arm1 "$ARM1_PATTERN" \
        --arg arm2 "$ARM2_PATTERN" \
        --argjson exemptPaths "$(printf '%s\n' ${EXEMPT_PATHS} | jq -R . | jq -s 'map(select(length > 0))')" \
        --argjson total "$TOTAL" \
        --argjson exemptCount "$EXEMPT_COUNT" \
        --argjson actionableCount "$ACTIONABLE_COUNT" \
        --arg actionableHitsRaw "$ACTIONABLE_HITS_RAW" \
        --argjson staleCount "$ARM4_STALE_COUNT" \
        --arg staleRowsRaw "$ARM4_STALE" \
        --argjson inventedCount "$ARM5_INVENTED_COUNT" \
        --arg inventedHitsRaw "$ARM5_INVENTED" \
        '{
            pattern: [$arm1, $arm2],
            exempt_paths: $exemptPaths,
            total: $total,
            exempt_count: $exemptCount,
            actionable_count: $actionableCount,
            actionable_hits: (if $actionableHitsRaw == "" then [] else ($actionableHitsRaw | split("\n")) end),
            stale_exemption_count: $staleCount,
            stale_exemption_rows: (if $staleRowsRaw == "" then [] else ($staleRowsRaw | split("\n")) end),
            invented_alias_count: $inventedCount,
            invented_alias_hits: (if $inventedHitsRaw == "" then [] else ($inventedHitsRaw | split("\n")) end)
        }'
else
    if [ "$ACTIONABLE_COUNT" -eq 0 ]; then
        echo "model_census.sh: arm1+arm2 PASS (total=${TOTAL}, exempt=${EXEMPT_COUNT}, actionable=0)"
    else
        echo "FAIL: ${ACTIONABLE_COUNT} actionable untiered model-name mention(s) (total=${TOTAL}, exempt=${EXEMPT_COUNT})"
        printf '%s\n' "$ACTIONABLE_HITS_RAW"
    fi

    if [ "$ARM4_STALE_COUNT" -eq 0 ]; then
        echo "model_census.sh: arm4 (stale-exemption-row) PASS (0 stale rows)"
    else
        echo "FAIL: ${ARM4_STALE_COUNT} stale exemption row(s) in ${EXEMPTIONS_TSV} (match-substring no longer found under cited path)"
        printf '%s\n' "$ARM4_STALE"
    fi

    if [ "$ARM5_INVENTED_COUNT" -eq 0 ]; then
        echo "model_census.sh: arm5 (invented-alias) PASS (0 non-canonical model=\"...\" values)"
    else
        echo "FAIL: ${ARM5_INVENTED_COUNT} invented-alias hit(s) (model=\"...\" value outside {${CANONICAL_MODEL_ALIASES[*]}})"
        printf '%s\n' "$ARM5_INVENTED"
    fi

    if [ "$ACTIONABLE_COUNT" -eq 0 ] && [ "$ARM4_STALE_COUNT" -eq 0 ] && [ "$ARM5_INVENTED_COUNT" -eq 0 ]; then
        echo "model_census.sh: all arms PASS (arm1+arm2+arm4+arm5)"
    fi
fi

[ "$ACTIONABLE_COUNT" -eq 0 ] && [ "$ARM4_STALE_COUNT" -eq 0 ] && [ "$ARM5_INVENTED_COUNT" -eq 0 ]
