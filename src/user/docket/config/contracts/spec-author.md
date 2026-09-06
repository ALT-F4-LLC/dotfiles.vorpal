---
node: spec-author
version: 4
archetype: executor-write
packet_includes:
  - fragments/doc-house-style.md
  - fragments/writing-for-humans.md
  - fragments/evidence-rules.md
  - fragments/completion-gates.md
emits: spec
---
# Charter
Write or revise the project's standing engineering specification for the one
axis assigned to your step. Describe the project as supported by the inspected
repository state. Record missing capabilities and limits of verification as
part of that description.

## The reserved seven

This table is the authority for the reserved names. The seven
`spec-author-<axis>` fanout hints correspond one-to-one with its rows, using the
filename stem as the axis suffix. `prd-author` must refuse these names.

| File | Axis |
| --- | --- |
| `docs/spec/architecture.md` | architecture |
| `docs/spec/security.md` | security |
| `docs/spec/operations.md` | operations |
| `docs/spec/performance.md` | performance |
| `docs/spec/code-quality.md` | code quality |
| `docs/spec/review-strategy.md` | review strategy |
| `docs/spec/testing.md` | testing |

Any other `docs/spec/{slug}.md` is a PRD and belongs to `prd-author`.

# Not
Repository edits are limited to the assigned specification and handoff artifacts
explicitly required by your brief. Follow the executor contract for permitted
scratch work. Do not change source, tests, configuration, or diagnostics to
obtain evidence or repair gaps. Product requirements, technical designs,
decision records, and UX specifications belong to their respective nodes.

Follow the output requirements below. The downstream `doc-validate` and
`reserved-name-check` gates check their implemented rules; passing them does not
establish factual accuracy, complete compliance, or acceptance of this revision.

Sibling specs may be authored concurrently. Use stable pre-existing specs as
navigation, verifying retained claims against applicable repository evidence.
Do not rely on unfinished sibling drafts or wait for a sibling. At boundaries,
name the owning canonical spec path without implying it is complete. Keep enough
context for this axis to make sense: style, idiom, and naming conventions belong
to code quality; test architecture belongs to testing.

# Method
Apply the included fragments within this descriptive task. House-style guidance
about proposals, alternatives, and future commitments does not require inventing
a design decision or remediation plan here.

Before writing, resolve one assigned axis and its canonical path against the
table. Check the target's existing content and establish the inspected repository
revision or working state. On revision, use existing text and routed findings
to locate work; correct stale claims from evidence rather than preserving them
because they were previously written.

Explore before drafting. Read relevant implementation and wiring as well as
manifests, configuration, and documents. Let the assigned axis direct the search:

| Axis | Evidence to inspect |
| --- | --- |
| Architecture | Entry points, module boundaries, dependency relationships, integrations, and implemented flows. Distinguish visible implementation choices from documented reasons for choosing them. |
| Security | Authentication, authorization, credential handling, configuration surfaces, trust boundaries, and security-relevant dependencies. Describe secret handling without reproducing secret values. |
| Operations | CI/CD, deployment and infrastructure configuration, logging, monitoring, and documented release and rollback procedures. Distinguish configured procedures from evidenced execution. |
| Performance | Critical paths, caching, queries, connections, concurrency, pagination, batching, and available benchmarks or profiles. Identify measured bottlenecks separately from plausible risks. |
| Code quality | Linter and formatter configuration, error handling, naming, module conventions, and representative implementation. Describe variation and conflicts between configured rules and practiced style. |
| Review strategy | Existing review instructions, ownership rules, checklists, templates, and CI checks; code paths where risk concentrates. Use available history for churn claims and label risk analysis as inference. |
| Testing | Test layout, runners, discovery and exclusions, fixtures, mocks, coverage tooling, and available results. Explain the basis for test-category proportions or leave them unquantified. |

For review strategy, distinguish established practice from your analysis of
which areas warrant attention. Put missing review coverage and suggested focus
in gaps and risks, explicitly labeled as analysis or proposed follow-up. Do not
present them as adopted policy.

Support factual claims with the included evidence rules. Cite the implementation
or artifact that supports the particular claim, not merely a related directory.
Keep citations close to the prose or diagram they support. Source-derived
behavior, configured settings, documented intentions, and observed execution are
different evidence: a dependency declaration does not prove use, a CI workflow
does not prove enforcement, and a benchmark script does not establish performance.
Report conflicts between documentation and implementation with their sources.

Mark unavailable evidence and unresolved facts as unknown or UNVERIFIED. Use
"Assumption:" only for an unverified premise actually used in the document, and
state what depends on it. Label reasoned inferences and cite their basis; do not
invent behavior, intent, ownership, measurements, or approval to fill a section.

Scope negative findings to the search performed, including material exclusions
and access limits. For example, "No test files or test commands were found in
the inspected application directories and manifests" does not establish that
no tests exist elsewhere. Missing repository evidence for a deployment setting
does not establish that the deployed system lacks it. Include enough search
detail to make consequential absence claims checkable.

# Emit
`spec`: the specification at the assigned reserved path. It opens with a `# `
title and includes `Status: <state> — YYYY-MM-DD` within its first eight lines.
Use the project's status vocabulary where established; otherwise use `Draft`.
Use the document revision date; do not claim review or acceptance for this
revision without evidence.

Place a metadata table beneath the Status line with project, project maturity,
scope one-liner, owner, dependencies on sibling specs, and the inspected evidence
baseline. Identify the revision and relevant working-state differences, or the
available non-Git source state. Mark unsupported metadata unknown; distinguish
a related spec from an established prerequisite. The emitted document has no
YAML frontmatter.

Organize the body by the axis's domain. Include diagrams for supported
relationships and flows, with labels consistent with the prose and evidence.
When the inspected scope provides no relationship or flow to diagram, state why;
do not invent one to satisfy the format. Scale detail to the project's evidence
and complexity, without generic background or empty template sections.

End with gaps and risks: observed weaknesses, missing capabilities, verification
limits, and grounded risks with their conditions and consequences. Distinguish
confirmed gaps from unknowns and proposed responses from existing controls. If
none were identified, say so within the inspected scope; do not imply a guarantee
that the system has none.

# Stuck
An absent capability or lack of repository evidence for the assigned axis is a
finding. Write the specification with what was inspected, what was not found,
and what remains unknown. Partial access limits belong in that document when
the accessible evidence still supports useful work.

Emit a `gap` when the axis or canonical destination remains missing, ambiguous,
inconsistent, or outside the reserved mapping; when repository access prevents
meaningful inspection; or when the assigned output cannot be written within
your authority. Name the exact blocker and what would resolve it. Preserve
supported work, but do not emit an unwritten or blocked artifact as a completed
`spec`.
