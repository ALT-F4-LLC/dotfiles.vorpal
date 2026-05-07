---
name: create-adr
description: >
  Author a single Architecture Decision Record at docs/tdd/adr/{NNNN}-{slug}.md. Loaded
  into the calling agent's context; the agent drafts the ADR per the format authority
  below.
  Trigger: "create ADR", "record this decision", "draft an architecture decision record", "log architectural decision".
argument-hint: "<topic>"
effort: max
allowed-tools: ["AskUserQuestion", "Bash", "Glob", "Grep", "Read", "Write"]
---

<!-- CANONICAL:BANNER:BEGIN -->
> **CRITICAL:** (1) Do NOT commit ANY changes (no `git add`, no `git commit`, no `git push`) unless EXPLICITLY instructed by the user. (2) This is a leaf skill. You MUST NOT spawn sub-agents, invoke `Skill()` recursively, or use `Agent()`, `TeamCreate`, `TeamDelete`, or `SendMessage`. The calling agent handles peer messaging after this skill returns.
<!-- CANONICAL:BANNER:END -->

# Create ADR — Author an Architecture Decision Record

You are the **ADR Author**. You produce a single Architecture Decision Record at
`docs/tdd/adr/{NNNN}-{slug}.md` and return. The calling agent (typically
`@staff-engineer`) drafts the content; this skill is the format authority — section
list, frontmatter contract, output path, ADR numbering, and collision handling all
live here.

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

For this skill, substitute `{TYPE}` with `adr` in the usage error.

## When to Use

- A single architectural or design decision needs to be recorded as an immutable
  artifact at `docs/tdd/adr/{NNNN}-{slug}.md` (numbered chronologically) so future
  readers can trace the why.
- The calling agent (typically `@staff-engineer`) is logging a decision that emerged
  during design, review, or implementation and that future work will need to reference.
- The decision has long-term consequences (e.g., choice of library, protocol, schema
  shape, naming convention) and a one-line note in a TDD or PR is not enough.

## When NOT to Use

- Inline advisory replies, review comments, scratch notes, or one-off design
  sketches that are not meant to live at `docs/tdd/adr/`.
- Full system designs spanning multiple components or phases: use
  `Skill(create-tdd, "<topic>")`.
- Product Requirements Documents (feature-level specs): use
  `Skill(create-prd, "<topic>")`.
- UX / design specs: use `Skill(create-ux-spec, "<topic>")`.
- Project-wide engineering specs (architecture, security, operations, performance,
  code-quality, review-strategy, testing): owned by the `create-specs` skill.

## Pre-flight

1. **Resolve `{slug}`** from `<topic>` per the Argument Handling slug rule above.
2. **Resolve `{output_dir}`** as `docs/tdd/adr/`.
3. **Resolve context**:
   - `{today_date}` = `Bash date +%Y-%m-%d`.
   - `{project_name}` = `Bash basename $(git rev-parse --show-toplevel)`.
   - `{updated_by}` = the calling agent's identifier (e.g., `@staff-engineer`).
4. **Collision handling**: ADR numbering (step 5 below) picks the next free
   `{NNNN}`, so a same-`{output_path}` collision should be impossible at Pre-flight
   time. Same-slug or same-number races are detected post-write in Save & Return.
   The COLLISION_DIALOG below remains the canonical handler if a pre-Write Glob ever
   does return an existing file at `{output_path}`.

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

5. **ADR numbering** (ADR-specific):
   1. `Glob docs/tdd/adr/*.md`.
   2. For each filename, match `^(\d{4})-[a-z0-9-]+\.md$` (basename only). Track
      filenames that do not match in `malformed[]`.
   3. If `malformed` is non-empty, ABORT:

      ```
      Error: Could not determine next ADR number.
             Existing ADR filenames must start with NNNN- (4-digit zero-padded).
             Found malformed: {malformed}.
      ```

   4. If there are no matching files, `next_num = 1`. Otherwise `next_num = max(matches) + 1`,
      where `max` is taken over the captured numeric group as integers.
   5. Format as `f"{next_num:04d}"` (4-digit zero-padded so chronological sort matches numeric sort up to ADR 9999).
   6. `{output_path}` = `docs/tdd/adr/{next_num:04d}-{slug}.md`.
   7. The numbering Glob is re-run inside Save & Return immediately before Write
      (see Save & Return step 1) — Authoring Procedure can take long enough for a
      concurrent author to claim the chosen `{NNNN}`.

## Authoring Procedure

1. **Gather prior art**: `Grep -r "{topic-keywords}" docs/tdd/adr/` to find related
   ADRs that may be superseded, reinforced, or contradicted by this decision. Read
   any candidate predecessors so the new ADR cites them in `Context`.
2. **Draft the frontmatter** per the Required Frontmatter contract below. Set
   `status: "proposed"` initially; `accepted` is set after the calling agent's
   review/vote loop, not by this skill.
3. **Draft each Required Section in order** (see Output Contract → Required
   Sections). Every section listed MUST appear, in the order shown. ADRs are
   intentionally short — aim for tight prose, not exhaustive coverage.
4. **Mermaid diagrams**: per the Mermaid Mandate, judgment call. ADRs about
   component relationships, state transitions, or flows MUST include a Mermaid
   block. ADRs about pure policy decisions ("use SemVer", "license under Apache
   2.0") may be prose-only. If pure-policy, record an explicit one-line override
   note in the Decision section: "Pure-policy ADR — no Mermaid required."
5. **Alternatives Considered** (brief): list at least one alternative with a
   one- or two-sentence verdict. ADRs are short; full Alt-A/Alt-B/Alt-C analysis
   belongs in a TDD, not an ADR.
6. **Consequences**: enumerate positive, negative, and neutral consequences.
   Future readers consult this section first when deciding whether the ADR still
   applies.
7. **Self-check** before proceeding to Validation Before Save:
   - All frontmatter fields populated (no `TODO`, no empty strings).
   - All Required Sections present, in order.
   - Mermaid block present where mandated, OR explicit pure-policy override note
     recorded.
   - At least one alternative considered.
   - No placeholder text (`{slug}`, `{topic}`, `{NNNN}`, `TBD`) leaked into the
     body.

## Output Contract

### Required Frontmatter

```yaml
---
project: "{project_name}"
last_updated: "{today_date}"
updated_by: "{updated_by}"
status: "proposed"
---
```

Field rules:

- `project` = `basename $(git rev-parse --show-toplevel)`.
- `last_updated` is ISO date `YYYY-MM-DD`.
- `updated_by` is the calling agent identifier (`@staff-engineer`, etc.).
- `status` is one of: `proposed | accepted | superseded`. New ADRs start at
  `proposed`. Promotion to `accepted` happens after the calling agent's review;
  `superseded` is set when a later ADR replaces this one.

ADRs intentionally omit `maturity`, `scope`, `owner`, and `dependencies` to keep
the file lean (see TDD §4.3 and `agents/staff-engineer.md` Responsibility 3).

### Required Sections

The ADR body MUST contain these top-level sections, in this order. Each is a `##`
heading in the drafted document.

1. **Context** — the decision-driver: what situation, constraint, or trigger forced
   this decision. Cite related TDDs, PRDs, ADRs, or incidents.
2. **Decision** — the chosen approach, stated affirmatively in one or two
   paragraphs. If the ADR is pure policy, the override note ("Pure-policy ADR —
   no Mermaid required.") lives here.
3. **Consequences** — positive, negative, and neutral consequences. Include
   what becomes easier and what becomes harder.
4. **Alternatives Considered** (brief) — at least one alternative with a short
   verdict. Full multi-alternative analysis belongs in a TDD.

### Mermaid Mandate

Mermaid is a **judgment call** for ADRs. Decisions about component relationships,
state transitions, sequence flows, or data shapes MUST include a Mermaid block —
diagrams disambiguate the decision better than prose. Decisions about pure policy
("use SemVer", "license under Apache 2.0", "team will follow this naming
convention") may be prose-only.

If pure-policy, record an explicit one-line override note in the Decision section:
"Pure-policy ADR — no Mermaid required." Validation Before Save accepts the ADR
without a Mermaid block when this note is present.

## Validation Before Save

Before invoking `Write`, verify in the calling agent's context:

1. **Frontmatter fields** — all of `project`, `last_updated`, `updated_by`,
   `status` present and non-empty.
2. **Status value** — `status` is one of `proposed | accepted | superseded`.
3. **Section order** — the body contains all 4 Required Sections, as `##`
   headings, in the order listed.
4. **Alternatives count** — Section 4 (Alternatives Considered) names at
   least one alternative.
5. **Mermaid presence** — at least one ` ```mermaid ` fenced block in the body,
   OR the pure-policy override note ("Pure-policy ADR — no Mermaid required.")
   recorded in the Decision section.
6. **Placeholder scan** — body contains no literal `{slug}`, `{topic}`,
   `{project_name}`, `{NNNN}`, `TBD`, or `TODO` text outside of code-fenced
   examples.

If any check fails, ABORT (no fix-and-retry — `Edit` is excluded from this
skill's tools):

```
Error: validation failed: {field/section} — {detail}.
```

The calling agent fixes the issue in its own context (it has its own tools)
and re-invokes `Skill(create-adr, "<topic>")`.

## Save & Return

<!-- CANONICAL:SAVE_AND_RETURN:BEGIN -->
After Validation Before Save passes:

1. `Bash mkdir -p {output_dir}` (idempotent).
2. **Re-run Pre-flight step 5** (numbering Glob + `next_num` + `{output_path}` resolution) so the chosen `{NNNN}` reflects the latest filesystem state. If `{NNNN}` changed, update the frontmatter / body references before Write.
3. `Write {output_path}` with the drafted content.
4. Emit a single confirmation line:

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

For this skill, `{output_dir}` is `docs/tdd/adr/` and `{output_path}` is
`docs/tdd/adr/{NNNN}-{slug}.md` (with `{NNNN}` resolved by Pre-flight step 5).

**Post-write race detection (best-effort)**: After Write, re-run `Glob
docs/tdd/adr/{NNNN}-*.md` (using the chosen `{NNNN}`). If more than one file is
returned, ABORT loudly:

```
Error: ADR number collision detected — another author may have raced you. Manual resolution required.
```

This catches different-slug concurrent races but NOT same-slug concurrent races
(see Failure Modes below).

## Failure Modes

| Trigger | Handling |
|---|---|
| `<topic>` missing or empty | Abort: `Error: Usage: Skill(create-adr, "<topic>") — describe the artifact in 3-10 words.` |
| Slug empty after sanitization (e.g., all-CJK or all-punct topic) | Abort: `Error: Topic must contain at least one alphanumeric character.` |
| Existing ADR filename does not match `^\d{4}-[a-z0-9-]+\.md$` | Abort: `Error: Could not determine next ADR number. Existing ADR filenames must start with NNNN- (4-digit zero-padded). Found malformed: {malformed}.` |
| Output file already exists at the resolved `{NNNN}-{slug}.md` path | Run COLLISION_DIALOG; never silently overwrite. On Cancel: `Cancelled — no file written.` |
| Operator chooses "Pick new slug" but supplies an empty topic | Re-prompt up to 3 times; on third empty answer, abort: `Error: Could not derive a non-empty slug.` |
| Post-write Glob finds two files with the same `{NNNN}` prefix (different slugs) | Abort loudly: `Error: ADR number collision detected — another author may have raced you. Manual resolution required.` |
| Validation Before Save fails | Abort with `Error: validation failed: {field/section} — {detail}.` No retry — calling agent re-invokes. |
| Mermaid mandate not satisfied AND no pure-policy override note | Abort: `Error: validation failed: Mermaid block missing — ADR involves component relationships, state transitions, or flows; include a Mermaid block or record the pure-policy override note in the Decision section.` |
| Filesystem write fails (permissions, disk, read-only mount) | Surface raw error: `Error: Write failed — {raw error}.` Do NOT retry. The calling agent reports to the operator. |
| Caller passes additional positional args beyond `<topic>` | Ignore extras silently. |
| Calling agent attempts to spawn sub-agents from inside this skill | Forbidden by the BANNER above and by `allowed-tools`. The skill's tool surface excludes `Agent`, `TeamCreate`, `TeamDelete`, `Skill`, `SendMessage`, and `Edit`. |

**Race-detection honesty.** ADR numbering is best-effort. The skill detects
different-slug concurrent races via a post-write Glob check. Same-slug concurrent
races (both invocations producing `(N+1)-{slug}.md`) are NOT detected — the later
write silently replaces the earlier. If the operator suspects a same-slug race,
they must manually inspect git diff after invocation.
