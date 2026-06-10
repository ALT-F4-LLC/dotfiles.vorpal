# Changelog: verify-ac

## 2026-06-10

### Summary
Compacted 10 entries (2026-05-19..2026-05-30) into Compacted history per ADR 0001.

### Changes
- Replaced the 10 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per ADR 0001, not a review cycle.

### Rename
No rename.

## 2026-06-10

### Summary
Full-cycle audit: NO changes. Healthiest skill in window (3 sessions, 8 invocations, zero errors across sonnet/fable/opus tiers). `round=N --prior` argument suggestion rejected — §4a comment-list carry-forward has zero observed failures; new flag surface unjustified.

### Changes
- None (NO-OP verdict).

### Dimensions Evaluated
All 8; Over-Engineering (HIGHEST — innovation declined); Completeness (literal-command-AC rule, OUT-OF-SCOPE deferral, §7a contamination guard all verified present); Coherence (COUPLING family parity, docket CLI usage matches sdet closeout contracts).

### Rename
No rename. verify→verify-ac rename rationale stands.

## 2026-06-09

### Summary
Compacted 4 entries (2026-05-16..2026-05-18) into Compacted history per ADR 0001.

### Changes
- Replaced the 4 oldest committed entries with one ledger line each in the terminal Compacted history section; full text recoverable via git history.

### Dimensions Evaluated
None — History Compaction per ADR 0001, not a review cycle.

### Rename
No rename.

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

## Compacted history

Entries below were compacted per ADR 0001; full text in git history (see the compaction entry's date).

- 2026-05-16: First entry: scoped spec reads, compressed Docket-CLI enumeration, trimmed Failure Modes, Save & Return Docket phrasing aligned with agents/sdet.md.
- 2026-05-16: Common Discipline gained the AskUserQuestion structural contract (1-4 questions, 2-4 options, header ≤12 chars) for sibling parity.
- 2026-05-17: Removed PR scope (dead surface for @sdet); added do-not-substitute-completion-comment-for-diff warning; deduplicated peer/vote guidance.
- 2026-05-18: Round-2 re-verification scoped to changed criteria; evidence-over-assertion bullet per Epistemic Discipline; comments-supersede phrasing tightened.
- 2026-05-19: Phase 2 coherence — added explicit Epistemic Discipline Validation check (new check #9) so the banned-framings rule in Common Discipline (referencing agents/...
- 2026-05-20: Phase 2 coherence pass: Title-Cased Doubling Rule heading to match three siblings (code-review, design-qa, design-review); added one-line acknowledgment in P...
- 2026-05-20: Operationalized prior-verdict awareness as enforced Pre-flight step (driven by historical audit session 8442dc39: 121 invocations across ~17 ephemeral fix-lo...
- 2026-05-25: Phase 2 coherence: trimmed AskUserQuestion structural-contract restatement (lockstep with code-review/design-qa).
- 2026-05-25: Three audit-driven additions: silent-completion self-check in Save & Return (cross-cutting with code-review/design-review/design-qa per staff-engineer pitfal...
- 2026-05-28: Phase 2 coherence: repointed two dead `docs/tdd/reviewer-doubling-lifecycle.md` references (the file does not exist) to `agents/team-lead.md`.
- 2026-05-28: Disambiguated from the external bundled runtime-verify skill (indistinguishable `"skill":"verify"` name collision, wrong-skill-load risk): front-loaded "stat...
- 2026-05-29: Trimmed the Doubling Rule's orchestration re-narration to a pointer (it contradicted team-lead.md step 15's default-single-verifier rule and duplicated canon...
- 2026-05-30: Fixed a verified coherence defect: the description's runtime-disambiguator named a phantom `runtime-verify` skill — the bundled runtime skill is registered a...
- 2026-05-30: Killed the verify-ac claim-drift in two places, both contradicting the corrected agents/sdet.md Rule 7 (verification is READ-ONLY on Docket workflow state; t...
