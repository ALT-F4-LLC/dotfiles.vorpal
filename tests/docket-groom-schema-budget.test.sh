#!/bin/bash

# Size gate for the output schemas docket-groom.js hands to agent().
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. It needs only `node` and `awk`: no engine, no
# database, no network, and it never runs a workflow.
#
# WHY THIS EXISTS. In auto mode the harness classifies each workflow agent
# spawn, prompt and output schema together, before the agent starts. When that
# classifier is unavailable, or the caller's transcript overflows its context,
# a spawn whose schema serializes to more than 4096 characters is blocked
# ("output schema too large to pass unreviewed") and agent() resolves to null
# (claude 2.1.289). The judge's ledger schema serialized to 8141 characters, so
# judges dropped out of a groom pass whenever the classifier failed, and their
# issues fell back to inline judgment in the main session. The script now
# sends the judge a schema without descriptions and renders the descriptions
# into the judge prompt instead.
#
# WHAT IS PINNED HERE. Every schema agent() receives serializes within the
# bound; every `schema:` option in the script names one of those measured
# schemas; JUDGE_SCHEMA is LEDGER_SCHEMA minus its descriptions and nothing
# else; the field guide carries every description; and `required` still
# covers each ledger field the script dereferences.
#
# DOCKET_GROOM_JS overrides the script under test, so a mutation probe can
# point the suite at a deliberately-broken COPY under $TMPDIR and observe red
# without touching the checkout.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
GROOM="${DOCKET_GROOM_JS:-${SCRIPT_DIR}/../src/user/claude_code/workflows/docket-groom.js}"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$GROOM" ] || fatal "docket-groom.js not found at ${GROOM}"
command -v node >/dev/null 2>&1 || fatal "node is required to run this test"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/docket-groom-schema-budget.XXXXXX") || fatal "mktemp failed"
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
    ' "$GROOM"
}

extract schemas > "${WORK}/suite.js" || fatal "bad or missing TEST markers for schemas"
[ -s "${WORK}/suite.js" ] || fatal "extracted schemas region is empty"

cat >> "${WORK}/suite.js" <<'JS'

let pass = 0
let fail = 0
const ok = (cond, label) => {
    if (cond) { pass++; console.log(`PASS: ${label}`) }
    else { fail++; console.error(`FAIL: ${label}`) }
}

// The harness's bound (claude 2.1.289): a schema whose JSON.stringify form is
// longer than this is blocked whenever the spawn classifier cannot run.
const BOUND = 4096

for (const [name, schema] of Object.entries({ REGISTRY_SCHEMA, JUDGE_SCHEMA, CLUSTER_SCHEMA })) {
    const chars = JSON.stringify(schema).length
    ok(chars <= BOUND, `${name} serializes to ${chars} characters, within ${BOUND}`)
}

// An independent strip: drop `description` from every schema node, walking
// properties maps by field so a field named "description" survives.
const strip = (node) => {
    const out = {}
    for (const [key, value] of Object.entries(node)) {
        if (key === 'description') continue
        if (key === 'properties') out[key] = Object.fromEntries(Object.entries(value).map(([field, s]) => [field, strip(s)]))
        else if (key === 'items') out[key] = strip(value)
        else out[key] = value
    }
    return out
}
ok(JSON.stringify(JUDGE_SCHEMA) === JSON.stringify(strip(LEDGER_SCHEMA)),
    'JUDGE_SCHEMA is LEDGER_SCHEMA with its descriptions removed and nothing else')
ok('description' in bareSchema(CLUSTER_SCHEMA).properties.epicProposals.items.properties,
    'bareSchema keeps a field named "description"')

// Every description reaches the judge through the field guide.
const descriptions = []
const collect = (node) => {
    if (typeof node.description === 'string') descriptions.push(node.description)
    for (const s of Object.values(node.properties || {})) collect(s)
    if (node.items) collect(node.items)
}
collect(LEDGER_SCHEMA)
const guide = JUDGE_FIELD_GUIDE.split('\n')
ok(descriptions.length > 0 && guide.length === descriptions.length,
    `the field guide has one line per description (${guide.length} lines, ${descriptions.length} descriptions)`)
ok(descriptions.every((d) => guide.some((line) => line.endsWith(`: ${d}`))),
    'every LEDGER_SCHEMA description appears in the field guide')

// The ledger fields the script dereferences stay required, so an entry that
// validates carries them.
const requires = (node, keys) => keys.every((k) => (node.required || []).includes(k))
const P = JUDGE_SCHEMA.properties
ok(requires(JUDGE_SCHEMA, ['readOk', 'value', 'size', 'epic', 'duplicateCandidates', 'notes']),
    'the root requires every object and field the script reads')
ok(requires(P.value, ['decision', 'reason', 'needRemaining']), 'value requires decision, reason, and needRemaining')
ok(requires(P.size, ['tier', 'sizeVerdict', 'files', 'outcomes']), 'size requires tier, sizeVerdict, files, and outcomes')
ok(requires(P.epic, ['candidate']), 'epic requires candidate')

console.log(`\n${pass} passed, ${fail} failed`)
process.exit(fail === 0 ? 0 : 1)
JS

node "${WORK}/suite.js"
suite_status=$?

# ---- Source shape: agent() receives only the schemas measured above ----
# An inline schema literal yields an empty name here, so it fails too.
printf '%s\n' CLUSTER_SCHEMA JUDGE_SCHEMA REGISTRY_SCHEMA > "${WORK}/measured.txt"
grep -E '^[[:space:]]*schema: ' "$GROOM" \
    | sed -E 's/^[[:space:]]*schema: ([A-Za-z_]*).*/\1/' \
    | sort -u > "${WORK}/passed.txt"
shape_status=0
if diff -u "${WORK}/measured.txt" "${WORK}/passed.txt" > "${WORK}/shape.diff"; then
    echo 'PASS: every agent() schema option names a measured schema'
else
    echo 'FAIL: the agent() schema options differ from the measured schemas:' >&2
    cat "${WORK}/shape.diff" >&2
    shape_status=1
fi

[ "$suite_status" -eq 0 ] && [ "$shape_status" -eq 0 ]
