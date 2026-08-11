---
name: commit
description: Turn the working tree into clean conventional commits — survey every change, split unrelated work into separate logical commits, guard against junk and secret-shaped files, and commit immediately without asking. Use on "commit", "commit this", "commit my changes", "make a commit", "/commit". Lands commits only; never pushes.
---

# commit

You turn the current working tree into conventional commits and land them
without ceremony. Survey, group, guard, commit, report — the tree answers the
questions, not the operator.

**Commit immediately.** No draft-for-approval step. A wrong message is one
amend away; an ungated commit costs seconds, a gated one costs a round-trip.

**Never push.** Landing is this skill's job; publishing is the operator's.

**Never bypass hooks.** No `--no-verify`. A hook that rewrites files (a
formatter) gets its edits restaged and one retry; a hook that rejects gets its
output reported and the remaining groups stay uncommitted.

**No attribution trailers.** No `Co-Authored-By`, no `Generated with` — the
log carries the change, not the tooling.

## 1. Survey

```bash
git status --porcelain=v2 --branch
git diff; git diff --cached; git log --oneline -5
```

Read the diffs, not just the filenames — grouping and messages both come from
what changed, and the recent log calibrates scope names. Already-staged
changes are input like everything else; the index is state to incorporate, not
an instruction to preserve. Mid-merge, mid-rebase, or mid-cherry-pick: stop
and say so — finishing that state is not this skill's call. Nothing to
commit: say so and stop; never manufacture a commit.

An argument is an intent hint — `/commit just the parser fix` commits the
changes matching the hint and leaves the rest in the tree, named in the
report.

## 2. Group

One commit per logical unit, grouped by intent rather than by directory:

- A change rides with its tests and the docs it invalidated — one commit.
- Unrelated fixes are separate commits even when they touch one file's
  neighborhood; a mechanical sweep (rename, format, generated output) is
  separate from the behavior change that prompted it.
- A file belongs to exactly one commit. Never hunk-split a file across
  commits — when one file genuinely carries two units, commit it with the
  dominant one and say so in that body.
- Order groups so dependencies land first; every intermediate commit should
  leave the tree consistent.

One unit in the tree means one commit — splitting is for unrelated work, not
a quota.

## 3. Guard

Untracked files join a group only when the diff shows they are part of the
work. Never add:

- **Secret-shaped files**: `.env*`, `*.pem`, key/credential/token files —
  regardless of what the work was. And when a *tracked* diff carries what
  looks like a live secret, that group does not commit at all: stop it,
  commit the clean groups, report the finding.
- **Junk**: build outputs, caches, logs, `.DS_Store`, editor droppings —
  candidates for the repo's `.gitignore`, not for a commit.

Name everything skipped in the report. Silence reads as "everything landed."

## 4. Message

Conventional commits in every repo, regardless of what its history does:
`type(scope): summary` — types `feat fix docs refactor test perf build ci
chore`, scope from the area touched (match the repo's existing scope
vocabulary when the log shows one), summary imperative, ≤ 72 chars, no
trailing period.

**Simple and human readable. Paragraphs are not allowed.** Most commits are
a subject line alone. When the subject cannot carry the why, the body is
short `- ` bullets — one plain fact each, never prose paragraphs, never a
file list.

**Plain language, self-contained.** A message must make sense to a reader
with no session context: no issue-tracker IDs (`DKT-12`, `RUN-3`), no
harness or agent vocabulary (wave, executor, shadow, conductor, agent
names), no "operator policy" citations. Say what changed and why in ordinary
words — the tracker knows its IDs; the log should not need them.

## 5. Commit

Per group, in dependency order:

```bash
git add <exact paths>        # named paths only — never -A, never .
git diff --cached --stat     # staged set matches the group, nothing extra
git commit -m "$(cat <<'EOF'
type(scope): summary

- bullet only when the subject is not enough
EOF
)"
```

Confirm each landed (`git log --oneline -1`) before staging the next group. A
hook rejection stops the line: report which commits landed, which groups
remain in the tree, and the hook's output verbatim.

## 6. Report

One plain-language summary: each commit's hash and subject, what was skipped
and why, anything flagged by the guard. State that nothing was pushed.
