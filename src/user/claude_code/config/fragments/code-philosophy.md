---
fragment: code-philosophy
version: 1
---
# Code philosophy

Senior code optimizes for *being correct* and *being deletable*; junior code optimizes
for *looking careful* (more guards, layers, abstraction). The smallest diff addressing
the real invariant beats the thorough-looking one. The unifying principle is **locality
of reasoning**: a reader understands code from itself and its immediate contract, with
no whole-program tracing. Junior tells — premature abstraction, defensive guards on
impossible inputs, try/catch around single lines, comments restating code, mocks of
internal collaborators — are anxiety made structural; delete the speculative thing and
trust the contract. Apply all of this per the language's grain.

1. **Abstract by concept, not by count.** Same text ≠ same concept. When unsure,
   duplicate. Extract when the helper has an independently meaningful name mapping to a
   real concept; reject mechanical rules like "rule of three."
2. **A name predicts behavior — correctly.** Predict what a thing returns without
   opening it. Domain language over CS-generic; invariants in types where possible;
   name length scales with scope. Names that *lie* are worse than vague ones.
3. **Length isn't the rule; cohesion is.** Too long = does more than one thing or mixes
   abstraction levels (the name needs "and"). ~50 lines is a tripwire, never a cap; a
   200-line protocol parser is one honest concept.
4. **Local mutation fine; shared mutation requires an explicit seam.** The boundary is
   *non-locality*. Mutation that escapes destroys reasoning. Where shared mutable state
   is genuinely required, put it behind a synchronization seam — never an ambient global.
5. **Parse, don't validate — at every external touchpoint.** Data is untrusted until
   parsed into a value whose *type* encodes the checked guarantees; the interior
   consumes the precise type with no re-validation. One schema per shape.
6. **Errors propagate; boundaries handle.** Throw freely; catch deliberately only at
   boundaries, where you translate, attach context, and log once. Invariant violations
   crash with a clear stack. Rule out hardest: a catch that swallows the error.
7. **Comments justify their existence — refactor before annotating.** Code needing a
   comment to explain *what* should be refactored instead. A comment IS warranted for
   non-obvious context the code cannot hold: the *why*, a workaround rationale, a
   ceiling marker, an issue pointer. Machine-required directives are always allowed.
8. **Tests pin behavior through the seam.** Tests fail *only* when behavior breaks.
   Arrange only what the behavior depends on; assert outcomes, never interactions. Mock
   only true external boundaries.
9. **Minimal diff is the default.** Scope is a budget: touch adjacent code only when
   this change is cheaper or more correct because of it. Rot that doesn't pay rent gets
   recorded, not fixed silently. Rule out hardest: the silent opportunistic rewrite.
10. **Deps for commodity plumbing; write your domain.** Take a dep for commodity
    problems; write it yourself where the code IS your domain. Prefer boring; skip deps
    for trivia. Rule out NIH on crypto/TLS/parsing.
11. **Solve the actual invariant, not the surface.** Code that works but ignores the
    underlying invariant is wrong — it just hasn't failed yet. A patch masking a symptom
    is not a fix. Ask "what's the real contract here?" before writing code that merely
    satisfies the test text. The highest-leverage principle: the others are craft, this
    one is correctness.
12. **Deletability is the outcome.** Deletable = blast radius small AND knowable:
    single-purpose units, no shared mutable state, contracts at the seams, explicit
    imports, narrow public surface, no registration-by-side-effect — so `grep` can be
    trusted. Deletability is the observable output of doing the other 11 right.

**Overrides.** These are defaults the writer applies, not gates the writer self-enforces.
When violating a principle on a specific line is right, say so explicitly in your
artifact — naming the principle, the location, and the one-line reason — so review can
challenge it rather than chase a dishonestly "satisfied" violation.

**Against project idiom.** A project spec documents the *current* idioms; these
principles are the universal grammar. Match the project idiom for surface form, but the
underlying contracts hold regardless. Where an existing pattern genuinely violates a
principle, surface it rather than diverging silently.
