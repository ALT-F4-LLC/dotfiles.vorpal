# Catalog

The patterns a declutter pass looks for, what removes each one without
changing behavior, and how the removal is proven safe. Human-written and
generated code produce the same cruft; the entries note where a pattern is
measured to be more common in generated code, because that is where the
scout should look first.

Every entry carries a proof class the skill's §2 applies:

- `inert`: the edit cannot change runtime behavior. Comments, dividers, a
  suppression the linter no longer needs, a cast the type checker no longer
  needs. Build and typecheck must still pass; no test is required.
- `reachability`: removal of code nothing can execute. Proven statically as
  the [gates reference](gates.md#reachability-proof) describes; no probe.
- `probe`: a transformation of live code. The site must fail a mutation
  probe first, then build, typecheck, and the full suite must pass after.

Each entry: Signal, Why, Simplification, Risk, Proof, Source. A source
marked `unsourced` is practitioner consensus the research found no primary
source for. The last two sections list what the scout reports but the
worker never touches, and what looks like cruft and is not.

## Evidence that generated code is where to look

- GitClear's report over 211 million changed lines (2020 to 2024) found
  copy-and-paste rising from 8.3% to 12.3% of changed lines while
  refactoring fell from about 25% to under 10%, and 2024 the first year
  copied code exceeded moved code.
  https://www.gitclear.com/ai_assistant_code_quality_2025_research
- GitClear's follow-up over 623 million changes (2023 to 2026) reports block
  duplication up 81%, error-masking constructs up 47%, cross-file function
  calls down 35%, and refactoring's share down to 3.8%.
  https://www.gitclear.com/the_ai_code_quality_maintainability_gap
- Sonar's cross-model study found code smells were over 90% of all issues
  for every model tested, with dead and redundant code and complexity
  metrics named as recurring contributors.
  https://www.sonarsource.com/company/press-releases/the-coding-personalities-of-leading-llms/
- A corpus study found generated code trends toward longer function names
  and more digit-suffixed names than human code.
  https://arxiv.org/pdf/2506.12014

## Comments and noise

### Narrating comment
- Signal: a comment that restates the statement below it. Grep
  `^\s*(//|#)\s*(Initialize|Set|Create|Return|Check|Loop|Call|Get|Increment)\b`
  and compare with the next line.
- Why: reading volume with no information, and it rots the moment the code
  changes without it.
- Simplification: delete it. Keep a comment only when it explains intent, a
  constraint, or a reason the code cannot express.
- Risk: a comment that cites an external reason (a regulation, a vendor
  quirk) is load-bearing. Delete only when the comment references nothing
  but the adjacent code.
- Proof: `inert`.
- Source: https://managed-code.com/blog-post/ai-slop-in-code names comments
  that restate what code does as a generated-code pattern.
  https://sive.rs/book/PoSD summarizes Ousterhout: comments should carry
  what the code cannot.

### Section-divider banner
- Signal: `^\s*(//|#|/\*)\s*[-=*#]{5,}`, often bracketing a titled block.
- Why: visual noise that indentation and function boundaries already
  provide.
- Simplification: delete the banner. If the block needs a seam, extract a
  named function instead of decorating it.
- Risk: none for deletion.
- Proof: `inert`.
- Source: https://github.com/dabit3/deslop lists section-divider comments.

### Restated docstring
- Signal: a docstring whose text is the function name split into words
  with no parameter, return, or error detail.
- Why: costs upkeep and adds nothing beyond the signature.
- Simplification: delete it, or when the symbol is a published export,
  replace it with the parameter and return contract.
- Risk: a lint rule may require a docstring's presence; a runtime may
  expose docstrings (Python `__doc__`, help generators). Check both before
  deleting on a published export.
- Proof: `inert`.
- Source: unsourced.

### Commented-out code
- Signal: contiguous comment lines that parse as code.
- Why: version control already holds the history; the block is noise that
  invites accidental revival.
- Simplification: delete it.
- Risk: none.
- Proof: `inert`.
- Source: unsourced; stated in most style guides.

### Chatty or emoji log line
- Signal: emoji or exclamation-heavy phrasing inside a log string literal.
- Why: breaks grep-ability and log parsing; a known generated-code tell.
- Simplification: strip the decoration, keep the informational content and
  the log level.
- Risk: a dashboard or alert may match on the exact string. Search the
  repository's alerting and dashboard config for the literal first.
- Proof: `probe` when a test captures the log output, else `inert` only if
  the literal is not asserted on anywhere.
- Source: unsourced.

### Unjustified lint suppression
- Signal: `eslint-disable`, `# noqa`, `# pylint: disable`, `#[allow(...)]`,
  `@SuppressWarnings`, `//nolint` with no reason comment.
- Why: silences a signal instead of resolving it; often left because the
  generator tripped a rule it did not reconcile.
- Simplification: remove the suppression. If the linter then reports, fix
  the reported code only when the fix is itself a catalog entry; otherwise
  restore the suppression and add the reason.
- Risk: a suppression may guard a linter false positive. The linter run
  after removal is the check.
- Proof: `inert` when the linter passes without it.
- Source: https://github.com/dabit3/deslop lists lint suppressions.

### Needless type cast or type-ignore
- Signal: `as any`, `as unknown as T`, `# type: ignore`, `@ts-ignore`,
  `unsafe` blocks or `.unwrap()` wrappers added only to silence a checker.
- Why: defeats the type system exactly where it would catch a bug.
- Simplification: remove the cast or ignore. When the checker then
  reports, narrow the type properly only when that is a local change;
  otherwise leave the cast and report it.
- Risk: a cast can change runtime behavior in some languages (numeric
  narrowing, Rust `as` conversions). Only compile-time-only casts are
  inert; a numeric or pointer cast is `probe`.
- Proof: `inert` for type-erasure casts when typecheck passes without
  them; `probe` for casts with runtime effect.
- Source: https://github.com/dabit3/deslop and
  https://managed-code.com/blog-post/ai-slop-in-code list casts to any.

## Dead code

### Unused import
- Signal: an import with no reference in the file. Linters name it: pylint
  `W0611`, ESLint `no-unused-vars`, `goimports`, rustc unused warnings.
- Why: misleads readers about dependencies; a common leftover from an
  earlier draft of a generation.
- Simplification: remove it.
- Risk: a side-effect import (a module that registers a plugin, a CSS
  import, a polyfill) looks unused and is not. Check the imported module for
  top-level effects before removing.
- Proof: `reachability`.
- Source: https://pylint.readthedocs.io/en/v3.2.7/user_guide/messages/warning/unused-import.html;
  https://dev.to/137foundry/5-open-source-linters-and-static-analysis-tools-for-ai-assisted-codebases-1859
  notes the rule catches imports relevant to an earlier version of a
  suggestion.

### Unused function or class
- Signal: a symbol with zero references across the tree, including tests,
  templates, build scripts, and string literals.
- Why: generated as part of a task and never wired up, or superseded by a
  later edit that did not clean up.
- Simplification: delete it and its now-unused imports.
- Risk: exported symbols of a published package may have external callers;
  reflection and string-built names defeat search. The frozen-contract and
  reachability rules in the gates reference decide.
- Proof: `reachability`.
- Source: https://scanaislop.com/blog/ai-slop-in-pull-requests/ names dead
  helpers; https://refactoring.com/catalog/ Remove Dead Code.

### Unused parameter
- Signal: a declared parameter never read in the body. Linters name it:
  pylint `W0613`, ESLint `no-unused-vars` args, rustc, `staticcheck`.
- Why: misleads callers about what affects behavior.
- Simplification: remove it and update every caller. When the signature
  must match an interface, callback shape, or trait, prefix it by the
  language's convention and stop.
- Risk: a fixed-shape signature (handler, trait impl, override) cannot
  change. Check what the function implements before touching the
  signature.
- Proof: `reachability` for the parameter; the caller updates make the
  edit `probe` at each caller when the argument expression had side
  effects.
- Source: unsourced.

### Unreachable statement
- Signal: code after an unconditional `return`, `throw`, `break`,
  `continue`, `panic`, or `exit`. Linters: ESLint `no-unreachable`, rustc,
  `go vet`.
- Why: it never runs, and it reads as if it does.
- Simplification: delete it.
- Risk: none once the compiler or linter confirms it.
- Proof: `reachability`.
- Source: standard static analysis.

### Branch on a constant
- Signal: `if (true)`, `if (false)`, a condition on a variable assigned a
  literal in the same scope and never reassigned, a `switch` case for a
  value the enum no longer has. Linters: ESLint `no-constant-condition`.
- Why: a leftover from copy-pasted conditionals not adapted to the new
  context.
- Simplification: delete the dead branch; when the condition is always
  true, inline the live body in its place.
- Risk: a call inside the condition may have side effects; keep the call
  and drop only the branch when so. Constant-ness must come from the code,
  not from "this cannot happen at runtime".
- Proof: `reachability`.
- Source: https://www.gitclear.com/ai_assistant_code_quality_2025_research
  for the copy-paste correlation; standard static analysis for detection.

### Fallback for an impossible case
- Signal: a null check on a parameter the type system marks non-nullable;
  a `default` arm on an exhaustively matched enum; an `else` after every
  variant is handled.
- Why: dead code that looks live and inflates every complexity metric.
- Simplification: remove the branch when the type system proves it dead.
  When the language cannot prove it, leave it.
- Risk: deserialization, reflection, and external input can bypass the
  type checker. Only a compiler-enforced type (not a comment or a
  docstring) counts as proof. A check on data crossing a trust boundary is
  never dead; see the leave-alone section.
- Proof: `reachability`, and only with compiler-enforced types.
- Source: unsourced.

### Version shim for a retired runtime
- Signal: a branch on a runtime, library, or API version below the minimum
  the build config declares; a polyfill for a feature the minimum target
  has.
- Why: a branch that can no longer be taken, kept by inertia.
- Simplification: delete the branch for versions below the declared
  minimum; inline an adapter that now has one implementation.
- Risk: the declared minimum may lag what is deployed. The declared minimum
  in the build config is the only evidence the pass may use; when the
  repository declares none, the shim stays.
- Proof: `reachability`.
- Source: unsourced; a case of Remove Dead Code,
  https://refactoring.com/catalog/.

### Trailing redundant return
- Signal: a final `return;`, `return None`, or `return undefined;` where
  fall-through yields the same result.
- Why: a line that says nothing.
- Simplification: delete it.
- Risk: a style rule may require explicit returns; the linter run is the
  check.
- Proof: `inert`.
- Source: https://github.com/dabit3/deslop lists redundant `return
  undefined`.

## Needless indirection

### Forwarding wrapper
- Signal: a function whose whole body is one call to another function with
  the same arguments in the same order. Ousterhout's pass-through method;
  Fowler's Middle Man at the class level.
- Why: a name to remember and a hop to trace, with no behavior.
- Simplification: inline it at every caller and delete it. Where the goal
  was a namespace, re-export or alias instead.
- Risk: a wrapper that is a published export, a test seam that a test
  double replaces, or a decorator adding cross-cutting behavior (logging,
  caching, a transaction) is not a pass-through. Check the test tree for
  mocks of the name before inlining.
- Proof: `probe`.
- Source: https://sive.rs/book/PoSD (pass-through methods);
  https://managed-code.com/blog-post/ai-slop-in-code (layers that forward
  calls unchanged); https://sourcemaking.com/refactoring/smells (Middle
  Man).

### Single-implementation interface
- Signal: an interface, trait, abstract class, or protocol with exactly one
  implementer in the tree, often named `Foo` and `FooImpl`.
- Why: two types kept in sync for every change, and readers cannot jump
  from a call site to the logic, with no polymorphism to pay for it.
- Simplification: delete the interface, give the implementation the domain
  name, and retype the call sites.
- Risk: an interface that a test double implements, a plugin boundary meant
  for external implementers, or a published export stays. Search the test
  tree for a second implementer before collapsing.
- Proof: `probe` at the call sites that change type.
- Source: https://www.symphonious.net/2011/06/18/the-single-implementation-fallacy/;
  https://managed-code.com/blog-post/ai-slop-in-code names interfaces with
  one implementation as a generated-code pattern.

### Factory for one type
- Signal: a `createFoo` or `FooFactory` whose body is `new Foo(...)` with
  the same arguments every time and no branching.
- Why: a factory earns its keep by deciding something; this one decides
  nothing.
- Simplification: call the constructor at each use site and delete the
  factory.
- Risk: a factory that a test replaces to inject a fake is a seam. Check
  the test tree.
- Proof: `probe`.
- Source: unsourced; a case of the pass-through critique above.

### Builder for a fixed small shape
- Signal: a builder for an object with two or three required fields, no
  optional fields, and no cross-field validation.
- Why: ceremony over a constructor call.
- Simplification: replace with the constructor or a literal and delete the
  builder.
- Risk: none when every field is required and unvalidated; otherwise the
  builder is doing work and stays.
- Proof: `probe`.
- Source: unsourced.

### Injected dependency with one binding
- Signal: a constructor parameter or container binding for which the tree
  constructs exactly one implementation and no test substitutes another.
- Why: indirection through a container to support a swap nobody makes.
- Simplification: replace the injected abstraction with the concrete
  dependency.
- Risk: a test that fakes the dependency is the second binding. Check the
  test tree; when one exists, leave it.
- Proof: `probe`.
- Source: unsourced; follows the single-implementation reasoning above.

### Config object for a constant
- Signal: a "configuration" field, option, or environment read whose value
  is identical at every call site and set in exactly one place, with no CI,
  deployment manifest, or documentation naming it.
- Why: a knob nobody turns, carrying wiring at every layer.
- Simplification: inline the constant and remove the option.
- Risk: the highest-risk removal in this catalog. Configuration can be set
  outside the repository (deploy environments, operator runbooks). Only a
  value read in one place, set in one place, and named nowhere in CI,
  manifests, or docs qualifies; anything read from the environment at
  runtime stays, because an external setter is unobservable from the tree.
- Proof: `reachability` for the removed read path, plus `probe` at the
  site that consumed it.
- Source: unsourced; an application of Speculative Generality,
  https://sourcemaking.com/refactoring/smells.

### Lazy class
- Signal: a class or module with one field, one trivial method, or only
  delegating methods.
- Why: a file to open and a name to look up for no behavior.
- Simplification: Inline Class into its one user; Collapse Hierarchy for a
  near-empty subclass or superclass.
- Risk: a seam for tests or a published type stays.
- Proof: `probe`.
- Source: https://sourcemaking.com/refactoring/smells (Lazy Class);
  https://refactoring.com/catalog/ (Inline Class, Collapse Hierarchy).

### Single-caller trivial function
- Signal: a function with exactly one caller, no test of its own, and a
  name that says nothing the call site could not.
- Why: Carmack's argument: a boundary is where callers drift from what the
  function assumes; a function that does not exist cannot be misused.
- Simplification: Inline Function into its caller.
- Risk: this cuts against blanket extraction advice. Apply only when the
  function has one caller, no test, and no name value; a function with a
  meaningful name that shortens the caller stays.
- Proof: `probe`.
- Source: https://cbarrete.com/carmack.html (secondary summary of
  Carmack's 2014 note on inlining);
  https://refactoring.com/catalog/ (Inline Function).

### Pattern imported for one call site
- Signal: a Repository, Strategy, Observer, or Command structure introduced
  for one call site in a tree that otherwise calls directly.
- Why: the generator applied a pattern from training data regardless of
  fit; the rest of the tree does not use it.
- Simplification: replace it with the direct call style the tree already
  uses.
- Risk: the layer may carry a cross-cutting behavior (caching, a
  transaction boundary, logging). Read the whole layer before removing;
  when it does anything beyond forwarding, it is not this entry.
- Proof: `probe`.
- Source: https://managed-code.com/blog-post/ai-slop-in-code (full
  Repository patterns in projects using direct data access).

### Promise.all over one promise
- Signal: `Promise\.all\(\[[^,\]]+\]\)`, and the equivalent in other
  languages (a join over one task).
- Why: an array wrap around a single await.
- Simplification: `await p` and fix the one destructuring site.
- Risk: none once the destructuring site is updated.
- Proof: `probe`.
- Source: https://github.com/dabit3/deslop.

## Duplication

### Duplicate helper across files
- Signal: near-identical function bodies in more than one file: date
  parsing, retry wrappers, mapping helpers, string utilities. Detect by
  normalized-body comparison or a clone detector when the repository has
  one.
- Why: written by a generation that did not know the tree already had one;
  the pattern GitClear measured rising.
- Simplification: pick the canonical copy (the tested one, or the one with
  more callers), redirect every caller to it, delete the rest.
- Risk: the copies may have diverged in edge cases (defaults, null
  handling, trimming). Diff them line by line; when they differ in
  behavior, they are not duplicates and this entry does not apply.
- Proof: `probe` at every redirected caller.
- Source: https://managed-code.com/blog-post/ai-slop-in-code;
  https://www.gitclear.com/the_ai_code_quality_maintainability_gap.

### Hand-rolled standard library
- Signal: a loop or helper that does what the standard library or an
  already-imported dependency does: trim, deep clone, group-by, retry,
  path join, URL parse.
- Why: more code to maintain than a call to a tested function.
- Simplification: replace it with the library call after confirming
  identical semantics on the edge cases (Unicode whitespace, locale,
  rounding, null).
- Risk: the hand-rolled version may differ on purpose (a narrower trim
  set, a different rounding mode). When it differs, it stays.
- Proof: `probe`.
- Source: https://managed-code.com/blog-post/ai-slop-in-code.

### Duplicate code block
- Signal: identical or renamed-variable-identical blocks in two or more
  places.
- Why: a fix made in one copy and missed in the others.
- Simplification: Extract Function to one shared implementation; for
  copies differing by a value, Parameterize Function.
- Risk: Sandi Metz: duplication is cheaper than the wrong abstraction.
  Extract only when the copies mean the same thing for the same reason, so
  that a change to one should always apply to the other. Wait for three
  occurrences when two are still diverging.
- Proof: `probe` at each replaced site.
- Source: https://refactoring.com/catalog/ (Extract Function,
  Parameterize Function);
  https://sandimetz.com/blog/2016/1/20/the-wrong-abstraction;
  https://understandlegacycode.com/blog/refactoring-rule-of-three/.

### Repeated compound condition
- Signal: the same boolean expression of three or more operators in more
  than one place.
- Why: copies drift when one is updated.
- Simplification: Extract Function to name the condition once.
- Risk: short-circuit order and side effects inside the condition must be
  preserved exactly.
- Proof: `probe`.
- Source: https://refactoring.com/catalog/ (Consolidate Conditional
  Expression).

### Same concern three ways
- Signal: pagination, error formatting, or validation implemented
  differently in three or more files, each internally consistent.
- Why: each generation chose a plausible approach; the tree has no
  canonical one.
- Simplification: pick the most-used or best-tested variant and migrate
  the others to it, one file per pass.
- Risk: only structural differences qualify. Variants that differ in
  behavior are not this entry.
- Proof: `probe` per migrated file.
- Source: https://managed-code.com/blog-post/ai-slop-in-code.

## Control flow and error handling

### Explicit boolean comparison
- Signal: `=== true`, `=== false`, `== True`, `== False` against a value
  the type checker knows is boolean.
- Why: a no-op comparison.
- Simplification: `x` and `!x`.
- Risk: in a loosely typed language with `==`, the left side may not be a
  boolean. Only a checker-confirmed boolean qualifies.
- Proof: `inert` when the type is checker-confirmed; else `probe`.
- Source: https://github.com/dabit3/deslop.

### Redundant null-equivalence chain
- Signal: `x !== null && x !== undefined && x !== ''` and kin.
- Why: usually one idiomatic check.
- Simplification: collapse to the language's idiom, only after confirming
  the dropped clauses were redundant for the value's actual type.
- Risk: `0`, `false`, `NaN`, and the empty string are distinct from null in
  most languages. When the value can be any of them and the code treats
  them differently, the chain stays.
- Proof: `probe`.
- Source: https://github.com/dabit3/deslop.

### Rewrapping try/catch
- Signal: a `try` around one call whose `catch` throws a new error with
  the same message, dropping the original.
- Why: a stack frame added and the original type and trace lost.
- Simplification: remove the wrapper and let the original propagate; when
  translation to a domain error is intended, attach the original as the
  cause.
- Risk: a caller may catch the wrapper's type. Search every catch site of
  that type; when one exists, the wrapper stays.
- Proof: `probe`.
- Source: unsourced.

### Nested conditional over guard clauses
- Signal: `if` nested three or more deep with the main path at the deepest
  indentation.
- Why: the reader holds every condition at once.
- Simplification: Replace Nested Conditional with Guard Clauses: early
  returns for the edge cases, main path unindented.
- Risk: reordering guards changes which error wins when two apply.
  Enumerate the combinations before flattening; when two conditions
  overlap, keep their order.
- Proof: `probe`.
- Source: https://refactoring.com/catalog/.

### Loop that is a pipeline
- Signal: a loop that filters, transforms, and collects with manual
  accumulators.
- Why: intent hidden behind bookkeeping.
- Simplification: Replace Loop with Pipeline when the language's
  collection operations express the same stages.
- Risk: early exits, laziness, and evaluation order can change. A loop
  with `break` or `continue`, or in a hot path, stays.
- Proof: `probe`.
- Source: https://refactoring.com/catalog/.

### Debug print left in
- Signal: `console.log`, `print`, `println!`, `fmt.Println`,
  `System.out.println` with no logger and no conditional, especially
  entry/exit pairs.
- Why: clutters output and can leak state.
- Simplification: remove it, or route it through the repository's logger
  when it carries diagnostic value.
- Risk: a test may assert on captured stdout. Search the test tree for the
  literal.
- Proof: `probe` when a test captures output; `inert` only when no test
  and no script reads the output.
- Source: https://github.com/dabit3/deslop.

## Naming and shape

### Generic name
- Signal: `Manager`, `Processor`, `Helper`, `Handler`, `Util`, `Data`,
  `Info`, `Service` as a type's whole name; `enhanced`, `improved`, `new`,
  `v2`, or a digit suffix on an internal symbol.
- Why: the name says that something is done, not what.
- Simplification: rename to the responsibility, updating every caller.
  When no specific name exists, the type lacks one responsibility; report
  it rather than rename it.
- Risk: renames of published exports, serialized fields, and CLI surfaces
  are frozen.
- Proof: `probe` at the callers.
- Source: Kevlin Henney, "Seven Ineffective Coding Habits of Many
  Programmers" (secondary summary);
  https://arxiv.org/pdf/2506.12014 for the length and suffix trend.

### Mixed convention for one concept
- Signal: `userId` and `user_id` in one module for the same value.
- Why: two spellings of one thing read as two things.
- Simplification: rename to the module's dominant convention.
- Risk: as above; serialized keys are frozen.
- Proof: `probe`.
- Source: unsourced.

### Oversized single-file dump
- Signal: a file whose line count is a large outlier for the tree, holding
  several separable classes or function groups.
- Why: single-shot generations inline what belongs in separate,
  independently testable units.
- Simplification: split along existing seams into files, keeping every
  import path working through re-exports.
- Risk: module-level side effects and import order; circular imports.
  Split one seam per pass.
- Proof: `probe` at the moved units' callers.
- Source: https://asdlc.io/concepts/pr-slop/ (generated pull requests
  averaging 154% larger).

### Temporary field
- Signal: an instance field set and read inside one method only, unset the
  rest of the object's life.
- Why: a hidden state machine for one operation.
- Simplification: make it a local variable or a return value.
- Risk: any other reader of the field, even incidental, makes this a
  behavior change. Search every read.
- Proof: `probe`.
- Source: https://sourcemaking.com/refactoring/smells (Temporary Field).

### Flag argument
- Signal: a boolean parameter that selects between two behaviors, with
  every caller passing a literal.
- Why: the function is two functions.
- Simplification: Remove Flag Argument: split into two functions and
  retarget each caller by its literal.
- Risk: a caller passing a computed value keeps the flag; this entry does
  not apply then.
- Proof: `probe`.
- Source: https://refactoring.com/catalog/ (Remove Flag Argument).

## Report only

The scout names these; the worker never applies them, because the fix
changes behavior or needs a decision this loop cannot make.

- **Swallowed exception.** An empty catch, or one that only logs on a path
  where the error matters. Removing it changes behavior, and a re-test of
  120 generated samples found every flagged case was a false positive or a
  documented fallback. Report the location; never edit.
  https://dev.to/tauridev/does-ai-generated-code-silently-swallow-errors-120-measured-generations-every-flagged-case-was-a-241p
- **TODO or placeholder stub** on a reachable path (`pass`, `throw new
  Error("not implemented")`, a hardcoded stand-in). Resolving it is a
  feature. A stub on a dead path is the unused-function entry.
  https://scanaislop.com/blog/ai-slop-in-pull-requests/
- **Hallucinated API shim**: a local stub defining a method a library never
  had. Replacing it with the real call is a bug fix.
  https://snyk.io/articles/package-hallucinations/ (the same invention
  tendency, measured for package names).
- **Hollow test**: asserts `toBeDefined`, `assertTrue(true)`, or a mock's
  call count. Strengthening it needs intended behavior; deleting it lowers
  the guard. https://managed-code.com/blog-post/ai-slop-in-code
- **Feature flag read from the environment**, whatever its default. An
  external setter is unobservable from the tree.
  https://launchdarkly.com/docs/guides/flags/technical-debt
- **Complexity outlier** (cyclomatic or cognitive) whose only fix is a
  redesign. Extracting guard clauses or a named condition is a catalog
  entry; re-architecting a function is a rewrite, and the diff review
  refuses rewrites.
- **Structural smells that need design**: Large Class, Divergent Change,
  Shotgun Surgery, Feature Envy, Inappropriate Intimacy, Parallel
  Hierarchies, Temporal Decomposition, Information Leakage. Each is a real
  finding from Fowler or Ousterhout and each fix moves responsibility
  between modules, which is design work for the operator, not a pass.
  https://sourcemaking.com/refactoring/smells; https://sive.rs/book/PoSD

## Leave alone

Things that pattern-match to cruft and are not.

- **Validation at a trust boundary.** A check on user input, a request
  body, an external API response, a file the program did not write, or an
  environment value is defensive on purpose, whatever the type annotation
  says. A study found generated code more often lacks such checks than
  over-uses them. https://arxiv.org/abs/2409.19182
- **A seam a test double replaces.** An interface, factory, or wrapper that
  a test substitutes has two implementations, one of them in the test tree.
- **A decorator that adds behavior.** Thin forwarding that also logs,
  caches, retries, or opens a transaction is a decorator, not a
  pass-through.
- **A side-effect import.** Registration, polyfills, stylesheet imports.
- **Deliberate duplication.** Two copies whose divergence is on purpose,
  or a hot-path copy kept for performance with a benchmark or comment
  saying so.
- **Anything reachable by reflection, string-built names, or a plugin
  registry.** Search cannot prove it dead.
- **Explicitness a style guide requires.** Explicit returns, docstrings,
  or type annotations that the repository's linter mandates.
- **Everything the frozen-contracts list names** in the gates reference.
