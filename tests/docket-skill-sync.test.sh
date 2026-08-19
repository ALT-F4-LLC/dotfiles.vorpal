#!/bin/bash

# Drift check for the deliberately duplicated docket skill.
#
# The docket CLI's skill lives twice: this repo's corpus copy at
# src/user/claude_code/skills/docket/SKILL.md (what `just activate` installs
# and every session executes), and the engine repo's own copy at
# docket.git/feature/graph-engine/skills/docket/SKILL.md, which the engine's
# self-hygiene gate keeps current as verbs change. Drift between them ships
# stale guidance to every session (2026-08-19 fleet review: 282 lines of
# drift including a load-bearing conductor caution, installed stale that
# same night). This suite byte-diffs the two copies and fails on ANY drift —
# convergence means an edit lands in BOTH, in the same session.
#
# DOCKET_SKILL_UPSTREAM overrides the engine-copy path. An absent engine
# checkout is a SKIP, not a failure, so machines without the sibling repo
# stay green.
set -uo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
LOCAL="$HERE/src/user/claude_code/skills/docket/SKILL.md"
UPSTREAM="${DOCKET_SKILL_UPSTREAM:-$HOME/Development/repository/github.com/ALT-F4-LLC/docket.git/feature/graph-engine/skills/docket/SKILL.md}"

if [ ! -f "$UPSTREAM" ]; then
    echo "SKIP: engine checkout not present at $UPSTREAM"
    exit 0
fi

if diff -u "$LOCAL" "$UPSTREAM"; then
    echo "PASS: docket skill copies are byte-identical"
else
    echo "FAIL: docket skill copies have drifted — land the edit in BOTH copies, same session"
    exit 1
fi
