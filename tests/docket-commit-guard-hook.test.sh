#!/bin/bash

# Behavior suite for src/user/claude_code/hooks/docket-commit-guard-hook.sh.
#
# DEFECT CLASS. Two failure directions, both silent in production:
#   FALSE ALLOW - a real `git commit/push/add` invocation whose shape the text
#     matcher fails to recognize, so the engine gate is never consulted and an
#     unapproved git write executes.
#   FALSE DENY  - a read, a query, or prose that merely mentions git-write
#     wording, matched anyway, bricking unrelated Bash calls for the session.
# Plus the decision layer this hook re-keyed onto engine state: which of the
# engine's gate verdicts mean "deny" and which mean "this guard has no opinion".
#
# SEAMS. The hook's only two external boundaries are injected, so the suite is
# a small test - single process, no network, no .docket database, no real run:
#   * PATH holds a fake `docket` whose gate verdict is chosen per case via
#     GATE_STATE. The engine's answer is an input here, not something this
#     suite arranges by mutating engine state.
#   * GUARD_HOOK overrides the hook under test, so a mutation probe can point
#     the suite at a deliberately-broken COPY under $TMPDIR and observe red
#     without touching the checkout.
# PATH is also narrowed to a directory of symlinks holding exactly the tools
# the hook needs, so "docket is not installed" is a real absence rather than a
# property of whichever machine runs the suite.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
HOOK="${GUARD_HOOK:-${REPO_ROOT}/src/user/claude_code/hooks/docket-commit-guard-hook.sh}"

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

SANDBOX=$(mktemp -d "${TMPDIR:-/tmp}/docket-commit-guard-test.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$SANDBOX"' EXIT

# A PATH with the hook's real dependencies and nothing else. `docket` is
# deliberately absent from it; the stub below lives in its own directory that
# is prepended only for the cases that want an installed engine.
TOOLS_DIR="${SANDBOX}/tools"
STUB_DIR="${SANDBOX}/stub"
mkdir -p "$TOOLS_DIR" "$STUB_DIR"
for tool in bash cat jq awk; do
    tool_path=$(command -v "$tool") || fatal "hook dependency ${tool} not found on PATH"
    ln -s "$tool_path" "${TOOLS_DIR}/${tool}"
done

# Fake engine. Implements exactly the one query the hook makes and returns the
# verdict named by GATE_STATE, reproducing the engine's real reason strings
# (internal/engine/guard.go) rather than paraphrases - the hook's not-applicable
# arms match on that text, so a paraphrase here would test nothing.
cat >"${STUB_DIR}/docket" <<'STUB'
#!/bin/bash
if [ "${1:-}" != "guard" ] || [ "${2:-}" != "gate" ]; then
    printf 'fake docket: unexpected invocation: %s\n' "$*" >&2
    exit 64
fi
case "${GATE_STATE:-unapproved}" in
    approved)
        exit 0
        ;;
    unapproved)
        printf 'gate "commit-gate" is pending, not approved\n' >&2
        exit 2
        ;;
    absent)
        printf 'no type="human" step named "commit-gate" in any active run\n' >&2
        exit 2
        ;;
    no-db)
        printf 'no docket database found\n' >&2
        exit 2
        ;;
    surprise)
        printf 'engine verdict this hook has never seen before\n' >&2
        exit 2
        ;;
    *)
        printf 'fake docket: unknown GATE_STATE %s\n' "${GATE_STATE:-}" >&2
        exit 64
        ;;
esac
STUB
chmod +x "${STUB_DIR}/docket"

PATH_WITH_DOCKET="${STUB_DIR}:${TOOLS_DIR}"
PATH_WITHOUT_DOCKET="${TOOLS_DIR}"

# Classifies one hook run as DENY (exit 2) or ALLOW (exit 0). The live hook
# emits no permissionDecision envelope - exit 2 is a pre-permission hard stop
# and exit 0 is silence - so the exit code is the entire verdict surface, and
# it is read directly from the hook rather than through a pipe.
verdict_of() {
    local input="$1" path_value="${2:-$PATH_WITH_DOCKET}" gate="${3:-unapproved}" rc
    PATH="$path_value" GATE_STATE="$gate" "$BASH_BIN" "$HOOK" >/dev/null 2>&1 <<<"$input"
    rc=$?
    if [ "$rc" -eq 2 ]; then
        printf 'DENY'
    else
        printf 'ALLOW'
    fi
}

build_input() {
    local cmd="$1" mode="${2:-}"
    if [ -n "$mode" ]; then
        jq -nc --arg c "$cmd" --arg m "$mode" \
            '{tool_name:"Bash",tool_input:{command:$c},permission_mode:$m}'
    else
        jq -nc --arg c "$cmd" '{tool_name:"Bash",tool_input:{command:$c}}'
    fi
}

# Default arrangement: an installed engine reporting a commit-gate step that
# exists and is not approved. That is the one engine state in which the
# matcher's verdict is observable, so it is what every matcher case below runs
# under; the engine's other verdicts are pinned in their own case group.
assert_verdict() {
    local cmd="$1" want="$2" label="$3" got
    got=$(verdict_of "$(build_input "$cmd")")
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

assert_gate_verdict() {
    local cmd="$1" gate="$2" path_value="$3" want="$4" label="$5" got
    got=$(verdict_of "$(build_input "$cmd")" "$path_value" "$gate")
    if [ "$got" = "$want" ]; then
        pass "${label} (${want})"
    else
        fail "${label} (want ${want}, got ${got})"
    fi
}

assert_mode_verdict() {
    local cmd="$1" mode="$2" gate="$3" want="$4" label="$5" got
    got=$(verdict_of "$(build_input "$cmd" "$mode")" "$PATH_WITH_DOCKET" "$gate")
    if [ "$got" = "$want" ]; then
        pass "${label} (${want})"
    else
        fail "${label} (want ${want}, got ${got})"
    fi
}

# ---- THE DECISION: engine gate verdict -> hook verdict --------------------
# The half of this hook that is NOT inherited matcher. Only one engine verdict
# is a denial; two are "this guard has no opinion" and must stay allows, or
# the hook bricks every git write in a session whose pipeline has no
# commit-gate step (and in every repo with no .docket at all).

case_engine_verdict_mapping() {
    assert_gate_verdict "git commit -m x" unapproved "$PATH_WITH_DOCKET" DENY \
        "gate exists and is unapproved -> deny"
    assert_gate_verdict "git commit -m x" approved "$PATH_WITH_DOCKET" ALLOW \
        "gate approved -> allow (the recorded human decision authorizes the write)"
    assert_gate_verdict "git commit -m x" absent "$PATH_WITH_DOCKET" ALLOW \
        "no commit-gate step in any active run -> allow (absent is not unapproved)"
    assert_gate_verdict "git commit -m x" no-db "$PATH_WITH_DOCKET" ALLOW \
        "no docket database -> allow (a non-docket repo is not a denial)"
    assert_gate_verdict "git commit -m x" surprise "$PATH_WITH_DOCKET" DENY \
        "unrecognized engine reason -> deny (fail closed on anything the engine judges)"
    assert_gate_verdict "git commit -m x" unapproved "$PATH_WITHOUT_DOCKET" ALLOW \
        "docket not installed -> allow (fail open on a tooling gap)"
    assert_gate_verdict "git status" unapproved "$PATH_WITH_DOCKET" ALLOW \
        "non-write command never reaches the gate query"
}

# ---- THE RE-KEY: permission_mode no longer decides anything ---------------
# The retired hook resolved on permission_mode (interactive -> ask, otherwise
# deny). This one answers from engine state alone, so the same write must get
# the same verdict in every mode - including a mode this hook has never heard
# of and a payload with no mode at all.

case_permission_mode_is_not_consulted() {
    local mode
    for mode in auto default plan acceptEdits dontAsk bypassPermissions weirdmode; do
        assert_mode_verdict "git commit -m x" "$mode" unapproved DENY \
            "unapproved gate denies in permission_mode=${mode}"
    done
    assert_mode_verdict "git commit -m x" bypassPermissions approved ALLOW \
        "approved gate allows even in bypassPermissions"
    assert_verdict_raw '{"tool_name":"Bash","tool_input":{"command":"git commit -m y"}}' \
        DENY "absent permission_mode field is irrelevant to the verdict"
}

# ---- MUST DENY: baseline invocations --------------------------------------

case_must_deny_baseline() {
    assert_verdict "git commit -m 'x'" DENY "plain git commit"
    assert_verdict "git add src/foo.rs" DENY "git add"
    assert_verdict "git push origin main" DENY "git push"
    assert_verdict "cd /x && git commit -m y" DENY "&& git commit"
    assert_verdict "git -C /repo commit -m y" DENY "git -C <path> commit"
    assert_verdict "git --no-pager push" DENY "git --no-pager push"
    assert_verdict "/usr/bin/git commit -m y" DENY "/usr/bin/git commit"
    assert_verdict "git -c user.email=x commit -m y" DENY "git -c <val> commit"
    assert_verdict "git 'commit' -m y" DENY "git 'commit' (quoted subcommand, bare head)"
}

# ---- MUST DENY: glued separator/no-space class (5 shapes) ----------------
# A separator or subshell-open glued directly onto `git` with no whitespace
# still resolves to a head of "git" via the head-normalization, so all five
# must deny - a future tokenizer change reopening any one of these would
# silently regress the operator's bar.

case_must_deny_glued_separator_class() {
    assert_verdict "cd /x &&git commit -m msg" DENY "&&git commit (no space)"
    assert_verdict "cd /x ;git commit -m msg" DENY ";git commit (no space)"
    assert_verdict "false ||git commit -m msg" DENY "||git commit (no space)"
    assert_verdict "cd /x &git commit -m msg" DENY "&git commit (single ampersand, no space)"
    assert_verdict "(git commit -m y)" DENY "(git commit (subshell, no space)"
}

# ---- MUST DENY: command-substitution capture-output shapes ---------------

case_must_deny_capture_output() {
    assert_verdict 'X=$(git commit -m y)' DENY 'X=$(git commit -m y) capture-output'
    assert_verdict 'MSG=$(git commit -m x 2>&1)' DENY 'MSG=$(git commit -m x 2>&1) capture-output'
    assert_verdict 'echo "$(git commit -m x)"' DENY 'echo "$(git commit -m x)" capture-output'
    assert_verdict 'OUT=`git push origin main`' DENY 'OUT=`git push origin main` backtick capture'
    assert_verdict '$(git add -A)' DENY 'bare $(git add -A)'
}

# ---- MUST DENY: terminal-position subcommand normalization ---------------
# A delimiter glued directly AFTER the subcommand with nothing following it.
# The head-normalization alone does not close these, so they get their own
# group: each one is a shape that once silently allowed.

case_must_deny_terminal_position() {
    assert_verdict 'git push;' DENY 'bare git push; terminal separator'
    assert_verdict 'git commit;' DENY 'bare git commit; terminal separator'
    assert_verdict 'git add;' DENY 'bare git add; terminal separator'
    assert_verdict 'git push&' DENY 'bare git push& terminal separator'
    assert_verdict 'git push|cat' DENY 'git push|cat terminal pipe'
    assert_verdict 'git push>out.log' DENY 'git push>out.log terminal redirect'
    assert_verdict 'X=$(git push)' DENY 'X=$(git push) terminal capture-output, no trailing content'
    assert_verdict 'X=$(git add)' DENY 'X=$(git add) terminal capture-output, no trailing content'
    assert_verdict 'X=`git push`' DENY 'X=`git push` terminal backtick capture (assignment-glued)'
    assert_verdict '`git push`' DENY 'bare `git push` terminal backtick capture'
    assert_verdict '(git push)' DENY '(git push) terminal subshell, no trailing content'
    assert_verdict '(git commit)' DENY '(git commit) terminal subshell, no trailing content'
    assert_verdict '{ git push; }' DENY '{ git push; } terminal brace group'
}

# ---- MUST ALLOW: negative controls for the terminal-position fix ---------
# (a prior attempt at that fix over-matched on these query/wrapper forms -
# locked in here so a future edit cannot silently regress)

case_must_allow_terminal_fix_negative_controls() {
    assert_verdict 'command -v git' ALLOW 'command -v git (query, no subcommand follows)'
    assert_verdict 'which git' ALLOW 'which git (query, no subcommand follows)'
    assert_verdict 'type git' ALLOW 'type git (query, no subcommand follows)'
    assert_verdict 'nice -n 10 echo hi' ALLOW 'nice -n 10 <non-git command>'
}

# ---- MUST ALLOW: computed subcommand, accepted residual -------------------
# The verb "git" is literal but the subcommand word is produced by expansion,
# so it never matches commit/push/add. Deliberate construction required (not a
# realistic accidental-mistake shape); a documented residual, not a gap this
# hook closes.

case_must_allow_computed_subcommand_residual() {
    assert_verdict 'git $(echo commit)' ALLOW 'git $(echo commit) computed subcommand'
    assert_verdict 'git $V' ALLOW 'git $V computed subcommand'
    assert_verdict 'git `echo commit`' ALLOW 'git `echo commit` computed subcommand'
}

# ---- MUST ALLOW: option-before-subcommand help exemption -----------------

case_must_allow_help_exemption() {
    assert_verdict "git --help add" ALLOW "git --help add (long-flag exemption)"
    assert_verdict "git -h add" ALLOW "git -h add (short-flag exemption)"
}

# ---- ACCEPTED FALSE POSITIVE: documented control row ---------------------
# Deliberately NOT fixed - closing it would require scanning past the
# subcommand for a trailing flag, which would let a commit message merely
# containing the text "--help" wrongly allow. This row exists so a future edit
# cannot change the behavior without a deliberate test change - see the hook's
# header comment for the same ruling.

case_accepted_false_positive_control() {
    assert_verdict "git commit --help" DENY "git commit --help (accepted FP, subcommand-before-flag NOT exempted)"
}

# ---- MUST NOT CATCH: prose / read-only -----------------------------------

case_must_not_catch_prose_and_reads() {
    assert_verdict 'docket issue comment add D-1 -m "do not git commit here"' ALLOW "prose mentioning git commit inside -m body"
    assert_verdict 'docket issue comment add D-1 -m "never git add or git push"' ALLOW "prose mentioning git add/push inside -m body"
    assert_verdict "git log --oneline -5" ALLOW "git log"
    assert_verdict "git status" ALLOW "git status"
    assert_verdict "git diff HEAD" ALLOW "git diff"
    assert_verdict "git remote add up http://u" ALLOW "git remote add (subcommand is remote, not add)"
    assert_verdict "git submodule add http://u p" ALLOW "git submodule add"
    assert_verdict "git worktree add ../wt" ALLOW "git worktree add"
    assert_verdict "echo 'the phrase git commit appears here'" ALLOW "single-quoted prose"
}

# ---- MUST NOT CATCH: substitution-READ shapes ----------------------------
# (false-positive check on the head-normalization: it must not start denying a
# read whose captured output never performs a write)

case_must_not_catch_substitution_reads() {
    assert_verdict 'SHA=$(git log -1 --format=%H)' ALLOW 'SHA=$(git log -1) substitution read'
    assert_verdict 'B=$(git rev-parse --abbrev-ref HEAD)' ALLOW 'B=$(git rev-parse) substitution read'
    assert_verdict 'echo "$(git status --short)"' ALLOW 'echo "$(git status)" substitution read'
    assert_verdict 'N=$(git remote add up http://u)' ALLOW 'N=$(git remote add ...) substitution read'
    assert_verdict 'F=$(ls src)' ALLOW 'F=$(ls src) non-git substitution'
    assert_verdict 'D=$(realpath src/foo)' ALLOW 'D=$(realpath ...) non-git substitution'
}

# ---- ACCEPTED RESIDUAL RISKS: unchanged by design, per hook header --------
# Shell indirection and script invocation are structurally invisible to this
# hook's only input: a script that commits internally carries no git token in
# the command line the hook sees, whatever prefix launches it. Documented and
# operator-accepted; these rows pin that the residual is deliberate rather than
# a regression somebody can claim was caught.

case_accepted_residual_risks() {
    local script="src/user/claude_code/hooks/docket-commit-guard-hook.sh"
    assert_verdict "./deploy.sh" ALLOW "wrapper-script invocation (accepted residual)"
    assert_verdict "bash ${script}" ALLOW "bash <script path> (interpreter-prefixed, accepted residual)"
    assert_verdict "./${script}" ALLOW "./<script path> (direct exec, accepted residual)"
    assert_verdict "timeout 30 bash ${script}" ALLOW "timeout-wrapped script path (accepted residual)"
    # The look-behind word of the code-argument rule is read as bash builds it
    # from LITERAL text, so a flag or an interpreter that only exists after an
    # expansion is invisible here. Denying every word carrying a `$` would close
    # the first row alone and deny ordinary `bash "$SCRIPT" ...` calls, so all
    # three stay ALLOW.
    assert_verdict "F=-c; bash \$F 'git commit -m x'" ALLOW \
        "code flag reached through a variable (accepted residual)"
    assert_verdict "I=bash; \$I -c 'git commit -m x'" ALLOW \
        "interpreter reached through a variable (accepted residual)"
    assert_verdict "bash \$(printf -- -c) 'git commit -m x'" ALLOW \
        "code flag reached through a substitution (accepted residual)"
}

# ---- MUST DENY: the write carried as an interpreter's code argument -------
#
# `bash -c "git commit …"` was pinned above as an accepted residual until the
# quote-group pass learned that a code argument is executed verbatim rather
# than being prose. It is a real dispatch of a guarded write, so it denies
# now; the rows above it stay ALLOW because an interpreter given a script
# path carries no code flag.

case_interpreter_code_argument_deny() {
    assert_verdict 'git commit -m x' DENY "bare write (positive control for this group)"
    assert_verdict 'bash -c "git commit -m x"' DENY "bash -c with a double-quoted code argument"
    assert_verdict "bash -c 'git commit -m x'" DENY "bash -c with a single-quoted code argument"
    assert_verdict "bash -lc 'git push origin main'" DENY "bundled short flags (-lc)"
    assert_verdict "env bash -c 'git commit -m x'" DENY "interpreter behind an env pass-through"
    assert_verdict "python3 -c 'import os; os.system(\"git commit -m x\")'" DENY \
        "python3 -c: the write inside a nested double-quoted string"
    assert_verdict "bash -c 'git status --short'" ALLOW "code argument naming only a read"
    assert_verdict "echo 'the phrase git commit appears here'" ALLOW \
        "prose quoted after a non-interpreter word"
}

# ---- MUST DENY: the same call with the flag or interpreter spelled oddly --
#
# Quoting, escaping or splitting a word across a quote boundary changes what
# the hook's lexer sees and nothing about what bash executes: `bash "-"c` runs
# the code argument exactly as `bash -c` does. Each attack spelling is its own
# row. Single and double quotes are SEPARATE branches of the lexer, so a split
# word is pinned in both styles: with one style unpinned, a one-line regression
# in the other branch reopens the bypass with the suite green.
# The last two rows are the price of reading words as bash builds them: a word
# that decodes to a code flag or to an interpreter name without being meant as
# either. Pinned DENY as a decision, on this hook's stated direction for an
# unresolvable case.

case_code_flag_and_interpreter_spellings_deny() {
    local inv='git commit -m x'
    assert_verdict "$inv" DENY "bare write (positive control for this group)"
    assert_verdict "bash '-c' '${inv}'" DENY "single-quoted code flag"
    assert_verdict "bash \"-c\" '${inv}'" DENY "double-quoted code flag"
    assert_verdict "bash -\"c\" '${inv}'" DENY \
        "code flag split across a quote boundary (-\"c\")"
    assert_verdict "bash \"-\"c '${inv}'" DENY \
        "code flag split across a quote boundary (\"-\"c)"
    assert_verdict "bash -'c' '${inv}'" DENY \
        "code flag split across a single-quote boundary (-'c')"
    assert_verdict "bash '-'c '${inv}'" DENY \
        "code flag split across a single-quote boundary ('-'c)"
    assert_verdict "bash \\-c '${inv}'" DENY "backslash-escaped code flag"
    assert_verdict "bash \\"$'\n'"-c '${inv}'" DENY \
        "code flag reached across a line continuation"
    assert_verdict "'bash' -c '${inv}'" DENY "single-quoted interpreter word"
    assert_verdict "\"bash\" -c '${inv}'" DENY "double-quoted interpreter word"
    assert_verdict "ba\"sh\" -c '${inv}'" DENY \
        "interpreter word split across a quote boundary"
    assert_verdict "ba'sh' -c '${inv}'" DENY \
        "interpreter word split across a single-quote boundary"
    assert_verdict "/bin/ba'sh' -c '${inv}'" DENY \
        "pathed interpreter word split across a single-quote boundary"
    assert_verdict "\\bash -c '${inv}'" DENY "backslash-escaped interpreter word"
    assert_verdict "bash deploy.sh '-c' 'the summary says git commit -m x was blocked'" \
        DENY "a quoted -c argv element of a script qualifies the next group as code"
    assert_verdict "grep 'sh' -c 'the summary says git commit -m x was blocked' notes.md" \
        DENY "a quoted data word decoding to an interpreter name qualifies the next group as code"
}

# ---- HEREDOC BODIES: a quoted delimiter makes the body prose -------------
#
# `cat > f <<'EOF'` cannot expand or execute anything in its body, so a body
# naming a git write is prose. An unquoted delimiter (`<<EOF`) does expand, so
# its body keeps reaching the matcher unmarked.

case_heredoc_body_prose() {
    local prose='the summary says git commit -m x was blocked'
    assert_verdict "cat > \"\$TMPDIR/f.txt\" <<'EOF'"$'\n'"${prose}"$'\nEOF' \
        ALLOW "single-quoted heredoc delimiter: body is prose"
    assert_verdict "cat > \"\$TMPDIR/f.txt\" <<\"EOF\""$'\n'"${prose}"$'\nEOF' \
        ALLOW "double-quoted heredoc delimiter: body is prose"
    assert_verdict "cat > \"\$TMPDIR/f.txt\" <<\\EOF"$'\n'"${prose}"$'\nEOF' \
        ALLOW "backslash-quoted heredoc delimiter: body is prose"
    assert_verdict "cat > \"\$TMPDIR/f.txt\" <<-'EOF'"$'\n\t'"${prose}"$'\n\tEOF' \
        ALLOW "tab-stripping quoted heredoc delimiter: body is prose"
    assert_verdict "cat > \"\$TMPDIR/f.txt\" <<'EOF'"$'\n'"${prose}"$'\nEOF\ngit commit -m x' \
        DENY "real invocation on the line after a quoted heredoc ends"
    assert_verdict "cat > \"\$TMPDIR/f.txt\" <<EOF"$'\n''git commit -m x'$'\nEOF' \
        DENY "unquoted heredoc delimiter: body still reaches the matcher"
    assert_verdict "cat > \"\$TMPDIR/f.txt\" <<'EOF'"$'\n\tEOF\n''git commit -m x'$'\nEOF' \
        ALLOW "tab-indented EOF does not end a plain quoted heredoc body"
    # The body ends at its own newline, not at a space: a body whose last word
    # is `git` must not merge with the words on the line after the terminator
    # into one record the matcher reads as a write.
    assert_verdict "cat > \"\$TMPDIR/f.txt\" <<'EOF'"$'\n''the summary names git'$'\nEOF\ncommit -m x' \
        ALLOW "a quoted heredoc body ends at its own line, not at the next one"
    # Cross-line state must not survive the construct that set it: each of
    # these opens a real heredoc AFTER a construct the pre-pass tracks.
    assert_verdict "# a note"$'\n'"cat > \"\$TMPDIR/f.txt\" <<'EOF'"$'\n'"${prose}"$'\nEOF' \
        ALLOW "a comment on the line before does not disarm the heredoc after it"
    assert_verdict 'n=$((1 << 3))'$'\n'"cat > \"\$TMPDIR/f.txt\" <<'EOF'"$'\n'"${prose}"$'\nEOF' \
        ALLOW "an arithmetic expansion closes, so the heredoc after it still opens"
    assert_verdict "cat > notes#1.txt <<'EOF'"$'\n'"${prose}"$'\nEOF' \
        ALLOW "a # inside an unquoted word is not a comment, so the heredoc still opens"
}

# ---- HEREDOC DESTINATION: a quoted delimiter is inert only to THIS shell ----
#
# `<<'EOF'` stops the OUTER shell expanding the body; it says nothing about
# what reads it. `cat` writes the body to a file, so the body is data. `bash`
# runs it as a script, so the body is code and a git write in it executes.
# Only a text sink gets its body marked as prose.

case_heredoc_body_destination() {
    assert_verdict "bash <<'EOF'"$'\n''git commit -m x'$'\nEOF' \
        DENY "quoted heredoc fed to bash: the inner shell runs the body"
    assert_verdict "sh <<'X'"$'\n''git commit -m x'$'\nX' \
        DENY "quoted heredoc fed to sh: the inner shell runs the body"
    assert_verdict "/bin/bash <<'EOF'"$'\n''git commit -m x'$'\nEOF' \
        DENY "quoted heredoc fed to a pathed interpreter"
    assert_verdict "tee \"\$TMPDIR/f.txt\" <<'EOF'"$'\n''the summary says git commit -m x was blocked'$'\nEOF' \
        ALLOW "quoted heredoc fed to tee: body is prose"
}

# ---- COMMENTS: inert to bash, so inert here ---------------------------------
#
# A comment runs to the end of its line and bash executes none of it. Anything
# the pre-pass reads inside one -- a quote that would otherwise open a region
# spanning the newline, a heredoc operator that would otherwise arm a body --
# is text, so the whole comment is consumed as one prose group and the command
# on the next line reaches the matcher on its own.

case_comment_regions_are_inert() {
    assert_verdict "# it's blocked by the gate"$'\n''git commit -m x' \
        DENY "an apostrophe inside a comment does not swallow the next line"
    assert_verdict '# the gate says "blocked"'$'\n''git commit -m x' \
        DENY "a double quote inside a comment does not swallow the next line"
    assert_verdict "echo hi # don't do that"$'\n''git commit -m x' \
        DENY "an apostrophe inside a trailing comment does not swallow the next line"
    assert_verdict "(echo one)#<<'EOF'"$'\n''git commit -m x' \
        DENY "a comment opened right after ) arms no heredoc"
    assert_verdict "echo one >#note"$'\n''git commit -m x' \
        DENY "a comment opened right after > arms no heredoc"
    assert_verdict '# git commit -m x is what the gate blocks' \
        ALLOW "a comment naming the guarded write is prose"
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
    assert_verdict "grep foo <<<\"bar\""$'\n''git commit -m x' \
        DENY "here-string with a double-quoted word is not a heredoc"
    assert_verdict "grep foo <<<'bar'"$'\n''git commit -m x' \
        DENY "here-string with a single-quoted word is not a heredoc"
    assert_verdict "cat <<A <<'B'"$'\n''$(git commit -m x)'$'\nA\nB' \
        DENY "two heredocs on one line keep their own quotedness in order"
    assert_verdict "# a note about <<'EOF' bodies"$'\n''git commit -m x' \
        DENY "a heredoc operator inside a whole-line comment opens no body"
    assert_verdict "echo hi  # uses <<'EOF' style"$'\n''git commit -m x' \
        DENY "a heredoc operator inside a trailing comment opens no body"
    assert_verdict "cat > \"\$TMPDIR/f.txt\" <<-'EOF'"$'\n\tprose\n\tEOF\n''git commit -m x' \
        DENY "a tab-indented terminator ends a <<- body, and the next line is code"
    assert_verdict 'n=$((1 << 3))'$'\n''echo "the summary says git commit -m x was blocked"' \
        ALLOW "an arithmetic shift opens no heredoc, so the prose after it stays prose"
    assert_verdict '((n = 1 << 3))'$'\n''echo "the summary says git commit -m x was blocked"' \
        ALLOW "a bare arithmetic command opens no heredoc either"
    assert_verdict 'for ((i = 1 << 2; i > 0; i--)); do echo $i; done'$'\n''echo "the summary says git commit -m x was blocked"' \
        ALLOW "an arithmetic for header opens no heredoc either"
    assert_verdict 'n=$[1 << 3]'$'\n''echo "the summary says git commit -m x was blocked"' \
        ALLOW "a deprecated \$[ ] arithmetic shift opens no heredoc either"
    # ACCEPTED INACCURACY (hook header): bash's own $BASH_COMMAND
    # reconstruction moves a here-string redirect to the end of the line,
    # so "git" no longer sits next to "commit" for the word-adjacency scan
    # to catch — a false ALLOW, but not a missed dispatch: "commit", "-m",
    # "x" are cat's file arguments here, and "git" is only cat's stdin
    # source, so nothing runs `git commit` as a command. Pinned as the
    # CURRENT verdict, not endorsed as correct.
    assert_verdict 'cat <<<git commit -m x' \
        ALLOW "here-string with an unquoted word: accepted false ALLOW, not a real dispatch"
}

# ---- Circuit breaker: a cap hit is the probe's finding, not the caller's ---
#
# The 2000-leaf ceiling reaches the script through a marker the probe writes
# beside the leaf buffer, never through a token inside it, so caller text
# cannot counterfeit one. A command that merely quotes the marker is an
# ordinary command; only a command that really enumerates past the ceiling is
# refused for size, and it must still say so.

case_leaf_cap_is_out_of_band() {
    local marker cmd i err
    marker='__CAP_HIT__'
    assert_verdict "echo ${marker}" ALLOW \
        "a single leaf whose text is the cap marker is not a cap hit"
    assert_verdict "cat <<'EOF'"$'\n'"prose naming ${marker} inline"$'\n'"EOF" \
        ALLOW "a heredoc quoting the cap marker is not a cap hit"
    cmd="echo 0"
    for ((i = 1; i <= 2100; i++)); do cmd="${cmd}; echo ${i}"; done
    assert_verdict "$cmd" DENY "over 2000 leaves still hits the cap"
    err=$(PATH="$PATH_WITH_DOCKET" GATE_STATE=unapproved "$BASH_BIN" "$HOOK" 2>&1 >/dev/null <<<"$(build_input "$cmd")")
    case "$err" in
        *"too many parts (over 2000)"*) pass "a real cap hit still explains itself as size" ;;
        *) fail "cap deny reason changed or missing: ${err}" ;;
    esac
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
    assert_verdict "echo${groups} 'never run git commit here'" ALLOW \
        "400 quoted groups then one prose group stays prose"
    assert_verdict "echo${groups}; git commit -m x" DENY \
        "the verb after 400 quoted groups is still caught"
}

# ---- Missing shared pre-pass file: fail CLOSED, not open ------------------
#
# The awk PROGRAM this hook's quote-group pass runs now lives in a sibling
# file, docket-guard-prepass.awk, rather than inline (DOT-1499). A hook copy
# with no sibling awk file beside it (a broken install) must DENY, not
# silently allow every call: this hook's whole job is deciding whether a git
# write is present, and with no lexer it cannot make that call. The deny
# fires before the engine gate query, so no docket stub is needed on PATH.

case_missing_prepass_file_denies() {
    local scratch_dir scratch_hook err rc
    scratch_dir=$(mktemp -d "${TMPDIR:-/tmp}/docket-commit-guard-prepass-missing.XXXXXX") || \
        fatal "mktemp failed"
    scratch_hook="${scratch_dir}/docket-commit-guard-hook.sh"
    cp "$HOOK" "$scratch_hook" || fatal "could not copy hook to scratch dir"
    # Deliberately no docket-guard-prepass.awk beside the copy.
    PATH="$TOOLS_DIR" "$BASH_BIN" "$scratch_hook" >/dev/null 2>&1 \
        <<<"$(build_input 'git commit -m x')"
    rc=$?
    if [ "$rc" -eq 2 ]; then
        pass "hook copy with no sibling awk file denies (exit 2)"
    else
        fail "hook copy with no sibling awk file did not deny (exit ${rc})"
    fi
    err=$(PATH="$TOOLS_DIR" "$BASH_BIN" "$scratch_hook" 2>&1 >/dev/null \
        <<<"$(build_input 'git commit -m x')")
    case "$err" in
        *"docket-guard-prepass.awk"*) pass "missing-file deny names the cause" ;;
        *) fail "missing-file deny reason changed or missing: ${err}" ;;
    esac
    rm -rf "$scratch_dir"
}

# ---- Pre-pass drift: the two guard hooks must share one lexer file --------
#
# The quote-aware pre-pass used to be duplicated byte-for-byte in the commit
# guard and the trust guard, with no sourcing mechanism available (each hook
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

# ---- Malformed / non-Bash input: fail open, never mid-parse --------------

case_input_edge_cases() {
    assert_verdict_raw '{"tool_name":"Read","tool_input":{"file_path":"x"}}' \
        ALLOW "non-Bash tool_name allows regardless of command content"
    assert_verdict_raw '{"tool_name":"Bash","tool_input":{"command":""}}' \
        ALLOW "empty command string allows"
    assert_verdict_raw '{"tool_name":"Bash"}' \
        ALLOW "missing tool_input allows"
    assert_verdict_raw 'not json at all' \
        ALLOW "malformed (non-JSON) stdin fails open to allow"
    assert_verdict_raw '' \
        ALLOW "empty stdin fails open to allow"
}

case_engine_verdict_mapping
case_permission_mode_is_not_consulted
case_must_deny_baseline
case_must_deny_glued_separator_class
case_must_deny_capture_output
case_must_deny_terminal_position
case_must_allow_terminal_fix_negative_controls
case_must_allow_computed_subcommand_residual
case_must_allow_help_exemption
case_accepted_false_positive_control
case_must_not_catch_prose_and_reads
case_must_not_catch_substitution_reads
case_accepted_residual_risks
case_interpreter_code_argument_deny
case_code_flag_and_interpreter_spellings_deny
case_heredoc_body_prose
case_heredoc_body_destination
case_comment_regions_are_inert
case_heredoc_position_edges
case_leaf_cap_is_out_of_band
case_many_quoted_groups_on_one_line
case_missing_prepass_file_denies
case_prepass_copies_identical
case_input_edge_cases

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"

if [ "$FAIL" -ne 0 ]; then
    exit 1
fi

exit 0
