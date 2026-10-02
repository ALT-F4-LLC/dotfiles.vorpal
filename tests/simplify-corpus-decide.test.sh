#!/bin/bash

# Behavior suite for simplify-corpus.js's decisions: which kind and landing
# rule a path gets, and that a candidate lands only when simplify-check.sh's
# own report says it passed, it is strictly smaller, it carries a greater
# version where one is required, and a majority of refuters uphold it.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. It needs only `node`, `awk`, and `bash` — no
# engine, no database, no network, and it never runs a workflow.
#
# WHY THIS EXISTS. The skill lands accepted candidates without a confirmation
# gate for every file but settings.rs and reruns under /loop until a pass
# lands nothing, so the classifier decides which files get the confirmation
# and version-bump rules, and the decision helpers are what make the loop
# converge and keep a restyling or a lone uphold from landing. The report
# parser is fed simplify-check.sh's real output, so a change to the report
# format fails here instead of rejecting every candidate live. The prompt
# guards pin the check's move out of the agent: it once composed its own
# commands from a template that set `path=`, which zsh ties to PATH, and its
# TOML gate was a `python3 -c` program the auto-mode classifier refuses.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SIMPLIFY="${SIMPLIFY_CORPUS_JS:-${SCRIPT_DIR}/../src/user/claude_code/workflows/simplify-corpus.js}"
SCRIPTS="${SCRIPT_DIR}/../src/user/claude_code/skills/simplify-corpus/scripts"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$SIMPLIFY" ] || fatal "simplify-corpus.js not found at ${SIMPLIFY}"
[ -f "${SCRIPTS}/simplify-check.sh" ] || fatal "simplify-check.sh not found under ${SCRIPTS}"
for tool in node awk; do
    command -v "$tool" >/dev/null 2>&1 || fatal "${tool} is required to run this test"
done

WORK=$(mktemp -d "${TMPDIR:-/tmp}/simplify-corpus-decide.XXXXXX") || fatal "mktemp failed"
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
    ' "$SIMPLIFY"
}

extract simplify-corpus-decide > "${WORK}/region.js" || fatal "bad or missing TEST markers for simplify-corpus-decide"

# Real check reports, with the exit line the runner prompt appends.
runner() { # <out-file> <command...>
    local out=$1
    shift
    { "$@"; echo "exit=$?"; } > "$out" 2>&1
}
printf '%s\n' '# Doc' '' 'Say "keep this" once.' 'And again, said once more.' > "${WORK}/doc.md"
printf '%s\n' '# Doc' '' 'Say "keep this" once.' > "${WORK}/doc-tight.md"
printf '%s\n' '# Doc' '' 'Say "keep that" once.' > "${WORK}/doc-broken.md"
printf '%s\n' '---' 'node: x' 'version: 4' '---' '' 'Body text, said twice.' 'Body text.' > "${WORK}/contract.md"
printf '%s\n' '---' 'node: x' 'version: 5' '---' '' 'Body text.' > "${WORK}/contract-bumped.md"
printf '%s\n' 'echo one' 'echo two' > "${WORK}/ok.sh"
printf '%s\n' 'if then fi' > "${WORK}/bad.sh"
runner "${WORK}/prose-intact.out" bash "${SCRIPTS}/simplify-check.sh" prose "${WORK}/doc.md" "${WORK}/doc-tight.md"
runner "${WORK}/prose-changed.out" bash "${SCRIPTS}/simplify-check.sh" prose "${WORK}/doc.md" "${WORK}/doc-broken.md"
runner "${WORK}/contract.out" bash "${SCRIPTS}/simplify-check.sh" contract "${WORK}/contract.md" "${WORK}/contract-bumped.md"
runner "${WORK}/shell-bad.out" bash "${SCRIPTS}/simplify-check.sh" shell "${WORK}/ok.sh" "${WORK}/bad.sh"

cat > "${WORK}/cases.js" <<'JS'
const fs = require('fs')
const read = (name) => fs.readFileSync(`${process.env.SIMPLIFY_WORK}/${name}`, 'utf8')
const out = {}
out.proseIntact = parseCheck(read('prose-intact.out'))
out.proseChanged = parseCheck(read('prose-changed.out'))
out.contractCheck = parseCheck(read('contract.out'))
out.contractBumped = versionBumped(out.contractCheck)
out.shellBad = parseCheck(read('shell-bad.out'))
out.noExit = parseCheck(read('prose-intact.out').replace(/exit=0\s*$/, ''))
out.forged = parseCheck('gate bash-n failed: syntax error\nversion -1 -1\nbytes 10 9\nlines 2 2\nresult intact\nexit=0\n')
out.empty = parseCheck('')
out.quoted = shellQuote("a'b c")
out.settings = classify('src/user/claude_code/settings.rs')
out.skill = classify('src/user/claude_code/skills/simplify-corpus/SKILL.md')
out.workflowJs = classify('src/user/claude_code/workflows/tighten.js')
out.script = classify('src/user/claude_code/skills/docket/scripts/evaluate.py')
out.statusline = classify('src/user/claude_code/statusline.sh')
out.docRecord = classify('src/user/docket/bin/doc-record')
out.contract = classify('src/user/docket/config/contracts/implement.md')
out.fragment = classify('src/user/docket/config/fragments/copy-discipline.md')
out.docketWorkflow = classify('src/user/docket/config/workflows/small-change.toml')
out.policy = classify('src/user/docket/config/policy.toml')
out.docketReadme = classify('src/user/docket/config/README.md')
out.fixture = classify('src/user/claude_code/skills/docket/evals/cases.json')
out.signers = classify('src/user/claude_code/allowed_signers')
out.smaller = shrank({ bytesBefore: 100, bytesAfter: 99 })
out.equal = shrank({ bytesBefore: 100, bytesAfter: 100 })
out.larger = shrank({ bytesBefore: 100, bytesAfter: 101 })
out.bumped = versionBumped({ versionBefore: 5, versionAfter: 6 })
out.sameVersion = versionBumped({ versionBefore: 5, versionAfter: 5 })
out.lowerVersion = versionBumped({ versionBefore: 5, versionAfter: 4 })
out.noVersion = versionBumped({ versionBefore: -1, versionAfter: -1 })
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
SIMPLIFY_WORK="$WORK" node "${WORK}/run.js" > "${WORK}/out.json"
ok $? 'the decision helpers evaluate outside a workflow run'

get() { node -e "const o=require('${WORK}/out.json'); process.stdout.write(String($1))"; }

[ "$(get 'o.settings.kind')" = "rust" ] && [ "$(get 'o.settings.confirm')" = "true" ]; ok $? 'settings.rs is rust and needs operator confirmation'
[ "$(get 'o.skill.kind')" = "prose" ] && [ "$(get 'o.skill.confirm')" = "false" ] && [ "$(get 'o.skill.versioned')" = "false" ]; ok $? 'a skill file is prose with no landing rule'
[ "$(get 'o.workflowJs.kind')" = "javascript" ]; ok $? 'a workflow script is javascript'
[ "$(get 'o.script.kind')" = "python" ]; ok $? 'a skill script is python'
[ "$(get 'o.statusline.kind')" = "shell" ]; ok $? 'statusline.sh is shell'
[ "$(get 'o.docRecord.kind')" = "shell" ]; ok $? 'the extensionless doc-record is shell'
[ "$(get 'o.contract.kind')" = "contract" ] && [ "$(get 'o.contract.versioned')" = "true" ]; ok $? 'a docket contract is versioned'
[ "$(get 'o.fragment.kind')" = "contract" ] && [ "$(get 'o.fragment.versioned')" = "true" ]; ok $? 'a docket fragment is versioned'
[ "$(get 'o.docketWorkflow.kind')" = "workflow-toml" ] && [ "$(get 'o.docketWorkflow.versioned')" = "true" ]; ok $? 'a docket workflow definition is versioned TOML'
[ "$(get 'o.policy.kind')" = "toml" ] && [ "$(get 'o.policy.versioned')" = "false" ]; ok $? 'policy.toml is plain TOML, outside the frozen check'
[ "$(get 'o.docketReadme.kind')" = "prose" ] && [ "$(get 'o.docketReadme.versioned')" = "false" ]; ok $? 'the docket README is unversioned prose'
[ "$(get 'o.fixture.kind')" = "data" ]; ok $? 'a JSON fixture is data'
[ "$(get 'o.signers.kind')" = "data" ]; ok $? 'allowed_signers is data'

[ "$(get 'o.smaller')" = "true" ]; ok $? 'a strictly smaller candidate shrank'
[ "$(get 'o.equal')" = "false" ]; ok $? 'an equal-size candidate did not shrink (a restyling cannot land)'
[ "$(get 'o.larger')" = "false" ]; ok $? 'a larger candidate did not shrink'

[ "$(get 'o.bumped')" = "true" ]; ok $? 'a greater version counts as bumped'
[ "$(get 'o.sameVersion')" = "false" ]; ok $? 'an unchanged version is not bumped'
[ "$(get 'o.lowerVersion')" = "false" ]; ok $? 'a lower version is not bumped'
[ "$(get 'o.noVersion')" = "false" ]; ok $? 'a file without a version is never bumped'

[ "$(get 'o.threeUphold.accepted')" = "true" ]; ok $? 'three upholds accept'
[ "$(get 'o.twoUphold.accepted')" = "true" ]; ok $? 'two upholds of three accept'
[ "$(get 'o.twoUphold.reasons.length')" = "1" ]; ok $? 'the dissenting reason is carried'
[ "$(get 'o.oneUphold.accepted')" = "false" ]; ok $? 'one uphold of three rejects'
[ "$(get 'o.oneUpholdTwoMissing.accepted')" = "false" ]; ok $? 'a missing vote is no vote: one uphold with two missing rejects'
[ "$(get 'o.oneUpholdTwoMissing.votes')" = "1" ]; ok $? 'missing votes are not counted as returned'
[ "$(get 'o.allMissing.accepted')" = "false" ]; ok $? 'no votes at all rejects'

[ "$(get 'o.proseIntact.intact')" = "true" ]; ok $? 'a real intact prose report parses as intact'
[ "$(get 'o.proseIntact.bytesAfter < o.proseIntact.bytesBefore')" = "true" ]; ok $? 'its size line parses into bytes before and after'
[ "$(get 'o.proseChanged.intact')" = "false" ]; ok $? 'an altered quotation parses as a failed check'
get 'o.proseChanged.problem' | grep -q '^quotes: added "keep that"'; ok $? 'the problem names the kind and the added span'
[ "$(get 'o.contractCheck.intact')" = "true" ] && [ "$(get 'o.contractCheck.versionBefore')" = "4" ] && [ "$(get 'o.contractCheck.versionAfter')" = "5" ]; ok $? 'a contract that changed only its version parses with both versions'
[ "$(get 'o.contractBumped')" = "true" ]; ok $? 'the parsed versions feed versionBumped'
[ "$(get 'o.shellBad.intact')" = "false" ]; ok $? 'a failed syntax gate parses as a failed check'
get 'o.shellBad.problem' | grep -q '^gate bash-n: '; ok $? 'the problem names the failed gate'
[ "$(get 'o.noExit.intact')" = "false" ]; ok $? 'a report without its exit line is not intact (fails closed)'
[ "$(get 'o.forged.intact')" = "false" ]; ok $? 'a failed gate outweighs a result intact line'
[ "$(get 'o.empty.intact')" = "false" ]; ok $? 'empty runner output is not intact'
get 'o.empty.problem' | grep -q '^unparsable'; ok $? 'empty runner output is reported as unparsable'
[ "$(get 'o.quoted')" = "'a'\\''b c'" ]; ok $? 'shellQuote survives a single quote and a space'

grep -q 'simplify-check.sh' "$SIMPLIFY"; ok $? 'the check runs simplify-check.sh'
! grep -nE 'python3 -c|(^|[^A-Za-z0-9_])path=' "$SIMPLIFY"; ok $? 'no prompt carries python3 -c or assigns path='
! grep -nE 'intact: \{ type' "$SIMPLIFY"; ok $? 'no agent schema reports its own intact verdict'

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
