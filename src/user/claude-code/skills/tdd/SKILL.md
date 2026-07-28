---
name: tdd
description: >
  Author a single Technical Design Document at docs/tdd/{slug}.md. Loaded into the
  calling agent's context; the agent drafts the TDD per the format authority below.
  Trigger: "create TDD", "draft TDD", "produce a technical design document", "write the technical design for {feature}".
argument-hint: "<topic>"
allowed-tools: ["AskUserQuestion", "Bash", "Glob", "Grep", "Read", "Write"]
effort: xhigh
---

<!-- CANONICAL:BANNER:BEGIN -->
> **CRITICAL:** (1) Do NOT commit ANY changes (no `git add`, no `git commit`, no `git push`) unless EXPLICITLY instructed by the user. (2) This is a leaf skill. You MUST NOT spawn sub-agents, invoke `Skill()` recursively, use `Agent()` or `SendMessage`, or form/manage a team. The calling agent handles peer messaging after this skill returns.
<!-- CANONICAL:BANNER:END -->

# TDD — Author a Technical Design Document

You are the **TDD Author**. You produce a single Technical Design Document at
`docs/tdd/{slug}.md` and return. The calling agent drafts the content —
`@distinguished-engineer` by DEFAULT (TDDs exist only on Medium+/TDD-bearing
cycles, and that seat is gold on every such cycle), with `@staff-engineer` as the
gold-unavailable fallback author or in standalone use. **Security carve-out:** a
security-dominated TDD is authored by `@security-engineer`; `@distinguished-engineer`
is categorically barred from security-sensitive work (`distinguished-engineer.md`
§Security Exclusion), and `updated_by` is what selects the validator's security
track (Required Sections §4, §9). This skill is the format authority — section
list, frontmatter contract, output path, and collision handling all live here.

> **Note — "TDD" here means Technical Design Document, NOT Test-Driven Development.**

<!-- CANONICAL:DOCS-PATHS-LOCAL:BEGIN -->
**Docs paths (this skill).** Master: `~/.claude/skills/team-doctrine/references/docs-paths.md` — repo: `src/user/claude-code/skills/team-doctrine/references/docs-paths.md` (maintained copy).
- Writes: `docs/tdd/{slug}.md`.
- Reads: `docs/spec/`, `docs/ux/`, `docs/tdd/`.
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

- A Technical Design Document is needed for non-trivial work (architecture, system
  design, multi-step migration, cross-cutting refactor) and should land at
  `docs/tdd/{slug}.md` as the authoritative design record. Pick TDD over PRD when
  *how* is the question — the what/why is settled and architecture is the open work
  (the inverse of prd's "scope precedes architecture" boundary).
- The calling agent (author attribution per the contract paragraph above) is
  producing a design that needs to go through the `status` lifecycle (see
  Required Frontmatter).
- The team-lead orchestrator's Medium Task pattern asks for a TDD without a separate
  PRD — this skill is the canonical path.

## When NOT to Use

<!-- COUPLING: this skill is part of the doc-authoring family. The "When NOT to Use" delegation routes below MUST stay in sync with src/user/claude-code/skills/prd, adr, ux-spec, and init-specs — update all 5 in lockstep when adding/removing a sibling skill. -->
- Inline advisory replies, review comments, scratch notes, or one-off design
  sketches that are not meant to live at `docs/tdd/`.
- Architecture Decision Records (single decisions): use `Skill(adr, "<topic>")`.
- Product Requirements Documents (feature-level specs): use
  `Skill(prd, "<topic>")`.
- UX / design specs: use `Skill(ux-spec, "<topic>")`. When a TDD touches a user-facing surface, the interaction-design portions belong in the UX spec; the TDD references it (per Pre-flight §4 + Authoring §1) rather than restating it.
- Project-wide engineering specs (architecture, security, operations, performance,
  code-quality, review-strategy, testing): owned by the `init-specs` skill.

## Pre-flight

1. **Run `Bash ~/.claude/scripts/doc_preflight.sh tdd "<topic>"`** (repo: `src/user/claude-code/scripts/doc_preflight.sh`)
   — single-homes slug derivation, date/project context, the collision check, and
   the near-duplicate prefix probe (DKT-167; matches the `evolve_preflight.sh`
   KEY=value convention). Parse its stdout: `{slug}`, `{today_date}`,
   `{project_name}`, `{exact_path_collision}`, `{near_dups}`. On non-zero exit,
   surface its stderr and ABORT (it propagates `slug.sh`'s own errors verbatim).
   Both `{exact_path_collision}` and `{near_dups}` are tri-state — a real path,
   empty (checked, no hit), or a `SKIPPED: docs/tdd absent` sentinel when the
   directory doesn't exist yet (a fresh repo, or between TDD-ephemerality
   cleanups) — never collapse the sentinel into "no collision".
   - `{output_path}` = `docs/tdd/{slug}.md`. `{output_dir}` = `docs/tdd/`. **No
     numbering step** — unlike `docs/adr/{NNNN}-{slug}.md`, TDD filenames are never
     number-prefixed (docs-paths.md master, `docs/tdd/` row);
     `~/.claude/scripts/next_doc_number.sh` (repo: `src/user/claude-code/scripts/next_doc_number.sh`)
     is `src/user/claude-code/skills/adr/SKILL.md`'s numbering step, not this
     skill's — do not invoke it here.
   - `{updated_by}` = the calling agent's identifier (e.g., `@staff-engineer`).
2. **Check collision**: if `{exact_path_collision}` is a real path (not empty,
   not a `SKIPPED:` sentinel), run the COLLISION_DIALOG below (`{exact_path_collision}`
   is `{output_path}`). A `SKIPPED:` sentinel means `docs/tdd/` doesn't exist yet —
   there is nothing to collide with; proceed directly to Authoring.
3. **Near-duplicate probe** (advisory, non-blocking): if `{near_dups}` is a
   non-empty, non-`SKIPPED:` value, surface it to the calling agent context as a
   one-line note: `Near-duplicate TDD(s) detected: {near_dups}. Proceed only if
   this is intentionally distinct work.` The calling agent decides whether to
   continue or re-derive a more specific slug; no automatic block. This catches
   near-identical args (different punctuation, suffix words) that derive to
   different but adjacent slugs. A `SKIPPED:` sentinel or an empty value need no
   further action.

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

4. **Related-doc probe**: `Glob docs/spec/*.md docs/ux/*.md`. For each match
   whose slug appears as a substring of `<topic>` (case-insensitive), include
   its relative path in the `dependencies` frontmatter array. The calling
   agent may add others from broader judgment.

## Authoring Procedure

1. **Gather prior art**: `Grep -r "{topic-keywords}" docs/` and read any candidate
   parent PRD or UX spec identified in Pre-flight step 4. Read existing TDDs in
   `docs/tdd/` touching adjacent areas — reference, not contradict, prior accepted work.
2. **Draft the frontmatter** per the Required Frontmatter contract below. Set
   `status: "draft"` initially.
3. **Draft each Required Section in order** (see Output Contract → Required
   Sections). Every section listed MUST appear, in the order shown. Sections
   marked "may be N/A" (Data Models §5, API Contracts §6) may contain a single
   `N/A.` paragraph with a one-line justification. The chosen alternative in §3
   must match the Architecture & System Design section (§4).

   **Authoring hazard — co-author serialization.** When two agents co-author one TDD
   (e.g., `@staff-engineer` drafts the body and `@security-engineer` appends the
   Threat Model / Trust Boundaries / Security Considerations sections), the prose
   hand-off does not serialize anything — the file-global modified-since-read gate is
   the real primitive, so the appending agent re-Reads fresh immediately before
   editing and, on a "File modified since read" error, re-Reads and diffs rather than
   blind-retrying. Sequence the hand-off through team-lead, not async peer messages;
   the sole-editor protocol authority is `security-engineer.md` §Responsibility 1
   (Threat-Model Annotation).
4. **Mermaid diagrams**: produce at least one ` ```mermaid ` (lowercase, no space)
   fenced block — component map, sequence, state, or data flow. The block's FIRST
   non-blank line MUST start with a Mermaid diagram-type keyword (`flowchart`/`graph`,
   `sequenceDiagram`, `stateDiagram-v2`, `erDiagram`, `C4Context`, …); the semantic
   label is not a keyword, so a block opening `component map: …` fails the validator's
   `mermaid` check, and a leading `%%` comment line fails it too.
5. **Verify embedded technical assertions before stating them as fact.** For each
   concrete claim the TDD commits to, apply the matching check arm and record the
   artifact or command behind it. A "verified" label must not over-claim scope.
   Label each load-bearing claim OBSERVED (you ran the command / read the artifact)
   or INFERRED (reasoning only); a claim that feeds a Risk row (§8) or a phase AC
   (§11) MUST be OBSERVED, not asserted as fact — an unverified claim a reviewer
   later falsifies invalidates every row and AC built on it.
   - **Snippet / command**: execute it; record the exit code or an output excerpt.
   - **Portability claim** (cross-platform, cross-engine, cross-dialect SQL): test
     each declared target — "valid in both X and Y" requires a run in both (see
     staff-engineer.md's Executable-claim gate, rule 6, for the SQL-dialect rule).
   - **Line-budget / size claim**: measure with `wc -l` or `sed -n`; never estimate.
   - **Concrete value** (image tag, count, path, flag, version) the TDD asserts as
     fact: `Grep` the committed artifact that owns it and confirm they match — a tag
     vs. the workflow's pin, a diagram count vs. the assets actually referenced.
   - **Module / API / test-infra reference**: `Grep` the codebase to confirm the
     target exists and its signature matches before writing it as settled. Existence
     is not coverage — before asserting what a named test ASSERTS, `Read` its
     assertion body; N mutually-citing docs, changelogs, or peer summaries are still
     zero observations (corroboration-is-not-verification, authoring-verification-gates.md).
   - **Enumerated set** stated as complete (every blocking gate, every carrier file,
     every affected call site): derive the members by `Grep` and record the command
     and count — never from memory or a peer's summary. A set asserted complete but
     enumerated partially still reads as authoritative, and silently truncates every
     phase, AC, and Risk row built on it.
   - **Insertion anchor** (a phase that directs an edit relative to a verbatim
     anchor line): before citing the anchor, test its mirrored-block
     membership: `Grep` the target file for `CANONICAL:` markers and check whether
     the anchor falls between a BEGIN/END pair — an anchor line INSIDE a `CANONICAL:*-LOCAL` block
     is synced across sibling files, so an insertion there silently breaks parity.
     Cite a stable anchor OUTSIDE the synced block, or name the whole block as the
     edit unit.
   - **Path citations**: every inline-backtick path the TDD cites must resolve on
     disk — verify with `Grep`/`Read` while drafting. Both the author (pre-Write,
     Validation §4) and the acceptance panel (post-Write) mechanize this via
     `~/.claude/scripts/tdd_preflight.sh` (repo: `src/user/claude-code/scripts/tdd_preflight.sh`);
     see Validation §4 for the run and the `MISSING`-hit classification (target-state,
     glob-literal, or genuinely-broken).
6. **Proceed to Validation Before Save** — the single source of truth for every
   pre-Write check.

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
- `updated_by` is the calling agent identifier (`@staff-engineer`, etc.). **On a co-authored TDD (Authoring §3) it names the agent whose TRACK the document must validate against — not whoever edited last:** when `@security-engineer` appends the Threat Model / Trust Boundaries / Security Considerations sections, set `updated_by: "@security-engineer"`. `doc_validate.py` fires the security-track checks on exact equality with that value, so leaving the body author's identifier in place skips them silently on a document that carries security sections.
- `scope` is a one-line description of what the doc covers — populated by the
  calling agent.
- `owner` is the responsible agent or team handle.
- `dependencies` is a YAML array of related-file paths (relative to the doc); use
  `[]` if none.
- `status` is one of: `draft | questions-resolved | in-review | accepted | superseded`.
  New TDDs start at `draft`. `accepted` is the terminal working state; the file itself
  is ephemeral — safely deletable at any time after its cycle's implementation
  completes (docs-paths.md §Persistence & lifecycle).

### Required Sections

The TDD body MUST contain these top-level sections, in this order. Each is a
`##` heading in the drafted document carrying the section title ONLY — the list
numbers below are NOT part of the heading (`## Problem Statement`, never
`## 1. Problem Statement`). The validator matches heading text exactly.

1. **Problem Statement** — what, why now, who is affected, constraints, non-goals
   (explicit out-of-scope), acceptance criteria, business context. State non-goals
   affirmatively — a goals-only framing is advocacy, not design.
2. **Context & Prior Art** — existing patterns in this repo and outside; how this
   work fits.
3. **Alternatives Considered** — at least two; shape, strengths, weaknesses,
   verdict per alternative.
4. **Architecture & System Design** — the chosen approach, with sub-sections as
   needed (component map, data flow, sequencing, contracts). **For security
   TDDs** (`updated_by` is `@security-engineer`), this section MUST include
   three `###` subsections — `Threat Model`, `Trust Boundaries`, and
   `Security Considerations` — enforced by the validator's `security-subsections`
   check. Non-security TDDs
   may omit them. Mixed-scope co-authoring is owned by
   `src/user/claude-code/agents/security-engineer.md`, not this skill (Authoring §3).
5. **Data Models & Storage** — schemas, persistence, migrations. May be `N/A.`
   with one-line justification if the design has no data plane.
6. **API Contracts** — request/response shapes, RPC contracts, CLI invocation
   shapes. May be `N/A.` with one-line justification.
7. **Migration & Rollout** — current state, target state, rollout sequencing,
   backward compatibility, rollback plan.
8. **Risks & Open Questions** — risk table (likelihood/impact/mitigation); open
   questions resolved or escalated before vote.
9. **Testing Strategy** — test levels, smoke tests, coverage of acceptance
   criteria, and an **untested-claims inventory**: explicitly list every
   forward-looking or currently-unreachable branch the design introduces that
   has no Phase-1 trigger yet (dead-on-arrival arms, future-flag paths,
   defensive fallbacks). When an acceptance criterion would demand a positive
   test for such a branch, do NOT fabricate one against the unreachable path —
   extract the branch's shape-builder into an exported pure function and unit-
   test THAT in isolation; record the deferred end-to-end coverage as a known
   gap. **For security TDDs** (per §4 security-track gating), this section MUST
   include a named subsection `### Abuse Cases` enumerating adversarial-input
   tests, not just happy-path coverage.
10. **Observability & Operational Readiness** — signals, 3am diagnosability,
    production readiness, runbooks.
11. **Implementation Phases** — partitioned phases that the planner consumes
    directly. Each phase MUST specify: (a) one-line phase goal, (b) file scope
    (paths affected), (c) per-phase acceptance criteria — a grep/regex-based AC
   must embed the exact command and its expected hit count (run it; the count is
   the evidence) per Authoring §5 and staff-engineer.md rule 6; for a MEASURED or RENDERED
   value (timing, byte/pixel size, sampled count) use a tolerance band or range,
   NOT exact-match — exact ACs on non-deterministic values fail ~15-20% of runs
   intermittently, while deterministic grep/regex hit counts stay exact; an AC whose meaning depends on
   specific source text ("must state X", "must not say Y") quotes that text verbatim
   inline rather than citing it — every downstream hop (issue distillation, a plan-mode
   `OLD:`/`NEW:` prose summary) paraphrases, and a paraphrase silently drops the
   sentence the AC tests, (d) effort estimate
    (S/M/L), (e) blocking dependencies on other phases, (f) explicit
    out-of-scope flags, (g) each phase must be interpretable stand-alone when
    copied verbatim into a Docket issue — restate any load-bearing contract inline
    rather than pointing at another section ("see §4" is not distillable). Phases
    must be independently shippable or explicitly chained — no implicit ordering.

## Validation Before Save

The full checklist — the frontmatter contract, the `status` allow-list, section
order, the Alternatives-Considered minimum (≥2 `###` subsections), Mermaid presence
& shape, the placeholder scan, and the `updated_by`-conditional security-track
subsections (`Threat Model` / `Trust Boundaries` / `Security Considerations` in §4
and `Abuse Cases` in §9) — is mechanized by the shared `doc_validate.py`, the single
source of truth for what a valid TDD must satisfy. Validate the drafted document
before the final `mv`:

1. **Stage the draft.** First resolve the staging dir: `Bash echo "${TMPDIR:-/tmp}"` —
   stdout is `{staging_dir}`, an absolute path. `Write` and `Read` take a LITERAL path and
   never expand shell variables, so `$TMPDIR/{slug}.md` is treated as a relative
   literal and resolved against the repo root, not the real temp dir. Then `Write` the
   complete drafted content (frontmatter + body) to `{staging_dir}/{slug}.md`.
2. **Run the validator.** `Bash python3 ~/.claude/scripts/doc_validate.py --type tdd "{staging_dir}/{slug}.md"`
   (repo: `src/user/claude-code/scripts/doc_validate.py`) — the same resolved `{staging_dir}`,
   never a re-expanded `$TMPDIR`, so an unset-`TMPDIR` caller validates the file it just
   wrote. Invoke via `python3`, never as a bare executable: a deployed copy that lost its
   executable bit exits 126, which no branch below handles; under `python3` a missing
   validator still exits 2.
3. **Act on the exit code:**
   - **exit 0** — validation passed; proceed to Save & Return (the final `mv` to
     `docs/tdd/...`).
   - **exit 1** — validation failure. ABORT, quoting the script's stderr (no
     fix-and-retry — the skill validates then writes in a single pass; repair is the
     calling agent's responsibility, and it re-invokes `Skill(tdd, "<topic>")`):

     ```
     Error: validation failed: {field/section} — {detail}.
     ```

   - **exit 2** — infrastructure/usage failure (validator missing or staging file
     unreadable). ABORT with a distinct message so the caller escalates the
     infrastructure problem instead of re-drafting:

     ```
     Error: validator unavailable: {stderr}
     ```

4. **Author-side citation pre-check (pre-Write).** On the staged draft, run
   `Bash ~/.claude/scripts/tdd_preflight.sh "{staging_dir}/{slug}.md"` (append ` {companion.md}`
   when a companion ADR/TDD exists) — it chains `check_citations.py` (path existence)
   with numbered-cross-reference reconciliation against the companion. This is the
   SAME gate the acceptance panel re-runs post-Write; running it here converts a
   broken-citation rejection (a full fix-respawn cycle) into a pre-Write repair.
   Advisory, not a hard abort — the checker resolves against the CURRENT tree, so
   classify each `MISSING` hit as target-state (post-move path — expected),
   glob-literal, or genuinely-broken; repair only the genuinely-broken before Save.

**Meta-TDD caveat** — the placeholder scan treats only ``` fenced blocks as exempt,
so a TDD that *documents a doc-authoring skill* and must show path templates should
put them inside a fenced block or use angle-bracket phrasing (`<slug>`,
`<NNNN>-<slug>`). Inline-backtick `{slug}`/`{topic}` literals trip the scan.

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

Planning-phase consumers (PM decomposition, team-lead briefs) copy this TDD's
committed values verbatim into issue bodies and briefs, with file+section provenance
annotations; post-planning phases operate exclusively from those distilled copies
(this TDD is ephemeral — see the `status` frontmatter rule). Any prescribed
`Skill(verify-ac)` is an EXPLICIT invocation, not a teammate-frontmatter assumption
(teammates load only `tools`+`model`).

## Failure Modes

| Trigger | Handling |
|---|---|
| `<topic>` missing or empty | Abort: `Error: Usage: Skill(tdd, "<topic>") — describe the artifact in 3-10 words.` |
| Slug empty after sanitization (e.g., all-CJK or all-punct topic) | Abort: `Error: Topic must contain at least one alphanumeric character.` |
| Output file already exists | Run COLLISION_DIALOG; never silently overwrite. On Cancel: `Cancelled — no file written.` |
| Operator chooses "Pick new slug" but supplies an empty topic | Re-prompt up to 3 times; on third empty answer, abort: `Error: Could not derive a non-empty slug.` |
| Validation Before Save fails | Abort with `Error: validation failed: {field/section} — {detail}.` No retry — calling agent re-invokes. |
| Mermaid mandate not satisfied | Abort: `Error: validation failed: Mermaid block missing — TDD requires at least one mermaid fenced block (component map, sequence, state, or data flow). Pure-policy decisions belong in an ADR.` |
| Filesystem `mv` fails (permissions, disk, read-only mount, cross-device rename) | Surface raw error: `Error: mv failed — {raw error}.` Do NOT retry. The calling agent reports to the operator. |
