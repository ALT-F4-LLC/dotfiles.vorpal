#!/bin/bash

# Behavior suite for .docket/bin/sdet-abuse itself.
#
# THE PROPERTY UNDER TEST: the gate fails on every gap it claims to catch —
# an unclassified hook, an ADVISORY hook that grew a deny path, a registered
# UNWIRED hook, a stale KNOWN_UNVERIFIED entry, an under-floor suite, and an
# ENFORCING hook with no registration — and passes a clean fixture. Before
# this suite existed, UNWIRED and KNOWN_UNVERIFIED had both gone empty on the
# real tree, so three of the gate's own checks (the "suite now exists"
# warning-turned-fail, the UNWIRED-stays-unregistered check, and the
# KNOWN_UNVERIFIED staleness check) ran on no input on any real invocation.
#
# SEAM. Each case drives the gate script against a synthetic fixture tree
# (hook dir, claude_code.rs stand-in, tests dir, registry file) via the
# SDET_ABUSE_HOOKS_DIR / SDET_ABUSE_REGISTRATION / SDET_ABUSE_SUITES_DIR /
# SDET_ABUSE_REGISTRY overrides the gate script reads for exactly this
# purpose; the real tree is never touched. Fixtures live under $TMPDIR, never
# under the worktree.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
GATE="${SDET_ABUSE_GATE:-${REPO_ROOT}/.docket/bin/sdet-abuse}"

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

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$GATE" ] || fatal "gate not found at ${GATE}"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/sdet-abuse-test.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT

# build_fixture <dir>; lays down a hooks dir, a tests dir, and a minimal
# claude_code.rs stand-in with one real registration (enforcing.sh, deny-
# capable) reachable through the settings_builder chain the gate's
# is_registered() looks for.
build_fixture() { # <dir>
    local dir="$1"
    mkdir -p "${dir}/hooks" "${dir}/tests"

    cat > "${dir}/hooks/enforcing.sh" <<'HOOK'
#!/bin/bash
exit 2
HOOK
    cat > "${dir}/hooks/advisory.sh" <<'HOOK'
#!/bin/bash
echo observed
HOOK
    chmod +x "${dir}/hooks/enforcing.sh" "${dir}/hooks/advisory.sh"

    cat > "${dir}/claude_code.rs" <<'RS'
fn build() {
    let settings_builder = settings_builder
        .with_hook(
            "PreToolUse",
            Some("Bash"),
            "bash ~/.claude/hooks/enforcing.sh",
            "command",
        );
}
RS

    write_suite "${dir}/tests/enforcing.test.sh" 10
}

# write_suite <path> <case-count>; a stub suite that prints <case-count> PASS
# lines and exits 0 — enough to clear MIN_CASES (10) in the gate under test.
write_suite() { # <path> <count>
    local path="$1" count="$2"
    {
        echo '#!/bin/bash'
        echo "for i in \$(seq 1 ${count}); do echo \"PASS case \$i\"; done"
        echo 'exit 0'
    } > "$path"
    chmod +x "$path"
}

# run_gate <dir> <registry-body>; runs the gate against the fixture at <dir>
# with ENFORCING/ADVISORY/UNWIRED/KNOWN_UNVERIFIED set by <registry-body>.
# Prints the gate's combined stdout+stderr and returns its exit code.
run_gate() { # <dir> <registry-body>
    local dir="$1" registry="$2" registry_file
    registry_file="${dir}/registry.sh"
    printf '%s\n' "$registry" > "$registry_file"
    SDET_ABUSE_HOOKS_DIR="${dir}/hooks" \
        SDET_ABUSE_REGISTRATION="${dir}/claude_code.rs" \
        SDET_ABUSE_SUITES_DIR="${dir}/tests" \
        SDET_ABUSE_REGISTRY="$registry_file" \
        bash "$GATE"
}

CLEAN_REGISTRY='ENFORCING=(enforcing.sh)
ADVISORY=(advisory.sh)
UNWIRED=()
KNOWN_UNVERIFIED=()'

# ---- clean fixture passes -------------------------------------------------
FIX="${WORK}/clean"
build_fixture "$FIX"
if out=$(run_gate "$FIX" "$CLEAN_REGISTRY" 2>&1); then
    pass "clean fixture: gate exits 0"
else
    fail "clean fixture: expected exit 0, got $?"
    printf '%s\n' "$out" | sed 's/^/    /'
fi

# ---- an unclassified hook fails -------------------------------------------
FIX="${WORK}/unclassified"
build_fixture "$FIX"
cat > "${FIX}/hooks/mystery.sh" <<'HOOK'
#!/bin/bash
echo unclassified
HOOK
chmod +x "${FIX}/hooks/mystery.sh"
if out=$(run_gate "$FIX" "$CLEAN_REGISTRY" 2>&1); then
    fail "unclassified hook: expected non-zero exit, gate passed"
else
    if printf '%s\n' "$out" | grep -q "mystery.sh is not classified"; then
        pass "unclassified hook: gate fails and names it"
    else
        fail "unclassified hook: gate failed but did not name mystery.sh"
        printf '%s\n' "$out" | sed 's/^/    /'
    fi
fi

# ---- an ADVISORY hook with a deny path fails ------------------------------
FIX="${WORK}/advisory-deny"
build_fixture "$FIX"
cat > "${FIX}/hooks/advisory.sh" <<'HOOK'
#!/bin/bash
exit 2
HOOK
if out=$(run_gate "$FIX" "$CLEAN_REGISTRY" 2>&1); then
    fail "ADVISORY with deny path: expected non-zero exit, gate passed"
else
    if printf '%s\n' "$out" | grep -q "advisory.sh is ADVISORY but its code carries a deny path"; then
        pass "ADVISORY with deny path: gate fails and names it"
    else
        fail "ADVISORY with deny path: gate failed but did not name advisory.sh"
        printf '%s\n' "$out" | sed 's/^/    /'
    fi
fi

# ---- a registered UNWIRED hook fails ---------------------------------------
FIX="${WORK}/unwired-registered"
build_fixture "$FIX"
cat >> "${FIX}/claude_code.rs" <<'RS'

fn build2() {
    let settings_builder = settings_builder
        .with_hook(
            "PreToolUse",
            Some("Bash"),
            "bash ~/.claude/hooks/parked.sh",
            "command",
        );
}
RS
cat > "${FIX}/hooks/parked.sh" <<'HOOK'
#!/bin/bash
exit 2
HOOK
chmod +x "${FIX}/hooks/parked.sh"
REGISTRY='ENFORCING=(enforcing.sh)
ADVISORY=(advisory.sh)
UNWIRED=(parked.sh)
KNOWN_UNVERIFIED=()'
if out=$(run_gate "$FIX" "$REGISTRY" 2>&1); then
    fail "UNWIRED but registered: expected non-zero exit, gate passed"
else
    if printf '%s\n' "$out" | grep -q "parked.sh is UNWIRED but .* registers it"; then
        pass "UNWIRED but registered: gate fails and names it"
    else
        fail "UNWIRED but registered: gate failed but did not name parked.sh"
        printf '%s\n' "$out" | sed 's/^/    /'
    fi
fi

# ---- KNOWN_UNVERIFIED entry that is gone fails -----------------------------
FIX="${WORK}/known-unverified-gone"
build_fixture "$FIX"
REGISTRY='ENFORCING=(enforcing.sh)
ADVISORY=(advisory.sh)
UNWIRED=()
KNOWN_UNVERIFIED=(vanished.sh)'
if out=$(run_gate "$FIX" "$REGISTRY" 2>&1); then
    fail "KNOWN_UNVERIFIED entry gone: expected non-zero exit, gate passed"
else
    if printf '%s\n' "$out" | grep -q "vanished.sh is in KNOWN_UNVERIFIED but not ENFORCING"; then
        pass "KNOWN_UNVERIFIED entry gone: gate fails and names it"
    else
        fail "KNOWN_UNVERIFIED entry gone: gate failed but did not name vanished.sh"
        printf '%s\n' "$out" | sed 's/^/    /'
    fi
fi

# ---- KNOWN_UNVERIFIED entry that now has a suite fails ---------------------
FIX="${WORK}/known-unverified-now-has-suite"
build_fixture "$FIX"
REGISTRY='ENFORCING=(enforcing.sh)
ADVISORY=(advisory.sh)
UNWIRED=()
KNOWN_UNVERIFIED=(enforcing.sh)'
if out=$(run_gate "$FIX" "$REGISTRY" 2>&1); then
    fail "KNOWN_UNVERIFIED now has suite: expected non-zero exit, gate passed"
else
    if printf '%s\n' "$out" | grep -q "enforcing.sh has a suite at .* now; remove it from KNOWN_UNVERIFIED"; then
        pass "KNOWN_UNVERIFIED now has suite: gate fails and names it"
    else
        fail "KNOWN_UNVERIFIED now has suite: gate failed but did not name enforcing.sh"
        printf '%s\n' "$out" | sed 's/^/    /'
    fi
fi

# ---- a suite under MIN_CASES fails -----------------------------------------
FIX="${WORK}/under-floor"
build_fixture "$FIX"
write_suite "${FIX}/tests/enforcing.test.sh" 3
if out=$(run_gate "$FIX" "$CLEAN_REGISTRY" 2>&1); then
    fail "suite under MIN_CASES: expected non-zero exit, gate passed"
else
    if printf '%s\n' "$out" | grep -q "passed only 3 case(s), under the floor"; then
        pass "suite under MIN_CASES: gate fails and names the shortfall"
    else
        fail "suite under MIN_CASES: gate failed but did not name the shortfall"
        printf '%s\n' "$out" | sed 's/^/    /'
    fi
fi

# ---- an ENFORCING hook with no registration fails --------------------------
FIX="${WORK}/no-registration"
build_fixture "$FIX"
cat > "${FIX}/claude_code.rs" <<'RS'
fn build() {
    let settings_builder = settings_builder;
}
RS
if out=$(run_gate "$FIX" "$CLEAN_REGISTRY" 2>&1); then
    fail "ENFORCING with no registration: expected non-zero exit, gate passed"
else
    if printf '%s\n' "$out" | grep -q "enforcing.sh is ENFORCING but .* never registers it"; then
        pass "ENFORCING with no registration: gate fails and names it"
    else
        fail "ENFORCING with no registration: gate failed but did not name it"
        printf '%s\n' "$out" | sed 's/^/    /'
    fi
fi

# ---- is_registered: a collapsed one-line .with_hook call is still found ---
# Mutant pin for the earlier line-leading-`)` rule: a one-line call opened
# the scan and never closed it (the next line-leading `)` was elsewhere),
# which both let the collapsed call itself pass AND could paper over an
# unrelated missing registration later in the chain.
FIX="${WORK}/collapsed-call"
build_fixture "$FIX"
cat > "${FIX}/claude_code.rs" <<'RS'
fn build() {
    let settings_builder = settings_builder
        .with_hook("PreToolUse", None, "bash ~/.claude/hooks/enforcing.sh", "command");
}
RS
if out=$(run_gate "$FIX" "$CLEAN_REGISTRY" 2>&1); then
    pass "collapsed one-line call: registration still found"
else
    fail "collapsed one-line call: gate failed to find the registration"
    printf '%s\n' "$out" | sed 's/^/    /'
fi

# ---- is_registered: a collapsed call for ONE hook does not paper over a ---
# ---- deleted registration for ANOTHER ------------------------------------
# The fail-open direction this actually pins: a line-leading-`)`
# rule, once opened by a one-line collapsed call, stays open until the next
# line-leading `)` — which can be dozens of lines later, past a dead command
# literal for a hook whose real registration was deleted. Two ENFORCING
# hooks here: other.sh gets a genuine collapsed one-line call; enforcing.sh's
# real registration is gone, replaced by a dead literal outside any
# settings_builder chain. Only other.sh may pass; enforcing.sh must be named
# as unregistered.
FIX="${WORK}/collapsed-call-fail-open"
mkdir -p "${FIX}/hooks" "${FIX}/tests"
cat > "${FIX}/hooks/enforcing.sh" <<'HOOK'
#!/bin/bash
exit 2
HOOK
cat > "${FIX}/hooks/other.sh" <<'HOOK'
#!/bin/bash
exit 2
HOOK
cat > "${FIX}/hooks/advisory.sh" <<'HOOK'
#!/bin/bash
echo observed
HOOK
chmod +x "${FIX}/hooks/enforcing.sh" "${FIX}/hooks/other.sh" "${FIX}/hooks/advisory.sh"
write_suite "${FIX}/tests/enforcing.test.sh" 10
write_suite "${FIX}/tests/other.test.sh" 10
cat > "${FIX}/claude_code.rs" <<'RS'
fn build() {
    let settings_builder = settings_builder
        .with_hook("PreToolUse", None, "bash ~/.claude/hooks/other.sh", "command");

    // enforcing.sh's real registration was deleted; only this dead literal,
    // outside any settings_builder chain, is left behind.
    let _dead_cmd = "bash ~/.claude/hooks/enforcing.sh";
}
RS
TWO_HOOK_REGISTRY='ENFORCING=(enforcing.sh other.sh)
ADVISORY=(advisory.sh)
UNWIRED=()
KNOWN_UNVERIFIED=()'
if out=$(run_gate "$FIX" "$TWO_HOOK_REGISTRY" 2>&1); then
    fail "collapsed call fail-open: expected non-zero exit, gate passed"
else
    if printf '%s\n' "$out" | grep -q "enforcing.sh is ENFORCING but .* never registers it"; then
        pass "collapsed call fail-open: deleted registration named despite an unrelated collapsed call"
    else
        fail "collapsed call fail-open: gate failed but did not name enforcing.sh"
        printf '%s\n' "$out" | sed 's/^/    /'
    fi
fi

# ---- is_registered: a wrapped nested argument keeps the call window open --
# Mutant pin for the same rule: a nested Some(&format!(...)) that wraps onto
# its own lines makes rustfmt emit a closing-paren line inside the argument
# list, above the command literal; a line-leading `)` rule closed the window
# there and missed the registration below it.
FIX="${WORK}/wrapped-argument"
build_fixture "$FIX"
cat > "${FIX}/claude_code.rs" <<'RS'
fn build() {
    let settings_builder = settings_builder
        .with_hook(
            "PreToolUse",
            Some(&format!(
                "{}{}",
                "Bash|", "LongToolNameToForceWrap"
            )),
            "bash ~/.claude/hooks/enforcing.sh",
            "command",
        );
}
RS
if out=$(run_gate "$FIX" "$CLEAN_REGISTRY" 2>&1); then
    pass "wrapped nested argument: registration still found"
else
    fail "wrapped nested argument: gate failed to find the registration"
    printf '%s\n' "$out" | sed 's/^/    /'
fi

# ---- is_registered: a block-commented registration does not count --------
FIX="${WORK}/block-commented"
build_fixture "$FIX"
cat > "${FIX}/claude_code.rs" <<'RS'
fn build() {
    let settings_builder = settings_builder;
    /* disabled while the guard is being reworked:
    let settings_builder = settings_builder
        .with_hook(
            "PreToolUse",
            None,
            "bash ~/.claude/hooks/enforcing.sh",
            "command",
        );
    */
}
RS
if out=$(run_gate "$FIX" "$CLEAN_REGISTRY" 2>&1); then
    fail "block-commented registration: expected non-zero exit, gate passed"
else
    if printf '%s\n' "$out" | grep -q "enforcing.sh is ENFORCING but .* never registers it"; then
        pass "block-commented registration: gate fails and names it"
    else
        fail "block-commented registration: gate failed but did not name it"
        printf '%s\n' "$out" | sed 's/^/    /'
    fi
fi

# ---- is_registered: a dropped builder result does not count --------------
FIX="${WORK}/dropped-result"
build_fixture "$FIX"
cat > "${FIX}/claude_code.rs" <<'RS'
fn build() {
    let settings_builder = settings_builder;

    let _dropped = other_builder.with_hook(
        "PreToolUse",
        None,
        "bash ~/.claude/hooks/enforcing.sh",
        "command",
    );
}
RS
if out=$(run_gate "$FIX" "$CLEAN_REGISTRY" 2>&1); then
    fail "dropped builder result: expected non-zero exit, gate passed"
else
    if printf '%s\n' "$out" | grep -q "enforcing.sh is ENFORCING but .* never registers it"; then
        pass "dropped builder result: gate fails and names it"
    else
        fail "dropped builder result: gate failed but did not name it"
        printf '%s\n' "$out" | sed 's/^/    /'
    fi
fi

echo
if [ "$FAIL" -gt 0 ]; then
    echo "sdet-abuse.test.sh: FAIL (${PASS} passed, ${FAIL} failed)"
    exit 1
fi
echo "sdet-abuse.test.sh: PASS (${PASS} cases)"
