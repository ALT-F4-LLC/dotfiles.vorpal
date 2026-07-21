# Changelog: session-metrics

## 2026-07-20

### Summary
Content-Gate hardening: escaped the one unescaped `$`+digit in prose (`$0` → `\$0` in the subagent-roster est.-cost instruction) so harness positional substitution cannot blank the guidance. No behavioral/coherence changes; skill verified coherent against scripts/session_metrics.py (all summary.* field references accurate). Findings: 0 sub / 1 cos / 0 rej / 0 def / 0 enc

### Changes
- TRIM[COSMETIC]: escape `$0` → `\$0` in Step 2 roster est.-cost line (Content Gate: unescaped `\$`+digit in prose; skill has no args so `$0` is an undefined positional)

### Dimensions Evaluated
Skill Design Quality / Coherence (Content Gate dollar-sigil scan; full field-reference cross-check against session_metrics.py). Deferred (unchanged, out of scope): L31 (DKT-30) script-side `price_table_version` emission.

### Rename
No rename.

## 2026-07-14

### Summary
Phase 3 disambiguation: pinned the referent of the stale-price caveat line.

### Changes
- "the table may be stale" → "the script's price table may be stale" — the user-facing caveat had two plausible table referents (chat roster table vs price table); only the price table can be stale (multi-reading).

### Dimensions Evaluated
Confusable names/triggers/terms; multi-reading wording; overlapping ownership.

### Rename
No rename.

## 2026-07-14

### Summary
Added a session-level stale-price caveat instruction (SKILL.md slice of I40): the renderer now flags that an unpriced model UNDERCOUNTS total cost rather than letting per-cell "n/a" pass unremarked — derivable from `summary.by_model` with no script change. Dropped a frozen "environment is 2.1.207" version claim (already drifted to 2.1.210). Findings: 1 sub / 1 cos / 1 rej (D2) / 1 def (I40 script-side) / 0 enc

### Changes
- AMPLIFY[SUBSTANTIVE]: instruct surfacing a one-line stale/undercount caveat when any `by_model`/subagent `cost_est` is `null` (I40, SKILL.md slice)
- TRIM[COSMETIC]: removed drift-prone "this environment is 2.1.207", keeping the load-bearing 2.1.196+ minimum

### Dimensions Evaluated
Actionability/Completeness (unpriced-model caveat), Coherence (version staleness), Skill Design Quality (D2 SKILL_DIR resolver — rejected migration). Deferred: I40 programmatic `price_table_models` emission (script-only).

### Rename
No rename.

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
