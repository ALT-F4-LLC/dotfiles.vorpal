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
#
# TWO FAIL-OPEN BRANCHES, and whether an executor seat can reach them:
# unparseable stdin (`INPUT=$(cat ...) || allow_default`, this file's own
# INPUT= line) and missing `jq` (the `command -v jq` check right after it).
# Both are decided KEEP FAILING OPEN, on a MEASURED (not inferred) answer to
# whether an executor's own Bash calls can move PATH for a LATER hook
# invocation in the same session: it cannot. [Claude Code hooks
# documentation] a hook process inherits the parent Claude Code process's
# environment directly (only the OTEL_* exporter vars are stripped, plus
# whatever CLAUDE_CODE_SUBPROCESS_ENV_SCRUB=1 would strip, which this
# fleet's settings set to "0"); [Claude Code tools reference] "Environment
# variables don't persist [across Bash tool calls]. An `export` in one
# command won't be available in the next." So PATH for THIS hook's own
# process comes from the operator's Claude Code CLI environment at launch,
# not from anything an executor's Bash tool invocations do -- this
# repository's own settings builder (src/user/claude_code.rs) sets neither
# PATH nor TMPDIR in its `env` block, so both stay at the operator's
# ambient values. An executor cannot set PATH for its OWN commands either
# in a way that survives to the NEXT hook call: each Bash tool call and its
# PreToolUse hook get a fresh environment snapshot. Both branches are
# therefore an operator-machine tooling gap, not an attacker-reachable
# input, so the existing fail-open direction (a tooling gap must not brick
# every Bash call in the session) stands unchanged for both. The probe
# keeps no scratch file (framed leaves travel on stdout instead), so there
# is no third branch over an unwritable TMPDIR to reason about.

# REDESIGN, replacing a hand-rolled AWK shell lexer that re-scanned
# raw command bytes for heredocs, comments, arithmetic expansions, and
# separators with no notion of bash's actual grammar. Three fix-loop rounds
# on that lexer EACH found a live, reproduced bypass or false-DENY
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
#
# PROBE HARDENING, ported from docket-sibling-guard-hook.sh, where four
# reproduced shapes showed the original probe executes part of the
# caller's command for real, or can be silenced entirely, while
# "analyzing" it:
#   - The probe shell is RESTRICTED (`set -r`) once the trap is armed, so
#     no redirection can open a file. A vetoed leaf never performs its own
#     redirection (a re-derivation of the sibling guard's own finding), but
#     a redirection on a STRUCTURAL builtin (`: > f`, `true > f`, `[ ] > f`)
#     or a COMPOUND command (`{ ...; } > f`, `( ... ) > f`, a loop or `if`
#     with a trailing `> f`) was performed by the unhardened probe,
#     truncating the target before any verdict — and a compound redirect
#     appears in no `$BASH_COMMAND` at all, so it never even reached the
#     matcher. A structural leaf carrying `<` or `>` now ends the probe
#     with a distinct exit code, and a compound redirect fails under the
#     restriction and denies on its error text.
#   - `readonly -f` on the handler: `_guard_probe() { return 0; }; ...` is
#     a function DEFINITION, a compound command the DEBUG trap never sees,
#     so it silently disarmed the walk and let the rest of the command run
#     for real. Redefinition now fails, and the attempt itself denies.
#   - Function-call leaves are RECORDED (via an fd-9 probe under the
#     restricted shell, since `declare -F ... >/dev/null` itself is a
#     redirection `set -r` would refuse) before the body is walked, and
#     `for`/`select`/`case`/`eval` headers are recorded as scan lines, so a
#     wrapper function or a computed verb inside a loop still reaches the
#     matcher.
#   - `break` and `continue` RUN, so a loop ends where the real command's
#     would; `exit`/`return` stay vetoed so the caller cannot pick the
#     probe's own exit status. The leaf cap EXITS the probe outright
#     (nothing runs after it) instead of disarming the trap, and is
#     checked before the empty-walk allow — the unhardened probe's cap
#     disarmed the trap and fell through to allow on an empty leaf list.
#   - The command reaches the probe on STDIN with a `bash -n` syntax
#     precheck first, and is refused outright over 256 KiB (the shared
#     pre-pass is quadratic in a word's length), rather than traveling
#     through the environment where an over-limit command made `bash -c`
#     fail with no leaf and no syntax error, which allowed.
#   - No temporary file: leaves travel on stdout framed in `\035...\036`
#     bytes, recovered from bash's own merged stderr. The old design's
#     predictable `$TMPDIR/<hook>.<pid>` path is gone along with the class
#     of attack a planted symlink or FIFO at that path enabled.

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

# The docket-run conductor is spawned as a named general-purpose agent, and
# the harness reports that name as its `agent_type` (`docket-conductor-RUN-N`,
# observed in ~/.claude/friction). Trust-store writes are operator-reserved
# in the conductor's own contract, so it has no legitimate path to the verb
# at all -- not even the help read below: the ask rule in claude_code.rs
# still fires on `docket trust add --help`, and a background seat's ask has
# nobody at a terminal to answer it. One conductor issued exactly that
# help read and its whole run sat behind the unanswered prompt for hours.
# Denying here is what turns that prompt into an immediate,
# explained refusal the conductor can route to `main` as a question.
is_conductor_seat() {
    case "$1" in
        docket-conductor-RUN-*) return 0 ;;
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
CONDUCTOR=0
if is_conductor_seat "$AGENT_TYPE"; then
    CONDUCTOR=1
elif ! is_executor_archetype "$AGENT_TYPE"; then
    allow_default
fi

COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null) || allow_default
[ -n "$COMMAND" ] || allow_default

# --- Leaf enumeration: ask bash, don't re-derive it. ---------------------
#
# PROBE_TEXT holds every simple command bash's own grammar would dispatch,
# `\036`-framed, each possibly itself multi-line when it embeds a heredoc
# (the heredoc's body arrives as part of that ONE leaf's text, exactly as
# bash reconstructs $BASH_COMMAND). The 2000-command ceiling below (exit
# 113) is a circuit breaker against a crafted or pathological input driving
# this into a long-running loop, not a bound expected to matter for an
# ordinary executor call (empirically, hundreds of simple commands
# enumerate in well under a second).
#
REASON_PREFIX="trust-store write blocked:"

if [ "${#COMMAND}" -gt 262144 ]; then
    deny "$REASON_PREFIX this command is over 256 KiB, more than the trust-guard hook will check in one call. Split it into smaller Bash calls, or write a large body with the Write tool where you have it; a single call this large is refused rather than passed through unchecked."
fi
case "$COMMAND" in
    *$'\035'* | *$'\036'*)
        deny "$REASON_PREFIX this command carries a control byte (0x1d or 0x1e) the trust-guard hook uses to frame its own analysis, so it cannot be checked. Remove the byte; no shell command needs it." ;;
esac

# --- Syntax first, on the same bytes the probe will walk. ------------------
if ! printf '%s' "$COMMAND" | bash -n >/dev/null 2>&1; then
    deny "$REASON_PREFIX the trust-guard hook could not parse this command to check it (bash reported a syntax error while analyzing it) and refuses rather than guessing. Fix the command's syntax; if it is not actually invalid, that is a hook defect to report separately."
fi

# `eval "$COMMAND"` is how the untrusted text reaches bash as SOURCE rather
# than as a re-quoted argument: COMMAND travels on stdin, never through
# string interpolation into this script's own source, so nothing about the
# outer invocation's quoting can be confused by what the inner text
# contains — it is parsed exactly once, by bash, exactly as it would be if
# the real Bash tool ran it. `eval` itself is on the structural allowlist
# below (it is a control mechanism, not a leaf) so the trap sees straight
# through it to what is actually inside.
#
# Leaves are printed as \035<text>\036 frames on stdout; bash's stderr is
# merged into the same capture and recovered from between the frames. Exit
# codes: 113 the cap, 114 a redirection on a structural builtin. The caller
# cannot pick either: `exit` and `return` are vetoed, and a vetoed leaf
# reports success.
PROBE_RAW=$(printf '%s' "$COMMAND" | bash -c '
    shopt -s extdebug
    set -T
    COMMAND=$(cat)
    _leaf_n=0   # not `n`: the analyzed command shares this shell, and `for n in …` collided with the counter
    # A leaf that is only variable assignments RUNS (see the header), but
    # only in these value shapes: bare words, $name, ${name}, and $(( ))
    # over names and operators. No quotes, no $( ), no backticks, no
    # subscripts, so nothing an assignment can evaluate runs a command.
    readonly _leaf_name="[A-Za-z_][A-Za-z0-9_]*"
    readonly _leaf_word="[A-Za-z0-9_./:@%+,-]|\\\$${_leaf_name}|\\\$\\{${_leaf_name}\\}|\\\$\\(\\(([^][()\$\`]|\\\$${_leaf_name})*\\)\\)"
    readonly _leaf_assign_re="^${_leaf_name}\\+?=(${_leaf_word})*([[:space:]]+${_leaf_name}\\+?=(${_leaf_word})*)*\$"
    _guard_probe() {
        _leaf_n=$((_leaf_n + 1))
        if [ "$_leaf_n" -gt 2000 ]; then
            exit 113
        fi
        # The first firing is this probe own eval line, not a leaf of the
        # command; recording it would put an interpreter word in every walk.
        if [ "$_leaf_n" -eq 1 ] && [ "$BASH_COMMAND" = "eval \"\$COMMAND\"" ]; then
            return 0
        fi
        local head="${BASH_COMMAND%%[ $'"'"'\t\n'"'"']*}"
        head="${head##*/}"
        case "$head" in
            for | select | case | eval)
                case "$BASH_COMMAND" in
                    *[\<\>]*) exit 114 ;;
                esac
                printf "\035%s\036" "$BASH_COMMAND"
                return 0 ;;
            while | until | if | elif | else | fi | then | do | done | \
            esac | function | time | "{" | "}" | "[" | "[[" | : | \
            true | false | break | continue)
                case "$BASH_COMMAND" in
                    *[\<\>]*) exit 114 ;;
                esac
                return 0 ;;
        esac
        if [[ "$BASH_COMMAND" =~ $_leaf_assign_re ]]; then
            case "$BASH_COMMAND" in
                *_leaf_*) ;;   # the counter and these patterns: never the command'"'"'s to set
                *)
                    printf "\035%s\036" "$BASH_COMMAND"
                    return 0 ;;
            esac
        fi
        printf "\035%s\036" "$BASH_COMMAND"
        if declare -F "$head" >&9 2>&9; then
            return 0
        fi
        return 1
    }
    readonly -f _guard_probe
    exec 9>/dev/null
    set -r
    trap _guard_probe DEBUG
    eval "$COMMAND"
' 2>&1)
PROBE_RC=$?

if [ "$PROBE_RC" -eq 113 ]; then
    deny "$REASON_PREFIX this command has too many parts (over 2000) for the trust-guard hook to finish checking it. Split it into smaller Bash calls; a single call this large is refused rather than passed through unchecked."
fi
if [ "$PROBE_RC" -eq 114 ]; then
    deny "$REASON_PREFIX a redirection on a shell builtin that carries no command (\`: > file\`, \`true > file\`, \`[ ... ] > file\`) cannot be checked for a trust-store write. Truncate or create a file with \`cat /dev/null > <path>\`, so the target is a visible operand."
fi

# Leaves are the framed segments; everything outside a frame is bash's own
# stderr during the walk.
PROBE_TEXT=$(printf '%s' "$PROBE_RAW" | awk 'BEGIN { RS = "\036"; ORS = "" } { i = index($0, "\035"); if (i > 0) printf "%s\036", substr($0, i + 1) }')
PROBE_ERR=$(printf '%s' "$PROBE_RAW" | awk 'BEGIN { RS = "\036"; ORS = "" } { i = index($0, "\035"); if (i > 0) printf "%s", substr($0, 1, i - 1); else printf "%s", $0 }')

case "$PROBE_ERR" in
    *"restricted: cannot redirect output"*)
        deny "$REASON_PREFIX a redirection on a compound command (\`{ ... } > file\`, \`( ... ) > file\`, a loop or \`if\` followed by \`> file\`, or a function call \`> file\`) hides its target from this check. Redirect each simple command's output on its own, e.g. \`docket trust list > <path>\`." ;;
    *"readonly function"*)
        deny "$REASON_PREFIX this command redefines the trust-guard hook's own probe handler (\`_guard_probe\`). No command needs a function by that name; rename it." ;;
esac

if [ -z "$PROBE_TEXT" ]; then
    # No leaf dispatched: the command is inert (all comment, all whitespace,
    # or only structural builtins), unless bash reported something while
    # walking it, in which case the walk is "could not analyze" and refuses
    # -- this hook's own direction on an unresolvable case is a false DENY
    # over a missed invocation.
    if [ -n "$PROBE_ERR" ]; then
        deny "$REASON_PREFIX the trust-guard hook could not analyze this command (bash reported: ${PROBE_ERR%%$'\n'*}) and refuses rather than guessing. Simplify the command; if it is valid, that is a hook defect to report separately."
    fi
    allow_default
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
#
# The boundary on either side of an interpreter name is any byte that is not
# a word character and not a dot. The dot is what separates a file name from
# its extension, so a target named `cases.sh`, `x.env` or `run.node` is not
# an interpreter and does not widen; every spelling that can run
# one still does (`sh`, `/bin/sh`, `"sh"`, `$(sh`, a backtick, `;sh`).
INTERPRETER_RE='(^|[^A-Za-z0-9_.])(sh|bash|dash|zsh|ksh|mksh|csh|tcsh|python[0-9.]*|perl|ruby|node|nodejs|php|lua[0-9.]*|tclsh|expect|osascript|env|eval)([^A-Za-z0-9_.]|$)'
WIDEN=0
if [[ "$PROBE_TEXT" =~ $INTERPRETER_RE ]]; then
    WIDEN=1
fi

SCAN_TEXT=$(printf '%s' "$PROBE_TEXT" | awk -v RS='\036' -v widen="$WIDEN" '
    # Drops every balanced arithmetic span from a line: $((...)), ((...))
    # and $[...]. A shift operator inside one is never a heredoc operator.
    # An unbalanced opener is kept verbatim with everything after it, so
    # the heredoc scan still reads any << there and errs toward widening.
    function strip_arith(s,   out, i, n, c, depth, start) {
        out = ""
        i = 1
        n = length(s)
        while (i <= n) {
            c = substr(s, i, 1)
            if (substr(s, i, 3) == "$((" || substr(s, i, 2) == "((") {
                start = i
                i += (c == "$") ? 3 : 2
                depth = 2
                while (i <= n && depth > 0) {
                    c = substr(s, i, 1)
                    if (c == "(") depth++
                    else if (c == ")") depth--
                    i++
                }
                if (depth > 0) return out substr(s, start)
                continue
            }
            if (substr(s, i, 2) == "$[") {
                start = i
                i += 2
                depth = 1
                while (i <= n && depth > 0) {
                    c = substr(s, i, 1)
                    if (c == "[") depth++
                    else if (c == "]") depth--
                    i++
                }
                if (depth > 0) return out substr(s, start)
                continue
            }
            out = out c
            i++
        }
        return out
    }
    # True when any heredoc operator on the line has an unquoted delimiter.
    # Checked per operator rather than per line: a quoted delimiter must not
    # mask an unquoted one beside it, whose body bash expands before any
    # consumer sees it. A here-string (<<<) is skipped as one unit. After <<
    # come an optional dash and blanks, then the delimiter: a quote or a
    # backslash there means quoted; anything else, end of line included,
    # means unquoted.
    function unquoted_heredoc(s,   rest, p, after, c) {
        rest = s
        while ((p = index(rest, "<<")) > 0) {
            after = substr(rest, p + 2)
            if (substr(after, 1, 1) == "<") {
                rest = substr(after, 2)
                continue
            }
            sub(/^-?[ \t]*/, "", after)
            c = substr(after, 1, 1)
            if (c != "\047" && c != "\042" && c != "\\") return 1
            rest = after
        }
        return 0
    }
    BEGIN { out = "" }
    {
        leaf = $0
        if (leaf == "") next
        eol = index(leaf, "\n")
        line1 = (eol == 0 ? leaf : substr(leaf, 1, eol - 1))
        leaf_widen = (widen == "1")
        # A heredoc operator on this leafs own first line whose delimiter
        # is NOT quoted, judged per operator by unquoted_heredoc above so
        # that a quoted delimiter never masks an unquoted one on the same
        # line, and with arithmetic shifts stripped first.
        if (!leaf_widen && index(line1, "<<") > 0 && unquoted_heredoc(strip_arith(line1))) {
            leaf_widen = 1
        }
        if (leaf_widen) {
            out = out leaf "\n"
        } else {
            out = out line1 "\n"
        }
    }
    END { printf "%s", out }
')

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
#
# The awk PROGRAM itself lives in docket-guard-prepass.awk, shared
# byte-for-byte with docket-commit-guard-hook.sh: both hooks
# install as siblings under ~/.claude/hooks (src/user/claude_code.rs ships
# the whole hooks/ directory as one artifact), so resolving it beside this
# script's own path reaches the installed copy the same way in production
# and in the test suite's scratch-copy override. A missing file fails
# CLOSED (deny, not allow_default): this hook's whole job is deciding
# whether a trust-store write is present in the command, and with no
# pre-pass program there is no way to make that call safely -- allowing
# would be worse than the tooling-gap fail-opens above, which apply only
# when the CALLER or shape can't be identified at all, not when the lexer
# itself is missing. The directory is a bash parameter expansion on `$0`
# rather than a call to the external `dirname`: this hook's dependency set
# is fixed at bash/cat/jq/awk, and the test suite runs it with PATH
# restricted to exactly those.
HOOK_DIR="${0%/*}"
[ "$HOOK_DIR" = "$0" ] && HOOK_DIR="."
PREPASS_AWK="${HOOK_DIR}/docket-guard-prepass.awk"
[ -r "$PREPASS_AWK" ] || deny "trust-store write blocked: the trust-guard hook's shared pre-pass file (docket-guard-prepass.awk) is missing or unreadable beside this hook, so it cannot check this command. This is a hook installation defect, not a caller mistake -- report it rather than retrying."
STRIPPED=$(printf '%s' "$SCAN_TEXT" | awk -f "$PREPASS_AWK" 2>/dev/null) || allow_default

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
#
# BRACE EXPANSION: bash's own $BASH_COMMAND reconstruction keeps
# a leaf's SOURCE spelling, unexpanded -- `docket trust ad{d,} erik key`
# reaches this scan as the literal text `ad{d,}`, not as the two words bash
# actually dispatches (`ad`, `d`) after expansion. The truncation below
# (stop at the first non-word character) then reads that as the word `ad`,
# which fails the add/rm test and ALLOWs a verb bash really ran as `add`.
# Rather than re-implementing brace expansion here -- exactly the kind of
# re-derivation of what bash already knows that produced CL16 -- an
# unresolved `{` in the `trust` or verb word position (checked on the
# UNTRUNCATED word, before the truncation below runs) is read as the same
# residual class as a `$`-expansion look-behind: this pass cannot evaluate
# it, so it deviates from that pattern's usual ALLOW and stays on the DENY
# side, because a `{` at exactly this position has no legitimate reading as
# prose (prose reaching this position already passed the quote-group test)
# and every real use of `docket trust add/rm` needs no brace at all. A
# `${...}` parameter expansion is stripped before this test, not treated as
# a brace: `docket trust ${V} erik key` is the SAME accepted residual as
# `docket trust $V erik key` (an interpreter-reached-through-a-variable
# shape this pass already declines to resolve), and `${` is never brace
# ALTERNATION syntax, so it carries none of the risk this check exists for.
MATCH=$(printf '%s' "$STRIPPED" | awk -v strict="$CONDUCTOR" '
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
        if (hw == "docket" || hw ~ /\/docket$/) {
            if (i + 2 > n) continue
            tquoted = decode(words[i + 1])
            tgroup = D_GROUP
            tw = D_WORD
            texact = tw
            if (has_brace(tw)) { print "MATCH"; exit }
            sub(/[^A-Za-z0-9_-].*$/, "", tw)
            if (tw != "trust") continue
            vquoted = decode(words[i + 2])
            vgroup = D_GROUP
            vw = D_WORD
            vexact = vw
            if (has_brace(vw)) { print "MATCH"; exit }
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
                if (!strict && !pquoted && (pw == "-h" || pw == "--help")) continue
            }
            print "MATCH"
            exit
        }
    }
}
' 2>/dev/null)
[ "$MATCH" = "MATCH" ] || allow_default

if [ "$CONDUCTOR" = "1" ]; then
    deny "trust-store write blocked: \`docket trust add/rm\` is operator-reserved and never the conductor's to run, \`--help\` included: a background seat's permission ask has nobody at a terminal to answer it, and one conductor has held one for hours. Send the trust matter to \`main\` as its own \`question:\` (never bundled with another gate) and end your turn; the operator's own terminal is the only path to that store."
fi
deny "trust-store write blocked: \`docket trust add/rm\` is operator-reserved and never in scope for an executor step, whatever the brief says. If your step genuinely needs a trust entry changed, that is a routing defect: record the mismatch as your step's finding through the gap channel your brief names, and do not retry this call. If this command performs no trust-store write, the matcher has false-positived on the phrase appearing as prose or as an interpreter's code argument (known limitation): to read or search a file's content, use the Read or Grep tool instead (bypasses this matcher entirely); to write prose that names the phrase, put it in a file through the Write tool where your archetype has one, and where it does not (executor-read has no Write), report the phrase in your return instead of passing it through Bash."
