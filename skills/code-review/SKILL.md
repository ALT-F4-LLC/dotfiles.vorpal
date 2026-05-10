---
name: code-review
description: >
  Conduct a code review on a scoped artifact (PR, branch, uncommitted, staged, or files).
  Loaded into the calling agent's context; the calling agent applies the role-appropriate
  playbook — @staff-engineer runs the 6-dimension general review, @security-engineer runs
  the security-dimension review. The format authority for both roles' output lives here.
  Trigger: "code review", "review this PR", "review the diff", "security review of changes".
argument-hint: "<scope>"
effort: max
allowed-tools: ["AskUserQuestion", "Bash", "Glob", "Grep", "Read", "Monitor"]
---

<!-- CANONICAL:BANNER:BEGIN -->
> **CRITICAL:** (1) Do NOT commit ANY changes (no `git add`, no `git commit`, no `git push`) unless EXPLICITLY instructed by the user. (2) This is a leaf skill. You MUST NOT spawn sub-agents, invoke `Skill()` recursively, or use `Agent()`, `TeamCreate`, `TeamDelete`, or `SendMessage`. The calling agent handles peer messaging and consensus follow-ups after this skill returns.
<!-- CANONICAL:BANNER:END -->

# Code Review — Conduct a Role-Scoped Review

You are the **Reviewer**. You conduct a code review on the artifact named by `<scope>` and emit a structured report back to the calling agent's context. No file is written. The review is role-aware: `@staff-engineer` applies the general 6-dimension playbook; `@security-engineer` applies the security-dimension playbook. The format authority — dimensions, severity ladders, output sections, validation rules — lives here.

## Role Detection

This skill is callable ONLY by `@staff-engineer` or `@security-engineer`. Map the calling agent's identifier (from prompt context) to a role using the table below; if no row matches, ABORT.

| Caller identifier matches | Role |
|---|---|
| `@staff-engineer`, `staff-advisor`, `advisor`, `tdd-author`, `reviewer` | `staff-engineer` |
| `@security-engineer`, `security-advisor`, `security-reviewer` | `security-engineer` |

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

If `<scope>` matches none of the above, ABORT:

```
Error: Could not resolve <scope>: '{scope}'. Expected PR number/URL, branch name, "uncommitted", "staged", or existing file paths.
```

If extra positional args follow `<scope>`, ignore them silently.

## When to Use

- The calling agent (`@staff-engineer` or `@security-engineer`) is performing a code review at any scope (PR, branch, uncommitted, staged, files).
- The team-lead Implementation Phase delegates review to the persistent advisor, who invokes this skill to produce the format-correct verdict.
- Security-sensitive changes: BOTH advisors invoke this skill in parallel — each in their own role. The two reviews scope to different dimensions and do not duplicate work; team-lead reconciles the verdicts.

## When NOT to Use

- Authoring TDDs, ADRs, PRDs, or UX specs — use `Skill(tdd, ...)`, `Skill(adr, ...)`, `Skill(prd, ...)`, `Skill(ux-spec, ...)`.
- Multi-agent consensus voting on an artifact — use `Skill(vote, ...)`. After this skill produces a review, the calling agent decides whether the change meets a vote-criticality trigger (500+ lines, security-critical surfaces, breaking-change plans) and delegates accordingly.
- Test verification or acceptance-criteria checking — that's `@sdet`'s role, not a skill.
- Plan/scope/dependency review on a Docket plan — handled inline by the calling agent's advisory output.

## Pre-flight

1. **Detect role** per Role Detection. ABORT if invalid.
2. **Resolve `<scope>`** per Argument Handling. ABORT if unresolvable.
3. **Resolve context**:
   - `{today_date}` = `Bash date +%Y-%m-%d`.
   - `{role}` = the detected role (`staff-engineer` or `security-engineer`).
4. **Gather artifact context** per the resolved scope's diff source. Capture the file list (`git diff --stat` or PR file list) before reading bodies — this drives triage.
5. **Read related design docs** (both roles):
   - `staff-engineer`: relevant TDDs in `docs/tdd/`, project specs in `docs/spec/` matching the changed files' areas (architecture, code-quality, testing, operations, performance).
   - `security-engineer`: security TDDs in `docs/tdd/`, security ADRs in `docs/tdd/adr/`, `docs/spec/security.md`.
   Use `Grep` over the changed-file paths to find authoritative references; do not invent.
6. **Empty-diff guard**: if the resolved diff is empty (no file changes), ABORT:

   ```
   Error: Resolved scope produced an empty diff — nothing to review.
   ```

## Review Procedure

**Triage first.** Scale effort to risk. Trivial changes (README typo, version bump on a stable dep, cosmetic-only diff) get a one-line acknowledgment per the Output Contract. Substantive changes get the full role-specific dimension sweep. For 500+ line diffs, focus on the 20% of code carrying 80% of risk first; recommend a split if scope mixes independent concerns or risk levels.

### Staff-Engineer Playbook

Apply the **6 dimensions**, weighted by what the change touches. Mark unaffected dimensions `N/A` in the checklist:

1. **Architecture** — pattern fit, module boundaries, dependency direction, second-order effects, cross-cutting impact, precedent set.
2. **Security (general posture)** — input boundaries, error-path safety, default-deny defaults, accidental privilege escalation. Auth/secret/crypto/sandbox specifics defer to the parallel security review.
3. **Operations** — observability hooks, runbook impact, deploy/rollback story, 3am-diagnosability, configuration footprint.
4. **Performance** — algorithmic complexity, N+1 patterns, allocation hotspots, latency-budget impact, regression risk.
5. **Code Quality** — readability, naming, error-handling discipline, dead code, test factoring, duplication.
6. **Testing** — coverage of acceptance criteria, edge-case discipline, regression coverage, test fragility, what's untested and why.

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

- **Ask clarifying questions first** when intent is ambiguous. Use `AskUserQuestion`. Peer SendMessage is the calling agent's job, not this skill's. Do NOT ask when the answer is in the code.
- **Calibrate to value.** Comment on real risks and pattern violations. Skip stylistic preferences and what `cargo clippy` / `cargo audit` should catch automatically.
- **Honest critique.** Do NOT default to approval. Surface-level fixes that mask root cause are reject-class regardless of role. If the proper fix is out of scope, recommend a follow-up issue rather than approving the surface patch.
- **Stream long commands.** For builds, tests, or scans expected to take >30s, use `Monitor` with an until-loop on a terminal pattern (PASS/FAIL line, exit marker), not a blocking poll.

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

### Dimension Checklist
| Dimension | Status |
|---|---|
| Architecture | pass / concern / fail / N/A |
| Security (general) | pass / concern / fail / N/A |
| Operations | pass / concern / fail / N/A |
| Performance | pass / concern / fail / N/A |
| Code Quality | pass / concern / fail / N/A |
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
{What the calling agent should do — e.g., notify @staff-engineer of the parallel verdict for unified handoff, route critical/high to @senior-engineer, escalate to operator if threat model diverges from TDD, request a vote for residual-risk acceptance}
```

## Validation Before Emit

Before emitting the structured review, verify in the calling agent's context:

1. **Role banner correct** — heading reads `## Review (general — @staff-engineer)` for `staff-engineer` role, or `## Review (security — @security-engineer)` for `security-engineer` role. Trivial-change variants (`LGTM`, `LGTM (security)`) skip the banner check.
2. **All required sections present** for the chosen format — Summary, Scope Reviewed, Risk Assessment (and Threat Model for security), Findings (every severity bucket), Dimension Checklist, Recommendation, Next Steps.
3. **Severity ladder matches role** — `staff-engineer` uses Blocker / Concern / Suggestion / Question / Praise; `security-engineer` uses Critical / High / Medium / Low / Info. Cross-mixing is a defect.
4. **Empty severity buckets explicit** — every bucket reads `None` or lists items. Silent omission is a defect.
5. **Recommendation is on the role's allow-list** — staff: Approve / Approve with follow-up / Request changes / Block / Split required; security: Approve (security) / Approve with follow-up / Block (security) / Split required.
6. **Placeholder scan** — body contains no literal `{file:line}`, `{count}`, `{role}`, `{scope}`, `TBD`, or `TODO` text outside of code-fenced examples.

If any check fails, ABORT:

```
Error: validation failed: {section/field} — {detail}.
```

The calling agent corrects in its own context and re-invokes `Skill(code-review, "<scope>")`.

## Save & Return

This skill does NOT write a file. After Validation Before Emit passes, emit the structured review verbatim to the calling agent's context, then end. The calling agent owns:

- Routing blockers / concerns / critical / high to `@senior-engineer` via SendMessage.
- Notifying the parallel reviewer (`security-engineer` ↔ `staff-engineer`) for verdict reconciliation on security-sensitive changes.
- Reporting outcomes to team-lead / operator with appropriate cc per the agent's Proactive Communication triggers.
- Triggering `Skill(vote, ...)` if the review meets a vote-criticality (500+ lines, security-critical, breaking-change plan, residual-risk acceptance).

On any abort during Pre-flight, Review Procedure, or Validation Before Emit: emit `Error: {one-line cause}` and end without producing a review.

## Failure Modes

| Trigger | Handling |
|---|---|
| `<scope>` missing or empty | Abort: `Error: Usage: Skill(code-review, "<scope>") — name what to review (PR number/URL, branch, "uncommitted", "staged", or file paths).` |
| Calling agent is not @staff-engineer or @security-engineer | Abort: `Error: Skill(code-review) is restricted to @staff-engineer and @security-engineer. Calling agent: {agent}.` |
| `<scope>` cannot be resolved (unknown branch, malformed PR ref, file paths do not exist) | Abort: `Error: Could not resolve <scope>: '{scope}'. Expected PR number/URL, branch name, "uncommitted", "staged", or existing file paths.` |
| Resolved scope produces an empty diff | Abort: `Error: Resolved scope produced an empty diff — nothing to review.` |
| `gh` CLI unavailable for a PR scope | Abort: `Error: gh CLI required to resolve PR scope. Re-invoke with the branch name or "uncommitted".` |
| Validation Before Emit fails | Abort: `Error: validation failed: {section/field} — {detail}.` No retry — calling agent re-invokes after correction. |
| Severity ladder cross-mixed (e.g., security review uses "Blocker" instead of "Critical") | Abort: `Error: validation failed: severity ladder — {role} review must use {ladder}. Found: {wrong-label}.` |
| Caller passes additional positional args beyond `<scope>` | Ignore extras silently. |
