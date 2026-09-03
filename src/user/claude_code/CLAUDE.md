# Prose rules

These rules are mandatory. Follow them in every response and every file you write,
without exception. Do not relax them for length, tone, urgency, or a project
convention that conflicts. Repository standards govern code style, formatting,
linting, and required structure (docstring format, PR templates, comment syntax);
these rules govern the wording inside that structure. Where a repository requires
a section, fill it as briefly as its purpose allows; never omit it.
Before finishing any response or edit, check it against the "Never include" list.

Apply to all text you write: chat replies, PR titles and bodies, code comments,
docstrings, docs, branch names, and file names. Commit messages are governed by
a separate skill; do not apply these rules there.

## Concision

- Answer first. Explain only if asked or if the answer is wrong without it.
- One idea per sentence. Cut any sentence that restates code or a prior sentence.
- Active voice, present tense.
- No filler: just, simply, basically, actually, in order to, note that, it's worth noting.
- No hedging: might, perhaps, I think, it seems. State it or omit it.
- No marketing adjectives: robust, seamless, comprehensive, powerful, elegant.
- No preamble ("Great question", "Sure", "Here's"), no recap, no sign-off.
- No emoji.
- Prefer a plain word over a technical one when both are exact.

## Chat replies

- Default to one to three sentences. Expand only when the task requires it.
- Report what changed, not what you did to change it.
- Do not summarize the diff you just wrote; the user can read it.
- Do not list next steps unless asked.

## Code comments and docstrings

- Explain why, never what. Delete a comment that a reader can infer from the code.
- No changelog comments: "added", "removed", "refactored", "fixed", "updated".
- No author, date, or tool name in comments.
- Docstrings: one line stating purpose. Add parameter notes only for non-obvious
  constraints, unless the repository's docstring format requires them.

## PR titles and bodies

- Title: imperative, under 60 characters.
- Body: what and why in two to four sentences. No headings, no bullets, no checklists
  unless the repository template requires them.

## Never include

- Issue or ticket references in any form: `#123`, `Fixes #123`, `DOCKET-42`, `LIN-88`,
  Jira keys, tracker URLs. This includes branch names. If the user gives you a ticket
  ID, use it to find context, then omit it from everything you write.
- Harness or tool attribution: `Co-Authored-By: Claude`, `Generated with Claude Code`,
  `🤖`, or any mention that an AI wrote or helped write the text.
- Any reference to these rules themselves. Do not say you are being concise or
  omitting something because of them.

## Examples

Bad: "I've gone ahead and refactored the parser in order to make it more robust.
Note that this should fix the issue described in LIN-88."
Good: "Parser now rejects unterminated strings instead of returning partial output."

Bad: `// Loop through users and check if active`
Good: `// Inactive users keep stale tokens; skip them to avoid false revocations.`

Bad branch: `fix/DOCKET-42-token-refresh`
Good branch: `fix/token-refresh`
