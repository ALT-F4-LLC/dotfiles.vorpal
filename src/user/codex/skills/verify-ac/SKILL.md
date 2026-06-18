---
name: verify-ac
description: >
  Verify a Docket issue's acceptance criteria against the implementation diff (static, evidence-based — NOT
  runtime app-behavior verification) and emit a structured verification report. Loaded into the calling
  agent's context; the calling agent (`@sdet`) drives verification, the skill enforces the format authority
  — verdict ladder, required sections, validation rules. No file written; the report is emitted into the
  agent's context.
  Trigger: "verify acceptance criteria", "verify Docket issue", "produce verification report" — NOT app/PR runtime checks (that is the bundled runtime `verify` skill, the name this skill was renamed away from to avoid collision).
---
<!-- CANONICAL:BANNER:BEGIN -->
> **CRITICAL:** (1) Do NOT commit ANY changes (no `git add`, no `git commit`, no `git push`) unless EXPLICITLY instructed by the user. (2) This is a leaf skill. You MUST NOT spawn sub-agents, invoke `Skill()` recursively, use `Agent()` or `SendMessage`, or form/manage a team. The calling agent handles peer messaging and Docket close/comment after this skill returns.
<!-- CANONICAL:BANNER:END -->

# Verify-AC — Acceptance-Criteria Verification

You are the **Verifier**. You verify the artifact named by `<scope>` against its acceptance criteria and emit a structured verification report back to the calling agent's context. No file is written. The skill is the format authority — verdict ladder, required sections, severity, validation rules.

<!-- CANONICAL:DOCS-PATHS-LOCAL:BEGIN -->
**Docs paths (this skill).** Master: team-lead.md §Docs-Path Taxonomy (maintained copy).
- Writes: none — report into the calling agent's context.
- Reads: `docs/tdd/` (accepted only), `docs/ux/`, `docs/spec/`.
- Always singular docs/spec/ — never docs/specs/.
<!-- CANONICAL:DOCS-PATHS-LOCAL:END -->

## Role Detection

This skill is callable ONLY by `@sdet`. Match the calling agent's identifier (from prompt context); if the caller is not `@sdet`, ABORT.

Abort message:

```
Error: Skill(verify-ac) is restricted to @sdet. Calling agent: {agent}.
```

## Argument Handling

The argument is a single positional `<scope>` (free-text). No flags.

If `<scope>` is missing or empty:

```
Error: Usage: Skill(verify-ac, "<scope>") — name what to verify (Docket issue ID, "uncommitted", "staged", branch name, or file paths). PR-scope review is @staff-engineer's via Skill(code-review-verdict, ...).
```

**Scope resolution** (apply rules in order; first match wins):

| Form | Detection | Sources |
|---|---|---|
| Docket issue ID | `docket issue show {scope} --json` exits 0 | Pull issue + acceptance criteria + comments + file attachments via `docket issue show`, `docket issue comment list`, `docket issue file list`, `docket issue log` |
| Branch name | `git rev-parse --verify {scope}` exits 0 | `git diff main...{scope}` + `git log main...{scope} --oneline` + `git diff --stat main...{scope}` |
| Literal `uncommitted` | exact match | `git diff` + `git diff --staged` + `git diff --stat HEAD` |
| Literal `staged` | exact match | `git diff --staged` + `git diff --stat --staged` |
| File paths (one or more, space-separated) | every token resolves via `Bash test -e {path}` | `Read` each file directly |

**Ambiguity rules** (apply when multiple forms could match):

- A token matching the Docket issue ID pattern (e.g., `DKT-123`, `ISS-45`) always tries Docket-issue resolution first. If `docket issue show` exits non-zero (no such issue), fall through to subsequent forms.
- A single token that is BOTH a valid branch name AND an existing file is treated as a branch. To force file-path scope, supply multiple tokens or prefix with `./` (e.g., `./main`).

If `<scope>` matches none of the above, ABORT:

```
Error: Could not resolve <scope>: '{scope}'. Expected Docket issue ID, branch name, "uncommitted", "staged", or existing file paths.
```

If extra positional args follow `<scope>`, ignore them silently.

**Comma-batched Docket IDs.** A `<scope>` of comma-separated Docket issue IDs (`DKT-45,DKT-46,DKT-47`) is N distinct verifications, not one merged scope — each issue carries its own acceptance criteria and verdict. Split on commas and run the full Pre-flight → Verification → Output cycle once per ID, emitting one report per issue. (Contrast `code-review-verdict`'s comma path-list, which forms a single scope: there the tokens are files in one diff; here they are independent issues.)

## Doubling Rule

Each verifier (whether paired `verifier-criteria` + `verifier-integration` under orchestration, or a standalone single invocation) runs this skill independently and emits its own report in this format — this skill is the single-verifier output-format authority, not the orchestrator. Spawning, eager dispatch, verdict reconciliation, degraded-fallback annotation, and fix-loop re-spawn are owned by the calling layer per `src/user/claude-code/agents/team-lead.md` (Rule 7, Rule 8, step 14, step 15). Do not duplicate that logic here.

## When to Use

- `@sdet` is verifying a Docket issue's acceptance criteria against the implementation diff at any scope (issue, uncommitted, staged, branch, files).
- A non-trivial change requires the FULL verification template with verdict ladder, evidence per criterion, and Issues Found.
- A trivial change (typo, formatting, docs-only) may use LIGHT mode — see Verification Procedure below.
- **Re-invocation after fix is expected.** When `@senior-engineer` ships fixes for prior BLOCK / ACCEPT-WITH-CAVEATS findings, `@sdet` re-invokes `Skill(verify-ac, "<scope>")` for a Round-2 pass on the new diff — carry-forward and end-to-end re-run rules are enforced at Pre-flight §3a.

## When NOT to Use

<!-- COUPLING: this skill is part of the report-emission family (code-review-verdict, verify-ac, design-qa, design-review). The "When NOT to Use" delegation routes below MUST stay in sync across the family — update all 4 in lockstep when adding/removing a sibling skill. The Doubling Rule section is also part of this family — keep its shape in sync across siblings per `src/user/claude-code/agents/team-lead.md` Rule 8. -->
- Production code-quality review against design dimensions — that's `Skill(code-review-verdict, ...)`, callable by `@staff-engineer` or `@security-engineer`.
- Design QA against a `docs/ux/` spec for user-facing surfaces — that's `Skill(design-qa, ...)`, callable by `@ux-designer`.
- Peer design review of a draft UX spec or design proposal — that's `Skill(design-review, ...)`, callable by `@ux-designer`.
- Authoring TDDs, ADRs, PRDs, or UX specs — use the doc-authoring family (`tdd`, `adr`, `prd`, `ux-spec`).
- Multi-agent consensus voting — use `Skill(vote, ...)`.

## Pre-flight

1. **Detect role** per Role Detection. ABORT if caller is not `@sdet`.
2. **Resolve `<scope>`** per Argument Handling. ABORT if unresolvable.
3. **Gather issue context** (Docket-issue scope only): description + acceptance criteria (`docket issue show {id} --json`), comments (which supersede the description on conflict), file attachments, and activity log when context is unclear. The calling agent (`@sdet`) acknowledges the dispatch via SendMessage but does NOT `docket issue move` for verification — verification is read-only on Docket workflow state per `src/user/claude-code/agents/sdet.md` Rule 7 (moving regresses state / falsely signals implementation is still running), so there is no state move to undo. If file attachments are missing, surface as a finding (planning gap) rather than abort; the calling agent decides whether to BLOCK.
3a. **Prior-verdict awareness** (Round-2+ re-verifications only). Before scoring criteria, scan `docket issue comment list {id}` for prior verification reports. For each acceptance criterion previously marked PASS whose evidence file/test was NOT touched by the current diff (`git diff --stat` vs the prior round's commit), cite the prior round's verdict in the new report's evidence (`PASS — unchanged since round {N}: {prior evidence}`) rather than re-running its evidence command. Re-run the full test suite end-to-end regardless; never carry forward a FAILed criterion or an Additional Testing gap. Reduces per-round token spend on multi-round fix-loops.
4. **Gather diff** per the resolved scope's source. **Do not substitute the implementer's completion comment for the diff** — completion claims describe what the implementer intended to ship; the diff describes what reached HEAD. Always Read the actual changed files and inspect `git diff` / `git diff --stat` before scoring criteria.
5. **Empty-artifact guard**: if the resolved diff/scope produces no inspectable content (no files, no acceptance criteria, empty issue), ABORT:

   ```
   Error: Resolved scope produced no verifiable content — nothing to verify.
   ```
6. **Read related design docs** (scope to what the diff touches):
   - TDDs in `docs/tdd/` that the issue references. **TDD status gate**: only verify against TDDs with `status: accepted`. If the referenced TDD is `draft`, `proposed`, or `in-review`, ABORT:

     ```
     Error: Referenced TDD '{path}' has status '{status}' — verification requires status: accepted. Escalate to team-lead for vote approval before re-invoking.
     ```

     If the referenced TDD is missing from `docs/tdd/`, ABORT:

     ```
     Error: Referenced TDD '{path}' not found in docs/tdd/. Escalate to team-lead before re-invoking.
     ```
   - UX specs in `docs/ux/` for user-facing behavior.
   - Project specs in `docs/spec/` matching the changed areas only (e.g., `testing.md` for test changes, `security.md` for auth/crypto/secrets, `performance.md` for hot-path edits — skip the rest).
6a. **Cross-issue contamination guard** (multi-issue sessions only). When this is the 2nd+ `Skill(verify-ac, ...)` invocation in the same session, identify whether the prior issue's verification produced persistent test artifacts (database rows, generated files outside the diff, env-var mutations, cached fixtures) that could affect the current issue's tests. If yes, the calling agent MUST reset the relevant state (drop test DB, `rm` generated artifacts, unset env vars) BEFORE running the current issue's tests; cite the reset commands in evidence. If reset is impractical (e.g., shared infra), surface a Test Coverage finding: `Cross-issue contamination risk: prior verification of {prior_issue} mutated {artifact}; current verification not isolated`.
7. **Mandatory verification commands check.** When invoked under team-lead orchestration, the dispatch brief SHOULD contain a `Mandatory verification commands` subsection listing greps / awks / wcs / test commands to execute against the artifact. If the brief lacks this subsection AND the change is non-trivial (any code change beyond a typo/doc edit), surface as a Pre-flight finding (`Caller-contract gap: dispatch brief omits Mandatory verification commands subsection`) and proceed by selecting commands derived from the acceptance criteria; cite each command's evidence in the report. Do NOT silently substitute text-inspection for empirical execution per `src/user/claude-code/agents/sdet.md` Epistemic Discipline.

## Verification Procedure

**Triage first.** The calling agent (`@sdet`) selects depth — LIGHT or FULL — per the judgment described in `src/user/claude-code/agents/sdet.md`. This skill enforces the format once depth is chosen.

### LIGHT mode

For trivial fixes (typo, formatting, single-line config), docs-only changes, or changes already covered by existing passing tests:

1. Run the relevant tests / verification command.
2. Emit the one-line report defined in Output Contract § LIGHT Output (no template).

If LIGHT cannot be issued (any failed test, any unmet or runtime-only criterion, any edge case worth surfacing), switch to FULL.

### FULL mode

Apply the full procedure. Scale evidence to risk.

1. **Verify each acceptance criterion individually** — mark PASS, FAIL, or OUT-OF-SCOPE with specific evidence (test output, file/line reference, observed behavior). **When an AC names a literal command, run THAT command verbatim** — an equivalent or paraphrased command leaves the named path unverified, so a PASS on a substitute is a defect; cite the exact command in evidence. OUT-OF-SCOPE = verifiable only at runtime/render (live app behavior, rendered page/visual output, deployed-environment state). NEVER PASS a runtime-only criterion on a static proxy (file exists, ref present, build exit 0 — a green build can still ship broken renders); mark OUT-OF-SCOPE, name the runtime route (`design-qa` for `docs/ux` surfaces; bundled runtime `verify` otherwise), and leave dispatch to the calling agent.
2. **Layer signals** — run the suite, trace key paths, diff output against baseline, verify generated artifacts are consumed correctly. Never rely on one signal.
3. **Test beyond stated criteria** — empty/null/large input, invalid/malicious input, unavailable dependencies, boundary conditions. Surface findings under Additional Testing.
4. **Analyze coverage** — what's tested, where, and which gaps are conscious decisions vs. real risk.
5. **Decide verdict** per the ladder:

| Verdict | Meaning |
|---|---|
| APPROVE | All acceptance criteria PASS (none OUT-OF-SCOPE); no Critical/High issues; edge cases handled or consciously deferred |
| ACCEPT WITH CAVEATS | Core paths verified, but edge-case coverage incomplete, non-blocking issues remain, or OUT-OF-SCOPE criteria await runtime verification (caveat names the route) — calling agent annotates the caveats |
| BLOCK | Acceptance criteria unmet, security/data-integrity tests fail, or critical coverage missing for high-risk paths |

**Severity ladder for Issues Found:**

| Severity | Meaning |
|---|---|
| Critical | Data loss, security exposure, crash, breaking-change without migration |
| High | Major defect, no workaround, blocks acceptance |
| Medium | Real defect with workaround, or significant edge-case gap |
| Low | Cosmetic, minor, or defense-in-depth opportunity |

**Common discipline:**

- **Ask clarifying questions first** when intent is ambiguous — use `AskUserQuestion` per the calling agent's structural contract. Do NOT ask when the answer is in the code.
- **Honest critique.** Do NOT default to APPROVE. A justified BLOCK is more valuable than an unexamined APPROVE.
- **Evidence over assertion.** Every PASS/FAIL claim cites the exact command run, file:line inspected, or observed behavior — not "tests pass" or "looks correct". Per `src/user/claude-code/agents/sdet.md` Epistemic Discipline rule: banned framings ("clearly", "obviously", "should work", "100%") are evidence-free assertions and a validation failure for the verdict.
- **Stream long commands.** For test suites, builds, or scans expected to take >30s, use `Monitor` with an until-loop on a terminal pattern (PASS/FAIL line, exit marker), not a blocking poll. For flaky-test confirmation (3-5x reruns), use Monitor with an exit-on-deviation pattern.

## Output Contract

Emit the verification report verbatim to the calling agent's context. Do NOT echo the raw diff. Do NOT save to disk. Do NOT add a preamble or trailing notes outside the format.

### LIGHT Output

```
APPROVE — tests pass: {command}; criteria met.
```

### FULL Output

```
## Verification: {Issue ID} — {Title}

### Acceptance Criteria
- [x] PASS / [ ] FAIL / [~] OUT-OF-SCOPE — {criterion 1} — {evidence: test output, file:line, observed behavior; OUT-OF-SCOPE cites the runtime route}
- [x] PASS / [ ] FAIL / [~] OUT-OF-SCOPE — {criterion 2} — {evidence}
- ... (one bullet per criterion)

### Additional Testing
- {edge case 1} — {result + evidence}
- {edge case 2} — {result + evidence}
- ... or "None beyond stated criteria"

### Test Coverage
- New tests: {file:test_name list, or "None"}
- Key files: {paths exercised}
- Coverage delta: {summary — branch/line, or "Not measured"}

### Issues Found
**Critical** ({count}):
- {bug summary} — {severity rationale} — {repro: command + expected vs actual}
- ... or "None"

**High** ({count}):
- ... or "None"

**Medium** ({count}):
- ... or "None"

**Low** ({count}):
- ... or "None"

### Recommendation
One of: **APPROVE** / **ACCEPT WITH CAVEATS** / **BLOCK** — {rationale tying verdict to criteria results and issues found}
```

## Validation Before Emit

Before emitting the report, verify in the calling agent's context:

1. **Mode selection is consistent** — LIGHT emits exactly one line in the LIGHT format; FULL emits the FULL template.
2. **FULL: every acceptance criterion has PASS, FAIL, or OUT-OF-SCOPE** — silent omission or "TBD" markers are defects; OUT-OF-SCOPE without a named runtime route is a defect.
3. **FULL: every PASS/FAIL has evidence** — `criterion met` without a test command, file/line, or observed-behavior fragment is a defect.
4. **FULL: every severity bucket is explicit** — every bucket reads `None` or lists items.
5. **FULL: BLOCK and ACCEPT WITH CAVEATS each have at least one Issue Found** — a BLOCK or ACCEPT verdict with empty Issues Found across all severities is a defect (the rationale must point at concrete findings); an OUT-OF-SCOPE criterion satisfies this for ACCEPT WITH CAVEATS.
6. **FULL: verdict consistency** — BLOCK requires at least one Critical or High issue OR at least one FAIL on a criterion; ACCEPT WITH CAVEATS requires at least one Medium/Low issue, an Additional Testing gap, or an OUT-OF-SCOPE criterion; APPROVE has no Critical/High, no FAIL, and no OUT-OF-SCOPE (any OUT-OF-SCOPE caps the verdict at ACCEPT WITH CAVEATS).
7. **Recommendation is on the verdict ladder** — exactly one of APPROVE / ACCEPT WITH CAVEATS / BLOCK.
8. **Placeholder scan** — body contains no literal `{Issue ID}`, `{count}`, `{evidence}`, `TBD`, or `TODO` text outside of code-fenced examples.
9. **Epistemic discipline scan** — no banned confidence phrases ("clearly," "obviously," "should work," "definitely," "100%," "guaranteed") in Acceptance Criteria evidence, Additional Testing, Issues Found, or Recommendation. Use evidence-anchored language ("ran X — saw Y," "verified at {file:line}," "unverified — assumption"). A hit is a defect.

If any check fails, ABORT:

```
Error: validation failed: {section/field} — {detail}.
```

The calling agent corrects in its own context and re-invokes `Skill(verify-ac, "<scope>")`.

## Save & Return

No file is written (Output Contract owns the emission rules). FULL mode ends with the confirmation line:

```
Verification report emitted ({verdict}).
```

where `{verdict}` is `APPROVE`, `ACCEPT WITH CAVEATS`, or `BLOCK`. LIGHT mode's single APPROVE line is the entire emission — no trailing confirmation.

The calling agent owns (in order):

- Closing or commenting the Docket issue (the issue was already CLOSED by `@senior-engineer` at end of implementation — `docket issue close` here is a no-op): on APPROVE, `docket issue comment add <id> -m "..."`; on ACCEPT WITH CAVEATS, comment summarizing the caveats and route any follow-up via SendMessage `@project-manager` (no workflow-state move); on BLOCK, `docket issue reopen <id>` followed by a blocking-criteria comment. `reopen` on BLOCK is the only legitimate verification state-change.
- SendMessage to peers per the `src/user/claude-code/agents/sdet.md` Inter-Agent Communication triggers (e.g., BLOCK → @senior-engineer + team-lead).
- Escalating to vote per the vote triggers in `src/user/claude-code/agents/sdet.md` — standalone: `Skill(vote, ...)`; team mode: NEVER `Skill(vote)` (nests a team) — `docket vote create` + `delegation_request` to team-lead per `src/user/claude-code/agents/sdet.md` §Using `/vote` for Consensus.

**Silent-completion self-check (mandatory before turn-end).** The trailing `Verification report emitted (...)` line is a confirmation, NOT a delivery — the verdict was emitted into your context, not the caller's inbox. Before ending the turn, answer: "Did I SendMessage the structured verdict body (not summarized) to team-lead this same turn?" If no, the turn is incomplete regardless of how complete the in-context emission feels. The skill's in-context output is the working artifact; the SendMessage IS the deliverable.

On any abort during Pre-flight, Verification Procedure, or Validation Before Emit: emit `Error: {one-line cause}` and end without producing a report.

## Failure Modes

The abort paths for missing/invalid `<scope>`, role-mismatched callers, unresolvable scope, empty content, TDD status gate, and validation failure are specified inline at Argument Handling, Role Detection, and Pre-flight. The table below covers abort paths that introduce new abort text or scope-specific behavior:

| Trigger | Handling |
|---|---|
| Docket CLI unavailable for an issue-ID scope | Abort: `Error: docket CLI required to resolve issue-ID scope. Re-invoke with branch name, "uncommitted", or file paths.` |
