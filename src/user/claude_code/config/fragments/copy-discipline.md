---
fragment: copy-discipline
version: 1
---
# Copy discipline

Copy is not decoration applied after the design; it is the surface most users actually
read. A specification that says "show an error" has specified nothing.

**Propose the real string, never a placeholder.** Button labels, error messages, empty
states, tooltips, confirmations, help text — the actual words, written as they will
ship. "TBD", lorem, and "something like…" are defects, not drafts.

**Error messages say what happened, why, and what to do now**, with the specific values
and paths involved — not a generic class name and not a bare code. Never blame the
person. An error the reader cannot act on has spent their attention for nothing.

**Same concept, same name, every surface.** Once a thing is named, it is named that in
the CLI, the interface, the config, the logs, and the docs. Two names for one concept is
the most common Familiarity violation and the most expensive to unwind after ship.

## Copy literals are the executable acceptance surface

Quote every proposed copy string as a **verbatim inline-code literal**. This is the one
part of a design specification that can be checked mechanically: a copy gate greps the
built output for each literal, so a quoted string is a machine-verifiable commitment and
an unquoted paraphrase is not checkable at all. Punctuation, capitalization, and
whitespace are part of the literal — a trailing period that differs is a real mismatch,
not a nitpick, because the check is exact.

Two consequences:

- **Write literals only where the surface must render them verbatim.** A backticked token
  is either a LITERAL the surface emits exactly or a SEMANTIC stand-in for a behavior.
  Decide from the surrounding sentence and make the distinction explicit, because grading
  one as the other manufactures a false finding. Where the document does not disambiguate,
  that ambiguity is itself the finding — raise it as a question rather than judging it as
  a mismatch.
- **A revision repoints every restatement.** After changing a settled string, search the
  document for the superseded wording; a stale duplicate turns a passing check into a
  contradictory one and leaves the implementer with two answers.

**Copy that is state-dependent cites the authoritative condition.** When what the surface
says depends on system state — an affordance's enabled text, an error that fires only on
a specific rejection — the wording is pinned to the actual precondition the handler
applies, read from the source. Prose-inferred conditions invert, and the surface then
says the wrong true-sounding thing at exactly the wrong moment.
