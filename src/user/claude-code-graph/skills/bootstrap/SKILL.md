---
name: bootstrap
description: Draft a complete .docket/config/ for a repo that has none — mine the repo, adapt a shipped template, propose trust entries, and surface the whole binding for approval before the first run. Use at project start, or when `docket run activate` reports no workflow matches an issue.
---

# bootstrap

You draft this repo's instance config. The developer provides work and
approvals; you do everything else. `.docket/config/` is machine-authored and
nobody hand-edits it after.

Two rules you must not fight:

- **Never run `workflow register` or `schema register`.** Activation
  auto-registers `.docket/config/`, schemas before workflows. Registering by
  hand freezes a `name@version` before the human has seen it.
- **Never add a trust entry before the human approves it.** You propose; they
  say yes; then you run `trust add --yes`.

## 1. Start from the template

```bash
docket init                                   # if .docket/ does not exist
docket workflow init --template standard-dev  # or parallel-check
```

`standard-dev` is check-then-approve, one fenced gate. `parallel-check` is
prepare → parallel checks → summarize → verify. Pick by the repo's shape.

## 2. Mine the repo

Read, don't guess. Every adaptation in §3 cites something you found:

Build files (`Makefile`, `justfile`, `package.json`, `Cargo.toml`, `*.nix`) and
CI config give you the real check command — the one a contributor actually
runs, and the ones that gate merges today. `README`/`CONTRIBUTING` give the
review shape: who approves, how many. `git log --format='%s' -50` gives
conventions and cadence. The test/doc layout tells you what a change touches,
for `scope` and `class`.

Run the check command once yourself. A command you have not seen exit 0 is a
guess, not a gate.

## 3. Adapt

Rewrite the template into `.docket/config/`:

- `workflows/<name>.toml` — named for the repo's work, `version = 1`, steps
  reflecting the real review shape.
- `schemas/<name>@1.json` — only if a threshold consumes a step's `payload`.
  **A payload schema describes an array**: `type: "array"` with the object
  under `items`. An object-shaped schema registers, then fails workflow
  validation with "declares no top-level properties." Ordered fields need
  `"ordered_enum": true` or `>=` is refused.
- `policy.toml`, `contracts/`, `fragments/`, `templates/` — pinned, registered
  as nothing. Instance knowledge lives here, including the fenced-check
  convention: a gate declaring `source = "fence:checks"` harvests ` ```checks `
  blocks from the issue body, one command per line, at activation only.

Head each generated file with a comment naming what you mined and the date —
that is what makes the next retro's diff legible.

## 4. Propose trust — do not add it

For each command a gate will run, propose the entry and argue every flag from
what you read:

```
name         checks
argv         make check
re-runnable  yes — the scripts only read docs/ and print; safe after a crash
tree         no  — writes nothing in the working tree
flaky        no  — no network, no clock; deterministic exit code
```

Default every flag **off** and justify turning it on. `--tree` wrong lets a
build race a parallel read step. `--re-runnable` wrong parks an interrupted
gate on a human. `--flaky` on a deterministic command hides a real failure
behind a retry. Never propose `--global`; propose `--prefix` only when the argv
genuinely varies, and say plainly that it over-authorizes.

## 5. Surface the binding — the approval moment

```bash
docket run start --issue DKT-1
docket run activate RUN-1 --dry-run --pin .docket/config/policy.toml
```

`--dry-run` computes the whole activation and writes nothing. It prints what
registers, what pins, and **every harvested command verbatim**, annotated
`matched` or `unmatched`. Show that output, not a summary of it. Before trust
exists the command reads `(unmatched)` — the correct state to present: this is
what would run, and nothing yet authorizes it.

Ask for approval of the config and the trust proposals together. On yes:

```bash
docket trust add checks --re-runnable --yes -- make check
docket run activate RUN-1 --dry-run --pin .docket/config/policy.toml
```

The second dry-run must read `(matched: checks)`. Still unmatched means the
argv differs from the fence line byte-for-byte — fix the entry, not the issue.

Then ask again, for the activation itself, and run it without `--dry-run`.
Two approvals: one for what you wrote, one for what runs.

## 6. Hand off

Report the config files you wrote, the trust entries they approved, and the run
you activated. `.docket/config/` is git-versioned and machine-authored: changes
go through a version bump, because changed bytes at an unchanged `name@version`
refuse the next activation outright.

Activation's refusals name the file and the fix; follow them literally. Two
worth pre-empting: an issue matching zero workflows is a `[match]` too narrow —
widen it, never label the issue to fit — and an issue matching several is
resolved with `unless_labels` on the loser, which evaluates last and wins.
