export const meta = {
    name: 'wave',
    description: 'Spawn one executor per dispatched step row, routed by policy.toml. Invoke by scriptPath ONLY, with args {rows, policyText} as a real object — policy.toml is passed as TEXT, never a path; the script cannot read files.',
    whenToUse: 'Invoked by the conduct skill on an open dispatch, always as Workflow({scriptPath}) — never by name. args is {rows, policyText}: `next` rows verbatim plus the literal TEXT of policy.toml. There is no policyPath and no file access.',
}

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
        const why = {
            action: 'action steps are engine-run; not a spawn',
            human: 'human gate steps are never claimed — they are approved or ' +
                'rejected directly',
            vote: 'vote gate steps convene the tribunal — conduct routes them ' +
                'to tribunal.js, never to a wave executor',
        }[row.kind] || 'only kind:"executor" rows are spawnable'
        throw new Error(
            `wave.js: step ${row.step} is kind:${JSON.stringify(row.kind)} — ${why}. ` +
            `Route executor rows to the wave only. Refusing to route.`
        )
    }

    let hint = row.executor

    const table = (policy.resolve || []).find((e) => e.executor === hint)
    if (table) {
        let matched = null
        for (const rule of table.rule || []) {
            const labelsOk = !rule.labels || rule.labels.every((l) => labels.includes(l))
            const docOk = !rule.doc_type || labels.includes('doc:' + rule.doc_type)
            if (labelsOk && docOk) { matched = rule.to; break }
        }
        hint = matched || table.default
    }

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
    return `You are executing one step of a Docket run. Follow these obligations exactly.

YOUR ASSIGNMENT: step ${row.step} (issue ${row.issue}, run ${row.run}). This
brief was rendered for that step alone — every occurrence of ${row.step} below
is your real, already-substituted step id, NOT a template placeholder. ${row.step}
is the id you claim in obligation 1; a brief with an unfilled placeholder would
read STEP-N or \${row.step}, and this one does not.${isolationNote}

1. Claim it AND PARK THE TOKEN ON DISK${isolated ? ` — ISOLATED: run form 1' from
   obligation 0 (separate plain commands, literal paths) instead of the block
   below — the one-shot block violates your one-action-per-call discipline.
   Every rule after the block still binds you.` : ', in ONE Bash call, exactly this:'}

   \`\`\`
   docket step claim ${row.step} --owner wave:${row.step} --render --json > "$TMPDIR/${row.step}.claim.json" &&
     jq -r '.data.token'  < "$TMPDIR/${row.step}.claim.json" > "$TMPDIR/${row.step}.token" &&
     chmod 600 "$TMPDIR/${row.step}.token" &&
     jq -r '.data.packet' < "$TMPDIR/${row.step}.claim.json" &&
     cat /dev/null > "$TMPDIR/${row.step}.claim.json"
   \`\`\`

   The last command TRUNCATES the claim file rather than deleting it. Its
   contents are spent the moment the packet above is printed, so emptying it
   is enough. Same rule at step 3.

   Every path is spelled out because \`$TMPDIR\` IS SHARED BY EVERY EXECUTOR IN
   THE WAVE (measured: concurrent subagents all get the same directory). Your
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

2. Execute the brief you were handed. It is your entire contract.
${isolated && isWrite ? `
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

   \`docket step record ${row.step}${isWrite ? ' --worktree <YOUR CHECKOUT>' : ''} --artifact-file "$TMPDIR/${row.step}-<kind>.md" --metadata '{"model_requested":"${r.model_requested}","effort_requested":"${r.effort_requested}","model_resolved":"<model that served you>","effort_resolved":"<effort you ran at>"}' < "$TMPDIR/${row.step}.token"\`

   \`record\` is an exact alias of \`step complete\` — identical saga, identical
   flags — and it is the verb to use: some shells parse the bare word
   \`complete\` as their own builtin and refuse the line before docket sees it.

   RUN THIS ONE COMMAND WITH THE SANDBOX DISABLED (the Bash tool's
   dangerouslyDisableSandbox: true) — operator-authorized, 2026-08-13.
   \`record\` executes the operator's TRUSTED gate scripts, and the sandbox
   blocks their TLS trust-store access, so a sandboxed record fails
   network-dependent gates on infrastructure the gate then honestly reports
   as its own failure (measured: a vulnerability scan 0-for-9 in-sandbox,
   clean outside). The gate argv is pinned in the per-user trust store and
   the permission classifier still screens the call. Elevation is for this
   record command ONLY — every other command you run stays sandboxed.
${isWrite ? `
   \`--worktree\` names the checkout the work happened in, and the engine
   computes the recorded diff THERE. Get its literal path once with \`git
   rev-parse --show-toplevel\` and paste that in; without it the engine diffs
   the wrong tree, because your edits live in your own worktree.
` : ''}
   \`model_resolved\` is the exact model id your environment reports (e.g.
   \`claude-sonnet-5\`), never a branding form — a "[1m]" suffix in the ledger
   fragments every routing-drift query that reads it (measured, RUN-8).

   or on failure:

   \`docket step fail ${row.step} --note '<why>' < "$TMPDIR/${row.step}.token"\`

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
${isolated ? `
   IF THE RECORD IS REFUSED (guard or permission), attempt it ONCE and STOP
   TRYING FORMS. Leave your deliverables parked where the brief already has
   them —

     $TMPDIR/${row.step}.token       (intact, 0600 — do NOT truncate it)
     $TMPDIR/${row.step}-<kind>.md   (your artifact body)
     $TMPDIR/${row.step}-payload.json (your payload, when the contract has one)

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
   it (\`cat /dev/null > "$TMPDIR/${row.step}.token"\`) — the engine retires
   the token the moment the record lands, so the file is inert either way. If \`record\` or
   \`fail\` errored, KEEP the token file INTACT and stop — it is the only
   thing that can still drive this step, and losing it after a failed record
   turns a routine step failure into a zombie claim the lease must reap.

   If the token file is missing or empty, or a record is refused for a missing
   or invalid token, say so plainly and stop. Do not reconstruct or guess it.

   EVERY record carries an artifact file. The engine refuses a record without
   \`--artifact-file\` before it validates anything else — "a step completes by
   recording what it produced" — so the file is never optional. Create it WITH
   BASH (a heredoc: \`cat > "$TMPDIR/${row.step}-<kind>.md" <<'EOF' ... EOF\`)
   as a FRESH file whose name starts with your step id, then pass that path as
   \`--artifact-file\`. NEVER create this file with the Write tool: under the
   sandbox the Write tool materializes files at a DIFFERENT physical path
   than the \`$TMPDIR\` your Bash commands resolve, and the record then
   fails "no such file or directory" against a file you just wrote
   (observed: RUN-1 STEP-32). (There is no \`--artifact-kind\`: the workflow's
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
   one wave share \`$TMPDIR\`, and under a shared name a racing sibling's bytes
   — or a predecessor's leftover when your own write silently fails — get
   recorded as YOUR artifact (RUN-3's STEP-11 recorded STEP-21's summary
   exactly this way).

   A guard or sandbox refusing one of your writes is a BLOCKED condition,
   exactly like a refused record: report \`WRITE BLOCKED\`, the refusal's
   first line, and every path involved, then stop that path and record what
   you can. NEVER split, tokenize, or re-encode content to get a refused
   write past a verifier — the harness classifier reads that as evasion of a
   safety mechanism, flags your step, and the flag taints your output for
   everyone downstream.

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

if (policy.policy?.version !== 2) {
    throw new Error(
        `wave.js: policy.toml [policy] version is ${JSON.stringify(policy.policy?.version)}, expected 2 ` +
        `(the [variants]/escalate_to shape). Refusing to route against an unknown schema.`
    )
}

// Two park signals, both in-band: the claim-CONFLICT text of an agent that
// launched INTO a park ('run is not active'), and the record-status tail of
// the agent whose own record CAUSED the park ('STEP-N recorded
// (waiting-human)') — the second stops the next stage before it spawns
// corpses (measured twice on RUN-8: 5 judges launched into a park the prior
// stage's result already announced). The tail format is mandated by the
// brief's closing instruction below. Fail-open: no match keeps launching.
function runParked(res) {
    return res != null && res.status === 'returned' &&
        typeof res.text === 'string' && (
            res.text.includes('run is not active') ||
            /recorded \((waiting-human|paused)\)/.test(res.text)
        )
}

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

// PER-ISSUE STAGE LANES (RUN-2, 2026-08-11). Engine stages only order
// SAME-ISSUE work — the staging relation requires one issue — so a global
// stage barrier serialized one issue's staged re-review behind ANOTHER
// issue's slowest stage-0 row for no correctness reason (measured: DKT-20's
// judges waited on DKT-19's mutation-testing judge). Rows group into one
// lane per issue; stages ascend WITHIN a lane with an await between; lanes
// run fully parallel. An issue-less row rides a lane of its own. The
// per-agent `phase` option carries the progress grouping — the global
// phase() call is gone because lanes run concurrently and would race it.
const lanes = new Map()
for (const row of rows) {
    const lane = row.issue || `row:${row.step}`
    if (!lanes.has(lane)) lanes.set(lane, [])
    lanes.get(lane).push(row)
}

log(`wave: ${rows.map((r) => `${r.step}·${r.executor}`).join(', ')} — policy ${(input.policyText || '').length} chars`)
log(
    `wave: ${rows.length} row(s) in ${lanes.size} issue lane(s): ` +
    [...lanes.entries()].map(([name, laneRows]) => {
        const ks = [...new Set(laneRows.map((r) => (Number.isInteger(r.stage) ? r.stage : 0)))]
            .sort((a, b) => a - b)
        return `${name}×${laneRows.length}${ks.length > 1 ? ` (stages ${ks.join('→')})` : ''}`
    }).join(', ')
)

const byStep = new Map()
// One shared flag: a park observed in ANY lane stops every lane's LATER
// stages (in-flight groups finish; the engine re-offers unlaunched steps
// after the park lifts). Single-threaded event loop, so a plain flag is
// sound.
let parked = false

async function runLane(laneName, laneRows) {
    const stages = new Map()
    for (const row of laneRows) {
        const s = Number.isInteger(row.stage) ? row.stage : 0
        if (!stages.has(s)) stages.set(s, [])
        stages.get(s).push(row)
    }
    const stageKeys = [...stages.keys()].sort((a, b) => a - b)
    for (const k of stageKeys) {
        if (parked) break
        const group = stages.get(k)
        const label = `${laneName} stage ${k} (${group.length} row${group.length === 1 ? '' : 's'})`
        const settled = await parallel(group.map((row) => () => spawn(row, label)))
        settled.forEach((res, i) => {
            const row = group[i]
            byStep.set(row.step, res || { step: row.step, status: 'spawn-failed' })
        })
        if (settled.some(runParked)) {
            parked = true
            log('wave: run parked mid-wave — later stages not launched in any ' +
                'lane; the engine re-offers their steps after the park lifts')
        }
    }
}

await parallel([...lanes.entries()].map(([name, laneRows]) => () => runLane(name, laneRows)))

return rows.map((row) => byStep.get(row.step) ||
    { step: row.step, status: parked ? 'not-launched-run-parked' : 'spawn-failed' })
