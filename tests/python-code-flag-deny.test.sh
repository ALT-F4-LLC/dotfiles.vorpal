#!/bin/bash

# Pins the python rows of the shell-indirection deny list in
# src/user/claude_code.rs against both failure directions.
#
# Defect class. The row `Bash(python* -*c *)` matched any python call with a
# ` -` followed later by `c `, so the prescribed lane splitter
# (`python3 -I .../lane_units.py ROWS .../launch-d10c --tribunal ...`) was
# refused through `launch-d10c --tribunal` and a run stalled. Anchoring the
# code flag to an option word fixes that, and this suite keeps both sides of
# it: every spelling of an inline python program still matches a deny row, and
# no row matches a script-path call whose arguments merely contain `c `.
#
# The deny rows are read from the Rust source and matched here as permission
# globs (`*` is any run of characters, spaces included, anchored at both ends),
# so a row added or dropped is enforced without editing a second list.
#
# Env: SETTINGS_SOURCE overrides the Rust source, to try a draft rule or the
# previous rule against the table before it lands.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETTINGS="${SETTINGS_SOURCE:-${SCRIPT_DIR}/../src/user/claude_code.rs}"

pass=0
fail=0
ok() { echo "ok   $1"; pass=$((pass + 1)); }
bad() { echo "FAIL $1"; fail=$((fail + 1)); }

[ -f "$SETTINGS" ] || { echo "no settings source at $SETTINGS" >&2; exit 2; }

# The Bash(...) rows of SHELL_INDIRECTION_DENY_PATTERNS, one glob per line.
globs() {
    awk '/^const SHELL_INDIRECTION_DENY_PATTERNS/{on=1; next} on && /^\];/{exit} on' "$SETTINGS" \
        | sed -n 's/^[[:space:]]*"Bash(\(.*\))",$/\1/p'
}

GLOBS=$(globs)
[ -n "$GLOBS" ] || { echo "no deny rows found in $SETTINGS" >&2; exit 2; }

# The first deny glob that matches the command, or nothing.
matching_glob() { # <command>
    local cmd="$1" g ere
    while IFS= read -r g; do
        [ -n "$g" ] || continue
        ere=$(printf '%s' "$g" | sed -e 's/[][\\^$+?(){}|]/\\&/g' -e 's/\./\\./g' -e 's/\*/.*/g')
        if printf '%s' "$cmd" | grep -Eq -- "^${ere}\$"; then
            printf '%s' "$g"
            return 0
        fi
    done <<< "$GLOBS"
    return 1
}

denied() { # <command>
    local g
    if g=$(matching_glob "$1"); then ok "denied (${g}): $1"; else bad "not denied: $1"; fi
}
allowed() { # <command>
    local g
    if g=$(matching_glob "$1"); then bad "wrongly denied by ${g}: $1"; else ok "allowed: $1"; fi
}

# Inline python programs, in every spelling a model or a script produces.
denied "python3 -c 'x'"
denied "python3 -Ic 'x'"
denied "python3 -I -c 'x'"
denied "python3 -I -X dev -c 'x'"
denied "python -c'x'"
denied "python3 -Bc 'x'"
denied "python3 -Ec 'x'"
denied "python3 -sc 'x'"
denied "python3 -uc 'x'"
denied "python3 -Oc 'x'"
denied "python3 -Sc 'x'"
denied "python3 -bc 'x'"
denied "python3 -ic 'x'"
denied "python3 -qc 'x'"
denied "python3 -vc 'x'"
denied "python3 -xc 'x'"
denied "python3 -Pc 'x'"
denied "python3 -dc 'x'"
denied "python3 -Rc 'x'"
denied "python3.12 -c 'import os'"
denied "python3 -W error -c 'x'"
denied "python3 -c"
# Documented limit: a ` -c ` anywhere after `python` still refuses the call, so
# the lane splitter runs as its own Bash call (docket-run SKILL.md).
denied 'python3 -I lane_units.py r.jsonl out; jq -c . out/launches.json'

# Script-path calls whose arguments contain `c ` or end a word in `c`.
LANE='python3 -I ~/.claude/skills/docket-run/scripts/lane_units.py'
allowed "${LANE} /x/launch-d10c --tribunal /y --write-cap 16"
allowed "${LANE} /x/rows-4067-r2.jsonl /x/launch-d10c --tribunal /y/tribunal.js --write-cap 16"
allowed "${LANE} /x/rows.jsonl /x/launch-d10c --tribunal /y --integrated /x/map.json --write-cap 16"
allowed "${LANE} /x/pending.jsonl /x/launch-d10c --tribunal /y --in-flight ISS-1,row:STEP-2 --write-cap 16"
allowed 'python3 ~/.claude/skills/docket-run/scripts/seat_roster.py /x/wave-c --out /x/launch-d10c'
allowed 'python3 script.py --write-cap 16 --tribunal /abc'
allowed 'python3 -m pytest tests/ -k abc'
allowed 'python3 build.py src/ -o out/'

# The exact form the docket-run SKILL prescribes, quoted arguments and no -I.
allowed 'python3 ~/.claude/skills/docket-run/scripts/lane_units.py "$ROWS_FILE" "$LAUNCH_DIR" --tribunal "/p/tribunal.js" --write-cap "$WRITE_CAP"'

# Known gap, pinned so it stays visible: a flag cluster of three or more
# letters ending in c is not enumerated and is left to the auto-mode hard-deny
# prose. Widening the rows to catch it must not bring back the launch-d10c
# false positive above.
allowed "python3 -IBc 'x'"
allowed "python3 -Iuc 'x'"

# Self-check: the glob matcher must be able to reject and accept at all.
[ -z "$(matching_glob 'ls -la')" ] && ok "matcher: an unrelated command matches no row" || bad "matcher: an unrelated command matched a row"

echo "python-code-flag-deny: ${pass} passed, ${fail} failed"
[ "$fail" -eq 0 ]
