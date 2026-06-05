---
name: ux-spec
description: >
  Author a single UX design spec as a Docket doc (docket doc create -T ux). Loaded into
  the calling agent's context; the agent drafts the spec per the format authority below.
  Trigger: "create UX spec", "draft UX spec", "author design spec", "design spec for the new CLI", "produce a design spec", "create UX design".
argument-hint: "<topic>"
effort: max
allowed-tools: ["AskUserQuestion", "Bash", "Read", "Write"]
---

<!-- CANONICAL:BANNER:BEGIN -->
> **CRITICAL:** (1) Do NOT commit ANY changes (no `git add`, no `git commit`, no `git push`) unless EXPLICITLY instructed by the user. (2) This is a leaf skill. You MUST NOT spawn sub-agents, invoke `Skill()` recursively, or use `Agent()`, `TeamCreate`, `TeamDelete`, or `SendMessage`. The calling agent handles peer messaging after this skill returns.
<!-- CANONICAL:BANNER:END -->

# UX Spec — Author a UX Design Spec

You are the **UX Spec Author**. You produce a single UX design spec as a Docket doc
(type `ux`) and return. The calling agent (typically `@ux-designer`) drafts the content;
this skill is the format authority — section list, frontmatter contract, and the
`docket doc create` recipe all live here. Docket issues the document's `DOC-<n>`
identity; there is no filename.

## Argument Handling

<!-- CANONICAL:ARGUMENT_HANDLING:BEGIN -->
The argument is a single positional `<topic>` (free-text, 3-10 words describing the
artifact). No flags, no other args.

If `<topic>` is missing or empty:

```
Error: Usage: Skill({TYPE}, "<topic>") — describe the artifact in 3-10 words.
```

If extra positional args are passed beyond `<topic>`, ignore them silently.

**Title derivation.** The document's identity is the Docket-issued `DOC-<n>`, not a
filename — there is no slug-to-path step. The `<topic>` is the human-readable `-t`
title (Title Case, free prose). Use `<topic>` verbatim as the default `{title}`; the
calling agent MAY refine it into a clearer prose title. Reject only an empty/all-
punctuation topic that yields no title text:

1. `cleaned = topic.strip()`.
2. If `cleaned` contains no alphanumeric character, ABORT: `Error: Topic must contain at least one alphanumeric character.`
3. Use `cleaned` (or a calling-agent refinement of it) as `{title}`.
<!-- CANONICAL:ARGUMENT_HANDLING:END -->

## When to Use

- A new or significantly revised user-facing surface (CLI, TUI, API, agent prompt,
  config format, doc structure) needs design guidance — wireframes, interaction
  flows, error states, accessibility — before implementation, and should live as a
  Docket `ux` doc as the authoritative design record.
- The calling agent (typically `@ux-designer`) is producing a design spec per
  Responsibility 1 of the agent prompt (`agents/ux-designer.md`).

## When NOT to Use

<!-- COUPLING: this skill is part of the doc-authoring family. The "When NOT to Use" delegation routes below MUST stay in sync with skills/prd, tdd, adr, and init-specs — update all 5 in lockstep when adding/removing a sibling skill. Also bridges the report-emission family (design-review, design-qa) which brackets the ux-spec lifecycle — keep those routes accurate too. -->
- Inline advisory replies, design review comments, scratch wireframes, or one-off
  copy proposals that are not meant to live as a Docket `ux` doc.
- Internal-only surfaces (agent-to-agent protocols, internal scripts, build
  tooling without external users), single-tier design fits (CLI flag rename,
  copy tweak, one-shot error message), or work that fits the calling agent's
  Design Output Tiers 1–3 (`agents/ux-designer.md` Responsibility 1) — use the
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

1. **Resolve `{title}`** from `<topic>` per the Argument Handling title rule above.
2. **Resolve context**:
   - `{today_date}` = `Bash date +%Y-%m-%d`.
   - `{project_name}` = `Bash basename $(git rev-parse --show-toplevel)`.
   - `{updated_by}` = the calling agent's identifier (e.g., `@ux-designer`).
3. **Near-duplicate probe** (advisory, non-blocking): run `docket doc list -T ux --json`
   and scan existing UX-spec titles for one that covers the same surface as `<topic>`.
   If a close match exists, surface it to the calling agent context as a one-line note:
   `Near-duplicate UX spec(s) detected: {DOC-ids + titles}. Proceed only if this is intentionally distinct work.` The calling agent decides whether to continue or refine the title; no automatic block. Docket does not collide on title, so there is no overwrite path — a new create always issues a fresh `DOC-<n>`.

## Authoring Procedure

1. **Gather prior art**: discover related docs with `docket doc list -T ux --json`,
   `docket doc list -T tdd --json`, and `docket doc list -T prd --json`, then read any
   adjacent docs via `docket doc show <DOC-id>`. The new UX spec should reference, not
   contradict, prior approved UX specs and design tokens (per `agents/ux-designer.md`:
   same concept gets the same name across all surfaces).
2. **Draft the frontmatter** per the Required Frontmatter contract below. UX specs
   use `maturity` (not `status`); new specs start at `maturity: "draft"`.
3. **Draft each Required Section in order** (see Output Contract → Required Sections). Every section listed MUST appear, in the order shown. Match spec fidelity to problem complexity — sections that do not apply to the surface type (e.g., accessibility for a non-interactive config schema) may contain a single `N/A.` paragraph with a one-line justification, but omitting them is a defect.
4. **Mermaid diagrams**: satisfy the Mermaid Mandate (see below) — at least one block.
   ASCII wireframes are encouraged alongside Mermaid but do not replace it.
5. **Propose actual copy**: per `agents/ux-designer.md` content design rule, propose
   real button labels, error messages (what happened → why → what to do), empty
   states, and tooltips. No placeholder strings. **When the calling agent must resolve
   copy or layout variants with the operator before save, prefer `AskUserQuestion`
   with the `preview` field** (CLI mockup, ASCII wireframe, or copy variants) so the
   operator can compare alternatives visually rather than from prose descriptions.
6. **Cover error branches**: every workflow in Interaction Design includes its
   error and recovery branches. Edge Cases & Error States enumerates empty,
   overloaded, degraded, and concurrent states.
7. **Resolve open questions before save**: per `agents/ux-designer.md`, no
   unresolved questions ship with the spec. There is no dedicated Open Questions
   section — entries belong inside §9 Handoff Notes and must be resolved (or the
   calling agent re-invokes this skill after consulting peers and the operator).

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
  - {DOC-<n> of related TDD/PRD/UX doc, or empty list}
status: "draft"
---
```

Field rules:

- `project` = `basename $(git rev-parse --show-toplevel)`.
- `maturity` is the doc-class ladder
  (`proof-of-concept | draft | experimental | stable`). New UX specs start at
  `draft`.
- `status` mirrors Docket's own doc-level status (`-s`) — one of `draft | approved`.
  New UX specs start at `draft`; promotion to `approved` happens after the calling
  agent's review loop via `docket doc edit <DOC-id> -s approved`. (`maturity` and
  `status` are orthogonal: `maturity` is how settled the content is, `status` is where
  the doc sits in the review lifecycle.)
- `last_updated` is ISO date `YYYY-MM-DD`.
- `updated_by` is the calling agent identifier (`@ux-designer`, etc.).
- `scope` is a one-line description of what the doc covers — populated by the
  calling agent.
- `owner` is the responsible agent or team handle.
- `dependencies` is a YAML array of related `DOC-<n>` ids; use `[]` if none.

### Required Sections

The UX spec body MUST contain these top-level sections, in this order. Each is a
`##` heading in the drafted document. The list mirrors `agents/ux-designer.md`
Responsibility 1 design spec format.

1. **Overview** — surface type, users (skill/context/frequency), key workflows
   (3-5 prioritized), success criteria (concrete, testable), success metrics
   (quantitative).
2. **Information Architecture** — user-facing data model,
   navigation/discoverability, information hierarchy.
3. **Layout & Structure** — wireframes/structure adapted to surface (ASCII for
   TUI, command tree for CLI, schemas for API, file tree for doc structures).
4. **Interaction Design** — user flows with error branches, input patterns,
   feedback patterns, perceived performance, keyboard/shortcut map, destructive
   action confirmation.
5. **Visual & Sensory Design** — semantic color palette, typography hierarchy,
   spacing/density, motion (where it aids comprehension), terminal constraints.
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

Mermaid is **required** for every UX spec (no override) — at least one block showing a user flow, state transition, or cross-surface journey. Acceptable block fences are ` ```mermaid ` (lowercase, no space). Authority: `agents/ux-designer.md`.

For non-GUI surfaces (CLI flag, API endpoint, config schema, log format), a
cross-surface journey (e.g., `cli invocation → API call → persisted config`) or
an input/output state machine satisfies the mandate. Single-action CLIs without
state should diagram the surrounding workflow, not the action itself.

## Validation Before Save

Before invoking `Write`, verify in the calling agent's context:

1. **Frontmatter fields** — all of `project`, `maturity`, `last_updated`,
   `updated_by`, `scope`, `owner`, `dependencies`, `status` present and non-empty
   (`dependencies` may be the empty list `[]`).
2. **`status` value** — `status` is one of `draft | approved`.
3. **Maturity value** — `maturity` is one of
   `proof-of-concept | draft | experimental | stable`.
4. **Section order** — the body contains all top-level sections enumerated
   in "Required Sections" above, as `##` headings, in the order listed.
   Off-by-one against the listed sections is a defect.
5. **Mermaid presence** — at least one ` ```mermaid ` fenced block in the body.
6. **Placeholder scan** — body contains no literal `{title}`, `{topic}`,
   `{project_name}`, `TBD`, or `TODO` text outside of code-fenced examples.

If any check fails, ABORT (no fix-and-retry — the skill validates then writes
in a single pass; repair is the calling agent's responsibility):

```
Error: validation failed: {field/section} — {detail}.
```

The calling agent fixes the issue in its own context and re-invokes
`Skill(ux-spec, "<topic>")`.

## Create & Return

<!-- CANONICAL:SAVE_AND_RETURN:BEGIN -->
After Validation Before Save passes, create the doc in Docket. The full document body
(frontmatter block + all Required Sections) is drafted to a temp file, then supplied to
`docket doc create` via `-d @`:

1. `Write` the full drafted document body to a temp file under `$TMPDIR`:

   ```
   BODY="${TMPDIR:-/tmp}/ux-doc.md"
   ```

2. Create the doc (type `ux`, create-status `draft`), capturing JSON:

   ```
   docket doc create -T ux -t "{title}" -s draft -d @"$BODY" --json
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

## Failure Modes

| Trigger | Handling |
|---|---|
| `<topic>` missing or empty | Abort: `Error: Usage: Skill(ux-spec, "<topic>") — describe the artifact in 3-10 words.` |
| Title empty after trimming (e.g., all-punct topic) | Abort: `Error: Topic must contain at least one alphanumeric character.` |
| Validation Before Save fails | Abort with `Error: validation failed: {field/section} — {detail}.` No retry — calling agent re-invokes. |
| Required section missing or out of order | Abort: `Error: validation failed: section §N — Required section '{name}' missing or out of order. UX specs require all sections enumerated in Required Sections, in the listed order.` |
| Frontmatter `status` value outside the allowed set | Abort: `Error: validation failed: frontmatter — 'status' must be one of draft \| approved. Got '{value}'.` |
| Mermaid mandate not satisfied | Abort: `Error: validation failed: Mermaid block missing — UX specs require at least one mermaid fenced block (user flow, state transition, or cross-surface journey).` |
| `docket doc create` returns a non-ok JSON envelope | Surface raw error: `Error: docket doc create failed — {message}.` Do NOT retry. The temp-file body remains on disk; the calling agent reports to the operator. |
| Caller passes additional positional args beyond `<topic>` | Ignore extras silently. |
