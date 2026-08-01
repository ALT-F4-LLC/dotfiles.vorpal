#!/bin/bash
# Deterministic secret-pattern battery for the Rule-8 shared review brief,
# folded in exactly as src/user/claude-code/scripts/audit_snapshot.sh is: takes a diff
# scope, emits a structured report-only JSON result, cheap to re-run.
#
# Design constraints from the security-advisor consult (DKT-187):
#   - Scans ADDED diff lines only ("+" lines, never "+++" headers or
#     context/removed lines) — a removed secret isn't a new leak, and
#     scanning context re-flags already-present strings on every review.
#   - NEVER emits the raw matched secret value. Findings carry a fixed,
#     non-secret label plus match length only (e.g. "AKIA...(len=20)"),
#     never the actual bytes.
#   - Self-exclusion: this script's own path and src/user/claude-code/scripts/test/ are
#     skipped (they contain the patterns themselves as literals), plus an
#     inline `pragma: allowlist secret` opt-out per line (detect-secrets
#     convention) for legitimate fixtures elsewhere.
#   - POSIX-ERE only (bash's [[ =~ ]]), no PCRE — deterministic, no ReDoS.
#   - Report-only: always exits 0, mirrors audit_snapshot.sh's JSON shape.
#     The reviewer decides; this script never blocks brief generation.
#     INDETERMINATE therefore rides the `error` field, NEVER the exit status.
#   - No disk cache (unlike audit_snapshot.sh) — a persisted cache of
#     secret findings is itself a new secrets-at-rest exposure; runs fresh.
#
# FILE ATTRIBUTION IS STRUCTURAL, NEVER TEXT-PARSED (DKT-237 / DKT-207
# fix-round-4). This script previously derived a line's owning file by
# pattern-matching the rendered diff's `+++ ` header text. That grammar was
# content-forgeable: an ADDED line whose text begins "++ " renders
# identically to a real header, so a single planted line re-attributed every
# following added line — including a real credential — to an excluded path,
# and the scan silently skipped it. Four further primitives of the same class
# followed (git C-quoted non-ASCII paths, an embedded " b/" substring path, a
# NUL-byte binary carrier, and an exclusion-decision asymmetry against
# distill_gate.sh). The common root cause is deriving identity from untrusted
# rendered text at all, so that surface is now REMOVED rather than hardened:
#   - Path IDENTITY comes from `git diff --numstat -z`, git's own plumbing-
#     derived, NUL-delimited byte stream. Under -z paths are emitted RAW —
#     never C-quoted, never escaped. (`core.quotePath=false` is NOT
#     sufficient: it suppresses only high-byte quoting, while paths
#     containing a quote or backslash still C-quote. Verified directly.)
#   - Line CONTENT comes from the rendered diff, but blocks are delimited by
#     the column-0 `diff --git ` anchor, which content can never forge (every
#     diff body line carries a "+"/"-"/" " prefix). The content pass never
#     extracts a path.
#   - The two are paired POSITIONALLY, in diff order, and reconciled: a
#     per-file added-line count disagreement, or a numstat binary/undiffable
#     marker `-`, is INDETERMINATE and reported via `error`.
# distill_gate.sh derives its own canonical paths the same way, so both
# scripts key exclusion on identical canonical path bytes and cannot disagree
# about which file a line belongs to.
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

SELF_PATH="src/user/claude-code/scripts/secret_scan.sh"
FIXTURES_PREFIX="src/user/claude-code/scripts/test/"

# One per-run scratch DIRECTORY rather than N loose files: cleanup is a
# single atomic `rm -rf` that cannot leave a subset behind if a new scratch
# file is added later and someone forgets to extend the trap.
SCRATCH_DIR=$(mktemp -d "${TMPDIR:-/tmp}/secret_scan_run.XXXXXX")
trap 'rm -rf "$SCRATCH_DIR"' EXIT INT TERM

MANIFEST_FILE="$SCRATCH_DIR/manifest"
FINDINGS_FILE="$SCRATCH_DIR/findings"
DIFF_FILE="$SCRATCH_DIR/diff"
DIFF_ERR_FILE="$SCRATCH_DIR/differr"
UNTRACKED_FILE="$SCRATCH_DIR/untracked"
NUMSTAT_FILE="$SCRATCH_DIR/numstat"
BLOCKS_FILE="$SCRATCH_DIR/blocks"
: > "$FINDINGS_FILE"
: > "$DIFF_ERR_FILE"

# Enumerates untracked files ONCE, shared by BOTH the rendered-diff build and
# the numstat build below, so the two passes cover an identical file set in an
# identical order — a second, independently-derived enumeration could diverge
# and silently desynchronize their positional pairing. -z gives NUL-
# terminated, unquoted/unescaped paths so filenames with spaces or special
# characters survive intact (porcelain's default output quote-escapes them,
# which silently dropped those files).
GIT_DIFF_STATUS=0
# Appends throughout (never truncates): a later git invocation must not
# discard an earlier one's captured stderr, or the reported `error` would
# name the wrong failure.
git status --porcelain -z --untracked-files=all -- . > "$UNTRACKED_FILE" 2>>"$DIFF_ERR_FILE"
STATUS_RC=$?
if [ "$STATUS_RC" -ne 0 ]; then
    echo "secret_scan.sh: git status --porcelain failed (exit $STATUS_RC)" >> "$DIFF_ERR_FILE"
fi

if [ "$SCOPE" = "uncommitted" ]; then
    # `git diff HEAD` alone omits untracked (brand-new) files, which is most
    # of what a pre-review scan needs to cover — fold in a synthetic
    # /dev/null-diff per untracked file so new files get scanned too.
    # A "??" porcelain entry is the ONLY status needing a synthetic diff: every
    # other status (including a "T" typechange) is already TRACKED, so
    # `git diff HEAD` covers it — synthesizing one too would double-count it.
    git diff HEAD -- . > "$DIFF_FILE" 2>>"$DIFF_ERR_FILE"
    GIT_DIFF_STATUS=$?
    if [ "$GIT_DIFF_STATUS" -eq 0 ] && [ "$STATUS_RC" -ne 0 ]; then
        GIT_DIFF_STATUS=$STATUS_RC
    fi
    if [ "$GIT_DIFF_STATUS" -eq 0 ]; then
        while IFS= read -r -d '' entry; do
            [ "${entry:0:2}" = "??" ] || continue
            f="${entry:3}"
            git diff --no-index -- /dev/null "$f" || true
        done < "$UNTRACKED_FILE" >> "$DIFF_FILE"

        git diff --numstat -z HEAD -- . > "$NUMSTAT_FILE" 2>>"$DIFF_ERR_FILE"
        NUMSTAT_RC=$?
        if [ "$NUMSTAT_RC" -eq 0 ]; then
            while IFS= read -r -d '' entry; do
                [ "${entry:0:2}" = "??" ] || continue
                f="${entry:3}"
                git diff --no-index --numstat -z -- /dev/null "$f" || true
            done < "$UNTRACKED_FILE" >> "$NUMSTAT_FILE"
        else
            GIT_DIFF_STATUS=$NUMSTAT_RC
        fi
    fi
else
    # This is the branch where a mistyped/invalid scope ref actually lands.
    git diff "$SCOPE" -- . > "$DIFF_FILE" 2>"$DIFF_ERR_FILE"
    GIT_DIFF_STATUS=$?
    if [ "$GIT_DIFF_STATUS" -eq 0 ]; then
        git diff --numstat -z "$SCOPE" -- . > "$NUMSTAT_FILE" 2>>"$DIFF_ERR_FILE"
        GIT_DIFF_STATUS=$?
    fi
fi

SCAN_ERROR=""
if [ "$GIT_DIFF_STATUS" -ne 0 ]; then
    SCAN_ERROR=$(cat "$DIFF_ERR_FILE")
fi

# --- structural file attribution (see the header comment) -------------------
# CANONICAL_PATHS[i] / CANONICAL_ADDED[i]: git's own ground truth for the i-th
# file in the diff, parsed from `--numstat -z`'s raw NUL-delimited byte
# stream. CANONICAL_ADDED stays the literal string "-" for a binary/undiffable
# file — never coerced to 0, since git cannot tell us how many lines it added.
#
# Handles BOTH numstat -z record shapes: the ordinary single-path form
# (added\tdeleted\tpath\0) and the two-path form used for renames/copies and
# for EVERY --no-index invocation (added\tdeleted\t\0preimage\0postimage\0 —
# note the EMPTY middle field followed by two MORE NUL-terminated tokens). A
# parser assuming only the first shape desynchronizes the stream on the first
# such record and mis-attributes every subsequent path. The POST-image path is
# reported: the file's identity in the resulting tree, which is what needs
# scanning.
CANONICAL_PATHS=()
CANONICAL_ADDED=()
parse_numstat_stream() {
    local chunk added after_added rest path preimage postimage
    while IFS= read -r -d '' chunk; do
        added="${chunk%%$'\t'*}"
        after_added="${chunk#*$'\t'}"
        rest="${after_added#*$'\t'}"
        if [ -z "$rest" ]; then
            IFS= read -r -d '' preimage || return 1
            IFS= read -r -d '' postimage || return 1
            path="$postimage"
        else
            path="$rest"
        fi
        CANONICAL_PATHS+=("$path")
        CANONICAL_ADDED+=("$added")
    done
    return 0
}
NUMSTAT_PARSE_RC=0
if [ "$GIT_DIFF_STATUS" -eq 0 ]; then
    parse_numstat_stream < "$NUMSTAT_FILE" || NUMSTAT_PARSE_RC=$?
fi

# Content pass: emits "<block_index><TAB><new_line_number><TAB><content>" for
# every ADDED line, delimited by the column-0 `diff --git ` anchor. It never
# extracts a path — block INDEX is all it reports, and main() maps that index
# to a canonical path below.
#
# TYPECHANGE BLOCK COLLAPSE: a tracked regular-file<->symlink typechange
# (porcelain "T") is ONE numstat record but renders as TWO `diff --git`
# blocks — a delete block followed by a new-mode block. Without collapsing
# them the position counts disagree and a credential-free diff hard-blocks.
#
# The predicate is DELIBERATELY NARROW. A false collapse merges two positions
# into one, which is a COUNT REDUCTION — structurally the same cancellation
# primitive as P-1/P-2/P-4 — so "two consecutive byte-identical headers" is
# NOT sufficient on its own: it is one rendering quirk or git-version change
# away from being satisfiable by something that is not a typechange. All of:
#   1. the two blocks are CONSECUTIVE, and
#   2. their `diff --git` header lines are byte-identical (FULL-LINE compare —
#      never a prefix or substring, which is what keeps the "a.txt" vs
#      "a.txt b" P-2-family near-miss from false-duping), and
#   3. the first block carries `deleted file mode <m1>`, and
#   4. the second carries `new file mode <m2>`, and
#   5. m1 != m2.
# Condition 5's reconciliation half — that the collapsed position count
# matches the numstat record set exactly — is enforced BELOW, against
# numstat ground truth. That keeps this collapse SUBORDINATE to the canonical
# source rather than a second independent authority, which is the
# architectural point of this round.
awk '
    /^diff --git / {
        # Defer the block decision until the mode lines are seen: conditions
        # 3-5 are only decidable after reading the next block header region.
        pending_header = $0
        pending_deleted = ""
        pending_new = ""
        saw_header = 1
        in_hunk = 0
        header_state = 1
        next
    }
    header_state == 1 && /^deleted file mode / {
        pending_deleted = substr($0, length("deleted file mode ") + 1)
        next
    }
    header_state == 1 && /^new file mode / {
        pending_new = substr($0, length("new file mode ") + 1)
        next
    }
    saw_header && /^@@/ {
        flush_block()
        match($0, /\+[0-9]+/)
        newline = substr($0, RSTART + 1, RLENGTH - 1) + 0
        in_hunk = 1
        header_state = 0
        next
    }
    in_hunk && /^\+/ {
        content = substr($0, 2)
        gsub(/\t/, "    ", content)
        print block "\t" newline "\t" content
        newline++
        next
    }
    in_hunk && /^ / {
        newline++
        next
    }
    function flush_block() {
        if (!saw_header) { return }
        # Collapse ONLY when all of conditions 1-5 hold. prev_deleted is the
        # mode from the immediately preceding block; a non-empty prev_deleted
        # with a non-empty pending_new and differing modes, on a byte-identical
        # consecutive header, is the typechange pair.
        if (block >= 0 && pending_header == prev_header && \
            prev_deleted != "" && pending_new != "" && prev_deleted != pending_new) {
            collapsed++
        } else {
            block++
        }
        prev_header = pending_header
        prev_deleted = pending_deleted
        prev_new = pending_new
        saw_header = 0
    }
    BEGIN { block = -1; in_hunk = 0; saw_header = 0; collapsed = 0; header_state = 0 }
    END {
        flush_block()
        print (block + 1) > blocks_out
    }
' blocks_out="$BLOCKS_FILE" "$DIFF_FILE" > "$MANIFEST_FILE"

# Block count comes from the SAME awk pass that assigned the indices — never
# from a second pass re-implementing the collapse rule. Two copies of that
# rule could drift apart, and a drift would silently misalign the manifest's
# block indices against this count, which is the exact class of desync this
# whole fix exists to remove.
CONTENT_BLOCKS=$(cat "$BLOCKS_FILE" 2>/dev/null)
[ -z "$CONTENT_BLOCKS" ] && CONTENT_BLOCKS=0

# Reconcile the two passes. Any disagreement is INDETERMINATE and rides the
# `error` field (this script always exits 0 — report-only). Deliberately
# FAIL-CLOSED BY CONSTRUCTION: a per-file added-line count is only accepted
# after its position has matched an exact canonical path, so an unmatched or
# unrecognized position cannot degrade to a silent 0.
RECONCILE_ERROR=""
if [ "$GIT_DIFF_STATUS" -eq 0 ]; then
    if [ "$NUMSTAT_PARSE_RC" -ne 0 ]; then
        RECONCILE_ERROR="numstat stream truncated mid-record (exit $NUMSTAT_PARSE_RC) — INDETERMINATE"
    elif [ "${#CANONICAL_PATHS[@]}" -ne "$CONTENT_BLOCKS" ]; then
        RECONCILE_ERROR="line-accounting invariant violated: numstat reports ${#CANONICAL_PATHS[@]} file(s) but the content pass found $CONTENT_BLOCKS — INDETERMINATE"
    fi
fi

# Per-block added-line totals from the content pass, for the per-path
# cross-check emitted as `added_lines_by_path`.
BLOCK_TOTALS=()
if [ -z "$RECONCILE_ERROR" ] && [ "$GIT_DIFF_STATUS" -eq 0 ]; then
    i=0
    while [ "$i" -lt "$CONTENT_BLOCKS" ]; do
        BLOCK_TOTALS+=(0)
        i=$((i + 1))
    done
    while IFS=$'\t' read -r blockidx _ _; do
        [ -z "$blockidx" ] && continue
        BLOCK_TOTALS[$blockidx]=$(( ${BLOCK_TOTALS[$blockidx]} + 1 ))
    done < "$MANIFEST_FILE"

    i=0
    while [ "$i" -lt "${#CANONICAL_PATHS[@]}" ]; do
        if [ "${CANONICAL_ADDED[$i]}" = "-" ]; then
            RECONCILE_ERROR="file '${CANONICAL_PATHS[$i]}' is binary/undiffable (numstat reported '-') — INDETERMINATE"
            break
        fi
        if [ "${BLOCK_TOTALS[$i]}" != "${CANONICAL_ADDED[$i]}" ]; then
            RECONCILE_ERROR="line-accounting invariant violated: file '${CANONICAL_PATHS[$i]}' — numstat reports ${CANONICAL_ADDED[$i]} added line(s) but the content pass counted ${BLOCK_TOTALS[$i]} — INDETERMINATE"
            break
        fi
        i=$((i + 1))
    done
fi

if [ -n "$RECONCILE_ERROR" ]; then
    SCAN_ERROR="${SCAN_ERROR:+$SCAN_ERROR; }$RECONCILE_ERROR"
fi

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

# Per-canonical-path scanned-line tallies, emitted as `added_lines_by_path`
# for distill_gate.sh's per-path cross-check. EVERY canonical path gets an
# entry — an excluded path is explicitly MARKED excluded, never omitted.
# Omitting it would render a predicate divergence between the two scripts as
# an ABSENT key, and an absent key degrading to 0 is exactly the cancellation
# every primitive in this class has exploited.
BY_PATH_SCANNED=()
BY_PATH_EXCLUDED=()
for _i in "${!CANONICAL_PATHS[@]}"; do
    BY_PATH_SCANNED+=(0)
    if [ "${CANONICAL_PATHS[$_i]}" = "$SELF_PATH" ] || [[ "${CANONICAL_PATHS[$_i]}" == "$FIXTURES_PREFIX"* ]]; then
        BY_PATH_EXCLUDED+=(true)
    else
        BY_PATH_EXCLUDED+=(false)
    fi
done

while IFS=$'\t' read -r blockidx lineno content; do
    [ -z "$blockidx" ] && continue
    # Identity is resolved by INDEX into git's own ground truth — never
    # parsed from the diff text this line came from. A block index with no
    # canonical entry cannot occur once the reconcile above has passed
    # (equal cardinality is a precondition of reaching here with an empty
    # RECONCILE_ERROR); if it somehow does, it is INDETERMINATE, never
    # silently scanned under a guessed path nor silently skipped.
    if [ "$blockidx" -ge "${#CANONICAL_PATHS[@]}" ]; then
        RECONCILE_ERROR="content block $blockidx has no canonical path — INDETERMINATE"
        break
    fi
    file="${CANONICAL_PATHS[$blockidx]}"
    if [ "${BY_PATH_EXCLUDED[$blockidx]}" = "true" ]; then
        continue
    fi
    if [[ "$content" == *"pragma: allowlist secret"* ]]; then
        continue
    fi
    ADDED_LINES_SCANNED=$((ADDED_LINES_SCANNED + 1))
    BY_PATH_SCANNED[$blockidx]=$(( ${BY_PATH_SCANNED[$blockidx]} + 1 ))

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

if [ -n "$RECONCILE_ERROR" ] && [[ "$SCAN_ERROR" != *"$RECONCILE_ERROR"* ]]; then
    SCAN_ERROR="${SCAN_ERROR:+$SCAN_ERROR; }$RECONCILE_ERROR"
fi

# `added_lines_by_path`: one entry per canonical path, each declaring BOTH the
# scanned-line count and the exclusion decision. distill_gate.sh joins against
# this on EXACT canonical path bytes (both sides derive those bytes from
# `--numstat -z`), and treats a path present on one side but absent from the
# other as fatal — so a predicate divergence surfaces as a set asymmetry
# rather than cancelling out. Built by folding one jq object per path so any
# path byte sequence (spaces, quotes, newlines) is encoded by jq itself.
BY_PATH_JSON="{}"
for _i in "${!CANONICAL_PATHS[@]}"; do
    # A failed fold step must not silently yield an empty string, which would
    # make the final `--argjson by_path ""` below emit MALFORMED JSON — the
    # consumer would then get unparseable output instead of a well-formed
    # INDETERMINATE. Fail closed onto the error field and stop folding.
    _next=$(jq -c \
        --arg path "${CANONICAL_PATHS[$_i]}" \
        --argjson scanned "${BY_PATH_SCANNED[$_i]}" \
        --argjson excluded "${BY_PATH_EXCLUDED[$_i]}" \
        '. + {($path): {scanned: $scanned, excluded: $excluded}}' <<<"$BY_PATH_JSON") || _next=""
    if [ -z "$_next" ]; then
        SCAN_ERROR="${SCAN_ERROR:+$SCAN_ERROR; }failed to build added_lines_by_path — INDETERMINATE"
        BY_PATH_JSON="{}"
        break
    fi
    BY_PATH_JSON="$_next"
done

jq -n --arg scope "$SCOPE" --argjson added "$ADDED_LINES_SCANNED" \
    --slurpfile findings "$FINDINGS_FILE" \
    --arg error "$SCAN_ERROR" \
    --argjson by_path "$BY_PATH_JSON" \
    '{
        scanned_scope: $scope,
        added_lines_scanned: $added,
        added_lines_by_path: $by_path,
        findings: $findings,
        high_confidence_count: ($findings | map(select(.confidence == "high")) | length),
        advisory_count: ($findings | map(select(.confidence == "advisory")) | length),
        error: (if $error == "" then null else $error end)
    }'

exit 0
