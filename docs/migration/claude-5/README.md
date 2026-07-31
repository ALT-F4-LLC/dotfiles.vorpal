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

## The paradigm gate's first cycle — the probe, and what it showed

`claude-5-paradigm-gate.md` shipped verified for CONSISTENCY and unverified for
EFFECT. By charter §4's own standard that made it a hypothesis with a probe
pending. The 2026-07-30 `/evolve-agents` cycle is that probe. Recorded here
plainly, including where the gate did not do the work.

**Did the cycle net-add prose to the definitions?** **No — it net-removed 165
bytes** (366552 → 366387). But the margin is the interesting part, and it did not
stay negative on its own: the sign flipped positive twice mid-cycle and was
pulled back both times only by deliberate intervention. See "the sign flipped
twice" below.

| File | Δ | driver |
|---|---|---|
| `team-lead.md` | **−531** | pin deleted, volatile world-state retired, 2 uncited legend rows |
| `sdet.md` | −106 | six §1.5/§1.6 culls funding the pin change |
| `senior-engineer.md` | −61 | `/tmp` rule de-duplicated, root-cause paragraph folded |
| `staff-engineer.md` | −28 | two shutdown/idle dedups |
| `project-manager.md` | +65 | Phase-2 `TeammateIdle` correction |
| `security-engineer.md` | +61 | Phase-2 `TeammateIdle` correction |
| `ux-designer.md` | +97 | Phase-2 `TeammateIdle` correction + seat-name generalization |
| `distinguished-engineer.md` | +212 | provenance comment + `TeammateIdle` correction |
| **fleet** | **−291** | |

`team-lead.md`'s ratchet **lowered** 78150 → 77619 rather than banking the
headroom, per gate §5.

**The sign flipped twice, and only orchestrator intervention pulled it back.**

The second flip is the more instructive, because it was self-inflicted and the
reviewer had recommended the opposite. The coherence pass observed that the
binding-provenance comment landed on 4 of 8 `effort:` pins and left 3 bare, and
called the split — correctly — indefensible either way. It recommended converging
by DELETING the four. The orchestrator instead added the clause to the remaining
three, which took the cycle from **−291 to +258: a net ADD**, the exact condition
this section exists to detect. Caught on the next measurement and resolved by a
third option neither side had proposed — keep provenance on all seven but cut each
comment to a short pointer rather than a copied clause — landing at −165.

Two things worth keeping from that:

- **"Converge the inconsistency" does not say which direction, and the cheap
  direction is usually addition.** Both available moves resolved the split; only
  one of them was measurable as accretion. Nothing in the gate distinguishes them,
  because neither move adds an imperative — this is provenance, not prescription,
  and §3's burden never attaches.
- **A per-file diff would not have caught it.** Each of the three additions was
  ~180 bytes, unremarkable in isolation. Only the fleet total showed the sign
  change, and the fleet total is explicitly NOT a charter target (gate §5: "no
  fleet-total byte target"). The measurement that caught this is one the diagnostics
  deliberately do not keep.

**The first flip: a correctness fix priced at 4× its necessary size.**
Phase 2 found a genuine defect — four agent files asserted "`TeammateIdle` is the
canonical stall signal", contradicting `team-lead.md`'s authority section, with
`security-engineer.md` contradicting *itself* between `:51` and `:199`. The
finding is real and worth fixing. But the reviewer's proposed remedy restated the
corrected framing at length in all four carriers, **adding ~660 bytes — enough to
turn the cycle's −588 into roughly +72.** The orchestrator applied the same
correction, citing the same authority, in about a quarter of the bytes.

Two lessons, recorded because they generalize past this cycle:

1. **Correctness findings are the accretion vector the gate does not cover.** §3
   burdens findings whose remedy is *more prescription*; nobody argues a
   false-claim correction is prescription, so it passes freely — and a correction
   applied across N carriers costs N× regardless. The gate has no rule about
   remedy *size*.
2. **Fixing a claim duplicated across 7 carriers by editing all 7 is itself the
   §1.5 shape**, just in correction's clothing. The conformant fix — which this
   cycle did not attempt and a later one should — is to reduce those carriers to
   citations of the authority rather than keeping seven synchronized restatements
   that will drift again. This one already had: the divergence was **pre-existing,
   not cycle-caused** (verified against HEAD), meaning the seven copies drifted
   silently at some earlier point and nothing caught it until a coherence pass
   went looking.

**Did a reviewer seat produce an "insufficient-prescription" finding, and did the
keep-list requirement reject it — or did it sail through?** Findings of that
shape appeared, and the record is mixed in a way worth stating precisely.

*Rejected, citing the gate:*
- **P1** — restate the doctrine-pinned-script trust rule in a second carrier.
  Rejected as §1.5 + §3; the conformant remedy is a citation.
- **B2 (coverage half)** — widen `PHANTOM-PATH-GUARD` from the 5 evolve-* skills
  into 8 agent files. Rejected as §1.5 by the gate's own terms.
- **staff-engineer's own pitfalls residue** — the strongest instance, because the
  seat rejected *itself*: "its only available remedy is an added verification
  step on an internal, reversible review judgment — reject-class under gate §3
  with no §2 category to point at," adding that encoding it would make it "the
  reviewer who, in the cycle whose entire purpose is stopping accretion, added a
  4th clause to a bullet that already has three." This is the burden rule working
  as designed, unprompted.
- **A brief-invited addition, declined.** The sdet brief invited citing the
  measured binding fact in §Lifecycle; the seat refused it as §1.5 within one
  file. A reviewer declining an addition its own dispatch asked for is the
  cleanest available evidence that Content-Gate check 5 has teeth.

*Rejected, but NOT by the gate — and this distinction matters:*
- **I6** (`hooks:` frontmatter to gate `git push`/`--amend`/`stash`) was killed by
  ground-truth verification, not by the burden rule: the field is inert on the
  teammate path, `guard-no-commit-hook.sh:268` already gates `commit|push|add`,
  and `stash` is a *documented deliberate exclusion* at `:28`. Counting this as a
  gate success would overstate the gate's record.
- **B1**, the bug audit's largest finding (40 occurrences), died because its
  premise was false, not because of §3.

*Where it did NOT hold — the honest failure.* One addition landed on a
self-classification the gate cannot check. **B3** (+160 bytes to
`senior-engineer.md` §Shell hygiene) was admitted on the reviewer's own argument
that extending an existing enumeration "does not add a MUST/NEVER/ALWAYS marker
and states a mechanical fact about the shell, so gate §3's burden does not
attach." That reading is defensible and the content is genuinely useful — the
defect is real and was reproduced — but §3 lists "an enumerated behavior list"
among the burdened forms, so the exemption was argued, not earned against a §2
category. **The gate's weak point is that the seat proposing an addition also
classifies whether the burden applies to it.** No mechanism checks that
classification. Recorded so a later cycle can decide whether the burden needs an
external adjudicator.

**Did the 9th dimension surface real taxonomy violations, or only restate the
other eight?** Real ones, but its yield is largely coextensive with Dimension 5
(Consolidation & Trimming) — reviewers routinely tagged findings `DIMENSION: 5 / 9`.
Its *distinct* contribution is not finding-generation but **remedy direction and
marker mapping**: dimension 5 says "this is duplicated," dimension 9 says "the
remedy is a citation or a deletion, not a rewrite," and it forces every surviving
MUST/NEVER/ALWAYS to name a §2 category. Concrete §-classified findings this
cycle: sdet's §1.6 (a local shell-hygiene restatement that *contradicted* its
master), senior-engineer's §1.2 (emphasis inflation where a real external gate
already caught every violation), team-lead's §1.6 (a sentence contradicting the
file's own rule seven lines above), staff-engineer's §1.5 (a dedup that had
re-accreted since 2026-06-09 — evidence the accretion pressure the gate exists to
counter is real and recurring).

**A second-order finding the gate did not cause, but the cycle exposed.** Two
independent Phase 0 auditors overstated where the `effort:` pin binds, in the same
direction, by counting `subagent_type="X"` spawn *sites* instead of testing the
`name=` discriminator — one of them citing its own non-discriminating probe as
"direct proof." Every `evolve-*` spawn is `Agent(name=…)`, i.e. a teammate, so
site-counting cannot distinguish binding from inert. The gate has nothing to say
about this class: it governs what may be *added*, not whether a finding's evidence
supports its claim. Both were caught by orchestrator verification, which is the
only thing standing between that error class and a shipped edit.

## Follow-ups

### 1. ~~Re-derive the agent effort pins~~ — **SETTLED 2026-07-30** by an `/evolve-agents` cycle

**R1 is closed.** The blocker was that its stated bar — "an effort sweep on real
evals, not a text edit" — had no instrument. That premise turned out to be half
false, and the half that survived was separated from the half that did not:

- **Binding: MEASURED.** Every assistant turn in every transcript carries a
  per-turn `"effort"` field (`.meta.json`, `spawn_model_join.sh`, and Mimir do
  not record it). A 3-cell controlled experiment plus a retrospective replay at
  n≈480 settled it: **report-only spawns ran at exactly their frontmatter pin,
  9/9, across three pin values on four roles; teammate effort varied *within* a
  single role under an unchanging pin.** Both halves of `team-lead.md` §Effort
  dispatch — previously an undocumented inference, since `agent-teams.md`'s
  "not applied for teammates" note names only `skills` and `mcpServers` — are
  therefore confirmed. That paragraph now carries the measurement as provenance.
- **Quality: NOT measured, and shipped as such.** No effort eval exists. The two
  pins with measured binding reach (`sdet`, `staff-engineer`) ship as `Trial:`
  entries under the Scientific Trial Protocol, adopt-or-rollback on the next
  cycle's Phase 0. The two with zero measured binding (`distinguished-engineer`,
  `senior-engineer`) ship as charter alignment, **not** as Trials — calling them
  Trials would fake a measurement that was never taken.

Measured genuine binding dispatch over 7 days: **sdet 5, security-engineer 1,
staff-engineer 1, every other role 0** — ~1.7% of ~420 spawns. Resulting pins:

| Agent | Was | Now | Basis |
|---|---|---|---|
| `sdet` | xhigh | **high** | Trial — 67% of all binding dispatch |
| `staff-engineer` | xhigh | **high** | Trial — 1 binding spawn |
| `distinguished-engineer` | xhigh | **high** | alignment (gate §4 Fable default); 0 binding |
| `senior-engineer` | xhigh | **high** | alignment; 0 binding |
| `security-engineer` | xhigh | **xhigh** | kept — threat reasoning |
| `project-manager`, `ux-designer` | high | **high** | already at the Claude 5 default |
| `team-lead` | xhigh | **pin deleted** | binds nowhere — never a report-only target |

Every changed pin carries a one-line provenance comment naming where it binds and
when it was derived, so a future sweep cannot mistake it for a carried-over 4.x
value. Two follow-ons remain open, both routed rather than dropped: the
`settings.json` (`high`) vs `src/user.rs` (`xhigh`) divergence → `/evolve-config`,
and an `effort_census.sh` that must derive its verdict from the `name=`
discriminator rather than from counting spawn sites.

<details>
<summary>Original follow-up text, retained for context</summary>

Charter §3 requires
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

</details>

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
