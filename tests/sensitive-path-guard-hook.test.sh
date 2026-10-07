#!/bin/bash

# Behavior suite for src/user/claude_code/hooks/sensitive-path-guard-hook.sh.
#
# Wired into CI: `.github/workflows/vorpal.yaml` enumerates test files by name.
#
# THE PROPERTY UNDER TEST: the hook denies a Read/Grep/Glob whose target
# resolves to a sensitive root or beneath it, and is silent for everything
# else. It stands in for the `Read(<path>)` permission deny rules it replaced,
# so the deny set must be at least what those rules covered, including the
# spellings a rule matched by prefix: `~`, `$HOME`-absolute, relative-to-cwd,
# and `..` walks that land inside a root.
#
# DEFECT CLASS. Two failure directions, both silent in production:
#   FALSE ALLOW - a credential store read through a spelling the normalizer
#     does not fold (a `..` walk, a trailing glob, a cwd already inside the
#     root), so the protection the deny rules gave is quietly gone.
#   FALSE DENY  - an ordinary read refused because a root matched as a string
#     prefix (`~/.sshd`, `~/.awsome`), or a tool the hook is not for got a
#     verdict at all.
#
# SEAM. No filesystem, no harness: the hook makes one decision from stdin JSON
# and the process environment (HOME), and its stdout is the entire verdict.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
HOOK="${GUARD_HOOK:-${REPO_ROOT}/src/user/claude_code/hooks/sensitive-path-guard-hook.sh}"

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

# A fixed HOME so the expected absolute paths are deterministic and the suite
# never touches the runner's real credential directories.
FAKE_HOME=/Users/tester
REPO=/Users/tester/Development/repo

# DENY when the hook emits a permissionDecision of deny; ALLOW on silence.
verdict_of() {
    local input="$1" out
    out=$(HOME="$FAKE_HOME" "$BASH_BIN" "$HOOK" 2>/dev/null <<<"$input")
    if printf '%s' "$out" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null 2>&1; then
        printf 'DENY'
    else
        printf 'ALLOW'
    fi
}

build_input() {
    local tool="$1" key="$2" value="$3" cwd="${4:-$REPO}"
    if [ -n "$key" ]; then
        jq -nc --arg t "$tool" --arg k "$key" --arg v "$value" --arg c "$cwd" \
            '{hook_event_name:"PreToolUse",tool_name:$t,tool_input:{($k):$v},cwd:$c}'
    else
        jq -nc --arg t "$tool" --arg c "$cwd" \
            '{hook_event_name:"PreToolUse",tool_name:$t,tool_input:{},cwd:$c}'
    fi
}

assert_verdict() {
    local tool="$1" key="$2" value="$3" cwd="$4" want="$5" label="$6" got
    got=$(verdict_of "$(build_input "$tool" "$key" "$value" "$cwd")")
    if [ "$got" = "$want" ]; then
        pass "${label} (${want})"
    else
        fail "${label} (want ${want}, got ${got})"
    fi
}

read_deny() { assert_verdict Read file_path "$1" "${2:-$REPO}" DENY "Read $1"; }
read_allow() { assert_verdict Read file_path "$1" "${2:-$REPO}" ALLOW "Read $1"; }

# ---- every root the Read() rules named, in the ~ spelling the rules used ---

case_every_root_denies() {
    read_deny '~/.aws/credentials'
    read_deny '~/.claude.json'
    read_deny '~/.doppler/.doppler.yaml'
    read_deny '~/.gemini/settings.json'
    read_deny '~/.gnupg/private-keys-v1.d/x.key'
    read_deny '~/.kube/config'
    read_deny '~/.netrc'
    read_deny '~/.ssh/id_ed25519'
    read_deny '~/.talos/config'
    read_deny '~/Desktop/notes.txt'
    read_deny '~/Downloads/statement.pdf'
}

# ---- spellings a prefix rule caught that a naive string match would miss ---

case_alternate_spellings_deny() {
    read_deny "${FAKE_HOME}/.ssh/id_ed25519"
    read_deny '~/.ssh'
    read_deny "${FAKE_HOME}/.ssh/"
    read_deny 'id_ed25519' "${FAKE_HOME}/.ssh"
    read_deny '../.ssh/config' "${FAKE_HOME}/Development"
    read_deny "${REPO}/../../.aws/credentials"
    read_deny "${FAKE_HOME}/./.kube/../.kube/config"
    read_deny '~/Downloads/../.ssh/known_hosts'
}

case_grep_and_glob_deny() {
    assert_verdict Grep path '~/.ssh' "$REPO" DENY "Grep path ~/.ssh"
    assert_verdict Glob path "${FAKE_HOME}/.gnupg" "$REPO" DENY "Glob path ~/.gnupg"
    assert_verdict Glob path '~/.ssh/**/*.pub' "$REPO" DENY "Glob path with trailing glob"
    assert_verdict Grep path '~/.aws/*' "$REPO" DENY "Grep path with trailing star"
    assert_verdict Grep "" "" "${FAKE_HOME}/.aws" DENY "Grep without path, cwd inside ~/.aws"
    assert_verdict Glob "" "" "${FAKE_HOME}/.kube" DENY "Glob without path, cwd inside ~/.kube"
}

# ---- ordinary reads stay silent ------------------------------------------

case_ordinary_reads_allow() {
    read_allow "${REPO}/src/main.rs"
    read_allow 'src/main.rs'
    read_allow '~/.sshd_config'
    read_allow '~/.awsome/notes'
    read_allow '~/.config/gh/hosts.yml'
    read_allow '~/.config/ghostty/config'
    read_allow '~/.claude.json.bak'
    read_allow '~/.claude/settings.json'
    read_allow '/tmp/claude-501/STEP-1.d/target/go.mod'
    read_allow "${REPO}/.ssh/README"
    read_allow '~/Development/Downloads/x'
    assert_verdict Grep path "$REPO" "$REPO" ALLOW "Grep path repo"
    assert_verdict Glob "" "" "$REPO" ALLOW "Glob without path, cwd repo"
    assert_verdict Read "" "" "$REPO" ALLOW "Read without file_path"
}

# ---- tools the hook is not for get no verdict -----------------------------

case_other_tools_allow() {
    assert_verdict Bash command 'cat ~/.ssh/id_ed25519' "$REPO" ALLOW "Bash is the sandbox's job"
    assert_verdict Edit file_path '~/.ssh/config' "$REPO" ALLOW "Edit is covered by Edit() rules"
}

# ---- Write: sensitive roots for every caller, own STEP-N.d for executor-read

# A scratch root reached through a symlink, so the TMPDIR spelling and its
# physical path differ on every platform, and transcripts whose opening is a
# wave brief claiming STEP-7, an operator message, or nothing.
WORK=$(mktemp -d "${TMPDIR:-/tmp}/sensitive-path-guard-test.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT
SCRATCH_PHYS=$(cd -P "$WORK" && pwd -P)/scratch
mkdir -p "${SCRATCH_PHYS}/STEP-7.d" "${SCRATCH_PHYS}/STEP-8.d"
SCRATCH_LINK="${WORK}/scratch-link"
ln -s "$SCRATCH_PHYS" "$SCRATCH_LINK"
WAVE_7="${WORK}/wave-7.jsonl"
printf '%s\n' '{"type":"user","message":{"role":"user","content":"docket step claim STEP-7 --owner wave:STEP-7:1 --render --json > <TMP>/STEP-7.d/STEP-7.claim.json"}}' >"$WAVE_7"
OPERATOR="${WORK}/operator.jsonl"
printf '%s\n' '{"type":"user","message":{"role":"user","content":"tidy /tmp/claude-501/STEP-7.d"}}' >"$OPERATOR"
SESS_DIR="${WORK}/projects/proj/sess-1"
mkdir -p "${SESS_DIR}/subagents"
cp "$OPERATOR" "${WORK}/projects/proj/sess-1.jsonl"
cp "$WAVE_7" "${SESS_DIR}/subagents/agent-a7.jsonl"

# write_verdict <file_path> <agent_type or ""> <transcript or ""> <ALLOW|DENY> <label> [agent_id session_id]
write_verdict() {
    local path="$1" agent="$2" transcript="$3" want="$4" label="$5" id="${6:-}" session="${7:-}" input out got
    input=$(jq -nc --arg p "$path" --arg a "$agent" --arg t "$transcript" --arg c "$REPO" --arg id "$id" --arg s "$session" '
        {hook_event_name:"PreToolUse",tool_name:"Write",tool_input:{file_path:$p,content:"x"},cwd:$c}
        | if $a != "" then .agent_type = $a else . end
        | if $t != "" then .transcript_path = $t else . end
        | if $id != "" then .agent_id = $id | .session_id = $s else . end')
    out=$(HOME="$FAKE_HOME" TMPDIR="$SCRATCH_LINK" "$BASH_BIN" "$HOOK" 2>/dev/null <<<"$input")
    if printf '%s' "$out" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null 2>&1; then
        got=DENY
    else
        got=ALLOW
    fi
    if [ "$got" = "$want" ]; then
        pass "${label} (${want})"
    else
        fail "${label} (want ${want}, got ${got})"
    fi
}

case_executor_read_write_confined() {
    write_verdict "${SCRATCH_LINK}/STEP-7.d/STEP-7-payload.json" executor-read "$WAVE_7" ALLOW \
        "executor-read Write in its own STEP-N.d, TMPDIR spelling"
    write_verdict "${SCRATCH_PHYS}/STEP-7.d/out/STEP-7-findings.md" executor-read "$WAVE_7" ALLOW \
        "executor-read Write in its own STEP-N.d, physical path"
    write_verdict "${SCRATCH_LINK}/STEP-7.d/STEP-7-payload.json" executor-read "${WORK}/projects/proj/sess-1.jsonl" ALLOW \
        "executor-read Write, own transcript found by agent_id" a7 sess-1
    write_verdict "${REPO}/src/main.rs" executor-read "$WAVE_7" DENY \
        "executor-read Write in the checkout"
    write_verdict "${SCRATCH_LINK}/STEP-8.d/STEP-8-payload.json" executor-read "$WAVE_7" DENY \
        "executor-read Write in a sibling STEP-M.d"
    write_verdict "${SCRATCH_LINK}/STEP-7.d/../STEP-8.d/x.json" executor-read "$WAVE_7" DENY \
        "executor-read Write walking out of its own dir with .."
    write_verdict "${SCRATCH_LINK}/STEP-7.d" executor-read "$WAVE_7" DENY \
        "executor-read Write onto its own dir path itself"
    write_verdict '~/.ssh/authorized_keys' executor-read "$WAVE_7" DENY \
        "executor-read Write under a sensitive home path"
    write_verdict "${SCRATCH_LINK}/STEP-7.d/STEP-7-payload.json" executor-read "" DENY \
        "executor-read Write with no transcript: own dir undetermined"
    write_verdict "${SCRATCH_LINK}/STEP-7.d/STEP-7-payload.json" executor-read "$OPERATOR" DENY \
        "executor-read Write whose transcript carries no claim"
}

case_other_callers_write_unconfined() {
    write_verdict "${REPO}/src/main.rs" "" "" ALLOW \
        "main session Write in the checkout"
    write_verdict '~/.aws/credentials' "" "" DENY \
        "main session Write under a sensitive home path"
    write_verdict "${REPO}/src/main.rs" executor-write "$WAVE_7" ALLOW \
        "executor-write Write in the checkout"
    write_verdict "${REPO}/src/main.rs" executor-write "" ALLOW \
        "executor-write Write in the checkout with no transcript"
    write_verdict '~/.ssh/config' executor-write "$WAVE_7" DENY \
        "executor-write Write under a sensitive home path"
}

# The confinement is for Write alone: an executor-read seat reads the checkout.
case_executor_read_reads_unconfined() {
    local input got
    input=$(jq -nc --arg p "${REPO}/src/main.rs" --arg t "$WAVE_7" --arg c "$REPO" \
        '{hook_event_name:"PreToolUse",tool_name:"Read",tool_input:{file_path:$p},agent_type:"executor-read",transcript_path:$t,cwd:$c}')
    got=$(verdict_of "$input")
    if [ "$got" = "ALLOW" ]; then
        pass "executor-read Read in the checkout (ALLOW)"
    else
        fail "executor-read Read in the checkout (want ALLOW, got ${got})"
    fi
}

case_malformed_input_is_silent() {
    local got
    got=$(verdict_of '')
    [ "$got" = "ALLOW" ] && pass "empty stdin (ALLOW)" || fail "empty stdin (want ALLOW, got ${got})"
    got=$(verdict_of 'not json')
    [ "$got" = "ALLOW" ] && pass "non-JSON stdin (ALLOW)" || fail "non-JSON stdin (want ALLOW, got ${got})"
}

# A deny must name the tool and the root so the model can see why and stop,
# rather than retrying spellings.
case_deny_reason_names_root() {
    local out
    out=$(HOME="$FAKE_HOME" "$BASH_BIN" "$HOOK" 2>/dev/null <<<"$(build_input Read file_path '~/.ssh/id_ed25519')")
    if printf '%s' "$out" | jq -e '.hookSpecificOutput.permissionDecisionReason | test("^sensitive-path-guard: Read of /Users/tester/.ssh/id_ed25519 is refused; /Users/tester/.ssh ")' >/dev/null 2>&1; then
        pass "deny reason names tool, path and root"
    else
        fail "deny reason changed or missing: ${out}"
    fi
}

case_every_root_denies
case_alternate_spellings_deny
case_grep_and_glob_deny
case_ordinary_reads_allow
case_other_tools_allow
case_executor_read_write_confined
case_other_callers_write_unconfined
case_executor_read_reads_unconfined
case_malformed_input_is_silent
case_deny_reason_names_root

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
