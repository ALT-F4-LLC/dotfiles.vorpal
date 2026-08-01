# Claude 5 Paradigm Gate

Sole authority for how the evolve-* cycles hold their targets to the Claude 5
context-engineering paradigm. Cited by `evolve-agents`, `evolve-skills`, and
`evolve-coherence`; cite this file, never restate its bodies.

**Governing doctrine:** `src/user/claude-code/docs/context-engineering-claude-5.md`
(the migration charter). This file is the OPERATIONAL form of that charter for an
evolve cycle — where the two disagree, the charter wins and this file is wrong
until reconciled.

The failure this gate exists to prevent: an evolve cycle is a prescription-writing
machine pointed at definition files, and every reviewer seat it spawns is rewarded
for finding something to add. Left alone it re-accretes exactly the enumerated,
self-verifying, duplicated prose the Claude 5 migration removed. The gate makes
addition the burdened move and judgment the default.

---

## 1. The Paradigm Content-Gate check

This is the fifth check on the 4-check Content Gate (Executable, Behavioral,
Non-redundant, Concrete) carried by `evolve-agents` and `evolve-skills`.

**5. Paradigm-conformant** — Does the addition survive charter §1 (violation
taxonomy)? Reject content that reintroduces a violation class:

| Class | Reject on sight |
|---|---|
| §1.1 Reasoning-echo | "explain your reasoning", "show your thinking", "state your rationale before acting", or a report-format section whose real content is the model's deliberation. Classifier-enforced on Fable 5 (`reasoning_extraction` refusals → Opus 4.8 fallbacks), so this is a correctness bug, not a style note. Requiring *evidence* (file:line, command output) is fine; requiring a transcript of deliberation is not. |
| §1.2 4.x workaround | Anti-laziness or anti-anxiety pressure, emphasis inflation ("CRITICAL: You MUST…" where "Use…" carries it), iteration caps, forced progress-update cadences, context-budget choreography. Also dead mechanisms: assistant-turn prefill and `budget_tokens` are removed on Claude 4.6+ — any instruction built on either is dead code. |
| §1.3 Enumerated imperatives | A behavior family expanded into an exhaustive MUST/NEVER/ALWAYS list where one principle plus its reason covers every item; negative framing where a positive statement of the goal would do; prohibitions with no stated reason. Prefer positive examples of the desired behavior. |
| §1.4 Self-verification scaffolding | Checklists, "double-check before responding", pre-flight self-verification, verifier-subagent mandates. Keep a genuine EXTERNAL gate (tests, a reviewer role, a parser); delete a prompt telling the model to distrust itself. Model-split — see §4 below. |
| §1.5 Cross-file repetition | A multi-line block copied into a second carrier. Each shared fact gets exactly one home; other files cite it. The one sanctioned exception is a single one-line reminder of one key instruction near the end of a long prompt. |
| §1.6 Conflicting guidance | An addition that answers a question another layer (agent body, skill, doctrine reference) already answers differently, or that stacks with behavior the model already has. |
| §1.7 Monolithic upfront context | Always-resident bulk that belongs behind progressive disclosure; few-shot usage examples where an expressive format/parameter design would do — examples now constrain the exploration space rather than teach. |

A new MUST/NEVER/ALWAYS marker lands ONLY if it maps to a named §2 keep-list
category and the CHANGE block names that category.

---

## 2. The keep-list (charter §2) — what survives with imperative force

Four categories, because in each the reader or the adversary — not the model's
judgment — makes softness fail:

1. **Irreversible and destructive actions** — deleting data, force-pushing,
   modifying shared or production systems, publishing externally.
2. **Security boundaries** — trust-hierarchy assertions, anti-injection blocks,
   genuine secret non-disclosure scoped to a file that actually guards a secret.
   (Anti-leak ceremony guarding nothing is a §1.2 deletion.)
3. **Authority contracts** — who may invoke what, which role owns which artifact,
   what an agent must never do regardless of context ("never commits"). Permission
   boundaries between principals, not behavior tuning.
4. **Output-format contracts consumed by machines** — a parser, grader, or
   downstream tool reads the output, so the format stays pinned exactly. Grounding
   rules whose exact escape wording IS the mechanism belong here.

**The test of a surviving marker: point to the boundary.** If the justification is
"the model might otherwise judge wrong" about something reversible and internal, it
converts to a judgment statement or dies.

---

## 3. Insufficient-prescription findings carry the burden of proof

Binding on every evolve-* reviewer seat, every reconciler, and the orchestrator
applying a change.

A finding whose remedy is MORE prescription — a new MUST/NEVER/ALWAYS, an added
checklist or verification step, a restated rule, an enumerated behavior list, or a
block copied into a second carrier — is **reject-class** unless it carries a
**keep-list justification**: the CHANGE block (or finding DESCRIPTION) names the §2
category it lands in AND points to the concrete boundary that makes softness fail.

- "The model might otherwise judge wrong" about something reversible and internal
  is not a keep-list justification.
- Where the same behavior is imperative in one carrier and stated as judgment in
  another, that is §1.6 drift: resolve toward the JUDGMENT-stated side unless a
  keep-list category applies to the imperative one.
- **Restoring a previously-deleted rule** additionally requires a demonstrated
  regression (charter §4 Verification) — a regression on a representative task, not
  nostalgia for the deleted rule.
- One counter-current, and the only place "more coverage" is the right answer:
  restrictive filters in REVIEW prompts are now followed literally. "Only report
  high-severity issues" reduces recall on Opus 5 and Sonnet 5 — review prompts ask
  for full coverage and filter downstream. Removing such a filter is a reduction in
  prescription, so it does not carry this burden.

---

## 4. Per-model deltas (charter §3) — frontmatter and definition body

All three models default to effort `high`, and all three guides say to re-run an
effort sweep rather than carrying 4.x values over. Effort controls thinking volume,
not visible response length — prompt for length separately.

- **Fable 5** (`model: fable`) — top-capability tier: long-horizon autonomous runs,
  ambiguous problems, orchestration. Lower effort settings often exceed `xhigh` on
  prior models, so `high` is the sensible default. Three gates for any definition
  targeting it: no reasoning-echo anywhere in its context (§1.1); not intended for
  offensive-cybersecurity or bio/life-sciences work — route security-audit roles to
  Opus 5; expect long turns, so prefer asynchronous orchestration.
- **Opus 5** (`model: opus`) — complex agentic coding and enterprise work; best
  given the complete task spec up front and left to run. Use `low`/`medium`
  liberally where evals hold, `xhigh` for demanding coding and agentic work.
  Code-review accuracy holds at lower effort. Implications: strip verification
  scaffolding (§1.4), cap subagent spawning, prompt explicitly for conciseness.
- **Sonnet 5** (`model: sonnet`) — workhorse for well-specified work; its signature
  is literalism, so state scope explicitly where Fable would generalize. Raise
  effort rather than prompting around shallow reasoning. Calibration: Sonnet 5 at
  `medium` ≈ Sonnet 4.6 at `high`; `high` ≈ 4.6 at `max`.

Where one definition serves multiple models, three divergences are made
model-conditional rather than averaged: verification scaffolding (add for Fable
long runs, remove for Opus), instruction granularity (brief-and-general for Fable,
explicit-scope for Sonnet), and subagent posture (encourage for Fable, cap for Opus).

**Routing-surface ownership is unchanged:** edits to `team-lead.md`'s model-routing
surface — precisely its two anchors: the `Tiers (four named tiers` block and the
`Per-spawn model routing` paragraph — are owned by
`/evolve-model-distribution`. An evolve-agents or evolve-skills cycle records such a
finding as DEFERRED (route: /evolve-model-distribution) rather than applying it.

**`team-lead.md` §Effort dispatch is NOT part of that carve-out** — it is effort
prose, not model routing, and `/evolve-model-distribution` never reads it (its
categorization authority declares only the two anchors above). It belongs to
evolve-agents along with the per-agent `effort:` pins. Read it before proposing any
effort change: it states that **agent-frontmatter `effort:` never binds for a
teammate spawn** — it binds only for report-only subagent spawns, and a skill's own
`effort:` is a third lever. An argument resting on a frontmatter `effort:` pin as
evidence of a role's cognitive demand is therefore citing a field that may be
causally inert in the dispatch path it is being cited for.

---

## 5. Measurable targets (charter §4) — diagnostics, not gates

**The qualitative gate decides; every number below only opens a review.**

*The gate.* Every section of an always-resident definition either (a) fires at the
point of action for a role that can take that action, or (b) is relocatable behind
progressive disclosure AND has a dated record of why it has not moved. A file
failing both is over-long regardless of its size; a file passing both is correctly
sized regardless of its size.

*The diagnostics.*

- **Markers.** Baseline 108 across agents, 100 across skills. Every surviving
  marker maps to a named §2 category; typical file ≤ 5, no file above 10. The
  MAPPING is the gate — a file under 5 with one unmappable marker fails, and a file
  at 9 whose markers all map passes.
- **Bytes.** `src/user/claude-code/scripts/byte_ceilings.tsv` holds the current
  figures; `byte_ceiling_check.sh` reports them. `team-lead.md` carries a RATCHET,
  not a floor: it may not exceed its recorded high-water mark without a stated
  reason, and the mark lowers only when a verified reduction lands (record the new
  figure in the TSV). Skills: no SKILL.md over 10,000 bytes without a recorded
  justification — an `#EXCUSE<TAB>path<TAB>reason` row in that TSV is the
  ratification mechanism; format-authority tables that are themselves output
  contracts are the expected exception. There is deliberately NO fleet-total byte
  target: no context holds more than one agent definition, so a sum bounds no real
  resource and double-charges CANONICAL blocks pinned across carriers on purpose.
- **Deduplication.** Zero multi-line blocks shared verbatim between two or more
  agent files; each shared fact has exactly one home. A block registered in
  `doctrine_check_manifest.tsv` is a RATIFIED pin — parity across its manifest
  carrier set is a PASS, not a §1.5 violation. An UNREGISTERED multi-line block
  appearing verbatim in two or more agent files is the §1.5 finding.

*Two caveats that bind the diagnostics.*

- **Reduction is a consequence of applying §1, never a goal met by deleting context
  the model cannot reconstruct.** A shell script cannot judge what the model can
  reconstruct, which is why the gate above is qualitative and a script must not be
  the thing that decides.
- **Relocation is not yet a validated reduction mechanism.** Across every recorded
  behavioral cycle, `team-doctrine/references/` files have been read zero times, and
  one relocation is on record as having stopped a behavior from firing. Treat a
  relocation as a hypothesis to be probed, not as a completed reduction — propose it
  with a probe for whether the behavior still fires, and never bank the bytes as
  saved.

**Where the ceilings are enforced.** Centrally, once: `.github/workflows/vorpal.yaml`
runs `byte_ceiling_check.sh --strict` in the `test-hooks` job. **No editing skill
carries its own byte check** — a per-skill copy would be a second carrier of one
obligation (§1.5), and this is the single home. A cycle that edits a ceilinged file
may run the script locally to see where it stands, but the gate that decides is CI.
A raise lands as a stated reason on the file's `byte_ceilings.tsv` row, not as a
silent absorption into a later cycle's trim budget.

**Byte-ceiling scope caveat.** The TSV's `each` glob covers only
`src/user/claude-code/skills/*/SKILL.md`. A `.claude/skills/*/SKILL.md` target
(every evolve-*) is outside the MECHANISM but not outside the CHARTER: hold it to
the same 10KB-plus-recorded-justification rule and state the justification in the
cycle's changelog entry when it is over.
