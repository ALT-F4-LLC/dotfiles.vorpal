---
fragment: hard-gates
version: 5
---
# Hard gates G1–G6

Six narrow, evidence-based conditions block a passing review even when other
features work. Patterns locate candidates; they do not establish findings.
Confirm the trigger from inspected code, an explicit contract, or applicable
execution evidence, and check the counter-examples before firing. Design
preferences belong under the dimension rubric. Missing evidence leaves the
dependent claim UNVERIFIED, not a defect or a pass.

Apply gates within the declared review scope. Attribute a finding to the change
only when the change introduces, exposes, or worsens it, and identify
pre-existing issues separately. State the reviewed revision or working state
and relevant verification gaps.

**G1: Discarded failure or unchecked panic.** An error on a path involving
untrusted input, network, or persistence is discarded and execution proceeds as
though the operation succeeded, contrary to its contract; or a reachable
failure from such a source is forced into a panic where the contract requires
rejection, propagation, or recovery. Candidates include empty or comment-only
handlers, ignored error results, and unchecked unwraps. Show the failing path
and its required disposition. Logging alone does not make apparent success
correct. **Not fired by** propagation through the language's error channel,
translation that preserves the required failure information, contract-supported
recovery or best-effort behavior, an unwrap whose precondition is established
and remains valid, or deliberate failure on a programmer-error invariant. Do
not require duplicate logging. **Mitigation:** restore the required error
behavior and preserve diagnostic context where needed.

**G2: Unprotected shared-state invariant.** Identify shared mutable state, the
conflicting accesses, and a reachable concurrent or asynchronous interleaving
that violates a required invariant without effective coordination. A global
declaration or missing local lock alone is insufficient. **Not fired by**
synchronization, transactions, message passing, or exclusive ownership that
protects the whole invariant; state immutable after initialization completed
before sharing; or local mutation whose result escapes as a new value. Atomics
or separate locks around individual accesses do not exempt an unprotected
compound operation.
**Mitigation:** enforce ownership or coordinate the full operation that must
remain consistent.

**G3: Boundary input used without required validation.** A value crosses a trust
boundary and reaches an operation that relies on a guarantee not established by
runtime parsing, validation, or an enforced upstream contract. Identify the
source, missing guarantee, and dependent use. HTTP fields, environment variables,
CLI arguments, queue payloads, database results, external responses, and files
are candidates, not proof of missing validation. Establish required guarantees
before their first dependent use and preserve them in precise types where
practical; annotations and unchecked casts do not establish runtime guarantees.
**Not fired by** validated internal flows whose guarantees remain valid,
framework or storage enforcement of the relevant constraint, or opaque data
handled according to a contract that requires no further interpretation.
**Mitigation:** establish the missing guarantee at the appropriate boundary;
recheck changing state where the operation requires it.

**G4: Demonstrated invariant bypass.** A purported fix suppresses a failure,
skips required behavior, or weakens an assertion while a supported case still
violates the contract being fixed. Cite that contract from the issue,
requirements, relevant callers, or tests, and provide a reproducer or concrete
execution trace showing the remaining violation. Added null checks, retries,
defensive guards, and snapshot changes are candidates, never sufficient evidence.
**Not fired by** a guard that enforces the actual contract, a retry whose replay
safety is established, or an expectation updated for an explicitly changed
requirement. If the contract is unclear or conflicting, report that uncertainty
under the ordinary rubric. **Mitigation:** repair the demonstrated contract
violation and verify the triggering case without hiding it.

**G5: Invalid verification or confirmed bypass.** A regex introduced or
modified to decide verification is demonstrated to misclassify the actual
target, or available execution evidence explicitly establishes that a required
check was skipped while the workflow reported verification passed.
Distinguish a detector defect from a bypass of required execution. Candidates
include markup or adjacency mismatches, incorrect counts, and regex-engine
mismatches. Before relying on the check, inspect the target representation
and validate the exact command, engine, flags, file scope, exit handling, and
expected result against the current target. Exercise representative
known-match and known-nonmatch controls through the same pipeline, and record
exit status and decisive output. Execution alone does not establish
correctness. **Not fired by** missing logs or an explicitly unverified or
blocked run alone; report the verification gap. Applicable prior evidence for
unchanged relevant inputs and conditions can satisfy execution. These
exceptions do not excuse an independently demonstrated detector defect.
**Mitigation:** correct and validate the detector, or execute the skipped
check and correct the verification claim.

**G6: Missing design-search record.** The change summary's decisions carry
neither the design-search record (candidates weighed, the pick, why it won)
nor the one-line reason the search did not apply, for a change that chose a
design, mechanism, interface, or test strategy. Confirm it from the change
summary alone; the diff can neither establish nor refute a search. **Not fired
by** a record that ends at the obvious answer with the alternatives named, a
not-applicable line for a change whose shape the requirement fixes (a rename,
a copied value, a one-line data fix, a repair whose form the acceptance
criterion dictates), or an artifact whose contract records the search under
its own heading. Do not grade the pick here; a dominated pick is
judge-architecture's design-search finding under the severity ladder.
**Mitigation:** run the search, record it, and revise the change where the
search changes the pick.

**Override recognition.** Before raising a gate finding, inspect the affected
code and adjacent comments, the change summary, and available attached
work-item context for an explicit override naming the gate or principle, the
occurrence it covers, and the reason. Comment syntax is irrelevant; no source
comment is required. A matching override moves only that occurrence to an
**Overrides** section: quote it verbatim, cite its source and affected
location, and preserve the stated reason. Surfacing it does not endorse the
reason or certify the code as correct; the reader decides whether to accept
it. Do not invent, broaden, or assume an override; quoted examples are not
declarations. Note unavailable context without treating an unseen marker as
present.

**A gate finding names five things:** the location and reviewed state; the
gate; the observed symptom and supporting evidence; the required mitigation;
and why the relevant counter-example does not apply. Report confirmed,
unoverridden gates plainly as blocking a passing review. Assign severity from
supported impact and preconditions, independently of confidence. Do not
inflate every gate to maximum severity or average it away because unrelated
features work.
