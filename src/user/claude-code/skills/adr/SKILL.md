---
name: adr
description: >
  Author a single Architecture Decision Record at docs/adr/{NNNN}-{slug}.md. Loaded
  into the calling agent's context; the agent drafts the ADR per the format authority
  below.
  Trigger: "create ADR", "record this decision", "draft an architecture decision record", "log architectural decision".
argument-hint: "<topic>"
allowed-tools: ["Bash", "Grep", "Read", "Write"]
effort: xhigh
---

<!-- CANONICAL:BANNER:BEGIN -->
> **CRITICAL:** (1) Do NOT commit ANY changes (no `git add`, no `git commit`, no `git push`) unless EXPLICITLY instructed by the user. (2) This is a leaf skill. You MUST NOT spawn sub-agents, invoke `Skill()` recursively, use `Agent()` or `SendMessage`, or form/manage a team. The calling agent handles peer messaging after this skill returns.
<!-- CANONICAL:BANNER:END -->

# ADR — Author an Architecture Decision Record

You are the **ADR Author**. You produce a single Architecture Decision Record at
`docs/adr/{NNNN}-{slug}.md` and return. The calling agent drafts the content —
`@distinguished-engineer` by DEFAULT on Medium+ cycles (the gold seat that carries
design authorship there), with `@staff-engineer` as the gold-unavailable fallback
author and the author on sub-Medium cycles and in standalone use; or
`@security-engineer` for a **security ADR** (its charter makes it the sole author
of security ADRs; @distinguished-engineer never takes security-sensitive work).
This skill is the format authority — section list, frontmatter contract, output
path, ADR numbering, and collision handling all live here.

<!-- CANONICAL:DOCS-PATHS-LOCAL:BEGIN -->
**Docs paths (this skill).** Master: `~/.claude/skills/team-doctrine/references/docs-paths.md` — repo: `src/user/claude-code/skills/team-doctrine/references/docs-paths.md` (maintained copy).
- Writes: `docs/adr/{NNNN}-{slug}.md`.
- Reads: `docs/adr/`, `docs/tdd/`, `docs/spec/`, `docs/ux/`.
- Always singular docs/spec/ — never docs/specs/.
<!-- CANONICAL:DOCS-PATHS-LOCAL:END -->

## Argument Handling

<!-- CANONICAL:ARGUMENT_HANDLING:BEGIN -->
The argument is a single positional `<topic>` (free-text, 3-10 words describing the
artifact) — the harness binds `\$ARGUMENTS` to this value. No flags, no other args.

Topic for this invocation: $ARGUMENTS.

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
- The calling agent is logging a decision that emerged during design, review, or
  implementation and that future work will need to reference.
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

1. **Run `Bash ~/.claude/scripts/doc_preflight.sh adr "<topic>"`** (repo: `src/user/claude-code/scripts/doc_preflight.sh`)
   — single-homes slug derivation, date/project context, and a same-slug lookup
   (DKT-167; matches the `evolve_preflight.sh` KEY=value convention; the
   near-duplicate prefix probe is tdd-only and not emitted for `adr` — this
   skill never had that check). Parse its stdout: `{slug}`, `{today_date}`,
   `{project_name}`, `{same_slug_existing}`. On non-zero exit, surface its
   stderr and ABORT (it propagates `slug.sh`'s own errors verbatim).
   `{same_slug_existing}` is tri-state — a real path, empty (checked, no hit),
   or a `SKIPPED: docs/adr absent` sentinel when the directory doesn't exist yet
   (no ADR has ever been authored in this repo) — never collapse the sentinel
   into "no match".
   - `{output_dir}` = `docs/adr/`.
   - `{updated_by}` = the calling agent's identifier (e.g., `@staff-engineer`).
   - ADR has no fixed pre-claim path (numbering is reserved separately and
     atomically below), so `{same_slug_existing}` is a same-slug signal across
     ANY existing `{NNNN}-{slug}.md` — advisory input to the prior-art gather
     below, not a blocking dialog (unlike tdd/prd/ux-spec, ADR has no
     COLLISION_DIALOG: each numbered file is a distinct, non-overwritable record).
     If it's a real path (not empty, not a `SKIPPED:` sentinel), read the named
     file first in the prior-art gather.
2. **Gather prior art**: `Grep -r "{topic-keywords}" docs/adr/ docs/tdd/ docs/spec/ docs/ux/` to find related
   ADRs, TDDs, PRDs, or UX specs that may be superseded, reinforced, or contradicted by this decision.
   Pass only the dirs that exist — `docs/spec/` and `docs/ux/` are materialized on
   first write and are commonly absent, and passing a path that does not exist makes
   the search error out (exit 2 with warnings) rather than return a clean no-match.
   Read any candidate predecessors (including any real `{same_slug_existing}` hit from
   step 1) so the new ADR cites them in `Context`. If a
   predecessor already records THIS decision, ABORT with `Error: {path} already records
   this decision — update or supersede it instead.` Run this BEFORE the atomic number
   claim in step 3 below: the claim is the only step that writes to disk, so gathering
   prior art first means a duplicate-decision abort never orphans a claimed stub. The
   atomic claim hands concurrent authors distinct numbers, so it prevents duplicate
   NUMBERS but never duplicate DECISIONS; this Grep is the only duplicate check in the
   flow.
3. **ADR numbering + atomic claim** (ADR-specific): `Bash ~/.claude/scripts/next_doc_number.sh --claim docs/adr {slug}` (repo: `src/user/claude-code/scripts/next_doc_number.sh`)
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
      has also already skipped any candidate whose `docs/adr/{NNNN}-` path prefix is
      cited elsewhere in the repo (citation-hijack) even though no file with that
      number exists yet; skipped candidates are reported on stderr — surface them to
      the calling agent as an informational note, not an abort. The check matches that
      path-prefix form only: a prose-only `ADR-{NNNN}` citation never triggers a skip,
      and a skip cannot tell a competing citation from this decision's own forward
      reference, so it will skip a number an upstream TDD or plan mandated. When the
      calling agent was handed an exact target number or filename, compare it against
      `{next_num}`. On mismatch, branch on whether the mandated number appears in THIS
      `--claim` invocation's stderr on an `already cited (citation-hijack)` line —
      that exact line form only. The script emits a SECOND, unrelated candidate-skip
      line, `lost the atomic claim (...), retrying`, which also names a number; a
      number appearing only there is NOT citation-hijacked and takes the
      **Not listed** branch:
      - **Listed** — it was free on disk but skipped because an upstream TDD or plan
        cites it (the self-forward-reference false positive). ABORT: writing at
        `{next_num}` would leave every upstream citation dangling, and this skill
        cannot rewrite the upstream doc. Report the orphaned stub per step 3.4:

        ```
        Error: {mandated} was mandated upstream but skipped as citation-hijacked; claimed {next_num} instead — reconcile the citation and re-invoke.
        ```

      - **Not listed** — a real file already holds the mandated number, so the mandate
        is stale. Proceed at `{next_num}` and report the mismatch so the calling agent
        updates the stale citation.
   2. On failure (non-zero exit — existing filenames in `docs/adr/` don't match
      `^\d{4}-[a-z0-9-]+\.md$`, or `{slug}` fails `^[a-z0-9-]+$`), ABORT using the
      script's stderr as `{detail}`:

      ```
      Error: Could not determine next ADR number. {detail}
      ```

   3. `{output_path}` = `docs/adr/{next_num}-{slug}.md`. This file already exists on
      disk as the empty claimed stub from step 3.1 — expected, not a collision.
   4. **Abort-after-claim caveat**: if the skill aborts anywhere at or after step 3.1
      (mandated-number mismatch, Authoring Procedure, Validation Before Save), the
      empty stub at `{output_path}`
      is left on disk as an orphaned reservation of `{next_num}` — a re-invocation does
      not reclaim it and instead claims the number above it. Note the orphaned stub
      path in the abort report so the operator can delete it manually if unwanted.

## Authoring Procedure

1. **Draft the frontmatter** per the Required Frontmatter contract below. Set
   `status: "proposed"` initially; `accepted` is set after the calling agent's
   review/vote loop, not by this skill.
2. **Draft each Required Section in order** (see Output Contract → Required
   Sections). Every section listed MUST appear, in the order shown. ADRs are
   intentionally short — aim for tight prose, not exhaustive coverage. Mermaid
   is optional; include a block only when it clarifies component, state, or
   flow relationships.
3. **Verify embedded technical assertions before stating them as fact.** Any
   concrete claim the ADR commits to — a code/config/command/SQL snippet, a
   portability or compatibility claim across engines/platforms, or a reference
   to test infrastructure the decision relies on — MUST be checked against its
   actual target (run it, or confirm the target exists) before it is written as
   settled. State unverified claims as assumptions, not facts.
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
heading in the drafted document carrying the section title ONLY — the list numbers
below are NOT part of the heading (`## Context`, never `## 1. Context`). The
validator matches heading text exactly.

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
document before the final `mv`:

1. **Stage the draft.** First resolve the staging dir: `Bash echo "${TMPDIR:-/tmp}"` —
   stdout is `{staging_dir}`, an absolute path. `Write` and `Read` take a LITERAL path and
   never expand shell variables, so `$TMPDIR/{slug}.md` is treated as a relative
   literal and resolved against the repo root, not the real temp dir. Then `Write` the
   complete drafted content (frontmatter + body) to `{staging_dir}/{slug}.md`.
2. **Run the validator.** `Bash python3 ~/.claude/scripts/doc_validate.py --type adr "{staging_dir}/{slug}.md"`
   (repo: `src/user/claude-code/scripts/doc_validate.py`) — the same resolved `{staging_dir}`,
   never a re-expanded `$TMPDIR`, so an unset-`TMPDIR` caller validates the file it just
   wrote. Invoke via `python3`, never as a bare executable: a deployed copy that lost its
   executable bit exits 126, which no branch below handles; under `python3` a missing
   validator still exits 2.
3. **Act on the exit code:**
   - **exit 0** — validation passed; proceed to Save & Return (the final `mv` to
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
2. `Bash mv "{staging_dir}/{slug}.md" {output_path}` — the SAME resolved `{staging_dir}`
   captured in Validation Before Save step 1, never a re-expanded `$TMPDIR` (the staged
   file already passed validation; re-emitting via `Write` risks staged-vs-final divergence).
3. Emit a single confirmation line:

   ```
   Created {output_path}
   ```

End. Do NOT echo the file body, do NOT send peer messages, do NOT invoke other skills.
The calling agent owns next steps (vote requests, decomposition, peer notification).

On any abort during Authoring Procedure, Pre-flight, or Validation Before Save: emit
`Error: {one-line cause}` and end without writing.

<!-- CANONICAL:SAVE_AND_RETURN:END -->

For this skill, `{output_dir}` is `docs/adr/` and `{output_path}` is
`docs/adr/{NNNN}-{slug}.md` (with `{NNNN}` resolved by Pre-flight step 3).

ADR-specific full sequence: `mkdir → mv → Emit`, matching the other doc-authoring
skills exactly. Canonical step 2's `mv "{staging_dir}/{slug}.md" {output_path}`
overwrites the empty stub the atomic `--claim` created back in Pre-flight step 3 via a
Bash operation rather than the `Write` tool — the harness's unread-overwrite guard,
which gates `Write`/`Edit` on an existing file, does not apply to `mv`, so no
compensating `Read {output_path}` step is needed here (retiring the prior
Read-stub workaround this sequence used to require). Because the number was reserved
atomically at Pre-flight step 3 via noclobber lock semantics, no peer can have claimed
the same `{NNNN}` in the interim, so no pre-move/post-move race-detection Glob is
needed either. On a clean `mv`, proceed directly to canonical step 3 (Emit
confirmation) and end.

## Failure Modes

| Trigger | Handling |
|---|---|
| `<topic>` missing or empty | Abort: `Error: Usage: Skill(adr, "<topic>") — describe the artifact in 3-10 words.` |
| Slug empty after sanitization (e.g., all-CJK or all-punct topic) | Abort: `Error: Topic must contain at least one alphanumeric character.` |
| Prior-art Grep (Pre-flight step 2) finds a predecessor already recording this decision | Abort: `Error: {path} already records this decision — update or supersede it instead.` Runs before the atomic claim (step 3), so no stub has been created yet — nothing is orphaned. |
| `next_doc_number.sh --claim docs/adr {slug}` exits non-zero (existing filename doesn't match `^\d{4}-[a-z0-9-]+\.md$`, or `{slug}` fails `^[a-z0-9-]+$`) | Abort: `Error: Could not determine next ADR number. {script stderr}.` |
| A peer claims a candidate `{NNNN}` before this invocation does | Handled transparently inside `next_doc_number.sh --claim` (retries the next candidate); never surfaces as a failure to this skill. |
| `{next_num}` differs from an upstream-mandated number that the script's stderr lists as citation-hijacked | Abort: `Error: {mandated} was mandated upstream but skipped as citation-hijacked; claimed {next_num} instead — reconcile the citation and re-invoke.` The claimed stub is orphaned — report its path per the abort-after-claim caveat. |
| Validation Before Save fails | Abort with `Error: validation failed: {field/section} — {detail}.` No retry — calling agent re-invokes. |
| Filesystem `mv` fails (permissions, disk, read-only mount, cross-device rename) | Surface raw error: `Error: mv failed — {raw error}.` Do NOT retry. The calling agent reports to the operator. |
