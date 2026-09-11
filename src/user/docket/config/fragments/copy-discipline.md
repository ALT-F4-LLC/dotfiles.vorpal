---
fragment: copy-discipline
version: 5
---
# Copy discipline

Copy is part of the product's behavior. A specification that asks for an error
message must specify its words and the condition that displays it. Apply these
rules to copy introduced or changed by the task.

**Propose the real words.** Write button labels, error messages, empty states,
tooltips, confirmations, help text, and accessibility text as they will ship.
Unfinished wording is not an acceptance criterion. Defined runtime substitutions
are allowed; invented product facts are not. Identify missing facts and continue
with unaffected copy.

**Errors explain the failure and the next useful step.** State what happened;
explain the cause when it is known. Give a recovery action only when it is
supported and available to the reader. If no action is available, state the
known status without inventing a remedy. Include specific values or paths when
they help the reader and are safe to disclose. Never blame the person, expose
secrets, or substitute a bare code for an explanation.

**Same concept, same name, every surface.** Use the established domain term
consistently in the interface, CLI, help, and docs. Where config keys, commands,
or log identifiers have an established technical spelling, make the mapping
clear. Preserve compatibility unless changing it is part of the task.

**State facts in plain words.** Say what the control does. Avoid promotional
verbs and unsupported importance claims. Use periods, commas, or colons instead
of em dashes in authored copy strings. Preserve exact identifiers and supplied
values when quoting or interpolating them.

## Copy contracts define observable acceptance criteria

**Identify the surface, state, channel, and kind.** Give each copy entry a
stable name or existing message key. Declare its locale, or inherit the
document's explicit locale. Mark the entry as one of:

- **LITERAL:** fixed text the named surface must emit exactly.
- **TEMPLATE:** final wording with defined runtime substitutions. Specify each
  value's source, formatting, and applicable plural or selection rules using
  the project's existing message format. Include representative inputs and
  exact expected output for each relevant branch.
- **SEMANTIC:** a behavior requirement with no exact wording commitment. It
  cannot substitute for shipping copy where this task requires wording.

Use inline code for one-line literals and templates. For multiline text or
significant boundary whitespace, use a fenced block or an explicitly encoded
string and state whether the final newline belongs to the output. Backticks
around commands, paths, identifiers, or explanatory examples do not create copy
contracts. Mark illustrative copy examples as non-normative. When reviewing an
unclassified entry, report the ambiguity without inventing an exact-match failure.

**Verify the specified output in the specified state.** When implementing,
use the project's existing checks to observe the named surface: visible text,
an accessible name or description, a CLI stream, or another declared channel.
Check visibility when the contract requires visible text. A match elsewhere
in source or a build does not prove the intended surface emits it.

Define the observation method and any normalization as part of the contract.
Compare against the settled specification; preserve capitalization, punctuation,
and whitespace unless the contract explicitly permits a transformation. Do not
let a test helper silently weaken exactness. Check templates after substitution
in the declared locale. Report checks actually run and gaps that remain; do not
claim an automated gate exists or passed without evidence.

**A revision updates every active restatement.** Keep one canonical definition
per entry and refer to its name elsewhere. After changing settled wording,
search the relevant specification, implementation, tests, and docs for the old
text. Update active restatements in scope and report unresolved conflicts;
preserve intentional historical quotations.

**State-dependent copy cites the deciding condition.** For existing behavior,
read and cite the implementation that selects the message or permits or rejects
the operation, including any authoritative server decision. Distinguish a UI
availability check from the operation's final decision. For proposed behavior,
state the intended condition and required implementation change. Surface any
conflict between requirements and current code. Check both a matching state
and a relevant excluded state; if evidence is unavailable, identify the gap
without inventing a condition.
