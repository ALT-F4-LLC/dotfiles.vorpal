---
name: design-qa
description: >
  Post-implementation QA of a shipped user-facing surface against its `docs/ux/` spec; emits
  a structured QA report. Driven by `@ux-designer`; format authority for verdict/severity/sections.
  Invoke after the spec is implemented (not for spec review — that's `design-review`).
  Trigger: "design QA", "run design QA", "verify implementation against UX spec", "QA the shipped UX".
argument-hint: "<scope>"
allowed-tools: ["AskUserQuestion", "Bash", "Glob", "Grep", "Read", "Monitor"]
---

<!-- CANONICAL:BANNER:BEGIN -->
> **CRITICAL:** (1) Do NOT commit ANY changes (no `git add`, no `git commit`, no `git push`) unless EXPLICITLY instructed by the user. (2) This is a leaf skill. You MUST NOT spawn sub-agents, invoke `Skill()` recursively, use `Agent()` or `SendMessage`, or form/manage a team. The calling agent handles peer messaging and Docket comments after this skill returns.
<!-- CANONICAL:BANNER:END -->

# Design QA — Verify Implementation Against UX Spec

You are the **Design QA Reviewer**. Walk through every workflow in a `docs/ux/` spec, verify the implementation matches (interactions, states, error handling, copy, layout), and emit a structured QA report into the calling agent's context — no file is written. This skill is the format authority: verdict ladder, severity ladder, required sections, validation.

<!-- CANONICAL:DOCS-PATHS-LOCAL:BEGIN -->
**Docs paths (this skill).** Master: `~/.claude/skills/team-doctrine/references/docs-paths.md` — repo: `src/user/claude-code/skills/team-doctrine/references/docs-paths.md`. Writes: none. Reads: `docs/ux/` (docs/spec/ is always singular).
<!-- CANONICAL:DOCS-PATHS-LOCAL:END -->

## Role Detection

Callable ONLY by `@ux-designer`. Any other caller ABORTS:

```
Error: Skill(design-qa) is restricted to @ux-designer. Calling agent: {agent}.
```

## Argument Handling

The argument is a single positional `<scope>` (free-text; extra positional args are ignored). If missing or empty:

```
Error: Usage: Skill(design-qa, "<scope>") — name what to QA (UX spec path, Docket issue ID, or "uncommitted").
```

**Scope resolution** (first match wins):

| Form | Detection | Sources |
|---|---|---|
| UX spec path | `Bash test -e {path}` and path matches `docs/ux/.*\.md` | `Read` the spec; locate the implementation surface from the spec's frontmatter and body |
| Docket issue ID | `docket issue show {scope} --json` exits 0 | Read issue + comments + file attachments; locate the linked UX spec |
| Literal `uncommitted` | exact match | `git diff` + `git diff --staged` + `git diff --stat HEAD`; identify the relevant spec from changed paths |

If `<scope>` matches none of the above, ABORT:

```
Error: Could not resolve <scope>: '{scope}'. Expected UX spec path, Docket issue ID, or "uncommitted".
```

## When to Use

`@senior-engineer` reports user-facing implementation complete against a `docs/ux/` spec; `@sdet` reports a design deviation to adjudicate; or the operator/team-lead requests a design audit against an existing spec.

## Doubling Rule

Panel sizing, opt-up triggers, ephemeral lifecycle, and verdict reconciliation are owned by `~/.claude/agents/team-lead.md` Rule 8 / Rule 7 / step 14. Skill-specific delta only:

- **Seats**: single (default) = persistent `ux-advisor` via SendMessage; doubled = `ux-advisor` + one ephemeral `design-qa-{N}`.
- **Finding-merge dedupe key**: `(spec section, surface)`.
- **Degraded-fallback annotation**, verbatim: `DEGRADED: single-reviewer (ephemeral failed 2×)`.

## When NOT to Use

<!-- COUPLING: this skill is part of the report-emission family (code-review-verdict, verify-ac, design-qa, design-review) — update all 4 in lockstep when adding/removing a sibling skill. -->
- Peer review of a draft UX spec or design proposal (nothing shipped yet) — `Skill(design-review)`.
- Acceptance-criteria verification against an issue's criteria — `Skill(verify-ac)` (@sdet).
- Production code-quality review — `Skill(code-review-verdict)`.
- Authoring or revising the UX spec itself — `Skill(ux-spec)`.

## Pre-flight

1. **Detect role**; ABORT if the caller is not `@ux-designer`.
2. **Resolve `<scope>`**; ABORT if unresolvable.
3. **Read the UX spec** — capture path, frontmatter `maturity` (and `status` if present), the workflow list, and the spec's §9 Handoff Notes MVP cutline: components deferred past the cutline are out of QA scope (record under Acceptable Deviations, never Blockers). `maturity: draft` is a finding, not an abort. If no spec can be located, ABORT: `Error: Could not locate UX spec for <scope>: '{scope}'. Attach the spec to the issue or pass the spec path directly.`
4. **Identify the implementation surface** from the spec (CLI command, generated config, error messages, rendered UI, API endpoint); confirm it appears in the changed paths (`git diff --stat` / issue attachments).
5. **Empty-implementation guard**: if no implementation surface exists yet, ABORT: `Error: No implementation surface found for spec '{spec_path}'. Design QA requires shipped implementation — use Skill(design-review, ...) for spec-only review.`

## QA Procedure

**Verify behavior, not code.** Trace user-facing output (CLI help text, error messages, generated config bytes, rendered UI, exit codes), not just source; when directly testable, test it — a spec matching the code but not the experience is a false positive.

1. **Walk every workflow in the spec** — interactions, states, transitions, error branches, success path, accessibility hooks, copy.
2. **Test edge cases** — empty inputs, error states, overloaded inputs, degraded mode, missing dependencies, NO_COLOR for TUI/CLI, viewport breakpoints for web. For externally-referenced media, confirm the rendered content — not just HTTP 200 or ref presence: a dead payload (broken-image placeholder, "content not available") passes liveness checks but fails the spec.
3. **Render before any Pass on static-export / slide / visual surfaces** — "build green" is not a render pass: a clean export can still emit broken-image placeholders or dead embeds. Render to image and visually READ the output at real delivery resolution: run `render_verify.sh <arm>` (`html`/`tui`/`cli`, dispatched by surface class; canonical table in `~/.claude/agents/ux-designer.md` §Render mechanism by surface class), then `Read` the captured artifact. A missing or broken render is a Blocker.
4. **Check accessibility implementation** against the implementation-level column of `~/.claude/skills/design-review/references/accessibility-checklist.md` (repo: `src/user/claude-code/skills/design-review/references/accessibility-checklist.md`) — measure rendered contrast, drive the keyboard, inspect the accessibility tree; token values alone prove nothing.
5. **Trace cross-surface consistency** — if the spec sets precedent, verify the same concept uses the same name and copy across surfaces.
6. **Decide verdict** per the ladder:

| Verdict | Meaning |
|---|---|
| Pass | Every workflow matches the spec; no Blocker or Concern findings |
| Pass with Issues | Core paths match; one or more Concerns, no Blockers; calling agent annotates the caveats |
| Fail | One or more Blockers: broken workflow, missing critical error state, accessibility regression, or copy/precedent divergence on a shipped surface |

**Severity ladder** (for the Issues table):

| Severity | Meaning |
|---|---|
| Blocker | Must fix before sign-off: broken workflow, missing critical error state, accessibility regression, cross-surface precedent violation, missing/broken render on a static-export or visual surface |
| Concern | Should fix or explicitly justify: spec deviation affecting usability, missing edge case, inconsistent copy, accessibility gap on non-critical path |
| Suggestion | Consider for this or future iteration: polish, minor improvement |
| Praise | Pattern worth highlighting — routes to `What's Implemented Well`, not `Issues` |

**Common discipline:**

- **Report every finding — do NOT self-filter.** Report each issue found, including low-severity and uncertain ones, tagged with severity (classification, not suppression); filtering happens downstream. Declining to report a finding because it seems minor is a recall defect.
- **Evidence per finding.** Every Blocker/Concern row's Description names the observed evidence (file:line, command + observed output, generated bytes, or surface state) AND the expected-per-spec target (copy text, state, interaction) so @senior-engineer can act without a follow-up consult. Banned confidence phrases: "clearly", "obviously", "should work", "definitely", "100%", "guaranteed".
- **Name the governing HIG principle where one applies** (Purpose, Agency, Responsibility, Familiarity, Flexibility, Simplicity, Craft, Delight — definitions: `~/.claude/agents/ux-designer.md` §Core Principles). When no principle grounds a finding, still report it — note "no HIG principle — candidate reviewer preference" so the downstream reconciler weighs it; the principle grounds a finding, it never gates reporting one.
- **Accept reasonable engineering tradeoffs** — deviations that don't affect usability go under Acceptable Deviations with their rationale, so the calling agent can decide how to communicate them.
- Ask when spec intent is genuinely ambiguous and the answer is not in the spec (standalone: `AskUserQuestion`; team mode: route through the calling agent).

## Output Contract

Emit the QA report verbatim into the calling agent's context. Do not echo the raw diff, save to disk, or add prose outside the format. If the harness blocks this skill's invocation, render the report directly per THIS format authority — never an improvised structure.

```
## Design QA: {Spec Title}

### Spec Reference
- Path: {docs/ux/...}
- Maturity / status: {maturity from frontmatter — and status if present}
- Surface(s): {CLI / TUI / Web / API / Config / Docs}

### Verdict
One of: **Pass** / **Pass with Issues** / **Fail**

### Issues

| # | Severity | Spec Section | Description |
|---|---|---|---|
| 1 | Blocker / Concern / Suggestion | {spec heading or "Cross-surface"} | {what's wrong + expected per spec + observed in implementation} |
| ... | | | |

(If no issues: write "None" in place of the table.)

### What's Implemented Well
- {praise — pattern + why it works}
- ... or "None to highlight"

### Acceptable Deviations
- {deviation} — {engineering rationale + why it does not affect usability}
- ... or "None"

### Recommendation
{One paragraph: verdict + concrete next steps for the calling agent — e.g., route Blockers to @senior-engineer, escalate spec ambiguity to operator, propose spec revision}

Design QA report emitted ({verdict}).
```

## Validation Before Emit

Stage and lint in a SINGLE Bash call — prefer the stdin form so there is no temp path to get wrong (shell state does not persist between Bash calls, and doubled panels share one `$TMPDIR`, so a hand-rolled fixed path races):

```
~/.claude/scripts/report_stage_lint.sh design-qa "$DRAFT_FILE"
```

Exit codes:

- **0** — emit the report in the calling agent's context.
- **1 (validation failure)** — ABORT; correct (quoting the script's stderr) and re-invoke: `Error: validation failed: {section/field} — {detail}.`
- **2 (infra/usage)** — do NOT hard-block: emit the report with `lint not run (infra: {reason})` appended after the trailing confirmation line and flag the infra failure to the caller.

Every check in this report's checklist is text-decidable and lives in the validator: verdict on the ladder and consistent with severity counts (any Blocker ⇒ Fail; any Concern with no Blockers ⇒ Pass with Issues; none ⇒ Pass); every Blocker/Concern row cites a non-empty Spec Section (the literal `"Cross-surface"` is accepted) and non-empty implementation evidence; required sections in order; placeholder and banned-phrase scans.

## Save & Return

End with the confirmation line:

```
Design QA report emitted ({verdict}).
```

The in-context emission is the working artifact; the deliverable is the calling agent's same-turn SendMessage of the structured verdict (team mode: to team-lead; standalone: to the peer per `~/.claude/agents/ux-designer.md` Inter-Agent Communication triggers, e.g. Fail with Blocker → @senior-engineer + team-lead). The calling agent also owns: mirroring the QA outcome as a Docket comment using `[UX→@agent] {summary}`, and proposing a spec revision via `Skill(ux-spec)` when QA reveals a spec ambiguity rather than an implementation defect.

On any abort: emit `Error: {one-line cause}` and end without producing a report.
