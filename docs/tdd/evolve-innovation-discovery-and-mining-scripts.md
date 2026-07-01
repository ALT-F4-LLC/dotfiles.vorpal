---
project: "main"
maturity: "draft"
last_updated: "2026-06-30"
updated_by: "@staff-engineer"
scope: "Enrich the Phase 0 innovation-scanner mission in evolve-agents/evolve-skills (byte-symmetric) and evolve-config (domain-adapted) to hunt RELIABLE process simplification/automation, and add two deterministic shared scripts under .claude/scripts/ (evolve_signals.py miner + symmetry_check.py linter) wired so the evolve cycles consume them."
owner: "@staff-engineer"
dependencies:
  - ../../.claude/skills/evolve-agents/SKILL.md
  - ../../.claude/skills/evolve-skills/SKILL.md
  - ../../.claude/skills/evolve-config/SKILL.md
  - ../../.claude/skills/evolve-coherence/SKILL.md
  - ../../src/user/claude-code/skills/session-metrics/SKILL.md
  - evolve-model-distribution-skill.md
  - adr/0001-retention-and-compaction-policy-for-evolution-cycle.md
status: "draft"
---

# TDD: Evolve Innovation Discovery + Deterministic Mining Scripts

## Problem Statement

**What.** Two coupled changes to the evolution ecosystem:

1. **Phase 0 innovation-discovery mandate.** Enrich the `innovation-scanner` mission in
   the three audit-bearing evolve skills so it EXPLICITLY seeks RELIABLE ways to
   simplify or automate processes — manual, repetitive, or error-prone steps that could
   be made DETERMINISTIC and REPEATABLE, including candidates worth codifying as a shared
   repository script. The change is applied **byte-symmetrically** to
   `evolve-agents/SKILL.md` and `evolve-skills/SKILL.md` (their innovation-scanner
   templates are parity-locked) and in a **domain-adapted** form to
   `evolve-config/SKILL.md` (whose innovation-scanner is config-specialized and NOT
   parity-locked).
2. **Deterministic mining/automation scripts.** Build a BOUNDED set of two shared,
   dependency-free scripts under `.claude/scripts/` and WIRE the evolve cycles to consume
   them: `evolve_signals.py` (a deterministic fitness-signal miner over transcripts +
   `history.jsonl` + Mimir + pitfalls, with distinct-`sessionId` de-dupe) and
   `symmetry_check.py` (a deterministic byte-symmetry / CANONICAL-parity linter that
   automates the currently-manual coherence checks).

**Why now.** The operator asked for it, and there is a concrete, measurable defect that
makes the request load-bearing rather than cosmetic:

- **A live internal contradiction in the evolve skills.** All three skills mandate, in
  prose, "count DISTINCT `sessionId`, never raw line-hit totals" — transcripts replicate
  ~10× across resumed/subagent `.jsonl` files (`evolve-agents/SKILL.md:266`,
  `evolve-skills/SKILL.md:262`, `evolve-config/SKILL.md:281`). Yet the actual
  model-distribution command they instruct the auditor to run is
  `grep -oh '"model":"[^"]*"' ~/.claude/projects/<session>/subagents/*.jsonl | sort | uniq -c`
  at **2 sites/file, 6 total**, in two distinct parity contexts (see S6): the
  **model-routing-auditor** step (`evolve-agents:347`, `evolve-skills:351`,
  `evolve-config:370` — the agents↔skills pair is parity-locked) and the
  **historical-auditor** note (`evolve-agents:274`, `evolve-skills:266`,
  `evolve-config:283` — intentionally asymmetric). That command RAW-counts per-turn
  `"model"` occurrences and does NOT de-dupe by `sessionId` — it directly violates the
  de-dupe rule stated inches away. The mining is therefore NOT reliable today; "reliably"
  is the operator's first-class requirement.
- **Innovation discovery is reporting-only with no reliability lens.** The scanner surfaces
  "Efficiency Gains" but never asks "could this be made DETERMINISTIC?" nor offers a path
  to codify a reliable automation. There is no shared script layer for it to point at.
- **Byte-symmetry is enforced by manual eyeballing.** `evolve-agents`/`evolve-skills`
  Phase 2 checks **5-8** (`evolve-agents/SKILL.md:480-483`) and `evolve-coherence` D4
  (`evolve-coherence/SKILL.md:117-132`) ask a spawned agent to visually confirm that
  parity-locked blocks are byte-identical modulo noun substitutions (check 9 is a
  presence-only assertion — the historical-auditor Mimir note — which a byte-differ cannot
  mechanize and which this work leaves manual). This is exactly the kind of error-prone
  manual step the new mandate targets — and a deterministic differ removes the human from
  the loop for the four byte-symmetric checks.

**Who is affected.** Every `evolve-agents` / `evolve-skills` / `evolve-config` cycle, the
`evolve-coherence` audit that guards their parity, and the operator who runs them. Better,
de-duped mining directly improves the fitness signals those cycles select on — so the
downstream effect is higher-quality evolution results.

**Constraints.**

- **535-line self-budget** per evolve orchestrator (`evolve-agents/SKILL.md:127`,
  `evolve-skills/SKILL.md:129`, `evolve-config/SKILL.md:83`) — DISTINCT from the
  review-target 500. Current sizes: evolve-agents 533, evolve-skills 533, evolve-config
  535 (at cap). SKILL.md additions MUST be net-line-neutral (line expansion, not new
  physical lines) unless the budget is explicitly raised.
- **Byte-symmetry.** The `innovation-scanner` and `model-routing-auditor` templates are
  parity-locked between `evolve-agents` and `evolve-skills` only; `evolve-config`'s
  innovation-scanner is intentionally config-specialized and out of that lock.
- **Reliability = determinism + repeatability.** Mining must de-dupe by distinct
  `sessionId`; identical input MUST yield byte-identical output.
- **Extend, don't replace wholesale.** The existing inline transcript/history/Mimir
  mining is upgraded surgically, not ripped out.
- **Scripts live under a code path, never under `docs/`.** Commit nothing.

**Acceptance criteria (operator).**

| # | Criterion | Verification |
|---|---|---|
| AC1 | The `innovation-scanner` mission in evolve-agents + evolve-skills explicitly names RELIABLE, DETERMINISTIC process simplification/automation and script codification, applied byte-symmetrically (modulo agent↔skill nouns). | `symmetry_check.py --check innovation-scanner` exits 0; AND on the innovation-scanner block ONLY (extract via `sed -n '/^### Phase 0: Innovation Scan/,/^### Phase 0: Model Routing Audit/p' <file>`), `grep -icE 'reliabl|determinist'` (bare pipe under `-E`) ≥ 1 for each file. |
| AC2 | evolve-config's innovation-scanner carries a domain-adapted (config-vocabulary) version of the same mandate. | On the config innovation-scanner block (same `sed` range extraction), `grep -icE 'reliabl|determinist'` ≥ 1; config vocabulary preserved (`grep -c 'New Settings' evolve-config/SKILL.md` ≥ 1). |
| AC3 | No SKILL.md exceeds its 535-line self-budget after the edits. | `wc -l` on all three ≤ 535. |
| AC4 | `.claude/scripts/evolve_signals.py` mines fitness signals deterministically with distinct-`sessionId` de-dupe; identical input → byte-identical JSON. | Run twice on the fixture → `diff` is empty; a 10×-replicated session counts as 1. |
| AC5 | `.claude/scripts/symmetry_check.py` deterministically verifies the parity-locked blocks; exits 0 on a symmetric pair, non-zero + diff on injected drift. | Fixture-driven: symmetric → exit 0; drifted → exit ≠ 0 with a printed diff. |
| AC6 | The evolve cycles CONSUME the scripts: the flawed distribution command is replaced by an `evolve_signals.py` call at ALL 6 sites, and the parity checks invoke `symmetry_check.py`. | `grep -c 'evolve_signals.py' <file>` ≥ 2 for EACH of the three files (both sites swapped); `grep -c "grep -oh '\"model\":\"" <file>` returns 0 for each (no raw-count distribution command remains — S1); `grep -c 'symmetry_check.py'` ≥ 1 in evolve-agents AND evolve-skills. |
| AC7 | Both scripts are stdlib-only Python 3 (no third-party deps), read-only, and never commit. | `grep -E '^(import|from) ' scripts` names only stdlib modules; no network write; no `git` calls. |

## Context & Prior Art

**In-repo prior art (read before designing; reused, not reinvented):**

- `src/user/claude-code/skills/session-metrics/SKILL.md` + `scripts/session_metrics.py`
  — the canonical **split pattern**: a stdlib-only Python 3 script parses/aggregates the
  local transcript and emits JSON; the agent renders/reasons over that JSON
  (`session-metrics/SKILL.md:21`). `session_metrics.py` is stdlib-only (`datetime, html,
  json, os, re, sys, tempfile, pathlib`), de-dupes replicated usage records via a
  `seen_message_ids` set (`session_metrics.py:109,134`), and reads the `subagents/`
  sidecar tree (`:268-269`). `evolve_signals.py` FOLLOWS this pattern (precedent, NOT a
  code dependency — it does not import `session_metrics.py`). Two concrete differences make
  code-reuse the wrong move: (1) **placement** — session-metrics is a USER-GLOBAL skill
  built from `src/` into `~/.claude/skills/`, whereas the evolve skills are PROJECT-LOCAL
  (git-tracked under `.claude/skills/`, no `src/` copy — verified), so `evolve_signals.py`
  is project-local (`.claude/scripts/`), not `src/`-built; (2) **de-dupe key** —
  session_metrics.py de-dupes by `message_id` (`session_metrics.py:109,134`), while
  `evolve_signals.py` de-dupes by distinct `sessionId` (the replication unit the evolve
  mandate names). Same split pattern, different code.
- `docs/tdd/evolve-model-distribution-skill.md` (accepted) — establishes the LOCAL
  (transcript ground-truth) vs REMOTE (Mimir supplement) grounding, the per-spawn
  `.meta.json`+`.jsonl` join (`role` via `name`, requested alias via `model`, resolved
  model with `<synthetic>` filtered), distinct-`sessionId` de-dupe, and a coherence
  contract. `evolve_signals.py` implements the SAME per-spawn/distinct-`sessionId`
  discipline that TDD specs (see §Prior Art & Non-Duplication below for the boundary).
- The three evolve orchestrators' **inline mining** — the `historical-auditor` and
  `model-routing-auditor` Phase 0 templates. They already carry the de-dupe PROSE
  (`evolve-agents/SKILL.md:266,269,272`) and the Mimir instant-query arm
  (`evolve-agents/SKILL.md:359-363`), but the model-distribution command itself
  (`:274,347`) does not de-dupe. This is the extend-target.
- The **parity-lock coherence checks** — `evolve-agents`/`evolve-skills` Phase 2 checks
  **5-8** (`evolve-agents/SKILL.md:480-483`) verify the cross-project pitfalls harvest,
  innovation-scanner, model-routing-auditor, and Mimir blocks are byte-symmetric between
  the two files (check 9 is presence-only — the historical-auditor Mimir note — out of
  scope for a byte-differ); `evolve-coherence` D4 (`evolve-coherence/SKILL.md:121-132`)
  verifies CANONICAL:* block byte-parity across the family. `symmetry_check.py` mechanizes
  the FOUR byte-symmetric checks 5-8; the CANONICAL:* D4 check is a deferred follow-up (no
  in-scope consumer — C-E, see §Risks & Open Questions).
- `docs/tdd/adr/0001-retention-and-compaction-policy-for-evolution-cycle.md` — the
  authority for changelog/compaction formulas; unchanged by this work (no new changelog
  family is introduced — see §Data Models).

**External precedent.** The split (deterministic tool + LLM reasoning over its structured
output) is the standard "tool-use" decomposition: push exact, repeatable computation into
code and reserve the model for judgment. It mirrors how linters/formatters (`gofmt`,
`ruff`) are run as deterministic gates and the human reviews only the diff — here
`symmetry_check.py` is the gate and the agent reviews only reported drift.

**Prior Art & Non-Duplication (evolve-model-distribution).** That skill is a downstream
APPLY orchestrator: it *decides* model-routing tier changes and *edits* `team-lead.md`
behind an operator gate. This TDD builds the shared MINING layer beneath it and does NOT
touch `team-lead.md` routing. The relationship is layered, not overlapping:

- **This work (`evolve_signals.py`)** = the deterministic, de-duped measurement library
  (per-spawn model identity + stalls + errors + corrections + history + Mimir + pitfalls).
  It *mines and wires*.
- **evolve-model-distribution** = a consumer that *decides and applies* routing edits.
  When implemented, it SHOULD call `evolve_signals.py` for its per-spawn collection rather
  than re-implement the `.meta.json`+`.jsonl` join inline — this work makes that join a
  single tested tool instead of prose duplicated across skills.

No edit surface is shared: this TDD edits only the three evolve SKILL.md files (Phase 0
wording + consume-wiring) and adds two scripts; it never edits `team-lead.md` routing or
the model tiers.

## Alternatives Considered

### Alternative A — Shared `.claude/scripts/`, 2 scripts, net-neutral wording, in-place reliability swap (CHOSEN)

Add `evolve_signals.py` + `symmetry_check.py` under a new shared project-local
`.claude/scripts/` directory. Enrich the innovation-scanner mission by EXPANDING existing
lines (net-zero `wc -l`), byte-symmetric across the agents/skills pair and domain-adapted
for config. Wire consumption by (1) replacing the flawed `uniq -c` distribution command
with an `evolve_signals.py --distribution` call at its 6 sites, and (2) invoking
`symmetry_check.py` from the parity checks.

- **Strengths.** Fixes the live de-dupe contradiction (on-mandate for "reliably"); stays
  within the 535-line budget with no budget change; a single miner replaces triplicated
  prose logic (kills the drift hazard at its root); `symmetry_check.py` both automates a
  manual check AND self-verifies that the innovation-scanner edit preserved symmetry;
  scripts are shared, not per-skill-duplicated.
- **Weaknesses.** The in-place swap edits the parity-locked `model-routing-auditor` block,
  so the change must be applied symmetrically and re-verified (mitigated: `symmetry_check.py`
  proves it). A new top-level `.claude/scripts/` directory is a new repo surface (bounded:
  two files).
- **Verdict.** CHOSEN. Directly serves the "reliable" mandate, respects the budget, and
  eliminates the duplicated-logic drift hazard rather than adding to it.

### Alternative B — Pure-additive wiring (no in-place swap), budget bump

Leave every inline command untouched. Add a pre-flight step that runs `evolve_signals.py`
and substitutes a new `{mining_digest}` variable into the Phase 1 templates. This adds
~4-6 physical lines per file, requiring the 535-line self-budget be raised (e.g. to 545)
across all three Self-budget notes plus the inventory thresholds.

- **Strengths.** Strictly "extend, never replace" — nothing existing changes; lowest risk
  to the parity locks.
- **Weaknesses.** Leaves the flawed raw-count `uniq -c` command in place, so the
  reliability defect the operator's mandate targets is NOT fixed — the digest and the
  contradictory inline command would coexist and could disagree. Requires a budget change
  touching three Self-budget notes + pre-flight inventory modes. Adds a parallel signal
  path instead of fixing the one that is wrong.
- **Verdict.** REJECTED. Fails the core "reliably" requirement (the wrong command
  survives) and costs a budget change for a strictly worse outcome. Documented here
  because the extend-vs-replace tension is the load-bearing decision the operator approves
  at plan time.

### Alternative C — Per-skill `scripts/` dirs (session-metrics placement), miner duplicated per skill

Follow session-metrics literally: put a copy of the miner under each evolve skill's own
`scripts/` directory (`.claude/skills/evolve-agents/scripts/…`, etc.).

- **Strengths.** Matches the one existing script-placement precedent exactly; each skill is
  self-contained.
- **Weaknesses.** The miner is consumed by THREE skills (plus, later, evolve-model-distribution
  and evolve-coherence), so per-skill placement forces either triplication (three copies to
  keep in sync — the exact drift hazard this work exists to remove) or an arbitrary
  "which skill owns it." session-metrics is a single-skill tool; this is shared
  infrastructure.
- **Verdict.** REJECTED. Reintroduces duplicated state across a maintenance boundary.
  A shared `.claude/scripts/` home is the honest representation of shared tooling.

## Architecture & System Design

### Component map

```mermaid
flowchart TD
    OP([Operator: /evolve-agents | /evolve-skills | /evolve-config]) --> PF[Pre-flight\ngoal + date + window\n+ availability probes]
    PF --> P0{Phase 0: parallel collection}

    subgraph consume [".claude/scripts/ — deterministic shared tools"]
      ES[evolve_signals.py\nper-spawn model dist + stalls/-r2\n+ is_error + corrections + history\n+ Mimir + pitfalls\nDISTINCT sessionId de-dupe\n-> JSON digest]
      SC[symmetry_check.py\nextract parity-locked blocks\napply noun substitutions\ndiff -> exit 0 / non-zero+diff]
    end

    P0 --> MRA[model-routing-auditor\ncalls evolve_signals.py --distribution\nreplacing flawed uniq -c]
    P0 --> HA[historical-auditor\nother inline signals stay\n+ evolve_signals.py --distribution]
    P0 --> ISCAN[innovation-scanner\nENRICHED: hunt RELIABLE\nsimplification/automation;\nsurface script candidates -> .claude/scripts/]
    ES -. deterministic digest .-> MRA
    ES -. deterministic digest .-> HA

    MRA --> P1[Phase 1: self-review\nreason over digest\nact on script candidates]
    HA --> P1
    ISCAN --> P1
    P1 --> P2[Phase 2: Coherence & Renames\nchecks 5-9 CALL symmetry_check.py\ninstead of manual eyeball]
    SC -. deterministic verdict .-> P2
    P2 --> WRAP[Wrap-up: report\nNO commit]
```

### 4.1 Script home & shape

- **Home.** `.claude/scripts/` — a new shared, git-tracked, project-local directory,
  sibling to `.claude/skills/`. Chosen over per-skill `scripts/` (Alt C) because the tools
  are consumed by 3+ skills; chosen over `src/` because the consumers are project-local,
  not `src/`-built. No registration is required — the skills invoke the scripts by path
  (`python3 .claude/scripts/<name>.py …`), exactly as session-metrics invokes its script by
  path.
- **Language & deps.** Python 3, **stdlib-only** (`json`, `os`, `sys`, `re`, `subprocess`,
  `argparse`, `pathlib`, `urllib.request`, `hashlib`, `difflib`) — matching
  `session_metrics.py`. No third-party dependency; deterministic across machines.
- **Split.** Each script does exact computation and prints a structured result (JSON for the
  miner, unified diff + exit code for the linter). The agent reasons over the output; the
  script never reasons, never edits, never commits.

### 4.2 `evolve_signals.py` contract

**Purpose.** One deterministic, de-duped implementation of the fitness-signal mining the
evolve cycles do by hand — so "reliably" is enforced in code, not asked of a grep.

**Inputs (read-only).** `~/.claude/projects/**/subagents/*.{jsonl,meta.json}`,
`~/.claude/history.jsonl`, `.claude/agent-memory/*/pitfalls.md` (+ cross-project pitfalls
under a configurable root), and one unauthenticated Mimir HTTP GET.

**De-dupe discipline (the reliability core).**
- **Per-spawn model identity:** one `subagents/*.jsonl` (+ its `.meta.json` sidecar) = ONE
  spawn = the unit of counting. Resolved `"model"` is read once per spawn (not once per
  turn); `"model":"<synthetic>"` is filtered. This is the fix for the `uniq -c` flaw:
  distribution counts are per-DISTINCT-spawn, never per-turn.
- **Session-level de-dupe:** transcripts replicate across resumed/subagent files; the
  script keys every count on distinct `sessionId` (parsed from each record / file stem) so
  the ~10× replication cannot inflate totals.
- **Stall/respawn de-dupe:** `-r2` respawns and `TeammateIdle` events counted DISTINCT by
  `name`+`sessionId`, per the existing prose (`evolve-agents/SKILL.md:269-272`).

**Output.** A single JSON object to stdout, keys sorted (deterministic ordering) — see
§API Contracts for the schema. All monetary/Mimir figures are labeled supplementary; LOCAL
is authoritative for model identity.

**Failure modes (never abort the cycle).** Missing/malformed `.jsonl` → that spawn degrades
to `<unparseable>` and the loop continues; absent `subagents/` → empty local arm; Mimir
non-200/empty → `{"remote": {"available": false, "reason": "<reason>"}}`; empty window →
`{"local": {"sessions_scanned": 0}}` and the caller reports "no local metrics."

### 4.3 `symmetry_check.py` contract

**Purpose.** Turn the manual byte-symmetry eyeball (Phase 2 checks **5-8**) into a
deterministic gate — the concrete "reliable automation of an error-prone process" this
cycle produces. It mechanizes the FOUR byte-symmetric checks (cross-project pitfalls
harvest, innovation-scanner, model-routing-auditor, Mimir block); check 9
(historical-auditor Mimir-note PRESENCE) is intentionally asymmetric and NOT mechanizable
by a differ — it stays a manual presence assertion.

**Method — normalize-then-diff, CALIBRATED against the live pair (C-A).** A naive
`s/agent/skill/g` token-swap FALSE-POSITIVES on the current, correctly-symmetric pair,
because the agents↔skills divergences are not all clean token swaps. The normalizer has
three arms:

- **Structural (bespoke) asymmetries** — not substitutions at all: e.g. the scanner's read
  target is `Read agents/*.md` on one side vs `Read .claude/skills/*/SKILL.md and skills/*/SKILL.md`
  on the other (one glob vs two globs joined by "and"). These are handled by explicit
  per-block structural normalization rules, not the token map.
- **Protected-literal allowlist** — tokens that CONTAIN `agent`/`skill` but MUST NOT be
  rewritten: `subagent_type`, `Agent(`, `innovation-scanner`, `historical-auditor`,
  `model-routing-auditor`, `SendMessage`. The normalizer skips these (whole-token guard) so
  a blanket `s/agent/skill/` can never corrupt them.
- **Clean token substitutions** (the remainder): `agents↔skills`, `Cross-Agent↔Cross-Skill`,
  `agent_name↔skill_name` (PromQL label), `target agents↔target skills`,
  `per-agent↔per-skill`, team-name/target-variable tokens.

The substitution set is therefore DERIVED by diffing the LIVE blocks until the current pair
normalizes to equality — not a guessed static map. **Calibration anchor (load-bearing
baseline AC):** against the CURRENT, correctly-symmetric evolve-agents/evolve-skills pair,
every `--check` MUST exit 0. A non-zero exit on the baseline means the normalizer is
mis-calibrated (a missing protected literal or structural rule), NOT that the skills drifted
— this baseline is the tool's primary correctness gate (AC5, Phase 2).

**Checks (selectable via `--check`).** `innovation-scanner`, `model-routing-auditor`,
`mimir`, `pitfalls-harvest` (the FOUR parity-locked evolve-agents↔evolve-skills blocks =
checks 5-8), and `all` (those four). `--check canonical` (CANONICAL:* byte-parity across the
agent/skill family, evolve-coherence D4) is DEFERRED — no in-scope consumer, high-complexity
(C-E, YAGNI); it ships with the same follow-up that wires evolve-coherence D4 (§Risks & Open
Questions).

**Output & exit.** Exit `0` = all selected blocks normalize to equality; exit `1` = drift
(prints the `difflib.unified_diff` of the NORMALIZED blocks, so the operator sees the true
residual difference, not substitution noise); exit `2` = usage/IO error (a required file
absent). Deterministic: same files → same verdict and diff.

### 4.4 Innovation-scanner wording change (shown for evolve-agents; symmetry note follows)

The change EXPANDS three existing lines (net-zero physical-line delta) — the MISSION line,
area #2's title+body, and its Output-Format bullet. Concrete diff for `evolve-agents/SKILL.md`:

- **MISSION** (`:308`) — append a reliability/automation clause:
  > MISSION: Discover NEW and MORE-EFFICIENT ways for agents to accomplish their tasks —
  > evolutionary variation and exploration, NOT auditing past failures (that is
  > historical-auditor's job). **A first-class target is RELIABLE process
  > simplification/automation: manual, repetitive, or error-prone steps that could be made
  > DETERMINISTIC and REPEATABLE — including any worth codifying as a shared script under
  > `.claude/scripts/` that a later cycle then consumes.** Read agents/*.md and surface
  > concrete opportunities …
- **Area #2** (`:314`) — rename + expand:
  > 2. **Efficiency Gains & Reliable Automation**: Steps, workflows, or verification loops
  > that could be shortened, parallelized, eliminated, **or made DETERMINISTIC by codifying
  > them as a repeatable script (e.g. under `.claude/scripts/`)** — without sacrificing
  > correctness; **prefer automating any step whose result currently varies by
  > hand-execution.**
- **Output-Format bullet** (`:327`) — rename the label to match area #2 so a script
  candidate has a home in the scanner's output that flows into `{innovation_findings}`:
  > `- Efficiency Gains & Reliable Automation: <1-3 bullets, or "none">`

**Symmetry note.** The identical three edits are applied to `evolve-skills/SKILL.md`
(`:312,318,331`) with the established substitutions (`agents`→`skills`, `Cross-Agent`→
`Cross-Skill`). Because every added token is common to both files (no agent/skill-specific
noun in the new clause), symmetry is preserved and `symmetry_check.py --check
innovation-scanner` MUST exit 0 afterward. `evolve-config/SKILL.md` (`:329,334,349`)
receives a **domain-adapted** version — same reliability/determinism intent phrased in
config vocabulary (e.g. "a deterministic script under `.claude/scripts/` that a later cycle
consumes" folded into "New Settings"/"Efficiency Gains"), NOT byte-symmetric, because its
innovation-scanner is out of the parity lock.

**Invariant (evolve-config non-symmetry — intentional; do NOT flag as drift).** The
`evolve-config` innovation-scanner is DELIBERATELY outside the
`evolve-agents`↔`evolve-skills` parity lock: it is config-domain-specialized (`New Settings`
/ `Config Innovation` vocabulary, names the `claude_code.rs` setter), and the coherence
checks that enforce innovation-scanner byte-symmetry bind ONLY the agents/skills pair
(`evolve-agents/SKILL.md:481`; `evolve-coherence` D4 keys on variant-FAMILY membership, not
a global lock). A future `evolve-coherence` / Phase-2 run MUST treat the config
innovation-scanner's divergence as a whitelisted intentional variant — never a parity
finding. `symmetry_check.py` encodes this invariant structurally: `--check
innovation-scanner` compares ONLY the agents/skills pair and NEVER compares evolve-config
against it, so the tool cannot produce a false drift finding for the config file.

### 4.5 Consume-wiring (Option A — in-place, net-neutral)

**This is a BEHAVIOR change, not a wording change — stated plainly.** Option A alters what
the evolve cycles DO at Phase 0: the distribution measurement stops raw-counting per-turn
`"model"` hits and starts counting distinct per-spawn identities via `evolve_signals.py`.
That is an intended **reliability fix** (it makes the command obey the distinct-`sessionId`
de-dupe mandate stated inches away in the same block), NOT cosmetic. The rejected
Alternative B (pure-additive `{mining_digest}`, +lines, needs a 535→545 budget bump, and
LEAVES the flawed command in place) sits beside it in §Alternatives so the operator chooses
the behavior change knowingly at plan time.

- **Miner.** Replace the flawed distribution command
  `grep -oh '"model":"[^"]*"' … | sort | uniq -c` at its 6 sites with
  `python3 .claude/scripts/evolve_signals.py --distribution --since {history_cutoff_iso}`
  (one command → one command; net-zero lines). The 6 sites split by **parity context (S6)**:
  the **3 model-routing-auditor** sites (`evolve-agents:347`, `evolve-skills:351`,
  `evolve-config:370`) — the agents↔skills pair is parity-locked, so its two swaps MUST be
  byte-identical (they are: the replacement carries no agent/skill noun); and the **3
  historical-auditor** sites (`evolve-agents:274`, `evolve-skills:266`, `evolve-config:283`)
  — intentionally asymmetric prose, swapped in place with NO symmetry constraint. The
  surrounding prose ("Report DISTINCT counts per model per role. This is ground truth …") is
  retained — the script now makes it TRUE. ALL other inline signals (stall grep, `-r2` grep,
  `is_error`, Mimir PromQL, `history.jsonl`, agent-memory) remain inline: a targeted
  reliability fix at the one command that contradicts the de-dupe mandate, not wholesale
  removal.
- **Linter.** Wire into the `evolve-agents`/`evolve-skills` Phase 2 Coherence step (checks
  **5-8**) **NET-ZERO (C-D)** by FOLDING the invocation into an EXISTING check line, not
  adding a new one (these files have only 2 lines of headroom). Concrete form: check 5's
  existing line `5. Verify the cross-project pitfalls harvest protocol … flag any drift.`
  becomes `5. Run \`python3 .claude/scripts/symmetry_check.py --check all\` (non-zero exit =
  drift; supersedes the manual eyeball for the four byte-symmetric blocks — cross-project
  pitfalls harvest, innovation-scanner, model-routing-auditor, Mimir). Flag any drift.` —
  one line rewritten, none added. Checks 6-8 prose remain as the human-readable spec the
  script enforces; check 9 (presence-only) stays manual. `evolve-coherence` D4 is a DEFERRED
  additional consumer (§Migration + Open Questions C-E), not wired this cycle.

### 4.6 Determinism & reliability contract

Both scripts are pure functions of their read-only inputs, with determinism engineered
explicitly (not merely asserted):

- **Sorted-key JSON AND sorted ARRAYS (C-C(b)).** `json.dumps(sort_keys=True)` orders object
  KEYS but NOT array ELEMENTS, so every output array carries an explicit sort: `per_spawn` by
  `(session_id, role)`, `pitfalls.recurring` by `(role, symptom)`, `pitfalls.manifest` by
  path, `operator_corrections` by model. Dict-valued signal maps (distribution, stalls) sort
  by key.
- **Path-sorted globs, NOT mtime (S4).** File iteration sorts inputs lexicographically by
  PATH (`sorted(glob(...))`), never by mtime. (Note: `session_metrics.py:70` sorts by mtime —
  correct for its "latest session" UX, WRONG for reproducible mining; `evolve_signals.py`
  must not copy that.)
- **Wall-clock excluded from the payload (S3).** No timestamp appears in stdout JSON; any
  `generated` marker goes to STDERR, and `--distribution` omits it entirely — so a double-run
  `diff` of stdout is trivially empty with no field-stripping.
- **Determinism scope (C-C(a)).** The guarantee "identical input → byte-identical output" is
  scoped to the **LOCAL arm and `--no-remote` mode**. The live-Mimir `--all` arm is NOT
  byte-stable (the remote `reason` string and label set legitimately vary with endpoint
  state); AC4's double-run equality test therefore runs with `--no-remote`. The remote arm is
  a labeled supplement, never a determinism-bearing input.

This scoped determinism IS the "reliably" the mandate demands: the LOCAL measurements the
cycle selects on no longer depend on grep-hit accidents or iteration order.

## Data Models & Storage

No persistent data plane and NO new changelog family (unlike evolve-model-distribution).
`evolve_signals.py` emits ephemeral JSON to stdout consumed in-session; an optional
`--cache` writes to `$TMPDIR` only (never `/tmp`, never `docs/`). `symmetry_check.py` emits
a diff + exit code, nothing persistent. All inputs are read-only. The SKILL.md edits are
recorded through the evolve skills' EXISTING changelog families
(`docs/changelog/agents/`, `docs/changelog/skills/`, `docs/changelog/config/`) when a cycle
applies them — no taxonomy change, so `evolve-coherence`'s one-writer-per-family invariant
is untouched.

**`evolve_signals.py` JSON schema (informative):**

```json
{
  "window": {"since_iso": "2026-06-23T00:00:00Z", "days": 7},
  "local": {
    "sessions_scanned": 12,
    "distinct_session_ids": 9,
    "distribution": {"claude-opus-4-8": 41, "claude-sonnet-4-6": 7},
    "per_spawn": [{"session_id": "…", "role": "review-senior-engineer",
                   "requested_model": "opus", "resolved_model": "claude-opus-4-8"}],
    "stalls": {"TeammateIdle": {"advisor": 2}, "r2_respawns": {"reviewer-2": 1},
               "shutdown_rejection": {}},
    "errors": {"is_error": 3},
    "operator_corrections": {},
    "history_invocations": {"/evolve-skills": 2}
  },
  "remote": {"available": false, "reason": "Mimir metrics unavailable: connection refused"},
  "pitfalls": {"manifest": ["…/staff-engineer/pitfalls.md"],
               "recurring": [{"role": "staff-engineer", "symptom": "…", "count": 2}]}
}
```

Arrays (`per_spawn`, `pitfalls.manifest`, `pitfalls.recurring`) are emitted in the
deterministic sort order defined in §4.6; NO wall-clock field appears in stdout (a
`generated` marker, if enabled, goes to stderr). The `remote` object is present only under
`--all`; `--distribution` omits it, keeping that arm byte-stable.

**`operator_corrections` is RESERVED / deferred** — its detector is UNWIRED (no reliable
transcript marker for operator corrections exists yet, and a phrase-grep heuristic was
deliberately declined as too fragile to feed a fitness signal), so it always emits an EMPTY
object `{}`. Consumers MUST NOT read empty as "zero corrections" — treat it as "not yet
measured." Wiring a reliable detector is a tracked follow-up (see §Risks & Open Questions).

## API Contracts

**`evolve_signals.py` (CLI):**

```
python3 .claude/scripts/evolve_signals.py [--all | --distribution]
    [--since <ISO8601>] [--days N]
    [--projects-root <path>]         # default ~/.claude/projects (fixture override)
    [--pitfalls-root <path>]         # default ~/Development
    [--mimir-base <url> | --no-remote]
    [--cache]                        # optional $TMPDIR JSON dump
```

- `--distribution` emits only the per-spawn distribution arm (the model-routing-auditor
  swap target; LOCAL-only, byte-stable — omits the `generated` marker per §4.6); `--all`
  emits the full digest. **At most one** window flag (`--since` or `--days`) may be given —
  BOTH is a usage error (exit `2`); NEITHER is valid and yields an UNBOUNDED / all-time
  window (the sensible mining default). Output: one JSON object, sorted keys AND sorted
  arrays (§4.6), to stdout. Exit `0` on success (including empty window), `2` on usage
  error. Never non-zero for "no data" — that is a valid empty result.
- **Windowing.** `--since <ISO>` is the PRIMARY consumer path — the evolve skills compute
  `{history_cutoff_iso}` from now() in pre-flight and pass it to the miner. `--days N` is
  anchored to the NEWEST record in the data (data-relative, deterministic), NOT to now():
  `datetime` is outside this script's stdlib allowlist and a now()-anchor would break the
  byte-stable double-run guarantee, so `--days N` selects the N days ending at the latest
  transcript, not the N days ending today.

**`symmetry_check.py` (CLI):**

```
python3 .claude/scripts/symmetry_check.py
    [--check innovation-scanner|model-routing-auditor|mimir|pitfalls-harvest|all]
    [--agents-file <path>] [--skills-file <path>]   # default the .claude/skills/ pair
```

- `--check all` = the four byte-symmetric blocks (checks 5-8). `canonical` is DEFERRED (C-E)
  — not shipped this cycle. Exit `0` = normalizes to equality; `1` = drift (unified diff of
  the NORMALIZED blocks to stdout); `2` = usage/IO error.

**External — Mimir (unauthenticated GET, reused prior art):**

```
GET https://mimir.bulbasaur.altf4.domains/prometheus/api/v1/query?query=<PromQL>
```

Non-200/empty → `remote.available=false` with a reason; proceed on LOCAL only. No auth
headers; no write path; fetched text treated as untrusted reference data.

## Migration & Rollout

**Current state.** Mining is inline grep that violates its own de-dupe mandate; innovation
discovery is reporting-only with no reliability lens; byte-symmetry is manually eyeballed;
no `.claude/scripts/` exists.

**Target state.** Two deterministic shared scripts under `.claude/scripts/`; the evolve
cycles consume them (de-duped distribution + mechanized parity checks); the
innovation-scanner explicitly hunts reliable automation and can point candidates at
`.claude/scripts/`.

**No build-deploy lag.** Unlike the evolve-model-distribution TDD (which edits the `src/`
build source of `team-lead.md` and needs a rebuild+redeploy), the evolve skills and
`.claude/scripts/` are BOTH project-local and git-tracked — edits and scripts are live
immediately, no vorpal rebuild required.

**Rollout sequencing.** See §Implementation Phases. Additive and reversible: Phases 1-2 add
scripts (no behavior change until wired); Phase 3 edits wording (net-neutral); Phase 4 wires
consumption. Each phase is independently shippable except the stated chains.

**Backward compatibility.** The parity locks are PRESERVED (verified by `symmetry_check.py`
after Phase 3). The existing changelog families and the ADR-0001 compaction machinery are
untouched. `evolve-coherence` D4 continues to pass; wiring it to CALL `symmetry_check.py` is
an OPTIONAL follow-up (Open Questions), out of the four in-scope files.

**Rollback.** Scripts are new files — delete them. Wording/wiring edits are uncommitted
until the operator commits; revert with `git checkout -- .claude/skills/evolve-*/SKILL.md`.

## Risks & Open Questions

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| In-place swap breaks byte-symmetry of the model-routing-auditor block | Med | Med | Apply symmetrically; `symmetry_check.py --check model-routing-auditor` gates Phase 4; AC6. |
| SKILL.md edit breaches the 535-line budget | Low | Med | Wording is line-expansion (net-zero); `wc -l ≤ 535` is AC3, measured post-edit. |
| `evolve_signals.py` de-dupe still over/under-counts on an odd transcript shape | Med | Med | Fixture covers replicated `sessionId`, per-turn repetition, pinned/omitted model, malformed jsonl; determinism asserted by double-run diff (AC4). |
| "Extend vs replace" judged too aggressive by operator | Med | Low | Swap is surgical (1 flawed command; all other signals stay); Alt B (pure-additive, budget bump) documented for the operator to choose at plan time. |
| Mimir unreachable at runtime | Med | Low | `remote.available=false` fallback; LOCAL is authoritative for identity. |
| `.claude/scripts/` path not sandbox-writable / not discovered | Low | Med | Path is under the project root (sandbox-writable); invoked by explicit path, no registration needed (session-metrics precedent). |
| Future coherence run mis-flags evolve-config's domain-adapted innovation-scanner as parity drift | Low | Low | Stated as an explicit INVARIANT (§4.4): config is intentionally outside the agents/skills lock; `symmetry_check.py --check innovation-scanner` compares ONLY the agents/skills pair, never evolve-config. |
| `symmetry_check.py` normalizer mis-calibrated → false drift on the correctly-symmetric pair (naive `s/agent/skill/` corrupts `subagent_type`/`Agent(`/etc.) | Med | Med | C-A: normalizer uses a protected-literal allowlist + explicit structural rules, NOT a blanket token swap; the LOAD-BEARING calibration AC (§4.3, Phase 2) requires the current live pair to exit 0 before the tool is accepted. |

**Open questions (resolved with recommendation; operator confirms at plan time).**

1. **Consume-wiring: in-place swap (Alt A) vs pure-additive (Alt B)?** RECOMMEND Alt A — it
   fixes the live de-dupe contradiction and stays in budget. RESOLVED pending operator
   approval.
2. **Script home: `.claude/scripts/` vs per-skill?** RECOMMEND `.claude/scripts/` (shared).
   RESOLVED (Alt C rejected).
3. **Wire `symmetry_check.py` into `evolve-coherence` D4 + ship `--check canonical`?**
   RECOMMEND: wire the linter into the in-scope `evolve-agents`/`evolve-skills` Phase 2 now
   (checks 5-8); DEFER BOTH the `evolve-coherence` D4 wiring AND the `--check canonical`
   implementation to ONE follow-up issue — high-complexity, no in-scope consumer (C-E,
   YAGNI). No blocker.
4. **Third script (`pitfalls_ledger`)?** RECOMMEND folding pitfalls harvest into
   `evolve_signals.py` as one arm rather than a standalone script — keeps the set bounded at
   two. RESOLVED.
5. **[COORDINATION — do NOT resolve unilaterally] evolve-model-distribution AC2 tension
   (X1).** The evolve-model-distribution skill (DKT-26/27) is built, but its per-spawn
   `.meta.json`+`.jsonl` join is a STUB pending those issues (its `SKILL.md` L92-93) — so
   there is NO live duplication today. However, its **AC2** requires "SKILL.md Phase 0
   embeds the per-spawn join loop," which CONFLICTS with the mine-ONCE-in-`evolve_signals.py`
   plan here; the window to prevent two divergent join implementations is NOW. TRACKED
   FOLLOW-UP: retarget DKT-26 to CONSUME `evolve_signals.py --distribution` instead of
   embedding its own join. Flagged for team-lead + operator reconciliation at plan approval
   — deliberately NOT decided in this TDD.
6. **`operator_corrections` detector (RESERVED).** The signal ships as a permanent empty
   `{}` this cycle — no reliable transcript marker for operator corrections exists, and the
   fragile phrase-grep heuristic the inline evolve skills use was deliberately declined (a
   false-firing detector would corrupt the fitness signal). TRACKED FOLLOW-UP: design a
   reliable corrections detector (or retire the field). Consumers treat empty as "not yet
   measured," never "zero corrections." Not a blocker — the digest stays schema-complete and
   deterministic.

## Testing Strategy

Scripts are executable and get real unit/fixture tests; SKILL.md edits get structural +
symmetry assertions.

- **`evolve_signals.py` — fixture-driven determinism (AC4).** Commit a synthetic
  `projects/<sess>/subagents/` tree (paired `agent-a<role>-<hash>.{jsonl,meta.json}`)
  covering: a session replicated across two resumed files (assert it counts as ONE distinct
  `sessionId`); a spawn whose `.jsonl` repeats `"model"` across many turns (assert counted
  once, not once/turn); a `"model":"<synthetic>"` turn (assert filtered); a pinned
  (`meta.model=opus`) vs omitted (`meta.model` absent) spawn; a truncated/zero-byte `.jsonl`
  (assert `<unparseable>` + loop continues). Run the script TWICE with `--no-remote` →
  assert `diff` of the two stdout JSON outputs is empty (byte-identical; no wall-clock in
  stdout per §4.6, so no field-stripping needed). Mimir exercised separately via a mock base
  and the `--no-remote` fallback path.
- **`symmetry_check.py` — calibration baseline (LOAD-BEARING) + gate behavior (AC5).** The
  primary correctness test (C-A): `--check all` against the CURRENT, correctly-symmetric
  evolve-agents/evolve-skills pair MUST exit 0 — proving the normalizer's protected-literal
  allowlist + structural rules are calibrated (a false-positive here means the TOOL is
  wrong, not the skills). Then: inject a one-token drift into a copy of one block → assert
  exit 1 with a printed unified diff of the NORMALIZED blocks; feed a missing file → assert
  exit 2. (`--check canonical` is out of scope this cycle — C-E.)
- **Self-test of the wording edit.** After Phase 3, `symmetry_check.py --check
  innovation-scanner` MUST exit 0 (the edit's own symmetry is proven by the tool this cycle
  ships — the linter validates the wording change that motivated it).
- **SKILL.md structural (AC1-AC3, AC6).** `wc -l ≤ 535` (all three); on each
  innovation-scanner block (extracted via the AC1 `sed` range, NOT a whole-file grep — C-F),
  `grep -icE 'reliabl|determinist'` ≥ 1; `grep -c 'evolve_signals.py' <file>` ≥ 2 per file
  (both swapped sites); the raw-count distribution command fully retired
  (`grep -c "grep -oh '\"model\":\"" <file>` → 0 per file — S1).
- **`evolve_signals.py` stdlib-only (AC7).** `grep -E '^(import|from) '
  .claude/scripts/evolve_signals.py` names only stdlib modules.

**Untested-claims inventory (forward-looking / unreachable branches).**

- **Mimir live path.** Exercised only against a mock/absent endpoint; a live 200 with real
  labels is a known positive-coverage gap (the `--no-remote` and mock arms keep the branch
  valid).
- **Cross-machine reconciliation.** `evolve_signals.py` mines THIS machine's transcripts;
  the LOCAL-vs-REMOTE divergence path (other machines route differently) is reported, not
  unit-tested — deferred, same posture as the evolve-model-distribution TDD.
- **`--check canonical` (CANONICAL:* family parity).** DEFERRED this cycle (C-E) — not
  implemented, so no coverage is owed here; it ships with the evolve-coherence D4 wiring
  follow-up (Open Question 3). The four in-scope checks (5-8) are covered by the calibration
  baseline + drift fixture above.
- **Real-window end-to-end.** A full evolve cycle consuming the digest is validated by
  inspection against the existing Phase 0→Phase 1 substitution contract, not by an induced
  cycle run (a markdown skill exposes no unit-testable orchestration function).

## Observability & Operational Readiness

- **Signals.** `evolve_signals.py`'s JSON digest is the durable-in-session audit artifact
  (every count carries its de-dupe basis); `symmetry_check.py`'s exit code + diff is the
  parity verdict. Both write diagnostics to stderr, data to stdout (session-metrics
  convention).
- **3am diagnosability.** Because both scripts are deterministic and read-only, an operator
  reproduces any measurement by re-running the exact command — no hidden state, no
  wall-clock dependence in the payload. A suspicious distribution count is re-derivable from
  the named session paths in `per_spawn`.
- **Production readiness.** Scripts commit nothing and edit nothing; blast radius is stdout.
  The evolve cycles' existing operator-approval HARD GATE still governs every SKILL.md edit
  the digest informs.
- **Runbook.** `python3 .claude/scripts/evolve_signals.py --all --days 7` to inspect the
  digest; `python3 .claude/scripts/symmetry_check.py --check all` to verify parity before
  committing any evolve edit; both are safe to run anytime.

## Implementation Phases

### Phase 1 — `evolve_signals.py` + fixtures + tests

- **Goal.** Build the deterministic fitness-signal miner with distinct-`sessionId` de-dupe
  and its committed fixture tree.
- **File scope.** `.claude/scripts/evolve_signals.py` (new); `.claude/scripts/test/fixtures/`
  (synthetic subagents tree + a mock Mimir payload).
- **Acceptance criteria.**
  - Script exists and is stdlib-only: `grep -cE '^(import|from) ' .claude/scripts/evolve_signals.py`
    ≥ 1 AND no non-stdlib module named (manual review of the import list).
  - Determinism: running `python3 .claude/scripts/evolve_signals.py --all --projects-root
    .claude/scripts/test/fixtures --no-remote` twice and `diff`-ing the two stdout outputs
    yields empty (no wall-clock in stdout per §4.6 — no field-stripping needed).
  - De-dupe: on the replicated-session fixture, `distinct_session_ids` < raw file count, and
    the per-turn-repeated-model spawn contributes 1 to `distribution`, not N.
- **Effort.** L.
- **Dependencies.** None.
- **Out of scope.** Any SKILL.md edit; the linter.

### Phase 2 — `symmetry_check.py` + tests

- **Goal.** Build the deterministic parity linter: the normalizer (protected-literal
  allowlist + per-block structural rules + clean token map, calibrated so the live pair
  normalizes to equality) and the FOUR byte-symmetric checks 5-8. `--check canonical` is NOT
  built this cycle (C-E).
- **File scope.** `.claude/scripts/symmetry_check.py` (new);
  `.claude/scripts/test/fixtures/` (a symmetric block pair + a drifted copy).
- **Acceptance criteria.**
  - **Calibration baseline (LOAD-BEARING — C-A):** `python3 .claude/scripts/symmetry_check.py
    --check all` against the CURRENT (pre-Phase-3) evolve-agents/evolve-skills pair exits 0 —
    the normalizer's allowlist + structural rules are calibrated so the correctly-symmetric
    live pair passes.
  - Against a drifted fixture copy, exit is 1 and stdout contains a unified diff (`grep -c
    '^[+-]' <output>` ≥ 1).
  - Missing-file invocation exits 2.
- **Effort.** M.
- **Dependencies.** None (parallel to Phase 1).
- **Out of scope.** Wiring into the skills; `--check canonical` + evolve-coherence D4
  (deferred follow-up, C-E / Open Question 3).

### Phase 3 — Innovation-scanner wording (3 files, net-neutral)

- **Goal.** Apply the reliability/automation mandate: byte-symmetric to
  evolve-agents/evolve-skills, domain-adapted to evolve-config; net-zero line delta.
- **File scope.** `.claude/skills/evolve-agents/SKILL.md`,
  `.claude/skills/evolve-skills/SKILL.md`, `.claude/skills/evolve-config/SKILL.md`.
- **Acceptance criteria.**
  - Budget: `wc -l` on each of the three files ≤ 535.
  - Content: on the innovation-scanner block ONLY — extract via
    `sed -n '/^### Phase 0: Innovation Scan/,/^### Phase 0: Model Routing Audit/p' <file>`
    (delimit on the next `### Phase` heading, NOT a bare `###` which the block's internal
    `### Agent:` / `### Skill:` / `### Config Innovation` headings truncate early — C-F) —
    `grep -icE 'reliabl|determinist'` ≥ 1 in each file.
  - Symmetry: `python3 .claude/scripts/symmetry_check.py --check innovation-scanner` exits 0
    AFTER the edit (proves the agents/skills pair stayed byte-symmetric).
  - Config vocabulary preserved: `grep -c 'New Settings' .claude/skills/evolve-config/SKILL.md`
    ≥ 1 (domain adaptation did not erase config-specific structure).
- **Effort.** M.
- **Dependencies.** Phase 2 (needs `symmetry_check.py` to verify the symmetry AC).
- **Out of scope.** Consume-wiring of the miner.

### Phase 4 — Consume-wiring (Option A) + coherence re-pass

- **Goal.** Wire both scripts in: swap the flawed distribution command for
  `evolve_signals.py --distribution` at all 6 sites (net-zero), and fold `symmetry_check.py`
  into the existing Phase 2 check-5 line (net-zero). Then re-run parity.
- **File scope.** `.claude/skills/evolve-agents/SKILL.md`,
  `.claude/skills/evolve-skills/SKILL.md`, `.claude/skills/evolve-config/SKILL.md`.
- **Acceptance criteria.**
  - Miner wired at BOTH sites/file: `grep -c 'evolve_signals.py' <file>` ≥ 2 for
    evolve-agents, evolve-skills, AND evolve-config.
  - Flawed command fully retired (S1): `grep -c "grep -oh '\"model\":\"" <file>` → 0 for each
    of the three files (no raw-count distribution command remains).
  - Linter wired NET-ZERO (C-D): `grep -c 'symmetry_check.py' <file>` ≥ 1 in evolve-agents
    AND evolve-skills, achieved by folding the call into the existing check-5 line — no line
    added (confirmed by the budget AC).
  - Budget held: `wc -l` on each of the three files ≤ 535 AND unchanged from Phase 3 (miner
    swap and linter fold are both net-zero).
  - Parity holds: `python3 .claude/scripts/symmetry_check.py --check all` exits 0.
- **Effort.** M.
- **Dependencies.** Phases 1, 2, 3.
- **Out of scope.** Editing `evolve-coherence` + `--check canonical` (deferred follow-up,
  Open Question 3); retargeting DKT-26 / evolve-model-distribution (coordination item X1,
  Open Question 5); editing `team-lead.md` routing; committing.
