#!/bin/bash
# The sole sanctioned non-append mutation of a pitfalls.md file: replaces
# exactly one entry with one ledger line under the "## Harvested ledger
# (compacted)" section, closing the loop between an entry's lesson and its
# distillation into a durable definition (doctrine file, script, etc.).
#
# File grammar (normative):
#   - Ledger section = the column-0 heading line, followed by at most one
#     blank line, followed by a contiguous run of lines matching
#     `^- \[YYYY-MM-DD\] `. At most one such section per file.
#   - Entry = any column-0 line matching `^## ` or `^- ` that is outside the
#     ledger section and is not the H1; spans to the line before the next
#     entry, the heading, or EOF (trailing blanks belong to the entry).
#   - Writer layout invariant: no blanks between ledger lines; exactly one
#     blank before the heading, one between heading and first ledger line,
#     one after the last ledger line.
# A pre-existing section violating this invariant is refused (exit 7)
# rather than misparsed — grammar alone never classifies a line as a ledger
# line, only section membership does (a real entry can start with
# `- [YYYY-MM-DD]` text and must not be swallowed by the ledger run).
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

usage() {
    echo "Usage: pitfalls_distill.sh <role> <in-repo|centralized>" >&2
    echo "           --entry <prefix> --encoded-in <path> --evidence <string>" >&2
    echo "           [--summary <text>] [--date <YYYY-MM-DD>]" >&2
    echo "  Replaces exactly one entry (matched by a fixed-string PREFIX of its" >&2
    echo "  first line) with one ledger line under the harvested-ledger section." >&2
    echo "  --encoded-in must be git-tracked in this repo; --evidence must" >&2
    echo "  fixed-string-match inside it. See script header for the grammar." >&2
    exit 1
}

if [ "$#" -lt 2 ]; then
    usage
fi

ROLE="$1"
HOME_KIND="$2"
shift 2

ENTRY_PREFIX=""
ENCODED_IN=""
EVIDENCE=""
SUMMARY=""
SUMMARY_GIVEN=0
DATE_VAL=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        --entry)
            [ "$#" -ge 2 ] || usage
            ENTRY_PREFIX="$2"
            shift 2
            ;;
        --encoded-in)
            [ "$#" -ge 2 ] || usage
            ENCODED_IN="$2"
            shift 2
            ;;
        --evidence)
            [ "$#" -ge 2 ] || usage
            EVIDENCE="$2"
            shift 2
            ;;
        --summary)
            [ "$#" -ge 2 ] || usage
            SUMMARY="$2"
            SUMMARY_GIVEN=1
            shift 2
            ;;
        --date)
            [ "$#" -ge 2 ] || usage
            DATE_VAL="$2"
            shift 2
            ;;
        *)
            usage
            ;;
    esac
done

[ -n "$ENTRY_PREFIX" ] || usage
[ -n "$ENCODED_IN" ] || usage
[ -n "$EVIDENCE" ] || usage

CLEANUP_FILES=()
cleanup() {
    local f
    # bash 3.2 (macOS system bash) treats "${arr[@]}" on a zero-element
    # array as unbound under `set -u` — guard on the count first.
    if [ "${#CLEANUP_FILES[@]}" -gt 0 ]; then
        for f in "${CLEANUP_FILES[@]}"; do
            rm -f "$f"
        done
    fi
}
trap cleanup EXIT INT TERM

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "pitfalls_distill.sh: not inside a git repository" >&2
    exit 2
}
cd "$REPO_ROOT"

CHECK_EXIT=0
TARGET_FILE=$("$SCRIPT_DIR/pitfalls_check.sh" "$ROLE" "$HOME_KIND" 2>/dev/null) || CHECK_EXIT=$?
if [ "$CHECK_EXIT" -ne 0 ] || [ -z "$TARGET_FILE" ]; then
    echo "pitfalls_distill.sh: pitfalls_check.sh failed for role='${ROLE}' home='${HOME_KIND}'" >&2
    exit 2
fi

AWK_INPUT="$TARGET_FILE"
[ -f "$TARGET_FILE" ] || AWK_INPUT=/dev/null

# --- shared awk program: select mode (parse + entry match) and reconstruct
# mode (splice + parity re-check) reuse the same grammar functions ----------
AWK_PROGRAM='
function is_blank(l) { return (l == "") }
function is_ledger_line(l) {
    return (l ~ /^- \[[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\] /)
}
function is_h1(l) { return (substr(l, 1, 2) == "# ") }
function is_entry_marker(l) {
    return (substr(l, 1, 3) == "## " || substr(l, 1, 2) == "- ")
}

# Parses arr[1..cnt] and sets p_* globals describing the ledger section (if
# any). Reusable across the original file and a reconstructed candidate.
function parse_structure(arr, cnt,   i, after_heading, idx) {
    p_malformed = 0
    p_section_exists = 0
    p_heading_idx = 0
    p_first_ledger_idx = 0
    p_last_ledger_idx = 0
    p_section_end_idx = 0
    p_h1_exists = (cnt >= 1 && is_h1(arr[1])) ? 1 : 0

    p_heading_count = 0
    for (i = 1; i <= cnt; i++) {
        if (arr[i] == HEADING_TEXT) {
            p_heading_count++
            p_heading_idx = i
        }
    }
    if (p_heading_count > 1) { p_malformed = 1; return }
    if (p_heading_count == 0) { return }

    p_section_exists = 1
    after_heading = p_heading_idx + 1

    if (after_heading <= cnt && is_blank(arr[after_heading])) {
        if ((after_heading + 1) <= cnt && is_blank(arr[after_heading + 1])) {
            p_malformed = 1; return
        }
        p_first_ledger_idx = after_heading + 1
    } else {
        p_first_ledger_idx = after_heading
    }

    idx = p_first_ledger_idx
    p_last_ledger_idx = p_first_ledger_idx - 1
    while (idx <= cnt && is_ledger_line(arr[idx])) {
        p_last_ledger_idx = idx
        idx++
    }

    if (idx <= cnt) {
        if (!is_blank(arr[idx])) { p_malformed = 1; return }
        if ((idx + 1) <= cnt && is_blank(arr[idx + 1])) { p_malformed = 1; return }
        p_section_end_idx = idx
    } else {
        p_section_end_idx = cnt
    }
}

# Enumerates entries in arr[1..cnt] (outside the section found by the last
# parse_structure() call on the same array) into p_entry_start/p_entry_end.
function enumerate_entries(arr, cnt,   i, c, e_end) {
    c = 0
    for (i = 1; i <= cnt; i++) {
        if (i == 1 && p_h1_exists) continue
        if (p_section_exists && i >= p_heading_idx && i <= p_section_end_idx) continue
        if (is_entry_marker(arr[i])) {
            c++
            p_entry_start[c] = i
        }
    }
    p_entry_count = c
    for (i = 1; i <= p_entry_count; i++) {
        e_end = cnt
        if (i < p_entry_count) e_end = p_entry_start[i + 1] - 1
        if (p_section_exists && p_heading_idx > p_entry_start[i] && (p_heading_idx - 1) < e_end) {
            e_end = p_heading_idx - 1
        }
        p_entry_end[i] = e_end
    }
}

# Fixed-string PREFIX match (index(), never a regex) against the first
# physical line of each entry, using the entries found by the last
# enumerate_entries call on lines[].
function do_select(   i, c, mi) {
    c = 0
    for (i = 1; i <= p_entry_count; i++) {
        if (index(lines[p_entry_start[i]], entry_prefix) == 1) {
            c++
            mi = i
        }
    }
    match_count = c
    if (c == 1) {
        sel_start = p_entry_start[mi]
        sel_end = p_entry_end[mi]
    }
}

BEGIN {
    HEADING_TEXT = "## Harvested ledger (compacted)"
    mode = ENVIRON["MODE"]
    entry_prefix = ENVIRON["ENTRY_PREFIX"]
    ledger_line = ENVIRON["LEDGER_LINE"]
    outfile = ENVIRON["OUTFILE"]
}

{ lines[NR] = $0 }

END {
    n = NR

    parse_structure(lines, n)
    if (p_malformed) {
        print "STATUS malformed"
        exit 7
    }

    enumerate_entries(lines, n)
    orig_entry_count = p_entry_count
    orig_ledger_count = (p_section_exists) ? (p_last_ledger_idx - p_first_ledger_idx + 1) : 0
    if (orig_ledger_count < 0) orig_ledger_count = 0
    section_exists = p_section_exists
    heading_idx = p_heading_idx
    first_ledger_idx = p_first_ledger_idx
    last_ledger_idx = p_last_ledger_idx
    h1_exists = p_h1_exists

    do_select()
    if (match_count == 0) {
        print "STATUS nomatch"
        exit 3
    }
    if (match_count >= 2) {
        print "STATUS ambiguous"
        exit 4
    }

    if (mode == "select") {
        print "STATUS ok"
        print "ENTRY_START " sel_start
        print "ENTRY_END " sel_end
        exit 0
    }

    # --- mode == reconstruct: splice out the entry, splice in the ledger
    # line (append to an existing well-formed section, or create one) -------
    out_n = 0
    if (section_exists) {
        anchor = (orig_ledger_count > 0) ? last_ledger_idx : (first_ledger_idx - 1)
        for (i = 1; i <= n; i++) {
            if (i >= sel_start && i <= sel_end) continue
            out_n++; out[out_n] = lines[i]
            if (i == anchor) { out_n++; out[out_n] = ledger_line }
        }
    } else {
        m = 0
        for (i = 1; i <= n; i++) {
            if (i >= sel_start && i <= sel_end) continue
            m++; remaining[m] = lines[i]
        }
        # Section placement: right after H1, or top-of-file with no H1.
        # Seam-blank normalization: consume every pre-existing blank at the
        # seam and re-emit exactly one blank at each required position.
        seam_after = h1_exists ? 1 : 0
        sp = seam_after + 1
        while (sp <= m && remaining[sp] == "") sp++

        if (h1_exists) { out_n++; out[out_n] = remaining[1]; out_n++; out[out_n] = "" }
        out_n++; out[out_n] = HEADING_TEXT
        out_n++; out[out_n] = ""
        out_n++; out[out_n] = ledger_line
        if (sp <= m) {
            out_n++; out[out_n] = ""
            for (i = sp; i <= m; i++) { out_n++; out[out_n] = remaining[i] }
        }
    }

    # Parity re-check (E3): re-parse the reconstructed content per the same
    # grammar as an independent tripwire, not a tautological recount.
    parse_structure(out, out_n)
    if (p_malformed) {
        print "STATUS parity_fail"
        exit 7
    }
    enumerate_entries(out, out_n)
    new_entry_count = p_entry_count
    new_ledger_count = (p_section_exists) ? (p_last_ledger_idx - p_first_ledger_idx + 1) : 0
    if (new_ledger_count < 0) new_ledger_count = 0

    if (new_entry_count != orig_entry_count - 1 || new_ledger_count != orig_ledger_count + 1) {
        print "STATUS parity_fail"
        exit 7
    }

    for (i = 1; i <= out_n; i++) print out[i] > outfile
    close(outfile)

    print "STATUS ok"
    print "ENTRIES_BEFORE " orig_entry_count
    print "ENTRIES_AFTER " new_entry_count
    print "LEDGER_BEFORE " orig_ledger_count
    print "LEDGER_AFTER " new_ledger_count
    exit 0
}
'

field() {
    printf '%s\n' "$1" | awk -v k="$2" '$1==k{print $2}'
}

SELECT_EXIT=0
SELECT_OUTPUT=$(MODE=select ENTRY_PREFIX="$ENTRY_PREFIX" LEDGER_LINE="" OUTFILE="" \
    awk "$AWK_PROGRAM" "$AWK_INPUT") || SELECT_EXIT=$?

case "$SELECT_EXIT" in
    0) ;;
    7)
        echo "pitfalls_distill.sh: ${TARGET_FILE} has a malformed pre-existing ledger section — refusing rather than misparsing" >&2
        exit 7
        ;;
    3)
        echo "pitfalls_distill.sh: --entry '${ENTRY_PREFIX}' matched no entry in ${TARGET_FILE}" >&2
        exit 3
        ;;
    4)
        echo "pitfalls_distill.sh: --entry '${ENTRY_PREFIX}' matched more than one entry in ${TARGET_FILE}" >&2
        exit 4
        ;;
    *)
        echo "pitfalls_distill.sh: internal parse error (awk exit ${SELECT_EXIT})" >&2
        exit 7
        ;;
esac

ENTRY_START=$(field "$SELECT_OUTPUT" ENTRY_START)
ENTRY_END=$(field "$SELECT_OUTPUT" ENTRY_END)

# From here on a same-directory temp file exists — the trap above covers
# every remaining exit path (usage/precondition failures included), not
# only the reconstruct/write step.
TARGET_DIR=$(dirname "$TARGET_FILE")
TMP_FILE=$(mktemp "$TARGET_DIR/.pitfalls_distill.XXXXXX")
CLEANUP_FILES+=("$TMP_FILE")

ENTRY_TEXT_TMP=$(mktemp "${TMPDIR:-/tmp}/pitfalls_distill_entry.XXXXXX")
CLEANUP_FILES+=("$ENTRY_TEXT_TMP")
sed -n "${ENTRY_START},${ENTRY_END}p" "$TARGET_FILE" > "$ENTRY_TEXT_TMP"

# --- E2: encoded-resolution precondition -----------------------------------
case "$ENCODED_IN" in
    /*)
        ENCODED_IN_ABS="$ENCODED_IN"
        ;;
    *)
        ENCODED_IN_ABS="$REPO_ROOT/$ENCODED_IN"
        ;;
esac
case "$ENCODED_IN_ABS" in
    "$REPO_ROOT"/*)
        ENCODED_IN_REL="${ENCODED_IN_ABS#"$REPO_ROOT"/}"
        ;;
    *)
        ENCODED_IN_REL="$ENCODED_IN_ABS"
        ;;
esac

if ! git ls-files --error-unmatch -- "$ENCODED_IN_REL" >/dev/null 2>&1; then
    echo "pitfalls_distill.sh: --encoded-in '${ENCODED_IN}' is not git-tracked (git add it first)" >&2
    exit 5
fi

if ! grep -qF -- "$EVIDENCE" "$ENCODED_IN_ABS" 2>/dev/null; then
    echo "pitfalls_distill.sh: --evidence '${EVIDENCE}' has no hit in ${ENCODED_IN}" >&2
    exit 6
fi

if [ "$HOME_KIND" = "centralized" ]; then
    case "$ENCODED_IN_REL" in
        src/user/claude-code/*) ;;
        *)
            echo "pitfalls_distill.sh: centralized home requires --encoded-in under src/user/claude-code/ (got '${ENCODED_IN_REL}')" >&2
            exit 8
            ;;
    esac
fi

# --- date + summary ---------------------------------------------------------
if [ -n "$DATE_VAL" ]; then
    if ! [[ "$DATE_VAL" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        echo "pitfalls_distill.sh: --date must be YYYY-MM-DD (got '${DATE_VAL}')" >&2
        exit 1
    fi
    FINAL_DATE="$DATE_VAL"
else
    FINAL_DATE=$(date +%Y-%m-%d)
fi

if [ "$SUMMARY_GIVEN" -eq 1 ]; then
    if [ "${#SUMMARY}" -gt 160 ]; then
        echo "pitfalls_distill.sh: --summary exceeds 160 characters (${#SUMMARY})" >&2
        exit 1
    fi
    FINAL_SUMMARY="$SUMMARY"
else
    FIRST_LINE=$(sed -n "${ENTRY_START}p" "$TARGET_FILE")
    STRIPPED="$FIRST_LINE"
    case "$STRIPPED" in
        "## "*) STRIPPED="${STRIPPED#"## "}" ;;
        "- "*) STRIPPED="${STRIPPED#"- "}" ;;
    esac
    COLLAPSED=$(printf '%s' "$STRIPPED" | tr -s '[:space:]' ' ' | sed -E 's/^ +//; s/ +$//')
    FINAL_SUMMARY="${COLLAPSED:0:160}"
fi

# --- E4: Trial:/Drift: lines appended verbatim ------------------------------
TRIAL_DRIFT_SUFFIX=""
while IFS= read -r tdline; do
    trimmed=$(printf '%s' "$tdline" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')
    TRIAL_DRIFT_SUFFIX="${TRIAL_DRIFT_SUFFIX} ${trimmed}"
done < <(grep -E '^[[:space:]]*(Trial|Drift):' "$ENTRY_TEXT_TMP" || true)

LEDGER_LINE="- [${FINAL_DATE}] ${FINAL_SUMMARY} → encoded in ${ENCODED_IN_REL} (${EVIDENCE})${TRIAL_DRIFT_SUFFIX}"

# --- RECOVERY-CHANNEL: git-history only for an in-repo entry byte-present
# at HEAD; centralized homes and uncommitted entries are record-mirror-only.
RECOVERY_CHANNEL="record-mirror-only"
if [ "$HOME_KIND" = "in-repo" ]; then
    TARGET_REL="${TARGET_FILE#"$REPO_ROOT"/}"
    HEAD_CONTENT=$(git show "HEAD:${TARGET_REL}" 2>/dev/null || true)
    ENTRY_TEXT_CONTENT=$(cat "$ENTRY_TEXT_TMP")
    if [ -n "$HEAD_CONTENT" ] && [[ "$HEAD_CONTENT" == *"$ENTRY_TEXT_CONTENT"* ]]; then
        RECOVERY_CHANNEL="git-history"
    fi
fi

# --- reconstruct + parity re-check + atomic write ---------------------------
RECON_EXIT=0
RECON_OUTPUT=$(MODE=reconstruct ENTRY_PREFIX="$ENTRY_PREFIX" LEDGER_LINE="$LEDGER_LINE" OUTFILE="$TMP_FILE" \
    awk "$AWK_PROGRAM" "$AWK_INPUT") || RECON_EXIT=$?

if [ "$RECON_EXIT" -ne 0 ]; then
    echo "pitfalls_distill.sh: reconstruction/parity check failed for ${TARGET_FILE} — refusing rather than misparsing" >&2
    exit 7
fi

ENTRIES_BEFORE=$(field "$RECON_OUTPUT" ENTRIES_BEFORE)
ENTRIES_AFTER=$(field "$RECON_OUTPUT" ENTRIES_AFTER)
LEDGER_BEFORE=$(field "$RECON_OUTPUT" LEDGER_BEFORE)
LEDGER_AFTER=$(field "$RECON_OUTPUT" LEDGER_AFTER)

TARGET_MODE=$(stat -f '%Lp' "$TARGET_FILE" 2>/dev/null || stat -c '%a' "$TARGET_FILE" 2>/dev/null)
chmod "$TARGET_MODE" "$TMP_FILE"
mv "$TMP_FILE" "$TARGET_FILE"

printf '%s\n' "--- REMOVED ENTRY (mirror into your change record) ---"
cat "$ENTRY_TEXT_TMP"
printf '%s\n' "--- REMOVED ENTRY (mirror into your change record) ---"
printf 'RECOVERY-CHANNEL: %s\n' "$RECOVERY_CHANNEL"
printf 'PARITY: entries %s->%s, ledger %s->%s\n' "$ENTRIES_BEFORE" "$ENTRIES_AFTER" "$LEDGER_BEFORE" "$LEDGER_AFTER"
printf '%s\n' "$TARGET_FILE"

exit 0
