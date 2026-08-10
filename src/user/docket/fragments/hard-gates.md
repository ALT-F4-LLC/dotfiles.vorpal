---
fragment: hard-gates
version: 1
---
# Hard gates G1–G5

Five narrow, **mechanically detectable** symptoms that outweigh feature correctness. They
fire only on the objective symptom — the moment a gate needs a judgment call to fire, it
is not a gate finding but an ordinary one under the dimension rubric. Read the
counter-examples as carefully as the patterns: a gate that fires on a correct construct
costs more trust than one that misses.

**G1 — Swallowed error.** A `catch`/`rescue`/`except` with no rethrow AND no logged
context AND no meaningful handling, on a path touching untrusted input, network, or
persistence. Patterns: an empty catch; a catch whose body is a comment; a discarded
error result (`_ = err`, `_, _ := …`); `.unwrap()` / `.expect()` / a bare force-unwrap on
data the function does not control. **Not fired by** deliberate panics on programmer-error
invariants, where a clear stack is the right move.

**G2 — Unguarded shared mutation.** Shared or module-global mutable state accessed with
no lock, channel, actor, or single-owner pattern. **Not fired by** mutex/atomic-guarded
access, message passing, single-owner tasks, or local mutation whose result escapes as a
new value.

**G3 — Unparsed boundary input.** Untrusted input — HTTP body, query, or header; env var;
CLI arg; queue payload; DB row; third-party response; file off disk — consumed without a
schema parse into a precise type at first contact. **Not fired by** data flowing through
internal calls after it was parsed once at the boundary.

**G4 — Surface-not-invariant patch.** A fix papering over an edge case instead of
addressing the underlying contract. Patterns: a null check added where the real bug is
upstream data of the wrong shape; a retry loop around a non-idempotent operation;
defensive guards masking an invariant violation; a snapshot or test updated to make a
failing case pass without diagnosing why. Firing this one requires reading the issue to
learn what the code was supposed to *uphold*.

**G5 — Unexecuted verification regex.** A change introduces or modifies a regex meant to
gate verification, with no evidence it was run against the actual target. Patterns: the
pattern assumes plain text where the target carries markup (bold markers insert
characters between word and colon); literal adjacency required where the target has
intervening words; an expected hit count that does not match the real one; a
basic-regex pipe treated as alternation when it is a literal character. An unexecuted
verification pattern is a broken gate that reports success.

**Override recognition.** Before raising any gate finding, look at the change and its
adjacent lines for an explicit override marker naming the principle the author knowingly
set aside, in any comment syntax. When one is present, that occurrence is not a gate
finding: report the override verbatim with its location and stated reason, in its own
section of your artifact. An override is **surfaced, never silently honored** — whoever
reads your artifact decides whether the reason holds. Note that in this system an
override may equally live outside the code, attached to the work item; treat a marker
you cannot find as absent rather than assumed.

**A gate finding names five things:** the location, which gate, the symptom observed, the
required mitigation, and — where the symptom is subtle — why the counter-example does not
apply. Hitting a hard gate is the review system working; report it plainly and at full
severity.
