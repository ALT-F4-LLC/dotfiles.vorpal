# Authoring Verification Gates — Maintained Master

`staff-engineer.md` (TDD Creation Workflow step 6) and `distinguished-engineer.md` (Mode 1)
carry compact `CANONICAL:AUTHORING-VERIFICATION-GATES-LOCAL` copies. Deployed at
`~/.claude/skills/team-doctrine/references/authoring-verification-gates.md` — repo:
`src/user/claude-code/skills/team-doctrine/references/authoring-verification-gates.md`.

---

## Authoring Verification Gates

<!-- CANONICAL:AUTHORING-VERIFICATION-GATES:BEGIN -->

**Core rule.** Before saving a TDD/ADR and before requesting a vote, every load-bearing
claim — referenced module, API signature, spec convention, existing pattern,
negative/absence claim, regex, SQL, byte count — is confirmed via Grep/Read/Bash against the
real targets, never approved by inspection or carried from earlier-session notes. An
accepted TDD built on unexecuted assumptions becomes implementation rework that costs more
than the TDD itself.

### Executable claims and AC authoring

- **Execute what claims to be executable.** Regex in an AC is "complete" only when executed
  against the actual target files with the hit count matching the expected file-set; SQL
  codified as cross-dialect runs against EVERY declared dialect before sign-off
  (`INSERT…SELECT…ON CONFLICT` parses in Postgres, fails in SQLite). Edit-without-execute
  on either is reject-class.
- **Render the output shape and run every AC against it** before any vote request — prose
  recommendation and executable contract must not ship mutually exclusive. Know each AC's
  semantics (`grep -c` counts LINES; `grep -o | wc -l` counts occurrences), and every AC
  must be computable from the surface it names. If a collision ships anyway, the executable
  AC outranks recommendation-grade prose; no post-vote AC surgery for aesthetics.
- **Every grep AC is verified DISCRIMINATING** (0 hits / fails pre-implementation) — a
  passing-from-the-start AC proves nothing changed. Positional/relocation properties
  ("moved from A to B") are not grep-count-expressible — demote them to prose with a
  BEHAVIORAL test as the normative check, and use explicit per-file `grep -c file1 file2`
  args, not `grep -rc <dir>`.
- **Declarative artifacts** (dashboards, manifests, configs): pair every count with a
  per-target structural assertion (jq path checks, pairwise geometry, snapshot+diff of the
  untouched remainder) — counts prove how-many, never where or what-shape. **Byte-budget
  ACs** are computed, not hoped: `wc -c` the drafted old/new fragments before the design
  locks.

### Scope sweeps and inventories

- **Reference inventories run `~/.claude/scripts/ref_census.sh -p <pattern> -e <exempt>...`**
  (repo: `src/user/claude-code/scripts/ref_census.sh`) from REPO-ROOT and read its
  `total`/`exempt_count`/`actionable_count` closed arithmetic; brief-supplied counts are
  verification targets, not facts. On namespace expansion (rename, new field type, alias),
  the pre-verification grep covers all historical stale states (inverted-scope), not just
  the prior reviewer's complaint token, and `actionable_count` closes against the claimed
  edit count.
- **A scoped exception to an existing rule** sweeps EVERY restatement/enforcement/audit home
  of that rule in the same change, each carved home its own AC with verified pre-counts.
- **Zero hits is suspect, not proof** — re-run against a known-positive control before
  concluding "not found."

### Negative claims, corroboration, and edit targets

- **Negative structural claim re-grep.** A negative claim ("no X exists", "resolves to
  nothing") is re-grepped when the sentence is WRITTEN and cites the search. A decision that
  strips prose-granted capabilities is a scope change, not a vocabulary fix: name each
  removal in Consequences and Alternatives.
- **Corroboration is not verification.** Before asserting what an existing test covers,
  Read that test's assertion body — mutually-citing docs/comments/tickets launder claims,
  and a `t.Fatalf` diagnostic use of captured output is not an assertion on it.
- **Read every prescribed edit target during authoring** — no exception for `~/.claude/`,
  per-user runtime state, or "obviously new" paths — and design UPDATE-vs-APPEND from
  observed content. For every insertion anchor: read ±3 lines around it and grep for region
  markers (`CANONICAL:`, BEGIN/END fences, generated-file headers) — an anchor inside a
  mirrored/generated region re-anchors to the region boundary; state the anchor's INTENT
  beside the coordinate.
- **Live-configured-set gate.** For designs adopting/rejecting providers, tools, or
  integration paths: enumerate the operator's LIVE configured set first (read-only CLI
  lists, never the secret store) and record it in Context & Prior Art. An empty SANDBOXED
  probe of a local CLI is not absence; re-run unsandboxed before concluding.

### Design intent and the teammate envelope

- **Design-intent vs current-fact.** When a TDD/ADR describes how an EXISTING subsystem
  behaves as a load-bearing constraint, Read that subsystem's source and quote the actual
  logic — never encode inferred design INTENT as current fact; frame aspirational behavior
  explicitly as "design intent / required change."
- **Teammate-mode envelope rule.** When a TDD prescribes a skill or MCP server for
  downstream agents, don't assume frontmatter auto-loads — for teammates only `tools` and
  `model` apply; the definition body is APPENDED to the system prompt and
  `skills:`/`mcpServers:` are NOT applied (code.claude.com/docs/en/agent-teams, "Use
  subagent definitions for teammates"). Prescribe explicit `Skill(<name>)` invocation in the
  TDD's Implementation Notes, not by referencing the agent's frontmatter.

<!-- CANONICAL:AUTHORING-VERIFICATION-GATES:END -->
