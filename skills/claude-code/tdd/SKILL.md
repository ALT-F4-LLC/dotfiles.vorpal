---
name: tdd
description: >
  Author a single Technical Design Document at docs/tdd/{slug}.md. Loaded into the
  calling agent's context; the agent drafts the TDD per the format authority below.
  Trigger: "create TDD", "draft TDD", "produce a technical design document", "write the design for {feature}".
argument-hint: "<topic>"
allowed-tools: ["AskUserQuestion", "Bash", "Glob", "Grep", "Read", "Write"]
---

<!-- CANONICAL:BANNER:BEGIN -->
> **CRITICAL:** (1) Do NOT commit ANY changes (no `git add`, no `git commit`, no `git push`) unless EXPLICITLY instructed by the user. (2) This is a leaf skill. You MUST NOT spawn sub-agents, invoke `Skill()` recursively, or use `Agent()`, `TeamCreate`, `TeamDelete`, or `SendMessage`. The calling agent handles peer messaging after this skill returns.
<!-- CANONICAL:BANNER:END -->

# TDD — Author a Technical Design Document

You are the **TDD Author**. You produce a single Technical Design Document at
`docs/tdd/{slug}.md` and return. The calling agent (typically `@staff-engineer`)
drafts the content; this skill is the format authority — section list, frontmatter
contract, output path, and collision handling all live here.

> **Note — "TDD" here means Technical Design Document, NOT Test-Driven Development.**

<!-- CANONICAL:DOCS-PATHS-LOCAL:BEGIN -->
**Docs paths (this skill).** Master: team-lead.md §Docs-Path Taxonomy (maintained copy).
- Writes: `docs/tdd/{slug}.md`.
- Reads: `docs/spec/`, `docs/ux/`, `docs/tdd/`.
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

- A Technical Design Document is needed for non-trivial work (architecture, system
  design, multi-step migration, cross-cutting refactor) and should land at
  `docs/tdd/{slug}.md` as the authoritative design record. Pick TDD over PRD when
  *how* is the question — the what/why is settled and architecture is the open work
  (the inverse of prd's "scope precedes architecture" boundary).
- The calling agent (typically `@staff-engineer`) is producing a design that needs to
  go through the draft → questions-resolved → in-review → accepted lifecycle.
- The team-lead orchestrator's Medium Task pattern asks for a TDD without a separate
  PRD — this skill is the canonical path.

## When NOT to Use

<!-- COUPLING: this skill is part of the doc-authoring family. The "When NOT to Use" delegation routes below MUST stay in sync with skills/claude-code/prd, adr, ux-spec, and init-specs — update all 5 in lockstep when adding/removing a sibling skill. -->
- Inline advisory replies, review comments, scratch notes, or one-off design
  sketches that are not meant to live at `docs/tdd/`.
- Architecture Decision Records (single decisions): use `Skill(adr, "<topic>")`.
- Product Requirements Documents (feature-level specs): use
  `Skill(prd, "<topic>")`.
- UX / design specs: use `Skill(ux-spec, "<topic>")`. When a TDD touches a user-facing surface, the interaction-design portions belong in the UX spec; the TDD references it (per Pre-flight §5 + Authoring §1) rather than restating it.
- Project-wide engineering specs (architecture, security, operations, performance,
  code-quality, review-strategy, testing): owned by the `init-specs` skill.

## Pre-flight

1. **Resolve `{slug}`** from `<topic>` per the Argument Handling slug rule above.
2. **Resolve `{output_path}`** as `docs/tdd/{slug}.md`. The output directory is
   `docs/tdd/`.
3. **Resolve context**:
   - `{today_date}` = `Bash date +%Y-%m-%d`.
   - `{project_name}` = `Bash basename $(git rev-parse --show-toplevel)`.
   - `{updated_by}` = the calling agent's identifier (e.g., `@staff-engineer`).
4. **Check collision**: `Glob docs/tdd/{slug}.md`. If a file exists at
   `{output_path}`, run the COLLISION_DIALOG below.
5. **Near-duplicate probe** (advisory, non-blocking): if `len(slug) >= 12`, run `Glob "docs/tdd/{slug[:12]}*.md"` and exclude `{output_path}` itself from the results. If any hits remain, surface them to the calling agent context as a one-line note: `Near-duplicate TDD(s) detected: {paths}. Proceed only if this is intentionally distinct work.` The calling agent decides whether to continue or re-derive a more specific slug; no automatic block. This catches near-identical args (different punctuation, suffix words) that derive to different but adjacent slugs.

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

6. **Related-doc probe**: `Glob docs/spec/*.md docs/ux/*.md`. For each match
   whose slug appears as a substring of `<topic>` (case-insensitive), include
   its relative path in the `dependencies` frontmatter array. The calling
   agent may add others from broader judgment.

## Authoring Procedure

1. **Gather prior art**: `Grep -r "{topic-keywords}" docs/` and read any candidate
   parent PRD or UX spec identified in Pre-flight step 6. Read existing TDDs in
   `docs/tdd/` touching adjacent areas — reference, not contradict, prior accepted work.
2. **Draft the frontmatter** per the Required Frontmatter contract below. Set
   `status: "draft"` initially.
3. **Draft each Required Section in order** (see Output Contract → Required
   Sections). Every section listed MUST appear, in the order shown. Sections
   marked "may be N/A" (Data Models §5, API Contracts §6) may contain a single
   `N/A.` paragraph with a one-line justification. The chosen alternative in §3
   must match the Architecture & System Design section (§4).
4. **Mermaid diagrams**: draft at least one Mermaid block (component map, sequence,
   state, or data flow). Validation §5 is the gate.
5. **Verify embedded technical assertions before stating them as fact.** Any
   concrete claim the TDD commits to — a code/config/command/SQL snippet, a
   cross-platform or cross-engine compatibility claim, an Implementation-Phase
   grep AC, a quantitative or line-budget feasibility claim (sizes, counts,
   fits-under-gate — measure with wc -l/sed -n, never estimate), or a reference
   to existing modules/APIs/test infrastructure the design relies on — MUST be
   checked against its actual target (run it, Grep/Read the target, or confirm
   it exists) before it is written as settled. State unverified claims as
   assumptions, not facts. A "verified" label MUST NOT claim broader scope than
   was actually checked — name the artifact or command behind it.
6. **Proceed to Validation Before Save** — that step is the single source of
   truth for frontmatter, sections, alternatives count, Mermaid, and placeholder
   checks (matches sibling PRD's §6).

## Output Contract

### Required Frontmatter

```yaml
---
project: "{project_name}"
maturity: "draft"
last_updated: "{today_date}"
updated_by: "{updated_by}"
scope: "{one-liner describing what the TDD covers}"
owner: "{owning agent or team, e.g. @staff-engineer}"
dependencies:
  - {relative path to parent PRD or related doc, or empty list}
status: "draft"
---
```

Field rules:

- `project` = `basename $(git rev-parse --show-toplevel)`.
- `maturity` describes how settled the content is (`proof-of-concept | draft | experimental | stable`). `status` describes where the doc sits in the review-and-vote lifecycle (see `status` rule below). The two are orthogonal — a TDD can be `status: accepted` while `maturity: experimental` (design signed off, approach still provisional).
- `last_updated` is ISO date `YYYY-MM-DD`.
- `updated_by` is the calling agent identifier (`@staff-engineer`, etc.).
- `scope` is a one-line description of what the doc covers — populated by the
  calling agent.
- `owner` is the responsible agent or team handle.
- `dependencies` is a YAML array of related-file paths (relative to the doc); use
  `[]` if none.
- `status` is one of: `draft | questions-resolved | in-review | accepted | superseded`.
  New TDDs start at `draft`.

### Required Sections

The TDD body MUST contain these top-level sections, in this order. Each is a
`##` heading in the drafted document.

1. **Problem Statement** — what, why now, who is affected, constraints, acceptance
   criteria, business context.
2. **Context & Prior Art** — existing patterns in this repo and outside; how this
   work fits.
3. **Alternatives Considered** — at least two; shape, strengths, weaknesses,
   verdict per alternative.
4. **Architecture & System Design** — the chosen approach, with sub-sections as
   needed (component map, data flow, sequencing, contracts). **For security
   TDDs** (`updated_by` is `@security-engineer`), this section MUST include
   three `###` subsections — `Threat Model`, `Trust Boundaries`, and
   `Security Considerations` — enforced by Validation §7. Non-security TDDs
   may omit them. (Mixed-scope routing — when @security-engineer appends
   these to a @staff-engineer TDD via the Threat-Model Annotation pattern
   — is owned by `agents/claude-code/security-engineer.md`, not this skill.)
5. **Data Models & Storage** — schemas, persistence, migrations. May be `N/A.`
   with one-line justification if the design has no data plane.
6. **API Contracts** — request/response shapes, RPC contracts, CLI invocation
   shapes. May be `N/A.` with one-line justification.
7. **Migration & Rollout** — current state, target state, rollout sequencing,
   backward compatibility, rollback plan.
8. **Risks & Open Questions** — risk table (likelihood/impact/mitigation); open
   questions resolved or escalated before vote.
9. **Testing Strategy** — test levels, smoke tests, coverage of acceptance
   criteria, untested-claims inventory. **For security TDDs** (per §4
   security-track gating), this section MUST include a named subsection
   `### Abuse Cases` enumerating adversarial-input tests, not just happy-path
   coverage.
10. **Observability & Operational Readiness** — signals, 3am diagnosability,
    production readiness, runbooks.
11. **Implementation Phases** — partitioned phases that the planner consumes
    directly. Each phase MUST specify: (a) one-line phase goal, (b) file scope
    (paths affected), (c) per-phase acceptance criteria — any grep/regex-based
    AC must be run against the named files, hit set verified to cover all expected
    matches (escape markdown, arm for word-order/formatting variants); a single-arm
    regex that silently under-matches is a defect, (d) effort estimate
    (S/M/L), (e) blocking dependencies on other phases, (f) explicit
    out-of-scope flags. Phases must be independently shippable or explicitly
    chained — no implicit ordering.

## Validation Before Save

Before invoking `Write`, verify in the calling agent's context:

1. **Frontmatter fields** — all of `project`, `maturity`, `last_updated`,
   `updated_by`, `scope`, `owner`, `dependencies`, `status` present and
   non-empty (`dependencies` may be the empty list `[]`).
2. **Status value** — `status` is one of `draft | questions-resolved |
   in-review | accepted | superseded`.
3. **Section order** — the body contains all top-level sections enumerated
   in "Required Sections" above, as `##` headings, in the order listed.
   Count only `##` headings at column 0 *outside* ``` code fences — a TDD that
   documents another doc/skill may embed `##`/`###` example headings inside
   fences; those are content, not structure. Off-by-one against the listed
   sections is a defect.
4. **Alternatives count** — Section 3 (Alternatives Considered) contains at
   least two `###`-level subsections (counting only `###` headings outside
   ``` code fences).
5. **Mermaid presence** — at least one ` ```mermaid ` fenced block in the body.
6. **Placeholder scan** — body contains no literal `{slug}`, `{topic}`,
   `{project_name}`, `TBD`, or `TODO` text outside of code-fenced examples.
7. **Security-track subsections** — if `updated_by` is `@security-engineer`,
   verify §4 (Architecture & System Design) contains three `###`-level
   subsections named exactly `Threat Model`, `Trust Boundaries`, and
   `Security Considerations`. Non-security TDDs skip this check.
8. **Security-track abuse cases** — if `updated_by` is `@security-engineer`,
   verify §9 (Testing Strategy) contains a `###`-level subsection named
   `Abuse Cases`. Non-security TDDs skip this check.

If any check fails, ABORT (no fix-and-retry — the skill validates then writes
in a single pass; repair is the calling agent's responsibility):

```
Error: validation failed: {field/section} — {detail}.
```

The calling agent fixes the issue in its own context and re-invokes
`Skill(tdd, "<topic>")`.

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
| `<topic>` missing or empty | Abort: `Error: Usage: Skill(tdd, "<topic>") — describe the artifact in 3-10 words.` |
| Slug empty after sanitization (e.g., all-CJK or all-punct topic) | Abort: `Error: Topic must contain at least one alphanumeric character.` |
| Output file already exists | Run COLLISION_DIALOG; never silently overwrite. On Cancel: `Cancelled — no file written.` |
| Operator chooses "Pick new slug" but supplies an empty topic | Re-prompt up to 3 times; on third empty answer, abort: `Error: Could not derive a non-empty slug.` |
| Validation Before Save fails | Abort with `Error: validation failed: {field/section} — {detail}.` No retry — calling agent re-invokes. |
| Mermaid mandate not satisfied | Abort: `Error: validation failed: Mermaid block missing — TDD requires at least one mermaid fenced block (component map, sequence, state, or data flow). Pure-policy decisions belong in an ADR.` |
| Filesystem write fails (permissions, disk, read-only mount) | Surface raw error: `Error: Write failed — {raw error}.` Do NOT retry. The calling agent reports to the operator. |
