#!/bin/bash

# Worktree prune — SessionStart.
#
# A session cannot delete a wave worktree's metadata directory
# (`<bare repo>/worktrees/<name>`): the harness puts that directory's
# `commondir` file on the sandbox's denyWithinAllow list, so an in-session
# `git worktree prune -v` fails on it with "Device or resource busy" and the
# entry stays `prunable` until someone prunes outside the sandbox. A hook is a
# harness child process, not a Bash-tool call, so the prune runs here instead
# of at the operator's prompt.
#
# PRUNE ONLY. git removes only entries it reports `prunable` (the working
# directory is gone) and skips locked ones, so a live worktree is never
# touched. Branch refs are left to docket-run's own sweep.
#
# STDOUT IS CONTEXT. SessionStart stdout reaches the model, so `-v` names each
# removed entry there and a repo with nothing to prune prints nothing.
#
# EXIT 0 ALWAYS. SessionStart cannot block, and a failed prune leaves the
# entries exactly as they were; git's own message on stderr is the only trace.

git rev-parse --git-dir >/dev/null 2>&1 || exit 0

git worktree prune -v 2>&1

exit 0
