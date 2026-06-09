# Changelog: review-and-comment

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
