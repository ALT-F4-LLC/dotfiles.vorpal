# Changelog: review-and-comment

## 2026-07-14

### Summary
NO-OP (9th no-change-class verdict). I23 rejected: the Step 3 dual-lens rubric is a DELIBERATE lighter fork (correctness axes + high/medium/nit severity for inline comments), not accidental drift from code-review-verdict's heavier Staff/Security Playbooks (Architecture/Ops/Perf/G1-G5 + Blocker/Concern). A ranged-Read line-pin would change behavior, worsen drift coupling into an actively-edited sibling, and mismatch the severity model. I24 deferred: `gh_pr_context.sh` verified nonexistent — script-authoring out of SKILL.md scope, mirrors the declined rc_pr.sh pattern.

### Changes
- None. I23 REJECTED (deliberate fork, behavior-changing, drift-coupling). I24 DEFERRED (phantom script → future Docket issue).

### Dimensions Evaluated
All 8; Over-Engineering (HIGHEST — file lean, escalation pointer to code-review-verdict already present + accurate); Coherence (fork intentional, code-review-verdict reference at L106 accurate post-rename).

### Rename
No rename.

## 2026-07-12

### Summary
Closed a cross-file completeness gap: findings anchored outside the PR diff (callers in unchanged files surfaced by the Step 2 clone) now have an explicit post/report path instead of being silently un-postable. Deferred gh_inline_comment.sh (verified nonexistent) as a future Docket tracking issue. Findings: 2 → 1 sub / 0 cos / 0 rej / 1 def / 0 enc

### Changes
- AMPLIFY[SUBSTANTIVE]: Step 4 — out-of-diff findings must be anchored to the nearest motivating changed line with a `(re: <path>:<line>)` pointer, or carried to the Step 9 report — never dropped. Previously the skill cloned for cross-file context (Step 2) it had no way to surface (GitHub rejects out-of-diff anchors)

### Dimensions Evaluated
Completeness (the gap), Over-Engineering (file already lean — no trims warranted). Deferred: gh_inline_comment.sh codification (verified nonexistent; recommend as a future Docket tracking issue, not authored this cycle). Confirmed: gh api sandbox failure still real, do not retire the sandbox-off mandate.

### Rename
No rename.

## 2026-07-10

### Summary
NO-OP (8th no-change-class verdict). 111 lines, all load-bearing; n=1 usage this window, zero failure signals. rc_pr.sh companion-script refactor declined on Over-Engineering grounds.

### Changes
- None. Considered+declined: codifying `.claude/scripts/rc_pr.sh` to wrap documented-fragile recipes — net-additive, fixes an unobserved failure mode (zero errors), introduces prose/script drift hazard.

### Dimensions Evaluated
All 8; Over-Engineering (HIGHEST — declined the only substantive addition); Coherence (escalation pointer + disallowed-tools intact).

### Rename
No rename.

## 2026-06-30

### Summary
Net 0; AMPLIFY diff-anchor validation and duplicate-comment filtering.

### Changes
- AMPLIFY: added PR-files diff anchor index.
- AMPLIFY: added same-path:line/same-concern dedupe against existing PR comments.

### Dimensions Evaluated
All 8.

### Rename
No rename.

## 2026-06-20

### Summary
Defense-in-depth coherence; net 0 (stays 110). Skill-specific CRITICAL banner unchanged (intentionally outside CANONICAL).

### Changes
- AMPLIFY: added `Agent` + `SendMessage` to `disallowed-tools` — mechanically enforces the no-team/no-delegate CRITICAL banner (skill is self-contained, posts via gh Bash, never spawns or messages). Per-turn defense-in-depth atop the prose banner (Phase-0 innovation signal).

### Dimensions Evaluated
Skill Design, Actionability, Completeness, Over-Engineering, Orchestration, Coherence, Spec Alignment, Rename.

### Rename
No rename.

## 2026-06-10

### Summary
Seventh consecutive NO-OP. 110 lines, all load-bearing; zero failure signals in window.

### Changes
- None (NO-OP verdict). Informational: the 2026-06-05 entry recorded `effort: max` as added but the key is absent from the current file — stale changelog record, no behavioral effect, consistent with peer skills.

### Dimensions Evaluated
All 8; Over-Engineering (HIGHEST — no ceremony); Orchestration (leaf boundary banner + disallowed-tools intact); Coherence (code-review-verdict escalation pointer accurate); Completeness ($-escaping verified).

### Rename
No rename.

## 2026-06-10

### Summary
Sixth evolution pass: NO changes. Both innovation suggestions declined after cost-benefit evaluation — voice-profile caching adds staleness risk for a 1-second round-trip save; step-1 batch parallelism adds ordering complexity for negligible gain.

### Changes
- None (NO-OP verdict).

### Dimensions Evaluated
All 8; Over-Engineering (HIGHEST — both innovation suggestions net-negative); Coherence (code-review-verdict boundary, lens lists, disallowed-tools all correct); Orchestration (leaf boundary banner + escalation section intact).

### Rename
No rename.

## 2026-06-09

### Summary
Full-cycle audit: NO changes. Pitfall-#5 regression check PASS: all positional tokens at L95 remain `\$`-escaped; zero unescaped $+digit in file. gh command surface (pr view/diff, api pulls/comments) verified current.

### Changes
- None (NO-OP verdict).

### Dimensions Evaluated
All 8; Over-Engineering primary (110 lines, every step load-bearing); Orchestration (leaf boundary banner intact); Coherence (code-review-verdict boundary accurate).

### Rename
No rename.

## 2026-06-09

### Summary
Mythos/Fable-5 cycle audit: NO changes. Banned-Skill(vote) audit clean (grep: no direct vote-invocation prose; escalation section routes to fleet flow correctly). Reasoning-echo clean; shell `\$1`/`\$2` usages correctly escaped already; "do NOT pad with marginal nits" is anti-fabrication for public operator-voice comments gated by per-item approval — not findings suppression.

### Changes
- None (NO-OP verdict).

### Dimensions Evaluated
All 8; banned-vote-prose + recall-filter + reasoning-echo audits clean.

### Rename
No rename.

## 2026-06-09

### Summary
Phase 2: escalation pointer updated for the code-review→code-review-verdict rename; banner carve-out documented in evolve-coherence.

### Changes
- "When to escalate instead" now names the code-review-verdict skill.
- The skill-specific CRITICAL banner (no CANONICAL markers) is now whitelisted in evolve-coherence D4 as intentional.

### Dimensions Evaluated
Coherence.

### Rename
No rename.

## 2026-06-09

### Summary
Escaped the `$1`/`$2`/`$3` tokens in the Step 8 posting recipe — Claude Code argument substitution (0-based `$N`, doc-confirmed) would silently replace them with stray invocation words, corrupting the validated `gh api` payload. Net 0 lines (111 total). Only skill of 15 affected.

### Changes
- Step 8: `"$1"`/`"$2"`/`"$3"` → `"\$1"`/`"\$2"`/`"\$3"` in the `post()` recipe; the `\$` escape (CLI v2.1.163+) restores the literal token before the agent reads the body.
- Declined `when_to_use` migration (description well under the 1,536-char cap), `arguments:` named substitution, and `paths` (all non-behavioral or N/A for a PR-triggered leaf).

### Dimensions Evaluated
All 8; Over-Engineering (HIGHEST — zero additions, healthy skill preserved), Completeness (substitution hazard). Highest operator-typed usage in window, zero failure signals.

### Rename
No rename.

## 2026-06-08

### Summary
Closed a terminal-state gap in the multi-turn approval flow (empty-findings / approval-declined), offset by de-duplicating the escalation recommendation. Net +2 lines (111 total, well under budget).

### Changes
- Step 7: added explicit terminal-state handling — zero findings → report "no findings to post", skip to cleanup, do NOT pad with marginal nits; operator declines all → post nothing, clean up, exit. Both paths previously undefined; Steps 8–9 assumed ≥1 approved comment.
- Step 3: collapsed the duplicated escalation recommendation to a pointer; the complete statement (team-lead reconciliation + optional vote) already lives in "When to escalate instead".

### Dimensions Evaluated
All 8; Completeness (terminal-state gap, 2nd-most operator-run skill), Over-Engineering (HIGHEST — escalation de-dup offset).

### Rename
No rename.

## 2026-06-05

### Summary
First evolution pass on this brand-new gh-based leaf skill (zero prior invocations). Compact and well-built — no over-engineering to trim; added the two earned frontmatter fields (net +2 lines).

### Changes
- Added `effort: max` — the only skill of 15 lacking an effort pin. Set to `max` (not the reviewer's `high`) for family consistency (14/15 use `max`) and the stakes of a dual security+correctness PR review.
- Added `disallowed-tools: ["Edit", "Write"]` — hardens the read-only contract at the tool layer (`allowed-tools` is grant-only, does not restrict). Mirrors the in-repo `.claude/skills/evolve-coherence` pattern.
- Declined `disable-model-invocation` (hides trigger phrases → worse discoverability), the code-review escalation reword (banner already bans recursive skill calls), and trigger edits (the lone historical "gap" was bootstrap-confounded).

### Dimensions Evaluated
All 8: Skill Design Quality, Actionability, Completeness, Over-Engineering, Orchestration, Coherence, Spec Alignment, Rename.

### Rename
No rename.
