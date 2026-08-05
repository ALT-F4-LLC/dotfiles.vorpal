# 09 — Implementation plan (phase packets)

Status: plan v1 — 2026-08-02. Companion to the approved design (01–08); updated as
units complete. Progress: M0 ✓ (2026-08-02); M1.S1 ✓ delivered as docket PR #33
(2026-08-03; one PR instead of two — delivery-vehicle deviation, no spec change;
§5 silent-drop scoping amended per its DKT amendment issue). M1.S2 ✓ (engine-s2;
WAL/busy_timeout ordering bug found and fixed). M1.S3 ✓ (engine-s3, 2026-08-03:
TDD-first with two-round review, four commit groups, stage review ACCEPT with
zero blocking; amendments applied — §11.1 on_fail + min_siblings, §11.3 ordinal
resolution, §11.4 instance field; DKT-16 open for S4). M1.S4 ✓ (engine-s4,
2026-08-03: security-led TDD review closed a real PATH-resolution gap
(.envrc/direnv vector) before code; two groups; stage review ACCEPT, zero
blocking; §11.4 gains pre_gates + reason per DKT-19/DKT-20; DKT-16 closed; the
§9.1 stranger demo is QA section ZH). M1.S5 ✓ (engine-s5, 2026-08-03: ordered
enums, live thresholds, aggregate + held steps; TDD review flipped H11 (held
blocks stop) and stage review caught the hand-fed aggregate seam — action steps
are engine-run, never claimed, fed from declared inputs (DKT-28); amendments
DKT-22..28 applied to both spec copies; the fixture's `any(severity >= high)`
routes for real over a user-registered order). M1.S6 ✓ (engine-s6, 2026-08-05:
budgets with the floor-as-query, dispatch manifests with recovery, the write-reap
acknowledgment, events read + the §9.2 attribution audit, auto-registration with
the schemas-before-workflows contract, and the §9.11 zero-touch rehearsal green —
the v5–v10 schema span is COMPLETE and v1 is shadow-runnable; TDD review fixed
D2's scope pre-code; three in-flight deviations filed and reconciled
(DKT-30/31/33); the v10 rewind guard now probes indexes, a lesson the dogfooded
tracker taught a fourth time). M1.S7 ✓ (engine-s7, 2026-08-05: --follow over
RunWatch, prune with §3's refusals, GONE live and reachable only by pruning,
run budget --set closing DKT-29's loop). **M1 COMPLETE — the engine shipped:
seven stages, seven local tags, schema v5–v10, the §9 scoreboard on DKT-7 with
three honest caveats (ZG21-partial cites ZK; item 10's gate half is Go-only;
the compat sweep is per-stage-invoked — backlog issue filed to self-contain
it). Artifact GC identified as unstaged by any stage — filed as post-M1
backlog; events.retain is the sole retention window until it lands (DKT-37
disposition). Next: M2a/M2b/M3 in parallel from the frozen grammar, then M4's
shadow run against a binary built from engine-s7.** M2a ✓ (2026-08-05: bootstrap +
retro skills, toy-repo zero-touch transcript; found the version-bump bind wedge —
fixed engine-side as bind-to-highest, DKT-40). **M2b COMPLETE (2026-08-05, DKT-9):
the corpus shipped at G:config/ — 24 contracts, 16 fragments, 2 schemas
(findings@1, ac-report@1 — engine-registered, CONFLICT-proven), 9 workflows
(engine-registered, 78-step activation proof, V21b refusal shown), policy.toml
(engine-pins-bytes-only, verified; tier/security/escalation values
operator-ratified). Eight batches + schemas/workflows/policy sessions, every batch
conversationally approved; deviations DKT-47..49, 50/51, 55..62 filed —
including the batch-9 team-lead.md breach (DKT-61) remedied by purge +
operator ratification, and the standing stop-and-file rule it produced.
Corpus distribution to target `.docket/config/` and the trust-setup flow are
M3's, per the single-homed-source decision; the 04-vs-05 emit and kind/label
contradictions found at registration are amended into 04/05 with annotations.** **M3 COMPLETE (2026-08-05): the harness shipped in six groups plus an
engine patch. G1 render path (artifact-level merge with a fail-closed
collision guard; E3 PASS ask-beats-allow, E4 NEGATIVE; team-lead default pin
removed, operator-ratified, R11). G2 wave.js (policy resolver + TOML subset
parser, golden-pinned) + three executor archetypes. G3 plan + conduct skills
(conductor renamed from `run` — bundled-skill collision, G3-F1). G4 docket-*
hooks (heartbeat dropped: E1 FAIL, D11 fallback — liveness is TTL-only, write
TTL 45m). G5 distribution, DKT-41/59/60/62/64 closed, commit-guard three-case
fix, E2 PASS (agentId join; label not persisted). Engine patch DKT-68/70 —
first engine commits since S7 (7e70547): completion metadata persisted;
packets compose declared files ({executor} token, packet_includes, checkPacketRef
containment) — the corpus reaches briefs at last. Corpus packet wave (DKT-72):
24 contracts + 9 workflows migrated; F-W1/DKT-73 recorded (M4 excludes
test-infra-labeled issues and doc pipelines). G6 re-measured all four
environment checks UNCHANGED from the recorded table against a fresh clone
and fresh binary; M4 pins recorded in the G6 report. Next: M4 pre-registration
(07 §4), then the shadow run.** Produced by three advisors (Go delivery grounded in the real
`feature/graph-engine` worktree; context-packet design; sequencing/risk), synthesized
and reviewed interactively with Erik phase by phase.

**Session model:** every unit runs in a **fresh Claude Code session** with only its
packet's inputs — the design's planner-then-exit principle applied to building itself.
Packets are self-contained: a clean session + the listed files + the kickoff prompt
must suffice. This planning session (Cowork) reviews packets; it implements nothing.

**Vehicles:** `plain` = single fresh session · `plain+review` = plain implements, the
current fleet's review machinery gates the PR (reviewer guard, §6) · `new-system` = the
graph system itself (permitted only at M4+, D-register).

## 1. Work-unit overview

| Unit | Goal | Vehicle | Effort | Depends on | Key acceptance (06 §9) |
|---|---|---|---|---|---|
| M0 ✓ | Freeze, spec port, preambles, DKT issues | this session + plain | S | — | files committed; issues carry ACs |
| M1.S1 ✓ | Reliability delta (`--json=v2`, CAS, taxonomy) | plain | M | M0 | 9.8 |
| M1.S2 ✓ | Claims/leases/capability tokens + `config` | plain | M | S1 | 9.3, 9.4 |
| M1.S3 ✓ | Spine: workflows, steps, next, activation/pins, loops, guard stop/gate | plain+review (+vote) | XL | S2 | 9.5, grammar §11 |
| M1.S4 ✓ | Gates + trust model + exec runner | plain+review (+security, vote) | L | S3 | 9.6, 9.10-part, 9.1 |
| M1.S5 ✓ | Schemas/ordered enums/thresholds/aggregate | plain | M | S4 | feeds 9.5 |
| M1.S6 ✓ | Runs/budgets/floor/report/dispatch + events read + guard spawn/record | plain+review (+security, concurrency) | L | S5 | 9.2, 9.7, 9.9, 9.10, 9.11 |
| M1.S7 ✓ | Events `--follow` + prune (+ `run budget`, DKT-29) | plain | S | S6 | retention/GONE rules |
| M2a | Author bootstrap + retro skills | plain | S | M0 (grammar frozen) | toy-repo zero-touch draft |
| M2b | Generate config corpus (batched) | plain (bootstrap-driven) | M | M2a; validation at S3/S5 | counts + Erik approvals |
| M3 | Harness wiring (skills, wave.js, shims, archetypes) | plain | M | S3 smoke; finish at S6 | three environment checks |
| M4 | v1 shadow run | new-system | M | S6 ∧ M2b ∧ M3 | 07 §4 protocol |
| M5 | Cutover per workflow class; retire fleet | plain | S | M4 (finalize: S7) | 07 §6 |

## 2. Tracks and dependencies

Three tracks join at M4. **Track A (engine, serial):** S1→…→S7 — genuinely serial
(taxonomy underpins every verb; the saga hosts gates; thresholds need schemas; report
rolls up gates+payloads). **Track B (corpus):** M2a → M2b; authoring needs only the
frozen §11 grammar, not the registry — registration/validation checkpoints occur when
S3 (grammar lint) and S5 (threshold-vs-schema) land. **Track C (harness):** M3 can
start after M0 (three environment checks immediately), smoke-test token flow at S2/S3
(`step claim --render`), complete guard shims at S6; wave.js dry-runs against fixture
spawn-rows with no engine at all. S7 may run parallel to M4. M5 finalization
(`--json=v2` default flip, fleet deletion) pairs with S7 per D10.

Safe-stop invariant (every unit): the previous system remains default and complete;
nothing requires a flag-day; every stage merge is tagged and green on its 06 §9 proofs.

**Delivery mode (operator decision, 2026-08-03 — D10 prerogative):** all M1 work
accumulates on `feature/graph-engine`, commit-separated — no per-stage merges to
main, no child branches, no per-stage PRs. Docket PR #33 stays open as a **draft**
tracking PR: its pull_request events give every branch push full CI (ci.yaml's push
triggers cover only main and tags), and its diff is the cumulative integration view.
Stage boundaries are operator-placed **local tags** after review — never pushed:
ci.yaml cuts a public prerelease with binaries on any pushed tag, so tag pushes are
reserved for the arc-end release. Fleet review units (S3/S4/S6) consume tag-range
diffs. History is linear, revert-only. The invariant reads accordingly: every local
stage tag is green on its 06 §9 proofs and shippable; M4 pins a locally built binary
from its tag; main merges once at arc end (post-S7 or post-M4, operator's call) with
a final dormancy re-proof against the pre-merge binary.

## 3. Phase packets

Shared elements (§4): every kickoff uses the SHARED HEADER + STANDING TAINT RULE;
paths — `D:` design docs (dotfiles `docs/design/graph-engine/`; in the docket repo
cite the port `docs/design/`), `R:` docket worktree (`…/docket.git/feature/graph-engine`),
`F:` legacy fleet (`src/user/claude-code/`, M2b named files only), `G:` new dotfiles
graph subtree (M0 creates).

### M0 — freeze, port, preambles, issues (vehicle: this session + one plain session)

Inputs: D:README, D:07 §2, D:08 §3, D:06 + D:02 (port sources), D:01 §6;
R:README.md, R:docs/tdd/vote-subcommand.md (frontmatter convention), R:scripts/qa.sh
header, R:skills/docket/SKILL.md (flag-table convention).
Outputs: dotfiles — `fleet-final-baseline` tag; evolve-* freeze (exclude the 5
harness-level evolve skills from the render build list — one edit, no fleet prose
touched; bugfix lane stays open); G:CLAUDE.md. Docket repo — spec port per §4 manifest
(`R:docs/design/{engine-spec,engine-core,genericity,amendments}.md`); R:CLAUDE.md;
DKT issues S1–S7 + M2a/M2b/M3/M4/M5 with `depends_on` edges mirroring §2, ACs quoting
06 §9/§10, vehicle named in each body (dogfooding the tracker from day one).
Done: `docket issue list` shows the units with edges; freeze commit landed; both
preambles committed verbatim.
Kickoff body: "Goal: execute the M0 checklist. Port the spec per the manifest; commit
both CLAUDE.md files verbatim from the plan; create the DKT issues with depends_on
edges and 06 §9 ACs; tag and freeze per the checklist. Nothing else."

### M1.S1 — reliability delta (plain · M · 2 PRs)

Inputs: D:06 §5, §11.4 (envelope), §9.8; R:internal/cli/root.go,
R:internal/output/*.go, R:internal/db/{db,schema,issues}.go, R:scripts/qa.sh +
scripts/qa/helpers.sh, R:skills/docket/SKILL.md, R:docs/tdd/vote-subcommand.md
(TDD template).
Repo facts that bind: schema is `currentSchemaVersion = 4` with a `migrations
map[int]func(tx)` pattern — copy it; **schema versions will span v5–v10 across
stages** (record in the TDD). `--json` is a Bool persistent flag; `--json=v2` needs
the Bool→String `NoOptDefVal` conversion — the most compat-sensitive edit of the
program. Envelope is centralized in `output/` (cheap v2). CI currently runs **no
tests** and nightly re-cuts from main daily with `install.sh` defaulting to nightly —
so **dormancy proofs are per-PR**, and this stage adds `go test ./...` + `scripts/qa.sh`
jobs to ci.yaml first.
PRs: (1) envelope v2 + error taxonomy (add AUTH_ERROR/STALE_LEASE/TIMEOUT/UNTRUSTED +
exits) + flag surgery; (2) CAS `--if-version` (greenfield version columns — none exist
today) + idempotency keys + ms/seq fields (new tables only; never mutate existing
column formats).
Tests: extend output_test.go; per-file CAS-conflict tests; new qa section
(`test_zd_jsonv2.sh` + SECTIONS array entry); commit a v4 fixture DB under
`scripts/qa/fixtures/` and prove open→migrate→golden-diff (9.8, re-run every stage).
Docs: `docs/tdd/reliability-delta.md` first (vote-schema-enhancement.md is the
precedent); update docs/spec/operations.md + code-quality.md; SKILL.md tables in the
same PR (stale table blocks review).
Done: 9.8 green; qa green; follow-up dotfiles issue filed to delete the nine wrappers
(seven docket_*, two vote_* — 07 §2).
Kickoff body: "Ship the reliability delta per D:06 §5 exactly. TDD doc first; CI gains
test jobs; two PRs as sliced; SKILL.md tables updated in-PR; prove 9.8 with the v4
fixture."

### M1.S2 — claims as capabilities (plain · M · 1 PR)

Inputs: D:06 §2 (claims), §11.4 (claim/context shapes), D:02 §5; R: as S1 plus
R:internal/cli/{config,issue_move}.go.
Work: v6 migration (lease fields shaped for steps to reuse: owner, token_hash,
expires_ms, attempt), `db/leases.go` + `model/lease.go`; claim/heartbeat/refusal
verbs on issues; `docket config set|get` (today's config cmd is read-only skipDB —
new subcommands, store in `meta`) for TTL/attempt/budget/context-cap defaults;
tokens via env/stdin only; reads compute effective status.
Tests: proofs 9.3 (CONFLICT/AUTH_ERROR/STALE_LEASE) and 9.4-half; qa with
backgrounded concurrent claimers. TDD yes; docs/spec/security.md (token transport).
Done: 9.3; expiry-re-ready; dormancy re-proof.

### M1.S3 — the spine (plain+review, vote gate · XL · 4 PRs)

Inputs: D:06 §2 (workflows/activation/steps/guards), §11.1–11.3 **verbatim**, D:02
§§2–5, D:05 §1 (standard-change TOML as a register-test fixture — its node names are
opaque strings to the engine); R: S1 set plus internal/planner/*.go,
internal/cli/{next,plan}.go, internal/db/{relations,labels}.go.
Repo facts: `BuildDAG`/`TopoSort` (Kahn + CycleError) are directly reusable for
register-time workflow lints; `plan.go`'s file-collision phase splitting is the
precursor of scope exclusion (scope needs a new column — `issue_files` is not it);
`next` gains `--run` switching to step mode with issue mode byte-identical.
PRs: (1) `internal/workflow` pkg: grammar parse + validation + `workflow
register|list|show|init` (+ embedded templates under `internal/` — Vorpal's include
list requires embeds there); (2) activation/pinning + minimal run subset (run row,
status, pins) + issue snapshots + DoR lints; (3) step lifecycle + `next --run` +
complete-saga (stages, token retirement, routing txn) + `step
claim/heartbeat/complete/fail/resolve/show/context/render`; (4) loops (`name@k#i`,
superseded, highest-ordinal completion) + fanout joins + `guard stop|gate` + events
*written* (read surface S6).
Each PR lands green on main independently (stall-safe slices — risk §8.1).
Tests: grammar/lint/loop/superseded tables mirroring plan_test.go style; cli tests
per next_test.go pattern; self-contained qa `test_ze_workflow.sh`; proofs 9.5
(byte-identical context goldens, mid-run edit immunity), 9.4-full, 9.2-partial.
Docs: TDD with Implementation Phases per the vote precedent; docs/spec/architecture.md
+ review-strategy.md (encode the genericity rule as a review gate); SKILL.md.
Review gate: TDD reviewed by fleet **before code**; PR-train reviewed
(code-review-verdict); **vote gate on acceptance** (D16 fixes concentrate here).
Done: 9.5; exactly-one-match VALIDATION_ERROR; dormancy.

### M1.S4 — gates + trust (plain+review incl. security, vote gate · L · 2 PRs)

Inputs: D:06 §4 (whole), D:02 §6; R: S3 set plus internal/cli/vote_*.go,
internal/db/proposals.go (vote-gate reuse — tallying works unchanged).
PRs: (1) `internal/trust` (store at `~/.config/docket/trust.toml`; TOFU full-argv
hash default, `--prefix` opt-in, repo scoping, `--global` opt-in) + `internal/exec`
runner (argv-no-shell, env allowlist, process-group kill, timeout, truncation-flagged
capture) — both pure and unit-testable; (2) saga wiring (gate-started events,
re-runnable flag, at-least-once, tree-mutex) + fence harvesting into activation +
`step approve|reject` + `trust` CLI.
Tests: proof 9.6 (malicious-clone cannot execute; unmatched → unverifiable), 9.10
partial (crash-resume never double-runs non-re-runnable), and **9.1 — script the
stranger demo** (human-only docs-review workflow) as qa; qa must sandbox
XDG_CONFIG_HOME. TDD yes; docs/spec/security.md is the major update.
Review gate: security-engineer lens mandatory; vote on acceptance.

### M1.S5 — payloads/enums/thresholds/aggregate (plain · M · 2 PRs)

Inputs: D:06 §2 (payloads/aggregate), §11.2, D:02 §6; R: S3 set.
PRs: (1) `internal/schema` (new pure-Go JSON-Schema dep — CGO stays off; `ordered_enum`
annotation) + `schema register` + payload validation at complete; (2) threshold
predicate parser (§11.2, register-time cross-validation) + builtin `aggregate`
(median/spread-hold/demotion trail; `<step>-held` materialization; embedded
`aggregate@1` schema).
Tests: predicate grammar tables; aggregate goldens; feeds 9.5. TDD yes.

### M1.S6 — runs/budgets/dispatch/events-read (plain+review · L · 3 PRs)

Inputs: D:06 §2 (scheduling/dispatch/budgets), §11.4 (dispatch/next rows), D:02
§§3, 7, §1.6; R: S3 set plus internal/cli/stats.go (rollup pattern).
PRs: (1) budgets/floor accrual in claim path + `run report` (stats.go patterns);
(2) dispatch (single-open CAS, TTL lazy auto-abandon, `abandon`, discrepancy
resolutions, byte-equality `verify`) + `next` refusal + write-reap acknowledgment;
(3) `events list --since` + `guard record|spawn`.
Tests: proofs 9.7 (floor with reporting disabled), 9.9 (dispatch recovery), 9.10
complete, 9.2 auditable via events read, **9.11 zero-touch rehearsal** — v1 becomes
runnable here (06 §10). Review gate: concurrency-focused pass (saga resume, CAS/TTL,
reap-ack) + security lens on guards/dispatch; no vote.
TDD yes; docs/spec/operations.md (backup/retention) + performance.md.

### M1.S7 — events follow/prune (plain · S · 1 PR)

Inputs: D:06 §3 (retention/prune/GONE); R:internal/watch/watch.go +
internal/cli/next.go (the `watch.RunWatch` wiring is ready-made).
Work: `--follow` via RunWatch + `--since` cursor; prune with non-terminal-run refusal
+ retention boundary + GONE. Fold TDD into S6's or a small one. Pairs with M5
finalization (D10).

### M2a — bootstrap + retro skills (plain · S)

Inputs: D:03 §1 (rows/sizes), D:06 §2 "Instance config lifecycle", D:05 §6, D:04
§§2–3, D:08 D8/D12/D14/D15. **No fleet files** — bootstrap mines target repos at
runtime.
Outputs: G:skills/{bootstrap,retro}/SKILL.md (~2KB each).
Done: on a toy repo, bootstrap drafts a complete `.docket/config/` with zero
hand-edits; every write conversation-approved; trust entries proposed, never added.

### M2b — config corpus (plain, batched 3–6 files/session · M, approval-dominated)

Inputs per batch: D:04 §2 (format) + §5 (exemplars) + the batch's §3/§4 rows; D:05
§1–§2 for the workflows batch; **only the named "distilled from" fleet sources**
(e.g. `implement` ← F:agents/senior-engineer.md; judges ← F:skills/code-review-verdict/**;
fragments ← the named team-doctrine reference files). Critical taint addition:
"Extract judgment/domain content only; protocol, lifecycle, shutdown, liveness,
verdict, envelope prose is taint — 07 §3 lists what dissolved; never load
team-lead.md."
Outputs: `.docket/config/{contracts/(24),fragments/(~16),workflows/(9),schemas/,
policy.toml}` + trust proposals.
Done: counts match 04/05; contracts 3–5KB with 04 §2 frontmatter; three exemplars
seeded byte-from 04 §5; workflows register clean once S3 exists; Erik approved each
batch conversationally.

### M3 — harness wiring (plain · M)

Inputs: D:03 entire (it is the spec), D:05 §5, D:06 §1 (guard verbs), D:08
D1/D9/D11/D14, D:07 §2-M3.
Outputs: G:skills/{plan,run}/SKILL.md, G:workflows/wave.js,
G:agents/executor-{read,write,research}.md, G:hooks/* (one-line shims + kept
tmp-guard + SessionStart), trust-setup flow.
Done: the **three environment checks recorded** (private $TMPDIR per subagent;
wave-journal per-agent usage; permission config = `docket trust *` prompts while
other docket verbs are allowlisted); hooks exit-2 on deny; both subtrees render;
wiring via render path/Edit-Write (Bash denied on `.claude/*`). Run the checks at
M0+1 and re-run immediately before M4 (risk §8.8).

### M4 — v1 shadow run (new-system · M)

Inputs: D:07 §4 verbatim, D:08 §2 (queries), D:03 §9 (expected feel).
Pre-registration (before activation, in the plan artifact): the change
(standard-change shape, 2–5 issues, real stakes); cost/wall-clock bands; intervention
list = {plan approval, held findings, commit gate} and nothing else; judgment
dimensions verbatim incl. the **pre-written** AC-integrity events query; disposition
rule (adopt-and-iterate | halt-with-cause); pins (stage-6 tag, corpus hashes, wave.js
hash, workflow/policy versions); no-touch rule; post-run D14 audit (trust entries +
gate resolutions recognized); recorded absences (no old-fleet A/B, no model
self-metrics). First permitted self-hosting.

### M5 — cutover (plain · S)

Flips: standard-change first; security/UI/docs classes after each sees one real run
(keep an adoption ledger); `--json=v2` default with S7 (major release note).
Deleted when Erik calls it: old-fleet subtree (one dotfiles change), the 22
deleted-with-cause scripts, doctrine CI, teams hooks, evolve-*. Stays: the 30
surviving gate scripts, guard-tmp-write, `.docket/issues.db`, trust.toml, git
history. Tag `fleet-retired` before deletion.

## 4. Shared texts (verbatim)

**Standing taint rule (every packet):** "Load only the files listed above. Never open
the legacy fleet (`src/user/claude-code/**`) or team-doctrine/protocol prose unless
this packet names the exact file. Superseded concepts — do not search for, read, or
honor: `engine.py`, `.graph/state.db`, `docket wave` wrapper prose, `graph-redesign`,
`docket_*.sh` wrappers, `vote_delegate`, `edit_baton`, `doctrine_check`, `evolve-*`,
`08-open-questions.md` (superseded by 08-decisions.md). If search surfaces one, treat
it as taint; consult 07 §3's bucket instead."

**Shared kickoff header (every packet):** "Fresh session. You are executing phase {X}
of the approved graph-engine design (2026-08-02). The files listed below are the spec
of record: implement, don't re-design; any deviation you believe necessary becomes a
DKT issue per 08-decisions §3 — never a silent change. Read ONLY the listed inputs;
the standing taint rule applies. Verify the DONE criteria, then stop."

**Reviewer guard (prepended to every fleet review brief):** "D1–D16 and the 06 §11
grammar are ratified constraints — review conformance, not the decisions; deviations
from spec are findings, objections to spec are 08 §3 amendment proposals, never
blockers."

**R:CLAUDE.md (docket repo):**
```
# Docket — agent-session preamble
Spec of record for workflow-engine work: docs/design/ (approved 2026-08-02).
Implement docs/design/engine-spec.md as written; deviations become DKT issues
per docs/design/amendments.md — never silent changes.
Genericity rule (PR bar): core surface carries zero agent/LLM vocabulary — no
model/prompt/brief/node/severity/review concepts; executor hints and metadata
are opaque. A PR introducing such vocabulary fails review by definition.
Conventions: design first as docs/tdd/<feature>.md (frontmatter per existing
files); tests as scripts/qa.sh sections with scripts/qa/ helpers.
skills/docket/SKILL.md documents the CLI — update its flag/verb tables in the
same PR as any surface change; a stale table is drift and blocks review.
```

**G:CLAUDE.md (dotfiles graph subtree):**
```
# Graph fleet subtree — new system; old fleet stays default until M5
Spec of record: docs 03 (runtime), 04 (nodes), 05 (pipelines) of the approved
graph-engine design. Implement, don't re-design; deviations become DKT issues
per 08 §3.
Never edit or copy src/user/claude-code/** from here; distillation happens
only in M2 sessions from per-contract named sources.
Sizes are diagnostics: skills ~2–4KB, archetypes ~1KB; hooks are one-line
`docket guard` shims holding no policy.
Bash writes to .claude/{agents,skills,hooks} are sandbox-denied — wire through
the dotfiles render path or Edit/Write tools.
.docket/config/ is machine-authored (bootstrap/retro), human-approved in
conversation; hand-editing it violates T9.
```

**Spec-port manifest (M0 → R:docs/design/):** `engine-spec.md` ← 06 verbatim incl.
§11 (scrub: "Erik('s)" → "the reference instance/operator"; fleet paths and agent
names in §8 examples → generic; keep §8 as marked examples, §9, §10 intact).
`engine-core.md` ← 02 §§1–9 (drop §10; judge names → "worker hints"; keep all
semantics and §8 context assembly). `genericity.md` ← 06 preamble rule + §7 + §9.1,
verbatim extract. `amendments.md` ← 08 §3 verbatim + "Decisions D1–D16 live upstream;
cite by number." Not ported: 01/03/04/05/07/08 — instance/migration docs; the docket
repo stays stranger-clean.

## 5. Grounded repo facts (bind all S-stages)

Schema: v4, `migrations map[int]func(tx)`, one tx per bump, additive DDL, rewind
guards — copy the pattern; stages span v5–v10. No version columns exist anywhere
today (CAS is greenfield). Timestamps are RFC3339-seconds — ms only in new tables.
Envelope centralized in `output/` (`{ok,data,message}`); codes GENERAL/NOT_FOUND/
VALIDATION/CONFLICT, exits 1–4. `--json` is Bool; v2 needs NoOptDefVal surgery.
`db.Open` already sets WAL + busy_timeout + MaxOpenConns(1). `planner.TopoSort` and
`plan.go` collision-splitting are reusable. `proposals.go` tallying serves vote gates
unchanged. `activity_log` is per-issue without seq — events is a new table. CI runs
no tests today; nightly re-cuts main daily and install.sh defaults to nightly ⇒
**per-PR dormancy**, add test jobs at S1, fleet machines pin DOCKET_VERSION to stage
tags. Vorpal: embeds must live under `internal/`; new deps touch go.sum; CGO stays
off (modernc sqlite); 4-platform matrix safe. Tag per stage (release workflow fires,
prerelease); align tag minors with schema versions (v5→v0.5.0…). Merge to main only
at green stage boundaries.

## 6. Review gates and checkpoints

S3/S4: TDD doc reviewed by the fleet before code; PR train reviewed
(code-review-verdict; security lens on S4); vote gate on acceptance. S6: concurrency
pass + security lens on guards/dispatch, no vote. The taint rule binds *authoring*,
not review — the fleet reviewing Go is clean. Checkpoint after every unit = safe-stop
invariant (§2); rollback is git-revert / don't-render / one-flip at every point; no
data migration to reverse anywhere.

## 7. Risks (top 8)

1. Solo stall mid-S3 (XL): the S3 TDD defines four landable slices, each green on
   main — any stop leaves shippable state.
2. Spec drift found while implementing: 08 §3 in practice — DKT amendment issue citing
   the §11 line → one-file edit → normal review; field-name changes pre-authorized at
   stage review.
3. Fleet bitrot during long M1: freeze scopes to evolve-* only; hotfix lane open; S1
   shrinks the wrapper surface early.
4. Nightly auto-ship: per-PR dormancy proofs; fleet machines pin stage tags; nightly
   stays canary.
5. Early self-host temptation: vehicle line in every DKT issue; no `.docket/config/`
   exists until M2b review; forbidden before M4 by the D-register.
6. Genericity erosion: CI grep-gate on core surface for model/prompt/llm vocabulary;
   stranger demo is an S4 qa test.
7. M2 corpus garbage: exemplar-seeded style, per-batch conversational approval,
   S3/S5 validation checkpoints, hand-authoring declared fallback.
8. Harness API drift mid-arc: one seam (wave.js, hash-pinned); re-run M3's three
   environment checks immediately before M4.

## 8. Calendar shape and milestones

Bands: M0 S · S1 M · S2 M · S3 XL · S4 L · S5 M · S6 L · S7 S · M2a S · M2b M
(approval-dominated) · M3 M · M4 M · M5 S. Critical path S3+S4+S6; tracks B/C fill
review-wait gaps. Public milestones (stream-worthy): S1 release ("reliability v2",
nine wrappers deleted live); S3 release (the workflow-engine spine, demoed via the
human-only stranger test); M4 pass → cutover ("the fleet that replaced itself" —
pre-registered predictions vs the ledger, on stream).
