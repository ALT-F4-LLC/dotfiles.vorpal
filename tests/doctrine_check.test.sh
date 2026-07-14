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

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"

if [ "$FAIL" -ne 0 ]; then
    exit 1
fi

exit 0
