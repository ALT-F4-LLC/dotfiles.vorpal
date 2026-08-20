export const meta = {
    name: 'wave',
    description: 'Run one dispatched manifest end to end: spawn one executor per executor row (routed by policy.toml), seat a judge panel on each vote row, and skip action rows (engine-run at record time). Stages run as awaited groups — the staged closure means one wave can carry judges -> gate -> reconcile -> report. Invoke by scriptPath ONLY, with args {rows, policyText} as a real object — policy.toml is passed as TEXT, never a path; the script cannot read files.',
    whenToUse: 'Invoked by the conduct skill on an open dispatch, always as Workflow({scriptPath}) — never by name. args is {rows, policyText}: `next` rows verbatim (executor, vote, and action rows; human rows stay with the conductor) plus the literal TEXT of policy.toml. There is no policyPath and no file access.',
}

// ---------------------------------------------------------------------------
// TOML subset parser — byte-identical to tribunal.js's, deliberately
// duplicated. A workflow script has no file access and no module resolution:
// it cannot import a sibling, so the only alternatives are this copy or a
// second parser that drifts. tests/workflow-sync.test.sh diffs every
// SYNC-marked region between the two files (self-names normalized) and fails
// on drift.
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

const INVESTIGATOR_CLASS = ['investigate', 'research', 'retro-analyst']

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
        if (g === 'failed-top-opus-round' && row.attempt > 1 &&
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
    // [[resolve]] tables are retired (2026-08-13): label routing is when-gated
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
    // Escalation: one escalate_to hop per failed attempt, from the standing
    // variant. The walk stops at the chain's end, at the security ceiling, or
    // just before a variant whose model is never-listed.
    if (row.attempt > 1) {
        for (let hop = 1; hop < row.attempt; hop++) {
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
            if (never.includes(next.model)) break
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
    'implement', 'test-infra', 'fix',
    'prd-author', 'tdd-author', 'tdd-author-security',
    'adr-author', 'ux-spec-author', 'pr-comment-author',
    'spec-author-architecture', 'spec-author-security', 'spec-author-operations',
    'spec-author-performance', 'spec-author-code-quality',
    'spec-author-review-strategy', 'spec-author-testing',
]

function archetype(row, hint) {
    if (hint === 'research') return 'executor-research'
    if (row.class === 'write' || WRITE_HINTS.includes(hint)) return 'executor-write'
    return 'executor-read'
}

// HOW THIS BRIEF IS WORDED, and it is load-bearing: state the required form,
// omit the defense. A brief never addresses the safety classifier, never names
// a technique by what it gets past, and never pre-argues its own
// authorization — that wording is itself screened, and on 2026-08-17 it cost
// manifest-argocd every executor spawn across three dispatch cycles (RUN-5:
// each spawn refused, zero steps claimed). Say what to do and what containment
// binds; a rule needs no argument for why it is allowed.
function bootstrap(row, r, isolated, isWrite) {
    const isolationNote = isolated ? `

0. YOU ARE IN A PRIVATE WORKTREE of the repository, AND YOUR BASH CALLS MAY
   BE SCREENED BY A GUARD — every rule below binds you identically whether
   or not one is active. The worktree protects your SIBLINGS from you — it does
   not change your own discipline: your archetype's byte-identical rule still
   holds, and any probe that must modify files still runs on a COPY under
   <TMP>, never on this checkout. (Never reach for the revert verbs — git
   restore, checkout --, reset, clean: probing on copies means never needing
   them, and this protocol has no undo step.) Never cd out to the shared
   repository tree. Command discipline, non-negotiable — every call you make
   must be obvious at a glance, exactly what it says and nothing more:

   - ONE action per Bash call: no \`&&\` chains, no \`$(...)\` substitution
     around git. Run every command PLAIN and SEPARATE.
   - Spell every redirect target as a LITERAL absolute path. (Shell
     variables do not survive between your calls anyway — see the token
     protocol below.)
   - Run git against YOUR OWN tree only — never \`git -C\` or \`--git-dir\`
     aimed at another checkout, never cd-then-git elsewhere. Pipes are fine.

   RUN \`docket\` BARE — no DOCKET_PATH prefix, ever. The store resolves from
   anywhere inside the repository, this worktree included: nothing to probe
   for, nothing to prepend.

   Bootstrap, one plain command at a time:

   a. \`printenv TMPDIR\` — your literal scratch root. Call it <TMP>;
      substitute its literal value wherever <TMP> or \`$TMPDIR\` appears in
      this brief. (Use \`printenv\`, not \`echo\` — no variable expansion
      anywhere in your calls, this one included.)

      PIN IT ONCE AND REUSE THE LITERAL. \`$TMPDIR\` is not guaranteed to
      resolve to the same root in every call, so a path written as the
      variable can name one directory when you create it and a different one
      when you read it back — files and directories alike, both of which
      persist perfectly well under whichever root actually received them.
      The literal is what makes "I wrote it, therefore I can read it" true.
   b. \`git worktree list --porcelain\` — every checkout's path and HEAD sha.
   c. Compare \`git rev-parse HEAD\` in your tree to the HEAD of the shared
      checkout from (b) — the one NOT under \`.claude/worktrees\`. If they
      differ, run \`git checkout --detach --quiet <that sha>\`. Config bases
      your worktree on the run's HEAD, so this is normally a no-op — verify,
      never assume.

   If any of these is DENIED by the guard or the permission system, say
   \`BOOTSTRAP DENIED\`, quote the denial verbatim, and STOP — that is an
   operator permission gap, not a repository-state problem. If a command
   fails on its own output instead, report that verbatim and STOP. Either
   way, do not hunt, do not guess, and NEVER claim after a failed
   bootstrap: an unclaimed step re-dispatches for free; a claimed one
   strands a token. Success binds the same way: once (c) passes, your NEXT
   command is the claim in 1' — no exploratory docket verbs first (no
   --help, no step list/show, no run status/report, no next, nothing under
   dispatch). The brief and the packet carry everything a claim needs.

   TRANSLATION RULES — obligations 1 and 3 below print code blocks written
   for the shared tree; run their ISOLATED forms instead, everything else
   in their prose still binding:

   1'. Claim, as separate plain commands, literal paths throughout:
       \`docket step claim ${row.step} --owner wave:${row.step} --render --json > <TMP>/${row.step}.claim.json\`
       \`jq -r '.data.token' <TMP>/${row.step}.claim.json > <TMP>/${row.step}.token\`
       \`chmod 600 <TMP>/${row.step}.token\`
       \`jq -r '.data.packet' <TMP>/${row.step}.claim.json > <TMP>/${row.step}.packet.md\`
       \`cat /dev/null > <TMP>/${row.step}.claim.json\`
       Then open <TMP>/${row.step}.packet.md with the Read tool — the packet
       goes to a FILE here, not stdout, which also keeps a large brief from
       being truncated by the harness's inline-output cap.
       If the claim itself errors naming a packet file ("pinned by this run
       but is no longer on disk"), report the error verbatim and STOP — the
       ref came from a REPO-ADDITION config layer, which is repo-root-relative
       and absent from your worktree (shared-corpus refs resolve from any cwd);
       the claim already recorded and the token is gone; a re-claim burns an
       attempt on the same wall, and the relay's reap is the only way out.
   3'. Record with the token fed to stdin from its literal path:
       \`docket step record ${row.step} ... < <TMP>/${row.step}.token\`

   Uncommitted work in the shared tree is deliberately not visible, and
   your inputs arrive in the rendered packet, not from the tree.` : ''
    const pinNote = isolated ? '' : `

0. FIRST, before the claim: \`printenv TMPDIR\` — your literal scratch root.
   Call it <TMP>; substitute its literal value wherever <TMP> appears below.
   (Use \`printenv\`, not \`echo\`.)

   PIN IT ONCE AND REUSE THE LITERAL. \`$TMPDIR\` is not guaranteed to resolve
   to the same root in every call, so a path written as the variable can name
   one directory when you create it and a different one when you read it
   back — files persist perfectly well under whichever root actually received
   them. The literal is what makes "I wrote it, therefore I can read it"
   true, and the claim token you park in obligation 1 depends on exactly
   that.`
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
   docket step claim ${row.step} --owner wave:${row.step} --render --json > <TMP>/${row.step}.claim.json &&
     jq -r '.data.token'  < <TMP>/${row.step}.claim.json > <TMP>/${row.step}.token &&
     chmod 600 <TMP>/${row.step}.token &&
     jq -r '.data.packet' < <TMP>/${row.step}.claim.json &&
     cat /dev/null > <TMP>/${row.step}.claim.json
   \`\`\`

   The last command TRUNCATES the claim file rather than deleting it. Its
   contents are spent the moment the packet above is printed, so emptying it
   is enough. Same rule at step 3.

   Every path is spelled out because YOUR SCRATCH ROOT <TMP> IS SHARED BY EVERY
   EXECUTOR IN THE WAVE (measured: concurrent subagents all get the same
   directory). Your
   step id is what makes these filenames yours; do not shorten them to
   \`claim.json\` or \`token\`, or a sibling's claim overwrites yours.

   THE TOKEN IS RETURNED EXACTLY ONCE, in that response body — re-claiming is
   refused while you hold the lease, so there is NO second chance to capture it.
   SHELL VARIABLES DO NOT SURVIVE BETWEEN BASH CALLS and your work in step 2
   will take many calls, so a variable is useless here. The file is the only
   channel that reaches step 3.

   WRITING THE TOKEN TO THIS FILE IS REQUIRED AND AUTHORIZED — it is the
   designed mechanism, not a leak. It is mode 0600 under your own step id, it
   dies with the session's scratch directory, and the engine retires the token
   the moment you record. Do not skip the file write to be cautious: skipping
   it strands the step and is the WORSE outcome.

   The last command prints your rendered brief. Read it — it is your contract.

   IF THE HARNESS REPLIES \`<persisted-output> Output too large\`, WHAT YOU SEE
   INLINE IS NOT YOUR BRIEF. It is the first 2KB of it, and the cut lands inside
   the REQUEST section — everything that actually binds you sits BELOW it: your
   contract file, every fragment, PINNED, and OUTPUT. Read the named file with
   the Read tool before doing anything else. A 30KB brief is the normal case for
   a step carrying several pinned files, not an anomaly (RUN-7 STEP-319: 30,697
   bytes, of which ~2,000 were shown).

   On CONFLICT: stop immediately and report AT MOST three lines: your step id,
   the word CONFLICT, and the engine's error line verbatim. Do not investigate
   the holder, the scopes, or the remedy — the conductor and the engine already
   know.

2. Execute the brief you were handed. It is your entire contract.${isWrite ? `
   Ship the issue's declared change list and NOTHING beyond it: unrequested
   hardening, extra controls, and adjacent cleanups go into gap files
   (obligation 3), never into the diff. Reviewers reject what nobody asked
   for — one measured run spent a third of its budget removing an executor's
   unrequested additions. The one exception to the quiet-gap rule: a defect
   you find that is actively exploitable is REPORTED in your return
   immediately, not merely gap-filed.` : ''}
${!isWrite ? `
2r. THE CHECKOUT YOU STAND IN MAY PREDATE THE CHANGE YOUR BRIEF DESCRIBES.
   Write-class siblings work in PRIVATE worktrees and hand their work back as
   a COMMIT — nothing merges those commits into this shared checkout, so HEAD
   here can be a round or more behind the change-summary and issue.diff your
   packet renders (measured twice on one run: judges read a pre-fix tree and
   re-filed findings the fix had already closed). Before reading ANY file by
   path to evaluate the change:

   - FIRST: if the packet's issue.diff is EMPTY and the change-summary
     records a gap-only outcome (no commit, no files changed), there is
     nothing to evaluate. Confirm that pair in ONE read-only pass and record
     immediately, saying exactly that and naming which half was
     engine-computed (the empty issue.diff) vs self-reported (the summary);
     do NOT investigate repositories to re-prove a non-change, and do NOT
     file a duplicate gap — the upstream record already carries it
     (measured: four judges each re-proved one empty diff).
   - Find the target sha — the change-summary's FIRST LINE carries it.
   - Reconstruct the target read-only, ALWAYS — do not first probe whether
     your checkout contains the change: integration cherry-picks, so the
     writer's sha is never an ancestor of the shared branch even after its
     content lands, and proving tree-equivalence burns budget the brief does
     not ask for (measured). Extract:
     TWO plain calls, and \`<TMP>\` is the LITERAL from bootstrap (a), never
     the words \`$TMPDIR\`:

       mkdir -p <TMP>/${row.step}-target
       git archive <sha> | tar -x -C <TMP>/${row.step}-target

     The \`mkdir\` is not optional: \`tar -x -C\` on a directory that does not
     exist fails \`could not chdir\` and extracts NOTHING, so a single-call
     form without it reports a failure you then have to diagnose.

     The literal is not optional either, and this is the half that bites
     silently. \`$TMPDIR\` does not resolve to the same root in every call —
     the same hazard the artifact-file rule below records for the Write tool
     (RUN-1 STEP-32), one call apart instead of one tool apart. Extract under
     one root and read under another and you get "no such file or directory"
     against a tree you just built successfully, or worse, fall back to
     reading the shared checkout — a judge reviewing a tree a round behind the
     change, which is exactly what this obligation exists to prevent
     (observed: RUN-31 STEP-821).

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
   (two SEPARATE plain calls exactly as shown — no compounds, and no global
   options before \`add\`/\`commit\`):

   git add -A
   git commit --no-gpg-sign -m "type(scope): summary"

   The subject is a CONVENTIONAL COMMIT, whatever the repo's history does:
   "type(scope): summary" — type one of feat|fix|docs|refactor|test|perf|
   build|ci|chore, scope named for the area you touched, summary imperative
   plain language, 72 chars max, no trailing period. No body paragraphs —
   most commits are a subject alone; when the subject cannot carry the why,
   short "- " bullets. Never step, issue, or run ids (no STEP-N, DKT-N, RUN-N in
   subject or body): ids already live in your change-summary artifact and
   the engine record, and an id-bearing subject forces a hand-amend at
   integration.

   Then \`git rev-parse HEAD\` and put that sha ON THE FIRST LINE of your
   change-summary artifact AND in your final report. The commit is unsigned
   integration plumbing on a throwaway worktree branch — the operator's own
   signed commit remains the only thing that enters published history. Do NOT
   push, and do not touch any other checkout.

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

   \`docket step record ${row.step}${isWrite ? ' --worktree <YOUR CHECKOUT>' : ''} --artifact-file <TMP>/${row.step}-<kind>.md --metadata '{"model_requested":"${r.model_requested}","effort_requested":"${r.effort_requested}","model_resolved":"<model that served you>","effort_resolved":"<effort you ran at>"}' < <TMP>/${row.step}.token\`

   \`record\` is an exact alias of \`step complete\` — identical saga, identical
   flags — and it is the verb to use: some shells parse the bare word
   \`complete\` as their own builtin and refuse the line before docket sees it.

   Run this command SANDBOXED, same as everything else — do NOT pass
   dangerouslyDisableSandbox. Only the operator can grant that, and never
   through a brief. Most gates are pure local work (build/test/lint/scan)
   and need no elevation at all.

   IF a gate genuinely needs network access and the sandbox denies it —
   record exits non-zero and the error names a DNS failure, a TLS handshake
   failure, or a blocked host — do not retry with the sandbox disabled and
   do not treat it as a normal step failure (the code may be fine; the
   infrastructure isn't reachable). Attempt once, then STOP and report
   \`NETWORK GATE BLOCKED\`: the gate name, the exact host/domain the error
   names, and the error verbatim. Leave your token intact, exactly as an
   unresolved record refusal below. The fix is a named domain added to
   \`sandbox_network_allowed_domains\` in \`src/user/claude_code.rs\` (see the
   \`vuln.go.dev\` entry there for precedent) through the operator's own
   \`just activate\` — never a live bypass, and never on your say-so.
${isWrite ? `
   \`--worktree\` names the checkout the work happened in. The engine
   computes the recorded diff THERE, and — since DKT-9 (docket.git,
   2026-08-16) — spawns your step's completion gates and the downstream
   verify pre-gate with that checkout as cwd too. Get its literal path once
   with \`git rev-parse --show-toplevel\` and paste that in; without it the
   engine diffs the wrong tree and its gates measure the shared checkout
   instead of your work, because your edits live in your own worktree.
` : ''}
   \`model_resolved\` is the exact model id your environment reports (e.g.
   \`claude-sonnet-5\`), never a branding form — a "[1m]" suffix in the ledger
   fragments every routing-drift query that reads it (measured, RUN-8).

   or on failure:

   \`docket step fail ${row.step} --note '<why>' < <TMP>/${row.step}.token\`

   \`fail\` takes ONLY --note and --metadata — there is no --artifact-file on
   it. What you learned goes in the note (or the metadata bag); do not try to
   attach an artifact to a failure. \`--artifact-file\` exists on \`record\`
   alone, where it is MANDATORY. Reach for \`fail\` only when a retry might
   redeem the attempt.

   AN OUT-OF-SCOPE PROBLEM YOUR WORK SURFACED IS NEITHER A FAILURE NOR YOUR
   DECLARED ARTIFACT. Write each one to its own file and pass \`--gap-file
   <path>\` (repeatable) on the record: every gap file lands as a \`gap\`
   artifact beside your declared emit AND files a related backlog issue in the
   SAME transaction, so the residue cannot evaporate — no workflow declaration
   needed, that channel is always open. Your contract's Stuck clause is a
   SUCCESS recorded this way, never a \`fail\`.

   A gap file's FIRST LINE becomes the filed issue's TITLE: one line naming
   the defect itself, readable on a board. Its SECOND LINE is the home
   declaration, ALWAYS: \`Home: <repo/checkout>\` — the other repository when
   the problem lives elsewhere, or \`Home: THIS repository\` when it is local
   (operator ruling 2026-08-16: gaps belong to their respective projects —
   the engine files yours HERE and the conductor re-homes it from your
   Home: line; a gap that leads with routing preamble buries the defect in
   every listing, and one that hides its home strands the work in the wrong
   backlog).
${isolated ? `
   IF THE RECORD IS REFUSED (guard or permission), attempt it ONCE and STOP
   TRYING FORMS. Leave your deliverables parked where the brief already has
   them —

     <TMP>/${row.step}.token       (intact, 0600 — do NOT truncate it)
     <TMP>/${row.step}-<kind>.md   (your artifact body)
     <TMP>/${row.step}-payload.json (your payload, when the contract has one)

   — and report RECORD BLOCKED: your step id, the refusal's first line
   verbatim, and every parked path including the token's. ONE refusal is an
   instruction, not a wall: "the lease has expired; claim it again to
   continue" means run the claim from 1' again for a FRESH token and record
   immediately — your finished work is still valid and the re-claim costs
   seconds (measured twice; the agent that parked instead cost a duplicate
   run). Park and report only when the re-claim or the record refuses for
   any OTHER reason; the conductor is not isolated and records the step from
   your parked state. NEVER record \`fail\` for work that succeeded — a
   false failure burns an attempt and re-runs the whole step to relearn what
   your parked artifacts already hold (RUN-8 measured one full re-judging).
` : ''}

   The CLI reads the token from DOCKET_TOKEN or, when that is unset, from stdin
   (\`internal/cli/token.go\`; engine-spec.md §4, "Tokens pass via env/stdin,
   never argv"). NOTHING SETS DOCKET_TOKEN FOR YOU — a claim cannot export
   into your shell. Redirecting the file into stdin is the channel.

   Never \`cat\` the file, echo its contents, paste it into a command line, or
   reproduce it in your reply. There is deliberately no \`--token\` flag on any
   verb, because argv is world-readable through \`ps\`. Redirect it; never read it.

   After the record command exits 0, leave the token file alone or truncate
   it (\`cat /dev/null > <TMP>/${row.step}.token\`) — the engine retires
   the token the moment the record lands, so the file is inert either way. If \`record\` or
   \`fail\` errored, KEEP the token file INTACT and stop — it is the only
   thing that can still drive this step, and losing it after a failed record
   turns a routine step failure into a zombie claim the lease must reap.

   If the token file is missing or empty, or a record is refused for a missing
   or invalid token, say so plainly and stop. Do not reconstruct or guess it.

   EVERY record carries an artifact file. The engine refuses a record without
   \`--artifact-file\` before it validates anything else — "a step completes by
   recording what it produced" — so the file is never optional. Create it WITH
   BASH (a heredoc: \`cat > <TMP>/${row.step}-<kind>.md <<'EOF' ... EOF\`)
   as a FRESH file whose name starts with your step id, then pass that path as
   \`--artifact-file\`. NEVER create this file with the Write tool: under the
   sandbox the Write tool materializes files at a DIFFERENT physical path
   than the <TMP> root your Bash commands use, and the record then
   fails "no such file or directory" against a file you just wrote
   (observed: RUN-1 STEP-32).

   ARTIFACT FILES: THREE AUTHORING RULES. A large or brace-heavy heredoc
   body fails in an isolated shell. Author files these ways from the start
   and that failure never arises. Every form below writes ONLY to targets
   under your <TMP> or your own worktree — that containment is the rule
   itself, not a detail of it, and a write aimed anywhere else is out of
   bounds whatever form it takes.

   - SIZE: never write a large body in one heredoc. Write the file as an
     initial \`cat > <path> <<'EOF'\` of a few KB at most, followed by
     \`cat >> <path> <<'EOF'\` appends of the same size until done.
   - JSON: always \`jq -n\` (below) — never a JSON literal in any heredoc.
   - CODE EXCERPTS (Go signatures, config samples, anything brace- or
     bracket-heavy): let the excerpt travel as file bytes rather than as
     command text. Write it to its own scratch file in small chunks with the
     SIZE form above, then \`cat\` that file into place — or build the
     artifact with \`jq -n --rawfile body <TMP>/<step>-excerpt.txt\`.
     Do not hand-encode, escape, or otherwise transform the content itself.

   (There is no \`--artifact-kind\`: the workflow's
   \`emits\` declares the artifact's KIND — which your brief's OUTPUT section
   already names — it does not make the file optional. A structured payload,
   when your brief requires one, goes in \`--payload-file <path>\` — and you
   BUILD that JSON with \`jq -n\`, never as a JSON literal in a heredoc or
   command: an isolated shell's guard refuses any heredoc body carrying \`{\`
   immediately followed by \`"\` — which is every JSON object literal, compact
   or pretty, so no formatting gets a literal past it. \`jq -n --arg id AC1
   --arg status met '{id: $id, status: $status}' > "$path"\` is the honest
   shape: the command text carries only \`{id:\` (which the guard allows) and
   jq writes the real JSON to the file. Keys needing quotes go as
   \`{("kebab-key"): $v}\`; arrays as \`jq -n '[ ... ]'\` or by \`jq -s\` over
   per-element files.) Never
   write to or reuse a shared filename like \`change-summary.md\`: executors in
   one wave share <TMP>, and under a shared name a racing sibling's bytes
   — or a predecessor's leftover when your own write silently fails — get
   recorded as YOUR artifact (RUN-3's STEP-11 recorded STEP-21's summary
   exactly this way).

   If a write is refused, triage the refusal before anything else. One that
   names the body's SIZE OR CONTENT, on a target under <TMP> or your own
   worktree, means the three forms above are how to write it — use them.
   One that says the command is TOO COMPLEX TO VERIFY that it stays inside
   the worktree names the command's SHAPE, not its body: reissue the same
   work as single plain commands — ONE redirection or ONE heredoc each, no
   \`&&\`, no pipes, no \`;\`, no command substitution — and run them
   separately. Its closing line about git operations is boilerplate; it fires
   on non-git commands too (a bare \`cat > <TMP>/x.txt <<'EOF'\` of two
   words has drawn it), so do NOT read it as a claim that you touched git,
   and do not go hunting for a git mistake you did not make. This is the same
   guard as the brace-then-quote rule above, refusing on a different axis.
   One that names ANYTHING ELSE — the target path, a permission, a policy
   concern — is a real BLOCKED condition on the spot, exactly like a refused
   record, and so is one that survives the three forms: report \`WRITE
   BLOCKED\`, the refusal's first line, and every path involved, then stop
   that path and record what you can. Use those three forms and nothing
   else. Never devise an encoding, a substitution, or a staged rewrite to
   get refused content through: content that will not go through in the
   plain forms is a BLOCKED report, always.

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
const policy = parseToml(input.policyText || '')

if (policy.policy?.version !== 3) {
    throw new Error(
        `wave.js: policy.toml [policy] version is ${JSON.stringify(policy.policy?.version)}, expected 3 ` +
        `(the [variants]/escalate_to shape, unchanged since v2 — only the version number moved). ` +
        `Refusing to route against an unknown schema.`
    )
}

if (policy.resolve) {
    throw new Error(
        'wave.js: policy.toml still carries [[resolve]] tables, but label-keyed ' +
        'hint resolution is retired (2026-08-13) — label routing lives in ' +
        'when-gated workflow steps declaring concrete executors, and silently ' +
        'ignoring a table would mis-route the very steps it named. Update the ' +
        'installed corpus (policy.toml + workflow files move together). ' +
        'Refusing to route.'
    )
}

// An agent's reply is PROSE. Read only the two shapes the brief actually
// mandates — never a substring of the body (DOT-226).
//
// Both park signals used to be `includes` over the whole reply, and RUN-28
// wave 1 shows the cost: judge STEP-687 reviewed the pause skill, quoted the
// engine constant it was reviewing — `CondRunActive = "run is not active"` —
// and recorded `done`. Its last line said so verbatim, `STEP-687 recorded
// (done)`. The wave read the quote, declared the run parked, and never
// launched stage 2; the engine re-offered synthesize one full dispatch
// round-trip later. A reviewer of park handling cannot describe a park
// without tripping a body scan, and this corpus reviews its own park
// handling constantly.
// TEST-BEGIN park-signals — extracted and exercised by
// tests/wave-park-signals.test.sh against the verbatim RUN-28 replies. Keep
// everything between the markers free of workflow globals (agent, log, args)
// so it stays evaluable on its own.
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
// corpses (measured twice on RUN-8: 5 judges launched into a park the prior
// stage's result already announced). The tail format is mandated by the
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

function spawn(row, phaseLabel) {
    const r = resolve(row, policy)
    const type = archetype(row, r.hint)
    // Only writers get a worktree (RUN-8 docket, 2026-08-12). Isolation exists
    // so parallel WRITERS cannot cross-contaminate the shared tree; read-class
    // steps never mutate it. And the harness guard that polices an isolated
    // shell refuses any heredoc body carrying `{` immediately followed by `"`
    // — every JSON object literal, compact or pretty — so isolating readers
    // taxed exactly the steps whose payloads are JSON: 89 refusals across 21
    // agents in 6 waves, including the one that evaded the guard and tripped
    // the security classifier (STEP-197).
    const isWrite = type === 'executor-write'
    const isolated = isWrite
    log(`${row.step}: ${r.hint} -> ${type} @ ${r.model}/${r.effort} (variant ${r.variant})` +
        ` [${labelsOf(row).join(' ') || 'no labels'}]` +
        (isolated ? ' [worktree]' : ''))
    const opts = (iso) => ({
        label: `${row.step} · ${r.hint}`,
        phase: phaseLabel,
        agentType: type,
        model: r.model,
        effort: r.effort,
        ...(iso ? { isolation: 'worktree' } : {}),
    })
    const handle = (text) => {
        if (text == null) {
            log(`${row.step}: SPAWN PRODUCED NOTHING (launch blocked before the ` +
                `agent existed — this wave's task .output workflowProgress[].error ` +
                `carries the stated reason when there is one — or model ${r.model} ` +
                `unavailable, the agent was skipped, or it died mid-flight) — whether a claim ` +
                `was recorded is UNKNOWN; reconcile via \`docket dispatch verify\` ` +
                `and \`docket step show ${row.step}\`, then, if it is still claimed ` +
                `by this dead spawn, return it to the pool with \`docket step reap ` +
                `${row.step} --reason '<what you observed>'\` (token-free) before ` +
                `any retry`)
            return { step: row.step, status: 'spawn-failed', text: null }
        }
        return { step: row.step, status: 'returned', text }
    }
    return agent(bootstrap(row, r, isolated, isWrite), opts(isolated)).then(handle)
        .catch((err) => {
            if (isolated && /base branch|worktree/i.test(String(err))) {
                log(`${row.step}: worktree isolation unavailable (${err}) — retrying ` +
                    `WITHOUT isolation; cross-contamination guard is OFF for this spawn`)
                return agent(bootstrap(row, r, false, isWrite), opts(false)).then(handle)
                    .catch((err2) => {
                        log(`${row.step}: spawn error on non-isolated retry: ${err2}`)
                        return { step: row.step, status: 'spawn-failed', text: null }
                    })
            }
            log(`${row.step}: spawn error: ${err}`)
            return { step: row.step, status: 'spawn-failed', text: null }
        })
}

// ---------------------------------------------------------------------------
// Vote rows: the in-wave panel. A `kind:"vote"` row rides the manifest —
// ready, or STAGED behind the work it judges (the engine's dependency
// closure) — and the wave seats the panel itself: it cannot nest tribunal.js
// (workflow nesting is one level, and the wave IS the child), so the seat
// contract lives here too, adapted from tribunal.js. The engine remains the
// only authority: `step record` on the gate's last predecessor opens the
// proposal (record-driving, engine drive.go), each seat casts a REAL
// `docket vote cast`, the engine tallies, and the quorum-reaching cast
// routes the gate — by the time the seats settle, downstream staged rows are
// claimable. This script never casts, approves, or tallies.
//
// Seat routing mirrors tribunal.js's resolveSeat: no attempt chain, no fable
// gates (a seat's variant is its standing home); the [security] node pins
// still bind.
// ---------------------------------------------------------------------------

// SYNC-BEGIN seat-contract
function resolveSeat(seat, policy) {
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
    if ((sec.nodes || []).includes(seat)) {
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

// A seat's lens is its trailing name segment: `tribunal-security` -> security.
// An unrecognised seat gets the whole-system lens rather than a throw — a gate
// decided by a generically-briefed judge is still decided; a thrown panel
// leaves the gate undecidable.
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

function seatBrief(r, voteId, row, isRespawn) {
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

    return `You are ONE SEAT of a tribunal deciding a gate step MID-WAVE in a Docket run.
You decide alone. You cannot see the other seats, you do not coordinate with
them, and your vote is recorded on its own merits — the engine tallies the
panel, not you.

YOUR SEAT:      ${r.seat}
YOUR LENS:      ${text}
THE GATE:       step ${row.step} (${row.instance}, issue ${row.issue}, run ${row.run})
THE PROPOSAL:   ${voteId}${respawnNote}

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

BOUND YOUR INVESTIGATION — then vote. Measured 2026-08-19 across seven days:
189 tribunal seats spent 5,309,378 output tokens, 68.7% of it on private
deliberation — the highest ratio of any role in this fleet — over an epoch of
36 votes and 12 decided proposals in which ZERO verdicts were overturned. That
is not a panel that needed to think harder; it is a panel that was already
right and kept going. You are seated MID-WAVE, so the cost is paid in wall
clock every other row in this stage waits out. Read what the claims rest on,
then decide:

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

ESCALATION (operator-ratified): a reject does not block work forever — the
gate routes onward per its declared routing, to the human operator or into a
rework loop that answers your findings, so reject when the evidence says
reject; do not approve to keep things moving.

CAST YOUR VOTE — exactly once, as your last action, in ONE Bash call:

  docket vote cast ${voteId} --voter ${r.seat} --role ${role} -v <approve|approve-with-concerns|reject> --confidence <0.0-1.0> --domain-relevance <0.0-1.0> --metadata '${metadataClaim}' --summary "<one-paragraph reasoning>"

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
  --summary         ONE paragraph, on ONE line, in double quotes: your verdict's
                    reasoning and the specific evidence behind it. No line
                    breaks; escape any embedded double quote as \\". Name files,
                    shas, and commands you ran — a summary that could have been
                    written without investigating will read like one.

YOUR FINAL TEXT IS NOT DELIVERED ANYWHERE. THE CAST IS YOUR DELIVERABLE. If the
cast command errors, read the error, fix what it names, and retry ONCE. If it
still fails, end your reply with the verbatim error text and nothing else —
that is the only case where your final text matters.`
}

function probeBrief(command, servingStep) {
    return `Run exactly this one command:

  ${command}

Return its output VERBATIM as your entire final reply — every line, unedited,
no summary, no commentary, no code fence, nothing added. If the command errors,
return the error text verbatim instead.

Do not cast a vote, do not investigate, do not run anything else. You are a
read-only probe reporting what the record currently says.${servingStep ? `
You are serving ${servingStep}; usage attribution joins on that id.` : ''}`
}

function probe(command, label, phaseLabel, servingStep) {
    return agent(probeBrief(command, servingStep), {
        label,
        phase: phaseLabel,
        agentType: 'executor-read',
        model: 'haiku',
        effort: 'low',
    }).then((text) => text == null ? '' : text)
        .catch((err) => {
            log(`${label}: probe spawn error: ${err}`)
            return ''
        })
}

async function runGate(row, phaseLabel) {
    // The ballot: record-driving opened the proposal when the gate's last
    // predecessor recorded — an earlier stage this wave already awaited — so
    // one probe normally finds it. A gate with NO proposal means the
    // predecessors did not all record (a failure upstream): the gate is
    // blocked, its issue's later rows are dead for this wave, and the next
    // round routes whatever on_fail produced.
    let show = await probe(`docket step show ${row.step} --json`,
        `${row.step} · gate:show`, phaseLabel)
    // Proposal ids are project-prefixed: 1-8 upcased letters, "-V", digits
    // (docket's FormatProposalID / project set-prefix grammar), e.g. DKT-V29.
    const m = show.match(/"proposal"\s*:\s*"([A-Z]{1,8}-V\d+)"/)
    // A vote step's STATUS cannot carry the verdict: the engine records a
    // REJECTED vote as `done` when its on_fail routes machine-side (measured
    // three runs: 0-3-0 tallies rendered "gate-passed" and the conductor
    // believed it). The TALLY is the outcome; read it from the proposal.
    const tallyOutcome = async (voteId) => {
        const t = await probe(`docket vote show ${voteId} --json`,
            `${row.step} · gate:tally`, phaseLabel, row.step)
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
        return { step: row.step, status: 'gate-passed', text: show }
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
    const seats = voters.map((v) => resolveSeat(v, policy))
    log(`${row.step}: ${voteId} — seating ${seats.map((s) => s.seat).join(', ')}`)
    await parallel(seats.map((r) => () =>
        agent(seatBrief(r, voteId, row, false), {
            label: `${row.step} · seat:${r.seat}`,
            phase: phaseLabel,
            agentType: 'executor-read',
            model: r.model,
            effort: r.effort,
        }).catch((err) => {
            log(`${row.step} seat ${r.seat}: spawn error: ${err}`)
            return null
        })))

    // One re-spawn for seats whose cast never landed — tribunal.js's rule.
    let record = await probe(`docket vote show ${voteId}`,
        `${row.step} · gate:record`, phaseLabel, row.step)
    const missing = seats.filter((s) => !record.includes(s.seat))
    if (missing.length > 0) {
        log(`${row.step}: ${missing.length} seat(s) returned without a recorded ` +
            `cast (${missing.map((s) => s.seat).join(', ')}) — re-spawning each ONCE`)
        await parallel(missing.map((r) => () =>
            agent(seatBrief(r, voteId, row, true), {
                label: `${row.step} · seat:${r.seat} (retry)`,
                phase: phaseLabel,
                agentType: 'executor-read',
                model: r.model,
                effort: r.effort,
            }).catch((err) => {
                log(`${row.step} seat ${r.seat}: respawn error: ${err}`)
                return null
            })))
    }

    // `done` says only that the step COMPLETED — a rejection whose on_fail
    // routes into rework also reads done/superseded. The tally is the verdict.
    show = await probe(`docket step show ${row.step} --json`,
        `${row.step} · gate:outcome`, phaseLabel)
    if (/"status"\s*:\s*"done"/.test(show)) {
        const { outcome, tally } = await tallyOutcome(voteId)
        if (outcome === 'rejected') {
            log(`${row.step}: gate decided REJECTED (${voteId}) — engine ` +
                `routes on_fail; the conductor verifies the routing; ` +
                `skipping this issue's later stages`)
            return { step: row.step, status: 'gate-rejected', text: tally }
        }
        log(`${row.step}: gate passed — continuing`)
        return { step: row.step, status: 'gate-passed', text: show }
    }
    log(`${row.step}: gate did NOT clear (${(show.match(/"status"\s*:\s*"([a-z-]+)"/) || [])[1] || 'unknown'}) ` +
        `— skipping this issue's later stages; the conductor escalates`)
    return { step: row.step, status: 'gate-parked', text: show }
}

// GLOBAL STAGE BARRIERS (2026-08-15, superseding RUN-2's per-issue lanes).
// The lanes existed because engine stages only ordered SAME-ISSUE work, so a
// global barrier made one issue's re-review wait on another issue's slowest
// row for nothing. The staged closure changed what a stage MEANS: the engine
// now also packs CROSS-ISSUE cohort constraints into stage numbers — two
// issues' writers sharing one bounded class slot, or one scope, are placed in
// DIFFERENT stages, and per-issue lanes would run them concurrently and
// bounce the later one off `claim` (the exact corpse-spawn waste DKT-23
// measured). Stages are one schedule now; the wave runs them as one ladder.
// The residual cross-issue wait is the price of that schedule being honored —
// rows the engine certifies concurrent share a stage and still run together.
const stages = new Map()
for (const row of rows) {
    const s = Number.isInteger(row.stage) ? row.stage : 0
    if (!stages.has(s)) stages.set(s, [])
    stages.get(s).push(row)
}
const stageKeys = [...stages.keys()].sort((a, b) => a - b)

log(`wave: ${rows.map((r) => `${r.step}·${r.kind === 'executor' ? r.executor : r.kind}`).join(', ')} — policy ${(input.policyText || '').length} chars`)
log(`wave: ${rows.length} row(s) across stage(s) ${stageKeys.join('→')}`)

// Executor rows staged BEHIND a same-issue action or vote row can be
// superseded/unclaimable by the time their stage arrives (the predecessor
// held or was rejected) — a blind spawn there dies on claim CONFLICT, an
// opus corpse per occurrence (measured: 17 across 4 runs). Probe those
// rows with the same cheap read the gate path uses; skip the spawn when
// the step is no longer claimable. Fail-open: an empty probe spawns.
const gateStageByIssue = new Map()
for (const row of rows) {
    if ((row.kind === 'action' || row.kind === 'vote') && row.issue) {
        const s = Number.isInteger(row.stage) ? row.stage : 0
        const cur = gateStageByIssue.get(row.issue)
        if (cur === undefined || s < cur) gateStageByIssue.set(row.issue, s)
    }
}
function needsClaimProbe(row) {
    if (row.kind !== 'executor' || !row.issue) return false
    const s = Number.isInteger(row.stage) ? row.stage : 0
    const g = gateStageByIssue.get(row.issue)
    return g !== undefined && g < s
}

// ASK THE ENGINE WHAT IS READY, rather than inferring it from the manifest
// (DOT-226). The per-row probe above answers "did this step already settle?",
// which is the wrong question for the case that actually cost tokens: a step
// still `pending` whose `after` predecessor is not done reads as perfectly
// claimable and spawns anyway, then dies on the engine's own words — RUN-28
// wf_93e53958-2d5, STEP-693: `step verify@0 is not ready to claim: an
// `after` predecessor is not done`. Six such spawns across that run's waves,
// 3,262 output and 53,691 cache-creation tokens on claims that could only
// CONFLICT.
//
// One `next --run` read per stage replaces N per-row reads and answers the
// right question. It is only asked from the SECOND stage on: the first
// stage's rows are what the dispatch just routed, so re-asking about them
// buys nothing.
//
// `--limit` matters. It defaults to 10, and a silent truncation here would
// read as "not ready" and skip real work, so it is passed explicitly above
// the row count.
//
// FAIL-OPEN, in the same direction as every other probe: anything short of a
// parsed `"ok":true` envelope (probe spawn error, an engine error, prose, a
// shape change) returns null and the stage spawns exactly as it did before.
// An `ok:true` answer with an EMPTY step list is a real answer — nothing in
// this stage is ready — and is honored, which is the whole point.
const READY_PROBE_LIMIT_SLACK = 50

async function readyStepIds(run, rowCount, phaseLabel) {
    if (!run) return null
    const limit = rowCount + READY_PROBE_LIMIT_SLACK
    const out = await probe(`docket next --run ${run} --limit ${limit} --json`,
        `${run} · ready`, phaseLabel)
    if (!/"ok"\s*:\s*true/.test(out)) {
        if (out.trim()) log(`${run}: readiness probe unusable — spawning the stage unfiltered`)
        return null
    }
    const ids = new Set()
    for (const m of out.matchAll(/"step"\s*:\s*"(STEP-\d+)"/g)) ids.add(m[1])
    return ids
}

const waveRun = (rows.find((r) => typeof r.run === 'string' && r.run) || {}).run || ''

const byStep = new Map()
// A park observed anywhere stops every LATER stage (in-flight groups finish;
// the engine re-offers unlaunched steps after the park lifts). A CONFLICT or
// an uncleared gate kills only its own ISSUE's later rows — the chain behind
// it cannot become claimable this wave, and spawning it anyway boots corpses.
let parked = false
const deadIssues = new Set()

// TEST-BEGIN chain-dead — see the park-signals note above.
function chainDead(res) {
    if (res == null) return false
    if (res.status === 'gate-parked' || res.status === 'gate-blocked' ||
        res.status === 'gate-rejected' || res.status === 'skipped-not-claimable' ||
        res.status === 'skipped-not-ready') return true
    // Same body-scan trap as runParked: `includes('CONFLICT')` would kill an
    // issue's whole remaining chain on a judge that merely REPORTED one.
    return res.status === 'returned' && isConflictReport(res.text)
}
// TEST-END chain-dead

for (const k of stageKeys) {
    if (parked) break
    const group = stages.get(k).filter((row) => {
        if (row.issue && deadIssues.has(row.issue)) {
            byStep.set(row.step, { step: row.step, status: 'skipped-dead-issue', text: null })
            log(`${row.step}: skipped — issue ${row.issue}'s chain died at an earlier stage`)
            return false
        }
        return true
    })
    if (group.length === 0) continue
    const label = `stage ${k} (${group.length} row${group.length === 1 ? '' : 's'})`
    const ready = k === stageKeys[0] || !group.some((r) => r.kind === 'executor')
        ? null
        : await readyStepIds(waveRun, group.length, label)
    const settled = await parallel(group.map((row) => () => {
        if (row.kind === 'action') {
            // Engine-run, and normally already DONE: the record of its last
            // predecessor drove it (engine drive.go) before that record
            // returned. Nothing to spawn; the row is in the manifest so the
            // stage numbering stays transparent.
            log(`${row.step}: action step — engine-run at record time, no spawn`)
            return Promise.resolve({ step: row.step, status: 'engine-run', text: null })
        }
        if (row.kind === 'vote') return runGate(row, label)
        if (ready && !ready.has(row.step)) {
            // The engine's own answer, so no per-row probe is needed and no
            // guess is made. The step stays pending and the next dispatch
            // offers it — the same recovery as before, minus the corpse.
            log(`${row.step}: the engine does not list it as ready this stage — ` +
                `skipping the spawn; the next dispatch re-offers it`)
            return { step: row.step, status: 'skipped-not-ready', text: null }
        }
        if (!ready && needsClaimProbe(row)) {
            return probe(`docket step show ${row.step} --json`,
                `${row.step} · pre-claim`, label, row.step).then((show) => {
                // Skip only on a positively recognized TERMINAL status; empty
                // output, prose, and anything unrecognized all spawn (fail-open).
                const term = show.match(/"status"\s*:\s*"(done|superseded|skipped|failed)"/)
                if (!term) return spawn(row, label)
                log(`${row.step}: not claimable (${term[1]}) — a same-issue ` +
                    `gate or action upstream settled it; skipping the spawn`)
                return { step: row.step, status: 'skipped-not-claimable', text: show }
            })
        }
        return spawn(row, label)
    }))
    settled.forEach((res, i) => {
        const row = group[i]
        byStep.set(row.step, res || { step: row.step, status: 'spawn-failed' })
        if (chainDead(res) && row.issue) deadIssues.add(row.issue)
    })
    if (settled.some(runParked)) {
        parked = true
        log('wave: run parked mid-wave — later stages not launched; the ' +
            'engine re-offers their steps after the park lifts')
    }
}

return rows.map((row) => byStep.get(row.step) ||
    { step: row.step, status: parked ? 'not-launched-run-parked' : 'spawn-failed' })
