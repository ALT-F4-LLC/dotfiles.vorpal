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
effort: xhigh
---

<!-- CANONICAL:BANNER:BEGIN -->
> **CRITICAL:** (1) Do NOT commit ANY changes (no `git add`, no `git commit`, no `git push`) unless EXPLICITLY instructed by the user. (2) This is a leaf skill. You MUST NOT spawn sub-agents, invoke `Skill()` recursively, use `Agent()` or `SendMessage`, or form/manage a team. The calling agent handles peer messaging and consensus follow-ups after this skill returns.
<!-- CANONICAL:BANNER:END -->

# Code Review Verdict — Conduct a Role-Scoped Review

You are the **Reviewer**. You conduct a code review on the artifact named by `<scope>` and emit a structured report back to the calling agent's context. No file is written. The review is role-aware; playbook selection is Pre-flight step 3 (`@distinguished-engineer`, the Medium+ advisor seat, applies the general playbook per `distinguished-engineer.md` §Mode 2 — Code review). The format authority — dimensions, severity ladders, output sections, validation rules — lives here.

<!-- CANONICAL:DOCS-PATHS-LOCAL:BEGIN -->
**Docs paths (this skill).** Master: `~/.claude/skills/team-doctrine/references/docs-paths.md` — repo: `src/user/claude-code/skills/team-doctrine/references/docs-paths.md` (maintained copy).
- Writes: none — report into the calling agent's context.
- Reads: `docs/spec/`, `docs/adr/`, `docs/ux/`, the Docket issue body + comments (distilled design contracts + ACs per the Distillation Gate — docs-paths.md §Persistence & lifecycle).
- Always singular docs/spec/ — never docs/specs/.
- `docs/tdd/` is ephemeral — Design/Planning input only; deletable any time after implementation (master: docs-paths.md).
<!-- CANONICAL:DOCS-PATHS-LOCAL:END -->

## Role Detection

This skill is callable ONLY by `@staff-engineer`, `@distinguished-engineer`, or `@security-engineer`; `{role}` is the calling agent's identifier (from prompt context) minus the `@`. Any other caller ABORTS:

```
Error: Skill(code-review-verdict) is restricted to @staff-engineer, @distinguished-engineer, and @security-engineer. Calling agent: {agent}.
```

## Argument Handling

The argument is a single positional `<scope>` (free-text). No flags.

If `<scope>` is missing or empty:

```
Error: Usage: Skill(code-review-verdict, "<scope>") — name what to review (PR number/URL, branch, "uncommitted", "staged", or file paths).
```

**Scope resolution** (apply rules in order; first match wins):

<!-- COUPLING: scope-resolution — this table's Branch name, Literal `staged`, and File paths rows are BYTE-IDENTICAL to the same three rows in `src/user/claude-code/skills/verify-ac/SKILL.md`'s scope-resolution table; the branch-vs-file `./`-prefix ambiguity bullet in the Ambiguity rules below is near-identical (differs only by "on such a name"). Keep all four in sync across both files when either changes — decision record: DKT-250 (extraction rejected; coupling documented instead; the originating TDD was deleted per docs-paths.md TDD ephemerality). -->
| Form | Detection | Diff source |
|---|---|---|
| GitHub PR number | matches `^\d+$` | `gh pr view {n}` (description) + `gh pr diff {n}` (diff) |
| GitHub PR URL | contains `/pull/` | extract `n`; same as PR number |
| Branch name | `git rev-parse --verify {scope}` exits 0 | `git diff main...{scope}` + `git log main...{scope} --oneline` + `git diff --stat main...{scope}` |
| Literal `uncommitted` | exact match | `git status --short` (surfaces untracked `??`) + `git diff` + `git diff --staged` + `git diff --stat HEAD` |
| Literal `staged` | exact match | `git diff --staged` + `git diff --stat --staged` |
| File paths (one or more, space-separated) | every token resolves via `Bash test -e {path}` | `Read` each file directly |

**Path-list normalization (canonical grammar).** The canonical multi-file form is bare space-separated paths — `Skill(code-review-verdict, "src/a.rs tests/b.rs")`. Before applying the table, strip a leading `files`/`files:` keyword if present, then split the argument on commas and/or whitespace; resolve the resulting tokens via the File paths row. This collapses the three observed call forms — `path path`, `files path path`, `files: path, path` — to one token list. (Single bare tokens are unaffected: no prefix, no comma, so branch/PR detection still wins per the table order.)

**Ambiguity rules** (apply when multiple forms could match):

- A token matching `^\d+$` always tries PR-number first via `gh pr view {n} --json number`. If `gh` exits non-zero (no such PR), fall through to branch detection. If both fail, fall through to file-path detection only when the token is a real path. If the `gh` CLI itself is unavailable for a PR scope, abort: `Error: gh CLI required to resolve PR scope. Re-invoke with the branch name or "uncommitted".`
- A single token that is BOTH a valid branch name AND an existing file is treated as a branch. To force file-path scope on such a name, supply multiple tokens or prefix with `./` (e.g., `./main`).

If `<scope>` matches none of the above, ABORT:

```
Error: Could not resolve <scope>: '{scope}'. Expected PR number/URL, branch name, "uncommitted", "staged", or existing file paths.
```

If extra positional args follow `<scope>`, ignore them silently.

## When to Use

- The calling agent (`@staff-engineer`, `@distinguished-engineer`, or `@security-engineer`) is performing a code review at any scope (PR, branch, uncommitted, staged, files).
- The team-lead Implementation Phase delegates review to the persistent advisor, who invokes this skill to produce the format-correct verdict.
- **Re-invocation after fix is expected** — the dominant call pattern is fix→re-review loops on the same scope (PR# first, then `uncommitted` once the fix lands locally). Emit the compact Round-N format (see Output Contract → Round-N Re-Review), not a fresh full sweep, unless new code introduces new risk.

## Doubling Rule

Panel sizing, opt-up triggers, same-turn eager dispatch, ephemeral lifecycle, verdict reconciliation, and the degraded-single-reviewer annotation are owned by `~/.claude/agents/team-lead.md` Rule 8 / Rule 7 / step 14 — read them there, do not restate them here. Skill-specific delta only:

- **Seats (general track)**: single (default) = persistent `advisor`, verdict final; doubled = `advisor` + one ephemeral `reviewer-2`, only when a Rule 8 (a)/(b)/(c) opt-up trigger fires.
- **Seats (security track)**: `security-advisor` + one ephemeral `security-reviewer-2` is an INDEPENDENT DEFAULT whenever the diff touches a security-sensitive surface (Rule 8 C3) — never an opt-up. The security flag does NOT force-double the general track; a security-sensitive diff that ALSO trips a general trigger lands at 4 reviewers.
- **Independent emission**: each reviewer invokes this skill independently and emits its own structured report — this skill is the single-reviewer output-format authority, never the panel-reconciliation authority.
- **Fix-round delta**: a Rule 8 C4 fix-round re-review emits the compact §Round-N Re-Review format below, not the full template.
- Standalone-mode invocations follow the calling agent's own discretion.

## When NOT to Use

<!-- COUPLING: this skill is part of the report-emission family (code-review-verdict, verify-ac, design-qa, design-review). The "When NOT to Use" delegation routes below MUST stay in sync across the family — update all 4 in lockstep when adding/removing a sibling skill. The Doubling Rule section is also part of this family — keep its shape in sync across siblings per `src/user/claude-code/agents/team-lead.md` Rule 8 (verify-ac's Doubling Rule is intentionally delegation-only — verifier pairing is owned by the calling layer, so it carries no Seats/dedupe/degraded bullets; never normalize it to the three-bullet delta shape). The Save & Return silent-completion self-check is family-synced too — shared sentence structure, per-skill delivery-channel tail; verify-ac's tail is mode-aware (its default lone `verifier` has NO SendMessage per sdet.md SP-2) and must NEVER be flattened to a SendMessage-only shape. -->
- Authoring TDDs, ADRs, PRDs, or UX specs — use `Skill(tdd, ...)`, `Skill(adr, ...)`, `Skill(prd, ...)`, `Skill(ux-spec, ...)`.
- Multi-agent consensus voting on an artifact — use `Skill(vote, ...)`. After this skill produces a review, the calling agent decides whether the change meets a vote-criticality trigger (500+ lines, security-critical surfaces, breaking-change plans) and delegates accordingly.
- Acceptance-criteria verification against a Docket issue — use `Skill(verify-ac, ...)`, callable by `@sdet`.
- Design QA against a `docs/ux/` spec for shipped user-facing surfaces — use `Skill(design-qa, ...)`, callable by `@ux-designer`.
- Peer design review of a draft UX spec or design proposal — use `Skill(design-review, ...)`, callable by `@ux-designer`.
- Plan/scope/dependency review on a Docket plan — handled inline by the calling agent's advisory output.

## Pre-flight

1. **Detect role** per Role Detection. ABORT if invalid.
2. **Resolve `<scope>`** per Argument Handling. ABORT if unresolvable.
3. **Resolve context**: `{role}` = the detected role (`staff-engineer`, `distinguished-engineer`, or `security-engineer`). **Playbook, severity, and output selection**: `@staff-engineer` and `@distinguished-engineer` → Staff-Engineer Playbook + output (general 6-dimension); `@security-engineer` → Security-Engineer Playbook + output. The general output's `## Review (general — @staff-engineer)` heading is a fixed TRACK literal — `report_lint.py`'s `CRV_GENERAL` banner regex recognizes only that exact banner — so a `@distinguished-engineer` caller emits it VERBATIM, never substituting its own handle; author identity rides the delivering SendMessage, not the banner.
4. **Gather artifact context** per the resolved scope's diff source. Capture the file list (`git diff --stat` or PR file list) before reading bodies — this drives triage. Run this census yourself (`git diff --stat`, plus `git status --short` on `uncommitted`/`staged` scopes to surface untracked `??` files); resolve `audit_snapshot.sh` relative to the invoking repo root and run it for a dependency snapshot if present, else skip — a missing script is N/A, not fatal, and a mismatched path layout must never hard-fail: `SNAP=$(git rev-parse --show-toplevel 2>/dev/null)/.claude/scripts/audit_snapshot.sh; [ -x "$SNAP" ] || SNAP=~/.claude/scripts/audit_snapshot.sh; [ -x "$SNAP" ] && "$SNAP" 2>/dev/null || true` (repo-root copy first, deployed home copy as fallback). **If the file count exceeds 50, surface a one-line summary first** (`{N} files, {lines} lines — recommend Split required unless author confirms cohesive scope`) so the calling agent can escalate before deep review effort is wasted.
5. **Empty-diff guard**: if the resolved diff is empty (no file changes), ABORT:

   ```
   Error: Resolved scope produced an empty diff — nothing to review.
   ```

   **Snapshot-tree guard** (`uncommitted`/`staged` scopes only; PR/branch scopes are not snapshot-prone and skip it): a local working-tree diff is a point-in-time snapshot — the skill cannot tell whether all of the cycle's expected edits have landed; do NOT mechanically guess the expected file-set. **Under team-lead orchestration**, do not proceed past Pre-flight unless the calling agent holds an implementation-complete signal — a team-lead GO with no open `blockedBy` on the reviewed work; when the invocation context names Docket issue IDs, confirm each is closed via `docket issue show <id> -q`. Without that signal, ABORT: `Error: moving tree — implementation not signalled complete; re-invoke after team-lead GO.` (Reviews have fired before implementers finished despite agent-level go-signal briefs and blockedBy edges — the skill-level gate is the backstop.) **Standalone (no orchestrator)**, prefix the verdict with one line — `Reviewed local working tree at this point in time — N files present; confirm implementation is signalled-complete before this verdict binds` — so the calling agent reconciles against the cycle's acceptance criteria before routing.
6. **Read related design docs** — scope reads to what the diff touches; do not read specs outside the changed-file paths:
   - `staff-engineer`: the issue's distilled contracts + `docs/spec/` matching changed areas, where present (`architecture.md`, `performance.md`, `testing.md`).
   - `security-engineer`: the issue's distilled security contracts + `docs/adr/` security records + `docs/spec/security.md`.

## Review Procedure

**Triage first.** Scale effort to risk. Trivial changes (README typo, version bump on a stable dep, cosmetic-only diff) get a one-line acknowledgment per the Output Contract. Substantive changes get the full role-specific dimension sweep. For 500+ line diffs, focus on the 20% of code carrying 80% of risk first; recommend a split if scope mixes independent concerns or risk levels.

**Finding-sourcing discipline (anti-fabrication — load-bearing).** Write each per-file finding ONLY from that file's COMPLETE diff rendered in a clean call this turn — never from memory of "what this kind of change usually does," and never from a cancelled or empty batch result. If a parallel batch member errors (e.g. a sandbox-denied `> $TMPDIR/...` redirect), the harness CANCELS every later call in that batch; an empty/cancelled result means the file is UNVERIFIED, not unchanged — re-issue the probe as a solo call before asserting anything about it. Prefer `git diff` / `Read` over `grep -n` for load-bearing verification (`grep -n` has returned wrong line content). Never carry an expected-change guess forward as a "verified" finding; an evidence-anchored line that is actually fabricated ("VERIFIED from real diff" for a hunk that does not exist) is worse than an honest "did not verify."

### Staff-Engineer Playbook

Apply the **6 dimensions**, weighted by what the change touches. Mark unaffected dimensions `N/A` in the checklist:

1. **Architecture** — pattern fit, module boundaries, dependency direction, second-order effects, cross-cutting impact, precedent set.
2. **Security (general posture)** — input boundaries, error-path safety, default-deny defaults, accidental privilege escalation. Auth/secret/crypto/sandbox specifics defer to the parallel `@security-engineer` review when one is running; if a routine staff review surfaces such specifics and no parallel review is in flight, flag the finding as a Concern with `Next Steps` instructing the calling agent to SendMessage `@security-engineer` for a dedicated security pass before merge.
3. **Operations** — observability hooks, runbook impact, deploy/rollback story, 3am-diagnosability, configuration footprint. Flag an emitted output/digest field that is initialized and emitted but never mutated (`grep` the field — init + emit, no write) as a Concern (Blocker only if AC-gated): an always-empty stub a consumer cannot distinguish from a real zero; require it wired or annotated reserved/deferred in both code and the design doc.
4. **Performance** — algorithmic complexity, N+1 patterns, allocation hotspots, latency-budget impact, regression risk.
5. **Code Quality** — apply the 12 code-philosophy principles per `~/.claude/agents/senior-engineer.md` → Code Quality & Craftsmanship (format authority). Four principles carry mechanical Hard Gates enforced below: **#4 mutation locality** (G2), **#5 parse at the edge** (G3), **#6 error propagation** (G1), **#11 invariant over surface** (G4). The other eight (#1 abstraction, #2 names, #3 cohesion-over-length, #7 comments-justify, #8 tests-pin-behavior, #9 minimal-diff, #10 dep-posture, #12 deletability) belong to the Concern/Suggestion rubric — apply per touched file.
6. **Testing** — coverage of acceptance criteria, edge-case discipline, regression coverage, test fragility, what's untested and why. Test *quality* (asserts behavior vs implementation, mocks at boundaries only) lives under #8 above; this dimension covers *what* is tested — acceptance criteria, edges, regressions, untested-but-should-be-tested paths.

**Severity ladder (general)**:

| Severity | Meaning |
|---|---|
| Blocker | Must fix before merge: data loss, breaking change without migration, critical missing test on a privileged path |
| Concern | Should fix or explicitly justify: pattern violation, missing edge case, test gap on a non-critical path |
| Suggestion | Consider for this or future work: better approach, minor improvement |
| Question | Need clarification to complete the review |
| Praise | Pattern worth highlighting |

### Security-Engineer Playbook

Apply the **9 security dimensions**, weighted by what the change touches. Mark unaffected dimensions `N/A`:

1. **Authn / Authz** — privileged-path gating, default-deny, role/permission resolution, session lifecycle.
2. **Input validation & encoding** — injection vectors, deserialization, boundary types, encoding at output.
3. **Secret handling** — storage, transit, logs, errors, lifetime, rotation paths.
4. **Cryptography** — primitive, mode, key management, randomness sources, constant-time properties.
5. **Trust boundaries** — where untrusted data enters; where privilege escalates; cross-context flow.
6. **Supply chain** — new deps' license/provenance/transitive surface; pinning discipline; CI integrity.
7. **Sandbox / isolation** — rules added or weakened; tools moved out of sandbox; allowlist additions.
8. **Logging / observability** — PII / secret leakage in logs and errors; audit-trail completeness on privileged paths.
9. **Denial of service** — unbounded allocations, regex backtracking, retry storms, untrusted-input parsers.

**Severity ladder (security)**:

| Severity | Meaning |
|---|---|
| Critical | Exploitable now: auth bypass, secret exposure, RCE, data corruption — MUST fix before merge or revert if shipped |
| High | Material weakening of posture — fix before merge or get explicit risk acceptance |
| Medium | Real concern with workaround or low likelihood — fix or justify |
| Low | Defense-in-depth opportunity — consider |
| Info | Educational note or pattern to highlight |

### Common Discipline (both playbooks)

- **Ask clarifying questions first** when intent is ambiguous — use `AskUserQuestion` per the calling agent's structural contract (absent in team-mode spawns — there route the question through the calling agent instead). Peer SendMessage is the calling agent's job, not this skill's. Do NOT ask when the answer is in the code.
- **Report every finding — do NOT self-filter.** Report each issue you find, including low-severity and uncertain ones, each tagged with the role's severity (classification, not suppression) and a confidence note. Filtering and ranking happen downstream (team-lead step-14 reconciliation / operator), never here — declining to report a found issue because it seems minor is a recall defect. A finding a linter (`cargo clippy` / `cargo audit`) would also catch is reported as a `Suggestion` (general) / `Info` (security), not omitted. The severity ladder ranks; it does not gate what you surface.
- **Honest critique.** Do NOT default to approval. Surface-level fixes that mask root cause are reject-class regardless of role. If the proper fix is out of scope, recommend a follow-up issue rather than approving the surface patch.
- **Stream long commands.** For builds, tests, or scans expected to take >30s, use `Monitor` with an until-loop on a terminal pattern (PASS/FAIL line, exit marker), not a blocking poll.
- **Epistemic discipline in the review body.** Every load-bearing finding cites evidence (file:line, command output, spec section). Banned phrases in findings/praise/recommendations: "clearly," "obviously," "should work," "definitely," "I'm sure," "100%," "guaranteed." Prefer "verified at {file:line}," "ran X — saw Y," "unverified — assumption," or qualify with what was checked vs. assumed. A confident wrong claim is worse than an honest "did not verify."

- **Review evidence gates (both playbooks) — never attribute from a false signal.** Before a load-bearing claim rests on a test result, an empty diff, or a green CI status, rule out the four ways the signal lies:
  - **Sandbox-signature-before-attribution.** Before attributing any test failure to the reviewed diff, check the failure text for sandbox signatures (`operation not permitted`, bind/socket errors) — the sandbox blocks even loopback listeners; only a fresh UNSANDBOXED run is citable as a real failure.
  - **Stale-cached-test-results detection.** A bare test re-run can report a stale `(cached)` OK from someone else's pass — require `-count=1` (or the toolchain's cache-bypass equivalent) before citing a green run as evidence the reviewed code passes.
  - **Empty-diff triage triple.** An empty `git diff` on files whose content demonstrably changed means STAGED or committed, not "no changes" — run `git status --short`, `git diff --staged --stat`, `git log --oneline -3` before concluding, and file unauthorized staging itself as a process finding.
  - **Hollow-green CI detection.** Green CI proves an AC only if the job proves the tests RAN: verify any artifact a ruling depends on is actually committed (`git ls-files <path>` / `git check-ignore -v <path>`), and treat skip-gated suites as hollow-green hazards.

### Hard Gates (Correctness — Blocker-class for `@staff-engineer`, Critical for `@security-engineer`)

Four narrow, mechanically detectable symptoms gate the merge **regardless of feature correctness**. These are the *symptoms* of the broader code-philosophy principles, not the principles themselves — the gate fires only on the objective, self-evaluable check. Judgment calls belong in Concern-class findings under the dimension rubric above; only these four symptoms trigger a hard gate.

| Gate | Symptom (what to look for in the diff) | Override marker |
|---|---|---|
| **G1 — Swallowed error** | A `catch`/`rescue`/`except` block with no rethrow AND no logged context AND no meaningful handling on a path that touches untrusted input, network, or persistence. Patterns: empty catch `{}`; `catch { /* ignore */ }`; discarded result (`_ = err`, `_, _ := ...` for an `error` return); `.unwrap()` / `.expect()` / a bare ! force-unwrap operator on data the function does not control. NOT fired by deliberate panics on programmer-error invariants where a clear stack is the right move. | `// OVERRIDE: code-philosophy/6 — <reason>` on or immediately above the catch/discard site |
| **G2 — Unguarded shared mutation** | Shared or module-global mutable state accessed without a lock, channel, actor, or single-owner pattern. NOT fired by `Mutex`/`RwLock`/atomic-guarded access, message-passing, single-owner goroutines/tasks, or local mutation inside a function whose result escapes as a new value. | `// OVERRIDE: code-philosophy/4 — <reason>` on the unguarded access |
| **G3 — Unparsed boundary input** | Untrusted input (HTTP body/query/header, env var, CLI arg, queue payload, DB row, third-party API response, file off disk) consumed without a schema parse into a precise type at first contact. NOT fired by data flowing through internal calls after it has been parsed once at the boundary; NOT fired by parsed-and-typed data simply being accessed deeper in the call stack. | `// OVERRIDE: code-philosophy/5 — <reason>` on the consumption site |
| **G4 — Surface-not-invariant patch** | Fix that papers over an edge case rather than addressing the underlying contract. Patterns: a `null` check added where the real bug is that upstream data is the wrong shape; a retry loop wrapped around a non-idempotent operation; defensive guards added that mask a real invariant violation instead of fixing it; a snapshot or test updated to make a failing case pass without diagnosing why. Detection requires reading the issue to understand what the code was supposed to *uphold* — flag when the diff looks like symptom-masking. | `// OVERRIDE: code-philosophy/11 — <reason>` on the affected block |
| **G5 — Unexecuted AC regex** | TDD/spec/AC diff introduces or modifies a regex (`grep -E`, `\bword\b`, alternation arms) intended to gate verification, with no evidence the regex was executed against the actual target files. Patterns: AC text says "match `Lifecycle:.*persistent name`" but the target file uses `**Lifecycle**:` (markdown-bold inserts `**` between word and colon); AC requires literal adjacency where target uses intervening words; expected hit count in the AC does not match actual `grep -lE` output; under `grep -E` a `\|` is a LITERAL pipe (BRE alternation), so `'a\|b'` matches the string `a|b` and returns 0 on a correct file — a false-negative; the alternation must be bare `|` under `-E`. Detection: when a diff edits regex in `docs/tdd/` or `docs/spec/`, run `~/.claude/scripts/g5_check.sh <scope>` (the same `<scope>` this skill resolved) — it extracts every added backtick `grep`, executes each against the tree, and reports `[RAN <n> hits]` / `[FAIL]` / `[REJECTED]` / `[TIMEOUT]` per command plus a `[BRE-PIPE-WARNING]` static flag for an escaped `\|` under `-E` (exit 0 all clean, 1 a candidate failed/rejected/warned, 2 no candidates in scope). Compare each reported hit count to the AC's claimed file-set; any count mismatch, exit-1 line, or BRE-pipe warning is a Blocker. | `// OVERRIDE: code-philosophy/5 — <reason>` on the AC block (G5 maps to principle #5, parse-at-the-edge, since AC regex is the verification's parse contract) |

**Override recognition (mandatory).** Before emitting a Blocker for any gate, scan the diff *and* the immediately adjacent lines for an `OVERRIDE: code-philosophy/<id>` comment matching the gate (the language's comment syntax — `//`, `#`, `--`, `;`, etc.). When present:
- Do NOT add a Blocker / Critical finding for that occurrence.
- List the override verbatim under the **Overrides Recognized** section of the report, with file:line and the reason text.
- The override is *surfaced*, not *silently honored* — the operator reads the report and decides whether the reason holds.

**Block means return-for-fix, not discard.** A gate-triggered Blocker names the file/line, the gate (G1..G5), the symptom observed, and the required mitigation. The calling agent routes back to `@senior-engineer` for a fix pass; the diff returns for re-review. Hitting a hard gate is the review system working — surface it loudly.
## Output Contract

Emit the review verbatim to the calling agent's context using the role-specific format below. Do NOT echo the raw diff. Do NOT save to disk. Do NOT add a preamble or trailing notes outside the format. **If the harness blocks this skill's invocation** (Stage-2 auto-mode classifier), render the review directly per THIS format authority — the role's banner heading, every required section in order (for `staff-engineer`: `Overrides Recognized` + `Hard Gates Triggered` G1..G5), and the verdict ladder — never an improvised structure.

### Staff-Engineer Output

For trivial / no-op changes:

```
LGTM - {one line summary}
```

For substantive changes:

```
## Review (general — @staff-engineer)

### Summary
{1-3 sentence description of what changed and why}

### Scope Reviewed
- Source: {PR # / branch / uncommitted / staged / files}
- Files changed: {N} ({git diff --stat one-line summary})
- Tree state: {git rev-parse --short HEAD}[+dirty:<sha12> — `~/.claude/scripts/tree_fingerprint.sh` output (repo: `src/user/claude-code/scripts/tree_fingerprint.sh`) — for uncommitted/staged] — the tree this verdict binds to; a Round-N re-review feeds this recorded fingerprint to `verify_carry_forward.sh` (§Round-N Re-Review) to decide carry-forward.
- Reference docs: {TDDs, specs consulted — or "None applicable"}

### Risk Assessment
- Blast radius: {scope of impact if this regresses}
- Rollback complexity: {trivial / moderate / hard}
- Confidence: {high / medium / low — and why}

### Findings

**Blockers** ({count}):
- {file:line} — {finding} — {recommended fix}
- ... or "None"

**Concerns** ({count}):
- ... or "None"

**Suggestions** ({count}):
- ... or "None"

**Questions** ({count}):
- ... or "None"

**Praise**:
- ... or "None"

**Overrides Recognized** ({count}):
- {file:line} — gate G{1..5} — `OVERRIDE: code-philosophy/{id} — {reason}` (operator decides whether the reason holds)
- ... or "None"

### Hard Gates Triggered
List any of G1..G5 that produced a Blocker in this review (after override recognition). If no gates fired, write "None".

- **G1 (swallowed error):** {file:line — symptom — required mitigation} or "None"
- **G2 (unguarded shared mutation):** {file:line — symptom — required mitigation} or "None"
- **G3 (unparsed boundary input):** {file:line — symptom — required mitigation} or "None"
- **G4 (surface-not-invariant patch):** {file:line — symptom — required mitigation} or "None"
- **G5 (unexecuted AC regex):** {file:line — regex — expected hit count vs actual hit count — required mitigation} or "None"

### Dimension Checklist
| Dimension | Status |
|---|---|
| Architecture | pass / concern / fail / N/A |
| Security (general) | pass / concern / fail / N/A |
| Operations | pass / concern / fail / N/A |
| Performance | pass / concern / fail / N/A |
| Code Quality (12 principles) | pass / concern / fail / N/A |
| Testing | pass / concern / fail / N/A |

### Recommendation
One of: **Approve** / **Approve with follow-up** / **Request changes** / **Block** / **Split required**

### Next Steps
{What the calling agent should do — e.g., route blockers to @senior-engineer, request a vote for a 500+ line change, escalate to operator for re-plan}

Code review emitted ({recommendation}).
```

### Security-Engineer Output

For changes with no security-relevant surface:

```
LGTM (security) - no security-relevant changes
```

For substantive security-relevant changes:

```
## Review (security — @security-engineer)

### Summary
{1-3 sentence security framing of what changed}

### Scope Reviewed
- Source: {PR # / branch / uncommitted / staged / files}
- Files changed: {N} (security-touched paths called out)
- Tree state: {git rev-parse --short HEAD}[+dirty:<sha12>] — same fingerprint and carry-forward rules as the general template above (§Round-N Re-Review)
- Reference docs: {the issue's distilled security contracts, `docs/adr/` security records, docs/spec/security.md sections — or "None applicable"}

### Threat Model (assumed)
- Adversary: {external attacker / curious insider / supply-chain compromise / prompt injection / ...}
- Asset under defense: {credentials / user data / build integrity / runtime isolation / ...}
- Out of scope: {explicit non-threats}

### Risk Assessment
- Blast radius: {what gets compromised}
- Exploit prerequisites: {auth required? remote? local? user interaction?}
- Data sensitivity: {none / low / high / regulated}
- Confidence: {high / medium / low — and why}

### Findings

**Critical** ({count}):
- {file:line} — {finding} — {threat} — {required mitigation}
- ... or "None"

**High** ({count}):
- ... or "None"

**Medium** ({count}):
- ... or "None"

**Low** ({count}):
- ... or "None"

**Info** ({count}):
- ... or "None"

### Required Mitigations
- {numbered list of must-do mitigations before merge — or "None"}

### Dimension Checklist
| Dimension | Status |
|---|---|
| Authn / Authz | pass / concern / fail / N/A |
| Input validation & encoding | pass / concern / fail / N/A |
| Secret handling | pass / concern / fail / N/A |
| Cryptography | pass / concern / fail / N/A |
| Trust boundaries | pass / concern / fail / N/A |
| Supply chain | pass / concern / fail / N/A |
| Sandbox / isolation | pass / concern / fail / N/A |
| Logging / observability | pass / concern / fail / N/A |
| Denial of service | pass / concern / fail / N/A |

### Recommendation
One of: **Approve (security)** / **Approve with follow-up** / **Block (security)** / **Split required**

### Next Steps
{What the calling agent should do — e.g., deliver this verdict to team-lead for step-14 reconciliation (security verdict binds for security findings), surface any security-vs-general track contradiction, escalate to operator if the threat model diverges from the issue's distilled threat contracts, request a vote for residual-risk acceptance. Standalone (no orchestrator): notify the parallel reviewer for unified handoff and route critical/high to @senior-engineer.}

Code review emitted ({recommendation}).
```

### Round-N Re-Review (compact)

On re-invocation against a fixed diff (the dominant call pattern — fix→re-review loops), skip the full template: emit `## Re-Review Round-{N} ({role})` with three sections — **Prior Findings Disposition** (one row per prior Blocker/Concern/Critical/High → `resolved | outstanding | regressed` + evidence), **New Findings (delta only)** (by severity, or "None"), **Recommendation** (role allow-list value), ending with the trailing confirmation line `Code review emitted ({recommendation}).` — the validator requires it under `--mode round-n` too. Revert to the full template if the fix introduces a new Blocker/Critical.

**G5 carry-forward.** A prior-round G5 PASS is reusable without re-running the regex ONLY when `~/.claude/scripts/verify_carry_forward.sh <prior-round Tree state> <current fingerprint> <AC-regex file> <target file …>` (repo: `src/user/claude-code/scripts/verify_carry_forward.sh` — the same script sibling `verify-ac` runs at its Pre-flight §3a) reports `[CARRY-FORWARD]` for EVERY path; it mechanizes both fingerprint components (rev-range `git diff --name-only`, plus hash-equality on `+dirty:<sha12>`). Compute `<current fingerprint>` as `git rev-parse --short HEAD` plus `+dirty:<sha12>` from `~/.claude/scripts/tree_fingerprint.sh` when the tree is dirty. Cite as `G5 PASS — unchanged since round {N}`. Any `[RE-VERIFY]` line (exit 1) means re-run the regex; never carry a prior G5 Blocker forward (re-run it).

## Validation Before Emit

Mechanically validate the drafted review before emitting it. **Do NOT hand-roll `mktemp` or use `$$` across separate Bash calls to stage the draft.** Each Bash tool call is a fresh shell process, so `$$` and any locally-computed temp path are not stable across calls — this is what causes `mktemp: File exists` races, missing trailing-confirmation appends, and "no recognized review banner" failures when staging and linting are split across turns. The SOLE prescribed path is a SINGLE Bash invocation of the shared staging + lint script at the deployed path `~/.claude/scripts/report_stage_lint.sh` (repo: `src/user/claude-code/scripts/report_stage_lint.sh`) — it stages the content to a UNIQUE-per-invocation `mktemp` path under `$TMPDIR` (parallel panel reviewers share one `$TMPDIR`; a fixed name races), then runs `~/.claude/scripts/report_lint.py` against the staged copy, all within that one call:

```
~/.claude/scripts/report_stage_lint.sh code-review-verdict [--mode round-n] "$DRAFT_FILE"
```

(or pipe the review body on stdin and omit `$DRAFT_FILE`). Omit `--mode` (default `full`) for the full general/security template; pass `--mode round-n` for a compact Re-Review emission. Handle the exit code DISTINCTLY (identical semantics to a direct `report_lint.py` invocation):

- **exit 0** — emit the review in the calling agent's context.
- **exit 1 (validation failure)** — ABORT. The calling agent corrects in its own context (quoting the script's stderr) and re-invokes `Skill(code-review-verdict, "<scope>")`:
  ```
  Error: validation failed: {section/field} — {detail}.
  ```
- **exit 2 (infra/usage — script or `report_lint.py` missing, `$TMPDIR` unwritable, unreadable staging file)** — do NOT hard-block. Emit the review anyway with the mandatory annotation line `lint not run (infra: {reason})` appended after the trailing confirmation line, and flag the infra failure to the caller. An advisory verdict a human/team-lead consumes downstream must not be suppressed by a lint-infrastructure hiccup.

The validator mechanizes the shared, text-decidable checks: heading matches the role's banner, required sections present in order (Round-N compact template under `--mode round-n`), severity ladder matches role, empty severity buckets explicit (general role includes the `Overrides Recognized` bucket in this check), recommendation on the role's allow-list, trailing confirmation line present, placeholder scan, banned-confidence-phrase scan (scoped to Findings/Praise/Recommendation), the report-internal hard-gate arm (a Blocker citing G1..G5 must cross-list that gate under `Hard Gates Triggered`), and `Hard Gates Triggered` enumeration (all five gates G1..G5 listed individually, even when None).

Two checks stay the calling agent's responsibility — they need Pre-flight diff state the review text does not carry:

- **Override recognition (verbatim-match arm)** — if an `OVERRIDE: code-philosophy/<id>` comment is present in the diff for an otherwise-gated symptom, that occurrence MUST appear in `Overrides Recognized` (verbatim text + file:line) AND must NOT appear as a Blocker for the same gate. Silent honoring of an override is a defect. (The bucket's mere presence — empty vs itemized — is validator-mechanized above; only the diff-cross-referenced verbatim match stays here.)
- **Citation-presence scan** — before emitting, cross-check every `file:line` cited in a Finding against the resolved scope's file list (captured at Pre-flight step 4); a cited path absent from that list is a fabricated-verification defect ("VERIFIED" for a hunk that does not exist). Do NOT emit such a finding: re-derive it from the file's real diff, or drop it and say so. Not yet mechanized — the linter never sees the file list.

## Save & Return

No file is written (Output Contract owns the emission rules). End with the confirmation line:

```
Code review emitted ({recommendation}).
```

where `{recommendation}` is the role's recommendation value (e.g., `Approve`, `Block`, `Block (security)`, `Split required`).

**Self-check before ending the turn**: the calling agent MUST self-check — "Did I SendMessage the verdict (structured, not summarized) this same turn?" (under team-lead orchestration, to team-lead — who reconciles per step 14; standalone, to whoever requested the review). The skill's in-context emission is the calling agent's working artifact, not the deliverable; the deliverable is the SendMessage. A silent turn after `Code review emitted (...)` is silent-completion — the dominant defect class across this skill family (`code-review-verdict`, `verify-ac`, `design-review`, `design-qa`).

The calling agent owns (in order):

- **Deliver the verdict to team-lead; reconciliation is team-lead's, not yours.** Under team-lead orchestration, team-lead reconciles the parallel verdicts per its step 14 (any Blocker blocks; security verdict binds for security findings) and prevents contradictory handoffs to `@senior-engineer`. Do NOT SendMessage the counterpart (`@security-engineer` ↔ `@staff-engineer`) for alignment before delivery (anti-anchoring — rationale owned by team-lead.md step 14). (Standalone, no orchestrator: reconcile directly with the parallel reviewer if one was run.)
- Routing blockers / concerns / critical / high findings — under orchestration, carry them in the verdict body to team-lead (team-lead routes them to the `impl-{DOCKET-ID}-fix-{N}` ephemeral; reviewers never SendMessage `@senior-engineer` directly, per the team-lead spawn templates). Standalone: SendMessage `@senior-engineer` with file/finding/fix triplets.
- Reporting outcomes to team-lead / operator with appropriate cc per the agent's Proactive Communication triggers.
- Escalating to vote if the review meets a vote-criticality threshold (500+ lines, security-critical surface, breaking-change plan, residual-risk acceptance) — standalone: `Skill(vote, ...)`; team mode: NEVER `Skill(vote)` (nests a team) — `docket vote create` + `delegation_request` to team-lead per the calling agent's Consensus Voting section (`~/.claude/agents/staff-engineer.md` / `~/.claude/agents/security-engineer.md`). When escalating, map this skill's Recommendation to the vote verdict per the table below; pass the structured Findings as `--findings-json` to preserve severity buckets through `docket vote cast`.

### Recommendation → Vote Verdict Map

| This skill's Recommendation | Vote verdict (for `docket vote cast -v`) |
|---|---|
| Approve / Approve (security) | `approve` |
| Approve with follow-up | `approve-with-concerns` |
| Request changes | `approve-with-concerns` (with explicit Concerns in findings) |
| Block / Block (security) | `reject` |
| Split required | Do NOT escalate to vote — return Split-required to caller and let them re-scope before any vote |