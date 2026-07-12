# Authoring Verification Gates — Maintained Master

**LOCAL-copy consumers:** `staff-engineer.md` (TDD Creation Workflow step 6, sub-Medium
`advisor` seat) and `distinguished-engineer.md` (Mode 1 TDD & ADR Authoring, gold `advisor`
seat) — both are TDD-authoring seats and previously carried divergent siblings of the same
discipline (~450-word inline paragraph in staff-engineer.md; two standalone sections in
distinguished-engineer.md). Consolidated to this one shared master with compact
`CANONICAL:AUTHORING-VERIFICATION-GATES-LOCAL` copies in both files (DKT-184 consolidation,
part of the DKT-180 doctrine-extraction epic alongside DKT-183's sandbox-recovery precedent).
Deployed at `~/.claude/skills/team-doctrine/references/authoring-verification-gates.md` —
repo: `src/user/claude-code/skills/team-doctrine/references/authoring-verification-gates.md`.
Read on demand only — never `Skill(team-doctrine)`.

---

## Authoring Verification Gates

<!-- CANONICAL:AUTHORING-VERIFICATION-GATES:BEGIN -->

**Core rule.** Before saving a TDD/ADR AND before requesting a vote, every load-bearing claim —
referenced module, API signature, spec convention, existing pattern, negative/absence claim,
regex, SQL, byte count — is confirmed via Grep/Read/Bash against the real targets, never
approved by inspection or carried from earlier-session notes. An accepted TDD built on outdated
or unexecuted assumptions becomes implementation rework that costs more than the TDD itself.

### Executable-claim & AC-authoring gates

- **Executable-claim gate (regex ACs + cross-dialect SQL).** A "valid in both X" claim in a
  TDD/AC is an executable claim, not reviewable-by-inspection. (a) Regex in acceptance criteria
  is "complete" only when executed against the actual target files (`grep -lE '<regex>' <files>`)
  with the hit count matching the AC's expected file-set — broaden escape-arms for markdown
  (`\*\*Word\*\*`) and word-order variants first. (b) Any SQL codified verbatim as cross-dialect
  MUST be executed against EVERY declared dialect before sign-off (`INSERT…SELECT…ON CONFLICT`
  parses in Postgres but fails in SQLite — `near 'DO'` — needing a `WHERE true` separator).
  Edit-without-execute on either is reject-class.
- **AC-authoring gate (binding before any vote request).** Render the design's recommended
  output shape as a literal hand-built example and run EVERY AC command against it — prose
  recommendation and executable contract must not ship mutually exclusive. Know the semantics
  each AC encodes (`grep -c` counts LINES; `grep -o | wc -l` counts occurrences), and every AC
  must be computable from the surface it names — never assert fields the design keeps off the
  wire. If a collision ships anyway, the executable AC outranks recommendation-grade prose; no
  post-vote AC surgery for aesthetics.
- **Declarative artifacts** (dashboards, manifests, configs): pair every count with a per-target
  structural assertion (jq path checks, pairwise geometry, snapshot+diff of the untouched
  remainder) and enumerate expected values for every gate branch — counts prove how-many, never
  where or what-shape.
- **Byte-budget ACs** are computed, not hoped: draft the exact replacement fragments and
  `wc -c` old/new pairs before the design locks; record the measured ledger and named reserve
  cuts.
- **Every grep AC is verified DISCRIMINATING** (0 hits / fails pre-implementation) against
  current state before it ships — a passing-from-the-start AC proves nothing changed.
- **Positional/relocation ACs are not grep-count-expressible.** A `grep -c <token>` count says
  how many, never WHERE — demote position/ordering/"moved from A to B" properties to prose in
  the design body with a BEHAVIORAL test as the normative check (run the path that would hit the
  old call → assert it does not fire); keep grep-count ACs for genuine presence/absence facts,
  and use explicit per-file `grep -c file1 file2` args (not `grep -rc <dir>`, whose aggregate
  count is ambiguous for "zero in each file").

### Scope-grep and inventory gates

- **Inverted-scope grep on namespace expansion.** When a fix cycle expands a namespace
  (renames, new field type, alias), pre-verification grep MUST cover all historical stale
  states (inverted-scope), not just the prior reviewer's specific complaint token — run
  `~/.claude/scripts/ref_census.sh -p <stale-state-regex> -e <exempt>...` (repo: `src/user/claude-code/scripts/ref_census.sh`) from REPO-ROOT and
  require its `actionable_count` to close against the change's own claimed edit count.
- **Remove/rename-all-references inventories** run
  `~/.claude/scripts/ref_census.sh -p <pattern> -e <frozen-history/memory-dir>...` from
  REPO-ROOT (`.git` always exempt; pass explicit `-e` exemptions — never an allowlist of trees,
  however long) and read its `total`/`exempt_count`/`actionable_count` closed arithmetic;
  brief-supplied counts are verification targets, not facts, and the closure AC re-runs the
  same script as belt-and-braces.
- **A scoped exception to an existing rule** sweeps EVERY restatement/enforcement/audit home of
  that rule (same doc AND sibling files) in the same change, each carved home its own AC with
  verified pre-counts; if the enforcement layer's vocabulary cannot express the exception's
  guarantee, name the substitute enforcement home explicitly in the carved text.
- **Zero-hits is suspect, not proof.** A grep returning zero hits may be a quoting/word-split/
  loop bug, not true absence — re-run against a known-positive control before concluding
  "not found."

### Negative claims, corroboration, and edit-target verification

- **Negative structural claim re-grep.** A negative structural claim ("no X exists", "resolves
  to nothing") is re-grepped when the sentence is WRITTEN — never carried from earlier-session
  notes — and cites the search. A decision that strips prose-granted capabilities (even
  never-config-backed ones) is a scope change, not a vocabulary fix: name each removal in
  Consequences and Alternatives, and frame any alias/vocabulary sweep as semantic re-derivation
  from the source of truth, never find-replace.
- **Corroboration is not verification.** Before asserting what an existing test covers (or
  building a risk/AC on it), Read that test's assertion body — mutually-citing docs/comments/
  tickets launder claims, and a `t.Fatalf` diagnostic use of captured output is not an assertion
  on it.
- **File-edit prescription gate.** When the design prescribes ANY file edit, Read that exact
  target during authoring — no exception for `~/.claude/`, per-user runtime state, or "obviously
  new" paths — and design UPDATE-vs-APPEND from observed content.
- **Insertion-anchor gate.** For every insertion anchor: read ±3 lines around it and grep the
  file for region markers (`CANONICAL:`, BEGIN/END fences, generated-file headers) — an anchor
  inside a mirrored/generated region re-anchors to the region boundary. State the anchor's
  INTENT beside the coordinate; downstream, a structural invariant outranks the literal
  coordinate, provided intent-adjacency is preserved.
- **Live-configured-set gate.** For designs adopting/rejecting providers, tools, or integration
  paths: enumerate the operator's LIVE configured set first (read-only CLI list commands, never
  the secret store) and record it in Context & Prior Art — reuse-vs-new-credential is a real
  alternatives axis. An empty SANDBOXED probe of a local CLI is not absence; re-run unsandboxed
  before concluding.

### Design-intent and teammate-envelope gates

- **Design-intent vs current-fact.** When a TDD/ADR describes how an EXISTING subsystem behaves
  as a load-bearing constraint, Read that subsystem's source and quote the actual command/logic
  before encoding it — do NOT encode the inferred design INTENT (what surrounding design implies
  it *should* do) as current fact; frame aspirational behavior explicitly as "design intent /
  required change."
- **Teammate-mode envelope rule (documented).** When a TDD prescribes a skill or MCP server for
  downstream agents (`Skill(verify-ac)`, MCP tool call), don't assume frontmatter auto-loads —
  for teammates only `tools` and `model` apply; the definition body is APPENDED to the system
  prompt and `skills:`/`mcpServers:` are NOT applied
  (code.claude.com/docs/en/agent-teams, "Use subagent definitions for teammates"). Prescribe
  explicit `Skill(<name>)` invocation in the TDD's Implementation Notes, not by referencing the
  agent's frontmatter.

<!-- CANONICAL:AUTHORING-VERIFICATION-GATES:END -->
