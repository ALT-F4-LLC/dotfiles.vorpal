#!/bin/bash

# Structured-output gate for every workflow script under
# src/user/claude_code/workflows.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# and this one is in that list. It needs only `node` — no engine, no
# database, no network, and it never runs a workflow.
#
# WHY THIS EXISTS. A workflow hands its caller one JSON value, and the caller
# acts on named fields. Free text breaks that at two seams. An agent() call
# without a `schema` returns whatever prose the agent ended with, which the
# script then parses or relays. And a return the harness cannot carry whole
# loses data silently: wave.js once returned an array with a named
# `coordination` property, and the harness's JSON transport delivered the
# elements without it.
#
# WHAT IS PINNED HERE, per workflow file:
#   1. Every agent(), countedAgent() and seat() call passes a schema: in its
#      options literal, or in a `const` options object it spreads or passes.
#      The ALLOW list below names the exceptions and why; each must match
#      exactly one call, so a stale entry fails too.
#   2. Every schema a script defines or passes inline serializes to at most
#      4096 characters. Past that bound the auto-mode classifier blocks the
#      spawn whenever it cannot review it, and agent() returns null (claude
#      2.1.289; tests/docket-groom-schema-budget.test.sh measures the groom
#      schemas this suite cannot evaluate statically).
#   3. The top-level return is not an array or an Object.assign() onto one.
#   4. The header comment documents the return shape.
#
# HOW. A small scanner blanks comments, string and template text and regex
# literals while keeping `${...}` code, so a prompt that mentions agent() or
# schema never counts; call spans are matched on parentheses in what is left.
#
# WORKFLOWS_DIR overrides the directory under test, so a mutation probe can
# point the suite at a deliberately-broken COPY under $TMPDIR and observe red
# without touching the checkout.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
WORKFLOWS="${WORKFLOWS_DIR:-${SCRIPT_DIR}/../src/user/claude_code/workflows}"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

command -v node >/dev/null 2>&1 || fatal "node is required to run this test"
[ -d "$WORKFLOWS" ] || fatal "workflows directory not found at ${WORKFLOWS}"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/workflow-structured-output.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT

cat > "${WORK}/suite.mjs" <<'JS'
import { readFileSync, readdirSync } from 'node:fs'
import { join } from 'node:path'

const dir = process.argv[2]
const files = readdirSync(dir).filter((f) => f.endsWith('.js')).sort()

let pass = 0
let fail = 0
const ok = (cond, label) => {
    if (cond) { pass++; console.log(`PASS: ${label}`) }
    else { fail++; console.error(`FAIL: ${label}`) }
}

// The harness's bound (claude 2.1.289).
const BOUND = 4096

// Calls that legitimately pass no schema, by file and whitespace-normalized
// call text.
const ALLOW = [
    { file: 'wave.js', call: 'agent(brief, options)',
      why: "countedAgent()'s pass-through; every countedAgent() call is checked instead" },
    { file: 'wave.js', call: 'agent(settleBrief(row, owner, claim, settleNote(signal, text)))',
      why: "settleStoppedReply()'s injected agent; its caller's countedAgent() call passes COMMAND_OUTPUT_SCHEMA and is checked instead" },
    { file: 'docket-postmortem.js', call: 'agent(prompt, opts)',
      why: "seat()'s pass-through; every seat() call is checked instead" },
]

// Schemas passed to agent() that no static evaluation can measure, and the
// suite that measures them.
const MEASURED_ELSEWHERE = {
    'docket-groom.js': ['JUDGE_SCHEMA', 'REGISTRY_SCHEMA', 'CLUSTER_SCHEMA'],
}
// Schemas a script defines but never passes to agent().
const NOT_PASSED = {
    'docket-groom.js': ['LEDGER_SCHEMA'],
}

// Blank comments, quoted strings, template text and regex literals to spaces
// (newlines kept, so offsets match the source); `${...}` stays code.
function codeOnly(src) {
    const out = src.split('')
    const n = src.length
    const blank = (i) => { if (i < n && out[i] !== '\n') out[i] = ' ' }
    const regexAllowed = (i) => {
        let j = i - 1
        while (j >= 0 && /\s/.test(out[j])) j--
        if (j < 0) return true
        if ('(,=:[!&|?{};+-*%<>~^'.includes(out[j])) return true
        let k = j
        while (k >= 0 && /[\w$]/.test(out[k])) k--
        return /^(return|typeof|case|of|in|void|delete|throw|new|yield|await)$/.test(out.slice(k + 1, j + 1).join(''))
    }
    function quoted(i, q) {
        blank(i++)
        while (i < n && src[i] !== q && src[i] !== '\n') {
            if (src[i] === '\\') blank(i++)
            blank(i++)
        }
        blank(i)
        return i + 1
    }
    function regex(i) {
        blank(i++)
        let cls = false
        while (i < n && src[i] !== '\n') {
            const c = src[i]
            if (c === '\\') { blank(i++); blank(i++); continue }
            if (c === '[') cls = true
            else if (c === ']') cls = false
            else if (c === '/' && !cls) break
            blank(i++)
        }
        blank(i++)
        while (i < n && /[a-z]/i.test(src[i])) blank(i++)
        return i
    }
    function template(i) {
        blank(i++)
        while (i < n) {
            const c = src[i]
            if (c === '\\') { blank(i++); blank(i++); continue }
            if (c === '`') { blank(i); return i + 1 }
            if (c === '$' && src[i + 1] === '{') { i = code(i + 2, true); continue }
            blank(i++)
        }
        return i
    }
    function code(i, nested) {
        let depth = 0
        while (i < n) {
            const c = src[i]
            const d = src[i + 1]
            if (c === '/' && d === '/') { while (i < n && src[i] !== '\n') blank(i++); continue }
            if (c === '/' && d === '*') {
                blank(i++); blank(i++)
                while (i < n && !(src[i] === '*' && src[i + 1] === '/')) blank(i++)
                blank(i++); blank(i++)
                continue
            }
            if (c === "'" || c === '"') { i = quoted(i, c); continue }
            if (c === '`') { i = template(i); continue }
            if (c === '/' && regexAllowed(i)) { i = regex(i); continue }
            if (c === '{') depth++
            if (c === '}') {
                if (nested && depth === 0) return i + 1
                depth--
            }
            i++
        }
        return i
    }
    code(0, false)
    return out.join('')
}

// The index just past the bracket that closes the one at `open`.
function closing(text, open) {
    const pair = { '(': ')', '{': '}', '[': ']' }[text[open]]
    let depth = 0
    for (let i = open; i < text.length; i++) {
        if (text[i] === text[open]) depth++
        else if (text[i] === pair && --depth === 0) return i + 1
    }
    return -1
}

// Evaluate every `const NAME = ...` with an UPPER_CASE name, at any depth, in
// file order, against the constants evaluated before it. An object or array
// initializer ends at its closing bracket; any other ends before the next
// line of code indented no deeper than the const. `mode` stands in for
// wave-usage's runtime arg, at its wider value.
function constants(src, code) {
    const scope = { mode: 'seats' }
    const failed = new Map()
    const re = /^([ \t]*)const ([A-Z][A-Z0-9_]*) = /gm
    let m
    while ((m = re.exec(code))) {
        const start = m.index + m[0].length
        let end
        if (code[start] === '{' || code[start] === '[') {
            end = closing(code, start)
        } else {
            const lines = code.slice(start).split('\n')
            let offset = lines[0].length + 1
            for (const line of lines.slice(1)) {
                const indent = line.search(/\S/)
                if (indent !== -1 && indent <= m[1].length) break
                offset += line.length + 1
            }
            end = start + offset - 1
        }
        if (end < 0) continue
        try {
            const expr = src.slice(start, end).trim().replace(/;$/, '')
            scope[m[2]] = new Function(...Object.keys(scope), `return (${expr}\n)`)(...Object.values(scope))
        } catch (e) {
            failed.set(m[2], e.message)
        }
    }
    return { scope, failed }
}

const CALL_RE = /(?<![\w$.])(agent|countedAgent|seat)\s*\(/g
const allowHits = new Map(ALLOW.map((a) => [`${a.file}|${a.call}`, 0]))

for (const file of files) {
    const src = readFileSync(join(dir, file), 'utf8')
    const code = codeOnly(src)
    const { scope, failed } = constants(src, code)
    const schemaless = []
    const passed = new Set()
    const inline = []
    let calls = 0

    let m
    CALL_RE.lastIndex = 0
    while ((m = CALL_RE.exec(code))) {
        if (/function\s+$/.test(code.slice(Math.max(0, m.index - 12), m.index))) continue
        const open = m.index + m[0].length - 1
        const end = closing(code, open)
        if (end < 0) { schemaless.push(`${m[1]}(... unbalanced at offset ${m.index}`); continue }
        calls++
        const span = code.slice(open + 1, end - 1)
        const text = src.slice(m.index, end).replace(/\s+/g, ' ')
        for (const s of span.matchAll(/\bschema\s*:\s*([A-Za-z_$][\w$]*|\{)/g)) {
            if (s[1] === '{') {
                const at = open + 1 + s.index + s[0].length - 1
                inline.push({ at, literal: src.slice(at, closing(code, at)) })
            } else {
                passed.add(s[1])
            }
        }
        if (/\bschema\b/.test(span)) continue
        // An options object held in a const: spread into the literal, or passed bare.
        const refs = [...span.matchAll(/\.\.\.([A-Za-z_$][\w$]*)/g)].map((r) => r[1])
        const bare = span.match(/,\s*([A-Za-z_$][\w$]*)\s*$/)
        if (bare) refs.push(bare[1])
        const resolved = refs.some((name) => {
            const defs = [...code.slice(0, m.index).matchAll(new RegExp(`\\b(?:const|let)\\s+${name}\\s*=\\s*\\{`, 'g'))]
            if (!defs.length) return false
            const last = defs[defs.length - 1]
            const at = last.index + last[0].length - 1
            return /\bschema\b/.test(code.slice(at, closing(code, at)))
        })
        if (resolved) continue
        const key = `${file}|${text}`
        if (allowHits.has(key)) { allowHits.set(key, allowHits.get(key) + 1); continue }
        schemaless.push(text.length > 160 ? `${text.slice(0, 160)}...` : text)
    }

    ok(calls > 0, `${file}: has agent calls to check (${calls})`)
    ok(schemaless.length === 0,
        `${file}: every agent call passes a schema${schemaless.length ? ` — schema-less: ${JSON.stringify(schemaless)}` : ''}`)

    // 2. Every defined schema and every inline one fits the bound.
    const elsewhere = MEASURED_ELSEWHERE[file] || []
    const unpassed = NOT_PASSED[file] || []
    for (const [name, value] of Object.entries(scope)) {
        if (!name.endsWith('SCHEMA') || unpassed.includes(name)) continue
        const chars = JSON.stringify(value).length
        ok(chars <= BOUND, `${file}: ${name} serializes to ${chars} characters, within ${BOUND}`)
    }
    for (const name of passed) {
        if (name in scope || elsewhere.includes(name)) continue
        ok(false, `${file}: ${name} is passed to agent() but could not be measured (${failed.get(name) || 'no top-level literal'})`)
    }
    for (const { literal } of inline) {
        let value
        try { value = new Function(...Object.keys(scope), `return (${literal})`)(...Object.values(scope)) } catch (e) { value = undefined }
        const chars = value === undefined ? Infinity : JSON.stringify(value).length
        ok(chars <= BOUND, `${file}: an inline schema serializes to ${chars} characters, within ${BOUND}`)
    }

    // 3. The top-level return is a plain value the JSON transport carries whole.
    const returns = src.split('\n').filter((line) => /^return\b/.test(line))
    const last = returns[returns.length - 1] || ''
    ok(last !== '' && !/^return\s*(\[|Object\.assign\()/.test(last),
        `${file}: the top-level return is not an array (${JSON.stringify(last)})`)

    // 4. The header documents the return shape.
    ok(/^\/\/ *(return|Return|Returns)\b/m.test(src), `${file}: the header comment documents the return`)
}

for (const a of ALLOW) {
    const hits = allowHits.get(`${a.file}|${a.call}`)
    ok(hits === 1, `allowed: ${a.file} ${a.call} matches exactly one call (${hits}) — ${a.why}`)
}

// The scanner itself: a prompt that names agent() or schema is text, not code.
const probe = codeOnly("const p = `run agent(x) with schema ${agent(q, { schema: S })}` // agent(y)\nconst r = /agent\\(/g")
ok((probe.match(/agent\(/g) || []).length === 1 && /schema: S/.test(probe),
    `scanner: only the call inside \${...} survives as code (got ${JSON.stringify(probe)})`)

console.log(`\n${pass} passed, ${fail} failed`)
process.exit(fail === 0 ? 0 : 1)
JS

node "${WORK}/suite.mjs" "$WORKFLOWS"
