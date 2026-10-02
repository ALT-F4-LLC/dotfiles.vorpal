#!/bin/bash

# The docket-run skill's done-gate is one `docket run report --json | jq -e`
# command. It once read two fields the report never emits, behind `// []`, so
# it passed on every run. This suite takes the filter out of SKILL.md and runs
# it against the recorded run-report fixtures: it must pass a clean report and
# fail one with a silent step or a silent vote seat.
#
# DOCKET_RUN_SKILL_FILE overrides the skill under test for mutation probes.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SKILL="${DOCKET_RUN_SKILL_FILE:-${SCRIPT_DIR}/../src/user/claude_code/skills/docket-run/SKILL.md}"
FIXTURES="${SCRIPT_DIR}/../src/user/claude_code/skills/docket-cli-audit/references/cli-fixtures.json"

command -v jq >/dev/null 2>&1 || { echo "FATAL: jq is required" >&2; exit 2; }

WORK=$(mktemp -d "${TMPDIR:-/tmp}/docket-run-done-gate.XXXXXX") || exit 2
trap 'rm -rf "$WORK"' EXIT

fail=0
ok() { printf 'ok   %s\n' "$1"; }
bad() { printf 'FAIL %s\n' "$1" >&2; fail=1; }

# The fenced block that starts with `docket run report $RUN --json | jq -e`,
# with the pipe prefix and the shell quotes stripped.
sed -n '/^docket run report \$RUN --json | jq -e /,/^```$/p' "$SKILL" | sed '$d' > "${WORK}/block"
[ -s "${WORK}/block" ] || { echo "FATAL: no done-gate command in ${SKILL}" >&2; exit 2; }
[ "$(grep -c '^docket run report \$RUN --json | jq -e ' "${WORK}/block")" -eq 1 ] \
    || { echo "FATAL: expected exactly one done-gate command in ${SKILL}" >&2; exit 2; }
sed -e "1s/^docket run report \\\$RUN --json | jq -e '//" -e "\$s/'\$//" "${WORK}/block" > "${WORK}/filter"

report() { # <fixture id> [jq edit]
    jq --arg id "$1" '.results[] | select(.id == $id and .mode == "json") | .json' "$FIXTURES" | jq "${2:-.}"
}
gate() { jq -e -f "${WORK}/filter" >/dev/null 2>&1; }

report run-report | gate && ok "a report with no attempts passes" || bad "a report with no attempts fails the gate"
report run-report-after-approve '.data.step_usage += [{"step": "STEP-3"}]' | gate \
    && ok "a report whose attempted steps all carry usage passes" \
    || bad "a report whose attempted steps all carry usage fails the gate"
report run-report-after-approve | gate \
    && bad "a claimed step with no usage row passes the gate" \
    || ok "a claimed step with no usage row fails"
report run-report-after-approve '.data.step_usage += [{"step": "STEP-3"}] | .data.vote_usage_coverage = {casts: 2, reported: 1}' | gate \
    && bad "a cast with no reported usage passes the gate" \
    || ok "a cast with no reported usage fails"

if [ "$fail" -ne 0 ]; then
    echo "docket-run-done-gate: FAIL" >&2
    exit 1
fi
echo "docket-run-done-gate: PASS"
