---
name: evolve-coherence
description: >
  Audit coherence between src/user/claude-code/agents/*.md and the skill ecosystem (src/user/claude-code/skills/* + .claude/skills/*)
  across four dimensions, emit a Coherence Report + Remediation Manifest, and ROUTE fixes to
  evolve-agents/evolve-skills. REPORT-AND-ROUTE ONLY: despite the evolve- prefix it NEVER edits
  any agent/skill file and NEVER self-invokes the evolve-* skills.
  Run as a post-edit gate after standalone evolve-agents/evolve-skills edits.
  Trigger: "evolve coherence", "audit coherence", "check agent/skill coherence", "cross-reference audit".
argument-hint: "[dimension(s) d1..d4]"
effort: xhigh
allowed-tools: ["Bash", "Read", "Glob", "Grep", "Monitor", "SendMessage", "TaskCreate", "TaskUpdate", "TaskList", "TaskGet", "Agent", "AskUserQuestion"]
disallowed-tools: ["Edit", "Write"]
---

<!-- CANONICAL:BANNER:BEGIN -->
> **CRITICAL — applies to orchestrator AND every spawned teammate:** (1) Do NOT commit ANY changes (no `git add`, `git commit`, or `git push`) unless EXPLICITLY instructed by the user. (2) Teammates MUST NOT spawn sub-agents, invoke `/vote`, use `Skill()` or `Agent()`, or form/manage a team — delegate to the orchestrator (see `src/user/claude-code/skills/vote/` Delegation Protocol).
<!-- CANONICAL:BANNER:END -->

# Evolve Coherence

You are the **Coherence Audit Orchestrator**. Spawn reviewers as teammates in the session's single implicit team (joined on your first `Agent(name=..., ...)` spawn), build a cross-reference index over all agents + skills, shard a four-dimension coherence audit across parallel reviewers, and emit a **Coherence Report** plus a routable **Remediation Manifest**.

> **REPORT + ROUTE ONLY — read this before anything else.** Unlike its siblings `evolve-agents`/`evolve-skills` (which *apply* edits to definition files), `evolve-coherence` **NEVER edits any agent or skill file** and **NEVER self-invokes `evolve-agents`/`evolve-skills`**. Its only output is a Coherence Report + a Remediation Manifest the **operator** feeds to the evolve-* skills. The `evolve-` prefix names the family it audits, not an edit capability. This is enforced by the No-Edit Guard below.

**evolve-\* location caveat (phantom-path guard).** `evolve-agents`, `evolve-coherence`, `evolve-config`, `evolve-model-distribution`, and `evolve-skills` live EXCLUSIVELY under `.claude/skills/` — they have NO `src/user/claude-code/skills/evolve-*/SKILL.md` counterpart (unlike every other skill in the fleet). Never cite a `src/user/claude-code/skills/evolve-*` path — in a PM tracking issue, a spawn prompt, or any downstream brief — it does not resolve; `src/user/claude-code/skills/` contains only the NON-evolve skills.

<!-- CANONICAL:EVOLUTION-MODEL:BEGIN -->
**Evolutionary model (shared vocabulary — evolve-agents, evolve-skills, evolve-config, evolve-coherence).** One cycle = one **generation**: the current definition file is the **parent genome**, the post-cycle file the **offspring**, the changelog entry the birth record (changelogs are the **phylogenetic record**; History-Compaction ledgering = fossil consolidation). A **trait** is one Content-Gate-passing behavioral unit; an **allele** is an alternative formulation of a trait; the file is the heritable **genome**, the population is the agents/skills under this cycle. **Fitness signals** are the Phase 0 audit measurements (pitfalls re-fires, operator-corrections, `TeammateIdle`/`-r2`/shutdown-rejection stalls, error/abort, model-routing, prior `Trial:`/`Drift:` outcomes). **Natural selection** assigns each evaluated trait a disposition from CITED fitness — AMPLIFY (cited gain → propagate family-wide in Phase 2 = positive selection) or CULL (cited recurring failure → remove = purifying/background selection); unlisted traits default to RETAIN. The **Content Gate is purifying selection** on every introduced allele. **Genetic drift** is bounded, fitness-INDEPENDENT neutral allele-substitution on a no-signal trait (see the drift operator). **Speciation/extinction** (new/retired organism) is a Phase 2 event gated by operator approval + vote, floored by the **biodiversity invariant** (never cull the last carrier of a live niche). Adaptive change and drift alike pass the operator-approval HARD GATE, are measured by the next cycle's Phase 0 audit, and adopt-or-rollback via the Phase 1 self-correct step. **evolve-coherence does not reproduce** — it is the **reproductive-isolation monitor**: it detects cross-organism incompatibility (parity/contract drift) and routes corrective selection to evolve-agents/evolve-skills; it never edits.
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

> **Operator prompts:** All operator-facing questions in Pre-flight MUST use `AskUserQuestion` with pre-generated selectable options (1-4 questions per call; **max 4 options per question regardless of `multiSelect`** — the API rejects >4); max 12-char `header`. If the operator needs to pick more than 4, ask a routing question first ("which category?") then a second narrow question. Free-text is permitted ONLY when the operator must paste material that doesn't fit options AFTER a structured option-led question routes them there.

Before spawning any agents:

1. **Goal alignment (HARD GATE)** — Team mode: adopt the verified goal from the orchestrator prompt; re-verify if your understanding diverges. Standalone: `AskUserQuestion` with options "All 4 dimensions", "Specific dimension(s)" (follow-up multiSelect over D1/D2/D3/D4, max 4), "Address operator-reported drift (free-text follow-up)", "Abort". Capture as `{verified_goal}`. Do not proceed until verified.
2. **Resolve dimensions** — Parse `\$ARGUMENTS` per Argument Handling. Default = all four. Store as `{dimensions}` (an ordered subset of D1–D4). Reject out-of-range tokens and abort.
3. **Inventory agents + skills** — Run `find src/user/claude-code/agents .claude/skills src/user/claude-code/skills -maxdepth 2 \( -path 'src/user/claude-code/agents/*.md' -o -name SKILL.md \) -exec wc -l {} + 2>/dev/null` and `find src/user/claude-code/skills .claude/skills -mindepth 1 -maxdepth 1 -type d 2>/dev/null` (find tolerates an absent root — e.g. a fresh repo with no `src/user/claude-code/skills/` — whereas a zsh `*/SKILL.md` or `src/user/claude-code/skills/*/` glob nomatch-aborts the whole command even with `2>/dev/null`). Capture the file set + counts as `{inventory}` (substituted into the Phase 0 builder prompt). If no agent files OR no skill files are found, inform the operator and abort.
4. **Scope-confirmation gate (HARD GATE)** — The all-targets inventory always exceeds 3. Surface the planned scope via `AskUserQuestion` with options: "Proceed (all <N> files, <dims> dimensions)", "Restrict dimensions (multiSelect D1–D4 follow-up)", "Abort". List the agent + skill counts and the resolved dimensions in the question body so the operator sees est. cycle weight before commit. Team mode: skip — orchestrator already verified scope.

---

## No-Edit Guard (falsifiable)

This skill and every teammate it spawns MUST NOT `Edit` or `Write` any path matching `src/user/claude-code/agents/*.md` or `*/SKILL.md` (the latter covers both `src/user/claude-code/skills/*/SKILL.md` and `.claude/skills/*/SKILL.md`, including `evolve-coherence`'s own). The XREF and Remediation Manifest are **in-context** artifacts (never written to disk, per Data Models §); task bookkeeping uses `TaskCreate`/`TaskUpdate`, not `Write`/`Edit`. A teammate that needs a fix applied emits it into the Remediation Manifest; it does NOT edit. `Edit`/`Write` are removed from `allowed-tools` and listed in `disallowed-tools` (hard-removed from the tool pool between operator messages) — defense-in-depth atop this prose Guard, not a replacement for it.

---

## The Coherence Rubric (FOUR dimensions — invariants + detection)

For each dimension: the **invariants** (checkable assertions) and the **detection method** (concrete grep/parse seeds). Seeds are starting points; reviewers ALWAYS confirm an XREF signal against ground truth before emitting a finding — XREF is signals-to-verify, not facts. To CONFIRM a pinned signal, a ranged `Read` of the XREF's cited `file:line` suffices (cheaper than a fresh whole-file grep); re-grep only for ABSENCE/coverage checks (a stale name appearing anywhere, a missing carrier) where no line anchor exists. As the **reproductive-isolation monitor** (see CANONICAL:EVOLUTION-MODEL), evolve-coherence uses these four dimensions to detect maladaptive divergence that breaks interbreeding — parity/contract drift that would make a shared gene (trait or CANONICAL block) incompatible across the population. Each dimension is a reproductive-isolation check, not a quality-improvement step; corrective selection routes to evolve-agents/evolve-skills via the Remediation Manifest.

### D1 — Skill references & registration integrity

**Invariants.**
1. Every `Skill(<token>)` call in any agent resolves to a real skill directory (in `src/user/claude-code/skills/*` or `.claude/skills/*`) whose `SKILL.md` `name:` equals the dir name. The literal placeholder token `name` (inside R2 rule bodies, e.g. `src/user/claude-code/agents/team-lead.md`) is excluded.
2. Every agent frontmatter `skills:` array entry resolves to a real skill DIRECTORY by the same rule — resolution is by directory existence, NOT frontmatter, because spawned-teammate mode ignores frontmatter `skills:`.
3. Every skill named in a team-lead spawn template / orchestration prose exists and is registered.
4. Deployed-vs-project-local is respected: a skill relied on at deployed (`~/.claude`) runtime must live under `src/user/claude-code/skills/` (only that root is symlinked per `src/user.rs`); a `.claude/skills/`-only skill is project-local. Flag any deployed-runtime reliance on a `.claude/skills/`-only skill.
5. No dead/unregistered refs (a `Skill(x)` or frontmatter entry pointing at a non-existent dir).
6. **Protocol-message emitter/ownership** — for each harness protocol message (`shutdown_request`/`_response`, `plan_approval_request`/`_response`) threaded through the family, verify every cross-ref's EMITTER: only the spawner (team-lead) emits a `_response`; peer/advisor/reviewer roles must "deliver verdict/review to team-lead", never "emit the structured `_response`". Cross-check parallel roles — the coherent ones reveal the outlier. This is a cross-file invariant no single per-agent reviewer can see.

**Detection (seeds).**
- Registry: `for d in src/user/claude-code/skills/*/ .claude/skills/*/; do dir=$(basename "$d"); name=$(awk -F': ' '/^name:/{print $2; exit}' "$d/SKILL.md"); echo "$dir|$name|$d"; done` — flag rows where `dir != name`.
- Refs: `grep -rnoE 'Skill\(([a-z][a-z-]*)' src/user/claude-code/agents/*.md` → strip to token → drop token `name` → resolve against registry.
- Frontmatter: parse each agent's `skills:` YAML list (under `^skills:` to next top-level key) → resolve each.
- Spawn mentions: `grep -noE 'Skill\(([a-z][a-z-]*)' src/user/claude-code/agents/team-lead.md` + prose skill names → resolve.
- Root: registry row's path prefix (`src/user/claude-code/skills/` = deployed; `.claude/skills/` = project-local).

### D2 — Role & format-authority consistency

**Invariants.**
1. Each skill's "driven by @X" / "callable ONLY by @X" / "typically @X" / "format authority" claim names an agent whose stated responsibilities own it: code-review-verdict → `@staff-engineer` (general 6-dim) + `@security-engineer` (security dim) + `@distinguished-engineer` (Medium+ advisor, general 6-dim); tdd/adr → `@staff-engineer` (+ `@security-engineer` for security); verify-ac → `@sdet`; prd → `@project-manager`; ux-spec/design-review/design-qa → `@ux-designer`; simplify-scout → `@senior-engineer` + `@distinguished-engineer` (deep-impl); vote → any agent; init-specs → spawns `@staff-engineer`.
2. No skill claims an agent a **constraint forbids**: a "no code / no source edits" agent (`@staff-engineer`, `@project-manager`, `@ux-designer`) must not drive a code-writing skill; `verify-ac`'s "@sdet reports as comments, never new issues" must agree with `src/user/claude-code/agents/sdet.md` and `src/user/claude-code/agents/project-manager.md` ("ONLY agent creating issues"); `verify-ac` ABORTs for any caller ≠ `@sdet`, so its real invoker must be `@sdet`.
3. A skill's documented invocation shape (`Skill(x, "<scope>")`) matches how the owning agent + team-lead invoke it.
4. **Hard-restriction skills** (those with an ABORT-on-wrong-caller Role Detection — code-review-verdict, verify-ac, design-review, design-qa, simplify-scout) have their restricted-caller set EXACTLY equal to `{agents holding the skill in frontmatter} ∪ {agents with a REAL first-person prose invocation}`. A **real first-person invocation** = the containing agent itself calls the skill as its own action. It EXCLUDES illustrative / meta-instruction / template / example / rule-body tokens (a `Skill(x)` describing how ANOTHER agent invokes, or an authoring example). **Canonical excluded case (verified — NOT a real invocation): the sole `Skill(verify-ac)` token in `src/user/claude-code/agents/staff-engineer.md`** sits inside a rule-body bullet as an example of a skill a TDD prescribes for `@sdet` — staff-engineer lacks verify-ac in frontmatter and verify-ac ABORTs for non-`@sdet`, so adding it would emit a FALSE Blocker. Soft "typically @X" doc skills (adr, prd, tdd, ux-spec) are advisory — plausibility only, not exact restriction.

**Detection (seeds).**
- Claims: `grep -rniE 'driven by|format authority|callable ONLY by|restricted to|typically .@|Role Detection' src/user/claude-code/skills/*/SKILL.md` → parse claimed agent(s) + restriction style.
- For each claimed agent, Read its Responsibilities / "What You Are NOT" and confirm ownership; flag mismatches.
- Contradictions: cross-grep `grep -ni 'never creates issues\|ONLY agent creating' src/user/claude-code/agents/sdet.md src/user/claude-code/agents/project-manager.md` ↔ `grep -ni 'never new issues\|reports as comments' src/user/claude-code/skills/verify-ac/SKILL.md`.
- Restricted-caller set: for each hard-restriction skill, compare its Role-Detection allowed set against the union above. **The prose-invocation classifier MUST distinguish "the containing agent invokes X" (real) from "describes @other / illustrative / template / rule-body example" (excluded)** via surrounding context (enclosing rule-body bullet, "example"/"e.g."/"prescribe" framing, subject = another agent). When in doubt cross-check frontmatter: a token whose containing agent LACKS the skill in frontmatter AND the skill ABORTs for that agent is almost certainly illustrative — do NOT add it.

### D3 — Naming & rename drift

**Invariants.**
1. No stale skill names: `verify` (→ `verify-ac`), `specs` (→ `init-specs`), and `code-review` (→ `code-review-verdict`) must not appear as project-skill refs. **Exception:** the distinct bundled-runtime `verify` and bundled `/code-review` skills are legitimate where referenced as the bundled tool — distinguish "renamed-away project skill" (drift) from "Claude-Code-bundled" (legit) by surrounding context.
2. CLOSED persistent-set names (`advisor`, `security-advisor`, `ux-advisor`) are spelled consistently and treated as closed wherever enumerated (`src/user/claude-code/agents/team-lead.md` Rule 7 is canonical — reference, do not restate).
3. Role-tag prefixes (`[LEAD→]`, `[PM→]`, `[SE→]`, `[STAFF→]`, `[SEC→]`, `[SDET→]`, `[UX→]`, `[DE→]`) are used consistently across agents.
4. Severity ladders are spelled consistently between the skill that DEFINES them and agents that CITE them: staff/UX `Blocker / Concern / Suggestion / Question / Praise` (design-qa intentionally drops Question — preserve, do NOT "fix"); security `Critical / High / Medium / Low / Info`; verify-ac verdict ladder (`PASS/FAIL` + `BLOCK` + LIGHT `APPROVE`). Definition site (code-review-verdict/design-review/verify-ac) is canonical; agent citations must match.
5. Ephemeral name conventions (`impl-{DOCKET-ID}`, `impl-{DOCKET-ID}-fix-{N}`, `reviewer-{N}`, `security-reviewer-2`, `tdd-author`/`-{slug}`/`-fix-{N}`, `planner`, `verifier-criteria`, `verifier-integration`, `design-review-{N}`, `design-qa-{N}`, `coherence-reviewer`, `docs-researcher` (team-lead's retrieval-only ephemeral), `docs-researcher-phase0` (the evolve-* Phase 0 doc-research ephemeral), `historical-auditor`) are spelled consistently between team-lead's spawn templates, the agents' self-descriptions, and the evolve-* templates.
6. **`<!-- COUPLING -->` family-membership notes are self-consistent.** These notes declare which sibling skills must be edited in lockstep, so a stale note silently breaks the contract. Verified families: (a) **doc-authoring family of 5** — adr, prd, tdd, ux-spec each say "update all 5 in lockstep" and name the other four incl. init-specs (init-specs's own note is the reserved-name one, not "all 5"); (b) **report-emission family of 4** — code-review-verdict, verify-ac, design-qa, design-review each say "update all 4 in lockstep" naming the same four; (c) **init-specs↔prd reserved-name lockstep** — both say "update init-specs and prd in lockstep". **Invariant:** for each note, (i) stated member COUNT = actual carrier set size, (ii) each named sibling actually carries a matching note (except documented one-directional bridges), (iii) each member's "When NOT to Use" delegation list agrees with the family roster. **One-directional bridges (whitelisted, NOT drift):** simplify-scout's report-only analog note; ux-spec's bridge into the report-emission family; init-specs (named in the doc-authoring roster but carrying only the reserved-name note, not an "all 5" note — see (a)). `coupling_check.py` whitelists all three.

**Detection (seeds).**
- Stale refs: `grep -rnE 'Skill\((verify|specs|code-review)[,)]|src/user/claude-code/skills/(verify|specs|code-review)/' src/user/claude-code/agents/*.md src/user/claude-code/skills/*/SKILL.md .claude/skills/*/SKILL.md` → classify each `verify`/`code-review` hit bundled-runtime (legit) vs renamed-project-skill (drift) by context.
- CLOSED-set: `grep -rnoE '(advisor|security-advisor|ux-advisor)' src/user/claude-code/agents/*.md` → confirm no near-variants (`sec-advisor`, `ux_advisor`).
- Role tags: `grep -rnoE '\[(LEAD|PM|SE|STAFF|SEC|SDET|UX|DE)→\]' src/user/claude-code/agents/*.md` → compare against the canonical eight.
- Ladders: `grep -niE 'Blocker / Concern|Critical / High' src/user/claude-code/skills/code-review-verdict/SKILL.md src/user/claude-code/skills/design-review/SKILL.md` vs each agent citation; whitelist the design-qa "no Question" variant.
- Ephemeral names: `grep -rnoE '(impl|reviewer|tdd-author|verifier|design-review|design-qa|security-reviewer)-[A-Za-z0-9{}-]+' src/user/claude-code/agents/team-lead.md` ↔ the same tokens in citing agents and evolve-* templates.
- COUPLING: run `python3 src/user/claude-code/scripts/coupling_check.py` from the repo root — it mechanizes legs (i) count=roster-size and (ii) reciprocity: parses each `update all N in lockstep` note, builds family rosters, and reports `[COUNT-MISMATCH]`/`[RECIPROCITY-MISMATCH]`/`[OK]` per note (exit 0 = all consistent, 1 = ≥1 mismatch, 2 = no family-membership notes found), whitelisting one-directional bridges (simplify-scout, ux-spec, init-specs). Leg (iii) — each member's "When NOT to Use" delegation list agrees with the roster — is NLP-judgment OUTSIDE the script's scope; confirm it manually per note. A non-zero exit is a signal-to-verify (Read the flagged note), not an auto-Blocker.

### D4 — Rules & canonical-block parity

**Invariants.**
1. **R-rule applicability matrix** — `src/user/claude-code/skills/team-doctrine/references/runtime-discipline.md` §matrix is source of truth (`src/user/claude-code/agents/team-lead.md` §Runtime Discipline now holds only a LOCAL R1/R3/R4/R6 copy + pointer, NOT the matrix; reference the matrix file, do NOT restate the bodies). Each agent's actual inclusion of R1–R7 matches the matrix (`✓` body / `▾` pointer / `—` omit / `✓*` body+variant). **Anchor the parse on the matrix HEADER ROW, NOT line numbers** (line numbers drift). Column key: tl=team-lead, st=staff, de=distinguished-engineer, se=security, pm=project-manager, ux=ux-designer, sd=sdet, sr=senior. Known shape: R4 omitted for `@project-manager`; R5 present only for the four seats (st/de/se/ux as ✓*), omitted for senior/sdet/pm; team-lead uses ▾ pointer for R2/R5/R7.
2. **CANONICAL:* block byte-parity** — each CANONICAL-tagged block is byte-identical across carriers **within its variant FAMILY** (modulo documented per-file exception). The "one global BANNER" model is FALSE — compare within the correct family. **The family rule keys on the OPENING-PREFIX STRING, never a hardcoded hash literal** (hashes drift the moment a banner is edited; no AC asserts a hash value). BANNER families:
   - **Leaf family** — every SKILL.md whose BANNER body contains the literal `This is a leaf skill` (currently adr, prd, tdd, ux-spec, code-review-verdict, design-review, design-qa, verify-ac, simplify-scout, brief). These differ only in an intentional **trailing clause** — this is mechanized as the `BANNER-LEAF` tag in `src/user/claude-code/scripts/doctrine_check_manifest.tsv`: its strip-transform column (`s/ The calling agent handles peer messaging.*$//`) truncates each carrier's body at the shared boundary before `doctrine_check.sh` hashes it, and the script itself REJECTS (nonzero exit, explicit error) any carrier whose strip transform empties its block — closing the vacuous-empty-match trap a naive line-range delete would fall into. Run `doctrine_check.sh` and read its `BANNER-LEAF` arm rather than hand-hashing; the per-skill tail is whitelisted, not drift.
   - **Orchestrator-prefix family** — opener `> **CRITICAL — applies to orchestrator AND every spawned teammate:**` — evolve-agents + evolve-skills + evolve-config + evolve-model-distribution are byte-identical; **`init-specs` shares the prefix but has a SHORTER divergent body** — treat init-specs's shorter body as a documented intra-family variant (one-shot bootstrap). **`evolve-coherence`'s OWN BANNER MUST match the evolve-agents/evolve-skills body** (this skill spawns a full team that delegates back — NOT the leaf body, NOT init-specs's shorter body, NOT vote's).
   - **`vote` singleton** — opener `> **CRITICAL — applies to coordinator AND every spawned reviewer:**` — a THIRD family of one (adds a team-mode-delegation clause). `vote` is NOT leaf-family (its banner lacks `This is a leaf skill`). Do not group `vote` with leaf or orchestrator.
   - (Agent-side CRITICAL banners are a separate per-role convention NOT wrapped in CANONICAL markers — check agent banners for *semantic* parity of the prohibitions, not byte-identity. `review-and-comment` and `session-metrics` are the two skills intentionally OUTSIDE the CANONICAL:BANNER system: each carries a skill-specific CRITICAL banner (review-and-comment: per-item approval gate + gh-identity check; session-metrics: leaf/no-commit/transcript-only) that fits no family — do NOT flag them as missing banners. `team-doctrine` (non-invocable reference index, `disable-model-invocation: true`) carries no banner by design.)
   - For any `CANONICAL:<TAG>` registered in `src/user/claude-code/scripts/doctrine_check_manifest.tsv` (the carrier registry `doctrine_check.sh` enforces), read the carrier SET from the manifest, NOT a hand-count here — a hardcoded count is the stale-enumeration drift this skill polices (the old inline "7 carriers" for PITFALLS under-counted the manifest set by omitting the team-doctrine reference carrier). The manifest now registers the doc-authoring families (`ARGUMENT_HANDLING`, `COLLISION_DIALOG`, `SAVE_AND_RETURN` across adr/prd/tdd/ux-spec), the evolve-* orchestrator families (`BANNER`, `EVOLUTION-MODEL`, `DISAMBIGUATION-CHARTER`, `GENETIC-DRIFT-OPERATOR`, `OPERATOR-PROMPTS-CONVENTION`, `SECOND-FAILURE-RECOVERY`, `PHASE3-DISAMBIGUATION-BOUNDARY`, `IMPACT-CLASS`, `SCIENTIFIC-TRIAL-PROTOCOL`), and the leaf-family BANNER variant (`BANNER-LEAF`, sharing the same physical in-file `BANNER` marker via the manifest's marker-override column) alongside `PITFALLS`. The sole non-registered family stays inline: `CANONICAL:HARVEST` — single-homed in `src/user/claude-code/skills/team-doctrine/references/evolve-phase0-templates.md` §2 (sole repo-wide carrier, consumed by evolve-agents/evolve-skills/evolve-config via the `{HARVEST_BLOCK}` spawn-time token) — no multi-carrier parity check applies.
3. **Rule-numbering asymmetry** — `src/user/claude-code/agents/team-lead.md` Rule 5 is source of truth (anchor on the Rule-5 prose, not a line number; reference, do not restate). Execution agents `@senior-engineer`/`@sdet` carry rules 1–10; doc/review agents `@staff-engineer` 1–10, `@security-engineer` 1–7, `@ux-designer` 1–8; `@project-manager` 1–6; team-lead 1–10. A doc agent acquiring a claim-first rule, or an execution agent losing it, is drift. **Documented exception: `@senior-engineer` and `@distinguished-engineer` use UNNUMBERED bullets cross-tagged to the sdet scheme** — a naive `grep -E 'R[1-7]'` UNDER-detects; presence of a rule ≠ a numbered line. Treat senior-engineer's and distinguished-engineer's bullet style as satisfying the set by cross-tag, NOT by counting numbered headings; do NOT flag it as "missing rules."
4. **Doubling Rule / panel sizing** — `src/user/claude-code/agents/team-lead.md` Rule 8 is source of truth (reference). Citing skills must not contradict its numbers: `src/user/claude-code/skills/code-review-verdict/SKILL.md` single-default + opt-up-to-doubled language; `src/user/claude-code/skills/vote/SKILL.md` panel-sizing table base 2/2/3/4, doubled 4/4/6/8 capped at 8.

**Detection (seeds).**
- Matrix parity: locate by header row `grep -n '| Rule | tl | st | de | se | pm | ux | sd | sr' src/user/claude-code/skills/team-doctrine/references/runtime-discipline.md` (SUBSTRING match — the live row has a trailing `| Lines |` column); parse the rows below into the expected per-agent map; detect R-rule presence via `grep -nE 'R[1-7]\b' src/user/claude-code/agents/<agent>.md` (the `\b` matches senior-engineer's bulleted `- **R1 ...**`) AND the `see team-lead.md §Runtime Discipline R{N}` pointer phrase; compare to expected (senior-engineer parse handled in the Rule-numbering seed below).
- Block byte-parity: run `doctrine_check.sh` — for each `CANONICAL:<TAG>` (including `BANNER-LEAF`) it extracts the BEGIN/END body per carrier from the manifest, applies that carrier's optional strip-transform column before hashing, REJECTS (nonzero exit) any carrier whose strip transform empties its block, and flags carriers diverging from the tag's reference hash. Read its Arm (c) PASS/FAIL output directly instead of hand-hashing; families with no strip-transform column (orchestrator-prefix, vote singleton) still compare via the same script, unstripped.
- Rule-numbering: extract the highest top-level rule number per agent (`grep -noE '^[0-9]+\.'` in the rules section) vs expected count — **SKIP this numeric parse for `@senior-engineer`** (unnumbered bullets); confirm its 10 rules by cross-tag prose match.
- Doubling/panel: compare `src/user/claude-code/skills/vote/SKILL.md` panel numbers and `src/user/claude-code/skills/code-review-verdict/SKILL.md` single-default/opt-up language against team-lead Rule 8.

> **Intentional variants (do NOT mis-flag)** are enumerated inline per dimension (each carries a `(D<n> #<m>)` carve-out) — this is the single canonical list; the Phase 1 spawn template points here rather than re-listing them, so there is one source and no whitelist drift.

---

## Orchestration Workflow

### Team Setup & Lifecycle

1. Resolve `{today_date}` (run `date +%Y-%m-%d`) for date substitution, then join the session's single implicit team on your first `Agent(name=..., ...)` spawn (Phase 0 below; the runtime ignores `team_name`).
2. `TaskCreate` up-front: "Build XREF" (Phase 0), one "Audit <Dn>" per resolved dimension (Phase 1), and "Reconcile & Report" (Phase 2).

| Phase | Agents | Lifecycle |
|---|---|---|
| 0 | `xref-builder` (senior-engineer, read-only Bash) | Spawn → completes → shut down before Phase 1 |
| 1 | `review-d{n}` per resolved dimension (staff-engineer, read-only) | Spawn ALL in same turn → each delivers its dimension report → shut down (don't wait for siblings) |
| 2 | `reconciler` (staff-engineer, read-only) | Spawn after ALL Phase 1 reports in → emit Report + Manifest → shut down → team cleanup |

**Shutdown protocol** (matches evolve-*): `SendMessage(to="<name>", message={type: "shutdown_request", reason: "<phase> complete"})`. Teammate replies `shutdown_response` **addressed to the orchestrator** (never to a peer). If rejected, read the `reason`, address it, re-request. (Orchestrator-originated shutdown is intentional: evolve orchestrators drive their own team's lifecycle, unlike leaf-review skills where reviewers AWAIT the orchestrator's request per `src/user/claude-code/agents/team-lead.md` Rule 7.)

### Crash, Stall & Degraded Fallback

Detect failure via: (a) TeammateIdle / `Monitor` silence past expected progress; (b) `shutdown_request` no response within one turn; (c) `Agent()` returns an error.

- **Re-spawn ONCE** with suffix `-r2` and a `Resume context:` block (prior partial report, task ID, `{xref}`, target dimension).
- **Degraded single-reviewer fallback** (mirrors `src/user/claude-code/agents/team-lead.md` Rule 8): if a Phase 1 dimension reviewer fails TWICE (probe-once + respawn both abort/empty), record that dimension verbatim as `DEGRADED: single-reviewer (ephemeral failed 2×)` and fold its scan into the reconciler — NEVER silently drop. If ALL four ephemerals are unavailable, fall back to the linear behavior (reconciler scans all four dimensions itself) with the `DEGRADED:` annotation.
- **Compaction recovery**: re-read `{verified_goal}`, `TaskList()`, `{xref}`, and the active phase template before any new `SendMessage`/`Agent` call.

### Phase 0 — Cross-Reference Index Builder (single `senior-engineer`)

Spawn ONE `xref-builder` per the Phase 0 template. Read-only Bash (grep/awk/parse). It builds the XREF the four Phase 1 reviewers consume, so each reviewer does not re-scan all files from scratch, and reports it verbatim to the orchestrator (captured as `{xref}` for Phase 1 substitution). **It does NOT judge** — judgment is Phase 1's job; XREF is signals-to-verify. The XREF schema is PINNED (see Data Models) — the builder emits exactly those keys as one fenced ` ```json ` block, every key present (`null`/`[]` for absent, never omit).

### Phase 1 — Four parallel dimension reviewers (`staff-engineer`)

Spawn one `review-d{n}` per resolved dimension, **all in the same turn** for parallelism. Each is read-only (no edits), receives `{xref}` + the instruction to Read both `src/user/claude-code/agents/*.md` and the skill files **as needed to confirm** any XREF signal against ground truth before emitting a finding. Each emits findings in the per-finding format (see Report Format) scoped to its dimension. Reviewers do NOT peer-message — the orchestrator is the only relay; cross-dimension overlaps reconcile in Phase 2.

### Phase 2 — Reconciler (single `staff-engineer`)

Gate: `TaskList()` shows all Phase 1 dimension tasks `completed` and all Phase 1 reviewers shut down. Then spawn one `reconciler`. Read-only. It:
1. Merges the reviewers' findings, **de-duplicating** by `(dimension, primary-location)` — a single ref can surface under D1 (unresolved) and D3 (rename drift); keep the most specific, cross-link the rest.
2. Assigns each confirmed finding a **fix-owner**: agent-side drift → `evolve-agents`; skill-side drift → `evolve-skills`; cross-cutting (both sides of one ref disagree) → `both`, noting which side is canonical (ladders → the skill is canonical; R-rules → team-lead is canonical).
3. Emits the **Coherence Report** + **Remediation Manifest** into the orchestrator context.

### Wrap-up

1. Shut down the reconciler and clean up the team (the session's single implicit team — no name needed) per lifecycle rules.
2. Surface any Blocker at the top of the report.
3. Report: dimensions audited, Blocker/Concern counts per dimension, the Remediation Manifest, any `DEGRADED:` annotations, and that NO file was modified (the skill is report-and-route only). Mechanize the no-edit attestation: `git status --porcelain` MUST show no modification to any `src/user/claude-code/agents/*.md` or `*/SKILL.md` path — paste that verification, not a narrative claim.

---

## Data Models

No persistent data plane. Two **in-context** artifacts (NOT written to disk — consistent with report-only): the XREF and the Remediation Manifest.

**XREF (Phase 0 → Phase 1 token `{xref}`) — PINNED schema.** The 4 parallel reviewers must parse it identically, so the builder emits EXACTLY these keys/fields as one fenced ` ```json ` block. All fields mandatory; use `null`/`[]` for absent, never omit a key:

```json
{
  "registry":           [{"dir": "code-review-verdict", "name": "code-review-verdict", "root": "src/user/claude-code/skills|.claude/skills", "deployed": true}],
  "skill_refs":         [{"file": "src/user/claude-code/agents/team-lead.md", "line": 251, "token": "code-review-verdict", "kind": "Skill-call|prose"}],
  "frontmatter_skills": [{"agent": "staff-engineer", "skill": "tdd"}],
  "role_claims":        [{"skill": "verify-ac", "file": "src/user/claude-code/skills/verify-ac/SKILL.md", "line": 25, "claimed_agent": "sdet", "restriction": "hard-abort|soft-typically"}],
  "ladders":            [{"name": "staff-severity", "def_site": "src/user/claude-code/skills/code-review-verdict/SKILL.md:350", "citations": ["src/user/claude-code/agents/staff-engineer.md:170"]}],
  "canonical_blocks":   [{"tag": "BANNER", "family": "leaf|orchestrator|vote|single", "carriers": ["src/user/claude-code/skills/tdd/SKILL.md:12"], "family_hash": "<computed-live>"}],
  "coupling_notes":     [{"file": "src/user/claude-code/skills/adr/SKILL.md", "line": 64, "family": "doc-authoring", "stated_count": 5, "named_siblings": ["prd","tdd","ux-spec","init-specs"]}],
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

A structured block the operator feeds to the evolve skills. One bucket per fix-owner so the operator can paste the relevant slice. Empty buckets read `None`. Manifest entries may include innovation-mandate and trial-protocol gaps detected during audit — for example, a mandate section absent from a sibling skill, trial protocol steps missing or incomplete (hypothesis / trial / operator approval / measurement / adopt or rollback), a missing operator-approval gate, or vocabulary drift between siblings (e.g., one skill uses different terminology for "model frontier" or "adopt or rollback"). These route under the appropriate fix-owner bucket (evolve-agents or evolve-skills) as Concerns.

```
Remediation Manifest
» evolve-agents   (agent-side drift; run: /evolve-agents [or /evolve-agents <agent>])
  - [D<n>][<severity>] <src/user/claude-code/agents/file.md:line> — <one-line finding> → <suggested correction>
» evolve-skills   (skill-side drift; run: /evolve-skills [or /evolve-skills <skill>])
  - [D<n>][<severity>] <src/user/claude-code/skills/.../SKILL.md:line> — <one-line finding> → <suggested correction>
» both            (cross-cutting; canonical side noted; run both, fix canonical side first)
  - [D<n>][<severity>] <agent-side:line> ↔ <skill-side:line> — <finding> — CANONICAL: <side> → <correction>
```

**Routing is advisory only** — the skill does NOT invoke evolve-* itself (per CANONICAL:BANNER, and even the orchestrator routes by emitting the manifest, not by auto-running an evolve cycle, to keep the human-in-the-loop gate the operator trusts).

**Report ↔ Manifest invariant:** every Blocker/Concern in the Coherence Report appears as EXACTLY one manifest line under EXACTLY one fix-owner bucket (`both` counts as one line spanning two sides). Suggestions/Questions/Praise MAY be report-only (not all are actionable as edits).

---

## Spawning Templates

### Phase 0: @senior-engineer (XREF builder)

```
Agent(name="xref-builder", subagent_type="senior-engineer", model="sonnet", prompt="...")

You are the cross-reference index builder. Read-only Bash (grep/awk/parse). No file edits. No commits. No sub-agents.
Inventory: {inventory}

## Task
Build the XREF index over ALL agents (src/user/claude-code/agents/*.md) and ALL skills (src/user/claude-code/skills/*/SKILL.md, .claude/skills/*/SKILL.md) using the detection seeds in the rubric — Read `.claude/skills/evolve-coherence/SKILL.md` §The Coherence Rubric first; it is NOT in this prompt — (D1 registry/refs/frontmatter; D2 role_claims; D3 ladders/coupling_notes; D4 canonical_blocks/rule_presence). Compute family_hash LIVE per the D4 family rule (key on the opening-prefix string, strip trailing whitespace via `sed 's/[[:space:]]*$//'` before `shasum`). You do NOT judge — emit signals only.

## Output
Emit the PINNED XREF schema (Data Models §) as ONE fenced ```json block — every key present, `null`/`[]` for absent, never omit a key. SendMessage the orchestrator the json block verbatim.

## Rules
- Read-only. Do NOT use Edit/Write. Do NOT commit.
- No sub-agents: no /vote, Skill(), Agent(); do not form/manage a team. SendMessage the orchestrator for delegation.
- No peer-to-peer SendMessage — orchestrator is the only relay.
- Per-file grep — never bulk-cat. Exclude the placeholder token `name`.
```

### Phase 1: @staff-engineer (dimension reviewer — one per resolved dimension)

Substitute `<n>` (the dimension), `{today_date}`, `{verified_goal}`, `{xref}`.

```
Agent(name="review-d<n>", subagent_type="staff-engineer", model="opus", prompt="...")

You audit ONE coherence dimension: D<n>. Read-only — NO file edits, no commits, no sub-agents.
Verified goal: {verified_goal} (pre-verified — re-verify if your understanding diverges)

## XREF (signals-to-verify, NOT facts)
{xref}
> Before emitting ANY finding, confirm it against ground truth. To CONFIRM a pinned XREF signal, a ranged `Read` of the cited `file:line` suffices (cheaper than a fresh whole-file grep); re-grep only for ABSENCE/coverage checks (a stale name anywhere, a missing carrier) where no line anchor exists. XREF is a signal; a finding built on an unconfirmed signal is reject-class.

## Task
Read `.claude/skills/evolve-coherence/SKILL.md` §The Coherence Rubric (it is NOT in this prompt), then apply the D<n> invariants + detection seeds. HONOR every intentional-variant carve-out — each inline `(D<n> #<m>)` carve-out in the rubric plus the "Intentional variants (do NOT mis-flag)" note — do NOT flag any whitelisted variant as drift.

## Output (per finding)
FINDING <n>: <title> / DIMENSION: D<n> / LOCATIONS: <file:line both sides> / SEVERITY: <ladder> / DESCRIPTION: <...> / FIX-OWNER: evolve-agents|evolve-skills|both (CANONICAL: <side>). Or "No findings." SendMessage the orchestrator verbatim, then mark your task completed.

## Rules
- Read-only. No Edit/Write. No commits. No /vote, Skill(), Agent(); do not form/manage a team.
- No peer-to-peer SendMessage — orchestrator is the only relay.
```

### Phase 2: @staff-engineer (reconciler)

Substitute `{today_date}`, `{dimension_reports}` (all Phase 1 reports verbatim), `{xref}`.

```
Agent(name="reconciler", subagent_type="staff-engineer", model="opus", prompt="...")

Reconcile the four dimension reports into a Coherence Report + Remediation Manifest. Read-only — NO edits, no commits, no sub-agents.

## Dimension reports
{dimension_reports}
## XREF
{xref}

## Task
1. Merge + de-dupe findings by (dimension, primary-location) — keep the most specific, cross-link the rest.
2. Assign each finding a fix-owner (evolve-agents / evolve-skills / both + canonical side: ladders→skill canonical, R-rules→team-lead canonical).
3. Emit the Coherence Report (per-finding format) with Blockers first, AND the Remediation Manifest (3 buckets, empty reads `None`). Enforce the Report↔Manifest 1:1-for-actionable invariant. Annotate any DEGRADED dimension verbatim.

## Rules
- Read-only. No Edit/Write. No commits. No /vote, Skill(), Agent(); do not form/manage a team.
- No peer-to-peer SendMessage — orchestrator is the only relay.
```

---

## Rules

1. **Report-and-route ONLY.** The skill and every teammate NEVER `Edit`/`Write` `src/user/claude-code/agents/*.md` or `*/SKILL.md`, and NEVER self-invoke evolve-*. See the No-Edit Guard.
2. **Teammates are read-only.** Never commit.
3. **Fail loud.** See Crash, Stall & Degraded Fallback — never silently drop a dimension.
4. **Clean up.** Shut down all teammates and clean up the team after wrap-up.

