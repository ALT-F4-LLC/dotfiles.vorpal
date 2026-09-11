# Maintaining and evaluating the Docket skill

Keep mechanical command discovery in `scripts/cli_inventory.py`. Check its
versioned inventory after a CLI upgrade; update authored semantics only after
checking the corresponding help, source version, or isolated behavior. Changes
to JSON shapes require runtime fixtures, not just a help comparison.

## Behavioral comparisons

`scripts/evaluate.py` compares a candidate and optional baseline across exact
model IDs and effort settings. It supplies the entry point and allows Claude
to read supporting references as needed. The twelve independent scenarios in
`evals/cases.json` cover voter identity, accepted records with failing gates,
confirmed success, interrupted recording, lease expiry, project selection,
pagination, literal descriptions and idempotency, claim attribution, gap
headers, guard denial, and inspection after a retained handoff.

Claude has only Read and Grep tools. It returns command proposals and decisions;
the harness never executes generated shell code. `--docket` additionally checks
allowlisted issue creation/replay and voting proposals against disposable
stores, then verifies their database results. These stores are created under
the system temporary directory with explicit `DOCKET_PATH` and isolated config.
No scenario uses a live project or its tracker. Database checks require a
Docket binary; the ordinary CI tests require neither Docket nor Claude.

From this skill directory:

```bash
python3 scripts/evaluate.py --baseline /path/to/saved/docket \
  --output /path/to/results.json --dry-run
python3 scripts/evaluate.py --baseline /path/to/saved/docket \
  --models claude-sonnet-5 claude-opus-5 claude-fable-5-1 \
  --efforts high --max-budget-usd 1.5 --docket /path/to/docket \
  --output /path/to/results.json
```

Each invocation has its own budget threshold and wall timeout. Claude checks
the budget between requests; an in-flight request can exceed the threshold.
The initial plan prints the matrix size and summed thresholds. A baseline doubles the
number of invocations. Add `--efforts low medium high xhigh max` or
`--repetitions 3` only when the comparison warrants that additional cost.
The default is one invocation per model/variant at high effort, suitable for
a smoke comparison rather than a statistically reliable ranking.

The output records frozen source/case/evaluator/inventory hashes, requested model/effort, Claude's result
metadata (including observed `modelUsage`, usage and cost when exposed), inspection
tool calls, elapsed time, per-case grades and isolated database checks. Failed
authentication, unavailable models, malformed results and timeouts are recorded
as unavailable, never as passing evaluations. The script returns nonzero for
an unavailable or failed cell, including failures in a supplied baseline.

## Interpret results within their limits

These are controlled decision and command-proposal evaluations, not a complete
autonomous Docket run. They do not test automatic skill discovery, native Skill
loading, an executor's tool permissions, physical shell quoting, or real
context compaction. Literal-text execution uses a shell-free argv transport.
`--prefix-chars N` adds a synthetic prefix-retention probe with the full skill
still readable from disk; it tests recovery with retrieval available. N counts characters,
not model tokens, and must not be reported as Claude Code's compaction result.
The resume scenario tests decisions from a retained handoff, not compaction's
ability to preserve that handoff.

Before promoting a substantially changed skill, also inspect a representative
Claude Code run for correct discovery, companion-skill routing, receipt
recovery and completion reporting. Keep the existing runtime hook/workflow
regression suites. A schema-valid final answer cannot establish a mutation
happened, and a model's self-report cannot attest which model served it.

## Current model targets

As checked 2026-09-11, use Fable 5.1, Opus 5 and Sonnet 5 for the generally
available Claude 5 comparison. Mythos 5.1 is an optional additional target
only for an account granted access. Haiku remains 4.5 and has no effort control.
The repository's policy already routes work by model and effort; preserve it
until Docket-specific results justify a change.

- Sonnet 5 benefits from explicitly scoped requirements and concrete output
  contracts, particularly at lower effort.
- Opus 5 needs the task's actual gates and acceptance criteria; repeated generic
  instructions to verify everything can add unnecessary work.
- Fable 5.1 should be compared across effort levels on completed-task quality,
  cost and latency. Low effort can retrieve less, so verify live CLI discovery
  on unfamiliar commands. Request concise progress updates on long operations.

Sources: [Claude skill evaluation guidance](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices),
[Sonnet 5](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-sonnet-5),
[Opus 5](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5),
[Fable 5.1](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-1),
[model availability](https://platform.claude.com/docs/en/about-claude/models/overview),
[effective models and effort limits](https://code.claude.com/docs/en/model-config).
