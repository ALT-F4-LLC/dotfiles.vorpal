---
name: adr
description: >
  Author a single Architecture Decision Record at docs/adr/{NNNN}-{slug}.md. Loaded
  into the calling agent's context; the agent drafts the ADR per the format authority
  below.
  Trigger: "create ADR", "record this decision", "draft an architecture decision record", "log architectural decision".
argument-hint: "<topic>"
allowed-tools: ["AskUserQuestion", "Bash", "Glob", "Grep", "Read", "Write"]
---

<!-- CANONICAL:BANNER:BEGIN -->
> **CRITICAL:** (1) Do NOT commit ANY changes (no `git add`, no `git commit`, no `git push`) unless EXPLICITLY instructed by the user. (2) This is a leaf skill. You MUST NOT spawn sub-agents, invoke `Skill()` recursively, use `Agent()` or `SendMessage`, or form/manage a team. The calling agent handles peer messaging after this skill returns.
<!-- CANONICAL:BANNER:END -->

# ADR — Author an Architecture Decision Record

You are the **ADR Author**. You produce a single Architecture Decision Record at
`docs/adr/{NNNN}-{slug}.md` and return. The calling agent (typically
`@staff-engineer`) drafts the content; this skill is the format authority — section
list, frontmatter contract, output path, ADR numbering, and collision handling all
live here.

<!-- CANONICAL:DOCS-PATHS-LOCAL:BEGIN -->
**Docs paths (this skill).** Master: `~/.claude/skills/team-doctrine/references/docs-paths.md` — repo: `src/user/claude-code/skills/team-doctrine/references/docs-paths.md` (maintained copy).
- Writes: `docs/adr/{NNNN}-{slug}.md`.
- Reads: `docs/adr/`, `docs/tdd/`, `docs/spec/`, `docs/ux/`.
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

- A single architectural or design decision needs to be recorded as an immutable
  artifact at `docs/adr/{NNNN}-{slug}.md` (numbered chronologically) so future
  readers can trace the why.
- The calling agent (typically `@staff-engineer`) is logging a decision that emerged
  during design, review, or implementation and that future work will need to reference.
- The decision has long-term consequences (e.g., choice of library, protocol, schema
  shape, naming convention) and a one-line note in a TDD or PR is not enough.
- ADRs are DURABLE records — exempt from TDD ephemerality (docs-paths.md §Persistence
  & lifecycle); they are a distillation target at cycle wrap-up.

## When NOT to Use

<!-- COUPLING: this skill is part of the doc-authoring family. The "When NOT to Use" delegation routes below MUST stay in sync with src/user/claude-code/skills/prd, tdd, ux-spec, and init-specs — update all 5 in lockstep when adding/removing a sibling skill. -->
- Inline advisory replies, review comments, scratch notes, or one-off design
  sketches that are not meant to live at `docs/adr/`.
- Full system designs spanning multiple components or phases: use
  `Skill(tdd, "<topic>")`.
- Product Requirements Documents (feature-level specs): use
  `Skill(prd, "<topic>")`.
- UX / design specs: use `Skill(ux-spec, "<topic>")`.
- Project-wide engineering specs (architecture, security, operations, performance,
  code-quality, review-strategy, testing): owned by the `init-specs` skill.

## Pre-flight

1. **Resolve `{slug}`** from `<topic>` per the Argument Handling slug rule above.
2. **Resolve `{output_dir}`** as `docs/adr/`.
3. **Resolve context**:
   - `{today_date}` = `Bash date +%Y-%m-%d`.
   - `{project_name}` = `Bash basename $(git rev-parse --show-toplevel)`.
   - `{updated_by}` = the calling agent's identifier (e.g., `@staff-engineer`).
4. **Collision handling**: if the resolved `{output_path}` exists after numbering (step 5), run the COLLISION_DIALOG below.

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
- "Overwrite" → first `Read {output_path}` (the harness blocks an overwrite Write of an unread file), then proceed to Authoring Procedure; the existing file is replaced on Write.
- "Cancel" → emit `Cancelled — no file written.` and end.

**Teammate-context caveat.** `AskUserQuestion` is inert in a teammate (only the main-session lead can call it) — if you cannot get an overwrite decision, do NOT Write: emit `Blocked: {output_path} exists; overwrite needs operator confirmation — the calling agent routes this to team-lead.` and end.

Never silently overwrite. There is no "append" option — partial appends produce
malformed frontmatter.
<!-- CANONICAL:COLLISION_DIALOG:END -->

5. **ADR numbering** (ADR-specific): `Bash .claude/scripts/next_doc_number.sh docs/adr`
   — the shared doc-number allocation + citation-hijack script (also used by
   `agents/distinguished-engineer.md`, `agents/staff-engineer.md`, and
   `agents/security-engineer.md` when hand-authoring ADRs outside this skill).
   1. On success (exit 0), stdout is `{next_num}` (4-digit zero-padded) — the next
      available number. The script has already skipped any candidate already cited
      elsewhere in the repo under a different slug (citation-hijack) even though no
      file with that number exists yet; skipped candidates are reported on stderr —
      surface them to the calling agent as an informational note, not an abort.
   2. On failure (non-zero exit — existing filenames in `docs/adr/` don't match
      `^\d{4}-[a-z0-9-]+\.md$`), ABORT using the script's stderr as `{detail}`:

      ```
      Error: Could not determine next ADR number. {detail}
      ```

   3. `{output_path}` = `docs/adr/{next_num}-{slug}.md`.

## Authoring Procedure

1. **Gather prior art**: `Grep -r "{topic-keywords}" docs/adr/ docs/tdd/ docs/spec/ docs/ux/` to find related
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

For this skill, `{output_dir}` is `docs/adr/` and `{output_path}` is
`docs/adr/{NNNN}-{slug}.md` (with `{NNNN}` resolved by Pre-flight step 5).

ADR-specific full sequence: `mkdir → Write → race-detection Glob → Emit`. The initial numbering (Pre-flight step 5) is authoritative; ADR authoring is single-author, so no pre-Write renumber is needed — the post-Write Glob below is the sole race guard.

**After Write, before Emit**: Re-run `Glob docs/adr/{NNNN}-*.md` (using the `{NNNN}` chosen in Pre-flight step 5). If more than one file is returned, ABORT loudly instead of emitting the confirmation:

```
Error: ADR number collision detected — another author may have raced you. Manual resolution required.
```

This catches different-slug concurrent races at the same `{NNNN}`. Same-slug races (two authors picking identical topics simultaneously) are undetectable — both writes target the same path. On clean Glob (exactly one match), proceed to canonical step 3 (Emit confirmation) and end.

## Failure Modes

| Trigger | Handling |
|---|---|
| `<topic>` missing or empty | Abort: `Error: Usage: Skill(adr, "<topic>") — describe the artifact in 3-10 words.` |
| Slug empty after sanitization (e.g., all-CJK or all-punct topic) | Abort: `Error: Topic must contain at least one alphanumeric character.` |
| `next_doc_number.sh docs/adr` exits non-zero (existing filename doesn't match `^\d{4}-[a-z0-9-]+\.md$`) | Abort: `Error: Could not determine next ADR number. {script stderr}.` |
| Output file already exists at the resolved `{NNNN}-{slug}.md` path | Run COLLISION_DIALOG; never silently overwrite. On Cancel: `Cancelled — no file written.` |
| Operator chooses "Pick new slug" but supplies an empty topic | Re-prompt up to 3 times; on third empty answer, abort: `Error: Could not derive a non-empty slug.` |
| Post-write Glob finds two files with the same `{NNNN}` prefix (different slugs) | Abort loudly: `Error: ADR number collision detected — another author may have raced you. Manual resolution required.` |
| Validation Before Save fails | Abort with `Error: validation failed: {field/section} — {detail}.` No retry — calling agent re-invokes. |
| Filesystem write fails (permissions, disk, read-only mount) | Surface raw error: `Error: Write failed — {raw error}.` Do NOT retry. The calling agent reports to the operator. |
