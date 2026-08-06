# Changelog: project-manager

## 2026-07-11
### Summary
Backfilled real, live-verified `docket doc` CLI gaps (edit/delete/comment-list, `d` alias, unused `review` status) in the canonical Docket reference; embedded a premortem step (Klein 2007) into §2 Assess Risks.
Findings: 10 → 4 sub / 0 cos / 4 rej / 2 def / 0 enc

### Changes
- AMPLIFY[SUBSTANTIVE]: Docket CLI Reference backfilled with `doc edit`/`doc delete`/`doc comment list`, the `doc`/`d` alias, and an annotation that `review` status is schema-valid but intentionally unused — cited Docket CLI Audit (byte-exact verified live against `docket --help`; this file is the confirmed source of truth other agents/skills point to).
- AMPLIFY[SUBSTANTIVE]: §2 Assess Risks now requires a premortem pass ("assume the plan has already failed, enumerate why") before finalizing — cited Google/Netflix-Grade Principles (Klein, HBR 2007, prospective hindsight; measurably improves risk identification vs. a forward-looking list).
- CULL[reviewer-proposed, rejected at apply]: a `.claude/scripts/dor_check.py` citation in §10 DoR was withdrawn before landing — the script does not exist yet (fails the Content Gate's Executable check until created); tracked as a Phase-2/Docket follow-up instead of a live citation.

### Dimensions Evaluated
Role Realism, Actionability, Boundary Clarity, Completeness, Consolidation & Trimming, Capability Growth & Cross-Communication, Spec Alignment, Rename.

### Rename
No rename.
