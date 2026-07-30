---
name: design-review
description: >
  Conduct a peer design review on a UX spec, draft design, or user-facing surface and emit
  a structured review report across six UX dimensions. Loaded into the calling agent's context;
  the calling agent (`@ux-designer`) drives the review, the skill enforces the format authority —
  six dimensions, severity ladder, recommendation ladder, required sections, validation rules.
  No file written; the report is emitted into the agent's context.
  Invoke BEFORE implementation (spec/draft review). For post-implementation verification use Skill(design-qa). Trigger: "design review", "review UX spec", "peer design review", "review this design".
argument-hint: "<scope>"
allowed-tools: ["AskUserQuestion", "Bash", "Glob", "Grep", "Read", "Monitor"]
---

<!-- CANONICAL:BANNER:BEGIN -->
> **CRITICAL:** (1) Do NOT commit ANY changes (no `git add`, no `git commit`, no `git push`) unless EXPLICITLY instructed by the user. (2) This is a leaf skill. You MUST NOT spawn sub-agents, invoke `Skill()` recursively, use `Agent()` or `SendMessage`, or form/manage a team. The calling agent handles peer messaging and Docket comments after this skill returns.
<!-- CANONICAL:BANNER:END -->

# Design Review — Peer Review of a Design Artifact

You are the **Design Reviewer**. Conduct a peer design review on the artifact named by `<scope>` (UX spec, draft, design proposal, or inline surface description) and emit a structured report into the calling agent's context — no file is written. This skill is the format authority: six UX dimensions, severity ladder, recommendation ladder, required sections, validation.

<!-- CANONICAL:DOCS-PATHS-LOCAL:BEGIN -->
**Docs paths (this skill).** Master: `~/.claude/skills/team-doctrine/references/docs-paths.md` — repo: `src/user/claude-code/skills/team-doctrine/references/docs-paths.md`. Writes: none. Reads: `docs/ux/`, `docs/tdd/`, `docs/adr/`, `docs/spec/` (always singular).
<!-- CANONICAL:DOCS-PATHS-LOCAL:END -->

## Role Detection

Callable ONLY by `@ux-designer`. Any other caller ABORTS:

```
Error: Skill(design-review) is restricted to @ux-designer. Calling agent: {agent}.
```

## Argument Handling

The argument is a single positional `<scope>` (free-text; extra positional args are ignored). If missing or empty:

```
Error: Usage: Skill(design-review, "<scope>") — name what to review (UX spec path, draft document path, TDD path with user-facing surfaces, or inline surface description).
```

**Scope resolution** (first match wins):

| Form | Detection | Sources |
|---|---|---|
| UX spec path | `Bash test -e {path}` and path matches `docs/ux/.*\.md` | `Read` the spec |
| TDD path | `Bash test -e {path}` and path matches `docs/tdd/.*\.md` | `Read` the TDD; focus on user-facing surface sections |
| Draft document path | `Bash test -e {path}` and path ends in `.md` | `Read` the file directly |
| Inline surface description | Otherwise | The description IS the artifact; cross-reference `docs/ux/`, `docs/tdd/`, `docs/spec/` for precedent |

If `<scope>` looks path-like (contains `/` or ends in `.md`) but the file does not exist, ABORT:

```
Error: Could not resolve <scope>: '{scope}'. File not found. Pass an existing path or a free-text inline description.
```

## When to Use

Reviewing a draft UX spec, a TDD proposing user-facing surfaces (CLI, API, config format, error copy), a design proposal embedded in a comment or chat, or any operator request for design feedback before a decision sets precedent.

## Doubling Rule

Panel sizing, opt-up triggers, ephemeral lifecycle, and verdict reconciliation are owned by `~/.claude/agents/team-lead.md` Rule 8 / Rule 7 / step 14. Skill-specific delta only:

- **Seats**: single (default) = persistent `ux-advisor` via SendMessage; doubled = `ux-advisor` + one ephemeral `design-review-{N}`.
- **Finding-merge dedupe key**: `(spec section, surface)`.
- **Degraded-fallback annotation**, verbatim: `DEGRADED: single-reviewer (ephemeral failed 2×)`.

## When NOT to Use

<!-- COUPLING: this skill is part of the report-emission family (code-review-verdict, verify-ac, design-qa, design-review) — update all 4 in lockstep when adding/removing a sibling skill. -->
- QA of shipped implementation against an accepted UX spec — `Skill(design-qa)`.
- Production code review against engineering dimensions — `Skill(code-review-verdict)`.
- Acceptance-criteria verification — `Skill(verify-ac)` (@sdet).
- Authoring a new UX spec — `Skill(ux-spec)`; consensus voting on a design — `Skill(vote)` after this skill produces a review.

## Pre-flight

1. **Detect role**; ABORT if the caller is not `@ux-designer`.
2. **Resolve `<scope>`**; ABORT if unresolvable.
3. **Read the artifact** — capture frontmatter (maturity, status, owner) and the workflow list; for inline scope the description is the artifact text.
4. **Cross-reference precedent** — `Grep -rl "{key-term}" docs/ux/ docs/tdd/ docs/spec/ docs/adr/` for related specs and established cross-surface conventions (CLI flag conventions, API error shapes, error-copy patterns).
5. **Empty-artifact guard**: if the artifact has no inspectable design content (empty file or description under 10 words), ABORT: `Error: Resolved scope contains no reviewable design content — expand the description or pass a non-empty file.`

## Review Procedure

**Simulate the user journey.** Walk through every workflow articulated in the artifact — trace entry point, interactions, success path, error branches, accessibility hooks, copy, exit point. Designs that read well but break on simulation are reject-class.

### Six UX Dimensions

Apply all six, weighted by what the artifact touches; mark unaffected dimensions `N/A`. Each is anchored to named Apple HIG principles (definitions: `~/.claude/agents/ux-designer.md` §Core Principles) — cite the anchoring principle by name where it grounds a severity:

1. **Usability** — task efficiency, cognitive load, discoverability, mental-model fit, learnability. (HIG: Purpose, Simplicity)
2. **Consistency** — alignment with existing `docs/ux/` patterns, cross-surface naming, terminology, flag/copy conventions. (HIG: Familiarity)
3. **Accessibility** — WCAG 2.2 AA floor; evaluate against the spec-level column of `references/accessibility-checklist.md` (contrast, keyboard, ARIA/semantics, dataviz, data tables, rendered-effect rule). (HIG: Flexibility)
4. **Information Hierarchy** — primary vs secondary, progressive disclosure, scan-ability, signal-to-noise. (HIG: Simplicity)
5. **Error Handling** — every workflow has error branches; messages follow "what happened → why → what to do now" with specific values/paths; degraded modes covered. (HIG: Agency, Responsibility)
6. **Performance Perception** — feedback latency, loading states, perceived progress, silence-is-the-worst-UX violations. (HIG: Familiarity, Craft)

### Severity Ladder

| Severity | Meaning |
|---|---|
| Blocker | Must fix before approval: broken workflow, inaccessible interaction, missing critical error state, cross-surface precedent violation, WCAG AA failure |
| Concern | Should fix or explicitly justify: pattern divergence, missing edge case, weak error copy, accessibility gap on non-critical path |
| Suggestion | Consider for this or future iteration: polish, minor improvement, alternative phrasing |
| Question | Need clarification to complete the review |
| Praise | Pattern worth highlighting and replicating — routes to `What's Strong`, not `What Needs Work` (HIG: Craft, Delight) |

### Recommendation Ladder

| Recommendation | Meaning |
|---|---|
| Approve | All six dimensions pass or are N/A; no Blockers or Concerns |
| Approve with follow-up | Real issues exist but are low-impact polish; calling agent annotates follow-up |
| Block | One or more Blockers; cannot ship until resolved |
| Redesign | Fundamental interaction model is wrong; incremental edits won't fix it (HIG: Purpose) |
| Incremental Improvement | Blockers/Concerns exist AND the foundation is sound (users have existing muscle memory), so they are fixed in place rather than by restarting. Satisfies the validator's any-Blocker constraint alongside Block and Redesign — NOT an approve-class verdict |

### Common Discipline

- **Report every finding — do NOT self-filter.** Report each issue found, including low-severity and uncertain ones, tagged with severity (classification, not suppression). Filtering and ranking happen downstream, never here — declining to report a finding because it seems minor is a recall defect.
- **Honest critique with evidence.** Do not default to Approve; a justified Block with a concrete alternative beats an unexamined Approve. Cite the artifact section, workflow, or precedent grounding each finding; banned hedges (the set `report_lint.py` enforces): "clearly", "obviously", "should work", "definitely", "100%", "guaranteed".
- **Pair every Blocker with an alternative.** The validator requires a `—` alternative/fix fragment on each Blocker; when no concrete alternative exists yet, write `— alternative: none identified — needs design exploration` rather than downgrading or dropping the Blocker.
- **Literal vs semantic backticks.** A backtick-quoted token in the artifact (`--no-color`, an error string) is either a LITERAL the surface must render verbatim or a SEMANTIC stand-in for a behavior; read the surrounding sentence to decide. If the artifact doesn't disambiguate, raise a Question, not a Blocker — grading one against the other produces a false Blocker.
- Ask when intent is genuinely ambiguous and the answer is not in the artifact (standalone: `AskUserQuestion`; team mode: route through the calling agent).

## Output Contract

Emit the review verbatim into the calling agent's context. Do not echo the raw artifact, save to disk, or add prose outside the format. If the harness blocks this skill's invocation, render the review directly per THIS format authority — never an improvised structure.

```
## Design Review: {Artifact Title}

### Assessment
{1-3 sentences: what is being designed, who the user is, what problem it solves, and the scope of this review}

### Artifact
- Source: {path or "Inline description"}
- Type: {UX spec / TDD / draft / inline}
- Maturity / status: {maturity from frontmatter — and status if present, or "N/A" for inline}

### What's Strong
- {praise — pattern + why it works}
- ... or "None to highlight yet"

### What Needs Work

**Blockers** ({count}):
- [{dimension}] {finding} — {required alternative or fix}
- ... or "None"

**Concerns** ({count}):
- [{dimension}] {finding} — {recommended fix or justification ask}
- ... or "None"

**Suggestions** ({count}):
- [{dimension}] {finding}
- ... or "None"

**Questions** ({count}):
- {open question for the artifact author}
- ... or "None"

### Open Questions
- {unresolved decision the artifact must address before approval, or "None"}

### Dimension Checklist
| Dimension | Status |
|---|---|
| Usability | pass / concern / fail / N/A |
| Consistency | pass / concern / fail / N/A |
| Accessibility | pass / concern / fail / N/A |
| Information Hierarchy | pass / concern / fail / N/A |
| Error Handling | pass / concern / fail / N/A |
| Performance Perception | pass / concern / fail / N/A |

### Recommendation
One of: **Approve** / **Approve with follow-up** / **Block** / **Redesign** / **Incremental Improvement**

### Next Steps
{What the calling agent should do — e.g., deliver the structured verdict, escalate to vote for cross-surface precedent, route Blockers to the author}

Design review emitted ({recommendation}).
```

## Validation Before Emit

Stage and lint in a SINGLE Bash call — prefer the stdin form so there is no temp path to get wrong (shell state does not persist between Bash calls, and doubled panels share one `$TMPDIR`, so a hand-rolled fixed path races):

```
~/.claude/scripts/report_stage_lint.sh design-review "$DRAFT_FILE"
```

Exit codes:

- **0** — emit the review in the calling agent's context.
- **1 (validation failure)** — ABORT; correct (quoting the script's stderr) and re-invoke: `Error: validation failed: {section/field} — {detail}.`
- **2 (infra/usage)** — do NOT hard-block: emit the review with `lint not run (infra: {reason})` appended after the trailing confirmation line and flag the infra failure to the caller.

Every check in this review's checklist is text-decidable and lives in the validator: recommendation on the ladder and consistent with severity counts (any Blocker ⇒ Block/Redesign/Incremental Improvement; any Concern with no Blockers forbids plain Approve); every Blocker/Concern carries a valid `[dimension]` tag and a non-empty finding; every Blocker has a `—` alternative/fix fragment; Dimension Checklist covers all six with a status; empty buckets explicit; section order; placeholder and banned-phrase scans.

## Save & Return

End with the confirmation line:

```
Design review emitted ({recommendation}).
```

The in-context emission is the working artifact; the deliverable is the calling agent's same-turn SendMessage of the structured verdict (team mode: to team-lead, who reconciles both reviewers per the Doubling Rule before routing to the author; standalone: to the author directly). The calling agent also owns: vote escalation for cross-surface precedent, TDD conflicts, or 3+ surface spans (standalone `Skill(vote)`; team mode never `Skill(vote)` — `docket vote create` + `delegation_request` to team-lead), and mirroring the outcome as a Docket comment using `[UX→@agent] {summary}`.

On any abort: emit `Error: {one-line cause}` and end without producing a review.
