# TDD — M3: harness wiring

Status: draft for review — 2026-08-05. Stage: M3 of the graph-engine arc.
Spec of record: **03 entire** (it is the spec), 05 §5, 06 §1, 08 D1/D9/D11/D14,
07 §2-M3, plus `docket/docs/design/engine-spec.md` for every engine surface the
harness drives. Implement, don't re-design; deviations become DKT issues per
08 §3.

**What M3 is.** The harness side of the graph engine: the prose and one script
that let a Claude Code session drive an engine that already exists. M1 shipped
the engine (stage 7, `engine-s7`); M2b shipped the corpus (24 contracts, 16
fragments, 2 schemas, 9 workflows, policy.toml). Both are **fixed points** —
this milestone reads them and adapts to them.

**What M3 is not.** Not an engine change. The standing constraint (09 §7 risk 6,
06 §7) is absolute: *anything M3 needs from core that core lacks is a DKT issue,
never an engine edit*. Every resolution below was checked against the shipped
binary for exactly this reason, and §3's four DKT resolutions all land
harness-side or as config — zero core deltas. The docket engine repo is
read-only authority for this arc, including for temporary
test modification (DKT-61's second breach).

---

## 1. Evidence standard and how to read this document

Every claim below carries a label. The engine-stage TDD discipline applies:

| Label | Means |
|---|---|
| **[OBSERVED]** | Run against the shipped binary or read out of a shipped file, in this session. Command or `file:line` given. |
| **[SPEC]** | Quoted or paraphrased from a ratified design doc. Citation given. |
| **[DERIVED]** | Follows from OBSERVED/SPEC facts by stated reasoning. |
| **[ASSUMED]** | Not verifiable before implementation. Every one is either a §6 environment check or a §8 risk. |

An unlabeled claim is an editorial error — treat it as a finding.

Phases (§7) are written so their ACs survive **verbatim copy** into an
implementation session's packet with no surrounding context. Group boundaries
are fresh-context scope fences, same discipline as S1–S7.

---

## 2. The surface, and what already exists

03 §1's inventory is the whole harness footprint. Status as of this session:

| File | 03 §1 target | Status | Group |
|---|---|---|---|
| `skills/plan/SKILL.md` | ~4KB | absent | G3 |
| `skills/conduct/SKILL.md` | ~2KB | absent | G3 — renamed from `run` (G3-F1: the CLI bundles a `run` skill; shadowing in either direction is unacceptable; precedent: code-review-verdict, verify-ac) |
| `workflows/wave.js` | ~2KB | absent | G2 |
| `agents/executor-{read,write,research}.md` | ~1KB ea. | absent | G2 |
| `hooks/*` (5 shims + tmp-guard + SessionStart) | tiny | absent (old fleet's 6 hooks exist, different jobs) | G4 |
| `skills/bootstrap/SKILL.md` | ~2KB | **exists** (5149B, M2a) — touch-up only | G5 |
| `skills/retro/SKILL.md` | — | **exists** (5258B, M2a) — touch-up only | G5 |
| corpus at `config/` | data | **exists** (M2b) — distribution only, no content edits | G5 |

[OBSERVED] `ls src/user/claude-code-graph/` → `CLAUDE.md config skills`; only
`skills/{bootstrap,retro}` exist. `find … -name '*.md' | xargs wc -c` gives the
two sizes above.

### 2.1 The render gap — a finding, not a task detail

[OBSERVED] `grep -rn "claude-code-graph" src/*.rs src/user/*.rs` returns
**nothing**. The graph subtree is not referenced by any Rust builder.

[DERIVED] "Both subtrees render" (09 §M3 Done) is therefore not a
verify-it-still-works item — **it is net-new wiring**, and it is on M3's plate.
Nothing renders from `claude-code-graph/` today; M2a's two skills and M2b's
entire corpus are unreachable from a live session. Sizing M3 as "write six
prose files" would miss this. It is G1, and it gates every other group's
ability to prove anything end-to-end.

[OBSERVED] The mechanism the old fleet uses, `src/user/claude_code.rs`:

- `FileSource::new(name, "src/user/claude-code/agents", systems)` → an artifact
  (`:104-110`), same for `hooks` (`:112`) and `skills` (`:355`).
- Each artifact is symlinked by env key into `${HOME}/.claude/<dir>`
  (`:373-384`).
- Hooks are registered individually via `.with_hook(event, matcher, "bash
  ~/.claude/hooks/<f>.sh", "command")` (`:155-190`).
- `artifacts` and `symlinks` vectors are returned together (`:395`).

[DERIVED] Rendering the graph subtree is the same three moves per directory. §7
G1 specifies it.

### 2.2 Coexistence: both fleets live, old stays default

[SPEC] 07 §2-M3: "Installed alongside the current fleet (separate subtree in the
dotfiles source so both render; the old fleet stays default until M5)."

[DERIVED] The two subtrees both target `~/.claude/{agents,hooks,skills}` — one
symlink per directory, so they cannot both own a path. The collision is real and
G1 must resolve it. §7 G1 AC-1.3 fixes the resolution: **graph files render into
the same three directories under reserved, non-colliding names** (`executor-*`
agents; `plan`/`conduct`/`bootstrap`/`retro` skills; `docket-*` hooks), not into
parallel directories. Rationale: the harness discovers skills and agents by
directory scan of `~/.claude/skills` and `~/.claude/agents` — a
`~/.claude/skills-graph` would render but never be invocable, which fails "both
subtrees render" in letter while failing M3 in substance. Name reservation is
checked mechanically (AC-1.3), so a future old-fleet file cannot silently shadow
a graph file.

[ASSUMED → check E4, §6] That a single `FileSource` per directory is the only
supported shape, i.e. two sources cannot merge into one symlinked directory.
If merging is supported, G1 uses it and the naming rule becomes belt-and-braces
rather than load-bearing. Either way the AC is unchanged.

**The settings surface (operator-found post-G1, 2026-08-05).** §2.2 as first
written covered file and hook collisions but not `~/.claude/settings.json`:
`claude_code.rs:150` pins `agent = "team-lead"` for EVERY session in scope, and
the harness permission/agent surface offers no opt-out value — the key can only
be replaced by name (CLI `--agent` > local > project > user). Re-imposing the
hub persona on every session breaks each graph and arc session unless
overridden per repo, a silent M4 contamination hazard. Operator-ratified
resolution: G1 REMOVES `with_agent` — fresh sessions boot plain; the team-lead
definition still renders, so a hub session is `claude --agent team-lead` away.
07 §2 is honored in substance (every old-fleet file renders; the persona
becomes opt-in), and M5 absorbs the residue: its cutover note documents the
flag fallback instead of removing the pin. E3 re-runs at G6 under the live
activated settings (G1 deviation 4). Risk register: R11.

---

## 3. The four open DKTs, resolved

Each resolution states the decision, the evidence, the alternatives with
verdicts, and what it obligates. All four land harness-side or in config.

### 3.1 DKT-41 — requested/resolved model emission

**The question as filed.** DKT-8's M2a report called `run report`'s metadata
section MISSING. DKT-41 verified both halves of that claim false and asks what,
if anything, is actually owed — specifically where 08 §2's "Model routing drift:
metadata requested-vs-resolved per step" query gets its data.

**[OBSERVED, from DKT-41's own verification]** The R7 rollup ships and works:
`db.MetadataRollup` (`internal/db/rollups.go`), `engine.RunReport.Metadata`
(`internal/engine/report.go:98,180`), both renderers
(`internal/cli/run_report.go:252`), `TestMetadataRollupReadsNoKey` passing.
`run report RUN-N --json` → `data.metadata = [{"key":…,"values":[…]}]`. It
shipped in `8d3c8cc` (DKT-6).

**[SPEC]** R7 is an **opaque key → value → count rollup and nothing else**. A
rollup that paired a "requested" value against a "resolved" one would be core
holding an opinion about what two of a workflow author's keys mean to each
other — reaching for model-selection vocabulary specifically, which is the
genericity rule's defining failure case.

**Resolution: no core change; the harness writes both keys, and 08 §2's query
is instance analysis over `run report --json`.**

Concretely — this is the part M3 owes:

- **All four keys are written by the executor on `step complete --metadata`.**
  wave.js does not write metadata itself — it *carries* the two requested
  values into the executor's bootstrap prompt, which instructs the executor to
  echo them back verbatim alongside the two resolved ones. This is a
  harness-authored relay of harness-authored values, not a judgment: the
  executor copies four strings it was handed and observed.

**[OBSERVED] Why the relay, and not a direct write — `complete` is the only
runtime metadata verb.** An earlier draft said "wave.js writes
`model_requested` before the agent runs" and named no mechanism. There is none:

```
$ docket step claim --help      # flags: --owner --render --template --ttl   (no --metadata)
$ docket step fail  --help      # flags: --note                             (no --metadata)
$ docket step complete --help   # flags: --artifact-file --metadata --payload-file --usage
```

Definition-side metadata is static at activation ([OBSERVED] `marshalMetadata`,
`activate.go:972-975`: "The engine never reads a key inside metadata"), so the
per-step requested values cannot come from there either. `complete --metadata`
is the single runtime write, which is what makes the relay the only available
shape. [SPEC] engine-spec §11.4 `complete args` confirms `[--metadata '{…}']`.

**Corollary, recorded rather than discovered later.** Because the write happens
only at `complete`, **a step that never completes contributes no routing
metadata at all** — and [OBSERVED] `step fail` has no `--metadata` flag, so this
covers *failed* steps too, not only crashed ones. 08 §2's model-routing-drift
query therefore sees **completions only**. Consequences worth stating plainly:
the steps most likely to expose bad routing (the ones that failed at a tier)
are exactly the ones missing from the data, and an escalation's requested-side
history is visible only from the attempt that finally succeeded. This is a real
limitation of the query, not a defect in the design, and it is the honest answer
to "why does drift analysis look thin after a rough run." Widening it would need
`--metadata` on `fail`, which is an engine change — a DKT if the query proves
too thin at M4, never an M3 edit.
- R7 then reports each of the four keys' distinct values with counts, verbatim
  and uninterpreted. **Correlating requested against resolved is a query over
  `--json`, not a core feature.**

**Placement question (08 §2 query table), resolved here.** The row "Model
routing drift — metadata requested-vs-resolved per step" stays in the table
**unchanged**, and its "Query over" column is correct as written: it queries
step metadata. What DKT-8 misread as a missing *feature* is a missing
*instance convention* — the four key names above — which is M3's to establish
and is established by this TDD. No amendment to 08 is required.

**Alternatives considered.**

| Alternative | Verdict |
|---|---|
| Core pairs the keys (an R7 variant that knows "requested"/"resolved") | **Rejected.** Genericity violation by definition; DKT-41 argues this at length and is right. Also an engine edit, which M3 may not make. |
| Emit one combined key, e.g. `model = "opus→opus"` | **Rejected.** Loses per-key value counts (R7's whole shape), makes drift detection a string-parse, and encodes a relationship in a value where the design puts it in a query. |
| Emit only `model_resolved`; treat policy.toml as the requested side | **Rejected.** policy.toml is pinned by hash, not per-step; a `[[resolve]]` table and an escalation rung both intervene between file and spawn (§4.3), so the file does not state what was requested *for this step*. Recording it at the spawn is the only faithful source. |
| Adopted: four discrete keys, correlation by query | **Accepted.** Zero core change; R7 serves it today; genericity intact. |

**Obligates:** wave.js (§4.3, §7 G2 AC-2.4), the executor bootstrap prompt
(§4.4), and DKT-41 closes as *verified-not-a-defect, convention recorded in
M3 TDD §3.1*.

### 3.2 DKT-59 — V26 vote rules must exist before two pipelines register

**The gap.** [OBSERVED, this session] `grep -rn vote_rule` over the nine
workflow TOMLs returns exactly three sites in two files:
`security-load-bearing.toml:110` (`"security-acceptance"`) and
`spec-doc.toml:120,130` (`"doc-acceptance"` twice — one rule shared by the two
vote steps, per that file's `:111` comment). [OBSERVED, DKT-59 against the real
binary on an empty config] V26 (gates-trust §8.2) requires the named rule to
exist at **workflow register** time:

```
✘ Error: step "security-vote": `vote_rule` "security-acceptance" is not registered;
  none are registered. Register one with
  `docket config set vote.rule.security-acceptance.threshold <0-1>`
```

**Why it is a bootstrap problem and not a corpus defect.** [SPEC] Vote rules
live in **engine config** (`docket config set vote.rule.<name>.threshold`), not
in `.docket/config/`. So they are outside activation's auto-registration of the
config directory (06 §2) and are not git-versioned alongside the workflows that
depend on them. On a fresh clone + fresh machine, `run activate` fails to
register two of nine pipelines. The nine TOMLs are correct as authored and
register clean once the rules exist.

**Resolution: the bootstrap skill proposes the two `docket config set`
commands alongside its trust proposals, for the same conversational approval.**

Values, provisional in the spirit of 06 §8 and matching DKT-59's batch-8 proof:

```bash
docket config set vote.rule.security-acceptance.threshold 0.67
docket config set vote.rule.doc-acceptance.threshold 0.60
```

**These are engine config writes, not trust entries** — they authorize no
execution, so they do not carry D14's residual risk and need no `--yes`
handshake. They are still surfaced for approval, because a threshold is policy
the operator owns.

**Alternatives considered.**

| Alternative | Verdict |
|---|---|
| Ship a `vote-rules.toml` in the corpus, auto-registered at activation | **Rejected.** Requires core to read a new config file — an engine change M3 may not make. Filed as the shape a future DKT would take if this friction recurs. |
| Drop `vote_rule` from the two pipelines; use plain human gates | **Rejected.** Discards 05 §4's vote-gate semantics to dodge a two-command setup step; a corpus edit to work around a bootstrap gap. |
| Have `run` skill set the rules lazily on first activation failure | **Rejected.** Error-driven config writes are exactly the "model notices failure and improvises" shape 03 §8 forbids. |
| Adopted: bootstrap proposes both, human approves in conversation | **Accepted.** T9-compliant (machine-proposes, human-approves), same moment as trust proposals, zero core change. |

**Obligates:** bootstrap SKILL.md §4 touch-up (§5.2, §7 G5 AC-5.2). DKT-59
closes when that lands.

### 3.3 DKT-60 — the doc-recorder mechanism

**The constraint.** [SPEC] Recording DOC-N is deterministic — "insert a row and
copy bytes." AC-2 is "zero model-made scheduling decisions in a full run" and
02 §6's standing rule puts arithmetic and bookkeeping in engine mechanics, not
judgment. **An LLM executor is not an option**, and `doc-recorder` is the only
one of 24 executor hints with no 04 contract behind it.

**The decisive evidence.** [OBSERVED] `internal/engine/action.go:1-18` — the
action seam has **exactly two paths**, and the resolution order is a security
property:

> BUILTIN FIRST (§6.1 B1). An action named `aggregate` is computed by core and
> never consults the trust store … Everything else goes through internal/trust
> and internal/exec — CALLED, never re-implemented (§6.2).

So builtins are a closed set (`aggregate` alone; [OBSERVED]
`internal/workflow/aggregate.go:20`, name reserved at register time by V27), but
the **second path is open to instances**: `action = "<trust-entry-name>"` runs a
user-trusted command that receives the step context bundle on stdin
([SPEC] engine-spec §2: "Other computations remain user-trusted commands
receiving step context on stdin"; §11.4 `action result` carries `argv`, `exit`).

[OBSERVED] `docket doc --help` → `create`, `edit`, `link`, `list`, `show`. The
doc surface DKT-60's option 2 wants already exists as a CLI verb.

**Resolution: option 2, in its achievable form — a trusted action step, not a
new builtin.** The `record` step becomes:

```toml
[[step]]
name    = "record"
after   = ["accept-vote-tdd", "accept-vote-adr", "accept-human"]
action  = "doc-record"                    # was: executor = "doc-recorder"
params  = { output = "doc-record" }       # NOT `emits` — see below
inputs  = ["author.doc"]
gates   = ["citation-check"]
```

with a trust entry `doc-record` whose argv is a small instance script reading
the context bundle on stdin and calling `docket doc create` + linking the
issue. Deterministic, no model, no engine edit.

**Why `params.output` and not `emits` — the kind comes from a different field
on an action step.** [OBSERVED] `internal/workflow/validate.go:549-558`, V11:
an action step "must declare `params.output` — it is the kind the step
produces, so without it no downstream `inputs` entry could ever resolve against
this step." [OBSERVED] `validate.go:240-242`, V7's comment: `emits` is
"required for executors, optional on fanout steps that declare it, **absent on
action/human/vote**." [OBSERVED] `producedKind` (`validate.go:475-495`) resolves
a `ClassAction` step's kind from `params.output` only, and its own comment names
the canonical fixture: "`reconcile` is an `action` step with no `emits` that
names its kind in `params.output = "findings"`."

An earlier draft of this section carried `emits` into the action step. That is
wrong, and the engine confirms it in the sharpest way available — see the
transcript below.

#### [OBSERVED] Sandbox registration transcript (2026-08-05)

Method: scratch repo under `$TMPDIR`, `XDG_CONFIG_HOME` redirected into it.
The real `~/.config/docket` was never touched (verified absent afterward), the
real corpus was never modified (`git status` clean over `config/`).

**V1 — the step as first drafted here (`emits`, no `params.output`):**

```
$ docket workflow register v1.toml
✘ Error: v1.toml: workflow f1v1: step "record": an `action` step must declare
  `params.output` — it is the kind the step produces, so without it no
  downstream `inputs` entry could ever resolve against this step
```

**V2 — the corrected step (`params.output`, no `emits`), gates retained:**

```
$ docket workflow register v2.toml
✔ Registered f1v2@1
```

**Two findings the transcript settles, beyond the correction itself:**

1. **`gates` DOES compose with an action step.** V2 registered with
   `gates = ["citation-check"]` intact, and the stored shape carries it:
   `docket workflow show f1v2@1 --json` returns the `record` step as
   `{"name":"record","action":"doc-record","after":["author"],
   "inputs":["author.doc"],"gates":[{"name":"citation-check","pre":false}],
   "params":{"output":"doc-record"},"on_fail":"waiting-human",…}`.
   **`citation-check` therefore stays on the `record` step**; the reviewer's
   contingency (relocate it to the acceptance steps or into the script's own
   checks) is not needed and is recorded here as untaken.
2. **`emits` on an action step is silently IGNORED, not rejected.** A third
   variant carrying both `params.output` and `emits` also registered
   (`✔ Registered f1v3@1`), and the stored shape above shows **no `emits` field
   at all** — it is dropped at parse. So the field is not merely redundant: it
   would sit in the corpus looking load-bearing while affecting nothing. That
   makes dropping it substantive, not cosmetic.

**End-to-end proof on the real file.** The actual `spec-doc.toml`, patched with
exactly the two hunks below, registers clean in the sandbox once its
dependencies exist — which also reproduces and closes DKT-59 in the same run:

```
$ docket workflow register spec-doc-fixed.toml          # no vote rules yet
✘ Error: step "accept-vote-tdd": `vote_rule` "doc-acceptance" is not registered
$ docket config set vote.rule.doc-acceptance.threshold 0.60
✔ Set vote.rule.doc-acceptance.threshold = 0.60
$ docket config set vote.rule.security-acceptance.threshold 0.67
✔ Set vote.rule.security-acceptance.threshold = 0.67
$ docket workflow register spec-doc-fixed.toml          # schemas not yet registered
✘ Error: workflow spec-doc: step "review": `payload` names "findings@1", which is not registered
$ docket schema register findings@1 …/schemas/findings@1.json
✔ Registered findings@1 (ordered: severity)
$ docket schema register ac-report@1 …/schemas/ac-report@1.json
✔ Registered ac-report@1
$ docket workflow register spec-doc-fixed.toml
✔ Registered spec-doc@1
```

(The schema-before-workflow ordering is not a finding — it is what activation's
auto-registration does for itself, schemas before workflows, 06 §2. It appears
here only because this transcript registers by hand.)

**[OBSERVED] What the transcript does NOT show, stated so the change is not
oversold: the UNPATCHED original also registers.**

```
$ docket workflow register spec-doc-orig.toml    # executor = "doc-recorder"
✔ Registered spec-doc-orig@1
```

[DERIVED] DKT-60 is therefore **not a registration defect**, and this TDD does
not claim to repair one. Executor hints are opaque to core (06 §11.1), so the
original registers exactly as DKT-60 said it would. The defect is AC-2
conformance: the original spawns an LLM for work that is "insert a row and copy
bytes." The fix buys correctness of *mechanism*, not of *registration* — and
the honest consequence is that nothing in the engine would ever have caught
this. It was caught by reading, and that is the only way it could have been.

**The executor hint drops**, so per the brief this resolution states both edits:

- **`workflows/spec-doc.toml`** — two lines inside the `record` step
  (`:149-156`). [OBSERVED] `:154` reads `executor = "doc-recorder"` → replace
  with `action = "doc-record"` **plus** `params = { output = "doc-record" }`.
  [OBSERVED] `:155` reads `emits = "doc-record"` → **delete it** (V7: absent on
  action steps; silently ignored if left, per the transcript above). `after`,
  `inputs`, and `gates` are unchanged — gates verified to compose.
  [SPEC] action steps are engine-run, never claimed (engine-spec §2, amended
  DKT-23/28), which is precisely the desired property.
- **`policy.toml:74`** — [OBSERVED] the line reads
  `doc-recorder      = { tier = "bronze" }   # mechanical: record accepted doc`.
  Delete it from `[executors]`. It routes a spawn that will no longer
  happen; leaving it would assert a model tier for deterministic work and would
  break §4.3's coverage invariant (every executor hint across the nine TOMLs has
  exactly one row) in the *other* direction — an orphan row.

Both are corpus files, which M2b shipped and which are otherwise fixed points.
This is a deliberate, narrow exception, authorized by DKT-60 explicitly
reserving the decision for M3 ("M3 resolves which mechanism it is"). It is the
only corpus content edit M3 makes; §7 G5 AC-5.4 fences it.

**Alternatives considered.**

| Alternative | Verdict |
|---|---|
| 1. Gate script on the acceptance steps, no step at all | **Rejected.** A gate's verdict is pass/fail; it emits no artifact. `record` is `inputs`-consuming and `emits = "doc-record"`, and downstream/report expect an artifact. Recording as a side effect of a gate also makes the DOC-N invisible in the artifact index. |
| 2a. New core builtin `action = "doc-record"` | **Rejected — not available.** Builtins are closed and name-reserved at register time; adding one is an engine edit. DKT-60 guessed option 2 was right and it is, but *builtin* was the wrong half. |
| 2b. Trusted action step (adopted) | **Accepted.** Uses the seam's documented second path, deterministic, instance-side, zero core change. |
| 3. Genuine LLM executor (if AC-carrying needs judgment) | **Rejected.** Copying ACs verbatim is a copy, not a judgment — "verbatim" is the operative word. Were judgment needed, the honest move is a contract in 04, which is M2b's closed scope. |

**Residual, stated plainly.** [ASSUMED] The trusted `doc-record` argv must be
approved by the operator like any gate command (06 §4), and the script is a new
instance artifact — the first one M3 introduces. It is small and deterministic,
but it is a script, and D13's default answer is "a generic core verb, not a
script." The honest reading: D13 forbids *harness glue that re-implements engine
mechanics*; this is an instance's own domain action (its doc conventions) on the
seam core provides for exactly that. Flagged for the reviewer as the judgment
call most worth challenging in §3.

**Obligates:** the two corpus edits above, a trust proposal in bootstrap (§5.2),
and §7 G5 AC-5.4. DKT-60 closes when they land.

### 3.4 DKT-62 — policy.toml's consumer interface

**The question.** [OBSERVED, DKT-62] Core reads nothing from policy.toml — not a
key, not a value (`internal/engine/autoregister.go:147-148` registers only
`schemas/*.json` and `workflows/*.toml`; everything else is pinned by content
hash; `docs/tdd/runs-dispatch.md:1679` states "No `policy.toml` interpretation.
It is pinned as bytes and never parsed"). [SPEC] 05 §5 assigns the file to
wave.js. wave.js did not exist, so M2b chose the schema unilaterally and asked
M3 to ratify or revise it.

**Resolution: the schema stands as authored. This section is the interface
contract 05 §5 demands, and it is now binding on wave.js.**

The operator ratified the tier values, security pins, and escalation policy on
2026-08-05 (DKT-61). DKT-62 asks only about *encoding*. Reviewing each of its
four flagged inventions:

| Flagged invention | Verdict | Reasoning |
|---|---|---|
| `[tiers]` named indirection rather than inline `{model, effort}` per row | **Keep.** | 02 §7 specifies the *mapping* (hint → {model, effort}), not its encoding. The indirection keeps one ordering for the ladder, which `[escalation] on_failure = "one-rung"` requires — "one rung" is undefined without an ordered tier list. Inlining would force the rung order to be re-derived or duplicated. |
| `[[resolve]]` with ordered `[[resolve.rule]]`, first-match-wins, keyed on `labels` + `doc_type` | **Keep, with `doc_type`'s origin now defined (below).** | 05 §1 mandates a label-keyed resolution table but leaves matching semantics open. First-match-wins with explicit ordering is the only rule that makes the security-over-plain-tdd precedence readable at the point of authorship, which the file relies on (`policy.toml:170-171`). |
| `[escalation]` in full (not named in 05 §5) | **Keep.** | An addition, correctly flagged. `never` lists and a security ceiling are inert without stating the failure response, and 03 §8's table routes *whether* to retry while leaving *at what tier* unspecified. It fills a real gap on the wave side, which is where 05 §5 puts spawn data. |
| `[security].labels` — task-level, beyond 02 §7's "node types" | **Keep.** | The gap is real: standard-change can carry security work whose executor rows are unpinned. A node-only reading leaves security-labelled work on an unpinned row. Widening a safety pin is the conservative direction. |

**`doc_type`'s origin — the open question DKT-62 raised and M3 must answer.**
DKT-62 notes correctly that `doc_type` "is not a label" and asks whether it
comes from a label or an issue field. **Decision: `doc_type` is read from the
issue's labels, as a `doc:<type>` prefix.** [OBSERVED] engine-spec §11.4's
`context.issue` carries `{id, title, body_snapshot, kind, labels, scope}` —
`labels` and `kind` are the only classification fields available, and `kind`
already carries the workflow match (05 §1). So a second free key would have
nowhere to come from. `doc:tdd` / `doc:adr` / `doc:ux-spec` / `doc:prd` on the
issue is the origin, and an issue with none takes `default` (`prd-author`),
which is exactly what `policy.toml:166-167` documents ("PRD is the unlabeled doc
type"). This requires **no policy.toml edit** — the key name `doc_type` stays;
§4.3 defines its extraction.

**The interface contract (binding).** wave.js reads exactly these tables, and
nothing else in the file:

| Table | Read as | Used for |
|---|---|---|
| `[tiers]` | `name → {model, effort}` | resolving a tier to a spawn's model+effort; the key order defines the rung ladder for `one-rung` |
| `[executors]` | `hint → {tier, never?, reason?}` | primary routing per step |
| `[security]` | `{nodes[], labels[], never[], ceiling}` | sensitivity pins, applied **before** escalation |
| `[[resolve]]` | ordered rules, first-match-wins on `labels`/`doc_type`, else `default` | resolving a hint that names a resolution table |
| `[escalation]` | `{on_failure, security_max, diamond_gates[]}` + `[escalation.fallback]` | tier movement on retry; diamond eligibility |
| `[policy] version` | int | compatibility assertion (§4.3) |

Any key wave.js does not read is inert. §4.3 gives the resolution algorithm;
§7 G2 AC-2.2/2.3 make it checkable.

**Obligates:** §4.3, and DKT-62 closes as *interface defined in M3 TDD §3.4/§4.3;
schema ratified unrevised; `doc_type` origin defined as the `doc:` label
prefix*.

---

## 4. Design

### 4.1 The conductor loop (shipped as the `conduct` skill — G3-F1) and its engine contract

[SPEC] 03 §3 gives the loop verbatim; this section fixes the exact verbs and
flags against the shipped binary.

```
1. docket next --run $RUN --json
     empty + nothing running          → report run state, stop
     REFUSES (dispatch open)          → reconcile first: dispatch verify/close, or abandon
2. ready steps → docket dispatch open --run $RUN [--ack-reap SEQ…]
     → cat policy.toml as text; assert `[policy] version = 1` by substring
     → invoke the saved `wave` workflow with args = {rows, policyText}
     → await completion notification (session stays free for the operator)
3. on wave completion:
     back-fill per-spawn usage from the wave journal
     docket dispatch close --run $RUN [--accept-missing-usage]
     surface any `waiting-human` steps (03 §6)
     → next again. Loop.
```

**The conductor's three policy obligations, and no fourth.** Policy *resolution*
is wave.js's (§4.2, §4.3). The skill's part is mechanical and bounded:

1. **Read** `.docket/config/policy.toml` as **text** (`cat`) — no parsing,
   no interpretation.
2. **Pass** `{rows, policyText}` as the wave's args. wave.js parses (§4.2).
3. **Assert** `[policy] version = 1` appears in the text; refuse on mismatch.
   A substring check, not a parse.

Nothing here chooses a model, a tier, or an executor. A skill that finds itself
comparing tiers has drifted out of spec — G3 AC-3.3 checks exactly that.

**[OBSERVED] Why text and not JSON — the reviewer's suggested one-liner does not
run on this machine.** The natural move is a TOML→JSON conversion in the skill
prose. It was tested and it fails:

```
$ python3 -c "import tomllib, …"
ModuleNotFoundError: No module named 'tomllib'      # python3 is 3.9.6; tomllib is 3.11+
$ which yq tomlq dasel                              # (nothing)
$ node -e 'require("node:toml")'                    # ERR_UNKNOWN_BUILTIN_MODULE
$ node -e 'require("node:util").parseTOML'          # undefined
```

[OBSERVED] No TOML→JSON converter exists on this machine (Python 3.9.6, no
`yq`/`tomlq`/`dasel`, Node v24 without a TOML builtin), and the engine cannot
supply one either: [OBSERVED] `run activate --help` — `--pin` files are
"read only to pin them by content hash… core never reads its meaning." So there
is no verb that emits policy.toml's parsed content.

Adding a dependency to make the one-liner work would put a package install in
the conductor's path — worse than the problem, and the Workflow runtime bars
external modules from wave.js regardless. Passing the raw text costs nothing and
moves the parse to the one place that is already deterministic code.

**Write-reap acknowledgment.** [OBSERVED] `docket dispatch open --help`:

> `--ack-reap` acknowledges a write-class reap by the seq of its `lease-reaped`
> event. It is the entry point a NEW relay uses when taking over from a crashed
> one: core knows the database lease lapsed but cannot check a process it did
> not start, so it holds the class's headroom until somebody confirms the writer
> is gone.

[OBSERVED] `docket guard spawn --help`: `--ack-reap SEQ` is repeatable and
processed **before** the predicate, "so one command both acknowledges and
answers."

[DERIVED] This is a **human-gated moment, not an automatic one**. The engine is
explicit that acknowledging means "YOU have established the old writer is gone,"
and the engine cannot check it. A conductor that acks reflexively converts a
deliberate safety fence into a formality. **Design rule: the `run` skill never
passes `--ack-reap` on its own initiative.** It surfaces the reaped write step to
the operator conversationally (a `waiting-human`-shaped moment in presentation,
though not an engine `waiting-human` state), and passes the seq only on the
operator's answer. This is a design decision M3 makes and the reviewer should
weigh: it costs an interruption on a rare path (crashed writer) to protect
D9's single-writer atomicity guarantee, which is the baseline the whole
concurrency story rests on.

**`--accept-missing-usage`.** [OBSERVED] engine-spec §2 and
`runs-dispatch.md:824` (P19): the flag closes despite missing-usage
discrepancies and *records the acceptance* (`close_reason =
'accepted-missing-usage'`). [SPEC] 07 §2-M3 makes it the fallback if
environment check E2 (wave-journal usage) fails. **Rule: `run` passes it only
when E2 has been recorded as failing** — otherwise a missing usage row is a real
discrepancy and must stall loudly. §6 E2 ties the two together.

**What the conductor must not do.** [SPEC] 03 §3: holds no run state (ids,
statuses, usage numbers, never artifact bodies), makes no routing decisions,
sizes no panels, reconciles nothing. The skill's prose must be written so that
following it produces no such state. §7 G3 AC-3.3 checks this by content.

### 4.2 wave.js — the one harness-specific piece

[SPEC] 03 §1: "the harness adapter (spawn rows → agents, claim→prompt, usage
report)", ~2KB, static and versioned, **not per-run generated** (01 §4 A2).
[SPEC] 03 §3: pipelines over the spawn rows it was handed, calls `agent()` per
step with the archetype, model, and effort the engine resolved.

**Inputs.** The `next` rows, verbatim, as `args`. [OBSERVED] engine-spec §11.4:

```
next row  { step, instance, issue, run, executor, class, attempt,
            expected_cost, lease_ttl_s, metadata }
```

**The file-reading question, answered — and who resolves policy.** [SPEC] 05 §5
says the workflow script "reads no files"; it *also* says "core never reads it —
wave.js does" of policy.toml. These are in tension only if one assumes reading
and receiving are the same act. [OBSERVED] workflow scripts have **no
filesystem access** (the Workflow tool's own constraint), so wave.js cannot
open policy.toml whatever the design says.

**Resolution: wave.js RESOLVES policy, as deterministic code, over the policy
text handed to it in `args`.** The `run` skill `cat`s policy.toml and passes
`{rows, policyText}`; wave.js parses and resolves. Args are not files, so
"reads no files" holds literally; wave.js is the policy consumer, so 05 §5 holds
literally; and the resolution itself is code, which is where it must be.

**[OBSERVED] The parse is wave.js's, and it is small.** No TOML parser is
available to either side (§4.1's evidence), so wave.js carries one for the
restricted subset policy.toml actually uses. That subset is closed and was
enumerated from the file: tables, array-of-tables, inline tables, quoted
strings, integers, and arrays of strings — nothing else. A ~40-line parser was
prototyped against the real `policy.toml` in this session and round-trips every
construct correctly, including the two hard ones: `[[resolve]]` with nested
`[[resolve.rule]]` children **in declared order** (security-first precedence
preserved, which §4.3 step 2 depends on) and `[escalation.fallback]`'s dotted
sub-table. It also strips `#` comments outside quotes — necessary, since
`[security].reason` contains a `#`-free but comma-bearing sentence and the file
is heavily commented.

[DERIVED] This is the one place M3 writes a parser, and it is justified only
because the alternative is a machine dependency in the conductor's path. It is
**not** a general TOML parser and must not be described as one: G2 AC-2.7 pins
it to the enumerated subset and requires it to **fail loudly** on anything
outside — a silent mis-parse of a security pin is the failure mode §4.2 exists
to prevent.

**Why this is not a stylistic choice.** An earlier draft of this TDD put the
resolution in the `run` skill as prose for the model to follow, step by step.
That contradicts the arc's own premise. [SPEC] 03 §3 says the conductor "makes
no routing decisions" — §4.1 quotes it — and an 8-step procedure followed as
prose is a routing decision performed by a model, once per step, for a whole
run. [SPEC] AC-2 is "zero model-made scheduling decisions"; 02 §6's rule is that
arithmetic and bookkeeping are engine mechanics, not judgment. The failure mode
is not hypothetical and it is not loud: a mis-applied security pin (§4.3 step 4)
routes security review to a model the policy forbids and **records the tier it
believed it used**, so the ledger agrees with itself while being wrong. That is
precisely the "silent provenance failure" the `[security]` block exists to
prevent (`policy.toml:126-131`). Deterministic code cannot make that mistake
twice-differently; prose eventually will.

**Consequence, argued rather than absorbed silently:** wave.js grows from 03
§1's ~2KB to ~3–4KB. Sizes are diagnostics, not limits (the subtree's own
CLAUDE.md says so), and the corpus set the precedent — M2b's contracts run
3–5KB against the same kind of target. Paying ~2KB in the one file that is
already "deterministic code, exactly where AC-2 wants it" (03 §3) to remove a
per-step model judgment is the trade the design asks for on its face.

[ASSUMED → §8 R2] That the harness passes `args` large enough for a full wave's
rows. Mitigated by rows being small (10 scalar fields) and waves bounded by
concurrency (~16).

**Per-agent obligations.** wave.js calls `agent()` with:
- the archetype (`agentType`) chosen from the step's `class`/`executor` (§4.4),
- `model` and `effort` from the resolved routing,
- the fixed bootstrap prompt (§4.4),
- `label` = the step id, so the journal is attributable per step.

**Returns.** A checklist: per row, the step id and the status the executor
recorded. [SPEC] 03 §3: "The wave's return is a checklist; the engine's own
discrepancy refusal in `next` is the enforcement."

**Hash pinning.** [SPEC] 09 §7 risk 8: harness API drift is contained to "one
seam (wave.js, hash-pinned)". The file's content hash is recorded at M4
pre-registration; §6's checks re-run immediately before M4 against that pin.

### 4.3 Policy resolution algorithm (the DKT-62 interface, executable form)

**Owner: wave.js, as code** (§4.2). Runs per row, over the `policy` object
handed in `args`. No model judgment anywhere in it, and no step of it is
performed by following prose.

```
resolve(row, issue, policy):
  1. hint ← row.executor
  2. if a [[resolve]] entry has executor == hint:
       for each [[resolve.rule]] in declared order:
         match if every key present matches:
           labels   — every listed label ∈ issue.labels
           doc_type — issue.labels contains "doc:" + doc_type   (§3.4)
         first match wins → hint ← rule.to
       no match → hint ← entry.default
  3. row_policy ← [executors][hint]               # MUST exist (coverage invariant)
     tier ← row_policy.tier
  4. sensitivity: if hint ∈ [security].nodes
                  OR issue.labels ∩ [security].labels ≠ ∅:
       never ← never ∪ [security].never
       ceiling ← [security].ceiling               # gold
       tier ← min(tier, ceiling)                  # applied BEFORE escalation
  5. escalation: if row.attempt > 1:
       tier ← ascend(tier, attempt-1 rungs)       # [escalation] on_failure = "one-rung"
       clamp to ceiling if sensitive              # security_max = gold
  6. diamond gating — applies to BASE tiers, not only escalated ones (§4.3.1):
       if tier == diamond ∧ ¬diamond_eligible(hint, issue, row):
         tier ← [escalation.fallback].diamond     # gold
  7. {model, effort} ← [tiers][tier]
  8. if model ∈ never → fall back per [escalation.fallback]; re-check never
  9. return {model, effort, model_requested, effort_requested} for the spawn;
     the two requested values go into the bootstrap prompt for the executor to
     echo back on `complete --metadata` (§3.1 — there is no earlier write verb)
```

#### 4.3.1 Diamond gating — F3's divergence, resolved

An earlier draft gated diamond only inside escalation (step 5), so a base-tier
diamond row reached diamond ungated. [OBSERVED] `policy.toml:196` states the
opposite: "diamond needs a gate to fire **even for an eligible row**." The file
is the binding interface (§3.4), so the algorithm conforms to it rather than the
reverse — **no corpus edit**, and step 6 above now gates base-tier diamond too.

The three `diamond_gates` entries become predicates. Each is decidable from the
row and the issue alone — no judgment, which is the point:

| `diamond_gates` entry | Predicate |
|---|---|
| `investigator-class` | resolved `hint ∈ {investigate, research, retro-analyst}` |
| `novel-architecture` | issue carries label `novel-architecture` |
| `failed-gold-round` | `row.attempt > 1` ∧ the tier before this attempt's ascent was `gold` |

`diamond_eligible` is true iff any predicate holds.

**Consequences, stated:** today the three `[executors]` diamond rows are exactly
the investigator-class set (`policy.toml:110-112`), so `investigator-class`
fires for all of them and behavior is unchanged — F3 is correctly labeled
harmless *today*. The gate earns its keep the moment a future retro proposes a
fourth diamond row: it will be clamped to gold until someone also states which
gate lets it through. That is the intended failure direction.

**`novel-architecture` needs a label that does not yet exist.** [OBSERVED] no
workflow TOML or policy row references such a label. Rather than invent an issue
field, the predicate reads a label the planner may attach (03 §2 records
labels), and until one is attached the predicate is simply false — a TDD/ADR
step stays at gold. Recorded as an [ASSUMED] to confirm in G2: if the reviewer
prefers this predicate be dropped instead of defined against an unused label,
that is a one-line change to the table above.

**Ordering is load-bearing and is stated because policy.toml states it**:
sensitivity is checked *ahead of* any escalation gate (`policy.toml:133-134`),
and gold is the ceiling for security work (`:135-137`).

**Coverage invariant.** Every executor hint appearing across the nine workflow
TOMLs resolves to exactly one `[executors]` row (after `[[resolve]]`
substitution). [OBSERVED] DKT-62 verified this holds today — "every executor
named across all nine workflow TOMLs has a row — zero missing." §3.3's
`doc-recorder` deletion preserves it by removing the hint and its row together.
§7 G2 AC-2.3 re-checks it mechanically, which is the check that catches a
corpus/policy drift at either end.

**Version assertion.** `[policy] version = 1`. The `run` skill asserts it
before invoking the wave and refuses on mismatch rather than guessing at an
unknown schema — a one-line check, not a resolution step, so it stays skill-side
(§4.1). wave.js asserts it again on the object it received, because a consumer
that trusts its caller's validation is one refactor away from not being
validated at all.

### 4.4 Executor archetypes and the bootstrap prompt

[SPEC] 03 §4 — three thin definitions differing **only in tool surface** (least
privilege, frontmatter-enforced), containing **no role content**: the brief
carries the entire contract (02 §8).

| Archetype | Tools | For |
|---|---|---|
| `executor-read` | Read/Grep/Glob + read-only Bash allowlist **plus** the `docket` CLI and a `$TMPDIR` write path + LSP | judges, verify-ac, design-qa, investigators |
| `executor-write` | full file tools + Bash + LSP; **no web** | implement, fix, test-infra, doc-author |
| `executor-research` | read tools + WebSearch/WebFetch | research |

[SPEC] The read archetype's `docket` CLI and `$TMPDIR` write access are
explicitly *not* tree mutation — "engine recording and scratch are not tree
mutation." This is what makes review honesty structural: a judge that cannot
write the tree cannot fix what it was asked to assess.

**Selection rule.** From the step's `class`/`executor` hint. Write-class →
`executor-write`; `research` → `executor-research`; everything else →
`executor-read`. The mapping lives in wave.js (deterministic code), never in a
model's judgment.

**The fixed bootstrap prompt** [SPEC] 03 §3 — four observable obligations, no
role content:

1. `docket step claim STEP --render` — one atomic mediation returning your
   capability token and fully rendered brief. **On CONFLICT, stop immediately.**
2. Execute the brief.
3. Record it yourself: `docket step complete|fail`, token via `DOCKET_TOKEN`
   env. On `complete`, `--metadata` carries **all four** keys (§3.1):
   `model_requested`/`effort_requested` echoed **verbatim** from the values
   this prompt handed you, plus `model_resolved`/`effort_resolved` for what
   actually served you. Copy the requested pair exactly as given — they are
   the harness's record of its own intent, not yours to adjust.
4. End with the step id and the recorded status.

[SPEC] Executors self-claim and self-record *and cannot do otherwise*: claims
are atomic so a duplicated spawn is harmless (loser gets CONFLICT); recording
requires the live lease's token (AUTH_ERROR otherwise), so an executor that
skipped claiming mechanically cannot record, and a late one gets STALE_LEASE.

**Worktree isolation** [SPEC] 03 §4 + 08 D9: writers *may* be granted worktree
isolation where policy wants parallel writes beyond scope-disjointness — "an
option, not the mechanism." **M3 does not enable it.** `[limits] write = 1`
(D9's always-available baseline) is what v1 ships; adopting worktrees requires
merge semantics specified first (D9's revisit clause). Recorded here so a future
session does not read the archetype's silence as an oversight.

### 4.5 Hooks

[SPEC] 03 §5 — five enforcement hooks plus the kept tmp-write guard and a
SessionStart injection. **Each body is a one-line shim over an engine verb**;
the logic lives in the engine, and hooks contain no policy of their own. All
fail toward safety (block) on engine-state uncertainty.

Filenames carry the `docket-` prefix AC-1.3 reserves (F6): 03 §5's names are the
hooks' *roles*, and the files must not collide with the old fleet's in a shared
`~/.claude/hooks/`. Role names are kept in the table so the mapping to 03 §5 is
one-to-one.

| Role (03 §5) | File | Event | Shim |
|---|---|---|---|
| `spawn-guard` | `docket-spawn-guard-hook.sh` | PreToolUse: Workflow/Agent | `docket guard spawn --run $RUN --rows -` |
| `heartbeat` | `docket-heartbeat-hook.sh` | PostToolUse (global) | `docket step heartbeat --from-marker` |
| `wave-audit` | `docket-wave-audit-hook.sh` | PostToolUse: Workflow | `docket guard record --run $RUN` |
| `run-guard` | `docket-run-guard-hook.sh` | Stop | `docket guard stop --run $RUN` |
| `commit-guard` | `docket-commit-guard-hook.sh` | PreToolUse: Bash | `docket guard gate --step commit-gate` |
| tmp-write guard | `guard-tmp-write-hook.sh` | PreToolUse: Bash | **kept as-is**, old-fleet file, unprefixed and unmoved (03 §5) |
| SessionStart | `docket-session-start-hook.sh` | SessionStart | `docket run status --active --json` injection |

**As-built (G4, 2026-08-05):** `guard stop` and `guard record` take no `--run`
— the flagless forms are the wired shapes (binary is authority over this
table). `heartbeat` was never wired: E1 FAILED (shared world-readable
`$TMPDIR`) and independently `step heartbeat --from-marker` does not exist —
D11 fallback applied, markers cut, drop recorded in
`docket-heartbeat-hook.sh.dropped`. CONSEQUENCE: liveness is TTL-only, so
`lease_ttl_s` sizing is load-bearing — a write-class TTL below worst-case step
duration produces mid-work reaps and ack loops. Bootstrap proposes sized TTLs
(G5); M4 pre-registration records the chosen values. commit-guard retains the
old parser per 03 §5 own carve-out (byte-identical, decision-only delta).

The kept tmp-guard is deliberately exempt from the prefix: it is the old fleet's
own file, shared rather than copied, and renaming it would edit the old fleet —
which M3 does not do (§9). AC-1.3's collision check must therefore treat it as
shared, not as a violation.

[OBSERVED] `docket guard spawn --help` confirms `--run` (required) and `--rows
FILE` (`-` for stdin) — the shim shape above is the real flag set, not a guess.

[SPEC] engine-spec §2: guards are deterministic allow/deny predicates, **exit 0
allow / exit 2 deny with reason**. Exit-2-on-deny is an acceptance item (§7 G4
AC-4.2) and is the whole mechanical basis of "drift is not trusted away, it is
blocked."

**Hooks are global to the session tree** [SPEC] 03 §5 — per-executor scoping
comes from engine state (claims, markers), never from hook configuration. This
is why `heartbeat` must no-op harmlessly in sessions holding no marker: it fires
in *every* session, including the operator's.

**Deleted with the teams runtime** [SPEC] 03 §5: `task-completed`,
`subagent-report` (superseded by `wave-audit`), `teammate-idle`. [OBSERVED] all
three exist in `src/user/claude-code/hooks/` and are registered at
`claude_code.rs:167-186`. **M3 does not delete them** — the old fleet stays
default until M5 (07 §2), and they serve it. M3 only adds the graph set under
reserved names (§2.2). Deletion is M5's one dotfiles change.

**`$RUN` resolution.** [ASSUMED → §6 E1 companion, §8 R3] Hooks need the active
run id without holding state. `docket run status --active` supplies it; the
shims resolve it per invocation rather than caching. If that proves too costly
per PostToolUse fire, the fallback is the engine's own `--active` handling
inside the guard verbs — a DKT, not a hook-side cache, because a cached run id
is exactly the drift hooks exist to prevent.

### 4.6 Trust setup flow

[SPEC] 06 §4 / 08 D14 / 07 §2-M3: **trust is never repo-shipped.** The session
proposes, the human approves in-chat, the session runs `trust add --yes`; the
harness's command-permission prompt is the human-confirmation backstop.

The flow, and its one hard rule — **the flow proposes; it never installs**:

1. bootstrap mines the repo and drafts entries, each flag argued from what it
   read (existing SKILL.md §4 already does this well).
2. `docket run activate RUN-N --dry-run` prints every harvested command
   verbatim, annotated `matched`/`unmatched`. Before trust exists it reads
   `(unmatched)` — the correct state to present.
3. Operator approves in conversation.
4. Session runs `docket trust add <name> [flags] --yes -- <argv>`.
5. Second `--dry-run` must read `(matched: <name>)`.

**D14's backstop is load-bearing only if the permission config cooperates** —
which is environment check E3, and which currently **fails** (§6 E3). Until E3
passes, step 4's `--yes` runs unprompted, and D14's residual-risk bound is not
in place. That is a real finding, not a hypothetical, and §7 G1 AC-1.4 fixes it.

[SPEC] Trust defaults: full-argv hashes; `--prefix` explicit opt-in with an
over-authorization warning; never `--global` unless deliberately chosen. Every
flag defaults **off** and must be argued on.

---

## 5. Corpus distribution and the M2a touch-ups

### 5.1 Distribution — single-homed source → target repo's `.docket/config/`

**The problem.** [SPEC] The corpus is single-homed at
`src/user/claude-code-graph/config/`. [SPEC] engine-spec §2 and D15: instance
config lives **in the target repo** at `.docket/config/`, git-versioned,
content-hash auto-registered at activation. These are different places, and
nothing currently moves bytes between them.

**Resolution: bootstrap distributes; the render path does not.** The corpus is
*instance data for a target repo*, not harness prose for `~/.claude/`. Rendering
it into the home directory would put it where activation never looks.

The distribution rule:

- **Reference copy renders** to the literal path
  **`~/.claude/docket-config/`** — source
  `src/user/claude-code-graph/config`, wired with the same `FileSource` +
  symlink pair as the other three directories (§2.1), so bootstrap has a local,
  versioned source to copy from without network access. The `docket-` prefix
  keeps it inside AC-1.3's reservation, and it is a sibling of
  `~/.claude/{agents,hooks,skills}` rather than a child, because it is not a
  harness-loaded directory — nothing scans it; only bootstrap reads it.
- **bootstrap copies** the relevant subset into the target repo's
  `.docket/config/`, adapting it per §2's mining — which is what the skill
  already does for a template, now with a much richer starting point than
  `workflow init --template standard-dev`.
- **Adaptation, not transcription.** [SPEC] The nine workflows and 24 contracts
  encode this project's conventions; a target repo's build commands, review
  shape, and scopes differ. bootstrap's existing §2/§3 discipline ("Read, don't
  guess. Every adaptation cites something you found") governs the copy.

**Alternatives considered.**

| Alternative | Verdict |
|---|---|
| Render corpus straight into `~/.claude/` alongside skills | **Rejected.** Activation reads `.docket/config/` in the repo, never `$HOME`. It would render and be inert. |
| Symlink `.docket/config/` → the dotfiles source | **Rejected.** Breaks D15 (git-versioned *in the repo*), breaks content-hash pinning's provenance story, and makes one repo's corpus edit mutate every repo's. |
| bootstrap fetches from git remote at run time | **Rejected.** Network dependency in a bootstrap path, and no offline story. |
| Adopted: reference copy renders locally; bootstrap copies + adapts into the target repo | **Accepted.** Preserves D15, preserves T9 (machine-authored, human-approved), no network. |

**Genericity note.** For *this* repo, dogfooding means bootstrap's target is the
repo it was invoked in — the corpus lands in `.docket/config/` here like
anywhere else. No special case.

### 5.2 bootstrap SKILL.md touch-up (existing file, 5149B)

Four changes; everything else stands (it is a good skill):

1. **§1 start-from** — the shipped corpus is the starting point where it fits,
   `workflow init --template` the fallback for an unlike repo. Preserve §2's
   mining discipline over both.
2. **§4 additions** — propose the two `vote.rule` config commands (DKT-59,
   §3.2) alongside trust proposals, and the `doc-record` trust entry
   (DKT-60, §3.3), each with flags argued.
3. **§5** — unchanged in shape; the two-approval discipline (config, then
   activation) already matches §4.6.
4. **Distribution** — a short §on copying-and-adapting the corpus (§5.1),
   replacing nothing.

Size after touch-up: ~6KB against 03 §1's ~2KB target. [DERIVED] The overage is
inherited from M2a, not created by M3, and the file is a *bootstrap* skill — run
once per repo, not loaded every session, so its cost profile differs from
`run`'s. Flagged for the reviewer rather than silently accepted; trimming M2a's
prose is out of M3's scope and would be a separate pass.

### 5.3 retro SKILL.md touch-up (existing file, 5258B)

[SPEC] 05 §6 / D8: retro is operator-invoked; the session *suggests* one after
every 5 completed runs — a conversational nudge, never automatic execution.
[SPEC] D15: retro evolves `.docket/config/` from run evidence.

Touch-up scope: the retro skill must know the M3-era surfaces it can now
propose edits to — policy.toml's tables (§3.4's interface), the vote-rule
thresholds, and the four metadata keys (§3.1) that make routing drift visible.
It reads the ledger; M3 gives it the vocabulary. No mechanism change.

---

## 6. The three environment checks (acceptance spine)

**Recorded results (G6 compares against these):** E1 FAIL (2026-08-05, G4:
shared `$TMPDIR=/tmp/claude-501` — owner-only mode, but shared across one user’s subagents, so the one-executor-renews-another’s-lease hazard holds (G6 corrected the world-readable characterization); D11 fallback applied) · E2
**PASS** (2026-08-05, G5: first real run, two live `agent()` spawns at bronze;
per-agent usage present and complete, attributable to step ids — but via an
`agentId` join, not via `label`, see the recorded answer) · E3 PASS
(2026-08-05, G1: ask-beats-allow, D14 backstop in place) · E4 NEGATIVE
(2026-08-05, G1: one symlink target per artifact; artifact-level merge is the
remedy).

**F-W1 (corpus wave, 2026-08-05 — durable record; tracker DKT-73).**
Resolution-table executor hints are structurally incompatible with engine-side
packet composition: the engine renders briefs from the raw hint before and
independent of harness resolution. Two manifestations — spec-doc-author
refuses loudly (no backing file; its author/revise steps ship packet-less,
correct-but-thin per the §1.3.1 interim), and implement->test-infra mis-briefs
silently (a test-infra-labeled issue gets implement’s charter AND a truncated
closure — test-infra declares six fragments to implement’s five, so
laziness-ladder never reaches it). LOAD-BEARING for M4: the shadow run
excludes test-infra-labeled issues and doc pipelines. Likely fix, post-M4:
dissolve each alias into label-gated sibling steps (the spec-doc acceptance
trio is the in-corpus precedent); DKT-73 carries five acceptance criteria.

[SPEC] 09 §M3 Done, verbatim: "the **three environment checks recorded**
(private $TMPDIR per subagent; wave-journal per-agent usage; permission config =
`docket trust *` prompts while other docket verbs are allowlisted)". [SPEC] Run
at M0+1 and **re-run immediately before M4** (risk 09 §7.8).

Each check states: what it tests, how, what a pass/fail means, and the decided
fallback. **Recording the result is the deliverable — a failed check that is
recorded and routed to its fallback is a passing M3.** These are measurements,
not requirements.

All checks sandbox `XDG_CONFIG_HOME` to a scratch dir. **Never the real
`~/.config/docket`, never the real trust store.**

### E1 — private `$TMPDIR` per subagent

**Tests** [SPEC] 03 §5 / D11: `claim` drops a token-bound 0600 marker in the
executor's `$TMPDIR` scope; the heartbeat hook renews only the lease whose token
the marker carries. This requires each subagent to get a **private** `$TMPDIR`.

**Method.** Spawn ≥2 concurrent subagents; each writes a file to `$TMPDIR` and
lists the directory. Pass = neither sees the other's file, and `$TMPDIR` paths
differ.

**On pass:** markers ship as designed.
**On fail** [SPEC] D11 (decided fallback, nothing pending): **markers are cut**
and TTL + `max_step_duration` alone carry liveness. The heartbeat hook is then
dropped from the set — not left in place firing against a shared marker, which
would let one executor renew another's lease.

### E2 — wave-journal per-agent usage

**Tests** [SPEC] 03 §3: `run` back-fills per-spawn usage from the wave journal.
Requires the journal to expose usage attributable to each `agent()` call.

**Method.** Run a toy 2-step wave; read the journal; confirm per-agent usage
numbers are present and attributable to step ids (hence wave.js's `label` =
step id, §4.2).

**On pass:** `dispatch close` carries real usage.
**On fail** [SPEC] 07 §2-M3: `dispatch close --accept-missing-usage` + the
engine's budget floor carry budgets. [SPEC] engine-spec §2: budgets are enforced
against `max(reported, floor)`, floor = Σ claimed steps' `expected_cost` — so
"the cap holds with reporting absent" by design. The cost is precision in 08
§2's cost-per-run query, not safety.

#### E2 — RECORDED ANSWER (G5, 2026-08-05): **PASS — usage is present, complete, and attributable to step ids.**

**Method.** A toy 2-step wave with **real `agent()` spawns** (G2 stubbed them;
this is the first live run). Routing came from wave.js's *shipped* parser and
resolver — its pure region was evaluated verbatim rather than reimplemented — so
the spawns were routed by the same code a production wave uses. Two bronze rows
(`commit-author`, `fix`), trivial prompts ("Reply with exactly the word OK"),
sandboxed `XDG_CONFIG_HOME`. Both agents returned `OK`; both resolved to
`sonnet`/`medium`/`executor-write`, as bronze should.

**[OBSERVED] Per-agent usage is present and complete**, one record per spawn:

```json
{"input_tokens":2,"cache_creation_input_tokens":10194,"cache_read_input_tokens":0,
 "output_tokens":4,"cache_creation":{"ephemeral_5m_input_tokens":10194,
 "ephemeral_1h_input_tokens":0},"service_tier":"standard","speed":"standard"}
```

**[OBSERVED] It is attributable to step ids — but NOT by `label`.** This is the
finding worth carrying forward, because §4.2 assumed the mechanism. The journal
directory holds three kinds of file:

| File | Carries | Usage? | Step id? |
|---|---|---|---|
| `journal.jsonl` | `started`/`result` lines with `agentId` | **no** | **no** |
| `agent-<id>.meta.json` | `{agentType, spawnDepth, model}` | no | no |
| `agent-<id>.jsonl` | the agent's own transcript | **yes** | yes, in the prompt |

`grep -c 'E2-STEP' journal.jsonl` → **0**. The `label` passed to `agent()` is not
persisted anywhere in the journal. Each `agent-<id>.jsonl` contains its step id
exactly once, in the first `user` message — i.e. **because the bootstrap prompt
names the step**, not because the harness recorded a label:

```json
{"agentId":"a5bb271c25cac1db4","type":"user","message":{"role":"user",
 "content":"Reply with exactly the word OK and nothing else. Your step id is E2-STEP-A."}}
```

Attribution therefore runs `agentId` → transcript → usage, with the step id read
out of the prompt. Verified unambiguous: `E2-STEP-A` appears in exactly one
transcript and `E2-STEP-B` in the other, one step per agent, no cross-talk.

**Consequence, and why this still passes.** 03 §3's requirement is that the
journal expose usage attributable to each `agent()` call, and it does. But the
attribution carrier is the **prompt**, which the harness already controls
(§4.4 puts the step id in the bootstrap prompt for its own reasons), rather than
the `label`. Two things follow: `label` = step id remains correct and worth
keeping — it is what makes `/workflows` and the progress tree legible — but
**nothing may depend on reading it back**, and the bootstrap prompt naming its
step id becomes load-bearing for cost attribution rather than merely helpful.
Recorded in the `conduct` skill so back-fill reads the right files.

**AC-3.4 consequence:** E2 did **not** fail, so `--accept-missing-usage` stays
locked. The conduct skill's scheduled one-paragraph revision is therefore
**untaken** — the section is updated only to replace "E2 has no recorded result"
with the recorded pass, which keeps the flag locked on evidence rather than on
absence of evidence.

### E3 — permission config matches D14's assumption

**Tests** [SPEC] 07 §2-M3: "the harness permission config matches D14's
assumption — `docket trust *` prompts while other docket verbs are allowlisted
(the backstop is load-bearing only if so configured)."

**[OBSERVED] This check FAILS today.** `src/user/claude_code.rs:212` is
`.with_permission_allow("Bash(docket:*)")` — a blanket allow. It matches
`docket trust add --yes` as readily as `docket next`. So D14's
human-confirmation backstop **is not currently in place**, and D14's residual
risk (a misbehaving session self-trusting a command) is bounded only by
full-argv hashing.

**[OBSERVED] The fix is available and small.** `with_permission_ask` exists and
is used at `:264-268` (`Bash(git commit:*)`, `Bash(git push:*)`, …). Adding
`.with_permission_ask("Bash(docket trust:*)")` alongside the existing allow is a
one-line change — G1 AC-1.4.

**[ASSUMED → the thing E3 must empirically verify]** That a more-specific `ask`
takes precedence over a broader `allow` in the harness's permission matcher.
This is *the* load-bearing behavior. If precedence runs the other way, the
allow must be narrowed instead (enumerating the non-trust docket verbs), which
is a larger but still config-only change.

**On fail (precedence wrong AND narrowing rejected):** D14's backstop is absent
and must be recorded as such — the decision's revisit trigger ("any run shows a
trust entry the operator doesn't recognize") becomes the only control, which
is materially weaker. This would be a finding worth escalating before M4, not
a silent acceptance.

#### E3 — RECORDED ANSWER (G1, 2026-08-05): **PASS — ask beats allow.**

The assumption holds. The one-line fix is correct and
`.with_permission_ask("Bash(docket trust:*)")` is in place at
`claude_code.rs`, alongside the unchanged `Bash(docket:*)` allow.

[OBSERVED] **Documentary.** code.claude.com/docs/en/permissions: "Rules are
evaluated in order: deny, then ask, then allow. The first match in that order
determines the outcome, and **rule specificity doesn't change the order**." And
explicitly for this case: "The same precedence applies between ask and allow: **a
matching ask rule prompts even when a more specific allow rule also matches the
same call**." Note the ordering is what makes this work, *not* the `ask` being
narrower — the docs say specificity is irrelevant. A future maintainer must not
"simplify" this by assuming the narrower rule wins on specificity.

[OBSERVED] **Empirical A/B**, run headless against the rendered settings with
`XDG_CONFIG_HOME` pointed at a scratch dir, same session config and cwd for
both arms:

| Command | Result |
|---|---|
| `docket next` | **executed** — reached the binary, which replied `Error: no docket database found`. That is docket's own stderr, not a permission block. |
| `docket trust list` | **never executed** — "The command needs permission to run — it wasn't granted, so it never executed." |
| `docket trust add --yes 'echo hi'` | **never executed** — same permission block. |

In headless (`-p`) mode there is no human to answer, so an `ask` rule surfaces as
a hard "not granted, never executed" rather than an interactive prompt; that is
the prompt path firing. The contrast is the evidence: an identical `Bash(docket
...)` invocation executes on the allow and is withheld on the ask.

**Trust-store safety:** no invocation reached a real trust store. `~/.config/docket/`
does not exist on this machine and was never created; the scratch
`XDG_CONFIG_HOME` ended the run containing only an unrelated `git/ignore`. The
`trust add` arm was blocked by the permission matcher before docket ran at all,
which is the backstop working as designed.

**Consequence:** D14's human-confirmation backstop **is now in place** as of this
change — it was absent before it (the blanket `Bash(docket:*)` allow matched
`docket trust add --yes` as readily as `docket next`). The fallback of narrowing
the allow by enumerating non-trust verbs is **not needed** and should not be
built. Re-verify at G6 against the live activated settings, since this run used
`--settings` rather than the activated symlink.

### E4 — (companion) two FileSources into one directory

Not one of the three, but blocking G1; see §2.2. **Method:** attempt it; if
unsupported, the reserved-naming rule of §2.2 becomes load-bearing rather than
belt-and-braces.

#### E4 — RECORDED ANSWER (G1, 2026-08-05): **NEGATIVE — two artifacts cannot share one symlink target. The §2.2 naming rule is load-bearing.**

[OBSERVED] `vorpal-sdk-0.4.0/src/artifact.rs:716-720` emits one line per symlink:
`ln -s {source} {target}` — **no `-f`** — into a script that opens `set -euo
pipefail` (`:669`). Two symlinks declared with the same target therefore run `ln
-s` twice at one path; the second fails and **activation aborts**. Confirmed
against real generated output, not just the SDK source: the pre-change
`vorpal-activate-symlinks` has exactly one `ln -s` per target.

Two further details worth not re-deriving:

- The pre-flight guard at `:713` is `if [ -f {target} ]`, which tests for a
  *regular file*. A pre-existing **directory or symlink** at the target is not
  caught by it, so a duplicate-target failure surfaces from `ln` itself rather
  than from the guard's intended error message.
- Deactivation (`:708`) is `rm -f {target}`, so a stale symlink is cleaned
  between activations; the failure mode is duplicate targets *within one*
  activation, not across them.

**Resolution adopted in G1 (deviation from AC-1.1's literal wording — see the
G1 report).** Because the harness discovers agents and skills by directory scan,
the graph fleet must land *inside* `~/.claude/{agents,hooks,skills}`, and a
second symlink per directory is impossible. G1 therefore merges the two subtrees
at the **artifact** level: `FileSource::with_merge_path` (`src/file.rs`) copies
the graph subtree into the same artifact output, which is then symlinked once.
This satisfies AC-1.1's intent (graph files reachable in the scanned
directories) and AC-1.2 (old-fleet artifacts unchanged — with `merge_paths`
empty the emitted script is byte-identical to the previous single-source form).

Because merge is `cp -r` layered in order, a shared path **would silently
overwrite** rather than fail. The authoritative guard against that is therefore
emitted into the build script itself (`FileSource::with_merge_path`), so it runs
at `vorpal build` / `just activate` — the chokepoint every render passes
through. `tests/graph_fleet_collision.rs` is the fast local signal, deliberately
not the last line: `cargo test` does not run at activation, so a clash
introduced between test runs would otherwise ship unguarded.

Two implementation details the guard depends on, both found by negative control
rather than reasoning, and both easy to reintroduce:

- **The walk covers directories, not just files** (`find . -mindepth 1`). `cp -r`
  clobbers at either granularity: merging a *file* `adr` onto an existing
  *directory* `adr/` is a real collision that a files-only walk misses entirely.
- **Collisions are counted into a marker file, not signalled by `exit` inside the
  loop.** `find | while read` runs the loop body in a subshell, so an `exit`
  there kills only the subshell and the script proceeds to the very `cp` it was
  meant to prevent. The first draft of this guard had exactly that bug: it
  printed its error and then completed with **exit 0**. Testing the marker in the
  parent shell is what makes the failure real. [OBSERVED] a plain `exit 1` in
  this step script does surface as `vorpal build` exit 1, so failing in the
  parent does fail the build.

#### [OBSERVED] Vorpal caches a failed step's partial output — a re-run reports success

Found while negative-controlling the guard, and worth recording because it will
mislead anyone who tests a build failure twice.

With a clash planted, the **first** `vorpal build` fails correctly: exit 1, guard
message naming both colliding paths, no store path emitted. The **second**
invocation, with the clash still planted and nothing else changed, returns
**exit 0** and emits a store path.

**The safety property still holds.** Inspecting that cached artifact: the
colliding `adr/SKILL.md` is the **old-fleet original**, byte-for-byte, and the
merged tree's own files (`bootstrap/`, `retro/`) are **absent**. The aborted
step's partial output was cached, so the overwrite never happened — the artifact
is *incomplete*, not *corrupted*. No wrong bytes ever reach `~/.claude`.

The cost is diagnostic, not safety: a green second build can mean "this is
fine" or "this is a cached failure." **When testing a build failure, treat only
the first run after a source change as meaningful**, and confirm a fix by
checking that the merged files are actually present in the output rather than by
trusting exit 0. This is pre-existing vorpal caching behavior, not introduced by
the guard, and is out of M3's scope to change.

---

## 7. Phases and groups

Five groups. Each is a **fresh-context scope fence**: an implementation session
gets one group's packet, the standing taint rule, and nothing else. ACs are
written to survive verbatim copy.

Ordering: **G1 → G2 → G3 → G4 → G5**, with G1 strictly first (nothing is
provable until the subtree renders) and G4 late (hooks that block spawns make
iteration harder, so they land after the things they guard are known-good).

---

### G1 — render path + permission config

**Scope.** Wire `src/user/claude-code-graph/` into the Rust builders so both
subtrees render; fix the permission config for E3.

**Inputs.** This TDD §2, §6 E3/E4. `src/user/claude_code.rs`. 07 §2-M3.

**AC-1.1** `src/user/claude-code-graph/{agents,hooks,skills}` each render via
`FileSource` and symlink into `~/.claude/{agents,hooks,skills}`, following the
pattern at `claude_code.rs:104-114,355,373-384`. The corpus reference copy
renders from `src/user/claude-code-graph/config` to the literal path
**`~/.claude/docket-config/`** (§5.1).

**AC-1.1b** All wiring is done through the dotfiles render path or Edit/Write
file tools. **Bash writes to `.claude/{agents,skills,hooks}` are sandbox-denied**
(07 §2-M3) — a shell script that writes there is not a workaround to find, it is
the constraint. Any step of G1 that appears to need one is a design error to
report, not to route around.

**AC-1.2** The old fleet renders unchanged. Every old-fleet agent, hook, skill,
and script present before the change is present after it, byte-identical. The
old fleet stays default (07 §2).

**AC-1.3** Graph files occupy reserved, non-colliding names in the shared
directories: `executor-*` (agents), `plan`/`conduct`/`bootstrap`/`retro` (skills — `conduct` renamed per G3-F1),
`docket-*` (hooks and the config dir). A mechanical check asserts zero basename
collisions between the two subtrees and fails the build on collision, with one
declared exemption: `guard-tmp-write-hook.sh` is the old fleet's own file,
shared not copied (§4.5), and is expected on both sides.

**AC-1.4** `Bash(docket trust:*)` prompts while other `docket` verbs remain
allowlisted (E3). The empirical precedence question (§6 E3) is answered and
**recorded** — including a negative answer, which routes to narrowing the allow.

**AC-1.5** E4 recorded: whether two `FileSource`s can merge into one symlinked
directory.

**Done:** `just activate` (operator's gate) renders both subtrees; a live
session sees both fleets' files; `docket trust add` prompts.

---

### G2 — wave.js + three archetypes

**Scope.** The harness adapter and the three executor definitions.

**Inputs.** This TDD §3.1, §3.4, §4.2, §4.3, §4.4. 03 §3–§4. 05 §5. 02 §7.
engine-spec §11.4 (wire shapes). `policy.toml`.

**AC-2.1** `workflows/wave.js` exists, is static and versioned (not per-run
generated, 01 §4 A2), and pipelines over the spawn rows handed to it in
`args = {rows, policyText}`, calling `agent()` per row with archetype, model,
effort, and the §4.4 bootstrap prompt. `label` = step id. Size ~3–4KB against
03 §1's ~2KB, the overage argued in §4.2 (it absorbs the policy resolver and its
parser) — sizes are diagnostics, and the argument is the deliverable, not the
number.

**AC-2.2** The policy resolution algorithm (§4.3) is implemented **in wave.js as
code** — not as prose for a model to follow, anywhere (F2) — including
**sensitivity-before-escalation** ordering, the gold ceiling for security work,
and base-tier diamond gating (§4.3.1). A table-driven check over hand-built rows
exercises, at minimum: a plain row; a `[[resolve]]` label match; a `doc_type`
match; the security-label match on an unpinned row; a `never`-list fallback; a
one-rung escalation on attempt 2; **a base-tier diamond row with no gate
satisfied, which must clamp to gold**; and a base-tier diamond row with
`investigator-class` satisfied, which must stay diamond.

**AC-2.2b** No model is asked to resolve, compare, or choose a tier, model,
effort, or executor at any point in the wave path. Verified by reading wave.js
and the bootstrap prompt: routing values reach the prompt as fixed strings only.

**AC-2.7** wave.js's TOML parser (§4.2) handles exactly the enumerated subset —
tables, array-of-tables, inline tables, quoted strings, integers, arrays of
strings, `#` comments outside quotes — and **fails loudly** on anything outside
it rather than parsing partially. Round-trips the real `policy.toml` with
`[[resolve.rule]]` order preserved and `[escalation.fallback]` nested
correctly. It is not a general TOML parser and its error message says so.

**AC-2.3** Coverage invariant: every executor hint across the nine workflow
TOMLs resolves to exactly one `[executors]` row, and every `[executors]` row is
reachable from some hint. Checked mechanically; fails loudly at either end.

**AC-2.4** The bootstrap prompt carries `model_requested`/`effort_requested` as
fixed strings, and instructs the executor to echo them verbatim alongside
`model_resolved`/`effort_resolved` on `complete --metadata` (§3.1 — `complete`
is the only runtime metadata verb). All four appear in `run report --json`'s
`data.metadata` after a completed toy step. The known gap is recorded, not
fixed: a failed or crashed step contributes none of the four.

**AC-2.5** `agents/executor-{read,write,research}.md` exist, ~1KB each, differing
**only in tool surface** per §4.4's table, containing **no role content**. Read
archetype has `docket` + `$TMPDIR` write + LSP; write has full file tools + LSP,
**no web**; research has read tools + web. Worktree isolation is **not** enabled
(§4.4).

**AC-2.6** wave.js's content hash is recorded for M4 pinning (09 §7 risk 8).

**Done:** a toy wave spawns the right archetype at the right model/effort for a
hand-built row set, under a sandboxed `XDG_CONFIG_HOME`.

---

### G3 — plan + run skills

**Scope.** The two session-level skills.

**Inputs.** This TDD §4.1, §4.3, §4.6. 03 §2, §3, §6, §7, §9, §10. 08 D1.

**AC-3.1** `skills/plan/SKILL.md` (~4KB): converses until the request is
unambiguous (goal, constraints, ACs, security sensitivity, size); records the
request, a plan artifact, and issues with kinds/labels/scopes/`depends_on` and
**verbatim** ACs; then **stops**. The planner never observes execution.
Re-planning is a fresh invocation reading the run record. Explicitly supports a
deliberately-uncomposed later phase behind a human gate (03 §2, §10).

**AC-3.2** `skills/conduct/SKILL.md` (~2KB): implements §4.1's loop verbatim —
`next` → `dispatch open` → invoke `wave` → await → back-fill usage →
`dispatch close` → `next`. Surfaces `waiting-human` steps conversationally and
runs the engine verb on the operator's answer (03 §6).

**AC-3.3** The `run` skill holds **no run state**: no ids, statuses, usage
numbers, and never artifact bodies; makes no routing decisions, sizes no panels,
reconciles nothing (03 §3, D1). Checked by reading the prose for any instruction
to remember, tally, or decide.

**AC-3.4** `--ack-reap` is passed **only** on an operator's explicit
conversational answer, never on the skill's own initiative (§4.1).
`--accept-missing-usage` is passed **only** when E2 is recorded as failing
(§6 E2).

**AC-3.5** The skill's policy involvement is **exactly three mechanical acts**
(§4.1): `cat` policy.toml as text, pass `{rows, policyText}` as the wave's args,
and assert `[policy] version = 1` by substring, refusing on mismatch. It does
**not** parse policy.toml, and it does not resolve anything — resolution is
wave.js's (AC-2.2). A skill that compares tiers has drifted out of spec.

**AC-3.6** The trust-setup flow (§4.6) **proposes and never installs**: no path
through either skill runs `trust add` without a recorded conversational
approval immediately prior.

**Done:** a dry toy run reaches `dispatch open` with correctly resolved routing
and stops cleanly; no engine command the operator did not authorize.

---

### G4 — hooks

**Scope.** Five shims + kept tmp-guard + SessionStart.

**Inputs.** This TDD §4.5, §6 E1. 03 §5, §7. 06 §1 (guard verbs). engine-spec §2
(guards). D11.

**AC-4.1** All five hooks exist as **one-line shims** over the engine verbs in
§4.5's table, registered via `.with_hook(...)` per `claude_code.rs:155-190`.
No hook contains policy, branching on run content, or state.

**AC-4.2** **Hooks exit 2 on deny.** Demonstrated live for at least
`spawn-guard` (rows not matching the open dispatch) and `run-guard` (session end
with pending work) — the deny path, not just the allow path.

**AC-4.3** `guard-tmp-write` is kept **as-is** from the old fleet (03 §5).

**AC-4.4** SessionStart injects `docket run status --active --json`; a fresh
session in the repo knows the run state with no handoff document (03 §7).

**AC-4.5** `heartbeat` no-ops harmlessly in sessions holding no marker (hooks
are global to the session tree, §4.5), and is **dropped entirely** if E1 failed
(D11's decided fallback) rather than left firing against a shared marker.

**AC-4.6** The three teams-runtime hooks (`task-completed`, `subagent-report`,
`teammate-idle`) are **left in place** for the old fleet; deletion is M5's.

**AC-4.7 (Stop-hook coexistence — R7 promoted out of the risk section, F5.)**
With **both** Stop hooks registered — the old `stop-guard-hook.sh` and the new
`docket-run-guard-hook.sh` — in a graph session holding no team config:

- a session with **no pending work stops cleanly** (neither hook blocks); and
- a session with pending work is **denied by `run-guard`, and the reason
  surfaced is `run-guard`'s**, not the old guard's.

This tests both of the old guard's dimensions, not just the Docket one: its
live-teammate check must also be inert without a team config. If either
dimension blocks a graph session, that is a finding that gates M5's deletion
ordering — record it; do not work around it graph-side.

**Done:** each hook fires on its event, allows the good case, and exits 2 with a
reason on the bad case.

---

### G5 — corpus distribution + M2a touch-ups + DKT closures

**Scope.** Distribution, the two skill touch-ups, the two DKT-60 corpus edits.

**Inputs.** This TDD §3.2, §3.3, §5. D15. engine-spec §2 (config lifecycle).
Existing `skills/{bootstrap,retro}/SKILL.md`.

**AC-5.1** Corpus distribution per §5.1: reference copy renders; bootstrap
copies and **adapts** into the target repo's `.docket/config/`, citing what it
mined for each adaptation. No symlink into the dotfiles source; no network.

**AC-5.2** bootstrap proposes the two `vote.rule` config commands (DKT-59) and
the `doc-record` trust entry (DKT-60) alongside its trust proposals, each flag
argued. **Proposes only** — approval precedes every install.

**AC-5.3** Both `security-load-bearing` and `spec-doc` register clean on a
**fresh machine with empty engine config** after the approved commands run.
This is DKT-59's exact reproduction, inverted into a pass.

**AC-5.4** DKT-60's edits land and nothing else in the corpus changes.
`spec-doc.toml`'s `record` step: `executor = "doc-recorder"` → `action =
"doc-record"` **plus** `params = { output = "doc-record" }`, and the
`emits = "doc-record"` line **deleted** (§3.3 — V11 requires `params.output`;
V7 puts `emits` absent on action steps, where it is silently ignored).
`gates = ["citation-check"]` **stays** — verified to compose with action steps.
`policy.toml`'s `doc-recorder` row is deleted. A diff over `config/` shows
exactly these hunks in exactly these two files. **The corpus is otherwise a
fixed point.**

**AC-5.4b** The patched `spec-doc.toml` registers clean in a sandboxed scratch
repo (`XDG_CONFIG_HOME` redirected; never the real `~/.config/docket`), and the
`record` step's stored shape carries `action`, `params.output`, `inputs`, and
`gates` with **no `emits` field**. §3.3's transcript is the reference run.

**AC-5.5** retro touch-up (§5.3): knows policy.toml's tables, the vote-rule
thresholds, and the four metadata keys as things it may propose edits to.
Operator-invoked; suggests after 5 runs; never executes automatically (D8).

**AC-5.6** DKT-41, -59, -60, -62 each closed with the resolution recorded and a
pointer to this TDD's section. **Never hand-edit the tracker DB** — closures go
through the CLI.

**Done:** a fresh-clone bootstrap produces a working `.docket/config/`, all nine
pipelines register, and the four DKTs are closed.

---

### G6 — re-run before M4 (not a build group)

[SPEC] 09 §7 risk 8: re-run the three environment checks **immediately before
M4**. Not code — a recorded re-measurement against the same method, comparing to
G1/G2's recorded results and to wave.js's pinned hash. A changed answer is a
finding that gates M4, which is the entire point of the risk item.

---

## 8. Risks, in hindsight form

Written as "we will have wished we had…", per the engine-stage discipline.

**R1 — The render gap was mistaken for a formality.** *We will have wished we
had treated "both subtrees render" as net-new wiring rather than a checkbox.*
[OBSERVED] no builder references the graph subtree; M2a's skills and M2b's
entire corpus are unreachable from a live session today. Mitigation: G1 is first
and gates everything.

**R2 — wave.js's args exceeded what the harness passes.** *We will have wished
we had measured a full wave's row payload before designing around it.*
Mitigation: rows are 10 scalar fields and waves are concurrency-bounded (~16);
if it bites, the fallback is passing a manifest reference rather than rows —
but that reads a file, which §4.2 rules out, so it would be a DKT.

**R3 — Hook `$RUN` resolution cost.** *We will have wished we had measured
`docket run status --active` per PostToolUse fire.* Mitigation: §4.5 states the
fallback (engine-side `--active` in the guard verbs, as a DKT) and rules out a
hook-side cache, which would reintroduce the drift hooks exist to prevent.

**R4 — E3's precedence assumption was wrong.** *We will have wished we had
tested ask-over-allow before designing the one-line fix.* Mitigation: E3 makes
the test explicit and states the larger fallback (narrow the allow). Until it
passes, D14's backstop is absent — recorded, not assumed away.

**R5 — The `doc-record` script became the first crack in D13.** *We will have
wished we had asked whether one instance script invites a second.* Mitigation:
§3.3 states the reasoning and flags it for the reviewer explicitly; the seam
used is the one engine-spec §2 provides for instance computations, and D13's
default answer ("a generic core verb, not a script") is preserved for anything
that is *engine mechanics* rather than instance domain.

**R6 — Harness API drift mid-arc.** [SPEC] 09 §7 risk 8. Mitigation: one seam
(wave.js), hash-pinned at M4 pre-registration; G6 re-runs the checks.

**R7 — Both fleets live at once produced confusing behavior.** *We will have
wished we had checked that the old fleet's global hooks do not fire against
graph runs.* [OBSERVED] the old fleet's hooks are registered globally at
`claude_code.rs:155-190`; `stop-guard-hook.sh` and the new `run-guard` both bind
Stop, so a graph session fires both.

[OBSERVED] The collision is **narrower than it looks**, and the evidence is worth
recording rather than re-deriving: `stop-guard-hook.sh`'s header documents
session scoping added after a real incident (DKT-362, 2026-07-16 DKT-345) — its
Docket dimension runs *only* when the session has its own team config at
`~/.claude/teams/session-<prefix>/config.json`, and "a no-team leaf session is
never Docket-blocked, regardless of repo-wide outstanding issues." A graph
session creates no team config, so the old guard's blocking dimension
self-disables and `run-guard` is the only one that can deny.

[ASSUMED] That the old guard's *live-teammate* dimension is likewise inert
without a team config — a Stop hook that blocks for a teammate that does not
exist would strand every graph session. **This is no longer left in the risk
section to be inferred: G4 AC-4.7 tests it explicitly**, covering both the
clean-stop and the denied-with-run-guard's-reason cases. If either dimension
blocks a graph session, the resolution is M5's deletion order, not a graph-side
workaround.

**R9 — A deterministic procedure was specified as prose for a model to follow.**
*We will have wished we had asked, of every numbered procedure in this TDD, "who
executes this?"* The first draft put §4.3's 8-step resolution in the `run`
skill — inside a document that quotes "makes no routing decisions" two sections
earlier. Caught in review, not by me. Mitigation: §4.2 states the ownership rule
and AC-2.2b makes it checkable. The general lesson is worth carrying into the
group sessions: **a numbered list in a skill is a model executing an algorithm**,
and the AC-2 boundary is exactly the line between that and code.

**R10 — wave.js's TOML parser mis-parsed a security pin silently.** *We will have
wished we had made the parser fail loudly instead of best-effort.* [OBSERVED] no
TOML parser is available to the harness (§4.1), so M3 writes one — a genuine new
failure surface introduced by this revision, not present in the first draft.
A partial parse that drops `[security].never` routes security review to Fable
while recording that it did not. Mitigation: AC-2.7 pins the parser to the
enumerated subset and requires loud failure outside it; AC-2.2's table exercises
the security paths specifically. Flagged as the revision's own most dangerous
addition.

**R11 — the settings surface re-imposed team-lead on every session.** *We will
have wished the coexistence analysis had covered rendered settings, not only
files and hooks.* [OBSERVED] `claude_code.rs:150` `with_agent("team-lead")`; no
opt-out value exists in the settings surface — a pinned agent can only be
replaced by name. Found by the operator between G1 review and activation;
missed by this TDD and its review both. Mitigation: the operator-ratified
resolution in §2.2 (G1 removes the pin; persona becomes opt-in via
`--agent team-lead`; M5 documents the fallback). The general lesson joins R9:
a shared surface is anything both fleets render INTO — files, hooks, settings,
permission rules — and the coexistence sweep must enumerate the surface list,
not the file list.

**R8 — Bootstrap's size grew past its target while nobody owned trimming.**
*We will have wished we had assigned M2a's overage to someone.* [OBSERVED]
5149B against a ~2KB target, before M3 adds to it. Mitigation: §5.2 states the
overage, its inheritance, and why a bootstrap skill's cost profile differs —
and declines to silently absorb it.

---

## 9. What M3 explicitly does not do

Stated so a later session does not read silence as an oversight:

- **No engine change of any kind.** Every gap found routes to a DKT. The docket
  repo is read-only authority, including for temporary test modification.
- **No corpus content change** beyond DKT-60's two authorized hunks (G5 AC-5.4).
- **No worktree isolation** (D9 — optional, never required; §4.4).
- **No deletion of old-fleet files** (M5's, 07 §2; G4 AC-4.6).
- **No self-hosting / real run.** [SPEC] 09 §7 risk 5: forbidden before M4.
  Toy runs only, sandboxed `XDG_CONFIG_HOME`, never the real
  `~/.config/docket`, never the real trust store.
- **No trust entry installed by any shipped file.** Trust is never repo-shipped
  (06 §4); the flow proposes (§4.6).
- **No push.** No tracker DB hand-edit.
- **`team-lead.md` is fenced absolutely.** Per DKT-61's standing rule, a design
  instruction that seems to require a fenced or missing source means **STOP and
  file the contradiction** — never resolve it by reading.

---

## 10. Traceability

| Obligation | Source | Where discharged |
|---|---|---|
| plan + run skills | 03 §1–§3 | G3 |
| wave.js | 03 §1, §3; 05 §5 | G2 |
| three archetypes | 03 §4 | G2 AC-2.5 |
| hooks (5 + tmp-guard + SessionStart) | 03 §5, §7 | G4 |
| trust-setup flow | 03 §1; 06 §4; D14 | §4.6, G3 AC-3.6, G5 AC-5.2 |
| corpus distribution | D15; engine-spec §2 | §5.1, G5 AC-5.1 |
| bootstrap touch-up | 07 §2-M3 | §5.2, G5 AC-5.2 |
| retro touch-up | 05 §6; D8 | §5.3, G5 AC-5.5 |
| three environment checks recorded | 09 §M3 Done | §6, G1/G2, G6 |
| hooks exit-2 on deny | 09 §M3 Done | G4 AC-4.2 |
| both subtrees render | 09 §M3 Done | G1 AC-1.1/1.2 |
| wiring via render path / Edit-Write | 07 §2-M3 | G1 |
| re-runnable before M4 | 09 §7 risk 8 | G6 |
| DKT-41 | this TDD §3.1 | G2 AC-2.4, G5 AC-5.6 |
| DKT-59 | this TDD §3.2 | G5 AC-5.2/5.3 |
| DKT-60 | this TDD §3.3 | G5 AC-5.4/5.4b |
| DKT-62 | this TDD §3.4, §4.3 | G2 AC-2.2/2.3 |

### 10.1 Review round 1 — where each finding landed

| Finding | Disposition | Sections revised |
|---|---|---|
| F1 — invalid action step (`emits`, no `params.output`) | **Accepted; reproduced in sandbox.** `gates` verified to compose, so `citation-check` stays put | §3.3 (+transcript), AC-5.4/5.4b |
| F2 — policy resolution was model-performed | **Accepted.** Moved into wave.js as code | §4.1, §4.2, §4.3, AC-2.1/2.2/2.2b/2.7, AC-3.5, R9 |
| F3 — base-tier diamond ungated | **Accepted; algorithm conforms to policy.toml.** No corpus edit; predicates defined | §4.3 step 6, §4.3.1, AC-2.2 |
| F4 — requested-side write named no verb | **Accepted.** Rerouted through `complete --metadata` relay; corollary widened to failed steps | §3.1, §4.3 step 9, §4.4, AC-2.4 |
| F5 — stop-guard inertness only [ASSUMED] | **Accepted.** Promoted to an AC | AC-4.7, R7 |
| F6 — hook names vs `docket-*` reservation | **Accepted.** Files prefixed; tmp-guard exempted with cause | §4.5, AC-1.3 |
| F7 — "stable path" unnamed | **Accepted.** Path named; Bash-denied constraint in AC text | §5.1, AC-1.1/1.1b |

Two findings surfaced *by* the revision and recorded rather than absorbed: the
reviewer's suggested TOML one-liner does not run on this machine (§4.1's
evidence), which forced the parse into wave.js and created R10; and the
unpatched `spec-doc.toml` registers fine, so DKT-60 is an AC-2 conformance fix,
not a registration repair (§3.3).
