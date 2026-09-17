#!/bin/bash

# Behavior suite for tighten.js's acceptance decisions: a candidate lands only
# when it is strictly smaller and a majority of refuters uphold it.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. It needs only `node` and `awk` — no engine, no
# database, no network, and it never runs a workflow.
#
# WHY THIS EXISTS. The skill applies accepted candidates without a
# confirmation gate and reruns under /loop until a pass lands nothing, so the
# two decisions in code are what make the loop converge and what keep a
# paraphrase or a lone uphold from landing. This suite pins both.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TIGHTEN="${TIGHTEN_JS:-${SCRIPT_DIR}/../src/user/claude_code/workflows/tighten.js}"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$TIGHTEN" ] || fatal "tighten.js not found at ${TIGHTEN}"
for tool in node awk; do
    command -v "$tool" >/dev/null 2>&1 || fatal "${tool} is required to run this test"
done

WORK=$(mktemp -d "${TMPDIR:-/tmp}/tighten-decide.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT

pass=0
fail=0
ok() { # <condition-already-evaluated: 0/1> <label>
    if [ "$1" -eq 0 ]; then
        pass=$((pass + 1)); printf 'PASS: %s\n' "$2"
    else
        fail=$((fail + 1)); printf 'FAIL: %s\n' "$2" >&2
    fi
}

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
    ' "$TIGHTEN"
}

extract tighten-decide > "${WORK}/region.js" || fatal "bad or missing TEST markers for tighten-decide"

cat > "${WORK}/cases.js" <<'JS'
const out = {}
out.smaller = shrank({ bytesBefore: 100, bytesAfter: 99 })
out.equal = shrank({ bytesBefore: 100, bytesAfter: 100 })
out.larger = shrank({ bytesBefore: 100, bytesAfter: 101 })
const uphold = { refuted: false, reason: '' }
const refute = (reason) => ({ refuted: true, reason })
out.threeUphold = tallyVotes([uphold, uphold, uphold])
out.twoUphold = tallyVotes([uphold, refute('a'), uphold])
out.oneUphold = tallyVotes([uphold, refute('a'), refute('b')])
out.oneUpholdTwoMissing = tallyVotes([uphold, null, null])
out.allMissing = tallyVotes([null, null, null])
process.stdout.write(JSON.stringify(out))
JS
{ cat "${WORK}/region.js"; cat "${WORK}/cases.js"; } > "${WORK}/run.js"
node "${WORK}/run.js" > "${WORK}/out.json"
ok $? 'the decision helpers evaluate outside a workflow run'

get() { node -e "const o=require('${WORK}/out.json'); process.stdout.write(String($1))"; }

[ "$(get 'o.smaller')" = "true" ]; ok $? 'a strictly smaller candidate shrank'
[ "$(get 'o.equal')" = "false" ]; ok $? 'an equal-size candidate did not shrink (a paraphrase cannot land)'
[ "$(get 'o.larger')" = "false" ]; ok $? 'a larger candidate did not shrink'

[ "$(get 'o.threeUphold.accepted')" = "true" ]; ok $? 'three upholds accept'
[ "$(get 'o.twoUphold.accepted')" = "true" ]; ok $? 'two upholds of three accept'
[ "$(get 'o.twoUphold.reasons.length')" = "1" ]; ok $? 'the dissenting reason is carried'
[ "$(get 'o.oneUphold.accepted')" = "false" ]; ok $? 'one uphold of three rejects'
[ "$(get 'o.oneUpholdTwoMissing.accepted')" = "false" ]; ok $? 'a missing vote is no vote: one uphold with two missing rejects'
[ "$(get 'o.oneUpholdTwoMissing.votes')" = "1" ]; ok $? 'missing votes are not counted as returned'
[ "$(get 'o.allMissing.accepted')" = "false" ]; ok $? 'no votes at all rejects'

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
