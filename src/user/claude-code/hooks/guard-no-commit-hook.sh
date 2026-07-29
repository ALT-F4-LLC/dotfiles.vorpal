#!/bin/bash

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
# left bare/unmarked for the matcher to inspect (this does not currently
# catch a git-write command embedded inside such a substitution, e.g.
# `echo "$(git commit -m x)"` - the substitution's `$(` prefix defeats the
# exact-token match below; this is a pre-existing tokenization gap, not
# something this pre-pass introduces or is required to close).
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

# Tokenizes on whitespace and, for every `git` token (bare OR
# sentinel-marked - a marked head is no longer skipped outright, since a
# quoted git plus a bare/differently-quoted subcommand, e.g. `"git" commit`,
# is still a real bash-unquoted invocation), skips recognized global options
# (including ones that consume a following value, e.g. `-C <path>`,
# regardless of whether that value token happens to be quoted - a
# value-consuming option following a bare `git` can only arise from a real
# invocation, since a prose mention has its `git` head marked too and is
# already suppressed by the group check below) before matching the first
# remaining token against commit/push/add.
#
# A candidate match is suppressed as prose ONLY when BOTH the head and the
# matched subcommand token are sentinel-marked AND share the SAME
# quote-group id - that means the entire phrase, including the literal word
# "git", sits inside one single quoted argument (e.g. a docket comment's -m
# body), which is inert prose. Every other combination denies: bare head +
# bare subcommand (plain invocation); bare head + marked subcommand of any
# group (`git "commit"` / `git 'push' origin main`); marked head + bare
# subcommand or marked-with-a-DIFFERENT-group subcommand (`"git" commit` /
# `"git" "commit" -m x` - two separately-quoted words that bash unquotes
# into a real invocation). This avoids false-denying `git remote add` /
# `git submodule add` / `git worktree add`, and correctly denies
# `git -C <path> commit`, `git -c user.email=x commit`, `git --no-pager
# push`, and `git "-C" <path> commit`.
GIT_WRITE_SCRIPTS='commit_execute.sh'
GIT_READ_SUBCOMMANDS='log,show,blame,cat-file,ls-files,status,describe,rev-parse'
INERT_READERS='cat,bat,head,tail,less,more,nl,od,xxd,hexdump,strings,wc,grep,rg,egrep,fgrep,ag,sed,awk,cut,sort,uniq,tr,fold,column,jq,yq,diff,cmp,comm,shasum,md5sum,sha1sum,sha256sum,file,stat,realpath,readlink,basename,dirname,ls,du,tree,cp,mv,rm,ln,touch,mkdir,chmod,chown,chgrp,install,tar,zip,unzip,gzip,gunzip,rsync,scp,vim,nvim,vi,emacs,nano,shellcheck,shfmt,prettier,test,[,docket,echo,printf,fmt,lint,check,format,ruff,pyflakes,mypy,pylint,black,eslint,tsc'
MATCH=$(printf '%s' "$STRIPPED" | awk -v REGISTRY="$GIT_WRITE_SCRIPTS" -v INERT="$INERT_READERS" -v GITSUBS="$GIT_READ_SUBCOMMANDS" '
BEGIN {
    MARK = "\001"
    split(REGISTRY, _rg, ","); for (_k in _rg) REG[_rg[_k]] = 1
    split(INERT, _sp, ",");    for (_k in _sp) SUP[_sp[_k]] = 1
    split(GITSUBS, _gs, ","); for (_k in _gs) GITSUB[_gs[_k]] = 1
}
function bname(w,   p) {
    p = w
    gsub(/^[\047\042]+|[\047\042]+$/, "", p)
    sub(/^.*\//, "", p)
    gsub(/^[\047\042]+|[\047\042]+$/, "", p)
    return p
}
function ismarked(raw) {
    return (length(raw) >= 2 && substr(raw, 1, 1) == MARK && substr(raw, length(raw), 1) == MARK)
}
function git_head_before(k,   g, rr, mk, ww) {
    for (g = k - 1; g >= 1; g--) {
        rr = words[g]
        mk = ismarked(rr)
        decode(rr)
        ww = bname(D_WORD)
        if (!mk && D_WORD ~ /[;|&`()\n]/) return 0
        if (ww == "git") return g
    }
    return 0
}
# Reuses the global-option skip list the hook already has (line 193) in its natural
# forward direction: find the preceding `git`, walk forward over exactly the
# options the existing matcher already skips, and require the walk to land on
# this token. No new grammar modeling -- the enumeration is already verified.
function git_read_adjacent(k,   g, j, o) {
    g = git_head_before(k)
    if (g == 0) return 0
    j = g + 1
    while (j < k) {
        decode(words[j])
        o = D_WORD
        if (o !~ /^-/) return 0
        if (o == "-C" || o == "-c" || o == "--git-dir" || o == "--work-tree" || o == "--exec-path" || o == "--namespace" || o == "--super-prefix" || o == "--config-env" || o == "--attr-source") j += 2
        else j += 1
    }
    return (j == k)
}
function inert_before(idx,   k, raw, marked, wk, bw, nf, tfr, nf2, tfr2) {
    for (k = idx - 1; k >= 1; k--) {
        raw = words[k]
        marked = ismarked(raw)
        decode(raw)
        wk = D_WORD
        if (!marked && wk ~ /[;|&`()\n]/) {
            # The token carries a command boundary. Its TRAILING fragment is
            # the head of the command that owns our token (`$(realpath`,
            # `foo;cat`), so test that head for inertness before stopping --
            # otherwise every substitution/separator wrapper severs the scan
            # and false-denies an ordinary read. Still purely lexical.
            nf = split(wk, tfr, /[;|&`()\n]+/)
            if (nf >= 1 && tfr[nf] != "" && (bname(tfr[nf]) in SUP)) return 1
            return 0
        }
        bw = bname(wk)
        # A marked token can also glue an inert head to a separator
        # (`cd /r&&cat script.sh` -> one marked word `/r&&cat`). Test its
        # trailing fragment for inertness too, symmetrically with the bare
        # barrier branch above. Any suppression this adds falls inside the
        # already-documented RES-1 lexical class.
        if (marked && !(bw in SUP) && !(bw in GITSUB)) {
            nf2 = split(wk, tfr2, /[;|&`()\n]+/)
            if (nf2 > 1 && tfr2[nf2] != "") {
                if (bname(tfr2[nf2]) in SUP) return 1
                if (bname(tfr2[nf2]) in GITSUB) { if (git_read_adjacent(k)) return 1 }
            }
        }
        if (bw in GITSUB) {
            if (git_read_adjacent(k)) return 1
            continue
        }
        if (bw in SUP) return 1
    }
    return 0
}
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
    # O(n) forward precompute of inert_before(): one left-to-right pass
    # maintaining "an INERT word has been seen since the last barrier".
    # Exactly equivalent to the backward scan (which skips non-inert tokens and
    # stops at the first barrier), but linear instead of quadratic -- the
    # backward form measured 664ms on a 1000-word comment with 500 basename
    # mentions, on a hook that runs for EVERY Bash tool call.
    ia = 0
    for (ri = 1; ri <= n; ri++) {
        rraw = words[ri]
        rmarked = ismarked(rraw)
        decode(rraw)
        rw = D_WORD
        rb = bname(rw)

        # --- registry test uses the state as of tokens BEFORE this one ---
        fm = split(rw, frags, /[;|&`()]+/)
        for (fi = 1; fi <= fm; fi++) {
            if (frags[fi] == "") continue
            if (bname(frags[fi]) in REG) {
                if (!rmarked && fi > 1) { print "MATCH"; exit }
                if (!ia) { print "MATCH"; exit }
            }
        }

        # --- then fold this token into the state ---
        if (!rmarked && rw ~ /[;|&`()\n]/) {
            nf = split(rw, tfr, /[;|&`()\n]+/)
            tf = (nf >= 1) ? bname(tfr[nf]) : ""
            # A SUBSTITUTION opener is not an ordinary command boundary: the
            # inner command produces a VALUE consumed by the OUTER command.
            # If the inner head is inert (`$(realpath X)`), the path is data and
            # the OUTER head decides -- so carry ia through unchanged. If the
            # inner head is NOT inert it may execute the path itself
            # (`$(bash X)`), so clear ia. Returning "suppressed" on an inert
            # inner head was a measured FAIL-OPEN: `bash $(echo /x/script)`
            # allowed while it correctly denied before.
            if (rw ~ /\$\(|`|<\(|>\(/) {
                if (!(tf in SUP)) ia = 0
            } else {
                ia = (tf != "" && (tf in SUP)) ? 1 : 0
            }
            continue
        }
        if (rb in GITSUB) { if (git_read_adjacent(ri)) ia = 1; continue }
        if (rb in SUP) { ia = 1; continue }
        if (rmarked) {
            nf2 = split(rw, tfr2, /[;|&`()]+/)
            if (nf2 > 1 && tfr2[nf2] != "") {
                if (bname(tfr2[nf2]) in SUP) ia = 1
                else if ((bname(tfr2[nf2]) in GITSUB) && git_read_adjacent(ri)) ia = 1
            }
        }
    }
    for (i = 1; i <= n; i++) {
        hquoted = decode(words[i])
        hgroup = D_GROUP
        w = D_WORD
        if (w == "git" || w ~ /\/git$/) {
            j = i + 1
            while (j <= n) {
                decode(words[j])
                opt = D_WORD
                if (opt !~ /^-/) break
                if (opt == "-C" || opt == "-c" || opt == "--git-dir" || opt == "--work-tree" || opt == "--exec-path" || opt == "--namespace" || opt == "--super-prefix" || opt == "--config-env" || opt == "--attr-source") {
                    j += 2
                } else {
                    j += 1
                }
            }
            if (j <= n) {
                squoted = decode(words[j])
                sgroup = D_GROUP
                s = D_WORD
                if (s == "commit" || s == "push" || s == "add") {
                    if (hquoted && squoted && hgroup == sgroup) {
                        continue
                    }
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
        deny "git writes are blocked in non-interactive permission mode '${PERMISSION_MODE}' where a human can't confirm approval - switch to an interactive mode (default/plan/acceptEdits) to commit."
        ;;
    *)
        deny "git write blocked - could not determine permission_mode from hook input."
        ;;
esac
