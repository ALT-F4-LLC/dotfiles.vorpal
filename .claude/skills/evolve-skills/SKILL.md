---
name: evolve-skills
description: >
  Review and improve skill definitions via parallel @staff-engineer agents. Evaluates 8
  dimensions, enforces Content Gate and byte budget. Phase 0 includes a per-skill
  historical audit of recent Claude Code transcripts, history, and agent memory.
  Trigger: "evolve skills", "improve skills", "refine skills".
argument-hint: "[skill-name] [days=N] [drift=N]"
effort: xhigh
allowed-tools: ["Edit", "Bash", "Read", "Write", "Glob", "Grep", "Monitor", "WebFetch", "SendMessage", "TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "Agent", "AskUserQuestion"]
---

<!-- CANONICAL:BANNER:BEGIN -->
> **CRITICAL — applies to orchestrator AND every spawned teammate:** (1) Do NOT commit ANY changes (no `git add`, `git commit`, or `git push`) unless EXPLICITLY instructed by the user. (2) Teammates MUST NOT spawn sub-agents, invoke `/vote`, use `Skill()` or `Agent()`, or form/manage a team — delegate to the orchestrator (see `src/user/claude-code/skills/vote/` Delegation Protocol).
<!-- CANONICAL:BANNER:END -->

# Evolve Skills

You are the **Skill Evolution Orchestrator**. All additions pass through the Content Gate.

<!-- CANONICAL:DOCS-PATHS-LOCAL:BEGIN -->
**Docs paths (this skill).** Master: `~/.claude/skills/team-doctrine/references/docs-paths.md` — repo: `src/user/claude-code/skills/team-doctrine/references/docs-paths.md` (maintained copy).
- Writes: `docs/changelog/claude-code/skills/<name>.md`.
- Reads: `docs/spec/`, `src/user/claude-code/skills/`, `.claude/skills/`.
- Always singular docs/spec/ — never docs/specs/.
<!-- CANONICAL:DOCS-PATHS-LOCAL:END -->

---

<!-- CANONICAL:EVOLUTION-MODEL:BEGIN -->
**Evolutionary model (shared vocabulary — evolve-agents, evolve-skills, evolve-config, evolve-coherence).** One cycle = one **generation**: the current definition file is the **parent genome**, the post-cycle file the **offspring**, the changelog entry the birth record (changelogs are the **phylogenetic record**; History-Compaction ledgering = fossil consolidation). A **trait** is one Content-Gate-passing behavioral unit; an **allele** is an alternative formulation of a trait; the file is the heritable **genome**, the population is the agents/skills under this cycle. **Fitness signals** are the Phase 0 audit measurements (pitfalls re-fires, operator-corrections, `TeammateIdle`/`-r2`/shutdown-rejection stalls, error/abort, model-routing, prior `Trial:`/`Drift:` outcomes). **Natural selection** assigns each evaluated trait a disposition from CITED fitness — AMPLIFY (cited gain → propagate family-wide in Phase 2 = positive selection) or CULL (cited recurring failure → remove = purifying/background selection); unlisted traits default to RETAIN. The **Content Gate is purifying selection** on every introduced allele. **Genetic drift** is bounded, fitness-INDEPENDENT neutral allele-substitution on a no-signal trait (see the drift operator). **Speciation/extinction** (new/retired organism) is a Phase 2 event gated by operator approval + vote, floored by the **biodiversity invariant** (never cull the last carrier of a live niche). Adaptive change and drift alike pass the operator-approval HARD GATE, are measured by the next cycle's Phase 0 audit, and adopt-or-rollback via the Phase 1 self-correct step. **evolve-coherence does not reproduce** — it is the **reproductive-isolation monitor**: it detects cross-organism incompatibility (parity/contract drift) and routes corrective selection to evolve-agents/evolve-skills; it never edits.
<!-- CANONICAL:EVOLUTION-MODEL:END -->

## Innovation Mandate

Each cycle sources variation three ways (see CANONICAL:EVOLUTION-MODEL): the **innovation-scanner** (directed adaptive exploration of new model/tool/coordination frontiers), the **historical-auditor** (reactive, fitness-driven), and the **genetic-drift operator** (stochastic, fitness-independent). Refactor authority — speciation (new skills) and extinction (retiring redundant skills) — is exercised per the Phase 2 Speciation / extinction gate.

## Scientific Trial Protocol

<!-- CANONICAL:SCIENTIFIC-TRIAL-PROTOCOL:BEGIN -->
Every non-neutral adaptive change AND every drift proposal passes this gate: **Hypothesis** (expected improvement + why) → **Baseline metric** — record one named metric from `evolve_signals.py`'s fitness panel (e.g. `TeammateIdle(role)=N @7d`) as of proposal time → **Operator approval (HARD GATE)** — present hypothesis, scope, blast radius, and the baseline metric via AskUserQuestion BEFORE any edit; an unapproved item is recorded as `Trial: <hypothesis> → proposed` (or `Drift: … → proposed`) and NOT implemented → **Measurement** (reuse the Phase 0 audit; add no new infrastructure) → **Adopt or rollback** (adopt if the next cycle's Phase 0 audit shows the same named metric improved against the recorded baseline, else the Phase 1 self-correct/revert step). Record the outcome as a `Trial:`/`Drift:` line in the changelog `### Summary`, including the baseline and comparison metric values.
<!-- CANONICAL:SCIENTIFIC-TRIAL-PROTOCOL:END -->

## Genetic-Drift Operator

Drift introduces `{drift_rate}` bounded, fitness-INDEPENDENT neutral allele-substitutions per cycle (default 1; `drift=0` skips this operator entirely). It is the standing-variation arm that counters the documented `fable-monoculture` local-optimum collapse (`1ea590c`) — pure fitness-driven selection in a small population converges to monoculture, so drift maintains alternative formulations that may become advantageous when the platform shifts.

**Target selection is structural, NOT auditor-derived (MC2).** The no-signal trait set is materialized by the orchestrator from file STRUCTURE, never from the Phase 0 auditor's narrative output — call `src/user/claude-code/scripts/drift_target.sh <skill-path>/SKILL.md {drift_seed} {drift_rate} <cited-findings-file>` to compute it (the script enumerates the target file's candidate traits as its headings and top-level list items, subtracts any candidate the historical-auditor cited in a finding for that file — the remainder is the **no-signal set** — and indexes it with `{drift_seed} mod len(set)` to pick `{drift_rate}` traits). Fitness-independent by construction: the candidate list is structural and only auditor-flagged traits are excluded, so the pick can never land on a trait that the historical-auditor's selection is acting on. **Empty no-signal set (every candidate was cited) → drift is a no-op for that organism this cycle** (the script exits 0 with no output in this case).

<!-- CANONICAL:GENETIC-DRIFT-OPERATOR:BEGIN -->
**The variation is a neutral allele substitution** — replace the selected trait's current formulation with a semantically-equivalent alternative (re-word, reorder a checklist, merge/split adjacent bullets, swap an illustrative example). It is a substitution of an existing functional trait, so it is net-line-neutral and passes the Content Gate's Behavioral check (the trait still changes output; only its expression drifts).

**Gate + caveat.** Every drift proposal routes through the **same operator-approval HARD GATE** as adaptive trials (Scientific Trial Protocol) and is recorded as a `Drift:` line. **(S2 — reproducibility caveat:)** because `{drift_seed}` is the cycle identity, two runs *on the same date* reproduce the *same* drift target — they are not independent draws; across-generation stochastic variation comes from the date advancing. This is intentional (reproducibility/auditability over per-run randomness), so an operator re-running a cycle on the same date is not surprised.
<!-- CANONICAL:GENETIC-DRIFT-OPERATOR:END -->

---

## Argument Handling

Target skill(s) and historical-audit window are determined by `\$ARGUMENTS`:

- **No argument** (`/evolve-skills`): Improve ALL skills in `.claude/skills/*/SKILL.md` and `src/user/claude-code/skills/*/SKILL.md`. Historical audit window defaults to 7 days.
- **Skill name only** (`/evolve-skills tdd`): Improve only the named skill. Pre-flight step 5 validates the argument matches an existing skill directory.
- **`days=N`** (`day=N` accepted as alias, optional, e.g. `/evolve-skills tdd days=14` or `/evolve-skills day=7`): Override the historical-audit window. Default `7`. Reject values outside `1..90` and abort with a usage note.
- **`drift=N`** (optional, e.g. `/evolve-skills drift=2` or `/evolve-skills tdd drift=0`): Override the genetic-drift rate — number of neutral drift proposals per cycle (see the genetic-drift operator). Integer ≥ 0; default `1`; `drift=0` disables drift for the cycle. Reject negatives with the same usage-note-and-abort idiom as `days=N`.

**Parsing:** strip the `days=N` (or `day=N`) and `drift=N` tokens from `\$ARGUMENTS` FIRST; the remaining token (if any) is the skill name. A "skill-name token" means a non-`days=`/non-`day=`/non-`drift=` token remains after stripping — `/evolve-skills days=7 drift=0` has NO skill-name token (all-skills mode).

---

## Pre-flight

<!-- CANONICAL:OPERATOR-PROMPTS-CONVENTION:BEGIN -->
> **Operator prompts:** All operator-facing questions in Pre-flight MUST use `AskUserQuestion` with pre-generated selectable options (1-4 questions per call; **max 4 options per question regardless of `multiSelect`** — the API rejects >4); max 12-char `header`. If the operator needs to pick more than 4, ask a routing question first ("which category?") then a second narrow question. Free-text is permitted ONLY when the operator must paste material that doesn't fit options (logs, reproductions, large diffs, verbatim quotes) AFTER a structured option-led question routes them there.
<!-- CANONICAL:OPERATOR-PROMPTS-CONVENTION:END -->

Before spawning any agents:

1. **Verify evolution goal (HARD GATE)** — Team mode: adopt the verified goal from orchestrator prompt; re-verify if your understanding diverges. Standalone: `AskUserQuestion` with options "All skills", "Specific skill" (pair with `\$ARGUMENTS` or free-text follow-up for the skill name), "Specific dimension(s)" (follow-up multiSelect over the 8 dimensions), "Address operator-reported pain (skip to step 2)". Capture as `{verified_goal}`. Do not proceed until verified.
2. **Gather experience feedback** — Skip if orchestrator prompt already includes `experience_feedback`. Otherwise call `AskUserQuestion` with `multiSelect: true` and 4 options: `Coordination, handoff & orchestration gaps`, `Operator-prompt or output quality`, `Scope, budget or file-size mismatch`, `Other (free-text follow-up)`. If `Other`, follow up free-text. Store as `{experience_feedback}`.
3. **Resolve today's date and the shared scratchpad** — Run `date +%Y-%m-%d` via Bash and capture the result. Store this
   as `{today_date}`. This value MUST be substituted into every spawning template so agents use
   a consistent date for changelog entries. Also compute `{scratchpad}` via Bash `echo "$TMPDIR/evolve-skills-{today_date}"`, capturing the EXPANDED literal absolute path — substitute THAT into every template, never the unexpanded `$TMPDIR/...` string (teammate `Read` takes absolute paths only, and the sandbox remaps `$TMPDIR` per context)
   — a SHARED, non-session-scoped path under the harness `$TMPDIR` (verified empirically 2026-07-13: a spawned
   teammate CAN Read an absolute path here; do NOT use a per-session scratchpad convention, which is
   session-isolated and unreachable by sibling teammates) — and `mkdir -p {scratchpad}/phase0`. Phase 0
   completion writes the audit blocks there for Phase 1 reviewers to Read by path.
4. **Inventory skill files and sizes** — Run `find .claude/skills src/user/claude-code/skills -maxdepth 2 -name SKILL.md -exec wc -c {} + 2>/dev/null` (zsh aborts a no-match `*/SKILL.md` glob even with `2>/dev/null` when the top-level `skills/` root is absent). Mode per file is **TRIM** (over 65,000 bytes: consolidation primary, removed bytes must exceed added bytes) or **BALANCED** (under 65,000 bytes: additions allowed but offset by removals). Include byte count and mode in each agent's spawning prompt.
5. **If a skill-name token is present** (per Argument Handling parsing) — Verify it matches exactly one of `.claude/skills/<arg>/SKILL.md` or `src/user/claude-code/skills/<arg>/SKILL.md`. If neither exists, inform user and abort. If both exist (name collision), inform user, list both paths, and ask which to target via `AskUserQuestion` (options: each path; header `Path`).
6. **If no skill files found at all** — Inform user and abort.
7. **Check existing changelogs + surface last-run preamble** — Run `find docs/changelog/claude-code/skills -name '*.md' 2>/dev/null` (spawned agents need this list; a bare `*.md` glob aborts under zsh nomatch on a fresh repo). Then surface the latest prior run via `find docs/changelog/claude-code/skills -name '*.md' -exec grep -h '^## 20' {} + 2>/dev/null | sort -r | head -1`, reported as `Last evolve-skills changelog entry: <date>` (or "no prior runs") so a re-run isn't the only way to confirm prior completion.
8. **Resolve historical-audit window and drift parameters** — Parse `days=N` (default `7`; reject outside `1..90`) and `drift=N` (default `1`; `drift=0` disables; reject negatives) from `\$ARGUMENTS` per Argument Handling, storing as `{history_days}` and `{drift_rate}`. Run `src/user/claude-code/scripts/evolve_preflight.sh --cycle evolve-skills --days {history_days} --drift {drift_rate}` via Bash (DKT-292; single-homes the macOS/Linux `date`-branched cutoff computation, the transcript-availability probe, and the drift-seed derivation) and capture `history_cutoff_iso`/`history_cutoff_epoch_ms` (the historical-auditor template substitutes these directly into the `history.jsonl` timestamp filter — never let the auditor compute them), `transcript_probe`, `drift_rate`, and `drift_seed`. If `transcript_probe` starts with `SKIPPED:`, set `{historical_audit_findings}`, `{model_routing_findings}`, `{repetition_audit_findings}`, and `{bug_audit_findings}` to that literal string and skip the historical-auditor, model-routing-auditor, repetition-auditor, and bug-auditor spawns in Phase 0 (Phase 1 still runs; the SKIPPED string is written to each of the four `{scratchpad}/phase0/<auditor>.md` files at Phase 0 completion and Read by path like any other block). The audit is always-on otherwise. Store `{drift_rate}` and `{drift_seed}` for the genetic-drift operator — the seed is keyed to cycle identity (date), uncorrelated with which traits are failing — that uncorrelatedness IS its fitness-independence; the determinism makes the cycle's drift reproducible and reviewable.
9. **Scope-confirmation gate (HARD GATE)** — If no skill-name token is present (all-skills mode, per Argument Handling parsing) AND the step-4 inventory contains >3 skills, surface the planned scope via `AskUserQuestion` with options: "Proceed with all <N> skills", "Pick specific skill (free-text follow-up)", "Limit to <≤4 named skills>" (multiSelect follow-up from the inventory, max 4 — the AskUserQuestion option cap), "Abort". List skill names + total byte count in the question body so the operator sees estimated cycle weight before commit. Step 1 cannot show this (it runs before inventory). Skip silently in single-skill mode. Team mode: skip — the orchestrator already verified scope.
10. **Pin latest Claude Code features** — Anchor the docs-researcher-phase0 against the installed CLI rather than stale training knowledge. The same step-8 `evolve_preflight.sh` invocation (run with `--drift`) also emits `claude_version` and `changelog_source` — reuse them, do not re-run the script. If `claude_version` starts with `SKIPPED:`, set `{latest_features_digest}` to that literal string (mirroring the step-8 transcript-SKIPPED idiom) and skip the rest of this step. Otherwise: if `changelog_source` is a filesystem path, Read it directly; if it starts with `CURL_FAILED:`, attempt the WebFetch it names (requires a local WebFetch grant for `raw.githubusercontent.com` + `code.claude.com` + `mimir.bulbasaur.altf4.domains` in the gitignored per-user settings.local.json — add each if absent), falling back to the `SKIPPED:` sentinel it also names if WebFetch also fails. Once you have the raw changelog content, distil a concise digest — the installed version plus the most recent releases' headline entries (new/changed/deprecated, ≤30 lines) — and store it as `{latest_features_digest}` so the docs-researcher-phase0 template stays valid and the cycle still runs.

---

## Content Gate

**Every proposed addition MUST pass ALL 4 checks. Reject content that fails ANY check.**

1. **Executable** — Can Claude do this in a stateless session? Reject: mentoring, meetings, relationship-building, career development.
2. **Behavioral** — Does removing it change the skill's output? Reject: general LLM knowledge.
3. **Non-redundant** — Already expressed elsewhere in the file? Reject duplicates even if reworded.
4. **Concrete** — Specific action, check, or output format? Reject aspirational fluff ("think holistically", "drive excellence").

---

<!-- CANONICAL:IMPACT-CLASS:BEGIN -->
**Impact classification & Findings Ledger (behavioral-delta test).** Every applied AMPLIFY/CULL is classified by its DIFF, not its content: **SUBSTANTIVE** — the old→new delta adds, removes, or alters a rule/gate (a MUST/never/reject-class condition), a workflow step or its ordering, a command/tool invocation/template field, or an output-format field/disposition, such that an executor following old vs new text would act differently or produce different output; **COSMETIC** — rewording with no behavioral delta. (Genetic-Drift substitutions are exempt from this classification and the floor below.) The orchestrator maintains a per-cycle **Findings Ledger**: at Phase 0 completion, enumerate every actionable finding from the captured audit blocks (Suggested focus areas, FIX/PREVENT items, innovation lenses) with an ID (H1, B2, I3, …); before Phase 2 may start, every ledger entry carries exactly one terminal disposition — **APPLIED-SUBSTANTIVE** (cite CHANGE + file), **APPLIED-COSMETIC**, **REJECTED** (the failed verification's concrete result, or the named Content Gate check with the failing text quoted), **DEFERRED** (Docket issue ID, or `Trial: … → proposed` where the operator HARD GATE declined), or **ALREADY-ENCODED** (cite the existing text). A verified finding with no disposition is reject-class. **Substantive floor:** every organism with ≥1 verified finding ships ≥1 SUBSTANTIVE change this cycle, or its ledger records the explicit non-APPLIED disposition(s) explaining why — a disposition missing its parenthesized evidence is INVALID: the finding stays open and blocks Phase 2. **Zero-substantive tripwire:** a cycle with ≥1 verified finding and zero APPLIED-SUBSTANTIVE across all organisms cannot self-certify the floor — the orchestrator presents the full Findings Ledger at the operator HARD GATE for explicit sign-off before Phase 2. **Worked example:** finding H3 ("require test verification before close") greps to text already present in Execution Workflow step 5 → **ALREADY-ENCODED** (cite step 5); finding B2 ("squash all commits") greps to nothing but fails the Non-redundant Content Gate check (commit hygiene already covered elsewhere) → **REJECTED** (quote the failing check).
<!-- CANONICAL:IMPACT-CLASS:END -->

---

## Changelog Format

All changes tracked in `docs/changelog/claude-code/skills/<skill-name>.md` (create directory if needed).

**Exact format — no deviations:** `# Changelog: <skill-name>` (kebab-case) > `## YYYY-MM-DD` (no suffixes) > exactly 4 H3 sections in order: `### Summary` (1-2 sentences), `### Changes` (bulleted with reasoning), `### Dimensions Evaluated`, `### Rename` (details or "No rename.").
**Selection recording (S1):** `### Changes` records only AMPLIFY and CULL dispositions, each as one bullet carrying its impact tag and citing its fitness signal (e.g. `CULL[SUBSTANTIVE]: removed X — cited TeammateIdle×3`); RETAIN is the unstated default for untouched traits and is never enumerated, protecting the 20-line cap — but a verified Phase 0 finding never silently RETAINs (Findings Ledger, CANONICAL:IMPACT-CLASS). `### Summary` carries one `Findings: N → S sub / C cos / R rej / D def / E enc` line after any `Trial:`/`Drift:` lines.

**Rules:** Max 20 lines per entry. **NEVER modify, edit, or replace existing changelog entries — always prepend a NEW entry below H1, even if one already exists for today's date** (stacked same-date entries are fine; the topmost is the latest). Sole scoped exception: the Phase 4 History Compaction phase may replace committed older entries with ledger lines per the retention-compaction master. Never read full history — consult only the most recent `## <date>` entry. Report honestly if no improvements found. **Normalization:** after prepending, run `python3 src/user/claude-code/scripts/changelog_normalize.py docs/changelog/claude-code/skills/<skill-name>.md --artifact-name <skill-name>` — it fixes H1, strips H2 suffixes, renames non-standard H3s, deletes extras, truncates over 20 lines, applied ONLY to the new entry just prepended, and refuses to write (nonzero exit) if the change would touch any prior entry. **Trial / Drift convention:** if a cycle included a scientific trial, prepend `Trial: <hypothesis> → <outcome>` as the first line inside `### Summary`; if a cycle applied a genetic-drift substitution (per the Genetic-Drift Operator), prepend a parallel `Drift: <neutral variation applied> → <outcome>` line in the same `### Summary`. The retention-compaction policy preserves both `Trial:` and `Drift:` lines verbatim through compaction.

---

## Orchestration Workflow

### Team Setup & Agent Lifecycle

1. Join the session's single implicit team on your first `Agent(name=..., ...)` spawn (Phase 0 below; the runtime ignores `team_name`).
2. `TaskCreate` all tasks up-front: Phase 0 ("Docs Research", "Historical Audit", "Repetition Audit", "Bug Audit", "Innovation Scan", "Model Routing Audit"), one "Review <name>" per target skill, "Coherence & Renames", "Disambiguation", and "History Compaction".

| Phase | Agents | Lifecycle |
|---|---|---|
| 0 | `docs-researcher-phase0`, `historical-auditor`, `repetition-auditor`, `bug-auditor`, `innovation-scanner`, `model-routing-auditor` | Spawn parallel → all complete → shut down all before Phase 1 |
| 1 | `review-<name>` per target skill | Spawn parallel → per agent: apply changes → shut down (don't wait for siblings) |
| 2 | `coherence-reviewer` (`distinguished-engineer`, `gold`) | Spawn after ALL Phase 1 applied → apply fixes → shut down |
| 3 | `disambiguation-reviewer` (`distinguished-engineer`, `gold`) | Spawn after Phase 2 applied and coherence-reviewer shut down → apply fixes → shut down |
| 4 | `history-compactor` (gated) | Spawn after Phase 3 only if the History Compaction `wc -l` gate trips → compact → shut down before team cleanup |

**Self-budget.** This SKILL.md is an ordinary member of the skill population governed by the standard skill byte budget.

**Shutdown protocol:** `SendMessage(to="<name>", message={type: "shutdown_request", reason: "<phase> complete"})`. Teammate replies with `shutdown_response` **addressed to the orchestrator** (never to a peer). If rejected, address the `reason` and re-request. No response → see Crash & Stall Recovery. (Orchestrator-originated shutdown is intentional: evolve orchestrators drive their own team's lifecycle, unlike leaf-review skills where ephemeral reviewers AWAIT the orchestrator's `shutdown_request` per `src/user/claude-code/agents/team-lead.md` Rule 7.)

### Crash & Stall Recovery

Detect failure via: (a) `TeammateIdle` notification or `Monitor` stream silence past expected progress — ≥2 turns with no new tool call is stall evidence (stall); (b) `shutdown_request` gets no response within one turn (crash); (c) Agent() returns an explicit error; (d) a teammate that dies on an API error self-reports `failed` to the orchestrator — a faster, cleaner crash signal than Monitor-silence heuristics.

- **Nudge before re-spawn (stall only).** For a stuck/idle teammate, one `SendMessage` nudge wakes it to retry immediately — cheaper than a fresh spawn; escalate to `-r2` only if the nudge draws no new tool call within one turn.
- **Re-spawn exactly once** with the `-r2` suffix, supplying a `Resume context:` block that lists (a) the prior partial report, (b) the task ID to claim, (c) the target file.
<!-- CANONICAL:SECOND-FAILURE-RECOVERY:BEGIN -->
- **Second failure**: mark task completed and skip; never do the work directly. Phase 1 reviewer → record "No review performed — agent unavailable" in the changelog. Phase 0 auditor → write `"UNAVAILABLE: <name> failed twice"` as the entire content of that auditor's `{scratchpad}/phase0/<name>.md` (its findings-token value) so the Phase 1 Read-by-path stays valid.
<!-- CANONICAL:SECOND-FAILURE-RECOVERY:END -->
- **Compaction recovery**: re-read verified goal, `TaskList()`, latest changelog entries for completed targets, and the active phase template before any new `SendMessage`/`Agent` call.

### Phase 0: Documentation Research & Historical Audit

Spawn SIX agents in parallel per the templates below: `docs-researcher-phase0` (staff-engineer), `historical-auditor` (senior-engineer, needs Bash for read-only grep/jq over `~/.claude/projects/`, `~/.claude/history.jsonl`, `.claude/agent-memory/`), `repetition-auditor` (senior-engineer, needs Bash for read-only grep/jq over `~/.claude/projects/` and `~/.claude/history.jsonl`, mining unintentional cross-session repetition GLOBALLY rather than per-skill), `bug-auditor` (senior-engineer, needs Bash for read-only grep/jq over `~/.claude/projects/` and `~/.claude/history.jsonl`, mining failed tool calls / incorrect-parameter bugs GLOBALLY rather than per-skill), `innovation-scanner` (distinguished-engineer), and `model-routing-auditor` (senior-engineer, needs Bash for read-only grep/jq over `~/.claude/projects/`, `~/.claude/history.jsonl`, `.claude/agent-memory/`). Skip `historical-auditor`, `repetition-auditor`, `bug-auditor`, and `model-routing-auditor` if pre-flight step 8 flagged SKIPPED. Assign Phase 0 tasks via `TaskUpdate`. Each agent's final `SendMessage` report is captured verbatim as `{docs_research_findings}`, `{historical_audit_findings}`, `{repetition_audit_findings}`, `{bug_audit_findings}`, `{innovation_findings}`, and `{model_routing_findings}` for Phase 1 template substitution. **At Phase 0 completion the orchestrator Writes each captured block to its own file** `{scratchpad}/phase0/<auditor>.md` — one per auditor: `docs-researcher-phase0`, `historical-auditor`, `repetition-auditor`, `bug-auditor`, `innovation-scanner`, `model-routing-auditor` — so Phase 1 reviewers Read them by path instead of receiving ~6 full reports inline-pasted (a large token cut on multi-agent runs). **A SKIPPED (pre-flight step 8) or UNAVAILABLE (Crash & Stall Recovery) auditor still gets its file — write the literal sentinel string as the file's entire content** — so all 6 paths always exist and Phase 1 never special-cases a missing file. From the captured blocks the orchestrator also materializes the Findings Ledger — one ID per actionable finding (CANONICAL:IMPACT-CLASS) — and **Writes it to `{scratchpad}/findings-ledger.md`**, making the ledger a persistent artifact the Phase 2 gate reads (it survives context compaction, unlike ephemeral orchestrator-context state). Do both Writes before spawning Phase 1.

### Phase 1: Review & Improve (parallel)

Spawn one @staff-engineer teammate per target skill. **Spawn all in the same turn** to maximize parallelism.
Assign tasks via `TaskUpdate(taskId=<id>, owner="review-<name>", status="in_progress")`.

Each teammate is read-only (no file edits) and follows the Phase 1 spawning template below.

**After each Phase 1 teammate completes**, the orchestrator:
1. Reviews recommendations against the **Content Gate** — reject any failing check
2. Applies approved changes via Edit (Read each target file in-session before its first Edit; after any grep/mv that shifts line numbers, re-Read and target content strings, never stale line numbers; apply exactly one Edit per approved CHANGE — no silent merge or drop); runs `wc -c` AFTER applying — the post-apply count is the only budget truth (never trust reviewer NET_BYTES figures; a still-over-budget file is NOT done — keep trimming); verify EVERY changed reference/CLI/feature claim against ground truth (`<cmd> --help`, Grep/Read) before applying — reject drift; classifies each applied CHANGE's impact from its actual diff (behavioral-delta test, CANONICAL:IMPACT-CLASS), downgrading any reviewer-claimed SUBSTANTIVE that fails it
3. Writes/normalizes `docs/changelog/claude-code/skills/<name>.md` per Changelog Format
4. Aggregates renames and coherence issues for Phase 2
5. **Self-correct**: if changes worsen clarity without behavioral gain, revert and retry

**Defer parity-bound and shared-frontmatter findings to Phase 2 — never apply piecemeal.** Any Phase 1 finding that edits a shared frontmatter line or a `CANONICAL`-tagged block maintains byte-identical parity across the skill family; applying one reviewer's isolated recommendation breaks parity, and per-skill reviewers can CONFLICT. Flag these, do NOT apply in Phase 1, route to Phase 2 for a single family-wide lockstep call, and settle conflicting recommendations EMPIRICALLY (grep the actual usage) before applying. Before adopting any newly-shipped frontmatter field, also (a) read its official LIFECYCLE / clearing semantics, not just headline behavior (a field that "clears on next message" is a per-turn hint, not a durable control); (b) check whether the skill forks (`context: fork`) or runs in the caller's context — an in-context tool-removing field strips that tool from the CALLER's own turn. Also check prior changelogs for an existing family-wide decision before re-proposing — a satisfied or rejected recommendation is a NO-OP, not a re-add. Parity-bound prose is NOT only `CANONICAL`-tagged blocks: before recommending any prose TRIM, `grep -F` a distinctive phrase of the target paragraph across the sibling evolve-*/SKILL.md files; a verbatim hit in 2+ marks it parity-bound.

**Triage every harvested pitfalls lesson — apply, no-op, or track; never drop.** For each lesson in the Phase 0 CROSS-PROJECT PITFALLS MANIFEST (and any Phase 1 finding derived from it): (a) if ALREADY encoded in the target skill, it is a NO-OP — confirm against the current file (captured-resolution check) and note "already applied" rather than re-adding; (b) if encodable as a definition edit this cycle, apply it via Phase 1 (deferring shared-frontmatter / `CANONICAL`-block edits to Phase 2 per the rule above); (c) if it CANNOT be applied this cycle — it needs investigation, a cross-cutting decision, or remediation outside the skill files, or names a target outside this cycle's scope — capture it as a Docket tracking issue (delegate creation to a `project-manager` spawn; per role boundaries the orchestrator does not create issues directly) rather than silently dropping it. Never hand-Edit any `pitfalls.md`; the sole sanctioned mutation is distill-time ledgering per the retention-compaction master — after applying (or confirming already-encoded) a lesson's definition edit, run `~/.claude/scripts/pitfalls_distill.sh` to replace that one entry with its ledger line (THIS repo's files and the centralized home only; Docket-tracked dispositions and cross-project files stay untouched; a centralized-home entry's encoding must sit under `src/user/claude-code/` — an evolve edit to project-local `.claude/skills/` satisfies only in-repo entries, so exit 8 there is by design).

**Phase 1 SendMessage triggers** (orchestrator-only relay — peer-to-peer creates race conditions across independent edit surfaces; Phase 2 consolidates cross-cutting items):
- A finding affects another skill (include affected skill name)
- The teammate needs delegation (voting, sub-agents)
- The teammate is blocked

Cross-cutting items append to a running notes list passed verbatim into the Phase 2 prompt's "Phase 1 Coherence Issues" section. `TaskList()` tracks progress.

### Phase 2: Coherence & Renames (sequential)

Gate: `TaskList()` shows all Phase 1 tasks `completed`, all Phase 1 edits applied, every Phase 1 teammate shut down per lifecycle rules, AND the Findings Ledger at `{scratchpad}/findings-ledger.md` complete — exactly one terminal disposition per Phase 0 finding (CANONICAL:IMPACT-CLASS), verified mechanically via `python3 src/user/claude-code/scripts/findings_ledger_check.py {scratchpad}/findings-ledger.md` (exit 0 required; 1 = an OPEN/evidence-less entry blocks Phase 2, 2 = ledger missing/empty/unparseable). Only then spawn a single @distinguished-engineer (read-only) coherence-reviewer; assign via `TaskUpdate`.

The Phase 2 teammate:
1. Reads ALL skill files (freshly improved versions)
2. Verifies Phase 1 rename recommendations and prepares rename instructions
3. Checks coherence: no scope overlaps, consistent terminology, shared conventions followed,
   accurate references, correct agent types in templates, consistent argument handling
4. Marks task completed and reports structured recommendations

**After completion**, the orchestrator executes renames (reference updates scoped to LIVE definition files only — `src/user/claude-code/skills/`, `.claude/skills/`, `src/user/claude-code/agents/`; never changelogs/pitfalls/prose), applies coherence fixes via Edit,
and updates changelogs for affected skills. Apply each parity-bound fix flagged in Phase 1 as the identical OLD→NEW to ALL family members in one turn, then verify byte-identity (`grep -h '^<shared-line>' <files> | sort -u` returns a single line), then run `src/user/claude-code/scripts/doctrine_check.sh` (exit 0 required — its byte-parity arm re-verifies every manifest-registered `CANONICAL:<TAG>` block across ALL carriers, catching a diverged carrier the single-line grep does not cover).

**Speciation / extinction gate (highest blast radius).** Speciation (new skill) and extinction (retiring a redundant skill) are gated Phase 2 events requiring an EVIDENCED trigger — never arbitrary. **Speciation** fires on *cladogenesis* (one skill's traits serve two divergent phenotypes producing role-confusion stalls — `TeammateIdle` clustering, scope-citing shutdown-rejections → split) or *niche colonization* (a recurring fitness gap no genome absorbs within the per-skill byte budget (pre-flight step 4) → new skill). **Extinction** fires on redundancy (two skills, highly overlapping genomes, low combined fitness → retire one). Both are architectural decisions requiring BOTH the Scientific Trial Protocol **operator HARD GATE** AND **vote** consensus before any create/retire. **Biodiversity invariant (S3):** before any CULL or extinction, identify the niche's defining behavior keyword (a capability keyword or rule name, NOT a CANONICAL tag — that matches every family carrier) and `grep -lE '<niche-token>' .claude/skills/*/SKILL.md src/user/claude-code/skills/*/SKILL.md` excluding the culled organism; the carrier-count is the remaining provider-file count — if it would reach 0 (monoculture), the CULL is BLOCKED pending a docs-researcher-phase0 confirmation that the platform made the niche obsolete. Do NOT create or retire any organism in this skill — that is a future cycle's gated action.

### Phase 3: Disambiguation (sequential)

<!-- CANONICAL:DISAMBIGUATION-CHARTER:BEGIN -->
**Phase 3 Disambiguation charter.** Surface and resolve residual ambiguity Phase 2 Coherence does NOT address: (1) confusable names/triggers/terms, (2) wording with multiple readings, (3) overlapping ownership between organisms. Coherence asks "do the pieces agree?"; disambiguation asks "can a reader tell the pieces apart and know who owns what?"
<!-- CANONICAL:DISAMBIGUATION-CHARTER:END -->

Gate: `TaskList()` shows the Phase 2 task `completed`, ALL Phase 2 fixes applied by the orchestrator, AND the `coherence-reviewer` shut down per lifecycle rules. Only then spawn a single read-only `disambiguation-reviewer` (`subagent_type="distinguished-engineer"`) over the post-coherence skill family and assign the Phase 3 task — disambiguation reasons over the *post-coherence* genome so it never re-litigates a fix coherence is still applying.

<!-- CANONICAL:PHASE3-DISAMBIGUATION-BOUNDARY:BEGIN -->
**Boundary (the load-bearing distinction — every finding must satisfy both arms or it routes to Phase 2 instead):** a Phase 3 finding's targets each independently PASS every Phase 2 coherence invariant (references resolve, CANONICAL bytes match within family, role claims map to a real owner, ladders/names spelled consistently) yet still FAIL clarity (a competent reader or routing classifier could confuse two concepts, read one instruction two ways, or be unable to name the single owner of a responsibility). A target that FAILS a coherence invariant is a Phase 2 finding, not Phase 3.
<!-- CANONICAL:PHASE3-DISAMBIGUATION-BOUNDARY:END -->

**Mechanism (read-only-reviewer → orchestrator-applies, same shape as Phase 2 — teammates never edit):** the reviewer Reads the freshly-coherent skill files (`.claude/skills/*/SKILL.md`, `src/user/claude-code/skills/*/SKILL.md`), emits structured disambiguation findings, and the orchestrator applies every edit (Read each target in-session before its first Edit; one Edit per finding; any finding touching a CANONICAL block or shared frontmatter applied family-wide in lockstep with byte-identity verification). The reviewer reports `No disambiguation findings.` when the family is clean — the stage always spawns its reviewer and no-ops cleanly. Shut down the `disambiguation-reviewer` per the orchestrator-driven `shutdown_request` protocol before the next phase.

### Phase 4: History Compaction (terminal, gated)

Changelog arm ONLY — evolve-skills has no pitfalls arm; this phase never touches any `pitfalls.md`. Gate: after Phase 3 fixes are applied and the disambiguation-reviewer is shut down, the orchestrator runs one `find docs/changelog/claude-code/skills -name '*.md' -exec wc -l {} + 2>/dev/null` pass against the 300-line per-file budget. All files under budget → no compactor spawned; record a no-op line in the final report. Otherwise spawn ephemeral `history-compactor` (senior-engineer, Bash + Edit) for the over-budget files.

Per over-budget file the compactor keeps the 10 most recent date-headed entries verbatim (keep-window, count pattern `^## 20`), compacts older entries oldest-first until under budget, and replaces each compacted entry with exactly one ledger line in a terminal `## Compacted history` section — any `Trial:` line is preserved verbatim in its ledger line (verbatim preservation takes precedence over the ≤160-char distillation cap). It then prepends one compaction entry recording the act — a normal Changelog Format entry in every respect, counted in the master's parity formula. Only content reachable at HEAD (`git show HEAD:<file>`) may be compacted; uncommitted entries are never touched.

The compactor's report MUST evidence invariant checks 0-5 per the retention-compaction master (pure-addition precondition, full-entry HEAD containment, diff-shape proof, parity formula, Trial preservation, post-compaction budget) — formulas and hunk shapes live in the retention-compaction master; do not restate them. On any failed check the orchestrator rejects the compaction and the compactor reverts its own edits (leaving the cycle's pre-existing additions intact) or leaves the file untouched, with the failure flagged in the final report — never ship a partial compaction. Shut down the compactor before team cleanup.

### Wrap-up & Team Cleanup

After Phase 4 (or its no-op gate check) completes:

1. Clean up the team (the session's single implicit team — no name needed) per lifecycle rules (coherence-reviewer and any history-compactor are already shut down); its `~/.claude/teams/` resources are auto-removed at session end.
2. Run `find .claude/skills src/user/claude-code/skills -maxdepth 2 -name SKILL.md -exec wc -c {} + 2>/dev/null`. Consolidate any over the per-skill byte budget (pre-flight step 4).
3. Report: files modified, before/after byte counts, improvements, renames/coherence fixes, the Disambiguation outcome (findings applied / "No disambiguation findings"), cross-communication events, the Findings Ledger outcome (per finding: ID → terminal disposition; substantive-floor result per organism), the cross-project pitfalls harvest outcome (lessons applied as edits / captured as tracking issues with IDs / already-present), the History Compaction outcome (per file: compacted or no-op, plus invariant-check 0-5 results per the retention-compaction master), and reminder that NO changes have been committed.
4. **Post-cycle coherence gate (recommend to operator).** Only when this cycle actually modified files (skip this suggestion on a true no-op cycle): these edits are un-committed and not yet audited for cross-family drift — recommend the operator run `/evolve-coherence` before committing, to catch any parity or cross-reference drift this cycle introduced. evolve-coherence is the post-edit gate for standalone evolve-skills runs; it never edits, only reports and routes.

---

## Spawning Templates

**Template sourcing.** The six Phase-0 spawn prompts below (Documentation Research, Historical Audit, Repetition Audit, Bug Audit, Innovation Scan, Model Routing Audit) are single-homed in `src/user/claude-code/skills/team-doctrine/references/evolve-phase0-templates.md`. Read that file ONCE at Phase-0 spawn time; for each prompt, paste the referenced section and substitute this cycle's spawn-time token VALUES: `{TARGET_NOUN}`=`skill`, `{TARGET_NOUN_CAP}`=`Skill`, `{A_TARGET_NOUN}`=`a skill`, `{TARGETS_LINE}`=`Target skills: {target_skills}`, `{TARGET_GLOB}`=`.claude/skills/*/SKILL.md and src/user/claude-code/skills/*/SKILL.md`, `{FOCUS_AREAS}`=`Skills (frontmatter, substitutions, discovery, subagents), Agent Teams (lifecycle, coordination, shutdown), Hooks (skill-scoped hooks, event types), Changelog (recent releases, breaking changes).`, `{MENTION_COUNT_LINE}`=the `/<skill>` invocation-count line (reference §1a literal, evolve-skills form), `{PROMQL_LABEL}`=`skill_name`, `{HARVEST_BLOCK}`=the reference's §2 HARVEST block. Runtime tokens (`{history_days}`, `{history_cutoff_iso}`, `{history_cutoff_epoch_ms}`, `{target_skills}`, `{latest_features_digest}`) pass through unchanged. If the file or a named section is missing, ABORT the cycle loudly (`Error: shared Phase-0 template missing: {section}`) — never spawn a Phase-0 teammate with a hand-reconstructed prompt.

### Phase 0: @staff-engineer (Documentation Research)

Substitute `{latest_features_digest}` with the version-anchored changelog digest pinned in pre-flight step 10; `{TARGET_NOUN}`/`{TARGET_GLOB}`/`{FOCUS_AREAS}` per the Template-sourcing VALUES above.

Source: **§8 Docs Research — tokenized template** in `evolve-phase0-templates.md`. Substitute the spawn-time tokens with the Template-sourcing VALUES above; runtime token `{latest_features_digest}` passes through. Spawns `Agent(name="docs-researcher-phase0", subagent_type="staff-engineer", model="opus")`.

### Phase 0: Historical Audit (one block per target skill)

Substitute `{target_skills}` with the list of skills Phase 1 will review (single skill from `\$ARGUMENTS`, or all `.claude/skills/*/SKILL.md` + `src/user/claude-code/skills/*/SKILL.md`). This audit is per-skill, does no clustering, and feeds Phase 1 directly.

Source: **§3b Historical Audit — evolve-skills variant** in `evolve-phase0-templates.md`. Substitute `{HARVEST_BLOCK}` (reference §2); runtime tokens pass through. Spawns `Agent(name="historical-auditor", subagent_type="senior-engineer", model="sonnet")`.

### Phase 0: Innovation Scan

Source: **§7 Innovation Scan — tokenized template** in `evolve-phase0-templates.md`. Substitute the spawn-time tokens with the Template-sourcing VALUES above; runtime tokens pass through. Spawns `Agent(name="innovation-scanner", subagent_type="distinguished-engineer", model="fable")`.

### Phase 0: Model Routing Audit

Skip if pre-flight step 8 flagged SKIPPED (same gate as historical-auditor). Substitute `{target_skills}`, `{history_days}`, `{history_cutoff_iso}`, `{history_cutoff_epoch_ms}` from pre-flight.

Source: **§6a Model Routing Audit — tokenized template** in `evolve-phase0-templates.md`. Substitute the spawn-time tokens with the Template-sourcing VALUES above; runtime tokens pass through. Spawns `Agent(name="model-routing-auditor", subagent_type="senior-engineer", model="sonnet")`.

### Phase 0: Repetition Audit

Skip if pre-flight step 8 flagged SKIPPED (same gate as historical-auditor). Substitute `{history_days}`, `{history_cutoff_iso}`, `{history_cutoff_epoch_ms}` from pre-flight. Scope is GLOBAL across the whole mined window — NOT filtered by target skill (unlike historical-auditor's per-skill grep).

Source: **§4 Repetition Audit — shared template** in `evolve-phase0-templates.md` (no spawn-time tokens; runtime tokens pass through). Spawns `Agent(name="repetition-auditor", subagent_type="senior-engineer", model="sonnet")`.

### Phase 0: Bug Audit

Skip if pre-flight step 8 flagged SKIPPED (same gate as historical-auditor). Substitute `{history_days}`, `{history_cutoff_iso}`, `{history_cutoff_epoch_ms}` from pre-flight. Scope is GLOBAL across the whole mined window — NOT filtered by target skill (unlike historical-auditor's per-skill grep).

Source: **§5 Bug Audit — shared template** in `evolve-phase0-templates.md` (no spawn-time tokens; runtime tokens pass through). Spawns `Agent(name="bug-auditor", subagent_type="senior-engineer", model="sonnet")`.

### Phase 1: @staff-engineer (Review & Improve)

Spawn one teammate per target skill. Substitute `<name>`, `<skill-path>`, `{byte_count}`,
`{mode}`, `{today_date}`, `{verified_goal}`, `{experience_feedback}`, and `{scratchpad}` for each.

```
Agent(name="review-<name>", subagent_type="staff-engineer", model="opus", prompt="...")

Target: <skill-path>/SKILL.md | Skill: <name> | Size: {byte_count} bytes | Mode: {mode}
Verified goal: {verified_goal} (pre-verified — re-verify if your understanding diverges)
Experience feedback: {experience_feedback}

## Size Budget

65,000-byte hard limit. **TRIM**: removed bytes must exceed added bytes at cycle net (the sum over this file's applied changes — a SUBSTANTIVE addition may ride if consolidation elsewhere in the same cycle pays for it). **BALANCED**: additions offset by removals, EXCEPT a SUBSTANTIVE-classified change (CANONICAL:IMPACT-CLASS) may land un-offset provided post-apply `wc -c` stays under the hard limit; COSMETIC additions are always offset or rejected. Report NET_BYTES per change as `len(NEW_STRING) − len(OLD_STRING)` (exact; byte deltas need no soft-wrap caveat); the orchestrator's post-apply `wc -c` remains the only budget truth.

## Context

Date: {today_date} (for changelog). Read latest changelog entry from docs/changelog/claude-code/skills/<name>.md, docs/spec/ selectively, other skill files via ranged Read of the relevant section (both .claude/skills/ and src/user/claude-code/skills/; a blanket 80-line cap can hide a cross-file contract past line 80). Prioritize the operator experience feedback below.

## Phase 0 Audit Findings — READ THESE PATHS (not pasted inline)
Your Phase 0 inputs are materialized on disk, one file per auditor. Read each before your task:
- `{scratchpad}/phase0/docs-researcher-phase0.md` — Claude Code Documentation Research
- `{scratchpad}/phase0/historical-auditor.md` — Historical Audit (find your own skill's block — strongest signal)
- `{scratchpad}/phase0/innovation-scanner.md` — Innovation Suggestions
- `{scratchpad}/phase0/model-routing-auditor.md` — Model Routing Audit
- `{scratchpad}/phase0/bug-auditor.md` — Bug Audit (GLOBAL scope)
- `{scratchpad}/phase0/repetition-auditor.md` — Repetition Audit (GLOBAL scope)
A file whose entire content is `SKIPPED: …` or `UNAVAILABLE: …` (or a missing/empty file) means that auditor produced no usable findings — treat it as an empty block, nothing to verify from it. This cycle's Findings Ledger is at `{scratchpad}/findings-ledger.md`.
> **Phase 0 findings are SIGNALS-TO-VERIFY, never accepted facts.** Before any CHANGE relies on a Docket CLI command, frontmatter field, or feature claim from the audit blocks above, re-confirm it against ground truth (`<cmd> --help` for Docket; Grep/Read the codebase for a feature/pattern). A change built on a fabricated "verified" finding is reject-class — the #1 recurring cross-skill failure (e.g. a prior audit claimed `docket issue state`/`stuck` and a close `-r/--reason` flag that do not exist).
> Prioritize the Suggested focus areas from your skill's block; cite example session refs in the `CONTEXT:` field of any CHANGE driven by historical signals. Model routing changes MUST be grounded in measured distribution data from Model Routing Audit Findings — do NOT propose routing changes without evidence citations.

## Content Gate
Apply 4-check gate (Executable, Behavioral, Non-redundant, Concrete) — reject additions failing ANY check. Flag any unescaped `\$`+digit (e.g. `\$1`, `\$ARGUMENTS`) in documentary prose — it renders empty; escape as `\$`.

## Your Task
Evaluate <skill-path>/SKILL.md against ALL 8 dimensions in TWO ORDERED PASSES. Pass A — Selection first: verify and apply this target's Phase 0 findings (AMPLIFY/CULL with cited signal + impact class per CANONICAL:IMPACT-CLASS); applying a verified finding outranks trimming. Pass B — Over-Engineering: pay for Pass A and reduce, governed by the Size Budget. Do not default to approval; do not default to RETAIN — every finding for this target gets a ledger disposition.
**Selection disposition (natural selection — see CANONICAL:EVOLUTION-MODEL).** The Phase 0 audit blocks above ARE the fitness assay; assign every trait you act on exactly one disposition — AMPLIFY (strengthen a trait that demonstrably reduces a failure class) or CULL (remove a trait correlated with recurring failure or superseded), both REQUIRING a cited fitness signal from those blocks (session ref, pitfalls re-fire, stall, routing datum); RETAIN is the unstated default for untouched traits. A non-RETAIN disposition without a cited fitness signal is reject-class.

1. **Skill Design Quality**: Frontmatter (`effort`, `argument-hint`, `allowed-tools`), argument handling, structure-brevity balance.
2. **Actionability**: Specific enough for reliable execution? Clear phases, concrete templates, defined outputs.
3. **Completeness**: Edge cases, error conditions, pre-flight checks, all workflow paths.
4. **Over-Engineering (Pass B)**: Verbose, redundant, or low-value sections to trim or consolidate — pays for Pass A within the Size Budget.
5. **Orchestration & Agent Teams**: Proper agent use, parallelism, correct types, coordination. Templates must include explicit SendMessage triggers — flag hub-and-spoke if >50% of paths route through one agent.
6. **Coherence**: Scope overlaps, terminology, shared conventions, accurate references.
7. **Spec Alignment**: Alignment with `docs/spec/` project patterns.
8. **Rename**: Only if compelling — stability has value.

## Rules
- **Read-only** — analyze and recommend only; orchestrator applies all edits.
- **No sub-agents**: Do NOT invoke `/vote`, `Skill()`, or `Agent()`; do not form/manage a team. SendMessage the orchestrator for delegation.
- **No peer-to-peer SendMessage** — orchestrator is the only relay.
- **SendMessage orchestrator IMMEDIATELY** on (a) cross-cutting findings (include affected skill name AND which root: `.claude/skills/` or `src/user/claude-code/skills/`), (b) scope expansion beyond target, or (c) blocker.

## Output Format
### Summary
<1-2 sentences or "No changes needed"> | Net byte change: <+/- bytes>
### Recommended Changes
For each: `CHANGE <n>: <title>` / `DIMENSION:` / `IMPACT:` (SUBSTANTIVE | COSMETIC — behavioral-delta test) / `FINDING:` (Findings Ledger ID(s), or `none` if reviewer-originated) / `CONTEXT:` / `NET_BYTES:` / `OLD_STRING:` / `NEW_STRING:` (use `<REMOVE>` to delete, `<INSERT_AFTER>` to add)
### Changelog Entry (under 20 lines, 4 sections: Summary, Changes, Dimensions Evaluated, Rename)
### Rename Recommendation
### Coherence Issues
```

### Phase 2: @distinguished-engineer (Coherence & Renames)

```
Agent(name="coherence-reviewer", subagent_type="distinguished-engineer", model="fable", prompt="...")

Check cross-skill coherence and recommend fixes.
Today's date: {today_date}. **Read-only** — the orchestrator applies all changes.
**No sub-agents** — do NOT invoke `/vote`, `Skill()`, or `Agent()`; do not form/manage a team. SendMessage the orchestrator for delegation. When your review is complete, SendMessage the orchestrator with the complete Output Format block verbatim.

## Renames to Execute
<list recommended renames, or "No renames were recommended.">

## Phase 1 Coherence Issues
<list issues from Phase 1, or "None reported.">

## Task
1. Read ALL skill files in .claude/skills/*/SKILL.md and src/user/claude-code/skills/*/SKILL.md
2. If renames listed, verify and prepare rename instructions (dir, frontmatter, references, changelog)
3. Check coherence: no scope overlaps, consistent terminology, accurate references,
   correct agent types in templates, consistent conventions and argument handling
4. Check cross-communication: verify orchestrator-to-teammate SendMessage trigger completeness, flag hub-and-spoke patterns (>50% routing through one agent)
5. Run `python3 src/user/claude-code/scripts/symmetry_check.py --check all` (non-zero exit = drift; mechanizes the manual eyeball for the byte-symmetric CANONICAL:IMPACT-CLASS block). Flag any drift.
6. Run `python3 src/user/claude-code/scripts/symmetry_check.py --check mimir-note` (non-zero exit = the historical-auditor Mimir note is missing from one or more of the §3a/§3b/§3c historical variants in `evolve-phase0-templates.md`; mechanizes the manual eyeball — do NOT flag structural differences as drift, the historical-auditor variants are intentionally asymmetric, presence of the note is the only check). Flag any MISSING result.
7. Run `python3 src/user/claude-code/scripts/check_citations.py <skill-file>` (repo-root base) per skill file — MISSING lines are candidate stale repo-layout path literals (mechanizes step 3's `accurate references` invariant, which Phase-3 disambiguation does not reliably catch). Adjudicate each: flag a genuinely stale/renamed path as a coherence fix; discard prose-fragment false positives (bare glob tokens, an ad-hoc-created `docs/spec/`).

## Output Format
### Renames
For each: `RENAME: <old> → <new>` with FRONTMATTER_UPDATE, REFERENCES_TO_UPDATE, CHANGELOG_RENAME. Or: "No renames needed."
### Coherence Fixes (including cross-communication gaps)
For each: `FIX <n>: <title>` / `FILE:` / `OLD_STRING:` / `NEW_STRING:` / `REASON:`. Or: "No coherence issues found."
### Changelog Entries
Standard format (4 sections, max 20 lines) for each affected skill.
### Remaining Issues
<Unresolvable issues, or "None">
```

### Phase 3: @distinguished-engineer (Disambiguation)

```
Agent(name="disambiguation-reviewer", subagent_type="distinguished-engineer", model="fable", prompt="...")

Surface residual semantic ambiguity Phase 2 Coherence does NOT catch, and recommend fixes.
Today's date: {today_date}. **Read-only** — the orchestrator applies all changes.
**No sub-agents** — do NOT invoke `/vote`, `Skill()`, or `Agent()`; do not form/manage a team. SendMessage the orchestrator for delegation. When your review is complete, SendMessage the orchestrator with the complete Output Format block verbatim.

**Charter & boundary (do not restate — apply as defined):** your charter is the **Phase 3 Disambiguation charter** CANONICAL block in `.claude/skills/evolve-skills/SKILL.md` §Phase 3: Disambiguation — Read it there; it is NOT in this prompt (the three dimensions + the coherence-vs-disambiguation framing). The **two-arm boundary test** is the **Boundary** paragraph there: a kept finding PASSES every Phase 2 coherence invariant (Arm 1) yet still FAILS clarity (Arm 2); a finding failing Arm 1 is coherence-class — report it under "Coherence-Class (route to Phase 2)", not as a DISAMBIG.

## Task
1. Read ALL skill files in .claude/skills/*/SKILL.md and src/user/claude-code/skills/*/SKILL.md (the freshly-coherent, post-Phase-2 genome).
2. For each candidate ambiguity, apply the two-arm test. Keep only findings that PASS Arm 1 AND FAIL Arm 2.
3. Classify each kept finding by DIMENSION: confusable-name | multi-reading | overlapping-ownership.

## Output Format
### Disambiguation Findings
For each: `DISAMBIG <n>: <title>` / `DIMENSION:` (confusable-name | multi-reading | overlapping-ownership) / `FILE:` / `OLD_STRING:` (verbatim current text) / `NEW_STRING:` (disambiguated replacement) / `REASON:` (which clarity arm fails and the resolved reading). Or: "No disambiguation findings."
### Coherence-Class (route to Phase 2)
<findings that FAIL Arm 1 — they belong to coherence, not disambiguation. Or "None.">
### Changelog Entries
Standard format (4 sections, max 20 lines) for each affected skill.
### Remaining Issues
<Unresolvable issues, or "None">
```

Always run this stage — it spawns its reviewer every cycle and no-ops cleanly when the reviewer reports `No disambiguation findings.` Shut down with `SendMessage(to="disambiguation-reviewer", message={type: "shutdown_request", reason: "Phase 3 complete"})`; the reviewer replies `shutdown_response` to the orchestrator.

---

## Rules

1. **Always run Phase 2** — even for single-skill improvements.
2. **Orchestrator-only edits.** Teammates are read-only — sole exception: the Phase 4 `history-compactor`, spawned with Edit, which applies (and on a failed invariant check reverts) its own changelog-compaction edits per the retention-compaction master. Never commit.
3. **Fail loud.** See Crash & Stall Recovery.
4. **Clean up.** Shutdown all teammates and clean up the team after wrap-up.
