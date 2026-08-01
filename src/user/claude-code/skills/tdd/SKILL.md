---
name: tdd
description: >
  Author a single Technical Design Document at docs/tdd/{slug}.md. Loaded into the
  calling agent's context; the agent drafts the TDD per the format authority below.
  Trigger: "create TDD", "draft TDD", "produce a technical design document", "write the technical design for {feature}".
argument-hint: "<topic>"
allowed-tools: ["AskUserQuestion", "Bash", "Glob", "Grep", "Read", "Write"]
---

<!-- CANONICAL:BANNER:BEGIN -->
> **CRITICAL:** (1) Do NOT commit ANY changes (no `git add`, no `git commit`, no `git push`) unless EXPLICITLY instructed by the user. (2) This is a leaf skill. You MUST NOT spawn sub-agents, invoke `Skill()` recursively, use `Agent()` or `SendMessage`, or form/manage a team. The calling agent handles peer messaging after this skill returns.
<!-- CANONICAL:BANNER:END -->

# TDD — Author a Technical Design Document

You are the **TDD Author**: produce a single Technical Design Document at `docs/tdd/{slug}.md` and return. The calling agent drafts the content — `@distinguished-engineer` by default (the capability-bound seat on every TDD-bearing cycle), `@staff-engineer` as the seat-unavailable fallback or standalone author. **Security carve-out:** a security-dominated TDD is authored by `@security-engineer` (`@distinguished-engineer` is categorically barred from security-sensitive work), and `updated_by` is what selects the validator's security track (Required Sections §4, §9). This skill is the format authority — section list, frontmatter contract, output path, collision handling.

> **"TDD" here means Technical Design Document, NOT Test-Driven Development.**

<!-- CANONICAL:DOCS-PATHS-LOCAL:BEGIN -->
**Docs paths (this skill).** Master: `~/.claude/skills/team-doctrine/references/docs-paths.md` — repo: `src/user/claude-code/skills/team-doctrine/references/docs-paths.md`. Writes: `docs/tdd/{slug}.md`. Reads: `docs/spec/` (always singular), `docs/ux/`, `docs/tdd/`.
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

A Technical Design Document for non-trivial work (architecture, system design, multi-step migration, cross-cutting refactor) landing at `docs/tdd/{slug}.md` as the authoritative design record. Pick TDD over PRD when *how* is the question — the what/why is settled and architecture is the open work.

## When NOT to Use

<!-- COUPLING: this skill is part of the doc-authoring family. The "When NOT to Use" delegation routes below MUST stay in sync with src/user/claude-code/skills/prd, adr, and ux-spec — update all 4 in lockstep when adding/removing a sibling skill. `init-specs` is in the doc-authoring family but carries no "When NOT to Use" section, so it is outside this particular sync. -->
- Inline advisory replies, review comments, scratch notes, or one-off sketches not meant to live at `docs/tdd/`.
- Architecture Decision Records (single decisions): `Skill(adr, "<topic>")`.
- Product Requirements Documents (feature-level specs): `Skill(prd, "<topic>")`.
- UX / design specs: `Skill(ux-spec, "<topic>")` — when a TDD touches a user-facing surface, the interaction-design portions belong in the UX spec; the TDD references it rather than restating it.
- Project-wide engineering specs: owned by `init-specs`.

## Pre-flight

1. **Run `Bash ~/.claude/scripts/doc_preflight.sh tdd "<topic>"`** — single-homes slug derivation, date/project context, the collision check, and the near-duplicate prefix probe. Parse its stdout: `{slug}`, `{today_date}`, `{project_name}`, `{exact_path_collision}`, `{near_dups}`; on non-zero exit, surface its stderr and ABORT. Both collision fields are tri-state — a real path, empty (checked, no hit), or a `SKIPPED: docs/tdd absent` sentinel (fresh repo or between ephemerality cleanups) — never collapse the sentinel into "no collision". `{output_path}` = `docs/tdd/{slug}.md`; `{output_dir}` = `docs/tdd/`; TDD filenames are never number-prefixed (`next_doc_number.sh` is adr's step, not this skill's). `{updated_by}` = the calling agent's identifier.
2. **Collision**: if `{exact_path_collision}` is a real path, run the COLLISION_DIALOG below; a `SKIPPED:` sentinel means nothing to collide with — proceed.
3. **Near-duplicate probe** (advisory): a non-empty, non-`SKIPPED:` `{near_dups}` surfaces one line — `Near-duplicate TDD(s) detected: {near_dups}. Proceed only if this is intentionally distinct work.` — and the calling agent decides; no automatic block.

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

4. **Related-doc probe**: `Glob docs/spec/*.md docs/ux/*.md`; matches whose slug appears in `<topic>` (case-insensitive) join the `dependencies` frontmatter array.

## Authoring Procedure

1. **Gather prior art**: `Grep -r "{topic-keywords}" docs/`, read any candidate parent PRD or UX spec from Pre-flight §4 and adjacent existing TDDs — reference, not contradict, prior accepted work.
2. **Draft the frontmatter** per the contract below (`status: "draft"` initially), then **each Required Section in order**. Sections marked "may be N/A" (§5, §6) may contain a single `N/A.` paragraph with a one-line justification; the chosen alternative in §3 must match §4. Co-author hazard: when `@security-engineer` appends the security sections to another agent's draft, the appending agent re-Reads fresh immediately before editing (on "File modified since read", re-Read and diff, never blind-retry), and the hand-off sequences through team-lead — sole-editor authority: `security-engineer.md` §Responsibility 1.
3. **Mermaid**: at least one ```` ```mermaid ```` (lowercase, no space) fenced block whose FIRST non-blank line starts with a diagram-type keyword (`flowchart`/`graph`, `sequenceDiagram`, `stateDiagram-v2`, `erDiagram`, `C4Context`, …) — a semantic label or leading `%%` comment fails the validator.
4. **Verify embedded technical assertions before stating them as fact**, per the authoring verification gates (`~/.claude/skills/team-doctrine/references/authoring-verification-gates.md`): execute what claims to be executable, derive enumerated sets by grep with the command and count recorded, Read a test's assertion body before asserting what it covers (corroboration is not verification), check insertion anchors for `CANONICAL:` block membership, and make every inline-backtick path resolve on disk. State any claim you could not verify explicitly as an assumption; a claim that feeds a Risk row (§8) or a phase AC (§11) must be verified (command run / artifact read), never assumed — an unverified claim a reviewer later falsifies invalidates every row and AC built on it. **Revision drafts** (answering review/panel findings) additionally bind the post-findings class sweep (same master): generalize each finding to its mistake class and sweep the ENTIRE document for sibling instances — every previously-verified claim re-checked against current ground truth — recording each class, sweep command, and disposition in the revision report; an instance-only fix is reject-class.
5. **Proceed to Validation Before Save.**

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

Field rules: `project` = `basename $(git rev-parse --show-toplevel)`; `maturity` (`proof-of-concept | draft | experimental | stable`) describes how settled the content is, orthogonal to `status` (`draft | questions-resolved | in-review | accepted | superseded`), which tracks the review-and-vote lifecycle — `accepted` is the terminal working state and the file itself stays ephemeral (deletable after its cycle's implementation completes). `last_updated` is `YYYY-MM-DD`. **`updated_by` names the agent whose TRACK the document must validate against — not whoever edited last:** when `@security-engineer` appends the security sections, set `updated_by: "@security-engineer"`; `doc_validate.py` fires the security-track checks on exact equality with that value, so leaving the body author's identifier silently skips them. `dependencies` is a YAML array of related-file paths (`[]` if none).

### Required Sections

`##` headings carrying the section title ONLY — list numbers are NOT part of the heading (`## Problem Statement`, never `## 1. Problem Statement`); the validator matches heading text exactly, in this order:

1. **Problem Statement** — what, why now, who is affected, constraints, non-goals (stated affirmatively — a goals-only framing is advocacy, not design), acceptance criteria, business context.
2. **Context & Prior Art** — existing patterns in this repo and outside; how this work fits.
3. **Alternatives Considered** — at least two `###` subsections; shape, strengths, weaknesses, verdict per alternative.
4. **Architecture & System Design** — the chosen approach. **Security TDDs** (`updated_by` = `@security-engineer`) MUST include three `###` subsections — `Threat Model`, `Trust Boundaries`, `Security Considerations` (validator-enforced); non-security TDDs may omit them.
5. **Data Models & Storage** — schemas, persistence, migrations. May be `N/A.` + one line.
6. **API Contracts** — request/response shapes, RPC contracts, CLI invocation shapes. May be `N/A.` + one line.
7. **Migration & Rollout** — current state, target state, sequencing, backward compatibility, rollback plan.
8. **Risks & Open Questions** — risk table (likelihood/impact/mitigation); open questions resolved or escalated before vote.
9. **Testing Strategy** — test levels, smoke tests, AC coverage, and an **untested-claims inventory**: every forward-looking or currently-unreachable branch with no Phase-1 trigger (dead-on-arrival arms, future-flag paths, defensive fallbacks). When an AC would demand a positive test for an unreachable branch, do NOT fabricate one — extract the branch's shape-builder into an exported pure function, unit-test THAT, and record the deferred end-to-end coverage as a known gap. **Security TDDs** MUST include a `### Abuse Cases` subsection enumerating adversarial-input tests.
10. **Observability & Operational Readiness** — signals, 3am diagnosability, production readiness, runbooks.
11. **Implementation Phases** — partitioned phases the planner consumes directly. Each phase specifies: (a) one-line goal, (b) file scope, (c) per-phase acceptance criteria — a grep/regex AC embeds the exact command and its expected hit count (run it; the count is the evidence); a MEASURED or RENDERED value (timing, byte/pixel size, sampled count) uses a tolerance band, never exact-match (exact ACs on non-deterministic values fail intermittently); an AC whose meaning depends on specific source text quotes that text verbatim inline — every downstream hop paraphrases, and a paraphrase silently drops the sentence the AC tests, (d) effort estimate (S/M/L), (e) blocking dependencies, (f) explicit out-of-scope flags, (g) stand-alone interpretability when copied verbatim into a Docket issue — restate load-bearing contracts inline ("see §4" is not distillable). Phases are independently shippable or explicitly chained.

## Validation Before Save

The full checklist — frontmatter contract, `status` allow-list, section order, the Alternatives minimum, Mermaid presence & shape, placeholder scan, and the `updated_by`-conditional security-track subsections — is mechanized by `doc_validate.py`, the single source of truth. Before the final `mv`:

1. **Stage the draft.** Resolve the staging dir first: `Bash echo "${TMPDIR:-/tmp}"` → `{staging_dir}` (an absolute path — `Write`/`Read` take literal paths and never expand `$TMPDIR`). `Write` the complete draft to `{staging_dir}/{slug}.md`.
2. **Run** `Bash python3 ~/.claude/scripts/doc_validate.py --type tdd "{staging_dir}/{slug}.md"` — the same resolved `{staging_dir}`, and always via `python3` (a deployed copy that lost its executable bit exits 126, which no branch below handles).
3. **Exit codes:** **0** → proceed to Save & Return. **1** → ABORT quoting the script's stderr (`Error: validation failed: {field/section} — {detail}.`) — no fix-and-retry; the calling agent re-invokes. **2** → ABORT with `Error: validator unavailable: {stderr}` so the caller escalates infrastructure, not the draft.
4. **Author-side citation pre-check.** `Bash ~/.claude/scripts/tdd_preflight.sh "{staging_dir}/{slug}.md"` (append ` {companion.md}` when a companion ADR/TDD exists) — chains path-existence checking with numbered-cross-reference reconciliation; the SAME gate the acceptance panel re-runs post-Write, so running it here converts a rejection into a pre-Write repair. Advisory: classify each `MISSING` hit as target-state (post-move path — expected), glob-literal, or genuinely-broken; repair only the genuinely-broken.

Meta-TDD caveat: the placeholder scan exempts only fenced blocks — a TDD documenting a doc-authoring skill puts path templates inside a fence or uses angle-bracket phrasing (`<slug>`).

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

A failed `mv` (permissions, disk, cross-device) surfaces the raw error — `Error: mv failed — {raw error}.` — with no retry. Planning-phase consumers copy this TDD's committed values verbatim into issue bodies and briefs with provenance annotations; post-planning phases operate exclusively from those distilled copies (the TDD is ephemeral). Any prescribed `Skill(verify-ac)` is an EXPLICIT invocation, not a teammate-frontmatter assumption (teammates load only `tools`+`model`).
