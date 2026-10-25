#!/usr/bin/env bash
#
# lane_roster: the workflow each issue of a run is bound to, as the JSON
# array lane_units.py takes through --workflows.
#
# Usage: lane_roster.sh RUN-N [--store PATH]
#
# Prints `[{"issue": "<PREFIX>-<n>", "workflow": "<name>@<version>"}, ...]`
# on stdout, one entry per issue bound to the run, in issue order. Exit 0 on
# success; 1 when the run binds no issue, when an issue of the run has no
# workflow (the engine never bound it, which activation refuses, so this is
# a store the engine did not write), when the store cannot be found or read,
# or when `sqlite3` or `jq` is missing; 2 on a usage error.
#
# WHY A STORE READ. The engine binds each run issue to one workflow version
# at activation (run_issues.workflow_id), and no docket verb reports those
# bindings for a run that is already active: `run activate --dry-run` lists
# in `bound_issues[]` only the issues the NEXT activation would bind, so
# after the first activation it is empty or holds only the issues added
# since; `run status` carries the run's pins, not per-issue bindings. The
# bindings the conductor needs to pick each lane's script are in the store,
# so this script reads them there.
#
# READ-ONLY. The store is found the way the engine finds it, through
# `docket config --json` (`DOCKET_PATH`, then a repository-local .docket,
# then ~/.docket), or named with --store. It is opened with `sqlite3
# -readonly`, which takes no write lock and runs no migration, unlike every
# docket verb; a WAL the engine has not checkpointed is still read. The
# display prefix is the issue's own project's, as the engine renders it, so
# an issue bound from another project keeps its own prefix.
#
# Format note: the output is exactly the `bound_issues` shape, so a caller
# can feed either this or an activation's `.data.bound_issues` to
# lane_units.py; this one is complete on an active run.

set -uo pipefail

usage() {
    printf 'usage: lane_roster.sh RUN-N [--store PATH]\n' >&2
    exit 2
}

run="" store=""
while [ $# -gt 0 ]; do
    case "$1" in
        --store) [ $# -ge 2 ] || usage; store="$2"; shift 2 ;;
        -h | --help) usage ;;
        -*) usage ;;
        *) [ -z "$run" ] || usage; run="$1"; shift ;;
    esac
done
[ -n "$run" ] || usage
case "$run" in
    RUN-[0-9]*) run_id="${run#RUN-}" ;;
    [0-9]*) run_id="$run"; run="RUN-$run" ;;
    *) printf 'lane_roster: %s is not a run id (RUN-N)\n' "$run" >&2; exit 2 ;;
esac
case "$run_id" in
    *[!0-9]*) printf 'lane_roster: %s is not a run id (RUN-N)\n' "$run" >&2; exit 2 ;;
esac

command -v sqlite3 >/dev/null 2>&1 || { printf 'lane_roster: sqlite3 is required\n' >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { printf 'lane_roster: jq is required\n' >&2; exit 1; }

if [ -z "$store" ]; then
    command -v docket >/dev/null 2>&1 || { printf 'lane_roster: docket is not on PATH and no --store was given\n' >&2; exit 1; }
    store=$(docket config --json 2>/dev/null | jq -r '.data.db_path // empty' 2>/dev/null) || store=""
    [ -n "$store" ] || { printf 'lane_roster: `docket config --json` names no db_path; pass --store\n' >&2; exit 1; }
fi
[ -r "$store" ] || { printf 'lane_roster: store %s is not readable\n' "$store" >&2; exit 1; }

# One row per run issue. The LEFT JOIN keeps an unbound issue (workflow
# NULL) so it can be reported instead of silently dropped.
query="SELECT UPPER(p.prefix) || '-' || ri.issue_id AS issue,
       CASE WHEN w.id IS NULL THEN NULL ELSE w.name || '@' || w.version END AS workflow
FROM run_issues ri
JOIN issues i ON i.id = ri.issue_id
JOIN projects p ON p.id = i.project_id
LEFT JOIN workflows w ON w.id = ri.workflow_id
WHERE ri.run_id = ${run_id}
ORDER BY ri.issue_id;"

rows=$(sqlite3 -readonly -json "$store" "$query" 2>&1)
status=$?
if [ "$status" -ne 0 ]; then
    printf 'lane_roster: sqlite3 failed reading %s: %s\n' "$store" "$rows" >&2
    exit 1
fi
[ -n "$rows" ] || rows='[]'

count=$(printf '%s' "$rows" | jq 'length')
if [ "$count" -eq 0 ]; then
    run_exists=$(sqlite3 -readonly "$store" "SELECT COUNT(*) FROM runs WHERE id = ${run_id};" 2>/dev/null || echo 0)
    if [ "$run_exists" -eq 0 ]; then
        printf 'lane_roster: %s does not exist in %s\n' "$run" "$store" >&2
    else
        printf 'lane_roster: %s binds no issue; activate it first\n' "$run" >&2
    fi
    exit 1
fi
unbound=$(printf '%s' "$rows" | jq -r '[.[] | select(.workflow == null) | .issue] | join(", ")')
if [ -n "$unbound" ]; then
    printf 'lane_roster: %s has issue(s) with no bound workflow: %s; the engine binds every issue at activation, so this store was not written by it\n' "$run" "$unbound" >&2
    exit 1
fi
printf '%s' "$rows" | jq '.'
