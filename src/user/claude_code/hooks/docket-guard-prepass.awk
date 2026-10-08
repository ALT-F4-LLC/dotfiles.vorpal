# Shared quote-group pre-pass for docket-trust-guard-hook.sh,
# docket-commit-guard-hook.sh and docket-sibling-guard-hook.sh. Each hook
# feeds this its SCAN_TEXT leaf buffer via `awk -f`: the trust guard passes
# the first line of each leaf (the whole leaf when widened), and the commit
# and sibling guards pass every line except heredoc bodies. See the trust or
# commit hook's header for the redesign this pre-pass is part of. Read as one
# file rather than duplicated inline so a lexer fix lands once for all three.
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
# The emitted buffer itself keeps one word whole in one case: a quoted group
# with no blank in it, glued to word text on either side, is written bare
# rather than marked, so `a""dd`, `ad"d"` and `'a'dd` reach the matcher as
# add. Every other quoted group is marked, with a blank on each side.
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
# at the start of a word, where bash reads commands. A word starts at line
# start, after a blank, or right after an unquoted, unescaped operator byte
# ;&|()<> or an opening backtick. A `#` inside a word is no comment start:
# after a quote, an escaped byte (a\;#), any other word byte (a#b, $#), a
# closing backtick, or the `)` or `}` that ends a group bash keeps inside the
# word. Inside a comment a quote opens no group, so an apostrophe in a widened
# heredoc body's comment cannot mark the body lines after it as prose; the
# comment's bytes stay ordinary words rather than being dropped or marked.
# A misread costs either way: a comment missed or a comment invented both
# move quote parity by one, and the next real quote then marks executed text
# as prose. So the rule must track bash's, not err toward either side.
# To track it, nest holds one char per open group, named for how bash reads
# the bytes inside the group and the `#` right after its close:
#   s  $( <( >(         commands inside; the close is mid-word
#   a  name=( name+=(   an array's words inside; the close is mid-word
#   p  any other (      commands inside; the close is an operator
#   m  (( $((           arithmetic: no comment inside; the close is mid-word
#   b  ${               word text: no comment or operator inside, and a
#                       paren there is text; the close is mid-word
# A `(` glued to a name that is not an assignment is p: bash reads `f()` as a
# function definition's two operators, so `f()#` opens a comment.
# Where the text alone does not settle bash's reading, the pass stops marking
# prose rather than guess: every later quote group in the leaf reaches the
# matcher unmarked, which can only add a DENY. Three shapes do that. An extglob
# group (@( ?( *( +( !( ) is one word only with extglob on, and with it off
# `!(cmd)#` is a negated subshell then a comment. The word case inside a $( )
# or backticks makes its pattern `)` close the wrong group. A quote that opens
# inside an m group: when the arithmetic parse fails (its `)` is not followed
# by `)`), bash re-reads `((` and `$((` as nested subshells, where a `#`
# after a blank opens a comment and the quote may be comment text.
# The group state, the open backtick and that fallback end with the leaf (the
# \036 byte): one leaf's unbalanced text, such as a heredoc body bash never
# parsed, must not move a comment in the next.
# KNOWN RESIDUALS of that rule: a $( inside a nested quoted heredoc body (text bash never parses)
# is still counted; $[ ] arithmetic is not tracked; and $((cmd) ), which bash
# may read as a substitution holding a subshell, is read as arithmetic. Each
# can leave a later `#` misjudged.
# Bytes inside a comment move no group state, as in bash, except a backtick
# while one is open: bash finds the closing backtick before it parses the
# comment.
# Two writes, one chokepoint: consume() is the only way a byte that belongs
# to a word enters the buffer, and it feeds the word model in the same call.
# emit() writes boundary bytes alone -- whitespace, newline, an escaped
# newline -- which by definition carry no word text. A branch that wrote the
# buffer without the word model would leave the tests reading a stale word,
# which is the bypass this shape exists to prevent. Both calls also clear the
# word-start state, so only track_plain(), run after consume() for a plain
# byte, can leave an operator behind for the next `#` to see.
function is_interpreter(word,   head) {
    head = word
    sub(/^.*\//, "", head)
    sub(/[^A-Za-z0-9_.]+$/, "", head)
    return head ~ /^(sh|bash|dash|zsh|ksh|mksh|csh|tcsh|python[0-9.]*|perl|ruby|node|nodejs|php|lua[0-9.]*|expect|osascript)$/
}
function emit(chunk) {
    out = out chunk
    end_token()
    word_start = 0
    prev_plain = ""
}
function consume(chunk, text) {
    out = out chunk
    if (!in_word) {
        words++
        in_word = 1
        cur_word = ""
    }
    cur_word = cur_word text
    word_start = 0
    prev_plain = ""
}
function end_word() {
    if (in_word) {
        prev_word = cur_word
        if (is_interpreter(prev_word)) saw_interpreter = 1
        in_word = 0
    }
}
# A quoted group with no blank in it, glued to word text on either side, is a
# fragment of one word bash builds by concatenation: a""dd, ad"d", 'a'dd and
# "a""dd" all run as add. Such a group is emitted bare, so the buffer the
# matcher reads holds the word bash builds rather than its fragments split
# around a marked token. A group with a blank in it stays marked: bash keeps
# the blank inside the word, so no fragment of it can stand as a verb word.
function glued_fragment(content, after) {
    if (content ~ /[ \t\n]/) return 0
    if (in_word) return 1
    return after != "" && after !~ /[ \t\n]/ && after != LEAF_END
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
function nest_top() {
    return substr(nest, length(nest), 1)
}
function pop_nest() {
    nest = substr(nest, 1, length(nest) - 1)
}
# True inside a group whose bytes bash reads as word text, where no comment
# opens.
function in_word_group() {
    return nest_top() ~ /[bmx]/
}
# Names the group an unquoted `(` opens, from the plain byte before it.
function paren_kind(before, top) {
    if (before == "$") return "s"
    if (top ~ /[mx]/) return top
    if (before ~ /[<>]/) return "s"
    if (before == "(") return "m"
    if (before ~ /[@?*+!]/) {
        unsure = 1
        return "x"
    }
    if (before == "=" && cur_word ~ /^[A-Za-z_][A-Za-z0-9_]*(\[.*\])?\+?=\($/) return "a"
    return "p"
}
# A word bash may read as the case keyword ends here. Inside $( ) or
# backticks its pattern `)` would close the wrong group.
function end_token() {
    if (tok == "case" && (index(nest, "s") || in_backtick)) unsure = 1
    tok = ""
}
# Updates the word-start and group state for one unquoted, unescaped byte
# outside a comment, already passed to consume(). before is the plain byte
# right before it, or empty.
function track_plain(c, before,   top) {
    top = nest_top()
    if (c ~ /[;&|()<>`]/) end_token()
    else tok = tok c
    if (c == "(") {
        if (top != "b" || before == "$") nest = nest paren_kind(before, top)
        word_start = 1
    } else if (c == ")") {
        if (top != "b") {
            pop_nest()
            word_start = (top == "p" || top == "")
        }
    } else if (c == "{") {
        if (before == "$") nest = nest "b"
    } else if (c == "}") {
        if (top == "b") pop_nest()
    } else if (c == "`") {
        in_backtick = !in_backtick
        word_start = in_backtick
    } else {
        word_start = (c ~ /[;&|<>]/)
    }
    prev_plain = c
}
function end_leaf() {
    end_line()
    nest = ""
    in_backtick = 0
    unsure = 0
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
    nest = ""
    in_backtick = 0
    unsure = 0
    tok = ""
    while (i <= n) {
        c = substr(line, i, 1)
        if (c == LEAF_END) {
            emit("\n")
            end_leaf()
            i += 1
            continue
        }
        if (c == "\\" && i < n && substr(line, i + 1, 1) != LEAF_END) {
            esc = substr(line, i + 1, 1)
            if (esc == "\n") { emit(c esc); end_line() }
            else consume(c esc, esc)
            i += 2
            continue
        }
        if (c == "#" && !in_comment && !in_word_group() && (!in_word || word_start)) in_comment = 1
        # A quote inside (( or $(( may be comment text (see the header).
        if ((c == SQ || c == DQ) && !in_comment && index(nest, "m")) unsure = 1
        if (c == SQ && !in_comment) {
            j = i + 1
            content = ""
            while (j <= n && (cc = substr(line, j, 1)) != SQ && cc != LEAF_END) {
                content = content cc
                j++
            }
            stop = substr(line, j, 1)
            if (code_argument() || unsure || open_across_lines(stop, content)) {
                # Inner quotes are the code arguments own syntax, not prose
                # glue: spacing them keeps a verb reachable as its own word.
                gsub(/[\047\042]/, " ", content)
                chunk = " " content " "
            } else if (glued_fragment(content, substr(line, (stop == SQ) ? j + 1 : j, 1))) {
                chunk = content
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
            if (code_argument() || unsure || open_across_lines(stop, content)) {
                gsub(/[\047\042]/, " ", content)
                chunk = " " content " "
            } else if (content ~ /\$\(|`|\$\{/) {
                chunk = " " content " "
            } else if (glued_fragment(content, substr(line, (stop == DQ) ? j + 1 : j, 1))) {
                chunk = content
            } else {
                chunk = marked_group(content)
            }
            consume(chunk, content)
            i = (stop == DQ) ? j + 1 : j
            continue
        }
        if (c == "\n") { emit(c); end_line() }
        else if (c == " " || c == "\t") { emit(c); end_word() }
        else {
            before = prev_plain
            consume(c, c)
            if (!in_comment) track_plain(c, before)
            else if (c == "`" && in_backtick) {
                in_backtick = 0
                in_comment = 0
                prev_plain = c
            }
        }
        i += 1
    }
    print out
}
