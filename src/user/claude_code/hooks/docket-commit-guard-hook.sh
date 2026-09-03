#!/bin/bash

# commit-guard (03 §5, TDD §4.5) — PreToolUse: Bash.
#
# Shim over `docket guard gate --step commit-gate`: `git commit/push/add` only
# behind an APPROVED human gate. The decision is the engine's; this hook holds
# no policy about which commits are acceptable.
#
# WHY THIS FILE IS NOT ONE LINE (deviation from AC-4.1's "one-line shim", argued
# rather than assumed). 03 §5 is explicit that this hook "replaces the 13KB awk-
# parser hook's job with an engine query" while "the awk hardening is RETAINED
# as the parser". Those are two statements about two different halves: the
# DECISION moves into the engine, the MATCHER stays. A literally-one-line
# `exec docket guard gate --step commit-gate` would deny every Bash call in the
# session, because the engine correctly denies when the gate is merely ABSENT
# ([OBSERVED] `no type="human" step named "commit-gate" in any active run`
# → exit 2). The matcher is what decides whether the engine is even the right
# question to ask. Everything between the `set -uo pipefail` below and the
# `[ "$MATCH" = "MATCH" ]` guard was lifted byte-identical from the retired
# fleet's claude-code/hooks/guard-no-commit-hook.sh (since deleted). This
# file is now that matcher's only home; its behavior is pinned
# by tests/docket-commit-guard-hook.test.sh.
#
# THE DECISION, and how it differs from the old fleet's. The old hook resolves
# on permission_mode: interactive modes get an `ask`, non-interactive modes get
# a hard deny, because a human must confirm each git write and in `auto` no
# human is at the prompt. The graph fleet answers that same question from engine
# state instead: an approved `commit-gate` step IS the recorded human decision,
# so it authorizes the write in any permission mode. That is the whole point of
# re-keying to engine truth — the approval happened, durably, at gate-approval
# time rather than at prompt time.
#
# Exit 0 allow / exit 2 deny with reason on stderr, matching the old hook's
# choice of exit 2 over a permissionDecision envelope: exit 2 is a
# pre-permission hard stop whose interaction with bypassPermissions is defined,
# and the guard family's native contract is already exit 0/2 (engine-spec §2).
#
# Fail-OPEN on a missing `docket` binary, fail-CLOSED on everything the engine
# itself judges. A tooling gap must not brick every Bash call in the session;
# an unapproved or absent gate must.

set -uo pipefail

allow_default() {
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
# HEREDOCS are the third quoting shape. A heredoc body is neither single- nor
# double-quoted content - the DELIMITER carries the quoting - so without the
# branch below every word of a body reached the matcher unmarked and a scratch
# file whose text merely described a git write was denied. A quoted-delimiter
# body (`<<'EOF'`, `<<"EOF"`, `<<\EOF`, and their `<<-` tab-stripping forms)
# cannot expand or execute anything IN THIS SHELL, so it is prose and is
# marked as ONE quote group -- but only when the command the body feeds is a
# text SINK (`cat`, `tee`, `dd`, pathed forms). The quoting says nothing about
# an inner shell: `bash <<'EOF'` runs its body as a script, so for any other
# head word the body stays unmarked and reaches the matcher. An
# unquoted-delimiter body (`<<EOF`) does expand and stays unmarked too.
#
# COMMENTS are consumed whole: on a `#` that begins a word, everything to the
# next newline is one prose quote group, so nothing inside a comment - a
# heredoc operator, an unbalanced quote - can arm state that swallows the real
# command on the line after it.
#
# The heredoc branch is REDIRECTION-POSITION aware, because `<<` is only a
# heredoc operator there: it does not fire on a here-string (`<<<WORD`, whose
# three characters are consumed whole), inside a comment, or inside an
# arithmetic expansion (`$((1 << 3))`, `((1 << 3))`, `for ((i = 1 << 2; ;))`)
# -- in each of those a firing branch armed a phantom delimiter and swallowed
# the rest of the command into one prose group. Pending heredocs are a QUEUE,
# so `cat <<A <<"B"` consumes each body in redirection order with its own
# quotedness instead of letting the last delimiter overwrite the first and
# mark an expanding body as prose. Leading tabs are stripped before the
# terminator comparison only for a `<<-` body, so a tab-indented line inside a
# plain `<<"EOF"` body no longer ends it early.
#
# ACCEPTED INACCURACIES, each stated with its failure direction, because this
# pre-pass models bash rather than parsing it and has no fail-closed default:
#   - An arithmetic spelling this branch does not count (`$[1 << 3]`, and any
#     future one) reaches the heredoc arm. A purely NUMERIC delimiter is
#     therefore refused, since no real script writes `<<3`; a shift by a
#     variable (`$[1 << k]`) still arms a phantom delimiter and swallows the
#     following lines - a false DENY.
#   - `cmd_head` finds the head word by scanning back to the nearest command
#     separator, so a separator that was escaped or quoted, or a leading
#     assignment (`LC_ALL=C cat <<"EOF"`), yields a word that is not a sink -
#     a false DENY.
#   - A git write passed as a single-quoted ARGUMENT to an interpreter
#     (`bash -c 'git push'`) is one prose group and is ALLOWED. This predates
#     the heredoc branch and is the quote-group design's standing tradeoff - a
#     false ALLOW, tracked separately.
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
# The head word of the simple command a heredoc redirection at POS belongs to,
# found by scanning back to the nearest command separator. Only a TEXT SINK
# gets its quoted body marked as prose: a quoted delimiter makes a body inert
# to the OUTER shell only, so an interpreter still runs every line of it in an
# inner shell. A head word this scan reads wrong (a leading assignment, a
# separator that was escaped or quoted) is simply not a sink, so the body stays
# unmarked -- a false DENY, never a missed invocation.
function cmd_head(pos,    k, ch, start, w) {
    start = 1
    for (k = pos - 1; k >= 1; k--) {
        ch = substr(line, k, 1)
        if (ch == ";" || ch == "&" || ch == "|" || ch == "(" || ch == ")" || ch == "\n") {
            start = k + 1
            break
        }
    }
    while (start < pos && substr(line, start, 1) ~ /[ \t]/) start++
    w = ""
    while (start < pos && substr(line, start, 1) !~ /[ \t]/) {
        w = w substr(line, start, 1)
        start++
    }
    sub(/^.*\//, "", w)
    return w
}
function is_text_sink(w) {
    return (w == "cat" || w == "tee" || w == "dd")
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
    HD_N = 0
    ARITH = 0
    WORD_START = 1
    while (i <= n) {
        c = substr(line, i, 1)
        if (c == "\\" && i < n) {
            out = out c substr(line, i + 1, 1)
            WORD_START = 0
            i += 2
            continue
        }
        if (c == "\n") {
            WORD_START = 1
            if (HD_N == 0) {
                out = out c
                i += 1
                continue
            }
            j = i + 1
            for (h = 1; h <= HD_N; h++) {
                body = ""
                while (j <= n) {
                    eol = index(substr(line, j), "\n")
                    if (eol == 0) {
                        seg = substr(line, j)
                        nj = n + 1
                    } else {
                        seg = substr(line, j, eol - 1)
                        nj = j + eol
                    }
                    trimmed = seg
                    if (HD_DASH[h]) sub(/^\t+/, "", trimmed)
                    j = nj
                    if (trimmed == HD_DELIM[h]) break
                    body = body "\n" seg
                }
                if (HD_QUOTED[h]) {
                    GROUP++
                    m = split(body, qw, /[ \t\n]+/)
                    for (k = 1; k <= m; k++) {
                        if (qw[k] != "") out = out " " MARK GROUP ":" qw[k] MARK
                    }
                    out = out "\n"
                } else {
                    out = out body "\n"
                }
            }
            HD_N = 0
            i = j
            continue
        }
        if (c == "#" && WORD_START) {
            j = i + 1
            content = ""
            while (j <= n && substr(line, j, 1) != "\n") {
                content = content substr(line, j, 1)
                j++
            }
            GROUP++
            m = split(content, qw, /[ \t]+/)
            for (k = 1; k <= m; k++) {
                if (qw[k] != "") out = out " " MARK GROUP ":" qw[k] MARK
            }
            out = out " "
            WORD_START = 1
            i = j
            continue
        }
        if (c == "(" && substr(line, i + 1, 1) == "(") {
            ARITH++
            out = out substr(line, i, 2)
            WORD_START = 1
            i += 2
            continue
        }
        if (ARITH > 0 && c == ")" && substr(line, i + 1, 1) == ")") {
            ARITH--
            out = out substr(line, i, 2)
            WORD_START = 1
            i += 2
            continue
        }
        if (c == "<" && substr(line, i + 1, 2) == "<<") {
            out = out " "
            WORD_START = 1
            i += 3
            continue
        }
        if (c == "<" && substr(line, i + 1, 1) == "<" && ARITH == 0) {
            sink = is_text_sink(cmd_head(i))
            j = i + 2
            dash = 0
            if (substr(line, j, 1) == "-") {
                dash = 1
                j++
            }
            while (j <= n && (substr(line, j, 1) == " " || substr(line, j, 1) == "\t")) j++
            dc = substr(line, j, 1)
            delim = ""
            dquoted = 0
            if (dc == SQ || dc == DQ) {
                dquoted = 1
                j++
                while (j <= n && substr(line, j, 1) != dc) {
                    delim = delim substr(line, j, 1)
                    j++
                }
                j++
            } else {
                if (dc == "\\") {
                    dquoted = 1
                    j++
                }
                while (j <= n && substr(line, j, 1) ~ /[A-Za-z0-9_.-]/) {
                    delim = delim substr(line, j, 1)
                    j++
                }
            }
            out = out " "
            WORD_START = 1
            i = j
            if (delim != "" && delim !~ /^[0-9]+$/) {
                HD_N++
                HD_DELIM[HD_N] = delim
                HD_QUOTED[HD_N] = (dquoted && sink)
                HD_DASH[HD_N] = dash
            }
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
            WORD_START = 0
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
            WORD_START = 0
            i = j + 1
            continue
        }
        out = out c
        WORD_START = (c ~ /[ \t;&|()<>]/)
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

# --- The decision: engine gate query, replacing the old hook's permission_mode
# --- case split. See this file's header for why an approved gate authorizes the
# --- write in any permission mode.
command -v docket >/dev/null 2>&1 || allow_default

if docket guard gate --step commit-gate >/dev/null 2>&1; then
    allow_default
fi

GATE_REASON=$(docket guard gate --step commit-gate 2>&1 >/dev/null) || true
[ -n "$GATE_REASON" ] || GATE_REASON="no approved commit-gate step in any active run"

# NOT-APPLICABLE IS NOT A DENIAL. [OBSERVED] internal/engine/guard.go:138-147 —
# the engine returns exactly three verdicts, and only ONE of them is this
# guard's business:
#
#   approved -> allow                                            (handled above)
#   found    -> `gate "commit-gate" is <state>, not approved`    (DENY: the case
#               this guard exists for — a run whose pipeline HAS a commit-gate
#               step that the operator has not yet approved)
#   default  -> `no type="human" step named "commit-gate" in any active run`
#               (ALLOW: the gate is ABSENT, not unapproved)
#
# The `default` arm is reached by a single query (`:101-108`) that joins steps
# to runs WHERE the run is active AND the step name matches AND kind=human. So
# ONE reason string covers two situations that are both "this guard has no
# opinion": no active run at all, and an active run whose pipeline simply has
# no commit-gate step (a retro or investigation pipeline, say). Denying either
# would brick every git write in a session that is not conducting a
# commit-bearing pipeline — which is exactly what the operator's no-run check
# found.
#
# Allowing here does NOT make those commits unguarded: `git commit` remains a
# `Bash(git commit:*)` permission-ask (E3), which is the whole of the remaining
# defense now that the old fleet's guard-no-commit-hook.sh is deleted. This hook
# re-keys the DECISION to engine truth where engine truth exists; it does not
# manufacture a verdict where the engine has declined to give one.
# "no docket database found" joins the not-applicable set for the same reason
# as the absent-gate arm: no DB means no run means this guard has no opinion.
# [MEASURED] every guard verb exits 2 with that error in a repo
# with no .docket up-tree — without this arm, this hook denies every git
# commit/push/add in every non-docket repo. Engine-side fix (NOT_FOUND off
# the deny channel) filed; this is the hook-side mitigation.
case $GATE_REASON in
    *'in any active run'*) allow_default ;;
    *'no docket database found'*) allow_default ;;
esac

deny "git write blocked: ${GATE_REASON}. A git write needs an APPROVED commit-gate step on an active run — approve it with \`docket step approve\`, then retry. If this command performs no git write, the retained text matcher has false-positived on git-write wording inside it (known limitation): to read a file's content, use the Read or Grep tool instead (bypasses this matcher entirely); only if the command must pass literal content through as an argument, write that content to a file and pass the path instead."
