# Claude 5 Migration — Closeout

**Status: closed, 2026-07-30.** The migration of `src/user/claude-code/`
(8 agents, 17 skills) from 4.x-generation prompt style to the Claude 5 paradigm
is complete. This file is the terminal summary; the working record stays in
place beside it.

| File | What it is |
|---|---|
| `../../../src/user/claude-code/docs/context-engineering-claude-5.md` | **The charter.** Governing doctrine — violation taxonomy, keep-list, per-model deltas, measurable targets. Still live; not a migration artifact. |
| `audit-manifest.md` | Pre-migration audit: every violation found, per file. |
| `baseline-metrics.md` | Pre-migration measurements + the recorded >10KB skill justifications. |
| `verification-report.md` | Post-migration verification as a system, incl. three live `claude -p` cycles. |

## What landed

**References and behavior held.** Every cross-reference in the tree resolves,
including all 61 cross-file `Rule N` citations — the hazard the audit ranked
first. Zero reasoning-echo instructions and zero self-verification scaffolding
survive anywhere in the fleet, agreed by mechanical scan and five independent
LLM graders. The review-recall counter-current (charter §1.3) is protected, and
two pre-migration recall defects were fixed along the way.

**Markers came down without losing the boundaries.** 108 → 51 across agents and
100 → 26 across skills, and the surviving markers map to named keep-list
categories rather than merely being fewer.

**The targets were made checkable.** `byte_ceilings.tsv` + `byte_ceiling_check.sh`
turned the charter's byte prose into a mechanism with an explicit `#EXCUSE`
ratification path; `doctrine_check.sh` covers index parity, pointer resolution,
CANONICAL byte-parity, and citer-set parity. All arms green at closeout.

**Live testing earned its place.** Part B found five behavioral defects that no
amount of reading would have surfaced — chief among them that the definitions had
no unattended-run safety, which burned $33.97 and 97.7 minutes on a cycle that
shipped no code. Fixed and confirmed live. One fix's first design was falsified
by testing and replaced, which is itself the argument for having run it.

**The paradigm is now self-preserving.** The gap this closeout was written to fix:
nothing stopped the next evolve cycle from re-accreting what the migration
removed. `team-doctrine/references/claude-5-paradigm-gate.md` is now the
operational form of the charter, cited by `evolve-agents`, `evolve-skills`, and
`evolve-coherence` — a fifth "Paradigm-conformant" Content Gate check, a ninth
review dimension, charter-aligned byte budgets, and an **insufficient-prescription
burden of proof**: any finding whose remedy is more prescription is reject-class
unless it names the keep-list category it lands in and points to the boundary.

## What did not land, and is accepted

**Byte reduction missed its floors by roughly 2×.** This is recorded as accepted,
not as an open defect: charter §4 was amended during the migration to make the
size condition qualitative — a section earns its place if it fires at the point of
action, or is relocatable *and* carries a dated record of why it has not moved.
Bytes are a diagnostic that opens a review, never a gate that closes one.

**Relocation is not a validated reduction mechanism.** Across every recorded
behavioral cycle, `team-doctrine/references/` files have been read zero times, and
one relocation is on record as having stopped a behavior from firing. Treat any
future relocation as a hypothesis to be probed, not a banked saving.

## Follow-ups

### 1. Re-derive the agent effort pins — *recommended next, and it splits across two skills*

**This is the migration's one substantive unfinished item.** Charter §3 requires
re-deriving `model:`/`effort:` per role rather than carrying 4.x values over.
Remediation item #14 applied that to skills but **never to agents** — the agent
`effort` pins are still byte-identical to the pre-migration baseline:

| Agent | model | effort | |
|---|---|---|---|
| `distinguished-engineer` | fable | **xhigh** | Fable's lower efforts "often exceed `xhigh` performance on prior models"; `high` is the sensible default, `xhigh` reserved for capability-sensitive work |
| `sdet` | opus | **xhigh** | |
| `security-engineer` | opus | **xhigh** | correctly off Fable per §3 |
| `senior-engineer` | sonnet | **xhigh** | |
| `staff-engineer` | opus | **xhigh** | code-review accuracy holds at lower effort — supports a cheap fast pass |
| `team-lead` | sonnet | **xhigh** | |
| `project-manager` | sonnet | high | |
| `ux-designer` | opus | high | |

Six of eight pin `xhigh` reflexively — the exact pattern §3 names. The Claude 5
effort ladder is the reason this is worth real money: **`low`/`medium` punch far
above their 4.x weight** (Sonnet 5 at `medium` ≈ Sonnet 4.6 at `high`; Sonnet 5 at
`high` ≈ 4.6 at `max`), and **`xhigh` is best reserved for demanding coding and
agentic work** rather than applied as a default. Use `low`/`medium` liberally
where evals hold.

**The work splits across two skills — do not send it all to one.** An earlier draft
of this note recommended running `/evolve-model-distribution` for the whole job;
that is wrong and an advisory review caught it:

- **The `effort:` pins above → `/evolve-agents`.** `/evolve-model-distribution`'s
  editable surface is bounded to `team-lead.md`'s Tiers bullet and routing prose
  (`SKILL.md:278`, "the ONLY editable surface"), and its declared Reads list
  contains no agent file but `team-lead.md`. It *cannot* open the other seven, and
  it has no effort telemetry to ground a retune with — `spawn_model_join.sh` emits
  `role/requested/resolved/session` and no effort field. Where it names
  `effort: xhigh` (`:212`, `:237`, `:268`) it is a **read-only** evidence anchor.
  evolve-agents' 9th dimension now owns this.
- **Model tier routing in `team-lead.md` → `/evolve-model-distribution`.** That
  part of the original recommendation stands: it is the sole owner of the routing
  surface and grounds edits in measured distribution.

**A caution for whoever does the effort retune:** `team-lead.md` §Effort dispatch
states that agent-frontmatter `effort:` **never binds for a teammate spawn** — it
binds only for report-only subagent spawns, and a skill's own `effort:` is a third
lever. So the six `xhigh` pins may be inert in the dispatch path they appear to
govern. Establish where each one actually binds before retuning it; a pin that
binds nowhere is a deletion, not a downgrade. That paragraph also already carries a
Claude 5 calibration (`S5 high ≈ Sonnet 4.6 max`) and sat in an ownership gap
between the two skills until the carve-out was tightened (see gate §4).

### 2. Extend the byte-ceiling mechanism to `.claude/skills/`

`byte_ceilings.tsv`'s `each` glob covers only `src/user/claude-code/skills/*/SKILL.md`.
The five `evolve-*` skills live under `.claude/skills/` and are 52–66KB each —
outside the *mechanism*, though the paradigm gate now holds them to the charter
anyway. Either extend the glob (and ratify the five with `#EXCUSE` rows) or record
why the root is exempt.

### 3. ~~Decide whether `evolve-config` and `evolve-model-distribution` need the fifth Content Gate check~~ — RESOLVED: **no, neither**

Settled 2026-07-30 by two independent read-only advisory reviews. Both said no, on
different and independently verified grounds:

- **`evolve-config` — no reachable surface.** Its declared scope
  (`CANONICAL:SOURCE-OF-TRUTH`, `SKILL.md:25`) is two Rust builders and two shell
  scripts. `statusline.sh:169` renders to the human operator; `teammate-idle-hook.sh:40`
  emits `systemMessage`, documented as user-visible. No prose in scope reaches a
  model's context, so the taxonomy cannot bite. Its `:345` disposition rule already
  imposes a stricter, config-native version of the burden rule than gate §3.
- **`evolve-model-distribution` — no attachment point.** Its Content Gate is an
  **orphan**: `grep -c 'Content Gate'` returns 1, the section header. No phase and
  no spawn prompt invokes it, unlike evolve-agents:290 / evolve-skills:299 which
  load the gate into a reviewer prompt. It has no dimension rubric to be ninth of
  (its rubric is the six divergence classes), and its Improvement-Only Mandate
  already exceeds gate §3. Adding checks to a gate nothing calls is a §1.7
  addition by the taxonomy's own terms.

The deliberate asymmetry is now recorded rather than drifting.

**Two live findings surfaced by that review. Both were decided by the operator on
2026-07-30 and are now CLOSED — recorded here with the reasoning, since each
changed behavior:**

**(a) RESOLVED — the class-6 `effort: xhigh` demand anchor was struck.**
`evolve-model-distribution`'s class-6 lane is the *one* lane admissible on zero
measured spawns, and it names `effort: xhigh` as a primary anchor for permanently
raising a model tier (`:212`, `:237`, `:268`, changelog exemplar `:85`). Three
problems: charter §3 explicitly names inherited `xhigh` pins as unreliable and due
for re-derivation; the field is **causally inert for teammate spawns**
(`team-lead.md:213`), and the Phase-2 re-verify checks only that the anchor
*appears*, never that it binds — so a citation to an inert field passes cleanly;
and effort and tier are separate levers whose Claude 5 remedies differ, while
class 6 has one remedy (raise the tier) and is locked monotonic. The lane is live:
a 2026-07-17 entry records a QUALITY upgrade admitted on n=1. **Applied:** the pin
is struck from all three anchor parentheticals (`:212`, `:237`, `:268`), the `:85`
changelog exemplar no longer models the bad citation, and a demand argument whose
Claude 5 remedy is an effort change now routes `DEFERRED (route: /evolve-agents)`
rather than becoming a tier raise. The counterargument — that the pin is weak
evidence of authorial judgment — was heard and rejected on the ground that the
Phase-2 gate can verify the anchor's *presence* but not its *bindingness*, making a
caveat unenforceable; exclusion was the only option the mechanism can act on.

**(b) RESOLVED — the ceilings are now enforced centrally in CI.**
`byte_ceiling_check.sh` reports `78150 / 78150`. `evolve-model-distribution` edits
that file by appending (a 2026-07-17 entry records "appended PRD-authoring clause")
and has **zero** awareness of the mechanism — `grep -c byte_ceiling` returns 0, and
its Phase-3 scripts touch no byte check. The ratchet has already fired once
unattributed (commit `5e63d8d`), leaving the delta to be reconciled by a later
unrelated cycle out of that cycle's trim budget. **Applied — the central fix, not
the in-skill one:** `.github/workflows/vorpal.yaml`'s `test-hooks` job now runs
`byte_ceiling_check.sh --strict`. No editing skill carries its own byte check; a
per-skill copy would be a second carrier of one obligation (§1.5), and gate §5
records CI as the single enforcement home so a future cycle does not add one.

This also closes a gap the advisory review surfaced in passing: until now the
script had **no caller but its own test**, so the charter's ceilings bound nothing
in practice. `--strict` converts the warn-only default into a failure. It exits 0
against the tree as committed, so the gate lands green — but note it now binds,
and `team-lead.md` has zero headroom, so the next append to it will fail CI until
its `byte_ceilings.tsv` row is raised with a stated reason. That is the mechanism
working as designed.

### 5. Probe whether `systemMessage` reaches a teammate's context

`teammate-idle-hook.sh:32` writes a ~505-byte instruction *addressed to the agent*
("If you still have an open assigned task or unsent report, finish it instead of
idling"), but the hooks docs describe `systemMessage` as user-visible only. Either
the docs are incomplete, or that instruction is being written to an agent that
never reads it — the second being the more interesting bug. Needs a live
TeammateIdle event to settle. Related: `CANONICAL:SOURCE-OF-TRUTH` names two of the
six scripts in `src/user/claude-code/hooks/`, and `subagent-report-hook.sh:47` — the
one confirmed `additionalContext` (true model-context) carrier — is outside
evolve-config's declared scope despite evolve-config having authored a sibling hook.

### 4. Honest note on this pass's own byte cost

Preserving the paradigm cost bytes in the files that enforce it: `evolve-agents`
+5.2KB, `evolve-skills` +5.7KB, `evolve-coherence` +6.1KB, plus the 11.5KB shared
reference. The additions are single-homed in that reference (charter §1.5) and are
**authority contracts** under keep-list category 3 — they define what a reviewer
seat may propose — which is the category they are claimed under. They are not
small, and a future cycle is entitled to test whether the shorter form works.
