export const meta = {
    name: 'sandbox-friction',
    description: 'Turn the sandbox friction ledger into a ranked summary grouped by the denied path, host, or classifier reason — the thing an allowlist or autoMode entry would name — and optionally file one dotfiles issue per group. Invoke by scriptPath ONLY, with args {ledger, cutoff, file, checkout}.',
    whenToUse: 'The operator-ruling half of the sandbox self-improving loop. sandbox-friction-hook.sh records every sandbox denial, unsandboxed retry, and classifier denial from any session in any project; this reads that ledger. Read-only unless file is true.',
    phases: [
        { title: 'Group', detail: 'one agent ranks the ledger by denied subject' },
        { title: 'File', detail: 'one agent per group files a sandbox issue from the dotfiles checkout' },
    ],
}

// Omitted models inherit the caller's model.
const AGENT_CONFIG = {
    group: { effort: 'low' },
    file: { effort: 'low' },
}
const PATH_SEGMENTS = 7
const CLASSIFIER_REASON_LENGTH = 80
const EXAMPLE_LENGTH = 100
const ERROR_DETAIL_LENGTH = 300

// Group paths by the region an allowlist entry would name: drop the trailing
// filename and limit the directory depth.
//
// File from the dotfiles checkout: `docket issue create` routes by cwd and
// has no --project flag.
//
// Subjects starting with "(" are unclassified and appear only in the summary.
//
// args: {ledger, cutoff, file, checkout}
//   ledger   — absolute path of the friction ledger (~/.claude/friction/sandbox.jsonl, expanded).
//   cutoff   — ISO-8601 UTC timestamp or null; events at or after it count.
//   file     — true files one issue per actionable group not already filed.
//   checkout — absolute path of the dotfiles checkout to file from.
//
// return: {groups:[{subject, kind, count, bypasses, repos, example}], filed:[subject], skipped:[{subject, why}]}

// TEST-BEGIN sandbox-friction-group — evaluate with the settings above; run as
// `jq -c -n -R --arg cutoff '' -f <file> <ledger>`. Prints one JSON array.
const GROUP_JQ = String.raw`
def trim_path:
    split("/") | map(select(length > 0))
    | (if (length > 0 and (.[-1] | test("[.]"))) then .[0:-1] else . end)
    | .[0:${PATH_SEGMENTS}] | "/" + join("/");

def subject:
    . as $e
    | if $e.kind == "classifier-denial" then
        # A classifier denial names no path or host. Its actionable subject is
        # the REASON, because that is what an autoMode.allow rule would have to
        # answer: a different fix from an allowlist entry, so never pooled with one.
        "classifier: " + ($e.evidence | if . == "" then "no reason given" else .[0:${CLASSIFIER_REASON_LENGTH}] end)
      else
        (( $e.evidence | capture("(?<s>[/~][^ :]{3,})[: ]*[Oo]peration not permitted") | .s | trim_path )?
         // ( $e.evidence | capture("(?<s>[a-z0-9.-]+[.][a-z]{2,})[^ ]*: tls") | .s )?
         // ( if $e.bypassed then "(bypass, no denial recorded)" else "(unclassified)" end ))
      end;

[ inputs
  | (try fromjson catch null)
  | select(type == "object")
  | select($cutoff == "" or .at >= $cutoff)
  | {subject: subject, kind: (.kind // "sandbox-denial"), bypassed: .bypassed, cwd: .cwd, command: .command}
]
| group_by(.subject)
| map({
    subject: .[0].subject,
    kind: .[0].kind,
    count: length,
    bypasses: (map(select(.bypassed)) | length),
    repos: (map(.cwd) | unique | length),
    example: .[0].command
  })
| sort_by(-.count)
`
// TEST-END sandbox-friction-group

const input = typeof args === 'string' ? JSON.parse(args) : (args || {})
if (typeof args === 'string') log('sandbox-friction: decoded args from the harness JSON-encoded transport (normal)')

if (typeof input.ledger !== 'string' || !input.ledger.startsWith('/')) {
    throw new Error(`sandbox-friction: args.ledger must be an absolute path (got ${JSON.stringify(input.ledger)})`)
}
if (input.cutoff != null && !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/.test(input.cutoff)) {
    throw new Error(`sandbox-friction: args.cutoff must be an ISO-8601 timestamp or null (got ${JSON.stringify(input.cutoff)})`)
}
const file = input.file === true
if (file && (typeof input.checkout !== 'string' || !input.checkout.startsWith('/'))) {
    throw new Error(`sandbox-friction: args.checkout must be an absolute path when file is true (got ${JSON.stringify(input.checkout)})`)
}
const {ledger, checkout} = input
const cutoff = input.cutoff == null ? '' : input.cutoff

const SANDBOX_RULE = `Run it SANDBOXED — do NOT pass dangerouslyDisableSandbox. If the sandbox denies it, report the denial text instead of retrying with the sandbox disabled.`

function shq(s) { return `'${String(s).replace(/'/g, `'\\''`)}'` }

phase('Group')
const grouped = await agent(
`Group the sandbox friction ledger with a fixed jq program. Write the program to a file with a QUOTED heredoc (the body must land byte-for-byte; do not edit it), then run it. Run exactly this, verbatim:

\`\`\`
cat > "$TMPDIR/sandbox-friction.jq" <<'GROUP_JQ_EOF'
${GROUP_JQ}
GROUP_JQ_EOF
jq -c -n -R --arg cutoff ${shq(cutoff)} -f "$TMPDIR/sandbox-friction.jq" ${shq(ledger)}; echo "exit=$?"
\`\`\`

${SANDBOX_RULE}

Return the JSON array jq printed as groups, element for element, unchanged: no rounding, no renaming, no reordering. If the ledger file does not exist or jq printed an error, return an empty groups array and the error text in a field named "error".`,
    {label: 'group:ledger', phase: 'Group', ...AGENT_CONFIG.group, schema: {
        type: 'object',
        properties: {
            groups: {type: 'array', items: {
                type: 'object',
                properties: {
                    subject: {type: 'string'},
                    kind: {type: 'string'},
                    count: {type: 'integer'},
                    bypasses: {type: 'integer'},
                    repos: {type: 'integer'},
                    example: {type: 'string'},
                },
                required: ['subject', 'kind', 'count', 'bypasses', 'repos', 'example'],
            }},
            error: {type: 'string'},
        },
        required: ['groups'],
    }},
)

if (!grouped) throw new Error('sandbox-friction: the grouping agent returned nothing')
// A missing ledger means nothing recorded yet, not a failure.
if (grouped.error && /Could not open|No such file/.test(grouped.error)) log(`sandbox-friction: no friction ledger at ${ledger}: nothing recorded yet`)
else if (grouped.error) throw new Error(`sandbox-friction: grouping failed: ${grouped.error}`)
const groups = grouped.groups
if (groups.length === 0 && !grouped.error) log(`sandbox-friction: ledger has no events${cutoff ? ` at or after ${cutoff}` : ''}`)
else log(`sandbox-friction: ${groups.length} groups${cutoff ? ` since ${cutoff}` : ''} — events/bypasses/repos kind subject`)
for (const g of groups) {
    log(`  ${g.count}/${g.bypasses}/${g.repos} ${g.kind} ${g.subject}  e.g. ${g.example.slice(0, EXAMPLE_LENGTH)}`)
}

const CLASSIFIER_REMEDY = `Auto mode denied this, so the command never ran. These accumulate toward auto
mode's pause threshold — 3 consecutive or 20 total, not configurable — and once
it pauses, prompting resumes and an unattended executor stalls on a question
nobody answers.
Decide one of: add an autoMode.allow or autoMode.environment entry in
src/user/claude_code.rs describing this action as routine for this fleet; or
record here why the denial is correct, so the next report does not re-raise it.`

const SANDBOX_REMEDY = `Decide one of: add the path to SANDBOX_TOOLCHAIN_CACHE_PATHS or the
with_sandbox_filesystem_allow_write list in src/user/claude_code.rs; add the host to
with_sandbox_network_allowed_domains; add the tool to with_sandbox_excluded_commands
if it genuinely cannot be sandboxed; or record here why it should stay denied, so
the next report does not re-raise it.`

function description(g) {
    return `Recorded by sandbox-friction-hook.sh.

Kind: ${g.kind}
Subject: ${g.subject}
Events: ${g.count} (of which ${g.bypasses} were unsandboxed retries)
Distinct checkouts affected: ${g.repos}
Example command: ${g.example}

${g.kind === 'classifier-denial' ? CLASSIFIER_REMEDY : SANDBOX_REMEDY}`
}

function filePrompt(g) {
    const title = `Sandbox friction: ${g.subject} hit ${g.count} times across ${g.repos} checkouts`
    return `File one docket issue for a sandbox friction group unless one already names its subject. Run exactly this, verbatim, as ONE shell invocation. The cd is load-bearing: docket routes \`issue create\` by cwd and has no --project flag, so the issue must be created from the dotfiles checkout.

\`\`\`
cd ${shq(checkout)} || { echo "exit=cd-failed"; exit 0; }
if docket issue list --label sandbox --json | grep -qF -- ${shq(g.subject)}; then
  echo "ALREADY-FILED"
else
  cat > "$TMPDIR/sandbox-friction-issue.md" <<'ISSUE_BODY_EOF'
${description(g)}
ISSUE_BODY_EOF
  docket issue create --title ${shq(title)} --description "$(cat "$TMPDIR/sandbox-friction-issue.md")" --label sandbox -f src/user/claude_code.rs --scope src/user/claude_code.rs
  echo "exit=$?"
fi
\`\`\`

${SANDBOX_RULE}

Report action "already-filed" when the output was ALREADY-FILED, "filed" when docket issue create printed exit=0, and "failed" otherwise. Put the command's output, verbatim and unedited, in detail (the issue id docket printed, or the error). Do not create the issue any other way, do not edit the title or description, and do not run anything else.`
}

async function fileGroups(groups) {
    phase('File')
    const skipped = groups
        .filter((g) => g.subject.startsWith('('))
        .map((g) => {
            log(`sandbox-friction: not filing ${g.subject} (${g.count} events): unclassified`)
            return {subject: g.subject, why: 'unclassified subject names nothing to act on'}
        })
    const actionable = groups.filter((g) => !g.subject.startsWith('('))

    const outcomes = await pipeline(actionable,
        (g, _item, i) => agent(filePrompt(g), {
            label: `file:${i + 1}/${actionable.length}`,
            phase: 'File',
            ...AGENT_CONFIG.file,
            schema: {
                type: 'object',
                properties: {
                    action: {type: 'string', enum: ['filed', 'already-filed', 'failed']},
                    detail: {type: 'string'},
                },
                required: ['action', 'detail'],
            },
        }),
    )

    const results = actionable.map(({subject}, index) => {
        const outcome = outcomes[index]
        if (!outcome) {
            log(`sandbox-friction: DROPPED ${subject}: filing agent returned nothing`)
            return {subject, why: 'filing agent returned nothing'}
        }
        if (outcome.action === 'filed') {
            log(`sandbox-friction: filed ${subject}: ${outcome.detail.trim().split('\n').pop()}`)
            return {subject, why: null}
        }
        if (outcome.action === 'already-filed') {
            log(`sandbox-friction: already filed, skipping ${subject}`)
            return {subject, why: 'already filed'}
        }
        const detail = outcome.detail.slice(0, ERROR_DETAIL_LENGTH)
        log(`sandbox-friction: could not file ${subject}: ${detail}`)
        return {subject, why: `failed: ${detail}`}
    })
    return {
        filed: results.filter((result) => result.why === null).map((result) => result.subject),
        skipped: [...skipped, ...results.filter((result) => result.why !== null)],
    }
}

// A workflow body may return only once, at column 0, at the end: the parse
// gate neutralizes that one keyword and nothing else.
const {filed, skipped} = file && groups.length > 0
    ? await fileGroups(groups)
    : {filed: [], skipped: []}

return {groups, filed, skipped}
