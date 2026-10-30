#!/bin/bash

# trust-guard — PreToolUse: Bash.
#
# `docket trust add/rm` mutates the trust store that authorizes an executor's
# own completion gates (`~/.config/docket/trust.toml`, denied sandbox-write
# through TRUST_STORE_PATHS in claude_code.rs). Unlike every other write an
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
# THE STRUCTURAL CONTROL IS NOT THIS HOOK. The sandbox denies every write to
# trust.toml and its lock for every seat in a session, and the denial holds
# at runtime: the sandbox friction ledger (~/.claude/friction/sandbox.jsonl)
# records `docket trust add` and `docket trust rm` failing inside the sandbox
# on 2026-09-02, 09-06, 09-07, 09-08, 09-18, 09-26, 10-09 and 10-10, each
# with "operation not permitted" opening the lock file or renaming the
# store's temp file onto it. An executor cannot lift the sandbox
# (sandbox-bypass-guard-hook.sh). So a command that reaches the verb past
# this hook does not write the store; it fails at the OS. What this hook
# adds is the refusal's shape: an immediate, explained deny the seat can
# route as a finding, in place of a permission ask nobody is at a terminal
# to answer (one conductor's run sat behind such an ask for hours) or a bare
# "operation not permitted" a seat retries. A shape that hides the literal
# verb from the text, listed under KNOWN RESIDUALS below, is therefore not
# a defect of this hook's contract: the write it would carry is refused one
# layer down, with that evidence.
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
# every Bash call in the session) stands unchanged for both. The hook keeps
# no scratch file, so there is no third branch over an unwritable TMPDIR to
# reason about.

# THE RULE: a quoted string or a quoted-delimiter heredoc body is prose only
# in an INERT command. Everywhere else the whole command text is the scan.
#
# A command is inert when every command word in it names a program or
# builtin that never runs its input or its arguments as code (INERT_WORDS
# below: the writers and readers an executor's findings, payload and
# scratch notes go through, plus the docket CLI itself), the command
# branches on nothing (no `if`, `while`, `until`, `for`, `select`, `case`,
# `!`, `[`, `[[`, `test` or `||`), and PATH is not reassigned. A launcher
# (LAUNCHER_WORDS: `command`, `env`, `nice`, `timeout`, `sudo` and the
# rest) is read through to the word it launches, past its options, counts
# and assignments; a launcher that launches nothing visible is not inert.
# In an inert command the quoted groups the pre-pass marks are exempt as
# prose in THE MATCH below, and a quoted-delimiter heredoc body is not read
# at all. An unquoted-delimiter heredoc body is read even there: bash
# expands `$(...)` inside it before any consumer sees it.
#
# In any other command every byte is read with quotes and backslashes
# removed, the words bash would build from them: a body written to a file,
# a string handed to an interpreter, a function body, an `eval` argument, a
# comment, all alike. Which program runs it, how its name is spelled
# (`b\ash`, `b''ash`), what launches it, and which branch reaches it no
# longer matter, because the deny does not depend on tracing any of that.
#
# WHY THIS RULE, and not a list of what runs code. Each earlier design of this
# hook each named the shapes that turn data into code (interpreter names,
# code flags, launchers, run-a-file verbs, source through /dev/stdin), and
# each review of each list found the next shape the list missed: an
# unlisted launcher, a reader that takes a file as a program (`make`, `awk
# -f`), a name bound with `hash -p`, an interpreter spelling the regex did
# not join, a heredoc on a compound command that no simple command carried.
# That list is open by nature. The list of commands that run NOTHING is
# closed and short, so the exemption is keyed on it, and the failure
# direction of a word outside it is a false DENY with a recourse (the deny
# text below), never a missed write.
#
# WHAT THIS REMOVES. The earlier design walked the command with bash's own
# DEBUG trap (docket-guard-probe.sh, still used by the commit and sibling
# guards) to learn which simple commands bash would dispatch, then decided
# per leaf what was prose. That walk was accurate about what it saw and
# blind to what it could not reach: the right side of `||` after a vetoed
# command, an `if` or `&&` behind a file test that the vetoed write never
# satisfied, a loop over a glob or a substitution that was empty at probe
# time, and a heredoc attached to a compound command, whose body belongs to
# no leaf. The scan here reads the command's text, not its execution, so an
# unreached branch is read like a reached one. The syntax precheck stays:
# text bash cannot parse is refused rather than guessed at.
#
# KNOWN RESIDUALS, each a shape the sandbox refuses at the write and each
# pinned in the suite so a reader can tell a decision from a miss:
#   - A verb reached through an expansion (`$V trust add`, `docket trust
#     $(printf add)`, a decoded body), which leaves no literal run of the
#     three words anywhere in the text.
#   - A file written in one Bash call and run in a later one: the later
#     call carries no verb, and this hook sees one call at a time.
#   - `cat <<<docket trust add erik key`: the three words are cat's
#     operands and its stdin, nothing dispatches them.
# And on the false-DENY side, by design: prose that names the verb in the
# same call as any non-inert command (a `git commit -m`, a `grep` through
# `xargs`, an interpreter), inside a comment of such a call, or beside
# control flow. The recourse is in the deny text: the Write tool, or a
# Bash call that holds only inert commands.
#
# THE MATCH step below asks whether "docket trust add" or "docket trust rm"
# is present as three separately-resolved words (a redirection between them
# is skipped, as the shell drops it) versus one prose span, and whether a
# bare -h/--help stands right after a clean verb. The same awk program
# decides inertness, in `mode=inert`, from the same command-position
# tracking the brace rule already needed.

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

# --- Wall-clock bound. ----------------------------------------------------
#
# The harness cancels a hook that reaches its registered timeout (600 s) and
# then runs the Bash call unchecked, so a check that outlived the timeout
# would fail open. This hook therefore runs its whole check in a child copy
# of itself under a wall-clock bound of DOCKET_GUARD_BOUND_SECONDS seconds
# (default 60; a value other than a whole number from 1 to 300 reads as 60)
# and denies, naming the bound, when the bound fires.
# A CPU limit (`ulimit -t`) would not do: it is per process, and the awk
# passes are separate processes on separate budgets. The bound uses bash
# builtins alone, since this hook's dependency set is bash/cat/jq/awk.
# `set -m` puts the pipeline below in a process group of its own, so the
# child and everything it starts (the awk passes) share one group that this
# shell is outside of. The pipeline's last stage waits with `read -t` for
# the line carrying the child's exit status; when none arrives in time it
# reports the bound and kills the whole group, itself included, with
# `kill -KILL 0`. DOCKET_GUARD_BOUNDED marks the child, which runs the
# check below unchanged. docket-commit-guard-hook.sh and
# docket-sibling-guard-hook.sh carry the same bound.
if [ -z "${DOCKET_GUARD_BOUNDED:-}" ]; then
    GUARD_BOUND=${DOCKET_GUARD_BOUND_SECONDS:-60}
    case $GUARD_BOUND in
        [1-9] | [1-9][0-9] | [12][0-9][0-9] | 300) ;;
        *) GUARD_BOUND=60 ;;
    esac
    INPUT=$(cat 2>/dev/null) || allow_default
    exec 4>&1 5>&2
    # The redirect sits inside the substitution: one after its `)` would apply
    # only once the substitution had run. Job control writes its warnings,
    # such as `child setpgid ...: Operation not permitted` where setpgid is
    # refused, to this stderr, and only the child's `2>&5` reaches the caller.
    GUARD_STATUS=$(
        exec 2>/dev/null
        set -m
        {
            printf '%s' "$INPUT" | DOCKET_GUARD_BOUNDED=1 "$BASH" "$0" >&4 2>&5 4>&- 5>&-
            printf '%s\n' "${PIPESTATUS[1]}"
        } | {
            if read -t "$GUARD_BOUND" -r guard_rc; then
                printf '%s' "$guard_rc"
                exit 0
            fi
            printf 'bound'
            kill -KILL 0
        }
    )
    case $GUARD_STATUS in
        bound) deny "trust-store write blocked: the trust-guard hook did not finish checking this command within its ${GUARD_BOUND} s wall-clock bound (DOCKET_GUARD_BOUND_SECONDS), so the command is refused rather than passed through unchecked. Split it into smaller Bash calls." ;;
        [0-9] | [0-9][0-9] | [0-9][0-9][0-9]) exit "$GUARD_STATUS" ;;
    esac
    exit 1
fi

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

REASON_PREFIX="trust-store write blocked:"

if [ "${#COMMAND}" -gt 262144 ]; then
    deny "$REASON_PREFIX this command is over 256 KiB, more than the trust-guard hook will check in one call. Split it into smaller Bash calls, or write a large body with the Write tool where you have it; a single call this large is refused rather than passed through unchecked."
fi
case "$COMMAND" in
    *$'\001'* | *$'\035'* | *$'\036'*)
        deny "$REASON_PREFIX this command carries a control byte (0x01, 0x1d or 0x1e) the trust-guard hook uses to frame its own analysis, so it cannot be checked. Remove the byte; no shell command needs it." ;;
esac

# --- Syntax first, on the same bytes the passes will read. ------------------
if ! printf '%s' "$COMMAND" | bash -n >/dev/null 2>&1; then
    deny "$REASON_PREFIX the trust-guard hook could not parse this command to check it (bash reported a syntax error while analyzing it) and refuses rather than guessing. Fix the command's syntax; if it is not actually invalid, that is a hook defect to report separately."
fi

# Install integrity before the passes: a hook copy missing a shared file
# beside it cannot decide whether a trust-store write is present and fails
# CLOSED (deny, not allow_default). This hook's whole job is deciding whether
# a trust-store write is present in the command, and with no lexer there is
# no way to make that call safely -- allowing would be worse than the
# tooling-gap fail-opens above, which apply only when the CALLER or shape
# can't be identified at all. The directory is a bash parameter expansion on
# `$0` rather than a call to the external `dirname`: this hook's dependency
# set is fixed at bash/cat/jq/awk, and the test suite runs it with PATH
# restricted to exactly those. Both files install as siblings under
# ~/.claude/hooks (src/user/claude_code.rs ships the whole hooks/ directory
# as one artifact), so resolving them beside this script's own path reaches
# the installed copies the same way in production and in the test suite's
# scratch-copy override.
HOOK_DIR="${0%/*}"
[ "$HOOK_DIR" = "$0" ] && HOOK_DIR="."
PREPASS_AWK="${HOOK_DIR}/docket-guard-prepass.awk"
[ -r "$PREPASS_AWK" ] || deny "trust-store write blocked: the trust-guard hook's shared pre-pass file (docket-guard-prepass.awk) is missing or unreadable beside this hook, so it cannot check this command. This is a hook installation defect, not a caller mistake -- report it rather than retrying."
LEAF_LINES_AWK="${HOOK_DIR}/docket-guard-leaf-lines.awk"
[ -r "$LEAF_LINES_AWK" ] || deny "trust-store write blocked: the trust-guard hook's shared line-selection file (docket-guard-leaf-lines.awk) is missing or unreadable beside this hook, so it cannot check this command. This is a hook installation defect, not a caller mistake -- report it rather than retrying."

# --- Code text: the command without its quoted-delimiter heredoc bodies. ----
#
# docket-guard-leaf-lines.awk (LEAF_LINES_AWK) in scan mode, over the whole
# command as one record, keeps every line but a quoted-delimiter heredoc body
# and its terminator, and keeps the text whole when a heredoc has an unquoted
# delimiter (its body expands) or when its quote-aware lexer cannot settle
# where a body ends. The pre-pass (PREPASS_AWK) then marks every quoted group
# with a sentinel and a group id so THE MATCH can tell one prose span from
# three separately-quoted words, and drops comments by a bash-shaped rule.
# The pre-pass walks bytes, and under a UTF-8 locale macOS awk refuses a lone
# byte of a multibyte character, so it runs in the C locale. A pass that
# fails (a program awk cannot parse) leaves the next stage no command to
# read, so the hook refuses rather than allowing.
#
# Line selection opens a comment at a `#` that starts a line, but bash joins
# a continuation first, so `echo x\` then `#y; sh` is `echo x#y; sh`, where
# the `#` is part of a word. Every backslash-newline directly before a `#`
# joins ahead of line selection, under the odd-run rule the join below
# states. Where bash would not join it (inside a comment, a quote or a
# quoted heredoc body), the next line already starts with `#`, so the merged
# text stays comment, quote or body; an unmatched heredoc terminator keeps
# the whole text as code. A continuation before any other byte must wait
# for the later join: joined early, a comment ending in a backslash
# (`echo hi # \`) would swallow the command on the next line.
CODE_TEXT=$(printf '%s' "$COMMAND" | LC_ALL=C awk 'BEGIN { RS = "\001"; ORS = "" } { t = $0; out = ""; while (match(t, /\\+\n#/)) { run = RLENGTH - 2; out = out substr(t, 1, RSTART - 1) substr(t, RSTART, run - run % 2) (run % 2 ? "" : "\n"); t = substr(t, RSTART + RLENGTH - 1) } print out t }' 2>/dev/null) || \
    deny "$REASON_PREFIX the trust-guard hook's comment-continuation pass failed, so it cannot check this command. This is a hook defect, not a caller mistake -- report it rather than retrying."
CODE_TEXT=$(printf '%s' "$CODE_TEXT" | awk -v mode=scan -v widen=0 -f "$LEAF_LINES_AWK") || \
    deny "$REASON_PREFIX the trust-guard hook's line-selection program failed (docket-guard-leaf-lines.awk), so it cannot check this command. This is a hook defect, not a caller mistake -- report it rather than retrying."
# The shell removes a backslash-newline and joins the two lines into one, so
# both passes below read logical lines: a continuation line is an argument,
# not a command (`jq -n \` then `--arg a b`), and a verb split across lines
# (`doc\` then `ket trust add`) is one word again. A backslash escaped by
# another (`\\` at the end of a line) is a literal, so only the last of an
# odd run joins. Apart from a continuation before `#`, joined above, this
# join runs after line selection, which has already dropped comments and
# quoted-delimiter heredoc bodies, where a trailing backslash joins nothing.
CODE_TEXT=$(printf '%s' "$CODE_TEXT" | LC_ALL=C awk 'BEGIN { RS = "\001"; ORS = "" } { t = $0; out = ""; while (match(t, /\\+\n/)) { run = RLENGTH - 1; out = out substr(t, 1, RSTART - 1) substr(t, RSTART, run - run % 2) (run % 2 ? "" : "\n"); t = substr(t, RSTART + RLENGTH) } print out t }' 2>/dev/null) || \
    deny "$REASON_PREFIX the trust-guard hook's line-joining pass failed, so it cannot check this command. This is a hook defect, not a caller mistake -- report it rather than retrying."
MARKED=$(printf '%s' "$CODE_TEXT" | LC_ALL=C awk -f "$PREPASS_AWK" 2>/dev/null) || \
    deny "$REASON_PREFIX the trust-guard hook's pre-pass program failed (docket-guard-prepass.awk), so it cannot check this command. This is a hook defect, not a caller mistake -- report it rather than retrying."

# --- THE MATCH, and the inertness test that bounds its prose exemption. -----
#
# One awk program, two modes. `mode=inert` walks the marked code text and
# prints ACTIVE at the first command word outside INERT_WORDS, the first
# control-flow word, the first `||`, or the first PATH assignment; a launcher
# word defers the test to the word it launches. `mode=match` is the match
# proper, on the marked code text of an inert command or on the unquoted
# whole text of any other.
#
# Three consecutive words `docket trust (add|rm)`, head-normalized on
# `docket` the same way commit-guard normalizes `git` (closes a delimiter
# or subshell glued directly onto the front with no whitespace), and
# quote-group-aware on all three words so real prose stays allowed while a
# trick built from separately-quoted tokens still denies. Consecutive as the
# shell dispatches them: a redirection between two of the words, or glued
# onto `docket`, is not one of them (argument_at).
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
# BRACE EXPANSION: the text keeps a word's SOURCE spelling, unexpanded --
# `docket trust ad{d,} erik key` reaches this scan as the literal text
# `ad{d,}`, not as the two words bash actually dispatches (`ad`, `d`) after
# expansion. The truncation below (stop at the first non-word character)
# then reads that as the word `ad`, which fails the add/rm test and ALLOWs a
# verb bash really ran as `add`. Rather than re-implementing brace expansion
# here, an unresolved `{` in the `trust` or verb word position (checked on
# the UNTRUNCATED word, before the truncation below runs) is read as the same
# residual class as a `$`-expansion look-behind: this pass cannot evaluate
# it, so it deviates from that pattern's usual ALLOW and stays on the DENY
# side, because every real use of `docket trust add/rm` needs no brace at
# all. Two shapes bash never expands skip that DENY and fall through to the
# ordinary word tests: a brace word in the same quote group as `docket` (and
# `trust`, at the verb position), since bash expands no quoted text, and a
# brace with no `,` or `..` anywhere after it on the line, which is literal
# text to bash (`stub docket {"ok":false}` in a findings note). A
# `${...}` parameter expansion is stripped before this test, not treated as
# a brace: `docket trust ${V} erik key` is the SAME accepted residual as
# `docket trust $V erik key` (an interpreter-reached-through-a-variable
# shape this pass already declines to resolve), and `${` is never brace
# ALTERNATION syntax, so it carries none of the risk this check exists for.
# The same DENY covers the `docket` word itself: an unquoted brace word in
# command position (`{docket,trust} add erik key`) can expand into the whole
# invocation, so it denies when it may expand and the letters of `docket trust
# add` or `docket trust rm` follow it in order. The zsh precommand modifiers
# `noglob`, `nocorrect` and `-` keep command position for the next word (zsh
# still brace-expands behind them), and after `repeat` every later word of the
# line is checked, because the pre-pass may split its count into several
# words. A brace word in argument position stays allowed. A brace word behind
# a wrapper (`env {docket,trust} add`, `env -u {x,docket} trust add`) is what
# the wrapper launches, which no inert command is, so the call is read
# unquoted and every word there is in command position.
MATCH_PROGRAM='
BEGIN {
    MARK = "\001"
    k = split("cat tee printf echo jq mkdir rmdir cd pwd ls wc head tail grep cut sort uniq tr diff cmp stat basename dirname realpath mktemp date sleep true false : chmod cp mv rm touch ln export local unset shift set readonly declare typeset read docket", list, " ")
    for (j = 1; j <= k; j++) INERT_WORDS[list[j]] = 1
    k = split("command builtin exec nohup nice timeout time setsid stdbuf sudo env repeat", list, " ")
    for (j = 1; j <= k; j++) LAUNCHER_WORDS[list[j]] = 1
    k = split("if elif while until for select case ! [ [[ test", list, " ")
    for (j = 1; j <= k; j++) FLOW_WORDS[list[j]] = 1
}
function active() { print "ACTIVE"; exit }
# The word in command position, or the word a launcher launches: a word
# outside INERT_WORDS ends the inert reading. A closing brace or paren is
# structure, not a command. A launcher defers the test to its operand.
function inert_word(word,   cw) {
    cw = word
    sub(/\).*$/, "", cw)
    if (cw == "" || cw == "}") return
    if (cw in FLOW_WORDS) active()
    if (cw in LAUNCHER_WORDS) { launch = 1; return }
    if (!(cw in INERT_WORDS)) active()
}
function has_brace(word,   stripped) {
    stripped = word
    gsub(/\$\{/, "", stripped)
    return index(stripped, "{") > 0
}
# Bash brace-expands only with a "," or ".." inside the braces. The pre-pass
# splits a source word at its embedded quotes, so the test reads the rest of
# the line rather than the one word: {"trust",} reaches here as three words.
function may_brace_expand(from,   k) {
    for (k = from; k <= n; k++) {
        if (index(words[k], ",") > 0 || index(words[k], "..") > 0) return 1
    }
    return 0
}
# Every word bash builds from a comma brace is a subsequence of the brace word
# itself, so a brace can dispatch a trust-store write only when docket, trust,
# and add or rm each appear as a subsequence from it to the end of its
# command. Each word is tested on its own, since words built from one brace
# share letters (`{docke,trus}t` is `docket trust`). The span starts at first
# (the brace word after any glued operator) and runs on through the words
# after it, up to the first unquoted ; | & or backtick, which ends the
# command. A redirection may stand anywhere in a simple command, so it ends
# nothing: its operator is dropped first, including the forms that carry & or
# | (2>&1, <&0, &>, >|), and its target stays in the span. The test reads no
# further: a heredoc body full of prose would otherwise spell the verb by
# chance. A sequence expression can build letters absent from its text (bash
# 4+ `{a..e..3}` is `a d`); zsh, the shell of the Bash tool, steps no letter
# range.
function may_spell_trust_verb(from, first,   k, rest, piece, p) {
    rest = first
    for (k = from + 1; k <= n; k++) {
        piece = words[k]
        if (substr(piece, 1, 1) != MARK) {
            gsub(/[<>]&|&>|>[|]/, "", piece)
            if ((p = match(piece, /[;|&\140]/)) > 0) {
                rest = rest substr(piece, 1, p - 1)
                break
            }
        }
        rest = rest piece
    }
    return rest ~ /d.*o.*c.*k.*e.*t/ && rest ~ /t.*r.*u.*s.*t/ && rest ~ /a.*d.*d|r.*m/
}
# An unquoted word that opens with a redirection operator, behind an optional
# fd number or {name}: `>f`, `2>&1`, `&>f`, `<<<x`, `>|f`, or a bare `>`.
# `<(` and `>(` are process substitutions, which are arguments.
function is_redirection(word,   rest) {
    if (substr(word, 1, 1) == MARK) return 0
    rest = word
    if (match(rest, /^[0-9]+/) || match(rest, /^[{][A-Za-z_][A-Za-z0-9_]*[}]/)) rest = substr(rest, RLENGTH + 1)
    if (match(rest, /^&>>?/) || match(rest, /^<<[<-]?/) || match(rest, /^[<>][<>&|]?/)) rest = substr(rest, RLENGTH + 1)
    else return 0
    return substr(rest, 1, 1) != "("
}
# An unquoted word that ends in a redirection operator with no target glued
# after it: `trust>`, `docket>>`, `trust>&`, `trust>|`, `trust&>`.
function ends_in_redirection(word) {
    if (word == "" || substr(word, 1, 1) == MARK) return 0
    return word ~ /[<>]$/ || word ~ /[<>][&|]$/ || word ~ /&>>?$/
}
# The index of the first word after the target of a bare redirection
# operator, which starts at words[k], and 0 when the command ends inside it.
# A quoted target holding blanks reaches here as several marked words of one
# group, and all of them are the target.
function past_target(k,   g, piece) {
    if (k > n) return k
    if (substr(words[k], 1, 1) == MARK) {
        decode(words[k])
        g = D_GROUP
        for (k++; k <= n && substr(words[k], 1, 1) == MARK; k++) {
            decode(words[k])
            if (D_GROUP != g) break
        }
        return k
    }
    piece = words[k]
    gsub(/[<>]&|&>|>[|]/, "", piece)
    if (piece ~ /[;|&\140]/) return 0
    return k + 1
}
# The index of the word the shell passes as the argument at words[k]. The
# shell drops a redirection from the word list, and where its target ends is
# not always recoverable here: the pre-pass writes bare a fragment glued
# after a quoted group holding blanks and a double-quoted target holding an
# expansion, and unquoted whole text has lost its quotes. So past a redirection the argument is the first later word of the
# same command that reads as want or holds an expandable brace, and 0 when
# none does. The command ends at the first unquoted ; | & or backtick that is
# not part of a redirection operator, and never inside target text glued to
# an operator: the pre-pass writes a blank-free quoted target bare, so
# `>a;b` may be `>"a;b"`, one word. Reading it as one costs a false DENY on
# the unquoted spelling. A brace word read by may_spell_trust_verb gets no
# such reading, so `{docket,trust} >"a;b" add` stays a residual ALLOW.
# The word after a bare operator is its target, never the argument, so a
# target spelled trust (`docket > trust trust add`) is skipped: after a bare
# operator word, and when prev, the word before words[k], ends in one
# (`trust> f`, `docket>& 2`).
function argument_at(k, want, prev,   w, piece) {
    if (k > n) return k
    if (ends_in_redirection(prev)) {
        k = past_target(k)
        if (!k) return 0
    } else if (!is_redirection(words[k])) return k
    for (; k <= n; k++) {
        if (!is_redirection(words[k])) {
            decode(words[k])
            w = D_WORD
            if (has_brace(w) && may_brace_expand(k)) return k
            sub(/[^A-Za-z0-9_-].*$/, "", w)
            if (w ~ want) return k
        } else if (ends_in_redirection(words[k])) {
            k = past_target(k + 1)
            if (!k) return 0
            k--
            continue
        }
        piece = words[k]
        if (substr(piece, 1, 1) == MARK) continue
        if (is_redirection(piece) && !ends_in_redirection(piece)) continue
        gsub(/[<>]&|&>|>[|]/, "", piece)
        if (piece ~ /[;|&\140]/) return 0
    }
    return 0
}
# A word bash reads in command position without making it the command name:
# an assignment, a reserved word or a zsh precommand modifier. A lone { is the
# reserved word unless a quoted fragment follows it, since the pre-pass splits
# {"a",b} at the quote.
function is_command_prefix(word, next_word) {
    if (word ~ /^[A-Za-z_][A-Za-z0-9_]*=/) return 1
    if (word ~ /^(if|then|else|elif|do|while|until|time|coproc|!|noglob|nocorrect|-)$/) return 1
    return word == "{" && substr(next_word, 1, 1) != MARK
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
function parens(word,   t, o, c) {
    t = word; o = gsub(/\(/, "", t)
    t = word; c = gsub(/\)/, "", t)
    return o - c
}
# The inert reading of one line of marked code text. Every word in command
# position must be inert: the first word of the line, the word after an
# operator (standalone, or glued: `(cat`, `sh;`), and the word a launcher
# launches. A quoted group is one word however many tokens the pre-pass
# split it into, and is the command when it stands in command position
# other than as an assignment value. Redirection operands, arithmetic spans
# and launcher options are skipped. A quoted group that holds a blank can
# never be an inert command, so `"a b"` in command position is active.
function inert_line(   i, q, w, m, segs, s, seg, trailing, prev_group) {
    cmdpos = 1
    launch = 0
    assign_tail = 0
    redir = 0
    arith = 0
    array = 0
    prev_group = ""
    for (i = 1; i <= n; i++) {
        q = decode(words[i])
        w = D_WORD
        if (q) {
            if (D_GROUP == prev_group) continue
            prev_group = D_GROUP
            if (redir) { redir = 0; continue }
            if (arith > 0) continue
            if (launch) { launch = 0; inert_word(w); cmdpos = 0; continue }
            if (cmdpos && !assign_tail) { inert_word(w); cmdpos = 0 }
            assign_tail = 0
            continue
        }
        prev_group = ""
        if (index(w, "||") > 0) active()
        if (w ~ /(^|[^A-Za-z0-9_])PATH\+?=/) active()
        # An operator ending the word (`x;`, `f)&&`) puts the next word in
        # command position whatever this word was.
        trailing = (w ~ /[\140(;|&]$/)
        skipped = 0
        if (arith > 0) { arith += parens(w); skipped = 1 }
        else if (index(w, "$((") > 0 || w ~ /^\(\(/) {
            arith = parens(w)
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
                if (launch) active()
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
                    if (launch) active()
                    cmdpos = 1
                    assign_tail = 0
                }
                if (seg == "") continue
                if (launch) {
                    if (seg ~ /^-/ || seg ~ /^[0-9]+$/ || seg ~ /^[A-Za-z_][A-Za-z0-9_]*\+?=/) continue
                    launch = 0
                    inert_word(seg)
                    cmdpos = 0
                    continue
                }
                if (!cmdpos) { assign_tail = 0; continue }
                if (seg in FLOW_WORDS) active()
                if (is_command_prefix(seg, words[i + 1])) { assign_tail = (seg ~ /=$/); continue }
                inert_word(seg)
                cmdpos = 0
                assign_tail = 0
            }
            if (parts[p] ~ /[(;|&]$/) {
                if (launch) active()
                cmdpos = 1
                assign_tail = 0
            }
            if (inside) cmdpos = 0
        }
        if (trailing) {
            if (launch) active()
            cmdpos = 1
            assign_tail = 0
        }
    }
    if (launch) active()
}
{
    n = split($0, words, /[ \t]+/)
    if (mode == "inert") { inert_line(); next }
    cmdpos = 1
    after_repeat = 0
    for (i = 1; i <= n; i++) {
        hquoted = decode(words[i])
        hgroup = D_GROUP
        w = D_WORD
        # The redirection operators that carry & or | (>&, <&, &>, >|) are
        # not command separators, so they are rewritten to their bare
        # redirection character before the cut below: the cut would
        # otherwise drop the brace word glued ahead of them ({a,b}>&2). The
        # bare character stays, so a redirection glued to a head word is
        # still trimmed off it. mawk has no backreference in a replacement,
        # hence one gsub per operator.
        cut = w
        if (!hquoted) {
            gsub(/>&/, ">", cut)
            gsub(/<&/, "<", cut)
            gsub(/&>/, ">", cut)
            gsub(/>[|]/, ">", cut)
        }
        hw = cut
        # Keep the text after the last glued operator. One leftmost match
        # of a one-byte class per pass: mawk does not take the longest
        # match of a greedy prefix before an alternation.
        while (match(hw, /[\140(;|&]/)) hw = substr(hw, RSTART + 1)
        # Command position: line start, after an assignment or reserved
        # word, after a standalone operator, or behind a glued one. A quoted
        # fragment leaves it unchanged: the pre-pass splits one source word
        # at its quotes, so FOO="a b" reaches here as three words. On
        # unquoted whole text (anypos) every word is read as if in command
        # position, since quote removal has already lost that boundary.
        if (!hquoted) {
            at_command = cmdpos || hw != cut || anypos
            # A glued or standalone operator ends the repeat command.
            if (hw != cut) after_repeat = 0
            if (at_command && hw == "repeat") {
                after_repeat = 1
                cmdpos = 1
            } else if (at_command && is_command_prefix(hw, words[i + 1])) {
                cmdpos = 1
            } else {
                if (after_repeat && hw == "") after_repeat = 0
                at_command = at_command || after_repeat
                if (at_command && has_brace(hw) && may_brace_expand(i) && may_spell_trust_verb(i, hw)) { print "MATCH"; exit }
                cmdpos = (hw == "")
            }
        }
        # On unquoted whole text an assignment value is glued to its name
        # (`C=docket trust add ...`), and the value runs once expanded.
        # A redirection glued onto the head word (`docket>/dev/null`) is not
        # part of the command name.
        hd = hw
        if (!hquoted) sub(/[<>].*$/, "", hd)
        if (anypos && hd ~ /^[A-Za-z_][A-Za-z0-9_]*\+?=docket$/) hd = "docket"
        if (hd == "docket" || hd ~ /\/docket$/) {
            if (i + 2 > n) continue
            t = argument_at(i + 1, "^trust$", hquoted ? "" : hw)
            if (!t || t + 1 > n) continue
            tquoted = decode(words[t])
            tgroup = D_GROUP
            tw = D_WORD
            texact = tw
            if (has_brace(tw) && !(hquoted && tquoted && hgroup == tgroup) && may_brace_expand(t)) { print "MATCH"; exit }
            sub(/[^A-Za-z0-9_-].*$/, "", tw)
            if (tw != "trust") continue
            v = argument_at(t + 1, "^(add|rm)$", words[t])
            if (!v) continue
            vquoted = decode(words[v])
            vgroup = D_GROUP
            vw = D_WORD
            vexact = vw
            if (has_brace(vw) && !(hquoted && tquoted && vquoted && hgroup == tgroup && tgroup == vgroup) && may_brace_expand(v)) { print "MATCH"; exit }
            sub(/[^A-Za-z0-9_-].*$/, "", vw)
            if (vw != "add" && vw != "rm") continue
            if (hquoted && tquoted && vquoted && hgroup == tgroup && tgroup == vgroup) continue
            # Help read: an unquoted, bare -h/--help directly after a clean
            # verb. Only a glued trailing shell operator is stripped from the
            # flag (it ends the segment); any other suffix is a different
            # argument and keeps the deny. See the comment above the block.
            if (texact == tw && vexact == vw && v + 1 <= n) {
                pquoted = decode(words[v + 1])
                pw = D_WORD
                sub(/[|&;()<>].*$/, "", pw)
                if (!strict && !pquoted && (pw == "-h" || pw == "--help")) continue
            }
            print "MATCH"
            exit
        }
    }
}
'

# An awk that exits non-zero with nothing printed did not finish its pass (a
# program that fails to parse prints nothing), so its empty output is not a
# verdict: refuse, as for a missing pre-pass file. A printed result still
# decides, since the program exits early on it and the pipeline can then end
# on SIGPIPE.
INERT=$(printf '%s' "$MARKED" | awk -v mode=inert "$MATCH_PROGRAM" 2>/dev/null)
INERT_RC=$?
if [ "$INERT_RC" -ne 0 ] && [ -z "$INERT" ]; then
    deny "$REASON_PREFIX the trust-guard hook's match program failed (awk exit ${INERT_RC}), so it cannot check this command. This is a hook defect, not a caller mistake -- report it rather than retrying."
fi
# The pre-pass emits `X= "a b"` and `X="a b"` alike (`X=` then marked
# tokens), and the inert pass reads a marked group after an `=`-ending word
# as that assignment's value. For the spaced form bash runs the quoted word
# as the command, so the code text itself decides: an assignment name, `=`,
# blank space and a quote make the call active.
EMPTY_ASSIGN_RE='(^|[^A-Za-z0-9_])[A-Za-z_][A-Za-z0-9_]*\+?=[[:space:]]+[\"'"'"']'
if [ "$INERT" != "ACTIVE" ] && [[ "$CODE_TEXT" =~ $EMPTY_ASSIGN_RE ]]; then
    INERT=ACTIVE
fi

ANYPOS=0
if [ "$INERT" = "ACTIVE" ]; then
    # The whole command, as the words bash builds: a backslash-newline joins
    # its lines, `$'` and `$"` are quotes, and every quote and backslash is
    # dropped. Nothing is marked, so no span is prose, and the brace rules
    # read every word as if in command position (anypos), since the quote
    # removal has lost the boundary that told a value from a command.
    SCAN_TEXT=$(printf '%s' "$COMMAND" | LC_ALL=C awk 'BEGIN { RS = "\001"; ORS = "" } { t = $0; gsub(/\\\n/, " ", t); gsub(/\$\047/, "\047", t); gsub(/\$\042/, "\042", t); gsub(/[\047\042\\]/, "", t); print t }' 2>/dev/null) || \
        deny "$REASON_PREFIX the trust-guard hook's unquoting pass failed, so it cannot check this command. This is a hook defect, not a caller mistake -- report it rather than retrying."
    ANYPOS=1
else
    SCAN_TEXT=$MARKED
fi

MATCH=$(printf '%s' "$SCAN_TEXT" | awk -v mode=match -v strict="$CONDUCTOR" -v anypos="$ANYPOS" "$MATCH_PROGRAM" 2>/dev/null)
MATCH_RC=$?
if [ "$MATCH_RC" -ne 0 ] && [ -z "$MATCH" ]; then
    deny "$REASON_PREFIX the trust-guard hook's match program failed (awk exit ${MATCH_RC}), so it cannot check this command. This is a hook defect, not a caller mistake -- report it rather than retrying."
fi
[ "$MATCH" = "MATCH" ] || allow_default

if [ "$CONDUCTOR" = "1" ]; then
    deny "trust-store write blocked: \`docket trust add/rm\` is operator-reserved and never the conductor's to run, \`--help\` included: a background seat's permission ask has nobody at a terminal to answer it, and one conductor has held one for hours. Send the trust matter to \`main\` as its own \`question:\` (never bundled with another gate) and end your turn; the operator's own terminal is the only path to that store."
fi
deny "trust-store write blocked: \`docket trust add/rm\` is operator-reserved and never in scope for an executor step, whatever the brief says. If your step genuinely needs a trust entry changed, that is a routing defect: record the mismatch as your step's finding through the gap channel your brief names, and do not retry this call. If this command performs no trust-store write, the phrase appears as prose in a call that also runs something (known limitation: quoted text is prose only in a call made of inert commands such as cat, tee, printf, echo, jq, mkdir, ls and docket, with no interpreter, launcher, file run, loop, condition or PATH change beside it). To read or search a file's content, use the Read or Grep tool instead (bypasses this matcher entirely). To write prose that names the phrase, use the Write tool where you have it, or a Bash call that holds only inert commands, for example \`cat > \"\$TMPDIR/STEP-N.d/STEP-N-findings.md\" <<'EOF'\` with nothing else in the same call; put any other command in a call of its own."
