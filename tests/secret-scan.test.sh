#!/bin/bash

# Behavior suite for .docket/bin/secret-scan. Each case builds a throwaway git
# repo under $TMPDIR carrying a committed copy of the script (it scans the repo
# it lives in), plants a synthetic credential in one source (a commit in the
# base range, the index, the working tree, or an untracked file), and asserts
# the exit status and message for one base-selection branch: explicit argument,
# DOCKET_GATE_BASE, the own-gate refusal, or the plain working-tree scan.
#
# Credentials are assembled at runtime so this file never carries one.
#
# Needs only git and bash; no engine, no network.

set -uo pipefail

# The engine exports these to gate processes; a suite run under a gate must not
# inherit them, or every case silently takes the env-base branch.
unset DOCKET_GATE DOCKET_GATE_BASE

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SCANNER="${SCRIPT_DIR}/../.docket/bin/secret-scan"

fatal() { printf 'FATAL: %s\n' "$1" >&2; exit 2; }
[ -x "$SCANNER" ] || fatal "secret-scan not executable at ${SCANNER}"
command -v git >/dev/null 2>&1 || fatal "git is required"

WORK=$(mktemp -d "${TMPDIR:-/tmp}/secret-scan.XXXXXX") || fatal "mktemp failed"
trap 'rm -rf "$WORK"' EXIT

pass=0; fail=0
ok()  { pass=$((pass + 1)); printf 'PASS: %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf 'FAIL: %s\n' "$1"; }

# An AWS access-key shape: the AKIA prefix plus sixteen uppercase letters.
KEY_PREFIX=AKI
CREDENTIAL="${KEY_PREFIX}A""QWERTYUIOPASDFGH"
MATCH_MSG='added line(s) match a credential pattern'

# fresh_repo <name>: a repo whose single baseline commit holds the scanner.
fresh_repo() {
    local d="$WORK/$1"
    mkdir -p "$d/.docket/bin"
    (
        cd "$d" || exit 1
        git init -q
        git config user.email t@example.invalid; git config user.name t
        cp "$SCANNER" .docket/bin/secret-scan
        printf 'readme\n' > README.md
        git add -A && git commit -qm base
    )
    printf '%s' "$d"
}

commit_file() {
    local repo="$1" file="$2" body="$3" msg="$4"
    (cd "$repo" && printf '%s\n' "$body" > "$file" && git add -A && git commit -qm "$msg")
}

head_of() { git -C "$1" rev-parse HEAD; }

# expect <label> <want-exit> <want-substring> <repo> <env...> -- <args...>
expect() {
    local label="$1" want="$2" needle="$3" repo="$4" out got
    shift 4
    local envs=()
    while [ "$#" -gt 0 ] && [ "$1" != -- ]; do envs+=("$1"); shift; done
    [ "$#" -gt 0 ] && shift
    out=$(cd "$repo" && env ${envs[@]+"${envs[@]}"} .docket/bin/secret-scan "$@" 2>&1); got=$?
    if [ "$got" -ne "$want" ]; then
        bad "$label (want exit $want, got $got): $out"
    elif [ -n "$needle" ] && [[ "$out" != *"$needle"* ]]; then
        bad "$label (exit $got, output lacks '$needle'): $out"
    elif [[ "$out" == *"$CREDENTIAL"* ]]; then
        bad "$label (output echoes the credential)"
    else
        ok "$label (exit $got)"
    fi
}

# ---- DOCKET_GATE_BASE, no argument -------------------------------------------
r=$(fresh_repo env-committed); base=$(head_of "$r")
commit_file "$r" leak.txt "key=$CREDENTIAL" leak
expect "env base: committed credential fails" 1 "$MATCH_MSG" "$r" \
    DOCKET_GATE=secret-scan "DOCKET_GATE_BASE=$base" --

r=$(fresh_repo env-add-remove); base=$(head_of "$r")
commit_file "$r" leak.txt "key=$CREDENTIAL" add
commit_file "$r" leak.txt "key=redacted" remove
expect "env base: credential added then removed in range fails" 1 "$MATCH_MSG" "$r" \
    DOCKET_GATE=secret-scan "DOCKET_GATE_BASE=$base" --

r=$(fresh_repo env-staged); base=$(head_of "$r")
(cd "$r" && printf 'key=%s\n' "$CREDENTIAL" > staged.txt && git add staged.txt)
expect "env base: staged credential fails" 1 "$MATCH_MSG" "$r" \
    DOCKET_GATE=secret-scan "DOCKET_GATE_BASE=$base" --

r=$(fresh_repo env-unstaged); base=$(head_of "$r")
printf 'key=%s\n' "$CREDENTIAL" >> "$r/README.md"
expect "env base: unstaged credential fails" 1 "$MATCH_MSG" "$r" \
    DOCKET_GATE=secret-scan "DOCKET_GATE_BASE=$base" --

r=$(fresh_repo env-untracked); base=$(head_of "$r")
printf 'key=%s\n' "$CREDENTIAL" > "$r/untracked.txt"
expect "env base: untracked credential fails" 1 "$MATCH_MSG" "$r" \
    DOCKET_GATE=secret-scan "DOCKET_GATE_BASE=$base" --

r=$(fresh_repo env-clean); base=$(head_of "$r")
expect "env base: clean tree at the baseline passes" 0 "" "$r" \
    DOCKET_GATE=secret-scan "DOCKET_GATE_BASE=$base" --

r=$(fresh_repo env-benign); base=$(head_of "$r")
commit_file "$r" notes.txt "ordinary text" benign
expect "env base: benign commit in range passes" 0 "secret-scan: clean" "$r" \
    DOCKET_GATE=secret-scan "DOCKET_GATE_BASE=$base" --

# ---- own-gate refusal ----------------------------------------------------------
r=$(fresh_repo own-gate)
expect "own gate, base unset: exits 2 naming the base" 2 "DOCKET_GATE_BASE" "$r" \
    DOCKET_GATE=secret-scan --
expect "own gate, base unresolvable: exits 2 naming the base" 2 "DOCKET_GATE_BASE" "$r" \
    DOCKET_GATE=secret-scan DOCKET_GATE_BASE=deadbeef --
expect "own gate, option-shaped base: exits 2" 2 "DOCKET_GATE_BASE" "$r" \
    DOCKET_GATE=secret-scan "DOCKET_GATE_BASE=--output=$WORK/pwn" --
if [ -e "$WORK/pwn" ] || compgen -G "$WORK/pwn*" >/dev/null; then
    bad "option-shaped base wrote a file"
else
    ok "option-shaped base wrote no file"
fi

# ---- base unset, not the own gate: working-tree scan as before ----------------
r=$(fresh_repo wt-unset)
commit_file "$r" leak.txt "key=$CREDENTIAL" leak
expect "no gate, base unset: committed credential outside the scan passes" 0 \
    "no added lines to scan" "$r" --
printf 'key=%s\n' "$CREDENTIAL" > "$r/untracked.txt"
expect "no gate, base unset: working-tree credential fails" 1 "$MATCH_MSG" "$r" --

r=$(fresh_repo wt-other-gate)
printf 'key=%s\n' "$CREDENTIAL" > "$r/untracked.txt"
expect "other gate, base unset: working-tree credential fails" 1 "$MATCH_MSG" "$r" \
    DOCKET_GATE=tests --
rm "$r/untracked.txt"
expect "other gate, base unset: clean tree passes" 0 "no added lines to scan" "$r" \
    DOCKET_GATE=tests --

# ---- explicit argument: range scan whatever the environment holds -------------
r=$(fresh_repo explicit); base=$(head_of "$r")
commit_file "$r" leak.txt "key=$CREDENTIAL" leak
tip=$(head_of "$r")
expect "explicit base: committed credential fails" 1 "$MATCH_MSG" "$r" -- "$base"
expect "explicit base overrides DOCKET_GATE_BASE at HEAD" 1 "$MATCH_MSG" "$r" \
    DOCKET_GATE=secret-scan "DOCKET_GATE_BASE=$tip" -- "$base"
expect "explicit base ignores an unresolvable DOCKET_GATE_BASE" 1 "$MATCH_MSG" "$r" \
    DOCKET_GATE=secret-scan DOCKET_GATE_BASE=deadbeef -- "$base"
expect "explicit base at HEAD is not widened by DOCKET_GATE_BASE" 0 "no added lines to scan" "$r" \
    DOCKET_GATE=secret-scan "DOCKET_GATE_BASE=$base" -- "$tip"
expect "explicit empty argument keeps its refusal" 1 "passed but empty" "$r" \
    DOCKET_GATE=secret-scan "DOCKET_GATE_BASE=$base" -- ""

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
