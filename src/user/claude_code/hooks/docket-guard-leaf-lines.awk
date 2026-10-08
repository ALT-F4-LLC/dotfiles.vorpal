# Leaf line selection for the docket guard hooks: which lines of a probed leaf
# are code. Loaded with `awk -f` from beside the hook, like
# docket-guard-prepass.awk, so the lexer lives in one file rather than one
# inline copy per hook. docket-sibling-guard-hook.sh and
# docket-commit-guard-hook.sh load it; the sibling guard's "Line selection"
# comment describes the rules this program implements.
#
# Input: the probe's leaves, each ended by 0x1e. Variables:
#   mode  "code" prints the code lines of every leaf; "scan" prints the code
#         lines, or the whole leaf when `widen` is set or the leaf carries an
#         unquoted-delimiter heredoc.
#   widen "1" makes scan mode print every leaf whole.
# Output: lines of one leaf are joined by newlines. Scan mode ends each leaf
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
function classify(leaf,   n, i, c, c2, j, k, t, s, sp, np, ln, found, x, lv, pmin) {
    NL = split(leaf, L, "\n")
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
            else if (c2 == "$(") { FT[++sp] = "N"; FD[sp] = 0; i++ }
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
            if (c2 == "$(") { FT[++sp] = "N"; FD[sp] = 0; i++ }
            else if (c == "{") FD[sp]++
            else if (c == "}") {
                if (FD[sp] > 0) FD[sp]--; else sp--
                if ((lv = level(sp)) < pmin) pmin = lv
            }
            i++
            continue
        }
        if (c == "#" && (i == 1 || index(" \t\n;&|()<>", substr(leaf, i - 1, 1)))) return
        if (c == "(" || c2 == "$(") {
            FD[sp]++
            i += (c == "(") ? 1 : 2
            continue
        }
        if (c == ")") {
            if (FD[sp] > 0) FD[sp]--
            else if (sp > 1) sp--
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
BEGIN {
    RS = "\036"
    SQ = "\047"
    DQ = "\042"
    BQ = "\140"
    END_LEAF = (mode == "scan") ? "\036" : "\n"
}
{
    leaf = $0
    if (leaf == "") next
    classify(leaf)
    if (mode == "scan" && (widen == "1" || UNQ)) {
        printf "%s\036", leaf
        next
    }
    last = 0
    for (k = 1; k <= NL; k++) if (CLS[k] == "c") last = k
    for (k = 1; k <= NL; k++) if (CLS[k] == "c") printf "%s%s", L[k], (k == last ? END_LEAF : "\n")
}
