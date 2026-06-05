---
name: tdd
description: >
  Author a single Technical Design Document as a Docket doc (docket doc create -T tdd).
  Loaded into the calling agent's context; the agent drafts the TDD per the format
  authority below.
  Trigger: "create TDD", "draft TDD", "produce a technical design document", "write the design for {feature}".
argument-hint: "<topic>"
effort: max
allowed-tools: ["AskUserQuestion", "Bash", "Read", "Write"]
---

<!-- CANONICAL:BANNER:BEGIN -->
> **CRITICAL:** (1) Do NOT commit ANY changes (no `git add`, no `git commit`, no `git push`) unless EXPLICITLY instructed by the user. (2) This is a leaf skill. You MUST NOT spawn sub-agents, invoke `Skill()` recursively, or use `Agent()`, `TeamCreate`, `TeamDelete`, or `SendMessage`. The calling agent handles peer messaging after this skill returns.
<!-- CANONICAL:BANNER:END -->

# TDD — Author a Technical Design Document

You are the **TDD Author**. You produce a single Technical Design Document as a Docket
doc (type `tdd`) and return. The calling agent (typically `@staff-engineer`) drafts the
content; this skill is the format authority — section list, frontmatter contract, and
the `docket doc create` recipe all live here. Docket issues the document's `DOC-<n>`
identity; there is no filename.

> **Note — "TDD" here means Technical Design Document, NOT Test-Driven Development.**

## Argument Handling

<!-- CANONICAL:ARGUMENT_HANDLING:BEGIN -->
The argument is a single positional `<topic>` (free-text, 3-10 words describing the
artifact). No flags, no other args.

If `<topic>` is missing or empty:

```
Error: Usage: Skill({TYPE}, "<topic>") — describe the artifact in 3-10 words.
```

If extra positional args are passed beyond `<topic>`, ignore them silently.

**Title derivation.** The document's identity is the Docket-issued `DOC-<n>`, not a
filename — there is no slug-to-path step. The `<topic>` is the human-readable `-t`
title (Title Case, free prose). Use `<topic>` verbatim as the default `{title}`; the
calling agent MAY refine it into a clearer prose title. Reject only an empty/all-
punctuation topic that yields no title text:

1. `cleaned = topic.strip()`.
2. If `cleaned` contains no alphanumeric character, ABORT: `Error: Topic must contain at least one alphanumeric character.`
3. Use `cleaned` (or a calling-agent refinement of it) as `{title}`.
<!-- CANONICAL:ARGUMENT_HANDLING:END -->

## When to Use

- A Technical Design Document is needed for non-trivial work (architecture, system
  design, multi-step migration, cross-cutting refactor) and should live as a Docket
  `tdd` doc as the authoritative design record. Pick TDD over PRD when *how* is the
  question — the what/why is settled and architecture is the open work (the inverse of
  prd's "scope precedes architecture" boundary).
- The calling agent (typically `@staff-engineer`) is producing a design that needs to
  go through the `draft → approved` lifecycle (Docket doc status; promotion happens
  after the calling agent's review/vote loop).
- The team-lead orchestrator's Medium Task pattern asks for a TDD without a separate
  PRD — this skill is the canonical path.

## When NOT to Use

<!-- COUPLING: this skill is part of the doc-authoring family. The "When NOT to Use" delegation routes below MUST stay in sync with skills/prd, adr, ux-spec, and init-specs — update all 5 in lockstep when adding/removing a sibling skill. -->
- Inline advisory replies, review comments, scratch notes, or one-off design
  sketches that are not meant to live as a Docket `tdd` doc.
- Architecture Decision Records (single decisions): use `Skill(adr, "<topic>")`.
- Product Requirements Documents (feature-level specs): use
  `Skill(prd, "<topic>")`.
- UX / design specs: use `Skill(ux-spec, "<topic>")`. When a TDD touches a user-facing surface, the interaction-design portions belong in the UX spec; the TDD references it (per Pre-flight step 4 + Authoring §1) rather than restating it.
- Project-wide engineering specs (architecture, security, operations, performance,
  code-quality, review-strategy, testing): owned by the `init-specs` skill.

## Pre-flight

1. **Resolve `{title}`** from `<topic>` per the Argument Handling title rule above.
2. **Resolve context**:
   - `{today_date}` = `Bash date +%Y-%m-%d`.
   - `{project_name}` = `Bash basename $(git rev-parse --show-toplevel)`.
   - `{updated_by}` = the calling agent's identifier (e.g., `@staff-engineer`).
3. **Near-duplicate probe** (advisory, non-blocking): run
   `docket doc list -T tdd --json` and scan existing TDD titles for one that covers the
   same surface as `<topic>`. If a close match exists, surface it to the calling agent
   context as a one-line note: `Near-duplicate TDD(s) detected: {DOC-ids + titles}. Proceed only if this is intentionally distinct work.` The calling agent decides whether to continue or refine the title; no automatic block. Docket does not collide on title, so there is no overwrite path — a new create always issues a fresh `DOC-<n>`.
4. **Related-doc probe**: run `docket doc list -T prd --json` and
   `docket doc list -T ux --json`. For each existing doc whose title overlaps
   `<topic>` (case-insensitive), include its `DOC-<n>` id in the `dependencies`
   frontmatter array. The calling agent may add others from broader judgment.

## Authoring Procedure

1. **Gather prior art**: discover related docs with `docket doc list -T tdd --json`,
   `docket doc list -T prd --json`, and `docket doc list -T ux --json`, then read any
   candidate parent PRD/UX doc identified in Pre-flight step 4 via
   `docket doc show <DOC-id>`. Read existing TDD docs that touch adjacent areas — the
   new TDD should reference, not contradict, prior approved work.
2. **Draft the frontmatter** per the Required Frontmatter contract below. Set
   `status: "draft"` initially.
3. **Draft each Required Section in order** (see Output Contract → Required
   Sections). Every section listed MUST appear, in the order shown. Sections
   marked "may be N/A" (Data Models §5, API Contracts §6) may contain a single
   `N/A.` paragraph with a one-line justification. The chosen alternative in §3
   must match the Architecture & System Design section (§4).
4. **Mermaid diagrams**: draft at least one Mermaid block appropriate to the
   design — component map, sequence, state, or data flow. Validation §5 is
   the gate; Failure Modes routes pure-policy decisions to ADR.
5. **Proceed to Validation Before Save** — that step is the single source of
   truth for frontmatter, sections, alternatives count, Mermaid, and placeholder
   checks (matches sibling PRD's §6).

## Output Contract

### Required Frontmatter

```yaml
---
project: "{project_name}"
maturity: "draft"
last_updated: "{today_date}"
updated_by: "{updated_by}"
scope: "{one-liner describing what the TDD covers}"
owner: "{owning agent or team, e.g. @staff-engineer}"
dependencies:
  - {DOC-<n> of parent PRD or related doc, or empty list}
status: "draft"
---
```

Field rules:

- `project` = `basename $(git rev-parse --show-toplevel)`.
- `maturity` describes how settled the content is (`proof-of-concept | draft | experimental | stable`). `status` describes where the doc sits in the review-and-vote lifecycle (see `status` rule below). The two are orthogonal — a TDD can be `status: approved` while `maturity: experimental` (design signed off, approach still provisional). Docket's own doc-level `status` field (`.data.status`, surfaced by `docket doc list -T tdd -s approved` / `docket doc show <DOC-id> --json`) is the SINGLE SOURCE OF TRUTH for downstream gates — `verify-ac` ABORTs verification unless `.data.status == "approved"`. The body-frontmatter `status:` is documentation-only: it mirrors the doc-level status at author time and is NOT auto-updated by `docket doc edit <DOC-id> -s approved`, so it may drift stale — never gate on it.
- `last_updated` is ISO date `YYYY-MM-DD`.
- `updated_by` is the calling agent identifier (`@staff-engineer`, etc.).
- `scope` is a one-line description of what the doc covers — populated by the
  calling agent.
- `owner` is the responsible agent or team handle.
- `dependencies` is a YAML array of related `DOC-<n>` ids; use `[]` if none.
- `status` is one of: `draft | approved`. New TDDs start at `draft`; promotion to
  `approved` happens after the calling agent's review/vote loop via
  `docket doc edit <DOC-id> -s approved`.

### Required Sections

The TDD body MUST contain these top-level sections, in this order. Each is a
`##` heading in the drafted document.

1. **Problem Statement** — what, why now, who is affected, constraints, acceptance
   criteria, business context.
2. **Context & Prior Art** — existing patterns in this repo and outside; how this
   work fits.
3. **Alternatives Considered** — at least two; shape, strengths, weaknesses,
   verdict per alternative.
4. **Architecture & System Design** — the chosen approach, with sub-sections as
   needed (component map, data flow, sequencing, contracts). **For security
   TDDs** (`updated_by` is `@security-engineer`), this section MUST include
   three `###` subsections — `Threat Model`, `Trust Boundaries`, and
   `Security Considerations` — enforced by Validation §7. Non-security TDDs
   may omit them. (Mixed-scope routing — when @security-engineer appends
   these to a @staff-engineer TDD via the Threat-Model Annotation pattern
   — is owned by `agents/security-engineer.md`, not this skill.)
5. **Data Models & Storage** — schemas, persistence, migrations. May be `N/A.`
   with one-line justification if the design has no data plane.
6. **API Contracts** — request/response shapes, RPC contracts, CLI invocation
   shapes. May be `N/A.` with one-line justification.
7. **Migration & Rollout** — current state, target state, rollout sequencing,
   backward compatibility, rollback plan.
8. **Risks & Open Questions** — risk table (likelihood/impact/mitigation); open
   questions resolved or escalated before vote.
9. **Testing Strategy** — test levels, smoke tests, coverage of acceptance
   criteria, untested-claims inventory. **For security TDDs** (per §4
   security-track gating), this section MUST include a named subsection
   `### Abuse Cases` enumerating adversarial-input tests, not just happy-path
   coverage.
10. **Observability & Operational Readiness** — signals, 3am diagnosability,
    production readiness, runbooks.
11. **Implementation Phases** — partitioned phases that the planner consumes
    directly. Each phase MUST specify: (a) one-line phase goal, (b) file scope
    (paths affected), (c) per-phase acceptance criteria — any grep/regex-based
    AC must be executable against the named files and cover all expected matches
    (escape markdown, arm for word-order/formatting variants); a single-arm
    regex that silently under-matches is a defect, (d) effort estimate
    (S/M/L), (e) blocking dependencies on other phases, (f) explicit
    out-of-scope flags. Phases must be independently shippable or explicitly
    chained — no implicit ordering.

## Validation Before Save

Before invoking `Write`, verify in the calling agent's context:

1. **Frontmatter fields** — all of `project`, `maturity`, `last_updated`,
   `updated_by`, `scope`, `owner`, `dependencies`, `status` present and
   non-empty (`dependencies` may be the empty list `[]`).
2. **Status value** — `status` is one of `draft | approved`.
3. **Section order** — the body contains all top-level sections enumerated
   in "Required Sections" above, as `##` headings, in the order listed.
   Count only `##` headings at column 0 *outside* ``` code fences — a TDD that
   documents another doc/skill may embed `##`/`###` example headings inside
   fences; those are content, not structure. Off-by-one against the listed
   sections is a defect.
4. **Alternatives count** — Section 3 (Alternatives Considered) contains at
   least two `###`-level subsections (counting only `###` headings outside
   ``` code fences).
5. **Mermaid presence** — at least one ` ```mermaid ` fenced block in the body.
6. **Placeholder scan** — body contains no literal `{title}`, `{topic}`,
   `{project_name}`, `TBD`, or `TODO` text outside of code-fenced examples.
7. **Security-track subsections** — if `updated_by` is `@security-engineer`,
   verify §4 (Architecture & System Design) contains three `###`-level
   subsections named exactly `Threat Model`, `Trust Boundaries`, and
   `Security Considerations`. Non-security TDDs skip this check.
8. **Security-track abuse cases** — if `updated_by` is `@security-engineer`,
   verify §9 (Testing Strategy) contains a `###`-level subsection named
   `Abuse Cases`. Non-security TDDs skip this check.

If any check fails, ABORT (no fix-and-retry — the skill validates then writes
in a single pass; repair is the calling agent's responsibility):

```
Error: validation failed: {field/section} — {detail}.
```

The calling agent fixes the issue in its own context and re-invokes
`Skill(tdd, "<topic>")`.

## Create & Return

<!-- CANONICAL:SAVE_AND_RETURN:BEGIN -->
After Validation Before Save passes, create the doc in Docket. The full document body
(frontmatter block + all Required Sections) is drafted to a temp file, then supplied to
`docket doc create` via `-d @`:

1. `Write` the full drafted document body to a temp file under `$TMPDIR`:

   ```
   BODY="${TMPDIR:-/tmp}/tdd-doc.md"
   ```

2. Create the doc (type `tdd`, create-status `draft`), capturing JSON:

   ```
   docket doc create -T tdd -t "{title}" -s draft -d @"$BODY" --json
   ```

3. Parse the new id from the JSON `.data.id` and emit a single confirmation line:

   ```
   Created DOC-<n>: {title}
   ```

End. Do NOT echo the file body, do NOT send peer messages, do NOT invoke other skills.
The calling agent owns next steps (vote requests, decomposition, peer notification,
`docket doc link add <DOC-id> --issue <DKT-id>` when a driving issue exists).

On any abort during Authoring Procedure, Pre-flight, or Validation Before Save: emit
`Error: {one-line cause}` and end without creating.

If `docket doc create` returns a non-ok JSON envelope (`{"ok":false,...}`), surface it:
`Error: docket doc create failed — {message}.` The temp-file body remains on disk for
inspection. Do NOT retry.
<!-- CANONICAL:SAVE_AND_RETURN:END -->

## Failure Modes

| Trigger | Handling |
|---|---|
| `<topic>` missing or empty | Abort: `Error: Usage: Skill(tdd, "<topic>") — describe the artifact in 3-10 words.` |
| Title empty after trimming (e.g., all-punct topic) | Abort: `Error: Topic must contain at least one alphanumeric character.` |
| Validation Before Save fails | Abort with `Error: validation failed: {field/section} — {detail}.` No retry — calling agent re-invokes. |
| Mermaid mandate not satisfied | Abort: `Error: validation failed: Mermaid block missing — TDD requires at least one mermaid fenced block (component map, sequence, state, or data flow). Pure-policy decisions belong in an ADR.` |
| Security TDD missing Threat Model / Trust Boundaries / Security Considerations subsections | Abort: `Error: validation failed: §4 — security TDD requires Threat Model, Trust Boundaries, and Security Considerations subsections (updated_by={agent}).` |
| Security TDD missing Abuse Cases subsection in §9 | Abort: `Error: validation failed: §9 — security TDD requires Abuse Cases subsection in Testing Strategy (updated_by={agent}).` |
| `docket doc create` returns a non-ok JSON envelope | Surface raw error: `Error: docket doc create failed — {message}.` Do NOT retry. The temp-file body remains on disk; the calling agent reports to the operator. |
| Caller passes additional positional args beyond `<topic>` | Ignore extras silently. |
