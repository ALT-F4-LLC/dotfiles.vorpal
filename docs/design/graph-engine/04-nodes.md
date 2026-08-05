# 04 — Nodes: contracts, knowledge, inventory

Status: approved — 2026-08-02. Nodes are the only place model judgment happens (AC-1). This document
defines the contract format, the knowledge-fragment system, the full node inventory with
its parity mapping to the current fleet, and three exemplar contracts in full.

## 1. What a node is

A node is a **task-typed unit of judgment** with a versioned prose contract. It has no
persistent identity, no memory, no lifecycle beyond one invocation, and no knowledge of
the graph: it receives a brief (02 §8) and returns an artifact. The engine records,
gates, and routes; the node only judges.

Contracts are data, not agent definitions: they live in `.docket/config/contracts/`
(machine-authored, T9), are hash-pinned per run at activation via generic file pins
(06 §2), and reach nodes through the context bundle rendered by
`docket step claim --render` (02 §8). The harness-side executor archetypes (03 §4) are content-free.

## 2. Contract format

```markdown
---
node: judge-security          # id, referenced by pipelines
version: 3                    # briefs pin it; runs record it
archetype: executor-read      # tool surface (03 §4)
fragments:                    # knowledge inlined into the brief, in order
  - severity-ladder-security
  - evidence-rules
emits: findings               # artifact kind
payload: findings@1           # registered schema, only if code consumes it (02 §6)
---
# Charter
One paragraph: the single kind of judgment this node performs.

# Not
What this node must not do — the boundary that keeps it narrow. (The best-performing
contracts teach the discrimination with a failing example, not with emphasis.)

# Method
The substantive domain knowledge: what to examine, in what order, what distinguishes a
real finding from noise. This is where the old roles' expertise lives on.

# Emit
The exact shape of the markdown artifact (sections, ordering) and, if a payload is
declared, what goes in it vs. in prose.

# Stuck
What to do when the task cannot proceed: emit a `gap` artifact stating what is missing
and stop. Never guess, never widen scope, never fake progress.
```

Rules: 3–5KB body target (a size *diagnostic*, not a ceiling with excuses — E-5 says
bytes here are ~1% of cost; the target exists for editability); no workflow content (when
you run, who runs after you — pipeline's job); no protocol content (how to report, how to
shut down — engine/runtime's job); no duplicated doctrine (shared knowledge goes in
fragments). A contract edit is one file + version bump; in-flight runs are pinned (T7).

## 3. Knowledge fragments

Fragments are the distillation target for the current fleet's genuinely valuable content —
the domain expertise buried between protocol blocks. Each is a small markdown file,
versioned, inlined by the engine wherever a contract declares it (no pointers, E-6).

| Fragment | Distilled from (current corpus) |
|---|---|
| `code-philosophy` | senior-engineer's 12 principles + override convention |
| `laziness-ladder` | team-doctrine/laziness-discipline (6-rung YAGNI) |
| `truth-first` | truth-first-debugging (OBSERVED/REPRODUCED/INFERRED labeling) |
| `evidence-rules` | code-review-verdict/evidence-gates (anti-fabrication, false-signal tests) |
| `hard-gates` | code-review-verdict/hard-gates (G1–G5 discriminations) |
| `severity-ladder-general` | staff/code-review-verdict ladder |
| `severity-ladder-security` | security-engineer ladder (kept distinct — the vocabularies bled once) |
| `security-review-dimensions` | security 9-dimension checklist |
| `threat-model-method` | security-engineer Shostack 4Q method |
| `hig-principles` | ux-designer's 8 HIG principles + WCAG 2.2 AA floors |
| `copy-discipline` | ux copy-literal rules (grep-verifiable acceptance surface) |
| `tdd-discipline` | agents/sdet.md §Testing Philosophy (red-green at sdet.md:110): red-first, AC-fail-first, no test-weakening *(source corrected 2026-08-05 — skills/tdd is the design-doc authoring skill and carries none of this; found by M2b batch 1)* |
| `scope-discipline` | senior-engineer.md principle 9 + the exemplars' own # Stuck honest-gap doctrine + sdet.md:168's undeclared-scope judgment: touch only declared scope, gap out otherwise *(sources named 2026-08-05 — the row previously named no file; M2b batch 1)* |
| `doc-house-style` | adr/prd/tdd/ux-spec section conventions (validators enforce structure; this carries taste) |
| `vorpal-toolchain` | vorpal-tools (pinned tool notes) |
| `writing-for-humans` | report-writing conventions worth keeping (minus banned-phrase lists — T5 removed their cause) |

What does **not** become a fragment: shutdown protocols, liveness doctrine, communication
discipline, envelope hygiene, retry rules, sandbox-recovery tables, monitor orchestration,
runtime discipline — all either engine mechanisms now or deleted (07 maps every one).

## 4. Node inventory (parity backbone)

Every judgment the fleet performs today, as a node. "Distilled from" is the parity claim;
07 §3 inverts this table to prove nothing is dropped.

| Node | Archetype | Judgment it owns | Emits | Distilled from |
|---|---|---|---|---|
| `plan` | (in-session skill) | Intake conversation → work DAG + scopes + ACs | plan + issues | brief skill, project-manager, team-lead pattern routing |
| `prd-author` | write | Product requirements | prd doc | prd skill, project-manager |
| `tdd-author` | write | Technical design | tdd doc | tdd skill, distinguished/staff-engineer |
| `tdd-author-security` | write | Security-track technical design | tdd doc | security-engineer TDD duties |
| `adr-author` | write | Decision records | adr doc | adr skill, staff-engineer |
| `ux-spec-author` | write | UX specification (incl. copy literals) | ux-spec doc | ux-spec skill, ux-designer |
| `spec-author` | write | One of the seven project spec files | spec doc | init-specs (pipeline spawns ×7) |
| `threat-model` | read | Threat model (4Q) for security-load-bearing work | threat-model | security-engineer |
| `implement` | write | Code change for one issue | change-summary | senior-engineer (exemplar below) |
| `fix` | write | Repair addressing reconciled findings | change-summary | senior/impl-fix loops |
| `test-infra` | write | Test infrastructure/fixtures | change-summary | sdet infra mode |
| `judge-correctness` | read | Defects: logic, boundaries, error handling | findings | code-review-verdict general dims, hard-gates |
| `judge-architecture` | read | Design conformance, coupling, plan conformance | findings | staff-engineer review duties |
| `judge-security` | read | Vulnerabilities and security regressions | findings | security-engineer review (exemplar below) |
| `judge-testing` | read | Test adequacy/honesty, flakiness risk | findings | sdet review lens |
| `judge-simplicity` | read | Overbuild, dead scaffolding, philosophy violations | findings | simplify-scout, laziness-discipline |
| `judge-design` | read | Spec/HIG conformance of UI changes | findings | ux-designer design-review |
| `synthesize-findings` | read | Cluster duplicate findings across judges | clusters | (reconciliation's judged half, 02 §6) |
| `verify-ac` | read | Per-AC met/unmet/unverifiable with evidence | ac-report | verify-ac skill, sdet (exemplar below) |
| `design-qa` | read | Shipped surface vs ux-spec | findings | design-qa skill, ux-designer |
| `investigate` | read | Root-cause analysis, reproduction | investigation | truth-first-debugging, DE investigator |
| `research` | research | External evidence gathering (verbatim-quoted) | research-notes | DE research mode, docs-research |
| `commit-author` | read | Commit message drafting | commit-message | commit skill (execution stays gated, 03 §5) |
| `pr-comment-author` | read | Inline PR comments in operator's voice | comment-set | review-and-comment (posting = human gate + gh gate) |
| `retro-analyst` | read | Mine run ledgers → propose contract/pipeline/policy edits | proposals + issues | evolve-* suite, five skills (05 §6) |

Twenty-five nodes. Deliberate non-nodes: reconciliation, gates, doc validation, metrics,
promotion, dispatch, votes-counting — deterministic (02); `synthesize-findings` may
collapse into reconciliation-adjacent tooling if measured clustering variance stays
tolerable at small fan-out (08 D3).

## 5. Exemplar contracts

### 5.1 `implement`

```markdown
---
node: implement
version: 1
archetype: executor-write
fragments: [code-philosophy, tdd-discipline, scope-discipline, truth-first, vorpal-toolchain]
emits: change-summary
---
# Charter
Make the code change described by one issue: satisfy its acceptance criteria within its
declared scope, test-first, leaving the tree building and the tests green.

# Not
You do not choose what to build (the issue does), review your own work's acceptability
(judges do), expand scope to fix adjacent problems (file a gap instead), or touch
workflow state beyond your own step.

# Method
Read the issue's acceptance criteria before any code. For each AC that is expressible as
a test, write the failing test first and observe it fail; an AC that passes before your
change is evidence the issue is mis-stated — emit a gap, do not proceed. Implement the
smallest change that satisfies the ACs under the code-philosophy fragment. Run the
project's build and test commands and include their real output in the summary. If an AC
is untestable as written, say so explicitly in the summary rather than approximating it.

# Emit
`change-summary` (markdown): Files changed (with one-line why each) · ACs addressed
(AC → test/evidence mapping, with observed pre-fail and post-pass output) · Decisions
made where the issue left latitude · Known limits (anything a reviewer should probe).
Do not restate the diff; the engine snapshots it.

# Stuck
Missing input, contradictory ACs, scope too narrow for a correct fix, or an environment
failure you cannot resolve in two attempts: emit a `gap` artifact naming exactly what is
missing and what you recommend, then stop. An honest gap is a success condition; a
workaround that hides one is a defect.
```

### 5.2 `judge-security`

```markdown
---
node: judge-security
version: 1
archetype: executor-read
fragments: [severity-ladder-security, security-review-dimensions, evidence-rules, truth-first]
emits: findings
payload: findings@1
---
# Charter
Examine one change for security defects: vulnerabilities introduced, protections
weakened, trust boundaries crossed unparsed, secrets exposed, and abuse cases enabled.

# Not
You do not assess general code quality (other judges own it), fix anything, soften a
finding because the code is otherwise good, or issue a verdict — you emit findings only;
acceptance is computed from the reconciled set, not asserted by you.

# Method
Work the security dimensions fragment in order against the diff and its blast radius:
input handling at every trust boundary, authn/authz changes, secret and credential flow,
injection surfaces, unsafe deserialization, resource exhaustion, dependency risk, error
and logging leakage, and regressions of existing mitigations. For each candidate finding
apply the evidence rules: cite the exact location, state what an attacker does and what
they gain, and label the claim OBSERVED (you traced it) or INFERRED (you suspect it,
with the cheapest probe that would confirm). Absence of findings in a dimension is
reported as examined-clean, not silence.

# Emit
`findings`: markdown body with one section per finding (location · mechanism · impact ·
evidence label · suggested direction), plus the findings payload — one entry per finding
with severity from the security ladder fragment. Severity reflects exploitability and
blast radius, not effort to fix. If you examined everything and found nothing, emit the
examined-clean report; an empty payload is a valid, meaningful result.

# Stuck
If the brief lacks the context to judge a boundary (e.g. the caller of changed code is
outside the provided artifacts), emit your findings plus a `gap` note naming the missing
context — never assume it safe, never guess it dangerous.
```

### 5.3 `verify-ac`

```markdown
---
node: verify-ac
version: 1
archetype: executor-read
fragments: [evidence-rules, truth-first, scope-discipline]
emits: ac-report
payload: ac-report@1
---
# Charter
Determine, one acceptance criterion at a time, whether the change satisfies it — with
evidence a skeptic could re-run.

# Not
You do not re-review code quality (judges did), weigh intent ("clearly meant to…"),
verify against any design document (the issue body is the sole authority — if it is
insufficient, that is a gap in the issue, and your report says so), or change any state.

# Method
For each AC in the issue body: classify it — command-verifiable (the engine executed
the fenced AC commands as *pre-gates at claim*; their recorded results are in your
context bundle — read them rather than re-running what you cannot observe), statically verifiable (trace the diff and cite file:line), or
runtime-only (mark unverifiable-static; never substitute a static proxy for a runtime
claim). Then judge met / unmet / unverifiable with the evidence attached. An AC whose
gate command passed but whose intent is visibly unmet by the diff is `unmet` — say why;
the arithmetic trusts you to judge intent, the gates cover the literal.

# Emit
`ac-report`: markdown body with one section per AC (classification · evidence ·
judgment), plus the ac-report payload (per-AC: id, status ∈ met|unmet|unverifiable).
Routing is computed from the payload and the gate results; you draw no overall verdict.

# Stuck
ACs missing, ambiguous, or contradictory: report per-AC `unverifiable` with the specific
defect in the AC's wording. A bad AC is a planning defect to surface, not a puzzle to
interpret charitably.
```

## 6. What replaces role memory

The fleet's per-role memory files (pitfalls ledgers, agent-memory) were the containers
for lessons. Their replacement is structural: recurring *process* failures become pipeline
or policy edits; recurring *judgment* failures become contract or fragment edits — both
proposed as ordinary issues by `retro-analyst` reading the run ledger (05 §6), reviewed
like any change, and versioned. A lesson that cannot be expressed as an edit to a
contract, fragment, pipeline, policy, or gate is a lesson the system cannot yet hold —
it goes in an issue, not in a memory file nobody re-reads. Authorship follows T9
throughout: the bootstrap skill drafts first-version contracts and fragments from the
repo's own history and conventions; retro proposes their evolution; the human approves
in conversation and hand-edits nothing.
