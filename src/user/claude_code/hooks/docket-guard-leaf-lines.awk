# Heredoc, redirect and widening-trigger classification for the docket guard
# hooks, in one file rather than one copy per hook. Loaded with `awk -f` from
# beside the hook, like docket-guard-prepass.awk. The sibling guard's "Line
# selection" and "Widening" comments describe the rules it implements.
#
# Two load forms. As a filter, `awk -v mode=M -f docket-guard-leaf-lines.awk`
# reads stdin and prints a result; only these modes run its rules and set RS.
# As a library, `awk -f docket-guard-leaf-lines.awk -f PROGRAM` with any other
# mode, its redir_* functions serve the program's own rules; they take words
# and return values, never print or exit, and read no global of the program.
# Such a program must not pass a filter mode's name as `mode`. The widen_*
# functions need tables only a filter mode fills, so they serve the filters.
#
# Filter modes. Leaf input is the probe's leaves, each ended by 0x1e.
#   code   prints the code lines of every leaf.
#   scan   prints the code lines, or the whole leaf when `widen` is "1" or the
#          leaf carries an unquoted-delimiter heredoc.
#   widen  prints 1 or 0, the interpreter trigger over leaf input: the code
#          lines, then the substitution spans of unquoted-delimiter bodies,
#          quoted prose dropped from both. With `bodies` "1" it reads the raw
#          input instead, comments and every heredoc body included.
#   probe-fd     prints 1 or 0: a redirection whose source is fd 7, 8 or 9.
#   zsh          the zsh write-redirect respelling (zsh_respell), then ".".
#   hoist        a scratch redirect list cut off a compound (hoist).
#   inert        prints ACTIVE unless every line of marked code text is the
#                trust guard's inert reading (widen_inert_line).
#   assign-widen prints ACTIVE for an assignment name, `=`, blanks and a quote.
# probe-fd, zsh, hoist and assign-widen read the whole input as one command
# text; inert reads it line by line.
#
# Output of code and scan: lines of one leaf are joined by newlines. Scan mode ends each leaf
# with 0x1e, which docket-guard-prepass.awk reads as a newline that also ends
# the leaf's group state, so one leaf's unbalanced text (a heredoc body bash
# never parsed) cannot move a comment or a prose group in the next; code mode
# ends each leaf with a newline.
#
# A heredoc body (its terminator line included) is not a code line. The
# operator is found with a quote-aware lexer, and classification stops,
# keeping every remaining line, wherever its reading could disagree with
# bash's. Inside a substitution a body is skipped only when bash 3.2's paren
# and quote scan reads it as plain balanced text (body_inert).
# A comment is cut from its line (CUT[k] holds the column it starts at):
# a `#` that starts a word in command text, where bash reads one. A `)`
# that closed a substitution keeps the word open, so a `#` right after
# it is text, as it is after any other word byte.
function count_nl(s,   t) {
    t = s
    return gsub(/\n/, "", t)
}
# Index just past the balanced arithmetic span opened at i ($(( or ((), or
# 0 when it is unbalanced or holds a quote, backtick or backslash.
function skip_arith(s, i, n,   j, depth, c) {
    j = i + (substr(s, i, 1) == "$" ? 3 : 2)
    depth = 2
    while (j <= n && depth > 0) {
        c = substr(s, j, 1)
        if (c == "(") depth++
        else if (c == ")") depth--
        else if (c == SQ || c == DQ || c == BQ || c == "\\") return 0
        j++
    }
    return depth > 0 ? 0 : j
}
# Index just past the single-quoted span opened at i, or 0 when unclosed.
function skip_single(s, i, n,   j) {
    j = i + 1
    while (j <= n && substr(s, j, 1) != SQ) j++
    return j > n ? 0 : j + 1
}
# Parses the heredoc operator at i into HD_DASH, HD_QUOTED and HD_DELIM (the
# delimiter after quote removal) and returns the index past its word.
# HD_BAIL is set when the delimiter value is uncertain.
function parse_heredoc(s, i, n,   j, c, k, part) {
    HD_DASH = 0
    HD_QUOTED = 0
    HD_DELIM = ""
    HD_BAIL = 0
    j = i + 2
    if (substr(s, j, 1) == "-") { HD_DASH = 1; j++ }
    while (j <= n && (substr(s, j, 1) == " " || substr(s, j, 1) == "\t")) j++
    while (j <= n) {
        c = substr(s, j, 1)
        if (index(" \t\n;&|()<>", c)) break
        if (c == SQ || c == DQ) {
            k = j + 1
            while (k <= n && substr(s, k, 1) != c) k++
            part = substr(s, j + 1, k - j - 1)
            if (k > n || part ~ /[\n\\$\140]/) { HD_BAIL = 1; return j }
            HD_DELIM = HD_DELIM part
            HD_QUOTED = 1
            j = k + 1
            continue
        }
        if (c == "\\") {
            if (j == n || substr(s, j + 1, 1) == "\n") { HD_BAIL = 1; return j }
            HD_DELIM = HD_DELIM substr(s, j + 1, 1)
            HD_QUOTED = 1
            j += 2
            continue
        }
        if (c == "$" || c == BQ) { HD_BAIL = 1; return j }
        HD_DELIM = HD_DELIM c
        j++
    }
    return j
}
function d_below(sp,   k) {
    for (k = 1; k < sp; k++) if (FT[k] == "D") return 1
    return 0
}
# 1 when lines a..b, a heredoc body and its terminator line, read the same to
# the paren and quote scan bash 3.2 uses to find the end of an enclosing
# substitution, which ignores heredocs: no quote, backtick, backslash, `#` or
# `$`, and parens that balance without closing below the level they start
# at. A `)` that closes there ends the substitution inside what would
# otherwise be body text; the terminator line is outside every quote for
# that scan even when the delimiter on the operator line was quoted.
function body_inert(a, b,   s, k, d, c) {
    d = 0
    for (s = a; s <= b; s++) {
        if (L[s] ~ /[\\#$\047\042\140]/) return 0
        for (k = 1; k <= length(L[s]); k++) {
            c = substr(L[s], k, 1)
            if (c == "(") d++
            else if (c == ")" && --d < 0) return 0
        }
    }
    return d == 0
}
# Nesting level of the lexer state in classify: every open frame above the
# first, plus the parens or braces each frame holds open (FD, 0 on D frames).
function level(sp,   k, v) {
    v = sp - 1
    for (k = 1; k <= sp; k++) v += FD[k]
    return v
}
# Fills NL, L[1..NL] and CLS[1..NL] ("c" code, "b" heredoc body or
# terminator) and sets UNQ when an operator has an unquoted or empty
# delimiter. Frames: N (command text, FD counts open parens), D (inside
# double quotes), B (inside ${ }, FD counts open braces). A body is taken
# only at a newline at the level its operator was queued at, with no close
# below that level since (pmin).
function classify(leaf,   n, i, c, c2, j, k, t, s, sp, np, ln, found, x, lv, pmin, sub_close) {
    NL = split(leaf, L, "\n")
    split("", CUT)
    sub_close = 0
    START[1] = 1
    for (k = 1; k <= NL; k++) {
        CLS[k] = "c"
        START[k + 1] = START[k] + length(L[k]) + 1
    }
    UNQ = 0
    n = length(leaf)
    i = 1
    ln = 1
    sp = 1
    FT[1] = "N"
    FD[1] = 0
    np = 0
    while (i <= n) {
        c = substr(leaf, i, 1)
        c2 = substr(leaf, i, 2)
        if (c == "\\") {
            if (substr(leaf, i + 1, 1) == "\n") ln++
            i += 2
            continue
        }
        if (c == "\n") {
            ln++
            i++
            if (FT[sp] != "N" || np == 0) continue
            lv = level(sp)
            if (pmin < lv) return
            for (k = 1; k <= np; k++) {
                if (PLVL[k] != lv) return
                found = 0
                for (t = ln; t <= NL; t++) {
                    x = L[t]
                    if (PDASH[k]) sub(/^\t+/, "", x)
                    if (x == PDELIM[k]) { found = 1; break }
                }
                if (!found) return
                if (lv > 0 && !body_inert(ln, t)) return
                for (s = ln; s <= t; s++) CLS[s] = "b"
                ln = t + 1
            }
            np = 0
            i = START[ln]
            continue
        }
        if (c == BQ || c2 == "$[") return
        if (c2 == "$(" && substr(leaf, i, 3) == "$((" || FT[sp] == "N" && c2 == "((") {
            j = skip_arith(leaf, i, n)
            if (!j) return
            ln += count_nl(substr(leaf, i, j - i))
            i = j
            continue
        }
        if (FT[sp] == "D") {
            if (c == DQ) { sp--; if ((lv = level(sp)) < pmin) pmin = lv }
            else if (c2 == "$(") { FT[++sp] = "N"; FD[sp] = 0; FSUB[sp] = 1; i++ }
            else if (c2 == "${") { FT[++sp] = "B"; FD[sp] = 0; i++ }
            i++
            continue
        }
        if (c == SQ || c2 == "$" SQ) {
            if (FT[sp] == "B" && (c2 == "$" SQ || d_below(sp))) return
            if (c2 == "$" SQ) {
                j = i + 2
                while (j <= n && substr(leaf, j, 1) != SQ) j += (substr(leaf, j, 1) == "\\") ? 2 : 1
                j = (j > n) ? 0 : j + 1
            } else {
                j = skip_single(leaf, i, n)
            }
            if (!j) return
            ln += count_nl(substr(leaf, i, j - i))
            i = j
            continue
        }
        if (c == DQ) { FT[++sp] = "D"; FD[sp] = 0; i++; continue }
        if (c2 == "${") { FT[++sp] = "B"; FD[sp] = 0; i += 2; continue }
        if (FT[sp] == "B") {
            if (c2 == "$(") { FT[++sp] = "N"; FD[sp] = 0; FSUB[sp] = 1; i++ }
            else if (c == "{") FD[sp]++
            else if (c == "}") {
                if (FD[sp] > 0) FD[sp]--; else sp--
                if ((lv = level(sp)) < pmin) pmin = lv
            }
            i++
            continue
        }
        if (c == "#" && (i == 1 || index(" \t\n;&|(<>", substr(leaf, i - 1, 1)) || (substr(leaf, i - 1, 1) == ")" && sub_close != i - 1))) {
            CUT[ln] = i - START[ln] + 1
            while (i <= n && substr(leaf, i, 1) != "\n") i++
            continue
        }
        if (c == "(" || c2 == "$(") {
            PK[sp, ++FD[sp]] = (c2 == "$(")
            i += (c == "(") ? 1 : 2
            continue
        }
        if (c == ")") {
            if (FD[sp] > 0) { if (PK[sp, FD[sp]]) sub_close = i; FD[sp]-- }
            else if (sp > 1) { if (FSUB[sp]) sub_close = i; FSUB[sp] = 0; sp-- }
            else if (np) return
            else { i++; continue }
            if ((lv = level(sp)) < pmin) pmin = lv
            i++
            continue
        }
        if (substr(leaf, i, 3) == "<<<") { i += 3; continue }
        if (c2 == "<<") {
            j = parse_heredoc(leaf, i, n)
            if (HD_BAIL) return
            if (HD_DELIM == "" || !HD_QUOTED) UNQ = 1
            if (HD_DELIM != "") {
                lv = level(sp)
                if (++np == 1) pmin = lv
                PDELIM[np] = HD_DELIM
                PDASH[np] = HD_DASH
                PLVL[np] = lv
            }
            i = j
            continue
        }
        i++
    }
}
# The text one leaf prints: its code lines, the last ended by end_leaf, or
# with whole set every line, the last ended by 0x1e. A comment is cut.
function leaf_text(whole, end_leaf,   k, last, out) {
    out = ""
    if (whole) {
        for (k = 1; k <= NL; k++) out = out (k in CUT ? substr(L[k], 1, CUT[k] - 1) : L[k]) (k == NL ? "\036" : "\n")
        return out
    }
    last = 0
    for (k = 1; k <= NL; k++) if (CLS[k] == "c") last = k
    for (k = 1; k <= NL; k++) if (CLS[k] == "c") out = out (k in CUT ? substr(L[k], 1, CUT[k] - 1) : L[k]) (k == last ? end_leaf : "\n")
    return out
}

# --- Widening: where a heredoc's body stops being inert data. ------------
#
# The sibling guard's "Widening" comment states the rules. An interpreter
# name widens when it stands between bytes that are neither word characters
# nor dots. widen_prose drops a quoted span holding a blank from a line, the
# pre-pass's prose rule, and keeps the line whole where its quoting cannot be
# read as bash would (an unclosed quote, `$'...'`, or a double-quoted span
# carrying `$(`, `${` or a backtick). widen_spans keeps only the `$( )` and
# backtick spans of a line, carrying its depth across lines; a span that
# never closes runs to the end of the text.
function widen_prose(s,   n, out, i, c, j, span) {
    n = length(s)
    if (index(s, "$" SQ)) return s
    out = ""
    i = 1
    while (i <= n) {
        c = substr(s, i, 1)
        if (c == "\\") { out = out substr(s, i, 2); i += 2; continue }
        if (c != SQ && c != DQ) { out = out c; i++; continue }
        j = i + 1
        while (j <= n && substr(s, j, 1) != c) j += (c == DQ && substr(s, j, 1) == "\\") ? 2 : 1
        if (j > n) { out = out substr(s, i); break }
        span = substr(s, i + 1, j - i - 1)
        if (c == DQ && (index(span, "$(") || index(span, "${") || index(span, BQ))) return s
        out = out (span ~ /[ \t]/ ? " " : substr(s, i, j - i + 1))
        i = j + 1
    }
    return out
}
function widen_spans(s,   n, out, i, c) {
    n = length(s)
    out = ""
    for (i = 1; i <= n; i++) {
        c = substr(s, i, 1)
        if (c == "\\") { if (W_DEPTH > 0 || W_INBT) out = out substr(s, i, 2); i++; continue }
        if (c == BQ) { W_INBT = !W_INBT; out = out " "; continue }
        if (c == "$" && substr(s, i + 1, 1) == "(") { W_DEPTH++; out = out " "; i++; continue }
        if (W_DEPTH > 0) {
            if (c == "(") W_DEPTH++
            else if (c == ")") { W_DEPTH--; if (W_DEPTH == 0) { out = out " "; continue } }
            out = out c
        } else if (W_INBT) {
            out = out c
        }
    }
    return out
}
# 1 when the interpreter trigger fires on text, read line by line through
# widen_prose, and through widen_spans first when spans is set.
function widen_lines(text, spans,   m, lines, k, out) {
    m = split(text, lines, "\n")
    out = ""
    for (k = 1; k <= m; k++) out = out (k > 1 ? "\n" : "") widen_prose(spans ? widen_spans(lines[k]) : lines[k])
    return out ~ WIDEN_INTERP_RE
}

# The trust guard's inert reading of one line of marked code text, as words
# split at blanks: 1 at the first command word outside WIDEN_INERT, the first
# control-flow word, the first `||` or the first PATH assignment. Every word
# in command position must be inert: the first word of the line, the word
# after an operator (standalone, or glued: `(cat`, `sh;`), and the word a
# launcher launches. A quoted group is one word however many tokens the
# pre-pass split it into, and is the command when it stands in command
# position other than as an assignment value. Redirection operands,
# arithmetic spans and launcher options are skipped. A quoted group that
# holds a blank can never be an inert command, so `"a b"` in command
# position is active. A closing brace or paren is structure, not a command.
function widen_inert_word(word,   cw) {
    cw = word
    sub(/\).*$/, "", cw)
    if (cw == "" || cw == "}") return 0
    if (cw in WIDEN_FLOW) return 1
    if (cw in WIDEN_LAUNCHER) { W_LAUNCH = 1; return 0 }
    return !(cw in WIDEN_INERT)
}
# A word bash reads in command position without making it the command name:
# an assignment, a reserved word or a zsh precommand modifier. A lone { is the
# reserved word unless a quoted fragment follows it, since the pre-pass splits
# {"a",b} at the quote.
function widen_command_prefix(word, next_word) {
    if (word ~ /^[A-Za-z_][A-Za-z0-9_]*=/) return 1
    if (word ~ /^(if|then|else|elif|do|while|until|time|coproc|!|noglob|nocorrect|-)$/) return 1
    return word == "{" && substr(next_word, 1, 1) != REDIR_MARK
}
function widen_decode(raw,    inner, cpos) {
    if (length(raw) >= 2 && substr(raw, 1, 1) == REDIR_MARK && substr(raw, length(raw), 1) == REDIR_MARK) {
        inner = substr(raw, 2, length(raw) - 2)
        cpos = index(inner, ":")
        W_GROUP = substr(inner, 1, cpos - 1)
        W_WORD = substr(inner, cpos + 1)
        gsub(/^[\047\042]+|[\047\042]+$/, "", W_WORD)
        return 1
    }
    W_GROUP = ""
    W_WORD = raw
    gsub(/^[\047\042]+|[\047\042]+$/, "", W_WORD)
    return 0
}
function widen_parens(word,   t, o, c) {
    t = word; o = gsub(/\(/, "", t)
    t = word; c = gsub(/\)/, "", t)
    return o - c
}
function widen_inert_line(words, n,   i, q, w, m, segs, s, seg, trailing, prev_group, cmdpos, assign_tail, redir, arith, array, skipped, nb, parts, p, inside) {
    cmdpos = 1
    W_LAUNCH = 0
    assign_tail = 0
    redir = 0
    arith = 0
    array = 0
    prev_group = ""
    for (i = 1; i <= n; i++) {
        q = widen_decode(words[i])
        w = W_WORD
        if (q) {
            if (W_GROUP == prev_group) continue
            prev_group = W_GROUP
            if (redir) { redir = 0; continue }
            if (arith > 0) continue
            if (W_LAUNCH) { W_LAUNCH = 0; if (widen_inert_word(w)) return 1; cmdpos = 0; continue }
            if (cmdpos && !assign_tail) { if (widen_inert_word(w)) return 1; cmdpos = 0 }
            assign_tail = 0
            continue
        }
        prev_group = ""
        if (index(w, "||") > 0) return 1
        if (w ~ /(^|[^A-Za-z0-9_])PATH\+?=/) return 1
        # An operator ending the word (`x;`, `f)&&`) puts the next word in
        # command position whatever this word was.
        trailing = (w ~ /[\140(;|&]$/)
        skipped = 0
        if (arith > 0) { arith += widen_parens(w); skipped = 1 }
        else if (index(w, "$((") > 0 || w ~ /^\(\(/) {
            arith = widen_parens(w)
            if (arith < 0) arith = 0
            skipped = 1
        }
        else if (redir) { redir = 0; skipped = 1 }
        # A redirection, with its operand glued (`2>/dev/null`, `<<EOF`) or
        # following (`> f`); `<(` and `>(` are substitutions, read below.
        else if (w ~ /^[0-9]*[<>]+([^(<>].*)?$/ || w ~ /^&>>?/) {
            redir = (w ~ /^[0-9]*[<>]+$/ || w ~ /^&>>?$/)
            skipped = 1
        }
        # In an array assignment the words up to the `)` are values.
        if (array) { if (index(w, ")") > 0) array = 0; skipped = 1 }
        else if (w ~ /^[A-Za-z_][A-Za-z0-9_]*\+?=\(/) { array = (index(w, ")") == 0); skipped = 1 }
        if (skipped) {
            if (trailing) {
                if (W_LAUNCH) return 1
                cmdpos = 1
                assign_tail = 0
            }
            continue
        }
        # Backticks alternate outside and inside text; inside is a command,
        # and the text glued after a closing backtick is not.
        nb = split(w, parts, /\140/)
        for (p = 1; p <= nb; p++) {
            inside = (p % 2 == 0)
            if (inside) { cmdpos = 1; assign_tail = 0 }
            m = split(parts[p], segs, /[(;|&]+/)
            for (s = 1; s <= m; s++) {
                seg = segs[s]
                if (s > 1) {
                    if (W_LAUNCH) return 1
                    cmdpos = 1
                    assign_tail = 0
                }
                if (seg == "") continue
                if (W_LAUNCH) {
                    if (seg ~ /^-/ || seg ~ /^[0-9]+$/ || seg ~ /^[A-Za-z_][A-Za-z0-9_]*\+?=/) continue
                    W_LAUNCH = 0
                    if (widen_inert_word(seg)) return 1
                    cmdpos = 0
                    continue
                }
                if (!cmdpos) { assign_tail = 0; continue }
                if (seg in WIDEN_FLOW) return 1
                if (widen_command_prefix(seg, words[i + 1])) { assign_tail = (seg ~ /=$/); continue }
                if (widen_inert_word(seg)) return 1
                cmdpos = 0
                assign_tail = 0
            }
            if (parts[p] ~ /[(;|&]$/) {
                if (W_LAUNCH) return 1
                cmdpos = 1
                assign_tail = 0
            }
            if (inside) cmdpos = 0
        }
        if (trailing) {
            if (W_LAUNCH) return 1
            cmdpos = 1
            assign_tail = 0
        }
    }
    return W_LAUNCH
}

# --- Redirections, for the guards' matchers. -----------------------------
#
# Each takes a word as the pre-pass writes it (a quoted group's words marked
# with REDIR_MARK) or a words array split at blanks, and returns a value.
#
# An unquoted word that opens with a redirection operator, behind an optional
# fd number or {name}: `>f`, `2>&1`, `&>f`, `<<<x`, `>|f`, or a bare `>`.
# `<(` and `>(` are process substitutions, which are arguments.
function redir_word(word,   rest) {
    if (substr(word, 1, 1) == REDIR_MARK) return 0
    rest = word
    if (match(rest, /^[0-9]+/) || match(rest, /^[{][A-Za-z_][A-Za-z0-9_]*[}]/)) rest = substr(rest, RLENGTH + 1)
    if (match(rest, /^&>>?/) || match(rest, /^<<[<-]?/) || match(rest, /^[<>][<>&|]?/)) rest = substr(rest, RLENGTH + 1)
    else return 0
    return substr(rest, 1, 1) != "("
}
# An unquoted word that ends in a redirection operator with no target glued
# after it: `trust>`, `docket>>`, `trust>&`, `trust>|`, `trust&>`, `<<-`.
function redir_open(word) {
    if (word == "" || substr(word, 1, 1) == REDIR_MARK) return 0
    return word ~ /[<>]$/ || word ~ /[<>][&|]$/ || word ~ /&>>?$/ || word ~ /<<-$/
}
# The text with every redirection operator that carries & or | (>&, <&, &>,
# >|) dropped, so its & or | is not read as a command separator.
function redir_strip_ops(s) {
    gsub(/[<>]&|&>|>[|]/, "", s)
    return s
}
# The text with those operators rewritten to their bare redirection
# character, so a cut at a separator keeps what is glued ahead of them
# ({a,b}>&2) and a redirection glued to a word can still be trimmed. mawk
# has no backreference in a replacement, hence one gsub per operator.
function redir_bare_ops(s) {
    gsub(/>&/, ">", s)
    gsub(/<&/, "<", s)
    gsub(/&>/, ">", s)
    gsub(/>[|]/, ">", s)
    return s
}
# A head word without the redirection glued onto it (`docket>/dev/null`).
function redir_cut_glued(s) {
    sub(/[<>].*$/, "", s)
    return s
}
# 1 when an unquoted word holds a ; | & or backtick that is not part of a
# redirection operator: the command ends there.
function redir_ends_command(word) {
    if (substr(word, 1, 1) == REDIR_MARK) return 0
    return redir_strip_ops(word) ~ /[;|&\140]/
}
function redir_group(raw,   inner) {
    if (length(raw) >= 2 && substr(raw, 1, 1) == REDIR_MARK && substr(raw, length(raw), 1) == REDIR_MARK) {
        inner = substr(raw, 2, length(raw) - 2)
        return substr(inner, 1, index(inner, ":") - 1)
    }
    return ""
}
# The index of the first word after the target of a bare redirection
# operator, which starts at words[k], and 0 when the command ends inside it.
# A quoted target holding blanks reaches here as several marked words of one
# group, and all of them are the target. The pre-pass writes a blank-free
# quoted target bare, so `>a;b` may be `>"a;b"`, one word: a target glued to
# its operator never ends the command.
function redir_past_target(words, n, k,   g) {
    if (k > n) return k
    if (substr(words[k], 1, 1) == REDIR_MARK) {
        g = redir_group(words[k])
        for (k++; k <= n && substr(words[k], 1, 1) == REDIR_MARK; k++) if (redir_group(words[k]) != g) break
        return k
    }
    if (redir_strip_ops(words[k]) ~ /[;|&\140]/) return 0
    return k + 1
}
# The index of the first word at or after k that is neither a redirection nor
# a redirection's target, and 0 when the command ends inside a target. The
# word after a bare operator is its target, so it is skipped, also when prev,
# the word before words[k], ends in one (`trust> f`, `docket>& 2`).
function redir_next(words, n, k, prev) {
    if (redir_open(prev)) {
        k = redir_past_target(words, n, k)
        if (!k) return 0
    }
    while (k <= n && redir_word(words[k])) {
        if (redir_open(words[k])) {
            k = redir_past_target(words, n, k + 1)
            if (!k) return 0
        } else k++
    }
    return k
}
# The sibling matcher's tests on an unquoted word. redir_write_word: it opens
# with a write operator (`>f`, `2>>f`, `<>f`, `&>f`). redir_write_op: it is a
# bare write operator, so the next word is the file written. redir_op: it is
# any bare operator, so the next word is its target. redir_glued: it is a
# redirection with its target glued on.
function redir_write_word(w) {
    return w ~ /^([0-9]*|\{[A-Za-z_][A-Za-z0-9_]*\})<?>/ || w ~ /^&>/
}
function redir_write_op(w) {
    return w ~ /^([0-9]*|\{[A-Za-z_][A-Za-z0-9_]*\})(>{1,2}\|?|<>)$/ || w ~ /^&>>?$/
}
function redir_op(w) {
    return w ~ /^([0-9]*|\{[A-Za-z_][A-Za-z0-9_]*\})[<>&|]*[<>][<>&|-]*$/
}
function redir_glued(w) {
    return w ~ /^[0-9]*[<>]/ || w ~ /^&>/
}
# The sibling text splitter cuts a word at ; | & ( ) and backticks. These
# hide the & and | of the operators >|, >&, &> and <& from that cut and then
# restore them.
function redir_protect_ops(w) {
    gsub(/>\|/, ">\002", w)
    gsub(/>&/, ">\003", w)
    gsub(/&>/, "\003>", w)
    gsub(/<&/, "<\003", w)
    return w
}
function redir_restore_ops(w) {
    gsub(/\002/, "|", w)
    gsub(/\003/, "\\&", w)
    return w
}

# --- zsh write redirects. ------------------------------------------------
#
# The sibling guard's comment above its zsh check states why. Each zsh
# clobber or append-clobber operator is spelled again as bash's `>` or `>>`,
# leftmost first. Returns "" when the text holds none, "R" and the operator
# when one has a missing target or one carrying `$` or a backtick, and
# otherwise "S" and the respelled text.
function zsh_respell(s,   m, op, rest, target, p) {
    if (s !~ ZSH_WRITE_RE) return ""
    while (match(s, ZSH_TARGET_RE)) {
        m = substr(s, RSTART, RLENGTH)
        p = RSTART
        match(m, "^(" ZSH_WRITE_RE ")")
        op = substr(m, 1, RLENGTH)
        rest = substr(m, RLENGTH + 1)
        sub(/^[[:space:]]*/, "", rest)
        target = rest
        if (target == "" || target ~ /[$\140]/) return "R" op
        s = substr(s, 1, p - 1) (index(op, ">>") ? ">>" : ">") substr(s, p + length(op))
    }
    return "S" s
}

# --- Hoisting a scratch redirect off a top-level compound. ---------------
#
# bash refuses a redirection on a compound command in the probe's restricted
# mode, so `for ...; done > "$TMPDIR/f"` cannot be walked. When the command
# ends with a redirect list straight after a done, fi, esac or } word, and
# every item writes /dev/null or a plain $TMPDIR-rooted path or duplicates an
# fd, the list is cut and each file it writes becomes a `cat /dev/null >
# TARGET` leaf, read as a simple command's redirect is. The list ending the
# command is what makes the compound top-level. The cut text holds no code,
# so the probe still walks every command. Returns "" when the command does
# not qualify, else the cut command, 0x1e, and each leaf ended by 0x1e.
#
# A command that spells TMPDIR anywhere but in $TMPDIR or ${TMPDIR} is left
# alone. The test is textual: a repoint spelled without those letters
# together (`T\MPDIR=...`, `declare "$x$y"=...`) passes it, the same residual
# a simple command has today (`d=/other; cat > "$d/f"`). A keyword after a
# `;` inside a comment (`echo hi #; done > T`) is hoisted too; its leaf can
# only add a deny.
function hoist_target(t) {
    if (t == "/dev/null") return 1
    if (t !~ /^((\$TMPDIR|\$\{TMPDIR\}|"\$TMPDIR"|"\$\{TMPDIR\}")\/[A-Za-z0-9._\/+@%=,:-]+|"(\$TMPDIR|\$\{TMPDIR\})\/[A-Za-z0-9._\/+@%=,:-]+")$/) return 0
    return t !~ /\/\.\.(\/|"|$)/
}
# The leaves for the redirect list in s, or "" when s is not one.
function hoist_list(s,   frames, op, t, any, c) {
    frames = ""
    any = 0
    while (1) {
        sub(/^[ \t]+/, "", s)
        if (s == "") return any ? (frames == "" ? "\036" : frames) : ""
        if (match(s, /^[0-9]*[<>]&([0-9]+-?|-)/) && ((c = substr(s, RLENGTH + 1, 1)) == "" || c == " " || c == "\t")) {
            s = substr(s, RLENGTH + 1)
            any = 1
            continue
        }
        if (!match(s, /^[0-9]?(&>>?|>>|>[|]|>&|<>|>)/)) return ""
        op = substr(s, 1, RLENGTH)
        s = substr(s, RLENGTH + 1)
        sub(/^[ \t]+/, "", s)
        if (!match(s, /^[^ \t\n;&|()<>]+/)) return ""
        t = substr(s, 1, RLENGTH)
        s = substr(s, RLENGTH + 1)
        if (s != "" && substr(s, 1, 1) !~ /[ \t>]/) return ""
        if (!hoist_target(t)) return ""
        if (t != "/dev/null") frames = frames "cat /dev/null > " t "\036"
        any = 1
    }
}
function hoist(s,   t, i, n, w, before, frames) {
    if (index(s, "<<") || index(s, BQ) || index(s, "$[") || index(s, "\036")) return ""
    t = s
    gsub(/\$\{TMPDIR\}|\$TMPDIR/, "", t)
    if (index(t, "TMPDIR")) return ""
    sub(/[ \t\n]+$/, "", s)
    n = length(s)
    for (i = 1; i <= n; i++) {
        if (substr(s, i, 4) == "done" || substr(s, i, 4) == "esac") w = 4
        else if (substr(s, i, 2) == "fi") w = 2
        else if (substr(s, i, 1) == "}") w = 1
        else continue
        before = substr(s, 1, i - 1)
        sub(/[ \t]+$/, "", before)
        if (before != "" && index(";&|({\n", substr(before, length(before), 1)) == 0) continue
        if (substr(s, i + w, 1) !~ /^[ \t<>&]$/) continue
        frames = hoist_list(substr(s, i + w))
        if (frames == "") continue
        if (frames == "\036") frames = ""
        return substr(s, 1, i + w - 1) "\036" frames
    }
    return ""
}

BEGIN {
    SQ = "\047"
    DQ = "\042"
    BQ = "\140"
    REDIR_MARK = "\001"
    FILTER = (mode ~ /^(code|scan|widen|probe-fd|zsh|hoist|inert|assign-widen)$/)
    if (FILTER) {
        RS = (mode == "inert") ? "\n" : "\036"
        END_LEAF = (mode == "scan") ? "\036" : "\n"
        WHOLE = (mode != "code" && mode != "scan" && mode != "inert" && !(mode == "widen" && bodies != "1"))
        WIDEN_INTERP_RE = "(^|[^A-Za-z0-9_.])(sh|bash|dash|zsh|ksh|mksh|csh|tcsh|python[0-9.]*|perl|ruby|node|nodejs|php|lua[0-9.]*|tclsh|expect|osascript|env|eval)([^A-Za-z0-9_.]|$)"
        ZSH_WRITE_RE = "(&>>?|>>&?|>&)[!|]|>!"
        ZSH_TARGET_RE = "(" ZSH_WRITE_RE ")[[:space:]]*([^[:space:];&|<>()]*)"
        k = split("cat tee printf echo jq mkdir rmdir cd pwd ls wc head tail grep cut sort uniq tr diff cmp stat basename dirname realpath mktemp date sleep true false : chmod cp mv rm touch ln export local unset shift set readonly declare typeset read docket", W_LIST, " ")
        for (j = 1; j <= k; j++) WIDEN_INERT[W_LIST[j]] = 1
        k = split("command builtin exec nohup nice timeout time setsid stdbuf sudo env repeat", W_LIST, " ")
        for (j = 1; j <= k; j++) WIDEN_LAUNCHER[W_LIST[j]] = 1
        k = split("if elif while until for select case ! [ [[ test", W_LIST, " ")
        for (j = 1; j <= k; j++) WIDEN_FLOW[W_LIST[j]] = 1
    }
}
# Whole-text modes read the input as one text, the 0x1e bytes between records
# put back.
FILTER && WHOLE {
    ALL = ALL (NR > 1 ? "\036" : "") $0
    next
}
FILTER && mode == "inert" {
    n = split($0, W_WORDS, /[ \t]+/)
    if (widen_inert_line(W_WORDS, n)) { print "ACTIVE"; DONE = 1; exit }
    next
}
FILTER {
    leaf = $0
    if (leaf == "") next
    classify(leaf)
    if (mode == "widen") {
        W_CODE = W_CODE leaf_text(0, "\n")
        W_SCAN = W_SCAN leaf_text(UNQ, "\036")
        next
    }
    printf "%s", leaf_text(mode == "scan" && (widen == "1" || UNQ), END_LEAF)
}
# No exit here: in library form a consumer's own END follows this one.
END {
    if (!FILTER || DONE) ;
    else if (mode == "widen" && bodies == "1") print (ALL ~ WIDEN_INTERP_RE) ? 1 : 0
    else if (mode == "widen") print (widen_lines(W_CODE, 0) || widen_lines(W_SCAN, 1)) ? 1 : 0
    else if (mode == "probe-fd") print (ALL ~ /(^|[^A-Za-z0-9_$])[789][<>]/) ? 1 : 0
    else if (mode == "assign-widen") { if (ALL ~ /(^|[^A-Za-z0-9_])[A-Za-z_][A-Za-z0-9_]*\+?=[[:space:]]+["\047]/) print "ACTIVE" }
    else if (mode == "zsh") { ALL = zsh_respell(ALL); if (ALL != "") printf "%s.", ALL }
    else if (mode == "hoist") printf "%s", hoist(ALL)
}
