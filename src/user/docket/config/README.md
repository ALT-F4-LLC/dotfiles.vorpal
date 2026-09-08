# Naming convention for this corpus

This file is authoring-facing documentation, not an engine or wave.js
input. It states the naming shape every definition in this directory
follows, so a future addition or edit stays consistent with the rest of
the corpus without re-deriving the reasoning each time.

## Executors

An executor name is the canonical identity for a piece of work: `<role>`
or `<role>-<domain>`, kebab-case (`verify-ac`, `judge-correctness`,
`tdd-author`). A step naming exactly one executor never inverts or
partially drops that executor's name — no `author-tdd` for executor
`tdd-author`, no `verify` for executor `verify-ac`. An executor MAY be
position-named (`fix`, `revise-investigation`) when the position is
genuinely a distinct identity of its own, the way `fix` already differs
from `implement`.

The contract file stem always equals the executor name
(`contracts/<executor>.md`), so `packet = ["contracts/{executor}.md", ...]`
resolves for every executor without a literal path — except the one
documented exception below.

**Named exception — an executor family sharing one contract file:**
`spec-author-<axis>` (seven policy rows: architecture, security,
operations, performance, code-quality, review-strategy, testing) shares
one file, `contracts/spec-author.md`, referenced by the literal path
`packet = ["contracts/spec-author.md", ...]`. These seven executors
differ only in which of seven reserved output paths they may write; the
content is genuinely one contract. No other executor may join this
exception without updating this file.

Voter-only executors (seated only via a vote step's `voters` list, no
packet of their own) are named `<lens>`, matching the review-executor
lens they stand in for when one exists: `tribunal-architecture`,
`tribunal-correctness`, `tribunal-design`, `tribunal-security` — their
`tribunal-` prefix distinguishes the vote-time identity (defined in
wave.js's/tribunal.js's shared LENSES table) from the `judge-`-prefixed
review executor of the same lens.

## Steps

A step that runs exactly one executor takes that executor's name, for its
first-pass appearance in a workflow. A loop-back pass of the same work is
a second `[[step]]` entry and needs its own name (the engine rejects two
steps sharing a `name` within one workflow) — named after its executor
when that executor's identity is unique to the loop-back role (`fix`
relative to `implement`), otherwise `revise-<what it revises>` (an
artifact kind: `revise-spec`; a doctype: `revise-tdd`, `revise-adr`,
`revise-ux-spec`, `revise-prd`, `revise-tdd-security`; a domain:
`revise-disposition`, `revise-investigation`).

A fanout or vote step that runs multiple executors is named after its
pipeline ROLE, never any one member's name (`review` for the judge
fanout, `spec-author` for the seven-way author fanout — a role name never
collides with a member executor's own name).

## Vote steps

Every vote/gate step is named `<role>-vote`, where `<role>` is the step,
stage, or doctype the vote gates: a step name (`verify-ac-vote`,
`review-vote`, `report-vote`), a stage with no single gated step
(`security-vote`), or a doctype for a per-doctype acceptance gate
(`tdd-vote`, `adr-vote`, `ux-spec-vote`, `prd-vote`, `spec-vote`).
`<role>` is never a voter's own name. One vote step gates one role; a step
that would otherwise gate two unrelated roles under one name (selected by
mutually exclusive `when` clauses) splits into two vote steps instead, so
each name states what it gates.

## Artifact kinds

`emits`, `payload`, and free-form `<kind>` labels in `inputs` are
kebab-case: singular for one artifact per production (`change-summary`,
`ac-report`, `disposition`, `threat-model`, `spec`, `doc`), plural for a
collection artifact (`findings`, `research-notes`, `proposals`). A
multi-word kind compounds as `<noun>-<qualifier>`; `-report` is reserved
for a step's own top-level verdict artifact (`ac-report`,
`drain-report`).

A document-producing contract's engine `emits` kind stays the generic
`doc` when a consuming step reads it back generically via
`issue.latest.doc` (the engine's `issue.latest.<kind>` grammar has no
wildcard form, so a generic consumer needs a generic kind). Each such
contract's `# Emit` section states both the engine kind (verbatim `doc`)
and the specific document type it produces, so a reader sees the mapping
without the engine needing to distinguish them.

## Gates, vote rules, policy variants, labels

Already kebab-case, already `<role>` or `<role>-<qualifier>` shaped
throughout this corpus (`ac-commands`, `secret-scan`,
`security-classifier-reroute`, `opus-medium`, `security-change`,
`blocked`). This file states the shape for new additions; it does not
mandate renaming anything that already conforms.

## What this convention does not cover

Contract, fragment, and schema PROSE content — severity ladders,
provenance vocabularies, house-style rules — is a matter of contract
authoring, not naming identity, and is out of scope here. Every
contract's H1 is the fixed literal `# Charter`; the definition's actual
name lives in its YAML frontmatter `node:` field, not the heading.
