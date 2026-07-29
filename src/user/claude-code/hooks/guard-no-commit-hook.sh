#!/bin/bash

# Mistake-guard for an honest-but-careless agent, NOT a closed enforcement
# boundary against deliberate evasion. The hook's only input is
# `.tool_input.command` (the literal Bash tool-call command string) - it
# never sees the contents of a file that string merely names. That makes
# the following classes structurally invisible to it, regardless of any
# text-matcher refinement:
#   - shell indirection: `bash -c "..."`, `sh -c '...'`, `eval "..."`, or
#     piping a command string into a shell (`echo "..." | bash`)
#   - wrapper-script invocation: `bash foo.sh` / `sh foo.sh` / `./foo.sh`
#     where the script's CONTENTS perform the git write
#   - variable-indirected shell invocation (the interpreter is computed at
#     runtime rather than appearing literally in the command string)
#   - non-shell interpreters (python/perl/ruby/etc. performing a git write
#     internally)
#   - computed subcommand: the verb `git` is literal, but the subcommand
#     word is produced by expansion or substitution (`git $V`, `git
#     $(echo commit)`) - the subcommand token truncates to empty at the
#     first non-identifier character and never matches, same as a fully
#     computed interpreter above
# These are accepted residual risk, not defects in this hook - closing them
# would require mediating where the git operation actually executes (e.g.
# a repo-level pre-commit/pre-push git hook), not refining a text matcher.
#
# Separately, by design this matcher only gates the three subcommands most
# likely to represent a completed, hard-to-revert git write (commit/push/
# add) - other write-shaped git subcommands (pull, stash, cherry-pick,
# merge, rebase, revert, am, and their --continue forms) are fully visible
# to this matcher, not a residual limitation like the classes above; they
# are simply not gated, a deliberate scope decision.
#
# TRIPWIRE (DKT-175/DKT-182): src/user/claude-code/scripts/commit_execute.sh
# is exactly the wrapper-script-invocation case above today - it is
# unwired/unreachable from any skill right now, so there is no live
# exposure yet. Wiring it (or any other git-writing script) into a skill
# so it becomes reachable is exactly the moment this control must be
# re-decided FIRST, before wiring proceeds - see that script's own header
# for the measured trade DKT-182 made against it.
#
# One accepted false positive, by design: `git commit --help` still DENYs.
# Only the option-before-subcommand help form (`git --help commit`) is
# exempted below - exempting the subcommand-before-flag form too would
# require scanning past the subcommand for a trailing flag, which would let
# a commit whose message argument merely contains the text "--help" wrongly
# ALLOW. Any other false positive (git-write-shaped wording denied even
# though the command performs no git write) has a documented escape hatch
# in the deny message below - but that message's own file-and-path route is
# for when the command must pass literal content through as an argument
# (e.g. a comment body). For a genuine READ of a file's content that got
# wrongly matched, use the Read or Grep tool instead of a Bash command -
# that bypasses this matcher entirely and does not exercise the
# file-and-path escape hatch at all.
#
# Two separate "could not determine state" paths resolve oppositely, by
# design: a missing/unrecognized permission_mode fails DENY (fail-closed -
# the safer direction when this hook can't tell which mode applies), but
# malformed/non-JSON stdin fails ALLOW (fail-open, matching every other
# early parse failure in this hook). If the harness's stdin schema ever
# changes or breaks, this hook silently allows every git write.

set -uo pipefail

ASK_REASON="git writes require explicit human approval each time - approve this commit at the prompt."

allow_default() {
    exit 0
}

ask() {
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s"}}\n' "$ASK_REASON"
    exit 0
}

# Exit 2 is a pre-permission hard stop: it blocks the tool call before
# permission rules/mode are evaluated at all, unlike a JSON
# permissionDecision:"deny" whose interaction with bypassPermissions mode is
# undocumented. Used for every deny path below so the block holds regardless
# of permission mode.
deny() {
    printf '%s\n' "$1" >&2
    exit 2
}

INPUT=$(cat 2>/dev/null) || allow_default

if ! command -v jq >/dev/null 2>&1; then
    allow_default
fi

TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null) || allow_default
[ "$TOOL_NAME" = "Bash" ] || allow_default

COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null) || allow_default
[ -n "$COMMAND" ] || allow_default

# Quote-aware pre-pass: distinguishes prose that merely *mentions* a
# git-write command (e.g. inside a docket comment's -m body) from an actual
# invocation, without discarding quoted subcommand names outright - deleting
# them entirely would let a form like `git "commit"` (which bash unquotes to
# a real `git commit` at execution) slip past the matcher unnoticed.
#
# Every word found inside a quoted string is preserved but wrapped with a
# sentinel marker (ASCII 0x01) that also encodes a QUOTE-GROUP id, e.g.
# 0x01<n>:word0x01, where every word originating from the SAME quoted
# string (one opening/closing quote pair) shares one group number and each
# successive quoted string gets a new, distinct number. Group identity -
# not just "was this word quoted at all" - is what lets the matcher below
# tell a single quoted phrase like `-m "... git commit ..."` (one group,
# prose, allow) apart from two separately-quoted words like
# `"git" "commit"` (two groups, a real bash-unquoted invocation, deny).
# Single-quoted content is always marked (bash performs no expansion inside
# single quotes, so it can never itself execute, but the same marking is
# still required so `git 'commit'` is recognized as a real invocation, not
# discarded). Double-quoted content is marked the same way UNLESS it
# contains `$(`, a backtick, or `${` - that content can still trigger
# command/parameter substitution despite the surrounding quotes, so it is
# left bare/unmarked for the matcher to inspect. A command-substitution
# capture shape like `echo "$(git commit -m x)"` is closed by the head-
# normalization step in the matcher below, which resolves a token's head
# past a preceding `$(`, backtick, `(`, `;`, `|`, or `&` before testing it
# against `git`. The matcher applies the same normalization to the
# subcommand token, so a delimiter glued directly AFTER the subcommand with
# nothing else following (`$(git push)`, `` `git push` ``, `(git commit)`,
# bare `git push;`/`git push&`/`git push|cat`) is also closed, not just the
# medial forms with trailing content.
#
# The whole COMMAND is buffered into a single blob before scanning (rather
# than processed line-by-line) so quote-tracking state carries across
# embedded newlines - otherwise a multi-line quoted argument (e.g. a
# multi-paragraph docket comment body) would have its quote state reset at
# each line boundary and a git-write phrase on line 2+ would false-positive
# as if it were bare/unquoted.
STRIPPED=$(printf '%s' "$COMMAND" | awk '
{
    buf = (NR == 1) ? $0 : buf "\n" $0
}
END {
    line = buf
    n = length(line)
    out = ""
    i = 1
    SQ = "\047"
    DQ = "\042"
    MARK = "\001"
    GROUP = 0
    while (i <= n) {
        c = substr(line, i, 1)
        if (c == "\\" && i < n) {
            out = out c substr(line, i + 1, 1)
            i += 2
            continue
        }
        if (c == SQ) {
            j = i + 1
            content = ""
            while (j <= n && substr(line, j, 1) != SQ) {
                content = content substr(line, j, 1)
                j++
            }
            GROUP++
            m = split(content, qw, /[ \t\n]+/)
            for (k = 1; k <= m; k++) {
                if (qw[k] != "") out = out " " MARK GROUP ":" qw[k] MARK
            }
            out = out " "
            i = j + 1
            continue
        }
        if (c == DQ) {
            j = i + 1
            content = ""
            while (j <= n) {
                cc = substr(line, j, 1)
                if (cc == "\\" && j < n) {
                    content = content cc substr(line, j + 1, 1)
                    j += 2
                    continue
                }
                if (cc == DQ) break
                content = content cc
                j++
            }
            if (content ~ /\$\(|`|\$\{/) {
                out = out " " content " "
            } else {
                GROUP++
                m = split(content, qw, /[ \t\n]+/)
                for (k = 1; k <= m; k++) {
                    if (qw[k] != "") out = out " " MARK GROUP ":" qw[k] MARK
                }
                out = out " "
            }
            i = j + 1
            continue
        }
        out = out c
        i += 1
    }
    print out
}
' 2>/dev/null) || allow_default
MATCH=$(printf '%s' "$STRIPPED" | awk '
BEGIN { MARK = "\001" }
function decode(raw,    inner, cpos) {
    if (length(raw) >= 2 && substr(raw, 1, 1) == MARK && substr(raw, length(raw), 1) == MARK) {
        inner = substr(raw, 2, length(raw) - 2)
        cpos = index(inner, ":")
        D_GROUP = substr(inner, 1, cpos - 1)
        D_WORD = substr(inner, cpos + 1)
        gsub(/^[\047\042]+|[\047\042]+$/, "", D_WORD)
        return 1
    }
    D_GROUP = ""
    D_WORD = raw
    gsub(/^[\047\042]+|[\047\042]+$/, "", D_WORD)
    return 0
}
{
    n = split($0, words, /[ \t]+/)
    for (i = 1; i <= n; i++) {
        hquoted = decode(words[i])
        hgroup = D_GROUP
        w = D_WORD
        # Resolve the token head past a preceding command-substitution,
        # subshell, or separator prefix (`X=$(`, backtick, `(`, `;`, `|`, `&`)
        # before testing it against `git`. This is what closes a
        # capture-output shape like `X=$(git commit -m y)` - the assignment
        # and `$(` are glued onto the same whitespace-delimited token as
        # `git`, so without this the head never equals "git" at all. It does
        # not touch how a matched *subcommand* is judged, so substitution-READ
        # shapes (`SHA=$(git log -1)`, `$(git remote add ...)`) are unaffected
        # since their subcommand still is not commit/push/add.
        hw = w
        sub(/^.*(\$\(|\140|\(|;|\||&)/, "", hw)
        if (hw == "git" || hw ~ /\/git$/) {
            j = i + 1
            helped = 0
            while (j <= n) {
                decode(words[j])
                opt = D_WORD
                if (opt !~ /^-/) break
                # Option-before-subcommand help exemption only (`git --help
                # commit`) - see header for why the subcommand-before-flag
                # form (`git commit --help`) is an accepted false positive
                # instead.
                if (opt == "--help" || opt == "-h") helped = 1
                if (opt == "-C" || opt == "-c" || opt == "--git-dir" || opt == "--work-tree" || opt == "--exec-path" || opt == "--namespace" || opt == "--super-prefix" || opt == "--config-env" || opt == "--attr-source") {
                    j += 2
                } else {
                    j += 1
                }
            }
            if (j <= n && !helped) {
                squoted = decode(words[j])
                sgroup = D_GROUP
                s = D_WORD
                # Symmetric to the head normalization above: strip a
                # trailing delimiter glued directly onto the subcommand
                # (closing paren/backtick, `;`, `|`, `&`) before comparing
                # it. This closes the terminal-position counterpart of the
                # head fix (`$(git push)`, `` `git push` ``, `(git commit)`,
                # bare `git push;`/`git push&`/`git push|cat`) without
                # affecting multi-word subcommand names like `commit-tree`/
                # `commit-graph` (hyphen stays part of the identifier).
                sw = s
                sub(/[^A-Za-z0-9_-].*$/, "", sw)
                if (sw == "commit" || sw == "push" || sw == "add") {
                    if (hquoted && squoted && hgroup == sgroup) continue
                    print "MATCH"
                    exit
                }
            }
        }
    }
}
' 2>/dev/null)
[ "$MATCH" = "MATCH" ] || allow_default

PERMISSION_MODE=$(printf '%s' "$INPUT" | jq -r '.permission_mode // empty' 2>/dev/null) \
    || deny "git write blocked - could not determine permission_mode from hook input."

case "$PERMISSION_MODE" in
    default | plan | acceptEdits)
        ask
        ;;
    auto | dontAsk | bypassPermissions)
        deny "git writes are blocked in non-interactive permission mode '${PERMISSION_MODE}' where a human can't confirm approval - switch to an interactive mode (default/plan/acceptEdits) to commit. If this command performs no git write, the text matcher has false-positived on git-write wording inside it (known limitation): to read a file's content, use the Read or Grep tool instead (bypasses this matcher entirely); only if the command must pass literal content through as an argument, write that content to a file and pass the path instead."
        ;;
    *)
        deny "git write blocked - could not determine permission_mode from hook input."
        ;;
esac
