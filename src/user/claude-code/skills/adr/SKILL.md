---
name: adr
description: >
  Author a single Architecture Decision Record at docs/adr/{NNNN}-{slug}.md. Loaded
  into the calling agent's context; the agent drafts the ADR per the format authority
  below.
  Trigger: "create ADR", "record this decision", "draft an architecture decision record", "log architectural decision".
argument-hint: "<topic>"
allowed-tools: ["AskUserQuestion", "Bash", "Grep", "Read", "Write"]
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

**Slug derivation** (deterministic): `Bash ~/.claude/scripts/slug.sh "<topic>"`
(repo: `src/user/claude-code/scripts/slug.sh`) — the shared 8-step algorithm
(lowercase → non-alphanumeric runs to `-` → strip → 60-char cut → prefer a word
boundary in [40, 60) → re-strip → empty check). On exit 0, stdout is `{slug}`. On
exit 1 (no alphanumeric survivors) the script emits `Error: Topic must contain at
least one alphanumeric character.` on stderr — surface it and ABORT.
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
4. **Collision handling**: not applicable to the ADR numbering path — atomic claim
   (step 5) reserves `{output_path}` and creates it as an empty stub in the same
   operation, so it always exists immediately after numbering and this is never a real
   collision. The COLLISION_DIALOG below is retained only for byte-identical parity
   with the sibling doc-authoring skills (`doctrine_check_manifest.tsv`); this skill's
   own flow never invokes it.

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

5. **ADR numbering + atomic claim** (ADR-specific): `Bash ~/.claude/scripts/next_doc_number.sh --claim docs/adr {slug}` (repo: `src/user/claude-code/scripts/next_doc_number.sh`)
   — the shared doc-number allocation + citation-hijack script, run here in `--claim`
   mode so numbering and reservation happen as one atomic step (also used in plain,
   non-claiming mode by `src/user/claude-code/agents/distinguished-engineer.md`,
   `src/user/claude-code/agents/staff-engineer.md`, and
   `src/user/claude-code/agents/security-engineer.md` when hand-authoring ADRs outside
   this skill).
   1. On success (exit 0), stdout is `{next_num}` (4-digit zero-padded). The number is
      now atomically claimed: the script has already created an empty stub at
      `docs/adr/{next_num}-{slug}.md` via noclobber (`set -C`) lock semantics, so no
      concurrent author can claim the same number out from under you — a losing
      concurrent claimant retries the next candidate instead of colliding. The script
      has also already skipped any candidate already cited elsewhere in the repo under
      a different slug (citation-hijack) even though no file with that number exists
      yet; skipped candidates are reported on stderr — surface them to the calling
      agent as an informational note, not an abort.
   2. On failure (non-zero exit — existing filenames in `docs/adr/` don't match
      `^\d{4}-[a-z0-9-]+\.md$`, or `{slug}` fails `^[a-z0-9-]+$`), ABORT using the
      script's stderr as `{detail}`:

      ```
      Error: Could not determine next ADR number. {detail}
      ```

   3. `{output_path}` = `docs/adr/{next_num}-{slug}.md`. This file already exists on
      disk as the empty claimed stub from step 5.1 — expected, not a collision.
   4. **Abort-after-claim caveat**: if the skill aborts anywhere past this point
      (Authoring Procedure, Validation Before Save), the empty stub at `{output_path}`
      is left on disk as an orphaned reservation of `{next_num}` — a re-invocation does
      not reclaim it and instead claims the number above it. Note the orphaned stub
      path in the abort report so the operator can delete it manually if unwanted.

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

The full checklist — the frontmatter contract (including the `superseded_by`
conditional), the `status` allow-list, section order, the Alternatives-Considered
minimum, and the placeholder scan — is mechanized by the shared `doc_validate.py`,
the single source of truth for what a valid ADR must satisfy. Validate the drafted
document before the final Write:

1. **Stage the draft.** `Write` the complete drafted content (frontmatter + body)
   to a staging path under `$TMPDIR` — e.g. `$TMPDIR/{slug}.md`.
2. **Run the validator.** `Bash ~/.claude/scripts/doc_validate.py --type adr "$TMPDIR/{slug}.md"`
   (repo: `src/user/claude-code/scripts/doc_validate.py`).
3. **Act on the exit code:**
   - **exit 0** — validation passed; proceed to Save & Return (the final `Write` to
     `docs/adr/...`).
   - **exit 1** — validation failure. ABORT, quoting the script's stderr (no
     fix-and-retry — the skill validates then writes in a single pass; repair is the
     calling agent's responsibility, and it re-invokes `Skill(adr, "<topic>")`):

     ```
     Error: validation failed: {field/section} — {detail}.
     ```

   - **exit 2** — infrastructure/usage failure (validator missing or staging file
     unreadable). ABORT with a distinct message so the caller escalates the
     infrastructure problem instead of re-drafting:

     ```
     Error: validator unavailable: {stderr}
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

ADR-specific full sequence: `mkdir → Read stub → Write → Emit`. Unlike the sibling
doc-authoring skills, canonical step 2 (`Write {output_path}`) here targets a file that
already exists on disk — the empty stub the atomic `--claim` created back in Pre-flight
step 5 — so the harness's unread-overwrite guard applies. Insert one
`Read {output_path}` between canonical steps 1 and 2 to satisfy it (the stub is empty;
there is nothing to review). Because the number was reserved atomically at Pre-flight
step 5 via noclobber lock semantics, no peer can have claimed the same `{NNNN}` in the
interim — the pre-Write/post-Write race-detection Globs the prior non-atomic design
needed to catch that race are no longer necessary and have been removed. On a clean
Read + Write, proceed directly to canonical step 3 (Emit confirmation) and end.

## Failure Modes

| Trigger | Handling |
|---|---|
| `<topic>` missing or empty | Abort: `Error: Usage: Skill(adr, "<topic>") — describe the artifact in 3-10 words.` |
| Slug empty after sanitization (e.g., all-CJK or all-punct topic) | Abort: `Error: Topic must contain at least one alphanumeric character.` |
| `next_doc_number.sh --claim docs/adr {slug}` exits non-zero (existing filename doesn't match `^\d{4}-[a-z0-9-]+\.md$`, or `{slug}` fails `^[a-z0-9-]+$`) | Abort: `Error: Could not determine next ADR number. {script stderr}.` |
| A peer claims a candidate `{NNNN}` before this invocation does | Handled transparently inside `next_doc_number.sh --claim` (retries the next candidate); never surfaces as a failure to this skill. |
| Read of `{output_path}` (the claimed stub) fails before Write (stub deleted or unreadable between claim and Save & Return) | Surface raw error: `Error: Read failed — {raw error}.` Do NOT retry. The calling agent reports to the operator. |
| Validation Before Save fails | Abort with `Error: validation failed: {field/section} — {detail}.` No retry — calling agent re-invokes. |
| Filesystem write fails (permissions, disk, read-only mount) | Surface raw error: `Error: Write failed — {raw error}.` Do NOT retry. The calling agent reports to the operator. |
