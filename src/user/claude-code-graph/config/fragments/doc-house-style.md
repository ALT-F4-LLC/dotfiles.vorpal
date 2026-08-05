---
fragment: doc-house-style
version: 1
---
# Doc house style

Structure is checked mechanically — required sections, their order, frontmatter fields,
diagram presence. Nothing below repeats those checks; this is the taste that a validator
cannot enforce. A document that passes every structural check and still leaves its reader
guessing has failed the only test that matters.

## What a document is for

A design document exists so someone who was not in the room can act. Every section earns
its place by answering a question that reader will actually ask, in the order they ask
it: what is the situation, what did we decide, what does that cost, what do I do now.
A section filled in because the template has it — restating the title, deferring to
another document, promising detail later — is worse than an honest `N/A.` with one line
saying why it does not apply.

## Claims, not vibes

- **Every commitment is checkable.** A requirement a reviewer cannot point at and say
  "satisfies / does not satisfy" without asking a follow-up question is not a
  requirement yet. Same for a success metric: name what is measured, how it is measured,
  and the number or threshold that counts as met. "Improve the experience" is a defect;
  "p95 under 800ms via the /metrics endpoint" is a commitment.
- **Verify before asserting.** Anything the document states as fact — a signature, a
  path, a command, an existing behavior it builds on — is confirmed against the real
  thing while writing, not recalled. What you could not verify is written as an
  assumption, in those words. An unverified claim that a reviewer later falsifies
  invalidates every risk row and criterion resting on it.
- **Quote what is load-bearing.** When a downstream reader's correctness depends on
  specific wording elsewhere, reproduce that wording inline rather than citing its
  location. Every hop paraphrases, and a paraphrase silently drops the sentence that
  carried the constraint.

## Honesty in the shape of the document

- **Present alternatives fairly.** A document that describes only the author's preferred
  option is advocacy wearing a design document's clothes. Each alternative gets its real
  strengths, and the verdict says what actually decided it. "Do nothing" and "use what we
  already have" are alternatives, and often the right one.
- **State non-goals affirmatively.** Non-goals are the things that could *reasonably*
  have been in scope and deliberately are not — not restatements of the goals with the
  polarity flipped. A goals-only framing hides where the boundary was drawn.
- **Say what gets worse.** Consequences that list only benefits are marketing. Name what
  becomes harder, what is now hard to reverse, and what the next person will curse.
- **Risks in hindsight form.** Write them as though the failure already happened — it is
  six months later and this did not work; here are the likeliest reasons — and pair each
  with a mitigation or an explicit decision to accept it. Prospective hindsight surfaces
  what a forward-looking list misses.

## Fidelity and length

Match weight to risk: the lightest document that fully answers is the right one, and
over-documenting is its own failure. Tight prose beats exhaustive coverage — a decision
record is a page, not a treatise. Resolve open questions before the document is
considered done; an unresolved question shipped inside a finished document becomes
someone else's silent assumption.

Reference prior accepted documents rather than contradicting or restating them. The same
concept keeps the same name everywhere it appears.
