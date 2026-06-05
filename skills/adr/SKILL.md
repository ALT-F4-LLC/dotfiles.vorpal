---
name: adr
description: >
  Author a single Architecture Decision Record as a Docket doc (docket doc create -T adr).
  Loaded into the calling agent's context; the agent drafts the ADR per the format
  authority below.
  Trigger: "create ADR", "record this decision", "draft an architecture decision record", "log architectural decision".
argument-hint: "<topic>"
effort: max
allowed-tools: ["AskUserQuestion", "Bash", "Read", "Write"]
---

<!-- CANONICAL:BANNER:BEGIN -->
> **CRITICAL:** (1) Do NOT commit ANY changes (no `git add`, no `git commit`, no `git push`) unless EXPLICITLY instructed by the user. (2) This is a leaf skill. You MUST NOT spawn sub-agents, invoke `Skill()` recursively, or use `Agent()`, `TeamCreate`, `TeamDelete`, or `SendMessage`. The calling agent handles peer messaging after this skill returns.
<!-- CANONICAL:BANNER:END -->

# ADR — Author an Architecture Decision Record

You are the **ADR Author**. You produce a single Architecture Decision Record as a
Docket doc (type `adr`) and return. The calling agent (typically `@staff-engineer`)
drafts the content; this skill is the format authority — section list, frontmatter
contract, the `docket doc create` recipe, and the supersession convention all live
here. Docket issues the document's `DOC-<n>` identity — there is no numbered or
filename-based identity.

## Argument Handling

<!-- CANONICAL:ARGUMENT_HANDLING:BEGIN -->
The argument is a single positional `<topic>` (free-text, 3-10 words describing the
artifact). No flags, no other args.

If `<topic>` is missing or empty:

```
Error: Usage: Skill({TYPE}, "<topic>") — describe the artifact in 3-10 words.
```

If extra positional args are passed beyond `<topic>`, ignore them silently.

**Title derivation.** The document's identity is the Docket-issued `DOC-<n>`, not an ADR
number or filename — there is no numbering step and no slug-to-path step. The `<topic>`
is the human-readable `-t` title (Title Case, free prose). Use `<topic>` verbatim as the
default `{title}`; the calling agent MAY refine it into a clearer prose title. Reject
only an empty/all-punctuation topic that yields no title text:

1. `cleaned = topic.strip()`.
2. If `cleaned` contains no alphanumeric character, ABORT: `Error: Topic must contain at least one alphanumeric character.`
3. Use `cleaned` (or a calling-agent refinement of it) as `{title}`.
<!-- CANONICAL:ARGUMENT_HANDLING:END -->

## When to Use

- A single architectural or design decision needs to be recorded as an immutable
  Docket `adr` doc (identified by its `DOC-<n>`) so future readers can trace the why.
- The calling agent (typically `@staff-engineer`) is logging a decision that emerged
  during design, review, or implementation and that future work will need to reference.
- The decision has long-term consequences (e.g., choice of library, protocol, schema
  shape, naming convention) and a one-line note in a TDD or PR is not enough.

## When NOT to Use

<!-- COUPLING: this skill is part of the doc-authoring family. The "When NOT to Use" delegation routes below MUST stay in sync with skills/prd, tdd, ux-spec, and init-specs — update all 5 in lockstep when adding/removing a sibling skill. -->
- Inline advisory replies, review comments, scratch notes, or one-off design
  sketches that are not meant to live as a Docket `adr` doc.
- Full system designs spanning multiple components or phases: use
  `Skill(tdd, "<topic>")`.
- Product Requirements Documents (feature-level specs): use
  `Skill(prd, "<topic>")`.
- UX / design specs: use `Skill(ux-spec, "<topic>")`.
- Project-wide engineering specs (architecture, security, operations, performance,
  code-quality, review-strategy, testing): owned by the `init-specs` skill.

## Pre-flight

1. **Resolve `{title}`** from `<topic>` per the Argument Handling title rule above.
2. **Resolve context**:
   - `{today_date}` = `Bash date +%Y-%m-%d`.
   - `{project_name}` = `Bash basename $(git rev-parse --show-toplevel)`.
   - `{updated_by}` = the calling agent's identifier (e.g., `@staff-engineer`).
3. **Supersession check**: if this decision replaces an earlier ADR, identify the old
   ADR's `DOC-<n>` via `docket doc list -T adr --json`. Carry `{old_doc}` into the
   supersession workflow in Create & Return. Docket does not collide on title, so there
   is no overwrite path — a new create always issues a fresh `DOC-<n>`.

## Authoring Procedure

1. **Gather prior art**: discover related decisions and designs with
   `docket doc list -T adr --json`, `docket doc list -T tdd --json`,
   `docket doc list -T prd --json`, and `docket doc list -T ux --json`; read candidate
   predecessors via `docket doc show <DOC-id>`. Find any ADR/TDD/PRD/UX doc that may be
   superseded, reinforced, or contradicted by this decision, and cite each by its
   `DOC-<n>` in the new ADR's `Context`.
2. **Draft the frontmatter** per the Required Frontmatter contract below. Set
   `status: "proposed"` initially; `accepted` is set after the calling agent's
   review/vote loop, not by this skill.
3. **Draft each Required Section in order** (see Output Contract → Required
   Sections). Every section listed MUST appear, in the order shown. ADRs are
   intentionally short — aim for tight prose, not exhaustive coverage. Mermaid
   is optional; include a block only when it clarifies component, state, or
   flow relationships.
4. **Proceed to Validation Before Save** — single source of truth for
   frontmatter, section order, alternatives count, and placeholder checks.

## Output Contract

### Required Frontmatter

```yaml
---
project: "{project_name}"
last_updated: "{today_date}"
updated_by: "{updated_by}"
status: "proposed"
superseded_by: "DOC-<new>"
---
```

Field rules:

- `project` = `basename $(git rev-parse --show-toplevel)`.
- `last_updated` is ISO date `YYYY-MM-DD`.
- `updated_by` is the calling agent identifier (`@staff-engineer`, etc.).
- `status` is one of: `proposed | accepted | superseded`. New ADRs start at
  `proposed`. Promotion to `accepted` happens after the calling agent's review;
  `superseded` is set when a later ADR replaces this one. ADR intentionally
  retains this `proposed → accepted → superseded` ladder while `tdd`, `prd`, and
  `ux` docs use `draft → approved`; the divergence is by design — do not
  reconcile them.
- `superseded_by` is required only when `status: superseded` and points to the
  successor ADR's `DOC-<n>` id (e.g., `DOC-42`). Omit the line entirely otherwise.

### Required Sections

The ADR body MUST contain these top-level sections, in this order. Each is a `##`
heading in the drafted document.

1. **Context** — the decision-driver: what situation, constraint, or trigger forced
   this decision. Cite related TDDs, PRDs, ADRs, or incidents.
2. **Decision** — the chosen approach, stated affirmatively in one or two
   paragraphs.
3. **Consequences** — positive, negative, and neutral consequences. Include
   what becomes easier and what becomes harder.
4. **Alternatives Considered** (brief) — at least one alternative with a short
   verdict. Full multi-alternative analysis belongs in a TDD.

## Validation Before Save

Before invoking `Write`, verify in the calling agent's context:

1. **Frontmatter fields** — all of `project`, `last_updated`, `updated_by`,
   `status` present and non-empty. If `status: superseded`, `superseded_by`
   must also be present, non-empty, and a `DOC-<n>` id.
2. **Status value** — `status` is one of `proposed | accepted | superseded`.
3. **Section order** — the body contains all top-level sections enumerated
   in "Required Sections" above, as `##` headings, in the order listed
   (currently 4 sections). Off-by-one against the count is a defect.
4. **Alternatives count** — Section 4 (Alternatives Considered) names at
   least one alternative.
5. **Placeholder scan** — body contains no literal `{title}`, `{topic}`,
   `{project_name}`, `TBD`, or `TODO` text outside of code-fenced examples.

If any check fails, ABORT with:

```
Error: validation failed: {field/section} — {detail}.
```

## Create & Return

<!-- CANONICAL:SAVE_AND_RETURN:BEGIN -->
After Validation Before Save passes, create the doc in Docket. The full document body
(frontmatter block + all Required Sections) is drafted to a temp file, then supplied to
`docket doc create` via `-d @`:

1. `Write` the full drafted document body to a temp file under `$TMPDIR`:

   ```
   BODY="${TMPDIR:-/tmp}/adr-doc.md"
   ```

2. Create the doc (type `adr`, create-status `proposed`), capturing JSON:

   ```
   docket doc create -T adr -t "{title}" -s proposed -d @"$BODY" --json
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

### Supersession (ADR-specific)

When this new ADR (`DOC-<new>`) supersedes an earlier ADR (`{old_doc}` =
`DOC-<old>`, identified in Pre-flight step 3), the two docs carry different pointers:

- **The NEW/superseding ADR** (`DOC-<new>`) carries a `Supersedes DOC-<old>` line in its
  `Context` section body (drafted before create). It does NOT set `superseded_by`.
- **The OLD/superseded ADR** (`DOC-<old>`) is transitioned after the new doc exists:
  1. `docket doc edit DOC-<old> -s superseded --json` (status bump → new revision),
  2. `docket doc comment add DOC-<old> -m "Superseded by DOC-<new>."` (audit breadcrumb),
  3. set its body frontmatter `superseded_by: DOC-<new>` via the same
     `docket doc edit DOC-<old> -d @"$BODY"` if the body is being re-supplied.

Identity is the `DOC-<n>` throughout — neither pointer uses a numbered or filename-based
form.

## Failure Modes

| Trigger | Handling |
|---|---|
| `<topic>` missing or empty | Abort: `Error: Usage: Skill(adr, "<topic>") — describe the artifact in 3-10 words.` |
| Title empty after trimming (e.g., all-punct topic) | Abort: `Error: Topic must contain at least one alphanumeric character.` |
| Validation Before Save fails | Abort with `Error: validation failed: {field/section} — {detail}.` No retry — calling agent re-invokes. |
| `docket doc create` returns a non-ok JSON envelope | Surface raw error: `Error: docket doc create failed — {message}.` Do NOT retry. The temp-file body remains on disk; the calling agent reports to the operator. |
| Caller passes additional positional args beyond `<topic>` | Ignore extras silently. |

