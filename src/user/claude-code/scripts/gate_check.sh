#!/bin/bash
# Promised-gate delivery check: scans a Docket issue's thread for each
# specialist role's OWN terminal artifact and reports present/missing per
# gate. Replaces two independently prose-defined greps with one deterministic
# check — team-lead.md step 16's "Promised-gate delivery check (before closing
# any issue)" and security-engineer.md's "Q4 closure" trigger. A doubled
# general+security review approving is NOT proof a DISTINCT promised gate
# fired; each gate is proven only by its own role's terminal marker.
#
# Three known gates, each matched against the issue's comment thread (the
# sdet gate additionally scans the file-attachment list, since an abuse-case
# artifact may be delivered as an attachment — per security-engineer.md Q4,
# which greps both `docket issue comment list` and `docket issue file list`):
#   design-qa   `[UX→team-lead] Design QA: <verdict>`   (ux-advisor)
#   security    `[SEC→...]` verdict w/ a security recommendation literal
#   sdet-abuse  an sdet-authored abuse-case artifact (comment or file)
#
# The script cannot know which gates a given cycle actually PROMISED (that is
# the caller's knowledge). By default it reports all three; restrict with
# --gates to only the promised subset so a missing-but-unpromised gate does
# not fail the check.
set -uo pipefail

usage() {
    echo "Usage: gate_check.sh <issue-id> [--gates <g1,g2,...>] [--json]" >&2
    echo "" >&2
    echo "  <issue-id>        Docket issue id (e.g. DKT-265)." >&2
    echo "  --gates <list>    Comma-separated subset of gates to check." >&2
    echo "                    Known gates: design-qa, security, sdet-abuse." >&2
    echo "                    Default: all three." >&2
    echo "  --json            Emit a JSON object instead of human-readable lines." >&2
    echo "" >&2
    echo "  Emits PRESENT/MISSING per checked gate (with the matched line for" >&2
    echo "  PRESENT). Exits 0 if every checked gate is PRESENT, 1 if any is" >&2
    echo "  MISSING, 2 on usage error or if the issue thread cannot be read." >&2
    exit 2
}

ISSUE_ID=""
GATES="design-qa,security,sdet-abuse"
JSON=0

while [ "$#" -gt 0 ]; do
    case "$1" in
        -h|--help) usage ;;
        --gates)
            [ "$#" -ge 2 ] || usage
            GATES="$2"
            shift 2
            ;;
        --json)
            JSON=1
            shift
            ;;
        -*)
            usage
            ;;
        *)
            [ -z "$ISSUE_ID" ] || usage
            ISSUE_ID="$1"
            shift
            ;;
    esac
done

[ -n "$ISSUE_ID" ] || usage

command -v docket >/dev/null 2>&1 || {
    echo "gate_check.sh: docket not found on PATH" >&2
    exit 2
}

COMMENTS=$(docket issue comment list "$ISSUE_ID" 2>/dev/null) || {
    echo "gate_check.sh: cannot read comments for '$ISSUE_ID' (docket issue comment list failed)" >&2
    exit 2
}
FILES=$(docket issue file list "$ISSUE_ID" 2>/dev/null || true)

# Per-gate detection. Each function echoes the first matching line (proof) on
# success and returns 0, or returns 1 if the gate's marker is absent.
gate_design_qa() {
    printf '%s\n' "$COMMENTS" | grep -m1 -F '[UX→team-lead] Design QA:' && return 0
    return 1
}

gate_security() {
    # A security verdict is a [SEC→...] comment carrying a code-review-verdict
    # security recommendation literal.
    printf '%s\n' "$COMMENTS" \
        | grep -E '\[SEC→' \
        | grep -m1 -E 'Approve \(security\)|Block \(security\)|Approve with follow-up|Split required' \
        && return 0
    return 1
}

gate_sdet_abuse() {
    # An sdet-authored abuse-case artifact: a [SDET→...] comment mentioning an
    # abuse case, or an attached file whose name references abuse cases.
    printf '%s\n' "$COMMENTS" \
        | grep -E '\[SDET→' \
        | grep -m1 -iE 'abuse[- ]case' \
        && return 0
    printf '%s\n' "$FILES" | grep -m1 -iE 'abuse[-_ ]?case' && return 0
    return 1
}

declare -a REQUESTED
IFS=',' read -r -a REQUESTED <<< "$GATES"

overall=0
json_entries=()

for gate in "${REQUESTED[@]}"; do
    gate="${gate// /}"
    [ -n "$gate" ] || continue
    case "$gate" in
        design-qa) proof=$(gate_design_qa) && status=PRESENT || status=MISSING ;;
        security)  proof=$(gate_security)  && status=PRESENT || status=MISSING ;;
        sdet-abuse) proof=$(gate_sdet_abuse) && status=PRESENT || status=MISSING ;;
        *)
            echo "gate_check.sh: unknown gate '$gate' (known: design-qa, security, sdet-abuse)" >&2
            exit 2
            ;;
    esac

    if [ "$status" = MISSING ]; then
        overall=1
        proof=""
    fi

    if [ "$JSON" -eq 1 ]; then
        json_entries+=("$(jq -n --arg gate "$gate" --arg status "$status" --arg proof "$proof" \
            '{gate: $gate, status: $status, proof: (if $proof == "" then null else ($proof | ltrimstr(" ") ) end)}')")
    else
        if [ "$status" = PRESENT ]; then
            printf '  %-8s %-10s %s\n' PRESENT "$gate" "$(printf '%s' "$proof" | sed 's/^[[:space:]]*//')"
        else
            printf '  %-8s %-10s (no terminal artifact found in thread)\n' MISSING "$gate"
        fi
    fi
done

if [ "$JSON" -eq 1 ]; then
    printf '%s\n' "${json_entries[@]+"${json_entries[@]}"}" \
        | jq -s --arg issue "$ISSUE_ID" '{issue: $issue, all_present: (all(.status == "PRESENT")), gates: .}'
else
    if [ "$overall" -eq 0 ]; then
        echo "gates: OK (all ${#REQUESTED[@]} checked gate(s) present)"
    else
        echo "gates: INCOMPLETE (one or more promised gates missing)" >&2
    fi
fi

exit "$overall"
