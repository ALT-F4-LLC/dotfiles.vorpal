---
name: adr
description: >
  Author a single Architecture Decision Record at docs/tdd/adr/{NNNN}-{slug}.md. Loaded
  into the calling agent's context; the agent drafts the ADR per the format authority
  below.
  Trigger: "create ADR", "record this decision", "draft an architecture decision record", "log architectural decision".
---

<!-- CANONICAL:BANNER:BEGIN -->
> **CRITICAL:** (1) Do NOT commit ANY changes (no `git add`, no `git commit`, no `git push`) unless EXPLICITLY instructed by the user. (2) This is a leaf skill. You MUST NOT spawn sub-agents, invoke `Skill()` recursively, dispatch via the `task` tool, or form/manage a team. The calling agent owns downstream routing after this skill returns. (3) Under Opencode the calling agent is a one-shot `task`-tool dispatch: the artifact is written to disk and the confirmation emitted into the calling agent's context; the calling agent carries the outcome in its returned summary to team-lead. There is no peer-messaging channel and no `SendMessage`.
<!-- CANONICAL:BANNER:END -->

# ADR — Author an Architecture Decision Record

You are the **ADR Author**. You produce a single Architecture Decision Record at
`docs/tdd/adr/{NNNN}-{slug}.md` and return. The calling agent (typically
`@staff-engineer`) drafts the content; this skill is the format authority — section
list, frontmatter contract, output path, ADR numbering, and collision handling all
live here.

<!-- CANONICAL:DOCS-PATHS-LOCAL:BEGIN -->
**Docs paths (this skill).** Master: `~/.config/opencode/skills/team-doctrine/references/docs-paths.md` — repo: `src/user/opencode/skills/team-doctrine/references/docs-paths.md` (maintained copy).
- Writes: `docs/tdd/adr/{NNNN}-{slug}.md`.
- Reads: `docs/tdd/adr/`, `docs/tdd/`, `docs/spec/`, `docs/ux/`.
- Always singular docs/spec/ — never docs/specs/.
<!-- CANONICAL:DOCS-PATHS-LOCAL:END -->

## Argument Handling

<!-- CANONICAL:ARGUMENT_HANDLING:BEGIN -->
The argument is a single positional `<topic>` (free-text, 3-10 words describing the
artifact). No flags, no other args.

If `<topic>` is missing or empty:

```
Error: Usage: Skill(adr, "<topic>") — describe the artifact in 3-10 words.
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

- A single architectural or design decision needs to be recorded as an immutable
  artifact at `docs/tdd/adr/{NNNN}-{slug}.md` (numbered chronologically) so future
  readers can trace the why.
- The calling agent (typically `@staff-engineer`) is logging a decision that emerged
  during design, review, or implementation and that future work will need to reference.
- The decision has long-term consequences (e.g., choice of library, protocol, schema
  shape, naming convention) and a one-line note in a TDD or PR is not enough.

## When NOT to Use

<!-- COUPLING: this skill is part of the doc-authoring family. The "When NOT to Use" delegation routes below MUST stay in sync with ~/.config/opencode/skills/prd, tdd, ux-spec, and init-specs — update all 5 in lockstep when adding/removing a sibling skill. -->
- Inline advisory replies, review comments, scratch notes, or one-off design
  sketches that are not meant to live at `docs/tdd/adr/`.
- Full system designs spanning multiple components or phases: use
  `Skill(tdd, "<topic>")`.
- Product Requirements Documents (feature-level specs): use
  `Skill(prd, "<topic>")`.
- UX / design specs: use `Skill(ux-spec, "<topic>")`.
- Project-wide engineering specs (architecture, security, operations, performance,
  code-quality, review-strategy, testing): owned by the `init-specs` skill.

## Pre-flight

1. **Resolve `{slug}`** from `<topic>` per the Argument Handling slug rule above.
2. **Resolve `{output_dir}`** as `docs/tdd/adr/`.
3. **Resolve context**:
   - `{today_date}` = `Bash date +%Y-%m-%d`.
   - `{project_name}` = `Bash basename $(git rev-parse --show-toplevel)`.
   - `{updated_by}` = the calling agent's identifier (e.g., `@staff-engineer`).
4. **Collision handling**: if the resolved `{output_path}` exists after numbering (step 5), run the COLLISION_DIALOG below.

<!-- CANONICAL:COLLISION_DIALOG:BEGIN -->
If a file already exists at the target output path, invoke `question`:

```
question({
  questions: [{
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
  }]
})
```

- "Pick new slug" → suggest `{slug}-2`, then `{slug}-3`, etc. via free-text follow-up.
- "Overwrite" → proceed to Authoring Procedure; the existing file will be replaced on Write.
- "Cancel" → emit `Cancelled — no file written.` and end.

**Dispatched-subagent caveat.** `question` may be unavailable in a dispatched one-shot subagent context (the operator is reached via team-lead relay, not directly) — if you cannot get an overwrite decision, do NOT Write: emit `Blocked: {output_path} exists; overwrite needs operator confirmation — surface this in your returned summary for team-lead to relay to the operator.` and end.

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
   5. Format as `f"{next_num:04d}"` (4-digit zero-padded).
   6. `{output_path}` = `docs/tdd/adr/{next_num:04d}-{slug}.md`.

## Authoring Procedure

1. **Gather prior art**: `Grep -r "{topic-keywords}" docs/tdd/adr/ docs/tdd/ docs/spec/ docs/ux/` to find related
   ADRs, TDDs, PRDs, or UX specs that may be superseded, reinforced, or contradicted by this decision.
   Read any candidate predecessors so the new ADR cites them in `Context`.
2. **Draft the frontmatter** per the Required Frontmatter contract below. Set
   `status: "proposed"` initially; `accepted` is set after the calling agent's
   review/vote loop, not by this skill.
3. **Draft each Required Section in order** (see Output Contract → Required
   Sections). Every section listed MUST appear, in the order shown. ADRs are
   intentionally short — aim for tight prose, not exhaustive coverage. Mermaid
   is optional; include a block only when it clarifies component, state, or
   flow relationships.
4. **Verify embedded technical assertions before stating them as fact.** Any
   concrete claim the ADR commits to — a code/config/command/SQL snippet, a
   portability or compatibility claim across engines/platforms, or a reference
   to test infrastructure the decision relies on — MUST be checked against its
   actual target (run it, or confirm the target exists) before it is written as
   settled. State unverified claims as assumptions, not facts.
5. **Proceed to Validation Before Save** — single source of truth for
   frontmatter, section order, alternatives count, and placeholder checks.

## Output Contract

### Required Frontmatter

```yaml
---
project: "{project_name}"
last_updated: "{today_date}"
updated_by: "{updated_by}"
status: "proposed"
# superseded_by: "0042-new-decision"  # required only when status is "superseded"
---
```

Field rules:

- `project` = `basename $(git rev-parse --show-toplevel)`.
- `last_updated` is ISO date `YYYY-MM-DD`.
- `updated_by` is the calling agent identifier (`@staff-engineer`, etc.).
- `status` is one of: `proposed | accepted | superseded`. New ADRs start at
  `proposed`. Promotion to `accepted` happens after the calling agent's review;
  `superseded` is set when a later ADR replaces this one.
- `superseded_by` is required when `status: superseded` and points to the
  successor ADR's basename without extension (e.g., `0042-new-decision`).
  Omit otherwise.

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
   must also be present and non-empty.
2. **Status value** — `status` is one of `proposed | accepted | superseded`.
3. **Section order** — the body contains all top-level sections enumerated
   in "Required Sections" above, as `##` headings, in the order listed
   (currently 4 sections; count only `##` headings at column 0 *outside*
   ``` code fences — an ADR that documents another doc/skill may embed
   `##`/`###` example headings inside fences; those are content, not
   structure). Off-by-one against the count is a defect.
4. **Alternatives count** — Section 4 (Alternatives Considered) names at
   least one alternative.
5. **Placeholder scan** — body contains no literal `{slug}`, `{topic}`,
   `{project_name}`, `{NNNN}`, `TBD`, or `TODO` text outside of code-fenced
   examples.

If any check fails, ABORT with:

```
Error: validation failed: {field/section} — {detail}.
```

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

For this skill, `{output_dir}` is `docs/tdd/adr/` and `{output_path}` is
`docs/tdd/adr/{NNNN}-{slug}.md` (with `{NNNN}` resolved by Pre-flight step 5).

ADR-specific full sequence: `mkdir → Write → race-detection Glob → Emit`. The initial numbering (Pre-flight step 5) is authoritative; ADR authoring is single-author, so no pre-Write renumber is needed — the post-Write Glob below is the sole race guard.

**After Write, before Emit**: Re-run `Glob docs/tdd/adr/{NNNN}-*.md` (using the `{NNNN}` chosen in Pre-flight step 5). If more than one file is returned, ABORT loudly instead of emitting the confirmation:

```
Error: ADR number collision detected — another author may have raced you. Manual resolution required.
```

This catches different-slug concurrent races at the same `{NNNN}`. Same-slug races (two authors picking identical topics simultaneously) are undetectable — both writes target the same path. On clean Glob (exactly one match), proceed to canonical step 3 (Emit confirmation) and end.

## Failure Modes

| Trigger | Handling |
|---|---|
| `<topic>` missing or empty | Abort: `Error: Usage: Skill(adr, "<topic>") — describe the artifact in 3-10 words.` |
| Slug empty after sanitization (e.g., all-CJK or all-punct topic) | Abort: `Error: Topic must contain at least one alphanumeric character.` |
| Existing ADR filename does not match `^\d{4}-[a-z0-9-]+\.md$` | Abort: `Error: Could not determine next ADR number. Existing ADR filenames must start with NNNN- (4-digit zero-padded). Found malformed: {malformed}.` |
| Output file already exists at the resolved `{NNNN}-{slug}.md` path | Run COLLISION_DIALOG; never silently overwrite. On Cancel: `Cancelled — no file written.` |
| Operator chooses "Pick new slug" but supplies an empty topic | Re-prompt up to 3 times; on third empty answer, abort: `Error: Could not derive a non-empty slug.` |
| Post-write Glob finds two files with the same `{NNNN}` prefix (different slugs) | Abort loudly: `Error: ADR number collision detected — another author may have raced you. Manual resolution required.` |
| Validation Before Save fails | Abort with `Error: validation failed: {field/section} — {detail}.` No retry — calling agent re-invokes. |
| Filesystem write fails (permissions, disk, read-only mount) | Surface raw error: `Error: Write failed — {raw error}.` Do NOT retry. The calling agent reports to the operator. |
