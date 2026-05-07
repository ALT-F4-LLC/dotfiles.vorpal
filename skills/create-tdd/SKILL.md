---
name: create-tdd
description: >
  Author a single Technical Design Document at docs/tdd/{slug}.md. Loaded into the
  calling agent's context; the agent drafts the TDD per the format authority below.
  Trigger: "create TDD", "draft TDD", "produce a technical design document", "write the design for {feature}".
argument-hint: "<topic>"
effort: max
allowed-tools: ["AskUserQuestion", "Bash", "Glob", "Grep", "Read", "Write"]
---

<!-- CANONICAL:BANNER:BEGIN -->
> **CRITICAL:** (1) Do NOT commit ANY changes (no `git add`, no `git commit`, no `git push`) unless EXPLICITLY instructed by the user. (2) This is a leaf skill. You MUST NOT spawn sub-agents, invoke `Skill()` recursively, or use `Agent()`, `TeamCreate`, `TeamDelete`, or `SendMessage`. The calling agent handles peer messaging after this skill returns.
<!-- CANONICAL:BANNER:END -->

# Create TDD — Author a Technical Design Document

You are the **TDD Author**. You produce a single Technical Design Document at
`docs/tdd/{slug}.md` and return. The calling agent (typically `@staff-engineer`)
drafts the content; this skill is the format authority — section list, frontmatter
contract, output path, and collision handling all live here.

## Argument Handling

<!-- CANONICAL:ARGUMENT_HANDLING:BEGIN -->
The argument is a single positional `<topic>` (free-text, 3-10 words describing the
artifact). No flags, no other args.

If `<topic>` is missing or empty:

```
Error: Usage: Skill(create-{TYPE}, "<topic>") — describe the artifact in 3-10 words.
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

For this skill, substitute `{TYPE}` with `tdd` in the usage error.

## When to Use

- A Technical Design Document is needed for non-trivial work (architecture, system
  design, multi-step migration, cross-cutting refactor) and should land at
  `docs/tdd/{slug}.md` as the authoritative design record.
- The calling agent (typically `@staff-engineer`) is producing a design that needs to
  go through the draft → questions-resolved → in-review → accepted lifecycle.
- The `dev` skill's Medium Task pattern asks for a TDD without a separate PRD — this
  skill is the canonical path.

## When NOT to Use

- Inline advisory replies, review comments, scratch notes, or one-off design
  sketches that are not meant to live at `docs/tdd/`.
- Architecture Decision Records (single decisions): use `Skill(create-adr, "<topic>")`.
- Product Requirements Documents (feature-level specs): use
  `Skill(create-prd, "<topic>")`.
- UX / design specs: use `Skill(create-ux-spec, "<topic>")`.
- Project-wide engineering specs (architecture, security, operations, performance,
  code-quality, review-strategy, testing): owned by the `specs` skill.

## Pre-flight

1. **Resolve `{slug}`** from `<topic>` per the Argument Handling slug rule above.
2. **Resolve `{output_path}`** as `docs/tdd/{slug}.md`. The output directory is
   `docs/tdd/`.
3. **Resolve context**:
   - `{today_date}` = `Bash date +%Y-%m-%d`.
   - `{project_name}` = `Bash basename $(git rev-parse --show-toplevel)`.
   - `{updated_by}` = the calling agent's identifier (e.g., `@staff-engineer`).
4. **Check collision**: `Glob docs/tdd/{slug}.md`. If a file exists at
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

5. **Parent-PRD probe** (TDD-specific):
   1. Split the slug on `-` to derive a keyword set; drop stopwords (`the`, `a`,
      `an`, `for`, `to`, `of`, `and`, `or`).
   2. Run `Glob docs/spec/*{keyword}*.md` for each keyword and aggregate matches.
   3. Fallback: `Grep -l "{topic-without-stopwords}" docs/spec/*.md`.
   4. If 1+ results found: list them inline (informational, not blocking) and
      proceed to Authoring Procedure. Note the candidate parent(s) for use in the
      `dependencies` frontmatter field.
   5. If zero results found, invoke `AskUserQuestion`:

   ```
   AskUserQuestion(
     header: "No matching PRD found",
     question: "I searched docs/spec/ for a PRD related to '{topic}' and found
                none. Proceed without a parent PRD?",
     options: [
       {label: "Proceed",
        description: "Author the TDD; PRD can come later"},
       {label: "Author PRD first",
        description: "Cancel; I'll create the PRD with create-prd, then re-invoke"},
       {label: "Cancel",
        description: "Stop without writing"}
     ]
   )
   ```

   - "Proceed" → continue to Authoring Procedure with `dependencies: []`.
   - "Author PRD first" → emit `Cancelled — no file written.` and end. The calling
     agent re-invokes after authoring the PRD.
   - "Cancel" → emit `Cancelled — no file written.` and end.

## Authoring Procedure

1. **Gather prior art**: `Grep -r "{topic-keywords}" docs/` and read any candidate
   parent PRD identified in Pre-flight step 5. Read existing TDDs in `docs/tdd/`
   that touch adjacent areas — the new TDD should reference, not contradict, prior
   accepted work.
2. **Draft the frontmatter** per the Required Frontmatter contract below. Set
   `status: "draft"` initially.
3. **Draft each Required Section in order** (see Output Contract → Required
   Sections). Every section listed MUST appear, in the order shown. Sections marked
   "or N/A" may contain a single `N/A.` paragraph with a one-line justification —
   omitting them is a defect.
4. **Mermaid diagrams**: per the Mermaid Mandate, include at least one Mermaid
   block where the design involves architecture, sequence, state, or data
   relationships. For pure-policy TDDs (e.g., "we will use semantic versioning")
   prose alone is acceptable; explicitly note the override here in the Authoring
   Procedure of the drafted document (one line in §4 or the Architecture section
   stating "Pure-policy TDD — no Mermaid required.").
5. **Alternatives Considered**: at least two alternatives, each with shape,
   strengths, weaknesses, and a verdict. The chosen alternative should match the
   Architecture & System Design section.
6. **Risks & Open Questions**: enumerate risks with likelihood/impact/mitigation;
   flag any open questions that must be resolved before vote.
7. **Implementation Phases**: split the work into phases with file scoping and
   per-phase acceptance. The planner consumes this section directly.
8. **Self-check** before proceeding to Validation Before Save:
   - All frontmatter fields populated (no `TODO`, no empty strings).
   - All Required Sections present, in order.
   - Mermaid block(s) present where mandated, OR explicit override note recorded.
   - At least two Alternatives Considered.
   - No placeholder text (`{slug}`, `{topic}`, `TBD`) leaked into the body.

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
  - {relative path to parent PRD or related doc, or empty list}
status: "draft"
---
```

Field rules:

- `project` = `basename $(git rev-parse --show-toplevel)`.
- `maturity` is the doc-class ladder; `status` is the workflow ladder. Both fields
  are required for TDDs (see TDD §4.3).
- `last_updated` is ISO date `YYYY-MM-DD`.
- `updated_by` is the calling agent identifier (`@staff-engineer`, etc.).
- `scope` is a one-line description of what the doc covers — populated by the
  calling agent.
- `owner` is the responsible agent or team handle.
- `dependencies` is a YAML array of related-file paths (relative to the doc); use
  `[]` if none.
- `status` is one of: `draft | questions-resolved | in-review | accepted | superseded`.
  New TDDs start at `draft`.

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
   needed (component map, data flow, sequencing, contracts).
5. **Data Models & Storage** — schemas, persistence, migrations. May be `N/A.`
   with one-line justification if the design has no data plane.
6. **API Contracts** — request/response shapes, RPC contracts, CLI invocation
   shapes. May be `N/A.` with one-line justification.
7. **Migration & Rollout** — current state, target state, rollout sequencing,
   backward compatibility, rollback plan.
8. **Risks & Open Questions** — risk table (likelihood/impact/mitigation); open
   questions resolved or escalated before vote.
9. **Testing Strategy** — test levels, smoke tests, coverage of acceptance
   criteria, untested-claims inventory.
10. **Observability & Operational Readiness** — signals, 3am diagnosability,
    production readiness, runbooks.
11. **Implementation Phases** — partitioned phases with file scoping, per-phase
    acceptance, effort estimates, out-of-scope flags.

### Mermaid Mandate

Mermaid is **required** where the design involves architecture, sequence, state,
or data relationships. Acceptable block fences are ` ```mermaid ` (lowercase, no
space). At minimum, include a high-level component map OR an authoring/data-flow
sequence diagram.

For **pure-policy TDDs** (e.g., "we will adopt semantic versioning", "use Apache
2.0 license"), prose is acceptable. The Authoring Procedure §4 above requires an
explicit one-line override note inside the document acknowledging the
pure-policy classification.

This is judgment by the calling agent: validation enforces Mermaid presence
unless the document contains the override note.

## Validation Before Save

Before invoking `Write`, verify in the calling agent's context:

1. **Frontmatter fields** — all of `project`, `maturity`, `last_updated`,
   `updated_by`, `scope`, `owner`, `dependencies`, `status` present and
   non-empty (`dependencies` may be the empty list `[]`).
2. **Status value** — `status` is one of `draft | questions-resolved |
   in-review | accepted | superseded`.
3. **Section order** — the body contains all 11 Required Sections, as `##`
   headings, in the order listed.
4. **Alternatives count** — Section 3 (Alternatives Considered) contains at
   least two alternatives (look for `### Alt` or two `###`-level subsections).
5. **Mermaid presence** — at least one ` ```mermaid ` fenced block in the
   body, OR a pure-policy override note recorded per the Mermaid Mandate.
6. **Placeholder scan** — body contains no literal `{slug}`, `{topic}`,
   `{project_name}`, `TBD`, or `TODO` text outside of code-fenced examples.

If any check fails, ABORT (no fix-and-retry — `Edit` is excluded from this
skill's tools):

```
Error: validation failed: {field/section} — {detail}.
```

The calling agent fixes the issue in its own context (it has its own tools)
and re-invokes `Skill(create-tdd, "<topic>")`.

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

On operator Cancel during the collision dialog or missing-parent prompt: emit
`Cancelled — no file written.` and end without writing.
<!-- CANONICAL:SAVE_AND_RETURN:END -->

For this skill, `{output_dir}` is `docs/tdd/` and `{output_path}` is
`docs/tdd/{slug}.md`.

## Failure Modes

| Trigger | Handling |
|---|---|
| `<topic>` missing or empty | Abort: `Error: Usage: Skill(create-tdd, "<topic>") — describe the artifact in 3-10 words.` |
| Slug empty after sanitization (e.g., all-CJK or all-punct topic) | Abort: `Error: Topic must contain at least one alphanumeric character.` |
| Output file already exists | Run COLLISION_DIALOG; never silently overwrite. On Cancel: `Cancelled — no file written.` |
| Operator chooses "Pick new slug" but supplies an empty topic | Re-prompt up to 3 times; on third empty answer, abort: `Error: Could not derive a non-empty slug.` |
| Parent-PRD probe finds zero results | Run the missing-parent AskUserQuestion. On "Author PRD first" or "Cancel": `Cancelled — no file written.` |
| Validation Before Save fails | Abort with `Error: validation failed: {field/section} — {detail}.` No retry — calling agent re-invokes. |
| Mermaid mandate not satisfied AND no pure-policy override note | Abort: `Error: validation failed: Mermaid block missing — TDD requires Mermaid where architecture/sequence/state/data relationships are involved, or an explicit pure-policy override note.` |
| Filesystem write fails (permissions, disk, read-only mount) | Surface raw error: `Error: Write failed — {raw error}.` Do NOT retry. The calling agent reports to the operator. |
| Caller passes additional positional args beyond `<topic>` | Ignore extras silently. |
| Calling agent attempts to spawn sub-agents from inside this skill | Forbidden by the BANNER above and by `allowed-tools`. The skill's tool surface excludes `Agent`, `TeamCreate`, `TeamDelete`, `Skill`, `SendMessage`, and `Edit`. |
