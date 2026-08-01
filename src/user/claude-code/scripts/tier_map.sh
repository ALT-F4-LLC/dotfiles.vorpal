#!/bin/bash
# Deterministically parses team-lead.md's model-routing policy (Tiers block +
# Per-Role Dispatch Table) so the 3 evolve-model-distribution consumer sites
# stop hand-grepping the same prose independently. Fails loudly (nonzero exit,
# stderr) when an expected anchor string is missing, so a doc restructure
# breaks visibly instead of silently emitting stale/wrong data.
set -euo pipefail

usage() {
    echo "Usage: tier_map.sh [path/to/team-lead.md]" >&2
    echo "  Emits KEY=value / TSV rows parsed from team-lead.md's" >&2
    echo "  model-routing policy:" >&2
    echo "    tier_alias.<tier>=<alias>   (bronze/silver/gold/diamond ->" >&2
    echo "                                 sonnet/opus/opus/fable)" >&2
    echo "    tier_effort.<tier>=<effort> (medium/high/xhigh/max)" >&2
    echo "    category<TAB>tier           (one row per Per-Role Dispatch Table entry)" >&2
    echo "    floor_roles=<comma-list>    (spawn-name patterns pinned at/above silver)" >&2
    echo "    suspended_aliases=<comma-list> (aliases excluded from the routing vocabulary)" >&2
    echo "  Defaults to the team-lead.md next to this script's repo checkout." >&2
    echo "  Exits nonzero with a stderr message if any expected anchor is missing." >&2
    exit 1
}

if [ "$#" -gt 1 ]; then
    usage
fi

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DEFAULT_TEAM_LEAD_MD="${SCRIPT_DIR}/../agents/team-lead.md"
TEAM_LEAD_MD="${1:-$DEFAULT_TEAM_LEAD_MD}"

if [ ! -f "$TEAM_LEAD_MD" ]; then
    echo "tier_map.sh: file not found: ${TEAM_LEAD_MD}" >&2
    exit 1
fi

fail() {
    echo "tier_map.sh: $1" >&2
    exit 1
}

# --- tier_alias.<tier>=<alias> + tier_effort.<tier>=<effort> ---
# Each tier resolves to an (alias, effort) PAIR, benchmark-ordered low to high,
# per team-lead.md's Tiers block and the escalation ladder it cites
# (docs/facts/1785618019_claude_v5_model_routing_policy.md). Emitted as two
# separate KEY=value lines so existing tier_alias.* consumers keep parsing
# unchanged while effort-aware consumers can read the second half.
for triple in bronze:sonnet:medium silver:opus:high gold:opus:xhigh diamond:fable:max; do
    tier="${triple%%:*}"
    rest="${triple#*:}"
    alias_name="${rest%%:*}"
    effort="${rest##*:}"
    anchor="\`${tier}\` — resolves to (\`${alias_name}\`, ${effort})"
    grep -qF -- "$anchor" "$TEAM_LEAD_MD" || fail "tier-pair anchor missing for '${tier}': expected substring \"${anchor}\""
    echo "tier_alias.${tier}=${alias_name}"
    echo "tier_effort.${tier}=${effort}"
done

# --- suspended_aliases= ---
suspended_anchor='`haiku` is not in the routing vocabulary'
grep -qF -- "$suspended_anchor" "$TEAM_LEAD_MD" || fail "suspended-aliases anchor missing: expected substring \"${suspended_anchor}\""
echo "suspended_aliases=haiku"

# --- floor_roles= ---
floor_anchor='it NEVER authorizes running tdd-author*/reviewer*/security-*/ux-*'
grep -qF -- "$floor_anchor" "$TEAM_LEAD_MD" || fail "floor-roles anchor missing: expected substring \"${floor_anchor}\""
echo "floor_roles=tdd-author*,reviewer*,security-*,ux-*"

# --- category -> tier rows (Per-Role Dispatch Table) ---
table_header='| Spawn name (pattern) | Role | Model tier | Lifecycle | Context deltas |'
grep -qF -- "$table_header" "$TEAM_LEAD_MD" || fail "Per-Role Dispatch Table header missing: expected exact line \"${table_header}\""

rows=$(awk -v header="$table_header" '
    index($0, header) { in_table = 1; next }
    in_table && /^\|---/ { next }
    in_table && /^\|/ {
        line = $0
        sub(/^\|/, "", line)
        sub(/\|[[:space:]]*$/, "", line)
        n = split(line, cols, "|")
        if (n < 3) { next }
        spawn = cols[1]
        tier = cols[3]
        gsub(/^[ \t]+|[ \t]+$/, "", spawn)
        gsub(/^[ \t]+|[ \t]+$/, "", tier)
        gsub(/`/, "", spawn)
        gsub(/`/, "", tier)
        gsub(/[ \t]+/, " ", tier)
        slug = tolower(spawn)
        gsub(/[^a-z0-9]+/, "-", slug)
        gsub(/^-+|-+$/, "", slug)
        print slug "\t" tier
        next
    }
    in_table && /^[[:space:]]*$/ { in_table = 0 }
' "$TEAM_LEAD_MD")

[ -n "$rows" ] || fail "Per-Role Dispatch Table parsed zero rows — table structure likely changed"

printf '%s\n' "$rows"
