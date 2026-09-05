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
- Validation at `step record`
- `docket schema` refusals

## Workflow: Payload schemas (`docket schema`)

A step can declare `payload = "name@version"`. That names a **payload schema**:
a JSON Schema document you register, against which the step's `--payload-file`
is checked, and — this is the part that matters — the place where **order comes
from**.

Docket's threshold predicates include ordered comparisons: `any(risk >= medium)`.
Docket does not know that `medium` outranks `low`. It knows it because your
schema said so.

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
| The order **is** the `enum` array, as written, ascending | there is no second list to disagree with it, and adding a value to `enum` cannot leave the order stale |
| `ordered_enum` must sit beside an `enum` of **at least two unique strings** | otherwise it is a `VALIDATION_ERROR` naming the property path |
| It constrains **nothing** | a document that validated before the annotation validates after it; the annotation declares position, not a new rule |
| Only **top-level properties of the array's item schema** are indexed | that is exactly what a threshold predicate's bare field token can name |

Docket learns *position*, never *significance*. It does not know which end of
your order is worse, more urgent, or better — and it never has to. A median over
a declared order is the same computation for risk levels, priorities, tiers,
T-shirt sizes, or ripeness grades.

A payload is an array of objects. A schema over it is therefore usually
`{"type": "array", "items": {"type": "object", …}}` — and a document that is not
that shape still registers, it simply declares nothing a threshold can name.

### The `conservative_end` annotation

Docket learns position, never significance — but *an order can know its own bad
end even when docket cannot*. One optional key says which one it is:

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
| The value is `"upper"` or `"lower"` — **positions in the ascending `enum`**, never the values it holds | `"high"` is a `VALIDATION_ERROR`: it is a member of *this* enum and could not name an end of any other |
| It must sit beside `"ordered_enum": true` | a direction names an end of an order; declared over an unordered field it is a `VALIDATION_ERROR` naming the property path, not a silently-ignored key |
| It is **optional**, and absent means `"lower"` | every schema written before this key existed computes exactly what it did before |
| It changes exactly one decision: the **even-count median tie** | it does not reach `min`, `max`, an odd-count median, a threshold predicate, `spread`, or a hold |

Declare it on a severity, a priority, or any order where a tie should fall on
the cautious side; leave it off for a confidence, a ripeness, or a tier, where
the two central values are simply two values and neither end is "bad". A
direction is not part of the order, so adding one to a schema does not change
what any threshold predicate compares — only which of two tied medians is taken.

### Registration is content-addressed and immutable

Exactly as workflows are:

| Second registration of… | Result |
|---|---|
| the same bytes | success, returns the existing row, changes nothing |
| **different** bytes at the same `name@version` | `CONFLICT` (exit 4), naming both hashes |
| any bytes at a new `version` | an ordinary registration |

To change a schema, register a new version. This is not ceremony: a schema
decides whether a worker's payload is *accepted*, so a mutable `risk-report@1`
would change a running job's acceptance criteria mid-flight. A workflow that
wants the new schema declares it and bumps its own `[pipeline].version`.

Registering `risk-report@2` does nothing to a workflow that declares
`payload = "risk-report@1"`. Version references are exact.

### Register schemas before the workflows that name them

A workflow declaring `payload = "risk-report@1"` is **checked against the
registered schema when you register the workflow**, not later:

| Check | What it refuses |
|---|---|
| the schema is registered | `payload` naming something absent — with the `docket schema register` line to run |
| the field exists | `any(rsk >= medium)` when the schema declares `risk`, listing what it does declare |
| the literal is valid | `any(risk == severe)` when the enum is `low, medium, high` |
| ordered means ordered | `any(stage >= final)` when `stage` declares an `enum` but no `ordered_enum` |

So register schemas first. A workflow that could never route correctly should
not register at all — the alternative is discovering a typo hours into a run, on
a step whose work is already done.

**Auto-registration already does this for you.** Activation registers everything
under `.docket/config/schemas/` before anything under `.docket/config/workflows/`,
so a workflow and the schema it names can live side by side in the same tree and
the ordering is never yours to arrange. The rule above matters when you register
by hand, and as the reason the auto-registration order is what it is.

**A threshold on a step with no `payload` is untouched by all of this.** It is
grammar-checked and nothing more, and at runtime an ordered comparison over a
field with no declared order parks the step for a human rather than guessing.
`any(status == unmet)` never needed a schema to be correct, and still does not:
equality has never needed an order.

### The one shipped schema

`docket schema list` reports one row in a fresh repo:

```
aggregate@1                  1e0a0be39394  builtin
```

`aggregate@1` ships with docket and describes the output of the builtin
`aggregate` action step. It is inert unless such a step runs, and nothing else
in the registry arrives without someone registering it.

### Validation at `step record`

A step that declares `payload = "name@version"` has its `--payload-file`
validated by `step record` (`complete` is an identical alias). A successful
recording can still yield failed gates or waiting-human routing; payload
acceptance alone does not establish that the work passed. A validation
refusal looks like:

```
Error: step assess@0: payload does not satisfy risk-report@1:
  payload[3].risk: value "urgent" is not one of ["info","low","medium","high","blocker"]
  (+2 more)
```

Three things about that refusal are deliberate:

- **It is path-precise.** `payload[3].risk` is the element and the property, in
  the notation the file itself is written in. "The payload is invalid" would be
  something a worker can only re-submit against blindly.
- **It is capped at five lines.** A worker's log is not improved by a hundred,
  and the count of what was dropped is reported so you know the list is partial.
- **It validates against the bytes the RUN PINNED**, not against whatever the
  registry holds now. Two runs of the same work at the same pins reach the same
  verdict on the same payload.

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
| `schema show` on an unregistered name or version | `NOT_FOUND` | 2 |
| `--payload-file` fails the step's declared schema at `step record` | `VALIDATION_ERROR` | 3 |
| `--payload-file` omitted on a step that declares `payload` | `VALIDATION_ERROR` | 3 |

---

