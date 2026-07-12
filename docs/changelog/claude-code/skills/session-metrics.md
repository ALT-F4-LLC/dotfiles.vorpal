# Changelog: session-metrics

## 2026-07-12

### Summary
Fixed an overclaiming OTEL/data-source note (the aggregate sink IS reachable — Mimir was read-queried 200-OK by 4 evolve-* agents this cycle — the true limitation is per-session attribution, not reachability), fixed in lockstep across SKILL.md and its companion `scripts/session_metrics.py`. Adopted `${CLAUDE_SKILL_DIR}` (2.1.196+, confirmed 2.1.207 here) to remove manual installed-vs-repo path-disambiguation prose. Rejected a Mimir-calibration cross-check arm (breaks the offline/leaf invariant, hardcodes operator-specific infra). Findings: 2 → 2 sub / 0 cos / 1 rej / 0 def / 0 enc

### Changes
- AMPLIFY[SUBSTANTIVE]: narrowed the OTEL overclaim to the true limitation (no per-session attribution, not "no local read path") in both SKILL.md's banner and `scripts/session_metrics.py`'s docstring + `summary.note` string (lockstep — Step 2 renders the script's note verbatim)
- AMPLIFY[SUBSTANTIVE]: switched script invocation to `${CLAUDE_SKILL_DIR}/scripts/session_metrics.py`, removing the repo-relative fallback path and "resolve whichever copy" prose

### Dimensions Evaluated
Coherence/Spec Alignment (OTEL note accuracy), Actionability/Skill Design Quality (portability). Rejected: Mimir-calibration cross-check arm — breaks the stated "no network calls, nothing leaves the machine" invariant, hardcodes `mimir.bulbasaur.altf4.domains` into a generic dotfiles-repo skill, and the aggregate metric can't isolate one session (the same granularity mismatch the OTEL-note fix documents). Follow-up idea (not this cycle, script-only): surface the price-table fetch date in `summary` for zero-network staleness signal.

### Rename
No rename.
