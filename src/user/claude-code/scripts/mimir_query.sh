#!/bin/bash
# Codifies the Mimir reachability probe + the 3 canonical instant GETs
# (token usage by model[+label], cost usage by model, active time total)
# hand-issued across evolve-model-distribution's Phase 0 SS2 and the shared
# evolve-phase0-templates.md Model Routing Audit templates (SS6a/SS6b), so the
# PromQL + unavailable-sentinel wording is authored once instead of
# hand-duplicated per consumer.
set -uo pipefail

MIMIR_BASE="https://mimir.bulbasaur.altf4.domains/prometheus/api/v1/query"

usage() {
    echo "Usage: mimir_query.sh <days> [--label agent_name|skill_name] [--probe]" >&2
    echo "  <days>   PromQL increase()/[Nd] window size, non-negative integer." >&2
    echo "           Unused in --probe mode but still required positionally." >&2
    echo "  --label  optional group-by dimension added to the token-usage query" >&2
    echo "           (agent_name for evolve-agents/evolve-model-distribution," >&2
    echo "           skill_name for evolve-skills; omit for the evolve-config" >&2
    echo "           form, which groups the token-usage query by model only)." >&2
    echo "           Cannot be combined with --probe." >&2
    echo "  --probe  reachability-only mode: issue just the 'up' probe, print" >&2
    echo "           'available' and exit 0 on success, or the sentinel (below)" >&2
    echo "           on failure. Skips the 3 canonical GETs entirely." >&2
    echo >&2
    echo "On success, emits labeled TSV to stdout (omitted in --probe mode, see" >&2
    echo "above):" >&2
    echo "  metric<TAB>model<TAB>label<TAB>value" >&2
    echo "one row per token_usage series, one per cost_usage series, and one" >&2
    echo "for active_time_total (<none> fills a column that does not apply)." >&2
    echo >&2
    echo "On an unreachable Mimir, a non-200/network-error response, or an" >&2
    echo "empty/malformed result from any of the 3 queries, emits exactly one" >&2
    echo "line (the sentinel callers string-match) and exits 0:" >&2
    echo "  Mimir metrics unavailable: <reason>" >&2
    exit 1
}

[ "$#" -ge 1 ] || usage

DAYS="$1"
shift

case "$DAYS" in
    ''|*[!0-9]*)
        echo "mimir_query.sh: <days> must be a non-negative integer, got '${DAYS}'" >&2
        exit 1
        ;;
esac

LABEL=""
PROBE=""
while [ "$#" -gt 0 ]; do
    case "$1" in
        --label)
            [ "$#" -ge 2 ] || usage
            LABEL="$2"
            shift 2
            ;;
        --probe)
            PROBE=1
            shift
            ;;
        *)
            usage
            ;;
    esac
done

if [ -n "$LABEL" ] && [ "$LABEL" != "agent_name" ] && [ "$LABEL" != "skill_name" ]; then
    echo "mimir_query.sh: --label must be agent_name or skill_name, got '${LABEL}'" >&2
    exit 1
fi

if [ -n "$PROBE" ] && [ -n "$LABEL" ]; then
    echo "mimir_query.sh: --probe cannot be combined with --label" >&2
    exit 1
fi

command -v curl >/dev/null 2>&1 || { echo "mimir_query.sh: curl not found" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "mimir_query.sh: jq not found" >&2; exit 1; }

fail() {
    echo "Mimir metrics unavailable: $1"
    exit 0
}

TMP=$(mktemp "${TMPDIR:-/tmp}/mimir_query.XXXXXX") || fail "could not create scratch file"
trap 'rm -f "$TMP"' EXIT

# Issues one unauthenticated instant GET. Echoes "<http_code>\t<body>"; a
# curl-level failure (network error, timeout, DNS) degrades to code "000"
# rather than aborting under set -e, matching the malformed/absent-tolerance
# convention used by spawn_model_join.sh.
mimir_get() {
    local promql="$1" code
    code=$(curl -sS --max-time 15 -G "$MIMIR_BASE" --data-urlencode "query=${promql}" -o "$TMP" -w '%{http_code}' 2>/dev/null) || code="000"
    printf '%s\t' "${code:-000}"
    cat "$TMP"
}

# 1. Reachability probe -- HTTP 200 + parseable JSON is sufficient (no
# data.result emptiness check here; that gate is the 3 GETs below).
probe_result=$(mimir_get "up")
probe_code="${probe_result%%$'\t'*}"
probe_body="${probe_result#*$'\t'}"
if [ "$probe_code" != "200" ]; then
    fail "reachability probe returned HTTP ${probe_code}"
fi
if ! printf '%s' "$probe_body" | jq -e . >/dev/null 2>&1; then
    fail "reachability probe returned unparseable JSON"
fi

if [ -n "$PROBE" ]; then
    echo "available"
    exit 0
fi

# 2. The 3 canonical instant GETs (evolve-model-distribution Phase 0 SS2 /
# evolve-phase0-templates.md SS6a-SS6b "primary factual arm").
if [ -n "$LABEL" ]; then
    TOKEN_QUERY="sum by (model, ${LABEL}) (increase(claude_code_token_usage[${DAYS}d]))"
else
    TOKEN_QUERY="sum by (model) (increase(claude_code_token_usage[${DAYS}d]))"
fi
COST_QUERY="sum by (model) (increase(claude_code_cost_usage[${DAYS}d]))"
ACTIVE_QUERY="sum(increase(claude_code_active_time_total[${DAYS}d]))"

run_query() {
    # NB: this runs inside a `$(...)` command substitution at every call
    # site, so `exit` here would only terminate the subshell, not the whole
    # script. On failure, print the ready-made sentinel line to stdout (it
    # becomes the captured value) and `return 1`; the caller checks the
    # subshell's exit status via `||` and re-emits it from the main shell.
    local name="$1" promql="$2" result code body status is_empty
    result=$(mimir_get "$promql")
    code="${result%%$'\t'*}"
    body="${result#*$'\t'}"
    if [ "$code" != "200" ]; then
        echo "Mimir metrics unavailable: ${name} query returned HTTP ${code}"
        return 1
    fi
    if ! status=$(printf '%s' "$body" | jq -r '.status' 2>/dev/null); then
        echo "Mimir metrics unavailable: ${name} query returned unparseable JSON"
        return 1
    fi
    if [ "$status" != "success" ]; then
        echo "Mimir metrics unavailable: ${name} query returned status=${status:-<empty>}"
        return 1
    fi
    is_empty=$(printf '%s' "$body" | jq '.data.result | length == 0' 2>/dev/null)
    if [ "$is_empty" != "false" ]; then
        echo "Mimir metrics unavailable: ${name} query returned empty data.result"
        return 1
    fi
    printf '%s' "$body"
}

TOKEN_BODY=$(run_query "token_usage" "$TOKEN_QUERY") || { echo "$TOKEN_BODY"; exit 0; }
COST_BODY=$(run_query "cost_usage" "$COST_QUERY") || { echo "$COST_BODY"; exit 0; }
ACTIVE_BODY=$(run_query "active_time_total" "$ACTIVE_QUERY") || { echo "$ACTIVE_BODY"; exit 0; }

echo -e "metric\tmodel\tlabel\tvalue"

if [ -n "$LABEL" ]; then
    printf '%s' "$TOKEN_BODY" | jq -r --arg label "$LABEL" '
        .data.result[] |
        "token_usage\t" + (.metric.model // "<none>") + "\t" + (.metric[$label] // "<none>") + "\t" + .value[1]
    '
else
    printf '%s' "$TOKEN_BODY" | jq -r '
        .data.result[] |
        "token_usage\t" + (.metric.model // "<none>") + "\t<none>\t" + .value[1]
    '
fi

printf '%s' "$COST_BODY" | jq -r '
    .data.result[] |
    "cost_usage\t" + (.metric.model // "<none>") + "\t<none>\t" + .value[1]
'

printf '%s' "$ACTIVE_BODY" | jq -r '
    .data.result[] |
    "active_time_total\t<none>\t<none>\t" + .value[1]
'
