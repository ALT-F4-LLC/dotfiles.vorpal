# Payload schemas

Read this when authoring or changing payload validation, enum ordering, or
aggregation tie behavior. For exact command flags, use
[the CLI reference](../reference.md).

Find the relevant heading before reading a large section:

- Workflow: Payload schemas (`docket schema`)
- The `ordered_enum` annotation
- The `conservative_end` annotation
- Registration is content-addressed and immutable
- Register schemas before the workflows that name them
- The one shipped schema
- Retiring a schema version (`docket schema deprecate`)
- Validation at `step record`
- `docket schema` refusals

## Workflow: Payload schemas (`docket schema`)

A step can declare `payload = "name@version"`. That names a payload schema: a
JSON Schema document you register, against which the step's `--payload-file`
is checked, and the place where order comes from.

Docket's threshold predicates include ordered comparisons: `any(risk >=
medium)`. Docket does not know that `medium` outranks `low`; it knows because
your schema said so.

```bash
docket schema register risk-report@1 .docket/config/schemas/risk-report.json --json=v2
docket schema list --json=v2
docket schema show risk-report@1 --body
```

### The `ordered_enum` annotation

An ordinary JSON Schema, plus one key:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "array",
  "items": {
    "type": "object",
    "properties": {
      "risk": {
        "type": "string",
        "enum": ["info", "low", "medium", "high", "blocker"],
        "ordered_enum": true
      }
    },
    "required": ["risk"]
  }
}
```

| Rule | |
|---|---|
| The order is the `enum` array, as written, ascending | no second list to disagree with it; adding a value to `enum` cannot leave the order stale |
| `ordered_enum` must sit beside an `enum` of at least two unique strings | otherwise `VALIDATION_ERROR`, naming the property path |
| It constrains nothing | a document that validated before the annotation validates after it; the annotation declares position, not a new rule |
| Only top-level properties of the array's item schema are indexed | that is exactly what a threshold predicate's bare field token can name |

A payload is an array of objects, so a schema over it is usually
`{"type": "array", "items": {"type": "object", …}}`. A document that is not
that shape still registers; it declares nothing a threshold can name.

### The `conservative_end` annotation

One optional key names which end of the order a tie falls toward:

```json
"risk": {
  "type": "string",
  "enum": ["info", "low", "medium", "high", "blocker"],
  "ordered_enum": true,
  "conservative_end": "upper"
}
```

| Rule | |
|---|---|
| The value is `"upper"` or `"lower"`, positions in the ascending `enum`, never the values it holds | `"high"` is a `VALIDATION_ERROR`: it is a member of this enum and could not name an end of any other |
| It must sit beside `"ordered_enum": true` | declared over an unordered field it is a `VALIDATION_ERROR` naming the property path, not a silently-ignored key |
| It is optional, and absent means `"lower"` | every schema written before this key existed computes exactly what it did before |
| It changes exactly one decision, the even-count median tie | it does not reach `min`, `max`, an odd-count median, a threshold predicate, `spread`, or a hold |

Declare it on a severity, a priority, or any order where a tie should fall on
the cautious side. Leave it off for a confidence, a ripeness, or a tier,
where the two central values are just two values and neither end is "bad". A
direction is not part of the order: adding one changes only which of two
tied medians is taken, never what a threshold predicate compares.

### Registration is content-addressed and immutable

Exactly as workflows are (same bytes: idempotent success; different bytes
at the same `name@version`: `CONFLICT`, exit 4, naming both hashes; any
bytes at a new `version`: an ordinary registration) — see [workflow
registration](workflows.md#registration-is-content-addressed-and-immutable).

To change a schema, register a new version. A workflow that wants the new
schema declares it and bumps its own `[pipeline].version`. Registering
`risk-report@2` does nothing to a workflow declaring `payload =
"risk-report@1"`; version references are exact.

### Register schemas before the workflows that name them

A workflow declaring `payload = "risk-report@1"` is checked against the
registered schema **when you register the workflow**, not later:

| Check | What it refuses |
|---|---|
| the schema is registered | `payload` naming something absent — with the `docket schema register` line to run |
| the field exists | `any(rsk >= medium)` when the schema declares `risk`, listing what it does declare |
| the literal is valid | `any(risk == severe)` when the enum is `low, medium, high` |
| ordered means ordered | `any(stage >= final)` when `stage` declares an `enum` but no `ordered_enum` |

Register schemas first. Auto-registration already does this: activation
registers everything under `.docket/config/schemas/` before anything under
`.docket/config/workflows/`. The rule matters only when you register by
hand.

A threshold on a step with no `payload` is untouched by this: it is
grammar-checked and nothing more, and at runtime an ordered comparison over a
field with no declared order parks the step for a human rather than
guessing. `any(status == unmet)` never needed a schema to be correct;
equality has never needed an order.

### The one shipped schema

`docket schema list` reports one row in a fresh repo:

```
aggregate@1                  1e0a0be39394  builtin
```

`aggregate@1` ships with docket and describes the output of the builtin
`aggregate` action step. It is inert unless such a step runs; nothing else in
the registry arrives without someone registering it.

### Retiring a schema version (`docket schema deprecate`)

A registered schema is never deleted. `deprecate` retires one version from
service, the schema half of `workflow deprecate`:

```bash
docket schema deprecate risk-report@1 --json=v2
docket schema deprecate risk-report@1 --json=v2 --restore   # back into service
docket schema deprecate canary@1 --project DOT              # another project
docket schema deprecate canary@1 --all-projects             # every project, per-project outcomes
```

The row survives: `schema show risk-report@1` still renders it (with a
`status: DEPRECATED` line), `--body` still emits the registered bytes, and a
run that already **pinned** it keeps validating payloads against it. What
stops is **new references**: `workflow register`, `workflow lint`, and
activation's auto-registration refuse a step whose `payload` names a retired
version, naming the schema and the `--restore` remedy. `schema list` hides
retired versions unless `--deprecated`; a bare `schema show NAME` resolves the
highest version still in service. `docket registry audit` reports an orphaned
schema whose every version is retired as `retired: true`.

Two refusals the workflow verb lacks. A version that a workflow **still in
service** names as `payload` is refused with `CONFLICT`, listing the
referencing `name@version`s; there is no override, so retire or re-version
those workflows first (a retired workflow does not block). The builtin
`aggregate@1` cannot be retired, since it is visible to every project. Under
`--all-projects` each project reports its own outcome: `deprecated`,
`already-deprecated`, `not-registered`, or `in-use`. The report carries
`ok: true` even when a project failed; the exit code and `failed` count are
the verdict, so an `already-deprecated` project exits 4.

Needs docket `nightly-209` or later; the store migrates to schema version 36
on first open.

### Validation at `step record`

A step that declares `payload = "name@version"` has its `--payload-file`
validated by `step complete` (`record` is an identical alias). A successful
recording can still yield failed gates or waiting-human routing: payload
acceptance alone does not establish that the work passed. A validation
refusal looks like:

```
Error: step assess@0: payload does not satisfy risk-report@1:
  payload[3].risk: value "urgent" is not one of ["info","low","medium","high","blocker"]
  (+2 more)
```

The refusal is path-precise (`payload[3].risk` names the element and
property), capped at five lines with the dropped count reported, and
validated against the bytes the run pinned, not whatever the registry holds
now.

Authorization is checked first, always: a caller that does not hold the step's
token gets `AUTH_ERROR` and learns nothing about the schema.

### `docket schema` refusals

| Situation | Code | Exit |
|---|---|---|
| Schema file not found or unreadable | `NOT_FOUND` | 2 |
| Reference is not `name@version` with a version ≥ 1 | `VALIDATION_ERROR` | 3 |
| Malformed JSON, or a document that does not compile as JSON Schema | `VALIDATION_ERROR` | 3 |
| `ordered_enum` without a usable sibling `enum` | `VALIDATION_ERROR` | 3, naming the property path |
| Re-registering different bytes at an existing `name@version` | `CONFLICT` | 4 |
| `schema show` on an unregistered name or version, or a bare name whose every version is retired | `NOT_FOUND` | 2 |
| `schema deprecate` on an already-retired version | `CONFLICT` | 4 |
| `schema deprecate` on a version a workflow still in service names as `payload` | `CONFLICT` | 4, listing the referencing workflows |
| `schema deprecate` on the builtin `aggregate@1` | `VALIDATION_ERROR` | 3 |
| `schema deprecate` on an unregistered name or version | `NOT_FOUND` | 2 |
| `workflow register` or `workflow lint` naming a retired schema as `payload` | `VALIDATION_ERROR` | 3 |
| `--payload-file` fails the step's declared schema at `step record` | `VALIDATION_ERROR` | 3 |
| `--payload-file` omitted on a step that declares `payload` | `VALIDATION_ERROR` | 3 |

---

