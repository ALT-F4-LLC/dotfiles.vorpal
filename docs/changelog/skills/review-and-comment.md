# Changelog: review-and-comment

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
