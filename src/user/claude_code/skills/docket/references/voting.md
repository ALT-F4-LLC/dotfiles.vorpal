# Votes and workflow gates

Read this when casting an assigned seat’s vote, authoring a vote rule, or
interpreting a workflow vote’s routing. For exact flags, use
[the CLI reference](../reference.md).

Find the relevant heading before reading a large section:

- Workflow: Voting (`docket vote`, consensus proposals)

## Workflow: Voting (`docket vote`, consensus proposals)

**A workflow step can open one of these.** A `type="vote"` step creates a
proposal when it becomes ready, fans out to the voters it names, and routes on
the outcome — `approved` passes the step, `rejected` routes per its `on_fail`,
which such a step must declare explicitly (V13a). `waiting-human` is legal there
and means *escalate to an operator*, unlike on a human gate where it is refused.
The proposal's id rides on the step row as `proposal`, and the roster as
`voters`, so a caller holding a `next` row can cast without reading the pinned
definition. Nothing about the machinery below changes: voters cast with the same
`docket vote cast` shown here, the tally is the same weighted score and quorum,
and there is **no new verb**. The step names a `vote_rule`, which is a pair of
`vote.rule.<name>.*` config keys, and `required_voters` is the length of its own
`voters` list. Nothing casts a vote automatically — a voter is a person or a
process running the CLI.

Create a proposal:

```bash
docket vote create --json=v2 \
  -d 'Adopt Result<T,E> for all internal/db error returns' \
  -r 'Panics currently propagate uncaught in 3 call sites' \
  -c high -n 3 --threshold 0.67 \
  --domain-tags 'database,error-handling' \
  --files-changed 'internal/db/issue.go,internal/db/doc.go'
```

Cast only the assigned seat’s own assessment. Pass its exact `--voter`: the
default is `git user.name`, so concurrent agents using the default collide
under one identity. Verify the roster, proposal, content, and assessment
before casting; there is no amendment path. Replace the values below with
the actual assignment and evidence. A file keeps long rationale out of argv:

```bash
docket vote cast DKT-V1 --json=v2 \
  --voter seat-security --role reviewer \
  -v approve --confidence 0.9 --domain-relevance 0.8 \
  --summary-file /tmp/seat-security-summary.md
```

`--metadata` is optional and opaque. Populate model and effort fields only
from observed runtime facts; do not infer a model from a role or fabricate
measurements. `--usage` records this seat’s own measured spend; a relay may
backfill usage after observing it. Consult the CLI reference for those flags.
Treat the value as public — it is visible to anyone who can list processes, it
is stored verbatim in the store, and `docket export` re-emits it verbatim with
no redaction. It reads back through `vote show --json`, `vote result --json`,
and the export document; the human-readable tables do not render it.

Valid `--verdict`/`-v` values: `approve`, `approve-with-concerns`, `reject`.
Valid `--criticality`/`-c` values: `low`, `medium`, `high`, `critical`.
`--confidence` and `--domain-relevance` are floats in `[0.0, 1.0]`.

Inspect the outcome and link the proposal as needed:

```bash
docket vote show DKT-V1 --json=v2
docket vote result DKT-V1 --json=v2
docket vote list --json=v2 --all               # default: open proposals only
docket vote link DKT-V1 --json=v2 --issue DKT-1
docket vote unlink DKT-V1 --json=v2 --issue DKT-1
```

`vote commit` records an authorized out-of-band decision and bypasses the
normal workflow threshold. It is not a routine finalization step after agent
casts. `vote close` retires an open proposal whose decision happened another
way; use it only after that actual decision. Neither verb grants authority to
override a human-only matter.

**A vote step may add a `threshold`, evaluated over the cast set once an
approved tally comes back — before the step is allowed to route `pass`**.
It reads the same predicate grammar `threshold` uses on gate steps,
but over the cast's own fields: `vote` / `verdict` (aliases for the same
field) and `voter`. Only `==`/`!=` are legal — casts carry no registered
schema, so an ordered comparison (`>=`, `>`, …) is refused at register time
(V36). Routing is restricted to `fix-loop`, `waiting-human`, `pass` — no
step-name interposition on a vote gate.

```toml
[[step]]
name = "gate"
type = "vote"
voters = ["seat-a", "seat-b", "seat-c"]
vote_rule = "majority"
on_fail = "waiting-human"
threshold = { "fix-loop" = "count>=2(vote == approve-with-concerns)" }
```

A **rejected** tally is untouched — it still routes per `on_fail`, threshold
or not. A **committed** proposal (an operator's manual `vote commit`) skips
the threshold too — that decision was made out of band. A step declaring no
`threshold` behaves exactly as before. `approve-with-concerns` has always
tallied as a full approval weight; what's new is only this post-approval
routing check, not the tally math. The step's own recorded tally is readable
downstream as an input — see [engine-produced inputs](workflows.md#engine-produced-inputs).

---

