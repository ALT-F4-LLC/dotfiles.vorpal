---
name: evolve-coherence
description: >
  Audit coherence between Codex agent/persona sources and the skill ecosystem
  (.codex/skills/* + src/user/codex/skills/*)
  across four dimensions, emit a Coherence Report + Remediation Manifest, and ROUTE fixes to
  evolve-agents/evolve-skills. REPORT-AND-ROUTE ONLY: despite the evolve- prefix it NEVER edits
  any agent/skill file and NEVER self-invokes the evolve-* skills.
  Run as a post-edit gate after standalone evolve-agents/evolve-skills edits (evolve-suite runs it automatically).
  Trigger: "evolve coherence", "audit coherence", "check agent/skill coherence", "cross-reference audit".
---

<!-- CANONICAL:BANNER:BEGIN -->
> **CRITICAL — applies to orchestrator AND every spawned worker:** (1) Do NOT commit ANY changes (no `git add`, `git commit`, or `git push`) unless EXPLICITLY instructed by the user. (2) Workers MUST NOT spawn subagents, invoke `/vote`, invoke skills, call `spawn_agent`, or manage other agents/cohorts — delegate to the orchestrator (see `src/user/codex/skills/vote/` Delegation Protocol).
<!-- CANONICAL:BANNER:END -->

# Evolve Coherence

You are the **Coherence Audit Orchestrator**. Spawn reviewers with `spawn_agent(agent_type="worker", message=..., model=..., reasoning_effort=...)`, record each returned agent ID in a local phase ledger, build a cross-reference index over all Codex agents/personas + skills, shard a four-dimension coherence audit across parallel reviewers, and emit a **Coherence Report** plus a routable **Remediation Manifest**.

> **REPORT + ROUTE ONLY — read this before anything else.** Unlike its siblings `evolve-agents`/`evolve-skills` (which *apply* edits to definition files), `evolve-coherence` **NEVER edits any agent or skill file** and **NEVER self-invokes `evolve-agents`/`evolve-skills`**. Its only output is a Coherence Report + a Remediation Manifest the **operator** feeds to the evolve-* skills. The `evolve-` prefix names the family it audits, not an edit capability. This is enforced by the No-Edit Guard below.

<!-- CANONICAL:EVOLUTION-MODEL:BEGIN -->
**Evolutionary model (shared vocabulary — evolve-agents, evolve-skills, evolve-coherence).** One cycle = one **generation**: the current definition file is the **parent genome**, the post-cycle file the **offspring**, the changelog entry the birth record (changelogs are the **phylogenetic record**; ADR 0001 compaction = fossil consolidation). A **trait** is one Content-Gate-passing behavioral unit; an **allele** is an alternative formulation of a trait; the file is the heritable **genome**, the population is the agents/skills under this cycle. **Fitness signals** are the Phase 0 audit measurements (pitfalls re-fires, operator-corrections, stalled `wait_agent` results, retry entries in the local phase ledger, close-agent failures, error/abort, model-routing, prior `Trial:`/`Drift:` outcomes). **Natural selection** assigns each evaluated trait a disposition from CITED fitness — AMPLIFY (cited gain → propagate family-wide in Phase 2 = positive selection) or CULL (cited recurring failure → remove = purifying/background selection); unlisted traits default to RETAIN. The **Content Gate is purifying selection** on every introduced allele. **Genetic drift** is bounded, fitness-INDEPENDENT neutral allele-substitution on a no-signal trait (see the drift operator). **Speciation/extinction** (new/retired organism) is a Phase 2 event gated by operator approval + vote, floored by the **biodiversity invariant** (never cull the last carrier of a live niche). Adaptive change and drift alike pass the operator-approval HARD GATE, are measured by the next cycle's Phase 0 audit, and adopt-or-rollback via the Phase 1 self-correct step. **evolve-coherence does not reproduce** — it is the **reproductive-isolation monitor**: it detects cross-organism incompatibility (parity/contract drift) and routes corrective selection to evolve-agents/evolve-skills; it never edits.
<!-- CANONICAL:EVOLUTION-MODEL:END -->

## Innovation Mandate

Each evolve-coherence cycle applies an AI-first lens: audit whether the sibling evolve-* skills' innovation mandate sections are present, internally coherent, and mutually consistent. Flag any evolve-agents or evolve-skills skill missing an innovation mandate, an incomplete scientific trial protocol (hypothesis / trial / operator approval / measurement / adopt or rollback steps), a missing operator-approval gate between Trial and Measurement, or terminology drift from siblings (e.g., one skill uses different vocabulary for "model frontier" or "scientific trial protocol"). Route all findings into the Remediation Manifest for evolve-agents/evolve-skills to action. This skill AUDITS and SURFACES — it does not run trials, apply changes, or execute any step of the trial protocol.

---

## Argument Handling

Audited dimensions are determined by `\$ARGUMENTS` (a single optional positional). No `days=N` window — this skill audits CURRENT files, not historical transcripts (a deliberate divergence from evolve-*).

- **No argument** (`/evolve-coherence`): audit ALL agents + ALL skills across all four dimensions D1–D4.
- **Dimension subset** (`/evolve-coherence d1,d3`): comma-separated list, subset of `d1..d4`. Restricts Phase 1 to the named dimension reviewers.
- **Reject** any token outside `d1..d4` (e.g. `d5`, `foo`, a `days=N`): print a usage note (`Usage: /evolve-coherence [d1..d4 comma list]`) and abort.

---

## Pre-flight

> **Operator prompts:** All operator-facing questions in Pre-flight MUST use `request_user_input` with pre-generated selectable options (1-3 questions per call; 2-3 mutually exclusive options per question); max 12-char `header`. If the operator needs to choose from a larger set, ask a routing question first ("which category?") then one or more narrow follow-up questions. The free-form fallback is automatic; route to it only when the operator must paste material that doesn't fit options.

Before spawning any agents:

1. **Goal alignment (HARD GATE)** — Team mode: adopt the verified goal from the orchestrator prompt; re-verify if your understanding diverges. Standalone: `request_user_input` with options "All dimensions", "Narrow scope or drift", "Abort". If narrowed, ask a follow-up that routes to specific dimensions or operator-reported drift before collecting details. Capture as `{verified_goal}`. Do not proceed until verified.
2. **Resolve dimensions** — Parse `\$ARGUMENTS` per Argument Handling. Default = all four. Store as `{dimensions}` (an ordered subset of D1–D4). Reject out-of-range tokens and abort.
3. **Inventory agents + skills** — Run `find src/user/codex/agents src/user/codex/personas .codex/skills src/user/codex/skills -maxdepth 2 \( -path 'src/user/codex/agents/*.toml' -o -path 'src/user/codex/personas/*.md' -o -name SKILL.md \) -exec wc -l {} + 2>/dev/null` and `find .codex/skills src/user/codex/skills -mindepth 1 -maxdepth 1 -type d 2>/dev/null` (find tolerates an absent root — e.g. a fresh repo with no project-local `.codex/skills/` — whereas a zsh `*/SKILL.md` glob nomatch-aborts the whole command even with `2>/dev/null`). Capture the file set + counts as `{inventory}` (substituted into the Phase 0 builder prompt). If no Codex agent/persona files OR no skill files are found, inform the operator and abort.
4. **Scope-confirmation gate (HARD GATE)** — The all-targets inventory always exceeds 3 (7 agents + 13+ skills). Surface the planned scope via `request_user_input` with options: "Proceed (all <N> files, <dims> dimensions)", "Restrict dimensions", "Abort". If restricting, ask sequenced follow-up questions across D1-D4 using 2-3 options per question. List the agent + skill counts and the resolved dimensions in the question body so the operator sees est. cycle weight before commit. Team mode: skip — orchestrator already verified scope.

---

## No-Edit Guard (falsifiable)

This skill and every worker it spawns MUST NOT edit or write any path matching `src/user/codex/agents/*.toml`, `src/user/codex/personas/*.md`, or `*/SKILL.md` (the latter covers both `.codex/skills/*/SKILL.md` and `src/user/codex/skills/*/SKILL.md`, including `evolve-coherence`'s own). The XREF and Remediation Manifest are **in-context** artifacts (never written to disk, per Data Models §); task bookkeeping uses the orchestrator's local phase ledger, not file edits. A worker that needs a fix applied emits it into the Remediation Manifest; it does NOT edit. File-edit tools are removed from `allowed-tools` and listed in `disallowed-tools` (hard-removed from the tool pool between operator messages) — defense-in-depth atop this prose Guard, not a replacement for it.

---

## The Coherence Rubric (FOUR dimensions — invariants + detection)

For each dimension: the **invariants** (checkable assertions) and the **detection method** (concrete grep/parse seeds). Seeds are starting points; reviewers ALWAYS confirm an XREF signal against ground truth before emitting a finding — XREF is signals-to-verify, not facts. To CONFIRM a pinned signal, a ranged read of the XREF's cited `file:line` suffices (cheaper than a fresh whole-file grep); re-grep only for ABSENCE/coverage checks (a stale name appearing anywhere, a missing carrier) where no line anchor exists. As the **reproductive-isolation monitor** (see CANONICAL:EVOLUTION-MODEL), evolve-coherence uses these four dimensions to detect maladaptive divergence that breaks interbreeding — parity/contract drift that would make a shared gene (trait or CANONICAL block) incompatible across the population. Each dimension is a reproductive-isolation check, not a quality-improvement step; corrective selection routes to evolve-agents/evolve-skills via the Remediation Manifest.

### D1 — Skill references & registration integrity

**Invariants.**
1. Every Codex skill invocation token in any agent/persona source resolves to a real skill directory (in `.codex/skills/*` or `src/user/codex/skills/*`) whose `SKILL.md` `name:` equals the dir name. Preserve existing repo grammar; do not invent a new skill-reference syntax. The literal placeholder token `name` (inside R2 rule bodies, e.g. `src/user/codex/personas/team-lead.md`) is excluded.
2. Every agent skill declaration in Codex source resolves to a real skill DIRECTORY by the same rule — resolution is by directory existence, not prose assertion, because spawned-worker capability depends on the Codex payload/user config.
3. Every skill named in a team-lead spawn template / orchestration prose exists and is registered in Codex source.
4. Source-vs-runtime is respected: repo-managed Codex skills live under `src/user/codex/skills/`, project-local skills live under `.codex/skills/`, and installed runtime skills live under `${CODEX_HOME:-~/.codex}/skills`. Flag any OpenAI Codex runtime reliance that can only be satisfied by a project-local `.codex/skills/` path without an explicit project-local assumption; do not edit Rust projection logic or generated runtime output.
5. No dead/unregistered refs (a skill invocation or agent skill declaration pointing at a non-existent dir).
6. **Lifecycle and report-delivery ownership** — for each Codex lifecycle operation threaded through the family, verify ownership: the orchestrator calls `spawn_agent`, tracks the returned agent ID, waits with `wait_agent` only when the report blocks the next step, relays necessary prompts with `send_input`, and closes with `close_agent`; workers/peers/advisors/reviewers deliver required reports, verdicts, and final reports to the orchestrator before idle/close and never claim to close sibling agents or manage cohorts. Cross-check parallel roles and report-delivery obligations — the coherent ones reveal the outlier. This is a cross-file invariant no single per-agent reviewer can see.

**Detection (seeds).**
- Registry: `for d in .codex/skills/*/ src/user/codex/skills/*/; do dir=$(basename "$d"); name=$(awk -F': ' '/^name:/{print $2; exit}' "$d/SKILL.md"); echo "$dir|$name|$d"; done` — flag rows where `dir != name`.
- Refs: grep Codex agent/persona sources for existing invocation grammar such as `(<skill-name>` and legacy `Skill(<token>)` examples; strip to token → drop token `name` → resolve against registry.
- Skill declarations: parse any Codex agent source skill declarations when present → resolve each by directory.
- Spawn/report mentions: grep `src/user/codex/personas/team-lead.md` and agent/skill lifecycle sections for skill-invocation tokens, prose skill names, `spawn_agent` templates, and report/final-report delivery obligations; emit lifecycle refs under `skill_refs` and report contracts under `report_delivery_obligations`.
- Root: registry row's path prefix (`src/user/codex/skills/` = repo-managed Codex source; `.codex/skills/` = project-local).

### D2 — Role & format-authority consistency

**Invariants.**
1. Each skill's "driven by @X" / "callable ONLY by @X" / "typically @X" / "format authority" claim names an agent whose stated responsibilities own it: code-review-verdict → `@staff-engineer` (general 6-dim) + `@security-engineer` (security dim); tdd/adr → `@staff-engineer` (+ `@security-engineer` for security); verify-ac → `@sdet`; prd → `@project-manager`; ux-spec/design-review/design-qa → `@ux-designer`; simplify-scout → `@senior-engineer`; vote → any agent; init-specs → spawns `@staff-engineer`.
2. No skill claims an agent a **constraint forbids**: a "no code / no source edits" agent (`@staff-engineer`, `@project-manager`, `@ux-designer`) must not drive a code-writing skill; `verify-ac`'s "@sdet reports as comments, never new issues" must agree with `src/user/codex/agents/sdet.toml` and `src/user/codex/agents/project-manager.toml` ("ONLY agent creating issues"); `verify-ac` ABORTs for any caller ≠ `@sdet`, so its real invoker must be `@sdet`.
3. A skill's documented invocation shape matches the Codex invocation grammar already present in the owning agent + team-lead sources.
4. **Hard-restriction skills** (those with an ABORT-on-wrong-caller Role Detection — code-review-verdict, verify-ac, design-review, design-qa, simplify-scout) have their restricted-caller set EXACTLY equal to `{agents with a Codex source skill declaration} ∪ {agents with a REAL first-person prose invocation}`. A **real first-person invocation** = the containing agent itself calls the skill as its own action. It EXCLUDES illustrative / meta-instruction / template / example / rule-body tokens (a legacy `Skill(x)` or Codex invocation describing how ANOTHER agent invokes, or an authoring example). **Canonical excluded case (verified — NOT a real invocation): the sole verify-ac invocation token in `src/user/codex/agents/staff-engineer.toml`** sits inside a rule-body bullet as an example of a skill a TDD prescribes for `@sdet` — staff-engineer lacks a Codex source skill declaration for verify-ac and verify-ac ABORTs for non-`@sdet`, so adding it would emit a FALSE Blocker. Soft "typically @X" doc skills (adr, prd, tdd, ux-spec) are advisory — plausibility only, not exact restriction.

**Detection (seeds).**
- Claims: `grep -rniE 'driven by|format authority|callable ONLY by|restricted to|typically .@|Role Detection' .codex/skills/*/SKILL.md src/user/codex/skills/*/SKILL.md` → parse claimed agent(s) + restriction style.
- For each claimed agent, read its Responsibilities / "What You Are NOT" and confirm ownership; flag mismatches.
- Contradictions: cross-grep `grep -ni 'never creates issues\|ONLY agent creating' src/user/codex/agents/sdet.toml src/user/codex/agents/project-manager.toml` ↔ `grep -ni 'never new issues\|reports as comments' src/user/codex/skills/verify-ac/SKILL.md`.
- Restricted-caller set: for each hard-restriction skill, compare its Role-Detection allowed set against the union above. **The prose-invocation classifier MUST distinguish "the containing agent invokes X" (real) from "describes @other / illustrative / template / rule-body example" (excluded)** via surrounding context (enclosing rule-body bullet, "example"/"e.g."/"prescribe" framing, subject = another agent). When in doubt cross-check Codex source declarations: a token whose containing agent LACKS a declaration for that skill AND the skill ABORTs for that agent is almost certainly illustrative — do NOT add it. Canonical excluded instance: the sole verify-ac invocation token in `src/user/codex/agents/staff-engineer.toml` (a rule-body example, not a first-person call).

### D3 — Naming & rename drift

**Invariants.**
1. No stale skill names: `verify` (→ `verify-ac`), `specs` (→ `init-specs`), and `code-review` (→ `code-review-verdict`) must not appear as project-skill refs. **Exception:** the distinct bundled-runtime `verify` and bundled `/code-review` skills are legitimate where referenced as the bundled tool — distinguish "renamed-away project skill" (drift) from "Codex-bundled" (legit) by surrounding context.
2. CLOSED persistent-set names (`advisor`, `security-advisor`, `ux-advisor`) are spelled consistently and treated as closed wherever enumerated (`src/user/codex/personas/team-lead.md` Rule 7 is canonical — reference, do not restate).
3. Role-tag prefixes (`[LEAD→]`, `[PM→]`, `[SE→]`, `[STAFF→]`, `[SEC→]`, `[SDET→]`, `[UX→]`) are used consistently across agents.
4. Severity ladders are spelled consistently between the skill that DEFINES them and agents that CITE them: staff/UX `Blocker / Concern / Suggestion / Question / Praise` (design-qa intentionally drops Question — preserve, do NOT "fix"); security `Critical / High / Medium / Low / Info`; verify-ac verdict ladder (`PASS/FAIL` + `BLOCK` + LIGHT `APPROVE`). Definition site (code-review-verdict/design-review/verify-ac) is canonical; agent citations must match.
5. Ephemeral name conventions (`impl-{DOCKET-ID}`, `impl-{DOCKET-ID}-fix-{N}`, `reviewer-{N}`, `security-reviewer-2`, `tdd-author`/`-{slug}`/`-fix-{N}`, `planner`, `verifier-criteria`, `verifier-integration`, `design-review-{N}`, `design-qa-{N}`, `coherence-reviewer`, `docs-researcher`, `docket-auditor`, `historical-auditor`) are spelled consistently between team-lead's spawn templates, the agents' self-descriptions, and the evolve-* templates.
6. **`<!-- COUPLING -->` family-membership notes are self-consistent.** These notes declare which sibling skills must be edited in lockstep, so a stale note silently breaks the contract. Verified families: (a) **doc-authoring family of 5** — adr, prd, tdd, ux-spec each say "update all 5 in lockstep" and name the other four incl. init-specs (init-specs's own note is the reserved-name one, not "all 5"); (b) **report-emission family of 4** — code-review-verdict, verify-ac, design-qa, design-review each say "update all 4 in lockstep" naming the same four; (c) **init-specs↔prd reserved-name lockstep** — both say "update init-specs and prd in lockstep". **Invariant:** for each note, (i) stated member COUNT = actual carrier set size, (ii) each named sibling actually carries a matching note (except documented one-directional bridges), (iii) each member's "When NOT to Use" delegation list agrees with the family roster. **One-directional bridges (whitelisted, NOT drift):** simplify-scout's report-only analog note; ux-spec's bridge into the report-emission family.

**Detection (seeds).**
- Stale refs: `grep -rnE 'Skill\((verify|specs|code-review)[,)]|/(verify|specs|code-review)/SKILL.md|\\((verify|specs|code-review)[,)]' src/user/codex/agents/*.toml src/user/codex/personas/*.md src/user/codex/skills/*/SKILL.md .codex/skills/*/SKILL.md` → classify each `verify`/`code-review` hit bundled-runtime (legit) vs renamed-project-skill (drift) by context.
- CLOSED-set: `grep -rnoE '(advisor|security-advisor|ux-advisor)' src/user/codex/agents/*.toml src/user/codex/personas/*.md` → confirm no near-variants (`sec-advisor`, `ux_advisor`).
- Role tags: `grep -rnoE '\[(LEAD|PM|SE|STAFF|SEC|SDET|UX)→\]' src/user/codex/agents/*.toml src/user/codex/personas/*.md` → compare against the canonical seven.
- Ladders: `grep -niE 'Blocker / Concern|Critical / High' src/user/codex/skills/code-review-verdict/SKILL.md src/user/codex/skills/design-review/SKILL.md` vs each agent citation; whitelist the design-qa "no Question" variant.
- Ephemeral labels: `grep -rnoE '(impl|reviewer|tdd-author|verifier|design-review|design-qa|security-reviewer)-[A-Za-z0-9{}-]+' src/user/codex/personas/team-lead.md` ↔ the same labels in citing agents and evolve-* templates. Labels are local ledger labels; Codex lifecycle operations target returned agent IDs.
- COUPLING: `grep -rn '<!-- COUPLING' src/user/codex/skills/*/SKILL.md .codex/skills/*/SKILL.md` → parse each note's "all N" count + named siblings; build family rosters; flag any note whose count ≠ roster size or whose named siblings don't reciprocate (EXCLUDING the one-directional bridges simplify-scout, ux-spec).

### D4 — Rules & canonical-block parity

**Invariants.**
1. **R-rule applicability matrix** — `src/user/codex/personas/team-lead.md` §Runtime Discipline matrix is source of truth (reference it; do NOT restate the bodies). Each agent's actual inclusion of R1–R7 matches the matrix (`✓` body / `▾` pointer / `—` omit / `✓*` body+variant). **Anchor the parse on the matrix HEADER ROW, NOT line numbers** (line numbers drift). Column key: tl=team-lead, st=staff, se=security, pm=project-manager, ux=ux-designer, sd=sdet, sr=senior. Known shape: R4 omitted for `@project-manager`; R5 present only for the three advisors (st/se/ux as ✓*), omitted for senior/sdet/pm; team-lead uses ▾ pointer for R2/R5/R7.
2. **CANONICAL:* block byte-parity** — each CANONICAL-tagged block is byte-identical across carriers **within its variant FAMILY** (modulo documented per-file exception). The "one global BANNER" model is FALSE — compare within the correct family. **The family rule keys on the OPENING-PREFIX STRING, never a hardcoded hash literal** (hashes drift the moment a banner is edited; no AC asserts a hash value). BANNER families:
   - **Leaf family** — every SKILL.md whose BANNER body contains the literal `This is a leaf skill` (currently adr, prd, tdd, ux-spec, code-review-verdict, design-review, design-qa, verify-ac, simplify-scout, brief). These differ only in an intentional **trailing clause** — so STRIP the trailing peer-messaging clause via a WITHIN-LINE substitution `sed 's/ The calling agent handles peer messaging.*$//'` (NOT a line-range delete: each BANNER body is ONE physical line, so a line-range delete collapses the whole body to empty and every leaf banner hashes to the empty-string SHA `da39a3ee…`, matching VACUOUSLY) before hashing, then compare the strip-normalized body and assert it is **byte-equal AND non-empty**; the per-skill tail is whitelisted, not drift.
   - **Orchestrator-prefix family** — opener `> **CRITICAL — applies to orchestrator AND every spawned worker:**` — evolve-agents, evolve-skills, evolve-config, evolve-coherence, evolve-model-distribution, and evolve-suite share the Codex worker banner when they use this prefix. Documented bootstrap variants with shorter one-shot bodies are allowed only when listed inline. **`evolve-coherence`'s OWN BANNER MUST match the shared worker body** (this skill spawns Codex workers that route findings back through the orchestrator — NOT the leaf body, NOT a bootstrap variant, NOT vote's).
   - **`vote` singleton** — opener `> **CRITICAL — applies to coordinator AND every spawned reviewer:**` — a THIRD family of one (adds a team-mode-delegation clause). `vote` is NOT leaf-family (its banner lacks `This is a leaf skill`). Do not group `vote` with leaf or orchestrator.
   - (Agent-side CRITICAL banners are a separate per-role convention NOT wrapped in CANONICAL markers — check agent banners for *semantic* parity of the prohibitions, not byte-identity. `review-and-comment` is the one skill intentionally OUTSIDE the CANONICAL:BANNER system: it carries a skill-specific operator-driven CRITICAL banner (per-item approval gate, gh-identity check) that fits no family — do NOT flag it as a missing banner.)
   - `CANONICAL:PITFALLS` — all 7 agents, byte-identical (single-family). `CANONICAL:HARVEST` — evolve-agents + evolve-skills only, byte-identical (the marked blocks are identical; the agent-vs-skill distinction between the two cycles lives in surrounding prose OUTSIDE the markers). `CANONICAL:ARGUMENT_HANDLING` and `CANONICAL:SAVE_AND_RETURN` — the 4 doc skills (adr, prd, tdd, ux-spec), byte-identical within each set. `CANONICAL:EVOLUTION-MODEL` — evolve-agents + evolve-skills + evolve-coherence (3 skills), single-family byte-identical; no variant families within this set.
3. **Rule-numbering asymmetry** — `src/user/codex/personas/team-lead.md` Rule 5 is source of truth (anchor on the Rule-5 prose, not a line number; reference, do not restate). Execution agents `@senior-engineer`/`@sdet` carry rules 1–10; doc/review agents `@staff-engineer` 1–9, `@security-engineer` 1–7, `@ux-designer` 1–7; `@project-manager` 1–6; team-lead 1–9. A doc agent acquiring a claim-first rule, or an execution agent losing it, is drift. **Documented exception: `@senior-engineer` uses UNNUMBERED bullets cross-tagged to the sdet scheme** — a naive `grep -E 'R[1-7]'` UNDER-detects; presence of a rule ≠ a numbered line. Treat senior-engineer's bullet style as satisfying the set by cross-tag, NOT by counting numbered headings; do NOT flag it as "missing rules."
4. **Doubling Rule / panel sizing** — `src/user/codex/personas/team-lead.md` Rule 8 is source of truth (reference). Citing skills must not contradict its numbers: `src/user/codex/skills/code-review-verdict/SKILL.md` single-default + opt-up-to-doubled language; `src/user/codex/skills/vote/SKILL.md` panel-sizing table base 2/2/3/4, doubled 4/4/6/8 capped at 8.

**Detection (seeds).**
- Matrix parity: locate by header row `grep -n '| Rule | tl | st | se | pm | ux | sd | sr' src/user/codex/personas/team-lead.md` (SUBSTRING match — the live row has a trailing `| Lines |` column); parse the rows below into the expected per-agent map; detect R-rule presence via `grep -nE 'R[1-7]\b' src/user/codex/agents/<agent>.toml` (the `\b` matches senior-engineer's bulleted `- **R1 ...**`) AND the `see team-lead.md §Runtime Discipline R{N}` pointer phrase; compare to expected (senior-engineer parse handled in the Rule-numbering seed below).
- Block byte-parity: for each `CANONICAL:<TAG>`, extract the BEGIN/END body per carrier, apply the family rule from invariant #2 (group by opening-prefix; for leaf, strip the peer-messaging clause first via `sed 's/ The calling agent handles peer messaging.*$//'`), pipe through `sed 's/[[:space:]]*$//'`, `shasum`, then flag carriers diverging from THEIR family's modal hash. Assert each strip-normalized body is BYTE-EQUAL **AND non-empty** (guard the vacuous empty==empty match).
- Rule-numbering: extract the highest top-level rule number per agent (`grep -noE '^[0-9]+\.'` in the rules section) vs expected count — **SKIP this numeric parse for `@senior-engineer`** (unnumbered bullets); confirm its 10 rules by cross-tag prose match.
- Doubling/panel: compare `src/user/codex/skills/vote/SKILL.md` panel numbers and `src/user/codex/skills/code-review-verdict/SKILL.md` single-default/opt-up language against team-lead Rule 8.

> **Intentional variants (do NOT mis-flag)** are enumerated inline per dimension (each carries a `(D<n> #<m>)` carve-out) and re-listed in the Phase 1 spawn template's `## Task` — reviewers honor them from those two sources.

---

## Orchestration Workflow

### Worker Setup & Lifecycle

1. Resolve `{today_date}` (run `date +%Y-%m-%d`) for date substitution.
2. Initialize an in-context **local phase ledger** up-front with entries for "Build XREF" (Phase 0), one "Audit <Dn>" per resolved dimension (Phase 1), and "Reconcile & Report" (Phase 2). Each ledger entry stores label, phase, spawned agent ID, status, report excerpt, retry-of, and close evidence.

| Phase | Agents | Lifecycle |
|---|---|---|
| 0 | `xref-builder` (senior-engineer, read-only shell access) | `spawn_agent` → record agent ID → `wait_agent` for report → `close_agent` before Phase 1 |
| 1 | `review-d{n}` per resolved dimension (staff-engineer, read-only) | Spawn ALL in same turn → record agent IDs → each delivers its dimension report → close each after consuming its report |
| 2 | `reconciler` (staff-engineer, read-only) | Spawn after ALL Phase 1 reports in → emit Report + Manifest → close after consuming report |

**Close protocol** (Codex): use returned agent IDs, not role labels, as lifecycle targets. `send_input(target=<agent-id>, message=...)` is for clarification or redirect while a worker is alive; `wait_agent(targets=[<agent-id>], timeout_ms=...)` collects blocking reports; `close_agent(target=<agent-id>)` runs only after the report is consumed and the local phase ledger has the report excerpt. A close acknowledgement alone is not cleanup proof — store explicit closed/reaped/terminated evidence in the local phase ledger, or mark cleanup degraded if that evidence is unavailable.

### Crash, Stall & Degraded Fallback

Detect failure via: (a) `wait_agent` timeout or completed status with no report; (b) `close_agent` failure or missing close evidence; (c) `spawn_agent()` returns an error.

- **Re-spawn ONCE** with a new worker, record the new agent ID in the local phase ledger as `retry_of=<prior-agent-id>`, and include a `Resume context:` block (prior partial report, ledger entry label, `{xref}`, target dimension).
- **Degraded single-reviewer fallback** (mirrors `src/user/codex/personas/team-lead.md` Rule 8): if a Phase 1 dimension reviewer fails TWICE (original spawn + retry both abort/empty), record that dimension verbatim as `DEGRADED: single-reviewer (ephemeral failed 2x)` and fold its scan into the reconciler — NEVER silently drop. If ALL four ephemerals are unavailable, fall back to the linear behavior (reconciler scans all four dimensions itself) with the `DEGRADED:` annotation.
- **Compaction recovery**: re-read `{verified_goal}`, the latest local phase ledger summary, `{xref}`, and the active phase template before any new `send_input`/`spawn_agent`/`wait_agent`/`close_agent` call.

### Phase 0 — Cross-Reference Index Builder (single `senior-engineer`)

Spawn ONE `xref-builder` per the Phase 0 template. Read-only shell access (grep/awk/parse). It builds the XREF the four Phase 1 reviewers consume, so each reviewer does not re-scan all files from scratch, and reports it verbatim to the orchestrator (captured as `{xref}` for Phase 1 substitution). **It does NOT judge** — judgment is Phase 1's job; XREF is signals-to-verify. The XREF schema is PINNED (see Data Models) — the builder emits exactly those keys as one fenced ` ```json ` block, every key present (`null`/`[]` for absent, never omit).

### Phase 1 — Four parallel dimension reviewers (`staff-engineer`)

Spawn one `review-d{n}` per resolved dimension, **all in the same turn** for parallelism. Each is read-only (no edits), receives `{xref}` + the instruction to read Codex agent/persona sources and the skill files **as needed to confirm** any XREF signal against ground truth before emitting a finding. Each emits findings in the per-finding format (see Report Format) scoped to its dimension. Reviewers do NOT peer-message — the orchestrator is the only relay; cross-dimension overlaps reconcile in Phase 2.

### Phase 2 — Reconciler (single `staff-engineer`)

Gate: the local phase ledger shows all Phase 1 dimension entries `completed`, each Phase 1 report consumed, and every Phase 1 agent ID closed or explicitly marked degraded. Then spawn one `reconciler`. Read-only. It:
1. Merges the reviewers' findings, **de-duplicating** by `(dimension, primary-location)` — a single ref can surface under D1 (unresolved) and D3 (rename drift); keep the most specific, cross-link the rest.
2. Assigns each confirmed finding a **fix-owner**: agent-side drift → `evolve-agents`; skill-side drift → `evolve-skills`; cross-cutting (both sides of one ref disagree) → `both`, noting which side is canonical (ladders → the skill is canonical; R-rules → team-lead is canonical).
3. Emits the **Coherence Report** + **Remediation Manifest** into the orchestrator context.

### Wrap-up

1. Close the reconciler by agent ID per lifecycle rules and record close evidence or degraded cleanup in the local phase ledger.
2. Surface any Blocker at the top of the report.
3. Report: dimensions audited, Blocker/Concern counts per dimension, the Remediation Manifest, any `DEGRADED:` annotations, and that NO file was modified (the skill is report-and-route only). Mechanize the no-edit attestation: `git status --porcelain -- src/user/codex/agents src/user/codex/personas .codex/skills src/user/codex/skills` MUST show no modification to target definition paths — paste that verification, not a narrative claim.

---

## Data Models

No persistent data plane. Two **in-context** artifacts (NOT written to disk — consistent with report-only): the XREF and the Remediation Manifest.

**XREF (Phase 0 → Phase 1 token `{xref}`) — PINNED schema.** The 4 parallel reviewers must parse it identically, so the builder emits EXACTLY these keys/fields as one fenced ` ```json ` block. All fields mandatory; use `null`/`[]` for absent, never omit a key:

```json
{
  "registry":           [{"dir": "code-review-verdict", "name": "code-review-verdict", "root": ".codex/skills|src/user/codex/skills", "runtime": "project-local|repo-managed|installed"}],
  "skill_refs":         [{"file": "src/user/codex/personas/team-lead.md", "line": 251, "token": "code-review-verdict", "kind": "codex-invocation|legacy-skill-call|prose"}],
  "agent_skill_declarations": [{"agent": "staff-engineer", "skill": "tdd"}],
  "report_delivery_obligations": [{"file": "src/user/codex/agents/staff-engineer.toml", "line": 1, "role": "staff-engineer", "obligation": "final report/verdict to orchestrator before close", "kind": "worker-report|advisor-reply|review-verdict"}],
  "role_claims":        [{"skill": "verify-ac", "file": "src/user/codex/skills/verify-ac/SKILL.md", "line": 25, "claimed_agent": "sdet", "restriction": "hard-abort|soft-typically"}],
  "ladders":            [{"name": "staff-severity", "def_site": "src/user/codex/skills/code-review-verdict/SKILL.md:350", "citations": ["src/user/codex/agents/staff-engineer.toml:170"]}],
  "canonical_blocks":   [{"tag": "BANNER", "family": "leaf|orchestrator|vote|single", "carriers": ["src/user/codex/skills/tdd/SKILL.md:12"], "family_hash": "<computed-live>"}],
  "coupling_notes":     [{"file": "src/user/codex/skills/adr/SKILL.md", "line": 64, "family": "doc-authoring", "stated_count": 5, "named_siblings": ["prd","tdd","ux-spec","init-specs"]}],
  "rule_presence":      [{"agent": "project-manager", "rules_present": ["R1","R2","R3","R5","R6","R7"], "top_rule_count": 6, "numbering_parse": "numbered|unnumbered-crosstag"}]
}
```

`coupling_notes` (D3 #6), `canonical_blocks.family`/`family_hash` (D4 #2), and `rule_presence.numbering_parse` (senior-engineer exception) are part of the pinned contract. `family_hash` is computed LIVE each run — pinned is the FIELD's presence, NEVER a fixed hash value.

**`[]` vs `null` semantics:** an empty array `[]` means "computed, none found"; `null` means "dimension not computed". On the `d1..d4` dimension-subset arg path, keys for UN-selected dimensions are `null` (not computed this run), distinct from a selected dimension that found nothing (`[]`).

---

## Coherence Report (Phase 2 output, in-context)

Human-readable. Blockers surfaced first. Per finding, emit a fenced block with these fields verbatim:

```
FINDING <n>: <title>
DIMENSION: D<n>
LOCATIONS: <agent-side file:line> [↔ <skill-side file:line> where applicable]
SEVERITY: Blocker | Concern | Suggestion | Question | Praise
DESCRIPTION: <what drifted and why it matters>
FIX-OWNER: evolve-agents | evolve-skills | both (CANONICAL: <side>)
```

Severity ladder reuses the staff-engineer ladder (the report is a staff-engineer artifact; D3 itself forbids ladder proliferation): **Blocker** (dead/unresolved ref, constraint contradiction — runtime-breaking), **Concern** (semantic drift that misleads but doesn't break), **Suggestion** (parity nit), **Question** (blocked on operator/agent confirmation before it can be dispositioned), **Praise** (notably coherent area). A clean run reports `0 Blockers, 0 Concerns` per dimension with an explicit `None` per manifest bucket.

---

## Remediation Manifest (Phase 2 output, in-context — routable)

A structured block the operator feeds into the next evolve-agents/evolve-skills Phase 0 input as signals-to-verify. One bucket per fix-owner so the operator can paste the relevant slice. Empty buckets read `None`. Manifest entries may include innovation-mandate and trial-protocol gaps detected during audit — for example, a mandate section absent from a sibling skill, trial protocol steps missing or incomplete (hypothesis / trial / operator approval / measurement / adopt or rollback), a missing operator-approval gate, or vocabulary drift between siblings (e.g., one skill uses different terminology for "model frontier" or "adopt or rollback"). These route under the appropriate fix-owner bucket (evolve-agents or evolve-skills) as Concerns.

```
Remediation Manifest
» evolve-agents   (agent-side drift; run: /evolve-agents [or /evolve-agents <agent>])
  - [D<n>][<severity>] <src/user/codex/agents/file.toml:line or src/user/codex/personas/file.md:line> — <one-line finding> → <suggested correction>
» evolve-skills   (skill-side drift; run: /evolve-skills [or /evolve-skills <skill>])
  - [D<n>][<severity>] <.codex/skills/.../SKILL.md or src/user/codex/skills/.../SKILL.md:line> — <one-line finding> → <suggested correction>
» both            (cross-cutting; canonical side noted; run both, fix canonical side first)
  - [D<n>][<severity>] <agent-side:line> ↔ <skill-side:line> — <finding> — CANONICAL: <side> → <correction>
```

**Routing is advisory only** — the skill does NOT invoke evolve-* itself (per CANONICAL:BANNER, and even the orchestrator routes by emitting the manifest, not by auto-running an evolve cycle, to keep the human-in-the-loop gate the operator trusts).

**Report ↔ Manifest invariant:** every Blocker/Concern in the Coherence Report appears as EXACTLY one manifest line under EXACTLY one fix-owner bucket (`both` counts as one line spanning two sides). Suggestions/Questions/Praise MAY be report-only (not all are actionable as edits).

---

## Spawning Templates

### Phase 0: @senior-engineer (XREF builder)

```
spawn_agent(agent_type="worker", message="xref-builder prompt (role: senior-engineer)", model="gpt-5.4-mini", reasoning_effort="medium")

You are the cross-reference index builder. Read-only shell access (grep/awk/parse). No file edits. No commits. No subagents.
Inventory: {inventory}

## Task
Build the XREF index over ALL Codex agent/persona sources (`src/user/codex/agents/*.toml`, `src/user/codex/personas/*.md`) and ALL skills (`.codex/skills/*/SKILL.md`, `src/user/codex/skills/*/SKILL.md`) using the detection seeds in the rubric — read `.codex/skills/evolve-coherence/SKILL.md` §The Coherence Rubric first; it is NOT in this prompt — (D1 registry/refs/agent_skill_declarations/report_delivery_obligations; D2 role_claims; D3 ladders/coupling_notes; D4 canonical_blocks/rule_presence). Compute family_hash LIVE per the D4 family rule (key on the opening-prefix string, strip trailing whitespace via `sed 's/[[:space:]]*$//'` before `shasum`). You do NOT judge — emit signals only.

## Output
Emit the PINNED XREF schema (Data Models §) as ONE fenced ```json block — every key present, `null`/`[]` for absent, never omit a key. send_input the orchestrator the json block verbatim and let the orchestrator update the local phase ledger.

## Rules
- Read-only. Do NOT edit files. Do NOT commit.
- No subagents: do NOT invoke `/vote`, invoke skills, call `spawn_agent`, or manage agent lifecycles. send_input the orchestrator for delegation.
- No peer-to-peer send_input — orchestrator is the only relay.
- Per-file grep — never bulk-cat. Exclude the placeholder token `name`.
```

### Phase 1: @staff-engineer (dimension reviewer — one per resolved dimension)

Substitute `<n>` (the dimension), `{today_date}`, `{verified_goal}`, `{xref}`.

```
spawn_agent(agent_type="worker", message="review-d<n> prompt (role: staff-engineer)", model="gpt-5.5", reasoning_effort="high")

You audit ONE coherence dimension: D<n>. Read-only — NO file edits, no commits, no subagents.
Verified goal: {verified_goal} (pre-verified — re-verify if your understanding diverges)

## XREF (signals-to-verify, NOT facts)
{xref}
> Before emitting ANY finding, confirm it against ground truth. To CONFIRM a pinned XREF signal, a ranged read of the cited `file:line` suffices (cheaper than a fresh whole-file grep); re-grep only for ABSENCE/coverage checks (a stale name anywhere, a missing carrier) where no line anchor exists. XREF is a signal; a finding built on an unconfirmed signal is reject-class.

## Task
Read `.codex/skills/evolve-coherence/SKILL.md` §The Coherence Rubric (it is NOT in this prompt), then apply the D<n> invariants + detection seeds. HONOR the whitelist of intentional variants — do NOT mis-flag design-qa's "no Question" ladder, the byte-identical HARVEST blocks, the `Skill(name)` placeholder, the meta-instruction verify-ac rule-body example in staff-engineer source, bundled-runtime `verify`, agent-banner semantic parity, the 3 BANNER families (incl. init-specs's shorter body + vote's singleton + leaf trailing clauses), review-and-comment's intentionally non-CANONICAL skill-specific banner, or the one-directional COUPLING bridges (simplify-scout, ux-spec).

## Output (per finding)
FINDING <n>: <title> / DIMENSION: D<n> / LOCATIONS: <file:line both sides> / SEVERITY: <ladder> / DESCRIPTION: <...> / FIX-OWNER: evolve-agents|evolve-skills|both (CANONICAL: <side>). Or "No findings." send_input the orchestrator verbatim; the orchestrator updates the local phase ledger.

## Rules
- Read-only. No file edits. No commits. Do NOT invoke `/vote`, invoke skills, call `spawn_agent`, or manage agent lifecycles.
- No peer-to-peer send_input — orchestrator is the only relay.
```

### Phase 2: @staff-engineer (reconciler)

Substitute `{today_date}`, `{dimension_reports}` (all Phase 1 reports verbatim), `{xref}`.

```
spawn_agent(agent_type="worker", message="reconciler prompt (role: staff-engineer)", model="gpt-5.5", reasoning_effort="high")

Reconcile the four dimension reports into a Coherence Report + Remediation Manifest. Read-only — NO edits, no commits, no subagents.

## Dimension reports
{dimension_reports}
## XREF
{xref}

## Task
1. Merge + de-dupe findings by (dimension, primary-location) — keep the most specific, cross-link the rest.
2. Assign each finding a fix-owner (evolve-agents / evolve-skills / both + canonical side: ladders→skill canonical, R-rules→team-lead canonical).
3. Emit the Coherence Report (per-finding format) with Blockers first, AND the Remediation Manifest (3 buckets, empty reads `None`). Enforce the Report↔Manifest 1:1-for-actionable invariant. Annotate any DEGRADED dimension verbatim.

## Rules
- Read-only. No file edits. No commits. Do NOT invoke `/vote`, invoke skills, call `spawn_agent`, or manage agent lifecycles.
- No peer-to-peer send_input — orchestrator is the only relay.
```

---

## Rules

1. **Report-and-route ONLY.** The skill and every worker NEVER edit/write Codex agent/persona sources or `*/SKILL.md`, and NEVER self-invoke evolve-*. See the No-Edit Guard.
2. **Workers are read-only.** Never commit.
3. **Fail loud.** See Crash, Stall & Degraded Fallback — never silently drop a dimension.
4. **Clean up.** Close all spawned agent IDs after wrap-up and record close evidence in the local phase ledger.
