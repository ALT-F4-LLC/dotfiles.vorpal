#!/bin/bash

# Behavior suite for session-census.js's agent-cap pre-flight: planAgentCap()
# projects a fleet sweep's extract-plus-retry cost against the Workflow
# tool's 1000-agent lifetime cap.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. It needs only `node` and `awk` — no engine, no
# database, no network, and it never runs a workflow.
#
# WHY THIS EXISTS. This script's own header says a fleet window can be
# "hundreds of files," and trusts the caller (the shadow skill) to pick a
# window that fits — but nothing here ever checked that trust against the
# real cap the way corpus-check.js's AGENT_CAP/AGENT_CAP_MARGIN/verifyBudget
# pattern does for its own fan-out. An unbounded window would run straight
# into the harness's own cap mid-sweep, failing with an unattributed
# AgentCapError deep in the Extract phase instead of a clear, up-front
# account of what would be dropped and why.
#
# WHAT IS PINNED HERE. (1) a file count comfortably under budget projects
# correctly and needs no truncation; (2) a count that would exceed the
# budget with the projected retry fraction is truncated to fit, and the
# amount dropped is exactly the difference; (3) a count near but under the
# 80%-of-budget line is flagged nearBudget without truncating; (4) a count
# at or just under budget truncates nothing; (5) zero files never divides
# by zero or produces a negative maxFiles.
#
# HOW. Extracts session-census-config (the AGENT_CAP/AGENT_CAP_MARGIN/
# SCOUT_AGENTS/RETRY_ESTIMATE_FRACTION constants) and session-census-agent-cap
# (the pure planAgentCap function) and calls it directly — no workflow
# globals, no agent stubs, no I/O.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CENSUS="${SESSION_CENSUS_JS:-${SCRIPT_DIR}/../src/user/claude_code/workflows/session-census.js}"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$CENSUS" ] || fatal "session-census.js not found at ${CENSUS}"
command -v node >/dev/null 2>&1 || fatal "node is required to run this test"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/session-census-agent-cap.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT

extract() { # <region> — body between the TEST-BEGIN/TEST-END markers
    awk -v r="$1" '
        index($0, "TEST-END " r)   { open = 0; ends++ }
        open                       { print }
        index($0, "TEST-BEGIN " r) { open = 1; begins++ }
        END {
            if (begins != 1 || ends != 1) {
                printf "expected exactly one TEST-BEGIN/TEST-END pair for %s, found %d/%d\n", r, begins, ends > "/dev/stderr"
                exit 1
            }
        }
    ' "$CENSUS"
}

extract session-census-config    > "${WORK}/config.js" || fatal "bad or missing TEST markers for session-census-config"
extract session-census-agent-cap > "${WORK}/cap.js"     || fatal "bad or missing TEST markers for session-census-agent-cap"
grep -q 'function planAgentCap' "${WORK}/cap.js" || fatal "session-census-agent-cap region does not contain planAgentCap"

{
    cat "${WORK}/config.js"
    cat "${WORK}/cap.js"
} > "${WORK}/suite.mjs"

cat >> "${WORK}/suite.mjs" <<'JS'

let pass = 0
let fail = 0
const ok = (cond, label) => {
    if (cond) { pass++; console.log(`PASS: ${label}`) }
    else { fail++; console.error(`FAIL: ${label}`) }
}

const budget = AGENT_CAP - AGENT_CAP_MARGIN - SCOUT_AGENTS   // 989

// ---- (1) comfortably under budget: no truncation, not flagged near ------
{
    const plan = planAgentCap(50)
    ok(plan.maxFiles === 50, `case 1: 50 files needs no truncation (got maxFiles ${plan.maxFiles})`)
    ok(!plan.nearBudget, 'case 1: 50 files is nowhere near the budget')
    ok(plan.budget === budget, `case 1: budget is AGENT_CAP - AGENT_CAP_MARGIN - SCOUT_AGENTS (got ${plan.budget})`)
}

// ---- (2) over budget: truncated, drop amount is exact --------------------
{
    // 900 files * 1.1 = 990, just over the 989 budget.
    const plan = planAgentCap(900)
    ok(plan.projected === Math.ceil(900 * 1.1), `case 2: projected is ceil(fileCount * (1 + RETRY_ESTIMATE_FRACTION)) (got ${plan.projected})`)
    ok(plan.projected > plan.budget, `case 2: 900 files projects over budget (got projected ${plan.projected}, budget ${plan.budget})`)
    ok(plan.maxFiles < 900, `case 2: maxFiles is truncated below the requested 900 (got ${plan.maxFiles})`)
    // maxFiles itself, when re-projected, must fit — never truncate to a
    // count that STILL exceeds budget.
    const replan = planAgentCap(plan.maxFiles)
    ok(replan.projected <= plan.budget,
        `case 2: the truncated count itself projects within budget (got ${replan.projected} <= ${plan.budget})`)
}

// ---- (3) near budget (over 80%, still under 100%): flagged, not truncated
{
    // budget=989; 80% = 791.2. Need projected in (791.2, 989]. fileCount=850
    // projects to ceil(850*1.1)=935, which is > 791.2 and <= 989.
    const plan = planAgentCap(850)
    ok(plan.maxFiles === 850, `case 3: 850 files is not truncated (got maxFiles ${plan.maxFiles})`)
    ok(plan.nearBudget, `case 3: 850 files (projected ${plan.projected}) is flagged near the ${plan.budget}-budget`)
}

// ---- (4) at or just under budget: truncates nothing ----------------------
{
    // fileCount such that projected == budget exactly is unlikely with the
    // ceil/fraction arithmetic, so probe just under: the largest fileCount
    // whose projection does not exceed budget.
    let largest = 0
    for (let n = 1; n <= 1000; n++) {
        if (Math.ceil(n * (1 + RETRY_ESTIMATE_FRACTION)) <= budget) largest = n
    }
    const plan = planAgentCap(largest)
    ok(plan.maxFiles === largest, `case 4: the largest count whose projection fits is not truncated (got maxFiles ${plan.maxFiles} for fileCount ${largest})`)
    const overByOne = planAgentCap(largest + 1)
    ok(overByOne.maxFiles < largest + 1,
        `case 4: one more file than fits DOES truncate (got maxFiles ${overByOne.maxFiles} for fileCount ${largest + 1})`)
}

// ---- (5) zero files: no division by zero, no negative maxFiles -----------
{
    const plan = planAgentCap(0)
    ok(plan.maxFiles === 0, `case 5: zero files needs zero, never negative or NaN (got ${plan.maxFiles})`)
    ok(!plan.nearBudget, 'case 5: zero files is not near budget')
    ok(Number.isFinite(plan.projected), `case 5: projected is a finite number, not NaN (got ${plan.projected})`)
}

console.log(`\n${pass} passed, ${fail} failed`)
process.exit(fail === 0 ? 0 : 1)
JS

node "${WORK}/suite.mjs"
exit $?
