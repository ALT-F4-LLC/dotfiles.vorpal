#!/bin/bash
# Behavior suite for .docket/bin/crossref-check.
#
# THE PROPERTY UNDER TEST: every name the prose corpus points at exists —
# paths, relative links and their heading anchors, /docket-* skill references
# and the skill names a description hands off to, schema versions, workflow
# executors, workflow gates, routing labels, and each definition's declared
# name — and the gate names the check and the location of every reference
# that does not resolve. Nothing else reads both trees: a rename
# on one side used to leave the other side describing a thing that is gone,
# with every other gate green.
#
# SEAM. Each case builds a small synthetic corpus under $TMPDIR — not a copy
# of the real one, so each mutant changes exactly one reference — and runs
# the real gate against it through CORPUS_ROOT. The baseline passes; every
# mutant below is proven red by its own case, and two positive cases pin the
# deliberate exemptions (a renamed path inside a version changelog comment,
# an unquoted route-<word> that is ordinary English, and a PROJECT_GATES row).

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
GATE="${CROSSREF_CHECK_GATE:-${REPO_ROOT}/.docket/bin/crossref-check}"

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

WORK=$(mktemp -d "${TMPDIR:-/tmp}/crossref-check-test.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT

# build_corpus <dir>; a corpus in which every reference resolves. The
# workflow's changelog cites contracts/old.md, which does not exist, and the
# skill body says "route-specific" unquoted: both must pass.
build_corpus() { # <dir>
    local d="$1"
    rm -rf "$d"
    mkdir -p "$d/src/user/claude_code/skills/alpha/references" \
             "$d/src/user/claude_code/skills/docket-beta" \
             "$d/src/user/claude_code/agents" \
             "$d/src/user/docket/config/contracts" \
             "$d/src/user/docket/config/fragments" \
             "$d/src/user/docket/config/schemas" \
             "$d/src/user/docket/config/workflows"

    printf 'build:\n    true\n\ntests:\n    true\n' > "$d/justfile"

    cat > "$d/src/user/claude_code/skills/alpha/SKILL.md" <<'EOF'
---
name: alpha
description: fixture
---
# alpha

Read [notes](references/notes.md#notes-on-alpha) first, then /docket-beta. The contract is
src/user/docket/config/contracts/implement.md and it emits `ac-report@2`.
Issues carry `route-run`; a route-specific step follows.
EOF
    printf '# Notes on `alpha`\n\n```\n# not a heading\n```\n' > "$d/src/user/claude_code/skills/alpha/references/notes.md"
    printf -- '---\nname: docket-beta\ndescription: fixture\n---\n# beta\n' \
        > "$d/src/user/claude_code/skills/docket-beta/SKILL.md"
    printf -- '---\nname: executor-x\ndescription: fixture\n---\n# x\n' \
        > "$d/src/user/claude_code/agents/executor-x.md"

    printf '# Naming\n' > "$d/src/user/docket/config/README.md"
    cat > "$d/src/user/docket/config/policy.toml" <<'EOF'
[policy]
version = 1  # 1: initial
             # cites contracts/old.md, which is history

[executors]
implement = { variant = "sonnet-high" }
EOF
    printf -- '---\nnode: implement\nversion: 1\n---\n# Charter\n' \
        > "$d/src/user/docket/config/contracts/implement.md"
    printf -- '---\nfragment: truth\nversion: 1\n---\n# Truth\n' \
        > "$d/src/user/docket/config/fragments/truth.md"
    printf '{}\n' > "$d/src/user/docket/config/schemas/ac-report@2.json"
    cat > "$d/src/user/docket/config/workflows/ui-change.toml" <<'EOF'
[pipeline]
name = "ui-change"
version = 2  # 2: implement no longer reads contracts/old.md
             # (renamed to contracts/implement.md)

[match]
labels_any = ["ui"]
unless_labels = ["blocked", "route-direct", "route-loop", "route-tend"]

[[step]]
name = "implement"
executor = "implement"
packet = ["contracts/{executor}.md"]
gates = ["build", { name = "render-verify", pre = true }]
EOF
}

run_gate() { # <dir>
    CORPUS_ROOT="$1" bash "$GATE" 2>&1
}

# expect_pass <label> <dir>
expect_pass() {
    local out
    if out=$(run_gate "$2"); then
        pass "$1"
    else
        fail "$1 (expected pass): $out"
    fi
}

# expect_fail <label> <dir> <check> <needle>; red, and the failure line names
# the check and the reference.
expect_fail() {
    local out
    if out=$(run_gate "$2"); then
        fail "$1 (expected fail, got pass)"
    elif ! grep -q "crossref-check: $3 " <<< "$out"; then
        fail "$1 (failed, but not on check '$3'): $out"
    elif ! grep -q -- "$4" <<< "$out"; then
        fail "$1 (failed, but did not name '$4'): $out"
    else
        pass "$1"
    fi
}

FIX="$WORK/fix"
SKILL="src/user/claude_code/skills/alpha/SKILL.md"
WF="src/user/docket/config/workflows/ui-change.toml"

# --- baseline ---------------------------------------------------------------
build_corpus "$FIX"
expect_pass "baseline corpus resolves, changelog and English route-word exempt" "$FIX"

# --- path ---------------------------------------------------------------------
build_corpus "$FIX"
echo 'See src/user/docket/config/contracts/gone.md.' >> "$FIX/$SKILL"
expect_fail "path: repo-rooted path to a missing file" "$FIX" path "contracts/gone.md"

build_corpus "$FIX"
echo 'packet = ["fragments/gone.md"]' >> "$FIX/$WF"
expect_fail "path: bare corpus path inside the docket tree" "$FIX" path "fragments/gone.md"

build_corpus "$FIX"
echo 'Example layout: config/fragments/gone.md.' >> "$FIX/$SKILL"
expect_pass "path: bare corpus path outside the docket tree is not checked" "$FIX"

build_corpus "$FIX"
printf '\n# implement once read contracts/old.md\n' >> "$FIX/src/user/docket/config/policy.toml"
expect_fail "path: renamed path outside the changelog block" "$FIX" path "contracts/old.md"

# --- link -------------------------------------------------------------------
build_corpus "$FIX"
echo 'Then read [more](references/missing.md).' >> "$FIX/$SKILL"
expect_fail "link: relative link to a missing file" "$FIX" link "references/missing.md"

build_corpus "$FIX"
echo 'Then read [more](references/notes.md#notes-on-beta).' >> "$FIX/$SKILL"
expect_fail "link: anchor names no heading in the target" "$FIX" link "#notes-on-beta"

build_corpus "$FIX"
echo 'Then read [more](references/notes.md#not-a-heading).' >> "$FIX/$SKILL"
expect_fail "link: a heading inside a code fence is not an anchor" "$FIX" link "#not-a-heading"

# --- skill --------------------------------------------------------------------
build_corpus "$FIX"
echo 'Hand off to /docket-gone.' >> "$FIX/$SKILL"
expect_fail "skill: /docket-<x> with no directory" "$FIX" skill "/docket-gone"

build_corpus "$FIX"
sed -i.bak 's|^description: fixture|description: fixture; hand off to docket-gone|' "$FIX/$SKILL"
expect_fail "skill: description names a docket-<x> with no directory" "$FIX" skill "docket-gone, not a skill"

build_corpus "$FIX"
sed -i.bak 's|^description: fixture|description: fixture; authoring belongs to `beta`|' "$FIX/$SKILL"
expect_fail "skill: description uses a short form of a docket- skill" "$FIX" skill "the skill is docket-beta"

build_corpus "$FIX"
sed -i.bak 's|^description: fixture|description: fixture; hand off to `docket-beta` or `alpha`|' "$FIX/$SKILL"
expect_pass "skill: description naming real skills in full passes" "$FIX"

# --- schema -------------------------------------------------------------------
build_corpus "$FIX"
echo 'The payload is `ac-report@7`.' >> "$FIX/$SKILL"
expect_fail "schema: version with no file" "$FIX" schema "ac-report@7"

# --- executor -----------------------------------------------------------------
build_corpus "$FIX"
sed -i.bak 's|^executor = "implement"|executor = "phantom"|' "$FIX/$WF"
expect_fail "executor: no contract file" "$FIX" executor "phantom has no contract"

build_corpus "$FIX"
sed -i.bak 's|^implement = |implemnt = |' "$FIX/src/user/docket/config/policy.toml"
expect_fail "executor: no policy row" "$FIX" executor "no \[executors\] row"

# --- gate ---------------------------------------------------------------------
build_corpus "$FIX"
sed -i.bak 's|"build"|"nope"|' "$FIX/$WF"
expect_fail "gate: not a justfile recipe" "$FIX" gate "gate nope"

build_corpus "$FIX"
mv "$FIX/$WF" "$FIX/src/user/docket/config/workflows/other.toml"
sed -i.bak 's|name = "ui-change"|name = "other"|' "$FIX/src/user/docket/config/workflows/other.toml"
expect_fail "gate: PROJECT_GATES row is per workflow" "$FIX" gate "render-verify"

# --- label --------------------------------------------------------------------
build_corpus "$FIX"
echo 'Set `route-tended` on it.' >> "$FIX/$SKILL"
expect_fail "label: quoted label outside the four" "$FIX" label "route-tended"

build_corpus "$FIX"
sed -i.bak 's|, "route-loop"||' "$FIX/$WF"
expect_fail "label: unless_labels missing a routed-away label" "$FIX" label 'lacks "route-loop"'

# --- name ---------------------------------------------------------------------
build_corpus "$FIX"
sed -i.bak 's|^node: implement|node: implemnt|' "$FIX/src/user/docket/config/contracts/implement.md"
expect_fail "name: contract node differs from stem" "$FIX" name "expected 'implement'"

build_corpus "$FIX"
sed -i.bak 's|^fragment: truth|fragment: lies|' "$FIX/src/user/docket/config/fragments/truth.md"
expect_fail "name: fragment name differs from stem" "$FIX" name "expected 'truth'"

build_corpus "$FIX"
sed -i.bak 's|^name: alpha|name: beta|' "$FIX/$SKILL"
expect_fail "name: skill name differs from directory" "$FIX" name "expected 'alpha'"

build_corpus "$FIX"
sed -i.bak 's|^name: executor-x|name: executor-y|' "$FIX/src/user/claude_code/agents/executor-x.md"
expect_fail "name: agent name differs from stem" "$FIX" name "expected 'executor-x'"

# --- every failure is listed, not only the first ------------------------------
build_corpus "$FIX"
echo 'See src/user/docket/config/contracts/gone.md and /docket-gone.' >> "$FIX/$SKILL"
out=$(run_gate "$FIX")
if grep -q 'crossref-check: path ' <<< "$out" && grep -q 'crossref-check: skill ' <<< "$out"; then
    pass "reports every failing check in one run"
else
    fail "reports every failing check in one run: $out"
fi

# --- the live corpus ------------------------------------------------------------
if out=$(CORPUS_ROOT="$REPO_ROOT" bash "$GATE" 2>&1); then
    pass "live corpus resolves"
else
    fail "live corpus resolves: $out"
fi

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
