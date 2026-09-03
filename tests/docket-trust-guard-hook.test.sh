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

SANDBOX=$(mktemp -d "${TMPDIR:-/tmp}/docket-trust-guard-test.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$SANDBOX"' EXIT

TOOLS_DIR="${SANDBOX}/tools"
mkdir -p "$TOOLS_DIR"
for tool in bash cat jq awk; do
    tool_path=$(command -v "$tool") || fatal "hook dependency ${tool} not found on PATH"
    ln -s "$tool_path" "${TOOLS_DIR}/${tool}"
done

# Classifies one hook run as DENY (exit 2) or ALLOW (exit 0). No
# permissionDecision envelope is emitted -- exit 2 is a pre-permission hard
# stop and exit 0 is silence -- so the exit code is the entire verdict.
verdict_of() {
    local input="$1" rc
    PATH="$TOOLS_DIR" "$BASH_BIN" "$HOOK" >/dev/null 2>&1 <<<"$input"
    rc=$?
    if [ "$rc" -eq 2 ]; then
        printf 'DENY'
    else
        printf 'ALLOW'
    fi
}

build_input() {
    local cmd="$1" agent="${2:-}"
    if [ -n "$agent" ]; then
        jq -nc --arg c "$cmd" --arg a "$agent" \
            '{tool_name:"Bash",tool_input:{command:$c},agent_type:$a}'
    else
        jq -nc --arg c "$cmd" '{tool_name:"Bash",tool_input:{command:$c}}'
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
}

# ---- COMMENTS: inert to bash, so inert here ---------------------------------
#
# A comment runs to the end of its line and bash executes none of it. Anything
# the pre-pass reads inside one -- a quote that would otherwise open a region
# spanning the newline, a heredoc operator that would otherwise arm a body --
# is text, so the whole comment is consumed as one prose group and the command
# on the next line reaches the matcher on its own.

case_comment_regions_are_inert() {
    local inv='docket trust add erik key'
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
        executor-write ALLOW "an arithmetic for header opens no heredoc either"
    assert_verdict 'n=$[1 << 3]'$'\n''echo "the rule says docket trust add is operator-reserved"' \
        executor-write ALLOW "a deprecated \$[ ] arithmetic shift opens no heredoc either"
    assert_verdict 'cat <<<docket trust add erik key' \
        executor-write DENY "here-string with an unquoted word is not a heredoc"
}

# ---- Pre-pass drift: the two guard hooks must share one lexer --------------
#
# The quote-aware pre-pass is duplicated byte-for-byte in the trust guard and
# the commit guard, with no sourcing mechanism available (each hook is invoked
# standalone). A fix applied to one copy and not the other leaves two guards
# with different notions of inert text, and nothing else in the tree notices.
#
# Both sides are read relative to the HOOK UNDER TEST, not from REPO_ROOT, so
# the check describes the same artifact every other case drives: under a
# GUARD_HOOK override it compares that copy against the sibling beside it, and
# reports the region missing when there is no sibling to compare against.

PREPASS_RANGE="/^STRIPPED=/,/^' 2>\/dev\/null) || allow_default\$/p"

case_prepass_copies_identical() {
    local mine sibling
    mine=$(sed -n "$PREPASS_RANGE" "$HOOK")
    sibling=$(sed -n "$PREPASS_RANGE" "$(dirname "$HOOK")/docket-commit-guard-hook.sh" 2>/dev/null)
    if [ -z "$mine" ] || [ -z "$sibling" ]; then
        fail "quote-aware pre-pass region not found in the hook under test or its sibling"
    elif [ "$mine" = "$sibling" ]; then
        pass "quote-aware pre-pass is byte-identical in the hook under test and its sibling"
    else
        fail "quote-aware pre-pass has drifted between the hook under test and its sibling"
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
case_main_conversation_and_other_agents_allow
case_ordinary_docket_verbs_allow
case_must_not_catch_prose_and_reads
case_must_deny_glued_separator_class
case_must_deny_separately_quoted_tokens
case_help_read_exemption_allows
case_help_lookalikes_and_compounds_deny
case_heredoc_body_prose
case_heredoc_body_destination
case_comment_regions_are_inert
case_heredoc_position_edges
case_prepass_copies_identical
case_input_edge_cases

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"

if [ "$FAIL" -ne 0 ]; then
    exit 1
fi

exit 0
