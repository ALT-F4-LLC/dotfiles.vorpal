# Evolve Orchestration Core (shared reference)

Single-homed home for orchestration-core prose shared by the `evolve-agents`, `evolve-config`, and `evolve-skills` cycles — extracted per DKT-106 to eliminate hand-maintained duplication (the same drift class `evolve-phase0-templates.md` already addresses for the Phase-0 auditor templates).

**How consumers use this file.** Read this file ONCE at the point each section is needed (Phase-0/Pre-flight spawn time for Scientific Trial Protocol / Genetic-Drift Operator / Operator prompts; Team Setup for Shutdown Protocol; Phase-0 spawn time for Crash & Stall Recovery / Second-Failure Recovery (detection signals must be known before any failure occurs); Phase 3 spawn time for the Disambiguation Charter/Boundary) and apply the section as defined. If this file or a named section is missing, ABORT the cycle loudly (`Error: shared orchestration-core section missing: {section}`) — never hand-reconstruct a gate. Section headings are named identifiers, not numbers — cited verbatim by every consumer's pointer stub — because renumbering a numbered reference silently breaks every citation, while a heading rename is at least greppable. No editor of this file (human or evolve-* cycle) may rename an existing heading without updating every consumer citation in the same turn.

**Hybrid-block note.** Two sections below (Scientific Trial Protocol, Operator prompts) are *not* fully single-homed: each of the three consumer SKILL.md files retains its own `CANONICAL:*`-tagged block, compressed to restate only the load-bearing, hard-fail constraint (the operator-approval HARD GATE scope; the max-4-options / 1-4-questions-per-call / 12-char-header API-shape limits) inline, with this file as the pointer target for full procedural detail. This is a deliberate design choice — those two topics are always-on gates that fire before a natural "read the reference" moment (Pre-flight step 1, and any AskUserQuestion call), so the hard-fail trigger must stay visible at the point of use, not live only behind a Read. Do NOT read the carriers' shorter local text as an incomplete duplicate to "finish" back to full length, and do NOT delete it as redundant with this master — the compression is intentional and the carriers remain manifest-registered, parity-enforced CANONICAL blocks (`doctrine_check_manifest.tsv`, `symmetry_check.py` CHECKS keys `trial-protocol` / `operator-prompts`). The other sections (Genetic-Drift Operator, Crash & Stall Recovery, Second-Failure Recovery, Shutdown Protocol, Phase 3 Disambiguation Charter, Phase 3 Disambiguation Boundary) are fully single-homed: each consumer's local CANONICAL markers for these tags are removed entirely and replaced by a bare "cite it, never restate it" pointer. **Scope of "fully single-homed": the CANONICAL BLOCK, not the whole carrier section.** A consumer heading of the same name may still carry per-carrier prose that was never inside the block and has no master here — each carrier's `## Genetic-Drift Operator`, for instance, keeps its own drift-rate and target-selection paragraphs alongside the pointer (carve-out in §Genetic-Drift Operator below). That prose is NOT an un-enforced restatement to trim; read the section's own body for what it carves out before removing carrier text under a single-homed tag.

**Drift-eligibility note (standing rule for future extractions).** Moving a block's prose here removes it from every carrier's own `drift_target.sh` candidate set (drift targets are computed from the target SKILL.md's own headings/list items) — a one-way narrowing of the standing-variation pool the Genetic-Drift Operator exists to maintain. Before extracting any further block from a consumer file, grep that file's own changelog (including its compacted-history section) for a recorded `Drift:`/`Trial:` line naming it; a block carrying a LIVE recorded allele stays local — a token cannot express a differing clause order or wording, only a differing value, so an active drift trial on a block's wording is not extraction-safe until the trial resolves (adopt or rollback).

**Consumers:** evolve-agents, evolve-config, evolve-skills.

---

## Scientific Trial Protocol

Every non-neutral adaptive change AND every drift proposal passes this gate: **Hypothesis** (expected improvement + why) → **Baseline metric** — record one named metric from `evolve_signals.py`'s fitness panel (e.g. `TeammateIdle(role)=N @7d`) as of proposal time → **Operator approval (HARD GATE)** — present hypothesis, scope, blast radius, and the baseline metric via AskUserQuestion BEFORE any edit; an unapproved item is recorded as `Trial: <hypothesis> → proposed` (or `Drift: … → proposed`) and NOT implemented → **Measurement** (reuse the Phase 0 audit; add no new infrastructure) → **Adopt or rollback** (adopt if the next cycle's Phase 0 audit shows the same named metric improved against the recorded baseline, else the Phase 1 self-correct/revert step). Record the outcome as a `Trial:`/`Drift:` line in the changelog `### Summary`, including the baseline and comparison metric values.

(Hybrid block — see the Hybrid-block note above. Each consumer keeps a compressed inline restatement of the HARD GATE scope under its own `CANONICAL:SCIENTIFIC-TRIAL-PROTOCOL` markers.)

---

## Genetic-Drift Operator

**The variation is a neutral allele substitution** — replace the selected trait's current formulation with a semantically-equivalent alternative (re-word, reorder a checklist, merge/split adjacent bullets, swap an illustrative example). It is a substitution of an existing functional trait, so it is net-line-neutral and passes the Content Gate's Behavioral check (the trait still changes output; only its expression drifts).

**Gate + caveat.** Every drift proposal routes through the **same operator-approval HARD GATE** as adaptive trials (Scientific Trial Protocol) and is recorded as a `Drift:` line. **(S2 — reproducibility caveat:)** because `{drift_seed}` is the cycle identity, two runs *on the same date* reproduce the *same* drift target — they are not independent draws; across-generation stochastic variation comes from the date advancing. This is intentional (reproducibility/auditability over per-run randomness), so an operator re-running a cycle on the same date is not surprised.

Fully single-homed — cite it, never restate it. Each consumer keeps its own LOCAL, per-carrier target-selection paragraph (the `drift_target.sh <target-path> {drift_seed} {drift_rate} <cited-findings-file>` invocation and the empty-no-signal-set no-op rule) OUTSIDE this section, because the target path differs per carrier (a generic `<skill-path>/SKILL.md` placeholder for evolve-skills, a hardcoded `src/user/claude-code/agents/<name>.md` for evolve-agents, a fixed `.claude/skills/evolve-config/SKILL.md` for evolve-config) — that per-carrier difference is not extraction-safe without a token, and no consumer requested one this cycle.

---

## Operator prompts

All operator-facing questions in Pre-flight MUST use `AskUserQuestion` with pre-generated selectable options (1-4 questions per call; **max 4 options per question regardless of `multiSelect`** — the API rejects >4); max 12-char `header`. If the operator needs to pick more than 4, ask a routing question first ("which category?") then a second narrow question. Free-text is permitted ONLY when the operator must paste material that doesn't fit options (logs, reproductions, large diffs, verbatim quotes) AFTER a structured option-led question routes them there.

(Hybrid block — see the Hybrid-block note above. Each consumer keeps a compressed inline restatement of the three API-shape constraints — 1-4 questions per call, max 4 options, max 12-char header — under its own `CANONICAL:OPERATOR-PROMPTS-CONVENTION` markers.)

---

## Crash & Stall Recovery

Detect failure via: (a) `TeammateIdle` notification or `Monitor` stream silence past expected progress — ≥2 turns with no new tool call is stall evidence (stall); (b) `shutdown_request` gets no response within one turn (crash); (c) Agent() returns an explicit error; (d) a teammate that dies on an API error self-reports `failed` to the orchestrator — a faster, cleaner crash signal than Monitor-silence heuristics.

- **Nudge before re-spawn (stall only).** For a stuck/idle teammate, one `SendMessage` nudge wakes it to retry immediately — cheaper than a fresh spawn; escalate to `-r2` only if the nudge draws no new tool call within one turn.
- **Re-spawn ONCE** with suffix `-r2` and a `Resume context:` block listing (a) prior partial report, (b) task ID to claim, (c) target file(s).

Fully single-homed — cite it, never restate it. **Carrier-scope carve-out:** each consumer's local `### Crash & Stall Recovery` heading is BROADER than this section — it also hosts the pointer to §Second-Failure Recovery and a per-carrier **Compaction recovery** bullet that is LOCAL-ONLY and mirrors nothing here. Bullet-level ownership is read off each bullet's own `Source:`/§ pointer, never off the heading; a carrier bullet carrying no such pointer is local-only, not drift, and is not trimmable as an un-enforced restatement of this section.

---

## Second-Failure Recovery

- **Second failure**: mark task completed and skip; never do the work directly. Phase 1 reviewer → record "No review performed — agent unavailable" in the changelog. Phase 0 auditor → write `"UNAVAILABLE: <name> failed twice"` as the entire content of that auditor's `{scratchpad}/phase0/<name>.md` (its findings-token value) so the Phase 1 Read-by-path stays valid.

Fully single-homed — cite it, never restate it.

---

## Shutdown Protocol

`SendMessage(to="<name>", message={type: "shutdown_request", reason: "<phase> complete"})`. Teammate replies with `shutdown_response` **addressed to the orchestrator** (never to a peer). If rejected, address the `reason` and re-request. No response → see §Crash & Stall Recovery. (Orchestrator-originated shutdown is intentional: evolve orchestrators drive their own team's lifecycle, unlike leaf-review skills where ephemeral reviewers AWAIT the orchestrator's `shutdown_request` per `src/user/claude-code/agents/team-lead.md` Rule 7.)

Fully single-homed — cite it, never restate it. This exact wording was previously unregistered (no CANONICAL markers, no manifest/symmetry_check.py coverage) and had already drifted: evolve-agents' local copy read "If rejected, read the `reason`, address it, then re-request. If no response, see…" against evolve-config's/evolve-skills' byte-identical "If rejected, address the `reason` and re-request. No response → see…" — this file adopts the latter (2-of-3, terser, no behavioral delta) and treats evolve-agents' prior wording as the drift.

---

## Phase 3 Disambiguation Charter

**Phase 3 Disambiguation charter.** Surface and resolve residual ambiguity Phase 2 Coherence does NOT address: (1) confusable names/triggers/terms, (2) wording with multiple readings, (3) overlapping ownership between organisms. Coherence asks "do the pieces agree?"; disambiguation asks "can a reader tell the pieces apart and know who owns what?"

Fully single-homed — cite it, never restate it.

---

## Phase 3 Disambiguation Boundary

**Boundary (the load-bearing distinction — every finding must satisfy both arms or it routes to Phase 2 instead):** a Phase 3 finding's targets each independently PASS every Phase 2 coherence invariant (references resolve, CANONICAL bytes match within family, role claims map to a real owner, ladders/names spelled consistently) yet still FAIL clarity (a competent reader or routing classifier could confuse two concepts, read one instruction two ways, or be unable to name the single owner of a responsibility). A target that FAILS a coherence invariant is a Phase 2 finding, not Phase 3.

**Mechanism (read-only-reviewer → orchestrator-applies, same shape as Phase 2 — teammates never edit):** the reviewer Reads the freshly-coherent genome, emits structured disambiguation findings, and the orchestrator applies every edit (Read each target in-session before its first Edit; one Edit per finding; any finding touching a CANONICAL block or shared frontmatter applied family-wide in lockstep with byte-identity verification). The reviewer reports `No disambiguation findings.` when the genome is clean — the stage always spawns its reviewer and no-ops cleanly. Shut down the `disambiguation-reviewer` per the Shutdown Protocol before the next phase. Each consumer's own local delta specifies its target glob (which files the reviewer Reads) and any organism-specific application detail; this section covers only the shared charter, boundary test, and mechanism.

Fully single-homed — cite it, never restate it.
