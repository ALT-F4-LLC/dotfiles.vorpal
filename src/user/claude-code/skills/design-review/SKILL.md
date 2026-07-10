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

You are the **Design Reviewer**. You conduct a peer design review on the artifact named by `<scope>` (UX spec, draft, design proposal, or inline surface description) and emit a structured report back to the calling agent's context. No file is written. The skill is the format authority — six UX dimensions, severity ladder, recommendation ladder, required sections, validation.

<!-- CANONICAL:DOCS-PATHS-LOCAL:BEGIN -->
**Docs paths (this skill).** Master: `~/.claude/skills/team-doctrine/references/docs-paths.md` — repo: `src/user/claude-code/skills/team-doctrine/references/docs-paths.md` (maintained copy).
- Writes: none — report into the calling agent's context.
- Reads: `docs/ux/`, `docs/tdd/`, `docs/adr/`, `docs/spec/`.
- Always singular docs/spec/ — never docs/specs/.
<!-- CANONICAL:DOCS-PATHS-LOCAL:END -->

## Role Detection

This skill is callable ONLY by `@ux-designer`. Match the calling agent's identifier (from prompt context); if the caller is not `@ux-designer`, ABORT.

Abort message:

```
Error: Skill(design-review) is restricted to @ux-designer. Calling agent: {agent}.
```

## Argument Handling

The argument is a single positional `<scope>` (free-text). No flags.

If `<scope>` is missing or empty:

```
Error: Usage: Skill(design-review, "<scope>") — name what to review (UX spec path, draft document path, TDD path with user-facing surfaces, or inline surface description).
```

**Scope resolution** (apply rules in order; first match wins):

| Form | Detection | Sources |
|---|---|---|
| UX spec path | `Bash test -e {path}` and path matches `docs/ux/.*\.md` | `Read` the spec |
| TDD path | `Bash test -e {path}` and path matches `docs/tdd/.*\.md` | `Read` the TDD; focus review on user-facing surface sections |
| Draft document path | `Bash test -e {path}` and path ends in `.md` | `Read` the file directly |
| Inline surface description | Otherwise (free-text description of the design under review) | The description IS the artifact — review the design as articulated; cross-reference `docs/ux/`, `docs/tdd/`, `docs/spec/` for precedent |

If `<scope>` matches a path-like pattern (contains `/` or ends in `.md`) but the file does not exist, ABORT:

```
Error: Could not resolve <scope>: '{scope}'. File not found. Pass an existing path or a free-text inline description.
```

If extra positional args follow `<scope>`, ignore them silently.

## When to Use

- Reviewing a draft UX spec authored by another agent (peer review before consensus).
- Reviewing a `@staff-engineer` TDD that proposes user-facing surfaces (CLI, API, config format, error copy).
- Reviewing a `@senior-engineer` design proposal embedded in a design comment or chat.
- Operator requests feedback on a design decision before it sets precedent.

## Doubling Rule

When invoked under team-lead orchestration (or `@ux-designer` orchestration), design review defaults to a **single** reviewer — the persistent `ux-advisor` consulted via SendMessage, no ephemeral spawn — per `~/.claude/agents/team-lead.md` Rule 8; the single verdict is final. **Opt up to a doubled panel** only when a Rule 8 trigger fires: the calling layer then spawns `ux-advisor` + one ephemeral `design-review-{N}` (`Agent()`), both dispatched in the SAME turn (eager parallel dispatch). The ephemeral `design-review-{N}` delivers its verdict, then AWAITS the calling layer's lead-initiated `shutdown_request` (it never self-originates shutdown); the ephemeral lifecycle is owned by the calling layer per `~/.claude/agents/team-lead.md` Rule 7 / step 14. Verdict reconciliation (any Blocker blocks; findings merge with `(spec section, surface)` dedupe; contradictions surface to operator via `AskUserQuestion` or `Skill(vote, ...)`; reviewers never address the operator directly) per `~/.claude/agents/team-lead.md` step 14. On double-ephemeral failure (probe-once + respawn both abort), the calling layer falls back to `ux-advisor` alone AND annotates the consolidated message header verbatim `DEGRADED: single-reviewer (ephemeral failed 2×)`. Standalone-mode invocations follow the calling agent's own discretion.

## When NOT to Use

<!-- COUPLING: this skill is part of the report-emission family (code-review-verdict, verify-ac, design-qa, design-review). The "When NOT to Use" delegation routes below MUST stay in sync across the family — update all 4 in lockstep when adding/removing a sibling skill. The Doubling Rule section is also part of this family — keep its shape in sync across siblings per `src/user/claude-code/agents/team-lead.md` Rule 8. -->
- QA of shipped implementation against an accepted UX spec — that's `Skill(design-qa, ...)`.
- Production code review against engineering dimensions — that's `Skill(code-review-verdict, ...)`, callable by `@staff-engineer` or `@security-engineer`.
- Acceptance-criteria verification — that's `Skill(verify-ac, ...)`, callable by `@sdet`.
- Authoring a new UX spec — use `Skill(ux-spec, ...)`.
- Multi-agent consensus voting on a design — use `Skill(vote, ...)` after this skill produces a review.

## Pre-flight

1. **Detect role** per Role Detection. ABORT if caller is not `@ux-designer`.
2. **Resolve `<scope>`** per Argument Handling. ABORT if unresolvable.
3. **Read the artifact**:
   - For UX spec / TDD / draft path: `Read` the file; capture frontmatter (maturity, status, owner) and the workflow list.
   - For inline surface description: treat the description as the artifact text.
4. **Cross-reference precedent**:
   - `Grep -rl "{key-term}" docs/ux/ docs/tdd/ docs/spec/ docs/adr/` to locate related specs, ADRs (under `docs/adr/`), and project specs.
   - Identify any cross-surface precedent already established (CLI flag conventions, API error shapes, error-copy patterns).
5. **Empty-artifact guard**: if the artifact has no inspectable design content (empty file or description under 10 words), ABORT:

   ```
   Error: Resolved scope contains no reviewable design content — expand the description or pass a non-empty file.
   ```

## Review Procedure

**Simulate the user journey.** Walk through every workflow articulated in the artifact — don't just read. For each workflow, trace: entry point, expected interactions, success path, error branches, accessibility hooks, copy, exit point. Designs that read well but break on simulation are reject-class.

### Six UX Dimensions

Apply all six dimensions, weighted by what the artifact touches. Mark unaffected dimensions `N/A` in the checklist:

1. **Usability** — task efficiency, cognitive load, discoverability, mental-model fit, learnability.
2. **Consistency** — alignment with existing `docs/ux/` patterns, cross-surface naming, terminology, flag/copy conventions, same-concept-same-name.
3. **Accessibility** — WCAG 2.2 AA floor, keyboard reachability, NO_COLOR support, color-not-sole-indicator, screen-reader semantics, contrast. On visual surfaces, the design must specify the rendered EFFECT at real delivery resolution (screenshare, streamed video, small viewport), not just the CSS/token value — a cue that meets the contract may fail to read once compressed. Every color/visual cue must be paired with a text fallback so a degraded render still carries meaning.
4. **Information Hierarchy** — what's primary, what's secondary, progressive disclosure, scan-ability, signal-to-noise.
5. **Error Handling** — every workflow has error branches; messages follow "what happened → why → what to do now"; specific values/paths in errors; degraded modes covered.
6. **Performance Perception** — feedback latency, loading states, perceived progress, silence-is-the-worst-UX violations, animation timing.

### Severity Ladder

| Severity | Meaning |
|---|---|
| Blocker | Must fix before approval: broken workflow, inaccessible interaction, missing critical error state, cross-surface precedent violation, WCAG AA failure |
| Concern | Should fix or explicitly justify: pattern divergence, missing edge case, weak error copy, accessibility gap on non-critical path |
| Suggestion | Consider for this or future iteration: polish, minor improvement, alternative phrasing |
| Question | Need clarification to complete the review |
| Praise | Pattern worth highlighting and replicating across surfaces — routes to `What's Strong`, not `What Needs Work` |

### Recommendation Ladder

| Recommendation | Meaning |
|---|---|
| Approve | All six dimensions pass or are N/A; no Blockers or Concerns; minor Suggestions/Praise allowed |
| Approve with follow-up | Real issues exist but are low-impact polish; calling agent annotates follow-up |
| Block | One or more Blockers; cannot ship until resolved |
| Redesign | Fundamental interaction model is wrong; incremental edits won't fix it — proposes restart |
| Incremental Improvement | Foundation is sound and users have existing muscle memory; recommend bounded improvements rather than a redesign |

### Common Discipline

- **Ask clarifying questions first** when intent is ambiguous — use `AskUserQuestion` per the calling agent's structural contract. Peer SendMessage is the calling agent's job, not this skill's. Do NOT ask when the answer is in the artifact.
- **Honest critique with evidence.** Do NOT default to Approve. A justified Block with a concrete alternative is more valuable than an unexamined Approve. Cite the artifact section, workflow, or precedent that grounds each finding — banned hedges: "clearly", "obviously", "should work", "definitely".
- **Pair every Blocker with a concrete alternative.** A Blocker without an alternative is half a finding.
- **Report every finding — do NOT self-filter.** Report each issue found, including low-severity and uncertain ones, each tagged with its severity (Blocker/Concern/Suggestion/Question/Praise — classification, not suppression). Filtering and ranking happen downstream (calling agent / team-lead reconciliation), never here — declining to report a finding because it seems minor is a recall defect.

## Output Contract

Emit the review verbatim to the calling agent's context. Do NOT echo the raw artifact body. Do NOT save to disk. Do NOT add a preamble or trailing notes outside the format. **If the harness blocks this skill's invocation** (Stage-2 auto-mode classifier), render the review directly per THIS format authority — every required section in order and the Approve / Approve with follow-up / Block / Redesign / Incremental Improvement recommendation ladder — never an improvised structure.

```
## Design Review: {Artifact Title}

### Assessment
{1-3 sentences: what is being designed, who the user is, what problem it solves, and the scope of this review (which dimensions are in focus, which are N/A and why)}

### Artifact
- Source: {path or "Inline description"}
- Type: {UX spec / TDD / draft / inline}
- Maturity / status: {maturity from frontmatter — and status if present, or "N/A" for inline}

### What's Strong
- {praise 1 — pattern + why it works}
- {praise 2}
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
{What the calling agent should do — e.g., deliver the structured verdict to the calling agent / team-lead, escalate to vote for cross-surface precedent, route Blockers to the author for revision, propose redesign with concrete starting points}
```

## Validation Before Emit

Before emitting the report, verify in the calling agent's context:

1. **Recommendation is on the ladder** — exactly one of Approve / Approve with follow-up / Block / Redesign / Incremental Improvement.
2. **Recommendation matches severity counts** — any Blocker ⇒ Block / Redesign / Incremental Improvement; any Concern with no Blockers ⇒ Approve with follow-up / Redesign / Incremental Improvement (plain Approve forbidden); zero Blockers and zero Concerns ⇒ Approve permitted (Redesign / Incremental Improvement still allowed when the body argues a rethink or bounded improvement path).
3. **Every Blocker cites a dimension** — the `[dimension]` tag at the start of each Blocker bullet must name one of the six dimensions.
4. **Every Concern names a spec section or workflow** — the bullet body must reference the artifact section, workflow, or surface it affects.
5. **Every Blocker has an alternative or required fix** — a Blocker bullet without `—` separator and an alternative/fix fragment is a defect.
6. **Dimension Checklist covers all six dimensions** — each row present with one of pass/concern/fail/N/A. Off-by-one is a defect.
7. **Empty severity buckets explicit** — every bucket (Blockers/Concerns/Suggestions/Questions) reads `None` or lists items. Silent omission is a defect.
8. **Required sections present, in order** — Assessment, Artifact, What's Strong, What Needs Work, Open Questions, Dimension Checklist, Recommendation, Next Steps.
9. **Placeholder scan** — body contains no literal `{Artifact Title}`, `{dimension}`, `{count}`, `TBD`, or `TODO` text outside of code-fenced examples.
10. **Epistemic discipline scan** — no banned confidence phrases ("clearly," "obviously," "should work," "definitely," "100%," "guaranteed") in What's Strong, What Needs Work, Open Questions, or Next Steps. Use evidence-anchored language ("verified at {section}," "the workflow at {path} shows …," "assumption: …"). A hit is a defect.

If any check fails, ABORT:

```
Error: validation failed: {section/field} — {detail}.
```

The calling agent corrects in its own context and re-invokes `Skill(design-review, "<scope>")`.

## Save & Return

No file is written (Output Contract owns the emission rules). End with the confirmation line:

```
Design review emitted ({recommendation}).
```

where `{recommendation}` is one of Approve / Approve with follow-up / Block / Redesign / Incremental Improvement.

The calling agent owns (in order):

- SendMessage the verdict per `~/.claude/agents/ux-designer.md` Inter-Agent Communication triggers (under team-lead orchestration, to team-lead — who reconciles both reviewers per the Doubling Rule before routing Blockers/Concerns to the author; standalone, to the author directly).
- Escalating to vote if the review touches cross-surface precedent, conflicts with a TDD, spans 3+ surfaces, or otherwise meets a vote-criticality threshold — standalone: `Skill(vote, ...)`; team mode: NEVER `Skill(vote)` (nests a team) — `docket vote create` + `delegation_request` to team-lead per `~/.claude/agents/ux-designer.md` Design Spec Approval.
- Mirroring the review outcome as a Docket comment using `[UX→@agent] {summary}` per the operator-visibility contract.

**Self-check before ending the turn**: the calling agent MUST self-check — "Did I SendMessage the verdict (structured, not summarized) this same turn?" (in team mode, to team-lead; standalone, to the author). The skill's in-context emission is the calling agent's working artifact, not the deliverable; the deliverable is the SendMessage. A silent turn after `Design review emitted (...)` is silent-completion — the dominant defect class across this skill family (`code-review-verdict`, `verify-ac`, `design-review`, `design-qa`).

On any abort during Pre-flight, Review Procedure, or Validation Before Emit: emit `Error: {one-line cause}` and end without producing a review.
