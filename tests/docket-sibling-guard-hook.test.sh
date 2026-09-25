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

WORK=$(mktemp -d "${TMPDIR:-/tmp}/docket-sibling-guard-test.XXXXXX") || fatal "mktemp failed"
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

# Classifies one hook run as DENY (exit 2) or ALLOW (exit 0). No
# permissionDecision envelope is emitted -- exit 2 is a pre-permission hard
# stop and exit 0 is silence -- so the exit code is the entire verdict.
verdict_of() {
    local input="$1" rc
    PATH="$TOOLS_DIR" HOME="${WORK}/home" "$BASH_BIN" "$HOOK" >/dev/null 2>&1 <<<"$input"
    rc=$?
    if [ "$rc" -eq 2 ]; then
        printf 'DENY'
    else
        printf 'ALLOW'
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
    local cmd="$1" agent="$2" transcript="$3" phrase="$4" label="$5" err
    err=$(PATH="$TOOLS_DIR" HOME="${WORK}/home" "$BASH_BIN" "$HOOK" 2>&1 >/dev/null <<<"$(build_input "$cmd" "$agent" "$transcript")")
    case "$err" in
        "${DENY_PREFIX}"*) pass "${label} (reason prefix unchanged)" ;;
        *) fail "${label} (reason prefix changed or missing: ${err})" ;;
    esac
    case "$err" in
        *"${phrase}"*) pass "${label} (reason names: ${phrase})" ;;
        *) fail "${label} (reason no longer says '${phrase}': ${err})" ;;
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
    assert_verdict $'cat > '"${OWN_DIR}"$'/STEP-42-findings.md <<\'EOF\'\nFound a leftover STEP-7.d beside my own dir.\nEOF' executor-write "$WAVE_42" ALLOW "quoted-delimiter heredoc body is inert"
    assert_verdict $'cat > '"${OWN_DIR}"$'/STEP-42-findings.md <<EOF\nFound a leftover STEP-7.d beside my own dir.\nEOF' executor-write "$WAVE_42" DENY "unquoted-delimiter heredoc body is scanned (accepted false deny)"
    assert_verdict $'cat <<\'EOF\' | sh\nrm -rf '"${SIB_DIR}"$'\nEOF' executor-write "$WAVE_42" DENY "quoted heredoc piped into an interpreter is code"
    assert_verdict "echo STEP-7.d" executor-write "$WAVE_42" DENY "a lone unquoted token is not prose (accepted false deny)"
    assert_verdict "grep -rn 'STEP-[0-9]*' ${OWN_DIR}" executor-read "$WAVE_42" DENY "glob-form token as a search pattern (accepted false deny)"
    assert_verdict "grep -rnE 'STEP.[0-9]+' ${OWN_DIR}" executor-read "$WAVE_42" ALLOW "the deny reason's search spelling is not a scratch token"
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
    check "vetoed leaf redirect onto own dir" ALLOW "echo x > ${OWN_DIR}/note.txt"
    check "handler redefinition" DENY "_guard_probe() { return 0; }; rm -rf ${OWN_DIR}/x; cat /dev/null > ${marker}"
    check "handler redefinition, function keyword" DENY "function _guard_probe { :; }; cat /dev/null > ${marker}"
    check "handler redefinition then a sibling rm" DENY "_guard_probe() { return 0; }; rm -rf ${SIB_DIR}"
    check "cap in a structural loop before the verb" DENY 'while [[ $((++i)) -lt 2100 ]]; do :; done; rm -rf '"${SIB_DIR}"
    check "cap in a structural loop before pkill" DENY 'while [[ $((++i)) -lt 2100 ]]; do :; done; pkill node'
    check "cap in a structural loop before reap" DENY 'while [[ $((++i)) -lt 2100 ]]; do :; done; docket step reap STEP-7 --reason x'
    check "unbounded loop touching the marker" DENY "while true; do cat /dev/null > ${marker}; done"
    rm -f "$marker"
    # No temp file: the scratch root holds nothing of this hook's afterward.
    local before after
    before=$(ls "${TMPDIR:-/tmp}" 2>/dev/null | grep -c 'docket-sibling-guard' || true)
    verdict_of "$(build_input "rm -rf ${SIB_DIR}" executor-write "$WAVE_42")" >/dev/null
    verdict_of "$(build_input "ls" executor-write "$WAVE_42")" >/dev/null
    after=$(ls "${TMPDIR:-/tmp}" 2>/dev/null | grep -c 'docket-sibling-guard' || true)
    [ "$after" -le "$before" ] && pass "no probe file left in TMPDIR" || fail "probe files left in TMPDIR (${before} -> ${after})"
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
    # The same bodies consumed by an interpreter are code.
    assert_verdict $'sh <<\'EOF\'\nrm -rf '"${SIB_DIR}"$'\nEOF' executor-write "$WAVE_42" DENY "heredoc fed to sh is code"
    assert_verdict $'python3 - <<\'EOF\'\nimport shutil; shutil.rmtree("'"${SIB_DIR}"$'")\nEOF' executor-write "$WAVE_42" DENY "heredoc fed to python is code"
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
    assert_verdict "rm() { command rm \"\$@\"; }; rm -rf ${SIB_DIR}" executor-write "$WAVE_42" DENY "function wrapper around rm"
    assert_verdict "git() { command git \"\$@\"; }; git worktree prune" executor-write "$WAVE_42" DENY "function wrapper around git"
    assert_verdict "kill() { command kill \"\$@\"; }; kill 1234" executor-write "$WAVE_42" DENY "function wrapper around kill"
    assert_verdict "docket() { command docket \"\$@\"; }; docket step reap STEP-7 --reason x" executor-write "$WAVE_42" DENY "function wrapper around docket"
    assert_verdict "DOCKET run conduct RUN-5" executor-write "$WAVE_42" DENY "uppercase DOCKET run conduct"
    assert_verdict "docket --json=v2 run conduct RUN-5" executor-write "$WAVE_42" DENY "docket --json=v2 before run conduct"
    assert_verdict "docket --format json run conduct RUN-5" executor-write "$WAVE_42" DENY "docket --format json before run conduct"
    assert_verdict "docket() { command docket \"\$@\"; }; docket run conduct RUN-5" executor-write "$WAVE_42" DENY "function wrapper around docket run conduct"
    assert_verdict "sudo pkill node" executor-write "$WAVE_42" DENY "sudo prefix"
    assert_verdict "xargs pkill < list" executor-write "$WAVE_42" DENY "xargs prefix"
    assert_verdict "timeout 5 pkill node" executor-write "$WAVE_42" DENY "timeout prefix with a duration"
    assert_verdict "env FOO=1 pkill node" executor-write "$WAVE_42" DENY "env prefix with an assignment"
    assert_verdict "nice -n 5 killall node" executor-write "$WAVE_42" DENY "nice prefix with an option value"
    assert_verdict "command kill 1234" executor-write "$WAVE_42" DENY "command prefix"
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
    # Residuals, pinned ALLOW.
    assert_verdict "rm -rf /tmp/claude-501/STEP-\"7\".d" executor-write "$WAVE_42" ALLOW "residual: id split by quotes"
    assert_verdict "rm -rf /tmp/claude-501/S*-7.d" executor-write "$WAVE_42" ALLOW "residual: glob outside the id"
    assert_verdict "cd /tmp/claude-501 && rm -rf [S]TEP-7.d" executor-write "$WAVE_42" ALLOW "residual: glob on the first letter"
    assert_verdict "rm -rf ${OWN_DIR}/.\".\"/" executor-write "$WAVE_42" ALLOW "residual: .. split by quotes"
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
    assert_deny_reason "grep -rn 'STEP-[0-9]*' ${OWN_DIR}" executor-read "$WAVE_42" "STEP.[0-9]+" "scratch deny names the search-pattern spelling"
    assert_deny_reason "grep -rn 'STEP-[0-9]*' ${OWN_DIR}" executor-read "$WAVE_42" "rewording a command that operates on another step's directory is not authorized" "scratch deny forbids rewording a sibling operation"
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
    err=$(PATH="$TOOLS_DIR" HOME="${WORK}/home" "$BASH_BIN" "$HOOK" 2>&1 >/dev/null <<<"$(build_input "while true; do touch ${marker}; done" executor-write "$WAVE_42")")
    case "$err" in
        "${DENY_PREFIX}"*"too many parts"*) pass "unbounded loop is refused as oversized" ;;
        *) fail "unbounded loop not refused as oversized: ${err}" ;;
    esac
    if [ -e "$marker" ]; then
        fail "the probe ran the loop body for real after the cap (marker exists)"
    else
        pass "the probe ran nothing for real after the cap"
    fi
    err=$(PATH="$TOOLS_DIR" HOME="${WORK}/home" "$BASH_BIN" "$HOOK" 2>&1 >/dev/null <<<"$(build_input "while true; do touch ${marker}; rm -rf ${SIB_DIR}; done" executor-write "$WAVE_42")")
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
case_size_and_bytes
case_artifact_heredoc_bodies
case_verb_spellings
case_scratch_spellings
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
