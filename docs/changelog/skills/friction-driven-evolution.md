# Changelog: friction-driven-evolution

## 2026-05-18

### Summary
Added a one-line operator-visible dispatch trace before each Phase 3 `Skill()` invocation so downstream-skill chaining is observable in the transcript. Resolves a historical-audit gap (2 invocations across 30d showed zero transcript-visible chaining; existing per-cluster recording was internal-only until wrap-up).

### Changes
- Phase 3 preamble: orchestrator now emits `Dispatching cluster {id} ({class}, {target_file_basename}) → {downstream_skill}` immediately before each `Skill()` call. Recording schema and wrap-up reporting unchanged.

### Dimensions Evaluated
Actionability (real-time operator visibility), Spec Alignment (closes historical-audit instrumentation gap).

### Rename
No rename.

## 2026-05-17

### Summary
Phase 2 coherence sync: corrected false AskUserQuestion "multiSelect lifts the 4-option cap" carve-out to match sister evolve-skills / evolve-agents corrections this cycle. The API hard-rejects >4 options regardless of multiSelect.

### Changes
- Operator-prompts blockquote: replaced "up to 8 options when multiSelect AND fixed dimension catalog" with "max 4 regardless of multiSelect" + routing-question pattern for >4-option dimensions. Sister-parity with evolve-skills + evolve-agents Phase 1 fix.

### Dimensions Evaluated
Coherence (cross-orchestrator parity), Skill Design Quality (operator-prompt contract correctness).

### Rename
No rename.

## 2026-05-17

### Summary
Fixed payload-contract mismatch with downstream consumers (evolve-skills/evolve-agents): renamed `example_refs` → `example_session_refs` and nested `target`/summary under `proposed_edit.*` to match the field names those skills look for. Trimmed redundant Rules section.

### Changes
- Phase 3 experience_feedback payload: renamed `example_refs` → `example_session_refs` and restructured `target=` and the OLD→NEW summary as `proposed_edit.target=` / `proposed_edit.summary=` so downstream skills' field-name expectations match emission.
- Rules section: removed rules 2/3/5 — each restated content already canonical earlier in the file. Kept Rules 1 (No scheduling) and 4 (Fail loud) as non-derivable constraints.
- Detection Patterns intro: removed duplicate hit-shape declaration; Phase 0 JSON schema is the single source of truth.

### Dimensions Evaluated
Coherence (payload contract with evolve-skills/evolve-agents — primary), Over-Engineering.

### Rename
No rename.

## 2026-05-16

### Summary
Phase 2 coherence pass: AskUserQuestion preamble extended with multiSelect+fixed-catalog carve-out for Pre-flight Classes question (5 options) and Phase 1 Top 5 cluster question.

### Changes
- Operator-prompts banner: extended option-count contract to permit "up to 8 options when multiSelect AND fixed dimension catalog" — resolves contradiction with Classes/Top-5 questions that exceed the 4-option cap.

### Dimensions Evaluated
Operator prompt quality (AskUserQuestion contract honesty), Coherence (family-wide carve-out).

### Rename
No rename.

## 2026-05-16

### Summary
Trimmed redundant Rules duplicating the canonical banner, replaced the inline Stage B awk filter (acknowledged 10+s on large transcripts) with a declarative description that delegates execution to the Phase 0 harvester in Python, closed the unowned `miscalibrated_classes` field, and condensed the multi-line `experience_feedback` payload into a single line.

### Changes
- Rules section consolidated: removed rule 1 (No commits) and rule 6 (Clean up) — both restated in canonical banner and Wrap-up step 1 respectively.
- Class 1 Stage B detection: replaced the inline 30-line awk-with-date-subshell block with a declarative algorithm description; implementation moves into the Phase 0 harvester (Python `json.loads` + `datetime.fromisoformat`).
- Phase 1 step 1: added clause routing `miscalibrated_classes[]` to the operator decision captured in pre-flight step 4 — previously the field was emitted but never consumed.
- `experience_feedback` payload condensed: multi-line YAML-ish shape replaced with a single-line string; downstream skills store it verbatim — nothing parses the structure.

### Dimensions Evaluated
Over-Engineering (highest — primary motivation), Actionability (declarative algo more useful than brittle bash), Completeness (closed unowned field), Coherence (payload shape matches consumer).

### Rename
No rename.

## 2026-05-16

### Summary
Tightened Class 1 (idle teammates / stalls) Detection Pattern into a two-stage filter to eliminate the ~94% false-positive rate observed in the 2026-05-16 sweep. SKILL grew 346 → 382 lines (+36).

### Changes
- Class 1 Detection Pattern restructured. Stage A preserves the existing high-signal markers (`TeammateIdle`, `-r2` respawn) unchanged. Stage B replaces the >120s naked-gap rule with a four-clause filter: gap > 600s AND handoff context (Agent call, SendMessage to non-team-lead, or wait tokens) AND no shutdown_response in the gap AND no concurrent tool_use. Pre-flight step 4 calibration must now exercise both stages.
- Added a performance note acknowledging the awk date-subshell overhead on large transcripts; flagged a Python fallback as an option if the cost becomes load-bearing.

### Dimensions Evaluated
Actionability (concrete two-stage filter with explicit thresholds), Completeness (covers Stage A + Stage B miscalibration handling), Over-Engineering (net +36 lines justified by 94–96% false-positive reduction observed in sweep). Content Gate: 4/4 passed.

### Rename
No rename.
