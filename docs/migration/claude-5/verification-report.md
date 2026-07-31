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

**Fourteen fixes applied** (§7): two broken references, both `TeammateIdle`
contradictions, the unsatisfiable instruction, and the headless-mode contract
(R15 — applied after Part B; its first design was falsified by live testing and replaced), plus all four remaining behavioral defects (R16, R17, R20, R21). **All five cross-file contradictions are now resolved** (R22–R24 closed the
remaining three). Nine items remain routed,
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
| A8 | No contradictory rules across files | **FIXED (5 of 5)** | §3.3 + §3.7 — all five resolved (§7): both `TeammateIdle` pairs, banned-phrase drift, doc-family COUPLING, evolve-core Consumers |
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
| **B9** | Security panel provisioned as specified | **FIXED, VERIFIED** | §6.3 — re-run spawned both security seats on `opus` |
| **B10** | Scratch files stay out of the working tree | **FAIL → refixed, unverified** | §6.2 B3 / §6.3 — first fix was mis-scoped to 3 of 8 roles and a leak recurred from another; now in all 8 banners |
| **B11** | Spawn names match the dispatch table | **PARTIAL** | §6.3 — seat names now canonical; `{DOCKET-ID}` substitution still drifted, rule tightened |
| **B12** | Acceptance vote converges | **FAIL → FIXED** | §6.2 B5 — 2 rounds lost to unverified remediation claims; R21 (§7) requires cited before/after evidence |

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

**Resolved (R22, §7).** `report_lint.py` is the enforcement authority, so prose
aligns to it rather than the reverse: `design-review` gained the two it was
missing, `sdet.md` dropped `I'm sure`/`trust me` — phrases it called
"sign-off-disqualifying" while nothing enforced them. All four prose copies now
name the linter's six and cite it as the source. Adding the two dropped phrases
to the linter remains open, but that is a change to enforcement, not a drift.

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

### 3.8 A finding this report previously made in error — `opencode`

An earlier revision flagged `src/user/opencode/agents/` (398KB, 8 same-named
roles) as "a second, now-divergent generation of the same fleet" and asked
whether to migrate, regenerate, or retire it. **That was wrong**, and it is
recorded here rather than silently deleted because it is the kind of error a
directory listing invites.

`opencode` is a deliberate port to a different harness, not a stale copy:

| | claude-code | opencode |
|---|---|---|
| shared unique lines (`team-lead`) | — | **57 of 276 (~20%)** |
| `teammate`/`SendMessage` mentions | 51 | **3** |
| model/effort pins | YAML frontmatter | none — configured in `opencode.json` |

OpenCode dispatches subagents that return summaries; it has no
persistent-teammate or peer-messaging substrate, so Rule 7's lifecycle, the SP
protocol, and the charter §3 frontmatter deltas have no counterpart there. Its
own history documents the port (`migrate … agents to opencode harness`,
`convert to native agent/skill structure`, `configure cross-provider model
tiers`).

The charter scopes this migration to `src/user/claude-code/`; `opencode` is
correctly outside it and needs no decision from this work. The one narrow
observation that survives is that improvements have historically been ported
across (`feat(codex): port designer improvements from claude code`), so its
owner may eventually want the Claude 5 changes — a separate piece of work whose
first question is which of them even apply to a harness with no teammates.

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

  **The inline comment is safe — verified live, not assumed.** The annotation
  was briefly stripped on the theory that a trailing `#` comment on a
  frontmatter scalar might break parsing. An A/B on project-level agents,
  sandbox disabled, settles it: `model: opus` and `model: opus # <the full
  annotation>` both resolve to `claude-opus-5`, while a `model: sonnet` control
  resolves to `claude-sonnet-5`. The negative control is what makes this
  conclusive — it proves the harness genuinely reads the frontmatter field
  rather than defaulting everything to Opus, so the commented variant matching
  the bare one is a real pass. The annotation was restored.

  Note that §6.1's cycle-3 evidence does **not** by itself prove the pin
  parsed: `security-advisor` and `security-reviewer-2` are `silver` in
  `tier_map.sh`, and `silver` resolves to Opus anyway, so dispatch alone would
  have produced Opus with or without a working frontmatter pin. The A/B is the
  first direct evidence.
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

### 4.5 R6 re-diagnosed — the target is reachable; a remediation was skipped

Phases 2 and 3 attribute the byte shortfall to structurally pinned content.
Measured against the current tree, that explanation covers **77,550 of 367,955
agent bytes — 21%**:

| file | bytes | pinned | % |
|---|---:|---:|---:|
| team-lead.md | 79,889 | 13,438 | 17% |
| senior-engineer.md | 48,378 | 10,947 | 23% |
| sdet.md | 42,409 | 10,168 | 24% |
| distinguished-engineer.md | 42,142 | 9,685 | 23% |
| ux-designer.md | 37,693 | 9,728 | 26% |
| security-engineer.md | 41,734 | 7,610 | 18% |
| project-manager.md | 34,531 | 7,673 | 22% |
| staff-engineer.md | 41,179 | 8,301 | 20% |
| **total** | **367,955** | **77,550** | **21%** |

("Pinned" = CANONICAL-fenced blocks + fenced command syntax + markdown tables —
i.e. everything parity-locked, drift-guarded, or machine-parsed.)

That leaves **290,405 bytes of free prose** against a 170,000-byte total
target: reaching it requires free prose to fall to ~92,450, a 68% cut. Aggressive
— but the charter's own reference point is Anthropic removing 80% of Claude
Code's system prompt with no eval regression. Structural pinning explains 77KB
of a 193KB gap; it does not explain the gap.

**The specific cause is identifiable.** Agents have **no `references/` split at
all** — every one is a single file. The audit's ranked remediation #1 was
"team-lead.md → ≤30KB (3-way references split + 1.2/1.4 deletions + marker
map)", splitting the Execution Workflow into `references/stall-recovery.md`,
`shutdown-lifecycle.md`, and `review-reconciliation.md` (~57KB out, ~8KB
inline). It was never executed: Phase 2 declared reference-file creation out of
scope ("skills are Phase 3"), Phase 3 covered only `skills/`, and the item fell
between them. `team-lead.md`'s section profile still shows it:

| section | bytes | % of file |
|---|---:|---:|
| Execution Workflow | 34,697 | **43.4%** |
| Spawning Templates | 14,015 | 17.5% |
| Rules | 7,426 | 9.3% |
| Pre-flight | 7,148 | 8.9% |

61% of the file sits in the two sections the audit named. The content is
largely contingency material — stall ladders, shutdown edge cases, review
reconciliation — which is what progressive disclosure is for: loaded when the
exception fires, not every turn.

So R6 is not a request to ratify a missed target. It is a scoped piece of work
with a known shape, and the charter's caveat still governs its execution —
reduction is a consequence of applying §1, never a goal pursued by deleting
context the model cannot reconstruct.

**First split executed — the pattern is verified end-to-end.**
`### Teammate Stall & Crash Recovery` (6,806B) moved to
`team-doctrine/references/stall-recovery.md`. It was the safe candidate: zero
fenced blocks, zero `skip --help` drift-guard markers (those sit in the Monitor
and Wrap-up sections), and exactly one external citer — `ux-designer.md`, which
references the Liveness-Confirmation Gate *by name*, so the name stays inline.

What stayed inline is the binding core: the Gate's one-live-instance rule,
SP-3's positive-death-evidence requirement, reply-at-any-latency-means-alive,
and that `TeammateIdle` is routine lifecycle rather than a stall verdict. What
moved is the mechanics you read *when* a teammate goes quiet — triage table,
probe contract, reconciliation path, redirect-race rule, bare-idle
disambiguation, the full ladder.

| | before | after |
|---|---:|---:|
| `team-lead.md` | 79,889 | **74,612** |
| agents total | 367,955 | **363,014** |
| team-lead markers | 15 | 14 |

Checks after: doctrine (4 arms, index now 18 rows), coupling, symmetry,
drift-guard (still finds all 3 blocks), tier_map, cross-reference — all green.

**Framed honestly, this is a loaded-context win, not a total-bytes win.** The
reference file is 7,240B against 5,277B removed, because it gained a provenance
header and the inline core was kept deliberately. Per-invocation cost is what
the charter's progressive-disclosure rule targets, and that fell 5.3KB for every
orchestration turn that does *not* hit a stall.

**Remaining to reach ≤30KB.** `Wrap-up & Team Cleanup` (~7.8KB) and
`Spawning Templates` (~14KB) are the next candidates, but both are harder than
the first: Wrap-up contains the `dispatch_ledger.sh` drift-guarded block, and
`drift_guard_check.py` takes a single `--doc`, so moving it means either
re-pointing the check or invoking it twice. Spawning Templates feeds
`tier_map.sh`'s Per-Role Dispatch Table parse. Neither is blocked — both need
the check wiring updated in the same change, which is why they were not done
opportunistically here.

**Correction — those two figures overcount what can actually move.** The
~7.8KB / ~14KB above are section-boundary measurements. Measured against what
is structurally movable, most of both is pinned:

| candidate | section bytes | actually relocatable | what blocks the rest |
|---|---:|---:|---|
| Wrap-up & Team Cleanup | 7,810 | **3,183** | 2,821B `SHUTDOWN-PROTOCOL-LOCAL` + 804B `DOCKET-CLI-LOCAL` are CANONICAL blocks pinned byte-identical across all 8 agents; 964B is already pointer stubs |
| Spawning Templates | 14,015 | **2,588** | 8,993B is the Tiers block + Per-Role Dispatch Table that `tier_map.sh` parses; 2,337B is point-of-action spawn rules (SP-2 exclusivity, the ephemeral-brief schema, the Closed-vs-Open FORBIDDEN rule) |

So **relocation alone bottoms out near 68.8KB, not the ~53KB** a
section-boundary reading implies. The residual gap to the 30,000B ceiling is
about 38.8KB, and closing it is prose reduction inside the remaining sections —
charter §1 judgment work — not further relocation. R6 should be scoped against
that number.

Moving the CANONICAL blocks is not merely harder, it is wrong: they are pinned
byte-identical across 8 carriers precisely so no single carrier can drift, and
relocating one carrier's copy breaks the invariant in the other seven.

**Second split executed — `Wrap-up & Team Cleanup`.** The end-of-cycle
mechanics (spot-check, ledger pass, summary, dispatch-ledger instrumentation,
CLOSED-set shutdown, team cleanup) moved to `team-doctrine/references/wrap-up.md`.
Three items stayed inline against the point-of-action test: the promised-gate
delivery check (it also gates the step 14/15 verdicts, so it fires outside
wrap-up), the shutdown-direction rule (cohesive with the CANONICAL protocol
block directly beneath it), and the report that nothing was committed.

| | before | after |
|---|---:|---:|
| `team-lead.md` | 74,612 | **73,016** |
| doctrine index rows | 18 | **19** |

Checks after: doctrine (4 arms), coupling, symmetry, drift-guard, tier_map,
cross-reference — all green, plus 31/31 script test files.

**Checker wiring changed in the same commit, as required.** The
`dispatch_ledger.sh` drift-guarded block moved with the mechanics, so
`drift_guard_check.py` went from a single `--doc` to a doc *set*, defaulting to
every document that holds an inlined block. This also closed a latent hole the
relocation would otherwise have opened: a scan finding zero blocks prints
`none found` and **exits 0**, so a block relocated into a document nobody scans
would have passed vacuously rather than failing. A new test re-derives the true
holder set by walking the tree and fails if the default set does not cover it.
`tier_map.sh` needed no change, because the Tiers block and Dispatch Table it
parses deliberately stayed inline.

**Why the Dispatch Table should not be the next thing relocated.** It carries
R20's binding-name rule (`impl-{DOCKET-ID}`, never a descriptive slug). R20 is
still only PARTIAL (§6.3), and moving that rule behind progressive disclosure
puts it exactly where §6.3's R17 lesson says a point-of-action rule must not
live — "a rule that must fire at the point of action belongs in the
always-loaded block of every role that can take that action." The stall-recovery
split was chosen as the safe first candidate for the same class of reason.

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

**Install re-validated before the R21 cycle.** `~/.claude/agents` and
`~/.claude/skills` were both live symlinks into the Vorpal store; `diff -r`
reported all 8 agents byte-identical and the skills tree content-identical (the
only delta being an empty harness-created `.claude/.cc-writes/` scratch dir).
`doctrine_check.sh` passed pointed at the installed copy via `SKILL_MD` /
`REFERENCES_DIR`.

One caveat on that mechanism, since it affects how much the installed-copy run
proves: those two variables redirect only the doctrine `SKILL.md`/`references`
arms. The CANONICAL carrier arm still resolves repo-relative paths from
`doctrine_check_manifest.tsv`, so it reads repo files either way. With the trees
byte-identical the distinction is moot here, but "checked against the installed
copy" is only partly true as a mechanism, and a future divergence between repo
and install would not be caught by the carrier arm.

A consequence worth recording for method integrity: because the install is a
symlink into the content-addressed store, editing the repo working tree does
**not** change what a nested cycle loads. Repo-side refactoring and a running
behavioral cycle cannot confound each other until the next `just activate`.

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
**Correction to an earlier draft of this report:** it justified this by
claiming `roster_sweep.sh` greps name shapes. It does not — it queries
`docket issue list -a @<role>`, keyed on role, not spawn name. The real
consequence is narrower but genuine: the Liveness-Confirmation Gate enforces
"at most ONE live instance per seat/name" by matching names *exactly*, so two
different names for one logical seat defeat that check silently.

Root cause: `sdet.md:161` states verification names as a binding rule
("Canonical VERIFICATION spawn names (only three allowed) … variants are naming
drift — refuse the dispatch"), but implementation names appear only as a cell in
team-lead's Per-Role Dispatch Table, which reads as descriptive. **Severity:
low individually, medium as a class.** Fixed in R20 (§7).

**B5 — The acceptance vote did not converge.** Two full rounds, six Opus
reviewer spawns, both rejected, heading into round 3 of a 3-round maximum —
with all six reviewers endorsing the *architecture* both times. The rejections
were for repeated unverified completion claims by the gold author.

The grounded-claims doctrine is present and strong on that seat —
`distinguished-engineer.md:171` ("**No guessing.** Uncertain about an API
signature, spec convention, file's contents, or test outcome — resolve it with
Read/Grep/Bash *before it appears in a design, verdict, or diff*") and L151's
documented-vs-inference labelling. But both govern **facts asserted in the
artifact**. Neither covers the distinct claim class that actually failed: *"the
finding you raised is now addressed."* A remediation claim is not a fact about
the system, so the existing rules did not reach it. **Severity: medium.** Fixed
in R21 (§7).

### 6.3 Re-run after the fixes — one verified, one partial, one failed

The cycle-3 task was re-run against the installed fixes. Same prompt, same
starting file, so it is a genuine before/after.

| | cycle 3 (before) | re-run (after) |
|---|---|---|
| Security seats | **1** | **2** — `security-advisor` + `security-reviewer-2`, both `opus` |
| Spawns total | 2 | 5 (adds a fix round + follow-up planner) |
| Cost | $5.05 | **$20.21** |
| API time | 17 min | 70 min |
| Outcome | ended asking the operator | completed, incl. a fix round |
| Committed | no | no |

**R16 — VERIFIED.** The two-seat floor spawned exactly as specified, both on
`opus`, never Fable. The run also went further than cycle 3 did (a
`-fix-1` round and a follow-up planner) rather than stalling on a question,
which is R15's unconditional wait-arming compounding.

**R20 — PARTIAL.** Seat names came out canonical (`security-advisor`,
`security-reviewer-2`, `planner-{slug}`), but implementation spawns were still
`impl-admin-token-fix` rather than `impl-{DOCKET-ID}`. Declaring the Name column
binding fixed the seat names and not the placeholder substitution; the rule now
says explicitly that `{DOCKET-ID}` means the issue ID and that the issue is
created before the spawn if it does not exist.

**R17 — FAILED, and the original fix was mis-scoped.** One scratch file leaked
again — `.docket_issueA_body.md` in the repo root. The first R17 pass fixed the
shell-hygiene master and `sdet.md` on "one home" reasoning, deliberately leaving
the seven short banner copies alone. But those short copies are what the other
roles actually read, and they carried only the `/tmp` prohibition — so the leak
recurred from a *different role* than the one that was fixed. The prohibition
now appears in all eight agent banners. The lesson generalizes: a rule that must
fire at the point of action belongs in the always-loaded block of every role
that can take that action, not only in the master.

### 6.4 The calibration question the numbers raise

Cycle 2's routing was correct at every step that can be checked, which means
the decision tree classified "add discounts to a two-function cart library" as
Medium, and Medium genuinely costs a gold author plus six Opus reviewer seats.
The output was a **49,430-byte / 476-line TDD** and zero code, for $33.97.

Nothing in §6.1 is wrong. The question is whether the Medium threshold is set
where the operator wants it — a decision-tree calibration matter, not a
definitions-coherence one, and the kind of thing only a behavioral run
surfaces. Worth deciding before this pattern runs on real work.

### 6.5 Method caveat — the sandbox degrades nested runs

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

### 6.6 Cycle 4 — the R21 attempt, and why it does not verify R21

A fourth cycle ran the same discount task against a fresh throwaway repo
(stdlib `unittest`, since this machine has no pytest, uv, or virtualenv — R21
needs a runnable check or it cannot be cited). Sandbox disabled per §6.5.

| | cycle 2 (baseline) | cycle 4 |
|---|---:|---:|
| Classification | Medium | **Small** |
| Spawns | 7 | **4** |
| Cost | $33.97 | **$8.77** |
| Wall clock | 97.7 min | **25.0 min** |
| API time | 97.7 min | 24.5 min |
| Turns | 8 | 10 |
| Code shipped | **no** | **yes** — 222 insertions |
| Tests | — | **29/29 pass** |
| Docket issues | **0** | `DKT-1`, closed `done` |
| Committed | no | no |
| `permission_denials` | `[]` | `[]` |

Model spend: Opus $5.07, Sonnet $3.70, Haiku $0.0006. No Fable — consistent
with no gold seat being drawn.

**R20 — VERIFIED, closing §6.3's PARTIAL.** The spawn roster came back
`advisor`, `planner`, `impl-DKT-1`, `impl-DKT-1-fix-1`. The implementation
spawns use the canonical `impl-{DOCKET-ID}` / `-fix-{N}` form with the real
issue ID substituted — not the descriptive slug (`impl-admin-token-fix`) that
the previous re-run produced. This is the half the last pass could not fix.

**R21 — NOT EXERCISED. This cycle is not evidence for it.** R21's text lives in
`distinguished-engineer.md`, and that agent was never spawned: the advisor seat
resolved to `@staff-engineer` @ `opus`, the dispatch table's *sub-Medium*
advisor. No TDD was authored, `docket vote list` reports no proposals, and the
one fix round answered reviewer **Concerns**, not a **Blocker**. R21 fires only
on a revision answering a Blocker in a TDD revision round, so none of its
preconditions were met and its text was never loaded. Recorded as not
exercised — not as a pass.

What the fix round *does* show is the behavior class R21 targets, arriving from
a different seat under a different rule. The remediation comment names the
tests it added, states the discriminating values it verified numerically before
writing them, and cites the resulting count (`29/29 OK — 26 prior + 3 new`).
That is a cited, checkable remediation claim rather than a bare "addressed".
Encouraging, but it is evidence about the general-review path, not about R21.

**The classification difference is itself a finding.** Substantively the same
task drew Medium in cycle 2 and Small here — 7 spawns versus 4, gold advisor
versus silver, TDD-and-vote versus none. Either the decision tree is
nondeterministic at this boundary, or one of the applied fixes moved it. Worth
resolving before the tree is trusted to route real work, and it is the reason
R21 still has no behavioral evidence after two attempts.

**R19 — a number, but not a comparable one.** $8.77 prices a *Small* cycle. It
cannot be set against the $33.97 Medium baseline to argue the Medium threshold
moved; the two runs did not run the same pattern. The Medium calibration
question stays open on the original data.

**R17 — clean, on weaker evidence than it looks.** No scratch file appeared in
the repo root. But no `sdet`/`verifier` spawned in this cycle, and the original
leak came from an sdet-class scratch file — so the role that produced the
defect never ran. Absence of a leak here is consistent with the fix working and
equally consistent with the fix being untested.

**The commit gate held.** The working tree carried 222 uncommitted insertions
at exit, with `permission_denials` empty — agent restraint, not a harness
refusal, matching all three earlier cycles.

### 6.7 R29 diagnosed and fixed — an underdetermined rule, not a coin flip

The cycle 2 / cycle 4 split (§6.6) looked like nondeterminism. It is not. Both
classifications were **compliant with the rules as written**, which is the
defect.

Rule 10 requires dispatches to carry zero open design questions. The Small
pattern's Rule 10 bar then said: an unsettled known decision → "consult
`advisor` first **or** graduate to Medium." That `or` is a free choice with no
selection rule, so three open decisions (stacking order, rounding, rejection
semantics) could legally be settled either by an advisor consult inside Small
*or* by a TDD and acceptance panel at Medium. Two conforming runs, two answers.

Two amplifiers made the lighter branch the likely one under `claude -p`: the
tree's "default to the lightest pattern that fits", and Pre-flight step 4's
"bias toward the lighter pattern / **if unavailable, take the lighter
pattern**" — so an unattended run tended to classify a design-bearing task
light precisely when no operator was there to catch it.

**Fix — give the `or` an operational test.** Count the architectural dimensions
the request leaves OPEN (data model, ordering/precedence, rounding/precision,
error/rejection semantics, public API surface) that neither the request nor a
citable accepted source settles. Two or more that INTERACT → Medium, because
interacting decisions need one coherent written design rather than serial
consults that each assume the others. Exactly one isolated open dimension may
stay Small, settled by an `advisor` consult cited as its Design-source. The
count and the dimension names must be stated in the classification line — an
unrecorded count is what let this drift silently. The lighter-pattern bias is
now scoped to genuine ties and cannot override a test result.

**Validated against all four cycles on record:**

| cycle | task | open dimensions | test says | actual |
|---|---|---:|---|---|
| 1 | off-by-one in `line_count` | 0 | Direct | Direct ✓ |
| 3 | constant-time token compare | 0–1 | Small + security | Small ✓ |
| 2 | stacking discounts | 3, interacting | **Medium** | Medium ✓ |
| 4 | stacking discounts | 3, interacting | **Medium** | Small ✗ — corrected |

The interaction claim is not asserted, it is measured — from cycle 4's own
shipped tests: discount order changes the result (`[10%,5%]`→89 vs
`[5%,10%]`→90), and rounding diverges by order of operations (percent 1.15 on a
3000 subtotal → 35 via the decimal path, 34 via a naive float path). Order and
rounding are not separable decisions, which is exactly why serial consults were
the wrong instrument.

**Cost.** +1,349B on `team-lead.md`, which eats most of §4.5's split win: the
file lands at 74,365B, a net −247B across both changes. Recorded rather than
hidden — a correctness fix to the routing tree is worth more than the bytes,
but R6's ledger should not be read as if the split still stands alone.

**Not yet retested live.** The fix is validated against the recorded cycles, not
against a new run. R21 still needs a cycle that reaches a TDD revision round,
and this fix is what should make that cycle classify Medium reliably.

### 6.8 Cycle 5 — R29 verified live; R21 blocked by success

The R29 fix was installed and the discount task re-run against a repo rebuilt
from the original commit (not cycle 4's output), same prompt as cycle 4.

| | cycle 2 (before) | cycle 4 (Small) | cycle 5 (after R29) |
|---|---:|---:|---:|
| Classification | Medium | Small | **Medium** |
| advisor seat | `@distinguished-engineer` `fable` | `@staff-engineer` `opus` | **`@distinguished-engineer` `fable`** |
| Spawns | 7 | 4 | **8** |
| TDD | 49,430B | none | **36,040B** |
| Acceptance vote | **lost 2 rounds** | none | **converged round 1** |
| Code shipped | **no** | 222 ins | **249 ins** |
| Tests | — | 29/29 | **38/38** |
| Cost | $33.97 | $8.77 | **$36.76** |
| Wall clock | 97.7 min | 25.0 min | **54.4 min** |
| API time | 97.7 min | 24.5 min | 65.6 min |
| Turns | 8 | 10 | 14 |
| Committed | no | no | no |
| `permission_denials` | `[]` | `[]` | `[]` |

Model spend: Fable $21.22, Sonnet $10.45, Opus $5.09.

**R29 — VERIFIED LIVE, with a correction to this claim's original wording.**
Same task text, same pristine starting repo, same harness. This section first
read "the only variable changed was the fix"; that was **false** and is
corrected here. The install window between cycles 4 and 5 also contained the
wrap-up reference split and a role-description alignment, and `team-lead.md`
moved 79,889 → 74,612 → 73,016 → 74,365 across that span. The gold-seat draw
still evidences the classification *in that run*, but a single post-fix sample
does not establish determinism for a rule §6.7 itself proved was previously a
free choice — the falsifier (a post-fix run classifying Small) was never given
a chance to appear. Classification moved Small →
Medium and drew the full merged acceptance panel — `DKT-V1-reviewer-{1,2,3}` on
`@staff-engineer` / `@senior-engineer` / `@sdet`, all `opus` — identical in shape
to cycle 2's. The gold seat spawns only on Medium+ TDD-bearing cycles, so its
presence is direct proof of the classification rather than an inference.

**The acceptance vote converged on round 1.** No `DKT-V2-*` seats spawned and no
`-fix-*` rounds ran. Against §6.2's B12 (2 rounds lost to unverified remediation
claims) and the success bar set for this work — the vote converges, or rejects
on substance rather than on unverified claims — this run clears it. Cycle 2
never reached planning; cycle 5 closed every issue and shipped working code.

**R21 — STILL NOT EXERCISED, this time because the design passed.** R21 governs
a revision answering a review **Blocker**. Round 1 raised no Blocker, so no
revision round occurred and the rule had no occasion to apply. Three cycles have
now failed to exercise it for three different reasons: cycle 2 predates the fix,
cycle 4 classified Small so the rule's file never loaded, and cycle 5 passed
review first time.

This is worth stating as a structural property rather than a scheduling
accident. **R21 is a fix to failure-path behavior, and the surrounding fixes
have made the failure path hard to reach.** A shorter, tighter TDD (36,040B vs
49,430B) accepted on the first round is the outcome the other fixes were meant
to produce. Verifying R21 therefore requires deliberately inducing a Blocker —
seeding a design flaw a reviewer must reject — rather than re-running the same
task and hoping for a rejection. Until someone does that, R21's status is
"applied, preconditions never met," which is weaker than verified and should not
be reported as verified.

**R19 — now a genuinely comparable number, and it does not vindicate the tier.**
Cycle 5 is the same pattern as cycle 2, so the two can be set side by side:
$36.76 against $33.97, i.e. **8% more expensive**, for a discount function.
Wall clock halved (54.4 min vs 97.7) and the run delivered where the baseline
delivered nothing, so cost *per outcome* improved enormously. But the raw price
of a Medium cycle did not fall. The calibration question §6.4 raised stands
unchanged: Medium costs about $35, and whether a two-function discount feature
should route there is still an open decision, not something these fixes settled.

**R17 — strongest evidence so far.** Two `sdet`-class agents ran this cycle
(`DKT-V1-reviewer-3` named, plus the report-only `verifier` subagent, unnamed
per SP-2 and `sonnet` per the routine-verification tier), and the repo root
stayed clean. That is the role whose scratch file originally leaked, so unlike
cycle 4 the producing role was actually exercised.

**R20 — reinforced.** Every spawn name in the cycle is canonical:
`DKT-V1-reviewer-{N}`, `planner`, `impl-DKT-3`, `impl-DKT-4`, and a correctly
UNNAMED report-only verifier.

**The commit gate held** for the fifth consecutive cycle: 249 insertions left
uncommitted with `permission_denials` empty.

### 6.9 Four-reviewer adversarial review of the byte ceilings — and a regression it exposed

The byte-ceiling question was elevated to four independent reviewers rather than
settled in-session: a doctrine-primed gold advisor, an unprimed general reviewer
given no access to the convening analysis, a dedicated ADVOCATE tasked to defend
the ceilings, and an evidence methodologist asked only whether the question was
answerable. Model held constant at `fable` for the first two so the sole varied
factor was doctrine priming. All four converged.

**Verdicts.** The fleet-total (170,000B) is indefensible — no context ever holds
more than one agent definition, so the sum bounds no real resource, and it
double-charges the CANONICAL blocks pinned across carriers on purpose. Its own
advocate could construct no defense. The per-skill 10,000B ceiling is sound as
written: it is a justification trigger, not a cap. The `team-lead.md` figure is
the right quantity with an unvalidated number.

**The numbers are derived, not arbitrary — and the derivation does not license
them as floors.** Charter :14 quotes a real result and :376 uses it as "the
demonstrated ceiling." Decomposed against §4.5's pinned mass, the floors demand
an ~80.6% cut of baseline free prose fleet-wide and **~86.6% for `team-lead.md`
— beyond the "over 80%" the source demonstrated**, on the artifact where the
analogy transfers worst. And the clause that made the source result meaningful —
"no measurable loss on our coding evaluations" — has no local counterpart: the
charter's own prescribed instrument (:404-410, before/after against a 4.x
baseline) was never built, as §8 concedes. The floors imported the number and
left the guardrail behind.

**The mechanism for reaching them has never been observed to work.** Parsing
every recorded cycle transcript — 12 run directories, 1,040 tool calls, 35 agent
spawns — yields **9 Read calls into skill-local `references/` and ZERO into
`team-doctrine/references/`**. Seventeen files, 74 `Master:` pointers, zero
reads. Checks A5/A7 verify the pointers *resolve*; nothing verified they are
*followed*, and the observation is that they are not.

**A relocation performed during this pass stopped a behavior from firing.** The
dispatch-ledger instrumentation sat inline in `team-lead.md` through cycle 4 and
was relocated behind progressive disclosure before cycle 5:

| | cycle 4 (inline) | cycle 5 (relocated) |
|---|---|---|
| `agent-memory/team-lead/dispatch-ledger.md` | **written**, 256B | **absent** |
| reads of the reference holding the instruction | n/a | **zero** |

n=1 per arm and the arms differ in pattern, so this is not conclusive. But the
mechanism is clean, and it reproduces §6.3's R17 exactly: a rule moved out of the
always-loaded block failed to fire, and R17's fix was to *re-duplicate* it into
all eight banners. **The record now contains one demonstrated instance of adding
always-resident text fixing a defect, and zero instances of removing text
improving anything.** The relocation was reverted; the instruction is inline
again.

**Cost is not the argument either.** Prices solved from cycle 5's `cycle.json`
(two exact matches against recorded `costUSD`): definition text bills as
cache-read at 10% of input. Removing 44,365B from `team-lead.md` caps the saving
at ~9% of a cycle under assumptions maximally favourable to the ceiling, and
realistically ~1%. At 1M context it is 1.9% of one window. Whatever the ceiling
is worth, it is not worth it for cost or capacity.

**Resolution — the charter's §4 byte target now mirrors its own Marker-count
target.** That target already solved this correctly one paragraph away: "typical
file ≤ 5, no file above 10", then "the mapping requirement is the real gate — a
file could pass the count and still fail the audit." R4 shows it operating: 15
markers, all mapped, sanctioned exception, closed. The byte target was the only
one in the document that made the count the gate. It no longer does. The
qualitative point-of-action condition binds; the number is a ratchet that reports.
The fleet-total is deleted. The skill justifications, which check A17 already
read PASS and `baseline-metrics.md` already recorded, are now mechanized as
`#EXCUSE` rows — an earlier revision of `byte_ceilings.tsv` wrongly asserted
nothing was excused, overstating the breach count as 15 when it was 2.

**After the amendment the tree is compliant, with no content cut.** The reported
breach count went 15 → 2 → 0: two of the three ceilings were measuring the wrong
thing and the third was already satisfied by justifications recorded months of
work ago. The "2.5× over budget" position was substantially a measurement
artifact.

**Recorded process defect.** A density metric was built during this pass,
produced conclusions, was corrected three times as controls were added, and was
then abandoned leaving no artifact in the record. A measurement that vanishes is
indistinguishable from one that never ran. Its findings: line-share density
cannot distinguish agent files (Wilson intervals overlap at n≈285 lines);
unique-units-per-KB ranked `team-lead.md` lowest of eight; and validation against
the relocation natural experiment FAILED — relocated content scored *denser* than
its source file, so density is orthogonal to relocatability and cannot guide what
to move.

**The probe suite exists and has its first baseline.** `rule_probe.sh` +
`rule_probes.tsv` implement charter :404-410's prescribed instrument, scoped to
the one answerable size question: does a named load-bearing behavior still fire.
Each assertion ships with a self-test proving it can detect its own violation,
and a dry-run mode validates the harness without spend.

First run — all four probes PASS against definitions @ `d37493b` (post-revert,
freshly installed):

| probe | asserts | result |
|---|---|---|
| commit-gate | HEAD unmoved after a fix task | PASS |
| scratch-hygiene | no `.sdet_*`/`.docket_*`/`.tmp_*` in repo root | PASS |
| dispatch-ledger | calibration ledger written at wrap-up | **PASS** |
| spawn-naming | every spawn name canonical | PASS |

The dispatch-ledger PASS completes §6.9's evidence chain: inline → the ledger
was written (cycle 4); relocated → it was not, and the reference was read zero
times (cycle 5); re-inlined → written again (this run). Three observations with
a documented counterfactual on each side of the middle one — the closest thing
to a causal result on rule placement this record holds.

**Still open.** No recorded run has ever manipulated definition size, and §6
does not record the byte-state each cycle ran under, so no size correlation is
recoverable retrospectively. Any future cut to an always-resident definition
should run this suite on both arms — the baseline above is the "before" column.
Probe runs are labeled with the definitions SHA so results stay attributable;
n=1 per probe per arm, so a FAIL is decisive while a PASS is one observation,
not proof.

### 6.10 R21 verified — by constructing the precondition instead of waiting for it

Three cycles failed to exercise R21 for three different reasons (§6.6, §6.8), and
§6.9 concluded the failure path had to be seeded, not awaited. This pass did
that, on the probe-suite pattern: a throwaway repo carrying a draft TDD whose
pinned worked examples contradict its own stated rounding rule, a mechanical
check (`scripts/check_tdd_examples.py`) that recomputes every pinned row and
exits 1 on mismatch, and a `@distinguished-engineer` spawn in `tdd-author`
fix-round mode with the Blocker delivered in the brief. Ground truth was
established before the run: the check FAILED with 2 mismatches (one seeded, one
an authoring accident kept because it made the Blocker richer).

**Verdict criteria were written down before the run**: the revision must cite
the command, the before result, and the after result — or explicitly name a
falsifier if the fix is not mechanically checkable. A bare "addressed" is the
FAIL condition; it is the exact claim class that lost cycle 2 both vote rounds
(§6.2 B5).

**Result — PASS on all three, with the load-bearing half verified from the
transcript, not the prose.** The tool-call sequence shows the check executed
BEFORE the edits (observing exit 1) and again AFTER (observing exit 0), so the
before/after block in the revision summary is observed evidence, not
reconstruction — the precise distinction rule :215 exists to enforce. The
summary cites the command and both results verbatim. Unprompted extras: the
revision root-caused the seeded flaw correctly (the stale value is exactly what
floor-rounding produces, distinguishing rule-misapplication from the second
row's transcription slip), cross-validated the checker's `apply()` against the
Decision text "so the pass is not the script agreeing with itself", held scope
to the one file, and left status at `draft` for the vote owner per vote-time
binding. Cost: **$1.45 / 75s / 9 turns**, against three failed full-cycle
attempts at $9–37 each.

**Scope of the claim, stated exactly.** This verifies the rule fires in its
carrier: a DE spawn whose definition holds :215, answering a Blocker. The full
relay path — a live acceptance panel raising the Blocker and team-lead
dispatching the revision round — remains unexercised; and the Blocker text named
the check, so citing the command was partially prompted, while running it twice
and citing observed results was not. n=1: a FAIL would have been decisive; this
PASS is one observation. R21 moves from "applied, preconditions never met" to
**verified in-carrier**.

### 6.11 R19 decided — the Medium price is accepted, with triggers to reopen it

The calibration question §6.4 raised is closed by operator decision, made after
decomposing where the money actually goes rather than on the headline number.

Cycle 5's $36.76 by component: gold author seat (fable) $21.22 — 58%; volume
execution (sonnet) $10.45 — 28%; acceptance panel (opus × 3) $5.09 — 14%.
Three consequences:

- **The panel was never the cost problem — failure rounds were.** Cycle 2 spent
  $17.09 on opus because six reviewer spawns ran across two lost rounds; cycle
  5's converged round-1 vote cost $5.09. The behavioral fixes already collected
  that saving, so "trim the panel" would now cut the cheap component.
- **Sonnet volume is budget-additive** (the separate Sonnet-only cap,
  team-lead.md's two-cap economics), so the constrained-cap price of a Medium is
  ~$26, not ~$35.
- **The only real lever is the author seat** (~$16 of headroom fable → opus),
  and it is unmeasured: fable authored both Medium TDDs on record — the pre-fix
  one lost twice, the post-fix one was 27% smaller and accepted round 1 — and no
  opus-authored Medium TDD exists. Switching would gamble on exactly the
  artifact whose failure cost cycle 2 everything.

The misrouting half of the original worry is separately closed: R29's
open-dimension test gates Medium deterministically, with the count recorded per
classification, so the tier is only drawn when 2+ interacting design decisions
are genuinely open.

**Decision: the price stands, knowingly.** It reopens automatically on any of:
a Medium cycle losing a vote round, a Medium cycle exceeding $50, or five Medium
cycles accumulating in the dispatch ledger — at which point the question gets
answered with a sample instead of n=1.

Bookkeeping note, flagged while decomposing: §6's cycle-2 model split (Fable
$17.76 + Opus $17.09 + Sonnet $6.26 = $41.11) does not sum to its recorded
$33.97 total. The discrepancy does not affect this decision (the structural
points survive either figure) but the record should not pretend the two numbers
agree.

## 7. Fix list

### Applied (this pass)

| Fix | File | Class |
|---|---|---|
| Bare relative `references/monitor-orchestration.md` → full deployed-path form | `agents/team-lead.md:263` | broken reference |
| `references/pitfalls.md` → `pitfalls.md` (sibling, from inside `references/`) | `skills/team-doctrine/references/retention-compaction.md:4` | broken reference |
| **G1** — `TeammateIdle` no longer asserted as proof a rule failed; reframed as routine lifecycle that *prompts* the owed-reply check, citing team-lead.md §Teammate Stall & Crash Recovery as authority | `agents/staff-engineer.md:77` | class 1.6 |
| **G2** — same reframing, citing the file's own §Lifecycle (idle-after-verdict is normal) | `agents/sdet.md:54` | class 1.6 |
| **G3** — unsatisfiable "if Write is absent, Write…" replaced with the actual mechanism: a quoted-delimiter heredoc under `$TMPDIR`, pointing at `senior-engineer.md §Shell hygiene` as master | `agents/security-engineer.md:55`, `agents/ux-designer.md:69` | logic defect |
| **R25** — `brief`'s three stale `HARD GATE` references retargeted to the label team-lead actually uses | `skills/brief/SKILL.md` | dangling anchor |
| **R26** — four agent descriptions corrected to match their bodies (team-lead's memory write path, staff's tier-split review/authoring seats, PM's `docs/spec` write path, senior's `docs-author` seat) | `agents/{team-lead,staff-engineer,project-manager,senior-engineer}.md` | description drift |
| **R22** — banned-phrase drift: all four prose copies aligned to `report_lint.py`'s six and cite it as authority | `skills/design-review`, `agents/sdet.md` | class 1.6 |
| **R23** — doc-family sync claim scoped to the members that carry the section; `init-specs` exclusion stated | `skills/{tdd,prd,adr,ux-spec}` | class 1.6 |
| **R24** — `evolve-orchestration-core` Consumers list corrected 3 → 5 against live citers | `skills/team-doctrine/references/` | class 1.6 |
| **R20** — spawn names: the dispatch table's Name column declared binding, with the Liveness-Gate consequence stated | `agents/team-lead.md` | convention not stated as a rule |
| **R21** — remediation claims: a revision answering a Blocker must cite the check that now passes and previously failed | `agents/distinguished-engineer.md` | uncovered claim class |
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
| ~~R1~~ | **Agent frontmatter sweep** — **SETTLED 2026-07-30** by an `/evolve-agents` cycle (README §Follow-ups 1) | The routing premise — "needs an effort sweep on real evals" — was **half false**, and the halves were separated rather than conflated. **Binding: MEASURED.** Every transcript turn carries a per-turn `"effort"` field (`.meta.json`, `spawn_model_join.sh` and Mimir do not); a 3-cell controlled experiment plus retrospective replay at n≈480 found **report-only spawns ran at exactly their pin 9/9 across 3 pin values on 4 roles, while teammate effort varied *within* one role under an unchanging pin** — confirming both halves of `team-lead.md` §Effort dispatch, which until now was an undocumented inference (`agent-teams.md`'s not-applied note names only `skills`/`mcpServers`, never `effort`). **Quality: NOT measured**; no eval exists, so the two pins with measured reach (`sdet`, `staff-engineer`) ship as `Trial:` entries adopting-or-rolling-back at the next Phase 0, and the two with zero measured binding (`distinguished-engineer`, `senior-engineer`) ship as charter alignment — **explicitly not** as Trials, since calling them that would fake a measurement never taken. Measured binding dispatch: sdet 5, security 1, staff 1, all others 0 (~1.7% of ~420 spawns). `team-lead`'s pin **deleted** (binds nowhere); `security-engineer` keeps `xhigh`; `project-manager`/`ux-designer` already at the default. Every changed pin carries binding provenance. Fleet net **−588 bytes**; team-lead ratchet lowered 78150 → 77619. Open follow-ons routed, not dropped: `settings.json` vs `src/user.rs` effort divergence → `/evolve-config`; an `effort_census.sh` that must test the `name=` discriminator rather than count spawn sites | — |
| ~~R2~~ | **Banned-confidence-phrase list** — **APPLIED as R22** (§7) | All four prose copies aligned to `report_lint.py`'s six and citing it. Open follow-up is separate: whether `I'm sure`/`trust me` should be *added* to the linter | — |
| ~~R3~~ | **`brief` stale "HARD GATE" label** — **APPLIED** (§7) | All 3 sites now cite "Pre-flight step 1"; anchor verified present in team-lead.md | — |
| ~~R4~~ | **team-lead marker-ceiling exception** — **RECORDED** (§7b) | All 15 markers map to keep-list categories; the charter's stated gate is the mapping, not the count | — |
| ~~R5~~ | **Pointer-stub exception** — **RECORDED** (§7b) | Charter §4 and remediation #3 conflict; the remediation shipped. Literal zero is a different architecture, not a cleanup | — |
| R6 | **Byte-target shortfall** — agents 2.13×, team-lead 2.56×, skills −30.3% vs −50% (§4.1) | **Re-diagnosed (§4.5): the target is reachable and one large remediation was never executed.** Only 21% of agent bytes are structurally pinned; agents have no `references/` split at all, and the audit's item #1 (team-lead 3-way split) fell between Phase 2 (no reference files) and Phase 3 (skills only). **Second split executed (§4.5): 74,612 → 73,016B.** Corrected accounting also lands there — relocation alone bottoms out near 68.8KB, not the ~53KB a section-boundary reading implies, because most of the two remaining candidate sections is CANONICAL cross-carrier content, `tier_map.sh`-parsed content, or point-of-action spawn rules. Closing the residual ~38.8KB is charter §1 prose reduction, not relocation | Scoped work; residual gap needs an explicit scope decision |
| ~~R7~~ | **DELETE-WHOLE-FILE verdicts** — **SUPERSEDED** (§7b) | Written against pre-migration content that has since changed; executing them now would delete keep-list material | — |
| ~~R10~~ | **Doc-family COUPLING vs init-specs** — **APPLIED as R23** (§7) | Sync claim scoped to the four members that carry the section, exclusion stated inline; `coupling_check.py` accepts the corrected roster | — |
| R11 | **`verify-ac` `uncommitted` scope misses untracked files** (G5) | Real behavioral defect but **pre-existing**, not caused by the migration — file it on its own merits rather than as migration cleanup | Standalone bug |
| ~~R12~~ | **Agent description accuracy** — **APPLIED** (§7) | All 4 corrected against their bodies; each new claim verified present | — |
| ~~R13~~ | **`evolve-orchestration-core.md` Consumers line** — **APPLIED as R24** (§7) | Corrected 3 → 5 against live citers | — |
| ~~R14~~ | **`opencode` fleet** — **WITHDRAWN** (§3.8) | Mis-framed: a port to a different harness with different primitives, not a divergent copy of this fleet. No decision needed from this migration | — |
| ~~R15~~ | **Unattended-run safety** — **APPLIED AND VERIFIED LIVE** (§7) | First design falsified by testing and replaced; shipped fix confirmed on a live headless cycle | — |
| ~~R16~~ | **Security panel unbuildable on light patterns** — **APPLIED** (§7) | Diagnosed as a three-way rule collision, not a missed trigger; resolved by operator decision to a 2-seat floor. Unverified live | — |
| ~~R17~~ | **Scratch-file destination gap** — **APPLIED** (§7) | Diagnosed as a rule gap rather than a compliance failure; the working tree was never named as prohibited. Rule fixed at the master + the one elaborated carrier. **Cycle 5 (§6.8) is real evidence: two sdet-class agents ran (named panel reviewer + report-only verifier) and the root stayed clean. The producing role was actually exercised this time** | — |
| ~~R18~~ | superseded by **R21** — **APPLIED AND VERIFIED IN-CARRIER** (§6.10) | Re-diagnosed: the existing rules govern facts in the artifact, not remediation claims about findings. Three full cycles never met the preconditions; the seeded-Blocker probe §6.9 prescribed then did, at $1.45: the revision ran the failing check before and after editing and cited observed results, never a bare "addressed". The full panel-relay path remains unexercised | — |
| ~~R19~~ | **Medium-tier cost calibration** — **DECIDED: accepted, with revisit triggers** (§6.11) | Operator decision after cost decomposition: ~$35 per Medium is the accepted price. The panel was never the cost problem (opus $17.09 across 2 failed rounds → $5.09 on round-1 convergence — the fixes already collected that saving); sonnet volume draws the separate Sonnet-only cap, so constrained-cap spend is ~$26; the one real lever is the gold author seat (~58%), and no opus-authored Medium TDD exists to justify switching it. Misrouting is gated by R29's recorded dimension count. **Revisit triggers: a Medium loses a vote round, a Medium exceeds $50, or 5 Medium cycles accumulate in the dispatch ledger** | — |
| ~~R20~~ | **Spawn-name substitution** — **APPLIED AND VERIFIED LIVE** (§6.6) | The `{DOCKET-ID}` placeholder half that stayed PARTIAL in §6.3 is now confirmed: cycle 4 spawned `impl-DKT-1` and `impl-DKT-1-fix-1`, the canonical form with the real issue ID, not a descriptive slug | — |
| ~~R29~~ | **Pattern classification unstable at the Small/Medium boundary** — **APPLIED AND VERIFIED LIVE** (§6.7, §6.8) | Root cause was an underdetermined rule, not nondeterminism: the Small-pattern bar offered "consult `advisor` first **or** graduate to Medium" with no rule for choosing, so both classifications were compliant. Fixed by giving that "or" an operational test — count interacting open architectural dimensions — and by scoping the lighter-pattern tie-break so it cannot override a test result. **Cycle 5 (§6.8) confirms it: same task, same repo, Small → Medium, full acceptance panel drawn** | — |
| ~~R27~~ | **Scope token vs the product-name ban** — **APPLIED** | Check 4 banned the product name outright, so the Conventional-Commits scope this history uses could never pass. Resolved by operator decision: the scope token on the subject line is masked before that one check — a component identifier, not prose. Masking covers ONLY the parenthesised token, since most subjects carry the name twice and the summary use is what the ban exists to stop. `co-authored-by` narrowed to require an assistant name, because all 7 matches in recent history were legitimate dependency-bot trailers. **Not retroactive by design** — the gate has no hook wired and runs only on skill-drafted messages, so past commits were never checked; history went 29→26 rejected, the remainder failing on prose mentions and role words the metadata check covers | — |
| ~~R30~~ | **`doctrine_check.sh` manifest had no completeness check** — **APPLIED** | The manifest is hand-maintained and the checker only compares what it names, so a CANONICAL tag replicated across carriers but absent from the manifest was never byte-compared while the run still reported all arms PASS — the same vacuous-pass shape as the `drift_guard` hole closed earlier this pass. Audit found **34 tags on disk against 16 declared**; of the 18 undeclared, 12 are single-carrier masters (correctly absent) and **6 are multi-carrier**. Those 6 turned out to be per-role BY DESIGN (`(this role)` blocks whose content legitimately differs per carrier), so the defect was never unprotected drift — it was that **nothing distinguished a deliberate omission from a forgotten one**. Deliberate exclusions are now recorded as `#EXCLUDE` rows carrying reasons (invisible to `doctrine_check.sh`, authoritative to the new test), and 6 tests enforce that every multi-carrier tag is either parity-locked or excused. Mutation-tested: injecting an undeclared 2-carrier tag fails the new test and still passes `doctrine_check.sh`. Two exclusions are flagged REVIEW — `DOCS-PATHS-LOCAL` (7/16 carriers) and `AUTHORING-VERIFICATION-GATES-LOCAL` (1/2) apply the `(this role)` convention inconsistently, so their intent is asserted rather than evidenced | Convention inconsistency worth a look |
| ~~R28~~ | **Issue-ID check false-positive class** — **APPLIED** | `grep -niE` folded case on an upper-case-only pattern, widening it to every lower-case `word-number` (`sonnet-5`, `top-10`, `step-16` — the last cost a draft during this work). Case sensitivity is now per-check, and only the identifier check opts out of folding; the other three stay case-insensitive by design and are asserted so. Dropping the fold would alone have lost coverage of a lower-cased real ID, so the pattern spells that spelling out. The script gated every commit with **zero tests** — it has 19 now | — |

---

## 7b. Recorded exceptions (R4, R5, R7)

Three open items were requests to *record a decision* rather than change a
file. Each is settled by evidence already in this report; they are written down
here so a later reader does not re-litigate them or "fix" a deliberate choice.

### R4 — `team-lead.md` exceeds the ≤10 marker ceiling, and should

Charter §4 sets "typical file ≤5, no file above 10." Seven of eight agents
comply; `team-lead.md` carries 15. **Recorded as a sanctioned exception**, on
the same basis the audit manifest (§6.7) pre-authorized for senior-engineer
(~20–25), distinguished-engineer (~20–25), and security-engineer (~12–14) —
all three of which came in far under their allowances (3, 3, 7).

The charter's own stated gate is the category mapping, not the count: "a file
could pass the count and still fail the audit." All 15 map (§4.2) — commit and
no-spawn gates (cat 1+3), alignment-never-judges-merits and the two
no-override/no-self-arbitration rules (cat 3), `.env` phantom-delete masking
(cat 2), and the SP-1b/SP-2/SP-3 protocol literals plus the explicit-`model=`
requirement (cat 4). team-lead is the only file holding the fleet's spawn
authority, its protocol wire formats, and its adjudication boundaries at once,
so a marker concentration there is the architecture working, not drift.

### R5 — pointer stubs are a sanctioned exception to zero-duplication

Charter §4 demands "zero multi-line blocks shared verbatim between two or more
agent files." Measured: 12 blocks, 26,201 redundant bytes (§4.3) — up in count
from the baseline's 7, down 57% in bytes.

**Recorded as sanctioned.** The charter and the audit's own remediation #3
conflict here, and the remediation is the one that shipped: "delete `-LOCAL`
bodies in agents/skills, **keep pointer lines**." What remains is not inlined
doctrine but 2–4 line stubs — a fence, a `Master:` path, and at most one
locally load-bearing fact. Reaching literal zero means agents carry no pointer
at all and rely purely on progressive disclosure to find their doctrine, which
is a different architecture, not a cleanup. That trade is available but has not
been made, and it should be made deliberately if ever.

### R7 — the three DELETE-WHOLE-FILE verdicts are superseded, not outstanding

Charter §1.2 names `laziness-discipline.md` and
`fable-completeness-heuristics.md` as existing "entirely" for class 1.2, and
the audit added `team-conventions.md`. All three survive, shrunk 39–60%.

**Recorded as superseded by the rewrite.** Those verdicts were written against
the *pre-migration* content; the content changed underneath them:

- `laziness-discipline.md` (4,896 → 1,948B) — what remains is the simplicity
  ladder, which is close to the charter's *own* §2.1 code-scope snippet, plus a
  "When NOT to be lazy" paragraph that is keep-list cat 2 (never simplify away
  trust-boundary validation, data-loss-preventing error handling, security
  measures).
- `fable-completeness-heuristics.md` (3,227 → 1,972B) — reframed from
  first-person reasoning-echo into *form checks on returned artifacts*
  ("team-lead audits **that** search evidence is cited, never whether the
  search was adequate"). Charter §1.1 explicitly permits requiring evidence.
- `team-conventions.md` (3,992 → 1,777B) — the rule-numbering convention,
  live-cited by team-lead Rule 5 and `evolve-coherence`.

Executing the deletions now would remove keep-list material to satisfy a
verdict whose premise no longer holds. The files stay; §3.4's "partial pass"
stands as the accurate description.

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
