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
    read_deny '~/.config/gh/hosts.yml'
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
    assert_verdict Grep path '~/.config/gh/*' "$REPO" DENY "Grep path with trailing star"
    assert_verdict Grep "" "" "${FAKE_HOME}/.aws" DENY "Grep without path, cwd inside ~/.aws"
    assert_verdict Glob "" "" "${FAKE_HOME}/.kube" DENY "Glob without path, cwd inside ~/.kube"
}

# ---- ordinary reads stay silent ------------------------------------------

case_ordinary_reads_allow() {
    read_allow "${REPO}/src/main.rs"
    read_allow 'src/main.rs'
    read_allow '~/.sshd_config'
    read_allow '~/.awsome/notes'
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
    assert_verdict Write file_path '~/.aws/credentials' "$REPO" ALLOW "Write is covered by Edit() rules"
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
case_malformed_input_is_silent
case_deny_reason_names_root

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
