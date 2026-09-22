#!/usr/bin/env bash
#
# peer-name — print the session name the peer convention expects for the
# current directory, so a session can compare it with the first line of
# `ListAgents` and ask the operator to `/rename` when they differ.
#
# The convention, in order:
#   1. Inside a git checkout, the repository's name: the basename of the
#      common git directory when the repository is bare (this org's
#      `<repo>.git/<worktree>` layout), else the basename of the directory
#      that holds `.git`. A trailing `.git` is dropped.
#   2. When the repository has more than one non-bare worktree, the
#      worktree's own directory name is appended with a hyphen, so two
#      sessions in two worktrees of one repository get distinct names.
#      A repository with a single worktree keeps the bare repository name.
#   3. Outside git, the current directory's basename.
#   4. Every character outside [A-Za-z0-9_-] becomes a hyphen, so the name
#      works in the `@` typeahead without quotes.
#
# Read-only: it runs `git rev-parse` and `git worktree list` and writes
# nothing. Exit 0 with the name on stdout.

set -euo pipefail

if top="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  common="$(git rev-parse --path-format=absolute --git-common-dir)"
  if [ "$(basename "$common")" = ".git" ]; then
    repo="$(basename "$(dirname "$common")")"
  else
    repo="$(basename "$common")"
  fi
  name="${repo%.git}"
  worktrees="$(git worktree list --porcelain | awk '/^worktree /{n++} /^bare$/{n--} END{print n+0}')"
  if [ "$worktrees" -gt 1 ]; then
    name="${name}-$(basename "$top")"
  fi
else
  name="$(basename "$PWD")"
fi

printf '%s\n' "$name" | sed 's/[^A-Za-z0-9_-]/-/g'
