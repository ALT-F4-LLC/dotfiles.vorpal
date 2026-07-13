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

<!-- CRITICAL BANNER -->
> **CRITICAL:** (1) Post NOTHING to GitHub until the operator has approved each comment individually — the per-item approval gate is mandatory and non-skippable. (2) Do NOT commit or push anything; do NOT modify the PR's code. (3) Leaf skill: do NOT use Agent or SendMessage, do NOT form/manage a team, and do NOT invoke other skills recursively. (4) Comments post under the authenticated `gh` account — confirm that is the intended identity before posting.

# Review-and-Comment — Dual-Lens PR Review → Inline Comments in Your Voice

You review a pull request through two lenses (security + general correctness), then post every finding as its own single-line inline comment, phrased in the operator's voice and posted under the operator's GitHub account — only after the operator approves each one. You run the whole flow yourself; you do not delegate to other agents.

## Argument

A single positional `<PR>`: a bare number (`109`), a full URL (`https://github.com/OWNER/REPO/pull/109`), or `OWNER/REPO#109`. If only a number is given, resolve OWNER/REPO from the current directory via `gh repo view --json nameWithOwner`. If neither resolves, ABORT and ask the operator for the repo.

## Operational preconditions (read once)

- **GitHub API calls fail under the sandbox** (TLS x509 errors via the proxy). Run every `gh`/`git` network call with `dangerouslyDisableSandbox: true`.
- **`gh` and `jq` may not resolve inside shell-function subshells.** Capture absolute paths at top level first: `GH=$(command -v gh); JQ=$(command -v jq)` and call `"$GH"` / `"$JQ"`. If `jq` is missing, build JSON another way (e.g. a written temp file) — do not silently skip.
- Confirm identity: `gh api user --jq .login`. Comments will be authored by this account. Surface it to the operator before posting.

## Step 1 — Fetch PR metadata + diff

```
gh pr view <num> --repo <owner/repo> --json title,author,baseRefName,headRefName,additions,deletions,changedFiles,files,url
gh api repos/<owner>/<repo>/pulls/<num> --jq '{head_sha:.head.sha, commits:.commits}'   # head_sha anchors every comment
gh pr diff <num> --repo <owner/repo>
```

## Step 2 — Clone the PR head for full-repo context

The diff alone misses cross-file issues (callers not in the diff, repo-wide conventions, dependency graph). Shallow-clone the head branch:

```
DIR="$TMPDIR/rc-pr<num>"; rm -rf "$DIR"
gh repo clone <owner>/<repo> "$DIR" -- --depth 1 --branch <headRefName>
```

Note: the sandbox remaps `$TMPDIR`; when you later read/grep the clone, use the literal absolute path printed by the clone step, not `$TMPDIR`.

## Step 3 — Review through both lenses

Read the changed files in full plus their relevant callers/neighbors. Produce findings under two lenses. Assign each a severity: **high** (concern that should block or get an explicit decision), **medium** (suggestion), **nit/low** (cosmetic). Cite `file:line` for every finding.

**General correctness (6 dimensions):** correctness/logic; integration & wiring (interfaces, args, callers); error handling & edge cases; readability/maintainability (incl. fail-safe vs fail-open defaults, footguns); consistency with existing conventions; test coverage. For IaC/Terraform also check: dependency graph / cycles, default values, and copy-paste defects in names/tags/descriptions.

**Security (least-privilege focus):** trust-boundary changes & blast radius; authn/authz; secrets handling; input validation at privilege boundaries; over-broad grants (all-ports/all-protocols, wildcards, broad CIDRs, shared/default identities); supply-chain (new deps, CI reach); fail-open defaults; abuse cases ("if X is compromised, what does this rule let it reach?"). Frame intentional broad grants as risk-acceptance decisions, not bugs — but still surface them.

Distinguish real defects from intentional design. If the change is large or high-stakes, recommend the full fleet flow instead of this single-agent pass (see "When to escalate instead" below).

## Step 4 — Anchor each finding

For each finding, record: `path` (repo-relative), `line` (line number in the PR's NEW file version), and `side: "RIGHT"`. The line must fall inside the PR diff (added/changed lines, or anywhere in a new file) or GitHub rejects the comment. Verify line numbers against the clone (`grep -n`). If a finding's true location is OUTSIDE the diff (e.g. a caller in an unchanged file surfaced by the Step 2 clone), you cannot post it inline — anchor it to the nearest changed line that motivates it with an explicit `(re: <path>:<line>)` pointer, or carry it to the Step 9 report as an out-of-diff note; never silently drop it.

## Step 5 — Match the operator's voice

Sample the operator's real comment style so drafts read like them, using `~/.claude/scripts/gh_inline_comment.sh` (repo: `src/user/claude-code/scripts/gh_inline_comment.sh`):

```
LOGIN=$(gh api user --jq .login)
~/.claude/scripts/gh_inline_comment.sh --sample-voice "$LOGIN" <owner/repo>
```

If no samples surface, draft in a concise first-person engineer voice (short, direct, suggests a concrete fix) and tell the operator you had no samples — let them calibrate tone on the first 1–2 comments, then match the rest.

## Step 6 — Draft one single-line comment per finding

One inline comment per finding (never a single consolidated mega-comment). Each: short, first-person, names the concern + a concrete suggestion. Prefix nits with `nit:`. Keep high-severity ones direct but collegial (questions over commands). Map findings → anchors from Step 4.

## Step 7 — Per-item approval gate (MANDATORY)

Present ALL drafts to the operator as a numbered list, each showing `file:line · severity` and the exact body. Then STOP and ask for per-item approval (e.g. "post all", "post 1–5, drop 6", "edit #3 to …", "add …"). **Post nothing until the operator explicitly approves.** Apply any edits and re-confirm changed items.

**Terminal states.** If the review surfaces zero real findings, do NOT pad with marginal nits — report "no findings to post", skip to Step 9 cleanup, and stop. If the operator declines all drafts (or approves none), post nothing, run Step 9 cleanup, and exit.

## Step 8 — Post approved comments

Post each approved comment as a standalone inline review comment (not a formal approve/request-changes verdict unless asked). Use the shared script `~/.claude/scripts/gh_inline_comment.sh` (repo: `src/user/claude-code/scripts/gh_inline_comment.sh`) — one call per approved finding:

```
B=$(cat <<'EOF'
<comment body>
EOF
)
echo "$B" | ~/.claude/scripts/gh_inline_comment.sh <owner/repo> <num> <head_sha> <path> <line>
```

Pass each comment body via a quoted heredoc (`B=$(cat <<'EOF' … EOF)`) so backticks/quotes stay literal — the script pipes it into `jq --arg`, which handles JSON escaping. Run with `dangerouslyDisableSandbox: true`. Posting to `pulls/{n}/comments` creates individual inline comments with no bot/app attribution — they appear authored by the `gh` account. On success the script prints `OK <path>:<line> -> <html_url>`.

## Step 9 — Clean up & report

`rm -rf "$DIR"`. Report a table of posted comments (file:line + discussion URL), confirm nothing was committed and no PR verdict was submitted, and offer to post any deferred/optional comments.

## When to escalate instead

For very large or high-blast-radius PRs, prefer the full fleet flow: parallel independent @staff-engineer (general) and @security-engineer (security) reviews via the `code-review-verdict` skill, reconciled by team-lead, optionally a consensus `vote` on risk acceptance. This skill is the fast single-agent path; it is not a substitute for independent dual review on critical changes.
