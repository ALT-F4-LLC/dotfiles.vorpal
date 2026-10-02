# Naming convention for this corpus

This file is authoring-facing documentation, not an engine or wave.js
input. It states the naming shape every definition in this directory
follows, so a future addition or edit stays consistent with the rest of
the corpus.

## Executors

An executor name is the canonical identity for a piece of work: `<role>`
or `<role>-<domain>`, kebab-case (`verify-ac`, `judge-correctness`,
`tdd-author`). A step naming exactly one executor never inverts or
partially drops that executor's name: no `author-tdd` for executor
`tdd-author`, no `verify` for executor `verify-ac`. An executor may be
position-named (`fix`, `revise-investigation`) when the position is
genuinely its own distinct identity, as `fix` already differs from
`implement`.

The contract file stem always equals the executor name
(`contracts/<executor>.md`), so `packet = ["contracts/{executor}.md", ...]`
resolves for every executor without a literal path, except the one
documented exception below.

**Named exception (an executor family sharing one contract file):**
`spec-author-<axis>` (seven policy rows: architecture, security,
operations, performance, code-quality, review-strategy, testing) shares
one file, `contracts/spec-author.md`, referenced by the literal path
`packet = ["contracts/spec-author.md", ...]`. These seven executors differ
only in their axis, which selects the reserved output path they may write
and the specialist and evidence focus the contract assigns; the content
is genuinely one contract. No other executor may join this exception
without updating this file.

Voter-only executors (seated only via a vote step's `voters` list, with no
packet of their own) are named `<lens>`, matching the review-executor lens
they stand in for when one exists: `tribunal-architecture`,
`tribunal-correctness`, `tribunal-design`, `tribunal-security`. Their
`tribunal-` prefix distinguishes the vote-time identity (defined in
tribunal.js's LENSES table) from the `judge-`-prefixed review executor of
the same lens.

## Gates, vote rules, policy variants, labels

Already kebab-case, already `<role>` or `<role>-<qualifier>` shaped
throughout this corpus (`ac-commands`, `secret-scan`,
`security-classifier-reroute`, `opus-medium`, `security-change`,
`blocked`). This file states the shape for new additions; it does not
mandate renaming anything that already conforms.

Most gate names are this repo's own `just` recipes. The three light tracks
(docs-only, trivial-change, small-change) bind on a label alone, so each
carries a `diff-scope-<track>` gate on implement and fix that refuses a
working-tree footprint the label does not promise (`.docket/bin/diff-scope`);
a repository bound to the corpus supplies those three recipes like any other
gate. A gate a workflow names that this repo doesn't provide belongs to the
target project instead: `ui-change.toml`'s `render-verify` and
`copy-verify` are supplied by whatever repository's own justfile the
workflow runs against, not by this one. `.docket/bin/crossref-check`'s
`PROJECT_GATES` list is the authority for which gate names are cross-repo
by design; a gate absent from both `just --summary` and that list is
drift, not a deliberate exception.

Routing labels form one family, `route-<destination>`, and an issue carries
at most one: `route-run` (a docket-plan run, the only value a workflow may
bind), `route-direct` (the operator's own session, through brief),
`route-tend` (the docket-tend queue), `route-loop` (a scheduled loop).
docket-groom sets them from the brief skill's route rules; brief files
`route-tend` issues under its own rule 5, and docket-plan adds `route-run`
when it records a run. docket-plan's bare mode selects on `route-run`
alone. Every workflow lists the other three in `unless_labels`, so a
routed-away issue matches zero workflows until the label changes, exactly
as `blocked` does. An issue with no routing label is unrouted, not run
work.

## What this convention does not cover

Contract, fragment, and schema prose content (severity ladders, provenance
vocabularies, house-style rules) is a matter of contract authoring, not
naming identity, and is out of scope here. `cut-ledger.json` at this root
is the docket-prune skill's verdict ledger, and `changelogs/<name>.md` holds
each workflow's and `policy.toml`'s version history, newest first; neither
is a definition. The engine reads only the five subtrees and `policy.toml`,
pins these two by content hash like every file under this root, and the
crossref and frozen-drift gates never scan them. Every contract's
H1 is the fixed literal `# Charter`; the definition's actual name lives in
its YAML frontmatter `node:` field, not the heading.
