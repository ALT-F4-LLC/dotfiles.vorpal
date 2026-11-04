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
# READ-ONLY, WHEN IT CANNOT READ. Plain `sqlite3 -readonly` does not suffice
# on an idle store. The WAL hypothesis is confirmed: a read-only connection
# cannot create the WAL index, so a WAL-mode store (database header bytes
# 18-19 are 02 02) with neither a -wal nor a -shm file fails with SQLite
# error 14, "unable to open database file", in a writable directory as well
# as an unwritable one; the sandbox is not the cause. Reproduced with sqlite3
# 3.54.0: `-readonly`, `mode=ro`, `nolock=1`, `readonly_shm=1`, `-vfs
# unix-excl` and `-deserialize` all fail, and only `immutable=1` opens it.
# With the two files present, even stale and in an unwritable directory,
# `-readonly` reads the store, WAL included. The engine's SQLite deletes them
# when its last connection closes, which happens after every docket verb,
# including the `docket config --json` this script runs to find the store
# (`ls issues.db-wal issues.db-shm` shows both, then neither after it). The
# script makes no write itself; that call opens and closes the store as any
# verb does. So the mechanism is `sqlite3 -readonly`, for
# both opens through read_ro(), and only when that fails this way, on a WAL
# store with no -wal, -shm or -journal file, a guarded `immutable=1` read.
# With no sidecar no connection holds the store and every committed write is
# in the main file. A writer that opens it during the read leaves a sidecar or
# checkpoints into the main file, and either fails the guard: the read is kept
# only if the store was at least 2 s old when it began and its size, mtime,
# ctime, inode and journal-mode header bytes, and the absence of the sidecars,
# are the same after it; otherwise it is retried, then exits 1. A file write
# that leaves mtime and ctime unchanged (mmap writes, some network
# filesystems) would escape that guard.
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

# The one read-only open both reads go through: an optional sqlite3 format
# option and the SQL in, the output in $ro_out. On failure it exits 1 itself.
#
# 1. `sqlite3 -readonly`. Used whenever it opens the store.
# 2. Only when that fails with "unable to open database file" on a WAL-mode
#    store with no -wal, -shm or -journal file, and only then: no connection
#    holds the store and every committed write is in the main file, so
#    `immutable=1` reads it. The result is kept only if the store was at least
#    2 s old when the read began and nothing changed across it: the same size,
#    mtime, ctime, inode and journal-mode header bytes, and still no sidecar.
#    A writer that opened the store meanwhile either left a sidecar or
#    checkpointed into the main file, and both fail that check; the read is
#    then discarded and retried, three times, before exiting 1.
store_sig() { # size mtime-ns ctime-ns inode: GNU stat first, BSD stat second
    stat -c '%s %.9Y %.9Z %i' "$store" 2>/dev/null || stat -f '%z %Fm %Fc %i' "$store" 2>/dev/null
}
wal_header() { head -c 20 "$store" 2>/dev/null | od -An -tx1 -j18 -N2 | tr -d ' \n'; }
no_sidecars() { [ ! -e "${store}-wal" ] && [ ! -e "${store}-shm" ] && [ ! -e "${store}-journal" ]; }
uri_encode() { # percent-encode all but [A-Za-z0-9/._~-]
    local s="$1" out="" c i
    LC_ALL=C
    for ((i = 0; i < ${#s}; i++)); do
        c="${s:i:1}"
        case "$c" in
            [A-Za-z0-9/._~-]) out+="$c" ;;
            *) out+=$(printf '%%%02X' "'$c") ;;
        esac
    done
    printf '%s' "$out"
}

ro_out=""
read_ro() { # [format-option] <sql>
    local fmt="" sql status attempt sig1 sig2 hdr1 hdr2 mtime abs uri why=""
    if [ $# -eq 2 ]; then fmt="$1"; sql="$2"; else sql="$1"; fi
    ro_out=$(sqlite3 -readonly ${fmt:+"$fmt"} "$store" "$sql" 2>&1)
    status=$?
    [ "$status" -ne 0 ] || return 0
    if printf '%s' "$ro_out" | grep -q 'unable to open database file' \
        && [ "$(wal_header)" = "0202" ] && no_sidecars; then
        case "$store" in /*) abs="$store" ;; *) abs="$PWD/$store" ;; esac
        uri="file:$(uri_encode "$abs")?mode=ro&immutable=1"
        for attempt in 1 2 3; do
            sig1=$(store_sig); hdr1=$(wal_header)
            mtime=${sig1#* }; mtime=${mtime%%.*}
            if [ -z "$sig1" ] || [ "$hdr1" != "0202" ] || ! no_sidecars; then
                why="the store or its sidecars changed"
            elif [ $(( $(date +%s) - mtime )) -lt 2 ]; then
                why="the store was written less than 2 s ago"
            else
                ro_out=$(sqlite3 ${fmt:+"$fmt"} "$uri" "$sql" 2>&1)
                status=$?
                sig2=$(store_sig); hdr2=$(wal_header)
                if [ "$status" -ne 0 ]; then
                    why=""
                    break
                elif [ "$sig1" = "$sig2" ] && [ "$hdr1" = "$hdr2" ] && no_sidecars; then
                    return 0
                fi
                why="the store changed during the read"
            fi
            sleep 0.2
        done
        if [ -n "$why" ]; then
            printf 'lane_roster: %s is a WAL-mode store with no -wal or -shm file, which no read-only open can read, and the guarded fallback read gave up: %s\n' "$store" "$why" >&2
            exit 1
        fi
    fi
    printf 'lane_roster: sqlite3 failed reading %s: %s\n' "$store" "$ro_out" >&2
    exit 1
}

read_ro -json "$query"
rows="$ro_out"
[ -n "$rows" ] || rows='[]'

count=$(printf '%s' "$rows" | jq 'length')
if [ "$count" -eq 0 ]; then
    read_ro "SELECT COUNT(*) FROM runs WHERE id = ${run_id};"
    if [ "$ro_out" -eq 0 ] 2>/dev/null; then
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
