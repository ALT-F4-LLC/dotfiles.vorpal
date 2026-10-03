# Shared quote-group pre-pass for docket-trust-guard-hook.sh and
# docket-commit-guard-hook.sh. Both hooks feed this the same SCAN_TEXT (their
# post-widening leaf buffer) via `awk -f`; see either hook's header for the
# redesign this pre-pass is part of. Read as one file rather than
# duplicated inline so a lexer fix lands once instead of twice.
#
# A quoted group in ONE position is code rather than prose: the argument an
# interpreter executes verbatim. True when the word immediately before the
# group is a code flag AND some earlier word on the SAME leaf line is an
# interpreter. The flags that count are the union of every listed
# interpreters own: -c and any short bundle ending in c (the shells,
# python, expect), -e, -E, -p, -r, --eval, --print. A union rather than a
# per-interpreter map errs toward DENY, the direction this file takes for
# an unresolvable case.
# KNOWN RESIDUALS, listed so a reader can tell a decision from a miss: awk,
# ssh, xargs and find -exec carry code with no code flag at all, and a verb
# reached through a variable (C="..." on one leaf, an interpreter reading $C
# on the next) leaves no literal run of words behind a flag. Those stay
# ALLOW and are pinned as such in both suites.
# A flag or an interpreter reached through an unresolved expansion is the
# same residual one step earlier: F=-c on one leaf and bash $F on the next,
# I=bash with $I -c, or bash $(printf -- -c) all leave a look-behind word
# this pass cannot evaluate, so the group after it stays prose and ALLOWs.
# Deciding those words the other way (DENY on any word carrying $ or a
# backtick) closes only the flag half -- an interpreter reached through an
# expansion is never recognized as an interpreter in the first place -- while
# denying every ordinary bash "$SCRIPT" ... form, so they stay ALLOW and are
# pinned as such in both suites. The words below are what bash builds from
# LITERAL text, never what an expansion would produce.
# env and tclsh are deliberately absent from the interpreter list here: env
# carries no code flag of its own (env bash -c still matches on bash) and
# tclsh has none, so listing them would only widen the false-DENY surface.
# The look-behind stops at a newline. Leaves are newline-separated in this
# buffer, so the last words of one leaf must not qualify a quoted group that
# opens the next one.
# A caller may also end each leaf with a \036 byte, which both hooks refuse in
# a command, so only the caller can place one. It reads as a newline, and it
# also stops a quote this pass could not close inside the leaf: an apostrophe
# in a heredoc body, or a multi-line argument cut to its first line, would
# otherwise run on and put the next leaf's words in the wrong quote group. Such
# an unclosed quote stays a prose group when its text is one line, since bash
# closes it on a line the caller did not pass. When its text spans lines, the
# leaf was passed whole, bash already found every quote in it balanced, and
# the stray quote can only be heredoc body bytes, so the text is emitted
# unmarked.
# The current line is carried forward as the input is consumed rather than
# recovered by scanning back over the emitted buffer: one backwards rescan per
# quoted group is quadratic in the leaf length, and a single-line command with
# a few hundred quoted arguments then outruns the hook timeout. Only two facts
# about the line are ever needed -- its last word, and whether any earlier word
# is an interpreter -- and both survive as scalars.
# Words are tracked from the SOURCE text in the form bash would build them:
# quote and backslash characters drop out and the fragments they separate
# accumulate into ONE word, so `-c`, `'-c'`, `"-c"`, `-"c"`, `"-"c` and `\-c`
# all reach the flag test as -c, and `bash`, `'bash'`, `ba"sh"` and `\bash` all
# reach the interpreter test as bash. Reading the emitted buffer instead tests
# a word this pass has already rewritten -- a MARK-wrapped token, or the
# literal \-c -- and one pair of quotes around the flag then bought a bypass.
# A backslash-newline is a line boundary here, not the word joiner bash makes
# of it: leaves reach this pass with continuations already resolved, so the
# byte only ever appears mid-word in a hand-fed buffer, and resetting is the
# safe reading of it.
# The direction here is DENY, in two classes, both accepted false DENYs
# pinned as their own rows in both suites: a word that decodes to a code flag
# after an interpreter qualifies the next quoted group as code even where the
# flag is really an argv element of a script (`bash script.sh '-c' 'prose'`),
# and a data word that merely decodes to an interpreter name qualifies the
# same way (`grep 'sh' -c 'prose'`), because a word bash builds carries no
# record of whether it was meant as a program name.
# A `#` opens a comment that runs to the newline where bash would start one:
# at the start of a word. A word starts after a blank, at line start, or
# right after an unquoted, unescaped operator byte ;&|()<> or an opening
# backtick. A `)` that closes $( <( >( or $(( and a closing backtick end a
# substitution INSIDE a word, so a `#` after them is mid-word, as is one after
# an escaped byte (a\;#), a quote, or any other word byte (a#b, $#, ${#x}).
# Inside a comment a quote opens no group, so an apostrophe in a widened
# heredoc body's comment cannot mark the body lines after it as prose; the
# comment's bytes stay ordinary words rather than being dropped or marked.
# A misread costs either way: a comment missed or a comment invented both
# move quote parity by one, and the next real quote then marks executed text
# as prose. So the rule must track bash's, not err toward either side.
# KNOWN RESIDUALS of that rule: a case pattern's `)` inside $( ) pops the
# substitution's entry, and a $( inside a nested quoted heredoc body (text
# bash never parses) is still counted; both leave a later `)` misjudged.
# Bytes inside a comment move no substitution state, as in bash, except a
# backtick while one is open: bash finds the closing backtick before it
# parses the comment.
# Two writes, one chokepoint: consume() is the only way a byte that belongs
# to a word enters the buffer, and it feeds the word model in the same call.
# emit() writes boundary bytes alone -- whitespace, newline, an escaped
# newline -- which by definition carry no word text. A branch that wrote the
# buffer without the word model would leave the tests reading a stale word,
# which is the bypass this shape exists to prevent.
function is_interpreter(word,   head) {
    head = word
    sub(/^.*\//, "", head)
    sub(/[^A-Za-z0-9_.]+$/, "", head)
    return head ~ /^(sh|bash|dash|zsh|ksh|mksh|csh|tcsh|python[0-9.]*|perl|ruby|node|nodejs|php|lua[0-9.]*|expect|osascript)$/
}
function emit(chunk) {
    out = out chunk
}
function consume(chunk, text) {
    out = out chunk
    if (!in_word) {
        words++
        in_word = 1
        cur_word = ""
    }
    cur_word = cur_word text
}
function end_word() {
    if (in_word) {
        prev_word = cur_word
        if (is_interpreter(prev_word)) saw_interpreter = 1
        in_word = 0
    }
}
function marked_group(content,   chunk, m, k) {
    GROUP++
    chunk = ""
    m = split(content, qw, /[ \t\n]+/)
    for (k = 1; k <= m; k++) {
        if (qw[k] != "") chunk = chunk " " MARK GROUP ":" qw[k] MARK
    }
    return chunk " "
}
# Updates the word-start and substitution state for one unquoted, unescaped
# byte outside a comment. subst holds one char per open paren: "s" for a
# substitution opener, "p" for any other.
function track_plain(c,   top) {
    if (c == "(") {
        subst = subst (prev_plain ~ /[$<>]/ ? "s" : "p")
        word_start = 1
    } else if (c == ")") {
        top = substr(subst, length(subst), 1)
        if (subst != "") subst = substr(subst, 1, length(subst) - 1)
        word_start = (top != "s")
    } else if (c == "`") {
        in_backtick = !in_backtick
        word_start = in_backtick
    } else {
        word_start = (c ~ /[;&|<>]/)
    }
    prev_plain = c
}
function end_line() {
    end_word()
    in_comment = 0
    words = 0
    saw_interpreter = 0
    prev_word = ""
}
function code_argument(   last) {
    if (words < 2 || !saw_interpreter) return 0
    last = in_word ? cur_word : prev_word
    return last ~ /^(-[A-Za-z]*c|-[eEpr]|--eval|--print)$/
}
function open_across_lines(stop, content,   text) {
    if (stop != LEAF_END) return 0
    text = content
    sub(/\n$/, "", text)
    return index(text, "\n") > 0
}
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
    LEAF_END = "\036"
    GROUP = 0
    subst = ""
    in_backtick = 0
    while (i <= n) {
        c = substr(line, i, 1)
        if (c == LEAF_END) {
            emit("\n")
            end_line()
            i += 1
            continue
        }
        if (c == "\\" && i < n && substr(line, i + 1, 1) != LEAF_END) {
            esc = substr(line, i + 1, 1)
            if (esc == "\n") { emit(c esc); end_line() }
            else consume(c esc, esc)
            word_start = 0
            prev_plain = ""
            i += 2
            continue
        }
        if (c == "#" && !in_comment && (!in_word || word_start)) in_comment = 1
        if ((c == SQ || c == DQ) && !in_comment) {
            word_start = 0
            prev_plain = ""
        }
        if (c == SQ && !in_comment) {
            j = i + 1
            content = ""
            while (j <= n && (cc = substr(line, j, 1)) != SQ && cc != LEAF_END) {
                content = content cc
                j++
            }
            stop = substr(line, j, 1)
            if (code_argument() || open_across_lines(stop, content)) {
                # Inner quotes are the code arguments own syntax, not prose
                # glue: spacing them keeps a verb reachable as its own word.
                gsub(/[\047\042]/, " ", content)
                chunk = " " content " "
            } else {
                chunk = marked_group(content)
            }
            consume(chunk, content)
            i = (stop == SQ) ? j + 1 : j
            continue
        }
        if (c == DQ && !in_comment) {
            j = i + 1
            content = ""
            while (j <= n) {
                cc = substr(line, j, 1)
                if (cc == "\\" && j < n && substr(line, j + 1, 1) != LEAF_END) {
                    content = content cc substr(line, j + 1, 1)
                    j += 2
                    continue
                }
                if (cc == DQ || cc == LEAF_END) break
                content = content cc
                j++
            }
            stop = substr(line, j, 1)
            if (code_argument() || open_across_lines(stop, content)) {
                gsub(/[\047\042]/, " ", content)
                chunk = " " content " "
            } else if (content ~ /\$\(|`|\$\{/) {
                chunk = " " content " "
            } else {
                chunk = marked_group(content)
            }
            consume(chunk, content)
            i = (stop == DQ) ? j + 1 : j
            continue
        }
        if (c == "\n") { emit(c); end_line(); word_start = 0; prev_plain = "" }
        else if (c == " " || c == "\t") { emit(c); end_word(); word_start = 0; prev_plain = "" }
        else {
            consume(c, c)
            if (!in_comment) track_plain(c)
            else if (c == "`" && in_backtick) {
                in_backtick = 0
                in_comment = 0
                word_start = 0
                prev_plain = c
            }
        }
        i += 1
    }
    print out
}
