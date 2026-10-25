#!/bin/bash

# lane_roster.sh reads a run's issue to workflow bindings out of the store.
#
# Wired into CI: `.github/workflows/vorpal.yaml` lists this file by name,
# and tests/ci-suite-wiring.test.sh fails when it is not. Needs sqlite3, jq,
# python3 and git; no engine, no network. The store is a fixture this test
# builds with sqlite3 from the five tables the query touches, in the shape
# docket's schema declares them.
#
# WHY THIS EXISTS. docket-run launches one lane script per issue, the
# script of the workflow the engine bound that issue to. The engine records
# the binding in run_issues.workflow_id at activation and no verb reports it
# afterwards: `run activate --dry-run` lists only what the next activation
# would bind, so on an active run its bound_issues[] is empty or partial.
# lane_roster.sh reads the store instead, read-only, and prints the
# [{issue, workflow}] array lane_units.py takes through --workflows. A wrong
# roster routes an issue's rows to another workflow's script, which that
# script refuses, so the roster has to be complete and exact; a roster that
# silently dropped an unbound issue or an issue from another project would
# fail later with a worse message.
#
# WHAT IS PINNED:
#   1. The happy path: every issue bound to the run, in issue order, named
#      with its own project's prefix upper-cased, the workflow as
#      name@version, and nothing from other runs. Output is exactly the
#      bound_issues shape, so lane_units.py --workflows takes it as is and
#      writes the lane's script into launches.json.
#   2. The store is found through `docket config --json`'s db_path when no
#      --store is given, and --store wins when both are present.
#   3. A run with no issues, a run that does not exist, and an issue with no
#      workflow each exit 1 naming the run (and the issue), with nothing on
#      stdout. A missing or unreadable store exits 1. Usage errors exit 2.
#   4. The read is read-only: the fixture's bytes are unchanged afterwards
#      and a WAL-mode store is read.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
ROSTER="${ROOT}/src/user/claude_code/skills/docket-run/scripts/lane_roster.sh"
UNITS="${ROOT}/src/user/claude_code/skills/docket-run/scripts/lane_units.py"

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$ROSTER" ] || fatal "lane_roster.sh not found at ${ROSTER}"
[ -f "$UNITS" ] || fatal "lane_units.py not found at ${UNITS}"
for tool in sqlite3 jq python3 git; do
    command -v "$tool" >/dev/null 2>&1 || fatal "${tool} is required to run this test"
done

WORK=$(mktemp -d "${TMPDIR:-/tmp}/lane-roster.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT

pass=0
fail=0
ok() { # <condition-already-evaluated: 0/1> <label>
    if [ "$1" -eq 0 ]; then
        pass=$((pass + 1)); printf 'PASS: %s\n' "$2"
    else
        fail=$((fail + 1)); printf 'FAIL: %s\n' "$2" >&2
    fi
}

# ---- the fixture store ------------------------------------------------------
# Two projects (prefixes stored lower-case, as docket stores them), two
# workflow rows of the same name at different versions plus one other, three
# runs: RUN-1 binds three issues across both projects, RUN-2 binds none, RUN-3
# binds one issue with no workflow. RUN-4 does not exist.
DB="$WORK/issues.db"
sqlite3 "$DB" <<'SQL'
CREATE TABLE projects (id INTEGER PRIMARY KEY AUTOINCREMENT, identity TEXT NOT NULL UNIQUE, name TEXT NOT NULL DEFAULT '', prefix TEXT NOT NULL DEFAULT 'DKT', created_at_ms INTEGER NOT NULL DEFAULT 0);
CREATE TABLE issues (id INTEGER PRIMARY KEY AUTOINCREMENT, project_id INTEGER NOT NULL DEFAULT 1, title TEXT NOT NULL, status TEXT NOT NULL DEFAULT 'backlog', created_at TEXT NOT NULL, updated_at TEXT NOT NULL);
CREATE TABLE workflows (id INTEGER PRIMARY KEY AUTOINCREMENT, project_id INTEGER NOT NULL DEFAULT 1, name TEXT NOT NULL, version INTEGER NOT NULL, source_sha256 TEXT NOT NULL, body TEXT NOT NULL, parsed TEXT NOT NULL, created_at_ms INTEGER NOT NULL, UNIQUE(project_id, name, version));
CREATE TABLE runs (id INTEGER PRIMARY KEY AUTOINCREMENT, request TEXT NOT NULL DEFAULT '', status TEXT NOT NULL DEFAULT 'planning', created_at_ms INTEGER NOT NULL, updated_at_ms INTEGER NOT NULL, project_id INTEGER NOT NULL DEFAULT 1);
CREATE TABLE run_issues (run_id INTEGER NOT NULL REFERENCES runs(id), issue_id INTEGER NOT NULL REFERENCES issues(id), workflow_id INTEGER REFERENCES workflows(id), PRIMARY KEY (run_id, issue_id));
INSERT INTO projects (id, identity, name, prefix) VALUES (1, 'github.com/a/one', 'one', 'hrn'), (2, 'github.com/a/two', 'two', 'dkt');
INSERT INTO issues (id, project_id, title, status, created_at, updated_at) VALUES
  (10, 1, 'first', 'in_progress', 't', 't'),
  (11, 2, 'from the other project', 'in_progress', 't', 't'),
  (12, 1, 'third', 'in_progress', 't', 't'),
  (13, 1, 'bound elsewhere', 'in_progress', 't', 't'),
  (14, 1, 'never bound', 'in_progress', 't', 't');
INSERT INTO workflows (id, project_id, name, version, source_sha256, body, parsed, created_at_ms) VALUES
  (100, 1, 'standard-change', 55, 'x', '', '{}', 0),
  (101, 1, 'standard-change', 56, 'x', '', '{}', 0),
  (102, 1, 'ui-change', 7, 'x', '', '{}', 0);
INSERT INTO runs (id, request, status, created_at_ms, updated_at_ms, project_id) VALUES
  (1, 'r1', 'active', 0, 0, 1), (2, 'r2', 'planning', 0, 0, 1), (3, 'r3', 'active', 0, 0, 1), (5, 'r5', 'active', 0, 0, 1);
INSERT INTO run_issues (run_id, issue_id, workflow_id) VALUES
  (1, 12, 102), (1, 10, 101), (1, 11, 100),
  (3, 14, NULL),
  (5, 13, 100);
SQL
[ -f "$DB" ] || fatal "fixture store was not created"
before=$(cksum < "$DB")

run_roster() { # [args...]: stdout to $WORK/out, stderr to $WORK/err, rc returned
    bash "$ROSTER" "$@" > "$WORK/out" 2> "$WORK/err"
}

# ---- 1. the happy path -----------------------------------------------------
run_roster RUN-1 --store "$DB"; rc=$?
want='[{"issue":"HRN-10","workflow":"standard-change@56"},{"issue":"DKT-11","workflow":"standard-change@55"},{"issue":"HRN-12","workflow":"ui-change@7"}]'
[ $rc -eq 0 ] && [ "$(jq -c . "$WORK/out")" = "$want" ]
ok $? "RUN-1: every bound issue, in issue order, own prefix upper-cased, workflow as name@version (rc ${rc})"
! grep -q 'HRN-13' "$WORK/out"; ok $? "RUN-1: an issue bound to another run is not listed"
[ -z "$(cat "$WORK/err")" ]; ok $? "RUN-1: nothing on stderr"
run_roster 1 --store "$DB"; rc=$?
[ $rc -eq 0 ] && [ "$(jq 'length' "$WORK/out")" = "3" ]
ok $? "a bare run number is accepted (rc ${rc})"

# the output is exactly what lane_units.py --workflows takes
export GIT_CEILING_DIRECTORIES="$WORK"
git init -q "$WORK/repo" || fatal "git init failed"
run_roster RUN-1 --store "$DB"
cp "$WORK/out" "$WORK/roster.json"
printf '%s' '[{"step":"STEP-1","issue":"HRN-10","kind":"executor","class":"write","stage":0},{"step":"STEP-2","issue":"DKT-11","kind":"executor","class":"read","stage":0}]' > "$WORK/rows.json"
(cd "$WORK/repo" && python3 -I "$UNITS" "$WORK/rows.json" "$WORK/launch" --workflows "$WORK/roster.json" --tribunal /x/tribunal.js > "$WORK/lu.out" 2> "$WORK/lu.err"); rc=$?
[ $rc -eq 0 ] && [ "$(jq -r '[.[] | "\(.lanes[0]) \(.workflow) \(.script)"] | join(";")' "$WORK/launch/launches.json")" = "HRN-10 standard-change standard-change.js;DKT-11 standard-change standard-change.js" ]
ok $? "lane_units.py --workflows takes the roster as is and names each lane's script (rc ${rc}: $(tail -n 1 "$WORK/lu.err"))"
[ "$(jq -r '.workflow' "$WORK/launch/args-0.json")" = "standard-change" ]
ok $? "...and writes the lane's workflow into its args object"

# ---- 2. finding the store ---------------------------------------------------
mkdir -p "$WORK/bin"
printf '#!/bin/bash\n[ "$1 $2" = "config --json" ] || { echo "stub docket: unexpected $*" >&2; exit 2; }\nprintf '"'"'{"ok":true,"data":{"db_path":"%%s","store_source":"home"}}\\n'"'"' "$STUB_DB"\n' > "$WORK/bin/docket"
chmod 755 "$WORK/bin/docket"
STUB_DB="$DB" PATH="$WORK/bin:$PATH" run_roster RUN-1; rc=$?
[ $rc -eq 0 ] && [ "$(jq 'length' "$WORK/out")" = "3" ]
ok $? "without --store the store is docket config --json's db_path (rc ${rc})"
STUB_DB="$WORK/nowhere.db" PATH="$WORK/bin:$PATH" run_roster RUN-1 --store "$DB"; rc=$?
[ $rc -eq 0 ] && [ "$(jq 'length' "$WORK/out")" = "3" ]
ok $? "--store wins over docket config (rc ${rc})"
STUB_DB="$WORK/nowhere.db" PATH="$WORK/bin:$PATH" run_roster RUN-1; rc=$?
[ $rc -eq 1 ] && grep -q 'not readable' "$WORK/err" && [ ! -s "$WORK/out" ]
ok $? "a db_path that does not exist exits 1 with nothing on stdout (rc ${rc})"
PATH="$WORK/bin-empty:/nonexistent" run_roster RUN-1 2>/dev/null; rc=$?
[ $rc -ne 0 ] && [ ! -s "$WORK/out" ]
ok $? "no docket on PATH and no --store is an error, not a guess (rc ${rc})"

# ---- 3. refusals -----------------------------------------------------------
run_roster RUN-2 --store "$DB"; rc=$?
[ $rc -eq 1 ] && grep -q 'RUN-2 binds no issue' "$WORK/err" && [ ! -s "$WORK/out" ]
ok $? "a run with no bound issue exits 1 naming the run, nothing on stdout (rc ${rc})"
run_roster RUN-4 --store "$DB"; rc=$?
[ $rc -eq 1 ] && grep -q 'RUN-4 does not exist' "$WORK/err" && [ ! -s "$WORK/out" ]
ok $? "a run that does not exist exits 1 saying so (rc ${rc})"
run_roster RUN-3 --store "$DB"; rc=$?
[ $rc -eq 1 ] && grep -q 'RUN-3 has issue(s) with no bound workflow: HRN-14' "$WORK/err" && [ ! -s "$WORK/out" ]
ok $? "an issue with no workflow exits 1 naming the issue, nothing on stdout (rc ${rc})"
run_roster --store "$DB"; rc=$?
[ $rc -eq 2 ] && grep -q '^usage:' "$WORK/err"
ok $? "no run id is a usage error (rc ${rc})"
run_roster RUN-x --store "$DB"; rc=$?
[ $rc -eq 2 ] && grep -q 'not a run id' "$WORK/err"
ok $? "a malformed run id is a usage error (rc ${rc})"
run_roster RUN-1 RUN-2 --store "$DB"; rc=$?
[ $rc -eq 2 ]; ok $? "two run ids are a usage error (rc ${rc})"
run_roster RUN-1 --store "$WORK/absent.db"; rc=$?
[ $rc -eq 1 ] && grep -q 'not readable' "$WORK/err"
ok $? "an absent --store exits 1 (rc ${rc})"
printf 'not a database\n' > "$WORK/garbage.db"
run_roster RUN-1 --store "$WORK/garbage.db"; rc=$?
[ $rc -eq 1 ] && grep -q 'sqlite3 failed' "$WORK/err" && [ ! -s "$WORK/out" ]
ok $? "a file that is not a store exits 1 with sqlite3's reason (rc ${rc})"

# ---- 4. read-only ----------------------------------------------------------
after=$(cksum < "$DB")
[ "$before" = "$after" ]; ok $? "the store's bytes are unchanged after every read"
cp "$DB" "$WORK/wal.db"
sqlite3 "$WORK/wal.db" 'PRAGMA journal_mode=WAL; UPDATE run_issues SET workflow_id = 102 WHERE run_id = 1 AND issue_id = 10;' > /dev/null
run_roster RUN-1 --store "$WORK/wal.db"; rc=$?
[ $rc -eq 0 ] && [ "$(jq -r '.[0].workflow' "$WORK/out")" = "ui-change@7" ]
ok $? "a WAL-mode store is read, with its latest write (rc ${rc})"
[ "$(sqlite3 "$WORK/wal.db" 'PRAGMA journal_mode;')" = "wal" ]
ok $? "...and reading left it in WAL mode"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
