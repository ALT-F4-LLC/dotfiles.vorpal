#!/bin/bash

# Pins the agent-shell glob option in src/user/zsh/.zshrc.
#
# Defect class. Claude Code runs Bash calls in the operator's zsh, where an
# unmatched glob is a hard error. An agent that writes the bash idiom
# `grep -rn X --include=*.go .` gets "no matches found", the command never
# runs, and a review can cite a search that did not happen (558 occurrences
# across one run's agent logs). The shipped .zshrc sets NO_NOMATCH when
# CLAUDECODE is set, so the glob passes through literally, as in bash, in the
# agent shell only.
#
# What this suite pins, on the block between the BEGIN/END agent-shell-options
# markers of the shipped .zshrc, sourced into a clean `zsh -f`:
#   (a) CLAUDECODE=1: an unmatched `--include=*.go` is echoed literally, exit 0;
#   (b) CLAUDECODE unset or empty: the same word fails with "no matches found"
#       (the operator's interactive shell is unchanged);
#   (c) CLAUDECODE=1 and a matching file: the glob still expands;
#   (d) the block itself sources cleanly, with and without CLAUDECODE;
#   (f) no line outside the block sets or unsets NOMATCH or resets the options;
#   (e) mutants of the block (option dropped, condition dropped, inverted)
#       each turn one of (a)-(d) red.
# A machine without zsh skips with a note: the check needs the real shell.
#
# Env: ZSHRC_SOURCE overrides the file read, for the mutant checks.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZSHRC="${ZSHRC_SOURCE:-${SCRIPT_DIR}/../src/user/zsh/.zshrc}"

if ! command -v zsh >/dev/null 2>&1; then
    if [ -n "${CI:-}" ]; then echo "zsh-agent-nomatch: zsh is missing in CI" >&2; exit 1; fi
    echo "zsh-agent-nomatch: SKIP (zsh is not installed here)"
    exit 0
fi
[ -f "$ZSHRC" ] || { echo "no zshrc at $ZSHRC" >&2; exit 2; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0
ok() { echo "ok   $1"; pass=$((pass + 1)); }
bad() { echo "FAIL $1"; fail=$((fail + 1)); }

# The option block of one zshrc, markers included, written to $2.
extract() { # <zshrc> <out>
    awk '/^# BEGIN agent-shell-options$/{on=1} on{print} /^# END agent-shell-options$/{on=0}' "$1" > "$2"
}

# Lines of a zshrc outside the option block that set or unset NOMATCH, or reset
# the options with a top-level `emulate`. Sets OUTSIDE.
outside_touches() { # <zshrc>
    OUTSIDE=$(awk '/^# BEGIN agent-shell-options$/{skip=1} !skip{print} /^# END agent-shell-options$/{skip=0}' "$1" \
        | grep -Ein '^[^#]*(setopt|unsetopt)[[:space:]].*(no_?)?match|^emulate[[:space:]]' || true)
}

# Runs the block in a clean zsh inside an empty directory; $1 is the CLAUDECODE
# setting ("unset" or a value), $2 the block file, $3 the word to echo.
# Sets OUT and RC.
agent_shell() { # <claudecode|unset> <block> <word>
    local dir="$TMP/work"
    rm -rf "$dir"; mkdir -p "$dir"
    if [ "$1" = unset ]; then
        OUT=$(cd "$dir" && env -u CLAUDECODE zsh -f -c "source '$2'; echo $3" 2>&1)
    else
        OUT=$(cd "$dir" && CLAUDECODE="$1" zsh -f -c "source '$2'; echo $3" 2>&1)
    fi
    RC=$?
}

# Runs checks (a)-(d) against one block file; prints findings, returns the
# number of red checks. The mutants call this too, so the self-checks and the
# real run share one code path.
check_block() { # <block>
    local blk="$1" red=0
    if [ "$(grep -c '^# BEGIN agent-shell-options$' "$blk")" -ne 1 ] || [ "$(grep -c '^# END agent-shell-options$' "$blk")" -ne 1 ]; then
        echo "  the block markers are missing or repeated"
        return 1
    fi

    agent_shell 1 "$blk" '--include=*.go'
    if [ "$RC" -eq 0 ] && [ "$OUT" = '--include=*.go' ]; then echo "  ok   (a) agent shell prints the glob literally"
    else echo "  FAIL (a) agent shell: exit ${RC}, output: ${OUT}"; red=$((red + 1)); fi

    agent_shell unset "$blk" '--include=*.go'
    if [ "$RC" -ne 0 ] && printf '%s' "$OUT" | grep -q 'no matches found'; then echo "  ok   (b) a shell without CLAUDECODE still errors"
    else echo "  FAIL (b) no CLAUDECODE: exit ${RC}, output: ${OUT}"; red=$((red + 1)); fi

    agent_shell '' "$blk" '--include=*.go'
    if [ "$RC" -ne 0 ] && printf '%s' "$OUT" | grep -q 'no matches found'; then echo "  ok   (b2) an empty CLAUDECODE still errors"
    else echo "  FAIL (b2) empty CLAUDECODE: exit ${RC}, output: ${OUT}"; red=$((red + 1)); fi

    mkdir -p "$TMP/match" && : > "$TMP/match/a.go"
    OUT=$(cd "$TMP/match" && CLAUDECODE=1 zsh -f -c "source '$blk'; echo *.go" 2>&1); RC=$?
    if [ "$RC" -eq 0 ] && [ "$OUT" = 'a.go' ]; then echo "  ok   (c) a matching glob still expands"
    else echo "  FAIL (c) matching glob: exit ${RC}, output: ${OUT}"; red=$((red + 1)); fi

    OUT=$(env -u CLAUDECODE zsh -f -c "source '$blk'" 2>&1); RC=$?
    if [ "$RC" -eq 0 ] && [ -z "$OUT" ]; then echo "  ok   (d) the block sources cleanly without CLAUDECODE"
    else echo "  FAIL (d) block without CLAUDECODE: exit ${RC}, output: ${OUT}"; red=$((red + 1)); fi
    OUT=$(CLAUDECODE=1 zsh -f -c "source '$blk'" 2>&1); RC=$?
    if [ "$RC" -eq 0 ] && [ -z "$OUT" ]; then echo "  ok   (d2) the block sources cleanly with CLAUDECODE"
    else echo "  FAIL (d2) block with CLAUDECODE: exit ${RC}, output: ${OUT}"; red=$((red + 1)); fi
    return "$red"
}

extract "$ZSHRC" "$TMP/real.zsh"
if [ ! -s "$TMP/real.zsh" ]; then
    bad "the shipped .zshrc has no agent-shell-options block"
else
    out=$(check_block "$TMP/real.zsh"); rc=$?
    printf '%s\n' "$out"
    if [ "$rc" -eq 0 ]; then ok "the shipped block passes (a)-(d)"; else bad "the shipped block fails ${rc} check(s)"; fi

    # (f) nothing outside the block turns the option back on or resets the
    # options: a later `setopt NOMATCH` or a top-level `emulate` would undo it
    # while the extracted block still passed.
    outside_touches "$ZSHRC"
    if [ -z "$OUTSIDE" ]; then ok "nothing outside the block touches NOMATCH or resets the options"
    else bad "the .zshrc touches the option outside the block: ${OUTSIDE}"; fi
    cp "$ZSHRC" "$TMP/late.zshrc"; printf '\nsetopt NOMATCH\n' >> "$TMP/late.zshrc"
    outside_touches "$TMP/late.zshrc"
    if [ -n "$OUTSIDE" ]; then ok "a later setopt NOMATCH outside the block is caught"; else bad "a later setopt NOMATCH outside the block went unnoticed"; fi
    cp "$ZSHRC" "$TMP/emu.zshrc"; printf '\nemulate zsh\n' >> "$TMP/emu.zshrc"
    outside_touches "$TMP/emu.zshrc"
    if [ -n "$OUTSIDE" ]; then ok "a top-level emulate outside the block is caught"; else bad "a top-level emulate outside the block went unnoticed"; fi

    # (e) mutants: each must turn at least one check red.
    mutant() { # <name> <sed expr>
        sed "$2" "$TMP/real.zsh" > "$TMP/mut.zsh"
        if cmp -s "$TMP/real.zsh" "$TMP/mut.zsh"; then bad "mutant ${1} changed nothing"; return; fi
        check_block "$TMP/mut.zsh" >/dev/null 2>&1
        if [ $? -ne 0 ]; then ok "mutant ${1} is red"; else bad "mutant ${1} passed the checks (should be red)"; fi
    }
    mutant "option dropped" 's/^  setopt NO_NOMATCH$/  :/'
    mutant "condition dropped" 's/^if \[\[ -n ${CLAUDECODE-} \]\]; then$/if true; then/'
    mutant "condition inverted" 's/^if \[\[ -n ${CLAUDECODE-} \]\]; then$/if [[ -z ${CLAUDECODE-} ]]; then/'
    mutant "option misspelled" 's/NO_NOMATCH/NO_NOMATCHES/'
fi

echo "zsh-agent-nomatch: ${pass} passed, ${fail} failed"
[ "$fail" -eq 0 ]
