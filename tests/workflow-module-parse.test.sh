#!/bin/bash

# Module-mode parse gate for every workflow script (DOT-611).
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. It needs only `node` — no engine, no database,
# no network, and it never runs a workflow.
#
# WHY THIS EXISTS. Commit 303d8b4 shipped wave.js with two top-level
# `function probeBrief` declarations. Nothing on the way to the store parses
# these files — the vorpal "workflows" artifact is a plain file copy — so the
# defect reached ~/.claude via `just activate` and blocked ALL docket-run dispatch
# machine-wide until it surfaced live at RUN-45's first dispatch (DOT-608 fixed
# the syntax; this suite is the net that was missing).
#
# WHY THE OBVIOUS LINT IS A TRAP. `node --check wave.js` PASSES on those exact
# bytes: script mode permits function redeclaration. The Workflow tool
# evaluates these scripts as ES MODULES, where the same bytes are a
# SyntaxError. Script-mode `node --check` is therefore NOT an acceptable gate
# for this class, and the fixture below asserts both halves of that claim every
# run so the suite stays honest about why it exists.
#
# WHY NOT WRAP THE BODY IN A FUNCTION. A workflow script body ends in a
# top-level `return`, which a bare ES module rejects ("illegal return
# statement"). The tempting fix — wrap the whole file in `async function
# __m(){...}` — MASKS the very bug being hunted: inside a function body,
# duplicate function declarations are legal even in a module. (Verified
# 2026-08-24 on node v24: the wrapped duplicate parses clean.) So the check
# parses the file at TOP LEVEL, exactly as the Workflow tool does, and
# neutralizes only the offending `return` KEYWORD — `return x` becomes
# `void x`, in place, on the same line, so reported line numbers still point
# at the real file. Only column-0 `return` lines are touched: a top-level
# statement in these files is always at column 0, and the one other column-0
# match (prose inside a multi-line prompt template literal) is string content,
# where the substitution is parse-neutral.
#
# WORKFLOWS_DIR overrides the directory under test, so a mutation probe can
# point the suite at a deliberately-broken COPY under $TMPDIR and observe red
# without touching the checkout.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
WORKFLOWS="${WORKFLOWS_DIR:-${SCRIPT_DIR}/../src/user/claude_code/workflows}"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

command -v node >/dev/null 2>&1 || fatal "node is required to run this test"
[ -d "$WORKFLOWS" ] || fatal "workflows directory not found at ${WORKFLOWS}"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/workflow-module-parse.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT

# Rewrite a workflow-tool script body into something a bare ES module accepts
# WITHOUT changing what the parser sees anywhere else: only the leading
# `return` keyword of a column-0 line is replaced, in place, same line.
neutralize_top_return() { # <src> <dst>
    sed -e 's/^return[[:space:]]*$/void 0/' \
        -e 's/^return;/void 0;/' \
        -e 's/^return /void /' \
        "$1" > "$2"
}

# The gate itself: does <file> parse as a top-level ES module?
# Prints node's diagnostic on failure. Uses a .mjs temp copy rather than
# stdin so the SyntaxError names a file instead of `[stdin]`.
module_parses() { # <file> <label>
    local src="$1" label="$2" tmp="${WORK}/$2"
    neutralize_top_return "$src" "${tmp%.js}.mjs"
    node --check "${tmp%.js}.mjs" 2>&1
}

fail=0

# ---- The real workflow scripts ----------------------------------------
shopt -s nullglob
scripts=("${WORKFLOWS}"/*.js)
shopt -u nullglob

if [ "${#scripts[@]}" -eq 0 ]; then
    echo "FAIL discovery: no *.js files found under ${WORKFLOWS}"
    fail=1
fi

for src in "${scripts[@]}"; do
    name=$(basename "$src")
    if diag=$(module_parses "$src" "$name"); then
        echo "ok   ${name} parses as an ES module"
    else
        echo "FAIL ${name}: does not parse as an ES module"
        printf '%s\n' "$diag" | sed 's/^/     /'
        fail=1
    fi
done

# ---- The suite's own honesty check ------------------------------------
# Two top-level `function foo` declarations with different signatures: the
# exact shape of the DOT-608 regression. Script mode must ACCEPT it (that is
# the documented false negative) and this suite's module-mode gate must
# REJECT it (that is the whole point). If either flips, the gate is not
# testing what its header claims.
FIXTURE="${WORK}/fixture.js"
cat > "$FIXTURE" <<'JS'
function probeBrief(a) { return a }
function probeBrief(a, b) { return [a, b] }
void probeBrief
JS

if node --check "$FIXTURE" >/dev/null 2>&1; then
    echo "ok   script-mode \`node --check\` accepts a duplicate top-level function (the false negative)"
else
    echo "FAIL false-negative fixture: script-mode \`node --check\` REJECTED the duplicate."
    echo "     The documented false negative no longer holds on this node; the header's"
    echo "     rationale needs re-deriving before trusting either gate."
    fail=1
fi

if diag=$(module_parses "$FIXTURE" "fixture.js"); then
    echo "FAIL true-positive fixture: module-mode check ACCEPTED a duplicate top-level function."
    echo "     This gate would not have caught DOT-608 — it is not enforcing anything."
    fail=1
elif printf '%s' "$diag" | grep -q "has already been declared"; then
    echo "ok   module-mode check rejects the same bytes (\"Identifier 'probeBrief' has already been declared\")"
else
    echo "FAIL true-positive fixture: module-mode check failed, but not for the expected reason."
    printf '%s\n' "$diag" | sed 's/^/     /'
    fail=1
fi

# And the neutralizer must not be doing the rejecting for us: the same
# fixture WITHOUT the duplicate has to sail through, trailing return and all.
CLEAN="${WORK}/clean.js"
cat > "$CLEAN" <<'JS'
function probeBrief(a) { return a }
return probeBrief(1)
JS
if diag=$(module_parses "$CLEAN" "clean.js"); then
    echo "ok   a clean script body with a trailing top-level return still passes"
else
    echo "FAIL neutralizer: a clean script body was rejected — the gate would cry wolf."
    printf '%s\n' "$diag" | sed 's/^/     /'
    fail=1
fi

if [ "$fail" -ne 0 ]; then
    echo "workflow-module-parse: FAIL — a workflow script does not parse as the Workflow tool will evaluate it." >&2
    exit 1
fi
echo "workflow-module-parse: PASS"
