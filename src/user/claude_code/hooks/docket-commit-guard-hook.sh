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
# question to ask. This file's behavior is pinned by
# tests/docket-commit-guard-hook.test.sh.
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
#
# THE MATCHER — leaf enumeration, widening, and quote-group marking below —
# is shared byte-for-byte with docket-trust-guard-hook.sh; see that file's
# header for the redesign rationale this replaces.
# Only what comes after quote-group marking differs: this file's MATCH step
# looks for `git commit`/`push`/`add`, with git's own `-C`/`-c`/`--git-dir`
# global-option skipping and its option-before-subcommand help exemption,
# where the trust-guard's looks for `docket trust add`/`rm`. This hook also
# carries no `agent_type` scoping — unlike the executor-only trust-guard, a
# git write needs an approved gate from ANY caller, main conversation
# included, matching the old fleet's own scope.

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

# --- Leaf enumeration: ask bash, don't re-derive it. ---------------------
#
# LEAVES holds every simple command bash's own grammar would dispatch,
# `\036` (RS)-separated, each possibly itself multi-line when it embeds a
# heredoc (the heredoc's body arrives as part of that ONE leaf's text,
# exactly as bash reconstructs $BASH_COMMAND). PROBE_CAP is written when the
# 2000-command ceiling below fires — a circuit breaker against a crafted or
# pathological input driving this into a long-running loop, not a bound
# expected to matter for an ordinary call (empirically, hundreds of simple
# commands enumerate in well under a second).
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
# bash/cat/jq/awk (tests/docket-commit-guard-hook.test.sh runs it with PATH
# restricted to exactly those), and `$$` is unique enough for a file this
# process creates, writes, reads, and deletes within its own lifetime.
PROBE_OUT="${TMPDIR:-/tmp}/docket-commit-guard-hook.$$"
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
    # independent DEBUG-trap pass, so an argument like `: $(git commit -m
    # x)` still gets its OWN trap firing for the embedded substitution
    # before true/false/: ever runs -- verified live, the inner leaf fired
    # on its own and was vetoed even though the outer `:` was allowed
    # through. No other builtin is added here: `test`/`[`/`[[` share the
    # same argument-expansion exposure but are already structural (their
    # own condition-only role), and anything else (echo, printf, cd, …)
    # can have a real side effect true/false/: never do.
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
            deny "git write blocked: the commit-guard hook could not parse this command to check it (bash reported a syntax error while analyzing it) and refuses rather than guessing. Fix the command's syntax; if it is not actually invalid, that is a hook defect to report separately." ;;
    esac
    allow_default
fi

if [ -s "$PROBE_CAP" ]; then
    deny "git write blocked: this command has too many parts (over 2000) for the commit-guard hook to finish checking it. Split it into smaller Bash calls; a single call this large is refused rather than passed through unchecked."
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
#      containing `$(git commit -m …)` runs that substitution as bash
#      prepares the heredoc, independent of what cat does with the result.
#      A quoted delimiter (`<<'EOF'`, `<<"EOF"`, `<<\EOF`) suppresses all of
#      that, which is the ONLY case this hook exempts as prose.
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
# real prose (`-m "... git commit ..."`, one group) apart from a
# bash-unquoted invocation built from separately-quoted words (`"git"
# "commit"`, two groups). A quoted group that is an interpreter's code
# argument (`bash -c "git commit -m x"`) is emitted unmarked instead: that is
# the one position where a quoted string is executed verbatim, so it was a
# bypass of this guard rather than prose, and it is no longer an accepted
# residual in either hook. Double-quoted content that could still trigger
# command/parameter substitution ($(...), backticks, ${...}) is left
# unmarked so the matcher inspects it directly. No heredoc, comment, or
# arithmetic handling here: SCAN_TEXT above is already, by construction,
# one or more complete simple-command lines with no unresolved separators
# — there is nothing of that shape left for this pass to get wrong.
#
# The awk PROGRAM itself lives in docket-guard-prepass.awk, shared
# byte-for-byte with docket-trust-guard-hook.sh: both hooks
# install as siblings under ~/.claude/hooks (src/user/claude_code.rs ships
# the whole hooks/ directory as one artifact), so resolving it beside this
# script's own path reaches the installed copy the same way in production
# and in the test suite's scratch-copy override. A missing file fails
# CLOSED (deny, not allow_default): this hook's whole job is deciding
# whether a git write is present in the command, and with no pre-pass
# program there is no way to make that call safely -- allowing would be
# worse than the tooling-gap fail-open above, which applies only when
# `docket` itself is missing, not when the lexer is missing. The directory
# is a bash parameter expansion on `$0` rather than a call to the external
# `dirname`: this hook's dependency set is fixed at bash/cat/jq/awk, and the
# test suite runs it with PATH restricted to exactly those.
HOOK_DIR="${0%/*}"
[ "$HOOK_DIR" = "$0" ] && HOOK_DIR="."
PREPASS_AWK="${HOOK_DIR}/docket-guard-prepass.awk"
[ -r "$PREPASS_AWK" ] || deny "git write blocked: the commit-guard hook's shared pre-pass file (docket-guard-prepass.awk) is missing or unreadable beside this hook, so it cannot check this command. This is a hook installation defect, not a caller mistake -- report it rather than retrying."
STRIPPED=$(printf '%s' "$SCAN_TEXT" | awk -f "$PREPASS_AWK" 2>/dev/null) || allow_default

# THE MATCH: `git (commit|push|add)`, head-normalized on `git` and skipping
# git's own global options (`-C`, `-c`, `--git-dir`, …) that may precede the
# subcommand, quote-group-aware on the head and subcommand so real prose
# stays allowed while a trick built from separately-quoted tokens still
# denies. Unchanged from the pre-redesign hook — this step was never
# implicated in CL9/CL16/CL17, which were all about recognizing where a
# simple command begins and what is data versus code BEFORE this step
# ever runs.
#
# THE ONE EXEMPTION: `git --help commit` (option BEFORE the subcommand)
# opens nothing. `git commit --help` (subcommand before the flag) stays
# denied — an accepted false positive, since git's own option parsing
# would need modeling to tell that case apart from `git commit
# --help-me-a-message-file`-shaped real writes reliably.
#
# BRACE EXPANSION: bash's own $BASH_COMMAND reconstruction keeps
# a leaf's SOURCE spelling, unexpanded -- `git commi{t,} -m x` reaches this
# scan as the literal text `commi{t,}`, not as the two words bash actually
# dispatches (`commit`, empty) after expansion. The truncation below (stop
# at the first non-word character) then reads that as the word `commi`,
# which fails the commit/push/add test and ALLOWs a write bash really ran
# as `commit`. Rather than re-implementing brace expansion here -- exactly
# the kind of re-derivation of what bash already knows that produced CL16
# -- an unresolved `{` in the subcommand word (checked on the UNTRUNCATED
# word, before the truncation below runs) is read as the same residual
# class as a `$`-expansion look-behind: this pass cannot evaluate it, so it
# deviates from that pattern's usual ALLOW and stays on the DENY side,
# because a `{` at exactly this position has no legitimate reading as
# prose (prose reaching this position already passed the quote-group test)
# and every real use of `git commit/push/add` needs no brace at all. A
# `${...}` parameter expansion is stripped before this test, not treated
# as a brace: `git ${V}` is the SAME accepted residual as `git $V` (a
# computed-subcommand shape this pass already declines to resolve), and
# `${` is never brace ALTERNATION syntax, so it carries none of the risk
# this check exists for.
MATCH=$(printf '%s' "$STRIPPED" | awk '
BEGIN { MARK = "\001" }
function has_brace(word,   stripped) {
    stripped = word
    gsub(/\$\{/, "", stripped)
    return index(stripped, "{") > 0
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
    for (i = 1; i <= n; i++) {
        hquoted = decode(words[i])
        hgroup = D_GROUP
        w = D_WORD
        hw = w
        sub(/^.*(\$\(|\140|\(|;|\||&)/, "", hw)
        if (hw == "git" || hw ~ /\/git$/) {
            j = i + 1
            helped = 0
            while (j <= n) {
                decode(words[j])
                opt = D_WORD
                if (opt !~ /^-/) break
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
                sw = s
                if (has_brace(sw)) { print "MATCH"; exit }
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
