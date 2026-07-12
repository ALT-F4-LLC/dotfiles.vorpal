#!/bin/bash
# Deterministic secret-pattern battery for the Rule-8 shared review brief,
# folded in exactly as .claude/scripts/audit_snapshot.sh is: takes a diff
# scope, emits a structured report-only JSON result, cheap to re-run.
#
# Design constraints from the security-advisor consult (DKT-187):
#   - Scans ADDED diff lines only ("+" lines, never "+++" headers or
#     context/removed lines) — a removed secret isn't a new leak, and
#     scanning context re-flags already-present strings on every review.
#   - NEVER emits the raw matched secret value. Findings carry a fixed,
#     non-secret label plus match length only (e.g. "AKIA...(len=20)"),
#     never the actual bytes.
#   - Self-exclusion: this script's own path and .claude/scripts/test/ are
#     skipped (they contain the patterns themselves as literals), plus an
#     inline `pragma: allowlist secret` opt-out per line (detect-secrets
#     convention) for legitimate fixtures elsewhere.
#   - POSIX-ERE only (bash's [[ =~ ]]), no PCRE — deterministic, no ReDoS.
#   - Report-only: always exits 0, mirrors audit_snapshot.sh's JSON shape.
#     The reviewer decides; this script never blocks brief generation.
#   - No disk cache (unlike audit_snapshot.sh) — a persisted cache of
#     secret findings is itself a new secrets-at-rest exposure; runs fresh.
set -uo pipefail
# nocasematch is scoped per-pattern in the scan loop below (not global) so
# exact-case vendor prefixes (AKIA, sk-, ghp_, eyJ, ...) stay case-sensitive
# and can't be loosened into FPs; only key-name/header text that legitimately
# varies in case opts in. set_nocase() below is the single toggle point.
set_nocase() {
    if [ "$1" = "1" ]; then
        shopt -s nocasematch
    else
        shopt -u nocasematch
    fi
}

usage() {
    echo "Usage: secret_scan.sh <diff-scope>" >&2
    echo "  <diff-scope>: 'uncommitted' (git diff HEAD) or any git diff-able" >&2
    echo "  ref/range (e.g. 'main..HEAD', 'HEAD~3')." >&2
    exit 1
}

if [ "$#" -ne 1 ]; then
    usage
fi

SCOPE="$1"

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "secret_scan.sh: not inside a git repository" >&2
    exit 1
}
cd "$REPO_ROOT"

SELF_PATH=".claude/scripts/secret_scan.sh"
FIXTURES_PREFIX=".claude/scripts/test/"

MANIFEST_FILE=$(mktemp "${TMPDIR:-/tmp}/secret_scan_manifest.XXXXXX")
FINDINGS_FILE=$(mktemp "${TMPDIR:-/tmp}/secret_scan_findings.XXXXXX")
DIFF_FILE=$(mktemp "${TMPDIR:-/tmp}/secret_scan_diff.XXXXXX")
DIFF_ERR_FILE=$(mktemp "${TMPDIR:-/tmp}/secret_scan_differr.XXXXXX")
trap 'rm -f "$MANIFEST_FILE" "$FINDINGS_FILE" "$DIFF_FILE" "$DIFF_ERR_FILE"' EXIT INT TERM

GIT_DIFF_STATUS=0
if [ "$SCOPE" = "uncommitted" ]; then
    # `git diff HEAD` alone omits untracked (brand-new) files, which is most
    # of what a pre-review scan needs to cover — fold in a synthetic
    # /dev/null-diff per untracked file so new files get scanned too.
    git diff HEAD -- . > "$DIFF_FILE" 2>"$DIFF_ERR_FILE"
    GIT_DIFF_STATUS=$?
    if [ "$GIT_DIFF_STATUS" -eq 0 ]; then
        # -z gives NUL-terminated, unquoted/unescaped paths so filenames with
        # spaces or special characters survive intact (porcelain's default
        # output quote-escapes them, which silently dropped those files).
        git status --porcelain -z --untracked-files=all -- . | \
            while IFS= read -r -d '' entry; do
                [ "${entry:0:2}" = "??" ] || continue
                f="${entry:3}"
                git diff --no-index -- /dev/null "$f" || true
            done >> "$DIFF_FILE"
    fi
else
    # This is the branch where a mistyped/invalid scope ref actually lands.
    git diff "$SCOPE" -- . > "$DIFF_FILE" 2>"$DIFF_ERR_FILE"
    GIT_DIFF_STATUS=$?
fi

SCAN_ERROR=""
if [ "$GIT_DIFF_STATUS" -ne 0 ]; then
    SCAN_ERROR=$(cat "$DIFF_ERR_FILE")
fi

# Extract ADDED lines only, as "file<TAB>new_line_number<TAB>content".
awk '
    /^\+\+\+ / {
        file = $0
        sub(/^\+\+\+ [ab]\//, "", file)
        sub(/^\+\+\+ /, "", file)
        next
    }
    /^@@/ {
        match($0, /\+[0-9]+/)
        newline = substr($0, RSTART + 1, RLENGTH - 1) + 0
        next
    }
    /^\+/ {
        if (file != "" && file != "/dev/null") {
            content = substr($0, 2)
            gsub(/\t/, "    ", content)
            print file "\t" newline "\t" content
        }
        newline++
        next
    }
    /^ / {
        newline++
        next
    }
' "$DIFF_FILE" > "$MANIFEST_FILE"

# --- pattern battery: parallel arrays (name, confidence tier, redaction
# prefix label, POSIX-ERE regex, value-capture-group index) -----------------
# VALUE_GROUPS indexes into BASH_REMATCH for the substring that is the
# ACTUAL credential value (excluding any key-name/operator prefix the regex
# also matches) — used for both the low-entropy distinct-char guard and the
# reported length, so a low-entropy placeholder value isn't hidden behind a
# naturally-varied prefix like `token = "`. 0 means "whole match is the
# value" (patterns with no surrounding assignment syntax).
QUOTE="'"
GENERIC_SQ_REGEX='(api[_-]?key|secret|token|password|passwd|credential)[[:space:]]*[:=][[:space:]]*'"$QUOTE"'([A-Za-z0-9+/=_-]{16,})'"$QUOTE"

NAMES=(
    aws_access_key_id
    aws_temp_access_key_id
    aws_secret_key_context
    gcp_api_key
    private_key_block
    github_token_classic
    github_token_fine_grained
    slack_token
    stripe_live_key
    jwt_triple
    anthropic_api_key
    openai_api_key
    bearer_token
    generic_secret_assignment_dq
    generic_secret_assignment_sq
    generic_secret_assignment_unquoted
)
TIERS=(
    high high advisory high high high high high high high high advisory advisory advisory advisory advisory
)
PREFIXES=(
    "AKIA" "ASIA" "REDACTED" "AIza" "-----BEGIN" "gh_token" "github_pat_"
    "xox" "sk/rk_live_" "eyJ" "sk-ant-" "sk-" "REDACTED" "REDACTED" "REDACTED" "REDACTED"
)
VALUE_GROUPS=(0 0 2 0 0 2 1 1 2 0 1 2 1 2 2 2)
# nocasematch opt-in per pattern index (see set_nocase() above) — 1 only for
# key-name/header patterns whose real-world case varies; vendor-fixed
# prefixes (AKIA/ghp_/sk-/eyJ/...) stay case-sensitive at 0.
NEEDS_NOCASE=(0 0 1 0 0 0 0 0 0 0 0 0 1 1 1 1)
REGEXES=(
    'AKIA[0-9A-Z]{16}'
    'ASIA[0-9A-Z]{16}'
    '(aws_secret_access_key|aws_secret_key|secret_access_key)[[:space:]]*[:=][[:space:]]*([A-Za-z0-9+/=]{40})'
    'AIza[0-9A-Za-z_-]{35}'
    '-----BEGIN( (RSA|EC|OPENSSH|DSA|PGP))? PRIVATE KEY-----'
    '(ghp_|gho_|ghu_|ghs_|ghr_)([A-Za-z0-9]{36})'
    'github_pat_([A-Za-z0-9_]{22,})'
    'xox[baprs]-([0-9A-Za-z-]{10,})'
    '(sk_live_|rk_live_)([0-9a-zA-Z]{24,})'
    'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}'
    'sk-ant-([A-Za-z0-9_-]{20,})'
    '(^|[^A-Za-z0-9_-])sk-([A-Za-z0-9]{20,})'
    'authorization:[[:space:]]*bearer[[:space:]]+([A-Za-z0-9._-]{20,})'
    '(api[_-]?key|secret|token|password|passwd|credential)[[:space:]]*[:=][[:space:]]*"([A-Za-z0-9+/=_-]{16,})"'
    "$GENERIC_SQ_REGEX"
    '(api[_-]?key|secret|token|password|passwd|credential)[[:space:]]*[:=][[:space:]]*([A-Za-z0-9+/=_-]{16,})'
)

# Site-detection patterns: not a secret VALUE match, but a risky CODE
# PATTERN (echoing/logging a secret-named variable). Redaction shows the
# variable NAME (safe — an identifier, not a value), captured at the group
# index in SITE_VARGROUP.
SITE_NAMES=(env_var_echo_shell env_var_access_code log_statement_secret_ref)
SITE_TIERS=(advisory advisory advisory)
SITE_VARGROUP=(1 2 2)
SITE_REGEXES=(
    'echo[[:space:]]+"?\$([A-Za-z_][A-Za-z0-9_]*(SECRET|TOKEN|KEY|PASSWORD|CREDENTIAL)[A-Za-z0-9_]*)'
    '(os\.environ|process\.env)[^A-Za-z0-9_]*([A-Za-z_][A-Za-z0-9_]*(SECRET|TOKEN|KEY|PASSWORD|CREDENTIAL)[A-Za-z0-9_]*)'
    '(console\.log|print|echo|log|logger\.[a-z]+)[[:space:]]*\(.*([A-Za-z_][A-Za-z0-9_]*(SECRET|TOKEN|KEY|PASSWORD|CREDENTIAL)[A-Za-z0-9_]*)'
)

PLACEHOLDER_RE='(changeme|example|xxx|placeholder|redacted|dummy|your-.*-here|<[^>]*>)'

distinct_chars_le() {
    local s="$1" max="$2" n
    n=$(printf '%s' "$s" | fold -w1 | sort -u | wc -l | tr -d ' ')
    [ "$n" -le "$max" ]
}

emit_finding() {
    local name="$1" tier="$2" file="$3" lineno="$4" redacted="$5"
    jq -nc --arg name "$name" --arg tier "$tier" --arg file "$file" \
        --argjson line "$lineno" --arg redacted "$redacted" \
        '{pattern_name:$name, confidence:$tier, file:$file, line_hint:$line, redacted:$redacted}' \
        >> "$FINDINGS_FILE"
}

ADDED_LINES_SCANNED=0

while IFS=$'\t' read -r file lineno content; do
    [ -z "$file" ] && continue
    if [ "$file" = "$SELF_PATH" ] || [[ "$file" == "$FIXTURES_PREFIX"* ]]; then
        continue
    fi
    if [[ "$content" == *"pragma: allowlist secret"* ]]; then
        continue
    fi
    ADDED_LINES_SCANNED=$((ADDED_LINES_SCANNED + 1))

    for i in "${!NAMES[@]}"; do
        regex="${REGEXES[$i]}"
        needs_nocase="${NEEDS_NOCASE[$i]}"
        remaining="$content"
        while :; do
            set_nocase "$needs_nocase"
            [[ "$remaining" =~ $regex ]] || break
            matched="${BASH_REMATCH[0]}"
            valuegroup="${VALUE_GROUPS[$i]}"
            value="${BASH_REMATCH[$valuegroup]}"

            set_nocase 1
            is_placeholder=0
            [[ "$value" =~ $PLACEHOLDER_RE ]] && is_placeholder=1

            if [ "$is_placeholder" = "0" ] && ! distinct_chars_le "$value" 2; then
                redacted="${PREFIXES[$i]}...(len=${#value})"
                emit_finding "${NAMES[$i]}" "${TIERS[$i]}" "$file" "$lineno" "$redacted"
            fi

            # Forward-progress guard: an empty match, or a match whose
            # literal text isn't found (shouldn't happen — matched came from
            # $remaining itself), must not spin the loop forever.
            [ -z "$matched" ] && break
            prefix="${remaining%%"$matched"*}"
            new_remaining="${remaining#"$prefix""$matched"}"
            [ "${#new_remaining}" -ge "${#remaining}" ] && break
            remaining="$new_remaining"
        done
    done
    set_nocase 0

    set_nocase 1
    for i in "${!SITE_NAMES[@]}"; do
        regex="${SITE_REGEXES[$i]}"
        remaining="$content"
        while [[ "$remaining" =~ $regex ]]; do
            matched="${BASH_REMATCH[0]}"
            group="${SITE_VARGROUP[$i]}"
            varname="${BASH_REMATCH[$group]}"
            emit_finding "${SITE_NAMES[$i]}" "${SITE_TIERS[$i]}" "$file" "$lineno" "var=${varname}"

            [ -z "$matched" ] && break
            prefix="${remaining%%"$matched"*}"
            new_remaining="${remaining#"$prefix""$matched"}"
            [ "${#new_remaining}" -ge "${#remaining}" ] && break
            remaining="$new_remaining"
        done
    done
    set_nocase 0
done < "$MANIFEST_FILE"

jq -n --arg scope "$SCOPE" --argjson added "$ADDED_LINES_SCANNED" \
    --slurpfile findings "$FINDINGS_FILE" \
    --arg error "$SCAN_ERROR" \
    '{
        scanned_scope: $scope,
        added_lines_scanned: $added,
        findings: $findings,
        high_confidence_count: ($findings | map(select(.confidence == "high")) | length),
        advisory_count: ($findings | map(select(.confidence == "advisory")) | length),
        error: (if $error == "" then null else $error end)
    }'

exit 0
