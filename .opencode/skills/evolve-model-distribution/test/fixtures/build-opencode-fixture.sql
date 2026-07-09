PRAGMA foreign_keys = OFF;

DROP TABLE IF EXISTS part;
DROP TABLE IF EXISTS message;
DROP TABLE IF EXISTS session_message;
DROP TABLE IF EXISTS session;
DROP TABLE IF EXISTS event;
DROP TABLE IF EXISTS event_sequence;
DROP TABLE IF EXISTS account;
DROP TABLE IF EXISTS project;

CREATE TABLE `project` (
  `id` text PRIMARY KEY,
  `worktree` text NOT NULL,
  `vcs` text,
  `name` text,
  `icon_url` text,
  `icon_url_override` text,
  `icon_color` text,
  `time_created` integer NOT NULL,
  `time_updated` integer NOT NULL,
  `time_initialized` integer,
  `sandboxes` text NOT NULL,
  `commands` text
);

CREATE TABLE `account` (
  `id` text PRIMARY KEY,
  `email` text NOT NULL,
  `url` text NOT NULL,
  `access_token` text NOT NULL,
  `refresh_token` text NOT NULL,
  `token_expiry` integer,
  `time_created` integer NOT NULL,
  `time_updated` integer NOT NULL
);

CREATE TABLE `event_sequence` (
  `aggregate_id` text PRIMARY KEY,
  `seq` integer NOT NULL,
  `owner_id` text
);

CREATE TABLE `event` (
  `id` text PRIMARY KEY,
  `aggregate_id` text NOT NULL,
  `seq` integer NOT NULL,
  `type` text NOT NULL,
  `data` text NOT NULL,
  CONSTRAINT `fk_event_aggregate_id_event_sequence_aggregate_id_fk` FOREIGN KEY (`aggregate_id`) REFERENCES `event_sequence`(`aggregate_id`) ON DELETE CASCADE
);

CREATE TABLE `session` (
  `id` text PRIMARY KEY,
  `project_id` text NOT NULL,
  `workspace_id` text,
  `parent_id` text,
  `slug` text NOT NULL,
  `directory` text NOT NULL,
  `path` text,
  `title` text NOT NULL,
  `version` text NOT NULL,
  `share_url` text,
  `summary_additions` integer,
  `summary_deletions` integer,
  `summary_files` integer,
  `summary_diffs` text,
  `metadata` text,
  `cost` real DEFAULT 0 NOT NULL,
  `tokens_input` integer DEFAULT 0 NOT NULL,
  `tokens_output` integer DEFAULT 0 NOT NULL,
  `tokens_reasoning` integer DEFAULT 0 NOT NULL,
  `tokens_cache_read` integer DEFAULT 0 NOT NULL,
  `tokens_cache_write` integer DEFAULT 0 NOT NULL,
  `revert` text,
  `permission` text,
  `agent` text,
  `model` text,
  `time_created` integer NOT NULL,
  `time_updated` integer NOT NULL,
  `time_compacting` integer,
  `time_archived` integer,
  CONSTRAINT `fk_session_project_id_project_id_fk` FOREIGN KEY (`project_id`) REFERENCES `project`(`id`) ON DELETE CASCADE
);

CREATE TABLE `session_message` (
  `id` text PRIMARY KEY,
  `session_id` text NOT NULL,
  `type` text NOT NULL,
  `seq` integer NOT NULL,
  `time_created` integer NOT NULL,
  `time_updated` integer NOT NULL,
  `data` text NOT NULL,
  CONSTRAINT `fk_session_message_session_id_session_id_fk` FOREIGN KEY (`session_id`) REFERENCES `session`(`id`) ON DELETE CASCADE
);

CREATE TABLE `message` (
  `id` text PRIMARY KEY,
  `session_id` text NOT NULL,
  `time_created` integer NOT NULL,
  `time_updated` integer NOT NULL,
  `data` text NOT NULL,
  CONSTRAINT `fk_message_session_id_session_id_fk` FOREIGN KEY (`session_id`) REFERENCES `session`(`id`) ON DELETE CASCADE
);

CREATE TABLE `part` (
  `id` text PRIMARY KEY,
  `message_id` text NOT NULL,
  `session_id` text NOT NULL,
  `time_created` integer NOT NULL,
  `time_updated` integer NOT NULL,
  `data` text NOT NULL,
  CONSTRAINT `fk_part_message_id_message_id_fk` FOREIGN KEY (`message_id`) REFERENCES `message`(`id`) ON DELETE CASCADE
);

PRAGMA foreign_keys = ON;

INSERT INTO project (id, worktree, vcs, name, icon_url, icon_url_override, icon_color, time_created, time_updated, time_initialized, sandboxes, commands)
VALUES ('fixture-project', '/fixture/worktree', 'git', 'opencode fixture', NULL, NULL, NULL, CAST(strftime('%s','now') AS INTEGER) * 1000, CAST(strftime('%s','now') AS INTEGER) * 1000, CAST(strftime('%s','now') AS INTEGER) * 1000, json_array(), json_object());

INSERT INTO account (id, email, url, access_token, refresh_token, token_expiry, time_created, time_updated)
VALUES ('fixture-account', 'fixture@example.invalid', 'https://example.invalid', 'fixture-access-token', 'fixture-refresh-token', NULL, CAST(strftime('%s','now') AS INTEGER) * 1000, CAST(strftime('%s','now') AS INTEGER) * 1000);

INSERT INTO event_sequence (aggregate_id, seq, owner_id)
VALUES ('fixture-event-aggregate', 1, 'fixture-owner');

INSERT INTO event (id, aggregate_id, seq, type, data)
VALUES ('fixture-event-1', 'fixture-event-aggregate', 1, 'fixture.created', json_object('type', 'fixture.created'));

INSERT INTO session (id, project_id, slug, directory, title, version, metadata, cost, tokens_input, tokens_output, tokens_reasoning, tokens_cache_read, tokens_cache_write, agent, model, time_created, time_updated)
VALUES
  ('fixture-tool-errors', 'fixture-project', 'fixture-tool-errors', '/fixture/worktree', 'Fixture tool errors', '0.0.0-fixture', json_object('fixture', 1), 0, 0, 0, 0, 0, 0, 'sdet', 'openai/gpt-5.5', CAST(strftime('%s','now') AS INTEGER) * 1000, CAST(strftime('%s','now') AS INTEGER) * 1000),
  ('fixture-model-switches', 'fixture-project', 'fixture-model-switches', '/fixture/worktree', 'Fixture model switches', '0.0.0-fixture', json_object('fixture', 1), 0, 0, 0, 0, 0, 0, 'team-lead', 'openai/gpt-5.5', CAST(strftime('%s','now') AS INTEGER) * 1000, CAST(strftime('%s','now') AS INTEGER) * 1000),
  ('fixture-stall-session', 'fixture-project', 'fixture-stall-session', '/fixture/worktree', 'Fixture high message count', '0.0.0-fixture', json_object('fixture', 1), 0, 0, 0, 0, 0, 0, 'senior-engineer', 'openai/gpt-5.5', CAST(strftime('%s','now') AS INTEGER) * 1000, CAST(strftime('%s','now') AS INTEGER) * 1000),
  ('fixture-cost-openai-1', 'fixture-project', 'fixture-cost-openai-1', '/fixture/worktree', 'Fixture cost OpenAI 1', '0.0.0-fixture', json_object('fixture', 1), 1.25, 1000, 200, 25, 100, 50, 'distinguished-engineer', 'openai/gpt-5.5', CAST(strftime('%s','now') AS INTEGER) * 1000, CAST(strftime('%s','now') AS INTEGER) * 1000),
  ('fixture-cost-openai-2', 'fixture-project', 'fixture-cost-openai-2', '/fixture/worktree', 'Fixture cost OpenAI 2', '0.0.0-fixture', json_object('fixture', 1), 1.75, 2000, 300, 50, 200, 75, 'distinguished-engineer', 'openai/gpt-5.5', CAST(strftime('%s','now') AS INTEGER) * 1000, CAST(strftime('%s','now') AS INTEGER) * 1000),
  ('fixture-cost-gemini-1', 'fixture-project', 'fixture-cost-gemini-1', '/fixture/worktree', 'Fixture cost Gemini 1', '0.0.0-fixture', json_object('fixture', 1), 2.50, 3000, 400, 100, 300, 125, 'staff-engineer', 'google/gemini-2.5-pro', CAST(strftime('%s','now') AS INTEGER) * 1000, CAST(strftime('%s','now') AS INTEGER) * 1000);

INSERT INTO message (id, session_id, time_created, time_updated, data)
VALUES
  ('fixture-tool-error-message-1', 'fixture-tool-errors', CAST(strftime('%s','now') AS INTEGER) * 1000, CAST(strftime('%s','now') AS INTEGER) * 1000, json_object('role', 'assistant', 'time', json_object('created', CAST(strftime('%s','now') AS INTEGER) * 1000), 'agent', 'sdet', 'modelID', 'openai/gpt-5.5', 'providerID', 'openai', 'mode', 'fixture')),
  ('fixture-tool-error-message-2', 'fixture-tool-errors', CAST(strftime('%s','now') AS INTEGER) * 1000, CAST(strftime('%s','now') AS INTEGER) * 1000, json_object('role', 'assistant', 'time', json_object('created', CAST(strftime('%s','now') AS INTEGER) * 1000), 'agent', 'sdet', 'modelID', 'openai/gpt-5.5', 'providerID', 'openai', 'mode', 'fixture')),
  ('fixture-tool-error-message-3', 'fixture-tool-errors', CAST(strftime('%s','now') AS INTEGER) * 1000, CAST(strftime('%s','now') AS INTEGER) * 1000, json_object('role', 'assistant', 'time', json_object('created', CAST(strftime('%s','now') AS INTEGER) * 1000), 'agent', 'sdet', 'modelID', 'openai/gpt-5.5', 'providerID', 'openai', 'mode', 'fixture'));

WITH RECURSIVE seq(n) AS (
  SELECT 1
  UNION ALL
  SELECT n + 1 FROM seq WHERE n < 85
)
INSERT INTO message (id, session_id, time_created, time_updated, data)
SELECT printf('fixture-stall-message-%03d', n),
       'fixture-stall-session',
       CAST(strftime('%s','now') AS INTEGER) * 1000 + n,
       CAST(strftime('%s','now') AS INTEGER) * 1000 + n,
       json_object('role', CASE WHEN n % 2 = 0 THEN 'assistant' ELSE 'user' END,
                   'time', json_object('created', CAST(strftime('%s','now') AS INTEGER) * 1000 + n),
                   'agent', 'senior-engineer',
                   'modelID', 'openai/gpt-5.5',
                   'providerID', 'openai',
                   'mode', 'fixture')
FROM seq;

INSERT INTO message (id, session_id, time_created, time_updated, data)
VALUES
  ('fixture-cost-openai-message-1', 'fixture-cost-openai-1', CAST(strftime('%s','now') AS INTEGER) * 1000, CAST(strftime('%s','now') AS INTEGER) * 1000, json_object('role', 'assistant', 'time', json_object('created', CAST(strftime('%s','now') AS INTEGER) * 1000), 'cost', 1.25, 'tokens', json_object('input', 1000, 'output', 200), 'modelID', 'openai/gpt-5.5', 'providerID', 'openai', 'agent', 'distinguished-engineer', 'mode', 'fixture')),
  ('fixture-cost-openai-message-2', 'fixture-cost-openai-2', CAST(strftime('%s','now') AS INTEGER) * 1000, CAST(strftime('%s','now') AS INTEGER) * 1000, json_object('role', 'assistant', 'time', json_object('created', CAST(strftime('%s','now') AS INTEGER) * 1000), 'cost', 1.75, 'tokens', json_object('input', 2000, 'output', 300), 'modelID', 'openai/gpt-5.5', 'providerID', 'openai', 'agent', 'distinguished-engineer', 'mode', 'fixture')),
  ('fixture-cost-gemini-message-1', 'fixture-cost-gemini-1', CAST(strftime('%s','now') AS INTEGER) * 1000, CAST(strftime('%s','now') AS INTEGER) * 1000, json_object('role', 'assistant', 'time', json_object('created', CAST(strftime('%s','now') AS INTEGER) * 1000), 'cost', 2.50, 'tokens', json_object('input', 3000, 'output', 400), 'modelID', 'google/gemini-2.5-pro', 'providerID', 'google', 'agent', 'staff-engineer', 'mode', 'fixture'));

INSERT INTO part (id, message_id, session_id, time_created, time_updated, data)
VALUES
  ('fixture-tool-error-part-1', 'fixture-tool-error-message-1', 'fixture-tool-errors', CAST(strftime('%s','now') AS INTEGER) * 1000, CAST(strftime('%s','now') AS INTEGER) * 1000, json_object('type', 'tool', 'callID', 'fixture-call-1', 'tool', 'bash', 'state', json_object('status', 'error', 'input', json_object('command', 'fixture failure 1'), 'error', 'fixture tool error 1', 'time', json_object('start', CAST(strftime('%s','now') AS INTEGER) * 1000, 'end', CAST(strftime('%s','now') AS INTEGER) * 1000)))),
  ('fixture-tool-error-part-2', 'fixture-tool-error-message-2', 'fixture-tool-errors', CAST(strftime('%s','now') AS INTEGER) * 1000, CAST(strftime('%s','now') AS INTEGER) * 1000, json_object('type', 'tool', 'callID', 'fixture-call-2', 'tool', 'sqlite3', 'state', json_object('status', 'error', 'input', json_object('database', 'fixture'), 'error', 'fixture tool error 2', 'time', json_object('start', CAST(strftime('%s','now') AS INTEGER) * 1000, 'end', CAST(strftime('%s','now') AS INTEGER) * 1000)))),
  ('fixture-tool-error-part-3', 'fixture-tool-error-message-3', 'fixture-tool-errors', CAST(strftime('%s','now') AS INTEGER) * 1000, CAST(strftime('%s','now') AS INTEGER) * 1000, json_object('type', 'tool', 'callID', 'fixture-call-3', 'tool', 'read', 'state', json_object('status', 'error', 'input', json_object('path', 'fixture'), 'error', 'fixture tool error 3', 'time', json_object('start', CAST(strftime('%s','now') AS INTEGER) * 1000, 'end', CAST(strftime('%s','now') AS INTEGER) * 1000)))),
  ('fixture-tool-completed-part-1', 'fixture-tool-error-message-1', 'fixture-tool-errors', CAST(strftime('%s','now') AS INTEGER) * 1000, CAST(strftime('%s','now') AS INTEGER) * 1000, json_object('type', 'tool', 'callID', 'fixture-call-completed-1', 'tool', 'bash', 'state', json_object('status', 'completed', 'input', json_object('command', 'fixture success'), 'output', 'fixture success', 'time', json_object('start', CAST(strftime('%s','now') AS INTEGER) * 1000, 'end', CAST(strftime('%s','now') AS INTEGER) * 1000)))),
  ('fixture-text-part-1', 'fixture-tool-error-message-1', 'fixture-tool-errors', CAST(strftime('%s','now') AS INTEGER) * 1000, CAST(strftime('%s','now') AS INTEGER) * 1000, json_object('type', 'text', 'text', 'fixture text part'));

INSERT INTO session_message (id, session_id, type, seq, time_created, time_updated, data)
VALUES
  ('fixture-session-message-model-switch-1', 'fixture-model-switches', 'model-switched', 1, CAST(strftime('%s','now') AS INTEGER) * 1000, CAST(strftime('%s','now') AS INTEGER) * 1000, json_object('model', json_object('id', 'openai/gpt-5.5', 'providerID', 'openai', 'variant', 'default'), 'time', json_object('created', CAST(strftime('%s','now') AS INTEGER) * 1000))),
  ('fixture-session-message-model-switch-2', 'fixture-model-switches', 'model-switched', 2, CAST(strftime('%s','now') AS INTEGER) * 1000, CAST(strftime('%s','now') AS INTEGER) * 1000, json_object('model', json_object('id', 'google/gemini-2.5-pro', 'providerID', 'google', 'variant', 'default'), 'time', json_object('created', CAST(strftime('%s','now') AS INTEGER) * 1000))),
  ('fixture-session-message-agent-switch-1', 'fixture-model-switches', 'agent-switched', 3, CAST(strftime('%s','now') AS INTEGER) * 1000, CAST(strftime('%s','now') AS INTEGER) * 1000, json_object('agent', 'staff-engineer', 'time', json_object('created', CAST(strftime('%s','now') AS INTEGER) * 1000)));

PRAGMA foreign_key_check;
