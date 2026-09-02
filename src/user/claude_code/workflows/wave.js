export const meta = {
    name: 'wave',
    description: 'Run one dispatched manifest end to end: spawn one executor per executor row (routed by policy.toml), seat a judge panel on each vote row, and skip action rows (engine-run at record time). Stages run as awaited groups per issue lane, with the cross-issue cohorts the manifest certifies honored — the staged closure means one wave can carry judges -> gate -> reconcile -> report, and no issue idles behind the slower stages of another. Invoke by scriptPath ONLY, with args {rows, policyText} as a real object — policy.toml is passed as TEXT, never a path; the script cannot read files.',
    whenToUse: 'Invoked by the conduct skill on an open dispatch, always as Workflow({scriptPath}) — never by name. args is {rows, policyText}: `next` rows verbatim (executor, vote, and action rows; human rows stay with the conductor) plus the literal TEXT of policy.toml. On a dispatch carrying a fix round\'s review fanout, args also carries `integrated` — a map from each such issue to the sha of its prior round\'s INTEGRATION commit — so the wave can assert base ancestry before seating the fanout. There is no policyPath and no file access.',
}

// ---------------------------------------------------------------------------
// TOML subset parser, byte-identical to tribunal.js's. A workflow script has
// no file access or module resolution, so this is either a duplicate or a
// second parser that drifts; tests/workflow-sync.test.sh diffs every
// SYNC-marked region between the two files (self-names normalized) and
// fails on drift.
// ---------------------------------------------------------------------------

// SYNC-BEGIN policy-parser
const SUBSET = 'tables, array-of-tables, inline tables, quoted strings, integers, arrays of strings, # comments outside quotes'

function bail(line, n, why) {
    throw new Error(
        `wave.js policy parser: ${why} (line ${n}: ${JSON.stringify(line)}). ` +
        `This is NOT a general TOML parser — it accepts only: ${SUBSET}. ` +
        `Fix policy.toml or widen the parser deliberately; do not parse partially.`
    )
}

function decomment(s) {
    let q = false
    for (let i = 0; i < s.length; i++) {
        const c = s[i]
        if (c === '"' && s[i - 1] !== '\\') q = !q
        else if (c === '#' && !q) return s.slice(0, i)
    }
    return s
}

function scalar(v, line, n) {
    v = v.trim()
    if (/^"(?:[^"\\]|\\.)*"$/.test(v)) return JSON.parse(v)
    if (/^-?\d+$/.test(v)) return parseInt(v, 10)
    if (/^'/.test(v)) bail(line, n, 'literal (single-quoted) strings are out of subset')
    if (/^(true|false)$/.test(v)) bail(line, n, 'booleans are out of subset')
    if (/^-?\d+\./.test(v)) bail(line, n, 'floats are out of subset')
    bail(line, n, `unsupported value ${JSON.stringify(v)}`)
}

function arrayOfStrings(v, line, n) {
    const inner = v.trim().slice(1, -1).trim()
    if (inner === '') return []
    if (inner.includes('[')) bail(line, n, 'nested arrays are out of subset')
    return splitTop(inner).map((e) => {
        const s = scalar(e, line, n)
        if (typeof s !== 'string') bail(line, n, 'only arrays OF STRINGS are in subset')
        return s
    })
}

function splitTop(s) {
    const out = []
    let cur = '', q = false
    for (let i = 0; i < s.length; i++) {
        const c = s[i]
        if (c === '"' && s[i - 1] !== '\\') { q = !q; cur += c }
        else if (c === ',' && !q) { out.push(cur); cur = '' }
        else cur += c
    }
    if (cur.trim() !== '') out.push(cur)
    return out.map((e) => e.trim()).filter((e) => e !== '')
}

function inlineTable(v, line, n) {
    const obj = {}
    for (const pair of splitTop(v.trim().slice(1, -1))) {
        const eq = pair.indexOf('=')
        if (eq < 0) bail(line, n, 'inline-table entry without `=`')
        const k = pair.slice(0, eq).trim()
        const raw = pair.slice(eq + 1).trim()
        obj[k] = raw.startsWith('[') ? arrayOfStrings(raw, line, n) : scalar(raw, line, n)
    }
    return obj
}

function parseToml(text) {
    const root = {}
    let cur = root
    let pendingKey = null, pendingBuf = '', pendingLine = 0

    const lines = text.split('\n')
    for (let i = 0; i < lines.length; i++) {
        const rawLine = lines[i]
        const n = i + 1
        let line = decomment(rawLine).trim()
        if (line === '') continue

        if (pendingKey !== null) {
            pendingBuf += ' ' + line
            if (!line.includes(']')) continue
            cur[pendingKey] = arrayOfStrings(pendingBuf, pendingBuf, pendingLine)
            pendingKey = null; pendingBuf = ''
            continue
        }

        let m = line.match(/^\[\[([A-Za-z0-9_.-]+)\]\]$/)
        if (m) {
            const path = m[1].split('.')
            let node = root
            for (let j = 0; j < path.length - 1; j++) {
                const seg = path[j]
                if (Array.isArray(node[seg])) node = node[seg][node[seg].length - 1]
                else node = (node[seg] = node[seg] || {})
            }
            const leaf = path[path.length - 1]
            if (!Array.isArray(node[leaf])) node[leaf] = []
            const entry = {}
            node[leaf].push(entry)
            cur = entry
            continue
        }

        m = line.match(/^\[([A-Za-z0-9_.-]+)\]$/)
        if (m) {
            const path = m[1].split('.')
            let node = root
            for (const seg of path) {
                if (Array.isArray(node[seg])) node = node[seg][node[seg].length - 1]
                else node = (node[seg] = node[seg] || {})
            }
            cur = node
            continue
        }

        if (line.startsWith('[')) bail(rawLine, n, 'malformed table header')

        const eq = line.indexOf('=')
        if (eq < 0) bail(rawLine, n, 'line is neither a table header nor a key/value pair')
        const key = line.slice(0, eq).trim()
        if (!/^[A-Za-z0-9_-]+$/.test(key)) bail(rawLine, n, `unsupported key ${JSON.stringify(key)} (dotted/quoted keys are out of subset)`)
        const val = line.slice(eq + 1).trim()

        if (val === '') bail(rawLine, n, 'empty value (multi-line strings are out of subset)')
        if (val.startsWith('"""') || val.startsWith("'''")) bail(rawLine, n, 'multi-line strings are out of subset')
        if (val.startsWith('{')) {
            if (!val.endsWith('}')) bail(rawLine, n, 'multi-line inline tables are out of subset')
            cur[key] = inlineTable(val, rawLine, n)
        } else if (val.startsWith('[')) {
            if (val.endsWith(']')) cur[key] = arrayOfStrings(val, rawLine, n)
            else { pendingKey = key; pendingBuf = val; pendingLine = n }   // wraps
        } else {
            cur[key] = scalar(val, rawLine, n)
        }
    }
    if (pendingKey !== null) bail('', pendingLine, 'unterminated array')
    return root
}
// SYNC-END policy-parser

// SYNC-BEGIN policy-shape
// What this reads out of policy.toml is a SHAPE, not a version number: a
// [executors].<seat>.variant naming a [variants] row, carrying model/effort/
// escalate_to. That shape hasn't moved since v2, so an exact-match check on
// the current version refuses healthy policy the moment it bumps — pinned at
// 15, it refused v16 and blocked every dispatch wave and gate fleet-wide.
// So this mirrors the conduct skill's own [policy] gate (present,
// integer) against a documented floor, then checks the tables routing
// actually depends on: a version above the floor is fine, a missing
// [variants]/[executors] table is not.
const POLICY_VERSION_FLOOR = 2   // first version carrying the [executors].variant -> [variants]/escalate_to shape this file routes on

function assertPolicyShape(policy, refusal) {
    const version = policy.policy?.version
    if (!Number.isInteger(version)) {
        throw new Error(
            `wave.js: policy.toml [policy] version is ${JSON.stringify(version)} — the ` +
            `[policy] table must declare an integer version field. ${refusal}`
        )
    }
    if (version < POLICY_VERSION_FLOOR) {
        throw new Error(
            `wave.js: policy.toml [policy] version is ${version}, below the floor ` +
            `${POLICY_VERSION_FLOOR} — the [executors].variant -> [variants]/escalate_to ` +
            `routing shape this script reads dates from v${POLICY_VERSION_FLOOR}. ${refusal}`
        )
    }
    for (const table of ['executors', 'variants']) {
        const t = policy[table]
        if (!t || typeof t !== 'object' || Array.isArray(t) || Object.keys(t).length === 0) {
            throw new Error(
                `wave.js: policy.toml (version ${version}) carries no non-empty [${table}] ` +
                `table — that is the shape this script routes against, whatever the version ` +
                `number says. ${refusal}`
            )
        }
    }
    return version
}
// SYNC-END policy-shape

const INVESTIGATOR_CLASS = ['investigate', 'research']

function executorRow(policy, hint) {
    const row = (policy.executors || {})[hint]
    return row ? { key: hint, row } : null
}

function variantSpec(policy, name) {
    return (policy.variants || {})[name]
}

// Entering a fable-model variant BY CHAIN-WALK needs a gate; rows STANDING on
// a fable variant need none — resolve() consults this only when the walk
// actually moved the variant, so a standing home declared in policy.toml is
// honored without a hardcoded roster. The failed-top-opus-round gate is
// structural, not name-matched: work whose standing variant is already at the
// top Opus efforts (xhigh/max) has nowhere left in Opus to earn.
function fableEligible(policy, hint, row, standingVariant) {
    const gates = (policy.escalation && policy.escalation.fable_gates) || []
    const labels = labelsOf(row)
    const standing = variantSpec(policy, standingVariant) || {}
    for (const g of gates) {
        if (g === 'investigator-class' && INVESTIGATOR_CLASS.includes(hint)) return true
        if (g === 'novel-architecture' && labels.includes('novel-architecture')) return true
        if (g === 'failed-top-opus-round' && row.attempt > 0 &&
            standing.model === 'opus' &&
            (standing.effort === 'xhigh' || standing.effort === 'max')) return true
    }
    return false
}

function labelsOf(row) {
    if (Array.isArray(row.labels)) return row.labels
    if (row.issue && Array.isArray(row.issue.labels)) return row.issue.labels
    return []
}

// Round-based escalation hops. A fix-loop round is a FRESH step id:
// `docket step resolve --as fix-round` mints fix@N+1 at attempt 0, so the
// attempt walk in resolve() never sees a loop's failure history — one past
// run had its fixer burn nine fix rounds pinned at its standing variant
// while every judge reviewing it stood at opus-high. The engine
// encodes the round ordinal in the manifest row's instance name — `name@N`,
// with `#k` for fanout siblings, and a loop step's first entry minted at @1 —
// and [escalation] on_round = "one-hop" + round_executors opts an executor
// into counting each round AFTER its first as one escalate_to hop. Scoping by
// executor name is deliberate: EVERY per-round step shares the ordinal
// (review@N judge fanouts, synthesize@N, verify@N), and only the listed
// loop-workers should climb — the workflow's own `loop = true` marker never
// reaches the manifest row, so policy.toml is the only conduit this routing
// can read it from.
function roundHops(policy, hint, row) {
    const esc = policy.escalation || {}
    if (esc.on_round !== 'one-hop') return 0
    if (!(esc.round_executors || []).includes(hint)) return 0
    const m = /@(\d+)(?:#\d+)?$/.exec(row.instance || '')
    if (!m) return 0
    const round = parseInt(m[1], 10)
    return round > 1 ? round - 1 : 0
}

function resolve(row, policy) {
    const labels = labelsOf(row)

    if (row.kind !== 'executor') {
        // action and vote rows never reach resolve(): the stage loop below
        // handles both natively (skip / seat a panel). Anything else here is
        // a misrouted row.
        const why = {
            human: 'human gate steps are never claimed — they are approved or ' +
                'rejected directly, and they stay with the conductor',
        }[row.kind] || 'only kind:"executor" rows are spawnable'
        throw new Error(
            `wave.js: step ${row.step} is kind:${JSON.stringify(row.kind)} — ${why}. ` +
            `Refusing to route.`
        )
    }

    // Executor hints are CONCRETE [executors] names. The label-keyed
    // [[resolve]] tables are retired: label routing is when-gated
    // sibling steps in the workflow files, each declaring its concrete
    // executor, so the engine's own packet substitution renders the right
    // contract and no harness-side hint rewrite exists anymore. The guard at
    // module load refuses a policy that still carries tables.
    const hint = row.executor
    const found = executorRow(policy, hint)
    if (!found) {
        throw new Error(
            `wave.js: executor hint ${JSON.stringify(hint)} has no [executors] row ` +
            `(step ${row.step}). Coverage invariant violated — policy.toml and the ` +
            `workflow corpus have drifted. Refusing to route.`
        )
    }
    const rowPolicy = found.row
    let variant = rowPolicy.variant
    let never = (rowPolicy.never || []).slice()

    const sec = policy.security || {}
    const sensitive =
        (sec.nodes || []).includes(found.key) ||
        (sec.labels || []).some((l) => labels.includes(l))
    if (sensitive) never = never.concat(sec.never || [])

    // The security ceiling is a TRUE BOUND without needing a variant ordering:
    // everything reachable FROM the ceiling by escalate_to chain lies beyond
    // it. A sensitive row standing beyond the ceiling is clamped back to it,
    // and the walk below never enters the beyond set — so a ceiling off a
    // row's chain path still binds instead of being skipped as a waypoint.
    const ceiling = sensitive ? sec.ceiling : null
    const beyond = new Set()
    if (ceiling) {
        let c = variantSpec(policy, ceiling)
        if (!c) {
            throw new Error(
                `wave.js: [security].ceiling ${JSON.stringify(ceiling)} has no ` +
                `[variants] row (step ${row.step}) — a mistyped ceiling would ` +
                `silently stop binding. Fix policy.toml. Refusing to route.`
            )
        }
        while (c && c.escalate_to && !beyond.has(c.escalate_to)) {
            beyond.add(c.escalate_to)
            c = variantSpec(policy, c.escalate_to)
        }
        if (beyond.has(variant)) variant = ceiling
    }

    const standing = variant
    // Escalation: one escalate_to hop per prior claim (row.attempt counts
    // claims-so-far, whatever ended each one) from the standing variant, PLUS
    // one hop per prior fix-loop round for opted-in executors (roundHops
    // above) — a loop round is a fresh step id at attempt 0, so without the
    // round term the walk restarted from standing every round. The walk
    // stops at the chain's end or the security ceiling. A hop whose model is
    // never-listed REDIRECTS through [escalation.fallback] rather than
    // ending there — the non-pinned path enters the fable variant, fails
    // fableEligible(), and lands on the fallback — and the redirect is
    // itself a ceiling-bounded hop.
    const hops = (row.attempt > 0 ? row.attempt : 0) + roundHops(policy, found.key, row)
    if (hops > 0) {
        for (let hop = 0; hop < hops; hop++) {
            if (ceiling && variant === ceiling) break
            const cur = variantSpec(policy, variant)
            if (!cur || !cur.escalate_to) break
            const next = variantSpec(policy, cur.escalate_to)
            if (!next) {
                throw new Error(
                    `wave.js: variant ${JSON.stringify(variant)} escalates to ` +
                    `${JSON.stringify(cur.escalate_to)}, which has no [variants] row ` +
                    `(step ${row.step}). Fix policy.toml. Refusing to route.`
                )
            }
            if (ceiling && beyond.has(cur.escalate_to)) {
                // A chain hop that would overshoot the ceiling clamps UP to
                // it rather than stranding the step below its permitted top.
                variant = ceiling
                break
            }
            if (never.includes(next.model)) {
                const fb = ((policy.escalation || {}).fallback || {})[cur.escalate_to]
                const fbSpec = fb ? variantSpec(policy, fb) : null
                if (!fbSpec || never.includes(fbSpec.model) || fb === variant) break
                if (ceiling && beyond.has(fb)) {
                    variant = ceiling
                    break
                }
                variant = fb
                continue
            }
            variant = cur.escalate_to
        }
    }

    let spec = variantSpec(policy, variant)
    if (!spec) {
        throw new Error(
            `wave.js: executor ${JSON.stringify(found.key)} names variant ` +
            `${JSON.stringify(variant)}, which has no [variants] row ` +
            `(step ${row.step}). Fix policy.toml. Refusing to route.`
        )
    }

    if (spec.model === 'fable' && variant !== standing &&
        !fableEligible(policy, found.key, row, standing)) {
        variant = ((policy.escalation || {}).fallback || {})[variant]
        spec = variantSpec(policy, variant)
        if (!spec) {
            throw new Error(
                `wave.js: fable gate unmet for step ${row.step} and ` +
                `[escalation.fallback] names no usable variant. Refusing to route.`
            )
        }
    }

    if (never.includes(spec.model)) {
        variant = ((policy.escalation || {}).fallback || {})[variant]
        spec = variantSpec(policy, variant)
        if (!spec || never.includes(spec.model)) {
            throw new Error(
                `wave.js: no permitted model for step ${row.step} — fallback variant ` +
                `${JSON.stringify(variant)} is missing or also names a never-listed ` +
                `model. Refusing to route.`
            )
        }
    }

    return {
        hint: found.key, variant,
        model: spec.model, effort: spec.effort,
        model_requested: spec.model, effort_requested: spec.effort,
    }
}

const WRITE_HINTS = [
    'implement', 'fix',
    'prd-author', 'tdd-author', 'tdd-author-security',
    'adr-author', 'ux-spec-author',
    'spec-author-architecture', 'spec-author-security', 'spec-author-operations',
    'spec-author-performance', 'spec-author-code-quality',
    'spec-author-review-strategy', 'spec-author-testing',
]

function archetype(row, hint) {
    if (hint === 'research') return 'executor-research'
    if (row.class === 'write' || WRITE_HINTS.includes(hint)) return 'executor-write'
    return 'executor-read'
}

// SCRATCH HYGIENE: every
// file an executor writes lives in a private per-step directory <TMP>/<step>.d,
// mode 0700, built fresh at claim (rm -rf then mkdir -m 700) and removed by the
// executor the moment a record or fail exits 0. Before this, tokens (0600) and
// packets/claims (0644, world-readable) accumulated unbounded at the shared
// TMPDIR root — 911 stale tokens and 139 world-readable packets measured on one
// machine. Step ids are engine-minted and monotonic, so a fresh
// run cannot inherit stale files; the interrupted path (executor dies holding a
// claim) is swept by the conductor at reap — see conduct/SKILL.md, "A dead
// spawn is reaped, not waited out."
//
// Replay of a stale token is refused by the engine either way (verified
// read-only against docket.git: record/fail/heartbeat
// all authorize through authorizeLease(), which refuses when owner/token_hash
// are NULL; completion and reap NULL them (RetireStepTokenTx/ReapStepTx), and
// a re-claim mints a fresh token the old one cannot match). The dir sweep is
// defense against exposure and accumulation, not the revocation mechanism.
//
// HOW THIS BRIEF IS WORDED, and it is load-bearing: state the required form,
// omit the defense. A brief never addresses the safety classifier, names a
// technique by what it gets past, or pre-argues its own authorization — a
// self-justifying brief once cost an entire dispatch every executor spawn
// (three cycles, every spawn refused, zero steps claimed). Say what to do and
// what containment binds; a rule needs no argument for why it is allowed.
function bootstrap(row, r, isolated, isWrite) {
    // The TMPDIR pin paragraph appears once per brief — in bootstrap (a) for
    // isolated executors, in pinNote for everyone else. The two renderings
    // are deliberate near-mirrors of one rule; a wording change lands in
    // BOTH or the two executor classes drift apart on the same hazard.
    const isolationNote = isolated ? `

0. YOU ARE IN A PRIVATE WORKTREE, and your Bash calls may be guard-screened —
   every rule below binds you either way. The worktree protects your
   SIBLINGS from you — it does not change your own discipline: any probe
   that must modify files still runs on a COPY under <TMP>, never on this
   checkout (never reach for git restore/checkout --/reset/clean — probing
   on copies means never needing them). Never cd out to the shared
   repository tree. Command discipline, non-negotiable — every call you make
   must be obvious at a glance, exactly what it says and nothing more:

   - ONE action per Bash call: no \`&&\` chains, no \`$(...)\` substitution
     around git. Run every command PLAIN and SEPARATE.
   - Spell every redirect target as a LITERAL absolute path (shell variables
     do not survive between your calls — see the token protocol below).
   - Run git against YOUR OWN tree only — never \`git -C\`/\`--git-dir\` at
     another checkout, never cd-then-git elsewhere. Pipes are fine.

   RUN \`docket\` BARE — no DOCKET_PATH prefix; the store resolves from
   anywhere inside the repository, this worktree included.

   Bootstrap, one plain command at a time:

   a. \`printenv TMPDIR\` — your literal scratch root. Call it <TMP>;
      substitute its literal value wherever <TMP> or \`$TMPDIR\` appears in
      this brief. (Use \`printenv\`, not \`echo\` — no variable expansion
      anywhere in your calls.) PIN IT ONCE AND REUSE THE LITERAL: \`$TMPDIR\`
      is not guaranteed to resolve to the same root on a later call, so a
      path written as the variable can name one directory when you create it
      and a different one when you read it back.
   b. \`git worktree list --porcelain\` — every checkout's path and HEAD sha.
   c. Compare \`git rev-parse HEAD\` in your tree to the HEAD of the shared
      checkout from (b) — the one NOT under \`.claude/worktrees\`. If they
      differ, run \`git checkout --detach --quiet <that sha>\`. Config bases
      your worktree on the run's HEAD, so this is normally a no-op — verify,
      never assume.

   If any of these is DENIED by the guard or the permission system, say
   \`BOOTSTRAP DENIED\`, quote the denial verbatim, and STOP — that is an
   operator permission gap, not a repository-state problem. If a command
   fails on its own output instead, report that verbatim and STOP either way;
   do not hunt, do not guess, and NEVER claim after a failed bootstrap — an
   unclaimed step re-dispatches for free, a claimed one strands a token. Once
   (c) passes, your NEXT command is the claim in 1' — no exploratory docket
   verbs first (no --help, no step list/show, no run status/report, no next,
   nothing under dispatch). The brief and the packet carry everything a
   claim needs.

   TRANSLATION RULES — obligations 1 and 3 below print code blocks written
   for the shared tree; run their ISOLATED forms instead, everything else in
   their prose still binding:

   1'. Claim, as separate plain commands, literal paths throughout — the
       first two build your PRIVATE STEP SCRATCH DIR (obligation 1's
       rationale below explains it):
       \`rm -rf <TMP>/${row.step}.d\`
       \`mkdir -m 700 <TMP>/${row.step}.d\`
       \`docket step claim ${row.step} --owner wave:${row.step} --render --json > <TMP>/${row.step}.d/${row.step}.claim.json\`
       \`jq -r '.data.token' <TMP>/${row.step}.d/${row.step}.claim.json > <TMP>/${row.step}.d/${row.step}.token\`
       \`chmod 600 <TMP>/${row.step}.d/${row.step}.token\`
       \`jq -r '.data.packet' <TMP>/${row.step}.d/${row.step}.claim.json > <TMP>/${row.step}.d/${row.step}.packet.md\`
       \`cat /dev/null > <TMP>/${row.step}.d/${row.step}.claim.json\`
       Then open <TMP>/${row.step}.d/${row.step}.packet.md with the Read tool — the packet
       goes to a FILE here, not stdout, which also keeps a large brief from
       being truncated by the harness's inline-output cap.
       If the claim itself errors naming a packet file ("pinned by this run
       but is no longer on disk"), report the error verbatim and STOP — the
       ref came from a REPO-ADDITION config layer, repo-root-relative and
       absent from your worktree (shared-corpus refs resolve from any cwd);
       the claim already recorded and the token is gone, so a re-claim just
       burns another attempt — the relay's reap is the only way out.
   3'. Record with the token fed to stdin from its literal path:
       \`docket step record ${row.step} ... < <TMP>/${row.step}.d/${row.step}.token\`

   Uncommitted work in the shared tree is deliberately not visible, and
   your inputs arrive in the rendered packet, not from the tree.` : ''
    const pinNote = isolated ? '' : `

0. FIRST, before the claim: \`printenv TMPDIR\` — your literal scratch root.
   Call it <TMP>; substitute its literal value wherever <TMP> appears below.
   (Use \`printenv\`, not \`echo\`.) PIN IT ONCE AND REUSE THE LITERAL:
   \`$TMPDIR\` is not guaranteed to resolve to the same root on a later call,
   so a path written as the variable can name one directory when you create
   it and a different one when you read it back — and the claim token you
   park in obligation 1 depends on exactly that.`
    return `You are executing one step of a Docket run. Follow these obligations exactly.

YOUR ASSIGNMENT: step ${row.step} (issue ${row.issue}, run ${row.run}). This
brief was rendered for that step alone — every occurrence of ${row.step} below
is your real, already-substituted step id, NOT a template placeholder. ${row.step}
is the id you claim in obligation 1; a brief with an unfilled placeholder would
read STEP-N or \${row.step}, and this one does not.${isolationNote}${pinNote}

1. Claim it AND PARK THE TOKEN ON DISK${isolated ? ` — ISOLATED: run form 1' from
   obligation 0 (separate plain commands, literal paths) instead of the block
   below — the one-shot block violates your one-action-per-call discipline.
   Every rule after the block still binds you.` : ', in ONE Bash call, exactly this:'}

   \`\`\`
   rm -rf <TMP>/${row.step}.d &&
     mkdir -m 700 <TMP>/${row.step}.d &&
     docket step claim ${row.step} --owner wave:${row.step} --render --json > <TMP>/${row.step}.d/${row.step}.claim.json &&
     jq -r '.data.token'  < <TMP>/${row.step}.d/${row.step}.claim.json > <TMP>/${row.step}.d/${row.step}.token &&
     chmod 600 <TMP>/${row.step}.d/${row.step}.token &&
     jq -r '.data.packet' < <TMP>/${row.step}.d/${row.step}.claim.json &&
     cat /dev/null > <TMP>/${row.step}.d/${row.step}.claim.json
   \`\`\`

   The last command TRUNCATES the claim file rather than deleting it — its
   contents are spent the moment the packet above is printed. Same rule at
   step 3.

   Every path is spelled out because YOUR SCRATCH ROOT <TMP> IS SHARED BY
   EVERY EXECUTOR IN THE WAVE (concurrent subagents all get the same
   directory) and OUTLIVES the wave. That is why EVERYTHING you write goes
   inside <TMP>/${row.step}.d — your PRIVATE STEP SCRATCH DIR, mode 0700,
   built fresh by the rm/mkdir pair above (the \`rm -rf\` clears any stale
   leftover from a prior attempt; never skip it, and never aim it anywhere
   but that literal step-id path). Your step id is what makes the dir and
   these filenames yours; do not shorten them to \`claim.json\` or \`token\`,
   or a sibling's claim overwrites yours.

   THE TOKEN IS RETURNED EXACTLY ONCE, in that response body — re-claiming is
   refused while you hold the lease, so there is NO second chance to capture
   it. SHELL VARIABLES DO NOT SURVIVE BETWEEN BASH CALLS and step 2 takes
   many calls, so a variable is useless here — the file is the only channel
   that reaches step 3.

   WRITING THE TOKEN TO THIS FILE IS REQUIRED AND AUTHORIZED — it is the
   designed mechanism, not a leak. It is mode 0600 inside your own 0700 step
   scratch dir, you remove that dir the moment your record lands (obligation
   3), and the engine retires the token in the same instant. Do not skip the
   write to be cautious: skipping it strands the step, the worse outcome.

   The last command prints your rendered brief. Read it — it is your contract.

   IF THE HARNESS REPLIES \`<persisted-output> Output too large\`, WHAT YOU SEE
   INLINE IS NOT YOUR BRIEF — it is the first 2KB, and the cut lands inside
   the REQUEST section; everything that actually binds you (contract file,
   every fragment, PINNED, OUTPUT) sits BELOW it. Read the named file with
   the Read tool before doing anything else. A 30KB brief is the normal case
   for a step carrying several pinned files, not an anomaly.

   On CONFLICT: stop immediately and report AT MOST three lines: your step id,
   the word CONFLICT, and the engine's error line verbatim. Do not investigate
   the holder, the scopes, or the remedy — the conductor and the engine already
   know.

2. Execute the brief you were handed. It is your entire contract.${isWrite ? `
   Ship the issue's declared change list and NOTHING beyond it: unrequested
   hardening, extra controls, and adjacent cleanups go into gap files
   (obligation 3), never into the diff — reviewers reject what nobody asked
   for. The one exception: a defect you find that is actively exploitable is
   REPORTED in your return immediately, not merely gap-filed.` : ''}
${!isWrite ? `
2r. THE CHECKOUT YOU STAND IN MAY PREDATE THE CHANGE YOUR BRIEF DESCRIBES.
   Write-class siblings work in PRIVATE worktrees and hand work back as a
   COMMIT that nothing merges into this shared checkout, so HEAD here can be
   a round or more behind the change-summary and issue.diff your packet
   renders. Before reading ANY file by path to evaluate the change:

   - FIRST: if the packet's issue.diff is EMPTY and the change-summary
     records a gap-only outcome (no commit, no files changed), there is
     nothing to evaluate. Confirm that pair in ONE read-only pass and record
     immediately, naming which half was engine-computed (the empty
     issue.diff) vs self-reported (the summary); do NOT investigate
     repositories to re-prove a non-change, and do NOT file a duplicate gap —
     the upstream record already carries it.
   - Find the target sha — the change-summary's FIRST LINE carries it.
   - Reconstruct the target read-only, ALWAYS — do not first probe whether
     your checkout contains the change: integration cherry-picks, so the
     writer's sha is never an ancestor of the shared branch even after its
     content lands. TWO plain calls, and \`<TMP>\` is the LITERAL from
     bootstrap (a), never the words \`$TMPDIR\`:

       mkdir -p <TMP>/${row.step}.d/target
       git archive <sha> | tar -x -C <TMP>/${row.step}.d/target

     The \`mkdir\` is not optional: \`tar -x -C\` on a directory that does not
     exist fails \`could not chdir\` and extracts NOTHING. The literal is not
     optional either — the same \`$TMPDIR\` hazard the printenv note above
     records: extracting under one root and reading under another gets "no
     such file or directory" against a tree you just built, or worse falls
     back to reading the shared checkout: a judge reviewing a tree a round
     behind the change, exactly what this obligation prevents.

     The sha resolves even when no branch of yours carries it, because every
     worktree shares one object store. Read, build, and probe THERE, and
     attribute every result to that tree, never to this checkout.
   - If the sha does not resolve at all, that is a hard gap: record it as a
     gap file per obligation 3 instead of reviewing whatever the checkout
     happens to hold.
` : ''}${isolated && isWrite ? `
2b. COMMIT YOUR DELIVERABLE IN YOUR WORKTREE before step 3. Your edits live in
   this private worktree and NOTHING merges them back automatically — the
   commit is the hand-back channel: worktrees share the repository's object
   database, so once committed your sha is reachable from every checkout, and
   the conductor integrates it. Two SEPARATE plain calls, exactly this shape
   (no compounds, no global options before \`add\`/\`commit\`):

   git add -A
   git commit -m "type(scope): summary"

   The subject is a CONVENTIONAL COMMIT, whatever the repo's history does:
   type one of feat|fix|docs|refactor|test|perf|build|ci|chore, scope named
   for the area you touched, summary imperative plain language, 72 chars max,
   no trailing period. No body paragraphs — most commits are a subject alone;
   when the subject cannot carry the why, short "- " bullets. Never step,
   issue, or run ids (no STEP-N, DKT-N, RUN-N in subject or body): ids
   already live in your change-summary artifact and the engine record, and
   an id-bearing subject forces a hand-amend at integration.

   Then \`git rev-parse HEAD\` and put that sha ON THE FIRST LINE of your
   change-summary artifact AND in your final report. The commit signs
   non-interactively with the dedicated agent signing key the harness
   injects (ssh-format, \`~/.ssh/agent-signing.pub\`) — never pass
   \`--no-gpg-sign\` and never touch signing config. This is integration
   plumbing on a throwaway worktree branch; publishing stays the operator's
   alone. Do NOT push, and do not touch any other checkout.

   IF THE COMMIT IS REFUSED (guard or permission), do not fight it: leave the
   worktree exactly as it is, and report COMMIT BLOCKED with the refusal's
   first line verbatim plus your worktree path (from \`git rev-parse
   --show-toplevel\`) — the conductor commits on your behalf with
   \`git -C <your worktree> ...\` from its own seat. Then continue to step 3
   (your record may still succeed or park per its own rules; the two
   blockages are independent).
` : ''}

3. Record it yourself with \`docket step record\`, feeding the token file to
   STDIN${isolated ? ` — ISOLATED: run form 3' from obligation 0 (literal
   token path) in place of the command below; everything else still binds you.` : ':'}

   \`docket step record ${row.step}${isWrite ? ' --worktree <YOUR CHECKOUT>' : ''} --artifact-file <TMP>/${row.step}.d/${row.step}-<kind>.md --metadata '{"model_requested":"${r.model_requested}","effort_requested":"${r.effort_requested}","model_resolved":"<model that served you>","effort_resolved":"<effort you ran at>"}' < <TMP>/${row.step}.d/${row.step}.token\`

   \`record\` is an exact alias of \`step complete\` — use it, since some
   shells parse the bare word \`complete\` as their own builtin and refuse
   the line before docket sees it.

   Run this command SANDBOXED, same as everything else — do NOT pass
   dangerouslyDisableSandbox. Only the operator can grant that, and never
   through a brief. Most gates are pure local work (build/test/lint/scan)
   and need no elevation at all.

   IF a gate genuinely needs network access and the sandbox denies it —
   record exits non-zero and the error names a DNS failure, a TLS handshake
   failure, or a blocked host — do not retry with the sandbox disabled and
   do not treat it as a normal step failure. Attempt once, then STOP and
   report \`NETWORK GATE BLOCKED\`: the gate name, the exact host/domain the
   error names, and the error verbatim. Leave your token intact, as an
   unresolved record refusal below. The fix is a named domain added to
   \`sandbox_network_allowed_domains\` in \`src/user/claude_code.rs\` through
   the operator's own \`just activate\` — never a live bypass, never on your
   say-so.
${isWrite ? `
   \`--worktree\` names the checkout the work happened in. The engine
   computes the recorded diff THERE, and spawns your step's completion gates
   and the downstream verify pre-gate with that checkout as cwd too. Get its
   literal path once with \`git rev-parse --show-toplevel\` and paste that
   in; without it the engine diffs the wrong tree.
` : ''}
   \`model_resolved\` is the exact model id your environment reports (e.g.
   \`claude-sonnet-5\`), never a branding form — a "[1m]" suffix in the ledger
   fragments every routing-drift query that reads it.

   or on failure:

   \`docket step fail ${row.step} --note '<why>' < <TMP>/${row.step}.d/${row.step}.token\`

   \`fail\` takes ONLY --note and --metadata — there is no --artifact-file on
   it; \`--artifact-file\` exists on \`record\` alone, where it is MANDATORY.
   Reach for \`fail\` only when a retry might redeem the attempt.

   AN OUT-OF-SCOPE PROBLEM YOUR WORK SURFACED IS NEITHER A FAILURE NOR YOUR
   DECLARED ARTIFACT. Write each one to its own file and pass \`--gap-file
   <path>\` (repeatable) on the record: every gap file lands as a \`gap\`
   artifact beside your declared emit AND files a related backlog issue in
   the SAME transaction — no workflow declaration needed, that channel is
   always open. Your contract's Stuck clause is a SUCCESS recorded this way,
   never a \`fail\`.

   A gap file's FIRST LINE becomes the filed issue's TITLE: one line naming
   the defect itself. Its SECOND LINE is the home declaration, ALWAYS:
   \`Home: <repo/checkout>\` — the other repository when the problem lives
   elsewhere, or \`Home: THIS repository\` when it is local (gaps belong to
   their respective projects; the engine files yours HERE and the conductor
   re-homes it from your Home: line).
${isolated ? `
   IF THE RECORD IS REFUSED (guard or permission), attempt it ONCE and STOP
   TRYING FORMS. Leave your deliverables parked where the brief already has
   them —

     <TMP>/${row.step}.d/${row.step}.token       (intact, 0600 — do NOT truncate it)
     <TMP>/${row.step}.d/${row.step}-<kind>.md   (your artifact body)
     <TMP>/${row.step}.d/${row.step}-payload.json (your payload, when the contract has one)

   (the WHOLE step scratch dir stays intact; the conductor records from it
   on your behalf and sweeps it after)

   — and report RECORD BLOCKED: your step id, the refusal's first line
   verbatim, and every parked path including the token's. ONE refusal is an
   instruction, not a wall: "the lease has expired; claim it again to
   continue" means run the claim from 1' again for a FRESH token and record
   immediately — your finished work is still valid. Park and report only
   when the re-claim or the record refuses for any OTHER reason; the
   conductor is not isolated and records the step from your parked state.
   NEVER record \`fail\` for work that succeeded — a false failure burns an
   attempt and re-runs the whole step to relearn what your parked artifacts
   already hold.
` : ''}

   The CLI reads the token from DOCKET_TOKEN or, when that is unset, from
   stdin. NOTHING SETS DOCKET_TOKEN FOR YOU — a claim cannot export into
   your shell. Redirecting the file into stdin is the channel.

   Never \`cat\` the file, echo its contents, paste it into a command line, or
   reproduce it in your reply. There is deliberately no \`--token\` flag on any
   verb, because argv is world-readable through \`ps\`. Redirect it; never read it.

   After the record command exits 0, REMOVE YOUR STEP SCRATCH DIR in one
   plain call — \`rm -rf <TMP>/${row.step}.d\` — token, packet, and all. The
   engine retires the token the moment the record lands and copies your
   artifact, payload, and gap files into its store during the record itself,
   so nothing in the dir will ever be read again. The sweep is part of the
   record, not optional tidying — a leftover dir parks a spent credential
   and your full rendered brief in a scratch root later agents, runs, and
   sessions all share. The same sweep follows a \`fail\` that exits 0. If
   \`record\` or \`fail\` errored, KEEP the dir and its token file INTACT and
   stop — the token is the only thing that can still drive this step, and
   losing it after a failed record turns a routine step failure into a
   zombie claim the lease must reap.

   If the token file is missing or empty, or a record is refused for a missing
   or invalid token, say so plainly and stop. Do not reconstruct or guess it.

   EVERY record carries an artifact file. The engine refuses a record without
   \`--artifact-file\` before it validates anything else, so the file is
   never optional. Create it WITH BASH
   (a heredoc: \`cat > <TMP>/${row.step}.d/${row.step}-<kind>.md <<'EOF' ... EOF\`)
   as a FRESH file whose name starts with your step id, then pass that path as
   \`--artifact-file\`. NEVER create this file with the Write tool: under the
   sandbox it materializes files at a DIFFERENT physical path than the <TMP>
   root your Bash commands use, and the record then fails "no such file or
   directory" against a file you just wrote.

   ARTIFACT FILES: THREE AUTHORING RULES. A large or brace-heavy heredoc
   body fails in an isolated shell; author files these ways from the start
   and that failure never arises. Every form below writes ONLY to targets
   under your <TMP> or your own worktree — that containment is the rule
   itself.

   - SIZE: never write a large body in one heredoc. Write the file as an
     initial \`cat > <path> <<'EOF'\` of a few KB at most, followed by
     \`cat >> <path> <<'EOF'\` appends of the same size until done.
   - JSON: always \`jq -n\` (below) — never a JSON literal in any heredoc.
   - CODE EXCERPTS (Go signatures, config samples, anything brace- or
     bracket-heavy): let the excerpt travel as file bytes rather than as
     command text. Write it to its own scratch file in small chunks with the
     SIZE form above, then \`cat\` that file into place — or build the
     artifact with \`jq -n --rawfile body <TMP>/<step>.d/<step>-excerpt.txt\`.
     Do not hand-encode, escape, or otherwise transform the content itself.

   (There is no \`--artifact-kind\`: the workflow's
   \`emits\` declares the artifact's KIND — which your brief's OUTPUT section
   already names — it does not make the file optional. A structured payload,
   when your brief requires one, goes in \`--payload-file <path>\` — and you
   BUILD that JSON with \`jq -n\`, never as a JSON literal in a heredoc or
   command: an isolated shell's guard refuses any heredoc body carrying \`{\`
   immediately followed by \`"\` — which is every JSON object literal, so no
   formatting gets a literal past it. \`jq -n --arg id AC1 --arg status met
   '{id: $id, status: $status}' > "$path"\` is the honest shape: the command
   text carries only \`{id:\` (which the guard allows) and jq writes the real
   JSON to the file. Keys needing quotes go as \`{("kebab-key"): $v}\`;
   arrays as \`jq -n '[ ... ]'\` or by \`jq -s\` over per-element files.)
   Never write to or reuse a shared filename like \`change-summary.md\`:
   executors in one wave share the <TMP> root — write inside your private
   step dir so your bytes cannot collide, and under a shared name a racing
   sibling's bytes, or a predecessor's leftover, get recorded as YOUR
   artifact.

   If a write is refused, triage the refusal before anything else. One that
   names the body's SIZE OR CONTENT, on a target under <TMP> or your own
   worktree, means the three forms above are how to write it — use them.
   One that says the command is TOO COMPLEX TO VERIFY that it stays inside
   the worktree names the command's SHAPE, not its body: reissue the same
   work as single plain commands — ONE redirection or ONE heredoc each, no
   \`&&\`, no pipes, no \`;\`, no command substitution — and run them
   separately. Its closing line about git operations is boilerplate that
   fires on non-git commands too, so do NOT read it as a claim that you
   touched git. This is the same guard as the brace-then-quote rule above,
   refusing on a different axis. One that names ANYTHING ELSE — the target
   path, a permission, a policy concern — is a real BLOCKED condition on the
   spot, exactly like a refused record, and so is one that survives the
   three forms: report \`WRITE BLOCKED\`, the refusal's first line, and every
   path involved, then stop that path and record what you can. Never devise
   an encoding, a substitution, or a staged rewrite to get refused content
   through: content that will not go through in the plain forms is a
   BLOCKED report, always.

   Copy model_requested and effort_requested EXACTLY as written above — they are
   the harness's record of its own intent, not yours to adjust. Fill the two
   resolved values with what actually served you.

4. End your reply with exactly this line, filled in from the record
   response: <step-id> recorded (<status>) — for example "STEP-12 recorded
   (done)" or "STEP-12 recorded (waiting-human)". The wave parses this tail
   to stop launching later stages into a parked run; do not paraphrase it.`
}

let input = args
if (typeof input === 'string') {
    try {
        input = JSON.parse(input)
        log('wave.js: decoded args from the harness JSON-encoded transport (normal)')
    } catch (e) {
        throw new Error(
            `wave.js: args arrived as a STRING that is not valid JSON (${e.message}). ` +
            `Refusing to route.`
        )
    }
}
if (!input || typeof input !== 'object') throw new Error(
    `wave.js: args is ${typeof input}, expected {rows, policyText}. Refusing to route.`
)

const rows = input.rows || []

// A conductor no longer hand-copies policy.toml into policyText.
// It passes this sentinel instead; docket-policy-guard-hook.sh (PreToolUse)
// substitutes the canonical ~/.docket/config/policy.toml bytes via
// updatedInput before this script ever runs, so `input.policyText` should
// never actually BE the sentinel by the time it reaches here. If it is, the
// hook's substitution did not apply (harness quirk, missing tooling, or
// the hook fell through to fail-open on a construction error) — surface
// that plainly rather than let the TOML parser bail on an opaque 25-char
// string. This is defense-in-depth, not the primary mechanism: the guard
// substituting or denying is what actually enforces "the wave runs exactly
// the pinned policy bytes."
const POLICY_SENTINEL = '__USE_PINNED_POLICY__'
if ((input.policyText || '').trim() === POLICY_SENTINEL) {
    throw new Error(
        `wave.js: policyText arrived as the unresolved "${POLICY_SENTINEL}" sentinel — ` +
        `docket-policy-guard-hook.sh was supposed to substitute the canonical ` +
        `policy.toml bytes before this launch and did not. Do not retry with the ` +
        `sentinel and do not paste policy.toml text by hand as a workaround. Report ` +
        `this verbatim; the hook or its registration needs attention. Refusing to route.`
    )
}

const policy = parseToml(input.policyText || '')

const policyVersion = assertPolicyShape(policy, 'Refusing to route.')

if (policy.resolve) {
    throw new Error(
        'wave.js: policy.toml still carries [[resolve]] tables, but label-keyed ' +
        'hint resolution is retired — label routing lives in ' +
        'when-gated workflow steps declaring concrete executors, and silently ' +
        'ignoring a table would mis-route the very steps it named. Update the ' +
        'installed corpus (policy.toml + workflow files move together). ' +
        'Refusing to route.'
    )
}

// An agent's reply is PROSE. Read only the two shapes the brief actually
// mandates — never a substring of the body.
//
// Both park signals used to be `includes` over the whole reply, and one past
// run shows the cost: a judge reviewed the pause skill, quoted the engine
// constant it was reviewing — `CondRunActive = "run is not active"` — and
// recorded `done`. Its last line said so verbatim, `<step> recorded (done)`.
// The wave read the quote, declared the run parked, and never launched stage
// 2; the engine re-offered synthesize one full dispatch round-trip later. A
// reviewer of park handling cannot describe a park without tripping a body
// scan, and this corpus reviews its own park handling constantly.
// TEST-BEGIN park-signals — extracted and exercised by
// tests/wave-park-signals.test.sh against verbatim replies captured from that
// run. Keep everything between the markers free of workflow globals (agent,
// log, args) so it stays evaluable on its own.
const CONFLICT_REPORT_MAX_LINES = 4

function lastLine(text) {
    const lines = String(text).trim().split('\n').filter((l) => l.trim())
    return lines.length ? lines[lines.length - 1].trim() : ''
}

// Obligation 1's CONFLICT clause mandates AT MOST three lines: the step id,
// the word CONFLICT, and the engine's error verbatim (one line of slack for a
// wrapper). Longer than that and the word is a FINDING about conflicts, not a
// conflict — the same confusion, one field over.
function isConflictReport(text) {
    if (typeof text !== 'string' || !text.includes('CONFLICT')) return false
    return text.trim().split('\n').filter((l) => l.trim()).length
        <= CONFLICT_REPORT_MAX_LINES
}

// Two park signals, both in-band: the claim-CONFLICT report of an agent that
// launched INTO a park ('run is not active'), and the record-status tail of
// the agent whose own record CAUSED the park ('STEP-N recorded
// (waiting-human)') — the second stops the next stage before it spawns
// corpses (measured twice on one run: 5 judges launched into a park the
// prior stage's result already announced). The tail format is mandated by the
// brief's closing instruction below, which says to END the reply with it, so
// it is read at the END and nowhere else; trailing emphasis or punctuation is
// tolerated, a paragraph after it is not. Fail-open: no match keeps launching,
// and the engine refuses a claim into a parked run anyway.
function runParked(res) {
    if (res == null || res.status !== 'returned' ||
        typeof res.text !== 'string') return false
    if (/recorded \((?:waiting-human|paused)\)[\s*_`.]*$/.test(lastLine(res.text))) return true
    return isConflictReport(res.text) && res.text.includes('run is not active')
}
// TEST-END park-signals

// ---------------------------------------------------------------------------
// ORPHANED CLAIM. One claim refusal inverts its own meaning when
// relayed at face value: `not ready to claim: the step is not pending` reads
// as "never started" but actually means ALREADY CLAIMED — routinely by a
// PREDECESSOR OF THE VERY AGENT that just reported it.
//
// RUN-61 DISPATCH-332 is the fixture: the operator interrupted
// the fix@1 executor mid-step, harness resume relaunched the identical agent
// spec (none of wave.js's own retry paths fired — resume is invisible from
// inside this script), the relaunched agent's claim was refused with that
// sentence, and the wave reported it as STEP-2760's outcome before
// chain-killing nine downstream rows. The truth was the opposite — claimed,
// holder dead, reap needed — and the conductor had to reconstruct it from
// the journal.
//
// THE CAVEAT: on a harness resume an interrupted executor's brief re-executes
// with IDENTICAL BYTES, and the docket claim is the only thing standing
// between that and silent duplicate work — but only for WRITE-class work,
// which claims. A READ-class brief that never claims re-runs INVISIBLY, so
// this branch diagnoses the write-class case alone.
//
// The remedy is REPORT-ONLY: the chain-kill is correct either way (nothing
// downstream of an unrecorded step becomes claimable this wave), preserved
// via the explicit `claim-conflict` status in chainDead(), independent of
// isConflictReport()'s line budget.
// TEST-BEGIN orphaned-claim — extracted and exercised by
// tests/wave-orphaned-claim.test.sh, which concatenates the park-signals
// region ahead of it (isConflictReport) and the chain-dead region after it.
// Keep everything between the markers free of workflow globals (agent, probe,
// log, args) so it stays evaluable on its own.
const CLAIM_CONFLICT_STATUS = 'claim-conflict'
const NOT_PENDING_CONFLICT = /not ready to claim:\s*the step is not pending/i

// Same domain rule as every other predicate here: a CONFLICT REPORT, which
// obligation 1 caps at three lines, never an arbitrary agent reply. A judge
// writing ABOUT this conflict fails the line budget and is left alone. The
// park signal wins the tie: 'run is not active' is a run-wide park that
// runParked() must still see on a `returned` result, so it is never enriched
// into a status of its own here.
function isOrphanedClaimConflict(text) {
    if (!isConflictReport(text)) return false
    if (text.includes('run is not active')) return false
    return NOT_PENDING_CONFLICT.test(text)
}

// `docket step show STEP-N --json` read the way the rest of this file reads
// engine JSON: named fields, matched wherever they sit in the envelope, each
// one independently OPTIONAL. Absence is normal (a lease block is absent on an
// unclaimed step; `failed_attempts`/`reaped_claims` are omitted at 0), and
// nothing here is asserted that the text did not actually carry.
function parseStepShow(show) {
    const s = typeof show === 'string' ? show : ''
    const grab = (key, val) => {
        const m = s.match(new RegExp(`"${key}"\\s*:\\s*${val}`))
        return m ? m[1] : ''
    }
    return {
        status: grab('status', '"([a-z-]+)"'),
        attempt: grab('attempt', '(\\d+)'),
        owner: grab('owner', '"([^"]*)"'),
        live: grab('live', '(true|false)'),
        failed: grab('failed_attempts', '(\\d+)'),
        reaped: grab('reaped_claims', '(\\d+)'),
    }
}

// A step whose row is HELD by a claim — the orphan case.
const CLAIM_HELD = ['claimed', 'running']
// A step that already recorded. The refusal then means this spawn arrived
// after the fact, which is the opposite diagnosis and needs no reap.
const ALREADY_RECORDED = ['done', 'superseded', 'skipped', 'failed']

// Build the step's real state as the outcome, in place of the raw refusal.
// Returns null when the probe text carries no status at all — the caller then
// relays the CONFLICT exactly as before, so a dead or empty probe degrades to
// precisely the old behavior.
function orphanedClaimReport(step, conflict, show) {
    const st = parseStepShow(show)
    if (!st.status) return null
    const at = st.attempt !== '' ? ` at attempt ${st.attempt}` : ''
    const facts = [
        `status=${st.status}`,
        st.attempt !== '' ? `attempt=${st.attempt}` : '',
        st.owner ? `owner=${JSON.stringify(st.owner)}` : '',
        st.live !== '' ? `lease live=${st.live}` : '',
        st.failed !== '' ? `failed_attempts=${st.failed}` : '',
        st.reaped !== '' ? `reaped_claims=${st.reaped}` : '',
    ].filter(Boolean).join(', ')

    let headline, reading
    if (CLAIM_HELD.includes(st.status)) {
        headline = `claimed${at}, holder returned nothing: likely orphaned ` +
            `claim, reap needed`
        reading = `The step is CLAIMED, not unstarted. The agent this wave ` +
            `launched for ${step} was refused that claim and recorded ` +
            `nothing, so the lease is held by something other than the agent ` +
            `that just ran — the standing case is an executor interrupted ` +
            `mid-step whose claim outlived it (the harness relaunches the ` +
            `identical brief on resume; the claim is what stops the duplicate ` +
            `from doing the work twice). ESTABLISH the holder is gone, then ` +
            `return the step to the pool: \`docket step reap ${step} ` +
            `--reason '<what you observed>'\` (token-free). Do NOT read this ` +
            `outcome as "the step never started".`
    } else if (ALREADY_RECORDED.includes(st.status)) {
        headline = `already ${st.status}${at}: the spawn arrived after the ` +
            `fact, no reap needed`
        reading = `The step already RECORDED (${st.status}). The refusal ` +
            `means this spawn arrived after the work landed, not that the ` +
            `step never started; nothing holds a lease, so there is nothing ` +
            `to reap.`
    } else {
        headline = `refused as "not pending" while \`step show\` reads ` +
            `${st.status}${at}`
        reading = `The refusal and the step's own row disagree — the claim ` +
            `was refused as "not pending" while \`step show\` reads ` +
            `${st.status}. Reconcile before any retry (\`docket dispatch ` +
            `verify\`, \`docket step show ${step}\`); this is not evidence ` +
            `that the step never started.`
    }

    return {
        step,
        status: CLAIM_CONFLICT_STATUS,
        headline,
        step_status: st.status,
        text: [
            `${step} CLAIM CONFLICT — ${headline}.`,
            `docket step show ${step}: ${facts}`,
            reading,
            `Engine refusal, verbatim:`,
            conflict,
        ].join('\n'),
    }
}
// TEST-END orphaned-claim

// The safety classifier runs PRE-SPAWN and fails CLOSED: when its stage-2
// check errors out, it blocks the launch and says so in its own reason text.
// One past run lost 3 of 24 executor spawns to the SAME error, verbatim,
// across three different issues/classes/models — infra, not content, since
// all three later recorded `done` on redispatch from the identical brief
// bytes, direct proof that resubmission succeeds.
//
// So the retry is gated on the classifier's own transient admission alone,
// and it resubmits the SAME BYTES — same brief, same opts. A REWORDED
// resubmission is the one thing never to do: to the classifier it reads as
// an obfuscated retry of blocked content. A content-based block (any reason
// without this signature) is a real refusal, deterministic on identical
// bytes anyway, and stays operator-escalated on the first failure.
//
// TEST-BEGIN classifier-retry — extracted and exercised by
// tests/wave-classifier-retry.test.sh against the verbatim reason text
// captured from that run. Keep everything between the markers free of
// workflow globals (agent, log, args) so it stays evaluable on its own.
//
// Both regexes must hit. CLASSIFIER_BLOCK is the harness's own wrapper —
// `[${label}] blocked by safety classifier: ${reason}` — which keeps the
// predicate off every other spawn error; TRANSIENT_CLASSIFIER is the
// classifier's admission that its own stage 2 broke. A content-based reason
// names the content, never its own machinery, so it matches neither phrase.
// Domain is BLOCK-REASON AND ERROR STRINGS ONLY, never an agent reply — the
// park-signal lesson one field over: a judge reviewing this retry will quote
// these sentences, and a body scan would misread the quote as the real thing.
const CLASSIFIER_BLOCK = /blocked by safety classifier/i
const TRANSIENT_CLASSIFIER = /Stage 2 classifier error|usually transient/i

function reasonText(e) {
    if (typeof e === 'string') return e
    if (e && typeof e === 'object') {
        if (typeof e.error === 'string') return e.error
        if (typeof e.message === 'string') return e.message
    }
    return ''
}

function transientClassifierBlock(e) {
    const s = reasonText(e)
    return CLASSIFIER_BLOCK.test(s) && TRANSIENT_CLASSIFIER.test(s)
}
// TEST-END classifier-retry

// A pre-spawn classifier block resolves agent() to a BARE null: the reason
// goes only to the harness's progress stream, which this script cannot read.
// The harness PERSISTS that stream as JSON at
// ~/.claude/projects/<flattened-cwd>/<session-id>/[subagents/]workflows/<wfId>.json,
// each workflowProgress entry carrying `label`, `blocked`, and the verbatim
// `error` — a read-only probe agent CAN read that file, so the null branch
// recovers the reason out-of-band instead of guessing. Killed waves persist
// partial progress, so the file is not completion-only; whether every
// mid-run block is flushed by the time the probe looks is UNVERIFIED — if
// not, the probe finds nothing and the branch degrades to its old
// conservative behavior.
const PROBE_SCHEMA = {
    type: 'object',
    properties: {
        found: { type: 'boolean' },
        label: { type: 'string' },
        blocked: { type: 'boolean' },
        state: { type: 'string' },
        error: { type: 'string' },
        file: { type: 'string' },
    },
    required: ['found'],
    additionalProperties: false,
}

function blockProbeBrief(label) {
    return [
        'You are a DIAGNOSTIC PROBE inside a running Docket wave (wave.js). A',
        'step\'s agent launch just resolved to null — blocked by the pre-spawn',
        'safety classifier, skipped by the operator, an unavailable model, or a',
        'mid-flight death. The harness records which, but only in its own wave',
        'state file, unreadable to the workflow script. Your ONLY job is to',
        'recover that record VERBATIM so the wave can tell a transient infra',
        'block (sanctioned to resubmit the IDENTICAL brief once) from everything',
        'else (operator-escalated). Change nothing, rephrase nothing.',
        '',
        'WAVE PROBE: not a step execution. Your usage is wave overhead — the',
        'label below names the step you are READING ABOUT, and the usage join',
        'must not attribute your tokens to it.',
        '',
        `TARGET LABEL (match byte-for-byte): ${label}`,
        '',
        'WHERE: the harness persists each workflow run as JSON at',
        '  ~/.claude/projects/*/workflows/wf_*.json',
        '  ~/.claude/projects/*/subagents/workflows/wf_*.json',
        '(one session-id directory between the project dir and',
        '`workflows`/`subagents`). Each file has a top-level `status` and a',
        '`workflowProgress` array whose entries carry `label`, `state`,',
        '`blocked`, and `error`.',
        '',
        'HOW — parse the JSON (python3 or jq); never raw-grep, since other',
        'fields such as promptPreview quote labels too:',
        '1. Consider only files modified within the last 12 hours whose',
        '   top-level status is NOT "completed", "failed", or "killed" — a',
        '   terminal-status file is some OTHER, older run of the same step.',
        '2. Find workflowProgress entries whose `label` field equals the',
        '   target EXACTLY. Ignore your own entry (label ends "block-probe")',
        '   and NEVER read agent-*.jsonl transcripts — agents quote classifier',
        '   text in prose, out of domain.',
        '3. If exactly one live-wave entry matches, report its fields',
        '   verbatim. If none match, more than one candidate remains, or',
        '   anything is ambiguous, report found: false — never a guess.',
        '',
        'Return via the structured output: found (exactly one match in a live',
        'wave), label (verbatim), blocked, state, error (byte-for-byte, never',
        'trimmed/rewrapped/paraphrased), file (the path you read it from).',
    ].join('\n')
}

// TEST-BEGIN null-probe — extracted and exercised by
// tests/wave-classifier-retry.test.sh. Keep everything between the markers
// free of workflow globals (agent, log, args) so it stays evaluable alone.
//
// The probe returns a structured CLAIM about this step's progress entry.
// Trust none of it structurally: a recovered reason is usable only when the
// probe found a live-wave entry, the entry is a pre-spawn BLOCK
// (blocked === true — an operator skip or mid-flight death is never
// blocked), the label echoes this step's label byte-for-byte (so a sloppy
// probe cannot hand back some other step's block), and the reason is a
// non-empty string. Anything less returns null and the null branch stays
// exactly as conservative as before the probe existed. The returned reason
// still has to pass transientClassifierBlock() at the call site — this
// function decides provenance, not transience.
function probeRecovered(p, label) {
    if (!p || p.found !== true || p.blocked !== true) return null
    if (p.label !== label) return null
    return typeof p.error === 'string' && p.error !== '' ? p.error : null
}
// TEST-END null-probe

function spawn(row, phaseLabel) {
    const r = resolve(row, policy)
    const type = archetype(row, r.hint)
    // Only writers get a worktree, so parallel WRITERS cannot cross-
    // contaminate the shared tree (read-class steps never mutate it). The
    // harness guard that polices an isolated shell also refuses any heredoc
    // body carrying `{` immediately followed by `"` — every JSON object
    // literal — so isolating readers taxed exactly the steps whose payloads
    // are JSON (89 refusals across 21 agents in 6 waves).
    const isWrite = type === 'executor-write'
    const isolated = isWrite
    log(`${row.step}: ${r.hint} -> ${type} @ ${r.model}/${r.effort} (variant ${r.variant})` +
        ` [${labelsOf(row).join(' ') || 'no labels'}]` +
        (isolated ? ' [worktree]' : ''))
    const stepLabel = `${row.step} · ${r.hint}`
    const opts = (iso) => ({
        label: stepLabel,
        phase: phaseLabel,
        agentType: type,
        model: r.model,
        effort: r.effort,
        ...(iso ? { isolation: 'worktree' } : {}),
    })
    const failed = () => ({ step: row.step, status: 'spawn-failed', text: null })
    const escalate = () => {
        log(`${row.step}: SPAWN PRODUCED NOTHING (launch blocked before the ` +
            `agent existed — this wave's task .output workflowProgress[].error ` +
            `carries the stated reason when there is one — or model ${r.model} ` +
            `unavailable, the agent was skipped, or it died mid-flight) — whether a claim ` +
            `was recorded is UNKNOWN; reconcile via \`docket dispatch verify\` ` +
            `and \`docket step show ${row.step}\`, then, if it is still claimed ` +
            `by this dead spawn, return it to the pool with \`docket step reap ` +
            `${row.step} --reason '<what you observed>'\` (token-free) before ` +
            `any retry. If that error carries the TRANSIENT classifier ` +
            `signature (\`Stage 2 classifier error\` / \`usually transient\`), ` +
            `redispatch the step UNCHANGED — same brief, never reworded`)
        return failed()
    }
    const handle = (text, retried) => {
        if (text != null) {
            const returned = { step: row.step, status: 'returned', text }
            // The ONE refusal whose face value inverts the truth.
            // "not ready to claim: the step is not pending" reads as "never
            // started" and means "already claimed" — ask the engine what the
            // step's row actually says and report THAT, refusal kept verbatim
            // underneath. See the ORPHANED CLAIM note above for the caveat
            // this cannot see: a read-class brief re-runs invisibly on
            // harness resume, since only a claim refuses the duplicate.
            if (!isOrphanedClaimConflict(text)) return returned
            log(`${row.step}: claim refused "the step is not pending" — probing ` +
                `the step's real state rather than relaying the refusal as the ` +
                `outcome`)
            return probe(`docket step show ${row.step} --json`,
                `${row.step} · claim-conflict`, phaseLabel, row.step)
                .then((show) => {
                    const diagnosed = orphanedClaimReport(row.step, text, show)
                    if (!diagnosed) {
                        log(`${row.step}: the claim-conflict probe read no status ` +
                            `— relaying the refusal verbatim, exactly as before`)
                        return returned
                    }
                    log(`${row.step}: ${diagnosed.headline}`)
                    return diagnosed
                }, () => returned)
        }
        // A bare null is still NEVER retried blind: agent() resolves to
        // `null` for a pre-spawn classifier block, an operator SKIP, an
        // unavailable model, and a mid-flight death alike, and the reason
        // string goes only onto the progress stream (workflowProgress[].error)
        // which this script cannot read. A blind retry here would relaunch
        // agents the operator had just skipped. Instead, a read-only probe
        // recovers the harness's own persisted record of THIS label, and the
        // identical-bytes resubmission fires only on a probe-recovered,
        // label-matched, blocked === true entry whose reason carries the
        // transient signature. Every other outcome escalates exactly as
        // before the probe existed. The probe deliberately inherits the
        // session model (no model override below): nulls are rare, and a
        // wrong extraction here is the one thing that could relaunch an
        // agent the operator skipped. A null probe result is a found-nothing.
        if (retried) return escalate()
        return agent(blockProbeBrief(stepLabel), {
            label: `${row.step} · block-probe`,
            phase: phaseLabel,
            agentType: 'executor-read',
            effort: 'low',
            schema: PROBE_SCHEMA,
        }).then((p) => probeRecovered(p, stepLabel), () => null)
            .then((reason) => {
                if (reason && transientClassifierBlock(reason)) {
                    log(`${row.step}: probe recovered the harness's block record and ` +
                        `it admits its own transience (${reason}) — resubmitting the ` +
                        `IDENTICAL brief once (never reworded); a second null is ` +
                        `spawn-failed`)
                    return launch(isolated, true).catch((err2) => {
                        log(`${row.step}: spawn error on transient-classifier retry: ${err2}`)
                        return failed()
                    })
                }
                if (reason) {
                    log(`${row.step}: probe recovered a NON-transient classifier block ` +
                        `(${reason}) — a content refusal stays operator-escalated, and ` +
                        `identical bytes would be refused deterministically anyway`)
                } else {
                    log(`${row.step}: probe could not attribute the null to a ` +
                        `classifier block — leaving it operator-escalated`)
                }
                return escalate()
            })
    }
    const launch = (iso, retried) =>
        agent(bootstrap(row, r, iso, isWrite), opts(iso)).then((text) => handle(text, retried))
    // EXACTLY ONCE, and only from the top-level catch: same brief bytes, same
    // opts, same isolation. `retried` rides through so a retry that resolves
    // null does not probe-and-retry again. A second failure returns
    // 'spawn-failed' exactly as an unretried one does.
    const retryTransient = (err, iso) => {
        log(`${row.step}: safety-classifier block admits its own transience ` +
            `(${err}) — resubmitting the IDENTICAL brief once (never reworded); ` +
            `a second failure is spawn-failed`)
        return launch(iso, true).catch((err2) => {
            log(`${row.step}: spawn error on transient-classifier retry: ${err2}`)
            return failed()
        })
    }
    return launch(isolated)
        .catch((err) => {
            if (transientClassifierBlock(err)) return retryTransient(err, isolated)
            if (isolated && /base branch|worktree/i.test(String(err))) {
                log(`${row.step}: worktree isolation unavailable (${err}) — retrying ` +
                    `WITHOUT isolation; cross-contamination guard is OFF for this spawn`)
                return launch(false)
                    .catch((err2) => {
                        log(`${row.step}: spawn error on non-isolated retry: ${err2}`)
                        return failed()
                    })
            }
            log(`${row.step}: spawn error: ${err}`)
            return failed()
        })
}

// ---------------------------------------------------------------------------
// Vote rows: the in-wave panel. A `kind:"vote"` row rides the manifest —
// ready, or STAGED behind the work it judges — and the wave seats the panel
// itself: it cannot nest tribunal.js (workflow nesting is one level, and the
// wave IS the child), so the seat contract lives here too, adapted from
// tribunal.js. The engine remains the only authority: `step record` on the
// gate's last predecessor opens the proposal, each seat casts a REAL
// `docket vote cast`, the engine tallies, and the quorum-reaching cast routes
// the gate. This script never casts, approves, or tallies.
//
// Seat routing mirrors tribunal.js's resolveSeat: no attempt chain, no fable
// gates (a seat's variant is its standing home); the [security] node pins
// still bind, and — unlike tribunal.js, whose caller has no issue to read
// labels from — this call site passes the row's issue labels, so
// [security].labels also binds here.
// ---------------------------------------------------------------------------

// SYNC-BEGIN seat-contract
function resolveSeat(seat, policy, labels = []) {
    const row = (policy.executors || {})[seat]
    if (!row) {
        throw new Error(
            `wave.js: seat ${JSON.stringify(seat)} has no [executors] row. ` +
            `Every voter named by a vote gate must be routable — policy.toml and ` +
            `the workflow corpus have drifted. Refusing to seat the panel.`
        )
    }

    let variant = row.variant
    let never = (row.never || []).slice()

    const sec = policy.security || {}
    const sensitive =
        (sec.nodes || []).includes(seat) ||
        (sec.labels || []).some((l) => labels.includes(l))
    if (sensitive) {
        never = never.concat(sec.never || [])
        if (sec.ceiling) {
            const beyond = new Set()
            let c = (policy.variants || {})[sec.ceiling]
            if (!c) {
                throw new Error(
                    `wave.js: [security].ceiling ${JSON.stringify(sec.ceiling)} ` +
                    `has no [variants] row — a mistyped ceiling would silently stop ` +
                    `binding. Fix policy.toml. Refusing to seat the panel.`
                )
            }
            while (c && c.escalate_to && !beyond.has(c.escalate_to)) {
                beyond.add(c.escalate_to)
                c = (policy.variants || {})[c.escalate_to]
            }
            if (beyond.has(variant)) variant = sec.ceiling
        }
    }

    let spec = (policy.variants || {})[variant]
    if (!spec) {
        throw new Error(
            `wave.js: seat ${JSON.stringify(seat)} names variant ${JSON.stringify(variant)}, ` +
            `which has no [variants] row. Refusing to seat the panel.`
        )
    }

    if (never.includes(spec.model)) {
        const fallback = (policy.escalation || {}).fallback || {}
        variant = fallback[variant]
        spec = (policy.variants || {})[variant]
        if (!spec || never.includes(spec.model)) {
            throw new Error(
                `wave.js: no permitted model for seat ${JSON.stringify(seat)} — ` +
                `fallback variant ${JSON.stringify(variant)} is missing or also names a ` +
                `never-listed model. Refusing to seat the panel.`
            )
        }
    }

    return { seat, variant, model: spec.model, effort: spec.effort }
}

// A seat's lens is its trailing name segment (`tribunal-security` -> security);
// an unrecognised seat gets the whole-system lens below rather than a throw, so
// a generically-briefed judge still decides instead of leaving the gate
// undecidable.
//
// A lens is the seat's VOTER brief only — the same trailing names also exist as
// review-executor contracts (contracts/judge-<name>.md) governing the seat when
// a workflow fans it out as a reviewer: one name, two remits, resolved by row
// kind. architecture and security broadly agree across the two; correctness
// deliberately does not, since the contract hunts logic defects while this lens
// interrogates the evidence behind the gate's ask (the contract
// carries the mirror note).
//
// Only lenses reachable from a current workflow's voter names are kept
// (architecture, security, correctness, design); a seat re-adding a retired one
// (completeness, feasibility, risk) must re-add its lens or it falls to the
// whole-system brief below.
const LENSES = {
    architecture:
        'DESIGN, COUPLING, AND PRECEDENT. Does this fit the shape of the system it ' +
        'lands in, or does it bolt a second way of doing something onto a first? What ' +
        'does it couple that was separate, and what does it make harder to change ' +
        'next? What precedent does accepting it set for the next twenty things like it?',
    security:
        'TRUST BOUNDARIES, PROVENANCE, AND BLAST RADIUS. What boundary does this move ' +
        'data or execution across, and who is trusted after it that was not before? ' +
        'Where did the inputs come from and can that provenance be checked? If this is ' +
        'wrong, how far does the damage reach and how would anyone notice?',
    correctness:
        'EVIDENCE, REPRODUCIBILITY, AND VERIFICATION. What is actually demonstrated ' +
        'here versus asserted? Was the claimed behaviour reproduced, and could you ' +
        'reproduce it from what is in front of you? What would have to be true for this ' +
        'to be wrong, and does anything check that?',
    design:
        'USER-FACING SHAPE AND COHERENCE. Does what a person sees and does here hold ' +
        'together — flows that complete, states that are all accounted for, names that ' +
        'mean what they say? Where does the design contradict itself or the system it ' +
        'joins, and what would a first-time user get wrong because of it?',
}
const WHOLE_SYSTEM_LENS =
    'WHOLE-SYSTEM REVIEW. No narrower lens is declared for your seat, so read this ' +
    'as a generalist: design fit, trust and blast radius, and the quality of the ' +
    'evidence behind every claim.'

function lensOf(seat) {
    const parts = seat.split('-')
    const key = parts[parts.length - 1]
    return { role: key, text: LENSES[key] || WHOLE_SYSTEM_LENS }
}
// SYNC-END seat-contract

// TEST-BEGIN seat-brief — extracted and exercised by
// tests/wave-target-envelope.test.sh, which stubs `lensOf` (the only global
// this reaches for) and asserts what a target ref does and does not put in
// front of a judge. Keep every other dependency inside the markers.
function seatBrief(r, voteId, row, isRespawn, heldCluster, target) {
    const { role, text } = lensOf(r.seat)
    const metadataClaim = JSON.stringify({
        seat: r.seat,
        variant: r.variant,
        model: r.model,
        effort: r.effort,
    })
    const respawnNote = isRespawn ? `

THIS IS A SECOND ATTEMPT AT YOUR SEAT. A prior agent held it and returned
without a recorded cast — \`docket vote show ${voteId}\` shows no entry for
${r.seat}. Nothing it may have concluded reached anyone, so decide the case
yourself from scratch. Whatever stopped the first attempt, the cast is the one
thing that must happen this time: if the command errors, do not abandon it
silently — end with the verbatim error as instructed below.` : ''
    // Absent on ordinary gates — then this renders NOTHING and the
    // brief is byte-for-byte what it was before held clusters existed.
    const heldClusterNote = heldCluster ? `

HELD CLUSTER: you decide ONE finding cluster — index ${heldCluster.clusterIndex} of
${heldCluster.clusterCount} in ${heldCluster.artifact} (produced by ${heldCluster.producerStep}). Read it with
\`docket step artifact ${heldCluster.artifact} --payload\` and judge that cluster
only: is the held remedy right, and should it block? The other clusters are
other seats' or already decided.` : ''
    // Seats used to vote on a tree their own checkout did not contain — one
    // judge reported that the fix commit was not an ancestor of the judge
    // worktree's own HEAD, and rejected on evidence grounds, because the
    // correctness lens asks whether you could reproduce it FROM WHAT IS IN
    // FRONT OF YOU — no code edit answers that reject, since the fix loop
    // cannot move a judge's HEAD. The engine lifts the resolved `issue.diff`
    // round record onto the context bundle as `target_sha`/`target_worktree`,
    // so NAME the round's target here. Either half may be missing — a bundle
    // carries both or neither per the engine, but a swept worktree or an
    // older manifest can leave one — and with NEITHER this says so in as many
    // words rather than staying silent (below).
    //
    // THE LAST NET BEFORE A SHA REACHES A JUDGE (DOT-1040). A `TARGET SHA:`
    // line is an assertion three opus seats will spend calls chasing, so it
    // is written only for a sha that is SHAPED like one — 40 lowercase hex,
    // the full object id the engine records, never an abbreviation and never
    // prose. RUN-63 relayed a fabricated 40-hex sha that existed in no
    // repository and briefed three judges with it; the call site
    // (corroboratedTarget) additionally requires the sha to occur in text the
    // wave read for itself, and this shape check stands behind that so no
    // other caller of seatBrief can route around it.
    const rawTargetSha = (target && target.sha) || ''
    const targetSha = /^[0-9a-f]{40}$/.test(rawTargetSha) ? rawTargetSha : ''
    const targetWorktree = (target && target.worktree) || ''
    const targetLines = []
    if (targetSha) {
        targetLines.push(`TARGET SHA:     ${targetSha} — the commit the diff under this gate stood at`)
    }
    if (targetWorktree) {
        targetLines.push(`TARGET WORKTREE:${targetWorktree} — the checkout that recorded it, while it is still on disk`)
    }
    const targetReads = [
        targetSha ? `  git cat-file -t ${targetSha}   — proves the object is here at all` : '',
        targetSha ? `  git show --stat ${targetSha}   then \`git show ${targetSha}\` for the body` : '',
        targetSha ? `  git diff ${targetSha}^ ${targetSha} -- <path>` : '',
        targetWorktree ? `  git -C ${targetWorktree} log --oneline -5` : '',
    ].filter(Boolean).join('\n')
    const targetNote = (targetSha || targetWorktree) ? `
${targetLines.join('\n')}

THAT IS THE STATE UNDER VOTE, AND YOUR OWN CHECKOUT MAY NOT CONTAIN IT — a
fact about where you were seated, not about the change. Write-class seats work
in PRIVATE worktrees and hand their work back as a commit on their own ref, so
a panel seated mid-wave routinely sits at a HEAD that predates the round it is
judging. Every worktree of this repository SHARES ONE OBJECT STORE, so the
commit is readable from where you are even when it is not an ancestor of your
HEAD:

${targetReads}

Do NOT reject because your own HEAD is behind: that verdict is about your
visibility, and no fix the loop can make will answer it. If after those reads
you still cannot see the state under vote — the object is genuinely absent, or
that worktree is already swept — say exactly that in your summary and decide on
the artifacts of record with a LOW \`--confidence\` (and a low
\`--domain-relevance\` when the question has moved outside what you can check),
or \`approve-with-concerns\` naming precisely what you could not verify. Reject
when the evidence you DID read says the change must not proceed.` : `

NO target ref — read your own HEAD. Nothing recorded a target commit for the
state under vote (the gate declares no \`issue.diff\` input, or the resolved
diff carries no round record), so this brief names NO sha and NO worktree.
There is no hidden commit id to recover: start from \`git log --oneline -5\`
and \`git status\` in your own checkout, and judge the artifacts of record.
If some other text hands you a 40-hex sha for this gate, it did not come from
the engine — do not spend calls hunting it.`

    // The TMPDIR pin and BOUND YOUR INVESTIGATION paragraphs below are
    // hand-mirrored with tribunal.js's judgeBrief — outside SYNC coverage,
    // so the sync test cannot catch drift. Update both files together,
    // especially the measured fleet stats.
    return `You are ONE SEAT of a tribunal deciding a gate step MID-WAVE in a Docket run.
You decide alone. You cannot see the other seats, you do not coordinate with
them, and your vote is recorded on its own merits — the engine tallies the
panel, not you.

YOUR SEAT:      ${r.seat}
YOUR LENS:      ${text}
THE GATE:       step ${row.step} (${row.instance}, issue ${row.issue}, run ${row.run})
THE PROPOSAL:   ${voteId}${targetNote}${respawnNote}

FIRST, before anything else: \`printenv TMPDIR\` — your literal scratch root.
Call it <TMP>; substitute its literal value wherever <TMP> appears in this
brief. (Use \`printenv\`, not \`echo\`.)

PIN IT ONCE AND REUSE THE LITERAL. \`$TMPDIR\` is not guaranteed to resolve to
the same root in every call, so a path written as the variable can name one
directory when you create it and a different one when you read it back — the
summary file your cast reads back below depends on exactly
that.${heldClusterNote}

Run \`docket\` BARE from your working directory — the store resolves from
anywhere inside the repository; nothing to probe for, nothing to prepend.

THE CASE IS IN THE RECORD, not in this brief: this gate readied mid-wave, so
read what is being decided yourself before you vote —

  docket vote show ${voteId}          (the proposal body: the question)
  docket step show ${row.step} / docket step context ${row.step}
  docket step artifacts ${row.step}   (then \`docket step artifact ARTIFACT-N\`)
  git log --oneline -20 / git diff / git show <sha>

THEIR FLAGS, since guessing one costs you a turn and teaches you nothing:
\`step context\` takes \`--meta\` and NOTHING else; \`step artifact\` takes
\`--payload\`; \`events list\` takes \`--tail N\` (the verb is \`events list\`,
not \`event list\`); \`--json\` is global and works on any of them. None of
these READ verbs takes \`--verbose\`, \`-v\`, or \`--version\` — \`-v\` belongs
to the CAST command below, where it means the verdict, and reaching for it
while reading is the one confusion to avoid. If you want a flag that is not
listed here, run that verb's \`--help\` and read it; never guess one.

plus reading any file those name. The gate sits downstream of the work it
judges — its issue's earlier steps recorded THIS wave, and their artifacts and
payloads are the evidence. Read what the claims rest on. Do not write, edit,
commit, or run anything that mutates state — the ONE state change you are
authorized to make is your own cast, below.

BOUND YOUR INVESTIGATION — then vote. Measured across seven days:
189 tribunal seats spent 5,309,378 output tokens, 68.7% of it on private
deliberation — the highest ratio of any role in this fleet — over 36 votes
and 12 decided proposals in which ZERO verdicts were overturned. That is not
a panel that needed to think harder; it was already right and kept going. You
are seated MID-WAVE, so the cost is paid in wall clock every other row in
this stage waits out. Read what the claims rest on, then decide:

  - A handful of targeted reads settles a typical gate. If your next read is
    not answering a question you can NAME, you are past the point of value.
  - You are ONE seat, not the panel. Another lens covering what yours does not
    is the design working, not a gap for you to close.
  - A concern you cannot resolve is what \`approve-with-concerns\` and the
    summary field exist for. Write it down; do not investigate it away.
  - When you can state a verdict and one paragraph of why, cast. The bar is
    whether your evidence supports the verdict — not whether more reading
    could raise your confidence further. It always could.

EVIDENCE-QUALITY RULE: A finding backed by reproduced evidence — a mutation
test, a demonstrated failure, a verified repro — outranks any aggregate that
demotes it. Never discount reproduced evidence because other reviewers scored
the issue lower.

SETTLED GROUND (operator-ratified): a finding whose \`prior_disposition\`
records a ruling — accepted, corrected, rejected, or deferred with its
follow-up issue named — is decided ground: an operator or an earlier panel
already spent that decision, and the fix loop deliberately does not re-route
it. Re-read the ruling before weighing the finding, and re-litigate it only on
evidence the ruling did not have. Do not reject a gate over settled findings
alone; open findings are the ones your verdict weighs — but weighing is not
counting. Severity already routes: \`blocker\` is the only value that marks a
change that must not proceed, and an open finding below blocker (a Concern,
\`high\`), even with no ruling yet, is not by itself reject grounds — its
venue is \`approve-with-concerns\` and the record, where the operator resolves
it; the severity ladder rules that mechanical rework is the Blocker's venue
alone. Reject over sub-blocker findings only when your own evidence convinces
you the change must not proceed as presented — a judgment about the change,
never an inventory of open highs.

ESCALATION (operator-ratified): a reject does not block work forever — the
gate routes onward per its declared routing, to the human operator or into a
rework loop that answers your findings, so reject when the evidence says
reject; do not approve to keep things moving.

CAST YOUR VOTE — exactly once, as your last action, in TWO Bash calls. First
write your one-paragraph summary to a scratch file with a QUOTED heredoc —
quoting the delimiter means the shell expands NOTHING in the body: backticks,
$( ), and $VAR all stay literal text:

  cat > <TMP>/${row.step}-${r.seat}-summary.txt <<'EOF'
  <your one-paragraph reasoning, on ONE line>
  EOF

Then cast, reading the file back — safe because the substitution wraps a fixed
\`cat\` of your own file, so its content passes into the flag verbatim instead
of being re-parsed as shell syntax:

  docket vote cast ${voteId} --voter ${r.seat} --role ${role} -v <approve|approve-with-concerns|reject> --confidence <0.0-1.0> --domain-relevance <0.0-1.0> --metadata '${metadataClaim}' --summary "$(cat <TMP>/${row.step}-${r.seat}-summary.txt)"

  --verdict/-v      approve                = nothing you found should stop this
                    approve-with-concerns  = proceed, with the risks you name recorded
                    reject                 = the evidence says do not proceed as presented
  --confidence      how sure you are of that verdict GIVEN WHAT YOU ACTUALLY
                    CHECKED. A confident verdict on an uninvestigated payload is
                    a lie about your own work; lower the number instead.
  --domain-relevance how much of this decision falls inside YOUR lens. A seat
                    with little purchase on the question says so with a low
                    number rather than inflating one — the tally weighs it.
  --metadata        pre-filled above with your seat's routing claim (seat,
                    variant, model, effort) so the ledger records what cast
                    this vote. Pass it VERBATIM — do not edit it, and add
                    nothing to it: it is unverified, stored as-is, and public.
  --summary         ONE paragraph: your verdict's reasoning and the specific
                    evidence behind it. Write it to the scratch file EXACTLY as
                    above — NEVER type the paragraph inline in double quotes:
                    backticks, $( ), and $VAR execute there. No line breaks
                    inside the file. Name files, shas, and commands you ran —
                    a summary that could have been written without
                    investigating will read like one.

YOUR FINAL TEXT IS NOT DELIVERED ANYWHERE. THE CAST IS YOUR DELIVERABLE. If the
cast command errors, read the error, fix what it names, and retry ONCE. If it
still fails, end your reply with the verbatim error text and nothing else —
that is the only case where your final text matters.`
}
// TEST-END seat-brief

// TEST-BEGIN gate-vote — extracted and exercised by
// tests/wave-vote-retry-report.test.sh, which concatenates this region after
// the classifier-retry region (whose CLASSIFIER_BLOCK / TRANSIENT_CLASSIFIER /
// reasonText the probe retry below reads) and feeds it stub `agent`,
// `parallel`, `log`, `seatBrief`, `resolveSeat`, `labelsOf`, and `policy`
// globals. Everything else the region needs must stay INSIDE the markers.
// The `target-envelope` region nests inside this one (the ancestry guard
// shares it); tests/wave-target-envelope.test.sh extracts this region whole
// alongside the real `seat-brief` renderer.
function probeBrief(command, servingStep) {
    return `Run exactly this one command:

  ${command}

Return its output VERBATIM as your entire final reply — every line, unedited,
no summary, no commentary, no code fence, nothing added. If the command errors,
return the error text verbatim instead.

Do not cast a vote, do not investigate, do not run anything else. You are a
read-only probe reporting what the record currently says.

WAVE PROBE: not a step execution. Your usage is wave overhead${servingStep ? `. This
read serves ${servingStep}, which is the step it READS, not a step you run — the
usage join must not attribute your tokens to it` : ''}.`
}

function probe(command, label, phaseLabel, servingStep, acct) {
    const once = () => {
        // A probe is wave overhead, NEVER a seat: it lands in its own bucket
        // so the gate summary can say "3 seats, 5 probes" (DOT-1027).
        if (acct) acct.probes++
        return agent(probeBrief(command, servingStep), {
            label,
            phase: phaseLabel,
            agentType: 'executor-read',
            model: 'haiku',
            effort: 'low',
        }).then((text) => text == null ? '' : text)
    }
    return once().catch((err) => {
        // A GATE probe that dies at the agent level (one past run hit this on
        // its gate:tally probe: "API Error: Connection lost mid-response")
        // used to degrade straight to '' — the wave then judged the gate on
        // an empty read, and the completion notification carried the corpse
        // as a failures entry BESIDE the same step's gate-passed verdict. A
        // probe is one read-only, idempotent command, so resubmit the
        // IDENTICAL brief once — except on a non-transient classifier block,
        // which is deterministic on identical bytes. The absorbed error and
        // the retry land in `acct`, so a SUCCEEDING tally reports them as
        // notes instead of leaving them to read as failures (gateSuccess
        // below). Accounting — and with it the retry — rides only the gate
        // path: call sites that pass no acct keep the old single-shot
        // fail-open behavior.
        if (!acct) {
            log(`${label}: probe spawn error: ${err}`)
            return ''
        }
        const reason = reasonText(err) || String(err)
        acct.absorbed.push(`[${label}] ${reason}`)
        if (CLASSIFIER_BLOCK.test(reason) && !TRANSIENT_CLASSIFIER.test(reason)) {
            log(`${label}: probe blocked on content (${reason}) — deterministic ` +
                `on identical bytes, not retried`)
            return ''
        }
        log(`${label}: probe spawn error (${reason}) — retrying the identical ` +
            `read-only probe once`)
        acct.retries++
        return once().catch((err2) => {
            const reason2 = reasonText(err2) || String(err2)
            acct.absorbed.push(`[${label} (retry)] ${reason2}`)
            log(`${label}: probe spawn error on retry: ${reason2}`)
            return ''
        })
    })
}

// Some gate steps decide ONE held finding cluster out of several, and their
// `step show --json` carries the assignment as a flat four-field object:
//   "held_cluster":{"cluster_index":0,"cluster_count":10,
//                   "artifact":"ARTIFACT-1251","producer_step":"reconcile@3"}
// Parse it out of the probe text (which may wrap the JSON in banner prose) so
// the seat brief can NAME the cluster on trial — without this, seats grep the
// repo and the event log to learn which cluster they are deciding. Ordinary
// gates carry no such field; they yield null and the brief renders unchanged.
function parseHeldCluster(show) {
    const m = show.match(/"held_cluster"\s*:\s*(\{[^{}]*\})/)
    if (!m) return null
    try {
        const hc = JSON.parse(m[1])
        if (typeof hc.cluster_index !== 'number' || typeof hc.cluster_count !== 'number' ||
            typeof hc.artifact !== 'string' || typeof hc.producer_step !== 'string') return null
        return {
            clusterIndex: hc.cluster_index,
            clusterCount: hc.cluster_count,
            artifact: hc.artifact,
            producerStep: hc.producer_step,
        }
    } catch {
        return null
    }
}

// The round's target ref, for the seat brief. Context assembly lifts the
// resolved `issue.diff` artifact's round record onto the bundle as
// `target_sha` (the commit the diff's tree stood at) and `target_worktree`
// (the producing record's declared checkout); both are omitted when the
// resolved diff carries no round record, so ABSENCE IS NORMAL and yields
// null rather than a throw.
//
// The probe below reduces rather than dumping the bundle: `step context`
// inlines every recorded input artifact, and a findings artifact runs to
// 1MiB. jq walks the whole bundle, so it finds both fields wherever they sit.
//
// NEVER HAND A SEAT AN EMPTY RESULT TO RELAY (DOT-1040). This used to be a
// `grep -Eo` whose ONLY output on a bundle with no round record was nothing
// at all — and a probe told to "return the output VERBATIM" with no output
// to return is a void the model fills. On RUN-63 (wave wf_48ebd80d-906,
// STEP-3187) the haiku probe's own thinking read "since there's no output and
// no error, I should return nothing", and it then replied with
// `"target_sha": "3ee9ca3cc3f5ada37eb46768efaebe0bea6a02ca"` — a 40-hex sha
// present in no repository and no transcript but its own reply. The wave
// briefed all three security-vote seats with it, and three opus judges spent
// calls hunting a phantom commit. The same probe on the same empty result
// behaved three different ways across one run (silent, fabricating, and
// chatty): the model behaviour is weather, the empty verbatim result is the
// defect.
//
// So the command PRINTS AN ENVELOPE EITHER WAY — `{"target_sha":null,
// "target_worktree":null}` when the bundle carries no round record — and the
// reply is parsed STRUCTURALLY (JSON.parse of that envelope), never by
// regex over free text. Anything that is not the envelope, including the
// empty string, is "no target".
//
// TEST-BEGIN target-envelope — extracted and exercised by
// tests/wave-target-envelope.test.sh, and prepended by
// tests/wave-fix-round-ancestry.test.sh, whose guard shares this command and
// this reader. It nests inside the gate-vote region (which the vote suite
// extracts whole), so keep it free of workflow globals — `log` included.
const TARGET_ENVELOPE_JQ =
    `jq -c '{target_sha: (first(.. | objects | select(has("target_sha")) | ` +
    `.target_sha) // null), target_worktree: (first(.. | objects | ` +
    `select(has("target_worktree")) | .target_worktree) // null)}'`

function targetRefCommand(step) {
    return `docket step context ${step} --json | ${TARGET_ENVELOPE_JQ}`
}

// Read the envelope. Returns {parsed, target}: `parsed` says the reply WAS
// the envelope (so the caller can log a non-envelope reply as such rather
// than as an absent target), `target` is null unless the envelope named at
// least one non-empty string field. A probe's text can carry a harness banner
// ahead of the JSON (seen on two probes), so slice between the outermost
// braces before parsing — that is still a structural read of one object, not
// a field-level regex over prose.
function readTargetEnvelope(text) {
    const s = (text || '').trim()
    const i = s.indexOf('{')
    const j = s.lastIndexOf('}')
    if (i < 0 || j <= i) return { parsed: false, target: null }
    let env
    try {
        env = JSON.parse(s.slice(i, j + 1))
    } catch {
        return { parsed: false, target: null }
    }
    if (!env || typeof env !== 'object' || Array.isArray(env)) {
        return { parsed: false, target: null }
    }
    // The envelope is defined by carrying BOTH keys — a stray object that
    // happens to mention one of them is prose, not this probe's answer.
    if (!('target_sha' in env) || !('target_worktree' in env)) {
        return { parsed: false, target: null }
    }
    const sha = typeof env.target_sha === 'string' ? env.target_sha : ''
    const worktree = typeof env.target_worktree === 'string' ? env.target_worktree : ''
    if (!sha && !worktree) return { parsed: true, target: null }
    return { parsed: true, target: { sha, worktree } }
}

function parseTargetRef(text) {
    return readTargetEnvelope(text).target
}

// A sha only reaches a seat brief when it is 40-hex AND occurs in text the
// wave read for ITSELF — the gate's own `step show` payload — rather than in
// the relayed probe reply alone, which is exactly where a fabrication lives.
// Same for the worktree path. Nothing corroborated means no target ref, and
// the seat is told to read its own HEAD.
const TARGET_SHA_RE = /^[0-9a-f]{40}$/

function corroboratedTarget(target, held) {
    if (!target) return null
    const text = held || ''
    const sha = (TARGET_SHA_RE.test(target.sha) && text.includes(target.sha))
        ? target.sha : ''
    const worktree = (target.worktree && text.includes(target.worktree))
        ? target.worktree : ''
    if (!sha && !worktree) return null
    return { sha, worktree }
}
// TEST-END target-envelope

// `docket vote show <id> --json` answers with the standard envelope
//   {ok: true, data: {id, status, final_outcome?, weighted_score,
//                     votes: [{voter_name, verdict, summary, ...}], ...}}
// A probe's text can carry a harness banner AHEAD of that JSON (seen on two
// probes), so slice from the first `{` before parsing. Returns the `data`
// object, or null when the text will not parse — callers then fall back to
// matching the raw text, and say so in the log.
function parseVoteShow(text) {
    const s = text || ''
    const i = s.indexOf('{')
    if (i < 0) return null
    try {
        const parsed = JSON.parse(s.slice(i))
        const data = parsed && typeof parsed === 'object' ? parsed.data : null
        return data && typeof data === 'object' ? data : null
    } catch {
        return null
    }
}

// Assemble a gate's SUCCESS result. A vote row whose tally succeeds after
// agent-level noise (a seat re-spawn, a probe resubmission, a dead probe)
// must not read as failed: one past run's completion notification carried
// "[STEP-N · gate:tally] failed: ..." BESIDE the same step's trusted
// gate-passed verdict — exactly the shape a conductor misreads as a failed
// gate. So the success result carries seat/probe/retry accounting
// explicitly, and every absorbed error as a NOTE naming the tally's
// success — never as a failure. Failure outcomes (gate-rejected/-blocked/
// -parked) deliberately do NOT come through here: their errors are real.
//
// SEATS AND PROBES ARE COUNTED SEPARATELY (DOT-1027). A single "N spawns for
// M seats" total conflated the judges with the read-only haiku probes the
// gate path spends on its own bookkeeping (gate:show, gate:target,
// gate:record, gate:outcome, gate:tally): a real 3-judge panel logged "8
// spawns for 3 seats", and an auditor checking the seat count against the
// row's `voters` saw 8 vs 3. Worse, an ALREADY-DECIDED gate seats no panel
// at all and logged "1 spawn for 0 seats" — a judge on an empty panel. So
// the seats clause is emitted ONLY when a panel was actually seated; with no
// panel the line reports probes and retries alone.
function gateSuccess(step, text, acct) {
    const n = (count, one, many) => `${count} ${count === 1 ? one : many}`
    const parts = []
    if (acct.seats > 0) parts.push(n(acct.seats, 'seat', 'seats'))
    parts.push(n(acct.probes, 'probe', 'probes'))
    parts.push(n(acct.retries, 'retry', 'retries'))
    const res = {
        step,
        status: 'gate-passed',
        text,
        spawn_accounting: parts.join(', '),
    }
    if (acct.absorbed.length > 0) {
        res.notes = acct.absorbed.map((e) =>
            `absorbed agent-level error (superseded in-wave; the tally ` +
            `SUCCEEDED — NOT a failure of this step): ${e}`)
    }
    return res
}

async function runGate(row, phaseLabel) {
    // Seat/probe accounting for THIS gate, counted in SEPARATE buckets:
    // `seats` is the judge panel (what the row's `voters` promised), `probes`
    // is every read-only haiku spawn the gate path spends on its own
    // bookkeeping. They used to share one `spawns` total, which read as a
    // panel far larger than the roster (DOT-1027). Seat re-spawns and probe
    // resubmissions are retries; agent-level errors land in `absorbed` and
    // ride the SUCCESS result as notes (gateSuccess above).
    const acct = { seats: 0, probes: 0, retries: 0, absorbed: [] }
    // The ballot: record-driving opened the proposal when the gate's last
    // predecessor recorded — an earlier stage this wave already awaited — so
    // one probe normally finds it. A gate with NO proposal means the
    // predecessors did not all record (a failure upstream): the gate is
    // blocked, its issue's later rows are dead for this wave, and the next
    // round routes whatever on_fail produced.
    let show = await probe(`docket step show ${row.step} --json`,
        `${row.step} · gate:show`, phaseLabel, undefined, acct)
    // Proposal ids are project-prefixed: 1-8 upcased letters, "-V", digits
    // (docket's FormatProposalID / project set-prefix grammar), e.g. DKT-V29.
    const m = show.match(/"proposal"\s*:\s*"([A-Z]{1,8}-V\d+)"/)
    // A held-cluster gate decides ONE cluster of findings, not the
    // whole gate — pass the assignment into every seat's brief (null on the
    // ordinary gates whose show text carries no held_cluster field).
    const heldCluster = parseHeldCluster(show)
    // A vote step's STATUS cannot carry the verdict: the engine records a
    // REJECTED vote as `done` when its on_fail routes machine-side (measured
    // three runs: 0-3-0 tallies rendered "gate-passed" and the conductor
    // believed it). The TALLY is the outcome; read it from the proposal.
    const tallyOutcome = async (voteId) => {
        const t = await probe(`docket vote show ${voteId} --json`,
            `${row.step} · gate:tally`, phaseLabel, row.step, acct)
        // Read the verdict STRUCTURALLY. The regex below matches
        // anywhere in the text — including inside a seat's free-text summary,
        // so a rationale quoting `"status": "rejected"` while explaining why it
        // did NOT reject flipped an approved gate to gate-rejected (rejected is
        // tested first). Parsing the envelope reads only the tally's own field.
        const data = parseVoteShow(t)
        if (data) {
            const verdicts = [data.status, data.final_outcome]
                .filter((v) => typeof v === 'string')
                .map((v) => v.toLowerCase())
            if (verdicts.includes('rejected')) return { outcome: 'rejected', tally: t }
            if (verdicts.includes('approved')) return { outcome: 'approved', tally: t }
            return { outcome: 'unknown', tally: t }
        }
        log(`${row.step}: gate:tally JSON did not parse — falling back to a ` +
            `regex match on the raw probe text`)
        if (/"(status|final_outcome)"\s*:\s*"rejected"/i.test(t)) return { outcome: 'rejected', tally: t }
        if (/"(status|final_outcome)"\s*:\s*"approved"/i.test(t)) return { outcome: 'approved', tally: t }
        return { outcome: 'unknown', tally: t }
    }
    if (/"status"\s*:\s*"(done|skipped|superseded)"/.test(show)) {
        if (m) {
            const { outcome, tally } = await tallyOutcome(m[1])
            if (outcome === 'rejected') {
                log(`${row.step}: gate already decided REJECTED (${m[1]}) — ` +
                    `engine routes on_fail; skipping this issue's later stages`)
                return { step: row.step, status: 'gate-rejected', text: tally }
            }
        }
        log(`${row.step}: gate already decided — continuing`)
        const early = gateSuccess(row.step, show, acct)
        // No panel was seated on this row, so the accounting carries no seats
        // clause at all — reading "0 seats" here (with the probes counted as
        // spawns) made an already-decided gate look like a judge on an empty
        // panel (DOT-1027).
        log(`${row.step}: no panel seated — ${early.spawn_accounting}` + (early.notes ?
            ` — ${early.notes.length} agent-level error(s) absorbed (NOT failures for this step)` : ''))
        return early
    }
    if (!m) {
        log(`${row.step}: gate has no proposal — its predecessors did not all ` +
            `record, so the panel cannot seat; skipping this issue's later stages`)
        return { step: row.step, status: 'gate-blocked', text: show }
    }
    const voteId = m[1]
    const voters = Array.isArray(row.voters) ? row.voters : []
    if (voters.length === 0) {
        log(`${row.step}: vote row carries no voters — the engine renders the ` +
            `roster on vote rows, so this manifest predates the contract; ` +
            `escalate instead of guessing a panel`)
        return { step: row.step, status: 'gate-blocked', text: show }
    }
    const seats = voters.map((v) => resolveSeat(v, policy, labelsOf(row)))
    // Name the round's target ref in every seat's brief. Seats are
    // NOT seated on the checkout the round was written in — writers work in
    // private worktrees — so without this a judge reads its own lagging HEAD,
    // finds the change absent, and rejects on evidence grounds, which no fix
    // loop can answer.
    //
    // DON'T SPEND THE PROBE WHEN THE ANSWER IS ALREADY IN HAND (DOT-1040).
    // `show` is the gate's own step payload, already fetched above. When it
    // carries no target field at all there is nothing for the probe to find,
    // and a probe with nothing to find is precisely the void that got filled
    // with a fabricated sha on RUN-63. Measured on this machine: 22 of these
    // probes across every recorded wave, ZERO of which relayed a real target
    // and ONE of which invented one. So skip the spawn outright; the probe
    // re-arms by itself the day the engine lifts the field onto `step show`.
    let target = null
    if (!/"target_(sha|worktree)"/.test(show)) {
        log(`${row.step}: gate:show carries no target ref field — skipping ` +
            `the gate:target probe entirely; seats are told to read their ` +
            `own HEAD`)
    } else {
        const reply = await probe(targetRefCommand(row.step),
            `${row.step} · gate:target`, phaseLabel, row.step, acct)
        const env = readTargetEnvelope(reply)
        if (!env.parsed) {
            log(`${row.step}: gate:target probe reply did not parse — ` +
                `treating as no target`)
        }
        // Second net: a sha reaches a brief only if it is 40-hex AND occurs
        // in `show`, which the wave read for itself.
        target = corroboratedTarget(env.target, show)
        if (env.target && !target) {
            log(`${row.step}: gate:target probe named a target the gate's own ` +
                `step payload does not carry — refusing to brief it; seats ` +
                `read their own HEAD`)
        }
    }
    log(`${row.step}: ${voteId} — seating ${seats.map((s) => s.seat).join(', ')}` +
        (target ? ` on target ${target.sha || '(no sha)'}${target.worktree ? ` (${target.worktree})` : ''}`
                : ` with NO target ref on the bundle — seats read their own HEAD`))
    acct.seats = seats.length
    await parallel(seats.map((r) => () => {
        return agent(seatBrief(r, voteId, row, false, heldCluster, target), {
            label: `${row.step} · seat:${r.seat}`,
            phase: phaseLabel,
            agentType: 'executor-read',
            model: r.model,
            effort: r.effort,
        }).catch((err) => {
            log(`${row.step} seat ${r.seat}: spawn error: ${err}`)
            acct.absorbed.push(`[${row.step} · seat:${r.seat}] ${reasonText(err) || String(err)}`)
            return null
        })
    }))

    // One re-spawn for seats whose cast never landed — tribunal.js's rule.
    // This reads the SAME `--json` envelope the tally does and takes
    // the roster from `.data.votes[].voter_name`. It used to spend a separate
    // human-format probe (~12-13k tokens, 35-60s) to substring-match seat
    // names out of prose — the JSON read already carries that structurally.
    const record = await probe(`docket vote show ${voteId} --json`,
        `${row.step} · gate:record`, phaseLabel, row.step, acct)
    const recorded = parseVoteShow(record)
    let missing
    if (recorded && Array.isArray(recorded.votes)) {
        const cast = recorded.votes
            .map((v) => (v && typeof v.voter_name === 'string') ? v.voter_name : '')
            .filter(Boolean)
        missing = seats.filter((s) => !cast.some((n) => n.includes(s.seat)))
    } else {
        log(`${row.step}: gate:record JSON did not parse — falling back to a ` +
            `substring match on the raw probe text`)
        missing = seats.filter((s) => !record.includes(s.seat))
    }
    if (missing.length > 0) {
        log(`${row.step}: ${missing.length} seat(s) returned without a recorded ` +
            `cast (${missing.map((s) => s.seat).join(', ')}) — re-spawning each ONCE`)
        await parallel(missing.map((r) => () => {
            // A re-seated judge is a RETRY of a seat already counted in
            // acct.seats — never an extra seat, never a probe.
            acct.retries++
            return agent(seatBrief(r, voteId, row, true, heldCluster, target), {
                label: `${row.step} · seat:${r.seat} (retry)`,
                phase: phaseLabel,
                agentType: 'executor-read',
                model: r.model,
                effort: r.effort,
            }).catch((err) => {
                log(`${row.step} seat ${r.seat}: respawn error: ${err}`)
                acct.absorbed.push(`[${row.step} · seat:${r.seat} (retry)] ${reasonText(err) || String(err)}`)
                return null
            })
        }))
    }

    // `done` says only that the step COMPLETED — a rejection whose on_fail
    // routes into rework also reads done/superseded. The tally is the verdict.
    show = await probe(`docket step show ${row.step} --json`,
        `${row.step} · gate:outcome`, phaseLabel, undefined, acct)
    if (/"status"\s*:\s*"done"/.test(show)) {
        const { outcome, tally } = await tallyOutcome(voteId)
        if (outcome === 'rejected') {
            log(`${row.step}: gate decided REJECTED (${voteId}) — engine ` +
                `routes on_fail; the conductor verifies the routing; ` +
                `skipping this issue's later stages`)
            return { step: row.step, status: 'gate-rejected', text: tally }
        }
        log(`${row.step}: gate passed — continuing`)
        const res = gateSuccess(row.step, show, acct)
        log(`${row.step}: ${res.spawn_accounting}` + (res.notes ?
            ` — ${res.notes.length} agent-level error(s) absorbed (NOT failures for this step)` : ''))
        return res
    }
    log(`${row.step}: gate did NOT clear (${(show.match(/"status"\s*:\s*"([a-z-]+)"/) || [])[1] || 'unknown'}) ` +
        `— skipping this issue's later stages; the conductor escalates`)
    return { step: row.step, status: 'gate-parked', text: show }
}
// TEST-END gate-vote

// ---------------------------------------------------------------------------
// FIX-ROUND BASE ANCESTRY. The conductor integrates a fix round by
// cherry-picking the sha on the change-summary's first line onto the shared
// branch; the next round's fix worktree is cut from that branch's HEAD, so
// the tree the next review fanout judges must DESCEND from the integrated
// commit. Nothing verified that, and twice the hand-off broke a round late:
// RUN-35 round 2 — all five judges found round-1's commit was not
// an ancestor of the judged commit and re-filed two defects round 1 had
// closed (17.37M tokens re-finding closed work); RUN-51 rounds 5-6
// — fix@5's worktree was a SIBLING of round 4's commit, two full review
// rounds spent detecting and repairing the fork.
//
// So the wave asserts the ancestry BEFORE the fanout spawns — the same check
// the judges already ran one round too late — and parks the round as a RELAY
// finding ('parked-base-ancestry', chain-dead for the issue) instead of
// seating judges on a tree that cannot contain the prior round's fix.
//
// THE SHA IS THE INTEGRATED ONE, AND ONLY THE CONDUCTOR HOLDS IT: integration
// cherry-picks, so the WRITER's sha is never an ancestor of the shared branch
// even after its content lands — asserting on it would park every healthy
// round. The conductor passes `args.integrated`, mapping each issue with a
// fix round in this dispatch to the sha of the PRIOR round's integration
// commit — the integration of the write step the judged tree was BUILT ON,
// which for a review@N fanout is fix@(N-1)'s integration (or implement's when
// N-1 is the implement round), NEVER fix@N's own (conduct/SKILL.md,
// "Worktree writers" — the other half of this contract). Absent map, absent
// entry, non-sha entry, no round fanout, round 1, missing target on the
// bundle, dead or unparseable probe — every one of these FAILS OPEN to the
// old behavior: the guard exists to stop a measured waste, never to add a new
// way for a healthy round to stall.
//
// AND THE MAP ITSELF CAN NAME THE WRONG ROUND (DOT-1022). When fix@N and its
// review@N#k fanout are SPLIT across dispatches — a /pause, a wave that ended
// between them, a budget stop — fix@N is already integrated by the time the
// conductor derives the map, and "most recent integration" reads as fix@N's
// own commit: the cherry-pick OF the judged tree. A cherry-pick can never be
// an ancestor of its source, so the merge-base exits 1 on every HEALTHY round
// in that shape (RUN-66 DISPATCH-360: 18 of 28 rows lost to it). So before
// parking, self-check the map entry — if `prior` carries a `cherry picked
// from commit <target>` trailer it IS the judged round's own integration and
// the verdict is worthless: fail open and dispatch.
// TEST-BEGIN fix-round-ancestry — extracted and exercised by
// tests/wave-fix-round-ancestry.test.sh (and concatenated ahead of the
// stage-ladder region by tests/wave-chain-dead-ladder.test.sh, whose ladder
// calls into it). Keep everything between the markers free of workflow
// globals (agent, probe, log, args) so it stays evaluable on its own.
//
// ONE declared dependency on another region: the target read shares the gate
// path's command and reader (`target-envelope`, nested inside `gate-vote`),
// so every suite that extracts THIS region prepends that one.

// A fix round's REVIEW FANOUT: the engine mints per-round step instances as
// `name@N`, with `#k` on fanout siblings (roundHops above reads the same
// grammar). Only fanout rows (`@N#k`) are guarded: they are the judge seats,
// a write row (`fix@N`, no `#k`) is what CREATES the round's tree, and
// per-round singletons behind the fanout (synthesize@N) die with the chain
// when the fanout parks. Round 1 reviews the initial implement — there is no
// prior fix round to contain — so the guard starts at round 2.
const FANOUT_INSTANCE_RE = /@(\d+)#\d+$/

function fixRoundFanoutRound(row) {
    const m = FANOUT_INSTANCE_RE.exec((row && row.instance) || '')
    return m ? parseInt(m[1], 10) : 0
}

// Both shas travel into a probe's command line, so both are shape-checked:
// the integrated sha against the conductor's map entry, the target sha as
// parsed off the engine bundle. Anything not plain hex is treated as absent.
const ANCESTRY_SHA_RE = /^[0-9a-f]{7,40}$/i

function integratedShaFor(row, integrated) {
    if (!integrated || typeof integrated !== 'object' ||
        Array.isArray(integrated)) return ''
    const sha = row && row.issue ? integrated[row.issue] : ''
    return typeof sha === 'string' && ANCESTRY_SHA_RE.test(sha) ? sha : ''
}

function needsAncestryCheck(row, integrated) {
    if (!row || row.kind !== 'executor') return false
    if (fixRoundFanoutRound(row) < 2) return false
    return integratedShaFor(row, integrated) !== ''
}

// The judged tree: context assembly lifts the resolved issue.diff round
// record onto the bundle as `target_sha` — the same field the gate path's
// probe reads (readTargetEnvelope above), narrowed to the sha half because
// the ancestry check has no use for the worktree path.
//
// SAME ENVELOPE, SAME REASON (DOT-1040). This probe used to share the gate
// path's `grep -Eo`, so on a bundle with no round record it too handed its
// haiku seat an empty result to relay verbatim — the void that got filled
// with a fabricated 40-hex sha on RUN-63's gate:target. Here the blast
// radius is worse than a misleading brief: an invented sha resolves nowhere,
// `git merge-base --is-ancestor` exits non-zero on it, and the guard PARKS a
// healthy fix round's whole judge fanout. So the command prints
// `{"target_sha":null,"target_worktree":null}` when the field is absent and
// the reply is parsed structurally; anything that is not that envelope is
// "no target" and fails open, exactly as an absent field always did.
// The command itself is targetRefCommand(step), shared verbatim with the
// gate path (TEST region `target-envelope`).
function parseAncestryTargetSha(text) {
    const target = parseTargetRef(text)
    const sha = target ? target.sha : ''
    return ANCESTRY_SHA_RE.test(sha) ? sha : ''
}

// One read-only probe carrying both directions of the evidence the RUN-35
// judges recorded: the merge-base exit status (0 = the judged tree contains
// the prior round's integrated commit) and the branch containment listing.
// Every worktree shares one object store, so both commands resolve from the
// shared checkout the probe runs in.
function ancestryProbeCommand(prior, target) {
    return `git merge-base --is-ancestor ${prior} ${target}; ` +
        `echo "ancestry-exit=$?"; git branch -a --contains ${prior}`
}

function parseAncestryExit(text) {
    const m = (text || '').match(/ancestry-exit=(\d+)/)
    return m ? parseInt(m[1], 10) : null
}

// SELF-CHECK ON THE MAP ENTRY (DOT-1022). A non-zero merge-base is only
// evidence of a broken hand-off if `prior` is the round BEFORE the one being
// judged. When the conductor derived the map after fix@N had already been
// integrated (the fanout split off into a later dispatch), `prior` is the
// cherry-pick OF `target` — it post-dates the judged tree by construction and
// no healthy tree can ever contain it. Integration cherry-picks with `-x`, so
// that relationship is readable straight off the commit message trailer. Grep
// is `-q`, so the exit marker alone carries the answer: 0 = `prior` is the
// cherry-pick of `target` = wrong round in the map. Both shas are already
// hex-shape-checked before they reach a command line.
function cherryPickOfTargetCommand(prior, target) {
    return `git log -1 --format=%B ${prior} | ` +
        `grep -q "cherry picked from commit ${target}"; ` +
        `echo "cherrypick-of-target-exit=$?"`
}

function parseCherryPickOfTargetExit(text) {
    const m = (text || '').match(/cherrypick-of-target-exit=(\d+)/)
    return m ? parseInt(m[1], 10) : null
}

// The parked round, as a RELAY finding: the report names what broke, carries
// the probe evidence verbatim, and says what the conductor does about it —
// exactly what five judges per round were re-deriving. chainDead() reads the
// status, so the issue's later rows die with the fanout this wave, and the
// engine re-offers the round's steps after the tree is repaired.
function ancestryParkReport(step, broken) {
    const headline = `fix round ${broken.round} parked before its judge ` +
        `fanout: the prior round's integrated commit ${broken.prior} is not ` +
        `an ancestor of the judged tree ${broken.target}`
    return {
        step,
        status: 'parked-base-ancestry',
        headline,
        text: [
            `${step} BASE ANCESTRY BROKEN — ${headline}.`,
            `git merge-base --is-ancestor ${broken.prior} ${broken.target} ` +
                `exited ${broken.exit} (0 would mean the judged tree ` +
                `contains the prior round's fix).`,
            `Probe evidence (exit marker, then \`git branch -a --contains ` +
                `${broken.prior}\`):`,
            broken.evidence,
            `This is a relay finding, not a judge finding: seating the ` +
                `fanout would spend a full review round re-discovering work ` +
                `the prior round already closed. Repair the hand-off — ` +
                `verify the integration commit is actually on the shared ` +
                `branch, and repair the tree this round judges so it ` +
                `descends from it (a conflict there is a stop-and-ask) — ` +
                `then redispatch; the engine re-offers the round's steps.`,
        ].join('\n'),
    }
}
// TEST-END fix-round-ancestry

// PER-ISSUE LANES, WITH THE ENGINE'S CROSS-ISSUE COHORTS HONORED FROM THE
// MANIFEST ITSELF. The engine's `stage` labels carry two different things at
// once (engine lookahead.go):
//
//   1. DEPENDENCY ORDER, which is SAME-ISSUE ONLY. `after` predecessors,
//      loop re-entry (precedesInSet refuses a cross-issue pair outright)
//      and open interposed gates all live inside one issue's workflow. A
//      cross-issue `depends_on` never reaches a manifest at all: the closure
//      stops at an unsatisfied one ("cross-issue edges resolve at issue
//      completion, which is rollup work no single wave owns"), so a row is
//      offered only once its issue's dependencies are already met, and no
//      manifest row carries a dependency field to inspect.
//   2. COHORT PACKING, which IS cross-issue. Within one stage a bounded
//      class holds at most `[limits] max` rows and tree-holding steps of
//      different issues must have disjoint scopes; a staged row that does
//      not fit its earliest legal stage is bumped later. That coupling is
//      what the first per-issue lanes broke — they ran the bumped row
//      concurrently with the writer it was bumped away from and bounced it
//      off `claim` — and why a global ladder replaced them.
//
// The global ladder honored (2) by making every issue wait for every other
// issue at every stage: measured on one run as an issue's judges idling
// ~12 minutes behind two unrelated implements and a park. This ladder keeps
// (1) per issue — a LANE ascends its own stage labels with an await between
// — and honors (2) from what the manifest proves:
//
//   - CLASS HEADROOM. The engine put at most `max` rows of a bounded class
//     into any one stage (ClaimablePrefix for ready rows, cohortFits for
//     staged ones), so the largest same-stage count of a class in this
//     manifest is a proven lower bound on its limit. The wave never has more
//     rows of a class in flight than that count, whichever stages they came
//     from. An unbounded class is under-used by the rule, never
//     over-committed.
//   - SCOPE. Two writers the engine co-staged were checked against each
//     other, and scope is a property of the ISSUE, so one co-staged writer
//     pair proves the two issues' scopes disjoint (or empty) for every
//     writer either issue owns. A writer launches ahead of another issue's
//     in-flight writer only on that proof; without it the pair keeps the
//     engine's stage order between them, and the log says so. "Writer" is
//     `class: "write"` — the corpus's tree-holding class; every other
//     executor step in the corpus declares `holds_tree = false` and is exempt
//     from R4 engine-side. This is the one place the ladder leans on corpus
//     convention rather than engine data: a step holding a tree under some
//     other class would be scope-serialized by the engine and not by the
//     wave, and would bounce on claim.
//
// A park is still RUN-WIDE: the engine refuses every claim while the run is
// not active (R1 is the first readiness clause and `claim` re-checks it), so
// once a park is observed no lane launches anything further — rows waiting
// for admission settle `not-launched-run-parked`, in-flight rows finish. A
// CONFLICT, a failed spawn, or an uncleared gate still kills only its own
// issue's later rows.
// TEST-BEGIN stage-ladder — extracted and exercised by
// tests/wave-chain-dead-ladder.test.sh, tests/wave-fix-round-ancestry.test.sh
// and tests/wave-issue-lanes.test.sh, which wrap this whole region in an
// async function and feed it stub `parallel`/`spawn`/`runGate`/`probe`/`log`
// globals. Everything the ladder itself needs must stay INSIDE the markers;
// the only workflow globals it may reach for are those stubs, `rows`,
// `input`, and the fix-round-ancestry region's helpers (the suites
// concatenate that region ahead of this one).
const stageOf = (row) => (Number.isInteger(row.stage) ? row.stage : 0)
const stages = new Map()
for (const row of rows) {
    const s = stageOf(row)
    if (!stages.has(s)) stages.set(s, [])
    stages.get(s).push(row)
}
const stageKeys = [...stages.keys()].sort((a, b) => a - b)

log(`wave: ${rows.map((r) => `${r.step}·${r.kind === 'executor' ? r.executor : r.kind}`).join(', ')} — policy v${policyVersion}, ${(input.policyText || '').length} chars`)
log(`wave: ${rows.length} row(s) across stage(s) ${stageKeys.join('→')}`)
{
    // Say up front which issues the fix-round ancestry guard is
    // armed for, so a wave with no `integrated` map is legible as unguarded
    // rather than silently skipping the check.
    const guarded = rows.filter((r) => needsAncestryCheck(r, input.integrated))
    if (guarded.length > 0) {
        const issues = [...new Set(guarded.map((r) => r.issue))]
        log(`wave: fix-round ancestry guard armed for ${issues.join(', ')} ` +
            `(${guarded.length} fanout row(s))`)
    }
}

// Executor rows staged BEHIND a same-issue action or vote row can be
// superseded/unclaimable by the time their stage arrives (the predecessor
// held or was rejected) — a blind spawn there dies on claim CONFLICT, an
// opus corpse per occurrence (measured: 17 across 4 runs). Probe those
// rows with the same cheap read the gate path uses; skip the spawn when
// the step is no longer claimable. Fail-open: an empty probe spawns.
const gateStageByIssue = new Map()
for (const row of rows) {
    if ((row.kind === 'action' || row.kind === 'vote') && row.issue) {
        const s = stageOf(row)
        const cur = gateStageByIssue.get(row.issue)
        if (cur === undefined || s < cur) gateStageByIssue.set(row.issue, s)
    }
}
function needsClaimProbe(row) {
    if (row.kind !== 'executor' || !row.issue) return false
    const g = gateStageByIssue.get(row.issue)
    return g !== undefined && g < stageOf(row)
}

// The fix-round base-ancestry guard (helpers above the ladder). One
// verdict per issue-round, shared by every fanout sibling: two cheap
// read-only probes decide whether the fanout spawns — the round's target sha
// off the bundle, then the merge-base check. The probes run AT THE ROW'S OWN
// STAGE, after its lane's earlier stages settled, so the bundle's round
// record is live. Every uncertain outcome resolves null (fail-open); only a
// positively parsed non-zero merge-base exit parks.
const ancestryVerdicts = new Map()
function ancestryVerdict(row, phaseLabel) {
    const round = fixRoundFanoutRound(row)
    const prior = integratedShaFor(row, input.integrated)
    const key = `${row.issue}@${round}`
    if (!ancestryVerdicts.has(key)) {
        ancestryVerdicts.set(key, (async () => {
            const ctx = await probe(targetRefCommand(row.step),
                `${row.step} · ancestry:target`, phaseLabel, row.step)
            const target = parseAncestryTargetSha(ctx)
            if (!target) {
                // Two distinct causes, both fail-open, logged apart so a
                // relayed non-envelope (DOT-1040) is never mistaken for the
                // engine recording no round record.
                if (!readTargetEnvelope(ctx).parsed) {
                    log(`${row.step}: ancestry:target probe reply did not ` +
                        `parse — treating as no target; fail-open, ` +
                        `dispatching round ${round} as before`)
                } else {
                    log(`${row.step}: fix-round ancestry guard found no ` +
                        `target_sha on the bundle — fail-open, dispatching ` +
                        `round ${round} as before`)
                }
                return null
            }
            const evidence = await probe(ancestryProbeCommand(prior, target),
                `${row.step} · ancestry:merge-base`, phaseLabel, row.step)
            const exit = parseAncestryExit(evidence)
            if (exit === null) {
                log(`${row.step}: ancestry probe carried no exit marker — ` +
                    `fail-open, dispatching round ${round} as before`)
                return null
            }
            if (exit === 0) {
                log(`${row.step}: round ${round} judged tree ${target} ` +
                    `contains the prior round's integrated ${prior} — ` +
                    `ancestry holds`)
                return null
            }
            // Before parking: is the map entry even the right round? A
            // `prior` that is the cherry-pick OF `target` is fix@N's own
            // integration, which cannot be an ancestor of the tree it was
            // taken from — the verdict says nothing about the hand-off.
            // Unparseable or dead self-check probe keeps the park (the
            // original evidence still stands).
            const selfCheck = await probe(
                cherryPickOfTargetCommand(prior, target),
                `${row.step} · ancestry:self-check`, phaseLabel, row.step)
            if (parseCherryPickOfTargetExit(selfCheck) === 0) {
                log(`${row.step}: integrated map carries the judged round's ` +
                    `OWN integration commit — wrong round, fail-open. ` +
                    `${prior} is the cherry-pick of the judged tree ` +
                    `${target}, so it post-dates it and no healthy round ` +
                    `could contain it; dispatching round ${round} and ` +
                    `spending no park on it`)
                return null
            }
            log(`${row.step}: BASE ANCESTRY BROKEN — merge-base ` +
                `--is-ancestor ${prior} ${target} exited ${exit}; parking ` +
                `round ${round} as a relay finding instead of spending its ` +
                `judge fanout`)
            return { round, prior, target, exit, evidence }
        })())
    }
    return ancestryVerdicts.get(key)
}

const byStep = new Map()
// A park observed anywhere stops every lane's LATER launches (in-flight rows
// finish; the engine re-offers unlaunched steps after the park lifts). A
// CONFLICT, a failed spawn, or an uncleared gate kills only its own ISSUE's
// later rows — the chain behind it cannot become claimable this wave, and
// spawning it anyway boots corpses.
let parked = false
const deadIssues = new Set()

// TEST-BEGIN chain-dead — see the park-signals note above.
function chainDead(res) {
    if (res == null) return false
    if (res.status === 'gate-parked' || res.status === 'gate-blocked' ||
        res.status === 'gate-rejected' || res.status === 'skipped-not-claimable' ||
        res.status === 'skipped-not-ready') return true
    // A stage-N executor that never produced an agent leaves its step
    // unrecorded, so every later `after` row of the same ISSUE is guaranteed to
    // die on claim ("an `after` predecessor is not done"). One past run spent
    // ~52K tokens booting three such corpses. The engine re-offers the whole
    // chain at the next dispatch, so calling the issue dead here loses nothing.
    if (res.status === 'spawn-failed') return true
    // A diagnosed claim CONFLICT is the SAME dead chain it always
    // was — only the report changed. It carries its own status precisely so
    // the kill does not ride on the report's text staying inside
    // isConflictReport()'s three-line budget, which the diagnosis exceeds.
    if (res.status === 'claim-conflict') return true
    // A fix round parked on broken base ancestry. The judged tree
    // does not contain the prior round's integrated commit, so every later
    // per-round row of the issue (synthesize@N, verify@N) would work the
    // same wrong tree.
    if (res.status === 'parked-base-ancestry') return true
    // Same body-scan trap as runParked: `includes('CONFLICT')` would kill an
    // issue's whole remaining chain on a judge that merely REPORTED one.
    return res.status === 'returned' && isConflictReport(res.text)
}
// TEST-END chain-dead

// ---- lanes: one per issue, an issue-less row riding a lane of its own ----
const laneOf = (row) => (row.issue ? String(row.issue) : `row:${row.step}`)
const lanes = new Map()
for (const row of rows) {
    const l = laneOf(row)
    if (!lanes.has(l)) lanes.set(l, [])
    lanes.get(l).push(row)
}
log(`wave: ${lanes.size} issue lane(s): ` + [...lanes.entries()].map(([name, laneRows]) => {
    const ks = [...new Set(laneRows.map(stageOf))].sort((a, b) => a - b)
    return `${name}×${laneRows.length}${ks.length > 1 ? ` (stages ${ks.join('→')})` : ''}`
}).join(', '))

// ---- what the manifest certifies about cross-issue concurrency ----
// The launch path treats every row that is neither an action nor a vote as
// an executor; the cohort arithmetic reads the same set, so a row without
// `kind` is reserved exactly as it is spawned. The engine keys class headroom
// on the row's `class`, defaulted to the executor hint at expansion (workflow
// validate.go) — mirror that default so a row rendered without the field
// lands in the bucket the engine actually counted.
const isExecutorRow = (row) => row.kind !== 'action' && row.kind !== 'vote'
const classOf = (row) => (typeof row.class === 'string' && row.class !== '')
    ? row.class
    : (typeof row.executor === 'string' ? row.executor : '')
const isWriter = (row) => isExecutorRow(row) && classOf(row) === 'write'
const pairKey = (a, b) => (a < b ? `${a} ${b}` : `${b} ${a}`)
const certifiedClass = new Map()   // class -> largest same-stage count
const scopePairs = new Set()       // lane pairs with writers co-staged
for (const group of stages.values()) {
    const perClass = new Map()
    const writerLanes = new Set()
    for (const row of group) {
        if (!isExecutorRow(row)) continue
        const c = classOf(row)
        perClass.set(c, (perClass.get(c) || 0) + 1)
        if (isWriter(row) && row.issue) writerLanes.add(laneOf(row))
    }
    for (const [c, n] of perClass) {
        if (n > (certifiedClass.get(c) || 0)) certifiedClass.set(c, n)
    }
    const ws = [...writerLanes]
    for (let i = 0; i < ws.length; i++) {
        for (let j = i + 1; j < ws.length; j++) scopePairs.add(pairKey(ws[i], ws[j]))
    }
}
const scopeCertified = (a, b) => a === b || scopePairs.has(pairKey(a, b))
if (lanes.size > 1) {
    log(`wave: lanes run concurrently; the manifest certifies class headroom ` +
        [...certifiedClass.entries()].map(([c, n]) => `${c || '(no class)'}≤${n}`).join(', '))
    const writerLanes = [...new Set(rows.filter((r) => isWriter(r) && r.issue).map(laneOf))]
    const unproven = []
    for (let i = 0; i < writerLanes.length; i++) {
        for (let j = i + 1; j < writerLanes.length; j++) {
            if (!scopeCertified(writerLanes[i], writerLanes[j])) {
                unproven.push(`${writerLanes[i]}/${writerLanes[j]}`)
            }
        }
    }
    if (unproven.length > 0) {
        log(`wave: cross-issue coupling — the engine never co-staged writers of ` +
            `${unproven.join(', ')}, so their scopes are unproven disjoint; those ` +
            `writers keep the global stage order between them`)
    }
}

// ---- admission: a row launches only when the in-flight set plus the row is
// a cohort the manifest certifies. Nothing here is a claim: the engine's own
// `claim` re-checks R1-R7 and stays the authority; this rule exists so the
// wave never spawns an executor INTO a refusal it can foresee. ----
const inFlight = new Map()   // step -> row, executor rows launched and unsettled
const waiting = []           // { row, seq, resolve, held }
let submitted = 0
function blocker(row) {
    if (!isExecutorRow(row)) return null
    const c = classOf(row)
    let live = 0
    for (const other of inFlight.values()) {
        if (classOf(other) === c) live++
        if (isWriter(row) && isWriter(other) && !scopeCertified(laneOf(row), laneOf(other))) {
            return `writer ${other.step} (${laneOf(other)}, stage ${stageOf(other)}) is ` +
                `in flight and the engine never co-staged writers of ${laneOf(row)} ` +
                `and ${laneOf(other)} — scopes unproven disjoint, holding to the ` +
                `engine's stage order`
        }
    }
    const cap = certifiedClass.get(c) || 1
    if (live >= cap) {
        return `${live} row(s) of class ${c || '(no class)'} in flight — the manifest ` +
            `certifies at most ${cap} concurrent`
    }
    return null
}
// Deterministic and synchronous: lowest stage first (the engine's own order,
// so the global ladder is what falls out wherever nothing is certified), then
// submission order. Every admission changes the in-flight set, so the scan
// restarts from the top. Single-threaded event loop; nothing here awaits.
function pump() {
    waiting.sort((a, b) => stageOf(a.row) - stageOf(b.row) || a.seq - b.seq)
    let i = 0
    while (i < waiting.length) {
        const w = waiting[i]
        if (parked) {
            waiting.splice(i, 1)
            w.resolve(false)
            continue
        }
        const why = blocker(w.row)
        if (why) {
            if (!w.held) {
                w.held = true
                log(`${w.row.step}: waiting — ${why}`)
            }
            i++
            continue
        }
        waiting.splice(i, 1)
        if (isExecutorRow(w.row)) inFlight.set(w.row.step, w.row)
        if (w.held) log(`${w.row.step}: released — launching`)
        w.resolve(true)
        i = 0
    }
}
// Resolves true to launch, false when the run parked while the row waited.
function admission(row) {
    return new Promise((resolve) => {
        waiting.push({ row, seq: submitted++, resolve, held: false })
        pump()
    })
}
function release(row) {
    if (inFlight.delete(row.step)) pump()
}
function observePark(res) {
    if (parked || !runParked(res)) return
    parked = true
    log('wave: run parked mid-wave — no lane launches a later stage; the ' +
        'engine refuses every claim until the park lifts, then re-offers ' +
        'their steps')
    pump()
}

// One row's launch, once admitted: the gate path for a vote row, else the
// fix-round ancestry guard and the pre-claim probe ahead of the spawn.
function startRow(row, label) {
    if (row.kind === 'vote') return runGate(row, label)
    const launchRow = () => {
        if (needsClaimProbe(row)) {
            return probe(`docket step show ${row.step} --json`,
                `${row.step} · pre-claim`, label, row.step).then((show) => {
                // Skip only on a positively recognized status the wave
                // cannot act on; empty output, prose, and anything
                // unrecognized all spawn (fail-open). `pending` belongs
                // in that set HERE and only here: this probe runs after
                // the row's lane awaited and settled its earlier stages,
                // and admission excludes this wave's own cohort pressure,
                // so nothing left in this wave can advance the step to
                // `ready`. A pending row is dead for the wave — spawning
                // it burns an executor that dies on claim CONFLICT, and
                // the engine re-offers it next dispatch.
                const term = show.match(/"status"\s*:\s*"(done|superseded|skipped|failed|pending)"/)
                if (!term) return spawn(row, label)
                log(`${row.step}: not claimable (${term[1]}) — a same-issue ` +
                    `gate or action upstream left it unreachable for this ` +
                    `wave; skipping the spawn`)
                return { step: row.step, status: 'skipped-not-claimable', text: show }
            })
        }
        return spawn(row, label)
    }
    // A fix round's review fanout is asserted against the prior
    // round's integrated commit BEFORE the judges spawn (ancestryVerdict
    // above; one shared verdict per issue-round). A broken ancestry parks
    // the round as a relay finding; anything short of a positively
    // broken read launches exactly as before.
    if (needsAncestryCheck(row, input.integrated)) {
        return ancestryVerdict(row, label).then((broken) =>
            broken ? ancestryParkReport(row.step, broken) : launchRow())
    }
    return launchRow()
}

async function runLane(name, laneRows) {
    const byStage = new Map()
    for (const row of laneRows) {
        const s = stageOf(row)
        if (!byStage.has(s)) byStage.set(s, [])
        byStage.get(s).push(row)
    }
    const keys = [...byStage.keys()].sort((a, b) => a - b)
    for (const k of keys) {
        if (parked) break
        const group = byStage.get(k).filter((row) => {
            if (row.issue && deadIssues.has(row.issue)) {
                byStep.set(row.step, { step: row.step, status: 'skipped-chain-dead', text: null })
                log(`${row.step}: skipped — this wave's chain died at an earlier ` +
                    `stage (the issue itself is untouched)`)
                return false
            }
            return true
        })
        if (group.length === 0) continue
        const label = `${name} stage ${k} (${group.length} row${group.length === 1 ? '' : 's'})`
        const settled = await parallel(group.map((row) => () => {
            if (row.kind === 'action') {
                // Engine-run, and normally already DONE: the record of its
                // last predecessor drove it (engine drive.go) before that
                // record returned. Nothing to spawn; the row is in the
                // manifest so the stage numbering stays transparent.
                log(`${row.step}: action step — engine-run at record time, no spawn`)
                return Promise.resolve({ step: row.step, status: 'engine-run', text: null })
            }
            return admission(row).then((go) => {
                if (!go) {
                    log(`${row.step}: not launched — the run parked while it waited`)
                    return { step: row.step, status: 'not-launched-run-parked', text: null }
                }
                return Promise.resolve()
                    .then(() => startRow(row, label))
                    .then((res) => {
                        // Read the park signal PER ROW, the moment it lands,
                        // and BEFORE the row's slot is released: releasing
                        // first would admit a waiter into a run the engine
                        // already refuses claims on.
                        observePark(res)
                        release(row)
                        return res
                    }, (err) => {
                        release(row)
                        throw err
                    })
            })
        }))
        settled.forEach((res, i) => {
            const row = group[i]
            // Normalize BEFORE the chain test: a missing settle is recorded as
            // spawn-failed, so it has to be read as one too.
            const out = res || { step: row.step, status: 'spawn-failed', text: null }
            byStep.set(row.step, out)
            if (chainDead(out) && row.issue) {
                deadIssues.add(row.issue)
                log(`${row.step}: settled ${out.status} — issue ${row.issue}'s later ` +
                    `stages will not be launched this wave`)
            }
        })
    }
}

await parallel([...lanes.entries()].map(([name, laneRows]) => () => runLane(name, laneRows)))

return rows.map((row) => byStep.get(row.step) ||
    { step: row.step, status: parked ? 'not-launched-run-parked' : 'spawn-failed' })
// TEST-END stage-ladder
