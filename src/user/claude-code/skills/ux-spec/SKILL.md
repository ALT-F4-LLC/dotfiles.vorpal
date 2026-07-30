---
name: ux-spec
description: >
  Author a single UX design spec at docs/ux/{slug}.md. Loaded into the calling agent's
  context; the agent drafts the spec per the format authority below.
  Trigger: "create UX spec", "draft UX spec", "author design spec", "design spec for the new CLI", "produce a design spec", "create UX design".
argument-hint: "<topic>"
allowed-tools: ["AskUserQuestion", "Bash", "Glob", "Grep", "Read", "Write"]
---

<!-- CANONICAL:BANNER:BEGIN -->
> **CRITICAL:** (1) Do NOT commit ANY changes (no `git add`, no `git commit`, no `git push`) unless EXPLICITLY instructed by the user. (2) This is a leaf skill. You MUST NOT spawn sub-agents, invoke `Skill()` recursively, use `Agent()` or `SendMessage`, or form/manage a team. The calling agent handles peer messaging after this skill returns.
<!-- CANONICAL:BANNER:END -->

# UX Spec — Author a UX Design Spec

You are the **UX Spec Author**: produce a single UX design spec at `docs/ux/{slug}.md` and return. The calling agent (typically `@ux-designer`) drafts the content; this skill is the format authority — section list, frontmatter contract, output path, collision handling.

<!-- CANONICAL:DOCS-PATHS-LOCAL:BEGIN -->
**Docs paths (this skill).** Master: `~/.claude/skills/team-doctrine/references/docs-paths.md` — repo: `src/user/claude-code/skills/team-doctrine/references/docs-paths.md`. Writes: `docs/ux/{slug}.md`. Reads: `docs/spec/` (always singular), `docs/tdd/`, `docs/ux/`, `docs/adr/`.
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

A new or significantly revised user-facing surface (CLI, TUI, API, agent prompt, config format, doc structure) needs design guidance — wireframes, interaction flows, error states, accessibility — before implementation. Full UX specs are Tier 4 work (new interaction pattern, multi-surface, core workflow change, precedent-setting) per `~/.claude/agents/ux-designer.md` Responsibility 1.

## When NOT to Use

<!-- COUPLING: this skill is part of the doc-authoring family. The "When NOT to Use" delegation routes below MUST stay in sync with src/user/claude-code/skills/prd, tdd, and adr — update all 4 in lockstep when adding/removing a sibling skill. Also bridges the report-emission family (design-review, design-qa) which brackets the ux-spec lifecycle — keep those routes accurate too. -->
- Inline advisory replies, review comments, scratch wireframes, or one-off copy proposals not meant to live at `docs/ux/`.
- Internal-only surfaces, single-tier design fits (flag rename, copy tweak, one-shot error message), or anything fitting the calling agent's lighter Design Output Tiers 1-3.
- Peer review of a draft spec — `Skill(design-review, "<scope>")`; QA of shipped implementation — `Skill(design-qa, "<scope>")`.
- Technical Design Documents — `Skill(tdd, "<topic>")` (when a UX spec implies non-trivial system design, the architecture belongs in a sibling TDD, referenced not restated). ADRs — `Skill(adr, "<topic>")`. PRDs — `Skill(prd, "<topic>")`.
- Project-wide engineering specs: owned by `init-specs`.

## Pre-flight

1. **Run `Bash ~/.claude/scripts/doc_preflight.sh ux-spec "<topic>"`** — single-homes slug derivation, date/project context, and the collision check (the near-duplicate probe is tdd-only). Parse stdout: `{slug}`, `{today_date}`, `{project_name}`, `{exact_path_collision}`; on non-zero exit, surface stderr and ABORT. `{exact_path_collision}` is tri-state — real path, empty, or `SKIPPED: docs/ux absent` — never collapse the sentinel into "no collision". `{output_path}` = `docs/ux/{slug}.md`; `{output_dir}` = `docs/ux/`; `{updated_by}` = the calling agent's identifier.
2. **Collision**: a real `{exact_path_collision}` runs the COLLISION_DIALOG below; a `SKIPPED:` sentinel means nothing to collide with — proceed.

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

1. **Gather prior art**: `Grep -r "{topic-keywords}" docs/spec/ docs/tdd/ docs/ux/ docs/adr/`; read adjacent specs touching the same surface or terminology — reference, not contradict, prior accepted specs and design tokens (same concept gets the same name across all surfaces).
2. **Draft the frontmatter** (`maturity: "draft"` initially), then **each Required Section in order**. Match spec fidelity to problem complexity — a section that does not apply to the surface type may contain a single `N/A.` paragraph with a one-line justification, but omitting it is a defect.
3. **Mermaid**: satisfy the Mermaid Mandate below. ASCII wireframes are encouraged alongside Mermaid but do not replace it.
4. **Propose actual copy**: real button labels, error messages (what happened → why → what to do), empty states, tooltips — no placeholder strings. When copy or layout variants need the operator's pick before save, prefer `AskUserQuestion` with the `preview` field (CLI mockup, ASCII wireframe, or copy variants) so alternatives are compared visually.
5. **Cover error branches**: every workflow in Interaction Design includes its error and recovery branches; Edge Cases & Error States enumerates empty, overloaded, degraded, and concurrent states.
6. **Resolve open questions before save**: no unresolved questions ship. There is no dedicated Open Questions section — entries belong inside §9 Handoff Notes and must be resolved (or the calling agent re-invokes after consulting peers and the operator).

## Output Contract

### Required Frontmatter

```yaml
---
project: "{project_name}"
maturity: "draft"
last_updated: "{today_date}"
updated_by: "{updated_by}"
scope: "{one-liner describing what the UX spec covers}"
owner: "{owning agent or team, e.g. @ux-designer}"
dependencies:
  - {relative path to related TDD/PRD/UX doc, or empty list}
---
```

Field rules: `project` = `basename $(git rev-parse --show-toplevel)`; `maturity` is one of `proof-of-concept | draft | experimental | stable` (new specs start `draft`); **UX specs do NOT have a `status` field** — workflow state rides `maturity`; `last_updated` is `YYYY-MM-DD`; `updated_by` is the calling agent identifier; `dependencies` is a YAML array of related-file paths (`[]` if none).

### Required Sections

`##` headings carrying the section title ONLY — list numbers are NOT part of the heading; the validator matches heading text exactly, in this order:

1. **Overview** — surface type, users (skill/context/frequency), key workflows (3-5 prioritized), success criteria (concrete, testable), success metrics (quantitative).
2. **Information Architecture** — user-facing data model, navigation/discoverability, information hierarchy.
3. **Layout & Structure** — wireframes/structure adapted to surface (ASCII for TUI, command tree for CLI, schemas for API, file tree for doc structures).
4. **Interaction Design** — user flows with error branches, input patterns, feedback patterns, perceived performance, keyboard/shortcut map, destructive-action confirmation. **Any affordance whose visibility or enabled/disabled state depends on backend or system state MUST cite the authoritative eligibility check verbatim** — the code-level predicate (handler precondition / accepted-state set), grepped and confirmed against code, not the prose description — so the affordance surfaces iff the action would be accepted; a prose-inferred gate can invert against the backend and appear exactly when the action would be rejected.
5. **Visual & Sensory Design** — semantic color palette, typography hierarchy, spacing/density, motion where it aids comprehension, terminal constraints. Specify the rendered EFFECT at real delivery resolution (screenshare, streamed video, small viewport), not just the CSS/token value, and pair every color/visual cue with a text fallback so a degraded render still carries meaning.
6. **Edge Cases & Error States** — empty, error, overloaded (10K+ items), degraded (network/permissions), concurrent.
7. **Accessibility** — keyboard navigation, screen-reader semantics, color independence, motion sensitivity, terminal accessibility.
8. **Internationalization / Privacy / Measurement** — scaled to the project: i18n (text expansion, RTL, locale), data minimization, metrics (instrumentation points, iteration triggers).
9. **Handoff Notes** — the bridge to @project-manager (decomposition) and @senior-engineer (implementation). MUST include: (a) component/surface breakdown with proposed file or module scoping where known, AND a per-component sequence priority (P0/P1/P2) so @project-manager can order Docket issues without re-deriving; (b) the MVP cutline (v1 components vs deferred polish) — the shared scope boundary @senior-engineer builds to and design-qa QAs against; (c) resolved design decisions with one-line rationale; (d) cross-spec dependencies; (e) recommended follow-on research or usability validation the calling agent cannot run. Vague entries ("see TDD", "TBD") are a defect.

### Mermaid Mandate

Required for every UX spec (no override): at least one ```` ```mermaid ```` (lowercase, no space) block — user flow, state transition, or cross-surface journey — whose FIRST non-blank line starts with a diagram-type keyword (`journey`, `stateDiagram-v2`, `graph`/`flowchart`, `sequenceDiagram`, …); a leading `%%` comment fails the check. For non-GUI surfaces, a cross-surface journey (`cli invocation → API call → persisted config`) or an input/output state machine satisfies it; single-action CLIs diagram the surrounding workflow.

## Validation Before Save

The full checklist — frontmatter contract (including the no-`status` rule), `maturity` allow-list, section order, Mermaid presence & shape, placeholder scan — is mechanized by `doc_validate.py`, the single source of truth. Before the final `mv`:

1. **Stage the draft.** Resolve the staging dir: `Bash echo "${TMPDIR:-/tmp}"` → `{staging_dir}` (an absolute path — `Write`/`Read` take literal paths and never expand `$TMPDIR`). `Write` the complete draft to `{staging_dir}/{slug}.md`.
2. **Run** `Bash python3 ~/.claude/scripts/doc_validate.py --type ux-spec "{staging_dir}/{slug}.md"` — the same resolved `{staging_dir}`, always via `python3` (a copy that lost its executable bit exits 126, which no branch below handles).
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
