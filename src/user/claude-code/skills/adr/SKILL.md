---
name: adr
description: >
  Author a single Architecture Decision Record at docs/adr/{NNNN}-{slug}.md. Loaded
  into the calling agent's context; the agent drafts the ADR per the format authority
  below.
  Trigger: "create ADR", "record this decision", "draft an architecture decision record", "log architectural decision".
argument-hint: "<topic>"
allowed-tools: ["Bash", "Grep", "Read", "Write"]
---

<!-- CANONICAL:BANNER:BEGIN -->
> **CRITICAL:** (1) Do NOT commit ANY changes (no `git add`, no `git commit`, no `git push`) unless EXPLICITLY instructed by the user. (2) This is a leaf skill. You MUST NOT spawn sub-agents, invoke `Skill()` recursively, use `Agent()` or `SendMessage`, or form/manage a team. The calling agent handles peer messaging after this skill returns.
<!-- CANONICAL:BANNER:END -->

# ADR — Author an Architecture Decision Record

You are the **ADR Author**: produce a single Architecture Decision Record at `docs/adr/{NNNN}-{slug}.md` and return. The calling agent drafts the content — `@distinguished-engineer` by default on Medium+ cycles, `@staff-engineer` as the seat-unavailable fallback and the sub-Medium/standalone author, or `@security-engineer` for a security ADR (its charter makes it the sole author of those; @distinguished-engineer never takes security-sensitive work). This skill is the format authority — section list, frontmatter contract, output path, ADR numbering, collision handling.

<!-- CANONICAL:DOCS-PATHS-LOCAL:BEGIN -->
**Docs paths (this skill).** Master: `~/.claude/skills/team-doctrine/references/docs-paths.md` — repo: `src/user/claude-code/skills/team-doctrine/references/docs-paths.md`. Writes: `docs/adr/{NNNN}-{slug}.md`. Reads: `docs/adr/`, `docs/tdd/`, `docs/spec/` (always singular), `docs/ux/`.
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

A single architectural or design decision with long-term consequences (library, protocol, schema shape, naming convention) needs recording at `docs/adr/{NNNN}-{slug}.md` so future readers can trace the why — and a one-line note in a TDD or PR is not enough. ADRs are DURABLE records, exempt from TDD ephemerality, and a distillation target at cycle wrap-up.

## When NOT to Use

<!-- COUPLING: this skill is part of the doc-authoring family. The "When NOT to Use" delegation routes below MUST stay in sync with src/user/claude-code/skills/prd, tdd, and ux-spec — update all 4 in lockstep when adding/removing a sibling skill. `init-specs` is in the doc-authoring family but carries no "When NOT to Use" section, so it is outside this particular sync. -->
- Inline advisory replies, review comments, scratch notes, or one-off sketches not meant to live at `docs/adr/`.
- Full system designs spanning multiple components or phases: `Skill(tdd, "<topic>")`.
- Product Requirements Documents: `Skill(prd, "<topic>")`. UX / design specs: `Skill(ux-spec, "<topic>")`.
- Project-wide engineering specs: owned by `init-specs`.

## Pre-flight

1. **Run `Bash ~/.claude/scripts/doc_preflight.sh adr "<topic>"`** — single-homes slug derivation, date/project context, and a same-slug lookup (the near-duplicate probe is tdd-only). Parse stdout: `{slug}`, `{today_date}`, `{project_name}`, `{same_slug_existing}`; on non-zero exit, surface stderr and ABORT. `{same_slug_existing}` is tri-state — real path, empty, or `SKIPPED: docs/adr absent` — never collapse the sentinel into "no match". `{output_dir}` = `docs/adr/`; `{updated_by}` = the calling agent's identifier. ADR has no COLLISION_DIALOG — each numbered file is a distinct, non-overwritable record, and numbering is reserved atomically in step 3 — so `{same_slug_existing}` is advisory input to the prior-art gather, not a blocking dialog.
2. **Gather prior art** (BEFORE the atomic claim — the claim is the only step that writes to disk, so aborting here never orphans a stub): `Grep -r "{topic-keywords}"` over the docs dirs that exist (`docs/spec/`/`docs/ux/` are commonly absent; passing a missing path makes the search error rather than no-match). Read candidate predecessors, including any real `{same_slug_existing}` hit, so the new ADR cites them in `Context`. If a predecessor already records THIS decision, ABORT: `Error: {path} already records this decision — update or supersede it instead.` The atomic claim prevents duplicate NUMBERS, never duplicate DECISIONS — this Grep is the only duplicate check in the flow.
3. **ADR numbering + atomic claim**: `Bash ~/.claude/scripts/next_doc_number.sh --claim docs/adr {slug}` — allocation and reservation as one atomic step. (The same script also runs in plain, non-claiming mode when agents hand-author ADRs outside this skill — the noclobber stub below is visible to those allocations too, so the reservation holds for any allocator that consults the directory; only a writer that computes a number without running the script at all could still collide.)
   1. On success (exit 0), stdout is `{next_num}` (4-digit zero-padded), atomically claimed: the script created an empty stub at `docs/adr/{next_num}-{slug}.md` via noclobber (`set -C`) lock semantics — a losing concurrent claimant retries the next candidate. It also skipped any candidate whose `docs/adr/{NNNN}-` path prefix is already cited elsewhere in the repo (citation-hijack; path-prefix form only — a prose `ADR-{NNNN}` never triggers a skip), reporting skips on stderr — surface them as an informational note. The skip cannot tell a competing citation from this decision's own forward reference, so it will skip a number an upstream TDD or plan mandated. When the caller was handed an exact target number, compare it to `{next_num}`; on mismatch, branch on whether the mandated number appears in THIS invocation's stderr on an `already cited (citation-hijack)` line — that exact line form only (the unrelated `lost the atomic claim (...), retrying` line also names numbers; a number appearing only there takes the Not-listed branch):
      - **Listed** — the mandated number was skipped as citation-hijacked (the self-forward-reference false positive). ABORT — writing at `{next_num}` would leave every upstream citation dangling — and report the orphaned stub per 3.4: `Error: {mandated} was mandated upstream but skipped as citation-hijacked; claimed {next_num} instead — reconcile the citation and re-invoke.`
      - **Not listed** — a real file already holds the mandated number; the mandate is stale. Proceed at `{next_num}` and report the mismatch so the caller updates the stale citation.
   2. On failure (non-zero — existing filenames don't match `^\d{4}-[a-z0-9-]+\.md$`, or `{slug}` fails `^[a-z0-9-]+$`), ABORT: `Error: Could not determine next ADR number. {stderr}`
   3. `{output_path}` = `docs/adr/{next_num}-{slug}.md` — it already exists as the empty claimed stub; expected, not a collision.
   4. **Abort-after-claim caveat**: any abort at or after 3.1 leaves the empty stub on disk as an orphaned reservation (a re-invocation claims the number above it, never reclaims it) — name the orphaned stub path in the abort report so the operator can delete it if unwanted.

## Authoring Procedure

1. **Draft the frontmatter** per the contract below (`status: "proposed"` initially; `accepted` is set after the calling agent's review/vote loop, not by this skill), then **each Required Section in order**. ADRs are intentionally short — tight prose, not exhaustive coverage. Mermaid is optional; include a block only when it clarifies component, state, or flow relationships.
2. **Verify embedded technical assertions before stating them as fact.** Any concrete claim the ADR commits to — a code/config/command/SQL snippet, a portability or compatibility claim, a reference to test infrastructure the decision relies on — is checked against its actual target (run it, or confirm the target exists) before being written as settled. State unverified claims as assumptions, not facts.
3. **Proceed to Validation Before Save.**

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

Field rules: `project` = `basename $(git rev-parse --show-toplevel)`; `last_updated` is `YYYY-MM-DD`; `updated_by` is the calling agent identifier; `status` is `proposed | accepted | superseded` (new ADRs start `proposed`); `superseded_by` is required exactly when `status: superseded` and names the successor's basename without extension — omit otherwise.

### Required Sections

`##` headings carrying the section title ONLY — list numbers are NOT part of the heading (`## Context`, never `## 1. Context`); the validator matches heading text exactly, in this order:

1. **Context** — the decision-driver: what situation, constraint, or trigger forced this decision; cite related TDDs, PRDs, ADRs, or incidents.
2. **Decision** — the chosen approach, stated affirmatively in one or two paragraphs.
3. **Consequences** — positive, negative, and neutral; what becomes easier and what becomes harder.
4. **Alternatives Considered** (brief) — at least one alternative with a short verdict; full multi-alternative analysis belongs in a TDD.

## Validation Before Save

The full checklist — frontmatter contract (including the `superseded_by` conditional), `status` allow-list, section order, the Alternatives minimum, placeholder scan — is mechanized by `doc_validate.py`, the single source of truth. Before the final `mv`:

1. **Stage the draft.** Resolve the staging dir: `Bash echo "${TMPDIR:-/tmp}"` → `{staging_dir}` (an absolute path — `Write`/`Read` take literal paths and never expand `$TMPDIR`). `Write` the complete draft to `{staging_dir}/{slug}.md`.
2. **Run** `Bash python3 ~/.claude/scripts/doc_validate.py --type adr "{staging_dir}/{slug}.md"` — the same resolved `{staging_dir}`, always via `python3` (a copy that lost its executable bit exits 126, which no branch below handles).
3. **Exit codes:** **0** → Save & Return. **1** → ABORT quoting stderr (`Error: validation failed: {field/section} — {detail}.`) — no fix-and-retry; the calling agent re-invokes. **2** → ABORT with `Error: validator unavailable: {stderr}` so the caller escalates infrastructure, not the draft. (Either abort orphans the claimed stub — report its path per Pre-flight 3.4.)

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

For this skill `{output_path}` is `docs/adr/{NNNN}-{slug}.md` with `{NNNN}` from Pre-flight step 3, and the `mv` intentionally overwrites the empty claimed stub — a Bash `mv` is not gated by the harness's unread-overwrite guard on `Write`/`Edit`, and the noclobber reservation means no `--claim` peer holds the same `{NNNN}`. A failed `mv` (permissions, disk, cross-device) surfaces the raw error — `Error: mv failed — {raw error}.` — with no retry.
