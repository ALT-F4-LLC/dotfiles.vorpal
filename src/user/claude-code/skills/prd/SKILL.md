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
> **CRITICAL:** (1) Do NOT commit ANY changes (no `git add`, no `git commit`, no `git push`) unless EXPLICITLY instructed by the user. (2) This is a leaf skill. You MUST NOT spawn sub-agents, invoke `Skill()` recursively, use `Agent()` or `SendMessage`, or form/manage a team. The calling agent handles peer messaging after this skill returns.
<!-- CANONICAL:BANNER:END -->

# PRD — Author a Product Requirements Document

You are the **PRD Author**: produce a single Product Requirements Document at `docs/spec/{slug}.md` and return. The calling agent (typically `@project-manager`) drafts the content; this skill is the format authority — section list, frontmatter contract, output path, reserved-name refusal, and collision handling.

<!-- CANONICAL:DOCS-PATHS-LOCAL:BEGIN -->
**Docs paths (this skill).** Master: `~/.claude/skills/team-doctrine/references/docs-paths.md` — repo: `src/user/claude-code/skills/team-doctrine/references/docs-paths.md`. Writes: `docs/spec/{slug}.md` (PRDs only — NOT the 7 reserved names; always singular docs/spec/). Reads: `docs/spec/`, `docs/tdd/`, `docs/ux/`.
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

A feature-level PRD for a non-trivial product surface, landing at `docs/spec/{slug}.md` as the authoritative product record before decomposition into Docket issues. Pick PRD over TDD when scope precedes architecture — what and why is uncertain, not how. The team-lead Large Task pattern's PRD entry point routes here.

## When NOT to Use

<!-- COUPLING: this skill is part of the doc-authoring family. The "When NOT to Use" delegation routes below MUST stay in sync with src/user/claude-code/skills/tdd, adr, ux-spec, and init-specs — update all 5 in lockstep when adding/removing a sibling skill. -->
- Inline scoping notes, advisory replies, decomposition comments, or scratch ideas not meant to live at `docs/spec/`.
- Technical Design Documents: `Skill(tdd, "<topic>")`. Architecture Decision Records: `Skill(adr, "<topic>")`. UX / design specs: `Skill(ux-spec, "<topic>")`.
- Project-wide engineering specs (the 7 reserved names): owned by `init-specs` — this skill HARD-REFUSES those names (Pre-flight step 2).

## Pre-flight

1. **Resolve `{slug}`** per the Argument Handling slug rule.
2. **Reserved-name refusal**: if `{slug}` matches a name in the Reserved-Name List below, ABORT — `Error: '{slug}.md' is a reserved name owned by the init-specs skill. Pick a different topic or use the init-specs skill to bootstrap project specs.` — checked BEFORE collision (and before the script below) so reserved files never reach the overwrite dialog. No overwrite path.
3. **Run `Bash ~/.claude/scripts/doc_preflight.sh prd "<topic>"`** — single-homes slug derivation, date/project context, and the collision check (the near-duplicate probe is tdd-only). Parse stdout: `{slug}`, `{today_date}`, `{project_name}`, `{exact_path_collision}`; on non-zero exit, surface stderr and ABORT. `{exact_path_collision}` is tri-state — real path, empty, or `SKIPPED: docs/spec absent` — never collapse the sentinel into "no collision". `{output_path}` = `docs/spec/{slug}.md`; `{output_dir}` = `docs/spec/`; `{updated_by}` = the calling agent's identifier.
4. **Collision**: a real `{exact_path_collision}` runs the COLLISION_DIALOG below; a `SKIPPED:` sentinel means nothing to collide with — proceed.

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
- "Overwrite" → proceed directly to Authoring Procedure; the existing file is replaced by the final `mv` in Save & Return.
- "Cancel" → emit `Cancelled — no file written.` and end.

**Teammate-context caveat.** `AskUserQuestion` is inert in a teammate (only the main-session lead can call it) — if you cannot get an overwrite decision, do NOT proceed: emit `Blocked: {output_path} exists; overwrite needs operator confirmation — the calling agent routes this to team-lead.` and end.

Never silently overwrite. There is no "append" option — partial appends produce
malformed frontmatter.
<!-- CANONICAL:COLLISION_DIALOG:END -->

On "Pick new slug" with an empty follow-up topic: re-prompt up to 3 times, then abort `Error: Could not derive a non-empty slug.`

## Authoring Procedure

1. **Gather prior art**: `Grep -r "{topic-keywords}" docs/`; read related PRDs in `docs/spec/` (the 7 reserved engineering specs are project conventions, not PRDs — skip unless genuinely depended on) plus TDDs and `docs/ux/` specs touching the same surface — reference, not contradict, prior accepted definitions, and record each one built on in `dependencies`.
2. **Probe Docket** (informational): `docket issue list --sort priority:asc --json` and `docket issue list --tree`; surface intersecting issues under a "Pre-existing Docket issues" sub-bullet in Risks & Open Questions.
3. **Draft the frontmatter** (`maturity: "draft"` initially), then **each Required Section in order**, then at least one Mermaid block per the mandate below, then proceed to Validation Before Save.

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

Field rules: `project` = `basename $(git rev-parse --show-toplevel)`; `maturity` is one of `proof-of-concept | draft | experimental | stable` (new PRDs start `draft`); **PRDs do NOT use a `status` field** — `status` is reserved for in-flight workflow artifacts (TDDs and ADRs), while PRDs are living product definitions on the `maturity` ladder; `last_updated` is `YYYY-MM-DD`; `updated_by` is the calling agent identifier; `dependencies` is a YAML array of related-file paths (`[]` if none).

### Required Sections

`##` headings carrying the section title ONLY — list numbers are NOT part of the heading; the validator matches heading text exactly, in this order:

1. **Problem Statement** — what the product surface is, why now, who is affected, constraints, business context.
2. **Goals** — concrete, testable outcomes the PRD commits to.
3. **Non-Goals** — explicit out-of-scope items, including future-work flags.
4. **User Stories / Use Cases** — narrative scenarios from the user perspective, with explicit per-story priority under ONE named scheme (P0/P1/P2 or MVP/polish) applied consistently — bare "with priorities" is a defect.
5. **Requirements** — functional and non-functional, prioritized MoSCoW (Must / Should / Could / Won't). Each requirement testable: a reviewer can point at a behavior and say "satisfies / does not satisfy" without a follow-up clarification.
6. **Success Metrics** — quantitative measures validating the Goals; each names (a) what is measured, (b) the method, (c) a numeric target or threshold. "Improve UX" is a defect; "p95 first-token latency under 800ms measured via /metrics endpoint" is acceptable.
7. **Risks & Open Questions** — risk table (likelihood/impact/mitigation); open questions resolved or escalated before decomposition.

### Mermaid Mandate

At least one ```` ```mermaid ```` (lowercase, no space) fenced block — user journey, state diagram, or component map — whose FIRST non-blank line starts with a diagram-type keyword (`journey`, `stateDiagram-v2`, `graph`/`flowchart`, `erDiagram`, `sequenceDiagram`, …); a leading `%%` comment fails the check. No override — a pure-policy decision routes to `Skill(adr, ...)` instead.

## Validation Before Save

The full checklist — frontmatter contract (including the no-`status` rule), `maturity` allow-list, section order, Mermaid presence & shape, placeholder scan, Success-Metrics concreteness — is mechanized by `doc_validate.py`, the single source of truth. Before the final `mv`:

1. **Stage the draft.** Resolve the staging dir: `Bash echo "${TMPDIR:-/tmp}"` → `{staging_dir}` (an absolute path — `Write`/`Read` take literal paths and never expand `$TMPDIR`). `Write` the complete draft to `{staging_dir}/{slug}.md`.
2. **Run** `Bash python3 ~/.claude/scripts/doc_validate.py --type prd "{staging_dir}/{slug}.md"` — the same resolved `{staging_dir}`, always via `python3` (a copy that lost its executable bit exits 126, which no branch below handles).
3. **Exit codes:** **0** → Save & Return. **1** → ABORT quoting stderr (`Error: validation failed: {field/section} — {detail}.`) — no fix-and-retry; the calling agent re-invokes. **2** → ABORT with `Error: validator unavailable: {stderr}` so the caller escalates infrastructure, not the draft.

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

On operator Cancel during the collision dialog: emit
`Cancelled — no file written.` and end without writing.
<!-- CANONICAL:SAVE_AND_RETURN:END -->

A failed `mv` (permissions, disk, cross-device) surfaces the raw error — `Error: mv failed — {raw error}.` — with no retry.

## Reserved-Name List

The 7 names below are owned by the `init-specs` skill and HARD-REFUSED by this skill (Pre-flight step 2).

<!-- COUPLING: the 7 reserved names are owned by src/user/claude-code/skills/init-specs (Spec File Reference) and HARD-REFUSED here because PRD shares docs/spec/ as its output directory. Sibling doc-authoring skills (tdd, adr, ux-spec) write to different directories (docs/tdd/, docs/adr/, docs/ux/) so they do not refuse these names. Update init-specs and this file in lockstep when adding/removing names. -->
<!-- RESERVED-NAMES:BEGIN -->
architecture
security
operations
performance
code-quality
review-strategy
testing
<!-- RESERVED-NAMES:END -->
