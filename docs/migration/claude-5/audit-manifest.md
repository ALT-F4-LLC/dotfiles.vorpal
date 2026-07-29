# Claude 5 Migration — Audit Manifest (2026-07-29)

Report-only audit of all 8 agent definitions and all 17 skills under
`src/user/claude-code/` against the charter at
`src/user/claude-code/docs/context-engineering-claude-5.md`. No definition file
was changed. Produced by 14 parallel per-file/per-group auditors briefed with
the charter, plus one evidence miner over 93 session transcripts (542MB,
Jul 15–29) and 12 agent-memory files (1.28MB). Baseline numbers in
`baseline-metrics.md` (same directory).

Violation classes cited throughout: **1.1** reasoning-echo, **1.2** 4.x
workarounds, **1.3** enumerated MUST/NEVER/ALWAYS, **1.4** self-verification
scaffolding, **1.5** cross-file duplication, **1.6** conflicting guidance,
**1.7** monolithic context. Keep-list categories: **cat 1** irreversible/
destructive, **cat 2** security boundary, **cat 3** authority contract,
**cat 4** machine-parsed format.

---

## 1. Cross-file duplication map

### 1a. Agent-file canonical blocks (mechanically verified)

The tree self-labels its duplication with `<!-- CANONICAL:<NAME>-LOCAL -->`
fences; masters live in `team-doctrine/references/`. Every copy **both inlines
the content and cites the master** — charter §1.5's named worst case. Byte
detail in `baseline-metrics.md`; ~61KB redundant across agents alone.

| Block | Copies | Where | Notes |
|---|---|---|---|
| Commit + no-spawn CRITICAL banner | 8/8 agents | preamble L19–25 in each | **8 different wordings** of one rule — already 1.6; team-lead L22 vs `> **CRITICAL:**` in the other 7 |
| tmp-write guard (`/tmp` → `$TMPDIR`) | 8/8 (+2× inside sdet, 3× inside distinguished-engineer) | inside the banner | hook-enforced; keep once per file at most |
| SHUTDOWN-PROTOCOL-LOCAL | 8/8 | e.g. staff L297, senior L385 | team-lead's full copy (3.9KB) is the defensible single home — it operates the handshake |
| DOCKET-CLI-LOCAL | 8/8 | e.g. pm L317, sdet L370 | each says "Invoke Skill(docket) for the full reference" then restates flags |
| DOCTRINE-SCRIPT-TRUST-LOCAL | 8/8 | byte-identical ×7 (md5 19b938f4) | master is nested inside runtime-discipline R6, which is slated for deletion — **needs a new home** |
| PITFALLS-LOCAL | 7 (all but team-lead) | byte-identical (md5 9334f54d), 1.78KB each | the ONLY block registered in `scripts/doctrine_check_manifest.tsv` (parity-enforced) — editing it is a coordinated 7-carrier + manifest change |
| TRUTH-FIRST-DEBUGGING-LOCAL | 7 | role-tailored variants | banner sentence identical |
| DOCS-PATHS-LOCAL | 7 agents + 9–10 skill SKILL.mds | widest fan-out in the fleet (~16–17 carriers) | highest-value single dedup |
| VORPAL-TOOLS-LOCAL | 7 | byte-identical (md5 bf3deac1) | team-lead carries pointer-only — **the model the others should follow** |
| DEEP-COLLABORATION-LOCAL | 6 | | master is 912B; 38% of it provenance header |
| SANDBOX-RECOVERY-LOCAL | 6 | ux copy byte-identical to sdet (md5 8dd09976) | |
| AUTHORING-VERIFICATION-GATES-LOCAL | 2 (staff, distinguished) | 1.4–1.9KB each | |
| LAZINESS-DISCIPLINE-LOCAL | 2 (sdet, senior) | | master is a charter-named whole-file deletion |

**Unfenced but equally fleet-wide** (no marker, so free to drift): tool-envelope
check (7–8 files, ~1.1–1.9KB each); Epistemic Discipline w/ banned-phrase list
(8, all citing team-lead Rule 6); stale-dispatch check (7–8, citing
senior-engineer's master); read-before-edit citations (8); Runtime Discipline
R1–R7 reminder digests (8; R4 byte-identical in 6, R6 byte-identical in 6);
vote_delegate.sh protocol (8); TeammateIdle stall paragraph (5); saturation
self-monitor (3: pm, staff, ux); `DONE — awaiting shutdown_request` literal
(4, self-documenting its adopters); Monitor choreography (4: sdet, senior,
staff, security).

### 1b. Skill-family blocks

| Block | Carriers | Notes |
|---|---|---|
| `CANONICAL:BANNER` (commit gate + leaf-skill clause) | 14 skill SKILL.mds | byte-identical through "…or form/manage a team"; clause (1) guards nothing in skills with no write path (design-qa, design-review, simplify-scout, brief, session-metrics) and is load-bearing only in init-specs/commit — make it conditional on write path |
| `CANONICAL:DOCS-PATHS-LOCAL` | 9–10 skills + 7 agents | see 1a |
| `## Doubling Rule` | code-review-verdict:88, verify-ac:77, design-qa:70, design-review:74 | each says "owned by team-lead.md Rule 8 … do not restate" then restates |
| Silent-completion self-check | crv:405, verify-ac:253, design-qa:214, design-review:253 | COUPLING-synced 1.1+1.4 violation — dies in all four |
| Lint-staging / mktemp / stdin-form paragraphs | verify-ac:221, design-qa:187-200, design-review:220-233, simplify-scout:246-260, crv:373, docket:296 | ~2.5KB near-verbatim; design-review copy has **already drifted** (+1 clause) |
| Banned-confidence-phrase list | design-qa:140 (6 phrases) vs design-review:153 (4 phrases) vs verify-ac:158 vs sdet.md:59 vs team-lead Rule 6 vs `report_lint.py:61` | **realized drift under a shared linter**; the executable copy is the only one that enforces anything — single-home in the linter |
| Scope-resolution table | verify-ac:57-60 ↔ code-review-verdict:61-64 | byte-identical per its own COUPLING comment |
| design-qa ↔ design-review sibling set | **14 verbatim blocks** (~5.3KB) | banner, docs-paths, role line, arg handling, scope resolution, Doubling Rule, COUPLING comment (927B identical), pre-flight steps, error strings, a11y checklist, self-check, lint paragraphs |
| Doc-authoring family (tdd/prd/ux-spec/adr) | **10 blocks ×3–4 copies ≈ 32KB, ~24KB recoverable** | BANNER 406B×4; ARGUMENT_HANDLING 982B×4; COLLISION_DIALOG 1,279B×3; SAVE_AND_RETURN ~900B×4; When-NOT-to-Use + COUPLING ~5.4KB; **Validation steps 1-3: 1,666–1,673B ×4, byte-identical modulo `--type`, UNFENCED — the most urgent (no marker = silent drift)** |
| evolve-phase0-templates internal | 6 scaffolding blocks ×3–9 copies within one 60KB file | no-subagents line ×9, $TMPDIR ¶ ×8, Mimir block ×5, operator-correction regex ×5, de-dupe rule ×5, quantified-claim ×3 — the `{HARVEST_BLOCK}` token mechanism already in the file is the fix, never applied to the other six |

### 1c. Agent ↔ skill doctrine restatements (single-home targets)

| Doctrine | Homes today | Proposed single home |
|---|---|---|
| Severity ladders (general + security) | code-review-verdict:142-150/166-174 ↔ staff-engineer:203-208 ↔ security-engineer:165 (+ structural mirrors in design-*) | **the skill** (validator parses it); agents cite |
| Six review dimensions | crv:133 ↔ staff:197; **conflicting second "6 dimensions"** in review-and-comment:55 (non-comparable list) | crv; review-and-comment cites or names its subset explicitly |
| No-self-filter / full-coverage rule | crv:179 ↔ staff:201 ↔ vote:265 ↔ design-qa:143 ↔ design-review:156 | one statement per consumer family; **protect during rewrite — charter counter-current** |
| 12 code-philosophy principles | senior-engineer:240-269 (master) ↔ simplify-scout:96-118 (inlined 1,985B) ↔ staff:179 ↔ DE deep-impl adoption | extract to `references/code-philosophy.md` with **stable numbering declared as a machine contract** — see §6.2 |
| SendMessage `summary` required | shutdown-protocol.md:43-45 ↔ runtime-discipline.md:80-83 (mutually cross-referencing) ↔ ~8 agent files ↔ team-lead ×3 internally | shutdown-protocol.md |
| Shutdown protocol | shutdown-protocol.md (master) ↔ 8 agents ↔ **competing home** evolve-orchestration-core §Shutdown (name collision, documented drift) ↔ vote:87/301/385 ↔ init-specs:164/174 | shutdown-protocol.md; rename the evolve section |
| Security-sensitive surface roster | team-lead:97 ↔ brief:35 (verbatim) ↔ review-and-comment:57 | team-lead |
| Vote panel sizing / composition | team-lead Rule 8 + step 6 ↔ vote:70-120 ("mirrored from") ↔ 4 skills' Doubling Rules | team-lead |
| Docket CLI flag lore (`-m`/`add`, `-f` semantics) | docket SKILL.md (×4 internally!) ↔ all 8 agents ↔ several skills | docket skill, once |
| Commit gate | senior-engineer:19 (quoted by commit:76, brief:14, all banners) ↔ commit skill ↔ team-lead:22 | keep absolute in every file that holds a write path (cat 1/3 — sanctioned repetition candidate), but ONE wording |
| Frontmatter doc-family convention (status/maturity) | prd:163 ↔ ux-spec:180 ↔ tdd:242 (three different slices) | validator schema or docs-paths master |
| team-doctrine master table | SKILL.md "Cited by" column ↔ 14 files' own LOCAL-copy headers | the files' headers die with the copies; table keeps nav columns only |

### 1d. Sequencing hazards (order-of-operations constraints)

1. **Rename-numbers-to-names first.** Doctrine is addressed by ≥7 numbering
   schemes (R1–R7, SP-1..4, TFD-1..5, E0–E4, team-lead Rules 2/6/7/9/10/11,
   `L111`, §3a/6a…). Three files forbid renumbering. The marker-reduction pass
   renumbers or deletes most of them — convert numeric citations to named
   anchors **before** content edits, or every cross-file pointer breaks at once.
2. **12-principles extraction lands before or with the senior-engineer.md
   rewrite** — otherwise simplify-scout's validator-enforced `1–12` citation
   contract dangles silently against a dissolved rubric (findings lint clean
   citing a deleted list).
3. **Severity ladders single-home in code-review-verdict before the
   staff/security agent trims** — trimming agents first risks deleting the
   surviving copy of a validator-parsed contract.
4. **DKT-250 re-litigation is a prerequisite** for the report-emission family:
   `code-review-verdict:57/:100` COUPLING comments record that extraction was
   *rejected* and mandate byte-identical sync across 4 skills. Every per-file
   remediation terminates at that instruction until the decision is reversed.
5. **PITFALLS-LOCAL is parity-locked** in `doctrine_check_manifest.tsv` — its
   replacement (charter §2.1 memory snippet) is a coordinated 7-carrier +
   manifest edit, not seven independent ones.
6. **Script-trust rule needs a new home** before runtime-discipline R6 is
   deleted (it is currently nested inside R6).

---

## 2. Evidence-backed rulings (transcripts + agent memory)

From the evidence miner (93 transcripts Jul 15–29; firing proxy =
thinking-block occurrences, since raw grep measures injection). Full caveats in
the source report; headline: thinking undercounts firing, so low counts are
suggestive, not proof.

**Rules that demonstrably fire — keep through the migration:**
- **Shutdown protocol / `teammate_terminated`-only-proof**: 1,657 payloads
  across 39/82 work sessions. The actual coordination substrate.
- **Liveness-Confirmation Gate (SP-3)**: born from a documented triple-Fable-
  spend incident (`team-lead/pitfalls.md:72`); corpus shows `-2`/`-3` names are
  now overwhelmingly intentional panel seats, not blind respawns. Holding.
- **Pitfalls ledger + dedup**: highest-firing topic (179 thinking-hits/28
  sessions); zero genuine duplicates across 301 entries. Works — but see
  compaction below.
- **Harvest provenance lines** ("Applied to …"): 115 lessons; the only
  machine-readable incident→rule link. Retain the convention.
- **Pre-shutdown state-verification**: caught a real deviation behind a clean
  completion report (`team-lead/pitfalls.md:302`) — supports keeping a one-line
  form even though the 4-step gate is 1.4.
- **Sandbox-recovery discriminator**: 281 hits/32 transcripts; fires in every
  test-running review.
- **Commit gate**: low frequency, observably held (agents self-restrained).
- **Promised-gate delivery check** (gate_check.sh): concrete, meets its own
  content gate.

**Rules that measurably thrash — deletion/replacement evidence:**
- **Anti-idle invariant + session-stop hook: the dominant thrash source.**
  1,029 "Session stop blocked" events across 50 sessions (169 in one). Agents
  manufactured actions purely to satisfy the hook, including interrupting the
  operator. Supports team-lead L314's replacement with the §2.1 autonomy
  snippet + one armed-wait line — **and a hook-behavior review, which is out of
  this audit's file scope but is the single highest-leverage fix available.**
- **Monitor choreography**: 730 thinking-hits → only 109 Monitor arms (~7:1
  deliberation-to-use); documented round-trips to nowhere; wrong-signal
  monitors fire non-informative lines indefinitely. Supports shrinking
  monitor-orchestration.md to the one discriminator sentence + script pointers.
- **Read-before-edit**: only **9 real** `is_error` rejections across 93
  transcripts (median recovery 2 calls, 96.6% self-heal, zero corruption), and
  `distinguished-engineer/pitfalls.md:196` records that the doctrine's
  laziness-blame misdiagnoses ~2/3 of the class (root cause: the harness gate
  doesn't survive resume/idle-wake). Supports collapsing senior-engineer L40's
  4,173B block to ~3 sentences. One counter-case (six consecutive unrecovered
  rejections in `d27533aa`) supports keeping the one-line recovery rule.
- **Laziness-discipline**: 3 thinking-hits in 2/82 sessions against a per-turn
  injection cost — near-zero yield, wrong causal premise. Supports the
  charter's DELETE-WHOLE-FILE.
- **Anti-Defensive-Exploration**: 1 thinking-hit corpus-wide; every other hit
  is mirror bookkeeping. Deletion evidence for R6 and its 8 copies.
- **Read-only/report-only as brief prose**: measured ineffective twice (23%
  self-apply rate after a mitigation attempt); transcript recommends stripping
  Edit/Write from the spawn envelope instead. **Mechanism over prose** — this
  generalizes to several keep-list boundaries: where the harness can enforce
  (disallowed-tools, hooks), the prose shrinks to one line.
- **Retention/compaction**: fires but does not bound growth (ledgers at
  1.28MB; dedup performed blind against the last ~50 lines). The §2.1 memory
  snippet replacement is safe; the growth problem is real but separate.
- **Structured plan_approval_response**: four ledger entries converge on
  "don't use it" (silent delivery failure). Supports the protocol notes staying
  exactly as pinned strings (cat 4) and nothing more.
- **No-signal topics** (zero harvested lessons ever): completeness heuristics,
  SendMessage-contract prose (the schema rule fires as *tool errors*, not
  doctrine), context budget, prefill, budget_tokens. Dead-mechanism sweep of
  the tree itself is clean (no prefill/budget_tokens anywhere).

---

## 3. Per-file findings — agents

Format: headline; violations by class (line refs); keep-list note; target.
All eight fail charter §4 marker targets today; six of eight pin
`effort: xhigh` reflexively.

### 3.1 team-lead.md — 137,218B / 530 lines / 42 markers → cap 30KB
- **Frontmatter**: `model: sonnet` conflicts with §3 (orchestration = Fable
  profile); the file's own L240-242 defends sonnet on cost — ratify explicitly
  or re-pin; the sonnet pin and the 42-marker enumeration style are causally
  linked. `effort: xhigh` is **documented inert** at L244 — delete pin and the
  paragraph explaining its inertness.
- **1.1**: mostly clean. L206 (never request reasoning echoes — trips
  distillation classifier) is the charter's own gate: KEEP, promote to an
  unconditional brief rule. L482 epistemic-provenance annotation → replace with
  §2.1 grounded-claims snippet. L52 per-turn self-audit → delete.
- **1.2**: L517 R6 banned phrases + L516 R4 (charter's named examples) —
  delete. L482 banned-phrase lists ×2 — delete. L314 anti-idle invariant
  (~1.1KB forced turn-shape; operator-pain provenance real) → §2.1 autonomy
  snippet + one armed-wait line. L60 anti-deliberation, L109 vocabulary
  discipline, L409 label discipline, L368 40-turn trigger — delete. L430-434
  dispatch ledger for an un-happened recalibration — move/delete pending
  consumption evidence. L242 MORE-models nudge — model-conditional (§2.1
  delegation snippets).
- **1.3**: all 42 markers mapped in the audit; ~24 keep (heavy cat 3
  concentration: L22 gates, L124/L126 alignment-never-judges-merits, L226,
  L286 recusal, L297, L303, L327, L352/L353 (sharpest), L366, L237 routing
  floor, liveness NEVERs consolidated to SP-3); ~18 convert/delete (incl. 3
  internal duplicates: L344=L342, L446=L204, summary rule ×3).
- **1.4**: L80 goal gate KEEP (external human gate; drop HARD GATE label +
  re-ask loop). L120-128 Alignment Verification (self-admits "mints no new
  authority") — delete half. L299-301 completion pre-check with a carve-out for
  its own false positives → 1 line. L323-336 step-13 spot-check (9.5KB, largest
  block) — keep authority core + phantom-deletion note; move sampling
  mechanics. L401-405 pre-shutdown gate → L404's one sentence (evidence
  supports the one-liner). L413-417 four stall ladders (~4.5KB) → principle +
  reference. L427 wrap-up dup — delete. L428 gate_check.sh — KEEP (real
  parser). L500 Rule 11 → keep reactive triage only.
- **1.6**: L54 vs L440 write-permission framings; L128/L480/L126 token-cap
  adjudication paragraph (delete cap + adjudication); L189/L380/L484 verifier
  sizing ×3 → Rule 8; L391(a)(iii) supersession narration → state current fact.
- **1.7**: Execution Workflow L272-458 = 65KB (47.6%) incl. harness-version
  archaeology and incident post-mortems → split to
  `references/stall-recovery.md`, `shutdown-lifecycle.md`,
  `review-reconciliation.md` (~57KB out, ~8KB inline). Change-ID legend +
  tags — delete (2KB). Keep the Per-Role Dispatch Table (densest info/byte)
  and tier→alias map (genuinely single-homed here).
- **Keep-list highlights**: commit gate; security-flag surface roster (L97 —
  scope definition, not tuning); L235-239 security-pins-silver (Fable
  classifier + ZDR, charter-derived); L477 hub-and-spoke + relayed-authority
  (cat 2 anti-injection, verbatim); SP-1/2/3 message schemas; GO/COLLABORATIVE/
  DEGRADED literals; `frozen:<sha12>`/`+dirty:`; brief 5-field schema.
- **Target**: ~30KB only if the 1.2/1.4 deletions land — they are not optional
  trimming; they close the last few KB.

### 3.2 senior-engineer.md — 78,897B / 429 lines / 77 imperative markers
- **Frontmatter**: `effort: xhigh` on sonnet ≈ two rungs over (§3 calibration)
  → `high` + sweep. **Model-conditional hazard**: L93 gold-arm (Fable/DE)
  adopts this Sonnet-tuned execution contract *verbatim* — scope the adoption
  to Docket mechanics + close-then-verify; exclude self-review substeps.
- **1.2**: L29 anti-overthink ¶ (on Sonnet literalism it suppresses legitimate
  edge-case analysis) — delete. L423 R6 / L422 R4 — delete (R4 directly
  contradicts L57/L170 AC gates). L52 10-min progress timer, L55 saturation
  monitor, L419/L424 tool tutoring — delete. L425 shell hygiene → keep $TMPDIR
  gate, move zsh trivia. Emphasis inflation throughout (CRITICAL/MANDATORY/
  HARD GATE/BINDING ×~20) — strip.
- **1.3**: L34 CODE-COMMENTS (2,395B — the charter's own worked example at 9×
  its "after") + L258 principle-7 duplicate = 4KB stated twice → one home;
  keep machine-directives allowlist + OVERRIDE gate. L40 READ-BEFORE-EDIT
  (4,173B, largest line) → 3 sentences (evidence: 9 real rejections/93
  transcripts; doctrine misdiagnoses ~2/3). L164 seven sub-gates (2,655B) →
  keep premise-check + AC-vs-prose precedence, move rest. L178-219 trigger
  list (28 rows) → principle + 3 security/authority rows.
- **1.4**: keep the external gates (self_review_scan.sh, ac_check.sh --pre and
  post, go_verify.sh, docket_close.sh JSON verify, pipefail/PIPESTATUS,
  falsify-regression-guard); delete self-critique framing, TFD 4-checkbox gate
  (keep 2-sentence banner), generic verify-your-work lines. simplify-scout
  optional pass = model-conditional (drop on Opus/gold path).
- **1.6**: R4 vs L170; R6/R7 vs L40 forcing rule (R7 self-arbitrates — the
  tell); L29 vs L266; L19 vs L379 vote-mode; "silence" bullets with opposite
  valence (L46/L53).
- **Keep-list**: the densest of any agent (~35 rows) — commit/stash/git-add
  sibling gates (cat 1: destroys peers' work), Skill(commit) caller gate,
  commit_msg_check.sh, close-then-verify (cat 4/1), Override format string
  (grep-consumed), parse-don't-validate, never-delete-test-to-green,
  same-turn shutdown ordering, SP-1 grounds, machine-directive comments.
- **12 principles (L240-269, 11.7KB)**: externally depended on BY NUMBER
  (simplify-scout:5-6,98,100) — keep all 12 numbered; trim elaborations;
  extract to a shared references/ home (see §6.2).
- **Target**: 20–25KB; markers land ~20-25 = **flag as negotiated exception**
  (only agent with Edit/Write + commit prohibition + shared-tree rules);
  charter's real gate is the category mapping, which holds.

### 3.3 staff-engineer.md — 67,580B / 326 lines / 16 strict markers
- **Frontmatter**: opus CORRECT (review seat; §1.4 strip applies at full
  strength). `effort: xhigh` → `high`, raise at dispatch for tdd-author spawns.
- **1.1**: L320 R5 self-summary + await-ack (clearest reasoning_extraction
  shape) — delete. L84 "reasoning + alternative" → alternative only. L224
  "Alternatives Considered" as mandated advisory section → principle.
- **1.4 (dominant, ~18KB)**: verification rule stated 3× (L67/L160/L210) → one
  §2.1 grounded-claims statement. No-Guessing section L88-129 (9.2KB) → ~1.2KB
  (keep L108 never-loosen-a-check (cat 1) + L90 "silence beats an unverified
  claim"; scripts become available-not-mandated; L212/L230/L246 war-story
  recipe clusters (~5.2KB) → references). L187 moving-tree gate → keep
  GO-authority + `+dirty:` + partial-read escape; cut re-run choreography.
  L306 PITFALLS (parity-locked) → §2.1 memory snippet via coordinated edit.
- **1.3**: keeps incl. L26 never-writes-code, L62/L63/L68 protocol, L70
  hub-and-spoke, L167 recusal, L284 vote-before-TDD-approval, L306 append-only.
  L151 10-item TDD decision table → principle + irreversible-decision trigger.
  **L201 full-coverage/filter-downstream line: KEEP VERBATIM (charter
  counter-current; a naive trim here regresses recall).**
- **1.6**: L66 vs R7 (hand-written reconciliation clause = the tell); L84/L179
  reject-class vs L201/L214 better-not-perfect → state the Google bar once;
  L104 vs L308 two memory lists; advisor-seat authority split across two files
  (flagged as a 1.6 generator by construction).
- **GAP**: no anti-injection block despite dontAsk + WebFetch/WebSearch +
  docket content — **keep-list ADDITION** (§2 cat 2 canonical snippet).
- **Target**: 16–18KB; strict markers → ~10, all mapped.

### 3.4 sdet.md — 61,892B / 389 lines / 10 strict (78 effective) markers
- **Frontmatter**: opus correct; `effort: xhigh` → high/medium (review-holds-
  at-lower-effort is §3's own note); conflicts with L32 anti-overthink.
- **1.2 (largest class)**: L32 banned-deliberation ¶, L34 forced narration,
  L36 comment rules (≈ charter's own example), L38 compaction, L40 (2.1KB)
  mode-introspection, L42 (1.6KB) tool-envelope, L46, L52, L57 10-min cadence,
  L255 "when in doubt go FULL" (over-verification bias on Opus), L383-385
  R4/R6/R7 — delete/move per audit.
- **1.4**: keep the 11 genuine external gates (red_green_verify.sh,
  flaky_confirm.sh, REAL_EXIT capture, sandbox rerun-before-BLOCK,
  phase_diff.sh, regression_diff.sh, consumer-command-path, ground-truth
  cross-check, fixture_shape_check.sh, copy_verify.sh, ≤5-probe edge pass);
  delete the Pre-Flight HARD GATE, sister-coordination, read-ENTIRE-issue
  framing, Skill(verify-ac) ×4 → ×1.
- **1.5 intra-file**: mode-split "single authority" (L40) restated at 8 other
  sites — the self-declared invariant already violated.
- **Keep-list**: L186 never-git-stash (destroys peer work — strongest single
  keep), L282/L288 read-only workflow state, L219 canonical spawn names,
  L259 verify-ac format-authority pointer (correct single-home pattern),
  DONE/DEGRADED/distillation-gap literals, L280 severity ladder, L343
  --threshold silent-default trap.
- **Target**: 12–15KB, ~10 markers mapped.

### 3.5 distinguished-engineer.md — 56,691B / 305 lines / 74 marker-occurrences
- **Frontmatter**: `model: fable` **correctly derived** (unique in fleet);
  `effort: xhigh` reflexive → high or mode-conditional. Gap: dontAsk +
  Edit/Write/Bash means the code-only-in-deep-impl invariant is prose-enforced
  only.
- **1.1**: prohibits echo rather than requesting it (L96 KEEP — Fable
  classifier boundary with mechanism stated); L299 R5 self-summary — delete;
  L200 "pairs reasoning with" → "names a concrete alternative".
- **1.2**: R1/R3-R7 delete (R2 cost fact survives as the only R); L223
  saturation; L31 compaction; L62 envelope (keep 2 facts); L204 no-overthink →
  scope snippet.
- **1.4**: ~20 stacked constructs. KEEP: L134 falsification pass (real
  WebFetch-fabrication provenance, compressed), L158 moving-tree gate
  (tree_fingerprint.sh external), L228 post-error retry gate (query external
  system first), ref_census.sh closed arithmetic. Move mode-gate blocks with
  their modes; delete stale-resume 3-probe, peer-name reverify ceremony,
  label-reverification.
- **1.7 (structural)**: four mutually exclusive modes fully specified, one
  binds per spawn — Modes 1-4 = 18.5KB (33%), ≥75% inert per spawn →
  `references/mode-{tdd-author,advisor,investigator,deep-impl}.md` keyed on
  the brief's `Mode:`. Cleanest progressive-disclosure win in the fleet.
- **Keep-list**: Security Exclusion L100-106 IN FULL (cat 2, charter-required);
  all six NOT-@role bullets; L112 tier-split authority; recusal (one home);
  L221/L222 routing + relay authority; L287 DONE literal; vote wire form;
  L260 vote no-cancel-verb (cat 1).
- **Target**: 8–12KB; markers ~20-25 — defensible overage on an
  authority-dense seat; flag to migration owner.

### 3.6 security-engineer.md — 56,068B / 291 lines / 18 uppercase markers
- **Frontmatter**: `model: opus` CORRECT AND LOAD-BEARING (§3 routes security
  off Fable) — **annotate as deliberate** so a fleet promote-to-Fable pass
  can't flip it. `effort: xhigh` → high (advisor) / medium (ephemeral
  reviewers) as spawn-time param. Missing Opus conciseness prompt.
- **1.2**: Runtime R-block (2.4KB) — R4/R5/R6/R7/R1 delete; L85 anti-rumination
  (conflicts with the effort pin) — delete; L235 "sign-off-disqualifying"
  enforcement language with no mechanism — delete; L273 pitfalls choreography →
  memory snippet. Dead-mechanism sweep clean.
- **1.4** (full Opus strength): Pre-Flight Q1-Q4 scaffold → one principle
  ("establish adversary, asset, residual risk"); keep gate_check.sh (exit-code
  external gate); delete RE-CHECK-standing-findings; keep the fail-open insight
  (SIMPLIFY removing a fail-closed trigger on an INFERRED property).
- **1.3**: L164 cargo-audit-findings-still-reported-at-Info — KEEP
  (counter-current, protect); L69-79 No-Guessing 7 bullets (9.7KB section) →
  one verify-against-live-source principle + recipes to
  `references/security-verification.md`.
- **1.6**: L225's deliberate, correctly-flagged override of the SendMessage
  tool default — KEEP AS-IS (the model of how to resolve a conflict).
- **Keep-list (legitimate cat-2 concentration)**: .env handling + phantom-
  deletion guard; OPENED/FAILED/INDETERMINATE 3-bucket; "unverified" escape
  string; exit-2 hook-bypass finding (relocate); suppression-directive-next-to-
  JWT rule; L103 silver-never-gold; sole-editor + baton-ack exact wording;
  recusal; L254 three vote thresholds; L187 ADR supersession append-at-EOF.
- **Consolidation**: 5 routing contracts (L55/L154/L177/L225/L242) = one
  principle "all verdicts route through team-lead" → 1-2 markers.
- **Target**: 12–16KB; 12-14 markers, all mapped (defensible for the role).

### 3.7 project-manager.md — 48,476B / 370 lines / 11 uppercase (~64 lines imperative)
- **Frontmatter**: `model: sonnet` mismatched to its own Complex tier
  ("ambiguous requirements" = Fable profile) — split by tier at spawn or
  re-pin; `effort: high` + L37 anti-overthink = frontmatter-vs-body
  contradiction → medium + delete L37. Sonnet literalism: collapsed principles
  must stay explicitly scoped.
- **1.2**: L57 tool-envelope (1.9KB, densest violation) → 3 harness facts;
  L66 ack cadence, L47 doubling-rule negation, L147 iteration cap, L361-366
  R-rules — delete.
- **1.4**: KEEP plan_collision_check.py + dor_check.py (external gates, exit
  codes); delete the DoR prose checklist, self-review pass, count-never-eyeball
  ritual (script already asserts); keep Docket-distrust rules (tool empirically
  lies — DKT-194), merged to one statement. L96 goal HARD GATE unsatisfiable in
  team mode (AskUserQuestion stripped) — keep standalone confirm only.
- **1.6**: L268 verify-before-attach vs L369 script-trust (L361 exists to
  arbitrate — the tell); spike-routing stated two ways; PRD boundary ×3.
- **Keep-list**: L338 nothing-outside-docs/spec (strongest); L8 never writes
  code; issue template (cat 4); Fn→issue-ID mapping table; -d/-f semantics;
  phantom -f breaks collision detection; L307 append-only; L137 TDD
  accepted-status gate; L331 reserved spec names.
- **Target**: 11–13KB, ~8 markers.

### 3.8 ux-designer.md — 46,903B / 322 lines / 11 uppercase markers
- **Frontmatter**: `model: opus` contradicted by the body — L287 binds the
  spec-authoring seat gold→Fable; the file averages the §3 divergences instead
  of making them model-conditional. Its 1.1 findings are therefore live
  reasoning_extraction risk (and contradict team-lead:206).
- **1.1**: L188 restate-in-your-own-words (also contradicts L61's own ban),
  L316 R5 structured-outline self-summary — delete; L210 "mentally trace" →
  coverage requirement; L191 self-validate → keep the 2 tool-grounded checks.
- **1.2**: L61 anti-overthink ¶, R4/R6/R7, L109 saturation, L313 skill
  pre-load ban, L76 retry pressure — delete.
- **1.4**: Pre-Flight gate is a no-op in team mode by its own admission —
  delete; keep L254 sandbox verdict-gate (external re-observation) and L302
  verification-incomplete shutdown rejection.
- **1.6**: requires-and-bans restatement (L188 vs L61); three layers on
  re-reading; model identity unresolved.
- **Keep-list**: L29 never-writes-impl-code; L242 render-before-Pass (de-shout;
  evidence contract); L232 reviewer independence + DEGRADED literal; L278 vote
  wire form; L305 append-only; L192 no unresolved Open Questions; L107
  turn-ends-with-reply.
- **Sizing**: HIG catalogue L125-144 is the declared single home for 3 skills —
  moving it requires repointing design-review/design-qa/ux-spec in the same
  change. QA render mechanics → design-qa references.
- **Target**: 10–13KB, ~7 markers.

---

## 4. Per-file findings — skills

### 4.1 team-doctrine (183,947B / 18 files / 181 marker-class occurrences)
~19.4KB (11%) is provenance/LOCAL-copy bookkeeping alone. Target ~55–65KB.
Per-file verdicts:

| File | Bytes | Verdict |
|---|---:|---|
| SKILL.md | 7,526 | RESTRUCTURE — "never invoke" ×17 (mechanically enforced already); Cited-by column dies with the copies |
| references/laziness-discipline.md | 4,896 | **DELETE-WHOLE-FILE** (charter-named; evidence: 3 thinking-hits/82 sessions). Salvage 1 sentence → consumers: never-simplify-away trust-boundary validation (cat 2+1); user-insists→build-it (cat 3) |
| references/fable-completeness-heuristics.md | 3,227 | **DELETE-WHOLE-FILE** (charter-named; clearest 1.1 in tree). Salvage negative-claim-cites-its-searches rule → authoring-verification-gates (cat 4) |
| references/team-conventions.md | 3,992 | **DELETE-WHOLE-FILE** (not charter-named; a hand-maintained census of rule numbers in 8 files this migration renumbers — guaranteed 1.6). Salvage facts already live in their agent files |
| references/runtime-discipline.md | 14,848 | SHRINK → ~2KB tool-contract notes. R4/R5/R6/R7 delete whole (kills the fleet copies); keeps: offset/limit ints, Read-not-directory, docket cwd no-op/never re-init (cat 1), Monitor timeout floor, never-guess-skill-name, summary rule (→ single-home in shutdown-protocol), memory-before-drop (cat 1). Script-trust needs a NEW HOME (nested in R6) |
| references/pitfalls.md | 4,391 | SHRINK → ~600B via §2.1 memory snippet. Keeps: append-only (cat 1), different-repo classification question verbatim, pitfalls_distill.sh sole-mutation + mirror-stdout (cat 1+3), pitfalls_check.sh (cat 4). Coordinated 7-carrier + manifest edit |
| references/shutdown-protocol.md | 9,524 | MOSTLY-KEEP → ~5KB (highest keep density; SP-1/1b JSON shapes = the one place few-shot is correct under cat 4). Cut incidence stats; DELETE SP-4 (exists to silence an auditor); SP-3's 8-item negative list → one positive sentence + 2 evidence-backed examples. VERIFY the `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` precondition against the live harness |
| references/docs-paths.md | 7,451 | MOSTLY-KEEP (writer/reader table = strongest cat-3 keep in tree; Distillation Gate; singular docs/spec). Cut the 1.9KB four-miss enumeration → 3 positive lines |
| references/vorpal-tools.md | 2,332 | MOSTLY-KEEP → ~800B (pin table cat 4; drop derivation trivia) |
| references/truth-first-debugging.md | 4,350 | MOSTLY-KEEP w/ cuts: banner + TFD-5 labels keep (cat 4); DELETE the 4-checkbox pre-fix gate (1.4) + banned-moves list; TFD-3 hypothesis-first → evidence half only |
| references/design-gate.md | 9,268 | MOSTLY-KEEP → ~5KB (Rule 10 lock, acceptance table, Design-source grammar, security track — cat 2/3/4). FORM-check-never-merits ×3 → once; drop the mermaid duplicate + rationale essays; numeric rule cites → names |
| references/authoring-verification-gates.md | 8,636 | SHRINK → ~2.5KB core + shape-keyed refs. Gates are mostly EXTERNAL (execute the regex/SQL, Read the assertion) — survive 1.4 on substance, fail 1.3/1.7 as a 17-bullet always-loaded list. KEEP VERBATIM the teammate-envelope rule (tools+model only — non-reconstructible harness fact) |
| references/sandbox-recovery.md | 6,771 | MOSTLY-KEEP → ~3.5KB symptom→cause→action table. Retry-once + NOT-covered list keeps force (cat 2+1); no blind rm index.lock; no go-mod-tidy |
| references/monitor-orchestration.md | 6,897 | SHRINK → ~1.2KB: the L43 discriminator sentence + deadman_watch.sh/singleton_wait.sh pointers + never-hash-rendered-output. Evidence: 7:1 deliberation-to-use ratio. The file supplies a while-loop pattern its own L43 forbids |
| references/retention-compaction.md | 15,329 | SHRINK → ~3KB: largest 1.4 concentration (six-check self-proof + E0-E4 meta-table); 3.5KB prose grammar for a format two scripts + a parity test implement (point at code); design-history essay → ADR. Keeps: distill.sh sole-mechanism + mirror stdout, exit-8 guard, Trial:/Drift: verbatim precedence, cross-project read-only, reject-failed-compaction |
| references/evolve-orchestration-core.md | 12,836 | SHRINK: 32% is preamble administering duplication. **LIVE DEFECT: L43 "≥2 turns no tool call = stall" misfires against Fable long turns (§3)**. §Shutdown name collision with shutdown-protocol.md. Keeps: missing-section ABORT string, Trial operator-approval gate, AskUserQuestion max-4 verbatim, -r2 respawn-once (grepped downstream), UNAVAILABLE sentinel |
| references/evolve-phase0-templates.md | 59,991 | RESTRUCTURE → ~28-32KB **zero behavior change**: tokenize the 6 scaffolding blocks ({SCAFFOLD_*}, per the existing {HARVEST_BLOCK} model — the one correctly single-homed block in the tree); split per-template. Keep all Output Format blocks (grader contracts), the day-count-vs-ISO script-arg trap, Mimir sentinel. Re-derive the 8 hardcoded model pins per §3 |
| references/deep-collaboration.md | 1,682 | FOLD into team-lead: one sentence survives (declared-phase peer-SendMessage permission grant, cat 3); fix the opaque "L111" line-number coupling |

### 4.2 Review/verdict family
- **code-review-verdict (42,125B, 4.2×)** — the charter's named monolith.
  1.1: Confidence "— and why" tails (L237/L320) → "basis: {commands run}";
  L182 "vs assumed" → checked/unverified + escape string. 1.2: L129
  anti-fabrication block → §2.1 snippet (keep the batch-cancellation harness
  fact); L373 mktemp post-mortem → 1 sentence. 1.4: L405 self-check — delete
  ×4-family; L184-188 evidence gates (real knowledge, wrong altitude) →
  references; G1-G5 symptom taxonomies (~5.3KB) → references/hard-gates.md
  (keep gate IDs + override grammar + g5_check.sh invocation). **1.6: L127
  20/80 triage vs L179 full-coverage — live recall conflict; make L127 an
  ORDERING rule.** L180 vs staff:215 approve-threshold — agent's
  better-not-perfect wins. Split: role-selected ONE template inline → ~11.5KB
  (justification recorded: ~4.9KB is report_lint.py-enforced format authority);
  8 references files. **Keep: L179 no-self-filter (counter-current), both
  ladders, both templates (one loaded), TRACK literal, banned-phrase list
  (linter-scanned), recommendation→vote-verdict map, abort strings.**
- **vote (39,047B, 3.9×)** — 1.1: Confidence/Domain-Relevance fields keep
  (vote_record.sh parses), delete the calibration tails; non-vote Rationale →
  external facts. 1.2: anti-rubber-stamp ×2 (risks opposite bias in a quorum
  protocol) → one independence sentence; CLI forensics/post-mortems →
  references. 1.4: keep docket-available precondition, premise re-verify (1
  sentence), domain-floor jq check; delete task-status bookkeeping +
  double-check. 1.6: L19 high-bar vs staff:284 per-TDD mandate → both cite
  team-lead Rule 10; L87 vs L385 shutdown ×2. Split → ~12.5KB (reviewer
  template = the coordinator-panel contract) + 8 references. **Keep: report
  structure headings, verdict enum, Findings JSON + [], delegation
  string-shape + enumerated rejection errors, NON-VOTE prefix + 0.0 zeroing,
  8-reviewer cap (cat 1), never-blind-retry create (cat 1, permanent audit
  pollution), proposer-exclusion @-stripping (cat 2 — silent independence
  defeat), max 3 rounds.**

### 4.3 Verification/ops family
- **verify-ac (26,055B → ~8KB)** — 5× 1.1 incl. {severity rationale} and the
  silent-completion self-check; carry-forward/contamination blocks →
  references/rounds.md; **delete both COUPLING comments (1,501B of
  instructions to human maintainers living in model context)**; keep ladders +
  LIGHT/FULL templates + literal-command-verbatim + never-PASS-runtime-on-
  static-proxy (strongest marker) + fail-open string + reopen-only (cat 3) +
  delivery-by-mode (cat 3). 1.6: depth-selection two owners; AskUserQuestion
  vs report-only mode.
- **docket (34,362B → ~8.5KB)** — clean on 1.1/1.4; pure CLI reference =
  charter's named references/ split candidate (cli-reference.md 12.6KB +
  workflows.md 11.6KB). Keep the parse contracts: JSON envelope, error/exit
  table, `.data` bare-array-vs-object table (highest value), no-TTY behavior,
  `--force` cascade + `import --replace` (cat 1), enums. Fix intra-file
  comment-add fact ×4. Shell-state corollary needs the runtime-discipline home
  that doesn't exist yet (6 copies, 0 masters).
- **session-metrics (6,490B → ~3.4KB)** — the fleet's positive exemplar
  (thin SKILL.md, script owns behavior, zero 1.1/1.4). Defect: 4 facts stated
  3-4× vs the script, and the prose has **already drifted** from the renderer
  ("n/a" vs "n/a (unpriced model)") — the two-homes failure mode realized.
  Keep the stdout parse contract, effort-never-inferred (once), n/a-never-$0
  (once), and the caller-side disallowed-tools restriction note (cat 3,
  highest-value sentence).
- **commit (21,633B → ~8.3KB)** — gates are largely genuine keep-list
  (caller gate, authorization-not-self-conferred, index-partition, staged-set
  equality, sandbox-context invariant, post-commit verify, no push/amend);
  ~9KB is ceremony around them (Failure-Modes table restating every abort,
  2.1KB regex essay → script comments, git tutorials, forbidden-content
  rosters → the script is declared SSoT). **1.6: L136 match-history-scope vs
  L273 `(claude-code)` forbidden — real three-way conflict ((claude-code) is
  the scope in 6 of the last 60 commits) → resolve in the script allowlist.**
- **review-and-comment (12,125B → ~9.3KB)** — leanest; Step 7 per-item
  approval gate = cat 1 paradigm case, KEEP UNALTERED; --existing dedupe
  re-check keep (external state + exit contract). **1.6: its "6 dimensions"
  ≠ code-review-verdict's "6 dimensions" (only Testing overlaps) — one rubric,
  one home.** effort: xhigh contradicts its own "fast path" positioning.
- **brief (11,111B → ~5.2KB)** — problem is shape (one 2,382B paragraph =
  21% of file). Keep: do-NOT-execute-$ARGUMENTS (cat 2 canonical
  anti-injection), chained-fetch exfil ban (consolidate 3→1; L46 ≈ the
  charter's own recommended wording), Bash read-only boundary (prose is the
  only enforcement), 8-field output block + value enums (team-lead fast path
  consumes), "unverified quote — source drifted" label. Delete the git clause
  (guards nothing), stop-instruction ×4 → ×2, security roster → team-lead
  pointer.

### 4.4 Design/scout/bootstrap family
- **design-qa (19,024B → ~7.5KB)** + **design-review (20,402B → ~8KB)** —
  14 verbatim sibling blocks (~5.3KB), already drifting (banned-hedge lists
  4 vs 6 under one linter; mktemp ¶ +1 clause). Shared
  references/accessibility-checklist.md replaces 3.1KB. 1.1: dr L166 "and
  why" (strongest in family), self-checks ×2, dq L175 rationale field. 1.6:
  who-may-SendMessage ×3 (dq) and ×4 (dr) — forbid-and-mandate in one file.
  **Counter-current: dq L143/dr L156 no-self-filter = compliant, preserve;
  fix 3 soft recall reducers — dq L142 principle-grounding re-check, dr L154
  + validator making an unsolved Blocker UN-EMITTABLE (permit "alternative:
  none identified"), and simplify-scout L98.** Keep: verdict/severity/
  recommendation ladders, templates, DEGRADED literal, dr L250 vote boundary,
  render-before-Pass substance.
- **simplify-scout (19,613B → ~7.5KB)** — clarity-over-length rule stated
  SEVENFOLD → 2 statements; DO/DON'T few-shot pair constrains exploration →
  references; Reminder/Calibration self-recitation output fields → delete
  (with their lint rules). **The 12-principles coupling is the load-bearing
  sequencing risk (§6.2). L98 "drop it" = explicit recall filter that
  discards the junior-tells the skill exists to find → "report it and say
  so".** L98-vs-L117 junior-tells dead end (in-scope, uncitable,
  lint-rejected) must be resolved in the same change. No effort pin — derive.
- **init-specs (16,930B → ~8KB)** — highest keep-rate (real spawns, real
  writes, two validator scripts; record the justification). **L107
  ask-operator-on-subagent-failure = sharpest autonomy conflict → respawn
  once automatically (matching L109's own orchestrator pattern). L44 max-4
  options vs L50's 7-filename multiSelect = latent hard failure — cannot be
  satisfied as written.** 1.6: maintenance owner stated two ways (frontmatter
  @staff-engineer vs body team-lead.md). Keep: RESERVED-NAMES sentinel block
  (lockstep w/ prd), frontmatter YAML contract, spec_verify.sh + escape
  string, overwrite-confirm (cat 1), worktree-safe git-common-dir command,
  `model="sonnet"` spawn pin (the one DERIVED pin in the family — flag
  correct).

### 4.5 Doc-authoring family (tdd 25.8KB / ux-spec 20.4KB / adr 19.3KB / prd 17.8KB)
83.3KB total → ~33.6KB projected (60%), all four under 10KB, no
Required-Sections table touched. ~24KB of the mass is 10 boilerplate blocks
×3-4 (see §1b) — single-home into a shared references/doc-authoring/ dir.
- **tdd**: 1.1 L185 OBSERVED/INFERRED per-claim labeling → adopt adr L191's
  form ("state unverified claims as assumptions"); 1.4 L180-217 eight-arm §5
  apparatus (3KB) → one principle + references (prd's absence of any such
  apparatus is the proof it's additive); keep the 6.1KB format-authority core
  verbatim incl. `updated_by`-selects-security-track (cat 4, silent skip
  otherwise).
- **prd**: cleanest (zero 1.1, zero 1.4 scaffolding); delete the cross-type
  validator-internals claim (L199) and the DKT-167 parentheticals; keep
  reserved-name hard-refusal ordering (checked before the overwrite dialog —
  cat 1/3).
- **ux-spec**: worst on 1.1 — L155 eight-principle pre-save walk + record-
  which-principle-won → delete walk; keep L208-212 affordance-eligibility
  cite-the-code-predicate rule (strongest MUST in the family, evidence-shaped);
  keep §9 Handoff Notes fields (consumed by PM + design-qa); delete the
  three-doc-type frontmatter convention (third home).
- **adr**: cleanest on 1.1/1.4 but only 1.6KB of its 19.3KB is format
  authority. Keep the atomic-claim machinery (noclobber, stub, citation-hijack
  stderr contract, orphan-stub reporting — cat 1/4); delete L298-311's
  narration of two retired workarounds (1.2 in purest form).

---

## 5. Ranked remediation order

Weight = bytes × violation density × load frequency. team-lead loads on every
orchestration session; runtime-discipline/pitfalls/shutdown content
effectively loads 8× via inlining; review-family skills load on the dominant
spawn classes.

| # | Work item | Why here | Prereqs |
|---|---|---|---|
| 0 | **Decisions in §6** + rename-numbers-to-names pass across doctrine + agents | unblocks everything; renumbering later breaks every cross-file pointer | — |
| 1 | **team-lead.md** → ≤30KB (3-way references split + 1.2/1.4 deletions + marker map) | largest file × highest load frequency × 42 markers; charter names it | §6.1 model-pin ruling |
| 2 | **runtime-discipline.md** shrink + fleet-wide R4/R6/R7/R5 deletion (8 agent copies die with the master) | small file, 8× effective load; evidence: ADE = 1 thinking-hit corpus-wide | script-trust rehome (§1d.6) |
| 3 | **Mechanical canonical-block dedup** — delete `-LOCAL` bodies in agents/skills, keep pointer lines (vorpal, docs-paths, shutdown, pitfalls*, truth-first, deep-collab, sandbox, docket-CLI, script-trust, BANNER, tool-envelope, stale-dispatch) | ~61KB agents + ~15KB skills, near-zero judgment; *pitfalls needs the coordinated manifest edit | #2 (so dead R-rules aren't re-pointed) |
| 4 | **senior-engineer.md** rewrite **+ 12-principles extraction to shared references** (repoint simplify-scout in the same change) | 79KB; 2nd-largest; master for CODE-COMMENTS/READ-BEFORE-EDIT (their collapse propagates); hard sequencing constraint | §6.2 |
| 5 | **staff-engineer.md + code-review-verdict** together (severity ladders single-home in the skill; agents get pointers) | 68KB + 42KB; reviewer-2 is the most frequent specialist spawn; ordering hazard §1d.3 | §6.3 DKT-250 |
| 6 | **sdet.md + verify-ac** together (five verification disciplines move into verify-ac references; format-authority pointer already correct) | 62KB + 26KB; verification is the second-highest spawn class | — |
| 7 | **team-doctrine remainder** — DELETE laziness/fable-heuristics/team-conventions; pitfalls→snippet; shutdown-protocol trim (VERIFY env-gate); retention-compaction; monitor; design-gate; authoring-gates; evolve-core (fix the 2-turn stall defect); phase0 tokenization | 184KB → ~55-65KB; mostly mechanical after #2/#3 | #2, #3 |
| 8 | **distinguished-engineer.md** (mode-files split) + **security-engineer.md** (annotate opus pin; No-Guessing → references) | 57KB + 56KB | #4 (adopts senior's contract), #7 (authoring-gates) |
| 9 | **project-manager.md + ux-designer.md** (+ HIG-catalogue home decision feeding design-* skills) | 48KB + 47KB | — |
| 10 | **vote** skill (references split; align trigger conditions with staff + team-lead Rule 10) | 39KB; loaded on every consensus round | #5 |
| 11 | **doc-authoring family** (tdd/prd/ux-spec/adr) — shared references/doc-authoring/; adopt adr's verification sentence family-wide | 83KB → ~34KB; batch job | §6.4 adr atomicity ruling |
| 12 | **design-qa + design-review + simplify-scout + init-specs** — sibling shared module; recall-filter fixes; init-specs autonomy + max-4 bug | 76KB → ~31KB | #4 (principles), #9 (HIG home) |
| 13 | **docket, commit, review-and-comment, brief, session-metrics** — references splits + dedup-to-script | 86KB → ~35KB; lowest load frequency | commit-scope conflict → script allowlist |
| 14 | **Fleet frontmatter sweep** — re-derive every `effort`/`model` pin per §3 (6 of 8 agents pin xhigh; 5 skills pin xhigh; 2 skills pin nothing); annotate deliberate pins (security opus, init-specs sonnet spawn) | cheap, but after content edits so evals measure the final files | #1–#13 |
| 15 | **Verification pass** per charter §4: grep-mechanical marker/dup checks, LLM-graded style conformance (different model), before/after task runs per rewritten agent | the only grounds for restoring a deleted rule is a regression here | all |

---

## 6. Decisions required before remediation (escalations)

1. **team-lead model pin.** File self-assigns sonnet on two-cap economics
   (L240-242); charter §3 assigns orchestration to Fable (with the
   long-turn caveat for an interactive entry point). Ratify one explicitly —
   this also decides whether the §2.1 Fable or Opus delegation snippet
   replaces the MORE-models rule, and whether team-lead's 1.1 hygiene is
   classifier-critical.
2. **12 code-philosophy principles' home.** Extract to a stable-numbered
   shared reference (numbering declared a machine contract) consumed by
   senior-engineer.md, simplify-scout, staff-engineer, and the DE deep-impl
   arm — must land **before or with** the senior-engineer rewrite.
3. **DKT-250 (report-family COUPLING).** The recorded decision *rejecting*
   extraction of the shared scope-table/family blocks directly contradicts the
   charter's zero-duplication target and gates ~8KB across 4 skills.
   Re-litigate as a prerequisite, not per-file.
4. **adr atomicity bypass.** adr:121-127 documents three agent files
   hand-allocating ADR numbers via non-claiming `next_doc_number.sh` while
   adr:133-136 claims no concurrent claim is possible. Remove the
   hand-authoring path or scope the atomicity claim.
5. **Stop-guard hook behavior.** Out of definition-file scope, but the
   1,029 blocked-stop events make it the largest measured thrash source; the
   anti-idle prose deletions in team-lead only pay off if the hook stops
   manufacturing turn-end pressure.
6. **Enforce-by-mechanism conversions.** Evidence shows read-only-by-prose
   fails ~23% of the time. Where boundaries can move into machinery —
   stripping Edit/Write from reviewer spawn envelopes, `disallowed-tools`
   frontmatter, the commit-msg checker's allowlist — prefer that over
   retaining imperative prose, then shrink the prose to one line.
7. **Marker-ceiling exceptions.** Four files cannot honestly reach the ≤10
   ceiling: senior-engineer (~20-25), distinguished-engineer (~20-25),
   security-engineer (~12-14), simplify-scout (~8) + init-specs (~9) among
   skills. Charter §4's real gate is the category mapping (which holds for
   each); record the justifications rather than forcing counts down.
8. **Two live defects found incidentally** (fix regardless of migration):
   evolve-orchestration-core L43's 2-turn stall heuristic misfires on Fable
   long turns; init-specs L44/L50 max-4-options vs 7-filename multiSelect
   cannot be satisfied as written.
