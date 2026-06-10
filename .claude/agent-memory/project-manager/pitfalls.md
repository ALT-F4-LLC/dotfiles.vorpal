# project-manager pitfalls

- 2026-06-10 — symptom: `docket issue create ... -l <label> -f <file> -d -` (body via stdin) prints success but the created issue's `labels` and `files` arrays are EMPTY → root cause: `-l` and `-f` are silently dropped when the description is piped through `-d -` → resolution: after any stdin-body create, always run explicit `docket issue label add <id> <label>` and `docket issue file add <id> <paths>`, and check the create response's `labels`/`files` arrays instead of trusting the success line (empty `-f` silently breaks collision detection).
