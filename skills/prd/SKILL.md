---
name: prd
description: >
  Author a single Product Requirements Document as a Docket doc (docket doc create -T prd).
  Loaded into the calling agent's context; the agent drafts the PRD per the format
  authority below.
  Trigger: "create PRD", "draft PRD", "write a product requirements document", "decompose this into a Docket prd doc", "write up requirements for", "scope this feature".
argument-hint: "<topic>"
effort: max
allowed-tools: ["AskUserQuestion", "Bash", "Read", "Write"]
---

<!-- CANONICAL:BANNER:BEGIN -->
> **CRITICAL:** (1) Do NOT commit ANY changes (no `git add`, no `git commit`, no `git push`) unless EXPLICITLY instructed by the user. (2) This is a leaf skill. You MUST NOT spawn sub-agents, invoke `Skill()` recursively, or use `Agent()`, `TeamCreate`, `TeamDelete`, or `SendMessage`. The calling agent handles peer messaging after this skill returns.
<!-- CANONICAL:BANNER:END -->

# PRD — Author a Product Requirements Document

You are the **PRD Author**. You produce a single Product Requirements Document as a
Docket doc (type `prd`) and return. The calling agent (typically `@project-manager`)
drafts the content; this skill is the format authority — section list, frontmatter
contract, the `docket doc create` recipe, and reserved-name refusal all live here.
Docket issues the document's `DOC-<n>` identity; there is no filename.

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
3. `normalized = lowercase(cleaned)` with non-alphanumerics collapsed to `-` — used
   ONLY for the reserved-name check below, never as a filename.
4. Use `cleaned` (or a calling-agent refinement of it) as `{title}`.
<!-- CANONICAL:ARGUMENT_HANDLING:END -->

## When to Use

- A feature-level Product Requirements Document is needed for a non-trivial product surface (new feature, UX-driven change, scope-defined initiative) and should live as a Docket `prd` doc as the authoritative product record. Pick PRD over TDD when scope precedes architecture — what and why is uncertain, not how.
- The calling agent (typically `@project-manager`) is producing a PRD before decomposition into Docket issues so reviewers and implementers share one product definition.
- The team-lead Large Task pattern (`agents/team-lead.md`) requests a PRD as the entry point for product-defined initiatives — this skill is the canonical path.

## When NOT to Use

<!-- COUPLING: this skill is part of the doc-authoring family. The "When NOT to Use" delegation routes below MUST stay in sync with skills/tdd, adr, ux-spec, and init-specs — update all 5 in lockstep when adding/removing a sibling skill. -->
- Inline scoping notes, advisory replies, decomposition comments, or scratch ideas
  that are not meant to live as a Docket `prd` doc.
- Technical Design Documents (architecture, system design, multi-step migration):
  use `Skill(tdd, "<topic>")`.
- Architecture Decision Records (single decisions): use `Skill(adr, "<topic>")`.
- UX / design specs: use `Skill(ux-spec, "<topic>")`.
- Project-wide engineering specs (the 7 reserved names: architecture, security,
  operations, performance, code-quality, review-strategy, testing): owned by the
  `init-specs` skill. This skill HARD-REFUSES those names — see Pre-flight step 3
  and Failure Modes.

## Pre-flight

1. **Resolve `{title}`** and `{normalized}` from `<topic>` per the Argument Handling
   title rule above.
2. **Resolve context**:
   - `{today_date}` = `Bash date +%Y-%m-%d`.
   - `{project_name}` = `Bash basename $(git rev-parse --show-toplevel)`.
   - `{updated_by}` = the calling agent's identifier (e.g., `@project-manager`).
3. **Reserved-name refusal**: if `{normalized}` matches a name in the Failure Modes
   Reserved-Name List, ABORT per the Failure Mode table. The seven baseline-spec names
   stay markdown under `docs/spec/` (owned by the `init-specs` skill) and are never
   authored as `prd` docs.

## Authoring Procedure

1. **Gather prior art**: discover related PRD docs with `docket doc list -T prd --json`
   and read them via `docket doc show <DOC-id>` (the 7 reserved engineering specs stay
   markdown under `docs/spec/` and are project-level conventions, not PRDs; read them by
   name only if the PRD genuinely depends on one). Discover related TDD/UX docs with
   `docket doc list -T tdd --json` / `docket doc list -T ux --json` — the new PRD should
   reference, not contradict, prior approved product definitions, and record each
   `DOC-<n>` the PRD builds on in the `dependencies` frontmatter field so reviewers and
   decomposition can trace the lineage.
2. **Probe Docket** (informational): run `docket issue list --sort priority:asc --json` (high-priority active tickets) and `docket issue list --tree` (existing epics whose decomposition may overlap). Surface any intersecting issues under a "Pre-existing Docket issues" sub-bullet in Risks & Open Questions.
3. **Draft the frontmatter** per the Required Frontmatter contract below. Set
   `maturity: "draft"` initially.
4. **Draft each Required Section in order** (see Output Contract → Required
   Sections). Every section listed MUST appear, in the order shown.
5. **Mermaid diagrams**: per the Mermaid Mandate subsection below, include at least one Mermaid block.
6. **Proceed to Validation Before Save** — that step is the single source of
   truth for frontmatter, sections, Mermaid, and placeholder checks.

## Output Contract

### Required Frontmatter

```yaml
---
project: "{project_name}"
maturity: "draft"
last_updated: "{today_date}"
updated_by: "{updated_by}"
scope: "{one-liner describing what the PRD covers}"
owner: "{owning agent or team, e.g. @project-manager}"
dependencies:
  - {DOC-<n> of related doc, or empty list}
status: "draft"
---
```

Field rules:

- `project` = `basename $(git rev-parse --show-toplevel)`.
- `maturity` is the doc-class ladder for living product definitions — one of
  `proof-of-concept | draft | experimental | stable`. New PRDs start at `draft`.
- `status` mirrors Docket's own doc-level status (`-s`) — one of `draft | approved`.
  The authoritative copy is Docket's `.data.status` (via `docket doc show <DOC-id>
  --json`) — the single source of truth for downstream gates; this body `status:` is
  documentation-only, NOT auto-updated by `docket doc edit <DOC-id> -s`, and may drift
  stale, so never gate on it.
  New PRDs start at `draft`; promotion to `approved` happens after the calling agent's
  review loop via `docket doc edit <DOC-id> -s approved`. (`maturity` and `status` are
  orthogonal: `maturity` is how settled the content is, `status` is where the doc sits
  in the review lifecycle.)
- `last_updated` is ISO date `YYYY-MM-DD`.
- `updated_by` is the calling agent identifier (`@project-manager`, etc.).
- `scope` is a one-line description of what the PRD covers — populated by the
  calling agent.
- `owner` is the responsible agent or team handle.
- `dependencies` is a YAML array of related `DOC-<n>` ids; use `[]` if none.

### Required Sections

The PRD body MUST contain these top-level sections, in this order. Each is a
`##` heading in the drafted document.

1. **Problem Statement** — what the product surface is, why now, who is affected,
   constraints, business context.
2. **Goals** — concrete, testable outcomes the PRD commits to.
3. **Non-Goals** — explicit out-of-scope items, including future-work flags.
4. **User Stories / Use Cases** — narrative scenarios from the operator/user
   perspective, with explicit per-story priority (P0/P1/P2 or MVP/polish — pick one
   scheme and apply it consistently). Bare "with priorities" without a named scheme
   is a defect.
5. **Requirements** — functional and non-functional, prioritized using MoSCoW (Must / Should / Could / Won't). Each requirement MUST be testable: a reviewer must be able to point at a behavior and say "this satisfies / does not satisfy" without a follow-up clarification.
6. **Success Metrics** — quantitative measures that validate Goals are met. Each
   metric MUST name (a) what is measured, (b) the measurement method, and (c) a
   numeric target or threshold. "Improve UX" is a defect; "p95 first-token latency
   under 800ms measured via /metrics endpoint" is acceptable.
7. **Risks & Open Questions** — risk table (likelihood/impact/mitigation); open
   questions resolved or escalated before decomposition into Docket issues.

### Mermaid Mandate

PRDs require at least one ` ```mermaid ` (lowercase, no space) fenced block — user journey, state diagram, or component map. Unlike TDDs, there is no pure-policy override; Validation §5 enforces this.

## Validation Before Save

Before invoking `Write`, verify in the calling agent's context:

1. **Frontmatter fields** — all of `project`, `maturity`, `last_updated`,
   `updated_by`, `scope`, `owner`, `dependencies`, `status` present and non-empty
   (`dependencies` may be the empty list `[]`).
2. **`status` value** — `status` is one of `draft | approved`.
3. **`maturity` value** — within the allowed set defined under Field rules above.
4. **Section order** — the body contains all top-level sections enumerated in "Required Sections" above, as `##` headings, in the order listed. Count only `##` headings at column 0 *outside* ``` code fences — a PRD that documents another doc/skill may embed `##`/`###` example headings inside fences; those are content, not structure.
5. **Mermaid presence** — at least one ` ```mermaid ` fenced block in the body.
6. **Placeholder scan** — body contains no literal `{title}`, `{topic}`,
   `{project_name}`, `TBD`, or `TODO` text outside of code-fenced examples.
7. **Success Metrics concreteness** — every bullet/item under the Success Metrics
   section contains at least one digit OR a comparison operator (`<`, `>`, `≤`, `≥`,
   `=`). A Success Metrics section with zero numeric targets is a defect.

If any check fails, ABORT (no fix-and-retry — the skill validates then writes
in a single pass; repair is the calling agent's responsibility):

```
Error: validation failed: {field/section} — {detail}.
```

The calling agent fixes the issue in its own context and re-invokes
`Skill(prd, "<topic>")`.

## Create & Return

<!-- CANONICAL:SAVE_AND_RETURN:BEGIN -->
After Validation Before Save passes, create the doc in Docket. The full document body
(frontmatter block + all Required Sections) is drafted to a temp file, then supplied to
`docket doc create` via `-d @`:

1. `Write` the full drafted document body to a temp file under `$TMPDIR`:

   ```
   BODY="${TMPDIR:-/tmp}/prd-doc.md"
   ```

2. Create the doc (type `prd`, create-status `draft`), capturing JSON:

   ```
   docket doc create -T prd -t "{title}" -s draft -d @"$BODY" --json
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

### Reserved-Name List

The 7 names below are owned by the `init-specs` skill (project-wide engineering specs
that stay markdown under `docs/spec/`) and HARD-REFUSED by this skill. There is no
overwrite path — a topic that normalizes to one of these names is never authored as a
`prd` doc.

<!-- COUPLING: the 7 reserved names are owned by skills/init-specs (Spec File Reference) and HARD-REFUSED here so a prd doc is never authored under a baseline-spec name (those stay markdown under docs/spec/). Sibling doc-authoring skills (tdd, adr, ux-spec) create docs of a different type, so they do not refuse these names. Update init-specs and this file in lockstep when adding/removing names. -->
<!-- RESERVED-NAMES:BEGIN -->
architecture
security
operations
performance
code-quality
review-strategy
testing
<!-- RESERVED-NAMES:END -->

### Failure Mode Table

| Trigger | Handling |
|---|---|
| `<topic>` missing or empty | Abort: `Error: Usage: Skill(prd, "<topic>") — describe the artifact in 3-10 words.` |
| Title empty after trimming (e.g., all-punct topic) | Abort: `Error: Topic must contain at least one alphanumeric character.` |
| Topic normalizes to a reserved name (see list above) | Abort: `Error: '{normalized}' is a reserved baseline-spec name owned by the init-specs skill. Pick a different topic or use the init-specs skill to bootstrap project specs.` No overwrite path. |
| Validation Before Save fails | Abort with `Error: validation failed: {field/section} — {detail}.` No retry — calling agent re-invokes. |
| Mermaid mandate not satisfied | Abort: `Error: validation failed: Mermaid block missing — PRD requires at least one mermaid fenced block (user journey, state, or component map).` |
| Frontmatter `status` value outside the allowed set | Abort: `Error: validation failed: frontmatter — 'status' must be one of draft \| approved. Got '{value}'.` |
| `maturity` value outside the allowed set | Abort: `Error: validation failed: frontmatter — 'maturity' must be one of proof-of-concept \| draft \| experimental \| stable. Got '{value}'.` |
| Success Metrics section has no numeric targets | Abort: `Error: validation failed: Success Metrics — every metric must include a numeric target or threshold (e.g., 'p95 < 800ms'). Vague metrics are rejected.` |
| `docket doc create` returns a non-ok JSON envelope | Surface raw error: `Error: docket doc create failed — {message}.` Do NOT retry. The temp-file body remains on disk; the calling agent reports to the operator. |
| Caller passes additional positional args beyond `<topic>` | Ignore extras silently. |
