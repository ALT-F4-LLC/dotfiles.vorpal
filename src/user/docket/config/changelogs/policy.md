# policy changelog

Version history of `policy.toml`, newest first. Each heading is the
`[policy].version` the entry describes.

## 37

every comment leaves the file; no routing value changed. The
version-bound row notes (each row's prior tier, the evidence for
its move, its retry walk, and its "Retro:" baseline) now live in
this changelog under the entry for the version that made the
move: 21 (the source list cited as D1-D7), 23 (the judge and
tribunal-correctness moves), 29 (every other row), and 32
(judge-testing). Removed outright, recoverable from the file at
36: the `blocked` label semantics and its epic exception; the
note that every `[security].labels` entry also routes and must
be mirrored in security-change's `labels_any` and every sibling
workflow's `unless_labels`; the security-load-bearing labeling
test and its six control classes (drain-highs@15 drops the
filing-time check that pointed at it); the `[security] reason`
gloss on D7; the [escalation] notes on how on_failure and
on_round walk, the one-hop ruling, and the declined proposal
that `fix` start one hop up on security-labelled issues; the
[escalation.fallback] note on why fable-low maps to
opus-medium; and the standing notes on tribunal-architecture's
seats and drain-highs' seat description. docket-retro's
evidence table now reads judge-testing's baseline from entry 32
instead of a row comment.

## 36

Version history moves from the trailing comment on `version =` to
`changelogs/policy.md`; no routing value changed.

## 35

comment-only concision rewrite; no routing value changed.

## 34

comment-only correction to [escalation], no routing value
changed. The paragraph beginning "The on_failure walk is
keyed on the row's claim count" described a since-resolved
engine limitation: the installed engine's resolver now keys
the on_failure walk on recorded failures (the row's
FailedAttempts field, claims that ended in an explicit `step
fail`) rather than the bare claim count, and a claim that
ended in a reap re-runs at the tier it was reaped from
instead of walking one hop up. The paragraph is rewritten to
state this. `on_failure = "one-hop"` and every other
[escalation] value are byte-identical; this is a comment
correction, not a policy change.

## 33

comment-only corrections, no routing value changed. Fixes
five stale or inconsistent row comments surfaced by a corpus
audit: the v24 comment claiming `investigate`'s tier at the
time was `fable-high` now says so explicitly as history (both
rows stand at `fable-low` today, moved by a later policy); the
verify-ac-vote comment's stale `judge-correctness` tier
(opus-high -> its actual current opus-medium) and stale
escalation claim (removed; the seat is vote-only with no
attempt walk); the tribunal-architecture comment's dead step
name (`accept-vote` -> `spec-vote`, spec-project's step name
since v19) and wrong co-seated voters for the spec-project
case (tribunal-security/tribunal-correctness, not
tribunal-design); the D5 comment's stale claim that only
judge-correctness hops opus-medium -> opus-high, now noting
judge-architecture and judge-testing moved to opus-low and
sonnet-low respectively; and two `Docket-retro` capitalizations
normalized to `docket-retro` for consistency with every other
reference to the skill.

## 32

judge-testing moves opus-low -> sonnet-low as the corpus's
one second-family review seat, a retro-measured experiment in
panel decorrelation rather than a tuning. Every other judge-*
and tribunal-* seat but tribunal-design stands on Opus, so a
panel's seats differed by lens and effort but never by model
family, and the match-rate statistics the workflow changelogs
cite ("the seat matched the panel N of N") say nothing when
the seats share a model. The metric that judges the move is
sole-finder clusters, never match rates; docket-retro's evidence
table reads the baseline recorded below. No other routing value
changed; [security] never/ceiling/labels/nodes are byte-identical.

Row note, recorded at 32 and moved here at 37: sonnet-low, from
opus-low, as the corpus's one second-family review seat: a
retro-measured experiment in panel decorrelation, not a tuning.
Every other judge-* and tribunal-* seat but tribunal-design
stands on Opus, so a panel's seats differ by lens and effort,
never by model family, and seats sharing a model share its blind
spots: "seat X matched the panel N of N" then measures
conformity, not independent detection, and is not evidence for
or against any seat. Chosen because it carries the most
sole-finder highs of any review seat (clusters no other seat
raised: 154 high / 3 blocker across 187 reconciled
standard-change rounds, 128 / 0 across 107 ui-change rounds,
103 / 7 across 98 security-change rounds), so a family change
here is the most measurable. Sonnet rather than Fable: on a
security-labelled row [security].never forbids Fable for every
seat and the fallback would put this seat back on Opus, and
Fable's broader safety classifiers re-run flagged requests on
another model with nothing in the step record catching the hop;
Sonnet has neither, so the panel mixes families on every track.
sonnet-low rather than sonnet-medium: the same effort tier as
the row it replaces, and its retry lands on sonnet-medium, still
in family, where sonnet-medium's retry would switch to
opus-medium on exactly the reap re-runs that dominate high-tier
samples. Taken against D2, which places Sonnet 5 at low on chat
and non-coding use; a fall in this seat's yield cannot on its
own be told apart from that tier placement. At opus-medium this
seat ran 204 completions at a median 7.5 min with 1.91 findings
per review (0.90 high-severity); it was the slowest seat of 49%
of three-judge fanouts. Retro: sole-finder clusters per
reconciled round, read from the synthesize step's
findings-cluster member_sources traced to this seat's review
step, against 0.82 high per round on standard-change, 1.20 on
ui-change, 1.05 on security-change; findings per review against
1.91; fanout median against 7.5 min. Never by how often its
findings matched the Opus seats'. Partition by the step row's
model_requested so a reap re-run that walked onto Opus is read
apart.

## 31

comment-only concision rewrite; no routing value changed.

## 30

comment-only, no routing value changed. Engine commit
ffd117a (docket nightly-101) exempts fable-standing
rows from the post-walk fable gate, so fable-low's retry now
stays on Fable for every row, not only the investigator
class; the version 29 deviation note and its per-row echoes
are dropped. Also corrects two version 29 comments: opus-low's
retry lands above the tier judge-testing and judge-architecture
left (opus-medium), and fix's security-labelled walk diverges
from the unlabelled one at round 4.

## 29

lower default effort across the corpus. Reverses policy
27's implement/fix move and goes below it: every row but
judge-simplicity now stands at the lowest tier its model
supports (three `low` variants added; judge-correctness,
tribunal-correctness and verify-ac at opus-medium), on the
operator's direction to be bullish on lower effort for
wall-clock and more incremental fix-loop rounds over longer
individual steps, taken against the measured or documented
recommendation where one existed (each such row says so).
What the store showed: across all 100 runs no step has ever
recorded a failed attempt (`failed_attempts` is 0 on every
row, no step-failed event exists), so the on_failure ladder
has only ever moved on lease reaps and the retry that actually
happens is the fix loop, at a mean 42 lane-minutes per round.
docket-retro checks each row's retro number after about five
runs on this version. [security] never/ceiling/labels/nodes
are byte-identical.

D4's re-run-failures pattern is what [escalation] implements: a
non-gated opus-medium seat that fails hops to fable-medium,
misses the fable gate, and lands on [escalation.fallback]
opus-high, the model's default effort. Row notes, recorded at 29
and corrected through 36, moved here at 37; each names the tier
the row left, its evidence, its retry walk, and the retro
baseline docket-retro reads:

- drain-highs: sonnet-low, from sonnet-medium. 110 completions
  at sonnet-medium ran a median 2.7 min; D2 places Sonnet 5 low
  on "chat and non-coding use cases". One retry lands on
  sonnet-medium. Retro: median against 2.7 min.
- adr-author: fable-low, from fable-high. Nothing measures this
  seat (6 steps, all skipped); D4's knowledge-work class and
  D5's "at low ... often competitive" are the only ground. A
  retry walks fable-low -> fable-medium and stays on Fable
  (policy 30, engine commit ffd117a), one notch below
  fable-high; the max_attempts = 2 cap binds. Retro: adr-vote
  outcomes at this tier.
- design-qa: opus-low, from opus-high. 129 completions, all at
  opus-high (median 10.3 min, p90 16.4; nine reap re-runs at
  opus-xhigh ran 11.7); nothing measures low, and its verdict
  is a silent detector. One retry lands on opus-high through
  opus-low's escalate_to. Retro: median against 10.3 min; NO
  COVERAGE and fail verdict rates.
- dispose: opus-low, from opus-high. The disposition workflow
  has never run, so nothing is measured. Round 2 onward climbs
  to opus-high through on_round (round_executors), and a retry
  within max_attempts = 2 lands on opus-high.
- fix: opus-low, from opus-high, against the measured
  recommendation of opus-medium (policy 27's tier before the
  reversal). fix binds more measured waves than any other
  executor (60 of 223, 19 min mean when it binds); round 1 at
  opus-medium ran a median 14.5 min over 39 attempts and looped
  again 16 of 32 times; nothing measures low, D4 has Opus 5
  giving up about 8 points at low against 2 at medium, and
  every extra loop costs a mean 42 lane-minutes. Round 2 onward
  climbs to opus-high through on_round; a retry lands on
  opus-high through opus-low's escalate_to. Unlabelled, the
  rounds climb opus-high, then opus-xhigh (fable-high
  redirected by the post-walk gate), and stay there at round 4
  because fable-high is a chain top; on a security-labelled
  issue `never` redirects fable-high to opus-xhigh and round 4
  reaches opus-max at the ceiling, so the two walks diverge
  there. Retro: round-1 median against 14.5 min; looped-again
  against 16 of 32.
- implement: opus-low, from opus-high, against the measured
  recommendation of opus-medium (the reversal of policy 27,
  which landed on reasoning alone; the one genuine first
  attempt at opus-high since ran 7.6 min in a one-issue run).
  implement binds 36 of 223 measured waves (19 min mean when it
  does), 18% of a lane's serial minutes. opus-medium served 274
  attempts (median 12.5 min, p90 21.6) with 45 of 250 issues
  (18%) entering a fix loop afterwards; nothing measures low,
  D4 has Opus 5 giving up about 8 points at low against 2 at
  medium, and a loop costs a mean 42 lane-minutes, so low pays
  only where its saving exceeds 0.42 min per point of extra
  loop entry. Judges and verify-ac stay the failure detector.
  The one retry within max_attempts = 2 lands on opus-high
  through opus-low's escalate_to. Retro: median against 12.5
  min; loop entry against 18%.
- investigate: fable-low, from fable-high. Eight completions
  across four runs: 2.2 min at fable-max (2), 5.4 at opus-max
  (4), 2.9 at fable-high (2); D1 names root-cause investigation
  as Fable's ground, D5 has low calling retrieval less often. A
  retry walks fable-low -> fable-medium and stays on Fable, one
  notch below fable-high; the max_attempts = 2 cap binds.
  Retro: report-vote outcomes and investigate minutes at this
  tier.
- judge-architecture: opus-low, from opus-medium. 211
  completions at opus-medium ran a median 4.5 min with 1.64
  findings per review (0.55 high-severity); nothing measures
  low on a silent seat. A retry lands on opus-high through
  opus-low's escalate_to, above medium. Retro: findings per
  review against 1.64.
- judge-correctness: opus-medium, from opus-high, on the policy
  23 evidence statement rather than the retry argument (a
  judge's miss is silent and never escalates). Since policy 23
  the two lenses it moved emitted as many findings per review
  at medium as at high (judge-architecture 1.64 vs 1.64,
  judge-testing 1.91 vs 1.86), though every high-tier sample
  since is a re-run after a reap. This lens is the slowest seat
  of 30% of three-judge fanouts and the only seat of
  small-change and docs-only reviews (24 since RUN-90). It also
  votes on security-change's security-vote and spec-doc's
  tdd-vote and adr-vote; the engine seats voters at the
  standing tier, so those panels move with it. A reaped or
  failed seat still re-runs at opus-high. Retro: findings per
  review against 0.95 (0.34 high).
- judge-design: opus-low, from opus-high. 208 completions, all
  at opus-high (median 6.5 min, 1.13 findings per review, 0.46
  high-severity; five reap re-runs at opus-xhigh ran 8.8);
  nothing measures low and a miss is silent. One retry lands on
  opus-high. Retro: findings per review against 1.13.
- judge-security: opus-low, from opus-high. 168 completions,
  all at opus-high (median 7.8 min, 1.9 findings per review),
  on security-change's fanout, spec-doc's review and the
  security-vote panel; nothing measures low here, and a miss on
  this seat is a silent security miss that never escalates.
  `never` and the [security] ceiling bound the walk, not the
  standing tier: a retry lands on opus-high, then fable-high is
  forbidden and redirects to opus-xhigh. Retro: findings per
  review against 1.9; security-vote rejects.
- judge-simplicity: kept at opus-medium; no decision covered
  it.
- judge-testing: opus-low, from opus-medium; moved again at 32,
  which carries its note.
- prd-author: fable-low, from fable-medium. Never run (6 steps
  skipped); D4's knowledge-work class and D5's "at low ...
  often competitive" are the only ground. A retry walks to
  fable-medium and stays on Fable (policy 30, engine commit
  ffd117a), reaching the prior tier within the max_attempts = 2
  cap. Retro: prd-vote outcomes at this tier.
- report: fable-low, from fable-high; matches investigate. Four
  completions (as investigation.toml's former `report` step)
  ran a mean 3.8 min. A retry walks to fable-medium and stays
  on Fable (policy 30), one notch below fable-high. Retro:
  report-vote outcomes.
- research: fable-low, from fable-medium, overriding the
  documented D5 retrieval floor (at low Fable "calls search and
  retrieval tools less often", so medium was the floor for a
  seat whose whole job is retrieval). The step has never
  completed (7 steps, all skipped), so nothing measures either
  tier. A retry walks to fable-medium and stays on Fable.
  Retro: the check that would show retrieval dropping is the
  source count and external-source citations per research-notes
  artifact at fable-low against the first notes recorded at any
  higher tier; a drop restores the floor.
- revise-investigation: fable-low, from fable-high; matches
  investigate. The step has never run. A retry walks to
  fable-medium and stays on Fable (policy 30), one notch below
  fable-high.
- spec-author-* (all seven): opus-low, from opus-high. No run
  has expanded spec-project's author fanout, so nothing is
  measured. One retry within max_attempts = 2 lands on
  opus-high through opus-low's escalate_to; the security axis
  keeps `never`, and its walk continues opus-xhigh, opus-max.
- synthesize-findings: sonnet-low, from sonnet-medium. 221
  completions at sonnet-medium ran a median 2.7 min (p90 5.6);
  D2 places Sonnet 5 low on "chat and non-coding use cases".
  One retry lands on sonnet-medium. Retro: median against 2.7
  min; reconcile aggregate outcomes.
- tdd-author: fable-low, from fable-high. Never run (6 steps
  skipped); the same ground and retry walk as adr-author
  (fable-medium, on Fable; the cap binds). Retro: tdd-vote
  outcomes.
- tdd-author-security: opus-low, from opus-high. Four
  completions, all at opus-xhigh (17.6 min mean, one run), none
  at high or below, so nothing measures the move. `never` and
  the ceiling bound the walk: a retry lands on opus-high, then
  fable-high is forbidden and redirects to opus-xhigh. Retro:
  tdd-vote outcomes for the security TDD at this tier.
- threat-model: opus-low, from opus-high (policy 20 had moved
  it from opus-xhigh). The threat model is the security track's
  longest serial stage and binds 11 measured security waves;
  139 completions ran a median 7.8 min at opus-high (77
  recorded) and 7.9 at opus-xhigh (24, an earlier era); effort
  barely moved it, the expected saving is small, and nothing
  measures low; the security-vote panel is its detector.
  `never` and the ceiling bound the walk: a retry lands on
  opus-high, then fable-high is forbidden and redirects to
  opus-xhigh, then opus-max at the ceiling. Retro: median
  against 7.8 min; security-vote rejects on the threat model.
- tribunal-architecture: opus-low, from opus-high. 328 casts
  across six tiers with a reject rate that did not track the
  tier (fable-high 4 of 32, fable-xhigh 3 of 62, fable-max 4 of
  56, opus-high 12 of 152, opus-max 3 of 18, opus-xhigh 0 of
  8); nothing measures low. A vote seat never walks. Retro:
  reject rate against these.
- tribunal-correctness: opus-medium, from opus-high, on the
  same D4 knowledge-work ground as judge-correctness. Across
  every tier this seat has served (fable-high, fable-xhigh,
  fable-max, opus-high, opus-xhigh, opus-max; 361 casts) its
  reject rate stayed near 6%, so the tier has not been what
  decides the verdict; the single-seat verify-ac-vote panel ran
  a median 5.7 min at opus-high across 52 lanes. A vote seat
  has no attempt walk, so this is the tier it always runs at;
  the [security] ceiling and never-list still apply on a
  security-labelled row. Retro: reject rate against 6%; panel
  against 5.7 min.
- tribunal-design: fable-low, from fable-high. This seat has
  never cast a vote (ux-spec-vote never reached), so nothing is
  measured. A vote seat never walks; on a security-labelled row
  `never` sends it through [escalation.fallback] to
  opus-medium.
- tribunal-security: opus-low, from opus-high. 328 casts with a
  reject rate that did not track the tier (opus-high 11 of 114,
  opus-xhigh 9 of 80, opus-max 15 of 134); nothing measures
  low, and a miss on this seat is a silent security miss. A
  vote seat never walks; `never` and the ceiling still apply.
  Retro: reject rate against these.
- ux-spec-author: fable-low, from fable-medium. Two
  completions, both at opus-xhigh in the earliest runs (19.7
  min median), none on Fable; the same ground and retry walk as
  prd-author. Retro: ux-spec-vote outcomes.
- verify-ac: opus-medium, from opus-high, against the measured
  recommendation to keep opus-high. 206 completions at
  opus-high ran a median 7.1 min (p90 10.9) and 18 reap re-runs
  at opus-xhigh 7.3; effort barely moved it. It flags an unmet
  or unverifiable AC on 58% of its reports, and a seat that
  marks more ACs unverifiable adds a 5.7-minute verify-ac-vote
  to the lane tail, the risk accepted here. A retry lands on
  opus-high. Retro: median against 7.1 min; unverifiable share
  against 114 of 619 ACs.

## 28

fixes a grammar slip in the round-1 fixer comment ("the
docket-retro attributes" -> "docket-retro attributes"). No
routing value changed.

## 27

implement and fix move opus-medium -> opus-high. The design
search (fragments/design-search.md) puts an architecture
decision inside every writer step, and D1 names architecture
decisions as where extra investigation pays; D6 has review and
verification at high. Round 2 onward already landed on opus-high
through the fallback, so the retune removes the cheap first
round rather than adding a tier. Escalation for both is now
fable-high via opus-high's escalate_to.

## 26

the [escalation] note now records what the reap-vs-failure
measurement found and where the fix belongs (the engine's
resolver now sees `prior_attempt_end` on the row but still
walks the bare claim count) and rules that `one-hop` stays;
the [security] `reason` no longer claims that executor
metadata catches a classifier re-run, since the wave records
`model_resolved` as unknown unless the runtime supplies an
observation. No routing value changed.

## 25

docket-groom now parents retained issues under epics and
can propose creating one, marking it `blocked` so no workflow
selects it. That is a permanent use of the hold label, which
this file's `blocked` comment did not previously cover.

## 24

corpus-wide naming-convention pass
(src/user/docket/config/README.md) adds two `[executors]` rows,
`report` and `revise-investigation`, promoted from borrowing
`investigate`'s policy row (investigation.toml renamed their
steps to match their own executor identity). Both inherit
`investigate`'s then-current `fable-high` tier absent evidence
to retune it (both rows now stand at `fable-low`, moved with
`investigate` by a later policy). No existing row renamed or
retuned at 24.

## 23

judge-architecture and judge-testing at opus-medium, down from
opus-high; judge-correctness stays at opus-high. Measured on
RUN-90 (session 099f7b93, 36 waves, 1594 agent-minutes): the
three review seats were 45% of all agent time (judge-testing
281 min at 8.5 min per seat, judge-correctness 215 min,
judge-architecture 191 min) against implement's 16%. D4 has
Opus 5 at medium giving up about 2 points for half the cost,
with re-running failures at the default recovering the pass
rate; the escalation ladder is that re-run: a judge seat that
fails hops opus-medium -> opus-high (as judge-correctness still
does; judge-architecture and judge-testing have since moved to
opus-low and sonnet-low respectively). D5 keeps this on Opus
rather than a smaller model at a higher effort. The correctness
lens keeps the default: it is the seat whose misses reach the
tree.

tribunal-correctness at opus-high, down from fable-high.
standard-change and security-change interpose a single-seat
verify-ac-vote (named verify-tribunal and three-seat at @31;
renamed and cut to tribunal-correctness alone since) on every
verify that reports an AC unverifiable, which on a repo whose
ac-commands gate is a stub is nearly every issue (measured 20
of 23 under the old name), so this seat is a per-issue pipeline
step, not an occasional conversational gate. D1's ground for
Fable, architecture decisions and precedent, is the
conversational-gate case; verify-ac-vote weighs an AC report
against a diff, the review-executor work judge-correctness
already does at opus-medium. This seat is vote-only and, like
other vote seats, has no attempt walk.

Recorded in policy.toml's comments at the time; moved here at
37.

## 21

model/effort re-derived from Anthropic's official documentation
(fetched 2026-09-02), fit to each seat's role, cost-aware. Later
entries cite the sources as D1-D7:

- D1 code.claude.com/docs/en/model-config: aliases resolve
  fable -> Fable 5.1, opus -> Opus 5, sonnet -> Sonnet 5, haiku
  -> Haiku 4.5; effort is low|medium|high|xhigh|max with `high`
  "The default on every model except Opus 4.7"; `max` "may show
  diminishing returns and is prone to overthinking. Test before
  adopting broadly"; Fable: "root-cause investigations, outage
  debugging, and architecture decisions are where the extra
  investigation and verification pay off".
- D2 platform.claude.com/docs/en/build-with-claude/effort:
  xhigh: "Long-running agentic and coding tasks (over 30
  minutes) with token budgets in the millions"; Fable 5.1:
  "Start with `high`, the default. Step up to `xhigh` or `max`
  for the most capability-sensitive agentic and coding work, and
  step down to `medium` or `low` for routine or
  latency-sensitive work once your evals show quality holds";
  Opus 5: "use `low` and `medium` liberally as your primary
  control for token cost and response time wherever your evals
  show quality holds"; Sonnet 5 medium: "Comparable to Claude
  Sonnet 4.6 at high effort"; max (Opus 4.7 table): "Reserve
  for frontier problems".
- D3 platform.claude.com/docs/en/about-claude/models/overview:
  "start with Claude Opus 5 for most workloads. Use Claude Fable
  5.1 for demanding reasoning and long-horizon agentic work, or
  when your evals on Claude Opus 5 at higher effort still fall
  short"; Haiku 4.5 effort: "Not supported" (so no haiku
  variant).
- D4 platform.claude.com/docs/en/about-claude/models/optimizing-for-cost-and-intelligence:
  SWE-bench Pro: "Claude Opus 5 at its default remains the
  cheaper way to the top score"; Opus 5 at `low` 84.0% for $0.25
  per solved task against Sonnet 5 at default 77.4% for $0.84;
  "Claude Opus 5 gave up about 2 points at `medium` for half the
  cost and about 8 points at `low` for a quarter of it"; `low`
  plus re-running failures at the default gave "the same pass
  rate for half the cost"; knowledge work: "`medium` matched the
  default's accuracy at about 70% to 87% of its cost, and the
  default bought nothing measurable over `medium`"; DeepResearch
  Bench II: Fable 5.1 "scored nearly the same at `low`,
  `medium`, and `high` while the cost per task rose".
- D5 platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-1:
  "At `medium`, results roughly match Claude Fable 5 at lower
  cost"; "At `low`, Claude Fable 5.1 is often competitive with
  Claude Opus and Claude Sonnet models on cost per task while
  scoring higher, so include it in the comparison wherever you'd
  otherwise run a smaller model at a higher effort level"; at
  `low` it "calls search and retrieval tools less often".
- D6 claude.com/blog/claude-model-and-effort-level-in-claude-code:
  routine edits and mechanical changes: Sonnet at default; code
  review and verification: Sonnet -> Opus at high; "for most
  tasks you should use the model's default effort level".
- D7 code.claude.com/docs/en/model-config#automatic-model-fallback:
  "Fable models and Opus 5 run with safety classifiers, which
  most often flag cybersecurity and biology content. When a
  classifier flags a request and the flagged category has a
  fallback model, Claude Code re-runs the request on that model
  and shows a notice in the transcript." Fable 5.1: cyber ->
  Opus 4.8, bio -> Opus 5. Opus 5: cyber -> Opus 4.8. Fable's
  classifier set is "a broader set than Claude Opus 5's
  cybersecurity-only classifiers" (Fable 5.1 migration guide).
  This is the ground for [security].never and its `reason`.

Recorded in policy.toml's comments at the time; moved here at
37.
