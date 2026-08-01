# Anthropic's Version 5 Claude Models: Cost & Coding/Agentic Benchmarks (as of August 1, 2026)

*Scope: the three publicly available v5 models — Sonnet 5, Opus 5, Fable 5.*

## TL;DR

- The available v5 lineup is three models: **Sonnet 5** (mid-tier, $3/$15 per MTok, intro $2/$10 to Aug 31), **Opus 5** (flagship daily driver, $5/$25), and **Fable 5** (top-end, generally available, $10/$50).
- On the cost/performance frontier for coding and agentic work, **Opus 5 at high or xhigh effort is the best value**: it beats Fable 5's AA-Briefcase score (1606 Elo at high effort for $10.41/task vs Fable 5's 1574 for $22.30) at under half the cost, and Anthropic prices it at half Fable's per-token rate while claiming near-Fable intelligence.
- The single biggest cost lever is the **effort/reasoning setting, not the model name**: Opus 5's output-token burn spans roughly 8x from low to max, and cost per AA-Briefcase task ranges from about $1.78 (low) to $17.79 (max). Anthropic's own data shows coding accuracy can peak at medium/xhigh and decline at max, so "max by default" often spends more for a worse result.

## Key Findings

1. **Three models, three price points.** Sonnet 5 (released June 30, 2026) and Opus 5 (July 24, 2026) are fully public. Fable 5 (June 9, 2026) is the top-end generally available model at double Opus 5's rate.

2. **API list pricing (per million tokens):** Sonnet 5 $3/$15 (intro $2/$10 through Aug 31, 2026); Opus 5 $5/$25; Fable 5 $10/$50. There is **no long-context (>200K) premium** on any Claude 4.6+ model including all v5 models — a 900K-token request bills at the same per-token rate as a 9K one.

3. **Effort setting dominates real cost.** All v5 models expose five effort levels (low, medium, high, xhigh, max) with high as the API default. Opus 5's cost per AA-Briefcase task spans about $1.78 (low) to $17.79 (max) — a 10x range within one model ID.

4. **Coding/agentic frontier:** Opus 5 leads SWE-bench Verified (96% Anthropic-reported; 97% on Vals AI) and Frontier-Bench v0.1 (43.3% at max, 44.4% at xhigh), Fable 5 leads SWE-bench Pro (80.3%), and GPT-5.6 Sol narrowly leads Terminal-Bench 2.1 (89.5% vs Opus 5's 89.1%). Opus 5 at high/xhigh effort is the strongest score-per-dollar option for most coding/agentic work.

5. **Fable 5's safeguard routing degrades its measured performance:** requests touching cybersecurity, biology, chemistry, or model distillation fall back to Opus 4.8, so Fable 5's published scores are only achievable in "unsafeguarded" domains. This affects both benchmark scores and effective cost — you can pay Fable rates for an Opus 4.8 answer.

## Details

### 1. API List Pricing Comparison

| Model | API ID | Input $/MTok | Output $/MTok | Cache read | Cache write | Batch (in/out) | Fast mode | Long-context premium |
|---|---|---|---|---|---|---|---|---|
| Claude Sonnet 5 | claude-sonnet-5 | $3 (intro $2 to Aug 31) | $15 (intro $10) | — | — | $1.50/$7.50 (intro $1/$5) | No | None |
| Claude Opus 5 | claude-opus-5 | $5 | $25 | $0.50 | $6.25 | $2.50/$12.50 | Yes ($10/$50, ~2.5x speed) | None |
| Claude Fable 5 | claude-fable-5 | $10 | $50 | $1 | $12.50 | $5/$25 | No | None |

Sources: Anthropic pricing docs (platform.claude.com), Anthropic Opus 5 launch post, Anthropic Fable 5 launch post, benchlm.ai model pages and API-pricing page.

**Notes:** Sonnet 5 uses a new tokenizer that Anthropic says produces ~30% more tokens for the same text vs Sonnet 4.6, so a flat per-million comparison against older models understates the real bill. US-only inference is available at 1.1x. Fable 5 carries mandatory 30-day data retention (Covered Model); Opus 5 and Sonnet 5 support zero data retention.

### 2. Effort Settings and Effective Cost Per Task

All v5 models expose five effort levels (low, medium, high, xhigh, max). High is the default on Opus 5 and Sonnet 5. On Opus 5, thinking can be disabled only at high effort or below; disabling at xhigh/max returns a 400 error. `max_tokens` covers both thinking and visible output.

**All measured model × effort combinations, AA-Briefcase (long-horizon agentic knowledge work), sorted by Elo (Artificial Analysis):**

| Rank | Model | Effort | AA-Briefcase Elo | Cost per task | Turns/task |
|---|---|---|---|---|---|
| 1 | Opus 5 | max | 1720 | $17.79 | 103 |
| 2 | Opus 5 | xhigh | 1693 | $14.26 | 91 |
| 3 | Opus 5 | high | 1606 | $10.41 | 76 |
| 4 | Fable 5 | max (w/ fallback) | 1574 | $22.30 | — |
| 5 | Opus 5 | medium | 1470 | not published | — |
| 6 | Sonnet 5 | max | 1386 | $14.43 | 183 |
| 7 | Opus 5 | low | 1223 | not published (≈$1.78 per eesel/AA chart) | — |

**Not measured / not published.** Artificial Analysis ran the full effort sweep only on Opus 5; Fable 5 and Sonnet 5 were reported at max effort only. The following eight combinations have no published AA-Briefcase Elo or cost figures and should not be interpolated from the Opus 5 curve — effort scaling is model-specific:

- Fable 5 at low, medium, high, xhigh
- Sonnet 5 at low, medium, high, xhigh

**Reading the table.** Three things stand out. Opus 5 at **high** (rank 3) outscores Fable 5 at **max** (rank 4) for less than half the cost — the single most important line in the report for API users. Sonnet 5 at max (rank 6) is beaten by Opus 5 at medium (rank 5) *and* costs more than Opus 5 at high, which is why raising Sonnet's effort is the wrong lever. And the top three rows are all one model: the effort dial moves Opus 5 across a 497-Elo range, wider than the gap between any two models at matched effort.

**Opus 5, Artificial Analysis Intelligence Index, cost per task by effort:** Per Artificial Analysis (verbatim): "Claude Opus 5 (max) costs $2.03 on average per Intelligence Index task, below Claude Fable 5 (with fallback) at $2.75, but still above Claude Opus 4.8 (max) at $1.80 and Claude Sonnet 5 (max) at $1.53." On short index-scale tasks, Sonnet 5 at max is cheaper per task; on long agentic tasks, Opus 5 at high wins. **Task length is the hinge.** Per-effort Intelligence-Index cost figures for low/medium/high/xhigh are not published in Artificial Analysis's own text (only the max value of $2.03 is confirmed).

**Token span:** Artificial Analysis states (verbatim) "On GDPval-AA v2, effort levels span 407 Elo points, with output token usage ranging around 8x from low to max effort." On GDPval-AA v2 Opus 5 takes the top two leaderboard spots at 1861 (max) and 1827 (xhigh) Elo, and "the xhigh setting beats every other model while using 25% fewer output tokens than max."

Anthropic reports coding accuracy on FrontierCode peaks at **medium** (53.4% main / 63.6% extended) and does not improve — sometimes declines — at higher effort, which Anthropic attributes to the model "making more changes than the task requires." On Zapier AutomationBench, per Anthropic's Opus 5 system card, Opus 5 "scored 26.0%, against 17.0% for Opus 4.8 and 17.4% for Fable 5. At medium effort it still scores 24% at $0.89 per task" — i.e., two points of score for roughly double the spend.

**Community rule of thumb:** run Sonnet 5 at low/medium; if that's not enough, switch to Opus 5 at high rather than turning Sonnet's dial up (Opus dominates the cost/quality frontier above medium). Do not run Sonnet 5 at max, and do not default Opus 5 to max.

### 3. Coding & Agentic Benchmarks (annotated with effort/config)

| Benchmark | Config | Opus 5 | Sonnet 5 | Fable 5 | Source |
|---|---|---|---|---|---|
| SWE-bench Verified | Anthropic-reported, adaptive/high | 96% | 85.2% | 95% | Anthropic system cards |
| SWE-bench Verified | Vals AI (independent) | 97.0% | — | 95.0% | vals.ai |
| SWE-bench Pro | Anthropic-reported | 79.2% | 63.2% | 80.0–80.3% | Anthropic system cards |
| Terminal-Bench 2.1 | max/xhigh | 89.1% (max) | 80.4% | 88.0% | Anthropic / tbench.ai / AA |
| Terminal-Bench 2.1 | Vals AI (independent) | 84.64% | 74.53% | 80.52% | vals.ai |
| OSWorld (computer use) | Anthropic | 70.6% (OSWorld 2.0) | 81.2% (Verified) | 85% (Verified) | Anthropic system cards |
| BrowseComp | single-agent | 90.8% | 84.7% | — | Anthropic system cards |
| FrontierCode 1.1 Main | medium/xhigh | 53.4% | 42.7% | 53.5% | Cognition / Anthropic |
| FrontierCode Diamond | medium | — | — | 29.3% | Anthropic / Cognition |
| Frontier-Bench v0.1 | max / xhigh | 43.3% / 44.4% | 17% | 33.7% | Anthropic Opus 5 card |
| ARC-AGI-2 | — | 90.4% | — | — | Anthropic Opus 5 card |
| ARC-AGI-3 | high | 30.2% | — | — | Anthropic Opus 5 card |
| CursorBench 3.2 | max | 70.0% | 61.5% | 70.5% | Cursor evals |
| GDPval-AA v2 (knowledge work) | max / xhigh | 1861 / 1827 Elo | 1607–1609 Elo | ~1747 Elo | Anthropic / AA |
| AA Intelligence Index | max | 61 | 53 | 60 | Artificial Analysis |

**Frontier-Bench vs Terminal-Bench, disambiguated:** On Frontier-Bench v0.1 (the 74-task successor to Terminal-Bench 2.1), Opus 5 leads. Per Anthropic's Opus 5 system card: "On FrontierBench v0.1... Opus 5 scored 43.3% at max effort. Opus 4.8 scored 18.7%. Fable 5 reached 33.7% and GPT-5.6 Sol reached 37.5%. At xhigh effort Opus 5 reaches 44.4% mean reward." GPT-5.6 Sol's lead is specifically on Terminal-Bench 2.1 itself (89.5% xhigh vs Opus 5's 89.1% max — essentially a tie).

**Notes on configuration and sample counts:** Anthropic's Frontier-Bench figures are mean reward over 5 attempts per task on the mini-SWE-agent harness, with Opus 4.8 serving as fallback on safety-classifier refusals. Fable 5's Terminal-Bench 2.1 and other scores were run with adaptive thinking at max effort, average of 5 trials, with Opus 4.8 fallback. On Vals AI's Terminal-Bench run, nine passing tasks across three runs were affected by Opus 4.8 fallback; counting them as failures drops Opus 5 from 84.64% to 81.27%. SWE-bench Pro's 80.3% Fable 5 figure was produced on Anthropic's own scaffolding and is contested by independent aggregators; Vals AI independently confirms Fable 5 at 95.0% on SWE-bench Verified.

**BenchLM aggregate ("BenchAlign") snapshot (July 31, 2026):** Opus 5 at 82.79, Fable 5 at 82.73, GPT-5.6 Sol at 81.36. Sonnet 5 ranks #29–33 at ~65. BenchLM category ranks: Opus 5 is #3 agentic / #4 coding / #1 knowledge; Fable 5 is #2 coding / #7 agentic; Sonnet 5 is #9 coding / #15 agentic. Treat BenchLM's composite as directional — its methodology and weighting are not documented in detail.

### 4. Subscription Tiers and Model Access

| Plan | Price | v5 model access |
|---|---|---|
| Free | $0 | Sonnet 5 (default) |
| Pro | $20/mo ($17 annual) | Sonnet 5 + Opus 5 (Opus is strongest model on Pro; Fable 5 only via pay-as-you-go usage credits since July 20) |
| Max 5x | $100/mo | Opus 5 (default) + Fable 5 included up to 50% of weekly limits |
| Max 20x | $200/mo | Opus 5 (default) + Fable 5 included up to 50% of weekly limits |
| Team | $25–$125/seat/mo | Premium seats get Fable 5 included (50% of weekly limits); standard seats use credits |
| Enterprise | $20+/seat + usage | Premium seats get Fable 5 included; standard seats need credits enabled |

Availability spans Claude.ai, Claude Code, Claude Cowork, and the Claude Platform API. Since July 20, 2026, the Fable 5 access split is permanent: included on Max/premium-Team/premium-Enterprise seats (up to 50% weekly), pay-as-you-go usage credits elsewhere. Opus 5 is the included model on Pro at no extra usage cost.

**Context note:** on the chat interface, Opus runs at ~200K context and only reaches 1M inside Claude Code; Sonnet 5 gets the full 1M in chat. Usage limits reset on a rolling five-hour session window, with weekly caps on top; activity across web, desktop, mobile, and Claude Code all draws from the same pool.

### 5. Fable 5 Access History & Safeguard Routing

- **June 9, 2026:** Fable 5 launched, generally available at $10/$50.
- **June 12, 2026:** US Dept. of Commerce issued an export-control directive (received 5:21pm ET) suspending access for all foreign nationals; Anthropic disabled the model for all users. Per Anthropic's "Redeploying Claude Fable 5" post, the directive "came after the government became aware of a report in which Amazon researchers had found a method of bypassing Fable 5's safeguards: prompting it so that it identified a number of software vulnerabilities. In one case, the model produced code demonstrating how the relevant vulnerability could be exploited."
- **June 30, 2026:** Export controls lifted.
- **July 1, 2026:** Fable 5 restored globally on Claude Platform, Claude.ai, Claude Code, Claude Cowork.
- **July 7 → July 12 → July 19, 2026:** Fable 5 free-inclusion window on paid plans extended twice (partly a competitive response to OpenAI's GPT-5.6 Sol launch).
- **July 20, 2026:** Permanent split — Fable 5 included on Max/premium seats, credits elsewhere.

**Safeguard routing:** Fable 5 includes safety classifiers that block cybersecurity, biology, chemistry, and distillation requests, rerouting them to Opus 4.8 (in Claude clients; the Messages API blocks by default unless fallback is configured). There are two different figures for how often this fires, and they should not be conflated: Anthropic's June launch materials estimated fallbacks affect "fewer than 5%" of Fable 5 sessions, while the Opus 5 system card (via MarkTechPost) reports "Fable 5 classifiers flagged 42% of calls across 26% of trials" in that specific evaluation set — reflecting how heavily the measured rate depends on the workload mix. For comparison, the same system card reports "Opus 5 safety classifiers flagged and refused 5% of API calls, across 4% of trials," and Anthropic states Opus 5's classifiers "are expected to intervene around 85% less often than on Fable 5."

Either way, Fable 5's published benchmark scores are only achievable in unsafeguarded domains, and users may pay Fable 5 rates ($10/$50) for what is actually an Opus 4.8 response on flagged queries.

### 6. Max 20x Plan: Session Routing Policy

On Max 20x ($200/mo) the cost analysis above largely does not apply. You are not paying per token, so the "score per dollar" frontier is not the binding constraint. **The currency is limit burn**: output tokens consumed against a rolling five-hour session window with a weekly cap on top, pooled across web, desktop, mobile, and Claude Code.

This inverts two of the report's conclusions:

- **Fable 5's 2x token premium costs you nothing** up to 50% of weekly limits. The report's advice to reserve it for absolute-ceiling work was a dollar argument; on Max it becomes a *budget* argument — spend the Fable allocation on your hardest work, not on routine tasks.
- **Opus 5 at high effort is still the right default**, but for a different reason. Max effort burns roughly 70% more output tokens than high (AA-Briefcase: $17.79 vs $10.41 at API rates, which maps proportionally to quota) for a 114-Elo gain, and on FrontierCode-type coding work Anthropic's own data shows accuracy *plateaus or declines* above medium/xhigh. You are paying quota for a worse result.

**Effective model budget on Max 20x:**

| Tier | Model | Effort | Use for |
|---|---|---|---|
| Ceiling | Fable 5 | max | Hardest debugging, novel architecture, tasks that failed at Opus 5 xhigh. Capped at 50% of weekly limits. |
| Default | Opus 5 | high | Nearly all coding and agentic work. Escalate to xhigh before max. |
| Bulk | Sonnet 5 | low–medium | Boilerplate, refactors, test generation, file edits with clear specs. |

**Escalation ladder — one step at a time, never jump to max:**

`Sonnet 5 medium → Opus 5 high → Opus 5 xhigh → Fable 5 max`

Switch *models* rather than raising Sonnet's dial. Opus 5 dominates the quality frontier above Sonnet's medium setting, so Sonnet 5 at high or max is wasted quota in almost every case. Sonnet 5 at max also took 183 turns per AA-Briefcase task — the most of any model measured — meaning the "cheap" model burns the most quota on long-horizon work.

**Two constraints that persist regardless of plan:**

- **Fable 5 safeguard fallback.** Requests touching cybersecurity, biology, chemistry, or model distillation reroute to Opus 4.8. On security work you will silently get a weaker model than Opus 5. Route security-adjacent tasks to Opus 5 directly rather than Fable 5.
- **Context ceiling by surface.** Opus runs at ~200K context in the chat interface and only reaches 1M inside Claude Code. For large-repo work, stay in Claude Code.

## Recommendations (pay-per-token API use)

*Superseded by Section 6 for Max plan subscribers.*

1. **Default coding/agentic stack: Opus 5 at high effort.** It sits on the cost/performance frontier — beating Fable 5 on AA-Briefcase (1606 Elo/$10.41 vs 1574/$22.30) at under half the cost, and beating Sonnet 5 max on both score and cost for long tasks. If a task fails at Opus 5 high, escalate to xhigh before max (max often costs more for equal or worse results — see FrontierCode/AutomationBench where quality plateaus or dips above medium/xhigh).

2. **For high-volume, short, well-specified work: Sonnet 5 at low/medium.** On short index-scale tasks Sonnet 5 max is cheapest per task ($1.53), but never run Sonnet 5 at max on long tasks — switch to Opus 5 instead. Threshold: if you're reaching for Sonnet 5 high or above, switch models rather than raising the dial.

3. **Reserve Fable 5 for absolute-ceiling, unsafeguarded work** where a missed edge case costs more than the ~2x token premium — and only after accepting its 30-day data retention and Opus 4.8 fallback behavior. If your work touches cyber/bio/chem, expect fallbacks that erode both performance and value. A common production pattern is Opus 5 (high) to plan and Sonnet 5 (medium) to implement.

4. **Plan choice:** Pro ($20) for individuals wanting Opus 5; Max 5x ($100) when you hit Pro limits weekly and want Fable 5 included (up to 50% of weekly usage); Max 20x ($200) for near-continuous Claude Code use.

5. **Run an effort sweep on your own evals whenever you switch models.** Opus 5 respects effort levels differently from earlier Opus models, and Anthropic's guidance flipped from "start at xhigh" (4.x era) to "start at high and reach down." Your workload's optimum will not necessarily match the benchmark optimum.

## Caveats

- **Verification status is uneven.** Pricing and plan tiers come from Anthropic's own pages and are easy to re-check. Benchmark figures attributed to Anthropic system cards are self-reported on Anthropic's own scaffolding — real publications, but not independent measurements. Vals AI and Artificial Analysis are the independent sources and should carry the most weight. BenchLM's composite scores are directional only.
- **Benchmark harness disagreements are large.** Vals AI and Anthropic differ by ~4.5 points on Terminal-Bench for the same model. Terminal-Bench versions (2.0 vs 2.1) are not directly comparable. SWE-bench Pro's Fable 5 figure is specifically contested.
- **Per-effort cost data is incomplete.** Artificial Analysis publishes AA-Briefcase cost per task only for Opus 5 high/xhigh/max; medium and low costs are not published. Per-effort GDPval-AA v2 Elo values below max/xhigh, and per-effort Intelligence-Index costs below max, live only in chart images or third-party recaps and are not confirmable from Artificial Analysis's own text.
- **Opus 5 hallucination rate rose.** Artificial Analysis measured a ~50% hallucination rate on AA-Omniscience (up 14 points vs Opus 4.8) — it answers more often when uncertain. Relevant for factual/support workloads.
- **Sonnet 5 intro pricing expires Aug 31, 2026** ($2/$10 → $3/$15). Any cost model built on today's Sonnet rate has roughly five weeks left.
- **Figures marked "not published" should not be inferred.** Several per-effort datapoints are genuinely unavailable and are flagged as such rather than estimated.
