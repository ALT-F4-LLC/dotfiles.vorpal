# Anthropic's Official Benchmarks for the Claude 5 Family (Sonnet 5, Opus 5, Fable 5)

All three Claude 5 models genuinely exist and each has first-party Anthropic benchmarks, but they are published in three different formats — a full numeric table for Fable/Mythos 5, a summary table for Sonnet 5, and mostly ratios-plus-cost-curves for Opus 5 — so the single most important finding is that a like-for-like, per-effort-level comparison across all three is only partially possible from Anthropic's own sources, and the honest chart below shows explicit gaps where Anthropic did not publish a number.

## TL;DR
- **Three Claude 5 models exist and all have official benchmarks:** Claude Fable 5 / Mythos 5 (announced June 9, 2026), Claude Sonnet 5 (June 30, 2026), and Claude Opus 5 (July 24, 2026). Fable 5 and Mythos 5 are the *same* "Mythos-class" weights — Fable is the safeguarded, generally-available configuration; Mythos is the restricted, safeguards-lifted configuration (Project Glasswing). There is no separate "Claude 5" beyond these; the family also sits above the still-current Opus 4.8, Sonnet 4.6, and Haiku 4.5 (which are 4.x and excluded here per scope).
- **Anthropic's headline configuration is "max effort" (adaptive thinking, default sampling, 5-trial average)** on an effort ladder of **low / medium / high / xhigh / max**. Default effort is `high` on the API/Claude Code for Opus 5 and Sonnet 5; Fable/Mythos 5 have adaptive thinking permanently on. Only a handful of benchmarks are broken out by effort level; most are single max-effort numbers or cost-performance curves.
- **Coverage differs sharply by model.** Fable/Mythos 5 and Sonnet 5 have detailed numeric tables; **Opus 5's launch presented most results as ratios ("more than doubles Opus 4.8," "three times the next-best model") and cost-performance charts rather than printed absolute numbers**, so several Opus 5 cells are genuine gaps in Anthropic's own text (third parties later read approximate values off the charts).

## Key Findings
1. **Fable 5 = Mythos 5 weights.** Anthropic's shared benchmark table shows the higher of the two values per row (usually Mythos, safeguards off) and footnotes where Fable's safety-refusal fallback to Opus 4.8 lowers its score. On Terminal-Bench, 20.9% of Fable trials hit a safety refusal and fell back to Opus 4.8 mid-trajectory, which is why Fable (84.3%) trails Mythos (88.0%) despite identical weights.
2. **GPQA Diamond and AIME are effectively retired.** Anthropic reports GPQA Diamond at 94.1% for Mythos 5 but describes it (and AIME) as saturated and no longer reports them for Sonnet 5 or Opus 5; the family is now benchmarked mostly on long-horizon agentic evaluations (SWE-bench Pro, Terminal-Bench 2.1, Frontier-Bench, OSWorld, GDPval-AA, BrowseComp).
3. **Sonnet 5's headline coding number is SWE-bench *Pro* 63.2%, not SWE-bench Verified.** Per Emergent's breakdown of Anthropic's June 30, 2026 announcement and System Card, "Sonnet 5's 63.2% is a five-point gain over Sonnet 4.6's 58.1%, bringing it within striking distance of Opus 4.8's 69.2%." Anthropic did **not** publish a SWE-bench Verified figure for Sonnet 5 in its announcement or summary table; circulating third-party numbers conflict badly — Cosmic (cosmicjs.com) reports "72.7% (Sonnet 4.6: 62.3% / Opus 4.8: 79.4%)" while a DEV Community post claims "92.4% on SWE-bench Verified" — and none can be confirmed against a primary Anthropic source, so this cell is left as "not published."
4. **Opus 5 is near-Fable-5 intelligence at half the price ($5/$25 vs $10/$50), sold largely in relative terms.** Per TechCrunch/The Next Web coverage of the July 24 launch, "On Frontier-Bench…Opus 5 more than doubles its predecessor's score and surpasses every competing model, including Fable 5." Third parties reading Anthropic's charts put the absolutes at Frontier-Bench v0.1 43.3% at max / 44.4% at xhigh, ARC-AGI-3 30.2%, GDPval-AA v2 ~1861 Elo, OSWorld 2.0 ~70.6%.

## The Static Comparison Chart

**How to read this:** Columns are model × effort configuration. Anthropic's default published configuration is **adaptive thinking at max effort, default sampling, 5-trial average** unless noted. **"—" = Anthropic did not publish a value at that configuration** (no estimation, no third-party substitution in these cells). "(chart)" = the value does not appear as printed text in Anthropic's release but is read from an Anthropic cost-performance chart; treat as approximate. Fable 5 and Mythos 5 share weights — where one value is shown for the pair, it is the higher (usually Mythos). **GDPval-AA is an Elo score, not a percentage,** and comes in two incompatible versions (see notes). All competitor comparisons in Anthropic's tables are drawn from other vendors' own cards, not re-run by Anthropic.

| Benchmark (version) | Fable 5 (max) | Fable 5 effort curve (low→xhigh) | Mythos 5 (max, safeguards off) | Opus 5 (max) | Opus 5 (xhigh) | Sonnet 5 (max) |
|---|---|---|---|---|---|---|
| SWE-bench Verified | 95.0% | — | 95.5% | 96.0% (chart) | — | not published |
| SWE-bench Pro | 80.0% | 75.0 → 80.4% | 80.3% | 79.2% (chart) | — | 63.2% |
| Terminal-Bench 2.1 | 84.3% | — | 88.0% | — | — | 80.4% |
| FrontierCode (Diamond) | 29.3% | 11.5 → 30.9% | 29.3% | — | — | — |
| FrontierCode (Main / v1) | 46.3% | — | — | — | — | 38.8% (v1) |
| Frontier-Bench v0.1 | 33.7% (chart) | — | — | 43.3% (chart) | 44.4% (chart) | — |
| CursorBench 3.2 (Cursor-run) | 72.9% (max) | — | — | within 0.5% of Fable, half cost | leads at fixed cost | ~57% |
| GPQA Diamond (retired/saturated) | 94.1% | — | 94.1% | — | — | not reported |
| Humanity's Last Exam (no tools) | 59.0% | — | 59.0% | — | — | 43.2% |
| Humanity's Last Exam (with tools) | 64.5% | — | 64.7%* | reported (ratio only) | — | 57.4% |
| GDPval-AA (v1, Elo) | 1932 | — | 1932 | — | — | — |
| GDPval-AA v2 (Elo) | 1783 | — | 1783 | ~1861 (chart) | — | 1618 |
| GDP.pdf (vision, no tools) | 29.8% | — | 29.8% | — | — | — |
| OSWorld-Verified / OSWorld 2.0 | 85.0% (Verified) | — | 85.0% | ~70.6% (OSWorld 2.0, chart) | — | 81.2% (Verified) |
| BrowseComp | — | — | — | — | — | 84.7% single / 86.6% multi |
| Blueprint-Bench 2 (spatial) | 38.6% | — | 38.6% | — | — | — |
| ARC-AGI 3 | — | — | — | 30.2% (chart) | 30.2% (high effort) | — |
| Zapier AutomationBench | 17.4% | — | 17.4% | ~26% (chart) | — | 13.5% |
| Legal Agent Benchmark | 13.3% | — | 13.3% | — | — | 8.9% public / 5.8% held-out |
| HealthBench Professional | 66.0%* | — | 66.0% | — | — | 57.8% |
| DeepSearchQA | — | — | — | reported (ratio/chart) | — | — |
| ExploitBench (cyber) | ≈ Opus 4.8 (safeguarded) | — | 78.0% | behind Mythos 5 (see OSS-Fuzz) | — | ~0% working exploit |

\* Starred Fable-column values are effectively Mythos-class numbers (cyber/bio/health-adjacent rows) that the safeguarded public Fable 5 will not reach when a classifier fires. HLE "with tools" 64.7% is Mythos Preview's figure, which Anthropic reports as the ceiling on that row.

### Footnotes preserving Anthropic's per-benchmark methodology
- **Standard configuration (Fable/Mythos 5 and Sonnet 5 tables):** "adaptive thinking at max effort, default sampling settings, averaged over 5 trials"; 1M-token context standard; **BrowseComp uses a 10M-token budget with compaction and programmatic tool calling.** Competitor figures are from those vendors' own cards.
- **Fable 5 Terminal-Bench 2.1:** 20.9% of Fable trials fell back to Opus 4.8 on a safety refusal, accounting for the 84.3% vs Mythos 88.0% gap despite identical weights. Anthropic also switched from the Terminus-2 harness to mini-SWE-agent (which restated Opus 4.8 from 74.6% to 82.7% on this eval).
- **Opus 5 Frontier-Bench v0.1:** internal run on the mini-SWE-agent harness with a GKE backend, mean reward over 5 attempts per task; Opus 4.8 served as the fallback on safety-classifier refusals (Anthropic says Opus 5's classifiers trigger roughly 85% less often than Fable 5's; third-party read of the chart puts refusals at ~4% of Opus 5 trials vs ~26% of Fable 5 trials). Anthropic notes max effort "can be prone to overthinking," which is why xhigh (44.4%) edges max (43.3%) on this benchmark.
- **Sonnet 5 OSWorld-Verified:** score reflects a zoom-tool bug fix and a max-tokens-per-turn increase from 16K to 128K (restated Sonnet 4.6 to 78.5%). **HLE:** grader model updated at launch (restated Sonnet 4.6 to 34.6% no-tools / 46.8% with-tools). **GDPval-AA v2:** Elo "as of June 17, 2026."
- **Cyber metrics (Fable/Mythos):** Firefox = fraction of trials achieving arbitrary code execution; OSS-Fuzz = severity-weighted mean of a five-tier score; CyberGym = fraction reproducing the target vulnerability; CyScenarioBench = success rate averaged across challenges. Fable's cyber classifiers fire consistently, so Anthropic does **not** report Fable cyber numbers and states Fable's cyber performance is effectively Opus 4.8's.
- **Opus 5 OSS-Fuzz (safety eval):** Opus 5 is close to Mythos 5 at *finding* vulnerabilities but far behind at *developing exploits* for them; Anthropic deliberately keeps Opus 5 below Mythos 5 on offensive cyber and autonomous biology.

## Details

### Which models exist and where the data comes from
- **Claude Fable 5 & Claude Mythos 5** — Anthropic announcement "Claude Fable 5 and Claude Mythos 5" (June 9, 2026) and the ~300-page "System Card: Claude Fable 5 & Claude Mythos 5." Same underlying weights; Fable is safeguarded/general, Mythos is restricted. $10/$50 per MTok; 1M context, 128k max output; adaptive thinking always on. Access was suspended June 12 under a US Commerce Department export-control order and restored July 1, 2026. The bulk of numeric benchmarks live in System Card Section 8 ("Capabilities," subsections 8.2–8.20), with a summary image table in the announcement.
- **Claude Sonnet 5** — announcement "Introducing Claude Sonnet 5" (June 30, 2026) + "Claude Sonnet 5 System Card" (summary Table 8.1.A). $2/$10 introductory through Aug 31, 2026, then $3/$15; new tokenizer produces ~30% more tokens for the same text; 1M context, 128k output; adaptive thinking on by default (manual extended thinking removed).
- **Claude Opus 5** — announcement "Introducing Claude Opus 5" (July 24, 2026) + "Claude Opus 5 System Card." $5/$25 (unchanged from Opus 4.8); Fast mode ~2.5× speed at $10/$50; May 2026 knowledge cutoff (freshest of the family); thinking on by default. The announcement carries one benchmark image plus nine cost-performance charts (Frontier-Bench v0.1, CursorBench, AA Coding Agent Index, ARC-AGI 3, GDPval-AA v2, OSWorld 2.0, HLE, AutomationBench, DeepSearchQA) and states most gains as ratios.

Anthropic's docs (platform.claude.com "Models overview") list all three as current models alongside Haiku 4.5, confirming `claude-fable-5`, `claude-opus-5`, `claude-sonnet-5`, and `claude-mythos-5` as the API IDs and pointing benchmark seekers to the Transparency Hub.

### Effort levels — exactly how Anthropic labels them
- The effort ladder is **low, medium, high, xhigh, max** (docs "Effort" page). On Opus 5 and Sonnet 5, effort **defaults to `high`** on the API and Claude Code; on Opus 4.8 it defaults to `high` on all surfaces. `max` is the explicit top tier on Opus 5 and requires no beta header.
- **Fable 5 / Mythos 5:** adaptive thinking is "always on" and `thinking: {type:"disabled"}` is unsupported; depth is controlled only via the effort parameter. Headline table values are max-effort. The system card publishes effort-scaling for coding: SWE-bench Pro **75.0% (low) → 80.4% (xhigh)** and FrontierCode Diamond **11.5% → 30.9%**. Anthropic states Fable "beats other models even at medium effort" on FrontierCode.
- **Sonnet 5:** publishes cost-performance **curves** at different effort levels for exactly two evaluations — BrowseComp (agentic search) and OSWorld-Verified (computer use) — plotting Sonnet 5 vs Sonnet 4.6 vs Opus 4.8; no numeric per-effort table is given. Anthropic explicitly defines "xhigh = extra high effort level."
- **Opus 5:** all nine launch charts use the same axes (score vs dollars-per-task, each model a curve across low→max). Anthropic reports the peak points as ratios; xhigh is Anthropic's recommended starting point for coding/agentic work, `max` reserved for tasks that justify unconstrained spend.

### Interpretation — what the numbers mean
- On **agentic coding**, the family's spread is real and effort-sensitive: Fable/Mythos 5 lead the frontier (SWE-bench Pro ~80%, Terminal-Bench 2.1 88%), Sonnet 5 lands ~6 points behind Opus 4.8 on SWE-bench Pro (63.2%) at a fraction of the price, and Opus 5 more than doubles Opus 4.8 on Frontier-Bench (43.3% vs 18.7%) while approaching Fable 5's CursorBench peak at half the cost.
- On **knowledge work**, GDPval-AA is the clearest differentiator, but note the version trap: the Fable launch table quoted GDPval-AA (v1) at 1932, whereas the later Sonnet 5 system card uses GDPval-AA **v2**, on which Fable is 1783, Sonnet 5 1618, and Opus 4.8 1615 — do not compare across versions.
- On **reasoning**, ARC-AGI 3 is Opus 5's standout (30.2%, roughly 3–4× the next-best public model and ~20× Opus 4.8), the single result hardest to dismiss as chart-framing.
- **Safety/alignment (reported with scores):** Opus 5 is Anthropic's most-aligned model at **2.3** on its automated behavioral-audit misaligned-behavior scale (lowest of recent models); Mythos 5's alignment is "very low" risk, comparable to Opus 4.8; Sonnet 5 is safer than Sonnet 4.6 but shows somewhat higher misaligned-behavior rates than Opus 4.8/Mythos Preview. Sonnet 5 scores 0.0% on developing a working Firefox 147 exploit (13.2% partial), far below Opus 4.8 and Mythos 5.

## Recommendations
1. **If you need maximum capability:** cite Fable 5's max-effort table, but flag every cyber/bio/health-adjacent row as a Mythos 5 number the safeguarded Fable will not reach in production (its classifiers fall back to Opus 4.8 in <5% of sessions but always in those domains). Run Fable at xhigh for long-horizon coding — it is the model that converts thinking budget into accuracy.
2. **For everyday premium work:** default to Opus 5 ($5/$25). Because Anthropic published ratios rather than absolute numbers for most Opus 5 evals, **benchmark it yourself on 20–50 of your own tasks at multiple effort levels** rather than trusting launch charts; start at xhigh for coding, `high` elsewhere, then step down where quality holds. Do not treat `max` as strictly better (it under-performs xhigh on Frontier-Bench).
3. **For cost-sensitive/high-volume agentic work:** Sonnet 5 at medium effort is the best value; escalate to xhigh only where the last few accuracy points beat Opus-tier cost. Account for the new tokenizer (~30% more tokens for the same text) when budgeting.
4. **Thresholds that would change these calls:** if Anthropic publishes (a) absolute per-effort Opus 5 numbers, (b) a SWE-bench Verified figure for Sonnet 5, or (c) Fable 5 (not Mythos) cyber/bio scores, revisit the routing above. Until then, treat "(chart)" cells as directional only.

## Caveats
- **Opus 5 has the thinnest first-party numeric coverage.** Most Opus 5 cells marked "(chart)" are third-party transcriptions of Anthropic's cost-performance charts, not figures Anthropic printed as text; the enrichment sources (Vellum, The Next Web, thevibefather.com) attribute them to Anthropic's launch materials but they remain chart-read approximations.
- **Fable vs Mythos naming:** Anthropic's table shows the higher value per row and does not always separate the two configurations; SWE-bench Pro is 80.0% (Fable) vs 80.3% (Mythos), a gap attributable to safeguard fallback, not capability.
- **GDPval-AA version mismatch** (v1 1932 vs v2 1783 for Fable) and the **Terminal-Bench harness change** (Terminus-2 → mini-SWE-agent) mean some numbers moved between the Fable launch and the Sonnet/Opus launches; the chart flags versions where known.
- **All figures are vendor-reported.** Anthropic controls the harness, effort setting, and 5-trial averaging; competitor scores in its tables come from other vendors' cards. Independent verification (e.g., Epoch AI) of the flagship claims was not available as of this report.
- **SWE-bench Verified for Sonnet 5 is genuinely unresolved** in Anthropic's published text; the three conflicting third-party figures (72.7% / 85.2% / 92.4%) are explicitly excluded from the chart rather than guessed.
