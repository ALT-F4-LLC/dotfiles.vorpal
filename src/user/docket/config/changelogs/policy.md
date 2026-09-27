# policy changelog

Version history of `policy.toml`, newest first. Each heading is the
`[policy].version` the entry describes.

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
