# Runtime Discipline (R1-R7) — Maintained Master

**LOCAL-copy consumers:** all 6 team agents (`staff-engineer.md`, `security-engineer.md`,
`senior-engineer.md`, `sdet.md`, `project-manager.md`, `ux-designer.md`) plus `team-lead.md`,
which retains compact `CANONICAL:RUNTIME-DISCIPLINE-LOCAL` bodies for R1/R3/R4/R6 (it is a
runtime consumer of those four rules on every turn) and a pointer for R2/R5/R7. Relocated from
`src/user/opencode/agents/team-lead.md` §Runtime Discipline (DKT-59/60 doctrine-home
migration). Deployed at `~/.config/opencode/skills/team-doctrine/references/runtime-discipline.md` —
repo: `src/user/opencode/skills/team-doctrine/references/runtime-discipline.md`. Read on
demand only — never `skill({ name: "team-doctrine" })`.

---

## Runtime Discipline (R1-R7)

Canonical R-rule bodies for the team. Other agents include rule bodies inline only where the rule applies; cross-agent pointers resolve here. Per-agent applicability per the matrix below; team-lead itself uses R2/R5/R7 via pointer style (▾) and the rest as bodies. This file is the source of truth for the R-rule bodies.

| Rule | tl | st | se | pm | ux | sd | sr | Lines |
|---|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
| **R1 Tool-Use Parsimony** | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ~8 |
| **R2 Skill Invocation Restraint** | ▾ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ~4 |
| **R3 Brevity Terseness** | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ~5 |
| **R4 Iteration Cap** | ✓ | ✓ | ✓ | — | ✓ | ✓ | ✓ | ~4 |
| **R5 Persistent-Advisor Self-Summary** | ▾ | ✓* | ✓* | — | ✓* | — | — | ~7+variants |
| **R6 Anti-Defensive-Exploration** | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ~4 |
| **R7 In-Session Read-Cache Awareness** | ▾ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ~3 |

✓ = full body; ▾ = pointer (`see skills/team-doctrine/references/runtime-discipline.md §R{N}`); — = omit; ✓* = canonical body + per-advisor variant trigger.

**Column legend:** `tl` = team-lead, `st` = staff-engineer, `se` = senior-engineer, `pm` = project-manager, `ux` = ux-designer, `sd` = sdet, `sr` = security-engineer.

### R1 — Tool-Use Parsimony

R1. **Tool-Use Parsimony.** Tool-call results land in your context verbatim — a 2,000-line
Read costs ~2,000 lines of context. Apply these defaults:

- File enumeration: use `grep -l 'pattern' path/`, NOT `grep -rn 'pattern' path/`. Reach for
  `-rn` ONLY when the line content itself IS the evidence you need.
- Large files: use `Read(file, offset=N, limit=M)`, NOT a full-file `Read`, when you only need
  a section. Read the whole file ONLY when you must reason about whole-file structure.
- Bash dumps: use `wc -l`, `head`, `tail`, or `awk` summary patterns. Do NOT pipe raw `cat`
  into your context. Pipe through `jq` / `grep` to filter BEFORE the result lands.
- Batched calls: dispatch 3+ independent reads/greps in ONE turn (harness runs them concurrently).
- Escape hatch: when the bulk read IS the load-bearing evidence (full file for review, full diff for verification), the full read is correct — the rule bans speculative bulk reads, not load-bearing ones.
- cwd PERSISTS across Bash calls (the shell keeps its working directory) and `docket` resolves its DB from cwd — never leave the repo `src/` root; scope directory-local commands with a subshell `(cd <dir> && ...)` or absolute paths. On `no docket database found`, `pwd` and cd back to root — do NOT re-`docket init`.

### R2 — Skill Invocation Restraint

R2. **Skill Invocation Restraint.** Every `skill({ name })` call loads the entire SKILL.md
body into your context.

- Invoke a skill ONLY on a real trigger match. NEVER pre-load a skill "in case I need it
  later".
- Your role-canonical skills (per the agent config `skills`/permission setup) are the ones you legitimately
  invoke routinely. Treat occasional skills (e.g., `vote` for non-staff agents) as
  trigger-dispatched, NOT defensive.
- **Banned for orchestrators (team-lead), planners (@project-manager), and persistent advisors (the three CLOSED-set names — `advisor`, `security-advisor`, `ux-advisor`):** do NOT invoke a skill "to learn the format authority" or "in case it's needed." Skill bodies are only loaded by the actual artifact-producing agent on the standard dispatch invocation (e.g., the reviewer running `code-review-verdict`, the TDD author running `tdd`). If you need to consult a skill's format without running it, ask the operator or the responsible dispatch owner.
- Escape hatch: when the operator or team-lead directs a skill explicitly, invoke per
  the directive.

### R3 — Brevity Terseness

R3. **Brevity Terseness.** Operator-facing messages and subagent-dispatch briefs accumulate in
context. (Peer-message terseness between subagents is **[NO OPENCODE EQUIVALENT — deferred]** —
Opencode has no peer messaging; this rule governs operator-facing and dispatch-brief brevity
instead.)

- Send one message per purpose. Do NOT append a status update to a question, or vice versa.
- Do NOT quote back the message you are replying to — the recipient already has it in their
  thread. Reference the prior message's claim/ask in 5-10 words and respond.
- Use `todowrite` state transitions (in_progress / completed / blocked) instead of narrative
  status paragraphs.
- Escape hatch: high-stakes events (re-plan triggers, scope deltas, blocker escalations) earn
  the longer message — the visibility contract (team-lead Rule 2) is the gate. Terseness bounds
  redundant state, never load-bearing context — see the Alignment & Optimization orthogonality statement (single source of truth) for how terseness and recipient-shaped optimization coexist.

### R4 — Iteration Cap (no re-verify of completed ACs)

R4. **Iteration Cap.** After verifying an AC once, mark it complete and do NOT re-Read the
artifact for that AC unless evidence of regression surfaces.

- Do NOT expand verification scope past the acceptance criteria — extra coverage is @sdet's
  call, not unilaterally yours.
- Cycle caps already exist at team-lead level (2 fix-review cycles, 2 fix-verify cycles per
  team-lead.md step 14/15). Your role-level discipline is to avoid INTRA-instance re-verification
  loops within a single fix cycle.
- Escape hatch: when an explicit blocker says "the prior verification was wrong because X",
  re-verify the specific criterion X impacts. Do NOT re-verify unrelated criteria.

### R5 — Advisory-Dispatch Saturation (team-lead heuristic)

**Obsolete as an advisor-side rule under Opencode.** R5 assumed persistent/auto-resuming advisors that could emit a self-summary turn and await a team-lead ack — impossible for one-shot `task` dispatches (an advisor returns a summary and ends; it cannot "notify team-lead and await ack" mid-run). The body is retained as a historical reference for a future persistent-team port; on Opencode the equivalent discipline is team-lead-side.

R5. **Advisory-dispatch saturation (team-lead-side).** When an advisory role's returned summaries degrade (shortening, losing track of decisions, going generic), team-lead stops resuming that `task_id` and re-dispatches the role FRESH with a continuity preamble (verified goal + load-bearing decisions so far + the new ask) — letting the stale accumulated context drop. Memory writes (`~/.opencode/agent-memory/{role}/pitfalls.md`) land before the fresh dispatch when a recurring saturation pattern surfaced. Never drop a cross-cycle canonical decision-record; when unsure if content is load-bearing, KEEP it in the continuity preamble.

**Per-advisor degradation triggers** (team-lead watches for). The advisory spawn names map to agent defs: `advisor` → `@staff-engineer`, `security-advisor` → `@security-engineer`, `ux-advisor` → `@ux-designer` (each resumed via `task_id` until degradation, then re-dispatched fresh). Triggers: `advisor` = 3+ TDD revision rounds OR after a TDD secondary-review fix-loop; `security-advisor` = each security-review verdict OR after a critical/high finding-to-fix cycle; `ux-advisor` = each design-QA verdict that surfaced a spec/implementation mismatch OR 3+ design-review rounds on the same spec.

### R6 — Anti-Defensive-Exploration

R6. **Anti-Defensive-Exploration.** Re-reading a file you already Read this session,
re-running a `git status` you already ran this turn, or re-checking facts because of vague
anxiety is context bloat with no evidence value.

- Re-read ONLY on actual cause: file edited since last Read, operator-flagged divergence, or
  explicit reviewer concern pointing at the specific file. Same discipline for lagging readers:
  once the owning authority confirms state (write acked by the live DB/system), STOP re-reading a possibly-stale reader to re-confirm it.
- Banned-phrase extension (complements Rule 6): "let me also check", "to be safe I'll Read", "let me confirm by Read" — anxiety-driven bloat. Verifying a specific load-bearing claim is fine; Reading "to be sure" is not.
- Escape hatch: after a long stretch of work or compaction, re-anchoring on the original brief
  is correct. The rule bans defensive re-checks of facts already in your turn context, not
  legitimate re-anchoring of context that has been lost.

### R7 — In-Session Read-Cache Awareness

R7. **In-Session Read-Cache Awareness.** Files you Read this session are already in your
context — re-Reading them doubles the cost without new evidence.

- Before any Read call, scan back through your turn history to confirm you have not already
  Read this file this session. The harness does not cache; you must.
- Exception (canonical): after compaction, all "previously Read" files are un-Read for the
  Edit/Write gate. Read once before the next Edit per the Read-before-Edit/Write rule.
  This is ONE Read per file after compaction, not defensive multi-Reads.
- Escape hatch: when a dispatch's report states "I just edited X", re-Read X — the edit invalidates
  your prior context. (Peer messaging of edits is **[NO OPENCODE EQUIVALENT — deferred]**.)
