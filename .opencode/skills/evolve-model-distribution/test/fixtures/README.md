# evolve-model-distribution fixture harness

## Opencode SQLite fixture

`opencode_fixture.db` is a synthetic SQLite fixture mirroring the live Opencode
tables used by Phase 3 telemetry validation: `session`, `session_message`,
`message`, `part`, `event`, `event_sequence`, and `account`. It also includes a
minimal `project` table because the live `session.project_id` foreign key points
there.

Rebuild the fixture from this directory:

```bash
sqlite3 opencode_fixture.db < build-opencode-fixture.sql
```

The build script seeds:

| Signal | Expected fixture result |
|---|---:|
| Tool errors in `part.data` where `$.type = 'tool'` and `$.state.status = 'error'` | 3 |
| Model switches in `session_message.type = 'model-switched'` | 2 |
| High-message-count sessions in `message` with `count(*) > 80` | `fixture-stall-session` with 85 messages |
| Cost/model aggregation rows in `session` where `cost > 0` | 2 grouped rows; total cost 5.5 |

Run the Phase 3 semantic checks against the fixture before using a live operator
database:

```bash
sqlite3 opencode_fixture.db "SELECT count(*) FROM part WHERE json_extract(data, '$.type') = 'tool' AND json_extract(data, '$.state.status') = 'error';"
sqlite3 opencode_fixture.db "SELECT count(*) FROM session_message WHERE type = 'model-switched';"
sqlite3 opencode_fixture.db "SELECT session_id, count(*) as msg_count FROM message GROUP BY session_id HAVING msg_count > 80;"
sqlite3 opencode_fixture.db "SELECT agent, model, count(*) AS spawn_count, round(sum(cost), 2) AS total_cost, sum(tokens_input) AS tokens_input, sum(tokens_output) AS tokens_output FROM session WHERE cost > 0 GROUP BY agent, model ORDER BY agent, model;"
```

Expected output:

```text
3
2
fixture-stall-session|85
distinguished-engineer|openai/gpt-5.5|2|3.0|3000|500
staff-engineer|google/gemini-2.5-pro|1|2.5|3000|400
```

`opencode stats --models --days 7 --project ""` is a live CLI check and does not
consume `opencode_fixture.db`; the SQL aggregation above is the deterministic
fixture equivalent that validates the same `session.agent`/`session.model`/
`session.cost` shape without depending on the operator's live database.

## Deprecated project-tree fixture data

The `projects/` tree is retained as an inert historical artifact and is not used
by Phase 3 validation. Do not point new migration checks at it. The supported
validation surface is the SQLite fixture and commands above.

Fallback and model-switch checks now use `session_message.type =
'model-switched'`. Requested-vs-resolved parity is unavailable in the verified
Opencode schema, so that distinction is an operator-judgment signal rather than
a deterministic fixture assertion.
