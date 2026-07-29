#!/bin/bash

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
HOOK="${REPO_ROOT}/src/user/claude-code/hooks/guard-no-commit-hook.sh"

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

# Classifies one hook run as DENY (exit 2), ASK (exit 0 with a structured
# permissionDecision:"ask" payload), or ALLOW (exit 0, no such payload).
# ASK and ALLOW share exit 0, so telling them apart requires checking this
# one structural field by name/value - never the human-readable reason
# string, which is free to reword without being a behavior change.
verdict_of() {
    local input="$1" out rc
    out=$(printf '%s' "$input" | bash "$HOOK" 2>/dev/null)
    rc=$?
    if [ "$rc" -eq 2 ]; then
        printf 'DENY'
    elif printf '%s' "$out" | jq -e '.hookSpecificOutput.permissionDecision == "ask"' >/dev/null 2>&1; then
        printf 'ASK'
    else
        printf 'ALLOW'
    fi
}

build_input() {
    local mode="$1" cmd="$2"
    jq -nc --arg c "$cmd" --arg m "$mode" \
        '{tool_name:"Bash",tool_input:{command:$c},permission_mode:$m}'
}

assert_verdict() {
    local mode="$1" cmd="$2" want="$3" label="$4" got
    got=$(verdict_of "$(build_input "$mode" "$cmd")")
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

# ---- MUST DENY: baseline invocations, unchanged by this change -----------

case_must_deny_baseline() {
    assert_verdict auto "git commit -m 'x'" DENY "plain git commit (auto)"
    assert_verdict default "git commit -m 'x'" ASK "plain git commit (default) routes to ask"
    assert_verdict plan "git commit -m 'x'" ASK "plain git commit (plan) routes to ask"
    assert_verdict acceptEdits "git commit -m 'x'" ASK "plain git commit (acceptEdits) routes to ask"
    assert_verdict dontAsk "git commit -m 'x'" DENY "plain git commit (dontAsk)"
    assert_verdict bypassPermissions "git commit -m 'x'" DENY "plain git commit (bypassPermissions)"
    assert_verdict auto "git add src/foo.rs" DENY "git add"
    assert_verdict auto "git push origin main" DENY "git push"
    assert_verdict auto "cd /x && git commit -m y" DENY "&& git commit"
    assert_verdict auto "git -C /repo commit -m y" DENY "git -C <path> commit"
    assert_verdict auto "git --no-pager push" DENY "git --no-pager push"
    assert_verdict auto "/usr/bin/git commit -m y" DENY "/usr/bin/git commit"
    assert_verdict auto "git -c user.email=x commit -m y" DENY "git -c <val> commit"
    assert_verdict auto "git 'commit' -m y" DENY "git 'commit' (quoted subcommand, bare head)"
}

# ---- MUST DENY: glued separator/no-space class (5 shapes) ----------------
# A separator or subshell-open glued directly onto `git` with no whitespace
# still resolves to a head of "git" via the fix-1 head-normalization, so all
# five must deny with zero human interaction - a future tokenizer change
# reopening any one of these would silently regress the operator's bar.

case_must_deny_glued_separator_class() {
    assert_verdict auto "cd /x &&git commit -m msg" DENY "&&git commit (no space)"
    assert_verdict auto "cd /x ;git commit -m msg" DENY ";git commit (no space)"
    assert_verdict auto "false ||git commit -m msg" DENY "||git commit (no space)"
    assert_verdict auto "cd /x &git commit -m msg" DENY "&git commit (single ampersand, no space)"
    assert_verdict auto "(git commit -m y)" DENY "(git commit (subshell, no space)"
}

# ---- MUST DENY: fix 1, command-substitution capture-output shapes --------
# (the ruling this change closes - previously ALLOWed with zero human
# interaction, a direct violation of the mode-dependent ask/deny floor)

case_must_deny_capture_output_fix() {
    assert_verdict auto 'X=$(git commit -m y)' DENY 'X=$(git commit -m y) capture-output'
    assert_verdict auto 'MSG=$(git commit -m x 2>&1)' DENY 'MSG=$(git commit -m x 2>&1) capture-output'
    assert_verdict auto 'echo "$(git commit -m x)"' DENY 'echo "$(git commit -m x)" capture-output'
    assert_verdict auto 'OUT=`git push origin main`' DENY 'OUT=`git push origin main` backtick capture'
    assert_verdict auto '$(git add -A)' DENY 'bare $(git add -A)'
}

# ---- MUST DENY: fix 3, terminal-position subcommand normalization --------
# (round-2 cold review finding: fix 1's head-normalization only stripped a
# glued delimiter BEFORE "git" - a delimiter glued directly AFTER the
# subcommand with nothing else following was never stripped, so these
# terminal-position shapes silently ALLOWed with zero human interaction even
# though the equivalent medial forms above were already closed by fix 1)

case_must_deny_terminal_position_fix() {
    assert_verdict auto 'git push;' DENY 'bare git push; terminal separator'
    assert_verdict auto 'git commit;' DENY 'bare git commit; terminal separator'
    assert_verdict auto 'git add;' DENY 'bare git add; terminal separator'
    assert_verdict auto 'git push&' DENY 'bare git push& terminal separator'
    assert_verdict auto 'git push|cat' DENY 'git push|cat terminal pipe'
    assert_verdict auto 'git push>out.log' DENY 'git push>out.log terminal redirect'
    assert_verdict auto 'X=$(git push)' DENY 'X=$(git push) terminal capture-output, no trailing content'
    assert_verdict auto 'X=$(git add)' DENY 'X=$(git add) terminal capture-output, no trailing content'
    assert_verdict auto 'X=`git push`' DENY 'X=`git push` terminal backtick capture (assignment-glued), no trailing content'
    assert_verdict auto '`git push`' DENY 'bare `git push` terminal backtick capture, no trailing content'
    assert_verdict auto '(git push)' DENY '(git push) terminal subshell, no trailing content'
    assert_verdict auto '(git commit)' DENY '(git commit) terminal subshell, no trailing content'
    assert_verdict auto '{ git push; }' DENY '{ git push; } terminal brace group'
}

# ---- MUST ALLOW: negative controls for the terminal-position fix ---------
# (a prior attempt at this same fix shape over-matched on these query/
# wrapper forms - locked in here so a future edit can't silently regress)

case_must_allow_terminal_fix_negative_controls() {
    assert_verdict auto 'command -v git' ALLOW 'command -v git (query, no subcommand follows)'
    assert_verdict auto 'which git' ALLOW 'which git (query, no subcommand follows)'
    assert_verdict auto 'type git' ALLOW 'type git (query, no subcommand follows)'
    assert_verdict auto 'nice -n 10 echo hi' ALLOW 'nice -n 10 <non-git command>'
}

# ---- MUST ALLOW: computed subcommand, accepted residual -------------------
# The verb "git" is literal, but the subcommand word is produced by
# expansion/substitution rather than appearing literally - the subcommand
# token truncates to empty at the first non-identifier character (`$` or a
# backtick) and never matches commit/push/add. Deliberate construction
# required (not a realistic accidental-mistake shape); accepted, documented
# residual per the header, not something this fix closes.

case_must_allow_computed_subcommand_residual() {
    assert_verdict auto 'git $(echo commit)' ALLOW 'git $(echo commit) computed subcommand'
    assert_verdict auto 'git $V' ALLOW 'git $V computed subcommand'
    assert_verdict auto 'git `echo commit`' ALLOW 'git `echo commit` computed subcommand'
}

# ---- MUST ALLOW: fix 2, option-before-subcommand help exemption ----------

case_must_allow_help_exemption_fix() {
    assert_verdict auto "git --help add" ALLOW "git --help add (long-flag exemption)"
    assert_verdict auto "git -h add" ALLOW "git -h add (short-flag exemption)"
}

# ---- MUST ALLOW: accepted false positive from deleting GIT_WRITE_SCRIPTS -
# The prior denial was the fail-closed registry design behaving correctly,
# not a defect - a generic interpreter invocation naming this script COULD
# legitimately execute it, so treating any mention conservatively was
# defensible even though `bash -n` specifically only syntax-checks and
# never executes. This is now accepted as a documented, deliberate false
# positive traded away alongside the rest of the registry (see the
# 7-shape accepted-regression case below for what else was traded).

case_must_allow_registry_deletion_accepted_fp() {
    assert_verdict auto "bash -n src/user/claude-code/scripts/commit_execute.sh" ALLOW "bash -n commit_execute.sh (syntax check, accepted FP - was fail-closed by design, not a bug)"
}

# ---- ACCEPTED FALSE POSITIVE: documented control row ---------------------
# Deliberately NOT fixed - closing it would require scanning past the
# subcommand for a trailing flag, which would let a commit message merely
# containing the text "--help" wrongly ALLOW. This row exists so a future
# edit cannot silently change this behavior without a deliberate test
# change - see the hook's header comment for the same ruling.

case_accepted_false_positive_control() {
    assert_verdict auto "git commit --help" DENY "git commit --help (accepted FP, subcommand-before-flag NOT exempted)"
}

# ---- MUST NOT CATCH: prose / read-only, differential parity --------------
# (untouched logic: quote-group pre-pass, decode(), and the subcommand
# allowlist of commit/push/add)

case_must_not_catch_prose_and_reads() {
    assert_verdict auto 'docket issue comment add D-1 -m "do not git commit here"' ALLOW "prose mentioning git commit inside -m body"
    assert_verdict auto 'docket issue comment add D-1 -m "never git add or git push"' ALLOW "prose mentioning git add/push inside -m body"
    assert_verdict auto "git log --oneline -5" ALLOW "git log"
    assert_verdict auto "git status" ALLOW "git status"
    assert_verdict auto "git diff HEAD" ALLOW "git diff"
    assert_verdict auto "git remote add up http://u" ALLOW "git remote add (subcommand is remote, not add)"
    assert_verdict auto "git submodule add http://u p" ALLOW "git submodule add"
    assert_verdict auto "git worktree add ../wt" ALLOW "git worktree add"
    assert_verdict auto "echo 'the phrase git commit appears here'" ALLOW "single-quoted prose"
}

# ---- MUST NOT CATCH: unchanged ALLOW, but for a DIFFERENT reason now -----
# Pre-diff this ALLOWed because shellcheck was on the now-deleted
# INERT_READERS list, which suppressed the GIT_WRITE_SCRIPTS registry match
# on the commit_execute.sh filename token that followed it. Post-diff there
# is no registry and no inert-reader list at all - this command has no
# "git" token in it, so it trivially allows. Net externally unchanged
# (ALLOW before and after), but NOT because of "untouched logic" like the
# group above - both the mechanism that used to explain this ALLOW and the
# thing it protected against are gone.

case_shellcheck_provenance_note() {
    assert_verdict auto "shellcheck src/user/claude-code/scripts/commit_execute.sh" ALLOW "shellcheck of commit_execute.sh (unchanged ALLOW, provenance shifted from deleted INERT_READERS to trivial no-git-token)"
}

# ---- MUST NOT CATCH: substitution-READ shapes -----------------------------
# (new-false-positive-risk check on fix 1 - the head-normalization must not
# start denying a read whose captured output never performs a write)

case_must_not_catch_substitution_reads() {
    assert_verdict auto 'SHA=$(git log -1 --format=%H)' ALLOW 'SHA=$(git log -1) substitution read'
    assert_verdict auto 'B=$(git rev-parse --abbrev-ref HEAD)' ALLOW 'B=$(git rev-parse) substitution read'
    assert_verdict auto 'echo "$(git status --short)"' ALLOW 'echo "$(git status)" substitution read'
    assert_verdict auto 'N=$(git remote add up http://u)' ALLOW 'N=$(git remote add ...) substitution read'
    assert_verdict auto 'F=$(ls src)' ALLOW 'F=$(ls src) non-git substitution'
    assert_verdict auto 'D=$(realpath src/foo)' ALLOW 'D=$(realpath ...) non-git substitution'
}

# ---- ACCEPTED RESIDUAL RISKS: unchanged by design, per hook header --------
# (shell indirection and wrapper-script invocation remain structurally
# invisible to this hook's only input - documented, operator-accepted)

case_accepted_residual_risks() {
    assert_verdict auto 'bash -c "git commit -m x"' ALLOW "bash -c indirection (accepted residual)"
    assert_verdict auto "./deploy.sh" ALLOW "wrapper-script invocation (accepted residual)"
}

# ---- ACCEPTED, OPERATOR-APPROVED COVERAGE REGRESSION (deliberate) --------
# Before this diff, the now-deleted GIT_WRITE_SCRIPTS registry named
# commit_execute.sh specifically and correctly DENIED all 7 of these
# invocation shapes (measured against git HEAD's pre-diff hook). This diff
# removes that registry - all 7 now silently ALLOW. This is the one
# deliberate regression in the diff, operator-accepted as a real, measured
# trade (see the hook and commit_execute.sh headers for the full framing) -
# not a silently-uncovered gap. If any of these ever needs to flip back to
# DENY, that is a new decision, not a "test caught a regression" one.

case_accepted_registry_regression_7_shapes() {
    local script="src/user/claude-code/scripts/commit_execute.sh"
    assert_verdict auto "bash ${script} draft.txt file1.txt" ALLOW "1/7 bash <path> (interpreter-prefixed: bash)"
    assert_verdict auto "sh ${script} draft.txt file1.txt" ALLOW "2/7 sh <path> (interpreter-prefixed: sh)"
    assert_verdict auto "./${script} draft.txt file1.txt" ALLOW "3/7 ./<relative path> (direct exec)"
    assert_verdict auto "${script} draft.txt file1.txt" ALLOW "4/7 <bare path, no ./> (direct exec)"
    assert_verdict auto "\"\$HOME/repo/${script}\" draft.txt file1.txt" ALLOW "5/7 quoted \$HOME-style path"
    assert_verdict auto "timeout 30 bash ${script} draft.txt file1.txt" ALLOW "6/7 timeout-wrapper form"
    assert_verdict auto "env bash ${script} draft.txt file1.txt" ALLOW "7/7 env-wrapper form"
}

# ---- Permission-mode / malformed-input edge cases (unchanged parsing) -----

case_permission_mode_and_input_edge_cases() {
    assert_verdict_raw '{"tool_name":"Read","tool_input":{"file_path":"x"},"permission_mode":"auto"}' \
        ALLOW "non-Bash tool_name allows regardless of command content"
    assert_verdict_raw '{"tool_name":"Bash","tool_input":{"command":""},"permission_mode":"auto"}' \
        ALLOW "empty command string allows"
    assert_verdict_raw 'not json at all' \
        ALLOW "malformed (non-JSON) stdin fails open to allow"
    assert_verdict_raw '{"tool_name":"Bash","tool_input":{"command":"git commit -m y"}}' \
        DENY "missing permission_mode on an actual git write fails closed (deny), not open"
    assert_verdict_raw '{"tool_name":"Bash","tool_input":{"command":"git commit -m y"},"permission_mode":"weirdmode"}' \
        DENY "unrecognized permission_mode value fails closed (deny), not open"
}

if [ ! -f "$HOOK" ]; then
    printf 'FATAL: hook not found at %s\n' "$HOOK" >&2
    exit 2
fi

if ! command -v jq >/dev/null 2>&1; then
    printf 'FATAL: jq is required to run this test\n' >&2
    exit 2
fi

case_must_deny_baseline
case_must_deny_glued_separator_class
case_must_deny_capture_output_fix
case_must_deny_terminal_position_fix
case_must_allow_terminal_fix_negative_controls
case_must_allow_computed_subcommand_residual
case_must_allow_help_exemption_fix
case_must_allow_registry_deletion_accepted_fp
case_accepted_false_positive_control
case_must_not_catch_prose_and_reads
case_shellcheck_provenance_note
case_must_not_catch_substitution_reads
case_accepted_residual_risks
case_accepted_registry_regression_7_shapes
case_permission_mode_and_input_edge_cases

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"

if [ "$FAIL" -ne 0 ]; then
    exit 1
fi

exit 0
