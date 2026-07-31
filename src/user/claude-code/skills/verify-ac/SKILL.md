---
name: verify-ac
description: >
  Verify a Docket issue's acceptance criteria against the implementation diff (static, evidence-based — NOT
  runtime app-behavior verification) and emit a structured verification report. Loaded into the calling
  agent's context; the calling agent (`@sdet`) drives verification, the skill enforces the format authority
  — verdict ladder, required sections, validation rules. No file written; the report is emitted into the
  agent's context.
  Trigger: "verify acceptance criteria", "verify Docket issue", "produce verification report" — NOT app/PR runtime checks (that is the bundled runtime `verify` skill, the name this skill was renamed away from to avoid collision).
argument-hint: "<scope>"
allowed-tools: ["AskUserQuestion", "Bash", "Glob", "Grep", "Read", "Monitor"]
---

<!-- CANONICAL:BANNER:BEGIN -->
> **CRITICAL:** (1) Do NOT commit ANY changes (no `git add`, no `git commit`, no `git push`) unless EXPLICITLY instructed by the user. (2) This is a leaf skill. You MUST NOT spawn sub-agents, invoke `Skill()` recursively, use `Agent()` or `SendMessage`, or form/manage a team. The calling agent handles peer messaging and Docket comment/reopen after this skill returns.
<!-- CANONICAL:BANNER:END -->

# Verify-AC — Acceptance-Criteria Verification

You are the **Verifier**. Verify the artifact named by `<scope>` against its acceptance criteria and emit a structured report into the calling agent's context — no file is written. This skill is the format authority: verdict ladder, required sections, severity, validation rules.

<!-- CANONICAL:DOCS-PATHS-LOCAL:BEGIN -->
**Docs paths (this skill).** Master: `~/.claude/skills/team-doctrine/references/docs-paths.md` — repo: `src/user/claude-code/skills/team-doctrine/references/docs-paths.md`. Writes: none. Reads: `docs/ux/`, `docs/spec/` (always singular), `docs/adr/`, the Docket issue body + comments (distilled contracts + ACs per the Distillation Gate); `docs/tdd/` is ephemeral — never a required input.
<!-- CANONICAL:DOCS-PATHS-LOCAL:END -->

## Role Detection

Callable ONLY by `@sdet`. Any other caller ABORTS:

```
Error: Skill(verify-ac) is restricted to @sdet. Calling agent: {agent}.
```

## Argument Handling

The argument is a single positional `<scope>` (free-text; extra positional args are ignored). If `<scope>` is missing or empty:

```
Error: Usage: Skill(verify-ac, "<scope>") — name what to verify (Docket issue ID, "uncommitted", "staged", branch name, or file paths). PR-scope review is @staff-engineer's via Skill(code-review-verdict, ...).
```

**Scope resolution** (apply rules in order; first match wins):

<!-- COUPLING: scope-resolution — this table's Branch name, Literal `uncommitted`, Literal `staged`, and File paths rows are BYTE-IDENTICAL to the same four rows in `src/user/claude-code/skills/code-review-verdict/SKILL.md`'s scope-resolution table; the branch-vs-file `./`-prefix ambiguity bullet below is near-identical. Keep both files in sync when either changes (DKT-250). -->
| Form | Detection | Sources |
|---|---|---|
| Docket issue ID | `docket issue show {scope} --json` exits 0 (abort: `Error: docket CLI required to resolve issue-ID scope. Re-invoke with branch name, "uncommitted", or file paths.` if CLI unavailable) | Pull issue + acceptance criteria + comments + file attachments via `docket issue show`, `docket issue comment list`, `docket issue file list`, `docket issue log` |
| Branch name | `git rev-parse --verify {scope}` exits 0 | `git diff main...{scope}` + `git log main...{scope} --oneline` + `git diff --stat main...{scope}` |
| Literal `uncommitted` | exact match | `git status --short` (surfaces untracked `??`) + `git diff` + `git diff --staged` + `git diff --stat HEAD` |
| Literal `staged` | exact match | `git diff --staged` + `git diff --stat --staged` |
| File paths (one or more, space-separated) | every token resolves via `Bash test -e {path}` | `Read` each file directly |

**Ambiguity rules:**

- A token matching the Docket issue ID pattern (e.g., `DKT-123`) always tries Docket-issue resolution first; on failure fall through to subsequent forms.
- A single token that is BOTH a valid branch name AND an existing file is treated as a branch. To force file-path scope, supply multiple tokens or prefix with `./` (e.g., `./main`).

If `<scope>` matches none of the above, ABORT:

```
Error: Could not resolve <scope>: '{scope}'. Expected Docket issue ID, branch name, "uncommitted", "staged", or existing file paths.
```

**Comma-batched Docket IDs.** A `<scope>` of comma-separated issue IDs (`DKT-45,DKT-46`) is N distinct verifications, not one merged scope — each issue carries its own ACs and verdict; run the full cycle once per ID, one report each.

## Doubling Rule

Each verifier (paired `verifier-criteria` + `verifier-integration` under orchestration, or a standalone single invocation) runs this skill independently and emits its own report — this skill is the single-verifier format authority. Verifier pairing, spawning, reconciliation, and fix-loop re-spawn are owned by the calling layer per `~/.claude/agents/team-lead.md`.

## When to Use

`@sdet` verifying a Docket issue's acceptance criteria against the implementation diff at any scope, including Round-2+ re-invocation after `@senior-engineer` ships fixes (carry-forward rules: `references/rounds.md`). Trivial changes may use LIGHT mode.

## When NOT to Use

<!-- COUPLING: this skill is part of the report-emission family (code-review-verdict, verify-ac, design-qa, design-review) — update all 4 in lockstep when adding/removing a sibling skill. -->
- Production code-quality review against design dimensions — `Skill(code-review-verdict)` (@staff-engineer/@distinguished-engineer/@security-engineer).
- Design QA of user-facing surfaces against a `docs/ux/` spec — `Skill(design-qa)`; peer review of a draft UX spec — `Skill(design-review)` (@ux-designer).
- Authoring TDDs, ADRs, PRDs, or UX specs — the doc-authoring family.
- Multi-agent consensus voting — `Skill(vote)`.

## Pre-flight

1. **Detect role**; ABORT if the caller is not `@sdet`.
2. **Resolve `<scope>`**; ABORT if unresolvable.
3. **Gather issue context** (Docket-issue scope): description + ACs (`docket issue show {id} --json`), comments (which supersede the description on conflict), file attachments, activity log when unclear. Verification is read-only on Docket workflow state per `~/.claude/agents/sdet.md` Rule 7 — never `docket issue move`. Missing file attachments are a finding (planning gap), not an abort. On a Round-2+ re-verification, apply the carry-forward procedure in `references/rounds.md` before scoring.
4. **Gather diff** per the resolved scope. **Never substitute the implementer's completion comment for the diff** — the comment describes intent; the diff describes what reached HEAD. Read the actual changed files and `git diff`/`git diff --stat` before scoring.
5. **Empty-artifact guard**: if the resolved scope produces no inspectable content, ABORT: `Error: Resolved scope produced no verifiable content — nothing to verify.`
6. **Read related design docs**, scoped to what the diff touches: `docs/ux/` for user-facing behavior; matching `docs/spec/` files only. If a criterion requires a `docs/tdd/` file to interpret, surface: `Distillation gap: this issue's acceptance criteria or context require a docs/tdd/ file to interpret — a planning defect. Surface to team-lead/@project-manager for re-distillation; do not dereference the TDD.` — and score that criterion FAIL (underspecified — planning defect), never resolved by locating the TDD. On the 2nd+ invocation in one session, apply the contamination guard in `references/rounds.md`.
7. **Mandatory verification commands check.** Under orchestration the dispatch brief SHOULD carry a `Mandatory verification commands` subsection. If absent on a non-trivial change, surface `Caller-contract gap: dispatch brief omits Mandatory verification commands subsection` and proceed with commands derived from the ACs — never silently substitute text-inspection for empirical execution.

## Verification Procedure

The calling agent selects depth per `~/.claude/agents/sdet.md`; this skill enforces the format once depth is chosen.

### LIGHT mode

For trivial fixes, docs-only changes, or changes already covered by existing passing tests: run the relevant tests, emit the one-line LIGHT Output. If LIGHT cannot be issued (any failed test, unmet or runtime-only criterion, or edge case worth surfacing), switch to FULL.

### FULL mode

1. **Verify each acceptance criterion individually** — PASS, FAIL, or OUT-OF-SCOPE with specific evidence (test output, file:line, observed behavior). **When an AC names a literal command, run THAT command verbatim** — a PASS on a paraphrased substitute is a defect; cite the exact command. For Docket-issue scope, `~/.claude/scripts/ac_check.sh {id}` mechanizes this: it extracts the AC's literal command spans and runs each verbatim, emitting per-AC `[PASS|FAIL]` you cite directly (pass `--section <heading-regex>` when ACs live under a differently-named heading). OUT-OF-SCOPE = verifiable only at runtime/render. **NEVER PASS a runtime-only criterion on a static proxy** (file exists, ref present, build exit 0 — a green build can still ship broken renders); mark OUT-OF-SCOPE, name the runtime route (`design-qa` for `docs/ux` surfaces; the bundled runtime `verify` otherwise), and leave dispatch to the calling agent.
2. **Layer signals** — run the suite, trace key paths, diff output against baseline, verify generated artifacts are consumed correctly; never rely on one signal.
3. **Test beyond stated criteria** — empty/null/large input, invalid input, unavailable dependencies, boundaries; surface under Additional Testing.
4. **Analyze coverage** — what's tested, where, and which gaps are conscious decisions vs. real risk.
5. **Decide verdict** per the ladder:

| Verdict | Meaning |
|---|---|
| APPROVE | All acceptance criteria PASS (none OUT-OF-SCOPE); no Critical/High issues; edge cases handled or consciously deferred |
| ACCEPT WITH CAVEATS | Core paths verified, but edge-case coverage incomplete, non-blocking issues remain, or OUT-OF-SCOPE criteria await runtime verification (caveat names the route) |
| BLOCK | Acceptance criteria unmet, security/data-integrity tests fail, or critical coverage missing for high-risk paths |

**Severity ladder for Issues Found:**

| Severity | Meaning |
|---|---|
| Critical | Data loss, security exposure, crash, breaking-change without migration |
| High | Major defect, no workaround, blocks acceptance |
| Medium | Real defect with workaround, or significant edge-case gap |
| Low | Cosmetic, minor, or defense-in-depth opportunity |

**Common discipline.** A justified BLOCK is more valuable than an unexamined APPROVE — do not default to APPROVE. Every PASS/FAIL claim cites the exact command run, file:line, or observed behavior; banned evidence-free framings: "clearly", "obviously", "should work", "definitely", "100%", "guaranteed". Ask when intent is genuinely ambiguous and the answer is not in the code (standalone: `AskUserQuestion`; team mode: route through the calling agent). For commands expected to take >30s (or 3-5x flaky-test reruns), use `Monitor` with a terminal-pattern filter, not a blocking poll.

## Output Contract

Emit the report verbatim into the calling agent's context. Do not echo the raw diff or add prose outside the format. If the harness blocks this skill's invocation, render the verdict directly per THIS format authority — never an improvised structure.

### LIGHT Output

```
APPROVE — tests pass: {command}; criteria met.
```

### FULL Output

```
## Verification: {Issue ID} — {Title}

**Tree state**: short `git rev-parse HEAD`, plus `+dirty:<sha12>` (`~/.claude/scripts/tree_fingerprint.sh` output) when the working tree has uncommitted changes — the fingerprint a later round diffs against for carry-forward.

### Acceptance Criteria
- [x] PASS / [ ] FAIL / [~] OUT-OF-SCOPE — {criterion 1} — {evidence: test output, file:line, observed behavior; OUT-OF-SCOPE cites the runtime route}
- ... (one bullet per criterion)

### Additional Testing
- {edge case} — {result + evidence}
- ... or "None beyond stated criteria"

### Test Coverage
- New tests: {file:test_name list, or "None"}
- Key files: {paths exercised}
- Coverage delta: {summary — branch/line, or "Not measured"}

### Issues Found
**Critical** ({count}):
- {bug summary} — {repro: command + expected vs actual}
- ... or "None"

**High** ({count}):
- ... or "None"

**Medium** ({count}):
- ... or "None"

**Low** ({count}):
- ... or "None"

### Recommendation
One of: **APPROVE** / **ACCEPT WITH CAVEATS** / **BLOCK** — {rationale tying verdict to criteria results and issues found}

Verification report emitted ({verdict}).
```

## Validation Before Emit

LIGHT mode is a single line — nothing to lint. FULL mode: stage and lint in a SINGLE Bash call — prefer the stdin form so there is no temp path to get wrong (shell state, including `$$` and computed paths, does not persist between Bash calls):

```
~/.claude/scripts/report_stage_lint.sh verify-ac [--mode light] "$DRAFT_FILE"
```

Exit codes:

- **0** — emit the report in the calling agent's context.
- **1 (validation failure)** — ABORT; correct (quoting the script's stderr) and re-invoke: `Error: validation failed: {section/field} — {detail}.`
- **2 (infra/usage)** — do NOT hard-block: emit the report with `lint not run (infra: {reason})` appended after the trailing confirmation line and flag the infra failure to the caller.

The validator mechanizes the text-decidable checks (section order, explicit empty buckets, verdict ↔ severity-count consistency, ladder allow-list, placeholder and banned-phrase scans). Two checks stay yours — they need the issue's AC list and semantic judgment: every acceptance criterion carries PASS/FAIL/OUT-OF-SCOPE (no silent omission; OUT-OF-SCOPE without a named runtime route is a defect), and every PASS/FAIL carries real evidence (a bare "criterion met" is a defect).

## Save & Return

FULL mode ends with the confirmation line:

```
Verification report emitted ({verdict}).
```

LIGHT mode's single APPROVE line is the entire emission — no trailing confirmation. The in-context emission is the working artifact; the deliverable is same-turn delivery by the channel your mode prescribes — the DEFAULT lone `verifier` is a report-only subagent with NO SendMessage (sdet.md SP-2): return the verdict body to team-lead as its PLAIN-TEXT final message and END, folding any peer routing into that text; a PAIRED-panel teammate verifier SendMessages peers per `~/.claude/agents/sdet.md`.

The calling agent owns:

- Docket follow-through (the issue was already closed by `@senior-engineer` at end of implementation): APPROVE → `docket issue comment add <id> -m "..."`; ACCEPT WITH CAVEATS → comment the caveats and route follow-up via `@project-manager` (no workflow-state move); BLOCK → `docket issue reopen <id>` + a blocking-criteria comment. `reopen` on BLOCK is the ONLY legitimate verification state-change.
- Vote escalation per `~/.claude/agents/sdet.md` — standalone: `Skill(vote)`; team mode: never `Skill(vote)` (nests a team) — `docket vote create` + `delegation_request` to team-lead.

On any abort: emit `Error: {one-line cause}` and end without producing a report.
