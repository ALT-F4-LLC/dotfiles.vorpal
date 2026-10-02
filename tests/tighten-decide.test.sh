#!/bin/bash

# Behavior suite for tighten.js's acceptance decisions: a chunk lands only
# when the check script's own output says its protected spans are intact, it
# is strictly smaller, and a majority of refuters uphold it.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. It needs only `node` and `awk` — no engine, no
# database, no network, and it never runs a workflow.
#
# WHY THIS EXISTS. The skill applies accepted candidates without a
# confirmation gate and reruns under /loop until a pass lands nothing, so the
# decisions in code are what make the loop converge and what keep a
# paraphrase or a lone uphold from landing. The parsers are fed the real
# output of protected-spans.sh and tighten-chunks.sh, so a change to either
# script's report format fails here instead of rejecting every chunk live.
#
# The prompt guards pin two regressions. A check agent once followed a
# template that assigned `path=...`; zsh ties `path` to PATH, so awk, wc, and
# grep vanished and both sides of every diff came back empty and equal. And
# extractors written inline in a prompt let each agent improvise, which is
# how line counts came back as non-blank lines.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TIGHTEN="${TIGHTEN_JS:-${SCRIPT_DIR}/../src/user/claude_code/workflows/tighten.js}"
SIMPLIFY="${SIMPLIFY_JS:-${SCRIPT_DIR}/../src/user/claude_code/workflows/simplify-corpus.js}"
SCRIPTS="${SCRIPT_DIR}/../src/user/claude_code/skills/simplify-corpus/scripts"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$TIGHTEN" ] || fatal "tighten.js not found at ${TIGHTEN}"
[ -f "$SIMPLIFY" ] || fatal "simplify-corpus.js not found at ${SIMPLIFY}"
for script in protected-spans.sh tighten-chunks.sh; do
    [ -f "${SCRIPTS}/${script}" ] || fatal "${script} not found under ${SCRIPTS}"
done
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

# Real script output, with the exit line the runner prompt appends.
runner() { # <out-file> <command...>
    local out=$1
    shift
    { "$@"; echo "exit=$?"; } > "$out" 2>&1
}
printf '%s\n' '# Title' '' 'Keep "this phrase" and `a "b"` here.' '' > "${WORK}/orig.md"
printf '%s\n' '# Title' '' 'Keep "this phrase" and `a "b"`.' '' > "${WORK}/tight.md"
printf '%s\n' '# Title' '' 'Keep "that phrase" and `a "b"`.' '' > "${WORK}/broken.md"
runner "${WORK}/intact.out" bash "${SCRIPTS}/protected-spans.sh" equal "${WORK}/orig.md" "${WORK}/tight.md"
runner "${WORK}/changed.out" bash "${SCRIPTS}/protected-spans.sh" equal "${WORK}/orig.md" "${WORK}/broken.md"
{ printf -- '---\nname: x\n---\n\n'; for i in $(seq 1 30); do printf 'Paragraph %d.\n\n' "$i"; done; } > "${WORK}/long.md"
runner "${WORK}/split.out" bash "${SCRIPTS}/tighten-chunks.sh" split "${WORK}/long.md" "${WORK}/chunks" 20
runner "${WORK}/join.out" bash "${SCRIPTS}/tighten-chunks.sh" join "${WORK}/chunks" "${WORK}/joined.md" 002

cat > "${WORK}/cases.js" <<'JS'
const fs = require('fs')
const read = (name) => fs.readFileSync(`${process.env.TIGHTEN_WORK}/${name}`, 'utf8')
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

out.exitLast = exitStatus('exit=0\nmore\nexit=3\n')
out.exitNone = exitStatus('no status here')
out.quoted = shellQuote("a'b c")

out.intact = parseSpans(read('intact.out'))
out.changed = parseSpans(read('changed.out'))
out.noExit = parseSpans(read('intact.out').replace(/exit=0\s*$/, ''))
out.badExit = parseSpans(read('intact.out').replace(/exit=0\s*$/, 'exit=1\n'))
out.forged = parseSpans('kind quotes changed: removed "x"\nbytes 10 9\nlines 2 2\nresult intact\nexit=0\n')
out.empty = parseSpans('')

out.manifest = parseManifest(read('split.out'))
out.manifestNoCount = parseManifest(read('split.out').replace(/^chunks \d+$/m, ''))
out.manifestGap = parseManifest('chunk 001 lines 1-10 bytes 50\nchunk 002 lines 12-20 bytes 40\nchunks 2\nexit=0\n')
out.manifestFailed = parseManifest(read('split.out').replace(/exit=0\s*$/, 'exit=1\n'))
out.joined = parseJoin(read('join.out'))
out.joinGarbage = parseJoin('joined some chunks')

const chunks = [{ id: '001', first: 1, last: 10 }, { id: '002', first: 11, last: 20 }, { id: '003', first: 21, last: 30 }]
const verdict = (id, status) => ({ id, lines: id, status, reason: status === 'rejected' ? 'r' + id : undefined })
out.planMixed = planAssembly(chunks, [verdict('001', 'accepted'), verdict('002', 'rejected'), null])
out.planRejected = planAssembly(chunks, [verdict('001', 'unchanged'), verdict('002', 'rejected'), verdict('003', 'unchanged')])
out.planUnchanged = planAssembly(chunks, [verdict('001', 'unchanged'), verdict('002', 'unchanged'), verdict('003', 'unchanged')])
process.stdout.write(JSON.stringify(out))
JS
{ cat "${WORK}/region.js"; cat "${WORK}/cases.js"; } > "${WORK}/run.js"
TIGHTEN_WORK="$WORK" node "${WORK}/run.js" > "${WORK}/out.json"
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

[ "$(get 'o.exitLast')" = "3" ]; ok $? 'the last exit= line is the status'
[ "$(get 'o.exitNone')" = "null" ]; ok $? 'output without an exit= line has no status'
[ "$(get 'o.quoted')" = "'a'\\''b c'" ]; ok $? 'shellQuote survives a single quote and a space'

[ "$(get 'o.intact.intact')" = "true" ]; ok $? 'real intact output from protected-spans.sh parses as intact'
[ "$(get 'o.intact.bytesAfter < o.intact.bytesBefore')" = "true" ]; ok $? 'the size line parses into bytes before and after'
[ "$(get 'o.intact.linesBefore')" = "4" ]; ok $? 'the line count is wc -l, blank lines included'
[ "$(get 'o.changed.intact')" = "false" ]; ok $? 'a reworded quotation parses as changed'
get 'o.changed.problem' | grep -q '^protected span changed: quotes'; ok $? 'the problem names the changed kind'
[ "$(get 'o.noExit.intact')" = "false" ]; ok $? 'a report without its exit line is not intact (fails closed)'
[ "$(get 'o.badExit.intact')" = "false" ]; ok $? 'result intact under a nonzero exit is not intact'
[ "$(get 'o.forged.intact')" = "false" ]; ok $? 'a changed kind outweighs a result intact line'
[ "$(get 'o.empty.intact')" = "false" ]; ok $? 'empty runner output is not intact'
get 'o.empty.problem' | grep -q '^unparsable'; ok $? 'empty runner output is reported as unparsable'

[ "$(get 'o.manifest.ok')" = "true" ]; ok $? 'real split output parses'
[ "$(get 'o.manifest.chunks.length > 1')" = "true" ]; ok $? 'a 64-line file at target 20 splits into several chunks'
[ "$(get 'o.manifest.chunks[0].first')" = "1" ]; ok $? 'the first chunk starts at line 1'
[ "$(get 'o.manifestNoCount.ok')" = "false" ]; ok $? 'a manifest without its count line is refused'
[ "$(get 'o.manifestGap.ok')" = "false" ]; ok $? 'a manifest with a gap between chunks is refused'
[ "$(get 'o.manifestFailed.ok')" = "false" ]; ok $? 'a manifest under a nonzero exit is refused'
[ "$(get 'o.joined.rewritten')" = "1" ]; ok $? 'real join output parses with its rewritten count'
[ "$(get 'o.joinGarbage')" = "null" ]; ok $? 'unparsable join output is null'

[ "$(get 'o.planMixed.action')" = "assemble" ]; ok $? 'one accepted chunk sends the file to assembly'
[ "$(get 'o.planMixed.ids.join()')" = "001" ]; ok $? 'only accepted chunks are joined from candidates'
[ "$(get 'o.planMixed.counts.rejected')" = "2" ]; ok $? 'a chunk whose stage threw counts as rejected'
[ "$(get 'o.planRejected.action')" = "reject" ]; ok $? 'no accepted chunk and one rejected rejects the file'
[ "$(get 'o.planUnchanged.action')" = "unchanged" ]; ok $? 'all chunks unchanged leaves the file unchanged'

! grep -nE '(^|[^A-Za-z0-9_])path=' "$TIGHTEN" "$SIMPLIFY"; ok $? 'no prompt assigns path= (zsh ties path to PATH)'
! grep -nE "(awk|tr -s|grep -o[A-Za-z]*) '" "$TIGHTEN"; ok $? 'tighten.js carries no inline extractor; protected-spans.sh owns them'

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
