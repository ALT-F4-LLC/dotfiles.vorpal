# Evolve Orchestration Core (shared reference)

Single home for orchestration-core prose shared by the `evolve-agents`, `evolve-config`, and
`evolve-skills` cycles (DKT-106). Read each section ONCE at the point it is needed
(Pre-flight for Scientific Trial Protocol / Genetic-Drift Operator / Operator prompts; Team
Setup for Shutdown Protocol; Phase-0 spawn for Crash & Stall / Second-Failure Recovery;
Phase 3 spawn for the Disambiguation sections). If this file or a named section is missing,
ABORT the cycle loudly (`Error: shared orchestration-core section missing: {section}`) —
never hand-reconstruct a gate. Section headings are named identifiers cited verbatim by
every consumer's pointer stub — no editor (human or evolve-* cycle) may rename an existing
heading without updating every consumer citation in the same turn.

**Hybrid-block note.** Two sections (Scientific Trial Protocol, Operator prompts) are not
fully single-homed: each consumer SKILL.md retains its own `CANONICAL:*`-tagged block
compressed to the load-bearing hard-fail constraint, with this file as the pointer target
for full detail — those gates fire before a natural "read the reference" moment, so the
trigger must stay visible at the point of use. The carriers' shorter local text is
intentional compression, manifest-registered and parity-enforced
(`doctrine_check_manifest.tsv`, `symmetry_check.py` keys `trial-protocol` /
`operator-prompts`) — do NOT "finish" it back to full length and do NOT delete it as
redundant. The other sections are fully single-homed at the CANONICAL-BLOCK level only: a
consumer heading of the same name may still carry per-carrier prose that was never inside
the block (see each section's own carve-out) — bullet-level ownership is read off each
bullet's own `Source:`/§ pointer, never off the heading.

**Drift-eligibility note (standing rule for future extractions).** Moving a block's prose
here removes it from that carrier's `drift_target.sh` candidate set. Before extracting any
further block from a consumer file, grep that file's changelog (including compacted history)
for a recorded `Drift:`/`Trial:` line naming it — a block carrying a LIVE recorded allele
stays local until the trial resolves.

**Consumers:** evolve-agents, evolve-config, evolve-skills.

---

## Scientific Trial Protocol

Every non-neutral adaptive change AND every drift proposal passes this gate: **Hypothesis**
(expected improvement + why) → **Baseline metric** — record one named metric from
`evolve_signals.py`'s fitness panel (e.g. `TeammateIdle(role)=N @7d`) as of proposal time →
**Operator approval (HARD GATE)** — present hypothesis, scope, blast radius, and the
baseline metric via AskUserQuestion BEFORE any edit; an unapproved item is recorded as
`Trial: <hypothesis> → proposed` (or `Drift: … → proposed`) and NOT implemented →
**Measurement** (reuse the Phase 0 audit; add no new infrastructure) → **Adopt or rollback**
(adopt if the next cycle's Phase 0 audit shows the same named metric improved against the
recorded baseline, else the Phase 1 self-correct/revert step). Record the outcome as a
`Trial:`/`Drift:` line in the changelog `### Summary`, including baseline and comparison
values.

(Hybrid block — each consumer keeps a compressed inline restatement of the HARD GATE scope
under its own `CANONICAL:SCIENTIFIC-TRIAL-PROTOCOL` markers.)

---

## Genetic-Drift Operator

**The variation is a neutral allele substitution** — replace the selected trait's current
formulation with a semantically-equivalent alternative (re-word, reorder a checklist,
merge/split adjacent bullets, swap an illustrative example). Net-line-neutral; passes the
Content Gate's Behavioral check. Every drift proposal routes through the same
operator-approval HARD GATE as adaptive trials and is recorded as a `Drift:` line.
**(S2 — reproducibility caveat:)** `{drift_seed}` is the cycle identity, so two runs on the
same date reproduce the same drift target — across-generation variation comes from the date
advancing; this is intentional (reproducibility over per-run randomness).

Fully single-homed — cite it, never restate it. Carve-out: each consumer keeps its own
per-carrier target-selection paragraph (the `drift_target.sh` invocation and the
empty-no-signal-set no-op rule) OUTSIDE this section, because the target path differs per
carrier.

---

## Operator prompts

All operator-facing questions in Pre-flight MUST use `AskUserQuestion` with pre-generated
selectable options (1-4 questions per call; **max 4 options per question regardless of
`multiSelect`** — the API rejects >4); max 12-char `header`. If the operator needs to pick
from more than 4, ask a routing question first ("which category?") then a second narrow
question. Free-text is permitted ONLY when the operator must paste material that doesn't fit
options (logs, reproductions, large diffs, verbatim quotes) AFTER a structured option-led
question routes them there.

(Hybrid block — each consumer keeps a compressed inline restatement of the three API-shape
constraints under its own `CANONICAL:OPERATOR-PROMPTS-CONVENTION` markers.)

---

## Crash & Stall Recovery

Detect failure via: (a) `TeammateIdle` notification, or `Monitor` stream silence past
expected progress — the signal is no new tool call across COMPLETED turns, judged against
that teammate's expected cadence, not wall-clock alone: 5-generation models legitimately run
single turns for many minutes, so a long turn still streaming tool calls is not a stall
(stall); (b) `shutdown_request` gets no response within one turn (crash); (c) `Agent()`
returns an explicit error; (d) a teammate that dies on an API error self-reports `failed` to
the orchestrator — the fastest, cleanest crash signal.

- **Nudge before re-spawn (stall only).** One `SendMessage` nudge wakes a stuck teammate to
  retry — cheaper than a fresh spawn; escalate to `-r2` only if the nudge draws no new tool
  call within one turn.
- **Re-spawn ONCE** with suffix `-r2` and a `Resume context:` block listing (a) prior
  partial report, (b) task ID to claim, (c) target file(s).

Fully single-homed — cite it, never restate it. Carrier-scope carve-out: each consumer's
local `### Crash & Stall Recovery` heading is BROADER than this section — it also hosts the
pointer to §Second-Failure Recovery and a per-carrier **Compaction recovery** bullet that is
LOCAL-ONLY; a carrier bullet carrying no `Source:`/§ pointer is local-only, not drift.

---

## Second-Failure Recovery

- **Second failure**: mark the task completed and skip; never do the work directly. Phase 1
  reviewer → record "No review performed — agent unavailable" in the changelog. Phase 0
  auditor → write `"UNAVAILABLE: <name> failed twice"` as the entire content of that
  auditor's `{scratchpad}/phase0/<name>.md` (its findings-token value) so the Phase 1
  Read-by-path stays valid.

Fully single-homed — cite it, never restate it.

---

## Shutdown Protocol

`SendMessage(to="<name>", message={type: "shutdown_request", reason: "<phase> complete"})`.
Teammate replies with `shutdown_response` **addressed to the orchestrator** (never to a
peer). If rejected, address the `reason` and re-request. No response → see §Crash & Stall
Recovery. (Orchestrator-originated shutdown is intentional: evolve orchestrators drive
their own team's lifecycle, unlike leaf-review skills where ephemeral reviewers AWAIT the
orchestrator's `shutdown_request` per `src/user/claude-code/agents/team-lead.md` Rule 7.)

Fully single-homed — cite it, never restate it.

---

## Phase 3 Disambiguation Charter

Surface and resolve residual ambiguity Phase 2 Coherence does NOT address: (1) confusable
names/triggers/terms, (2) wording with multiple readings, (3) overlapping ownership between
organisms. Coherence asks "do the pieces agree?"; disambiguation asks "can a reader tell
the pieces apart and know who owns what?"

Fully single-homed — cite it, never restate it.

---

## Phase 3 Disambiguation Boundary

**Boundary (every finding must satisfy both arms or it routes to Phase 2):** a Phase 3
finding's targets each independently PASS every Phase 2 coherence invariant (references
resolve, CANONICAL bytes match within family, role claims map to a real owner,
ladders/names spelled consistently) yet still FAIL clarity (a competent reader or routing
classifier could confuse two concepts, read one instruction two ways, or be unable to name
the single owner of a responsibility). A target that FAILS a coherence invariant is a Phase
2 finding, not Phase 3.

**Mechanism (read-only-reviewer → orchestrator-applies; teammates never edit):** the
reviewer Reads the freshly-coherent genome and emits structured disambiguation findings; the
orchestrator applies every edit (Read each target in-session before its first Edit; one Edit
per finding; any finding touching a CANONICAL block or shared frontmatter applied
family-wide in lockstep with byte-identity verification). The reviewer reports
`No disambiguation findings.` when the genome is clean — the stage always spawns its
reviewer and no-ops cleanly. Shut down the `disambiguation-reviewer` per the Shutdown
Protocol before the next phase. Each consumer's local delta specifies its target glob and
any organism-specific application detail.

Fully single-homed — cite it, never restate it.
