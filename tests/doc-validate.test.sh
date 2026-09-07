#!/bin/bash

# Behavior suite for .docket/bin/doc-validate.
#
# THE PROPERTY UNDER TEST: a changed doc under docs/ or
# src/user/claude_code/skills/ carries the header shape this repo's docs
# carry — a skill opens and closes a YAML frontmatter fence, everything else
# opens with a '# ' title — and the gate names every file it actually
# checked, so a reader can tell a pass from a gate that never saw the
# change.
#
# DEFECT CLASS pinned here: the frontmatter terminator
# search used to scan the whole file for ANY later '---' line, so a skill
# whose real closing fence was deleted still read as terminated once the
# scan reached a body '---' (a markdown thematic break) further down —
# src/user/claude_code/skills/docket/SKILL.md is long enough in its body to
# carry one, and is the fixture used below for exactly that reason.
#
# SEAM. Each case builds a throwaway git repo under $TMPDIR with the gate
# script copied into its own .docket/bin/ (the gate finds its repo root via
# `git -C "$(dirname "${BASH_SOURCE[0]}")")`, so a copy run from a fixture
# resolves to that fixture, never the real worktree), commits a baseline,
# then edits a file without staging or committing it — the same "changed
# but not yet committed" state doc-validate is meant to catch.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
GATE="${DOC_VALIDATE_GATE:-${REPO_ROOT}/.docket/bin/doc-validate}"
DOCKET_SKILL="${REPO_ROOT}/src/user/claude_code/skills/docket/SKILL.md"

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
[ -f "$DOCKET_SKILL" ] || fatal "fixture source not found at ${DOCKET_SKILL}"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/doc-validate-test.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT

# build_repo <dir>; a git repo with the gate script under its own
# .docket/bin/, a committed copy of the real skills/docket/SKILL.md (which
# carries a body '---' well past any reasonable frontmatter bound, from its
# 250+ line body), and a committed docs/facts/*.md with a proper '# ' title.
build_repo() { # <dir>
    local dir="$1"
    mkdir -p "${dir}/.docket/bin" \
        "${dir}/src/user/claude_code/skills/docket" \
        "${dir}/docs/facts"
    git -C "$dir" init -q
    git -C "$dir" config user.email test@test
    git -C "$dir" config user.name test
    cp "$GATE" "${dir}/.docket/bin/doc-validate"
    chmod +x "${dir}/.docket/bin/doc-validate"
    cp "$DOCKET_SKILL" "${dir}/src/user/claude_code/skills/docket/SKILL.md"
    cat > "${dir}/docs/facts/sample.md" <<'MD'
# Sample Fact

Body text.
MD
    git -C "$dir" add -A
    git -C "$dir" commit -q -m init
}

# run_gate <dir>; runs the fixture's own copy of the gate, printing combined
# stdout+stderr and returning its exit code.
run_gate() { # <dir>
    ( cd "$1" && bash .docket/bin/doc-validate 2>&1 )
}

# ---- clean tree, nothing changed: exits 0, "no docs changed" -----------
FIX="${WORK}/clean"
build_repo "$FIX"
if out=$(run_gate "$FIX"); then
    pass "clean tree: gate exits 0"
else
    fail "clean tree: expected exit 0, got non-zero"
    printf '%s\n' "$out" | sed 's/^/    /'
fi

# ---- a well-formed skill edit is named in stdout, exit 0 ---------------
FIX="${WORK}/skill-edit"
build_repo "$FIX"
printf '\nAn added paragraph.\n' >> "${FIX}/src/user/claude_code/skills/docket/SKILL.md"
if out=$(run_gate "$FIX"); then
    if printf '%s\n' "$out" | grep -q "checking src/user/claude_code/skills/docket/SKILL.md"; then
        pass "well-formed skill edit: gate exits 0 and names the file"
    else
        fail "well-formed skill edit: gate passed but did not name the file"
        printf '%s\n' "$out" | sed 's/^/    /'
    fi
else
    fail "well-formed skill edit: expected exit 0, got non-zero"
    printf '%s\n' "$out" | sed 's/^/    /'
fi

# ---- unterminated frontmatter (no later --- at all) fails --------------
FIX="${WORK}/unterminated-no-dash"
build_repo "$FIX"
python3 - "${FIX}/src/user/claude_code/skills/docket/SKILL.md" <<'PY'
import sys
path = sys.argv[1]
with open(path) as f:
    lines = f.readlines()
# Drop the closing fence and every line after it, leaving no later '---'.
close_at = None
for i, line in enumerate(lines):
    if i > 0 and line.rstrip("\n") == "---":
        close_at = i
        break
del lines[close_at:]
with open(path, "w") as f:
    f.writelines(lines)
PY
if out=$(run_gate "$FIX"); then
    fail "unterminated (no later dash): expected non-zero exit, gate passed"
else
    if printf '%s\n' "$out" | grep -q "has an unterminated frontmatter block"; then
        pass "unterminated (no later dash): gate fails"
    else
        fail "unterminated (no later dash): gate failed but not with the expected message"
        printf '%s\n' "$out" | sed 's/^/    /'
    fi
fi

# ---- unterminated frontmatter in a file WITH a body --- fails ----------
# The defeat this pins: the real closing fence is deleted, but the body still
# carries a later '---' (a markdown thematic break) that an unbounded scan
# would mistake for the terminator.
FIX="${WORK}/unterminated-with-body-dash"
build_repo "$FIX"
python3 - "${FIX}/src/user/claude_code/skills/docket/SKILL.md" <<'PY'
import sys
path = sys.argv[1]
with open(path) as f:
    lines = f.readlines()
close_at = None
for i, line in enumerate(lines):
    if i > 0 and line.rstrip("\n") == "---":
        close_at = i
        break
del lines[close_at]
# Insert a body thematic break well past any reasonable frontmatter bound.
lines.insert(49, "---\n")
with open(path, "w") as f:
    f.writelines(lines)
PY
if out=$(run_gate "$FIX"); then
    fail "unterminated (with body dash): expected non-zero exit, gate passed"
else
    if printf '%s\n' "$out" | grep -q "has an unterminated frontmatter block"; then
        pass "unterminated (with body dash): gate fails"
    else
        fail "unterminated (with body dash): gate failed but not with the expected message"
        printf '%s\n' "$out" | sed 's/^/    /'
    fi
fi

# ---- first line not --- fails ------------------------------------------
FIX="${WORK}/first-line-not-dash"
build_repo "$FIX"
sed -i.bak '1s/^---$/name: docket/' "${FIX}/src/user/claude_code/skills/docket/SKILL.md"
rm -f "${FIX}/src/user/claude_code/skills/docket/SKILL.md.bak"
if out=$(run_gate "$FIX"); then
    fail "first line not dash: expected non-zero exit, gate passed"
else
    if printf '%s\n' "$out" | grep -q "does not open with a '---' frontmatter fence"; then
        pass "first line not dash: gate fails"
    else
        fail "first line not dash: gate failed but not with the expected message"
        printf '%s\n' "$out" | sed 's/^/    /'
    fi
fi

# ---- a docs/ file without a '# ' title fails ---------------------------
FIX="${WORK}/docs-no-title"
build_repo "$FIX"
cat > "${FIX}/docs/facts/sample.md" <<'MD'
Sample Fact

Body text with no title line.
MD
if out=$(run_gate "$FIX"); then
    fail "docs file without title: expected non-zero exit, gate passed"
else
    if printf '%s\n' "$out" | grep -q "does not open with a '# ' title"; then
        pass "docs file without title: gate fails"
    else
        fail "docs file without title: gate failed but not with the expected message"
        printf '%s\n' "$out" | sed 's/^/    /'
    fi
fi

echo
if [ "$FAIL" -gt 0 ]; then
    echo "doc-validate.test.sh: FAIL (${PASS} passed, ${FAIL} failed)"
    exit 1
fi
echo "doc-validate.test.sh: PASS (${PASS} cases)"
