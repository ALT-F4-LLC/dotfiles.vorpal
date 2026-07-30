---
name: review-and-comment
description: >
  Review a pull request across security and general-correctness lenses, then post each
  finding as an individual single-line inline comment on the PR — written in the operator's
  voice, under the operator's GitHub account, after per-item approval. Self-contained leaf
  skill: the calling agent runs the whole flow end-to-end; it does NOT spawn a team.
  Trigger: "review and comment", "review this PR and post comments", "inline review of a PR",
  "post my review comments on <PR>".
argument-hint: "<PR — number, full URL, or owner/repo#number>"
allowed-tools: ["AskUserQuestion", "Bash", "Glob", "Grep", "Read"]
disallowed-tools: ["Edit", "Write", "Agent", "SendMessage"]
---

<!-- CANONICAL:BANNER:BEGIN -->
<!-- CRITICAL BANNER -->
> **CRITICAL:** (1) Post NOTHING to GitHub until the operator has approved each comment individually — the per-item approval gate is mandatory and non-skippable. (2) Do NOT commit or push anything; do NOT modify the PR's code. (3) Leaf skill: do NOT use Agent or SendMessage, do NOT form/manage a team, and do NOT invoke other skills recursively. (4) Comments post under the authenticated `gh` account — confirm that is the intended identity before posting. (5) Caller-side effect: this skill's `disallowed-tools` frontmatter removes `Edit`, `Write`, `Agent`, and `SendMessage` from the CALLING agent's tool pool until the OPERATOR's next real message — the restriction persists across stop-hook continuations, inbound teammate messages, and any number of autonomous turns (transcript-verified). Schedule spawns/teammate messages/file edits BEFORE invoking, and treat a subsequent `"exists but is not enabled in this context"` error on those tools as this restriction, not an outage.
<!-- CANONICAL:BANNER:END -->

# Review-and-Comment — Dual-Lens PR Review → Inline Comments in Your Voice

Review a pull request through two lenses (security + general correctness), then post every finding as its own single-line inline comment, phrased in the operator's voice and posted under the operator's GitHub account — only after the operator approves each one. You run the whole flow yourself.

## Argument

A single positional `<PR>`: a bare number (`109`), a full URL, or `OWNER/REPO#109`. If only a number is given, resolve OWNER/REPO from the current directory via `gh repo view --json nameWithOwner`; if neither resolves, ABORT and ask the operator for the repo.

## Operational preconditions

- **GitHub API calls fail under the sandbox** (TLS x509 via the proxy) — run every `gh`/`git` network call with `dangerouslyDisableSandbox: true`, including the script calls below.
- **`gh`/`jq` may not resolve inside shell-function subshells** — capture absolute paths at top level (`GH=$(command -v gh); JQ=$(command -v jq)`) for any raw call; the setup script handles this internally.
- Comments post as the authenticated account — Step 1 prints it as `IDENTITY`; surface it to the operator before posting.

## Step 1 — Fetch metadata, diff, and clone

Run `~/.claude/scripts/rc_pr_setup.sh <owner/repo> <num>` (repo: `src/user/claude-code/scripts/rc_pr_setup.sh`) with `dangerouslyDisableSandbox: true`. One deterministic call: prints the acting `IDENTITY`, fetches PR metadata and `HEAD_SHA` (anchors every comment), writes the full diff to `DIFF_FILE`, and shallow-clones the PR head branch to `CLONE_DIR` for full-repo context (the diff alone misses callers not in the diff, repo conventions, the dependency graph). **Reuse the printed `DIFF_FILE`/`CLONE_DIR` absolute paths verbatim for the rest of the flow** — the sandbox remaps `$TMPDIR` between calls, so recomputing them later points at the wrong location.

## Step 2 — Review through both lenses

Read the changed files in full plus their relevant callers/neighbors from the clone. Assign each finding a severity — **high** (should block or get an explicit decision), **medium** (suggestion), **nit/low** (cosmetic) — and cite `file:line`.

**General-correctness lens:** correctness/logic; integration & wiring (interfaces, args, callers); error handling & edge cases; readability/maintainability (incl. fail-safe vs fail-open defaults, footguns); consistency with existing conventions; test coverage. For IaC/Terraform also: dependency graph/cycles, default values, copy-paste defects in names/tags/descriptions.

**Security lens (least-privilege focus):** trust-boundary changes & blast radius; authn/authz; secrets handling; input validation at privilege boundaries; over-broad grants (all-ports/all-protocols, wildcards, broad CIDRs, shared/default identities); supply-chain (new deps, CI reach); fail-open defaults; abuse cases ("if X is compromised, what does this rule let it reach?"). Frame intentional broad grants as risk-acceptance decisions, not bugs — but still surface them.

Distinguish real defects from intentional design. (This fast single-agent pass is not the fleet's formal 6-dimension review rubric — that lives in `Skill(code-review-verdict)`; see "When to escalate instead".)

## Step 3 — Anchor each finding

Record `path` (repo-relative), `line` (in the PR's NEW file version), `side: "RIGHT"`. The line must fall inside the PR diff (added/changed lines, or anywhere in a new file) or GitHub rejects the comment — verify line numbers against the clone (`grep -n`). A finding whose true location is OUTSIDE the diff cannot post inline: anchor it to the nearest changed line that motivates it with an explicit `(re: <path>:<line>)` pointer, or carry it to the Step 8 report as an out-of-diff note — never silently drop it.

## Step 4 — Match the operator's voice

Sample the operator's real comment style: `~/.claude/scripts/gh_inline_comment.sh --sample-voice <IDENTITY> <owner/repo>`. If no samples surface, draft in a concise first-person engineer voice (short, direct, concrete fix), tell the operator you had no samples, and let them calibrate tone on the first 1-2 comments.

## Step 5 — Draft one single-line comment per finding

One inline comment per finding (never a consolidated mega-comment): short, first-person, names the concern + a concrete suggestion. Prefix nits with `nit:`. Keep high-severity ones direct but collegial (questions over commands).

## Step 6 — Per-item approval gate (MANDATORY)

Before presenting, fetch the PR's existing inline comments once (`gh api repos/<owner>/<repo>/pulls/<num>/comments --jq '.[]|"\(.path):\(.line)\t\(.body)"'`, sandbox-off) and mark any draft whose `path:line` + concern already matches one as `[DUP — already on PR]`; exclude dups from the post set unless the operator opts to re-post — this keeps a re-run from posting the same comment twice under the operator's account.

Present ALL drafts as a numbered list, each showing `file:line · severity` and the exact body. Then STOP and ask for per-item approval ("post all", "post 1-5, drop 6", "edit #3 to …"). **Post nothing until the operator explicitly approves.** Apply edits and re-confirm changed items.

**Terminal states.** Zero real findings → do NOT pad with marginal nits; report "no findings to post", clean up (Step 8), stop. Operator declines all → post nothing, clean up, exit.

## Step 7 — Post approved comments

One `~/.claude/scripts/gh_inline_comment.sh` call per approved finding, preceded by a fresh dedupe check for that exact `path:line`:

```
~/.claude/scripts/gh_inline_comment.sh --existing <owner/repo> <num> <path> <line>; rc=$?
if [ "$rc" -eq 2 ]; then
    echo "STOP: could not verify whether <path>:<line> already has a comment (gh api/jq lookup failed) — do not post; ask the operator before proceeding" >&2
elif [ "$rc" -eq 0 ]; then
    echo "skipping <path>:<line> — comment already exists"
else
    B=$(cat <<'EOF'
<comment body>
EOF
    )
    echo "$B" | ~/.claude/scripts/gh_inline_comment.sh <owner/repo> <num> <head_sha> <path> <line>
fi
```

Run `--existing` immediately before EVERY post even though Step 6 previewed a snapshot — it catches comments posted in between and is the authoritative dedupe guard. Three outcomes: exit 0 (`EXISTS`) — skip and note it in the report; exit 1 (`NONE`) — post; exit 2 (lookup failed — existence genuinely unknown) — do NOT post and do NOT silently skip: surface it ("could not verify whether a comment already exists at `<path>:<line>` — retry, check manually, or post anyway?") and wait for the operator's call. Pass each body via a quoted heredoc so backticks/quotes stay literal (the script pipes into `jq --arg`); run both calls sandbox-disabled. Posting to `pulls/{n}/comments` creates inline comments with no bot/app attribution; on success the script prints `OK <path>:<line> -> <html_url>`.

## Step 8 — Clean up & report

`rm -rf <CLONE_DIR> <DIFF_FILE>` — substitute the LITERAL paths Step 1 printed (shell variables don't survive between Bash calls; an unset one expands empty and `rm -rf ""` exits 0 silently, leaving the clone behind). Report: a table of posted comments (file:line + discussion URL), items skipped as duplicates, items left unposted on an exit-2 lookup still awaiting the operator's call, confirmation that nothing was committed and no PR verdict was submitted, and an offer to post any deferred comments.

## When to escalate instead

For very large or high-blast-radius PRs, prefer the full fleet flow: parallel independent @staff-engineer and @security-engineer reviews via `Skill(code-review-verdict)`, reconciled by team-lead, optionally a consensus `vote` on risk acceptance. This skill is the fast single-agent path, not a substitute for independent dual review on critical changes.
