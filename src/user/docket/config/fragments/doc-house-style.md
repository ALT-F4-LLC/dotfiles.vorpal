---
fragment: doc-house-style
version: 5
---
# Doc house style

Apply this style to documentation written or revised for the task. Structural
requirements, such as required sections, their order, frontmatter fields, and
diagram presence, come from the consuming contract's Emit section, not from a
gate. Keep that required structure; apply brevity within it. These rules
govern whether the content lets someone act without guessing.

## What a document is for

A design document lets someone who was not in the room act. Within the required
structure, answer in a useful sequence: the situation, what is proposed or
decided, its cost, what happens next. Explain the decision and its rationale
where the reader needs them. Use `N/A.` with a one-line reason only when a
section does not apply. Missing evidence or an undecided answer is an unknown,
not inapplicability.

## Claims, not vibes

- **Every commitment is checkable.** A reviewer can determine whether a
  requirement is satisfied from a stated observable outcome and its conditions.
  A success metric names the operation or population, measurement method,
  relevant conditions and window, and passing threshold. Example: "Across all
  requests in the specified 10-minute staging load test at 100 requests/second,
  client-measured p95 latency for `GET /orders` is below 800 ms." This is
  illustrative, not a project requirement.
- **Verify before asserting.** Check claims about existing signatures, paths,
  commands, and behavior against the relevant implementation, tests, or
  authoritative documentation for the version described. Cite evidence for
  claims the decision depends on. State proposed behavior as proposed; label
  unverified premises as assumptions and identify what depends on them. If
  evidence contradicts a premise, surface the conflict and reassess the
  affected reasoning and criteria.
- **Quote what is load-bearing.** When correctness depends on exact wording
  elsewhere, include the shortest quotation that preserves the constraint and
  its qualifications. Mark it as a quotation; cite its source and version or
  section. Link to the source for surrounding detail. Otherwise reference the
  canonical document rather than duplicating it.

## Honesty in the shape of the document

- **Present alternatives fairly.** Compare plausible alternatives against the
  same decision criteria. Give each its real strengths and costs; say what
  decided the choice. Consider doing nothing and using what already exists.
  Explain briefly when either is ruled out by a real constraint. Invented
  alternatives and token disadvantages do not make a comparison fair.
- **State non-goals as deliberate boundaries.** Name things that could
  reasonably have been in scope and were deliberately excluded or deferred,
  for example "Historical data migration is deferred to a separate project."
  Do not pad the list by reversing the wording of the goals.
- **Say what gets worse.** Name supported tradeoffs: what becomes harder, what
  costs more, what becomes hard to reverse. Scale detail to the decision; do
  not invent a drawback to fill a section.
- **Use a premortem to find risks.** Imagine the decision failed after a
  realistic interval. Identify the likeliest causes and consequences, then
  pair each material risk with a concrete mitigation or explicit acceptance of
  the remaining risk. Mark these as hypothetical failures. Distinguish
  proposed mitigations and acceptance from actions already taken or agreed.

## Fidelity and length

Match weight to risk: write the lightest document that fully answers the
reader's questions. Use direct wording and readable paragraphs. Keep decision
records brief, often about a page, without cutting necessary evidence or
consequences. Retain required headings even for short answers; add optional
headings only when they help navigation. Diagrams explain relevant boundaries,
dependencies, or flows; their labels and behavior agree with the prose.

Resolve questions that could change the decision, acceptance criteria, or safe
execution before treating that decision as settled. If an answer is
unavailable, keep the affected decision provisional and continue unaffected
work. Deliberate deferrals identify the next step, responsible person or role,
and deadline or trigger. Mark missing assignments as unassigned. Do not invent
an answer, assignment, or agreement to make the document appear finished.

Use accepted documents as the baseline. State explicitly when a proposal would
amend or supersede an earlier decision, and preserve its history. The same
concept keeps the same name everywhere it appears.

End on the last decision, consequence, or next action. Omit closing recaps and
aphorisms. Put any required executive summary where the template calls for it.
