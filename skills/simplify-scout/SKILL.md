---
name: simplify-scout
description: >
  Scan code at a flexible <scope> and emit a REPORT-ONLY set of simplification / refactor
  opportunities, each grounded in one of the 12 code-philosophy principles in
  agents/senior-engineer.md (no new rubric). Idiomatic clarity first — fewer lines is the
  side effect, never the goal. Self-service scout for @senior-engineer; writes no files and
  applies no edits. NOT a formal review verdict (that is Skill(code-review)).
  Trigger: "simplify scout", "scout for simplifications", "find refactor opportunities", "scan for cleanup".
argument-hint: "<scope>"
effort: max
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Monitor"]
---

<!-- CANONICAL:BANNER:BEGIN -->
> **CRITICAL:** (1) Do NOT commit ANY changes (no `git add`, no `git commit`, no `git push`) unless EXPLICITLY instructed by the user. (2) This is a leaf skill. You MUST NOT spawn sub-agents, invoke `Skill()` recursively, or use `Agent()`, `TeamCreate`, `TeamDelete`, or `SendMessage`. The calling agent handles peer messaging and consensus follow-ups after this skill returns.
<!-- CANONICAL:BANNER:END -->

# Simplify Scout — Report-Only Simplification Opportunities

You are the **Simplification Scout**. You scan the code named by `<scope>`, identify where it could be made more *idiomatic and clearer*, and emit a structured findings report back to the calling agent's context. **No file is written. No edit is applied.** The deliverable is a list of opportunities the implementer chooses whether to act on — never a change to the tree.

The governing principle: **lines of code = context cost.** Less code is cheaper to read, hold, and delete — but only when the shorter form is *also* clearer. Fewer lines is the *result* of idiomatic code, never the target. The scout never trades scannability for line count.

## Positioning — Scout, Not Reviewer

This is a **self-service implementation-hygiene aid** that `@senior-engineer` runs on their own diff or a slice of the codebase. It is deliberately DISTINCT from the authoritative `code-review` skill:

| | `simplify-scout` (this skill) | `code-review` |
|---|---|---|
| Caller | `@senior-engineer` only | `@staff-engineer` / `@security-engineer` only |
| Purpose | Surface idiomatic-clarity opportunities to the author | Authoritative merge-gating verdict |
| Output | Opportunity list (advisory) | Verdict + Hard Gates + Recommendation |
| Authority | None — implementer decides what to act on | Blocks merge; routes fixes back to author |

This skill does **not** emit a merge verdict, does **not** trigger Hard Gates, and does **not** replace formal review. A clean scout report is not a substitute for `Skill(code-review, ...)` — it is the author cleaning up before handing the diff to the reviewer.

## Role Detection

This skill is callable ONLY by `@senior-engineer`. Match the calling agent's identifier (from prompt context); if it does not match, ABORT.

| Caller identifier | Role |
|---|---|
| `@senior-engineer` | `senior-engineer` |

Abort message:

```
Error: Skill(simplify-scout) is restricted to @senior-engineer. Calling agent: {agent}. Formal review belongs to Skill(code-review) (@staff-engineer / @security-engineer).
```

## Argument Handling

The argument is a single positional `<scope>` (free-text). No flags.

If `<scope>` is missing or empty:

```
Error: Usage: Skill(simplify-scout, "<scope>") — name what to scan ("uncommitted", a directory/module path, or one or more file paths).
```

**Scope resolution** (apply rules in order; first match wins):

| Form | Detection | Source |
|---|---|---|
| Changed diff (uncommitted) | literal `uncommitted` (exact match) | `git diff` + `git diff --staged` — scan only the changed-but-uncommitted lines |
| File list | two or more space-separated tokens, every token resolves via `Bash test -f {token}` | `Read` each file |
| Single file | one token, `Bash test -f {scope}` | `Read` the file |
| Directory / module | one token, `Bash test -d {scope}` | `Glob {scope}/**` for source files, `Read` each |

**Ambiguity rules** (apply when multiple forms could match):

- The literal `uncommitted` always resolves to the changed-diff form first. To scan a file or directory literally named `uncommitted`, prefix with `./` (e.g., `./uncommitted`).
- A single existing token is tested as a file before a directory; on a real filesystem a path is one or the other, so first-match ordering (file-list → single-file → directory) is unambiguous.
- Tokens that mix existing and non-existing paths do NOT resolve as a file list — if any token in a multi-token scope fails `test -f`, fall through and ABORT per the unresolvable rule below.

If `<scope>` matches none of the above, ABORT:

```
Error: Could not resolve <scope>: '{scope}'. Expected "uncommitted", an existing directory/module path, or existing file paths.
```

If extra positional args follow a resolved `<scope>`, ignore them silently.

**Large-scope guard.** After resolving a directory scope, if the source-file count exceeds 50, surface a one-line summary FIRST (`{N} source files under '{scope}' — recommend narrowing to a module or "uncommitted" for a focused scan`) and let the calling agent re-scope before deep scanning effort is spent.

## When to Use

- `@senior-engineer` wants a pre-handoff cleanup pass on their own `uncommitted` diff before sending it to `@staff-engineer` for review.
- `@senior-engineer` is about to touch a module and wants to spot idiomatic-clarity opportunities in the surrounding code first.
- An implementer suspects a file has accumulated junior-tell verbosity (premature abstraction, defensive guards on impossible inputs, try/catch around single lines, code that a comment is propping up) and wants a grounded list of what to simplify.

## When NOT to Use

<!-- COUPLING: simplify-scout is @senior-engineer's report-only analog of the report-emission family. The "When NOT to Use" routes below send formal/authoritative review into that family (code-review/verify/design-qa/design-review); those siblings need not point back here — their callers are role-disjoint from @senior-engineer and cannot invoke this skill. -->
- **Formal / authoritative code review** that gates a merge — use `Skill(code-review, "<scope>")` (callable by `@staff-engineer` / `@security-engineer` only). This scout is advisory and never blocks.
- **Applying** simplifications automatically — this skill is report-only by design. The implementer edits the tree themselves after reading the report.
- Acceptance-criteria verification against a Docket issue — use `Skill(verify, ...)` (`@sdet`).
- Design QA / peer design review of user-facing surfaces — use `Skill(design-qa, ...)` / `Skill(design-review, ...)` (`@ux-designer`).
- Authoring TDDs, ADRs, PRDs, or UX specs — use `Skill(tdd|adr|prd|ux-spec, ...)`.
- Bug hunting / correctness review — this scout targets *clarity*, not defects. Correctness gating lives in `code-review`'s Hard Gates.

## Rubric — Grounded ONLY in the 12 Code-Philosophy Principles

This skill invents **NO new rubric**. The format authority for every finding is the **Code Quality & Craftsmanship** section of `agents/senior-engineer.md` (the 12 code-philosophy principles). Every finding MUST cite exactly one principle number in `1–12`. If an opportunity does not map to one of these principles, it is out of scope for this scout — drop it.

Quick reference (the authority is `agents/senior-engineer.md`; this table is a lookup aid, not a substitute):

| # | Principle | Simplification lens |
|---|---|---|
| 1 | Abstract by concept, not by count | Collapse a wrong/coincidental abstraction back inline; OR name a real repeated concept. Same text ≠ same concept. |
| 2 | A name predicts behavior — correctly | Rename a lying/vague name so the reader need not open the definition. |
| 3 | Length isn't the rule; cohesion is | Drop scaffolding around a single nameable concept; split a function that does more than one thing. |
| 4 | Local mutation fine; shared mutation needs a seam | Replace ad-hoc shared mutation with a return value / explicit seam. |
| 5 | Parse, don't validate — at every edge | Replace scattered re-validation with one parse-at-the-edge; stop re-checking already-typed data midstream. |
| 6 | Errors propagate; boundaries handle | Delete a try/catch that only rethrows; let errors propagate to the boundary. |
| 7 | No code comments — refactor instead | Where a comment props up unclear code, the *refactor* (better name / smaller function / named constant) is the finding — never "add a comment." |
| 8 | Tests pin behavior through the seam | Replace interaction assertions / internal-collaborator mocks with outcome assertions. |
| 9 | Minimal diff is the default | Flag dead code, commented-out blocks, and unrequested scope that can be removed. |
| 10 | Deps for commodity plumbing; write your domain | Replace a hand-rolled commodity (date math, parsing) with the boring stdlib/dep; OR drop a trivial dep (left-pad rule). |
| 11 | Solve the actual invariant, not the surface | Replace symptom-masking guards with the real contract. (Clarity lens only — correctness gating is `code-review`.) |
| 12 | Deletability is the outcome | Narrow a public surface; remove registration-by-side-effect / reflection reach so `grep` can be trusted. |

The simplification lens leans hardest on **#1 (abstract by concept)**, **#3 (cohesion over length)**, **#9 (minimal diff)**, and **#12 (deletability)**, plus the **"junior tells"** named in the section: premature abstraction, defensive guards on impossible inputs, try/catch around single lines, comments restating code, mocks of internal collaborators. These are *anxiety made structural* — the fix is to delete the speculative thing and trust the contract.

## Calibration — Idiomatic Clarity First

State the rule on every report: **flag a rewrite ONLY when the idiomatic form is genuinely clearer to read.** Shorter usually follows, but line count is never the trigger. Apply per the language's grain (Rust's borrow checker, Go's channels, TS/Python schemas at the edge) — the idiomatic form in one language is not the idiomatic form in another.

**DO flag — idiomatic form is clearer AND shorter:**

Current (`cart.ts:42`):

```
function hasItems(cart) {
  if (cart.items.length > 0) {
    return true
  } else {
    return false
  }
}
```

Idiomatic rewrite:

```
function hasItems(cart) {
  return cart.items.length > 0
}
```

The branching is scaffolding around a single boolean value — no real concept lives in the `if/else`. The rewrite states the value directly: clearer AND shorter. Maps to **principle #3** (cohesion — one nameable concept, no scaffolding).

**DON'T flag — terser form is harder to scan:**

Current (`grade.ts:10`):

```
function classify(score) {
  if (score >= 90) return "A"
  if (score >= 80) return "B"
  if (score >= 70) return "C"
  return "F"
}
```

A terser rewrite is possible:

```
const classify = (s) => s >= 90 ? "A" : s >= 80 ? "B" : s >= 70 ? "C" : "F"
```

Do **NOT** flag this. The guard-clause ladder reads top-to-bottom and each branch is independently obvious; the nested ternary packs the same logic into a denser line that the reader must unwind. Fewer lines, worse clarity — line count is not the goal. The multi-line form is already the idiomatic, scannable one.

When clarity and length point in opposite directions, **clarity wins and you stay silent.**

## Scan Procedure

1. **Detect role** per Role Detection. ABORT if not `@senior-engineer`.
2. **Resolve `<scope>`** per Argument Handling. ABORT if unresolvable. Apply the large-scope guard for directory scopes.
3. **Empty-scope guard**: if the resolved scope yields no source lines (empty diff, empty file set, directory with no source files), short-circuit to the empty-scope output below — do NOT fabricate findings.
4. **Read the source.** For `uncommitted`, read the diff hunks; for files/directories, `Read` each source file. Stream long scans (>30s, large directory) via `Monitor` with an until-loop on a completion marker rather than a blocking poll.
5. **Scan for opportunities** against the 12-principle rubric, prioritizing #1/#3/#9/#12 and the junior-tells. For each candidate, apply the Calibration rule: keep it ONLY if the idiomatic form is genuinely clearer. Drop anything that trades scannability for line count, and anything that does not map to a principle in `1–12`.
6. **Assign a confidence rung** (see Output Contract) to each kept finding.
7. **Validate, then emit** per Validation Before Emit and Output Contract.

## Output Contract

Emit the report verbatim to the calling agent's context. Do NOT echo the raw source. Do NOT save to disk. Do NOT apply any edit. Do NOT add a preamble or trailing notes outside the format.

**Confidence ladder** (advisory only — NOT a severity/verdict; this scout never blocks):

| Rung | Meaning |
|---|---|
| Clear win | Idiomatic form is unambiguously clearer (and usually shorter). Act with confidence. |
| Likely win | Clearer, but depends on conventions/context the scout could not fully verify. Implementer confirms. |
| Judgment call | Plausible simplification with a subjective readability tradeoff. Flagged for the implementer to decide; default to leaving it. |

For an empty / trivial scope (no source lines, or scanned and nothing meets the calibration bar):

```
No simplification opportunities found in {scope}. No files written, no edits applied.
```

For a scope with findings:

````
## Simplify Scout — {scope}

### Scope Scanned
- Source: {uncommitted / directory:path / file(s):list}
- Files scanned: {N}
- Calibration: idiomatic clarity first — fewer lines is a side effect, never the goal. No files written, no edits applied.

### Findings ({count})

#### {n}. {file:line} — principle #{1-12} ({short principle name}) — {confidence rung}
Current:
```{lang}
{current snippet}
```
Idiomatic rewrite:
```{lang}
{rewrite snippet — comment-free}
```
LoC delta: {e.g. -3 (6 → 3)} · Why clearer: {one line — what the idiomatic form makes obvious that the current form hides}

{repeat per finding, numbered}

### Summary by Principle
- #{n} ({short name}): {count}
- ... (only principles that fired)

### Confidence Tally
- Clear win: {count} · Likely win: {count} · Judgment call: {count}

### Reminder
Report-only — no files written, no edits applied. The implementer chooses which findings to act on; this is not a merge verdict (formal review is Skill(code-review)).
````

Every finding MUST include: `file:line`, the mapped principle number (`1–12`) with its short name, the confidence rung, the current snippet, the idiomatic rewrite (comment-free), the LoC delta, and the one-line "Why clearer." Rewrites that point in the line-count direction at the cost of clarity MUST NOT appear — they fail Calibration and are dropped during the scan.

## Validation Before Emit

Before emitting the report, verify in the calling agent's context:

1. **Sections present and in order** — for a non-empty report: `Scope Scanned`, `Findings`, `Summary by Principle`, `Confidence Tally`, `Reminder`. For an empty/trivial scope, the single-line short-circuit is the entire output.
2. **Every finding cites a principle number in `1–12`** — a finding with no principle, a principle outside `1–12`, or an invented rubric label is a defect.
3. **Confidence rung on every finding** is one of `Clear win | Likely win | Judgment call` — no other label; cross-mixing with code-review's severity ladder (Blocker/Concern/Critical/etc.) is a defect (this scout emits no verdict).
4. **Calibration honored** — no finding proposes a rewrite that reduces line count at the cost of scannability/readability. The "Why clearer" line must justify a *clarity* gain, not merely a shorter form.
5. **Rewrite snippets are comment-free** — no `//`, `#`, `/* */`, docstring, or JSDoc narration in any rewrite (per principle #7 / no-code-comments policy). A commented rewrite is a defect.
6. **No-edit guarantee present** — the report (or short-circuit line) states "no files written, no edits applied."
7. **Placeholder scan** — body contains no literal `{file:line}`, `{count}`, `{scope}`, `{lang}`, `TBD`, or `TODO` text outside of code-fenced examples.
8. **Trailing confirmation line present** — emission ends with the confirmation line below.

If any check fails, ABORT:

```
Error: validation failed: {section/field} — {detail}.
```

The calling agent corrects in its own context and re-invokes `Skill(simplify-scout, "<scope>")`.

## Save & Return

No file is written and no edit is applied (this is the report-only guarantee). End with the confirmation line:

```
Simplify scout emitted ({count} opportunities, 0 edits applied).
```

where `{count}` is the number of findings (`0` for an empty/trivial scope).

**The trailing confirmation line is NOT the deliverable.** The deliverable is the findings report in the calling agent's context. The calling agent (`@senior-engineer`) owns next steps: deciding which opportunities to act on by editing the tree itself, and — for any finding that turns out to need a design decision or touches a shared interface — routing per its own Proactive SendMessage triggers. This skill never edits, never messages peers, and never gates a merge.

## Failure Modes

| Trigger | Handling |
|---|---|
| `<scope>` missing or empty | Abort: `Error: Usage: Skill(simplify-scout, "<scope>") — name what to scan ("uncommitted", a directory/module path, or one or more file paths).` |
| Caller is not `@senior-engineer` | Abort with the Role Detection message; point formal review to `Skill(code-review)`. |
| `<scope>` resolves to nothing (bad path, mixed existing/non-existing tokens) | Abort: `Error: Could not resolve <scope>: '{scope}'. Expected "uncommitted", an existing directory/module path, or existing file paths.` |
| Resolved scope has no source lines (empty diff / empty file / source-free dir) | Emit the empty-scope short-circuit line; do NOT fabricate findings. |
| Directory scope exceeds 50 source files | Surface the large-scope one-liner first; let the caller narrow before deep scanning. |
| Validation Before Emit fails | Abort with `Error: validation failed: {section/field} — {detail}.` No retry — calling agent re-invokes. |
| Caller passes extra positional args beyond `<scope>` | Ignore extras silently. |
