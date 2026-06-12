---
name: prd
description: >
  Author a single Product Requirements Document at docs/spec/{slug}.md. Loaded into the
  calling agent's context; the agent drafts the PRD per the format authority below.
  Trigger: "create PRD", "draft PRD", "write a product requirements document", "decompose this into a spec under docs/spec/", "write up requirements for", "scope this feature".
argument-hint: "<topic>"
allowed-tools: ["AskUserQuestion", "Bash", "Glob", "Grep", "Read", "Write"]
---

<!-- CANONICAL:BANNER:BEGIN -->
> **CRITICAL:** (1) Do NOT commit ANY changes (no `git add`, no `git commit`, no `git push`) unless EXPLICITLY instructed by the user. (2) This is a leaf skill. You MUST NOT spawn sub-agents, invoke `Skill()` recursively, or use `Agent()`, `TeamCreate`, `TeamDelete`, or `SendMessage`. The calling agent handles peer messaging after this skill returns.
<!-- CANONICAL:BANNER:END -->

# PRD — Author a Product Requirements Document

You are the **PRD Author**. You produce a single Product Requirements Document at
`docs/spec/{slug}.md` and return. The calling agent (typically `@project-manager`)
drafts the content; this skill is the format authority — section list, frontmatter
contract, output path, reserved-name refusal, and collision handling all live here.

<!-- CANONICAL:DOCS-PATHS-LOCAL:BEGIN -->
**Docs paths (this skill).** Master: team-lead.md §Docs-Path Taxonomy (maintained copy).
- Writes: `docs/spec/{slug}.md` (PRDs only — NOT the 7 reserved names).
- Reads: `docs/spec/`, `docs/tdd/`, `docs/ux/`.
- Always singular docs/spec/ — never docs/specs/.
<!-- CANONICAL:DOCS-PATHS-LOCAL:END -->

## Argument Handling

<!-- CANONICAL:ARGUMENT_HANDLING:BEGIN -->
The argument is a single positional `<topic>` (free-text, 3-10 words describing the
artifact). No flags, no other args.

If `<topic>` is missing or empty:

```
Error: Usage: Skill({TYPE}, "<topic>") — describe the artifact in 3-10 words.
```

If extra positional args are passed beyond `<topic>`, ignore them silently.

**Slug derivation** (deterministic):

1. `lower      = lowercase(topic)`
2. `cleaned    = re.sub(r'[^a-z0-9]+', '-', lower)`
3. `trimmed    = cleaned.strip('-')`
4. `truncated  = trimmed[:60]`
5. Prefer a word boundary in [40, 60): `boundary = truncated.rfind('-', 40, 60)`. If
   `boundary != -1`, set `truncated = truncated[:boundary]`.
6. `truncated  = truncated.strip('-')` (re-trim after step 5).
7. If `truncated == ""`, ABORT: `Error: Topic must contain at least one alphanumeric character.`
8. Use `truncated` as `{slug}`.
<!-- CANONICAL:ARGUMENT_HANDLING:END -->

## When to Use

- A feature-level Product Requirements Document is needed for a non-trivial product surface (new feature, UX-driven change, scope-defined initiative) and should land at `docs/spec/{slug}.md` as the authoritative product record. Pick PRD over TDD when scope precedes architecture — what and why is uncertain, not how.
- The calling agent (typically `@project-manager`) is producing a PRD before decomposition into Docket issues so reviewers and implementers share one product definition.
- The team-lead Large Task pattern (`agents/team-lead.md`) requests a PRD as the entry point for product-defined initiatives — this skill is the canonical path.

## When NOT to Use

<!-- COUPLING: this skill is part of the doc-authoring family. The "When NOT to Use" delegation routes below MUST stay in sync with skills/claude-code/tdd, adr, ux-spec, and init-specs — update all 5 in lockstep when adding/removing a sibling skill. -->
- Inline scoping notes, advisory replies, decomposition comments, or scratch ideas
  that are not meant to live at `docs/spec/`.
- Technical Design Documents (architecture, system design, multi-step migration):
  use `Skill(tdd, "<topic>")`.
- Architecture Decision Records (single decisions): use `Skill(adr, "<topic>")`.
- UX / design specs: use `Skill(ux-spec, "<topic>")`.
- Project-wide engineering specs (the 7 reserved names: architecture, security,
  operations, performance, code-quality, review-strategy, testing): owned by the
  `init-specs` skill. This skill HARD-REFUSES those names — see Pre-flight step 4
  and Failure Modes.

## Pre-flight

1. **Resolve `{slug}`** from `<topic>` per the Argument Handling slug rule above.
2. **Resolve `{output_path}`** as `docs/spec/{slug}.md`. The output directory is
   `docs/spec/`.
3. **Resolve context**:
   - `{today_date}` = `Bash date +%Y-%m-%d`.
   - `{project_name}` = `Bash basename $(git rev-parse --show-toplevel)`.
   - `{updated_by}` = the calling agent's identifier (e.g., `@project-manager`).
4. **Reserved-name refusal**: if `{slug}` matches a name in the Failure Modes Reserved-Name List, ABORT per the Failure Mode table (no overwrite path) — checked before collision so reserved files never reach the overwrite dialog.
5. **Check collision**: `Glob docs/spec/{slug}.md`. If a file exists at
   `{output_path}`, run the COLLISION_DIALOG below.

<!-- CANONICAL:COLLISION_DIALOG:BEGIN -->
If a file already exists at the target output path, invoke `AskUserQuestion`:

```
AskUserQuestion(
  header: "File exists",
  question: "{output_path} already exists. How should I proceed?",
  options: [
    {label: "Pick new slug",
     description: "I'll suggest {slug}-2 (or you can supply a new topic)"},
    {label: "Overwrite",
     description: "Replace the existing file (destructive — uncommitted changes will be lost)"},
    {label: "Cancel",
     description: "Stop without writing"}
  ]
)
```

- "Pick new slug" → suggest `{slug}-2`, then `{slug}-3`, etc. via free-text follow-up.
- "Overwrite" → proceed to Authoring Procedure; the existing file will be replaced on Write.
- "Cancel" → emit `Cancelled — no file written.` and end.

Never silently overwrite. There is no "append" option — partial appends produce
malformed frontmatter.
<!-- CANONICAL:COLLISION_DIALOG:END -->

## Authoring Procedure

1. **Gather prior art**: `Grep -r "{topic-keywords}" docs/` and read related PRDs
   already in `docs/spec/` (the 7 reserved engineering specs — see the Reserved-Name
   List — are project-level conventions, not PRDs; skip them unless the PRD genuinely
   depends on one). Read any TDDs in `docs/tdd/` or design specs in `docs/ux/` that
   touch the same surface — the new PRD should reference, not contradict, prior accepted
   product definitions, and record each one the PRD builds on in the `dependencies`
   frontmatter field so reviewers and decomposition can trace the lineage.
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
  - {relative path to related doc, or empty list}
---
```

Field rules:

- `project` = `basename $(git rev-parse --show-toplevel)`.
- `maturity` is the doc-class ladder for living product definitions — one of
  `proof-of-concept | draft | experimental | stable`. New PRDs start at `draft`.
- **PRDs do NOT use a `status` field.** `status` is reserved for in-flight workflow
  artifacts (TDDs and ADRs). PRDs are living product definitions — they take
  `maturity` from the `init-specs` family ladder.
- `last_updated` is ISO date `YYYY-MM-DD`.
- `updated_by` is the calling agent identifier (`@project-manager`, etc.).
- `scope` is a one-line description of what the PRD covers — populated by the
  calling agent.
- `owner` is the responsible agent or team handle.
- `dependencies` is a YAML array of related-file paths (relative to the doc); use
  `[]` if none.

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
   `updated_by`, `scope`, `owner`, `dependencies` present and non-empty
   (`dependencies` may be the empty list `[]`).
2. **No `status` field** — PRDs use `maturity`, not `status`. Presence of `status`
   in frontmatter is a defect.
3. **`maturity` value** — within the allowed set defined under Field rules above.
4. **Section order** — the body contains all top-level sections enumerated in "Required Sections" above, as `##` headings, in the order listed. Count only `##` headings at column 0 *outside* ``` code fences — a PRD that documents another doc/skill may embed `##`/`###` example headings inside fences; those are content, not structure.
5. **Mermaid presence** — at least one ` ```mermaid ` fenced block in the body.
6. **Placeholder scan** — body contains no literal `{slug}`, `{topic}`,
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

## Save & Return

<!-- CANONICAL:SAVE_AND_RETURN:BEGIN -->
After Validation Before Save passes:

1. `Bash mkdir -p {output_dir}` (idempotent).
2. `Write {output_path}` with the drafted content.
3. Emit a single confirmation line:

   ```
   Created {output_path}
   ```

End. Do NOT echo the file body, do NOT send peer messages, do NOT invoke other skills.
The calling agent owns next steps (vote requests, decomposition, peer notification).

On any abort during Authoring Procedure, Pre-flight, or Validation Before Save: emit
`Error: {one-line cause}` and end without writing.

On operator Cancel during the collision dialog: emit
`Cancelled — no file written.` and end without writing.
<!-- CANONICAL:SAVE_AND_RETURN:END -->

## Failure Modes

### Reserved-Name List

The 7 names below are owned by the `init-specs` skill (project-wide engineering specs)
and HARD-REFUSED by this skill. There is no overwrite path.

<!-- COUPLING: the 7 reserved names are owned by skills/claude-code/init-specs (Spec File Reference) and HARD-REFUSED here because PRD shares docs/spec/ as its output directory. Sibling doc-authoring skills (tdd, adr, ux-spec) write to different directories (docs/tdd/, docs/tdd/adr/, docs/ux/) so they do not refuse these names. Update init-specs and this file in lockstep when adding/removing names. -->
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
| Slug empty after sanitization (e.g., all-CJK or all-punct topic) | Abort: `Error: Topic must contain at least one alphanumeric character.` |
| Slug matches a reserved name (see list above) | Abort: `Error: '{slug}.md' is a reserved name owned by the init-specs skill. Pick a different topic or use the init-specs skill to bootstrap project specs.` No overwrite path. |
| Output file already exists (and slug is not reserved) | Run COLLISION_DIALOG; never silently overwrite. On Cancel: `Cancelled — no file written.` |
| Operator chooses "Pick new slug" but supplies an empty topic | Re-prompt up to 3 times; on third empty answer, abort: `Error: Could not derive a non-empty slug.` |
| Validation Before Save fails | Abort with `Error: validation failed: {field/section} — {detail}.` No retry — calling agent re-invokes. |
| Mermaid mandate not satisfied | Abort: `Error: validation failed: Mermaid block missing — PRD requires at least one mermaid fenced block (user journey, state, or component map).` |
| Frontmatter contains `status` field | Abort: `Error: validation failed: frontmatter — PRDs use 'maturity', not 'status'. Remove the status field.` |
| `maturity` value outside the allowed set | Abort: `Error: validation failed: frontmatter — 'maturity' must be one of proof-of-concept \| draft \| experimental \| stable. Got '{value}'.` |
| Success Metrics section has no numeric targets | Abort: `Error: validation failed: Success Metrics — every metric must include a numeric target or threshold (e.g., 'p95 < 800ms'). Vague metrics are rejected.` |
| Filesystem write fails (permissions, disk, read-only mount) | Surface raw error: `Error: Write failed — {raw error}.` Do NOT retry. The calling agent reports to the operator. |
