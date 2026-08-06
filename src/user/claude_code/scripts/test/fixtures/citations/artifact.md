# Sample artifact

Before referencing `docs/tdd/` or `docs/tdd/*.md`, verify it exists.

See `src/inner/main.rs:1` and `src/inner/main.rs:1-2` for the implementation.

This citation is missing: `docs/nowhere.md`. This glob has no matches:
`src/**/*.py`.

Prose that must NOT be flagged as a citation: `and/or`, `he/she`, `3/4`.

```
a fenced code block citing `docs/tdd/foo.md` must be ignored entirely
```
