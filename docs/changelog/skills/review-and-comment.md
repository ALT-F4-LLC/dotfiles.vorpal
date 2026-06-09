# Changelog: review-and-comment

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
