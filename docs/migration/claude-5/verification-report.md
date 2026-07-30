# Claude 5 Migration — Verification Report (2026-07-29)

Post-migration verification of the rewritten definitions under
`src/user/claude-code/` (8 agents, 17 skills) as a **system**, against the
charter at `src/user/claude-code/docs/context-engineering-claude-5.md` and the
baseline in `baseline-metrics.md` (same directory).

**Verdict: references PASS, consistency and size FAIL.**

What held: every cross-reference in the tree resolves — including all 61
cross-file `Rule N` citations, the hazard the audit ranked first. Zero
reasoning-echo instructions and zero self-verification scaffolding survive
anywhere in the fleet (mechanical scan and five independent LLM graders agree).
The review-recall counter-current protections all held, and two pre-migration
recall defects were fixed. Every mechanical check is green: 4 doctrine arms, 4
sibling checks, 403/403 script tests.

What did not: **five cross-file contradictions were found**, two of them inside
a single agent file each — `TeammateIdle` meant "a rule failed" in one paragraph
and "is normal" in another, in both `staff-engineer.md` and `sdet.md`, with both
files contradicting the team-lead master. One instruction was unsatisfiable as
written in two agents. Four of eight agent frontmatter descriptions overclaim or
omit a real capability. All three byte-reduction floors miss by roughly 2×, and
the agent-frontmatter re-derivation (remediation item #14) was applied to skills
but never to agents — those `effort` pins are byte-identical to the baseline.

**Six fixes applied** (§7): two broken references, both `TeammateIdle`
contradictions, the unsatisfiable instruction, and the headless-mode contract
(R15 — applied after Part B; its first design was falsified by live testing and replaced). **Three contradictions
remain routed** because each needs a content decision, not an edit:
the banned-confidence-phrase list, the doc-family 5-way COUPLING claim, and
`evolve-orchestration-core.md`'s Consumers line. Twelve items total are routed,
one of which (`verify-ac`'s `uncommitted` scope missing untracked files) is a
real behavioral defect that predates the migration.

**Part B ran.** Three live `claude -p --agent team-lead` cycles against the
installed definitions (§6). Routing, tier assignment, panel composition, the
commit gate, Rule 10's design lock, and the security-off-Fable pin all held
under real spawns. Five behavioral defects surfaced that no amount of reading
would have found — chief among them that the definitions had **no unattended-run
safety**: cycle 2 burned $33.97 and 97.7 minutes and shipped no code, because
`team-lead.md:260` told the orchestrator it could end its turn awaiting a
teammate, which under `claude -p` ends the run. That one is now fixed and
confirmed on a live cycle (R15, §7) — including a first attempt whose design
live testing falsified, which is itself the argument for running Part B at all.

---

## 1. Method

Read-only audit of the tree as text, plus execution of the repo's own
verification scripts. No definition was loaded as an active agent or skill
(this session ran plain: no project skills, no custom agents).

Every finding below is grounded in a mechanical instrument or a direct file
read with a line number. Charter §4's LLM-graded style pass ran as five fresh
vanilla subagents briefed with the charter, covering all 8 agents and all 17
skills. **Every grader finding reported in §3.8 was independently re-verified
against the files before being accepted**; two were rejected on that check and
are recorded with the reason.

Evidence classes:

| Class | Instrument |
|---|---|
| Mechanical doctrine parity | `doctrine_check.sh` (4 arms), `coupling_check.py`, `symmetry_check.py`, `drift_guard_check.py`, `tier_map.sh` |
| Cross-reference resolution | purpose-built checker over all 58 md files (paths, `Skill()` names, `@role` names, `SP-n`/`TFD-n`/`R-n` tokens, team-lead Rule citations) + `check_citations.py` |
| Duplication metric | purpose-built maximal-shared-block scan across the 8 agent files |
| Marker census | `grep -o` for `MUST`/`NEVER`/`ALWAYS`/`CRITICAL`, same commands as the baseline |
| Script layer | `pytest src/user/claude-code/scripts/test/` — **403 passed** |
| Harness health | `claude doctor` |

---

## 2. Pass/fail per check

| # | Check | Result | Detail |
|---|---|---|---|
| A1 | Every file-path reference resolves | **PASS** | §3.1 |
| A2 | Every skill name resolves | **PASS** | §3.1 |
| A3 | Every `@role` reference resolves | **PASS** | §3.1 |
| A4 | Every section anchor / numbered citation resolves | **PASS** | §3.2 — the migration's #1 sequencing hazard did **not** materialize |
| A5 | Every canonical-master pointer resolves | **PASS** | 74 `Master:` pointers, `doctrine_check.sh` arm (b) |
| A6 | Every cited script exists | **PASS** | 51/51 |
| A7 | No orphaned doctrine references | **PASS** | `doctrine_check.sh` arm (d): 17/17 rows' `Cited by` sets match live grep |
| A8 | No contradictory rules across files | **FAIL → 3 remain** | §3.3 + §3.7 — 5 confirmed; the two `TeammateIdle` contradictions **fixed** (§7). Remaining: banned-phrase drift, doc-family 5-way COUPLING, evolve-core Consumers line |
| A9 | No charter violation class reintroduced | **PASS** | §3.4 — 1.1 and 1.4 scan clean (0 hits); 1.2's single hit is the §3.3 list, counted once |
| A9b | Charter-named class-1.2 files retired | **PARTIAL** | §3.4 — 3 DELETE-WHOLE-FILE verdicts resolved as shrink-not-delete, documented |
| A10 | Skill frontmatter matches content | **PASS w/ 1 exception** | §3.5 — `brief` cites a retired label; 16/17 clean |
| A10b | Agent frontmatter description matches content | **FAIL (4 of 8)** | §3.7 G6–G8 — team-lead, staff-engineer, project-manager, senior-engineer |
| A10c | No unsatisfiable instruction | **FIXED** | §3.7 G3 — tool-envelope fallback in 2 agents, corrected in §7 |
| A11 | Byte reduction — agents ≤170KB | **FAIL** | 362,822B = 2.13× target |
| A12 | Byte reduction — `team-lead.md` ≤30KB | **FAIL** | 76,878B = 2.56× target |
| A13 | Byte reduction — skills ≥50% prose cut | **FAIL** | −30.3% achieved |
| A14 | Marker count — no file above 10 | **FAIL (1 file)** | team-lead 15; all 15 map to keep-list categories |
| A15 | Marker mapping — every marker maps to a keep-list category | **PASS** | §4.2 |
| A16 | Zero verbatim multi-line blocks shared between agent files | **FAIL (by design)** | 12 blocks / 26,201B — pointer stubs, §4.3 |
| A17 | Progressive disclosure — no SKILL.md >10KB without justification | **PASS** | 13 over, all justified in `baseline-metrics.md` |
| A18 | Agent frontmatter re-derived per charter §3 | **FAIL** | §4.4 — 6 of 8 still pin `effort: xhigh`, unchanged from baseline |
| A19 | Skill frontmatter re-derived per charter §3 | **PASS** | all 5 `effort: xhigh` pins removed |
| A19b | Charter counter-current — review recall preserved | **PASS** | §3.6 — 8 protections intact, 2 pre-migration recall defects fixed |
| A20 | Mechanical doctrine parity (4 arms + 4 sibling checks) | **PASS** | §3.9 |
| A21 | Script layer green | **PASS** | 403/403 |
| A22 | `/doctor` | **PASS (2 unrelated warnings)** | §5 |
| **B1** | Routing — pattern matches task size, no inflation | **PASS** | §6.1 — Direct drew 1 bronze spawn; Medium drew gold author + correct 3-seat panel |
| **B2** | Tier assignment matches the dispatch table | **PASS** | §6.1 — `sonnet`/`fable`/`opus` all as specified |
| **B3** | Security routed off the gold/Fable tier | **PASS** | §6.1 — cycle 3 pinned `opus`; the charter §3 constraint held live |
| **B4** | Commit gate holds without operator instruction | **PASS (3/3)** | §6 — nothing committed in any cycle, `permission_denials` empty each time |
| **B5** | Rule 10 design lock holds | **PASS** | §6.1 — cycle 2 ran 97 min with zero code and zero issues, design unaccepted |
| **B6** | Review recall holds live (no self-filtering) | **PASS** | §6.1 — cycle 3 reported a pre-existing Critical unasked; cycle 2 rejected on evidence |
| **B7** | Authority gate — no override-on-merits | **PASS** | §6.1 — cycle 3 escalated a Block rather than dispositioning it |
| **B8** | Cycles complete unattended | **FAIL → FIXED, verified** | §6.2 B1 — cycle 2 died mid-round-3. R15 (§7) ships unconditional wait-arming; confirmed live |
| **B9** | Security panel provisioned as specified | **FAIL → FIXED** | §6.2 B2 — the 3-seat roster was unbuildable on Direct/Small; R16 (§7) sets a 2-seat floor there |
| **B10** | Scratch files stay out of the working tree | **FAIL → rule gap fixed** | §6.2 B3 — 9 `.sdet_*` files left in the repo root; the rule never prohibited that destination. R17 (§7) closes it |
| **B11** | Spawn names match the dispatch table | **FAIL (1 of 3)** | §6.2 B4 — three forms across four runs: `impl-DKT-1`, bare `senior-engineer`, `impl-cart-linecount` |
| **B12** | Acceptance vote converges | **FAIL** | §6.2 B5 — 2 rounds rejected on unverified claims, into round 3 of 3 |

---

## 3. Coherence findings

### 3.1 Cross-reference resolution

All path, skill-name, and role-name references resolve. The checker's raw
output flags 19 paths, all of which are **target-project output paths** the
agents write into whatever repo they are working in (`docs/spec/`, `docs/tdd/`,
`docs/adr/`, `docs/ux/`) or runtime artifacts (`.git/index.lock`,
`~/.claude/agent-memory/…`). This repo has no `docs/spec/` etc., so
non-resolution here is correct, not a defect. `check_citations.py` over all 8
agent files reproduces the same set and nothing else.

Two genuine breakages were found and **fixed** (§7):

- `agents/team-lead.md:263` cited the monitor-orchestration master as the bare
  relative `references/monitor-orchestration.md`, which resolves to nothing
  from `agents/`. Line 258 of the same file already used the correct full
  deployed-path form.
- `skills/team-doctrine/references/retention-compaction.md:4` referred to its
  own sibling as `references/pitfalls.md` from inside `references/`.

### 3.2 Numbered anchors — the migration's top sequencing hazard held

Audit manifest §1d.1 warned that doctrine is addressed by ≥7 numbering schemes
and that "the marker-reduction pass renumbers or deletes most of them — convert
numeric citations to named anchors **before** content edits, or every
cross-file pointer breaks at once."

Verified: **it held.** `team-lead.md` still defines Rules 1–11 as an ordered
list under `## Rules`, and all 61 cross-file `Rule N` citations across agents,
skills, and the out-of-tree `.claude/skills/evolve-*` consumers resolve to a
rule whose subject matches the citing context. `SP-n`, `TFD-n`, and `R-n`
tokens likewise resolve to their masters (0 unresolved).

Two relocations are handled correctly rather than deleted: Rule 5
(rule-numbering convention) and Rule 9 (code comments) are now pointer stubs
naming their new homes, so citations of those numbers still land.

The 12 code-philosophy principles — `simplify-scout`'s validator-enforced
`1–12` citation contract, flagged as sequencing hazard §1d.2 — are intact:
`senior-engineer.md:178–200` defines all 12, numbered 1–12 in order, and
`simplify-scout/references/principles-lens.md` maps the same 12 in the same
order to the same meanings.

### 3.3 One surviving cross-file contradiction — banned-confidence-phrase list

The audit manifest (§1b) named this as "**realized drift under a shared
linter**; the executable copy is the only one that enforces anything —
single-home in the linter." **The drift survived the migration**, in a
different shape:

| Home | Phrases | Count | Agrees with linter? |
|---|---|---|---|
| `scripts/report_lint.py:63` (executable authority) | clearly, obviously, should work, definitely, 100%, guaranteed | 6 | — |
| `skills/code-review-verdict/SKILL.md:110` | same 6 | 6 | yes |
| `skills/verify-ac/SKILL.md:123` | same 6 | 6 | yes |
| `skills/design-review/SKILL.md:123` | clearly, obviously, should work, definitely | **4** | **no** — omits `100%`, `guaranteed` |
| `agents/sdet.md:48` | the 6 + `I'm sure`, `trust me` | **8** | **no** — 2 phrases nothing enforces |
| `skills/design-qa/SKILL.md` | *(no restatement — defers to the scan)* | 0 | yes |

`design-qa` dropping its copy is the correct move and the pattern the other
three should follow. `sdet.md:48` additionally calls the phrases
"sign-off-disqualifying" — an enforcement claim that is true for 6 of the 8 and
false for the 2 the linter never sees.

Routed, not patched: which list is right is a content decision (the linter is
the enforcement authority, but "I'm sure"/"trust me" may be wanted *in* it),
and it touches a declared coupled family.

### 3.4 No charter violation class reintroduced

Pattern scans across all agent and skill files:

- **1.1 reasoning-echo** — 0 hits (`explain your reasoning`, `show your
  thinking`, `state your rationale`, `restate in your own words`, `mentally
  trace`, `narrate your reasoning`, …). The pre-migration tree carried several;
  all are gone.
- **1.2 4.x workarounds** — 1 hit, `sdet.md:48` (the banned-phrase list of
  §3.3). Forced-cadence progress rules, anti-laziness pressure, iteration caps,
  and context-budget choreography are absent.
- **1.4 self-verification scaffolding** — 0 hits (`double-check`, `self-check`,
  `verify your own`, `before responding verify`, `use a subagent to verify`,
  `final verification step`). External gates (validator scripts, human
  approval, reviewer roles, parsers) remain, which the charter keeps.
- **Dead mechanisms** — no `prefill` or `budget_tokens` anywhere, consistent
  with the audit's sweep.

**Partial:** the charter names
`team-doctrine/references/laziness-discipline.md` and
`fable-completeness-heuristics.md` as existing *entirely* for class 1.2, and
the audit manifest's verdict on both (plus `team-conventions.md`) was
DELETE-WHOLE-FILE. All three survive, shrunk:

| File | Baseline | Now | Verdict |
|---|---:|---:|---|
| `laziness-discipline.md` | 4,896B | 1,948B | −60%; the retained "When NOT to be lazy" paragraph is keep-list cat 2 (never simplify away trust-boundary validation, error handling that prevents data loss, security measures) |
| `fable-completeness-heuristics.md` | 3,227B | 1,972B | −39%; reframed from reasoning-echo to *form checks on returned artifacts* ("team-lead audits **that** search evidence is cited, never whether the search was adequate") — charter §1.1 explicitly permits requiring evidence |
| `team-conventions.md` | 3,992B | 1,777B | −55% |

Phase 3's own note records the rationale: every one of the 17 reference files
is cited by a Phase 2 agent or an out-of-scope `evolve-*` skill, so the three
DELETE verdicts (which predated the citation map) were resolved as
shrink-not-delete. That is defensible and documented — but the charter's text
still says these files should not exist, so this is recorded as a **partial
pass**, not a clean one.

### 3.5 Skill frontmatter vs content

16 of 17 descriptions accurately describe their body. One mismatch:

`skills/brief/SKILL.md` describes its output as the artifact "team-lead's
**Pre-flight HARD GATE** consumes" (frontmatter description line 5, plus body
lines 19 and 66). `team-lead.md` has **no** "HARD GATE" — the label was
deliberately dropped per audit §3.1 ("keep the goal gate as an external human
gate; drop the HARD GATE label"). The *anchor* still resolves (`## Pre-flight`
step 1, "Verify the goal", exists at `team-lead.md:54–56`); only the label is
stale. Because the frontmatter description loads on every skill listing, this
also re-exposes a charter §1.4 label the migration retired everywhere else.

### 3.6 Charter counter-current — recall protections all intact

Charter §1.3 warns that restrictive review filters are now followed *literally*
and reduce recall on Opus 5 and Sonnet 5 — review prompts must ask for full
coverage and filter downstream. This is the one place where a naive "trim the
enumerated list" pass would have caused a real behavioral regression. The audit
named seven lines to protect and four soft recall-reducers to fix. **All
eleven verified:**

| Protection | Where | State |
|---|---|---|
| No-self-filter (general review) | `code-review-verdict/SKILL.md:106` | intact — "Report every finding — do NOT self-filter … including low-severity and uncertain ones" |
| No-self-filter (design QA) | `design-qa/SKILL.md:110` | intact |
| No-self-filter (design review) | `design-review/SKILL.md:122` | intact |
| No-self-filter (vote panel) | `vote/references/reviewer-template.md:31` | intact |
| Linter-catchable findings still reported | `staff-engineer.md:170` | intact — "still reported — at `Suggestion` severity, not [omitted]" |
| `cargo audit` findings still reported | `security-engineer.md:137` | intact — "still reported — at `Info` severity, not omitted; filtering and ranking happen downstream" |
| Unsolved Blocker must stay emittable | `design-review/SKILL.md:124` | **fixed** — validator now accepts `— alternative: none identified — needs design exploration` |
| Un-taxonomized finding must not be discarded | `simplify-scout/SKILL.md:65` | **fixed** — "cite the closest governing principle and say so … never drop a real finding for taxonomy reasons" |

A fleet-wide scan for the harmful shape (`only report high-severity`, `drop
it`, `do not report`, `omit the finding`) returns zero hits in any review path.
The pre-migration `simplify-scout` "drop it" defect — an explicit recall filter
discarding exactly the junior-tells the skill exists to find — is gone.

### 3.7 LLM-graded pass — findings (all independently re-verified)

Five vanilla graders covered the fleet. Their class-1.1 and class-1.4 verdicts
agree with the mechanical scans: **zero reasoning-echo instances anywhere**, and
no self-verification scaffolding that isn't a sanctioned external gate. They
confirmed the two special-check fixes independently — `commit`'s
`(claude-code)` scope three-way conflict is resolved to a single statement that
matches what `commit_msg_check.sh:57` actually enforces, and `session-metrics`'
prose now matches the renderer's literal `n/a (unpriced model)` at
`session_metrics.py:363,370`.

**Confirmed new findings** (each re-checked against the file by me):

| # | Finding | Evidence | Severity |
|---|---|---|---|
| G1 | **`staff-engineer.md` self-contradicts on `TeammateIdle`** | L77 "`TeammateIdle` means rule 1, 2, or 4 failed" (unconditional) vs L241 "Persistent `advisor` idles between phases … `TeammateIdle` is normal" | **FIXED (§7)** — class 1.6 — real |
| G2 | **`sdet.md` self-contradicts on `TeammateIdle`** | L31 "(idle-after-verdict is normal; working past verdict emission is the stall pattern)" vs L54 "`TeammateIdle` is the canonical stall signal — it means rule 1, 2, or 7 has failed" | **FIXED (§7)** — class 1.6 — real |
| G3 | **Incoherent tool-envelope fallback**, identical in 2 agents | `security-engineer.md:55` and `ux-designer.md:69`: "If Edit/Write are absent, **Write** the edit script to `$TMPDIR` and run it via Bash (not inline `python3 -c`/heredoc…)" — the remedy for lacking Write is to Write, and the one shell alternative is banned in the same sentence | **FIXED (§7)** — logic defect — unsatisfiable as written |
| G4 | **Doc-family COUPLING asserts a 5-way sync against a section that doesn't exist** | `tdd/SKILL.md:55` (and prd/adr/ux-spec): "the 'When NOT to Use' delegation routes … MUST stay in sync with … init-specs — update all 5 in lockstep". `init-specs/SKILL.md` has no "When NOT to Use" section and no equivalent (headings verified) | class 1.6 — real; **`coupling_check.py` blind spot**: it verifies roster membership and reciprocity, not that each member carries the coupled section |
| G5 | **`verify-ac`'s `uncommitted` scope misses untracked files** | `code-review-verdict/SKILL.md:56` resolves `uncommitted` with `git status --short` (surfaces untracked `??`) + 3 git commands; `verify-ac/SKILL.md:49` omits `git status --short`. A newly added file can therefore go unverified, or fail an AC it satisfies | real behavioral defect — **pre-existing, not a migration regression** (verified: both rows identical to their pre-rewrite forms at `bb89bea~1` / `38542ea~1`). The COUPLING comment pins only the Branch/`staged`/File-paths rows, so this is outside its declared scope |
| G6 | **`team-lead` description overstates read-only** | frontmatter L10 "read-only on the working tree" vs body L32 "read-only on the working tree, **with two sanctioned write paths**: Edit/Write scoped to `.claude/agent-memory/team-lead/**`" — which is inside the working tree | description accuracy |
| G7 | **`staff-engineer` description overstates its review seat** | description "Reviews **all** @senior-engineer changes" vs body L150 "designated general reviewer … on **sub-Medium cycles** … on Medium+ the verdict seat is @distinguished-engineer". Same for TDD authorship: body L126 scopes it to "the gold-unavailable fallback" | description accuracy — can mis-route dispatch |
| G8 | **`project-manager` description omits its write path**; **`senior-engineer` description omits `docs-author`** | pm description says it "uses Read, Grep, and Glob to explore" and never writes, but the body grants Edit/Write against `docs/spec/*` for PRD authoring; senior-engineer's body L88 hosts `docs-author` (README/API docs), unmentioned in the description | description accuracy |
| G9 | **`evolve-orchestration-core.md`'s own Consumers line is stale** | L3/L32 "Consumers: evolve-agents, evolve-config, evolve-skills" (3) vs `team-doctrine/SKILL.md:56` listing 5; grep confirms all 5 reference it | class 1.6 — real |

**Rejected on re-verification** (recorded so they aren't re-raised):

- *"`team-doctrine/SKILL.md:46` undercounts `retention-compaction.md`'s citers — `evolve-skills` cites it too."* **Rejected.** The `Cited by` column tracks files that cite the reference's **path**; `grep -c "references/retention-compaction.md"` in `evolve-skills/SKILL.md` returns **0**. It mentions "the retention-compaction master" by name at L206 without a path. `doctrine_check.sh` arm (d) is correct and the cell is accurate. *(The underlying observation is still worth one line: `evolve-skills:206` imposes a requirement sourced from that master with no dereferenceable pointer — a soft gap, not a table defect.)*
- *"`verify-ac` lacks the no-self-filter sentence its three siblings carry."* **Not a recall defect.** Coverage is enforced structurally instead — a mandatory PASS/FAIL/OUT-OF-SCOPE bullet per AC (L143) and all four severity buckets explicit with "or None" (L156–167). Worth harmonizing for family consistency, but it does not filter.

**Unconfirmed external references** (flagged, not counted as breakage): `verify-ac`
cites "the bundled runtime `verify` skill" (frontmatter L9, body L102) — no such
skill is visible in this harness build; and both scope-table COUPLING comments
cite `DKT-250`, which returns `NOT_FOUND` against the local Docket DB (max ID
DKT-191). Either may be a forward reference.

### 3.8 Out of scope but worth recording — the unmigrated `opencode` fleet

`src/user/opencode/agents/` holds a **parallel copy of the same 8 agents,
398,405B, untouched by this migration** (`team-lead.md` there is 86,569B vs
76,878B in `claude-code/`). The charter scopes the migration to
`src/user/claude-code/`, so this is correctly out of scope — but the repo now
carries two divergent generations of one fleet, and `src/user.rs:481` inlines
agent descriptions for the opencode variant as Rust string literals, a third
place descriptions can drift from the definitions they describe. Worth an
explicit decision: migrate, regenerate from the claude-code sources, or retire.

### 3.9 Mechanical doctrine parity — all green

```
doctrine_check.sh          all 4 arms PASS
  (a) index parity          17 reference files == 17 table rows
  (b) Master: pointers      74 resolved
  (c) CANONICAL byte-parity 16 tags across 2–10 carriers each
  (d) Cited-by parity       17 rows match live grep
coupling_check.py          8/8 family-membership notes consistent
symmetry_check.py          impact-class, trial-protocol, operator-prompts, mimir-note OK
drift_guard_check.py       3 inlined blocks in sync with their scripts' Usage lines
tier_map.sh                Tiers block + Per-Role Dispatch Table parse clean
```

Re-run green after the §7 fixes.

---

## 4. Metrics — before / after / target

### 4.1 Bytes

| Scope | Baseline | Now | Δ | Charter target | Result |
|---|---:|---:|---:|---|---|
| Agents (8 files) | 553,725 | 362,822 | −34.5% | ≤170,000 (≥70% cut) | **FAIL** — 2.13× |
| `team-lead.md` | 137,218 | 76,878 | −44.0% | ≤30,000 | **FAIL** — 2.56× |
| Skills (all .md) | 536,134 | 373,651 | −30.3% | ≥50% cut | **FAIL** |
| Skills — loaded context (Σ SKILL.md) | 359,713 | 217,025 | −39.7% | — | (the operative number) |

The loaded-context figure is the honest one for per-invocation cost, and −39.7%
is real. But no reading of the charter's §4 floors makes them met. Phases 2 and
3 each recorded a shortfall note attributing the residue to parity-locked
CANONICAL blocks, machine-parsed anchors, and skill-cited anchors — those are
genuine constraints, and charter §4's own caveat ("reduction is a consequence
of applying §1, never a goal pursued by deleting context the model cannot
reconstruct") governs the stop point. The gap is nonetheless ~2× on two of
three floors, which is a scope question for the migration owner, not something
a verification pass can close.

### 4.2 Markers

| File | Baseline M/N/A | Now | CRITICAL (was) |
|---|---:|---:|---:|
| team-lead.md | 42 | **15** | 0 (0) |
| project-manager.md | 11 | 8 | 1 (2) |
| security-engineer.md | 12 | 7 | 1 (1) |
| staff-engineer.md | 16 | 7 | 1 (1) |
| ux-designer.md | 7 | 5 | 1 (1) |
| sdet.md | 10 | 4 | 1 (3) |
| senior-engineer.md | 6 | 3 | 1 (3) |
| distinguished-engineer.md | 4 | 3 | 1 (1) |
| **Agents total** | **108** | **52** (−52%) | 7 (12) |
| **Skills total** | **100** | **41** (−59%) | 19 (19) |

Charter target is "typical file ≤5, no file above 10, every surviving marker
maps to a named keep-list category."

- **Mapping: PASS.** Spot-verified team-lead's 15 — commit + no-spawn gate
  (cat 1+3), alignment-never-judges-merits (cat 3), `name=`/`run_in_background`
  exclusivity (cat 4, SP-2), explicit `model=` requirement (cat 4), tier escape
  hatch upgrades-only (cat 3), `.env` phantom-delete masking (cat 2),
  no-override-on-merits and no-self-arbitration (cat 3), SP-1b/SP-2/SP-3
  protocol literals (cat 4). All point to a real boundary.
- **Count: 7 of 8 agents pass; team-lead at 15 exceeds the ≤10 ceiling.** The
  audit manifest (§6.7) pre-authorized recorded exceptions for
  senior-engineer (~20–25), distinguished-engineer (~20–25), and
  security-engineer (~12–14) — all three came in far *under* their allowances
  (3, 3, 7). team-lead got no such allowance and needs one recorded, since its
  markers are the densest concentration of cat-3/cat-4 boundaries in the fleet.

### 4.3 Deduplication

Charter target: **zero** multi-line blocks shared verbatim between two or more
agent files (baseline: 7 such blocks, ~61,159 redundant bytes).

Measured now: **12 shared blocks, 26,201 redundant bytes** (−57% in redundant
bytes; count up from 7).

This is a **deliberate architecture choice, not a regression**. The blocks are
no longer inlined doctrine bodies — they are 2–4 line *pointer stubs* (fence +
`Master: <path>` + at most one locally-load-bearing fact), which is exactly
what remediation item #3 prescribed ("delete `-LOCAL` bodies in agents/skills,
**keep pointer lines**"). Largest remaining carriers, all 7-way:
`PITFALLS-LOCAL`, `VORPAL-TOOLS-LOCAL` (3,978B redundant),
`SHUTDOWN-PROTOCOL-LOCAL` (3,924B), `DOCTRINE-SCRIPT-TRUST-LOCAL` (2,418B),
`DOCS-PATHS-LOCAL` (1,278B).

The charter and the remediation plan genuinely conflict here. Recording the
pointer-stub pattern as a sanctioned exception to the zero-duplication target
is the cheap resolution; the alternative (agents carry no fence at all and rely
purely on progressive disclosure) is a real design change.

### 4.4 Frontmatter re-derivation — applied to skills, not to agents

Charter §3: all three 5-gen models default to `high`, often exceed prior-model
`xhigh` at lower settings, and "re-run an effort sweep on your own evals rather
than carrying 4.x values over." Remediation item #14 is the fleet sweep.

**Skills: PASS.** All 5 `effort: xhigh` pins removed; zero effort pins remain.

**Agents: FAIL.** The pins are **byte-identical to the baseline**:

| Agent | Baseline | Now | Audit's per-file target |
|---|---|---|---|
| team-lead | sonnet / xhigh | sonnet / **xhigh** | delete the pin (documented inert) |
| senior-engineer | sonnet / xhigh | sonnet / **xhigh** | → `high` + sweep |
| staff-engineer | opus / xhigh | opus / **xhigh** | → `high` |
| sdet | opus / xhigh | opus / **xhigh** | → `high`/`medium` |
| distinguished-engineer | fable / xhigh | fable / **xhigh** | → `high` or mode-conditional |
| security-engineer | opus / xhigh | opus / **xhigh** | → `high` advisor / `medium` reviewers |
| project-manager | sonnet / high | sonnet / high | → `medium` |
| ux-designer | opus / high | opus / high | — |

Two escalations from audit §6 *were* resolved:

- `security-engineer.md` now carries the deliberate-pin annotation
  (`model: opus # deliberate pin — security work routes off the gold/fable
  tier … never promote in a fleet sweep`), closing escalation §6.1's sibling
  concern.
- team-lead's model pin is ratified in-body via the two-cap economics
  paragraph (`team-lead.md:195`).

The effort pins are **not** inert in all paths. `team-lead.md:197` states
teammate spawns inherit session effort and frontmatter effort never binds for a
teammate — but that same line says report-only **subagent** spawns *do* honor
the definition's `effort:` and "are the only per-dispatch xhigh lane." Since
`@sdet` is dispatched as a report-only `verifier` subagent by default (step
15), `sdet.md`'s `effort: xhigh` binds on the fleet's second-most-common spawn
class. This is a live cost setting, not a no-op.

---

## 5. `/doctor`

`/doctor` is a Claude Code CLI built-in, not a repo skill; run as `claude
doctor`. Output:

```
Claude Code doctor
Running: native (2.1.220)
Commit: 4073f59596e2
Platform: darwin-arm64
Path: /Users/erikreinert/.local/share/claude/versions/2.1.220
Config install method: not set
Search: OK (bundled)
Auto-updates: enabled
Auto-update channel: latest
Last update attempt: failed (install_failed) — 2026-07-26

Remote Control
Unable to determine your organization for Remote Control eligibility.
- Organization not resolved

2 warnings found
- Running native installation but config install method is 'not set'
  Fix: Run claude install to update configuration
- macOS Keychain is not writable … Console login will fail to save your API key.
```

Both warnings are environmental (install-method metadata; keychain
permissions) and unrelated to the migration. No skill or agent definition is
implicated.

---
## 6. Part B — behavior verification: RUN (3 cycles)

The definitions were installed via `just activate` and verified byte-identical
to the repo (all 8 agents, all 17 skills, `references/` dirs live), then three
`claude -p --agent team-lead` cycles ran headless against throwaway git repos in
the scratchpad — never against this repo, whose Docket DB holds live issues.

| | Cycle 1 — Direct | Cycle 2 — Medium (design + review) | Cycle 3 — security Small |
|---|---|---|---|
| Task | fix an off-by-one in `line_count` | add stacking percentage + fixed-amount discounts; decide stacking order, rounding, validation | make an admin-token comparison constant-time |
| Spawns | **1** | **7** | **2** |
| Cost | **$1.09** | **$33.97** | **$5.05** |
| API time | 1.9 min | **97.7 min** | 17 min |
| Turns | 4 | 8 | 8 |
| Code shipped | yes | **no** | yes |
| Committed | no | no | no |
| `permission_denials` | `[]` | `[]` | `[]` |
| Verdict | **PASS** | **INCOMPLETE** | **PASS w/ routing failure** |

Model spend on cycle 2: Fable $17.76, Opus $17.09, Sonnet $6.26.

### 6.1 What held

**Routing is correct at every tier.** Cycle 1 drew exactly one implementer,
`impl-DKT-1` → `@senior-engineer` @ `sonnet` (bronze), with no advisor, PM,
panel, or verifier — no pattern inflation on a Direct task. Cycle 2 drew the
gold seat and the exact merged acceptance panel step 6 specifies:

```
advisor            -> distinguished-engineer @ fable   (author, recused from verdict)
DKT-V1-reviewer-1  -> staff-engineer         @ opus
DKT-V1-reviewer-2  -> senior-engineer        @ opus
DKT-V1-reviewer-3  -> sdet                   @ opus
DKT-V2-reviewer-{1,2,3}  same three seats, fresh ephemerals for round 2
```

Three seats, those three roles, `{vote-id}-reviewer-{N}` naming, and Rule 7's
new-ephemeral-per-round rule honored on the re-vote rather than resuming the
prior instances.

**Security pinned off the gold tier.** Cycle 3 routed the security review to
`@security-engineer` @ **`opus`**, never Fable — the charter §3 constraint that
`security-engineer.md`'s deliberate-pin annotation exists to protect. It held
under a live spawn.

**The commit gate held in all three cycles**, with `permission_denials` empty
every time — so this was agent restraint, not a harness refusal.

**Rule 10's design lock held under load.** Cycle 2 ran 97 minutes without
writing a line of implementation or creating a single Docket issue, because
design was never accepted. That is the gate working exactly as specified.

**Full-coverage review survived contact with reality.** Cycle 3's reviewer
returned four findings including a *pre-existing* Critical nobody asked about
(an empty `ADMIN_TOKEN` makes `compare_digest` succeed on empty input). Cycle
2's reviewers rejected the TDD twice on evidence — claimed fixes that no
failing test actually verified. The charter's counter-current protection
(§3.6) is real in practice, not just in the text.

**The authority gate held.** Cycle 3's reviewer returned Block; team-lead did
not disposition it on its own engineering judgment, but escalated to the
operator with three costed options — Rule 3a ("no override-on-merits")
behaving as designed.

### 6.2 Defects found

**B1 — The definitions have no headless-mode contract.** `team-lead.md:260`
sanctions "end the turn cleanly so the teammate's async reply lands as its own
new turn." Interactively that is right; under `claude -p` it ends the *run*.
Cycle 2 terminated with the advisor mid-revision on round 3 — 98 minutes and
$34 spent, no deliverable. Cycle 3 hit the same class from the other side:
Pre-flight steps 1 and 3 both mandate `AskUserQuestion`, which does not exist
headless (team-lead adapted in prose: "Since `AskUserQuestion` isn't in my
available tool set this session, I'll ask directly"). Root cause is the same as
the G3 defect fixed in §7 — an instruction whose premise does not hold in the
environment it runs in. **Severity: high** — it makes unattended/CI operation
unreliable, and neither gap is documented.

**B2 — the security panel was unbuildable at the size it was needed.** Cycle 3
ran a single `@security-engineer` subagent where Rule 8 specifies three seats.
Initially recorded as an unconsidered omission; investigation showed the
opposite — team-lead *did* fire the flag, calling it "the mandatory security
review (non-negotiable on an auth surface)" in its first turn. What it could
not do was build the panel.

Three rules collided on a security-sensitive trivial change, and no reading
satisfied all of them:

| Rule | Says |
|---|---|
| `Direct Task` (L109) | "no plan, **no review**" — roster is `@senior-engineer` alone |
| Security Track (L82) | security review "non-negotiable on any security surface" — but the carve-out named **Small** only, never Direct |
| Rule 8 / C3 | that review is `advisor` + `security-advisor` + `security-reviewer-2` — **persistent seats Direct never spawns** |
| QF-2 | "never drops to a lone security reviewer" |

So the 3-seat roster was unconstructible at that pattern size without standing
up two persistent seats for a one-line fix, and team-lead's single reviewer was
a reasonable resolution of an underspecified rule rather than negligence — it
violated QF-2 only because no constructible alternative existed. Emphasis would
have been the wrong fix: the trigger is already stated in six places.

**Resolved by operator decision (R16, §7): a two-seat floor on Direct/Small** —
`security-advisor` + `security-reviewer-2`, dropping the general `advisor` whose
value on a ≤3-file diff is low, keeping the cross-checking independence QF-2
demands. **Severity: was high; now closed.**

**B3 — Reviewer subagents wrote scratch files into the target repo.** Cycle 2
left nine files in the repo root: `.sdet_probe.py`, `.sdet_probe2.py`,
`.sdet_v2_b1.py`–`.sdet_v2_b5.py`, `.sdet_v2_acs.sh`, `.sdet_v2_ref.py` —
falsification harnesses for the reviewers' Blocker findings. In a real
repository these land in `git status` and are commit candidates.

**This is a rule gap, not a compliance failure** — the distinction matters for
the fix. The rule as written names one prohibited destination (`/tmp/…`) and
one correct destination (`$TMPDIR`); it never prohibits the working tree.
`sdet.md`'s banner: "NEVER write to a literal `/tmp/...` path … scratch/temp
writes go to `$TMPDIR`." The agent obeyed it exactly — it avoided `/tmp` — and
wrote to the third destination the rule is silent about, which happens to be
the harmful one. Notably `@sdet`, the role that leaked, carries the *most*
elaborated version of the rule (the only LONG variant across the 8 agents) and
it still has the gap.

An earlier draft of this report treated it as prose failing to hold and
proposed a blocking hook. That was wrong on the evidence and would have been
the wrong instrument: "scratch vs deliverable" is a judgment, not a crisp
boundary, so a blocking hook carries real false-deny risk against legitimate
file creation. Fix the rule first; if it then leaks, *that* is the regression
evidence the charter requires before adding a mechanism. **Severity: medium.**

**B4 — Spawn naming has no stable convention.** Three different forms across
four runs of the same definition, for the same role on the same kind of task:
`impl-DKT-1` (cycle 1, matching the Per-Role Dispatch Table), bare
`senior-engineer` (cycle 3), and `impl-cart-linecount` (a later probe run).
Canonical spawn names are a keep-list item (`sdet.md` §canonical spawn names)
precisely because downstream tooling greps them — `roster_sweep.sh` and the
Liveness-Confirmation Gate both match on name shape. **Severity: low
individually, medium as a class** — the gate that prevents duplicate live
seats depends on names being predictable.

**B5 — The acceptance vote did not converge.** Two full rounds, six Opus
reviewer spawns, both rejected, heading into round 3 of a 3-round maximum —
with all six reviewers endorsing the *architecture* both times. The rejections
were for repeated unverified completion claims by the gold author, which is
exactly the failure mode the charter's §2.1 grounded-progress-claims snippet
exists to prevent. The snippet is present in the fleet; it did not hold on the
Fable seat. **Severity: medium** — and the clearest candidate for a
before/after comparison once fixed.

### 6.3 The calibration question the numbers raise

Cycle 2's routing was correct at every step that can be checked, which means
the decision tree classified "add discounts to a two-function cart library" as
Medium, and Medium genuinely costs a gold author plus six Opus reviewer seats.
The output was a **49,430-byte / 476-line TDD** and zero code, for $33.97.

Nothing in §6.1 is wrong. The question is whether the Medium threshold is set
where the operator wants it — a decision-tree calibration matter, not a
definitions-coherence one, and the kind of thing only a behavioral run
surfaces. Worth deciding before this pattern runs on real work.

### 6.4 Method caveat — the sandbox degrades nested runs

The first cycle-1 attempt ran inside the session sandbox and came back
crippled: Bash died with `EPERM` for both team-lead and its teammate, no
transcript was written, and it cost **$1.98 / 282s / 1 turn**. Cause:
`~/.claude/projects` and `~/.claude/session-env` are write-denied in the
sandbox profile, so a nested session cannot initialize. Re-run with the sandbox
disabled, the identical task cost **$1.09 / 114s / 4 turns** — the degraded run
burned 45% more money and 60% more wall-clock fighting a broken tool envelope.
All three reported cycles ran with the sandbox disabled. Anyone repeating this
must do the same or the numbers are meaningless.

Worth noting on its own terms: the sandbox-recovery doctrine correctly
*detected* the failure (the teammate reported reproducing it with sandbox
disabled) but the cycle still degraded to file-reads-only — detection without a
recovery path.

## 7. Fix list

### Applied (this pass)

| Fix | File | Class |
|---|---|---|
| Bare relative `references/monitor-orchestration.md` → full deployed-path form | `agents/team-lead.md:263` | broken reference |
| `references/pitfalls.md` → `pitfalls.md` (sibling, from inside `references/`) | `skills/team-doctrine/references/retention-compaction.md:4` | broken reference |
| **G1** — `TeammateIdle` no longer asserted as proof a rule failed; reframed as routine lifecycle that *prompts* the owed-reply check, citing team-lead.md §Teammate Stall & Crash Recovery as authority | `agents/staff-engineer.md:77` | class 1.6 |
| **G2** — same reframing, citing the file's own §Lifecycle (idle-after-verdict is normal) | `agents/sdet.md:54` | class 1.6 |
| **G3** — unsatisfiable "if Write is absent, Write…" replaced with the actual mechanism: a quoted-delimiter heredoc under `$TMPDIR`, pointing at `senior-engineer.md §Shell hygiene` as master | `agents/security-engineer.md:55`, `agents/ux-designer.md:69` | logic defect |
| **R16** — security-review floor: Direct/Small now specifies two security seats; Rule 8's 3-seat roster scoped to Medium+ where the `advisor` seat exists | `agents/team-lead.md` (5 sites: Security Track, Direct heading, dispatch table, C3, QF-2) | rule collision |
| **R17** — scratch-file destination: `$TMPDIR` rule now names the working tree as prohibited, not just `/tmp` | `agents/senior-engineer.md` (master), `agents/sdet.md` | rule gap |

**On G1/G2 — which side was wrong.** `team-lead.md:338` is the authority and
states it plainly: "`TeammateIdle` fires on nearly every spawn as routine
lifecycle — it triggers the checks below, **never a stall verdict alone**," and
"`TeammateIdle` on an advisor is **not a stall**." So the "means rule N failed"
halves were the incorrect ones, and the "idle is normal" halves already agreed
with the master. Both rewrites keep the useful behavioral instruction (reply
that turn with current state) while removing the false premise, and now cite
the master instead of restating it.

**R15 — unattended-run safety** (`agents/team-lead.md`, §6.2 B1). Cycle 2 died
because `team-lead.md:260` sanctioned ending a turn to await a worker — correct
interactively, fatal under `claude -p`, where it ends the run with dispatched
work in flight.

The **first attempt was wrong and is recorded as such**: it added a session-mode
discriminator keyed on whether `AskUserQuestion` was in the live tool list, on
the strength of cycle 3 reporting the tool absent. Live testing falsified that
signal — an identical headless run declared `Mode: ATTENDED`, i.e. inferred the
tool *present*, then told a non-existent operator "no further action needed from
you in the meantime." Two headless runs, opposite readings of the same signal.
The declaration mechanism itself worked (making it Pre-flight step 0 got it
emitted on turn 1); what it keyed on was unreliable.

The shipped fix removes the inference instead of improving it — both paths are
made safe, which also removes a branch rather than adding one:

- **Arming a wait is unconditional** while dispatched work is outstanding.
  Ending a turn is safe only if another turn is guaranteed, and nothing in
  context establishes that. With an operator, arming costs nothing (the wait
  exits on its own signal); without one it is the difference between a
  delivered result and a lost run.
- **Every Pre-flight `AskUserQuestion` is best-effort at the point of use** —
  keyed on the call actually being unavailable, not on an up-front guess.
  Fallbacks are the conservative branch and get recorded as assumptions. Where
  a gate states no fallback, a judgment team-lead may not make routes to
  `Skill(vote, ...)` (charter §1.3 — a principle, not four enumerated sites).

**Verified live.** A headless Direct cycle on the installed fix: zero mode
declarations, a wait armed via `run_in_background`, ran to completion in 9
turns (up from 2–4, the orchestrator now holding control through waits), fix
correct with `subtotal` untouched, at **$0.97** — the cheapest of four Direct
runs ($1.09 / $1.18 / $1.01 / $0.97). More turns, less spend.

Cost: +1,646 bytes on `team-lead.md` (76,909 → 78,555), a real trade against
§4.1's target, taken for the highest-severity behavioral defect.

**On G3 — what the clause was trying to say.** `senior-engineer.md:306` (the
shell-hygiene master) says only that "zsh history-expansion mangles `!` in
Bash-tool strings — avoid bare `!=` inline; escape it." The two agent copies had
garbled that into a blanket ban on heredocs, which removed the one mechanism
that solves the problem — a quoted delimiter suppresses expansion entirely.
Only 2 of 8 agents carried the clause; the other 6 have the envelope check with
no fallback, so nothing else needed touching.

All five re-verified green: `doctrine_check.sh` (4 arms), `coupling_check.py`,
`symmetry_check.py`, `drift_guard_check.py`, `tier_map.sh`, and the
cross-reference checker (both new section anchors resolve; marker counts
unchanged).

> **Not yet committed.** `guard-no-commit-hook.sh` blocks git writes in the
> `auto` permission mode this session runs in ("git writes are blocked in
> non-interactive permission mode 'auto' where a human can't confirm
> approval"). The two edits are in the working tree unstaged. Commit them from
> an interactive mode (`default`/`plan`/`acceptEdits`) with:
>
> ```
> fix(claude-code): resolve two unresolvable relative doc references
> ```

### Routed to a Phase 2/3-style session (structural — do not patch ad hoc)

| # | Item | Why routed | Owner phase |
|---|---|---|---|
| R1 | **Agent frontmatter sweep** — re-derive `effort` on 6 agents per charter §3 (§4.4) | Needs an effort sweep on real evals, not a text edit; changes dispatch cost on the two most common spawn classes | Phase 2 follow-up (remediation #14) |
| R2 | **Banned-confidence-phrase list** — single-home in `report_lint.py`; `design-review` (4) and `sdet.md` (8) disagree with the linter's 6 (§3.3) | Touches a declared coupled family under a shared validator; which phrases belong is a content decision | Phase 3 (review family) |
| R3 | **`brief` skill's stale "HARD GATE" label** ×3 incl. the frontmatter description (§3.5) | Trivial as text, but the wording is the operator-facing intake contract with team-lead's Pre-flight step 1 — rename both ends together | Phase 3 |
| R4 | **Record team-lead's marker-ceiling exception** (15 vs ≤10; all 15 map to keep-list) (§4.2) | Documentation decision belonging with the other §6.7 exceptions | Migration owner |
| R5 | **Record the pointer-stub exception** to the zero-duplication target (§4.3) | Charter §4 and remediation #3 conflict; needs an explicit ruling | Migration owner |
| R6 | **Byte-target shortfall** — agents 2.13×, team-lead 2.56×, skills −30.3% vs −50% (§4.1) | Closing it requires the coordinated all-carriers + manifest edits and consumer-lockstep changes both phases declared out of scope | Migration owner — re-scope or ratify |
| R7 | **Finish the three DELETE-WHOLE-FILE verdicts** (`laziness-discipline`, `fable-completeness-heuristics`, `team-conventions`) (§3.4) | Requires repointing live citers in Phase 2 agents and out-of-scope `evolve-*` skills in lockstep | Phase 3 |
| R10 | **Doc-family 5-way COUPLING vs init-specs** (G4) — either init-specs gains a "When NOT to Use" section or the comment drops to 4 members | Family contract across 5 skills; also **extend `coupling_check.py`** to assert each named member carries the coupled section, which is the blind spot that let this pass | Phase 3 |
| R11 | **`verify-ac` `uncommitted` scope misses untracked files** (G5) | Real behavioral defect but **pre-existing**, not caused by the migration — file it on its own merits rather than as migration cleanup | Standalone bug |
| R12 | **Agent description accuracy** — team-lead read-only overclaim, staff-engineer "reviews all"/TDD-authorship overclaim, project-manager write-path omission, senior-engineer `docs-author` omission (G6–G8) | Descriptions drive harness routing and are **duplicated as Rust string literals in `src/user.rs`** for the opencode variant — fix both homes together | Phase 2 follow-up |
| R13 | **`evolve-orchestration-core.md` Consumers line** lists 3 of 5 real consumers (G9) | Out-of-scope `evolve-*` consumers must be re-checked in the same edit | Phase 3 |
| R14 | **Decide the fate of `src/user/opencode/agents/`** (398KB, unmigrated) (§3.8) | A second, now-divergent generation of the same 8 agents; migrate, regenerate, or retire | Migration owner |
| ~~R15~~ | **Unattended-run safety** — **APPLIED AND VERIFIED LIVE** (§7) | First design falsified by testing and replaced; shipped fix confirmed on a live headless cycle | — |
| ~~R16~~ | **Security panel unbuildable on light patterns** — **APPLIED** (§7) | Diagnosed as a three-way rule collision, not a missed trigger; resolved by operator decision to a 2-seat floor. Unverified live | — |
| ~~R17~~ | **Scratch-file destination gap** — **APPLIED** (§7) | Diagnosed as a rule gap rather than a compliance failure; the working tree was never named as prohibited. Rule fixed at the master + the one elaborated carrier. Unverified — a repeat leak would be the evidence for adding a mechanism | — |
| **R18** | **Grounded-progress-claims snippet not holding on the Fable seat** (§6.2 B5) | Two vote rounds lost to claimed-but-unverified fixes. The §2.1 snippet is present; the gold seat's authoring path may need the claim-audit made a pre-emission step | Phase 2 follow-up |
| **R19** | **Medium-tier cost calibration** (§6.3) | $33.97 / 97.7 min / 49KB TDD / zero code for a discount function. Routing was correct — the question is whether the Medium threshold sits where you want it | Migration owner |

---

## 8. What this pass did not cover

- **Runtime behavior beyond three cycles.** §6 covers one Direct, one Medium,
  and one security-sensitive Small. Untested: Large/deep-impl, the doubled
  general panel (no Rule 8 (a)/(b)/(c) trigger fired), `@ux-designer` and
  `@project-manager` seats, verification phase (cycle 2 never reached it), the
  fix-loop, and resume-from-existing-issues. Cycle 2's `INCOMPLETE` verdict
  means the Medium path is only verified through design acceptance.
- **Whether the five §7 fixes changed behavior.** All three cycles ran on the
  fixed definitions, so there is no before/after comparison — the fixes are
  verified coherent, not verified effective.
- **The `.claude/skills/evolve-*` consumers** were read for cross-reference
  resolution only; they were out of the migration's scope and were not graded
  against the charter.
- **Hook behavior** (`stop-guard-hook.sh` in particular) — audit escalation
  §6.5's largest measured thrash source is out of definition-file scope and
  remains unaddressed.
- **`docket_ref_check.sh`** was not run (requires the `docket` CLI against a
  live DB); the Phase 3 note records it green at 51 subcommands.
