#!/bin/bash

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
SCRIPT="${REPO_ROOT}/src/user/claude-code/scripts/drift_guard_check.py"

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

case_real_repo_pass() {
    local out rc
    out=$(python3 "$SCRIPT" \
        --doc "${REPO_ROOT}/src/user/claude-code/agents/team-lead.md" \
        --scripts-dir "${REPO_ROOT}/src/user/claude-code/scripts" 2>&1); rc=$?
    assert_exit 0 "$rc" "real repo state"
    assert_contains "$out" "drift-guard: OK" "real repo state"
}

case_drift_detected_on_stale_positional_arg() {
    local tmp out rc
    tmp=$(mktemp -d "${TMPDIR:-/tmp}/driftguardcheck.XXXXXX")
    mkdir -p "${tmp}/scripts"
    cat > "${tmp}/scripts/widget.sh" <<'EOF'
#!/bin/bash
# Usage: widget.sh <key> <count>
EOF
    cat > "${tmp}/doc.md" <<'EOF'
Run it (skip `--help` -- this is the complete, current syntax):
```
~/.claude/scripts/widget.sh <key>
```
EOF
    out=$(python3 "$SCRIPT" --doc "${tmp}/doc.md" --scripts-dir "${tmp}/scripts" 2>&1); rc=$?
    assert_exit 1 "$rc" "drift: stale positional arg"
    assert_contains "$out" "DRIFT" "drift: stale positional arg"
    assert_contains "$out" "drift-guard: FAIL" "drift: stale positional arg"

    rm -rf "$tmp"
}

# Hardening item 2 (DKT-130): the flag regex must distinguish `--dry-run`
# from `--dry-clean` -- under the pre-fix `--[A-Za-z_]+` pattern both
# normalize to `--dry` and this drift would be masked (falsely OK).
case_drift_detected_on_hyphenated_flag_variant() {
    local tmp out rc
    tmp=$(mktemp -d "${TMPDIR:-/tmp}/driftguardcheck.XXXXXX")
    mkdir -p "${tmp}/scripts"
    cat > "${tmp}/scripts/widget.sh" <<'EOF'
#!/bin/bash
# Usage: widget.sh --dry-run
EOF
    cat > "${tmp}/doc.md" <<'EOF'
Run it (skip `--help` -- this is the complete, current syntax):
```
~/.claude/scripts/widget.sh --dry-clean
```
EOF
    out=$(python3 "$SCRIPT" --doc "${tmp}/doc.md" --scripts-dir "${tmp}/scripts" 2>&1); rc=$?
    assert_exit 1 "$rc" "drift: hyphenated flag variant"
    assert_contains "$out" "DRIFT" "drift: hyphenated flag variant"
    assert_contains "$out" "--dry-run" "drift: hyphenated flag variant"
    assert_contains "$out" "--dry-clean" "drift: hyphenated flag variant"

    rm -rf "$tmp"
}

# Hardening item 3 (DKT-130): an inlined block whose text substring-matches
# two known script basenames (e.g. `census.sh` vs `model_census.sh`) must be
# reported UNRESOLVED rather than silently resolved to the first match.
case_ambiguous_basename_match_is_unresolved() {
    local tmp out rc
    tmp=$(mktemp -d "${TMPDIR:-/tmp}/driftguardcheck.XXXXXX")
    mkdir -p "${tmp}/scripts"
    cat > "${tmp}/scripts/census.sh" <<'EOF'
#!/bin/bash
# Usage: census.sh <key> <count>
EOF
    cat > "${tmp}/scripts/model_census.sh" <<'EOF'
#!/bin/bash
# Usage: model_census.sh <key> <count>
EOF
    cat > "${tmp}/doc.md" <<'EOF'
Run it (skip `--help` -- this is the complete, current syntax):
```
~/.claude/scripts/model_census.sh <key> <count>
```
EOF
    out=$(python3 "$SCRIPT" --doc "${tmp}/doc.md" --scripts-dir "${tmp}/scripts" 2>&1); rc=$?
    assert_exit 1 "$rc" "ambiguous basename match"
    assert_contains "$out" "UNRESOLVED  ambiguous script match" "ambiguous basename match"

    rm -rf "$tmp"
}

if [ ! -f "$SCRIPT" ]; then
    printf 'FATAL: script not found at %s\n' "$SCRIPT" >&2
    exit 2
fi

case_real_repo_pass
case_drift_detected_on_stale_positional_arg
case_drift_detected_on_hyphenated_flag_variant
case_ambiguous_basename_match_is_unresolved

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"

if [ "$FAIL" -ne 0 ]; then
    exit 1
fi

exit 0
