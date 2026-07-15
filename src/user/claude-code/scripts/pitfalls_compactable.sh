#!/bin/bash
# Lists pitfalls.md entries that are structural candidates for the
# evolve-agents Phase-4 compaction gate (retention-compaction.md, "Pitfalls
# policy"): live (un-ledgered) entries whose FULL text is already
# byte-present in `git show HEAD:<file>` -- i.e. committed, not appended
# this session. Mechanizes the two purely-structural legs of compactability:
# (b) full-entry HEAD containment, and "un-ledgered" (a live entry, by
# construction of the shared entry-boundary grammar, is not yet represented
# by a ledger line). The remaining legs -- (a) received a Phase 1 triage
# disposition, per the cycle's harvest-outcome report -- and (c) predates
# the current cycle (implied by HEAD containment, since evolve-agents cycles
# never commit mid-cycle) -- need cycle-scoped context this script does not
# have; the caller (evolve-agents Phase 4) cross-references the printed
# candidate list against its own harvest-outcome report before deciding to
# spawn a compactor.
#
# Only the in-repo home is in scope: evolve-agents Phase 4 compacts "THIS
# repo's .claude/agent-memory/*/pitfalls.md" only (retention-compaction.md);
# centralized homes are never part of that gate, so `centralized` is
# accepted for interface parity with pitfalls_check.sh but always reports
# nothing compactable.
#
# Reuses the entry-boundary + ledger-section grammar defined in
# pitfalls_distill.sh / retention-compaction.md (shared, not restated here
# beyond the read-only subset needed for enumeration).
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

usage() {
    echo "Usage: pitfalls_compactable.sh <role> <in-repo|centralized>" >&2
    echo "  Prints one line per compaction-candidate entry (first-line prefix," >&2
    echo "  <=120 chars) to stdout. Exit 0 = none found; 1 = candidates found" >&2
    echo "  (printed); 2 = usage/precondition error; 7 = malformed ledger" >&2
    echo "  section (refuses rather than misparsing)." >&2
    exit 2
}

[ "$#" -eq 2 ] || usage

ROLE="$1"
HOME_KIND="$2"

case "$HOME_KIND" in
    in-repo|centralized) ;;
    *) usage ;;
esac

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "pitfalls_compactable.sh: not inside a git repository" >&2
    exit 2
}
cd "$REPO_ROOT"

if [ "$HOME_KIND" = "centralized" ]; then
    echo "pitfalls_compactable.sh: centralized home is never part of the evolve-agents Phase-4 compaction gate (in-repo only per retention-compaction.md) -- nothing to report" >&2
    exit 0
fi

CHECK_EXIT=0
TARGET_FILE=$("$SCRIPT_DIR/pitfalls_check.sh" "$ROLE" "$HOME_KIND" 2>/dev/null) || CHECK_EXIT=$?
if [ "$CHECK_EXIT" -ne 0 ] || [ -z "$TARGET_FILE" ]; then
    echo "pitfalls_compactable.sh: pitfalls_check.sh failed for role='${ROLE}' home='${HOME_KIND}'" >&2
    exit 2
fi

if [ ! -f "$TARGET_FILE" ] || [ ! -s "$TARGET_FILE" ]; then
    echo "pitfalls_compactable.sh: no pitfalls.md content yet at $TARGET_FILE -- nothing to compact" >&2
    exit 0
fi

AWK_PROGRAM='
function is_blank(l) { return (l == "") }
function is_ledger_line(l) {
    return (l ~ /^- \[[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\] /)
}
function is_h1(l) { return (substr(l, 1, 2) == "# ") }
function is_entry_marker(l) {
    return (substr(l, 1, 3) == "## " || substr(l, 1, 2) == "- ")
}

BEGIN { HEADING_TEXT = "## Harvested ledger (compacted)" }
{ lines[NR] = $0 }

END {
    n = NR
    h1_exists = (n >= 1 && is_h1(lines[1])) ? 1 : 0

    heading_count = 0
    for (i = 1; i <= n; i++) {
        if (lines[i] == HEADING_TEXT) { heading_count++; heading_idx = i }
    }
    if (heading_count > 1) { print "STATUS malformed"; exit 7 }

    section_exists = 0
    section_end_idx = 0
    if (heading_count == 1) {
        section_exists = 1
        after_heading = heading_idx + 1
        if (after_heading <= n && is_blank(lines[after_heading])) {
            if ((after_heading + 1) <= n && is_blank(lines[after_heading + 1])) {
                print "STATUS malformed"; exit 7
            }
            first_ledger_idx = after_heading + 1
        } else {
            first_ledger_idx = after_heading
        }
        idx = first_ledger_idx
        last_ledger_idx = first_ledger_idx - 1
        while (idx <= n && is_ledger_line(lines[idx])) { last_ledger_idx = idx; idx++ }
        if (idx <= n) {
            if (!is_blank(lines[idx])) { print "STATUS malformed"; exit 7 }
            if ((idx + 1) <= n && is_blank(lines[idx + 1])) { print "STATUS malformed"; exit 7 }
            section_end_idx = idx
        } else {
            section_end_idx = n
        }
    }

    c = 0
    for (i = 1; i <= n; i++) {
        if (i == 1 && h1_exists) continue
        if (section_exists && i >= heading_idx && i <= section_end_idx) continue
        if (is_entry_marker(lines[i])) { c++; entry_start[c] = i }
    }
    entry_count = c
    for (i = 1; i <= entry_count; i++) {
        e_end = n
        if (i < entry_count) e_end = entry_start[i + 1] - 1
        if (section_exists && heading_idx > entry_start[i] && (heading_idx - 1) < e_end) {
            e_end = heading_idx - 1
        }
        entry_end[i] = e_end
    }

    print "STATUS ok"
    print "ENTRY_COUNT " entry_count
    for (i = 1; i <= entry_count; i++) {
        print "ENTRY " entry_start[i] " " entry_end[i]
    }
}
'

AWK_EXIT=0
AWK_OUTPUT=$(awk "$AWK_PROGRAM" "$TARGET_FILE") || AWK_EXIT=$?
if [ "$AWK_EXIT" -eq 7 ]; then
    echo "pitfalls_compactable.sh: ${TARGET_FILE} has a malformed ledger section -- refusing rather than misparsing" >&2
    exit 7
elif [ "$AWK_EXIT" -ne 0 ]; then
    echo "pitfalls_compactable.sh: internal parse error (awk exit ${AWK_EXIT})" >&2
    exit 2
fi

TARGET_REL="${TARGET_FILE#"$REPO_ROOT"/}"
HEAD_CONTENT=$(git show "HEAD:${TARGET_REL}" 2>/dev/null || true)

FOUND=0
while IFS= read -r line; do
    case "$line" in
        "ENTRY "*)
            read -r _ start end <<< "$line"
            ENTRY_TEXT=$(sed -n "${start},${end}p" "$TARGET_FILE")
            if [ -n "$HEAD_CONTENT" ] && [[ "$HEAD_CONTENT" == *"$ENTRY_TEXT"* ]]; then
                FIRST_LINE=$(sed -n "${start}p" "$TARGET_FILE")
                echo "${FIRST_LINE:0:120}"
                FOUND=1
            fi
            ;;
    esac
done <<< "$AWK_OUTPUT"

[ "$FOUND" -eq 0 ]
