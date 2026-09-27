# policy changelog

Version history of `policy.toml`, newest first. Each heading is the
`[policy].version` the entry describes.

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
the seats share a model. The row comment names the metric that
judges the move (sole-finder clusters, never match rates) and
docket-retro's evidence table reads it. No other routing value
changed; [security] never/ceiling/labels/nodes are byte-identical.

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
