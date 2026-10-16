#!/bin/bash

# Behavior suite for src/user/claude_code/hooks/docket-trust-guard-hook.sh
# (DOT-812).
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name
#
# THE PROPERTY UNDER TEST is caller-scoped, not command-scoped: the same
# `docket trust add/rm` invocation must DENY when agent_type names an
# executor archetype and ALLOW when it does not (main conversation, or any
# other agent type) -- that split is the whole point of this hook, and every
# case group below is organized around it rather than around the text
# matcher alone.
#
# DEFECT CLASS. Two failure directions, both silent in production:
#   FALSE ALLOW - a real `docket trust add/rm` invocation from an executor
#     whose shape or agent_type the matcher fails to recognize, so the write
#     that repoints a gate goes through unblocked.
#   FALSE DENY  - a read, a query, or prose that merely mentions
#     "docket trust add", a help read (`docket trust add --help`, which
#     opens nothing), or a main-conversation call, denied anyway.
#
# THE RULE the rows pin (the hook's header states it in full): quoted text
# and a quoted-delimiter heredoc body are prose only in an INERT call, one
# whose every command word is a program that runs nothing (cat, tee, printf,
# echo, jq, mkdir, ls, docket and the rest of the hook's list, reached
# through a launcher or not), with no branch, loop, `||` or PATH change. Any
# other call is read whole with its quotes removed, so a verb anywhere in it
# denies whatever runs it. Rows labeled "read unquoted" pin that side; the
# prose controls pin the inert side. The structural control is the sandbox,
# which refuses the trust-store write itself; this hook turns the refusal
# into an explained deny before a seat's permission ask can stall.
#
# SEAM. No engine, no `docket` binary, no filesystem: this hook makes exactly
# one decision from its stdin JSON and nothing else, so the suite is a single
# process reading the hook's exit code.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
HOOK="${GUARD_HOOK:-${REPO_ROOT}/src/user/claude_code/hooks/docket-trust-guard-hook.sh}"

PASS=0
FAIL=0

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    FAIL=$((FAIL + 1))
}

pass() {
    printf 'PASS: %s\n' "$1"
    PASS=$((PASS + 1))
}

fatal() {
    printf 'FATAL: %s\n' "$1" >&2
    exit 2
}

[ -f "$HOOK" ] || fatal "hook not found at ${HOOK}"
command -v jq >/dev/null 2>&1 || fatal "jq is required to run this test"

BASH_BIN=$(command -v bash) || fatal "bash not found on PATH"

# shellcheck source=tests/lib/hook-probe.sh
. "${SCRIPT_DIR}/lib/hook-probe.sh"

SANDBOX=$(mktemp -d "${TMPDIR:-/tmp}/docket-trust-guard-test.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$SANDBOX"' EXIT

TOOLS_DIR="${SANDBOX}/tools"
hook_probe_link_shims "$TOOLS_DIR" bash cat jq awk || fatal "cannot build hook probe shims"

# Classifies one hook run as DENY (exit 2) or ALLOW (exit 0). No
# permissionDecision envelope is emitted -- exit 2 is a pre-permission hard
# stop and exit 0 is silence -- so the exit code is the entire verdict. Any
# other exit is a broken hook, reported as ERROR so an ALLOW row cannot pass
# on a crash.
verdict_of() {
    local input="$1" rc
    PATH="$TOOLS_DIR" "$BASH_BIN" "$HOOK" >/dev/null 2>&1 <<<"$input"
    rc=$?
    case "$rc" in
        2) printf 'DENY' ;;
        0) printf 'ALLOW' ;;
        *) printf 'ERROR(exit %s)' "$rc" ;;
    esac
}

build_input() {
    local cmd="$1" agent="${2:-}"
    # The command travels on jq's stdin, not as an argument: a Linux argument
    # may carry at most 128 KiB, and a larger one would make jq fail to start
    # and hand the hook no input at all.
    if [ -n "$agent" ]; then
        printf '%s' "$cmd" | jq -Rsc --arg a "$agent" \
            '{tool_name:"Bash",tool_input:{command:.},agent_type:$a}'
    else
        printf '%s' "$cmd" | jq -Rsc '{tool_name:"Bash",tool_input:{command:.}}'
    fi
}

assert_verdict() {
    local cmd="$1" agent="$2" want="$3" label="$4" got
    got=$(verdict_of "$(build_input "$cmd" "$agent")")
    if [ "$got" = "$want" ]; then
        pass "${label} (${want})"
    else
        fail "${label} (want ${want}, got ${got})"
    fi
}

assert_verdict_raw() {
    local raw="$1" want="$2" label="$3" got
    got=$(verdict_of "$raw")
    if [ "$got" = "$want" ]; then
        pass "${label} (${want})"
    else
        fail "${label} (want ${want}, got ${got})"
    fi
}

# The one place the suite reads stderr: a deny must carry the hook's fixed
# reason line, so a narrowing of the matcher cannot silently swap the
# executor-facing text for a different one.
DENY_REASON='trust-store write blocked: `docket trust add/rm` is operator-reserved'

assert_deny_reason() {
    local cmd="$1" agent="$2" label="$3" err
    err=$(PATH="$TOOLS_DIR" "$BASH_BIN" "$HOOK" 2>&1 >/dev/null <<<"$(build_input "$cmd" "$agent")")
    case "$err" in
        "${DENY_REASON}"*) pass "${label} (reason text unchanged)" ;;
        *) fail "${label} (reason text changed or missing: ${err})" ;;
    esac
}

# ---- THE PROPERTY: same command, verdict turns on agent_type alone --------

case_executor_archetypes_deny() {
    assert_verdict "docket trust add erik ssh-ed25519 AAAA" executor-read DENY \
        "executor-read: docket trust add"
    assert_verdict "docket trust add erik ssh-ed25519 AAAA" executor-write DENY \
        "executor-write: docket trust add"
    assert_verdict "docket trust add erik ssh-ed25519 AAAA" executor-research DENY \
        "executor-research: docket trust add"
    assert_verdict "docket trust rm erik" executor-write DENY \
        "executor-write: docket trust rm"
}

# The docket-run conductor is a named general-purpose agent whose name is what
# the harness reports as agent_type (`docket-conductor-RUN-N`, seen in the
# friction ledger). Trust verbs are operator-reserved in its own contract, so
# it is denied like an executor -- and unlike one, its help read is denied too:
# the claude_code.rs ask rule still fires on `docket trust add --help`, and a
# background seat's ask has nobody to answer it (RUN-90, 188 minutes).
case_conductor_seat_denies() {
    assert_verdict "docket trust add erik ssh-ed25519 AAAA" docket-conductor-RUN-90 DENY \
        "conductor: docket trust add"
    assert_verdict "docket trust rm erik" docket-conductor-RUN-90 DENY \
        "conductor: docket trust rm"
    assert_verdict "docket trust add --help" docket-conductor-RUN-90 DENY \
        "conductor: the help read is denied too"
    assert_verdict "docket trust add --help 2>&1 | sed -n '1,60p'; echo '--- current sdet-abuse row ---'; docket trust list 2>&1 | grep -E '^sdet-abuse|^build'" \
        docket-conductor-RUN-90 DENY "conductor: RUN-90's own 14:52Z command"
    assert_verdict "docket trust list" docket-conductor-RUN-90 ALLOW \
        "conductor: docket trust list stays readable"
    assert_verdict "docket issue show AGT-1" docket-conductor-RUN-90 ALLOW \
        "conductor: ordinary verbs untouched"
    assert_verdict "docket trust add erik key" docket-conductor ALLOW \
        "near-miss: docket-conductor without a run suffix is not the seat"
    assert_verdict "docket trust add --help" executor-read ALLOW \
        "executor: the help read exemption is unchanged"
    assert_deny_reason "docket trust add erik key" docket-conductor-RUN-90 \
        "conductor: deny reason keeps the fixed prefix"
}

# executor-research has no Write tool, so the deny text must name a recovery
# every executor has beside the Write tool: a quoted-delimiter heredoc into
# its own STEP-N.d in a Bash call that holds only inert commands.
case_executor_read_deny_recovery() {
    local err
    err=$(PATH="$TOOLS_DIR" "$BASH_BIN" "$HOOK" 2>&1 >/dev/null <<<"$(build_input "docket trust add erik key" executor-read)")
    case "$err" in
        *"Write tool where you have it"*) pass "executor deny reason names the Write tool as one recovery, not the only one" ;;
        *) fail "executor deny reason names the Write tool as one recovery, not the only one (got: ${err})" ;;
    esac
    case "$err" in
        *"only inert commands"*"<<'EOF'"*'$TMPDIR/STEP-N.d'* | *"only inert commands"*'$TMPDIR/STEP-N.d'*"<<'EOF'"*)
            pass "executor deny reason names the own-scratch quoted heredoc in an inert call" ;;
        *) fail "executor deny reason names the own-scratch quoted heredoc in an inert call (missing: ${err})" ;;
    esac
}

case_main_conversation_and_other_agents_allow() {
    assert_verdict "docket trust add erik ssh-ed25519 AAAA" "" ALLOW \
        "no agent_type (main conversation): docket trust add"
    assert_verdict "docket trust rm erik" "" ALLOW \
        "no agent_type (main conversation): docket trust rm"
    assert_verdict "docket trust add erik ssh-ed25519 AAAA" planner ALLOW \
        "agent_type=planner (not an executor archetype): docket trust add"
    assert_verdict "docket trust add erik ssh-ed25519 AAAA" groomer ALLOW \
        "agent_type=groomer (not an executor archetype): docket trust add"
    assert_verdict "docket trust add erik ssh-ed25519 AAAA" general-purpose ALLOW \
        "agent_type=general-purpose (not an executor archetype): docket trust add"
}

# ---- MUST ALLOW: ordinary docket verbs, any caller -------------------------

case_ordinary_docket_verbs_allow() {
    assert_verdict "docket trust list" executor-write ALLOW \
        "executor: docket trust list (read-only verb, not add/rm)"
    assert_verdict "docket issue list" executor-write ALLOW \
        "executor: unrelated docket verb"
    assert_verdict "docket trust show erik" executor-write ALLOW \
        "executor: docket trust show (not add/rm)"
    # A loop over a bare list is control flow, so the text is read whole; it
    # names no verb, so it allows.
    assert_verdict 'for n in 100 833 922 1324 2026; do echo "$n"; done' executor-write ALLOW \
        "executor: for n in … loop (control flow with no verb in the text)"
}

# ---- MUST NOT CATCH: prose / read-only, from an executor -------------------

case_must_not_catch_prose_and_reads() {
    assert_verdict 'docket issue comment add D-1 -m "never run docket trust add"' \
        executor-write ALLOW "prose mentioning docket trust add inside -m body"
    assert_verdict 'echo "the phrase docket trust add appears here"' \
        executor-write ALLOW "single-quoted-content prose"
}

# ---- MUST DENY: separator/subshell-glued shapes, from an executor ---------

case_must_deny_glued_separator_class() {
    assert_verdict "cd /x && docket trust add erik key" executor-write DENY \
        "&& docket trust add"
    assert_verdict "cd /x &&docket trust add erik key" executor-write DENY \
        "&&docket trust add (no space)"
    assert_verdict "(docket trust rm erik)" executor-write DENY \
        "(docket trust rm) subshell"
    assert_verdict "/usr/local/bin/docket trust add erik key" executor-write DENY \
        "absolute path to docket binary"
}

# ---- MUST DENY: separately-quoted tokens forming a real invocation --------

case_must_deny_separately_quoted_tokens() {
    assert_verdict '"docket" "trust" "add" erik key' executor-write DENY \
        "separately-quoted docket/trust/add (bash-unquotes to a real call)"
}

# ---- MUST DENY: a word split by an empty or embedded quote pair --------
#
# Bash joins the fragments of one word across its quotes, so each of these
# runs the guarded verb. The pre-pass emits a blank-free quoted fragment
# glued to word text as bare text, so the matcher reads the joined word.
case_must_deny_quote_split_words() {
    assert_verdict 'docket trust a""dd erik key' executor-write DENY 'empty quote pair inside the verb'
    assert_verdict 'docket trust ad"d" erik key' executor-write DENY 'double-quoted tail of the verb'
    assert_verdict "docket trust 'a'dd erik key" executor-write DENY 'single-quoted head of the verb'
    assert_verdict "docket trust r''m erik" executor-write DENY 'empty quote pair inside rm'
    assert_verdict 'do""cket trust add erik key' executor-write DENY 'empty quote pair inside the CLI word'
    assert_verdict 'docket tr""ust add erik key' executor-write DENY 'empty quote pair inside the trust word'
}

# ---- MUST DENY: a brace-split verb word --------------------------------
#
# bash's own $BASH_COMMAND reconstruction keeps a leaf's source spelling,
# unexpanded: `docket trust ad{d,} erik key` reaches this hook as the
# literal text `ad{d,}`, not as the two words bash actually dispatches
# (`add`, then an extra empty-alternative token) once it expands the brace.
# The MATCH pass's word-truncation (stop at the first non-word character)
# used to read that as the word `ad`, which fails the add/rm test and
# ALLOWs a verb bash really runs as `add`. A brace can split any of the
# three words the matcher tests, so each position gets its own row.

case_brace_split_verb_denies() {
    assert_verdict "docket trust ad{d,} erik ssh-ed25519 AAAA" executor-write DENY \
        "brace-split verb: docket trust ad{d,}"
    assert_verdict "docket trust r{m,} erik" executor-write DENY \
        "brace-split verb: docket trust r{m,}"
    assert_verdict "docket trus{t,} add erik key" executor-write DENY \
        "brace-split trust word: docket trus{t,} add"
    assert_verdict "docket trust add{,} erik key" executor-write DENY \
        "brace-split verb, alternative at the end: docket trust add{,}"
    # A ${...} parameter expansion is not brace alternation: the same
    # accepted residual as a bare $V (an interpreter/verb reached through a
    # variable, which this pass already declines to resolve), so it must
    # not be caught by the brace check above.
    assert_verdict 'docket trust ${V} erik key' executor-write ALLOW \
        'docket trust ${V} computed verb: a parameter expansion, not a brace alternation'
    assert_verdict "docket {trust,} add erik key" executor-write DENY \
        "brace alternation in the trust position: docket {trust,} add"
    # The pre-pass splits a source word at its embedded quotes, so a quoted
    # alternative must not hide the comma from the brace test.
    assert_verdict "docket {\"trust\",add} erik key" executor-write DENY \
        "brace word split at embedded double quotes: docket {\"trust\",add}"
    assert_verdict "docket {'trust',} add erik key" executor-write DENY \
        "brace word split at embedded single quotes: docket {'trust',} add"
    assert_verdict "docket {trust,add} erik key" executor-write DENY \
        "one brace word expanding to trust and the verb: docket {trust,add}"
    assert_verdict "docket tru{s..s}t add erik key" executor-write DENY \
        "sequence expression, no comma: docket tru{s..s}t add"
    assert_verdict "bash -c 'docket {trust,} add erik key'" executor-write DENY \
        "brace alternation inside an interpreter's code argument"
    assert_verdict '"docket" "{trust,}" "add" erik key' executor-write DENY \
        "separately quoted brace word: different quote groups keep the DENY"
    assert_verdict "cat <<'EOF' | sh"$'\n''docket {trust,} add erik key'$'\nEOF' \
        executor-write DENY "brace alternation in a quoted heredoc piped to sh"
}

# ---- MUST DENY: a brace word in command position that spells docket -------
#
# The matcher enters only on a word that already reads `docket`, so a brace
# word bash expands INTO `docket` and the words after it was never tested:
# `{docket,trust} add erik key` dispatches the full write. Outside command
# position a brace word is an ordinary argument (`mkdir -p src/{a,b}`), and
# one whose text cannot hold the letters of docket in order cannot produce
# it, so both stay allowed.

case_command_position_brace_denies() {
    assert_verdict "{docket,trust} add erik key" executor-write DENY \
        "command-position brace word expanding to docket and trust"
    assert_verdict "{docket,} trust add erik key" executor-write DENY \
        "command-position brace word with an empty alternative"
    assert_verdict "{docket,trust} add erik key" docket-conductor-RUN-1 DENY \
        "conductor: command-position brace word"
    assert_verdict "{docket,trust,add,erik,key}" executor-write DENY \
        "one brace word carrying the whole invocation"
    assert_verdict "{docke,trus}t add erik key" executor-write DENY \
        "brace word with a shared suffix"
    assert_verdict "FOO=1 {docket,trust} add erik key" executor-write DENY \
        "brace word after an assignment prefix"
    assert_verdict 'FOO="a b" {docket,trust} add erik key' executor-write DENY \
        "brace word after a quoted assignment prefix"
    assert_verdict "coproc {docket,trust} add erik key" executor-write DENY \
        "brace word after the reserved word coproc"
    assert_verdict "2>/dev/null {docket,trust} add erik key" executor-write DENY \
        "brace word after a leading redirection"
    assert_verdict "cd /x && {docket,trust} add erik key" executor-write DENY \
        "brace word after a standalone &&"
    assert_verdict "cd /x;{docket,trust} add erik key" executor-write DENY \
        "brace word glued onto a ;"
    assert_verdict "{docket,'trust'} add erik key" executor-write DENY \
        "brace word split at embedded single quotes"
    assert_verdict '{"docket",trust} add erik key' executor-write DENY \
        "brace word whose first alternative is double-quoted"
    assert_verdict '""{docket,trust} add erik key' executor-write DENY \
        "brace word behind an empty quoted prefix"
    assert_verdict "cat <<'EOF' | sh"$'\n''{docket,trust} add erik key'$'\nEOF' \
        executor-write DENY "command-position brace word in a quoted heredoc piped to sh"
    # Accepted false DENY: this expands to two command words and writes
    # nothing, but it holds an expandable brace that spells docket.
    assert_verdict "d{o,}cket trust add erik key" executor-write DENY \
        "accepted false DENY: d{o,}cket expands to two command words"
    assert_verdict "{docket,trust} add erik key" "" ALLOW \
        "no agent_type (main conversation): command-position brace word"
    assert_verdict "{docket,trust} rm erik" executor-write DENY \
        "command-position brace word ahead of the rm verb"
    # A wrapper launches the brace word, so the call is read unquoted and the
    # brace word is tested as a command word.
    assert_verdict "env {docket,trust} add erik key" executor-write DENY \
        "brace word launched by env"
    assert_verdict "env -u {x,docket} trust add erik key" executor-write DENY \
        "brace word behind env -u, whose option takes the first alternative"
    assert_verdict "timeout 5 {docket,trust} add erik key" executor-write DENY \
        "brace word launched by timeout"
}

# A redirection may stand anywhere in a simple command, so one between the
# brace word and the verb leaves the verb in the same command. Operators that
# carry & or | (2>&1, &>, >|) are redirections too, not command separators.
case_brace_redirection_before_verb_denies() {
    assert_verdict "{docket,trust} >/dev/null add erik key" executor-write DENY \
        "redirection between the brace word and add"
    assert_verdict "{docket,trust} 2>&1 rm erik" executor-write DENY \
        "fd duplication between the brace word and rm"
    assert_verdict "{docket,trust} </dev/null add erik key" executor-write DENY \
        "input redirection between the brace word and add"
    assert_verdict "{docket,trust} >/dev/null add erik key" docket-conductor-RUN-1 DENY \
        "conductor: redirection between the brace word and add"
    assert_verdict "{docket,} 2>/dev/null trust add erik key" executor-write DENY \
        "redirection between a docket-only brace word and trust"
    assert_verdict "env {docket,trust} >/dev/null add erik key" executor-write DENY \
        "launched brace word with a redirection before add"
    assert_verdict "{docket,trust} &>/dev/null add erik key" executor-write DENY \
        "&> redirection between the brace word and add"
    assert_verdict "{docket,trust} >|/tmp/x add erik key" executor-write DENY \
        ">| redirection between the brace word and add"
    assert_verdict "{docket,trust} <<<x add erik key" executor-write DENY \
        "here-string between the brace word and add"
    assert_verdict "bash -c '{docket,trust} >/dev/null add erik key'" executor-write DENY \
        "bash -c running a brace word with a redirection before add"
}

# The span still ends where the command does, so letters after a ; or | are
# not read as the brace word's verb.
case_brace_redirection_command_end_allows() {
    assert_verdict "{docket,trust} list >/dev/null" executor-write ALLOW \
        "brace word with a read verb and a trailing redirection"
    assert_verdict "{docket,trust} >/dev/null; echo add" executor-write ALLOW \
        "verb letters in the next command after ;"
    assert_verdict "{docket,trust} 2>/dev/null|cat" executor-write ALLOW \
        "a pipe after the redirection ends the command"
}

# zsh, the Bash tool's shell here, runs `noglob`, `nocorrect`, `-` and
# `repeat N` as precommand modifiers and still brace-expands the word after
# them, so that word keeps command position. The plain spellings deny through
# the docket head check, which runs at every word.
case_zsh_modifier_brace_denies() {
    assert_verdict "noglob {docket,trust} add erik key" executor-write DENY \
        "brace word after the zsh modifier noglob"
    assert_verdict "nocorrect {docket,trust} add erik key" executor-write DENY \
        "brace word after the zsh modifier nocorrect"
    assert_verdict "- {docket,trust} add erik key" executor-write DENY \
        "brace word after the zsh modifier -"
    assert_verdict "repeat 1 {docket,trust} add erik key" executor-write DENY \
        "brace word after a zsh repeat count"
    assert_verdict "noglob docket trust add erik key" executor-write DENY \
        "plain spelling after noglob"
    assert_verdict "nocorrect docket trust rm erik key" executor-write DENY \
        "plain spelling after nocorrect"
    assert_verdict "- docket trust add erik key" executor-write DENY \
        "plain spelling after the zsh modifier -"
    assert_verdict "repeat 1 docket trust add erik key" executor-write DENY \
        "plain spelling after a zsh repeat count"
    # Accepted false DENY: the pre-pass may split a repeat count into several
    # words, so every later word of the leaf is read as command position.
    assert_verdict "repeat 2 echo {docket,trust} add" executor-write DENY \
        "accepted false DENY: brace argument after a repeat count"
}

case_zsh_modifier_brace_allows() {
    assert_verdict "noglob echo {docket,trust} add" executor-write ALLOW \
        "brace word as an argument behind noglob"
    assert_verdict "noglob ls" executor-write ALLOW \
        "noglob in front of a non-docket command"
    assert_verdict "repeat 2 echo hi && echo {docket,trust} add" executor-write ALLOW \
        "a standalone operator ends the repeat command"
}

# A command that starts with `-` (the zsh precommand modifier) keeps command
# position for the next word. These rows pin that a plain one allows, and a
# trust-store write behind it denies with the trust-store reason.
case_leading_dash_command() {
    assert_verdict "- ls" executor-write ALLOW \
        "leading-dash command with no docket word"
    assert_verdict "- docket trust add erik key" executor-write DENY \
        "trust-store write behind a leading -"
    assert_deny_reason "- docket trust add erik key" executor-write \
        "trust-store write behind a leading -"
}

case_command_position_brace_allows() {
    # bash expands no quoted brace, so this runs a literal command that does
    # not exist; the quoted word is no inert command either, so the text is
    # read unquoted and the brace rule denies it. A false DENY of nothing.
    assert_verdict "'{docket,trust}' add erik key" executor-write DENY \
        "quoted command-position brace word: not inert, so read unquoted"
    assert_verdict "{docket} trust add erik key" executor-write ALLOW \
        "command-position brace with no , or ..: bash leaves it literal"
    assert_verdict "mkdir -p src/{a,b}" executor-write ALLOW \
        "brace word in argument position"
    assert_verdict "cp f{,.bak}" executor-write ALLOW \
        "brace word with an empty alternative in argument position"
    assert_verdict "ls tests/{docket-trust,docket-commit}-guard-hook.test.sh" executor-write ALLOW \
        "argument brace word naming docket paths"
    assert_verdict "{ echo a,b; }" executor-write ALLOW \
        "group command: the reserved word { is not a brace"
    assert_verdict "{ docket issue list; } | jq -r '.a, .b'" executor-write ALLOW \
        "group command around a docket read, with a comma later on the line"
    assert_verdict "cat > f.json <<EOF"$'\n''{"a":1,"b":2}'$'\nEOF' executor-write ALLOW \
        "JSON body line of an unquoted heredoc"
    # The rule denies a brace only when the letters of a trust write follow
    # it; a comma brace whose later letters spell docket alone dispatches
    # nothing. xargs and bash make these calls active, read unquoted.
    assert_verdict "jq -n '{id:1, doc:\"locked set\"}' | xargs echo" executor-write ALLOW \
        "comma brace spelling only docket, in an active call"
    assert_verdict "jq -n --arg a b '{id:1, doc:\"locked set\"}' > \$TMPDIR/x.json; bash --version" \
        executor-write ALLOW "jq payload with a comma brace spelling only docket, beside bash"
}

# ---- A backslash-newline joins two lines into one ------------------------
#
# The shell removes a backslash-newline, so a continuation line is an
# argument of the line before it, never a command of its own, and a word
# split across the join is one word. An escaped backslash at a line end, a
# backslash inside quotes before the line end, and one in a comment or a
# quoted heredoc body join nothing.

case_backslash_continuation() {
    local nl=$'\n' inv="docket trust add erik key" multi
    multi="jq -n \\${nl}--arg a b \\${nl}'{id:1, doc:\"locked set\"}' > \$TMPDIR/x.json"
    assert_verdict "$multi" executor-write ALLOW \
        "jq payload continued over three lines"
    assert_verdict "jq -n --arg a b '{id:1, doc:\"locked set\"}' > \$TMPDIR/x.json" executor-write ALLOW \
        "the same jq payload on one line"
    # Read as separate lines, `--arg` is a command word, which makes the call
    # active and its quoted prose code.
    assert_verdict "jq -n \\${nl}--arg a b \\${nl}'{\"note\":\"never run ${inv}\"}' > \$TMPDIR/x.json" \
        executor-write ALLOW "jq payload naming the verb in prose, continued over three lines"
    assert_verdict "jq -n --arg a b '{\"note\":\"never run ${inv}\"}' > \$TMPDIR/x.json" \
        executor-write ALLOW "the same jq payload naming the verb, on one line"
    assert_verdict "echo \\${nl}'${inv}'" executor-write ALLOW \
        "quoted prose on a continuation line of an inert call"
    assert_verdict "docket \\${nl}trust add erik key" executor-write DENY \
        "continuation between docket and trust"
    assert_verdict "docket trust \\${nl}add erik key" executor-write DENY \
        "continuation between trust and the verb"
    assert_verdict "doc\\${nl}ket trust add erik key" executor-write DENY \
        "continuation inside the docket word"
    assert_verdict "docket tr\\${nl}ust add erik key" executor-write DENY \
        "continuation inside the trust word"
    assert_verdict "echo a\\\\${nl}sh -s <<< '${inv}'" executor-write DENY \
        "escaped backslash at a line end joins nothing"
    assert_verdict "echo x'a\\'${nl}sh -s <<< '${inv}'" executor-write DENY \
        "single-quoted backslash glued before the line end joins nothing"
    assert_verdict "echo hi # \\${nl}sh -s <<< '${inv}'" executor-write DENY \
        "backslash ending a comment joins nothing"
    assert_verdict "cat > f <<'EOF'${nl}x\\${nl}EOF${nl}sh -s <<< '${inv}'" executor-write DENY \
        "backslash ending a quoted heredoc body line joins nothing"
    assert_verdict "cat > f <<'EOF' \\${nl}; sh -s <<< '${inv}'${nl}body${nl}EOF" executor-write DENY \
        "continued heredoc operator line"
}

# ---- MUST NOT CATCH: a brace bash never expands ---------------------------
#
# A findings note quoting stub output (`stub docket {"ok":false}`) holds a
# `{` after `docket` but no `,` or `..`, or holds it inside one quoted
# group, and bash brace-expands neither. Each row runs under both executor
# archetypes; with no agent_type the hook allows before the matcher runs.
# A quoted heredoc body is read only when the call is not inert, so the row
# that reads it carries an interpreter beside the heredoc (`&& bash
# --version`).

# The denied findings command itself: a findings heredoc whose body names an
# interpreter in prose and holds one apostrophe, then a multi-line jq
# program whose note uses '"'"' escapes and quotes stub output.
incident_findings_command() {
    cat <<'CMD'
cat > STEP-11188-findings.md <<'EOF'
# Findings
ran bash tests/docket-trust-guard-hook.test.sh: exit 0
the checkout's tests pass
EOF
jq -n '[
  {
    "id": "F-1",
    "note": "the implementer'"'"'s probe stub docket {\"ok\":false}: same, x",
    "n": 1
  }
]' > STEP-11188-findings.json
CMD
}

case_unexpandable_brace_prose_allows() {
    local agent incident
    incident=$(incident_findings_command)
    for agent in executor-read executor-write; do
        assert_verdict 'echo "stub docket {\"ok\":false}"' "$agent" ALLOW \
            "${agent}: double-quoted prose naming docket {...}"
        assert_verdict "cat > f.md <<'EOF'"$'\n''stub docket {"ok":false}'$'\nEOF' \
            "$agent" ALLOW "${agent}: quoted heredoc body naming docket {...}"
        assert_verdict "cat > f.md <<'EOF' && bash --version"$'\n''stub docket {"ok":false}'$'\nEOF' \
            "$agent" ALLOW "${agent}: widened quoted heredoc body naming docket {...}"
        # Accepted false deny: in an active call the text is read unquoted,
        # so a brace word after docket with a comma in it and a word after
        # it may expand, and the brace rule denies it.
        assert_verdict "cat > f.md <<'EOF' && bash --version"$'\n''stub docket {"ok":false,"n":1}: same'$'\nEOF' \
            "$agent" DENY "${agent}: accepted false deny: docket {...,...} in a body read unquoted"
        assert_verdict "$incident" "$agent" ALLOW \
            "${agent}: the denied findings command (body apostrophe, then a jq program naming docket {...} beside commas)"
        assert_verdict "echo 'docket trust ad{d,} erik key'" "$agent" ALLOW \
            "${agent}: one quoted group naming a brace-split verb"
    done
}

# ---- ACCEPTED RESIDUAL: a quoted brace group fed to an interpreter's stdin --
#
# The hook reads the outer line only. A quoted group piped or here-stringed
# into an interpreter reaches the child unexpanded, and the child runs it.
# The brace-free form is already ALLOW (AB-7), so the same-group exemption
# adds no reach; these rows pin that verdict in both directions. The DENY
# controls put the brace word in a different quote group from the head word
# (unquoted, then quoted), so a same-group test that stops comparing groups
# turns them red.

case_quoted_brace_interpreter_stdin_residual() {
    local agent
    for agent in executor-read executor-write; do
        assert_verdict "echo 'docket trus{t,} add erik key' | sh" "$agent" DENY \
            "${agent}: quoted brace trust word piped to sh (an interpreter reads the text unquoted)"
        assert_verdict "echo 'docket trust ad{d,} erik key' | bash" "$agent" DENY \
            "${agent}: quoted brace verb piped to bash (an interpreter reads the text unquoted)"
        assert_verdict "sh <<< 'docket trus{t,} add erik key'" "$agent" DENY \
            "${agent}: quoted brace trust word as a here-string to sh (an interpreter reads the text unquoted)"
        assert_verdict "bash <<< 'docket trust ad{d,} erik key'" "$agent" DENY \
            "${agent}: quoted brace verb as a here-string to bash (an interpreter reads the text unquoted)"
        assert_verdict "echo docket 'trus{t,}' add erik key | sh" "$agent" DENY \
            "${agent}: brace trust word in its own quote group, unquoted head"
        assert_verdict "echo 'docket' 'trus{t,}' add erik key | sh" "$agent" DENY \
            "${agent}: brace trust word in its own quote group, quoted head"
        assert_verdict "echo 'docket trust' 'ad{d,}' erik key | sh" "$agent" DENY \
            "${agent}: brace verb in its own quote group, quoted head"
    done
}

# ---- MUST DENY: the verb carried as an interpreter's code argument --------
#
# A quoted string is prose everywhere except one position: the code argument
# of an interpreter, where it is executed verbatim. Treating that position as
# prose let an executor write the trust store at the cost of one extra word.
# Both quote styles carry it, and the code flag may be bundled with other
# short flags (`-lc`), so each of those is its own row.

case_interpreter_code_argument_deny() {
    local inv='docket trust add erik ssh-ed25519 AAAA'
    assert_verdict "$inv" executor-write DENY \
        "bare invocation (positive control for this group)"
    assert_verdict "bash -c '${inv}'" executor-write DENY \
        "bash -c with a single-quoted code argument"
    assert_verdict "bash -c \"${inv}\"" executor-write DENY \
        "bash -c with a double-quoted code argument"
    assert_verdict "sh -c '${inv}'" executor-write DENY \
        "sh -c with a code argument"
    assert_verdict "bash -lc '${inv}'" executor-write DENY \
        "code flag bundled with another short flag (-lc)"
    assert_verdict "env bash -c '${inv}'" executor-write DENY \
        "interpreter behind an env pass-through"
    assert_verdict "/bin/bash -c '${inv}'" executor-write DENY \
        "pathed interpreter with a code argument"
    assert_verdict "python3 -c 'import os; os.system(\"${inv}\")'" executor-write DENY \
        "python3 -c: the verb inside a nested double-quoted string"
    assert_verdict "perl -e 'system(\"${inv}\")'" executor-write DENY \
        "perl -e code argument"
    assert_verdict "node -e 'require(\"child_process\").execSync(\"${inv}\")'" \
        executor-write DENY "node -e code argument"
    assert_deny_reason "bash -c '${inv}'" executor-write \
        "interpreter-carried invocation"
}

# ---- TABLE: every listed interpreter and every listed code flag denies ---
#
# Both lists live in the shared pre-pass (docket-guard-prepass.awk):
# is_interpreter()'s name list and code_argument()'s flag regex. Before this
# row, only a handful of each list's members were ever named in a
# `-c`/`bash`-shaped row above, so narrowing either regex to a fraction of
# its members left every existing row green (a fix round measured a
# narrowed flag regex and a narrowed interpreter regex both passing the
# suite unnoticed). Looping over the FULL lists here means a member
# deleted from either regex turns its own named row red rather than hiding
# behind rows that happen to use a different member.

case_full_interpreter_list_denies() {
    local inv='docket trust add erik key' interp
    for interp in sh bash dash zsh ksh mksh csh tcsh \
                  python python3 python3.11 perl ruby node nodejs php \
                  lua lua5.1 expect osascript; do
        assert_verdict "${interp} -c '${inv}'" executor-write DENY \
            "listed interpreter denies: ${interp} -c"
    done
}

case_full_code_flag_list_denies() {
    local inv='docket trust add erik key' flag
    for flag in -c -lc -alc -e -E -p -r --eval --print; do
        assert_verdict "bash ${flag} '${inv}'" executor-write DENY \
            "listed code flag denies: bash ${flag}"
    done
}

# ---- MUST DENY: the same call with the flag or interpreter spelled oddly --
#
# Quoting, escaping or splitting a word across a quote boundary changes what
# the hook's lexer sees and nothing about what bash executes: `bash "-"c` runs
# the code argument exactly as `bash -c` does. Every attack spelling below cost
# the attacker one pair of quotes and bought a trust-store write, so each is
# its own row. Single and double quotes are SEPARATE branches of the lexer, so
# a split word is pinned in both styles: with one style unpinned, a one-line
# regression in the other branch reopens the bypass with the suite green.
# The last two rows are the price of reading words as bash builds them: a word
# that decodes to a code flag or to an interpreter name without being meant as
# either. Pinned DENY as a decision, on this file's stated direction of a
# false DENY over a missed invocation.

case_code_flag_and_interpreter_spellings_deny() {
    local inv='docket trust add erik ssh-ed25519 AAAA'
    assert_verdict "$inv" executor-write DENY \
        "bare invocation (positive control for this group)"
    assert_verdict "bash '-c' '${inv}'" executor-write DENY \
        "single-quoted code flag"
    assert_verdict "bash \"-c\" '${inv}'" executor-write DENY \
        "double-quoted code flag"
    assert_verdict "bash -\"c\" '${inv}'" executor-write DENY \
        "code flag split across a quote boundary (-\"c\")"
    assert_verdict "bash \"-\"c '${inv}'" executor-write DENY \
        "code flag split across a quote boundary (\"-\"c)"
    assert_verdict "bash -'c' '${inv}'" executor-write DENY \
        "code flag split across a single-quote boundary (-'c')"
    assert_verdict "bash '-'c '${inv}'" executor-write DENY \
        "code flag split across a single-quote boundary ('-'c)"
    assert_verdict "bash \\-c '${inv}'" executor-write DENY \
        "backslash-escaped code flag"
    assert_verdict "bash \\"$'\n'"-c '${inv}'" executor-write DENY \
        "code flag reached across a line continuation"
    assert_verdict "'bash' -c '${inv}'" executor-write DENY \
        "single-quoted interpreter word"
    assert_verdict "\"bash\" -c '${inv}'" executor-write DENY \
        "double-quoted interpreter word"
    assert_verdict "ba\"sh\" -c '${inv}'" executor-write DENY \
        "interpreter word split across a quote boundary"
    assert_verdict "ba'sh' -c '${inv}'" executor-write DENY \
        "interpreter word split across a single-quote boundary"
    assert_verdict "/bin/ba'sh' -c '${inv}'" executor-write DENY \
        "pathed interpreter word split across a single-quote boundary"
    assert_verdict "\\bash -c '${inv}'" executor-write DENY \
        "backslash-escaped interpreter word"
    assert_verdict "bash script.sh '-c' 'the rule says docket trust add is reserved'" \
        executor-write DENY \
        "a quoted -c argv element of a script qualifies the next group as code"
    assert_verdict "grep 'sh' -c 'the rule says docket trust add is reserved' notes.md" \
        executor-write DENY \
        "a quoted data word decoding to an interpreter name qualifies the next group as code"
}

# ---- ACCEPTED: prose naming the verb, carried inside a code argument ------
#
# The code-argument rule reads a whole quoted code argument unmarked, so
# prose that merely NAMES "docket trust add/rm" there (a replacement string,
# a logged sentence) denies exactly like a real invocation would — no
# invocation runs in either case below. Pinned DENY, not a miss: this file's
# stated direction for an unresolvable case is a false DENY over a missed
# invocation, and the deny message's escape hatch (Read/Grep, or write the
# prose to a file) is how a step recovers from it.

case_interpreter_code_argument_prose_deny() {
    assert_verdict "perl -pi -e 's/old/docket trust add is reserved/' notes.md" \
        executor-write DENY \
        "perl -pi -e: a substitution naming the verb as replacement text, no invocation"
    assert_verdict "node -e 'console.log(\"never run docket trust add here\")'" \
        executor-write DENY \
        "node -e: a logged sentence naming the verb, no invocation"
    assert_deny_reason "node -e 'console.log(\"never run docket trust add here\")'" \
        executor-write "prose-in-code-argument escape hatch is named"
}

# ---- MUST NOT CATCH: the false-DENY floor ---------------------------------
#
# Quoted text is read unquoted whenever a command outside the inert set is
# in the call, and that reading finds only the three words: an interpreter
# given a script path, a code argument with no guarded verb in it, and prose
# quoted beside an inert command all keep their ALLOW.

case_interpreter_code_argument_allows() {
    assert_verdict "bash -c 'echo hi'" executor-write ALLOW \
        "code argument naming no guarded verb"
    assert_verdict "bash script.sh" executor-write ALLOW \
        "interpreter given a script path, no code flag"
    assert_verdict 'docket issue comment add D-1 -m "never run docket trust add"' \
        executor-write ALLOW "prose after -m stays prose (no code flag)"
    assert_verdict "echo 'never run docket trust add here'" executor-write ALLOW \
        "prose quoted after a non-interpreter word"
    # The look-behind must not cross a leaf boundary: the words that end one
    # leaf cannot qualify a quoted group that opens the next one.
    assert_verdict "echo bash -c"$'\n'"echo 'the rule says docket trust add is reserved'" \
        executor-write ALLOW "a code flag ending one leaf does not reach the next leaf's quotes"
}

# ---- CARRIERS WITHOUT A CODE FLAG, and the one residual left ---------------
#
# A carrier with no code flag (awk, ssh), and a flag or an interpreter that
# only exists after an expansion, all deny: each names a command outside the
# inert set, so the quoted text is read as the words it holds. The pre-pass
# comment in the hook states the same. The one residual is a verb reached
# through a variable, which leaves no literal run of the three words.

case_interpreter_carriers_residual_allow() {
    local inv='docket trust add erik key'
    assert_verdict "awk 'BEGIN { system(\"${inv}\") }'" executor-write DENY \
        "awk program text: no code flag, read unquoted"
    assert_verdict "ssh host '${inv}'" executor-write DENY \
        "ssh remote command: no code flag, read unquoted"
    assert_verdict "C=\"${inv}\"; bash -c \"\$C\"" executor-write DENY \
        "verb assigned in a quoted value, then handed to an interpreter"
    assert_verdict "C=\"${inv}\"; echo \"\$C\"" executor-write ALLOW \
        "verb assigned in a quoted value beside echo alone"
    assert_verdict "C=\"trust add erik key\"; docket \$C" executor-write ALLOW \
        "verb reached through a variable (accepted residual: the sandbox refuses the write)"
    assert_verdict "F=-c; bash \$F '${inv}'" executor-write DENY \
        "code flag reached through a variable, read unquoted"
    assert_verdict "I=bash; \$I -c '${inv}'" executor-write DENY \
        "interpreter reached through a variable, read unquoted"
    assert_verdict "bash \$(printf -- -c) '${inv}'" executor-write DENY \
        "code flag reached through a substitution, read unquoted"
}

# ---- MUST ALLOW: the help read, the one exemption, from an executor -------
#
# `docket trust add --help` opens nothing. The exemption is exactly: an
# unquoted, bare `-h`/`--help` as the word directly after a clean `add`/`rm`,
# with at most a shell operator glued onto its tail. The originating shape
# piped the help text into grep, so operators and redirects after the flag
# must not defeat it.

case_help_read_exemption_allows() {
    assert_verdict "docket trust add --help" executor-read ALLOW \
        "executor-read: docket trust add --help"
    assert_verdict "docket trust add -h" executor-read ALLOW \
        "executor-read: docket trust add -h"
    assert_verdict "docket trust rm --help" executor-read ALLOW \
        "executor-read: docket trust rm --help"
    assert_verdict "docket trust rm -h" executor-write ALLOW \
        "executor-write: docket trust rm -h"
    assert_verdict "docket trust add --help 2>&1 | grep -n -i -E 'stub|reason' | head -20" \
        executor-read ALLOW "help piped into grep (the originating shape)"
    assert_verdict "docket trust add --help; echo done" executor-read ALLOW \
        "help with ; glued onto the flag"
    assert_verdict "(docket trust add --help)" executor-read ALLOW \
        "help inside a subshell, ) glued onto the flag"
    assert_verdict "cd /x && docket trust add --help" executor-read ALLOW \
        "help after &&"
    assert_verdict "docket trust add --help >/dev/null 2>&1" executor-read ALLOW \
        "help followed by redirects"
    assert_verdict "/usr/local/bin/docket trust add --help" executor-research ALLOW \
        "help via absolute path to docket binary"
}

# ---- MUST DENY: help lookalikes and help-then-write compounds -------------
#
# Every shape here either is a write or cannot be told from one without
# modelling the CLI: a second occurrence after the exempted one, a flag that
# turns help OFF (`--help=false`), `--help` as an argv element after `--`, a
# help flag in any position other than directly after the verb (where an
# earlier option could swallow it as a value), or a quoted flag.

case_help_lookalikes_and_compounds_deny() {
    assert_verdict "docket trust add foo --yes -- /bin/sh -c 'x'" executor-read DENY \
        "executor-read: real add with argv"
    assert_deny_reason "docket trust add foo --yes -- /bin/sh -c 'x'" executor-read \
        "executor-read: real add with argv"
    assert_verdict "docket trust add --help && docket trust add foo --yes -- /bin/sh -c 'x'" \
        executor-read DENY "help then a real add after && (scan continues past the exemption)"
    assert_verdict "docket trust add --help; docket trust add erik -- /bin/sh -c 'x'" \
        executor-read DENY "help then a real add after ;"
    assert_verdict $'docket trust add --help\ndocket trust add erik -- /bin/sh -c x' \
        executor-read DENY "help then a real add on the next line"
    assert_verdict 'docket trust add --help $(docket trust add erik -- /bin/sh -c x)' \
        executor-read DENY "help with a real add inside a command substitution"
    assert_verdict "docket trust add --help=false erik -- /bin/sh -c 'x'" executor-read DENY \
        "--help=false turns the flag off: a real add"
    assert_verdict "docket trust add -h=false erik -- /bin/sh -c 'x'" executor-read DENY \
        "-h=false turns the flag off: a real add"
    assert_verdict "docket trust add -- --help" executor-read DENY \
        "--help after -- is a positional, not the flag"
    assert_verdict "docket trust add erik -- --help" executor-read DENY \
        "--help as an argv element of a real add"
    assert_verdict "docket trust add --timeout --help erik -- /bin/sh -c 'x'" executor-read DENY \
        "--help swallowed as the value of --timeout"
    assert_verdict "docket trust add erik --help" executor-read DENY \
        "help not directly after the verb: outside the exemption by design"
    assert_verdict 'docket trust add "--help"' executor-read DENY \
        "quoted help flag: outside the exemption by design"
}

# ---- HEREDOC BODIES: a quoted delimiter makes the body prose ---------------
#
# `cat > f <<'EOF'` cannot expand or execute anything in its body, so a body
# that names the guarded verb is prose - exactly the case the quote-aware
# pre-pass exists to distinguish, on an input shape it did not cover. An
# unquoted delimiter (`<<EOF`) does expand, so its body keeps reaching the
# matcher unmarked and a real invocation there still denies.

# An executor-read seat writes its payload into its own step dir through a
# quoted heredoc; a body naming the guarded verb is data. The same body piped
# into an interpreter, or written beside one, runs or may run.
case_executor_read_payload_heredoc() {
    local body='docket trust add erik key'
    assert_verdict "cat > \"\$TMPDIR/STEP-7.d/STEP-7-payload.json\" <<'EOF'"$'\n'"${body}"$'\nEOF' \
        executor-read ALLOW "executor-read payload written by cat from a quoted heredoc"
    assert_verdict "jq -c . > \"\$TMPDIR/STEP-7.d/STEP-7-payload.json\" <<'EOF'"$'\n'"${body}"$'\nEOF' \
        executor-read ALLOW "executor-read payload written by jq from a quoted heredoc"
    local agent
    for agent in executor-read executor-write; do
        assert_verdict "cat <<'EOF' | bash"$'\n'"${body}"$'\nEOF' \
            "$agent" DENY "$agent: quoted heredoc piped into bash"
        assert_verdict "$body" "$agent" DENY "$agent: bare trust-store write"
    done
    assert_verdict "cat > \"\$TMPDIR/STEP-7.d/p.json\" <<'EOF' && python3 --version"$'\n'"${body}"$'\nEOF' \
        executor-read DENY "quoted heredoc body beside an interpreter on another leaf"
}

case_heredoc_body_prose() {
    local prose='the rule says docket trust add is operator-reserved'
    assert_verdict "cat > \"\$TMPDIR/f.txt\" <<'EOF'"$'\n'"${prose}"$'\nEOF' \
        executor-write ALLOW "single-quoted heredoc delimiter: body is prose"
    assert_verdict "cat > \"\$TMPDIR/f.txt\" <<\"EOF\""$'\n'"${prose}"$'\nEOF' \
        executor-write ALLOW "double-quoted heredoc delimiter: body is prose"
    assert_verdict "cat > \"\$TMPDIR/f.txt\" <<\\EOF"$'\n'"${prose}"$'\nEOF' \
        executor-write ALLOW "backslash-quoted heredoc delimiter: body is prose"
    assert_verdict "cat > \"\$TMPDIR/f.txt\" <<-'EOF'"$'\n\t'"${prose}"$'\n\tEOF' \
        executor-write ALLOW "tab-stripping quoted heredoc delimiter: body is prose"
    assert_verdict "cat > \"\$TMPDIR/f.txt\" <<'EOF'"$'\n'"${prose}"$'\nEOF\ndocket trust add erik key' \
        executor-write DENY "real invocation on the line after a quoted heredoc ends"
    assert_verdict "cat > \"\$TMPDIR/f.txt\" <<EOF"$'\n''docket trust add erik key'$'\nEOF' \
        executor-write DENY "unquoted heredoc delimiter: body still reaches the matcher"
    assert_verdict "cat > \"\$TMPDIR/f.txt\" <<'EOF'"$'\n\tEOF\n''docket trust add erik key'$'\nEOF' \
        executor-write ALLOW "tab-indented EOF does not end a plain quoted heredoc body"
    # The body ends at its own newline, not at a space: a body whose last word
    # is `docket` must not merge with the words on the line after the
    # terminator into one record the matcher reads as an invocation.
    assert_verdict "cat > \"\$TMPDIR/f.txt\" <<'EOF'"$'\n''the rule names docket'$'\nEOF\ntrust add erik key' \
        executor-write ALLOW "a quoted heredoc body ends at its own line, not at the next one"
    # Cross-line state must not survive the construct that set it: each of
    # these opens a real heredoc AFTER a construct the pre-pass tracks.
    assert_verdict "# a note"$'\n'"cat > \"\$TMPDIR/f.txt\" <<'EOF'"$'\n'"${prose}"$'\nEOF' \
        executor-write ALLOW "a comment on the line before does not disarm the heredoc after it"
    assert_verdict 'n=$((1 << 3))'$'\n'"cat > \"\$TMPDIR/f.txt\" <<'EOF'"$'\n'"${prose}"$'\nEOF' \
        executor-write ALLOW "an arithmetic expansion closes, so the heredoc after it still opens"
    assert_verdict "cat > notes#1.txt <<'EOF'"$'\n'"${prose}"$'\nEOF' \
        executor-write ALLOW "a # inside an unquoted word is not a comment, so the heredoc still opens"
}

# An interpreter beside the heredoc makes the call active, so the body is
# read unquoted and its prose reaches the brace check. Only the brace word
# itself can spell docket: letters in the words after it never join it.
case_widened_body_brace_prose() {
    local body='`/bin/bash `{tool_name:"Bash",tool_input:{command},agent_type:"executor-write",cwd:<scratch>}` unknown; does not'
    assert_verdict "cat > /tmp/claude-501/x.md <<'EOF' && bash --version"$'\n'"${body}"$'\nEOF' \
        executor-read ALLOW "widened artifact body: backtick-quoted harness argv is prose"
    assert_verdict "cat <<'EOF' | bash"$'\n''`{docket,trust} add erik key`'$'\nEOF' \
        executor-write DENY "a body bash runs still denies a brace word in a substitution"
}

# An executor's own scratch artifact names the trust verbs in prose. A word
# inside a quoted heredoc body is data, so an interpreter name there (a gate
# table row reading `bash gate script`) must not make the call active; an
# interpreter in command position does, wherever it sits in the call. A real
# invocation keeps its deny and reason, and a help read stays allowed.
case_scratch_prose_names_trust_verbs() {
    local file='"$TMPDIR/STEP-N.d/STEP-N-findings.md"'
    local summary='"$TMPDIR/STEP-N.d/STEP-N-change-summary.md"'
    local prose='the refusal named docket trust add and docket trust rm as operator-reserved'
    local inv='docket trust add erik key'
    assert_verdict "cat >> ${file} <<'EOF'"$'\n'"${prose}"$'\nEOF' \
        executor-write ALLOW "AC-1: quoted heredoc append to own scratch names both trust verbs"
    assert_verdict "cat >> ${summary} <<'EOF'"$'\n'"${prose}"$'\n''| tests | bash gate script | 0 |'$'\nEOF' \
        executor-write ALLOW "AC-5: interpreter word only inside a quoted heredoc body does not widen"
    assert_verdict "docket trust add erik ssh-ed25519 AAAA" executor-write DENY \
        "AC-2: direct docket trust add"
    assert_deny_reason "docket trust add erik ssh-ed25519 AAAA" executor-write \
        "AC-2: direct docket trust add"
    assert_verdict "docket trust rm erik" executor-write DENY \
        "AC-2: direct docket trust rm"
    assert_deny_reason "docket trust rm erik" executor-write \
        "AC-2: direct docket trust rm"
    assert_verdict "docket trust add --help" executor-write ALLOW \
        "AC-2: docket trust add --help read"
    assert_verdict "docket trust rm -h" executor-write ALLOW \
        "AC-2: docket trust rm -h read"
    assert_verdict "cat <<'EOF' | sh"$'\n'"${inv}"$'\nEOF' \
        executor-write DENY "AC-3: quoted heredoc body piped into sh"
    assert_verdict "cat <<'EOF' | bash"$'\n''docket trust rm erik'$'\nEOF' \
        executor-write DENY "AC-3: quoted heredoc body piped into bash"
    assert_verdict "cat <<'EOF' | exec -a 'x"$'\n'"' sh"$'\n'"${inv}"$'\nEOF' \
        executor-write DENY "interpreter on a later code line of its leaf still widens"
}

# ---- HEREDOC DESTINATION: a quoted delimiter is inert only to THIS shell ----
#
# `<<'EOF'` stops the OUTER shell expanding the body; it says nothing about
# what reads it. `cat` writes the body to a file, so the body is data. `bash`
# runs it as a script, so the body is code and a guarded invocation in it
# executes. Only a text sink gets its body marked as prose.

case_heredoc_body_destination() {
    local inv='docket trust add erik key'
    assert_verdict "bash <<'EOF'"$'\n'"${inv}"$'\nEOF' \
        executor-write DENY "quoted heredoc fed to bash: the inner shell runs the body"
    assert_verdict "sh <<'X'"$'\n'"${inv}"$'\nX' \
        executor-write DENY "quoted heredoc fed to sh: the inner shell runs the body"
    assert_verdict "/bin/bash <<'EOF'"$'\n'"${inv}"$'\nEOF' \
        executor-write DENY "quoted heredoc fed to a pathed interpreter"
    assert_verdict "tee \"\$TMPDIR/f.txt\" <<'EOF'"$'\n'"the rule says ${inv} is operator-reserved"$'\nEOF' \
        executor-write ALLOW "quoted heredoc fed to tee: body is prose"
    # A file extension is not an interpreter: a target named cases.sh or
    # .env once widened the whole command on its own suffix.
    assert_verdict "cat > \"\$TMPDIR/probe/cases.sh\" <<'EOF'"$'\n'"${inv}"$'\nEOF' \
        executor-write ALLOW "quoted heredoc to a .sh target: body is data"
    assert_verdict "cat > \"\$TMPDIR/probe/.env\" <<'EOF'"$'\n'"${inv}"$'\nEOF' \
        executor-write ALLOW "quoted heredoc to a .env target: body is data"
    assert_verdict "\"sh\" <<'EOF'"$'\n'"${inv}"$'\nEOF' \
        executor-write DENY "quoted heredoc fed to a double-quoted sh"
    assert_verdict "'/bin/sh' <<'EOF'"$'\n'"${inv}"$'\nEOF' \
        executor-write DENY "quoted heredoc fed to a single-quoted pathed sh"
    assert_verdict "x=\$(sh <<'EOF'"$'\n'"${inv}"$'\nEOF\n)' \
        executor-write DENY "quoted heredoc fed to sh inside an assignment's substitution"
    assert_verdict "x=\`sh <<'EOF'"$'\n'"${inv}"$'\nEOF\n`' \
        executor-write DENY "quoted heredoc fed to sh inside an assignment's backticks"
}

# ---- WRITE THEN RUN: a body written to a file is code once a file runs -------
#
# A quoted delimiter keeps the body from this shell only. When any command
# in the same call is outside the inert set (a path run, `.`/`source`, a
# launcher, make, find), the written body may be what runs, whatever its own
# words say, so the whole call is read unquoted. A write with no run stays
# data.
case_heredoc_written_then_run() {
    local write="cat > \"\$TMPDIR/x\" <<'EOF'"$'\n''docket trust add erik key'$'\nEOF'
    local prose="cat > \"\$TMPDIR/x\" <<'EOF'"$'\n''the rule says docket trust add is operator-reserved'$'\nEOF'
    assert_verdict "${write}"$'\n''chmod +x "$TMPDIR/x" && "$TMPDIR/x"' \
        executor-write DENY "AC-1: quoted heredoc written to a file, then executed by path"
    assert_verdict "${write}"$'\n''. "$TMPDIR/x"' \
        executor-write DENY "AC-2: quoted heredoc written to a file, then sourced with ."
    assert_verdict "${write}" \
        executor-write ALLOW "AC-3: quoted heredoc written to a file with no later run"
    assert_verdict "${write}"$'\n''source "$TMPDIR/x"' \
        executor-write DENY "written file sourced with source"
    assert_verdict "${write}"$'\n''cd "$TMPDIR" && chmod +x x && ./x' \
        executor-write DENY "written file executed by a relative path"
    assert_verdict "${write}"$'\n''exec "$TMPDIR/x"' \
        executor-write DENY "written file executed through exec"
    assert_verdict "${write}"$'\n''command "$TMPDIR/x"' \
        executor-write DENY "written file executed through command"
    assert_verdict "${write}"$'\n''builtin . "$TMPDIR/x"' \
        executor-write DENY "written file sourced through builtin"
    assert_verdict "${write}"$'\n''f="$TMPDIR/x"; $f' \
        executor-write DENY "written file executed through a computed command word"
    assert_verdict "${write}"$'\n''cp "$TMPDIR/x" "$TMPDIR/y" && "$TMPDIR/y"' \
        executor-write DENY "written file copied, then the copy executed"
    assert_verdict "${write}"$'\n''nohup "$TMPDIR/x"' \
        executor-write DENY "written file executed through nohup"
    assert_verdict "${write}"$'\n''xargs -I{} {} <<< "$TMPDIR/x"' \
        executor-write DENY "written file executed through xargs"
    assert_verdict "${write}"$'\n''find "$TMPDIR" -name x -exec {} \;' \
        executor-write DENY "written file executed through find -exec"
    assert_verdict "${prose}"$'\n''make -C "$TMPDIR" test' \
        executor-write DENY "prose heredoc written beside make, which reads a Makefile"
    assert_verdict "${prose}"$'\n''find "$TMPDIR" -name x' \
        executor-write DENY "prose heredoc written beside find, which is not inert"
    assert_verdict "dir=\"\$TMPDIR/out\""$'\n'"${prose}" \
        executor-write ALLOW "prose heredoc written beside an assignment of a path"
    assert_verdict "command -v jq"$'\n'"${prose}" \
        executor-write ALLOW "prose heredoc written beside a command -v lookup"
}

# ---- SOURCE FROM STDIN: `.`/`source` run a quoted body with no file written --
#
# `source /dev/stdin <<'EOF'` reads its own heredoc as code, so the body is
# never data even though its delimiter is quoted. `.` and `source` are not
# inert, so the whole call is read unquoted, the piped form included.
case_heredoc_sourced_from_stdin() {
    local body=$'\n''docket trust add erik key'$'\nEOF'
    assert_verdict "source /dev/stdin <<'EOF'${body}" \
        executor-write DENY "AC-1: quoted heredoc sourced through /dev/stdin with source"
    assert_deny_reason "source /dev/stdin <<'EOF'${body}" \
        executor-write "AC-1: quoted heredoc sourced through /dev/stdin with source"
    assert_verdict ". /dev/stdin <<'EOF'${body}" \
        executor-write DENY "AC-2: quoted heredoc sourced through /dev/stdin with ."
    assert_verdict "cat > \"\$TMPDIR/notes\" <<'EOF'${body}" \
        executor-write ALLOW "AC-3: quoted heredoc naming the verb written to notes, nothing sourced"
    assert_verdict "cat <<'EOF' | source /dev/stdin${body}" \
        executor-write DENY "quoted heredoc piped into source /dev/stdin"
    assert_verdict "cat <<'EOF' | . /dev/stdin${body}" \
        executor-write DENY "quoted heredoc piped into . /dev/stdin"
    assert_verdict "builtin source /dev/stdin <<'EOF'${body}" \
        executor-write DENY "quoted heredoc sourced through builtin source"
    assert_verdict "command . /dev/stdin <<'EOF'${body}" \
        executor-write DENY "quoted heredoc sourced through command ."
    assert_verdict "'source' /dev/stdin <<'EOF'${body}" \
        executor-write DENY "quoted heredoc sourced through a quoted source word"
    assert_verdict "s\\ource /dev/stdin <<'EOF'${body}" \
        executor-write DENY "quoted heredoc sourced through a backslash-split source word"
}

# ---- INERT COMMANDS: the only shape whose quoted text is prose ----------------
#
# A quoted group or a quoted-delimiter heredoc body is data only while every
# command in the call is one that never runs its input or arguments as code
# (the hook's INERT_WORDS), the call branches on nothing, and PATH is not
# reassigned. Any other command word, however it is spelled or launched,
# makes the whole command text the scan, so a body written to a file and run
# by any means in the same call denies without the hook naming that means.
# Each DENY row below is one observed bypass of the earlier trigger lists; the
# ALLOW rows are the prose controls that keep the inert shape usable.
case_inert_commands_bound_the_prose_exemption() {
    local inv='docket trust add erik key'
    local write="cat > \"\$TMPDIR/x\" <<'EOF'"$'\n'"${inv}"$'\nEOF\n''chmod +x "$TMPDIR/x"'
    local notes="cat > \"\$TMPDIR/notes\" <<'EOF'"$'\n'"${inv}"$'\nEOF'
    local heredoc=$'\n'"${inv}"$'\nEOF'

    # A quoted argument written to a file, then run or sourced.
    assert_verdict "echo '${inv}' > \"\$TMPDIR/x\"; chmod +x \"\$TMPDIR/x\"; \"\$TMPDIR/x\"" \
        executor-write DENY "quoted argument written to a file, then run by path"
    assert_verdict "printf '${inv}\\n' > \"\$TMPDIR/x\"; . \"\$TMPDIR/x\"" \
        executor-write DENY "quoted argument written to a file, then sourced"
    assert_verdict "echo '${inv}' > \"\$TMPDIR/notes\"" \
        executor-write ALLOW "quoted argument written to notes, nothing run"

    # An interpreter name split by an in-word backslash or empty quotes.
    assert_verdict "cat <<'EOF' | b\\ash${heredoc}" \
        executor-write DENY "quoted heredoc piped into a backslash-split bash"
    assert_verdict "cat <<'EOF' | b''ash${heredoc}" \
        executor-write DENY "quoted heredoc piped into an empty-quote-split bash"
    assert_verdict "${notes}" \
        executor-write ALLOW "quoted heredoc naming the verb written to notes, no interpreter"

    # A leading assignment whose value holds a quoted or escaped blank.
    assert_verdict "${write}"$'\n''X="a b" "$TMPDIR/x"' \
        executor-write DENY "written file run by path behind an assignment with a quoted blank"
    assert_verdict "${write}"$'\n''X="a b" . "$TMPDIR/x"' \
        executor-write DENY "written file sourced behind an assignment with a quoted blank"
    assert_verdict "${write}"$'\n''X=a\ b "$TMPDIR/x"' \
        executor-write DENY "written file run by path behind an assignment with an escaped blank"
    assert_verdict "${notes}"$'\n''FOO="a b" echo hi' \
        executor-write ALLOW "notes written beside an assignment with a quoted blank before echo"
    assert_verdict "${write}"$'\n''X= "$TMPDIR/x"' \
        executor-write DENY "written file run as a quoted word after an empty assignment"
    assert_verdict "${write}"$'\n'"X= '\$TMPDIR/x'" \
        executor-write DENY "written file run as a single-quoted word after an empty assignment"

    # Launchers in front of a written path.
    assert_verdict "${write}"$'\n''timeout 5 "$TMPDIR/x"' \
        executor-write DENY "written file run through timeout"
    assert_verdict "${write}"$'\n''nice "$TMPDIR/x"' \
        executor-write DENY "written file run through nice"
    assert_verdict "${write}"$'\n''setsid "$TMPDIR/x"' \
        executor-write DENY "written file run through setsid"
    assert_verdict "${write}"$'\n''stdbuf -o0 "$TMPDIR/x"' \
        executor-write DENY "written file run through stdbuf with an option"
    assert_verdict "${write}"$'\n''sudo "$TMPDIR/x"' \
        executor-write DENY "written file run through sudo"
    assert_verdict "${write}"$'\n''time "$TMPDIR/x"' \
        executor-write DENY "written file run through time"
    assert_verdict "${write}"$'\n''caffeinate -i "$TMPDIR/x"' \
        executor-write DENY "written file run through a launcher no list names"
    assert_verdict "${notes}"$'\n''timeout 5 echo done' \
        executor-write ALLOW "notes written beside a launcher in front of an inert command"

    # Programs that read a written file as code.
    assert_verdict "cat > \"\$TMPDIR/Makefile\" <<'EOF'"$'\nall:\n\t'"${inv}"$'\nEOF\n''make -C "$TMPDIR"' \
        executor-write DENY "Makefile written, then run with make -C"
    assert_verdict "cat > \"\$TMPDIR/x\" <<'EOF'"$'\n'"BEGIN { system(\"${inv}\") }"$'\nEOF\n''awk -f "$TMPDIR/x"' \
        executor-write DENY "awk program written, then run with awk -f"
    assert_verdict "cat > \"\$TMPDIR/x\" <<'EOF'"$'\n'"s/^/x/e ${inv}"$'\nEOF\n''sed -f "$TMPDIR/x"' \
        executor-write DENY "sed script written, then run with sed -f"
    assert_verdict "${notes}"$'\n''make --version' \
        executor-write DENY "notes written beside make, which reads a Makefile from the directory"

    # hash -p binding a bare name to the written path.
    assert_verdict "${write}"$'\n''hash -p "$TMPDIR/x" t && t' \
        executor-write DENY "written file bound to a bare name with hash -p, then run"
    assert_verdict "${write}"$'\n''PATH="$TMPDIR:$PATH"; x' \
        executor-write DENY "written file reached through a PATH reassignment"

    # A heredoc on a compound command, whose body sits in no leaf.
    assert_verdict "{ source /dev/stdin; } <<'EOF'${heredoc}" \
        executor-write DENY "quoted heredoc sourced inside a brace group"
    assert_verdict "( . /dev/stdin ) <<'EOF'${heredoc}" \
        executor-write DENY "quoted heredoc sourced inside a subshell"
    assert_verdict "if source /dev/stdin; then :; fi <<'EOF'${heredoc}" \
        executor-write DENY "quoted heredoc sourced inside an if"
    assert_verdict "while . /dev/stdin; do break; done <<'EOF'${heredoc}" \
        executor-write DENY "quoted heredoc sourced inside a while loop"
    assert_verdict "{ sh; } <<'EOF'${heredoc}" \
        executor-write DENY "quoted heredoc fed to sh inside a brace group"
    assert_verdict "( bash ) <<'EOF'${heredoc}" \
        executor-write DENY "quoted heredoc fed to bash inside a subshell"
    assert_verdict "{ source /dev/stdin; } <<EOF${heredoc}" \
        executor-write DENY "unquoted heredoc sourced inside a brace group"
    assert_verdict "{ cat; } <<'EOF'${heredoc}" \
        executor-write ALLOW "quoted heredoc naming the verb fed to cat inside a brace group"

    # A branch, a loop or an or-list makes the whole text the scan.
    assert_verdict "${write}"$'\n''[ -x "$TMPDIR/x" ] && "$TMPDIR/x"' \
        executor-write DENY "written file run behind a file test"
    assert_verdict "${write}"$'\n''ls "$TMPDIR/none" || "$TMPDIR/x"' \
        executor-write DENY "written file run on the failing side of an or-list"
    assert_verdict "${write}"$'\n''for f in "$TMPDIR"/*; do "$f"; done' \
        executor-write DENY "written file run from a loop over a glob"
    assert_verdict "mkdir -p \"\$TMPDIR/d\" && ${notes}"$'\n''ls "$TMPDIR/d" | wc -l' \
        executor-write ALLOW "notes written in a straight and-list of inert commands"
}

# ---- COMMENTS: inert to bash, so inert here ---------------------------------
#
# A comment runs to the end of its line and bash executes none of it. Anything
# the pre-pass reads inside one -- a quote that would otherwise open a region
# spanning the newline, a heredoc operator that would otherwise arm a body --
# is text, and the command on the next line reaches the matcher on its own.
# A comment in the command is cut from the code text by the line-selection
# lexer and read by the pre-pass's own comment rule: a `#` that starts a word
# (after a blank, an unquoted ;&|()<>, or an opening backtick) opens a comment
# in which quotes open no group. A `#` inside a word is not a comment start,
# including one right after a substitution's or an arithmetic group's closing
# `)`, a closing backtick, or an escaped byte, and no `#` inside ${...} or
# (( )) is one. A function definition's `()` is two operators, so a `#` after
# it is. A body handed to an interpreter (`widened` below) is read unquoted
# and whole, comments included, so every such row denies whatever the comment
# rule would have said; the rows without an interpreter pin the rule on the
# outer command, where a misread either way moves quote parity.

case_comment_regions_are_inert() {
    local inv='docket trust add erik key'
    local widened="cat <<'EOF' | bash"
    local sq="'" dq='"'
    local prose="the rule says ${inv} is operator-reserved"
    assert_verdict "${widened}"$'\n'"# it's"$'\n'"${inv}"$'\nEOF' \
        executor-write DENY "an apostrophe in a widened body's comment does not swallow the next body line"
    assert_verdict "${widened}"$'\n'"echo hi # it's"$'\n'"${inv}"$'\nEOF' \
        executor-write DENY "an apostrophe in a widened body's trailing comment does not swallow the next body line"
    assert_verdict "${widened}"$'\n''# say "x'$'\n'"${inv}"$'\nEOF' \
        executor-write DENY "a double quote in a widened body's comment does not swallow the next body line"
    # The same three bodies with a closing quote after the write: a quote the
    # comment rule failed to suppress then closes inside the leaf and marks
    # the write as prose, rather than running to the leaf end unmarked.
    assert_verdict "${widened}"$'\n'"# it's"$'\n'"${inv}"$'\n'"'"$'\nEOF' \
        executor-write DENY "an apostrophe in a widened body's comment does not pair with a later quote"
    assert_verdict "${widened}"$'\n'"echo hi # it's"$'\n'"${inv}"$'\n'"'"$'\nEOF' \
        executor-write DENY "an apostrophe in a widened body's trailing comment does not pair with a later quote"
    assert_verdict "${widened}"$'\n''# say "x'$'\n'"${inv}"$'\n''"'$'\nEOF' \
        executor-write DENY "a double quote in a widened body's comment does not pair with a later quote"
    assert_verdict "${widened}"$'\n'"echo hi;# it's"$'\n'"${inv}"$'\nEOF' \
        executor-write DENY "a widened body's comment opened right after ; does not swallow the next body line"
    assert_verdict "${widened}"$'\n'"(echo hi)# it's"$'\n'"${inv}"$'\nEOF' \
        executor-write DENY "a widened body's comment opened right after ) does not swallow the next body line"
    assert_verdict "${widened}"$'\n'"echo a#b 'the rule says ${inv} is operator-reserved'"$'\nEOF' \
        executor-write DENY "a # inside a widened body's word opens no comment, and the body is read unquoted"
    assert_verdict "echo a#b 'the rule says ${inv} is operator-reserved'" \
        executor-write ALLOW "a # inside a word opens no comment, so the quoted prose beside echo stays prose"
    local op
    for op in '|' '&' '<' '>'; do
        assert_verdict "${widened}"$'\n'"echo hi ${op}# it's"$'\n'"${inv}"$'\nEOF' \
            executor-write DENY "a widened body's comment opened right after ${op} does not swallow the next body line"
    done
    assert_verdict "${widened}"$'\n'"(# it's"$'\n'"${inv}"$'\n)\nEOF' \
        executor-write DENY "a widened body's comment opened right after ( does not swallow the next body line"
    assert_verdict "${widened}"$'\n'"echo \`# it's"$'\n'"${inv}"$'\n`\nEOF' \
        executor-write DENY "a widened body's comment opened right after a backtick does not swallow the next body line"
    assert_verdict "${widened}"$'\n'"echo hi # it's"$'\n'"echo ${sq}${prose}${sq}"$'\nEOF' \
        executor-write DENY "a widened body's comment apostrophe does not matter: the body is read unquoted"
    assert_verdict "echo hi # it's"$'\n'"echo ${sq}${prose}${sq}" \
        executor-write ALLOW "a comment apostrophe leaves the next line's quoted prose as prose"
    assert_verdict "${widened}"$'\n'"echo \$(true)#${sq}"$'\nx\n'"${sq}"$'\n'"${inv}"$'\nEOF' \
        executor-write DENY "a # right after a substitution's ) is mid-word, so its quote still opens a group"
    assert_verdict "${widened}"$'\n'"echo a\\;#${sq}"$'\nx\n'"${sq}"$'\n'"${inv}"$'\nEOF' \
        executor-write DENY "a # right after an escaped ; is mid-word, so its quote still opens a group"
    assert_verdict "${widened}"$'\n'"echo hi;\\;#${sq}"$'\nx\n'"${sq}"$'\n'"${inv}"$'\nEOF' \
        executor-write DENY "an escaped byte after an operator starts the word, so a # after it is mid-word"
    assert_verdict "${widened}"$'\n'"echo \$(true)#${dq}"$'\nx\n'"${dq}"$'\n'"${inv}"$'\nEOF' \
        executor-write DENY "a # right after a substitution's ) is mid-word, so its double quote still opens a group"
    assert_verdict "${widened}"$'\n'"echo \$(true)#; FOO='a b' {docket,} trust add erik key"$'\nEOF' \
        executor-write DENY "a # right after a substitution's ) leaves the next quote's words in command position"
    # The same word shape without the #: an operator that follows a
    # substitution inside one word still ends the command before it.
    assert_verdict "${widened}"$'\n'"echo \$(true);${inv}"$'\nEOF' \
        executor-write DENY "a ; glued after a substitution's ) puts the next word in command position"
    assert_verdict "${widened}"$'\n'"x=\$(true)&&${inv}"$'\nEOF' \
        executor-write DENY "a && glued after a substitution's ) puts the next word in command position"
    assert_verdict "${widened}"$'\n'"echo \$((1+2));${inv}"$'\nEOF' \
        executor-write DENY "a ; glued after an arithmetic close puts the next word in command position"
    assert_verdict "bash -c ${sq}x=\$(true);${inv}${sq}" \
        executor-write DENY "a ; glued after a substitution's ) in an interpreter's code argument puts the next word in command position"
    assert_verdict "${widened}"$'\n'"echo \$(docket trust list);docket trust list"$'\nEOF' \
        executor-write ALLOW "a trust read glued after a substitution's ) stays a read"
    assert_verdict "echo \$((1+2))#${sq}${prose}${sq}" \
        executor-write ALLOW "a # right after an arithmetic close is mid-word, so the quoted prose stays prose"
    assert_verdict "echo \$(date)#${sq}${prose}${sq}" \
        executor-write ALLOW "a # right after a substitution's ) is mid-word, so the quoted prose stays prose"
    assert_verdict "echo \`date\`#${sq}${prose}${sq}" \
        executor-write ALLOW "a # right after a closing backtick is mid-word, so the quoted prose stays prose"
    # These bodies end with a quote after the write, so a quote group the
    # pre-pass opens in the wrong place closes inside the leaf and marks the
    # write as prose instead of running to the leaf end, where it is emitted
    # unmarked.
    local sq_end=$'\n'"${sq}"$'\nEOF' dq_end=$'\n'"${dq}"$'\nEOF'
    assert_verdict "${widened}"$'\n'"echo hi;${sq}x${sq}#${sq}"$'\nx\n'"${sq}"$'\n'"${inv}${sq_end}" \
        executor-write DENY "a # right after a quoted word that follows ; is mid-word, so its quote still opens a group"
    assert_verdict "${widened}"$'\n'"echo hi;${dq}x${dq}#${dq}"$'\nx\n'"${dq}"$'\n'"${inv}${dq_end}" \
        executor-write DENY "a # right after a double-quoted word that follows ; is mid-word, so its quote still opens a group"
    assert_verdict "${widened}"$'\n'"a=(x)#${sq}"$'\ny\n'"${sq}"$'\n'"${inv}${sq_end}" \
        executor-write DENY "a # right after an array assignment's ) is mid-word, so its quote still opens a group"
    assert_verdict "a=(x)#${sq}${prose}${sq}" \
        executor-write ALLOW "a # right after an array assignment's ) is mid-word, so the quoted prose stays prose"
    assert_verdict "${widened}"$'\n'"f()#${sq}"$'\n'"{ ${inv}; }"$'\nf'"${sq_end}" \
        executor-write DENY "a # right after a function definition's () opens a comment, so the body after it is code"
    assert_verdict "${widened}"$'\nshopt -s extglob\n'"echo @(a|b)#${sq}"$'\nx\n'"${sq}"$'\n'"${inv}${sq_end}" \
        executor-write DENY "a # right after an extglob group's ) leaves no quote able to mark later lines as prose"
    assert_verdict "${widened}"$'\nshopt -s extglob\n'"echo +(a)#${sq}"$'\nx\n'"${sq}"$'\n'"${inv}${sq_end}" \
        executor-write DENY "a # right after a +( ) extglob group's ) leaves no quote able to mark later lines as prose"
    assert_verdict "${widened}"$'\nshopt -s extglob\n'"echo @(a|b)#${dq}"$'\nx\n'"${dq}"$'\n'"${inv}${dq_end}" \
        executor-write DENY "a # right after an extglob group's ) leaves no double quote able to mark later lines as prose"
    assert_verdict "${widened}"$'\n'"!(true)#${sq}"$'\n'"${inv}${sq_end}" \
        executor-write DENY "a # right after !( ), a comment unless extglob is on, leaves the next line as code"
    for op in ';' '|' '('; do
        assert_verdict "${widened}"$'\n'"echo \${x:-${op}#${sq}"$'\nx\n'"${sq}}"$'\n'"${inv}${sq_end}" \
            executor-write DENY "a # after ${op} inside \${...} is mid-word, so its quote still opens a group"
    done
    assert_verdict "${widened}"$'\n'"echo \${x:- #${sq}"$'\nx\n'"${sq}}"$'\n'"${inv}${sq_end}" \
        executor-write DENY "a # after a blank inside \${...} is mid-word, so its quote still opens a group"
    assert_verdict "${widened}"$'\n'"echo \${x:-;#}; FOO='a b' {docket,} trust add erik key"$'\nEOF' \
        executor-write DENY "a # after ; inside \${...} leaves the next quote's words in command position"
    assert_verdict "${widened}"$'\n'"(( 1 #${sq}"$'\n'"${sq} ))"$'\n'"${inv}${sq_end}" \
        executor-write DENY "a # inside an arithmetic (( )) is no comment, so its quote still opens a group"
    # When the arithmetic parse fails, bash re-reads (( as nested subshells
    # and the # opens a comment, so the apostrophe after it is comment text.
    assert_verdict "${widened}"$'\n'"((echo hi # it's"$'\n'"docket trust add erik ssh-ed25519 AAAA"$'\n'"echo ' ) ' )"$'\n'")"$'\nEOF' \
        executor-write DENY "a quote inside a failed (( parse leaves the next line as code"
    assert_verdict "${widened}"$'\n'"echo \$((echo hi # it's"$'\n'"docket trust add erik ssh-ed25519 AAAA"$'\n'"echo ' ) ' )"$'\n'")"$'\nEOF' \
        executor-write DENY "a quote inside a failed \$(( parse leaves the next line as code"
    assert_verdict "${widened}"$'\n'"echo \$(case x in x) true;; esac)#${sq}"$'\nx\n'"${sq}"$'\n'"${inv}${sq_end}" \
        executor-write DENY "a case pattern's ) inside \$( ) leaves no quote able to mark later lines as prose"
    assert_verdict "${widened}"$'\n'"echo \$(echo \$(case x in x) true;; esac))#${sq}"$'\nx\n'"${sq}"$'\n'"${inv}${sq_end}" \
        executor-write DENY "a case pattern's ) inside a nested \$( ) leaves no quote able to mark later lines as prose"
    assert_verdict "cat <<'EOF' | zsh"$'\n'"echo \$(case x in x) true;; esac)#${sq}"$'\nx\n'"${sq}"$'\n'"${inv}${sq_end}" \
        executor-write DENY "a case pattern's ) inside \$( ) in a zsh body leaves no quote able to mark later lines as prose"
    assert_verdict "# it's operator-reserved"$'\n'"${inv}" \
        executor-write DENY "an apostrophe inside a comment does not swallow the next line"
    assert_verdict '# the rule says "operator-reserved"'$'\n'"${inv}" \
        executor-write DENY "a double quote inside a comment does not swallow the next line"
    assert_verdict "echo hi # don't do that"$'\n'"${inv}" \
        executor-write DENY "an apostrophe inside a trailing comment does not swallow the next line"
    assert_verdict "(echo one)#<<'EOF'"$'\n'"${inv}" \
        executor-write DENY "a comment opened right after ) arms no heredoc"
    assert_verdict "echo one >#note"$'\n'"${inv}" \
        executor-write DENY "a comment opened right after > arms no heredoc"
    assert_verdict "# ${inv} is the rule this hook enforces" \
        executor-write ALLOW "a comment naming the guarded verb is prose"
}

# ---- QUOTE STATE ENDS WITH ITS LEAF -----------------------------------------
#
# The pre-pass reads the code text in one buffer. A quote it cannot close --
# an apostrophe in a heredoc body, or a multi-line argument -- used to run on
# into the next command, putting its words in the wrong quote group: a
# trust-store write after it read as prose, and prose after it read as code.
# A quoted-delimiter body is cut from the code text before the pre-pass sees
# it, and a call that hands a body to an interpreter is read unquoted, so no
# body byte moves a quote group.

case_quote_state_ends_with_its_leaf() {
    local inv='docket trust add erik key' incident
    incident=$(incident_findings_command)
    assert_verdict "${incident}"$'\n'"${inv}" executor-write DENY \
        "a trust-store write on its own line after the denied findings command"
    assert_deny_reason "${incident}"$'\n'"${inv}" executor-write \
        "a trust-store write after the denied findings command"
    assert_verdict "cat <<'EOF'"$'\n'"bash it's"$'\nEOF\n'"${inv}" executor-write DENY \
        "an apostrophe in a widened heredoc body does not reach the next leaf"
    assert_verdict "jq -n '["$'\n'"1]'"$'\n'"${inv}" executor-write DENY \
        "a multi-line quoted argument cut to its first line does not reach the next leaf"
    assert_verdict "bash 3<<'A' <<'B'"$'\n'"it's"$'\nA\n'"${inv}"$'\nB' executor-write DENY \
        "an apostrophe in one heredoc body does not hide the interpreter's script body after it"
    assert_verdict "cat <<'A' | bash"$'\necho ${x:-\nA\n'"cat <<'B' | bash"$'\n'"# it's"$'\n'"${inv}"$'\n'"'"$'\nB' \
        executor-write DENY "a \${ left open in one heredoc body does not hide a comment in the next leaf"
    assert_verdict "docket issue comment add D-1 -m 'never run ${inv}"$'\n'"on this step'" \
        executor-write ALLOW "multi-line quoted prose cut to its first line stays prose"
}

# ---- A quoted newline before the docket word ------------------------------
#
# When docket is an argument to a wrapper, a quoted argument holding a newline
# before it moves `docket trust add` onto the command's second line. Every
# line is scanned, so the verb is found wherever the quoted argument leaves
# it; a newline inside one quoted group keeps that group prose. sudo is a
# launcher read through to docket, and script is not inert, so the call is
# read unquoted.

case_quoted_newline_before_the_verb() {
    local inv='docket trust add erik' nl=$'\n'
    assert_verdict "echo key | xargs -I '@${nl}' ${inv} @" executor-write DENY \
        "a quoted newline in xargs -I does not hide the verb on the next line"
    assert_deny_reason "echo key | xargs -I '@${nl}' ${inv} @" executor-write \
        "a quoted newline in xargs -I"
    assert_verdict "echo key | xargs -I '@${nl}' ${inv} @" docket-conductor-RUN-1 DENY \
        "conductor: a quoted newline in xargs -I does not hide the verb"
    assert_verdict "echo key | xargs -I \$'@\\n' ${inv} @" executor-write DENY \
        "an ANSI-C quoted newline, which bash's reconstruction makes literal, does not hide the verb"
    assert_verdict "sudo -p 'pw${nl}' ${inv} key" executor-write DENY \
        "a quoted newline in sudo -p does not hide the verb"
    assert_verdict "script -q \"/dev/null${nl}\" docket trust rm erik" executor-write DENY \
        "a double-quoted newline in script's file argument does not hide the verb"
    assert_verdict "sudo -p 'pw${nl}' ${inv} key <<'K'${nl}key${nl}K" executor-write DENY \
        "a quoted heredoc in the same leaf does not hide the verb on the code line"
    assert_verdict "nice -n 1 ${inv} key" executor-write DENY \
        "a wrapper with no quoted newline: nice"
    assert_verdict "echo key | xargs ${inv}" executor-write DENY \
        "a wrapper with no quoted newline: xargs"
    assert_verdict "sudo -p 'pw${nl}' docket trust add --help" executor-write ALLOW \
        "a help read behind a quoted newline stays a help read"
    assert_verdict "sudo -p 'pw${nl}' docket trust add --help" docket-conductor-RUN-1 DENY \
        "conductor: a help read behind a quoted newline still denies"
    assert_verdict "docket issue comment add D-1 -m 'first line${nl}never run ${inv} key'" \
        executor-write ALLOW "multi-line quoted prose naming the verb on its second line stays prose"
    assert_verdict "jq -n '[${nl}1]'" executor-write ALLOW \
        "a multi-line quoted argument with no verb stays allowed"
}

# ---- HEREDOC POSITION: `<<` is only a heredoc operator in redirection ------
#
# The two characters `<<` also appear in a here-string, in a comment, and in
# an arithmetic shift, where they open no body at all. A branch that arms a
# pending delimiter in those positions swallows everything after it into one
# prose group, which turns a real invocation into an ALLOW; the arithmetic
# case fails the other way, denying prose that was allowed before. Every case
# below is DENY except the arithmetic one, and each pins one position.

case_heredoc_position_edges() {
    assert_verdict "grep foo <<<\"bar\""$'\n''docket trust add erik key' \
        executor-write DENY "here-string with a double-quoted word is not a heredoc"
    assert_verdict "grep foo <<<'bar'"$'\n''docket trust add erik key' \
        executor-write DENY "here-string with a single-quoted word is not a heredoc"
    assert_verdict "cat <<A <<'B'"$'\n''$(docket trust add erik key)'$'\nA\nB' \
        executor-write DENY "two heredocs on one line keep their own quotedness in order"
    assert_verdict "# a note about <<'EOF' bodies"$'\n''docket trust add erik key' \
        executor-write DENY "a heredoc operator inside a whole-line comment opens no body"
    assert_verdict "echo hi  # uses <<'EOF' style"$'\n''docket trust add erik key' \
        executor-write DENY "a heredoc operator inside a trailing comment opens no body"
    assert_verdict "cat > \"\$TMPDIR/f.txt\" <<-'EOF'"$'\n\tprose\n\tEOF\n''docket trust add erik key' \
        executor-write DENY "a tab-indented terminator ends a <<- body, and the next line is code"
    assert_verdict 'n=$((1 << 3))'$'\n''echo "the rule says docket trust add is operator-reserved"' \
        executor-write ALLOW "an arithmetic shift opens no heredoc, so the prose after it stays prose"
    assert_verdict '((n = 1 << 3))'$'\n''echo "the rule says docket trust add is operator-reserved"' \
        executor-write ALLOW "a bare arithmetic command opens no heredoc either"
    assert_verdict 'for ((i = 1 << 2; i > 0; i--)); do echo $i; done'$'\n''echo "the rule says docket trust add is operator-reserved"' \
        executor-write DENY "an arithmetic for header opens no heredoc, but a loop reads the text whole"
    assert_verdict 'n=$[1 << 3]'$'\n''echo "the rule says docket trust add is operator-reserved"' \
        executor-write ALLOW "a deprecated \$[ ] arithmetic shift opens no heredoc either"
    # ACCEPTED INACCURACY (hook header): bash's own $BASH_COMMAND
    # reconstruction moves a here-string redirect to the end of the line,
    # so "docket" no longer sits next to "trust add" for the word-adjacency
    # scan to catch — a false ALLOW, but not a missed dispatch: "trust",
    # "add", "erik", "key" are cat's file arguments here, and "docket" is
    # only cat's stdin source, so nothing runs `docket trust add` as a
    # command. Pinned as the CURRENT verdict, not endorsed as correct.
    assert_verdict 'cat <<<docket trust add erik key' \
        executor-write ALLOW "here-string with an unquoted word: accepted false ALLOW, not a real dispatch"
}



# ---- One long line of quoted groups ---------------------------------------
#
# The quote-group pass carries the current line's state forward as it emits
# rather than rescanning what it has already emitted. This pins the verdict
# half of that: group numbering and the code-argument look-behind must read
# the same on the four-hundredth group as on the first. The cost half has no
# assertion here, since a rescan regression is slow rather than wrong; it
# shows up as this row taking seconds.

case_many_quoted_groups_on_one_line() {
    local pad groups i
    pad=$(printf 'a%.0s' {1..70})
    groups=""
    for ((i = 0; i < 400; i++)); do groups="${groups} '${pad}'"; done
    assert_verdict "echo${groups} 'never run docket trust add here'" \
        executor-write ALLOW "400 quoted groups then one prose group stays prose"
    assert_verdict "echo${groups}; docket trust add erik key" \
        executor-write DENY "the verb after 400 quoted groups is still caught"
}


# ---- Missing shared pre-pass file: fail CLOSED, not open ------------------
#
# The awk PROGRAM this hook's quote-group pass runs now lives in a sibling
# file, docket-guard-prepass.awk, rather than inline (DOT-1499). A hook copy
# with no sibling awk file beside it (a broken install) must DENY, not
# silently allow every call: this hook's whole job is deciding whether a
# trust-store write is present, and with no lexer it cannot make that call.

case_missing_prepass_file_denies() {
    local scratch_dir scratch_hook err rc
    scratch_dir=$(mktemp -d "${TMPDIR:-/tmp}/docket-trust-guard-prepass-missing.XXXXXX") || \
        fatal "mktemp failed"
    scratch_hook="${scratch_dir}/docket-trust-guard-hook.sh"
    cp "$HOOK" "$scratch_hook" || fatal "could not copy hook to scratch dir"
    # Deliberately no docket-guard-prepass.awk beside the copy.
    PATH="$TOOLS_DIR" "$BASH_BIN" "$scratch_hook" >/dev/null 2>&1 \
        <<<"$(build_input 'docket trust add erik key' executor-write)"
    rc=$?
    if [ "$rc" -eq 2 ]; then
        pass "hook copy with no sibling awk file denies (exit 2)"
    else
        fail "hook copy with no sibling awk file did not deny (exit ${rc})"
    fi
    err=$(PATH="$TOOLS_DIR" "$BASH_BIN" "$scratch_hook" 2>&1 >/dev/null \
        <<<"$(build_input 'docket trust add erik key' executor-write)")
    case "$err" in
        *"docket-guard-prepass.awk"*) pass "missing-file deny names the cause" ;;
        *) fail "missing-file deny reason changed or missing: ${err}" ;;
    esac
    rm -rf "$scratch_dir"
}

# The code text is selected through docket-guard-leaf-lines.awk. Without it
# the hook cannot tell a body word from a code word, so a copy with every
# other sibling present still denies a command it would allow.
case_missing_leaf_lines_file_denies() {
    local scratch_dir scratch_hook err rc
    scratch_dir=$(mktemp -d "${TMPDIR:-/tmp}/docket-trust-guard-leaf-lines-missing.XXXXXX") || \
        fatal "mktemp failed"
    scratch_hook="${scratch_dir}/docket-trust-guard-hook.sh"
    cp "$HOOK" "$scratch_hook" || fatal "could not copy hook to scratch dir"
    cp "$(dirname "$HOOK")/docket-guard-prepass.awk" "${scratch_dir}/" || \
        fatal "could not copy the shared files to scratch dir"
    err=$(PATH="$TOOLS_DIR" "$BASH_BIN" "$scratch_hook" 2>&1 >/dev/null \
        <<<"$(build_input 'ls' executor-write)")
    rc=$?
    if [ "$rc" -eq 2 ]; then
        pass "hook copy with no line-selection file denies (exit 2)"
    else
        fail "hook copy with no line-selection file did not deny (exit ${rc})"
    fi
    case "$err" in
        *"docket-guard-leaf-lines.awk"*) pass "missing line-selection file is named in the reason" ;;
        *) fail "missing line-selection file deny reason changed or missing: ${err}" ;;
    esac
    rm -rf "$scratch_dir"
}

# ---- Unparseable match program: fail CLOSED, not open ---------------------
#
# A match program awk cannot parse prints nothing and exits non-zero. Read
# as "no trust-store write", that would allow every command, so the hook
# refuses instead. The copy breaks the program at its first statement; `ls`
# from an executor is allowed by the shipped hook.

case_match_program_failure() {
    local scratch_dir scratch_hook err rc
    scratch_dir=$(mktemp -d "${TMPDIR:-/tmp}/docket-trust-guard-match-broken.XXXXXX") || \
        fatal "mktemp failed"
    scratch_hook="${scratch_dir}/docket-trust-guard-hook.sh"
    sed 's/^function active() { print "ACTIVE"; exit }$/function active() { print = "ACTIVE"; exit }/' \
        "$HOOK" >"$scratch_hook" || fatal "could not copy hook to scratch dir"
    cp "$(dirname "$HOOK")/docket-guard-prepass.awk" "$(dirname "$HOOK")/docket-guard-leaf-lines.awk" "${scratch_dir}/" || \
        fatal "could not copy the pre-pass file to scratch dir"
    if cmp -s "$HOOK" "$scratch_hook"; then
        fail "unparseable match program: the fixture edit did not apply"
        rm -rf "$scratch_dir"
        return
    fi
    err=$(PATH="$TOOLS_DIR" "$BASH_BIN" "$scratch_hook" 2>&1 >/dev/null \
        <<<"$(build_input 'ls' executor-write)")
    rc=$?
    if [ "$rc" -eq 2 ]; then
        pass "unparseable match program fails closed on ls (DENY)"
    else
        fail "unparseable match program on ls (want DENY, got exit ${rc})"
    fi
    case "$err" in
        *"match program failed"*) pass "unparseable match program names the analysis failure" ;;
        *) fail "unparseable match program reason: ${err}" ;;
    esac
    rm -rf "$scratch_dir"
}

# ---- Unparseable pre-pass program: fail CLOSED, not open ------------------
#
# A pre-pass program awk cannot parse prints nothing and exits non-zero, so
# the match stage would see no command at all. The hook refuses instead of
# allowing. The copy appends one unparseable statement to the shared file;
# `ls` from an executor is allowed by the shipped hook.

# Under a UTF-8 locale macOS awk refused a lone byte of a multibyte
# character, so the byte-wise pre-pass failed and the guard denied any
# command carrying one unquoted. The deny rows show the C-locale pass still
# closes on a trust verb beside the same text.
case_multibyte_text_under_utf8() {
    LC_ALL=en_US.UTF-8 assert_verdict "echo café" executor-write ALLOW \
        "utf-8: unquoted multibyte word"
    LC_ALL=en_US.UTF-8 assert_verdict "echo 'a — b' && ls" executor-write ALLOW \
        "utf-8: quoted multibyte text beside a read"
    LC_ALL=en_US.UTF-8 assert_verdict "echo café && docket trust add erik key" executor-write DENY \
        "utf-8: multibyte word before docket trust add"
    LC_ALL=en_US.UTF-8 assert_verdict "docket trust rm erik # café — x" executor-write DENY \
        "utf-8: docket trust rm with a multibyte comment"
}

case_prepass_program_failure() {
    local scratch_dir scratch_hook err rc
    scratch_dir=$(mktemp -d "${TMPDIR:-/tmp}/docket-trust-guard-prepass-broken.XXXXXX") || \
        fatal "mktemp failed"
    scratch_hook="${scratch_dir}/docket-trust-guard-hook.sh"
    cp "$HOOK" "$scratch_hook" || fatal "could not copy hook to scratch dir"
    cp "$(dirname "$HOOK")/docket-guard-leaf-lines.awk" "${scratch_dir}/" || \
        fatal "could not copy the line-selection file to scratch dir"
    { cat "$(dirname "$HOOK")/docket-guard-prepass.awk"; printf '%s\n' 'BEGIN { x = = 1 }'; } \
        >"${scratch_dir}/docket-guard-prepass.awk" || \
        fatal "could not write the broken pre-pass file to scratch dir"
    err=$(PATH="$TOOLS_DIR" "$BASH_BIN" "$scratch_hook" 2>&1 >/dev/null \
        <<<"$(build_input 'ls' executor-write)")
    rc=$?
    if [ "$rc" -eq 2 ]; then
        pass "unparseable pre-pass program fails closed on ls (DENY)"
    else
        fail "unparseable pre-pass program on ls (want DENY, got exit ${rc})"
    fi
    case "$err" in
        *"pre-pass program failed"*) pass "unparseable pre-pass program names the analysis failure" ;;
        *) fail "unparseable pre-pass program reason: ${err}" ;;
    esac
    rm -rf "$scratch_dir"
}

# ---- Pre-pass drift: the two guard hooks must share one lexer file --------
#
# The quote-aware pre-pass used to be duplicated byte-for-byte in the trust
# guard and the commit guard, with no sourcing mechanism available (each hook
# is invoked standalone). DOT-1499 moved the awk PROGRAM into one file,
# docket-guard-prepass.awk, that both hooks read with `awk -f`; a fix now
# lands once. What could still drift is which file each hook points at: this
# pins that both hooks resolve the SAME line (`awk -f "$PREPASS_AWK"` against
# a path built from their own script directory) rather than a hand-copied
# inline program reappearing in either one.
#
# Both sides are read from REPO_ROOT rather than from the hook under test: the
# claim is about the pair that ships, and a GUARD_HOOK override points at a
# scratch copy. Anchored to the override, this row reported the pre-pass
# identical while both shipped hooks were untouched and both scratch copies
# carried the same mutation -- true of the wrong pair, and the only check
# standing between a fix applied to one hook and a half-closed bypass.

SHIPPED_HOOKS="${REPO_ROOT}/src/user/claude_code/hooks"
PREPASS_AWK_FILE="${SHIPPED_HOOKS}/docket-guard-prepass.awk"
PREPASS_INVOCATION='awk -f "$PREPASS_AWK" 2>/dev/null'

case_prepass_copies_identical() {
    local trust_line commit_line
    trust_line=$(grep -F "$PREPASS_INVOCATION" "${SHIPPED_HOOKS}/docket-trust-guard-hook.sh" 2>/dev/null)
    commit_line=$(grep -F "$PREPASS_INVOCATION" "${SHIPPED_HOOKS}/docket-commit-guard-hook.sh" 2>/dev/null)
    if [ ! -r "$PREPASS_AWK_FILE" ]; then
        fail "shared pre-pass file docket-guard-prepass.awk is missing"
    elif [ -z "$trust_line" ] || [ -z "$commit_line" ]; then
        fail "one of the shipped hooks no longer reads the shared pre-pass file with awk -f (an inline copy may have returned)"
    else
        pass "both shipped hooks read the one shared pre-pass file"
    fi
}

# ---- Framing control bytes: refused before any analysis -------------------
#
# The hook frames its own analysis with 0x01 (the pre-pass quote-group mark),
# 0x1d (a quoted blank held in a word) and 0x1e (a record boundary) and
# refuses any command that carries one, so a caller cannot forge a mark or a
# boundary that resets the pre-pass quote state. Each row asserts exit 2 and
# the control-byte reason together: the reason text keeps the row red when
# the refusal is gone but another matcher still denies the command.
# assert_deny_reason does not fit, because this reason differs from
# DENY_REASON. The bytes are built at runtime so the file stays plain text.

CONTROL_BYTE_REASON='control byte (0x01, 0x1d or 0x1e)'

assert_control_byte_deny() {
    local cmd="$1" agent="$2" label="$3" err rc
    err=$(PATH="$TOOLS_DIR" "$BASH_BIN" "$HOOK" 2>&1 >/dev/null <<<"$(build_input "$cmd" "$agent")")
    rc=$?
    if [ "$rc" -ne 2 ]; then
        fail "${label} (want exit 2, got exit ${rc})"
        return
    fi
    case "$err" in
        *"${CONTROL_BYTE_REASON}"*) pass "${label} (DENY, control-byte reason)" ;;
        *) fail "${label} (control-byte reason missing: ${err})" ;;
    esac
}

case_framing_control_bytes_deny() {
    local rs gs
    rs=$(printf '\036')
    gs=$(printf '\035')
    assert_control_byte_deny "docket ${rs} trust add erik ssh-ed25519 AAAA" executor-write \
        "executor-write: bare 0x1e word between docket and trust add"
    assert_control_byte_deny "docket ${gs} trust add erik ssh-ed25519 AAAA" executor-write \
        "executor-write: bare 0x1d word between docket and trust add"
}

# ---- Wall-clock bound: an analysis that outlives it denies -----------------
#
# The harness cancels a hook that reaches its timeout and runs the Bash call
# unchecked, so the hook bounds its own run well under that timeout and
# denies when the bound fires. The row lowers the bound to 1 s through
# DOCKET_GUARD_BOUND_SECONDS and puts an awk first on PATH that sleeps 3 s
# before running the real one, so the check outlives the bound on any machine
# rather than only on one slow enough to take more than a second.

case_analysis_bound_denies() {
    local input err rc slow="${SANDBOX}/slow-awk"
    mkdir -p "$slow"
    printf '#!%s\n/bin/sleep 3\nexec %s "$@"\n' "$BASH_BIN" "$(command -v awk)" > "${slow}/awk"
    chmod +x "${slow}/awk"
    input=$(build_input 'ls' executor-write)
    err=$(DOCKET_GUARD_BOUND_SECONDS=1 PATH="${slow}:${TOOLS_DIR}" "$BASH_BIN" "$HOOK" 2>&1 >/dev/null <<<"$input")
    rc=$?
    if [ "$rc" -eq 2 ]; then
        pass "executor-write: analysis past a 1 s bound is refused (DENY)"
    else
        fail "executor-write: analysis past a 1 s bound (want DENY, got exit ${rc})"
    fi
    case "$err" in
        *"within its 1 s wall-clock bound"*) pass "executor-write: the bound deny names the bound" ;;
        *) fail "executor-write: the bound deny reason: ${err}" ;;
    esac
    PATH="$TOOLS_DIR" "$BASH_BIN" "$HOOK" >/dev/null 2>&1 <<<"$input"
    rc=$?
    if [ "$rc" -eq 0 ]; then
        pass "executor-write: the same analysis at the default bound allows (ALLOW)"
    else
        fail "executor-write: the same analysis at the default bound (want ALLOW, got exit ${rc})"
    fi
}

# ---- Input edge cases: fail open, never mid-parse --------------------------

case_input_edge_cases() {
    assert_verdict_raw '{"tool_name":"Read","tool_input":{"file_path":"x"},"agent_type":"executor-write"}' \
        ALLOW "non-Bash tool_name allows regardless of agent_type"
    assert_verdict_raw '{"tool_name":"Bash","tool_input":{"command":""},"agent_type":"executor-write"}' \
        ALLOW "empty command string allows"
    assert_verdict_raw '{"tool_name":"Bash","agent_type":"executor-write"}' \
        ALLOW "missing tool_input allows"
    assert_verdict_raw 'not json at all' \
        ALLOW "malformed (non-JSON) stdin fails open to allow"
    assert_verdict_raw '' \
        ALLOW "empty stdin fails open to allow"
}

case_executor_archetypes_deny
case_conductor_seat_denies
case_executor_read_deny_recovery
case_main_conversation_and_other_agents_allow
case_ordinary_docket_verbs_allow
case_must_not_catch_prose_and_reads
case_must_deny_glued_separator_class
case_must_deny_separately_quoted_tokens
case_must_deny_quote_split_words
case_brace_split_verb_denies
case_command_position_brace_denies
case_brace_redirection_before_verb_denies
case_brace_redirection_command_end_allows
case_command_position_brace_allows
case_backslash_continuation
case_zsh_modifier_brace_denies
case_zsh_modifier_brace_allows
case_leading_dash_command
case_unexpandable_brace_prose_allows
case_quoted_brace_interpreter_stdin_residual
case_interpreter_code_argument_deny
case_full_interpreter_list_denies
case_full_code_flag_list_denies
case_code_flag_and_interpreter_spellings_deny
case_interpreter_code_argument_prose_deny
case_interpreter_code_argument_allows
case_interpreter_carriers_residual_allow
case_help_read_exemption_allows
case_help_lookalikes_and_compounds_deny
case_heredoc_body_prose
case_executor_read_payload_heredoc
case_widened_body_brace_prose
case_scratch_prose_names_trust_verbs
case_heredoc_body_destination
case_heredoc_written_then_run
case_heredoc_sourced_from_stdin
case_inert_commands_bound_the_prose_exemption
case_comment_regions_are_inert
case_quote_state_ends_with_its_leaf
case_quoted_newline_before_the_verb
case_heredoc_position_edges
case_many_quoted_groups_on_one_line
case_missing_prepass_file_denies
case_missing_leaf_lines_file_denies
case_match_program_failure
case_prepass_program_failure
case_multibyte_text_under_utf8
case_prepass_copies_identical
case_framing_control_bytes_deny
case_analysis_bound_denies
case_input_edge_cases

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"

if [ "$FAIL" -ne 0 ]; then
    exit 1
fi

exit 0
