# The 12 principles through the simplification lens

The authority is the **Code Quality & Craftsmanship** section of
`~/.claude/agents/senior-engineer.md` (repo: `src/user/claude-code/agents/senior-engineer.md`)
— this table is a lookup aid mapping each numbered principle to its simplification move,
never a substitute.

| # | Principle | Simplification lens |
|---|---|---|
| 1 | Abstract by concept, not by count | Collapse a wrong/coincidental abstraction back inline; OR name a real repeated concept. Same text ≠ same concept. |
| 2 | A name predicts behavior — correctly | Rename a lying/vague name so the reader need not open the definition. |
| 3 | Length isn't the rule; cohesion is | Drop scaffolding around a single nameable concept; split a function that does more than one thing. |
| 4 | Local mutation fine; shared mutation requires an explicit seam | Replace ad-hoc shared mutation with a return value / explicit seam. |
| 5 | Parse, don't validate — at every external touchpoint | Replace scattered re-validation with one parse-at-the-edge; stop re-checking already-typed data midstream. |
| 6 | Errors propagate; boundaries handle | Delete a try/catch that only rethrows; let errors propagate to the boundary. |
| 7 | Comments justify their existence — refactor before annotating | Where a *redundant* comment props up unclear code, the *refactor* (better name / smaller function / named constant) is the finding — never "add a comment." A minimal informative comment (non-obvious *why*, `simplify:` marker) is not a finding. |
| 8 | Tests pin behavior through the seam | Replace interaction assertions / internal-collaborator mocks with outcome assertions. |
| 9 | Minimal diff is the default | Flag dead code, commented-out blocks, and unrequested scope that can be removed. |
| 10 | Deps for commodity plumbing; write your domain | Replace a hand-rolled commodity (date math, parsing) with the boring stdlib/dep; OR drop a trivial dep (left-pad rule). |
| 11 | Solve the actual invariant, not the surface | Replace symptom-masking guards with the real contract. (Clarity lens only — correctness gating is `code-review-verdict`.) |
| 12 | Deletability is the outcome | Narrow a public surface; remove registration-by-side-effect / reflection reach so `grep` can be trusted. |

## Calibration example pair

**DO flag — idiomatic form is clearer AND shorter** (`cart.ts:42`):

```
function hasItems(cart) {
  if (cart.items.length > 0) {
    return true
  } else {
    return false
  }
}
```

→ `return cart.items.length > 0` — the branching is scaffolding around a single boolean
value; the rewrite states the value directly (principle #3).

**DON'T flag — terser form is harder to scan** (`grade.ts:10`): a guard-clause ladder
(`if (score >= 90) return "A"; ...`) can be packed into a nested ternary one-liner. Do NOT
flag it: each branch of the ladder is independently obvious; the ternary packs the same
logic into a denser line the reader must unwind. Fewer lines, worse clarity — the
multi-line form is already the idiomatic, scannable one.
