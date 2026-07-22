#!/bin/bash
# Sidecar holder-file baton protocol for coordinating sole-editor access to a
# shared artifact (e.g. a TDD) across agents. claim and release happen in
# SEPARATE Bash tool-call processes (each Bash call is a fresh shell), so a
# process-bound lock (flock, or any lock tied to a held file descriptor)
# cannot survive between calls -- the claim must persist as an on-disk file
# instead. Atomicity comes from bash's `set -C` (noclobber), which opens the
# sidecar with O_CREAT|O_EXCL: a collision fails the redirection rather than
# truncating an existing holder's claim.
#
# Sidecar: sibling plaintext file `<artifact-path>.baton`, one line:
#   <holder>\t<epoch-seconds>\t<context>
#
# NO TTL / auto-expiry: a crashed holder's claim is NOT reclaimed
# automatically. `release <path> <holder>` (or an explicit unconditional
# `release <path>`) is required to clear a stale claim.
set -euo pipefail

usage() {
    echo "Usage: edit_baton.sh claim <artifact-path> <holder> [<context>]" >&2
    echo "       edit_baton.sh holder <artifact-path>" >&2
    echo "       edit_baton.sh release <artifact-path> [<holder>]" >&2
    echo "" >&2
    echo "  claim   : atomically create <artifact-path>.baton for <holder>." >&2
    echo "            Fails (nonzero exit) without overwriting if another" >&2
    echo "            holder already holds the baton." >&2
    echo "  holder  : print the current holder of <artifact-path>, or 'none'" >&2
    echo "            if unclaimed. Zero side effects." >&2
    echo "  release : remove <artifact-path>.baton. No-op (exit 0) if" >&2
    echo "            already unclaimed. If <holder> is given, removes ONLY" >&2
    echo "            if it matches the current holder (exit nonzero, file" >&2
    echo "            untouched, otherwise); omit <holder> to release" >&2
    echo "            unconditionally." >&2
    echo "" >&2
    echo "  NOTE: no TTL/auto-expiry. A crashed holder's claim persists" >&2
    echo "  until explicitly released." >&2
    exit 1
}

if [ "$#" -lt 2 ]; then
    usage
fi

SUBCOMMAND="$1"
ARTIFACT="$2"
shift 2

SIDECAR="${ARTIFACT}.baton"

read_holder() {
    if [ ! -f "$SIDECAR" ]; then
        echo "none"
        return 0
    fi
    cut -f1 "$SIDECAR"
}

case "$SUBCOMMAND" in
    claim)
        if [ "$#" -lt 1 ]; then
            usage
        fi
        HOLDER="$1"
        CONTEXT="${2:-}"
        EPOCH=$(date +%s)
        if ( set -C; printf '%s\t%s\t%s\n' "$HOLDER" "$EPOCH" "$CONTEXT" > "$SIDECAR" ) 2>/dev/null; then
            echo "claimed ${ARTIFACT} for ${HOLDER}"
            exit 0
        fi
        CURRENT_HOLDER=$(read_holder)
        echo "edit_baton.sh: claim failed — ${ARTIFACT} already held by '${CURRENT_HOLDER}'" >&2
        exit 1
        ;;
    holder)
        read_holder
        exit 0
        ;;
    release)
        REQUESTED_HOLDER="${1:-}"
        if [ ! -f "$SIDECAR" ]; then
            exit 0
        fi
        if [ -n "$REQUESTED_HOLDER" ]; then
            CURRENT_HOLDER=$(read_holder)
            if [ "$CURRENT_HOLDER" != "$REQUESTED_HOLDER" ]; then
                echo "edit_baton.sh: release refused — ${ARTIFACT} is held by '${CURRENT_HOLDER}', not '${REQUESTED_HOLDER}'" >&2
                exit 1
            fi
        fi
        rm -f "$SIDECAR"
        exit 0
        ;;
    *)
        usage
        ;;
esac
