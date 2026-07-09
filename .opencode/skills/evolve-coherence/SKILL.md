---
name: evolve-coherence
description: >
  Audit coherence between agents/*.md and the Opencode skill ecosystem (.opencode/skills/*)
  across four dimensions, return a Coherence Report + Remediation Manifest to the caller/orchestrator, and ROUTE fixes to
  evolve-agents/evolve-skills. REPORT-AND-ROUTE ONLY: despite the evolve- prefix it NEVER edits
  any agent/skill file and NEVER self-invokes the evolve-* skills.
  Run as a post-edit gate after standalone evolve-agents/evolve-skills edits (evolve-suite runs it automatically).
  Trigger: "evolve coherence", "audit coherence", "check agent/skill coherence", "cross-reference audit".
argument-hint: "[dimension(s) d1..d4]"
---

<!-- CANONICAL:BANNER:BEGIN -->
> **CRITICAL — applies to evolve-coherence:** (1) Do NOT commit ANY changes (no `git add`, `git commit`, or `git push`) unless EXPLICITLY instructed by the user. (2) This skill MUST NOT dispatch subagents, invoke `skill(vote)`, call `skill()` to route work, or form/manage a worker pool — return one Coherence Report + Remediation Manifest to the caller/orchestrator.
<!-- CANONICAL:BANNER:END -->

# Evolve Coherence

You are the **Coherence Audit Reporter**. Build a cross-reference index over all agents + Opencode skills, run the four-dimension coherence audit in this session, and return one **Coherence Report** plus a routable **Remediation Manifest** to the caller/orchestrator.

> **REPORT + ROUTE ONLY — read this before anything else.** Unlike its siblings `evolve-agents`/`evolve-skills` (which *apply* edits to definition files), `evolve-coherence` **NEVER edits any agent or skill file** and **NEVER self-invokes `evolve-agents`/`evolve-skills`**. Its only output is a Coherence Report + a Remediation Manifest the **operator** feeds to the evolve-* skills. The `evolve-` prefix names the family it audits, not a change capability. This is enforced by the No-change Guard below.

<!-- CANONICAL:EVOLUTION-MODEL:BEGIN -->
**Evolutionary model (shared vocabulary — evolve-agents, evolve-skills, evolve-coherence).** One cycle = one **generation**: the current definition file is the **parent genome**, the post-cycle file the **offspring**, the changelog entry the birth record (changelogs are the **phylogenetic record**; ADR 0001 compaction = fossil consolidation). A **trait** is one Content-Gate-passing behavioral unit; an **allele** is an alternative formulation of a trait; the file is the heritable **genome**, the population is the agents/skills under this cycle. **Fitness signals** are the Phase 0 audit measurements (pitfalls re-fires, operator-corrections, tool stalls, error/abort, model-routing, prior `Trial:`/`Drift:` outcomes). **Natural selection** assigns each evaluated trait a disposition from CITED fitness — AMPLIFY (cited gain → propagate family-wide in Phase 2 = positive selection) or CULL (cited recurring failure → remove = purifying selection); unlisted traits default to RETAIN. The **Content Gate is purifying selection** on every introduced allele. **Genetic drift** is bounded, fitness-INDEPENDENT neutral allele-substitution on a no-signal trait (see the drift operator). **Speciation/extinction** (new/retired organism) is a Phase 2 event gated by operator approval + vote, floored by the **biodiversity invariant** (never cull the last carrier of a live niche). Adaptive change and drift alike pass the operator-approval HARD GATE, are measured by the next cycle's Phase 0 audit, and adopt-or-rollback via the Phase 1 self-correct step. **evolve-coherence does not reproduce** — it is the **reproductive-isolation sentinel**: it detects cross-organism incompatibility (parity/contract drift) and routes corrective selection to evolve-agents/evolve-skills; it never edits.
<!-- CANONICAL:EVOLUTION-MODEL:END -->

## Innovation Mandate

Each evolve-coherence cycle applies an AI-first lens: audit whether the sibling evolve-* skills' innovation mandate sections are present, internally coherent, and mutually consistent. Flag any evolve-agents or evolve-skills skill missing an innovation mandate, an incomplete scientific trial protocol (hypothesis / trial / operator approval / measurement / adopt or rollback steps), a missing operator-approval gate between Trial and Measurement, or terminology drift from siblings (e.g., one skill uses different vocabulary for "model frontier" or "scientific trial protocol"). Route all findings into the Remediation Manifest for evolve-agents/evolve-skills to action. This skill AUDITS and SURFACES — it does not run trials, apply changes, or execute any step of the trial protocol.

---

## Argument Handling

Audited dimensions are determined by `\$ARGUMENTS` (a single optional positional). No `days=N` window — this skill audits CURRENT files, not historical session history (a deliberate divergence from evolve-*).

- **No argument** (`/evolve-coherence`): audit ALL agents + ALL skills across all four dimensions D1–D4.
- **Dimension subset** (`/evolve-coherence d1,d3`): comma-separated list, subset of `d1..d4`. Restricts Phase 1 to the named dimension audit passes.
- **Reject** any token outside `d1..d4` (e.g. `d5`, `foo`, a `days=N`): print a usage note (`Usage: /evolve-coherence [d1..d4 comma list]`) and abort.

---

## Pre-flight

> **Operator prompts:** All operator-facing questions in Pre-flight MUST use `question` with pre-generated selectable options (1-4 questions per call; **max 4 options per question regardless of `multiSelect`** — the API rejects >4); max 12-char `header`. If the operator needs to pick more than 4, ask a routing question first ("which category?") then a second narrow question. Free-text is permitted ONLY when the operator must paste material that doesn't fit options AFTER a structured option-led question routes them there.

Before analysis:

1. **Goal alignment (HARD GATE)** — Team mode: adopt the verified goal from the orchestrator prompt; re-verify if your understanding diverges. Standalone: `question` with options "All 4 dimensions", "Specific dimension(s)" (follow-up multiSelect over D1/D2/D3/D4, max 4), "Address operator-reported drift (free-text follow-up)", "Abort". Capture as `{verified_goal}`. Do not proceed until verified.
2. **Resolve dimensions** — Parse `\$ARGUMENTS` per Argument Handling. Default = all four. Store as `{dimensions}` (an ordered subset of D1–D4). Reject out-of-range tokens and abort.
3. **Inventory agents + skills** — Run `find agents .opencode/skills -maxdepth 2 \( -path 'agents/*.md' -o -path '.opencode/skills/*/SKILL.md' \) -exec wc -l {} + 2>/dev/null` and `find .opencode/skills -mindepth 1 -maxdepth 1 -type d 2>/dev/null` (find tolerates an absent root, whereas a zsh glob nomatch-aborts the whole command even with `2>/dev/null`). Capture the file set + counts as `{inventory}` for the Phase 0 build. If no agent files OR no Opencode skill files are found, inform the operator and abort.
4. **Scope-confirmation gate (HARD GATE)** — The all-targets inventory always exceeds 3 (7 agents + 13+ skills). Surface the planned scope via `question` with options: "Proceed (all <N> files, <dims> dimensions)", "Restrict dimensions (multiSelect D1–D4 follow-up)", "Abort". List the agent + skill counts and the resolved dimensions in the question body so the operator sees est. cycle weight before commit. Team mode: skip — orchestrator already verified scope.

---

## No-change Guard (falsifiable)

This skill MUST NOT `edit` or `write` any path matching `agents/*.md` or `.opencode/skills/*/SKILL.md`, including its own file. The XREF and Remediation Manifest are **in-context** artifacts (never written to disk, per Data Models §); progress bookkeeping uses `todowrite`, not `write`/`edit`. A needed fix is emitted into the Remediation Manifest; it is NOT applied here. Removing `edit`/`write` from the available tool set is defense-in-depth atop this prose Guard, not a replacement for it.

---

## The Coherence Rubric (FOUR dimensions — invariants + detection)

For each dimension: the **invariants** (checkable assertions) and the **detection method** (concrete grep/parse seeds). Seeds are starting points; each audit pass ALWAYS confirms an XREF signal against ground truth before emitting a finding — XREF is signals-to-verify, not facts. To CONFIRM a pinned signal, a ranged `read` of the XREF's cited `file:line` suffices (cheaper than a fresh whole-file grep); re-grep only for ABSENCE/coverage checks (a stale name appearing anywhere, a missing carrier) where no line anchor exists. As the **reproductive-isolation sentinel** (see CANONICAL:EVOLUTION-MODEL), evolve-coherence uses these four dimensions to detect maladaptive divergence that breaks interbreeding — parity/contract drift that would make a shared gene (trait or CANONICAL block) incompatible across the population. Each dimension is a reproductive-isolation check, not a quality-improvement step; corrective selection routes to evolve-agents/evolve-skills via the Remediation Manifest.

### D1 — Skill references & registration integrity

**Invariants.**
1. Every `skill(<token>)` call in any agent resolves to a real Opencode skill directory under `.opencode/skills/*` whose `SKILL.md` `name:` equals the dir name. The literal placeholder token `name` (inside R2 rule bodies, e.g. `agents/team-lead.md`) is excluded.
2. Every agent frontmatter `skills:` array entry resolves to a real skill DIRECTORY by the same rule — resolution is by directory existence, NOT frontmatter.
3. Every skill named in team-lead routing prose or worker prompt text exists and is registered.
4. Opencode skill-path convention is respected: project skill references use `.opencode/skills/<name>/SKILL.md`; flag non-Opencode skill roots for project skills unless a doc explicitly talks about bundled/global runtime skills.
5. No dead/unregistered refs (a `skill(x)` or frontmatter entry pointing at a non-existent dir).
6. **Hub-and-spoke handoff ownership** — for each structured handoff threaded through the family (plan approval, review verdicts, verification reports, vote delegation payloads), verify the producing role and relay path are stated consistently: leaf roles return reports to team-lead/caller; team-lead relays outcomes to the next worker or operator. Cross-check parallel roles — the coherent ones reveal the outlier. This is a cross-file invariant no single file can reveal.

**Detection (seeds).**
- Registry: `for d in .opencode/skills/*/; do dir=$(basename "$d"); declared=$(awk -F': ' '/^name:/{print $2; exit}' "$d/SKILL.md"); echo "$dir|$declared|$d"; done` — flag rows where `dir != declared`.
- Refs: `grep -rnoE 'skill\(([a-z][a-z-]*)' agents/*.md` → strip to token → drop token `name` → resolve against registry.
- Frontmatter: parse each agent's `skills:` YAML list (under `^skills:` to next top-level key) → resolve each.
- Team-lead routing mentions: `grep -noE 'skill\(([a-z][a-z-]*)' agents/team-lead.md` + prose skill names → resolve.
- Root: registry row's path prefix must be `.opencode/skills/`; any other project-skill root found during the ref scan is drift.

### D2 — Role & format-authority consistency

**Invariants.**
1. Each skill's "driven by @X" / "callable ONLY by @X" / "typically @X" / "format authority" claim names an agent whose stated responsibilities own it: code-review-verdict → `@staff-engineer` (general 6-dim) + `@security-engineer` (security dim) + `@distinguished-engineer` (Medium+ advisor, general 6-dim); tdd/adr → `@staff-engineer` (+ `@security-engineer` for security); verify-ac → `@sdet`; prd → `@project-manager`; ux-spec/design-review/design-qa → `@ux-designer`; simplify-scout → `@senior-engineer` + `@distinguished-engineer` (deep-impl); vote → any agent; init-specs → uses `@staff-engineer`.
2. No skill claims an agent a **constraint forbids**: a "no code / no source edits" agent (`@staff-engineer`, `@project-manager`, `@ux-designer`) must not drive a code-writing skill; `verify-ac`'s "@sdet reports as comments, never new issues" must agree with `agents/sdet.md` and `agents/project-manager.md` ("ONLY agent creating issues"); `verify-ac` ABORTs for any caller ≠ `@sdet`, so its real invoker must be `@sdet`.
3. A skill's documented invocation shape (`skill(x, "<scope>")`) matches how the owning agent + team-lead invoke it.
4. **Hard-restriction skills** (those with an ABORT-on-wrong-caller Role Detection — code-review-verdict, verify-ac, design-review, design-qa, simplify-scout) have their restricted-caller set EXACTLY equal to `{agents holding the skill in frontmatter} ∪ {agents with a REAL first-person prose invocation}`. A **real first-person invocation** = the containing agent itself calls the skill as its own action. It EXCLUDES illustrative / meta-instruction / template / example / rule-body tokens (a `skill(x)` describing how ANOTHER agent invokes, or an authoring example). **Canonical excluded case (verified — NOT a real invocation): the sole `skill(verify-ac)` token in `agents/staff-engineer.md`** sits inside a rule-body bullet as an example of a skill a TDD prescribes for `@sdet` — staff-engineer lacks verify-ac in frontmatter and verify-ac ABORTs for non-`@sdet`, so adding it would output a FALSE Blocker. Soft "typically @X" doc skills (adr, prd, tdd, ux-spec) are advisory — plausibility only, not exact restriction.

**Detection (seeds).**
- Claims: `grep -rniE 'driven by|format authority|callable ONLY by|restricted to|typically .@|Role Detection' .opencode/skills/*/SKILL.md` → parse claimed agent(s) + restriction style.
- For each claimed agent, read its Responsibilities / "What You Are NOT" and confirm ownership; flag mismatches.
- Contradictions: cross-grep `grep -ni 'never creates issues\|ONLY agent creating' agents/sdet.md agents/project-manager.md` ↔ `grep -ni 'never new issues\|reports as comments' .opencode/skills/verify-ac/SKILL.md`.
- Restricted-caller set: for each hard-restriction skill, compare its Role-Detection allowed set against the union above. **The prose-invocation classifier MUST distinguish "the containing agent invokes X" (real) from "describes @other / illustrative / template / rule-body example" (excluded)** via surrounding context (enclosing rule-body bullet, "example"/"e.g."/"prescribe" framing, subject = another agent). When in doubt cross-check frontmatter: a token whose containing agent LACKS the skill in frontmatter AND the skill ABORTs for that agent is almost certainly illustrative — do NOT add it. Canonical excluded instance: the sole `skill(verify-ac)` token in `agents/staff-engineer.md` (a rule-body example, not a first-person call).

### D3 — Naming & rename drift

**Invariants.**
1. No stale skill names: `verify` (→ `verify-ac`), `specs` (→ `init-specs`), and `code-review` (→ `code-review-verdict`) must not appear as project-skill refs. **Exception:** the distinct bundled-runtime `verify` and bundled `/code-review` skills are legitimate where referenced as the bundled tool — distinguish "renamed-away project skill" (drift) from "legacy-runtime-bundled" (legit) by surrounding context.
2. CLOSED persistent-set names (`advisor`, `security-advisor`, `ux-advisor`) are spelled consistently and treated as closed wherever enumerated (`agents/team-lead.md` Rule 7 is canonical — reference, do not restate).
3. Role-tag prefixes (`[LEAD→]`, `[PM→]`, `[SE→]`, `[STAFF→]`, `[SEC→]`, `[SDET→]`, `[UX→]`, `[DE→]`) are used consistently across agents.
4. Severity ladders are spelled consistently between the skill that DEFINES them and agents that CITE them: staff/UX `Blocker / Concern / Suggestion / Question / Praise` (design-qa intentionally drops Question — preserve, do NOT "fix"); security `Critical / High / Medium / Low / Info`; verify-ac verdict ladder (`PASS/FAIL` + `BLOCK` + LIGHT `APPROVE`). Definition site (code-review-verdict/design-review/verify-ac) is canonical; agent citations must match.
5. Ephemeral name conventions (`impl-{DOCKET-ID}`, `impl-{DOCKET-ID}-fix-{N}`, `reviewer-{N}`, `security-reviewer-2`, `tdd-author`/`-{slug}`/`-fix-{N}`, `planner`, `verifier-criteria`, `verifier-integration`, `design-review-{N}`, `design-qa-{N}`, `coherence-reviewer`, `docs-researcher`, `docket-auditor`, `historical-auditor`) are spelled consistently between team-lead's routing templates, the agents' self-descriptions, and the evolve-* instructions.
6. **`<!-- COUPLING -->` family-membership notes are self-consistent.** These notes declare which sibling skills must be edited in lockstep, so a stale note silently breaks the contract. Verified families: (a) **doc-authoring family of 5** — adr, prd, tdd, ux-spec each say "update all 5 in lockstep" and name the other four incl. init-specs (init-specs's own note is the reserved-name one, not "all 5"); (b) **report-emission family of 4** — code-review-verdict, verify-ac, design-qa, design-review each say "update all 4 in lockstep" naming the same four; (c) **init-specs↔prd reserved-name lockstep** — both say "update init-specs and prd in lockstep". **Invariant:** for each note, (i) stated member COUNT = actual carrier set size, (ii) each named sibling actually carries a matching note (except documented one-directional bridges), (iii) each member's "When NOT to Use" delegation list agrees with the family membership. **One-directional bridges (whitelisted, NOT drift):** simplify-scout's report-only analog note; ux-spec's bridge into the report-emission family.

**Detection (seeds).**
- Stale refs: `grep -rnE 'skill\((verify|specs|code-review)[,)]|\.opencode/skills/(verify|specs|code-review)/' agents/*.md .opencode/skills/*/SKILL.md` → classify each `verify`/`code-review` hit bundled-runtime (legit) vs renamed-project-skill (drift) by context.
- CLOSED-set: `grep -rnoE '(advisor|security-advisor|ux-advisor)' agents/*.md` → confirm no near-variants (`sec-advisor`, `ux_advisor`).
- Role tags: `grep -rnoE '\[(LEAD|PM|SE|STAFF|SEC|SDET|UX|DE)→\]' agents/*.md` → compare against the canonical eight.
- Ladders: `grep -niE 'Blocker / Concern|Critical / High' .opencode/skills/code-review-verdict/SKILL.md .opencode/skills/design-review/SKILL.md` vs each agent citation; whitelist the design-qa "no Question" variant.
- Ephemeral names: `grep -rnoE '(impl|reviewer|tdd-author|verifier|design-review|design-qa|security-reviewer)-[A-Za-z0-9{}-]+' agents/team-lead.md` ↔ the same tokens in citing agents and evolve-* templates.
- COUPLING: `grep -rn '<!-- COUPLING' .opencode/skills/*/SKILL.md` → parse each note's "all N" count + named siblings; build family memberships; flag any note whose count ≠ membership size or whose named siblings don't reciprocate (EXCLUDING the one-directional bridges simplify-scout, ux-spec).

### D4 — Rules & canonical-block parity

**Invariants.**
1. **R-rule applicability matrix** — `src/user/opencode/skills/team-doctrine/references/runtime-discipline.md` §matrix is source of truth (`agents/team-lead.md` §Runtime Discipline now holds only a LOCAL R1/R3/R4/R6 copy + pointer, NOT the matrix; reference the matrix file, do NOT restate the bodies). Each agent's actual inclusion of R1–R7 matches the matrix (`✓` body / `▾` pointer / `—` omit / `✓*` body+variant). **Anchor the parse on the matrix HEADER ROW, NOT line numbers** (line numbers drift). Column key: tl=team-lead, st=staff, de=distinguished-engineer, se=security, pm=project-manager, ux=ux-designer, sd=sdet, sr=senior. Known shape: R4 omitted for `@project-manager`; R5 present only for the four seats (st/de/se/ux as ✓*), omitted for senior/sdet/pm; team-lead uses ▾ pointer for R2/R5/R7.
2. **CANONICAL:* block byte-parity** — each CANONICAL-tagged block is byte-identical across carriers **within its variant FAMILY** (modulo documented per-file exception). The "one global BANNER" model is FALSE — compare within the correct family. **The family rule keys on the OPENING-PREFIX STRING, never a hardcoded hash literal** (hashes drift the moment a banner is edited; no AC asserts a hash value). BANNER families:
   - **Leaf family** — every SKILL.md whose BANNER body contains the literal `This is a leaf skill` (currently adr, prd, tdd, ux-spec, code-review-verdict, design-review, design-qa, verify-ac, simplify-scout, brief). These differ only in an intentional **trailing caller-relay clause** — strip that live clause text with a within-line substitution (NOT a line-range delete: each BANNER body is ONE physical line, so a line-range delete collapses the whole body to empty and every leaf banner hashes to the empty-string SHA `da39a3ee…`, matching VACUOUSLY) before hashing, then compare the strip-normalized body and assert it is **byte-equal AND non-empty**; the per-skill tail is whitelisted, not drift.
   - **Task-dispatch orchestrator family** — opener identifies orchestrator + worker guard — evolve-agents, evolve-skills, and evolve-config are byte-identical; **`init-specs` shares the shape but has a SHORTER divergent body** — treat init-specs's shorter body as a documented intra-family variant (one-shot bootstrap). **`evolve-coherence`'s OWN BANNER is a report-only family** — do NOT group it with worker-dispatching skills, the leaf body, init-specs's shorter body, or vote's singleton.
   - **`vote` singleton** — opener identifies coordinator + reviewer guard — a THIRD family of one (adds a team-mode-delegation clause). `vote` is NOT leaf-family (its banner lacks `This is a leaf skill`). Do not group `vote` with leaf or orchestrator.
   - (Agent-side CRITICAL banners are a separate per-role convention NOT wrapped in CANONICAL markers — check agent banners for *semantic* parity of the prohibitions, not byte-identity. `review-and-comment` is the one skill intentionally OUTSIDE the CANONICAL:BANNER system: it carries a skill-specific operator-driven CRITICAL banner (per-item approval gate, gh-identity check) that fits no family — do NOT flag it as a missing banner.)
   - `CANONICAL:PITFALLS` — 7 carriers (every agent except team-lead, incl. distinguished-engineer), byte-identical (single-family). `CANONICAL:HARVEST` — evolve-agents + evolve-skills only, byte-identical (the marked blocks are identical; the agent-vs-skill distinction between the two cycles lives in surrounding prose OUTSIDE the markers). `CANONICAL:ARGUMENT_HANDLING` and `CANONICAL:SAVE_AND_RETURN` — the 4 doc skills (adr, prd, tdd, ux-spec), byte-identical within each set. `CANONICAL:EVOLUTION-MODEL` — evolve-agents + evolve-skills + evolve-coherence (3 skills), single-family byte-identical; no variant families within this set.
3. **Rule-numbering asymmetry** — `agents/team-lead.md` Rule 5 is source of truth (anchor on the Rule-5 prose, not a line number; reference, do not restate). Execution agents `@senior-engineer`/`@sdet` carry rules 1–10; doc/review agents `@staff-engineer` 1–9, `@security-engineer` 1–7, `@ux-designer` 1–7; `@project-manager` 1–6; team-lead 1–9. A doc agent acquiring a claim-first rule, or an execution agent losing it, is drift. **Documented exception: `@senior-engineer` and `@distinguished-engineer` use UNNUMBERED bullets cross-tagged to the sdet scheme** — a naive `grep -E 'R[1-7]'` UNDER-detects; presence of a rule ≠ a numbered line. Treat senior-engineer's and distinguished-engineer's bullet style as satisfying the set by cross-tag, NOT by counting numbered headings; do NOT flag it as "missing rules."
4. **Doubling Rule / panel sizing** — `agents/team-lead.md` Rule 8 is source of truth (reference). Citing skills must not contradict its numbers: `.opencode/skills/code-review-verdict/SKILL.md` single-default + opt-up-to-doubled language; `.opencode/skills/vote/SKILL.md` panel-sizing table base 2/2/3/4, doubled 4/4/6/8 capped at 8.

**Detection (seeds).**
- Matrix parity: locate by header row `grep -n '| Rule | tl | st | de | se | pm | ux | sd | sr' src/user/opencode/skills/team-doctrine/references/runtime-discipline.md` (SUBSTRING match — the live row has a trailing `| Lines |` column); parse the rows below into the expected per-agent map; detect R-rule presence via `grep -nE 'R[1-7]\b' agents/<agent>.md` (the `\b` matches senior-engineer's bulleted `- **R1 ...**`) AND the `see team-lead.md §Runtime Discipline R{N}` pointer phrase; compare to expected (senior-engineer parse handled in the Rule-numbering seed below).
- Block byte-parity: for each `CANONICAL:<TAG>`, extract the BEGIN/END body per carrier, apply the family rule from invariant #2 (group by opening-prefix; for leaf, strip the trailing caller-relay clause first), pipe through `sed 's/[[:space:]]*$//'`, `shasum`, then flag carriers diverging from THEIR family's modal hash. Assert each strip-normalized body is BYTE-EQUAL **AND non-empty** (guard the vacuous empty==empty match).
- Rule-numbering: extract the highest top-level rule number per agent (`grep -noE '^[0-9]+\.'` in the rules section) vs expected count — **SKIP this numeric parse for `@senior-engineer`** (unnumbered bullets); confirm its 10 rules by cross-tag prose match.
- Doubling/panel: compare `.opencode/skills/vote/SKILL.md` panel numbers and `.opencode/skills/code-review-verdict/SKILL.md` single-default/opt-up language against team-lead Rule 8.

> **Intentional variants (do NOT mis-flag)** are enumerated inline per dimension (each carries a `(D<n> #<m>)` carve-out) and re-listed in the Phase 1 analysis instructions — audit passes honor them from those two sources.

---

## Analysis Workflow

### Setup

1. Resolve `{today_date}` (run `date +%Y-%m-%d`) for date substitution.
2. `todowrite` up-front: "Build XREF" (Phase 0), one "Audit <Dn>" per resolved dimension (Phase 1), and "Reconcile & Report" (Phase 2).
3. Execute every phase in the current skill context. This skill has no worker lifecycle and no subagent dispatch path.

| Phase | Work product | Lifecycle |
|---|---|---|
| 0 | XREF index | Build directly, then mark "Build XREF" completed |
| 1 | Dimension findings | Run one self-contained audit pass per resolved dimension, then mark each "Audit <Dn>" completed |
| 2 | Coherence Report + Remediation Manifest | Reconcile confirmed findings and return the report to the caller/orchestrator |

### Failure & Degraded Fallback

No external-worker recovery exists because the skill launches no workers. If an inventory, read, or grep command fails, diagnose once. If missing evidence prevents a dimension from being checked, record that dimension verbatim as `DEGRADED: <dimension> (<cause>)` and surface a Question or Blocker instead of dropping it.

- **Partial evidence:** carry confirmed findings forward, label unverified sections `DEGRADED:`, and state which files or commands were unavailable.
- **Compaction recovery:** re-read `{verified_goal}`, `todowrite()`, `{xref}`, and the active phase instructions before continuing.

### Phase 0 — Cross-Reference Index Build

Build the XREF directly with read-only grep/awk/parse. It lets the Phase 1 audit passes reuse signals without re-scanning all files from scratch. **It does NOT judge** — judgment is Phase 1's job; XREF is signals-to-verify. The XREF schema is PINNED (see Data Models) — emit exactly those keys as one fenced ` ```json ` block, every key present (`null`/`[]` for absent, never omit).

### Phase 1 — Dimension Audit Passes

Run one audit pass per resolved dimension in the current context. Each pass reads `agents/*.md` and `.opencode/skills/*/SKILL.md` **as needed to confirm** any XREF signal against ground truth before emitting a finding. Emit findings in the per-finding format (see Report Format) scoped to the dimension. Cross-dimension overlaps reconcile in Phase 2.

### Phase 2 — Reconcile

Gate: `todowrite()` shows all selected Phase 1 dimension audits `completed`. Then:
1. Merge the dimension findings, **de-duplicating** by `(dimension, primary-location)` — a single ref can surface under D1 (unresolved) and D3 (rename drift); keep the most specific, cross-link the rest.
2. Assign each confirmed finding a **fix-owner**: agent-side drift → `evolve-agents`; skill-side drift → `evolve-skills`; cross-cutting (both sides of one ref disagree) → `both`, noting which side is canonical (ladders → the skill is canonical; R-rules → team-lead is canonical).
3. Emit the **Coherence Report** + **Remediation Manifest** into the caller/orchestrator context.

### Wrap-up

1. Surface any Blocker at the top of the report.
2. Report: dimensions audited, Blocker/Concern counts per dimension, the Remediation Manifest, any `DEGRADED:` annotations, and that NO file was modified by this skill (the skill is report-and-route only).
3. Mechanize the no-edit attestation: capture `git status --porcelain -- agents .opencode/skills` before and after the run and paste the unchanged result, not a narrative claim.

---

## Data Models

No persistent data plane. Two **in-context** artifacts (NOT written to disk — consistent with report-only): the XREF and the Remediation Manifest.

**XREF (Phase 0 → Phase 1 input `{xref}`) — PINNED schema.** The audit passes must parse it identically, so the Phase 0 build emits EXACTLY these keys/fields as one fenced ` ```json ` block. All fields mandatory; use `null`/`[]` for absent, never omit a key:

```json
{
  "registry":           [{"dir": "code-review-verdict", "name": "code-review-verdict", "root": ".opencode/skills", "available": true}],
  "skill_refs":         [{"file": "agents/team-lead.md", "line": 251, "token": "code-review-verdict", "kind": "skill-call|prose"}],
  "frontmatter_skills": [{"agent": "staff-engineer", "skill": "tdd"}],
  "role_claims":        [{"skill": "verify-ac", "file": ".opencode/skills/verify-ac/SKILL.md", "line": 25, "claimed_agent": "sdet", "restriction": "hard-abort|soft-typically"}],
  "ladders":            [{"name": "staff-severity", "def_site": ".opencode/skills/code-review-verdict/SKILL.md:350", "citations": ["agents/staff-engineer.md:170"]}],
  "canonical_blocks":   [{"tag": "BANNER", "family": "leaf|orchestrator|report-only|vote|single", "carriers": [".opencode/skills/tdd/SKILL.md:12"], "family_hash": "<computed-live>"}],
  "coupling_notes":     [{"file": ".opencode/skills/adr/SKILL.md", "line": 64, "family": "doc-authoring", "stated_count": 5, "named_siblings": ["prd","tdd","ux-spec","init-specs"]}],
  "rule_presence":      [{"agent": "project-manager", "rules_present": ["R1","R2","R3","R5","R6","R7"], "top_rule_count": 6, "numbering_parse": "numbered|unnumbered-crosstag"}]
}
```

`coupling_notes` (D3 #6), `canonical_blocks.family`/`family_hash` (D4 #2), and `rule_presence.numbering_parse` (senior-engineer exception) are part of the pinned contract. `family_hash` is computed LIVE each run — pinned is the FIELD's presence, NEVER a fixed hash value.

**`[]` vs `null` semantics:** an empty array `[]` means "computed, none found"; `null` means "dimension not computed". On the `d1..d4` dimension-subset arg path, keys for UN-selected dimensions are `null` (not computed this run), distinct from a selected dimension that found nothing (`[]`).

---

## Coherence Report (Phase 2 output, in-context)

Human-readable. Blockers surfaced first. Per finding, output a fenced block with these fields verbatim:

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

A structured block the operator/caller routes to the evolve skills. One bucket per fix-owner so the relevant slice can be pasted into the owning evolve skill. Empty buckets read `None`. Manifest entries may include innovation-mandate and trial-protocol gaps detected during audit — for example, a mandate section absent from a sibling skill, trial protocol steps missing or incomplete (hypothesis / trial / operator approval / measurement / adopt or rollback), a missing operator-approval gate, or vocabulary drift between siblings (e.g., one skill uses different terminology for "model frontier" or "adopt or rollback"). These route under the appropriate fix-owner bucket (evolve-agents or evolve-skills) as Concerns.

```
Remediation Manifest
» evolve-agents   (agent-side drift; run: /evolve-agents [or /evolve-agents <agent>])
  - [D<n>][<severity>] <agents/file.md:line> — <one-line finding> → <suggested correction>
» evolve-skills   (skill-side drift; run: /evolve-skills [or /evolve-skills <skill>])
  - [D<n>][<severity>] <.opencode/skills/.../SKILL.md:line> — <one-line finding> → <suggested correction>
» both            (cross-cutting; canonical side noted; run both, fix canonical side first)
  - [D<n>][<severity>] <agent-side:line> ↔ <skill-side:line> — <finding> — CANONICAL: <side> → <correction>
```

**Routing is advisory only** — the skill does NOT invoke evolve-* itself (per CANONICAL:BANNER). It returns the manifest for caller/orchestrator routing instead of auto-running an evolve cycle, preserving the human-in-the-loop gate the operator trusts.

**Report ↔ Manifest invariant:** every Blocker/Concern in the Coherence Report appears as EXACTLY one manifest line under EXACTLY one fix-owner bucket (`both` counts as one line spanning two sides). Suggestions/Questions/Praise MAY be report-only (not all are actionable as edits).

---

## Self-contained Analysis Instructions

The former external-worker prompt templates are intentionally not retained. Execute the instructions below in the current skill context and return one report. Do not turn them into subagent calls.

### Phase 0: XREF build

Inventory: `{inventory}`.

Build the XREF index over ALL agents (`agents/*.md`) and ALL Opencode skills (`.opencode/skills/*/SKILL.md`) using the detection seeds in the rubric — Review this file's §The Coherence Rubric first — (D1 registry/refs/frontmatter; D2 role_claims; D3 ladders/coupling_notes; D4 canonical_blocks/rule_presence). Compute `family_hash` LIVE per the D4 family rule (key on the opening-prefix string, strip trailing whitespace via `sed 's/[[:space:]]*$//'` before `shasum`). Do NOT judge in Phase 0 — output signals only.

Emit the PINNED XREF schema (Data Models §) as ONE fenced ```json block — every key present, `null`/`[]` for absent, never omit a key.

Rules:
- read-only. Do NOT use edit/write. Do NOT commit.
- No subagents, no `skill(vote)`, no `skill()` routing calls, no worker dispatches.
- Per-file grep — never bulk-cat. Exclude the placeholder token `name`.

### Phase 1: dimension audit passes

For each resolved dimension, substitute `<n>` (the dimension), `{today_date}`, `{verified_goal}`, and `{xref}`.

Audit ONE coherence dimension: D<n>. Confirm every candidate finding against ground truth. To CONFIRM a pinned XREF signal, a ranged `read` of the cited `file:line` suffices (cheaper than a fresh whole-file grep); re-grep only for ABSENCE/coverage checks (a stale name anywhere, a missing carrier) where no line anchor exists. XREF is a signal; a finding built on an unconfirmed signal is reject-class.

Apply the D<n> invariants + detection seeds. HONOR the whitelist of intentional variants — do NOT mis-flag design-qa's "no Question" ladder, the byte-identical HARVEST blocks, the `skill(name)` placeholder, the meta-instruction `skill(verify-ac)` rule-body example in staff-engineer.md, bundled-runtime `verify`, agent-banner semantic parity, the 3 BANNER families (incl. init-specs's shorter body + vote's singleton + leaf trailing clauses), review-and-comment's intentionally non-CANONICAL skill-specific banner, or the one-directional COUPLING bridges (simplify-scout, ux-spec).

Per finding output: `FINDING <n>: <title> / DIMENSION: D<n> / LOCATIONS: <file:line both sides> / SEVERITY: <ladder> / DESCRIPTION: <...> / FIX-OWNER: evolve-agents|evolve-skills|both (CANONICAL: <side>)`. Or `No findings.` Mark the dimension audit completed in `todowrite`.

Rules:
- read-only. No edit/write. No commits.
- No subagents, no `skill(vote)`, no `skill()` routing calls, no worker dispatches.

### Phase 2: reconcile

Substitute `{today_date}`, `{dimension_reports}` (all Phase 1 reports verbatim), and `{xref}`.

Reconcile the dimension reports into a Coherence Report + Remediation Manifest:
1. Merge + de-dupe findings by `(dimension, primary-location)` — keep the most specific, cross-link the rest.
2. Assign each finding a fix-owner (`evolve-agents` / `evolve-skills` / `both` + canonical side: ladders→skill canonical, R-rules→team-lead canonical).
3. Emit the Coherence Report (per-finding format) with Blockers first, AND the Remediation Manifest (3 buckets, empty reads `None`). Enforce the Report↔Manifest 1:1-for-actionable invariant. Annotate any `DEGRADED:` dimension verbatim.

Rules:
- read-only. No edit/write. No commits.
- No subagents, no `skill(vote)`, no `skill()` routing calls, no worker dispatches.

---

## Rules

1. **Report-and-route ONLY.** The skill NEVER `edit`/`write` `agents/*.md` or `.opencode/skills/*/SKILL.md`, and NEVER self-invokes evolve-*. See the No-change Guard.
2. **Analysis is read-only.** Never commit.
3. **Fail loud.** See Failure & Degraded Fallback — never silently drop a dimension.
4. **Return one report.** The final output is the Coherence Report + Remediation Manifest; there is no worker lifecycle to clean up.
