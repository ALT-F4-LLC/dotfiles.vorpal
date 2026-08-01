---
name: code-review-verdict
description: >
  Conduct a code review on a scoped artifact (PR, branch, uncommitted, staged, or files).
  Loaded into the calling agent's context; the calling agent applies the role-appropriate
  playbook — @staff-engineer or @distinguished-engineer (the Medium+ general-review advisor
  seat) runs the 6-dimension general review, @security-engineer runs the security-dimension
  review. The format authority for all three roles' output lives here.
  NOT the bundled /code-review skill (which can edit the working tree via --fix); this project
  skill was renamed away from "code-review" to avoid that collision. Emits a structured verdict
  into the calling agent's context only — it does NOT post to the PR; to post findings as inline
  PR comments in the operator's voice use Skill(review-and-comment).
  Trigger: "code review", "review this PR", "review the diff", "security review of changes".
argument-hint: "<scope — PR#, branch, uncommitted, staged, or path [path …]>"
allowed-tools: ["AskUserQuestion", "Bash", "Glob", "Grep", "Read", "Monitor"]
---

<!-- CANONICAL:BANNER:BEGIN -->
> **CRITICAL:** (1) Do NOT commit ANY changes (no `git add`, no `git commit`, no `git push`) unless EXPLICITLY instructed by the user. (2) This is a leaf skill. You MUST NOT spawn sub-agents, invoke `Skill()` recursively, use `Agent()` or `SendMessage`, or form/manage a team. The calling agent handles peer messaging and consensus follow-ups after this skill returns.
<!-- CANONICAL:BANNER:END -->

# Code Review Verdict — Conduct a Role-Scoped Review

You are the **Reviewer**. Conduct a code review on the artifact named by `<scope>` and emit a structured report into the calling agent's context — no file is written. The format authority (dimensions, severity ladders, output sections, validation rules) lives here.

<!-- CANONICAL:DOCS-PATHS-LOCAL:BEGIN -->
**Docs paths (this skill).** Master: `~/.claude/skills/team-doctrine/references/docs-paths.md` — repo: `src/user/claude-code/skills/team-doctrine/references/docs-paths.md`. Writes: none. Reads: `docs/spec/` (always singular), `docs/adr/`, `docs/ux/`, the Docket issue body + comments (distilled contracts + ACs per the Distillation Gate); `docs/tdd/` is ephemeral — never a required input.
<!-- CANONICAL:DOCS-PATHS-LOCAL:END -->

## Role Detection

Callable ONLY by `@staff-engineer`, `@distinguished-engineer`, or `@security-engineer`; `{role}` is the calling agent's identifier minus the `@`. Any other caller ABORTS:

```
Error: Skill(code-review-verdict) is restricted to @staff-engineer, @distinguished-engineer, and @security-engineer. Calling agent: {agent}.
```

## Argument Handling

The argument is a single positional `<scope>` (free-text; extra positional args are ignored). Scope for this invocation: $ARGUMENTS.

If `<scope>` is missing or empty:

```
Error: Usage: Skill(code-review-verdict, "<scope>") — name what to review (PR number/URL, branch, "uncommitted", "staged", or file paths).
```

**Scope resolution** (apply rules in order; first match wins):

<!-- COUPLING: scope-resolution — this table's Branch name, Literal `uncommitted`, Literal `staged`, and File paths rows are BYTE-IDENTICAL to the same four rows in `src/user/claude-code/skills/verify-ac/SKILL.md`'s scope-resolution table; the branch-vs-file `./`-prefix ambiguity bullet below is near-identical. Keep both files in sync when either changes (DKT-250). -->
| Form | Detection | Diff source |
|---|---|---|
| GitHub PR number | matches `^\d+$` | `gh pr view {n}` (description) + `gh pr diff {n}` (diff) |
| GitHub PR URL | contains `/pull/` | extract `n`; same as PR number |
| Branch name | `git rev-parse --verify {scope}` exits 0 | `git diff main...{scope}` + `git log main...{scope} --oneline` + `git diff --stat main...{scope}` |
| Literal `uncommitted` | exact match | `git status --short` (surfaces untracked `??`) + `git diff` + `git diff --staged` + `git diff --stat HEAD` |
| Literal `staged` | exact match | `git diff --staged` + `git diff --stat --staged` |
| File paths (one or more, space-separated) | every token resolves via `Bash test -e {path}` | `Read` each file directly |

**Path-list normalization.** The canonical multi-file form is bare space-separated paths. Before applying the table, strip a leading `files`/`files:` keyword, then split on commas and/or whitespace; resolve the tokens via the File paths row.

**Ambiguity rules:**

- A token matching `^\d+$` always tries PR-number first via `gh pr view {n} --json number`; on failure fall through to branch, then file-path detection. If the `gh` CLI itself is unavailable for a PR scope, abort: `Error: gh CLI required to resolve PR scope. Re-invoke with the branch name or "uncommitted".`
- A single token that is BOTH a valid branch name AND an existing file is treated as a branch. To force file-path scope on such a name, supply multiple tokens or prefix with `./` (e.g., `./main`).

If `<scope>` matches none of the above, ABORT:

```
Error: Could not resolve <scope>: '{scope}'. Expected PR number/URL, branch name, "uncommitted", "staged", or existing file paths.
```

## When to Use

Any role-scoped code review at any scope — including the dominant call pattern, fix→re-review loops on the same scope: re-invocations emit the compact §Round-N format, not a fresh full sweep, unless new code introduces new risk.

## Doubling Rule

Panel sizing, opt-up triggers, ephemeral lifecycle, and verdict reconciliation are owned by `~/.claude/agents/team-lead.md` Rule 8 / Rule 7 / step 14. Skill-specific delta only:

- **Seats (general track)**: single (default) = persistent `advisor`, verdict final; doubled adds one ephemeral `reviewer-2` only on a Rule 8 opt-up trigger.
- **Seats (security track)**: `security-advisor` + one ephemeral `security-reviewer-2` is an INDEPENDENT DEFAULT whenever the diff touches a security-sensitive surface — never an opt-up, and it does not force-double the general track.
- **Independent emission**: each reviewer invokes this skill and emits its own report — this skill is the single-reviewer format authority, never the panel-reconciliation authority.

## When NOT to Use

<!-- COUPLING: this skill is part of the report-emission family (code-review-verdict, verify-ac, design-qa, design-review) — update all 4 in lockstep when adding/removing a sibling skill. -->
- Authoring TDDs, ADRs, PRDs, or UX specs — `Skill(tdd)`, `Skill(adr)`, `Skill(prd)`, `Skill(ux-spec)`.
- Multi-agent consensus voting — `Skill(vote)`; after this skill produces a review, the calling agent decides whether a vote-criticality trigger applies.
- Acceptance-criteria verification against a Docket issue — `Skill(verify-ac)` (@sdet).
- Design QA of shipped user-facing surfaces — `Skill(design-qa)`; peer review of a draft UX spec — `Skill(design-review)` (@ux-designer).

## Pre-flight

1. **Detect role**; ABORT if invalid. `@staff-engineer`/`@distinguished-engineer` → general playbook + `references/output-general.md`; `@security-engineer` → security playbook + `references/output-security.md`. The general banner `## Review (general — @staff-engineer)` is a fixed TRACK literal (the validator recognizes only that exact banner) — a `@distinguished-engineer` caller emits it VERBATIM; author identity rides the delivering SendMessage, not the banner.
2. **Resolve `<scope>`**; ABORT if unresolvable.
3. **Gather artifact context** per the resolved scope's diff source. Capture the file list (`git diff --stat`, plus `git status --short` on `uncommitted`/`staged` to surface untracked `??`) before reading bodies — this drives triage and the citation-presence check. Run `audit_snapshot.sh` for a dependency snapshot if present (repo-root `.claude/scripts/` copy first, `~/.claude/scripts/` fallback); a missing script is N/A, never fatal. If the file count exceeds 50, surface a one-line summary first (`{N} files, {lines} lines — recommend Split required unless author confirms cohesive scope`).
4. **Empty-diff guard**: if the resolved diff is empty, ABORT: `Error: Resolved scope produced an empty diff — nothing to review.`
5. **Snapshot-tree guard** (`uncommitted`/`staged` scopes only): a working-tree diff is a point-in-time snapshot. Under team-lead orchestration, do not proceed unless the calling agent holds an implementation-complete signal (team-lead GO, no open `blockedBy`; when the context names Docket issue IDs, confirm each is closed) — else ABORT: `Error: moving tree — implementation not signalled complete; re-invoke after team-lead GO.` (Reviews have fired before implementers finished; this gate is the backstop.) Standalone, prefix the verdict with: `Reviewed local working tree at this point in time — N files present; confirm implementation is signalled-complete before this verdict binds`.
6. **Read related design docs**, scoped to what the diff touches: general → the issue's distilled contracts + matching `docs/spec/` files; security → distilled security contracts + `docs/adr/` security records + `docs/spec/security.md`.

## Review Procedure

**Triage governs effort ORDER, never what gets reported.** Trivial changes (typo, stable version bump, cosmetic diff) get the one-line LGTM form. Substantive changes get the full dimension sweep; on 500+ line diffs, start with the 20% of code carrying 80% of the risk and recommend a split when scope mixes independent concerns — but every finding found anywhere in the diff is still reported.

**Report every finding — do NOT self-filter.** Report each issue you find, including low-severity and uncertain ones, tagged with severity (classification, not suppression) and a confidence note. Filtering and ranking happen downstream (team-lead step-14 reconciliation / operator), never here — declining to report a found issue because it seems minor is a recall defect. A finding a linter would also catch is reported as `Suggestion` (general) / `Info` (security), not omitted.

**Honest critique.** Do not default to approval; a surface fix that masks root cause is reject-class. If the proper fix is out of scope, recommend a follow-up issue rather than approving the patch. When intent is genuinely ambiguous and the answer is not in the code, ask (standalone: `AskUserQuestion`; team mode: route through the calling agent). For builds/tests/scans expected to take >30s, use `Monitor` with a terminal-pattern filter rather than a blocking poll.

**Evidence.** Every load-bearing finding cites evidence (file:line, command output, spec section); banned confidence phrases in findings/praise/recommendations: "clearly," "obviously," "should work," "definitely," "100%," "guaranteed" — say what was checked vs. assumed, and mark the unverified as "unverified — assumption". Source each per-file finding only from that file's real diff rendered this turn; before resting a claim on a test result, empty diff, green CI, or any probe you built or ran, read `references/evidence-gates.md` (the ways those signals lie, plus the anti-fabrication sourcing rules). Probe-sourced Critical/High/Blocker findings cite their positive control per `references/evidence-gates.md` — a missing citation is a FORMAT defect routed back for a control run, never an override-on-merits.

### General playbook (@staff-engineer / @distinguished-engineer)

Apply the **6 dimensions**, weighted by what the change touches; mark unaffected ones `N/A`:

1. **Architecture** — pattern fit, module boundaries, dependency direction, second-order effects, precedent set.
2. **Security (general posture)** — input boundaries, error-path safety, default-deny defaults, accidental privilege escalation. Auth/secret/crypto/sandbox specifics defer to a parallel `@security-engineer` review when one is running; otherwise flag as a Concern with Next Steps routing a dedicated security pass.
3. **Operations** — observability hooks, runbook impact, deploy/rollback story, 3am-diagnosability. An emitted field that is initialized and emitted but never mutated is a Concern (Blocker only if AC-gated): an always-empty stub a consumer cannot distinguish from a real zero.
4. **Performance** — algorithmic complexity, N+1 patterns, allocation hotspots, regression risk.
5. **Code Quality** — the 12 code-philosophy principles per `~/.claude/agents/senior-engineer.md` → Code Quality & Craftsmanship (format authority). Principles #4/#5/#6/#11 carry the mechanical Hard Gates below; the other eight belong to the Concern/Suggestion rubric.
6. **Testing** — coverage of acceptance criteria, edge cases, regressions, what's untested and why (test *quality* lives under principle #8).

**Severity ladder (general)**:

| Severity | Meaning |
|---|---|
| Blocker | Must fix before merge: data loss, breaking change without migration, critical missing test on a privileged path |
| Concern | Should fix or explicitly justify: pattern violation, missing edge case, test gap on a non-critical path |
| Suggestion | Consider for this or future work: better approach, minor improvement |
| Question | Need clarification to complete the review |
| Praise | Pattern worth highlighting |

### Security playbook (@security-engineer)

Apply the **9 security dimensions**, weighted by what the change touches; mark unaffected ones `N/A`: Authn/Authz; Input validation & encoding; Secret handling; Cryptography; Trust boundaries; Supply chain; Sandbox/isolation; Logging/observability (PII/secret leakage, audit-trail completeness); Denial of service (unbounded allocations, regex backtracking, retry storms).

**Severity ladder (security)**:

| Severity | Meaning |
|---|---|
| Critical | Exploitable now: auth bypass, secret exposure, RCE, data corruption — MUST fix before merge or revert if shipped |
| High | Material weakening of posture — fix before merge or get explicit risk acceptance |
| Medium | Real concern with workaround or low likelihood — fix or justify |
| Low | Defense-in-depth opportunity — consider |
| Info | Educational note or pattern to highlight |

### Hard Gates (Blocker-class general / Critical security)

Five narrow, mechanically detectable symptoms gate the merge regardless of feature correctness — **G1** swallowed error, **G2** unguarded shared mutation, **G3** unparsed boundary input, **G4** surface-not-invariant patch, **G5** unexecuted AC regex (run `~/.claude/scripts/g5_check.sh <scope>` whenever the diff edits regex in `docs/tdd/` or `docs/spec/`). Full symptom patterns, counter-examples, and the override-recognition procedure are in `references/hard-gates.md` — read it before emitting or dismissing any gate finding. An `OVERRIDE: code-philosophy/<id>` comment at the site suppresses the Blocker and is listed verbatim under **Overrides Recognized** instead — surfaced for the operator, never silently honored.

## Output Contract

Emit the review verbatim per the role's template — `references/output-general.md` or `references/output-security.md` (read the one selected at Pre-flight step 1). Do not echo the raw diff, save to disk, or add prose outside the format. If the harness blocks this skill's invocation, render the review directly per the same template — never an improvised structure.

### Round-N Re-Review (compact)

On re-invocation against a fixed diff, skip the full template: emit `## Re-Review Round-{N} ({role})` with three sections — **Prior Findings Disposition** (one row per prior Blocker/Concern/Critical/High → `resolved | outstanding | regressed` + evidence), **New Findings (delta only)** (by severity, or "None"), **Recommendation** (role allow-list value) — ending with the trailing confirmation line. Revert to the full template if the fix introduces a new Blocker/Critical.

**G5 carry-forward.** A prior-round G5 PASS is reusable without re-running the regex ONLY when `~/.claude/scripts/verify_carry_forward.sh <prior-round Tree state> <current fingerprint> <AC-regex file> <target file …>` reports `[CARRY-FORWARD]` for EVERY path (compute `<current fingerprint>` as `git rev-parse --short HEAD` plus `+dirty:<sha12>` from `~/.claude/scripts/tree_fingerprint.sh` when dirty). Cite as `G5 PASS — unchanged since round {N}`. Any `[RE-VERIFY]` line means re-run the regex; never carry a prior G5 Blocker forward.

## Validation Before Emit

Stage and lint the draft in a SINGLE Bash call — shell state (including `$$` and computed temp paths) does not persist between Bash calls, so never split staging from linting:

```
~/.claude/scripts/report_stage_lint.sh code-review-verdict [--mode round-n] "$DRAFT_FILE"
```

(or pipe the body on stdin). Exit codes:

- **0** — emit the review in the calling agent's context.
- **1 (validation failure)** — ABORT; the calling agent corrects (quoting the script's stderr) and re-invokes: `Error: validation failed: {section/field} — {detail}.`
- **2 (infra/usage)** — do NOT hard-block: emit the review with the annotation line `lint not run (infra: {reason})` appended after the trailing confirmation line, and flag the infra failure to the caller.

The validator mechanizes the text-decidable checks (banner, section order, ladders, explicit empty buckets, allow-list recommendation, trailing line, placeholder and banned-phrase scans, hard-gate cross-listing and G1..G5 enumeration). Two checks stay yours — they need diff state the review text does not carry:

- **Override verbatim-match** — an `OVERRIDE` present in the diff for a gated symptom MUST appear in `Overrides Recognized` (verbatim + file:line) and must NOT also appear as a Blocker for the same gate.
- **Citation presence** — every `file:line` cited in a Finding must name a path in the scope's file list (Pre-flight step 3); a cited path absent from that list is a fabricated-verification defect — re-derive it from the real diff or drop it and say so.

## Save & Return

End with the confirmation line:

```
Code review emitted ({recommendation}).
```

The in-context emission is the working artifact; the deliverable is the calling agent's same-turn SendMessage of the structured verdict — under team-lead orchestration to team-lead (who reconciles parallel verdicts per step 14: any Blocker blocks, the security verdict binds for security findings; do not pre-align with the counterpart reviewer before delivery), standalone to whoever requested the review. Blockers/Criticals ride in the verdict body — team-lead routes them to the fix ephemeral; standalone, SendMessage `@senior-engineer` with file/finding/fix triplets. Escalating to a vote (500+ lines, security-critical surface, breaking-change plan, residual-risk acceptance): standalone `Skill(vote)`; team mode never `Skill(vote)` — `docket vote create` + `delegation_request` to team-lead, passing structured Findings as `--findings-json` and mapping the Recommendation per this table:

| This skill's Recommendation | Vote verdict (for `docket vote cast -v`) |
|---|---|
| Approve / Approve (security) | `approve` |
| Approve with follow-up | `approve-with-concerns` |
| Request changes | `approve-with-concerns` (with explicit Concerns in findings) |
| Block / Block (security) | `reject` |
| Split required | Do NOT escalate to vote — return Split-required and let the caller re-scope first |
