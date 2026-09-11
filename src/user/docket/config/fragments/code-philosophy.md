---
fragment: code-philosophy
version: 7
---
# Code philosophy

Optimize for **being correct** and **being deletable**. Prefer the smallest clear
implementation that fully satisfies the real contract. Account for the
code left to maintain, including anything the change makes obsolete. The unifying
principle is **locality of reasoning**: a reader can understand a unit from its
implementation and immediate contracts, without tracing the whole program.
Guards, layers, and abstractions must serve a concrete need. Before deleting a
guard, establish which enforced guarantee makes it redundant; a presumed happy
path is not a contract.
Apply these defaults in the language's idiom and within the task's scope.

1. **Abstract by concept, not by count.** Same text does not imply the same
   concept. When the relationship is unclear, prefer duplication to coupling.
   Extract around a coherent responsibility with an independently meaningful
   name. The extraction must improve local reasoning or centralize a policy
   shared by current callers. A plausible name or repetition count alone does
   not justify an abstraction.
2. **A name predicts behavior, correctly.** Names should communicate purpose,
   relevant effects, and results. Prefer domain language to generic labels;
   express invariants in types where practical. Name length scales with scope.
   Names that lie are worse than vague ones.
3. **Length isn't the rule; cohesion is.** Split code when it combines independent
   responsibilities or obscures abstraction levels. Around 50 lines is a prompt
   to inspect, never a cap; a 200-line protocol parser can be one honest concept.
   A name containing "and" is a clue, not proof that a function needs splitting.
4. **Local mutation is fine; shared mutation needs explicit ownership.** Keep
   state and its lifetime locally understandable. Where state must be shared,
   make its owner, permitted mutations, and synchronization or transaction rules
   explicit. Protect the whole invariant, not merely individual accesses. Avoid
   ambient mutable globals.
5. **Parse at trust boundaries; preserve the guarantees.** Turn untrusted input
   into values whose construction establishes the required guarantees, using
   precise types where practical. Do not substitute annotations or unchecked
   casts for runtime checks.
   Interior code relies on guarantees that remain valid, without repeating those
   checks. Enforce authorization and conditions that depend on changing state at
   the operation that requires them. Reuse schemas for the same semantic
   contract, not merely the same shape.
6. **Errors propagate; capable boundaries handle them.** Use the language's
   idiomatic error channel. Handle errors where meaningful recovery, translation,
   or missing diagnostic context is possible; otherwise preserve and propagate
   them. Keep catches narrow and retain the cause. Assign logging to one
   responsible boundary. Broken invariants fail visibly at the appropriate
   isolation boundary, without continuing in invalid state. Never turn an
   unhandled failure into apparent success.
7. **Write code that needs no comments.** Do not add explanatory comments,
   docstrings, or section banners. Express intent through precise names, useful
   types, and direct control flow. Simplify unclear code before explaining it;
   do not add helpers or layers merely to avoid a comment. Put necessary
   rationale in the change summary. Preserve required tooling directives and
   repository-required notices.
8. **Tests pin behavior through the seam.** Tests should survive refactoring that
   preserves the contract. Arrange only what the behavior depends on; assert
   observable results and effects. Assert an interaction's occurrence, absence,
   count, or order when that is itself part of the contract. Prefer real internal
   collaborators; use test doubles at external boundaries. Prefer extending
   existing tests and fixtures; size new tests to distinct changed behaviors and
   credible regressions. Avoid coupling tests to incidental internal calls.
9. **Minimal scope; minimal maintained code.** Once the design search has
   weighed the alternatives, find and modify the existing implementation before
   adding another path. New helpers, layers, configuration
   options, and fallback behavior require a concrete need in the requested
   change. Remove superseded code and configuration; update affected tests while
   preserving relevant coverage. Retain compatibility paths only for a supported
   contract. Touch adjacent code only when necessary for a complete, clear fix.
   Include necessary callers, focused tests, and documentation. Report unrelated
   cleanup separately. Preserve clarity and correctness; do not compress code or
   delete unrelated functionality to improve a line count.
10. **Deps for commodity plumbing; write your domain.** Prefer the standard
    library or established dependencies for commodity problems. Write domain
    policy yourself; skip dependencies for trivia. Use maintained implementations
    for cryptography, TLS, and standard formats or protocols. A parser for a
    language or format that is itself your domain can belong in your codebase.
11. **Solve the actual invariant, not the surface.** Establish the contract from
    requirements, relevant callers, implementation, and tests. Resolve the cause
    of the failure instead of merely satisfying the test text. When the evidence
    disagrees, surface the conflict; do not invent a stricter contract or silently
    change supported behavior. Correctness takes priority over diff size.
12. **Deletability is the outcome.** Keep the blast radius small and discoverable:
    cohesive units, explicit dependencies, owned state, contracts at seams, and a
    narrow public surface. Make initialization, registration, and cleanup easy
    to locate. Prefer explicit wiring; localize framework-required registration.
    Check relevant callers, configuration, and external contracts before deletion;
    a text search alone does not prove something is unused.

**Harness use.** Use the harness proactively throughout development. Discover
relevant capabilities available in the current environment and apply them
without waiting to be asked: skills and project workflows for established
procedures; code intelligence and diagnostics for navigation and feedback;
connected tools for external systems; execution and browser tools to exercise
behavior. Consult current tool help when needed. Prefer these capabilities to
equivalent scripts, scaffolding, or infrastructure added to the repository.

Batch independent tool calls and delegate substantial, separable work with clear
scope and expected results. Use worktrees when concurrent edits need isolation,
keep coupled work together, and continue useful local work while delegated tasks
run. Integrate their results. Use supported task, context, and session mechanisms
to retain decisions and progress.

Use existing hooks and automation for recurring mechanical work. Improve harness
configuration when an observed recurring need justifies it and the change is
within scope. Keep scratch checks and coordination out of permanent project
code. Choose capabilities for faster, more reliable completion; skip setup,
orchestration, or repeated review that costs more than it saves.

**Overrides.** These are defaults to apply with judgment, not approval gates.
Make routine tradeoffs yourself. For a material deviation introduced by the
change, name the principle, location, the alternatives compared, and one-line
reason in the change summary so review can challenge it. Do not add source
comments merely to report compliance
or exceptions.

**Project idiom.** Follow explicit task and repository requirements. Match local
idiom where it serves the contract; distinguish existing habits from required
behavior. Use these principles to evaluate patterns and explain concrete
conflicts, without silently replacing a required contract or architecture.
