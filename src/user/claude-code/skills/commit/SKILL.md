---
name: commit
description: >
  Draft a Conventional-Commits-compliant commit message and execute a scoped
  `git add` + `git commit` with it. Guarantees the message never references
  agents/subagents, Docket issue IDs, harness/orchestration metadata, or
  Claude/Claude Code/Anthropic. Invokable ONLY by team-lead — no other agent
  or subagent may call this skill. Requires team-lead to already hold
  explicit operator authorization to commit — invoking this skill is NOT
  itself that authorization.
  Trigger: "commit this", "create a commit", "standardized commit", "draft a commit message".
argument-hint: "<files to commit> [-- what changed and why]"
allowed-tools: ["AskUserQuestion", "Bash", "Read", "Grep", "Glob"]
disallowed-tools: ["Edit", "Write", "Agent", "SendMessage"]
---

<!-- CANONICAL:BANNER:BEGIN -->
<!-- CRITICAL BANNER -->
> **CRITICAL:** (1) This skill may be invoked ONLY by team-lead — no other agent or subagent may call `Skill(commit, ...)`. (2) This skill stages and commits ONLY when team-lead has already received EXPLICIT operator authorization to commit right now — invoking `Skill(commit, ...)` is NOT itself that authorization. If team-lead has not confirmed explicit authorization, STOP and ask; do not stage or commit. (3) Never run `git push`. Never run `git commit --amend` on a pre-existing commit. (4) This is a leaf skill. You MUST NOT spawn sub-agents, invoke `Skill()` recursively, use `Agent()` or `SendMessage`, or form/manage a team. (5) Caller-side effect: this skill's `disallowed-tools` frontmatter removes `Edit`, `Write`, `Agent`, and `SendMessage` from the CALLING agent's tool pool until the OPERATOR's next real message — the restriction persists across stop-hook continuations, inbound teammate messages, and any number of autonomous turns (transcript-verified). Schedule spawns/teammate messages/file edits BEFORE invoking, and treat a subsequent `"exists but is not enabled in this context"` error on those tools as this restriction, not an outage.
<!-- CANONICAL:BANNER:END -->

# Commit — Draft and Execute a Standardized Conventional Commit

You are the **Commit Author**: draft one Conventional-Commits-compliant message for the files the calling agent specifies, then run a scoped `git add` + `git commit`. This skill is the format authority for the message and the safety authority for the execution (scoping, index verification, no push/amend).

## Argument Handling

The argument is `<files to commit>` (space-separated paths or pathspecs, required), optionally followed by `-- <what changed and why>` (free-text context for the body). If missing or empty:

```
Error: Usage: Skill(commit, "<files> [-- what changed and why]") — name the exact files to stage.
```

Never infer the fileset from a bare `git status`/`git diff` scan — in a shared multi-agent tree an unscoped scan surfaces sibling agents' uncommitted work; the caller must already know and state which files are in scope.

## Step 0 — Caller & Authorization Gate

**Caller check (first).** Only `team-lead` may invoke this skill. Any other caller:

```
Blocked: Skill(commit) may only be invoked by team-lead. Route the commit
request to team-lead instead of invoking this skill directly.
```

**Authorization check (second).** Confirm the invocation context states the operator has already given explicit authorization to commit *now* — not standing permission, not an inference from "this seems done". If absent:

```
Blocked: Skill(commit) requires team-lead to already hold explicit operator
authorization to commit. Invoking this skill is not itself that authorization
— confirm with the operator, then re-invoke.
```

This gate operates *within* the fleet's standing no-commit rule — it adds message-format and scoping guarantees once authorization already exists, never a way around it. Also outside this skill's contract, decline and point at direct `git` usage under explicit operator instruction: pushing, amending, history rewrites, filesets spanning multiple unrelated logical changes (split first).

## Step 1 — Resolve and verify commit scope

1. Parse `<files to commit>` into an explicit path list. Reject bare `.` or `-A`/`--all` — pathspecs name real files or directories, never a blanket wildcard.
2. `git status --porcelain -- <files>` scoped to exactly those paths. Read both columns: `MM` means staged content from an earlier round plus newer unstaged edits — not a blocker (Step 4's `git add` refreshes it), but a bare `git diff` would have looked clean while the index held stale content.
3. `git diff --cached --name-only` — if non-empty before you stage anything, partition the list against the fileset. Paths INSIDE the fileset are your own stale index — leave them; Step 4 refreshes and re-verifies. Paths OUTSIDE the fileset are possibly a sibling agent's in-progress work — never commit through them:

   ```
   Blocked: index already has staged changes ({out-of-fileset staged files})
   that are not part of this commit's fileset. Resolve (unstage or hand off)
   before invoking Skill(commit) — never commit through someone else's
   staged work.
   ```

## Step 2 — Draft the message

**Format**: `<type>[optional scope]: <description>`, blank line, optional body, optional footer. **Type** (exactly one): `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`, `build`, `ci`, `revert`. **Scope**: the code area touched, never the authoring agent or branch — match the scope tokens already in this repo's history (`git log --oneline -20 -- <touched-dir>`), with one exception: the historical `(claude-code)` scope trips Step 3's rule 4 (`claude` matches inside `claude-code`) and cannot be used — prefer another in-use area token or a bare scopeless type. **Description**: imperative mood, no trailing period, ≤50 characters. **Body**: wrap at ~72 characters; explain *why*, not a restatement of the diff. **Breaking changes**: a `BREAKING CHANGE: <description>` footer when a documented public contract breaks. **One-change guard**: if the fileset cannot be honestly described by one `<type>(<scope>): <description>` line, STOP and have the caller split into separate invocations — one per logical, bisectable change.

Example:

```
fix(hooks): reject git writes in non-interactive permission modes

The guard hook previously allowed git add/commit/push to slip through
when no human could confirm the prompt. Deny the write outright in
auto/dontAsk/bypassPermissions instead of silently allowing it.
```

Also pick non-triggering wording up front for known false-positive tokens — e.g. "peer-skills" instead of "teammate" (rule 3 matches it) — a drafting preference that avoids rework, not a change to the checks.

## Step 3 — Forbidden-content check (mandatory, before staging)

The message must contain none of: (1) agent/subagent/role `@`-mentions; (2) Docket issue IDs or any issue-tracker references; (3) harness/orchestration metadata (task/session/vote IDs, model or tier names, team/teammate names); (4) Claude/Claude Code/Anthropic references or AI-attribution trailers (`Generated by…`, `Co-Authored-By: Claude`, `🤖…`).

Mechanize it: write the fully drafted message to `$TMPDIR/commit-msg-draft.txt` via a quoted heredoc (`cat > ... <<'EOF'`), then run the single source of truth for all four patterns:

```
~/.claude/scripts/commit_msg_check.sh "$TMPDIR/commit-msg-draft.txt"
```

Any nonzero exit is a defect in the draft, not a false positive to explain away — rewrite and re-run until it exits 0. (Rule 2 allowlists standard technical identifiers like `UTF-8`/`SHA-256`/`CVE-2024-…`, so a surviving hit is a genuine tracker ID.) One residual the script deliberately does not gate: single-word tier/model/role nouns (`gold`, `diamond`, `sonnet`, `opus`, `advisor`, …) collide too often with ordinary English — eyeball the draft for a stray bare one before staging.

## Step 4 — Stage the scoped files

`git add -- <file1> <file2> ...` naming every path explicitly — never `git add .`/`-A`/a bare sweeping directory. `guard-no-commit-hook.sh` intercepts `git add` as well as `git commit`, so a permission-mode denial can first surface here; in an interactive mode the hook raises a SEPARATE operator prompt at Step 4 and Step 5 — approval here followed by denial at Step 5 leaves the index staged, not clean. On the hook's denial (stderr contains `git writes are blocked in non-interactive permission mode`), surface: `This session's permission mode blocks git writes here — switch to an interactive mode (default/plan/acceptEdits, e.g. Shift+Tab or /permissions) and re-invoke Skill(commit). Nothing was committed.` — and if `git add` already succeeded, name the staged files rather than claiming a clean tree (Step 1's index precheck blocks the next invocation until they're unstaged). Never retry with `--no-verify` or probe the mode in advance.

After staging, re-run `git diff --cached --name-only` and confirm the result is *exactly* the intended fileset (order-independent). If it differs, the index changed concurrently — ABORT without committing:

```
Blocked: staged fileset does not match the intended scope after `git add`
({staged} vs {intended}) — index changed concurrently. Re-run from Step 1.
```

## Step 5 — Commit

`git commit -F "$TMPDIR/commit-msg-draft.txt"` — `-F` against the already-checked file avoids re-typing through shell quoting.

**Sandbox-context invariant.** `$TMPDIR` can resolve differently between sandboxed and sandbox-disabled Bash calls — never split "write the checked message file" and "consume it with `-F`" across calls that might differ in sandbox setting. A known signature requiring the disabled-sandbox retry: `1Password: Could not connect to socket. Is the agent running?` (the sandbox blocking the SSH-signing-agent socket — retry once sandbox-disabled; this is distinct from `--no-verify`, which stays forbidden). On any such retry, rewrite the message file, re-run the Step 3 check, and run `git commit -F` all inside that same disabled-sandbox call.

**Post-commit verification (mandatory).** After `git commit -F` succeeds, run `git log -1 --format='%H%n%s%n%b'` and confirm subject and body match the checked draft exactly — a stale `$TMPDIR` file commits successfully while silently carrying the wrong message. On mismatch: no success report, no self-fix with `--amend` (forbidden) — report the mismatch and the commit's SHA to the caller so it can secure fresh operator authorization for whatever fixes it. Any other `git commit` failure (hook rejection, empty diff): surface the raw error; never bypass.

## Step 6 — Report

```
Committed {short_sha}: {subject line}
Files: {file1}, {file2}, ...
```

Do not push, open a PR, or send peer messages — the calling agent owns next steps.
