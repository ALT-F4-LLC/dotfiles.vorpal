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

You are the **UX Spec Author**. You produce a single UX design spec at
`docs/ux/{slug}.md` and return. The calling agent (typically `@ux-designer`) drafts
the content; this skill is the format authority — section list, frontmatter contract,
output path, and collision handling all live here.

<!-- CANONICAL:DOCS-PATHS-LOCAL:BEGIN -->
**Docs paths (this skill).** Master: `~/.claude/skills/team-doctrine/references/docs-paths.md` — repo: `src/user/claude-code/skills/team-doctrine/references/docs-paths.md` (maintained copy).
- Writes: `docs/ux/{slug}.md`.
- Reads: `docs/spec/`, `docs/tdd/`, `docs/ux/`, `docs/adr/`.
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

- A new or significantly revised user-facing surface (CLI, TUI, API, agent prompt,
  config format, doc structure) needs design guidance — wireframes, interaction
  flows, error states, accessibility — before implementation, and should land at
  `docs/ux/{slug}.md` as the authoritative design record.
- The calling agent (typically `@ux-designer`) is producing a design spec per
  Responsibility 1 of the agent prompt (`~/.claude/agents/ux-designer.md` — repo: `src/user/claude-code/agents/ux-designer.md`).

## When NOT to Use

<!-- COUPLING: this skill is part of the doc-authoring family. The "When NOT to Use" delegation routes below MUST stay in sync with src/user/claude-code/skills/prd, tdd, adr, and init-specs — update all 5 in lockstep when adding/removing a sibling skill. Also bridges the report-emission family (design-review, design-qa) which brackets the ux-spec lifecycle — keep those routes accurate too. -->
- Inline advisory replies, design review comments, scratch wireframes, or one-off
  copy proposals that are not meant to live at `docs/ux/`.
- Internal-only surfaces (agent-to-agent protocols, internal scripts, build
  tooling without external users), single-tier design fits (CLI flag rename,
  copy tweak, one-shot error message), or work that fits the calling agent's
  Design Output Tiers 1–3 (`~/.claude/agents/ux-designer.md` — repo: `src/user/claude-code/agents/ux-designer.md` — Responsibility 1) — use the
  appropriate lighter tier instead. Full UX specs are reserved for Tier 4
  (new interaction pattern, multi-surface, core workflow change,
  precedent-setting).
- Peer review of a draft UX spec or design proposal (no file written, report into
  the calling agent's context): use `Skill(design-review, "<scope>")`.
- QA of shipped implementation against an accepted UX spec (no file written, report
  into the calling agent's context): use `Skill(design-qa, "<scope>")`.
- Technical Design Documents (architecture/system design): use `Skill(tdd, "<topic>")`. When a UX spec implies non-trivial backend or system design, the architecture portions belong in a sibling TDD; this spec references it rather than restating it.
- Architecture Decision Records (single decisions): use `Skill(adr, "<topic>")`.
- Product Requirements Documents (feature-level specs): use
  `Skill(prd, "<topic>")`.
- Project-wide engineering specs (architecture, security, operations, performance,
  code-quality, review-strategy, testing): owned by the `init-specs` skill.

## Pre-flight

1. **Resolve `{slug}`** from `<topic>` per the Argument Handling slug rule above.
2. **Resolve `{output_path}`** as `docs/ux/{slug}.md`. The output directory is
   `docs/ux/`.
3. **Resolve context**:
   - `{today_date}` = `Bash date +%Y-%m-%d`.
   - `{project_name}` = `Bash basename $(git rev-parse --show-toplevel)`.
   - `{updated_by}` = the calling agent's identifier (e.g., `@ux-designer`).
4. **Check collision**: `Glob docs/ux/{slug}.md`. If a file exists at
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
- "Overwrite" → first `Read {output_path}` (the harness blocks an overwrite Write of an unread file), then proceed to Authoring Procedure; the existing file is replaced on Write.
- "Cancel" → emit `Cancelled — no file written.` and end.

**Teammate-context caveat.** `AskUserQuestion` is inert in a teammate (only the main-session lead can call it) — if you cannot get an overwrite decision, do NOT Write: emit `Blocked: {output_path} exists; overwrite needs operator confirmation — the calling agent routes this to team-lead.` and end.

Never silently overwrite. There is no "append" option — partial appends produce
malformed frontmatter.
<!-- CANONICAL:COLLISION_DIALOG:END -->

## Authoring Procedure

1. **Gather prior art**: `Grep -r "{topic-keywords}" docs/spec/ docs/tdd/ docs/ux/ docs/adr/`. Read any adjacent specs that touch the same surface or terminology — the new UX spec should reference, not contradict, prior accepted UX specs and design tokens (per `~/.claude/agents/ux-designer.md`, repo: `src/user/claude-code/agents/ux-designer.md`: same concept gets the same name across all surfaces).
2. **Draft the frontmatter** per the Required Frontmatter contract below. UX specs
   use `maturity` (not `status`); new specs start at `maturity: "draft"`.
3. **Draft each Required Section in order** (see Output Contract → Required Sections). Every section listed MUST appear, in the order shown. Match spec fidelity to problem complexity — sections that do not apply to the surface type (e.g., accessibility for a non-interactive config schema) may contain a single `N/A.` paragraph with a one-line justification, but omitting them is a defect.
4. **Mermaid diagrams**: satisfy the Mermaid Mandate (see below) — at least one block.
   ASCII wireframes are encouraged alongside Mermaid but do not replace it.
5. **Propose actual copy**: per `~/.claude/agents/ux-designer.md` (repo: `src/user/claude-code/agents/ux-designer.md`) content design rule, propose
   real button labels, error messages (what happened → why → what to do), empty
   states, and tooltips. No placeholder strings. **When the calling agent must resolve
   copy or layout variants with the operator before save, prefer `AskUserQuestion`
   with the `preview` field** (CLI mockup, ASCII wireframe, or copy variants) so the
   operator can compare alternatives visually rather than from prose descriptions.
6. **Cover error branches**: every workflow in Interaction Design includes its
   error and recovery branches. Edge Cases & Error States enumerates empty,
   overloaded, degraded, and concurrent states.
7. **Resolve open questions before save**: per `~/.claude/agents/ux-designer.md` (repo: `src/user/claude-code/agents/ux-designer.md`), no
   unresolved questions ship with the spec. There is no dedicated Open Questions
   section — entries belong inside §9 Handoff Notes and must be resolved (or the
   calling agent re-invokes this skill after consulting peers and the operator).
8. **Principle alignment self-check**: before save, walk the draft against the eight HIG principles (definitions: `~/.claude/agents/ux-designer.md` §Core Principles — repo: `src/user/claude-code/agents/ux-designer.md`): Purpose grounds §1 success criteria; Familiarity grounds consistency with prior art (step 1); Agency and the error-case-first house floor ground error/recovery branches (step 6); Simplicity grounds copy and hierarchy (steps 3, 5); Flexibility grounds §7 Accessibility; Craft grounds the actual-copy/no-placeholder rule (step 5); Delight is checked last and never at the cost of the task. Record in §9 Handoff Notes which principle won any documented tension.

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

Field rules:

- `project` = `basename $(git rev-parse --show-toplevel)`.
- `maturity` is the doc-class ladder
  (`proof-of-concept | draft | experimental | stable`). New UX specs start at
  `draft`. **UX specs do NOT have a `status` field** — workflow state is tracked
  via `maturity`. (Doc-family convention: PRDs and UX specs use `maturity`
  only — they are living definitions, not vote-gated workflow artifacts. TDDs
  use both. ADRs use `status` only.)
- `last_updated` is ISO date `YYYY-MM-DD`.
- `updated_by` is the calling agent identifier (`@ux-designer`, etc.).
- `scope` is a one-line description of what the doc covers — populated by the
  calling agent.
- `owner` is the responsible agent or team handle.
- `dependencies` is a YAML array of related-file paths (relative to the doc); use
  `[]` if none.

### Required Sections

The UX spec body MUST contain these top-level sections, in this order. Each is a
`##` heading in the drafted document.

1. **Overview** — surface type, users (skill/context/frequency), key workflows
   (3-5 prioritized), success criteria (concrete, testable), success metrics
   (quantitative).
2. **Information Architecture** — user-facing data model,
   navigation/discoverability, information hierarchy.
3. **Layout & Structure** — wireframes/structure adapted to surface (ASCII for
   TUI, command tree for CLI, schemas for API, file tree for doc structures).
4. **Interaction Design** — user flows with error branches, input patterns,
   feedback patterns, perceived performance, keyboard/shortcut map, destructive
   action confirmation. Any affordance whose visibility or enabled/disabled state
   depends on backend or system state MUST cite the authoritative eligibility check
   verbatim — the code-level predicate (handler precondition / accepted-state set),
   grepped and confirmed against code, not the prose description — so the affordance
   surfaces iff the action would be accepted. A prose-inferred gate can invert
   against the backend and appear exactly when the action would be rejected.
5. **Visual & Sensory Design** — semantic color palette, typography hierarchy,
   spacing/density, motion (where it aids comprehension), terminal constraints.
   Specify the rendered EFFECT target at real delivery resolution (screenshare,
   streamed video, small viewport), not just the CSS/token value — a cue that meets
   the contract may not read once compressed. Pair every color/visual cue with a text
   fallback so a degraded render still carries meaning.
6. **Edge Cases & Error States** — empty states, error states, overloaded states
   (10K+ items), degraded states (network/permissions), concurrency.
7. **Accessibility** — keyboard navigation, screen reader semantics, color
   independence, motion sensitivity, terminal accessibility.
8. **Internationalization / Privacy / Measurement** — scale to project: i18n (text
   expansion, RTL, locale), data minimization (inventory, consent, display),
   metrics (instrumentation points, iteration triggers).
9. **Handoff Notes** — the bridge to @project-manager (decomposition) and
   @senior-engineer (implementation). MUST include: (a) component / surface
   breakdown with proposed file or module scoping where known, AND a per-component
   sequence priority (P0/P1/P2) so @project-manager can order Docket issues without
   re-deriving; (b) the MVP cutline (v1 components versus deferred polish) — the
   shared scope boundary @senior-engineer builds to and design-qa QAs against; (c)
   resolved design decisions with one-line rationale; (d) cross-spec dependencies
   (TDDs, PRDs, sibling UX specs); (e) recommended follow-on research,
   instrumentation, or usability validation the calling agent cannot run. Vague
   entries ("see TDD", "TBD") are a defect.

### Mermaid Mandate

Mermaid is **required** for every UX spec (no override) — at least one block showing a user flow, state transition, or cross-surface journey. Acceptable block fences are ` ```mermaid ` (lowercase, no space). Authority: `~/.claude/agents/ux-designer.md` (repo: `src/user/claude-code/agents/ux-designer.md`).

For non-GUI surfaces (CLI flag, API endpoint, config schema, log format), a
cross-surface journey (e.g., `cli invocation → API call → persisted config`) or
an input/output state machine satisfies the mandate. Single-action CLIs without
state should diagram the surrounding workflow, not the action itself.

## Validation Before Save

The full checklist — the frontmatter contract (including the no-`status` rule),
the `maturity` allow-list, section order, Mermaid presence & shape, and the
placeholder scan — is mechanized by the shared `doc_validate.py`, the single source
of truth for what a valid UX spec must satisfy. Validate the drafted document before
the final Write:

1. **Stage the draft.** `Write` the complete drafted content (frontmatter + body)
   to a staging path under `$TMPDIR` — e.g. `$TMPDIR/{slug}.md`.
2. **Run the validator.** `Bash ~/.claude/scripts/doc_validate.py --type ux-spec "$TMPDIR/{slug}.md"`
   (repo: `src/user/claude-code/scripts/doc_validate.py`).
3. **Act on the exit code:**
   - **exit 0** — validation passed; proceed to Save & Return (the final `Write` to
     `docs/ux/...`).
   - **exit 1** — validation failure. ABORT, quoting the script's stderr (no
     fix-and-retry — the skill validates then writes in a single pass; repair is the
     calling agent's responsibility, and it re-invokes `Skill(ux-spec, "<topic>")`):

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

## Failure Modes

| Trigger | Handling |
|---|---|
| `<topic>` missing or empty | Abort: `Error: Usage: Skill(ux-spec, "<topic>") — describe the artifact in 3-10 words.` |
| Slug empty after sanitization (e.g., all-CJK or all-punct topic) | Abort: `Error: Topic must contain at least one alphanumeric character.` |
| Output file already exists | Run COLLISION_DIALOG; never silently overwrite. On Cancel: `Cancelled — no file written.` |
| Validation Before Save fails | Abort with `Error: validation failed: {field/section} — {detail}.` No retry — calling agent re-invokes. |
| Required section missing or out of order | Abort: `Error: validation failed: section §N — Required section '{name}' missing or out of order. UX specs require all sections enumerated in Required Sections, in the listed order.` |
| Frontmatter contains `status` field | Abort: `Error: validation failed: frontmatter — UX specs use 'maturity', not 'status'. Remove the status field.` |
| Mermaid mandate not satisfied | Abort: `Error: validation failed: Mermaid block missing — UX specs require at least one mermaid fenced block (user flow, state transition, or cross-surface journey).` |
| Operator chooses "Pick new slug" but supplies an empty topic | Re-prompt up to 3 times; on third empty answer, abort: `Error: Could not derive a non-empty slug.` |
| Filesystem write fails (permissions, disk, read-only mount) | Surface raw error: `Error: Write failed — {raw error}.` Do NOT retry. The calling agent reports to the operator. |
