# Changelog: verify

## 2026-05-28

### Summary
Phase 2 coherence: repointed two dead `docs/tdd/reviewer-doubling-lifecycle.md` references (the file does not exist) to `agents/team-lead.md`.

### Changes
- Eager same-turn dispatch ref → `agents/team-lead.md` Rule 8.
- Verdict reconciliation ref → `agents/team-lead.md` step 14.

### Dimensions Evaluated
Coherence (accurate references).

### Rename
No rename.

## 2026-05-28

### Summary
Disambiguated from the external bundled runtime-verify skill (indistinguishable `"skill":"verify"` name collision, wrong-skill-load risk): front-loaded "static, evidence-based — NOT runtime app-behavior verification" in the description and dropped the generic "run verification"/"verify issue" triggers. Offset by trimming the redundant Pre-flight §8 doubling-rule back-reference (renumber §9→§8). Net 0 lines.

### Changes
- Description/Trigger: added runtime-verify disambiguator; trigger now "verify acceptance criteria"/"verify Docket issue"/"produce verification report" + NOT-clause; family-parity phrasing preserved.
- Pre-flight: removed §8 (pure back-reference to the in-file Doubling Rule section); renumbered §9→§8.

### Dimensions Evaluated
Skill Design Quality + Coherence (name collision — operator priority), Over-Engineering (HIGHEST — §8 trim), Orchestration, Spec Alignment, Actionability, Completeness.

### Rename
No rename (operator decision, 2026-05-28). A cross-file rename to `verify-ac` was considered to eliminate the bundled-runtime-verify collision; the operator chose to keep `verify` and rely on the description disambiguation above (no observed wrong-skill-loads; stability + 7-ref blast radius across agents/sdet.md, agents/staff-engineer.md, code-review, design-qa, design-review). Revisit only if collisions occur.

## 2026-05-25

### Summary
Phase 2 coherence: trimmed AskUserQuestion structural-contract restatement (lockstep with code-review/design-qa).

### Changes
- Replaced AskUserQuestion structural-contract restatement with pointer to calling agent's contract (Item 4 lockstep).

### Dimensions Evaluated
Coherence, Consolidation.

### Rename
No rename.

## 2026-05-25

### Summary
Three audit-driven additions: silent-completion self-check in Save & Return (cross-cutting with code-review/design-review/design-qa per staff-engineer pitfalls); Mandatory verification commands caller-contract check (Pre-flight §9, team-lead pitfall on review-phase dispatch); cross-issue contamination guard for multi-issue sessions (Pre-flight §7a — 154 invocations / 45 sessions = ~3.4 issues per session typical). Net +18 lines (267 → 285).

### Changes
- Save & Return: added Silent-completion self-check paragraph — verdict in skill context is working artifact; SendMessage IS the deliverable; trailing confirmation line is not a delivery signal.
- Pre-flight §9 (new): Mandatory verification commands caller-contract check — surfaces brief gap as Pre-flight finding, derives commands from ACs as fallback.
- Pre-flight §7a (new): Cross-issue contamination guard — multi-issue sessions reset persistent test artifacts before running current issue's tests, OR surface contamination risk as Test Coverage finding.

### Dimensions Evaluated
Orchestration (HIGHEST — silent-completion fix), Actionability (Mandatory verification commands), Skill Design Quality (cross-issue contamination), Coherence (cross-family Save & Return parity).

### Rename
No rename.

## 2026-05-20

### Summary
Phase 2 coherence pass: Title-Cased Doubling Rule heading to match three siblings (code-review, design-qa, design-review); added one-line acknowledgment in Pre-flight §4 that calling `@sdet` has already claimed the Docket issue per Rule 7.

### Changes
- Heading `## Doubling rule` → `## Doubling Rule` to match siblings. Cross-family heading-case parity.
- Pre-flight §4: added note acknowledging `@sdet` Rule 7 issue claim already happened, preventing redundant `docket issue move` calls. Phase 1 open item #5 (skill ↔ agent contract sync).

### Dimensions Evaluated
Coherence (sibling-family heading parity); Cross-communication contract (skill/agent claim handshake).

### Rename
No rename.

## 2026-05-20

### Summary
Operationalized prior-verdict awareness as enforced Pre-flight step (driven by historical audit session 8442dc39: 121 invocations across ~17 ephemeral fix-loop rounds × 7 DKT issues, where Round-N verifiers re-ran full criteria sweeps with no awareness of prior round's evidence). Reduces per-round token spend on multi-round fix-loops while preserving "always re-run suite end-to-end" guarantee. Tightened Pre-flight §5 completion-comment-vs-diff phrasing. Net +1 line.

### Changes
- Pre-flight §4a (new): Round-2+ verifications scan `docket issue comment list {id}` for prior verify reports; PASS criteria whose evidence files are untouched by current diff cite the prior round's evidence instead of re-running. Suite still re-runs end-to-end; never carries forward FAIL or Additional Testing gap.
- Pre-flight §5: replaced "completion claims describe intent; diff describes reality" with "completion claims describe what the implementer intended to ship; the diff describes what reached HEAD" — names concrete failure mode.

### Dimensions Evaluated
Orchestration & Agent Teams (HIGHEST — audit-driven), Actionability, Coherence.

### Rename
No rename.

## 2026-05-19

### Summary
Phase 2 coherence — added explicit Epistemic Discipline Validation check (new check #9) so the banned-framings rule in Common Discipline (referencing agents/sdet.md) is gate-enforced. Net +1 line.

### Changes
- Validation Before Emit: added check #9 — scan criterion evidence / Additional Testing / Issues Found / Recommendation for banned confidence phrases; a hit is a defect.

### Dimensions Evaluated
Coherence, Epistemic Discipline, Report-Emission Family Parity.

### Rename
No rename.

## 2026-05-18

### Summary
Round-2 scoping + Epistemic Discipline parity. Adds explicit re-invocation guidance to scope Round-2 verifications to changed criteria (addresses 9-per-session re-verification rate from historical audit); mirrors Epistemic Discipline rule into Common Discipline so evidence-free PASS/FAIL claims fail validation; tightens "comments supersede description" phrasing.

### Changes
- When to Use: added "Re-invocation after fix is expected" bullet — Round-2 may carry forward PASS criteria whose evidence files are untouched, but always re-run the suite end-to-end.
- Common Discipline: added "Evidence over assertion" bullet referencing agents/sdet.md Epistemic Discipline rule.
- Pre-flight §4: clarified "comments supersede description" → "comments (which supersede the description on conflict)".

### Dimensions Evaluated
Over-Engineering (HIGHEST), Coherence (Epistemic Discipline cross-agent parity), Actionability.

### Rename
No rename.

## 2026-05-17

### Summary
Workflow-boundary cleanup: removed PR scope (dead surface for @sdet, who is Docket-issue centric per `agents/sdet.md`); strengthened Pre-flight §5 with "do not substitute completion comment for diff" warning lifted from @sdet's load-bearing rule; deduplicated peer-SendMessage and vote-trigger guidance against canonical banner and agent file.

### Changes
- Argument Handling: dropped PR-number and PR-URL rows from scope table; updated usage error to redirect PR review to Skill(code-review).
- Argument Handling: dropped `gh`-availability ambiguity rule (unreachable after PR removal).
- Pre-flight §5: added "do not substitute completion comment for diff" warning (from agents/sdet.md §Verification Workflow §2).
- Pre-flight §7: dropped redundant scoping preamble.
- Save & Return: vote-trigger bullet now defers to agents/sdet.md.
- Common Discipline: dropped redundant peer-SendMessage sentence (canonical banner owns this).
- Failure Modes: dropped `gh`-CLI-unavailable row.

### Dimensions Evaluated
Over-Engineering (HIGHEST), Coherence (workflow boundary with code-review, @sdet agent file), Actionability (Pre-flight §5).

### Rename
No rename.

## 2026-05-16

### Summary
Phase 2 coherence pass: Common Discipline now includes the AskUserQuestion structural contract (added to design-review this cycle).

### Changes
- Common Discipline: added "with 1-4 questions, each having 2-4 options and a `header` ≤12 chars" to the AskUserQuestion guidance — parity with design-review/code-review/design-qa.

### Dimensions Evaluated
Coherence (operator-prompt contract).

### Rename
No rename.

## 2026-05-16

### Summary
First changelog entry. Five over-engineering + coherence fixes: scoped spec-read examples for parity with code-review, compressed Pre-flight Docket-CLI enumeration to a single sentence (CLI guidance lives in agents/sdet.md), trimmed Failure Modes table to rows with new abort text only (matches code-review trim pattern), aligned Save & Return Docket move/close phrasing with agents/sdet.md, deduplicated Save & Return emission preamble against Output Contract.

### Changes
- Pre-flight §7: spec-read scope now names concrete examples + "skip the rest" — matches `code-review` §6 wording.
- Pre-flight §4: compressed 4-bullet Docket-CLI enumeration to one sentence; CLI procedure is owned by `agents/sdet.md`.
- Failure Modes table: dropped 6 rows that duplicated inline aborts; kept only CLI-unavailable + ignore-extras rows.
- Save & Return: aligned Docket move/close phrasing with `agents/sdet.md` (APPROVE → close+comment; ACCEPT WITH CAVEATS or BLOCK → `move review`).
- Save & Return: removed duplicate "no file / emit verbatim / no preamble" preamble — Output Contract owns those rules.

### Dimensions Evaluated
Over-Engineering (HIGHEST — primary cuts), Skill Design Quality, Actionability, Coherence (sibling skills + parent agent `agents/sdet.md`).

### Rename
No rename. `verify` is operator-aligned and family-aligned with report-emission siblings.
