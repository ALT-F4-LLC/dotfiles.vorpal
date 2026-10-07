#!/bin/bash

# Behavior suite for src/user/claude_code/hooks/docket-sibling-guard-hook.sh.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name.
#
# THE PROPERTY UNDER TEST is ownership-scoped: the same verb must DENY when
# its target is a sibling step's (another step's `STEP-N.d`, a checkout the
# caller did not make, a process it did not start) and ALLOW when the target
# is the caller's own — the bootstrap sweep of its own scratch dir above all,
# since a false deny there strands the step before it claims. Caller scope
# rides on top: an executor archetype is in, the main conversation and every
# identified non-executor seat are out, and an unidentified caller is in only
# when its transcript opens with a wave executor brief.
#
# DEFECT CLASS. Two failure directions, both silent in production:
#   FALSE ALLOW - an executor's `rm -rf` on a stranger's `STEP-N.d`, a
#     `git worktree remove` of a checkout it never made, or a `pkill`, goes
#     through because the target arrived in a spelling the matcher did not
#     read (quoted path, glob, `bash -c`, a variable set in the same call).
#   FALSE DENY  - the executor's own sweep, its own claim redirect, a jobspec
#     kill of its own server, prose that mentions a sibling's dir, or the
#     operator's / conductor's sweep from outside the executor scope, blocked.
#
# SEAM. No engine, no `docket` binary: one decision from stdin JSON plus a
# bounded read of the transcript named in it, and the exit code is the entire
# verdict. The hook's decision path needs only bash/cat/jq/awk, so most cases
# run it with PATH restricted to exactly those (the friction-log case runs
# with the full PATH, since logging is best-effort and may use more).

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
HOOK="${GUARD_HOOK:-${REPO_ROOT}/src/user/claude_code/hooks/docket-sibling-guard-hook.sh}"

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
# bash 5.2 parses a `$( )` body as it reads it and reprints the leaf from that
# parse: a comment in the body is gone, and a heredoc in a substitution that
# closed on its line takes the following lines as its body. The probe follows
# whichever bash runs the hook, so the pins on those two shapes do too.
if "$BASH_BIN" -c '[ "${BASH_VERSINFO[0]}" -gt 5 ] || { [ "${BASH_VERSINFO[0]}" -eq 5 ] && [ "${BASH_VERSINFO[1]}" -ge 2 ]; }'; then
    COMSUB_REPRINTED=1
else
    COMSUB_REPRINTED=0
fi

# Every fixture path lands in command text the hook reads, so the work root
# must not carry a `STEP-N.d` segment: a caller whose TMPDIR is its own step
# scratch dir would otherwise put a step id foreign to the STEP-42 fixture
# into every path. Cut the root back to the shared scratch root above it.
work_root_for() { # <tmpdir>
    local root="${1:-/tmp}"
    root="${root%%/STEP-[0-9]*}"
    printf '%s' "${root:-/tmp}"
}

WORK=$(mktemp -d "$(work_root_for "${TMPDIR:-}")/docket-sibling-guard-test.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT

TOOLS_DIR="${WORK}/tools"
mkdir -p "$TOOLS_DIR"
for tool in bash cat jq awk; do
    tool_path=$(command -v "$tool") || fatal "hook dependency ${tool} not found on PATH"
    ln -s "$tool_path" "${TOOLS_DIR}/${tool}"
done

# Transcript fixtures: the first record of a wave executor's transcript is
# its rendered brief, carrying the claim for its own step; a tribunal seat's
# opens with the proposal and a vote cast; the operator's is whatever they
# typed. The marker the hook reads is the wave spelling with a literal step
# id and `--owner wave:`, so the seat and operator fixtures must not carry it.
WAVE_42="${WORK}/wave-42.jsonl"
printf '%s\n' '{"type":"user","message":{"role":"user","content":"1. rm -rf <TMP>/STEP-42.d\nmkdir -m 700 <TMP>/STEP-42.d\ndocket step claim STEP-42 --owner wave:STEP-42:1 --render --metadata {} --json > <TMP>/STEP-42.d/STEP-42.claim.json\n..."}}' >"$WAVE_42"
WAVE_9393="${WORK}/wave-9393.jsonl"
printf '%s\n' '{"type":"user","message":{"role":"user","content":"docket step claim STEP-9393 --owner wave:STEP-9393:2 --render --json > <TMP>/STEP-9393.d/STEP-9393.claim.json"}}' >"$WAVE_9393"
SEAT="${WORK}/tribunal-seat.jsonl"
printf '%s\n' '{"type":"user","message":{"role":"user","content":"THE PROPOSAL:   DKT-V338\n...docket vote cast DKT-V338 --voter judge-security..."}}' >"$SEAT"
OPERATOR="${WORK}/operator.jsonl"
printf '%s\n' '{"type":"user","message":{"role":"user","content":"help me clean up /tmp/claude-501/STEP-7.d, and read the docket skill: docket step claim, docket vote cast"}}' >"$OPERATOR"
MISSING="${WORK}/does-not-exist.jsonl"

# Own-transcript resolution fixtures. Inside a subagent the harness hands the
# hook the PARENT conversation's transcript_path; the seat's own file sits
# under the session directory keyed by agent_id (Workflow seats under
# subagents/workflows/<run>/, Agent-tool seats directly under subagents/).
# RUN-103's first wave was stranded on exactly this shape: every executor
# read as `none` off the operator's transcript while its own carried the
# marker.
SESS_DIR="${WORK}/projects/proj/sess-1"
PARENT="${WORK}/projects/proj/sess-1.jsonl"
mkdir -p "${SESS_DIR}/subagents/workflows/wf_a"
cp "$OPERATOR" "$PARENT"
cp "$WAVE_42" "${SESS_DIR}/subagents/workflows/wf_a/agent-a1.jsonl"
cp "$WAVE_9393" "${SESS_DIR}/subagents/agent-a5.jsonl"
cp "$SEAT" "${SESS_DIR}/subagents/workflows/wf_a/agent-a4.jsonl"
: >"${SESS_DIR}/subagents/workflows/wf_a/agent-a3.jsonl"
UNRELATED="${WORK}/projects/proj/unrelated.jsonl"
cp "$OPERATOR" "$UNRELATED"

# run_hook <input>: one hook run on <input>, stdout and stderr passed through.
# A probe that never ends would stall the suite (and CI) instead of failing
# its row, and there is no portable `timeout`, so each run gets a CPU-time
# bound. The bound kills the spinning probe, not the hook, and the hook then
# carries on to a verdict; a run that lasted as long as the bound therefore
# returns 124 so the row reports it as such rather than as that verdict.
HOOK_CPU_LIMIT=20
run_hook() {
    local start=$SECONDS rc
    (
        ulimit -t "$HOOK_CPU_LIMIT"
        PATH="$TOOLS_DIR" HOME="${WORK}/home" exec "$BASH_BIN" "$HOOK"
    ) <<<"$1"
    rc=$?
    [ $((SECONDS - start)) -ge "$HOOK_CPU_LIMIT" ] && return 124
    return "$rc"
}

# Classifies one hook run as DENY (exit 2) or ALLOW (exit 0). No
# permissionDecision envelope is emitted -- exit 2 is a pre-permission hard
# stop and exit 0 is silence -- so the exit code is the entire verdict.
verdict_of() {
    local rc
    run_hook "$1" >/dev/null 2>&1
    rc=$?
    case "$rc" in
        2) printf 'DENY' ;;
        124) printf 'HOOK-RAN-TO-THE-%sS-CPU-BOUND' "$HOOK_CPU_LIMIT" ;;
        *) printf 'ALLOW' ;;
    esac
}

# deny_reason_of <command> <agent_type> <transcript>: the hook's stderr.
deny_reason_of() {
    local err rc
    err=$(run_hook "$(build_input "$1" "$2" "$3")" 2>&1 >/dev/null)
    rc=$?
    if [ "$rc" -eq 124 ]; then
        printf 'hook ran to the %ss CPU bound' "$HOOK_CPU_LIMIT"
    else
        printf '%s' "$err"
    fi
}

# build_input <command> <agent_type or ""> <transcript_path or "">
#
# The command travels on jq's stdin (-Rs), never as a --arg: an argument is
# one argv string, and Linux caps a single argument at 128 KiB, so a 300 KiB
# command passed by --arg makes jq fail and the builder emit nothing, which
# the hook then reads as an empty payload and allows.
build_input() {
    local cmd="$1" agent="${2:-}" transcript="${3:-}"
    printf '%s' "$cmd" | jq -Rsc --arg a "$agent" --arg t "$transcript" '
        {tool_name:"Bash", tool_input:{command:.}}
        | if $a != "" then .agent_type = $a else . end
        | if $t != "" then .transcript_path = $t else . end'
}

# build_sub_input <command> <agent_type> <agent_id> <session_id> <transcript_path>
build_sub_input() {
    printf '%s' "$1" | jq -Rsc --arg a "$2" --arg id "$3" --arg s "$4" --arg t "$5" '
        {tool_name:"Bash", tool_input:{command:.}, agent_id:$id, session_id:$s, transcript_path:$t}
        | if $a != "" then .agent_type = $a else . end'
}

# assert_sub_verdict <command> <agent_type> <agent_id> <session_id> <transcript_path> <ALLOW|DENY> <label>
assert_sub_verdict() {
    local got
    got=$(verdict_of "$(build_sub_input "$1" "$2" "$3" "$4" "$5")")
    if [ "$got" = "$6" ]; then
        pass "$7 ($6)"
    else
        fail "$7 (want $6, got ${got})"
    fi
}

# assert_verdict <command> <agent_type> <transcript> <ALLOW|DENY> <label>
assert_verdict() {
    local cmd="$1" agent="$2" transcript="$3" want="$4" label="$5" got
    got=$(verdict_of "$(build_input "$cmd" "$agent" "$transcript")")
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
# reason prefix and name what to do instead, so a narrowing of the matcher
# cannot silently swap the executor-facing text for a different one.
DENY_PREFIX='sibling-destructive verb blocked:'

# assert_deny_reason <command> <agent_type> <transcript> <phrase> <label>
assert_deny_reason() {
    local phrase="$4" label="$5" err
    err=$(deny_reason_of "$1" "$2" "$3")
    case "$err" in
        "${DENY_PREFIX}"*) pass "${label} (reason prefix unchanged)" ;;
        *) fail "${label} (reason prefix changed or missing: ${err})" ;;
    esac
    case "$err" in
        *"${phrase}"*) pass "${label} (reason names: ${phrase})" ;;
        *) fail "${label} (reason no longer says '${phrase}': ${err})" ;;
    esac
}

# assert_deny_reason_lacks <command> <agent_type> <transcript> <phrase> <label>
assert_deny_reason_lacks() {
    local phrase="$4" label="$5" err
    err=$(deny_reason_of "$1" "$2" "$3")
    case "$err" in
        "${DENY_PREFIX}"*"${phrase}"*) fail "${label} (reason says '${phrase}': ${err})" ;;
        "${DENY_PREFIX}"*) pass "${label} (reason does not say: ${phrase})" ;;
        *) fail "${label} (not denied: ${err})" ;;
    esac
}

OWN_DIR='/tmp/claude-501/STEP-42.d'
SIB_DIR='/tmp/claude-501/STEP-7.d'

# --- The four acceptance cases. --------------------------------------------
case_acceptance() {
    assert_verdict "rm -rf ${SIB_DIR}" executor-write "$WAVE_42" DENY "executor-write: rm -rf another step's STEP-N.d"
    assert_verdict "git worktree remove /repo/.claude/worktrees/wf_abc-1" executor-write "$WAVE_42" DENY "executor-write: git worktree remove of a checkout it did not create"
    assert_verdict "pkill -f vorpal" executor-read "$WAVE_42" DENY "executor-read: pkill"
    assert_verdict "rm -rf ${OWN_DIR}" executor-write "$WAVE_42" ALLOW "executor-write: own-dir sweep"
    assert_verdict "docket run conduct RUN-5" executor-read "$WAVE_42" DENY "executor-read: docket run conduct"
}

# --- The bootstrap and hand-back sequence the brief dictates stays allowed. --
case_own_bootstrap_allows() {
    assert_verdict "mkdir -m 700 ${OWN_DIR}" executor-write "$WAVE_42" ALLOW "own: mkdir -m 700"
    assert_verdict "docket step claim STEP-42 --owner wave:STEP-42:1 --render --json > ${OWN_DIR}/STEP-42.claim.json" executor-write "$WAVE_42" ALLOW "own: claim redirect"
    assert_verdict "jq -r '.data.token' ${OWN_DIR}/STEP-42.claim.json > ${OWN_DIR}/STEP-42.token" executor-write "$WAVE_42" ALLOW "own: token extraction"
    assert_verdict "chmod 600 ${OWN_DIR}/STEP-42.token" executor-write "$WAVE_42" ALLOW "own: chmod token"
    assert_verdict "cat /dev/null > ${OWN_DIR}/STEP-42.claim.json" executor-write "$WAVE_42" ALLOW "own: truncate claim file"
    assert_verdict "docket step record STEP-42 --artifact-file ${OWN_DIR}/STEP-42-findings.md < ${OWN_DIR}/STEP-42.token" executor-write "$WAVE_42" ALLOW "own: record from token file"
    assert_verdict "rm -rf ${OWN_DIR}/probe-copy" executor-read "$WAVE_42" ALLOW "own: rm of a probe copy inside own dir"
    assert_verdict "find ${OWN_DIR} -name '*.pid' -delete" executor-write "$WAVE_42" ALLOW "own: find -delete inside own dir"
    assert_verdict "git add -A" executor-write "$WAVE_42" ALLOW "own: git add (commit guard's domain)"
    # The probe's leaf counter shares a shell with the analyzed command; a
    # command that assigns `n` used to move the counter and trip the cap.
    assert_verdict 'for n in 100 833 922 1324 2026; do echo "$n"; done' executor-write "$WAVE_42" ALLOW "own: for n in … loop (the probe counter does not collide with the command)"
    assert_verdict "git commit -m 'feat(x): y'" executor-write "$WAVE_42" ALLOW "own: git commit (commit guard's domain)"
    assert_verdict "git rev-parse HEAD" executor-write "$WAVE_42" ALLOW "own: git rev-parse"
    assert_verdict "cargo test --locked --offline" executor-write "$WAVE_42" ALLOW "own: cargo test"
}

# --- Caller scope. ----------------------------------------------------------
case_scope() {
    assert_verdict "rm -rf ${SIB_DIR}" "" "$OPERATOR" ALLOW "main conversation: sweeping a step dir stays the operator's"
    assert_verdict "pkill -f vorpal" "" "$OPERATOR" ALLOW "main conversation: pkill stays with the harness"
    assert_verdict "rm -rf ${SIB_DIR}" docket-conductor-RUN-5 "$WAVE_42" ALLOW "conductor seat: the dead-executor sweep is its job"
    assert_verdict "git worktree prune" docket-conductor-RUN-5 "$OPERATOR" ALLOW "conductor seat: worktree prune out of scope"
    assert_verdict "rm -rf ${SIB_DIR}" general-purpose "$WAVE_42" ALLOW "general-purpose seat: not in scope even with a wave transcript"
    assert_verdict "rm -rf ${SIB_DIR}" Explore "$OPERATOR" ALLOW "Explore seat: not in scope"
    assert_verdict "rm -rf ${SIB_DIR}" executor "$WAVE_42" ALLOW "bare 'executor' is not an archetype"
    assert_verdict "rm -rf ${SIB_DIR}" executor-writer "$WAVE_42" ALLOW "near-miss archetype name"
    assert_verdict "rm -rf ${SIB_DIR}" executor-research "$WAVE_42" DENY "executor-research: in scope"
    assert_verdict "rm -rf ${SIB_DIR}" executor-read "$WAVE_42" DENY "executor-read: in scope"
    # Workflow-spawned seat whose agent_type arrives empty: the transcript's
    # own brief puts it in scope and names its step.
    assert_verdict "rm -rf ${SIB_DIR}" "" "$WAVE_42" DENY "agent_type absent, wave brief in transcript: foreign dir denied"
    assert_verdict "rm -rf ${OWN_DIR}" "" "$WAVE_42" ALLOW "agent_type absent, wave brief in transcript: own sweep allowed"
    # A tribunal seat's brief is not the wave marker: unidentified and out of
    # scope (the operator's transcript can carry the same skill wording).
    assert_verdict "rm -rf ${SIB_DIR}" "" "$SEAT" ALLOW "agent_type absent, tribunal brief: not the wave marker, out of scope"
    assert_verdict "rm -rf ${SIB_DIR}" "" "$MISSING" ALLOW "agent_type absent, unreadable transcript: out of scope"
}

# --- The three own-step states. -------------------------------------------
case_own_step_states() {
    # KNOWN: pinned throughout. NONE: an executor archetype whose transcript
    # carries no claim holds no step, so every STEP-N.d is a stranger's.
    assert_verdict "rm -rf ${SIB_DIR}" executor-read "$SEAT" DENY "none: tribunal seat as executor-read, foreign dir denied"
    assert_verdict "rm -rf ${SIB_DIR}" executor-write "$OPERATOR" DENY "none: no claim in transcript, foreign dir denied"
    assert_verdict "git worktree remove ${OWN_DIR}/probe" executor-write "$OPERATOR" DENY "none: no own dir, so no own worktree either"
    assert_verdict "git branch -d step-42-probe" executor-write "$OPERATOR" DENY "none: no own step, so no own branch either"
    # UNKNOWN: no readable transcript. Own-id clauses are skipped and the call
    # is allowed (this hook family's direction when the target cannot be
    # identified); clauses needing no own id still deny.
    assert_verdict "rm -rf ${SIB_DIR}" executor-write "$MISSING" ALLOW "unknown: foreign dir allowed, pinned direction"
    assert_verdict "rm -rf ${SIB_DIR}" executor-write "" ALLOW "unknown: no transcript_path at all, foreign dir allowed"
    assert_verdict "git worktree remove /repo/.claude/worktrees/wf_x" executor-write "$MISSING" ALLOW "unknown: worktree remove allowed"
    assert_verdict "git branch -D feature/x" executor-write "$MISSING" ALLOW "unknown: branch delete allowed"
    assert_verdict "pkill -f node" executor-write "$MISSING" DENY "unknown: pkill still denied"
    assert_verdict "killall node" executor-write "$MISSING" DENY "unknown: killall still denied"
    assert_verdict "git worktree prune" executor-write "$MISSING" DENY "unknown: worktree prune still denied"
    assert_verdict "kill 1234" executor-write "$MISSING" DENY "unknown: kill by literal pid still denied"
}

# --- Own transcript resolved from agent_id. --------------------------------
case_own_transcript_from_agent_id() {
    # The shape that stranded RUN-103: agent_type present, transcript_path is
    # the parent's, the seat's own file under subagents/workflows/ carries the
    # marker. Resolution must find it: own dir allowed, a sibling's denied.
    assert_sub_verdict "rm -rf ${OWN_DIR}" executor-read a1 sess-1 "$PARENT" ALLOW "agent_id: workflow seat's own sweep allowed off its own transcript"
    assert_sub_verdict "mkdir -m 700 ${OWN_DIR}" executor-write a1 sess-1 "$PARENT" ALLOW "agent_id: workflow seat's own mkdir allowed"
    assert_sub_verdict "rm -rf ${SIB_DIR}" executor-read a1 sess-1 "$PARENT" DENY "agent_id: workflow seat still denied a sibling's dir"
    # Agent-tool shape: the file sits directly under subagents/.
    assert_sub_verdict "rm -rf /tmp/claude-501/STEP-9393.d" executor-write a5 sess-1 "$PARENT" ALLOW "agent_id: Agent-tool seat's own sweep allowed"
    assert_sub_verdict "rm -rf /tmp/claude-501/STEP-93.d" executor-write a5 sess-1 "$PARENT" DENY "agent_id: Agent-tool seat denied a sibling's dir"
    # The session directory can also come from session_id when transcript_path
    # is not <session>.jsonl.
    assert_sub_verdict "rm -rf ${OWN_DIR}" executor-read a1 sess-1 "$UNRELATED" ALLOW "agent_id: session_id locates the session directory"
    # transcript_path that already IS the seat's own file is read as before.
    assert_sub_verdict "rm -rf ${OWN_DIR}" executor-read a1 sess-1 "${SESS_DIR}/subagents/workflows/wf_a/agent-a1.jsonl" ALLOW "agent_id: an own transcript_path is read directly"
    # No own file (not flushed yet, or an unknown layout) is UNKNOWN, never
    # none: the bootstrap goes through, pkill still does not.
    assert_sub_verdict "rm -rf ${SIB_DIR}" executor-write a2 sess-1 "$PARENT" ALLOW "agent_id: no own transcript found is unknown, allowed"
    assert_sub_verdict "pkill -f node" executor-write a2 sess-1 "$PARENT" DENY "agent_id: unknown still denies pkill"
    # An own file that is still empty (asynchronous write) is unknown too.
    assert_sub_verdict "rm -rf ${SIB_DIR}" executor-read a3 sess-1 "$PARENT" ALLOW "agent_id: an empty own transcript is unknown, allowed"
    # No candidate directory at all (a transcript_path without .jsonl and no
    # session_id): the empty candidate list must not trip bash 3.2's `set -u`;
    # the seat is unknown, and pkill still denies.
    assert_sub_verdict "rm -rf ${SIB_DIR}" executor-write a2 "" "${WORK}/no-extension" ALLOW "agent_id: no candidate directory is unknown, allowed"
    assert_sub_verdict "pkill -f node" executor-write a2 "" "${WORK}/no-extension" DENY "agent_id: no candidate directory still denies pkill"
    # A located own transcript without the marker is a seat that holds no
    # step: none, denied, exactly as before.
    assert_sub_verdict "rm -rf ${SIB_DIR}" executor-read a4 sess-1 "$PARENT" DENY "agent_id: tribunal seat's own transcript has no marker, foreign dir denied"
    # Unidentified caller (no agent_type) resolves the same way.
    assert_sub_verdict "rm -rf ${SIB_DIR}" "" a1 sess-1 "$PARENT" DENY "agent_id, no agent_type: wave brief found through agent_id, foreign dir denied"
    assert_sub_verdict "rm -rf ${OWN_DIR}" "" a1 sess-1 "$PARENT" ALLOW "agent_id, no agent_type: own sweep allowed"
    # The pre-fix shape, pinned so a regression is a visible diff: without an
    # agent_id the parent transcript is all the hook has, and it carries no
    # marker, so the seat reads as none and its own dir as foreign.
    assert_verdict "rm -rf ${OWN_DIR}" executor-read "$PARENT" DENY "no agent_id: parent transcript reads as none (the RUN-103 shape without the fix)"
}

# --- Scratch-dir token shapes. ---------------------------------------------
case_scratch_shapes() {
    assert_verdict "rm -rf \"${SIB_DIR}\"" executor-write "$WAVE_42" DENY "quoted foreign path is not prose"
    assert_verdict "rm -rf '${SIB_DIR}'" executor-write "$WAVE_42" DENY "single-quoted foreign path is not prose"
    assert_verdict "rm -rf ${SIB_DIR}/" executor-write "$WAVE_42" DENY "trailing slash"
    assert_verdict "rm -f ${SIB_DIR}/STEP-7.token" executor-write "$WAVE_42" DENY "a file inside a sibling's dir"
    assert_verdict "rm -rf /tmp/claude-501/step-7.d" executor-write "$WAVE_42" DENY "lowercase step-7.d (case-insensitive filesystem)"
    assert_verdict "rm -rf /tmp/claude-501/STEP-*.d" executor-write "$WAVE_42" DENY "glob in the step id"
    assert_verdict "rm -rf /tmp/claude-501/STEP-{7,8}.d" executor-write "$WAVE_42" DENY "brace expansion in the step id"
    assert_verdict "rm -rf ${OWN_DIR}/.." executor-write "$WAVE_42" DENY "own dir followed by .. is the whole scratch root"
    assert_verdict "rm -rf ${OWN_DIR}/../STEP-7.d" executor-write "$WAVE_42" DENY "own dir traversed into a sibling's"
    assert_verdict "rm -rf /tmp/claude-501/STEP-9342.d" executor-write "$WAVE_42" DENY "STEP-9342 is not STEP-42 (id compared whole)"
    assert_verdict "rm -rf /tmp/claude-501/STEP-4.d" executor-write "$WAVE_42" DENY "STEP-4 is not STEP-42"
    assert_verdict "rm -rf /tmp/claude-501/STEP-93.d" executor-write "$WAVE_9393" DENY "STEP-93 is not STEP-9393"
    assert_verdict "rm -rf /tmp/claude-501/STEP-9393.d" executor-write "$WAVE_9393" ALLOW "STEP-9393 own sweep with a four-digit id"
    assert_verdict "ls /tmp/claude-501/STEP-7.dump" executor-write "$WAVE_42" ALLOW "STEP-7.dump is not a scratch dir token"
    assert_verdict "docket step artifact ARTIFACT-7 --payload" executor-write "$WAVE_42" ALLOW "an artifact id is not a scratch dir"
    assert_verdict "docket step show STEP-7 --json=v2" executor-write "$WAVE_42" ALLOW "a bare sibling step id without .d is not a scratch dir"
    # Not only rm: the dir name is the offence, whatever touches it.
    assert_verdict "mv ${SIB_DIR} ${OWN_DIR}/stolen" executor-write "$WAVE_42" DENY "mv of a sibling's dir"
    assert_verdict "find ${SIB_DIR} -delete" executor-write "$WAVE_42" DENY "find -delete on a sibling's dir"
    assert_verdict "cat /dev/null > ${SIB_DIR}/STEP-7.token" executor-write "$WAVE_42" DENY "redirect truncating a sibling's token"
    assert_verdict "chmod -R 000 ${SIB_DIR}" executor-write "$WAVE_42" DENY "chmod locking a sibling out of its dir"
    assert_verdict "ls ${SIB_DIR}" executor-read "$WAVE_42" DENY "even a read of a sibling's dir names it (accepted false deny)"
}

# --- Command shapes: chains, subshells, carriers, interpreters. --------------
case_command_shapes() {
    assert_verdict "cd /tmp && rm -rf ${SIB_DIR}" executor-write "$WAVE_42" DENY "&& chain"
    assert_verdict "true; rm -rf ${SIB_DIR}" executor-write "$WAVE_42" DENY "; chain after true"
    assert_verdict "false || rm -rf ${SIB_DIR}" executor-write "$WAVE_42" DENY "right side of ||"
    assert_verdict "(rm -rf ${SIB_DIR})" executor-write "$WAVE_42" DENY "subshell"
    assert_verdict "\$(rm -rf ${SIB_DIR})" executor-write "$WAVE_42" DENY "command substitution"
    assert_verdict "sudo rm -rf ${SIB_DIR}" executor-write "$WAVE_42" DENY "sudo prefix"
    assert_verdict "command rm -rf ${SIB_DIR}" executor-write "$WAVE_42" DENY "command builtin prefix"
    assert_verdict "for d in ${SIB_DIR}; do rm -rf \$d; done" executor-write "$WAVE_42" DENY "for loop naming the dir on its header"
    assert_verdict "for d in ${OWN_DIR}/a ${OWN_DIR}/b; do rm -rf \$d; done" executor-write "$WAVE_42" ALLOW "for loop over own paths"
    assert_verdict "while true; do rm -rf ${SIB_DIR}; break; done" executor-write "$WAVE_42" DENY "while loop ended by break (break runs under the probe)"
    assert_verdict "if true; then rm -rf ${SIB_DIR}; fi" executor-write "$WAVE_42" DENY "if body"
    assert_verdict "{ rm -rf ${SIB_DIR}; }" executor-write "$WAVE_42" DENY "brace group"
    assert_verdict "f() { rm -rf ${SIB_DIR}; }; f" executor-write "$WAVE_42" DENY "function body"
    assert_verdict "exit 0; rm -rf ${SIB_DIR}" executor-write "$WAVE_42" DENY "exit is vetoed, so the walk reads past it (conservative)"
    assert_verdict "d=${SIB_DIR}; rm -rf \$d" executor-write "$WAVE_42" DENY "variable set in the same call names the dir"
    assert_verdict "bash -c 'rm -rf ${SIB_DIR}'" executor-write "$WAVE_42" DENY "bash -c code argument"
    assert_verdict "sh -c \"rm -rf ${SIB_DIR}\"" executor-write "$WAVE_42" DENY "sh -c code argument, double-quoted"
    assert_verdict "python3 -c 'import shutil; shutil.rmtree(\"${SIB_DIR}\")'" executor-write "$WAVE_42" DENY "python -c code argument"
    assert_verdict "rm -rf \$TMPDIR/STEP-7.d" executor-write "$WAVE_42" DENY "TMPDIR variable prefix"
    assert_verdict "rm -rf \${TMPDIR}/STEP-7.d" executor-write "$WAVE_42" DENY "braced TMPDIR prefix"
    assert_verdict "rm -rf ${SIB_DIR} # cleanup" executor-write "$WAVE_42" DENY "trailing comment does not hide the leaf"
    assert_verdict "# rm -rf ${SIB_DIR}" executor-write "$WAVE_42" ALLOW "a whole-line comment dispatches nothing"
    # Residuals, pinned as ALLOW so a change in direction is a visible diff.
    assert_verdict "ls /tmp/claude-501 | xargs rm -rf" executor-write "$WAVE_42" ALLOW "residual: xargs carrier that never names the dir"
    assert_verdict "rm -rf /tmp/claude-501/*" executor-write "$WAVE_42" ALLOW "residual: whole scratch root, no step named"
}

# --- Prose. ------------------------------------------------------------------
case_prose() {
    assert_verdict "docket issue comment add DOT-1 -d 'a leftover STEP-7.d was seen beside mine'" executor-write "$WAVE_42" ALLOW "quoted prose span mentioning a sibling's dir"
    assert_verdict "docket issue comment add DOT-1 -d \"a leftover STEP-7.d was seen\"" executor-write "$WAVE_42" ALLOW "double-quoted prose span"
    assert_verdict "echo \"see ${SIB_DIR} later\"" executor-write "$WAVE_42" ALLOW "double-quoted prose span naming a sibling's full path"
    assert_verdict "echo \"\$(rm -rf ${SIB_DIR} now)\"" executor-write "$WAVE_42" DENY "double-quoted \$( ) substitution is not prose"
    assert_verdict "echo \"\`rm -rf ${SIB_DIR} now\`\"" executor-write "$WAVE_42" DENY "double-quoted backtick substitution is not prose"
    assert_verdict $'cat > '"${OWN_DIR}"$'/STEP-42-findings.md <<\'EOF\'\nFound a leftover STEP-7.d beside my own dir.\nEOF' executor-write "$WAVE_42" ALLOW "quoted-delimiter heredoc body is inert"
    assert_verdict $'cat > '"${OWN_DIR}"$'/STEP-42-findings.md <<EOF\nFound a leftover STEP-7.d beside my own dir.\nEOF' executor-write "$WAVE_42" DENY "unquoted-delimiter heredoc body is scanned (accepted false deny)"
    assert_verdict $'cat <<\'EOF\' | sh\nrm -rf '"${SIB_DIR}"$'\nEOF' executor-write "$WAVE_42" DENY "quoted heredoc piped into an interpreter is code"
    assert_verdict "echo STEP-7.d" executor-write "$WAVE_42" DENY "a lone unquoted token is not prose (accepted false deny)"
    assert_verdict "grep -rn 'STEP-[0-9]*' ${OWN_DIR}" executor-read "$WAVE_42" DENY "glob-form token as a search pattern (accepted false deny)"
    assert_verdict "grep -rnE 'STEP.[0-9]+' ${OWN_DIR}" executor-read "$WAVE_42" ALLOW "the deny reason's search spelling is not a scratch token"
    assert_verdict "grep -rnE 'STEP.[0-9]+' ${SIB_DIR}" executor-read "$WAVE_42" DENY "the search spelling aimed at a sibling's dir is still refused"
    assert_verdict "git log --grep kill" executor-write "$WAVE_42" ALLOW "kill as an argument word with no operands"
    assert_verdict "echo 'please kill 1234 later'" executor-write "$WAVE_42" ALLOW "kill inside a quoted prose span"
}

# --- Worktrees and branches. ------------------------------------------------
case_worktree_and_branch() {
    assert_verdict "git worktree list --porcelain" executor-write "$WAVE_42" ALLOW "worktree list"
    assert_verdict "git worktree add ${OWN_DIR}/probe HEAD" executor-read "$WAVE_42" ALLOW "worktree add under own dir"
    assert_verdict "git worktree remove ${OWN_DIR}/probe" executor-read "$WAVE_42" ALLOW "worktree remove of own probe checkout"
    assert_verdict "git worktree remove --force ${OWN_DIR}/probe" executor-read "$WAVE_42" ALLOW "worktree remove --force of own probe checkout"
    assert_verdict "git worktree remove ${SIB_DIR}/probe" executor-read "$WAVE_42" DENY "worktree remove of a sibling's probe checkout"
    assert_verdict "git worktree remove ${OWN_DIR}/../wf_x" executor-read "$WAVE_42" DENY "worktree remove traversing out of own dir"
    assert_verdict "git worktree remove ." executor-write "$WAVE_42" DENY "worktree remove of the current checkout"
    assert_verdict "git -C /repo worktree remove /repo/.claude/worktrees/wf_x" executor-write "$WAVE_42" DENY "-C global option before worktree remove"
    assert_verdict "git worktree move /repo/.claude/worktrees/wf_x /elsewhere" executor-write "$WAVE_42" DENY "worktree move of a checkout it did not make"
    assert_verdict "git worktree move ${OWN_DIR}/a ${OWN_DIR}/b" executor-write "$WAVE_42" ALLOW "worktree move inside own dir"
    assert_verdict "git worktree prune" executor-write "$WAVE_42" DENY "worktree prune"
    assert_verdict "git worktree prune --dry-run" executor-write "$WAVE_42" DENY "worktree prune --dry-run still refused (no executor use)"
    assert_verdict "git worktree lock ${OWN_DIR}/probe" executor-write "$WAVE_42" ALLOW "worktree lock is not destructive"
    assert_verdict "git branch -D feature/x" executor-write "$WAVE_42" DENY "branch -D"
    assert_verdict "git branch -d feature/x" executor-write "$WAVE_42" DENY "branch -d"
    assert_verdict "git branch --delete --force feature/x" executor-write "$WAVE_42" DENY "branch --delete --force"
    assert_verdict "git branch -Df feature/x" executor-write "$WAVE_42" DENY "branch -Df bundle"
    assert_verdict "git branch -rd origin/feature/x" executor-write "$WAVE_42" DENY "branch -rd remote-tracking delete"
    assert_verdict "git branch -d worktree-wf_e9395cda-5cb-1" executor-write "$WAVE_42" DENY "a sibling's harness worktree branch"
    assert_verdict "git branch -d step-42-probe" executor-write "$WAVE_42" ALLOW "own-named branch delete"
    assert_verdict "git branch -D STEP-42/scratch" executor-write "$WAVE_42" ALLOW "own-named branch delete, uppercase"
    assert_verdict "git branch -d step-4-probe" executor-write "$WAVE_42" DENY "step-4 is not step-42"
    assert_verdict "git branch -d step-421" executor-write "$WAVE_42" DENY "step-421 is not step-42"
    assert_verdict "git branch -a" executor-write "$WAVE_42" ALLOW "branch listing"
    assert_verdict "git branch new-branch" executor-write "$WAVE_42" ALLOW "branch creation"
    assert_verdict "git branch --show-current" executor-write "$WAVE_42" ALLOW "branch --show-current"
    assert_verdict "git checkout --detach --quiet abc123" executor-write "$WAVE_42" ALLOW "checkout --detach from the brief's bootstrap"
    assert_verdict "git --help branch" executor-write "$WAVE_42" ALLOW "git --help before the subcommand"
}

# --- Processes. --------------------------------------------------------------
case_processes() {
    assert_verdict "pkill -f vorpal" executor-write "$WAVE_42" DENY "pkill -f"
    assert_verdict "pkill node" executor-research "$WAVE_42" DENY "pkill by name"
    assert_verdict "killall node" executor-write "$WAVE_42" DENY "killall"
    assert_verdict "/usr/bin/pkill node" executor-write "$WAVE_42" DENY "pkill by absolute path"
    assert_verdict "kill 1234" executor-write "$WAVE_42" DENY "kill literal pid"
    assert_verdict "kill -9 1234" executor-write "$WAVE_42" DENY "kill -9 literal pid"
    assert_verdict "kill -s KILL 1234" executor-write "$WAVE_42" DENY "kill -s SIG literal pid"
    assert_verdict "kill -TERM 1234 5678" executor-write "$WAVE_42" DENY "kill several literal pids"
    assert_verdict "kill '1234'" executor-write "$WAVE_42" DENY "kill quoted literal pid"
    assert_verdict "kill 0" executor-write "$WAVE_42" DENY "kill 0 (own process group)"
    assert_verdict "kill -- -1" executor-write "$WAVE_42" DENY "kill -- -1 (every process)"
    assert_verdict "kill %1" executor-write "$WAVE_42" ALLOW "kill jobspec"
    assert_verdict "kill -TERM %1" executor-write "$WAVE_42" ALLOW "kill -TERM jobspec"
    assert_verdict "srv & kill \$!" executor-write "$WAVE_42" ALLOW "kill \$! of a job this call started"
    assert_verdict "srv & pid=\$!; sleep 1; kill \$pid" executor-write "$WAVE_42" ALLOW "kill \$pid captured in the same call"
    assert_verdict "kill \$(cat ${OWN_DIR}/srv.pid)" executor-write "$WAVE_42" ALLOW "kill on a pid file under own dir"
    assert_verdict "kill \$(pgrep -f srv)" executor-write "$WAVE_42" DENY "kill fed by pgrep"
    assert_verdict "kill \$(lsof -ti :8080)" executor-write "$WAVE_42" DENY "kill fed by lsof (whoever holds the port)"
    assert_verdict "p=\$(ps -o pid= -C srv); kill \$p" executor-write "$WAVE_42" DENY "kill fed by ps in the same call"
    assert_verdict "kill -0 1234" executor-write "$WAVE_42" ALLOW "kill -0 is a liveness probe"
    assert_verdict "kill -s 0 1234" executor-write "$WAVE_42" ALLOW "kill -s 0 is a liveness probe"
    assert_verdict "kill -l" executor-write "$WAVE_42" ALLOW "kill -l lists signals"
    assert_verdict "kill -L" executor-write "$WAVE_42" ALLOW "kill -L lists signals"
    assert_verdict "pgrep -f srv" executor-write "$WAVE_42" ALLOW "pgrep alone is a read"
    assert_verdict "lsof -i :8080" executor-write "$WAVE_42" ALLOW "lsof alone is a read"
}

# --- Engine verbs. -----------------------------------------------------------
case_engine_verbs() {
    assert_verdict "docket step reap STEP-7 --reason 'holder gone'" executor-write "$WAVE_42" DENY "docket step reap of a sibling"
    assert_verdict "docket step reap STEP-42 --reason x" executor-write "$WAVE_42" DENY "docket step reap even of its own step id"
    assert_verdict "docket step reap --help" executor-read "$WAVE_42" DENY "docket step reap --help (no executor use for the verb)"
    assert_verdict "docket step reap STEP-7 --reason x" executor-write "$MISSING" DENY "docket step reap needs no own id to deny"
    assert_verdict "docket step reap STEP-7 --reason x" "" "$OPERATOR" ALLOW "main conversation: reap stays the operator's"
    assert_verdict "docket step reap STEP-7 --reason 'relay saw the spawn die'" docket-conductor-RUN-5 "$OPERATOR" ALLOW "conductor seat: the reap is its verb"
    assert_verdict "docket step heartbeat STEP-42 < ${OWN_DIR}/STEP-42.token" executor-write "$WAVE_42" ALLOW "token-bound heartbeat"
    assert_verdict "docket step fail STEP-42 --note x < ${OWN_DIR}/STEP-42.token" executor-write "$WAVE_42" ALLOW "token-bound fail"
    assert_verdict "docket step show STEP-7 --json=v2" executor-write "$WAVE_42" ALLOW "docket step show"
    assert_verdict "docket issue comment add DOT-1 -d 'the conductor should docket step reap STEP-7'" executor-write "$WAVE_42" ALLOW "reap mentioned inside a quoted prose span"
    assert_verdict "\"docket\" \"step\" \"reap\" STEP-7 --reason x" executor-write "$WAVE_42" DENY "separately-quoted reap words still run the verb"
    # `docket run conduct` re-mints the run's conductor capability; the engine
    # refuses the other seven operator verbs itself, so this is the one verb
    # the hook must keep executors off. Same scope as reap: every executor
    # archetype denied with or without an own step, the main conversation and
    # the conductor seat allowed.
    assert_verdict "docket run conduct RUN-5" executor-write "$WAVE_42" DENY "docket run conduct from a writer"
    assert_verdict "docket run conduct RUN-5 --json=v2" executor-read "$WAVE_42" DENY "docket run conduct --json=v2 from a reader"
    assert_verdict "docket run conduct RUN-5" executor-research "$MISSING" DENY "docket run conduct needs no own id to deny"
    assert_verdict "docket run conduct --help" executor-write "$WAVE_42" DENY "docket run conduct --help (no executor use for the verb)"
    assert_verdict "docket run conduct RUN-5" "" "$WAVE_42" DENY "agent_type absent, wave brief in transcript: conduct denied"
    assert_verdict "docket run conduct RUN-5" "" "$OPERATOR" ALLOW "main conversation: conduct is how the conductor takes the seat"
    assert_verdict "docket run conduct RUN-5 --json=v2" docket-conductor-RUN-5 "$OPERATOR" ALLOW "conductor seat: conduct re-mints its own capability"
    assert_verdict "docket run status RUN-5 --json=v2" executor-write "$WAVE_42" ALLOW "docket run status"
    assert_verdict "docket run report RUN-5" executor-read "$WAVE_42" ALLOW "docket run report"
    assert_verdict "docket issue comment add DOT-1 -d 'the conductor should docket run conduct RUN-5'" executor-write "$WAVE_42" ALLOW "conduct mentioned inside a quoted prose span"
    assert_verdict "\"docket\" \"run\" \"conduct\" RUN-5" executor-write "$WAVE_42" DENY "separately-quoted conduct words still run the verb"
}

# --- Probe hardening: the hook must never act on the caller's behalf. -------
# Each case plants a marker file with known bytes and checks it is untouched
# after the hook ran, whatever the verdict.
case_probe_never_acts() {
    local marker="${WORK}/probe-marker" err got
    plant() { printf 'twelve bytes' >"$marker"; }
    intact() { [ "$(cat "$marker" 2>/dev/null)" = "twelve bytes" ]; }
    check() { # <label> <want> <command>
        plant
        got=$(verdict_of "$(build_input "$3" executor-write "$WAVE_42")")
        [ "$got" = "$2" ] && pass "${1} (${2})" || fail "${1} (want ${2}, got ${got})"
        intact && pass "${1}: marker untouched" || fail "${1}: the probe altered the marker ($(cat "$marker" 2>/dev/null | head -c 40))"
    }
    check "structural redirect (: > file)" DENY ": > ${marker}"
    check "structural redirect (true > file)" DENY "true > ${marker}"
    check "structural redirect ([ ] > file)" DENY "[ 1 ] > ${marker}"
    check "structural redirect onto a sibling token" DENY ": > ${SIB_DIR}/STEP-7.token"
    check "structural redirect onto a gitdir pointer" DENY ": > /repo/.claude/worktrees/wf_x/.git"
    check "structural heredoc" DENY $': <<\'EOF\'\nhi\nEOF'
    check "compound redirect ({ } > file)" DENY "{ :; } > ${marker}"
    check "compound redirect (( ) > file)" DENY "( : ) > ${marker}"
    check "compound redirect (loop > file)" DENY "while :; do break; done > ${marker}"
    check "compound redirect (function call > file)" DENY "f() { :; }; f > ${marker}"
    check "vetoed leaf redirect stays inspectable and inert" ALLOW "cat /dev/null > ${marker}"
    local step_tmp_marker
    step_tmp_marker="$(work_root_for "${WORK}/STEP-10355.d/tmp")/probe-marker"
    got=$(verdict_of "$(build_input "cat /dev/null > ${step_tmp_marker}" executor-write "$WAVE_42")")
    [ "$got" = ALLOW ] && pass "marker under a TMPDIR inside a foreign STEP-N.d stays allowed (ALLOW)" || fail "marker under a TMPDIR inside a foreign STEP-N.d stays allowed (want ALLOW, got ${got})"
    check "vetoed leaf redirect onto own dir" ALLOW "echo x > ${OWN_DIR}/note.txt"
    check "handler redefinition" DENY "_guard_probe() { return 0; }; rm -rf ${OWN_DIR}/x; cat /dev/null > ${marker}"
    check "handler redefinition, function keyword" DENY "function _guard_probe { :; }; cat /dev/null > ${marker}"
    check "handler redefinition then a sibling rm" DENY "_guard_probe() { return 0; }; rm -rf ${SIB_DIR}"
    check "cap in a structural loop before the verb" DENY 'while [[ $((++i)) -lt 2100 ]]; do :; done; rm -rf '"${SIB_DIR}"
    check "cap in a structural loop before pkill" DENY 'while [[ $((++i)) -lt 2100 ]]; do :; done; pkill node'
    check "cap in a structural loop before reap" DENY 'while [[ $((++i)) -lt 2100 ]]; do :; done; docket step reap STEP-7 --reason x'
    check "unbounded loop touching the marker" DENY "while true; do cat /dev/null > ${marker}; done"
    # A leaf that is only assignments RUNS, so a counter-bounded wait loop
    # ends where the real command's would instead of walking into the cap.
    # Everything an assignment could make run stays vetoed: a command word
    # after the assignment, a substitution or backtick in the value, a
    # subscript reached through arithmetic, and the probe's own counter.
    check "counted wait loop (assignment counter) ends" ALLOW 'i=0; until [ -s /nonexistent ] || [ $i -ge 3 ]; do sleep 0; i=$((i+1)); done'
    check "counted wait loop, spaced arithmetic and \$i" ALLOW 'n=0; until [ -s /nonexistent ] || [ $n -ge 180 ]; do sleep 5; n=$(( $n + 1 )); done; ls -la /nonexistent'
    check "counted wait loop with a sibling rm in the body" DENY 'i=0; until [ -s /nonexistent ] || [ $i -ge 3 ]; do rm -rf '"${SIB_DIR}"'; i=$((i+1)); done'
    check "counted wait loop touching the marker" ALLOW 'i=0; until [ $i -ge 3 ]; do cat /dev/null > '"${marker}"'; i=$((i+1)); done'
    check "assignment prefix on a sibling rm" DENY "n=1 rm -rf ${SIB_DIR}"
    check "assignment from a command substitution stays vetoed" ALLOW "x=\$(cat /dev/null > ${marker})"
    check "assignment from a backtick stays vetoed" ALLOW "x=\`cat /dev/null > ${marker}\`"
    check "arithmetic over a subscripted value stays vetoed" ALLOW "x='a[\$(cat /dev/null > ${marker})]'; n=\$((x[0]))"
    # The for-word is a subscript expression whose substitution would delete
    # the marker; `$((x))` on it evaluates the subscript, and the trap must
    # reach into that substitution and veto the rm. (A redirect there is
    # refused by the restricted shell instead, so the probe is a bare rm.)
    check "arithmetic over a tainted for-word never runs its subscript" ALLOW "for x in 'a[\$(rm -f ${marker})]'; do n=\$((x)); done"
    check "read loop with a substitution in its operand stays vetoed" DENY "ls | while read x\$(rm -f ${marker}); do :; done"
    check "read loop with a subscripted operand stays vetoed" DENY "ls | while read 'a[\$(rm -f ${marker})]'; do :; done"
    check "counter reset cannot lift the cap" DENY "_leaf_n=-100000; while true; do cat /dev/null > ${marker}; done"
    check "counter reset in a multi-assignment cannot lift the cap" DENY "x=1 _leaf_n=-100000; while true; do cat /dev/null > ${marker}; done"
    rm -f "$marker"
    # No temp file: the scratch root holds nothing of this hook's afterward.
    local before after
    before=$(ls "${TMPDIR:-/tmp}" 2>/dev/null | grep -c 'docket-sibling-guard' || true)
    verdict_of "$(build_input "rm -rf ${SIB_DIR}" executor-write "$WAVE_42")" >/dev/null
    verdict_of "$(build_input "ls" executor-write "$WAVE_42")" >/dev/null
    after=$(ls "${TMPDIR:-/tmp}" 2>/dev/null | grep -c 'docket-sibling-guard' || true)
    [ "$after" -le "$before" ] && pass "no probe file left in TMPDIR" || fail "probe files left in TMPDIR (${before} -> ${after})"
}

# --- Read loops. -------------------------------------------------------------
# The probe vetoes every producer, so a `read` over a pipe sees no input. A
# vetoed read reports success and the loop never ended; a read that always
# ran would hit EOF before the body was walked. Each read site is vetoed once,
# so the body is walked, then runs and ends the loop.
case_read_loops() {
    local err
    assert_verdict "printf 'a\\nb\\n' | while read x; do echo \$x; done" executor-write "$WAVE_42" ALLOW "read loop over finite piped input ends"
    assert_verdict "git status --short | while IFS= read -r f; do echo \"\$f\"; done" executor-write "$WAVE_42" ALLOW "IFS= read -r loop over piped input ends"
    assert_verdict "ls | while read d; do rm -rf ${SIB_DIR}/\$d; done" executor-write "$WAVE_42" DENY "read loop body naming a sibling dir"
    assert_deny_reason "ls | while read d; do rm -rf ${SIB_DIR}/\$d; done" executor-write "$WAVE_42" "STEP-7.d" "read loop body is walked before the loop ends"
    assert_deny_reason_lacks "ls | while read d; do rm -rf ${SIB_DIR}/\$d; done" executor-write "$WAVE_42" "too many parts" "read loop over a sibling dir is denied by the scratch clause, not the cap"
    assert_verdict "ls | while read d; do pkill node; done" executor-write "$WAVE_42" DENY "read loop body running pkill"
    assert_verdict "ls | while read a; do ls \$a | while read b; do rm -rf ${SIB_DIR}/\$b; done; done" executor-write "$WAVE_42" DENY "nested read loops walk the inner body"
    # A read site is its text in one shell: a same-text read in a pipeline
    # stage, a ( ) subshell or a function's pipeline is a site of its own.
    assert_deny_reason_lacks "ls | while read d; do ls | while read d; do rm -rf ${SIB_DIR}/\$d; done; done" executor-write "$WAVE_42" "too many parts" "same-text nested read loops walk the inner body"
    assert_deny_reason "ls | while read d; do ls | while read d; do rm -rf ${SIB_DIR}/\$d; done; done" executor-write "$WAVE_42" "STEP-7.d" "same-text nested read loops walk the inner body"
    assert_verdict "ls | while read d; do echo \$d | while read d; do pkill node; done; done" executor-write "$WAVE_42" DENY "same-text nested read loop running pkill"
    assert_verdict "ls | while read d; do (ls | while read d; do rm -rf ${SIB_DIR}/\$d; done); done" executor-write "$WAVE_42" DENY "same-text read loop inside ( ) walks its body"
    assert_verdict "f() { ls | while read d; do rm -rf ${SIB_DIR}/\$d; done; }; ls | while read d; do f; done" executor-write "$WAVE_42" DENY "same-text read loop in a called function walks its body"
    assert_verdict "read d; ls | while read d; do rm -rf ${SIB_DIR}/\$d; done" executor-write "$WAVE_42" DENY "a lone read does not skip a later piped same-text loop"
    assert_verdict "ls | { while read d; do break; done; while read d; do rm -rf ${SIB_DIR}/\$d; done; }" executor-write "$WAVE_42" DENY "a read loop left by break does not skip a later same-text loop"
    # A break that leaves only an inner loop does not keep the read loop
    # around it from ending, and its body is still walked.
    assert_verdict "printf 'a\\n' | while read d; do for x in 1 2; do break; done; done" executor-write "$WAVE_42" ALLOW "read loop with a break in an inner loop ends"
    assert_verdict "printf 'a\\n' | while read d; do while :; do break; done; done" executor-write "$WAVE_42" ALLOW "read loop with a break in an inner while loop ends"
    assert_deny_reason_lacks "ls | while read d; do for x in 1 2; do break; done; rm -rf ${SIB_DIR}/\$d; done" executor-write "$WAVE_42" "too many parts" "read loop with an inner break walks the rest of its body"
    assert_deny_reason "ls | while read d; do for x in 1 2; do break; done; rm -rf ${SIB_DIR}/\$d; done" executor-write "$WAVE_42" "STEP-7.d" "read loop with an inner break walks the rest of its body"
    # Only `[IFS=<bare word>] read [-r] [name...]` runs; any other option,
    # IFS value or redirect keeps the read vetoed, so these loops cap.
    local shape
    for shape in 'read -a d' 'read -d x d' 'read -n 1 d' 'read -p x d' 'read -t 1 d' 'read -s d' 'read -e d' 'IFS=$(true) read d' 'IFS="x" read d' "IFS='x' read d" 'read d < /dev/null'; do
        assert_deny_reason "printf 'a\\n' | while ${shape}; do :; done" executor-write "$WAVE_42" "too many parts" "read loop over \`${shape}\` stays vetoed"
    done
    # The probe counter is never a read operand: the counter would reset on
    # every pass and the walk would never reach the cap.
    assert_deny_reason 'while :; do read _leaf_n; done' executor-write "$WAVE_42" "too many parts" "read into the probe counter stays vetoed"
    # Only a pipe at EOF lets a read run: a device that may never end, or
    # input the probe would read for real, keeps the read vetoed and caps.
    assert_deny_reason 'while read x; do :; done < /dev/zero' executor-write "$WAVE_42" "too many parts" "read loop over an endless device caps"
    assert_deny_reason 'while read d; do :; done < /dev/null' executor-write "$WAVE_42" "too many parts" "read loop whose input is not a pipe caps"
    assert_verdict "while read d; do rm -rf \$d; done <<< \"${SIB_DIR}\"" executor-write "$WAVE_42" DENY "read loop over a here-string naming a sibling dir"
    assert_verdict "ls | while read -u 0 d; do :; done" executor-write "$WAVE_42" DENY "read with an option outside -r stays vetoed and caps"
    # A vetoed read assigned nothing, so a test, case, for-list or expansion
    # on a value during that walk, or a continue, can steer the loop past the
    # body it never walked. The walk is refused instead, in the body or the
    # condition, and even with a command after the loop.
    local cmd
    for cmd in \
        "ls | while read d; do [ -n \"\$d\" ] || continue; rm -rf ${SIB_DIR}/\$d; done" \
        "ls | while read d; do if [ -n \"\$d\" ]; then rm -rf ${SIB_DIR}/\$d; fi; done" \
        "ls | while read d; do [ -z \"\$d\" ] && continue; pkill -f \"\$d\"; done" \
        "ls | while IFS= read -r f; do [ -e \"\$f\" ] || continue; rm -rf ${SIB_DIR}/\$f; done" \
        "ls | while read d; do [[ -n \$d ]] || continue; rm -rf ${SIB_DIR}/\$d; done" \
        "ls | while read d; do case \$d in '') continue ;; esac; rm -rf ${SIB_DIR}/\$d; done" \
        "ls | while read -r d && [ -n \"\$d\" ]; do rm -rf ${SIB_DIR}/\$d; done" \
        "ls | while read -r d && [ -n \"\$d\" ]; do rm -rf ${SIB_DIR}/\$d; done; echo done" \
        "ls | while read d; do test -z \"\$d\" && continue; rm -rf ${SIB_DIR}/\$d; done" \
        "ls | while read d; do x=\$d; [ -n \"\$x\" ] || continue; rm -rf ${SIB_DIR}/\$x; done" \
        "ls | while read d; do for f in \$d; do rm -rf ${SIB_DIR}/\$f; done; done" \
        "ls | while read head; do for f in \$head; do rm -rf ${SIB_DIR}/\$f; done; done" \
        "ls | while read d; do : \${d:?}; rm -rf ${SIB_DIR}/\$d; done"; do
        assert_deny_reason "$cmd" executor-write "$WAVE_42" "branches on a variable" "read loop that branches on its value: ${cmd}"
    done
    # A loop that closes stderr cannot swallow the refusal: the marker
    # travels on a descriptor the probe opens before `set -r`.
    assert_verdict "ls | while read d; do [ -n \"\$d\" ] || continue; rm -rf ${SIB_DIR}/\$d; done 2>&-" executor-write "$WAVE_42" DENY "guarded read loop with stderr closed"
    assert_verdict "ls | while read d; do [ -n \"\$d\" ] || continue; rm -rf ${SIB_DIR}/\$d; done 2>&-; echo done" executor-write "$WAVE_42" DENY "guarded read loop with stderr closed before a trailing command"
    assert_verdict "{ ls | while read d; do [ -n \"\$d\" ] || continue; rm -rf ${SIB_DIR}/\$d; done; } 2>&-" executor-write "$WAVE_42" DENY "guarded read loop in a group with stderr closed"
    assert_verdict "ls | while read d; do [ -z \"\$d\" ] && continue; pkill -f node; done 2>&-" executor-write "$WAVE_42" DENY "guarded read loop running pkill with stderr closed"
    assert_verdict "read d; for f in \$d; do rm -rf ${SIB_DIR}/\$f; done 2>&-" executor-write "$WAVE_42" DENY "for-list over a lone read with stderr closed"
    assert_deny_reason "ls | while read d; do rm -rf ${SIB_DIR}/\$d; done 2>&-" executor-write "$WAVE_42" "STEP-7.d" "unguarded read loop with stderr closed walks its body"
    assert_verdict "ls | while read d; do [ -n \"\$d\" ] || continue; rm -rf ${SIB_DIR}/\$d; done 2>/dev/null" executor-write "$WAVE_42" DENY "guarded read loop redirecting stderr to a file"
    assert_verdict "printf 'a\\nb\\n' | while read x; do echo \$x; done 2>&-" executor-write "$WAVE_42" ALLOW "read loop with stderr closed ends"
    assert_verdict "printf 'a\\n' | while read d; do [ -s /nonexistent ] || echo \$d; done 2>&-" executor-write "$WAVE_42" ALLOW "read loop whose test expands no value, stderr closed, ends"
    # The read placeholder covers the IFS= -r form, a read with no name
    # (REPLY) and every operand of a multi-name read.
    assert_deny_reason "ls | while IFS= read -r f; do for g in \$f; do rm -rf ${SIB_DIR}/\$g; done; done" executor-write "$WAVE_42" "branches on a variable" "for-list over an IFS= read -r placeholder"
    assert_deny_reason "ls | while read; do for f in \$REPLY; do rm -rf ${SIB_DIR}/\$f; done; done" executor-write "$WAVE_42" "branches on a variable" "for-list over the REPLY placeholder of a nameless read"
    assert_deny_reason "ls | while read a b; do for f in \$b; do rm -rf ${SIB_DIR}/\$f; done; done" executor-write "$WAVE_42" "branches on a variable" "for-list over the second operand of a multi-name read"
    # An arithmetic `[[` comparison or `((...))` reads a bare name as a
    # variable, so it branches on the read value with no `$` in sight.
    assert_deny_reason "seq 3 | while read n; do if [[ n -ne 0 ]]; then rm -rf ${SIB_DIR}/\$n; fi; done" executor-write "$WAVE_42" "branches on a variable" "bare name in an arithmetic [[ if after a read"
    assert_deny_reason "seq 3 | while read n; do [[ n -gt 0 ]] || break; rm -rf ${SIB_DIR}/\$n; done" executor-write "$WAVE_42" "branches on a variable" "bare name in an arithmetic [[ || break after a read"
    assert_deny_reason "seq 3 | while read n && [[ n -gt 0 ]]; do rm -rf ${SIB_DIR}/\$n; done" executor-write "$WAVE_42" "branches on a variable" "bare name in an arithmetic [[ in the read loop condition"
    assert_verdict "seq 3 | while read n; do for ((i=n; i; i--)); do rm -rf ${SIB_DIR}/x; done; done" executor-write "$WAVE_42" DENY "arithmetic for head over a read value"
    assert_deny_reason "seq 3 | while read n; do if [[ \$n -ne 0 ]]; then rm -rf ${SIB_DIR}/\$n; fi; done" executor-write "$WAVE_42" "branches on a variable" "\$n in an arithmetic [[ if after a read"
    assert_verdict "n=1; [[ n -ne 0 ]] && echo ok" executor-write "$WAVE_42" ALLOW "bare name in an arithmetic [[ with no read"
    # The refusal costs these benign shapes too; a test on no value still ends.
    assert_deny_reason "git status --short | while IFS= read -r f; do [ -e \"\$f\" ] || continue; echo \"\$f\"; done" executor-write "$WAVE_42" "branches on a variable" "benign read loop that tests its value is refused"
    assert_deny_reason "read x; [ -n \"\$x\" ] && echo y" executor-write "$WAVE_42" "branches on a variable" "test after a lone read is refused"
    assert_verdict "printf 'a\\n' | while read d; do [ -s /nonexistent ] || echo \$d; done" executor-write "$WAVE_42" ALLOW "read loop whose test expands no value ends"
    # A for or select header cannot preset the probe's own read state.
    assert_deny_reason "for _leaf_reads in '|P1:read d|'; do :; done; ls | while read d; do rm -rf ${SIB_DIR}/\$d; done" executor-write "$WAVE_42" "_leaf_*" "for header presetting the read state"
    assert_deny_reason "ls | { for _leaf_reads in '|P1:read d|'; do :; done; while read d; do pkill node; done; }; echo done" executor-write "$WAVE_42" "_leaf_*" "for header presetting the read state in a pipeline stage"
    assert_deny_reason "select _leaf_reads in x; do break; done; ls | while read d; do pkill node; done" executor-write "$WAVE_42" "_leaf_*" "select header naming the probe state"
    # A marked read site runs only when another leaf fired since the last
    # read, so a lone read directly before a same-text loop does not let
    # the loop skip its body, at top level or in a pipeline stage.
    assert_verdict "read d; while read d; do rm -rf ${SIB_DIR}/\$d; done" executor-write "$WAVE_42" DENY "same-text read loop right after a top-level lone read"
    assert_verdict "ls | { read d; while read d; do rm -rf ${SIB_DIR}/\$d; done; }" executor-write "$WAVE_42" DENY "same-text read loop after a lone read in the same shell"
    # KNOWN RESIDUAL: a read whose site was vetoed but never fired again,
    # with another leaf between it and the later read (a lone read and a
    # command, a loop left through a failing condition right after its
    # read, or a second same-text loop left by break), leaves that site
    # marked, so a later read with the same text in the same shell runs at
    # once and its body is not walked.
    assert_verdict "ls | { while read d; do break; done; while read d; do break; done; while read d; do rm -rf ${SIB_DIR}/\$d; done; }" executor-write "$WAVE_42" ALLOW "residual: same-text read loop after two loops left by break"
    assert_verdict "ls | { while read d && false; do :; done; while read d; do rm -rf ${SIB_DIR}/\$d; done; }" executor-write "$WAVE_42" ALLOW "residual: same-text read after a condition exit"
    assert_verdict "ls | { read d; ls; while read d; do rm -rf ${SIB_DIR}/\$d; done; }" executor-write "$WAVE_42" ALLOW "residual: same-text read loop after a lone read and another command"
    # A read placeholder the command strips itself leaves a for-list empty,
    # so no leaf fires between two reads and the loop caps.
    assert_deny_reason "ls | while read d; do for f in \${d%x}; do rm -rf ${SIB_DIR}/\$f; done; done" executor-write "$WAVE_42" "too many parts" "for-list over a stripped read placeholder caps"
    # KNOWN RESIDUAL: a vetoed condition reports status 0, so only its then
    # branch is walked, in a read loop as at top level.
    assert_verdict "ls | while read d; do if test -z \"\$d\"; then :; else rm -rf ${SIB_DIR}/\$d; fi; done" executor-write "$WAVE_42" ALLOW "residual: else branch after a vetoed condition in a read loop"
    assert_verdict "if grep -q x f; then :; else rm -rf ${SIB_DIR}/x; fi" executor-write "$WAVE_42" ALLOW "residual: else branch after a vetoed condition at top level"
    # The cap reason names the counted wait and the read loop the probe ends.
    assert_deny_reason 'while true; do :; done' executor-write "$WAVE_42" 'n=0; until [ -s f ] || [ $n -ge N ]; do sleep S; n=$((n+1)); done' "cap reason names the counted wait loop"
    assert_deny_reason 'while true; do :; done' executor-write "$WAVE_42" 'cmd | while IFS= read -r x; do ...; done' "cap reason names the read loop shape that ends"
    assert_deny_reason 'while true; do :; done' executor-write "$WAVE_42" "too many parts (over 2000)" "cap reason keeps the oversized wording"
    # The read-value reason names a filtered loop, and that loop ends.
    assert_deny_reason "ls | while read d; do [ -n \"\$d\" ] || continue; echo \$d; done" executor-write "$WAVE_42" "cmd | grep -v '^\$' | while IFS= read -r x; do ...; done" "read-value reason names the filtered loop"
    assert_verdict "git status --short | grep -v '^\$' | while IFS= read -r x; do echo \"\$x\"; done" executor-write "$WAVE_42" ALLOW "filtered read loop named by the read-value reason ends"
    # A lone read earlier in the call refuses the counted wait too, and the
    # reason says to run that read in its own call.
    assert_deny_reason 'read x; n=0; until [ -s f ] || [ $n -ge 3 ]; do n=$((n+1)); done' executor-write "$WAVE_42" "run that read in its own Bash call" "read-value reason names a lone read before a counted wait"
}

# Oversized and odd inputs fail closed or stay inert, quickly.
case_size_and_bytes() {
    local big
    big=$(printf 'a%.0s' $(seq 1 300000))
    assert_verdict "echo ${big}; rm -rf ${SIB_DIR}" executor-write "$WAVE_42" DENY "a 300 KiB command is refused rather than walked"
    big=$(printf 'a%.0s' $(seq 1 100000))
    assert_verdict "echo ${big}; rm -rf ${SIB_DIR}" executor-write "$WAVE_42" DENY "a 100 KiB command is walked and the sibling rm found"
    assert_verdict "echo ${big}" executor-write "$WAVE_42" ALLOW "a 100 KiB harmless command is allowed"
    assert_verdict $'echo a\036b; rm -rf '"${SIB_DIR}" executor-write "$WAVE_42" DENY "a framing byte in the command is refused"
    assert_verdict $'echo a\035b' executor-write "$WAVE_42" DENY "the other framing byte is refused too"
    assert_verdict $'ls\r\nrm -rf '"${SIB_DIR}" executor-write "$WAVE_42" DENY "CRLF command still walked"
}

# The sanctioned artifact heredoc: a quoted-delimiter body is never read,
# whatever words it carries. executor-read and executor-research have no
# Write tool, so this is their only record path.
case_artifact_heredoc_bodies() {
    local art="cat > ${OWN_DIR}/STEP-42-findings.md <<'EOF'"
    assert_verdict "${art}"$'\nThe test server is started with `node server.js`. A leftover STEP-7.d sat beside my dir.\nEOF' executor-read "$WAVE_42" ALLOW "body naming node and a sibling dir"
    assert_verdict "${art}"$'\nRecommendation: the conductor should run `docket step reap STEP-7`. The fixture loads .env before the suite.\nEOF' executor-read "$WAVE_42" ALLOW "body naming reap and .env"
    assert_verdict "${art}"$'\nkill 1234 appears in the README; the script runs `sh -c` unsafely.\nEOF' executor-research "$WAVE_42" ALLOW "body naming kill and sh -c"
    assert_verdict "${art}"$'\nThe Makefile target runs pkill -f devserver; that is fine for a python project.\nEOF' executor-read "$WAVE_42" ALLOW "body naming pkill and python"
    assert_verdict "${art}"$'\ngit worktree prune would fix it; git branch -D too.\nEOF' executor-write "$WAVE_42" ALLOW "body naming worktree prune and branch -D"
    # The interpreter test matches whole words of the code lines, never a
    # suffix: a target file named `cases.sh` widened the scan on its `.sh`
    # and a quoted body carrying the glob-form step token was denied
    # (recorded in a threat model with the cause then unknown). A quoted
    # interpreter word still widens: `"sh"` is `sh`, `"x.sh"` is not.
    local sh_target="cat > ${OWN_DIR}/probe/tests/cases.sh <<'EOF'"
    assert_verdict "cat > \"${OWN_DIR}/probe/tests/cases.sh\" <<'EOF'"$'\ngrep -rn \'STEP-[0-9]*\' .\nEOF' executor-read "$WAVE_42" ALLOW "own quoted .sh target: quoted body carrying the glob-form step token"
    assert_verdict $'"sh" <<\'EOF\'\nrm -rf '"${SIB_DIR}"$'\nEOF' executor-write "$WAVE_42" DENY "heredoc fed to a double-quoted sh is code"
    assert_verdict $'\'/bin/sh\' <<\'EOF\'\nrm -rf '"${SIB_DIR}"$'\nEOF' executor-write "$WAVE_42" DENY "heredoc fed to a single-quoted /bin/sh is code"
    assert_verdict $'sh<<\'EOF\'\nrm -rf '"${SIB_DIR}"$'\nEOF' executor-write "$WAVE_42" DENY "heredoc fed to sh with no blank before the operator is code"
    # An interpreter glued to the substitution that runs it: a whitespace-only
    # boundary missed these and let the body run unread.
    assert_verdict $'x=$(sh <<\'EOF\'\nrm -rf '"${SIB_DIR}"$'\nEOF\n)' executor-write "$WAVE_42" DENY "heredoc fed to sh inside an assignment's substitution is code"
    assert_verdict $'x=`sh <<\'EOF\'\nrm -rf '"${SIB_DIR}"$'\nEOF\n`' executor-write "$WAVE_42" DENY "heredoc fed to sh inside an assignment's backticks is code"
    assert_verdict "${sh_target}"$'\ngrep -rn \'STEP-[0-9]*\' .\nEOF' executor-read "$WAVE_42" ALLOW "own .sh target: quoted body carrying the glob-form step token"
    assert_verdict "${sh_target}"$'\nFound a leftover STEP-7.d beside my own dir.\nEOF' executor-read "$WAVE_42" ALLOW "own .sh target: quoted body naming a sibling dir"
    assert_verdict "cat > ${OWN_DIR}/probe/.env <<'EOF'"$'\nrm -rf '"${SIB_DIR}"$'\nEOF' executor-write "$WAVE_42" ALLOW "own .env target: quoted body is still inert"
    assert_verdict "cat > ${OWN_DIR}/probe/tests/cases.sh <<EOF"$'\nrm -rf '"${SIB_DIR}"$'\nEOF' executor-write "$WAVE_42" DENY "own .sh target: unquoted body is still scanned"
    assert_verdict $'/bin/sh <<\'EOF\'\nrm -rf '"${SIB_DIR}"$'\nEOF' executor-write "$WAVE_42" DENY "heredoc fed to /bin/sh (path-prefixed word) is code"
    assert_verdict $'env sh <<\'EOF\'\nrm -rf '"${SIB_DIR}"$'\nEOF' executor-write "$WAVE_42" DENY "heredoc fed through env to sh is code"
    # An interpreter name inside another leaf's quoted prose argument is not
    # a command word, so it does not widen the artifact body beside it.
    local prose_name
    for prose_name in zsh bash python3; do
        assert_verdict "cat > ${OWN_DIR}/a.md <<'EOF'"$'\nx `repeat 1 docket step reap STEP-7 --reason x` y\nEOF\n'"printf 'see ${prose_name} here' > ${OWN_DIR}/b.md" executor-read "$WAVE_42" ALLOW "quoted body beside a printf whose prose names ${prose_name}"
    done
    # The same bodies consumed by an interpreter are code.
    assert_verdict $'sh <<\'EOF\'\nrm -rf '"${SIB_DIR}"$'\nEOF' executor-write "$WAVE_42" DENY "heredoc fed to sh is code"
    assert_verdict $'python3 - <<\'EOF\'\nimport shutil; shutil.rmtree("'"${SIB_DIR}"$'")\nEOF' executor-write "$WAVE_42" DENY "heredoc fed to python is code"
}

# A substitution whose body spans lines is one leaf to the probe, which
# vetoes it before the body runs; every body line is matched as its own leaf.
# Only a quoted-delimiter heredoc body, up to its terminator line, is skipped.
# bash 5.2 reprints the body onto the opener line instead, so the verbs after
# a substitution opener are matched too, on one line as on several.
case_multiline_substitutions() {
    assert_verdict 'echo $(pkill node)' executor-write "$WAVE_42" DENY "one-line \$( ) body holding pkill"
    assert_verdict 'echo "$(pkill node)"' executor-write "$WAVE_42" DENY "one-line \$( ) in double quotes holding pkill"
    assert_verdict "echo '\$(pkill node)'" executor-write "$WAVE_42" ALLOW "a single-quoted \$( ) is data"
    assert_verdict 'echo `pkill node`' executor-write "$WAVE_42" DENY "one-line backtick body holding pkill"
    assert_verdict 'cat <(pkill node)' executor-write "$WAVE_42" DENY "one-line process substitution holding pkill"
    assert_verdict 'echo $(ls; pkill node)' executor-write "$WAVE_42" DENY "pkill after a separator inside a \$( )"
    assert_verdict 'echo $(sudo pkill node)' executor-write "$WAVE_42" DENY "pkill behind a wrapper inside a \$( )"
    assert_verdict 'echo $(docket step reap STEP-7 --reason x)' executor-write "$WAVE_42" DENY "one-line \$( ) body holding docket step reap"
    assert_verdict 'echo $(grep -rn pkill hooks/)' executor-write "$WAVE_42" ALLOW "pkill as an argument inside a \$( ) is a read"
    # bash 5 walks a coproc body in a child whose stdout is the coproc pipe;
    # the probe writes its frames to a saved fd so they still arrive.
    assert_verdict 'coproc { pkill node; }' executor-write "$WAVE_42" DENY "coproc body holding pkill"
    assert_verdict 'coproc X { pkill node; }' executor-write "$WAVE_42" DENY "named coproc body holding pkill"
    # bash 3.2 has no coproc keyword and reports `coproc` as the command name,
    # while zsh runs the rest as a coprocess: the verb resolves past it.
    assert_verdict 'coproc pkill node' executor-write "$WAVE_42" DENY "coproc simple command running pkill"
    assert_verdict 'coproc docket step reap STEP-7 --reason x' executor-write "$WAVE_42" DENY "coproc simple command running docket step reap"
    assert_verdict 'echo $(coproc pkill node)' executor-write "$WAVE_42" DENY "coproc pkill inside a \$( )"
    assert_verdict 'coproc grep -rn pkill hooks/' executor-write "$WAVE_42" ALLOW "coproc wrapping a read stays a read"
    assert_verdict $'echo $(\nrm -rf STEP-$s\n)' executor-write "$WAVE_42" DENY "multi-line \$( ) body holding a sibling rm"
    assert_verdict $'docket step artifacts $(\nrm -rf /tmp/claude-501/STEP-7.d\n)' executor-write "$WAVE_42" DENY "multi-line \$( ) body as a docket argument"
    assert_verdict $'echo `\nrm -rf STEP-$s\n`' executor-write "$WAVE_42" DENY "multi-line backtick body holding a sibling rm"
    assert_verdict $'docket step artifacts `\nrm -rf STEP-$s\n`' executor-write "$WAVE_42" DENY "multi-line backtick body as a docket argument"
    assert_verdict $'docket step artifacts <(\nrm -rf STEP-$s\n)' executor-write "$WAVE_42" DENY "multi-line process substitution as a docket argument"
    assert_verdict $'echo $(\nls\n)' executor-write "$WAVE_42" ALLOW "multi-line \$( ) body with a harmless command"
    assert_verdict $'echo $(\npkill node\n)' executor-write "$WAVE_42" DENY "multi-line \$( ) body holding pkill"
    assert_verdict $'echo $(\ndocket step reap STEP-7 --reason x\n)' executor-write "$WAVE_42" DENY "multi-line \$( ) body holding docket step reap"
    assert_verdict $'echo $(\necho \'rm -rf /tmp/claude-501/STEP-7.d\' | sh\n)' executor-write "$WAVE_42" DENY "interpreter on a body line widens the scan"
    assert_verdict $'git commit -m "$(cat <<\'EOF\'\nfix: clean STEP-7.d leftovers\nEOF\n)"' executor-write "$WAVE_42" ALLOW "quoted heredoc body inside a substitution stays inert"
    assert_verdict $'echo $(cat <<-\'EOF\'\n\tsaw STEP-7.d beside mine\n\tEOF\n)' executor-write "$WAVE_42" ALLOW "<<- body ends at its tab-indented terminator"
    assert_verdict $'cat > "${D}/notes.md" <<\'EOF\'\nsaw STEP-7.d beside mine\nEOF' executor-write "$WAVE_42" ALLOW "a \${ } word before a quoted heredoc leaves the body inert"
    assert_verdict $'echo $(cat <<\'EOF\'\nfoo\nEOF\nrm -rf /tmp/claude-501/STEP-7.d\n)' executor-write "$WAVE_42" DENY "a line after the quoted heredoc terminator is code"
    assert_verdict $'echo $(cat <<\'EOF\'\nrm -rf /tmp/claude-501/STEP-7.d\n)' executor-write "$WAVE_42" DENY "an unterminated quoted heredoc keeps its lines"
    assert_verdict $'echo $(\necho "<<\'EOF\'"\nrm -rf /tmp/claude-501/STEP-7.d\nEOF\n)' executor-write "$WAVE_42" DENY "a heredoc operator inside double quotes is not one"
    assert_verdict $'echo $(\n# <<\'EOF\'\nrm -rf /tmp/claude-501/STEP-7.d\nEOF\n)' executor-write "$WAVE_42" DENY "a heredoc operator inside a comment is not one"
    # Bash 3.2 finds the end of a substitution by a paren and quote scan that
    # ignores heredocs, so a `)` in a body inside a substitution closes it and
    # the rest of that line runs. A balanced body stays inert.
    assert_verdict $'echo $(cat <<\'EOF\'\nfoo\n) $(rm -rf '"${SIB_DIR}"$') "\nEOF\n"' executor-write "$WAVE_42" DENY "a close paren in a heredoc body ends the substitution (quote after)"
    assert_verdict $'echo $(cat <<\'EOF\'\n) $(rm -rf '"${SIB_DIR}"$') $(:\nEOF\n)' executor-write "$WAVE_42" DENY "a close paren in a heredoc body ends the substitution (reopened)"
    assert_verdict $'git commit -m "$(cat <<\'EOF\'\nfix(hooks): clean STEP-7.d leftovers\nEOF\n)"' executor-write "$WAVE_42" ALLOW "balanced parens in a heredoc body inside a substitution stay inert"
    # The terminator line is outside every quote for that scan, so a `)` in
    # a quoted delimiter closes the substitution on the terminator line.
    assert_verdict $'echo $(cat <<\') <(rm -rf '"${SIB_DIR}"$') <(:\'\nfoo\n) <(rm -rf '"${SIB_DIR}"$') <(:\n)' executor-write "$WAVE_42" DENY "a close paren on the terminator line ends the substitution (<( ) form)"
    assert_verdict $'echo $(cat <<\') >(rm -rf '"${SIB_DIR}"$') >(:\'\nfoo\n) >(rm -rf '"${SIB_DIR}"$') >(:\n)' executor-write "$WAVE_42" DENY "a close paren on the terminator line ends the substitution (>( ) form)"
    assert_verdict $'docket step artifacts $(cat <<\') <(rm -rf '"${SIB_DIR}"$') <(:\'\nfoo\n) <(rm -rf '"${SIB_DIR}"$') <(:\n)' executor-write "$WAVE_42" DENY "a close paren on the terminator line, as a docket argument"
    assert_verdict $'echo $(cat <<\') <(rm -rf '"${SIB_DIR}"$') <(:\'\n) <(rm -rf '"${SIB_DIR}"$') <(:\n)' executor-write "$WAVE_42" DENY "a close paren on the terminator line of an empty body"
    # Each character the scan reads differently from plain text makes the
    # body read: a quote, a backtick or a backslash hides a paren from it,
    # and so does a `#` comment. `$` is kept in the class defensively.
    assert_verdict $'echo $(cat <<\'EOF\'\nx \'(\' y\n) <(rm -rf '"${SIB_DIR}"$') \'\nEOF\n\'' executor-write "$WAVE_42" DENY "a single-quoted paren in a heredoc body is hidden from the scan"
    assert_verdict $'echo $(cat <<\'EOF\'\nx "(" y\n) <(rm -rf '"${SIB_DIR}"$') "\nEOF\n"' executor-write "$WAVE_42" DENY "a double-quoted paren in a heredoc body is hidden from the scan"
    assert_verdict $'echo $(cat <<\'EOF\'\nx `(` y\n) <(rm -rf '"${SIB_DIR}"$') `\nEOF\n`' executor-write "$WAVE_42" DENY "a backtick-quoted paren in a heredoc body is hidden from the scan"
    assert_verdict $'echo $(cat <<\'EOF\'\n# (\n) <(rm -rf '"${SIB_DIR}"$') <(: # )\nEOF\n)' executor-write "$WAVE_42" DENY "a commented paren in a heredoc body is hidden from the scan"
    assert_verdict $'echo $(cat <<\'EOF\'\nx \\(\n) <(rm -rf '"${SIB_DIR}"$') <(: \\)\nEOF\n)' executor-write "$WAVE_42" DENY "a backslash-escaped paren in a heredoc body is hidden from the scan"
    assert_verdict $'git commit -m "$(cat <<\'EOF\'\nfix: pass $HOME through\nsee STEP-7.d for details\nEOF\n)"' executor-write "$WAVE_42" DENY "accepted false deny: a \$ in a commit body naming a sibling dir"
    assert_verdict $'git commit -m "$(cat <<\'EOF\'\nfix: pass $HOME through\nsee the notes for details\nEOF\n)"' executor-write "$WAVE_42" ALLOW "a \$ in a commit body naming no sibling dir"
    assert_verdict $'git commit -m "$(cat <<\'EOF\'\nfix: refs #12\nsee STEP-7.d for details\nEOF\n)"' executor-write "$WAVE_42" DENY "accepted false deny: a # in a commit body naming a sibling dir"
    assert_verdict $'git commit -m "$(cat <<\'EOF\'\nfix: path C:\\tmp\nsee STEP-7.d for details\nEOF\n)"' executor-write "$WAVE_42" DENY "accepted false deny: a backslash in a commit body naming a sibling dir"
    # A heredoc body starts after the first newline at the operator's own
    # nesting level: a substitution opened after the operator holds its
    # newlines, and one that closed around the operator leaves no body.
    assert_verdict $'echo "$(cat <<\'E\' $(\nrm -rf '"${SIB_DIR}"$'\n)\nE\n)"' executor-write "$WAVE_42" DENY "a \$( ) opened after a heredoc operator holds its newline"
    assert_verdict $'echo "$(cat <<\'E\' <(\nrm -rf '"${SIB_DIR}"$'\n)\nE\n)"' executor-write "$WAVE_42" DENY "a <( ) opened after a heredoc operator holds its newline"
    assert_verdict $'docket step artifacts "$(cat <<\'E\' $(\nrm -rf '"${SIB_DIR}"$'\n)\nE\n)"' executor-write "$WAVE_42" DENY "a \$( ) after a heredoc operator, as a docket argument"
    assert_verdict $'echo "$(cat <<\'E\' $(\npkill node\n)\nE\n)"' executor-write "$WAVE_42" DENY "a \$( ) opened after a heredoc operator hides no pkill"
    assert_verdict $'echo "$(cat <<\'E\' $(\nrm -rf '"${SIB_DIR}"$'\nE\n)\n)"' executor-write "$WAVE_42" DENY "a \$( ) opened after a heredoc operator holds its terminator line too"
    if [ "$COMSUB_REPRINTED" = 1 ]; then
        assert_verdict $'echo "$(echo $(cat <<\'E\')\nrm -rf '"${SIB_DIR}"$'\nE\n)"' executor-write "$WAVE_42" ALLOW "bash 5.2: a heredoc whose substitution closed on its line still reads the next lines as its body"
    else
        assert_verdict $'echo "$(echo $(cat <<\'E\')\nrm -rf '"${SIB_DIR}"$'\nE\n)"' executor-write "$WAVE_42" DENY "a heredoc whose substitution closed on its line has no body"
    fi
    # Accepted false denies: every code line of a leaf is matched, and the
    # interpreter test reads them all.
    assert_verdict $'echo "multi\nuse node STEP-7.d prose"' executor-write "$WAVE_42" DENY "accepted false deny: interpreter word on a later line of quoted prose"
    assert_verdict $'echo "multi\nline STEP-7.d prose"' executor-write "$WAVE_42" ALLOW "multi-line quoted prose naming a sibling dir"
    if [ "$COMSUB_REPRINTED" = 1 ]; then
        assert_verdict $'echo $(\n# see STEP-7.d\nls\n)' executor-write "$WAVE_42" ALLOW "bash 5.2: a comment line in a substitution body is dropped by the parse"
    else
        assert_verdict $'echo $(\n# see STEP-7.d\nls\n)' executor-write "$WAVE_42" DENY "accepted false deny: comment line in a substitution body"
    fi
    # Further substitution shapes.
    assert_verdict $'echo "$(\nrm -rf '"${SIB_DIR}"$'\n)"' executor-write "$WAVE_42" DENY "multi-line \$( ) inside double quotes"
    assert_verdict $'echo $(echo $(\nrm -rf '"${SIB_DIR}"$'\n))' executor-write "$WAVE_42" DENY "nested multi-line \$( )"
    assert_verdict $'echo $(ls\nrm -rf '"${SIB_DIR}"$')' executor-write "$WAVE_42" DENY "multi-line \$( ) whose body starts on the opener line"
    assert_verdict $'for d in $(\nrm -rf '"${SIB_DIR}"$'\n); do echo; done' executor-write "$WAVE_42" DENY "multi-line \$( ) in a for-loop word list"
    assert_verdict $'tee >(\nrm -rf '"${SIB_DIR}"$'\n) </dev/null' executor-write "$WAVE_42" DENY "multi-line >( ) process substitution"
    assert_verdict $'x=$(\nrm -rf '"${SIB_DIR}"$'\n)' executor-write "$WAVE_42" DENY "multi-line \$( ) in an assignment"
    assert_verdict $'echo $(cat <<\'A\' <<\'B\'\nsaw STEP-7.d\nA\nsaw STEP-7.d\nB\nrm -rf '"${SIB_DIR}"$'\n)' executor-write "$WAVE_42" DENY "a line after the second of two heredocs is code"
    assert_verdict $'echo $(cat <<\'A\' <<\'B\'\nsaw STEP-7.d\nA\nsaw STEP-7.d\nB\n)' executor-write "$WAVE_42" ALLOW "two quoted heredoc bodies on one line stay inert"
    assert_verdict $'echo $(cat <<\'EOF\' \\\n'"${SIB_DIR}"$'\nEOF\n)' executor-write "$WAVE_42" DENY "a backslash-newline continues the heredoc operator line"
    # Wherever the lexer could misread bash it stops skipping and keeps every
    # remaining line, so these bodies are read.
    assert_verdict $'echo $(echo `date` <<\'EOF\'\nrm -rf '"${SIB_DIR}"$'\nEOF\n)' executor-write "$WAVE_42" DENY "fails toward reading: a backtick before the operator"
    assert_verdict $'echo $(echo $[1] <<\'EOF\'\nrm -rf '"${SIB_DIR}"$'\nEOF\n)' executor-write "$WAVE_42" DENY "fails toward reading: \$[ ] before the operator"
    assert_verdict $'echo $(echo $(( "1" )) <<\'EOF\'\nrm -rf '"${SIB_DIR}"$'\nEOF\n)' executor-write "$WAVE_42" DENY "fails toward reading: a quote inside \$(( ))"
    assert_verdict $'echo $(cat <<\'E$X\'\nrm -rf '"${SIB_DIR}"$'\nE$X\n)' executor-write "$WAVE_42" DENY "fails toward reading: an expansion inside a quoted delimiter"
    assert_verdict $'echo $(cat <<E$X\nnode \'rm -rf '"${SIB_DIR}"$'\'\nE$X\n)' executor-write "$WAVE_42" DENY "an expansion in an unquoted delimiter keeps the body read"
    assert_verdict $'cat <<E$X\nnode\nE$X\ncat <<\'Q\'\nsaw STEP-7.d\nQ' executor-write "$WAVE_42" DENY "fails toward reading: an expansion in an unquoted delimiter feeds the interpreter test"
    assert_verdict $'echo "${x:-\'a\'}" <<\'EOF\'\nsaw STEP-7.d\nEOF' executor-write "$WAVE_42" DENY "fails toward reading: a single quote inside \${ } within double quotes"
}

# Verb spellings: case, wrappers, docket global flags, function wrappers.
case_verb_spellings() {
    assert_verdict "PKILL node" executor-write "$WAVE_42" DENY "uppercase PKILL (case-insensitive filesystem)"
    assert_verdict "Killall node" executor-write "$WAVE_42" DENY "mixed-case Killall"
    assert_verdict "GIT worktree prune" executor-write "$WAVE_42" DENY "uppercase GIT"
    assert_verdict "DOCKET step reap STEP-7 --reason x" executor-write "$WAVE_42" DENY "uppercase DOCKET"
    assert_verdict "docket --json step reap STEP-7 --reason x" executor-write "$WAVE_42" DENY "docket --json before the subcommand"
    assert_verdict "docket -q step reap STEP-7 --reason x" executor-write "$WAVE_42" DENY "docket -q before the subcommand"
    assert_verdict "docket --format json step reap STEP-7 --reason x" executor-write "$WAVE_42" DENY "docket --format json before the subcommand"
    assert_verdict "docket --interval 5s step reap STEP-7 --reason x" executor-write "$WAVE_42" DENY "docket --interval 5s before the subcommand"
    assert_verdict "docket --interval=5s step reap STEP-7 --reason x" executor-write "$WAVE_42" DENY "docket --interval=5s before the subcommand"
    assert_verdict "rm() { command rm \"\$@\"; }; rm -rf ${SIB_DIR}" executor-write "$WAVE_42" DENY "function wrapper around rm"
    assert_verdict "git() { command git \"\$@\"; }; git worktree prune" executor-write "$WAVE_42" DENY "function wrapper around git"
    assert_verdict "kill() { command kill \"\$@\"; }; kill 1234" executor-write "$WAVE_42" DENY "function wrapper around kill"
    assert_verdict "docket() { command docket \"\$@\"; }; docket step reap STEP-7 --reason x" executor-write "$WAVE_42" DENY "function wrapper around docket"
    assert_verdict "DOCKET run conduct RUN-5" executor-write "$WAVE_42" DENY "uppercase DOCKET run conduct"
    assert_verdict "docket --json=v2 run conduct RUN-5" executor-write "$WAVE_42" DENY "docket --json=v2 before run conduct"
    assert_verdict "docket --format json run conduct RUN-5" executor-write "$WAVE_42" DENY "docket --format json before run conduct"
    assert_verdict "docket --interval 5s run conduct RUN-5" executor-write "$WAVE_42" DENY "docket --interval 5s before run conduct"
    assert_verdict "docket() { command docket \"\$@\"; }; docket run conduct RUN-5" executor-write "$WAVE_42" DENY "function wrapper around docket run conduct"
    assert_verdict "sudo pkill node" executor-write "$WAVE_42" DENY "sudo prefix"
    assert_verdict "xargs pkill < list" executor-write "$WAVE_42" DENY "xargs prefix"
    assert_verdict "timeout 5 pkill node" executor-write "$WAVE_42" DENY "timeout prefix with a duration"
    assert_verdict "timeout \$t pkill node" executor-write "$WAVE_42" DENY "timeout prefix with a parameter duration"
    assert_verdict "timeout 1.5 pkill node" executor-write "$WAVE_42" DENY "timeout prefix with a fractional duration"
    assert_verdict "timeout 5 ls" executor-write "$WAVE_42" ALLOW "timeout prefix with a duration before a read"
    assert_verdict "env FOO=1 pkill node" executor-write "$WAVE_42" DENY "env prefix with an assignment"
    assert_verdict "nice -n 5 killall node" executor-write "$WAVE_42" DENY "nice prefix with an option value"
    # A wrapper option whose value is a separate word of any shape. The
    # timeout rows keep the mandatory DURATION after the option value.
    assert_verdict "sudo -u root pkill node" executor-write "$WAVE_42" DENY "sudo -u value before pkill"
    assert_verdict "env -u FOO pkill node" executor-write "$WAVE_42" DENY "env -u value before pkill"
    assert_verdict "sudo -g wheel pkill node" executor-write "$WAVE_42" DENY "sudo -g value before pkill"
    assert_verdict "sudo -C \$fd pkill node" executor-write "$WAVE_42" DENY "sudo -C value before pkill"
    assert_verdict "sudo -D /tmp pkill node" executor-write "$WAVE_42" DENY "sudo -D value before pkill"
    assert_verdict "env -C /tmp pkill node" executor-write "$WAVE_42" DENY "env -C value before pkill"
    assert_verdict "env -S x pkill node" executor-write "$WAVE_42" DENY "env -S value before pkill"
    assert_verdict "ionice -c idle pkill node" executor-write "$WAVE_42" DENY "ionice -c value before pkill"
    assert_verdict "ionice -n \$n pkill node" executor-write "$WAVE_42" DENY "ionice -n value before pkill"
    assert_verdict "timeout -s KILL 1.5 pkill node" executor-write "$WAVE_42" DENY "timeout -s value before pkill"
    assert_verdict "timeout -k 1.5 1.5 pkill node" executor-write "$WAVE_42" DENY "timeout -k value before pkill"
    assert_verdict "stdbuf -i 1K pkill node" executor-write "$WAVE_42" DENY "stdbuf -i value before pkill"
    assert_verdict "stdbuf -o L pkill node" executor-write "$WAVE_42" DENY "stdbuf -o value before pkill"
    assert_verdict "stdbuf -e L pkill node" executor-write "$WAVE_42" DENY "stdbuf -e value before pkill"
    assert_verdict "sudo -u root ls" executor-write "$WAVE_42" ALLOW "sudo -u value before a read stays a read"
    # A value that is itself a verb stays the verb: env -S runs its value.
    assert_verdict "env -S 'kill 1234'" executor-write "$WAVE_42" DENY "env -S value running a literal-pid kill"
    assert_verdict "env -S \"pkill node\"" executor-write "$WAVE_42" DENY "env -S value running pkill"
    assert_verdict "command kill 1234" executor-write "$WAVE_42" DENY "command prefix"
    # zsh precommand modifiers that bash reads as the command name.
    assert_verdict "noglob pkill node" executor-write "$WAVE_42" DENY "zsh noglob prefix"
    assert_verdict "nocorrect killall node" executor-write "$WAVE_42" DENY "zsh nocorrect prefix"
    assert_verdict "- pkill node" executor-write "$WAVE_42" DENY "zsh - prefix leading the command"
    assert_deny_reason "- pkill node" executor-write "$WAVE_42" "addresses processes by name across the whole machine" "zsh - prefix leading the command resolves to pkill"
    assert_verdict "- ls" executor-write "$WAVE_42" ALLOW "zsh - prefix leading a read stays a read"
    assert_verdict "true; - pkill node" executor-write "$WAVE_42" DENY "zsh - prefix after a separator"
    assert_verdict "true && - killall node" executor-write "$WAVE_42" DENY "zsh - prefix after &&"
    assert_verdict "repeat 1 docket step reap STEP-7 --reason x" executor-write "$WAVE_42" DENY "zsh repeat with a count"
    # zsh evaluates the repeat count arithmetically, so any word there is the
    # count, and a lone `{` after it opens the body.
    assert_verdict "repeat 1+1 pkill node" executor-write "$WAVE_42" DENY "zsh repeat with an arithmetic count"
    assert_verdict "repeat \$n pkill node" executor-write "$WAVE_42" DENY "zsh repeat with a parameter count"
    assert_verdict "repeat \"1 + 1\" pkill node" executor-write "$WAVE_42" DENY "zsh repeat with a quoted multi-word count"
    assert_verdict "repeat 2 { pkill node }" executor-write "$WAVE_42" DENY "zsh repeat with a brace body"
    assert_verdict "repeat \$n { pkill node }" executor-write "$WAVE_42" DENY "zsh repeat with a parameter count and a brace body"
    assert_verdict "repeat 2 { { pkill node } }" executor-write "$WAVE_42" DENY "zsh repeat with nested brace bodies"
    assert_verdict "repeat 1 ls" executor-write "$WAVE_42" ALLOW "zsh repeat of a read stays a read"
    assert_verdict "repeat \$n ls" executor-write "$WAVE_42" ALLOW "zsh repeat with a parameter count of a read stays a read"
    assert_verdict "repeat 1+1 ls" executor-write "$WAVE_42" ALLOW "zsh repeat with an arithmetic count of a read stays a read"
    assert_verdict "repeat x+1 noglob pkill node" executor-write "$WAVE_42" DENY "zsh repeat count then a modifier"
    assert_verdict "repeat 2 { noglob pkill node }" executor-write "$WAVE_42" DENY "zsh repeat brace body then a modifier"
    assert_verdict "repeat \$n repeat 1+1 pkill node" executor-write "$WAVE_42" DENY "nested zsh repeat"
    assert_verdict "echo \$(repeat 1+1 pkill node)" executor-write "$WAVE_42" DENY "zsh repeat inside a \$( )"
    assert_verdict "repeat 2 kill 4242" executor-write "$WAVE_42" DENY "zsh repeat count resolves the verb for a pid kill"
    assert_verdict "repeat x+1 noglob kill 4242" executor-write "$WAVE_42" DENY "zsh repeat count then a modifier resolves the verb for a pid kill"
    # The pre-pass splits one count word built from glued quoted parts or a
    # quoted expansion into several tokens, and a quoted blank leaves no token
    # at all, so the end of the count cannot be found: a name-addressed kill or
    # an engine verb anywhere after `repeat` denies.
    assert_verdict "repeat 1\"+1\" pkill node" executor-write "$WAVE_42" DENY "zsh repeat count with a glued double-quoted tail"
    assert_verdict "repeat \"1\"+1 pkill node" executor-write "$WAVE_42" DENY "zsh repeat count with a glued double-quoted head"
    assert_verdict "repeat 1' '+1 pkill node" executor-write "$WAVE_42" DENY "zsh repeat count glued across a quoted blank"
    assert_verdict "repeat 1+' 'x pkill node" executor-write "$WAVE_42" DENY "zsh repeat count glued across a quoted blank before a name"
    assert_verdict "repeat \$n' 'x pkill node" executor-write "$WAVE_42" DENY "zsh repeat parameter count glued across a quoted blank"
    assert_verdict "repeat 1' '-' 'x pkill node" executor-write "$WAVE_42" DENY "zsh repeat count glued across quoted blanks around an operator"
    assert_verdict "repeat 1'+1' killall node" executor-write "$WAVE_42" DENY "zsh repeat count with a glued single-quoted tail before killall"
    assert_verdict "repeat 1'+1' docket run conduct RUN-5" executor-write "$WAVE_42" DENY "zsh repeat glued count before docket run conduct"
    assert_verdict "repeat \"\$(echo 2)\" pkill node" executor-write "$WAVE_42" DENY "zsh repeat count from a quoted substitution"
    assert_verdict "repeat \"\${n} + 1\" pkill node" executor-write "$WAVE_42" DENY "zsh repeat count from a quoted braced expansion"
    assert_verdict "repeat \$(( 1 + 1 )) pkill node" executor-write "$WAVE_42" DENY "zsh repeat count from an arithmetic expansion"
    assert_verdict "repeat \$( echo 2 ) pkill node" executor-write "$WAVE_42" DENY "zsh repeat count from a spaced \$( ) substitution"
    assert_verdict "repeat \`echo 2\` pkill node" executor-write "$WAVE_42" DENY "zsh repeat count from a spaced backtick substitution"
    assert_verdict "echo \$(repeat 1'+1' pkill node)" executor-write "$WAVE_42" DENY "zsh repeat glued count inside a \$( )"
    assert_verdict "command repeat pkill node" executor-write "$WAVE_42" DENY "a name-addressed kill read as a repeat count"
    assert_verdict "repeat 1 echo \"stop pkill now\"" executor-write "$WAVE_42" ALLOW "zsh repeat with prose naming a kill stays a read"
    # Accepted false DENY: a protected verb as data after `repeat`.
    assert_verdict "repeat 3 echo pkill" executor-write "$WAVE_42" DENY "zsh repeat with a kill name as data"
    assert_verdict "nocorrect noglob pkill node" executor-write "$WAVE_42" DENY "stacked zsh modifiers"
    assert_verdict "echo \$(noglob pkill node)" executor-write "$WAVE_42" DENY "zsh noglob prefix inside a \$( )"
    assert_verdict "noglob ls" executor-write "$WAVE_42" ALLOW "zsh noglob wrapping a read stays a read"
    assert_verdict "nocorrect ls" executor-write "$WAVE_42" ALLOW "zsh nocorrect wrapping a read stays a read"
    assert_verdict "true; - ls" executor-write "$WAVE_42" ALLOW "zsh - prefix on a read after a separator stays a read"
    assert_verdict "true && - ls" executor-write "$WAVE_42" ALLOW "zsh - prefix on a read after && stays a read"
    # zsh `=cmd` equals expansion, which bash reads as a literal name.
    assert_verdict "=pkill node" executor-write "$WAVE_42" DENY "zsh =cmd expansion of pkill"
    assert_verdict "noglob =pkill node" executor-write "$WAVE_42" DENY "zsh =cmd expansion after noglob"
    assert_verdict "=git worktree prune" executor-write "$WAVE_42" DENY "zsh =cmd expansion of git"
    assert_verdict "=ls" executor-write "$WAVE_42" ALLOW "zsh =cmd expansion of a read stays a read"
    # zsh opens a brace group on a `{` glued to the verb; bash brace-expands
    # `{a,b}` and runs its first element.
    assert_verdict "{pkill node}" executor-write "$WAVE_42" DENY "zsh glued brace group around pkill"
    assert_verdict "{=pkill node}" executor-write "$WAVE_42" DENY "zsh glued brace group around =pkill"
    assert_verdict "{ls}" executor-write "$WAVE_42" ALLOW "zsh glued brace group around a read stays a read"
    assert_verdict "{pkill,x} node" executor-write "$WAVE_42" DENY "brace expansion whose first element is pkill"
    assert_verdict "\${HOME}/bin/pkill node" executor-write "$WAVE_42" DENY "a braced parameter in the verb's directory still resolves to pkill"
    assert_verdict "x=pkill; echo ok" executor-write "$WAVE_42" ALLOW "assignment whose value names pkill"
    # A leading assignment prefixes the command; the verb is after it.
    assert_verdict "FOO=1 pkill node" executor-write "$WAVE_42" DENY "assignment prefix before pkill"
    assert_verdict "FOO=1 killall node" executor-write "$WAVE_42" DENY "assignment prefix before killall"
    assert_verdict "FOO=1 git worktree prune" executor-write "$WAVE_42" DENY "assignment prefix before git worktree prune"
    assert_verdict "FOO=1 docket run conduct" executor-write "$WAVE_42" DENY "assignment prefix before docket run conduct"
    assert_verdict "FOO=1 ls" executor-write "$WAVE_42" ALLOW "assignment prefix before a read"
    assert_verdict "FOO=1" executor-write "$WAVE_42" ALLOW "assignment-only leaf"
    assert_verdict "FOO=\"a b\" pkill node" executor-write "$WAVE_42" DENY "assignment prefix with a quoted multi-word value before pkill"
    assert_verdict "echo \$(FOO=1 pkill node)" executor-write "$WAVE_42" DENY "assignment prefix before pkill inside a \$( )"
    assert_verdict "FOO=\$(pkill node)" executor-write "$WAVE_42" DENY "pkill in an assignment's substitution"
    assert_verdict "/usr/bin/env pkill node" executor-write "$WAVE_42" DENY "env by absolute path"
    assert_verdict "\\pkill node" executor-write "$WAVE_42" DENY "backslash-escaped verb"
    assert_verdict "pk\\ill node" executor-write "$WAVE_42" DENY "backslash inside the verb"
    assert_verdict "grep -rn 'pkill' src/user/claude_code/hooks/" executor-read "$WAVE_42" ALLOW "pkill as a grep pattern is a read"
    assert_verdict "grep -rn pkill src/user/claude_code/hooks/" executor-read "$WAVE_42" ALLOW "unquoted pkill as a grep pattern is a read"
    assert_verdict "rg 'kill -9' tests/" executor-read "$WAVE_42" ALLOW "kill inside a search pattern"
    assert_verdict "man pkill" executor-read "$WAVE_42" ALLOW "man pkill"
    assert_verdict "docket step show STEP-7 --json=v2 | jq .reap" executor-read "$WAVE_42" ALLOW "reap as a jq field"
    # Residuals, pinned ALLOW.
    assert_verdict "p\"\"kill node" executor-write "$WAVE_42" ALLOW "residual: verb split by empty quotes"
    assert_verdict "k=pkill; \$k node" executor-write "$WAVE_42" ALLOW "residual: verb reached through a variable"
    assert_verdict "\$(which pkill) node" executor-write "$WAVE_42" ALLOW "residual: verb reached through \$(which)"
    assert_verdict "x='rm -rf ${SIB_DIR}'; \$x" executor-write "$WAVE_42" ALLOW "residual: command string carried in a variable"
}

# Scratch-dir spellings beyond the plain path.
case_scratch_spellings() {
    assert_verdict "N=7; rm -rf /tmp/claude-501/STEP-\${N}.d" executor-write "$WAVE_42" DENY "expansion in the id (braced)"
    assert_verdict "for n in 7 8; do rm -rf /tmp/claude-501/STEP-\$n.d; done" executor-write "$WAVE_42" DENY "expansion in the id inside a loop body"
    assert_verdict "rm -rf /tmp/claude-501/STEP-\$((6+1)).d" executor-write "$WAVE_42" DENY "arithmetic in the id"
    assert_verdict "rm -rf /tmp/claude-501/STEP-\$(echo 7).d" executor-write "$WAVE_42" DENY "command substitution in the id"
    assert_verdict "rm -rf \"/tmp/claude-501/STEP-\$N.d\"" executor-write "$WAVE_42" DENY "expansion in the id, double-quoted"
    assert_verdict "rm -rf /tmp/claude-501/STEP-7.[d]" executor-write "$WAVE_42" DENY "glob standing for the d"
    assert_verdict "rm -rf /tmp/claude-501/STEP-7.?" executor-write "$WAVE_42" DENY "? standing for the d"
    assert_verdict "rm -rf /tmp/claude-501/STEP-7.*" executor-write "$WAVE_42" DENY "* after the dot"
    assert_verdict "rm -rf /tmp/claude-501/STEP-7*" executor-write "$WAVE_42" DENY "* after the id"
    assert_verdict "rm -rf /tmp/claude-501/STEP-7\\.d" executor-write "$WAVE_42" DENY "backslash before the dot"
    assert_verdict "rm -rf ${OWN_DIR}/.\\./" executor-write "$WAVE_42" DENY "own dir then a backslashed .."
    assert_verdict "find /tmp/claude-501 -mindepth 1 -maxdepth 1 -type d ! -name STEP-42.d -exec rm -rf {} +" executor-write "$WAVE_42" DENY "find negating the own name"
    assert_verdict "find /tmp/claude-501 -maxdepth 1 -not -name STEP-42.d -delete" executor-write "$WAVE_42" DENY "find -not the own name"
    assert_verdict "find ${OWN_DIR} -name '*.log' -delete" executor-write "$WAVE_42" ALLOW "find inside own dir with a name filter"
    assert_verdict "find ${OWN_DIR} ! -name keep.txt -delete" executor-write "$WAVE_42" ALLOW "find negating a plain name inside own dir"
    assert_verdict "rm -rf /tmp/claude-501/STEP-N.d" executor-write "$WAVE_42" ALLOW "the brief's STEP-N placeholder is not a token"
    # A docket argument that is a whole expansion-form step id names a step
    # to the engine, not a directory; any `.d`, glob or path form, any other
    # verb, and a redirect target stay tokens.
    assert_verdict "for s in 7 8; do docket step artifacts STEP-\$s; done" executor-write "$WAVE_42" ALLOW "docket read loop over sibling ids (\$s)"
    assert_verdict "for s in 7 8; do docket step artifacts STEP-\${s}; done" executor-write "$WAVE_42" ALLOW "docket read loop over sibling ids (\${s})"
    assert_verdict "docket step artifacts STEP-7" executor-write "$WAVE_42" ALLOW "docket read of a literal sibling id"
    assert_verdict "for s in 7 8; do rm -rf /tmp/claude-501/STEP-\$s.d; done" executor-write "$WAVE_42" DENY "rm loop over expansion-form sibling dirs"
    assert_verdict "for s in 7 8; do ls /tmp/claude-501/STEP-\$s.d; done" executor-write "$WAVE_42" DENY "ls loop over expansion-form sibling dirs"
    assert_verdict "for s in 7.d; do rm -rf /tmp/claude-501/STEP-\$s; done" executor-write "$WAVE_42" DENY "expansion carrying the .d, under a path"
    assert_verdict "for s in 7.d; do rm -rf STEP-\$s; done" executor-write "$WAVE_42" DENY "bare expansion-form id outside docket"
    assert_verdict "docket step record STEP-42 --artifact-file /tmp/claude-501/STEP-\$s.d/x" executor-write "$WAVE_42" DENY "docket argument naming an expansion-form .d path"
    assert_verdict "for s in 7 8; do docket step show STEP-42 > STEP-\$s; done" executor-write "$WAVE_42" DENY "expansion-form id as a docket leaf's redirect target"
    assert_verdict "docket step fail STEP-42 --note x < STEP-\$s" executor-write "$WAVE_42" DENY "expansion-form id as a docket leaf's input redirect"
    assert_verdict "docket step show STEP-42 <> STEP-\$s" executor-write "$WAVE_42" DENY "expansion-form id as a docket leaf's read-write redirect"
    assert_verdict "docket step artifacts STEP-\$s 3<> STEP-\$s" executor-write "$WAVE_42" DENY "expansion-form id after a numbered read-write redirect"
    assert_verdict "docket step show STEP-42 >& STEP-\$s" executor-write "$WAVE_42" DENY "expansion-form id after a >& redirect"
    # A substitution inside the docket leaf is a command the probe never
    # dispatches on its own, so its words are not docket arguments.
    assert_verdict "cd /tmp/claude-501 && for s in 7.d; do docket step show STEP-42 \$(rm -rf STEP-\$s ); done" executor-write "$WAVE_42" DENY "command substitution inside a docket leaf"
    assert_verdict "docket step artifacts \$(rm -rf STEP-\$s )" executor-write "$WAVE_42" DENY "command substitution as a docket argument"
    assert_verdict "docket step artifacts \`rm -rf STEP-\$s \`" executor-write "$WAVE_42" DENY "backtick substitution as a docket argument"
    assert_verdict "docket step artifacts <(rm -rf STEP-\$s )" executor-write "$WAVE_42" DENY "process substitution as a docket argument"
    # The admission is the whole word: any suffix, path or glob stays a token.
    assert_verdict "for s in 7 8; do docket step artifacts STEP-\$s.d; done" executor-write "$WAVE_42" DENY "docket argument STEP-\$s.d"
    assert_verdict "for s in 7 8; do docket step artifacts STEP-\${s}.d; done" executor-write "$WAVE_42" DENY "docket argument STEP-\${s}.d"
    assert_verdict "for s in 7 8; do docket step artifacts STEP-\$s/x; done" executor-write "$WAVE_42" DENY "docket argument STEP-\$s/x"
    assert_verdict "for s in 7 8; do docket step artifacts STEP-\$s*; done" executor-write "$WAVE_42" DENY "docket argument STEP-\$s*"
    assert_verdict "docket step artifacts STEP-\$(echo 7)" executor-write "$WAVE_42" DENY "docket argument STEP-\$(echo 7)"
    # Wrapper and path spellings resolve to the docket verb; an interpreter
    # carrier and a compound with a .d operand do not get the admission.
    assert_verdict "for s in 7 8; do xargs docket step artifacts STEP-\$s; done" executor-write "$WAVE_42" ALLOW "xargs-prefixed docket read over sibling ids"
    assert_verdict "for s in 7 8; do /usr/bin/docket step artifacts STEP-\$s; done" executor-write "$WAVE_42" ALLOW "path-qualified docket read over sibling ids"
    assert_verdict "bash -c 'for s in 7 8; do docket step artifacts STEP-\$s; done'" executor-write "$WAVE_42" DENY "bash -c carrying a docket read loop (interpreter leaf, no admission)"
    assert_verdict "for s in 7 8; do docket step artifacts STEP-\$s; rm -rf /tmp/claude-501/STEP-\$s.d; done" executor-write "$WAVE_42" DENY "docket read beside an rm of the expansion-form .d"
    # Residuals, pinned ALLOW.
    assert_verdict "rm -rf /tmp/claude-501/STEP-\"7\".d" executor-write "$WAVE_42" ALLOW "residual: id split by quotes"
    assert_verdict "rm -rf /tmp/claude-501/S*-7.d" executor-write "$WAVE_42" ALLOW "residual: glob outside the id"
    assert_verdict "cd /tmp/claude-501 && rm -rf [S]TEP-7.d" executor-write "$WAVE_42" ALLOW "residual: glob on the first letter"
    assert_verdict "rm -rf ${OWN_DIR}/.\".\"/" executor-write "$WAVE_42" ALLOW "residual: .. split by quotes"
}

# A file inside the own dir whose name is the own id, a dash, then text that
# may carry a plain variable. Only that exact shape, after the own `.d`, is
# admitted; every other expansion near a step id stays a token.
case_own_leaf_expansions() {
    assert_verdict "for i in DOT-1 DOT-2; do docket issue show \$i --json > ${OWN_DIR}/STEP-42-\$i.json; done" executor-read "$WAVE_42" ALLOW "own leaf STEP-42-\$i.json as a loop's redirect target"
    assert_verdict "cat ${OWN_DIR}/STEP-42-\${i}.json" executor-read "$WAVE_42" ALLOW "own leaf STEP-42-\${i}.json read"
    assert_verdict "cat ${OWN_DIR}/STEP-42-\$i.json" executor-read "$WAVE_42" ALLOW "own leaf STEP-42-\$i.json read"
    assert_verdict "for i in a b; do jq . ${OWN_DIR}/STEP-42-\${i}.json > ${OWN_DIR}/STEP-42-out-\$i.json; done" executor-read "$WAVE_42" ALLOW "own leaf STEP-42-\${i} and STEP-42-out-\$i in one loop"
    assert_verdict "cat ${OWN_DIR}/STEP-42\$x" executor-read "$WAVE_42" DENY "expansion directly after the own digits inside own dir"
    assert_verdict "cat ${OWN_DIR}/../STEP-42\$x" executor-read "$WAVE_42" DENY "own dir, .., then expansion directly after the own digits"
    assert_verdict "cat STEP-42\$x" executor-read "$WAVE_42" DENY "bare expansion directly after the own digits"
    assert_verdict "cat ${SIB_DIR}/STEP-7-\$i.json" executor-read "$WAVE_42" DENY "foreign dir carrying a leaf of its own id"
    assert_verdict "cat ${OWN_DIR}/STEP-7-\$i.json" executor-read "$WAVE_42" DENY "own dir carrying a foreign leaf id"
    assert_verdict "cat ${OWN_DIR}/STEP-4-\$i.json" executor-read "$WAVE_42" DENY "own dir carrying a prefix of the own id"
    assert_verdict "cat ${OWN_DIR}/STEP-420-\$i.json" executor-read "$WAVE_42" DENY "own dir carrying the own id extended"
    assert_verdict "cat STEP-42-\$i.json" executor-read "$WAVE_42" DENY "own leaf shape without the own dir before it"
    assert_verdict "cat ${OWN_DIR}/STEP-42-\$i/../../STEP-7.d/t" executor-read "$WAVE_42" DENY "own leaf followed by a traversal into a sibling"
    assert_verdict "cat ${OWN_DIR}/STEP-42-\$(date).json" executor-read "$WAVE_42" DENY "command substitution in the own leaf"
    assert_verdict "cat ${OWN_DIR}/STEP-42-\${x:-y}.json" executor-read "$WAVE_42" DENY "parameter operator in the own leaf"
    assert_verdict "cat ${OWN_DIR}/STEP-42-\$1.json" executor-read "$WAVE_42" DENY "positional parameter in the own leaf"
    assert_verdict "find /tmp/claude-501 ! -name STEP-42-\$x -delete" executor-write "$WAVE_42" DENY "find negating an own-leaf-shaped name"
    assert_verdict "git worktree remove ${OWN_DIR}/STEP-42-\$p" executor-write "$WAVE_42" DENY "worktree remove of an own-leaf-shaped path stays a token"
    # A backtick substitution's closing backtick glued to the last word.
    assert_verdict "echo \"\`cat ${OWN_DIR}/STEP-42-note\`\"" executor-write "$WAVE_42" ALLOW "own file closing a double-quoted backtick substitution"
    assert_verdict "echo \`cat ${OWN_DIR}/STEP-42-note\`" executor-write "$WAVE_42" ALLOW "own file closing an unquoted backtick substitution"
    assert_verdict "echo \"\`cat /tmp/claude-501/STEP-7.d/STEP-7-note\`\"" executor-write "$WAVE_42" DENY "sibling file closing a backtick substitution"
    assert_verdict "rm -rf ${OWN_DIR}/STEP-42-\`echo x\`" executor-write "$WAVE_42" DENY "opening backtick inside the own leaf"
    assert_verdict "echo \"\`cat ${OWN_DIR}/STEP-42-\$(id)\`\"" executor-write "$WAVE_42" DENY "\$( ) in the own leaf before a closing backtick"
    # A sed s### expression gluing the own leaf to a variable.
    assert_verdict "sed -i \"s#${OWN_DIR}/STEP-42-base-hook.sh#\$D/basehooks/x.sh#\" ${OWN_DIR}/f" executor-write "$WAVE_42" ALLOW "own leaf glued to a #\$VAR sed delimiter"
    assert_verdict "sed -i s#${OWN_DIR}/STEP-42-base-hook.sh#\$D/basehooks/x.sh# ${OWN_DIR}/f" executor-write "$WAVE_42" ALLOW "own leaf glued to a #\$VAR sed delimiter, unquoted"
    assert_verdict "sed -i \"s#${OWN_DIR}/STEP-7-base-hook.sh#\$D/basehooks/x.sh#\" ${OWN_DIR}/f" executor-write "$WAVE_42" DENY "foreign leaf id glued to a #\$VAR sed delimiter"
    assert_verdict "D=${OWN_DIR}; sed -i \"s#\$D/STEP-42-base-hook.sh#\$D/basehooks/x.sh#\" \"\$D/f\"" executor-write "$WAVE_42" DENY "own leaf behind \$D, not the own dir, before a #\$VAR delimiter (accepted false deny)"
}

# Prose under an interpreter, and the string forms of CL9.
case_interpreter_strings() {
    assert_verdict "echo \"rm -rf ${SIB_DIR}\" | sh" executor-write "$WAVE_42" DENY "quoted command piped into sh"
    assert_verdict "echo 'rm -rf ${SIB_DIR}' | bash" executor-write "$WAVE_42" DENY "single-quoted command piped into bash"
    assert_verdict "sh <<< \"rm -rf ${SIB_DIR}\"" executor-write "$WAVE_42" DENY "here-string into sh"
    assert_verdict "eval \"\$(printf 'rm -rf ${SIB_DIR}')\"" executor-write "$WAVE_42" DENY "eval of a printf-built string"
    assert_verdict "x='rm -rf ${SIB_DIR}'; eval \"\$x\"" executor-write "$WAVE_42" DENY "eval of a variable set in the same call"
    assert_verdict "eval 'rm -rf ${SIB_DIR}'" executor-write "$WAVE_42" DENY "eval of a quoted string"
    assert_verdict "C='rm -rf ${SIB_DIR}'; bash -c \"\$C\"" executor-write "$WAVE_42" DENY "quoted command string handed to bash -c"
    assert_verdict "echo 'a leftover STEP-7.d was seen' | tee ${OWN_DIR}/note.txt" executor-write "$WAVE_42" ALLOW "prose piped into tee (no interpreter)"
    assert_verdict "python3 -m pytest tests/ -k 'not slow'" executor-write "$WAVE_42" ALLOW "interpreter head with harmless quoted words"
}

# Process operand shapes.
case_process_operands() {
    assert_verdict "kill -9 -1234" executor-write "$WAVE_42" DENY "negative pgid after a signal"
    assert_verdict "kill -TERM -1234" executor-write "$WAVE_42" DENY "negative pgid after a named signal"
    assert_verdict "kill -s TERM -1234" executor-write "$WAVE_42" DENY "negative pgid after -s"
    assert_verdict "kill +1234" executor-write "$WAVE_42" DENY "plus-signed pid"
    assert_verdict "kill \"\$((1233+1))\"" executor-write "$WAVE_42" DENY "arithmetic pid"
    assert_verdict "kill \$((1234))" executor-write "$WAVE_42" DENY "arithmetic pid, bare"
    assert_verdict "kill -9 1\\234" executor-write "$WAVE_42" DENY "backslash inside the pid"
    assert_verdict "kill -9 \$(echo 1234)" executor-write "$WAVE_42" DENY "echoed literal pid"
    assert_verdict "kill \$(ss -lptn 'sport = :8080' | grep -o 'pid=[0-9]*' | cut -d= -f2)" executor-write "$WAVE_42" DENY "kill fed by ss"
    assert_verdict "kill \$(netstat -anv | awk '/8080/{print \$9}')" executor-write "$WAVE_42" DENY "kill fed by netstat"
    assert_verdict "kill -9 -- 1234" executor-write "$WAVE_42" DENY "literal pid after --"
    assert_verdict "kill -TERM \$SERVER_PID" executor-write "$WAVE_42" ALLOW "named variable pid"
    assert_verdict "kill -0 \$pid" executor-write "$WAVE_42" ALLOW "liveness probe on a variable pid"
    assert_verdict "docker kill devserver" executor-write "$WAVE_42" ALLOW "docker kill is docker's verb"
    assert_verdict "tmux kill-session -t build" executor-write "$WAVE_42" ALLOW "tmux kill-session"
    assert_verdict "make kill-server" executor-write "$WAVE_42" ALLOW "make target named kill-server"
    # Residuals, pinned ALLOW.
    assert_verdict "p=1234; kill \$p" executor-write "$WAVE_42" ALLOW "residual: literal pid via a variable"
    assert_verdict "kill \$(cat /repo/.claude/worktrees/wf_x/srv.pid)" executor-write "$WAVE_42" ALLOW "residual: pid file under another checkout"
}

# git spellings beyond the plain verbs.
case_git_spellings() {
    assert_verdict "git -c alias.wt=worktree wt remove /repo/.claude/worktrees/wf_x" executor-write "$WAVE_42" DENY "-c alias before the subcommand"
    assert_verdict "git -c alias.p='worktree prune' p" executor-write "$WAVE_42" DENY "-c alias carrying prune"
    assert_verdict "git -c core.pager=cat log -1" executor-write "$WAVE_42" ALLOW "-c with a non-alias key"
    assert_verdict "git update-ref -d refs/heads/feature/x" executor-write "$WAVE_42" DENY "update-ref -d"
    assert_verdict "git symbolic-ref -d refs/heads/feature/x" executor-write "$WAVE_42" DENY "symbolic-ref -d"
    assert_verdict "git update-ref -d refs/heads/step-42-probe" executor-write "$WAVE_42" ALLOW "update-ref -d on an own-named ref"
    assert_verdict "git update-ref refs/heads/x abc123" executor-write "$WAVE_42" ALLOW "update-ref without -d"
    assert_verdict "git push origin --delete feature/x" executor-write "$WAVE_42" DENY "push --delete after the remote"
    assert_verdict "git push --delete origin feature/x" executor-write "$WAVE_42" DENY "push --delete before the remote"
    assert_verdict "git push -d origin feature/x" executor-write "$WAVE_42" DENY "push -d"
    assert_verdict "git push origin :feature/x" executor-write "$WAVE_42" DENY "push with an empty source refspec"
    assert_verdict "git push origin :refs/heads/feature/x" executor-write "$WAVE_42" DENY "push with an empty source, full ref"
    assert_verdict "git push origin --delete step-42-probe" executor-write "$WAVE_42" ALLOW "push --delete of an own-named branch (push itself is the commit guard's)"
    assert_verdict "git push origin HEAD:feature/x" executor-write "$WAVE_42" ALLOW "push with a source is not a deletion (the commit guard's domain)"
    assert_verdict "git push origin main" executor-write "$WAVE_42" ALLOW "plain push is not a deletion (the commit guard's domain)"
    # Residuals, pinned ALLOW.
    assert_verdict "git wor\"\"ktree prune" executor-write "$WAVE_42" ALLOW "residual: subcommand split by quotes"
    assert_verdict "g=git; \$g worktree prune" executor-write "$WAVE_42" ALLOW "residual: git via a variable"
}

# A sibling's checkout destroyed by path, keyed to the caller's cwd.
case_checkout_paths() {
    local own_wt="/repo/.claude/worktrees/wf_own" sib_wt="/repo/.claude/worktrees/wf_sib"
    with_cwd() { build_input "$1" executor-write "$WAVE_42" | jq -c --arg c "$2" '.cwd = $c'; }
    got=$(verdict_of "$(with_cwd "rm -rf ${sib_wt}" "$own_wt")")
    [ "$got" = "DENY" ] && pass "rm -rf of a sibling's checkout (DENY)" || fail "rm -rf of a sibling's checkout (want DENY, got ${got})"
    got=$(verdict_of "$(with_cwd "rm -rf /repo/.git/worktrees/wf_sib" "$own_wt")")
    [ "$got" = "DENY" ] && pass "rm -rf of a sibling's .git/worktrees entry (DENY)" || fail "rm -rf of a sibling's .git/worktrees entry (want DENY, got ${got})"
    got=$(verdict_of "$(with_cwd "mv ${sib_wt} /tmp/x" "$own_wt")")
    [ "$got" = "DENY" ] && pass "mv of a sibling's checkout (DENY)" || fail "mv of a sibling's checkout (want DENY, got ${got})"
    got=$(verdict_of "$(with_cwd "rm -rf ${own_wt}/target" "$own_wt")")
    [ "$got" = "ALLOW" ] && pass "rm -rf inside own checkout (ALLOW)" || fail "rm -rf inside own checkout (want ALLOW, got ${got})"
    got=$(verdict_of "$(with_cwd "cat ${sib_wt}/src/main.rs" "$own_wt")")
    [ "$got" = "ALLOW" ] && pass "a judge reads a sibling's checkout (ALLOW)" || fail "a judge reads a sibling's checkout (want ALLOW, got ${got})"
    got=$(verdict_of "$(with_cwd "git -C ${sib_wt} diff HEAD~1" "$own_wt")")
    [ "$got" = "ALLOW" ] && pass "git -C into a sibling's checkout for a diff (ALLOW)" || fail "git -C into a sibling's checkout (want ALLOW, got ${got})"
    assert_verdict "rm -rf /repo/.claude/worktrees/wf_x" executor-write "$WAVE_42" DENY "rm -rf of a checkout with no cwd known"
    got=$(verdict_of "$(with_cwd "cat /dev/null > ${sib_wt}/.git" "$own_wt")")
    [ "$got" = "DENY" ] && pass "redirect into a sibling's gitdir pointer (DENY)" || fail "redirect into a sibling's gitdir pointer (want DENY, got ${got})"
    got=$(verdict_of "$(with_cwd "echo x >> ${sib_wt}/src/main.rs" "$own_wt")")
    [ "$got" = "DENY" ] && pass "append into a sibling's source file (DENY)" || fail "append into a sibling's source file (want DENY, got ${got})"
    got=$(verdict_of "$(with_cwd "echo x >${sib_wt}/note" "$own_wt")")
    [ "$got" = "DENY" ] && pass "glued redirect into a sibling's checkout (DENY)" || fail "glued redirect into a sibling's checkout (want DENY, got ${got})"
    got=$(verdict_of "$(with_cwd "cargo build 2>&1 > ${own_wt}/build.log" "$own_wt")")
    [ "$got" = "ALLOW" ] && pass "redirect into own checkout (ALLOW)" || fail "redirect into own checkout (want ALLOW, got ${got})"
    got=$(verdict_of "$(with_cwd "cat ${sib_wt}/.git" "$own_wt")")
    [ "$got" = "ALLOW" ] && pass "reading a sibling's gitdir pointer (ALLOW)" || fail "reading a sibling's gitdir pointer (want ALLOW, got ${got})"
    got=$(verdict_of "$(with_cwd "diff ${own_wt}/a ${sib_wt}/a > ${own_wt}/d.patch" "$own_wt")")
    [ "$got" = "ALLOW" ] && pass "sibling path as a read operand beside an own-dir redirect (ALLOW)" || fail "sibling read operand with own redirect (want ALLOW, got ${got})"
    # `[n]<>` opens its target read-write and creates it, so it writes into
    # a sibling as surely as `>` does; a plain `<` only reads.
    local rw
    for rw in "1<> " "3<> " "<> " "1<>"; do
        assert_verdict "cat x ${rw}/repo/.claude/worktrees/wf_x/.git" executor-write "$WAVE_42" DENY "read-write redirect '${rw}' onto a sibling's gitdir pointer"
        assert_deny_reason "cat x ${rw}/repo/.claude/worktrees/wf_x/.git" executor-write "$WAVE_42" "write into" "read-write redirect '${rw}' deny is the write-into rule"
    done
    assert_verdict "cat < /repo/.claude/worktrees/wf_x/srv.pid" executor-write "$WAVE_42" ALLOW "input redirect from a sibling's checkout"
}

# Two claims in one opening: the marker must name the same step twice.
case_marker_shape() {
    local two="${WORK}/two-claims.jsonl"
    printf '%s\n' '{"type":"user","message":{"role":"user","content":"docket step claim STEP-41 --owner wave:STEP-42:1 ... docket step claim STEP-42 --owner wave:STEP-42:1"}}' >"$two"
    assert_verdict "rm -rf ${OWN_DIR}" executor-write "$two" ALLOW "a mismatched claim is skipped; the matching one names the step"
    assert_verdict "rm -rf /tmp/claude-501/STEP-41.d" executor-write "$two" DENY "the mismatched id is not the own step"
}

# --- Deny reasons. -----------------------------------------------------------
case_deny_reasons() {
    assert_deny_reason "rm -rf ${SIB_DIR}" executor-write "$WAVE_42" "your own scratch dir is <TMP>/STEP-42.d" "scratch deny names the caller's own dir"
    assert_deny_reason "rm -rf ${SIB_DIR}" executor-write "$WAVE_42" "STEP-7.d" "scratch deny names the offending dir"
    assert_deny_reason "rm -rf ${SIB_DIR}" executor-write "$WAVE_42" "Write tool" "scratch deny names the prose path"
    assert_deny_reason "rm -rf ${SIB_DIR}" executor-write "$WAVE_42" "body holds no quote, backtick, backslash, # or \$" "scratch deny qualifies the heredoc path inside a substitution"
    assert_deny_reason "grep -rn 'STEP-[0-9]*' ${OWN_DIR}" executor-read "$WAVE_42" "STEP.[0-9]+" "scratch deny names the search-pattern spelling"
    assert_deny_reason "grep -rn 'STEP-[0-9]*' ${OWN_DIR}" executor-read "$WAVE_42" "rewording a command that operates on another step's directory is not authorized" "scratch deny forbids rewording a sibling operation"
    assert_deny_reason "for s in 7 8; do rm -rf /tmp/claude-501/STEP-\$s.d; done" executor-write "$WAVE_42" "docket step artifacts STEP-7; docket step artifacts STEP-8" "scratch deny names the literal-id recovery"
    assert_deny_reason "rm -rf ${SIB_DIR}" executor-read "$SEAT" "holds no step claim" "scratch deny with no own step says so"
    assert_deny_reason "git worktree prune" executor-write "$WAVE_42" "git worktree prune" "prune deny names the verb"
    assert_deny_reason "git worktree remove /repo/.claude/worktrees/wf_x" executor-write "$WAVE_42" "did not create" "worktree deny explains ownership"
    assert_deny_reason "git branch -D feature/x" executor-write "$WAVE_42" "feature/x" "branch deny names the branch"
    assert_deny_reason "pkill -f vorpal" executor-write "$WAVE_42" "kill %1" "pkill deny names the sanctioned jobspec form"
    assert_deny_reason "kill 1234" executor-write "$WAVE_42" "kill 1234" "kill deny echoes the literal pid"
    assert_deny_reason "kill \$(pgrep -f srv)" executor-write "$WAVE_42" "process lookup" "kill deny names the lookup"
    assert_deny_reason "docket step reap STEP-7 --reason x" executor-write "$WAVE_42" "leave the reap to the conductor" "reap deny names the conductor"
    assert_deny_reason "docket run conduct RUN-5" executor-write "$WAVE_42" "The seat is the conductor's" "conduct deny names the conductor's seat"
    assert_deny_reason "docket run conduct RUN-5" executor-write "$WAVE_42" "main conversation" "conduct deny names the main conversation's path"
    assert_deny_reason "docket run conduct RUN-5" executor-write "$WAVE_42" "finding in your step report" "conduct deny names the executor's own path"
    assert_deny_reason ": > ${SIB_DIR}/x" executor-write "$WAVE_42" "cat /dev/null" "structural-redirect deny names the plain spelling"
    assert_deny_reason "{ :; } > ${SIB_DIR}/x" executor-write "$WAVE_42" "compound command" "compound-redirect deny explains the shape"
    # A cap or structural-redirect refusal inside a pipeline stage ends only
    # that stage, so a trailing command must not turn it into an allow; one
    # made where the command closed stderr must not either.
    assert_deny_reason "ls | { while true; do :; done; rm -rf ${SIB_DIR}/x; }; echo done" executor-write "$WAVE_42" "too many parts (over 2000)" "cap in a pipeline stage before a trailing command"
    assert_deny_reason "ls | { : > ${SIB_DIR}/f; }; echo done" executor-write "$WAVE_42" "cat /dev/null" "structural redirect in a pipeline stage before a trailing command"
    assert_verdict "ls | { : > /tmp/zz; rm -rf ${SIB_DIR}/x; }; echo done" executor-write "$WAVE_42" DENY "structural redirect then a sibling rm in a pipeline stage before a trailing command"
    assert_deny_reason "while true; do :; done 2>&-" executor-write "$WAVE_42" "too many parts (over 2000)" "cap with stderr closed"
    assert_deny_reason ": > ${SIB_DIR}/x 2>&-" executor-write "$WAVE_42" "cat /dev/null" "structural redirect with stderr closed"
    assert_deny_reason "{ : > ${SIB_DIR}/x; } 2>&-" executor-write "$WAVE_42" "cat /dev/null" "structural redirect inside a group with stderr closed"
    # The probe's own fds: closing the marker fd (7) or the leaf-frame fd (8)
    # would silence the refusal or hide the leaves, so any redirect of 7-9
    # is refused before the walk.
    assert_deny_reason "ls | while read d; do [ -n \"\$d\" ] || continue; rm -rf ${SIB_DIR}/\$d; done 7>&- 2>&-" executor-write "$WAVE_42" "file descriptor 7, 8 or 9" "guarded read loop closing the marker fd"
    assert_deny_reason "ls | { rm -rf ${SIB_DIR}; } 8>&- 2>&-; echo done" executor-write "$WAVE_42" "file descriptor 7, 8 or 9" "pipeline stage closing the leaf-frame fd"
    assert_deny_reason "exec 9>&-; ls" executor-write "$WAVE_42" "file descriptor 7, 8 or 9" "exec closing fd 9"
    assert_verdict "ls 2>&1 | head -n 8 >/dev/null" executor-write "$WAVE_42" ALLOW "fds 1 and 2 and a numeric operand are not probe fds"
    assert_verdict "echo \$7>/dev/null" executor-write "$WAVE_42" ALLOW "a positional parameter before a redirect is not a probe fd"
    assert_deny_reason "_guard_probe() { :; }; ls" executor-write "$WAVE_42" "_guard_probe" "probe-tamper deny names the handler"
    assert_deny_reason "git -c alias.x=worktree x prune" executor-write "$WAVE_42" "alias" "alias deny names the alias"
}

# --- Input edges and installation. ------------------------------------------
case_input_edges() {
    assert_verdict_raw '' ALLOW "empty stdin"
    assert_verdict_raw 'not json' ALLOW "non-JSON stdin"
    assert_verdict_raw "$(jq -nc --arg t "$WAVE_42" '{tool_name:"Read", tool_input:{file_path:"/tmp/claude-501/STEP-7.d/x"}, agent_type:"executor-write", transcript_path:$t}')" ALLOW "non-Bash tool"
    assert_verdict_raw "$(jq -nc --arg t "$WAVE_42" '{tool_name:"Bash", tool_input:{}, agent_type:"executor-write", transcript_path:$t}')" ALLOW "Bash with no command"
    assert_verdict "rm -rf (" executor-write "$WAVE_42" DENY "unparseable command refused rather than guessed"
    assert_verdict "rm -rf (" "" "$OPERATOR" ALLOW "unparseable command from the main conversation stays with the harness"
    assert_verdict "   " executor-write "$WAVE_42" ALLOW "whitespace-only command dispatches nothing"
}

# The pre-pass file must sit beside the hook; a copy of the hook alone must
# fail CLOSED, as the sibling guards do, and a copy with the pre-pass beside
# it must decide exactly as the checkout's copy.
case_prepass_installation() {
    local alone="${WORK}/alone" beside="${WORK}/beside" got
    mkdir -p "$alone" "$beside"
    cp "$HOOK" "${alone}/hook.sh"
    got=$(PATH="$TOOLS_DIR" HOME="${WORK}/home" "$BASH_BIN" "${alone}/hook.sh" >/dev/null 2>&1 <<<"$(build_input "ls" executor-write "$WAVE_42")"; [ $? -eq 2 ] && printf DENY || printf ALLOW)
    [ "$got" = "DENY" ] && pass "missing pre-pass file fails closed (DENY)" || fail "missing pre-pass file (want DENY, got ${got})"
    cp "$HOOK" "${beside}/hook.sh"
    cp "$(dirname "$HOOK")/docket-guard-prepass.awk" "${beside}/"
    got=$(PATH="$TOOLS_DIR" HOME="${WORK}/home" "$BASH_BIN" "${beside}/hook.sh" >/dev/null 2>&1 <<<"$(build_input "rm -rf ${SIB_DIR}" executor-write "$WAVE_42")"; [ $? -eq 2 ] && printf DENY || printf ALLOW)
    [ "$got" = "DENY" ] && pass "installed copy with pre-pass beside it denies a foreign dir (DENY)" || fail "installed copy with pre-pass (want DENY, got ${got})"
    got=$(PATH="$TOOLS_DIR" HOME="${WORK}/home" "$BASH_BIN" "${beside}/hook.sh" >/dev/null 2>&1 <<<"$(build_input "rm -rf ${OWN_DIR}" executor-write "$WAVE_42")"; [ $? -eq 2 ] && printf DENY || printf ALLOW)
    [ "$got" = "ALLOW" ] && pass "installed copy with pre-pass beside it allows the own sweep (ALLOW)" || fail "installed copy own sweep (want ALLOW, got ${got})"
}

# The transcript read is bounded: a brief buried past 64 KiB is not found
# (own step reads NONE), one within the bound on a later line is.
case_transcript_bound() {
    local late="${WORK}/late.jsonl" second="${WORK}/second-line.jsonl" filler
    filler=$(printf 'x%.0s' $(seq 1 70000))
    printf '{"type":"user","message":{"role":"user","content":"%s"}}\n' "$filler" >"$late"
    printf '%s\n' '{"type":"user","message":{"role":"user","content":"docket step claim STEP-42 --owner wave:STEP-42:1"}}' >>"$late"
    assert_verdict "rm -rf ${OWN_DIR}" executor-write "$late" DENY "claim past the 64 KiB bound is not read (own step NONE, own dir denied)"
    printf '%s\n' '{"type":"summary","summary":"context"}' >"$second"
    printf '%s\n' '{"type":"user","message":{"role":"user","content":"docket step claim STEP-42 --owner wave:STEP-42:1"}}' >>"$second"
    assert_verdict "rm -rf ${OWN_DIR}" executor-write "$second" ALLOW "claim on the second line within the bound is read"
    assert_verdict "rm -rf ${SIB_DIR}" executor-write "$second" DENY "and a foreign dir is still denied against it"
    # A conductor-recovery claim is not the wave marker.
    local recovery="${WORK}/recovery.jsonl"
    printf '%s\n' '{"type":"user","message":{"role":"user","content":"docket step claim STEP-42 --owner conduct:recovery"}}' >"$recovery"
    assert_verdict "rm -rf ${SIB_DIR}" "" "$recovery" ALLOW "conduct:recovery claim spelling is not the wave marker (out of scope)"
}

# A command the probe cannot finish walking (over 2000 simple commands) is
# refused as oversized, and the walk must END there with nothing executed:
# the marker a spinning loop keeps trying to create must not exist afterward.
case_leaf_cap_stops_the_walk() {
    local marker="${WORK}/cap-marker" err
    err=$(deny_reason_of "while true; do touch ${marker}; done" executor-write "$WAVE_42")
    case "$err" in
        "${DENY_PREFIX}"*"too many parts"*) pass "unbounded loop is refused as oversized" ;;
        *) fail "unbounded loop not refused as oversized: ${err}" ;;
    esac
    if [ -e "$marker" ]; then
        fail "the probe ran the loop body for real after the cap (marker exists)"
    else
        pass "the probe ran nothing for real after the cap"
    fi
    err=$(deny_reason_of "while true; do touch ${marker}; rm -rf ${SIB_DIR}; done" executor-write "$WAVE_42")
    case "$err" in
        "${DENY_PREFIX}"*) pass "unbounded loop over a sibling's dir is refused" ;;
        *) fail "unbounded loop over a sibling's dir allowed: ${err}" ;;
    esac
    [ -e "$marker" ] && fail "the probe ran the sibling-dir loop body for real (marker exists)" || pass "the sibling-dir loop body never ran"
}

# Denies and own-unknown allows land in the friction ledger; routine allows do
# not (an executor makes hundreds of Bash calls).
case_friction_log_records_decisions() {
    local home_dir log_file
    home_dir=$(mktemp -d "${TMPDIR:-/tmp}/docket-sibling-guard-home.XXXXXX")
    log_file="${home_dir}/.claude/friction/docket-sibling-guard.jsonl"

    HOME="$home_dir" "$BASH_BIN" "$HOOK" >/dev/null 2>&1 <<<"$(build_input "rm -rf ${SIB_DIR}" executor-write "$WAVE_42")"
    if [ -s "$log_file" ] && jq -e '.decision == "deny" and .clause == "SCRATCH" and .detected_via == "agent_type" and .own_mode == "known" and .own_step == "42"' "$log_file" >/dev/null 2>&1; then
        pass "friction log records a scratch deny with the own step"
    else
        fail "friction log missing or wrong shape after a scratch deny"
    fi

    : >"$log_file"
    HOME="$home_dir" "$BASH_BIN" "$HOOK" >/dev/null 2>&1 <<<"$(build_sub_input "rm -rf ${SIB_DIR}" executor-read a1 sess-1 "$PARENT")"
    if [ -s "$log_file" ] && jq -e --arg own "${SESS_DIR}/subagents/workflows/wf_a/agent-a1.jsonl" '.agent_id == "a1" and .own_transcript == $own and .own_mode == "known" and .own_step == "42"' "$log_file" >/dev/null 2>&1; then
        pass "friction log names the agent_id and the own transcript it read"
    else
        fail "friction log missing agent_id/own_transcript after an agent_id deny"
    fi

    : >"$log_file"
    HOME="$home_dir" "$BASH_BIN" "$HOOK" >/dev/null 2>&1 <<<"$(build_input "rm -rf ${SIB_DIR}" executor-write "$MISSING")"
    if [ -s "$log_file" ] && jq -e '.decision == "allow" and .clause == "own-unknown" and .own_mode == "unknown"' "$log_file" >/dev/null 2>&1; then
        pass "friction log records an own-unknown allow"
    else
        fail "friction log missing or wrong shape after an own-unknown allow"
    fi

    : >"$log_file"
    HOME="$home_dir" "$BASH_BIN" "$HOOK" >/dev/null 2>&1 <<<"$(build_input "rm -rf ${OWN_DIR}" executor-write "$WAVE_42")"
    if [ ! -s "$log_file" ]; then
        pass "friction log stays silent on a routine own-dir allow"
    else
        fail "friction log recorded a routine allow"
    fi

    rm -rf "$home_dir"
}

case_acceptance
case_own_bootstrap_allows
case_scope
case_own_step_states
case_own_transcript_from_agent_id
case_scratch_shapes
case_command_shapes
case_prose
case_worktree_and_branch
case_processes
case_engine_verbs
case_probe_never_acts
case_read_loops
case_size_and_bytes
case_artifact_heredoc_bodies
case_multiline_substitutions
case_verb_spellings
case_scratch_spellings
case_own_leaf_expansions
case_interpreter_strings
case_process_operands
case_git_spellings
case_checkout_paths
case_marker_shape
case_deny_reasons
case_input_edges
case_prepass_installation
case_transcript_bound
case_leaf_cap_stops_the_walk
case_friction_log_records_decisions

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
