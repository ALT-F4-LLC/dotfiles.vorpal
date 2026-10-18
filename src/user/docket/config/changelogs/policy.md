# policy changelog

Version history of `policy.toml`, newest first. Each heading is the
`[policy].version` the entry describes.

## 43

`[security].reason` states the current behavior only: it drops the
version-32 comparison and the "no longer" and "residual unchanged"
phrasing. No row, variant, `never`, `ceiling`, `labels`, `nodes`, or
`[escalation]` change.

## 42

Nine executor rows move; `[security].reason` is rewritten and dated
to this version. `[variants]`, `[security]` never/ceiling/labels/
nodes, and `[escalation]` are byte-identical to version 41.

Sources, fetched 2026-10-13:

- O1 Introducing Claude Opus 5.5, September 22, 2026
  (https://www.anthropic.com/claude-opus-5-5).
- S1 Introducing Claude Sonnet 5.5, September 28, 2026
  (https://www.anthropic.com/claude-sonnet-5-5).
- F1 Introducing Claude Fable 5.1 and Claude Mythos 5.1, September
  2026 (https://www.anthropic.com/claude-fable-and-mythos-5-1).
- H2 Introducing Claude Haiku 5.5, October 7, 2026
  (https://www.anthropic.com/claude-haiku-5-5).

Fable rows to Opus. O1: Opus 5.5 "performs at the level of Claude
Fable 5.1 on most work and costs 40% less to run than Opus 5", and its
benchmark table leads Fable 5.1 on every row it reports (Terminal-Bench
4.0 66.4 vs 55.8, FrontierCode 54.4 vs 50.3, CursorBench 4.0 57.8 vs
51.8, GDPval-AA v2.1 1846 vs 1735, Terminal-Bench-Science 58.7 vs
52.6, HLE 67.7 vs 65.6, OSWorld 2.1 81.8 vs 80.7). Price per million
tokens, input / output: Opus 5.5 $4 / $20, Fable 5.1 $10 / $50 (F1).
Every moved row keeps its one-hop path back to Fable through
`opus-high`'s `escalate_to = fable-high`, and `[escalation].fable_gates`
(`investigator-class`, `novel-architecture`) still names the cases
where Fable's edge is claimed.

- research `fable-high` -> `opus-high`. O1: in the verified-figures
  report test, "16 out of 18 of Opus 5.5's reports cleared our quality
  bar, where any invented figure or quote would have failed. Neither
  Fable 5.1 nor Opus 5 cleared that bar in any attempt." The contract's
  whole discipline is `quoted` against `summary-derived`. `high` because
  the step is agentic acquisition plus verification.
- report `fable-high` -> `opus-medium`. The contract is synthesis-only
  and read-only: no new research, reproduction, or probes. O1: Opus 5.5
  "puts the most important information up front" and "follows the
  writing rules you give it". `medium` is the Opus API default and the
  step emits one document from supplied inputs.
- investigate `fable-high` -> `opus-high`. O1: Terminal-Bench-Science
  58.7 vs 52.6. F1's investigation evidence for Fable 5.1 (Millennium
  crash, Datadog incident RCA, Red Hat broken builds) is measured
  against Opus 5, not Opus 5.5. revise-investigation stays on
  `fable-high`: it runs only after a report-vote rejection, so the
  revision now climbs a model tier as well as re-reading the votes.
- prd-author, adr-author, tdd-author, ux-spec-author `fable-high` ->
  `opus-high`. Document authoring. O1: GDPval-AA v2.1 1846 vs Fable
  5.1's 1735; Ramp: "A design spec came out usable with very minimal
  edits." F1's authoring praise for Fable 5.1 (Canva, Hebbia) is
  against Fable 5. Novel ideation, Fable's claimed edge in F1 (IMC,
  Rakuten), is what the `novel-architecture` gate escalates for.

tribunal-design `fable-high` -> `sonnet-high`. A voter-only seat on
the spec-doc panels beside tribunal-architecture and
tribunal-security, both Opus; the version-32 decorrelation argument
applies, so this panel now mixes families as the review fanouts do
through judge-testing. S1: Sonnet 5.5 has "a sharp eye for design"
and "adds polish to user interfaces". `high` is the Sonnet API
default. Price per million tokens, input / output: Sonnet 5.5
$2 / $10 against Fable 5.1's $10 / $50.

judge-architecture `opus-medium` -> `opus-low`, an experiment in
review effort, measured and not tuned. The one code-review-by-effort
datapoint published: O1, Deloitte: "Even at its lowest effort setting,
Claude Opus 5.5 caught 72% of known bugs in our code reviews to Opus
5's 56% at high effort, with fewer false alarms and a fraction of the
output." Version 40 already lands `opus-low`'s retry on `opus-medium`,
in family. This seat rather than judge-correctness: it runs on the
standard-change, ui-change, and security-change fanouts, so it is
measurable, and it is not the sole correctness line. Retro: sole-finder
clusters per reconciled round traced to this seat's review step,
findings per review, and fanout median, never match rates; partition
by the step row's `model_requested` so a reap re-run that walked onto
`opus-medium` is read apart. Baselines are this seat's `opus-medium`
rows under versions 38 through 41.

`[security].reason` rewritten. The version-32 wording held that
Fable's classifiers reroute flagged requests while Opus's cyber-only
set does not, so naming Opus avoids the hop. O1: Opus 5.5 "is the
first Opus model to launch with a similar class of safeguards to Fable
5.1 on cybersecurity, biology, and distillation, all of which fall
back to another model transparently" (cyber -> Opus 4.8, biology ->
Opus 5). The hop is now identical on both models; `never = ["fable"]`
stands on price alone. The rewrite also narrows the hop (O1 and F1:
vulnerability discovery in source code is allowed on both; binaries,
penetration testing, and exploit development are blocked) and records
why Sonnet and Haiku stay off these nodes: S1, Sonnet 5.5's cyber
fallback is Sonnet 5 (Terminal-Bench 4.0 10.3%); H2, Haiku 5.5 has no
fallback model.

Rows that stay, and why. implement, fix, dispose at `opus-medium`:
O1, "Opus 5.5 at default effort beats Opus 5 at max effort for about
a fifth of the cost" on Terminal-Bench 4.0, and Factory: "the first
model we'd default to at medium effort". judge-correctness,
judge-simplicity, judge-design, verify-ac, design-qa at `opus-medium`:
version 41's Haiku 5.5 System Card reading that Opus 5.5 is strictly
best on input hallucination, important omissions, and false completion
claims still governs the honesty-critical seats. judge-testing at
`sonnet-high`: stays, and the version-32 confound is gone; S1 puts
Sonnet 5.5 at 70.6% on Terminal-Bench 4.0 against Sonnet 5's 10.3%,
so a yield change in this seat can no longer be attributed to Sonnet's
chat-tier placement (D2). synthesize-findings and drain-highs: per
version 41.

Corrections to version 41's price line: Sonnet 5.5 cache reads are
$0.10 per million tokens since October 7 (H2), halved from $0.20.
`ceiling = "opus-max"` is unchanged, with the note that Opus 5.5's own
top Terminal-Bench 4.0 score is reported at `xhigh` (O1), so `max`
buys the highest cost, not a guaranteed highest score.

Store audit, 2026-10-13, against `~/.docket/issues.db` (144 runs,
2026-08-12 to 2026-10-13; window below is 2026-09-13 to 2026-10-13
unless stated). `model_resolved` and `effort_resolved` are `unknown` on
every step row since 2026-09-05 (populated on 2,738 rows before that
date; the boundary is the day step metadata began carrying `variant`),
so dollar figures are estimates at list price for `model_requested`.
This is a regression to fix in the engine, not a design limit, and the
`[security].reason` residual falls with it.

- Token mix, all executors, window: 6.58B cache-read, 379M
  cache-write, 9.7M output, 0.2M input tokens; at Opus rates about
  55% of spend is cache writes, 38% cache reads, 6% output. Effort
  moves output tokens only, so no effort change on this version can
  move more than about 6% of spend. A median implement step at
  `opus-medium` writes 293k tokens of cache, reads 4.0M, and emits
  3.0k output; its packet (contract plus fragments) is 58k bytes
  and its gate output a median 2k bytes per step, so the cache
  volume is in-step exploration the store does not record. The one
  store-visible tail is the `tests` gate at p90 156k bytes of output
  (n=641).
- Spend by seat, window, est. $3,071: implement `opus-medium`
  $1,167 (38%, 385 steps), judge-correctness `opus-medium` $342
  (11%), verify-ac `opus-medium` $245 (8%), judge-architecture
  `opus-medium` $196 (6%), judge-testing `sonnet-high` $183 (6%).
  Every Fable row combined: $53 (1.7%), 38 steps all-time. The
  version-42 Fable moves are supported but small.
- Review panel, 355 reconciled rounds with `member_sources`: 12% of
  clusters have more than one seat, so the panel is not paying for
  correlated findings and sole-finder counts are effectively
  findings per seat. Sole high/blocker per seat: judge-testing
  `sonnet-high` 0.32 (345 seats, $1.9 per sole high),
  judge-testing `sonnet-low` 0.37 (107, $1.1), judge-architecture
  `opus-medium` 0.09 (352, $7.1), judge-architecture `opus-low` 0.13
  (107, $4.2), judge-correctness `opus-medium` 0.09 (452, $7.9),
  judge-security `opus-medium` 0.06 (141, $14.6). Lenses carry
  different severity ladders, so cross-seat ratios are indicative;
  within-seat effort comparisons show no yield loss at low.
- Write seats: implement at `opus-medium` was followed by a fix
  round in 7% of 378 steps; at `opus-low`, 20% of 113. implement
  and fix stay at `medium` on this evidence. fix@1 needed another
  round in 25% (`opus-medium`, 28) and 29% (`opus-low`, 21) of
  cases; fix@2 on `opus-high` needed a third in 0 of 13, but
  `max_fix_loops = 2` caps the loop there, so that zero measures the
  cap, not the hop. `on_round = "one-hop"` stays unmeasured.
- Reaps: at or under 1% on every row except threat-model (5 of
  142) and design-qa (2 of 9). No `fable_gates` entry has fired in
  the event log. Votes: 478 in the window, 10 rejections.

Transcript audit, 2026-10-13, against the Claude Code transcripts the
store's steps ran in (`~/.claude/projects/**`, 14,066 files, all from
2026-10-06 onward; earlier transcripts are no longer on disk). Joined
to step rows by exact cache-token totals (1,373 steps) and, for
worktree steps, by time window and cwd (325 implement steps in all).

- Served model equals requested model on every joined step: 905
  `opus-medium` -> claude-opus-5-5, 436 `sonnet-high` ->
  claude-sonnet-5-5, 28 `haiku-high` -> claude-haiku-5-5, 2
  `fable-high` -> claude-fable-5-1. No transcript shows a step served
  by more than one model, so no safeguard fallback hop occurred in the
  window, on the security track or elsewhere. The `model_resolved`
  back-fill can take the served id from the transcript's assistant
  messages, which carry it.
- The ledger's cache-read and cache-write totals match the step's
  transcript exactly on the joined steps; output differs by the
  message-id dedupe (ledger 1.25x transcript on implement), which is
  why most steps did not match on all three units.
- Where the spend goes: on implement, cache writes are not new context.
  Tool results, thinking and text across 325 implement transcripts
  sum to about a tenth of the 124M cache-write tokens. In a 60-step
  sample, 66% of cache-write tokens fall on 117 turns (4% of turns)
  that follow a 5-15 minute pause, where the write is ~100k tokens
  instead of the ~2k of an ordinary turn: the prompt cache has
  expired while the step waited, and the whole context is written
  again. The pauses are test gates and gate-bearing `docket step
  record` runs (`scripts/qa/tests.sh`, `just tests`, `make qa-test`,
  `tail -f` on a gate log). implement averages 1.74 such rewrites per
  step, judge-testing 0.59, fix 0.60; every other seat is at or near
  zero. At Opus rates a rewrite is roughly $0.50; across the window's
  implement and judge-testing volume this is on the order of $500 a
  month, about 16% of spend, and larger than any routing or effort
  change available in this file.
- The ledger covers executor steps only. In the same eight days the
  conductor sessions that drive the waves (29 top-level sessions using
  the Workflow tool, all Opus 5.5) consumed an estimated $1,176, 56% of
  the $2,083 the ledger records for steps; two sessions started
  2026-10-09 account for $913 of it. The ~10,000 two-turn Haiku 5.5
  helper transcripts (Bash + StructuredOutput) cost $38 in total.

Remedy for the rewrite cost belongs in the contracts, not here: a rule
in `completion-gates` (or `rerun-discipline`) that a command expected
to run longer than four minutes runs in the background and is polled
on a short interval, so no turn gap exceeds the cache's idle window;
and shorter test gates. Routed as a docket issue.

Revert criteria for this version, read at the next retro:

- judge-architecture `opus-low`: revert to `opus-medium` if, over
  at least 100 seats, sole high/blocker per seat falls below 0.06 or
  sole clusters of any severity per seat fall below 0.60 (baselines
  0.09 and 0.87 at `opus-medium`; the 107 historical `opus-low`
  seats sit at 0.13 and 0.64).
- research, investigate, report, prd-author, adr-author,
  tdd-author, ux-spec-author on Opus: vote rejections are too rare
  to carry a rule. Take the `gap` artifact rate per step on these
  rows from their first 20 Opus runs as baseline; revert a row if a
  Fable `revise-investigation` materially changes the conclusion of
  an Opus report twice, or if `failed-top-opus-round` fires on it.

Known limit: the engine routes by executor row, so implement and fix
on trivial-change and docs-only run at `opus-medium` like every other
track. Measured: small-change plus docs-only spent $272 on
implement and fix in the window (trivial-change did not run); a
Sonnet 5.5 seat there would save roughly $135 a month, about 4% of
spend. Not worth an `implement-light` row and contract stem at that
size; revisit if the light tracks' share grows.

## 41

`haiku-high` joins `[variants]`, escalating to `sonnet-high`, and
drain-highs moves `sonnet-high` -> `haiku-high`. No other row changes;
`[security]` and `[escalation]` are byte-identical.

Sources, fetched 2026-10-11:

- H1 Claude Haiku 5.5 System Card, October 7, 2026
  (https://www.anthropic.com/document/claude-haiku-5-5-system-card).
- H2 Introducing Claude Haiku 5.5
  (https://www.anthropic.com/claude-haiku-5-5).

Why drain-highs: its contract says "Select mechanically" on one
field of a schema-bound artifact and forbids re-grading, merging, or
dropping clusters. H2 calls Haiku 5.5 "best suited to more narrowly
scoped tasks". `high` rather than the `medium` default because lower
effort skips checks in long agent prompts, and the step's whole value
is complete coverage. The seat is measured by clusters at `high` or
`blocker` left without a backlog home, read from the round's findings
artifact against the drain-report.

Why nothing else moved. H1 6.2.3: Opus 5.5 and Sonnet 5.5 "were all
strictly better on input hallucination, important omissions, and false
completion claims", and H1 6.3.2 measures a self-preference bias as a
grader larger than Opus 5.5's, so every judge-*, tribunal-*, verify-ac,
design-qa, and synthesize-findings seat stays. H1 8.4: Terminal-Bench
4.0 at 39.2% against Sonnet 5.5's 70.6% and Opus 5.5's 66.4%, and H2:
Sonnet 5.5 and Opus 5.5 "remain better choices for complex agentic
coding", so implement, fix, dispose, and every author and investigator
seat stays.

A Haiku seat has no fallback model (H1 1.5: "blocks on these safeguards
will not fall back to any other models"), so a classifier stop is
never a silent reroute and the `[security].reason` residual does not
apply to this row. The cost moves to latency: wave.js cannot read a
classifier stop, so the step stays unrecorded until its lease is
reaped, and the re-run's variant is the engine's to resolve from
`escalate_to`. H1 8.4 measured such stops in 1.8% of Terminal-Bench
4.0 trials, 10 of the 12 on one task.

Price per million tokens, input / output: Haiku 5.5 $0.10 / $0.50 for
a prompt up to 100,000 tokens and $0.50 / $2.50 above it; Sonnet 5.5
$2 / $10.

## 40

`opus-low` escalates to `opus-medium` instead of `opus-high`, so every
`*-low` variant and every fallback hop steps one tier. No executor row
names `opus-low`, so no current routing changes. `[security].reason` now
dates its Opus 5 and Opus 4.8 claims to policy version 32, when the reason
was written; re-check them when the runtime's fallback changes. The
`opus-xhigh` row loses a stray space before `=`.

## 39

`sonnet-max` and `sonnet-xhigh` leave `[variants]`. Under version
38 no executor row, `escalate_to` edge, `[escalation.fallback]`
value, size, or ceiling reached either one, and the engine looks
a variant up only when one of those names it. The `sonnet-xhigh`
hops seen on fix rounds across 108 runs in 11 projects ran under
older pinned policies. `fable-low` and its fallback stay. Every
executor row stays: the spec-doc authors, research, and
tribunal-design run only for their labels, and the spec-author
seats belong to spec-project, which has not yet run.

## 38

every executor row now starts at its model's API default effort,
as documented for Claude Managed Agents
(https://platform.claude.com/docs/en/managed-agents/overview):
opus rows at `opus-medium`, sonnet rows at `sonnet-high`, and
fable rows at `fable-high`. Rows already at `opus-medium`
(judge-correctness, judge-simplicity, tribunal-correctness,
verify-ac) are unchanged. Every `never` exclusion, `[variants]`
escalation target, and `[escalation]` value is unchanged.

## 32

judge-testing moves opus-low -> sonnet-low as the corpus's
one second-family review seat: a retro-measured experiment in
panel decorrelation, not a tuning. Every other judge-* and
tribunal-* seat but tribunal-design stands on Opus, so a panel's
seats differ by lens and effort, never by model family, and
seats sharing a model share its blind spots: "seat X matched the
panel N of N" then measures conformity, not independent
detection, and is not evidence for or against any seat. The
metric that judges the move is sole-finder clusters, never match
rates; docket-retro's evidence table reads the baseline recorded
below. No other routing value changed; [security]
never/ceiling/labels/nodes are byte-identical.

judge-testing was chosen because it carries the most sole-finder
highs of any review seat (clusters no other seat raised: 154 high / 3 blocker across 187 reconciled
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

## 21

model/effort re-derived from Anthropic's official documentation
(fetched 2026-09-02), fit to each seat's role, cost-aware. Entry
32 cites this source as D2:

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
