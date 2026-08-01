# Model Routing Policy

Plan: **Claude Max 20x**. Not billed per token. The constraint is **quota burn** — output tokens against a rolling 5-hour session window plus a weekly cap, pooled across web, desktop, mobile, and Claude Code.

Optimize for: fewest output tokens that still clear the task. Not lowest dollar cost.

## Model tiers

| Tier | Model | Effort | Use for |
|---|---|---|---|
| Bulk | Sonnet 5 | low–medium | Boilerplate, mechanical refactors, test generation, well-specified file edits, formatting, docs |
| Default | Opus 5 | high | Nearly all coding and agentic work — the standard choice |
| Stretch | Opus 5 | xhigh | Task failed once at high, or spans many files with unclear coupling |
| Ceiling | Fable 5 | max | Hardest debugging, novel architecture, anything that failed at Opus 5 xhigh. Budget-capped — see below |

## Escalation ladder

Escalate one step at a time. Never jump straight to max.

```
Sonnet 5 medium → Opus 5 high → Opus 5 xhigh → Fable 5 max
```

**Switch models rather than raising Sonnet's effort.** Opus 5 dominates the quality frontier above Sonnet's medium setting, so Sonnet 5 at high or max is wasted quota in essentially every case. Sonnet 5 at max also averaged 183 turns per long-horizon agentic task — the highest of any model measured — so the "cheap" model burns the *most* quota on long work.

**Do not default to max effort.** Max burns ~70% more output tokens than high for a marginal gain, and on coding benchmarks accuracy plateaus or *declines* above medium/xhigh (the model makes more changes than the task requires). Escalate on evidence of failure, not in anticipation of difficulty.

## Fable 5 budget

Fable 5 is included on Max 20x up to **50% of weekly limits**. It costs no extra money, but it is the scarcest resource in the session.

- Spend it on genuinely hard problems, not routine work.
- If Fable allocation is exhausted mid-week, fall back to Opus 5 xhigh — not to Sonnet.
- Prefer one well-scoped Fable 5 attempt over three speculative ones.

## Hard routing rules

1. **Security, cryptography, malware analysis, vulnerability work → Opus 5, never Fable 5.** Fable 5's safeguard classifiers reroute cyber/bio/chem/distillation requests to Opus 4.8 silently. You get a *weaker* model than Opus 5 while consuming Fable budget.
2. **Large-repo work stays in Claude Code.** Opus reaches 1M context here; the chat interface caps it near 200K.
3. **Plan with Opus 5 (high), implement with Sonnet 5 (medium)** on multi-step work. Reserve the strong model for the decisions, not the typing.
4. **Long agentic loops: prefer Opus 5 high over Sonnet 5 at any effort.** Turn count, not per-token rate, drives quota burn on long-horizon tasks.
5. **Re-run an effort sweep after any model change.** Opus 5 responds to effort levels differently from the 4.x line; Anthropic's own guidance flipped from "start at xhigh" to "start at high and reach down."

## Why Opus 4.8 is not in the ladder

Deliberately excluded. Opus 5 beats it decisively on the work Claude Code does — Frontier-Bench 43.3% vs 18.7%, Zapier AutomationBench 26.0% vs 17.0% — and the usual reason to reach for an older model (lower cost) does not apply on Max. If you need to conserve quota, drop to Sonnet 5 at medium rather than to 4.8.

Two things to still be aware of:

- **It is already in the routing path.** Opus 4.8 is what Fable 5 falls back to when safeguard classifiers fire. You do not choose it; you receive it. This is the basis for rule 1 above.
- **One genuine regression.** Opus 5's hallucination rate on AA-Omniscience measured ~50%, up ~14 points from Opus 4.8 — it answers more often when uncertain. Matters less here than elsewhere, since most Claude Code answers get validated by running the code, but it is a trade rather than a clean upgrade.

If Opus 5 is over-editing (making more changes than the task requires), drop effort to medium first. Do not reach for 4.8.

## Quick decision

- Is the task mechanical and clearly specified? → Sonnet 5, low/medium
- Anything else? → Opus 5, high
- Did it fail at high? → Opus 5, xhigh
- Did it fail at xhigh, and is it non-security? → Fable 5, max
- Did it fail at xhigh, and is it security-related? → stay on Opus 5, decompose the task instead
