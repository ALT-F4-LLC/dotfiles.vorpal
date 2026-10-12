#!/bin/bash

# Worktree and branch cleanup — SessionStart.
#
# A session cannot delete a wave worktree's metadata directory
# (`<bare repo>/worktrees/<name>`): the harness puts that directory's
# `commondir` file on the sandbox's denyWithinAllow list, so an in-session
# `git worktree prune -v` fails on it with "Device or resource busy" and the
# entry stays `prunable` until someone prunes outside the sandbox. A hook is a
# harness child process, not a Bash-tool call, so the cleanup runs here instead
# of at the operator's prompt.
#
# WORKTREES. git removes only entries it reports `prunable` (the working
# directory is gone) and skips locked ones, so a live worktree is never
# touched.
#
# BRANCHES. After the prune, a `worktree-wf_*` or `worktree-agent-*` branch
# that no worktree entry holds is a leftover of a finished wave or agent. It is
# deleted when every commit on it is already on HEAD, by ancestry or as a
# patch-equivalent cherry-pick. One that still carries a commit HEAD lacks is
# kept and named, since deleting it would drop the only ref to that work.
#
# STDOUT IS CONTEXT. SessionStart stdout reaches the model, so each removed
# entry, deleted ref and kept ref is named there and a repo with nothing to
# clean prints nothing.
#
# EXIT 0 ALWAYS. SessionStart cannot block, and a failed step leaves the
# entries and refs exactly as they were.

git rev-parse --git-dir >/dev/null 2>&1 || exit 0

git worktree prune -v 2>&1

held=$(git worktree list --porcelain 2>/dev/null | sed -n 's/^branch //p')

git for-each-ref --format='%(refname)' 'refs/heads/worktree-wf_*' 'refs/heads/worktree-agent-*' 2>/dev/null |
    while read -r ref; do
        printf '%s\n' "$held" | grep -qxF "$ref" && continue
        sha=$(git rev-parse --verify -q "$ref") || continue
        if ! ahead=$(git cherry HEAD "$ref" 2>/dev/null); then
            echo "kept $ref $sha: could not compare it with HEAD"
            continue
        fi
        if printf '%s\n' "$ahead" | grep -q '^+'; then
            echo "kept $ref $sha: it carries commits HEAD lacks"
            continue
        fi
        git update-ref -d "$ref" "$sha" && echo "deleted $ref $sha"
    done

exit 0
