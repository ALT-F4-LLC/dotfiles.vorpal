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
function end_line() {
    end_word()
    words = 0
    saw_interpreter = 0
    prev_word = ""
}
function code_argument(   last) {
    if (words < 2 || !saw_interpreter) return 0
    last = in_word ? cur_word : prev_word
    return last ~ /^(-[A-Za-z]*c|-[eEpr]|--eval|--print)$/
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
    GROUP = 0
    while (i <= n) {
        c = substr(line, i, 1)
        if (c == "\\" && i < n) {
            esc = substr(line, i + 1, 1)
            if (esc == "\n") { emit(c esc); end_line() }
            else consume(c esc, esc)
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
            if (code_argument()) {
                # Inner quotes are the code arguments own syntax, not prose
                # glue: spacing them keeps a verb reachable as its own word.
                gsub(/[\047\042]/, " ", content)
                chunk = " " content " "
            } else {
                chunk = marked_group(content)
            }
            consume(chunk, content)
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
            if (code_argument()) {
                gsub(/[\047\042]/, " ", content)
                chunk = " " content " "
            } else if (content ~ /\$\(|`|\$\{/) {
                chunk = " " content " "
            } else {
                chunk = marked_group(content)
            }
            consume(chunk, content)
            i = j + 1
            continue
        }
        if (c == "\n") { emit(c); end_line() }
        else if (c == " " || c == "\t") { emit(c); end_word() }
        else consume(c, c)
        i += 1
    }
    print out
}
