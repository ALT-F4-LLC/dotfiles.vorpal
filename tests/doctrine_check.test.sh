#!/bin/bash

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
SCRIPT="${REPO_ROOT}/src/user/claude-code/scripts/doctrine_check.sh"

PASS=0
FAIL=0

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    FAIL=$((FAIL + 1))
}

pass() {
    printf 'PASS: %s\n' "$1"
    PASS=$((PASS + 1))
}

assert_exit() {
    local expected="$1" actual="$2" label="$3"
    if [ "$actual" -eq "$expected" ]; then
        pass "${label}: exit ${expected}"
    else
        fail "${label}: expected exit ${expected}, got ${actual}"
    fi
}

assert_contains() {
    local haystack="$1" needle="$2" label="$3"
    case "$haystack" in
        *"$needle"*) pass "${label}: output contains '${needle}'" ;;
        *) fail "${label}: output did not contain '${needle}'" ;;
    esac
}

assert_not_contains() {
    local haystack="$1" needle="$2" label="$3"
    case "$haystack" in
        *"$needle"*) fail "${label}: output unexpectedly contained '${needle}'" ;;
        *) pass "${label}: output correctly omits '${needle}'" ;;
    esac
}

# One CANONICAL:GOODTAG:BEGIN/END block, byte-identical in two files, used as
# a stable "arm (c) passes" carrier pair across several fixtures.
write_good_tag_carrier() {
    local path="$1"
    cat > "$path" <<'EOF'
intro text
<!-- CANONICAL:GOODTAG:BEGIN -->
identical body line 1
identical body line 2
<!-- CANONICAL:GOODTAG:END -->
trailing text
EOF
}

case_real_repo_pass() {
    local out rc
    out=$(bash "$SCRIPT" 2>&1); rc=$?
    assert_exit 0 "$rc" "real repo state"
    assert_contains "$out" "doctrine_check.sh: all arms PASS" "real repo state"
}

case_arm_a_fail_disk_file_not_in_table() {
    local tmp out rc
    tmp=$(mktemp -d "${TMPDIR:-/tmp}/doctrinecheck.XXXXXX")
    mkdir -p "${tmp}/references"
    : > "${tmp}/references/orphan.md"
    printf '| \`references/other.md\` | desc |\n' > "${tmp}/skill.md"

    out=$(SKILL_MD="${tmp}/skill.md" REFERENCES_DIR="${tmp}/references" \
        bash "$SCRIPT" 2>&1); rc=$?
    assert_exit 1 "$rc" "arm a: orphan reference file"
    assert_contains "$out" "FAIL: index parity violated" "arm a: orphan reference file"
    assert_contains "$out" "orphan.md is on disk but not cited" "arm a: orphan reference file"

    rm -rf "$tmp"
}

case_arm_b_fail_zero_pointers() {
    local tmp out rc
    tmp=$(mktemp -d "${TMPDIR:-/tmp}/doctrinecheck.XXXXXX")
    mkdir -p "${tmp}/empty"

    out=$(POINTER_SEARCH_DIRS="${tmp}/empty" bash "$SCRIPT" 2>&1); rc=$?
    assert_exit 1 "$rc" "arm b: zero pointers found"
    assert_contains "$out" "FAIL: 0 Master: pointer(s) found" "arm b: zero pointers found"

    rm -rf "$tmp"
}

case_arm_b_fail_unresolvable_pointer() {
    local tmp out rc
    tmp=$(mktemp -d "${TMPDIR:-/tmp}/doctrinecheck.XXXXXX")
    mkdir -p "${tmp}/pointers"
    printf 'Master: `%s/nope.md` (repo: `%s/also-nope.md`)\n' "$tmp" "$tmp" \
        > "${tmp}/pointers/bad.md"

    out=$(POINTER_SEARCH_DIRS="${tmp}/pointers" bash "$SCRIPT" 2>&1); rc=$?
    assert_exit 1 "$rc" "arm b: unresolvable pointer"
    assert_contains "$out" "repo path does not exist" "arm b: unresolvable pointer"
    assert_contains "$out" "FAIL: 1 of 1 Master: pointer(s) failed to resolve" "arm b: unresolvable pointer"

    rm -rf "$tmp"
}

case_arm_c_warns_on_single_carrier_no_silent_pass() {
    local tmp out rc
    tmp=$(mktemp -d "${TMPDIR:-/tmp}/doctrinecheck.XXXXXX")
    write_good_tag_carrier "${tmp}/solo.md"
    printf 'SOLOTAG\t%s/solo.md\n' "$tmp" > "${tmp}/manifest.tsv"

    out=$(MANIFEST="${tmp}/manifest.tsv" bash "$SCRIPT" 2>&1); rc=$?
    assert_contains "$out" "WARN: SOLOTAG has only 1 carrier(s)" "arm c: single carrier"
    assert_not_contains "$out" "PASS: SOLOTAG byte-identical" "arm c: single carrier"

    rm -rf "$tmp"
}

case_arm_c_fail_zero_carrier_lines() {
    local tmp out rc
    tmp=$(mktemp -d "${TMPDIR:-/tmp}/doctrinecheck.XXXXXX")
    printf 'EMPTYTAG\t\n' > "${tmp}/manifest.tsv"

    out=$(MANIFEST="${tmp}/manifest.tsv" bash "$SCRIPT" 2>&1); rc=$?
    assert_exit 1 "$rc" "arm c: zero carrier lines"
    assert_contains "$out" "FAIL: EMPTYTAG has 0 carrier line(s)" "arm c: zero carrier lines"

    rm -rf "$tmp"
}

case_arm_c_fail_byte_mismatch() {
    local tmp out rc
    tmp=$(mktemp -d "${TMPDIR:-/tmp}/doctrinecheck.XXXXXX")
    write_good_tag_carrier "${tmp}/a.md"
    cat > "${tmp}/b.md" <<'EOF'
intro text
<!-- CANONICAL:GOODTAG:BEGIN -->
identical body line 1
DIVERGED body line 2
<!-- CANONICAL:GOODTAG:END -->
trailing text
EOF
    printf 'GOODTAG\t%s/a.md\nGOODTAG\t%s/b.md\n' "$tmp" "$tmp" > "${tmp}/manifest.tsv"

    out=$(MANIFEST="${tmp}/manifest.tsv" bash "$SCRIPT" 2>&1); rc=$?
    assert_exit 1 "$rc" "arm c: byte mismatch"
    assert_contains "$out" "FAIL: GOODTAG parity violated" "arm c: byte mismatch"
    assert_contains "$out" "differs from" "arm c: byte mismatch"

    rm -rf "$tmp"
}

case_arm_c_pass_prose_mention_not_treated_as_marker() {
    local tmp out rc
    tmp=$(mktemp -d "${TMPDIR:-/tmp}/doctrinecheck.XXXXXX")
    write_good_tag_carrier "${tmp}/a.md"
    # b.md carries the same real marker pair as a.md, plus a trailing prose
    # line that mentions the marker syntax mid-sentence (not at line start).
    # The anchored extractor (DKT-169) must not mistake this prose for a
    # second BEGIN, which would otherwise swallow the rest of the file and
    # break byte-parity against a.md.
    cat > "${tmp}/b.md" <<'EOF'
intro text
<!-- CANONICAL:GOODTAG:BEGIN -->
identical body line 1
identical body line 2
<!-- CANONICAL:GOODTAG:END -->
trailing text mentions the marker syntax `<!-- CANONICAL:GOODTAG:BEGIN -->` and `<!-- CANONICAL:GOODTAG:END -->` in running prose, not at line start
EOF
    printf 'GOODTAG\t%s/a.md\nGOODTAG\t%s/b.md\n' "$tmp" "$tmp" > "${tmp}/manifest.tsv"

    out=$(MANIFEST="${tmp}/manifest.tsv" bash "$SCRIPT" 2>&1); rc=$?
    assert_exit 0 "$rc" "arm c: prose mention of marker syntax ignored"
    assert_contains "$out" "PASS: GOODTAG byte-identical across 2 carrier(s)" "arm c: prose mention of marker syntax ignored"
    assert_not_contains "$out" "FAIL: GOODTAG parity violated" "arm c: prose mention of marker syntax ignored"

    rm -rf "$tmp"
}

case_arm_c_fail_unbalanced_begin_end_markers() {
    local tmp out rc
    tmp=$(mktemp -d "${TMPDIR:-/tmp}/doctrinecheck.XXXXXX")
    write_good_tag_carrier "${tmp}/a.md"
    # b.md has 2 real BEGIN markers but only 1 END marker for the same tag —
    # the unclosed/duplicate-marker shape the balance check (DKT-169) exists
    # to reject rather than silently extracting a runaway range.
    cat > "${tmp}/b.md" <<'EOF'
intro text
<!-- CANONICAL:GOODTAG:BEGIN -->
identical body line 1
<!-- CANONICAL:GOODTAG:BEGIN -->
identical body line 2
<!-- CANONICAL:GOODTAG:END -->
trailing text
EOF
    printf 'GOODTAG\t%s/a.md\nGOODTAG\t%s/b.md\n' "$tmp" "$tmp" > "${tmp}/manifest.tsv"

    out=$(MANIFEST="${tmp}/manifest.tsv" bash "$SCRIPT" 2>&1); rc=$?
    assert_exit 1 "$rc" "arm c: unbalanced BEGIN/END markers"
    assert_contains "$out" "BEGIN/END marker count imbalance (unclosed or duplicate marker) — refusing to compare" "arm c: unbalanced BEGIN/END markers"
    assert_contains "$out" "FAIL: GOODTAG parity violated" "arm c: unbalanced BEGIN/END markers"

    rm -rf "$tmp"
}

case_arm_d_fail_stale_cited_by_row() {
    local tmp out rc
    tmp=$(mktemp -d "${TMPDIR:-/tmp}/doctrinecheck.XXXXXX")
    mkdir -p "${tmp}/references" "${tmp}/agents"
    : > "${tmp}/references/mytag.md"
    printf 'MYTAG\t\n' > "${tmp}/manifest.tsv"
    # Row declares only consumer-a.md as a citer; consumer-b.md also cites
    # references/mytag.md on disk but was (deliberately) never added to the
    # cell — the exact drift class this arm exists to catch.
    printf '| `references/mytag.md` | desc | `consumer-a.md` |\n' > "${tmp}/skill.md"
    printf 'Master: `~/x/mytag.md` (repo: `references/mytag.md`) cites consumer-a\n' \
        > "${tmp}/agents/consumer-a.md"
    printf 'Master: `~/x/mytag.md` (repo: `references/mytag.md`) cites consumer-b\n' \
        > "${tmp}/agents/consumer-b.md"

    out=$(SKILL_MD="${tmp}/skill.md" REFERENCES_DIR="${tmp}/references" \
        MANIFEST="${tmp}/manifest.tsv" POINTER_SEARCH_DIRS="${tmp}" \
        bash "$SCRIPT" 2>&1); rc=$?
    assert_exit 1 "$rc" "arm d: stale Cited by row"
    assert_contains "$out" "FAIL: 'Cited by' citer-set parity violated" "arm d: stale Cited by row"
    assert_contains "$out" "extra: consumer-b.md cites \`references/mytag.md\` on disk but is not listed" "arm d: stale Cited by row"
    assert_not_contains "$out" "extra: consumer-a.md" "arm d: stale Cited by row"

    rm -rf "$tmp"
}

case_arm_d_fail_agents_count_divergence() {
    local tmp out rc
    tmp=$(mktemp -d "${TMPDIR:-/tmp}/doctrinecheck.XXXXXX")
    mkdir -p "${tmp}/references" "${tmp}/agents"
    : > "${tmp}/references/mytag.md"
    printf '# empty\n' > "${tmp}/manifest.tsv"
    # Cell claims "6 agents" but only 2 agent files exist on disk — a
    # count-divergence the set-membership comparison alone would miss (both
    # declared and live sets are identical: the full 2-agent roster).
    printf '| `references/mytag.md` | desc | 6 agents |\n' > "${tmp}/skill.md"
    printf 'Master: `~/x/mytag.md` (repo: `references/mytag.md`) cites consumer-a\n' \
        > "${tmp}/agents/consumer-a.md"
    printf 'Master: `~/x/mytag.md` (repo: `references/mytag.md`) cites consumer-b\n' \
        > "${tmp}/agents/consumer-b.md"

    out=$(SKILL_MD="${tmp}/skill.md" REFERENCES_DIR="${tmp}/references" \
        MANIFEST="${tmp}/manifest.tsv" POINTER_SEARCH_DIRS="${tmp}" \
        bash "$SCRIPT" 2>&1); rc=$?
    assert_exit 1 "$rc" "arm d: agents count divergence"
    assert_contains "$out" "FAIL: 'Cited by' citer-set parity violated" "arm d: agents count divergence"
    assert_contains "$out" 'cell states "6 agents" but the resolved agent roster is 2' "arm d: agents count divergence"

    rm -rf "$tmp"
}

case_arm_d_fail_skills_count_divergence() {
    local tmp out rc
    tmp=$(mktemp -d "${TMPDIR:-/tmp}/doctrinecheck.XXXXXX")
    mkdir -p "${tmp}/references" "${tmp}/skill-a" "${tmp}/skill-b"
    : > "${tmp}/references/mytag2.md"
    printf '# empty\n' > "${tmp}/manifest.tsv"
    # Cell claims "3 great skills" but only 2 names are enumerated in its own
    # parenthetical list — a bare typo the set-membership comparison alone
    # would miss (declared == live == {skill-a, skill-b}).
    printf '| `references/mytag2.md` | desc | 3 great skills (`skill-a`, `skill-b`) |\n' \
        > "${tmp}/skill.md"
    printf 'Master: `~/x/mytag2.md` (repo: `references/mytag2.md`) cites skill-a\n' \
        > "${tmp}/skill-a/SKILL.md"
    printf 'Master: `~/x/mytag2.md` (repo: `references/mytag2.md`) cites skill-b\n' \
        > "${tmp}/skill-b/SKILL.md"

    out=$(SKILL_MD="${tmp}/skill.md" REFERENCES_DIR="${tmp}/references" \
        MANIFEST="${tmp}/manifest.tsv" POINTER_SEARCH_DIRS="${tmp}" \
        bash "$SCRIPT" 2>&1); rc=$?
    assert_exit 1 "$rc" "arm d: skills count divergence"
    assert_contains "$out" "FAIL: 'Cited by' citer-set parity violated" "arm d: skills count divergence"
    assert_contains "$out" 'cell states "3 ... skills" shorthand but its parenthetical list names 2 skill(s)' "arm d: skills count divergence"

    rm -rf "$tmp"
}

case_arm_d_pass_marker_only_citer() {
    local tmp out rc
    tmp=$(mktemp -d "${TMPDIR:-/tmp}/doctrinecheck.XXXXXX")
    mkdir -p "${tmp}/references" "${tmp}/agents"
    : > "${tmp}/references/markertag.md"
    printf '# empty\n' > "${tmp}/manifest.tsv"
    # consumer-marker-only.md cites markertag.md ONLY via its
    # CANONICAL:MARKERTAG-LOCAL:BEGIN marker — no literal
    # references/markertag.md path anywhere in the file — the exact
    # citation style the marker-detection leg exists to catch.
    printf '| `references/markertag.md` | desc | `consumer-marker-only.md` |\n' \
        > "${tmp}/skill.md"
    cat > "${tmp}/agents/consumer-marker-only.md" <<'EOF'
intro text
<!-- CANONICAL:MARKERTAG-LOCAL:BEGIN -->
compact local body, no literal reference path here
<!-- CANONICAL:MARKERTAG-LOCAL:END -->
EOF

    out=$(SKILL_MD="${tmp}/skill.md" REFERENCES_DIR="${tmp}/references" \
        MANIFEST="${tmp}/manifest.tsv" POINTER_SEARCH_DIRS="${tmp}" \
        bash "$SCRIPT" 2>&1); rc=$?
    assert_contains "$out" "PASS: 1 reference row(s), 'Cited by' citer sets match live grep results" "arm d: marker-only citer"
    assert_not_contains "$out" "missing: consumer-marker-only.md" "arm d: marker-only citer"
    assert_not_contains "$out" "'Cited by' citer-set parity violated" "arm d: marker-only citer"

    rm -rf "$tmp"
}

if [ ! -f "$SCRIPT" ]; then
    printf 'FATAL: script not found at %s\n' "$SCRIPT" >&2
    exit 2
fi

case_real_repo_pass
case_arm_a_fail_disk_file_not_in_table
case_arm_b_fail_zero_pointers
case_arm_b_fail_unresolvable_pointer
case_arm_c_warns_on_single_carrier_no_silent_pass
case_arm_c_fail_zero_carrier_lines
case_arm_c_fail_byte_mismatch
case_arm_c_pass_prose_mention_not_treated_as_marker
case_arm_c_fail_unbalanced_begin_end_markers
case_arm_d_fail_stale_cited_by_row
case_arm_d_fail_agents_count_divergence
case_arm_d_fail_skills_count_divergence
case_arm_d_pass_marker_only_citer

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"

if [ "$FAIL" -ne 0 ]; then
    exit 1
fi

exit 0
