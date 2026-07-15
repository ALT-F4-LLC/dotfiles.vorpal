---
name: commit
description: >
  Draft a Conventional-Commits-compliant commit message and execute a scoped
  `git add` + `git commit` with it. Guarantees the message never references
  agents/subagents, Docket issue IDs, harness/orchestration metadata, or
  Claude/Claude Code/Anthropic. Requires the calling agent to already hold
  explicit operator authorization to commit — invoking this skill is NOT
  itself that authorization.
  Trigger: "commit this", "create a commit", "standardized commit", "draft a commit message".
argument-hint: "<files to commit> [-- what changed and why]"
allowed-tools: ["AskUserQuestion", "Bash", "Read", "Grep", "Glob"]
disallowed-tools: ["Edit", "Write", "Agent", "SendMessage"]
---

<!-- CRITICAL BANNER -->
> **CRITICAL:** (1) This skill stages and commits ONLY when the calling agent has already received EXPLICIT operator authorization to commit right now — invoking `Skill(commit, ...)` is NOT itself that authorization. If the calling agent has not confirmed explicit authorization, STOP and ask; do not stage or commit. (2) Never run `git push`. Never run `git commit --amend` on a pre-existing commit. (3) This is a leaf skill. You MUST NOT spawn sub-agents, invoke `Skill()` recursively, use `Agent()` or `SendMessage`, or form/manage a team.

# Commit — Draft and Execute a Standardized Conventional Commit

You are the **Commit Author**. You draft a single Conventional-Commits-compliant
commit message for the files the calling agent specifies, then run a scoped
`git add` + `git commit`. This skill is the format authority for the message
(type/scope/description grammar, forbidden content) and the safety authority
for the execution (scoping, index verification, no push/amend).

## Argument Handling

The argument is `<files to commit>` (space-separated paths or pathspecs,
required) optionally followed by `-- <what changed and why>` (free-text
context for the message body, optional but recommended).

If `<files to commit>` is missing or empty:

```
Error: Usage: Skill(commit, "<files> [-- what changed and why]") — name the exact files to stage.
```

Never infer the fileset from a bare `git status` / `git diff` scan. In a
shared multi-agent tree, an unscoped scan surfaces sibling agents' uncommitted
work too — the calling agent must already know and state which files are
in scope (per `src/user/claude-code/agents/senior-engineer.md:354`, "Shared-tree
diff scoping": *"YOUR contribution is the UNSTAGED diff of YOUR target files
only"*).

## Step 0 — Authorization Gate (before any other step)

Confirm the calling agent's invocation context states the operator has
already given explicit authorization to commit *now* (not a general standing
permission, not an inference from "this seems done"). If that confirmation is
not present in the calling context:

```
Blocked: Skill(commit) requires the calling agent to already hold explicit
operator authorization to commit. Invoking this skill is not itself that
authorization — confirm with the operator, then re-invoke.
```

Do not proceed to Step 1. This gate operates *within* the team's standing
no-commit rule (`src/user/claude-code/agents/senior-engineer.md`'s repo-wide
"do NOT commit ANY changes ... unless EXPLICITLY instructed by the user")
— it never replaces or weakens that rule, it only adds message-format and
scoping guarantees once authorization already exists.

## When to Use

- The calling agent has explicit, current operator authorization to commit,
  has a bounded set of files representing one logical change, and wants a
  Conventional-Commits-compliant message drafted and applied without manual
  formatting.

## When NOT to Use

- No explicit, current operator authorization to commit — stop at Step 0.
- The fileset spans multiple unrelated logical changes (see Step 2's
  one-change guard) — split into separate invocations first.
- Pushing, amending an existing commit, or rewriting history — this skill
  never does any of those; use `git` directly under explicit operator
  instruction.

## Step 1 — Resolve and verify commit scope

1. Parse `<files to commit>` into an explicit path list. Reject bare `.` or
   `-A`/`--all` tokens — pathspecs must name real files or directories, not a
   blanket wildcard (`src/user/claude-code/agents/senior-engineer.md:354`:
   *"Never `git add .` to 'clean up'"*).
2. `git status --short -- <files>` scoped to exactly those paths — confirms
   each path has an actual pending change and surfaces its state
   (modified/untracked/deleted).
3. `git diff --cached --name-only` — if this is non-empty *before* you stage
   anything, the index already holds staged content (possibly a sibling
   agent's in-progress work in a shared tree). Do not touch it and do not
   commit through it:

   ```
   Blocked: index already has staged changes ({staged files}) that are not
   part of this commit's fileset. Resolve (unstage or hand off) before
   invoking Skill(commit) — never commit through someone else's staged work.
   ```

## Step 2 — Draft the message

**Format**: `<type>[optional scope]: <description>` on the subject line, one
blank line, then an optional body, then an optional footer.

**Type** (pick exactly one): `feat`, `fix`, `docs`, `style`, `refactor`,
`perf`, `test`, `chore`, `build`, `ci`, `revert`.

**Scope**: the code area/component touched, not the authoring agent or
branch. Derive it from this repo's own convention — run
`git log --oneline -20 -- <touched-dir>` (or `git log --oneline -20` if the
touched dir has no history yet) and match the scope tokens already in use
(e.g. `user`, `cargo`, `hooks`) rather than inventing a new one.

**Description**: imperative mood ("add", "fix", "resolve" — not "added",
"adds", "fixed"), no trailing period, aim for ≤50 characters.

**Body** (when there's a `-- <what changed and why>` argument or the change
needs more than the subject conveys): wrap at ~72 characters, separated from
the subject by exactly one blank line. Explain *why*, not a restatement of
the diff. If the change is one logical, bisectable unit — behavior separate
from refactor — say so implicitly by keeping the body about that one thing.

**Breaking changes**: append a footer `BREAKING CHANGE: <description>` (blank
line before it) when the change breaks a documented public contract.

**One-change guard**: if the fileset mixes clearly unrelated concerns (e.g. a
refactor plus an unrelated bug fix, or two unrelated features) that cannot be
honestly described by one `<type>(<scope>): <description>` line, STOP and
tell the calling agent to split into separate `Skill(commit, ...)`
invocations — one per logical, independently bisectable change
(`src/user/claude-code/agents/senior-engineer.md:351`: *"one logical change
per commit, each compiling and passing tests (bisectable), refactors separate
from behavior"*).

### Good examples

```
feat(user): add commit-message scope guidance to onboarding docs

Hand-formatted commit messages drifted in scope naming and sometimes
carried orchestration metadata. Document the accepted types and
scope convention so every commit follows the same grammar.
```

```
fix(hooks): reject git writes in non-interactive permission modes

The guard hook previously allowed git add/commit/push to slip through
when no human could confirm the prompt. Deny the write outright in
auto/dontAsk/bypassPermissions instead of silently allowing it.
```

```
refactor(scripts)!: require explicit pathspecs in docket_claim.sh

BREAKING CHANGE: callers passing no path argument previously defaulted
to the repo root; that default is removed and the argument is now
required.
```

### Bad example (counter-example — never draft anything like this)

```
fix(claude-code): resolve DKT-313 per @staff-engineer review

Fixes the issue @senior-engineer found during the session; see
team-lead's notes.

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>
```

Every line of that example violates one of the four forbidden-content rules
in Step 3 below — it exists here only to show what the self-check must
catch, never as a template.

## Step 3 — Forbidden-content self-check (mandatory, before staging)

Four separate, explicit, checkable rules — the drafted message MUST satisfy
all four before you proceed to Step 4:

1. **No agent/subagent/role references.** Never `@`-mention any agent or role
   name (`@senior-engineer`, `@staff-engineer`, `@distinguished-engineer`,
   `@security-engineer`, `@sdet`, `@ux-designer`, `@project-manager`,
   `@team-lead`, `@advisor`, or similar) in subject, body, or footer.
2. **No Docket issue IDs or issue-tracker references.** Never include a
   Docket-style ID (e.g. `DKT-123`) or a reference to any other issue
   tracker, ticket, or tracking system.
3. **No harness/orchestration metadata.** Never include task IDs, session
   IDs, model or tier names (Sonnet, Opus, Fable, Haiku, or similar),
   team/teammate names, vote IDs, or any other internal-tooling artifact.
4. **No Claude/Claude Code/Anthropic references or AI-attribution
   trailers.** Never mention Claude, Claude Code, or Anthropic in any form,
   and never add an attribution trailer (`Generated by...`,
   `Co-Authored-By: Claude`, `🤖 Generated with...`, or similar).

Mechanize the check rather than eyeballing it:

1. Write the fully drafted message (subject + blank line + body + footer, as
   it will actually be committed) to `$TMPDIR/commit-msg-draft.txt` via Bash
   (`cat > ... <<'EOF' ... EOF`, quoted heredoc so no shell expansion
   touches the message).
2. Run all four checks against that file:

   ```
   grep -niE '@(senior-engineer|staff-engineer|distinguished-engineer|security-engineer|sdet|ux-designer|project-manager|team-lead|advisor)\b' "$TMPDIR/commit-msg-draft.txt"
   grep -niE '\b[A-Z]{2,10}-[0-9]+\b' "$TMPDIR/commit-msg-draft.txt"
   grep -niE '\b(session[_ -]?id|task[_ -]?id|vote[_ -]?id|teammate|docket)\b' "$TMPDIR/commit-msg-draft.txt"
   grep -niE '\b(claude|anthropic)\b|generated (with|by)|co-authored-by' "$TMPDIR/commit-msg-draft.txt"
   ```

3. Any hit is a defect in the draft, not a false positive to explain away —
   rewrite the message to remove the offending content and re-run all four
   checks before continuing. Do not proceed to Step 4 until all four checks
   report zero matches.

## Step 3.5 — Permission-mode pre-flight (best-effort)

This step runs after Step 3 and before Step 4, because
`guard-no-commit-hook.sh` intercepts `git add` as well as `git commit` — Step
4 is the first git write in this flow, so the check must precede it, not
just precede Step 5.

Read the live permission mode from the session's own transcript JSONL (never
from a hook file, and never by writing a new file):

```bash
T=$(ls -t "$HOME"/.claude/projects/*/"$CLAUDE_CODE_SESSION_ID".jsonl 2>/dev/null | head -1)
MODE=""
if [ -n "$T" ]; then
    MODE=$(jq -rc 'select(.type=="permission-mode") | .permissionMode' "$T" 2>/dev/null | tail -1)
fi
```

Use `jq`'s `select(.type=="permission-mode")` structural match, not a bare
`grep '"type":"permission-mode"'` substring match — a substring match is
brittle against JSON key-order or content variation.

Branch on `MODE`:

1. **Hard-deny modes** (`auto`, `dontAsk`, `bypassPermissions` — the modes
   `guard-no-commit-hook.sh` denies outright). STOP; do not proceed to Step
   4. Emit:

   ```
   This session is in '<mode>' permission mode; the repo's guard-no-commit hook hard-blocks git add/commit/push there because no human can approve the write. Switch to an interactive mode (Shift+Tab, or /permissions) — default/plan/acceptEdits — then re-invoke Skill(commit). Nothing was staged.
   ```

2. **Ask-and-proceed modes** (`default`, `plan`, `acceptEdits` — the modes
   `guard-no-commit-hook.sh` interactively prompts on). Proceed to Step 4 as
   normal; no extra notice needed.

3. **Inconclusive read** (`MODE` empty, unrecognized, or the read otherwise
   failed — missing transcript file, `jq` absent, malformed JSON). Never
   hard-block on an inconclusive read; the guard hook remains the real
   enforcement and independently fails closed on an unrecognized
   `permission_mode`. Emit a one-line notice, then proceed to Step 4:

   ```
   Couldn't confirm the current permission mode from the session transcript — proceeding, relying on guard-no-commit-hook.sh's own enforcement to ask/deny as appropriate.
   ```

Two invariants:

1. **Never probe indirectly.** Do not run a dry-run/probe `git` command to
   detect the mode — the hook's exit-2 stderr on a denied probe is fed back
   to the model, so a probe "works" but burns a denied attempt, which is the
   exact failure this pre-flight exists to avoid.
2. **Advisory only.** This check is not itself the security control —
   `guard-no-commit-hook.sh` remains the sole real enforcement and
   independently fails closed regardless of what this pre-flight determines.
   Never treat this pre-flight as a substitute for the hook.

This check is independent of Step 0's authorization gate: a compliant
permission mode does not imply operator authorization, and operator
authorization does not imply a compliant permission mode. Both gates must
hold; neither substitutes for the other.

## Step 4 — Stage the scoped files

`git add -- <file1> <file2> ...` naming every path from Step 1 explicitly.
Never `git add .` / `git add -A` / a bare directory that could sweep in
unrelated changes beyond what Step 1 verified.

After staging, re-run `git diff --cached --name-only` and confirm the result
is *exactly* the intended fileset (same set, order-independent) — if it
differs, something outside this skill's control changed the index between
Step 1 and here; ABORT without committing:

```
Blocked: staged fileset does not match the intended scope after `git add`
({staged} vs {intended}) — index changed concurrently. Re-run from Step 1.
```

## Step 5 — Commit

`git commit -F "$TMPDIR/commit-msg-draft.txt"` — using `-F` against the
already-checked file avoids re-typing the message through shell quoting.

Never run `git push`. Never run `git commit --amend`. If the calling agent
asked for either, decline and point them at direct `git` usage under
explicit operator instruction — both are outside this skill's contract.

## Step 6 — Report

Emit a single confirmation:

```
Committed {short_sha}: {subject line}
Files: {file1}, {file2}, ...
```

Do not push. Do not open a PR. Do not send peer messages — the calling agent
owns next steps.

## Failure Modes

| Trigger | Handling |
|---|---|
| `<files to commit>` missing or empty | Abort: `Error: Usage: Skill(commit, "<files> [-- what changed and why]") — name the exact files to stage.` |
| Calling agent has not confirmed explicit, current operator authorization | Abort at Step 0 with the `Blocked:` authorization message. |
| Bare `.`/`-A`/`--all` pathspec passed | Abort: reject, require explicit paths. |
| Index already has unrelated staged content before `git add` | Abort at Step 1 with the `Blocked: index already has staged changes` message. |
| Fileset mixes unrelated logical changes | Abort at Step 2 (one-change guard); ask the calling agent to split into separate invocations. |
| Forbidden-content self-check (Step 3) finds any hit | Rewrite the draft and re-run all four checks; do not stage or commit until clean. |
| Session is in a hard-deny permission mode (`auto`/`dontAsk`/`bypassPermissions`) per the Step 3.5 pre-flight | Abort at Step 3.5 with the mode-mismatch notice; do not proceed to Step 4. Nothing staged. |
| `git diff --cached --name-only` mismatches the intended fileset after `git add` | Abort at Step 4 with the `Blocked: staged fileset does not match` message; re-run from Step 1. |
| `git commit -F` fails (hook rejection, empty diff, permission denial) | Surface the raw `git` error; do not retry with `--no-verify` or any other bypass. |
| Calling agent asks for `git push` or `git commit --amend` | Decline — outside this skill's contract; direct them to explicit direct `git` usage under operator instruction. |
