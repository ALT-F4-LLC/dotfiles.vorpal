#!/bin/bash

# Behavior suite for corpus-cut.js's pass decisions: which definitions a pass
# judges, how refuter votes settle a ruling, when a pass rests, and how an
# issue's replay key and the merged ledger are derived, and which prior
# issues a pass supersedes.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. It needs only `node` and `awk` — no engine, no
# database, no network, and it never runs a workflow.
#
# WHY THIS EXISTS. The skill files issues and commits the ledger without a
# confirmation gate and reruns under /loop until a pass rests, so the pure
# decisions in code are what make the loop converge, keep an unchanged corpus
# from being re-tried or re-filed, and keep a lone refuter from overturning a
# ruling. This suite pins them.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CUT="${CORPUS_CUT_JS:-${SCRIPT_DIR}/../src/user/claude_code/workflows/corpus-cut.js}"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$CUT" ] || fatal "corpus-cut.js not found at ${CUT}"
for tool in node awk; do
    command -v "$tool" >/dev/null 2>&1 || fatal "${tool} is required to run this test"
done

WORK=$(mktemp -d "${TMPDIR:-/tmp}/corpus-cut-decide.XXXXXX") || fatal "mktemp failed"
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
    ' "$CUT"
}

extract corpus-cut-config > "${WORK}/config.js" || fatal "bad or missing TEST markers for corpus-cut-config"
extract corpus-cut-decide > "${WORK}/decide.js" || fatal "bad or missing TEST markers for corpus-cut-decide"

cat > "${WORK}/cases.js" <<'JS'
const out = {}
const defs = [
  { path: 'contracts/fix.md', surface: 'contract', hash: 'aaa' },
  { path: 'fragments/truth-first.md', surface: 'fragment', hash: 'bbb' },
  { path: 'schemas/findings@13.json', surface: 'schema', hash: 'ccc' },
]
const ledger = { version: 1, verdicts: [
  { path: 'contracts/fix.md', unit: 'file', hash: 'aaa', verdict: 'stay', issue: null },
  { path: 'contracts/fix.md', unit: 'section:Emit', hash: 'aaa', verdict: 'refactor', issue: 'DOT-1' },
  { path: 'fragments/truth-first.md', unit: 'file', hash: 'old', verdict: 'stay', issue: null },
  { path: 'contracts/gone.md', unit: 'file', hash: 'zzz', verdict: 'remove', issue: 'DOT-2' },
] }

// plan
const p1 = planPass(defs, ledger, false)
out.planJudge = p1.judge.map((d) => d.path)
out.planCarried = p1.carried.map((v) => `${v.path}#${v.unit}`)
out.planDropped = p1.dropped
out.planAllJudge = planPass(defs, ledger, true).judge.length
out.planNoLedgerJudge = planPass(defs, null, false).judge.length

// judge budget
out.budgetSmall = judgeBudget(30)
out.budgetHuge = judgeBudget(AGENT_CAP)

// settle
const up = { refuted: false, proposed: '', reason: '' }
const rf = (proposed, reason) => ({ refuted: true, proposed, reason })
out.threeUphold = settleVerdict('stay', [up, up, up])
out.oneRefute = settleVerdict('stay', [up, rf('remove', 'a'), up])
out.twoAgree = settleVerdict('stay', [rf('remove', 'a'), rf('remove', 'b'), up])
out.twoDisagree = settleVerdict('stay', [rf('remove', 'a'), rf('refactor', 'b'), up])
out.twoProposeSame = settleVerdict('remove', [rf('remove', 'a'), rf('remove', 'b'), up])
out.oneSeated = settleVerdict('remove', [up, null, null])
out.noneSeated = settleVerdict('remove', [null, null, null])
out.badProposed = settleVerdict('stay', [rf('keep', 'a'), rf('keep', 'b'), up])

// subsume
const sub = subsume([
  { path: 'contracts/x.md', unit: 'file', verdict: 'remove', issue: null },
  { path: 'contracts/x.md', unit: 'section:Emit', verdict: 'refactor', issue: null },
  { path: 'contracts/x.md', unit: 'section:Gates', verdict: 'stay', issue: null },
  { path: 'contracts/y.md', unit: 'file', verdict: 'refactor', issue: null },
  { path: 'contracts/y.md', unit: 'section:Emit', verdict: 'remove', issue: null },
  { path: 'policy.toml', unit: 'file', verdict: 'stay', issue: null },
  { path: 'policy.toml', unit: 'row:fix', verdict: 'remove', issue: 'DOT-9' },
  { path: 'fragments/z.md', unit: 'file:fragment', kind: 'file', verdict: 'remove', issue: null },
  { path: 'fragments/z.md', unit: 'section:Scope', kind: 'section', verdict: 'stay', issue: null },
])
out.subsumed = sub.filter((v) => v.subsumed).map((v) => `${v.path}#${v.unit}`)
out.needsIssue = sub.filter(needsIssue).map((v) => `${v.path}#${v.unit}`)

// rest
out.restJudging = shouldRest({ judge: [defs[0]], carried: [], dropped: [] })
out.restDropped = shouldRest({ judge: [], carried: [], dropped: ['contracts/gone.md'] })
out.restAllStay = shouldRest({ judge: [], carried: [{ path: 'a', unit: 'file', verdict: 'stay', issue: null }], dropped: [] })
out.restFiled = shouldRest({ judge: [], carried: [{ path: 'a', unit: 'file', verdict: 'remove', issue: 'DOT-3' }], dropped: [] })
out.restUnfiled = shouldRest({ judge: [], carried: [{ path: 'a', unit: 'file', verdict: 'remove', issue: null }], dropped: [] })
out.restSubsumed = shouldRest({ judge: [], carried: [
  { path: 'a', unit: 'file', verdict: 'remove', issue: 'DOT-3' },
  { path: 'a', unit: 'section:Emit', verdict: 'remove', issue: null },
], dropped: [] })

// shards
const many = Array.from({ length: 100 }, (_, i) => ({ path: `p${i}`, unit: 'file' }))
out.shardsEmpty = shardEntries([], 40, 12).length
out.shardsSmall = shardEntries(many.slice(0, 5), 40, 12).map((s) => s.length)
out.shardsHundred = shardEntries(many, 40, 12).map((s) => s.length)
out.shardsCapped = shardEntries(many, 3, 12).map((s) => s.length)
out.shardsCover = shardEntries(many, 3, 12).flat().map((v) => v.path).join() === many.map((v) => v.path).join()

// key
const v = { hash: 'abcdef0123456789ffff', unit: 'section:Emit', verdict: 'remove' }
out.key = idempotencyKey(v)
out.keyHash = idempotencyKey({ ...v, hash: 'abcdef0123456789aaaa' }) === out.key
out.keyHashChange = idempotencyKey({ ...v, hash: '0000000000000000ffff' }) === out.key
out.keyVerdict = idempotencyKey({ ...v, verdict: 'refactor' }) === out.key

// merge
const merged = mergeVerdicts(
  [{ path: 'b.md', unit: 'file', verdict: 'stay' }, { path: 'a.md', unit: 'section:Z', verdict: 'stay' }],
  [{ path: 'a.md', unit: 'file', verdict: 'remove' }, { path: 'b.md', unit: 'file', verdict: 'refactor' }],
)
out.merged = merged.map((x) => `${x.path}#${x.unit}=${x.verdict}`)

// superseded
const was = (path, unit, verdict, issue, hash = 'old') => ({ path, unit, hash, verdict, issue, key: verdict === 'stay' ? null : idempotencyKey({ hash, unit, verdict }) })
const now = (path, unit, verdict, hash = 'new') => ({ path, unit, hash, verdict })
const supFresh = [
  now('a.md', 'file', 'refactor'),
  now('a.md', 'section:S', 'stay'),
  now('a.md', 'section:Null', 'refactor'),
  now('b.md', 'file', 'remove'),
  now('b.md', 'section:Emit', 'refactor'),
  now('c.md', 'file', 'remove', 'same'),
]
const supLedger = { verdicts: [
  was('a.md', 'file', 'remove', 'DOT-10'),
  was('a.md', 'section:S', 'remove', 'DOT-11'),
  was('a.md', 'section:Gone', 'refactor', 'DOT-12'),
  was('a.md', 'section:Null', 'refactor', null),
  was('b.md', 'section:Emit', 'remove', 'DOT-14'),
  was('c.md', 'file', 'remove', 'DOT-15', 'same'),
  was('k.md', 'file', 'remove', 'DOT-13'),
] }
const supPlan = { judge: [{ path: 'a.md' }, { path: 'b.md' }, { path: 'c.md' }], carried: supLedger.verdicts.filter((x) => x.path === 'k.md'), dropped: [] }
const sup = supersededIssues(supLedger, supPlan, supFresh)
const supBy = Object.fromEntries(sup.map((x) => [`${x.path}#${x.unit}`, x]))
out.supUnits = sup.map((x) => `${x.path}#${x.unit}=${x.issue}`)
out.supCut = supBy['a.md#file']?.replacementKey === idempotencyKey(supFresh[0])
out.supStay = supBy['a.md#section:S']?.replacementKey
out.supAbsent = supBy['a.md#section:Gone']?.replacementKey
out.supCarried = 'k.md#file' in supBy
out.supNoIssue = 'a.md#section:Null' in supBy
out.supSubsumed = supBy['b.md#section:Emit']?.replacementKey === idempotencyKey(supFresh[3])
out.supUnchanged = 'c.md#file' in supBy
out.supNoLedger = supersededIssues(null, supPlan, supFresh).length
process.stdout.write(JSON.stringify(out))
JS
{ cat "${WORK}/config.js"; cat "${WORK}/decide.js"; cat "${WORK}/cases.js"; } > "${WORK}/run.js"
node "${WORK}/run.js" > "${WORK}/out.json"
ok $? 'the decision helpers evaluate outside a workflow run'

get() { node -e "const o=require('${WORK}/out.json'); process.stdout.write(String($1))"; }

[ "$(get 'o.planJudge.join()')" = "fragments/truth-first.md,schemas/findings@13.json" ]; ok $? 'a changed hash and a missing verdict are judged; an unchanged definition is not'
[ "$(get 'o.planCarried.join()')" = "contracts/fix.md#file,contracts/fix.md#section:Emit" ]; ok $? 'every ledgered verdict of an unchanged definition is carried'
[ "$(get 'o.planDropped.join()')" = "contracts/gone.md" ]; ok $? 'a ledgered path gone from disk is dropped'
[ "$(get 'o.planAllJudge')" = "3" ]; ok $? 'all=true judges every definition'
[ "$(get 'o.planNoLedgerJudge')" = "3" ]; ok $? 'no ledger judges every definition'

[ "$(get 'o.budgetSmall')" = "153" ]; ok $? 'the judge budget leaves the cap margin, the record writers, and the evidence agents'
[ "$(get 'o.budgetHuge')" = "0" ]; ok $? 'a launch whose evidence alone fills the cap judges nothing rather than overrunning'

[ "$(get 'o.subsumed.join()')" = "contracts/x.md#section:Emit,contracts/x.md#section:Gates,fragments/z.md#section:Scope" ]; ok $? 'a removed file subsumes its sections; a refactored file does not'
[ "$(get 'o.needsIssue.join()')" = "contracts/x.md#file,contracts/y.md#file,contracts/y.md#section:Emit,fragments/z.md#file:fragment" ]; ok $? 'one issue per removed file, none for its sections; filed and stay entries need none'
[ "$(get 'o.subsumed.length')" = "3" ]; ok $? 'a file unit spelled by kind rather than by the literal unit still subsumes'

[ "$(get 'o.threeUphold.disposition')" = "upheld" ]; ok $? 'three upholds uphold'
[ "$(get 'o.oneRefute.disposition')" = "upheld" ]; ok $? 'one refuter of three cannot overturn'
[ "$(get 'o.oneRefute.contested')" = "true" ]; ok $? 'a lone refutation is still recorded as contested'
[ "$(get 'o.twoAgree.verdict')" = "remove" ]; ok $? 'two refuters agreeing on a replacement override the ruling'
[ "$(get 'o.twoAgree.disposition')" = "overridden" ]; ok $? 'an override is labelled overridden'
[ "$(get 'o.twoDisagree.verdict')" = "stay" ]; ok $? 'two refuters disagreeing on the replacement leave the ruling standing'
[ "$(get 'o.twoDisagree.disposition')" = "contested" ]; ok $? 'a standing ruling under a refuting majority is contested'
[ "$(get 'o.twoProposeSame.verdict')" = "remove" ]; ok $? 'a proposal equal to the ruling changes nothing'
[ "$(get 'o.oneSeated.disposition')" = "unverified" ]; ok $? 'one seated vote leaves the ruling unverified'
[ "$(get 'o.oneSeated.verdict')" = "remove" ]; ok $? 'an unverified ruling keeps the judge verdict'
[ "$(get 'o.noneSeated.disposition')" = "unverified" ]; ok $? 'no seated votes leaves the ruling unverified'
[ "$(get 'o.badProposed.verdict')" = "stay" ]; ok $? 'a proposed verdict outside stay/refactor/remove never overrides'

[ "$(get 'o.restJudging')" = "false" ]; ok $? 'a pass with something to judge does not rest'
[ "$(get 'o.restDropped')" = "false" ]; ok $? 'a ledgered path gone from disk keeps the pass awake so the ledger is rewritten'
[ "$(get 'o.restAllStay')" = "true" ]; ok $? 'nothing to judge and every carried verdict stay rests'
[ "$(get 'o.restFiled')" = "true" ]; ok $? 'nothing to judge and every cut filed rests'
[ "$(get 'o.restUnfiled')" = "false" ]; ok $? 'a carried cut without an issue keeps the pass awake'
[ "$(get 'o.restSubsumed')" = "true" ]; ok $? 'a subsumed section without an issue does not keep the pass awake'

[ "$(get 'o.shardsEmpty')" = "0" ]; ok $? 'no entries means no writer'
[ "$(get 'o.shardsSmall.join()')" = "5" ]; ok $? 'a few entries fit one writer'
[ "$(get 'o.shardsHundred.join()')" = "12,12,12,12,12,12,12,12,4" ]; ok $? 'entries shard at the per-writer size'
[ "$(get 'o.shardsCapped.join()')" = "34,34,32" ]; ok $? 'shards grow rather than exceed the writer cap'
[ "$(get 'o.shardsCover')" = "true" ]; ok $? 'sharding keeps every entry in order'

[ "$(get 'o.key')" = "corpus-cut:abcdef0123456789:section:Emit:remove" ]; ok $? 'the replay key carries hash prefix, unit, and verdict'
[ "$(get 'o.keyHash')" = "true" ]; ok $? 'a hash differing past the prefix keeps the key'
[ "$(get 'o.keyHashChange')" = "false" ]; ok $? 'a changed hash changes the key'
[ "$(get 'o.keyVerdict')" = "false" ]; ok $? 'a changed verdict changes the key'

[ "$(get 'o.merged.join()')" = "a.md#file=remove,a.md#section:Z=stay,b.md#file=refactor" ]; ok $? 'fresh verdicts replace carried ones per unit and the ledger sorts by path then unit'

[ "$(get 'o.supUnits.join()')" = "a.md#file=DOT-10,a.md#section:S=DOT-11,a.md#section:Gone=DOT-12,b.md#section:Emit=DOT-14" ]; ok $? 'every filed entry of a re-judged definition is superseded, in ledger order'
[ "$(get 'o.supCut')" = "true" ]; ok $? 'a superseded issue names the fresh cut of its unit as the replacement'
[ "$(get 'o.supStay')" = "null" ]; ok $? 'a unit that now stays has no replacement'
[ "$(get 'o.supAbsent')" = "null" ]; ok $? 'a unit the fresh verdicts no longer rule has no replacement'
[ "$(get 'o.supCarried')" = "false" ]; ok $? 'a carried entry is never superseded'
[ "$(get 'o.supNoIssue')" = "false" ]; ok $? 'an entry with no issue supersedes nothing'
[ "$(get 'o.supSubsumed')" = "true" ]; ok $? 'a section under a freshly removed file names the file issue as the replacement'
[ "$(get 'o.supUnchanged')" = "false" ]; ok $? 'a fresh key equal to the prior one replays the issue and is not superseded'
[ "$(get 'o.supNoLedger')" = "0" ]; ok $? 'no ledger supersedes nothing'

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
