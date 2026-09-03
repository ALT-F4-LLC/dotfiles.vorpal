#!/bin/bash

# Drift check for the deliberately duplicated docket skill.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
# — in the `skill-sync` job, which is `continue-on-error` because the two
# copies are known to differ today; the drift is reported, not gated.
#
# The docket CLI's skill lives twice: this repo's corpus copy at
# src/user/claude_code/skills/docket/SKILL.md (what `just activate` installs
# and every session executes), and the engine repo's own copy at
# docket.git/main/skills/docket/SKILL.md, which the engine's
# self-hygiene gate keeps current as verbs change. Drift between them ships
# stale guidance to every session (2026-08-19 fleet review: 282 lines of
# drift including a load-bearing conductor caution, installed stale that
# same night). This suite byte-diffs the two copies and fails on ANY drift —
# convergence means an edit lands in BOTH, in the same session.
#
# DOCKET_SKILL_UPSTREAM overrides the engine-copy path. An absent engine
# checkout is a SKIP on a developer machine, so machines without the sibling
# repo stay green. Under CI it is a FAILURE: a skip there would make this
# suite green-by-default and catch no drift at all, which is the one place
# the check has to bite.
set -uo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
LOCAL="$HERE/src/user/claude_code/skills/docket/SKILL.md"
# The fallback is a developer's local engine worktree. CI does not use it: the
# `skill-sync` job in `.github/workflows/vorpal.yaml` checks the engine repo out
# and sets DOCKET_SKILL_UPSTREAM. Moving one of the two means moving the other.
UPSTREAM="${DOCKET_SKILL_UPSTREAM:-$HOME/Development/repository/github.com/ALT-F4-LLC/docket.git/main/skills/docket/SKILL.md}"

if [ ! -f "$UPSTREAM" ]; then
    if [ -n "${CI:-}" ] || [ -n "${GITHUB_ACTIONS:-}" ]; then
        echo "FAIL: engine checkout not present at $UPSTREAM — CI must provide it"
        exit 1
    fi
    echo "SKIP: engine checkout not present at $UPSTREAM"
    exit 0
fi

if diff -u "$LOCAL" "$UPSTREAM"; then
    echo "PASS: docket skill copies are byte-identical"
else
    echo "FAIL: docket skill copies have drifted"
    echo "  this repo: $LOCAL ($(wc -l <"$LOCAL" | tr -d ' ') lines)"
    echo "  engine:    $UPSTREAM ($(wc -l <"$UPSTREAM" | tr -d ' ') lines)"
    echo "  If you edited either copy, land the edit in BOTH, same session."
    echo "  If you edited neither, the drift came from the engine copy moving:"
    echo "  reconcile it there and here, not by patching this PR."
    exit 1
fi
