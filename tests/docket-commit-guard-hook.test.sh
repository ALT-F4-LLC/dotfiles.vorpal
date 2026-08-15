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
    assert_verdict 'bash -c "git commit -m x"' ALLOW "bash -c indirection (accepted residual)"
    assert_verdict "./deploy.sh" ALLOW "wrapper-script invocation (accepted residual)"
    assert_verdict "bash ${script}" ALLOW "bash <script path> (interpreter-prefixed, accepted residual)"
    assert_verdict "./${script}" ALLOW "./<script path> (direct exec, accepted residual)"
    assert_verdict "timeout 30 bash ${script}" ALLOW "timeout-wrapped script path (accepted residual)"
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
case_input_edge_cases

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"

if [ "$FAIL" -ne 0 ]; then
    exit 1
fi

exit 0
