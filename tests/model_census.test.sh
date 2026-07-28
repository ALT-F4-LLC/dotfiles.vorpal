#!/bin/bash

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
SCRIPT="${REPO_ROOT}/src/user/claude-code/scripts/model_census.sh"

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

# Sets FIXTURE_BASE, FIXTURE_REPO, FIXTURE_EXEMPTIONS. FIXTURE_REPO is a
# throwaway git repo (its own .git makes ref_census.sh's git-rev-parse-based
# root resolution sweep FIXTURE_REPO instead of this repo, isolating the
# sweep). FIXTURE_EXEMPTIONS is deliberately kept OUTSIDE FIXTURE_REPO's
# swept tree — an exemptions TSV placed inside the swept tree would become a
# sweep hit against its own content (arm 2's closed-list words routinely
# appear in exemption rationale text).
setup_fixture() {
    FIXTURE_BASE=$(mktemp -d "${TMPDIR:-/tmp}/modelcensus.XXXXXX")
    FIXTURE_REPO="${FIXTURE_BASE}/repo"
    FIXTURE_EXEMPTIONS="${FIXTURE_BASE}/exemptions.tsv"
    mkdir -p "$FIXTURE_REPO"
    (cd "$FIXTURE_REPO" && git init -q .)
    : > "$FIXTURE_EXEMPTIONS"
}

teardown_fixture() {
    rm -rf "$FIXTURE_BASE"
}

run_model_census() {
    (cd "$FIXTURE_REPO" && EXEMPTIONS_TSV="$FIXTURE_EXEMPTIONS" bash "$SCRIPT" "$@")
}

case_arm1_structural_hit() {
    setup_fixture
    printf 'we should use claude-mythos-9 for this\n' > "${FIXTURE_REPO}/notes.md"

    local out rc
    out=$(run_model_census); rc=$?
    assert_exit 1 "$rc" "arm 1: structural claude-[a-z]+-[0-9] token"
    assert_contains "$out" "claude-mythos-9" "arm 1: structural claude-[a-z]+-[0-9] token"

    teardown_fixture
}

case_arm2_closed_list_hit() {
    setup_fixture
    printf 'Use the Opus tier for this task.\n' > "${FIXTURE_REPO}/notes.md"

    local out rc
    out=$(run_model_census); rc=$?
    assert_exit 1 "$rc" "arm 2: closed-list alias/product word"
    assert_contains "$out" "Opus tier" "arm 2: closed-list alias/product word"

    teardown_fixture
}

case_exemption_suppresses_hit() {
    setup_fixture
    printf 'Use the Opus tier for this task.\n' > "${FIXTURE_REPO}/notes.md"
    printf 'functional-value\tnotes.md\tOpus tier\tfixture exemption\n' > "$FIXTURE_EXEMPTIONS"

    local out rc
    out=$(run_model_census); rc=$?
    assert_exit 0 "$rc" "exemption: path-prefix + substring suppresses hit"
    assert_contains "$out" "all arms PASS" "exemption: path-prefix + substring suppresses hit"

    teardown_fixture
}

case_json_closed_arithmetic() {
    setup_fixture
    printf 'Use the Opus tier here.\nAnd claude-mythos-9 here.\n' > "${FIXTURE_REPO}/notes.md"
    printf 'functional-value\tnotes.md\tOpus tier\tfixture exemption\n' > "$FIXTURE_EXEMPTIONS"

    local out rc total exempt actionable
    out=$(run_model_census --json); rc=$?
    assert_exit 1 "$rc" "json: exit reflects remaining actionable hit"

    total=$(printf '%s' "$out" | jq '.total' 2>/dev/null)
    exempt=$(printf '%s' "$out" | jq '.exempt_count' 2>/dev/null)
    actionable=$(printf '%s' "$out" | jq '.actionable_count' 2>/dev/null)
    if [ -n "$total" ] && [ -n "$exempt" ] && [ -n "$actionable" ] \
        && [ "$total" -eq "$((exempt + actionable))" ] 2>/dev/null; then
        pass "json: total == exempt_count + actionable_count (${total} == ${exempt} + ${actionable})"
    else
        fail "json: total != exempt_count + actionable_count (total=${total} exempt=${exempt} actionable=${actionable})"
    fi

    teardown_fixture
}

case_backstop_always_exits_zero() {
    setup_fixture
    printf 'The Gold tier uses Zephyrion for something.\n' > "${FIXTURE_REPO}/notes.md"

    local out rc
    out=$(run_model_census --backstop); rc=$?
    assert_exit 0 "$rc" "backstop: always exits 0 even when it reports hits"
    assert_contains "$out" "residual capitalized-token hit" "backstop: always exits 0 even when it reports hits"

    teardown_fixture
}

case_arm4_pass_substring_present() {
    setup_fixture
    printf 'Use the Opus tier for this task.\n' > "${FIXTURE_REPO}/notes.md"
    printf 'functional-value\tnotes.md\tOpus tier\tfixture exemption\n' > "$FIXTURE_EXEMPTIONS"

    local out rc
    out=$(run_model_census); rc=$?
    assert_exit 0 "$rc" "arm4: pass when exemption substring still present under its path"
    assert_contains "$out" "arm4 (stale-exemption-row) PASS" "arm4: pass when exemption substring still present under its path"

    teardown_fixture
}

case_arm4_fail_stale_row() {
    setup_fixture
    printf 'This file has nothing to do with tiers.\n' > "${FIXTURE_REPO}/notes.md"
    printf 'functional-value\tnotes.md\tOpus tier\tfixture exemption\n' > "$FIXTURE_EXEMPTIONS"

    local out rc
    out=$(run_model_census); rc=$?
    assert_exit 1 "$rc" "arm4: fail when exemption substring no longer found under its path"
    assert_contains "$out" "FAIL: 1 stale exemption row" "arm4: fail when exemption substring no longer found under its path"
    assert_contains "$out" "Opus tier" "arm4: fail when exemption substring no longer found under its path"

    teardown_fixture
}

case_arm5_pass_canonical_alias() {
    setup_fixture
    printf 'spawn_agent(model="sonnet")\n' > "${FIXTURE_REPO}/agent.go"

    local out invented
    out=$(run_model_census --json)
    invented=$(printf '%s' "$out" | jq '.invented_alias_count' 2>/dev/null)
    if [ "$invented" = "0" ]; then
        pass "arm5: canonical alias model=\"sonnet\" produces 0 invented-alias hits"
    else
        fail "arm5: canonical alias model=\"sonnet\" unexpectedly flagged (invented_alias_count=${invented})"
    fi

    teardown_fixture
}

case_arm5_fail_invented_alias() {
    setup_fixture
    printf 'spawn_agent(model="mythos")\n' > "${FIXTURE_REPO}/agent.go"

    local out rc
    out=$(run_model_census); rc=$?
    assert_exit 1 "$rc" "arm5: fail on non-canonical model=\"mythos\" value"
    assert_contains "$out" "FAIL: 1 invented-alias hit" "arm5: fail on non-canonical model=\"mythos\" value"
    assert_contains "$out" 'model="mythos"' "arm5: fail on non-canonical model=\"mythos\" value"

    teardown_fixture
}

# Expected to FAIL at this phase: model_census_exemptions.tsv is a zero-row
# skeleton (a later phase populates real rows against the live tree), so
# arms 1+2 will legitimately find unexempted real-repo hits. Not weakened to
# force a false pass — this file is not wired into CI yet.
case_real_repo_pass() {
    local out rc
    out=$(bash "$SCRIPT" 2>&1); rc=$?
    assert_exit 0 "$rc" "real repo state"
    assert_contains "$out" "model_census.sh: all arms PASS" "real repo state"
}

if [ ! -f "$SCRIPT" ]; then
    printf 'FATAL: script not found at %s\n' "$SCRIPT" >&2
    exit 2
fi

case_arm1_structural_hit
case_arm2_closed_list_hit
case_exemption_suppresses_hit
case_json_closed_arithmetic
case_backstop_always_exits_zero
case_arm4_pass_substring_present
case_arm4_fail_stale_row
case_arm5_pass_canonical_alias
case_arm5_fail_invented_alias
case_real_repo_pass

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"

if [ "$FAIL" -ne 0 ]; then
    exit 1
fi

exit 0
