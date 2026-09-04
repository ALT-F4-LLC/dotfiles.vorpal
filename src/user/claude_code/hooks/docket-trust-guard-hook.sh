#!/bin/bash

# trust-guard — PreToolUse: Bash.
#
# `docket trust add/rm` mutates the trust store that authorizes an executor's
# own completion gates (`~/.config/docket/trust.toml`, granted sandbox-write
# at SANDBOX_DOCKET_TRUST_PATH in claude_code.rs). Unlike every other write an
# executor makes, this one lands nowhere in the recorded diff a wave judge
# reads — trust.toml lives outside every checkout — so a self-repointed gate
# is invisible to the one review layer downstream of the executor itself. The
# `Bash(docket trust add/rm:*)` ask rule in claude_code.rs is not a
# structural stop for that case: an unattended executor has no human at a
# terminal to answer an ask, so under this fleet's `auto` permission default
# the decision falls to the same classifier already measured approving
# sandbox bypasses a brief forbade (a fleet review found this; sandbox-bypass-guard-hook.sh
# now denies the lift for executors outright). This hook re-keys the decision away from that
# classifier for exactly the callers who must never win it.
#
# THE SCOPE, and why it is not a blanket deny. `docket trust add/rm` stays a
# permission ASK for the main conversation — the operator's own path, working
# as intended per the docket-run contract's "Reserved to the operator" list
# (trust-store writes go through a direct question, every time). A deny here
# that ignored caller identity would block the operator's own ask-confirmed
# path too, which the issue's acceptance criteria explicitly forbids. The
# distinguishing field is `agent_type`, present in PreToolUse hook input only
# for a subagent's own tool calls (Claude Code hooks.md, "Subagent Fields")
# and absent for the main conversation's -- so EXECUTOR_ARCHETYPES below is
# the whole of this hook's policy, and it names only the three graph-fleet
# executor archetypes (agents/executor-{read,write,research}.md), not every
# subagent type: a groomer or planner seat was never in this hook's scope, and
# widening this list to "any agent_id present" would deny seats this issue
# never asked to touch, on no evidence any of them needs to.
#
# Exit 0 allow / exit 2 deny with reason on stderr, matching this hook
# family's established contract (docket-commit-guard-hook.sh): exit 2 is a
# pre-permission hard stop, honored "regardless of permission mode" — the
# same property that makes it survive an unsandboxed retry, unlike the ask
# rule and unlike a sandbox-only deny.
#
# This hook carries no engine query and no state, deliberately: unlike
# commit-gate, whether a trust-store write is in scope for a step does not
# depend on run content, only on who is asking. There is nothing here for the
# engine to have an opinion about.
#
# Fail-open on a missing `jq`: a tooling gap must not brick every Bash call in
# the session. There is no `docket`-binary fail-open branch here, unlike
# commit-guard — this hook never shells out to `docket` itself.

# DOT-1123 REDESIGN, replacing a hand-rolled AWK shell lexer that re-scanned
# raw command bytes for heredocs, comments, arithmetic expansions, and
# separators with no notion of bash's actual grammar. Three fix-loop rounds
# on that lexer (RUN-76) EACH found a live, reproduced bypass or false-DENY
# regression in what the PRIOR round had just landed:
#   CL9  (survived all 3 rounds): a quoted heredoc's body, once marked
#        prose because its immediate destination (cat/tee/dd) was on a
#        short allowlist, still executes for real when that destination is
#        piped into an interpreter — `cat <<'EOF' | sh` with the guarded
#        invocation in the body ran it, live: PWNED_VIA_PIPE. A one-hop
#        "is the destination safe" test can never be complete: a pipe, a
#        command substitution, or a process substitution moves the same
#        bytes to a consumer the allowlist never saw.
#   CL16 (round 2): the lexer's head-word scan re-derived a fact bash's own
#        parser already knows (where a simple command starts) by walking
#        raw bytes for `;`/`&`/`|`/`(`/`)`, with no notion of quoting — a
#        separator INSIDE a quoted argument spoofed it into a false ALLOW
#        (`bash -s "a;cat " <<'EOF'` with the guarded invocation in the
#        body ran it, live), and the round's own fix for that broke
#        ordinary heredocs inside `for`/`if`/`{ }` (false DENY regression).
#   CL17 (round 3, NEW): the lexer's comment-boundary rule for a bare `#`
#        misfired on `$(...)`/`$((...))`/`=(...)` closes, so a real
#        invocation after a `;` on the same line as one of those got
#        swallowed into the "comment" and ALLOWED — a regression this
#        round introduced while trying to close CL9's class.
#
# Three independent bypasses in three rounds, each a NEW shape of the SAME
# defect (a hand-rolled model of bash's grammar is not bash's grammar), is
# the signature of the wrong tool for the job, not a bug count to keep
# whittling down. This redesign does not re-implement heredocs, comments,
# arithmetic, quoting, pipes, or command substitution AT ALL: it asks bash
# itself what it would run, using bash's own DEBUG trap with `extdebug` and
# `functrace` (`set -T`, which makes DEBUG traps propagate into subshells,
# command substitutions, and function bodies — without it, `(docket trust
# add …)` in a bare subshell ran unobserved, verified live here). The trap
# fires once per SIMPLE COMMAND bash's real parser is about to execute; it
# ALWAYS vetoes that command (returns non-zero, which `extdebug` treats as
# "skip it") rather than letting anything actually run, except for a small
# fixed set of purely structural constructs (`eval`, loop/conditional
# keywords, and names bash already knows as functions) — those are allowed
# through so the trap gets to see what is genuinely INSIDE them, without
# ever letting a real leaf command (an external program or a builtin with a
# side effect) execute. Verified with a filesystem marker across pipes,
# subshells, command substitutions, `eval`, loops, conditionals, function
# calls, and backgrounded jobs: nothing the probe walks ever runs for real.
#
# What this closes, by construction rather than by patching a symptom:
#   - CL16's class cannot recur: there is no separator re-scan of any kind
#     — bash's own parser is what decided where each simple command starts.
#   - CL17's class cannot recur: there is no comment-boundary rule of any
#     kind — bash's own parser is what decided what is a comment.
#   - CL9's class is closed differently, because it is a genuinely
#     different problem (not a parsing bug — a semantic one, about where
#     data ends up): every leaf this probe records is inspected, and if ANY
#     of them names a program that can interpret arbitrary input as code
#     (INTERPRETER_WORDS below), every heredoc body in the WHOLE command is
#     scanned for the guarded verb too, not exempted as it would be for a
#     command with no interpreter anywhere in it. This does not try to
#     prove which specific pipe or substitution carries the bytes to that
#     interpreter — CL9 is exactly the finding that a one-hop version of
#     that proof is unsound — it widens instead, which is this hook's
#     established direction for an unresolvable case (a false DENY over a
#     missed invocation).
#
# The final MATCH step below — is "docket trust add" or "docket trust rm"
# present as three separately-resolved words versus one prose span, and is
# a bare -h/--help present right after a clean verb — is UNCHANGED from the
# pre-redesign hook: that logic was never implicated in any of the three
# findings above, which were all about recognizing where a simple command
# begins and what is data versus code BEFORE that step ever runs.
#
# The quote-GROUP marking that feeds it carries ONE later change: a quoted
# group that is an interpreter's code argument (`bash -c '…'`, `python3 -c
# '…'`) is emitted unmarked, because that is the one position where a quoted
# string is executed verbatim rather than being prose. Without it the group
# exemption below read a whole invocation as one prose span and allowed it —
# the trust store is written from a quoted string at the cost of one extra
# word. The pre-pass comment states which interpreters and flags count and
# which carriers stay allowed as residuals.
# What is gone is the heredoc/comment/arithmetic re-scanning this file used
# to do to feed that step a stream of words; bash's own grammar does that
# now, on every leaf it hands back.
#
# ONE ACCEPTED INACCURACY, stated with its failure direction: bash's own
# $BASH_COMMAND reconstruction MOVES a here-string redirect (`<<<word`) to
# the end of the line, so `cat <<<docket trust add erik key` reconstructs
# as `cat trust add erik key <<< docket` — "docket" no longer sits next to
# "trust add", and the MATCH step's word-adjacency scan misses it. This is
# a false ALLOW, but not a missed dispatch: bash treats "trust", "add",
# "erik", "key" as cat's file arguments and "docket" as cat's stdin source,
# so nothing here ever runs `docket trust add` as its own command — the
# words are merely adjacent-looking text this scan no longer catches. Fixing
# it would mean tracking each redirect operand's original source position
# through bash's reconstruction, which this redesign deliberately does not
# do (that is exactly the kind of re-derivation of what bash already knows
# that produced CL16). Left open rather than patched around.

set -uo pipefail

allow_default() {
    exit 0
}

deny() {
    printf '%s\n' "$1" >&2
    exit 2
}

is_executor_archetype() {
    case "$1" in
        executor-read | executor-write | executor-research) return 0 ;;
        *) return 1 ;;
    esac
}

INPUT=$(cat 2>/dev/null) || allow_default

if ! command -v jq >/dev/null 2>&1; then
    allow_default
fi

TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null) || allow_default
[ "$TOOL_NAME" = "Bash" ] || allow_default

AGENT_TYPE=$(printf '%s' "$INPUT" | jq -r '.agent_type // empty' 2>/dev/null) || allow_default
is_executor_archetype "$AGENT_TYPE" || allow_default

COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null) || allow_default
[ -n "$COMMAND" ] || allow_default

# --- Leaf enumeration: ask bash, don't re-derive it. ---------------------
#
# LEAVES holds every simple command bash's own grammar would dispatch,
# `\036` (RS)-separated, each possibly itself multi-line when it embeds a
# heredoc (the heredoc's body arrives as part of that ONE leaf's text,
# exactly as bash reconstructs $BASH_COMMAND). PROBE_CAP is written when the
# 2000-command ceiling below fires — a circuit breaker against a crafted or
# pathological input driving this into a long-running loop, not a bound
# expected to matter for an ordinary executor call (empirically, hundreds
# of simple commands enumerate in well under a second).
#
# `eval "$COMMAND"` is how the untrusted text reaches bash as SOURCE rather
# than as a re-quoted argument: COMMAND travels via the environment, never
# through string interpolation into this script's own source, so nothing
# about the outer invocation's quoting can be confused by what the inner
# text contains — it is parsed exactly once, by bash, exactly as it would
# be if the real Bash tool ran it. `eval` itself is on the structural
# allowlist below (it is a control mechanism, not a leaf) so the trap sees
# straight through it to what is actually inside.
# No `mktemp`: this hook's dependency set is deliberately fixed at
# bash/cat/jq/awk (tests/docket-trust-guard-hook.test.sh runs it with PATH
# restricted to exactly those), and `$$` is unique enough for a file this
# process creates, writes, reads, and deletes within its own lifetime.
PROBE_OUT="${TMPDIR:-/tmp}/docket-trust-guard-hook.$$"
# The cap hit travels in its own file rather than as a token inside
# PROBE_OUT: that buffer holds the caller's own leaf text, so an in-band
# marker lets any command that merely quotes it be refused as oversized.
PROBE_CAP="${PROBE_OUT}.cap"
: >"$PROBE_OUT" 2>/dev/null || allow_default
: >"$PROBE_CAP" 2>/dev/null || allow_default
trap 'rm -f "$PROBE_OUT" "$PROBE_CAP"' EXIT

PROBE_ERR=$(COMMAND="$COMMAND" PROBE_OUT="$PROBE_OUT" PROBE_CAP="$PROBE_CAP" bash -c '
    shopt -s extdebug
    set -T
    n=0
    _guard_probe() {
        n=$((n + 1))
        if [ "$n" -gt 2000 ]; then
            printf 1 >> "$PROBE_CAP"
            trap - DEBUG
            return 1
        fi
        local head="${BASH_COMMAND%%[ $'"'"'\t\n'"'"']*}"
        head="${head##*/}"
        case "$head" in
            eval | for | while | until | if | elif | else | fi | then | do | done | \
            case | esac | select | function | time | "{" | "}" | "[" | "[[" | : | \
            true | false)
                return 0 ;;
        esac
        if declare -F "$head" >/dev/null 2>&1; then
            return 0
        fi
        printf "%s\036" "$BASH_COMMAND" >> "$PROBE_OUT"
        return 1
    }
    # WHY true/false/: RUN FOR REAL rather than vetoed like every other
    # leaf: a vetoed command is always reported to bash as SUCCEEDED
    # (verified live: `extdebug`s trap-skip has no way to report failure,
    # whatever the trap itself returns) -- so `false || git commit ...`
    # never even reached the right side of || for this probe to see it,
    # a real gap this fix closes. Letting true/false/: run instead of
    # skipping them is safe FOR THE SAME REASON eval is on the structural
    # list: `set -T` (functrace) gives every command substitution its own
    # independent DEBUG-trap pass, so an argument like `: $(docket trust
    # add erik key)` still gets its OWN trap firing for the embedded
    # substitution before true/false/: ever runs -- verified live, the
    # inner `touch` fired as its own leaf and was vetoed even though the
    # outer `:` was allowed through. No other builtin is added here: `test`/
    # `[`/`[[` share the same argument-expansion exposure but are already
    # structural (their own condition-only role), and anything else
    # (echo, printf, cd, …) can have a real side effect true/false/: never
    # do.
    trap _guard_probe DEBUG
    eval "$COMMAND"
' 2>&1 >/dev/null)
# Nothing runs after eval returns, deliberately: any command here would
# ALSO be a leaf the still-armed trap intercepts (including a bare
# "trap - DEBUG" itself, which the trap would veto exactly like any other
# command, so it would never actually take effect and disarm anything) —
# proven live: this hook's own attempt at a "trap - DEBUG; exit 0" wrap-up
# logged ITSELF as two bogus leaves instead of running, which on an eval
# that failed outright was the only thing that made PROBE_OUT non-empty,
# masking the failure as an ordinary (and wrong) ALLOW. `trap - DEBUG`
# inside `_guard_probe` above is a different case: bash suspends a trap
# while its own handler runs, so that call executes normally and is not
# itself re-intercepted. The script just ends here; the subshell's own
# exit status is unused, only $PROBE_OUT is read below.

PROBE_TEXT=$(<"$PROBE_OUT") 2>/dev/null

if [ -z "$PROBE_TEXT" ]; then
    # No leaf dispatched at all: either the command is genuinely inert (all
    # comment, all whitespace — safe to allow) or `eval` never got past a
    # syntax error, in which case bash never reached ANY command including
    # a guarded one — but this probe could not confirm which, so it is
    # "could not analyze", not "nothing here", and this hook's own direction
    # on an unresolvable case is a false DENY over a missed invocation.
    case "$PROBE_ERR" in
        *"syntax error"*)
            deny "trust-store write blocked: the trust-guard hook could not parse this command to check it (bash reported a syntax error while analyzing it) and refuses rather than guessing. Fix the command's syntax; if it is not actually invalid, that is a hook defect to report separately." ;;
    esac
    allow_default
fi

if [ -s "$PROBE_CAP" ]; then
    deny "trust-store write blocked: this command has too many parts (over 2000) for the trust-guard hook to finish checking it. Split it into smaller Bash calls; a single call this large is refused rather than passed through unchecked."
fi

# --- Widening: where a heredoc's body stops being inert data. ------------
#
# Two independent triggers, either one widening a leaf's scan from its
# first physical line to its whole text (heredoc body included) rather
# than exempted as prose:
#
#   1. INTERPRETER (CL9's fix, whole-command scope). If ANY leaf names a
#      program that reads arbitrary input as code, no heredoc body
#      anywhere in the WHOLE command is treated as inert data — this does
#      not try to prove which specific pipe or substitution carries the
#      bytes to that interpreter (CL9 is exactly the finding that a
#      one-hop version of that proof is unsound), it widens instead.
#   2. UNQUOTED DELIMITER (per leaf). A heredoc with an unquoted (or
#      backslash-quoted-per-character, which is the same case) delimiter
#      undergoes parameter/command/arithmetic expansion on its body BEFORE
#      it ever reaches its consumer — `cat > f <<EOF` with a body
#      containing `$(docket trust add …)` runs that substitution as bash
#      prepares the heredoc, independent of what cat does with the result.
#      A quoted delimiter (`<<'EOF'`, `<<"EOF"`, `<<\EOF`) suppresses all of
#      that, which is the ONLY case this hook exempts as prose (AC1/AC2).
#
# With neither trigger, only each leaf's FIRST physical line is scanned: a
# genuine invocation's verb is always on that first line by construction
# (bash resolves `\`-continuations before setting $BASH_COMMAND, verified
# live; only a heredoc body or a literal newline inside a quoted argument
# adds further lines, and neither can move the verb off line one).
INTERPRETER_RE='(^|[^A-Za-z0-9_])(sh|bash|dash|zsh|ksh|mksh|csh|tcsh|python[0-9.]*|perl|ruby|node|nodejs|php|lua[0-9.]*|tclsh|expect|osascript|env)([^A-Za-z0-9_]|$)'
WIDEN=0
if [[ "$PROBE_TEXT" =~ $INTERPRETER_RE ]]; then
    WIDEN=1
fi

SCAN_TEXT=$(awk -v RS='\036' -v widen="$WIDEN" '
    BEGIN { out = "" }
    {
        leaf = $0
        if (leaf == "") next
        eol = index(leaf, "\n")
        line1 = (eol == 0 ? leaf : substr(leaf, 1, eol - 1))
        leaf_widen = (widen == "1")
        # A heredoc operator on this leafs own first line whose delimiter
        # is NOT quoted. Checked as a positive is-it-quoted test, not a
        # negated one: << or <<-, optional spaces, then immediately a
        # quote or backslash (a backslash-quoted delimiter is quoted too).
        # POSIX ERE leftmost-longest matching makes the optional dash
        # ambiguous in a NEGATED class here -- for a tab-stripping quoted
        # delimiter it can match either by consuming the dash and landing
        # on the quote, or by NOT consuming it and landing on the dash
        # itself, which a negated class excluding only quotes and
        # backslash would wrongly accept. A positive quote check has no
        # such second reading: only consuming the dash and then finding a
        # quote ever satisfies it.
        if (!leaf_widen && line1 ~ /<</ && line1 !~ /<<-?[ \t]*[\x27\x22\\]/) {
            leaf_widen = 1
        }
        if (leaf_widen) {
            out = out leaf "\n"
        } else {
            out = out line1 "\n"
        }
    }
    END { printf "%s", out }
' "$PROBE_OUT")

# --- Quote-group marking. ------------------------------------------------
#
# Marks every word that came from inside a single- or double-quoted string
# with a sentinel plus a quote-GROUP id, so the MATCH step below can tell
# real prose (`-m "... docket trust add ..."`, one group) apart from a
# bash-unquoted invocation built from separately-quoted words (`"docket"
# "trust" "add"`, three groups). Double-quoted content that could still
# trigger command/parameter substitution ($(...), backticks, ${...}) is
# left unmarked so the matcher inspects it directly. No heredoc, comment,
# or arithmetic handling here: SCAN_TEXT above is already, by construction,
# one or more complete simple-command lines with no unresolved separators
# — there is nothing of that shape left for this pass to get wrong.
STRIPPED=$(printf '%s' "$SCAN_TEXT" | awk '
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
# The direction here is DENY: a word that decodes to a code flag after an
# interpreter qualifies the next quoted group as code even where the flag is
# really an argv element of a script (`bash script.sh '-c' 'prose'`), an
# accepted false DENY pinned as its own row in both suites.
function is_interpreter(word,   head) {
    head = word
    sub(/^.*\//, "", head)
    sub(/[^A-Za-z0-9_.]+$/, "", head)
    return head ~ /^(sh|bash|dash|zsh|ksh|mksh|csh|tcsh|python[0-9.]*|perl|ruby|node|nodejs|php|lua[0-9.]*|expect|osascript)$/
}
function emit(chunk) {
    out = out chunk
}
function word_text(t) {
    if (!in_word) {
        if (words >= 1 && is_interpreter(prev_word)) saw_interpreter = 1
        words++
        in_word = 1
        cur_word = ""
    }
    cur_word = cur_word t
}
function end_word() {
    if (in_word) { prev_word = cur_word; in_word = 0 }
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
            emit(c esc)
            if (esc == "\n") end_line(); else word_text(esc)
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
                emit(" " content " ")
            } else {
                GROUP++
                m = split(content, qw, /[ \t\n]+/)
                for (k = 1; k <= m; k++) {
                    if (qw[k] != "") emit(" " MARK GROUP ":" qw[k] MARK)
                }
                emit(" ")
            }
            word_text(content)
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
                emit(" " content " ")
            } else if (content ~ /\$\(|`|\$\{/) {
                emit(" " content " ")
            } else {
                GROUP++
                m = split(content, qw, /[ \t\n]+/)
                for (k = 1; k <= m; k++) {
                    if (qw[k] != "") emit(" " MARK GROUP ":" qw[k] MARK)
                }
                emit(" ")
            }
            word_text(content)
            i = j + 1
            continue
        }
        emit(c)
        if (c == "\n") end_line()
        else if (c == " " || c == "\t") end_word()
        else word_text(c)
        i += 1
    }
    print out
}
' 2>/dev/null) || allow_default

# --- THE MATCH, unchanged from the pre-redesign hook. ---------------------
#
# Three consecutive words `docket trust (add|rm)`, head-normalized on
# `docket` the same way commit-guard normalizes `git` (closes a delimiter
# or subshell glued directly onto the front with no whitespace), and
# quote-group-aware on all three words so real prose stays allowed while a
# trick built from separately-quoted tokens still denies.
#
# THE ONE EXEMPTION: `docket trust add --help` (or `-h`, or `rm`) opens
# nothing -- it is the read a judge seat needs to evaluate a trust entry's
# flags, and denying it as a write cost a tribunal the one lookup its verdict
# rested on. The exemption is deliberately the narrowest shape that is a help
# read by construction rather than by CLI courtesy: the flag must be the word
# IMMEDIATELY after the verb, unquoted, and exactly `-h` or `--help` with at
# most a shell operator glued onto its tail (`--help;`, `--help)`, `--help|`
# all end the segment right after the flag). Directly after the verb no
# earlier option can swallow the flag as its value and no `--` has been seen,
# so docket's parser sees the help flag before it validates a single argument
# -- whereas `docket trust add name -- --help` is a real write with `--help`
# as an argv element, and `docket trust add --timeout --help -- x` feeds the
# flag to --timeout, which is why a help flag in any later position stays
# denied. Exact spelling matters for the same reason: `--help=false` and
# `-h=false` are pflag's way of turning the flag OFF, so they must not be
# stripped down to a match. The verb and `trust` must be clean words (nothing
# glued) -- a glued operator there means the segment ended before the flag.
#
# An exempted occurrence `continue`s the scan rather than allowing outright:
# `docket trust add --help && docket trust add x -- y` still denies on its
# second occurrence, on this line or a later one.
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
        hw = w
        sub(/^.*(\$\(|\140|\(|;|\||&)/, "", hw)
        if (hw == "docket" || hw ~ /\/docket$/) {
            if (i + 2 > n) continue
            tquoted = decode(words[i + 1])
            tgroup = D_GROUP
            tw = D_WORD
            texact = tw
            sub(/[^A-Za-z0-9_-].*$/, "", tw)
            if (tw != "trust") continue
            vquoted = decode(words[i + 2])
            vgroup = D_GROUP
            vw = D_WORD
            vexact = vw
            sub(/[^A-Za-z0-9_-].*$/, "", vw)
            if (vw != "add" && vw != "rm") continue
            if (hquoted && tquoted && vquoted && hgroup == tgroup && tgroup == vgroup) continue
            # Help read: an unquoted, bare -h/--help directly after a clean
            # verb. Only a glued trailing shell operator is stripped from the
            # flag (it ends the segment); any other suffix is a different
            # argument and keeps the deny. See the comment above the block.
            if (texact == tw && vexact == vw && i + 3 <= n) {
                pquoted = decode(words[i + 3])
                pw = D_WORD
                sub(/[|&;()<>].*$/, "", pw)
                if (!pquoted && (pw == "-h" || pw == "--help")) continue
            }
            print "MATCH"
            exit
        }
    }
}
' 2>/dev/null)
[ "$MATCH" = "MATCH" ] || allow_default

deny "trust-store write blocked: \`docket trust add/rm\` is operator-reserved and never in scope for an executor step, whatever the brief says. If your step genuinely needs a trust entry changed, that is a routing defect: record the mismatch as your step's finding through the gap channel your brief names, and do not retry this call. If this command performs no trust-store write, the matcher has false-positived on the phrase appearing as prose or as an interpreter's code argument (known limitation): to read or search a file's content, use the Read or Grep tool instead (bypasses this matcher entirely); to write prose that names the phrase, put it in a file via the Write/Edit tool rather than a Bash heredoc or an inline code argument."
