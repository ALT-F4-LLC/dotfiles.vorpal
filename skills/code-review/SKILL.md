---
name: code-review
description: >
  Conduct a code review on a scoped artifact (PR, branch, uncommitted, staged, or files).
  Loaded into the calling agent's context; the calling agent applies the role-appropriate
  playbook — @staff-engineer runs the 6-dimension general review, @security-engineer runs
  the security-dimension review. The format authority for both roles' output lives here.
  Trigger: "code review", "review this PR", "review the diff", "security review of changes".
argument-hint: "<scope — PR#, branch, uncommitted, staged, or path [path …]>"
effort: max
allowed-tools: ["AskUserQuestion", "Bash", "Glob", "Grep", "Read", "Monitor"]
---

<!-- CANONICAL:BANNER:BEGIN -->
> **CRITICAL:** (1) Do NOT commit ANY changes (no `git add`, no `git commit`, no `git push`) unless EXPLICITLY instructed by the user. (2) This is a leaf skill. You MUST NOT spawn sub-agents, invoke `Skill()` recursively, or use `Agent()`, `TeamCreate`, `TeamDelete`, or `SendMessage`. The calling agent handles peer messaging and consensus follow-ups after this skill returns.
<!-- CANONICAL:BANNER:END -->

# Code Review — Conduct a Role-Scoped Review

You are the **Reviewer**. You conduct a code review on the artifact named by `<scope>` and emit a structured report back to the calling agent's context. No file is written. The review is role-aware: `@staff-engineer` applies the general 6-dimension playbook; `@security-engineer` applies the security-dimension playbook. The format authority — dimensions, severity ladders, output sections, validation rules — lives here.

## Role Detection

This skill is callable ONLY by `@staff-engineer` or `@security-engineer`. Match the calling agent's identifier (from prompt context) to a role; if neither matches, ABORT.

| Caller identifier | Role |
|---|---|
| `@staff-engineer` | `staff-engineer` |
| `@security-engineer` | `security-engineer` |

Abort message:

```
Error: Skill(code-review) is restricted to @staff-engineer and @security-engineer. Calling agent: {agent}.
```

## Argument Handling

The argument is a single positional `<scope>` (free-text). No flags.

If `<scope>` is missing or empty:

```
Error: Usage: Skill(code-review, "<scope>") — name what to review (PR number/URL, branch, "uncommitted", "staged", or file paths).
```

**Scope resolution** (apply rules in order; first match wins):

| Form | Detection | Diff source |
|---|---|---|
| GitHub PR number | matches `^\d+$` | `gh pr view {n}` (description) + `gh pr diff {n}` (diff) |
| GitHub PR URL | contains `/pull/` | extract `n`; same as PR number |
| Branch name | `git rev-parse --verify {scope}` exits 0 | `git diff main...{scope}` + `git log main...{scope} --oneline` + `git diff --stat main...{scope}` |
| Literal `uncommitted` | exact match | `git diff` + `git diff --staged` + `git diff --stat HEAD` |
| Literal `staged` | exact match | `git diff --staged` + `git diff --stat --staged` |
| File paths (one or more, space-separated) | every token resolves via `Bash test -e {path}` | `Read` each file directly |

**Path-list normalization (canonical grammar).** The canonical multi-file form is bare space-separated paths — `Skill(code-review, "src/a.rs tests/b.rs")`. Before applying the table, strip a leading `files`/`files:` keyword if present, then split the argument on commas and/or whitespace; resolve the resulting tokens via the File paths row. This collapses the three observed call forms — `path path`, `files path path`, `files: path, path` — to one token list. (Single bare tokens are unaffected: no prefix, no comma, so branch/PR detection still wins per the table order.)

**Ambiguity rules** (apply when multiple forms could match):

- A token matching `^\d+$` always tries PR-number first via `gh pr view {n} --json number`. If `gh` exits non-zero (no such PR), fall through to branch detection. If both fail, fall through to file-path detection only when the token is a real path.
- A single token that is BOTH a valid branch name AND an existing file is treated as a branch. To force file-path scope on such a name, supply multiple tokens or prefix with `./` (e.g., `./main`).

If `<scope>` matches none of the above, ABORT:

```
Error: Could not resolve <scope>: '{scope}'. Expected PR number/URL, branch name, "uncommitted", "staged", or existing file paths.
```

If extra positional args follow `<scope>`, ignore them silently.

## When to Use

- The calling agent (`@staff-engineer` or `@security-engineer`) is performing a code review at any scope (PR, branch, uncommitted, staged, files).
- The team-lead Implementation Phase delegates review to the persistent advisor, who invokes this skill to produce the format-correct verdict.
- **Re-invocation after fix is expected** — the dominant call pattern is fix→re-review loops on the same scope (PR# first, then `uncommitted` once the fix lands locally). Emit the compact Round-N format (see Output Contract → Round-N Re-Review), not a fresh full sweep, unless new code introduces new risk.

## Doubling Rule (under team-lead orchestration)

When invoked under team-lead orchestration, code review defaults to a **single** reviewer — the persistent `advisor` via SendMessage, no ephemeral spawn — per `agents/team-lead.md` Rule 8; the single verdict is final. **Opt up to a doubled panel** when a Rule 8 trigger fires (TDD secondary review, security-sensitive surface, diff ≥500 LOC, or operator flag): routine general review then runs `advisor` + ephemeral `reviewer-2`; security-sensitive review runs `advisor` + `reviewer-2` + `security-advisor` + ephemeral `security-reviewer-2` (4 parallel). Each reviewer invokes this skill independently and emits its own structured report — this skill remains the single-reviewer output-format authority; team-lead reconciles the parallel verdicts per its step 14.

**Ephemeral lifecycle.** `reviewer-2` and `security-reviewer-2` are ephemeral instances — they emit `shutdown_request` immediately after delivering their verdict. Persistent advisors (`advisor`, `security-advisor`) stay idle between phases by design.

**Degraded fallback.** If an ephemeral peer reviewer fails twice (probe-once + respawn both abort or return empty), team-lead falls back to the persistent advisor's verdict alone AND prefixes the consolidated verdict header verbatim `DEGRADED: single-reviewer (ephemeral failed 2×)` so the operator sees the degradation explicitly. Outside team-lead orchestration, doubling is at the calling agent's discretion.

## When NOT to Use

<!-- COUPLING: this skill is part of the report-emission family (code-review, verify-ac, design-qa, design-review). The "When NOT to Use" delegation routes below MUST stay in sync across the family — update all 4 in lockstep when adding/removing a sibling skill. -->
- Authoring TDDs, ADRs, PRDs, or UX specs — use `Skill(tdd, ...)`, `Skill(adr, ...)`, `Skill(prd, ...)`, `Skill(ux-spec, ...)`.
- Multi-agent consensus voting on an artifact — use `Skill(vote, ...)`. After this skill produces a review, the calling agent decides whether the change meets a vote-criticality trigger (500+ lines, security-critical surfaces, breaking-change plans) and delegates accordingly.
- Acceptance-criteria verification against a Docket issue — use `Skill(verify-ac, ...)`, callable by `@sdet`.
- Design QA against a `docs/ux/` spec for shipped user-facing surfaces — use `Skill(design-qa, ...)`, callable by `@ux-designer`.
- Peer design review of a draft UX spec or design proposal — use `Skill(design-review, ...)`, callable by `@ux-designer`.
- Plan/scope/dependency review on a Docket plan — handled inline by the calling agent's advisory output.

## Pre-flight

1. **Detect role** per Role Detection. ABORT if invalid.
2. **Resolve `<scope>`** per Argument Handling. ABORT if unresolvable.
3. **Resolve context**: `{role}` = the detected role (`staff-engineer` or `security-engineer`).
4. **Gather artifact context** per the resolved scope's diff source. Capture the file list (`git diff --stat` or PR file list) before reading bodies — this drives triage. **If the file count exceeds 50, surface a one-line summary first** (`{N} files, {lines} lines — recommend Split required unless author confirms cohesive scope`) so the calling agent can escalate before deep review effort is wasted.
5. **Empty-diff guard**: if the resolved diff is empty (no file changes), ABORT:

   ```
   Error: Resolved scope produced an empty diff — nothing to review.
   ```
6. **Read related design docs** — scope reads to what the diff touches; do not read specs outside the changed-file paths:
   - `staff-engineer`: TDDs in `docs/tdd/`; project specs in `docs/spec/` matching changed areas, where present (`architecture.md`, `performance.md`, `testing.md`).
   - `security-engineer`: security TDDs in `docs/tdd/`, security ADRs in `docs/tdd/adr/`, `docs/spec/security.md`.

## Review Procedure

**Triage first.** Scale effort to risk. Trivial changes (README typo, version bump on a stable dep, cosmetic-only diff) get a one-line acknowledgment per the Output Contract. Substantive changes get the full role-specific dimension sweep. For 500+ line diffs, focus on the 20% of code carrying 80% of risk first; recommend a split if scope mixes independent concerns or risk levels.

**Finding-sourcing discipline (anti-fabrication — load-bearing).** Write each per-file finding ONLY from that file's COMPLETE diff rendered in a clean call this turn — never from memory of "what this kind of change usually does," and never from a cancelled or empty batch result. If a parallel batch member errors (e.g. a sandbox-denied `> $TMPDIR/...` redirect), the harness CANCELS every later call in that batch; an empty/cancelled result means the file is UNVERIFIED, not unchanged — re-issue the probe as a solo call before asserting anything about it. Prefer `git diff` / `Read` over `grep -n` for load-bearing verification (`grep -n` has returned wrong line content). Never carry an expected-change guess forward as a "verified" finding; an evidence-anchored line that is actually fabricated ("VERIFIED from real diff" for a hunk that does not exist) is worse than an honest "did not verify."

### Staff-Engineer Playbook

Apply the **6 dimensions**, weighted by what the change touches. Mark unaffected dimensions `N/A` in the checklist:

1. **Architecture** — pattern fit, module boundaries, dependency direction, second-order effects, cross-cutting impact, precedent set.
2. **Security (general posture)** — input boundaries, error-path safety, default-deny defaults, accidental privilege escalation. Auth/secret/crypto/sandbox specifics defer to the parallel `@security-engineer` review when one is running; if a routine staff review surfaces such specifics and no parallel review is in flight, flag the finding as a Concern with `Next Steps` instructing the calling agent to SendMessage `@security-engineer` for a dedicated security pass before merge.
3. **Operations** — observability hooks, runbook impact, deploy/rollback story, 3am-diagnosability, configuration footprint.
4. **Performance** — algorithmic complexity, N+1 patterns, allocation hotspots, latency-budget impact, regression risk.
5. **Code Quality** — apply the 12 code-philosophy principles per `agents/senior-engineer.md` → Code Quality & Craftsmanship (format authority). Four principles carry mechanical Hard Gates enforced below: **#4 mutation locality** (G2), **#5 parse at the edge** (G3), **#6 error propagation** (G1), **#11 invariant over surface** (G4). The other eight (#1 abstraction, #2 names, #3 cohesion-over-length, #7 comments-justify, #8 tests-pin-behavior, #9 minimal-diff, #10 dep-posture, #12 deletability) belong to the Concern/Suggestion rubric — apply per touched file.
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

### Common Discipline (both roles)

- **Ask clarifying questions first** when intent is ambiguous — use `AskUserQuestion` per the calling agent's structural contract. Peer SendMessage is the calling agent's job, not this skill's. Do NOT ask when the answer is in the code.
- **Calibrate to value.** Comment on real risks and pattern violations. Skip stylistic preferences and what `cargo clippy` / `cargo audit` should catch automatically.
- **Honest critique.** Do NOT default to approval. Surface-level fixes that mask root cause are reject-class regardless of role. If the proper fix is out of scope, recommend a follow-up issue rather than approving the surface patch.
- **Stream long commands.** For builds, tests, or scans expected to take >30s, use `Monitor` with an until-loop on a terminal pattern (PASS/FAIL line, exit marker), not a blocking poll.
- **Epistemic discipline in the review body.** Every load-bearing finding cites evidence (file:line, command output, spec section). Banned phrases in findings/praise/recommendations: "clearly," "obviously," "should work," "definitely," "I'm sure," "100%," "guaranteed." Prefer "verified at {file:line}," "ran X — saw Y," "unverified — assumption," or qualify with what was checked vs. assumed. A confident wrong claim is worse than an honest "did not verify."

### Hard Gates (Correctness — Blocker-class for `@staff-engineer`, Critical for `@security-engineer`)

Four narrow, mechanically detectable symptoms gate the merge **regardless of feature correctness**. These are the *symptoms* of the broader code-philosophy principles, not the principles themselves — the gate fires only on the objective, self-evaluable check. Judgment calls belong in Concern-class findings under the dimension rubric above; only these four symptoms trigger a hard gate.

| Gate | Symptom (what to look for in the diff) | Override marker |
|---|---|---|
| **G1 — Swallowed error** | A `catch`/`rescue`/`except` block with no rethrow AND no logged context AND no meaningful handling on a path that touches untrusted input, network, or persistence. Patterns: empty catch `{}`; `catch { /* ignore */ }`; discarded result (`_ = err`, `_, _ := ...` for an `error` return); `.unwrap()` / `.expect()` / `!` on data the function does not control. NOT fired by deliberate panics on programmer-error invariants where a clear stack is the right move. | `// OVERRIDE: code-philosophy/6 — <reason>` on or immediately above the catch/discard site |
| **G2 — Unguarded shared mutation** | Shared or module-global mutable state accessed without a lock, channel, actor, or single-owner pattern. NOT fired by `Mutex`/`RwLock`/atomic-guarded access, message-passing, single-owner goroutines/tasks, or local mutation inside a function whose result escapes as a new value. | `// OVERRIDE: code-philosophy/4 — <reason>` on the unguarded access |
| **G3 — Unparsed boundary input** | Untrusted input (HTTP body/query/header, env var, CLI arg, queue payload, DB row, third-party API response, file off disk) consumed without a schema parse into a precise type at first contact. NOT fired by data flowing through internal calls after it has been parsed once at the boundary; NOT fired by parsed-and-typed data simply being accessed deeper in the call stack. | `// OVERRIDE: code-philosophy/5 — <reason>` on the consumption site |
| **G4 — Surface-not-invariant patch** | Fix that papers over an edge case rather than addressing the underlying contract. Patterns: a `null` check added where the real bug is that upstream data is the wrong shape; a retry loop wrapped around a non-idempotent operation; defensive guards added that mask a real invariant violation instead of fixing it; a snapshot or test updated to make a failing case pass without diagnosing why. Detection requires reading the issue/TDD to understand what the code was supposed to *uphold* — flag when the diff looks like symptom-masking. | `// OVERRIDE: code-philosophy/11 — <reason>` on the affected block |
| **G5 — Unexecuted AC regex** | TDD/spec/AC diff introduces or modifies a regex (`grep -E`, `\bword\b`, alternation arms) intended to gate verification, with no evidence the regex was executed against the actual target files. Patterns: AC text says "match `Lifecycle:.*persistent name`" but the target file uses `**Lifecycle**:` (markdown-bold inserts `**` between word and colon); AC requires literal adjacency where target uses intervening words; expected hit count in the AC does not match actual `grep -lE` output. Detection: when a diff edits regex in `docs/tdd/` or `docs/spec/`, the reviewer MUST run the regex against the named target files and compare hit count to the AC's claimed file-set. A mismatch is a Blocker. | `// OVERRIDE: code-philosophy/5 — <reason>` on the AC block (G5 maps to principle #5, parse-at-the-edge, since AC regex is the verification's parse contract) |

**Override recognition (mandatory).** Before emitting a Blocker for any gate, scan the diff *and* the immediately adjacent lines for an `OVERRIDE: code-philosophy/<id>` comment matching the gate (the language's comment syntax — `//`, `#`, `--`, `;`, etc.). When present:
- Do NOT add a Blocker / Critical finding for that occurrence.
- List the override verbatim under the **Overrides Recognized** section of the report, with file:line and the reason text.
- The override is *surfaced*, not *silently honored* — the operator reads the report and decides whether the reason holds.

**Block means return-for-fix, not discard.** A gate-triggered Blocker names the file/line, the gate (G1..G5), the symptom observed, and the required mitigation. The calling agent routes back to `@senior-engineer` for a fix pass; the diff returns for re-review. Hitting a hard gate is the review system working — surface it loudly.
## Output Contract

Emit the review verbatim to the calling agent's context using the role-specific format below. Do NOT echo the raw diff. Do NOT save to disk. Do NOT add a preamble or trailing notes outside the format.

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
- {file:line} — gate G{1..4} — `OVERRIDE: code-philosophy/{id} — {reason}` (operator decides whether the reason holds)
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
- Reference docs: {security TDD, security ADRs, docs/spec/security.md sections — or "None applicable"}

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
{What the calling agent should do — e.g., deliver this verdict to team-lead for step-14 reconciliation (security verdict binds for security findings), surface any security-vs-general track contradiction, escalate to operator if the threat model diverges from the TDD, request a vote for residual-risk acceptance. Standalone (no orchestrator): notify the parallel reviewer for unified handoff and route critical/high to @senior-engineer.}
```

### Round-N Re-Review (compact)

On re-invocation against a fixed diff (the dominant call pattern — fix→re-review loops), skip the full template: emit `## Re-Review Round-{N} ({role})` with three sections — **Prior Findings Disposition** (one row per prior Blocker/Concern/Critical/High → `resolved | outstanding | regressed` + evidence), **New Findings (delta only)** (by severity, or "None"), **Recommendation** (role allow-list value). Revert to the full template if the fix introduces a new Blocker/Critical.

## Validation Before Emit

Before emitting the structured review, verify in the calling agent's context:

1. **Heading matches the role's banner** per the Output Contract.
2. **Every section in the role's template is present, in order** — see Output Contract for the full list. For `staff-engineer`, this includes the `Overrides Recognized` section and the `Hard Gates Triggered` section (each gate G1..G5 listed individually, even if "None"). **Round-N exception:** a compact Re-Review emission validates against its three-section template (Prior Findings Disposition, New Findings, Recommendation) instead.
3. **Severity ladder matches role** — `staff-engineer` uses Blocker / Concern / Suggestion / Question / Praise; `security-engineer` uses Critical / High / Medium / Low / Info. Cross-mixing is a defect.
4. **Hard gate consistency** — if a Blocker is emitted citing G1..G5, the same gate MUST appear in the `Hard Gates Triggered` section with the file:line and required mitigation. If an `OVERRIDE: code-philosophy/<id>` comment is present in the diff for an otherwise-gated symptom, that occurrence MUST appear in `Overrides Recognized` (verbatim text + file:line) AND must NOT appear as a Blocker for the same gate. Silent honoring of an override is a defect.
5. **Empty severity buckets explicit** — every bucket reads `None` or lists items. Silent omission is a defect.
6. **Recommendation is on the role's allow-list** — staff: Approve / Approve with follow-up / Request changes / Block / Split required; security: Approve (security) / Approve with follow-up / Block (security) / Split required.
7. **Placeholder scan** — body contains no literal `{file:line}`, `{count}`, `{scope}`, `TBD`, or `TODO` text outside of code-fenced examples.
8. **Trailing confirmation line present** — emission ends with `Code review emitted ({recommendation}).` where `{recommendation}` is on the role's allow-list.
9. **Epistemic discipline scan** — no banned confidence phrases ("clearly," "obviously," "should work," "definitely," "100%," "guaranteed") in Findings, Praise, or Recommendation. Use evidence-anchored language instead. A hit is a defect.

If any check fails, ABORT:

```
Error: validation failed: {section/field} — {detail}.
```

The calling agent corrects in its own context and re-invokes `Skill(code-review, "<scope>")`.

## Save & Return

No file is written (Output Contract owns the emission rules). End with the confirmation line:

```
Code review emitted ({recommendation}).
```

where `{recommendation}` is the role's recommendation value (e.g., `Approve`, `Block`, `Block (security)`, `Split required`).

**The trailing confirmation line is NOT the deliverable.** The deliverable is the SendMessage to team-lead (the calling agent) carrying the structured verdict body — the in-context emission is only the working artifact. Before ending the turn that invoked this skill, the calling agent MUST self-check: *Did I SendMessage the verdict this same turn?* If no, the turn is incomplete. Silent-completion is the dominant defect class across this skill family (`code-review`, `verify-ac`, `design-review`, `design-qa`).

The calling agent owns (in order):

- **Deliver the verdict to team-lead; reconciliation is team-lead's, not yours.** Under team-lead orchestration, team-lead reconciles the parallel verdicts per its step 14 (any Blocker blocks; security verdict binds for security findings) and prevents contradictory handoffs to `@senior-engineer`. Do NOT SendMessage the counterpart (`@security-engineer` ↔ `@staff-engineer`) for alignment before delivery — eager parallel dispatch is anti-anchoring, and pre-delivery cross-talk lets one reviewer anchor the other's verdict. (Standalone, no orchestrator: reconcile directly with the parallel reviewer if one was run.)
- Routing blockers / concerns / critical / high findings — under orchestration, carry them in the verdict body to team-lead (team-lead routes them to the `impl-{DOCKET-ID}-fix-{N}` ephemeral; reviewers never SendMessage `@senior-engineer` directly, per the team-lead spawn templates). Standalone: SendMessage `@senior-engineer` with file/finding/fix triplets.
- Reporting outcomes to team-lead / operator with appropriate cc per the agent's Proactive Communication triggers.
- Triggering `Skill(vote, ...)` if the review meets a vote-criticality threshold (500+ lines, security-critical surface, breaking-change plan, residual-risk acceptance). When escalating, map this skill's Recommendation to the vote verdict per the table below; pass the structured Findings as `--findings-json` to preserve severity buckets through `docket vote cast`.

### Recommendation → Vote Verdict Map

| This skill's Recommendation | Vote verdict (for `docket vote cast -v`) |
|---|---|
| Approve / Approve (security) | `approve` |
| Approve with follow-up | `approve-with-concerns` |
| Request changes | `approve-with-concerns` (with explicit Concerns in findings) |
| Block / Block (security) | `reject` |
| Split required | Do NOT escalate to vote — return Split-required to caller and let them re-scope before any vote |

## Failure Modes

Most abort paths are specified inline (Argument Handling, Role Detection, Pre-flight, Validation Before Emit). The table covers only abort paths with new abort text:

| Trigger | Handling |
|---|---|
| `gh` CLI unavailable for a PR scope | Abort: `Error: gh CLI required to resolve PR scope. Re-invoke with the branch name or "uncommitted".` |
