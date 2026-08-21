# policy.toml — rationale and evidence

Companion to `policy.toml` in this directory. That file now carries only the
functional routing tables, a short structural header, and the handful of
invariant comments an editor must not violate. Everything else that used to
live between its rows — the evidence narratives, retro history, benchmark and
ledger citations behind every value — lives here, moved out because
policy.toml's raw text is passed inside every wave/tribunal launch's args
(the engine pins it by content hash and never parses it; wave.js and
tribunal.js parse the TOML programmatically and drop comments), so narrative
comments there were pure per-launch token and latency overhead (DOT-477).

The operator's standing ruling (2026-08-11) is that values be DECIDED FROM
MINED EVIDENCE, not preference — which makes this evidence load-bearing
provenance, not disposable history. Nothing below has been summarized away;
it is the commentary from policy.toml, relocated intact.

Headings mirror policy.toml's own section structure. To find the "why" for a
table or row, match its name.

---

## File header (scope, enforcement split, provenance, version history)

policy.toml is wave-side spawn routing (05 §5, 02 §7).

THE ENGINE NEVER READS THIS FILE. Core pins it by content hash at activation
and registers nothing (06 §2; docket's own TDD states it outright: "No
`policy.toml` interpretation. It is pinned as bytes and never parsed"). Its
only consumers are wave.js and tribunal.js, which read these tables and
deliver the result as spawn model/effort — the workflow scripts read no files
(05 §5). Everything engine-ENFORCED lives core-side instead (06 §11.1):
budget cap, attempt defaults, lease TTLs, and context-size caps via
`docket config` / run flags and `[limits]`; gate timeout and flake policy in
trust entries (06 §4).

NO TRUST ENTRIES, NO ARGV TEMPLATES. Executable argv lives only in the
per-user `~/.config/docket/trust.toml` and is NEVER repo-shipped (06 §4) — a
cloned repo can never introduce execution. Workflows reference gate names
only; this file references none.

Provenance (T9): machine-authored, human-approved in conversation, never
hand-maintained (05 §1).

VERSION 2 (2026-08-11): the four generic tiers (bronze/silver/gold/diamond)
are retired. Variants are named for what they literally are — model plus
effort — and each executor row names the variant sized to its workload. The
operator directed 2026-08-11 that values be DECIDED FROM MINED EVIDENCE,
not preference, so every CHANGED row cites its evidence: the ledger
mining of this epoch (6 runs, 180 steps, 580 usage rows, 826 events since
the 2026-08-10 store reset) or, where a node has never spawned, the
workload analysis of its contract and workflow position. Structure —
literal variant names, escalate_to chains, gated fable entry, the version
bump — was operator-ratified in the same conversation. 05 §5's four-tier
ladder is superseded by the same authority that adopted it: operator
ratification in conversation.

---

## [variants]

Model+effort combos, named literally. There is NO implied ordering and no
generic ladder: escalation is the explicit `escalate_to` chain on each
variant, one hop per failed attempt. Rungs are still earned by a failed
attempt, never by predicted difficulty.

**Aliases, not model IDs.** Exactly one other file turns an alias into a
concrete model ID: src/user/claude_code.rs:135-138, the
ANTHROPIC_DEFAULT_*_MODEL env bindings (fable:135, opus:137, sonnet:138;
haiku:136 serves wave.js's internal read probes, which hardcode
model "haiku" / effort "low" in probe() outside policy.toml — no variant
there routes to it, so retuning the probe tier means editing wave.js
(DOT-386)). Duplicating model IDs in policy.toml would create a second
source of truth that drifts.

**EVIDENCE NOTE on chains:** the old ladder's escalation NEVER FIRED in this
epoch — all 22 lease-reaped events map exactly onto the 19 attempt>1 steps,
and zero step-failed/escalation events exist. Every observed "retry" was a
lease timeout, not a capability failure. The chains are therefore
sized from workload shape and failure asymmetry, not observed ascent, and
the next retro should re-read them once a real escalation has fired.

Every variant is referenced by an executor row or a chain hop — an
unreferenced variant violates the every-row-reachable invariant. wave.js's
probe seat is the one spawn routed outside the variants table entirely
(DOT-386), so spawn mining from these rows undercounts the fleet by the
probe share.

Per-variant notes:

- **sonnet-high** (escalate_to = opus-high): a failed cheap-model attempt
  earns review-grade capability in one hop (the old bronze->silver jump),
  not an effort tweak on the same model.
- **opus-max** (escalate_to = fable-max): the pre-fable rung — failed deep
  work escalates within Opus before the fable gate fires.
- **fable-max**: top of the system; no escalate_to. Entry by chain is gated —
  see [escalation].fable_gates.

---

## [executors]

executor hint -> variant (02 §7). Keys are node names from 04 — opaque
strings core never interprets (05 §1).

The step records requested vs resolved model (the harness may substitute),
which makes routing drift measurable from the ledger itself (02 §7). This
epoch measured it: 179/180 steps resolved faithfully; the single drift was
one judge-simplicity step requesting effort=high and resolving effort=medium.

### Write nodes

- **implement** = sonnet-high — RAISED from sonnet/medium on ledger evidence:
  its output drew 371 findings (26 blockers, 124 high) across 11 issues,
  7 of 11 needed a fix round, and every quality-attributable gate failure in
  the epoch traces to implement. Review costs 7.8x the tokens and 7.3x the
  wall clock of the writing it reviews, so effort spent here discounts the
  system's dominant expense.
- **test-infra** = opus-high — RAISED from sonnet/medium on workload evidence
  (zero spawns this epoch): its contract asks for permanent API design —
  seams no downstream test can retrofit — and it is the rarest write node
  (label-keyed only), so the per-spawn saving the cheap tier bought was
  negligible against the durability of what it writes.
- **fix** = opus-medium — RAISED from sonnet/medium on workload evidence:
  fix adjudicates between opposing opus-high judge findings ("fix for the
  stronger argument"), falsifies INFERRED findings, and carries the corpus's
  only recorded tier-attributed failure (a cheap-tier fix round wrote two
  gate scripts that fed three review rounds of defects). It fires 0-2 times
  per issue, so the saving was small — and its worst failure modes (the
  swallowed error, the widened assertion) PASS gates, so escalation can
  never reach them: capability must be set at dispatch. Ledger corroborates
  the workload weight: fix averaged 3.3x the output tokens and 2.3x the wall
  clock of implement while both sat at the same tier.
- **commit-author** — row removed 2026-08-09 (operator policy, ratified in
  conversation): the commit tail is gone from every workflow — automated
  commits are incompatible with the harness security model (interactive
  1Password commit-signing authorization is unavailable to headless
  executors). Executors commit unsigned in their private worktrees, the
  conductor integrates each sha, and the operator alone publishes.

### Review nodes

opus-high is the floor for ASSURANCE-BEARING review, and dispatching such
review below it is a routing defect: a judge exists to find defects the
author missed, and a model that misses them too returns a clean verdict
worth less than no review at all. The floor now binds by what a node's
output DOES rather than by section membership: nodes whose findings gate
shipping keep it; nodes that transcribe or advise are sized to that.

- **judge-correctness** = opus-high — blocker yield 0.42/spawn (n=20) —
  earns the floor.
- **judge-architecture** = opus-high — blocker yield 0.58/spawn (n=20) —
  highest in the epoch.
- **judge-testing** = opus-high — blocker yield 0.32/spawn (n=20).
- **judge-design** = opus-high — zero spawns (ui-change never ran); floor by
  class.
- **judge-simplicity** = opus-medium — LOWERED from opus/high on ledger
  evidence: 611,318 output tokens across 22 spawns produced 1 blocker and
  11 highs (yield 0.05/spawn, 12x below judge-architecture). Fix loops are
  blocker-only, so its output is almost entirely advisory. Same model, less
  effort — the lens stays, the spend matches the yield. The watch item that
  rode here — was the low yield effort-bound rather than dimension-bound? —
  is ANSWERED, and the downsize stands (retro 2026-08-19): 12 post-downsize
  spawns across three independent analyst windows returned 0 blockers and a
  unique yield of 1 low plus 1 adopted high, with no capability degradation
  visible in the bodies, at 3-5x cheaper than any other seat in the fanout.
  opus-medium stays. Cutting the SEAT is a different question and 12 spawns
  do not answer it: re-read at n >= 20 before it is asked (D2).
- **design-qa** = opus-high — zero spawns; terminal verification of BUILT
  output, once per UI issue.
- **verify-ac** = opus-high — kept at the floor despite a near-mechanical
  contract: it is the terminal step, and its one judgment (gate passed but
  intent visibly unmet) is exactly the false-assurance case the floor
  exists for.
- **synthesize-findings** = opus-high — clustering IS the judgment; all
  downstream severity arithmetic derives from it.
- **pr-comment-author** = sonnet-high — LOWERED from opus/high on workload
  evidence (zero spawns): transcription of already-made findings into PR
  prose — no assurance produced, smallest packet in the corpus (7.9KB), 0-1
  spawns per release. Stakes are reputational (posts under the operator's
  GitHub account), which is a review-the-draft concern, not a capability
  one.

### Authoring nodes

Open-ended synthesis whose cost lands later, when the document is relied on.
The through-line in their contracts is that DECLINING to write is part of
the deliverable ("say so and name the cheaper route"), a judgment cheaper
spawns reliably get wrong in the productive direction: they write the
document. Zero authoring spawns this epoch (only standard-change and
investigation have ever run), so these stand on workload analysis, unchanged
in effect from their prior ratification.

There is deliberately NO `spec-doc-author` row and no router of that name
anywhere: spec-doc's authoring is six when-gated workflow steps, each
declaring one of the five concrete authors directly (DKT-70 decision (d),
2026-08-13 — the label-keyed [[resolve]] tables are retired).

- **prd-author** = opus-high — product intent and acceptance criteria —
  authoring-class but not the architectural design work above it; also the
  doc-type-unlabeled default, via spec-doc's author-prd `when` clause.
- **tdd-author-security** = opus-xhigh — RAISED from opus/high: it is the
  same design work as tdd-author — the security pin bars a MODEL, it does
  not discount the work. The old row under-sized it relative to its
  unpinned twin.

**spec-author-\* fanout:** spec-project's seven reserved spec files (05 §2),
one row per fanout hint. [OBSERVED] Seven DISTINCT executor hints, not seven
spawns of one: `internal/workflow/expand.go:160-168` assigns
`row.Executor = hint` per sibling — the hint IS the per-sibling identity
carrier telling sibling #1 to write the architecture spec and #4 the
performance spec.

### Investigator-class

Diagnosis and synthesis with no map to follow; the only work standing at
fable-max (until the 2026-08-19 swap below). Ledger (n=2, small):
investigate at fable/max averaged 3.6 minutes and 16.3k output tokens — the
top of the system was also its CHEAPEST band this epoch (0.6% of output
tokens), so there is no cost case against the standing home and a capability
case for it: the smallest declared input of any node (issue body only) means
everything else must be found, and a confident wrong guess costs a full
cycle.

MODEL SWAPPED fable -> opus 2026-08-19, effort ceiling UNCHANGED. The
capability case above is a case for the CEILING, not for fable, and opus-max
is the same ceiling. Two readings put opus ahead at that ceiling: benchlm.ai
(2026-08-19) ranks Opus 5 #2 at 83.1 against Fable 5 #3 at 83.0; and the
local 7-day census (scripts/session-census) measured, at identical
effort=max, opus-5 at 30.3% thinking against fable-5 at 59.0%. Better score,
about half the deliberation. Operator ruling the same day: model diversity is
not a goal, best measured result is, and `max` is reserved for work that
genuinely needs the ceiling — which this class does.

fable-max is no longer any row's standing home. It stays live as the final
chain hop off opus-max, which is what [escalation].fable_gates was written
for ("failed-top-opus-round"): fable is now reached only by work that has
actually failed at the top of Opus, never by declaration.

- **research** = opus-max — swapped with its class, but still never
  exercised: 4 lifetime spawns planned, 4 skipped, 0 executed. If the next
  retro still reads 0, the honest move is to drop the research fanout from
  investigation.toml at a version bump and retire this row with it — an
  unreachable row is a routing claim nothing tests.
- **retro-analyst** = opus-max — mines the entire run ledger -> proposals
  (04, 05 §6). Swapped with its class, and the one row of the three with
  direct measurement: 6 spawns, 503,339 output tokens, 67.8% of it thinking
  (census 2026-08-19). Ceiling kept — a retro reads a whole epoch — but on
  the model that benchmarks higher and deliberates roughly half as much.

### Tribunal seats

The standing panel where workflows used to declare `type = "human"`.

CORRECTION 2026-08-19 (operator): "2 Fable and 1 Opus" was never a chosen
composition and carries no diversity intent. The panel was Fable throughout;
the security seat is Opus ONLY because fable is barred from security work
(`never = ["fable"]`, the security-classifier reroute). Read every "2-and-1"
claim below as an artifact of that reroute, not a design to preserve — it was
cited as validation for years' worth of pins it never actually justified.

Earlier text, kept for the ledger evidence it carries: across 36 votes and 12
decided proposals, no tribunal verdict was ever overturned by the operator,
and all three rejections caught real defects and were answered by rework. The
asymmetry argument stands: a wrong rejection costs one operator read; a
wrong approval consumes the operator gate unbounded.

Reachability: referenced by the `voters` lists in investigation.toml
(`read-gate`), spec-doc.toml (`accept-human`), spec-project.toml (`accept`),
and retro.toml (`accept`). Retiring any of those four retires the row.

SELF-REPORTED IDENTITY, UNMEASURED COST. Each ballot now carries its seat's
identity, model, effort, and variant (`vote_metadata`) — but the engine
stores that bag uninterpreted and verifies none of it, so it is an
attribution trail, not a faithfulness check: a silently rerouted model
would still write the requested name here. Resolved-model faithfulness AND
seat spend both remain unmeasured (`vote_usage` held 0 rows all epoch — a
filed engine gap), which is why these rows cite vote outcomes, not cost.

COST NOW MEASURED (2026-08-19) — the gap the paragraph above names is closed,
not from `vote_usage` (still 0 rows) but from the session transcripts, via
src/user/claude_code/scripts/session-census. Over 7 days, 189 tribunal seats
ran at effort=max and burned 5,309,378 output tokens at 68.7% thinking — the
highest deliberation ratio of any role measured anywhere in the fleet, and
14% of all subagent output. A seat reads one proposal and casts one ballot
with a reason.

LOWERED to opus-high on that measurement plus the outcome record above: 36
votes, 12 decided proposals, ZERO verdicts overturned. A perfect outcome
record is evidence of headroom, not of a ceiling being earned — had a verdict
ever been wrong the argument would run the other way. Two further reasons:
these seats outranked `judge-*` (all opus-high), so a voter was more
expensive than the judge whose findings it votes on; and opus-high still
reaches fable-max through the chain (opus-high -> opus-xhigh -> opus-max ->
fable-max), so the ceiling stays available to a seat that actually fails,
it is just no longer the entry rung.

SWAPPED to opus-high on mined evidence, with no composition constraint to
respect (see the correction above). Every reading available points one way,
and none points at fable:

- Public benchmark (benchlm.ai, 2026-08-19): Opus 5 #2 at 83.1, Fable 5 #3
  at 83.0. Opus ahead, if narrowly.
- Local census (scripts/session-census, 2026-08-19): at identical
  effort=max, opus-5 spent 30.3% of output on thinking, fable-5 59.0%.
- Vote ledger, tribunal seats only (n=162): nothing separates them on
  quality. No seat of either model recorded a single finding; confidence
  is 0.87 fable vs 0.833 opus, and that gap is the security lens scoring
  its own domain-relevance low on non-security proposals, not judgement.
- Cost, the one unambiguous signal: 189 seats spent 5,309,378 output tokens
  at 68.7% thinking — 11.7 characters of private deliberation per
  character of the ballot cast. Highest ratio of any role in the fleet.

Effort drops max -> high in the same move. That is deliberate: `max` is
reserved for work that genuinely needs the ceiling (operator ruling
2026-08-19), and a seat that reads one proposal and casts one vote does not.

KNOWN UNTESTED: this makes the tribunal all-Opus for the first time. The
ledger has 54 proposals of mixed-panel history and zero all-Opus tribunal
history, so the reject rate is the thing to watch — the security seat
rejects 22% where the fable seats rejected 7%, and if the whole panel moves
toward 22% the cost lands as rework loops and operator gates, which is the
very expense this change set out to cut. Re-read at the next retro against
`select status, count(*) from proposals group by status`.

- **tribunal-security** = opus-max — RAISED from opus/xhigh: the security
  ceiling is now opus-max (see [security]), and this seat earned the
  headroom — it was the swing rejector on both split-decision rejections
  this epoch (P6, P11), each sustained. Still the "1 Opus" of the ratified
  2-and-1: the pin bars fable, and top-of-Opus is the most the pin permits.

### Security nodes

**threat-model** = opus-high, pinned off fable — see the [security] section
for why these nodes never reach fable.

---

## [security] — Security model pins

02 §7: "Security-sensitive node types carry a `never: [model...]` list
honored at spawn (the vendor-classifier constraint that pinned security work
off Fable is a policy row with a reason, not folklore)."

The reason is a durable property of the model, not a fact about today's
entitlements:

> Fable screens cyber and bio content and quietly serves Opus instead when a
> request trips those screens. Security review trips them by its nature. The
> harm is the silence, not the substitution: the ledger would attribute the
> finding to a model that never produced it, so the provenance of a security
> judgement becomes unreliable. Naming Opus up front keeps the recorded
> model and the executing model the same, whatever the screens decide.

Consequences, both deliberate:

- Sensitivity is checked ahead of any escalation hop. Security-sensitive
  work takes these pins even when its node's own row says otherwise.
- opus-max is the ceiling for this work — the top Opus rung, raised from
  the old gold/opus-xhigh when opus-max entered the menu, because the
  ceiling's purpose was always "climb Opus fully, never fable", not a cap
  below Opus's top. A security step that fails AT opus-max gets broken
  into smaller pieces; there is no higher rung the pin permits.

The `labels` key: sensitivity is a property of the TASK, not only the node. A
step on an issue carrying any of the listed labels takes the security pins
even when its own executor row is unpinned.

---

## Label-keyed executor resolution: RETIRED (2026-08-13)

The two [[resolve]] tables that lived in policy.toml (implement ->
test-infra, and the spec-doc-author doc-type router) are gone: the engine
composes packets from a step's DECLARED executor, so a table-resolved hint
always rendered the wrong contract (m3-harness.md F-W1). Label routing is
now when-gated sibling steps in the workflow files, each declaring its
concrete executor — standard-change's implement/implement-test-infra and
spec-doc's six author variants. wave.js refuses to route while any
[[resolve]] table is present, so a stale install fails loudly instead of
mis-briefing silently.

---

## [escalation]

One `escalate_to` hop per failed attempt, following the chain from the
row's standing variant. Rungs are earned by a failed attempt, not predicted
difficulty — the presence of a security-sounding keyword in an issue is not
on its own a reason to move.

Note the asymmetry with core: the engine's `max_attempts` / `on_fail` decide
WHETHER a step retries (06 §11.1, engine-enforced). This decides what
variant the retry SPAWNS at. Two different questions; the engine owns the
first.

KNOWN LIMIT, deliberate and now evidence-backed: escalation is structurally
blind to failure modes that PASS gates (the symptom-suppressing fix, the
interaction-coupled test seam) — which is why fix and test-infra were
right-sized at dispatch instead of left to earn rungs they can never earn.

`on_failure = "one-hop"`: exactly one escalate_to hop per failed attempt
(security work stops at [security].ceiling — declared ONCE there, and it is
a true bound: a walk never enters what lies beyond the ceiling on the
chain).

`fable_gates`: entering a fable-model variant BY CHAIN-WALK needs a gate; a
row STANDING on a fable variant needs none — its residency is policy.toml's
own declaration.

- `"investigator-class"` — diagnosis with no map to follow — admits a walk
  into fable should an investigator-class hint ever stand lower.
- `"novel-architecture"` — a TDD/ADR/UX spec standing up a subsystem or seam
  with no precedent here.
- `"failed-top-opus-round"` — work STANDING at opus-xhigh or opus-max that
  already failed there — cheap-tier and floor-tier rows top out at opus-max
  instead.

### [escalation.fallback]

When fable cannot be used — gate unmet, never-listed, or unavailable (under
zero-data-retention a Fable request fails outright instead of degrading, so
unavailability is a normal condition) — the step drops to the top Opus rung:
`fable-max = "opus-max"`.
