# Changelog: verify-ac

## 2026-06-09

### Summary
Removed one Failure Modes row duplicating the "ignore extras silently" rule already at Argument Handling L70 and violating the table's own abort-path scope. Net -1 (267 → 266, orchestrator-verified post-apply). Both priority audit signals verified resolved: literal-command-AC rule present (L142); vote mode-split correct (L254).

### Changes
- Failure Modes: removed "Caller passes additional positional args" row — not an abort path; behavior already stated at L70.

### Dimensions Evaluated
All 8; Over-Engineering primary (one trim); sdet pitfall #3 and staff pitfall #7 closed with grep citations; no unescaped $+digit.

### Rename
No rename.

## 2026-06-09

### Summary
Closed the refuted literal-command-AC gap: FULL-mode item 1 now mandates running an AC's named literal command VERBATIM — equivalents leave the named path unverified; PASS on a substitute is a defect. The 2026-06-05 cycle recorded this rule as already-encoded; a 2026-06-09 re-grep refuted that claim (only unrelated "report verbatim" at L172 matched). Net 0 physical lines (within-line append; 267 lines).

### Changes
- FULL-mode procedure item 1: added "When an AC names a literal command, run THAT command verbatim... cite the exact command in evidence."
- Aligns with sdet.md Epistemic Discipline (empirical execution over text inspection).
- [NO-OP, grep-cited] Reasoning-echo clean; recall-filter clean (PASS/FAIL/OUT-OF-SCOPE is classification; Validation checks 2+4 already forbid silent omission).

### Dimensions Evaluated
Completeness (refuted-NO-OP closure, primary), Over-Engineering (single clause, no new section), Actionability, Coherence.

### Rename
No rename.

## 2026-06-09

### Summary
Phase 2: code-review→code-review-verdict reference updates (lockstep) and vote-escalation mode-split in Save & Return.

### Changes
- 4 refs updated for the sibling rename, incl. the byte-identical COUPLING marker (byte parity re-verified across the family of 4).
- Save & Return vote bullet now mode-split: standalone Skill(vote); team mode docket vote create + delegation_request per agents/sdet.md §Using /vote for Consensus.

### Dimensions Evaluated
Coherence (family lockstep), Orchestration (vote delegation).

### Rename
No rename (sibling code-review renamed → code-review-verdict; refs updated).

## 2026-06-09

### Summary
Added an OUT-OF-SCOPE deferral path for runtime/render-only acceptance criteria (fem-kubernetes pitfall: static gates — files exist, refs present, build exit 0 — passed while rendered output shipped broken images; design-qa gates its side, verify-ac had no marker). Threaded through FULL step 1, verdict ladder (caps at ACCEPT WITH CAVEATS), report template ([~] marker + route), and validation checks 2/5/6. Offset: deduplicated the LIGHT one-liner and pointed the Round-2 bullet at Pre-flight §4a. Net −6 (268/500).

### Changes
- FULL §1: PASS/FAIL/OUT-OF-SCOPE; runtime-only criteria never pass on static proxies; route named (design-qa / bundled runtime verify), dispatch stays with the calling agent.
- Verdict ladder + validation 2/5/6: OUT-OF-SCOPE requires a named route, satisfies the ACCEPT-WITH-CAVEATS finding requirement, and bars APPROVE.
- LIGHT: switch-to-FULL includes runtime-only criteria; duplicate one-liner removed; Round-2 carry-forward deferred to §4a.
- Phase-0 NO-OPs verified: no `$`+digit; description 695/1536 chars; `disallowed-tools` rejected (caller-strip risks SendMessage deliverable).

### Dimensions Evaluated
All 8. Completeness (PRIMARY), Over-Engineering (HIGHEST — net −6), Coherence (design-qa boundary + COUPLING parity byte-identical).

### Rename
No rename.

## 2026-06-08

### Summary
Phase 1 no-change verdict (274 lines). COUPLING marker byte-identical across the 4-skill family; all docket CLI usage (reopen / comment add -m / comment list) verified live and matches sdet.md closeout contracts; static-vs-runtime boundary confirmed sharp (bundled `verify` collision disambiguator accurate). Audit-grounded Pre-flight additions (§4a/§7a/§8) all pass the Content Gate — nothing to trim.

### Changes
- None. Noted (no edit): the 2026-06-04/06-05 entries' "draft|approved" narrative is stale — live body correctly gates §7 on `status: accepted`, matching skills/tdd/SKILL.md canonical lifecycle. Editing to `approved` would break tdd parity; changelog is historical, left as-is.

### Dimensions Evaluated
All 8; Over-Engineering (HIGHEST — zero net, no trimmable additions), Coherence (COUPLING/BANNER/docket/sdet.md parity verified).

### Rename
No rename.

## 2026-06-05

### Summary
Phase 2 coherence: moved the report-emission COUPLING marker from under "When to Use" to directly above the "When NOT to Use" routes it governs (matching code-review's semantically-correct placement) and synced its text. All 4 family markers now byte-identical. (Supersedes the same-day Phase 1 entry below, which deferred this to Phase 2.)

### Changes
- COUPLING marker relocated under "When NOT to Use"; doubling-rule parity sentence added (directionless wording).

### Dimensions Evaluated
Coherence (report-emission family COUPLING placement + text parity).

### Rename
No rename.

## 2026-06-05

### Summary
Reviewed against all 8 dimensions; no edits applied. The Phase 0 "TDD status: accepted abort" signal is stale — the skill correctly gates on `approved` (canonical lifecycle is draft|approved); already resolved/rejected in the 2026-06-04 entry below.

### Changes
- No changes. `$`-escape (2.1.163): no `$`+digit in body — NO-OP. A proposed COUPLING-marker relocation was REJECTED: empirical grep shows verify-ac matches the 3/4 family norm (marker after "When to Use"); the real drift (code-review's marker placement, design-review's longer marker text) is routed to Phase 2.

### Dimensions Evaluated
Coherence (PRIMARY), Completeness, Over-Engineering (HIGHEST — zero net). All Phase 0 signals resolved NO-OP.

### Rename
No rename.

## 2026-06-04

### Summary
Routed the TDD-status-gate abort to the authoritative Docket status field. The body-frontmatter `status:` mirrors Docket's top-level doc status but can go stale (verified: DOC-4 is top-level `approved` / body `draft`); the prior abort unconditionally sent the caller to "vote approval" — the wrong path when the TDD is already Docket-approved and only the mirror is stale. The status READ (top-level `.data.status`, L103) was already correct and unchanged. Net 0.

### Changes
- Pre-flight §7 status-gate abort: added a clause directing the caller to re-confirm via `docket doc list -T tdd -s approved` (the authoritative top-level field) before escalating, since the body-frontmatter mirror may be stale.
- Pre-flight §7 not-found abort: trimmed the redundant "before re-invoking" tail (an abort always precedes a re-invoke) as the BALANCED offset.

### Dimensions Evaluated
Completeness (PRIMARY — status-gate abort guidance), Coherence (status-authority theme shared with tdd; the read mechanism agrees across both), Over-Engineering (HIGHEST — net 0, offset; rejected an ungrounded "test-writing closes separately" addition).

### Rename
No rename.

## 2026-05-30

### Summary
Fixed a verified coherence defect: the description's runtime-disambiguator named a phantom `runtime-verify` skill — the bundled runtime skill is registered as `verify`, so the disambiguator pointed agents at a non-existent name. Corrected to name the real `verify` skill. Also fixed H1 rename residue (bare "Verify" → "Verify-AC" for sibling parity) and trimmed two inline audit-stat provenance clauses. Net 0 file lines.

### Changes
- Description Trigger line: phantom `runtime-verify` → `verify` (the actual bundled runtime skill; verify-ac was renamed away from `verify` to avoid this collision).
- H1 heading: `# Verify —` → `# Verify-AC —` (rename residue; sibling parity with Code Review / Design QA / Design Review).
- Pre-flight §4a, §7a: dropped two inline audit-stat provenance parentheticals (session IDs / invocation counts); behavioral rules + rationale retained, provenance lives in changelog.

### Dimensions Evaluated
Coherence (PRIMARY — phantom skill name verified against the skills registry), Rename (H1 residue), Over-Engineering (HIGHEST — two provenance trims), Skill Design, Actionability, Completeness, Orchestration, Spec Alignment.

### Rename
Skill name unchanged (verify-ac). H1 heading residue from the prior verify→verify-ac rename fixed. No registry/cross-file rename.

## 2026-05-30

### Summary
Killed the verify-ac claim-drift in two places, both contradicting the corrected agents/sdet.md Rule 7 (verification is READ-ONLY on Docket workflow state; the only legitimate state-change is `reopen` on BLOCK; the issue is already CLOSED by @senior-engineer). Pre-flight step 4 wrongly asserted @sdet had already `docket issue move <id> in-progress`-claimed the issue; Save & Return wrongly routed ACCEPT-WITH-CAVEATS/BLOCK to `docket issue move <id> review`. Net 0; 267 lines.

### Changes
- Pre-flight step 4: replaced the "already claimed via `docket issue move`" assertion with "acknowledges via SendMessage but does NOT `docket issue move` (read-only per sdet.md Rule 7)".
- Save & Return closeout: replaced `docket issue move <id> review` on ACCEPT-WITH-CAVEATS/BLOCK with the correct branches — APPROVE/ACCEPT = comment-only (issue already closed by @senior-engineer), BLOCK = `reopen` + blocking comment.

### Dimensions Evaluated
Coherence (PRIMARY — sdet Rule 7 contradiction, fixed in 2 places) · Over-Engineering (both changes net 0) · Spec Alignment (closeout now matches sdet.md §Execution Workflow step 5)

### Rename
No skill rename. Changelog file renamed docs/changelog/skills/verify.md → verify-ac.md and header "# Changelog: verify" → "# Changelog: verify-ac" (the verify→verify-ac skill rename had not moved it).

## 2026-05-29

### Summary
Trimmed the Doubling Rule's orchestration re-narration to a pointer (it contradicted team-lead.md step 15's default-single-verifier rule and duplicated canonical logic), and documented the comma-batched Docket-ID arg form observed in the historical audit.

### Changes
- Doubling Rule: replaced 9 lines of spawn/reconcile/fix-loop narration (which wrongly asserted "no single-verifier mode under orchestration", contradicting team-lead.md step 15) with a 3-line pointer to agents/team-lead.md (Rule 7/8, step 14/15). Net -7.
- Argument Handling: added a Comma-batched Docket IDs paragraph — split on commas, one report per issue; contrast with code-review's single-scope path-list. Net +3.

### Dimensions Evaluated
Over-Engineering (HIGHEST — net offset), Orchestration (removed team-lead.md contradiction), Completeness + Argument Handling (comma-batch form), Coherence (runtime-verify name collision flagged for Phase 2; docket close-no--m verified), Skill Design Quality, Actionability, Spec Alignment, Rename.

### Rename
No rename — runtime-verify collision mitigated by the front-loaded description disclaimer; a registry rename is a Phase-2 decision.

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
